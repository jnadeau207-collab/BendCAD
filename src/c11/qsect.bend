import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c01/ops.bend as O1
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ../c06/model.bend as M
import ../c07/ivx.bend as X
import ../c07/sol.bend as SO
import ../c07/xs.bend as Q
import ../c07/par.bend as PA
import ../c07/ss.bend as SS
import ../c07/isect.bend as Y
import ./qcert.bend as QC
import ./qaccel.bend as QA
import ./qinterf.bend as QI

type Sg is Data:
  Sg{ s: String, nc: Nat, nu: Nat, nk: Nat, ok: Bool }

type ON is Data:
  ON{ o: V.Point, n: V.Dir }

def fs(+x: F64) -> String:
  S.f_show(x)

def si(+a: I.I) -> String:
  "[" ++ fs(I.i_lo(a)) ++ ", " ++ fs(I.i_hi(a)) ++ "]"

def sp3(+p: List<&2, I.I>) -> String:
  si(X.vn(p, 0n)) ++ "x" ++ si(X.vn(p, 1n)) ++ "x" ++ si(X.vn(p, 2n))

def sp2(p: List<&2, I.I>) -> String:
  match p:
    case []: "-"
    case a <> t: "(" ++ si(a) ++ ", " ++ si(X.vn(t, 0n)) ++ ")"

def cls_k(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(c, 0u64), "interior",
    Bool.pick(String, U64.is_eq(c, 16u64), "seam",
      Bool.pick(String, U64.is_eq(U64.and(c, 1u64), 1u64), "a-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 2u64), 2u64), "a-end ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 4u64), 4u64), "b-start ", "") ++
      Bool.pick(String, U64.is_eq(U64.and(c, 8u64), 8u64), "b-end ", "")))

def cls_s(+c: U64) -> String:
  Bool.pick(String, U64.is_eq(U64.and(c, 32u64), 32u64), "tangent ", "") ++ cls_k(U64.and(c, 31u64))

def hit_s(h: Q.Hit) -> String:
  match h:
    case Q.H_pt{s, t, p, cls}: "point s=" ++ si(s) ++ " t=" ++ si(t) ++ " at=" ++ sp3(p) ++ " class=" ++ cls_s(cls)
    case Q.H_ov{s, t}: "overlap s=" ++ si(s) ++ " t=" ++ si(t)
    case Q.H_un{s, t, p}: "unresolved s=" ++ si(s) ++ " t=" ++ si(t) ++ " near=" ++ sp3(p)
    case Q.H_no{w}: "error unsupported-op | intersect | why: " ++ w

def hit_k(h: Q.Hit) -> U64:
  match h:
    case Q.H_pt{s, t, p, c}: 0u64
    case Q.H_ov{s, t}: 1u64
    case Q.H_un{s, t, p}: 2u64
    case Q.H_no{w}: 3u64

def hx_str(h: Y.Hx) -> String:
  match h:
    case Y.Hx_c{w}: hit_s(w)
    case Y.Hx_uv{s, u, v, p, cls}: "point s=" ++ si(s) ++ " u=" ++ si(u) ++ " v=" ++ si(v) ++ " at=" ++ sp3(p) ++ " class=" ++ cls_s(cls)
    case Y.Hx_un3{s, u, v}: "unresolved s=" ++ si(s) ++ " u=" ++ si(u) ++ " v=" ++ si(v)

def hx_k(h: Y.Hx) -> U64:
  match h:
    case Y.Hx_c{w}: hit_k(w)
    case Y.Hx_uv{s, u, v, p, cls}: 0u64
    case Y.Hx_un3{s, u, v}: 2u64

def hxs_s(hs: List<&2, Y.Hx>) -> String:
  match hs:
    case []: ""
    case h <> t: hx_str(h) ++ "\n" ++ hxs_s(t)

def cnt(hs: List<&2, Y.Hx>, +k: U64) -> Nat:
  match hs:
    case []: 0n
    case h <> t:
      +me = Bool.pick(Nat, U64.is_eq(hx_k(h), k), 1n, 0n)
      Nat.add(me, cnt(t, k))

