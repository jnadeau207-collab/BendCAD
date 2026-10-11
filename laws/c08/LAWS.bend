import Base
import ../../src/c08/bool.bend as B

type BOp is Data:
  O_union{}
  O_diff{}
  O_inter{}

type Cfg is Data:
  C_apart{}
  C_a_in_b{}
  C_b_in_a{}
  C_crossing{}

type Res is Data:
  R_carry_a{}
  R_carry_b{}
  R_both{}
  R_empty{}
  R_cavity{}
  R_fail{}
  R_continue{}

def tag(o: BOp) -> U64:
  match o:
    case O_union{}: B.tag_union()
    case O_diff{}: B.tag_diff()
    case O_inter{}: B.tag_inter()

def dec(c: Cfg) -> U64:
  match c:
    case C_apart{}: B.dec_sep()
    case C_a_in_b{}: B.dec_ainb()
    case C_b_in_a{}: B.dec_bina()
    case C_crossing{}: 3u64

def res_code(r: Res) -> U64:
  match r:
    case R_carry_a{}: 0u64
    case R_carry_b{}: 1u64
    case R_both{}: 2u64
    case R_empty{}: 3u64
    case R_cavity{}: 4u64
    case R_fail{}: 5u64
    case R_continue{}: 10u64

def regularized(o: BOp, c: Cfg) -> Res:
  match o c:
    case O_union{} C_apart{}: R_both{}
    case O_union{} C_a_in_b{}: R_carry_b{}
    case O_union{} C_b_in_a{}: R_carry_a{}
    case O_diff{} C_apart{}: R_carry_a{}
    case O_diff{} C_a_in_b{}: R_empty{}
    case O_diff{} C_b_in_a{}: R_cavity{}
    case O_inter{} C_apart{}: R_empty{}
    case O_inter{} C_a_in_b{}: R_carry_a{}
    case O_inter{} C_b_in_a{}: R_carry_b{}
    case _ C_crossing{}: R_fail{}

def with_empty(ea: Bool, eb: Bool, same: Bool, o: BOp) -> Res:
  match ea eb:
    case True{} True{}: R_empty{}
    case True{} False{}:
      match same o:
        case True{} O_diff{}: R_empty{}
        case True{} _: R_carry_a{}
        case False{} O_union{}: R_carry_b{}
        case False{} _: R_empty{}
    case False{} True{}:
      match same o:
        case True{} O_diff{}: R_empty{}
        case True{} _: R_carry_a{}
        case False{} O_inter{}: R_empty{}
        case False{} _: R_carry_a{}
    case False{} False{}:
      match same o:
        case True{} O_diff{}: R_empty{}
        case True{} _: R_carry_a{}
        case False{} _: R_continue{}

law outcome_is_regularized:
  for +o: BOp
  for +c: Cfg
  {B.outcome(tag(o), dec(c)) == res_code(regularized(o, c)) : U64}

law empty_algebra:
  for +o: BOp
  for +ea: Bool
  for +eb: Bool
  for +same: Bool
  {B.empty_outcome(tag(o), ea, eb, same) == res_code(with_empty(ea, eb, same, o)) : U64}

law uncertain_fragment_fails:
  for o: BOp
  {B.keep_frag(tag(o), B.fc_unc()) == 2u64 : U64}
