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

-- Constructive classification of canonical bit representation. Unlike the
-- upstream pack/unpack functions, these roots retain the compact admitted
-- dependency closure and may be independently replayed in PSC0.
theorem canonicalPacked_nan (spec : Format) (bits : BitVec spec.numBits)
    (he : UnpackedFloat.unpackExponent (spec := spec) bits = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := spec) bits ≠ (0#_)) :
    canonicalPacked spec bits = UnpackedFloat.packedNaN spec := by
  simp [canonicalPacked, he, hm]

theorem canonicalPacked_infinityBits (spec : Format) (bits : BitVec spec.numBits)
    (he : UnpackedFloat.unpackExponent (spec := spec) bits = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := spec) bits = (0#_)) :
    canonicalPacked spec bits = bits := by
  simp [canonicalPacked, he, hm]

theorem canonicalPacked_finiteExponent (spec : Format) (bits : BitVec spec.numBits)
    (he : UnpackedFloat.unpackExponent (spec := spec) bits ≠ (-1#_)) :
    canonicalPacked spec bits = bits := by
  simp [canonicalPacked, he]

-- Exact sign-bit roundtrip. Restrict bit-blasting to a one-bit value;
-- whole-word bit-blasting is needlessly expensive for field reassembly.
theorem signBitRoundTrip (sign : BitVec 1) :
    (UnpackedFloat.Sign.ofBitVec sign).toBitVec = sign := by
  simp [UnpackedFloat.Sign.ofBitVec, UnpackedFloat.Sign.toBitVec] <;> bv_decide

-- Reassemble each pinned IEEE word using upstream BitVec extraction and
-- concatenation lemmas, without a 64/32-bit SAT computation.
theorem reconstructPackedFields64 (bits : BitVec 64) :
    UnpackedFloat.packComponents Format.binary64
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary64) bits))
      (UnpackedFloat.unpackExponent (spec := Format.binary64) bits)
      (UnpackedFloat.unpackMantissa (spec := Format.binary64) bits) = bits := by
  change
    ((UnpackedFloat.Sign.ofBitVec (bits.extractLsb' 63 1)).toBitVec ++
      bits.extractLsb' 52 11) ++ bits.extractLsb' 0 52 = bits
  rw [signBitRoundTrip]
  have hi : bits.extractLsb' 63 1 ++ bits.extractLsb' 52 11 =
      bits.extractLsb' 52 12 := by
    simpa using (BitVec.extractLsb'_append_extractLsb'_eq_extractLsb'
      (x := bits) (start₂ := 63) (start₁ := 52) (len₂ := 1) (len₁ := 11)
      (by decide))
  rw [hi]
  simpa using (BitVec.extractLsb'_append_extractLsb'
    (x := bits) (w := 12) (len := 52))

theorem reconstructPackedFields32 (bits : BitVec 32) :
    UnpackedFloat.packComponents Format.binary32
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary32) bits))
      (UnpackedFloat.unpackExponent (spec := Format.binary32) bits)
      (UnpackedFloat.unpackMantissa (spec := Format.binary32) bits) = bits := by
  change
    ((UnpackedFloat.Sign.ofBitVec (bits.extractLsb' 31 1)).toBitVec ++
      bits.extractLsb' 23 8) ++ bits.extractLsb' 0 23 = bits
  rw [signBitRoundTrip]
  have hi : bits.extractLsb' 31 1 ++ bits.extractLsb' 23 8 =
      bits.extractLsb' 23 9 := by
    simpa using (BitVec.extractLsb'_append_extractLsb'_eq_extractLsb'
      (x := bits) (start₂ := 31) (start₁ := 23) (len₂ := 1) (len₁ := 8)
      (by decide))
  rw [hi]
  simpa using (BitVec.extractLsb'_append_extractLsb'
    (x := bits) (w := 9) (len := 23))


-- Upstream representation reconstruction for every infinity and signed-zero
-- encoding at this width; both sign bits are covered symbolically.
theorem upstreamPackUnpack_infinity64 (bits : BitVec 64)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  have hrec := reconstructPackedFields64 bits
  have hInf : UnpackedFloat.packedInfinity Format.binary64
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary64) bits)) = bits := by
    simpa [UnpackedFloat.packedInfinity, he, hm] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked, he, hm] using hInf

