# C02 predicate types: signs, predicate/segment/triangle results, exact
# small-integer domain, sign-magnitude integer arithmetic.
# Filters + predicates: ops.bend. Contract: docs/c02-contract.md.
# Failure arms reuse C00 FailKind (T.FailKind); no new taxonomy.

import Base
import ../c00/types.bend as T

# --- Signs: the certified output of every predicate. ---
type Sign is Data:
  Sg_neg{}
  Sg_zero{}
  Sg_pos{}

def sign_show(s: Sign) -> String:
  match s:
    case Sg_neg{}: "neg"
    case Sg_zero{}: "zero"
    case Sg_pos{}: "pos"

def sign_neg(s: Sign) -> Sign:
  match s:
    case Sg_neg{}: Sg_pos{}
    case Sg_zero{}: Sg_zero{}
    case Sg_pos{}: Sg_neg{}

def sign_is_neg(s: Sign) -> Bool:
  match s:
    case Sg_neg{}: True{}
    case Sg_zero{}: False{}
    case Sg_pos{}: False{}

def sign_is_zero(s: Sign) -> Bool:
  match s:
    case Sg_neg{}: False{}
    case Sg_zero{}: True{}
    case Sg_pos{}: False{}

def sign_is_pos(s: Sign) -> Bool:
  match s:
    case Sg_neg{}: False{}
    case Sg_zero{}: False{}
    case Sg_pos{}: True{}

# Total F64 classifier. Ordered comparisons fail closed, so NaN maps to
# Sg_zero BY DOCUMENTED CONVENTION; filter callers gate finiteness first
# and never read that arm (contract §3).
def sign_of_f_gt(gt: Bool) -> Sign:
  match gt:
    case True{}: Sg_pos{}
    case False{}: Sg_zero{}

def sign_of_f_go(lt: Bool, gt: Bool) -> Sign:
  match lt:
    case True{}: Sg_neg{}
    case False{}: sign_of_f_gt(gt)

def sign_of_f(+f: F64) -> Sign:
  sign_of_f_go(F64.is_lt(f, 0.0f64), F64.is_lt(0.0f64, f))

# --- Predicate result: certified sign or a C00 failure kind. ---
type PRes is Data:
  Pok{ s: Sign }
  Perr{ kind: T.FailKind }

def pok(s: Sign) -> PRes:
  Pok{s}

def perr(k: T.FailKind) -> PRes:
  Perr{k}

def pres_ok(r: PRes) -> Bool:
  match r:
    case Pok{s}: True{}
    case Perr{kind}: False{}

def pres_show(r: PRes) -> String:
  match r:
    case Pok{s}: "ok"
    case Perr{kind}: T.FailKind.show(kind)

# Total kind projector. There is no ok-valued FailKind, so Pok yields
# F_invalid BY DOCUMENTED CONVENTION (mirrors C01 cres_kind); gate on
# pres_ok or pres_show before reading the kind. Pinned: pos-kind-doc.
def pres_kind(r: PRes) -> T.FailKind:
  match r:
    case Pok{s}: T.F_invalid{}
    case Perr{kind}: kind

# Total sign projector; documented Sg_zero unless the arm matches.
def pres_sign(r: PRes) -> Sign:
  match r:
    case Pok{s}: s
    case Perr{kind}: Sg_zero{}

def pres_sign_show(r: PRes) -> String:
  sign_show(pres_sign(r))

# --- Segment-segment relation in 2D (see ops.bend seg_seg). ---
type Xrel is Data:
  X_disjoint{}
  X_touch{}
  X_proper{}
  X_overlap{}

def xrel_show(x: Xrel) -> String:
  match x:
    case X_disjoint{}: "disjoint"
    case X_touch{}: "touch"
    case X_proper{}: "proper"
    case X_overlap{}: "overlap"

type Xres is Data:
  Xok{ r: Xrel }
  Xerr{ kind: T.FailKind }

def xok(r: Xrel) -> Xres:
  Xok{r}

