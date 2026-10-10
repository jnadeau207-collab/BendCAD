import Base
import ../src/c00/types.bend as T
import ../src/c06/iv.bend as I
import ../src/c06/model.bend as M
import ../src/c06/sx.bend as S
import ../src/c09/feat.bend as F9

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def part(+src: String) -> M.Part:
  S.part_of(ps_xs(S.parse(src)))

def ev(+src: String) -> List<&2, M.CE>:
  M.ev_part(part(src), [])

def r_s(r: M.NR) -> String:
  match r:
    case M.NR_ok{b, fx}: "ok " ++ M.fx_show(fx)
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "err " ++ T.FailKind.show(k) ++ " " ++ y

def last_r(cs: List<&2, M.CE>, +d: M.NR) -> M.NR:
  match cs:
    case []: d
    case c <> t:
      M.CE{id, key, r} = c
      last_r(t, r)

def last_s(+src: String) -> String:
  r_s(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def last_body(+src: String) -> M.Body:
  M.nr_body(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def vol_has(+src: String, +v: F64) -> Bool:
  +m = M.body_ms(last_body(src))
  +i = M.ms_vol(m)
  Bool.and(F64.is_le(I.i_lo(i), v), F64.is_le(v, I.i_hi(i)))

def nr_ok(r: M.NR) -> Bool:
  match r:
    case M.NR_ok{b, fx}: True{}
    case M.NR_err{k, d}: False{}

def published(+src: String) -> Bool:
  nr_ok(last_r(ev(src), M.bad("-", "-", "empty", "-")))

def box() -> String:
  "(bendcad 1) (node 1 (box 10 10 10) (intent create 6 0 1 0)) "

def rg(+x0: String, +y0: String, +x1: String, +y1: String) -> String:
  "(region (path " ++ x0 ++ " " ++ y0 ++ " (line " ++ x1 ++ " " ++ y0 ++ ") (line " ++ x1 ++ " " ++ y1 ++ ") (line " ++ x0 ++ " " ++ y1 ++ ")))"

def fillet_src() -> String:
  box() ++ "(node 2 (fillet 1 1) (intent remove 26 0 1 0))"

def chamfer_src() -> String:
  box() ++ "(node 2 (chamfer 1 1) (intent remove 10 0 1 0))"

def loft_src() -> String:
  "(bendcad 1) (node 1 (loft 5 " ++ rg("-5", "-5", "5", "5") ++ " " ++ rg("-3", "-3", "3", "3") ++ ") (intent create 6 0 1 0))"

def arc_src() -> String:
  "(bendcad 1) (node 1 (sweep (arc 90) " ++ rg("2", "0", "4", "3") ++ ") (intent create any 0 1 0))"

def shell_src() -> String:
  box() ++ "(node 2 (shell 1 1) (intent remove any any 1 0))"

def g1_src() -> String:
  "(bendcad 1) (node 1 (loft 5 " ++ rg("0", "0", "4", "5") ++ " " ++ rg("0", "0", "4", "5") ++ " (continuity g1)) (intent create any 0 1 0))"

def offset_src() -> String:
  box() ++ "(node 2 (offset 1 1) (intent add 6 0 1 0))"

def thicken_src() -> String:
  box() ++ "(node 2 (thicken 1 1) (intent add 6 0 1 0))"

law ev_fillet_box:
  {last_s(fillet_src()) == "ok material=remove faces_created=26 faces_modified=0 solids=1 through_holes=0" : String}

def ev_fillet_box():
  {==}

law ev_fillet_not_cube:
  {vol_has(fillet_src(), 1000.0f64) == False{} : Bool}

def ev_fillet_not_cube():
  {==}

law ev_fillet_volume:
  {vol_has(fillet_src(), F9.vol_fillet_box(10.0f64, 10.0f64, 10.0f64, 1.0f64)) == True{} : Bool}

def ev_fillet_volume():
  {==}

law ev_chamfer_box:
  {Bool.and(String.eq(last_s(chamfer_src()), "ok material=remove faces_created=10 faces_modified=0 solids=1 through_holes=0"), vol_has(chamfer_src(), 980.0f64)) == True{} : Bool}

def ev_chamfer_box():
  {==}

law ev_loft_square:
  {Bool.and(String.eq(last_s(loft_src()), "ok material=create faces_created=6 faces_modified=0 solids=1 through_holes=0"), vol_has(loft_src(), F64.div(980.0f64, 3.0f64))) == True{} : Bool}

def ev_loft_square():
  {==}

law ev_sweep_arc90:
  {Bool.and(published(arc_src()), vol_has(arc_src(), F64.mul(9.0f64, F9.pi()))) == True{} : Bool}

def ev_sweep_arc90():
  {==}

law ev_shell_closed:
  {Bool.and(published(shell_src()), Bool.and(vol_has(shell_src(), 488.0f64), Bool.not(vol_has(shell_src(), 1000.0f64)))) == True{} : Bool}

def ev_shell_closed():
  {==}

law ev_loft_g1_refuses:
  {last_s(g1_src()) == "err unsupported-op continuity-not-met" : String}

def ev_loft_g1_refuses():
  {==}

law ev_thicken_matches_offset:
  {Bool.and(vol_has(offset_src(), 1728.0f64), vol_has(thicken_src(), 1728.0f64)) == True{} : Bool}

def ev_thicken_matches_offset():
  {==}
