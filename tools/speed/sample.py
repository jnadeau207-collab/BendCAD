import bisect
import collections
import ctypes
import os
import re
import struct
import subprocess
import sys
import time

libc = ctypes.CDLL('libc.so.6', use_errno=True)
libc.ptrace.argtypes = [ctypes.c_long, ctypes.c_long, ctypes.c_void_p, ctypes.c_void_p]
libc.ptrace.restype = ctypes.c_long
SEIZE, INTERRUPT, GETREGS, CONT, DETACH = 0x4206, 0x4207, 12, 7, 17


MEM = None
KT = None
KLO = 0
DEPTH = int(os.environ.get('SAMPLE_STACK', '16384'))
FP = os.environ.get('SAMPLE_FP', '') == '1'
BUCKET = float(os.environ.get('SAMPLE_TIMELINE', '0'))
LEAFMODS = set(os.environ.get('SAMPLE_LEAF', 'C07/RB,C07/IVX,BASE/EX,C07/I,C01/TYPES,K1/LS,K1/SF').split(','))


class Regs(ctypes.Structure):
    _fields_ = [(n, ctypes.c_ulonglong) for n in
                ['r15', 'r14', 'r13', 'r12', 'rbp', 'rbx', 'r11', 'r10', 'r9', 'r8', 'rax', 'rcx', 'rdx', 'rsi', 'rdi', 'orig_rax', 'rip',
                 'cs', 'eflags', 'rsp', 'ss', 'fs_base', 'gs_base', 'ds', 'es', 'fs', 'gs']]


def symbols(binp):
    rows = []
    for ln in subprocess.run(['nm', '-n', binp], capture_output=True, text=True).stdout.splitlines():
        p = ln.split()
        if len(p) == 3 and p[1] in 'tT':
            rows.append((int(p[0], 16), p[2]))
    return [r[0] for r in rows], [r[1] for r in rows]


def outside(pid, ip, maps, syms):
    if not maps:
        try:
            for ln in open('/proc/%d/maps' % pid):
                f = ln.split()
                if len(f) >= 6 and 'x' in f[1]:
                    a, b = [int(x, 16) for x in f[0].split('-')]
                    maps.append((a, b, int(f[2], 16), f[5]))
        except OSError:
            pass
    for a, b, off, path in maps:
        if a <= ip < b:
            if path not in syms:
                rows = []
                for ln in subprocess.run(['nm', '-D', '--defined-only', path], capture_output=True, text=True).stdout.splitlines():
                    q = ln.split()
                    if len(q) == 3:
                        rows.append((int(q[0], 16), q[2].split('@')[0]))
                rows.sort()
                syms[path] = ([r[0] for r in rows], [r[1] for r in rows])
            ad, nm = syms[path]
            j = bisect.bisect_right(ad, ip - a + off) - 1
            return '[%s] %s' % (os.path.basename(path), nm[j] if j >= 0 else '?')
    return '[outside]'


def base_of(pid, binp):
    real = os.path.realpath(binp)
    for ln in open('/proc/%d/maps' % pid):
        if ln.rstrip().endswith(real):
            lo = int(ln.split('-')[0], 16)
            off = int(ln.split()[2], 16)
            return lo - off
    return 0


def sample(tid):
    if libc.ptrace(INTERRUPT, tid, None, None) != 0:
        return None
    t1 = time.time() + 0.2
    while True:
        try:
            got, st = os.waitpid(tid, 0x40000001)
        except OSError:
            return None
        if got == tid:
            if not os.WIFSTOPPED(st):
                return None
            break
        if time.time() > t1:
            return None
    r = Regs()
    ok = libc.ptrace(GETREGS, tid, None, ctypes.byref(r)) == 0
    stack = b''
    if ok and MEM:
        d = DEPTH
        while d >= 4096 and not stack:
            try:
                MEM.seek(r.rsp)
                stack = MEM.read(d)
            except (OSError, ValueError, OverflowError):
                stack = b''
            d //= 2
    kc = kchain(r, KLO, *KT) if ok and KT and KLO else None
    libc.ptrace(CONT, tid, None, None)
    return (r.rip, stack, r.rsp, r.rbp, kc) if ok else None


def walk(stack, rsp, rbp, lim):
    out = []
    n = len(stack)
    while len(out) < lim:
        off = rbp - rsp
        if off < 0 or off + 16 > n:
            break
        nxt, ret = struct.unpack_from('<QQ', stack, off)
        out.append(ret)
        if nxt <= rbp:
            break
        rbp = nxt
    return out


