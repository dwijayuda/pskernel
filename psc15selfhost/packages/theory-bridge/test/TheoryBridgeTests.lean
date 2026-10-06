import Ps.TheoryBridge.Model

def psTheoryBridgeIdentityTest : Bool :=
  let bridge := psTheoryBridgeIdentity "psc-declarative-core-seed/1";
  psTheoryBridgeWellFormed bridge

def psTheoryBridgeRejectsEmptySource : Bool :=
  let bridge :=
    psTheoryBridgeV1
      ""
      "destination"
      List.nil
      List.nil
      List.nil
      "claim"
      List.nil;
  if psTheoryBridgeWellFormed bridge then
    false
  else
    true

def main : IO Unit := do
  if psTheoryBridgeIdentityTest
      && psTheoryBridgeRejectsEmptySource then
    IO.println "PSCV_THEORY_BRIDGE_TESTS: PASS"
  else
    throw (IO.userError "PSCV_THEORY_BRIDGE_TESTS: FAIL")
