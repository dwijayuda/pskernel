import Ps.Environment.SelfHostPrelude
import Ps.Elab.Basic
import Ps.Environment.Resolve

-- One typed controller serves both source syntaxes. Families only construct
-- ordinary Core terms; psElabResolvedTerm checks every constructed operation.
-- Lexical state and delayed continuations serve sequencing, mutation and exits.
-- Every constructed operation remains an ordinary checked Core term.
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

def psElabDoSelectIdentity (arguments : List PsExpr) :
    Except PsElabError (Prod PsElabDoOps PsExpr) :=
  match arguments with
  | List.nil => Except.error PsElabError.doUnsupportedEffect
  | List.cons value rest =>
      match rest with
      | List.nil => Except.ok (Prod.mk (PsElabDoOps.identity PsLevel.zero) value)
      | _ => Except.error PsElabError.doUnsupportedEffect

def psElabDoSelectExcept (arguments : List PsExpr) :
    Except PsElabError (Prod PsElabDoOps PsExpr) :=
  match arguments with
  | List.nil => Except.error PsElabError.doUnsupportedEffect
  | List.cons error rest =>
      match rest with
      | List.nil => Except.error PsElabError.doUnsupportedEffect
      | List.cons value tail =>
          match tail with
          | List.nil => Except.ok (Prod.mk (PsElabDoOps.except error) value)
          | _ => Except.error PsElabError.doUnsupportedEffect

def psElabDoSelectCompiler (arguments : List PsExpr) :
    Except PsElabError (Prod PsElabDoOps PsExpr) :=
  match arguments with
  | List.nil => Except.error PsElabError.doUnsupportedEffect
  | List.cons reader rest =>
      match rest with
      | List.nil => Except.error PsElabError.doUnsupportedEffect
      | List.cons state tail =>
          match tail with
          | List.nil => Except.error PsElabError.doUnsupportedEffect
          | List.cons error values =>
              match values with
              | List.nil => Except.error PsElabError.doUnsupportedEffect
              | List.cons value final =>
                  match final with
                  | List.nil =>
                      Except.ok (Prod.mk (PsElabDoOps.compiler reader state error) value)
                  | _ => Except.error PsElabError.doUnsupportedEffect

def psElabDoSelect
    (context : PsElabContext) (expected : Option PsExpr) :
    Except PsElabError (Prod PsElabDoOps PsExpr) :=
  match expected with
  | Option.none => Except.error PsElabError.doExpectedType
  | Option.some expectedType =>
      let view := psExprAppView (psElabDoView 256 context expectedType);
      match view.head with
      | PsExpr.constE name levels =>
          match levels with
          | List.nil =>
              if psNameEq name (psRootName "Id") then psElabDoSelectIdentity view.args
              else if psNameEq name psSelfHostExceptName then psElabDoSelectExcept view.args
              else if psNameEq name (psRootName "CompilerM") then psElabDoSelectCompiler view.args
              else Except.error PsElabError.doUnsupportedEffect
          | _ => Except.error PsElabError.doUnsupportedEffect
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
  let term : PsExpr :=
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

-- The selected do effect gives bare pure its result type. Ordinary
-- local and global bindings retain precedence over this contextual spelling.
def psElabDoBuiltinArgument
    (context : PsElabContext) (builtin : String) (action : PsSyntaxTerm) :
    Option PsSyntaxTerm :=
  match action with
  | PsSyntaxTerm.app fn arguments _ =>
      match fn with
      | PsSyntaxTerm.reference sourceName =>
          match arguments with
          | List.nil => Option.none
          | List.cons value rest =>
              match rest with
              | List.nil =>
                  match sourceName.segments with
                  | List.nil => Option.none
                  | List.cons segment tail =>
                      match tail with
                      | List.nil =>
                          if psStringEq segment builtin then
                            let name := psRootName builtin;
                            match psResolveNameInNamespace context.localContext context.environment
                                context.currentNamespace name with
                            | Option.some _ => Option.none
                            | Option.none => Option.some value
                          else Option.none
                      | _ => Option.none
              | _ => Option.none
      | _ => Option.none
  | _ => Option.none

def psElabDoPureArgument (context : PsElabContext) : PsSyntaxTerm -> Option PsSyntaxTerm :=
  psElabDoBuiltinArgument context "pure"

def psElabDoErrorType (ops : PsElabDoOps) : Except PsElabError PsExpr :=
  match ops with
  | PsElabDoOps.except error => Except.ok error
  | PsElabDoOps.compiler _ _ error => Except.ok error
  | PsElabDoOps.identity _ => Except.error PsElabError.doUnsupportedEffect

def psElabDoRaise (ops : PsElabDoOps) (context : PsElabContext)
    (type value : PsExpr) : Except PsElabError PsElabTermResult :=
  let term : Except PsElabError PsExpr :=
    match ops with
    | PsElabDoOps.identity _ => Except.error PsElabError.doUnsupportedEffect
    | PsElabDoOps.except error => Except.ok (psSelfHostExceptErrorOf error type value)
    | PsElabDoOps.compiler reader state error =>
        Except.ok (psExprApplyMany (PsExpr.constE (psRootName "compilerThrow") [])
          [reader, state, error, type, value]);
  match term with
  | Except.error error => Except.error error
  | Except.ok value => psElabResolvedTerm context value (Option.some (psElabDoType ops type))

