import Ps.Elab.Binders
import Ps.Environment.Logic

def psExprApplyManyWorker
    (arguments : List PsExpr)
    (fn : PsExpr) : PsExpr :=
  match arguments with
  | [] => fn
  | argument :: rest =>
      psExprApplyManyWorker rest (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) :
    PsExpr :=
  psExprApplyManyWorker arguments fn

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAccWorker
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  match expr with
  | .app fn argument =>
      psExprAppViewAccWorker fn (List.cons argument args)
  | _ =>
      {
        head := expr
        args := args
      }

def psExprAppViewAcc
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  psExprAppViewAccWorker expr args

def psExprAppView (expr : PsExpr) : PsExprAppView :=
  psExprAppViewAcc expr []

def psExprHasConst
    (target : PsName)
    (expr : PsExpr) : Bool :=
  match expr with
  | .constE name _ => psNameEq name target
  | .app fn argument =>
      psElabBoolOr
        (psExprHasConst target fn)
        (psExprHasConst target argument)
  | .lam _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .forallE _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .letE _ type value body =>
      psElabBoolOr
        (psExprHasConst target type)
        (psElabBoolOr
          (psExprHasConst target value)
          (psExprHasConst target body))
  | .proj _ _ value => psExprHasConst target value
  | _ => false

def psElabSubstituteLocals (values : List (Nat × PsExpr)) (term : PsExpr) : PsExpr :=
  values.foldl (fun body entry => psExprInstantiate1
    (psExprAbstractFVar entry.fst body) entry.snd) term

def psElabExprContainsLocal (id : Nat) (term : PsExpr) : Bool :=
  !(psExprAlphaEq term (psExprAbstractFVar id term))

-- Preserve outer local declarations. Refinement creates fresh let aliases only
-- for names not shadowed by a pattern; closing inlines those aliases. Dependent
-- outer hypotheses are never silently assigned a different type.
structure PsElabMatchAliases where
  context : PsElabContext
  valuesRev : List (Nat × PsExpr)

def psElabMatchAlias (state : PsElabMatchAliases) (entry : Nat × PsExpr) :
    Except PsElabError PsElabMatchAliases := do
  let some original := psLocalFindById state.context.localContext entry.fst
    | throw .structuralRecursionInternal
  let name := psLocalDeclUserName original
  let some visible := psLocalFindUser state.context.localContext name | return state
  if psLocalDeclId visible != entry.fst then return state
  let type ← (psInferType state.context.environment state.context.metaContext
    state.context.localContext entry.snd).mapError PsElabError.infer
  let pushed := psLocalPushLet state.context.localContext name type entry.snd
  return {
    context := psElabContextWithLocal state.context pushed.context
    valuesRev := (pushed.id, entry.snd) :: state.valuesRev }

-- Ordered dependency closure is shared by motive generalization and equality
-- elimination. Let locals are reintroduced with their definitions, not assumed.
structure PsElabDependentLocal where
  binder : PsElabTypedBinder
  value : Option PsExpr

def psElabDependentLocals (context : PsElabContext) (roots ignored : List Nat) :
    List PsElabDependentLocal :=
  let state := context.localContext.declarations.reverse.foldl (fun state declaration =>
    let id := psLocalDeclId declaration
    let type := psMetaInstantiate context.metaContext (psLocalDeclType declaration)
    let value := match declaration with
      | .binding .. => none
      | .letDecl _ _ _ value => some (psMetaInstantiate context.metaContext value)
    let dependent := state.fst.any fun root =>
      psElabExprContainsLocal root type ||
        (value.map (psElabExprContainsLocal root)).getD false
    if roots.contains id || ignored.contains id || !dependent then state else
      let binder := match declaration with
        | .binding _ _ _ binder => binder
        | _ => PsBinderInfo.explicit
      (id :: state.fst, {
        binder := PsElabTypedBinder.mk id (psLocalDeclUserName declaration) type binder
        value := value } :: state.snd)) (roots, [])
  state.snd.reverse

def psElabCloseDependentType (locals : List PsElabDependentLocal) (body : PsExpr) : PsExpr :=
  locals.foldr (fun local body =>
    let binder := local.binder
    let body := psExprAbstractFVar binder.id body
    match local.value with
    | none => .forallE binder.name binder.type body binder.binder
    | some value => .letE binder.name binder.type value body) body

def psElabDependentArguments (locals : List PsElabDependentLocal) : List PsExpr :=
  locals.filterMap fun local => if local.value.isSome then none else some (.fvar local.binder.id)

structure PsElabOpenedDependents where
  context : PsElabContext
  body : PsExpr
  bindersRev : List PsElabTypedBinder
  aliasesRev : List (Nat × PsExpr)
  replacements : List (Nat × PsExpr)

-- The target telescope is authoritative. Substitutions are also retained for
-- let values and for later equality constraints. Inaccessible names preserve
-- constructor-pattern shadowing over an outer generalized local.
def psElabExposeTelescope (fuel : Nat) (context : PsElabContext) (type : PsExpr) : PsExpr :=
  match fuel with
  | 0 => type
  | fuel + 1 =>
    let type := psMetaInstantiate context.metaContext type
    match type with
    | .letE .. => type
    | .app fn value =>
      match psWhnf context.environment context.metaContext context.localContext fn with
      | .lam _ _ body _ => psElabExposeTelescope fuel context (psExprInstantiate1 body value)
      | _ => psWhnf context.environment context.metaContext context.localContext type
    | _ => psWhnf context.environment context.metaContext context.localContext type

def psElabOpenDependents (locals : List PsElabDependentLocal)
    (state : PsElabOpenedDependents) : Except PsElabError PsElabOpenedDependents := do
  match locals with
  | [] => return state
  | local :: rest =>
    let original := local.binder
    let visible := match psLocalFindUser state.context.localContext original.name with
      | some declaration => psLocalDeclId declaration == original.id
      | none => false
    let name := if visible then original.name else psNameAppendNum (psRootName "_context") original.id
    match local.value with
    | some _ =>
      let .letE _ type value body := psElabExposeTelescope 256 state.context state.body
        | throw (.refinement "dependent local definition lost its telescope")
      let pushed := psLocalPushLet state.context.localContext name type value
      psElabOpenDependents rest { state with
        context := psElabContextWithLocal state.context pushed.context
        body := psExprInstantiate1 body (.fvar pushed.id)
        aliasesRev := (pushed.id, value) :: state.aliasesRev
        replacements := state.replacements ++ [(original.id, .fvar pushed.id)] }
    | none =>
      let pi ← (psInferEnsureForall state.context.environment state.context.metaContext
        state.context.localContext state.body).mapError PsElabError.infer
      let pushed := psLocalPushBinding state.context.localContext name pi.domain original.binder
      psElabOpenDependents rest { state with
        context := psElabContextWithLocal state.context pushed.context
        body := psExprInstantiate1 pi.body (.fvar pushed.id)
        bindersRev := PsElabTypedBinder.mk pushed.id name pi.domain original.binder :: state.bindersRev
        replacements := state.replacements ++ [(original.id, .fvar pushed.id)] }

def psElabCloseDependents (opened : PsElabOpenedDependents)
    (constraints : PsMetaContext) (value : PsExpr) : PsExpr :=
  psCloseElabLambdaBinders constraints opened.bindersRev
    (psElabSubstituteLocals opened.aliasesRev (psMetaInstantiate constraints value))

def psElabExpressionSort (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsLevel := do
  let sort ← (psInferType context.environment context.metaContext context.localContext type).mapError PsElabError.infer
  (psInferEnsureSort context.environment context.metaContext context.localContext sort).mapError PsElabError.infer
