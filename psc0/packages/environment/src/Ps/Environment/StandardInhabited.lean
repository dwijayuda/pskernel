import Ps.Environment.StandardList

-- Lean 4.35-rc4 Inhabited α: an inhabited Sort u has a designated element.
-- The class itself is universe-polymorphic (including Prop); supported
-- executable instances below are selected Type 0 data families.
def psStandardInhabitedClass : List PsDeclaration :=
  let name := psRootName "Inhabited"
  let ctor := psNameAppendStr name "mk"
  let method := psNameAppendStr name "default"
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let self := PsExpr.fvar 1
  let sort := PsExpr.sortE (.param u)
  let classSort := PsExpr.sortE (.max (.succ .zero) (.param u))
  let family := PsExpr.app (.constE name [.param u]) alpha
  let params := fun body => psLogicPi 0 "α" sort body .implicit
  let paramLams := fun body => psLogicLam 0 "α" sort body .implicit
  [ .inductiveDecl (.mk name [u]
      (psLogicPi 0 "α" sort classSort) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "default" alpha family)) name 0 1 1 []),
    .definitionDecl method [u]
      (params (psLogicPi 1 "self" family alpha .instanceImplicit))
      (paramLams (psLogicLam 1 "self" family
        (.proj name 0 self) .instanceImplicit)) ]

-- Executable values inhabit Type 0 = Sort 1; instantiation of the class
-- therefore uses universe 1, not universe 0 (Prop).
def psStandardInhabitedType (type : PsExpr) : PsExpr :=
  .app (.constE (psRootName "Inhabited") [.succ .zero]) type

def psStandardInhabitedValue (type value : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psRootName "Inhabited") "mk")
    [.succ .zero]) [type, value]

-- Construct a proof-checkable default application after typeclass search.
-- The universe is the inferred sort of the requested field type, not a
-- guessed Type-0 specialization.
def psStandardInhabitedDefault (level : PsLevel)
    (type dictionary : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psRootName "Inhabited") "default")
    [level]) [type, dictionary]

def psStandardInhabitedGround (suffix : String) (type value : PsExpr) :
    PsDeclaration :=
  .definitionDecl (psNameAppendStr (psRootName "PsStandard")
    ("instInhabited" ++ suffix)) []
      (psStandardInhabitedType type) (psStandardInhabitedValue type value)

def psStandardInhabitedContainer (suffix : String) (typeName : PsName)
    (defaultValue : PsExpr → PsExpr) : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let type := .app (.constE typeName []) alpha
  let declarationType := psLogicPi 0 "α" psPreludeTypeType
    (psStandardInhabitedType type) .implicit
  let declarationValue := psLogicLam 0 "α" psPreludeTypeType
    (psStandardInhabitedValue type (defaultValue alpha)) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard")
    ("instInhabited" ++ suffix)) [] declarationType declarationValue

-- All entries are ordinary checked data or existing audited runtime primitives.
-- Crucially the collection defaults do not require Inhabited α.
def psStandardInhabitedInstances : List PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let int := PsExpr.constE psIntName []
  let bool := PsExpr.constE psBoolName []
  let str := PsExpr.constE psStringName []
  let char := PsExpr.constE psCharName []
  let unit := PsExpr.constE psUnitName []
  [ psStandardInhabitedGround "Nat" nat (.constE psNatZeroName []),
    psStandardInhabitedGround "Int" int
      (.app (.constE psIntOfNatName []) (.lit (.natural 0))),
    psStandardInhabitedGround "Bool" bool (.constE psBoolFalseName []),
    psStandardInhabitedGround "String" str (.lit (.string "")),
    psStandardInhabitedGround "Char" char
      (.app (.constE psCharOfNatName []) (.lit (.natural 0))),
    psStandardInhabitedGround "Unit" unit (.constE psUnitUnitName []),
    psStandardInhabitedContainer "Option" psOptionName psSelfHostOptionNoneOf,
    psStandardInhabitedContainer "List" psListName psSelfHostListNilOf,
    psStandardInhabitedContainer "Array" psArrayName
      (fun alpha => psLogicApply (.constE psArrayEmptyWithCapacityName [])
        [alpha, .lit (.natural 0)]) ]

def psStandardInhabitedDeclarations : List PsDeclaration :=
  psStandardInhabitedClass ++ psStandardInhabitedInstances

def psStandardPreludeDeclarationsWithInhabited : List PsDeclaration :=
  psStandardPreludeDeclarationsWithList ++ psStandardInhabitedDeclarations

def psStandardInhabitedExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardListExtend environment
  let environment := psStandardInhabitedDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let className := psRootName "Inhabited"
  let instances := psStandardInhabitedInstances.foldl (fun index declaration =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration) []
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with
    classes := className :: environment.classes
    classParameters := (className,
      { outputs := [], outputLevels := [] }) :: environment.classParameters
    instances }

-- Inventory audit only: not a substitute for the pinned RC4 differential
-- registry/digest or for kernel and backend qualification.
def psStandardInhabitedAudit (environment : PsEnvironment) : Except String Unit := do
  psStandardRegistryAudit environment
  for declaration in psStandardInhabitedDeclarations do
    psStandardAuditDeclaration environment declaration
  if !environment.classes.any (psNameEq (psRootName "Inhabited")) then
    throw "PSCV0-STANDARD: missing Inhabited class registration"
  for declaration in psStandardInhabitedInstances do
    psStandardAuditInstance environment declaration
