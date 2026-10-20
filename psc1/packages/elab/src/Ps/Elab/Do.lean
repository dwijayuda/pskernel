import Ps.Environment.SelfHostPrelude
import Ps.Elab.Basic

-- One typed controller serves both source syntaxes. Families only construct
-- ordinary Core terms; psElabResolvedTerm checks every constructed operation.
-- This first slice has immutable sequencing and terminal return. Branch exits,
-- mutation, loops and transformer/class search remain explicit later work.
inductive PsElabDoOps where
  | identity (level : PsLevel)
  | except (error : PsExpr)
  | compiler (reader state error : PsExpr)

def psElabDoRecognizedName (name : PsName) : Bool :=
  if psNameEq name (psRootName "Id") then true
  else if psNameEq name psSelfHostExceptName then true
  else psNameEq name (psRootName "CompilerM")

-- Expose aliases one definition at a time. Full WHNF would lose the Id
-- boundary in Id (Except E A), changing which effect the block uses.
def psElabDoView (fuel : Nat) (context : PsElabContext) :
    PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero => fun (type : PsExpr) => type
  | Nat.succ remaining =>
      fun (type : PsExpr) =>
        let smaller : PsExpr -> PsExpr := psElabDoView remaining context;
        let core := psWhnfCore context.metaContext context.localContext type;
        let view := psExprAppView core;
        match view.head with
        | PsExpr.constE name levels =>
            if psElabDoRecognizedName name then core
            else
              match psEnvironmentFind context.environment name with
              | Option.none => core
              | Option.some declaration =>
                  match psDeclarationValue declaration with
                  | Option.none => core
                  | Option.some value =>
                      if Nat.beq
                          (psReduceNameListLength (psDeclarationLevelParams declaration))
                          (psReduceLevelListLength levels) then
                        smaller
                          (psExprApplyMany
                            (psExprInstantiateLevelParams
                              (psDeclarationLevelParams declaration) levels value)
                            view.args)
                      else core
        | _ => core

def psElabDoSelect
    (context : PsElabContext) (expected : Option PsExpr) :
    Except PsElabError (Prod PsElabDoOps PsExpr) :=
  match expected with
  | Option.none => Except.error PsElabError.doExpectedType
  | Option.some expectedType =>
      let view := psExprAppView (psElabDoView 256 context expectedType);
      match view.head with
      | PsExpr.constE name levels =>
          if psNameEq name (psRootName "Id") then
            match levels, view.args with
            | [], [value] => Except.ok (Prod.mk (PsElabDoOps.identity PsLevel.zero) value)
            | _, _ => Except.error PsElabError.doUnsupportedEffect
          else if psNameEq name psSelfHostExceptName then
            match levels, view.args with
            | [], [error, value] => Except.ok (Prod.mk (PsElabDoOps.except error) value)
            | _, _ => Except.error PsElabError.doUnsupportedEffect
          else if psNameEq name (psRootName "CompilerM") then
            match levels, view.args with
            | [], [reader, state, error, value] =>
                Except.ok (Prod.mk (PsElabDoOps.compiler reader state error) value)
            | _, _ => Except.error PsElabError.doUnsupportedEffect
          else Except.error PsElabError.doUnsupportedEffect
      | _ => Except.error PsElabError.doUnsupportedEffect

def psElabDoType (ops : PsElabDoOps) (type : PsExpr) : PsExpr :=
  match ops with
  | PsElabDoOps.identity _ =>
      PsExpr.app (PsExpr.constE (psRootName "Id") []) type
  | PsElabDoOps.except error =>
      psSelfHostExceptOf error type
  | PsElabDoOps.compiler reader state error =>
      psExprApplyMany (PsExpr.constE (psRootName "CompilerM") [])
        [reader, state, error, type]

def psElabDoValueSort (ops : PsElabDoOps) : PsExpr :=
  match ops with
  | PsElabDoOps.identity level => PsExpr.sortE (PsLevel.succ level)
  | _ => PsExpr.sortE (PsLevel.succ PsLevel.zero)

