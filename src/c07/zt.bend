import Base
import ../base/par.bend as B
import ../c06/iv.bend as I
import ../c06/xp.bend as X
import ../c06/prof.bend as F
import ./ivx.bend as V
import ./sym.bend as Y
import ./zd.bend as D

type Zb is Data:
  Zb{ lo: X.Env, hi: X.Env }

type Pm is Data:
  Pl{ a: List<&2, I.I>, b: List<&2, I.I>, xa: X.Xp, xb: X.Xp }
  Pa{ c: List<&2, I.I>, r: I.I, a: List<&2, I.I>, b: List<&2, I.I>, ccw: Bool, th: I.I, xa: X.Xp, xb: X.Xp }
  Pc{ c: List<&2, I.I>, r: I.I, xc: X.Xp, xr: X.Xp }

type Sw is Data:
  Sw{ d: Nat, sp: I.I, sq: I.I }

type Lz is Data:
  Lz{ ps: List<&2, Pm>, ok: Bool }

type Pt is Data:
  Pt{ x: X.Xp, y: X.Xp }

type Ac is Data:
  Ac{ ps: List<&2, Pm>, ok: Bool, p: Pt }

type Ix is Data:
  Ix{ l: Nat, i: Nat, n: Nat, p: Pm, lo: F64 }

type Zd is Data:
  Zd{ ids: List<&2, U64>, vs: List<&2, I.I> }

type Dm is Data:
  Dm{ ar: D.Dv, ln: D.Dv, rv: D.Dv, ra: D.Dv }

def xi(x: X.Xp, +z: Zb) -> I.I:
  match x:
    case X.X_k{v}: I.ipt(v)
    case X.X_p{+id}:
      Zb{lo, hi} = z
      V.iof(X.env_get(lo, id), X.env_get(hi, id))
    case X.X_add{a, b}: I.iadd(xi(a, z), xi(b, z))
    case X.X_sub{a, b}: I.isub(xi(a, z), xi(b, z))
    case X.X_mul{a, b}: I.imul(xi(a, z), xi(b, z))
    case X.X_div{a, b}: I.idiv(xi(a, z), xi(b, z))
    case X.X_neg{a}: I.ineg(xi(a, z))

def p2(+x: X.Xp, +y: X.Xp, +z: Zb) -> List<&2, I.I>:
  [xi(x, z), xi(y, z)]