def psElabDoEffectTerm
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (context : PsElabContext)
    (type : PsExpr) (action : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult :=
  match psElabDoPureArgument context action with
  | Option.some value =>
      match elaborate context value (Option.some type) with
      | Except.error error => Except.error error
      | Except.ok checked =>
          psElabDoPure ops checked.context
            (psMetaInstantiate checked.context.metaContext type) checked.term
  | Option.none =>
      match psElabDoBuiltinArgument context "throw" action with
      | Option.none => elaborate context action (Option.some (psElabDoType ops type))
      | Option.some value =>
          match psElabDoErrorType ops with
          | Except.error error => Except.error error
          | Except.ok errorType =>
              match elaborate context value (Option.some errorType) with
              | Except.error error => Except.error error
              | Except.ok checked =>
                  psElabDoRaise ops checked.context
                    (psMetaInstantiate checked.context.metaContext type) checked.term

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
              let term : PsExpr :=
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
      match psElabDoEffectTerm elaborate ops current alpha action with
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

-- Mutable source locals are represented by successive immutable Core values.
-- The stable binding id distinguishes a mutable variable from a same-named
-- immutable shadow; currentId records the value visible at this program point.
structure PsElabDoMutable where
  bindingId : Nat
  currentId : Nat
  userName : PsName
  type : PsExpr

def psElabDoMutableFindCurrent
    (id : Nat) (entries : List PsElabDoMutable) : Option PsElabDoMutable :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if Nat.beq id entry.currentId then Option.some entry
      else psElabDoMutableFindCurrent id rest

def psElabDoMutableFindBinding
    (id : Nat) (entries : List PsElabDoMutable) : Option PsElabDoMutable :=
  match entries with
  | List.nil => Option.none
  | List.cons entry rest =>
      if Nat.beq id entry.bindingId then Option.some entry
      else psElabDoMutableFindBinding id rest

def psElabDoMutableUpdate
    (bindingId currentId : Nat) (entries : List PsElabDoMutable) :
    List PsElabDoMutable :=
  match entries with
  | List.nil => []
  | List.cons entry rest =>
      let next : PsElabDoMutable :=
        if Nat.beq bindingId entry.bindingId then
          PsElabDoMutable.mk entry.bindingId currentId entry.userName entry.type
        else entry;
      List.cons next (psElabDoMutableUpdate bindingId currentId rest)

def psElabDoMutableVisible
    (context : PsElabContext) (entries : List PsElabDoMutable) :
    List PsElabDoMutable :=
  match entries with
  | List.nil => []
  | List.cons entry rest =>
      let tail := psElabDoMutableVisible context rest;
      match psLocalFindUser context.localContext entry.userName with
      | Option.none => tail
      | Option.some declaration =>
          if Nat.beq (psLocalDeclId declaration) entry.currentId then List.cons entry tail
          else tail

def psElabDoMutableHasName
    (name : PsName) (entries : List PsElabDoMutable) : Bool :=
  match entries with
  | List.nil => false
  | List.cons entry rest =>
      if psNameEq name entry.userName then true
      else psElabDoMutableHasName name rest

def psElabDoInternalName (label : String) (context : PsElabContext) : PsName :=
  PsName.num (psRootName label) context.localContext.nextId

def psElabDoWithLocal
    (next : PsElabContext -> Nat -> Except PsElabError PsElabTermResult)
    (outerContext : PsElabContext) (name : PsName) (type : PsExpr)
    (value : PsElabTermResult) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let pushed := psLocalPushLet value.context.localContext name type value.term;
  let bodyContext := psElabContextWithLocal value.context pushed.context;
  match next bodyContext pushed.id with
  | Except.error error => Except.error error
  | Except.ok body =>
      let metas := body.context.metaContext;
      let term : PsExpr :=
        PsExpr.letE name (psMetaInstantiate metas type)
          (psMetaInstantiate metas value.term)
          (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term));
      psElabResolvedTerm (psElabContextWithMeta outerContext metas) term expected

