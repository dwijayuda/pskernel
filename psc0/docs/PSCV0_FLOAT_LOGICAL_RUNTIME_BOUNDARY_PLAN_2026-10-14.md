# PSCV0 Float/Float32 logical-to-runtime boundary — Lean 4.35.0 study

Status: **research and implementation contract only; not implemented or qualified by this document**. The latest green executable baseline is `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`, [Linux 38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060): profile /61, selected Standard 1516 declarations / 23 classes / 153 instances, 426 shared runtime observations.

## F0 inventory verified against the /61 repository (14 October 2026)

**This section is a checked design/audit checkpoint, not a Float implementation.**
Last full-green executable is `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`,
CI `38515443060`. The current float plan is documentation-only after that
executable, with no new float build or conformance acceptance.

### Existing PSC0 substrate and the missing interface

| Boundary | Code | F0 finding |
| --- | --- | --- |
| Source/Core names | `packages/core/src/Ps/Core/Builtin.lean` | `psFloatName` and `psFloat32Name` are defined as identifiers only |
| Checked selected Standard | `packages/environment/src/Ps/Environment/SelfHostPrelude.lean`, `SelfHostProd.lean`, `StandardUnsigned*.lean` | No registered checked logical Float/Float32 inductive families, constructors, methods or instances; F0 must define/import them before any source-level promise |
| Erasure | `packages/erasure/src/Ps/Erasure/Basic.lean` | The type classifier recognizes Float and Float32 as primitive types, but this does **not** admit unregistered source declarations or establish a logical-to-runtime model |
| Strict typed IR | `packages/compiler-ir/src/Ps/CompilerIr/Model.lean` | `float`/`float32` types, `floatBinary` and `floatCompare` operation categories exist; they are a transport substrate, not proven semantic equivalence |
| Native kernel | `packages/pskernel-lean/provider/PsKernelLean/Prelude.lean`; `host/src/Ps/Host/NativeV7.lean` | A newly selected logical family must be rechecked with Lean 4.35.0 `Kernel.Environment.addDeclCore`. Source programs remain strictly kernel checked with their independent finite budgets |
| Output | JS/TS/Rust and Wasm GC/Canonical ABI modules | No source Float feature can be declared qualified until all typed and ABI paths have exact signed-zero/NaN/f32-rounding evidence |

### Lean 4.35.0's actual declaration/semantic cut

