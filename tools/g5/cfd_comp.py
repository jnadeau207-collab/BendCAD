import json
import math
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(__file__))
import jet
import cfd as C

LEVEL = int(os.environ.get('G5_CFD_LEVEL', '2'))
CASE = os.path.join(jet.ROOT, 'cfd', f'g5comp_L{LEVEL}')
CYC = jet.CYC
OMEGA = CYC['shaft_rpm'] * 2.0 * math.pi / 60.0
P0, T0 = 101325.0, 288.15
P_OUT = float(os.environ.get('G5_POUT', '239000'))
ROT = ['impeller', 'shaft', 'nut_front']
STA = ['intake', 'front_cover', 'diffuser', 'tunnel', 'casing']
LVL = {'impeller': (3, 4), 'front_cover': (3, 4), 'diffuser': (3, 3), 'shaft': (2, 2), 'nut_front': (2, 2), 'intake': (2, 2), 'tunnel': (2, 2), 'casing': (2, 2)}
BOX = (-0.060, 0.060, -0.060, 0.060, -0.040, 0.045)
CELL = 0.004 * 2.0 ** ((2 - LEVEL) / 2.0)
MRF = (0.03425, -0.0095, 0.02775)
GAP_Z = (0.0240, 0.0286)
Z_ZONE0 = -0.0005
ZONE_OFF = 0.4
TIP_Z = (0.008, 0.020)
TIP_CELL, TIP_BAND = 1.0e-4, 3.5e-4
TIP_LVL = math.ceil(math.log2(CELL / TIP_CELL))
GAP_R = 0.0352
RAMP = int(os.environ.get('G5_CFD_RAMP', '1500'))
ORDER = int(os.environ.get('G5_CFD_ORDER', '2'))
UDIV = 'linearUpwind grad(U)' if ORDER == 2 else 'upwind'
R_OUT = jet.R_CASE_I * 1e-3
T_MIN = 200.0
U_MAX = 2.0 * OMEGA * MRF[0]


def w(rel, cls, obj, body):
    p = os.path.join(CASE, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding='utf-8', newline='\n').write(C.HDR % (cls, obj) + body)


def stls(mesh_dir):
    os.makedirs(os.path.join(CASE, 'constant', 'triSurface'), exist_ok=True)
    rep = {}
    for p in ROT + STA:
        rep[p] = C.obj_to_stl(os.path.join(mesh_dir, p + '.obj'), os.path.join(CASE, 'constant', 'triSurface', p + '.stl'), p)
        print(p, rep[p], flush=True)
    return rep


def stl_verts(p):
    import numpy as np
    import struct
    b = open(p, 'rb').read()
    n = struct.unpack('<I', b[80:84])[0]
    if 84 + 50 * n == len(b):
        a = np.frombuffer(b[84:84 + 50 * n], dtype=np.dtype([('n', '<3f4'), ('v', '<9f4'), ('a', '<u2')]))
        return a['v'].reshape(-1, 3).astype(float)
    return np.array([[float(x) for x in l.split()[1:4]] for l in b.decode().splitlines() if l.strip().startswith('vertex')])


def shroud(s):
    if s <= 9.5:
        return jet.IMP_RS1 - 0.5 * (9.5 - s) / 12.5, jet.IMP_Z0 + s
    a = (s - 9.5) / 9.5
    return jet.IMP_R2 - 9.5 * math.cos(a), jet.IMP_Z0 + 9.5 + 9.5 * math.sin(a)


def shroud_off(off, z0, z1, n=400):
    s0, s1 = z0 - jet.IMP_Z0, jet.IMP_LS
    out = []
    for k in range(n + 1):
        t = s0 + (s1 - s0) * k / n
        (r, z), (ra, za), (rb, zb) = shroud(t), shroud(t - 1e-4), shroud(t + 1e-4)
        dr, dz = rb - ra, zb - za
        l = math.hypot(dr, dz)
        q = (r + off * dz / l, z - off * dr / l)
        if z0 <= q[1] <= z1:
            out.append((q[0] * 1e-3, q[1] * 1e-3))
    return out


