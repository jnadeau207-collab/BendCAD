import Base
import ../c00/types.bend as T
import ../c03/types.bend as G
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ./iv.bend as I
import ./xp.bend as X
import ./build.bend as BD
import ./model.bend as M
import ./sx.bend as S
import ../c16/sheet.bend as SH
import ../c16/surf.bend as SU
import ../c16/blade.bend as BA
import ./tess.bend as TS
import ../c10/mesh.bend as M10
import ./zone.bend as Z
import ../c07/gsx.bend as GQ
import ../c08/bool.bend as BO
import ../c11/qdist.bend as QD
import ../c11/qmass.bend as QM
import ../c11/qsect.bend as QN
import ../c11/qinterf.bend as QI
import ../c12/blob.bend as BL
import ../c12/stepw.bend as SW
import ../c12/stepr.bend as SR
import ../c12/mesh.bend as MO
import ../c14/asm.bend as AS
import ../c15/pmi.bend as PM
import ../k2/mat.bend as KM
import ../k2/thr.bend as KT
import ../c13/err.bend as E
import ../c13/req.bend as R

def iv_s(+v: I.I) -> String:
  "[" ++ S.f_show(I.i_lo(v)) ++ ", " ++ S.f_show(I.i_hi(v)) ++ "]"

def z_kind(+w: String) -> String:
  Bool.pick(String, String.eq(w, "topology-not-certified-over-zone"), "numerical-uncertainty", "invalid-input")

def z_fix(+w: String) -> String:
  Bool.pick(String, String.eq(w, "topology-not-certified-over-zone"), "narrow the zones or keep profile segments, holes and feature footprints apart over the whole envelope; arcs must meet their endpoints for every parameter value",
    Bool.pick(String, String.eq(w, "node-failed-at-nominal"), "fix the node at its nominal parameters first (eval)",
    Bool.pick(String, String.eq(w, "dimension-not-certified-positive-over-zone"), "narrow the zones so every dimension stays positive (torus: R > r)",
      Bool.pick(String, String.eq(w, "zone-not-ordered"), "give every parameter lo <= nom <= hi", "name an existing node"))))

def z_fix_on(+w: String, +bo: Bool) -> String:
  match bo:
    case False{}: z_fix(w)
    case True{}: Bool.pick(String, String.eq(w, "topology-not-certified-over-zone"),
      "union, difference and intersection refuse before any zone split; narrowing zones or separating profile features does not certify them",
      z_fix(w))

def zone_s(r: Z.ZR, +id: U64, +bo: Bool) -> String:
  match r:
    case Z.Z_ok{v, a}: "zone node " ++ U64.show(id) ++ ": certified over the tolerance envelope | volume=" ++ iv_s(v) ++ " area=" ++ iv_s(a)
    case Z.Z_err{+w}: "error " ++ z_kind(w) ++ " | zone @ node " ++ U64.show(id) ++ " | why: " ++ w ++ " | fix: " ++ z_fix_on(w, bo)

def zone_line(+p: M.Part, +id: U64) -> String:
  zone_s(Z.zone(p, id), id, Z.z_bool(p, id))

def ms_s(m: M.Ms) -> String:
  M.Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  "volume=" ++ iv_s(vol) ++ " area=" ++ iv_s(area) ++ " bbox=[" ++ S.f_show(x0) ++ ", " ++ S.f_show(x1) ++ "]x[" ++
    S.f_show(y0) ++ ", " ++ S.f_show(y1) ++ "]x[" ++ S.f_show(z0) ++ ", " ++ S.f_show(z1) ++ "] vertices=" ++
    Nat.show(nv) ++ " edges=" ++ Nat.show(ne) ++ " faces=" ++ Nat.show(nf) ++ " solids=" ++ Nat.show(ns) ++
    " genus=" ++ Nat.show(genus) ++ " linear_uncertainty=" ++ S.f_show(lin)

def proof_s(+pr: String) -> String:
  Bool.pick(String, String.eq(pr, ""), "", " | proof: " ++ pr)

