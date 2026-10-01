import os, re, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
gen = os.path.join(here, "gen")
os.makedirs(gen, exist_ok=True)
bench = open(os.path.join(here, "..", "..", "bench", "bench.py"), encoding="utf-8").read()


def block(name):
    m = re.search(name + r' = f?"""', bench)
    s = bench[m.end():]
    return s[:s.index('"""')]


src = os.path.relpath(os.path.join(here, "..", "..", "..", "src"), gen).replace(os.sep, "/")
head4 = block("HEAD4").replace("{{", "{").replace("}}", "}").replace("{src}", src)
holes = block("HOLES")
holes = holes[:holes.index("def main()")]
prism = block("PRISM")
prism = prism[:prism.index("def main()")]
ren = {}
for n in re.findall(r"^def (\w+)\(", prism, re.M):
    if re.search(r"^def " + n + r"\(", holes, re.M):
        ren[n] = "pr_" + n
for a, b in ren.items():
    prism = re.sub(r"(?<![\w.])" + a + r"\(", b + "(", prism)

MUT = '''
def l_set(-A: Data, xs: List<&2, A>, i: Nat, +v: A) -> List<&2, A>:
  match xs:
    case Nil{}: []
    case h <> t:
      match i:
        case 0n: v <> t
        case 1n+j: h <> l_set(A, t, j, v)

def l_del(-A: Data, xs: List<&2, A>, i: Nat) -> List<&2, A>:
  match xs:
    case Nil{}: []
    case h <> t:
      match i:
        case 0n: t
        case 1n+j: h <> l_del(A, t, j)

def l_ins(-A: Data, i: Nat, xs: List<&2, A>, +v: A) -> List<&2, A>:
  match i:
    case 0n: v <> xs
    case 1n+j:
      match xs:
        case Nil{}: [v]
        case h <> t: h <> l_ins(A, j, t, v)

def l_get(-A: Data, xs: List<&2, A>, i: Nat, +d: A) -> A:
  match xs:
    case Nil{}: d
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: l_get(A, t, j, d)

def l_swap(-A: Data, +xs: List<&2, A>, +i: Nat, +d: A) -> List<&2, A>:
  +a = l_get(A, xs, i, d)
  +b = l_get(A, xs, Nat.add(i, 1n), d)
  +n = List.length(&2, A, xs)
  Bool.pick(List<&2, A>, Nat.is_lt(Nat.add(i, 1n), n), l_set(A, l_set(A, xs, i, b), Nat.add(i, 1n), a), xs)

def lp_ces_to(lp: Ty.Loop, +hs: List<&2, Ty.HCoedge>) -> Ty.Loop:
  Ty.Lp{lg, lh, lk} = lp
  Ty.Lp{lg, hs, lk}

def lp_kflip(lp: Ty.Loop) -> Ty.Loop:
  Ty.Lp{lg, lh, lk} = lp
  Ty.Lp{lg, lh, Bool.pick(Ty.LoopKind, U64.is_eq(Ty.lkind_tag(lk), 0u64), Ty.LK_inner{}, Ty.LK_outer{})}

def ce_flip(ce: Ty.Coedge) -> Ty.Coedge:
  Ty.Ce{cg, ch, cf, ct} = ce
  Ty.Ce{cg, ch, Bool.not(cf), ct}

def ce_stale(ce: Ty.Coedge) -> Ty.Coedge:
  Ty.Ce{cg, ch, cf, ct} = ce
  Ty.HE{hei, heg} = ch
  Ty.Ce{cg, Ty.HE{hei, (heg + 1u64 : U64)}, cf, ct}

def ce_edge_to(ce: Ty.Coedge, +he: Ty.HEdge) -> Ty.Coedge:
  Ty.Ce{cg, ch, cf, ct} = ce
  Ty.Ce{cg, he, cf, ct}

def fa_flip(fa: Ty.Face) -> Ty.Face:
  Ty.Fa{fg, fsu, fl, fsa} = fa
  Ty.Fa{fg, fsu, fl, Bool.not(fsa)}

def sh_faces_to(sh: Ty.Shell, +fs: List<&2, Ty.HFace>) -> Ty.Shell:
  Ty.Sh{sg, sf, sk} = sh
  Ty.Sh{sg, fs, sk}

def vx_to(vx: Ty.Vertex, +p: V.Point) -> Ty.Vertex:
  Ty.Vx{vg, vp} = vx
  Ty.Vx{vg, p}

def vx_shift(vx: Ty.Vertex) -> Ty.Vertex:
  Ty.Vx{vg, +vp} = vx
  Ty.Vx{vg, V.Pt{(V.pt_x(vp) + 0.5f64 : F64), V.pt_y(vp), V.pt_z(vp)}}

def ed_swap(ed: Ty.Edge) -> Ty.Edge:
  Ty.Ed{eg, e0, e1, ek} = ed
  Ty.Ed{eg, e1, e0, ek}

def cp_dup(top: Ty.Compound) -> Ty.Compound:
  Ty.Cp{+csol, cshl} = top
  Ty.Cp{List.append(&2, Ty.HSolid, csol, csol), cshl}

def md(+s: U64, +n: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_eq(n, 0n), 0n, Nat.mod(U64.to_nat(U64.mod((s / 8589934592u64 : U64), 1000003u64)), n))

def lcg(+s: U64) -> U64:
  ((s * 6364136223846793005u64 : U64) + 1442695040888963407u64 : U64)

def sd1(+s: U64) -> U64:
  lcg(s)

def sd2(+s: U64) -> U64:
  lcg(lcg(s))

def m_li(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd1(s), List.length(&2, Ty.Loop, Ty.brep_lps(b)))

def m_lp(+b: Ty.Brep, +s: U64) -> Ty.Loop:
  l_get(Ty.Loop, Ty.brep_lps(b), m_li(b, s), Ty.lp_dflt())

def m_hs(+b: Ty.Brep, +s: U64) -> List<&2, Ty.HCoedge>:
  Ty.lp_ces(m_lp(b, s))

def m_j(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd2(s), List.length(&2, Ty.HCoedge, m_hs(b, s)))

def m_ci(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd1(s), List.length(&2, Ty.Coedge, Ty.brep_ces(b)))

def m_ce(+b: Ty.Brep, +s: U64) -> Ty.Coedge:
  l_get(Ty.Coedge, Ty.brep_ces(b), m_ci(b, s), Ty.ce_dflt())

def m_fi(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd2(s), List.length(&2, Ty.Face, Ty.brep_fas(b)))

def m_vi(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd1(s), List.length(&2, Ty.Vertex, Ty.brep_vs(b)))

def m_vj(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd2(s), List.length(&2, Ty.Vertex, Ty.brep_vs(b)))

def m_ei(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd2(s), List.length(&2, Ty.Edge, Ty.brep_es(b)))

def m_sh(+b: Ty.Brep) -> Ty.Shell:
  l_get(Ty.Shell, Ty.brep_shs(b), 0n, Ty.sh_dflt())

def m_fs(+b: Ty.Brep) -> List<&2, Ty.HFace>:
  Ty.sh_faces(m_sh(b))

def m_fj(+b: Ty.Brep, +s: U64) -> Nat:
  md(sd1(s), List.length(&2, Ty.HFace, m_fs(b)))

def with_lps(b: Ty.Brep, +lps: List<&2, Ty.Loop>) -> Ty.Brep:
  Ty.Br{vs, es, ces, x, fas, shs, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_ces(b: Ty.Brep, +ces: List<&2, Ty.Coedge>) -> Ty.Brep:
  Ty.Br{vs, es, x, lps, fas, shs, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_fas(b: Ty.Brep, +fas: List<&2, Ty.Face>) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, x, shs, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_shs(b: Ty.Brep, +shs: List<&2, Ty.Shell>) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, fas, x, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_vs(b: Ty.Brep, +vs: List<&2, Ty.Vertex>) -> Ty.Brep:
  Ty.Br{x, es, ces, lps, fas, shs, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_es(b: Ty.Brep, +es: List<&2, Ty.Edge>) -> Ty.Brep:
  Ty.Br{vs, x, ces, lps, fas, shs, sos, top, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def with_top(b: Ty.Brep, +top: Ty.Compound) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, fas, shs, sos, x, stamp} = b
  Ty.Br{vs, es, ces, lps, fas, shs, sos, top, stamp}

def set_lp(+b: Ty.Brep, +s: U64, +lp: Ty.Loop) -> Ty.Brep:
  with_lps(b, l_set(Ty.Loop, Ty.brep_lps(b), m_li(b, s), lp))

def set_hs(+b: Ty.Brep, +s: U64, +hs: List<&2, Ty.HCoedge>) -> Ty.Brep:
  set_lp(b, s, lp_ces_to(m_lp(b, s), hs))

def set_ce(+b: Ty.Brep, +s: U64, +ce: Ty.Coedge) -> Ty.Brep:
  with_ces(b, l_set(Ty.Coedge, Ty.brep_ces(b), m_ci(b, s), ce))

def set_fs(+b: Ty.Brep, +fs: List<&2, Ty.HFace>) -> Ty.Brep:
  with_shs(b, l_set(Ty.Shell, Ty.brep_shs(b), 0n, sh_faces_to(m_sh(b), fs)))

def set_vx(+b: Ty.Brep, +s: U64, +v: Ty.Vertex) -> Ty.Brep:
  with_vs(b, l_set(Ty.Vertex, Ty.brep_vs(b), m_vi(b, s), v))

def mk0(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_hs(b, s, l_del(Ty.HCoedge, m_hs(b, s), m_j(b, s)))

def mk1(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  +hs = m_hs(b, s)
  +j = m_j(b, s)
  set_hs(b, s, l_ins(Ty.HCoedge, j, hs, l_get(Ty.HCoedge, hs, j, Ty.hc_null())))

def mk2(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_hs(b, s, l_swap(Ty.HCoedge, m_hs(b, s), m_j(b, s), Ty.hc_null()))

def mk3(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_ce(b, s, ce_flip(m_ce(b, s)))

def mk4(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_ce(b, s, ce_stale(m_ce(b, s)))

def mk5(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  +fi = m_fi(b, s)
  with_fas(b, l_set(Ty.Face, Ty.brep_fas(b), fi, fa_flip(l_get(Ty.Face, Ty.brep_fas(b), fi, Ty.fa_dflt()))))

def mk6(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_lp(b, s, lp_kflip(m_lp(b, s)))

def mk7(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  +fs = m_fs(b)
  +fj = m_fj(b, s)
  set_fs(b, l_ins(Ty.HFace, fj, fs, l_get(Ty.HFace, fs, fj, Ty.hfa_null())))

def mk8(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_fs(b, l_del(Ty.HFace, m_fs(b), m_fj(b, s)))

def m_vx(+b: Ty.Brep, +s: U64) -> Ty.Vertex:
  l_get(Ty.Vertex, Ty.brep_vs(b), m_vi(b, s), Ty.vx_dflt())

def mk9(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_vx(b, s, vx_to(m_vx(b, s), Ty.vx_p(l_get(Ty.Vertex, Ty.brep_vs(b), m_vj(b, s), Ty.vx_dflt()))))

def mk10(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_vx(b, s, vx_shift(m_vx(b, s)))

def m_ed(+b: Ty.Brep, +s: U64) -> Ty.Edge:
  l_get(Ty.Edge, Ty.brep_es(b), m_ei(b, s), Ty.ed_dflt())

def mk11(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_ce(b, s, ce_edge_to(m_ce(b, s), Ty.mk_he(m_ei(b, s), Ty.ed_gen(m_ed(b, s)))))

def mk12(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_hs(b, s, List.reverse(&2, Ty.HCoedge, m_hs(b, s)))

def mk13(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  with_top(b, cp_dup(Ty.brep_top(b)))

def mk14(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  with_es(b, l_set(Ty.Edge, Ty.brep_es(b), m_ei(b, s), ed_swap(m_ed(b, s))))

def off_of(+s: U64) -> F64:
  +a = U64.to_f64(U64.from_nat(md(s, 9n)))
  ((a - 4.0f64 : F64) * 0.5f64 : F64)

def vx_jit(vx: Ty.Vertex, +s: U64) -> Ty.Vertex:
  Ty.Vx{vg, +vp} = vx
  Ty.Vx{vg, V.Pt{(V.pt_x(vp) + off_of(s) : F64), (V.pt_y(vp) + off_of(lcg(s)) : F64), V.pt_z(vp)}}

def vx_sub(vx: Ty.Vertex) -> Ty.Vertex:
  Ty.Vx{vg, +vp} = vx
  Ty.Vx{vg, V.Pt{F64{1u64}, V.pt_y(vp), V.pt_z(vp)}}

def mk15(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_vx(b, s, vx_jit(m_vx(b, s), lcg(sd2(s))))

def mk16(+b: Ty.Brep, +s: U64) -> Ty.Brep:
  set_vx(b, s, vx_sub(m_vx(b, s)))

def mut(+b: Ty.Brep, +s: U64, +k: Nat) -> Ty.Brep:
  mut_go(Nat.mod(k, 17n), b, s)

def mut2_go(two: Bool, +b: Ty.Brep, +s: U64) -> Ty.Brep:
  match two:
    case True{}: mut(b, sd2(lcg(s)), md(lcg(sd2(s)), 17n))
    case False{}: b

def mutc(+b: Ty.Brep, +s: U64, +i: Nat) -> Ty.Brep:
  mut2_go(Nat.is_eq(Nat.mod(Nat.div(i, 17n), 2n), 1n), mut(b, s, i), s)

def mut_go(k: Nat, +b: Ty.Brep, +s: U64) -> Ty.Brep:
  match k:
    case 0n: mk0(b, s)
    case 1n: mk1(b, s)
    case 2n: mk2(b, s)
    case 3n: mk3(b, s)
    case 4n: mk4(b, s)
    case 5n: mk5(b, s)
    case 6n: mk6(b, s)
    case 7n: mk7(b, s)
    case 8n: mk8(b, s)
    case 9n: mk9(b, s)
    case 10n: mk10(b, s)
    case 11n: mk11(b, s)
    case 12n: mk12(b, s)
    case 13n: mk13(b, s)
    case 14n: mk14(b, s)
    case 15n: mk15(b, s)
    case _: mk16(b, s)

def ns(+c: Nat) -> String:
  Nat.show(c)

def codes_new_a(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  ns(Op.brep_incid_c(b, f)) ++ ns(Op.brep_use_c(b, p, f)) ++ ns(Op.brep_loop_c(b, f)) ++ ns(Op.brep_facekind_c(b, f))

def codes_new_b(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  ns(Op.brep_prof_c(b, p, f)) ++ ns(Op.brep_embed_c(b, f)) ++ ns(Op.brep_link_c(b, p, f)) ++ ns(Op.brep_conn_c(b, f))

def codes_new_c(+b: Ty.Brep, +f: Nat) -> String:
  ns(Op.brep_coin_c(b, f)) ++ ns(Op.brep_xing_c(b, f)) ++ ns(Op.brep_orient_c(b, f)) ++ "," ++ ns(Op.brep_orient_cert_c(b, f))

def codes_new_d(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  "," ++ ns(Op.brep_orient_skip_c(b, f)) ++ ns(Op.brep_recheck_c(b, f)) ++ ":" ++ Ty.tres_show(Op.brep_checked(b, p, f))

def codes_new(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  codes_new_a(b, p, f) ++ codes_new_b(b, p, f) ++ codes_new_c(b, f) ++ codes_new_d(b, p, f)

def codes_ref_a(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  ns(R.brep_incid_c(b, f)) ++ ns(R.brep_use_c(b, p, f)) ++ ns(R.brep_loop_c(b, f)) ++ ns(R.brep_facekind_c(b, f))

def codes_ref_b(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  ns(R.brep_prof_c(b, p, f)) ++ ns(R.brep_embed_c(b, f)) ++ ns(link_ref(b, p, f)) ++ ns(R.brep_conn_c(b, f))

def codes_ref_c(+b: Ty.Brep, +f: Nat) -> String:
  ns(R.brep_coin_c(b, f)) ++ ns(R.brep_xing_c(b, f)) ++ ns(R.brep_orient_c(b, f)) ++ "," ++ ns(R.brep_orient_cert_c(b, f))

def codes_ref_d(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  "," ++ ns(R.brep_orient_skip_c(b, f)) ++ ns(R.brep_recheck_c(b, f)) ++ ":" ++ Ty.tres_show(R.brep_checked(b, p, f))

def codes_ref(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> String:
  codes_ref_a(b, p, f) ++ codes_ref_b(b, p, f) ++ codes_ref_c(b, f) ++ codes_ref_d(b, p, f)

def orbit_spin(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> Bool:
  Bool.and(Nat.is_eq(R.brep_link_c(b, p, f), 0n),
    Bool.and(Nat.is_eq(R.brep_link_c(b, p, Nat.mul(4n, f)), 0n), Nat.is_eq(Op.brep_link_c(b, p, f), 2n)))

def link_ref(+b: Ty.Brep, +p: Ty.Profile, +f: Nat) -> Nat:
  Bool.pick(Nat, orbit_spin(b, p, f), 2n, R.brep_link_c(b, p, f))

type Tal is Data:
  Tal{ n: Nat, bad: Nat, out: String, inv: Nat, spin: Nat }

def one(+b: Ty.Brep, +p: Ty.Profile, +tag: String, t: Tal) -> Tal:
  Tal{n, bad, +out, inv, spin} = t
  +a = codes_new(b, p, 1000n)
  +r = codes_ref(b, p, 1000n)
  +same = String.eq(a, r)
  +iv = String.eq(Ty.tres_show(Op.brep_checked(b, p, 1000n)), "ok")
  Tal{Nat.add(n, 1n), Nat.add(bad, Bool.pick(Nat, same, 0n, 1n)),
    Bool.pick(String, same, out, out ++ tag ++ " new=" ++ a ++ " ref=" ++ r ++ "\\n"), Nat.add(inv, Bool.pick(Nat, iv, 0n, 1n)),
    Nat.add(spin, Bool.pick(Nat, orbit_spin(b, p, 1000n), 1n, 0n))}

def tal_show(t: Tal) -> String:
  Tal{n, bad, +out, inv, spin} = t
  out ++ "differential: " ++ Nat.show(n) ++ " cases, mismatches=" ++ Nat.show(bad) ++ ", rejected by brep_checked=" ++ Nat.show(inv)
  ++ ", non-closing orbits (ref fuel-out at 4x, new invalid)=" ++ Nat.show(spin)

def run(c: Nat, +b: Ty.Brep, +p: Ty.Profile, +s: U64, +i: Nat, t: Tal) -> Tal:
  match c:
    case 0n: t
    case 1n+m: run(m, b, p, lcg(lcg(lcg(s))), Nat.add(i, 1n), one(mutc(b, s, i), p, "case" ++ Nat.show(i), t))

def main() -> String:
  +s0 = {SEEDu64 : U64}
  +t0 = {Tal{0n, 0n, "", 0n, 0n} : Tal}
  +t1 = one(prism(1n), Ty.P_manifold_solid{}, "base-prism1", one(plate(1n), Ty.P_open_shell{}, "base-plate1", t0))
  +t2 = run(COUNTn, prism(1n), Ty.P_manifold_solid{}, s0, 0n, t1)
  +t3 = run(COUNTn, prism(2n), Ty.P_manifold_solid{}, lcg(s0), 1000n, t2)
  +t4 = run(COUNTn, plate(1n), Ty.P_open_shell{}, lcg(lcg(s0)), 2000n, t3)
  +t5 = run(COUNTn, plate(2n), Ty.P_open_shell{}, lcg(lcg(lcg(s0))), 3000n, t4)
  tal_show(run(COUNTn, prism(1n), Ty.P_open_shell{}, lcg(lcg(lcg(lcg(s0)))), 4000n, t5))
'''



