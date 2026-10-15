import Base
import ../../src/c00/types.bend as T
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/model.bend as M
import ../../src/c06/xp.bend as X
import ../../src/c16/blade.bend as BA

def sg_a(+s: BA.Sg) -> Nat:
  match s:
    case BA.Sg_ln{+a, +b}: a

def sg_b(+s: BA.Sg) -> Nat:
  match s:
    case BA.Sg_ln{+a, +b}: b

def below(ss: List<&2, BA.Sg>, +n: Nat) -> Bool:
  match ss:
    case []: True{}
    case +s <> t: Bool.and(Bool.and(Nat.is_lt(sg_a(s), n), Nat.is_lt(sg_b(s), n)), below(t, n))

def linked(ss: List<&2, BA.Sg>, +at: Nat) -> Bool:
  match ss:
    case []: True{}
    case +s <> t: Bool.and(Nat.is_eq(sg_a(s), at), linked(t, sg_b(s)))

def idx_closed(+p: BA.PR) -> Bool:
  BA.PR{+pts, +segs} = p
  match segs:
    case []: False{}
    case +s <> t:
      Bool.and(Nat.is_eq(sg_a(s), 0n),
        Bool.and(linked(t, sg_b(s)), below(segs, List.length(&2, BA.P2, pts))))

def dpts_go(left: Nat) -> List<&2, BA.P2>:
  match left:
    case 0n: []
    case 1n+k: BA.P2{0.0f64, 0.0f64} <> dpts_go(k)

def dpts(+m: Nat) -> List<&2, BA.P2>:
  dpts_go(m)

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

def bal_go(n: Nat, +us: List<&2, BD.Use>) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+k):
      Bool.and(Bool.and(Nat.is_eq(hits(us, k, True{}), 1n), Nat.is_eq(hits(us, k, False{}), 1n)),
        bal_go(k, us))

def ends_below(es: List<&2, Ty.Edge>, +nv: Nat) -> Bool:
  match es:
    case []: True{}
    case +e <> t: Bool.and(Bool.and(Nat.is_lt(ev0(e), nv), Nat.is_lt(ev1(e), nv)), ends_below(t, nv))

def closed_solid(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>) -> Bool:
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nf = List.length(&2, BD.FS, fs)
  Bool.and(Bool.and(faces_closed(es, fs), bal_go(ne, uses(fs))),
    Bool.and(ends_below(es, nv), Nat.is_eq(Nat.add(nv, nf), Nat.add(ne, 2n))))

def dvs_go(left: Nat, +i: Nat) -> List<&2, Ty.Vertex>:
  match left:
    case 0n: []
    case 1n+k: Ty.Vx{0u64, V.Pt{0.0f64, 0.0f64, 0.0f64}} <> dvs_go(k, Nat.add(i, 1n))

def dvs(+n: Nat, +m: Nat) -> List<&2, Ty.Vertex>:
  dvs_go(Nat.mul(n, m), 0n)

def dedge(+n: Nat, +m: Nat, +e: Nat) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(BA.edge_a(n, m, e)), BD.hv(BA.edge_b(n, m, e)), Ty.EK_degenerate{}}

def dedges_go(+n: Nat, +m: Nat, left: Nat, +e: Nat) -> List<&2, Ty.Edge>:
  match left:
    case 0n: []
    case 1n+k: dedge(n, m, e) <> dedges_go(n, m, k, Nat.add(e, 1n))

def dedges(+n: Nat, +m: Nat) -> List<&2, Ty.Edge>:
  dedges_go(n, m, BA.blade_ne(n, m), 0n)

def duse(+u: BA.Ub) -> BD.Use:
  BD.Us{BA.ub_e(u), BA.ub_fwd(u), V.V2{0.0f64, 0.0f64}, V.V2{0.0f64, 0.0f64}}

def dloop(l: List<&2, BA.Ub>) -> List<&2, BD.Use>:
  match l:
    case []: []
    case +u <> t: duse(u) <> dloop(t)

def dfs_go(ls: List<&2, List<&2, BA.Ub>>, +i: Nat) -> List<&2, BD.FS>:
  match ls:
    case []: []
    case +l <> t:
      BD.FS{0n, G.GV_f{0.0f64}, True{}, [dloop(l)], BD.Fn{0u64, 0n, 2u64, i, 0n}} <> dfs_go(t, Nat.add(i, 1n))

def dloops(+n: Nat, +m: Nat) -> List<&2, List<&2, BA.Ub>>:
  List.append(&2, List<&2, BA.Ub>, BA.walls_flat(n, m), [BA.cap_root(m), BA.cap_tip(n, m)])

def dfs(+n: Nat, +m: Nat) -> List<&2, BD.FS>:
  dfs_go(dloops(n, m), 0n)

type SN is Data:
  S2{}
  S3{}

def sn_n(+w: SN) -> Nat:
  match w:
    case S2{}: 2n
    case S3{}: 3n

type SM is Data:
  S8{}
  S16{}

def sm_m(+q: SM) -> Nat:
  match q:
    case S8{}: 8n
    case S16{}: 16n

law naca_loop_closed:
  for +q: BA.NQ
  {idx_closed(BA.PR{dpts(BA.ring_m(BA.ring_k(q))), BA.ring_segs(BA.ring_m(BA.ring_k(q)))}) == True{} : Bool}

