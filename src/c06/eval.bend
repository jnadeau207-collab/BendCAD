# C06 op-graph eval: content-hashed parts over the ops.bend builders.
# Style note: Bend matches only on params/binders, never on let-bound
# computed values, and forbids mutual recursion. Every branch below
# therefore routes its decision through a helper-def param (the
# base/par.bend tr_set pattern): decisions are computed in argument
# position and matched as params in the callee. Cache reuse is
# all-or-nothing: when every node hash matches and every op is a
# box, the cache is reused and the root is published through the
# intent gate. An unsupported op is never reused. Otherwise every
# node rebuilds. Per-node partial reuse is future work. The hash
# covers the op tag, dim ids, zone bits (nom, lo, hi), and input
# node ids.

import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ./types.bend as Y
import ./ops.bend as O

# --- Eval result: the new cache plus the last node outcome. On the
# success path `last` is a dummy Sok; ev_part looks the root body up
# in `cc` by id. ---
type EvRes is Data:
  EV{ cc: Y.Cache, last: Y.SRes }

# --- Cache find outcome: hit flag + entry-or-dummy + remainder. ---
type CcOut is Data:
  CO{ hit: Bool, bt: Y.Built, rest: List<&2, Y.Built> }

# --- Node id + build hash pair for the coverage walk. ---
type HPair is Data:
  HP{ id: U64, h: U64 }

def fnv_step(+h: U64, +b: U64) -> U64:
  (U64.mul(h, 1099511628211u64) + b : U64)

def pm_hit_go(xs: List<&2, Y.Param>, +id: U64) -> Bool:
  match xs:
    case []: False{}
    case p <> t:
      match p:
        case Y.Pm{pid, d}:
          Bool.or(U64.is_eq(pid, id), pm_hit_go(t, id))

def pm_nom_go(xs: List<&2, Y.Param>, +id: U64) -> F64:
  match xs:
    case []: 0.0f64
    case p <> t:
      match p:
        case Y.Pm{pid, d}:
          Bool.pick(F64, U64.is_eq(pid, id), Y.dm_nom(d),
            pm_nom_go(t, id))

def pm_dm_go(xs: List<&2, Y.Param>, +id: U64) -> Y.Dim:
  match xs:
    case []: Y.mk_dm(0.0f64, 0.0f64, 0.0f64)
    case p <> t:
      match p:
        case Y.Pm{pid, d}:
          Bool.pick(Y.Dim, U64.is_eq(pid, id), d, pm_dm_go(t, id))

def bt_id(x: Y.Built) -> U64:
  match x:
    case Y.Bt{i, h, b, f}: i

def dummy_body() -> Y.Body:
  Y.mk_body(Ty.brep_empty(), 0u64, Y.mk_prof([], []), 0.0f64,
    0.0f64, [], 0n, [], [])

def bt_dummy() -> Y.Built:
  Y.mk_built(0u64, 0u64, dummy_body(),
    Y.mk_fx(Y.M_same{}, 0n, 0n, 0n, 0n))

def bt_cat(a: List<&2, Y.Built>, b: List<&2, Y.Built>) -> List<&2, Y.Built>:
  match a:
    case []: b
    case h <> t: h <> bt_cat(t, b)

def cc_has(xs: List<&2, Y.Built>, +id: U64, +h: U64) -> Bool:
  match xs:
    case []: False{}
    case b <> t:
      match b:
        case Y.Bt{bid, bh, body, fx}:
          Bool.or(Bool.and(U64.is_eq(bid, id), U64.is_eq(bh, h)),
            cc_has(t, id, h))

def cc_covers(+items: List<&2, Y.Built>,
    pairs: List<&2, HPair>) -> Bool:
  match pairs:
    case []: True{}
    case q <> t:
      match q:
        case HP{i, h}:
          Bool.and(cc_has(items, i, h), cc_covers(items, t))

# Delayed-branch find by id: the caller passes the head decision in
# `peq`; each frame computes the NEXT head decision in arg position.
def hd_eq(xs: List<&2, Y.Built>, id: U64) -> Bool:
  match xs:
    case []: False{}
    case c <> u: U64.is_eq(bt_id(c), id)

def cc_find_id(xs: List<&2, Y.Built>, acc: List<&2, Y.Built>,
    +id: U64, peq: Bool) -> CcOut:
  match xs:
    case []: CO{False{}, bt_dummy(), acc}
    case +b <> +t:
      match peq:
        case True{}: CO{True{}, b, bt_cat(acc, t)}
        case False{}:
          cc_find_id(t, bt_cat(acc, [b]), id, hd_eq(t, id))

def cc_find_id0(xs: List<&2, Y.Built>, acc: List<&2, Y.Built>,
    +id: U64) -> CcOut:
  match xs:
    case []: CO{False{}, bt_dummy(), acc}
    case +c <> u:
      cc_find_id(c <> u, acc, id, U64.is_eq(bt_id(c), id))

