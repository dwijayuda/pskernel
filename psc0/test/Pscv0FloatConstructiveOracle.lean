import Lean
import Ps.Host.FloatConstructive
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
namespace Pscv0FloatCanonicalModel

open Float.Model

def canonicalPacked (spec : Format) (bits : BitVec spec.numBits) :
    BitVec spec.numBits :=
  if UnpackedFloat.unpackExponent (spec := spec) bits = (-1#_) then
    if UnpackedFloat.unpackMantissa (spec := spec) bits = (0#_) then bits
    else UnpackedFloat.packedNaN spec
  else bits

-- No Classical.choice, sorryAx, unchecked proof or opaque validity cast:
-- this is the *actual* pinned Format.Valid predicate, discharged for every
-- possible packed bitvector by cases on the exponent and mantissa.
theorem canonicalPacked_valid (spec : Format) (bits : BitVec spec.numBits) :
    Format.Valid spec (canonicalPacked spec bits) := by
  unfold canonicalPacked
  by_cases he : UnpackedFloat.unpackExponent (spec := spec) bits = (-1#_)
  · simp only [if_pos he]
    by_cases hm : UnpackedFloat.unpackMantissa (spec := spec) bits = (0#_)
    · simp only [if_pos hm]
      exact ⟨fun _ hNonzero => False.elim (hNonzero hm)⟩
    · simp only [if_neg hm]
      exact ⟨fun _ _ => rfl⟩
  · simp only [if_neg he]
    exact ⟨fun h _ => False.elim (he h)⟩

-- Genuine logical Float values constructed with verified Format.Valid
-- evidence. Host-only at this stage: source-level Float.ofBits and the
-- cross-target floating ABI are deliberately NOT activated by these.
def fromBits64 (bits : UInt64) : Float :=
  Float.ofModel {
    toBits := UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec)
    valid := canonicalPacked_valid Format.binary64 bits.toBitVec
  }

def fromBits32 (bits : UInt32) : Float32 :=
  Float32.ofModel {
    toBits := UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec)
    valid := canonicalPacked_valid Format.binary32 bits.toBitVec
  }

end Pscv0FloatCanonicalModel

-- Independent pinned native executable observations. Full all-input
-- equivalence to the upstream Float.ofBits still requires its own theorem;
-- examples alone neither certify that equivalence nor target preservation.
#guard (Pscv0FloatCanonicalModel.fromBits64 18444492273895866368).toBits ==
  (9221120237041090560 : UInt64)
#guard (Pscv0FloatCanonicalModel.fromBits64 9223372036854775808).toBits ==
  (9223372036854775808 : UInt64)
#guard (Pscv0FloatCanonicalModel.fromBits64 1).toBits == (1 : UInt64)
#guard (Pscv0FloatCanonicalModel.fromBits32 4290772992).toBits ==
  (2143289344 : UInt32)
#guard (Pscv0FloatCanonicalModel.fromBits32 2147483648).toBits ==
  (2147483648 : UInt32)
#guard (Pscv0FloatCanonicalModel.fromBits32 1).toBits == (1 : UInt32)

run_cmd do
  for name in [``Pscv0FloatCanonicalModel.canonicalPacked_valid,
      ``Pscv0FloatCanonicalModel.fromBits64,
      ``Pscv0FloatCanonicalModel.fromBits32] do
    let dependencies ← Lean.collectAxioms name
    if dependencies.contains ``Classical.choice then
      throwError "PSCV0-FLOAT-F1: constructive Valid proof imports Classical.choice"
    if dependencies.contains ``sorryAx then
      throwError "PSCV0-FLOAT-F1: constructive Valid proof imports sorryAx"
