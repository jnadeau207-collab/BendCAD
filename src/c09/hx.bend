import Base
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/build.bend as BD
import ../k1/sf.bend as S
import ../base/par.bend as B
import ./feat.bend as F9

type Hr is Data:
  Hr{ code: U64, bt: BD.Bt }

def pd(+p: V.Point, +k: F64, +d: V.Dir) -> V.Point:
  V.Pt{F64.add(V.pt_x(p), F64.mul(k, V.dr_x(d))), F64.add(V.pt_y(p), F64.mul(k, V.dr_y(d))), F64.add(V.pt_z(p), F64.mul(k, V.dr_z(d)))}

def rad_pt(+o: V.Point, +u: V.Dir, +v: V.Dir, +r: F64, +t: F64) -> V.Point:
  pd(pd(o, F64.mul(r, S.fcos(t)), u), F64.mul(r, S.fsin(t)), v)

def hx_at(+h: G.Helicoid, +t: F64, +s: F64) -> V.Point:
  G.Hx{+o, +u, +v, +a, +c, +r0, +z0, +dr, +dz} = h
  pd(rad_pt(o, u, v, F64.add(r0, F64.mul(dr, s)), t), F64.add(F64.add(z0, F64.mul(dz, s)), F64.mul(c, t)), a)

def sh_at(+w: G.SpiralHelix, +t: F64) -> V.Point:
  G.Sh{+o, +u, +v, +a, +r0, +kr, +z0, +kz} = w
  pd(rad_pt(o, u, v, F64.add(r0, F64.mul(kr, t)), t), F64.add(z0, F64.mul(kz, t)), a)

def two_pi() -> F64:
  6.283185307179586f64

def t30() -> F64:
  0.5773502691896258f64

type Fp is Data:
  Fp{ r0: F64, dr: F64, z0: F64, dz: F64 }

type Tq is Data:
  Tq{ o: V.Point, u: V.Dir, v: V.Dir, a: V.Dir, c: F64, l: F64 }

def fp_r0(+f: Fp) -> F64:
  Fp{+r0, dr, z0, dz} = f
  r0

def fp_dr(+f: Fp) -> F64:
  Fp{r0, +dr, z0, dz} = f
  dr

def fp_z0(+f: Fp) -> F64:
  Fp{r0, dr, +z0, dz} = f
  z0

def fp_dz(+f: Fp) -> F64:
  Fp{r0, dr, z0, +dz} = f
  dz

def q_c(+q: Tq) -> F64:
  Tq{o, u, v, a, +c, l} = q
  c

def q_l(+q: Tq) -> F64:
  Tq{o, u, v, a, c, +l} = q
  l

def wb_of(+p: F64, +rb: F64, +rr: F64) -> F64:
  F64.add(F64.mul(0.125f64, p), F64.mul(2.0f64, F64.mul(F64.sub(rr, rb), t30())))

def fl_dz(+p: F64, +wb: F64) -> F64:
  F64.sub(F64.mul(0.5f64, wb), F64.mul(0.0625f64, p))

def fps4(+p: F64, +rb: F64, +rr: F64, +wb: F64) -> List<&2, Fp>:
  [Fp{rb, 0.0f64, F64.mul(0.5f64, wb), F64.sub(p, wb)}, Fp{rb, F64.sub(rr, rb), F64.mul(F64.neg(0.5f64), wb), fl_dz(p, wb)},
   Fp{rr, 0.0f64, F64.mul(F64.neg(0.0625f64), p), F64.mul(0.125f64, p)}, Fp{rr, F64.sub(rb, rr), F64.mul(0.0625f64, p), fl_dz(p, wb)}]

def fps_of(+p: F64, +rb: F64, +rr: F64) -> List<&2, Fp>:
  fps4(p, rb, rr, wb_of(p, rb, rr))

def wx_of(+p: F64, +rr: F64, +rc: F64) -> F64:
  F64.add(F64.mul(0.25f64, p), F64.mul(2.0f64, F64.mul(F64.sub(rc, rr), t30())))

