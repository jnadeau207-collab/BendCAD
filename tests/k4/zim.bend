import Base
import ../../src/c01/types.bend as V
import ../../src/c04/types.bend as Ty
import ../../src/c04/ops.bend as O
import ../../src/c03/types.bend as G
import ../../src/c06/build.bend as BD
import ../../src/c03/bsp.bend as Q
import ../../src/c16/skin.bend as SK

def bt_b(bt: BD.Bt) -> Ty.Brep:
  BD.Bt{+b, fns} = bt
  b

def yn(+b: Bool) -> String:
  Bool.pick(String, b, "y", "n")

def fas_s(fs: List<&2, Ty.Face>, +x: Ty.Ix, +i: Nat) -> String:
  match fs:
    case []: ""
    case +h <> t:
      +sf = Ty.fa_surf(h)
      " f" ++ Nat.show(i) ++ ":" ++ yn(O.hls_face_ok(Ty.fa_loops(h), x, sf, O.surf_coinc(sf), O.surf_quad(sf), Ty.fa_slv(h))) ++ fas_s(t, x, Nat.add(i, 1n))

def ps(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def eds(es: List<&2, Ty.Edge>, +x: Ty.Ix, +i: Nat) -> String:
  match es:
    case []: ""
    case +h <> t:
      +p0 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v0(h))))
      +p1 = Ty.vx_p(Ty.tres_vx(Ty.ix_vx(x, Ty.ed_v1(h))))
      +ok = O.edge_ends_on_curve(Ty.ed_kind(h), p0, p1, 1000n)
      +fin = O.curve_fin_ok(Ty.ekind_curve(Ty.ed_kind(h)), 1000n)
      +c = Ty.ekind_curve(Ty.ed_kind(h))
      +q0 = G.gres_p(O.curve_at(c, 0.0f64, 1000n))
      +q1 = G.gres_p(O.curve_at(c, 1.0f64, 1000n))
      Bool.pick(String, Bool.and(ok, fin), "", " e" ++ Nat.show(i) ++ " fin=" ++ yn(fin) ++ " v" ++ ps(p0) ++ ps(p1) ++ " c" ++ ps(q0) ++ ps(q1) ++ "
") ++ eds(t, x, Nat.add(i, 1n))

def run(+k: F64) -> String:
  +b = bt_b(SK.skr_bt(SK.sk_run([SK.Sc{([[V.V2{F64.add(k, 0.0f64), F64.add(k, F64.neg(0.25f64))}, V.V2{F64.add(k, 15.864998604895911f64), F64.add(k, F64.neg(0.2f64))}], [V.V2{F64.add(k, 15.864998604895911f64), F64.add(k, F64.neg(0.2f64))}, V.V2{F64.add(k, 15.864998604895911f64), F64.add(k, 0.2f64)}], [V.V2{F64.add(k, 15.864998604895911f64), F64.add(k, 0.2f64)}, V.V2{F64.add(k, 0.0f64), F64.add(k, 0.25f64)}], [V.V2{F64.add(k, 0.0f64), F64.add(k, 0.25f64)}, V.V2{F64.add(k, 0.0f64), F64.add(k, F64.neg(0.25f64))}]]), SK.Fr{V.Pt{F64.add(k, 8.53561258903847f64), F64.add(k, F64.neg(1.6730010234594566f64)), F64.add(k, 4.80961836091673f64)}, V.Dr{F64.add(k, 0.9771673501711374f64), F64.add(k, F64.neg(0.191527199702914f64)), F64.add(k, F64.neg(0.09198533325198063f64))}, V.Dr{F64.add(k, 0.19234266297203803f64), F64.add(k, 0.9813278249396707f64), 0.0f64}, 1.0f64}}, SK.Sc{([[V.V2{F64.add(k, 0.0f64), F64.add(k, F64.neg(0.8f64))}, V.V2{F64.add(k, 14.008503383036862f64), F64.add(k, F64.neg(0.4f64))}], [V.V2{F64.add(k, 14.008503383036862f64), F64.add(k, F64.neg(0.4f64))}, V.V2{F64.add(k, 14.008503383036862f64), F64.add(k, 0.4f64)}], [V.V2{F64.add(k, 14.008503383036862f64), F64.add(k, 0.4f64)}, V.V2{F64.add(k, 0.0f64), F64.add(k, 0.8f64)}], [V.V2{F64.add(k, 0.0f64), F64.add(k, 0.8f64)}, V.V2{F64.add(k, 0.0f64), F64.add(k, F64.neg(0.8f64))}]]), SK.Fr{V.Pt{F64.add(k, 9.509509336941504f64), F64.add(k, F64.neg(5.610461457297708f64)), F64.add(k, 12.068347316600516f64)}, V.Dr{F64.add(k, 0.8248802141310824f64), F64.add(k, F64.neg(0.4866663972127067f64)), F64.add(k, F64.neg(0.28762553808565666f64))}, V.Dr{F64.add(k, 0.5081388481638113f64), F64.add(k, 0.861275165662377f64), 0.0f64}, 1.0f64}}], 1u64)))
  +x = Ty.ix_of(b)
  +fu = Nat.mul(1000n, 100n)
  "edges " ++ yn(O.es_embed_ok(Ty.brep_es(b), x, fu)) ++ " trim " ++ yn(O.ces_trim_ok(Ty.brep_ces(b))) ++ " surf " ++ yn(O.fas_surf_ok(Ty.brep_fas(b))) ++ fas_s(Ty.brep_fas(b), x, 0n) ++ "
" ++ eds(Ty.brep_es(b), x, 0n)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(run(Q.nf(List.length(&1, String, args))))
