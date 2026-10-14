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
