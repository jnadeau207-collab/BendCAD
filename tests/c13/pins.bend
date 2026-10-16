import Base
import ../../src/c00/types.bend as T
import ../../src/c13/err.bend as E
import ../../src/c13/req.bend as R

def code_invalid__got() -> U64:
  E.code(T.F_invalid{})

def code_invalid__want() -> U64:
  1u64

def code_unsupported__got() -> U64:
  E.code(T.F_unsupported{})

def code_unsupported__want() -> U64:
  2u64

def code_uncertain__got() -> U64:
  E.code(T.F_uncertain{})

def code_uncertain__want() -> U64:
  3u64

def code_nonconverged__got() -> U64:
  E.code(T.F_nonconverged{})

def code_nonconverged__want() -> U64:
  4u64

def code_cancelled__got() -> U64:
  E.code(T.F_cancelled{})

def code_cancelled__want() -> U64:
  5u64

def code_exhausted__got() -> U64:
  E.code(T.F_exhausted{})

def code_exhausted__want() -> U64:
  6u64

def line_basic__got() -> String:
  E.line(T.F_invalid{}, "apply", "-", "bad-edit", "fix it")

def line_basic__want() -> String:
  "error invalid-input | apply @ - | why: bad-edit | fix: fix it"

def json_ok__got() -> String:
  E.json_ok(1u64)

def json_ok__want() -> String:
  "{\"node\":1,\"ok\":true}"

def json_err_basic__got() -> String:
  E.json_err(2u64, T.F_unsupported{}, "fillet", "node 2", "fillet-cone-not-certified",
    "give the edge equal end radii")

def json_err_basic__want() -> String:
  "{\"node\":2,\"ok\":false,\"code\":2,\"kind\":\"unsupported-op\",\"what\":\"fillet\",\"loc\":\"node 2\",\"why\":\"fillet-cone-not-certified\",\"fix\":\"give the edge equal end radii\"}"

def esc_plain__got() -> String:
  E.esc("abc XYZ 09-_.")

def esc_plain__want() -> String:
  "abc XYZ 09-_."

def esc_quote__got() -> String:
  E.esc("a\"b")

def esc_quote__want() -> String:
  "a\\\"b"

def esc_backslash__got() -> String:
  E.esc("a\\b")

def esc_backslash__want() -> String:
  "a\\\\b"

def nl() -> String:
  SCon{Chr{10}, SNil{}}

def esc_newline__got() -> String:
  E.esc("a" ++ nl() ++ "b")

def esc_newline__want() -> String:
  "a\\u000ab"

def dec_go__got() -> R.Dec:
  R.dec_of(False{}, False{})

def dec_go__want() -> R.Dec:
  R.D_go{}

def dec_over__got() -> R.Dec:
  R.dec_of(False{}, True{})

def dec_over__want() -> R.Dec:
  R.D_over{}

def dec_cancel__got() -> R.Dec:
  R.dec_of(True{}, False{})

def dec_cancel__want() -> R.Dec:
  R.D_cancel{}

def dec_cancel_wins__got() -> R.Dec:
  R.dec_of(True{}, True{})

def dec_cancel_wins__want() -> R.Dec:
  R.D_cancel{}

def over_empty__got() -> Bool:
  R.over_ids([], 5n)

def over_empty__want() -> Bool:
  False{}

def over_zero__got() -> Bool:
  R.over_ids([7u64], 0n)

def over_zero__want() -> Bool:
  True{}

def over_exact__got() -> Bool:
  R.over_ids([7u64, 8u64], 2n)

def over_exact__want() -> Bool:
  False{}

def over_over__got() -> Bool:
  R.over_ids([7u64, 8u64], 1n)

def over_over__want() -> Bool:
  True{}

def over_under__got() -> Bool:
  R.over_ids([7u64], 9n)

def over_under__want() -> Bool:
  False{}

def parse_plain__got() -> R.Fl:
  R.parse(["eval"])

def parse_plain__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "eval", [], ""}

def parse_cap__got() -> R.Fl:
  R.parse(["--max-nodes", "5", "eval"])

def parse_cap__want() -> R.Fl:
  R.Fl{5u64, False{}, "eval", [], ""}

def parse_cancel__got() -> R.Fl:
  R.parse(["--cancelled", "eval"])

def parse_cancel__want() -> R.Fl:
  R.Fl{281474976710655u64, True{}, "eval", [], ""}

def parse_both__got() -> R.Fl:
  R.parse(["--max-nodes", "3", "--cancelled", "measure", "1"])

def parse_both__want() -> R.Fl:
  R.Fl{3u64, True{}, "measure", ["1"], ""}

def parse_unknown__got() -> R.Fl:
  R.parse(["--bogus", "eval"])

def parse_unknown__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "", [], "unknown-flag --bogus"}

def parse_badval__got() -> R.Fl:
  R.parse(["--max-nodes", "abc", "eval"])

def parse_badval__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "", [], "bad-max-nodes abc"}

def parse_missing__got() -> R.Fl:
  R.parse(["--max-nodes"])

def parse_missing__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "", [], "bad-max-nodes"}

def parse_empty__got() -> R.Fl:
  R.parse([])

def parse_empty__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "", [], ""}

def parse_lastwins__got() -> R.Fl:
  R.parse(["--max-nodes", "5", "--max-nodes", "3", "eval"])

def parse_lastwins__want() -> R.Fl:
  R.Fl{3u64, False{}, "eval", [], ""}

def cap_max_val__got() -> U64:
  R.cap_max()

def cap_max_val__want() -> U64:
  281474976710655u64

def parse_huge__got() -> R.Fl:
  R.parse(["--max-nodes", "18446744073709551615", "eval"])

def parse_huge__want() -> R.Fl:
  R.Fl{281474976710655u64, False{}, "eval", [], ""}