law blade_n_closed:
  for +w: SN
  {closed_solid(dvs(sn_n(w), 8n), dedges(sn_n(w), 8n), dfs(sn_n(w), 8n)) == True{} : Bool}

law blade_m_closed:
  for +q: SM
  {closed_solid(dvs(2n, sm_m(q)), dedges(2n, sm_m(q)), dfs(2n, sm_m(q))) == True{} : Bool}

law ring_segs_len:
  for +m: Nat
  for left: Nat
  for +j: Nat
  {List.length(&2, BA.Sg, BA.ring_segs_go(m, left, j)) == left : Nat}

law walls_len:
  for +n: Nat
  for +m: Nat
  for left: Nat
  for +w: Nat
  {List.length(&2, List<&2, BA.Ub>, BA.walls_flat_go(n, m, left, w)) == left : Nat}

law blade_rows_len:
  for ses: List<&2, BA.SecE>
  for +m: Nat
  for +i: Nat
  {List.length(&2, BA.BR, BA.blade_rows_go(ses, m, i)) == List.length(&2, BA.SecE, ses) : Nat}

law blade_rows_nil:
  for +m: Nat
  for +i: Nat
  {BA.blade_rows_go([], m, i) == [] : List<&2, BA.BR>}

law blade_sections_refused:
  for s0: U64
  for s1: U64
  for s2: U64
  for s3: U64
  for s4: U64
  for s5: U64
  for s6: U64
  for s7: U64
  for s8: U64
  for z: X.Xp
  for tw: U64
  for tp: U64
  for e: X.Env
  for nd: U64
  for ns: List<&2, M.Node>
  {M.op_blade([s0, s1, s2, s3, s4, s5, s6, s7, s8], z, tw, tp, e, nd, ns) == M.NR_err{T.F_unsupported{}, M.Dg{"blade", "node " ++ U64.show(nd), "blade-sections-not-admitted", "stack 2 to 8 naca4 sections"}} : M.NR}

law blade_twist_refused:
  for s0: U64
  for s1: U64
  for z: X.Xp
  for tp: U64
  for e: X.Env
  for nd: U64
  for ns: List<&2, M.Node>
  {M.op_blade([s0, s1], z, 15u64, tp, e, nd, ns) == M.NR_err{T.F_unsupported{}, M.Dg{"blade", "node " ++ U64.show(nd), "twist-not-admitted", "twist 0, 10, 20 or 30 degrees"}} : M.NR}

law blade_taper_refused:
  for s0: U64
  for s1: U64
  for z: X.Xp
  for e: X.Env
  for nd: U64
  for ns: List<&2, M.Node>
  {M.op_blade([s0, s1], z, 0u64, 60u64, e, nd, ns) == M.NR_err{T.F_unsupported{}, M.Dg{"blade", "node " ++ U64.show(nd), "taper-not-admitted", "taper 50, 75 or 100 tip-chord percent"}} : M.NR}

law naca_digits_refused:
  for p: U64
  for t: U64
  for c: X.Xp
  for n: U64
  for e: X.Env
  for nd: U64
  {M.op_naca4(10u64, p, t, c, n, e, nd) == M.NR_err{T.F_unsupported{}, M.Dg{"naca4", "node " ++ U64.show(nd), "naca-digits-not-admitted", "use M 0-9, P 0-9 with P nonzero when M is nonzero, T 06-24"}} : M.NR}

law naca_points_refused:
  for e: X.Env
  for nd: U64
  {M.op_naca4(0u64, 0u64, 12u64, X.X_k{0.0f64}, 20u64, e, nd) == M.NR_err{T.F_unsupported{}, M.Dg{"naca4", "node " ++ U64.show(nd), "naca-points-not-admitted", "use 17, 33 or 65 points per surface"}} : M.NR}

law blade_span_refused:
  for s0: U64
  for s1: U64
  for e: X.Env
  for nd: U64
  for ns: List<&2, M.Node>
  {M.op_blade([s0, s1], X.X_k{0.0f64}, 0u64, 100u64, e, nd, ns) == M.NR_err{T.F_invalid{}, M.Dg{"blade", "node " ++ U64.show(nd), "degenerate-feature", "give finite positive chord and span"}} : M.NR}

law blade_ruled_refused:
  for x0: X.Xp
  for y0: X.Xp
  for z0: X.Xp
  for it0: M.It
  for x1: X.Xp
  for y1: X.Xp
  for z1: X.Xp
  for it1: M.It
  for e: X.Env
  for nd: U64
  {M.op_blade([1u64, 7u64], X.X_k{50.0f64}, 0u64, 100u64, e, nd, [M.Nd{1u64, M.O_box{x0, y0, z0}, it0}, M.Nd{7u64, M.O_box{x1, y1, z1}, it1}]) == M.NR_err{T.F_uncertain{}, M.Dg{"blade", "node " ++ U64.show(nd), "blade-stack-not-ruled", "stack admitted naca4 sections with equal points and chord"}} : M.NR}

law blade_needs_blade_refused:
  for x: X.Xp
  for y: X.Xp
  for z: X.Xp
  for it: M.It
  for e: X.Env
  {BA.blade_rep(7u64, M.bl_chain([M.Nd{7u64, M.O_box{x, y, z}, it}], 7u64), e) == "error invalid-input | blade | why: " ++ "blade-needs-blade" ++ " | fix: " ++ "run blade on a blade node" : String}
