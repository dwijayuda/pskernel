import Ps.Erasure.Recursion
import Ps.Erasure.Entry

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
    (scope : PsErasureScope) (name : PsName) (levels : List PsLevel)
    (entryArguments : List PsExpr)
    (majorId : Nat) (stateIds : List Nat) (callbackType : PsExpr) :
    Except PsErasureError PsExpr := do
  let smaller ← (psInferEnsureForall environment psMetaEmpty
    scope.localContext callbackType).mapError (fun _ => PsErasureError.binderMismatch)
  if !psBinderInfoEq smaller.binder .explicit then throw .unsupportedRuntimeTerm
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
    if !psBinderInfoEq state.binder .explicit then throw .unsupportedRuntimeTerm
    let pushed := psLocalPushBinding localContext state.name state.domain state.binder
    replacements := replacements ++ [(id, .fvar pushed.id)]
    bindersRev := .mk pushed.id state.name state.domain state.binder :: bindersRev
    localContext := pushed.context
    resultType := psExprInstantiate1 state.body (.fvar pushed.id)
  let arguments ← entryArguments.mapM fun entry => do
    let .fvar id := entry | throw PsErasureError.unsupportedRuntimeTerm
    return ((replacements.find? (fun pair => pair.fst == id)).map Prod.snd).getD entry
  let self := psExprApplyMany (.constE name levels) arguments
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
  let domain :: motive :: measure :: functional :: major :: arguments := view.args
    | throw .unsupportedApplication
  if levels.length != 2 then throw .unsupportedRuntimeTerm
  let entry ← psErasureValidateRootEntry environment scope
  let applied := psExprApplyMany view.head view.args
  if !psExprAlphaEq entry.value applied ||
      arguments.length < entry.applicationArguments.length then
    throw .unsupportedRuntimeTerm
  let stateCount := arguments.length - entry.applicationArguments.length
  let stateArguments := arguments.take stateCount
  let applicationArguments := arguments.drop stateCount
  if !(applicationArguments.zip entry.applicationArguments).all
      (fun pair => psExprAlphaEq pair.fst pair.snd) then
    throw .unsupportedRuntimeTerm
  let entryIds ← entry.headerArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  let .fvar majorId := major | throw .unsupportedRuntimeTerm
  let stateIds ← stateArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  let changingIds := majorId :: stateIds
  if changingIds.eraseDups.length != changingIds.length ||
      !changingIds.all entryIds.contains then
    throw .unsupportedRuntimeTerm
  let fixedIds := entryIds.filter fun id => !changingIds.contains id
  -- Fixed captures cannot indirectly depend on a changed argument through
  -- their types. Extra result-application arguments are not fixed captures.
  for declaration in scope.localContext.declarations do
    if fixedIds.contains (psLocalDeclId declaration) &&
        (psExprFVarIds (psLocalDeclType declaration)).any changingIds.contains then
      throw .unsupportedRuntimeTerm
  if [domain, motive, measure, functional].any (fun term =>
      !(psExprFVarIds term).all fixedIds.contains) then
    throw .unsupportedRuntimeTerm
  let resultType ← (psInferType environment psMetaEmpty scope.localContext applied).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext resultType entry.type then
    throw .unsupportedRuntimeTerm
  let .lam callbackName callbackType body .explicit :=
      psWhnf environment psMetaEmpty scope.localContext (.app functional major)
    | throw .unsupportedRuntimeTerm
  let recursiveCore ← psErasureWellFoundedCallback environment scope entry.name
    entry.levelArguments entry.headerArguments majorId stateIds callbackType
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
  let body := psExprApplyMany body applicationArguments
  let bodyType ← (psInferType environment psMetaEmpty bodyScope.localContext body).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty bodyScope.localContext bodyType entry.type then
    throw .unsupportedRuntimeTerm
  return some (← eraseAt bodyScope body)
