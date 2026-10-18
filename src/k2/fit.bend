import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c06/build.bend as BD
import ../c06/sx.bend as S
import ../k1/fb.bend as FB
import ./mat.bend as KM
import ./thr.bend as KT

type FC is Data:
  FC{ ok: Bool, hl: String, hg: Nat, sl: String, sg: Nat }

type FE is Data:
  FE{ name: String, a: U64, hs: String, b: U64, ss: String, cls: String, kind: String }

type TE is Data:
  TE{ name: String, t: F64 }

def tops() -> List<&2, F64>:
  [3.0f64, 6.0f64, 10.0f64, 18.0f64, 30.0f64, 50.0f64, 80.0f64, 120.0f64, 180.0f64, 250.0f64, 315.0f64, 400.0f64, 500.0f64]

def subtops() -> List<&2, F64>:
  [3.0f64, 6.0f64, 10.0f64, 18.0f64, 30.0f64, 50.0f64, 65.0f64, 80.0f64, 100.0f64, 120.0f64, 140.0f64, 160.0f64, 180.0f64,
   200.0f64, 225.0f64, 250.0f64, 280.0f64, 315.0f64, 355.0f64, 400.0f64, 450.0f64, 500.0f64]

def rng_go(ts: List<&2, F64>, +d: F64, +i: Nat) -> Nat:
  match ts:
    case []: i
    case +h <> +t: Bool.pick(Nat, F64.is_le(d, h), i, rng_go(t, d, Nat.add(i, 1n)))

def it_tab(+g: Nat) -> List<&2, F64>:
  match g:
    case 5n: [4.0f64, 5.0f64, 6.0f64, 8.0f64, 9.0f64, 11.0f64, 13.0f64, 15.0f64, 18.0f64, 20.0f64, 23.0f64, 25.0f64, 27.0f64]
    case 6n: [6.0f64, 8.0f64, 9.0f64, 11.0f64, 13.0f64, 16.0f64, 19.0f64, 22.0f64, 25.0f64, 29.0f64, 32.0f64, 36.0f64, 40.0f64]
    case 7n: [10.0f64, 12.0f64, 15.0f64, 18.0f64, 21.0f64, 25.0f64, 30.0f64, 35.0f64, 40.0f64, 46.0f64, 52.0f64, 57.0f64, 63.0f64]
    case 8n: [14.0f64, 18.0f64, 22.0f64, 27.0f64, 33.0f64, 39.0f64, 46.0f64, 54.0f64, 63.0f64, 72.0f64, 81.0f64, 89.0f64, 97.0f64]
    case 9n: [25.0f64, 30.0f64, 36.0f64, 43.0f64, 52.0f64, 62.0f64, 74.0f64, 87.0f64, 100.0f64, 115.0f64, 130.0f64, 140.0f64, 155.0f64]
    case 10n: [40.0f64, 48.0f64, 58.0f64, 70.0f64, 84.0f64, 100.0f64, 120.0f64, 140.0f64, 160.0f64, 185.0f64, 210.0f64, 230.0f64, 250.0f64]
    case 11n: [60.0f64, 75.0f64, 90.0f64, 110.0f64, 130.0f64, 160.0f64, 190.0f64, 220.0f64, 250.0f64, 290.0f64, 320.0f64, 360.0f64, 400.0f64]
    case _: []

def es_up(+l: String) -> List<&2, F64>:
  Bool.pick(List<&2, F64>, String.eq(l, "d"), [20.0f64, 30.0f64, 40.0f64, 50.0f64, 65.0f64, 80.0f64, 100.0f64, 120.0f64, 145.0f64, 170.0f64, 190.0f64, 210.0f64, 230.0f64],
    Bool.pick(List<&2, F64>, String.eq(l, "e"), [14.0f64, 20.0f64, 25.0f64, 32.0f64, 40.0f64, 50.0f64, 60.0f64, 72.0f64, 85.0f64, 100.0f64, 110.0f64, 125.0f64, 135.0f64],
      Bool.pick(List<&2, F64>, String.eq(l, "f"), [6.0f64, 10.0f64, 13.0f64, 16.0f64, 20.0f64, 25.0f64, 30.0f64, 36.0f64, 43.0f64, 50.0f64, 56.0f64, 62.0f64, 68.0f64],
        Bool.pick(List<&2, F64>, String.eq(l, "g"), [2.0f64, 4.0f64, 5.0f64, 6.0f64, 7.0f64, 9.0f64, 10.0f64, 12.0f64, 14.0f64, 15.0f64, 17.0f64, 18.0f64, 20.0f64], []))))

