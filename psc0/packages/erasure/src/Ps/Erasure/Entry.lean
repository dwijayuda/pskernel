import Ps.Erasure.Basic

/-
Typed correspondence between a declaration's actual Core entry telescope and
the ordinary eraser's slots. EntryInfo owns the raw forall/lambda prefix; the
scope records actual opened arguments. Neither source binder counts nor a
cached recursion plan may supply this correspondence.

Some callers can already have applied a function-valued result to additional
entry arguments. Open only the declaration's actual lambda prefix by beta
substitution, then check and apply those remaining arguments. This does not
assume function eta or promote result binders into the source header.
-/

def psErasureEntryBinderKindEq : PsErasedBinderKind → PsErasedBinderKind → Bool
  | .type, .type | .index, .index | .proof, .proof | .runtime, .runtime => true
  | _, _ => false

def psErasureEntryInfoEq (left right : PsErasureEntryInfo) : Bool :=
  left.runtimeArity == right.runtimeArity && left.typeArity == right.typeArity &&
    left.binders.length == right.binders.length &&
    (left.binders.zip right.binders).all (fun pair => psErasureEntryBinderKindEq pair.fst pair.snd)

structure PsErasureRootEntry where
  name : PsName
  levelArguments : List PsLevel
  headerArguments : List PsExpr
  applicationArguments : List PsExpr
  type : PsExpr
  value : PsExpr

def psErasureValidateRootEntry (environment : PsEnvironment) (scope : PsErasureScope) :
    Except PsErasureError PsErasureRootEntry := do
  let some current := scope.currentDefinition | throw .unsupportedRuntimeTerm
  let some name := current.coreName | throw .unsupportedRuntimeTerm
  if psErasureLookupName scope.declarationNames name != some current.name then
    throw .unsupportedRuntimeTerm
  let some (.definitionDecl actualName levels declaredType declaredValue) :=
      psEnvironmentFind environment name | throw .unsupportedRuntimeTerm
  if !psNameEq actualName name ||
      [declaredType, declaredValue].any psExprHasUnresolvedMeta ||
      [declaredType, declaredValue].any (fun term => !(psExprFVarIds term).isEmpty) then
    throw .unsupportedRuntimeTerm
  let inferred ← (psInferType environment psMetaEmpty psLocalEmpty declaredValue).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty inferred declaredType then
    throw .unsupportedRuntimeTerm
  let info ← psErasureEntryInfoWithFuel environment 4096 psLocalEmpty declaredType declaredValue
  let some cached := psErasureLookupEntry scope.declarationNames name
    | throw .unsupportedRuntimeTerm
  if !psErasureEntryInfoEq info cached then throw .unsupportedRuntimeTerm
  let arguments := current.coreParametersRev.reverse
  let ids ← arguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  let declarations := scope.localContext.declarations.reverse
  if info.binders.length > arguments.length || ids.eraseDups.length != ids.length ||
      ids != declarations.map psLocalDeclId || !scope.runtimeExpressions.isEmpty ||
      current.runtimeParameters.eraseDups.length != current.runtimeParameters.length then
    throw .unsupportedRuntimeTerm
  let mut type := declaredType
  let mut value := declaredValue
  let mut headerKinds := info.binders
  let mut runtimeParameters := current.runtimeParameters
  let mut typeArguments := current.typeArgumentsRev.reverse
  let mut previousIds : List Nat := []
  let mut runtimeIds : List Nat := []
  let mut typeIds : List Nat := []
  let mut erasedIds : List Nat := []
  for (argument, declaration) in arguments.zip declarations do
    let .binding id _ actualType actualBinder := declaration
      | throw .unsupportedRuntimeTerm
    let parameter ← (psInferEnsureForall environment psMetaEmpty
      scope.localContext type).mapError (fun _ => PsErasureError.binderMismatch)
    if !psBinderInfoEq actualBinder parameter.binder ||
        !(psExprFVarIds actualType).all previousIds.contains ||
        !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
          actualType parameter.domain then
      throw .unsupportedRuntimeTerm
    let kind := psErasureClassifyBinder environment scope.localContext parameter.domain
    match headerKinds with
    | expected :: rest =>
      if !psErasureEntryBinderKindEq kind expected then throw .unsupportedRuntimeTerm
      let .lam _ domain body binder := value | throw .unsupportedRuntimeTerm
      if !psBinderInfoEq binder parameter.binder ||
          !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
            domain parameter.domain then
        throw .unsupportedRuntimeTerm
      value := psExprInstantiate1 body argument
      headerKinds := rest
    | [] =>
      -- A result application is checked at its actual dependent type. It is
      -- not a new source header parameter or a beta/eta conversion shortcut.
      let actual ← (psInferType environment psMetaEmpty scope.localContext value).mapError
        (fun _ => PsErasureError.unsupportedRuntimeTerm)
      if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext actual type then
        throw .unsupportedRuntimeTerm
      value := .app value argument
    match kind with
    | .type =>
      let .typeParameter parameterName :: rest := typeArguments
        | throw .unsupportedRuntimeTerm
      if psErasureLookupNat scope.typeLocals id != some parameterName ||
          (psErasureLookupNat scope.runtimeLocals id).isSome ||
          !scope.erasedLocals.contains id then
        throw .unsupportedRuntimeTerm
      typeArguments := rest
      typeIds := id :: typeIds
      erasedIds := id :: erasedIds
    | .runtime =>
      let parameterName :: rest := runtimeParameters | throw .unsupportedRuntimeTerm
      if psErasureLookupNat scope.runtimeLocals id != some parameterName ||
          (psErasureLookupNat scope.typeLocals id).isSome || scope.erasedLocals.contains id then
        throw .unsupportedRuntimeTerm
      runtimeParameters := rest
      runtimeIds := id :: runtimeIds
    | .proof =>
      let parameterName :: rest := runtimeParameters | throw .unsupportedRuntimeTerm
      if (psErasureLookupNat scope.runtimeLocals id).isSome ||
          (psErasureLookupNat scope.typeLocals id).isSome ||
          !scope.erasedLocals.contains id ||
          psErasureIndexFind Bool scope.declarationNames.byOutput
            (psRootName parameterName) != some true then
        throw .unsupportedRuntimeTerm
      -- psErasureOpenProofSlot retains a Unit parameter and reserves its name;
      -- it deliberately exposes no computational local for the proof itself.
      runtimeParameters := rest
      erasedIds := id :: erasedIds
    | .index =>
      if (psErasureLookupNat scope.runtimeLocals id).isSome ||
          (psErasureLookupNat scope.typeLocals id).isSome || !scope.erasedLocals.contains id then
        throw .unsupportedRuntimeTerm
      erasedIds := id :: erasedIds
    previousIds := previousIds ++ [id]
    type := psExprInstantiate1 parameter.body argument
  if !headerKinds.isEmpty || !runtimeParameters.isEmpty || !typeArguments.isEmpty ||
      scope.runtimeLocals.map Prod.fst != runtimeIds ||
      scope.typeLocals.map Prod.fst != typeIds || scope.erasedLocals != erasedIds then
    throw .unsupportedRuntimeTerm
  let inferred ← (psInferType environment psMetaEmpty scope.localContext value).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext inferred type then
    throw .unsupportedRuntimeTerm
  return {
    name
    levelArguments := levels.map PsLevel.param
    headerArguments := arguments.take info.binders.length
    applicationArguments := arguments.drop info.binders.length
    type
    value }
