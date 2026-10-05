import Base
import ../base/par.bend as B
import ../base/ex.bend as E
import ../c05/exact.bend as XE








type QP is Data:
  QP{ id: Nat, x: F64, y: F64 }








type Tri is Data:
  Tri{ a: Nat, b: Nat, c: Nat }








type Gr is Data:
  Gr{ x0: F64, y0: F64, cs: F64, nx: Nat, ny: Nat, cells: B.Tb<&2, List<&2, Nat>> }








type CL is Data:
  CL{ c: Nat, l: Nat }








type Pg is Data:
  Pg{ pts: B.Tb<&2, QP>, nx: B.Tb<&2, Nat>, pv: B.Tb<&2, Nat>, rm: B.Tb<&2, Bool>, dup: B.Tb<&2, Bool>, main: B.Tb<&2, Bool> }








type SE is Data:
  SE{ a: Nat, b: Nat }








type DC is Data:
  DC{ d: F64, i: Nat }








type HB is Data:
  HB{ b: Nat, n: Nat, mx: F64, im: Nat }








def qx(q: QP) -> F64:
  QP{id, x, y} = q
  x








def qy(q: QP) -> F64:
  QP{id, x, y} = q
  y








def qid(q: QP) -> Nat:
  QP{id, x, y} = q
  id








def u(+n: Nat) -> U32:
  U32.from_nat(n)








def sgp(s: B.Sgn) -> Bool:
  match s:
    case B.Sp{}: True{}
    case _: False{}








def sgn(s: B.Sgn) -> Bool:
  match s:
    case B.Sn{}: True{}
    case _: False{}








def ori(+a: QP, +b: QP, +c: QP) -> B.Sgn:
  XE.orient2s(qx(a), qy(a), qx(b), qy(b), qx(c), qy(c))








def same(+a: QP, +b: QP) -> Bool:
  Bool.and(F64.is_eq(qx(a), qx(b)), F64.is_eq(qy(a), qy(b)))








def pg_pts(p: Pg) -> B.Tb<&2, QP>:
  Pg{pts, nx, pv, rm, dup, main} = p
  pts








def pg_nx(p: Pg) -> B.Tb<&2, Nat>:
  Pg{pts, nx, pv, rm, dup, main} = p
  nx








def pg_pv(p: Pg) -> B.Tb<&2, Nat>:
  Pg{pts, nx, pv, rm, dup, main} = p
  pv








def pg_rm(p: Pg) -> B.Tb<&2, Bool>:
  Pg{pts, nx, pv, rm, dup, main} = p
  rm








def pg_dup(p: Pg) -> B.Tb<&2, Bool>:
  Pg{pts, nx, pv, rm, dup, main} = p
  dup








def pg_main(p: Pg) -> B.Tb<&2, Bool>:
  Pg{pts, nx, pv, rm, dup, main} = p
  main








def pt(+p: Pg, +i: Nat) -> QP:
  B.tb_get(QP, pg_pts(p), u(i))








def nxt(+p: Pg, +i: Nat) -> Nat:
  B.tb_get(Nat, pg_nx(p), u(i))








def prv(+p: Pg, +i: Nat) -> Nat:
  B.tb_get(Nat, pg_pv(p), u(i))








def gone(+p: Pg, +i: Nat) -> Bool:
  B.tb_get(Bool, pg_rm(p), u(i))








def cix(+v: F64, +v0: F64, +cs: F64, +n: Nat) -> Nat:
  +f = F64.min(F64.max(F64.div(F64.sub(v, v0), cs), 0.0f64), U64.to_f64(U64.from_nat(Nat.sub(n, 1n))))
  U64.to_nat(F64.to_u64(f))








def cell_of(+g: Gr, +x: F64, +y: F64) -> Nat:
  Gr{+x0, +y0, +cs, +nx, +ny, cells} = g
  Nat.add(Nat.mul(cix(y, y0, cs, ny), nx), cix(x, x0, cs, nx))








