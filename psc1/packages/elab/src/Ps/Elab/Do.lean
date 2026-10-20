import Ps.Elab.DoFor

def psElabDoBodyWithState
    (fuel : Nat)
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) :
    PsElabContext -> List PsElabDoMutable -> PsSyntaxTerm ->
    (PsElabContext -> List PsElabDoMutable ->
      Except PsElabError PsElabTermResult) ->
    Except PsElabError PsElabTermResult :=
  match fuel with
  | 0 =>
      fun _ _ _ _ => .error PsElabError.fuelExhausted
  | remaining + 1 =>
      fun context state body finish =>
        let smaller := psElabDoBodyWithState remaining elaborate ops result
        let expected := some (psElabDoType ops result)
        match body with
        | PsSyntaxTerm.doEndE _ => finish context state
        | PsSyntaxTerm.doReturnE value _ =>
            match elaborate context value (some result) with
            | .error error => .error error
            | .ok valueResult =>
                psElabDoPure ops valueResult.context
                  (psMetaInstantiate valueResult.context.metaContext result) valueResult.term
        | PsSyntaxTerm.letE sourceName annotation value rest _ =>
            match psSyntaxNameToName sourceName with
            | none => .error PsElabError.emptyName
            | some name =>
                if psElabDoMutableHasName name state then
                  .error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoLocalValue elaborate context annotation value with
                  | .error error => .error error
                  | .ok valueResult =>
                      psElabDoWithLocal
                        (fun bodyContext _ => smaller bodyContext state rest finish)
                        context name valueResult.type valueResult expected
        | PsSyntaxTerm.doLetMutE sourceName annotation value rest _ =>
            match psSyntaxNameToName sourceName with
            | none => .error PsElabError.emptyName
            | some name =>
                if psElabDoMutableHasName name state then
                  .error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoLocalValue elaborate context annotation value with
                  | .error error => .error error
                  | .ok valueResult =>
                      let type := psMetaInstantiate valueResult.context.metaContext valueResult.type
                      psElabDoWithLocal
                        (fun bodyContext id =>
                          smaller bodyContext
                            (PsElabDoMutable.mk id id name type :: state) rest finish)
                        context name type valueResult expected
        | PsSyntaxTerm.doAssignE sourceName value rest _ =>
            match psSyntaxNameToName sourceName with
            | none => .error PsElabError.emptyName
            | some name =>
                match psLocalFindUser context.localContext name with
                | none => .error (PsElabError.unknownName name)
                | some declaration =>
                    match psElabDoMutableFindCurrent (psLocalDeclId declaration) state with
                    | none => .error (PsElabError.doImmutableAssignment name)
                    | some entry =>
                        let type := psMetaInstantiate context.metaContext entry.type
                        match elaborate context value (some type) with
                        | .error error => .error error
                        | .ok valueResult =>
                            psElabDoWithLocal
                              (fun bodyContext id =>
                                smaller bodyContext
                                  (psElabDoMutableUpdate entry.bindingId id state) rest finish)
                              context name type valueResult expected
        | PsSyntaxTerm.doBindE sourceName annotation action rest _ =>
            match psSyntaxNameToName sourceName with
            | none => .error PsElabError.emptyName
            | some name =>
                if psElabDoMutableHasName name state then
                  .error (PsElabError.doMutableShadowing name)
                else
                  match psElabDoAction elaborate ops context annotation action with
                  | .error error => .error error
                  | .ok actionResult =>
                      psElabDoContinue
                        (fun bodyContext nextBody _ => smaller bodyContext state nextBody finish)
                        ops context result name actionResult.fst actionResult.snd rest
        | PsSyntaxTerm.doThenE action rest _ =>
            let unitType := PsExpr.constE psUnitName []
            match psElabDoEffectTerm elaborate ops context unitType action with
            | .error error => .error error
            | .ok actionResult =>
                psElabDoContinue
                  (fun bodyContext nextBody _ => smaller bodyContext state nextBody finish)
                  ops context result (psRootName "_") actionResult unitType rest
        | PsSyntaxTerm.doIfE condition thenBranch elseBranch rest _ =>
            let boolType := PsExpr.constE psBoolName []
            match elaborate context condition (some boolType) with
            | .error error => .error error
            | .ok conditionResult =>
                let conditionName := psElabDoInternalName "_psc1DoCondition" context
                psElabDoWithLocal
                  (fun conditionContext conditionId =>
                    let conditionValue := PsExpr.fvar conditionId
                    match rest with
                    | PsSyntaxTerm.doEndE _ =>
                        psElabDoBranches
                          (fun branchContext branch =>
                            smaller branchContext state branch finish)
                          ops result conditionContext conditionValue thenBranch elseBranch
                    | _ =>
                        let carried := psElabDoMutableVisible conditionContext state
                        match psElabDoJoin
                            (fun joinContext joinState =>
                              smaller joinContext joinState rest finish)
                            carried conditionContext state with
                        | .error error => .error error
                        | .ok joinResult =>
                            let joinName := psElabDoInternalName "_psc1DoJoin" conditionContext
                            psElabDoWithLocal
                              (fun branchContext joinId =>
                                let next :=
                                  psElabDoJoinCall ops result joinId carried
                                psElabDoBranches
                                  (fun current branch =>
                                    smaller current state branch next)
                                  ops result branchContext conditionValue thenBranch elseBranch)
                              conditionContext joinName joinResult.type joinResult expected)
                  context conditionName boolType conditionResult expected
        | PsSyntaxTerm.doForE name collection loopBody rest _ =>
            psElabDoFor elaborate smaller ops result context state name collection loopBody rest finish
        | PsSyntaxTerm.doForRangeE name lower upper loopBody rest _ =>
            psElabDoForRange elaborate smaller ops result context state name lower upper loopBody rest finish
        | _ => psElabDoEffectTerm elaborate ops context result body

def psElabDoBody
    (fuel : Nat)
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) :
    PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  fun context body _ =>
    psElabDoBodyWithState fuel elaborate ops result context [] body
      (fun current _ =>
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
