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
