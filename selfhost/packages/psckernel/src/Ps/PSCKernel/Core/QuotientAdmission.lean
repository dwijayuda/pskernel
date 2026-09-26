import Ps.PSCKernel.Core.Environment

-- Lean 4 treats quotient support as a dedicated environment transaction.
-- It is not admitted as four unrelated constant declarations.

def psCKernelQuotAdmissionName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelQuotName : PsCKernelName :=
  psCKernelQuotAdmissionName "Quot"

def psCKernelQuotMkName : PsCKernelName :=
  psCKernelQuotAdmissionName "Quot.mk"

def psCKernelQuotLiftName : PsCKernelName :=
  psCKernelQuotAdmissionName "Quot.lift"

def psCKernelQuotIndName : PsCKernelName :=
  psCKernelQuotAdmissionName "Quot.ind"

def psCKernelEqName : PsCKernelName :=
  psCKernelQuotAdmissionName "Eq"

def psCKernelQuotUniverseUName : PsCKernelName :=
  psCKernelQuotAdmissionName "u"

def psCKernelQuotUniverseVName : PsCKernelName :=
  psCKernelQuotAdmissionName "v"

def psCKernelQuotAnonymousBinderName : PsCKernelName :=
  psCKernelQuotAdmissionName "_"

def psCKernelQuotArrow
    (domain codomain : PsCKernelExpr) : PsCKernelExpr :=
  PsCKernelExpr.forallE
    psCKernelQuotAnonymousBinderName
    domain
    codomain
    PsCKernelBinderInfo.default

-- Lean expression equality ignores binder display names but preserves binder info.
-- Keep this local to quotient initialization until the general expression layer
-- exposes that exact relation as a public primitive.
def psCKernelQuotShapeEq
    (left : PsCKernelExpr) : PsCKernelExpr -> Bool :=
  match left with
  | PsCKernelExpr.bvar leftIndex =>
      fun right =>
        match right with
        | PsCKernelExpr.bvar rightIndex => Nat.beq leftIndex rightIndex
        | _ => false
  | PsCKernelExpr.sortE leftLevel =>
      fun right =>
        match right with
        | PsCKernelExpr.sortE rightLevel =>
            psCKernelLevelEqStructural leftLevel rightLevel
        | _ => false
  | PsCKernelExpr.constE leftName leftLevels =>
      fun right =>
        match right with
        | PsCKernelExpr.constE rightName rightLevels =>
            psCKernelNameEq leftName rightName &&
            psCKernelLevelListEqStructural leftLevels rightLevels
        | _ => false
  | PsCKernelExpr.app leftFn leftArg =>
      fun right =>
        match right with
        | PsCKernelExpr.app rightFn rightArg =>
            psCKernelQuotShapeEq leftFn rightFn &&
            psCKernelQuotShapeEq leftArg rightArg
        | _ => false
  | PsCKernelExpr.forallE _ leftType leftBody leftInfo =>
      fun right =>
        match right with
        | PsCKernelExpr.forallE _ rightType rightBody rightInfo =>
            psCKernelBinderInfoEq leftInfo rightInfo &&
            psCKernelQuotShapeEq leftType rightType &&
            psCKernelQuotShapeEq leftBody rightBody
        | _ => false
  | _ => fun _ => false

def psCKernelQuotExpectedEqType (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionName "α")
    (PsCKernelExpr.sortE u)
    (psCKernelQuotArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero)))
    PsCKernelBinderInfo.implicit

def psCKernelQuotExpectedEqReflType (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionName "α")
    (PsCKernelExpr.sortE u)
    (PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "a")
      (PsCKernelExpr.bvar 0)
      (psCKernelExprMkAppN
        (PsCKernelExpr.constE psCKernelEqName [u])
        [PsCKernelExpr.bvar 1, PsCKernelExpr.bvar 0, PsCKernelExpr.bvar 0])
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.implicit