def nr_s(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      E.line(k, w, l, y, f)
    case M.NR_ok{+b, fx}: "ok " ++ M.fx_show(fx) ++ " | " ++ ms_s(M.body_ms(b)) ++ proof_s(M.xb_pr(M.bd_xb(b)))

def ces_s(cs: List<&2, M.CE>) -> String:
  match cs:
    case []: ""
    case c <> t:
      M.CE{id, key, r} = c
      "node " ++ U64.show(id) ++ ": " ++ nr_s(r) ++ "\n" ++ ces_s(t)

def ces_ok(cs: List<&2, M.CE>) -> Bool:
  match cs:
    case []: True{}
    case c <> t:
      M.CE{id, key, r} = c
      Bool.and(M.nr_ok(r), ces_ok(t))

def diag_ce(c: M.CE) -> String:
  match c:
    case M.CE{+id, key, +r}:
      match r:
        case M.NR_ok{b, fx}: E.json_ok(id)
        case M.NR_err{k, d}:
          M.Dg{w, l, y, f} = d
          E.json_err(id, k, w, l, y, f)

def diag_s(cs: List<&2, M.CE>) -> String:
  match cs:
    case []: ""
    case c <> t: diag_ce(c) ++ "\n" ++ diag_s(t)

def pm_name(p: M.Param) -> String:
  M.Pm{id, name, dim} = p
  name

def pm_idv(p: M.Param) -> U64:
  M.Pm{id, name, dim} = p
  id

def max_id(ps: List<&2, M.Param>, +m: U64) -> U64:
  match ps:
    case []: m
    case p <> t: max_id(t, U64.max(m, pm_idv(p)))

def pm_set(ps: List<&2, M.Param>, +name: String, +d: M.Dim) -> List<&2, M.Param>:
  match ps:
    case []: []
    case +p <> +t: Bool.pick(List<&2, M.Param>, String.eq(pm_name(p), name), M.Pm{pm_idv(p), name, d} <> t, p <> pm_set(t, name, d))

def pm_has(ps: List<&2, M.Param>, +name: String) -> Bool:
  match ps:
    case []: False{}
    case p <> t: Bool.or(String.eq(pm_name(p), name), pm_has(t, name))

def nd_idv(n: M.Node) -> U64:
  M.Nd{id, op, it} = n
  id

def nd_set(ns: List<&2, M.Node>, +n: M.Node) -> List<&2, M.Node>:
  match ns:
    case []: [n]
    case +x <> +t: Bool.pick(List<&2, M.Node>, U64.is_eq(nd_idv(x), nd_idv(n)), n <> t, x <> nd_set(t, n))

def nd_del(ns: List<&2, M.Node>, +id: U64) -> List<&2, M.Node>:
  match ns:
    case []: []
    case +x <> +t: Bool.pick(List<&2, M.Node>, U64.is_eq(nd_idv(x), id), t, x <> nd_del(t, id))

def dim_of(+xs: List<&2, S.Sx>) -> M.Dim:
  +nom = S.some_v(S.num(S.sx_s(S.sx_nth(xs, 2n))))
  +lo = S.num(S.sx_s(S.sx_nth(xs, 3n)))
  +hi = S.num(S.sx_s(S.sx_nth(xs, 4n)))
  M.Dm{nom, Bool.pick(F64, S.is_some(lo), S.some_v(lo), nom), Bool.pick(F64, S.is_some(hi), S.some_v(hi), nom)}

def edit_param(+p: M.Part, +xs: List<&2, S.Sx>) -> M.Part:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +name = S.sx_s(S.sx_nth(xs, 1n))
  +d = dim_of(xs)
  Bool.pick(M.Part, pm_has(ps, name), M.Pt{pm_set(ps, name, d), ns, ms, ts},
    M.Pt{List.append(&2, M.Param, ps, [M.Pm{(max_id(ps, 0u64) + 1u64 : U64), name, d}]), ns, ms, ts})

def edit_node(+p: M.Part, +x: S.Sx) -> M.Part:
  M.Pt{+ps, ns, +ms, +ts} = p
  +xs = S.sx_xs(x)
  +ni = S.nis_of(ps)
  M.Pt{ps, nd_set(ns, M.Nd{S.u64_of(S.sx_nth(xs, 1n)), S.op_of(S.sx_nth(xs, 2n), ni), S.it_of(S.sx_nth(xs, 3n))}), ms, ts}

def edit_del(+p: M.Part, +xs: List<&2, S.Sx>) -> M.Part:
  M.Pt{ps, ns, +ms, +ts} = p
  M.Pt{ps, nd_del(ns, S.u64_of(S.sx_nth(xs, 1n))), ms, ts}

def edit_mat(+p: M.Part, +x: S.Sx) -> M.Part:
  M.Pt{+ps, +ns, +ms, +ts} = p
  M.Pt{ps, ns, KM.mat_set(ms, S.mt_of(x)), ts}

def edit_thr(+p: M.Part, +x: S.Sx) -> M.Part:
  M.Pt{+ps, +ns, +ms, +ts} = p
  M.Pt{ps, ns, ms, KT.th_set(ts, S.th_of(x))}

def edit_one(+p: M.Part, +x: S.Sx) -> M.Part:
  +xs = S.sx_xs(x)
  Bool.pick(M.Part, S.head_is(x, "param"), edit_param(p, xs),
    Bool.pick(M.Part, S.head_is(x, "node"), edit_node(p, x), Bool.pick(M.Part, S.head_is(x, "delete"), edit_del(p, xs),
      Bool.pick(M.Part, S.head_is(x, "material"), edit_mat(p, x), Bool.pick(M.Part, S.head_is(x, "thread"), edit_thr(p, x), p)))))

def fin_of(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{+v}: Bool.pick(F64, T.is_finite(v), v, F64.nan())

def pm_ok(+xs: List<&2, S.Sx>) -> Bool:
  +n = List.length(&2, S.Sx, xs)
  +nom = fin_of(S.num(S.sx_s(S.sx_nth(xs, 2n))))
  +lo = Bool.pick(F64, Nat.is_eq(n, 3n), nom, fin_of(S.num(S.sx_s(S.sx_nth(xs, 3n)))))
  +hi = Bool.pick(F64, Nat.is_eq(n, 3n), nom, fin_of(S.num(S.sx_s(S.sx_nth(xs, 4n)))))
  Bool.and(Bool.or(Nat.is_eq(n, 3n), Nat.is_eq(n, 5n)), Bool.and(F64.is_le(lo, nom), F64.is_le(nom, hi)))

def thr_ok(+xs: List<&2, S.Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 8n), S.nat_ok(S.sx_nth(xs, 1n)))

def mat_ok(+xs: List<&2, S.Sx>) -> Bool:
  Bool.and(Nat.is_eq(List.length(&2, S.Sx, xs), 5n), S.nat_ok(S.sx_nth(xs, 1n)))

def edit_ok(+x: S.Sx) -> Bool:
  Bool.or(Bool.and(S.head_is(x, "param"), pm_ok(S.sx_xs(x))), Bool.or(S.head_is(x, "node"), Bool.or(S.head_is(x, "delete"),
    Bool.or(Bool.and(S.head_is(x, "material"), mat_ok(S.sx_xs(x))), Bool.and(S.head_is(x, "thread"), thr_ok(S.sx_xs(x)))))))

def edits_ok(xs: List<&2, S.Sx>) -> Bool:
  match xs:
    case []: True{}
    case x <> t: Bool.and(edit_ok(x), edits_ok(t))

def edits(xs: List<&2, S.Sx>, +p: M.Part) -> M.Part:
  match xs:
    case []: p
    case x <> t: edits(t, edit_one(p, x))

def str_cat(xs: List<&2, String>) -> String:
  match xs:
    case []: ""
    case x <> t: x ++ " " ++ str_cat(t)

def fn_s_b(+f: BD.Fn) -> String:
  BD.fn_base(f)

def fn_s(+f: BD.Fn) -> String:
  BD.fn_name(f)

def surf_s(s: G.GVal) -> String:
  match s:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_bp{w}: "planar-patch"
    case G.GV_sp{w}: "sphere"
    case G.GV_co{w}: "cone"
    case G.GV_to{w}: "torus"
    case _: "other"

def v3_s(+x: F64, +y: F64, +z: F64) -> String:
  "(" ++ F64.show(F64.add(x, 0.0f64)) ++ "," ++ F64.show(F64.add(y, 0.0f64)) ++ "," ++ F64.show(F64.add(z, 0.0f64)) ++ ")"

def wdir_s(+d: V.Dir, +pl: M.Pl) -> String:
  M.Pl{+m, tx, ty, tz, mi, ti} = pl
  +v = M.m3_ap(m, V.dr_x(d), V.dr_y(d), V.dr_z(d))
  v3_s(M.f_nth(v, 0n), M.f_nth(v, 1n), M.f_nth(v, 2n))

def frame_s(+a: Ty.Face, +pl: M.Pl) -> String:
  +fr = M.frame_of(a)
  +o = TS.pl_pt(M.fr_o(fr), pl)
  Bool.pick(String, M.fa_planar(a),
    " frame o=" ++ v3_s(V.pt_x(o), V.pt_y(o), V.pt_z(o)) ++ " x=" ++ wdir_s(M.fr_u(fr), pl) ++ " y=" ++
      wdir_s(M.fr_w(fr), pl) ++ " n=" ++ wdir_s(M.fr_n(fr), pl), "")

def faces_s(fs: List<&2, BD.Fn>, fas: List<&2, Ty.Face>, +pl: M.Pl, +v: Bool) -> String:
  match fs:
    case []: ""
    case f <> t:
      match fas:
        case []: ""
        case +a <> u:
          Ty.Fa{g, s, ls, same, slv, sla} = a
          fn_s(f) ++ " " ++ surf_s(s) ++ " loops=" ++ Nat.show(List.length(&2, Ty.HLoop, ls)) ++ Bool.pick(String, v, frame_s(a, pl), "") ++ "\n" ++ faces_s(t, u, pl, v)

def delv_s(d: BO.Del) -> String:
  "deleted " ++ BO.del_show(d) ++ "\n"

def dels_v(ds: List<&2, BO.Del>) -> String:
  match ds:
    case []: ""
    case d <> t: delv_s(d) ++ dels_v(t)

def node_faces_vf(r: M.NR, +verbose: Bool, +frames: Bool) -> String:
  match r:
    case M.NR_err{k, d}: "node failed\n"
    case M.NR_ok{+b, fx}:
      +s = faces_s(M.bd_fns(b), Ty.brep_fas(M.bd_brep(b)), M.bd_pl(b), frames)
      Bool.pick(String, verbose, s ++ dels_v(M.xb_dl(M.bd_xb(b))), s)

def node_faces_v(r: M.NR, +verbose: Bool) -> String:
  node_faces_vf(r, verbose, False{})

def node_faces(r: M.NR) -> String:
  node_faces_v(r, False{})

def node_res(cs: List<&2, M.CE>, +id: U64) -> M.NR:
  M.ce_r(M.ce_find(cs, id))

def mass_tail(r: M.NR, +m: Maybe<&2, M.Grade>) -> String:
  match r:
    case M.NR_err{k, dg}: ""
    case M.NR_ok{+b, fx}: KM.mass_line(m, M.ms_vol(M.body_ms(b)))

def threads_out(+p: M.Part, +n: U64) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +r = node_res(M.ev_part(p, []), n)
  Bool.pick(String, M.nr_ok(r), "threads node " ++ U64.show(n) ++ "
" ++ KT.ths_of_node(ts, n, M.nr_body(r)), "error: node failed; nothing listed")

def mass_out(+p: M.Part, +n: U64, +d: Nat) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +cs = M.ev_part(p, [])
  QM.mass_s(node_res(cs, n), d) ++ "
" ++ mass_tail(node_res(cs, n), KM.mat_find(ms, n))

def pm_nom(ps: List<&2, M.Param>, +name: String) -> F64:
  match ps:
    case []: F64.nan()
    case p <> t:
      M.Pm{id, n, d} = p
      M.Dm{nom, lo, hi} = d
      Bool.pick(F64, String.eq(n, name), nom, pm_nom(t, name))

def pm_bump(ps: List<&2, M.Param>, +name: String, +dv: F64) -> List<&2, M.Param>:
  match ps:
    case []: []
    case p <> t:
      M.Pm{+id, +n, +d} = p
      M.Dm{+nom, +lo, +hi} = d
      Bool.pick(M.Param, String.eq(n, name), M.Pm{id, n, M.Dm{F64.add(nom, dv), lo, hi}}, M.Pm{id, n, d}) <> pm_bump(t, name, dv)

def ms_vec(m: M.Ms) -> List<&2, F64>:
  M.Ms{vol, area, x0, x1, y0, y1, z0, z1, nv, ne, nf, ns, genus, lin} = m
  [I.imid(vol), I.imid(area), x0, x1, y0, y1, z0, z1]

def fd(xs: List<&2, F64>, ys: List<&2, F64>, +h2: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case x <> t:
      match ys:
        case []: []
        case y <> u: F64.div(F64.sub(x, y), h2) <> fd(t, u, h2)

def fns_eq(a: List<&2, BD.Fn>, b: List<&2, BD.Fn>) -> Bool:
  match a b:
    case Nil{} Nil{}: True{}
    case Con{x, xt} Con{y, yt}: Bool.and(M.keq(M.fn_w(x), M.fn_w(y)), fns_eq(xt, yt))
    case _ _: False{}

def sens_lbl() -> List<&2, String>:
  ["d_volume", "d_area", "d_xmin", "d_xmax", "d_ymin", "d_ymax", "d_zmin", "d_zmax"]

def sens_lines(ls: List<&2, String>, vs: List<&2, F64>) -> String:
  match ls:
    case []: ""
    case l <> t:
      match vs:
        case []: ""
        case v <> u: l ++ "=" ++ S.f_show(v) ++ " " ++ sens_lines(t, u)

def sens_go(a: M.NR, b: M.NR, c: M.NR, +h: F64) -> String:
  match a:
    case M.NR_err{k, d}: "error: the nominal design fails at this node"
    case M.NR_ok{+ba, fa}:
      match b:
        case M.NR_err{k, d}: "no derivative: the design fails within the step (h=" ++ S.f_show(h) ++ ")"
        case M.NR_ok{+bb, fb}:
          match c:
            case M.NR_err{k, d}: "no derivative: the design fails within the step (h=" ++ S.f_show(h) ++ ")"
            case M.NR_ok{+bc, fc}:
              Bool.pick(String, Bool.and(fns_eq(M.bd_fns(ba), M.bd_fns(bb)), fns_eq(M.bd_fns(ba), M.bd_fns(bc))),
                "estimated central difference h=" ++ S.f_show(h) ++ " " ++
                  sens_lines(sens_lbl(), fd(ms_vec(M.body_ms(bb)), ms_vec(M.body_ms(bc)), F64.mul(2.0f64, h))),
                "no derivative: topology changes within the step (h=" ++ S.f_show(h) ++ ")")

def reuse_n(a: List<&2, M.CE>, b: List<&2, M.CE>) -> Nat:
  match a:
    case []: 0n
    case x <> t:
      match b:
        case []: 0n
        case y <> u: Nat.add(Bool.pick(Nat, M.keq(M.ce_key(x), M.ce_key(y)), 1n, 0n), reuse_n(t, u))

def sens_rep(+s: String, +c0: List<&2, M.CE>, +cp: List<&2, M.CE>) -> String:
  s ++ "| reused " ++ Nat.show(reuse_n(cp, c0)) ++ " of " ++ Nat.show(List.length(&2, M.CE, cp)) ++ " nodes per step"

def sens(+p: M.Part, +name: String, +id: U64) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +nom = pm_nom(ps, name)
  +h = F64.mul(F64.max(F64.abs(nom), 1.0f64), 9.5367431640625e-07f64)
  +c0 = M.ev_part(p, [])
  +cp = M.ev_part(M.Pt{pm_bump(ps, name, h), ns, ms, ts}, c0)
  +cm = M.ev_part(M.Pt{pm_bump(ps, name, F64.neg(h)), ns, ms, ts}, c0)
  Bool.pick(String, T.is_finite(nom), sens_rep(sens_go(node_res(c0, id), node_res(cp, id), node_res(cm, id), h), c0, cp), "error: unknown parameter " ++ name)

def arg_drop(xs: List<&2, String>, +i: Nat) -> List<&2, String>:
  match xs:
    case []: []
    case x <> +t:
      match i:
        case 0n: x <> t
        case 1n+j: arg_drop(t, j)

def edits_parse(xs: List<&2, String>) -> S.PS:
  S.parse(str_cat(xs))

law read_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(String)

def read_go(m):
  (f, r) = m
  do IO<String>:
    data : String <- IO.pass(String, r)
    x : Unit <- File.close(f)
    return data

law size_go:
  for m: File & Result<&1, &1, (U32 & String), U32>
  IO(String)

def size_go(m):
  (f, r) = m
  do IO<String>:
    n : U32 <- IO.pass(U32, r)
    d : File & Result<&1, &1, (U32 & String), String> <- File.read(f, U32.add(n, 1))
    read_go(d)

law read_file:
  for path: String
  IO(String)

def read_file(path):
  do IO<String>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, (U32 & String), U32> <- File.size(f)
    size_go(m)

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law write_file:
  for path: String
  for data: String
  IO(Unit)

def write_file(path, data):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, data)
    write_go(w)

law write_bytes:
  for path: String
  for data: List<&2, U32>
  IO(Unit)

def write_bytes(path, data):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write_bytes(f, data)
    write_go(w)

def load(+src: String) -> M.Part:
  S.part_of(S.ps_xs(S.parse(src)))

def commit_go(ok: Bool, +path: String, +p: M.Part) -> IO(Unit):
  match ok:
    case True{}:
      do IO<Unit>:
        w : Unit <- write_file(path, S.part_show(p))
        IO.print("committed")
    case False{}: IO.print("rejected: the design was not changed")

def part_errs(+p: M.Part, +cs: List<&2, M.CE>) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  KM.mats_err(ms, cs) ++ KT.ths_err(ts, cs)

def commit_e(+path: String, +p: M.Part, +cs: List<&2, M.CE>, +errs: String) -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(ces_s(cs) ++ errs)
    commit_go(Bool.and(ces_ok(cs), String.eq(errs, "")), path, p)

def commit(+path: String, +p: M.Part, +cs: List<&2, M.CE>) -> IO(Unit):
  commit_e(path, p, cs, part_errs(p, cs))

def apply_go(ok: Bool, +path: String, +p: M.Part) -> IO(Unit):
  match ok:
    case False{}: IO.print("error invalid-input | apply | why: edits must be (param NAME NOM [LO HI]) with finite numbers LO <= NOM <= HI, (node ID OP INTENT) or (delete ID) | fix: correct the edit syntax")
    case True{}: commit(path, p, M.ev_part(p, []))

def cmd_code(+c: String) -> U64:
  Bool.pick(U64, String.eq(c, "show"), 1u64, Bool.pick(U64, String.eq(c, "eval"), 2u64,
  Bool.pick(U64, String.eq(c, "faces"), 3u64, Bool.pick(U64, String.eq(c, "measure"), 4u64,
  Bool.pick(U64, String.eq(c, "sens"), 5u64, Bool.pick(U64, String.eq(c, "apply"), 6u64, Bool.pick(U64, String.eq(c, "tess"), 7u64, Bool.pick(U64, String.eq(c, "zone"), 8u64,
  Bool.pick(U64, String.eq(c, "classify"), 9u64, Bool.pick(U64, String.eq(c, "check"), 10u64,
  Bool.pick(U64, String.eq(c, "dist"), 11u64, Bool.pick(U64, String.eq(c, "extrema"), 12u64,
  Bool.pick(U64, String.eq(c, "mass"), 13u64, Bool.pick(U64, String.eq(c, "section"), 14u64,
  Bool.pick(U64, String.eq(c, "interf"), 15u64, Bool.pick(U64, String.eq(c, "clearance"), 16u64,
  Bool.pick(U64, String.eq(c, "wall"), 17u64, Bool.pick(U64, String.eq(c, "step"), 18u64,
  Bool.pick(U64, String.eq(c, "archive"), 19u64, Bool.pick(U64, String.eq(c, "stl"), 20u64,
  Bool.pick(U64, String.eq(c, "3mf"), 21u64, Bool.pick(U64, String.eq(c, "asm"), 22u64,
  Bool.pick(U64, String.eq(c, "pmi"), 23u64,
  Bool.pick(U64, String.eq(c, "flat"), 24u64,
  Bool.pick(U64, String.eq(c, "surf"), 25u64,
  Bool.pick(U64, String.eq(c, "blade"), 26u64, Bool.pick(U64, String.eq(c, "diag"), 27u64,
  Bool.pick(U64, String.eq(c, "threads"), 28u64, 0u64))))))))))))))))))))))))))))

def apply_parsed(r: S.PS, +path: String, +p: M.Part) -> IO(Unit):
  S.PS{+ok, +xs} = r
  apply_go(Bool.and(ok, edits_ok(xs)), path, edits(xs, p))

def f_or_nan(m: Maybe<&2, F64>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{v}: v

def tess_pn(m: Maybe<&2, U64>) -> U64:
  match m:
    case None{}: 99u64
    case Some{v}: v

def tess_p_go(+e: Bool, +arg: String) -> U64:
  match e:
    case True{}: 1u64
    case False{}: tess_pn(U64.read(arg))

def tess_p(+arg: String) -> U64:
  tess_p_go(String.eq(arg, ""), arg)

def tess_f(+arg: String, +dflt: F64) -> F64:
  Bool.pick(F64, String.eq(arg, ""), dflt, f_or_nan(S.dec(arg)))

def tess_mx(+arg: String, +dflt: Nat) -> Nat:
  Bool.pick(Nat, String.eq(arg, ""), dflt, U64.to_nat(S.u64_of(S.Sx_a{arg})))

def tess_prof(+arg: String, +dflt: U64) -> U64:
  Bool.pick(U64, String.eq(arg, ""), dflt, Bool.pick(U64, String.eq(arg, "display"), 0u64,
    Bool.pick(U64, String.eq(arg, "manufacturing"), 1u64, 9u64)))

def tess_q_err(+a2: String, +p: U64, +q: M10.Q) -> String:
  Bool.pick(String, Bool.not(U64.is_le(p, M10.q_preset_max())),
    "error invalid-input | tess | why: preset " ++ a2 ++ " needs 0..3" ++
      " | fix: tess NODE OUT [0|1|2|3] [CHORD] [ANGLE] [MAXTRIS] [display|manufacturing]",
  Bool.pick(String, Bool.not(T.tol_pos(M10.q_chord(q))),
    "error invalid-input | tess | why: chord needs a positive finite number" ++
      " | fix: give CHORD in millimetres, or omit it for the preset value",
  Bool.pick(String, Bool.not(T.tol_pos(M10.q_angle(q))),
    "error invalid-input | tess | why: angle needs a positive finite number" ++
      " | fix: give ANGLE in radians, or omit it for the preset value",
  Bool.pick(String, Nat.is_eq(M10.q_max(q), 0n),
    "error invalid-input | tess | why: max-tris needs a positive integer" ++
      " | fix: give MAXTRIS, or omit it for the preset value",
  Bool.pick(String, Bool.not(M10.q_prof_ok(q)),
    "error invalid-input | tess | why: profile needs display or manufacturing" ++
      " | fix: give display or manufacturing, or omit it for the preset value", "")))))

def prof_s(+p: U64) -> String:
  Bool.pick(String, U64.is_eq(p, 1u64), "manufacturing", "display")

def tess_write_ok(+t: M10.Tres, +out: String, +q: M10.Q) -> IO(Unit):
  do IO<Unit>:
    w : Unit <- write_file(out, M10.tres_obj(t))
    IO.print("wrote " ++ out ++ " nverts " ++ Nat.show(M10.tres_nv(t)) ++ " ntris " ++ Nat.show(M10.tres_nt(t)) ++
      " est " ++ Nat.show(M10.tres_est(t)) ++ " chord " ++ S.f_show(M10.tres_chord(t)) ++
      " ang " ++ S.f_show(M10.tres_ang(t)) ++ " nsamp " ++ Nat.show(M10.tres_nsamp(t)) ++
      " profile " ++ prof_s(M10.q_prof(q)) ++ " (sampled, not certified)")

def tess_write_go(+ok: Bool, +t: M10.Tres, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match ok:
    case True{}: tess_write_ok(t, out, q)
    case False{}: IO.print("refused " ++ M10.tres_why(t) ++ " | tess @ node " ++ U64.show(id) ++
      " | est " ++ Nat.show(M10.tres_est(t)) ++ " max " ++ Nat.show(M10.q_max(q)) ++
      " | fix: coarsen quality (preset 0, larger chord/angle) or raise max-tris")

def tess_write(+t: M10.Tres, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  tess_write_go(M10.tres_ok_of(t), t, out, id, q)

def tess_out(r: M.NR, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match r:
    case M.NR_err{k, d}: IO.print("error: node failed; nothing tessellated")
    case M.NR_ok{+b, fx}: tess_write(TS.body_q(b, q), out, id, q)

def tess_with(+bad: Bool, r: M.NR, +out: String, +id: U64, +a2: String, +p: U64, +q: M10.Q) -> IO(Unit):
  match bad:
    case True{}: IO.print(tess_q_err(a2, p, q))
    case False{}: tess_out(r, out, id, q)

def tess_args(r: M.NR, +out: String, +id: U64, +a2: String, +a3: String, +a4: String, +a5: String, +a6: String) -> IO(Unit):
  +p = tess_p(a2)
  +base = M10.q_preset(p)
  +q = M10.q_mk(tess_f(a3, M10.q_chord(base)), tess_f(a4, M10.q_angle(base)), tess_mx(a5, M10.q_max(base)),
    tess_prof(a6, M10.q_prof(base)))
  tess_with(Bool.not(String.eq(tess_q_err(a2, p, q), "")), r, out, id, a2, p, q)

def f_arg(+xs: List<&2, String>, +i: Nat) -> F64:
  f_or_nan(S.dec(S.arg_at(xs, i)))

def step_write_go(+w: Bool, +r: SW.WS, +out: String) -> IO(Unit):
  match w:
    case True{}:
      do IO<Unit>:
        u : Unit <- write_file(out, SW.ws_s(r))
        IO.print("wrote " ++ out ++ " entities " ++ Nat.show(SW.ws_nent(r)) ++ " products " ++
          Nat.show(SW.ws_nprod(r)))
    case False{}: IO.print("refused " ++ SW.ws_why(r) ++ " | step | fix: keep analytic curves, trim-seg coedges and plane/sphere/cylinder/torus/bezier-patch faces")

def step_out(r: M.NR, +out: String) -> IO(Unit):
  match r:
    case M.NR_err{k, d}: IO.print("error: node failed; nothing exported")
    case M.NR_ok{+b, fx}:
      +w = SW.sw_ms(b)
      step_write_go(SW.ws_ok(w), w, out)

def arc_write_go(+w: Bool, +e: BL.ES, +out: String) -> IO(Unit):
  match w:
    case True{}:
      do IO<Unit>:
        u : Unit <- write_file(out, BL.es_s(e))
        IO.print("wrote " ++ out ++ " archive " ++ BL.ar_ver())
    case False{}: IO.print("refused " ++ BL.es_why(e) ++ " | archive | fix: keep analytic curves and plane/sphere/cylinder/torus/bezier-patch faces")

def arc_out_open(+open: Bool, +b: M.Body, +out: String, +lin: String) -> IO(Unit):
  match open:
    case True{}: IO.print("refused archive-open-shell-not-in-profile | archive | fix: thicken-open the shell to a solid first")
    case False{}:
      +e = BL.ar_mk("mm", lin, M.bd_brep(b))
      arc_write_go(BL.es_ok_of(e), e, out)

def arc_out(r: M.NR, +out: String, +lin: String) -> IO(Unit):
  match r:
    case M.NR_err{k, d}: IO.print("error: node failed; nothing archived")
    case M.NR_ok{+b, fx}: arc_out_open(M.bd_open(b), b, out, lin)

def stl_write_go(+w: Bool, +r: MO.MO_R, +out: String) -> IO(Unit):
  match w:
    case True{}:
      do IO<Unit>:
        u : Unit <- write_file(out, MO.mo_r_s(r))
        IO.print("wrote " ++ out ++ " nverts " ++ Nat.show(MO.mo_r_nv(r)) ++ " ntris " ++
          Nat.show(MO.mo_r_nt(r)) ++ " (sampled, not certified)")
    case False{}: IO.print("refused " ++ MO.mo_r_why(r) ++ " | stl | fix: tessellate the node first (tess)")

def stl_tres_go(+w: Bool, +t: M10.Tres, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match w:
    case False{}: IO.print("refused " ++ M10.tres_why(t) ++ " | stl @ node " ++ U64.show(id) ++
      " | est " ++ Nat.show(M10.tres_est(t)) ++ " max " ++ Nat.show(M10.q_max(q)) ++
      " | fix: coarsen quality (preset 0, larger chord/angle) or raise max-tris")
    case True{}:
      +r = MO.mo_stl(M10.tres_obj(t))
      stl_write_go(MO.mo_r_ok(r), r, out)

def stl_out(r: M.NR, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match r:
    case M.NR_err{k, d}: IO.print("error: node failed; nothing exported")
    case M.NR_ok{+b, fx}:
      +t = TS.body_q(b, q)
      stl_tres_go(M10.tres_ok_of(t), t, out, id, q)

def stl_with(+bad: Bool, r: M.NR, +out: String, +id: U64, +a2: String, +p: U64, +q: M10.Q) ->
    IO(Unit):
  match bad:
    case True{}: IO.print(tess_q_err(a2, p, q))
    case False{}: stl_out(r, out, id, q)

def stl_args(r: M.NR, +out: String, +id: U64, +a2: String, +a3: String, +a4: String, +a5: String,
    +a6: String) -> IO(Unit):
  +p = tess_p(a2)
  +base = M10.q_preset(p)
  +q = M10.q_mk(tess_f(a3, M10.q_chord(base)), tess_f(a4, M10.q_angle(base)), tess_mx(a5, M10.q_max(base)),
    tess_prof(a6, M10.q_prof(base)))
  stl_with(Bool.not(String.eq(tess_q_err(a2, p, q), "")), r, out, id, a2, p, q)

def mf3_write_go(+w: Bool, +r: MO.MO_B, +out: String) -> IO(Unit):
  match w:
    case True{}:
      do IO<Unit>:
        u : Unit <- write_bytes(out, MO.mo_b_xs(r))
        IO.print("wrote " ++ out ++ " nverts " ++ Nat.show(MO.mo_b_nv(r)) ++ " ntris " ++
          Nat.show(MO.mo_b_nt(r)) ++ " (sampled, not certified)")
    case False{}: IO.print("refused " ++ MO.mo_b_why(r) ++ " | 3mf | fix: tessellate the node first (tess)")

def mf3_tres_go(+w: Bool, +t: M10.Tres, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match w:
    case False{}: IO.print("refused " ++ M10.tres_why(t) ++ " | 3mf @ node " ++ U64.show(id) ++
      " | est " ++ Nat.show(M10.tres_est(t)) ++ " max " ++ Nat.show(M10.q_max(q)) ++
      " | fix: coarsen quality (preset 0, larger chord/angle) or raise max-tris")
    case True{}:
      +r = MO.mo_threemf(M10.tres_obj(t))
      mf3_write_go(MO.mo_b_ok(r), r, out)

def mf3_out(r: M.NR, +out: String, +id: U64, +q: M10.Q) -> IO(Unit):
  match r:
    case M.NR_err{k, d}: IO.print("error: node failed; nothing exported")
    case M.NR_ok{+b, fx}:
      +t = TS.body_q(b, q)
      mf3_tres_go(M10.tres_ok_of(t), t, out, id, q)

def mf3_with(+bad: Bool, r: M.NR, +out: String, +id: U64, +a2: String, +p: U64, +q: M10.Q) ->
    IO(Unit):
  match bad:
    case True{}: IO.print(tess_q_err(a2, p, q))
    case False{}: mf3_out(r, out, id, q)

def mf3_args(r: M.NR, +out: String, +id: U64, +a2: String, +a3: String, +a4: String, +a5: String,
    +a6: String) -> IO(Unit):
  +p = tess_p(a2)
  +base = M10.q_preset(p)
  +q = M10.q_mk(tess_f(a3, M10.q_chord(base)), tess_f(a4, M10.q_angle(base)), tess_mx(a5, M10.q_max(base)),
    tess_prof(a6, M10.q_prof(base)))
  mf3_with(Bool.not(String.eq(tess_q_err(a2, p, q), "")), r, out, id, a2, p, q)

def op_blob_tol_go(+ok: Bool, +b: Ty.Brep, +pr: BL.PR, +nd: U64) -> M.NR:
  match ok:
    case False{}: M.bad("import", "node " ++ U64.show(nd),
      "import-validation-failed at brep stage " ++ M.stage_why(M.stage_of(b, M.fuel_of(b))),
      "re-import the STEP file")
    case True{}: M.op_blob_pay(True{}, pr, nd)

def op_blob_tol_pay(+w: Bool, +pr: BL.PR, +nd: U64) -> M.NR:
  match w:
    case False{}: M.bad("import", "node " ++ U64.show(nd), BL.pr_why(pr), "re-import the STEP file")
    case True{}:
      +b = BL.pr_b(pr)
      +te = SR.sr_brep_tol(b, Ty.P_manifold_solid{}, M.fuel_of(b))
      op_blob_tol_go(SR.sr_te_ok(te), b, pr, nd)

def op_blob_tol(+payload: String, +nd: U64) -> M.NR:
  +pr = BL.pay_brep(payload)
  op_blob_tol_pay(BL.pr_ok_of(pr), pr, nd)

def imp_nr(+w: Bool, +e: BL.ES) -> M.NR:
  match w:
    case False{}: M.bad("import", "step data", BL.es_why(e), "re-import the STEP file")
    case True{}: op_blob_tol(BL.es_s(e), 0u64)

def imp_b1(+w: Bool, +p: BL.PR) -> M.NR:
  match w:
    case False{}: M.bad("import", "step data", BL.pr_why(p), "re-import the STEP file")
    case True{}:
      +e = BL.brep_s(BL.pr_b(p))
      imp_nr(BL.es_ok_of(e), e)

def imp_step(+data: String) -> M.NR:
  +p = SR.sr_file(data)
  imp_b1(BL.pr_ok_of(p), p)

def imp_apr_nr(+w: Bool, +e: BL.ES, +tol: Bool) -> M.NR:
  match w:
    case False{}: M.bad("import", "archive data", BL.es_why(e), "use a BendCAD BCAD2 archive")
    case True{}:
      match tol:
        case True{}: op_blob_tol(BL.es_s(e), 0u64)
        case False{}: M.op_blob(1u64, BL.es_s(e), 0u64)

def imp_apr(+w: Bool, +a: BL.APR) -> M.NR:
  match w:
    case False{}: M.bad("import", "archive data", BL.apr_why(a), "use a BendCAD BCAD2 archive")
    case True{}:
      +e = BL.brep_s(BL.apr_b(a))
      imp_apr_nr(BL.es_ok_of(e), e, SR.sr_has_tol(BL.apr_lineage(a)))

def imp_arc(+data: String) -> M.NR:
  +a = BL.ar_parse(data)
  imp_apr(BL.apr_ok(a), a)

def imp_line(+tag: String, +src: String, +r: M.NR) -> String:
  tag ++ " " ++ src ++ " | " ++ nr_s(r)

def imp_save_go(+w: Bool, +e: BL.ES, +out: String, +rep: String) -> IO(Unit):
  match w:
    case False{}: IO.print(rep ++ "\nrefused " ++ BL.es_why(e) ++ " | archive | fix: keep analytic geometry")
    case True{}:
      do IO<Unit>:
        u : Unit <- write_file(out, BL.es_s(e))
        IO.print(rep ++ "\nwrote " ++ out ++ " archive " ++ BL.ar_ver())

def imp_save(+save: Bool, +out: String, r: M.NR, +lin: String, +rep: String) -> IO(Unit):
  match save:
    case False{}: IO.print(rep)
    case True{}:
      match r:
        case M.NR_err{k, d}: IO.print(rep)
        case M.NR_ok{+b, fx}:
          +e = BL.ar_mk("mm", lin, M.bd_brep(b))
          imp_save_go(BL.es_ok_of(e), e, out, rep)

def geo_step_import_go(+data: String, +file: String, +out: String) -> IO(Unit):
  +r = imp_step(data)
  imp_save(Bool.not(String.eq(out, "")), out, r, "step:" ++ file ++ ":tol", imp_line("imported", file, r))

def geo_step_import(+file: String, +out: String) -> IO(Unit):
  do IO<Unit>:
    data : String <- read_file(file)
    geo_step_import_go(data, file, out)

def geo_reopen_v(+v: Bool, r: M.NR) -> String:
  match v:
    case False{}: ""
    case True{}: "\n" ++ node_faces(r)

def geo_reopen_go(+w: Bool, +a: BL.APR, +file: String, +verb: String) -> IO(Unit):
  match w:
    case False{}: IO.print("error invalid-input | reopen " ++ file ++ " | why: " ++ BL.apr_why(a) ++
      " | fix: reopen a BendCAD BCAD2 archive")
    case True{}:
      +r = imp_apr(True{}, a)
      IO.print("reopened " ++ file ++ " units " ++ BL.apr_units(a) ++ " lineage " ++
        BL.apr_lineage(a) ++ " | " ++ nr_s(r) ++ geo_reopen_v(String.eq(verb, "-v"), r))

def geo_reopen_data(+data: String, +file: String, +verb: String) -> IO(Unit):
  +a = BL.ar_parse(data)
  geo_reopen_go(BL.apr_ok(a), a, file, verb)

def geo_reopen(+file: String, +verb: String) -> IO(Unit):
  do IO<Unit>:
    data : String <- read_file(file)
    geo_reopen_data(data, file, verb)

def geo_step_of_go(+w: Bool, +a: BL.APR, +out: String) -> IO(Unit):
  match w:
    case False{}: IO.print("error invalid-input | step_of | why: " ++ BL.apr_why(a) ++
      " | fix: export from a BendCAD BCAD2 archive")
    case True{}:
      +s = SW.sw_pr(BL.pr_ok(BL.apr_b(a)), M.pl_id())
      step_write_go(SW.ws_ok(s), s, out)

def geo_step_of_data(+data: String, +out: String) -> IO(Unit):
  +a = BL.ar_parse(data)
  geo_step_of_go(BL.apr_ok(a), a, out)

def geo_step_of(+file: String, +out: String) -> IO(Unit):
  do IO<Unit>:
    data : String <- read_file(file)
    geo_step_of_data(data, out)

def geo_stl_of(+file: String, +out: String, +a2: String, +a3: String, +a4: String, +a5: String,
    +a6: String) -> IO(Unit):
  do IO<Unit>:
    data : String <- read_file(file)
    stl_args(imp_arc(data), out, 0u64, a2, a3, a4, a5, a6)

def geo_mf3_of(+file: String, +out: String, +a2: String, +a3: String, +a4: String, +a5: String,
    +a6: String) -> IO(Unit):
  do IO<Unit>:
    data : String <- read_file(file)
    mf3_args(imp_arc(data), out, 0u64, a2, a3, a4, a5, a6)

def geo12(+c: String) -> U64:
  Bool.pick(U64, String.eq(c, "step_import"), 1u64, Bool.pick(U64, String.eq(c, "reopen"), 2u64,
    Bool.pick(U64, String.eq(c, "step_of"), 3u64, Bool.pick(U64, String.eq(c, "stl_of"), 4u64,
      Bool.pick(U64, String.eq(c, "3mf_of"), 5u64, 0u64)))))

def geo_go(code: U64, +args: List<&2, String>) -> IO(Unit):
  match code:
    case 1u64: geo_step_import(S.arg_at(args, 3n), S.arg_at(args, 4n))
    case 2u64: geo_reopen(S.arg_at(args, 3n), S.arg_at(args, 4n))
    case 3u64: geo_step_of(S.arg_at(args, 3n), S.arg_at(args, 4n))
    case 4u64: geo_stl_of(S.arg_at(args, 3n), S.arg_at(args, 4n), S.arg_at(args, 5n), S.arg_at(args, 6n),
      S.arg_at(args, 7n), S.arg_at(args, 8n), S.arg_at(args, 9n))
    case 5u64: geo_mf3_of(S.arg_at(args, 3n), S.arg_at(args, 4n), S.arg_at(args, 5n), S.arg_at(args, 6n),
      S.arg_at(args, 7n), S.arg_at(args, 8n), S.arg_at(args, 9n))
    case _: IO.print(GQ.geom(arg_drop(args, 2n)))

def pmi_fr(+fr: PM.FR, +out: String) -> IO(Unit):
  match fr:
    case PM.FR_ok{+s, +n}:
      do IO<Unit>:
        w : Unit <- write_file(out, s)
        IO.print("wrote " ++ out ++ " ap242 PMI " ++ Nat.show(n) ++ " entities")
    case PM.FR_err{+why, +fix}: IO.print("error invalid-input | pmi step42 | why: " ++ why ++
      " | fix: " ++ fix)
    case PM.FR_line{+l}: IO.print(l)

def pmi_vc_go(+code: U64, +p: M.Part, +rest: List<&2, String>) -> IO(Unit):
  match code:
    case 4u64: pmi_fr(PM.pmi_file(p, rest), S.arg_at(rest, 1n))
    case _: IO.print(PM.pmi_go(p, rest))

def pmi_run(+p: M.Part, +rest: List<&2, String>) -> IO(Unit):
  pmi_vc_go(PM.verb_code(S.arg_at(rest, 0n)), p, rest)

def flat_k(+g: SH.GR, +id: U64, +sc: SH.SC, +e: X.Env, +klo: F64, +khi: F64) -> String:
  match g:
    case SH.GR_ok{}: SH.flat_rep(id, sc, e, klo, khi)
    case SH.GR_no{+why, +fix}: "error invalid-input | flat | why: " ++ why ++ " | fix: " ++ fix

def flat_sc(+ok: Bool, +sc: SH.SC, +e: X.Env, +id: U64, +klo: F64, +khi: F64) -> String:
  match ok:
    case False{}: "error invalid-input | flat | why: flat-needs-sheet | fix: run flat on a flat, bend or hem node"
    case True{}: flat_k(SH.k_go(SH.k_ok(klo, khi), klo, khi), id, sc, e, klo, khi)

def flat_nr(+ok: Bool, +sc: SH.SC, +e: X.Env, +id: U64, +klo: F64, +khi: F64) -> String:
  match ok:
    case False{}: "error: node " ++ U64.show(id) ++ "; nothing flattened"
    case True{}: flat_sc(SH.sc_sc_ok(sc), sc, e, id, klo, khi)

def flat_has(+has: Bool, +cs: List<&2, M.CE>, +ns: List<&2, M.Node>, +e: X.Env, +id: U64, +klo: F64,
    +khi: F64) -> String:
  match has:
    case False{}: "error invalid-input | flat | why: unknown-node " ++ U64.show(id) ++ " | fix: name an evaluated node"
    case True{}: flat_nr(M.nr_ok(node_res(cs, id)), M.sh_chain(ns, id), e, id, klo, khi)

def flat_go(+p: M.Part, +xs: List<&2, String>) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +id = S.u64_of(S.Sx_a{S.arg_at(xs, 0n)})
  +klo = f_or_nan(S.dec(S.arg_at(xs, 1n)))
  +khi = f_or_nan(S.dec(S.arg_at(xs, 2n)))
  +cs = M.ev_part(p, [])
  flat_has(M.ce_has(cs, id), cs, ns, X.env_of(M.pvs_of(ps)), id, klo, khi)

def surf_nr(+ok: Bool, +so: SU.SO, +e: X.Env, +id: U64) -> String:
  match ok:
    case False{}: "error: node " ++ U64.show(id) ++ "; nothing surfaced"
    case True{}: SU.surf_rep(id, so, e)

def surf_has(+has: Bool, +cs: List<&2, M.CE>, +ns: List<&2, M.Node>, +e: X.Env, +id: U64) -> String:
  match has:
    case False{}: "error invalid-input | surf | why: unknown-node " ++ U64.show(id) ++ " | fix: name an evaluated node"
    case True{}: surf_nr(M.nr_ok(node_res(cs, id)), M.su_chain(ns, id), e, id)

def blade_nr(+ok: Bool, +bo: BA.BO, +e: X.Env, +id: U64) -> String:
  match ok:
    case False{}: "error: node " ++ U64.show(id) ++ "; nothing bladed"
    case True{}: BA.blade_rep(id, bo, e)

def blade_has(+has: Bool, +cs: List<&2, M.CE>, +ns: List<&2, M.Node>, +e: X.Env, +id: U64) -> String:
  match has:
    case False{}: "error invalid-input | blade | why: unknown-node " ++ U64.show(id) ++ " | fix: name an evaluated node"
    case True{}: blade_nr(M.nr_ok(node_res(cs, id)), M.bl_chain(ns, id), e, id)

def blade_go(+p: M.Part, +xs: List<&2, String>) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +cs = M.ev_part(p, [])
  +id = S.u64_of(S.Sx_a{S.arg_at(xs, 0n)})
  blade_has(M.ce_has(cs, id), cs, ns, X.env_of(M.pvs_of(ps)), id)

def surf_go(+p: M.Part, +xs: List<&2, String>) -> String:
  M.Pt{+ps, +ns, +ms, +ts} = p
  +id = S.u64_of(S.Sx_a{S.arg_at(xs, 0n)})
  +cs = M.ev_part(p, [])
  surf_has(M.ce_has(cs, id), cs, ns, X.env_of(M.pvs_of(ps)), id)

def run_go(code: U64, +cmd: String, +path: String, +rest: List<&2, String>, +p: M.Part) -> IO(Unit):
  match code:
    case 1u64: IO.print(S.part_show(p))
    case 2u64: IO.print(ces_s(M.ev_part(p, [])))
    case 3u64: IO.print(node_faces_vf(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), String.eq(S.arg_at(rest, 1n), "-v"), String.eq(S.arg_at(rest, 1n), "-f")))
    case 4u64: IO.print(nr_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}))))
    case 5u64: IO.print(sens(p, S.arg_at(rest, 0n), S.u64_of(S.Sx_a{S.arg_at(rest, 1n)})))
    case 6u64: apply_parsed(edits_parse(rest), path, p)
    case 7u64: tess_args(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), S.arg_at(rest, 1n),
      S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}), S.arg_at(rest, 2n), S.arg_at(rest, 3n), S.arg_at(rest, 4n), S.arg_at(rest, 5n), S.arg_at(rest, 6n))
    case 8u64: IO.print(zone_line(p, S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})))
    case 9u64: IO.print(QI.classify_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), f_arg(rest, 1n), f_arg(rest, 2n), f_arg(rest, 3n)))
    case 10u64: IO.print(QI.check_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}))))
    case 11u64: IO.print(QD.dist_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), f_arg(rest, 1n), f_arg(rest, 2n), f_arg(rest, 3n)))
    case 12u64: IO.print(QD.extrema_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}))))
    case 13u64: IO.print(mass_out(p, S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}), QM.mass_depth(S.arg_at(rest, 1n))))
    case 14u64: IO.print(QN.sect_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), f_arg(rest, 1n), f_arg(rest, 2n), f_arg(rest, 3n), f_arg(rest, 4n)))
    case 15u64: IO.print(QI.rel_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 1n)}))))
    case 16u64: IO.print(QD.clear_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 1n)}))))
    case 17u64: IO.print(QD.wall_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}))))
    case 18u64: step_out(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), S.arg_at(rest, 1n))
    case 19u64: arc_out(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), S.arg_at(rest, 1n),
      S.arg_at(rest, 2n))
    case 20u64: stl_args(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), S.arg_at(rest, 1n),
      S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}), S.arg_at(rest, 2n), S.arg_at(rest, 3n), S.arg_at(rest, 4n), S.arg_at(rest, 5n), S.arg_at(rest, 6n))
    case 21u64: mf3_args(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), S.arg_at(rest, 1n),
      S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}), S.arg_at(rest, 2n), S.arg_at(rest, 3n), S.arg_at(rest, 4n), S.arg_at(rest, 5n), S.arg_at(rest, 6n))
    case 22u64: IO.print(AS.asm_go(p, rest))
    case 23u64: pmi_run(p, rest)
    case 24u64: IO.print(flat_go(p, rest))
    case 25u64: IO.print(surf_go(p, rest))
    case 26u64: IO.print(blade_go(p, rest))
    case 27u64: IO.print(diag_s(M.ev_part(p, [])))
    case 28u64: IO.print(threads_out(p, S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})))
    case _: IO.print("error unknown command " ++ cmd ++ " | use new, show, eval, apply, measure, faces, sens, tess, zone, classify, check, dist, extrema, mass, section, interf, clearance, wall, step, archive, stl, 3mf, asm, pmi, flat, surf, blade, diag, threads")

