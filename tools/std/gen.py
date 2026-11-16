import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'data' / 'std' / 'fasteners.json'
GRV = ROOT / 'data' / 'std' / 'grooves.json'
TLS = ROOT / 'data' / 'std' / 'tools.json'
RANGE = ('key', 'drill', 'tap')
OUT = ROOT / 'src' / 'k2' / 'std.bend'
DOC = ROOT / 'docs' / 'std.md'


def f(x):
    return 'F64.nan()' if x is None else repr(float(x)) + 'f64'


def sane(name, r, cols):
    v = dict(zip(cols, r))
    bad = []
    if not (v['d'] < v['clear_fine'] < v['clear_medium'] < v['clear_coarse']):
        bad.append('clearance series not increasing above d')
    if abs(v['d'] - v['p'] - v['tap_drill']) > 0.06:
        bad.append('tap drill is not the drill size nearest D - P')
    if not (v['cbore_d'] > v['shcs_dk'] and v['cbore_t'] >= v['shcs_k']):
        bad.append('ISO 4762 head does not fit the counterbore')
    if v['csk_d'] is not None and not (v['csk_d'] >= v['csk_dk'] and v['csk_d'] > v['clear_coarse']):
        bad.append('ISO 10642 head does not fit the countersink')
    if not v['hex_af'] > v['d']:
        bad.append('hex width across flats not above d')
    if not (v['shcs_s'] < v['shcs_dk'] and v['shcs_t'] < v['shcs_k'] and v['shcs_b'] > v['d']):
        bad.append('ISO 4762 socket, socket depth or thread length out of proportion')
    if bad:
        sys.exit(name + ': ' + '; '.join(bad))


