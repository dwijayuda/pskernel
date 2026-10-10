# PSCV P1-M — explicit imported generic/concrete dictionary applications

The preceding P1-J batch observed actual generic and concrete selected
Lean typeclass instances for 42 arithmetic operator/type rows in the
pinned Lean **4.35.0-rc3** environment. Independent `#synth` results
do not prove a dependency relation between the two choices.

P1-M generates explicit `@instHAdd T selectedAddT`,
`@instHSub T selectedSubT` and
`@instHMul T selectedMulT` terms wherever the selected generic
head is exactly the corresponding known imported Lean constructor.
Each candidate is emitted as an `example : H* T T T := ...` and
must typecheck in the same pinned Lean environment. Rows where a
specialized generic term is selected remain explicitly excluded,
not silently assumed compatible.

The generator binds to the qualified P1-J observation digest
`364b16cbf5b972411cb00006fc1bcf596671ba57dfcbc7ad23f8517fb63b3c4b`,
requires all 42 exact normative rows, and preserves a report of
attempted and excluded relationships. A failed Lean check refuses
the qualification. This demonstrates concrete source-level typed
instance application where Lean succeeds, rather than merely
recording two identical-looking names.

**Limits:** imported Lean declarations are not the PSCV closed
Standard registry; even an explicitly typed dictionary construction
does not establish the real instance-search priority, scope/import
tie resolution, the corresponding source snapshot-ID, codegen
semantics, or backend executable correctness. No release-certified
PSCV proof term is produced.

The normative source still has **230 required surface rows, 194
distinct IDs, and 191 unresolved Standard mappings**. P1 semantic
registry closure, effect/WP rules, approval and conformance remain
required before P2's source certification. P3–P5 remain later
soundness gates per [PSCV_P1_TO_P5_SOUND_GATES.md](PSCV_P1_TO_P5_SOUND_GATES.md).

The standard compiler, PSKernel Core, selected seed, TypeScript7,
npm release and protected PSCV publication gate remain unchanged.
