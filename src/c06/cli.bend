import Base
import ../c00/types.bend as T
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ./iv.bend as I
import ./build.bend as BD
import ./model.bend as M
import ./sx.bend as S
import ./tess.bend as TS
import ../c10/mesh.bend as M10
import ./zone.bend as Z
import ../c07/gsx.bend as GQ
import ../c08/bool.bend as BO
import ../c11/qdist.bend as QD
import ../c11/qmass.bend as QM
import ../c11/qsect.bend as QN
import ../c11/qinterf.bend as QI

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
      "error " ++ T.FailKind.show(k) ++ " | " ++ w ++ " @ " ++ l ++ " | why: " ++ y ++ " | fix: " ++ f
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
  M.Pt{+ps, +ns} = p
  +name = S.sx_s(S.sx_nth(xs, 1n))
  +d = dim_of(xs)
  Bool.pick(M.Part, pm_has(ps, name), M.Pt{pm_set(ps, name, d), ns},
    M.Pt{List.append(&2, M.Param, ps, [M.Pm{(max_id(ps, 0u64) + 1u64 : U64), name, d}]), ns})

def edit_node(+p: M.Part, +x: S.Sx) -> M.Part:
  M.Pt{+ps, ns} = p
  +xs = S.sx_xs(x)
  +ni = S.nis_of(ps)
  M.Pt{ps, nd_set(ns, M.Nd{S.u64_of(S.sx_nth(xs, 1n)), S.op_of(S.sx_nth(xs, 2n), ni), S.it_of(S.sx_nth(xs, 3n))})}

def edit_del(+p: M.Part, +xs: List<&2, S.Sx>) -> M.Part:
  M.Pt{ps, ns} = p
  M.Pt{ps, nd_del(ns, S.u64_of(S.sx_nth(xs, 1n)))}

def edit_one(+p: M.Part, +x: S.Sx) -> M.Part:
  +xs = S.sx_xs(x)
  Bool.pick(M.Part, S.head_is(x, "param"), edit_param(p, xs),
    Bool.pick(M.Part, S.head_is(x, "node"), edit_node(p, x), Bool.pick(M.Part, S.head_is(x, "delete"), edit_del(p, xs), p)))

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

def edit_ok(+x: S.Sx) -> Bool:
  Bool.or(Bool.and(S.head_is(x, "param"), pm_ok(S.sx_xs(x))), Bool.or(S.head_is(x, "node"), S.head_is(x, "delete")))

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

def fn_s(f: BD.Fn) -> String:
  BD.Fn{+nd, +k, +role, +i, +j} = f
  Bool.pick(String, U64.is_eq(role, 4u64),
    "n" ++ U64.show(nd) ++ ".cav." ++ Nat.show(k) ++ "." ++ Nat.show(i) ++ "." ++ Nat.show(j),
    "n" ++ U64.show(nd) ++ ".c" ++ Nat.show(k) ++ Bool.pick(String, U64.is_eq(role, 0u64), ".top",
      Bool.pick(String, U64.is_eq(role, 1u64), ".bottom", ".wall." ++ Nat.show(i) ++ "." ++ Nat.show(j))))

def surf_s(s: G.GVal) -> String:
  match s:
    case G.GV_pl{w}: "plane"
    case G.GV_cy{w}: "cylinder"
    case G.GV_bp{w}: "planar-patch"
    case G.GV_sp{w}: "sphere"
    case G.GV_co{w}: "cone"
    case G.GV_to{w}: "torus"
    case _: "other"

def faces_s(fs: List<&2, BD.Fn>, fas: List<&2, Ty.Face>) -> String:
  match fs:
    case []: ""
    case f <> t:
      match fas:
        case []: ""
        case a <> u:
          Ty.Fa{g, s, ls, same} = a
          fn_s(f) ++ " " ++ surf_s(s) ++ " loops=" ++ Nat.show(List.length(&2, Ty.HLoop, ls)) ++ "\n" ++ faces_s(t, u)

def delv_s(d: BO.Del) -> String:
  "deleted " ++ BO.del_show(d) ++ "\n"

def dels_v(ds: List<&2, BO.Del>) -> String:
  match ds:
    case []: ""
    case d <> t: delv_s(d) ++ dels_v(t)

