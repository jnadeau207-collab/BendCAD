#!/bin/bash
set -u
cd "$(dirname "$0")/../../.."
out=${1:-/tmp/c05-oracle}
mkdir -p "$out" /var/tmp/c05o
export PYTHONPATH=$HOME/oracle-pkgs
root=$(pwd)
git rev-parse HEAD > "$out/head.txt" 2>/dev/null
git status --short src/c05 tools/oracle/c05 > "$out/dirty.txt" 2>/dev/null
sha256sum src/c05/*.bend tools/oracle/c05/*.py > "$out/src_sha256.txt"
build() {
  rm -f "/var/tmp/$(basename "$1" .bend)"
  ROOT=$root OPT=2 ~/nprobe2.sh "$1" > "$out/build-$(basename "$1" .bend).log" 2>&1
  mv "/var/tmp/$(basename "$1" .bend)" "/var/tmp/c05o/$(basename "$1" .bend)"
}
python3 tools/oracle/c05/stress.py gen 2 1500 tests/c05/zo_stress.bend
build tests/c05/zo_stress.bend
/usr/bin/time -f "%e s %M KB" -o "$out/stress_time.txt" /var/tmp/c05o/zo_stress > "$out/stress_out.txt"
python3 tools/oracle/c05/stress.py judge 2 1500 "$out/stress_rows.json" "$out/stress_out.txt" > "$out/stress_judge.txt"
python3 tools/oracle/c05/arr_stress.py gen 7 500 tests/c05/zo_arr.bend
build tests/c05/zo_arr.bend
/usr/bin/time -f "%e s %M KB" -o "$out/arr_time.txt" /var/tmp/c05o/zo_arr > "$out/arr_out.txt"
python3 tools/oracle/c05/arr_stress.py judge 7 500 "$out/arr_rows.json" "$out/arr_out.txt" > "$out/arr_judge.txt"
: > "$out/scale.txt"
for n in 10 20 50 100 200; do
  python3 tools/oracle/c05/stress.py scale 5 $n tests/c05/zo_big$n.bend
  build tests/c05/zo_big$n.bend
  /usr/bin/time -f "n=$n %e s %M KB" -a -o "$out/scale.txt" /var/tmp/c05o/zo_big$n > "$out/big$n.txt"
  python3 tools/oracle/c05/stress.py scale-judge 5 $n "$out/big${n}_rows.json" "$out/big$n.txt" >> "$out/scale.txt"
done
rm -f tests/c05/zo_*.bend
python3 - "$out" <<'PY'
import collections, json, sys
o = sys.argv[1]
s = json.load(open(o + '/stress_rows.json'))
a = json.load(open(o + '/arr_rows.json'))
c = collections.Counter((r['want'], r['verdict'].split(':')[0]) for r in s)
wrong = [r for r in s if r['verdict'].startswith('WRONG')]
aw = [r for r in a if r['verdict'] != 'PASS']
lines = ['solver %d cases: %s' % (len(s), dict(sorted(c.items()))), 'solver wrong answers: %d' % len(wrong),
         'arrangement %d cases, not PASS: %d' % (len(a), len(aw))]
open(o + '/summary.txt', 'w').write(chr(10).join(lines) + chr(10))
print(chr(10).join(lines))
sys.exit(1 if wrong or aw else 0)
PY
