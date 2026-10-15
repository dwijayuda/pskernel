import Ps.Host.FloatCanonical

/-!
Native reference correspondence for the small constructive Float model.

Primary implementation: Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`,
Init/Data/Float/Model/{Format/Basic,Unpacked/Pack/Basic,Float,Float32}.lean.
The proof handles every Format and every bit pattern, not sampled values.

This module is deliberately outside the selected Standard export roots.
The reference side mentions the original upstream unpack/pack definitions,
including their transitive proof dependencies. The separate native oracle
reports these dependencies; it does not authorize importing them into PSC0.
The constructive constructors and their strict portable replay are unchanged.
-/

namespace PsV7Native.FloatCorrespondence

open Float.Model (Format UnpackedFloat)
open Float.Model.UnpackedFloat
open PsV7Native.FloatCanonical

private theorem sign_roundtrip (b : BitVec 1) :
    Sign.toBitVec (Sign.ofBitVec b) = b := by
  by_cases hz : b = 0#1
  · subst b
    rfl
  · have hn : b.toNat ≠ 0 := by
      intro h
      apply hz
      exact BitVec.eq_of_toNat_eq h
    have hb : b.toNat = 1 := by
      have bound : b.toNat < 2 := b.toFin.isLt
      omega
    simp only [Sign.ofBitVec, ite_eq_right hz, Sign.toBitVec]
    apply BitVec.eq_of_toNat_eq
    exact hb.symm

-- Reassemble the three adjacent slices. No floating arithmetic or native
-- evaluator participates in this all-bitpattern representation theorem.
private theorem components_roundtrip (spec : Format) (b : BitVec spec.numBits) :
    packComponents spec (Sign.ofBitVec (unpackSign b))
      (unpackExponent b) (unpackMantissa b) = b := by
  unfold packComponents
  rw [sign_roundtrip]
  simp (discharger := omega) [unpackSign, unpackExponent, unpackMantissa,
    BitVec.extractLsb'_append_extractLsb'_eq_extractLsb']

-- Pinned Bootstrap.toNat_append is expressed with shift/or, not the newer
-- toNat_append_eq_mul_add API. Disjoint low bits justify addition exactly.
private theorem normal_mantissa_toNat {w : Nat} (m : BitVec w) :
    (1#1 ++ m).toNat = 2 ^ w + m.toNat := by
  have bound : m.toNat < 2 ^ w := m.toFin.isLt
  calc
    (1#1 ++ m).toNat = 2 ^ w ||| m.toNat := by
      simp [BitVec.toNat_append, Nat.shiftLeft_eq]
    _ = 2 ^ w + m.toNat := by
      simpa only [Nat.mul_one] using (Nat.two_pow_add_eq_or_of_lt bound 1).symm

private theorem normal_mantissa_log2 {w : Nat} (m : BitVec w) :
    (1#1 ++ m).toNat.log2 = w := by
  have lower : 2 ^ w ≤ (1#1 ++ m).toNat := by
    rw [normal_mantissa_toNat]
    omega
  have upper : (1#1 ++ m).toNat < 2 ^ (w + 1) := by
    have bound : (1#1 ++ m).toNat < 2 ^ (1 + w) := (1#1 ++ m).toFin.isLt
    simpa only [Nat.add_comm 1 w] using bound
  have nonzero : (1#1 ++ m).toNat ≠ 0 := by
    have positive := Nat.two_pow_pos w
    omega
  exact (Nat.log2_eq_iff nonzero).mpr ⟨lower, upper⟩

private theorem normal_mantissa_truncate {w : Nat} (m : BitVec w) :
    BitVec.ofNat w (1#1 ++ m).toNat = m := by
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_ofNat, normal_mantissa_toNat]
  simp

private theorem exponent_capacity (spec : Format) : 2 < 2 ^ spec.exponentBits := by
  have width : spec.exponentBits = (spec.exponentBits - 2) + 2 := by
    have bound := spec.he
    omega
  have power : 2 ^ spec.exponentBits = 2 ^ (spec.exponentBits - 2) * 4 := by
    calc
      2 ^ spec.exponentBits = 2 ^ ((spec.exponentBits - 2) + 2) :=
        congrArg (fun n : Nat => 2 ^ n) width
      _ = 2 ^ (spec.exponentBits - 2) * 4 := by
        rw [Nat.pow_add]
  rw [power]
  have positive := Nat.two_pow_pos (spec.exponentBits - 2)
  omega

private theorem pack_normal (spec : Format) (s : Sign)
    (e : BitVec spec.exponentBits) (m : BitVec spec.mantissaBitsWithoutImplicit)
    (he : e ≠ -1#_) {hp : 0 < (1#1 ++ m).toNat} :
    UnpackedFloat.pack spec (.finite s (1#1 ++ m).toNat
      ((e.toNat : Int) - (spec.exponentBias + spec.mantissaBitsWithoutImplicit)) hp) =
      packComponents spec s e m := by
  have biased : (((e.toNat : Int) -
      (spec.exponentBias + spec.mantissaBitsWithoutImplicit)) +
      spec.exponentBias + spec.mantissaBitsWithoutImplicit).toNat = e.toNat := by
    omega
  have notMax : e.toNat ≠ 2 ^ spec.exponentBits - 1 := by
    intro h
    apply he
    apply BitVec.eq_of_toNat_eq
    simpa [BitVec.neg_one_eq_allOnes] using h
  have noOverflow : ¬ 2 ^ spec.exponentBits ≤ e.toNat + 1 := by
    have bound := e.toFin.isLt
    omega
  have full : (1#1 ++ m).toNat.log2 + 1 = spec.mantissaBits := by
    rw [normal_mantissa_log2]
    simp only [Format.mantissaBits, Nat.add_comm]
  simp only [UnpackedFloat.pack, biased, ite_eq_right noOverflow, ite_eq_left full]
  rw [normal_mantissa_truncate]
  simp

private theorem pack_subnormal (spec : Format) (s : Sign)
    (e : BitVec spec.exponentBits) (m : BitVec spec.mantissaBitsWithoutImplicit)
    (he : e = 0#_) (hm : m ≠ 0#_) {hp : 0 < m.toNat} :
    UnpackedFloat.pack spec (.finite s m.toNat
      (((e.toNat : Int) - (spec.exponentBias + spec.mantissaBitsWithoutImplicit)) + 1) hp) =
      packComponents spec s e m := by
  subst e
  have biased : ((((0#spec.exponentBits).toNat : Int) -
      (spec.exponentBias + spec.mantissaBitsWithoutImplicit)) + 1 +
      spec.exponentBias + spec.mantissaBitsWithoutImplicit).toNat = 1 := by
    simp only [BitVec.toNat_ofNat, Nat.zero_mod]
    omega
  have nonzero : m.toNat ≠ 0 := by
    intro h
    exact hm (BitVec.eq_of_toNat_eq h)
  have short : m.toNat.log2 < spec.mantissaBitsWithoutImplicit :=
    (Nat.log2_lt nonzero).mpr m.toFin.isLt
  have notFull : ¬ m.toNat.log2 + 1 = spec.mantissaBits := by
    unfold Format.mantissaBits
    omega
  have noOverflow : ¬ 2 ^ spec.exponentBits ≤ 1 + 1 := by
    have capacity := exponent_capacity spec
    omega
  simp only [UnpackedFloat.pack, biased, ite_eq_right noOverflow, ite_eq_right notFull]
  simp

/-- Upstream unpack/repack is exactly direct NaN canonicalization for every bit pattern. -/
theorem pack_unpack (spec : Format) (b : BitVec spec.numBits) :
    UnpackedFloat.pack spec (UnpackedFloat.unpack spec b) = canonicalPacked spec b := by
  by_cases he : unpackExponent (spec := spec) b = -1#_
  · by_cases hm : unpackMantissa (spec := spec) b = 0#_
    · simp only [canonicalPacked, ite_eq_left he, ite_eq_left hm,
        UnpackedFloat.unpack, UnpackedFloat.pack, packedInfinity]
      simpa [he, hm] using components_roundtrip spec b
    · simp only [canonicalPacked, ite_eq_left he, ite_eq_right hm,
        UnpackedFloat.unpack, UnpackedFloat.pack]
  · by_cases he0 : unpackExponent (spec := spec) b = 0#_
    · by_cases hm : unpackMantissa (spec := spec) b = 0#_
      · simp only [canonicalPacked, ite_eq_right he, UnpackedFloat.unpack,
          ite_eq_left he0, dite_eq_left hm, UnpackedFloat.pack, packedZero]
        simpa [he0, hm] using components_roundtrip spec b
      · simp only [canonicalPacked, ite_eq_right he, UnpackedFloat.unpack,
          ite_eq_left he0, dite_eq_right hm]
        rw [pack_subnormal spec _ _ _ he0 hm]
        exact components_roundtrip spec b
    · simp only [canonicalPacked, ite_eq_right he, UnpackedFloat.unpack, ite_eq_right he0]
      rw [pack_normal spec _ _ _ he]
      exact components_roundtrip spec b

/-- Exact native-reference correspondence, including NaNs and signed zero. -/
theorem fromBits64_eq_ofBits (b : UInt64) :
    FloatCanonical.fromBits64 b = Float.ofBits b := by
  simp only [FloatCanonical.fromBits64, Float.ofBits, Float.Model.ofBits,
    Float.Model.pack, pack_unpack]

/-- Binary32 is proved separately at its own format; no binary64 rounding path. -/
theorem fromBits32_eq_ofBits (b : UInt32) :
    FloatCanonical.fromBits32 b = Float32.ofBits b := by
  simp only [FloatCanonical.fromBits32, Float32.ofBits, Float32.Model.ofBits,
    Float32.Model.pack, pack_unpack]

end PsV7Native.FloatCorrespondence