-- A continuation is elaborated once in its original lexical scope. Only the
-- visible mutable values are parameters. Branch-local declarations therefore
-- cannot leak, and captured functions keep the value present when created.
-- The final Unit parameter delays the continuation even with no mutable locals.
def psElabDoJoinWorker
    (finish :
      PsElabContext -> List PsElabDoMutable ->
      Except PsElabError PsElabTermResult)
    (carried : List PsElabDoMutable) :
    PsElabContext -> List PsElabDoMutable -> Except PsElabError PsElabTermResult :=
  match carried with
  | List.nil =>
      fun (context : PsElabContext) (state : List PsElabDoMutable) =>
        let unitType := PsExpr.constE psUnitName [];
        let name := psElabDoInternalName "_psc1DoContinue" context;
        let pushed := psLocalPushBinding context.localContext name unitType PsBinderInfo.explicit;
        match finish (psElabContextWithLocal context pushed.context) state with
        | Except.error error => Except.error error
        | Except.ok body =>
            let metas := body.context.metaContext;
            let term : PsExpr := PsExpr.lam name unitType
              (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term))
              PsBinderInfo.explicit;
            psElabResolvedTerm (psElabContextWithMeta context metas) term Option.none
  | List.cons entry rest =>
      fun (context : PsElabContext) (state : List PsElabDoMutable) =>
        let smaller : PsElabContext -> List PsElabDoMutable ->
            Except PsElabError PsElabTermResult := psElabDoJoinWorker finish rest;
        let type := psMetaInstantiate context.metaContext entry.type;
        let pushed := psLocalPushBinding context.localContext entry.userName type PsBinderInfo.explicit;
        let nextState := psElabDoMutableUpdate entry.bindingId pushed.id state;
        match smaller (psElabContextWithLocal context pushed.context) nextState with
        | Except.error error => Except.error error
        | Except.ok body =>
            let metas := body.context.metaContext;
            let term : PsExpr := PsExpr.lam entry.userName (psMetaInstantiate metas type)
              (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term))
              PsBinderInfo.explicit;
            psElabResolvedTerm (psElabContextWithMeta context metas) term Option.none

def psElabDoJoin
    (finish :
      PsElabContext -> List PsElabDoMutable ->
      Except PsElabError PsElabTermResult)
    (carried : List PsElabDoMutable) (context : PsElabContext)
    (state : List PsElabDoMutable) : Except PsElabError PsElabTermResult :=
  psElabDoJoinWorker finish carried context state

def psElabDoJoinArguments
    (state : List PsElabDoMutable) (carried : List PsElabDoMutable) :
    Except PsElabError (List PsExpr) :=
  match carried with
  | List.nil => Except.ok [PsExpr.constE psUnitUnitName []]
  | List.cons entry rest =>
      match psElabDoMutableFindBinding entry.bindingId state with
      | Option.none => Except.error PsElabError.unsupportedTerm
      | Option.some current =>
          match psElabDoJoinArguments state rest with
          | Except.error error => Except.error error
          | Except.ok arguments => Except.ok (List.cons (PsExpr.fvar current.currentId) arguments)

def psElabDoJoinCall
    (ops : PsElabDoOps) (result : PsExpr)
    (joinId : Nat) (carried : List PsElabDoMutable)
    (context : PsElabContext) (state : List PsElabDoMutable) :
    Except PsElabError PsElabTermResult :=
  match psElabDoJoinArguments state carried with
  | Except.error error => Except.error error
  | Except.ok arguments =>
      psElabResolvedTerm context
        (psExprApplyMany (PsExpr.fvar joinId) arguments)
        (Option.some (psElabDoType ops result))

-- Conditions are bound once before construction of the ordinary checked ite.
-- Its proposition and Decidable argument are the existing Bool decision path.
def psElabDoCoreIf
    (ops : PsElabDoOps) (result : PsExpr) (context : PsElabContext)
    (condition thenValue elseValue : PsExpr) :
    Except PsElabError PsElabTermResult :=
  let metas := context.metaContext;
  let type := psMetaInstantiate metas (psElabDoType ops result);
  match psInferType context.environment metas context.localContext type with
  | Except.error error => Except.error (PsElabError.infer error)
  | Except.ok typeType =>
      match psInferEnsureSort context.environment metas context.localContext typeType with
      | Except.error error => Except.error (PsElabError.infer error)
      | Except.ok level =>
          let boolType := PsExpr.constE psBoolName [];
          let trueValue := PsExpr.constE psBoolTrueName [];
          let condition := psMetaInstantiate metas condition;
          let proposition := psExprApplyMany
            (PsExpr.constE psEqName [PsLevel.succ PsLevel.zero])
            [boolType, condition, trueValue];
          let decision := psExprApplyMany (PsExpr.constE psBoolDecEqName [])
            [condition, trueValue];
          let term : PsExpr := psExprApplyMany (PsExpr.constE psIteName [level])
            [type, proposition, decision,
              psMetaInstantiate metas thenValue, psMetaInstantiate metas elseValue];
          psElabResolvedTerm context term (Option.some type)

def psElabDoBranches
    (next :
      PsElabContext -> PsSyntaxTerm ->
      Except PsElabError PsElabTermResult)
    (ops : PsElabDoOps) (result : PsExpr) (context : PsElabContext)
    (condition : PsExpr) (thenBranch elseBranch : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult :=
  match next context thenBranch with
  | Except.error error => Except.error error
  | Except.ok thenResult =>
      match next (psElabContextWithMeta context thenResult.context.metaContext) elseBranch with
      | Except.error error => Except.error error
      | Except.ok elseResult =>
          psElabDoCoreIf ops result
            (psElabContextWithMeta context elseResult.context.metaContext)
            condition thenResult.term elseResult.term