def fpx4(+p: F64, +rr: F64, +rc: F64, +wo: F64) -> List<&2, Fp>:
  +fz = F64.mul(0.5f64, F64.sub(wo, F64.mul(0.25f64, p)))
  [Fp{rr, 0.0f64, F64.mul(F64.neg(0.125f64), p), F64.mul(0.25f64, p)}, Fp{rr, F64.sub(rc, rr), F64.mul(0.125f64, p), fz},
   Fp{rc, 0.0f64, F64.mul(0.5f64, wo), F64.sub(p, wo)}, Fp{rc, F64.sub(rr, rc), F64.sub(p, F64.mul(0.5f64, wo)), fz}]

def fps_x(+p: F64, +rr: F64, +rc: F64) -> List<&2, Fp>:
  fpx4(p, rr, rc, wx_of(p, rr, rc))

def fp_at(xs: List<&2, Fp>, +k: Nat) -> Fp:
  match xs:
    case []: Fp{0.0f64, 0.0f64, 0.0f64, 1.0f64}
    case +h <> +t:
      match k:
        case 0n: h
        case 1n+j: fp_at(t, j)

def nxt(+k: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(k, 3n), 0n, Nat.add(k, 1n))

def prv(+k: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(k, 0n), 3n, Nat.sub(k, 1n))

def th_c(+h: F64, +z: F64, +c: F64) -> F64:
  F64.div(F64.sub(h, z), c)

def hx_mk(+q: Tq, +f: Fp) -> G.Helicoid:
  Tq{+o, +u, +v, +a, +c, l} = q
  Fp{+r0, +dr, +z0, +dz} = f
  G.Hx{o, u, v, a, c, r0, z0, dr, dz}

def helix_mk(+q: Tq, +g: Fp) -> G.SpiralHelix:
  Tq{+o, +u, +v, +a, +c, l} = q
  G.Sh{o, u, v, a, fp_r0(g), 0.0f64, fp_z0(g), c}

def hdom_mk(+q: Tq, +g: Fp) -> G.Dom:
  G.Dom{th_c(0.0f64, fp_z0(g), q_c(q)), th_c(q_l(q), fp_z0(g), q_c(q))}

def end_r0(+r0: F64, +dr: F64, +z0: F64, +dz: F64, +h: F64) -> F64:
  F64.add(r0, F64.div(F64.mul(dr, F64.sub(h, z0)), dz))

def end_kr(+dr: F64, +dz: F64, +c: F64) -> F64:
  F64.neg(F64.div(F64.mul(dr, c), dz))

def end_mk(+q: Tq, +f: Fp, +h: F64) -> G.SpiralHelix:
  Tq{+o, +u, +v, +a, +c, l} = q
  Fp{+r0, +dr, +z0, +dz} = f
  G.Sh{o, u, v, a, end_r0(r0, dr, z0, dz, h), end_kr(dr, dz, c), h, 0.0f64}

def edom_mk(+q: Tq, +f: Fp, +h: F64) -> G.Dom:
  G.Dom{th_c(h, F64.add(fp_z0(f), fp_dz(f)), q_c(q)), th_c(h, fp_z0(f), q_c(q))}

def vtx_mk(+q: Tq, +g: Fp, +h: F64) -> V.Point:
  sh_at(helix_mk(q, g), th_c(h, fp_z0(g), q_c(q)))

def vx2(+q: Tq, +g: Fp) -> List<&2, Ty.Vertex>:
  [Ty.Vx{0u64, vtx_mk(q, g, 0.0f64)}, Ty.Vx{0u64, vtx_mk(q, g, q_l(q))}]

def new_vs(+q: Tq, +fs: List<&2, Fp>) -> List<&2, Ty.Vertex>:
  List.append(&2, Ty.Vertex, List.append(&2, Ty.Vertex, vx2(q, fp_at(fs, 1n)), vx2(q, fp_at(fs, 2n))),
    List.append(&2, Ty.Vertex, vx2(q, fp_at(fs, 3n)), vx2(q, fp_at(fs, 0n))))

def vi(+nv: Nat, +k: Nat, +top: Bool) -> Nat:
  Nat.add(nv, Nat.add(Nat.mul(2n, k), Bool.pick(Nat, top, 1n, 0n)))

def ed_sh(+i0: Nat, +i1: Nat, +w: G.SpiralHelix, +d: G.Dom) -> Ty.Edge:
  Ty.Ed{0u64, BD.hv(i0), BD.hv(i1), Ty.EK_curve{G.GV_sh{w}, d}}

