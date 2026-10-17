import re
import sys


def fix(path):
    s = open(path, encoding='utf-8').read()
    parts = re.split(r'(?m)^(?=(?:def|type) )', s)
    out = []
    for p in parts:
        if not p.startswith('def '):
            out.append(p)
            continue
        m = re.match(r'def ([\w.]+)\((.*?)\) ->', p, re.S)
        if not m:
            out.append(p)
            continue
        body = p[m.end():]
        mm = re.search(r'(?m)^  match (\w+)', body)
        scr = mm.group(1) if mm else None
        params = m.group(2)

        def rep(x):
            name = x.group(2)
            if x.group(1) == '+' or name == scr:
                return x.group(0)
            return '+' + name + ':'
        newp = re.sub(r'(\+?)\b(\w+):', rep, params)
        out.append(p[:m.start(2)] + newp + p[m.end(2):])
    open(path, 'w', encoding='utf-8', newline='\n').write(''.join(out))


for f in sys.argv[1:]:
    fix(f)
