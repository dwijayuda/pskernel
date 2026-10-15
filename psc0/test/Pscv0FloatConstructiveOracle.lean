import Lean
import Ps.Host.FloatConstructive
import Ps.Host.FloatCanonicalContracts
import Lean.Util.CollectAxioms

-- Host-only audited replacement candidate for original pinned
-- BitVec.getLsbD_of_ge. Do not publish it until independent theorem-only
-- portable replay verifies exact type equivalence and source dependencies.
example {w : Nat} (x : BitVec w) (i : Nat) (h : w ≤ i) :
    x.getLsbD i = false :=
  PsV7Native.FloatConstructive.getLsbDOfGe x i h

run_cmd do
  let used ← Lean.collectAxioms
    ``PsV7Native.FloatConstructive.getLsbDOfGe
  for assumption in used do
    unless [``propext, ``Quot.sound].contains assumption do
      throwError "PSCV0-BITVEC-CUT: unapproved axiom {assumption}"

-- The rejected portable Float closure touches these actual pinned Int
-- theorem bodies. Any replacement must have identical upstream types and a
-- strict allowed-assumption closure before independent portable replay.
example (a : Int) : a + 0 = a :=
  PsV7Native.FloatConstructive.intAddZero a
example (a b : Int) : a + -b = a - b :=
  PsV7Native.FloatConstructive.intAddNegEqSub

run_cmd do
  for name in
      [``PsV7Native.FloatConstructive.intAddZero,
       ``PsV7Native.FloatConstructive.intAddNegEqSub] do
    for assumption in ← Lean.collectAxioms name do
      unless [``propext, ``Quot.sound].contains assumption do
        throwError "PSCV0-INT-CUT: unapproved axiom {name}: {assumption}"

/-! Independent native Lean 4.35.0 verification. Not selected Standard. -/
example {a n : Nat} : a ^ n = 0 ↔ a = 0 ∧ n ≠ 0 :=
  PsV7Native.FloatConstructive.powEqZero

run_cmd do
  let used ← Lean.collectAxioms ``PsV7Native.FloatConstructive.powEqZero
  if used.contains ``Classical.choice then
    throwError "PSCV0-FLOAT-F1: constructive proof imports Classical.choice"
  if used.contains ``sorryAx then
    throwError "PSCV0-FLOAT-F1: constructive proof imports sorryAx"

-- Independent executable reference cases from the pinned official Lean
-- tests/elab/floatBits.lean and floatEquality.lean. These exercise *native*
-- bit canonicalization and both equality notions, not PSC0 Float acceptance.
-- A later F1 backend must reproduce these observable results on every target.
#guard (Float.ofBits 18444492273895866368).toBits == (9221120237041090560 : UInt64)
#guard (Float32.ofBits 4290772992).toBits == (2143289344 : UInt32)
#guard (Float.ofBits 9223372036854775808).toBits == (9223372036854775808 : UInt64)
#guard (Float32.ofBits 2147483648).toBits == (2147483648 : UInt32)
#guard (Float.ofBits 1).toBits == (1 : UInt64)
#guard (Float32.ofBits 1).toBits == (1 : UInt32)
#guard (Float.ofBits 0) == (Float.ofBits 9223372036854775808)
#guard !((Float.ofBits 9221120237041090560) == (Float.ofBits 9221120237041090560))
#guard decide ((Float.ofBits 0) ≠ (Float.ofBits 9223372036854775808))
#guard decide ((Float.ofBits 9221120237041090560) = (Float.ofBits 18444492273895866368))

-- Native independent Lean 4.35.0 classification oracle, matching the
-- exact bit-level masks selected for the source UInt32/UInt64 helpers.
-- Here the upstream Float operations are the *reference*, not PSC0's
-- unimplemented checked Float constructors or runtime intrinsics.
#guard (Float.ofBits 9218868437227405312).isInf
#guard !(Float.ofBits 9218868437227405312).isFinite
#guard !(Float.ofBits 9221120237041090560).isInf
#guard (Float.ofBits 0).isFinite
#guard (Float.ofBits 9223372036854775808).isFinite
#guard (Float.ofBits 1).isFinite
#guard (Float32.ofBits 2139095040).isInf
#guard !(Float32.ofBits 2143289344).isInf
#guard !(Float32.ofBits 2143289344).isFinite
#guard (Float32.ofBits 2147483648).isFinite
#guard (Float32.ofBits 1).isFinite

-- Pinned Lean 4.35.0 tests/elab/floatEquality.lean: IEEE BEq and
-- propositional equality disagree specifically for signed zero and NaN.
#guard (Float32.ofBits 0) == (Float32.ofBits 2147483648)
#guard !((Float32.ofBits 2143289344) == (Float32.ofBits 4290772992))
#guard decide ((Float32.ofBits 0) ≠ (Float32.ofBits 2147483648))
#guard decide ((Float32.ofBits 2143289344) = (Float32.ofBits 4290772992))

-- Native, kernel-checked constructive replacement for the very small
-- Format.Valid proof boundary, *not* an export of the whole Float.ofBits
-- dependency graph. The proof works at any valid Float.Model.Format width.

-- Independent pinned native executable observations. Full all-input
-- equivalence to the upstream Float.ofBits still requires its own theorem;
-- examples alone neither certify that equivalence nor target preservation.
#guard (PsV7Native.FloatCanonical.fromBits64 18444492273895866368).toBits ==
  (9221120237041090560 : UInt64)
