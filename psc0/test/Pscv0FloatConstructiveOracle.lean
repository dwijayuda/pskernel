import Lean
import Ps.Host.FloatConstructive
import Ps.Host.FloatCanonicalContracts
import Lean.Util.CollectAxioms

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