def cc_items(c: Y.Cache) -> List<&2, Y.Built>:
  match c:
    case Y.Cc{items}: items

# FNV-1 over a list of words. The list is the first argument so the
# self-call shrinks before the accumulator changes.
def fnv_list(xs: List<&2, U64>, +h: U64) -> U64:
  match xs:
    case []: h
    case b <> t: fnv_list(t, fnv_step(h, b))

# Nominal, lo, and hi bits of each dim id. A missing id contributes
# the zero dim pm_dm_go returns. Dropping lo/hi makes two zones with
# the same nominal hash equal.
def fnv_zone(+id: U64, +h: U64, +ps: List<&2, Y.Param>) -> U64:
  +d = pm_dm_go(ps, id)
  fnv_step(fnv_step(fnv_step(h, F64.bits(Y.dm_nom(d))),
    F64.bits(Y.dm_lo(d))), F64.bits(Y.dm_hi(d)))

def fnv_zones(ids: List<&2, U64>, +h: U64,
    +ps: List<&2, Y.Param>) -> U64:
  match ids:
    case []: h
    case i <> t: fnv_zones(t, fnv_zone(i, h, ps), ps)

# Dim ids carried by the op, in constructor order. Coordinates, profiles,
# and hole lists are not dim ids.
def op_dim_ids(op: Y.Op) -> List<&2, U64>:
  match op:
    case Y.O_box{w, h, d}: [w, h, d]
    case Y.O_cyl{r, h}: [r, h]
    case Y.O_sph{r}: [r]
    case Y.O_cone{r, h}: [r, h]
    case Y.O_tor{bigR, r}: [bigR, r]
    case Y.O_extrude{prof, depth}: [depth]
    case Y.O_revolve{prof}: []
    case Y.O_holes{base, hs}: []
    case Y.O_pocket{base, x, y, w, h, depth}: [depth]
    case Y.O_pad{base, x, y, w, h, d}: [w, h, d]
    case Y.O_xform{base, xf}: []

# Input node ids embedded in the op. Node.ins is hashed separately.
def op_in_ids(op: Y.Op) -> List<&2, U64>:
  match op:
    case Y.O_box{w, h, d}: []
    case Y.O_cyl{r, h}: []
    case Y.O_sph{r}: []
    case Y.O_cone{r, h}: []
    case Y.O_tor{bigR, r}: []
    case Y.O_extrude{prof, depth}: []
    case Y.O_revolve{prof}: []
    case Y.O_holes{base, hs}: [base]
    case Y.O_pocket{base, x, y, w, h, depth}: [base]
    case Y.O_pad{base, x, y, w, h, d}: [base]
    case Y.O_xform{base, xf}: [base]

# Build hash: op tag, dim ids, zone bits (nom, lo, hi), embedded input
# ids, then Node.ins. A change to any of those misses. Unsupported ops
# still hash, and a hit on one is not a publish (nodes_box / ev_op).
def node_hash(+op: Y.Op, ps: List<&2, Y.Param>,
    ins: List<&2, U64>) -> U64:
  +ids = op_dim_ids(op)
  fnv_list(ins, fnv_list(op_in_ids(op), fnv_zones(ids,
    fnv_list(ids, fnv_step(14695981039346656037u64, Y.op_tag(op))),
    ps)))

def ev_wrap(r: Y.SRes, +nw: F64, +nh: F64, +nd: F64) -> Y.SRes:
  match r:
    case Y.Serr{k, dg}: Y.Serr{k, dg}
    case Y.Sok{v}:
      match v:
        case Y.SV_brep{b}:
          Y.sok_body(Y.mk_body(b, 0u64,
            Y.mk_prof([V.V2{0.0f64, 0.0f64}, V.V2{nw, 0.0f64},
              V.V2{nw, nh}, V.V2{0.0f64, nh}], []),
            0.0f64, nd, [], 0n, [], [nw, nh, nd]))
        case _:
          Y.serr_unsupported("box value", "ev_wrap",
            "non-brep box result", "internal: report this")

def ev_box_go(okw: Bool, okh: Bool, okd: Bool, +nw: F64,
    +nh: F64, +nd: F64, +fuel: Nat) -> Y.SRes:
  Bool.pick(Y.SRes, okw,
    Bool.pick(Y.SRes, okh,
      Bool.pick(Y.SRes, okd,
        ev_wrap(O.box_checked(0.0f64, 0.0f64, 0.0f64, nw, nh,
          nd, fuel), nw, nh, nd),
        Y.serr_invalid("box depth", "ev_box", "unknown dim id",
          "add the dim to the part params")),
      Y.serr_invalid("box height", "ev_box", "unknown dim id",
        "add the dim to the part params")),
    Y.serr_invalid("box width", "ev_box", "unknown dim id",
      "add the dim to the part params"))

