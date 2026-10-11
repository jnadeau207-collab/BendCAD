#!/bin/bash
set -u
export PATH=$HOME/.bend/bin:$PATH
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")/../.."
log=${1:-/tmp/bendcad-laws}
mkdir -p "$log"
git rev-parse HEAD > "$log/head.txt" 2>/dev/null
git status --short laws src > "$log/dirty.txt" 2>/dev/null
cat ~/.bend/FORK > "$log/fork.txt" 2>/dev/null
bend version > "$log/bend_version.txt" 2>&1
sha256sum ~/.bend/bin/bend > "$log/bend_sha256.txt"
sha256sum laws/*/*.bend > "$log/law_sha256.txt"
find src -name '*.bend' | sort | xargs sha256sum > "$log/src_sha256.txt"
st=0
: > "$log/results.txt"
for p in laws/*/PROOF.bend; do
  d=$(basename "$(dirname "$p")")
  n=$(grep -c '^law ' "laws/$d/LAWS.bend")
  s=$(date +%s)
  c=$(timeout 7200 bend "$p" --check-only 2>&1 | grep -v 'bend update' | head -1)
  m=$(date +%s)
  v=$(timeout 7200 bend "$p" --verdict 2>&1 | grep -v 'bend update' | head -1)
  e=$(date +%s)
  echo "$d laws=$n check=[$c] $((m - s))s verdict=[$v] $((e - m))s" | tee -a "$log/results.txt"
  [ "$c" = "ALL PROOFS CHECK" ] && [ "$v" = "ALL PROOFS CHECK" ] || st=1
done
exit $st