def e_helix(+k: Nat, +nv: Nat, +q: Tq, +fs: List<&2, Fp>) -> Ty.Edge:
  ed_sh(vi(nv, k, False{}), vi(nv, k, True{}), helix_mk(q, fp_at(fs, nxt(k))), hdom_mk(q, fp_at(fs, nxt(k))))

def e_end2(+k: Nat, +top: Bool, +h: F64, +nv: Nat, +q: Tq, +f: Fp) -> Ty.Edge:
  ed_sh(vi(nv, k, top), vi(nv, prv(k), top), end_mk(q, f, h), edom_mk(q, f, h))

def e_end(+k: Nat, +top: Bool, +nv: Nat, +q: Tq, +fs: List<&2, Fp>) -> Ty.Edge:
  e_end2(k, top, Bool.pick(F64, top, q_l(q), 0.0f64), nv, q, fp_at(fs, k))

def es_hel(+nv: Nat, +q: Tq, +fs: List<&2, Fp>) -> List<&2, Ty.Edge>:
  [e_helix(0n, nv, q, fs), e_helix(1n, nv, q, fs), e_helix(2n, nv, q, fs), e_helix(3n, nv, q, fs)]

def es_end(+top: Bool, +nv: Nat, +q: Tq, +fs: List<&2, Fp>) -> List<&2, Ty.Edge>:
  [e_end(0n, top, nv, q, fs), e_end(1n, top, nv, q, fs), e_end(2n, top, nv, q, fs), e_end(3n, top, nv, q, fs)]

def new_es(+nv: Nat, +q: Tq, +fs: List<&2, Fp>) -> List<&2, Ty.Edge>:
  List.append(&2, Ty.Edge, es_hel(nv, q, fs), List.append(&2, Ty.Edge, es_end(False{}, nv, q, fs), es_end(True{}, nv, q, fs)))

def v2(+x: F64, +y: F64) -> V.Vec2:
  V.V2{x, y}

def us(+e: Nat, +f: Bool, +a: V.Vec2, +b: V.Vec2) -> BD.Use:
  BD.Us{e, f, a, b}

def th_loop4(+k: Nat, +ne: Nat, +pa: V.Vec2, +pb: V.Vec2, +pc: V.Vec2, +pdd: V.Vec2) -> List<&2, BD.Use>:
  [us(Nat.add(ne, Nat.add(4n, k)), False{}, pa, pdd), us(Nat.add(ne, k), True{}, pdd, pc),
   us(Nat.add(ne, Nat.add(8n, k)), True{}, pc, pb), us(Nat.add(ne, prv(k)), False{}, pb, pa)]

def th_loop2(+k: Nat, +ne: Nat, +z0: F64, +z1: F64, +c: F64, +l: F64) -> List<&2, BD.Use>:
  th_loop4(k, ne, v2(th_c(0.0f64, z0, c), 0.0f64), v2(th_c(l, z0, c), 0.0f64), v2(th_c(l, z1, c), 1.0f64), v2(th_c(0.0f64, z1, c), 1.0f64))

def th_loop(+k: Nat, +ne: Nat, +q: Tq, +f: Fp) -> List<&2, BD.Use>:
  th_loop2(k, ne, fp_z0(f), F64.add(fp_z0(f), fp_dz(f)), q_c(q), q_l(q))

def th_loop4r(+k: Nat, +ne: Nat, +pa: V.Vec2, +pb: V.Vec2, +pc: V.Vec2, +pdd: V.Vec2) -> List<&2, BD.Use>:
  [us(Nat.add(ne, prv(k)), True{}, pa, pb), us(Nat.add(ne, Nat.add(8n, k)), False{}, pb, pc),
   us(Nat.add(ne, k), False{}, pc, pdd), us(Nat.add(ne, Nat.add(4n, k)), True{}, pdd, pa)]

def th_loop2x(+k: Nat, +ne: Nat, +z0: F64, +z1: F64, +c: F64, +l: F64) -> List<&2, BD.Use>:
  th_loop4r(k, ne, v2(th_c(0.0f64, z0, c), 0.0f64), v2(th_c(l, z0, c), 0.0f64), v2(th_c(l, z1, c), 1.0f64), v2(th_c(0.0f64, z1, c), 1.0f64))

