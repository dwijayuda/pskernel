import KernelCore.Foundation.Core
import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

def psKernelArenaFuelName (value : String) : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous value

def psKernelArenaFuelDefinition
    (name next : PsKernelName) : PsKernelConstantInfo :=
  PsKernelConstantInfo.defnInfo {
    base := {
      name := name
      levelParams := []
      type := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
    }
    value := PsKernelExpr.const next []
    hints := PsKernelReducibilityHints.regular 0
    safety := PsKernelDefinitionSafety.safe
  }

def psKernelArenaMutualAnalysisFuelTest : Bool :=
  let target := psKernelArenaFuelName "ArenaFuelTarget"
  let alias0 := psKernelArenaFuelName "ArenaFuelAlias0"
  let alias1 := psKernelArenaFuelName "ArenaFuelAlias1"
  let alias2 := psKernelArenaFuelName "ArenaFuelAlias2"
  let environment :=
    psKernelEnvironmentAddUnchecked
      (psKernelEnvironmentAddUnchecked
        (psKernelEnvironmentAddUnchecked
          psKernelEnvironmentEmpty
          (psKernelArenaFuelDefinition alias2 target))
        (psKernelArenaFuelDefinition alias1 alias2))
      (psKernelArenaFuelDefinition alias0 alias1)
  let session :=
    psKernelMkCheckerSession
      environment
      []
      PsKernelDefinitionSafety.safe
      0
      (Nat.mul (Nat.mul 128 1024) 1024)
  let domain := PsKernelExpr.const alias0 []
  let shape : PsKernelSimpleMutualTypeShape := {
    decl := {
      name := target
      type := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
      ctors := []
    }
    indices := []
  }
  let field : PsKernelOpenBinder :=
    PsKernelOpenBinder.mk
      (psKernelArenaFuelName "arenaFuelField")
      (psKernelArenaFuelName "field")
      domain
      PsKernelBinderInfo.default
  match
      psKernelAnalyzeSimpleMutualRecursiveArgument
        64
        session
        [target]
        [shape]
        []
        []
        field
        domain with
  | Except.ok result =>
      match result.recursiveInfo with
      | Option.some recursive =>
          Nat.beq recursive.target 0
      | Option.none => false
  | Except.error _ => false

def main : IO Unit :=
  if !psKernelCoreLevelTests then
    throw (IO.userError "PSKERNEL_CORE_ARENA_LEVEL_REGRESSION: FAIL")
  else if !psKernelArenaMutualAnalysisFuelTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_MUTUAL_ANALYSIS_FUEL: FAIL")
  else
    IO.println "PSKERNEL_CORE_ARENA_COMPATIBILITY_REGRESSIONS: PASS"
