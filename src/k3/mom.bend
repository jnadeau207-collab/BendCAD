import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../k1/sf.bend as S
import ../k1/ef.bend as EF
import ../k1/fb.bend as FB
import ../k1/ls.bend as L
import ../k1/vi.bend as VI
import ../c06/model.bend as M
import ./div.bend as D
import ../c11/qmass.bend as QM

def cr_of(+ivs: List<&2, I.I>) -> List<&2, I.I>:
  +v = M.i_nth(ivs, 0n)
  [I.idiv(M.i_nth(ivs, 1n), v), I.idiv(M.i_nth(ivs, 2n), v), I.idiv(M.i_nth(ivs, 3n), v)]

def cl_of(+cr: List<&2, I.I>, +c: V.Point) -> List<&2, I.I>:
  [I.iadd(M.i_nth(cr, 0n), I.ipt(V.pt_x(c))), I.iadd(M.i_nth(cr, 1n), I.ipt(V.pt_y(c))), I.iadd(M.i_nth(cr, 2n), I.ipt(V.pt_z(c)))]

def il_of(+ivs: List<&2, I.I>) -> List<&2, I.I>:
  +sxx = M.i_nth(ivs, 4n)
  +syy = M.i_nth(ivs, 5n)
  +szz = M.i_nth(ivs, 6n)
  QM.i9_of(I.iadd(syy, szz), I.iadd(sxx, szz), I.iadd(sxx, syy), I.ineg(M.i_nth(ivs, 7n)), I.ineg(M.i_nth(ivs, 9n)),
    I.ineg(M.i_nth(ivs, 8n)))

def cen_s(+mi: List<&2, I.I>, +ti: List<&2, I.I>, +cl: List<&2, I.I>) -> String:
  QM.iv3_s(QM.cw_of(mi, ti, cl))

def ine_s(+mi: List<&2, I.I>, +il: List<&2, I.I>, +v: I.I, +cr: List<&2, I.I>) -> String:
  QM.iv6_s(QM.pk6(QM.rot_i(mi, QM.sh9(il, v, cr))))

def mom_line(+ivs: List<&2, I.I>, +c: V.Point, +pl: M.Pl) -> String:
  +cr = cr_of(ivs)
  +mi = M.pl_mi(pl)
  "moments volume=" ++ QM.iv_s(M.i_nth(ivs, 0n)) ++ " centroid " ++ cen_s(mi, M.pl_ti(pl), cl_of(cr, c)) ++ " inertia-centroid " ++
    ine_s(mi, il_of(ivs), M.i_nth(ivs, 0n), cr) ++ " status=certified method=divergence
"

def mom_of(+r: D.MR, +pl: M.Pl) -> String:
  D.MR{+c, +m, +e, +slv, +rad, ar, sla} = r
  mom_line(D.mv_iv(m, e, slv, rad), c, pl)

def mom_s(+b: M.Body) -> String:
  mom_of(D.brep_mom(M.bd_brep(b)), M.bd_pl(b))

def i3(+xs: List<&2, I.I>, +i: Nat) -> I.I:
  M.i_nth(xs, i)

def dot3(+a: List<&2, I.I>, +b: List<&2, I.I>) -> I.I:
  I.iadd(I.iadd(I.imul(i3(a, 0n), i3(b, 0n)), I.imul(i3(a, 1n), i3(b, 1n))), I.imul(i3(a, 2n), i3(b, 2n)))

def sc3(+k: I.I, +a: List<&2, I.I>) -> List<&2, I.I>:
  [I.imul(k, i3(a, 0n)), I.imul(k, i3(a, 1n)), I.imul(k, i3(a, 2n))]

def sub3(+a: List<&2, I.I>, +b: List<&2, I.I>) -> List<&2, I.I>:
  [I.isub(i3(a, 0n), i3(b, 0n)), I.isub(i3(a, 1n), i3(b, 1n)), I.isub(i3(a, 2n), i3(b, 2n))]

def mat3(+m: List<&2, I.I>, +v: List<&2, I.I>) -> List<&2, I.I>:
  [dot3([i3(m, 0n), i3(m, 1n), i3(m, 2n)], v), dot3([i3(m, 3n), i3(m, 4n), i3(m, 5n)], v), dot3([i3(m, 6n), i3(m, 7n), i3(m, 8n)], v)]

