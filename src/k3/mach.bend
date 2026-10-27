import Base
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c06/model.bend as M
import ../c06/sx.bend as S2
import ../c07/sol.bend as SO
import ../c08/bool.bend as B8
import ../c07/emb.bend as EM
import ../k1/fb.bend as FB
import ../k1/sf.bend as S
import ../k1/ls.bend as L
import ../k1/ef.bend as EF
import ../k1/vi.bend as VI
import ../base/par.bend as B

type TL is Data:
  TL{ r: F64, fl: F64, hr: F64, hl: F64 }

type TB is Data:
  TB{ ball: Ty.Brep, cut: Ty.Brep, hold: Ty.Brep }

def tl_r(+t: TL) -> F64:
  TL{+r, fl, hr, hl} = t
  r

def tl_fl(+t: TL) -> F64:
  TL{r, +fl, hr, hl} = t
  fl

def tl_hr(+t: TL) -> F64:
  TL{r, fl, +hr, hl} = t
  hr

def tl_hl(+t: TL) -> F64:
  TL{r, fl, hr, +hl} = t
  hl

def tb_ball(+t: TB) -> Ty.Brep:
  TB{+ball, cut, hold} = t
  ball

def tb_cut(+t: TB) -> Ty.Brep:
  TB{ball, +cut, hold} = t
  cut

def tb_hold(+t: TB) -> Ty.Brep:
  TB{ball, cut, +hold} = t
  hold

def ic() -> String:
  " (intent create any any any any))\n"

def tool_src(+t: TL) -> String:
  "(bendcad 1)\n(node 1 (sphere " ++ F64.show(tl_r(t)) ++ ")" ++ ic() ++ "(node 2 (cylinder " ++ F64.show(tl_r(t)) ++ " " ++
    F64.show(tl_fl(t)) ++ ")" ++ ic() ++ "(node 3 (cylinder " ++ F64.show(tl_hr(t)) ++ " " ++ F64.show(tl_hl(t)) ++ ")" ++ ic()

def brep_of(cs: List<&2, M.CE>, +id: U64) -> Ty.Brep:
  M.bd_brep(M.nr_body(M.ce_r(M.ce_find(cs, id))))

def tool_bs(+t: TL) -> TB:
  +cs = M.ev_part(S2.part_of(S2.ps_xs(S2.parse(tool_src(t)))), [])
  TB{brep_of(cs, 1u64), brep_of(cs, 2u64), brep_of(cs, 3u64)}

def frame(+d: V.Dir) -> V.Mat3:
  +a = Bool.pick(V.Dir, F64.is_lt(F64.abs(S.dz(d)), 0.9f64), S.dr(0.0f64, 0.0f64, 1.0f64), S.dr(1.0f64, 0.0f64, 0.0f64))
  +u = S.dunit(S.cross(a, d))
  +v = S.cross(d, u)
  V.M3{S.dx(u), S.dx(v), S.dx(d), S.dy(u), S.dy(v), S.dy(d), S.dz(u), S.dz(v), S.dz(d)}

def place(+b: Ty.Brep, +d: V.Dir, +c: V.Point) -> Ty.Brep:
  B8.xf_brep(frame(d), V.pt_x(c), V.pt_y(c), V.pt_z(c), b)

def worst(+a: U64, +b: U64) -> U64:
  Bool.pick(U64, Bool.or(U64.is_eq(a, 1u64), U64.is_eq(b, 1u64)), 1u64, U64.max(a, b))

def cl_fs(fs: List<&2, SO.Fi>, +acc: U64) -> U64:
  match fs:
    case []: acc
    case +f <> +t:
      SO.Fi{+c, a, b} = f
      cl_fs(t, worst(acc, Bool.pick(U64, B8.is_uncertain_code(c), 2u64, 1u64)))

def cls(+c: U64) -> U64:
  Bool.pick(U64, U64.is_eq(c, 0u64), 0u64, Bool.pick(U64, Bool.or(U64.is_eq(c, 1u64), U64.is_eq(c, 3u64)), 1u64, 2u64))

def clr_go(c: U64, +fp: List<&2, SO.Fd>, +t: Ty.Brep, +tp: V.Point, +pp: V.Point) -> U64:
  match c:
    case 0u64: worst(cls(SO.classify(fp, tp)), cls(SO.classify(SO.fds_of(t), pp)))
    case _: c