def psElabDoPure
    (ops : PsElabDoOps) (context : PsElabContext) (type value : PsExpr) :
    Except PsElabError PsElabTermResult :=
  let term :=
    match ops with
    | PsElabDoOps.identity _ => value
    | PsElabDoOps.except error => psSelfHostExceptOkOf error type value
    | PsElabDoOps.compiler reader state error =>
        psExprApplyMany (PsExpr.constE (psRootName "compilerPure") [])
          [reader, state, error, type, value];
  let wrapped := psElabDoType ops type;
  match psInferType context.environment context.metaContext context.localContext wrapped with
  | Except.error error => Except.error (PsElabError.infer error)
  | Except.ok _ => psElabResolvedTerm context term (Option.some wrapped)

def psElabDoBind
    (ops : PsElabDoOps) (context : PsElabContext)
    (alpha beta action continuation : PsExpr) :
    Except PsElabError PsElabTermResult :=
  let inputType := psElabDoType ops alpha;
  let resultType := psElabDoType ops beta;
  -- The expected wrapper itself must be well-typed. For Id this enforces
  -- the Type 0 boundary even though reduction erases the identity alias.
  match psInferType context.environment context.metaContext context.localContext inputType with
  | Except.error error => Except.error (PsElabError.infer error)
  | Except.ok _ =>
      match psInferType context.environment context.metaContext context.localContext resultType with
      | Except.error error => Except.error (PsElabError.infer error)
      | Except.ok resultSort =>
          match psInferEnsureSort
              context.environment context.metaContext context.localContext resultSort with
          | Except.error error => Except.error (PsElabError.infer error)
          | Except.ok level =>
              let term :=
                match ops with
                | PsElabDoOps.identity _ =>
                    -- Generated continuations are lambdas. Preserve strict
                    -- single evaluation as an ordinary checked Core let,
                    -- avoiding a needless computed runtime call target.
                    match continuation with
                    | PsExpr.lam name type body _ =>
                        PsExpr.letE name type action body
                    | _ => PsExpr.app continuation action
                | PsElabDoOps.except error =>
                    let motive :=
                      PsExpr.lam (psRootName "_") inputType
                        (psExprLiftBVars 1 0 resultType) PsBinderInfo.explicit;
                    let errorValue :=
                      psSelfHostExceptErrorOf
                        (psExprLiftBVars 1 0 error)
                        (psExprLiftBVars 1 0 beta)
                        (PsExpr.bvar 0);
                    let errorBranch :=
                      PsExpr.lam (psRootName "error") error errorValue PsBinderInfo.explicit;
                    psExprApplyMany (PsExpr.constE psSelfHostExceptRecName [level])
                      [error, alpha, motive, errorBranch, continuation, action]
                | PsElabDoOps.compiler reader state error =>
                    psExprApplyMany (PsExpr.constE (psRootName "compilerBind") [])
                      [reader, state, error, alpha, beta, action, continuation];
              psElabResolvedTerm context term (Option.some resultType)

