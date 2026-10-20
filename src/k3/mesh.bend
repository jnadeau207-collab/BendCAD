import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c07/ivx.bend as X
import ../c07/xs.bend as XS
import ../c07/mem.bend as Mm
import ../c07/im.bend as MI
import ../c07/sol.bend as SO
import ../base/par.bend as B

type LX is Data:
  LX{ ok: Bool, ts: List<&2, F64> }

type GR is Data:
  GR{ ox: F64, oy: F64, oz: F64, h: F64, nx: Nat, ny: Nat, nz: Nat }

def lx_ok(+l: LX) -> Bool:
  LX{ok, ts} = l
  ok

def lx_ts(+l: LX) -> List<&2, F64>:
  LX{ok, ts} = l
  ts

def pt_t(+s: I.I, +m: U64, +acc: LX) -> LX:
  LX{+ok, +ts} = acc
  Bool.pick(LX, U64.is_eq(m, 0u64), LX{ok, ts}, Bool.pick(LX, U64.is_eq(m, 1u64), LX{ok, I.imid(s) <> ts}, LX{False{}, ts}))

def bad_t(+acc: LX) -> LX:
  LX{ok, +ts} = acc
  LX{False{}, ts}

def hit_t(h: XS.Hit, +fc: Mm.Fc, +im: MI.Im, +acc: LX) -> LX:
  match h:
    case XS.H_pt{+s, t, +pb, c}: pt_t(s, Mm.member(fc, pb, im), acc)
    case _: bad_t(acc)

def hits_t(hs: List<&2, XS.Hit>, +fc: Mm.Fc, +im: MI.Im, +acc: LX) -> LX:
  match hs:
    case []: acc
    case +h <> t: hits_t(t, fc, im, hit_t(h, fc, im, acc))

def face_t(+f: SO.Fd, +p: V.Point, +d: V.Dir, +len: F64, +sb: List<&2, I.I>, +acc: LX) -> LX:
  Bool.pick(LX, X.vdisj(SO.fd_bx(f), sb), acc,
    hits_t(XS.inter_cs(G.GV_ln{G.Ln{p, d}}, G.Dom{0.0f64, len}, SO.fd_g(f), 40n), SO.fd_fc(f), SO.fd_im(f), acc))

def faces_t(fs: List<&2, SO.Fd>, +p: V.Point, +d: V.Dir, +len: F64, +sb: List<&2, I.I>, +acc: LX) -> LX:
  match fs:
    case []: acc
    case +f <> t: faces_t(t, p, d, len, sb, face_t(f, p, d, len, sb, acc))

def fcmp2(+a: F64, +b: F64) -> B.Sgn:
  Bool.pick(B.Sgn, F64.is_lt(a, b), B.Sn{}, Bool.pick(B.Sgn, F64.is_lt(b, a), B.Sp{}, B.Sz{}))

def fcmp(a: F64, b: F64) -> B.Sgn:
  fcmp2(a, b)

def so_f(s: B.So<&2, F64>) -> List<&2, F64>:
  B.So{ok, xs} = s
  xs

def seg_xs(+fs: List<&2, SO.Fd>, +p: V.Point, +d: V.Dir, +len: F64) -> LX:
  +sb = SO.seg_box(p, d, len)
  +r = faces_t(fs, p, d, len, sb, LX{True{}, []})
  LX{lx_ok(r), so_f(B.msort(~F64, ~fcmp, lx_ts(r)))}

def below(ts: List<&2, F64>, +t: F64, +n: Nat) -> Nat:
  match ts:
    case []: n
    case +x <> r: Bool.pick(Nat, F64.is_lt(x, t), below(r, t, Nat.add(n, 1n)), n)

def nat_f(+n: Nat) -> F64:
  U64.to_f64(U64.from_nat(n))

def line_signs(i: Nat, +n: Nat, +h: F64, +ts: List<&2, F64>) -> List<&2, Bool>:
  match i:
    case 0n: []
    case 1n+(+j):
      +t = F64.mul(h, nat_f(Nat.sub(Nat.sub(n, 1n), j)))
      Nat.is_eq(Nat.mod(below(ts, t, 0n), 2n), 1n) <> line_signs(j, n, h, ts)

type GS is Data:
  GS{ ok: Bool, s: List<&2, Bool> }

def xdir() -> V.Dir:
  V.Dr{1.0f64, 0.0f64, 0.0f64}

type LN is Data:
  LN{ p: V.Point, n: Nat, h: F64 }

type FX is Data:
  FX{ fs: List<&2, SO.Fd> }

def line_f(c: FX, l: LN) -> GS:
  FX{+fs} = c
  LN{+p, +n, +h} = l
  +r = seg_xs(fs, p, xdir(), F64.mul(h, nat_f(n)))
  GS{lx_ok(r), line_signs(n, n, h, lx_ts(r))}

def gs_join(+x: GS, +y: GS) -> GS:
  GS{+ok, +s} = x
  GS{+ok2, +s2} = y
  GS{Bool.and(ok, ok2), List.append(&2, Bool, s, s2)}

def gs_cat(xs: List<&2, GS>) -> GS:
  match xs:
    case []: GS{True{}, []}
    case +x <> t: gs_join(x, gs_cat(t))

def ln_j(j: Nat, +x0: F64, +y0: F64, +z: F64, +h: F64, +n: Nat, +acc: List<&2, LN>) -> List<&2, LN>:
  match j:
    case 0n: acc
    case 1n+(+m): ln_j(m, x0, y0, z, h, n, LN{V.Pt{x0, F64.add(y0, F64.mul(h, nat_f(m))), z}, n, h} <> acc)

def ln_k(k: Nat, +x0: F64, +y0: F64, +z0: F64, +h: F64, +n: Nat, +nj: Nat, +acc: List<&2, LN>) -> List<&2, LN>:
  match k:
    case 0n: acc
    case 1n+(+m): ln_k(m, x0, y0, z0, h, n, nj, ln_j(nj, x0, y0, F64.add(z0, F64.mul(h, nat_f(m))), h, n, acc))

def rows(+fs: List<&2, SO.Fd>, +x0: F64, +y0: F64, +z0: F64, +h: F64, +n: Nat, +nj: Nat, +nk: Nat) -> GS:
  gs_cat(B.pmap_g(~LN, ~FX, ~GS, ~line_f, 4, FX{fs}, ln_k(nk, x0, y0, z0, h, n, nj, [])))

def signs_a(+fs: List<&2, SO.Fd>, +gr: GR) -> GS:
  GR{+ox, +oy, +oz, +h, +nx, +ny, +nz} = gr
  rows(fs, ox, oy, oz, h, nx, ny, nz)

def signs_b(+fs: List<&2, SO.Fd>, +gr: GR) -> GS:
  GR{+ox, +oy, +oz, +h, +nx, +ny, +nz} = gr
  +hh = F64.mul(0.5f64, h)
  rows(fs, F64.add(ox, hh), F64.add(oy, hh), F64.add(oz, hh), h, Nat.sub(nx, 1n), Nat.sub(ny, 1n), Nat.sub(nz, 1n))

def ceil_n(+x: F64) -> Nat:
  U64.to_nat(F64.to_u64(F64.add(F64.max(0.0f64, x), 0.999999f64)))

def grid_of(+bb: List<&2, I.I>, +h: F64) -> GR:
  +lx = X.vn(bb, 0n)
  +ly = X.vn(bb, 1n)
  +lz = X.vn(bb, 2n)
  +ox = F64.sub(I.i_lo(lx), F64.mul(h, 1.6180339887498949f64))
  +oy = F64.sub(I.i_lo(ly), F64.mul(h, 1.4142135623730951f64))
  +oz = F64.sub(I.i_lo(lz), F64.mul(h, 1.7320508075688772f64))
  GR{ox, oy, oz, h, Nat.add(ceil_n(F64.div(F64.sub(I.i_hi(lx), ox), h)), 2n), Nat.add(ceil_n(F64.div(F64.sub(I.i_hi(ly), oy), h)), 2n),
    Nat.add(ceil_n(F64.div(F64.sub(I.i_hi(lz), oz), h)), 2n)}

