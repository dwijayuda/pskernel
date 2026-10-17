# M3+B — direct-recursive Repr through checked induction

16 October 2026. Candidate implementation; exact qualification is pending. M3+B remains OPEN. v7.2 is the sole forward source reference; no legacy mode or foundational change.

## Stage entry and source basis

Reapplied the attached user prompt and PSCV0_V72_STAGE_DIRECTIVE_2026-10-16. Read live58d439f36094dc9aa79217eadec58bc7ea8290b9, both handoffs, the selected deriving requirement in v7.2 §0A/source-selection registry, current DerivingContext/Repr, and official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc src/Lean/Elab/Deriving/Repr.lean and tests/elab/derivingRepr.lean. Upstream recursively prints a direct child at max_prec; explicit fields retain constructor order, types/proofs print underscores, hidden inductive fields are omitted, and parenthesization/nesting depends on precedence. Upstream nested/mutual partial-helper fallback is not adopted by this smaller checked direct-recursion slice.

The preceding58d439 native38890154136 and focused Hashable38890154087 completed successfully. The capture-avoiding abstracted-motive checks remain unchanged. Earlier pending/failure snapshots and all accepted M2/performance receipts remain in history.

## Implementation

Repr plans independent field dictionaries once. Direct recursive fields are validated by the existing recursion-enabled field planner and obtain Nat-to-Format printers from the existing checked recursor minor, keyed by actual field IDs. Rendering applies that induction printer to1024 rather than asking instance search for a self dictionary. The motive is a total function from precedence to Format. No new recursive-call representation, partial definition, assumption, source-name shortcut or backend behavior is introduced.

Structure formatting keeps recursion disabled and its original projection path. Constructor naming, source-order explicit fields, proof/type placeholders, precedence, grouping and nesting are unchanged. Missing induction evidence fails with a handler-specific diagnostic. Nested/indexed/mutual families and missing independent dictionaries retain their previous fail-closed boundaries.

## Focused evidence plan

Extend the existing generic binary-tree Hashable fixture with Repr rather than creating another test executable/workflow. The native oracle uses the exact same public family name, so text is compared without a rename normalization. Nat and Bool payloads, two recursive children and nested constructors render at root precedences0/1024 and width40. Native oracle strings are embedded as source literals and retained in expected.json. Generated functions compare their computed text exactly to the selected oracle text and export UInt64 one/zero; every selected VM must return one. This compares strings directly, not string hashes, and preserves the existing scalar foreign ABI with GC recursive data internal.

Keep the original checked Hashable law and three refusal cases. Add the corresponding three Repr nested/indexed/missing-dictionary refusals at their exact elaboration rule. All JS/strict TS/Rust/V8-GC/Wasmtime execution checks remain mandatory. Full native and independent logical workflows are also required. No iterations, budgets, assertions, original benchmark workloads, or qualification commands change.

This is not full M3+B, mutual/indexed deriving, partial runtime admission, a general compiler-preservation theorem or a performance result. Broader data/elimination, well-founded recursion, deriving and selected P0/P1 obligations remain open. Only propext/Quot.sound; no pskernel-core, self-hosting or C5 execution.
