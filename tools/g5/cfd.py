import json
import math
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(__file__))
import jet

CASE = os.path.join(ROOT, 'cfd', 'g5')
CYC = jet.CYC
OMEGA = CYC['shaft_rpm'] * 2.0 * math.pi / 60.0
Q_HEAT = CYC['fuel_flow_g_s'] * 1e-3 * CYC['inputs']['LHV_J_kg'] * CYC['inputs']['eta_b']
ROTOR = ['impeller', 'turbine', 'shaft', 'nut_front', 'nut_rear', 'spacer']
STATOR = ['intake', 'front_cover', 'diffuser', 'casing', 'tunnel', 'liner', 'fuel_ring', 'lube_tube', 'ngv', 'exhaust']
FINE = {'impeller': 4, 'turbine': 4, 'diffuser': 4, 'ngv': 4, 'liner': 4, 'fuel_ring': 3}
BOX = (-0.075, 0.075, -0.075, 0.075, -0.075, 0.32)
CELL = 0.005
IMP_ZONE = (0.03425, -0.0078, 0.02775)
TUR_ZONE = (0.03313, 0.1615, 0.1736)
HEAT_ZONE = (0.0230, 0.0450, 0.061, 0.115)

HDR = '''FoamFile
{
    version     2.0;
    format      ascii;
    class       %s;
    object      %s;
}
'''


def w(rel, cls, obj, body):
    p = os.path.join(CASE, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding='utf-8', newline='\n').write(HDR % (cls, obj) + body)


