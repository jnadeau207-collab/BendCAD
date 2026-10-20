import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c06/sx.bend as SX
import ../c07/sol.bend as SO
import ../c07/emb.bend as EM
import ../c07/ivx.bend as X
import ../c08/bool.bend as BO
import ../base/par.bend as B
import ./qaccel.bend as QA
import ./qmass.bend as QM

type Ag is Data:
  Ag{ nin: Nat, nout: Nat, nunc: Nat }

def loc_c(+mi: List<&2, I.I>, +w: List<&2, I.I>, +j: Nat) -> F64:
  I.imid(I.iadd(I.iadd(I.imul(M.i_nth(mi, j), M.i_nth(w, 0n)), I.imul(M.i_nth(mi, Nat.add(j, 3n)), M.i_nth(w, 1n))), I.imul(M.i_nth(mi, Nat.add(j, 6n)), M.i_nth(w, 2n))))

def w3(+ti: List<&2, I.I>, +x: F64, +y: F64, +z: F64) -> List<&2, I.I>:
  [I.isub(I.ipt(x), M.i_nth(ti, 0n)), I.isub(I.ipt(y), M.i_nth(ti, 1n)), I.isub(I.ipt(z), M.i_nth(ti, 2n))]

def loc_w(+mi: List<&2, I.I>, +w: List<&2, I.I>) -> V.Point:
  V.Pt{loc_c(mi, w, 0n), loc_c(mi, w, 1n), loc_c(mi, w, 2n)}

def loc_pt(+p: M.Pl, +x: F64, +y: F64, +z: F64) -> V.Point:
  loc_w(M.pl_mi(p), w3(M.pl_ti(p), x, y, z))

def cls_s(+r: U64) -> String:
  Bool.pick(String, U64.is_eq(r, 0u64), "outside", Bool.pick(String, U64.is_eq(r, 1u64), "inside", Bool.pick(String, U64.is_eq(r, 3u64), "boundary", "uncertain | why: every ray met a tangency, an edge or an unsupported face | fix: move the point off the boundary")))

def fin3(+x: F64, +y: F64, +z: F64) -> Bool:
  Bool.and(T.is_finite(x), Bool.and(T.is_finite(y), T.is_finite(z)))

def classify_bd(ok: Bool, +b: M.Body, +x: F64, +y: F64, +z: F64) -> String:
  match ok:
    case False{}: "error invalid-input | classify | why: the point needs three finite numbers | fix: classify NODE X Y Z"
    case True{}: cls_s(SO.classify(SO.fds_of(M.bd_brep(b)), loc_pt(M.bd_pl(b), x, y, z)))

def classify_s(r: M.NR, +x: F64, +y: F64, +z: F64) -> String:
  match r:
    case M.NR_err{k, d}: "error: node failed; nothing classified"
    case M.NR_ok{+b, fx}:
      Bool.pick(String, M.bd_open(b), "refused classify-needs-solid | classify | fix: thicken-open the shell to a solid first",
        classify_bd(fin3(x, y, z), b, x, y, z))

def fi_s(fs: List<&2, SO.Fi>) -> String:
  match fs:
    case []: ""
    case f <> t:
      SO.Fi{c, a, b} = f
      c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "
" ++ fi_s(t)

def fi_real_go(fs: List<&2, SO.Fi>, +acc: List<&2, SO.Fi>) -> List<&2, SO.Fi>:
  match fs:
    case []: acc
    case SO.Fi{+c, +a, +b} <> t:
      fi_real_go(t, Bool.pick(List<&2, SO.Fi>, BO.is_contact(c), acc, SO.Fi{c, a, b} <> acc))

def fi_real(fs: List<&2, SO.Fi>) -> List<&2, SO.Fi>:
  List.reverse(&2, SO.Fi, fi_real_go(fs, []))