def report(+hs: List<&2, Y.Hx>) -> String:
  hxs_s(hs) ++ "summary points=" ++ Nat.show(cnt(hs, 0u64)) ++ " overlaps=" ++ Nat.show(cnt(hs, 1u64)) ++ " unresolved=" ++ Nat.show(cnt(hs, 2u64))

def coord_name(+kind: U64, +k: Nat) -> String:
  Bool.pick(String, U64.is_eq(kind, 0u64), Bool.pick(String, Nat.is_eq(k, 0n), "x", Bool.pick(String, Nat.is_eq(k, 1n), "y", "z")),
    Bool.pick(String, U64.is_eq(kind, 3u64), Bool.pick(String, Nat.is_eq(k, 0n), "u1", Bool.pick(String, Nat.is_eq(k, 1n), "v1", Bool.pick(String, Nat.is_eq(k, 2n), "u2", "v2"))),
      Bool.pick(String, Nat.is_eq(k, 0n), "u", "v")))

def ep_s(e: SS.Ep, +kind: U64) -> String:
  SS.Ep{k, c, z, i, s} = e
  "  end at " ++ coord_name(kind, k) ++ "=" ++ fs(c) ++ "\n"

def eps_s(es: List<&2, SS.Ep>, +kind: U64) -> String:
  match es:
    case []: ""
    case e <> t: ep_s(e, kind) ++ eps_s(t, kind)

