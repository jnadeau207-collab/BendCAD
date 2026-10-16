import Base

def cap_max() -> U64:
  281474976710655u64

def over_ids(ids: List<&2, U64>, +cap: Nat) -> Bool:
  match ids:
    case []: False{}
    case _ <> t:
      match cap:
        case 0n: True{}
        case 1n+j: over_ids(t, j)

type Dec is Data:
  D_go{}
  D_cancel{}
  D_over{}

def dec_of(cancelled: Bool, +over: Bool) -> Dec:
  match cancelled:
    case True{}: D_cancel{}
    case False{}:
      match over:
        case True{}: D_over{}
        case False{}: D_go{}

type Fl is Data:
  Fl{ cap: U64, cancel: Bool, verb: String, rest: List<&2, String>, err: String }

def is_dash(+h: Char) -> Bool:
  match h:
    case Chr{+c}: U32.is_eq(c, 45)

def is_flag(+s: String) -> Bool:
  match s:
    case SNil{}: False{}
    case SCon{+h, t}:
      match t:
        case SNil{}: False{}
        case SCon{+h2, _}: Bool.and(is_dash(h), is_dash(h2))

def read_ok(m: Maybe<&2, U64>) -> Bool:
  match m:
    case None{}: False{}
    case Some{n}: True{}

def read_n(m: Maybe<&2, U64>) -> U64:
  match m:
    case None{}: 0u64
    case Some{n}: n

def parse_go(tokens: List<&2, String>, +cap: U64, +cancel: Bool) -> Fl:
  match tokens:
    case []: Fl{cap, cancel, "", [], ""}
    case "--max-nodes" <> t:
      match t:
        case []: Fl{cap, cancel, "", [], "bad-max-nodes"}
        case +v <> u:
          Bool.pick(Fl, read_ok(U64.read(v)), parse_go(u, U64.min(read_n(U64.read(v)), cap_max()), cancel),
            Fl{cap, cancel, "", [], "bad-max-nodes " ++ v})
    case "--cancelled" <> t: parse_go(t, cap, True{})
    case +w <> t:
      Bool.pick(Fl, is_flag(w), Fl{cap, cancel, "", [], "unknown-flag " ++ w}, Fl{cap, cancel, w, t, ""})

def parse(tokens: List<&2, String>) -> Fl:
  parse_go(tokens, cap_max(), False{})
