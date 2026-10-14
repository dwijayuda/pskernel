# M2+A Float F1 constructive dependency closure — research candidate

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
