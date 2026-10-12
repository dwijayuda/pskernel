import Ps.Elab.Class
import Ps.Environment.StandardInhabited

-- Phase A deriving handlers produce ordinary checked Core declarations.
-- The source command retains ownership of registration, interface exposure
-- and origin bookkeeping. This module owns only selection and Core generation.
-- No handler may install an axiom, bypass Lean checking, or silently widen
-- the selected RC4 syntax profile.

def psElabDeriveInhabitedConstructor (environment : PsEnvironment)
    (family : PsExpr) (constructor : PsConstructorInfo) :
    Except PsElabError PsExpr := do
  if constructor.numParams != 0 || !constructor.levelParams.isEmpty then
    throw (.data "deriving constructor has unsupported family parameters")
  let mut cursor := constructor.type
  let mut value := PsExpr.constE constructor.name []
  for _ in [:constructor.numFields] do
    let .forallE _ domain body _ :=
      psWhnf environment psMetaEmpty psLocalEmpty cursor
      | throw (.data "deriving constructor field telescope is incomplete")
    let inferred ← (psInferType environment psMetaEmpty psLocalEmpty domain).mapError
      PsElabError.infer
    let .sortE level := psWhnf environment psMetaEmpty psLocalEmpty inferred
      | throw (.data "deriving field must be a type")
    let target := .app (.constE (psRootName "Inhabited") [level]) domain
    let candidate := psSynthInstance environment psLocalEmpty environment.instances
      psMetaEmpty target
    let some dictionary := candidate.value
      | throw (.data "deriving constructor field has no Inhabited instance")
    let dictionary := psMetaInstantiate candidate.context dictionary
    if psExprHasUnresolvedMeta dictionary then
      throw (.data "deriving constructor field leaves unresolved typeclass parameters")
    let defaultValue := psStandardInhabitedDefault level domain dictionary
    cursor := psExprInstantiate1 body defaultValue
    value := .app value defaultValue
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty cursor family then
    throw (.data "derived constructor does not produce the expected family")
  return value

def psElabDeriveInhabited (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving requires an inductive/structure declaration")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "derived family is not an inductive")
  if info.numParams != 0 || info.numIndices != 0 || !info.levelParams.isEmpty then
    throw (.data "bounded Inhabited deriving requires a closed non-indexed family")
  let .sortE level := info.type
    | throw (.data "bounded Inhabited deriving requires a Type 0 family")
  if !psLevelEquivalent level (.succ .zero) then
    throw (.data "bounded Inhabited deriving requires a Type 0 family")
  let family := PsExpr.constE info.name []
  let name := psNameAppendStr info.name "instInhabited"
  for constructorName in info.constructors do
    let some constructor := psEnvironmentFindConstructor environment constructorName
      | throw (.data "deriving constructor is missing")
    match psElabDeriveInhabitedConstructor environment family constructor with
    | .ok defaultValue =>
      return .definitionDecl name [] (psStandardInhabitedType family)
        (psStandardInhabitedValue family defaultValue)
    | .error _ => pure ()
  throw (.data "Inhabited deriving requires a constructor with inhabitable fields")

-- Checked finite-enumeration Boolean equality, lowered through the
-- generated inductive recursor without new runtime primitives.
-- This initial selected handler refuses parameterized or payload cases.
def psElabDeriveEnumBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "deriving BEq requires a data declaration")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "deriving BEq family missing")
  if info.numParams != 0 || info.numIndices != 0 ||
      !info.levelParams.isEmpty || info.constructors.isEmpty then
    throw (.data "bounded BEq deriving requires a closed finite enumeration")
  let .sortE level := info.type
    | throw (.data "BEq deriving requires a Type 0 enumeration")
  if !psLevelEquivalent level (.succ .zero) then
    throw (.data "BEq deriving requires a Type 0 enumeration")
  for constructorName in info.constructors do
    let some constructor := psEnvironmentFindConstructor environment constructorName
      | throw (.data "BEq deriving constructor missing")
    if constructor.numParams != 0 || constructor.numFields != 0 ||
        !constructor.levelParams.isEmpty then
      throw (.data "bounded BEq deriving requires fieldless constructors")
  let family := PsExpr.constE info.name []
  let bool := PsExpr.constE psBoolName []
  let recursor := PsExpr.constE (psNameAppendStr info.name "rec") [.succ .zero]
  let rightMotive := psLogicLam 6 "_" family bool
  let outerMotive := psLogicLam 7 "_" family
    (psLogicPi 8 "right" family bool)
  let outerBranches := (info.constructors.zipIdx).map fun (_, leftIndex) =>
    let compareRight := (info.constructors.zipIdx).map fun (_, rightIndex) =>
      if leftIndex == rightIndex then PsExpr.constE psBoolTrueName []
      else PsExpr.constE psBoolFalseName []
    psLogicLam 5 "right" family
      (psLogicApply recursor ([rightMotive] ++ compareRight ++ [.fvar 5]))
  let outer := psLogicApply recursor
    ([outerMotive] ++ outerBranches ++ [.fvar 0])
  let method := psLogicLam 0 "left" family
    (psLogicLam 1 "right" family (.app outer (.fvar 1)))
  let className := psRootName "BEq"
  let dictionaryType := PsExpr.app (.constE className [.zero]) family
  let value := psLogicApply (.constE (psNameAppendStr className "mk") [.zero])
    [family, method]
  return .definitionDecl (psNameAppendStr info.name "instBEq") []
    dictionaryType value