#guard (PsV7Native.FloatCanonical.fromBits64 9223372036854775808).toBits ==
  (9223372036854775808 : UInt64)
#guard (PsV7Native.FloatCanonical.fromBits64 1).toBits == (1 : UInt64)
#guard (PsV7Native.FloatCanonical.fromBits32 4290772992).toBits ==
  (2143289344 : UInt32)
#guard (PsV7Native.FloatCanonical.fromBits32 2147483648).toBits ==
  (2147483648 : UInt32)
#guard (PsV7Native.FloatCanonical.fromBits32 1).toBits == (1 : UInt32)

run_cmd do
  -- Audit exactly the same roots that the independent exporter replays.
  -- Reject every unapproved axiom, not just two familiar forbidden names.
  for name in PsV7Native.FloatCanonical.contractRoots do
    let dependencies ← Lean.collectAxioms name
    for assumption in dependencies do
      unless [``propext, ``Quot.sound].contains assumption do
        throwError "PSCV0-FLOAT-F1: {name} imports unapproved axiom {assumption}"

-- Exact mask-model constructive proof audit. Portable export roots are
-- unchanged until the independent kernel can replay every dependency.
run_cmd do
  for name in
      [``PsV7Native.FloatCanonical.andAllOnes8_constructive,
       ``PsV7Native.FloatCanonical.andAllOnes11_constructive,
       ``PsV7Native.FloatCanonical.andAllOnes23_constructive,
       ``PsV7Native.FloatCanonical.andAllOnes52_constructive,
       ``PsV7Native.FloatCanonical.maskedHigh_iff,
       ``PsV7Native.FloatCanonical.maskedLow_iff,
       ``PsV7Native.FloatCanonical.binary64ExponentMask_iff,
       ``PsV7Native.FloatCanonical.binary64FractionMask_iff,
       ``PsV7Native.FloatCanonical.binary32ExponentMask_iff,
       ``PsV7Native.FloatCanonical.binary32FractionMask_iff,
       ``PsV7Native.FloatCanonical.canonicalMask64_eq_compact,
       ``PsV7Native.FloatCanonical.canonicalMask32_eq_compact] do
    for assumption in ← Lean.collectAxioms name do
      unless [``propext, ``Quot.sound].contains assumption do
        throwError "PSCV0-FLOAT-MASK-CONSTRUCTIVE: {name} imports unapproved axiom {assumption}"

-- Native-only F1 exact UInt helper correspondence. The original checked
-- source helpers are defined by UInt.and/UInt.toNat/Nat.beq/Bool.rec and
-- remain separately qualified by the cross-target runtime tests.
-- These are source-reference theorems, not portable admission proofs:
-- bit-blasting transitively imports Classical.choice under pinned Lean.
-- Explicitly log this boundary; refuse any incomplete (sorryAx) proof.
run_cmd do
  for name in
      [``PsV7Native.FloatCanonical.binary64ExponentMask_iff,
       ``PsV7Native.FloatCanonical.binary64FractionMask_iff,
       ``PsV7Native.FloatCanonical.binary32ExponentMask_iff,
       ``PsV7Native.FloatCanonical.binary32FractionMask_iff,
       ``PsV7Native.FloatCanonical.canonicalMask64_eq_compact,
       ``PsV7Native.FloatCanonical.canonicalMask32_eq_compact,
       ``PsV7Native.FloatCanonical.canonicalUIntMask64_eq_logical,
       ``PsV7Native.FloatCanonical.canonicalUIntMask32_eq_logical,
       ``PsV7Native.FloatCanonical.canonicalUIntMask64_eq_upstream_toBits,
       ``PsV7Native.FloatCanonical.canonicalUIntMask32_eq_upstream_toBits] do
    let dependencies ← Lean.collectAxioms name
    if dependencies.contains ``sorryAx then
      throwError "PSCV0-FLOAT-MASK-NATIVE: {name} depends on sorryAx"
    for assumption in dependencies do
      Lean.logInfo m!"PSCV0-FLOAT-MASK-NATIVE {name}: {assumption}"

-- Full upstream pack/unpack brings its own transitive axioms in native Lean,
-- including Classical.choice. Never export these research-only comparisons to
-- PSC0's admitted Standard, and never enlarge contractRoots to silence the gate.
-- Keep the strict compact-roots audit above unchanged. The following diagnostic
-- makes the native reference's actual assumptions visible in CI.
run_cmd do
  for name in
      [``Float.ofBits, ``Float32.ofBits,
       ``Float.Model.ofBits, ``Float32.Model.ofBits,
       ``PsV7Native.FloatCanonical.upstreamPackUnpack_nan,
       ``PsV7Native.FloatCanonical.fromBits64_eq_upstream_ofBits_nan,
       ``PsV7Native.FloatCanonical.fromBits32_eq_upstream_ofBits_nan,
       ``PsV7Native.FloatCanonical.upstreamPackUnpack_all64,
       ``PsV7Native.FloatCanonical.upstreamPackUnpack_all32,
       ``PsV7Native.FloatCanonical.fromBits64_eq_upstream_ofBits_all,
       ``PsV7Native.FloatCanonical.fromBits32_eq_upstream_ofBits_all] do
    let dependencies ← Lean.collectAxioms name
    for assumption in dependencies do
      Lean.logInfo m!"PSCV0-FLOAT-UPSTREAM-RESEARCH {name}: {assumption}"
