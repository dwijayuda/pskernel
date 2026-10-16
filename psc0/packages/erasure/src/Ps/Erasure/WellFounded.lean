import Ps.Erasure.Recursion

/-
Runtime equation for the selected, already checked Nat-measure fixpoint.
Pinned Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Init/WF.lean:494-517 gives WellFounded.Nat.fix and its checked fix_eq;
Lean/Elab/PreDefinition/WF/Fix.lean:289-319 selects this construction.

The root expression and its full typed callback are authoritative. A source
strategy flag, assumed recursive equation, or P0 body marker is insufficient.
The callback accepts a smaller argument AND a checked decrease proof. Erasing
that proof leaves exactly the recursive self application given by fix_eq.
-/

def psErasureWellFoundedFixName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix"

def psErasureWellFoundedIsNat (environment : PsEnvironment)
    (scope : PsErasureScope) (type : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
    type (.constE psNatName [])

def psEraseWellFoundedApplication (environment : PsEnvironment)
    (scope : PsErasureScope)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  if !psNameEq name psErasureWellFoundedFixName then return none
  let [domain, motive, measure, functional, major] := view.args
    | throw .unsupportedApplication
  let some current := scope.currentDefinition | throw .unsupportedRuntimeTerm
  let [runtimeName] := current.runtimeParameters | throw .unsupportedRuntimeTerm
  if !current.typeArgumentsRev.isEmpty then throw .unsupportedRuntimeTerm
  -- Exactly one actual entry binder excludes fixed proof/type parameters and
  -- indirect dependencies on the old major through another captured local.
  let [.binding localId _ localType .explicit] := scope.localContext.declarations
    | throw .unsupportedRuntimeTerm
  let .fvar majorId := major | throw .unsupportedRuntimeTerm
  if majorId != localId ||
      psErasureLookupNat scope.runtimeLocals majorId != some runtimeName then
    throw .unsupportedRuntimeTerm
  if !psErasureWellFoundedIsNat environment scope domain ||
      !psErasureWellFoundedIsNat environment scope localType ||
      !psErasureWellFoundedIsNat environment scope (.app motive major) then
    throw .unsupportedRuntimeTerm
  -- F, its measure and motive must be unchanged by a recursive self call.
  -- Only F's bound argument varies. This is the same captured-local boundary
  -- enforced by the existing root structural recursor lowering.
  if [domain, motive, measure, functional].any (fun term =>
      (psExprFVarIds term).contains majorId) then
    throw .unsupportedRuntimeTerm
  let applied := view.args.foldl PsExpr.app view.head
  let resultType ← (psInferType environment psMetaEmpty scope.localContext applied)
    .mapError (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psErasureWellFoundedIsNat environment scope resultType then
    throw .unsupportedRuntimeTerm
  let .lam callbackName callbackType body .explicit :=
      psWhnf environment psMetaEmpty scope.localContext (.app functional major)
    | throw .unsupportedRuntimeTerm
  -- Check the runtime callback representation using its real Core telescope.
  -- Its proof payload is erased but the ordinary Unit application slot stays.
  let argument ← (psInferEnsureForall environment psMetaEmpty
    scope.localContext callbackType).mapError (fun _ => PsErasureError.binderMismatch)
  if !psErasureWellFoundedIsNat environment scope argument.domain then
    throw .unsupportedRuntimeTerm
  let probe := psLocalPushBinding scope.localContext argument.name argument.domain argument.binder
  let probeScope := { scope with localContext := probe.context }
  let proof ← (psInferEnsureForall environment psMetaEmpty probe.context
    (psExprInstantiate1 argument.body (.fvar probe.id)))
    .mapError (fun _ => PsErasureError.binderMismatch)
  let proofKind := psErasureClassifyBinder environment probe.context proof.domain
  let .proof := proofKind | throw .unsupportedRuntimeTerm
  if !psErasureWellFoundedIsNat environment probeScope proof.body then
    throw .unsupportedRuntimeTerm
  let argumentName := psErasureLocalName scope "_psWFArg" "_psWFArg" probe.id
  if psErasureLocalNameUsed scope argumentName then throw .fuelExhausted
  let reserved := psErasureReserveOutputName scope argumentName
  let proofName := psErasureLocalName reserved "_psWFProof" "_psWFProof" (probe.id + 1)
  if psErasureLocalNameUsed reserved proofName then throw .fuelExhausted
  let reserved := psErasureReserveOutputName reserved proofName
  let natType := PsVerifiedIrType.primitive .nat
  -- Supplying the smaller argument alone must not execute recursion before
  -- the proof slot is supplied. This is the existing canonical function ABI.
  let recursiveValue := PsVerifiedIrExpr.lambda
    [PsVerifiedIrParameter.mk argumentName natType]
    (.function [psErasureProofSlotType] natType)
    (.lambda [PsVerifiedIrParameter.mk proofName psErasureProofSlotType] natType
      (.call (.var current.name) [] [.var argumentName]))
  let callback := psLocalPushBinding scope.localContext callbackName callbackType .explicit
  let bodyScope := { reserved with
    localContext := callback.context
    erasedLocals := callback.id :: scope.erasedLocals
    runtimeExpressions := (callback.id, recursiveValue) :: scope.runtimeExpressions
    currentDefinition := none }
  let lowered ← eraseAt bodyScope (psExprInstantiate1 body (.fvar callback.id))
  return some lowered
