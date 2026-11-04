import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c03/bpi.bend as BI
import ../../src/c03/bsp.bend as Q
import ../../src/c16/skin.bend as SK
import ../../src/k1/sf.bend as S
import ../../src/k1/ss.bend as SS
import ../../src/k1/ef.bend as EF

def fr_z(+z: F64) -> SK.Fr:
  SK.Fr{V.Pt{0.0f64, 0.0f64, z}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}, 1.0f64}

def naca_sec(+z: F64) -> SK.Sc:
  SK.Sc{(SK.naca_runs(4u64, 4u64, 12u64, 40.0f64, 24n)), fr_z(z)}

def gaps(ps: List<&2, V.Point>, +w: G.BezP) -> String:
  match ps:
    case []: ""
    case +p <> t:
      +q = S.bp_uv(w, p)
      " (" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ " gap " ++ F64.show(BI.bp_gap(w, p, V.v2_x(q), V.v2_y(q))) ++ ")" ++ gaps(t, w)

def ics_s(cs: List<&2, SS.IC>, +w: G.BezP) -> String:
  match cs:
    case []: ""
    case +c <> t: "[ic n=" ++ Nat.show(List.length(&2, V.Point, SS.ic_pts(c))) ++ gaps(SS.ic_pts(c), w) ++ "] " ++ ics_s(t, w)

def one(+g: SK.Gr, +u: Nat) -> String:
  +w = SK.pat(g, u, 0n)
  +pl = {G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 5.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}} : G.GVal}
  +r = SS.ssi(G.GV_bp{w}, pl)
  "patch " ++ Nat.show(u) ++ " why " ++ U64.show(SS.ics_why(r)) ++ " tol " ++ F64.show(BI.bp_tol(w)) ++ " " ++ ics_s(SS.ics_ics(r), w) ++ "\n"

def cg(ps: List<&2, V.Point>, +w: G.BezP, +pl: G.GVal) -> String:
  match ps:
    case []: ""
    case +p <> t:
      +q = S.bp_uv(w, p)
      +c = EF.cert_gs([G.GV_bp{w}, pl], p)
      " (" ++ F64.show(V.v2_x(q)) ++ "," ++ F64.show(V.v2_y(q)) ++ " g " ++ F64.show(BI.bp_gap(w, p, V.v2_x(q), V.v2_y(q))) ++ (Bool.pick(String, EF.ct_ok(c), " ok", " BAD")) ++ " f " ++ F64.show(S.bp_f(w, p)) ++ ")" ++ cg(t, w, pl)

def zpl() -> G.GVal:
  G.GV_pl{G.Pl{V.Pt{0.0f64, 0.0f64, 5.0f64}, V.Dr{1.0f64, 0.0f64, 0.0f64}, V.Dr{0.0f64, 1.0f64, 0.0f64}}}

def seedp(+s1: S.SF, +s2: S.SF, +q: V.Vec2) -> V.Point:
  +p1 = S.sf_at(s1, V.v2_x(q), V.v2_y(q))
  S.newton2(10n, s1, s2, p1, S.dunit(SS.fr_tan(s1, s2, p1)), p1)

def tr1(+s1: S.SF, +s2: S.SF) -> SS.TR:
  SS.fr_seed(s1, s2, SS.fr_h(s1, s2), seedp(s1, s2, SS.fr_seed_first(SS.fr_seeds(s1, s2))))

def tr0(+g: SK.Gr) -> String:
  +w = SK.pat(g, 0n, 0n)
  +tr = tr1(S.sf_of(G.GV_bp{w}), S.sf_of(zpl()))
  "ok " ++ (Bool.pick(String, SS.tr_ok(tr), "y", "n")) ++ cg(SS.tr_pts(tr), w, zpl())

def main() -> IO(Unit):
  +cs = SK.orient([naca_sec(0.0f64), naca_sec(15.0f64), naca_sec(30.0f64)])
  +g = SK.grid(cs)
  IO.print("nu " ++ Nat.show(SK.gr_nu(g)) ++ " nb " ++ Nat.show(SK.gr_nb(g)) ++ "\n" ++ tr0(g))