def xerr(k: T.FailKind) -> Xres:
  Xerr{k}

def xres_ok(r: Xres) -> Bool:
  match r:
    case Xok{x}: True{}
    case Xerr{kind}: False{}

def xres_show(r: Xres) -> String:
  match r:
    case Xok{x}: "ok"
    case Xerr{kind}: T.FailKind.show(kind)

def xres_kind(r: Xres) -> T.FailKind:
  match r:
    case Xok{x}: T.F_invalid{}
    case Xerr{kind}: kind

def xres_rel(r: Xres) -> Xrel:
  match r:
    case Xok{x}: x
    case Xerr{kind}: X_disjoint{}

def xres_rel_show(r: Xres) -> String:
  xrel_show(xres_rel(r))

# --- Point-in-triangle classification (see ops.bend tri_class). ---
type Tcls is Data:
  T_in{}
  T_bound{}
  T_out{}

def tcls_show(c: Tcls) -> String:
  match c:
    case T_in{}: "inside"
    case T_bound{}: "boundary"
    case T_out{}: "outside"

type Tres is Data:
  Tok{ c: Tcls }
  Terr{ kind: T.FailKind }

def tok(c: Tcls) -> Tres:
  Tok{c}

def terr(k: T.FailKind) -> Tres:
  Terr{k}

def tres_ok(r: Tres) -> Bool:
  match r:
    case Tok{c}: True{}
    case Terr{kind}: False{}

def tres_show(r: Tres) -> String:
  match r:
    case Tok{c}: "ok"
    case Terr{kind}: T.FailKind.show(kind)

def tres_kind(r: Tres) -> T.FailKind:
  match r:
    case Tok{c}: T.F_invalid{}
    case Terr{kind}: kind

def tres_cls(r: Tres) -> Tcls:
  match r:
    case Tok{c}: c
    case Terr{kind}: T_out{}

def tres_cls_show(r: Tres) -> String:
  tcls_show(tres_cls(r))

# --- Filter constants (exact powers of two, bit-pinned; contract §3). ---
# Conservative Shewchuk Stage-A coefficients: 8/16/32/64 eps, each with
# >= 2x margin over the published A-constant for its determinant size.
def k_o2() -> F64:
  F64{4382002437431492608u64}

def k_o3() -> F64:
  F64{4386506037058863104u64}

def k_ic() -> F64:
  F64{4391009636686233600u64}

def k_is() -> F64:
  F64{4395513236313604096u64}

# Filter floor: detsum must reach 2^-960. Below it the error bound itself
# would leave the normal range, so the filter stays silent and the exact
# integer path (or honest uncertainty) decides. Contract §3.
def detmin() -> F64:
  F64{283726776524341248u64}

# --- Exact small-integer domains (contract §4). ---
# |coordinate| must be integral and within the limit. Maxima are chosen
# so every exact kernel fits U64 with 10+ bits of margin.
def lim_o2() -> U64:
  67108864u64

def lim_o3() -> U64:
  4096u64

def lim_ic() -> U64:
  256u64

def lim_is() -> U64:
  256u64

# Validated small integer: ok iff x is integral and |x| <= lim.
# Detected by truncation roundtrip: mag = to_u64(|x|) is exact, and
# to_f64(mag) == |x| holds iff x is integral (all mags < 2^53 convert
# exactly). -0.0 normalizes to +0 (neg only when mag != 0).
type SInt is Data:
  SI{ ok: Bool, neg: Bool, mag: U64 }

def si_ok(i: SInt) -> Bool:
  SI{ok, neg, mag} = i
  ok

def si_neg(i: SInt) -> Bool:
  SI{ok, neg, mag} = i
  neg

def si_mag(i: SInt) -> U64:
  SI{ok, neg, mag} = i
  mag

def sint_of(+x: F64, +lim: U64) -> SInt:
  +ax = F64.abs(x)
  +mag = F64.to_u64(ax)
  +rt = U64.to_f64(mag)
  +ok = Bool.and(F64.is_eq(rt, ax), U64.is_le(mag, lim))
  +neg = Bool.and(F64.sign(x), Bool.not(U64.is_zero(mag)))
  SI{ok, neg, mag}

