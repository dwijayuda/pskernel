import Ps.Meta.Recursor
import Ps.Elab.Refinement
import Ps.Elab.Declaration

-- Typed Core closure conversion before admission. Helpers preserve captures and
-- expose fresh indices/major as the only varying recursion arguments.
structure PsRecursorLiftState where
  environment : PsEnvironment
  owner : PsName
  levels : List PsName
  nextName : Nat := 0
  helpersRev : List PsDeclaration := []

structure PsRecursorLiftResult where
  state : PsRecursorLiftState
  term : PsExpr

def psRecursorLiftContext (state : PsRecursorLiftState)
    (locals : PsLocalContext) : PsElabContext :=
  psElabContextWithLocal (psElabContextEmpty state.environment) locals

def psRecursorLiftInfer (state : PsRecursorLiftState) (locals : PsLocalContext)
    (expr : PsExpr) : Except String PsExpr :=
  (psInferType state.environment psMetaEmpty locals expr).mapError
    (fun _ => "cannot infer recursor preparation type")

def psRecursorLiftIsComputational (state : PsRecursorLiftState)
    (locals : PsLocalContext) (expr : PsExpr) : Except String Bool := do
  let type ← psRecursorLiftInfer state locals expr
  let reduce := psWhnf state.environment psMetaEmpty locals
  match reduce type with
  | .sortE _ => return false
  | _ =>
    let sort ← psRecursorLiftInfer state locals type
    match reduce sort with
    | .sortE level => return psInferClosedLevelValue level != some 0
    | _ => throw "recursor result is not a type"

-- Walk newest-to-oldest so adding a capture's type discovers only earlier
-- dependencies. Let locals become parameters, preserving their evaluated values.
def psRecursorLiftCaptures (locals : PsLocalContext) (type value : PsExpr) :
    List PsElabTypedBinder :=
  let state := locals.declarations.foldl
    (fun (state : PsExpr × List PsElabTypedBinder) declaration =>
      let id := psLocalDeclId declaration
      if !psRecursorContainsLocal id state.fst then state else
        let domain := psLocalDeclType declaration
        let kind := match declaration with
          | .binding _ _ _ kind => kind
          | _ => PsBinderInfo.explicit
        let binder := PsElabTypedBinder.mk id (psLocalDeclUserName declaration) domain kind
        (.app state.fst domain, binder :: state.snd)) (.app type value, [])
  state.snd

def psRecursorLiftFreshName (fuel : Nat) (state : PsRecursorLiftState) :
    Except String (PsName × PsRecursorLiftState) := do
  match fuel with
  | 0 => throw "recursor helper name budget"
  | fuel + 1 =>
    let name := psNameAppendNum (psNameAppendStr state.owner "_rec") state.nextName
    let next := { state with nextName := state.nextName + 1 }
    if psEnvironmentContains state.environment name then psRecursorLiftFreshName fuel next
    else return (name, next)

def psRecursorLiftBetaApply (value : PsExpr) (arguments : List PsExpr) : Option PsExpr := do
  match arguments with
  | [] => return value
  | argument :: rest =>
    let .lam _ _ body _ := value | none
    psRecursorLiftBetaApply (psExprInstantiate1 body argument) rest

def psRecursorLiftHelper (state : PsRecursorLiftState) (locals : PsLocalContext)
    (view : PsRecursorApplication) : Except String PsRecursorLiftResult := do
  let context := psRecursorLiftContext state locals
  let headType ← psRecursorLiftInfer state locals view.head
  let some cursor := psReduceApplyType
    (psWhnf state.environment psMetaEmpty locals) headType view.fixedArgs
    | throw "recursor fixedArgs does not match its telescope"
  let opened ← (psElabOpenCoreTelescope 4096 context cursor
    (some (view.info.numIndices + 1))).mapError (fun _ => "cannot open recursor index/major telescope")
  let fresh := psElabBinderArguments opened.bindersRev
  let body := psReduceApply view.head (view.fixedArgs ++ fresh)
  let value := psCloseElabLambdaBinders psMetaEmpty opened.bindersRev body
  let type := psCloseElabForallBinders psMetaEmpty opened.bindersRev opened.body
  let captures := psRecursorLiftCaptures locals type value
  let value := psCloseElabLambdaBinders psMetaEmpty captures.reverse value
  let type := psCloseElabForallBinders psMetaEmpty captures.reverse type
  let arguments := captures.map (fun binder => PsExpr.fvar binder.id) ++ view.indices ++ [view.major]
  let some restored := psRecursorLiftBetaApply value arguments
    | throw "recursor helper substitution failed"
  let original := psReduceApply view.head (view.fixedArgs ++ view.indices ++ [view.major])
  if !psExprAlphaEq restored original then throw "recursor helper changed its original computation"
  let (name, state) ← psRecursorLiftFreshName 4096 state
  let declaration := PsDeclaration.definitionDecl name state.levels type value
  let some environment := psEnvironmentAdd state.environment declaration
    | throw "recursor helper name collision"
  return {
    state := { state with environment, helpersRev := declaration :: state.helpersRev }
    term := psReduceApply (.constE name (state.levels.map PsLevel.param)) (arguments ++ view.suffix) }