def th_loopx(+ext: Bool, +k: Nat, +ne: Nat, +q: Tq, +f: Fp) -> List<&2, BD.Use>:
  Bool.pick(List<&2, BD.Use>, ext, th_loop2x(k, ne, fp_z0(f), F64.add(fp_z0(f), fp_dz(f)), q_c(q), q_l(q)),
    th_loop2(k, ne, fp_z0(f), F64.add(fp_z0(f), fp_dz(f)), q_c(q), q_l(q)))

def th_fs(+k: Nat, +ne: Nat, +q: Tq, +f: Fp, +nm: BD.Fn, +ext: Bool) -> BD.FS:
  BD.FS{0n, G.GV_hx{hx_mk(q, f)}, ext, [th_loopx(ext, k, ne, q, f)], nm}

def z2() -> V.Vec2:
  v2(0.0f64, 0.0f64)

def ccw4(+e0: Nat, +ne: Nat) -> List<&2, BD.Use>:
  [us(Nat.add(ne, e0), True{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 3n)), True{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 2n)), True{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 1n)), True{}, z2(), z2())]

def cw4(+e0: Nat, +ne: Nat) -> List<&2, BD.Use>:
  [us(Nat.add(ne, e0), False{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 1n)), False{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 2n)), False{}, z2(), z2()), us(Nat.add(ne, Nat.add(e0, 3n)), False{}, z2(), z2())]

def end_loop(+e0: Nat, +ne: Nat, +ccw: Bool) -> List<&2, BD.Use>:
  Bool.pick(List<&2, BD.Use>, ccw, ccw4(e0, ne), cw4(e0, ne))

