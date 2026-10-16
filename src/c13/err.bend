import Base
import ../c00/types.bend as T

def code(+k: T.FailKind) -> U64:
  match k:
    case T.F_invalid{}: 1u64
    case T.F_unsupported{}: 2u64
    case T.F_uncertain{}: 3u64
    case T.F_nonconverged{}: 4u64
    case T.F_cancelled{}: 5u64
    case T.F_exhausted{}: 6u64

def line(+k: T.FailKind, +w: String, +l: String, +y: String, +f: String) -> String:
  "error " ++ T.FailKind.show(k) ++ " | " ++ w ++ " @ " ++ l ++ " | why: " ++ y ++ " | fix: " ++ f

def hex_ch(+n: U32) -> Char:
  Chr{Bool.pick(U32, U32.is_lt(n, 10), U32.add(n, 48), U32.add(n, 87))}

def esc_u(+c: U32, +acc: String) -> String:
  +lo = Bool.pick(U32, U32.is_lt(c, 16), c, (c - 16 : U32))
  +hi = Bool.pick(U32, U32.is_lt(c, 16), 0, 1)
  SCon{hex_ch(lo), SCon{hex_ch(hi), SCon{Chr{48}, SCon{Chr{48}, SCon{Chr{117}, SCon{Chr{92}, acc}}}}}}

def esc_ch(+h: Char, +acc: String) -> String:
  match h:
    case Chr{+c}:
      Bool.pick(String, U32.is_eq(c, 34), SCon{Chr{34}, SCon{Chr{92}, acc}},
        Bool.pick(String, U32.is_eq(c, 92), SCon{Chr{92}, SCon{Chr{92}, acc}},
          Bool.pick(String, U32.is_lt(c, 32), esc_u(c, acc), SCon{Chr{c}, acc})))

def s_rev(s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{+h, t}: s_rev(t, SCon{h, acc})

def esc_go(s: String, +acc: String) -> String:
  match s:
    case SNil{}: s_rev(acc, "")
    case SCon{+h, t}: esc_go(t, esc_ch(h, acc))

def esc(+s: String) -> String:
  esc_go(s, "")

def json_ok(+node: U64) -> String:
  "{\"node\":" ++ U64.show(node) ++ ",\"ok\":true}"

def json_err(+node: U64, +k: T.FailKind, +w: String, +l: String, +y: String, +f: String) -> String:
  "{\"node\":" ++ U64.show(node) ++ ",\"ok\":false,\"code\":" ++ U64.show(code(k)) ++ ",\"kind\":\"" ++ esc(T.FailKind.show(k)) ++ "\",\"what\":\"" ++ esc(w) ++ "\",\"loc\":\"" ++ esc(l) ++ "\",\"why\":\"" ++ esc(y) ++ "\",\"fix\":\"" ++ esc(f) ++ "\"}"
