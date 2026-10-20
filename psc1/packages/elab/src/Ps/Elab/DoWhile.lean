import Ps.Elab.DoFor
import Ps.Elab.DoLoop

-- Recurrence remains in a private helper's direct tail position.
def psElabDoWhileNestedLoop (term : PsSyntaxTerm) : Bool :=
  match term with
  | PsSyntaxTerm.doForE _ _ _ _ _ => true
  | PsSyntaxTerm.doForRangeE _ _ _ _ _ _ => true
  | PsSyntaxTerm.doWhileE _ _ _ _ => true
  | PsSyntaxTerm.letE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.letPatternE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doLetMutE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doAssignE _ _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doBindE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doThenE _ rest _ => psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doTryE action _ recovery rest _ =>
      psElabDoWhileNestedLoop action || psElabDoWhileNestedLoop recovery ||
        psElabDoWhileNestedLoop rest
  | PsSyntaxTerm.doIfE _ yes no rest _ =>
      psElabDoWhileNestedLoop yes || psElabDoWhileNestedLoop no ||
        psElabDoWhileNestedLoop rest
  | _ => false

def psElabDoWhileStateType
    (context : PsElabContext) (carried : List PsElabDoMutable) : PsExpr :=
  match carried with
  | List.nil => PsExpr.constE psUnitName []
  | List.cons entry rest =>
      psExprApplyMany (PsExpr.constE psProdName [])
        [psMetaInstantiate context.metaContext entry.type,
          psElabDoWhileStateType context rest]

def psElabDoWhileStateValue
    (context : PsElabContext) (state : List PsElabDoMutable)
    (carried : List PsElabDoMutable) : Except PsElabError PsExpr :=
  match carried with
  | List.nil => Except.ok (PsExpr.constE psUnitUnitName [])
  | List.cons entry rest =>
      match psElabDoMutableFindBinding entry.bindingId state with
      | Option.none => Except.error PsElabError.unsupportedTerm
      | Option.some current =>
          match psElabDoWhileStateValue context state rest with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (psExprApplyMany (PsExpr.constE psProdMkName [])
                [psMetaInstantiate context.metaContext entry.type,
                  psElabDoWhileStateType context rest, PsExpr.fvar current.currentId, tail])

def psElabDoWhileOpenStateWorker
    (finish : PsElabDoForFinish) (ops : PsElabDoOps) (result : PsExpr)
    (carried : List PsElabDoMutable) :
    PsElabContext -> List PsElabDoMutable -> PsExpr ->
    Except PsElabError PsElabTermResult :=
  match carried with
  | List.nil =>
      fun (context : PsElabContext) (state : List PsElabDoMutable) (packed : PsExpr) =>
        finish context state
  | List.cons entry rest =>
      fun (context : PsElabContext) (state : List PsElabDoMutable) (packed : PsExpr) =>
        let smaller : PsElabContext -> List PsElabDoMutable -> PsExpr ->
            Except PsElabError PsElabTermResult :=
          psElabDoWhileOpenStateWorker finish ops result rest;
        let type := psMetaInstantiate context.metaContext entry.type;
        match psElabResolvedTerm context (PsExpr.proj psProdName 0 packed) (Option.some type) with
        | Except.error error => Except.error error
        | Except.ok value =>
            psElabDoWithLocal
              (fun (current : PsElabContext) (id : Nat) =>
                smaller current (psElabDoMutableUpdate entry.bindingId id state)
                  (PsExpr.proj psProdName 1 packed))
              context entry.userName type value (Option.some (psElabDoType ops result))

