import Ps.Elab.DoTry
import Ps.Elab.Data

def psElabDoPatternMutableConflict
    (state : List PsElabDoMutable) (sources : List PsSyntaxName) : Option PsName :=
  match sources with
  | List.nil => Option.none
  | List.cons source rest =>
      match psSyntaxNameToName source with
      | Option.none => psElabDoPatternMutableConflict state rest
      | Option.some name =>
          if psElabDoMutableHasName name state then Option.some name
          else psElabDoPatternMutableConflict state rest

def psElabDoBodyWithExitWorker
    (fuel : Nat)
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (returnType : PsExpr) :
    PsExpr -> PsElabDoReturn -> Bool -> PsElabDoForNext :=
  match fuel with
  | 0 =>
      fun (result : PsExpr) (onReturn : PsElabDoReturn) (liftTerminal : Bool)
          (context : PsElabContext) (state : List PsElabDoMutable) (body : PsSyntaxTerm)
          (finish : PsElabDoForFinish) => Except.error PsElabError.fuelExhausted
  | remaining + 1 =>
      fun (result : PsExpr) (onReturn : PsElabDoReturn) (liftTerminal : Bool)
          (context : PsElabContext) (state : List PsElabDoMutable) (body : PsSyntaxTerm)
          (finish : PsElabDoForFinish) =>
        let smallerWorker : PsExpr -> PsElabDoReturn -> Bool -> PsElabDoForNext :=
          psElabDoBodyWithExitWorker remaining elaborate ops returnType;
        let smaller : PsElabDoForNext := smallerWorker result onReturn liftTerminal;
        let expected : Option PsExpr := Option.some (psElabDoType ops result);
        match body with
        | PsSyntaxTerm.doEndE _ => finish context state
        | PsSyntaxTerm.doReturnE value _ =>
            match elaborate context value (Option.some returnType) with
            | Except.error error => Except.error error
            | Except.ok valueResult =>
                onReturn valueResult.context valueResult.term
        | PsSyntaxTerm.letPatternE pattern annotation value rest _ =>
            match psElabDoPatternMutableConflict state (psSyntaxBindingPatternNames pattern) with
            | Option.some name => Except.error (PsElabError.doMutableShadowing name)
            | Option.none =>
                psElabLetPattern elaborate context pattern annotation value
                  (fun (bodyContext : PsElabContext) => smaller bodyContext state rest finish) expected
        | PsSyntaxTerm.letE sourceName annotation value rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                if psElabDoMutableHasName name state then
                  Except.error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoLocalValue elaborate context annotation value with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      psElabDoWithLocal
                        (fun (bodyContext : PsElabContext) (id : Nat) => smaller bodyContext state rest finish)
                        context name valueResult.type valueResult expected
        | PsSyntaxTerm.doLetMutE sourceName annotation value rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                if psElabDoMutableHasName name state then
                  Except.error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoLocalValue elaborate context annotation value with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      let type := psMetaInstantiate valueResult.context.metaContext valueResult.type;
                      psElabDoWithLocal
                        (fun (bodyContext : PsElabContext) (id : Nat) =>
                          smaller bodyContext
                            (List.cons (PsElabDoMutable.mk id id name type) state) rest finish)
                        context name type valueResult expected
        | PsSyntaxTerm.doAssignE sourceName value rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                match psLocalFindUser context.localContext name with
                | Option.none => Except.error (PsElabError.unknownName name)
                | Option.some declaration =>
                    match psElabDoMutableFindCurrent (psLocalDeclId declaration) state with
                    | Option.none => Except.error (PsElabError.doImmutableAssignment name)
                    | Option.some entry =>
                        let type := psMetaInstantiate context.metaContext entry.type;
                        match elaborate context value (Option.some type) with
                        | Except.error error => Except.error error
                        | Except.ok valueResult =>
                            psElabDoWithLocal
                              (fun (bodyContext : PsElabContext) (id : Nat) =>
                                smaller bodyContext
                                  (psElabDoMutableUpdate entry.bindingId id state) rest finish)
                              context name type valueResult expected
        | PsSyntaxTerm.doBindE sourceName annotation action rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                if psElabDoMutableHasName name state then
                  Except.error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoAction elaborate ops context annotation action with
                  | Except.error error => Except.error error
                  | Except.ok actionResult =>
                      psElabDoContinue
                        (fun (bodyContext : PsElabContext) (nextBody : PsSyntaxTerm) (expectedBody : Option PsExpr) => smaller bodyContext state nextBody finish)
                        ops context result name actionResult.fst actionResult.snd rest
        | PsSyntaxTerm.doThenE action rest _ =>
            let unitType := PsExpr.constE psUnitName [];
            match psElabDoEffectTerm elaborate ops context unitType action with
            | Except.error error => Except.error error
            | Except.ok actionResult =>
                psElabDoContinue
                  (fun (bodyContext : PsElabContext) (nextBody : PsSyntaxTerm) (expectedBody : Option PsExpr) => smaller bodyContext state nextBody finish)
                  ops context result (psRootName "_") actionResult unitType rest
        | PsSyntaxTerm.doIfE condition thenBranch elseBranch rest _ =>
            let boolType := PsExpr.constE psBoolName [];
            match elaborate context condition (Option.some boolType) with
            | Except.error error => Except.error error
            | Except.ok conditionResult =>
                let conditionName := psElabDoInternalName "_psc1DoCondition" context;
                psElabDoWithLocal
                  (fun (conditionContext : PsElabContext) (conditionId : Nat) =>
                    let conditionValue := PsExpr.fvar conditionId;
                    match rest with
                    | PsSyntaxTerm.doEndE _ =>
                        psElabDoBranches
                          (fun (branchContext : PsElabContext) (branch : PsSyntaxTerm) =>
                            smaller branchContext state branch finish)
                          ops result conditionContext conditionValue thenBranch elseBranch
                    | _ =>
                        let carried := psElabDoMutableVisible conditionContext state;
                        match psElabDoJoin
                            (fun (joinContext : PsElabContext) (joinState : List PsElabDoMutable) =>
                              smaller joinContext joinState rest finish)
                            carried conditionContext state with
                        | Except.error error => Except.error error
                        | Except.ok joinResult =>
                            let joinName := psElabDoInternalName "_psc1DoJoin" conditionContext;
                            psElabDoWithLocal
                              (fun (branchContext : PsElabContext) (joinId : Nat) =>
                                let next : PsElabDoForFinish :=
                                  psElabDoJoinCall ops result joinId carried;
                                psElabDoBranches
                                  (fun (current : PsElabContext) (branch : PsSyntaxTerm) =>
                                    smaller current state branch next)
                                  ops result branchContext conditionValue thenBranch elseBranch)
                              conditionContext joinName joinResult.type joinResult expected)
                  context conditionName boolType conditionResult expected
        | PsSyntaxTerm.doForE name collection loopBody rest _ =>
            psElabDoFor elaborate smaller ops result context state name collection loopBody rest finish
        | PsSyntaxTerm.doForRangeE name lower upper loopBody rest _ =>
            psElabDoForRange elaborate smaller ops result context state name lower upper loopBody rest finish
        | PsSyntaxTerm.doTryE action name recovery rest _ =>
            psElabDoTry
              (fun (innerResult : PsExpr) (innerReturn : PsElabDoReturn) =>
                smallerWorker innerResult innerReturn true)
              smaller ops returnType result onReturn context state
              action name recovery rest finish
        | PsSyntaxTerm.doWhileE condition loopBody rest _ =>
            psElabDoWhile elaborate smaller ops result context state condition loopBody rest finish
        | _ =>
            if liftTerminal then
              psElabDoLiftTerminal elaborate ops returnType result onReturn context body
            else psElabDoEffectTerm elaborate ops context result body

