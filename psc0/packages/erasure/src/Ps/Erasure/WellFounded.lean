import Ps.Erasure.Recursion
import Ps.Erasure.Entry
import Ps.Meta.WellFounded

/-
Runtime equation for the checked unary well-founded fixpoint.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Init/WF.lean gives the generic and Nat fixedpoints; WF/Fix.lean:78-87 puts
the smaller argument before its proof and remaining state arguments.

The exact typed definition, its complete entry telescope and actual fix
application are authoritative. Captured fixed parameters are frozen; major
and state arguments are replaced at recursive calls in original entry order.
The ordinary typed eraser owns the callback's proof slot and function ABI.
-/

def psErasureWellFoundedFixName : PsName :=
  psWellFoundedFixName

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


-- Only the actual constructor at a checked declaration entry owns this
-- two-slot encoding. A user's PSigma in either slot is not flattened.
def psErasureWellFoundedPairEntry (environment : PsEnvironment)
    (scope : PsErasureScope) (entryIds : List Nat) (domain major : PsExpr) :
    Except PsErasureError (PsWellFoundedPairPacking × Nat × Nat) := do
  let some packing := psWellFoundedPairPackingView domain
    | throw .unsupportedRuntimeTerm
  let some (.fvar firstId, .fvar secondId) := psWellFoundedPairUnpack packing major
    | throw .unsupportedRuntimeTerm
  let [firstSlot, secondSlot] := entryIds.filter (fun id => id == firstId || id == secondId)
    | throw .unsupportedRuntimeTerm
  if firstId == secondId || firstSlot != firstId || secondSlot != secondId then
    throw .unsupportedRuntimeTerm
  let some (.binding _ _ secondType _) := psLocalFindById scope.localContext secondId
    | throw .unsupportedRuntimeTerm
  if !(psExprFVarIds secondType).contains firstId then
    throw .unsupportedRuntimeTerm
  let inferred ← (psInferType environment psMetaEmpty scope.localContext major).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psWellFoundedDefEq environment psMetaEmpty scope.localContext inferred domain then
    throw .unsupportedRuntimeTerm
  return (packing, firstId, secondId)

-- The runtime callback retains the two source arguments and ordinary Unit
-- proof slot. Its body calls the real public function in full header order.
def psErasureWellFoundedPairCallback (environment : PsEnvironment)
    (scope : PsErasureScope) (name : PsName) (levels : List PsLevel)
    (entryArguments : List PsExpr) (firstId secondId : Nat) (sourceType : PsExpr) :
    Except PsErasureError PsExpr := do
  let first ← (psInferEnsureForall environment psMetaEmpty scope.localContext sourceType).mapError
    (fun _ => PsErasureError.binderMismatch)
  if !psBinderInfoEq first.binder .explicit then throw .unsupportedRuntimeTerm
  let firstLocal := psLocalPushBinding scope.localContext first.name first.domain first.binder
  let second ← (psInferEnsureForall environment psMetaEmpty firstLocal.context
    (psExprInstantiate1 first.body (.fvar firstLocal.id))).mapError
    (fun _ => PsErasureError.binderMismatch)
  if !psBinderInfoEq second.binder .explicit then throw .unsupportedRuntimeTerm
  let secondLocal := psLocalPushBinding firstLocal.context second.name second.domain second.binder
  let proof ← (psInferEnsureForall environment psMetaEmpty secondLocal.context
    (psExprInstantiate1 second.body (.fvar secondLocal.id))).mapError
    (fun _ => PsErasureError.binderMismatch)
  let .proof := psErasureClassifyBinder environment secondLocal.context proof.domain
    | throw .unsupportedRuntimeTerm
  if !psBinderInfoEq proof.binder .explicit then throw .unsupportedRuntimeTerm
  let evidence := psLocalPushBinding secondLocal.context proof.name proof.domain proof.binder
  let resultType := psExprInstantiate1 proof.body (.fvar evidence.id)
  let arguments ← entryArguments.mapM fun entry => do
    let .fvar id := entry | throw PsErasureError.unsupportedRuntimeTerm
    return if id == firstId then .fvar firstLocal.id
      else if id == secondId then .fvar secondLocal.id else entry
  let self := psExprApplyMany (.constE name levels) arguments
  let inferred ← (psInferType environment psMetaEmpty evidence.context self).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty evidence.context inferred resultType then
    throw .unsupportedRuntimeTerm
  let value := PsExpr.lam first.name first.domain
    (psExprAbstractFVar firstLocal.id (.lam second.name second.domain
      (psExprAbstractFVar secondLocal.id (.lam proof.name proof.domain
        (psExprAbstractFVar evidence.id self) proof.binder)) second.binder)) first.binder
  let inferred ← (psInferType environment psMetaEmpty scope.localContext value).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext inferred sourceType then
    throw .unsupportedRuntimeTerm
  return value