Study, convert and compare at **pinned commit**
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`:

1. `src/Init/Data/Float/Model/Float.lean`: `Float.Model` is a
   subtype-like structure with `toBits : UInt64` and
   `valid : Float.Model.Format.binary64.Valid toBits.toBitVec`.
   `pack/unpack`, `nan`, `inf`, `ofBits`, arithmetic and comparisons
   are defined over the checked unpacked model, NOT over unconstrained UInt64.
2. `src/Init/Data/Float/Float.lean`: logical `structure Float`
   has exactly one field `toModel : Float.Model`; native
   `Float.ofModel`/`toModel` have optimized extern representations.
   `Float.ofBits` delegates to the model's canonicalization,
   `Float.toBits` delegates to model bits, and `Float.beq` uses
   model/IEEE Boolean equality. `Float.toString` is opaque in Core:
   do not fabricate a logical computation proof for its runtime rendering.
3. `src/Init/Data/Float/Model/Float32.lean` and
   `src/Init/Data/Float/Float32.lean`: the separate **binary32** model
   has a `UInt32` bit carrier and binary32 validity. Each arithmetic
   operation and conversion must perform the binary32 model's rounding,
   not binary64 arithmetic with final narrowing.
4. `src/Init/Data/OfScientific/Basic.lean`: the class accepts an exact
   `Nat` mantissa, `Bool` exponent sign and `Nat` decimal exponent.
   `src/Init/Data/OfScientific.lean` implements the checked fast path
   and fallback. Lexing must preserve this triple before elaboration.
5. Differential references:
   `tests/elab/floatEquality.lean`,
   `tests/elab/floatBits.lean`, `tests/elab/floatModelDefeq.lean`
   and `tests/pkg/ofScientific`, all at the same commit.

**Selection policy:** The selected F0 declaration cut must be closed over every
logical dependency (including the exact `Float.Model.Format.*` predicates and
unpacked operations). Preserve original Lean signatures, real proof bodies,
inductive constructor/recursor metadata and declared assumptions.
Use the existing deterministic native exporter and official kernel replay;
a cutoff that turns native definitions into convenient new axioms is forbidden.
Only the already authorized `propext` and `Quot.sound` foundation
assumptions are allowed; separately report the full F0 assumption manifest.

**Transport policy:** Keep logical `Float` separate from runtime
`PsVerifiedIrPrimitiveType.float`. Erasure may map the checked wrapper to a
typed scalar only after proving the selected logical representation and
one-to-one canonical bit transport meet all existing IR checks.
The same rule applies to Float32. Do not add implicit Float↔UInt coercions or
reinterpretation of proof/structure fields.

**First executable F0 gate:** Export only the pinned, closed logical
families and constructor/projection/bit contracts. Audit the exact membership,
assumptions, snapshot FNV/SHA, kernel-generated metadata and all-admission
receipt. Validate negative refusal before enabling any float arithmetic,
literal syntax or emitter path. F1–F4 follow only after the F0 gate is green.

## Pinned upstream implementation (primary reference)

Commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, Lean 4.35.0:

- `src/Init/Data/Float/Float.lean`: `Float` logical wrapper, `ofModel`, `ofBits : UInt64 → Float`, `toBits : Float → UInt64`, `BEq`, conversions, finite/NaN classifications and arithmetic externs.
- `src/Init/Data/Float/Float32.lean`: corresponding binary32 definitions and separate native operations.
- `src/Init/Data/Float/Model/Float.lean`: `Float.Model` carries a canonical bit-pattern plus `Format.binary64.Valid` evidence; `ofBits` canonicalizes NaNs; `beq`, `isNaN`, `isFinite`, `ofScientific` delegate to checked unpacked-float semantics.
- `src/Init/Data/OfScientific.lean` and `src/Init/Data/OfScientific/Basic.lean`: fast exact scientific conversion where possible, fallback through the checked model. Do not round to host float during lexing.
- `tests/elab/floatEquality.lean`, `tests/elab/floatBits.lean`, `tests/elab/floatModelDefeq.lean`, `tests/pkg/ofScientific`: equality, bit patterns, canonical NaN, concrete definitional reduction and decimal-literal conformance.

Adapted upstream text/code must retain upstream MIT/Apache notices as applicable, with the actual checked source attribution recorded in `psc0/THIRD_PARTY_NOTICES.md`.

## Semantic invariants and implementation design

1. **Logical identity:** keep Float and Float32 as separate checked Lean-compatible data with their own explicit logical models. `Float.ofBits` and `Float32.ofBits` must canonicalize every NaN payload according to pinned model rules. Floating bits are *not* unconstrained integers; `toBits` must reflect the canonical model.
2. **Two equalities:** Boolean `BEq` follows IEEE-style comparisons (`NaN == NaN` false; `+0 == -0` true). Propositional equality and decidable equality follow the model's *structural* canonical identity (NaNs equal after canonicalization, signed zero distinct). Never conflate the two in elaboration, kernel checking or runtime.
3. **Runtime representation:** introduce the smallest common IR/runtime representation and typed f32/f64 operations, not backend-specific language semantics. In generic arrays, closures or ADTs retain the correct boxed scalar transport; Wasm GC remains internal. All JS/TS, Rust, Wasm GC and component ABI paths must consume the same checked typed plan.
4. **Conversions:** Float→UInt8/16/32/64 truncates toward zero and clamps, using 0 for negative/NaN. Float32 must perform binary32 rounding *per operation*; a binary64 operation followed by one final cast is not equivalent. Preserve signed zero, infinity and canonical NaN across bit operations and ABI.
5. **Scientific literals:** lex exact decimal mantissa/sign/exponent as integer source data; elaborate `OfScientific` with correct priority/defaulting and confirmed target type, and *only then* lower. Do not use JavaScript `Number` parsing or Rust host parsing as the reference for all inputs.
6. **Trust boundary:** native opaque/extern floating primitives require explicit typed runtime semantics plus differential evidence. Official kernel acceptance proves validity of the logical declarations; it does not by itself prove the JS/Rust/Wasm operation implements the same logical model. No new axioms, sorry, unchecked casts or admission shortcuts.
7. **Resource behavior:** bounds and fixed-width operations must not cause unbounded host expansion. Preserve independent source-kernel heartbeat budgets and the frozen Standard fingerprint check. Avoid introducing huge proof closures into executable IR.

## Coherent implementation slices (do not skip dependency order)

**F0 — Source/Core contract:** inventory all existing Float/Float32/OfScientific support; compare pinned theorem dependencies and identify which exact trusted primitive declarations or native checked definitions enter the selected Standard. Decide each imported item's reducibility, erasure, ABI shape and provenance. Pin a closed, reviewed Standard candidate only after official kernel replay and signature comparison.

**F1 — Bit identity and classification:** implement checked `Float.ofBits/toBits`, `Float32.ofBits/toBits`, NaN normalization, finite/NaN/infinity and signed-zero behavior, with explicit f32/f64 runtime storage and normal typed IR. Test +0/-0, ±infinity, both canonical NaNs and noncanonical payloads (quiet/signalling; both signs), min subnormal, max finite, ±1 and boundary bits.

**F2 — Equality and arithmetic:** implement `BEq` separately from logical equality; add independently typed arithmetic and comparisons, with exact f32 rounding at each operation. Prove any claimed Core identities using ordinary official kernel checking; for opaque runtime operations retain differential evidence, not invented proofs. Test NaN/zero comparison matrices and overflow/underflow/rounding edge cases across all targets.

**F3 — Conversions and scientific literals:** complete float/integer conversions and the `OfScientific` scheduler and checked fallback, including huge exponents, denormals, exact halfway/round-ties-to-even and overflow. Use Lean's `tests/pkg/ofScientific` as the primary negative/positive corpus.

**F4 — Cross-target qualification and performance:** verify the same 32/64-bit observable results in native Lean, JS, strict TS, Rust, V8 Wasm GC, Wasmtime core/component and WIT flat-slot ABI. Include repeated calls and NaN canonicalization after host crossings, strict IR refusal for type/width mismatch, and project/module linkage. Record per-stage compiler timing, heap use and operation runtimes against native Lean. No performance parity claims without actual comparable measurements.

## Architecture choices and non-goals

Do not copy the entire upstream elaborator, proof engine or floating model if the selected subset can share smaller checked representations. **Do preserve** the logical model, canonical bit-level behavior, rounding, equality separation, typed ABI and explicit trusted boundary. No C5, self-hosting or pskernel-core integration in this slice. The prior /61 426-observation suite is the regression baseline and must not shrink.

## Exit criteria

- Positive and negative tests for the selected declared Float/Float32 surface; kernel admits every logical declaration, refusing any source proof violation.
- Exact bits and classifications match pinned native Lean including signed zero, NaN normalization, f32 rounding and scientific inputs.
- Zero unresolved runtime IR types, absent ABI representations, unchecked proof/effect/assumption obligations or invisible widening conversions.
- A complete green Linux workflow at one exact source SHA, frozen registry fingerprints, new cross-target observation count and performance evidence.
- Explicitly document what remains unsupported (e.g. full arbitrary-precision floating proofs or extensive math libraries), rather than claiming total Lean compatibility.