def root_nn(+x: I.I) -> I.I:
  I.isqrt(I.I{F64.max(0.0f64, I.i_lo(x)), F64.max(0.0f64, I.i_hi(x))})

def bal_verdict(+u: I.I, +up: I.I) -> String:
  Bool.pick(String, F64.is_lt(I.i_hi(u), I.i_lo(up)), "within status=certified",
    Bool.pick(String, F64.is_lt(I.i_hi(up), I.i_lo(u)), "exceeds status=certified", "undecided status=estimated"))

def bal_go(+ivs: List<&2, I.I>, +c: V.Point, +pl: M.Pl, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +w: F64, +g: F64) -> String:
  +cr = cr_of(ivs)
  +mi = M.pl_mi(pl)
  +v = i3(ivs, 0n)
  +cw = QM.cw_of(mi, M.pl_ti(pl), cl_of(cr, c))
  +iw = QM.rot_i(mi, QM.sh9(il_of(ivs), v, cr))
  +kg = I.iscale(v, F64.mul(rho, 1.0e-9f64))
  +r = sub3(cw, p)
  +perp = sub3(r, sc3(dot3(r, d), d))
  +e = root_nn(dot3(perp, perp))
  +u = I.iscale(I.imul(kg, e), 1000.0f64)
  +up = I.iscale(kg, F64.div(F64.mul(1000.0f64, g), w))
  +id = mat3(iw, d)
  +ddi = dot3(d, id)
  +pv = sub3(id, sc3(ddi, d))
  +pr = I.iscale(root_nn(dot3(pv, pv)), F64.mul(rho, 1.0e-9f64))
  "balance mass=" ++ QM.iv_s(kg) ++ " kg offset=" ++ QM.iv_s(e) ++ " mm residual=" ++ QM.iv_s(u) ++ " g.mm permissible=" ++
    QM.iv_s(up) ++ " g.mm grade=G" ++ F64.show(g) ++ " omega=" ++ F64.show(w) ++ " rad/s products=" ++ QM.iv_s(pr) ++
    " kg.mm2 " ++ bal_verdict(u, up) ++ " method=divergence
"

def even_go(+ivs: List<&2, I.I>, +c: V.Point, +pl: M.Pl, +p: List<&2, I.I>, +d: List<&2, I.I>) -> Bool:
  +cr = cr_of(ivs)
  +mi = M.pl_mi(pl)
  +v = i3(ivs, 0n)
  +r = sub3(QM.cw_of(mi, M.pl_ti(pl), cl_of(cr, c)), p)
  +perp = sub3(r, sc3(dot3(r, d), d))
  +id = mat3(QM.rot_i(mi, QM.sh9(il_of(ivs), v, cr)), d)
  +pv = sub3(id, sc3(dot3(d, id), d))
  +ax = I.i_hi(dot3(d, id))
  Bool.and(F64.is_le(I.i_lo(dot3(perp, perp)), F64.mul(1.0e-18f64, F64.div(ax, I.i_lo(v)))), F64.is_le(I.i_lo(dot3(pv, pv)), F64.mul(1.0e-18f64, F64.mul(ax, ax))))

def even_r(r: D.MR, +pl: M.Pl, +p: List<&2, I.I>, +d: List<&2, I.I>) -> Bool:
  D.MR{+c, +m, +e, +slv, +rad, ar, sla} = r
  even_go(D.mv_iv(m, e, slv, rad), c, pl, p, d)

def even(+b: M.Body, +p: List<&2, I.I>, +d: List<&2, I.I>) -> Bool:
  even_r(D.brep_mom(M.bd_brep(b)), M.bd_pl(b), p, d)

def bal_r(r: D.MR, +pl: M.Pl, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +w: F64, +g: F64) -> String:
  D.MR{+c, +m, +e, +slv, +rad, ar, sla} = r
  bal_go(D.mv_iv(m, e, slv, rad), c, pl, rho, p, d, w, g)

def bal_s(+b: M.Body, +rho: F64, +p: List<&2, I.I>, +d: List<&2, I.I>, +rpm: F64, +g: F64) -> String:
  bal_r(D.brep_mom(M.bd_brep(b)), M.bd_pl(b), rho, p, d, F64.div(F64.mul(rpm, 6.283185307179586f64), 60.0f64), g)
