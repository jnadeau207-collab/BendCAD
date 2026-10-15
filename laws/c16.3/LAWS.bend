import Base
import ../../src/c01/types.bend as V
import ../../src/c03/types.bend as G
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
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

law fin_go_false:
  {BA.fin_go(False{}) == BA.GR_no{"degenerate-feature", "give finite positive chord and span"} : BA.GR}

law dg_go_false:
  {BA.dg_go(False{}) == BA.GR_no{"naca-digits-not-admitted", "use M 0-9, P 0-9 with P nonzero when M is nonzero, T 06-24"} : BA.GR}

law np_go_false:
  {BA.np_go(False{}) == BA.GR_no{"naca-points-not-admitted", "use 17, 33 or 65 points per surface"} : BA.GR}

law ns_go_false:
  {BA.ns_go(False{}) == BA.GR_no{"blade-sections-not-admitted", "stack 2 to 8 naca4 sections"} : BA.GR}

law tw_go_false:
  for +tw: U64
  {BA.tw_go(False{}, tw) == BA.GR_no{"twist-not-admitted", "twist 0, 10, 20 or 30 degrees"} : BA.GR}

law tp_go_false:
  for +tp: U64
  {BA.tp_go(False{}, tp) == BA.GR_no{"taper-not-admitted", "taper 50, 75 or 100 tip-chord percent"} : BA.GR}

law rl_go_false:
  {BA.rl_go(False{}) == BA.GR_no{"blade-stack-not-ruled", "stack admitted naca4 sections with equal points and chord"} : BA.GR}

law bl_go_false:
  {BA.bl_go(False{}) == BA.GR_no{"blade-needs-blade", "run blade on a blade node"} : BA.GR}
