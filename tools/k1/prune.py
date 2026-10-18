import re
import sys

ROOT = 'C:/dev/BendCAD/'


def blocks(text):
    parts = re.split(r'(?m)^(?=(?:def|type) )', text)
    head, rest = parts[0], parts[1:]
    out = []
    for b in rest:
        kind, name = re.match(r'(def|type)\s+([A-Za-z_0-9.]+)', b).groups()
        out.append((kind, name, b))
    return head, out


def ctors(b):
    return set(re.findall(r'(?m)^\s+([A-Z][A-Za-z_0-9]*)\{', b))


def refs(body, alias):
    toks = set(re.findall(r'(?<![A-Za-z_0-9.])([A-Za-z_][A-Za-z_0-9]*)', body))
    ext = {}
    for a, n in re.findall(r'\b([A-Z][A-Za-z0-9]*)\.([A-Za-z_][A-Za-z_0-9]*)', body):
        ext.setdefault(a, set()).add(n)
    return toks, ext


def external_uses(mod_path, files):
    used = set()
    for f in files:
        t = open(ROOT + f, encoding='utf-8').read()
        for m in re.finditer(r'(?m)^import\s+(\S+)\s+as\s+(\S+)', t):
            p, al = m.groups()
            if p.endswith(mod_path.split('/')[-1]):
                used |= set(re.findall(r'\b' + re.escape(al) + r'\.([A-Za-z_][A-Za-z_0-9]*)', t))
    return used


if __name__ == '__main__':
    mod = sys.argv[1]
    users = [a for a in sys.argv[2:] if not a.startswith('--')]
    text = open(ROOT + mod, encoding='utf-8').read()
    head, bl = blocks(text)
    names = {n for _, n, _ in bl}
    ctor_of = {}
    for k, n, b in bl:
        if k == 'type':
            for c in ctors(b):
                ctor_of[c] = n
    keep = set(external_uses(mod, users)) & (names | set(ctor_of))
    keep = {ctor_of.get(n, n) for n in keep}
    body = {n: b for _, n, b in bl}
    stack = list(keep)
    while stack:
        n = stack.pop()
        toks, _ = refs(body[n], None)
        for t in toks:
            t2 = ctor_of.get(t, t)
            if t2 in body and t2 not in keep:
                keep.add(t2)
                stack.append(t2)
    drop = [n for _, n, _ in bl if n not in keep]
    print('keep', len(keep), 'drop', len(drop))
    if '--write' in sys.argv:
        out = head + ''.join(b for _, n, b in bl if n in keep)
        open(ROOT + mod, 'w', encoding='utf-8', newline='\n').write(out)
