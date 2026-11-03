#!/bin/bash
set -eo pipefail
out=${1:-$HOME/bc/bendcad}
src=${2:-src/c06/cli.bend}
cin=${3:-}
tmp=$(mktemp -d /var/tmp/fastbuild.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
Z=$HOME/.zig/zig/zig
SR=/home/jesse/sysroot/usr
t0=$(date +%s)
if [ -n "$cin" ]; then cp "$cin" $tmp/cli.c; else
ulimit -s unlimited; export BUN_JSC_maxPerThreadStackUsage=1073741824
for try in 1 2 3 4 5; do BEND_NO_TELEMETRY=1 $HOME/.bend/bin/bend "$src" -o $tmp/cli.c && break; done; fi
test -s $tmp/cli.c
t1=$(date +%s)
python3 /mnt/c/dev/BendCAD-k3/tools/build/csplit.py $tmp/cli.c $tmp ${UNITS:-32} > /dev/null
t2=$(date +%s)
ls $tmp/tu*.c | xargs -P ${JOBS:-10} -I{} $Z cc -I$SR/include -std=c11 -O3 -c {} -o {}.o
t3=$(date +%s)
$Z cc -L$SR/lib/x86_64-linux-gnu -Wl,--allow-shlib-undefined -Wl,-rpath,$SR/lib/x86_64-linux-gnu $tmp/tu*.c.o -o $tmp/bendcad -lpthread -lm
mv $tmp/bendcad "$out"
echo "gen $((t1-t0))s split $((t2-t1))s cc $((t3-t2))s link $(($(date +%s)-t3))s"
sha256sum "$out"
