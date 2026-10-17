import re
import sys

QUAL = {'V.V2': 'V.Vec2', 'V.Pt': 'V.Point', 'V.Dr': 'V.Dir', 'Ty.EK_curve': 'Ty.EdgeKind',
        'Ty.EK_degenerate': 'Ty.EdgeKind', 'Ty.HV': 'Ty.HVertex', 'Ty.HE': 'Ty.HEdge',
        'Ty.HC': 'Ty.HCoedge', 'Ty.HL': 'Ty.HLoop', 'Ty.Ce': 'Ty.Coedge', 'Ty.Lp': 'Ty.Loop',
        'Ty.Fa': 'Ty.Face', 'Ty.Ed': 'Ty.Edge', 'Ty.Vx': 'Ty.Vertex', 'G.Dom': 'G.Dom',
        'G.Ln': 'G.Line3', 'G.Cc': 'G.Circle3', 'G.Bz': 'G.Bez3', 'G.Rq': 'G.RQBez', 'G.Ts': 'G.TSeg'}


def typ(ctor, local):
    if ctor in QUAL:
        return QUAL[ctor]
    if ctor.startswith('G.GV_'):
        return 'G.GVal'
    if ctor in local:
        return local[ctor]
    return None


def main(path):
    s = open(path, encoding='utf-8').read()
    local = {}
    for m in re.finditer(r'(?m)^type (\w+) is Data:\n((?:  .*\n)+)', s):
        for c in re.findall(r'(?m)^  (\w+)\{', m.group(2)):
            local[c] = m.group(1)
    out = []
    for ln in s.split('\n'):
        m = re.match(r'^(\s*\+\w+ = )([A-Z][\w.]*)(\{.*)$', ln)
        if m:
            t = typ(m.group(2), local)
            body = m.group(2) + m.group(3)
            if t and body.count('{') == body.count('}'):
                ln = m.group(1) + '{' + body + ' : ' + t + '}'
        out.append(ln)
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))


for p in sys.argv[1:]:
    main(p)