def zone_profile():
    side = shroud_off(ZONE_OFF, Z_ZONE0 * 1e3, 1e9)
    r_end, z_end = side[-1]
    return [(0.0, side[0][1])] + side + [(MRF[0], z_end), (MRF[0], MRF[2]), (0.0, MRF[2])]


def revolve_stl(path, prof, name, n=360):
    out = [f'solid {name}']
    ring = lambda r, z: [(r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), z) for k in range(n)]
    tri = lambda a, b, c: out.extend([' facet normal 0 0 0', '  outer loop'] + [f'   vertex {float(x)!r} {float(y)!r} {float(zz)!r}' for x, y, zz in (a, b, c)] + ['  endloop', ' endfacet'])
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        a, b = ring(r0, z0), ring(r1, z1)
        for k in range(n):
            j = (k + 1) % n
            if r0 > 0:
                tri(a[k], a[j], b[k])
            if r1 > 0:
                tri(a[j], b[j], b[k])
    out.append(f'endsolid {name}')
    open(path, 'w', newline='\n').write('\n'.join(out) + '\n')


def zone_stls():
    prof = zone_profile()
    ts = os.path.join(CASE, 'constant', 'triSurface')
    revolve_stl(os.path.join(ts, 'wheel.stl'), prof, 'wheel')
    revolve_stl(os.path.join(ts, 'tipband.stl'), shroud_off(0.0, TIP_Z[0] * 1e3, TIP_Z[1] * 1e3), 'tipband')
    return prof


