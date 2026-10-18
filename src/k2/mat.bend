import Base
import ../c00/types.bend as T
import ../c06/iv.bend as I
import ../c06/model.bend as M
import ../c06/sx.bend as S

def mat_find(ms: List<&2, M.Grade>, +n: U64) -> Maybe<&2, M.Grade>:
  match ms:
    case []: None{}
    case +h <> +t:
      M.Gr{+nd, +g, +rho, +cte} = h
      Bool.pick(Maybe<&2, M.Grade>, U64.is_eq(nd, n), Some{M.Gr{nd, g, rho, cte}}, mat_find(t, n))

def mt_node(+m: M.Grade) -> U64:
  M.Gr{+n, +g, +rho, +cte} = m
  n

def mat_set(ms: List<&2, M.Grade>, +m: M.Grade) -> List<&2, M.Grade>:
  match ms:
    case []: [m]
    case +h <> +t: Bool.pick(List<&2, M.Grade>, U64.is_eq(mt_node(h), mt_node(m)), m <> t, h <> mat_set(t, m))

def nd_known(+cs: List<&2, M.CE>, +n: U64) -> Bool:
  match cs:
    case []: False{}
    case +c <> +t:
      M.CE{+id, +k, +r} = c
      Bool.or(U64.is_eq(id, n), nd_known(t, n))

def err_line(+what: String, +why: String, +fix: String) -> String:
  "error invalid-input | " ++ what ++ " | why: " ++ why ++ " | fix: " ++ fix ++ "\n"

def mat_err1(+m: M.Grade, +cs: List<&2, M.CE>) -> String:
  M.Gr{+n, +g, +rho, +cte} = m
  +num = Bool.and(Bool.and(T.is_finite(rho), F64.is_lt(0.0f64, rho)), Bool.and(T.is_finite(cte), F64.is_le(0.0f64, cte)))
  Bool.pick(String, Bool.not(nd_known(cs, n)),
    err_line("material", "unknown-node " ++ U64.show(n), "bind materials to evaluated design nodes"),
    Bool.pick(String, num, "",
      err_line("material", "bad-material: " ++ g ++ " needs a finite density > 0 kg/m3 and a finite expansion >= 0 1/K",
        "write (material NODE GRADE DENSITY CTE)")))

def mats_err(ms: List<&2, M.Grade>, +cs: List<&2, M.CE>) -> String:
  match ms:
    case []: ""
    case +h <> +t: mat_err1(h, cs) ++ mats_err(t, cs)

def mass_iv(+v: I.I, +rho: F64) -> I.I:
  I.imul(v, I.imul(I.ipt(rho), I.ipt(1.0e-9f64)))

def mass_line(m: Maybe<&2, M.Grade>, +v: I.I) -> String:
  match m:
    case None{}: ""
    case Some{+x}:
      M.Gr{+n, +g, +rho, +cte} = x
      +k = mass_iv(v, rho)
      "material " ++ g ++ " density=" ++ S.f_show(rho) ++ " cte=" ++ S.f_show(cte) ++ " mass=[" ++ S.f_show(I.i_lo(k)) ++
        ", " ++ S.f_show(I.i_hi(k)) ++ "] kg status=certified\n"
