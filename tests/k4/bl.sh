B=${BIN:-/home/jesse/bin/bc}
D=/home/jesse/k4/bl.bcd
mkdir -p /home/jesse/k4; rm -f $D
IC='(intent create any any any any)'
$B $D new >/dev/null
$B $D apply "(node 1 (naca4 4 4 12 40 17) $IC)" "(node 2 (naca4 4 4 12 40 17) $IC)" "(node 3 (blade 1 2 30 ${TW:-20} 100) $IC)" | tail -2
$B $D apply "(node 4 (box 60 60 10) $IC)" "(node 5 (move 4 -10.0 -30.0 -5.0 0) (intent same any any any any))" "(node 6 (${OP:-union} 3 5) (intent ${IN:-add} any any any any))" | tail -3
