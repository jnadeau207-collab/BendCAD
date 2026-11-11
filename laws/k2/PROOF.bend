import Base
import ../../src/c06/iv.bend as I
import ../../src/k2/fit.bend as F
import ./LAWS.bend as Laws

def and_assoc(a: Bool, b: Bool, c: Bool) -> {Bool.and(a, Bool.and(b, c)) == Bool.and(Bool.and(a, b), c) : Bool}:
  match a:
    case False{}:
      {==}
    case True{}:
      {==}

def neg_zz(t: List<&2, I.I>, b: Bool) -> {Bool.and(b, F.all_neg_zz(t, True{})) == F.all_neg_zz(t, b) : Bool}:
  match t b:
    case _ True{}:
      {==}
    case Nil{} False{}:
      {==}
    case Con{h, u} False{}:
      {==}

def pos_zz(t: List<&2, I.I>, b: Bool) -> {Bool.and(b, F.all_pos_zz(t, True{})) == F.all_pos_zz(t, b) : Bool}:
  match t b:
    case _ True{}:
      {==}
    case Nil{} False{}:
      {==}
    case Con{h, u} False{}:
      {==}

def mixed_zz(t: List<&2, I.I>, b: Bool) -> {Bool.and(b, F.all_mixed_zz(t, True{})) == F.all_mixed_zz(t, b) : Bool}:
  match t b:
    case _ True{}:
      {==}
    case Nil{} False{}:
      {==}
    case Con{h, u} False{}:
      {==}

def neg_go(xs: List<&2, I.I>, +ys: List<&2, I.I>) -> {F.all_neg(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_neg(xs), F.all_neg(ys)) : Bool}:
  match xs:
    case []:
      {==}
    case +h <> +t:
      %neg_zz(List.append(&2, I.I, t, ys), F64.is_lt(I.i_hi(h), 0.0f64)) : {_ == Bool.and(F.all_neg_zz(t, F64.is_lt(I.i_hi(h), 0.0f64)), F.all_neg(ys)) : Bool}
      %neg_zz(t, F64.is_lt(I.i_hi(h), 0.0f64)) : {Bool.and(F64.is_lt(I.i_hi(h), 0.0f64), F.all_neg(List.append(&2, I.I, t, ys))) == Bool.and(_, F.all_neg(ys)) : Bool}
      %and_assoc(F64.is_lt(I.i_hi(h), 0.0f64), F.all_neg(t), F.all_neg(ys)) : {Bool.and(F64.is_lt(I.i_hi(h), 0.0f64), F.all_neg(List.append(&2, I.I, t, ys))) == _ : Bool}
      %neg_go(t, ys) : {Bool.and(F64.is_lt(I.i_hi(h), 0.0f64), F.all_neg(List.append(&2, I.I, t, ys))) == Bool.and(F64.is_lt(I.i_hi(h), 0.0f64), _) : Bool}
      {==}

def pos_go(xs: List<&2, I.I>, +ys: List<&2, I.I>) -> {F.all_pos(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_pos(xs), F.all_pos(ys)) : Bool}:
  match xs:
    case []:
      {==}
    case +h <> +t:
      %pos_zz(List.append(&2, I.I, t, ys), F64.is_lt(0.0f64, I.i_lo(h))) : {_ == Bool.and(F.all_pos_zz(t, F64.is_lt(0.0f64, I.i_lo(h))), F.all_pos(ys)) : Bool}
      %pos_zz(t, F64.is_lt(0.0f64, I.i_lo(h))) : {Bool.and(F64.is_lt(0.0f64, I.i_lo(h)), F.all_pos(List.append(&2, I.I, t, ys))) == Bool.and(_, F.all_pos(ys)) : Bool}
      %and_assoc(F64.is_lt(0.0f64, I.i_lo(h)), F.all_pos(t), F.all_pos(ys)) : {Bool.and(F64.is_lt(0.0f64, I.i_lo(h)), F.all_pos(List.append(&2, I.I, t, ys))) == _ : Bool}
      %pos_go(t, ys) : {Bool.and(F64.is_lt(0.0f64, I.i_lo(h)), F.all_pos(List.append(&2, I.I, t, ys))) == Bool.and(F64.is_lt(0.0f64, I.i_lo(h)), _) : Bool}
      {==}

def mix_go(xs: List<&2, I.I>, +ys: List<&2, I.I>) -> {F.all_mixed(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_mixed(xs), F.all_mixed(ys)) : Bool}:
  match xs:
    case []:
      {==}
    case +h <> +t:
      %mixed_zz(List.append(&2, I.I, t, ys), Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h)))) : {_ == Bool.and(F.all_mixed_zz(t, Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h)))), F.all_mixed(ys)) : Bool}
      %mixed_zz(t, Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h)))) : {Bool.and(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), F.all_mixed(List.append(&2, I.I, t, ys))) == Bool.and(_, F.all_mixed(ys)) : Bool}
      %and_assoc(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), F.all_mixed(t), F.all_mixed(ys)) : {Bool.and(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), F.all_mixed(List.append(&2, I.I, t, ys))) == _ : Bool}
      %mix_go(t, ys) : {Bool.and(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), F.all_mixed(List.append(&2, I.I, t, ys))) == Bool.and(Bool.and(F64.is_lt(I.i_lo(h), 0.0f64), F64.is_lt(0.0f64, I.i_hi(h))), _) : Bool}
      {==}

def Laws.press_verdict_is_interference_at_every_state(cs):
  {==}

def Laws.clearance_verdict_is_clearance_at_every_state(cs):
  {==}

def Laws.transition_verdict_is_both_at_every_state(cs):
  {==}

def Laws.interference_states_compose(xs, ys):
  neg_go(xs, ys)

def Laws.clearance_states_compose(xs, ys):
  pos_go(xs, ys)

def Laws.transition_states_compose(xs, ys):
  mix_go(xs, ys)