def ktables(path):
    fids, popn, cur = {}, {}, None
    for ln in open(path, errors='replace'):
        if ln.startswith('#define FID_'):
            q = ln.split()
            if len(q) == 3 and q[2].isdigit():
                fids[q[1]] = int(q[2])
        elif 'WL_CASE(FID_' in ln:
            cur = ln.split('WL_CASE(')[1].split(')')[0]
            popn[cur] = 0
        elif cur and 'WL_POPN(' in ln:
            popn[cur] = int(ln.split('WL_POPN(')[1].split(')')[0])
            cur = None
        elif cur and 'WL_OPEN' in ln:
            cur = None
    names = {v: re.sub(r'_K\d+$', '', k.replace('FID____', '').replace('FID_', '')) for k, v in fids.items()}
    return names, {fids[k]: v for k, v in popn.items() if k in fids}, fids.get('FID_EXIT', -1)


def kchain(r, lo, names, pops, fin):
    for reg in ('r14', 'r13', 'r15', 'r12', 'rbx', 'rbp', 'rdi', 'rsi'):
        sp = getattr(r, reg)
        if not (lo < sp < lo + (1 << 31)) or sp % 8:
            continue
        n = min(sp - lo, 1 << 21)
        try:
            MEM.seek(sp - n)
            buf = MEM.read(n)
        except (OSError, ValueError, OverflowError):
            continue
        ws = struct.unpack('<%dQ' % (len(buf) // 8), buf)
        out, i = [], len(ws) - 1
        while i >= 0:
            f = ws[i]
            if f == fin or f not in names or f not in pops:
                break
            out.append(names[f])
            i -= pops[f] + 1
        if out:
            return out
    return []


def main(period, argv):
    addrs, names = symbols(argv[0])
    static = addrs and addrs[0] >= 0x200000
    pin = [int(c) for c in os.environ.get('SAMPLE_CPUS', '').split(',') if c]
    p = subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         preexec_fn=(lambda: os.sched_setaffinity(0, pin)) if pin else None)
    global MEM, KT, KLO
    kpath = os.environ.get('SAMPLE_KSTK', '')
    if kpath:
        KT = ktables(kpath)
        kaddr = [int(ln.split()[0], 16) for ln in subprocess.run(['nm', argv[0]], capture_output=True, text=True).stdout.splitlines() if ln.endswith(' io_stk')][0]
    kskip = os.environ.get('SAMPLE_KSKIP', r'^(C07_RB|C07_IVX|C07_I_|BASE_|C01_|LIST_|[a-z])')
    kunder = os.environ.get('SAMPLE_UNDER', '')
    kincl, knear, kpath2 = collections.Counter(), collections.Counter(), collections.Counter()
    kn = 0
    seized, hits, n = set(), collections.Counter(), 0
    onstack, callers = collections.Counter(), collections.Counter()
    incl, edges = collections.Counter(), collections.Counter()
    top = addrs[-1] + 4096
    maps, libsyms, cpu = [], {}, (0, 0)
    line = collections.defaultdict(collections.Counter)
    time.sleep(0.05)
    base = 0 if static else base_of(p.pid, argv[0])
    try:
        MEM = open('/proc/%d/mem' % p.pid, 'rb', buffering=0)
    except OSError:
        MEM = None
    t0 = time.time()
    while True:
        try:
            tids = [int(t) for t in os.listdir('/proc/%d/task' % p.pid)]
            ps = open('/proc/%d/stat' % p.pid).read().rsplit(')', 1)[1].split()
            cpu = (int(ps[11]), int(ps[12]))
            if ps[0] in 'ZX':
                break
        except OSError:
            break
        for t in tids:
            if t not in seized:
                if libc.ptrace(SEIZE, t, None, None) == 0:
                    seized.add(t)
                else:
                    continue
            try:
                st = open('/proc/%d/task/%d/stat' % (p.pid, t)).read().rsplit(')', 1)[1].split()[0]
            except OSError:
                continue
            if st != 'R':
                continue
            got = sample(t)
            if got is None:
                continue
            ip, stack, rsp, rbp, kc = got
            if KT and not KLO:
                try:
                    MEM.seek(kaddr + base)
                    KLO = struct.unpack('<Q', MEM.read(8))[0]
                except (ValueError, OSError):
                    pass
            i = bisect.bisect_right(addrs, ip - base) - 1
            nm = names[i] if i >= 0 else '?'
            if i < 0 or ip - base >= top:
                nm = outside(p.pid, ip, maps, libsyms)
            hits[re.sub(r'_K\d+$', '', nm)] += 1
            if BUCKET:
                line[int((time.time() - t0) / BUCKET)][re.sub(r'_K\d+$', '', nm)] += 1
            n += 1
            if KT:
                if kc:
                    leaf = re.sub(r'_K\d+$', '', nm).replace('WL_FID____', '').replace('WL_FID_', '')
                    ch = [leaf] + kc
                    if kunder and not any(re.search(kunder, c) for c in ch):
                        continue
                    kn += 1
                    for c in set(ch):
                        kincl[c] += 1
                    near = [c for c in ch if not re.search(kskip, c)]
                    knear[near[0] if near else '?'] += 1
                    ded = []
                    for c in near:
                        if not ded or ded[-1] != c:
                            ded.append(c)
                    kpath2[' < '.join(ded[:int(os.environ.get('SAMPLE_KDEPTH', '4'))])] += 1
                continue
            if FP:
                chain, prev = [], re.sub(r'_K\d+$', '', nm)
                for ret in walk(stack, rsp, rbp, 20000):
                    j = bisect.bisect_right(addrs, ret - base) - 1
                    if j < 0 or ret - base >= top:
                        break
                    sym = re.sub(r'_K\d+$', '', names[j])
                    chain.append(sym)
                    if sym != prev:
                        edges[(sym, prev)] += 1
                    prev = sym
                for sym in set(chain + [re.sub(r'_K\d+$', '', nm)]):
                    incl[sym] += 1
                continue
            words = [w - base for w in struct.unpack('<%dQ' % (len(stack) // 8), stack[:len(stack) // 8 * 8])]
            seen, first = [], None
            for w in words:
                if addrs[0] <= w < top:
                    sym = names[bisect.bisect_right(addrs, w) - 1]
                    m = re.match(r'WL_FID____(.*?)_([A-Z0-9]+)_', sym)
                    if not m:
                        continue
                    q = m.group(1) + '/' + m.group(2)
                    if q not in seen:
                        seen.append(q)
                    if first is None and q not in LEAFMODS:
                        first = re.sub(r'_K\d+$', '', sym)
            for q in seen:
                onstack[q] += 1
            if first:
                callers[first] += 1
        time.sleep(period)
    dt = time.time() - t0
    tck = float(os.sysconf('SC_CLK_TCK'))
    print('wall %.1f s, cpu %.1f s user %.1f s sys, %d running-thread samples' % (dt, cpu[0] / tck, cpu[1] / tck, n))
    mods = collections.Counter()
    for k, v in hits.items():
        m = re.match(r'WL_FID____(.*?)_([A-Z0-9]+)_', k)
        mods[m.group(1) + '/' + m.group(2) if m else k] += v
    print('by module:')
    for k, v in mods.most_common(12):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))
    print('by definition:')
    for k, v in hits.most_common(int(os.environ.get('SAMPLE_TOP', '30'))):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))
    if KT:
        print('%d samples with a continuation chain' % kn)
        for title, ctr, lim in (('inclusive by definition:', kincl, 'SAMPLE_INCL'), ('nearest caller:', knear, 'SAMPLE_NEAR'), ('caller paths:', kpath2, 'SAMPLE_PATHS')):
            print(title)
            for k, v in ctr.most_common(int(os.environ.get(lim, '60'))):
                print('  %5.1f%%  %s' % (100.0 * v / max(kn, 1), k))
        return
    if FP:
        print('inclusive by definition:')
        for k, v in incl.most_common(int(os.environ.get('SAMPLE_INCL', '90'))):
            print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))
        want = os.environ.get('SAMPLE_EDGE', '')
        if want:
            print('callers of ' + want + ':')
            for (a, b), v in sorted(edges.items(), key=lambda kv: -kv[1]):
                if want in b:
                    print('  %5.1f%%  %s -> %s' % (100.0 * v / max(n, 1), a, b))
        return

    if BUCKET:
        print('timeline:')
        for b in sorted(line):
            tot = sum(line[b].values())
            mm = collections.Counter()
            for k, v in line[b].items():
                m = re.match(r'WL_FID____(.*?)_([A-Z0-9]+)_', k)
                mm[m.group(1) + '/' + m.group(2) if m else k] += v
            print('  %7.1f s  %5d  %s' % (b * BUCKET, tot, '  '.join('%s %d' % (k, 100 * v // tot) for k, v in mm.most_common(7))))
            skip = os.environ.get('SAMPLE_TLSKIP', '')
            rows = [(k, v) for k, v in line[b].most_common() if not (skip and re.search(skip, k))]
            print('                    %s' % '  '.join('%s %d' % (k.replace('WL_FID____', ''), 100 * v // tot) for k, v in rows[:int(os.environ.get('SAMPLE_TLTOP', '6'))]))
    print('modules present on the stack:')
    for k, v in onstack.most_common(14):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))
    print('nearest non-leaf frame:')
    for k, v in callers.most_common(25):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))


if __name__ == '__main__':
    main(float(sys.argv[1]), sys.argv[2:])

