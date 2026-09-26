import Ps.PSCKernel.Core.InductiveAdmissionUniverse

def psCKernelInductiveUniverseFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveUniverseFixtureAccepted
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductiveUniverse?
        psCKernelEnvironmentEmpty
        decl with
  | none => false
  | some _ => true

def psCKernelInductiveUniverseFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelInductiveUniverseFixtureUnaryDecl
    (typeName ctorName : PsCKernelName)
    (resultLevel fieldDomainLevel : PsCKernelLevel) : PsCKernelInductiveDecl :=
  let fieldName := psCKernelInductiveUniverseFixtureName "α"
  let ctorType :=
    PsCKernelExpr.forallE
      fieldName
      (PsCKernelExpr.sortE fieldDomainLevel)
      (PsCKernelExpr.constE typeName [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := typeName
      type := PsCKernelExpr.sortE resultLevel
      ctors := [{ name := ctorName, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniverseFixturePrint
    (key : String)
    (value : Bool) : IO Unit :=
  IO.println
    (String.Internal.append
      key
      (String.Internal.append
        "\t"
        (psCKernelInductiveUniverseFixtureBoolText value)))

def main : IO Unit := do
  let one := psCKernelLevelSucc psCKernelLevelZero
  let two := psCKernelLevelSucc one
  let tooLarge :=
    psCKernelInductiveUniverseFixtureUnaryDecl
      (psCKernelInductiveUniverseFixtureName "Universe.Small")
      (psCKernelInductiveUniverseFixtureName "Universe.Small.mk")
      one
      one
  let bounded :=
    psCKernelInductiveUniverseFixtureUnaryDecl
      (psCKernelInductiveUniverseFixtureName "Universe.Wide")
      (psCKernelInductiveUniverseFixtureName "Universe.Wide.mk")
      two
      one
  let propLike :=
    psCKernelInductiveUniverseFixtureUnaryDecl
      (psCKernelInductiveUniverseFixtureName "Universe.PropLike")
      (psCKernelInductiveUniverseFixtureName "Universe.PropLike.mk")
      psCKernelLevelZero
      two
  psCKernelInductiveUniverseFixturePrint
    "too-large-field"
    (psCKernelInductiveUniverseFixtureAccepted tooLarge)
  psCKernelInductiveUniverseFixturePrint
    "bounded-field"
    (psCKernelInductiveUniverseFixtureAccepted bounded)
  psCKernelInductiveUniverseFixturePrint
    "prop-field-exemption"
    (psCKernelInductiveUniverseFixtureAccepted propLike)
