# M2+A explicit target-word profiles

Status: complete implementation submitted for qualification; no executable platform-word qualification claim yet.

## Platform registry checkpoint — runtime qualification pending, 16 October 2026

Active request: complete remaining M2+A in native .lean. Stop after M2+A; the established later sequence is M3+B -> M4+C/D -> M5/E. Earlier stop-after-F3 instructions are superseded.

Development remains at 4fedd6cab8236c5f0f0a16dcffe8f7e10402972e (documentation receipt), with F4 executable f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3 qualified by all32 native steps in run38793307283 and independent F1/F2/F3-F4 replays. All978 shared JS/TS/Rust observations, GC Wasm core/components, repeated native Wasmtime calls/post-return and unchanged performance gates passed. This is scoped conformance, not full M2+A or v7 completion.

Platform work is isolated on psc0/pscv0-v7-platform-words-research. Compiler/test source at 7e4066022da4b4045ef75dc474fb074042c02c8c compiled under Lean4.35.0. Native run38798802729 independently refused the old registry at both publication and host boundaries, agreeing on FNV 12360804534911715399, declaration SHA256 ba5b31288f85ace664b421705a345c3c5cf88f8aa0f0afc7d751dbb7b6a168bc; surface candidate c1c6a33f603ba503ade3c7d1bca9a6bd3ac29dffc060ba21980e34afe9363196. This checkpoint selects exactly those observed values; the next run must qualify actual source/kernel/IR/runtime behavior.

The checked platform asset replays byte-for-byte: 196 declarations, 4775 sharednodes, 773868 UTF8bytes, two recursor rules, zero new axioms; SHA256 54fd05f822dd6e30b11a38ee06f16054eb2edbae9e759c82196c2e4229f3a89e. USize's legacy axiom becomes the actual BitVec structure. Existing ISize identity is reused. F3/F4/platform independent replay38797063336 passed at compiler-source-identical 3cf7f41026ea62f4e240a66052a7643b91088859. Source closure:263 portable/277 native modules.

The implementation carries an explicit optional targetWordSize through portable API, erasure scopes, native Request, CLI --word-size32|64 and artifact metadata. Logical getNumBits stays opaque; checking never specializes its inhabitant. Shared lowering resolves platform words to fixed-width IR before validation. 28 checked scalar dictionaries, eight native registrations and two private checked power adapters reuse existing owners. The independent native64/fixed32 oracle passes. Full cross-target qualification is still pending for35 common probes per profile, typed ABI echoes, absent-profile refusals and a false numBits=64 proof refusal. No acceptance criterion or budget changed.


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