def clr(+p: Ty.Brep, +fp: List<&2, SO.Fd>, +t: Ty.Brep, +tp: V.Point, +pp: V.Point) -> U64:
  +bc = B8.brep_append(p, t)
  clr_go(cl_fs(EM.emb_cross(bc, SO.fds_of(bc)), 0u64), fp, t, tp, pp)

type PC is Data:
  PC{ b: Ty.Brep, k: FB.KB, fs: List<&2, SO.Fd>, pp: V.Point }

def pc_k(+x: PC) -> FB.KB:
  PC{b, +k, fs, pp} = x
  k

def pc_b(+x: PC) -> Ty.Brep:
  PC{+b, k, fs, pp} = x
  b

def pc_fs(+x: PC) -> List<&2, SO.Fd>:
  PC{b, k, +fs, pp} = x
  fs

def pc_pp(+x: PC) -> V.Point:
  PC{b, k, fs, +pp} = x
  pp

def hold_go(c: U64, +pc: PC, +tb: TB, +t: TL, +d: V.Dir, +ch: V.Point) -> U64:
  match c:
    case 0u64: clr(pc_b(pc), pc_fs(pc), place(tb_hold(tb), d, ch), S.padd(ch, F64.mul(0.5f64, tl_hl(t)), d), pc_pp(pc))
    case _: c

def cut_go(c: U64, +pc: PC, +tb: TB, +t: TL, +d: V.Dir, +cc: V.Point) -> U64:
  match c:
    case 0u64:
      +ch = S.padd(cc, tl_fl(t), d)
      hold_go(clr(pc_b(pc), pc_fs(pc), place(tb_cut(tb), d, cc), S.padd(cc, F64.mul(0.5f64, tl_fl(t)), d), pc_pp(pc)), pc, tb, t, d, ch)
    case _: c

def tool_at(+pc: PC, +tb: TB, +t: TL, +p: V.Point, +n: V.Dir, +d: V.Dir, +gap: F64) -> U64:
  +cc = S.padd(p, F64.add(tl_r(t), gap), n)
  cut_go(clr(pc_b(pc), pc_fs(pc), place(tb_ball(tb), d, cc), cc, pc_pp(pc)), pc, tb, t, d, cc)

type RC is Data:
  RC{ code: U64, d: V.Dir }

def rc_code(+x: RC) -> U64:
  RC{+code, d} = x
  code

def rc_d(+x: RC) -> V.Dir:
  RC{code, +d} = x
  d

def rc_next(+c: U64, +d: V.Dir, +acc: RC) -> RC:
  Bool.pick(RC, U64.is_eq(c, 0u64), RC{0u64, d}, Bool.pick(RC, U64.is_eq(c, 2u64), RC{2u64, d}, acc))

def dir_code(back: Bool, +pc: PC, +tb: TB, +t: TL, +p: V.Point, +n: V.Dir, +d: V.Dir, +gap: F64) -> U64:
  match back:
    case True{}: 1u64
    case False{}: tool_at(pc, tb, t, p, n, d, gap)

def try_dirs(ds: List<&2, V.Dir>, done: Bool, +pc: PC, +tb: TB, +t: TL, +p: V.Point, +n: V.Dir, +gap: F64, +acc: RC) -> RC:
  match ds:
    case []: acc
    case +d <> +rest:
      match done:
        case True{}: acc
        case False{}:
          +c = dir_code(F64.is_lt(S.dot(d, n), F64.neg(1.0e-9f64)), pc, tb, t, p, n, d, gap)
          try_dirs(rest, U64.is_eq(c, 0u64), pc, tb, t, p, n, gap, rc_next(c, d, acc))

def zup() -> V.Dir:
  S.dr(0.0f64, 0.0f64, 1.0f64)

def dirs_of(+five: Bool, +n: V.Dir) -> List<&2, V.Dir>:
  +z = zup()
  +nz = S.dadd(n, 1.0f64, z)
  +tilt = Bool.pick(List<&2, V.Dir>, F64.is_lt(1.0e-6f64, S.dlen(nz)), [S.dunit(nz)], [])
  Bool.pick(List<&2, V.Dir>, five, List.append(&2, V.Dir, n <> tilt, [z]), [z])

type SP is Data:
  SP{ p: V.Point, n: V.Dir }

type UV is Data:
  UV{ u0: F64, u1: F64, v0: F64, v1: F64 }