# --- Sign-magnitude exact arithmetic on U64 (total; wrapping can only
# occur if a caller exceeds the documented domain maxima, which the
# exact kernels never do: contract §4 lists every maximum). ---
type SBal is Data:
  SB{ neg: Bool, mag: U64 }

def sb_zero() -> SBal:
  SB{False{}, 0u64}

def sb_neg(s: SBal) -> Bool:
  SB{neg, mag} = s
  neg

def sb_mag(s: SBal) -> U64:
  SB{neg, mag} = s
  mag

def sb_of_int(i: SInt) -> SBal:
  SI{ok, neg, mag} = i
  SB{neg, mag}

def sb_sign_neg(neg: Bool) -> Sign:
  match neg:
    case True{}: Sg_neg{}
    case False{}: Sg_pos{}

def sb_sign_go(neg: Bool, zero: Bool) -> Sign:
  match zero:
    case True{}: Sg_zero{}
    case False{}: sb_sign_neg(neg)

def sb_sign(s: SBal) -> Sign:
  SB{neg, mag} = s
  sb_sign_go(neg, U64.is_zero(mag))

def sb_flip_go(neg: Bool, mag: U64, zero: Bool) -> SBal:
  match zero:
    case True{}: SB{False{}, 0u64}
    case False{}: SB{Bool.not(neg), mag}

def sb_flip(s: SBal) -> SBal:
  SB{neg, +mag} = s
  sb_flip_go(neg, mag, U64.is_zero(mag))

def sb_sub_mag_gt(+nf: Bool, +m1: U64, +m2: U64, gt: Bool) -> SBal:
  match gt:
    case True{}: SB{nf, U64.sub(m1, m2)}
    case False{}: SB{Bool.not(nf), U64.sub(m2, m1)}

def sb_sub_mag_go(+nf: Bool, +m1: U64, +m2: U64, eq: Bool,
    gt: Bool) -> SBal:
  match eq:
    case True{}: SB{False{}, 0u64}
    case False{}: sb_sub_mag_gt(nf, m1, m2, gt)

def sb_sub_mag(+nf: Bool, +m1: U64, +m2: U64) -> SBal:
  sb_sub_mag_go(nf, m1, m2, U64.is_eq(m1, m2), U64.is_gt(m1, m2))

def sb_add_nega(+am: U64, +bn: Bool, +bm: U64) -> SBal:
  match bn:
    case True{}: SB{True{}, U64.add(am, bm)}
    case False{}: sb_sub_mag(True{}, am, bm)

def sb_add_posa(+am: U64, +bn: Bool, +bm: U64) -> SBal:
  match bn:
    case True{}: sb_sub_mag(False{}, am, bm)
    case False{}: SB{False{}, U64.add(am, bm)}

def sb_add_go(+an: Bool, +am: U64, +bn: Bool, +bm: U64) -> SBal:
  match an:
    case True{}: sb_add_nega(am, bn, bm)
    case False{}: sb_add_posa(am, bn, bm)

def sb_add(+a: SBal, +b: SBal) -> SBal:
  SB{+an, +am} = a
  SB{+bn, +bm} = b
  sb_add_go(an, am, bn, bm)

def sb_sub(+a: SBal, +b: SBal) -> SBal:
  sb_add(a, sb_flip(b))

def sb_mul_go(+an: Bool, +am: U64, +bn: Bool, +bm: U64,
    zero: Bool) -> SBal:
  match zero:
    case True{}: SB{False{}, 0u64}
    case False{}: SB{Bool.xor(an, bn), U64.mul(am, bm)}

def sb_mul(+a: SBal, +b: SBal) -> SBal:
  SB{+an, +am} = a
  SB{+bn, +bm} = b
  sb_mul_go(an, am, bn, bm,
    Bool.or(U64.is_zero(am), U64.is_zero(bm)))
