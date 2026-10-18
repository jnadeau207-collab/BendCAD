import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c03/types.bend as G
import ../c04/types.bend as Ty
import ../c06/model.bend as M
import ../c06/build.bend as BD
import ../c06/sx.bend as S
import ../k1/sf.bend as KS
import ../k1/fb.bend as FB
import ./mat.bend as KM

type PR is Data:
  PR{ p: F64, td1: List<&2, F64>, td: List<&2, F64>, es: List<&2, F64> }

type DS is Data:
  DS{ ok: Bool, d: F64, p: F64 }

type TG is Data:
  TG{ ok: Bool, ax: V.Dir, o: V.Point, r: F64, inner: Bool, t0: F64, t1: F64 }

def pitches() -> List<&2, PR>:
  [PR{0.5f64, [0.112f64, 0.140f64, 0.180f64], [0.067f64, 0.106f64], [0.050f64, 0.036f64, 0.020f64]},
   PR{0.7f64, [0.140f64, 0.180f64, 0.224f64], [0.090f64, 0.140f64], [0.056f64, 0.038f64, 0.022f64]},
   PR{0.75f64, [0.150f64, 0.190f64, 0.236f64], [0.090f64, 0.140f64], [0.056f64, 0.038f64, 0.022f64]},
   PR{0.8f64, [0.160f64, 0.200f64, 0.250f64], [0.095f64, 0.150f64], [0.060f64, 0.038f64, 0.024f64]},
   PR{1.0f64, [0.190f64, 0.236f64, 0.300f64], [0.112f64, 0.180f64], [0.060f64, 0.040f64, 0.026f64]},
   PR{1.25f64, [0.212f64, 0.265f64, 0.335f64], [0.132f64, 0.212f64], [0.063f64, 0.042f64, 0.028f64]},
   PR{1.5f64, [0.236f64, 0.300f64, 0.375f64], [0.150f64, 0.236f64], [0.067f64, 0.045f64, 0.032f64]},
   PR{1.75f64, [0.265f64, 0.335f64, 0.425f64], [0.170f64, 0.265f64], [0.071f64, 0.048f64, 0.034f64]},
   PR{2.0f64, [0.300f64, 0.375f64, 0.475f64], [0.180f64, 0.280f64], [0.071f64, 0.052f64, 0.038f64]},
   PR{2.5f64, [0.355f64, 0.450f64, 0.560f64], [0.212f64, 0.335f64], [0.080f64, 0.058f64, 0.042f64]},
   PR{3.0f64, [0.400f64, 0.500f64, 0.630f64], [0.236f64, 0.375f64], [0.085f64, 0.063f64, 0.048f64]},
   PR{3.5f64, [0.450f64, 0.560f64, 0.710f64], [0.265f64, 0.425f64], [0.090f64, 0.070f64, 0.053f64]},
   PR{4.0f64, [0.475f64, 0.600f64, 0.750f64], [0.300f64, 0.475f64], [0.095f64, 0.075f64, 0.060f64]}]

def coarse() -> List<&2, V.Vec2>:
  [V.V2{3.0f64, 0.5f64}, V.V2{4.0f64, 0.7f64}, V.V2{5.0f64, 0.8f64}, V.V2{6.0f64, 1.0f64}, V.V2{8.0f64, 1.25f64},
   V.V2{10.0f64, 1.5f64}, V.V2{12.0f64, 1.75f64}, V.V2{14.0f64, 2.0f64}, V.V2{16.0f64, 2.0f64}, V.V2{18.0f64, 2.5f64},
   V.V2{20.0f64, 2.5f64}, V.V2{22.0f64, 2.5f64}, V.V2{24.0f64, 3.0f64}, V.V2{27.0f64, 3.0f64}, V.V2{30.0f64, 3.5f64},
   V.V2{33.0f64, 3.5f64}, V.V2{36.0f64, 4.0f64}]

def coarse_p(cs: List<&2, V.Vec2>, +d: F64) -> F64:
  match cs:
    case []: F64.nan()
    case +h <> +t: Bool.pick(F64, F64.is_eq(V.v2_x(h), d), V.v2_y(h), coarse_p(t, d))

def pr_find(ps: List<&2, PR>, +p: F64) -> Maybe<&2, PR>:
  match ps:
    case []: None{}
    case +h <> +t:
      PR{+pp, +a, +b, +c} = h
      Bool.pick(Maybe<&2, PR>, F64.is_eq(pp, p), Some{PR{pp, a, b, c}}, pr_find(t, p))

