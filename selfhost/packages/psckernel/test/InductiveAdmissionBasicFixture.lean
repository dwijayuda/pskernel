import Ps.PSCKernel.Core.InductiveAdmission

def psCKernelInductiveAdmissionFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveAdmissionFixtureType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveAdmissionFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelInductiveAdmissionFixtureJoinNats
    (values : List Nat) : String :=
  match values with
  | [] => ""
  | value :: rest =>
      match rest with
      | [] => psCKernelNatToString value
      | _ =>
          String.Internal.append
            (psCKernelNatToString value)
            (String.Internal.append
              ","
              (psCKernelInductiveAdmissionFixtureJoinNats rest))

def psCKernelInductiveAdmissionFixtureSummary
    (result : Option PsCKernelOrdinaryInductiveBasicValidation) : String :=
  match result with
  | none => "false"
  | some validation =>
      String.Internal.append
        "true|"
        (String.Internal.append
          (psCKernelNatToString validation.numIndices)
          (String.Internal.append
            "|"
            (psCKernelInductiveAdmissionFixtureJoinNats
              validation.constructorFields)))

def psCKernelInductiveAdmissionFixtureRejected
    (result : Option PsCKernelOrdinaryInductiveBasicValidation) : Bool :=
  match result with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionFixtureBaseAxiom
    (name : PsCKernelName) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := []
      declType := psCKernelInductiveAdmissionFixtureType
    }
    isUnsafe := false
  }

def psCKernelInductiveAdmissionFixtureAddRaw
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | some next => next
  | none => env

def psCKernelInductiveAdmissionFixtureEnumDecl : PsCKernelInductiveDecl :=
  let color := psCKernelInductiveAdmissionFixtureName "Basic.Color"
  let red := psCKernelInductiveAdmissionFixtureName "Basic.Color.red"
  let blue := psCKernelInductiveAdmissionFixtureName "Basic.Color.blue"
  {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionFixtureType
      ctors := [
        { name := red, type := PsCKernelExpr.constE color [] },
        { name := blue, type := PsCKernelExpr.constE color [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveAdmissionFixtureBoxDecl : PsCKernelInductiveDecl :=
  let box := psCKernelInductiveAdmissionFixtureName "Basic.Box"
  let mk := psCKernelInductiveAdmissionFixtureName "Basic.Box.mk"
  let alpha := psCKernelInductiveAdmissionFixtureName "α"
  let value := psCKernelInductiveAdmissionFixtureName "value"
  let type :=
    PsCKernelExpr.forallE
      alpha
      psCKernelInductiveAdmissionFixtureType
      psCKernelInductiveAdmissionFixtureType
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      alpha
      psCKernelInductiveAdmissionFixtureType
      (PsCKernelExpr.forallE
        value
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app
          (PsCKernelExpr.constE box [])
          (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := box
      type := type
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveAdmissionFixtureEmptyBlock : Bool :=
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := []
    isUnsafe := false
    numNested := 0
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixtureDuplicateUniverse : Bool :=
  let u := psCKernelInductiveAdmissionFixtureName "u"
  let decl := {
    psCKernelInductiveAdmissionFixtureEnumDecl with
    levelParams := [u, u]
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixtureTypeConflict : Bool :=
  let typeName := psCKernelInductiveAdmissionFixtureName "Basic.Color"
  let env :=
    psCKernelInductiveAdmissionFixtureAddRaw
      psCKernelEnvironmentEmpty
      (psCKernelInductiveAdmissionFixtureBaseAxiom typeName)
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic?
      env
      psCKernelInductiveAdmissionFixtureEnumDecl)

def psCKernelInductiveAdmissionFixtureRecursorConflict : Bool :=
  let recName :=
    psCKernelStrName
      (psCKernelInductiveAdmissionFixtureName "Basic.Color")
      "rec"
  let env :=
    psCKernelInductiveAdmissionFixtureAddRaw
      psCKernelEnvironmentEmpty
      (psCKernelInductiveAdmissionFixtureBaseAxiom recName)
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic?
      env
      psCKernelInductiveAdmissionFixtureEnumDecl)

def psCKernelInductiveAdmissionFixtureParamMismatch : Bool :=
  let decl := {
    psCKernelInductiveAdmissionFixtureBoxDecl with
    numParams := 2
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixtureDuplicateCtor : Bool :=
  let color := psCKernelInductiveAdmissionFixtureName "Basic.DuplicateCtor"
  let mk := psCKernelInductiveAdmissionFixtureName "Basic.DuplicateCtor.mk"
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionFixtureType
      ctors := [
        { name := mk, type := PsCKernelExpr.constE color [] },
        { name := mk, type := PsCKernelExpr.constE color [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixtureWrongResult : Bool :=
  let color := psCKernelInductiveAdmissionFixtureName "Basic.BadResult"
  let mk := psCKernelInductiveAdmissionFixtureName "Basic.BadResult.mk"
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionFixtureType
      ctors := [{
        name := mk
        type := psCKernelInductiveAdmissionFixtureType
      }]
    }]
    isUnsafe := false
    numNested := 0
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixtureFreeHeader : Bool :=
  let color := psCKernelInductiveAdmissionFixtureName "Basic.FreeHeader"
  let fvarId : PsCKernelFVarId := {
    name := psCKernelInductiveAdmissionFixtureName "x"
  }
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := PsCKernelExpr.fvar fvarId
      ctors := []
    }]
    isUnsafe := false
    numNested := 0
  }
  psCKernelInductiveAdmissionFixtureRejected
    (psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl)

def psCKernelInductiveAdmissionFixturePrint
    (key value : String) : IO Unit :=
  IO.println
    (String.Internal.append
      key
      (String.Internal.append "\t" value))

def main : IO Unit := do
  psCKernelInductiveAdmissionFixturePrint
    "enum"
    (psCKernelInductiveAdmissionFixtureSummary
      (psCKernelValidateOrdinaryInductiveBasic?
        psCKernelEnvironmentEmpty
        psCKernelInductiveAdmissionFixtureEnumDecl))
  psCKernelInductiveAdmissionFixturePrint
    "box"
    (psCKernelInductiveAdmissionFixtureSummary
      (psCKernelValidateOrdinaryInductiveBasic?
        psCKernelEnvironmentEmpty
        psCKernelInductiveAdmissionFixtureBoxDecl))
  psCKernelInductiveAdmissionFixturePrint
    "empty-block"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureEmptyBlock)
  psCKernelInductiveAdmissionFixturePrint
    "duplicate-universe"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureDuplicateUniverse)
  psCKernelInductiveAdmissionFixturePrint
    "type-name-conflict"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureTypeConflict)
  psCKernelInductiveAdmissionFixturePrint
    "recursor-name-conflict"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureRecursorConflict)
  psCKernelInductiveAdmissionFixturePrint
    "num-params-mismatch"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureParamMismatch)
  psCKernelInductiveAdmissionFixturePrint
    "duplicate-ctor"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureDuplicateCtor)
  psCKernelInductiveAdmissionFixturePrint
    "wrong-result"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureWrongResult)
  psCKernelInductiveAdmissionFixturePrint
    "free-header"
    (psCKernelInductiveAdmissionFixtureBoolText
      psCKernelInductiveAdmissionFixtureFreeHeader)