def n_in(xs: List<&2, Bool>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case +x <> t: n_in(t, Bool.pick(Nat, x, Nat.add(n, 1n), n))

type GD is Data:
  GD{ gr: GR, na: Nat, nb: Nat, sg: B.Tb<&2, Bool> }

def gr_nx(+g: GR) -> Nat:
  GR{ox, oy, oz, h, nx, ny, nz} = g
  nx

def gr_ny(+g: GR) -> Nat:
  GR{ox, oy, oz, h, nx, ny, nz} = g
  ny

def gr_nz(+g: GR) -> Nat:
  GR{ox, oy, oz, h, nx, ny, nz} = g
  nz

def gr_h(+g: GR) -> F64:
  GR{ox, oy, oz, h, nx, ny, nz} = g
  h

def gd_of(+gr: GR, +sa: List<&2, Bool>, +sb: List<&2, Bool>) -> GD:
  +na = Nat.mul(gr_nx(gr), Nat.mul(gr_ny(gr), gr_nz(gr)))
  +nb = Nat.mul(Nat.sub(gr_nx(gr), 1n), Nat.mul(Nat.sub(gr_ny(gr), 1n), Nat.sub(gr_nz(gr), 1n)))
  GD{gr, na, nb, B.tb_of(Bool, List.append(&2, Bool, sa, sb), False{})}

def gd_gr(+g: GD) -> GR:
  GD{gr, na, nb, sg} = g
  gr

def gd_na(+g: GD) -> Nat:
  GD{gr, na, nb, sg} = g
  na

def gd_in(+g: GD, +v: Nat) -> Bool:
  GD{gr, na, nb, +sg} = g
  B.tb_get(Bool, sg, U32.from_nat(v))

def ida(+g: GR, +i: Nat, +j: Nat, +k: Nat) -> Nat:
  Nat.add(i, Nat.mul(gr_nx(g), Nat.add(j, Nat.mul(gr_ny(g), k))))

def idb(+gd: GD, +i: Nat, +j: Nat, +k: Nat) -> Nat:
  +g = gd_gr(gd)
  Nat.add(gd_na(gd), Nat.add(i, Nat.mul(Nat.sub(gr_nx(g), 1n), Nat.add(j, Nat.mul(Nat.sub(gr_ny(g), 1n), k)))))

def vpos_g(+g: GR, +na: Nat, +v: Nat) -> V.Point:
  GR{+ox, +oy, +oz, +h, +nx, +ny, +nz} = g
  +isb = Nat.is_le(na, v)
  +w = Bool.pick(Nat, isb, Nat.sub(v, na), v)
  +mx = Bool.pick(Nat, isb, Nat.sub(nx, 1n), nx)
  +my = Bool.pick(Nat, isb, Nat.sub(ny, 1n), ny)
  +off = Bool.pick(F64, isb, F64.mul(0.5f64, h), 0.0f64)
  +i = Nat.mod(w, mx)
  +j = Nat.mod(Nat.div(w, mx), my)
  +k = Nat.div(w, Nat.mul(mx, my))
  V.Pt{F64.add(F64.add(ox, off), F64.mul(h, nat_f(i))), F64.add(F64.add(oy, off), F64.mul(h, nat_f(j))), F64.add(F64.add(oz, off), F64.mul(h, nat_f(k)))}

def vpos(+gd: GD, +v: Nat) -> V.Point:
  vpos_g(gd_gr(gd), gd_na(gd), v)

type EG is Data:
  EG{ a: Nat, b: Nat, red: Bool }

def eg_if(+gd: GD, +a: Nat, +b: Nat, +red: Bool, +acc: List<&2, EG>) -> List<&2, EG>:
  Bool.pick(List<&2, EG>, Bool.xor(gd_in(gd, a), gd_in(gd, b)), EG{a, b, red} <> acc, acc)

def a_edges(+gd: GD, +i: Nat, +j: Nat, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  +g = gd_gr(gd)
  +a = ida(g, i, j, k)
  +x = Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(i, 1n), gr_nx(g)), eg_if(gd, a, ida(g, Nat.add(i, 1n), j, k), False{}, acc), acc)
  +y = Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(j, 1n), gr_ny(g)), eg_if(gd, a, ida(g, i, Nat.add(j, 1n), k), False{}, x), x)
  Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(k, 1n), gr_nz(g)), eg_if(gd, a, ida(g, i, j, Nat.add(k, 1n)), False{}, y), y)

def b_reds(+gd: GD, +b: Nat, +i: Nat, +j: Nat, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  +g = gd_gr(gd)
  +i1 = Nat.add(i, 1n)
  +j1 = Nat.add(j, 1n)
  +k1 = Nat.add(k, 1n)
  eg_if(gd, ida(g, i, j, k), b, True{}, eg_if(gd, ida(g, i1, j, k), b, True{}, eg_if(gd, ida(g, i, j1, k), b, True{},
    eg_if(gd, ida(g, i1, j1, k), b, True{}, eg_if(gd, ida(g, i, j, k1), b, True{}, eg_if(gd, ida(g, i1, j, k1), b, True{},
      eg_if(gd, ida(g, i, j1, k1), b, True{}, eg_if(gd, ida(g, i1, j1, k1), b, True{}, acc))))))))

def b_edges(+gd: GD, +i: Nat, +j: Nat, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  +g = gd_gr(gd)
  +b = idb(gd, i, j, k)
  +r = b_reds(gd, b, i, j, k, acc)
  +x = Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(i, 2n), gr_nx(g)), eg_if(gd, b, idb(gd, Nat.add(i, 1n), j, k), False{}, r), r)
  +y = Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(j, 2n), gr_ny(g)), eg_if(gd, b, idb(gd, i, Nat.add(j, 1n), k), False{}, x), x)
  Bool.pick(List<&2, EG>, Nat.is_lt(Nat.add(k, 2n), gr_nz(g)), eg_if(gd, b, idb(gd, i, j, Nat.add(k, 1n)), False{}, y), y)