def drop2(xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case a <> t:
      match t:
        case []: []
        case b <> u: u

def par_a(+kind: U64, +ga: G.GVal, +x: List<&2, I.I>, +p: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, Bool.or(U64.is_eq(kind, 1u64), U64.is_eq(kind, 3u64)), x, PA.sf_par(ga, p))

def par_b(+kind: U64, +gb: G.GVal, +x: List<&2, I.I>, +p: List<&2, I.I>) -> List<&2, I.I>:
  Bool.pick(List<&2, I.I>, U64.is_eq(kind, 2u64), x, Bool.pick(List<&2, I.I>, U64.is_eq(kind, 3u64), drop2(x), PA.sf_par(gb, p)))

def pts_s(ps: List<&2, List<&2, I.I>>, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match ps:
    case []: ""
    case +x <> t:
      +p = Y.sample3(kind, ga, gb, x)
      "  p " ++ sp3(p) ++ " a=" ++ sp2(par_a(kind, ga, x, p)) ++ " b=" ++ sp2(par_b(kind, gb, x, p)) ++ "\n" ++ pts_s(t, kind, ga, gb)

def br_s(b: SS.Br, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  SS.Br{closed, +pts, ends} = b
  "curve " ++ Bool.pick(String, closed, "closed", "open") ++ " samples=" ++ Nat.show(List.length(&2, List<&2, I.I>, pts)) ++ "\n" ++ pts_s(pts, kind, ga, gb) ++ eps_s(ends, kind)

def brs_s(bs: List<&2, SS.Br>, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match bs:
    case []: ""
    case b <> t: br_s(b, kind, ga, gb) ++ brs_s(t, kind, ga, gb)

def uns_go(n: Nat, us: List<&2, List<&2, I.I>>) -> String:
  match n:
    case 0n: ""
    case 1n+m:
      match us:
        case []: ""
        case u <> t: "unresolved box " ++ sp3(u) ++ "\n" ++ uns_go(m, t)

def hull_all(us: List<&2, List<&2, I.I>>, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match us:
    case []: acc
    case u <> t: hull_all(t, X.vhull(acc, u))

def first_box(us: List<&2, List<&2, I.I>>) -> List<&2, I.I>:
  match us:
    case []: []
    case u <> t: u

def uns_s(+us: List<&2, List<&2, I.I>>) -> String:
  +n = List.length(&2, List<&2, I.I>, us)
  uns_go(32n, us) ++ Bool.pick(String, Nat.is_lt(32n, n), "unresolved more=" ++ Nat.show(Nat.sub(n, 32n)) ++ " hull=" ++ sp3(hull_all(us, first_box(us))) ++ "\n", "")

def ss_body(s: SS.Ss, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  SS.Ss{ok, +brs, +un} = s
  brs_s(brs, kind, ga, gb) ++ uns_s(un) ++ "summary curves=" ++ Nat.show(List.length(&2, SS.Br, brs)) ++ " unresolved=" ++ Nat.show(List.length(&2, List<&2, I.I>, un))

def sr_go(coin: Bool, s: SS.Ss, +kind: U64, +ga: G.GVal, +gb: G.GVal) -> String:
  match coin:
    case True{}: "overlap surfaces coincide\nsummary curves=0 unresolved=0 coincident=1"
    case False{}: ss_body(s, kind, ga, gb)

def sr_s(r: Y.Sr, +ga: G.GVal, +gb: G.GVal) -> String:
  Y.Sr{ss, kind, coin} = r
  sr_go(coin, ss, kind, ga, gb)

def fin4(+a: F64, +b: F64, +c: F64, +d: F64) -> Bool:
  Bool.and(T.is_finite(a), Bool.and(T.is_finite(b), Bool.and(T.is_finite(c), T.is_finite(d))))

def hint_of(+a: F64, +b: F64, +c: F64) -> V.Dir:
  +aa = F64.abs(a)
  +bb = F64.abs(b)
  Bool.pick(V.Dir, Bool.and(F64.is_le(aa, bb), F64.is_le(aa, F64.abs(c))), V.Dr{1.0f64, 0.0f64, 0.0f64},
    Bool.pick(V.Dir, F64.is_le(bb, F64.abs(c)), V.Dr{0.0f64, 1.0f64, 0.0f64}, V.Dr{0.0f64, 0.0f64, 1.0f64}))

def plane_fr_mk(+f: V.Frame) -> Maybe<&2, G.GVal>:
  V.Fr{+ox, +oy, +oz, +xx, +xy, +xz, +yx, +yy, +yz, +zx, +zy, +zz} = f
  Some{G.GV_pl{G.Pl{V.Pt{ox, oy, oz}, V.Dr{xx, xy, xz}, V.Dr{yx, yy, yz}}}}

def rt_c(+mi: List<&2, I.I>, +d: V.Dir, +j: Nat) -> F64:
  V.Dr{+x, +y, +z} = d
  I.imid(I.iadd(I.iadd(I.imul(M.i_nth(mi, j), I.ipt(x)), I.imul(M.i_nth(mi, Nat.add(j, 3n)), I.ipt(y))), I.imul(M.i_nth(mi, Nat.add(j, 6n)), I.ipt(z))))

def rt_ap(+mi: List<&2, I.I>, +d: V.Dir) -> V.Dir:
  V.Dr{rt_c(mi, d, 0n), rt_c(mi, d, 1n), rt_c(mi, d, 2n)}

def sg_empty() -> Sg:
  Sg{"", 0n, 0n, 0n, True{}}

def sg_s(+a: Sg) -> String:
  Sg{s, nc, nu, nk, o} = a
  s

def sg_nc(+a: Sg) -> Nat:
  Sg{s, nc, nu, nk, o} = a
  nc

def sg_nu(+a: Sg) -> Nat:
  Sg{s, nc, nu, nk, o} = a
  nu

def sg_nk(+a: Sg) -> Nat:
  Sg{s, nc, nu, nk, o} = a
  nk

def sg_ok(+a: Sg) -> Bool:
  Sg{s, nc, nu, nk, o} = a
  o

def sg_add(+a: Sg, +line: String, +c: Nat, +u: Nat, +k: Nat, +ok: Bool) -> Sg:
  Sg{sg_s(a) ++ line, Nat.add(sg_nc(a), c), Nat.add(sg_nu(a), u), Nat.add(sg_nk(a), k),
    Bool.and(sg_ok(a), ok)}

def ss_nbr(s: SS.Ss) -> Nat:
  SS.Ss{ok, brs, un} = s
  List.length(&2, SS.Br, brs)

def ss_nun(s: SS.Ss) -> Nat:
  SS.Ss{ok, brs, un} = s
  List.length(&2, List<&2, I.I>, un)

def ss_ok(s: SS.Ss) -> Bool:
  SS.Ss{ok, brs, un} = s
  ok

def sect_ss(+ss: SS.Ss, +kind: U64, +coin: Bool, +pl: G.GVal, +g: G.GVal, +at: Nat) -> Sg:
  sg_add(sg_empty(), "face " ++ Nat.show(at) ++ ":\n" ++ sr_go(coin, ss, kind, pl, g) ++ "\n",
    ss_nbr(ss), ss_nun(ss), Bool.pick(Nat, coin, 1n, 0n), ss_ok(ss))

def sg_cat(+a: Sg, +b: Sg) -> Sg:
  Sg{sg_s(a) ++ sg_s(b), Nat.add(sg_nc(a), sg_nc(b)), Nat.add(sg_nu(a), sg_nu(b)),
    Nat.add(sg_nk(a), sg_nk(b)), Bool.and(sg_ok(a), sg_ok(b))}

def sect_rep(+g: Sg, +nf: Nat, +mapped: Bool) -> String:
  sg_s(g) ++ "summary faces=" ++ Nat.show(nf) ++ " curves=" ++ Nat.show(sg_nc(g)) ++ " unresolved=" ++
    Nat.show(sg_nu(g)) ++ " coincident=" ++ Nat.show(sg_nk(g)) ++ " status=" ++
    Bool.pick(String, Bool.and(sg_ok(g), Bool.and(Nat.is_eq(sg_nu(g), 0n), Bool.not(mapped))),
      "certified", "estimated") ++
    Bool.pick(String, mapped, " plane=mapped", "")

def plane_fr_go(ok: Bool, r: V.CRes) -> Maybe<&2, G.GVal>:
  match ok:
    case False{}: None{}
    case True{}: plane_fr_mk(V.cres_fr(r))

def sect_sr(r: Y.Sr, +pl: G.GVal, +g: G.GVal, +at: Nat) -> Sg:
  Y.Sr{ss, kind, coin} = r
  sect_ss(ss, kind, coin, pl, g, at)

def plane_gv(+o: V.Point, +n: V.Dir) -> Maybe<&2, G.GVal>:
  V.Dr{+a, +b, +c} = n
  +r = O1.frame_basis(o, V.Dr{a, b, c}, hint_of(a, b, c))
  plane_fr_go(V.cres_ok(r), r)

def plane_on_go(ok: Bool, +a: F64, +b: F64, +c: F64, +dd: F64) -> Maybe<&2, ON>:
  match ok:
    case False{}: None{}
    case True{}:
      +nn = F64.add(F64.mul(a, a), F64.add(F64.mul(b, b), F64.mul(c, c)))
      +k = F64.div(dd, nn)
      Some{ON{V.Pt{F64.mul(k, a), F64.mul(k, b), F64.mul(k, c)}, V.Dr{a, b, c}}}

def plane_on(+a: F64, +b: F64, +c: F64, +dd: F64) -> Maybe<&2, ON>:
  plane_on_go(Bool.and(fin4(a, b, c, dd), F64.is_lt(0.0f64, F64.add(F64.mul(a, a), F64.add(F64.mul(b, b), F64.mul(c, c))))), a, b, c, dd)

def local_plane(+o: V.Point, +n: V.Dir, +p: M.Pl) -> Maybe<&2, G.GVal>:
  plane_gv(QI.loc_pt(p, V.pt_x(o), V.pt_y(o), V.pt_z(o)), rt_ap(M.pl_mi(p), n))

def pl_ident(+p: M.Pl) -> Bool:
  M.Pl{+m, +tx, +ty, +tz, +mi, +ti} = p
  V.M3{+a, +b, +c, +d, +e, +f, +g, +h, +i} = m
  Bool.and(F64.is_eq(tx, 0.0f64),
    Bool.and(F64.is_eq(ty, 0.0f64),
      Bool.and(F64.is_eq(tz, 0.0f64),
        Bool.and(F64.is_eq(a, 1.0f64),
          Bool.and(F64.is_eq(e, 1.0f64),
            Bool.and(F64.is_eq(i, 1.0f64),
              Bool.and(F64.is_eq(b, 0.0f64),
                Bool.and(F64.is_eq(c, 0.0f64),
                  Bool.and(F64.is_eq(d, 0.0f64),
                    Bool.and(F64.is_eq(f, 0.0f64),
                      Bool.and(F64.is_eq(g, 0.0f64), F64.is_eq(h, 0.0f64))))))))))))

def sect_plane_id(idp: Bool, +o: V.Point, +n: V.Dir, +p: M.Pl) -> Maybe<&2, G.GVal>:
  match idp:
    case True{}: plane_gv(o, n)
    case False{}: local_plane(o, n, p)

def sect_on(m: Maybe<&2, ON>, +p: M.Pl, idp: Bool) -> Maybe<&2, G.GVal>:
  match m:
    case None{}: None{}
    case Some{w}:
      ON{+o, +n} = w
      sect_plane_id(idp, o, n, p)

def sect_one(+pl: G.GVal, +f: Ty.Face, +fd: SO.Fd, +at: Nat) -> Sg:
  sect_sr(Y.inter_ss(pl, Ty.fa_surf(f), SO.fd_bx(fd)), pl, Ty.fa_surf(f), at)

def sect_find(fds: List<&2, SO.Fd>, +at: Nat) -> Maybe<&2, SO.Fd>:
  match fds:
    case []: None{}
    case +f <> t: Bool.pick(Maybe<&2, SO.Fd>, Nat.is_eq(SO.fd_fi(f), at), Some{f}, sect_find(t, at))

def sect_miss(+at: Nat) -> Sg:
  Sg{"face " ++ Nat.show(at) ++ ":\nunresolved no-descriptor\n", 0n, 1n, 0n, False{}}

def sect_at(m: Maybe<&2, SO.Fd>, +pl: G.GVal, +f: Ty.Face, +at: Nat) -> Sg:
  match m:
    case None{}: sect_miss(at)
    case Some{+fd}: sect_one(pl, f, fd, at)

def sect_zip(fs: List<&2, Ty.Face>, +fds: List<&2, SO.Fd>, +pl: G.GVal, +at: Nat, +acc: Sg) -> Sg:
  match fs:
    case []: acc
    case f <> t: sect_zip(t, fds, pl, Nat.add(at, 1n), sg_cat(acc, sect_at(sect_find(fds, at), pl, f, at)))

def sect_go(+pl: G.GVal, +b: M.Body, mapped: Bool) -> String:
  sect_rep(sect_zip(Ty.brep_fas(M.bd_brep(b)), SO.fds_of(M.bd_brep(b)), pl, 0n, sg_empty()),
    List.length(&2, Ty.Face, Ty.brep_fas(M.bd_brep(b))), mapped)

def sect_with(m: Maybe<&2, G.GVal>, +b: M.Body, mapped: Bool) -> String:
  match m:
    case None{}: QC.qfail("invalid-input", "section", "the plane needs four finite numbers with a nonzero normal", "section NODE A B C D")
    case Some{+pl}: sect_go(pl, b, mapped)

def sect_plane(+a: F64, +b: F64, +c: F64, +dd: F64, +p: M.Pl) -> Maybe<&2, G.GVal>:
  sect_on(plane_on(a, b, c, dd), p, pl_ident(p))

def sect_s(r: M.NR, +a: F64, +b: F64, +c: F64, +d: F64) -> String:
  match r:
    case M.NR_err{k, dg}: "error: node failed; nothing sectioned"
    case M.NR_ok{+bd, fx}: sect_with(sect_plane(a, b, c, d, M.bd_pl(bd)), bd, Bool.not(pl_ident(M.bd_pl(bd))))
