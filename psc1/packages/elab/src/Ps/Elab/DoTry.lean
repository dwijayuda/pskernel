import Ps.Elab.DoWhile

-- Packet.error is early return; only the outer base effect is a source error.
def PsElabDoReturn : Type :=
  PsElabContext -> PsExpr -> Except PsElabError PsElabTermResult

def PsElabDoTryNext : Type :=
  PsExpr -> PsElabDoReturn -> PsElabDoForNext

def psElabDoNoFallthrough (term : PsSyntaxTerm) : Bool :=
  match term with
  | PsSyntaxTerm.doEndE _ => false
  | PsSyntaxTerm.doReturnE _ _ => true
  | PsSyntaxTerm.letE _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.letPatternE _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doLetMutE _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doAssignE _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doBindE _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doThenE _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doIfE _ yes no rest _ =>
      psElabDoNoFallthrough rest ||
        (psElabDoNoFallthrough yes && psElabDoNoFallthrough no)
  | PsSyntaxTerm.doTryE body _ handler rest _ =>
      psElabDoNoFallthrough rest ||
        (psElabDoNoFallthrough body && psElabDoNoFallthrough handler)
  | PsSyntaxTerm.doForE _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doForRangeE _ _ _ _ rest _ => psElabDoNoFallthrough rest
  | PsSyntaxTerm.doWhileE _ _ rest _ => psElabDoNoFallthrough rest
  | _ => true

def psElabDoExceptCases
    (context : PsElabContext) (error value result scrutinee onError onOk : PsExpr) :
    Except PsElabError PsElabTermResult :=
  let inputType := psSelfHostExceptOf error value;
  match psInferType context.environment context.metaContext context.localContext result with
  | Except.error error => Except.error (PsElabError.infer error)
  | Except.ok resultSort =>
      match psInferEnsureSort context.environment context.metaContext context.localContext resultSort with
      | Except.error error => Except.error (PsElabError.infer error)
      | Except.ok level =>
          let motive := PsExpr.lam (psRootName "_") inputType
            (psExprLiftBVars 1 0 result) PsBinderInfo.explicit;
          psElabResolvedTerm context
            (psExprApplyMany (PsExpr.constE psSelfHostExceptRecName [level])
              [error, value, motive, onError, onOk, scrutinee]) (Option.some result)

def psElabDoCatch
    (ops : PsElabDoOps) (context : PsElabContext)
    (type action handler : PsExpr) : Except PsElabError PsElabTermResult :=
  match ops with
  | PsElabDoOps.identity _ => Except.error PsElabError.doUnsupportedEffect
  | PsElabDoOps.except error =>
      match psElabDoForLambda
          (fun (current : PsElabContext) (id : Nat) =>
            psElabDoPure ops current type (PsExpr.fvar id))
          context (psElabDoInternalName "_psc1CatchOk" context) type with
      | Except.error error => Except.error error
      | Except.ok okBranch =>
          let current := psElabContextWithMeta context okBranch.context.metaContext;
          psElabDoExceptCases current error type (psElabDoType ops type)
            action handler okBranch.term
  | PsElabDoOps.compiler reader state error =>
      psElabResolvedTerm context
        (psExprApplyMany (PsExpr.constE (psRootName "compilerTryCatch") [])
          [reader, state, error, type, action, handler])
        (Option.some (psElabDoType ops type))

