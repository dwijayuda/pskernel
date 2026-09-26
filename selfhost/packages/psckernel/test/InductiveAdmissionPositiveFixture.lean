import Ps.PSCKernel.Core.InductiveAdmissionPositive

def psCKernelInductivePositiveFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductivePositiveFixtureType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductivePositiveFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelInductivePositiveFixtureJoinNats
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
              (psCKernelInductivePositiveFixtureJoinNats rest))

def psCKernelInductivePositiveFixtureSummary
    (result : Option PsCKernelOrdinaryInductivePositiveValidation) : String :=
  match result with
  | none => "false"
  | some validation =>
      String.Internal.append
        "true|"
        (String.Internal.append
          (if validation.isRec then "1" else "0")
          (String.Internal.append
            "|"
            (String.Internal.append
              (if validation.isReflexive then "1" else "0")
              (String.Internal.append
                "|"
                (psCKernelInductivePositiveFixtureJoinNats
                  validation.constructorFields)))))

def psCKernelInductivePositiveFixtureDirectDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveFixtureName "Positive.NatLike"
  let zero := psCKernelInductivePositiveFixtureName "Positive.NatLike.zero"
  let succ := psCKernelInductivePositiveFixtureName "Positive.NatLike.succ"
  let succType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "n")
      (PsCKernelExpr.constE target [])
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveFixtureType
      ctors := [
        { name := zero, type := PsCKernelExpr.constE target [] },
        { name := succ, type := succType }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveFixtureHigherDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveFixtureName "Positive.Higher"
  let mk := psCKernelInductivePositiveFixtureName "Positive.Higher.mk"
  let callbackType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "p")
      (PsCKernelExpr.sortE psCKernelLevelZero)
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "f")
      callbackType
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveFixtureType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveFixtureNegativeDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveFixtureName "Positive.Negative"
  let mk := psCKernelInductivePositiveFixtureName "Positive.Negative.mk"
  let badFieldType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "x")
      (PsCKernelExpr.constE target [])
      (PsCKernelExpr.sortE psCKernelLevelZero)
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "f")
      badFieldType
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveFixtureType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveFixtureNonrecursiveDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveFixtureName "Positive.Color"
  let red := psCKernelInductivePositiveFixtureName "Positive.Color.red"
  let blue := psCKernelInductivePositiveFixtureName "Positive.Color.blue"
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveFixtureType
      ctors := [
        { name := red, type := PsCKernelExpr.constE target [] },
        { name := blue, type := PsCKernelExpr.constE target [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveFixtureUniverseViolationDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveFixtureName "Positive.UniverseViolation"
  let mk := psCKernelInductivePositiveFixtureName "Positive.UniverseViolation.mk"
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveFixtureName "α")
      (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero))
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveFixtureType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveFixtureRejected
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        decl with
  | none => true
  | some _ => false

def psCKernelInductivePositiveFixturePrint
    (key value : String) : IO Unit :=
  IO.println (String.Internal.append key (String.Internal.append "\t" value))

def main : IO Unit := do
  psCKernelInductivePositiveFixturePrint
    "direct"
    (psCKernelInductivePositiveFixtureSummary
      (psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveFixtureDirectDecl))
  psCKernelInductivePositiveFixturePrint
    "higher-order"
    (psCKernelInductivePositiveFixtureSummary
      (psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveFixtureHigherDecl))
  psCKernelInductivePositiveFixturePrint
    "negative"
    (psCKernelInductivePositiveFixtureBoolText
      (psCKernelInductivePositiveFixtureRejected
        psCKernelInductivePositiveFixtureNegativeDecl))
  psCKernelInductivePositiveFixturePrint
    "nonrecursive"
    (psCKernelInductivePositiveFixtureSummary
      (psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveFixtureNonrecursiveDecl))
  psCKernelInductivePositiveFixturePrint
    "universe-violation"
    (psCKernelInductivePositiveFixtureBoolText
      (psCKernelInductivePositiveFixtureRejected
        psCKernelInductivePositiveFixtureUniverseViolationDecl))