def cr2(+a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  I.isub(I.imul(V.vn(a, 0n), V.vn(b, 1n)), I.imul(V.vn(a, 1n), V.vn(b, 0n)))

def two_pi() -> I.I:
  I.iscale(I.pi_i(), 2.0f64)

def pos(+a: I.I) -> Bool:
  Bool.and(V.ifin(a), F64.is_lt(0.0f64, I.i_lo(a)))

def neg(+a: I.I) -> Bool:
  Bool.and(V.ifin(a), F64.is_lt(I.i_hi(a), 0.0f64))

def atan2p(+c: I.I, +d: I.I) -> I.I:
  Bool.pick(I.I, neg(d), I.isub(I.pi_i(), I.atan2q(c, I.ineg(d))), I.atan2q(c, d))

def ang_ccw(+c: I.I, +d: I.I) -> I.I:
  +ac = I.ihull(c, I.ineg(c))
  +m = V.iof(0.0f64, I.i_hi(ac))
  +t = atan2p(m, d)
  Bool.pick(I.I, pos(c), atan2p(c, d), Bool.pick(I.I, neg(c), I.isub(two_pi(), atan2p(I.ineg(c), d)), I.ihull(t, I.isub(two_pi(), t))))

def sang(+u0: List<&2, I.I>, +u: List<&2, I.I>) -> I.I:
  +c = cr2(u0, u)
  +d = V.vdot(u0, u)
  +m = atan2p(V.iof(0.0f64, V.imag(c)), d)
  Bool.pick(I.I, pos(c), atan2p(c, d), Bool.pick(I.I, neg(c), I.ineg(atan2p(I.ineg(c), d)), I.ihull(I.ineg(m), m)))

def mids(+v: List<&2, I.I>) -> List<&2, I.I>:
  [I.ipt(V.imid(V.vn(v, 0n))), I.ipt(V.imid(V.vn(v, 1n)))]

def sweep(+c: List<&2, I.I>, +a: List<&2, I.I>, +b: List<&2, I.I>, +ccw: Bool) -> I.I:
  +u = V.vsub(a, c)
  +v = V.vsub(b, c)
  +u0 = mids(u)
  +v0 = mids(v)
  +t0 = ang_ccw(cr2(u0, v0), V.vdot(u0, v0))
  +da = sang(u0, u)
  +db = sang(v0, v)
  Bool.pick(I.I, ccw, I.iadd(t0, I.isub(db, da)), I.iadd(I.isub(two_pi(), t0), I.isub(da, db)))

def d2(+a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  +d = V.vsub(b, a)
  V.vdot(d, d)

def sq_x(+a: X.Xp, +b: X.Xp) -> X.Xp:
  X.X_mul{X.X_sub{a, b}, X.X_sub{a, b}}

def circ_x(+px: X.Xp, +py: X.Xp, +cx: X.Xp, +cy: X.Xp, +r: X.Xp) -> X.Xp:
  X.X_sub{X.X_add{sq_x(px, cx), sq_x(py, cy)}, X.X_mul{r, r}}

def on_circ(+px: X.Xp, +py: X.Xp, +cx: X.Xp, +cy: X.Xp, +r: X.Xp) -> Bool:
  Y.is_zero(circ_x(px, py, cx, cy, r))

def in_02pi(+t: I.I) -> Bool:
  Bool.and(pos(t), F64.is_lt(I.i_hi(t), I.i_lo(two_pi())))

def pt_x(p: Pt) -> X.Xp:
  Pt{x, y} = p
  x

def pt_y(p: Pt) -> X.Xp:
  Pt{x, y} = p
  y

def seg_pm(s: F.Seg, +p: Pt, +z: Zb) -> Ac:
  match s:
    case F.S_line{+x, +y}:
      +px = pt_x(p)
      +a = p2(px, pt_y(p), z)
      +b = p2(x, y, z)
      Ac{[Pl{a, b, px, x}], pos(d2(a, b)), Pt{x, y}}
    case F.S_arc{+cx, +cy, +r, +x, +y, +ccw}:
      +px = pt_x(p)
      +py = pt_y(p)
      +a = p2(px, py, z)
      +b = p2(x, y, z)
      +c = p2(cx, cy, z)
      +ri = xi(r, z)
      +th = sweep(c, a, b, ccw)
      +ok = Bool.and(Bool.and(on_circ(px, py, cx, cy, r), on_circ(x, y, cx, cy, r)), Bool.and(pos(ri), Bool.and(pos(d2(a, b)), in_02pi(th))))
      Ac{[Pa{c, ri, a, b, ccw, th, px, x}], ok, Pt{x, y}}

def ac_join(r: Ac, +ps: List<&2, Pm>, +ok: Bool) -> Ac:
  Ac{ps1, ok1, p1} = r
  Ac{List.append(&2, Pm, ps, ps1), Bool.and(ok, ok1), p1}

def ac_add(acc: Ac, +s: F.Seg, +z: Zb) -> Ac:
  Ac{ps, ok, p} = acc
  ac_join(seg_pm(s, p, z), ps, ok)

def segs_go(ss: List<&2, F.Seg>, +acc: Ac, +z: Zb) -> Ac:
  match ss:
    case []: acc
    case s <> t: segs_go(t, ac_add(acc, s, z), z)

def close(r: Ac, +x0: X.Xp, +y0: X.Xp, +z: Zb) -> Lz:
  Ac{+ps, +ok, +p} = r
  +x = pt_x(p)
  +y = pt_y(p)
  +shut = Bool.and(Y.same(x, x0), Y.same(y, y0))
  +a = p2(x, y, z)
  +b = p2(x0, y0, z)
  Bool.pick(Lz, shut, Lz{ps, ok}, Lz{List.append(&2, Pm, ps, [Pl{a, b, x, x0}]), Bool.and(ok, pos(d2(a, b)))})

def loop_z(l: F.Loop, +z: Zb) -> Lz:
  match l:
    case F.L_path{+x, +y, segs}: close(segs_go(segs, Ac{[], True{}, Pt{x, y}}, z), x, y, z)
    case F.L_circ{+cx, +cy, +r}:
      +ri = xi(r, z)
      Lz{[Pc{p2(cx, cy, z), ri, cx, r}], pos(ri)}

def lz_ps(l: Lz) -> List<&2, Pm>:
  Lz{ps, ok} = l
  ps

def lz_ok(l: Lz) -> Bool:
  Lz{ps, ok} = l
  ok

def cossin(+f: I.I) -> List<&2, I.I>:
  +hp = I.half_pi()
  +q = F64.to_u64(F64.add(F64.div(F64.max(V.imid(f), 0.0f64), V.imid(hp)), 0.5f64))
  +t = I.isub(f, I.imul(I.ipt(U64.to_f64(q)), hp))
  +c = I.clamp1(I.iwiden(I.cos_small(t), 1.0e-20f64))
  +s = I.clamp1(I.iwiden(I.sin_small(t), 1.0e-20f64))
  Bool.pick(List<&2, I.I>, F64.is_lt(V.iwid(f), V.imid(hp)), I.quad(U64.mod(q, 4u64), c, s), [V.iof(F64.neg(1.0f64), 1.0f64), V.iof(F64.neg(1.0f64), 1.0f64)])

def rot(+u: List<&2, I.I>, +f: I.I, +ccw: Bool) -> List<&2, I.I>:
  +cs = cossin(f)
  +c = V.vn(cs, 0n)
  +s = Bool.pick(I.I, ccw, V.vn(cs, 1n), I.ineg(V.vn(cs, 1n)))
  +ux = V.vn(u, 0n)
  +uy = V.vn(u, 1n)
  [I.isub(I.imul(c, ux), I.imul(s, uy)), I.iadd(I.imul(s, ux), I.imul(c, uy))]

def tan_of(+r: List<&2, I.I>, +ccw: Bool) -> List<&2, I.I>:
  +x = V.vn(r, 0n)
  +y = V.vn(r, 1n)
  Bool.pick(List<&2, I.I>, ccw, [I.ineg(y), x], [y, I.ineg(x)])

def vsc(+s: I.I, xs: List<&2, I.I>) -> List<&2, I.I>:
  match xs:
    case []: []
    case x <> t: I.imul(s, x) <> vsc(s, t)

def pbox(p: Pm, +s: I.I) -> List<&2, I.I>:
  match p:
    case Pl{+a, +b, xa, xb}: V.vadd(a, vsc(s, V.vsub(b, a)))
    case Pa{+c, r, +a, b, +ccw, +th, xa, xb}: V.vadd(c, rot(V.vsub(a, c), I.imul(th, s), ccw))
    case Pc{+c, +r, xc, xr}: V.vadd(c, rot([r, I.ipt(0.0f64)], I.imul(two_pi(), s), True{}))

def pder(p: Pm, +s: I.I) -> List<&2, I.I>:
  match p:
    case Pl{+a, +b, xa, xb}: V.vsub(b, a)
    case Pa{+c, r, +a, b, +ccw, +th, xa, xb}: tan_of(rot(V.vsub(a, c), I.imul(th, s), ccw), ccw)
    case Pc{c, +r, xc, xr}: tan_of(rot([r, I.ipt(0.0f64)], I.imul(two_pi(), s), True{}), True{})

def half(+s: I.I, +left: Bool) -> I.I:
  +m = V.imid(s)
  Bool.pick(I.I, left, V.iof(I.i_lo(s), m), V.iof(m, I.i_hi(s)))

def sep_code(+bp: List<&2, I.I>, +bq: List<&2, I.I>) -> U64:
  Bool.pick(U64, Bool.and(Bool.and(V.vfin(bp), V.vfin(bq)), V.vdisj(bp, bq)), 0u64, Bool.pick(U64, F64.is_le(V.vwid(bq), V.vwid(bp)), 1u64, 2u64))

def sep_go(fuel: Nat, dead: Bool, ws: List<&2, Sw>, +p: Pm, +q: Pm) -> Bool:
  match fuel:
    case 0n: False{}
    case 1n+f:
      match dead:
        case True{}: False{}
        case False{}:
          match ws:
            case []: True{}
            case w <> +t:
              Sw{+d, +sp, +sq} = w
              +k = sep_code(pbox(p, sp), pbox(q, sq))
              +kids = Bool.pick(List<&2, Sw>, U64.is_eq(k, 1u64), [Sw{Nat.sub(d, 1n), half(sp, True{}), sq}, Sw{Nat.sub(d, 1n), half(sp, False{}), sq}],
                [Sw{Nat.sub(d, 1n), sp, half(sq, True{})}, Sw{Nat.sub(d, 1n), sp, half(sq, False{})}])
              sep_go(f, Bool.and(Bool.not(U64.is_eq(k, 0u64)), Nat.is_eq(d, 0n)), Bool.pick(List<&2, Sw>, U64.is_eq(k, 0u64), t, List.append(&2, Sw, kids, t)), p, q)

def sep_in(+p: Pm, +q: Pm, +sp: I.I, +sq: I.I) -> Bool:
  sep_go(4096n, False{}, [Sw{14n, sp, sq}], p, q)

def piece(+i: Nat, +dl: F64) -> I.I:
  Bool.pick(I.I, Nat.is_eq(i, 0n), V.iof(0.0f64, dl), Bool.pick(I.I, Nat.is_eq(i, 1n), V.iof(dl, F64.sub(1.0f64, dl)), V.iof(F64.sub(1.0f64, dl), 1.0f64)))

def cone(+p: Pm, +q: Pm, +pe: Bool, +qe: Bool, +dl: F64) -> Bool:
  +dp = vsc(Bool.pick(I.I, pe, I.ipt(F64.neg(1.0f64)), I.ipt(1.0f64)), pder(p, piece(Bool.pick(Nat, pe, 2n, 0n), dl)))
  +dq = vsc(Bool.pick(I.I, qe, I.ipt(F64.neg(1.0f64)), I.ipt(1.0f64)), pder(q, piece(Bool.pick(Nat, qe, 2n, 0n), dl)))
  +cs = I.idiv(V.vdot(dp, dq), I.imul(I.isqrt(V.vdot(dp, dp)), I.isqrt(V.vdot(dq, dq))))
  Bool.and(V.ifin(cs), F64.is_lt(I.i_hi(cs), 1.0f64))

def cut(+fwd: Bool, +bwd: Bool, +p: Pm, +q: Pm, +dl: F64, +i: Nat, +j: Nat) -> Bool:
  +f = Bool.and(Bool.and(fwd, Bool.and(Nat.is_eq(i, 2n), Nat.is_eq(j, 0n))), cone(p, q, True{}, False{}, dl))
  +b = Bool.and(Bool.and(bwd, Bool.and(Nat.is_eq(i, 0n), Nat.is_eq(j, 2n))), cone(p, q, False{}, True{}, dl))
  Bool.or(f, b)

def cells(n: Nat, +fwd: Bool, +bwd: Bool, +p: Pm, +q: Pm, +dl: F64) -> Bool:
  match n:
    case 0n: True{}
    case 1n+(+m):
      +i = Nat.div(m, 3n)
      +j = Nat.mod(m, 3n)
      Bool.and(Bool.or(cut(fwd, bwd, p, q, dl, i, j), sep_in(p, q, piece(i, dl), piece(j, dl))), cells(m, fwd, bwd, p, q, dl))

def adj_go(ds: List<&2, F64>, +ok: Bool, +fwd: Bool, +bwd: Bool, +p: Pm, +q: Pm) -> Bool:
  match ds:
    case []: ok
    case d <> t:
      match ok:
        case True{}: True{}
        case False{}: adj_go(t, cells(9n, fwd, bwd, p, q, d), fwd, bwd, p, q)

def adj_ok(+fwd: Bool, +bwd: Bool, +p: Pm, +q: Pm) -> Bool:
  adj_go([0.125f64, 0.015625f64, 0.001953125f64], False{}, fwd, bwd, p, q)

def pair_k(k: U64, +fwd: Bool, +bwd: Bool, +p: Pm, +q: Pm) -> Bool:
  match k:
    case 0u64: True{}
    case 1u64: adj_ok(fwd, bwd, p, q)
    case _: sep_in(p, q, V.iof(0.0f64, 1.0f64), V.iof(0.0f64, 1.0f64))

def pair_ok(x: Ix, y: Ix) -> Bool:
  Ix{+lx, +ix, +nx, +px, lo1} = x
  Ix{+ly, +iy, +ny, +py, lo2} = y
  +same = Nat.is_eq(lx, ly)
  +fwd = Bool.and(same, Nat.is_eq(Nat.mod(Nat.add(ix, 1n), nx), iy))
  +bwd = Bool.and(same, Nat.is_eq(Nat.mod(Nat.add(iy, 1n), ny), ix))
  +skip = Bool.and(Nat.is_lt(lx, 1000000n), Nat.is_lt(ly, 1000000n))
  pair_k(Bool.pick(U64, skip, 0u64, Bool.pick(U64, Bool.or(fwd, bwd), 1u64, 2u64)), fwd, bwd, px, py)

def ix_lo(x: Ix) -> F64:
  Ix{l, i, n, p, lo} = x
  lo

def ix_cmp(a: Ix, b: Ix) -> B.Sgn:
  +x = ix_lo(a)
  +y = ix_lo(b)
  B.sgn_pick(F64.is_lt(x, y), F64.is_lt(y, x))

def pm_box(+p: Pm) -> List<&2, I.I>:
  pbox(p, V.iof(0.0f64, 1.0f64))

def ix_ps(ps: List<&2, Pm>, +l: Nat, +i: Nat, +n: Nat) -> List<&2, Ix>:
  match ps:
    case []: []
    case +p <> t: Ix{l, i, n, p, I.i_lo(V.vn(pm_box(p), 0n))} <> ix_ps(t, l, Nat.add(i, 1n), n)

def ix_lzs(ls: List<&2, Lz>, +l: Nat) -> List<&2, Ix>:
  match ls:
    case []: []
    case +x <> t:
      +ps = lz_ps(x)
      List.append(&2, Ix, ix_ps(ps, l, 0n, List.length(&2, Pm, ps)), ix_lzs(t, Nat.add(l, 1n)))

def so_ix(s: B.So<&2, Ix>) -> List<&2, Ix>:
  B.So{ok, xs} = s
  xs

def ix_hi(x: Ix) -> F64:
  Ix{l, i, n, p, lo} = x
  I.i_hi(V.vn(pm_box(p), 0n))

def stop_at(ys: List<&2, Ix>, +hi: F64) -> Bool:
  match ys:
    case []: True{}
    case y <> t: F64.is_lt(hi, ix_lo(y))

def scan(ys: List<&2, Ix>, stop: Bool, +x: Ix, +hi: F64) -> Bool:
  match ys:
    case []: True{}
    case +y <> +t:
      match stop:
        case True{}: True{}
        case False{}: Bool.and(pair_ok(x, y), scan(t, stop_at(t, hi), x, hi))

def sweep_ok(xs: List<&2, Ix>) -> Bool:
  match xs:
    case []: True{}
    case +x <> +t:
      +hi = ix_hi(x)
      Bool.and(scan(t, stop_at(t, hi), x, hi), sweep_ok(t))

def lzs_ok(ls: List<&2, Lz>) -> Bool:
  match ls:
    case []: True{}
    case x <> t: Bool.and(lz_ok(x), lzs_ok(t))

def shift(xs: List<&2, Ix>, +o: Nat) -> List<&2, Ix>:
  match xs:
    case []: []
    case x <> t:
      Ix{l, i, n, p, lo} = x
      Ix{Nat.add(l, o), i, n, p, lo} <> shift(t, o)

def cert(+fixed: List<&2, Lz>, +free: List<&2, Lz>) -> Bool:
  +xs = List.append(&2, Ix, ix_lzs(fixed, 0n), shift(ix_lzs(free, 0n), 1000000n))
  Bool.and(lzs_ok(free), sweep_ok(so_ix(B.msort(~Ix, ~ix_cmp, xs))))

def x_code(+p: Pm, +s: I.I) -> U64:
  +x = V.vn(pbox(p, s), 0n)
  Bool.pick(U64, pos(x), 1u64, Bool.pick(U64, neg(x), 0u64, 2u64))

def xpos_go(d: Nat, +k: U64, +p: Pm, +s: I.I) -> Bool:
  match d:
    case 0n: U64.is_eq(k, 1u64)
    case 1n+(+e):
      match k:
        case 1u64: True{}
        case 0u64: False{}
        case _: Bool.and(xpos_go(e, x_code(p, half(s, True{})), p, half(s, True{})), xpos_go(e, x_code(p, half(s, False{})), p, half(s, False{})))

def pm_xa(p: Pm) -> X.Xp:
  match p:
    case Pl{a, b, xa, xb}: xa
    case Pa{c, r, a, b, ccw, th, xa, xb}: xa
    case Pc{c, r, xc, xr}: X.X_sub{xc, xr}

def pm_xb(p: Pm) -> X.Xp:
  match p:
    case Pl{a, b, xa, xb}: xb
    case Pa{c, r, a, b, ccw, th, xa, xb}: xb
    case Pc{c, r, xc, xr}: X.X_sub{xc, xr}

def ax_end(+p: Pm, +e: Bool, +dl: F64) -> Bool:
  +dx = V.vn(pder(p, piece(Bool.pick(Nat, e, 2n, 0n), dl)), 0n)
  Bool.pick(Bool, e, neg(dx), pos(dx))

def is_pl(p: Pm) -> Bool:
  match p:
    case Pl{a, b, xa, xb}: True{}
    case _: False{}

def pm_xok(+p: Pm, +hole: Bool) -> Bool:
  +za = Y.is_zero(pm_xa(p))
  +zb = Y.is_zero(pm_xb(p))
  +dl = F64.mul(0.25f64, 0.25f64)
  +s = V.iof(Bool.pick(F64, za, dl, 0.0f64), Bool.pick(F64, zb, F64.sub(1.0f64, dl), 1.0f64))
  +axis = Bool.and(is_pl(p), Bool.and(za, zb))
  +ends = Bool.and(Bool.or(Bool.not(za), ax_end(p, False{}, dl)), Bool.or(Bool.not(zb), ax_end(p, True{}, dl)))
  +inner = Bool.and(xpos_go(16n, x_code(p, s), p, s), ends)
  Bool.pick(Bool, hole, Bool.and(Bool.not(Bool.or(za, zb)), inner), Bool.or(axis, inner))

def pms_xok(ps: List<&2, Pm>, +hole: Bool) -> Bool:
  match ps:
    case []: True{}
    case +p <> t: Bool.and(pm_xok(p, hole), pms_xok(t, hole))

def zd_n(z: Zd) -> Nat:
  Zd{ids, vs} = z
  List.length(&2, U64, ids)

def find_ix(ids: List<&2, U64>, +id: U64, +i: Nat) -> Nat:
  match ids:
    case []: i
    case x <> t: Bool.pick(Nat, U64.is_eq(x, id), i, find_ix(t, id, Nat.add(i, 1n)))

def zd_var(+z: Zd, +id: U64) -> D.Dv:
  Zd{+ids, vs} = z
  +n = List.length(&2, U64, ids)
  +i = find_ix(ids, id, 0n)
  D.dvar(n, i, V.vn(vs, i))

def xd(x: X.Xp, +z: Zd) -> D.Dv:
  match x:
    case X.X_k{v}: D.dk(zd_n(z), I.ipt(v))
    case X.X_p{id}: zd_var(z, id)
    case X.X_add{a, b}: D.dadd(xd(a, z), xd(b, z))
    case X.X_sub{a, b}: D.dsub(xd(a, z), xd(b, z))
    case X.X_mul{a, b}: D.dmul(xd(a, z), xd(b, z))
    case X.X_div{a, b}: D.ddiv(xd(a, z), xd(b, z))
    case X.X_neg{a}: D.dneg(xd(a, z))

def dvn(xs: List<&2, D.Dv>, +i: Nat) -> D.Dv:
  match xs:
    case []: D.Dv{I.ipt(F64.nan()), []}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: dvn(t, j)

def dp(+x: X.Xp, +y: X.Xp, +z: Zd) -> List<&2, D.Dv>:
  [xd(x, z), xd(y, z)]

def dsubv(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> List<&2, D.Dv>:
  [D.dsub(dvn(a, 0n), dvn(b, 0n)), D.dsub(dvn(a, 1n), dvn(b, 1n))]

def daddv(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> List<&2, D.Dv>:
  [D.dadd(dvn(a, 0n), dvn(b, 0n)), D.dadd(dvn(a, 1n), dvn(b, 1n))]

def dcr(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> D.Dv:
  D.dsub(D.dmul(dvn(a, 0n), dvn(b, 1n)), D.dmul(dvn(a, 1n), dvn(b, 0n)))

def ddot(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> D.Dv:
  D.dadd(D.dmul(dvn(a, 0n), dvn(b, 0n)), D.dmul(dvn(a, 1n), dvn(b, 1n)))

def dvals(+a: List<&2, D.Dv>) -> List<&2, I.I>:
  [D.dval(dvn(a, 0n)), D.dval(dvn(a, 1n))]

def dkv(+n: Nat, +v: List<&2, I.I>) -> List<&2, D.Dv>:
  [D.dk(n, V.vn(v, 0n)), D.dk(n, V.vn(v, 1n))]

def dsang(+u0: List<&2, I.I>, +u: List<&2, D.Dv>, +n: Nat) -> D.Dv:
  +c0 = dkv(n, u0)
  D.datan(dcr(c0, u), ddot(c0, u), sang(u0, dvals(u)))

def dsweep(+c: List<&2, D.Dv>, +a: List<&2, D.Dv>, +b: List<&2, D.Dv>, +ccw: Bool, +n: Nat) -> D.Dv:
  +u = dsubv(a, c)
  +v = dsubv(b, c)
  +u0 = mids(dvals(u))
  +v0 = mids(dvals(v))
  +t0 = ang_ccw(cr2(u0, v0), V.vdot(u0, v0))
  +da = dsang(u0, u, n)
  +db = dsang(v0, v, n)
  Bool.pick(D.Dv, ccw, D.dadd(D.dk(n, t0), D.dsub(db, da)), D.dadd(D.dk(n, I.isub(two_pi(), t0)), D.dsub(da, db)))

def drot(+u: List<&2, D.Dv>, +f: D.Dv, +ccw: Bool) -> List<&2, D.Dv>:
  +sc = D.dsincos(f, cossin(D.dval(f)))
  +c = dvn(sc, 0n)
  +s0 = dvn(sc, 1n)
  +s = Bool.pick(D.Dv, ccw, s0, D.dneg(s0))
  +ux = dvn(u, 0n)
  +uy = dvn(u, 1n)
  [D.dsub(D.dmul(c, ux), D.dmul(s, uy)), D.dadd(D.dmul(s, ux), D.dmul(c, uy))]

def dsin(+f: D.Dv) -> D.Dv:
  dvn(D.dsincos(f, cossin(D.dval(f))), 1n)

def dhalf(+x: D.Dv) -> D.Dv:
  D.dsc(I.ipt(0.5f64), x)

def dm_add(+a: Dm, +b: Dm) -> Dm:
  Dm{ar1, ln1, rv1, ra1} = a
  Dm{ar2, ln2, rv2, ra2} = b
  Dm{D.dadd(ar1, ar2), D.dadd(ln1, ln2), D.dadd(rv1, rv2), D.dadd(ra1, ra2)}

def dm_zero(+n: Nat) -> Dm:
  Dm{D.dk(n, I.ipt(0.0f64)), D.dk(n, I.ipt(0.0f64)), D.dk(n, I.ipt(0.0f64)), D.dk(n, I.ipt(0.0f64))}

def drline(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> D.Dv:
  +ra = dvn(a, 0n)
  +rb = dvn(b, 0n)
  D.dsc(I.idiv(I.ipt(1.0f64), I.ipt(6.0f64)), D.dmul(D.dsub(dvn(b, 1n), dvn(a, 1n)), D.dadd(D.dadd(D.dsq(ra), D.dmul(ra, rb)), D.dsq(rb))))

def dlen(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>) -> D.Dv:
  +d = dsubv(b, a)
  D.dsqrt(ddot(d, d))

def dline(+a: List<&2, D.Dv>, +b: List<&2, D.Dv>, +axis: Bool, +n: Nat) -> Dm:
  +l = dlen(a, b)
  Dm{dhalf(dcr(a, b)), l, drline(a, b), Bool.pick(D.Dv, axis, D.dk(n, I.ipt(0.0f64)), dhalf(D.dmul(l, D.dadd(dvn(a, 0n), dvn(b, 0n)))))}

def dpiece(+c: List<&2, D.Dv>, +r: D.Dv, +a: List<&2, D.Dv>, +b: List<&2, D.Dv>, +f: D.Dv, +ccw: Bool) -> Dm:
  +sg0 = dhalf(D.dmul(D.dsq(r), D.dsub(f, dsin(f))))
  +sg = Bool.pick(D.Dv, ccw, sg0, D.dneg(sg0))
  +hf = D.ddiv(dlen(a, b), D.dsc(I.ipt(2.0f64), r))
  +s = daddv(dsubv(a, c), dsubv(b, c))
  +bxu = D.ddiv(dvn(s, 0n), D.dsqrt(ddot(s, s)))
  +t0 = D.dadd(D.dmul(sg0, dvn(c, 0n)), D.dmul(D.dsc(I.idiv(I.ipt(2.0f64), I.ipt(3.0f64)), D.dmul(D.dmul(D.dsq(r), r), D.dmul(D.dmul(hf, hf), hf))), bxu))
  +t = Bool.pick(D.Dv, ccw, t0, D.dneg(t0))
  +dy = D.dsub(dvn(b, 1n), dvn(a, 1n))
  Dm{D.dadd(dhalf(dcr(a, b)), sg), D.dmul(r, f), D.dadd(drline(a, b), t), D.dadd(D.dmul(D.dmul(r, dvn(c, 0n)), f), D.dmul(r, Bool.pick(D.Dv, ccw, dy, D.dneg(dy))))}

def darc(+c: List<&2, D.Dv>, +r: D.Dv, +a: List<&2, D.Dv>, +b: List<&2, D.Dv>, +ccw: Bool, +n: Nat) -> Dm:
  +th = dsweep(c, a, b, ccw, n)
  +f = D.dsc(I.ipt(0.25f64), th)
  +u = dsubv(a, c)
  +m1 = daddv(c, drot(u, f, ccw))
  +m2 = daddv(c, drot(u, D.dsc(I.ipt(0.5f64), th), ccw))
  +m3 = daddv(c, drot(u, D.dsc(I.ipt(0.75f64), th), ccw))
  dm_add(dm_add(dpiece(c, r, a, m1, f, ccw), dpiece(c, r, m1, m2, f, ccw)), dm_add(dpiece(c, r, m2, m3, f, ccw), dpiece(c, r, m3, b, f, ccw)))

def dseg(s: F.Seg, +p: Pt, +z: Zd) -> Dm:
  match s:
    case F.S_line{+x, +y}:
      +px = pt_x(p)
      dline(dp(px, pt_y(p), z), dp(x, y, z), Bool.and(Y.is_zero(px), Y.is_zero(x)), zd_n(z))
    case F.S_arc{cx, cy, r, +x, +y, ccw}: darc(dp(cx, cy, z), xd(r, z), dp(pt_x(p), pt_y(p), z), dp(x, y, z), ccw, zd_n(z))

def seg_end(s: F.Seg) -> Pt:
  match s:
    case F.S_line{x, y}: Pt{x, y}
    case F.S_arc{cx, cy, r, x, y, ccw}: Pt{x, y}

def dsegs(ss: List<&2, F.Seg>, +p: Pt, +z: Zd, +acc: Dm) -> Dm:
  match ss:
    case []:
      +n = zd_n(z)
      dm_add(acc, dm_zero(n))
    case +s <> t: dsegs(t, seg_end(s), z, dm_add(acc, dseg(s, p, z)))

def dclose(+last: Pt, +x0: X.Xp, +y0: X.Xp, +z: Zd) -> Dm:
  +x = pt_x(last)
  +y = pt_y(last)
  +n = zd_n(z)
  Bool.pick(Dm, Bool.and(Y.same(x, x0), Y.same(y, y0)), dm_zero(n), dline(dp(x, y, z), dp(x0, y0, z), Bool.and(Y.is_zero(x), Y.is_zero(x0)), n))

def last_pt(ss: List<&2, F.Seg>, +p: Pt) -> Pt:
  match ss:
    case []: p
    case +s <> t: last_pt(t, seg_end(s))

def dloop(l: F.Loop, +z: Zd) -> Dm:
  match l:
    case F.L_path{+x, +y, +segs}: dm_add(dsegs(segs, Pt{x, y}, z, dm_zero(zd_n(z))), dclose(last_pt(segs, Pt{x, y}), x, y, z))
    case F.L_circ{cx, cy, r}:
      +c = dp(cx, cy, z)
      +rr = xd(r, z)
      +r2 = D.dsq(rr)
      Dm{D.dsc(I.pi_i(), r2), D.dsc(two_pi(), rr), D.dsc(I.pi_i(), D.dmul(r2, dvn(c, 0n))), D.dsc(two_pi(), D.dmul(rr, dvn(c, 0n)))}

def dm_ar(m: Dm) -> D.Dv:
  Dm{ar, ln, rv, ra} = m
  ar

def dm_ln(m: Dm) -> D.Dv:
  Dm{ar, ln, rv, ra} = m
  ln

def dm_rv(m: Dm) -> D.Dv:
  Dm{ar, ln, rv, ra} = m
  rv

def dm_ra(m: Dm) -> D.Dv:
  Dm{ar, ln, rv, ra} = m
  ra

def dabs(+a: D.Dv) -> D.Dv:
  +v = D.dval(a)
  Bool.pick(D.Dv, neg(v), D.dneg(a), Bool.pick(D.Dv, pos(v), a, D.Dv{V.iof(F64.nan(), F64.nan()), D.dgrad(a)}))