def main():
    s = json.loads(SRC.read_text(encoding='utf-8'))
    cols = s['columns']
    sizes = s['sizes']
    for k, r in sizes.items():
        if len(r) != len(cols):
            sys.exit(k + ': wrong column count')
        sane(k, r, cols)
    recs = ',\n   '.join('Fa{"%s", [%s]}' % (k, ', '.join(f(x) for x in r)) for k, r in sizes.items())
    acc = '\n\n'.join('def %s(+m: String) -> F64:\n  fv(fa(m), %dn)' % (c, i) for i, c in enumerate(cols))
    tabs = dict(s['tables'])
    g = json.loads(GRV.read_text(encoding='utf-8'))
    g.update(json.loads(TLS.read_text(encoding='utf-8')))
    for k in RANGE:
        if k in g and not all(r[0] < r[1] for r in g[k]['rows']):
            sys.exit(k + ': band lower bound not below upper bound')
    for k, t in g.items():
        if any(len(r) != len(t['columns']) for r in t['rows']):
            sys.exit(k + ': wrong column count')
        if k.startswith('ring') and not all((r[2] < r[0]) == (k == 'ring_shaft') for r in t['rows']):
            sys.exit(k + ': groove diameter on the wrong side of d1')
        tabs[k] = dict(columns=[], standard=t['standard'], source=t['source'])
    tdefs = '\n\n'.join('def t_%s() -> List<&2, List<&2, F64>>:\n  [%s]' % (k, ',\n   '.join('[' + ', '.join(f(x) for x in r) + ']' for r in t['rows'])) for k, t in g.items())
    tsel = ''.join('Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "%s"), t_%s(), ' % (k, k) for k in g) + '[]' + ')' * len(g)
    cite = ''.join('Bool.pick(String, String.eq(t, "%s"), "%s | source: %s", ' % (k, v['standard'], v['source']) for k, v in tabs.items())
    cite += '""' + ')' * len(tabs)
    tcol = ''.join('Bool.pick(String, String.eq(c, "%s"), "%s", ' % (c, k) for k, v in tabs.items() for c in v['columns'])
    ncol = sum(len(v['columns']) for v in tabs.values())
    tcol += '""' + ')' * ncol
    rng = ''.join('Bool.or(String.eq(t, "%s"), ' % k for k in RANGE[:-1]) + 'String.eq(t, "%s")' % RANGE[-1] + ')' * (len(RANGE) - 1)
    body = '''import Base
import ../base/num.bend as N

type Fa is Data:
  Fa{ m: String, v: List<&2, F64> }

def fas() -> List<&2, Fa>:
  [%s]

def fa_go(xs: List<&2, Fa>, +m: String) -> Fa:
  match xs:
    case []: Fa{"", []}
    case +h <> +t:
      Fa{+hm, +hv} = h
      Bool.pick(Fa, String.eq(hm, m), Fa{hm, hv}, fa_go(t, m))

def fa(+m: String) -> Fa:
  fa_go(fas(), m)

def fa_m(+a: Fa) -> String:
  Fa{+k, v} = a
  k

def fa_ok(+m: String) -> Bool:
  Bool.not(String.is_empty(fa_m(fa(m))))

def fv_go(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: fv_go(t, j)

def fv(+a: Fa, +i: Nat) -> F64:
  Fa{m, +v} = a
  fv_go(v, i)

%s

def sizes() -> String:
  "%s"

def sw_go(xs: List<&2, Fa>, +i: Nat) -> String:
  match xs:
    case []: ""
    case +h <> +t:
      Fa{+hm, +hv} = h
      +r = sw_go(t, i)
      +v = fv_go(hv, i)
      Bool.pick(String, F64.is_eq(v, v), Bool.pick(String, String.is_empty(r), hm, hm ++ " " ++ r), r)

def sizes_with(+i: Nat) -> String:
  sw_go(fas(), i)

def cite(+t: String) -> String:
  %s

def table_of(+c: String) -> String:
  %s

%s

def tab(+t: String) -> List<&2, List<&2, F64>>:
  %s

def row_go(rs: List<&2, List<&2, F64>>, +key: Bool, +d: F64) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> +t:
      +a = fv_go(r, 0n)
      +b = fv_go(r, 1n)
      +hit = Bool.pick(Bool, key, Bool.and(F64.is_lt(a, d), F64.is_le(d, F64.add(b, 1.0e-9f64))), F64.is_le(F64.abs(F64.sub(a, d)), 1.0e-9f64))
      Bool.pick(List<&2, F64>, hit, r, row_go(t, key, d))

def row(+t: String, +d: F64) -> List<&2, F64>:
  row_go(tab(t), %s, d)

def row_ok(+r: List<&2, F64>) -> Bool:
  Bool.not(Nat.is_eq(List.length(&2, F64, r), 0n))

def rk_go(rs: List<&2, List<&2, F64>>, +key: Bool) -> String:
  match rs:
    case []: ""
    case +r <> +t:
      +s = Bool.pick(String, key, N.f_show(fv_go(r, 0n)) ++ "-" ++ N.f_show(fv_go(r, 1n)), N.f_show(fv_go(r, 0n)))
      +rest = rk_go(t, key)
      Bool.pick(String, String.is_empty(rest), s, s ++ " " ++ rest)

def row_keys(+t: String) -> String:
  rk_go(tab(t), %s)
''' % (recs, acc, ' '.join(sizes), cite, tcol, tdefs, tsel, rng, rng)
    OUT.write_text(body, encoding='utf-8', newline='\n')
    rows = ['| size | ' + ' | '.join(cols) + ' |', '|' + '---|' * (len(cols) + 1)]
    for k, r in sizes.items():
        rows.append('| ' + k + ' | ' + ' | '.join('' if x is None else repr(float(x)) for x in r) + ' |')
    cites = ['- `%s` (%s): %s; source: %s' % (k, ', '.join(v['columns']), v['standard'], v['source']) for k, v in tabs.items() if v['columns']]
    grv = []
    for k, t in g.items():
        grv.append('\n## %s\n\n%s; source: %s\n\n| %s |\n|%s' % (k, t['standard'], t['source'], ' | '.join(t['columns']), '---|' * len(t['columns'])))
        grv.extend('| ' + ' | '.join(repr(float(x)) for x in r) + ' |' for r in t['rows'])
    DOC.write_text('# Standard engineering data\n\nGenerated by `tools/std/gen.py` from `data/std/fasteners.json`, `data/std/grooves.json` and `data/std/tools.json`; the kernel reads the same records (`src/k2/std.bend`, verb `std`). Millimetres. Groove and key rows are looked up at the face diameter rounded to 0.1 mm (a k5 seat of 8.004 reads the d1 = 8 row). The key, drill and tap tables are bands: a row applies to d_lo < d <= d_hi.\n\n## fasteners\n\n' +
                   '\n'.join(rows) + '\n\n' + '\n'.join(cites) + '\n' + '\n'.join(grv) + '\n', encoding='utf-8', newline='\n')
    print('wrote', OUT, DOC)


main()
