import Ps.Elab.DoWhile

-- A handler is not tail-resumptive: the following statements must run outside
-- its catch. Pack successful fallthrough and early return inside the base effect
-- using existing checked Except/Prod data. Packet.error is an EARLY RETURN;
-- only an error of the outer base effect is a caught source error.
def PsElabDoReturn : Type :=
  PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult

def PsElabDoTryNext : Type :=
  PsExpr -> PsElabDoReturn -> PsElabDoForNext

-- A terminal arm which never invokes its fallthrough continuation does not
-- require a state packet. Return callbacks are exclusively base pure/packet
-- constructors, never source continuations. This avoids inventing a value for
-- an unreachable fallthrough branch in a non-Unit terminal computation.
def psElabDoNoFallthrough : PsSyntaxTerm -> Bool
  | .doEndE _ => false
  | .doReturnE _ _ => true
  | .letE _ _ _ rest _ | .letPatternE _ _ _ rest _ | .doLetMutE _ _ _ rest _
  | .doAssignE _ _ rest _ | .doBindE _ _ _ rest _
  | .doThenE _ rest _ => psElabDoNoFallthrough rest
  | .doIfE _ yes no rest _ =>
      psElabDoNoFallthrough rest ||
        (psElabDoNoFallthrough yes && psElabDoNoFallthrough no)
  | .doTryE body _ handler rest _ =>
      psElabDoNoFallthrough rest ||
        (psElabDoNoFallthrough body && psElabDoNoFallthrough handler)
  | .doForE _ _ _ rest _ | .doForRangeE _ _ _ _ rest _
  | .doWhileE _ _ rest _ => psElabDoNoFallthrough rest
  | _ => true

