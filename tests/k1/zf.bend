import Base

import ../../src/c00/types.bend as T

import ../../src/c01/types.bend as V

import ../../src/c03/types.bend as G

import ../../src/c06/surfx.bend as SX

import ../../src/c06/xp.bend as X

import ../../src/c06/prof.bend as F

import ../../src/c06/iv.bend as I

import ../../src/c06/model.bend as M

import ../../src/c06/sx.bend as S

import ../../src/c06/ear.bend as EA

import ../../src/c06/zone.bend as Z

import ../../src/c04/types.bend as Ty

import ../../src/c08/bool.bend as B8
import ../../src/k1/gb.bend as GB
import ../../src/k1/asm.bend as K1

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def ev(+src: String) -> List<&2, M.CE>:
  M.ev_part(S.part_of(ps_xs(S.parse(src))), [])

def node_r(cs: List<&2, M.CE>, +n: U64) -> M.NR:
  match cs:
    case []: M.bad("-", "-", "missing", "-")
    case c <> t:
      M.CE{id, key, r} = c
      Bool.pick(M.NR, U64.is_eq(id, n), r, node_r(t, n))

def bk(+cs: List<&2, M.CE>, +n: U64) -> Ty.Brep:
  B8.bake_of(M.bool_in(M.nr_body(node_r(cs, n))))

def vol_s(+r: M.NR) -> String:
  match r:
    case M.NR_ok{+b, fx}:
      +m = M.body_ms(b)
      "ok vol=[" ++ F64.show(I.i_lo(M.ms_vol(m))) ++ "," ++ F64.show(I.i_hi(M.ms_vol(m))) ++ "] check=" ++ B8.vcode(B8.vcore(M.bd_brep(b)))
    case M.NR_err{k, d}:
      M.Dg{w, l, y, f} = d
      "err " ++ y

def main() -> String:
  +cs = ev("(node 1 (box 20 20 10) (intent create any any any any)) (node 2 (pocket 1 (face 1 0 top) through (region (circle 10 10 3))) (intent remove any any any any)) (node 3 (fillet 2 (face 2 n1.c0.top) (circle 10 10 3) 1) (intent remove any any any any)) (node 4 (cylinder 2 6) (intent create any any any any)) (node 5 (move 4 4 4 10 0) (intent same 0 0 1 0)) (node 6 (union 3 5) (intent add any any any any))")
  "n3 " ++ vol_s(node_r(cs, 3u64)) ++ " n6 " ++ vol_s(node_r(cs, 6u64))
