import re
import sys


def span(s, kind, name):
    m = re.search(r'(?m)^' + kind + r' ' + re.escape(name) + r'\b', s)
    if not m:
        raise SystemExit('missing ' + kind + ' ' + name)
    i = m.start()
    n = re.search(r'(?m)^(def|type) ', s[m.end():])
    j = m.end() + n.start() if n else len(s)
    return i, j


def put(path, blocks):
    s = open(path, encoding='utf-8').read()
    for b in blocks:
        b = b.strip('\n') + '\n\n'
        kind, name = re.match(r'(def|type)\s+([A-Za-z_0-9]+)', b).groups()
        try:
            i, j = span(s, kind, name)
            s = s[:i] + b + s[j:]
        except SystemExit:
            s = s.rstrip('\n') + '\n\n' + b
    open(path, 'w', encoding='utf-8', newline='\n').write(s.rstrip('\n') + '\n')


def drop(path, names):
    s = open(path, encoding='utf-8').read()
    for nm in names:
        kind = 'type' if nm[0].isupper() else 'def'
        i, j = span(s, kind, nm)
        s = s[:i] + s[j:]
    open(path, 'w', encoding='utf-8', newline='\n').write(s)


if __name__ == '__main__':
    path = sys.argv[1]
    text = open(sys.argv[2], encoding='utf-8').read()
    parts = re.split(r'(?m)^(?=(?:def|type) )', text)
    put(path, [p for p in parts if p.strip()])