def psElabDoLiftTerminal
    (elaborate : PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (returnType result : PsExpr)
    (onReturn : PsElabDoReturn) (context : PsElabContext) (body : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult :=
  match psElabDoEffectTerm elaborate ops context returnType body with
  | Except.error error => Except.error error
  | Except.ok action =>
      match psElabDoForLambda
          (fun (current : PsElabContext) (id : Nat) => onReturn current (PsExpr.fvar id))
          action.context (psElabDoInternalName "_psc1TryValue" action.context)
          (psMetaInstantiate action.context.metaContext returnType) with
      | Except.error error => Except.error error
      | Except.ok continuation =>
          let current := psElabContextWithMeta context continuation.context.metaContext;
          psElabDoBind ops current
            (psMetaInstantiate current.metaContext returnType)
            (psMetaInstantiate current.metaContext result)
            (psMetaInstantiate current.metaContext action.term) continuation.term

def psElabDoTryPacket
    (inside : PsElabDoTryNext) (next : PsElabDoForNext)
    (ops : PsElabDoOps) (returnType result : PsExpr) (onReturn : PsElabDoReturn)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (body : PsSyntaxTerm) (name : PsName) (errorType : PsExpr)
    (handler rest : PsSyntaxTerm) (finish : PsElabDoForFinish) :
    Except PsElabError PsElabTermResult :=
  let carried := psElabDoMutableVisible context state;
  let stateType := psElabDoWhileStateType context carried;
  let packetType := psSelfHostExceptOf returnType stateType;
  let returnPacket : PsElabDoReturn :=
    fun (current : PsElabContext) (value : PsExpr) =>
      psElabDoPure ops current
        (psMetaInstantiate current.metaContext packetType)
        (psSelfHostExceptErrorOf
          (psMetaInstantiate current.metaContext returnType)
          (psMetaInstantiate current.metaContext stateType) value);
  let finishPacket : PsElabDoForFinish :=
    fun (current : PsElabContext) (currentState : List PsElabDoMutable) =>
      match psElabDoWhileStateValue current currentState carried with
      | Except.error error => Except.error error
      | Except.ok packed =>
          psElabDoPure ops current
            (psMetaInstantiate current.metaContext packetType)
            (psSelfHostExceptOkOf
              (psMetaInstantiate current.metaContext returnType)
              (psMetaInstantiate current.metaContext stateType) packed);
  match inside packetType returnPacket context state body finishPacket with
  | Except.error error => Except.error error
  | Except.ok action =>
      -- Recovery starts from the pre-try lexical values.
      let current := psElabContextWithMeta context action.context.metaContext;
      match psElabDoForLambda
          (fun (recoveryContext : PsElabContext) (id : Nat) =>
            inside packetType returnPacket recoveryContext state handler finishPacket)
          current name (psMetaInstantiate current.metaContext errorType) with
      | Except.error error => Except.error error
      | Except.ok recovery =>
          let current := psElabContextWithMeta context recovery.context.metaContext;
          match psElabDoCatch ops current
              (psMetaInstantiate current.metaContext packetType)
              (psMetaInstantiate current.metaContext action.term) recovery.term with
          | Except.error error => Except.error error
          | Except.ok caught =>
              match psElabDoForLambda
                  (fun (packetContext : PsElabContext) (packetId : Nat) =>
                    match psElabDoForLambda
                        (fun (returnContext : PsElabContext) (valueId : Nat) =>
                          onReturn returnContext (PsExpr.fvar valueId))
                        packetContext (psElabDoInternalName "_psc1TryReturn" packetContext)
                        (psMetaInstantiate packetContext.metaContext returnType) with
                    | Except.error error => Except.error error
                    | Except.ok returnBranch =>
                        let current := psElabContextWithMeta packetContext returnBranch.context.metaContext;
                        match psElabDoForLambda
                            (fun (stateContext : PsElabContext) (stateId : Nat) =>
                              psElabDoWhileOpenState
                                (fun (restored : PsElabContext) (restoredState : List PsElabDoMutable) =>
                                  next restored restoredState rest finish)
                                ops result carried stateContext state (PsExpr.fvar stateId))
                            current (psElabDoInternalName "_psc1TryState" current)
                            (psMetaInstantiate current.metaContext stateType) with
                        | Except.error error => Except.error error
                        | Except.ok stateBranch =>
                            let current := psElabContextWithMeta packetContext stateBranch.context.metaContext;
                            psElabDoExceptCases current
                              (psMetaInstantiate current.metaContext returnType)
                              (psMetaInstantiate current.metaContext stateType)
                              (psElabDoType ops (psMetaInstantiate current.metaContext result))
                              (PsExpr.fvar packetId) returnBranch.term stateBranch.term)
                  caught.context (psElabDoInternalName "_psc1TryPacket" caught.context)
                  (psMetaInstantiate caught.context.metaContext packetType) with
              | Except.error error => Except.error error
              | Except.ok continuation =>
                  let current := psElabContextWithMeta context continuation.context.metaContext;
                  psElabDoBind ops current
                    (psMetaInstantiate current.metaContext packetType)
                    (psMetaInstantiate current.metaContext result)
                    (psMetaInstantiate current.metaContext caught.term) continuation.term

def psElabDoTry
    (inside : PsElabDoTryNext) (next : PsElabDoForNext)
    (ops : PsElabDoOps) (returnType result : PsExpr) (onReturn : PsElabDoReturn)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (body : PsSyntaxTerm) (errorName : PsSyntaxName)
    (handler rest : PsSyntaxTerm) (finish : PsElabDoForFinish) :
    Except PsElabError PsElabTermResult :=
  match psElabDoErrorType ops with
  | Except.error error => Except.error error
  | Except.ok errorType =>
      match psSyntaxNameToName errorName with
      | Option.none => Except.error PsElabError.emptyName
      | Option.some name =>
          if psElabDoMutableHasName name state then
            Except.error (PsElabError.doMutableShadowing name)
          else
            let terminal : Bool :=
              match rest with
              | PsSyntaxTerm.doEndE _ => true
              | _ => false;
            if terminal && psElabDoNoFallthrough body && psElabDoNoFallthrough handler then
              match inside result onReturn context state body finish with
              | Except.error error => Except.error error
              | Except.ok action =>
                  let current := psElabContextWithMeta context action.context.metaContext;
                  match psElabDoForLambda
                      (fun (recoveryContext : PsElabContext) (id : Nat) =>
                        inside result onReturn recoveryContext state handler finish)
                      current name (psMetaInstantiate current.metaContext errorType) with
                  | Except.error error => Except.error error
                  | Except.ok recovery =>
                      let current := psElabContextWithMeta context recovery.context.metaContext;
                      psElabDoCatch ops current
                        (psMetaInstantiate current.metaContext result)
                        (psMetaInstantiate current.metaContext action.term) recovery.term
            else
              psElabDoTryPacket inside next ops returnType result onReturn context state
                body name errorType handler rest finish