def toposort(text):
    lines = text.split("\n")
    imps = [l for l in lines if l.startswith("import ")]
    body = "\n".join(l for l in lines if not l.startswith("import "))
    blocks = [b for b in re.split(r"(?m)^(?=def |type )", body) if b.strip() and re.match(r"(?:def|type) ", b)]
    names = [re.match(r"(?:def|type) (\w+)", b).group(1) for b in blocks]
    bm = dict(zip(names, blocks))
    deps = {n: [m for m in names if m != n and re.search(r"(?<![\w.])" + m + r"\b", bm[n])] for n in names}
    out, done = [], set()

    def visit(n, path=()):
        if n in done or n in path:
            return
        for d in deps[n]:
            visit(d, path + (n,))
        done.add(n)
        out.append(n)
    for n in names:
        if bm[n].startswith("type "):
            visit(n)
    for n in names:
        visit(n)
    return "\n".join(imps) + "\n\n" + "".join(bm[n].rstrip("\n") + "\n\n" for n in out)


def wsl(cmd):
    if os.name == "nt":
        return subprocess.run(["wsl.exe", "-e", "bash", "-lc", cmd], capture_output=True, text=True)
    return subprocess.run(["bash", "-lc", cmd], capture_output=True, text=True)


def wpath(p):
    if os.name != "nt":
        return p
    d, rest = os.path.splitdrive(os.path.abspath(p))
    return "/mnt/" + d[0].lower() + rest.replace("\\", "/")


