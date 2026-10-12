import Ps.Environment.StandardInhabited

-- Type-0 built-in product constructors are defined once for both the
-- kernel-facing prelude and the selected Standard dictionary instances.
def psStandardProductOf (alpha beta : PsExpr) : PsExpr :=
  psLogicApply (.constE psProdName []) [alpha, beta]

def psStandardProductMkOf (alpha beta fst snd : PsExpr) : PsExpr :=
  psLogicApply (.constE psProdMkName []) [alpha, beta, fst, snd]

-- The two component dictionaries are actual required arguments. There is
-- no universal default or BEq for a product whose fields lack the instances.
def psStandardProductInhabitedInstance : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let classAlpha := psStandardInhabitedType alpha
  let classBeta := psStandardInhabitedType beta
  let leftDefault := psStandardInhabitedDefault (.succ .zero) alpha (.fvar 2)
  let rightDefault := psStandardInhabitedDefault (.succ .zero) beta (.fvar 3)
  let product := psStandardProductOf alpha beta
  let result := psStandardInhabitedValue product
    (psStandardProductMkOf alpha beta leftDefault rightDefault)
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "left" classAlpha
        (psLogicPi 3 "right" classBeta
          (psStandardInhabitedType product) .instanceImplicit)
        .instanceImplicit) .implicit) .implicit
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "left" classAlpha
        (psLogicLam 3 "right" classBeta result .instanceImplicit)
        .instanceImplicit) .implicit) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard") "instInhabitedProd")
    [] type value

def psStandardProductBEqInstance : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let className := psRootName "BEq"
  let classAlpha := PsExpr.app (.constE className [.zero]) alpha
  let classBeta := PsExpr.app (.constE className [.zero]) beta
  let product := psStandardProductOf alpha beta
  let leftFst := PsExpr.proj psProdName 0 (.fvar 4)
  let rightFst := PsExpr.proj psProdName 0 (.fvar 5)
  let leftSnd := PsExpr.proj psProdName 1 (.fvar 4)
  let rightSnd := PsExpr.proj psProdName 1 (.fvar 5)
  let beq := PsExpr.constE (psNameAppendStr className "beq") [.zero]
  let fstEqual := psLogicApply beq [alpha, .fvar 2, leftFst, rightFst]
  let sndEqual := psLogicApply beq [beta, .fvar 3, leftSnd, rightSnd]
  let bool := PsExpr.constE psBoolName []
  let boolMotive := psLogicLam 6 "_" bool bool
  -- False short-circuits; a true first component selects the second check.
  let both := psLogicApply
    (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [boolMotive, .constE psBoolFalseName [], sndEqual, fstEqual]
  let method := psLogicLam 4 "left" product
    (psLogicLam 5 "right" product both)
  let dictionaryType := PsExpr.app (.constE className [.zero]) product
  let dictionary := psLogicApply
    (.constE (psNameAppendStr className "mk") [.zero]) [product, method]
  let type := psLogicPi 0 "α" psPreludeTypeType
    (psLogicPi 1 "β" psPreludeTypeType
      (psLogicPi 2 "left" classAlpha
        (psLogicPi 3 "right" classBeta dictionaryType .instanceImplicit)
        .instanceImplicit) .implicit) .implicit
  let value := psLogicLam 0 "α" psPreludeTypeType
    (psLogicLam 1 "β" psPreludeTypeType
      (psLogicLam 2 "left" classAlpha
        (psLogicLam 3 "right" classBeta dictionary .instanceImplicit)
        .instanceImplicit) .implicit) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard") "instBEqProd")
    [] type value

def psStandardProductInstances : List (PsDeclaration × PsName) :=
  [(psStandardProductInhabitedInstance, psRootName "Inhabited"),
   (psStandardProductBEqInstance, psRootName "BEq")]

def psStandardProductDeclarations : List PsDeclaration :=
  psStandardProductInstances.map Prod.fst

-- The product inductive/constructor/recursor must be installed before these
-- definitions: registration cannot supply a missing dependent family.
def psStandardProductExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardProductDeclarations.foldl
    (fun env declaration => (psEnvironmentAdd env declaration).getD env) environment
  let instances := psStandardProductInstances.foldl (fun index (declaration, className) =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration) []
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with instances }

def psStandardProductAudit (environment : PsEnvironment) : Except String Unit := do
  psStandardInhabitedAudit environment
  for (declaration, className) in psStandardProductInstances do
    psStandardAuditDeclaration environment declaration
    unless environment.instances.entries.any (fun entry =>
      let ownsClass := match entry.className with
        | some registered => psNameEq registered className
        | none => false
      ownsClass && match entry.value with
      | .constE name _ => psNameEq name (psDeclarationName declaration)
      | _ => false) do
      throw "PSCV0-STANDARD: missing checked product instance"
