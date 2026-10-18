import Base
import ../c01/types.bend as V
import ../c06/model.bend as M
import ../c06/sx.bend as S
import ../c12/blob.bend as BL
import ../c12/stepw.bend as SW
import ./thr.bend as KT

type KB is Data:
  KB{ s: String, n: Nat }

def num(+v: F64) -> String:
  BL.ns_s(SW.sw_f(v))

def q(+s: String) -> String:
  "'" ++ s ++ "'"

def mat_blk(m: Maybe<&2, M.Grade>, +b: Nat, +pd: Nat, +ctx: Nat) -> KB:
  match m:
    case None{}: KB{"", 0n}
    case Some{+g}:
      M.Gr{+n, +gr, +rho, +cte} = g
      KB{SW.sw_ent(b, "MATERIAL_DESIGNATION(" ++ q(gr) ++ ",(" ++ SW.sw_ref(pd) ++ "))") ++
        SW.sw_ent(Nat.add(b, 1n), "PROPERTY_DEFINITION('material property','density'," ++ SW.sw_ref(pd) ++ ")") ++
        SW.sw_ent(Nat.add(b, 2n), "DESCRIPTIVE_REPRESENTATION_ITEM('density'," ++ q(num(rho) ++ " kg/m3") ++ ")") ++
        SW.sw_ent(Nat.add(b, 3n), "DESCRIPTIVE_REPRESENTATION_ITEM('thermal expansion'," ++ q(num(cte) ++ " 1/K") ++ ")") ++
        SW.sw_ent(Nat.add(b, 4n), "REPRESENTATION('material',(" ++ SW.sw_ref(Nat.add(b, 2n)) ++ "," ++ SW.sw_ref(Nat.add(b, 3n)) ++ ")," ++ SW.sw_ref(ctx) ++ ")") ++
        SW.sw_ent(Nat.add(b, 5n), "PROPERTY_DEFINITION_REPRESENTATION(" ++ SW.sw_ref(Nat.add(b, 1n)) ++ "," ++ SW.sw_ref(Nat.add(b, 4n)) ++ ")"), 6n}

def th_blk(+t: M.Thr, +b: Nat, +pds: Nat, +ctx: Nat) -> String:
  +d = KT.ds_name(KT.desig(KT.th_d(t)))
  +z = KT.th_z(t)
  SW.sw_ent(b, "SHAPE_ASPECT(" ++ q(KT.th_name(t)) ++ "," ++ q(KT.th_face(t)) ++ "," ++ SW.sw_ref(pds) ++ ",.T.)") ++
    SW.sw_ent(Nat.add(b, 1n), "PROPERTY_DEFINITION('thread'," ++ q(KT.th_name(t)) ++ "," ++ SW.sw_ref(b) ++ ")") ++
    SW.sw_ent(Nat.add(b, 2n), "DESCRIPTIVE_REPRESENTATION_ITEM('designation'," ++ q(d ++ " " ++ KT.th_c(t)) ++ ")") ++
    SW.sw_ent(Nat.add(b, 3n), "DESCRIPTIVE_REPRESENTATION_ITEM('length'," ++ q(num(F64.sub(V.v2_y(z), V.v2_x(z)))) ++ ")") ++
    SW.sw_ent(Nat.add(b, 4n), "REPRESENTATION('thread',(" ++ SW.sw_ref(Nat.add(b, 2n)) ++ "," ++ SW.sw_ref(Nat.add(b, 3n)) ++ ")," ++ SW.sw_ref(ctx) ++ ")") ++
    SW.sw_ent(Nat.add(b, 5n), "PROPERTY_DEFINITION_REPRESENTATION(" ++ SW.sw_ref(Nat.add(b, 1n)) ++ "," ++ SW.sw_ref(Nat.add(b, 4n)) ++ ")")

def ths_blk(ts: List<&2, M.Thr>, +node: U64, +b: Nat, +pds: Nat, +ctx: Nat, +acc: KB) -> KB:
  match ts:
    case []: acc
    case +h <> +t:
      KB{+s, +n} = acc
      +mine = U64.is_eq(KT.th_node(h), node)
      ths_blk(t, node, Bool.pick(Nat, mine, Nat.add(b, 6n), b), pds, ctx,
        KB{Bool.pick(String, mine, s ++ th_blk(h, b, pds, ctx), s), Bool.pick(Nat, mine, Nat.add(n, 6n), n)})

def kb_s(+k: KB) -> String:
  KB{+s, +n} = k
  s

def kb_n(+k: KB) -> Nat:
  KB{+s, +n} = k
  n

def k2_block(m: Maybe<&2, M.Grade>, +ts: List<&2, M.Thr>, +node: U64, +e: Nat) -> KB:
  +mb = mat_blk(m, Nat.add(e, 20n), Nat.add(e, 9n), Nat.add(e, 16n))
  +tb = ths_blk(ts, node, Nat.add(Nat.add(e, 20n), kb_n(mb)), Nat.add(e, 10n), Nat.add(e, 16n), KB{"", 0n})
  KB{kb_s(mb) ++ kb_s(tb), Nat.add(kb_n(mb), kb_n(tb))}
