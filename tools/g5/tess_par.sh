#!/bin/bash
bin=$1
design=$2
out=$3
list=$4
jobs=${5:-6}
mkdir -p "$out"
cd /var/tmp
one() { s=$(date +%s); r=$("$bin" "$design" tess "$2" "$out/$1.obj" 2 | head -c 160); echo "$1 $2 $(( $(date +%s) - s ))s $r"; }
export -f one
export bin design out
xargs -P "$jobs" -L 1 bash -c 'one "$@"' _ < "$list"
echo ALLDONE
