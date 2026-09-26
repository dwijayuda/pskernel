import Ps.PSCKernel.Core.Environment

def psCKernelEnvironmentFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelEnvironmentFixtureEmit (key : String) (value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def psCKernelEnvironmentFixtureEmitBool (key : String) (value : Bool) : IO Unit :=
  psCKernelEnvironmentFixtureEmit key (psCKernelEnvironmentFixtureBoolText value)

def psCKernelEnvironmentFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelEnvironmentFixtureExpr (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelEnvironmentFixtureName text) []

def psCKernelEnvironmentFixtureAxiom (text : String) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelEnvironmentFixtureName text
      levelParams := []
      declType := psCKernelEnvironmentFixtureExpr "Type"
    }
    isUnsafe := false
  }

def psCKernelEnvironmentFixtureFoundName
    (value : Option PsCKernelConstantInfo) : String :=
  match value with
  | none => "<none>"
  | some info => psCKernelNameToString (psCKernelConstantInfoName info)

def main : IO Unit := do
  let empty := psCKernelEnvironmentEmpty
  let nameA := psCKernelEnvironmentFixtureName "A"
  let nameB := psCKernelEnvironmentFixtureName "B"
  let nameAB := psCKernelEnvironmentFixtureName "A.B"

  psCKernelEnvironmentFixtureEmit "empty.size" (toString (psCKernelEnvironmentSize empty))
  psCKernelEnvironmentFixtureEmitBool "empty.hasA" (psCKernelEnvironmentContains empty nameA)
  psCKernelEnvironmentFixtureEmitBool "quot.initial" empty.quotInitialized

  match psCKernelEnvironmentTryAdd empty (psCKernelEnvironmentFixtureAxiom "A") with
  | none =>
      psCKernelEnvironmentFixtureEmit "internal.add" "failed"
  | some envA =>
      psCKernelEnvironmentFixtureEmit "add.size" (toString (psCKernelEnvironmentSize envA))
      psCKernelEnvironmentFixtureEmitBool "add.hasA" (psCKernelEnvironmentContains envA nameA)
      psCKernelEnvironmentFixtureEmit
        "add.findA"
        (psCKernelEnvironmentFixtureFoundName (psCKernelEnvironmentFind? envA nameA))
      psCKernelEnvironmentFixtureEmit "persistent.baseSize" (toString (psCKernelEnvironmentSize empty))
      psCKernelEnvironmentFixtureEmitBool
        "duplicate.rejected"
        (match psCKernelEnvironmentTryAdd envA (psCKernelEnvironmentFixtureAxiom "A") with
         | none => true
         | some _ => false)
      match psCKernelEnvironmentTryAdd envA (psCKernelEnvironmentFixtureAxiom "B") with
      | none =>
          psCKernelEnvironmentFixtureEmit "internal.secondAdd" "failed"
      | some envB =>
          psCKernelEnvironmentFixtureEmit "two.size" (toString (psCKernelEnvironmentSize envB))
          psCKernelEnvironmentFixtureEmitBool "two.hasB" (psCKernelEnvironmentContains envB nameB)
      let marked := psCKernelEnvironmentMarkQuotInitialized envA
      psCKernelEnvironmentFixtureEmitBool "quot.marked" marked.quotInitialized
      psCKernelEnvironmentFixtureEmit "quot.preserveSize" (toString (psCKernelEnvironmentSize marked))

  match psCKernelEnvironmentTryAdd empty (psCKernelEnvironmentFixtureAxiom "A.B") with
  | none =>
      psCKernelEnvironmentFixtureEmit "internal.exactAdd" "failed"
  | some exactEnv =>
      psCKernelEnvironmentFixtureEmitBool "exact.hasAB" (psCKernelEnvironmentContains exactEnv nameAB)
      psCKernelEnvironmentFixtureEmitBool "exact.hasB" (psCKernelEnvironmentContains exactEnv nameB)