def mesh_dicts():
    zone_stls()
    x0, x1, y0, y1, z0, z1 = BOX
    n = [int(round((b - a) / CELL)) for a, b in ((x0, x1), (y0, y1), (z0, z1))]
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    vs = '\n'.join(f'    ({a} {b} {c})' for a, b, c in v)
    w('system/blockMeshDict', 'dictionary', 'blockMeshDict', f'''scale 1;
vertices
(
{vs}
);
blocks ( hex (0 1 2 3 4 5 6 7) ({n[0]} {n[1]} {n[2]}) simpleGrading (1 1 1) );
boundary
(
    inlet {{ type patch; faces ((0 3 2 1)); }}
    outlet {{ type patch; faces ((4 5 6 7)); }}
    ambient {{ type patch; faces ((0 1 5 4) (1 2 6 5) (2 3 7 6) (3 0 4 7)); }}
);
''')
    geo = '\n'.join(f'    {p}.stl {{ type triSurfaceMesh; name {p}; }}' for p in ROT + STA)
    ref = '\n'.join(f'        {p} {{ level ({LVL[p][0]} {LVL[p][1]}); patchInfo {{ type wall; }} }}' for p in ROT + STA)
    ref += '\n        wheel { level (3 3); faceZone wheel; cellZone wheel; cellZoneInside inside; faceType internal; }'
    w('system/snappyHexMeshDict', 'dictionary', 'snappyHexMeshDict', f'''castellatedMesh true;
snap            true;
addLayers       false;
geometry
{{
{geo}
    wheel.stl {{ type triSurfaceMesh; name wheel; }}
    tipband.stl {{ type triSurfaceMesh; name tipband; }}
    passage {{ type searchableCylinder; point1 (0 0 -0.012); point2 (0 0 0.042); radius 0.054; }}
    gaps {{ type searchableCylinder; point1 (0 0 {GAP_Z[0]}); point2 (0 0 {GAP_Z[1]}); radius {GAP_R}; }}
}}
castellatedMeshControls
{{
    maxLocalCells 3000000;
    maxGlobalCells 8000000;
    minRefinementCells 10;
    maxLoadUnbalance 0.10;
    nCellsBetweenLevels 3;
    features ();
    refinementSurfaces
    {{
{ref}
    }}
    resolveFeatureAngle 25;
    refinementRegions
    {{
        wheel {{ mode inside; levels ((1e15 3)); }}
        passage {{ mode inside; levels ((1e15 2)); }}
        gaps {{ mode inside; levels ((1e15 5)); }}
        tipband {{ mode distance; levels (({TIP_BAND} {TIP_LVL})); }}
    }}
    locationInMesh (0.0 0.0 -0.035);
    allowFreeStandingZoneFaces true;
}}
snapControls
{{
    nSmoothPatch 3;
    tolerance 2.0;
    nSolveIter 60;
    nRelaxIter 5;
    nFeatureSnapIter 10;
    implicitFeatureSnap true;
    explicitFeatureSnap false;
    multiRegionFeatureSnap false;
}}
addLayersControls
{{
    relativeSizes true;
    layers {{ }}
    expansionRatio 1.2;
    finalLayerThickness 0.5;
    minThickness 0.1;
    nGrow 0;
    featureAngle 60;
    nRelaxIter 3;
    nSmoothSurfaceNormals 1;
    nSmoothNormals 3;
    nSmoothThickness 10;
    maxFaceThicknessRatio 0.5;
    maxThicknessToMedialRatio 0.3;
    minMedialAxisAngle 90;
    nBufferCellsNoExtrude 0;
    nLayerIter 50;
}}
meshQualityControls
{{
    #includeEtc "caseDicts/meshQualityDict"
    maxBoundarySkewness 4;
    minVol {(CELL / 2 ** TIP_LVL) ** 3 * 1e-3!r};
    maxInternalSkewness 4;
    nSmoothScale 4;
    errorReduction 0.75;
}}
mergeTolerance 1e-6;
''')
    w('system/topoSetDict', 'dictionary', 'topoSetDict', f'''actions
(
    {{ name outFaces; type faceSet; action new; source patchToFace; patch outlet; }}
    {{ name outFaces; type faceSet; action subset; source cylinderToFace; p1 (0 0 0.04); p2 (0 0 0.05); radius {R_OUT}; }}
)
;
''')
    w('system/createPatchDict', 'dictionary', 'createPatchDict', '''pointSync false;
patches
(
    { name plenum; patchInfo { type patch; } constructFrom set; set outFaces; }
);
''')


def physics():
    w('constant/MRFProperties', 'dictionary', 'MRFProperties', f'''wheel
{{
    cellZone wheel;
    active yes;
    nonRotatingPatches (front_cover diffuser tunnel intake casing);
    origin (0 0 0);
    axis (0 0 1);
    omega table ((0 0) ({RAMP} {OMEGA}) (1e9 {OMEGA}));
}}
''')
    w('constant/fvOptions', 'dictionary', 'fvOptions', f'''limitT {{ type limitTemperature; selectionMode all; min {T_MIN}; max 3500; }}
limitU {{ type limitVelocity; selectionMode all; max {U_MAX!r}; }}
''')
    w('constant/thermophysicalProperties', 'dictionary', 'thermophysicalProperties', '''thermoType
{
    type            hePsiThermo;
    mixture         pureMixture;
    transport       sutherland;
    thermo          janaf;
    equationOfState perfectGas;
    specie          specie;
    energy          sensibleEnthalpy;
}
mixture
{
    specie { molWeight 28.96; }
    thermodynamics
    {
        Tlow 200; Thigh 3500; Tcommon 1000;
        highCpCoeffs (3.08792717 1.24597184e-03 -4.23718945e-07 6.74774789e-11 -3.97076972e-15 -995.262755 5.95960930);
        lowCpCoeffs (3.56839620 -6.78729429e-04 1.55371476e-06 -3.29937060e-12 -4.66395387e-13 -1062.34659 3.71582965);
    }
    transport { As 1.4792e-06; Ts 116; }
}
''')
    w('constant/turbulenceProperties', 'dictionary', 'turbulenceProperties', 'simulationType RAS;\nRAS { RASModel kOmegaSST; turbulence on; printCoeffs on; }\n')