def psElabDoWhileOpenState
    (finish : PsElabDoForFinish) (ops : PsElabDoOps) (result : PsExpr)
    (carried : List PsElabDoMutable) (context : PsElabContext)
    (state : List PsElabDoMutable) (packed : PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabDoWhileOpenStateWorker finish ops result carried context state packed

def psElabDoWhileStep
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (condition body : PsSyntaxTerm) (restId recursiveId : Nat) :
    Except PsElabError PsElabTermResult :=
  let boolType := PsExpr.constE psBoolName [];
  match elaborate context condition (Option.some boolType) with
  | Except.error error => Except.error error
  | Except.ok conditionValue =>
      psElabDoWithLocal
        (fun (conditionContext : PsElabContext) (conditionId : Nat) =>
          match next conditionContext state body
              (fun (current : PsElabContext) (currentState : List PsElabDoMutable) =>
                match psElabDoWhileStateValue current currentState carried with
                | Except.error error => Except.error error
                | Except.ok packed =>
                    psElabResolvedTerm current
                      (psExprApplyMany (PsExpr.fvar recursiveId)
                        [packed, PsExpr.constE psUnitUnitName []])
                      (Option.some (psElabDoType ops result))) with
          | Except.error error => Except.error error
          | Except.ok yes =>
              let noContext := psElabContextWithMeta conditionContext yes.context.metaContext;
              match psElabDoJoinCall ops result restId carried noContext state with
              | Except.error error => Except.error error
              | Except.ok no =>
                  psElabDoCoreIf ops result no.context
                    (PsExpr.fvar conditionId) yes.term no.term)
        context (psElabDoInternalName "_psc1WhileCondition" context)
        boolType conditionValue (Option.some (psElabDoType ops result))

-- Preserve the selected primitive/inductive result profile.
def psElabDoWhileResultAllowed (context : PsElabContext) (resultType : PsExpr) : Bool :=
  let reduced := psWhnf context.environment context.metaContext context.localContext resultType;
  let view := psExprAppView reduced;
  match view.head with
  | PsExpr.constE name _ =>
      if psNameEq name psBoolName || psNameEq name psUnitName ||
          psNameEq name psNatName || psNameEq name psIntName ||
          psNameEq name psStringName || psNameEq name psCharName then true
      else
        match psEnvironmentFind context.environment name with
        | Option.none => false
        | Option.some declaration =>
            match declaration with
            | PsDeclaration.inductiveDecl _ => true
            | _ => false
  | _ => false

def psElabDoWhile
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (condition body rest : PsSyntaxTerm) (finish : PsElabDoForFinish) :
    Except PsElabError PsElabTermResult :=
  match context.whileHelper with
  | Option.none => Except.error PsElabError.doWhileNeedsPartial
  | Option.some helperName =>
      let supportedEffect : Bool :=
        match ops with
        | PsElabDoOps.compiler _ _ _ => false
        | _ => true;
      if supportedEffect then
        if psElabDoWhileNestedLoop body then Except.error PsElabError.doWhileUnsupportedBody
        else
          let resultType := psElabDoType ops result;
          if psElabDoWhileResultAllowed context resultType then
            let carried := psElabDoMutableVisible context state;
            match psElabDoJoin
                (fun (current : PsElabContext) (currentState : List PsElabDoMutable) =>
                  next current currentState rest finish)
                carried context state with
            | Except.error error => Except.error error
            | Except.ok continuation =>
                psElabDoWithLocal
                  (fun (loopContext : PsElabContext) (restId : Nat) =>
                    let unitType := PsExpr.constE psUnitName [];
                    let stateType := psElabDoWhileStateType loopContext carried;
                    let thunkType := psElabDoLoopArrow unitType resultType;
                    let recursiveType := psElabDoLoopArrow stateType thunkType;
                    match psElabDoForLambda
                        (fun (current : PsElabContext) (id : Nat) =>
                          psElabDoJoinCall ops result restId carried current state)
                        loopContext (psElabDoInternalName "_psc1WhileFallback" loopContext) unitType with
                    | Except.error error => Except.error error
                    | Except.ok fallback =>
                        let current := psElabContextWithMeta loopContext fallback.context.metaContext;
                        match psElabDoForLambda
                            (fun (recursiveContext : PsElabContext) (recursiveId : Nat) =>
                              psElabDoForLambda
                                (fun (stateContext : PsElabContext) (stateId : Nat) =>
                                  psElabDoForLambda
                                    (fun (thunkContext : PsElabContext) (id : Nat) =>
                                      psElabDoWhileOpenState
                                        (fun (bodyContext : PsElabContext) (bodyState : List PsElabDoMutable) =>
                                          psElabDoWhileStep elaborate next ops result bodyContext
                                            bodyState carried condition body restId recursiveId)
                                        ops result carried thunkContext state (PsExpr.fvar stateId))
                                    stateContext (psElabDoInternalName "_psc1WhileUnit" stateContext) unitType)
                                recursiveContext (psElabDoInternalName "_psc1WhileState" recursiveContext) stateType)
                            current (psElabDoInternalName "_psc1WhileNext" current) recursiveType with
                        | Except.error error => Except.error error
                        | Except.ok step =>
                            let current := psElabContextWithMeta current step.context.metaContext;
                            match psElabDoWhileStateValue current state carried with
                            | Except.error error => Except.error error
                            | Except.ok initial =>
                                psElabResolvedTerm current
                                  (psExprApplyMany (PsExpr.constE helperName [])
                                    [stateType, resultType, fallback.term, step.term, initial,
                                      PsExpr.constE psUnitUnitName []])
                                  (Option.some resultType))
                  context (psElabDoInternalName "_psc1WhileRest" context)
                  continuation.type continuation (Option.some resultType)
          else Except.error PsElabError.doWhileUnsupportedBody
      else Except.error PsElabError.doWhileUnsupportedBody
