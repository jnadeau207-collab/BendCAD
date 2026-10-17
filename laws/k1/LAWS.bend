import Base
import ../../src/k1/core.bend as K
import ../../src/c08/bool.bend as B

type Rl is Data:
  R_dis{}
  R_tra{}
  R_par{}
  R_cop{}
  R_coa{}
  R_tan{}
  R_cyl{}
  R_cpar{}

type Pr is Data:
  P_par{}
  P_perp{}
  P_ang{}

type Op is Data:
  O_union{}
  O_diff{}
  O_inter{}

type Fc is Data:
  F_out{}
  F_in{}
  F_same{}
  F_opp{}
  F_unc{}
  F_coin{}

type Sd is Data:
  S_a{}
  S_b{}

type St is Data:
  St_in{}
  St_out{}

type Ck is Data:
  C_none{}
  C_line{}
  C_circle{}
  C_segs{}
  C_ring{}

def rel(+r: Rl) -> U64:
  match r:
    case R_dis{}: K.rel_disjoint()
    case R_tra{}: K.rel_transverse()
    case R_par{}: K.rel_parallel()
    case R_cop{}: K.rel_coplanar()
    case R_coa{}: K.rel_coaxial()
    case R_tan{}: K.rel_tangent()
    case R_cyl{}: K.rel_cylcoin()
    case R_cpar{}: K.rel_cylpar()

def pr(+p: Pr) -> U64:
  match p:
    case P_par{}: K.pp_parallel()
    case P_perp{}: K.pp_perp()
    case P_ang{}: K.pp_angled()

def tag(+o: Op) -> U64:
  match o:
    case O_union{}: B.tag_union()
    case O_diff{}: B.tag_diff()
    case O_inter{}: B.tag_inter()

def fc(+c: Fc) -> U64:
  match c:
    case F_out{}: K.fc_out()
    case F_in{}: K.fc_in()
    case F_same{}: K.fc_same()
    case F_opp{}: K.fc_opp()
    case F_unc{}: K.fc_unc()
    case F_coin{}: K.fc_coin()

def side(+s: Sd) -> U64:
  match s:
    case S_a{}: 0u64
    case S_b{}: 1u64

def st_cls(+s: St) -> U64:
  match s:
    case St_in{}: K.cls_in()
    case St_out{}: K.cls_out()

def st_fc(+s: St) -> U64:
  match s:
    case St_in{}: K.fc_in()
    case St_out{}: K.fc_out()

def ck(+c: Ck) -> U64:
  match c:
    case C_none{}: K.ck_none()
    case C_line{}: K.ck_line()
    case C_circle{}: K.ck_circle()
    case C_segs{}: K.ck_segs()
    case C_ring{}: K.ck_ring()

def spec_pp(+r: Rl) -> U64:
  match r:
    case R_cop{}: K.dec_pack(True{}, True{}, K.ck_segs(), K.kr_ok())
    case R_tra{}: K.dec_pack(True{}, True{}, K.ck_line(), K.kr_ok())
    case _: K.dec_none()

def spec_pc(+r: Rl, +p: Pr) -> U64:
  match r p:
    case R_tra{} P_perp{}: K.dec_pack(True{}, True{}, K.ck_circle(), K.kr_ok())
    case R_tra{} P_par{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_thetacut())
    case R_tra{} P_ang{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_angled())
    case _ _: K.dec_none()

def spec_pq(+r: Rl, +c: Bool, +p: Pr) -> U64:
  match r c p:
    case R_tra{} True{} P_par{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_thetacut())
    case R_tra{} True{} P_ang{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_angled())
    case R_tra{} True{} P_perp{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_curvedside())
    case R_tra{} False{} _: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_curvedside())
    case _ _ _: K.dec_none()

def spec_cc(+r: Rl) -> U64:
  match r:
    case R_cyl{}: K.dec_pack(True{}, True{}, K.ck_circle(), K.kr_ok())
    case R_cpar{}: K.dec_pack(True{}, True{}, K.ck_none(), K.kr_ok())
    case R_tra{}: K.dec_pack(True{}, True{}, K.ck_ring(), K.kr_ok())
    case _: K.dec_none()

def spec_gen(+r: Rl) -> U64:
  match r:
    case R_tra{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_curvedside())
    case R_cyl{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_thetacut())
    case R_cpar{}: K.dec_pack(False{}, False{}, K.ck_none(), K.kr_thetacut())
    case _: K.dec_none()

def spec_strict(+o: Op, +s: Sd, +c: St) -> U64:
  match o s c:
    case O_diff{} S_b{} St_in{}: 1u64
    case O_diff{} S_b{} St_out{}: 0u64
    case _ _ _: B.keep_frag(tag(o), st_fc(c))