def check_bd(+b: M.Body) -> String:
  +br = M.bd_brep(b)
  +fd = SO.fds_of(br)
  +fs = fi_real(List.append(&2, SO.Fi, SO.solid_fi(br, fd), EM.emb_fi(br, fd)))
  +cc = BO.coin_contact(br)
  Bool.pick(String, Bool.not(BO.CR_ok(cc)),
    "coincident-vertices " ++ Nat.show(BO.CR_a(cc)) ++ " " ++ Nat.show(BO.CR_b(cc)) ++
      " within one solid",
    Bool.pick(String, Nat.is_eq(List.length(&2, SO.Fi, fs), 0n),
      "ok: embedded, shells outward, cavities nested", fi_s(fs)))

def check_s(r: M.NR) -> String:
  match r:
    case M.NR_err{k, d}: "error: node failed; nothing checked"
    case M.NR_ok{+b, fx}:
      Bool.pick(String, M.bd_open(b), "refused check-needs-solid | check | fix: thicken-open the shell to a solid first",
        check_bd(b))

def wbox(+b: M.Body) -> QA.Ab:
  +m = M.body_ms(b)
  QA.Ab{M.ms_x0(m), M.ms_x1(m), M.ms_y0(m), M.ms_y1(m), M.ms_z0(m), M.ms_z1(m)}

def wpts(xs: List<&2, BO.SM>, +mi: List<&2, I.I>, +ti: List<&2, I.I>) -> List<&2, V.Point>:
  match xs:
    case []: []
    case BO.SM{+q, +s} <> t: QA.ab_wpt(mi, ti, q) <> wpts(t, mi, ti)

def sms_of(+b: M.Body) -> List<&2, V.Point>:
  +br = M.bd_brep(b)
  +pl = M.bd_pl(b)
  wpts(BO.sm_of(br, Ty.brep_sos(br), 0n), M.pl_mi(pl), M.pl_ti(pl))

def ag_zero() -> Ag:
  Ag{0n, 0n, 0n}

def ag_add(+a: Ag, +c: U64) -> Ag:
  Ag{+nin, +nout, +nunc} = a
  Bool.pick(Ag, U64.is_eq(c, 1u64), Ag{Nat.add(nin, 1n), nout, nunc},
    Bool.pick(Ag, U64.is_eq(c, 0u64), Ag{nin, Nat.add(nout, 1n), nunc}, Ag{nin, nout, Nat.add(nunc, 1n)}))

def ag_classify(ps: List<&2, V.Point>, +fs: List<&2, SO.Fd>, +bb: List<&2, I.I>, +p: M.Pl,
    +acc: Ag) -> Ag:
  match ps:
    case []: acc
    case V.Pt{+x, +y, +z} <> t: ag_classify(t, fs, bb, p, ag_add(acc, SO.classify_in(fs, bb, loc_pt(p, x, y, z))))

def ag_of(+b: M.Body, ps: List<&2, V.Point>) -> Ag:
  +fs = SO.fds_of(M.bd_brep(b))
  ag_classify(ps, fs, SO.bbox(fs, []), M.bd_pl(b), ag_zero())

def wov_bx(+a: QA.Ab, +b: QA.Ab) -> List<&2, I.I>:
  [I.I{F64.max(QA.ab_x0(a), QA.ab_x0(b)), F64.min(QA.ab_x1(a), QA.ab_x1(b))},
    I.I{F64.max(QA.ab_y0(a), QA.ab_y0(b)), F64.min(QA.ab_y1(a), QA.ab_y1(b))},
    I.I{F64.max(QA.ab_z0(a), QA.ab_z0(b)), F64.min(QA.ab_z1(a), QA.ab_z1(b))}]

def wit_hit(+c: List<&2, I.I>, +fa: List<&2, SO.Fd>, +ba: List<&2, I.I>, +pa: M.Pl,
    +fb: List<&2, SO.Fd>, +bb: List<&2, I.I>, +pb: M.Pl) -> Bool:
  +x = I.imid(X.vn(c, 0n))
  +y = I.imid(X.vn(c, 1n))
  +z = I.imid(X.vn(c, 2n))
  Bool.and(U64.is_eq(SO.classify_in(fa, ba, loc_pt(pa, x, y, z)), 1u64),
    U64.is_eq(SO.classify_in(fb, bb, loc_pt(pb, x, y, z)), 1u64))

