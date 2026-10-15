import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/build.bend as BD
import ../../src/c06/revolve.bend as RV
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

law lo_go_false:
  {SU.lo_go(False{}) == SU.GR_no{"loft-open-not-planar", "loft-open axis-aligned rect pairs with planar walls"} : SU.GR}

law sa_go_false:
  for +deg: U64
  {SU.sa_go(False{}, deg) == SU.GR_no{"sweep-angle-not-certified", "sweep-open 90, 180 or 270 degrees"} : SU.GR}

law sp_go_false:
  {SU.sp_go(False{}) == SU.GR_no{"sweep-profile-not-admitted", "sweep-open one axis-aligned rect profile off the axis"} : SU.GR}

law pa_go_false:
  {SU.pa_go(False{}) == SU.GR_no{"patch-degenerate", "give 16 finite control points with distinct rows, columns and corners"} : SU.GR}

law tc_go_false:
  {SU.tc_go(False{}) == SU.GR_no{"thicken-curvature-not-certified", "thicken rect patches, rect ducts and rect sectors only"} : SU.GR}

law ts_go_false:
  {SU.ts_go(False{}) == SU.GR_no{"thicken-consumes-shell", "keep wall thickness below the shell minimum"} : SU.GR}

law su_go_false:
  {SU.su_go(False{}) == SU.GR_no{"surf-needs-open-shell", "run surf on a loft-open, sweep-open or patch node"} : SU.GR}

law th_go_false:
  {SU.th_go(False{}) == SU.GR_no{"thicken-needs-open-shell", "thicken-open an open-shell node"} : SU.GR}

law dg_go_false:
  for +t: F64
  {SU.dg_go(False{}, t) == SU.GR_no{"degenerate-feature", "give finite positive wall thickness"} : SU.GR}