def psCKernelQuotEqShapeValid (env : PsCKernelEnvironment) : Bool :=
  match psCKernelEnvironmentFind? env psCKernelEqName with
  | some (PsCKernelConstantInfo.inductInfo eqValue) =>
      match eqValue.base.levelParams, eqValue.ctors with
      | [eqUName], [reflName] =>
          if psCKernelQuotShapeEq
              eqValue.base.declType
              (psCKernelQuotExpectedEqType eqUName) then
            match psCKernelEnvironmentFind? env reflName with
            | some (PsCKernelConstantInfo.ctorInfo reflValue) =>
                match reflValue.base.levelParams with
                | [reflUName] =>
                    psCKernelQuotShapeEq
                      reflValue.base.declType
                      (psCKernelQuotExpectedEqReflType reflUName)
                | _ => false
            | _ => false
          else
            false
      | _, _ => false
  | _ => false

def psCKernelQuotNamesAvailable (env : PsCKernelEnvironment) : Bool :=
  !psCKernelEnvironmentContains env psCKernelQuotName &&
  !psCKernelEnvironmentContains env psCKernelQuotMkName &&
  !psCKernelEnvironmentContains env psCKernelQuotLiftName &&
  !psCKernelEnvironmentContains env psCKernelQuotIndName

def psCKernelQuotBase
    (name : PsCKernelName)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantVal := {
  name := name
  levelParams := levelParams
  declType := declType
}

def psCKernelQuotTypeInfo : PsCKernelConstantInfo :=
  let u := PsCKernelLevel.param psCKernelQuotUniverseUName
  let relation :=
    psCKernelQuotArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero))
  let declType :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "α")
      (PsCKernelExpr.sortE u)
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "r")
        relation
        (PsCKernelExpr.sortE u)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.implicit
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelQuotBase
      psCKernelQuotName
      [psCKernelQuotUniverseUName]
      declType
    kind := PsCKernelQuotKind.type
  }

def psCKernelQuotMkInfo : PsCKernelConstantInfo :=
  let u := PsCKernelLevel.param psCKernelQuotUniverseUName
  let relation :=
    psCKernelQuotArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero))
  let result :=
    psCKernelExprMkAppN
      (PsCKernelExpr.constE psCKernelQuotName [u])
      [PsCKernelExpr.bvar 2, PsCKernelExpr.bvar 1]
  let declType :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "α")
      (PsCKernelExpr.sortE u)
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "r")
        relation
        (PsCKernelExpr.forallE
          (psCKernelQuotAdmissionName "a")
          (PsCKernelExpr.bvar 1)
          result
          PsCKernelBinderInfo.default)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.implicit
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelQuotBase
      psCKernelQuotMkName
      [psCKernelQuotUniverseUName]
      declType
    kind := PsCKernelQuotKind.ctor
  }

def psCKernelQuotLiftInfo : PsCKernelConstantInfo :=
  let u := PsCKernelLevel.param psCKernelQuotUniverseUName
  let v := PsCKernelLevel.param psCKernelQuotUniverseVName
  let relation :=
    psCKernelQuotArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero))
  let fType :=
    PsCKernelExpr.forallE
      psCKernelQuotAnonymousBinderName
      (PsCKernelExpr.bvar 2)
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.default
  let respects :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "a")
      (PsCKernelExpr.bvar 3)
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "b")
        (PsCKernelExpr.bvar 4)
        (PsCKernelExpr.forallE
          psCKernelQuotAnonymousBinderName
          (psCKernelExprMkAppN
            (PsCKernelExpr.bvar 4)
            [PsCKernelExpr.bvar 1, PsCKernelExpr.bvar 0])
          (psCKernelExprMkAppN
            (PsCKernelExpr.constE psCKernelEqName [v])
            [
              PsCKernelExpr.bvar 4,
              PsCKernelExpr.app (PsCKernelExpr.bvar 3) (PsCKernelExpr.bvar 2),
              PsCKernelExpr.app (PsCKernelExpr.bvar 3) (PsCKernelExpr.bvar 1)
            ])
          PsCKernelBinderInfo.default)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let afterF :=
    PsCKernelExpr.forallE
      psCKernelQuotAnonymousBinderName
      respects
      (PsCKernelExpr.forallE
        psCKernelQuotAnonymousBinderName
        (psCKernelExprMkAppN
          (PsCKernelExpr.constE psCKernelQuotName [u])
          [PsCKernelExpr.bvar 4, PsCKernelExpr.bvar 3])
        (PsCKernelExpr.bvar 3)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let declType :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "α")
      (PsCKernelExpr.sortE u)
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "r")
        relation
        (PsCKernelExpr.forallE
          (psCKernelQuotAdmissionName "β")
          (PsCKernelExpr.sortE v)
          (PsCKernelExpr.forallE
            (psCKernelQuotAdmissionName "f")
            fType
            afterF
            PsCKernelBinderInfo.default)
          PsCKernelBinderInfo.implicit)
        PsCKernelBinderInfo.implicit)
      PsCKernelBinderInfo.implicit
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelQuotBase
      psCKernelQuotLiftName
      [psCKernelQuotUniverseUName, psCKernelQuotUniverseVName]
      declType
    kind := PsCKernelQuotKind.lift
  }

