import Ps.Environment.StandardList
import Ps.Environment.InhabitedExpr

-- Lean 4.35.0 Inhabited α: an inhabited Sort u has a designated element.
-- The class itself is universe-polymorphic (including Prop); supported
-- executable instances carry each selected family's actual universe.
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

def psStandardInhabitedGround (suffix : String) (type value : PsExpr) :
    PsDeclaration :=
  .definitionDecl (psNameAppendStr (psRootName "PsStandard")
    ("instInhabited" ++ suffix)) []
      (psStandardInhabitedType type) (psStandardInhabitedValue type value)

-- One constructor for empty-container dictionaries at their actual universe.
-- Array, List and Option carry their element universe.
def psStandardInhabitedContainer (suffix : String) (parameters : List PsName)
    (level : PsLevel) (type value : PsExpr) : PsDeclaration :=
  .definitionDecl (psDecisionName ("PsStandard.instInhabited" ++ suffix)) parameters
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psStandardInhabitedType type (.succ level)) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psStandardInhabitedValue type value (.succ level)) .implicit)

def psStandardInhabitedOption : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  psStandardInhabitedContainer "Option" [u] level
    (psSelfHostOptionOf (.fvar 0) level) (psSelfHostOptionNoneOf (.fvar 0) level)

def psStandardInhabitedList : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  psStandardInhabitedContainer "List" [u] level
    (psSelfHostListOf (.fvar 0) level) (psSelfHostListNilOf (.fvar 0) level)

def psStandardInhabitedArray : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  psStandardInhabitedContainer "Array" [u] level (psPreludeArrayOf (.fvar 0) level)
    (psLogicApply (.constE psArrayEmptyWithCapacityName [level])
      [.fvar 0, .lit (.natural 0)])

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
    psStandardInhabitedOption,
    psStandardInhabitedList,
    psStandardInhabitedArray ]

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
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
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
