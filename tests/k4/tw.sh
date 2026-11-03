set -e
B=${BIN:-/home/jesse/bin/bc}
D=/home/jesse/k4/tw.bcd
mkdir -p /home/jesse/k4; rm -f $D
IC='(intent create any any any any)'
$B $D new >/dev/null
T="(region (path 5.0 -5.0 (line 5.0 5.0) (line -5.0 5.0) (line -5.0 -5.0)))"
U="(region (path 6.830127 -1.830127 (line 1.830127 6.830127) (line -6.830127 1.830127) (line -1.830127 -6.830127)))"
$B $D apply "(node 1 (loft 10.0 $T $U) $IC)" "(node 2 (box 4.0 4.0 20.0) $IC)" "(node 3 (move 2 0.0 0.0 -5.0 0) (intent same any any any any))" "(node 4 ${OP:-intersect} 1 3) (intent remove any any any any))" | tail -3