# A missing id is not a zone error; ev_box_go names the unknown dim.
# A present id whose zone is not lo <= nom <= hi with lo > 0 does not
# build. The solid itself stays the nominal box.
def zone_one(hit: Bool, +d: Y.Dim) -> Bool:
  match hit:
    case False{}: True{}
    case True{}: Y.dm_valid_pos(d)

def ev_box_zone(ok: Bool, +w: U64, +h: U64, +d: U64,
    +ps: List<&2, Y.Param>, +fuel: Nat) -> Y.SRes:
  match ok:
    case False{}:
      Y.serr_invalid("dims", "ev_box", "zone",
        "lo <= nom <= hi and lo > 0")
    case True{}:
      ev_box_go(pm_hit_go(ps, w), pm_hit_go(ps, h), pm_hit_go(ps, d),
        pm_nom_go(ps, w), pm_nom_go(ps, h), pm_nom_go(ps, d), fuel)

def ev_box(+w: U64, +h: U64, +d: U64, +ps: List<&2, Y.Param>,
    +fuel: Nat) -> Y.SRes:
  ev_box_zone(Bool.and(zone_one(pm_hit_go(ps, w), pm_dm_go(ps, w)),
    Bool.and(zone_one(pm_hit_go(ps, h), pm_dm_go(ps, h)),
      zone_one(pm_hit_go(ps, d), pm_dm_go(ps, d)))),
    w, h, d, ps, fuel)

# The only built op. The cache and ev_op share this test so a hit
# cannot publish an op ev_op would reject.
def op_is_box(op: Y.Op) -> Bool:
  match op:
    case Y.O_box{w, h, d}: True{}
    case _: False{}

def nodes_box(ns: List<&2, Y.Node>) -> Bool:
  match ns:
    case []: True{}
    case n <> t:
      match n:
        case Y.Nd{id, op, ins}:
          Bool.and(op_is_box(op), nodes_box(t))

def ev_op_go(ok: Bool, op: Y.Op, +ps: List<&2, Y.Param>,
    +fuel: Nat) -> Y.SRes:
  match ok op:
    case True{} Y.O_box{w, h, d}: ev_box(w, h, d, ps, fuel)
    case _ _:
      Y.serr_unsupported("op", "ev_op", "builder pending",
        "only box is implemented so far")

def ev_op(+op: Y.Op, +ps: List<&2, Y.Param>,
    +fuel: Nat) -> Y.SRes:
  ev_op_go(op_is_box(op), op, ps, fuel)

def fx_of_body(b: Y.Body) -> Y.Effect:
  match b:
    case Y.Bd{+brep, kind, prof, z0, z1, boss, nhole, rh,
      dims}:
      Y.mk_fx(Y.M_create{},
        List.length(&2, Ty.Face, Ty.brep_fas(brep)), 0n,
        List.length(&2, Ty.Shell, Ty.brep_shs(brep)), nhole)

def ev_hashes(ns: List<&2, Y.Node>,
    +ps: List<&2, Y.Param>) -> List<&2, HPair>:
  match ns:
    case []: []
    case n <> t:
      match n:
        case Y.Nd{id, op, ins}:
          HP{id, node_hash(op, ps, ins)} <> ev_hashes(t, ps)

# Fail-fast node walk, self-recursive only. The continue/halt branch
# on the computed node result goes through Bool.pick (a match cannot
# scrutinize it and a dispatch helper would be mutual recursion).
# The shared node result evaluates once; only the taken arm's memo
# entries are demanded.
def sres_is_body(r: Y.SRes) -> Bool:
  match r:
    case Y.Serr{k, dg}: False{}
    case Y.Sok{v}:
      match v:
        case Y.SV_body{b}: True{}
        case _: False{}

def sres_body(r: Y.SRes) -> Y.Body:
  match r:
    case Y.Serr{k, dg}: dummy_body()
    case Y.Sok{v}:
      match v:
        case Y.SV_body{b}: b
        case _: dummy_body()

def gate_go(ok: Bool, mat: Y.MatFx, fc: Nat, fm: Nat, sh: Nat,
    ho: Nat) -> Y.SRes:
  match ok:
    case True{}: Y.sok_fx(Y.mk_fx(mat, fc, fm, sh, ho))
    case False{}:
      Y.serr_invalid("effect", "gate_publish",
        "measured effect differs from declared intent",
        "align the op graph with the intent or update it")

def gate_publish(fx: Y.Effect, it: Y.Intent) -> Y.SRes:
  match fx it:
    case Y.Fx{+mat, +fc, +fm, +sh, +ho} Y.In{imat, ifc, ifm,
      ish, iho}:
      gate_go(Bool.and(Y.matfx_eq(mat, imat),
        Bool.and(Nat.is_eq(fc, ifc),
          Bool.and(Nat.is_eq(fm, ifm),
            Bool.and(Nat.is_eq(sh, ish),
              Nat.is_eq(ho, iho))))),
        mat, fc, fm, sh, ho)

