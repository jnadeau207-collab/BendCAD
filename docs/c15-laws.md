# C15 laws

20 laws in 6 families. Every law quantifies over its inputs and passes
both the checker and the Lean-proven kernel. Every family kills its
planted mutants (`python3 tools/laws/mutate.py c15`). There are no
accessor laws and no whole-body restatements: a fixed input with a
fixed expected output is a pin in `tests/c15/pins.bend`, and dispatch
codes, refusal strings and entity templates are pinned, not proven.

## F1 — selector validity (4 laws)

`sel_mem_nil`, `sel_mem_hit`: the empty face table resolves nothing;
a name hit resolves regardless of the tail. `sel_idx_hit`: a hit
returns the current index. `res_all_len` (induction): resolution maps
every entry to exactly one verdict — no annotation is silently
dropped. Mutants killed: empty-table-claims-all, verdict-drop.

## F2 — per-state counts (3 laws)

`stk_rows_len`, `clr_rows_len` (both induction): every stack and every
toler clearance renders exactly one row per state. `states_nonempty`:
a declared state list passes through untouched (the default applies
only to the empty list, pinned). Mutants killed: row-drop,
first-state-drop.

## F3 — refusal closure and non-publishing (4 laws)

`fb_bad`: the first bad verdict wins, deterministically.
`check_fb_bad`: a bad verdict renders the refusal, never lines.
`file_fb_bad`: a bad verdict yields `FR_err`, never file content —
failure publishes nothing. `check_empty_ok`: the empty set checks ok.
Mutants killed: first-failure-skipped, failure-smuggled-as-line.

## F4 — state gating (1 law)

`st_go_false`: a bad grow refuses as `bad-state`. Mutant killed:
bad-state-accepted. Envelope bound order and per-state row content are
formatting, evidenced by the `toler.envelope` and `stack.*` journeys,
which check each bound exactly.

## F5 — emission base and failure propagation (3 laws)

`emit_nil`: the empty set emits no entities and holds the base id.
`em_dt_halt`: a failed accumulator stays failed through datum
emission. `em_ok_false`: a failed accumulator fails the number gate
whatever the numbers. Sequential numbering and exact entity text are
pinned; the independent reader re-verifies contiguity end to end.
Mutants killed: base-bump, halt-drop.

## F6 — parse gates (5 laws)

`entry_atom`: a bare atom is not an entry. `ps_go_false`,
`one_go_false`, `head_go_false`: tokenizer failure, wrong form count
and wrong head all refuse as `pmi-parse-failed`. `dup_go_true`: a
seen name is a duplicate. Mutants killed: duplicates-pass,
parse-failure-reworded.
