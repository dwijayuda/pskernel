# M2+A scalar completion design — Lean 4.35.0

Status: unsigned conversion /59 and Hashable /60 are qualified. Shared word
lowering and logical foundation support are under qualification; the complete
unsigned operation slice is blocked on explicit foundation approval. Float, signed words and expanded BitVec operations
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

## Required Lean logical foundation (reviewed dependency, qualification pending)

The complete 48-operation unsigned candidate at Linux 38469424406 contains
794 declarations beyond the old boundary. Its only imported axioms are
Lean's `propext` and `Quot.sound`; quotient primitives support the checked
`funext` theorem in native arithmetic proof dependencies. A fully populated
quotient family adds the previously unused `Quot.ind` metadata. The canonical
language inventory already requires Lean's quotient foundation with restricted
source use. This dependency is implemented here; general runtime quotient
support and source proof automation are not implied.

Studied pinned `src/kernel/quot.cpp`, `Lean/Declaration.lean`,
`Lean/Meta/WHNF.lean:reduceQuotRec`, `Init/Prelude.lean:Quot.sound/funext`,
`Init/Core.lean:propext`, `tests/elab/quotInd.lean` and the security regression
`tests/elab_fail/kernelQuotNameCollision.lean`. The latter requires collision
rejection before kernel insertion; a quotient is not an ordinary axiom or
inductive. The upstream quotInd example uses admit, so it is a semantic source
reference, not accepted validation evidence.

Portable Core now distinguishes four kernel quotient descriptor kinds. The
official provider submits Lean's generative `quotDecl`, then checks every
regenerated signature and kind. No unchecked insertion or overwrite is used.
WHNF reduces registered lift/ind applications on registered quotient
constructors, retaining trailing arguments. Arbitrary familiar names do not
activate reduction. The checked-admission wire format refuses these descriptors
instead of silently pretending that another provider supports them.

A proposed per-slice assumption allowlist would permit exactly pinned
`propext` and `Quot.sound`, with their original signatures. **Publishing this
trust expansion was rejected by automatic approval review; explicit user
approval is pending.** No assumption has been added to the active environment.
The exporter still refuses all new axioms. CI verifies refusal of the full
unsigned candidate and continues the existing /60 integration suite. The
candidate is not qualified or admitted. If approved, these imported Lean
foundation assumptions must appear in the strict snapshot and manifest. No arbitrary/source axiom,
`Classical.choice`, sorry, unsafe definition or proof replacement is allowed.
Previous “no new axioms” receipts describe their historical snapshots; they
must not be used to conceal this intentional trust-boundary expansion.

### Concrete pending assumption change

If authorized, the native export specification would allow exactly
`[`propext, `Quot.sound]` for this slice and no other axioms. Native signatures:

```lean
axiom propext {a b : Prop} : (a ↔ b) → a = b
axiom Quot.sound : ∀ {α : Sort u} {r : α → α → Prop} {a b : α},
  r a b → Eq (Quot.mk r a) (Quot.mk r b)
```

The signatures come from pinned Init/Core.lean and Init/Prelude.lean. The
exported proof bodies would remain unchanged; all converted declarations
would undergo fresh official kernel replay. The snapshot and final assumption
manifest would distinguish these two foundations from ordinary definitions
and from the four generative quotient primitives. Arbitrary axiom import,
source axioms and runtime quotient emission remain refused. Approval covers
this explicit logical assumption delta; it does not certify compiler soundness
or native/backend semantic equivalence.

### Approval received

On 14 October 2026 the user explicitly approved: “Approve these two pinned
Lean assumptions.” The unsigned candidate now has exactly this per-slice
allowlist. Earlier blocked/pending statements above record the review history;
there is no remaining approval blocker for this delta. Candidate export,
public admission and full qualification remain separate subsequent steps.
