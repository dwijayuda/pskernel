import Lean
import Ps.Host.FloatCanonical

/-!
Representation contracts for the existing compact Float/Float32 model.
Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

These are original proof candidates, not a new implementation of Float.
The relevant pinned definitions are Float/Float32.ofModel and toBits, the
proof-bearing Model structures, and Format.Valid. The original compact
constructors, validity proof and normalization policy are left unchanged.

This module does not claim equality with upstream Float.ofBits on arbitrary
raw inputs, publish any selected Standard declaration, or enable runtime
Float. Its root roster is authoring metadata and is not itself exported.
-/

namespace PsV7Native.FloatCanonical

open Float.Model

-- Exact characterization of the representation invariant, at any format.
theorem canonicalPacked_fixed_iff_valid (spec : Format)
    (bits : BitVec spec.numBits) :
    canonicalPacked spec bits = bits ↔ Format.Valid spec bits := by
  constructor
  · intro h
    exact h ▸ canonicalPacked_valid spec bits
  · exact canonicalPacked_of_valid spec bits

-- The compact constructors' observable bits, for every raw input.
theorem toBits_fromBits64 (bits : UInt64) :
    (fromBits64 bits).toBits =
      UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) := rfl

theorem toBits_fromBits32 (bits : UInt32) :
    (fromBits32 bits).toBits =
      UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) := rfl

-- Logical identity, NOT IEEE BEq. Eliminate only the actual native
-- wrappers; the erased Valid fields are propositions, not runtime data.
theorem eq_of_toBits_eq64 {a b : Float}
    (h : a.toBits = b.toBits) : a = b := by
  cases a with
  | ofModel a =>
    cases b with
    | ofModel b =>
      cases a with
      | mk aBits aValid =>
        cases b with
        | mk bBits bValid =>
          change aBits = bBits at h
          cases h
          rfl

theorem eq_of_toBits_eq32 {a b : Float32}
    (h : a.toBits = b.toBits) : a = b := by
  cases a with
  | ofModel a =>
    cases b with
    | ofModel b =>
      cases a with
      | mk aBits aValid =>
        cases b with
        | mk bBits bValid =>
          change aBits = bBits at h
          cases h
          rfl

-- Native upstream bridge, limited to ALL NaN payloads (not a finite sample).
-- This uses upstream UnpackedFloat.pack/unpack, not a replacement Float model.
-- Keep it OUT of the portable contractRoots until the independent full-upstream
-- dependency closure is compatible with the selected PSC0 environment.
theorem upstreamPackUnpack_nan (spec : Format)
    (bits : BitVec spec.numBits)
    (he : UnpackedFloat.unpackExponent bits = (-1#_))
    (hm : UnpackedFloat.unpackMantissa bits ≠ (0#_)) :
    UnpackedFloat.pack spec (UnpackedFloat.unpack spec bits) =
      canonicalPacked spec bits := by
  simp [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked, he, hm]

theorem fromBits64_eq_upstream_ofBits_nan (bits : UInt64)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary64) bits.toBitVec = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits.toBitVec ≠ (0#_)) :
    fromBits64 bits = Float.ofBits bits := by
  apply eq_of_toBits_eq64
  change UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) =
    UInt64.ofBitVec
      (UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits.toBitVec))
  exact congrArg UInt64.ofBitVec
    ((upstreamPackUnpack_nan Format.binary64 bits.toBitVec he hm).symm)

theorem fromBits32_eq_upstream_ofBits_nan (bits : UInt32)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary32) bits.toBitVec = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits.toBitVec ≠ (0#_)) :
    fromBits32 bits = Float32.ofBits bits := by
  apply eq_of_toBits_eq32
  change UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) =
    UInt32.ofBitVec
      (UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits.toBitVec))
  exact congrArg UInt32.ofBitVec
    ((upstreamPackUnpack_nan Format.binary32 bits.toBitVec he hm).symm)

-- A left inverse on ALL existing native logical Float values. This is a
-- representation contract for future erasure/ABI work, not an executable
-- backend preservation theorem or a raw upstream-ofBits equivalence.
theorem fromBits64_toBits (value : Float) :
    fromBits64 value.toBits = value :=
  eq_of_toBits_eq64
    (congrArg UInt64.ofBitVec
      (canonicalPacked_of_valid Format.binary64 value.toBits.toBitVec
        value.toModel.valid))

theorem fromBits32_toBits (value : Float32) :
    fromBits32 value.toBits = value :=
  eq_of_toBits_eq32
    (congrArg UInt32.ofBitVec
      (canonicalPacked_of_valid Format.binary32 value.toBits.toBitVec
        value.toModel.valid))

-- Equality compares CANONICAL bits: never assert that distinct raw NaN
-- payloads remain distinct, or identify signed zeros using IEEE BEq.
theorem fromBits64_eq_iff (a b : UInt64) :
    fromBits64 a = fromBits64 b ↔
      canonicalPacked Format.binary64 a.toBitVec =
        canonicalPacked Format.binary64 b.toBitVec := by
  constructor
  · intro h
    exact congrArg (fun value : Float => value.toBits.toBitVec) h
  · intro h
    exact eq_of_toBits_eq64 (congrArg UInt64.ofBitVec h)

theorem fromBits32_eq_iff (a b : UInt32) :
    fromBits32 a = fromBits32 b ↔
      canonicalPacked Format.binary32 a.toBitVec =
        canonicalPacked Format.binary32 b.toBitVec := by
  constructor
  · intro h
    exact congrArg (fun value : Float32 => value.toBits.toBitVec) h
  · intro h
    exact eq_of_toBits_eq32 (congrArg UInt32.ofBitVec h)

-- One explicit roster for native assumption auditing and independent
-- portable replay. Metadata is host-only; every listed term must still
-- pass the unmodified exporter's type, dependency and assumption checks.
def contractRoots : List Lean.Name :=
  [``fromBits64, ``fromBits32,
   ``canonicalPacked_valid, ``canonicalPacked_of_valid,
   ``canonicalPacked_idempotent, ``canonicalPacked_fixed_iff_valid,
   ``toBits_fromBits64, ``toBits_fromBits32,
   ``eq_of_toBits_eq64, ``eq_of_toBits_eq32,
   ``fromBits64_toBits, ``fromBits32_toBits,
   ``fromBits64_eq_iff, ``fromBits32_eq_iff]

end PsV7Native.FloatCanonical
