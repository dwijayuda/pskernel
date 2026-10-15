import Lean
import Ps.Host.FloatCanonical

/-!
Representation contracts for the existing compact Float/Float32 model.
Pinned Lean 4.35.0: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

These are original proof candidates, not a new implementation of Float.
The relevant pinned definitions are Float/Float32.ofModel and toBits, the
proof-bearing Model structures, and Format.Valid. The original compact
constructors, validity proof and normalization policy are left unchanged.

This module has native-only proofs that its canonical constructor equals
upstream Float.ofBits / Float32.ofBits for EVERY raw bit pattern. Those
upstream-dependent theorems transitively import Classical.choice and are
NOT in portable contractRoots. Only the independent compact constructive
model is replayed against the strict selected assumptions propext and
Quot.sound; neither source Float constructors nor runtime Float are enabled.
The explicit root roster is authoring metadata, not automatic publication.
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

-- Pinned upstream normal representation proof (native research only).
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
  have hExpBound : exponent.toNat < 2 ^ 11 := by
    simpa [Format.binary64] using exponent.isLt
  have hJoin : joined.toNat = 2 ^ 52 + mantissa.toNat := by
    change ((1#1) ++ mantissa).toNat = 2 ^ 52 + mantissa.toNat
    rw [BitVec.toNat_append]
    rw [← Nat.shiftLeft_add_eq_or_of_lt hMantBound]
    simp [Nat.shiftLeft_eq, Format.binary64]
  have hLow : 2 ^ 52 ≤ joined.toNat := by omega
  have hHigh : joined.toNat < 2 ^ (52 + 1) := by
    have hd : 2 ^ (52 + 1) = 2 ^ 52 + 2 ^ 52 := by
      simp [Nat.pow_succ]
    rw [hd]
    omega
  have hPositive : joined.toNat ≠ 0 := by
    have hp : 0 < 2 ^ 52 := by decide
    omega
  have hLog : joined.toNat.log2 = 52 :=
    (Nat.log2_eq_iff hPositive).2 ⟨hLow, hHigh⟩
  have hMask : BitVec.ofNat 52 joined.toNat = mantissa := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, hJoin, Nat.mod_eq_of_lt hMantBound]
  have hExp : BitVec.ofNat 11 exponent.toNat = exponent := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, Nat.mod_eq_of_lt hExpBound]
  have hNotMax : exponent.toNat ≠ 2047 := by
    intro h
    have ht : exponent = (-1#11) := by
      apply (BitVec.toNat_inj).mp
      simpa using h
    exact heTop (by simpa [exponent] using ht)
  have hNoOverflow : ¬ (2 ^ 11 ≤ exponent.toNat + 1) := by
    have hp : (2 : Nat) ^ 11 = 2048 := by decide
    omega
  have hBias :
      (((exponent.toNat : Int) - (1023 + 52) + 1023 + 52).toNat) =
        exponent.toNat := by omega
  have hUnpack : UnpackedFloat.unpack Format.binary64 bits =
      .finite
        (UnpackedFloat.Sign.ofBitVec
          (UnpackedFloat.unpackSign (spec := Format.binary64) bits))
        joined.toNat
        ((exponent.toNat : Int) - (1023 + 52))
        (Nat.pos_of_ne_zero hPositive) := by
    simp only [UnpackedFloat.unpack, if_neg heTop, if_neg heZero]
    rfl
  have hRawBias :
      (((exponent.toNat : Int) - (1023 + 52) +
        (Format.binary64.exponentBias : Nat) + ((52 : Nat) : Int)).toNat) =
        exponent.toNat := by
    exact hBias
  have hRawNoOverflow :
      ¬ (2 ^ 11 ≤ (((exponent.toNat : Int) - (1023 + 52) +
        (Format.binary64.exponentBias : Nat) + ((52 : Nat) : Int)).toNat) + 1) := by
    rw [hRawBias]
    exact hNoOverflow
  have hRawExponent : BitVec.ofNat 11
      (((exponent.toNat : Int) - (1023 + 52) +
        (Format.binary64.exponentBias : Nat) + ((52 : Nat) : Int)).toNat) = exponent := by
    rw [hRawBias]
    exact hExp
  have hIsNormal : joined.toNat.log2 + 1 = Format.binary64.mantissaBits := by
    simp [hLog, Format.binary64, Format.mantissaBits]
  have hRec := reconstructPackedFields64 bits
  rw [canonicalPacked_finiteExponent Format.binary64 bits heTop]
  rw [hUnpack]
  unfold UnpackedFloat.pack
  dsimp only
  rw [if_neg hRawNoOverflow]
  rw [if_pos hIsNormal]
  rw [hRawExponent, hMask]
  exact hRec

-- Pinned upstream normal representation proof (native research only).
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
  have hExpBound : exponent.toNat < 2 ^ 8 := by
    simpa [Format.binary32] using exponent.isLt
  have hJoin : joined.toNat = 2 ^ 23 + mantissa.toNat := by
    change ((1#1) ++ mantissa).toNat = 2 ^ 23 + mantissa.toNat
    rw [BitVec.toNat_append]
    rw [← Nat.shiftLeft_add_eq_or_of_lt hMantBound]
    simp [Nat.shiftLeft_eq, Format.binary32]
  have hLow : 2 ^ 23 ≤ joined.toNat := by omega
  have hHigh : joined.toNat < 2 ^ (23 + 1) := by
    have hd : 2 ^ (23 + 1) = 2 ^ 23 + 2 ^ 23 := by
      simp [Nat.pow_succ]
    rw [hd]
    omega
  have hPositive : joined.toNat ≠ 0 := by
    have hp : 0 < 2 ^ 23 := by decide
    omega
  have hLog : joined.toNat.log2 = 23 :=
    (Nat.log2_eq_iff hPositive).2 ⟨hLow, hHigh⟩
  have hMask : BitVec.ofNat 23 joined.toNat = mantissa := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, hJoin, Nat.mod_eq_of_lt hMantBound]
  have hExp : BitVec.ofNat 8 exponent.toNat = exponent := by
    apply (BitVec.toNat_inj).mp
    simp [BitVec.toNat_ofNat, Nat.mod_eq_of_lt hExpBound]
  have hNotMax : exponent.toNat ≠ 255 := by
    intro h
    have ht : exponent = (-1#8) := by
      apply (BitVec.toNat_inj).mp
      simpa using h
    exact heTop (by simpa [exponent] using ht)
  have hNoOverflow : ¬ (2 ^ 8 ≤ exponent.toNat + 1) := by
    have hp : (2 : Nat) ^ 8 = 256 := by decide
    omega
  have hBias :
      (((exponent.toNat : Int) - (127 + 23) + 127 + 23).toNat) =
        exponent.toNat := by omega
  have hUnpack : UnpackedFloat.unpack Format.binary32 bits =
      .finite
        (UnpackedFloat.Sign.ofBitVec
          (UnpackedFloat.unpackSign (spec := Format.binary32) bits))
        joined.toNat
        ((exponent.toNat : Int) - (127 + 23))
        (Nat.pos_of_ne_zero hPositive) := by
    simp only [UnpackedFloat.unpack, if_neg heTop, if_neg heZero]
    rfl
  have hRawBias :
      (((exponent.toNat : Int) - (127 + 23) +
        (Format.binary32.exponentBias : Nat) + ((23 : Nat) : Int)).toNat) =
        exponent.toNat := by
    exact hBias
  have hRawNoOverflow :
      ¬ (2 ^ 8 ≤ (((exponent.toNat : Int) - (127 + 23) +
        (Format.binary32.exponentBias : Nat) + ((23 : Nat) : Int)).toNat) + 1) := by
    rw [hRawBias]
    exact hNoOverflow
  have hRawExponent : BitVec.ofNat 8
      (((exponent.toNat : Int) - (127 + 23) +
        (Format.binary32.exponentBias : Nat) + ((23 : Nat) : Int)).toNat) = exponent := by
    rw [hRawBias]
    exact hExp
  have hIsNormal : joined.toNat.log2 + 1 = Format.binary32.mantissaBits := by
    simp [hLog, Format.binary32, Format.mantissaBits]
  have hRec := reconstructPackedFields32 bits
  rw [canonicalPacked_finiteExponent Format.binary32 bits heTop]
  rw [hUnpack]
  unfold UnpackedFloat.pack
  dsimp only
  rw [if_neg hRawNoOverflow]
  rw [if_pos hIsNormal]
  rw [hRawExponent, hMask]
  exact hRec

-- F1 mask/field bridge: these are the exact masks used by the checked
-- PsStandard.canonicalFloat32/64Bits UInt helpers. Prove each condition
-- symbolically for EVERY bit pattern; spot observations are not sufficient.
-- This is native proof research until source Float erasure and each target
-- representation are independently qualified.
-- The pinned generic BitVec.and_allOnes lemma imports Classical.choice
-- transitively despite expressing a constructive bit identity. Use the
-- lower-level natural bitwise identity instead; keep the trust audit strict.
-- Fixed IEEE field width 8: constructive finite bit-index check.
-- This never imports the pinned generic choice-bearing allOnes bit theorem.
theorem andAllOnes8_constructive (x : BitVec 8) :
    x &&& BitVec.allOnes 8 = x := by
  apply BitVec.eq_of_getLsbD_eq
  intro i hi
  have bit : (BitVec.allOnes 8).getLsbD i = true := by
    change Nat.testBit (2 ^ 8 - 1) i = true
    have hAll : ∀ j : Fin 8, Nat.testBit (2 ^ 8 - 1) j.val = true := by decide
    exact hAll ⟨i, hi⟩
  simpa only [BitVec.getLsbD_and, bit, Bool.and_true]

-- Fixed IEEE field width 11: constructive finite bit-index check.
-- This never imports the pinned generic choice-bearing allOnes bit theorem.
theorem andAllOnes11_constructive (x : BitVec 11) :
    x &&& BitVec.allOnes 11 = x := by
  apply BitVec.eq_of_getLsbD_eq
  intro i hi
  have bit : (BitVec.allOnes 11).getLsbD i = true := by
    change Nat.testBit (2 ^ 11 - 1) i = true
    have hAll : ∀ j : Fin 11, Nat.testBit (2 ^ 11 - 1) j.val = true := by decide
    exact hAll ⟨i, hi⟩
  simpa only [BitVec.getLsbD_and, bit, Bool.and_true]

-- Fixed IEEE field width 23: constructive finite bit-index check.
-- This never imports the pinned generic choice-bearing allOnes bit theorem.
theorem andAllOnes23_constructive (x : BitVec 23) :
    x &&& BitVec.allOnes 23 = x := by
  apply BitVec.eq_of_getLsbD_eq
  intro i hi
  have bit : (BitVec.allOnes 23).getLsbD i = true := by
    change Nat.testBit (2 ^ 23 - 1) i = true
    have hAll : ∀ j : Fin 23, Nat.testBit (2 ^ 23 - 1) j.val = true := by decide
    exact hAll ⟨i, hi⟩
  simpa only [BitVec.getLsbD_and, bit, Bool.and_true]

-- Fixed IEEE field width 52: constructive finite bit-index check.
-- This never imports the pinned generic choice-bearing allOnes bit theorem.
theorem andAllOnes52_constructive (x : BitVec 52) :
    x &&& BitVec.allOnes 52 = x := by
  apply BitVec.eq_of_getLsbD_eq
  intro i hi
  have bit : (BitVec.allOnes 52).getLsbD i = true := by
    change Nat.testBit (2 ^ 52 - 1) i = true
    have hAll : ∀ j : Fin 52, Nat.testBit (2 ^ 52 - 1) j.val = true := by decide
    exact hAll ⟨i, hi⟩
  simpa only [BitVec.getLsbD_and, bit, Bool.and_true]

-- Constructive BitVec field-mask lemmas adapted from the pinned upstream
-- String/Decode.lean splitting method. No tactic-based SAT oracle or
-- unchecked theorem is needed; the kernel checks ordinary equality rewrites.
theorem maskedHigh_iff {upper lower : Nat}
    (bits : BitVec (upper + lower)) (mask target : BitVec upper) :
    bits &&& (mask ++ 0#lower) = target ++ 0#lower ↔
      bits.extractLsb' lower upper &&& mask = target := by
  have split : bits = bits.extractLsb' lower upper ++ bits.extractLsb' 0 lower := by
    rw [BitVec.extractLsb'_append_extractLsb']
  conv => lhs; rw [split]
  rw [BitVec.and_append, BitVec.and_zero, BitVec.append_left_inj]

theorem maskedLow_iff {upper lower : Nat}
    (bits : BitVec (upper + lower)) (mask target : BitVec lower) :
    bits &&& (0#upper ++ mask) = 0#upper ++ target ↔
      bits.extractLsb' 0 lower &&& mask = target := by
  have split : bits = bits.extractLsb' lower upper ++ bits.extractLsb' 0 lower := by
    rw [BitVec.extractLsb'_append_extractLsb']
  conv => lhs; rw [split]
  rw [BitVec.and_append, BitVec.and_zero, BitVec.append_right_inj]

theorem binary64ExponentMask_iff (bits : BitVec 64) :
    (bits &&& 9218868437227405312#64 = 9218868437227405312#64) ↔
      UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (-1#11) := by
  change
    (bits &&& ((0#1 ++ BitVec.allOnes 11) ++ 0#52) =
      ((0#1 ++ BitVec.allOnes 11) ++ 0#52)) ↔
        bits.extractLsb' 52 11 = BitVec.allOnes 11
  rw [maskedHigh_iff (upper := 12) (lower := 52)
    (bits := bits) (mask := (0#1 ++ BitVec.allOnes 11))
    (target := (0#1 ++ BitVec.allOnes 11))]
  have split : bits.extractLsb' 52 12 =
      bits.extractLsb' 63 1 ++ bits.extractLsb' 52 11 := by
    simpa using (BitVec.extractLsb'_append_extractLsb'_eq_extractLsb'
      (x := bits) (start₂ := 63) (start₁ := 52)
      (len₂ := 1) (len₁ := 11) (by decide)).symm
  rw [split, BitVec.and_append, BitVec.and_zero,
      andAllOnes11_constructive, BitVec.append_right_inj]

theorem binary64FractionMask_iff (bits : BitVec 64) :
    (bits &&& 4503599627370495#64 = 0#64) ↔
      UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#52) := by
  change (bits &&& (0#12 ++ BitVec.allOnes 52) = 0#12 ++ 0#52) ↔
    bits.extractLsb' 0 52 = 0#52
  simpa only [andAllOnes52_constructive] using (maskedLow_iff (upper := 12) (lower := 52)
    (bits := bits) (mask := BitVec.allOnes 52) (target := 0#52))

theorem binary32ExponentMask_iff (bits : BitVec 32) :
    (bits &&& 2139095040#32 = 2139095040#32) ↔
      UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (-1#8) := by
  change
    (bits &&& ((0#1 ++ BitVec.allOnes 8) ++ 0#23) =
      ((0#1 ++ BitVec.allOnes 8) ++ 0#23)) ↔
        bits.extractLsb' 23 8 = BitVec.allOnes 8
  rw [maskedHigh_iff (upper := 9) (lower := 23)
    (bits := bits) (mask := (0#1 ++ BitVec.allOnes 8))
    (target := (0#1 ++ BitVec.allOnes 8))]
  have split : bits.extractLsb' 23 9 =
      bits.extractLsb' 31 1 ++ bits.extractLsb' 23 8 := by
    simpa using (BitVec.extractLsb'_append_extractLsb'_eq_extractLsb'
      (x := bits) (start₂ := 31) (start₁ := 23)
      (len₂ := 1) (len₁ := 8) (by decide)).symm
  rw [split, BitVec.and_append, BitVec.and_zero,
      andAllOnes8_constructive, BitVec.append_right_inj]

theorem binary32FractionMask_iff (bits : BitVec 32) :
    (bits &&& 8388607#32 = 0#32) ↔
      UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#23) := by
  change (bits &&& (0#9 ++ BitVec.allOnes 23) = 0#9 ++ 0#23) ↔
    bits.extractLsb' 0 23 = 0#23
  simpa only [andAllOnes23_constructive] using (maskedLow_iff (upper := 9) (lower := 23)
    (bits := bits) (mask := BitVec.allOnes 23) (target := 0#23))

-- Exactly the mask/branch behavior of the selected
-- PsStandard.canonicalFloat64Bits function, expressed on its bit carrier.
-- Native reference model only; runtime IR and source Float remain gated.
def canonicalMask64 (bits : BitVec 64) : BitVec 64 :=
  if bits &&& 9218868437227405312#64 = 9218868437227405312#64 then
    if bits &&& 4503599627370495#64 = 0#64 then bits else 9221120237041090560#64
  else bits

theorem packedNaN64_eq_constant :
    UnpackedFloat.packedNaN Format.binary64 = 9221120237041090560#64 := by
  decide

theorem canonicalMask64_eq_compact (bits : BitVec 64) :
    canonicalMask64 bits = canonicalPacked Format.binary64 bits := by
  unfold canonicalMask64 canonicalPacked
  by_cases he : bits &&& 9218868437227405312#64 = 9218868437227405312#64
  · have he' : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (-1#11) :=
      (binary64ExponentMask_iff bits).mp he
    simp only [if_pos he, if_pos he']
    by_cases hm : bits &&& 4503599627370495#64 = 0#64
    · have hm' : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#52) :=
        (binary64FractionMask_iff bits).mp hm
      simp only [if_pos hm, if_pos hm']
    · have hm' : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits ≠ (0#52) :=
        mt (binary64FractionMask_iff bits).mpr hm
      simp only [if_neg hm, if_neg hm']
      exact packedNaN64_eq_constant.symm
  · have he' : UnpackedFloat.unpackExponent (spec := Format.binary64) bits ≠ (-1#11) :=
      mt (binary64ExponentMask_iff bits).mpr he
    simp only [if_neg he, if_neg he']

-- Exactly the mask/branch behavior of the selected
-- PsStandard.canonicalFloat32Bits function, expressed on its bit carrier.
-- Native reference model only; runtime IR and source Float remain gated.
def canonicalMask32 (bits : BitVec 32) : BitVec 32 :=
  if bits &&& 2139095040#32 = 2139095040#32 then
    if bits &&& 8388607#32 = 0#32 then bits else 2143289344#32
  else bits

theorem packedNaN32_eq_constant :
    UnpackedFloat.packedNaN Format.binary32 = 2143289344#32 := by
  decide

theorem canonicalMask32_eq_compact (bits : BitVec 32) :
    canonicalMask32 bits = canonicalPacked Format.binary32 bits := by
  unfold canonicalMask32 canonicalPacked
  by_cases he : bits &&& 2139095040#32 = 2139095040#32
  · have he' : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (-1#8) :=
      (binary32ExponentMask_iff bits).mp he
    simp only [if_pos he, if_pos he']
    by_cases hm : bits &&& 8388607#32 = 0#32
    · have hm' : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#23) :=
        (binary32FractionMask_iff bits).mp hm
      simp only [if_pos hm, if_pos hm']
    · have hm' : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits ≠ (0#23) :=
        mt (binary32FractionMask_iff bits).mpr hm
      simp only [if_neg hm, if_neg hm']
      exact packedNaN32_eq_constant.symm
  · have he' : UnpackedFloat.unpackExponent (spec := Format.binary32) bits ≠ (-1#8) :=
      mt (binary32ExponentMask_iff bits).mpr he
    simp only [if_neg he, if_neg he']

-- Direct native model of the selected PsStandard.canonicalFloat64Bits
-- source helper (UInt.land -> UInt.toNat -> Nat.beq -> Bool.rec).
-- This is not a new runtime intrinsic.
def canonicalUIntMask64 (bits : UInt64) : UInt64 :=
  if (bits &&& (9218868437227405312 : UInt64)).toNat = 9218868437227405312 then
    if (bits &&& (4503599627370495 : UInt64)).toNat = 0 then bits
    else (9221120237041090560 : UInt64)
  else bits

theorem canonicalUIntMask64_eq_logical (bits : UInt64) :
    canonicalUIntMask64 bits = UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) := by
  have hExpNat : (9218868437227405312 : UInt64).toNat = 9218868437227405312 := by decide
  have hFracNat : (4503599627370495 : UInt64).toNat = 4503599627370495 := by decide
  have hExp : (bits &&& (9218868437227405312 : UInt64)).toNat = 9218868437227405312 ↔
      bits.toBitVec &&& 9218868437227405312#64 = 9218868437227405312#64 := by
    rw [← hExpNat, UInt64.toNat_inj, ← UInt64.toBitVec_inj]
    simp [UInt64.toBitVec_and, UInt64.toBitVec_ofNat']
  have hFrac : (bits &&& (4503599627370495 : UInt64)).toNat = 0 ↔
      bits.toBitVec &&& 4503599627370495#64 = 0#64 := by
    change (bits &&& (4503599627370495 : UInt64)).toNat = (0 : UInt64).toNat ↔
      bits.toBitVec &&& 4503599627370495#64 = 0#64
    rw [UInt64.toNat_inj, ← UInt64.toBitVec_inj]
    simp [UInt64.toBitVec_and, UInt64.toBitVec_ofNat']
  apply UInt64.eq_of_toBitVec_eq
  rw [UInt64.toBitVec_ofBitVec, ← canonicalMask64_eq_compact]
  unfold canonicalUIntMask64 canonicalMask64
  by_cases he : (bits &&& (9218868437227405312 : UInt64)).toNat = 9218868437227405312
  · have he' := hExp.mp he
    by_cases hm : (bits &&& (4503599627370495 : UInt64)).toNat = 0
    · have hm' := hFrac.mp hm
      simp only [if_pos he, if_pos he', if_pos hm, if_pos hm']
    · have hm' := mt hFrac.mpr hm
      simp only [if_pos he, if_pos he']
      rw [if_neg hm, if_neg hm']
      rfl
  · have he' := mt hExp.mpr he
    simp only [if_neg he, if_neg he']

-- Direct native model of the selected PsStandard.canonicalFloat32Bits
-- source helper (UInt.land -> UInt.toNat -> Nat.beq -> Bool.rec).
-- This is not a new runtime intrinsic.
def canonicalUIntMask32 (bits : UInt32) : UInt32 :=
  if (bits &&& (2139095040 : UInt32)).toNat = 2139095040 then
    if (bits &&& (8388607 : UInt32)).toNat = 0 then bits
    else (2143289344 : UInt32)
  else bits

theorem canonicalUIntMask32_eq_logical (bits : UInt32) :
    canonicalUIntMask32 bits = UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) := by
  have hExpNat : (2139095040 : UInt32).toNat = 2139095040 := by decide
  have hFracNat : (8388607 : UInt32).toNat = 8388607 := by decide
  have hExp : (bits &&& (2139095040 : UInt32)).toNat = 2139095040 ↔
      bits.toBitVec &&& 2139095040#32 = 2139095040#32 := by
    rw [← hExpNat, UInt32.toNat_inj, ← UInt32.toBitVec_inj]
    simp [UInt32.toBitVec_and, UInt32.toBitVec_ofNat']
  have hFrac : (bits &&& (8388607 : UInt32)).toNat = 0 ↔
      bits.toBitVec &&& 8388607#32 = 0#32 := by
    change (bits &&& (8388607 : UInt32)).toNat = (0 : UInt32).toNat ↔
      bits.toBitVec &&& 8388607#32 = 0#32
    rw [UInt32.toNat_inj, ← UInt32.toBitVec_inj]
    simp [UInt32.toBitVec_and, UInt32.toBitVec_ofNat']
  apply UInt32.eq_of_toBitVec_eq
  rw [UInt32.toBitVec_ofBitVec, ← canonicalMask32_eq_compact]
  unfold canonicalUIntMask32 canonicalMask32
  by_cases he : (bits &&& (2139095040 : UInt32)).toNat = 2139095040
  · have he' := hExp.mp he
    by_cases hm : (bits &&& (8388607 : UInt32)).toNat = 0
    · have hm' := hFrac.mp hm
      simp only [if_pos he, if_pos he', if_pos hm, if_pos hm']
    · have hm' := mt hFrac.mpr hm
      simp only [if_pos he, if_pos he']
      rw [if_neg hm, if_neg hm']
      rfl
  · have he' := mt hExp.mpr he
    simp only [if_neg he, if_neg he']

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

-- Complete upstream compact-bit correspondence for every 64-bit pattern:
-- NaN, infinity, both zeros, subnormal and normal. This remains native-only
-- because upstream Float pack/unpack imports Classical.choice transitively.
theorem upstreamPackUnpack_all64 (bits : BitVec 64) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  by_cases hTop : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (-1#_)
  · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)
    · exact upstreamPackUnpack_infinity64 bits hTop hMant
    · exact upstreamPackUnpack_nan Format.binary64 bits hTop hMant
  · by_cases hZero : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (0#_)
    · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)
      · exact upstreamPackUnpack_zero64 bits hZero hMant
      · exact upstreamPackUnpack_subnormal64 bits hZero hMant
    · exact upstreamPackUnpack_normal64 bits hZero hTop

theorem fromBits64_eq_upstream_ofBits_all (bits : UInt64) :
    fromBits64 bits = Float.ofBits bits := by
  apply eq_of_toBits_eq64
  change UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) =
    UInt64.ofBitVec
      (UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits.toBitVec))
  exact congrArg UInt64.ofBitVec
    ((upstreamPackUnpack_all64 bits.toBitVec).symm)

-- Complete upstream compact-bit correspondence for every 32-bit pattern:
-- NaN, infinity, both zeros, subnormal and normal. This remains native-only
-- because upstream Float pack/unpack imports Classical.choice transitively.
theorem upstreamPackUnpack_all32 (bits : BitVec 32) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  by_cases hTop : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (-1#_)
  · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)
    · exact upstreamPackUnpack_infinity32 bits hTop hMant
    · exact upstreamPackUnpack_nan Format.binary32 bits hTop hMant
  · by_cases hZero : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (0#_)
    · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)
      · exact upstreamPackUnpack_zero32 bits hZero hMant
      · exact upstreamPackUnpack_subnormal32 bits hZero hMant
    · exact upstreamPackUnpack_normal32 bits hZero hTop

theorem fromBits32_eq_upstream_ofBits_all (bits : UInt32) :
    fromBits32 bits = Float32.ofBits bits := by
  apply eq_of_toBits_eq32
  change UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) =
    UInt32.ofBitVec
      (UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits.toBitVec))
  exact congrArg UInt32.ofBitVec
    ((upstreamPackUnpack_all32 bits.toBitVec).symm)


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

-- Complete upstream compact-bit correspondence for every 64-bit pattern:
-- NaN, infinity, both zeros, subnormal and normal. This remains native-only
-- because upstream Float pack/unpack imports Classical.choice transitively.
theorem upstreamPackUnpack_all64 (bits : BitVec 64) :
    UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits) =
      canonicalPacked Format.binary64 bits := by
  by_cases hTop : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (-1#_)
  · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)
    · exact upstreamPackUnpack_infinity64 bits hTop hMant
    · exact upstreamPackUnpack_nan Format.binary64 bits hTop hMant
  · by_cases hZero : UnpackedFloat.unpackExponent (spec := Format.binary64) bits = (0#_)
    · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary64) bits = (0#_)
      · exact upstreamPackUnpack_zero64 bits hZero hMant
      · exact upstreamPackUnpack_subnormal64 bits hZero hMant
    · exact upstreamPackUnpack_normal64 bits hZero hTop

theorem fromBits64_eq_upstream_ofBits_all (bits : UInt64) :
    fromBits64 bits = Float.ofBits bits := by
  apply eq_of_toBits_eq64
  change UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) =
    UInt64.ofBitVec
      (UnpackedFloat.pack Format.binary64 (UnpackedFloat.unpack Format.binary64 bits.toBitVec))
  exact congrArg UInt64.ofBitVec
    ((upstreamPackUnpack_all64 bits.toBitVec).symm)

-- Complete upstream compact-bit correspondence for every 32-bit pattern:
-- NaN, infinity, both zeros, subnormal and normal. This remains native-only
-- because upstream Float pack/unpack imports Classical.choice transitively.
theorem upstreamPackUnpack_all32 (bits : BitVec 32) :
    UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits) =
      canonicalPacked Format.binary32 bits := by
  by_cases hTop : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (-1#_)
  · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)
    · exact upstreamPackUnpack_infinity32 bits hTop hMant
    · exact upstreamPackUnpack_nan Format.binary32 bits hTop hMant
  · by_cases hZero : UnpackedFloat.unpackExponent (spec := Format.binary32) bits = (0#_)
    · by_cases hMant : UnpackedFloat.unpackMantissa (spec := Format.binary32) bits = (0#_)
      · exact upstreamPackUnpack_zero32 bits hZero hMant
      · exact upstreamPackUnpack_subnormal32 bits hZero hMant
    · exact upstreamPackUnpack_normal32 bits hZero hTop

theorem fromBits32_eq_upstream_ofBits_all (bits : UInt32) :
    fromBits32 bits = Float32.ofBits bits := by
  apply eq_of_toBits_eq32
  change UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) =
    UInt32.ofBitVec
      (UnpackedFloat.pack Format.binary32 (UnpackedFloat.unpack Format.binary32 bits.toBitVec))
  exact congrArg UInt32.ofBitVec
    ((upstreamPackUnpack_all32 bits.toBitVec).symm)

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
   ``binary64ExponentMask_iff, ``binary64FractionMask_iff,
   ``binary32ExponentMask_iff, ``binary32FractionMask_iff,
   ``canonicalMask64, ``canonicalMask32,
   ``packedNaN64_eq_constant, ``packedNaN32_eq_constant,
   ``canonicalMask64_eq_compact, ``canonicalMask32_eq_compact,
   ``canonicalUIntMask64, ``canonicalUIntMask32,
   ``canonicalUIntMask64_eq_logical, ``canonicalUIntMask32_eq_logical,
   ``toBits_fromBits64, ``toBits_fromBits32,
   ``eq_of_toBits_eq64, ``eq_of_toBits_eq32,
   ``fromBits64_toBits, ``fromBits32_toBits,
   ``fromBits64_eq_iff, ``fromBits32_eq_iff]

end PsV7Native.FloatCanonical
