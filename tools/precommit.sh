#!/bin/bash
set -u
cd "$(dirname "$0")/.."
ref=${1:?usage: tools/precommit.sh REF_BIN NEW_BIN [OUTDIR]}
new=${2:?usage: tools/precommit.sh REF_BIN NEW_BIN [OUTDIR]}
out=${3:-/tmp/bendcad-precommit}
mkdir -p "$out"
st=0
step() { echo "== $1"; shift; "$@" || { echo "FAILED: $*"; st=1; }; }
step "identity battery (ref vs new)" bash -c "python3 tools/speed/ident.py run '$ref' '$out/ref' 2 > /dev/null && python3 tools/speed/ident.py run '$new' '$out/new' 2 > /dev/null && python3 tools/speed/ident.py compare '$out/ref' '$out/new' '$out/ident.txt'"
step "fuzz gate (tests/eval/gate-baseline.json)" env FUZZ_BIN="$new" FUZZ_WORK="$out/fuzz" python3 tests/eval/gate.py --out "$out/gate.json"
step "law gate (--check-only and --verdict)" bash tools/laws/check.sh "$out/laws"
step "README ladder generated from receipts" python3 tools/readme/ladder.py --check
echo "precommit: $([ $st = 0 ] && echo PASS || echo FAIL) ($out)"
exit $st
