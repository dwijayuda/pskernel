import Ps.Erasure.Recursion

/-
Runtime equation for the checked Nat-measure fixpoint.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Init/WF.lean:494-517 gives Nat.fix/fix_eq; WF/Fix.lean:78-87 puts
the smaller argument before its proof and remaining state arguments.

The exact typed definition, its complete entry telescope and actual fix
application are authoritative. Captured fixed parameters are frozen; major
and state arguments are replaced at recursive calls in original entry order.
The ordinary typed eraser owns the callback's proof slot and function ABI.
-/

def psErasureWellFoundedFixName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix"

def psErasureWellFoundedIsNat (environment : PsEnvironment)
    (scope : PsErasureScope) (type : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
    type (.constE psNatName [])

-- Open only actual lambda binders, without unfolding the fixpoint itself.
def psErasureWellFoundedOpenValue (arguments : List PsExpr) (value : PsExpr) :
    Option PsExpr :=
  match arguments with
  | [] => some value
  | argument :: rest =>
    match value with
    | .lam _ _ body _ =>
      psErasureWellFoundedOpenValue rest (psExprInstantiate1 body argument)
    | _ => none

structure PsErasureWellFoundedBinder where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

def psErasureWellFoundedCallback (environment : PsEnvironment)
    (scope : PsErasureScope) (name : PsName) (entryArguments : List PsExpr)
    (majorId : Nat) (stateIds : List Nat) (callbackType : PsExpr) :
    Except PsErasureError PsExpr := do
  let smaller ← (psInferEnsureForall environment psMetaEmpty
    scope.localContext callbackType).mapError (fun _ => PsErasureError.binderMismatch)
  if !psBinderInfoEq smaller.binder .explicit ||
      !psErasureWellFoundedIsNat environment scope smaller.domain then
    throw .unsupportedRuntimeTerm
  let argument := psLocalPushBinding scope.localContext smaller.name smaller.domain smaller.binder
  let proof ← (psInferEnsureForall environment psMetaEmpty argument.context
    (psExprInstantiate1 smaller.body (.fvar argument.id))).mapError
    (fun _ => PsErasureError.binderMismatch)
  let .proof := psErasureClassifyBinder environment argument.context proof.domain
    | throw .unsupportedRuntimeTerm
  if !psBinderInfoEq proof.binder .explicit then throw .unsupportedRuntimeTerm
  let evidence := psLocalPushBinding argument.context proof.name proof.domain proof.binder
  let mut localContext := evidence.context
  let mut resultType := psExprInstantiate1 proof.body (.fvar evidence.id)
  let mut replacements := [(majorId, PsExpr.fvar argument.id)]
  let mut bindersRev : List PsErasureWellFoundedBinder := [
    .mk evidence.id proof.name proof.domain proof.binder,
    .mk argument.id smaller.name smaller.domain smaller.binder]
  for id in stateIds do
    let state ← (psInferEnsureForall environment psMetaEmpty localContext resultType).mapError
      (fun _ => PsErasureError.binderMismatch)
    let stateScope := { scope with localContext := localContext }
    if !psBinderInfoEq state.binder .explicit ||
        !psErasureWellFoundedIsNat environment stateScope state.domain then
      throw .unsupportedRuntimeTerm
    let pushed := psLocalPushBinding localContext state.name state.domain state.binder
    replacements := replacements ++ [(id, .fvar pushed.id)]
    bindersRev := .mk pushed.id state.name state.domain state.binder :: bindersRev
    localContext := pushed.context
    resultType := psExprInstantiate1 state.body (.fvar pushed.id)
  let resultScope := { scope with localContext := localContext }
  if !psErasureWellFoundedIsNat environment resultScope resultType then
    throw .unsupportedRuntimeTerm
  let arguments ← entryArguments.mapM fun entry => do
    let .fvar id := entry | throw PsErasureError.unsupportedRuntimeTerm
    return ((replacements.find? (fun pair => pair.fst == id)).map Prod.snd).getD entry
  let self := psExprApplyMany (.constE name []) arguments
  let inferred ← (psInferType environment psMetaEmpty localContext self).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty localContext inferred resultType then
    throw .unsupportedRuntimeTerm
  let value := bindersRev.foldl (fun body binder =>
    PsExpr.lam binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) self
  let inferred ← (psInferType environment psMetaEmpty scope.localContext value).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext inferred callbackType then
    throw .unsupportedRuntimeTerm
  return value

def psEraseWellFoundedApplication (environment : PsEnvironment)
    (scope : PsErasureScope)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name levels := view.head | return none
  if !psNameEq name psErasureWellFoundedFixName then return none
  let domain :: motive :: measure :: functional :: major :: stateArguments := view.args
    | throw .unsupportedApplication
  let one := PsLevel.succ .zero
  if levels.length != 2 || !(levels.all (psLevelEquivalent one)) then
    throw .unsupportedRuntimeTerm
  let some current := scope.currentDefinition | throw .unsupportedRuntimeTerm
  let some coreName := current.coreName | throw .unsupportedRuntimeTerm
  if !current.typeArgumentsRev.isEmpty then throw .unsupportedRuntimeTerm
  let entryArguments := current.coreParametersRev.reverse
  if entryArguments.isEmpty || current.runtimeParameters.length != entryArguments.length then
    throw .unsupportedRuntimeTerm
  let entryIds ← entryArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  if entryIds.eraseDups.length != entryIds.length ||
      entryIds != scope.localContext.declarations.reverse.map psLocalDeclId then
    throw .unsupportedRuntimeTerm
  for ((id, runtimeName), declaration) in
      (entryIds.zip current.runtimeParameters).zip scope.localContext.declarations.reverse do
    let .binding actualId _ type .explicit := declaration
      | throw .unsupportedRuntimeTerm
    if actualId != id || psErasureLookupNat scope.runtimeLocals id != some runtimeName ||
        !psErasureWellFoundedIsNat environment scope type then
      throw .unsupportedRuntimeTerm
  let .fvar majorId := major | throw .unsupportedRuntimeTerm
  let stateIds ← stateArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  let changingIds := majorId :: stateIds
  if changingIds.eraseDups.length != changingIds.length ||
      !changingIds.all entryIds.contains then
    throw .unsupportedRuntimeTerm
  let some (.definitionDecl actualName [] declaredType declaredValue) :=
      psEnvironmentFind environment coreName | throw .unsupportedRuntimeTerm
  if !psNameEq actualName coreName then throw .unsupportedRuntimeTerm
  let inferredDeclaration ← (psInferType environment psMetaEmpty psLocalEmpty declaredValue).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty
      inferredDeclaration declaredType then
    throw .unsupportedRuntimeTerm
  let some opened := psErasureWellFoundedOpenValue entryArguments declaredValue
    | throw .unsupportedRuntimeTerm
  let applied := psExprApplyMany view.head view.args
  if !psExprAlphaEq opened applied then throw .unsupportedRuntimeTerm
  if !psErasureWellFoundedIsNat environment scope domain then throw .unsupportedRuntimeTerm
  -- A fixed captured local may not carry an indirect dependency on a changed
  -- argument through its declared type. No source plan authorizes this check.
  for declaration in scope.localContext.declarations do
    if !changingIds.contains (psLocalDeclId declaration) &&
        (psExprFVarIds (psLocalDeclType declaration)).any changingIds.contains then
      throw .unsupportedRuntimeTerm
  if [domain, motive, measure, functional].any (fun term =>
      (psExprFVarIds term).any changingIds.contains) then
    throw .unsupportedRuntimeTerm
  let resultType ← (psInferType environment psMetaEmpty scope.localContext applied).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psErasureWellFoundedIsNat environment scope resultType then throw .unsupportedRuntimeTerm
  let .lam callbackName callbackType body .explicit :=
      psWhnf environment psMetaEmpty scope.localContext (.app functional major)
    | throw .unsupportedRuntimeTerm
  let recursiveCore ← psErasureWellFoundedCallback environment scope coreName
    entryArguments majorId stateIds callbackType
  let nestedScope := { scope with currentDefinition := none }
  let recursiveValue ← eraseAt nestedScope recursiveCore
  let callback := psLocalPushBinding scope.localContext callbackName callbackType .explicit
  let bodyScope := { scope with
    localContext := callback.context
    erasedLocals := callback.id :: scope.erasedLocals
    runtimeExpressions := (callback.id, recursiveValue) :: scope.runtimeExpressions
    currentDefinition := none }
  let some body := psErasureWellFoundedOpenValue stateArguments
      (psExprInstantiate1 body (.fvar callback.id))
    | throw .unsupportedRuntimeTerm
  return some (← eraseAt bodyScope body)