-- Both matched terms are closed with respect to bound variables: inference
-- checks the adapter in its actual local context, and the replacement is one
-- fresh free variable. Therefore entering binders needs no de Bruijn shift.
-- Types and proof terms are visited too; the caller rejects every leftover
-- use of the raw unary callback after this exact replacement.
def psErasureWellFoundedReplaceAdapter (adapter replacement : PsExpr)
    (expression : PsExpr) : Nat × PsExpr :=
  if psExprAlphaEq expression adapter then (1, replacement) else
    match expression with
    | .app function argument =>
      let (leftCount, left) := psErasureWellFoundedReplaceAdapter adapter replacement function
      let (rightCount, right) := psErasureWellFoundedReplaceAdapter adapter replacement argument
      (leftCount + rightCount, .app left right)
    | .lam name type body binder =>
      let (typeCount, type) := psErasureWellFoundedReplaceAdapter adapter replacement type
      let (bodyCount, body) := psErasureWellFoundedReplaceAdapter adapter replacement body
      (typeCount + bodyCount, .lam name type body binder)
    | .forallE name type body binder =>
      let (typeCount, type) := psErasureWellFoundedReplaceAdapter adapter replacement type
      let (bodyCount, body) := psErasureWellFoundedReplaceAdapter adapter replacement body
      (typeCount + bodyCount, .forallE name type body binder)
    | .letE name type value body =>
      let (typeCount, type) := psErasureWellFoundedReplaceAdapter adapter replacement type
      let (valueCount, value) := psErasureWellFoundedReplaceAdapter adapter replacement value
      let (bodyCount, body) := psErasureWellFoundedReplaceAdapter adapter replacement body
      (typeCount + valueCount + bodyCount, .letE name type value body)
    | .proj name index value =>
      let (count, value) := psErasureWellFoundedReplaceAdapter adapter replacement value
      (count, .proj name index value)
    | _ => (0, expression)

def psEraseWellFoundedPairBody (environment : PsEnvironment)
    (scope : PsErasureScope)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (entry : PsErasureRootEntry) (packing : PsWellFoundedPairPacking)
    (firstId secondId : Nat) (callbackName : PsName)
    (callbackType body : PsExpr) (applicationArguments : List PsExpr) :
    Except PsErasureError PsVerifiedIrExpr := do
  let some (.binding _ firstName _ _) := psLocalFindById scope.localContext firstId
    | throw .unsupportedRuntimeTerm
  let some (.binding _ secondName _ _) := psLocalFindById scope.localContext secondId
    | throw .unsupportedRuntimeTerm
  let sourceType ← (psWellFoundedPairCurryType environment psMetaEmpty scope.localContext
    packing firstName secondName callbackType).mapError
      (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let raw := psLocalPushBinding scope.localContext callbackName callbackType .explicit
  let adapter ← (psWellFoundedPairCurryCallback environment psMetaEmpty raw.context packing
    sourceType (.fvar raw.id)).mapError (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let sourceBody := psExprApplyMany (psExprInstantiate1 body (.fvar raw.id)) applicationArguments
  let beforeType ← (psInferType environment psMetaEmpty raw.context sourceBody).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty raw.context beforeType entry.type then
    throw .unsupportedRuntimeTerm
  let curried := psLocalPushBinding raw.context
    (psNameAppendStr callbackName "curried") sourceType .explicit
  let (replacements, body) := psErasureWellFoundedReplaceAdapter adapter (.fvar curried.id) sourceBody
  if replacements == 0 || (psExprFVarIds body).contains raw.id then
    throw .unsupportedRuntimeTerm
  let afterType ← (psInferType environment psMetaEmpty curried.context body).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty curried.context afterType entry.type then
    throw .unsupportedRuntimeTerm
  let recursiveCore ← psErasureWellFoundedPairCallback environment scope entry.name
    entry.levelArguments entry.headerArguments firstId secondId sourceType
  let recursiveValue ← eraseAt { scope with currentDefinition := none } recursiveCore
  let bodyScope := { scope with
    localContext := curried.context
    erasedLocals := raw.id :: curried.id :: scope.erasedLocals
    runtimeExpressions := (curried.id, recursiveValue) :: scope.runtimeExpressions
    currentDefinition := none }
  eraseAt bodyScope body

def psEraseWellFoundedApplication (environment : PsEnvironment)
    (scope : PsErasureScope)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let viewed ← (psWellFoundedFixApplicationView view.head view.args).mapError (fun error =>
    match error with
    | .expectedFunction => PsErasureError.unsupportedApplication
    | _ => PsErasureError.unsupportedRuntimeTerm)
  let some fixed := viewed | return none
  let motive := fixed.motive
  let functional := fixed.functional
  let major := fixed.major
  let arguments := fixed.arguments
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
  let stateIds ← stateArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw .unsupportedRuntimeTerm
  let (majorIds, packing) ← match major with
    | .fvar id => pure ([id], none)
    | _ => do
      if !stateIds.isEmpty then throw .unsupportedRuntimeTerm
      let (packing, firstId, secondId) ← psErasureWellFoundedPairEntry environment
        scope entryIds fixed.plan.domain major
      pure ([firstId, secondId], some (packing, firstId, secondId))
  let changingIds := majorIds ++ stateIds
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
  if (psWellFoundedPlanTerms fixed.plan ++ [motive, functional]).any (fun term =>
      !(psExprFVarIds term).all fixedIds.contains) then
    throw .unsupportedRuntimeTerm
  let resultType ← (psInferType environment psMetaEmpty scope.localContext applied).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext resultType entry.type then
    throw .unsupportedRuntimeTerm
  let .lam callbackName callbackType body .explicit :=
      psWhnf environment psMetaEmpty scope.localContext (.app functional major)
    | throw .unsupportedRuntimeTerm
  if let some (packing, firstId, secondId) := packing then
    return some (← psEraseWellFoundedPairBody environment scope eraseAt entry
      packing firstId secondId callbackName callbackType body applicationArguments)
  let [majorId] := majorIds | throw .unsupportedRuntimeTerm
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