def ei_lo(+l: String) -> List<&2, F64>:
  Bool.pick(List<&2, F64>, String.eq(l, "k"), [0.0f64, 1.0f64, 1.0f64, 1.0f64, 2.0f64, 2.0f64, 2.0f64, 3.0f64, 3.0f64, 4.0f64, 4.0f64, 4.0f64, 5.0f64],
    Bool.pick(List<&2, F64>, String.eq(l, "m"), [2.0f64, 4.0f64, 6.0f64, 7.0f64, 8.0f64, 9.0f64, 11.0f64, 13.0f64, 15.0f64, 17.0f64, 20.0f64, 21.0f64, 23.0f64],
      Bool.pick(List<&2, F64>, String.eq(l, "n"), [4.0f64, 8.0f64, 10.0f64, 12.0f64, 15.0f64, 17.0f64, 20.0f64, 23.0f64, 27.0f64, 31.0f64, 34.0f64, 37.0f64, 40.0f64],
        Bool.pick(List<&2, F64>, String.eq(l, "p"), [6.0f64, 12.0f64, 15.0f64, 18.0f64, 22.0f64, 26.0f64, 32.0f64, 37.0f64, 43.0f64, 50.0f64, 56.0f64, 62.0f64, 68.0f64], []))))

def ei_sub(+l: String) -> List<&2, F64>:
  Bool.pick(List<&2, F64>, String.eq(l, "r"), [10.0f64, 15.0f64, 19.0f64, 23.0f64, 28.0f64, 34.0f64, 41.0f64, 43.0f64, 51.0f64, 54.0f64, 63.0f64, 65.0f64, 68.0f64,
      77.0f64, 80.0f64, 84.0f64, 94.0f64, 98.0f64, 108.0f64, 114.0f64, 126.0f64, 132.0f64],
    Bool.pick(List<&2, F64>, String.eq(l, "s"), [14.0f64, 19.0f64, 23.0f64, 28.0f64, 35.0f64, 43.0f64, 53.0f64, 59.0f64, 71.0f64, 79.0f64, 92.0f64, 100.0f64, 108.0f64,
      122.0f64, 130.0f64, 140.0f64, 158.0f64, 170.0f64, 190.0f64, 208.0f64, 232.0f64, 252.0f64], []))

