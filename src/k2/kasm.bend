import Base
import ../c01/types.bend as V
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c06/sx.bend as S
import ../c14/asm.bend as A4
import ../c12/stepw.bend as SW
import ../k1/sf.bend as KS
import ./mat.bend as KM
import ./thr.bend as KT
import ./kgap.bend as KG

type MS is Data:
  MS{ ok: Bool, txt: String, tot: I.I }

type WA is Data:
  WA{ p: V.Point, d: V.Dir, lo: F64, hi: F64 }

def mx(+m: V.Mat3, +d: V.Dir) -> V.Dir:
  V.M3{+a, +b, +c, +e, +f, +g, +h, +i, +j} = m
  V.Dr{F64.add(F64.add(F64.mul(a, V.dr_x(d)), F64.mul(b, V.dr_y(d))), F64.mul(c, V.dr_z(d))),
    F64.add(F64.add(F64.mul(e, V.dr_x(d)), F64.mul(f, V.dr_y(d))), F64.mul(g, V.dr_z(d))),
    F64.add(F64.add(F64.mul(h, V.dr_x(d)), F64.mul(i, V.dr_y(d))), F64.mul(j, V.dr_z(d)))}

def place_pt(+b: M.Body, +p: V.Point) -> V.Point:
  +pl = M.bd_pl(b)
  +w = mx(M.pl_m(pl), KS.psub(p, KS.pt(0.0f64, 0.0f64, 0.0f64)))
  KS.pt(F64.add(V.dr_x(w), M.pl_tx(pl)), F64.add(V.dr_y(w), M.pl_ty(pl)), F64.add(V.dr_z(w), M.pl_tz(pl)))

def place_dr(+b: M.Body, +d: V.Dir) -> V.Dir:
  mx(M.pl_m(M.bd_pl(b)), d)

def in_find(xs: List<&2, A4.IN>, +nm: String) -> Maybe<&2, A4.IN>:
  match xs:
    case []: None{}
    case +h <> +t: Bool.pick(Maybe<&2, A4.IN>, String.eq(A4.in_name(h), nm), Some{h}, in_find(t, nm))

def in_node(+x: A4.IN) -> U64:
  A4.IN{+i, +r} = x
  A4.inst_node(i)