def wit_map(cs: List<&2, List<&2, I.I>>, +fa: List<&2, SO.Fd>, +ba: List<&2, I.I>, +pa: M.Pl,
    +fb: List<&2, SO.Fd>, +bb: List<&2, I.I>, +pb: M.Pl) -> List<&2, Bool>:
  match cs:
    case []: []
    case +c <> t: wit_hit(c, fa, ba, pa, fb, bb, pb) <> wit_map(t, fa, ba, pa, fb, bb, pb)

def wit_any(bs: List<&2, Bool>) -> Bool:
  match bs:
    case []: False{}
    case +h <> t: Bool.or(h, wit_any(t))

def wit_batch_go(cs: List<&2, List<&2, I.I>>) -> List<&2, List<&2, List<&2, I.I>>>:
  match cs:
    case []: []
    case +c <> t: QM.sub_go(1n, [c]) <> wit_batch_go(t)

def wit_batches(+bss: List<&2, List<&2, List<&2, I.I>>>, +hit: Bool, +fa: List<&2, SO.Fd>,
    +ba: List<&2, I.I>, +pa: M.Pl, +fb: List<&2, SO.Fd>, +bb: List<&2, I.I>, +pb: M.Pl) -> Bool:
  match bss:
    case []: hit
    case +bs <> t:
      match hit:
        case True{}: True{}
        case False{}: wit_batches(t, wit_any(wit_map(bs, fa, ba, pa, fb, bb, pb)), fa, ba, pa, fb, bb, pb)

def wit_line(wit: Bool, +fb: String) -> String:
  match wit:
    case True{}: "relation interference status=certified witness=subdiv"
    case False{}: fb

def fd_abs(fs: List<&2, SO.Fd>, +p: M.Pl) -> List<&2, QA.Ab>:
  match fs:
    case []: []
    case f <> t: QA.ab_world(QA.ab_of_iv(SO.fd_bx(f)), p) <> fd_abs(t, p)

def any_ov(bs: List<&2, QA.Ab>, +t: QA.Bvh, +tb: B.Tb<&2, QA.Ab>) -> Bool:
  match bs:
    case []: False{}
    case b <> rest: Bool.pick(Bool, QA.bvh_has(t, b, tb), True{}, any_ov(rest, t, tb))

def shells_ov(+fa: List<&2, SO.Fd>, +pa: M.Pl, +fb: List<&2, SO.Fd>, +pb: M.Pl) -> Bool:
  +bb = fd_abs(fb, pb)
  +tb = B.tb_of(QA.Ab, bb, QA.ab_zero())
  any_ov(fd_abs(fa, pa), QA.bvh_build(bb), tb)

def shells_ov_go(ok: Bool, +fa: List<&2, SO.Fd>, +pa: M.Pl, +fb: List<&2, SO.Fd>, +pb: M.Pl) -> Bool:
  match ok:
    case False{}: True{}
    case True{}: shells_ov(fa, pa, fb, pb)

def box_in_box(+a: QA.Ab, +b: QA.Ab) -> Bool:
  Bool.and(F64.is_le(QA.ab_x0(b), QA.ab_x0(a)),
    Bool.and(F64.is_le(QA.ab_x1(a), QA.ab_x1(b)),
      Bool.and(F64.is_le(QA.ab_y0(b), QA.ab_y0(a)),
        Bool.and(F64.is_le(QA.ab_y1(a), QA.ab_y1(b)),
          Bool.and(F64.is_le(QA.ab_z0(b), QA.ab_z0(a)), F64.is_le(QA.ab_z1(a), QA.ab_z1(b)))))))

def ag_counts(+ai: Nat, +ao: Nat, +au: Nat, +bi: Nat, +bo: Nat, +bu: Nat) -> String:
  "a:in=" ++ Nat.show(ai) ++ " out=" ++ Nat.show(ao) ++ " uncertain=" ++ Nat.show(au) ++ " b:in=" ++
    Nat.show(bi) ++ " out=" ++ Nat.show(bo) ++ " uncertain=" ++ Nat.show(bu)