def fields(ramp=RAMP):
    walls = '"(' + '|'.join(ROT + STA) + ')"'
    rot = '"(' + '|'.join(ROT) + ')"'
    k0, om0 = 1.0, 2000.0
    amb = 'inlet'
    box = '"(ambient|outlet)"'
    tab = ' '.join(f'({ramp * k / 10!r} {P0 + (P_OUT - P0) * (k / 10) ** 2!r})' for k in range(11))
    pout = f'plenum {{ type uniformFixedValue; uniformValue table ({tab}); value uniform {P0}; }}'
    base = {
        'p': ('volScalarField', '[1 -1 -2 0 0 0 0]', P0,
              f'"({amb})" {{ type totalPressure; p0 uniform {P0}; value uniform {P0}; }}\n    {pout}\n    {walls} {{ type zeroGradient; }}\n    {box} {{ type zeroGradient; }}'),
        'T': ('volScalarField', '[0 0 0 1 0 0 0]', T0,
              f'"({amb})" {{ type totalTemperature; gamma 1.4; T0 uniform {T0}; value uniform {T0}; }}\n    plenum {{ type inletOutlet; inletValue uniform {CYC["T2_K"]}; value uniform {T0}; }}\n    {walls} {{ type zeroGradient; }}\n    {box} {{ type zeroGradient; }}'),
        'U': ('volVectorField', '[0 1 -1 0 0 0 0]', '(0 0 0)',
              f'"({amb})" {{ type pressureInletOutletVelocity; value uniform (0 0 0); }}\n    plenum {{ type inletOutlet; inletValue uniform (0 0 0); value uniform (0 0 0); }}\n    {box} {{ type slip; }}\n'
              f'    {rot} {{ type rotatingWallVelocity; origin (0 0 0); axis (0 0 1); omega table ((0 0) ({RAMP} {OMEGA}) (1e9 {OMEGA})); value uniform (0 0 0); }}\n'
              f'    "(' + '|'.join(STA) + ')" { type noSlip; }'),
        'k': ('volScalarField', '[0 2 -2 0 0 0 0]', k0,
              f'"({amb}|plenum)" {{ type inletOutlet; inletValue uniform {k0}; value uniform {k0}; }}\n    {walls} {{ type kqRWallFunction; value uniform {k0}; }}\n    {box} {{ type zeroGradient; }}'),
        'omega': ('volScalarField', '[0 0 -1 0 0 0 0]', om0,
                  f'"({amb}|plenum)" {{ type inletOutlet; inletValue uniform {om0}; value uniform {om0}; }}\n    {walls} {{ type omegaWallFunction; value uniform {om0}; }}\n    {box} {{ type zeroGradient; }}'),
        'nut': ('volScalarField', '[0 2 -1 0 0 0 0]', 0,
                f'"({amb}|plenum)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type nutkWallFunction; value uniform 0; }}\n    {box} {{ type zeroGradient; }}'),
        'alphat': ('volScalarField', '[1 -1 -1 0 0 0 0]', 0,
                   f'"({amb}|plenum)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type compressible::alphatWallFunction; value uniform 0; }}\n    {box} {{ type zeroGradient; }}'),
    }
    for name, (cls, dim, val, bnd) in base.items():
        w(f'0.orig/{name}', cls, name, f'dimensions {dim};\ninternalField uniform {val};\nboundaryField\n{{\n    {bnd}\n}}\n')


