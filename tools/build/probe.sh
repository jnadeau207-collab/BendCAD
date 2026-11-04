#!/bin/bash
set -eo pipefail
src=$1; shift
out=/var/tmp/probe.$(basename $src .bend)
Z=$HOME/.zig/zig/zig
SR=/home/jesse/sysroot/usr
ulimit -s unlimited; export BUN_JSC_maxPerThreadStackUsage=1073741824
BEND_NO_TELEMETRY=1 $HOME/.bend/bin/bend "$src" -o $out.c
$Z cc -I$SR/include -std=c11 -O1 -L$SR/lib/x86_64-linux-gnu -Wl,--allow-shlib-undefined -Wl,-rpath,$SR/lib/x86_64-linux-gnu $out.c -o $out -lpthread -lm
rm -f $out.c
$out "$@"