theorem upstreamPackUnpack_zero64 (bits : BitVec 64)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (0#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  have hrec := reconstructPackedFields64 bits
  have hZero : UnpackedFloat.packedZero Format.binary64
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary64) bits)) = bits := by
    simpa [UnpackedFloat.packedZero, he, hm] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked, he, hm] using hZero

-- Upstream representation reconstruction for every infinity and signed-zero
-- encoding at this width; both sign bits are covered symbolically.
theorem upstreamPackUnpack_infinity32 (bits : BitVec 32)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (-1#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  have hrec := reconstructPackedFields32 bits
  have hInf : UnpackedFloat.packedInfinity Format.binary32
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary32) bits)) = bits := by
    simpa [UnpackedFloat.packedInfinity, he, hm] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked, he, hm] using hInf

theorem upstreamPackUnpack_zero32 (bits : BitVec 32)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (0#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  have hrec := reconstructPackedFields32 bits
  have hZero : UnpackedFloat.packedZero Format.binary32
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary32) bits)) = bits := by
    simpa [UnpackedFloat.packedZero, he, hm] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked, he, hm] using hZero


-- Raw subnormal reconstruction: a nonzero mantissa with a zero exponent
-- retains every mantissa and sign bit through upstream unpack/repack.
theorem upstreamPackUnpack_subnormal64 (bits : BitVec 64)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (0#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits ≠ (0#_)) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  let mantissa := UnpackedFloat.unpackMantissa (spec := Format.binary64) bits
  have hpos : mantissa.toNat ≠ 0 := by
    intro h
    apply hm
    apply (BitVec.toNat_inj).mp
    simpa [mantissa] using h
  have hlog : mantissa.toNat.log2 < 52 :=
    (Nat.log2_lt hpos).2 mantissa.isLt
  have hsmall : mantissa.toNat.log2 + 1 ≠ 53 := by omega
  have hrec := reconstructPackedFields64 bits
  have hsub : UnpackedFloat.packComponents Format.binary64
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary64) bits))
      (0#_) mantissa = bits := by
    simpa [mantissa, he] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked,
    Format.binary64, Format.exponentBias, Format.mantissaBits,
    he, hm, mantissa, hsmall] using hsub

