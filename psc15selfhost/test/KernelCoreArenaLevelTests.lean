import KernelCore.Foundation.Core
import Ps.KernelCore.Admission.Inductive.Mutual.Analysis
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.Host.KernelCoreArena.Replay

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

def psKernelArenaAdmissionFastPathTest : Bool :=
  match PsKernelCoreArena.State.empty false with
  | Except.error _ => false
  | Except.ok state =>
      let name := psKernelArenaFuelName "ArenaAdmissionFastPath"
      let request : PsKernelDeclarationRequest :=
        PsKernelDeclarationRequest.axiomDecl {
          base := {
            name := name
            levelParams := []
            type := PsKernelExpr.sort PsKernelLevel.zero
          }
          isUnsafe := false
        }
      match
          PsKernelCoreArena.State.admitRequest state request,
          psKernelV1AdmitDeclaration state.session request with
      | Except.ok fast, Except.ok reference =>
          Bool.and
            (psKernelEnvironmentContains fast.session.environment name)
            (Bool.and
              (psKernelEnvironmentContains reference.session.environment name)
              (Nat.beq
                (psKernelEnvironmentSize fast.session.environment)
                (psKernelEnvironmentSize reference.session.environment)))
      | _, _ => false

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

def psKernelArenaLambdaFuelPair
    (expr : PsKernelExpr)
    (argCount : Nat) : Bool :=
  let reference :=
    psKernelWhnfCountLambdasWithFuel
      (Nat.succ (psKernelExprNodeCount expr))
      expr
      argCount
      0
  let bounded := psKernelWhnfCountLambdas expr argCount
  psKernelExprEq (Prod.fst reference) (Prod.fst bounded) &&
    Nat.beq (Prod.snd reference) (Prod.snd bounded)

/-- Compare structural fuel to argument-count fuel on nested lambda spines. -/
def psKernelArenaLambdaSpineFuelTests : Bool :=
  let name := PsKernelName.str PsKernelName.anonymous "spine"
  let domain := PsKernelExpr.sort PsKernelLevel.zero
  let base := PsKernelExpr.bvar 0
  let single := PsKernelExpr.lam name domain base PsKernelBinderInfo.default
  let nested :=
    PsKernelExpr.lam name domain
      (PsKernelExpr.lam name domain
        (PsKernelExpr.lam name domain base PsKernelBinderInfo.default)
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  psKernelArenaLambdaFuelPair base 4 &&
    psKernelArenaLambdaFuelPair single 0 &&
    psKernelArenaLambdaFuelPair single 1 &&
    psKernelArenaLambdaFuelPair nested 1 &&
    psKernelArenaLambdaFuelPair nested 2 &&
    psKernelArenaLambdaFuelPair nested 3 &&
    psKernelArenaLambdaFuelPair nested 4

def main : IO Unit :=
  if !psKernelCoreLevelTests then
    throw (IO.userError "PSKERNEL_CORE_ARENA_LEVEL_REGRESSION: FAIL")
  else if !psKernelArenaAdmissionFastPathTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_ADMISSION_FAST_PATH: FAIL")
  else if !psKernelArenaMutualAnalysisFuelTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_MUTUAL_ANALYSIS_FUEL: FAIL")
  else if !psKernelArenaRawConstructorSpineTest then
    throw (IO.userError "PSKERNEL_CORE_ARENA_RAW_CONSTRUCTOR_SPINE: FAIL")
  else if !psKernelArenaLambdaSpineFuelTests then
    throw (IO.userError "PSKERNEL_CORE_ARENA_LAMBDA_SPINE_FUEL: FAIL")
  else
    IO.println "PSKERNEL_CORE_ARENA_COMPATIBILITY_REGRESSIONS: PASS"
