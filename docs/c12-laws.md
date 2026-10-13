# C12 laws: what the kernel proves about interchange

C12 proves 64 laws over the production interchange paths (`step`,
`archive`, `stl`, `3mf`, `step_import`, `reopen`, `step_of`, `stl_of`,
`3mf_of`). Every law quantifies over its inputs, lives in
`laws/c12/LAWS.bend`, and is proven in `laws/c12/PROOF.bend` through
reduction (`{==}` after unfolding one stage). All 64 pass both
`--check-only` and `--verdict`. Nine planted mutants (one per family plus two regression)
are all killed.

## Families

1. Archive envelope (8 laws). The units gate is exactly the `mm`
   comparison, every envelope refusal returns its exact named reason,
   and the accepted envelope assembles version, units, lineage, and the
   canonical B1 body. Killed mutant: `ar_units_ok` accepts everything.
2. Entity classifier (20 laws). `sr_kind_of` maps each profile entity
   name to its exact kind number, complex rational splines to 7, SI
   units to 29, voids to 30, `MAPPED_ITEM` (assembly instance) to
   31, and unknown names to 0 (skipped, except at use sites,
   which fail loudly); the empty name-list match is false. Killed
   mutant: `CARTESIAN_POINT` maps to 2.
3. Writer staging (3 laws). The wrapped entity count includes the
   three-entity units block, refusal keeps the stage reason, and the
   units block carries `.MILLI.` + `.METRE.`. Killed mutant: the count
   adds 3 instead of 2.
4. Reader refusal closure (18 laws). Every parse stage maps a false
   gate to its exact named refusal (entity cap, entity parse, sort,
   duplicate id, units, open shell, voids, assembly instances,
   vertex/edge/shell/solid walks), and every edge/face/loop/coedge and
   curve/surface failure names its stage with the entity id. Killed
   mutant: the entity-cap refusal is reworded.
5. Section scan (3 laws). The DATA extractor returns the accumulator on
   empty input, enters on `DATA;`, and stops on `ENDSEC;`. Killed
   mutant: `DATA;` fails to enter.
6. Mesh gates (7 laws). OBJ `v`/`f` headers classify by their first two
   bytes, short lines classify as neither, CRC starts from all-ones and
   finalizes by xor, byte pairs have length 2, and the byte walker
   returns its accumulator on empty input. Killed mutant: the `v`
   header byte becomes `w`.
7. Structure (3 laws). The archive drops exactly its three envelope
   fields, the rank range peels one element, and the top pair has length
   2. Killed mutant: the envelope drop returns the wrong tail.
8. Regression (2 laws). The char-list string builder un-reverses its
   accumulator (the planted reverse broke every line, token, name, and
   body in the reader), and the parsed brep's stamp covers its highest
   generation (the planted zero stamp failed `mk_brep` on every
   import). Killed mutants: the re-added reverse, and the zero stamp.

## What is not proven

Floats are axiomatic: no law depends on F64 arithmetic computing.
Recovery numerics (frame normalization, tan-half-angle, trim
projection), CRC bit-correctness, zip acceptance by readers, and
oracle agreement are evidenced by pins and E2E, not proofs. The
multi-thousand-definition validators (`brep_checked`, the full
`sr_file` pipeline) are exercised by pins, E2E journeys, and neg
journeys; the laws pin their stage functions' contracts, which is what
keeps each refusal firing on exactly its own branch.
