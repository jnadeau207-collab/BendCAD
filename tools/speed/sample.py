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
DEPTH = int(os.environ.get('SAMPLE_STACK', '16384'))
FP = os.environ.get('SAMPLE_FP', '') == '1'
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
    libc.ptrace(CONT, tid, None, None)
    return (r.rip, stack, r.rsp, r.rbp) if ok else None


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


def main(period, argv):
    addrs, names = symbols(argv[0])
    static = addrs and addrs[0] >= 0x200000
    p = subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    global MEM
    seized, hits, n = set(), collections.Counter(), 0
    onstack, callers = collections.Counter(), collections.Counter()
    incl, edges = collections.Counter(), collections.Counter()
    top = addrs[-1] + 4096
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
            if open('/proc/%d/stat' % p.pid).read().rsplit(')', 1)[1].split()[0] in 'ZX':
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
            ip, stack, rsp, rbp = got
            i = bisect.bisect_right(addrs, ip - base) - 1
            nm = names[i] if i >= 0 else '?'
            hits[re.sub(r'_K\d+$', '', nm)] += 1
            n += 1
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
    print('wall %.1f s, %d running-thread samples' % (dt, n))
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

    print('modules present on the stack:')
    for k, v in onstack.most_common(14):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))
    print('nearest non-leaf frame:')
    for k, v in callers.most_common(25):
        print('  %5.1f%%  %s' % (100.0 * v / max(n, 1), k))


if __name__ == '__main__':
    main(float(sys.argv[1]), sys.argv[2:])

