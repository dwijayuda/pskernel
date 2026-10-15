import Lean
import Ps.Host.FloatCanonicalContracts
import Lean.Util.CollectAxioms

/-!
Research-only exact upstream Float constructor correspondence, pinned Lean
4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

The compact model's all-input correspondence remains OPEN. First prove the
entire NaN *class* (not sampled bit patterns): every raw NaN is normalized
identically to the upstream unpack/repack model for each IEEE width.
Do not export this host-side theorem through the selected Standard or
silently import the original full Float closure.
-/

namespace PsV7Native.FloatCanonical

open Float.Model

theorem fromBits64_eq_upstream_nan (bits : UInt64)
    (he : UnpackedFloat.unpackExponent
      (spec := Format.binary64) bits.toBitVec = (-1#_))
    (hm : UnpackedFloat.unpackMantissa
      (spec := Format.binary64) bits.toBitVec ≠ 0#_) :
    fromBits64 bits = Float.ofBits bits := by
  apply eq_of_toBits_eq64
  change UInt64.ofBitVec (canonicalPacked Format.binary64 bits.toBitVec) =
    UInt64.ofBitVec
      (UnpackedFloat.pack Format.binary64
        (UnpackedFloat.unpack Format.binary64 bits.toBitVec))
  simp [canonicalPacked, UnpackedFloat.unpack, UnpackedFloat.pack, he, hm]

theorem fromBits32_eq_upstream_nan (bits : UInt32)
    (he : UnpackedFloat.unpackExponent
      (spec := Format.binary32) bits.toBitVec = (-1#_))
    (hm : UnpackedFloat.unpackMantissa
      (spec := Format.binary32) bits.toBitVec ≠ 0#_) :
    fromBits32 bits = Float32.ofBits bits := by
  apply eq_of_toBits_eq32
  change UInt32.ofBitVec (canonicalPacked Format.binary32 bits.toBitVec) =
    UInt32.ofBitVec
      (UnpackedFloat.pack Format.binary32
        (UnpackedFloat.unpack Format.binary32 bits.toBitVec))
  simp [canonicalPacked, UnpackedFloat.unpack, UnpackedFloat.pack, he, hm]

-- Separate host research policy: the portable exporter must never
-- inherit previously refused upstream assumptions through these roots.
run_cmd do
  for name in [``fromBits64_eq_upstream_nan, ``fromBits32_eq_upstream_nan] do
    let deps ← Lean.collectAxioms name
    for axiom in deps do
      unless [``propext, ``Quot.sound].contains axiom do
        throwError "PSC0-F1-upstream: {name} depends on unapproved {axiom}"

end PsV7Native.FloatCanonical