def evm(ns: List<&2, Y.Node>, +ps: List<&2, Y.Param>,
    +nw: List<&2, Y.Built>, +fuel: Nat) -> EvRes:
  match ns:
    case []: EV{Y.Cc{nw}, Y.sok_u(0u64)}
    case n <> t:
      match n:
        case Y.Nd{id, +op, ins}:
          +r = ev_op(op, ps, fuel)
          +sb = sres_body(r)
          Bool.pick(EvRes, sres_is_body(r),
            evm(t, ps,
              bt_cat(nw, [Y.mk_built(id, node_hash(op, ps, ins), sb,
                fx_of_body(sb))]),
              fuel),
            EV{Y.Cc{nw}, r})

# Publish the root body only when its stored effect matches the
# part intent. A mismatch is the gate's invalid-input, not a body.
def ev_root_pub(g: Y.SRes, +cc: Y.Cache, +body: Y.Body) -> EvRes:
  match g:
    case Y.Serr{k, dg}: EV{cc, Y.Serr{k, dg}}
    case Y.Sok{v}: EV{cc, Y.sok_body(body)}

def ev_root2(hit: Bool, bt: Y.Built, rest: List<&2, Y.Built>,
    +cc: Y.Cache, +root: U64, +it: Y.Intent) -> EvRes:
  match hit bt:
    case True{} Y.Bt{bid, bh, body, fx}:
      ev_root_pub(gate_publish(fx, it), cc, body)
    case False{} _:
      EV{cc, Y.serr_invalid("root", "ev_part",
        "root node id not built",
        "point root at a node id in the part")}

def ev_root(out: CcOut, +cc: Y.Cache, +root: U64,
    +it: Y.Intent) -> EvRes:
  match out:
    case CO{hit, bt, rest}: ev_root2(hit, bt, rest, cc, root, it)

def ev_part3(er: EvRes, +root: U64, +it: Y.Intent) -> EvRes:
  match er:
    case EV{+cc, last}:
      match last:
        case Y.Serr{k, dg}: EV{cc, Y.Serr{k, dg}}
        case Y.Sok{v}:
          ev_root(cc_find_id0(cc_items(cc), [], root), cc, root, it)

def ev_part2(hit: Bool, +ps: List<&2, Y.Param>,
    +ns: List<&2, Y.Node>, +root: U64, +old: Y.Cache,
    +fuel: Nat, +it: Y.Intent) -> EvRes:
  match hit:
    case True{}:
      ev_root(cc_find_id0(cc_items(old), [], root), old, root, it)
    case False{}:
      ev_part3(evm(ns, ps, [], fuel), root, it)

def ev_part(p: Y.Part, +old: Y.Cache, +fuel: Nat) -> EvRes:
  match p:
    case Y.Pt{+ps, +ns, root, it}:
      ev_part2(Bool.and(cc_covers(cc_items(old), ev_hashes(ns, ps)),
          nodes_box(ns)), ps, ns, root, old, fuel, it)

# Box lineage names: 6 faces (role 0), 12 edges (role 1), 8 vertices
# (role 2) under the creator node id.
def box_names(+node: U64) -> List<&2, Y.Nm>:
  [Y.mk_nm(node, 0u64, 0n), Y.mk_nm(node, 0u64, 1n),
    Y.mk_nm(node, 0u64, 2n), Y.mk_nm(node, 0u64, 3n),
    Y.mk_nm(node, 0u64, 4n), Y.mk_nm(node, 0u64, 5n),
    Y.mk_nm(node, 1u64, 0n), Y.mk_nm(node, 1u64, 1n),
    Y.mk_nm(node, 1u64, 2n), Y.mk_nm(node, 1u64, 3n),
    Y.mk_nm(node, 1u64, 4n), Y.mk_nm(node, 1u64, 5n),
    Y.mk_nm(node, 1u64, 6n), Y.mk_nm(node, 1u64, 7n),
    Y.mk_nm(node, 1u64, 8n), Y.mk_nm(node, 1u64, 9n),
    Y.mk_nm(node, 1u64, 10n), Y.mk_nm(node, 1u64, 11n),
    Y.mk_nm(node, 2u64, 0n), Y.mk_nm(node, 2u64, 1n),
    Y.mk_nm(node, 2u64, 2n), Y.mk_nm(node, 2u64, 3n),
    Y.mk_nm(node, 2u64, 4n), Y.mk_nm(node, 2u64, 5n),
    Y.mk_nm(node, 2u64, 6n), Y.mk_nm(node, 2u64, 7n)]
