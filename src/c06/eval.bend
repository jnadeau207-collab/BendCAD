import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../base/par.bend as B
import ./types.bend as Y
import ./ops.bend as O

type EvRes is Data:
  EV{ cc: Y.Cache, last: Y.SRes }

type CcOut is Data:
  CO{ hit: Bool, bt: Y.Built }

type NKey is Data:
  NK{ id: U64, key: List<&2, U64> }

type Mt is Data:
  Mt{ ok: Bool, out: List<&2, Y.Built> }

type PX is Data:
  PX{ t: B.Tb<&2, Y.Param>, n: U32 }

def fnv_step(+h: U64, +b: U64) -> U64:
  (U64.mul(h, 1099511628211u64) + b : U64)

def fnv_list(xs: List<&2, U64>, +h: U64) -> U64:
  match xs:
    case []: h
    case b <> t: fnv_list(t, fnv_step(h, b))

def u64_cmp_go(+a: U64, +b: U64) -> B.Sgn:
  B.sgn_pick(U64.is_lt(a, b), U64.is_lt(b, a))

def u64_cmp(a: U64, b: U64) -> B.Sgn:
  u64_cmp_go(a, b)

def so_u64(s: B.So<&2, U64>) -> List<&2, U64>:
  B.So{ok, xs} = s
  xs

def u_adj(xs: List<&2, U64>, +prev: U64, first: Bool) -> Bool:
  match xs:
    case []: True{}
    case +h <> t: Bool.and(Bool.or(first, Bool.not(U64.is_eq(h, prev))), u_adj(t, h, False{}))

def ids_distinct(+xs: List<&2, U64>) -> Bool:
  u_adj(so_u64(B.msort(~U64, ~u64_cmp, xs)), 0u64, True{})

def pm_id(p: Y.Param) -> U64:
  match p:
    case Y.Pm{i, d}: i

def pm_dim(p: Y.Param) -> Y.Dim:
  match p:
    case Y.Pm{i, d}: d

def pm_cmp_go(+a: Y.Param, +b: Y.Param) -> B.Sgn:
  u64_cmp_go(pm_id(a), pm_id(b))

def pm_cmp(a: Y.Param, b: Y.Param) -> B.Sgn:
  pm_cmp_go(a, b)

def so_pm(s: B.So<&2, Y.Param>) -> List<&2, Y.Param>:
  B.So{ok, xs} = s
  xs

def pm_adj(xs: List<&2, Y.Param>, +prev: U64, first: Bool) -> Bool:
  match xs:
    case []: True{}
    case +h <> t:
      Bool.and(Bool.or(first, Bool.not(U64.is_eq(pm_id(h), prev))),
        pm_adj(t, pm_id(h), False{}))

def pm_pad() -> Y.Param:
  Y.Pm{18446744073709551615u64, Y.mk_dm(0.0f64, 0.0f64, 0.0f64)}

def px_mk(+xs: List<&2, Y.Param>) -> PX:
  PX{B.tb_of(Y.Param, xs, pm_pad()), B.ulen(Y.Param, xs)}

def px_of(+ps: List<&2, Y.Param>) -> PX:
  px_mk(so_pm(B.msort(~Y.Param, ~pm_cmp, ps)))

def pt_min(t: B.Tr<&2, Y.Param>) -> U64:
  match t:
    case B.TL{v}: pm_id(v)
    case B.TN{l, r}: pt_min(l)

def pz_of(t: B.Tr<&2, Y.Param>, +k: U64) -> Bool:
  match t:
    case B.TL{v}: False{}
    case B.TN{l, r}: U64.is_lt(k, pt_min(r))

def pf_go(t: B.Tr<&2, Y.Param>, +k: U64, +base: U32, +n: U32,
    z: Bool) -> U32:
  match t z:
    case B.TL{v} _: base
    case B.TN{+l, r} True{}: pf_go(l, k, base, U32.shr(n), pz_of(l, k))
    case B.TN{l, +r} False{}:
      +h = U32.shr(n)
      pf_go(r, k, (base + h : U32), h, pz_of(r, k))

def px_at(+x: PX, +k: U64) -> Y.Param:
  PX{+t, +n} = x
  B.Tb{+m, +tr} = t
  B.tb_get(Y.Param, t, U32.min(pf_go(tr, k, 0, m, pz_of(tr, k)),
    (n - 1 : U32)))