def bb2_go(ps: List<&2, V.Vec2>, +acc: UV) -> UV:
  match ps:
    case []: acc
    case +q <> +t:
      UV{+u0, +u1, +v0, +v1} = acc
      bb2_go(t, UV{F64.min(u0, V.v2_x(q)), F64.max(u1, V.v2_x(q)), F64.min(v0, V.v2_y(q)), F64.max(v1, V.v2_y(q))})

def bb_polys(ls: List<&2, List<&2, V.Vec2>>, +acc: UV) -> UV:
  match ls:
    case []: acc
    case +h <> +t: bb_polys(t, bb2_go(h, acc))

def at(+a: F64, +b: F64, +k: Nat, +ns: F64) -> F64:
  F64.add(a, F64.mul(F64.div(F64.add(L.f64_of(k), 0.5f64), ns), F64.sub(b, a)))

def out_n(+b: FB.KB, +fi: Nat, +s: S.SF, +p: V.Point) -> V.Dir:
  +g = S.sf_normal(s, p)
  Bool.pick(V.Dir, FB.face_same(b, fi), g, S.dscale(F64.neg(1.0f64), g))

def grid_v(js: List<&2, Nat>, +u: F64, +v0: F64, +v1: F64, +ns: F64, +b: FB.KB, +fi: Nat, +s: S.SF) -> List<&2, SP>:
  match js:
    case []: []
    case +j <> +t:
      +p = S.sf_at(s, u, at(v0, v1, j, ns))
      +rest = grid_v(t, u, v0, v1, ns, b, fi, s)
      Bool.pick(List<&2, SP>, FB.pt_in_face(b, fi, p), SP{p, out_n(b, fi, s, p)} <> rest, rest)

def grid_u(ix: List<&2, Nat>, +bx: UV, +n: Nat, +b: FB.KB, +fi: Nat, +s: S.SF) -> List<&2, SP>:
  match ix:
    case []: []
    case +i <> +t:
      UV{+u0, +u1, +v0, +v1} = bx
      +ns = L.f64_of(n)
      List.append(&2, SP, grid_v(L.nat_range(n), at(u0, u1, i, ns), v0, v1, ns, b, fi, s), grid_u(t, bx, n, b, fi, s))

def samples(+b: FB.KB, +fi: Nat, +n: Nat) -> List<&2, SP>:
  +big = {1.0e300f64 : F64}
  grid_u(L.nat_range(n), bb_polys(FB.face_polys(b, fi), UV{big, F64.neg(big), big, F64.neg(big)}), n, b, fi, FB.face_sf(b, fi))

type FR is Data:
  FR{ n: Nat, ok: Nat, unc: Nat, bad: List<&2, V.Point>, um: List<&2, V.Point> }

def fr_add(+r: FR, +c: U64, +p: V.Point) -> FR:
  FR{+n, +ok, +unc, +bad, +um} = r
  FR{Nat.add(n, 1n), Bool.pick(Nat, U64.is_eq(c, 0u64), Nat.add(ok, 1n), ok), Bool.pick(Nat, U64.is_eq(c, 2u64), Nat.add(unc, 1n), unc),
    Bool.pick(List<&2, V.Point>, U64.is_eq(c, 1u64), p <> bad, bad), Bool.pick(List<&2, V.Point>, U64.is_eq(c, 2u64), p <> um, um)}

def reach_ps(ps: List<&2, SP>, +five: Bool, +pc: PC, +tb: TB, +t: TL, +gap: F64, +acc: FR) -> FR:
  match ps:
    case []: acc
    case +q <> +rest:
      SP{+p, +n} = q
      +r = try_dirs(dirs_of(five, n), False{}, pc, tb, t, p, n, gap, RC{1u64, n})
      reach_ps(rest, five, pc, tb, t, gap, fr_add(acc, rc_code(r), p))

