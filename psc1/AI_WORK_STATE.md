# PSC1 current work state — scoped correctness and readable output

Updated 2026-10-20. Active branch: `fix/psc1-scoped-correctness-20261020`.

## User goal and boundaries

Repair corrected PSKernel-Core integration, independent admission, specialization,
exports and declarations, source provenance, atomic artifact publication, Rust
packaging, WIT comparison and native/npm command identity. Generate readable JS,
TS, Rust, WIT and WAT. Do not add substantial language features, upgrade Lean,
run full self-host suites, publish npm packages, force-push or alter PSC0/main.

Use GitHub and Linux cloud CI only. Fetch HEAD before writes; preserve history.
No local checkout/build/test execution is authorized for this workstream.

## Exact evidence already observed

Baseline `0fd7b9aa8bc2f51b21e0cd9477edde35063de0e4` passed run39322348232 and
integrates the corrected PSKernel-Core source from the separately qualified
`0a53836489c4e88f46df8f5b8b0c19cc41bafbbb` lineage, typed specialization rechecks
and independent official Lean 4.34.0 admission.

Repair commit `ad5d21e88be22230e8b9f869837c692c4ffa5f88`, run39330964018:

- Native compiler/focused executable build: 233 jobs, PASS.
- Corrected PSKernel-Core native build: 163 jobs, PASS; 15 regressions PASS.
- Host formatting/map/transaction tests: 14 PASS.
- Specialization, native source-map, official Lean provider and scoped negative
  tests: PASS.
- Eleven backend integration groups PASS: native/npm identity, rejection of bad
  source, .ps/.lean JS execution, final-layout Unicode maps, imported helper
  visibility across JS/Wasm/Rust, strict TS execution, .d.ts consumer checks,
  captured-source mutation, locked/formatted Rust runtime, core Wasm/WAT runtime,
  and actual Bool component WIT/WAT execution.
- The run then correctly REFUSED UInt8 because the active IR checker reports
  `scalar-capability-unqualified`. Overall run FAILED; it is not a full green.

## Current correction and tests requiring exact-HEAD qualification

The old WIT representation table advertised integer/float capabilities that the
active IR contract explicitly refuses. Do NOT erase that guard to obtain a pass.
WIT selection now checks the same `psIrCheckPrimitive` policy, with active public
component scalar **Bool only**. `profile.json` states this boundary. Ten source
refusal tests and native WIT-policy tests retain the guard. No scalar feature
activation or gate relaxation is part of this repair.

The source-level edge suite additionally tests imported generic specialization,
Core/target name collision handling, empty public modules and deep existing Nat
recursion through the stack-safe JS printer. These tests require their own actual
result; do not assume success from the earlier eleven passing groups.

The exact formatter dependency lock from cloud run39329257133 is committed.
The workflow now requires that lock and uses npm ci, without resolving a missing
lock at qualification time.

## Implemented architecture

- Captured dependency-ordered source bytes and ASTs; canonical path/cycle checks.
- Same immutable prepared Core graph admitted by independent official Lean before
  erasure. Typed IR is checked; specialization input and output are rechecked.
- Entry API and provenance use erasure's exact collision-aware Core-name map.
- JS/TS share a closed revalidated declaration/implementation plan. Rust retains
  its existing checked generic IR; Wasm uses its own checked specialization path.
- Stack-safe JS printing, readable JS/TS with parsed-tree-preserving formatting,
  final-layout multi-file maps with UTF-16 coordinates and corrected negative VLQ.
- Rustfmt output plus usable exact-direct-pin Cargo.toml/Cargo.lock library.
- Structural full bounded WIT API comparison and actual-binary WAT generation.
- Per-target staged immutable generations, content hashes, managed public aliases
  and one atomic current-pointer replacement. Failure preserves prior output.
- Both npm launcher paths invoke the same identity-checked native command model;
  no archived generated PSC0 compiler/kernel fallback. The duplicate stdlib source
  workspace identity is corrected.

## Trust and scope limits

Direct output uses the independent **official Lean 4.34.0 kernel**. Corrected
**PSKernel-Core** source is integrated and regression-tested separately; it is not
claimed to be the current default direct-output provider. Source admission, IR
checking and executable tests do not constitute formal backend-preservation proofs.

Publication is atomic for one target bundle. Multi-file readers should resolve an
immutable generation once. Separate targets with the same `.d.ts` output path need
separate output directories; foreign/ordinary preexisting paths are refused rather
than silently overwritten. Maps are declaration-level. Old immutable generations
are retained; automatic collection is separate work.

Native npm platform distribution, runtime extraction/tree-shaking, incremental
compilation, expression-level maps, formal preservation, optional scalar activation
and full self-host qualification remain separate, unclaimed work.

## Next actions

Read the latest scoped workflow. Resolve genuine compiler/backend failures without
weakening checks or expanding the language. Record exact green SHA/run before
promotion. Keep the source/format examples and JSON test results in cloud artifacts.
The prior historical work state is preserved byte-for-byte in
`docs/history/AI_WORK_STATE_BEFORE_SCOPED_2026-10-20.md`.