def psElabDoLocalValue
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (annotation : Option PsSyntaxTerm) (value : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult :=
  match annotation with
  | Option.none => elaborate context value Option.none
  | Option.some sourceType =>
      match elaborate context sourceType Option.none with
      | Except.error error => Except.error error
      | Except.ok typeResult =>
          match psInferEnsureSort typeResult.context.environment
              typeResult.context.metaContext typeResult.context.localContext typeResult.type with
          | Except.error error => Except.error (PsElabError.infer error)
          | Except.ok _ =>
              elaborate typeResult.context value (Option.some typeResult.term)

def psElabDoAction
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (context : PsElabContext)
    (annotation : Option PsSyntaxTerm) (action : PsSyntaxTerm) :
    Except PsElabError (Prod PsElabTermResult PsExpr) :=
  let finish :
      PsElabContext -> PsExpr ->
      Except PsElabError (Prod PsElabTermResult PsExpr) :=
    fun (current : PsElabContext) (alpha : PsExpr) =>
      match elaborate current action (Option.some (psElabDoType ops alpha)) with
      | Except.error error => Except.error error
      | Except.ok value =>
          Except.ok (Prod.mk value (psMetaInstantiate value.context.metaContext alpha));
  match annotation with
  | Option.none =>
      let fresh := psMetaFresh context.metaContext context.localContext
        (psElabDoValueSort ops) PsMetaVarKind.natural;
      finish (psElabContextWithMeta context fresh.context) fresh.expr
  | Option.some sourceType =>
      match elaborate context sourceType Option.none with
      | Except.error error => Except.error error
      | Except.ok typeResult =>
          match psInferEnsureSort typeResult.context.environment
              typeResult.context.metaContext typeResult.context.localContext typeResult.type with
          | Except.error error => Except.error (PsElabError.infer error)
          | Except.ok _ => finish typeResult.context typeResult.term

def psElabDoContinue
    (next :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (outerContext : PsElabContext)
    (beta : PsExpr) (name : PsName)
    (action : PsElabTermResult) (alpha : PsExpr) (body : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult :=
  let pushed := psLocalPushBinding action.context.localContext name alpha PsBinderInfo.explicit;
  let bodyContext := psElabContextWithLocal action.context pushed.context;
  match next bodyContext body (Option.some (psElabDoType ops beta)) with
  | Except.error error => Except.error error
  | Except.ok bodyResult =>
      let metaContext := bodyResult.context.metaContext;
      let continuation :=
        PsExpr.lam name
          (psMetaInstantiate metaContext alpha)
          (psExprAbstractFVar pushed.id (psMetaInstantiate metaContext bodyResult.term))
          PsBinderInfo.explicit;
      psElabDoBind ops
        (psElabContextWithMeta outerContext metaContext)
        (psMetaInstantiate metaContext alpha)
        (psMetaInstantiate metaContext beta)
        (psMetaInstantiate metaContext action.term)
        continuation

def psElabDoBody
    (fuel : Nat)
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) :
    PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsElabContext) (_body : PsSyntaxTerm) (_expected : Option PsExpr) =>
        Except.error PsElabError.fuelExhausted
  | Nat.succ remaining =>
      fun (context : PsElabContext) (body : PsSyntaxTerm) (_expected : Option PsExpr) =>
        let smaller :
            PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
            Except PsElabError PsElabTermResult :=
          psElabDoBody remaining elaborate ops result;
        let expected := Option.some (psElabDoType ops result);
        match body with
        | PsSyntaxTerm.doReturnE value _ =>
            match elaborate context value (Option.some result) with
            | Except.error error => Except.error error
            | Except.ok valueResult =>
                psElabDoPure ops valueResult.context
                  (psMetaInstantiate valueResult.context.metaContext result) valueResult.term
        | PsSyntaxTerm.letE sourceName annotation value rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                match psElabDoLocalValue elaborate context annotation value with
                | Except.error error => Except.error error
                | Except.ok valueResult =>
                    psElabLetAfterValue smaller context name valueResult.type valueResult rest expected
        | PsSyntaxTerm.doBindE sourceName annotation action rest _ =>
            match psSyntaxNameToName sourceName with
            | Option.none => Except.error PsElabError.emptyName
            | Option.some name =>
                match psElabDoAction elaborate ops context annotation action with
                | Except.error error => Except.error error
                | Except.ok actionResult =>
                    psElabDoContinue smaller ops context result name
                      actionResult.fst actionResult.snd rest
        | PsSyntaxTerm.doThenE action rest _ =>
            let unitType := PsExpr.constE psUnitName [];
            match elaborate context action (Option.some (psElabDoType ops unitType)) with
            | Except.error error => Except.error error
            | Except.ok actionResult =>
                psElabDoContinue smaller ops context result (psRootName "_")
                  actionResult unitType rest
        | _ => elaborate context body expected

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