def concave_r(+s: S.SF, ps: List<&2, SP>) -> F64:
  match ps:
    case []: 1.0e300f64
    case +q <> rest:
      SP{+p, +n} = q
      +o = S.sf_o(s)
      +a = S.sf_a(s)
      +d = S.psub(p, o)
      +rad = S.dadd(d, F64.neg(S.dot(d, a)), a)
      +rl = S.dlen(rad)
      +ru = S.dscale(F64.div(1.0f64, F64.max(rl, 1.0e-300f64)), rad)
      +tc = S.padd(o, S.sf_r(s), ru)
      +kd = S.sf_kind(s)
      +inward = F64.is_lt(S.dot(n, Bool.pick(V.Dir, S.is_tor(s), S.psub(p, tc), Bool.pick(V.Dir, S.is_sph(s), d, rad))), 0.0f64)
      +r = Bool.pick(F64, S.is_tor(s), S.sf_r2(s), S.sf_r(s))
      Bool.pick(F64, Bool.and(inward, Bool.or(Bool.or(U64.is_eq(kd, S.k_cyl()), S.is_sph(s)), S.is_tor(s))), r, 1.0e300f64)

type FO is Data:
  FO{ s: String, ok: Nat, n: Nat, unc: Nat, tight: Nat }

def pt_s(+p: V.Point) -> String:
  "(" ++ F64.show(V.pt_x(p)) ++ "," ++ F64.show(V.pt_y(p)) ++ "," ++ F64.show(V.pt_z(p)) ++ ")"

def bad_s(ps: List<&2, V.Point>, +w: String) -> String:
  match ps:
    case []: ""
    case +p <> +t: " " ++ w ++ "=" ++ pt_s(p)

def fo_of(+fi: Nat, +rr: F64, +tight: Bool, r: FR) -> FO:
  FR{+n, +ok, +unc, +bad, +um} = r
  FO{"face " ++ Nat.show(fi) ++ " reach=" ++ Nat.show(ok) ++ "/" ++ Nat.show(n) ++ Bool.pick(String, Nat.is_eq(unc, 0n), "", " uncertain=" ++ Nat.show(unc)) ++
      Bool.pick(String, tight, " concave-radius=" ++ F64.show(rr) ++ " below-tool-radius", "") ++ bad_s(bad, "blocked") ++ bad_s(um, "uncertain-at") ++ "\n",
    ok, n, unc, Bool.pick(Nat, tight, 1n, 0n)}

def face_one(+pc: PC, +tb: TB, +t: TL, +five: Bool, +ns: Nat, +gap: F64, +fi: Nat) -> FO:
  +b = pc_k(pc)
  +ps = samples(b, fi, ns)
  +rr = concave_r(FB.face_sf(b, fi), ps)
  fo_of(fi, rr, F64.is_lt(rr, F64.mul(tl_r(t), F64.sub(1.0f64, 1.0e-9f64))), reach_ps(ps, five, pc, tb, t, gap, FR{0n, 0n, 0n, [], []}))

type MC is Data:
  MC{ pc: PC, tb: TB, t: TL, five: Bool, ns: Nat, gap: F64 }

def face_f(c: MC, fi: Nat) -> FO:
  MC{+pc, +tb, +t, +five, +ns, +gap} = c
  face_one(pc, tb, t, five, ns, gap, fi)

type SE is Data:
  SE{ n: Nat, es: List<&2, Nat> }

def sharp_go2(+b: FB.KB, +e: Nat, +k: Ty.EdgeKind) -> Bool:
  +fs = FB.edge_faces(b, e)
  +f1 = L.nth_n(fs, 0n)
  +f2 = L.nth_n(fs, 1n)
  +g = EF.ek_curve(k)
  +tm = F64.mul(0.5f64, F64.add(EF.ek_lo(k), EF.ek_hi(k)))
  +m = EF.ev(g, tm)
  +s1 = FB.face_sf(b, f1)
  +s2 = FB.face_sf(b, f2)
  +n1 = out_n(b, f1, s1, m)
  +n2 = out_n(b, f2, s2, m)
  +t = S.dunit(VI.cv_der(g, tm))
  +w0 = S.cross(n2, t)
  +eps = F64.mul(1.0e-4f64, F64.add(1.0f64, S.dlen(S.psub(m, S.pt(0.0f64, 0.0f64, 0.0f64)))))
  +w = Bool.pick(V.Dir, FB.pt_in_face(b, f2, S.padd(m, eps, w0)), w0, S.dscale(F64.neg(1.0f64), w0))
  Bool.and(Nat.is_lt(1n, List.length(&2, Nat, fs)), Bool.and(F64.is_lt(S.dot(n1, n2), F64.sub(1.0f64, 1.0e-6f64)), F64.is_lt(1.0e-9f64, S.dot(n1, w))))