def s_letters(s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{+h, +t}:
      +c = S.chr_code(h)
      Bool.pick(String, Bool.and(U32.is_le(48, c), U32.is_le(c, 57)), acc, s_letters(t, acc ++ SCon{h, ""}))

def s_digits(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{+h, +t}:
      +c = S.chr_code(h)
      Bool.pick(String, Bool.and(U32.is_le(48, c), U32.is_le(c, 57)), SCon{h, t}, s_digits(t))

def nat_of(+s: String) -> Nat:
  +f = KT.f_of(s)
  Bool.pick(Nat, Bool.and(T.is_finite(f), F64.is_le(1.0f64, f)), U64.to_nat(F64.to_u64(f)), 0n)

def split_slash(s: String, +acc: String) -> List<&2, String>:
  match s:
    case SNil{}: [acc]
    case SCon{+h, +t}: Bool.pick(List<&2, String>, U32.is_eq(S.chr_code(h), 47), acc <> split_slash(t, ""), split_slash(t, acc ++ SCon{h, ""}))

def hole_ok(+l: String) -> Bool:
  Bool.or(Bool.or(Bool.or(String.eq(l, "D"), String.eq(l, "E")), Bool.or(String.eq(l, "F"), String.eq(l, "G"))), Bool.or(String.eq(l, "H"), String.eq(l, "JS")))

def shaft_ok(+l: String) -> Bool:
  Bool.or(Bool.or(Bool.or(Bool.or(String.eq(l, "d"), String.eq(l, "e")), Bool.or(String.eq(l, "f"), String.eq(l, "g"))),
    Bool.or(Bool.or(String.eq(l, "h"), String.eq(l, "js")), Bool.or(String.eq(l, "k"), String.eq(l, "m")))),
    Bool.or(Bool.or(String.eq(l, "n"), String.eq(l, "p")), Bool.or(String.eq(l, "r"), String.eq(l, "s"))))

def grade_ok(+g: Nat) -> Bool:
  Bool.and(Nat.is_le(5n, g), Nat.is_le(g, 11n))

def fc_of(+c: String) -> FC:
  +ps = split_slash(c, "")
  +h = KT.str_at(ps, 0n)
  +s = KT.str_at(ps, 1n)
  +hl = s_letters(h, "")
  +sl = s_letters(s, "")
  +hg = nat_of(s_digits(h))
  +sg = nat_of(s_digits(s))
  FC{Bool.and(Nat.is_eq(List.length(&2, String, ps), 2n), Bool.and(Bool.and(hole_ok(hl), shaft_ok(sl)), Bool.and(grade_ok(hg), grade_ok(sg)))),
    hl, hg, sl, sg}

def lower(+l: String) -> String:
  Bool.pick(String, String.eq(l, "D"), "d", Bool.pick(String, String.eq(l, "E"), "e", Bool.pick(String, String.eq(l, "F"), "f",
    Bool.pick(String, String.eq(l, "G"), "g", l))))

def shaft_lim(+l: String, +g: Nat, +d: F64) -> V.Vec2:
  +ri = rng_go(tops(), d, 0n)
  +si = rng_go(subtops(), d, 0n)
  +it = F64.div(KT.f_at(it_tab(g), ri), 1000.0f64)
  +up = Bool.or(Bool.or(String.eq(l, "d"), String.eq(l, "e")), Bool.or(String.eq(l, "f"), String.eq(l, "g")))
  +es = F64.neg(F64.div(KT.f_at(es_up(l), ri), 1000.0f64))
  +kz = Bool.and(String.eq(l, "k"), Nat.is_lt(7n, g))
  +sub = Bool.or(String.eq(l, "r"), String.eq(l, "s"))
  +ei = Bool.pick(F64, kz, 0.0f64, F64.div(Bool.pick(F64, sub, KT.f_at(ei_sub(l), si), KT.f_at(ei_lo(l), ri)), 1000.0f64))
  Bool.pick(V.Vec2, String.eq(l, "h"), V.V2{F64.sub(d, it), d},
    Bool.pick(V.Vec2, String.eq(l, "js"), V.V2{F64.sub(d, F64.mul(0.5f64, it)), F64.add(d, F64.mul(0.5f64, it))},
      Bool.pick(V.Vec2, up, V.V2{F64.add(F64.sub(d, it), es), F64.add(d, es)}, V.V2{F64.add(d, ei), F64.add(F64.add(d, ei), it)})))

def hole_lim(+l: String, +g: Nat, +d: F64) -> V.Vec2:
  +ri = rng_go(tops(), d, 0n)
  +it = F64.div(KT.f_at(it_tab(g), ri), 1000.0f64)
  +ei = Bool.pick(F64, String.eq(l, "H"), 0.0f64, F64.div(KT.f_at(es_up(lower(l)), ri), 1000.0f64))
  Bool.pick(V.Vec2, String.eq(l, "JS"), V.V2{F64.sub(d, F64.mul(0.5f64, it)), F64.add(d, F64.mul(0.5f64, it))},
    V.V2{F64.add(d, ei), F64.add(F64.add(d, ei), it)})

def fe_of(+x: S.Sx) -> FE:
  +xs = S.sx_xs(x)
  FE{S.sx_s(S.sx_nth(xs, 1n)), S.u64_of(S.sx_nth(xs, 2n)), S.sx_s(S.sx_nth(xs, 3n)), S.u64_of(S.sx_nth(xs, 4n)),
    S.sx_s(S.sx_nth(xs, 5n)), S.sx_s(S.sx_nth(xs, 6n)), S.sx_s(S.sx_nth(xs, 7n))}

def fes_of(xs: List<&2, S.Sx>) -> List<&2, FE>:
  match xs:
    case []: []
    case +x <> +t:
      +r = fes_of(t)
      Bool.pick(List<&2, FE>, S.head_is(x, "fit"), fe_of(x) <> r, r)

def tes_of(xs: List<&2, S.Sx>) -> List<&2, TE>:
  match xs:
    case []: []
    case +x <> +t:
      +r = tes_of(t)
      Bool.pick(List<&2, TE>, S.head_is(x, "temp"), TE{S.sx_s(S.sx_nth(S.sx_xs(x), 1n)), KT.f_of(S.sx_s(S.sx_nth(S.sx_xs(x), 2n)))} <> r, r)

def tes_or(+ts: List<&2, TE>) -> List<&2, TE>:
  Bool.pick(List<&2, TE>, Nat.is_eq(List.length(&2, TE, ts), 0n), [TE{"nominal", 20.0f64}], ts)

def cte_of(m: Maybe<&2, M.Grade>) -> F64:
  match m:
    case None{}: F64.nan()
    case Some{+g}:
      M.Gr{+n, +gr, +rho, +cte} = g
      cte

def gf(+cte: F64, +t: F64) -> I.I:
  Bool.pick(I.I, F64.is_eq(t, 20.0f64), I.ipt(1.0f64), I.iadd(I.ipt(1.0f64), I.imul(I.ipt(cte), I.isub(I.ipt(t), I.ipt(20.0f64)))))

def clear_iv(+h: V.Vec2, +s: V.Vec2, +fh: I.I, +fs: I.I) -> I.I:
  I.I{I.i_lo(I.isub(I.imul(I.ipt(V.v2_x(h)), fh), I.imul(I.ipt(V.v2_y(s)), fs))),
    I.i_hi(I.isub(I.imul(I.ipt(V.v2_y(h)), fh), I.imul(I.ipt(V.v2_x(s)), fs)))}

def iv_s(+a: F64, +b: F64) -> String:
  "[" ++ S.f_show(a) ++ ", " ++ S.f_show(b) ++ "]"

def temp_line(+kind: String, +nm: String, +t: F64, +c: I.I) -> String:
  "  temp " ++ nm ++ " T=" ++ S.f_show(t) ++ Bool.pick(String, String.eq(kind, "press"),
    " interference=" ++ iv_s(F64.neg(I.i_hi(c)), F64.neg(I.i_lo(c))), " clearance=" ++ iv_s(I.i_lo(c), I.i_hi(c))) ++ "\n"

def temps_go(ts: List<&2, TE>, +kind: String, +h: V.Vec2, +s: V.Vec2, +ah: F64, +as: F64, +acc: List<&2, I.I>) -> List<&2, I.I>:
  match ts:
    case []: acc
    case +x <> +t:
      TE{+nm, +tt} = x
      temps_go(t, kind, h, s, ah, as, clear_iv(h, s, gf(ah, tt), gf(as, tt)) <> acc)

def te_nm(+x: TE) -> String:
  TE{+nm, +tt} = x
  nm

def te_t(+x: TE) -> F64:
  TE{+nm, +tt} = x
  tt

def lines_go(ts: List<&2, TE>, cs: List<&2, I.I>, +kind: String) -> String:
  match ts:
    case []: ""
    case +x <> +t:
      match cs:
        case []: ""
        case +c <> +ct: temp_line(kind, te_nm(x), te_t(x), c) ++ lines_go(t, ct, kind)

def all_pos(cs: List<&2, I.I>) -> Bool:
  match cs:
    case []: True{}
    case +h <> +t: Bool.and(F64.is_lt(0.0f64, I.i_lo(h)), all_pos(t))

def all_neg(cs: List<&2, I.I>) -> Bool:
  match cs:
    case []: True{}
    case +h <> +t: Bool.and(F64.is_lt(I.i_hi(h), 0.0f64), all_neg(t))

def all_mixed(cs: List<&2, I.I>) -> Bool:
  match cs:
    case []: True{}
    case +h <> +t: Bool.and(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), all_mixed(t))

def verdict_of(+kind: String, +cs: List<&2, I.I>) -> String:
  Bool.pick(String, String.eq(kind, "press"), Bool.pick(String, all_neg(cs), "verdict=press-certified", "fit-not-press"),
    Bool.pick(String, String.eq(kind, "clearance"), Bool.pick(String, all_pos(cs), "verdict=clearance-certified", "fit-not-clearance"),
      Bool.pick(String, String.eq(kind, "transition"), Bool.pick(String, all_mixed(cs), "verdict=transition-certified", "fit-not-transition"), "unknown-fit-kind")))

def fe_name(+f: FE) -> String:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  nm

def tg_at(+cs: List<&2, M.CE>, +n: U64, +nm: String) -> KT.TG:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, n)))
  KT.tg_of(b, M.name_idx(M.bd_fns(b), nm, 0n))