-- Non-dependent structure equality is a fold of checked BEq dictionary
-- comparisons on corresponding projections. A dependent field's comparison
-- type may differ between left/right records, so this bounded handler
-- conservatively declines it rather than casting or assuming type equality.
def psElabDeriveStructureBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .structureType => true
    | _ => false)
    | throw (.data "structure BEq deriving requires a structure")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "structure BEq deriving family missing")
  if !info.isStructure || info.numParams != 0 || info.numIndices != 0 ||
      !info.levelParams.isEmpty || info.constructors.length != 1 then
    throw (.data "bounded BEq deriving requires one closed structure")
  let .sortE level := info.type
    | throw (.data "BEq deriving requires a Type 0 structure")
  if !psLevelEquivalent level (.succ .zero) then
    throw (.data "BEq deriving requires a Type 0 structure")
  let some ctorName := info.constructors.head?
    | throw (.data "BEq deriving constructor missing")
  let some ctor := psEnvironmentFindConstructor environment ctorName
    | throw (.data "BEq deriving constructor missing")
  if ctor.numParams != 0 || !ctor.levelParams.isEmpty then
    throw (.data "bounded BEq deriving cannot compare parameterized structures")
  let family := PsExpr.constE info.name []
  let bool := PsExpr.constE psBoolName []
  let beqClass := psRootName "BEq"
  let mut cursor := ctor.type
  let mut comparisons : List PsExpr := []
  for index in [:ctor.numFields] do
    let .forallE _ domain body _ :=
      psWhnf environment psMetaEmpty psLocalEmpty cursor
      | throw (.data "BEq deriving constructor field telescope incomplete")
    -- A non-dependent field is closed at this point; a dependent field
    -- references earlier left projections and fails the closed-type check.
    let sort ← (psInferType environment psMetaEmpty psLocalEmpty domain).mapError
      (fun _ => PsElabError.data "BEq deriving requires independent field types")
    let .sortE fieldLevel :=
      psWhnf environment psMetaEmpty psLocalEmpty sort
      | throw (.data "BEq deriving field is not a type")
    if !psLevelEquivalent fieldLevel (.succ .zero) then
      throw (.data "BEq deriving currently requires Type 0 fields")
    let target := PsExpr.app (.constE beqClass [.zero]) domain
    let candidate := psSynthInstance environment psLocalEmpty
      environment.instances psMetaEmpty target
    let some dictionary := candidate.value
      | throw (.data "BEq deriving field has no checked BEq instance")
    let dictionary := psMetaInstantiate candidate.context dictionary
    if psExprHasUnresolvedMeta dictionary then
      throw (.data "BEq deriving field leaves unresolved instance variables")
    let left := PsExpr.proj info.name index (.fvar 0)
    let right := PsExpr.proj info.name index (.fvar 1)
    let comparison := psLogicApply (.constE
        (psNameAppendStr beqClass "beq") [.zero])
      [domain, dictionary, left, right]
    comparisons := comparison :: comparisons
    cursor := psExprInstantiate1 body left
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty cursor family then
    throw (.data "BEq deriving structure constructor result mismatch")
  let boolMotive := psLogicLam 9 "_" bool bool
  let combined := comparisons.reverse.foldl (fun previous current =>
    psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
      [boolMotive, .constE psBoolFalseName [], current, previous])
    (.constE psBoolTrueName [])
  let method := psLogicLam 0 "left" family
    (psLogicLam 1 "right" family combined)
  let dictionaryType := PsExpr.app (.constE beqClass [.zero]) family
  let value := psLogicApply (.constE
      (psNameAppendStr beqClass "mk") [.zero]) [family, method]
  return .definitionDecl (psNameAppendStr info.name "instBEq") []
    dictionaryType value

def psElabDeriveBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let some member := origin.members.find? (fun member =>
    match member.role with
    | .inductiveType | .structureType => true
    | _ => false)
    | throw (.data "BEq deriving requires a data declaration")
  let some (.inductiveDecl info) := psEnvironmentFind environment member.name
    | throw (.data "BEq deriving family missing")
  if info.isStructure then psElabDeriveStructureBEq environment origin
  else psElabDeriveEnumBEq environment origin

def psElabDeriveHandler (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (handler : PsSyntaxName) :
    Except PsElabError PsDeclaration :=
  match handler.segments with
  | ["Inhabited"] => psElabDeriveInhabited environment origin
  | ["BEq"] => psElabDeriveBEq environment origin
  | _ => .error (.data "deriving handler is selected but not yet implemented")

