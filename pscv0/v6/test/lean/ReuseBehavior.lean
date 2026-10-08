import Ps.CompilerIr.Model
import Ps.InterfaceIr.Validate

/-!
Research-only compatibility check for selected old Lean algorithms.
Nothing here is imported by the V6 trusted core/native compiler.
-/ 
def main : IO UInt32 := do
  let typeChecks :=
    psVerifiedIrTypeResolved (.primitive .nat) &&
    !(psVerifiedIrTypeResolved .unknown)
  let witChecks :=
    psForeignNameValid "module-name" &&
    !(psForeignNameValid "BadName") &&
    !(psForeignNameValid "trailing-")
  if typeChecks && witChecks then
    IO.println "PSCV_V6_OLD_IR_WIT_BEHAVIOR_PROBE: PASS"
    return 0
  else
    IO.eprintln "PSCV_V6_OLD_IR_WIT_BEHAVIOR_PROBE: FAIL"
    return 1
