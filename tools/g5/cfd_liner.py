import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import jet
import cfd as C

LEVEL = int(os.environ.get('G5_CFD_LEVEL', '2'))
CASE = os.path.join(jet.ROOT, 'cfd', f'g5liner_L{LEVEL}')
CYC = jet.CYC
P3 = 101325.0 * CYC['inputs']['PR']
T3 = CYC['T2_K']
DP = 0.04
PARTS = ['liner', 'tunnel', 'casing', 'ngv', 'fuel_ring', 'lube_tube']
LVL = {'liner': (3, 3), 'fuel_ring': (2, 3), 'ngv': (2, 2), 'tunnel': (2, 2), 'casing': (2, 2), 'lube_tube': (2, 2)}
BOX = (-0.056, 0.056, -0.056, 0.056, 0.040, 0.152)
CELL = 0.004 * 2.0 ** ((2 - LEVEL) / 2.0)
ROWS = [('primary', 72.0), ('secondary', 95.0), ('dilution', 125.0)]


def w(rel, cls, obj, body):
    p = os.path.join(CASE, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding='utf-8', newline='\n').write(C.HDR % (cls, obj) + body)


def band_stl(path, r, z0, z1, n=180, m=8):
    th = np.linspace(0, 2 * np.pi, n + 1)
    zs = np.linspace(z0, z1, m + 1)
    with open(path, 'w', newline='\n') as f:
        f.write('solid band\n')
        for i in range(n):
            for j in range(m):
                a = [(r * math.cos(th[i]), r * math.sin(th[i]), zs[j]), (r * math.cos(th[i + 1]), r * math.sin(th[i + 1]), zs[j]),
                     (r * math.cos(th[i + 1]), r * math.sin(th[i + 1]), zs[j + 1]), (r * math.cos(th[i]), r * math.sin(th[i]), zs[j + 1])]
                for t in ((a[0], a[1], a[2]), (a[0], a[2], a[3])):
                    f.write(' facet normal 0 0 0\n  outer loop\n' + ''.join(f'   vertex {x * 1e-3:.9e} {y * 1e-3:.9e} {z * 1e-3:.9e}\n' for x, y, z in t) + '  endloop\n endfacet\n')
        f.write('endsolid band\n')


def bands():
    out = []
    ro = jet.R_LIN_O - jet.T_LIN / 2.0
    ri = jet.R_LIN_I + jet.T_LIN / 2.0
    for name, z in ROWS:
        for side, r in (('outer', ro), ('inner', ri)):
            b = f'{name}_{side}'
            band_stl(os.path.join(CASE, 'constant', 'triSurface', b + '.stl'), r, z - 6.0, z + 6.0)
            out.append(b)
    return out


def stls(mesh_dir):
    os.makedirs(os.path.join(CASE, 'constant', 'triSurface'), exist_ok=True)
    rep = {p: C.obj_to_stl(os.path.join(mesh_dir, p + '.obj'), os.path.join(CASE, 'constant', 'triSurface', p + '.stl'), p) for p in PARTS}
    rep['bands'] = bands()
    return rep


