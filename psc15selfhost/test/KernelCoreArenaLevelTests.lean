import KernelCore.Foundation.Core
import Ps.KernelCore.Admission.Inductive.Mutual.Analysis
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission

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

def psKernelArenaRawConstructorSpineTest : Bool :=
  let aliasName := psKernelArenaFuelName "ArenaCtorTypeAlias"
  let targetName := psKernelArenaFuelName "ArenaRawCtorTarget"
  let ctorName := PsKernelName.str targetName "mk"
  let alphaName := psKernelArenaFuelName "alpha"
  let typeOne := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  let aliasInfo : PsKernelConstantInfo :=
    PsKernelConstantInfo.defnInfo {
      base := {
        name := aliasName
        levelParams := []
        type :=
          PsKernelExpr.forallE
            alphaName
            typeOne
            typeOne
            PsKernelBinderInfo.default
      }
      value :=
        PsKernelExpr.lam
          alphaName
          typeOne
          (PsKernelExpr.bvar 0)
          PsKernelBinderInfo.default
      hints := PsKernelReducibilityHints.regular 0
      safety := PsKernelDefinitionSafety.safe
    }
  let environment :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      aliasInfo
  let hiddenCtorType :=
    PsKernelExpr.app
      (PsKernelExpr.const aliasName [])
      (PsKernelExpr.const targetName [])
  let decl : PsKernelSimpleInductiveDecl := {
    levelParams := []
    name := targetName
    type := typeOne
    ctors := [{
      name := ctorName
      type := hiddenCtorType
    }]
    isUnsafe := false
    numParams := 0
  }
  match
      psKernelAddSimpleInductive
        4096
        environment
        decl
        4096
        (Nat.mul (Nat.mul 128 1024) 1024) with
  | Except.error _ => true
  | Except.ok _ => false

def main : IO Unit :=
  if !psKernelCoreLevelTests then
    throw (IO.userError "PSKERNEL_CORE_ARENA_LEVEL_REGRESSION: FAIL")
  else if !psKernelArenaMutualAnalysisFuelTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_MUTUAL_ANALYSIS_FUEL: FAIL")
  else if !psKernelArenaRawConstructorSpineTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_RAW_CONSTRUCTOR_SPINE: FAIL")
  else
    IO.println "PSKERNEL_CORE_ARENA_COMPATIBILITY_REGRESSIONS: PASS"
