# M2+A explicit target-word profiles

Status: dependency research; no platform-word executable capability is selected or qualified.

Lean pin: 4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc. This continues the existing M2+A scalar completion, not a new roadmap milestone.

## Reference and invariant

Study: Init/Prelude.lean (System.Platform.getNumBits/numBits/numBits_eq and USize); Init/Data/UInt/Basic{,Aux}.lean; Init/Data/SInt/Basic.lean and Float{,32}.lean; Lean/Compiler/LCNF/ToImpureType.lean and Simp/ConstantFold.lean. Tests: tests/elab/compiler_fold_usize.lean, no_simproc_usize.lean and sint_conversions.lean.

Lean's getNumBits is opaque, with a checked 64-bit inhabitant. That inhabitant is not a theorem that execution uses 64 bits. The returned subtype guarantees only 32 or 64. Lean constant-folds USize operations only when the 32-bit and 64-bit interpretations agree. Signed words use the corresponding unsigned two's-complement carrier; shifts reduce the shift count modulo width and signed division truncates toward zero.

PSC0 already has strict machine-word types, fixed-width operations and optional width/range helpers in CompilerIr.Model. It currently refuses executable USize/ISize because it has no selected target width. Rust host usize and Wasm address width must not determine source semantics.

## Chosen design

Keep a single checking environment with the original abstract-width declarations and opaque native inhabitants. Author a dependency-closed native asset against the frozen pre-platform F4 stage, with independent official-kernel replay and the unchanged approved assumptions propext/Quot.sound. Do not register proof-closure instances implicitly.

An explicit optional bits32/bits64 configuration belongs to the compilation request and erasure context. Resolve target-sized source scalars to existing fixed-width IR types before strict IR validation; all backends and ABI plans then use the same resolved widths. Logical elaboration/kernel reduction must not specialize to the selected execution profile. Absence of a profile must continue refusing executable platform-dependent values, including platform width introspection.

Reuse the existing unsigned/signed conversion, arithmetic, comparison and Float mechanisms. Preserve lexical context with record updates when adding the erasure configuration; do not hide target policy in name indexes or duplicate per-backend width selection. Enable platform-specific runtime dictionaries only when a profile is present. Record the selected profile in emitted artifact/result metadata. Keep Wasm GC internals and linear memory only at existing explicit ABI boundaries; 64-bit source words do not imply Wasm memory64.

## Qualification

Review the complete native dependency closure before selection; no axiom substitution, unrestricted reduction of getNumBits, or increased resource ceilings. Validate one compact family for each explicit profile through all existing runtime backends. Compare 64-bit execution with pinned native USize/ISize; compare 32-bit execution with the pinned fixed-width/BitVec model. Include width-sensitive overflow/sign/shift/conversion vectors, generic/partial dictionaries, actual API width and metadata, absent-profile refusal, and a negative source proof that attempts to derive numBits = 64 by reflexivity. This is conformance evidence, not a general compiler-preservation theorem.

Upstream code and converted Core retain Apache-2.0 attribution in generated assets and THIRD_PARTY_NOTICES.md.

## Adjacent remaining M2+A work

The source audit confirms List.filter already exists, while Array.filter is absent. Pinned Array.filter is a sliced left fold with order-preserving push. String.toUTF8 is the checked byte-array projection and fromUTF8? validates UTF-8 before constructing a String; inspect their complete representation before adding runtime support. The selected P0 API manifest must name concrete APIs, with actual notation/handler/effect/import/assumption provenance. Re-audit current M2 scoped synthetic scheduling, generalized answer sharing, higher-rank runtime dictionary boundaries and measured search growth; dated RC4 handoffs are not current completion evidence. Dependent/indexed/recursive deriving retains its existing M3+B dependency.
