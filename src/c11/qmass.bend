import Base
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/sx.bend as S
import ../c06/model.bend as M
import ../c07/ivx.bend as X
import ../c07/sol.bend as SO
import ../c07/im.bend as MI
import ../base/par.bend as B
import ./qcert.bend as QC
import ./qaccel.bend as QA

type Mc is Data:
  Mc{ k: U64, v: I.I, sx: I.I, sy: I.I, sz: I.I, txx: I.I, tyy: I.I, tzz: I.I, txy: I.I, txz: I.I,
    tyz: I.I }

type Ma is Data:
  Ma{ inn: Mc, unc: Mc, nin: Nat, nout: Nat, nunc: Nat }

type Qx is Data:
  Qx{ fds: List<&2, SO.Fd>, bb: List<&2, I.I>, allok: Bool }

def mc_k(+c: Mc) -> U64:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  k

def mc_v(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  v

def mc_sx(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  sx

def mc_sy(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  sy

def mc_sz(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  sz

def mc_txx(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  txx

def mc_tyy(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  tyy

def mc_tzz(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  tzz

def mc_txy(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  txy

def mc_txz(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  txz

def mc_tyz(+c: Mc) -> I.I:
  Mc{k, v, sx, sy, sz, txx, tyy, tzz, txy, txz, tyz} = c
  tyz

def mc_zero() -> Mc:
  Mc{0u64, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64},
    I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64},
    I.I{0.0f64, 0.0f64}, I.I{0.0f64, 0.0f64}}

def mc_add(+a: Mc, +b: Mc) -> Mc:
  Mc{0u64, I.iadd(mc_v(a), mc_v(b)), I.iadd(mc_sx(a), mc_sx(b)), I.iadd(mc_sy(a), mc_sy(b)),
    I.iadd(mc_sz(a), mc_sz(b)), I.iadd(mc_txx(a), mc_txx(b)), I.iadd(mc_tyy(a), mc_tyy(b)),
    I.iadd(mc_tzz(a), mc_tzz(b)), I.iadd(mc_txy(a), mc_txy(b)), I.iadd(mc_txz(a), mc_txz(b)),
    I.iadd(mc_tyz(a), mc_tyz(b))}

def ma_zero() -> Ma:
  Ma{mc_zero(), mc_zero(), 0n, 0n, 0n}

def ma_k(+k: U64, +inn: Mc, +unc: Mc, +nin: Nat, +nout: Nat, +nunc: Nat, +c: Mc) -> Ma:
  match k:
    case 0u64: Ma{inn, unc, nin, Nat.add(nout, 1n), nunc}
    case 1u64: Ma{mc_add(inn, c), unc, Nat.add(nin, 1n), nout, nunc}
    case _: Ma{inn, mc_add(unc, c), nin, nout, Nat.add(nunc, 1n)}

def split(+a: I.I) -> List<&2, I.I>:
  +m = I.imid(a)
  [I.I{I.i_lo(a), I.up(m)}, I.I{I.dn(m), I.i_hi(a)}]

def sub1(+x: I.I, +y: I.I, zs: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match zs:
    case []: []
    case z <> t: [x, y, z] <> sub1(x, y, t)

def qx_fds(+c: Qx) -> List<&2, SO.Fd>:
  Qx{fds, bb, allok} = c
  fds

def qx_bb(+c: Qx) -> List<&2, I.I>:
  Qx{fds, bb, allok} = c
  bb

def qx_allok(+c: Qx) -> Bool:
  Qx{fds, bb, allok} = c
  allok

def im_hit(+im: MI.Im, +cell: List<&2, I.I>) -> Bool:
  +v = MI.im_val(im, cell)
  Bool.and(F64.is_le(I.i_lo(v), 0.0f64), F64.is_le(0.0f64, I.i_hi(v)))

def qx_hit(ov: Bool, +f: SO.Fd, +cell: List<&2, I.I>) -> Bool:
  match ov:
    case False{}: False{}
    case True{}: im_hit(SO.fd_im(f), cell)

def qx_cross_go(fs: List<&2, SO.Fd>, +cell: List<&2, I.I>) -> Bool:
  match fs:
    case []: False{}
    case +f <> t:
      Bool.or(qx_hit(QA.ab_overlap(QA.ab_of_iv(SO.fd_bx(f)), QA.ab_of_iv(cell)), f, cell),
        qx_cross_go(t, cell))

def qx_cross(+fs: List<&2, SO.Fd>, +cell: List<&2, I.I>) -> Bool:
  qx_cross_go(fs, cell)

def qx_cen(+cell: List<&2, I.I>) -> V.Point:
  V.Pt{I.imid(X.vn(cell, 0n)), I.imid(X.vn(cell, 1n)), I.imid(X.vn(cell, 2n))}

def qx_k(+r: U64, +ov: Bool) -> U64:
  match ov:
    case True{}: 2u64
    case False{}: Bool.pick(U64, U64.is_eq(r, 1u64), 1u64, Bool.pick(U64, U64.is_eq(r, 0u64), 0u64, 2u64))

def iw(+a: I.I) -> I.I:
  I.isub(I.ipt(I.i_hi(a)), I.ipt(I.i_lo(a)))

def ic(+a: I.I) -> I.I:
  +m = I.imid(a)
  I.I{I.dn(m), I.up(m)}

def twelfth() -> I.I:
  +q = F64.div(1.0f64, 12.0f64)
  I.I{I.dn(q), I.up(q)}

def cell_mc(+cell: List<&2, I.I>, +k: U64) -> Mc:
  +x = X.vn(cell, 0n)
  +y = X.vn(cell, 1n)
  +z = X.vn(cell, 2n)
  +v = I.imul(I.imul(iw(x), iw(y)), iw(z))
  +cx = ic(x)
  +cy = ic(y)
  +cz = ic(z)
  +tw = twelfth()
  Mc{k, v, I.imul(v, cx), I.imul(v, cy), I.imul(v, cz),
    I.iadd(I.imul(v, I.iadd(I.isq(cy), I.isq(cz))), I.imul(v, I.imul(tw, I.iadd(I.isq(iw(y)), I.isq(iw(z)))))),
    I.iadd(I.imul(v, I.iadd(I.isq(cx), I.isq(cz))), I.imul(v, I.imul(tw, I.iadd(I.isq(iw(x)), I.isq(iw(z)))))),
    I.iadd(I.imul(v, I.iadd(I.isq(cx), I.isq(cy))), I.imul(v, I.imul(tw, I.iadd(I.isq(iw(x)), I.isq(iw(y)))))),
    I.ineg(I.imul(v, I.imul(cx, cy))), I.ineg(I.imul(v, I.imul(cx, cz))), I.ineg(I.imul(v, I.imul(cy, cz)))}

def tot_rg(+inn: I.I, +unc: I.I) -> I.I:
  I.iadd(inn, unc)

def h2(+a: I.I, +b: I.I) -> I.I:
  I.I{F64.min(I.i_lo(a), I.i_lo(b)), F64.max(I.i_hi(a), I.i_hi(b))}

def h3(+a: I.I, +b: I.I, +c: I.I) -> I.I:
  h2(a, h2(b, c))

def h5(+a: I.I, +b: I.I, +c: I.I, +d: I.I, +e: I.I) -> I.I:
  h2(h3(a, b, c), h2(d, e))

def maxpt(+a: I.I) -> I.I:
  I.ipt(F64.max(0.0f64, I.i_hi(a)))

def mx2(+a: I.I, +b: I.I) -> I.I:
  I.iadd(maxpt(I.isq(a)), maxpt(I.isq(b)))

def cell_mr(+cell: List<&2, I.I>, +k: U64) -> Mc:
  +x = X.vn(cell, 0n)
  +y = X.vn(cell, 1n)
  +z = X.vn(cell, 2n)
  +v = I.imul(I.imul(iw(x), iw(y)), iw(z))
  +x0 = I.ipt(I.i_lo(x))
  +x1 = I.ipt(I.i_hi(x))
  +y0 = I.ipt(I.i_lo(y))
  +y1 = I.ipt(I.i_hi(y))
  +z0 = I.ipt(I.i_lo(z))
  +z1 = I.ipt(I.i_hi(z))
  +p0 = I.ipt(0.0f64)
  Mc{k, h2(p0, v), h3(p0, I.imul(x0, v), I.imul(x1, v)), h3(p0, I.imul(y0, v), I.imul(y1, v)),
    h3(p0, I.imul(z0, v), I.imul(z1, v)),
    I.I{0.0f64, I.i_hi(I.imul(I.iadd(mx2(y0, y1), mx2(z0, z1)), v))},
    I.I{0.0f64, I.i_hi(I.imul(I.iadd(mx2(x0, x1), mx2(z0, z1)), v))},
    I.I{0.0f64, I.i_hi(I.imul(I.iadd(mx2(x0, x1), mx2(y0, y1)), v))},
    h5(p0, I.ineg(I.imul(I.imul(x0, y0), v)), I.ineg(I.imul(I.imul(x0, y1), v)),
      I.ineg(I.imul(I.imul(x1, y0), v)), I.ineg(I.imul(I.imul(x1, y1), v))),
    h5(p0, I.ineg(I.imul(I.imul(x0, z0), v)), I.ineg(I.imul(I.imul(x0, z1), v)),
      I.ineg(I.imul(I.imul(x1, z0), v)), I.ineg(I.imul(I.imul(x1, z1), v))),
    h5(p0, I.ineg(I.imul(I.imul(y0, z0), v)), I.ineg(I.imul(I.imul(y0, z1), v)),
      I.ineg(I.imul(I.imul(y1, z0), v)), I.ineg(I.imul(I.imul(y1, z1), v)))}

def qx_mk(+k: U64, +cell: List<&2, I.I>) -> Mc:
  match k:
    case 0u64: mc_zero()
    case 1u64: cell_mc(cell, k)
    case _: cell_mr(cell, k)

def mm_col(+r: Nat, +j: Nat, +a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  M.i_dot3(a, r, b, j, 3n)

def mm_row(+r: Nat, +j: Nat, +a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  M.i_dot3(a, r, b, Nat.mul(j, 3n), 1n)

def mm9(f: Nat, +t: Nat, +a: List<&2, I.I>, +b: List<&2, I.I>, +tr: Bool) -> List<&2, I.I>:
  match f:
    case 0n: []
    case 1n+g:
      Bool.pick(I.I, tr, mm_row(Nat.div(t, 3n), Nat.mod(t, 3n), a, b),
        mm_col(Nat.div(t, 3n), Nat.mod(t, 3n), a, b)) <> mm9(g, Nat.add(t, 1n), a, b, tr)

def mmul(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  mm9(9n, 0n, a, b, False{})

def mmult(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  mm9(9n, 0n, a, b, True{})

def i9_of(+txx: I.I, +tyy: I.I, +tzz: I.I, +txy: I.I, +txz: I.I, +tyz: I.I) -> List<&2, I.I>:
  [txx, txy, txz, txy, tyy, tyz, txz, tyz, tzz]

def rot_i(+mi: List<&2, I.I>, +loc: List<&2, I.I>) -> List<&2, I.I>:
  mmult(mmul(mi, loc), mi)

def sh9(+w: List<&2, I.I>, +m: I.I, +c: List<&2, I.I>) -> List<&2, I.I>:
  +cx = M.i_nth(c, 0n)
  +cy = M.i_nth(c, 1n)
  +cz = M.i_nth(c, 2n)
  [I.isub(M.i_nth(w, 0n), I.imul(m, I.iadd(I.isq(cy), I.isq(cz)))),
    I.iadd(M.i_nth(w, 1n), I.imul(m, I.imul(cx, cy))),
    I.iadd(M.i_nth(w, 2n), I.imul(m, I.imul(cx, cz))),
    I.iadd(M.i_nth(w, 3n), I.imul(m, I.imul(cx, cy))),
    I.isub(M.i_nth(w, 4n), I.imul(m, I.iadd(I.isq(cx), I.isq(cz)))),
    I.iadd(M.i_nth(w, 5n), I.imul(m, I.imul(cy, cz))),
    I.iadd(M.i_nth(w, 6n), I.imul(m, I.imul(cx, cz))),
    I.iadd(M.i_nth(w, 7n), I.imul(m, I.imul(cy, cz))),
    I.isub(M.i_nth(w, 8n), I.imul(m, I.iadd(I.isq(cx), I.isq(cy))))]

def pk6(+w: List<&2, I.I>) -> List<&2, I.I>:
  [M.i_nth(w, 0n), M.i_nth(w, 4n), M.i_nth(w, 8n), M.i_nth(w, 1n), M.i_nth(w, 2n),
    M.i_nth(w, 5n)]

def iv_s(+v: I.I) -> String:
  "[" ++ S.f_show(I.i_lo(v)) ++ ", " ++ S.f_show(I.i_hi(v)) ++ "]"

def iv3_s(+xs: List<&2, I.I>) -> String:
  iv_s(M.i_nth(xs, 0n)) ++ "x" ++ iv_s(M.i_nth(xs, 1n)) ++ "x" ++ iv_s(M.i_nth(xs, 2n))

def iv6_s(+xs: List<&2, I.I>) -> String:
  iv_s(M.i_nth(xs, 0n)) ++ " " ++ iv_s(M.i_nth(xs, 1n)) ++ " " ++ iv_s(M.i_nth(xs, 2n)) ++ " " ++
    iv_s(M.i_nth(xs, 3n)) ++ " " ++ iv_s(M.i_nth(xs, 4n)) ++ " " ++ iv_s(M.i_nth(xs, 5n))

def mass_line(+ms: M.Ms, +m0: F64, +m1: F64, +nin: Nat, +nout: Nat, +nunc: Nat, +d: Nat) -> String:
  "mass volume=" ++ iv_s(M.ms_vol(ms)) ++ " certified octree=" ++ iv_s(I.I{m0, m1}) ++ " depth=" ++
    Nat.show(d) ++ " cells=" ++ Nat.show(nin) ++ "/" ++ Nat.show(nout) ++ "/" ++ Nat.show(nunc)

def cl_of(+inn: Mc, +unc: Mc, +mr: I.I) -> List<&2, I.I>:
  [I.idiv(tot_rg(mc_sx(inn), mc_sx(unc)), mr), I.idiv(tot_rg(mc_sy(inn), mc_sy(unc)), mr),
    I.idiv(tot_rg(mc_sz(inn), mc_sz(unc)), mr)]

def cw_of(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +cl: List<&2, I.I>) -> List<&2, I.I>:
  +w = M.im_ap(mi, cl)
  [I.iadd(M.i_nth(w, 0n), M.i_nth(ti, 0n)), I.iadd(M.i_nth(w, 1n), M.i_nth(ti, 1n)),
    I.iadd(M.i_nth(w, 2n), M.i_nth(ti, 2n))]

def mass_full(+b: M.Body, +ms: M.Ms, +inn: Mc, +unc: Mc, +nin: Nat, +nout: Nat, +nunc: Nat, +d: Nat,
    +m0: F64, +m1: F64) -> String:
  +mr = I.ihull(I.ipt(m0), I.ipt(m1))
  +pl = M.bd_pl(b)
  +mi = M.pl_mi(pl)
  +ti = M.pl_ti(pl)
  +cl = cl_of(inn, unc, mr)
  +cw = cw_of(mi, ti, cl)
  +il = i9_of(tot_rg(mc_txx(inn), mc_txx(unc)), tot_rg(mc_tyy(inn), mc_tyy(unc)),
    tot_rg(mc_tzz(inn), mc_tzz(unc)), tot_rg(mc_txy(inn), mc_txy(unc)),
    tot_rg(mc_txz(inn), mc_txz(unc)), tot_rg(mc_tyz(inn), mc_tyz(unc)))
  mass_line(ms, m0, m1, nin, nout, nunc, d) ++ "\ncentroid " ++ iv3_s(cw) ++ " status=certified" ++ QC.inc_s(nunc) ++
    "\ninertia-centroid " ++ iv6_s(pk6(rot_i(mi, sh9(il, mr, cl)))) ++ " status=certified"

def ma_add(+m: Ma, +c: Mc) -> Ma:
  Ma{+inn, +unc, +nin, +nout, +nunc} = m
  ma_k(mc_k(c), inn, unc, nin, nout, nunc, c)

def ma_fold(cs: List<&2, Mc>, +acc: Ma) -> Ma:
  match cs:
    case []: acc
    case c <> t: ma_fold(t, ma_add(acc, c))

def sub2(+x: I.I, ys: List<&2, I.I>, +zs: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match ys:
    case []: []
    case y <> t: List.append(&2, List<&2, I.I>, sub1(x, y, zs), sub2(x, t, zs))

def qx_cls(ok: Bool, +c: Qx, +cell: List<&2, I.I>) -> U64:
  match ok:
    case False{}: 2u64
    case True{}: qx_k(SO.classify_in(qx_fds(c), qx_bb(c), qx_cen(cell)), qx_cross(qx_fds(c), cell))

def qx_class(+c: Qx, +cell: List<&2, I.I>) -> U64:
  qx_cls(qx_allok(c), c, cell)

def qx_go(+c: Qx, +cell: List<&2, I.I>) -> Mc:
  qx_mk(qx_class(c, cell), cell)

def qx_cell(c: Qx, cell: List<&2, I.I>) -> Mc:
  qx_go(c, cell)

def qx_of(+fs: List<&2, SO.Fd>) -> Qx:
  Qx{fs, SO.bbox(fs, []), QA.fd_allok(fs)}

def mass_rep(empty: Bool, +b: M.Body, +ms: M.Ms, +inn: Mc, +unc: Mc, +nin: Nat, +nout: Nat,
    +nunc: Nat, +d: Nat, +m0: F64, +m1: F64) -> String:
  match empty:
    case True{}: mass_line(ms, m0, m1, nin, nout, nunc, d) ++ "\ncentroid incomplete status=incomplete" ++ QC.inc_s(nunc)
    case False{}: mass_full(b, ms, inn, unc, nin, nout, nunc, d, m0, m1)

def sub3_go(xs: List<&2, I.I>, +ys: List<&2, I.I>, +zs: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  match xs:
    case []: []
    case x <> t: List.append(&2, List<&2, I.I>, sub2(x, ys, zs), sub3_go(t, ys, zs))

def mass_run(+ms: M.Ms, +b: M.Body, a: Ma, +d: Nat) -> String:
  Ma{+inn, +unc, +nin, +nout, +nunc} = a
  +m0 = I.i_lo(mc_v(inn))
  +m1 = I.i_hi(I.iadd(mc_v(inn), mc_v(unc)))
  mass_rep(F64.is_le(m0, 0.0f64), b, ms, inn, unc, nin, nout, nunc, d, m0, m1)

def sub3(+xs: List<&2, I.I>) -> List<&2, List<&2, I.I>>:
  sub3_go(split(X.vn(xs, 0n)), split(X.vn(xs, 1n)), split(X.vn(xs, 2n)))

def sub_all(cs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match cs:
    case []: []
    case c <> t: List.append(&2, List<&2, I.I>, sub3(c), sub_all(t))

def sub_go(+d: Nat, +cs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, I.I>>:
  match d:
    case 0n: cs
    case 1n+j: sub_go(j, sub_all(cs))

def run_cells(+fs: List<&2, SO.Fd>, +d: Nat) -> Ma:
  ma_fold(B.pmap_g(~List<&2, I.I>, ~Qx, ~Mc, ~qx_cell, 2, qx_of(fs), sub_go(d, [SO.bbox(fs, [])])), ma_zero())

def mass_go(+b: M.Body, +d: Nat) -> String:
  mass_run(M.body_ms(b), b, run_cells(SO.fds_of(M.bd_brep(b)), d), d)

def mass_dn(m: Maybe<&2, U64>) -> Nat:
  match m:
    case None{}: 99n
    case Some{v}: U64.to_nat(v)

def mass_depth(+arg: String) -> Nat:
  Bool.pick(Nat, String.eq(arg, ""), QC.depth_dflt(), mass_dn(U64.read(arg)))

def mass_dep(ok: Bool, +b: M.Body, +d: Nat) -> String:
  match ok:
    case False{}: QC.qfail("invalid-input", "mass", "depth needs 0..6", "mass NODE [DEPTH]")
    case True{}: mass_go(b, d)

def mass_s(r: M.NR, +d: Nat) -> String:
  match r:
    case M.NR_err{k, dg}: "error: node failed; nothing measured"
    case M.NR_ok{+b, fx}: mass_dep(QC.depth_ok(d), b, d)