-- Only a declaration's leading lambda telescope may reuse its recursion
-- equation. Every nested computation has its own major and lexical captures.
def psRecursorLiftVisit (fuel : Nat) (root : Bool) (entryIds : List Nat)
    (state : PsRecursorLiftState) (locals : PsLocalContext) (expr : PsExpr) :
    Except String PsRecursorLiftResult := do
  match fuel with
  | 0 => throw "recursor preparation traversal budget"
  | fuel + 1 =>
    match expr with
    | .lam name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      let result ← psRecursorLiftVisit fuel root (if root then pushed.id :: entryIds else entryIds)
        state pushed.context (psExprInstantiate1 body (.fvar pushed.id))
      return { result with term := .lam name domain (psExprAbstractFVar pushed.id result.term) binder }
    | .letE name type value body =>
      let value ← psRecursorLiftVisit fuel false entryIds state locals value
      let pushed := psLocalPushLet locals name type value.term
      let body ← psRecursorLiftVisit fuel false entryIds value.state pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
      return { body with term := .letE name type value.term (psExprAbstractFVar pushed.id body.term) }
    | .proj name index value =>
      let value ← psRecursorLiftVisit fuel false entryIds state locals value
      return { value with term := .proj name index value.term }
    | .app .. =>
      -- Do not transform a proof or type recursor merely because its proof
      -- term contains computational intermediate expressions.
      match psRecursorApplication state.environment expr with
      | some _ =>
        if !(← psRecursorLiftIsComputational state locals expr) then return { state, term := expr }
      | none => pure ()
      let spine := psReduceAppView expr
      let head ← psRecursorLiftVisit fuel false entryIds state locals spine.head
      let arguments ← spine.args.foldlM (fun (acc : PsRecursorLiftState × List PsExpr) value => do
        let result ← psRecursorLiftVisit fuel false entryIds acc.fst locals value
        return (result.state, result.term :: acc.snd)) (head.state, [])
      let state := arguments.fst
      let term := psReduceApply head.term arguments.snd.reverse
      let some view := psRecursorApplication state.environment term | return { state, term }
      if !psRecursorUsesHypotheses state.environment view then return { state, term }
      let minors := view.fixedArgs.drop (view.info.numParams + 1)
      let direct := root && view.suffix.isEmpty &&
        ((psRecursorVaryingLocals view.major view.indices minors).map
          (fun ids => ids.all entryIds.contains)).getD false
      if direct then return { state, term }
      psRecursorLiftHelper state locals view
    | _ => return { state, term := expr }

def psRecursorLiftDeclarations (environment : PsEnvironment)
    (declarations : List PsDeclaration) : Except String PsElabModuleResult := do
  let result ← declarations.foldlM
    (fun (acc : PsEnvironment × List PsDeclaration) declaration => do
      match declaration with
      | .definitionDecl name levels type value =>
        let state : PsRecursorLiftState := { environment := acc.fst, owner := name, levels }
        let lifted ← (psRecursorLiftVisit 4096 true [] state psLocalEmpty value).mapError
          (fun message => message ++ " (in " ++ psNameToString name ++ ")")
        let rewritten := PsDeclaration.definitionDecl name levels type lifted.term
        let environment := { lifted.state.environment with
          declarations := rewritten :: psEnvironmentRemoveName name lifted.state.environment.declarations
          index := psEnvironmentIndexInsert lifted.state.environment.index rewritten }
        return (environment, rewritten :: (lifted.state.helpersRev ++ acc.snd))
      | _ => return (acc.fst, declaration :: acc.snd)) (environment, [])
  return { environment := result.fst, declarations := result.snd.reverse }