def trim_a(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{+a, b} = w
      a
    case _: v2(0.0f64, 0.0f64)

def trim_b(t: G.GVal) -> V.Vec2:
  match t:
    case G.GV_ts{w}:
      G.Ts{a, +b} = w
      b
    case _: v2(0.0f64, 0.0f64)

def ce_use(+c: Ty.Coedge) -> BD.Use:
  Ty.Ce{g, +h, +f, +tr} = c
  BD.Us{Ty.he_idx(h), f, trim_a(tr), trim_b(tr)}

def hcs_uses(hs: List<&2, Ty.HCoedge>, +tc: B.Tb<&2, Ty.Coedge>) -> List<&2, BD.Use>:
  match hs:
    case []: []
    case +h <> +t: ce_use(B.tb_get(Ty.Coedge, tc, U32.from_nat(Ty.hc_idx(h)))) <> hcs_uses(t, tc)

def hls_uses(hs: List<&2, Ty.HLoop>, +tl: B.Tb<&2, Ty.Loop>, +tc: B.Tb<&2, Ty.Coedge>) -> List<&2, List<&2, BD.Use>>:
  match hs:
    case []: []
    case +h <> +t: hcs_uses(Ty.lp_ces(B.tb_get(Ty.Loop, tl, U32.from_nat(Ty.hlp_idx(h)))), tc) <> hls_uses(t, tl, tc)

def tl_of(+br: Ty.Brep) -> B.Tb<&2, Ty.Loop>:
  B.tb_of(Ty.Loop, Ty.brep_lps(br), Ty.Lp{0u64, [], Ty.LK_outer{}})

def tc_of(+br: Ty.Brep) -> B.Tb<&2, Ty.Coedge>:
  B.tb_of(Ty.Coedge, Ty.brep_ces(br), Ty.Ce{0u64, Ty.HE{0n, 0u64}, True{}, G.GV_f{0.0f64}})

def us_has(xs: List<&2, BD.Use>, +e: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t:
      BD.Us{+x, f, a, b} = h
      Bool.or(Nat.is_eq(x, e), us_has(t, e))

def us_fwd(xs: List<&2, BD.Use>, +e: Nat) -> Bool:
  match xs:
    case []: True{}
    case +h <> +t:
      BD.Us{+x, +f, a, b} = h
      Bool.pick(Bool, Nat.is_eq(x, e), f, us_fwd(t, e))

def rm2(+x: Nat, +a: Nat, +b: Nat) -> Nat:
  Nat.sub(Nat.sub(x, Bool.pick(Nat, Nat.is_lt(a, x), 1n, 0n)), Bool.pick(Nat, Nat.is_lt(b, x), 1n, 0n))

def us_map(xs: List<&2, BD.Use>, +a: Nat, +b: Nat) -> List<&2, BD.Use>:
  match xs:
    case []: []
    case +h <> +t:
      BD.Us{+x, +f, +p, +q} = h
      BD.Us{rm2(x, a, b), f, p, q} <> us_map(t, a, b)

type Ce2 is Data:
  Ce2{ ea: Nat, eb: Nat, ca: Bool, cb: Bool }

def ce2_ea(+x: Ce2) -> Nat:
  Ce2{+ea, eb, ca, cb} = x
  ea

def ce2_eb(+x: Ce2) -> Nat:
  Ce2{ea, +eb, ca, cb} = x
  eb

def lp_new(+us0: List<&2, BD.Use>, +x: Ce2, +ne: Nat) -> List<&2, BD.Use>:
  Ce2{+ea, +eb, +ca, +cb} = x
  Bool.pick(List<&2, BD.Use>, us_has(us0, ea), end_loop(4n, ne, Bool.not(Bool.xor(us_fwd(us0, ea), ca))),
    Bool.pick(List<&2, BD.Use>, us_has(us0, eb), end_loop(8n, ne, Bool.not(Bool.xor(us_fwd(us0, eb), cb))), us_map(us0, ea, eb)))

def lps_new(ls: List<&2, List<&2, BD.Use>>, +x: Ce2, +ne: Nat) -> List<&2, List<&2, BD.Use>>:
  match ls:
    case []: []
    case +h <> +t: lp_new(h, x, ne) <> lps_new(t, x, ne)

def fa_fs(+f: Ty.Face, +n: BD.Fn, +x: Ce2, +ne: Nat, +tl: B.Tb<&2, Ty.Loop>, +tc: B.Tb<&2, Ty.Coedge>) -> BD.FS:
  Ty.Fa{g, +sf, +ls, +same, slv, sla} = f
  BD.FS{0n, sf, same, lps_new(hls_uses(ls, tl, tc), x, ne), n}

def fas_keep(fas: List<&2, Ty.Face>, fns: List<&2, BD.Fn>, +i: Nat, +fb: Nat, +x: Ce2, +ne: Nat,
    +tl: B.Tb<&2, Ty.Loop>, +tc: B.Tb<&2, Ty.Coedge>, +acc: List<&2, BD.FS>) -> List<&2, BD.FS>:
  match fas:
    case []: acc
    case +f <> +t:
      match fns:
        case []: acc
        case +n <> +u:
          +rest = fas_keep(t, u, Nat.add(i, 1n), fb, x, ne, tl, tc, acc)
          Bool.pick(List<&2, BD.FS>, Nat.is_eq(i, fb), rest, fa_fs(f, n, x, ne, tl, tc) <> rest)

def tol_keep(fas: List<&2, Ty.Face>, +i: Nat, +fb: Nat, +acc: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  match fas:
    case []: acc
    case +f <> +t:
      Ty.Fa{g, sf, ls, same, +slv, +sla} = f
      +rest = tol_keep(t, Nat.add(i, 1n), fb, acc)
      Bool.pick(List<&2, V.Vec2>, Nat.is_eq(i, fb), rest, V.V2{slv, sla} <> rest)

def fa_set(+f: Ty.Face, +w: V.Vec2) -> Ty.Face:
  Ty.Fa{+g, +sf, +ls, +same, slv, sla} = f
  Ty.Fa{g, sf, ls, same, V.v2_x(w), V.v2_y(w)}

def fa_tol(fas: List<&2, Ty.Face>, ts: List<&2, V.Vec2>) -> List<&2, Ty.Face>:
  match fas:
    case []: []
    case +f <> +t:
      match ts:
        case []: f <> fa_tol(t, [])
        case +w <> +u: fa_set(f, w) <> fa_tol(t, u)

def br_tol(+br: Ty.Brep, +ts: List<&2, V.Vec2>) -> Ty.Brep:
  Ty.Br{+vs, +es, +ces, +lps, +fas, +shs, +sos, +top, +st} = br
  Ty.Br{vs, es, ces, lps, fa_tol(fas, ts), shs, sos, top, st}

def es_keep(es: List<&2, Ty.Edge>, +i: Nat, +ea: Nat, +eb: Nat, +va: Nat, +vb: Nat) -> List<&2, Ty.Edge>:
  match es:
    case []: []
    case +e <> +t:
      Ty.Ed{+g, +v0, +v1, +k} = e
      +rest = es_keep(t, Nat.add(i, 1n), ea, eb, va, vb)
      Bool.pick(List<&2, Ty.Edge>, Bool.or(Nat.is_eq(i, ea), Nat.is_eq(i, eb)), rest,
        Ty.Ed{g, BD.hv(rm2(Ty.hv_idx(v0), va, vb)), BD.hv(rm2(Ty.hv_idx(v1), va, vb)), k} <> rest)

def vs_keep(vs: List<&2, Ty.Vertex>, +i: Nat, +va: Nat, +vb: Nat) -> List<&2, Ty.Vertex>:
  match vs:
    case []: []
    case +v <> +t:
      +rest = vs_keep(t, Nat.add(i, 1n), va, vb)
      Bool.pick(List<&2, Ty.Vertex>, Bool.or(Nat.is_eq(i, va), Nat.is_eq(i, vb)), rest, v <> rest)

def cat_v(xs: List<&2, Ty.Vertex>, +ys: List<&2, Ty.Vertex>) -> List<&2, Ty.Vertex>:
  match xs:
    case []: ys
    case +h <> +t: h <> cat_v(t, ys)

def cat_e(xs: List<&2, Ty.Edge>, +ys: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match xs:
    case []: ys
    case +h <> +t: h <> cat_e(t, ys)

def cat_f(xs: List<&2, BD.FS>, +ys: List<&2, BD.FS>) -> List<&2, BD.FS>:
  match xs:
    case []: ys
    case +h <> +t: h <> cat_f(t, ys)

def tols_th(+ts: List<&2, V.Vec2>) -> List<&2, V.Vec2>:
  +z = {V.V2{0.0f64, 0.0f64} : V.Vec2}
  List.append(&2, V.Vec2, ts, [z, z, z, z])

def bt_tol(+bt: BD.Bt, +ts: List<&2, V.Vec2>) -> BD.Bt:
  BD.Bt{+br, +fns} = bt
  BD.Bt{br_tol(br, ts), fns}

def fn_j(+n: BD.Fn, +k: Nat) -> BD.Fn:
  BD.Fn{+nd, +c, +r, +i, +j} = n
  BD.Fn{nd, c, r, i, Nat.add(j, k)}

def ths4(+ne: Nat, +q: Tq, +fs: List<&2, Fp>, +nm: BD.Fn, +ext: Bool) -> List<&2, BD.FS>:
  [th_fs(0n, ne, q, fp_at(fs, 0n), fn_j(nm, 0n), ext), th_fs(1n, ne, q, fp_at(fs, 1n), fn_j(nm, 1n), ext),
   th_fs(2n, ne, q, fp_at(fs, 2n), fn_j(nm, 2n), ext), th_fs(3n, ne, q, fp_at(fs, 3n), fn_j(nm, 3n), ext)]

def thread_go(+br: Ty.Brep, +fns: List<&2, BD.Fn>, +fb: Nat, +x: Ce2, +q: Tq, +fs: List<&2, Fp>,
    +nm: BD.Fn, +ext: Bool, +vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>) -> BD.Bt:
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  bt_tol(F9.pack(cat_v(vs, new_vs(q, fs)), cat_e(es, new_es(nv, q, fs)), cat_f(fas_keep(Ty.brep_fas(br), fns, 0n, fb, x, ne, tl_of(br), tc_of(br), []), ths4(ne, q, fs, nm, ext))),
    tols_th(tol_keep(Ty.brep_fas(br), 0n, fb, [])))

def thread_bt(+br: Ty.Brep, +fns: List<&2, BD.Fn>, +fb: Nat, +x: Ce2, +va: Nat, +vb: Nat, +q: Tq, +fs: List<&2, Fp>,
    +nm: BD.Fn, +ext: Bool) -> BD.Bt:
  thread_go(br, fns, fb, x, q, fs, nm, ext, vs_keep(Ty.brep_vs(br), 0n, va, vb), es_keep(Ty.brep_es(br), 0n, ce2_ea(x), ce2_eb(x), va, vb))
