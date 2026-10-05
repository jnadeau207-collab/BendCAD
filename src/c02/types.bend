import Base
import ../c00/types.bend as T

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

def pres_kind(r: PRes) -> T.FailKind:
  match r:
    case Pok{s}: T.F_invalid{}
    case Perr{kind}: kind

def pres_sign(r: PRes) -> Sign:
  match r:
    case Pok{s}: s
    case Perr{kind}: Sg_zero{}

def pres_sign_show(r: PRes) -> String:
  sign_show(pres_sign(r))

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

def k_o2() -> F64:
  F64{4382002437431492608u64}

def k_o3() -> F64:
  F64{4386506037058863104u64}

def k_ic() -> F64:
  F64{4391009636686233600u64}

def k_is() -> F64:
  F64{4395513236313604096u64}

def detmin() -> F64:
  F64{283726776524341248u64}
