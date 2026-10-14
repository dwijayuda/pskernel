# M2+A Float F1 constructive dependency closure — research candidate

## 15 October — F2 bit equalities green; constructive Format.Valid candidate

The checked Float32/Float64 *bit-level* two-equality models passed all
[27 Linux CI 38647823991](https://github.com/dwijayuda/pskernel/actions/runs/38647823991)
steps at `ecdff92f3b59981f78aaadbf2c6022178d8ce8d3`.
IEEE Bool equality (NaN unequal, signed zeros equal) is kept distinct
from canonical logical bit identity (all NaN payloads normalized,
signed zeros distinct). Sixteen native-reference/cross-target observations
passed, without declaring source Float instances or additional axioms.

**Research-only next candidate:** direct constructive Lean 4.35.0 proof
for `Format.Valid spec (canonicalPacked spec bits)` for *all*
bitvectors in any permitted Float.Model.Format. The definition branches
on the original pinned `unpackExponent`/`unpackMantissa`, preserving
non-NaN bits and mapping NaNs to `packedNaN spec`. This avoids the
previous 1,038-declaration original Float.ofBits import and its
independently refused List/Int proof-model mismatch. The native oracle
also constructs actual Float and Float32 values with proof-bearing
model fields and checks a handful of reference bit patterns.

This does **not** publish Float.ofBits into the selected Standard, prove
all-input equivalence to the full original upstream ofBits, or qualify
JS/TS/Rust/Wasm floating runtime/ABI behavior. Strict transitive
assumption auditing forbids Classical.choice/sorryAx; kernel/erasure and
all native CI still apply. No pskernel-core, self-hosting or C5.

## 15 October — Float32/64 bit classification fully qualified; two equalities candidate

Commit `5bb8c9c9f3c731263d910cfed8eda394b1d75ac6` passed all
[27 Linux CI 38646612366](https://github.com/dwijayuda/pskernel/actions/runs/38646612366)
steps, qualifying four additional `isInf*` and `isFinite*` checked
UInt32/UInt64 bit helper declarations and sixteen shared target observations
against pinned native Lean 4.35.0 reference behavior. The earlier
`canonical*` and `isNaN*` helpers are unchanged, and full Float F1,
arithmetic and scientific syntax remain unimplemented.

**Next candidate only:** two distinct Bool-valued bit models per width:
`beqFloat32/64Bits` reflects upstream IEEE BEq (NaN never equal,
positive/negative zero equal, other canonical bit encodings compared);
`logicalEqFloat32/64Bits` models *canonical structural bit identity*
(NaN payloads normalize, signed zero distinct). Both use checked existing
UInt, Nat.beq and Bool.rec definitions with one shared recursion helper.
They **do not** supply an Eq proof or selected BEq/DecidableEq Float
instance and must pass separate native reference, kernel/erasure,
JS/TS/Rust/Wasm GC/Wasmtime and performance checks. The strict Standard
FNV/SHA changes must first be measured independently, never guessed.
Full M2+A remains open; no pskernel-core, self-hosting, or C5.

## 15 October — checked F1 bit canonicalization fully qualified; finite/inf candidate

Commit `832764c6ec47b34e330e25441c258c4f4cbcfe05` passed all 27
[Linux CI 38644795298](https://github.com/dwijayuda/pskernel/actions/runs/38644795298)
gates, including independent native official Lean 4.35.0 bit reference cases,
strict FNV/SHA review, kernel admissions, JS/TypeScript/Rust/Wasm GC/Wasmtime
and resource qualification. The four selected `PsStandard.isNaN*` and
`canonical*` UInt32/UInt64 bit definitions are executable and checked; no
`Float.ofBits` or floating arithmetic is published.

**New pending candidate:** extend the same generic native checked bit helper
family with four `isInf*` and `isFinite*` definitions. Their exact IEEE
predicates come from pinned Lean 4.35.0 `Float.Model.UnpackedFloat.unpack`:
all exponent bits set with a zero fraction is ±infinity; any exponent other
than all ones is finite (including signed zero/subnormals). The selected
`Float.Model.isFinite`/`isInf` delegates to this unpacked model. A
small independent pinned native oracle and 16 cross-target observations cover
±infinity, both NaNs, positive/negative zero and subnormals.

No Float constructors, proof fabrication, unchecked runtime cast, platform
word-size assumption, pskernel-core, self-hosting or C5 are involved.
**Do not qualify** until CI independently measures the new strict FNV/SHA
and the entire runtime/Wasmtime/performance gate passes. Full F1–F4 and
remaining M2+A are still open.

## 15 October — native checked Float32/64 bit canonicalization candidate

The upstream F1 export at
[research CI 38643459231](https://github.com/dwijayuda/pskernel/actions/runs/38643459231)
reached 1,038 original Lean declarations but *correctly refused* their
portable replay: the current selected List.get universe signature and
multiple Int addition/ordering theorem bodies differ from the upstream
kernel dependencies. This is a real architecture/semantic boundary, not
an opportunity to weaken checking or mark the full F1 import complete.

**New coherent F1 bit-layer candidate:** native
`StandardFloatCanonical.lean` contains four ordinary checked UInt32/64
helper definitions, shared by the entire runtime prelude. IEEE exponent
and mantissa masks normalize any NaN sign/payload to the positive quiet
NaN while preserving all non-NaN bits (including signed zero/infinity).
Their exact observable cases are checked against independent pinned
Lean 4.35.0 Float/Float32 native oracles and twelve common-source
JS/TS/Rust/Wasm observations. Neither a Float constructor, unchecked
Validity witness nor an executable float arithmetic operation is added.
The new Standard fingerprints require an independent CI observation,
then a full green native/backends/Wasmtime/performance run. Candidate only.

## 15 October — full Float proof-cut root collision corrected (candidate)

[Linux research 38642547802](https://github.com/dwijayuda/pskernel/actions/runs/38642547802)
independently replayed the unchanged two-declaration constructive theorem
successfully, then refused the larger F1 experiment because `Float.toBits`
is already in the selected checked Standard boundary. This refusal is
correct: a selected declaration must not be silently duplicated.

The native F1 authoring candidate now explicitly requires the selected
`Float.toBits` and `Float32.toBits` declarations to exist at the frozen
boundary and exports only the missing `ofBits/isNaN/isFinite` roots plus
the constructive theorem proof. Original `Nat.pow_eq_zero` is still cut
only as a theorem, all other dependencies remain checked, and the
allowed assumption list stays `propext`/`Quot.sound`. No executable
Float was enabled; the new full-F1 experiment remains **unqualified**.

## 15 October — pinned executable reference cases (native only)

The official Lean 4.35.0 sources `tests/elab/floatBits.lean` and
`tests/elab/floatEquality.lean` explicitly define the required
canonical quiet-NaN outputs, retention of signed-zero bit patterns,
Boolean equality treating signed zeros equal and NaNs unequal,
and propositional identity distinguishing signed zero while
identifying canonical NaNs.

The `Pscv0FloatConstructiveOracle.lean` native oracle now includes
ten focused tests on the pinned Lean implementation, including both
Float64 and Float32. The new checks are **independent native reference
evidence**, not newly accepted PSC0 executable semantics. Each target
must be qualified separately before the M2+A Float exit criteria
can be marked complete.

## Scope and authoritative sources

Lean 4.35.0 pinned to `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Primary code: `src/Init/Data/Nat/Lemmas.lean` for the upstream theorem
`Nat.pow_eq_zero : a ^ n = 0 ↔ a = 0 ∧ n ≠ 0`;
`src/Init/Data/Float/Model/Unpacked/Pack/Basic.lean` and
`src/Init/Data/Float/Model/{Float,Float32}.lean` for bit unpack/repack,
NaN canonicalization and the proof-carrying packed model;
`src/Lean/Util/CollectAxioms.lean` for transitive proof assumptions.

The earlier F1 exporter run
[38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033)
found the exact path `Float.ofBits → Float.Model.ofBits →
UnpackedFloat.unpack → Nat.shiftLeft_pos_iff →
Nat.shiftLeft_eq_zero_iff → Nat.pow_eq_zero → private proof →
Classical.choice`. It correctly refused admission; nothing is
authorized to extend the approved `propext`/`Quot.sound` allowlist.

## Constructive alternative

The isolated `Pscv0FloatConstructiveOracle.lean` proves the same
proposition using only natural zero/successor discrimination and
`Nat.pow_pos`. The official Lean kernel type-checks the statement,
and `Lean.collectAxioms` fails compilation if the alternate theorem
still reaches `Classical.choice` or `sorryAx`. This is a research-only
checked witness, not a replacement theorem in the frozen Standard.

## 15 October — checked constructive theorem and opt-in proof-cut research

The standalone Lean 4.35.0 theorem/axiom audit passed
[CI 38636902147](https://github.com/dwijayuda/pskernel/actions/runs/38636902147).
The next authoring-only proof cut validates definitional equality against
the original `Nat.pow_eq_zero` type with the official native kernel,
retains a strict theorem-only whitelist, then independently replays
the proof in the portable kernel. No trust expansion or Float runtime
admission. Independent research CI is separate from the main native gate.

## 15 October — full F1 transitive proof-cut experiment

The original theorem-only cut passed all native type, imported-assumption,
and portable kernel replay gates at
[CI 38641629995](https://github.com/dwijayuda/pskernel/actions/runs/38641629995),
with exactly two new checked declarations and no imported
`Classical.choice`.

The full F1 research exporter now adds the original Float/Float32
`ofBits`, `toBits`, `isNaN` and `isFinite` roots alongside the
constructive theorem source. The *original* `Nat.pow_eq_zero` name is
a checked theorem-only dependency cut: the exporter never imports its
historical nonconstructive proof body into this candidate. It instead
replays a fresh theorem of exactly the same proposition at the same name.
Every other dependency remains subject to the ordinary official kernel
and strict assumption guard. No claim of executable Float follows from
this research and further unsupported dependencies must fail closed.

## Required next gates before F1 authorization

1. Qualify this proof/axiom audit in the full unchanged native CI matrix.
2. If successful, review a generic, transparent theorem-only replacement
   mechanism in the *authoring exporter*. It must accept only a theorem
   with an exact native-kernel-checked type, record the original identity,
   and check every transitive dependency against the existing allowlist.
   It must not substitute a definition, data constructor or kernel axiom.
3. Re-export the complete Float/Float32 F1 closure against the frozen F0
   environment and independent official-kernel proof replay; investigate
   any further unapproved assumptions rather than ignoring them.
4. Separately implement typed Float/Float32 IR, canonical NaN and signed
   zero, binary32 rounding, JS/TS/Rust/Wasm/Wasmtime and ABI semantics,
   plus scientific literal conversion and final manifest correspondence.

The standalone theorem does not establish backend semantic preservation,
full Float support, M2+A completion, or trust expansion.