def cl_c(x: CL) -> Nat:
  CL{c, l} = x
  c








def cl_l(x: CL) -> Nat:
  CL{c, l} = x
  l








def cl_cmp_go(+a: CL, +b: CL) -> B.Sgn:
  B.sgn_pick(Nat.is_lt(cl_c(a), cl_c(b)), Nat.is_lt(cl_c(b), cl_c(a)))








def cl_cmp(a: CL, b: CL) -> B.Sgn:
  cl_cmp_go(a, b)








def so_cl(s: B.So<&2, CL>) -> List<&2, CL>:
  B.So{ok, xs} = s
  xs








def grp(f: Nat, +c: Nat, xs: List<&2, CL>, +acc: List<&2, Nat>) -> List<&2, List<&2, Nat>>:
  match f:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: acc <> grp(m, Nat.add(c, 1n), [], [])
        case +x <> +t:
          +here = Nat.is_eq(cl_c(x), c)
          List.append(&2, List<&2, Nat>, Bool.pick(List<&2, List<&2, Nat>>, here, [], [acc]),
            grp(m, Bool.pick(Nat, here, c, Nat.add(c, 1n)), Bool.pick(List<&2, CL>, here, t, x <> t),
              Bool.pick(List<&2, Nat>, here, cl_l(x) <> acc, [])))








def cls_pts(ps: List<&2, QP>, +g0: Gr, +i: Nat) -> List<&2, CL>:
  match ps:
    case []: []
    case +p <> t: CL{cell_of(g0, qx(p), qy(p)), i} <> cls_pts(t, g0, Nat.add(i, 1n))








def bb_go(ps: List<&2, QP>, +x0: F64, +x1: F64, +y0: F64, +y1: F64) -> List<&2, F64>:
  match ps:
    case []: [x0, x1, y0, y1]
    case +p <> t: bb_go(t, F64.min(x0, qx(p)), F64.max(x1, qx(p)), F64.min(y0, qy(p)), F64.max(y1, qy(p)))