def psCKernelQuotIndInfo : PsCKernelConstantInfo :=
  let u := PsCKernelLevel.param psCKernelQuotUniverseUName
  let relation :=
    psCKernelQuotArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero))
  let motive :=
    PsCKernelExpr.forallE
      psCKernelQuotAnonymousBinderName
      (psCKernelExprMkAppN
        (PsCKernelExpr.constE psCKernelQuotName [u])
        [PsCKernelExpr.bvar 1, PsCKernelExpr.bvar 0])
      (PsCKernelExpr.sortE psCKernelLevelZero)
      PsCKernelBinderInfo.default
  let minor :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "a")
      (PsCKernelExpr.bvar 2)
      (PsCKernelExpr.app
        (PsCKernelExpr.bvar 1)
        (psCKernelExprMkAppN
          (PsCKernelExpr.constE psCKernelQuotMkName [u])
          [PsCKernelExpr.bvar 3, PsCKernelExpr.bvar 2, PsCKernelExpr.bvar 0]))
      PsCKernelBinderInfo.default
  let afterMotive :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "mk")
      minor
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "q")
        (psCKernelExprMkAppN
          (PsCKernelExpr.constE psCKernelQuotName [u])
          [PsCKernelExpr.bvar 3, PsCKernelExpr.bvar 2])
        (PsCKernelExpr.app (PsCKernelExpr.bvar 2) (PsCKernelExpr.bvar 0))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let declType :=
    PsCKernelExpr.forallE
      (psCKernelQuotAdmissionName "α")
      (PsCKernelExpr.sortE u)
      (PsCKernelExpr.forallE
        (psCKernelQuotAdmissionName "r")
        relation
        (PsCKernelExpr.forallE
          (psCKernelQuotAdmissionName "β")
          motive
          afterMotive
          PsCKernelBinderInfo.implicit)
        PsCKernelBinderInfo.implicit)
      PsCKernelBinderInfo.implicit
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelQuotBase
      psCKernelQuotIndName
      [psCKernelQuotUniverseUName]
      declType
    kind := PsCKernelQuotKind.ind
  }

def psCKernelAddQuotConstants?
    (env : PsCKernelEnvironment) : Option PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env psCKernelQuotTypeInfo with
  | none => none
  | some env1 =>
      match psCKernelEnvironmentTryAdd env1 psCKernelQuotMkInfo with
      | none => none
      | some env2 =>
          match psCKernelEnvironmentTryAdd env2 psCKernelQuotLiftInfo with
          | none => none
          | some env3 =>
              match psCKernelEnvironmentTryAdd env3 psCKernelQuotIndInfo with
              | none => none
              | some env4 => some (psCKernelEnvironmentMarkQuotInitialized env4)

def psCKernelAddQuot?
    (env : PsCKernelEnvironment) : Option PsCKernelEnvironment :=
  if env.quotInitialized then
    some env
  else if !psCKernelQuotEqShapeValid env then
    none
  else if !psCKernelQuotNamesAvailable env then
    none
  else
    psCKernelAddQuotConstants? env