def px_hit(+x: PX, +k: U64) -> Bool:
  PX{t, +n} = x
  Bool.and(U32.is_lt(0, n), U64.is_eq(pm_id(px_at(x, k)), k))

def px_dm(+x: PX, +k: U64) -> Y.Dim:
  Bool.pick(Y.Dim, px_hit(x, k), pm_dim(px_at(x, k)),
    Y.mk_dm(0.0f64, 0.0f64, 0.0f64))

def px_nom(+x: PX, +k: U64) -> F64:
  Y.dm_nom(px_dm(x, k))

def bt_id(x: Y.Built) -> U64:
  match x:
    case Y.Bt{i, k, b, f}: i

def bt_key(x: Y.Built) -> List<&2, U64>:
  match x:
    case Y.Bt{i, k, b, f}: k

def dummy_body() -> Y.Body:
  Y.mk_body(Ty.brep_empty(), 0u64, Y.mk_prof([], []), 0.0f64,
    0.0f64, [], 0n, [], [])

def bt_dummy() -> Y.Built:
  Y.mk_built(0u64, [], dummy_body(),
    Y.mk_fx(Y.M_same{}, 0n, 0n, 0n, 0n))

def cc_items(c: Y.Cache) -> List<&2, Y.Built>:
  match c:
    case Y.Cc{items}: items

def bt_cmp_go(+a: Y.Built, +b: Y.Built) -> B.Sgn:
  u64_cmp_go(bt_id(a), bt_id(b))

def bt_cmp(a: Y.Built, b: Y.Built) -> B.Sgn:
  bt_cmp_go(a, b)

def so_bt(s: B.So<&2, Y.Built>) -> List<&2, Y.Built>:
  B.So{ok, xs} = s
  xs

def nk_id(x: NKey) -> U64:
  match x:
    case NK{i, k}: i

def nk_key(x: NKey) -> List<&2, U64>:
  match x:
    case NK{i, k}: k

def nk_cmp_go(+a: NKey, +b: NKey) -> B.Sgn:
  u64_cmp_go(nk_id(a), nk_id(b))

def nk_cmp(a: NKey, b: NKey) -> B.Sgn:
  nk_cmp_go(a, b)

def so_nk(s: B.So<&2, NKey>) -> List<&2, NKey>:
  B.So{ok, xs} = s
  xs

def keq(xs: List<&2, U64>, ys: List<&2, U64>) -> Bool:
  match xs ys:
    case Nil{} Nil{}: True{}
    case Con{x, xt} Con{y, yt}: Bool.and(U64.is_eq(x, y), keq(xt, yt))
    case _ _: False{}

def dec2(c: B.Sgn, eq: Bool) -> U64:
  match c:
    case B.Sn{}: 0u64
    case B.Sz{}: Bool.pick(U64, eq, 1u64, 0u64)
    case _: 2u64

def dec(keys: List<&2, NKey>, items: List<&2, Y.Built>) -> U64:
  match keys items:
    case Nil{} _: 3u64
    case _ Nil{}: 2u64
    case Con{+k, kt} Con{+b, bt}:
      dec2(u64_cmp_go(bt_id(b), nk_id(k)), keq(bt_key(b), nk_key(k)))

def mt_end(d: U64, acc: List<&2, Y.Built>) -> Mt:
  match d:
    case 3u64: Mt{True{}, List.reverse(&2, Y.Built, acc)}
    case _: Mt{False{}, []}

def mt_go(items: List<&2, Y.Built>, keys: List<&2, NKey>, d: U64,
    acc: List<&2, Y.Built>) -> Mt:
  match items:
    case Nil{}: mt_end(d, acc)
    case b <> +bt:
      match keys:
        case Nil{}: mt_end(d, acc)
        case +k <> +kt:
          match d:
            case 0u64: mt_go(bt, k <> kt, dec(k <> kt, bt), acc)
            case 1u64: mt_go(bt, kt, dec(kt, bt), b <> acc)
            case _: Mt{False{}, []}

def cc_match_go(+items: List<&2, Y.Built>, +keys: List<&2, NKey>) -> Mt:
  +si = so_bt(B.msort(~Y.Built, ~bt_cmp, items))
  +sk = so_nk(B.msort(~NKey, ~nk_cmp, keys))
  mt_go(si, sk, dec(sk, si), [])