def psElabDoBodyWithExit
    (fuel : Nat)
    (elaborate : PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (returnType result : PsExpr)
    (onReturn : PsElabDoReturn) (liftTerminal : Bool) : PsElabDoForNext :=
  psElabDoBodyWithExitWorker fuel elaborate ops returnType result onReturn liftTerminal

-- Preserve the established public controller entry point. A nested do term
-- gets its own return context; direct nested statements are parser-spliced.
def psElabDoBodyWithState
    (fuel : Nat)
    (elaborate : PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) : PsElabDoForNext :=
  psElabDoBodyWithExit fuel elaborate ops result result
    (fun (current : PsElabContext) (value : PsExpr) => psElabDoPure ops current
      (psMetaInstantiate current.metaContext result) value) false

def psElabDoBody
    (fuel : Nat)
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) :
    PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  fun (context : PsElabContext) (body : PsSyntaxTerm) (expectedBody : Option PsExpr) =>
    psElabDoBodyWithState fuel elaborate ops result context [] body
      (fun (current : PsElabContext) (state : List PsElabDoMutable) =>
        psElabDoPure ops current result (PsExpr.constE psUnitUnitName []))

def psElabDo
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext) (body : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabDoSelect context expected with
  | Except.error error => Except.error error
  | Except.ok selection =>
      match psElabDoBody 4096 elaborate selection.fst selection.snd context body expected with
      | Except.error error => Except.error error
      | Except.ok result => psElabFinalizeExpected result expected
