import Init.Data.Float.Float
import Init.Data.Float.Float32

/-!
Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Proof-carrying canonical Float/Float32 native logical model. All input
validity and idempotence are kernel-checked; no new axiom or runtime Float.
-/

namespace PsV7Native.FloatCanonical

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

-- Format.Valid states NaN canonicalization. Hence normalization fixes
-- every valid bit pattern and is idempotent on every possible input.
theorem canonicalPacked_of_valid (spec : Format) (bits : BitVec spec.numBits)
    (h : Format.Valid spec bits) : canonicalPacked spec bits = bits := by
  unfold canonicalPacked
  by_cases he : UnpackedFloat.unpackExponent (spec := spec) bits = (-1#_)
  · simp only [if_pos he]
    by_cases hm : UnpackedFloat.unpackMantissa (spec := spec) bits = (0#_)
    · simp only [if_pos hm]
    · simp only [if_neg hm]
      exact (h.eq_packedNaN he hm).symm
  · simp only [if_neg he]

theorem canonicalPacked_idempotent (spec : Format)
    (bits : BitVec spec.numBits) :
    canonicalPacked spec (canonicalPacked spec bits) = canonicalPacked spec bits :=
  canonicalPacked_of_valid spec (canonicalPacked spec bits)
    (canonicalPacked_valid spec bits)

-- Genuine logical Float values constructed with verified Format.Valid
-- evidence. The selected portable asset replays these logical constructors.
-- Executable Float erasure, typed IR and the cross-target ABI remain gated.
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

end PsV7Native.FloatCanonical