def sharp_k(deg: Bool, +b: FB.KB, +e: Nat, +k: Ty.EdgeKind) -> Bool:
  match deg:
    case True{}: False{}
    case False{}: sharp_go2(b, e, k)

def sharp_e(+b: FB.KB, +e: Nat) -> Bool:
  +k = Ty.ed_kind(FB.edge_at(b, e))
  sharp_k(U64.is_eq(VI.ek_tag(k), 0u64), b, e, k)

def sharp_go(es: List<&2, Nat>, +b: FB.KB, +acc: SE) -> SE:
  match es:
    case []: acc
    case +e <> +t:
      SE{+n, +xs} = acc
      sharp_go(t, b, Bool.pick(SE, sharp_e(b, e), SE{Nat.add(n, 1n), e <> xs}, acc))

def es_s(es: List<&2, Nat>) -> String:
  match es:
    case []: ""
    case +e <> +t: "edge " ++ Nat.show(e) ++ " sharp-concave radius=0\n" ++ es_s(t)

type AG is Data:
  AG{ s: String, ok: Nat, n: Nat, unc: Nat, tight: Nat }

def ag_go(fs: List<&2, FO>, +acc: AG) -> AG:
  match fs:
    case []: acc
    case +f <> +t:
      FO{+s, +ok, +n, +unc, +tight} = f
      AG{+s0, +ok0, +n0, +unc0, +tight0} = acc
      ag_go(t, AG{s0 ++ s, Nat.add(ok0, ok), Nat.add(n0, n), Nat.add(unc0, unc), Nat.add(tight0, tight)})

def verdict(+ok: Nat, +n: Nat, +unc: Nat, +tight: Nat, +sharp: Nat) -> String:
  +good = Bool.and(Nat.is_eq(ok, n), Nat.is_eq(Nat.add(tight, sharp), 0n))
  +blocked = Nat.sub(Nat.sub(n, ok), unc)
  +word = Bool.pick(String, good, "machinable", Bool.pick(String, Bool.and(Nat.is_eq(blocked, 0n), Nat.is_eq(Nat.add(tight, sharp), 0n)), "uncertain", "not-machinable"))
  "verdict " ++ word ++ " samples=" ++ Nat.show(n) ++ " reachable=" ++ Nat.show(ok) ++ " blocked=" ++ Nat.show(blocked) ++ " uncertain=" ++
    Nat.show(unc) ++ " tight-faces=" ++ Nat.show(tight) ++ " sharp-concave-edges=" ++ Nat.show(sharp) ++
    Bool.pick(String, Nat.is_eq(unc, 0n), " status=certified", " status=estimated") ++ "\n"

def first_pt(vs: List<&2, Ty.Vertex>) -> V.Point:
  match vs:
    case []: S.pt(0.0f64, 0.0f64, 0.0f64)
    case +v <> t: Ty.vx_p(v)

def mach_s(+t: TL, +five: Bool, +ns: Nat, +gap: F64, a: AG, se: SE) -> String:
  AG{+s, +ok, +n, +unc, +tight} = a
  SE{+nsh, +es} = se
  "machine tool=ball r=" ++ F64.show(tl_r(t)) ++ " flute=" ++ F64.show(tl_fl(t)) ++ " holder-r=" ++ F64.show(tl_hr(t)) ++ " holder-l=" ++
    F64.show(tl_hl(t)) ++ " axes=" ++ Bool.pick(String, five, "5", "3") ++ " samples-per-side=" ++ Nat.show(ns) ++ " gap=" ++ F64.show(gap) ++ "\n" ++
    s ++ es_s(es) ++ verdict(ok, n, unc, tight, nsh)

def machine(+b: Ty.Brep, +t: TL, +five: Bool, +ns: Nat) -> String:
  +k = FB.kb_of(b)
  +pc = {PC{b, k, SO.fds_of(b), first_pt(Ty.brep_vs(b))} : PC}
  +gap = F64.mul(0.01f64, tl_r(t))
  +tb = tool_bs(t)
  +mc = {MC{pc, tb, t, five, ns, gap} : MC}
  +fos = B.pmap_g(~Nat, ~MC, ~FO, ~face_f, 1, mc, L.nat_range(FB.nfaces(k)))
  mach_s(t, five, ns, gap, ag_go(fos, AG{"", 0n, 0n, 0n, 0n}), sharp_go(L.nat_range(FB.nedges(k)), k, SE{0n, []}))
