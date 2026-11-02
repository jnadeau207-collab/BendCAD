import Base
import ../c00/types.bend as T
import ../c01/types.bend as V
import ../c04/types.bend as Ty
import ../c07/sol.bend as SO
import ../base/par.bend as B

def nth_fa0(xs: List<&2, Ty.Face>, +i: Nat) -> Ty.Face:
  match xs:
    case []: Ty.fa_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_fa0(t, j)

def nth_ce0(xs: List<&2, Ty.Coedge>, +i: Nat) -> Ty.Coedge:
  match xs:
    case []: Ty.ce_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ce0(t, j)

def nth_ed0(xs: List<&2, Ty.Edge>, +i: Nat) -> Ty.Edge:
  match xs:
    case []: Ty.ed_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_ed0(t, j)

def nth_lp0(xs: List<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match xs:
    case []: Ty.lp_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_lp0(t, j)

def nth_vx0(xs: List<&2, Ty.Vertex>, +i: Nat) -> Ty.Vertex:
  match xs:
    case []: Ty.vx_dflt()
    case h <> t:
      match i:
        case 0n: h
        case 1n+j: nth_vx0(t, j)

def hv(+i: Nat) -> Ty.HVertex:
  Ty.HV{i, U64.from_nat(Nat.add(i, 1n))}

def he(+i: Nat) -> Ty.HEdge:
  Ty.HE{i, U64.from_nat(Nat.add(i, 1n))}

def hc(+i: Nat) -> Ty.HCoedge:
  Ty.HC{i, U64.from_nat(Nat.add(i, 1n))}

def hlp(+i: Nat) -> Ty.HLoop:
  Ty.HL{i, U64.from_nat(Nat.add(i, 1n))}

def hfa(+i: Nat) -> Ty.HFace:
  Ty.HF{i, U64.from_nat(Nat.add(i, 1n))}

def hsh(+i: Nat) -> Ty.HShell:
  Ty.HS{i, U64.from_nat(Nat.add(i, 1n))}

def hso(+i: Nat) -> Ty.HSolid:
  Ty.HSo{i, U64.from_nat(Nat.add(i, 1n))}

type EK is Data:
  EK{ va: Nat, vb: Nat, kind: U64, side: U64, id: Nat, idx: Nat }

type AS is Data:
  AS{ vs: List<&2, Ty.Vertex>, es: List<&2, Ty.Edge>, ces: List<&2, Ty.Coedge>,
    lps: List<&2, Ty.Loop>, fas: List<&2, Ty.Face>, eks: List<&2, EK>, nv: Nat, ne: Nat,
    nc: Nat, nl: Nat, nf: Nat, ms: List<&2, V.Point>, nm: Nat }

def as_vs(+a: AS) -> List<&2, Ty.Vertex>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  vs

def as_es(+a: AS) -> List<&2, Ty.Edge>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  es

def as_ces(+a: AS) -> List<&2, Ty.Coedge>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  ces

def as_lps(+a: AS) -> List<&2, Ty.Loop>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  lps

def as_fas(+a: AS) -> List<&2, Ty.Face>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  fas

def as_eks(+a: AS) -> List<&2, EK>:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  eks

def as_nv(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nv

def as_ne(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  ne

def as_nc(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nc

def as_nl(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nl

def as_nf(+a: AS) -> Nat:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  nf

def as_empty() -> AS:
  AS{[], [], [], [], [], [], 0n, 0n, 0n, 0n, 0n, [], 0n}

def gen1(+i: Nat) -> U64:
  U64.from_nat(Nat.add(i, 1n))

def as_add_v(+a: AS, +p: V.Point) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  AS{Ty.Vx{gen1(nv), p} <> vs, es, ces, lps, fas, eks, Nat.add(nv, 1n), ne, nc, nl, nf, ms, nm}

def as_add_e(+a: AS, +ed: Ty.Edge, +ek: EK) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Ed{+g, +v0, +v1, +k} = ed
  AS{vs, Ty.Ed{gen1(ne), v0, v1, k} <> es, ces, lps, fas, ek <> eks, nv, Nat.add(ne, 1n), nc, nl,
    nf, ms, nm}

def as_add_ce(+a: AS, +ce: Ty.Coedge) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Ce{+g, +e, +fwd, +trim} = ce
  AS{vs, es, Ty.Ce{gen1(nc), e, fwd, trim} <> ces, lps, fas, eks, nv, ne, Nat.add(nc, 1n), nl,
    nf, ms, nm}

def as_add_lp(+a: AS, +lp: Ty.Loop) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Lp{+g, +ces2, +kind} = lp
  AS{vs, es, ces, Ty.Lp{gen1(nl), ces2, kind} <> lps, fas, eks, nv, ne, nc, Nat.add(nl, 1n), nf, ms, nm}

def as_add_fa(+a: AS, +fa: Ty.Face) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = a
  Ty.Fa{+g, +surf, +loops, +same, +slv, +sla} = fa
  AS{vs, es, ces, lps, Ty.Fa{gen1(nf), surf, loops, same, slv, sla} <> fas, eks, nv, ne, nc, nl,
    Nat.add(nf, 1n), ms, nm}

def ek_match(+e: EK, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat) -> Bool:
  EK{+a, +b, +k, +s, +i, +x} = e
  Bool.and(Bool.or(Bool.and(Nat.is_eq(a, va), Nat.is_eq(b, vb)),
      Bool.and(Nat.is_eq(a, vb), Nat.is_eq(b, va))),
    Bool.and(U64.is_eq(k, kind), Bool.and(U64.is_eq(s, side), Nat.is_eq(i, id))))

def ek_idx(+e: EK) -> Nat:
  EK{+a, +b, +k, +s, +i, +x} = e
  x

def efind_go(es: List<&2, EK>, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat,
    +dflt: Nat) -> Nat:
  match es:
    case []: dflt
    case +h <> +t: Bool.pick(Nat, ek_match(h, va, vb, kind, side, id), ek_idx(h),
      efind_go(t, va, vb, kind, side, id, dflt))

type ER is Data:
  ER{ idx: Nat, st: AS }

def eemit_go(+found: Bool, +f: Nat, +st: AS, +va: Nat, +vb: Nat, +kind: U64, +side: U64,
    +id: Nat, +ed: Ty.Edge) -> ER:
  match found:
    case True{}: ER{f, st}
    case False{}: ER{as_ne(st), as_add_e(st, ed, EK{va, vb, kind, side, id, as_ne(st)})}

def eemit(+st: AS, +va: Nat, +vb: Nat, +kind: U64, +side: U64, +id: Nat, +ed: Ty.Edge) -> ER:
  +n = as_ne(st)
  +f = efind_go(as_eks(st), va, vb, kind, side, id, n)
  eemit_go(Nat.is_lt(f, n), f, st, va, vb, kind, side, id, ed)

def er_idx(+r: ER) -> Nat:
  ER{idx, st} = r
  idx

def er_st(+r: ER) -> AS:
  ER{idx, st} = r
  st

def ce_at_go(ok: Bool, +tc: B.Tb<&2, Ty.Coedge>, +i: Nat) -> Ty.Coedge:
  match ok:
    case True{}: B.tb_get(Ty.Coedge, tc, U32.from_nat(i))
    case False{}: Ty.ce_dflt()

def ce_at(+tc: B.Tb<&2, Ty.Coedge>, +n: Nat, +i: Nat) -> Ty.Coedge:
  ce_at_go(Nat.is_lt(i, n), tc, i)

def lp_at_go(ok: Bool, +tl: B.Tb<&2, Ty.Loop>, +i: Nat) -> Ty.Loop:
  match ok:
    case True{}: B.tb_get(Ty.Loop, tl, U32.from_nat(i))
    case False{}: Ty.lp_dflt()

def lp_at(+tl: B.Tb<&2, Ty.Loop>, +n: Nat, +i: Nat) -> Ty.Loop:
  lp_at_go(Nat.is_lt(i, n), tl, i)

def nat_at_go(ok: Bool, +tn: B.Tb<&2, Nat>, +i: Nat) -> Nat:
  match ok:
    case True{}: B.tb_get(Nat, tn, U32.from_nat(i))
    case False{}: 0n

def nat_at(+tn: B.Tb<&2, Nat>, +n: Nat, +i: Nat) -> Nat:
  nat_at_go(Nat.is_lt(i, n), tn, i)

def nat_put_go(ok: Bool, +tn: B.Tb<&2, Nat>, +i: Nat, +v: Nat) -> B.Tb<&2, Nat>:
  match ok:
    case True{}: B.tb_set(Nat, tn, U32.from_nat(i), v)
    case False{}: tn

def nat_put(+tn: B.Tb<&2, Nat>, +n: Nat, +i: Nat, +v: Nat) -> B.Tb<&2, Nat>:
  nat_put_go(Nat.is_lt(i, n), tn, i, v)

def loop_eis_go(cs: List<&2, Ty.HCoedge>, +tc: B.Tb<&2, Ty.Coedge>, +nc: Nat,
    +acc: List<&2, Nat>) -> List<&2, Nat>:
  match cs:
    case []: acc
    case +h <> +t:
      loop_eis_go(t, tc, nc, Ty.he_idx(Ty.ce_edge(ce_at(tc, nc, Ty.hc_idx(h)))) <> acc)

def face_eis_go(ls: List<&2, Ty.HLoop>, +tl: B.Tb<&2, Ty.Loop>, +nl: Nat, +tc: B.Tb<&2, Ty.Coedge>,
    +nc: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match ls:
    case []: acc
    case +h <> +t:
      face_eis_go(t, tl, nl, tc, nc,
        List.append(&2, Nat, acc, loop_eis_go(Ty.lp_ces(lp_at(tl, nl, Ty.hlp_idx(h))), tc, nc, [])))

def faces_eis(fs: List<&2, Ty.Face>, +tl: B.Tb<&2, Ty.Loop>, +nl: Nat, +tc: B.Tb<&2, Ty.Coedge>,
    +nc: Nat) -> List<&2, List<&2, Nat>>:
  match fs:
    case []: []
    case +h <> +t: face_eis_go(Ty.fa_loops(h), tl, nl, tc, nc, []) <> faces_eis(t, tl, nl, tc, nc)

def nat_mem(+x: Nat, xs: List<&2, Nat>) -> Bool:
  match xs:
    case []: False{}
    case +h <> +t: Bool.or(Nat.is_eq(x, h), nat_mem(x, t))

def nat_nth(xs: List<&2, Nat>, +i: Nat) -> Nat:
  match xs:
    case []: 0n
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: nat_nth(t, j)

def hd_is(xs: List<&2, Nat>, +f: Nat) -> Bool:
  match xs:
    case []: False{}
    case +h <> t: Nat.is_eq(h, f)

def ef_push(dup: Bool, +cur: List<&2, Nat>, +f: Nat) -> List<&2, Nat>:
  match dup:
    case True{}: cur
    case False{}: f <> cur

def tef_put(ok: Bool, +tb: B.Tb<&2, List<&2, Nat>>, +e: Nat, +f: Nat) -> B.Tb<&2, List<&2, Nat>>:
  match ok:
    case False{}: tb
    case True{}:
      +k = U32.from_nat(e)
      +cur = B.tb_get(List<&2, Nat>, tb, k)
      B.tb_set(List<&2, Nat>, tb, k, ef_push(hd_is(cur, f), cur, f))

def tef_es(es: List<&2, Nat>, +f: Nat, +ne: Nat, +tb: B.Tb<&2, List<&2, Nat>>) -> B.Tb<&2, List<&2, Nat>>:
  match es:
    case []: tb
    case +e <> +t: tef_es(t, f, ne, tef_put(Nat.is_lt(e, ne), tb, e, f))

def tef_fs(fs: List<&2, List<&2, Nat>>, +i: Nat, +ne: Nat, +tb: B.Tb<&2, List<&2, Nat>>) -> B.Tb<&2, List<&2, Nat>>:
  match fs:
    case []: tb
    case +h <> +t: tef_fs(t, Nat.add(i, 1n), ne, tef_es(h, i, ne, tb))

def ufind_t(fuel: Nat, stop: Bool, +p: B.Tb<&2, Nat>, +n: Nat, +x: Nat) -> Nat:
  match fuel stop:
    case 0n _: x
    case 1n++j True{}: x
    case 1n++j False{}:
      +r = nat_at(p, n, x)
      ufind_t(j, Nat.is_eq(nat_at(p, n, r), r), p, n, r)

def ufind(+p: B.Tb<&2, Nat>, +n: Nat, +x: Nat) -> Nat:
  ufind_t(n, Nat.is_eq(nat_at(p, n, x), x), p, n, x)

def uunion(+p: B.Tb<&2, Nat>, +a: Nat, +b: Nat, +n: Nat) -> B.Tb<&2, Nat>:
  +ra = ufind(p, n, a)
  +rb = ufind(p, n, b)
  Bool.pick(B.Tb<&2, Nat>, Nat.is_eq(ra, rb), p, nat_put(p, n, ra, rb))

def ul_go(fs: List<&2, Nat>, +fst: Nat, +p: B.Tb<&2, Nat>, +n: Nat) -> B.Tb<&2, Nat>:
  match fs:
    case []: p
    case +h <> +t: ul_go(t, fst, uunion(p, fst, h, n), n)

def ul_go2(fs: List<&2, Nat>, +p: B.Tb<&2, Nat>, +n: Nat) -> B.Tb<&2, Nat>:
  match fs:
    case []: p
    case +f <> +t: ul_go(t, f, p, n)

def erange(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: erange(j, j <> acc)

def comps_go(es: List<&2, Nat>, +tef: B.Tb<&2, List<&2, Nat>>, +p: B.Tb<&2, Nat>,
    +n: Nat) -> B.Tb<&2, Nat>:
  match es:
    case []: p
    case +e <> +t: comps_go(t, tef, ul_go2(B.tb_get(List<&2, Nat>, tef, U32.from_nat(e)), p, n), n)

def comps_of(+st: AS) -> B.Tb<&2, Nat>:
  +lps = as_lps(st)
  +ces = as_ces(st)
  +fe = faces_eis(as_fas(st), B.tb_of(Ty.Loop, lps, Ty.lp_dflt()), List.length(&2, Ty.Loop, lps),
    B.tb_of(Ty.Coedge, ces, Ty.ce_dflt()), List.length(&2, Ty.Coedge, ces))
  +n = as_nf(st)
  +ne = as_ne(st)
  +tef = tef_fs(fe, 0n, ne, B.tb_of(List<&2, Nat>, B.rep_n(List<&2, Nat>, ne, []), []))
  comps_go(erange(ne, []), tef, B.tb_of(Nat, erange(n, []), 0n), n)

type GRP is Data:
  GRP{ r: Nat, fs: List<&2, Nat> }

def grp_r(+r: GRP) -> Nat:
  GRP{r, fs} = r
  r

def grp_fs(+r: GRP) -> List<&2, Nat>:
  GRP{r, fs} = r
  fs

def gadd(g: List<&2, GRP>, +r: Nat, +f: Nat) -> List<&2, GRP>:
  match g:
    case []: [GRP{r, [f]}]
    case +h <> +t:
      Bool.pick(List<&2, GRP>, Nat.is_eq(grp_r(h), r), GRP{r, f <> grp_fs(h)} <> t,
        h <> gadd(t, r, f))

def groups_go(fs: List<&2, Nat>, +p: B.Tb<&2, Nat>, +n: Nat,
    +acc: List<&2, GRP>) -> List<&2, GRP>:
  match fs:
    case []: acc
    case +e <> +t: groups_go(t, p, n, gadd(acc, ufind(p, n, e), e))

def hfas_of(fs: List<&2, Nat>, +acc: List<&2, Ty.HFace>) -> List<&2, Ty.HFace>:
  match fs:
    case []: List.reverse(&2, Ty.HFace, acc)
    case +h <> +t: hfas_of(t, hfa(h) <> acc)

def hsos_of(n: Nat, +acc: List<&2, Ty.HSolid>) -> List<&2, Ty.HSolid>:
  match n:
    case 0n: acc
    case 1n++j: hsos_of(j, hso(j) <> acc)

def hshs_of(n: Nat, +acc: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match n:
    case 0n: acc
    case 1n++j: hshs_of(j, hsh(j) <> acc)

def tmpsos(n: Nat, +acc: List<&2, Ty.Solid>) -> List<&2, Ty.Solid>:
  match n:
    case 0n: acc
    case 1n++j:
      +hs = hsh(j)
      tmpsos(j, Ty.So{0u64, hs, []} <> acc)

def k1temp(+vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>,
    +sos: List<&2, Ty.Solid>, +hsos: List<&2, Ty.HSolid>,
    +hshs: List<&2, Ty.HShell>) -> Ty.Brep:
  Ty.Br{vs, es, ces, lps, fas, shs, sos, Ty.Cp{hsos, hshs}, 0u64}

def comp_sample_ce(cs: List<&2, Ty.HCoedge>, +st: AS) -> V.Point:
  match cs:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      +ce = nth_ce0(as_ces(st), Ty.hc_idx(h))
      +ed = nth_ed0(as_es(st), Ty.he_idx(Ty.ce_edge(ce)))
      Ty.vx_p(nth_vx0(as_vs(st), Ty.hv_idx(Ty.ed_v0(ed))))

def comp_sample_lp(ls: List<&2, Ty.HLoop>, +st: AS) -> V.Point:
  match ls:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +h <> +t:
      +lp = nth_lp0(as_lps(st), Ty.hlp_idx(h))
      comp_sample_ce(Ty.lp_ces(lp), st)

def comp_sample(+faces: List<&2, Nat>, +st: AS) -> V.Point:
  match faces:
    case []: V.Pt{0.0f64, 0.0f64, 0.0f64}
    case +f <> +t:
      +fa = nth_fa0(as_fas(st), f)
      comp_sample_lp(Ty.fa_loops(fa), st)

def comp_fds_go(fs: List<&2, SO.Fd>, +inc: List<&2, Nat>, +acc: List<&2, SO.Fd>) -> List<&2, SO.Fd>:
  match fs:
    case []: acc
    case +h <> +t: comp_fds_go(t, inc,
      Bool.pick(List<&2, SO.Fd>, nat_mem(SO.fd_fi(h), inc), h <> acc, acc))

def comp_fds(+fs: List<&2, SO.Fd>, +inc: List<&2, Nat>) -> List<&2, SO.Fd>:
  comp_fds_go(fs, inc, [])

def cav_find_step(+skip: Bool, +pt: V.Point, +fds: List<&2, SO.Fd>, +h: GRP, +gi: Nat,
    +acc: Nat, +nf: Nat) -> Nat:
  match skip:
    case True{}: acc
    case False{}:
      +of = comp_fds(fds, grp_fs(h))
      +c = SO.classify_in(of, SO.bbox(of, []), pt)
      Bool.pick(Nat, Bool.and(U64.is_eq(c, 1u64), Nat.is_eq(acc, nf)), gi, acc)

def cav_find_go(gs: List<&2, GRP>, +pt: V.Point, +fds: List<&2, SO.Fd>, +own: Nat, +gi: Nat,
    +acc: Nat, +nf: Nat) -> Nat:
  match gs:
    case []: acc
    case +h <> +t:
      cav_find_go(t, pt, fds, own, Nat.add(gi, 1n),
        cav_find_step(Nat.is_eq(grp_r(h), own), pt, fds, h, gi, acc, nf), nf)

def cav_find(+gs: List<&2, GRP>, +pt: V.Point, +fds: List<&2, SO.Fd>, +own: Nat,
    +nf: Nat) -> Nat:
  cav_find_go(gs, pt, fds, own, 0n, nf, nf)

def sk_of(+o: Bool) -> Ty.ShellKind:
  Bool.pick(Ty.ShellKind, o, Ty.SK_outer{}, Ty.SK_inner{})

def shells_go(gs: List<&2, GRP>, +conts: List<&2, Nat>, +nf: Nat, +acc: List<&2, Ty.Shell>, +gi: Nat) -> List<&2, Ty.Shell>:
  match gs:
    case []: List.reverse(&2, Ty.Shell, acc)
    case +h <> +t:
      +fh = hfas_of(grp_fs(h), [])
      +sk = sk_of(Nat.is_eq(nat_nth(conts, gi), nf))
      shells_go(t, conts, nf, Ty.Sh{gen1(gi), fh, sk} <> acc, Nat.add(gi, 1n))

def shells_of(gs: List<&2, GRP>) -> List<&2, Ty.Shell>:
  shells_go(gs, [], 0n, [], 0n)

def cont_ok_go(cs: List<&2, Nat>, +full: List<&2, Nat>, +nf: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t: cont_ok_go(t, full, nf,
      Bool.and(ok, Bool.or(Nat.is_eq(h, nf), Nat.is_eq(nat_nth(full, h), nf))))

def cont_ok(+cs: List<&2, Nat>, +nf: Nat) -> Bool:
  cont_ok_go(cs, cs, nf, True{})

def conts_go(gs: List<&2, GRP>, +all: List<&2, GRP>, +st: AS, +fds: List<&2, SO.Fd>,
    +nf: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match gs:
    case []: List.reverse(&2, Nat, acc)
    case +h <> +t:
      +pt = comp_sample(grp_fs(h), st)
      conts_go(t, all, st, fds, nf, cav_find(all, pt, fds, grp_r(h), nf) <> acc)

def conts_of(+gs: List<&2, GRP>, +st: AS, +fds: List<&2, SO.Fd>, +nf: Nat) -> List<&2, Nat>:
  conts_go(gs, gs, st, fds, nf, [])

def cavs_go(cs: List<&2, Nat>, +i: Nat, +gi: Nat, +acc: List<&2, Ty.HShell>) -> List<&2, Ty.HShell>:
  match cs:
    case []: acc
    case +h <> +t: cavs_go(t, i, Nat.add(gi, 1n),
      Bool.pick(List<&2, Ty.HShell>, Nat.is_eq(h, i), hsh(gi) <> acc, acc))

def solids_go(gs: List<&2, GRP>, +conts: List<&2, Nat>, +gi: Nat, +nf: Nat,
    +acc: List<&2, Ty.Solid>, +si: Nat) -> List<&2, Ty.Solid>:
  match gs:
    case []: List.reverse(&2, Ty.Solid, acc)
    case +h <> +t:
      +c = nat_nth(conts, gi)
      +cv = cavs_go(conts, gi, 0n, [])
      +hs = hsh(gi)
      +keep = Nat.is_eq(c, nf)
      solids_go(t, conts, Nat.add(gi, 1n), nf,
        Bool.pick(List<&2, Ty.Solid>, keep, Ty.So{gen1(si), hs, cv} <> acc, acc),
        Bool.pick(Nat, keep, Nat.add(si, 1n), si))

type KAB is Data:
  KAB{ ok: Bool, why: U64, brep: Ty.Brep, fk: List<&2, SO.KF> }

def kab_ok(+r: KAB) -> Bool:
  KAB{ok, why, brep, fk} = r
  ok

def kab_why(+r: KAB) -> U64:
  KAB{ok, why, brep, fk} = r
  why

def kab_brep(+r: KAB) -> Ty.Brep:
  KAB{ok, why, brep, fk} = r
  brep

def kab_fk(+r: KAB) -> List<&2, SO.KF>:
  KAB{ok, why, brep, fk} = r
  fk

def k1asm_sos(+none: Bool, +sos: List<&2, Ty.Solid>, +vs: List<&2, Ty.Vertex>,
    +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>, +lps: List<&2, Ty.Loop>,
    +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>, +ns: Nat, +no: Nat, +fk: List<&2, SO.KF>) -> KAB:
  match none:
    case True{}: KAB{False{}, 40u64, k1temp(vs, es, ces, lps, fas, shs, sos, [], []), fk}
    case False{}:
      KAB{True{}, 0u64, k1temp(vs, es, ces, lps, fas, shs, sos, hsos_of(no, []), []), fk}

def k1asm_fin(+cok: Bool, +cntok: Bool, +conts: List<&2, Nat>, +gs: List<&2, GRP>,
    +vs: List<&2, Ty.Vertex>, +es: List<&2, Ty.Edge>, +ces: List<&2, Ty.Coedge>,
    +lps: List<&2, Ty.Loop>, +fas: List<&2, Ty.Face>, +shs: List<&2, Ty.Shell>, +ns: Nat,
    +st: AS, +fk: List<&2, SO.KF>) -> KAB:
  match cok:
    case False{}: KAB{False{}, 31u64, k1temp(vs, es, ces, lps, fas, shs, [], [], []), fk}
    case True{}:
      match cntok:
        case False{}: KAB{False{}, 44u64, k1temp(vs, es, ces, lps, fas, shs, [], [], []), fk}
        case True{}:
          +sos = solids_go(gs, conts, 0n, as_nf(st), [], 0n)
          +no = List.length(&2, Ty.Solid, sos)
          +shk = shells_go(gs, conts, as_nf(st), [], 0n)
          k1asm_sos(Nat.is_eq(no, 0n), sos, vs, es, ces, lps, fas, shk, ns, no, fk)

def k1asm_nf(+empty: Bool, +st: AS, +pool: B.Tb<&2, SO.KF>, +rpool: B.Tb<&2, SO.KF>) -> KAB:
  match empty:
    case True{}: KAB{False{}, 40u64, k1temp([], [], [], [], [], [], [], [], []), []}
    case False{}:
      +p = comps_of(st)
      +n = as_nf(st)
      +gs = groups_go(erange(n, []), p, n, [])
      +shs = shells_of(gs)
      +ns = List.length(&2, Ty.Shell, shs)
      +sos0 = tmpsos(ns, [])
      +vs = as_vs(st)
      +es = as_es(st)
      +ces = as_ces(st)
      +lps = as_lps(st)
      +fas = as_fas(st)
      +hsos = hsos_of(ns, [])
      +hshs = hshs_of(ns, [])
      +tb = k1temp(vs, es, ces, lps, fas, shs, sos0, hsos, hshs)
      +fds = SO.fds_rr(tb, pool, rpool)
      +conts = conts_of(gs, st, fds, n)
      +cntok = Bool.and(Nat.is_eq(as_nv(st), List.length(&2, Ty.Vertex, vs)),
        Bool.and(Nat.is_eq(as_ne(st), List.length(&2, Ty.Edge, es)),
          Bool.and(Nat.is_eq(as_nc(st), List.length(&2, Ty.Coedge, ces)),
            Bool.and(Nat.is_eq(as_nl(st), List.length(&2, Ty.Loop, lps)),
              Nat.is_eq(as_nf(st), List.length(&2, Ty.Face, fas))))))
      k1asm_fin(cont_ok(conts, n), cntok, conts, gs, vs, es, ces, lps, fas, shs, ns, st, SO.kfs_of(tb, fds))

def as_rev(+a: AS) -> AS:
  AS{vs, es, ces, lps, fas, eks, nv, ne, nc, nl, nf, ms, nm} = a
  AS{List.reverse(&2, Ty.Vertex, vs), List.reverse(&2, Ty.Edge, es),
    List.reverse(&2, Ty.Coedge, ces), List.reverse(&2, Ty.Loop, lps),
    List.reverse(&2, Ty.Face, fas), List.reverse(&2, EK, eks), nv, ne, nc, nl, nf, ms, nm}

type VS2 is Data:
  VS2{ vs: List<&2, Ty.Vertex>, mp: List<&2, Nat> }

def vzeros(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: vzeros(j, 0n <> acc)

def vmark_go(es: List<&2, Ty.Edge>, +n: Nat, +used: B.Tb<&2, Nat>) -> B.Tb<&2, Nat>:
  match es:
    case []: used
    case +h <> +t:
      vmark_go(t, n, nat_put(nat_put(used, n, Ty.hv_idx(Ty.ed_v0(h)), 1n), n, Ty.hv_idx(Ty.ed_v1(h)), 1n))

def tb_take(n: Nat, +tn: B.Tb<&2, Nat>, +i: Nat) -> List<&2, Nat>:
  match n:
    case 0n: []
    case 1n+m: B.tb_get(Nat, tn, U32.from_nat(i)) <> tb_take(m, tn, Nat.add(i, 1n))

def vprune_go(fs: List<&2, Nat>, vs: List<&2, Ty.Vertex>, +new: Nat,
    +vcc: List<&2, Ty.Vertex>, +mcc: List<&2, Nat>) -> VS2:
  match fs vs:
    case +f <> +u +h <> +t:
      +used = Nat.is_eq(f, 1n)
      vprune_go(u, t, Bool.pick(Nat, used, Nat.add(new, 1n), new),
        Bool.pick(List<&2, Ty.Vertex>, used, Ty.Vx{gen1(new), Ty.vx_p(h)} <> vcc, vcc),
        Bool.pick(List<&2, Nat>, used, new <> mcc, 0n <> mcc))
    case _ _: VS2{List.reverse(&2, Ty.Vertex, vcc), List.reverse(&2, Nat, mcc)}

def ereidx_go(es: List<&2, Ty.Edge>, +mp: B.Tb<&2, Nat>, +n: Nat, +acc: List<&2, Ty.Edge>) -> List<&2, Ty.Edge>:
  match es:
    case []: List.reverse(&2, Ty.Edge, acc)
    case +h <> +t:
      Ty.Ed{+g, +v0, +v1, +k} = h
      ereidx_go(t, mp, n, Ty.Ed{g, hv(nat_at(mp, n, Ty.hv_idx(v0))), hv(nat_at(mp, n, Ty.hv_idx(v1))),
        k} <> acc)

def vs2_vs(+r: VS2) -> List<&2, Ty.Vertex>:
  VS2{vs, mp} = r
  vs

def vs2_mp(+r: VS2) -> List<&2, Nat>:
  VS2{vs, mp} = r
  mp

def k1prune(+st: AS) -> AS:
  AS{+vs, +es, +ces, +lps, +fas, +eks, +nv, +ne, +nc, +nl, +nf, +ms, +nm} = st
  +used = tb_take(nv, vmark_go(es, nv, B.tb_of(Nat, vzeros(nv, []), 0n)), 0n)
  +pr = vprune_go(used, vs, 0n, [], [])
  +vs2 = vs2_vs(pr)
  +mp = vs2_mp(pr)
  AS{vs2, ereidx_go(es, B.tb_of(Nat, mp, 0n), List.length(&2, Nat, mp), []), ces, lps, fas, eks, List.length(&2, Ty.Vertex, vs2), ne, nc,
    nl, nf, ms, nm}

def k1assemble_p(+st: AS, +pool: B.Tb<&2, SO.KF>, +rpool: B.Tb<&2, SO.KF>) -> KAB:
  +n = as_nf(st)
  k1asm_nf(Nat.is_eq(n, 0n), k1prune(as_rev(st)), pool, rpool)

def k1assemble(+st: AS) -> KAB:
  k1assemble_p(st, SO.pool_kf([]), SO.pool_kf([]))

def k1ed_gen(+e: Ty.Edge) -> U64:
  Ty.Ed{+g, +a, +b, +k} = e
  g

def k1hs_idx(+h: Ty.HShell) -> Nat:
  Ty.HS{+i, +g} = h
  i

def k1hcs_go(cs: List<&2, Ty.HCoedge>, +nc: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t: k1hcs_go(t, nc, Bool.and(ok, Nat.is_lt(Ty.hc_idx(h), nc)))

def k1hcs(cs: List<&2, Ty.HCoedge>, +nc: Nat) -> Bool:
  k1hcs_go(cs, nc, True{})

def k1hls_go(ls: List<&2, Ty.HLoop>, +nl: Nat, +ok: Bool) -> Bool:
  match ls:
    case []: ok
    case +h <> +t: k1hls_go(t, nl, Bool.and(ok, Nat.is_lt(Ty.hlp_idx(h), nl)))

def k1hls(ls: List<&2, Ty.HLoop>, +nl: Nat) -> Bool:
  k1hls_go(ls, nl, True{})

def k1hfs_go(fs: List<&2, Ty.HFace>, +nf: Nat, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t: k1hfs_go(t, nf, Bool.and(ok, Nat.is_lt(Ty.hfa_idx(h), nf)))

def k1hfs(fs: List<&2, Ty.HFace>, +nf: Nat) -> Bool:
  k1hfs_go(fs, nf, True{})

def k1hss_go(ss: List<&2, Ty.HShell>, +nsh: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t: k1hss_go(t, nsh, Bool.and(ok, Nat.is_lt(k1hs_idx(h), nsh)))

def k1hss(ss: List<&2, Ty.HShell>, +nsh: Nat) -> Bool:
  k1hss_go(ss, nsh, True{})

def k1hso_go(ss: List<&2, Ty.HSolid>, +nso: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t: k1hso_go(t, nso, Bool.and(ok, Nat.is_lt(Ty.hso_idx(h), nso)))

def k1hso(ss: List<&2, Ty.HSolid>, +nso: Nat) -> Bool:
  k1hso_go(ss, nso, True{})

def k1top(+top: Ty.Compound, +nso: Nat, +nsh: Nat) -> Bool:
  Bool.and(k1hso(Ty.cp_solids(top), nso), k1hss(Ty.cp_shells(top), nsh))

def k1vs_go(vs: List<&2, Ty.Vertex>, +i: Nat, +ok: Bool) -> Bool:
  match vs:
    case []: ok
    case +h <> +t: k1vs_go(t, Nat.add(i, 1n), Bool.and(ok, U64.is_eq(Ty.vx_gen(h), gen1(i))))

def k1es_go(es: List<&2, Ty.Edge>, +i: Nat, +nv: Nat, +ok: Bool) -> Bool:
  match es:
    case []: ok
    case +h <> +t:
      +e0 = Ty.hv_idx(Ty.ed_v0(h))
      +e1 = Ty.hv_idx(Ty.ed_v1(h))
      k1es_go(t, Nat.add(i, 1n), nv,
        Bool.and(ok, Bool.and(Nat.is_lt(e0, nv),
          Bool.and(Nat.is_lt(e1, nv), U64.is_eq(k1ed_gen(h), gen1(i))))))

def k1ces_go(cs: List<&2, Ty.Coedge>, +i: Nat, +ne: Nat, +ok: Bool) -> Bool:
  match cs:
    case []: ok
    case +h <> +t:
      k1ces_go(t, Nat.add(i, 1n), ne,
        Bool.and(ok, Bool.and(Nat.is_lt(Ty.he_idx(Ty.ce_edge(h)), ne),
          U64.is_eq(Ty.ce_gen(h), gen1(i)))))

def k1lps_go(ls: List<&2, Ty.Loop>, +i: Nat, +nc: Nat, +ok: Bool) -> Bool:
  match ls:
    case []: ok
    case +h <> +t:
      k1lps_go(t, Nat.add(i, 1n), nc,
        Bool.and(ok, Bool.and(k1hcs(Ty.lp_ces(h), nc), U64.is_eq(Ty.lp_gen(h), gen1(i)))))

def k1fas_go(fs: List<&2, Ty.Face>, +i: Nat, +nl: Nat, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t:
      k1fas_go(t, Nat.add(i, 1n), nl,
        Bool.and(ok, Bool.and(k1hls(Ty.fa_loops(h), nl), U64.is_eq(Ty.fa_gen(h), gen1(i)))))

def k1shs_go(ss: List<&2, Ty.Shell>, +i: Nat, +nf: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t:
      k1shs_go(t, Nat.add(i, 1n), nf,
        Bool.and(ok, Bool.and(k1hfs(Ty.sh_faces(h), nf), U64.is_eq(Ty.sh_gen(h), gen1(i)))))

def k1sos_go(ss: List<&2, Ty.Solid>, +i: Nat, +nsh: Nat, +ok: Bool) -> Bool:
  match ss:
    case []: ok
    case +h <> +t:
      k1sos_go(t, Nat.add(i, 1n), nsh,
        Bool.and(ok, Bool.and(Nat.is_lt(k1hs_idx(Ty.so_outer(h)), nsh),
          Bool.and(k1hss(Ty.so_cavities(h), nsh), U64.is_eq(Ty.so_gen(h), gen1(i))))))

def zeros(n: Nat, +acc: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n: acc
    case 1n++j: zeros(j, 0n <> acc)

def uinc(+tn: B.Tb<&2, Nat>, +n: Nat, +i: Nat) -> B.Tb<&2, Nat>:
  nat_put(tn, n, i, Nat.add(nat_at(tn, n, i), 1n))

def k1use_go(cs: List<&2, Ty.Coedge>, +n: Nat, +acc: B.Tb<&2, Nat>) -> B.Tb<&2, Nat>:
  match cs:
    case []: acc
    case +h <> +t: k1use_go(t, n, uinc(acc, n, Ty.he_idx(Ty.ce_edge(h))))

def k1use_all(xs: List<&2, Nat>, +ok: Bool) -> Bool:
  match xs:
    case []: ok
    case +h <> +t: k1use_all(t, Bool.and(ok, Nat.is_eq(h, 2n)))

def k1use(+ces: List<&2, Ty.Coedge>, +ne: Nat) -> Bool:
  k1use_all(tb_take(ne, k1use_go(ces, ne, B.tb_of(Nat, zeros(ne, []), 0n)), 0n), True{})

def k1slv_ok(+h: Ty.Face) -> Bool:
  Bool.and(T.is_finite(Ty.fa_slv(h)), Bool.and(T.is_finite(Ty.fa_sla(h)),
    Bool.and(F64.is_le(0.0f64, Ty.fa_slv(h)), F64.is_le(0.0f64, Ty.fa_sla(h)))))

def k1slv_go(fs: List<&2, Ty.Face>, +ok: Bool) -> Bool:
  match fs:
    case []: ok
    case +h <> +t: k1slv_go(t, Bool.and(ok, k1slv_ok(h)))

type KCT is Data:
  KCT{ ok: Bool, why: U64 }

def kct_ok(+r: KCT) -> Bool:
  KCT{ok, why} = r
  ok

def kct_why(+r: KCT) -> U64:
  KCT{ok, why} = r
  why

def k1cert(+b: Ty.Brep) -> KCT:
  +vs = Ty.brep_vs(b)
  +es = Ty.brep_es(b)
  +ces = Ty.brep_ces(b)
  +lps = Ty.brep_lps(b)
  +fas = Ty.brep_fas(b)
  +shs = Ty.brep_shs(b)
  +sos = Ty.brep_sos(b)
  +nv = List.length(&2, Ty.Vertex, vs)
  +ne = List.length(&2, Ty.Edge, es)
  +nc = List.length(&2, Ty.Coedge, ces)
  +nl = List.length(&2, Ty.Loop, lps)
  +nf = List.length(&2, Ty.Face, fas)
  +nsh = List.length(&2, Ty.Shell, shs)
  +nso = List.length(&2, Ty.Solid, sos)
  +idx = Bool.and(k1vs_go(vs, 0n, True{}),
    Bool.and(k1es_go(es, 0n, nv, True{}),
      Bool.and(k1ces_go(ces, 0n, ne, True{}),
        Bool.and(k1lps_go(lps, 0n, nc, True{}),
          Bool.and(k1fas_go(fas, 0n, nl, True{}),
            Bool.and(k1shs_go(shs, 0n, nf, True{}),
              Bool.and(k1sos_go(sos, 0n, nsh, True{}),
                k1top(Ty.brep_top(b), nso, nsh))))))))
  +use = k1use(ces, ne)
  +slv = k1slv_go(fas, True{})
  KCT{Bool.and(idx, Bool.and(use, slv)),
    Bool.pick(U64, idx, Bool.pick(U64, use, Bool.pick(U64, slv, 0u64, 43u64), 42u64), 41u64)}

type KR is Data:
  KR{ ok: Bool, why: U64, brep: Ty.Brep, nv: Nat, ne: Nat, nf: Nat, nc: Nat, fk: List<&2, SO.KF> }

def kr_ok(+r: KR) -> Bool:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  ok

def kr_why(+r: KR) -> U64:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  why

def kr_brep(+r: KR) -> Ty.Brep:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  brep

def kr_nv(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  nv

def kr_ne(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  ne

def kr_nf(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  nf

def kr_nc(+r: KR) -> Nat:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  nc

def kr_fk(+r: KR) -> List<&2, SO.KF>:
  KR{ok, why, brep, nv, ne, nf, nc, fk} = r
  fk

def k1run_e(+okt: Bool, +whyt: U64, +brep: Ty.Brep, +fk: List<&2, SO.KF>) -> KR:
  match okt:
    case False{}: KR{False{}, whyt, brep, 0n, 0n, 0n, 0n, fk}
    case True{}:
      KR{True{}, 0u64, brep, List.length(&2, Ty.Vertex, Ty.brep_vs(brep)),
        List.length(&2, Ty.Edge, Ty.brep_es(brep)),
        List.length(&2, Ty.Face, Ty.brep_fas(brep)),
        List.length(&2, Ty.Solid, Ty.brep_sos(brep)), fk}

def k1run_d(+okc: Bool, +whyc: U64, +brep: Ty.Brep, +fk: List<&2, SO.KF>) -> KR:
  match okc:
    case False{}: KR{False{}, whyc, brep, 0n, 0n, 0n, 0n, fk}
    case True{}:
      +ct = k1cert(brep)
      k1run_e(kct_ok(ct), kct_why(ct), brep, fk)

