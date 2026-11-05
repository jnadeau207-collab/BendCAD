import re
import sys


def blocks(text):
    lines = text.split('\n')
    head, defs, cur = [], [], None
    intype = False
    for ln in lines:
        m = re.match(r'def (\w+)\(', ln)
        if m:
            intype = False
            cur = [m.group(1), [ln]]
            defs.append(cur)
        elif ln.startswith('type '):
            intype = True
            head.append('')
            head.append(ln)
        elif intype and (ln.startswith(' ') or ln == ''):
            head.append(ln)
            if ln == '':
                intype = False
        elif cur is None:
            head.append(ln)
        else:
            cur[1].append(ln)
    return head, [(n, '\n'.join(b).rstrip('\n')) for n, b in defs]


def order(defs):
    names = {n for n, _ in defs}
    body = dict(defs)
    pos = {n: i for i, (n, _) in enumerate(defs)}
    deps = {}
    for n, b in defs:
        rest = b.split('\n', 1)[1] if '\n' in b else ''
        deps[n] = {m for m in re.findall(r'(?<![\w.])(\w+)\(', rest) + re.findall(r'~(\w+)', rest) if m in names and m != n}
    out, state = [], {}

    def visit(n):
        if state.get(n) == 2:
            return
        if state.get(n) == 1:
            return
        state[n] = 1
        for d in sorted(deps[n], key=lambda x: pos[x]):
            visit(d)
        state[n] = 2
        out.append(n)
    for n, _ in defs:
        visit(n)
    return [(n, body[n]) for n in out]


def main():
    p = sys.argv[1]
    text = open(p, newline='').read()
    head, defs = blocks(text)
    h = '\n'.join(head).rstrip('\n')
    res = h + '\n\n' + '\n\n'.join(b for _, b in order(defs)) + '\n'
    open(p, 'w', newline='').write(res)


if __name__ == '__main__':
    main()