def cc_match(+items: List<&2, Y.Built>, keys: List<&2, NKey>) -> Mt:
  match keys:
    case Nil{}: Mt{True{}, []}
    case +k <> +t: cc_match_go(items, k <> t)

def mt_ok(m: Mt) -> Bool:
  match m:
    case Mt{ok, out}: ok

def mt_out(m: Mt) -> List<&2, Y.Built>:
  match m:
    case Mt{ok, out}: out

def cc_covers(+items: List<&2, Y.Built>, +keys: List<&2, NKey>) -> Bool:
  mt_ok(cc_match(items, keys))

def hd_eq(xs: List<&2, Y.Built>, +id: U64) -> Bool:
  match xs:
    case []: False{}
    case c <> u: U64.is_eq(bt_id(c), id)

def cc_find_go(xs: List<&2, Y.Built>, +id: U64, peq: Bool) -> CcOut:
  match xs:
    case []: CO{False{}, bt_dummy()}
    case b <> +t:
      match peq:
        case True{}: CO{True{}, b}
        case False{}: cc_find_go(t, id, hd_eq(t, id))

def cc_find(+xs: List<&2, Y.Built>, +id: U64) -> CcOut:
  cc_find_go(xs, id, hd_eq(xs, id))

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

def bits2(+v: V.Vec2, acc: List<&2, U64>) -> List<&2, U64>:
  V.V2{+x, +y} = v
  F64.bits(x) <> F64.bits(y) <> acc