def f_at(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: f_at(t, j)

def split_x(s: String, +acc: String) -> List<&2, String>:
  match s:
    case SNil{}: [acc]
    case SCon{+h, +t}: Bool.pick(List<&2, String>, U32.is_eq(S.chr_code(h), 120), acc <> split_x(t, ""), split_x(t, acc ++ SCon{h, ""}))

def s_tail(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{+h, +t}: t

def s_head(s: String) -> U32:
  match s:
    case SNil{}: U32.from_nat(0n)
    case SCon{+h, +t}: S.chr_code(h)

def f_of(+s: String) -> F64:
  +m = S.num(s)
  Bool.pick(F64, S.is_some(m), S.some_v(m), F64.nan())

def str_at(xs: List<&2, String>, +i: Nat) -> String:
  match xs:
    case []: ""
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: str_at(t, j)

def is_pr(m: Maybe<&2, PR>) -> Bool:
  match m:
    case None{}: False{}
    case Some{x}: True{}

def desig(+s: String) -> DS:
  +parts = split_x(s_tail(s), "")
  +d = f_of(str_at(parts, 0n))
  +two = Nat.is_eq(List.length(&2, String, parts), 2n)
  +p = Bool.pick(F64, two, f_of(str_at(parts, 1n)), coarse_p(coarse(), d))
  +ok = Bool.and(U32.is_eq(s_head(s), 77), Bool.and(Bool.and(T.is_finite(d), T.is_finite(p)),
    Bool.and(Bool.or(Nat.is_eq(List.length(&2, String, parts), 1n), two), is_pr(pr_find(pitches(), p)))))
  DS{Bool.and(ok, F64.is_le(1.0f64, d)), d, p}

def ds_name(+d: DS) -> String:
  DS{+ok, +dd, +p} = d
  "M" ++ S.f_show(dd) ++ "x" ++ S.f_show(p)

def cls_code(+c: String) -> U64:
  Bool.pick(U64, String.eq(c, "5H"), 10u64, Bool.pick(U64, String.eq(c, "6H"), 11u64, Bool.pick(U64, String.eq(c, "7H"), 12u64,
    Bool.pick(U64, String.eq(c, "6G"), 13u64, Bool.pick(U64, String.eq(c, "4h"), 20u64, Bool.pick(U64, String.eq(c, "6h"), 21u64,
      Bool.pick(U64, String.eq(c, "6g"), 22u64, Bool.pick(U64, String.eq(c, "6f"), 23u64, Bool.pick(U64, String.eq(c, "6e"), 24u64, 0u64)))))))))

def cls_inner(+k: U64) -> Bool:
  U64.is_lt(k, 20u64)

def es_mag(+k: U64, +pr: PR) -> F64:
  PR{+p, +a, +b, +c} = pr
  Bool.pick(F64, Bool.or(U64.is_eq(k, 13u64), U64.is_eq(k, 22u64)), f_at(c, 2n),
    Bool.pick(F64, U64.is_eq(k, 23u64), f_at(c, 1n), Bool.pick(F64, U64.is_eq(k, 24u64), f_at(c, 0n), 0.0f64)))

def win(+k: U64, +d: DS, +pr: PR) -> V.Vec2:
  DS{+ok, +dd, +p} = d
  PR{+pp, +td1, +td, +es} = pr
  +d1 = F64.sub(dd, F64.mul(1.0825317547305483f64, p))
  +g = Bool.pick(Nat, U64.is_eq(k, 10u64), 0n, Bool.pick(Nat, U64.is_eq(k, 12u64), 2n, 1n))
  +e = es_mag(k, PR{pp, td1, td, es})
  +tde = f_at(td, Bool.pick(Nat, U64.is_eq(k, 20u64), 0n, 1n))
  Bool.pick(V.Vec2, cls_inner(k), V.V2{F64.add(d1, e), F64.add(F64.add(d1, e), f_at(td1, g))},
    V.V2{F64.sub(F64.sub(dd, e), tde), dd})

def r3(+x: F64) -> F64:
  F64.div(KS.f_round(F64.mul(x, 1000.0f64)), 1000.0f64)

def canon(+a: V.Dir) -> V.Dir:
  +ax = F64.abs(V.dr_x(a))
  +ay = F64.abs(V.dr_y(a))
  +az = F64.abs(V.dr_z(a))
  +c = Bool.pick(F64, Bool.and(F64.is_le(ay, ax), F64.is_le(az, ax)), V.dr_x(a), Bool.pick(F64, F64.is_le(az, ay), V.dr_y(a), V.dr_z(a)))
  Bool.pick(V.Dir, F64.is_lt(c, 0.0f64), KS.dscale(F64.neg(1.0f64), a), a)

def t_rng(cs: List<&2, FB.CE>, +b: Ty.Brep, +a: V.Dir, +acc: V.Vec2) -> V.Vec2:
  match cs:
    case []: acc
    case +h <> +t:
      +q = FB.ce_start3(b, h)
      +v = KS.dot(KS.psub(q, KS.pt(0.0f64, 0.0f64, 0.0f64)), a)
      t_rng(t, b, a, V.V2{F64.min(V.v2_x(acc), v), F64.max(V.v2_y(acc), v)})

def ts_rng(ls: List<&2, List<&2, FB.CE>>, +b: Ty.Brep, +a: V.Dir, +acc: V.Vec2) -> V.Vec2:
  match ls:
    case []: acc
    case +h <> +t: ts_rng(t, b, a, t_rng(h, b, a, acc))

def tg_cy(g: G.GVal, +b: Ty.Brep, +fi: Nat) -> TG:
  match g:
    case G.GV_cy{w}:
      G.Cy{+o, +a, +r} = w
      +ca = canon(a)
      +tr = ts_rng(FB.face_ce(b, fi), b, ca, V.V2{F64.div(1.0f64, 0.0f64), F64.neg(F64.div(1.0f64, 0.0f64))})
      TG{True{}, ca, o, r, Bool.not(FB.face_same(b, fi)), V.v2_x(tr), V.v2_y(tr)}
    case _: TG{False{}, V.Dr{0.0f64, 0.0f64, 1.0f64}, V.Pt{0.0f64, 0.0f64, 0.0f64}, 0.0f64, False{}, 0.0f64, 0.0f64}

def tg_of(+b: M.Body, +fi: Nat) -> TG:
  tg_cy(FB.face_surf(M.bd_brep(b), fi), M.bd_brep(b), fi)

def tg_ok(+t: TG) -> Bool:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  ok

def tg_r(+t: TG) -> F64:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  r

def tg_inner(+t: TG) -> Bool:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  inn

def tg_span(+t: TG) -> V.Vec2:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  V.V2{t0, t1}

def tg_ax(+t: TG) -> V.Dir:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  ax

def tg_o(+t: TG) -> V.Point:
  TG{+ok, +ax, +o, +r, +inn, +t0, +t1} = t
  o

def th_face(+th: M.Thr) -> String:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  f

def th_node(+th: M.Thr) -> U64:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  n

def th_name(+th: M.Thr) -> String:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  nm

def th_d(+th: M.Thr) -> String:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  d

def th_c(+th: M.Thr) -> String:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  c

def th_z(+th: M.Thr) -> V.Vec2:
  M.Th{+n, +nm, +f, +d, +c, +z0, +z1} = th
  V.V2{z0, z1}

def pr_or(m: Maybe<&2, PR>) -> PR:
  match m:
    case None{}: PR{0.0f64, [], [], []}
    case Some{x}: x

def ds_ok(+d: DS) -> Bool:
  DS{+ok, +dd, +p} = d
  ok

def ds_p(+d: DS) -> F64:
  DS{+ok, +dd, +p} = d
  p

def ds_d(+d: DS) -> F64:
  DS{+ok, +dd, +p} = d
  dd

def th_code(+th: M.Thr, +b: M.Body) -> U64:
  +fi = M.name_idx(M.bd_fns(b), th_face(th), 0n)
  +nf = List.length(&2, BD.Fn, M.bd_fns(b))
  +ds = desig(th_d(th))
  +k = cls_code(th_c(th))
  +tg = tg_of(b, fi)
  +z = th_z(th)
  +sp = tg_span(tg)
  +eps = {1.0e-9f64 : F64}
  +inside = Bool.and(F64.is_lt(V.v2_x(z), V.v2_y(z)), Bool.and(F64.is_le(F64.sub(V.v2_x(sp), eps), V.v2_x(z)), F64.is_le(V.v2_y(z), F64.add(V.v2_y(sp), eps))))
  +w = win(k, ds, pr_or(pr_find(pitches(), ds_p(ds))))
  +dm = F64.mul(2.0f64, tg_r(tg))
  +fits = Bool.and(F64.is_le(F64.sub(V.v2_x(w), eps), dm), F64.is_le(dm, F64.add(V.v2_y(w), eps)))
  Bool.pick(U64, Bool.not(ds_ok(ds)), 1u64, Bool.pick(U64, U64.is_eq(k, 0u64), 2u64,
    Bool.pick(U64, Nat.is_le(nf, fi), 3u64, Bool.pick(U64, Bool.not(tg_ok(tg)), 4u64,
      Bool.pick(U64, Bool.not(Bool.xor(tg_inner(tg), cls_inner(k))), Bool.pick(U64, inside, Bool.pick(U64, fits, 0u64, 7u64), 6u64), 5u64)))))

def th_why(+code: U64, +th: M.Thr, +inner: Bool) -> String:
  match code:
    case 1u64: "unknown-thread " ++ th_d(th)
    case 2u64: "unknown-thread-class " ++ th_c(th)
    case 3u64: "face-not-found: " ++ th_face(th)
    case 4u64: "thread-face-not-cylindrical: " ++ th_face(th)
    case 5u64: "thread-class-side-mismatch: " ++ th_c(th) ++ " on " ++ Bool.pick(String, inner, "a hole", "a shaft")
    case 6u64: "thread-span-outside-face: " ++ th_name(th)
    case 7u64: Bool.pick(String, inner, "thread-minor-diameter-mismatch: ", "thread-major-diameter-mismatch: ") ++ th_name(th)
    case _: ""

def th_err1(+th: M.Thr, +cs: List<&2, M.CE>) -> String:
  +n = th_node(th)
  +r = M.ce_r(M.ce_find(cs, n))
  +b = M.nr_body(r)
  +code = th_code(th, b)
  +tg = tg_of(b, M.name_idx(M.bd_fns(b), th_face(th), 0n))
  Bool.pick(String, Bool.not(KM.nd_known(cs, n)), KM.err_line("thread", "unknown-node " ++ U64.show(n), "bind threads to evaluated design nodes"),
    Bool.pick(String, U64.is_eq(code, 0u64), "",
      KM.err_line("thread", th_why(code, th, tg_inner(tg)), "write (thread NODE NAME FACE DESIGNATION CLASS Z0 Z1) on a cylindrical face sized to the class")))

def ths_err(ts: List<&2, M.Thr>, +cs: List<&2, M.CE>) -> String:
  match ts:
    case []: ""
    case +h <> +t: th_err1(h, cs) ++ ths_err(t, cs)

def th_line(+th: M.Thr, +b: M.Body) -> String:
  +ds = desig(th_d(th))
  +k = cls_code(th_c(th))
  +tg = tg_of(b, M.name_idx(M.bd_fns(b), th_face(th), 0n))
  +w = win(k, ds, pr_or(pr_find(pitches(), ds_p(ds))))
  +z = th_z(th)
  "thread " ++ th_name(th) ++ " " ++ ds_name(ds) ++ " " ++ th_c(th) ++ " z=[" ++ S.f_show(V.v2_x(z)) ++ ", " ++ S.f_show(V.v2_y(z)) ++
    "] length=" ++ S.f_show(F64.sub(V.v2_y(z), V.v2_x(z))) ++ Bool.pick(String, tg_inner(tg), " internal minor=[", " external major=[") ++
    S.f_show(r3(V.v2_x(w))) ++ ", " ++ S.f_show(r3(V.v2_y(w))) ++ "] model=" ++ S.f_show(F64.mul(2.0f64, tg_r(tg))) ++
    " face=" ++ th_face(th) ++ " status=certified
"

def ths_of_node(ts: List<&2, M.Thr>, +n: U64, +b: M.Body) -> String:
  match ts:
    case []: ""
    case +h <> +t: Bool.pick(String, U64.is_eq(th_node(h), n), th_line(h, b), "") ++ ths_of_node(t, n, b)

def th_set(ts: List<&2, M.Thr>, +x: M.Thr) -> List<&2, M.Thr>:
  match ts:
    case []: [x]
    case +h <> +t:
      Bool.pick(List<&2, M.Thr>, Bool.and(U64.is_eq(th_node(h), th_node(x)), String.eq(th_name(h), th_name(x))), x <> t, h <> th_set(t, x))
