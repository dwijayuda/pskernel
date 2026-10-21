# PSC1 development roadmap

Updated 2026-10-21 by explicit user priority pivot. This roadmap supersedes the
self-host-first ordering in earlier continuation prompts and architecture notes.
The goal is a complete, correct practical compiler/language across both authored
.lean/.ps input grammars and all seven target mappings.

1. Complete the finite fourteen-family Practical Core contract in
   PSC1_PRACTICAL_CORE_DECISIONS.md. Start with missing cross-target CompilerM
   state/error/control coverage and executable per-case parity enforcement.
   Continue checked Prop-valued Nat/Int order, bounded inference/pattern/control
   interactions and typed console plus UTF-8 file IO with explicit capabilities.
2. Close reached backend gaps, including Rust owned callback values/captures,
   deep traversal/destruction and Wasm W1-W6 adapters. Preserve public ABI
   refusals until actual marshalling is supported. Measure realistic application
   compilation and runtime behavior under existing limits.
3. Keep independent pinned official checking, exact ordinary source/logical
   graph pairing, strict original/transformed IR and every existing refusal,
   native, target, scoped and package regression. G1 functionality runs the
   existing four positive/four negative cases after one native seed; no native
   frontend/emitter delegation afterwards. All closures remain complete.
4. At a stable feature-frozen milestone, explicitly run the separate manual
   psc1-selfhost-qualification workflow for full G1 -> G2 -> G3, identical
   compiler source/graph/IR/artifacts and actual repeated corpus observations.
   Rust repeat generations follow its completed architecture/runtime contract.
   Manual failures do not gate ordinary language/backend development.

G2/G3 are deferred, not passed or removed. The full generation assertions,
publication/refusal checks, pinned tools and unchanged process/heap/stack limits
remain in the manual workflow. G2 CPU and immutable fixed-workload comparison
workflows are manual as well. G1 artifacts now retain 90 days; source and exact
historical qualification receipts remain in Git history. Artifact retention is
finite; a feature-freeze run must produce fresh evidence, never infer it from
expired downloads.

Tracked performance defect: PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md. Address
its mechanisms when normal source/application compilation demonstrates need;
do not chase fixed points before feature freeze. No family is selected-v1
complete until its finite both-grammar x relevant-target obligations pass.
