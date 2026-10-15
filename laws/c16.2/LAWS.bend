import Base
import ../../src/c00/types.bend as T
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/model.bend as M
import ../../src/c06/prof.bend as FP
import ../../src/c06/revolve.bend as RV
import ../../src/c06/xp.bend as X
import ../../src/c09/feat.bend as F9
import ../../src/c16/surf.bend as SU

def e_at(es: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match es:
    case []: Ty.Ed{0u64, Ty.HV{0n, 0u64}, Ty.HV{0n, 0u64}, Ty.EK_degenerate{}}
    case e <> t:
      match i:
        case 0n: e
        case 1n+j: e_at(t, j)

def ev0(e: Ty.Edge) -> Nat:
  Ty.Ed{g, a, b, k} = e
  Ty.HV{i, ag} = a
  i

def ev1(e: Ty.Edge) -> Nat:
  Ty.Ed{g, a, b, k} = e
  Ty.HV{i, bg} = b
  i

def u_start(+es: List<&2, Ty.Edge>, u: BD.Use) -> Nat:
  BD.Us{+e, fwd, ta, tb} = u
  Bool.pick(Nat, fwd, ev0(e_at(es, e)), ev1(e_at(es, e)))

def u_end(+es: List<&2, Ty.Edge>, u: BD.Use) -> Nat:
  BD.Us{+e, fwd, ta, tb} = u
  Bool.pick(Nat, fwd, ev1(e_at(es, e)), ev0(e_at(es, e)))

def chain(+es: List<&2, Ty.Edge>, us: List<&2, BD.Use>, +at: Nat, +home: Nat) -> Bool:
  match us:
    case []: Nat.is_eq(at, home)
    case +u <> t: Bool.and(Nat.is_eq(u_start(es, u), at), chain(es, t, u_end(es, u), home))

def loop_closed(+es: List<&2, Ty.Edge>, us: List<&2, BD.Use>) -> Bool:
  match us:
    case []: False{}
    case +u <> t: chain(es, t, u_end(es, u), u_start(es, u))

def loops_closed(+es: List<&2, Ty.Edge>, ls: List<&2, List<&2, BD.Use>>) -> Bool:
  match ls:
    case []: True{}
    case l <> t: Bool.and(loop_closed(es, l), loops_closed(es, t))

def faces_closed(+es: List<&2, Ty.Edge>, fs: List<&2, BD.FS>) -> Bool:
  match fs:
    case []: True{}
    case f <> t:
      BD.FS{sol, surf, same, lps, nm} = f
      Bool.and(loops_closed(es, lps), faces_closed(es, t))

def flat(ls: List<&2, List<&2, BD.Use>>) -> List<&2, BD.Use>:
  match ls:
    case []: []
    case l <> t: List.append(&2, BD.Use, l, flat(t))

def beq(a: Bool, b: Bool) -> Bool:
  match a:
    case True{}: b
    case False{}: Bool.not(b)

def uses(fs: List<&2, BD.FS>) -> List<&2, BD.Use>:
  match fs:
    case []: []
    case f <> t:
      BD.FS{sol, surf, same, lps, nm} = f
      List.append(&2, BD.Use, flat(lps), uses(t))

def hits(us: List<&2, BD.Use>, +e: Nat, +d: Bool) -> Nat:
  match us:
    case []: 0n
    case u <> t:
      BD.Us{e2, fwd, ta, tb} = u
      Nat.add(Bool.pick(Nat, Bool.and(Nat.is_eq(e2, e), beq(fwd, d)), 1n, 0n), hits(t, e, d))

def is_bnd(bs: List<&2, Nat>, +e: Nat) -> Bool:
  match bs:
    case []: False{}
    case +b <> t: Bool.or(Nat.is_eq(b, e), is_bnd(t, e))

def bndge(n: Nat, +us: List<&2, BD.Use>, +bs: List<&2, Nat>) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+k):
      Bool.and(Bool.pick(Bool, is_bnd(bs, k),
        Nat.is_eq(Nat.add(hits(us, k, True{}), hits(us, k, False{})), 1n),
        Bool.and(Nat.is_eq(hits(us, k, True{}), 1n), Nat.is_eq(hits(us, k, False{}), 1n))),
        bndge(k, us, bs))

def ends_below(es: List<&2, Ty.Edge>, +nv: Nat) -> Bool:
  match es:
    case []: True{}
    case +e <> t: Bool.and(Bool.and(Nat.is_lt(ev0(e), nv), Nat.is_lt(ev1(e), nv)), ends_below(t, nv))

def open_shell(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>,
    +bs: List<&2, Nat>, +chi: Nat) -> Bool:
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nf = List.length(&2, BD.FS, fs)
  Bool.and(Bool.and(faces_closed(es, fs), bndge(ne, uses(fs), bs)),
    Bool.and(ends_below(es, nv), Nat.is_eq(Nat.add(nv, nf), Nat.add(ne, chi))))