def ain_go(+ov: Bool, +cont: Bool, +ai: Nat, +ao: Nat, +au: Nat, +bi: Nat, +bu: Nat) -> Bool:
  Bool.and(Nat.is_eq(Nat.add(ao, au), 0n),
    Bool.and(Nat.is_eq(Nat.add(bi, bu), 0n),
      Bool.and(Nat.is_lt(0n, ai), Bool.and(Bool.not(ov), cont))))

def in_either(+ov: Bool, +ainb: Bool, +bina: Bool, aa: Ag, bb: Ag) -> Bool:
  Ag{+ai, +ao, +au} = aa
  Ag{+bi, +bo, +bu} = bb
  Bool.or(ain_go(ov, ainb, ai, ao, au, bi, bu), ain_go(ov, bina, bi, bo, bu, ai, au))

def rel_vb(+box_dis: Bool, +ov: Bool, +ainb: Bool, +bina: Bool, +ai: Nat, +ao: Nat, +au: Nat,
    bb: Ag) -> String:
  Ag{+bi, +bo, +bu} = bb
  Bool.pick(String, box_dis, "relation disjoint status=certified",
    Bool.pick(String, ain_go(ov, ainb, ai, ao, au, bi, bu), "relation inside a-in-b status=certified",
      Bool.pick(String, ain_go(ov, bina, bi, bo, bu, ai, au), "relation inside b-in-a status=certified",
        Bool.pick(String, Bool.or(Nat.is_lt(0n, ai), Nat.is_lt(0n, bi)),
          "relation interference status=certified " ++ ag_counts(ai, ao, au, bi, bo, bu),
          Bool.pick(String,
            Bool.and(Bool.not(ov),
              Bool.and(Nat.is_eq(Nat.add(ai, au), 0n), Nat.is_eq(Nat.add(bi, bu), 0n))),
            "relation disjoint status=certified",
            "relation uncertain status=estimated " ++ ag_counts(ai, ao, au, bi, bo, bu) ++
              " boxes-overlap=" ++ Bool.pick(String, ov, "1", "0"))))))

def ag_nin(+a: Ag) -> Nat:
  Ag{nin, nout, nunc} = a
  nin

def shells_overlap(+a: M.Body, +b: M.Body) -> Bool:
  +fa = SO.fds_of(M.bd_brep(a))
  +fb = SO.fds_of(M.bd_brep(b))
  shells_ov_go(Bool.and(QA.fd_allok(fa), QA.fd_allok(fb)), fa, M.bd_pl(a), fb, M.bd_pl(b))