def obj_to_stl(src, dst, name):
    V, F = [], []
    with open(src, encoding='utf-8') as fh:
        for ln in fh:
            if ln.startswith('v '):
                V.append([float(x) for x in ln.split()[1:4]])
            elif ln.startswith('f '):
                F.append([int(x.split('/')[0]) - 1 for x in ln.split()[1:4]])
    V = np.array(V) * 1e-3
    F = np.array(F)
    T = V[F]
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    a = np.linalg.norm(n, axis=1)
    keep = a > 1e-18
    n = n[keep] / a[keep, None]
    T = T[keep]
    with open(dst, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(f'solid {name}\n')
        for k in range(len(T)):
            fh.write(f' facet normal {n[k, 0]:.9e} {n[k, 1]:.9e} {n[k, 2]:.9e}\n  outer loop\n')
            for v in T[k]:
                fh.write(f'   vertex {v[0]:.9e} {v[1]:.9e} {v[2]:.9e}\n')
            fh.write('  endloop\n endfacet\n')
        fh.write(f'endsolid {name}\n')
    return int(keep.sum()), int((~keep).sum())


def stls(mesh_dir):
    out = {}
    os.makedirs(os.path.join(CASE, 'constant', 'triSurface'), exist_ok=True)
    for p in ROTOR + STATOR:
        out[p] = obj_to_stl(os.path.join(mesh_dir, p + '.obj'), os.path.join(CASE, 'constant', 'triSurface', p + '.stl'), p)
        print(p, out[p], flush=True)
    return out


def block_mesh():
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


def snappy(level_shift=0):
    geo = '\n'.join(f'    {p}.stl {{ type triSurfaceMesh; name {p}; }}' for p in ROTOR + STATOR)
    ref = '\n'.join(f'        {p} {{ level ({FINE.get(p, 3) + level_shift} {FINE.get(p, 3) + level_shift}); patchInfo {{ type wall; }} }}'
                    for p in ROTOR + STATOR)
    w('system/snappyHexMeshDict', 'dictionary', 'snappyHexMeshDict', f'''castellatedMesh true;
snap            true;
addLayers       false;
geometry
{{
{geo}
    core {{ type searchableCylinder; point1 (0 0 -0.03); point2 (0 0 0.235); radius 0.0535; }}
}}
castellatedMeshControls
{{
    maxLocalCells 4000000;
    maxGlobalCells 14000000;
    minRefinementCells 10;
    maxLoadUnbalance 0.10;
    nCellsBetweenLevels 2;
    features ();
    refinementSurfaces
    {{
{ref}
    }}
    resolveFeatureAngle 30;
    refinementRegions
    {{
        core {{ mode inside; levels ((1e15 {2 + level_shift})); }}
    }}
    locationInMesh (0.0 0.0 -0.07);
    allowFreeStandingZoneFaces true;
}}
snapControls
{{
    nSmoothPatch 3;
    tolerance 2.0;
    nSolveIter 50;
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
    #includeEtc "caseDicts/mesh/generation/meshQualityDict"
}}
mergeTolerance 1e-6;
''')


def topo():
    r, z0, z1 = IMP_ZONE
    rt, t0, t1 = TUR_ZONE
    ri, ro, h0, h1 = HEAT_ZONE
    w('system/topoSetDict', 'dictionary', 'topoSetDict', f'''actions
(
    {{ name impellerCells; type cellSet; action new; source cylinderToCell; p1 (0 0 {z0}); p2 (0 0 {z1}); radius {r}; }}
    {{ name impeller_zone; type cellZoneSet; action new; source setToCellZone; set impellerCells; }}
    {{ name turbineCells; type cellSet; action new; source cylinderToCell; p1 (0 0 {t0}); p2 (0 0 {t1}); radius {rt}; }}
    {{ name turbine_zone; type cellZoneSet; action new; source setToCellZone; set turbineCells; }}
    {{ name heatCells; type cellSet; action new; source cylinderAnnulusToCell; p1 (0 0 {h0}); p2 (0 0 {h1}); outerRadius {ro}; innerRadius {ri}; }}
    {{ name heat_zone; type cellZoneSet; action new; source setToCellZone; set heatCells; }}
);
''')


def physics():
    def plist(xs):
        return '(' + ' '.join(xs) + ')'
    stat_imp = plist(['front_cover', 'intake', 'diffuser'])
    stat_tur = plist(['ngv', 'exhaust'])
    w('constant/MRFProperties', 'dictionary', 'MRFProperties', f'''impeller
{{
    cellZone impeller_zone;
    active yes;
    nonRotatingPatches {stat_imp};
    origin (0 0 0);
    axis (0 0 1);
    omega constant {OMEGA};
}}
turbine
{{
    cellZone turbine_zone;
    active yes;
    nonRotatingPatches {stat_tur};
    origin (0 0 0);
    axis (0 0 1);
    omega constant {OMEGA};
}}
''')
    w('constant/fvOptions', 'dictionary', 'fvOptions', f'''combustion_heat_release
{{
    type scalarSemiImplicitSource;
    active true;
    selectionMode cellZone;
    cellZone heat_zone;
    volumeMode absolute;
    sources {{ h ({Q_HEAT} 0); }}
}}
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
    w('constant/turbulenceProperties', 'dictionary', 'turbulenceProperties', '''simulationType RAS;
RAS { RASModel kOmegaSST; turbulence on; printCoeffs on; }
''')


def fields():
    walls = '"(' + '|'.join(ROTOR + STATOR) + ')"'
    rot = '"(' + '|'.join(ROTOR) + ')"'
    k0, om0 = 1.0, 2000.0
    amb = 'inlet|ambient'
    base = {
        'p': ('volScalarField', '[1 -1 -2 0 0 0 0]', 101325,
              f'"({amb})" {{ type totalPressure; p0 uniform 101325; value uniform 101325; }}\n    outlet {{ type fixedValue; value uniform 101325; }}\n    {walls} {{ type zeroGradient; }}'),
        'T': ('volScalarField', '[0 0 0 1 0 0 0]', 288.15,
              f'"({amb})" {{ type totalTemperature; T0 uniform 288.15; value uniform 288.15; }}\n    outlet {{ type inletOutlet; inletValue uniform 288.15; value uniform 288.15; }}\n    {walls} {{ type zeroGradient; }}'),
        'U': ('volVectorField', '[0 1 -1 0 0 0 0]', '(0 0 0)',
              f'"({amb})" {{ type pressureInletOutletVelocity; value uniform (0 0 0); }}\n    outlet {{ type inletOutlet; inletValue uniform (0 0 0); value uniform (0 0 0); }}\n'
              f'    {rot} {{ type rotatingWallVelocity; origin (0 0 0); axis (0 0 1); omega {OMEGA}; value uniform (0 0 0); }}\n'
              f'    "(' + '|'.join(STATOR) + ')" { type noSlip; }'),
        'k': ('volScalarField', '[0 2 -2 0 0 0 0]', k0,
              f'"({amb}|outlet)" {{ type inletOutlet; inletValue uniform {k0}; value uniform {k0}; }}\n    {walls} {{ type kqRWallFunction; value uniform {k0}; }}'),
        'omega': ('volScalarField', '[0 0 -1 0 0 0 0]', om0,
                  f'"({amb}|outlet)" {{ type inletOutlet; inletValue uniform {om0}; value uniform {om0}; }}\n    {walls} {{ type omegaWallFunction; value uniform {om0}; }}'),
        'nut': ('volScalarField', '[0 2 -1 0 0 0 0]', 0,
                f'"({amb}|outlet)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type nutkWallFunction; value uniform 0; }}'),
        'alphat': ('volScalarField', '[1 -1 -1 0 0 0 0]', 0,
                   f'"({amb}|outlet)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type compressible::alphatWallFunction; value uniform 0; }}'),
    }
    for name, (cls, dim, val, bnd) in base.items():
        w(f'0.orig/{name}', cls, name, f'''dimensions {dim};
internalField uniform {val};
boundaryField
{{
    {bnd}
}}
''')


def system(end=3000, procs=14):
    w('system/controlDict', 'dictionary', 'controlDict', f'''application rhoSimpleFoam;
startFrom latestTime;
startTime 0;
stopAt endTime;
endTime {end};
deltaT 1;
writeControl timeStep;
writeInterval 250;
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
    w('system/fvSchemes', 'dictionary', 'fvSchemes', '''ddtSchemes { default steadyState; }
gradSchemes { default cellLimited Gauss linear 1; }
divSchemes
{
    default none;
    div(phi,U) bounded Gauss linearUpwind grad(U);
    div(phi,h) bounded Gauss upwind;
    div(phi,K) bounded Gauss upwind;
    div(phi,k) bounded Gauss upwind;
    div(phi,omega) bounded Gauss upwind;
    div(phid,p) Gauss upwind;
    div(((rho*nuEff)*dev2(T(grad(U))))) Gauss linear;
}
laplacianSchemes { default Gauss linear limited corrected 0.5; }
interpolationSchemes { default linear; }
snGradSchemes { default limited corrected 0.5; }
wallDist { method meshWave; }
''')
    w('system/fvSolution', 'dictionary', 'fvSolution', '''solvers
{
    p { solver GAMG; tolerance 1e-8; relTol 0.05; smoother GaussSeidel; }
    "(U|h|k|omega)" { solver smoothSolver; smoother symGaussSeidel; tolerance 1e-9; relTol 0.1; }
}
SIMPLE
{
    nNonOrthogonalCorrectors 1;
    pMinFactor 0.5;
    pMaxFactor 3.5;
    transonic no;
    consistent yes;
}
relaxationFactors
{
    fields { p 1; rho 0.5; }
    equations { U 0.7; h 0.6; k 0.6; omega 0.6; }
}
''')
    w('system/flowReport', 'dictionary', 'flowReport', '''massIn { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name inlet; operation sum; fields (phi); }
massOut { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name outlet; operation sum; fields (phi); }
massAmb { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10;
    log true; writeFields false; regionType patch; name ambient; operation sum; fields (phi); }
torqueImp { type forces; libs (forces); writeControl timeStep; writeInterval 10; log true; patches (impeller); CofR (0 0 0); }
torqueTur { type forces; libs (forces); writeControl timeStep; writeInterval 10; log true; patches (turbine); CofR (0 0 0); }
Tmax { type fieldMinMax; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 10; log true; fields (T U p); }
''')


def allrun():
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
runApplication checkMesh -constant
rm -rf 0 && cp -r 0.orig 0
runApplication decomposePar -force
runParallel rhoSimpleFoam
runApplication reconstructPar -latestTime
''')


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'stl':
        json.dump(stls(sys.argv[2]), open(os.path.join(CASE, 'stl_report.json'), 'w'), indent=1)
    elif cmd == 'case':
        block_mesh()
        snappy(int(sys.argv[2]) if len(sys.argv) > 2 else 0)
        topo()
        physics()
        fields()
        system()
        allrun()
        print('case', CASE, 'omega', OMEGA, 'Q', Q_HEAT)