def spec_pm(+o: Op, +s: Sd) -> U64:
  match o s:
    case O_diff{} S_a{}: 1u64
    case _ _: 0u64

def spec_mp(+o: Op, +s: Sd) -> U64:
  match o s:
    case O_union{} S_a{}: 1u64
    case O_inter{} S_a{}: 1u64
    case _ _: 0u64

def spec_flip(+o: Op, +s: Sd) -> Bool:
  match o s:
    case O_diff{} S_b{}: True{}
    case _ _: False{}

law pp_table:
  for +r: Rl
  {K.pk_pp(rel(r)) == spec_pp(r) : U64}

law pc_table:
  for +r: Rl
  for +p: Pr
  {K.pk_pc(rel(r), pr(p)) == spec_pc(r, p) : U64}

law pq_table:
  for +r: Rl
  for +c: Bool
  for +p: Pr
  {K.pk_pq(rel(r), c, pr(p)) == spec_pq(r, c, p) : U64}

law cc_table:
  for +r: Rl
  {K.pk_cc(rel(r)) == spec_cc(r) : U64}

law gen_table:
  for +r: Rl
  {K.pk_gen(rel(r)) == spec_gen(r) : U64}

law keep_matches_c08:
  for +o: Op
  for +c: Fc
  {K.kkeep(tag(o), fc(c)) == B.keep_frag(tag(o), fc(c)) : U64}

law frag_strict:
  for +o: Op
  for +s: Sd
  for +c: St
  {K.kfrag(tag(o), side(s), st_cls(c), K.cls_unc(), K.cls_unc()) == spec_strict(o, s, c) : U64}

law frag_coin_pm:
  for +o: Op
  for +s: Sd
  {K.kfrag(tag(o), side(s), 3u64, K.cls_in(), K.cls_out()) == spec_pm(o, s) : U64}

law frag_coin_mp:
  for +o: Op
  for +s: Sd
  {K.kfrag(tag(o), side(s), 3u64, K.cls_out(), K.cls_in()) == spec_mp(o, s) : U64}

law frag_uncertain:
  for +o: Op
  for +s: Sd
  {K.kfrag(tag(o), side(s), K.cls_unc(), K.cls_unc(), K.cls_unc()) == 2u64 : U64}

law frag_graze:
  for +o: Op
  for +s: Sd
  for +c: St
  {K.kfrag(tag(o), side(s), 3u64, st_cls(c), st_cls(c)) == spec_strict(o, s, c) : U64}

law flip_diff_tool:
  for +o: Op
  for +s: Sd
  {K.kflip(tag(o), side(s)) == spec_flip(o, s) : Bool}

def spec_band_lo(+flip: Bool, +same: Bool, +pos: Bool) -> Bool:
  match flip same pos:
    case False{} False{} False{}: True{}
    case False{} False{} True{}: False{}
    case False{} True{} False{}: False{}
    case False{} True{} True{}: True{}
    case True{} False{} False{}: False{}
    case True{} False{} True{}: True{}
    case True{} True{} False{}: True{}
    case True{} True{} True{}: False{}

def spec_band_hi(+flip: Bool, +same: Bool, +pos: Bool) -> Bool:
  match flip same pos:
    case False{} False{} False{}: False{}
    case False{} False{} True{}: True{}
    case False{} True{} False{}: True{}
    case False{} True{} True{}: False{}
    case True{} False{} False{}: True{}
    case True{} False{} True{}: False{}
    case True{} True{} False{}: False{}
    case True{} True{} True{}: True{}

law band_fw_lo:
  for +flip: Bool
  for +same: Bool
  for +pos: Bool
  {K.band_fw_lo(K.band_sm(flip, same), pos) == spec_band_lo(flip, same, pos) : Bool}

law band_fw_hi:
  for +flip: Bool
  for +same: Bool
  for +pos: Bool
  {K.band_fw_hi(K.band_sm(flip, same), pos) == spec_band_hi(flip, same, pos) : Bool}

law dec_curve_roundtrip:
  for +a: Bool
  for +b: Bool
  for +c: Ck
  {K.dec_curve(K.dec_pack(a, b, ck(c), K.kr_ok())) == ck(c) : U64}

law dec_splitA_roundtrip:
  for +a: Bool
  for +b: Bool
  for +c: Ck
  {K.dec_splitA(K.dec_pack(a, b, ck(c), K.kr_ok())) == a : Bool}

law dec_splitB_roundtrip:
  for +a: Bool
  for +b: Bool
  for +c: Ck
  {K.dec_splitB(K.dec_pack(a, b, ck(c), K.kr_ok())) == b : Bool}
