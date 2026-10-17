import re
import sys


def blocks(text):
    lines = text.split('\n')
    head, items, cur = [], [], None
    for ln in lines:
        top = ln and not ln[0].isspace()
        if top and (ln.startswith('def ') or ln.startswith('type ')):
            if cur:
                items.append(cur)
            cur = [ln]
        elif cur is None:
            head.append(ln)
        else:
            cur.append(ln)
    if cur:
        items.append(cur)
    return head, items


def name_of(b):
    m = re.match(r'(def|type)\s+([A-Za-z_0-9.]+)', b[0])
    return m.group(1), m.group(2)


def main(path):
    text = open(path, encoding='utf-8').read()
    head, items = blocks(text)
    while head and head[-1] == '':
        head.pop()
    types = [b for b in items if b[0].startswith('type ')]
    defs = [b for b in items if b[0].startswith('def ')]
    names = {name_of(b)[1]: i for i, b in enumerate(defs)}
    deps = {}
    for i, b in enumerate(defs):
        body = '\n'.join(b)
        own = name_of(b)[1]
        ws = set(re.findall(r'(?<![A-Za-z_0-9.])([A-Za-z_][A-Za-z_0-9]*)\s*\(', body))
        deps[i] = sorted(names[w] for w in ws if w in names and w != own)
    order, state = [], {}

    def visit(i):
        if state.get(i) == 2:
            return
        if state.get(i) == 1:
            raise SystemExit('cycle at ' + name_of(defs[i])[1])
        state[i] = 1
        for j in deps[i]:
            visit(j)
        state[i] = 2
        order.append(i)

    for i in range(len(defs)):
        visit(i)
    out = head + ['']
    for b in types:
        while b and b[-1] == '':
            b = b[:-1]
        out += b + ['']
    for i in order:
        b = defs[i]
        while b and b[-1] == '':
            b = b[:-1]
        out += b + ['']
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))


if __name__ == '__main__':
    for p in sys.argv[1:]:
        main(p)