def system(end=6000, procs=14):
    w('system/controlDict', 'dictionary', 'controlDict', f'''application rhoSimpleFoamMRFp;
startFrom latestTime;
startTime 0;
stopAt endTime;
endTime {end};
deltaT 1;
writeControl timeStep;
writeInterval 500;
purgeWrite 2;
writeFormat binary;
writePrecision 8;
writeCompression off;
timeFormat general;
runTimeModifiable true;
functions
{{
    #include "flowReport"
}}
''')
    w('system/decomposeParDict', 'dictionary', 'decomposeParDict', f'numberOfSubdomains {procs};\nmethod scotch;\n')
    w('system/fvSchemes', 'dictionary', 'fvSchemes', ('''ddtSchemes { default steadyState; }
gradSchemes { default cellLimited Gauss linear 1; }
divSchemes
{
    default none;
    div(phi,U) bounded Gauss UDIV;
    div(phi,h) bounded Gauss upwind;
    div(phi,K) bounded Gauss upwind;
    div(phi,k) bounded Gauss upwind;
    div(phi,omega) bounded Gauss upwind;
    div(phid,p) Gauss upwind; div(phiMRF,p) Gauss upwind;
    div(((rho*nuEff)*dev2(T(grad(U))))) Gauss linear;
}
laplacianSchemes { default Gauss linear limited corrected 0.5; }
interpolationSchemes { default linear; }
snGradSchemes { default limited corrected 0.5; }
wallDist { method meshWave; }
''').replace('UDIV', UDIV))
    w('system/fvSolution', 'dictionary', 'fvSolution', '''solvers
{
    p { solver GAMG; tolerance 1e-8; relTol 0.05; smoother GaussSeidel; maxIter 50; }
    "(U|h|k|omega)" { solver smoothSolver; smoother symGaussSeidel; tolerance 1e-9; relTol 0.1; }
}
SIMPLE
{
    nNonOrthogonalCorrectors 1;
    pMinFactor 0.3;
    pMaxFactor 4.0;
    transonic yes;
    consistent no;
    residualControl { p 1e-5; U 1e-5; h 1e-5; }
}
relaxationFactors
{
    fields { p 0.3; rho 0.05; }
    equations { U 0.2; h 0.2; k 0.2; omega 0.2; }
}
''')
    w('system/flowReport', 'dictionary', 'flowReport', '''massIn { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name inlet; operation sum; fields (phi); }
massAmb { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name ambient; operation sum; fields (phi); }
massOut { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name plenum; operation sum; fields (phi); }
pOut { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name plenum; operation weightedAreaAverage; weightField phi; fields (p T); }
extremes { type fieldMinMax; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10; log true; location true; fields (T p U); }
torque { type forces; libs (forces); writeControl timeStep; writeInterval 10; log true; patches (impeller); CofR (0 0 0); }
''')
    open(os.path.join(CASE, 'Allrun'), 'w', newline='\n').write('''#!/bin/bash
set -e
cd ${0%/*}
. $WM_PROJECT_DIR/bin/tools/RunFunctions
runApplication blockMesh
runApplication decomposePar -force
runParallel snappyHexMesh -overwrite
runApplication reconstructParMesh -constant
rm -rf processor*
runApplication topoSet
runApplication createPatch -overwrite
runApplication checkMesh -constant
rm -rf 0 && cp -r 0.orig 0
rm -f log.decomposePar
runApplication decomposePar -force
bash foam_mrfp.sh $PWD/solver > log.solverBuild 2>&1
mpirun -np $(getNumberOfProcessors) $PWD/solver/bin/rhoSimpleFoamMRFp -parallel > log.rhoSimpleFoam 2>&1
runApplication reconstructPar -latestTime
''')
    shutil.copy(os.path.join(os.path.dirname(__file__), 'foam_mrfp.sh'), os.path.join(CASE, 'foam_mrfp.sh'))


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'stl':
        json.dump(stls(sys.argv[2]), open(os.path.join(CASE, 'stl_report.json'), 'w'), indent=1)
    elif cmd == 'case':
        mesh_dicts()
        physics()
        fields()
        system(end=int(os.environ.get('G5_CFD_END', '6000')), procs=int(os.environ.get('G5_CFD_PROCS', '14')))
        print('case', CASE, 'omega', OMEGA, 'p_out', P_OUT)