def face_known(+cs: List<&2, M.CE>, +n: U64, +nm: String) -> Bool:
  +b = M.nr_body(M.ce_r(M.ce_find(cs, n)))
  Nat.is_lt(M.name_idx(M.bd_fns(b), nm, 0n), List.length(&2, BD.Fn, M.bd_fns(b)))

def needs_mat(ts: List<&2, TE>) -> Bool:
  match ts:
    case []: False{}
    case +h <> +t:
      TE{+nm, +tt} = h
      Bool.or(Bool.not(F64.is_eq(tt, 20.0f64)), needs_mat(t))

def fit_ok(+f: FE, +fc: FC, +ms: List<&2, M.Grade>, +tes: List<&2, TE>, +d: F64) -> String:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  FC{+ok, +hl, +hg, +sl, +sg} = fc
  +h = hole_lim(hl, hg, d)
  +s = shaft_lim(sl, sg, d)
  +ah = Bool.pick(F64, needs_mat(tes), cte_of(KM.mat_find(ms, a)), 0.0f64)
  +as = Bool.pick(F64, needs_mat(tes), cte_of(KM.mat_find(ms, b)), 0.0f64)
  +cl = List.reverse(&2, I.I, temps_go(tes, k, h, s, ah, as, []))
  +v = verdict_of(k, cl)
  +head = "fit " ++ nm ++ " hole " ++ U64.show(a) ++ "." ++ hs ++ " " ++ hl ++ Nat.show(hg) ++ "=" ++ iv_s(V.v2_x(h), V.v2_y(h)) ++
    " shaft " ++ U64.show(b) ++ "." ++ ss ++ " " ++ sl ++ Nat.show(sg) ++ "=" ++ iv_s(V.v2_x(s), V.v2_y(s)) ++ " nominal=" ++ S.f_show(d) ++ "\n"
  Bool.pick(String, Bool.and(T.is_finite(ah), T.is_finite(as)),
    Bool.pick(String, Bool.or(Bool.or(String.eq(v, "fit-not-press"), String.eq(v, "fit-not-transition")), Bool.or(String.eq(v, "fit-not-clearance"), String.eq(v, "unknown-fit-kind"))),
      head ++ lines_go(tes, cl, k) ++ "error invalid-input | pmi fits | why: " ++ v ++ ": " ++ nm ++ " | fix: choose classes whose envelope gives the declared kind at every state\n",
      head ++ lines_go(tes, cl, k) ++ "  " ++ v ++ " status=certified\n"),
    "error invalid-input | pmi fits | why: material-not-bound for fit " ++ nm ++ " | fix: bind materials to nodes " ++ U64.show(a) ++ " and " ++ U64.show(b) ++ " to evaluate states other than 20 C\n")

