import Ps.PSCKernel.Core.InductiveAdmissionUniform

def psCKernelInductiveUniformFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveUniformFixtureType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveUniformFixtureListType : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelInductiveUniformFixtureName "α")
    psCKernelInductiveUniformFixtureType
    psCKernelInductiveUniformFixtureType
    PsCKernelBinderInfo.default

def psCKernelInductiveUniformFixtureDirectDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductiveUniformFixtureName "Uniform.ListLike"
  let nilName := psCKernelInductiveUniformFixtureName "Uniform.ListLike.nil"
  let consName := psCKernelInductiveUniformFixtureName "Uniform.ListLike.cons"
  let nilType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformFixtureName "α")
      psCKernelInductiveUniformFixtureType
      (PsCKernelExpr.app
        (PsCKernelExpr.constE target [])
        (PsCKernelExpr.bvar 0))
      PsCKernelBinderInfo.default
  let consType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformFixtureName "α")
      psCKernelInductiveUniformFixtureType
      (PsCKernelExpr.forallE
        (psCKernelInductiveUniformFixtureName "x")
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.forallE
          (psCKernelInductiveUniformFixtureName "xs")
          (PsCKernelExpr.app
            (PsCKernelExpr.constE target [])
            (PsCKernelExpr.bvar 1))
          (PsCKernelExpr.app
            (PsCKernelExpr.constE target [])
            (PsCKernelExpr.bvar 2))
          PsCKernelBinderInfo.default)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := target
      type := psCKernelInductiveUniformFixtureListType
      ctors := [
        { name := nilName, type := nilType },
        { name := consName, type := consType }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniformFixtureErasedDecl
    (validParameter : Bool) : PsCKernelInductiveDecl :=
  let target := psCKernelInductiveUniformFixtureName "Uniform.Erased"
  let mk := psCKernelInductiveUniformFixtureName "Uniform.Erased.mk"
  let recursiveArgument :=
    if validParameter then
      PsCKernelExpr.bvar 0
    else
      PsCKernelExpr.sortE psCKernelLevelZero
  let recursiveOccurrence :=
    PsCKernelExpr.app
      (PsCKernelExpr.constE target [])
      recursiveArgument
  let eraser :=
    PsCKernelExpr.lam
      (psCKernelInductiveUniformFixtureName "ignored")
      psCKernelInductiveUniformFixtureType
      (PsCKernelExpr.sortE psCKernelLevelZero)
      PsCKernelBinderInfo.default
  let erasedFieldType := PsCKernelExpr.app eraser recursiveOccurrence
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformFixtureName "α")
      psCKernelInductiveUniformFixtureType
      (PsCKernelExpr.forallE
        (psCKernelInductiveUniformFixtureName "ghost")
        erasedFieldType
        (PsCKernelExpr.app
          (PsCKernelExpr.constE target [])
          (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := target
      type := psCKernelInductiveUniformFixtureListType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniformFixtureAccepted
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductiveUniform?
        psCKernelEnvironmentEmpty
        decl with
  | none => false
  | some _ => true

def psCKernelInductiveUniformFixturePrint
    (key : String)
    (value : Bool) : IO Unit :=
  IO.println
    (String.Internal.append
      key
      (String.Internal.append "\t" (if value then "true" else "false")))

def main : IO Unit := do
  psCKernelInductiveUniformFixturePrint
    "direct"
    (psCKernelInductiveUniformFixtureAccepted
      psCKernelInductiveUniformFixtureDirectDecl)
  psCKernelInductiveUniformFixturePrint
    "erased-uniform"
    (psCKernelInductiveUniformFixtureAccepted
      (psCKernelInductiveUniformFixtureErasedDecl true))
  psCKernelInductiveUniformFixturePrint
    "erased-nonuniform"
    (psCKernelInductiveUniformFixtureAccepted
      (psCKernelInductiveUniformFixtureErasedDecl false))
