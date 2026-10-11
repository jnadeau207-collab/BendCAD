import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c09/feat.bend as F9

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

def balanced(n: Nat, +us: List<&2, BD.Use>) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+k): Bool.and(Bool.and(Nat.is_eq(hits(us, k, True{}), 1n), Nat.is_eq(hits(us, k, False{}), 1n)), balanced(k, us))

def ends_below(es: List<&2, Ty.Edge>, +nv: Nat) -> Bool:
  match es:
    case []: True{}
    case +e <> t: Bool.and(Bool.and(Nat.is_lt(ev0(e), nv), Nat.is_lt(ev1(e), nv)), ends_below(t, nv))

def closed_solid(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +fs: List<&2, BD.FS>) -> Bool:
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nf = List.length(&2, BD.FS, fs)
  Bool.and(Bool.and(faces_closed(es, fs), balanced(ne, uses(fs))),
    Bool.and(ends_below(es, nv), Nat.is_eq(Nat.add(nv, nf), Nat.add(ne, 2n))))

law frustum_closed_solid:
  for +fr: F9.FR
  {closed_solid(F9.fr_vs(8n, 0n, fr), F9.fr_es(12n, 0n, fr), F9.fr_fs(fr)) == True{} : Bool}

law fillet_closed_solid:
  for +fm: F9.FM
  {closed_solid(F9.fil_vs(24n, 0n, fm), F9.fil_es(48n, 0n, fm), F9.fil_fs(26n, 0n, fm)) == True{} : Bool}

law cone_closed_solid:
  for +c: F9.CN
  {closed_solid(F9.cn_vs(10n, 0n, c), F9.cn_es(15n, 0n, c), F9.cn_fs(7n, 0n, c)) == True{} : Bool}
