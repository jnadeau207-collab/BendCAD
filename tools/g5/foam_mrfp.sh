#!/bin/bash
set -e
out=${1:-/case/solver}
src=$FOAM_SOLVERS/compressible/rhoSimpleFoam
rm -rf "$out/src"
mkdir -p "$out/src" "$out/bin"
cp -r "$src"/. "$out/src"
cd "$out/src"
rm -rf overPimpleDyMFoam rhoPorousSimpleFoam
grep -q 'EEqn += fvc::div(MRF.phi(), p);' EEqn.H
sed -i 's|EEqn += fvc::div(MRF.phi(), p);|EEqn += fvc::div(MRF.phi(), p) - fvc::div(MRF.phi())*p;|' EEqn.H
grep -q 'fvc::div(MRF.phi())\*p' EEqn.H
sed -i "s|^EXE = .*|EXE = $out/bin/rhoSimpleFoamMRFp|" Make/files
sed -i 's|^rhoSimpleFoam.C|rhoSimpleFoam.C|' Make/files
wmake > "$out/wmake.log" 2>&1
test -x "$out/bin/rhoSimpleFoamMRFp"
sha256sum "$out/src/EEqn.H" "$out/bin/rhoSimpleFoamMRFp"