def ab_edges(ab: Bool, +gd: GD, +i: Nat, +j: Nat, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  match ab:
    case True{}: a_edges(gd, i, j, k, acc)
    case False{}: b_edges(gd, i, j, k, acc)

def loop_i(n: Nat, +ab: Bool, +gd: GD, +j: Nat, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  match n:
    case 0n: acc
    case 1n+(+i): loop_i(i, ab, gd, j, k, ab_edges(ab, gd, i, j, k, acc))

def loop_j(n: Nat, +ni: Nat, +ab: Bool, +gd: GD, +k: Nat, +acc: List<&2, EG>) -> List<&2, EG>:
  match n:
    case 0n: acc
    case 1n+(+j): loop_j(j, ni, ab, gd, k, loop_i(ni, ab, gd, j, k, acc))

def loop_k(n: Nat, +ni: Nat, +nj: Nat, +ab: Bool, +gd: GD, +acc: List<&2, EG>) -> List<&2, EG>:
  match n:
    case 0n: acc
    case 1n+(+k): loop_k(k, ni, nj, ab, gd, loop_j(nj, ni, ab, gd, k, acc))

def cross_edges(+gd: GD) -> List<&2, EG>:
  +g = gd_gr(gd)
  loop_k(Nat.sub(gr_nz(g), 1n), Nat.sub(gr_nx(g), 1n), Nat.sub(gr_ny(g), 1n), False{}, gd,
    loop_k(gr_nz(g), gr_nx(g), gr_ny(g), True{}, gd, []))

type CT is Data:
  CT{ key: Nat, a: Nat, b: Nat, p: V.Point, f: F64, len: F64, red: Bool, ok: Bool }

def psub(+p: V.Point, +q: V.Point) -> V.Dir:
  V.Dr{F64.sub(V.pt_x(p), V.pt_x(q)), F64.sub(V.pt_y(p), V.pt_y(q)), F64.sub(V.pt_z(p), V.pt_z(q))}

def dlen(+d: V.Dir) -> F64:
  F64.sqrt(F64.add(F64.add(F64.mul(V.dr_x(d), V.dr_x(d)), F64.mul(V.dr_y(d), V.dr_y(d))), F64.mul(V.dr_z(d), V.dr_z(d))))

def dsc(+k: F64, +d: V.Dir) -> V.Dir:
  V.Dr{F64.mul(k, V.dr_x(d)), F64.mul(k, V.dr_y(d)), F64.mul(k, V.dr_z(d))}

def padd(+p: V.Point, +d: V.Dir) -> V.Point:
  V.Pt{F64.add(V.pt_x(p), V.dr_x(d)), F64.add(V.pt_y(p), V.dr_y(d)), F64.add(V.pt_z(p), V.dr_z(d))}

def hd0(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case +x <> t: x

def ekey(+nv: Nat, +a: Nat, +b: Nat) -> Nat:
  Nat.add(Nat.mul(nv, Nat.min(a, b)), Nat.max(a, b))

def cut_lx(+l: LX, +nv: Nat, +a: Nat, +b: Nat, +p: V.Point, +u: V.Dir, +len: F64, +red: Bool) -> CT:
  +ok = Bool.and(lx_ok(l), Bool.not(Nat.is_eq(List.length(&2, F64, lx_ts(l)), 0n)))
  +t = Bool.pick(F64, ok, hd0(lx_ts(l), F64.mul(0.5f64, len)), F64.mul(0.5f64, len))
  CT{ekey(nv, a, b), a, b, padd(p, dsc(t, u)), F64.div(t, len), len, red, ok}

def cut_of(+fs: List<&2, SO.Fd>, +gd: GD, +nv: Nat, e: EG) -> CT:
  EG{+a, +b, +red} = e
  +p = vpos(gd, a)
  +d = psub(vpos(gd, b), p)
  +len = dlen(d)
  +u = dsc(F64.div(1.0f64, len), d)
  cut_lx(seg_xs(fs, p, u, len), nv, a, b, p, u, len, red)

type CX is Data:
  CX{ fs: List<&2, SO.Fd>, gd: GD, nv: Nat }

def cut_cx(c: CX, e: EG) -> CT:
  CX{+fs, +gd, +nv} = c
  cut_of(fs, gd, nv, e)

def cuts_of(+es: List<&2, EG>, +fs: List<&2, SO.Fd>, +gd: GD, +nv: Nat) -> List<&2, CT>:
  B.pmap_g(~EG, ~CX, ~CT, ~cut_cx, 4, CX{fs, gd, nv}, es)

type SC is Data:
  SC{ v: Nat, d: F64, p: V.Point }

def alpha(+red: Bool) -> F64:
  Bool.pick(F64, red, 0.41189f64, 0.24999f64)

def cands(cs: List<&2, CT>, +acc: List<&2, SC>) -> List<&2, SC>:
  match cs:
    case []: acc
    case +c <> t:
      CT{k, +a, +b, +p, +f, +len, +red, ok} = c
      +al = alpha(red)
      +s1 = Bool.pick(List<&2, SC>, F64.is_lt(f, al), SC{a, F64.mul(f, len), p} <> acc, acc)
      cands(t, Bool.pick(List<&2, SC>, F64.is_lt(F64.sub(1.0f64, f), al), SC{b, F64.mul(F64.sub(1.0f64, f), len), p} <> s1, s1))

def sc_cmp2(+a: SC, +b: SC) -> B.Sgn:
  SC{+av, +ad, ap} = a
  SC{+bv, +bd, bp} = b
  Bool.pick(B.Sgn, Nat.is_lt(av, bv), B.Sn{}, Bool.pick(B.Sgn, Nat.is_lt(bv, av), B.Sp{}, fcmp2(ad, bd)))

def sc_cmp(a: SC, b: SC) -> B.Sgn:
  sc_cmp2(a, b)

def so_sc(s: B.So<&2, SC>) -> List<&2, SC>:
  B.So{ok, xs} = s
  xs

def sc_v(+s: SC) -> Nat:
  SC{v, d, p} = s
  v

def firsts(xs: List<&2, SC>, +prev: Nat, +first: Bool) -> List<&2, SC>:
  match xs:
    case []: []
    case +x <> t:
      +v = sc_v(x)
      +rest = firsts(t, v, False{})
      Bool.pick(List<&2, SC>, Bool.or(first, Bool.not(Nat.is_eq(v, prev))), x <> rest, rest)

def snaps(+cs: List<&2, CT>) -> List<&2, SC>:
  firsts(so_sc(B.msort(~SC, ~sc_cmp, cands(cs, []))), 0n, True{})

def lab_l(xs: List<&2, Bool>) -> List<&2, U32>:
  match xs:
    case []: []
    case +x <> t: Bool.pick(U32, x, 1, 0) <> lab_l(t)

def pos_l(n: Nat, +gd: GD, +acc: List<&2, V.Point>) -> List<&2, V.Point>:
  match n:
    case 0n: acc
    case 1n+(+m): pos_l(m, gd, vpos(gd, m) <> acc)

def sc_p(+s: SC) -> V.Point:
  SC{v, d, p} = s
  p

def snap_lab(ss: List<&2, SC>, +t: B.Tb<&2, U32>) -> B.Tb<&2, U32>:
  match ss:
    case []: t
    case +x <> r: snap_lab(r, B.tb_set(U32, t, U32.from_nat(sc_v(x)), 2))

def snap_pos(ss: List<&2, SC>, +t: B.Tb<&2, V.Point>) -> B.Tb<&2, V.Point>:
  match ss:
    case []: t
    case +x <> r: snap_pos(r, B.tb_set(V.Point, t, U32.from_nat(sc_v(x)), sc_p(x)))

def ct_a(+c: CT) -> Nat:
  CT{k, a, b, p, f, len, red, ok} = c
  a

def ct_b(+c: CT) -> Nat:
  CT{k, a, b, p, f, len, red, ok} = c
  b

def ct_p(+c: CT) -> V.Point:
  CT{k, a, b, p, f, len, red, ok} = c
  p

def ct_ok(+c: CT) -> Bool:
  CT{k, a, b, p, f, len, red, ok} = c
  ok

def cts_ok(cs: List<&2, CT>) -> Bool:
  match cs:
    case []: True{}
    case +c <> t: Bool.and(ct_ok(c), cts_ok(t))

def lab(+lt: B.Tb<&2, U32>, +v: Nat) -> U32:
  B.tb_get(U32, lt, U32.from_nat(v))

def live(cs: List<&2, CT>, +lt: B.Tb<&2, U32>) -> List<&2, CT>:
  match cs:
    case []: []
    case +c <> t:
      +rest = live(t, lt)
      Bool.pick(List<&2, CT>, Bool.or(U32.is_eq(lab(lt, ct_a(c)), 2), U32.is_eq(lab(lt, ct_b(c)), 2)), rest, c <> rest)

def slot(+gd: GD, +a: Nat, +b: Nat) -> Nat:
  +lo = Nat.min(a, b)
  +hi = Nat.max(a, b)
  +na = gd_na(gd)
  +g = gd_gr(gd)
  +nx = gr_nx(g)
  +ny = gr_ny(g)
  +isb = Nat.is_le(na, lo)
  +red = Bool.and(Nat.is_lt(lo, na), Nat.is_le(na, hi))
  +w = Nat.sub(hi, na)
  +mx = Nat.sub(nx, 1n)
  +my = Nat.sub(ny, 1n)
  +ci = Nat.sub(Nat.mod(lo, nx), Nat.mod(w, mx))
  +cj = Nat.sub(Nat.mod(Nat.div(lo, nx), ny), Nat.mod(Nat.div(w, mx), my))
  +ck = Nat.sub(Nat.div(lo, Nat.mul(nx, ny)), Nat.div(w, Nat.mul(mx, my)))
  +c = Nat.add(ci, Nat.add(Nat.mul(2n, cj), Nat.mul(4n, ck)))
  +d = Nat.sub(hi, lo)
  +ry = Bool.pick(Nat, isb, mx, nx)
  +ax = Bool.pick(Nat, Nat.is_eq(d, 1n), 0n, Bool.pick(Nat, Nat.is_eq(d, ry), 1n, 2n))
  Bool.pick(Nat, red, Nat.add(Nat.mul(11n, hi), Nat.add(3n, c)), Nat.add(Nat.mul(11n, lo), ax))

def cut_tb(cs: List<&2, CT>, +gd: GD, +id: Nat, +t: B.Tb<&2, U32>) -> B.Tb<&2, U32>:
  match cs:
    case []: t
    case +c <> r: cut_tb(r, gd, Nat.add(id, 1n), B.tb_set(U32, t, U32.from_nat(slot(gd, ct_a(c), ct_b(c))), U32.from_nat(id)))

def ct_ps(cs: List<&2, CT>) -> List<&2, V.Point>:
  match cs:
    case []: []
    case +c <> t: ct_p(c) <> ct_ps(t)

type T4 is Data:
  T4{ a: Nat, b: Nat, c: Nat, d: Nat }

type MS is Data:
  MS{ gd: GD, lt: B.Tb<&2, U32>, ct: B.Tb<&2, U32>, pt: B.Tb<&2, V.Point>, fs: List<&2, SO.Fd>, span: F64 }

def ms_gd(+m: MS) -> GD:
  MS{gd, lt, ct, pt, fs, span} = m
  gd

def ms_lt(+m: MS) -> B.Tb<&2, U32>:
  MS{gd, lt, ct, pt, fs, span} = m
  lt

def ms_pt(+m: MS) -> B.Tb<&2, V.Point>:
  MS{gd, lt, ct, pt, fs, span} = m
  pt

def cn(+m: MS, +a: Nat, +b: Nat) -> Nat:
  MS{+gd, lt, +ct, pt, fs, span} = m
  U32.to_nat(B.tb_get(U32, ct, U32.from_nat(slot(gd, a, b))))

type P3 is Data:
  P3{ i: List<&2, Nat>, z: List<&2, Nat>, o: List<&2, Nat> }

def p3_add(+p: P3, +l: U32, +v: Nat) -> P3:
  P3{+i, +z, +o} = p
  Bool.pick(P3, U32.is_eq(l, 1), P3{v <> i, z, o}, Bool.pick(P3, U32.is_eq(l, 2), P3{i, v <> z, o}, P3{i, z, v <> o}))

def l0(xs: List<&2, Nat>, +d: Nat) -> Nat:
  match xs:
    case []: d
    case +x <> t: x

def l1(xs: List<&2, Nat>, +d: Nat) -> Nat:
  match xs:
    case []: d
    case +x <> t: l0(t, d)

def mn4(+a: Nat, +b: Nat, +c: Nat, +d: Nat) -> Nat:
  Nat.min(Nat.min(a, b), Nat.min(c, d))

def pyr(+q0: Nat, +q1: Nat, +q2: Nat, +q3: Nat, +p: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  +mn = mn4(q0, q1, q2, q3)
  Bool.pick(List<&2, T4>, Bool.or(Nat.is_eq(mn, q0), Nat.is_eq(mn, q2)), T4{q0, q1, q2, p} <> T4{q0, q2, q3, p} <> acc,
    T4{q1, q2, q3, p} <> T4{q1, q3, q0, p} <> acc)

def pr_b(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  Bool.pick(List<&2, T4>, Nat.is_lt(Nat.min(b, f), Nat.min(c, e)), T4{a, b, c, f} <> T4{a, b, f, e} <> T4{a, e, f, d} <> acc,
    T4{a, b, c, e} <> T4{a, e, c, f} <> T4{a, e, f, d} <> acc)

def pr_a(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  Bool.pick(List<&2, T4>, Nat.is_lt(d, a), pr_b(d, e, f, a, b, c, acc), pr_b(a, b, c, d, e, f, acc))

def prism(+a: Nat, +b: Nat, +c: Nat, +d: Nat, +e: Nat, +f: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  +mn = Nat.min(Nat.min(Nat.min(a, b), Nat.min(c, d)), Nat.min(e, f))
  Bool.pick(List<&2, T4>, Bool.or(Nat.is_eq(mn, a), Nat.is_eq(mn, d)), pr_a(a, b, c, d, e, f, acc),
    Bool.pick(List<&2, T4>, Bool.or(Nat.is_eq(mn, b), Nat.is_eq(mn, e)), pr_a(b, c, a, e, f, d, acc), pr_a(c, a, b, f, d, e, acc)))

def ctr(+m: MS, +t: T4) -> V.Point:
  T4{+a, +b, +c, +d} = t
  +pt = ms_pt(m)
  +pa = B.tb_get(V.Point, pt, U32.from_nat(a))
  +pb = B.tb_get(V.Point, pt, U32.from_nat(b))
  +pc = B.tb_get(V.Point, pt, U32.from_nat(c))
  +pd = B.tb_get(V.Point, pt, U32.from_nat(d))
  V.Pt{F64.mul(0.25f64, F64.add(F64.add(V.pt_x(pa), V.pt_x(pb)), F64.add(V.pt_x(pc), V.pt_x(pd)))),
    F64.mul(0.25f64, F64.add(F64.add(V.pt_y(pa), V.pt_y(pb)), F64.add(V.pt_y(pc), V.pt_y(pd)))),
    F64.mul(0.25f64, F64.add(F64.add(V.pt_z(pa), V.pt_z(pb)), F64.add(V.pt_z(pc), V.pt_z(pd))))}

def odd_n(+n: Nat) -> Bool:
  Nat.is_eq(Nat.mod(n, 2n), 1n)

def inside_pt(+m: MS, +p: V.Point) -> Bool:
  MS{gd, lt, ct, pt, +fs, +span} = m
  odd_n(List.length(&2, F64, lx_ts(seg_xs(fs, p, xdir(), span))))

def all_z(c: Bool, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match c:
    case True{}: Bool.pick(List<&2, T4>, inside_pt(m, ctr(m, tt)), tt <> acc, acc)
    case False{}: acc

def st_none(zs: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  all_z(Nat.is_eq(List.length(&2, Nat, zs), 4n), m, tt, acc)

def one_3(r2: List<&2, Nat>, +m1: Nat, +o1: Nat, +o2: Nat, +zs: List<&2, Nat>, +m: MS, +acc: List<&2, T4>) -> List<&2, T4>:
  match r2:
    case []: T4{m1, l0(zs, m1), cn(m, m1, o1), cn(m, m1, o2)} <> acc
    case +o3 <> r3: T4{m1, cn(m, m1, o1), cn(m, m1, o2), cn(m, m1, o3)} <> acc

def one_2(r: List<&2, Nat>, +m1: Nat, +o1: Nat, +zs: List<&2, Nat>, +m: MS, +acc: List<&2, T4>) -> List<&2, T4>:
  match r:
    case []: T4{m1, l0(zs, m1), l1(zs, m1), cn(m, m1, o1)} <> acc
    case +o2 <> r2: one_3(r2, m1, o1, o2, zs, m, acc)

def one_in(os: List<&2, Nat>, +m1: Nat, +zs: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match os:
    case []: tt <> acc
    case +o1 <> r: one_2(r, m1, o1, zs, m, acc)

def two_2(r: List<&2, Nat>, +m1: Nat, +m2: Nat, +o1: Nat, +zs: List<&2, Nat>, +m: MS, +acc: List<&2, T4>) -> List<&2, T4>:
  match r:
    case []: pyr(m1, m2, cn(m, m2, o1), cn(m, m1, o1), l0(zs, m1), acc)
    case +o2 <> r2: prism(m1, cn(m, m1, o1), cn(m, m1, o2), m2, cn(m, m2, o1), cn(m, m2, o2), acc)

def two_in(os: List<&2, Nat>, +m1: Nat, +m2: Nat, +zs: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match os:
    case []: tt <> acc
    case +o1 <> r: two_2(r, m1, m2, o1, zs, m, acc)

def three_in(os: List<&2, Nat>, +m1: Nat, +m2: Nat, +m3: Nat, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match os:
    case []: tt <> acc
    case +o <> r: prism(m1, m2, m3, cn(m, m1, o), cn(m, m2, o), cn(m, m3, o), acc)

def st_3(t3: List<&2, Nat>, +m1: Nat, +m2: Nat, +m3: Nat, +os: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match t3:
    case []: three_in(os, m1, m2, m3, m, tt, acc)
    case +m4 <> r: tt <> acc

def st_2(t2: List<&2, Nat>, +m1: Nat, +m2: Nat, +zs: List<&2, Nat>, +os: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match t2:
    case []: two_in(os, m1, m2, zs, m, tt, acc)
    case +m3 <> r: st_3(r, m1, m2, m3, os, m, tt, acc)

def st_1(t1: List<&2, Nat>, +m1: Nat, +zs: List<&2, Nat>, +os: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match t1:
    case []: one_in(os, m1, zs, m, tt, acc)
    case +m2 <> r: st_2(r, m1, m2, zs, os, m, tt, acc)

def st_i(ins: List<&2, Nat>, +zs: List<&2, Nat>, +os: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match ins:
    case []: st_none(zs, m, tt, acc)
    case +m1 <> r: st_1(r, m1, zs, os, m, tt, acc)

def st_go(c: Bool, +i: List<&2, Nat>, +z: List<&2, Nat>, +o: List<&2, Nat>, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  match c:
    case True{}: acc
    case False{}: st_i(i, z, o, m, tt, acc)

def st_p3(+p: P3, +m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  P3{+i, +z, +o} = p
  st_go(Nat.is_eq(List.length(&2, Nat, o), 4n), i, z, o, m, tt, acc)

def stencil(+m: MS, +tt: T4, +acc: List<&2, T4>) -> List<&2, T4>:
  T4{+a, +b, +c, +d} = tt
  +lt = ms_lt(m)
  st_p3(p3_add(p3_add(p3_add(p3_add(P3{[], [], []}, lab(lt, d), d), lab(lt, c), c), lab(lt, b), b), lab(lt, a), a), m, tt, acc)

def quad4(+m: MS, +a0: Nat, +a1: Nat, +b0: Nat, +b1: Nat, +b2: Nat, +b3: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  stencil(m, T4{a0, a1, b0, b1}, stencil(m, T4{a0, a1, b1, b2}, stencil(m, T4{a0, a1, b2, b3}, stencil(m, T4{a0, a1, b3, b0}, acc))))

def tets_if(c: Bool, +m: MS, +a0: Nat, +a1: Nat, +b0: Nat, +b1: Nat, +b2: Nat, +b3: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  match c:
    case True{}: quad4(m, a0, a1, b0, b1, b2, b3, acc)
    case False{}: acc

def in_rng(+i: Nat, +lo: Nat, +hi: Nat) -> Bool:
  Bool.and(Nat.is_le(lo, i), Nat.is_lt(i, hi))

def tets_at(+m: MS, +i: Nat, +j: Nat, +k: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  +gd = ms_gd(m)
  +g = gd_gr(gd)
  +nx = gr_nx(g)
  +ny = gr_ny(g)
  +nz = gr_nz(g)
  +a = ida(g, i, j, k)
  +i0 = Nat.sub(i, 1n)
  +j0 = Nat.sub(j, 1n)
  +k0 = Nat.sub(k, 1n)
  +ix = Bool.and(in_rng(i, 0n, Nat.sub(nx, 1n)), Bool.and(in_rng(j, 1n, Nat.sub(ny, 1n)), in_rng(k, 1n, Nat.sub(nz, 1n))))
  +iy = Bool.and(in_rng(i, 1n, Nat.sub(nx, 1n)), Bool.and(in_rng(j, 0n, Nat.sub(ny, 1n)), in_rng(k, 1n, Nat.sub(nz, 1n))))
  +iz = Bool.and(in_rng(i, 1n, Nat.sub(nx, 1n)), Bool.and(in_rng(j, 1n, Nat.sub(ny, 1n)), in_rng(k, 0n, Nat.sub(nz, 1n))))
  +x = tets_if(ix, m, a, ida(g, Nat.add(i, 1n), j, k), idb(gd, i, j0, k0), idb(gd, i, j, k0), idb(gd, i, j, k), idb(gd, i, j0, k), acc)
  +y = tets_if(iy, m, a, ida(g, i, Nat.add(j, 1n), k), idb(gd, i0, j, k0), idb(gd, i, j, k0), idb(gd, i, j, k), idb(gd, i0, j, k), x)
  tets_if(iz, m, a, ida(g, i, j, Nat.add(k, 1n)), idb(gd, i0, j0, k), idb(gd, i, j0, k), idb(gd, i, j, k), idb(gd, i0, j, k), y)

def tl_i(n: Nat, +m: MS, +j: Nat, +k: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  match n:
    case 0n: acc
    case 1n+(+i): tl_i(i, m, j, k, tets_at(m, i, j, k, acc))

def tl_j(n: Nat, +ni: Nat, +m: MS, +k: Nat, +acc: List<&2, T4>) -> List<&2, T4>:
  match n:
    case 0n: acc
    case 1n+(+j): tl_j(j, ni, m, k, tl_i(ni, m, j, k, acc))

def tk_go(+m: MS, +k: Nat) -> List<&2, T4>:
  +g = gd_gr(ms_gd(m))
  tl_j(gr_ny(g), gr_nx(g), m, k, [])

def tk_f(m: MS, k: Nat) -> List<&2, T4>:
  tk_go(m, k)

def t4_cat(xs: List<&2, List<&2, T4>>) -> List<&2, T4>:
  match xs:
    case []: []
    case +x <> t: List.append(&2, T4, x, t4_cat(t))

def ks(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n+(+m): ks(m, m <> acc)

def tets(+m: MS) -> List<&2, T4>:
  +g = gd_gr(ms_gd(m))
  t4_cat(B.pmap_g(~Nat, ~MS, ~List<&2, T4>, ~tk_f, 1, m, ks(gr_nz(g), [])))

def det3(+u: V.Dir, +v: V.Dir, +w: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(u), F64.sub(F64.mul(V.dr_y(v), V.dr_z(w)), F64.mul(V.dr_z(v), V.dr_y(w)))),
    F64.mul(V.dr_y(u), F64.sub(F64.mul(V.dr_z(v), V.dr_x(w)), F64.mul(V.dr_x(v), V.dr_z(w))))),
    F64.mul(V.dr_z(u), F64.sub(F64.mul(V.dr_x(v), V.dr_y(w)), F64.mul(V.dr_y(v), V.dr_x(w)))))

def tvol(+pt: B.Tb<&2, V.Point>, +t: T4) -> F64:
  T4{+a, +b, +c, +d} = t
  +pa = B.tb_get(V.Point, pt, U32.from_nat(a))
  F64.div(F64.abs(det3(psub(B.tb_get(V.Point, pt, U32.from_nat(b)), pa), psub(B.tb_get(V.Point, pt, U32.from_nat(c)), pa),
    psub(B.tb_get(V.Point, pt, U32.from_nat(d)), pa))), 6.0f64)

def vol_sum(ts: List<&2, T4>, +pt: B.Tb<&2, V.Point>, +acc: F64) -> F64:
  match ts:
    case []: acc
    case +t <> r: vol_sum(r, pt, F64.add(acc, tvol(pt, t)))

type MR is Data:
  MR{ ok: Bool, nv: Nat, ncut: Nat, nsnap: Nat, ts: List<&2, T4>, pt: B.Tb<&2, V.Point> }

def mk_ms(+gd: GD, +lt: B.Tb<&2, U32>, +ct: B.Tb<&2, U32>, +pt: B.Tb<&2, V.Point>, +fs: List<&2, SO.Fd>, +span: F64) -> MS:
  MS{gd, lt, ct, pt, fs, span}

def mk_mr(+ok: Bool, +nv: Nat, +nc: Nat, +ns: Nat, +ts: List<&2, T4>, +pt: B.Tb<&2, V.Point>) -> MR:
  MR{ok, nv, nc, ns, ts, pt}

def origin() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def mesh_gd(+gd: GD, +sa: List<&2, Bool>, +sb: List<&2, Bool>, +fs: List<&2, SO.Fd>, +span: F64) -> MR:
  +nv = Nat.add(List.length(&2, Bool, sa), List.length(&2, Bool, sb))
  +cs = cuts_of(cross_edges(gd), fs, gd, nv)
  +ss = snaps(cs)
  +lt = snap_lab(ss, B.tb_of(U32, List.append(&2, U32, lab_l(sa), lab_l(sb)), 0))
  +lc = live(cs, lt)
  +p0 = B.tb_list(V.Point, snap_pos(ss, B.tb_of(V.Point, pos_l(nv, gd, []), origin())))
  +pt = B.tb_of(V.Point, List.append(&2, V.Point, B.take_u(V.Point, p0, U32.from_nat(nv), False{}), ct_ps(lc)), origin())
  +ct = cut_tb(lc, gd, nv, B.tb_of(U32, B.rep_n(U32, Nat.mul(11n, nv), 0), 0))
  +m = mk_ms(gd, lt, ct, pt, fs, span)
  mk_mr(cts_ok(cs), nv, List.length(&2, CT, lc), List.length(&2, SC, ss), tets(m), pt)

type FK is Data:
  FK{ a: Nat, b: Nat, c: Nat }

def key3(+a: Nat, +b: Nat, +c: Nat) -> FK:
  +lo = Nat.min(a, Nat.min(b, c))
  +hi = Nat.max(a, Nat.max(b, c))
  FK{lo, Nat.sub(Nat.add(a, Nat.add(b, c)), Nat.add(lo, hi)), hi}

def fkeys(ts: List<&2, T4>, +acc: List<&2, FK>) -> List<&2, FK>:
  match ts:
    case []: acc
    case +t <> r:
      T4{+a, +b, +c, +d} = t
      fkeys(r, key3(a, b, c) <> key3(a, b, d) <> key3(a, c, d) <> key3(b, c, d) <> acc)

def ncmp2(+a: Nat, +b: Nat) -> B.Sgn:
  Bool.pick(B.Sgn, Nat.is_lt(a, b), B.Sn{}, Bool.pick(B.Sgn, Nat.is_lt(b, a), B.Sp{}, B.Sz{}))

def lex(+s: B.Sgn, +t: B.Sgn) -> B.Sgn:
  Bool.pick(B.Sgn, B.sgn_is(s, B.Sz{}), t, s)

def fk_cmp2(+x: FK, +y: FK) -> B.Sgn:
  FK{+a, +b, +c} = x
  FK{+d, +e, +f} = y
  lex(ncmp2(a, d), lex(ncmp2(b, e), ncmp2(c, f)))

def fk_cmp(x: FK, y: FK) -> B.Sgn:
  fk_cmp2(x, y)

def fk_eq(+x: FK, +y: FK) -> Bool:
  B.sgn_is(fk_cmp2(x, y), B.Sz{})

def so_fk(s: B.So<&2, FK>) -> List<&2, FK>:
  B.So{ok, xs} = s
  xs

type FC is Data:
  FC{ n1: Nat, n2: Nat, bad: Nat, bk: List<&2, FK> }

def fc_run(+f: FC, +k: FK, +c: Nat) -> FC:
  FC{+n1, +n2, +bad, +bk} = f
  Bool.pick(FC, Nat.is_eq(c, 1n), FC{Nat.add(n1, 1n), n2, bad, k <> bk},
    Bool.pick(FC, Nat.is_eq(c, 2n), FC{n1, Nat.add(n2, 1n), bad, bk}, FC{n1, n2, Nat.add(bad, 1n), bk}))

def runs(xs: List<&2, FK>, +k: FK, +c: Nat, +f: FC) -> FC:
  match xs:
    case []: Bool.pick(FC, Nat.is_eq(c, 0n), f, fc_run(f, k, c))
    case +x <> t:
      +same = fk_eq(x, k)
      runs(t, x, Bool.pick(Nat, same, Nat.add(c, 1n), 1n), Bool.pick(FC, Bool.or(same, Nat.is_eq(c, 0n)), f, fc_run(f, k, c)))

def faces(+ts: List<&2, T4>) -> FC:
  runs(so_fk(B.msort(~FK, ~fk_cmp, fkeys(ts, []))), FK{0n, 0n, 0n}, 0n, FC{0n, 0n, 0n, []})

def cross(+u: V.Dir, +v: V.Dir) -> V.Dir:
  V.Dr{F64.sub(F64.mul(V.dr_y(u), V.dr_z(v)), F64.mul(V.dr_z(u), V.dr_y(v))), F64.sub(F64.mul(V.dr_z(u), V.dr_x(v)), F64.mul(V.dr_x(u), V.dr_z(v))),
    F64.sub(F64.mul(V.dr_x(u), V.dr_y(v)), F64.mul(V.dr_y(u), V.dr_x(v)))}

def ddot(+u: V.Dir, +v: V.Dir) -> F64:
  F64.add(F64.add(F64.mul(V.dr_x(u), V.dr_x(v)), F64.mul(V.dr_y(u), V.dr_y(v))), F64.mul(V.dr_z(u), V.dr_z(v)))

def onrm(+o: V.Point, +p: V.Point, +q: V.Point, +r: V.Point) -> V.Dir:
  +n = cross(psub(q, p), psub(r, p))
  dsc(Bool.pick(F64, F64.is_lt(ddot(n, psub(p, o)), 0.0f64), F64.neg(1.0f64), 1.0f64), n)

def dih(+n: V.Dir, +m: V.Dir) -> F64:
  F64.neg(F64.div(ddot(n, m), F64.mul(dlen(n), dlen(m))))

type QD is Data:
  QD{ lo: F64, hi: F64, ndeg: Nat }

def mn6(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64) -> F64:
  F64.min(F64.min(F64.min(a, b), F64.min(c, d)), F64.min(e, f))

def mx6(+a: F64, +b: F64, +c: F64, +d: F64, +e: F64, +f: F64) -> F64:
  F64.max(F64.max(F64.max(a, b), F64.max(c, d)), F64.max(e, f))

def qd_dih(+na: V.Dir, +nb: V.Dir, +nc: V.Dir, +nd: V.Dir) -> QD:
  +c1 = dih(na, nb)
  +c2 = dih(na, nc)
  +c3 = dih(na, nd)
  +c4 = dih(nb, nc)
  +c5 = dih(nb, nd)
  +c6 = dih(nc, nd)
  QD{mn6(c1, c2, c3, c4, c5, c6), mx6(c1, c2, c3, c4, c5, c6), 0n}

def tq(+pt: B.Tb<&2, V.Point>, +t: T4, +vmin: F64) -> QD:
  T4{+a, +b, +c, +d} = t
  +pa = B.tb_get(V.Point, pt, U32.from_nat(a))
  +pb = B.tb_get(V.Point, pt, U32.from_nat(b))
  +pc = B.tb_get(V.Point, pt, U32.from_nat(c))
  +pd = B.tb_get(V.Point, pt, U32.from_nat(d))
  +deg = F64.is_lt(F64.div(F64.abs(det3(psub(pb, pa), psub(pc, pa), psub(pd, pa))), 6.0f64), vmin)
  Bool.pick(QD, deg, QD{1.0f64, F64.neg(1.0f64), 1n}, qd_dih(onrm(pa, pb, pc, pd), onrm(pb, pa, pc, pd), onrm(pc, pa, pb, pd), onrm(pd, pa, pb, pc)))

def qd_join(+x: QD, +y: QD) -> QD:
  QD{+a, +b, +c} = x
  QD{+d, +e, +f} = y
  QD{F64.min(a, d), F64.max(b, e), Nat.add(c, f)}

def quality(ts: List<&2, T4>, +pt: B.Tb<&2, V.Point>, +vmin: F64, +q: QD) -> QD:
  match ts:
    case []: q
    case +t <> r: quality(r, pt, vmin, qd_join(q, tq(pt, t, vmin)))

def so_nat(s: B.So<&2, Nat>) -> List<&2, Nat>:
  B.So{ok, xs} = s
  xs

def ncmp(a: Nat, b: Nat) -> B.Sgn:
  ncmp2(a, b)

def tverts(ts: List<&2, T4>, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ts:
    case []: acc
    case +t <> r:
      T4{+a, +b, +c, +d} = t
      tverts(r, a <> b <> c <> d <> acc)

def uniq(xs: List<&2, Nat>, +prev: Nat, +first: Bool) -> List<&2, Nat>:
  match xs:
    case []: []
    case +x <> t:
      +rest = uniq(t, x, False{})
      Bool.pick(List<&2, Nat>, Bool.or(first, Bool.not(Nat.is_eq(x, prev))), x <> rest, rest)

def zeros(n: Nat, +tl: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n: tl
    case 1n+(+m): 0 <> zeros(m, tl)

def dense(us: List<&2, Nat>, +i: Nat, +k: Nat) -> List<&2, U32>:
  match us:
    case []: []
    case +u <> t: zeros(Nat.sub(u, i), U32.from_nat(k) <> dense(t, Nat.add(u, 1n), Nat.add(k, 1n)))

def rmap(+mp: B.Tb<&2, U32>, +v: Nat) -> Nat:
  U32.to_nat(B.tb_get(U32, mp, U32.from_nat(v)))

def remap(ts: List<&2, T4>, +mp: B.Tb<&2, U32>) -> List<&2, T4>:
  match ts:
    case []: []
    case +t <> r:
      T4{+a, +b, +c, +d} = t
      T4{rmap(mp, a), rmap(mp, b), rmap(mp, c), rmap(mp, d)} <> remap(r, mp)

def upts(us: List<&2, Nat>, +pt: B.Tb<&2, V.Point>) -> List<&2, V.Point>:
  match us:
    case []: []
    case +u <> t: B.tb_get(V.Point, pt, U32.from_nat(u)) <> upts(t, pt)

type CM is Data:
  CM{ ts: List<&2, T4>, ps: List<&2, V.Point>, n: Nat }

def compact(+ts: List<&2, T4>, +pt: B.Tb<&2, V.Point>, +nn: Nat) -> CM:
  +us = uniq(so_nat(B.msort(~Nat, ~ncmp, tverts(ts, []))), 0n, True{})
  +mp = B.tb_of(U32, List.append(&2, U32, dense(us, 0n, 0n), []), 0)
  CM{remap(ts, mp), upts(us, pt), List.length(&2, Nat, us)}

type ER is Data:
  ER{ lo: Nat, hi: Nat, t: Nat, s: Nat }

def er(+a: Nat, +b: Nat, +t: Nat, +s: Nat) -> ER:
  ER{Nat.min(a, b), Nat.max(a, b), t, s}

def t_ers(ts: List<&2, T4>, +i: Nat, +acc: List<&2, ER>) -> List<&2, ER>:
  match ts:
    case []: acc
    case +t <> r:
      T4{+a, +b, +c, +d} = t
      t_ers(r, Nat.add(i, 1n), er(a, b, i, 0n) <> er(b, c, i, 1n) <> er(a, c, i, 2n) <> er(a, d, i, 3n) <> er(b, d, i, 4n) <> er(c, d, i, 5n) <> acc)

def er_cmp2(+x: ER, +y: ER) -> B.Sgn:
  ER{+a, +b, +c, +d} = x
  ER{+e, +f, +g, +h} = y
  lex(ncmp2(a, e), lex(ncmp2(b, f), lex(ncmp2(c, g), ncmp2(d, h))))

def er_cmp(x: ER, y: ER) -> B.Sgn:
  er_cmp2(x, y)

def ts_cmp2(+x: ER, +y: ER) -> B.Sgn:
  ER{+a, +b, +c, +d} = x
  ER{+e, +f, +g, +h} = y
  lex(ncmp2(c, g), ncmp2(d, h))

def ts_cmp(x: ER, y: ER) -> B.Sgn:
  ts_cmp2(x, y)

def so_er(s: B.So<&2, ER>) -> List<&2, ER>:
  B.So{ok, xs} = s
  xs

type EK is Data:
  EK{ lo: Nat, hi: Nat, op: Nat }

type EA is Data:
  EA{ es: List<&2, EK>, rs: List<&2, ER> }

def ea_put(+a: EA, +x: ER, +nw: Bool, +id: Nat) -> EA:
  EA{+es, +rs} = a
  ER{+lo, +hi, +t, +s} = x
  EA{Bool.pick(List<&2, EK>, nw, EK{lo, hi, 0n} <> es, es), ER{id, 0n, t, s} <> rs}

def er_same(+x: ER, +lo: Nat, +hi: Nat) -> Bool:
  ER{+a, +b, t, s} = x
  Bool.and(Nat.is_eq(a, lo), Nat.is_eq(b, hi))

def er_lo(+x: ER) -> Nat:
  ER{a, b, t, s} = x
  a

def er_hi(+x: ER) -> Nat:
  ER{a, b, t, s} = x
  b

def assign(xs: List<&2, ER>, +lo: Nat, +hi: Nat, +id: Nat, +first: Bool, +acc: EA) -> EA:
  match xs:
    case []: acc
    case +x <> t:
      +nw = Bool.or(first, Bool.not(er_same(x, lo, hi)))
      +nid = Bool.pick(Nat, Bool.and(nw, Bool.not(first)), Nat.add(id, 1n), id)
      assign(t, er_lo(x), er_hi(x), nid, False{}, ea_put(acc, x, nw, nid))

type T10 is Data:
  T10{ a: Nat, b: Nat, c: Nat, d: Nat, e0: Nat, e1: Nat, e2: Nat, e3: Nat, e4: Nat, e5: Nat }

def er_id(+x: ER, +base: Nat) -> Nat:
  ER{a, b, t, s} = x
  Nat.add(a, base)

def er1(rs: List<&2, ER>, +base: Nat, +t: T4, +e0: Nat, +e1: Nat, +e2: Nat, +e3: Nat, +e4: Nat) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r <> tl:
      T4{+a, +b, +c, +d} = t
      T10{a, b, c, d, e0, e1, e2, e3, e4, er_id(r, base)}

def er2(rs: List<&2, ER>, +base: Nat, +t: T4, +e0: Nat, +e1: Nat, +e2: Nat, +e3: Nat) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r <> tl: er1(tl, base, t, e0, e1, e2, e3, er_id(r, base))

def er3(rs: List<&2, ER>, +base: Nat, +t: T4, +e0: Nat, +e1: Nat, +e2: Nat) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r <> tl: er2(tl, base, t, e0, e1, e2, er_id(r, base))

def er4(rs: List<&2, ER>, +base: Nat, +t: T4, +e0: Nat, +e1: Nat) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r <> tl: er3(tl, base, t, e0, e1, er_id(r, base))

def er5(rs: List<&2, ER>, +base: Nat, +t: T4, +e0: Nat) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r <> tl: er4(tl, base, t, e0, er_id(r, base))

def er6(rs: List<&2, ER>, +base: Nat, +t: T4) -> T10:
  match rs:
    case []: T10{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}
    case +r0 <> t0: er5(t0, base, t, er_id(r0, base))

def drop6(xs: List<&2, ER>) -> List<&2, ER>:
  B.drop_u(ER, xs, 6, False{})

def build10(ts: List<&2, T4>, +rs: List<&2, ER>, +base: Nat) -> List<&2, T10>:
  match ts:
    case []: []
    case +t <> r: er6(rs, base, t) <> build10(r, drop6(rs), base)

def bedges(ks: List<&2, FK>, +acc: List<&2, EK>) -> List<&2, EK>:
  match ks:
    case []: acc
    case +k <> t:
      FK{+a, +b, +c} = k
      bedges(t, EK{a, b, c} <> EK{a, c, b} <> EK{b, c, a} <> acc)


type MJ is Data:
  MJ{ lo: Nat, hi: Nat, op: Nat, bd: Bool }

type JR is Data:
  JR{ lo: Nat, hi: Nat, op: Nat, tg: Nat }

def jr_e(xs: List<&2, EK>, +acc: List<&2, JR>) -> List<&2, JR>:
  match xs:
    case []: acc
    case +x <> t:
      EK{+a, +b, c} = x
      jr_e(t, JR{a, b, 0n, 0n} <> acc)

def jr_b(xs: List<&2, EK>, +acc: List<&2, JR>) -> List<&2, JR>:
  match xs:
    case []: acc
    case +x <> t:
      EK{+a, +b, +c} = x
      jr_b(t, JR{a, b, c, 1n} <> acc)

def jr_cmp2(+x: JR, +y: JR) -> B.Sgn:
  JR{+a, +b, c, +d} = x
  JR{+e, +f, g, +h} = y
  lex(ncmp2(a, e), lex(ncmp2(b, f), ncmp2(d, h)))

def jr_cmp(x: JR, y: JR) -> B.Sgn:
  jr_cmp2(x, y)

def so_jr(s: B.So<&2, JR>) -> List<&2, JR>:
  B.So{ok, xs} = s
  xs

def jr_step(+x: JR, +p: MJ) -> MJ:
  JR{+lo, +hi, +op, +tg} = x
  MJ{+a, +b, +o, +bd} = p
  +same = Bool.and(Nat.is_eq(lo, a), Nat.is_eq(hi, b))
  Bool.pick(MJ, Nat.is_eq(tg, 0n), MJ{lo, hi, 0n, False{}}, Bool.pick(MJ, Bool.and(same, Bool.not(bd)), MJ{a, b, op, True{}}, MJ{a, b, o, bd}))

def jr_tg(+x: JR) -> Nat:
  JR{lo, hi, op, tg} = x
  tg

def jr_go(xs: List<&2, JR>, +p: MJ, +has: Bool) -> List<&2, MJ>:
  match xs:
    case []: Bool.pick(List<&2, MJ>, has, p <> [], [])
    case +x <> t:
      +isn = Nat.is_eq(jr_tg(x), 0n)
      +rest = jr_go(t, jr_step(x, p), Bool.or(has, isn))
      Bool.pick(List<&2, MJ>, Bool.and(isn, has), p <> rest, rest)

def mjoin(+es: List<&2, EK>, +bs: List<&2, EK>) -> List<&2, MJ>:
  jr_go(so_jr(B.msort(~JR, ~jr_cmp, jr_e(es, jr_b(bs, [])))), MJ{0n, 0n, 0n, False{}}, False{})

type PX is Data:
  PX{ fs: List<&2, SO.Fd>, pt: B.Tb<&2, V.Point> }

type MP is Data:
  MP{ p: V.Point, dev: F64, ok: Bool }

def nearest(ts: List<&2, F64>, +c: F64, +best: F64) -> F64:
  match ts:
    case []: best
    case +x <> t: nearest(t, c, Bool.pick(F64, F64.is_lt(F64.abs(F64.sub(x, c)), F64.abs(F64.sub(best, c))), x, best))

def mid_go(+fs: List<&2, SO.Fd>, +m: V.Point, +n: V.Dir, +len: F64) -> MP:
  +u = dsc(F64.div(1.0f64, dlen(n)), n)
  +s = padd(m, dsc(F64.neg(len), u))
  +l = seg_xs(fs, s, u, F64.mul(2.0f64, len))
  +ok = Bool.and(lx_ok(l), Bool.not(Nat.is_eq(List.length(&2, F64, lx_ts(l)), 0n)))
  +t = nearest(lx_ts(l), len, F64.mul(1.0e30f64, len))
  +q = padd(s, dsc(t, u))
  Bool.pick(MP, ok, MP{q, F64.abs(F64.sub(t, len)), True{}}, MP{m, 0.0f64, False{}})

def mid_bd(c: Bool, +fs: List<&2, SO.Fd>, +m: V.Point, +n: V.Dir, +len: F64) -> MP:
  match c:
    case True{}: mid_go(fs, m, n, len)
    case False{}: MP{m, 0.0f64, True{}}

def mid_f(c: PX, j: MJ) -> MP:
  PX{+fs, +pt} = c
  MJ{+lo, +hi, +op, +bd} = j
  +pa = B.tb_get(V.Point, pt, U32.from_nat(lo))
  +pb = B.tb_get(V.Point, pt, U32.from_nat(hi))
  +m = padd(pa, dsc(0.5f64, psub(pb, pa)))
  +n = cross(psub(pb, pa), psub(B.tb_get(V.Point, pt, U32.from_nat(op)), pa))
  mid_bd(bd, fs, m, n, dlen(psub(pb, pa)))

type TM is Data:
  TM{ ts: List<&2, T10>, ps: List<&2, V.Point>, nn: Nat, nb: Nat, nfail: Nat, dev: F64 }

def mp_p(+x: MP) -> V.Point:
  MP{p, d, ok} = x
  p

def mp_ps(xs: List<&2, MP>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case +x <> t: mp_p(x) <> mp_ps(t)

type MD is Data:
  MD{ nf: Nat, dev: F64 }

def mp_stat(xs: List<&2, MP>, +a: MD) -> MD:
  match xs:
    case []: a
    case +x <> t:
      MP{p, +d, +ok} = x
      MD{+nf, +dv} = a
      mp_stat(t, MD{Bool.pick(Nat, ok, nf, Nat.add(nf, 1n)), F64.max(dv, d)})

def mj_bd(xs: List<&2, MJ>, +n: Nat) -> Nat:
  match xs:
    case []: n
    case +x <> t:
      MJ{lo, hi, op, +bd} = x
      mj_bd(t, Bool.pick(Nat, bd, Nat.add(n, 1n), n))

def mk_tm(+ts: List<&2, T10>, +ps: List<&2, V.Point>, +nn: Nat, +nb: Nat, +md: MD) -> TM:
  MD{+nf, +dv} = md
  TM{ts, ps, nn, nb, nf, dv}

def ea_es(+a: EA) -> List<&2, EK>:
  EA{es, rs} = a
  es

def ea_rs(+a: EA) -> List<&2, ER>:
  EA{es, rs} = a
  rs

def fc_bk(+f: FC) -> List<&2, FK>:
  FC{n1, n2, bad, bk} = f
  bk

def cm_ts(+c: CM) -> List<&2, T4>:
  CM{ts, ps, n} = c
  ts

def cm_ps(+c: CM) -> List<&2, V.Point>:
  CM{ts, ps, n} = c
  ps

def cm_n(+c: CM) -> Nat:
  CM{ts, ps, n} = c
  n

def t10_go(+ts: List<&2, T4>, +ps: List<&2, V.Point>, +n: Nat, +fs: List<&2, SO.Fd>) -> TM:
  +pt = B.tb_of(V.Point, ps, origin())
  +ea = assign(so_er(B.msort(~ER, ~er_cmp, t_ers(ts, 0n, []))), 0n, 0n, 0n, True{}, EA{[], []})
  +es = List.reverse(&2, EK, ea_es(ea))
  +rs = so_er(B.msort(~ER, ~ts_cmp, ea_rs(ea)))
  +bs = bedges(fc_bk(faces(ts)), [])
  +mj = mjoin(es, bs)
  +mps = B.pmap_g(~MJ, ~PX, ~MP, ~mid_f, 8, PX{fs, pt}, mj)
  mk_tm(build10(ts, rs, n), List.append(&2, V.Point, ps, mp_ps(mps)), Nat.add(n, List.length(&2, EK, es)), mj_bd(mj, 0n), mp_stat(mps, MD{0n, 0.0f64}))

def t10_of(+ts: List<&2, T4>, +pt: B.Tb<&2, V.Point>, +nn: Nat, +fs: List<&2, SO.Fd>) -> TM:
  +cm = compact(ts, pt, nn)
  t10_go(cm_ts(cm), cm_ps(cm), cm_n(cm), fs)

type P10 is Data:
  P10{ a: V.Point, b: V.Point, c: V.Point, d: V.Point, e0: V.Point, e1: V.Point, e2: V.Point, e3: V.Point, e4: V.Point, e5: V.Point }

def pg(+pt: B.Tb<&2, V.Point>, +i: Nat) -> V.Point:
  B.tb_get(V.Point, pt, U32.from_nat(i))

def p10(+pt: B.Tb<&2, V.Point>, +t: T10) -> P10:
  T10{+a, +b, +c, +d, +e0, +e1, +e2, +e3, +e4, +e5} = t
  P10{pg(pt, a), pg(pt, b), pg(pt, c), pg(pt, d), pg(pt, e0), pg(pt, e1), pg(pt, e2), pg(pt, e3), pg(pt, e4), pg(pt, e5)}

def pv(+p: V.Point) -> V.Dir:
  V.Dr{V.pt_x(p), V.pt_y(p), V.pt_z(p)}

def dadd(+u: V.Dir, +v: V.Dir) -> V.Dir:
  V.Dr{F64.add(V.dr_x(u), V.dr_x(v)), F64.add(V.dr_y(u), V.dr_y(v)), F64.add(V.dr_z(u), V.dr_z(v))}

def cw(+l: F64, +dl: F64) -> F64:
  F64.mul(F64.sub(F64.mul(4.0f64, l), 1.0f64), dl)

def ew(+li: F64, +lj: F64, +di: F64, +dj: F64) -> F64:
  F64.mul(4.0f64, F64.add(F64.mul(lj, di), F64.mul(li, dj)))

def jcol(+p: P10, +l1: F64, +l2: F64, +l3: F64, +l4: F64, +d1: F64, +d2: F64, +d3: F64, +d4: F64) -> V.Dir:
  P10{+a, +b, +c, +d, +e0, +e1, +e2, +e3, +e4, +e5} = p
  +k = dadd(dadd(dsc(cw(l1, d1), pv(a)), dsc(cw(l2, d2), pv(b))), dadd(dsc(cw(l3, d3), pv(c)), dsc(cw(l4, d4), pv(d))))
  +e = dadd(dadd(dsc(ew(l1, l2, d1, d2), pv(e0)), dsc(ew(l2, l3, d2, d3), pv(e1))), dadd(dsc(ew(l1, l3, d1, d3), pv(e2)), dsc(ew(l1, l4, d1, d4), pv(e3))))
  dadd(k, dadd(e, dadd(dsc(ew(l2, l4, d2, d4), pv(e4)), dsc(ew(l3, l4, d3, d4), pv(e5)))))

def detj(+p: P10, +l2: F64, +l3: F64, +l4: F64) -> F64:
  +l1 = F64.sub(1.0f64, F64.add(l2, F64.add(l3, l4)))
  +m = F64.neg(1.0f64)
  det3(jcol(p, l1, l2, l3, l4, m, 1.0f64, 0.0f64, 0.0f64), jcol(p, l1, l2, l3, l4, m, 0.0f64, 1.0f64, 0.0f64), jcol(p, l1, l2, l3, l4, m, 0.0f64, 0.0f64, 1.0f64))

type JV is Data:
  JV{ v: F64, jmin: F64, jmax: F64 }

def jv_one(+j1: F64, +j2: F64, +j3: F64, +j4: F64, +j5: F64) -> JV:
  +g = Bool.pick(F64, F64.is_lt(j1, 0.0f64), F64.neg(1.0f64), 1.0f64)
  +s = F64.mul(g, F64.add(F64.mul(F64.neg(0.13333333333333333f64), j1), F64.mul(0.075f64, F64.add(F64.add(j2, j3), F64.add(j4, j5)))))
  +r = F64.div(F64.min(F64.min(j2, j3), F64.min(j4, j5)), j1)
  +r2 = F64.div(F64.max(F64.max(j2, j3), F64.max(j4, j5)), j1)
  JV{s, F64.min(r, r2), F64.max(r, r2)}

def sixth() -> F64:
  0.16666666666666666f64

def t10_jv(+pt: B.Tb<&2, V.Point>, +t: T10) -> JV:
  +p = p10(pt, t)
  +q = sixth()
  jv_one(detj(p, 0.25f64, 0.25f64, 0.25f64), detj(p, q, q, q), detj(p, 0.5f64, q, q), detj(p, q, 0.5f64, q), detj(p, q, q, 0.5f64))

def jv_join(+x: JV, +y: JV) -> JV:
  JV{+a, +b, +c} = x
  JV{+d, +e, +f} = y
  JV{F64.add(a, d), F64.min(b, e), F64.max(c, f)}

def t10_vols(ts: List<&2, T10>, +pt: B.Tb<&2, V.Point>, +acc: JV) -> JV:
  match ts:
    case []: acc
    case +t <> r: t10_vols(r, pt, jv_join(acc, t10_jv(pt, t)))