def run_cancel_go(is_diag: Bool, +cmd: String, +path: String) -> IO(Unit):
  match is_diag:
    case True{}: IO.print(E.json_err(0u64, T.F_cancelled{}, cmd, path, "request-cancelled", "reissue the request"))
    case False{}: IO.print(E.line(T.F_cancelled{}, cmd, path, "request-cancelled", "reissue the request"))

def run_over_go(is_diag: Bool, +cmd: String, +path: String) -> IO(Unit):
  match is_diag:
    case True{}: IO.print(E.json_err(0u64, T.F_exhausted{}, cmd, path, "node-budget-exceeded", "raise --max-nodes N or split the design"))
    case False{}: IO.print(E.line(T.F_exhausted{}, cmd, path, "node-budget-exceeded", "raise --max-nodes N or split the design"))

def run_dec(d: R.Dec, +code: U64, +cmd: String, +path: String, +rest: List<&2, String>, +p: M.Part) -> IO(Unit):
  match d:
    case R.D_go{}: run_go(code, cmd, path, rest, p)
    case R.D_cancel{}: run_cancel_go(String.eq(cmd, "diag"), cmd, path)
    case R.D_over{}: run_over_go(String.eq(cmd, "diag"), cmd, path)

def run_part(+cmd: String, +path: String, +rest: List<&2, String>, +p: M.Part, +cap: U64, +cancel: Bool) -> IO(Unit):
  M.Pt{+ps, +ns, +ms, +ts} = p
  run_dec(R.dec_of(cancel, R.over_ids(M.nd_ids(ns), U64.to_nat(cap))), cmd_code(cmd), cmd, path, rest, p)