seed = int(sys.argv[1]) if len(sys.argv) > 1 else 7
count = int(sys.argv[2]) if len(sys.argv) > 2 else 60
ops_mod = os.environ.get("C04_OPS")
prog = head4.replace("NN", "1n") + "import ../ref/ops.bend as R\n" + holes + prism + MUT.replace("SEED", str(seed)).replace("COUNT", str(count))
prog = prog.replace("import Base\n", "import Base\n", 1)
lines = prog.split("\n")
imps = [l for l in lines if l.startswith("import ")]
rest = [l for l in lines if not l.startswith("import ")]
prog = "\n".join(imps + [""] + rest)
if ops_mod:
    prog = prog.replace("c04/ops.bend as Op", "c04/" + ops_mod + " as Op")
prog = toposort(prog)
f = os.path.join(gen, f"diff_{seed}.bend")
open(f, "w", newline="\n").write(prog)
exe = f"/tmp/bendcad-c04-diff-{seed}"
r = wsl(f'export PATH=$HOME/.bend/bin:$PATH; (ulimit -v 8000000; bend "{wpath(f)}" -o {exe}) && {exe}')
if r.returncode:
    sys.exit(f"diff oracle failed:\n{r.stdout}{r.stderr}")
print(r.stdout.strip().strip('"').replace("\\n", "\n"))