def fit_code(+f: FE, +fc: FC, +cs: List<&2, M.CE>) -> U64:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  FC{+ok, +hl, +hg, +sl, +sg} = fc
  +th = tg_at(cs, a, hs)
  +ts = tg_at(cs, b, ss)
  +dh = F64.mul(2.0f64, KT.tg_r(th))
  +ds = F64.mul(2.0f64, KT.tg_r(ts))
  Bool.pick(U64, Bool.not(ok), 1u64,
    Bool.pick(U64, Bool.not(Bool.and(face_known(cs, a, hs), face_known(cs, b, ss))), 2u64,
      Bool.pick(U64, Bool.not(Bool.and(KT.tg_ok(th), KT.tg_ok(ts))), 3u64,
        Bool.pick(U64, F64.is_lt(1.0e-6f64, F64.abs(F64.sub(dh, ds))), 4u64,
          Bool.pick(U64, Bool.or(F64.is_le(dh, 0.0f64), F64.is_lt(500.0f64, dh)), 5u64, 0u64)))))

def fit_err(+code: U64, +f: FE) -> String:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  "error invalid-input | pmi fits | why: " ++ Bool.pick(String, U64.is_eq(code, 1u64), "unknown-fit-class " ++ c,
    Bool.pick(String, U64.is_eq(code, 2u64), "face-not-found for fit " ++ nm,
      Bool.pick(String, U64.is_eq(code, 3u64), "fit-face-not-cylindrical for fit " ++ nm,
        Bool.pick(String, U64.is_eq(code, 4u64), "fit-nominal-mismatch for fit " ++ nm, "fit-size-outside-table for fit " ++ nm)))) ++
    " | fix: write (fit NAME HOLE_NODE HOLE_FACE SHAFT_NODE SHAFT_FACE CLASS KIND) on cylinders of one nominal size up to 500 mm with ISO 286 classes such as H7/g6\n"

