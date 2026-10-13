import Ps.Environment.StandardInhabited

-- Lean 4.35.0 Init/Prelude.lean: two independent element universes,
-- maximum result universe, and an independent recursor motive sort.
def psStandardProductOf (alpha beta : PsExpr)
    (leftLevel rightLevel : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE psProdName [leftLevel, rightLevel]) [alpha, beta]

def psStandardProductMkOf (alpha beta fst snd : PsExpr)
    (leftLevel rightLevel : PsLevel := .zero) : PsExpr :=
  psLogicApply (.constE psProdMkName [leftLevel, rightLevel]) [alpha, beta, fst, snd]

def psStandardProductDataDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "u_1"
  let ul := PsLevel.param u
  let vl := PsLevel.param v
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let product := psStandardProductOf alpha beta ul vl
  let bind := fun body binder => psLogicPi 0 "α" (.sortE (.succ ul))
    (psLogicPi 1 "β" (.sortE (.succ vl)) body binder) binder
  let bindLams := fun body => psLogicLam 0 "α" (.sortE (.succ ul))
    (psLogicLam 1 "β" (.sortE (.succ vl)) body .implicit) .implicit
  let constructor := psStandardProductMkOf alpha beta (.fvar 4) (.fvar 5) ul vl
  let motive := PsExpr.fvar 2
  let recursorType := bind
    (psLogicPi 2 "motive" (psLogicPi 6 "value" product (.sortE (.param w)))
      (psLogicPi 3 "mk" (psLogicPi 4 "fst" alpha
        (psLogicPi 5 "snd" beta (.app motive constructor)))
        (psLogicPi 6 "value" product (.app motive (.fvar 6)))) .implicit) .implicit
  let projection := fun name index result =>
    PsDeclaration.definitionDecl name [u, v]
      (bind (psLogicPi 6 "self" product result) .implicit)
      (bindLams (psLogicLam 6 "self" product (.proj psProdName index (.fvar 6))))
  [ .inductiveDecl (.mk psProdName [u, v]
      (bind (.sortE (.succ (.max ul vl))) .explicit) 2 0 [psProdMkName] true),
    .constructorDecl (.mk psProdMkName [u, v]
      (bind (psLogicPi 4 "fst" alpha (psLogicPi 5 "snd" beta product)) .implicit)
      psProdName 0 2 2 []),
    .recursorDecl (.mk (psNameAppendStr psProdName "rec") [w, u, v]
      recursorType [psProdName] 2 0 1 1),
    projection psProdFstName 0 alpha,
    projection psProdSndName 1 beta ]

-- Shared telescope for checked product dictionaries, with actual component
-- levels. Register the same universe parameters used by the declaration.
def psStandardProductInstance (name className : String)
    (classAt : PsExpr → PsLevel → PsExpr)
    (valueAt : PsExpr → PsLevel → PsExpr → PsExpr)
    (method : PsExpr → PsExpr → PsExpr → PsLevel → PsLevel → PsExpr) : PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let ul := PsLevel.param u
  let vl := PsLevel.param v
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let product := psStandardProductOf alpha beta ul vl
  let close := fun body lambda =>
    let bind := fun id name type body binder =>
      if lambda then psLogicLam id name type body binder else psLogicPi id name type body binder
    bind 0 "α" (.sortE (.succ ul)) (bind 1 "β" (.sortE (.succ vl))
      (bind 2 "left" (classAt alpha ul)
        (bind 3 "right" (classAt beta vl) body .instanceImplicit) .instanceImplicit)
      .implicit) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard") ("inst" ++ className ++ name))
    [u, v] (close (classAt product (.max ul vl)) false)
    (close (valueAt product (.max ul vl) (method alpha beta product ul vl)) true)

def psStandardProductInhabitedInstance : PsDeclaration :=
  psStandardProductInstance "Prod" "Inhabited"
    (fun type level => psStandardInhabitedType type (.succ level))
    (fun type level value => psStandardInhabitedValue type value (.succ level))
    (fun alpha beta _ ul vl => psStandardProductMkOf alpha beta
      (psStandardInhabitedDefault (.succ ul) alpha (.fvar 2))
      (psStandardInhabitedDefault (.succ vl) beta (.fvar 3)) ul vl)

def psStandardProductBEqInstance : PsDeclaration :=
  let className := psRootName "BEq"
  psStandardProductInstance "Prod" "BEq"
    (fun type level => .app (.constE className [level]) type)
    (fun type level method => psLogicApply
      (.constE (psNameAppendStr className "mk") [level]) [type, method])
    (fun alpha beta product ul vl =>
      let compare := fun type level dictionary index =>
        psLogicApply (.constE (psNameAppendStr className "beq") [level])
          [type, dictionary, .proj psProdName index (.fvar 4), .proj psProdName index (.fvar 5)]
      let bool := PsExpr.constE psBoolName []
      let both := psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [psLogicLam 6 "_" bool bool, .constE psBoolFalseName [],
          compare beta vl (.fvar 3) 1, compare alpha ul (.fvar 2) 0]
      psLogicLam 4 "left" product (psLogicLam 5 "right" product both))

def psStandardProductInstances : List (PsDeclaration × PsName) :=
  [(psStandardProductInhabitedInstance, psRootName "Inhabited"),
   (psStandardProductBEqInstance, psRootName "BEq")]

def psStandardProductDeclarations : List PsDeclaration :=
  psStandardProductInstances.map Prod.fst

def psStandardProductExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardProductDeclarations.foldl
    (fun env declaration => (psEnvironmentAdd env declaration).getD env) environment
  let instances := psStandardProductInstances.foldl (fun index (declaration, className) =>
    let levels := psDeclarationLevelParams declaration
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration) (levels.map PsLevel.param)
      levelParams := levels
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