def mass_one(g: Maybe<&2, M.Grade>, +h: A4.IN, +ok: Bool, +txt: String, +tot: I.I) -> MS:
  match g:
    case None{}: MS{False{}, txt ++ "error invalid-input | asm mass | why: material-not-bound " ++ A4.in_name(h) ++
      " | fix: bind (material NODE GRADE DENSITY CTE) to node " ++ U64.show(in_node(h)) ++ "
", tot}
    case Some{+x}:
      M.Gr{+n, +gr, +rho, +cte} = x
      +k = KM.mass_iv(M.ms_vol(M.body_ms(M.nr_body(A4.in_nr(h)))), rho)
      MS{ok, txt ++ A4.in_name(h) ++ " " ++ gr ++ " mass=[" ++ S.f_show(I.i_lo(k)) ++ ", " ++ S.f_show(I.i_hi(k)) ++ "] kg
",
        I.iadd(tot, k)}

def mass_go(xs: List<&2, A4.IN>, +ms: List<&2, M.Grade>, +acc: MS) -> MS:
  match xs:
    case []: acc
    case +h <> +t:
      MS{+ok, +txt, +tot} = acc
      mass_go(t, ms, mass_one(KM.mat_find(ms, in_node(h)), h, ok, txt, tot))

def mass_fmt(+r: MS) -> String:
  MS{+ok, +txt, +tot} = r
  Bool.pick(String, ok, "assembly mass\n" ++ txt ++ "total=[" ++ S.f_show(I.i_lo(tot)) ++ ", " ++ S.f_show(I.i_hi(tot)) ++
    "] kg status=certified", txt)

def mass_rep(+xs: List<&2, A4.IN>, +ms: List<&2, M.Grade>) -> String:
  mass_fmt(mass_go(xs, ms, MS{True{}, "", I.ipt(0.0f64)}))

def th_find(ts: List<&2, M.Thr>, +n: U64, +nm: String) -> Maybe<&2, M.Thr>:
  match ts:
    case []: None{}
    case +h <> +t: Bool.pick(Maybe<&2, M.Thr>, Bool.and(U64.is_eq(KT.th_node(h), n), String.eq(KT.th_name(h), nm)), Some{h}, th_find(t, n, nm))

def axial_pt(+t: KT.TG, +z: F64) -> V.Point:
  +a = KT.tg_ax(t)
  +o = KT.tg_o(t)
  KS.padd(o, F64.sub(z, KS.dot(KS.psub(o, KS.pt(0.0f64, 0.0f64, 0.0f64)), a)), a)

def wa_of(+b: M.Body, +th: M.Thr) -> WA:
  +t = KT.tg_of(b, M.name_idx(M.bd_fns(b), KT.th_face(th), 0n))
  +z = KT.th_z(th)
  +d = place_dr(b, KT.tg_ax(t))
  +p0 = place_pt(b, axial_pt(t, V.v2_x(z)))
  +p1 = place_pt(b, axial_pt(t, V.v2_y(z)))
  WA{p0, d, KS.dot(KS.psub(p0, KS.pt(0.0f64, 0.0f64, 0.0f64)), d), KS.dot(KS.psub(p1, KS.pt(0.0f64, 0.0f64, 0.0f64)), d)}

def wa_p(+w: WA) -> V.Point:
  WA{+p, +d, +lo, +hi} = w
  p

def wa_d(+w: WA) -> V.Dir:
  WA{+p, +d, +lo, +hi} = w
  d

def wa_rng(+w: WA, +d: V.Dir) -> V.Vec2:
  WA{+p, +dd, +lo, +hi} = w
  +s0 = KS.dot(KS.psub(p, KS.pt(0.0f64, 0.0f64, 0.0f64)), d)
  +s1 = F64.add(s0, F64.mul(F64.sub(hi, lo), KS.dot(dd, d)))
  V.V2{F64.min(s0, s1), F64.max(s0, s1)}

def coaxial(+a: WA, +b: WA) -> Bool:
  +da = wa_d(a)
  +db = wa_d(b)
  +off = KS.psub(wa_p(b), wa_p(a))
  +perp = KS.dadd(off, F64.neg(KS.dot(off, da)), da)
  +tol = F64.mul(1.0e-9f64, F64.add(1.0f64, KS.dlen(KS.psub(wa_p(a), KS.pt(0.0f64, 0.0f64, 0.0f64)))))
  Bool.and(F64.is_le(KS.dlen(KS.cross(da, db)), 1.0e-12f64), F64.is_le(KS.dlen(perp), tol))

def r6(+x: F64) -> F64:
  F64.div(KS.f_round(F64.mul(x, 1000000.0f64)), 1000000.0f64)

def eng_e(+wa: WA, +wb: WA) -> F64:
  +ra = wa_rng(wa, wa_d(wb))
  +rb = wa_rng(wb, wa_d(wb))
  F64.max(0.0f64, F64.sub(F64.min(V.v2_y(ra), V.v2_y(rb)), F64.max(V.v2_x(ra), V.v2_x(rb))))

def eng_w(+wa: WA, +wb: WA) -> F64:
  +ra = wa_rng(wa, wa_d(wb))
  +rb = wa_rng(wb, wa_d(wb))
  F64.mul(1.0e-12f64, F64.add(1.0f64, F64.max(F64.abs(V.v2_y(ra)), F64.abs(V.v2_y(rb)))))

def eng_line(+na: String, +nb: String, +e: F64, +w: F64, +d: F64) -> String:
  "engage " ++ na ++ " " ++ nb ++ " engagement=[" ++ S.f_show(F64.max(0.0f64, F64.sub(e, w))) ++ ", " ++ S.f_show(F64.add(e, w)) ++
    "] ratio=" ++ S.f_show(r6(F64.div(e, d))) ++ " d=" ++ S.f_show(d) ++ " status=certified"

def eng_k(+code: U64, +na: String, +nb: String, +da: String, +db: String, +wa: WA, +wb: WA, +d: F64) -> String:
  match code:
    case 1u64: "error invalid-input | asm engage | why: thread-designation-mismatch: " ++ da ++ " in " ++ db ++ " | fix: mate threads of one designation"
    case 2u64: "error invalid-input | asm engage | why: threads-not-coaxial: " ++ na ++ " " ++ nb ++ " | fix: place the parts on one axis"
    case _: eng_line(na, nb, eng_e(wa, wb), eng_w(wa, wb), d)

def same_desig(+a: KT.DS, +b: KT.DS) -> Bool:
  Bool.and(F64.is_eq(KT.ds_d(a), KT.ds_d(b)), F64.is_eq(KT.ds_p(a), KT.ds_p(b)))

def engage_go(+sa: A4.IN, +ta: M.Thr, +sb: A4.IN, +tb: M.Thr) -> String:
  +wa = wa_of(M.nr_body(A4.in_nr(sa)), ta)
  +wb = wa_of(M.nr_body(A4.in_nr(sb)), tb)
  +da = KT.desig(KT.th_d(ta))
  +db = KT.desig(KT.th_d(tb))
  +code = Bool.pick(U64, Bool.not(same_desig(da, db)), 1u64, Bool.pick(U64, Bool.not(coaxial(wa, wb)), 2u64, 0u64))
  eng_k(code, A4.in_name(sa) ++ "." ++ KT.th_name(ta), A4.in_name(sb) ++ "." ++ KT.th_name(tb), KT.ds_name(da), KT.ds_name(db), wa, wb, KT.ds_d(da))

def eng_th(ta: Maybe<&2, M.Thr>, tb: Maybe<&2, M.Thr>, +a: A4.IN, +b: A4.IN) -> String:
  match ta:
    case None{}: "error invalid-input | asm engage | why: unknown-thread-feature on " ++ A4.in_name(a) ++ " | fix: name a thread bound with (thread ...)"
    case Some{+x}:
      match tb:
        case None{}: "error invalid-input | asm engage | why: unknown-thread-feature on " ++ A4.in_name(b) ++ " | fix: name a thread bound with (thread ...)"
        case Some{+y}: engage_go(a, x, b, y)


def eng_go(ma: Maybe<&2, A4.IN>, mb: Maybe<&2, A4.IN>, +ts: List<&2, M.Thr>, +xs: List<&2, String>) -> String:
  match ma:
    case None{}: "error invalid-input | asm engage | why: unknown-instance " ++ S.arg_at(xs, 1n) ++ " | fix: asm engage INST THREAD INST THREAD (assembly ...)"
    case Some{+a}:
      match mb:
        case None{}: "error invalid-input | asm engage | why: unknown-instance " ++ S.arg_at(xs, 3n) ++ " | fix: asm engage INST THREAD INST THREAD (assembly ...)"
        case Some{+b}: eng_th(th_find(ts, in_node(a), S.arg_at(xs, 2n)), th_find(ts, in_node(b), S.arg_at(xs, 4n)), a, b)

def part_ms(+p: M.Part) -> List<&2, M.Grade>:
  M.Pt{+ps, +ns, +ms, +ts} = p
  ms

def part_ts(+p: M.Part) -> List<&2, M.Thr>:
  M.Pt{+ps, +ns, +ms, +ts} = p
  ts

def sel_of(xs: List<&2, String>, +i: Nat) -> List<&2, String>:
  match xs:
    case []: []
    case +h <> +t:
      match i:
        case 0n: Bool.pick(List<&2, String>, U32.is_eq(KT.s_head(h), 40), [], h <> sel_of(t, 0n))
        case 1n+j: sel_of(t, j)

def gap_go(ma: Maybe<&2, A4.IN>, mb: Maybe<&2, A4.IN>, +xs: List<&2, String>) -> String:
  match ma:
    case None{}: "error invalid-input | asm gap | why: unknown-instance " ++ S.arg_at(xs, 1n) ++ " | fix: asm gap INST INST [FACE ...] (assembly ...)"
    case Some{+a}:
      match mb:
        case None{}: "error invalid-input | asm gap | why: unknown-instance " ++ S.arg_at(xs, 2n) ++ " | fix: asm gap INST INST [FACE ...] (assembly ...)"
        case Some{+b}: KG.gap_s(A4.in_name(a), A4.in_name(b), KG.traces(M.nr_body(A4.in_nr(a)), []), KG.traces(M.nr_body(A4.in_nr(b)), sel_of(xs, 3n)))

def mesh_go(ma: Maybe<&2, A4.IN>, mb: Maybe<&2, A4.IN>, +xs: List<&2, String>) -> String:
  match ma:
    case None{}: "error invalid-input | asm mesh | why: unknown-instance " ++ S.arg_at(xs, 1n) ++ " | fix: asm mesh INST TEETH INST TEETH (assembly ...)"
    case Some{+a}:
      match mb:
        case None{}: "error invalid-input | asm mesh | why: unknown-instance " ++ S.arg_at(xs, 3n) ++ " | fix: asm mesh INST TEETH INST TEETH (assembly ...)"
        case Some{+b}:
          +ba = M.nr_body(A4.in_nr(a))
          +bb = M.nr_body(A4.in_nr(b))
          KG.mesh_s(A4.in_name(a), A4.in_name(b), KG.traces(ba, []), KG.traces(bb, []), KT.f_of(S.arg_at(xs, 2n)), KT.f_of(S.arg_at(xs, 4n)),
            place_pt(ba, KS.pt(0.0f64, 0.0f64, 0.0f64)), place_pt(bb, KS.pt(0.0f64, 0.0f64, 0.0f64)))

def k2_solved(+code: U64, +p: M.Part, +a: A4.Asm, +ins: List<&2, A4.IN>, +xs: List<&2, String>) -> String:
  match code:
    case 1u64: mass_rep(ins, part_ms(p))
    case 2u64: eng_go(in_find(ins, S.arg_at(xs, 1n)), in_find(ins, S.arg_at(xs, 3n)), part_ts(p), xs)
    case 3u64: gap_go(in_find(ins, S.arg_at(xs, 1n)), in_find(ins, S.arg_at(xs, 2n)), xs)
    case 4u64: mesh_go(in_find(ins, S.arg_at(xs, 1n)), in_find(ins, S.arg_at(xs, 3n)), xs)
    case _: "error invalid-input | asm | why: unknown verb"

def k2_sol(+code: U64, +p: M.Part, +a: A4.Asm, +s: A4.AS, +cs: List<&2, M.CE>, +xs: List<&2, String>) -> String:
  match s:
    case A4.AS_conf{+ids, +res}: A4.conf_rep(a, ids, res)
    case A4.AS_ok{+sx, +dof, +red, +res}: k2_solved(code, p, a, A4.place_all(A4.asm_insts(a), sx, cs, 0n), xs)

def k2_ar(+code: U64, +p: M.Part, +ar: A4.AR, +xs: List<&2, String>) -> String:
  match ar:
    case A4.AR_err{+why, +fix}: "error invalid-input | asm | why: " ++ why ++ " | fix: " ++ fix
    case A4.AR_ok{+a}:
      +cs = M.ev_part(p, [])
      +e = A4.nodes_err(A4.asm_insts(a), A4.asm_mates(a), cs)
      Bool.pick(String, String.eq(e, ""), k2_sol(code, p, a, A4.asm_solve(a, cs), cs, xs), e)

def k2_code(+v: String) -> U64:
  Bool.pick(U64, String.eq(v, "mass"), 1u64, Bool.pick(U64, String.eq(v, "engage"), 2u64,
    Bool.pick(U64, String.eq(v, "gap"), 3u64, Bool.pick(U64, String.eq(v, "mesh"), 4u64, 0u64))))

def k2_skip(xs: List<&2, String>, +i: Nat) -> Nat:
  match xs:
    case []: i
    case +h <> +t: Bool.pick(Nat, U32.is_eq(KT.s_head(h), 40), i, k2_skip(t, Nat.add(i, 1n)))

def k2_asm(+p: M.Part, +xs: List<&2, String>) -> String:
  +code = k2_code(S.arg_at(xs, 0n))
  k2_ar(code, p, A4.asm_parse(A4.cat(A4.sdrop(xs, k2_skip(xs, 0n)))), xs)

type AW is Data:
  AW{ ws: SW.WS, names: String }

def aw_err(+why: String) -> AW:
  AW{SW.WS{False{}, "", why, 0n, 0n}, ""}

def snap9(+x: F64) -> F64:
  F64.div(KS.f_round(F64.mul(x, 1.0e9f64)), 1.0e9f64)

def snap_pl(+p: M.Pl) -> M.Pl:
  M.Pl{+m, +tx, +ty, +tz, +mi, +ti} = p
  +x = snap9(tx)
  +y = snap9(ty)
  +z = snap9(tz)
  M.Pl{m, x, y, z, mi, ti}

def step_ins(ins: List<&2, A4.IN>, +acc: SW.ER2) -> SW.ER2:
  match ins:
    case []: acc
    case +h <> +t:
      +b = M.nr_body(A4.in_nr(h))
      +st = SW.sw_stage(M.bd_brep(b), snap_pl(M.bd_pl(b)), SW.er2_n(acc))
      +r = SW.er2_cat_s(acc, st)
      step_ins(t, SW.sw_sid_cat(SW.er2_ok_of(r), r, acc, st))

def in_names(ins: List<&2, A4.IN>, +acc: String) -> String:
  match ins:
    case []: acc
    case +h <> +t: in_names(t, Bool.pick(String, String.eq(acc, ""), A4.in_name(h), acc ++ "," ++ A4.in_name(h)))

def step_placed(+ins: List<&2, A4.IN>) -> AW:
  +r = step_ins(ins, SW.ER2{True{}, "", "", 1n, []})
  AW{SW.sw_wrap42(r, List.length(&2, A4.IN, ins), "", 0n), in_names(ins, "")}

def step_sol(+s: A4.AS, +a: A4.Asm, +cs: List<&2, M.CE>) -> AW:
  match s:
    case A4.AS_conf{+ids, +res}: aw_err("assembly-conflict: mates cannot all hold")
    case A4.AS_ok{+sx, +dof, +red, +res}: step_placed(A4.place_all(A4.asm_insts(a), sx, cs, 0n))

def step_ok(+ok: Bool, +e: String, +a: A4.Asm, +cs: List<&2, M.CE>) -> AW:
  match ok:
    case False{}: aw_err(e)
    case True{}: step_sol(A4.asm_solve(a, cs), a, cs)

def step_ar(+p: M.Part, +ar: A4.AR) -> AW:
  match ar:
    case A4.AR_err{+why, +fix}: aw_err(why)
    case A4.AR_ok{+a}:
      +cs = M.ev_part(p, [])
      +e = A4.nodes_err(A4.asm_insts(a), A4.asm_mates(a), cs)
      step_ok(String.eq(e, ""), e, a, cs)

def k2_step(+p: M.Part, +xs: List<&2, String>) -> AW:
  step_ar(p, A4.asm_parse(A4.cat(A4.sdrop(xs, k2_skip(xs, 0n)))))