def wit_go(+ovl: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> Bool:
  match ovl:
    case False{}: False{}
    case True{}:
      +fa = SO.fds_of(M.bd_brep(a))
      +fb = SO.fds_of(M.bd_brep(b))
      +aa = ag_of(b, sms_of(a))
      +bb = ag_of(a, sms_of(b))
      Bool.and(wit_batches(wit_batch_go(QM.sub_go(3n, [wov_bx(wa, wb)])), False{}, fa,
          SO.bbox(fa, []), M.bd_pl(a), fb, SO.bbox(fb, []), M.bd_pl(b)),
        Bool.not(in_either(shells_overlap(a, b), box_in_box(wa, wb), box_in_box(wb, wa), aa, bb)))

def rel_interf_go(dis: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> Bool:
  match dis:
    case True{}: False{}
    case False{}:
      +aa = ag_of(b, sms_of(a))
      +bb = ag_of(a, sms_of(b))
      Bool.or(wit_go(True{}, a, b, wa, wb),
        Bool.and(Bool.or(Nat.is_lt(0n, ag_nin(aa)), Nat.is_lt(0n, ag_nin(bb))),
          Bool.not(in_either(shells_overlap(a, b), box_in_box(wa, wb), box_in_box(wb, wa), aa, bb))))

def rel_interf(+a: M.Body, +b: M.Body) -> Bool:
  +wa = wbox(a)
  +wb = wbox(b)
  rel_interf_go(QA.ab_disjoint(wa, wb), a, b, wa, wb)

def cav_boxes_go(fs: List<&2, SO.Fd>, +p: M.Pl, +wb: QA.Ab) -> List<&2, QA.Ab>:
  match fs:
    case []: []
    case +f <> t:
      Bool.pick(QA.Ab, SO.fd_ok(f), QA.ab_world(QA.ab_of_iv(SO.fd_bx(f)), p), wb) <> cav_boxes_go(t, p, wb)

def cavs_disjoint(+cb: List<&2, QA.Ab>, +db: List<&2, QA.Ab>) -> Bool:
  +tb = B.tb_of(QA.Ab, db, QA.ab_zero())
  Bool.not(any_ov(cb, QA.bvh_build(db), tb))

def cav_line(+r: U64, +nov: Bool, +c: Nat, +o: Nat) -> String:
  Bool.pick(String, Bool.and(U64.is_eq(r, 1u64), nov), "cavity " ++ Nat.show(c) ++ " inside " ++ Nat.show(o) ++ " status=certified",
    Bool.pick(String, U64.is_eq(r, 0u64), "cavity " ++ Nat.show(c) ++ " outside " ++ Nat.show(o) ++ " status=certified",
      "cavity " ++ Nat.show(c) ++ " nesting-uncertain " ++ Nat.show(o) ++ " status=estimated"))

def cav_rest_cons(eq: Bool, +d: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match eq:
    case True{}: acc
    case False{}: d <> acc

def cav_rest(cs: List<&2, Ty.HShell>, +c: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match cs:
    case []: acc
    case h <> t:
      Ty.HS{+d, +g} = h
      cav_rest(t, c, cav_rest_cons(Nat.is_eq(d, c), d, acc))

def cav_pair_line(+r: U64, +nov: Bool, +c: Nat, +d: Nat) -> String:
  Bool.pick(String, Bool.and(U64.is_eq(r, 0u64), nov), "cavities " ++ Nat.show(c) ++ " " ++ Nat.show(d) ++ " disjoint status=certified\n",
    Bool.pick(String, U64.is_eq(r, 1u64), "cavities " ++ Nat.show(c) ++ " " ++ Nat.show(d) ++ " nested status=certified\n",
      "cavities " ++ Nat.show(c) ++ " " ++ Nat.show(d) ++ " uncertain status=estimated\n"))

def cav_class(m: Maybe<&2, List<&2, I.I>>, +sub: List<&2, SO.Fd>) -> U64:
  match m:
    case None{}: 2u64
    case Some{q}: SO.classify_in(sub, SO.bbox(sub, []), SO.pt_of(q))

def rel_verdict(+box_dis: Bool, +ov: Bool, +ainb: Bool, +bina: Bool, +aa: Ag, +bb: Ag) -> String:
  Ag{+ai, +ao, +au} = aa
  rel_vb(box_dis, ov, ainb, bina, ai, ao, au, bb)

def rel_sample(+a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:
  wit_line(wit_go(True{}, a, b, wa, wb),
    rel_verdict(False{}, shells_overlap(a, b), box_in_box(wa, wb), box_in_box(wb, wa), ag_of(b, sms_of(a)), ag_of(a, sms_of(b))))

def s_pre(a: String, b: String) -> Bool:
  match a b:
    case SNil{} SNil{}: True{}
    case SNil{} SCon{bh, bt}: False{}
    case SCon{ah, at} SNil{}: True{}
    case SCon{ah, at} SCon{bh, bt}: Bool.and(U32.is_eq(SX.chr_code(ah), SX.chr_code(bh)), s_pre(at, bt))

def iv_txt(+v: I.I) -> String:
  "[" ++ F64.show(I.i_lo(v)) ++ ", " ++ F64.show(I.i_hi(v)) ++ "]"

def ex_hit(+smp: String, +vol: I.I, +proof: String) -> String:
  Bool.pick(String, s_pre(smp, "relation uncertain"),
    "relation interference status=certified method=exact-intersection volume=" ++ iv_txt(vol) ++ " " ++ proof,
    smp)

def ex_some(empty: Bool, +vol: I.I, +proof: String, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:
  match empty:
    case True{}: "relation disjoint status=certified method=exact-intersection"
    case False{}: ex_hit(rel_sample(a, b, wa, wb), vol, proof)

def ex_sel(ok: Bool, +vol: I.I, +proof: String, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:
  match ok:
    case False{}: rel_sample(a, b, wa, wb)
    case True{}: ex_some(F64.is_le(I.i_hi(vol), 0.0f64), vol, proof, a, b, wa, wb)

def ex_go(r: BO.Out, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:
  BO.Out{ok, kind, what, loc, why, fix, carry, brep, cells, fns, rv, nc, +vol, area, bb, lin, hasm, mat, fc, fm, sh, ho, nct, +proof, del} = r
  ex_sel(ok, vol, proof, a, b, wa, wb)

def rel_pair_go(dis: Bool, +a: M.Body, +b: M.Body, +wa: QA.Ab, +wb: QA.Ab) -> String:
  match dis:
    case True{}: "relation disjoint status=certified"
    case False{}: ex_go(BO.run(BO.tag_inter(), M.bool_in(a), M.bool_in(b), 0u64, 0u64, 0u64, False{}), a, b, wa, wb)

def cav_boxes(+fs: List<&2, SO.Fd>, +s: Nat, +p: M.Pl, +wb: QA.Ab) -> List<&2, QA.Ab>:
  cav_boxes_go(SO.of_sh(fs, s), p, wb)

def cav_vs2(ds: List<&2, Nat>, +fs: List<&2, SO.Fd>, +p: M.Pl, +c: Nat, +cb: List<&2, QA.Ab>,
    +wb: QA.Ab) -> String:
  match ds:
    case []: ""
    case +d <> t:
      +sub = SO.of_sh(fs, d)
      +r = cav_class(SO.ip_q(SO.ip_find(fs, None{}, c, 0n)), sub)
      +nov = cavs_disjoint(cb, cav_boxes(fs, d, p, wb))
      cav_pair_line(r, nov, c, d) ++ cav_vs2(t, fs, p, c, cb, wb)

def cav_go(cs: List<&2, Ty.HShell>, +all: List<&2, Ty.HShell>, +fs: List<&2, SO.Fd>, +p: M.Pl, +o: Nat,
    +wb: QA.Ab) -> String:
  match cs:
    case []: ""
    case h <> t:
      Ty.HS{+c, +g} = h
      +out = SO.of_sh(fs, o)
      +cb = cav_boxes(fs, c, p, wb)
      cav_line(cav_class(SO.ip_q(SO.ip_find(fs, None{}, c, 0n)), out), cavs_disjoint(cb, cav_boxes(fs, o, p, wb)), c, o) ++ "\n" ++
        cav_vs2(cav_rest(all, c, []), fs, p, c, cb, wb) ++ cav_go(t, all, fs, p, o, wb)

def cav_solid(s: Ty.Solid, +fs: List<&2, SO.Fd>, +p: M.Pl, +wb: QA.Ab) -> String:
  Ty.So{g, o, +cs} = s
  Ty.HS{+oi, +og} = o
  cav_go(cs, cs, fs, p, oi, wb)

def cav_solids(ss: List<&2, Ty.Solid>, +fs: List<&2, SO.Fd>, +p: M.Pl, +wb: QA.Ab) -> String:
  match ss:
    case []: ""
    case s <> t: cav_solid(s, fs, p, wb) ++ cav_solids(t, fs, p, wb)

def cav_exact(+b: M.Body) -> String:
  +br = M.bd_brep(b)
  cav_solids(Ty.brep_sos(br), SO.fds_of(br), M.bd_pl(b), wbox(b))

def rel_pair(+a: M.Body, +b: M.Body) -> String:
  +wa = wbox(a)
  +wb = wbox(b)
  +dis = QA.ab_disjoint(wa, wb)
  rel_pair_go(dis, a, b, wa, wb)

def rel_s(ra: M.NR, rb: M.NR) -> String:
  match ra:
    case M.NR_err{k, d}: "error: node failed; nothing compared"
    case M.NR_ok{+a, fa}:
      match rb:
        case M.NR_err{k, d}: "error: node failed; nothing compared"
        case M.NR_ok{+b, fb}:
          Bool.pick(String, Bool.or(M.bd_open(a), M.bd_open(b)),
            "refused interf-needs-solid | interf | fix: thicken-open the shell to a solid first",
            cav_exact(a) ++ cav_exact(b) ++ rel_pair(a, b))
