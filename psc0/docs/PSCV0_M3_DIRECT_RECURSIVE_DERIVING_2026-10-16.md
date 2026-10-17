# M3+B — checked direct-recursive deriving

16 October 2026. **Implementation candidate; qualification is pending. M3+B remains OPEN.** Reapplied the user's v7.2 stage-entry prompt, inspected current HEAD/CI and the corresponding pinned Lean sources before this slice. This extends the existing deriving owner, not the language specification or trusted foundation.

## Scope and evidence baseline

v7.2 alone remains normative for `.ps`: reference blob `694115223777599ba28ee175e14bb642b7b6aa4b`, SHA256 `c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e`. Its selected Hashable deriving and broader M3 data/recursion obligations motivate this slice. M2+A at2a707206/acceptance280e1e4e remains unchanged historical acceptance.

Initial live HEAD c8d5521ce895a26d44c5fe2c80e03a33026c6c11 added partial logical checking. A concurrent7ad23de88482c2b09d8dbfd066c98eee6d6de6e1 corrected the command-dispatch layout; it is preserved without replacement. Its independent F1/F2/F3 runs38882181756/38882181672/38882181892 passed. Native38882181825/job116911291299 compiled the compiler but failed the measurement harness at lines270–271 because `prefix` was used as a Lean variable name. Repair062fee20a6fd05b9f67ee05627cacaa2da1a4c67 renames only that binding to diagnosticPrefix (two-line diff); assertions, budgets and benchmark workloads are unchanged. Partial semantic cases still require execution, not merely successful compilation.

## Pinned implementation study

Official Lean4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:

- `src/Lean/Elab/Deriving/Hashable.lean`: seeds each constructor by its index and combines field hashes in source order through mixHash. Its general recursive helpers and partial fallback are not silently imported as logical authority.
- `tests/elab/derivingHashable.lean`: structure-like, recursive, nested and mutual examples distinguish the upstream capability from this slice's smaller direct-recursion scope.
- PSC0 `Elab/Data.lean`, `Meta/Inductive.lean` and `Elab/DerivingContext.lean`: actual constructor metadata, recursor minor telescope, motive levels and field ownership. Existing recursors put fields before their recursive hypotheses. The former deriving builder rejected recursive fields and exposed no induction evidence.

## Shared mechanism

DerivingContext now provides an explicitly recursion-enabled field validator and eliminator builder. It checks recursive field positions for bounds/uniqueness and verifies their instantiated types equal the uniform family. It opens each actual recursor minor with all fields and induction hypotheses, checks hypothesis types against the selected motive, and checks the minor conclusion. The branch callback receives induction evidence keyed by the fresh local field ID. Closing the full telescope retains scope and ordinary Core typing.

The existing nonrecursive API delegates with recursion disabled. BEq, DecidableEq and Repr retain their previous refusal boundary until their own recursive algorithms and evidence are implemented. This is an internal capability boundary, not a legacy language-version mode.

Hashable is the first consumer: a direct child hash is the recursor-provided induction result; other fields retain ordinary checked Hashable dictionary selection. Constructor seeds, field order, mixHash semantics, generic requirements and existing proof-field behavior remain unchanged. No recursive dictionary assumption, new axiom, partial definition, source-name shortcut or backend-specific semantics are introduced. The generated definition goes through the same official-kernel/typed-erasure/checked-IR pipeline.

## Focused qualification

One generic binary-tree source fixture instantiates Nat and Bool, with two recursive children, nested values and a kernel-checked defining law. An independently compiled pinned Lean deriving instance supplies the expected UInt64 results. The same fixture requests direct JS, TS, Rust, Wasm GC core and component output, exporting only two Bool-to-UInt64 functions. Recursive language data stay internal GC/typed data, not a new foreign recursive-value ABI.

Three negative sources must reject at their intended elaboration rules: nested recursion, indexed deriving, and a recursive family with an unhashable function field. A generic unrelated failure is not a passing negative test.

The additive `psc0-m3-recursive-deriving.yml` workflow compiles native Lean, checks source/kernel/IR emission, runs JS and strict compiled TS, runs Rust using the existing lock, and compares V8 GC core/Wasmtime components with the same native oracle. It has read-only permissions and the existing tool/action pins. The original native and independent workflows remain unchanged and are required for whole-closure qualification. An artifact records the source SHA, source, expected results, emitted outputs and logs. Until those checks finish successfully, this is not qualified functionality.

## Remaining work and trust boundary

This is not complete recursive/indexed/dependent/mutual deriving or full M3+B. Nested/mutual data and elimination, broader total recursion, partial P0 execution/assurance and selected P1 fixedpoints remain open. The partial executable refusal marker from the parent candidate is preserved. No additional classical assumptions, proof holes, kernel changes, pskernel-core, self-hosting or C5 execution. No benchmark gains are claimed by this slice; the separately measured runtime133af061 and paired38840337837 evidence remain authoritative.
