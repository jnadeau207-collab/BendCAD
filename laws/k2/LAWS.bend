import Base
import ../../src/c06/iv.bend as I
import ../../src/k2/fit.bend as F

law press_verdict_is_interference_at_every_state:
  for cs: List<&2, I.I>
  {F.verdict_of("press", cs) == Bool.pick(String, F.all_neg(cs), "verdict=press-certified", "fit-not-press") : String}

law clearance_verdict_is_clearance_at_every_state:
  for cs: List<&2, I.I>
  {F.verdict_of("clearance", cs) == Bool.pick(String, F.all_pos(cs), "verdict=clearance-certified", "fit-not-clearance") : String}

law transition_verdict_is_both_at_every_state:
  for cs: List<&2, I.I>
  {F.verdict_of("transition", cs) == Bool.pick(String, F.all_mixed(cs), "verdict=transition-certified", "fit-not-transition") : String}

law interference_states_compose:
  for xs: List<&2, I.I>
  for ys: List<&2, I.I>
  {F.all_neg(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_neg(xs), F.all_neg(ys)) : Bool}

law clearance_states_compose:
  for xs: List<&2, I.I>
  for ys: List<&2, I.I>
  {F.all_pos(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_pos(xs), F.all_pos(ys)) : Bool}

law transition_states_compose:
  for xs: List<&2, I.I>
  for ys: List<&2, I.I>
  {F.all_mixed(List.append(&2, I.I, xs, ys)) == Bool.and(F.all_mixed(xs), F.all_mixed(ys)) : Bool}
