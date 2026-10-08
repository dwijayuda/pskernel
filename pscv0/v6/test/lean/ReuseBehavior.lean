import Ps.CompilerIr.Model
import Ps.InterfaceIr.Validate
import Ps.Syntax.ParseProofScript

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
  let acceptedParser := match psParseProofScriptSource
    "function id(x : Nat): Nat := { x }" with
    | .ok module => !module.declarations.isEmpty
    | .error _ => false
  let rejectedLegacy := match psParseProofScriptSource
    "def old (x : Nat) : Nat := x;" with
    | .error _ => true
    | .ok _ => false
  if typeChecks && witChecks && acceptedParser && rejectedLegacy then
    IO.println "PSCV_V6_OLD_IR_WIT_PARSER_BEHAVIOR_PROBE: PASS"
    return 0
  else
    IO.eprintln "PSCV_V6_OLD_IR_WIT_BEHAVIOR_PROBE: FAIL"
    return 1
