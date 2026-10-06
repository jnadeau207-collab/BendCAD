import Base
import ../../src/c04/types.bend as Ty
import ../../src/c06/model.bend as M
import ../../src/c06/sx.bend as S
import ../../src/c07/sol.bend as SO
import ../../src/c07/emb.bend as EM

type Of is Data:
  Of{ v: Nat, e: Nat, c: Nat, l: Nat, f: Nat, s: Nat }

def hv(h: Ty.HVertex, +o: Nat) -> Ty.HVertex:
  Ty.HV{i, g} = h
  Ty.HV{Nat.add(i, o), g}

def he(h: Ty.HEdge, +o: Nat) -> Ty.HEdge:
  Ty.HE{i, g} = h
  Ty.HE{Nat.add(i, o), g}

def hc(h: Ty.HCoedge, +o: Nat) -> Ty.HCoedge:
  Ty.HC{i, g} = h
  Ty.HC{Nat.add(i, o), g}

def hl(h: Ty.HLoop, +o: Nat) -> Ty.HLoop:
  Ty.HL{i, g} = h
  Ty.HL{Nat.add(i, o), g}

def hf(h: Ty.HFace, +o: Nat) -> Ty.HFace:
  Ty.HF{i, g} = h
  Ty.HF{Nat.add(i, o), g}

def hs(h: Ty.HShell, +o: Nat) -> Ty.HShell:
  Ty.HS{i, g} = h
  Ty.HS{Nat.add(i, o), g}

def es_sh(xs: List<&2, Ty.Edge>, +o: Nat) -> List<&2, Ty.Edge>:
  match xs:
    case []: []
    case x <> t:
      Ty.Ed{g, v0, v1, k} = x
      Ty.Ed{g, hv(v0, o), hv(v1, o), k} <> es_sh(t, o)

def cs_sh(xs: List<&2, Ty.Coedge>, +o: Nat, +fl: Bool) -> List<&2, Ty.Coedge>:
  match xs:
    case []: []
    case x <> t:
      Ty.Ce{g, e, +fwd, tr} = x
      Ty.Ce{g, he(e, o), Bool.pick(Bool, fl, Bool.not(fwd), fwd), tr} <> cs_sh(t, o, fl)

def hcs(xs: List<&2, Ty.HCoedge>, +o: Nat) -> List<&2, Ty.HCoedge>:
  match xs:
    case []: []
    case x <> t: hc(x, o) <> hcs(t, o)

def ls_sh(xs: List<&2, Ty.Loop>, +o: Nat) -> List<&2, Ty.Loop>:
  match xs:
    case []: []
    case x <> t:
      Ty.Lp{g, cs, k} = x
      Ty.Lp{g, hcs(cs, o), k} <> ls_sh(t, o)

def hls(xs: List<&2, Ty.HLoop>, +o: Nat) -> List<&2, Ty.HLoop>:
  match xs:
    case []: []
    case x <> t: hl(x, o) <> hls(t, o)

def fs_sh(xs: List<&2, Ty.Face>, +o: Nat, +fl: Bool) -> List<&2, Ty.Face>:
  match xs:
    case []: []
    case x <> t:
      Ty.Fa{g, s, ls, +same} = x
      Ty.Fa{g, s, hls(ls, o), Bool.pick(Bool, fl, Bool.not(same), same)} <> fs_sh(t, o, fl)

def hfs(xs: List<&2, Ty.HFace>, +o: Nat) -> List<&2, Ty.HFace>:
  match xs:
    case []: []
    case x <> t: hf(x, o) <> hfs(t, o)

def ss_sh(xs: List<&2, Ty.Shell>, +o: Nat) -> List<&2, Ty.Shell>:
  match xs:
    case []: []
    case x <> t:
      Ty.Sh{g, fs, k} = x
      Ty.Sh{g, hfs(fs, o), k} <> ss_sh(t, o)

def hss(xs: List<&2, Ty.HShell>, +o: Nat) -> List<&2, Ty.HShell>:
  match xs:
    case []: []
    case x <> t: hs(x, o) <> hss(t, o)

def so_sh(xs: List<&2, Ty.Solid>, +o: Nat) -> List<&2, Ty.Solid>:
  match xs:
    case []: []
    case x <> t:
      Ty.So{g, out, cs} = x
      Ty.So{g, hs(out, o), hss(cs, o)} <> so_sh(t, o)

def of_of(b: Ty.Brep) -> Of:
  Ty.Br{vs, es, cs, ls, fs, ss, os, top, st} = b
  Of{List.length(&2, Ty.Vertex, vs), List.length(&2, Ty.Edge, es), List.length(&2, Ty.Coedge, cs), List.length(&2, Ty.Loop, ls),
    List.length(&2, Ty.Face, fs), List.length(&2, Ty.Shell, ss)}

def flip(b: Ty.Brep) -> Ty.Brep:
  Ty.Br{vs, es, cs, ls, fs, ss, os, top, st} = b
  Ty.Br{vs, es, cs_sh(cs, 0n, True{}), ls, fs_sh(fs, 0n, True{}), ss, os, top, st}

def so_out(xs: List<&2, Ty.Solid>) -> Ty.HShell:
  match xs:
    case []: Ty.hsh_null()
    case x <> t:
      Ty.So{g, out, cs} = x
      out