def pts_w(xs: List<&2, V.Vec2>, acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: acc
    case p <> t: bits2(p, pts_w(t, acc))

def loop_w(+xs: List<&2, V.Vec2>, acc: List<&2, U64>) -> List<&2, U64>:
  U64.from_nat(List.length(&2, V.Vec2, xs)) <> pts_w(xs, acc)

def loops_w(xs: List<&2, List<&2, V.Vec2>>,
    acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: acc
    case h <> t: loop_w(h, loops_w(t, acc))

def prof_w(p: Y.Prof, acc: List<&2, U64>) -> List<&2, U64>:
  match p:
    case Y.Pf{loop, +holes}:
      loop_w(loop,
        U64.from_nat(List.length(&2, List<&2, V.Vec2>, holes)) <>
          loops_w(holes, acc))

def hs_w(xs: List<&2, Y.HoleSpec>, acc: List<&2, U64>) -> List<&2, U64>:
  match xs:
    case []: acc
    case h <> t:
      match h:
        case Y.Hs{x, y, r}:
          F64.bits(x) <> F64.bits(y) <> F64.bits(r) <> hs_w(t, acc)

def rig_w(xf: V.Rigid, acc: List<&2, U64>) -> List<&2, U64>:
  match xf:
    case V.Rg{rot, tx, ty, tz}:
      match rot:
        case V.M3{a, b, c, d, e, f, g, h, i}:
          List.append(&2, U64, [F64.bits(a), F64.bits(b), F64.bits(c),
            F64.bits(d), F64.bits(e), F64.bits(f), F64.bits(g),
            F64.bits(h), F64.bits(i), F64.bits(tx), F64.bits(ty),
            F64.bits(tz)], acc)

def op_extra(op: Y.Op, acc: List<&2, U64>) -> List<&2, U64>:
  match op:
    case Y.O_box{w, h, d}: acc
    case Y.O_cyl{r, h}: acc
    case Y.O_sph{r}: acc
    case Y.O_cone{r, h}: acc
    case Y.O_tor{bigR, r}: acc
    case Y.O_extrude{prof, depth}: prof_w(prof, acc)
    case Y.O_revolve{prof}: prof_w(prof, acc)
    case Y.O_holes{base, +hs}:
      U64.from_nat(List.length(&2, Y.HoleSpec, hs)) <> hs_w(hs, acc)
    case Y.O_pocket{base, x, y, w, h, depth}:
      F64.bits(x) <> F64.bits(y) <> F64.bits(w) <> F64.bits(h) <> acc
    case Y.O_pad{base, x, y, w, h, d}: F64.bits(x) <> F64.bits(y) <> acc
    case Y.O_xform{base, xf}: rig_w(xf, acc)

def zone_w(+x: PX, ids: List<&2, U64>, acc: List<&2, U64>) -> List<&2, U64>:
  match ids:
    case []: acc
    case +i <> t:
      +d = px_dm(x, i)
      F64.bits(Y.dm_nom(d)) <> F64.bits(Y.dm_lo(d)) <>
        F64.bits(Y.dm_hi(d)) <> zone_w(x, t, acc)

def node_key_x(+op: Y.Op, +x: PX, +ins: List<&2, U64>) -> List<&2, U64>:
  +ids = op_dim_ids(op)
  Y.op_tag(op) <> List.append(&2, U64, ids, zone_w(x, ids,
    List.append(&2, U64, op_in_ids(op), op_extra(op, ins))))

def node_key(+op: Y.Op, +ps: List<&2, Y.Param>,
    +ins: List<&2, U64>) -> List<&2, U64>:
  node_key_x(op, px_of(ps), ins)

def node_hash(+op: Y.Op, +ps: List<&2, Y.Param>,
    +ins: List<&2, U64>) -> U64:
  fnv_list(node_key(op, ps, ins), 14695981039346656037u64)

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

def zone_one(hit: Bool, +d: Y.Dim) -> Bool:
  match hit:
    case False{}: True{}
    case True{}: Y.dm_valid_pos(d)

def ev_box_zone(ok: Bool, +w: U64, +h: U64, +d: U64, +x: PX,
    +fuel: Nat) -> Y.SRes:
  match ok:
    case False{}:
      Y.serr_invalid("dims", "ev_box", "zone",
        "lo <= nom <= hi and lo > 0")
    case True{}:
      ev_box_go(px_hit(x, w), px_hit(x, h), px_hit(x, d),
        px_nom(x, w), px_nom(x, h), px_nom(x, d), fuel)

def ev_box_x(+w: U64, +h: U64, +d: U64, +x: PX, +fuel: Nat) -> Y.SRes:
  ev_box_zone(Bool.and(zone_one(px_hit(x, w), px_dm(x, w)),
    Bool.and(zone_one(px_hit(x, h), px_dm(x, h)),
      zone_one(px_hit(x, d), px_dm(x, d)))),
    w, h, d, x, fuel)

def ev_box(+w: U64, +h: U64, +d: U64, +ps: List<&2, Y.Param>,
    +fuel: Nat) -> Y.SRes:
  ev_box_x(w, h, d, px_of(ps), fuel)

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

def ev_op_go(ok: Bool, op: Y.Op, +x: PX, +fuel: Nat) -> Y.SRes:
  match ok op:
    case True{} Y.O_box{w, h, d}: ev_box_x(w, h, d, x, fuel)
    case _ _:
      Y.serr_unsupported("op", "ev_op", "builder pending",
        "only box is implemented so far")

def ev_op_x(+op: Y.Op, +x: PX, +fuel: Nat) -> Y.SRes:
  ev_op_go(op_is_box(op), op, x, fuel)

def ev_op(+op: Y.Op, +ps: List<&2, Y.Param>, +fuel: Nat) -> Y.SRes:
  ev_op_x(op, px_of(ps), fuel)

def fx_of_body(b: Y.Body) -> Y.Effect:
  match b:
    case Y.Bd{+brep, kind, prof, z0, z1, boss, nhole, rh,
      dims}:
      Y.mk_fx(Y.M_create{},
        List.length(&2, Ty.Face, Ty.brep_fas(brep)), 0n,
        List.length(&2, Ty.Shell, Ty.brep_shs(brep)), nhole)

def ev_keys_x(ns: List<&2, Y.Node>, +x: PX) -> List<&2, NKey>:
  match ns:
    case []: []
    case n <> t:
      match n:
        case Y.Nd{id, op, ins}: NK{id, node_key_x(op, x, ins)} <> ev_keys_x(t, x)

def ev_keys(ns: List<&2, Y.Node>, +ps: List<&2, Y.Param>) -> List<&2, NKey>:
  ev_keys_x(ns, px_of(ps))

def nd_id(n: Y.Node) -> U64:
  match n:
    case Y.Nd{id, op, ins}: id

def nd_op(n: Y.Node) -> Y.Op:
  match n:
    case Y.Nd{id, op, ins}: op

def nd_ins(n: Y.Node) -> List<&2, U64>:
  match n:
    case Y.Nd{id, op, ins}: ins

def nd_ids(ns: List<&2, Y.Node>) -> List<&2, U64>:
  match ns:
    case []: []
    case n <> t:
      match n:
        case Y.Nd{id, op, ins}: id <> nd_ids(t)

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

def bt_keep(c: Bool, +x: Y.Built, rest: List<&2, Y.Built>) -> List<&2, Y.Built>:
  match c:
    case True{}: x <> rest
    case False{}: rest

def evm(ns: List<&2, Y.Node>, go: Bool, +x: PX, nw: List<&2, Y.Built>,
    +fuel: Nat, last: Y.SRes) -> EvRes:
  match ns go:
    case _ False{}: EV{Y.Cc{List.reverse(&2, Y.Built, nw)}, last}
    case Nil{} True{}: EV{Y.Cc{List.reverse(&2, Y.Built, nw)}, Y.sok_u(0u64)}
    case Con{+n, t} True{}:
      +op = nd_op(n)
      +ins = nd_ins(n)
      +id = nd_id(n)
      +r = ev_op_x(op, x, fuel)
      +sb = sres_body(r)
      evm(t, sres_is_body(r), x,
        bt_keep(sres_is_body(r), Y.mk_built(id, node_key_x(op, x, ins),
          sb, fx_of_body(sb)), nw),
        fuel, r)

def ev_root_pub(g: Y.SRes, +cc: Y.Cache, +body: Y.Body) -> EvRes:
  match g:
    case Y.Serr{k, dg}: EV{cc, Y.Serr{k, dg}}
    case Y.Sok{v}: EV{cc, Y.sok_body(body)}

def ev_root2(hit: Bool, bt: Y.Built, +cc: Y.Cache,
    +it: Y.Intent) -> EvRes:
  match hit bt:
    case True{} Y.Bt{bid, bk, body, fx}:
      ev_root_pub(gate_publish(fx, it), cc, body)
    case False{} _:
      EV{cc, Y.serr_invalid("root", "ev_part",
        "root node id not built",
        "point root at a node id in the part")}

def ev_root(out: CcOut, +cc: Y.Cache, +it: Y.Intent) -> EvRes:
  match out:
    case CO{hit, bt}: ev_root2(hit, bt, cc, it)

def ev_part3(er: EvRes, +root: U64, +it: Y.Intent) -> EvRes:
  match er:
    case EV{+cc, last}:
      match last:
        case Y.Serr{k, dg}: EV{cc, Y.Serr{k, dg}}
        case Y.Sok{v}: ev_root(cc_find(cc_items(cc), root), cc, it)

def ev_part2(hit: Bool, +mt: List<&2, Y.Built>, +x: PX,
    +ns: List<&2, Y.Node>, +root: U64, +old: Y.Cache, +fuel: Nat,
    +it: Y.Intent) -> EvRes:
  match hit:
    case True{}: ev_root(cc_find(mt, root), old, it)
    case False{}:
      ev_part3(evm(ns, True{}, x, [], fuel, Y.sok_u(0u64)), root, it)

def ev_part_v(ok: Bool, +sp: List<&2, Y.Param>, +ns: List<&2, Y.Node>,
    +root: U64, +old: Y.Cache, +fuel: Nat, +it: Y.Intent) -> EvRes:
  match ok:
    case False{}:
      EV{old, Y.serr_invalid("ids", "ev_part",
        "duplicate node or param id",
        "give every node and every param a distinct id")}
    case True{}:
      +x = px_mk(sp)
      +m = cc_match(cc_items(old), ev_keys_x(ns, x))
      ev_part2(Bool.and(mt_ok(m), nodes_box(ns)), mt_out(m), x, ns,
        root, old, fuel, it)

def ev_part(p: Y.Part, +old: Y.Cache, +fuel: Nat) -> EvRes:
  match p:
    case Y.Pt{+ps, +ns, root, it}:
      +sp = so_pm(B.msort(~Y.Param, ~pm_cmp, ps))
      ev_part_v(Bool.and(pm_adj(sp, 0u64, True{}), ids_distinct(nd_ids(ns))),
        sp, ns, root, old, fuel, it)

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
