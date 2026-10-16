# M2+A platform-width result layout

Status: implementation submitted for cloud qualification; M2+A remains OPEN.

## Evidence and root cause

Native run 38821837990, job 116719998782, tested `be634b576572ab2fa4ba43962abec67f1ee6eec5`. Compilation, parser/native checks, all preceding frozen logical asset steps, source qualification and real three-module emission passed. The next step, GC core/component qualification, failed before Wasm execution: `--word-size 32 --emit-all .../platform/words32.ps` reported `PSCV0-ERASURE: unsupported runtime term (in checkGetWidth)`. Later backend/performance steps were skipped.

`PsPlatformRuntime.erase` correctly intended to emit the prepared `Subtype` record instantiated at `Nat`, but obtained its layout through `psErasureSingleRuntimeField`. That helper deliberately requires zero type parameters. The prepared generic `Subtype` retains one type parameter for its value; its predicate and proof do not become physical fields. A monomorphic-layout helper therefore rejects the intended result before typed IR validation.

## Pinned reference study

Official Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:

- `src/Init/Prelude.lean`, `System.Platform.getNumBits`, `numBits` and `numBits_eq`: the opaque function returns `Unit -> Subtype (fun n : Nat => n = 32 or n = 64)`. Its checked 64-bit inhabitant does not determine target execution; opacity deliberately avoids architecture-dependent checking.
- `src/Lean/Compiler/LCNF/ToImpureType.lean`, `impureIrrelevantType`, trivial-structure handling and constructor layout: proof/type-former erasure and physical layout are distinct from the logical dependent type. PSC0 retains its existing prepared generic-record representation rather than adopting Lean's unboxing strategy in this patch.
- Existing PSC0 `Structure.lean`/`Basic.lean` preparation and strict single-field adapter, plus `Platform.lean`'s explicit target resolution and typed record construction.

No upstream source is copied by this correction; existing Apache-2.0 attribution remains intact.

## Correction and invariants

Only the `getBits` caller changes. It looks up the prepared `Subtype` layout and requires exactly one type parameter and one physical field whose type is that parameter. Unboxed or incompatible layouts remain refused. The record uses the actual prepared structure/field names and the explicit `Nat` type argument. Strict IR validation still checks the resulting record.

The monomorphic helper is unchanged, so Fin, BitVec and scalar-model adapters retain their existing checks. The Unit argument is evaluated exactly once. Target width is still selected solely through the explicit request profile; absence of a profile remains an error. No kernel reduction rule, opaque inhabitant, proof, approved assumption, registry digest, budget, backend memory model or ABI changes.

## Qualification

Run the unchanged cloud native workflow. Its existing platform family checks both explicit profiles, width introspection including `checkGetWidth`, word operations/conversions and ABI echoes, absent-profile refusal and refusal of a false width theorem. Continue through shared readable/GC/component/Wasmtime/performance gates. Existing expected results and diagnostic assertions are not rewritten. A source-level explanation and successful compilation alone are not a backend qualification receipt or an M2+A exit.

Exact new commit/run receipts belong in both handoff files after the push and observed cloud results. The development branch and draft PR109 are not modified by this slice.
