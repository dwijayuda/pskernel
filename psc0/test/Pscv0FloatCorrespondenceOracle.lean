import Lean
import Ps.Host.FloatCorrespondence
import Lean.Util.CollectAxioms

/-!
Reference-only all-input Float correspondence. This does not change the
selected Standard, its imported assumptions, or target execution admission.
The upstream reference itself has transitive proof dependencies that the
small constructive model intentionally does not import. Report the exact
reference audit instead of mislabelling it as a portable proof closure.
-/

example (b : UInt64) : PsV7Native.FloatCanonical.fromBits64 b = Float.ofBits b :=
  PsV7Native.FloatCorrespondence.fromBits64_eq_ofBits b

example (b : UInt32) : PsV7Native.FloatCanonical.fromBits32 b = Float32.ofBits b :=
  PsV7Native.FloatCorrespondence.fromBits32_eq_ofBits b

run_cmd do
  -- Preserve the stronger admitted-model boundary independently.
  for name in [``PsV7Native.FloatCanonical.fromBits64,
      ``PsV7Native.FloatCanonical.fromBits32] do
    let used ← Lean.collectAxioms name
    for assumption in used do
      unless [``propext, ``Quot.sound].contains assumption do
        throwError "constructive Float model has an unapproved assumption: {assumption}"
  -- Exact correspondence must not introduce assumptions beyond those already
  -- in the pinned upstream reference and the two approved Lean foundations.
  let reference64 ← Lean.collectAxioms ``Float.ofBits
  let reference32 ← Lean.collectAxioms ``Float32.ofBits
  let reference := reference64 ++ reference32 ++ #[``propext, ``Quot.sound]
  for name in [``PsV7Native.FloatCorrespondence.pack_unpack,
      ``PsV7Native.FloatCorrespondence.fromBits64_eq_ofBits,
      ``PsV7Native.FloatCorrespondence.fromBits32_eq_ofBits] do
    let used ← Lean.collectAxioms name
    for assumption in used do
      if assumption == ``sorryAx || !reference.contains assumption then
        throwError "Float correspondence introduced an unexpected assumption: {assumption}"
    logInfo "PSCV0-FLOAT-CORRESPONDENCE reference-only {name}: {used}"