def f4(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: 0.0f64
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: f4(t, j)








def isqrt_n(+n: Nat) -> Nat:
  U64.to_nat(F64.to_u64(F64.sqrt(U64.to_f64(U64.from_nat(n)))))








def inf() -> F64:
  F64.div(1.0f64, 0.0f64)








def gr_frame(+ps: List<&2, QP>) -> Gr:
  +n = List.length(&2, QP, ps)
  +bb = bb_go(ps, inf(), F64.neg(inf()), inf(), F64.neg(inf()))
  +w = F64.max(F64.sub(f4(bb, 1n), f4(bb, 0n)), F64.sub(f4(bb, 3n), f4(bb, 2n)))
  +k = Nat.max(1n, isqrt_n(n))
  +cs = F64.max(F64.div(w, U64.to_f64(U64.from_nat(k))), 1.0e-300f64)
  +nx = Nat.add(U64.to_nat(F64.to_u64(F64.div(F64.sub(f4(bb, 1n), f4(bb, 0n)), cs))), 1n)
  +ny = Nat.add(U64.to_nat(F64.to_u64(F64.div(F64.sub(f4(bb, 3n), f4(bb, 2n)), cs))), 1n)
  Gr{f4(bb, 0n), f4(bb, 2n), cs, nx, ny, B.tb_of(List<&2, Nat>, [], [])}








def gr_fill(g0: Gr, +ps: List<&2, QP>) -> Gr:
  Gr{+x0, +y0, +cs, +nx, +ny, c0} = g0
  +nc = Nat.mul(nx, ny)
  +cl = so_cl(B.msort(~CL, ~cl_cmp, cls_pts(ps, Gr{x0, y0, cs, nx, ny, c0}, 0n)))
  Gr{x0, y0, cs, nx, ny, B.tb_of(List<&2, Nat>, grp(Nat.add(nc, List.length(&2, CL, cl)), 0n, cl, []), [])}








def g_cell(+g: Gr, +i: Nat) -> List<&2, Nat>:
  Gr{x0, y0, cs, nx, ny, +cells} = g
  B.tb_get(List<&2, Nat>, cells, u(i))








def g_cx(+g: Gr, +x: F64) -> Nat:
  Gr{+x0, y0, +cs, +nx, ny, cells} = g
  cix(x, x0, cs, nx)








def g_cy(+g: Gr, +y: F64) -> Nat:
  Gr{x0, +y0, +cs, nx, +ny, cells} = g
  cix(y, y0, cs, ny)








def g_nx(+g: Gr) -> Nat:
  Gr{x0, y0, cs, nx, ny, cells} = g
  nx








def row_cells(f: Nat, +g: Gr, +cx: Nat, +cy: Nat) -> List<&2, Nat>:
  match f:
    case 0n: []
    case 1n+m: List.append(&2, Nat, g_cell(g, Nat.add(Nat.mul(cy, g_nx(g)), cx)), row_cells(m, g, Nat.add(cx, 1n), cy))








def box_cells(f: Nat, +g: Gr, +cx0: Nat, +w: Nat, +cy: Nat) -> List<&2, Nat>:
  match f:
    case 0n: []
    case 1n+m: List.append(&2, Nat, row_cells(w, g, cx0, cy), box_cells(m, g, cx0, w, Nat.add(cy, 1n)))








def near(+g: Gr, +x0: F64, +x1: F64, +y0: F64, +y1: F64) -> List<&2, Nat>:
  +cx0 = g_cx(g, x0)
  +cx1 = g_cx(g, x1)
  +cy0 = g_cy(g, y0)
  +cy1 = g_cy(g, y1)
  box_cells(Nat.add(Nat.sub(cy1, cy0), 1n), g, cx0, Nat.add(Nat.sub(cx1, cx0), 1n), cy0)








def in_tri(+a: QP, +b: QP, +c: QP, +q: QP) -> Bool:
  Bool.and(Bool.not(sgn(ori(a, b, q))), Bool.and(Bool.not(sgn(ori(b, c, q))), Bool.not(sgn(ori(c, a, q)))))








def ang_in(+v: QP, +w1: QP, +w2: QP, +n: QP) -> Bool:
  Bool.and(sgp(ori(v, w1, n)), sgp(ori(v, n, w2)))








def blocks(+p: Pg, +ia: Nat, +ib: Nat, +ic: Nat, +a: QP, +b: QP, +c: QP, +j: Nat) -> Bool:
  +q = pt(p, j)
  +self = Bool.or(Nat.is_eq(j, ia), Bool.or(Nat.is_eq(j, ib), Nat.is_eq(j, ic)))
  +co = Bool.or(same(q, a), Bool.or(same(q, b), same(q, c)))
  +pn = pt(p, prv(p, j))
  +nn = pt(p, nxt(p, j))
  +dupb = Bool.or(Bool.and(same(q, a), Bool.or(ang_in(a, b, c, pn), ang_in(a, b, c, nn))),
    Bool.or(Bool.and(same(q, b), Bool.or(ang_in(b, c, a, pn), ang_in(b, c, a, nn))),
      Bool.and(same(q, c), Bool.or(ang_in(c, a, b, pn), ang_in(c, a, b, nn)))))
  Bool.and(Bool.not(self), Bool.and(Bool.not(gone(p, j)), Bool.pick(Bool, co, dupb, in_tri(a, b, c, q))))








def any_block(js: List<&2, Nat>, +p: Pg, +ia: Nat, +ib: Nat, +ic: Nat, +a: QP, +b: QP, +c: QP) -> Bool:
  match js:
    case []: False{}
    case +j <> t: Bool.or(blocks(p, ia, ib, ic, a, b, c, j), any_block(t, p, ia, ib, ic, a, b, c))








def ear_go(cv: Bool, +p: Pg, +g: Gr, +ia: Nat, +ib: Nat, +ic: Nat, +a: QP, +b: QP, +c: QP) -> Bool:
  match cv:
    case False{}: False{}
    case True{}:
      +x0 = F64.min(qx(a), F64.min(qx(b), qx(c)))
      +x1 = F64.max(qx(a), F64.max(qx(b), qx(c)))
      +y0 = F64.min(qy(a), F64.min(qy(b), qy(c)))
      +y1 = F64.max(qy(a), F64.max(qy(b), qy(c)))
      Bool.not(any_block(near(g, x0, x1, y0, y1), p, ia, ib, ic, a, b, c))







def ear_at(+p: Pg, +g: Gr, +ib: Nat) -> Bool:
  +ia = prv(p, ib)
  +ic = nxt(p, ib)
  +a = pt(p, ia)
  +b = pt(p, ib)
  +c = pt(p, ic)
  ear_go(sgp(ori(a, b, c)), p, g, ia, ib, ic, a, b, c)







def unlink(p: Pg, +ib: Nat) -> Pg:
  Pg{+pts, +nx, +pv, +rm, dup, main} = p
  +ia = B.tb_get(Nat, pv, u(ib))
  +ic = B.tb_get(Nat, nx, u(ib))
  Pg{pts, B.tb_set(Nat, nx, u(ia), ic), B.tb_set(Nat, pv, u(ic), ia), B.tb_set(Bool, rm, u(ib), True{}), dup, main}








def tri_of(+p: Pg, +ib: Nat) -> Tri:
  Tri{qid(pt(p, prv(p, ib))), qid(pt(p, ib)), qid(pt(p, nxt(p, ib)))}








def ear_if(gn: Bool, +p: Pg, +g: Gr, +ib: Nat) -> Bool:
  match gn:
    case True{}: False{}
    case False{}: ear_at(p, g, ib)





def walk(n: Nat, +p: Pg, +i: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: i <> walk(m, p, nxt(p, i))




def clip(f: Nat, done: Bool, +p: Pg, +g: Gr, st: List<&2, Nat>, +r: Nat, +acc: List<&2, Tri>, +alive: Nat, +prog: Bool) -> List<&2, Tri>:
  match f:
    case 0n: acc
    case 1n+(+m):
      match done:
        case True{}: acc
        case False{}:
          match st:
            case []: clip(m, Bool.not(prog), p, g, walk(r, p, alive), r, acc, alive, False{})
            case +b <> +t:
              +g0 = gone(p, b)
              +last = Bool.and(Bool.not(g0), Nat.is_le(r, 3n))
              +ear = Bool.or(last, ear_if(Bool.or(g0, last), p, g, b))
              clip(m, last, Bool.pick(Pg, ear, unlink(p, b), p), g,
                Bool.pick(List<&2, Nat>, ear, prv(p, b) <> nxt(p, b) <> t, t), Bool.pick(Nat, ear, Nat.sub(r, 1n), r),
                Bool.pick(List<&2, Tri>, ear, tri_of(p, b) <> acc, acc), Bool.pick(Nat, ear, prv(p, b), alive), Bool.or(prog, ear))




def n_seq(n: Nat, +b: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: b <> n_seq(m, Nat.add(b, 1n))





def ring_links(n: Nat, +b: Nat, +i: Nat, +len: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: Nat.add(b, Bool.pick(Nat, Nat.is_eq(Nat.add(i, 1n), len), 0n, Nat.add(i, 1n))) <> ring_links(m, b, Nat.add(i, 1n), len)








def ring_backs(n: Nat, +b: Nat, +i: Nat, +len: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: Nat.add(b, Bool.pick(Nat, Nat.is_eq(i, 0n), Nat.sub(len, 1n), Nat.sub(i, 1n))) <> ring_backs(m, b, Nat.add(i, 1n), len)








def rings_nx(rs: List<&2, List<&2, QP>>, +b: Nat) -> List<&2, Nat>:
  match rs:
    case []: []
    case +r <> t:
      +n = List.length(&2, QP, r)
      List.append(&2, Nat, ring_links(n, b, 0n, n), rings_nx(t, Nat.add(b, n)))








def rings_pv(rs: List<&2, List<&2, QP>>, +b: Nat) -> List<&2, Nat>:
  match rs:
    case []: []
    case +r <> t:
      +n = List.length(&2, QP, r)
      List.append(&2, Nat, ring_backs(n, b, 0n, n), rings_pv(t, Nat.add(b, n)))








def rep_b(n: Nat, +x: Bool) -> List<&2, Bool>:
  match n:
    case 0n: []
    case 1n+m: x <> rep_b(m, x)








def rep_n(n: Nat, +x: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: x <> rep_n(m, x)








def rep_q(n: Nat, +x: QP) -> List<&2, QP>:
  match n:
    case 0n: []
    case 1n+m: x <> rep_q(m, x)








def cat_q(rs: List<&2, List<&2, QP>>) -> List<&2, QP>:
  match rs:
    case []: []
    case r <> t: List.append(&2, QP, r, cat_q(t))








def maxx_i(xs: List<&2, QP>, +i: Nat, +bi: Nat, +bx: F64) -> Nat:
  match xs:
    case []: bi
    case +p <> t:
      +b = F64.is_lt(bx, qx(p))
      maxx_i(t, Nat.add(i, 1n), Bool.pick(Nat, b, i, bi), Bool.pick(F64, b, qx(p), bx))








def sep(+m: QP, +q: QP, +a: QP, +b: QP) -> Bool:
  +s1 = ori(m, q, a)
  +s2 = ori(m, q, b)
  +s3 = ori(a, b, m)
  +s4 = ori(a, b, q)
  Bool.or(Bool.or(Bool.and(sgp(s1), sgp(s2)), Bool.and(sgn(s1), sgn(s2))), Bool.or(Bool.and(sgp(s3), sgp(s4)), Bool.and(sgn(s3), sgn(s4))))








def seg_clear(+p: Pg, +m: QP, +q: QP, +ea: Nat) -> Bool:
  +a = pt(p, ea)
  +b = pt(p, nxt(p, ea))
  +touch = Bool.or(same(a, m), Bool.or(same(b, m), Bool.or(same(a, q), same(b, q))))
  Bool.or(Bool.or(touch, gone(p, ea)), sep(m, q, a, b))








def all_clear(es: List<&2, Nat>, +p: Pg, +m: QP, +q: QP) -> Bool:
  match es:
    case []: True{}
    case +e <> t: Bool.and(seg_clear(p, m, q, e), all_clear(t, p, m, q))








def gr_with(g: Gr, +c: B.Tb<&2, List<&2, Nat>>) -> Gr:
  Gr{x0, y0, cs, nx, ny, cells} = g
  Gr{x0, y0, cs, nx, ny, c}



def g_cs(+g: Gr) -> F64:
  Gr{x0, y0, cs, nx, ny, cells} = g
  cs








def visible(+p: Pg, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +longs: List<&2, Nat>, +im: Nat, +iq: Nat) -> Bool:
  +m = pt(p, im)
  +q = pt(p, iq)
  +x0 = F64.min(qx(m), qx(q))
  +x1 = F64.max(qx(m), qx(q))
  +y0 = F64.min(qy(m), qy(q))
  +y1 = F64.max(qy(m), qy(q))
  +e = g_cs(g)
  Bool.and(all_clear(longs, p, m, q), Bool.and(all_clear(near(g, F64.sub(x0, e), F64.add(x1, e), F64.sub(y0, e), F64.add(y1, e)), p, m, q),
    all_clear(near(gr_with(g, bg), x0, x1, y0, y1), p, m, q)))



def dc_cmp_go(+a: DC, +b: DC) -> B.Sgn:
  DC{+da, ia} = a
  DC{+db, ib} = b
  B.sgn_pick(F64.is_lt(da, db), F64.is_lt(db, da))








def dc_cmp(a: DC, b: DC) -> B.Sgn:
  dc_cmp_go(a, b)








def so_dc(s: B.So<&2, DC>) -> List<&2, DC>:
  B.So{ok, xs} = s
  xs








def d2(+a: QP, +b: QP) -> F64:
  +dx = F64.sub(qx(a), qx(b))
  +dy = F64.sub(qy(a), qy(b))
  F64.add(F64.mul(dx, dx), F64.mul(dy, dy))








def cands(js: List<&2, Nat>, +p: Pg, +m: QP) -> List<&2, DC>:
  match js:
    case []: []
    case +j <> t:
      +ok = Bool.and(B.tb_get(Bool, pg_main(p), u(j)), Bool.and(Bool.not(B.tb_get(Bool, pg_dup(p), u(j))), Bool.not(gone(p, j))))
      +rest = cands(t, p, m)
      Bool.pick(List<&2, DC>, ok, DC{d2(pt(p, j), m), j} <> rest, rest)








def dc_i(c: DC) -> Nat:
  DC{d, i} = c
  i






def first_vis(cs: List<&2, DC>, +p: Pg, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +longs: List<&2, Nat>, +im: Nat, +r: Nat) -> Nat:
  match cs:
    case []: r
    case +c <> t:
      match r:
        case 0n: first_vis(t, p, g, bg, longs, im, Bool.pick(Nat, visible(p, g, bg, longs, im, dc_i(c)), Nat.add(dc_i(c), 1n), 0n))
        case 1n+j: Nat.add(j, 1n)






def gr_cells(g: Gr) -> B.Tb<&2, List<&2, Nat>>:
  Gr{x0, y0, cs, nx, ny, cells} = g
  cells



def bg_row(f: Nat, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +cx: Nat, +cy: Nat, +e: Nat) -> B.Tb<&2, List<&2, Nat>>:
  match f:
    case 0n: bg
    case 1n+m:
      +i = u(Nat.add(Nat.mul(cy, g_nx(g)), cx))
      bg_row(m, g, B.tb_set(List<&2, Nat>, bg, i, e <> B.tb_get(List<&2, Nat>, bg, i)), Nat.add(cx, 1n), cy, e)



def bg_box(f: Nat, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +cx0: Nat, +w: Nat, +cy: Nat, +e: Nat) -> B.Tb<&2, List<&2, Nat>>:
  match f:
    case 0n: bg
    case 1n+m: bg_box(m, g, bg_row(w, g, bg, cx0, cy, e), cx0, w, Nat.add(cy, 1n), e)



def bg_add(+g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +a: QP, +b: QP, +e: Nat) -> B.Tb<&2, List<&2, Nat>>:
  +cx0 = g_cx(g, F64.min(qx(a), qx(b)))
  +cx1 = g_cx(g, F64.max(qx(a), qx(b)))
  +cy0 = g_cy(g, F64.min(qy(a), qy(b)))
  +cy1 = g_cy(g, F64.max(qy(a), qy(b)))
  bg_box(Nat.add(Nat.sub(cy1, cy0), 1n), g, bg, cx0, Nat.add(Nat.sub(cx1, cx0), 1n), cy0, e)



def win_find(f: Nat, +p: Pg, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +longs: List<&2, Nat>, +im: Nat, +k: F64, +r: Nat) -> Nat:
  match f:
    case 0n: r
    case 1n+m:
      match r:
        case 0n:
          +q = pt(p, im)
          win_find(m, p, g, bg, longs, im, F64.mul(k, 2.0f64),
            first_vis(so_dc(B.msort(~DC, ~dc_cmp, cands(near(g, F64.sub(qx(q), k), F64.add(qx(q), k), F64.sub(qy(q), k), F64.add(qy(q), k)), p, q))),
              p, g, bg, longs, im, 0n))
        case 1n+j: Nat.add(j, 1n)






def splice(p: Pg, +ip: Nat, +im: Nat, +s: Nat) -> Pg:
  Pg{+pts, +nx, +pv, rm, +dup, +main} = p
  +pn = B.tb_get(Nat, nx, u(ip))
  +mp = B.tb_get(Nat, pv, u(im))
  +m2 = s
  +p2 = Nat.add(s, 1n)
  +pts2 = B.tb_set(QP, B.tb_set(QP, pts, u(m2), B.tb_get(QP, pts, u(im))), u(p2), B.tb_get(QP, pts, u(ip)))
  +nx2 = B.tb_set(Nat, B.tb_set(Nat, B.tb_set(Nat, B.tb_set(Nat, nx, u(ip), im), u(mp), m2), u(m2), p2), u(p2), pn)
  +pv2 = B.tb_set(Nat, B.tb_set(Nat, B.tb_set(Nat, B.tb_set(Nat, pv, u(im), ip), u(m2), mp), u(p2), m2), u(pn), p2)
  +dup2 = B.tb_set(Bool, B.tb_set(Bool, B.tb_set(Bool, B.tb_set(Bool, dup, u(ip), True{}), u(im), True{}), u(m2), True{}), u(p2), True{})
  Pg{pts2, nx2, pv2, rm, dup2, main}








def set_main(n: Nat, +i: Nat, +main: B.Tb<&2, Bool>) -> B.Tb<&2, Bool>:
  match n:
    case 0n: main
    case 1n+m: set_main(m, Nat.add(i, 1n), B.tb_set(Bool, main, u(i), True{}))








def pg_main_on(p: Pg, +b: Nat, +n: Nat) -> Pg:
  Pg{pts, nx, pv, rm, dup, +main} = p
  Pg{pts, nx, pv, rm, dup, set_main(n, b, main)}








def q_nth(xs: List<&2, QP>, +i: Nat) -> QP:
  match xs:
    case []: QP{0n, 0.0f64, 0.0f64}
    case x <> t:
      match i:
        case 0n: x
        case 1n+j: q_nth(t, j)








def hbs(rs: List<&2, List<&2, QP>>, +b: Nat) -> List<&2, HB>:
  match rs:
    case []: []
    case +r <> t:
      +n = List.length(&2, QP, r)
      +i = maxx_i(r, 0n, 0n, F64.neg(inf()))
      HB{b, n, qx(q_nth(r, i)), Nat.add(b, i)} <> hbs(t, Nat.add(b, n))








def hb_cmp_go(+a: HB, +b: HB) -> B.Sgn:
  HB{ba, na, +ma, ia} = a
  HB{bb, nb, +mb, ib} = b
  B.sgn_pick(F64.is_lt(mb, ma), F64.is_lt(ma, mb))








def hb_cmp(a: HB, b: HB) -> B.Sgn:
  hb_cmp_go(a, b)








def so_hb(s: B.So<&2, HB>) -> List<&2, HB>:
  B.So{ok, xs} = s
  xs








def bridge_all(hs: List<&2, HB>, +p: Pg, +g: Gr, +bg: B.Tb<&2, List<&2, Nat>>, +longs: List<&2, Nat>, +s: Nat, +ok: Bool) -> List<&2, Pg>:
  match hs:
    case []: [p]
    case h <> t:
      HB{+b, +n, mx, +im} = h
      +ip1 = win_find(64n, p, g, bg, longs, im, F64.mul(g_cs(g), 1.0f64), 0n)
      +found = Bool.not(Nat.is_eq(ip1, 0n))
      +ip = Nat.sub(ip1, 1n)
      +pn = nxt(p, ip)
      +p2 = pg_main_on(splice(p, ip, im, s), b, n)
      +bg2 = bg_add(g, bg_add(g, bg_add(g, bg, pt(p, ip), pt(p, im), ip), pt(p, im), pt(p, ip), s), pt(p, ip), pt(p, pn), Nat.add(s, 1n))
      Bool.pick(List<&2, Pg>, found, bridge_all(t, p2, g, bg2, longs, Nat.add(s, 2n), ok), [])



def long_edges(f: Nat, +p: Pg, +g: Gr, +i: Nat) -> List<&2, Nat>:
  match f:
    case 0n: []
    case 1n+m:
      +a = pt(p, i)
      +b = pt(p, nxt(p, i))
      +lg = F64.is_lt(F64.mul(g_cs(g), g_cs(g)), d2(a, b))
      +rest = long_edges(m, p, g, Nat.add(i, 1n))
      Bool.pick(List<&2, Nat>, lg, i <> rest, rest)








def pg_hd(xs: List<&2, Pg>, +d: Pg) -> Pg:
  match xs:
    case []: d
    case x <> t: x








def mk_pg(+a: B.Tb<&2, QP>, +b: B.Tb<&2, Nat>, +c: B.Tb<&2, Nat>, +d: B.Tb<&2, Bool>, +e: B.Tb<&2, Bool>, +f: B.Tb<&2, Bool>) -> Pg:
  Pg{a, b, c, d, e, f}







def rep_l(n: Nat) -> List<&2, List<&2, Nat>>:
  match n:
    case 0n: []
    case 1n+m: [] <> rep_l(m)



def g_ny(+g: Gr) -> Nat:
  Gr{x0, y0, cs, nx, ny, cells} = g
  ny


def tri_poly(+o: List<&2, QP>, +hs: List<&2, List<&2, QP>>) -> List<&2, Tri>:
  +rs = {o <> hs : List<&2, List<&2, QP>>}
  +all = cat_q(rs)
  +n = List.length(&2, QP, all)
  +nh = List.length(&2, List<&2, QP>, hs)
  +tot = Nat.add(n, Nat.mul(2n, nh))
  +pad = {QP{0n, 0.0f64, 0.0f64} : QP}
  +no = List.length(&2, QP, o)
  +p0 = mk_pg(B.tb_of(QP, List.append(&2, QP, all, rep_q(Nat.mul(2n, nh), pad)), pad),
    B.tb_of(Nat, List.append(&2, Nat, rings_nx(rs, 0n), rep_n(Nat.mul(2n, nh), 0n)), 0n),
    B.tb_of(Nat, List.append(&2, Nat, rings_pv(rs, 0n), rep_n(Nat.mul(2n, nh), 0n)), 0n),
    B.tb_of(Bool, rep_b(tot, False{}), False{}), B.tb_of(Bool, rep_b(tot, False{}), False{}),
    B.tb_of(Bool, List.append(&2, Bool, rep_b(no, True{}), rep_b(Nat.sub(tot, no), False{})), False{}))
  +g = gr_fill(gr_frame(all), all)
  +bs = bridge_all(so_hb(B.msort(~HB, ~hb_cmp, hbs(hs, no))), p0, g, B.tb_of(List<&2, Nat>, rep_l(Nat.mul(g_nx(g), g_ny(g))), []), long_edges(n, p0, g, 0n), n, True{})
  +ok = Bool.not(Nat.is_eq(List.length(&2, Pg, bs), 0n))
  +p = pg_hd(bs, p0)
  +r = Nat.add(n, Nat.mul(2n, nh))
  Bool.pick(List<&2, Tri>, ok, clip(Nat.add(Nat.mul(8n, r), 64n), False{}, p, gr_fill(gr_frame(all), B.tb_list(QP, pg_pts(p))), n_seq(r, 0n), r, [], 0n, True{}), [])


