import json
import math
import os
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
LVL = {'impeller': (4, 5), 'front_cover': (4, 5), 'diffuser': (3, 4), 'shaft': (3, 3), 'nut_front': (3, 3), 'intake': (2, 3), 'tunnel': (2, 3), 'casing': (2, 2)}
BOX = (-0.060, 0.060, -0.060, 0.060, -0.040, 0.045)
CELL = 0.004 * 2.0 ** ((2 - LEVEL) / 2.0)
MRF = (0.03425, -0.0095, 0.02775)
R_OUT = jet.R_CASE_I * 1e-3


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


def mesh_dicts():
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
    w('system/snappyHexMeshDict', 'dictionary', 'snappyHexMeshDict', f'''castellatedMesh true;
snap            true;
addLayers       false;
geometry
{{
{geo}
    wheel {{ type searchableCylinder; point1 (0 0 {MRF[1]}); point2 (0 0 {MRF[2]}); radius {MRF[0]}; }}
    passage {{ type searchableCylinder; point1 (0 0 -0.012); point2 (0 0 0.042); radius 0.054; }}
}}
castellatedMeshControls
{{
    maxLocalCells 6000000;
    maxGlobalCells 16000000;
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
        wheel {{ mode inside; levels ((1e15 4)); }}
        passage {{ mode inside; levels ((1e15 3)); }}
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
    nSmoothScale 4;
    errorReduction 0.75;
}}
mergeTolerance 1e-6;
''')
    w('system/topoSetDict', 'dictionary', 'topoSetDict', f'''actions
(
    {{ name wheelCells; type cellSet; action new; source cylinderToCell; p1 (0 0 {MRF[1]}); p2 (0 0 {MRF[2]}); radius {MRF[0]}; }}
    {{ name wheel; type cellZoneSet; action new; source setToCellZone; set wheelCells; }}
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
    omega constant {OMEGA};
}}
''')
    w('constant/fvOptions', 'dictionary', 'fvOptions', '')
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


def fields(ramp=1500):
    walls = '"(' + '|'.join(ROT + STA) + ')"'
    rot = '"(' + '|'.join(ROT) + ')"'
    k0, om0 = 1.0, 2000.0
    amb = 'inlet|ambient|outlet'
    pout = f'plenum {{ type uniformFixedValue; uniformValue table ((0 {P0}) ({ramp} {P_OUT})); value uniform {P0}; }}'
    base = {
        'p': ('volScalarField', '[1 -1 -2 0 0 0 0]', P0,
              f'"({amb})" {{ type totalPressure; p0 uniform {P0}; value uniform {P0}; }}\n    {pout}\n    {walls} {{ type zeroGradient; }}'),
        'T': ('volScalarField', '[0 0 0 1 0 0 0]', T0,
              f'"({amb})" {{ type totalTemperature; gamma 1.4; T0 uniform {T0}; value uniform {T0}; }}\n    plenum {{ type inletOutlet; inletValue uniform {CYC["T2_K"]}; value uniform {T0}; }}\n    {walls} {{ type zeroGradient; }}'),
        'U': ('volVectorField', '[0 1 -1 0 0 0 0]', '(0 0 0)',
              f'"({amb})" {{ type pressureInletOutletVelocity; value uniform (0 0 0); }}\n    plenum {{ type inletOutlet; inletValue uniform (0 0 0); value uniform (0 0 0); }}\n'
              f'    {rot} {{ type rotatingWallVelocity; origin (0 0 0); axis (0 0 1); omega {OMEGA}; value uniform (0 0 0); }}\n'
              f'    "(' + '|'.join(STA) + ')" { type noSlip; }'),
        'k': ('volScalarField', '[0 2 -2 0 0 0 0]', k0,
              f'"({amb}|plenum)" {{ type inletOutlet; inletValue uniform {k0}; value uniform {k0}; }}\n    {walls} {{ type kqRWallFunction; value uniform {k0}; }}'),
        'omega': ('volScalarField', '[0 0 -1 0 0 0 0]', om0,
                  f'"({amb}|plenum)" {{ type inletOutlet; inletValue uniform {om0}; value uniform {om0}; }}\n    {walls} {{ type omegaWallFunction; value uniform {om0}; }}'),
        'nut': ('volScalarField', '[0 2 -1 0 0 0 0]', 0,
                f'"({amb}|plenum)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type nutkWallFunction; value uniform 0; }}'),
        'alphat': ('volScalarField', '[1 -1 -1 0 0 0 0]', 0,
                   f'"({amb}|plenum)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type compressible::alphatWallFunction; value uniform 0; }}'),
    }
    for name, (cls, dim, val, bnd) in base.items():
        w(f'0.orig/{name}', cls, name, f'dimensions {dim};\ninternalField uniform {val};\nboundaryField\n{{\n    {bnd}\n}}\n')


def system(end=6000, procs=14):
    w('system/controlDict', 'dictionary', 'controlDict', f'''application rhoSimpleFoam;
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
    pMinFactor 0.3;
    pMaxFactor 4.0;
    transonic yes;
    consistent yes;
    residualControl { p 1e-5; U 1e-5; h 1e-5; }
}
relaxationFactors
{
    fields { p 0.7; rho 0.3; }
    equations { U 0.5; h 0.5; k 0.5; omega 0.5; }
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
runParallel rhoSimpleFoam
runApplication reconstructPar -latestTime
''')


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