def fe_a(+f: FE) -> U64:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  a

def fe_hs(+f: FE) -> String:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  hs

def fe_c(+f: FE) -> String:
  FE{+nm, +a, +hs, +b, +ss, +c, +k} = f
  c

def fit_k(+code: U64, +f: FE, +fc: FC, +cs: List<&2, M.CE>, +ms: List<&2, M.Grade>, +tes: List<&2, TE>) -> String:
  match code:
    case 0u64: fit_ok(f, fc, ms, tes, F64.mul(2.0f64, KT.tg_r(tg_at(cs, fe_a(f), fe_hs(f)))))
    case _: fit_err(code, f)

def fits_go(fs: List<&2, FE>, +cs: List<&2, M.CE>, +ms: List<&2, M.Grade>, +tes: List<&2, TE>) -> String:
  match fs:
    case []: ""
    case +h <> +t:
      +fc = fc_of(fe_c(h))
      fit_k(fit_code(h, fc, cs), h, fc, cs, ms, tes) ++ fits_go(t, cs, ms, tes)

def body_xs(+r: S.PS) -> List<&2, S.Sx>:
  S.PS{+ok, +xs} = r
  S.sx_drop(S.sx_xs(S.sx_nth(xs, 0n)), 1n)

def fits_s(+p: M.Part, +ms: List<&2, M.Grade>, +text: String) -> String:
  +es = body_xs(S.parse(text))
  +fs = fes_of(es)
  Bool.pick(String, Nat.is_eq(List.length(&2, FE, fs), 0n), "error invalid-input | pmi fits | why: no fit entries | fix: add (fit NAME HOLE_NODE HOLE_FACE SHAFT_NODE SHAFT_FACE CLASS KIND)",
    "fits " ++ Nat.show(List.length(&2, FE, fs)) ++ "\n" ++ fits_go(fs, M.ev_part(p, []), ms, tes_or(tes_of(es))))
