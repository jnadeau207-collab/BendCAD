import sys

from build123d import Compound, Plane, Solid, export_step, import_step

STAMP = '2026-10-13T00:00:00'

TOP = Plane((5, 5, 0), (1, 0, 0), (0, 0, 1))
OFF = Plane((20, 0, 0), (1, 0, 0), (0, 0, 1))


def main():
    box = Solid.make_box(10, 10, 10)
    export_step(box, '/tmp/oracle_box.step', timestamp=STAMP)
    hole = Solid.make_box(10, 10, 10).cut(Solid.make_cylinder(2, 10, TOP))
    export_step(hole, '/tmp/oracle_hole.step', timestamp=STAMP)
    export_step(Solid.make_sphere(10), '/tmp/oracle_sphere.step', timestamp=STAMP)
    export_step(Solid.make_torus(30, 10), '/tmp/oracle_torus.step', timestamp=STAMP)
    multi = Compound([Solid.make_box(10, 10, 10),
                      Solid.make_box(10, 10, 10, OFF)])
    export_step(multi, '/tmp/oracle_multi.step', timestamp=STAMP)
    names = ['box', 'hole', 'sphere', 'torus', 'multi']
    ok = True
    for f in names:
        sh = import_step('/tmp/oracle_%s.step' % f)
        solids = sh.solids() if hasattr(sh, 'solids') else [sh]
        vols = [round(s.volume, 4) for s in solids]
        want = {'box': [1000.0], 'hole': [874.3363], 'sphere': [4188.7902],
                'torus': [59217.6264], 'multi': [1000.0, 1000.0]}[f]
        good = vols == want and all(s.is_valid for s in solids)
        ok = ok and good
        print(('PASS ' if good else 'FAIL ') + f, vols)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