def run(+cmd: String, +path: String, +rest: List<&2, String>, +src: String, +cap: U64, +cancel: Bool) -> IO(Unit):
  run_part(cmd, path, rest, load(src), cap, cancel)

def main_new(+path: String) -> IO(Unit):
  do IO<Unit>:
    w : Unit <- write_file(path, "(bendcad 1)
")
    IO.print("created " ++ path)

def main_old_go(+path: String, +cmd: String, +rest: List<&2, String>, +cap: U64, +cancel: Bool) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(path)
    run(cmd, path, rest, src, cap, cancel)

def main_isnew_go(isnew: Bool, +path: String, +verb: String, +rest: List<&2, String>, +cap: U64, +cancel: Bool) -> IO(Unit):
  match isnew:
    case True{}: main_new(path)
    case False{}: main_old_go(path, verb, rest, cap, cancel)

def main_flag_go(bad: Bool, +path: String, +verb: String, +rest: List<&2, String>, +cap: U64, +cancel: Bool, +err: String) -> IO(Unit):
  match bad:
    case True{}: IO.print(E.line(T.F_invalid{}, "args", path, err, "use [--max-nodes N] [--cancelled] before the verb"))
    case False{}: main_isnew_go(String.eq(verb, "new"), path, verb, rest, cap, cancel)

def main_fl(+path: String, +fl: R.Fl) -> IO(Unit):
  R.Fl{+cap, +cancel, +verb, +rest, +err} = fl
  main_flag_go(Bool.not(String.eq(err, "")), path, verb, rest, cap, cancel, err)

def main_sel(+path: String, +tokens: List<&2, String>) -> IO(Unit):
  main_fl(path, R.parse(tokens))

def main_geo(isgeo: Bool, +args: List<&2, String>) -> IO(Unit):
  match isgeo:
    case True{}: geo_go(geo12(S.arg_at(args, 2n)), args)
    case False{}: main_sel(S.arg_at(args, 1n), arg_drop(args, 2n))

def main_go(+args: List<&2, String>) -> IO(Unit):
  main_geo(String.eq(S.arg_at(args, 1n), "geom"), args)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    main_go(S.args_l(args))