def case(end=3000, procs=14):
    x0, x1, y0, y1, z0, z1 = BOX
    n = [int(round((b - a) / CELL)) for a, b in ((x0, x1), (y0, y1), (z0, z1))]
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    w('system/blockMeshDict', 'dictionary', 'blockMeshDict', 'scale 1;\nvertices\n(\n' + '\n'.join(f'    ({a} {b} {c})' for a, b, c in v) + f'''
);
blocks ( hex (0 1 2 3 4 5 6 7) ({n[0]} {n[1]} {n[2]}) simpleGrading (1 1 1) );
boundary
(
    front {{ type wall; faces ((0 3 2 1)); }}
    back {{ type wall; faces ((4 5 6 7)); }}
    sides {{ type wall; faces ((0 1 5 4) (1 2 6 5) (2 3 7 6) (3 0 4 7)); }}
);
''')
    geo = '\n'.join(f'    {p}.stl {{ type triSurfaceMesh; name {p}; }}' for p in PARTS)
    ref = '\n'.join(f'        {p} {{ level ({LVL[p][0]} {LVL[p][1]}); patchInfo {{ type wall; }} }}' for p in PARTS)
    w('system/snappyHexMeshDict', 'dictionary', 'snappyHexMeshDict', f'''castellatedMesh true;
snap true;
addLayers false;
geometry
{{
{geo}
    holes {{ type searchableCylinder; point1 (0 0 0.064); point2 (0 0 0.132); radius 0.0475; }}
}}
castellatedMeshControls
{{
    maxLocalCells 3000000; maxGlobalCells 8000000; minRefinementCells 10; maxLoadUnbalance 0.10; nCellsBetweenLevels 3; features ();
    refinementSurfaces
    {{
{ref}
    }}
    resolveFeatureAngle 25;
    refinementRegions {{ holes {{ mode inside; levels ((1e15 2)); }} }}
    locationInMesh (0.0 0.034 0.100);
    allowFreeStandingZoneFaces true;
}}
snapControls {{ nSmoothPatch 3; tolerance 2.0; nSolveIter 60; nRelaxIter 5; nFeatureSnapIter 10; implicitFeatureSnap true; explicitFeatureSnap false; multiRegionFeatureSnap false; }}
addLayersControls {{ relativeSizes true; layers {{ }} expansionRatio 1.2; finalLayerThickness 0.5; minThickness 0.1; nGrow 0; featureAngle 60; nRelaxIter 3; nSmoothSurfaceNormals 1; nSmoothNormals 3; nSmoothThickness 10; maxFaceThicknessRatio 0.5; maxThicknessToMedialRatio 0.3; minMedialAxisAngle 90; nBufferCellsNoExtrude 0; nLayerIter 50; }}
meshQualityControls {{ #includeEtc "caseDicts/meshQualityDict" nSmoothScale 4; errorReduction 0.75; }}
mergeTolerance 1e-6;
''')
    ri, ro = (jet.R_LIN_I + jet.T_LIN) * 1e-3, (jet.R_LIN_O - jet.T_LIN) * 1e-3
    w('system/topoSetDict', 'dictionary', 'topoSetDict', f'''actions
(
    {{ name inF; type faceSet; action new; source patchToFace; patch front; }}
    {{ name outF; type faceSet; action new; source patchToFace; patch back; }}
    {{ name outF; type faceSet; action subset; source cylinderToFace; p1 (0 0 0.15); p2 (0 0 0.153); radius {ro}; innerRadius {ri}; }}
);
''')
    w('system/createPatchDict', 'dictionary', 'createPatchDict', '''pointSync false;
patches
(
    { name inlet; patchInfo { type patch; } constructFrom set; set inF; }
    { name exit; patchInfo { type patch; } constructFrom set; set outF; }
);
''')
    w('constant/thermophysicalProperties', 'dictionary', 'thermophysicalProperties', '''thermoType { type hePsiThermo; mixture pureMixture; transport sutherland; thermo janaf; equationOfState perfectGas; specie specie; energy sensibleEnthalpy; }
mixture
{
    specie { molWeight 28.96; }
    thermodynamics { Tlow 200; Thigh 3500; Tcommon 1000;
        highCpCoeffs (3.08792717 1.24597184e-03 -4.23718945e-07 6.74774789e-11 -3.97076972e-15 -995.262755 5.95960930);
        lowCpCoeffs (3.56839620 -6.78729429e-04 1.55371476e-06 -3.29937060e-12 -4.66395387e-13 -1062.34659 3.71582965); }
    transport { As 1.4792e-06; Ts 116; }
}
''')
    w('constant/turbulenceProperties', 'dictionary', 'turbulenceProperties', 'simulationType RAS;\nRAS { RASModel kOmegaSST; turbulence on; printCoeffs on; }\n')
    walls = '"(' + '|'.join(PARTS + ['front', 'back', 'sides']) + ')"'
    pex = P3 * (1.0 - DP)
    flds = {
        'p': ('volScalarField', '[1 -1 -2 0 0 0 0]', P3, f'inlet {{ type totalPressure; p0 uniform {P3}; value uniform {P3}; }}\n    exit {{ type fixedValue; value uniform {pex}; }}\n    {walls} {{ type zeroGradient; }}'),
        'T': ('volScalarField', '[0 0 0 1 0 0 0]', T3, f'inlet {{ type totalTemperature; gamma 1.4; T0 uniform {T3}; value uniform {T3}; }}\n    exit {{ type inletOutlet; inletValue uniform {T3}; value uniform {T3}; }}\n    {walls} {{ type zeroGradient; }}'),
        'U': ('volVectorField', '[0 1 -1 0 0 0 0]', '(0 0 0)', f'inlet {{ type pressureInletOutletVelocity; value uniform (0 0 0); }}\n    exit {{ type inletOutlet; inletValue uniform (0 0 0); value uniform (0 0 0); }}\n    {walls} {{ type noSlip; }}'),
        'k': ('volScalarField', '[0 2 -2 0 0 0 0]', 1.0, f'"(inlet|exit)" {{ type inletOutlet; inletValue uniform 1; value uniform 1; }}\n    {walls} {{ type kqRWallFunction; value uniform 1; }}'),
        'omega': ('volScalarField', '[0 0 -1 0 0 0 0]', 2000.0, f'"(inlet|exit)" {{ type inletOutlet; inletValue uniform 2000; value uniform 2000; }}\n    {walls} {{ type omegaWallFunction; value uniform 2000; }}'),
        'nut': ('volScalarField', '[0 2 -1 0 0 0 0]', 0, f'"(inlet|exit)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type nutkWallFunction; value uniform 0; }}'),
        'alphat': ('volScalarField', '[1 -1 -1 0 0 0 0]', 0, f'"(inlet|exit)" {{ type calculated; value uniform 0; }}\n    {walls} {{ type compressible::alphatWallFunction; value uniform 0; }}'),
    }
    for name, (cls, dim, val, bnd) in flds.items():
        w(f'0.orig/{name}', cls, name, f'dimensions {dim};\ninternalField uniform {val};\nboundaryField\n{{\n    {bnd}\n}}\n')
    fo = []
    for name, _ in ROWS:
        for side in ('outer', 'inner'):
            b = f'{name}_{side}'
            fo.append(f'{b} {{ type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 20; log true; writeFields false; '
                      f'regionType sampledSurface; name {b}; sampledSurfaceDict {{ type meshedSurface; surface {b}.stl; source cells; interpolate true; }} '
                      f'operation areaNormalIntegrate; fields (U); }}')
    fo.append('massIn { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 20; log true; writeFields false; regionType patch; name inlet; operation sum; fields (phi); }')
    fo.append('massExit { type surfaceFieldValue; libs (fieldFunctionObjects); writeControl timeStep; writeInterval 20; log true; writeFields false; regionType patch; name exit; operation sum; fields (phi); }')
    w('system/flowReport', 'dictionary', 'flowReport', '\n'.join(fo) + '\n')
    w('system/controlDict', 'dictionary', 'controlDict', f'''application rhoSimpleFoam;
startFrom latestTime; startTime 0; stopAt endTime; endTime {end}; deltaT 1; writeControl timeStep; writeInterval 500; purgeWrite 2;
writeFormat binary; writePrecision 8; writeCompression off; timeFormat general; runTimeModifiable true;
functions {{ #include "flowReport" }}
''')
    w('system/decomposeParDict', 'dictionary', 'decomposeParDict', f'numberOfSubdomains {procs};\nmethod scotch;\n')
    w('system/fvSchemes', 'dictionary', 'fvSchemes', '''ddtSchemes { default steadyState; }
gradSchemes { default cellLimited Gauss linear 1; }
divSchemes { default none; div(phi,U) bounded Gauss linearUpwind grad(U); div(phi,h) bounded Gauss upwind; div(phi,K) bounded Gauss upwind;
    div(phi,k) bounded Gauss upwind; div(phi,omega) bounded Gauss upwind; div(phid,p) Gauss upwind; div(((rho*nuEff)*dev2(T(grad(U))))) Gauss linear; }
laplacianSchemes { default Gauss linear limited corrected 0.5; }
interpolationSchemes { default linear; }
snGradSchemes { default limited corrected 0.5; }
wallDist { method meshWave; }
''')
    w('system/fvSolution', 'dictionary', 'fvSolution', '''solvers { p { solver GAMG; tolerance 1e-8; relTol 0.05; smoother GaussSeidel; }
    "(U|h|k|omega)" { solver smoothSolver; smoother symGaussSeidel; tolerance 1e-9; relTol 0.1; } }
SIMPLE { nNonOrthogonalCorrectors 1; pMinFactor 0.5; pMaxFactor 2.0; transonic no; consistent yes; residualControl { p 1e-5; U 1e-5; h 1e-5; } }
relaxationFactors { fields { p 1; rho 0.5; } equations { U 0.7; h 0.6; k 0.6; omega 0.6; } }
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
    print('case', CASE, 'p3', P3, 'exit', pex)


if __name__ == '__main__':
    if sys.argv[1] == 'stl':
        json.dump(stls(sys.argv[2]), open(os.path.join(CASE, 'stl_report.json'), 'w'), indent=1)
    else:
        case(end=int(os.environ.get('G5_CFD_END', '3000')), procs=int(os.environ.get('G5_CFD_PROCS', '14')))
