import re
import sys

src, outdir, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
lines = open(src).read().split('\n')


def find(mark, start=0):
    for i in range(start, len(lines)):
        if lines[i] == mark:
            return i
    raise SystemExit('missing ' + mark)


g0 = find('// Globals')
t0 = find('// Tables', g0)
w0 = find('// Work')
s0 = find('// Segments', w0)
m0 = find('// Monk', s0)

proto_re = re.compile(r'^static ([^=;{]*?\b([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{]*\));$')
tail_txt = '\n'.join(lines[m0:])
late = set()
for l in lines[:s0]:
    m = proto_re.match(l)
    if m and re.search(r'\b' + m.group(2) + r'\s*\([^;]*\)\s*\{', tail_txt):
        late.add(m.group(2))


def unstatic(ls):
    out = []
    for l in ls:
        m = proto_re.match(l)
        if m and m.group(2) in late:
            l = l[len('static '):]
        out.append(l)
    return out


def unstatic_defs(ls):
    out = []
    for l in ls:
        if l.startswith('static ') and not l.rstrip().endswith(';'):
            for nm in late:
                if re.match(r'^static [^=;(]*\b' + nm + r'\s*\(', l):
                    l = l[len('static '):]
                    break
        out.append(l)
    return out


late.discard('__attribute__')
lines = unstatic(lines[:s0]) + lines[s0:m0] + unstatic_defs(lines[m0:])

glob_re = re.compile(r'^static ((?!const)[^(=;]*?)(\s*=\s*[^;]*)?;$')


def globals_as(kind):
    out = []
    for l in lines[g0:t0]:
        m = glob_re.match(l)
        if m and 'CONSTV' not in l:
            out.append(l[len('static '):] if kind == 'def' else 'extern ' + m.group(1) + ';')
        else:
            out.append(l)
    return out


def fix_common(ls):
    out = []
    for l in ls:
        if l.startswith('#define WL_FN      static '):
            l = l.replace('static ', '__attribute__((visibility("hidden"))) ', 1)
        out.append(l)
    return out


body = '\n'.join(lines[s0:m0])
pieces = body.split('\n\n')
seg_ix = [i for i, p in enumerate(pieces)
          if re.match(r'^(#if !DEVICE\n)?  WL_CASE\(FID_', p)
          and 'WL_CASE(FID_ENTER)' not in p and 'WL_CASE(FID_EXIT)' not in p]
sizes = [pieces[i].count('\n') + 1 for i in seg_ix]
total = sum(sizes)
target = total / n
groups = [[] for _ in range(n)]
acc, g = 0, 0
for i, sz in zip(seg_ix, sizes):
    if acc >= target * (g + 1) and g < n - 1:
        g += 1
    groups[g].append(i)
    acc += sz
moved = set(i for grp in groups[1:] for i in grp)

head_def = fix_common(lines[:g0] + globals_as('def') + lines[t0:s0])
head_ext = fix_common(lines[:g0] + globals_as('ext') + lines[t0:s0])
head_def = [l.replace('static const WlFn wl_tab[]', 'const WlFn wl_tab[]') for l in head_def]
head_ext = [('extern const WlFn wl_tab[];' if l.startswith('static const WlFn wl_tab[]') else l) for l in head_ext]

sp0 = find('// Spins')
sp_pieces = '\n'.join(lines[sp0:w0]).split('\n\n')
spin_re = re.compile(r'\bspin_(\d+)\b')
sp_name = {}
sp_deps = {}
for j, p in enumerate(sp_pieces):
    m = re.match(r'^(INLINE|FAR)[^\n(]*\bspin_(\d+)\(', p)
    if m:
        sp_name[j] = m.group(2)
        sp_deps[m.group(2)] = set(spin_re.findall(p)) - {m.group(2)}


def spins_for(text):
    need = set(spin_re.findall(text))
    stack = list(need)
    while stack:
        x = stack.pop()
        for d in sp_deps.get(x, ()):
            if d not in need:
                need.add(d)
                stack.append(d)
    return '\n\n'.join(p for j, p in enumerate(sp_pieces) if j not in sp_name or sp_name[j] in need).split('\n')


ext_pre = head_ext[:sp0]
ext_post = head_ext[w0:]

tu0 = head_def +['\n\n'.join(p for i, p in enumerate(pieces) if i not in moved)] + lines[m0:]
open(f'{outdir}/tu0.c', 'w').write('\n'.join(tu0))
for k in range(1, n):
    chunk = '\n\n'.join(pieces[i] for i in groups[k])
    tail = ['', '#if !DEVICE', chunk, '#endif']
    open(f'{outdir}/tu{k}.c', 'w').write('\n'.join(ext_pre + spins_for(chunk) + ext_post + tail))
sz = dict(zip(seg_ix, sizes))
print('late', sorted(late))
print('segments', len(seg_ix), 'per tu', [sum(sz[i] for i in grp) for grp in groups])