def so_add(xs: List<&2, Ty.Solid>, +cav: Ty.HShell) -> List<&2, Ty.Solid>:
  match xs:
    case []: []
    case x <> t:
      Ty.So{g, out, cs} = x
      Ty.So{g, out, List.append(&2, Ty.HShell, cs, [cav])} <> t

def join(a: Ty.Brep, b: Ty.Brep, +o: Of, +cav: Bool) -> Ty.Brep:
  Ty.Br{va, ea, ca, la, fa, sa, +oa, ta, st} = a
  Ty.Br{vb, eb, cb, lb, fb, sb, ob, tb, sb2} = b
  Of{ov, oe, oc, ol, ofa, os} = o
  +ob2 = so_sh(ob, os)
  Ty.Br{List.append(&2, Ty.Vertex, va, vb), List.append(&2, Ty.Edge, ea, es_sh(eb, ov)), List.append(&2, Ty.Coedge, ca, cs_sh(cb, oe, False{})),
    List.append(&2, Ty.Loop, la, ls_sh(lb, oc)), List.append(&2, Ty.Face, fa, fs_sh(fb, ol, False{})), List.append(&2, Ty.Shell, sa, ss_sh(sb, ofa)),
    Bool.pick(List<&2, Ty.Solid>, cav, so_add(oa, so_out(ob2)), List.append(&2, Ty.Solid, oa, ob2)), ta, st}

def two(+a: Ty.Brep, +b: Ty.Brep, +cav: Bool) -> Ty.Brep:
  join(a, b, of_of(a), cav)

def ps_xs(r: S.PS) -> List<&2, S.Sx>:
  S.PS{ok, xs} = r
  xs

def br_of(r: M.NR) -> Ty.Brep:
  match r:
    case M.NR_err{k, d}: Ty.brep_empty()
    case M.NR_ok{b, fx}: M.bd_brep(b)

def node(cs: List<&2, M.CE>, +i: U64) -> Ty.Brep:
  br_of(M.ce_r(M.ce_find(cs, i)))

def fis_s(fs: List<&2, SO.Fi>) -> String:
  match fs:
    case []: ""
    case f <> t:
      SO.Fi{c, a, b} = f
      c ++ " " ++ Nat.show(a) ++ " " ++ Nat.show(b) ++ "; " ++ fis_s(t)

def check(+b: Ty.Brep) -> String:
  +fd = SO.fds_of(b)
  +fs = List.append(&2, SO.Fi, SO.solid_fi(b, fd), EM.emb_fi(b, fd))
  Bool.pick(String, Nat.is_eq(List.length(&2, SO.Fi, fs), 0n), "ok", fis_s(fs))

def line(+name: String, +b: Ty.Brep) -> String:
  "CASE " ++ name ++ ": " ++ check(b) ++ "\n"

def design() -> String:
  "(bendcad 1) (node 1 (box 10 10 10) (intent create any 0 1 0)) (node 2 (prism 5 15 (region (path 5 5 (line 15 5) (line 15 15) (line 5 15)))) (intent create any 0 1 0)) (node 3 (prism 2 4 (region (path 2 2 (line 4 2) (line 4 4) (line 2 4)))) (intent create any 0 1 0)) (node 4 (prism 20 22 (region (path 20 20 (line 22 20) (line 22 22) (line 20 22)))) (intent create any 0 1 0)) (node 5 (prism 1 9 (region (path 1 1 (line 9 1) (line 9 9) (line 1 9)))) (intent create any 0 1 0)) (node 6 (prism 0 10 (region (path 10 0 (line 20 0) (line 20 10) (line 10 10)))) (intent create any 0 1 0)) (node 7 (prism 0 10 (region (path 10 10 (line 20 10) (line 20 20) (line 10 20)))) (intent create any 0 1 0)) (node 8 (sphere 6) (intent create any 0 1 0)) (node 9 (prism 3 7 (region (circle 5 5 2))) (intent create any 0 1 0)) (node 10 (prism 3 7 (region (circle 9 5 2))) (intent create any 0 1 0))"

def run(+cs: List<&2, M.CE>) -> String:
  +a = node(cs, 1u64)
  line("ok.box", a) ++ line("ok.disjoint", two(a, node(cs, 4u64), False{})) ++ line("inverted", flip(a)) ++
  line("overlap.boxes", two(a, node(cs, 2u64), False{})) ++ line("cavity.ok", two(a, flip(node(cs, 3u64)), True{})) ++
  line("cavity.curved", two(a, flip(node(cs, 9u64)), True{})) ++ line("cavity.unflipped", two(a, node(cs, 3u64), True{})) ++
  line("cavity.outside", two(a, flip(node(cs, 4u64)), True{})) ++
  line("cavity.nested", two(two(a, flip(node(cs, 5u64)), True{}), flip(node(cs, 3u64)), True{})) ++
  line("cavity.crossing", two(a, flip(node(cs, 10u64)), True{})) ++ line("touch.face", two(a, node(cs, 6u64), False{})) ++
  line("touch.edge", two(a, node(cs, 7u64), False{})) ++ line("overlap.sphere", two(a, node(cs, 8u64), False{}))

def main() -> IO(Unit):
  IO.print(run(M.ev_part(S.part_of(ps_xs(S.parse(design()))), [])))