def node_faces_v(r: M.NR, +verbose: Bool) -> String:
  match r:
    case M.NR_err{k, d}: "node failed\n"
    case M.NR_ok{+b, fx}:
      +s = faces_s(M.bd_fns(b), Ty.brep_fas(M.bd_brep(b)))
      Bool.pick(String, verbose, s ++ dels_v(M.xb_dl(M.bd_xb(b))), s)

def node_faces(r: M.NR) -> String:
  node_faces_v(r, False{})

def node_res(cs: List<&2, M.CE>, +id: U64) -> M.NR:
  M.ce_r(M.ce_find(cs, id))

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
  M.Pt{+ps, +ns} = p
  +nom = pm_nom(ps, name)
  +h = F64.mul(F64.max(F64.abs(nom), 1.0f64), 9.5367431640625e-07f64)
  +c0 = M.ev_part(p, [])
  +cp = M.ev_part(M.Pt{pm_bump(ps, name, h), ns}, c0)
  +cm = M.ev_part(M.Pt{pm_bump(ps, name, F64.neg(h)), ns}, c0)
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

def load(+src: String) -> M.Part:
  S.part_of(S.ps_xs(S.parse(src)))

def commit_go(ok: Bool, +path: String, +p: M.Part) -> IO(Unit):
  match ok:
    case True{}:
      do IO<Unit>:
        w : Unit <- write_file(path, S.part_show(p))
        IO.print("committed")
    case False{}: IO.print("rejected: the design was not changed")

def commit(+path: String, +p: M.Part, +cs: List<&2, M.CE>) -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(ces_s(cs))
    commit_go(ces_ok(cs), path, p)

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
  Bool.pick(U64, String.eq(c, "wall"), 17u64, 0u64)))))))))))))))))

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

def run_go(code: U64, +cmd: String, +path: String, +rest: List<&2, String>, +p: M.Part) -> IO(Unit):
  match code:
    case 1u64: IO.print(S.part_show(p))
    case 2u64: IO.print(ces_s(M.ev_part(p, [])))
    case 3u64: IO.print(node_faces_v(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), String.eq(S.arg_at(rest, 1n), "-v")))
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
    case 13u64: IO.print(QM.mass_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), QM.mass_depth(S.arg_at(rest, 1n))))
    case 14u64: IO.print(QN.sect_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), f_arg(rest, 1n), f_arg(rest, 2n), f_arg(rest, 3n), f_arg(rest, 4n)))
    case 15u64: IO.print(QI.rel_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 1n)}))))
    case 16u64: IO.print(QD.clear_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)})), node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 1n)}))))
    case 17u64: IO.print(QD.wall_s(node_res(M.ev_part(p, []), S.u64_of(S.Sx_a{S.arg_at(rest, 0n)}))))
    case _: IO.print("error unknown command " ++ cmd ++ " | use new, show, eval, apply, measure, faces, sens, tess, zone, classify, check, dist, extrema, mass, section, interf, clearance, wall")

def run(+cmd: String, +path: String, +rest: List<&2, String>, +src: String) -> IO(Unit):
  run_go(cmd_code(cmd), cmd, path, rest, load(src))

def main_new(+path: String) -> IO(Unit):
  do IO<Unit>:
    w : Unit <- write_file(path, "(bendcad 1)
")
    IO.print("created " ++ path)

def main_old(+path: String, +cmd: String, +rest: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    src : String <- read_file(path)
    run(cmd, path, rest, src)

def main_sel(isnew: Bool, +path: String, +cmd: String, +rest: List<&2, String>) -> IO(Unit):
  match isnew:
    case True{}: main_new(path)
    case False{}: main_old(path, cmd, rest)

def main_geo(isgeo: Bool, +args: List<&2, String>) -> IO(Unit):
  match isgeo:
    case True{}: IO.print(GQ.geom(arg_drop(args, 2n)))
    case False{}:
      +cmd = S.arg_at(args, 2n)
      main_sel(String.eq(cmd, "new"), S.arg_at(args, 1n), cmd, arg_drop(args, 3n))

def main_go(+args: List<&2, String>) -> IO(Unit):
  main_geo(String.eq(S.arg_at(args, 1n), "geom"), args)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    main_go(S.args_l(args))

