# C14 laws: what the kernel proves about assemblies

C14 proves 181 laws over the production assembly path (`asm
solve|interf|clear|explode|faces`). Every law quantifies over its
inputs, lives in `laws/c14/LAWS.bend`, and is proven in
`laws/c14/PROOF.bend` through reduction (`{==}` after unfolding one
stage). All 181 pass both `--check-only` and `--verdict`. Nineteen
planted mutants are all killed. A dead-code audit shows all 125
`src/c14/asm.bend` definitions reachable from `asm_go`.

## Families

1. Accessors (15 laws). The instance, mate, assembly, and placed-node
   projections return their own fields. Killed mutant: `inst_node`
   returns the turn code.
2. Argument and number helpers (18 laws). String concatenation,
   list-drop, F64/U64 argument decoders, the 6/7/9-number packs, the
   finiteness scan, the nonzero scan, entry-kind and mate dispatch.
   Killed mutant: the coincident pack takes five numbers.
3. Instance index (5 laws). Name membership, lookup, and positional
   index over the instance list.
4. Instance scan (15 laws). Duplicate detection, per-entry wrap, the
   accumulator update, and the empty/nonempty recursion. Killed mutant:
   the empty scan refuses instead of accepting.
5. Mate scan (16 laws). Reference checking against the instance list,
   per-entry wrap, the accumulator update, and the empty/nonempty
   recursion.
6. Parse join (14 laws). Mate-list join, the instance-result fold, the
   `assembly` head gate, the single-form gate, and the parse/ok wiring.
   Killed mutants: the parse-failure reason is reworded; the empty
   assembly is accepted.
7. Solver wiring (14 laws). The three-per-instance column layout,
   fix/coincident/plane/axis row arities (3/3/1/2), per-kind dispatch
   (kind 4 builds two rows), row concatenation, the declared-translation
   vector, and the least-squares conversion. Killed mutants: fix mates
   build no rows; the axis arm builds plane rows; declared translations
   drop a component; columns pack four per instance.
8. Residual audit (12 laws). The max-residual fold, the id-set helpers,
   the violator and redundancy folds, the ordering projection, and the
   verdict: an empty violator list solves, a nonempty one conflicts.
   Killed mutant: the verdict arms are swapped, so conflicts publish
   and solutions refuse.
9. Reports (12 laws). Id-list rendering, the lineage fold, per-instance
   lines, the solved/underconstrained renders, and the conflict render.
   Killed mutants: lineage prints `=N`; id lists open with `(`.
10. Placement and pairs (14 laws). Failure-silent placement, per-node
    placement, the all-instances fold, the pair flag (clearance vs
    relation), the pair recursion, the pairs render, and the explode
    fold and render. Killed mutants: interf renders clearances;
    placement wipes the failure diagnosis; the pair flag arms are
    swapped.
11. Faces (16 laws). The role-name classifier (cavity/top/bottom/wall),
    the seven-kind surface classifier, the face-row fold, known/unknown
    instance dispatch, and the faces render wiring. Killed mutants: the
    plane kind prints `cylinder`; rows print `loop=`.
12. Dispatch (30 laws). The per-verb output builder (five verbs plus
    default), the conflict/ok output arms, unknown/failed/ok node
    staging, the error-prefix fold, the query entry, the explode-args
    gate, the faces-args gate, verb codes, and the top-level wiring.
    Killed mutants: the solve verb runs interf; the unknown-node reason
    is reworded.

## What is not proven

Floats are axiomatic: no law depends on F64 arithmetic computing. Row
constants, the 1e-9 audit bound's fitness, residual magnitudes, dof
values on fixtures, and oracle agreement are evidenced by pins and E2E,
not proofs. The exact kind-4→`rows_axis` identity law is deferred to
pins/E2E (unfolding it spins 91 s in F64 soft-float terms); the arity
law plus the axis pins and the plane+axis journey cover it. Two
first-choice mutants were replaced after failing-check blowup (checker
inequality on giant stuck F64 terms is pathological): the fix-rows
mutant is arm-1→`[]`, killed via `mate_rows_fix`, and the lineage
mutant is `=n`→`=N`, killed via `lin_cons`.
