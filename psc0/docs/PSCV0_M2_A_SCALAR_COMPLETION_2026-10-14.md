# M2+A scalar completion design — Lean 4.35.0

Status: design/research only; unsigned conversion /59 is qualified, Hashable /60
is undergoing qualification. Float, signed words and expanded BitVec operations
are not enabled by this document.

All Lean references below use commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

## Dependency order and reuse

1. Retain the checked UInt/BitVec/Fin logical foundation and its typed scalar
   representation boundary. Complete word operations and BitVec numeric
   registrations using converted closed native declarations where compatible.
2. Reuse the same fixed-width operation family for arithmetic, comparison,
   division/modulus and shifts. Zero division and oversize shift behavior must
   match the native methods, rather than target operator accidents.
3. Preserve Float/Float32 logical models, then implement typed floating runtime
   representation, exact bit conversion, classification and scientific literals.
   The lexer and shared synthetic-default scheduler own token decomposition
   and OfScientific defaulting, not individual backends.
4. Complete scalar display dictionaries and selected byte/collection APIs.
   Keep the manifest and C5 occurrence/binder retention with their semantic
   owners. No additional milestone track or self-hosting requirement.

Current Standard arithmetic uses ordinary HAdd/HSub/HMul/HDiv/HMod classes
with explicit out-parameter positions. Add fixed-width instances there via
shared registrations; do not add per-type operator cases in the parser or
elaborator. The existing strict IR already has machine binary/comparison
operations and rejects unqualified scalar families.

## Unsigned and bitvector invariants

[UInt/Basic](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/UInt/Basic.lean)
and [BasicAux](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/UInt/BasicAux.lean)
define unsigned values through actual BitVec structures. Arithmetic wraps.
Unsigned division by zero gives zero; modulus by zero retains the dividend.
UInt shifts reduce the shift operand modulo the width. General
[BitVec operations](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/BitVec/Basic.lean)
accept Nat or bitvector shifts and have their own width semantics; a UInt shift
plan cannot silently stand in for arbitrary-width BitVec shifting.

The native exporter rejects new axioms/unsafe/partial/quotient primitives,
rechecks converted data with the official kernel, and compares regenerated
constructor/recursor signatures. A name collision is not evidence of semantic
compatibility. Keep every exported asset's exact pre-admission declaration
stage and frozen name boundary.

## Floating semantics that must survive lowering

[Float](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Float.lean),
[Float32](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Float32.lean)
and [Float.Model](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Float/Model/Float.lean)
define wrappers around checked bit-pattern models. NaNs normalize to a chosen
canonical NaN. The model carries a validity proof; it is not a free UInt64
substitute or a newly assumed real-number theory.

- Boolean BEq treats positive/negative zero as equal and NaN as unequal to
  itself.
- Propositional/DecidableEq preserves signed zero distinction and equates
  canonical NaNs.
- ofBits/toBits and arithmetic/negation must preserve the canonical observable
  bit rules; backend-native NaN payload/sign behavior is not sufficient.
- Float-to-unsigned conversions truncate and clamp, with zero for negative/NaN.
- Binary32 operations round at each binary32 operation, including conversions.
  Float64 arithmetic followed by one final cast may double-round.

Independent reference tests:
[floatEquality](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatEquality.lean),
[floatBits](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatBits.lean),
[floatModelDefeq](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/floatModelDefeq.lean).
The last demonstrates kernel reduction of concrete arithmetic; opaque placeholder
definitions would lose required behavior.

## Scientific conversion

[OfScientific](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/OfScientific.lean)
has an exactly-representable fast path and a checked model fallback.
Float's default OfScientific priority is 501, above Neg Int's 500.
The fallback bounds huge exponents before computing powers of ten and handles
subnormal rounding. Reuse these semantics and the pinned
`tests/pkg/ofScientific` oracle; avoid parsing into host floating values before
type selection or treating scientific tokens as already-rounded binary64 data.

Wasm floating values remain scalar f32/f64 and GC boxes at generic crossings.
Linear memory is permitted only by the explicit component ABI. Extend the
existing typed Canonical ABI flat-slot plan for floats, including its join and
bit-reinterpretation rules; do not build a second ABI planner.

This research does not establish implementation, runtime parity or full M2+A
completion. Native logical admission, runtime conformance and performance
remain distinct evidence.

## Unsigned operation closure review

The native-only authoring candidate selects all four widths' add/sub/mul,
div/mod, neg/complement, bitwise and/or/xor, and left/right shifts together.
It also selects the actual Nat.div logical definition, replacing the earlier
axiom in the candidate replay base. Native division bound proofs unfold that
model; retaining an axiom at this dependency cut would be invalid reuse.

References additionally studied: `Init/Data/BitVec/BasicAux.lean`,
`Init/Data/Nat/Div/Basic.lean`, `tests/compile/uint_fold.lean` and
`tests/elab/bv_uint.lean` at the pinned commit. Logical export, instance
registration and runtime selection remain separate. The authoring command
cannot modify the compiler's admitted environment. All candidates undergo
fresh trust-zero kernel replay before source transport. No qualification or
public availability of this operation closure is claimed until it is reviewed,
integrated and checked across the existing target matrix.

### Shared integer operation lowering

The existing machine-integer operation family now carries division, remainder
and shifts. Division/remainder guard zero; signed minimum / -1 wraps without
trapping. Shift amounts reduce modulo the value width, including 8/16-bit
values on a 32-bit Wasm stack. Operands evaluate once. Negation and complement
reuse subtraction and xor with width-correct constants.

Direct JS/TS and the legacy TS printer share one ECMAScript numeric expression
plan. Rust uses wrapping operations and explicit zero guards. Wasm uses pure
scalar helpers, with no memory allocation; its word descriptor continues to
supply one mnemonic/opcode/signature to both WAT and binary output. Pinned
`src/include/lean/lean.h` supplies runtime edge-case semantics. Additional
signed helper coverage remains gated by the signed Standard/IR milestone.
Opcodes were verified against the official
[Wasm numeric instruction encoding](https://webassembly.github.io/spec/core/binary/instructions.html).
Source exposure and all-target conformance await logical closure review.

### Required logical recursion dependency

Candidate run38466911457 passed all existing /60 qualification gates, then
refused `Acc` at the authoring policy. The complete unsigned bound-proof
closure uses function-valued recursive fields in this proposition. This is a
missing logical iota mechanism, not a reason to replace the proof with an axiom.

At the pinned Lean commit, `kernel/inductive.cpp` (`is_rec_argument`,
`mk_rec_rules`) abstracts each recursive field's dependent function telescope,
then recurses at its instantiated indices and applied field value.
`Lean/Meta/WHNF.lean:reduceRec` applies the generated rule to parameters,
motives, minors and fields. Relevant upstream tests include
`tests/elab/casesOnAcc.lean` and `indPredRecursion.lean`.

PSC0's single-family iota now constructs that telescope using capture-avoiding
bound-variable lifting. Its existing recursive-field indices suffice; no new
wire schema or stored rule language is needed. The exporter admits reflexive
**propositions** only, still refusing nested/mutual families and computational
reflexive datatypes. Every exported constructor iota rule is now compared
symbolically with the actual pinned native rule after fresh kernel replay.
This does not enable general source well-founded or higher-order recursive
runtime compilation; those remain M3+B with their full acceptance criteria.