law loft_open_shell:
  for +fr: F9.FR
  {open_shell(F9.fr_vs(8n, 0n, fr), F9.fr_es(12n, 0n, fr), SU.loft_wall_fs(fr), SU.loft_bnd_ids(), 0n) == True{} : Bool}

law swo_open_shell:
  for +s: SU.SWO
  for +q: SU.QD
  for +nd: U64
  {open_shell(RV.sec_vs(SU.swo_pcs(s), 4n, Nat.add(SU.qd_n(q), 1n)),
    RV.sec_es(SU.swo_pcs(s), 4n, SU.qd_n(q)),
    RV.sides_all(SU.qd_n(q), SU.swo_pcs(s), 4n, 0n, SU.qd_n(q), nd, 0n), SU.swo_bnd_ids(q), 0n) == True{} : Bool}

law patch_open_shell:
  for +p: SU.PP
  for +nd: U64
  {open_shell(SU.patch_vs(p), SU.patch_es(p), SU.patch_fs(p, nd), SU.patch_bnd_ids(), 1n) == True{} : Bool}

law thicken_slab_closed:
  for +p: SU.PP
  for +t: F64
  for +nd: U64
  {open_shell(SU.slab_vs(p, t), SU.slab_es(p, t), SU.slab_fs(p, t, nd), [], 2n) == True{} : Bool}

law thicken_duct_closed:
  for +d: SU.DD
  for +nd: U64
  {open_shell(SU.duct_vs(d), SU.duct_es(d), SU.duct_fs(d, nd), [], 0n) == True{} : Bool}

law thicken_sec_closed:
  for +d: SU.SD
  for +q: SU.QD
  for +nd: U64
  {open_shell(SU.sec_vs(d, SU.qd_n(q)), SU.sec_es(d, SU.qd_n(q)), SU.sec_fs(d, SU.qd_n(q), nd), [], 0n) == True{} : Bool}

law surf_rows_len:
  for bs: List<&2, SU.BE>
  for +i: Nat
  {List.length(&2, SU.BR, SU.bnd_rows(bs, i)) == List.length(&2, SU.BE, bs) : Nat}

law surf_rows_nil:
  for +i: Nat
  {SU.bnd_rows([], i) == [] : List<&2, SU.BR>}

law sweep_angle_refused:
  for rs: List<&2, FP.Region>
  for g: U64
  for gd: U64
  for tw: U64
  for e: X.Env
  for nd: U64
  {M.op_sw_open(45u64, rs, g, gd, tw, e, nd) == M.NR_err{T.F_unsupported{}, M.Dg{"sweep-open", "node " ++ U64.show(nd), "sweep-angle-not-certified", "sweep-open 90, 180 or 270 degrees"}} : M.NR}

law patch_degenerate_refused:
  for e: X.Env
  for nd: U64
  {M.op_patch([X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{3.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{3.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{1.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{2.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{3.0f64}, X.X_k{1.0f64}, X.X_k{0.0f64}, X.X_k{0.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}, X.X_k{1.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}, X.X_k{2.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}, X.X_k{3.0f64}, X.X_k{2.0f64}, X.X_k{0.0f64}], e, nd) == M.NR_err{T.F_invalid{}, M.Dg{"patch", "node " ++ U64.show(nd), "patch-degenerate", "give 16 finite control points with distinct rows, columns and corners"}} : M.NR}

law surf_needs_open_refused:
  for x: X.Xp
  for y: X.Xp
  for z: X.Xp
  for it: M.It
  for e: X.Env
  {SU.surf_rep(7u64, M.su_chain([M.Nd{7u64, M.O_box{x, y, z}, it}], 7u64), e) == "error invalid-input | surf | why: " ++ "surf-needs-open-shell" ++ " | fix: " ++ "run surf on a loft-open, sweep-open or patch node" : String}

law thicken_needs_open_refused:
  for x: X.Xp
  for y: X.Xp
  for z: X.Xp
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_thicken_open(7u64, X.X_k{1.0f64}, b, e, nd, [M.Nd{7u64, M.O_box{x, y, z}, it}]) == M.NR_err{T.F_invalid{}, M.Dg{"thicken-open", "node " ++ U64.show(nd), "thicken-needs-open-shell", "thicken-open an open-shell node"}} : M.NR}

law thicken_thickness_refused:
  for ps: List<&2, X.Xp>
  for it: M.It
  for b: M.Body
  for e: X.Env
  for nd: U64
  {M.op_thicken_open(7u64, X.X_k{0.0f64}, b, e, nd, [M.Nd{7u64, M.O_patch{ps}, it}]) == M.NR_err{T.F_invalid{}, M.Dg{"thicken-open", "node " ++ U64.show(nd), "degenerate-feature", "give finite positive wall thickness"}} : M.NR}
