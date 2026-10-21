import Base
import ../c01/types.bend as V
import ../base/par.bend as B
import ../c07/sol.bend as SO
import ../k1/sf.bend as S
import ../k1/ls.bend as L
import mesh.bend as K
import fem.bend as F
import warm.bend as W

type CL is Data:
  CL{ on: Bool, p: V.Point, d: V.Dir, r: F64, pl: Bool }

def org() -> V.Point:
  V.Pt{0.0f64, 0.0f64, 0.0f64}

def perp(+c: CL, +x: V.Point) -> V.Dir:
  CL{on, +p, +d, r, pl} = c
  +v = S.psub(x, p)
  S.dadd(v, F64.neg(S.dot(v, d)), d)

def held(+c: CL, +x: V.Point) -> Bool:
  CL{+on, +p, +d, +r, +pl} = c
  +w = perp(c, x)
  Bool.and(on, Bool.pick(Bool, pl, F64.is_le(F64.abs(S.dot(S.psub(x, p), d)), r), F64.is_le(F64.sqrt(S.dot(w, w)), r)))

def cl_mask(ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +m = Bool.pick(F64, held(c, x), 0.0f64, 1.0f64)
      m <> m <> m <> cl_mask(t, c)

def n_held(ps: List<&2, V.Point>, +c: CL, +n: Nat) -> Nat:
  match ps:
    case []: n
    case +x <> +t: n_held(t, c, Bool.pick(Nat, held(c, x), Nat.add(n, 1n), n))

def cl_on(+c: CL) -> Bool:
  CL{+on, p, d, r, pl} = c
  on

def xperp(ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +w = perp(c, x)
      S.dx(w) <> S.dy(w) <> S.dz(w) <> xperp(t, c)

def rvec(n: Nat, +i: F64, +j: F64) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m): S.fsin(F64.add(F64.mul(0.7f64, F64.mul(j, i)), F64.mul(0.3f64, i))) <> rvec(m, i, F64.add(j, 1.0f64))

def starts(k: Nat, +n: Nat, +i: F64, +mask: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match k:
    case 0n: []
    case 1n+(+m): F.hadam(mask, rvec(n, i, 1.0f64)) <> starts(m, n, F64.add(i, 1.0f64), mask)

def ext2(ps: List<&2, V.Point>, +p0: V.Point, +acc: F64) -> F64:
  match ps:
    case []: acc
    case +x <> +t:
      +v = S.psub(x, p0)
      ext2(t, p0, F64.max(acc, S.dot(v, v)))

def hd_p(ps: List<&2, V.Point>) -> V.Point:
  match ps:
    case []: org()
    case +x <> +t: x

def hzs(xs: List<&2, F64>, +sg: F64) -> List<&2, F64>:
  match xs:
    case []: []
    case +x <> +t: F64.div(F64.sqrt(F64.max(0.0f64, F64.sub(x, sg))), S.two_pi()) <> hzs(t, sg)

def last_f(xs: List<&2, F64>, +d: F64) -> F64:
  match xs:
    case []: d
    case +x <> +t: last_f(t, x)

def n_below(xs: List<&2, F64>, +t: F64, +n: Nat) -> Nat:
  match xs:
    case []: n
    case +x <> +r: n_below(r, t, Bool.pick(Nat, F64.is_le(x, t), Nat.add(n, 1n), n))

def drop_f(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: xs
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: drop_f(m, t)

def take_f(n: Nat, xs: List<&2, F64>) -> List<&2, F64>:
  match n:
    case 0n: []
    case 1n+(+m):
      match xs:
        case []: []
        case +x <> +t: x <> take_f(m, t)

type WS is Data:
  WS{ on: Bool, ps: List<&2, V.Point>, x: List<&2, List<&2, F64>>, h: F64 }

type LV is Data:
  LV{ ok: Bool, nn: Nat, ne: Nat, nc: Nat, held: Nat, rig: Nat, it: Nat, hz: List<&2, F64>, w: WS, res: F64 }

def ws_none() -> WS:
  WS{False{}, [], [], 1.0f64}

def lv_w(+l: LV) -> WS:
  LV{ok, nn, ne, nc, nh, rig, it, hz, +w, res} = l
  w

def x0_of(on: Bool, +ws: WS, +ps: List<&2, V.Point>, +kk: Nat, +n3: Nat, +mask: List<&2, F64>) -> List<&2, List<&2, F64>>:
  match on:
    case True{}:
      WS{o, +pc, +xc, +hc} = ws
      F.cmask(mask, W.prolong(pc, xc, ps, hc))
    case False{}: starts(kk, n3, 1.0f64, mask)

def ws_on(+ws: WS) -> Bool:
  WS{+on, ps, x, h} = ws
  on

def lv_si(+si: F.SI, +sg: F64, +k: Nat, +free: Bool, +ok: Bool, +nn: Nat, +ne: Nat, +nc: Nat, +nh: Nat, +ps: List<&2, V.Point>, +hl: F64) -> LV:
  F.SI{+x, +lam, +it, +res} = si
  +h = hzs(lam, sg)
  +rig = Bool.pick(Nat, free, n_below(h, F64.mul(1.0e-4f64, last_f(h, 0.0f64)), 0n), 0n)
  LV{ok, nn, ne, nc, nh, rig, it, take_f(k, drop_f(rig, h)), WS{True{}, ps, x, hl}, res}

def guard(+k: Nat) -> Nat:
  Nat.add(k, Nat.max(3n, Nat.div(k, 4n)))

def cl_d(+c: CL) -> V.Dir:
  CL{on, p, +d, r, pl} = c
  d

def sv_u(+sv: F.SV) -> List<&2, F64>:
  F.SV{+x, rz} = sv
  F.hd_l(x)

def pre_if(on: Bool, +fm: F.FM, +es: List<&2, F.EL>, +ps: List<&2, V.Point>, +mask: List<&2, F64>, +e: F64, +nu: F64, +c: CL, +w: F64) -> F.FM:
  match on:
    case True{}:
      +f = F.hadam(mask, F.scale(F64.mul(w, w), F.apply_op(fm, True{}, xperp(ps, c))))
      F.prestress(fm, es, sv_u(F.bsolve_tol(fm, mask, [f], 40000n, 1.0e-10f64)), e, nu, w, cl_d(c))
    case False{}: fm

def lv_go(+tm: K.TM, +ok: Bool, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS, +hl: F64) -> LV:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv} = tm
  +es = K.fe_els(ts, B.tb_of(V.Point, ps, org()), 1.0e-12f64)
  +free = Bool.not(cl_on(c))
  +sg = Bool.pick(F64, free, F64.div(F64.mul(0.1f64, F64.div(e, rho)), F64.max(ext2(ps, hd_p(ps), 0.0f64), 1.0e-300f64)), 0.0f64)
  +kw = Bool.pick(Nat, free, Nat.add(k, 6n), k)
  +kk = guard(kw)
  +mask = cl_mask(ps, c)
  +n3 = Nat.mul(nn, 3n)
  +fm = F.fm_sig(pre_if(F64.is_lt(0.0f64, w), F.fm_of(U32.from_nat(nn), es, e, nu, rho), es, ps, mask, e, nu, c, w), sg)
  lv_si(F.lobpcg(100n, fm, mask, kk, kw, 1.0e-6f64, x0_of(ws_on(ws), ws, ps, kk, n3, mask)), sg, k, free, ok, nn, List.length(&2, K.T10, ts), K.n_ec(es, 0n),
    n_held(ps, c, 0n), ps, hl)

def lv_tr(+t: K.TR, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS, +hl: F64) -> LV:
  K.TR{+ok, +tm} = t
  lv_go(tm, ok, e, nu, rho, c, k, w, ws, hl)

def lv_modes(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64, +ws: WS) -> LV:
  lv_tr(K.tm_of(fs, h), e, nu, rho, c, k, w, ws, h)

type EB is Data:
  EB{ v: F64, est: F64, bd: F64, mono: Bool }

def est3(+a: F64, +b: F64, +c: F64) -> EB:
  +q = F64.div(F64.sub(a, b), F64.sub(b, c))
  +mono = Bool.and(F64.is_lt(1.05f64, q), F64.is_eq(q, q))
  +est = Bool.pick(F64, mono, F64.add(c, F64.div(F64.sub(c, b), F64.sub(q, 1.0f64))), c)
  +bd = Bool.pick(F64, mono, F64.max(F64.abs(F64.sub(c, b)), F64.abs(F64.sub(est, c))),
    F64.mul(2.0f64, F64.max(F64.abs(F64.sub(a, b)), F64.abs(F64.sub(b, c)))))
  EB{c, est, bd, mono}

def eb_s(+x: EB) -> String:
  EB{+v, +est, +bd, +mono} = x
  " est=" ++ F64.show(est) ++ " bound=" ++ F64.show(bd) ++ " status=" ++ Bool.pick(String, mono, "estimated", "estimated-nonmonotone")

def mode_lines(as: List<&2, F64>, bs: List<&2, F64>, cs: List<&2, F64>, +i: Nat) -> String:
  match as:
    case []: ""
    case +a <> +at:
      match bs:
        case []: ""
        case +b <> +bt:
          match cs:
            case []: ""
            case +c <> +ct:
              "mode " ++ Nat.show(i) ++ " hz=[" ++ F64.show(a) ++ ", " ++ F64.show(b) ++ ", " ++ F64.show(c) ++ "]" ++ eb_s(est3(a, b, c)) ++ "\n" ++
                mode_lines(at, bt, ct, Nat.add(i, 1n))

def lv_hz(+l: LV) -> List<&2, F64>:
  LV{ok, nn, ne, nc, nh, rig, it, +hz, w, res} = l
  hz

def lv_ok(+l: LV) -> Bool:
  LV{+ok, nn, ne, nc, nh, rig, it, hz, w, res} = l
  ok

def lv_s(+l: LV, +h: F64) -> String:
  LV{ok, +nn, +ne, +nc, +nh, +rig, +it, hz, w, +res} = l
  "level h=" ++ F64.show(h) ++ " nodes=" ++ Nat.show(nn) ++ " tets=" ++ Nat.show(ne) ++ " curved=" ++ Nat.show(nc) ++ " held=" ++ Nat.show(nh) ++
    " rigid=" ++ Nat.show(rig) ++ " iters=" ++ Nat.show(it) ++ " residual=" ++ F64.show(res) ++ "\n"

def cbrt2() -> F64:
  1.2599210498948732f64

def modes3(+a: LV, +b: LV, +c: LV, +h: F64, +w: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  Bool.pick(String, Bool.and(lv_ok(a), Bool.and(lv_ok(b), lv_ok(c))),
    lv_s(a, h) ++ lv_s(b, h1) ++ lv_s(c, h2) ++ mode_lines(lv_hz(a), lv_hz(b), lv_hz(c), 1n) ++
      "method=T10 isosurface-stuffing mesh, block LOBPCG; bound from three levels h, h/2^(1/3), h/2^(2/3)" ++
        Bool.pick(String, F64.is_lt(0.0f64, w), "; prestressed at rpm=" ++ F64.show(F64.div(F64.mul(w, 60.0f64), 6.283185307179586f64)) ++
          " (stress stiffening from the linear centrifugal state and spin softening)", "") ++ "\n",
    "refused mesh-uncertified | modes | why: a lattice ray or edge cut did not certify against the faces | fix: change H slightly\n")

def modes_s(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +k: Nat, +w: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  +a = lv_modes(fs, h, e, nu, rho, c, k, w, ws_none())
  +b = lv_modes(fs, h1, e, nu, rho, c, k, w, lv_w(a))
  modes3(a, b, lv_modes(fs, h2, e, nu, rho, c, k, w, lv_w(b)), h, w)

type VC is Data:
  VC{ u: B.Tb<&2, F64>, lam: F64, mu: F64 }

def ud(+u: B.Tb<&2, F64>, +n: U32) -> V.Dir:
  +k = U32.mul(n, 3)
  S.dr(B.tb_get(F64, u, k), B.tb_get(F64, u, U32.add(k, 1)), B.tb_get(F64, u, U32.add(k, 2)))

def uds(ns: List<&2, U32>, +u: B.Tb<&2, F64>) -> List<&2, V.Dir>:
  match ns:
    case []: []
    case +n <> +t: ud(u, n) <> uds(t, u)

def gu(gs: List<&2, V.Dir>, us: List<&2, V.Dir>, +h: F.M9) -> F.M9:
  match gs:
    case []: h
    case +g <> +gt:
      match us:
        case []: h
        case +u <> +ut:
          +gx = S.dx(g)
          +gy = S.dy(g)
          +gz = S.dz(g)
          +ux = S.dx(u)
          +uy = S.dy(u)
          +uz = S.dz(u)
          gu(gt, ut, F.m9_add(h, F.M9{F64.mul(gx, ux), F64.mul(gx, uy), F64.mul(gx, uz), F64.mul(gy, ux), F64.mul(gy, uy), F64.mul(gy, uz),
            F64.mul(gz, ux), F64.mul(gz, uy), F64.mul(gz, uz)}))

def sq(+x: F64) -> F64:
  F64.mul(x, x)

def vm_of(+h: F.M9, +lam: F64, +mu: F64) -> F64:
  F.M9{+a, +b, +c, +d, +e, +f, +g, +hh, +i} = h
  +tr = F64.mul(lam, F64.add(F64.add(a, e), i))
  +m2 = F64.mul(2.0f64, mu)
  +sx = F64.add(tr, F64.mul(m2, a))
  +sy = F64.add(tr, F64.mul(m2, e))
  +sz = F64.add(tr, F64.mul(m2, i))
  +txy = F64.mul(mu, F64.add(b, d))
  +txz = F64.mul(mu, F64.add(c, g))
  +tyz = F64.mul(mu, F64.add(f, hh))
  F64.sqrt(F64.add(F64.mul(0.5f64, F64.add(F64.add(sq(F64.sub(sx, sy)), sq(F64.sub(sy, sz))), sq(F64.sub(sz, sx)))),
    F64.mul(3.0f64, F64.add(F64.add(sq(txy), sq(txz)), sq(tyz)))))

def vm_aff(qs: List<&2, List<&2, F64>>, +gl: List<&2, V.Dir>, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: F64) -> F64:
  match qs:
    case []: acc
    case +q <> +t: vm_aff(t, gl, us, lam, mu, F64.max(acc, vm_of(gu(F.grads(q, gl), us, F.m9z()), lam, mu)))

def vm_qg(+g: F.QG, +us: List<&2, V.Dir>, +lam: F64, +mu: F64) -> F64:
  F.QG{+gs, w} = g
  vm_of(gu(gs, us, F.m9z()), lam, mu)

def vm_cur(qs: List<&2, List<&2, F64>>, +ps: List<&2, V.Point>, +us: List<&2, V.Dir>, +lam: F64, +mu: F64, +acc: F64) -> F64:
  match qs:
    case []: acc
    case +q <> +t: vm_cur(t, ps, us, lam, mu, F64.max(acc, vm_qg(F.qg_of(ps, q), us, lam, mu)))

def el_vm_go(+c: VC, e: F.EL) -> F64:
  VC{+u, +lam, +mu} = c
  match e:
    case F.EL{+ns, +gl, +v}: vm_aff(F.gq(), gl, uds(ns, u), lam, mu, 0.0f64)
    case F.EC{+ns, +ps}: vm_cur(F.wq(), ps, uds(ns, u), lam, mu, 0.0f64)

def el_vm(c: VC, e: F.EL) -> F64:
  el_vm_go(c, e)

def fmax(xs: List<&2, F64>, +acc: F64) -> F64:
  match xs:
    case []: acc
    case +x <> +t: fmax(t, F64.max(acc, x))

type GR is Data:
  GR{ rmax: F64, tip: F64, gmax: F64 }

def grow(ps: List<&2, V.Point>, +i: U32, +u: B.Tb<&2, F64>, +c: CL, +g: GR) -> GR:
  match ps:
    case []: g
    case +x <> +t:
      GR{+rm, +tp, +gm} = g
      +w = perp(c, x)
      +r = F64.sqrt(S.dot(w, w))
      +gr = Bool.pick(F64, F64.is_lt(0.0f64, r), F64.div(S.dot(w, ud(u, i)), r), 0.0f64)
      +up = F64.is_lt(rm, r)
      grow(t, U32.add(i, 1), u, c, GR{Bool.pick(F64, up, r, rm), Bool.pick(F64, up, gr, tp), F64.max(gm, gr)})

type SP is Data:
  SP{ ok: Bool, nn: Nat, ne: Nat, nh: Nat, rz: F64, rmax: F64, tip: F64, gmax: F64, vm: F64, wk: F64 }

def hd_l(xs: List<&2, List<&2, F64>>) -> List<&2, F64>:
  match xs:
    case []: []
    case +h <> +t: h

def sp_gr(+g: GR, +ok: Bool, +nn: Nat, +ne: Nat, +nh: Nat, +rz: F64, +vm: F64, +wk: F64) -> SP:
  GR{+rm, +tp, +gm} = g
  SP{ok, nn, ne, nh, rz, rm, tp, gm, vm, wk}

def sp_sv(+sv: F.SV, +f: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64, +c: CL, +ok: Bool, +nn: Nat, +ne: Nat) -> SP:
  F.SV{+x, +rz} = sv
  +u = B.tb_of(F64, hd_l(x), 0.0f64)
  sp_gr(grow(ps, 0, u, c, GR{0.0f64, 0.0f64, 0.0f64}), ok, nn, ne, n_held(ps, c, 0n), rz,
    fmax(B.pmap_g(~F.EL, ~VC, ~F64, ~el_vm, 64, VC{u, lam, mu}, es), 0.0f64), F.dot_l(f, hd_l(x), 0.0f64))

def lame(+e: F64, +nu: F64) -> F64:
  F64.div(F64.mul(e, nu), F64.mul(F64.add(1.0f64, nu), F64.sub(1.0f64, F64.mul(2.0f64, nu))))

def shear(+e: F64, +nu: F64) -> F64:
  F64.div(e, F64.mul(2.0f64, F64.add(1.0f64, nu)))

def rig_n(ps: List<&2, V.Point>, +p0: V.Point, +k: Nat) -> List<&2, F64>:
  match ps:
    case []: []
    case +x <> +t:
      +r = S.psub(x, p0)
      +v = Bool.pick(V.Dir, Nat.is_eq(k, 0n), S.dr(1.0f64, 0.0f64, 0.0f64), Bool.pick(V.Dir, Nat.is_eq(k, 1n), S.dr(0.0f64, 1.0f64, 0.0f64),
        Bool.pick(V.Dir, Nat.is_eq(k, 2n), S.dr(0.0f64, 0.0f64, 1.0f64), Bool.pick(V.Dir, Nat.is_eq(k, 3n), S.cross(S.dr(1.0f64, 0.0f64, 0.0f64), r),
          Bool.pick(V.Dir, Nat.is_eq(k, 4n), S.cross(S.dr(0.0f64, 1.0f64, 0.0f64), r), S.cross(S.dr(0.0f64, 0.0f64, 1.0f64), r))))))
      S.dx(v) <> S.dy(v) <> S.dz(v) <> rig_n(t, p0, k)

def rigs(+ps: List<&2, V.Point>, +p0: V.Point) -> List<&2, List<&2, F64>>:
  [rig_n(ps, p0, 0n), rig_n(ps, p0, 1n), rig_n(ps, p0, 2n), rig_n(ps, p0, 3n), rig_n(ps, p0, 4n), rig_n(ps, p0, 5n)]

def coef(+v: List<&2, List<&2, F64>>, +d: List<&2, F64>, +b: List<&2, F64>, js: List<&2, Nat>, +acc: List<&2, F64>) -> List<&2, F64>:
  match js:
    case []: acc
    case +j <> +t:
      +vj = F.colj(v, j)
      coef(v, d, b, t, F.axpy(F64.div(F.dot_l(vj, b, 0.0f64), L.nth_f64(d, j)), vj, acc))

def acc_ja(j: F.JA, +b: List<&2, F64>) -> List<&2, F64>:
  F.JA{+a, +v} = j
  coef(v, F.diag_of(a, L.nat_range(6n)), b, L.nat_range(6n), [0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64])

def relieved(+fm: F.FM, +ps: List<&2, V.Point>, +f: List<&2, F64>, +p0: V.Point) -> List<&2, F64>:
  +r = rigs(ps, p0)
  +one = F.ones_l(Nat.mul(3n, List.length(&2, V.Point, ps)))
  +mr = F.blk_op(fm, one, True{}, r)
  F.axpy(F64.neg(1.0f64), F.hd_l(F.rcomb(mr, [acc_ja(F.jacobi(F.pgram(r, mr), 6n), F.gram_row(f, r))])), f)

def cl_p(+c: CL) -> V.Point:
  CL{on, +p, d, r, pl} = c
  p

def nrm(+xs: List<&2, F64>) -> F64:
  F64.sqrt(F.dot_l(xs, xs, 0.0f64))

def sp_free(on: Bool, +f: List<&2, F64>, +fm: F.FM, +ps: List<&2, V.Point>, +c: CL) -> List<&2, F64>:
  match on:
    case True{}: f
    case False{}: relieved(fm, ps, f, cl_p(c))

def sp_bal(ok: Bool, +f: List<&2, F64>, +fm: F.FM, +mask: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64, +c: CL,
    +nn: Nat, +ne: Nat) -> SP:
  match ok:
    case True{}: sp_sv(F.bsolve_tol(fm, mask, [f], 40000n, 1.0e-10f64), f, ps, es, lam, mu, c, True{}, nn, ne)
    case False{}: SP{False{}, nn, ne, 0n, F64.nan(), 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64}

def sp_rel(+f0: List<&2, F64>, +f: List<&2, F64>, +fm: F.FM, +mask: List<&2, F64>, +ps: List<&2, V.Point>, +es: List<&2, F.EL>, +lam: F64, +mu: F64,
    +c: CL, +nn: Nat, +ne: Nat) -> SP:
  sp_bal(F64.is_le(nrm(F.axpy(F64.neg(1.0f64), f, f0)), F64.mul(1.0e-3f64, nrm(f0))), f, fm, mask, ps, es, lam, mu, c, nn, ne)

def sp_ok2(+ok: Bool, +s: SP) -> SP:
  SP{+o2, +nn, +ne, +nh, +rz, +rm, +tp, +gm, +vm, +wk} = s
  SP{Bool.and(ok, o2), nn, ne, nh, rz, rm, tp, gm, vm, wk}

def sp_go(+tm: K.TM, +ok: Bool, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64) -> SP:
  K.TM{+ts, +ps, +nn, +nb, +nf, +dv} = tm
  +es = K.fe_els(ts, B.tb_of(V.Point, ps, org()), 1.0e-12f64)
  +mask = cl_mask(ps, c)
  +fm = F.fm_of(U32.from_nat(nn), es, e, nu, rho)
  +f = F.hadam(mask, F.scale(F64.mul(w, w), F.apply_op(fm, True{}, xperp(ps, c))))
  sp_ok2(ok, sp_rel(f, sp_free(cl_on(c), f, fm, ps, c), fm, mask, ps, es, lame(e, nu), shear(e, nu), c, nn, List.length(&2, K.T10, ts)))

def sp_tr(+t: K.TR, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64) -> SP:
  K.TR{+ok, +tm} = t
  sp_go(tm, ok, e, nu, rho, c, w)

def sp_lv(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64) -> SP:
  sp_tr(K.tm_of(fs, h), e, nu, rho, c, w)

def sp_ok(+s: SP) -> Bool:
  SP{+ok, nn, ne, nh, rz, rm, tp, gm, vm, wk} = s
  ok

def sp_tip(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, +tp, gm, vm, wk} = s
  tp

def sp_gm(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, +gm, vm, wk} = s
  gm

def sp_vm(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, gm, +vm, wk} = s
  vm

def sp_wk(+s: SP) -> F64:
  SP{ok, nn, ne, nh, rz, rm, tp, gm, vm, +wk} = s
  wk

def sp_s(+s: SP, +h: F64) -> String:
  SP{ok, +nn, +ne, +nh, +rz, +rm, +tp, +gm, +vm, wk} = s
  "level h=" ++ F64.show(h) ++ " nodes=" ++ Nat.show(nn) ++ " tets=" ++ Nat.show(ne) ++ " held=" ++ Nat.show(nh) ++ " rmax=" ++ F64.show(rm) ++
    " tip=" ++ F64.show(tp) ++ " growth_max=" ++ F64.show(gm) ++ " vm_max=" ++ F64.show(vm) ++ " pcg_rz=" ++ F64.show(rz) ++ "\n"

def q_line(+name: String, +a: F64, +b: F64, +c: F64) -> String:
  name ++ " [" ++ F64.show(a) ++ ", " ++ F64.show(b) ++ ", " ++ F64.show(c) ++ "]" ++ eb_s(est3(a, b, c)) ++ "\n"

def spin3(+a: SP, +b: SP, +c: SP, +h: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  Bool.pick(String, Bool.and(sp_ok(a), Bool.and(sp_ok(b), sp_ok(c))),
    sp_s(a, h) ++ sp_s(b, h1) ++ sp_s(c, h2) ++ q_line("tip_growth_mm", sp_tip(a), sp_tip(b), sp_tip(c)) ++
      q_line("max_growth_mm", sp_gm(a), sp_gm(b), sp_gm(c)) ++ q_line("max_von_mises_mpa", sp_vm(a), sp_vm(b), sp_vm(c)) ++
      q_line("work_nmm", sp_wk(a), sp_wk(b), sp_wk(c)) ++
      "method=T10 isosurface-stuffing mesh, clamped nodes within R of the axis, consistent centrifugal load, PCG; bound from three levels\n",
    "refused spin-unsupported | spin | why: the mesh did not certify, or R = 0 on a part whose centrifugal load is not self-equilibrated about the axis | fix: give a clamp radius R > 0 about the axis, or change H slightly\n")

def spin_s(+fs: List<&2, SO.Fd>, +h: F64, +e: F64, +nu: F64, +rho: F64, +c: CL, +w: F64) -> String:
  +h1 = F64.div(h, cbrt2())
  +h2 = F64.div(h1, cbrt2())
  spin3(sp_lv(fs, h, e, nu, rho, c, w), sp_lv(fs, h1, e, nu, rho, c, w), sp_lv(fs, h2, e, nu, rho, c, w), h)
