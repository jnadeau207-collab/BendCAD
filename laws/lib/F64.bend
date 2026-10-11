import Base

def bxor_inv(a: Bool, b: Bool) -> {Bool.xor(Bool.xor(a, b), b) == a : Bool}:
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      {==}
    case True{} False{}:
      {==}
    case True{} True{}:
      {==}

def xor_inv(n: Nat, +w: Word(n), +s: Word(n)) -> {Word.xor(n, Word.xor(n, w, s), s) == w : Word(n)}:
  match n w s:
    case 0n WNil{} WNil{}:
      {==}
    case 1n+p WCon{+a, +t} WCon{+b, +u}:
      %xor_inv(p, t, u) : {WCon{Bool.xor(Bool.xor(a, b), b), Word.xor(p, Word.xor(p, t, u), u)} == WCon{a, _} : Word(1n+p)}
      %bxor_inv(a, b) : {WCon{Bool.xor(Bool.xor(a, b), b), Word.xor(p, Word.xor(p, t, u), u)} == WCon{_, Word.xor(p, Word.xor(p, t, u), u)} : Word(1n+p)}
      {==}

def take_cat(n: Nat, m: Nat, +a: Word(n), +b: Word(m)) -> {Word.take(n, m, Word.cat(n, m, a, b)) == a : Word(n)}:
  match n a:
    case 0n WNil{}:
      {==}
    case 1n+p WCon{+h, +t}:
      %take_cat(p, m, t, b) : {WCon{h, Word.take(p, m, Word.cat(p, m, t, b))} == WCon{h, _} : Word(1n+p)}
      {==}

def drop_cat(n: Nat, m: Nat, +a: Word(n), +b: Word(m)) -> {Word.drop(n, m, Word.cat(n, m, a, b)) == b : Word(m)}:
  match n a:
    case 0n WNil{}:
      {==}
    case 1n+p WCon{h, t}:
      drop_cat(p, m, t, b)

def cat_take_drop(n: Nat, m: Nat, +w: Word(Nat.add(n, m))) -> {Word.cat(n, m, Word.take(n, m, w), Word.drop(n, m, w)) == w : Word(Nat.add(n, m))}:
  match n w:
    case 0n _:
      {==}
    case 1n+p WCon{+h, +t}:
      %cat_take_drop(p, m, t) : {WCon{h, Word.cat(p, m, Word.take(p, m, t), Word.drop(p, m, t))} == WCon{h, _} : Word(1n+Nat.add(p, m))}
      {==}

def sgn() -> Word(64n):
  U64.word((1u64 << 63n : U64))

def neg_inv(+x: F64) -> {F64.neg(F64.neg(x)) == x : F64}:
  match x:
    case F64{bits}:
      match bits:
        case U64{lo, hi}:
          match lo hi:
            case U32{+a} U32{+b}:
              %take_cat(32n, 32n, a, b) : {F64.neg(F64.neg(F64{U64{U32{a}, U32{b}}})) == F64{U64{U32{_}, U32{b}}} : F64}
              %drop_cat(32n, 32n, a, b) : {F64.neg(F64.neg(F64{U64{U32{a}, U32{b}}})) == F64{U64{U32{Word.take(32n, 32n, Word.cat(32n, 32n, a, b))}, U32{_}}} : F64}
              %xor_inv(64n, Word.cat(32n, 32n, a, b), sgn()) : {F64.neg(F64.neg(F64{U64{U32{a}, U32{b}}})) == F64{U64.of(_)} : F64}
              %cat_take_drop(32n, 32n, Word.xor(64n, Word.cat(32n, 32n, a, b), sgn())) : {F64.neg(F64.neg(F64{U64{U32{a}, U32{b}}})) == F64{U64.of(Word.xor(64n, _, sgn()))} : F64}
              {==}
