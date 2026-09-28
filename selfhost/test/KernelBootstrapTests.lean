import Ps.Kernel.Validation
import Ps.Kernel.Level

def psKernelTestName (value : String) : PsName :=
  PsName.str PsName.anonymous value

def psKernelTestExpect (condition : Bool) (message : String) : IO Unit :=
  if condition then
    pure ()
  else
    throw (IO.userError message)

def psKernelTestIsDuplicate :
    Except PsKernelStructuralError PsKernelEnvironment -> Bool
  | Except.error PsKernelStructuralError.duplicateConstant => true
  | _ => false

def psKernelTestIsDuplicateLevel :
    Except PsKernelStructuralError PsKernelEnvironment -> Bool
  | Except.error PsKernelStructuralError.duplicateLevelParameter => true
  | _ => false

def psKernelTestIsInvalidValue :
    Except PsKernelStructuralError PsKernelEnvironment -> Bool
  | Except.error PsKernelStructuralError.invalidValue => true
  | _ => false

def psKernelTestIsUnsupported :
    Except PsKernelStructuralError Unit -> Bool
  | Except.error PsKernelStructuralError.unsupportedConstantKind => true
  | _ => false

def main : IO Unit := do
  let u := psKernelTestName "u"
  let x := psKernelTestName "x"
  let a := psKernelTestName "A"

  let closedBinder :=
    PsExpr.forallE
      x
      (PsExpr.sortE PsLevel.zero)
      (PsExpr.bvar 0)
      PsBinderInfo.explicit
  psKernelTestExpect
    (psKernelExprClosed [] closedBinder)
    "bound variable under binder must be structurally closed"

  psKernelTestExpect
    (!psKernelExprClosed [] (PsExpr.bvar 0))
    "loose bound variable must fail closed"

  psKernelTestExpect
    (!psKernelExprClosed [] (PsExpr.fvar 0))
    "free variable must fail closed"

  psKernelTestExpect
    (!psKernelExprClosed [] (PsExpr.mvar 0))
    "meta variable must fail closed"

  psKernelTestExpect
    (psKernelExprClosed [u] (PsExpr.sortE (PsLevel.param u)))
    "declared universe parameter must be accepted"

  psKernelTestExpect
    (!psKernelExprClosed [] (PsExpr.sortE (PsLevel.param u)))
    "undeclared universe parameter must be rejected"


  let levelU := PsLevel.param u
  let levelV := PsLevel.param (psKernelTestName "v")
  psKernelTestExpect
    (psLevelStructuralEq
      (psKernelLevelMkMax PsLevel.zero levelU)
      levelU)
    "smart max must absorb zero"

  psKernelTestExpect
    (psKernelLevelEquivalent
      (PsLevel.max levelU levelV)
      (PsLevel.max levelV levelU))
    "kernel level normalization must make max commutative"

  psKernelTestExpect
    (psKernelLevelEquivalent
      (psKernelLevelMkIMax levelU PsLevel.zero)
      PsLevel.zero)
    "imax u 0 must normalize to zero"

  let levelVSucc := PsLevel.succ levelV
  psKernelTestExpect
    (psKernelLevelEquivalent
      (psKernelLevelMkIMax levelU levelVSucc)
      (psKernelLevelMkMax levelU levelVSucc))
    "imax u (v+1) must agree with max u (v+1)"

  psKernelTestExpect
    (psKernelLevelLe
      (psKernelLevelMkIMax levelU levelV)
      (PsLevel.max levelU levelV))
    "final-4.34 max shortcut must fall through before imax decomposition"

  let incompleteLeft := psKernelLevelMkMax levelV levelU
  let incompleteRight :=
    psKernelLevelMkMax
      (psKernelLevelMkIMax levelU levelV)
      levelU
  psKernelTestExpect
    (!psKernelLevelEquivalent incompleteLeft incompleteRight)
    "final-4.34 normalized structural equivalence must remain incomplete"
  psKernelTestExpect
    (psKernelLevelLe incompleteLeft incompleteRight
      && psKernelLevelLe incompleteRight incompleteLeft)
    "final-4.34 level order must still prove both directions"

  let base : PsKernelBaseInfo := {
    name := a
    levelParams := [u]
    type := PsExpr.sortE (PsLevel.succ (PsLevel.param u))
  }
  let axiomInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := base
      isUnsafe := false
    }

  let first := psKernelStructuralInsertOrdinary psKernelEnvironmentEmpty axiomInfo
  let environment :=
    match first with
    | Except.ok value => value
    | Except.error _ => psKernelEnvironmentEmpty

  psKernelTestExpect
    (psKernelEnvironmentContains environment a)
    "first structurally valid constant must enter the candidate environment"

  psKernelTestExpect
    (psKernelTestIsDuplicate
      (psKernelStructuralInsertOrdinary environment axiomInfo))
    "duplicate constant must be rejected"

  let duplicateLevels : PsKernelBaseInfo := {
    name := psKernelTestName "DupLevel"
    levelParams := [u, u]
    type := PsExpr.sortE (PsLevel.param u)
  }
  let duplicateLevelInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := duplicateLevels
      isUnsafe := false
    }
  psKernelTestExpect
    (psKernelTestIsDuplicateLevel
      (psKernelStructuralInsertOrdinary environment duplicateLevelInfo))
    "duplicate universe parameter must be rejected"

  let badDefinitionBase : PsKernelBaseInfo := {
    name := psKernelTestName "badDefinition"
    levelParams := []
    type := PsExpr.sortE PsLevel.zero
  }
  let badDefinition :=
    PsKernelConstantInfo.definitionInfo {
      base := badDefinitionBase
      value := PsExpr.mvar 0
      hints := PsKernelReducibilityHints.regular 0
      safety := PsKernelDefinitionSafety.safe
    }
  psKernelTestExpect
    (psKernelTestIsInvalidValue
      (psKernelStructuralInsertOrdinary environment badDefinition))
    "declaration value containing meta variables must be rejected"

  let unsupportedBase : PsKernelBaseInfo := {
    name := psKernelTestName "I"
    levelParams := []
    type := PsExpr.sortE PsLevel.zero
  }
  let unsupported :=
    PsKernelConstantInfo.inductiveInfo {
      base := unsupportedBase
      numParams := 0
      numIndices := 0
      all := [unsupportedBase.name]
      constructors := []
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    }
  psKernelTestExpect
    (psKernelTestIsUnsupported
      (psKernelStructuralCheckOrdinary environment unsupported))
    "unported constant kinds must fail closed"

  IO.println "PSC1_KERNEL_BOOTSTRAP_TESTS: PASS"