def psElabDoExceptCases
    (context : PsElabContext) (error value result scrutinee onError onOk : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let inputType := psSelfHostExceptOf error value
  let resultSort <- (psInferType context.environment context.metaContext
    context.localContext result).mapError PsElabError.infer
  let level <- (psInferEnsureSort context.environment context.metaContext
    context.localContext resultSort).mapError PsElabError.infer
  let motive := PsExpr.lam (psRootName "_") inputType
    (psExprLiftBVars 1 0 result) PsBinderInfo.explicit
  psElabResolvedTerm context
    (psExprApplyMany (PsExpr.constE psSelfHostExceptRecName [level])
      [error, value, motive, onError, onOk, scrutinee]) (some result)

def psElabDoCatch
    (ops : PsElabDoOps) (context : PsElabContext)
    (type action handler : PsExpr) : Except PsElabError PsElabTermResult := do
  match ops with
  | .identity _ => throw PsElabError.doUnsupportedEffect
  | .except error =>
      let okBranch <- psElabDoForLambda
        (fun current id => psElabDoPure ops current type (PsExpr.fvar id))
        context (psElabDoInternalName "_psc1CatchOk" context) type
      let current := psElabContextWithMeta context okBranch.context.metaContext
      psElabDoExceptCases current error type (psElabDoType ops type)
        action handler okBranch.term
  | .compiler reader state error =>
      -- Existing checked library operation; failure resets its effect state.
      psElabResolvedTerm context
        (psExprApplyMany (PsExpr.constE (psRootName "compilerTryCatch") [])
          [reader, state, error, type, action, handler])
        (some (psElabDoType ops type))

-- A terminal effect expression retains its original source result type. Only
-- its successful value is then forwarded through the enclosing return context.
def psElabDoLiftTerminal
    (elaborate : PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (returnType result : PsExpr)
    (onReturn : PsElabDoReturn) (context : PsElabContext) (body : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult := do
  let action <- psElabDoEffectTerm elaborate ops context returnType body
  let continuation <- psElabDoForLambda
    (fun current id => onReturn current (PsExpr.fvar id))
    action.context (psElabDoInternalName "_psc1TryValue" action.context)
    (psMetaInstantiate action.context.metaContext returnType)
  let current := psElabContextWithMeta context continuation.context.metaContext
  psElabDoBind ops current
    (psMetaInstantiate current.metaContext returnType)
    (psMetaInstantiate current.metaContext result)
    (psMetaInstantiate current.metaContext action.term) continuation.term

def psElabDoTry
    (inside : PsElabDoTryNext) (next : PsElabDoForNext)
    (ops : PsElabDoOps) (returnType result : PsExpr) (onReturn : PsElabDoReturn)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (body : PsSyntaxTerm) (errorName : PsSyntaxName)
    (handler rest : PsSyntaxTerm) (finish : PsElabDoForFinish) :
    Except PsElabError PsElabTermResult := do
  let errorType <- psElabDoErrorType ops
  let some name := psSyntaxNameToName errorName | throw PsElabError.emptyName
  if psElabDoMutableHasName name state then
    throw (PsElabError.doMutableShadowing name)
  let terminal := match rest with | .doEndE _ => true | _ => false
  if terminal && psElabDoNoFallthrough body && psElabDoNoFallthrough handler then
    let action <- inside result onReturn context state body finish
    let current := psElabContextWithMeta context action.context.metaContext
    let recovery <- psElabDoForLambda
      (fun recoveryContext _ =>
        inside result onReturn recoveryContext state handler finish)
      current name (psMetaInstantiate current.metaContext errorType)
    let current := psElabContextWithMeta context recovery.context.metaContext
    return <- psElabDoCatch ops current
      (psMetaInstantiate current.metaContext result)
      (psMetaInstantiate current.metaContext action.term) recovery.term
  let carried := psElabDoMutableVisible context state
  let stateType := psElabDoWhileStateType context carried
  let packetType := psSelfHostExceptOf returnType stateType
  let returnPacket : PsElabDoReturn := fun current value =>
    psElabDoPure ops current
      (psMetaInstantiate current.metaContext packetType)
      (psSelfHostExceptErrorOf
        (psMetaInstantiate current.metaContext returnType)
        (psMetaInstantiate current.metaContext stateType) value)
  let finishPacket : PsElabDoForFinish := fun current currentState => do
    let packed <- psElabDoWhileStateValue current currentState carried
    psElabDoPure ops current
      (psMetaInstantiate current.metaContext packetType)
      (psSelfHostExceptOkOf
        (psMetaInstantiate current.metaContext returnType)
        (psMetaInstantiate current.metaContext stateType) packed)
  let action <- inside packetType returnPacket context state body finishPacket
  -- Both arms start from the pre-try lexical values. Only successful
  -- fallthrough carries changed values beyond the handler boundary.
  let current := psElabContextWithMeta context action.context.metaContext
  let recovery <- psElabDoForLambda
    (fun recoveryContext _ =>
      inside packetType returnPacket recoveryContext state handler finishPacket)
    current name (psMetaInstantiate current.metaContext errorType)
  let current := psElabContextWithMeta context recovery.context.metaContext
  let caught <- psElabDoCatch ops current
    (psMetaInstantiate current.metaContext packetType)
    (psMetaInstantiate current.metaContext action.term) recovery.term
  let continuation <- psElabDoForLambda
    (fun packetContext packetId => do
      let returnBranch <- psElabDoForLambda
        (fun returnContext valueId => onReturn returnContext (PsExpr.fvar valueId))
        packetContext (psElabDoInternalName "_psc1TryReturn" packetContext)
        (psMetaInstantiate packetContext.metaContext returnType)
      let current := psElabContextWithMeta packetContext returnBranch.context.metaContext
      let stateBranch <- psElabDoForLambda
        (fun stateContext stateId =>
          psElabDoWhileOpenState
            (fun restored restoredState => next restored restoredState rest finish)
            ops result carried stateContext state (PsExpr.fvar stateId))
        current (psElabDoInternalName "_psc1TryState" current)
        (psMetaInstantiate current.metaContext stateType)
      let current := psElabContextWithMeta packetContext stateBranch.context.metaContext
      psElabDoExceptCases current
        (psMetaInstantiate current.metaContext returnType)
        (psMetaInstantiate current.metaContext stateType)
        (psElabDoType ops (psMetaInstantiate current.metaContext result))
        (PsExpr.fvar packetId) returnBranch.term stateBranch.term)
    caught.context (psElabDoInternalName "_psc1TryPacket" caught.context)
    (psMetaInstantiate caught.context.metaContext packetType)
  let current := psElabContextWithMeta context continuation.context.metaContext
  psElabDoBind ops current
    (psMetaInstantiate current.metaContext packetType)
    (psMetaInstantiate current.metaContext result)
    (psMetaInstantiate current.metaContext caught.term) continuation.term