-- Raw subnormal reconstruction: a nonzero mantissa with a zero exponent
-- retains every mantissa and sign bit through upstream unpack/repack.
theorem upstreamPackUnpack_subnormal32 (bits : BitVec 32)
    (he : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (0#_))
    (hm : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits ≠ (0#_)) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  let mantissa := UnpackedFloat.unpackMantissa (spec := Format.binary32) bits
  have hpos : mantissa.toNat ≠ 0 := by
    intro h
    apply hm
    apply (BitVec.toNat_inj).mp
    simpa [mantissa] using h
  have hlog : mantissa.toNat.log2 < 23 :=
    (Nat.log2_lt hpos).2 mantissa.isLt
  have hsmall : mantissa.toNat.log2 + 1 ≠ 24 := by omega
  have hrec := reconstructPackedFields32 bits
  have hsub : UnpackedFloat.packComponents Format.binary32
      (UnpackedFloat.Sign.ofBitVec
        (UnpackedFloat.unpackSign (spec := Format.binary32) bits))
      (0#_) mantissa = bits := by
    simpa [mantissa, he] using hrec
  simpa [UnpackedFloat.unpack, UnpackedFloat.pack, canonicalPacked,
    Format.binary32, Format.exponentBias, Format.mantissaBits,
    he, hm, mantissa, hsmall] using hsub


-- Raw normal reconstruction: the implicit leading one fixes log2 of the
-- unpacked significand, and excluding the all-ones exponent prevents overflow.
theorem upstreamPackUnpack_normal64 (bits : BitVec 64)
    (heZero : UnpackedFloat.unpackExponent (spec := Format.binary64) bits ≠ (0#_))
    (heTop : UnpackedFloat.unpackExponent (spec := Format.binary64) bits ≠ (-1#_)) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  let mantissa := UnpackedFloat.unpackMantissa (spec := Format.binary64) bits
  let exponent := UnpackedFloat.unpackExponent (spec := Format.binary64) bits
  let joined : BitVec 53 := (1#1) ++ mantissa
  have hMantBound : mantissa.toNat < 2 ^ 52 := by
    simpa [Format.binary64] using mantissa.isLt
  have hjoin : joined.toNat = 2 ^ 52 + mantissa.toNat := by
    change ((1#1) ++ mantissa).toNat = 2 ^ 52 + mantissa.toNat
    rw [BitVec.toNat_append]
    rw [← Nat.shiftLeft_add_eq_or_of_lt hMantBound]
    simp [Nat.shiftLeft_eq, Format.binary64]
  have hlow : 2 ^ 52 ≤ joined.toNat := by omega
  have hhigh : joined.toNat < 2 ^ (52 + 1) := by
    have hdouble : 2 ^ (52 + 1) = 2 ^ 52 + 2 ^ 52 := by
      simp [Nat.pow_succ]
    rw [hdouble]
    omega
  have hpositive : joined.toNat ≠ 0 := by
    have hpow : 0 < 2 ^ 52 := by decide
    omega
  have hlog : joined.toNat.log2 = 52 :=
    (Nat.log2_eq_iff hpositive).2 ⟨hlow, hhigh⟩
  have hmask : BitVec.ofNat 52 joined.toNat = mantissa := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, hjoin, Nat.add_mod,
      Nat.mod_eq_of_lt hMantBound]
  have hnotMax : exponent.toNat ≠ 2047 := by
    intro h
    have ht : exponent = (-1#11) := by
      apply (BitVec.toNat_inj).mp
      simpa using h
    exact heTop (by simpa [exponent] using ht)
  have hnoOverflow : ¬ (2 ^ 11 ≤ exponent.toNat + 1) := by
    have hExpBound : exponent.toNat < 2 ^ 11 := by
      simpa [Format.binary64] using exponent.isLt
    have hPow : (2 : Nat) ^ 11 = 2048 := by decide
    omega
  have hBiased :
      (((exponent.toNat : Int) - (((Format.binary64.exponentBias : Nat) : Int) +
          (52 : Int)) + ((Format.binary64.exponentBias : Nat) : Int) + (52 : Int)).toNat) =
        exponent.toNat := by omega
  have hMantBits : 52 + 1 = Format.binary64.mantissaBits := by decide
  have hnoOverflow' : ¬ (2047 ≤ exponent.toNat) := by
    have hExpBound : exponent.toNat < 2 ^ 11 := by
      simpa [Format.binary64] using exponent.isLt
    have hPow : (2 : Nat) ^ 11 = 2048 := by decide
    omega
  have hWidth : BitVec.setWidth 52
      ((1#1) ++ UnpackedFloat.unpackMantissa (spec := Format.binary64) bits) =
        UnpackedFloat.unpackMantissa (spec := Format.binary64) bits := by
    change BitVec.ofNat 52
      ((1#1 ++ UnpackedFloat.unpackMantissa (spec := Format.binary64) bits).toNat) =
        UnpackedFloat.unpackMantissa (spec := Format.binary64) bits
    exact hmask
  have hrec := reconstructPackedFields64 bits
  rw [canonicalPacked_finiteExponent Format.binary64 bits heTop]
  dsimp [joined, exponent, mantissa] at hBiased hlog hmask hnoOverflow hnoOverflow'
  simp only [UnpackedFloat.unpack, if_neg heTop, if_neg heZero]
  simp only [UnpackedFloat.pack]
  rw [hBiased]
  simp only [hnoOverflow, ite_false, hlog, hMantBits, ite_true,
    hWidth, BitVec.ofNat_toNat]
  exact hrec

-- Raw normal reconstruction: the implicit leading one fixes log2 of the
-- unpacked significand, and excluding the all-ones exponent prevents overflow.
theorem upstreamPackUnpack_normal32 (bits : BitVec 32)
    (heZero : UnpackedFloat.unpackExponent (spec := Format.binary32) bits ≠ (0#_))
    (heTop : UnpackedFloat.unpackExponent (spec := Format.binary32) bits ≠ (-1#_)) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  let mantissa := UnpackedFloat.unpackMantissa (spec := Format.binary32) bits
  let exponent := UnpackedFloat.unpackExponent (spec := Format.binary32) bits
  let joined : BitVec 24 := (1#1) ++ mantissa
  have hMantBound : mantissa.toNat < 2 ^ 23 := by
    simpa [Format.binary32] using mantissa.isLt
  have hjoin : joined.toNat = 2 ^ 23 + mantissa.toNat := by
    change ((1#1) ++ mantissa).toNat = 2 ^ 23 + mantissa.toNat
    rw [BitVec.toNat_append]
    rw [← Nat.shiftLeft_add_eq_or_of_lt hMantBound]
    simp [Nat.shiftLeft_eq, Format.binary32]
  have hlow : 2 ^ 23 ≤ joined.toNat := by omega
  have hhigh : joined.toNat < 2 ^ (23 + 1) := by
    have hdouble : 2 ^ (23 + 1) = 2 ^ 23 + 2 ^ 23 := by
      simp [Nat.pow_succ]
    rw [hdouble]
    omega
  have hpositive : joined.toNat ≠ 0 := by
    have hpow : 0 < 2 ^ 23 := by decide
    omega
  have hlog : joined.toNat.log2 = 23 :=
    (Nat.log2_eq_iff hpositive).2 ⟨hlow, hhigh⟩
  have hmask : BitVec.ofNat 23 joined.toNat = mantissa := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, hjoin, Nat.add_mod,
      Nat.mod_eq_of_lt hMantBound]
  have hnotMax : exponent.toNat ≠ 255 := by
    intro h
    have ht : exponent = (-1#8) := by
      apply (BitVec.toNat_inj).mp
      simpa using h
    exact heTop (by simpa [exponent] using ht)
  have hnoOverflow : ¬ (2 ^ 8 ≤ exponent.toNat + 1) := by
    have hExpBound : exponent.toNat < 2 ^ 8 := by
      simpa [Format.binary32] using exponent.isLt
    have hPow : (2 : Nat) ^ 8 = 256 := by decide
    omega
  have hBiased :
      (((exponent.toNat : Int) - (((Format.binary32.exponentBias : Nat) : Int) +
          (23 : Int)) + ((Format.binary32.exponentBias : Nat) : Int) + (23 : Int)).toNat) =
        exponent.toNat := by omega
  have hMantBits : 23 + 1 = Format.binary32.mantissaBits := by decide
  have hnoOverflow' : ¬ (255 ≤ exponent.toNat) := by
    have hExpBound : exponent.toNat < 2 ^ 8 := by
      simpa [Format.binary32] using exponent.isLt
    have hPow : (2 : Nat) ^ 8 = 256 := by decide
    omega
  have hWidth : BitVec.setWidth 23
      ((1#1) ++ UnpackedFloat.unpackMantissa (spec := Format.binary32) bits) =
        UnpackedFloat.unpackMantissa (spec := Format.binary32) bits := by
    change BitVec.ofNat 23
      ((1#1 ++ UnpackedFloat.unpackMantissa (spec := Format.binary32) bits).toNat) =
        UnpackedFloat.unpackMantissa (spec := Format.binary32) bits
    exact hmask
  have hrec := reconstructPackedFields32 bits
  rw [canonicalPacked_finiteExponent Format.binary32 bits heTop]
  dsimp [joined, exponent, mantissa] at hBiased hlog hmask hnoOverflow hnoOverflow'
  simp only [UnpackedFloat.unpack, if_neg heTop, if_neg heZero]
  simp only [UnpackedFloat.pack]
  rw [hBiased]
  simp only [hnoOverflow, ite_false, hlog, hMantBits, ite_true,
    hWidth, BitVec.ofNat_toNat]
  exact hrec

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
   ``canonicalPacked_nan, ``canonicalPacked_infinityBits,
   ``canonicalPacked_finiteExponent,
   ``toBits_fromBits64, ``toBits_fromBits32,
   ``eq_of_toBits_eq64, ``eq_of_toBits_eq32,
   ``fromBits64_toBits, ``fromBits32_toBits,
   ``fromBits64_eq_iff, ``fromBits32_eq_iff]

end PsV7Native.FloatCanonical
