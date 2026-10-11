import Base
import ../../src/c08/bool.bend as B
import ./LAWS.bend as Laws

def Laws.outcome_is_regularized(o, c):
  match o c:
    case Laws.O_union{} Laws.C_apart{}:
      {==}
    case Laws.O_union{} Laws.C_a_in_b{}:
      {==}
    case Laws.O_union{} Laws.C_b_in_a{}:
      {==}
    case Laws.O_union{} Laws.C_crossing{}:
      {==}
    case Laws.O_diff{} Laws.C_apart{}:
      {==}
    case Laws.O_diff{} Laws.C_a_in_b{}:
      {==}
    case Laws.O_diff{} Laws.C_b_in_a{}:
      {==}
    case Laws.O_diff{} Laws.C_crossing{}:
      {==}
    case Laws.O_inter{} Laws.C_apart{}:
      {==}
    case Laws.O_inter{} Laws.C_a_in_b{}:
      {==}
    case Laws.O_inter{} Laws.C_b_in_a{}:
      {==}
    case Laws.O_inter{} Laws.C_crossing{}:
      {==}

def Laws.empty_algebra(o, ea, eb, same):
  match o ea eb same:
    case Laws.O_union{} True{} True{} True{}:
      {==}
    case Laws.O_union{} True{} True{} False{}:
      {==}
    case Laws.O_union{} True{} False{} True{}:
      {==}
    case Laws.O_union{} True{} False{} False{}:
      {==}
    case Laws.O_union{} False{} True{} True{}:
      {==}
    case Laws.O_union{} False{} True{} False{}:
      {==}
    case Laws.O_union{} False{} False{} True{}:
      {==}
    case Laws.O_union{} False{} False{} False{}:
      {==}
    case Laws.O_diff{} True{} True{} True{}:
      {==}
    case Laws.O_diff{} True{} True{} False{}:
      {==}
    case Laws.O_diff{} True{} False{} True{}:
      {==}
    case Laws.O_diff{} True{} False{} False{}:
      {==}
    case Laws.O_diff{} False{} True{} True{}:
      {==}
    case Laws.O_diff{} False{} True{} False{}:
      {==}
    case Laws.O_diff{} False{} False{} True{}:
      {==}
    case Laws.O_diff{} False{} False{} False{}:
      {==}
    case Laws.O_inter{} True{} True{} True{}:
      {==}
    case Laws.O_inter{} True{} True{} False{}:
      {==}
    case Laws.O_inter{} True{} False{} True{}:
      {==}
    case Laws.O_inter{} True{} False{} False{}:
      {==}
    case Laws.O_inter{} False{} True{} True{}:
      {==}
    case Laws.O_inter{} False{} True{} False{}:
      {==}
    case Laws.O_inter{} False{} False{} True{}:
      {==}
    case Laws.O_inter{} False{} False{} False{}:
      {==}

def Laws.uncertain_fragment_fails(o):
  match o:
    case Laws.O_union{}:
      {==}
    case Laws.O_diff{}:
      {==}
    case Laws.O_inter{}:
      {==}
