import Ps.Elab.DoLoop
import Ps.Environment.SelfHostPrelude
import Ps.Foundation.List

-- Closed source terms are converted before ordinary admission. The temporary
-- generic while signature is only an elaboration marker; no generic loop body
-- or unchecked backend operation is used by the resulting runtime graph.
def psElabDoLoopLiftName (owner : PsName) (index : Nat) : PsName :=
  PsName.num (PsName.str owner "_psc1WhileBody") index

def psElabDoLoopIsLiftedName (owner : PsName) : PsName -> Bool
  | .num (.str parent segment) _ =>
      psNameEq parent owner && psStringEq segment "_psc1WhileBody"
  | _ => false

def psElabDoLoopHasFVar (target : Nat) : PsExpr -> Bool
  | .fvar id => Nat.beq id target
  | .app fn arg => psElabDoLoopHasFVar target fn || psElabDoLoopHasFVar target arg
  | .lam _ type body _ =>
      psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target body
  | .forallE _ type body _ =>
      psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target body
  | .letE _ type value body =>
      psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target value ||
        psElabDoLoopHasFVar target body
  | .proj _ _ value => psElabDoLoopHasFVar target value
  | _ => false

def psElabDoLoopNeedsLocal (id : Nat) : List PsExpr -> Bool
  | [] => false
  | value :: rest => psElabDoLoopHasFVar id value || psElabDoLoopNeedsLocal id rest

-- Locals are newest first, so adding a selected local's type to the roots
-- closes its dependencies while retaining the existing telescope order.
def psElabDoLoopCaptures (roots : List PsExpr) :
    List PsLocalDecl -> List PsLocalDecl
  | [] => []
  | declaration :: rest =>
      if psElabDoLoopNeedsLocal (psLocalDeclId declaration) roots then
        declaration :: psElabDoLoopCaptures (psLocalDeclType declaration :: roots) rest
      else psElabDoLoopCaptures roots rest

def psElabDoLoopCaptureBinders :
    List PsLocalDecl -> List (Prod Nat (Prod PsName PsExpr))
  | [] => []
  | declaration :: rest =>
      Prod.mk (psLocalDeclId declaration)
        (Prod.mk (psLocalDeclUserName declaration) (psLocalDeclType declaration)) ::
          psElabDoLoopCaptureBinders rest

def psElabDoLoopCaptureArguments : List PsLocalDecl -> List PsExpr
  | [] => []
  | declaration :: rest =>
      PsExpr.fvar (psLocalDeclId declaration) :: psElabDoLoopCaptureArguments rest

-- The replacement is a fresh free variable. Closing its binder after all other
-- binders also replaces source-self occurrences in dependent capture types.
def psElabDoLoopReplaceOwner (owner : PsName) (replacement : PsExpr) : PsExpr -> PsExpr
  | .constE name levels =>
      if psNameEq name owner then replacement else PsExpr.constE name levels
  | .app fn arg =>
      PsExpr.app (psElabDoLoopReplaceOwner owner replacement fn)
        (psElabDoLoopReplaceOwner owner replacement arg)
  | .lam name type body binder =>
      PsExpr.lam name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement body) binder
  | .forallE name type body binder =>
      PsExpr.forallE name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement body) binder
  | .letE name type value body =>
      PsExpr.letE name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement value)
        (psElabDoLoopReplaceOwner owner replacement body)
  | .proj name index value =>
      PsExpr.proj name index (psElabDoLoopReplaceOwner owner replacement value)
  | value => value

def psElabDoLoopBetaValue : PsExpr -> Bool
  | .fvar _ | .bvar _ | .lam _ _ _ _ | .sortE _ | .lit _ => true
  | .constE name [] =>
      psNameEq name psUnitUnitName || psNameEq name psBoolTrueName ||
        psNameEq name psBoolFalseName
  | _ => false

-- Inline only lambda values containing this helper's recurrence. Applying a
-- lambda to a nonvalue produces a Core let, preserving strict single evaluation.
-- Moving an application through a let keeps evaluation of its function first.
def psElabDoLoopNormalize (fuel : Nat) (helper : PsName) (term : PsExpr) :
    Except PsElabError PsExpr :=
  if !psElabDoLoopOccurs helper term then .ok term
  else
    match fuel with
    | 0 => .error PsElabError.fuelExhausted
    | remaining + 1 =>
        let smaller := psElabDoLoopNormalize remaining helper
        match term with
        | .app fn arg => do
            let fn <- smaller fn
            let arg <- smaller arg
            match fn with
            | .lam name domain body _ =>
                if psElabDoLoopBetaValue arg then
                  smaller (psExprInstantiate1 body arg)
                else
                  smaller (PsExpr.letE name domain arg body)
            | .letE name type value body =>
                smaller (PsExpr.letE name type value
                  (PsExpr.app body (psExprLiftBVars 1 0 arg)))
            | _ => pure (PsExpr.app fn arg)
        | .letE name type value body => do
            if psElabDoLoopOccurs helper type then
              throw PsElabError.doWhileUnsupportedBody
            let value <- smaller value
            match value with
            | .lam _ _ _ _ =>
                if psElabDoLoopOccurs helper value then
                  smaller (psExprInstantiate1 body value)
                else
                  pure (PsExpr.letE name type value (<- smaller body))
            | _ => pure (PsExpr.letE name type value (<- smaller body))
        | .lam name type body binder => do
            if psElabDoLoopOccurs helper type then
              throw PsElabError.doWhileUnsupportedBody
            pure (PsExpr.lam name type (<- smaller body) binder)
        | .proj name index value => do
            pure (PsExpr.proj name index (<- smaller value))
        | .forallE _ _ _ _ => .error PsElabError.doWhileUnsupportedBody
        | _ => .ok term

def psElabDoLoopCleanArguments (helper : PsName) : List PsExpr -> Bool
  | [] => true
  | argument :: rest =>
      !psElabDoLoopOccurs helper argument && psElabDoLoopCleanArguments helper rest

-- These are the Core control forms whose erasure preserves branch tail
-- position. Any escaping, partial, non-tail or otherwise hidden self use fails.
def psElabDoLoopTailValid (fuel : Nat) (helper : PsName) (arity : Nat)
    (term : PsExpr) : Bool :=
  if !psElabDoLoopOccurs helper term then true
  else
    match fuel with
    | 0 => false
    | remaining + 1 =>
        let smaller := psElabDoLoopTailValid remaining helper arity
        match term with
        | .letE _ type value body =>
            !psElabDoLoopOccurs helper type &&
              !psElabDoLoopOccurs helper value && smaller body
        | .app _ _ =>
            let view := psExprAppView term
            match view.head with
            | .constE name _ =>
                if psNameEq name helper then
                  Nat.beq (psListLength view.args) arity &&
                    psElabDoLoopCleanArguments helper view.args
                else if psNameEq name psIteName then
                  match view.args with
                  | [type, proposition, decision, yes, no] =>
                      psElabDoLoopCleanArguments helper [type, proposition, decision] &&
                        smaller yes && smaller no
                  | _ => false
                else if psNameEq name psSelfHostExceptRecName then
                  match view.args with
                  | [error, value, motive, failure, success, action] =>
                      let branch := fun (minor : PsExpr) =>
                        if !psElabDoLoopOccurs helper minor then true
                        else
                          match minor with
                          | .lam _ type body _ =>
                              !psElabDoLoopOccurs helper type && smaller body
                          | _ => false
                      psElabDoLoopCleanArguments helper [error, value, motive, action] &&
                        branch failure && branch success
                  | _ => false
                else false
            | _ => false
        | _ => false

structure PsElabDoLoopLiftState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration
  nextIndex : Nat

structure PsElabDoLoopLiftResult where
  term : PsExpr
  state : PsElabDoLoopLiftState

def psElabDoLoopAddHeader (environment : PsEnvironment) (name : PsName)
    (type : PsExpr) : Except PsElabError PsEnvironment :=
  match psEnvironmentAdd environment (PsDeclaration.axiomDecl name [] type) with
  | none => .error (PsElabError.duplicateDeclaration name)
  | some result => .ok result

def psElabDoLoopCheck (environment : PsEnvironment) (locals : PsLocalContext)
    (term type : PsExpr) : Except PsElabError Unit := do
  let context := psElabContextWithLocal (psElabContextEmpty environment) locals
  let _ <- psElabResolvedTerm context term (some type)
  pure ()

def psElabDoLoopApplyStep (step recurrence state unit : PsExpr) :
    Except PsElabError PsExpr := do
  let .lam _ _ first _ := step | throw PsElabError.doWhileUnsupportedBody
  let .lam _ _ second _ := psExprInstantiate1 first recurrence
    | throw PsElabError.doWhileUnsupportedBody
  let .lam _ _ third _ := psExprInstantiate1 second state
    | throw PsElabError.doWhileUnsupportedBody
  pure (psExprInstantiate1 third unit)

def psElabDoLoopSpecialize
    (owner : PsName) (ownerType : PsExpr) (marker : PsName)
    (locals : PsLocalContext) (work : PsElabDoLoopLiftState)
    (stateType resultType fallback step initial unit : PsExpr) :
    Except PsElabError PsElabDoLoopLiftResult := do
  if psElabDoLoopOccurs marker step then
    throw PsElabError.doWhileUnsupportedBody
  let name := psElabDoLoopLiftName owner work.nextIndex
  let capturesRev := psElabDoLoopCaptures [stateType, resultType, step] locals.declarations
  let captureArguments := psElabDoLoopCaptureArguments (psListReverse capturesRev)
  let unitType := PsExpr.constE psUnitName []
  let thunkType := psElabDoLoopArrow unitType resultType
  let fallbackId := locals.nextId
  let stateId := fallbackId + 1
  let unitId := stateId + 1
  let nextId := unitId + 1
  let sourceId := nextId + 1
  let sourceName := psRootName "_psc1SourceFunction"
  let bindersRev :=
    [Prod.mk unitId (Prod.mk (psRootName "_psc1WhileUnit") unitType),
      Prod.mk stateId (Prod.mk (psRootName "_psc1WhileState") stateType),
      Prod.mk fallbackId (Prod.mk (psRootName "_psc1WhileFallback") thunkType)] ++
        psElabDoLoopCaptureBinders capturesRev
  let closedType := psElabDoLoopCloseType bindersRev resultType
  let captureSource := psElabDoLoopOccurs owner closedType || psElabDoLoopOccurs owner step
  let helperType :=
    if captureSource then
      PsExpr.forallE sourceName ownerType
        (psExprAbstractFVar sourceId
          (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) closedType))
        PsBinderInfo.explicit
    else closedType
  let argumentsPrefix := (if captureSource then [PsExpr.constE owner []] else []) ++ captureArguments
  let environment <- psElabDoLoopAddHeader work.environment name helperType
  let recursiveCall := psExprApplyMany (PsExpr.constE name [])
    (argumentsPrefix ++ [PsExpr.fvar fallbackId, PsExpr.fvar nextId])
  let recurrence := PsExpr.lam (psRootName "_psc1WhileNextState") stateType
    (psExprAbstractFVar nextId recursiveCall) PsBinderInfo.explicit
  let openBody <- psElabDoLoopApplyStep step recurrence
    (PsExpr.fvar stateId) (PsExpr.fvar unitId)
  let openBody <- psElabDoLoopNormalize 4096 name openBody
  let arity := psListLength capturesRev + 3 + (if captureSource then 1 else 0)
  if !psElabDoLoopTailValid 4096 name arity openBody then
    throw PsElabError.doWhileUnsupportedBody
  let closedValue := psElabDoLoopCloseValue bindersRev openBody
  let helperValue :=
    if captureSource then
      PsExpr.lam sourceName ownerType
        (psExprAbstractFVar sourceId
          (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) closedValue))
        PsBinderInfo.explicit
    else closedValue
  if psElabDoLoopOccurs owner helperType || psElabDoLoopOccurs owner helperValue then
    throw PsElabError.doWhileUnsupportedBody
  psElabDoLoopCheck environment psLocalEmpty helperValue helperType
  let call := psExprApplyMany (PsExpr.constE name [])
    (argumentsPrefix ++ [fallback, initial, unit])
  psElabDoLoopCheck environment locals call resultType
  let declaration := PsDeclaration.partialDecl name [] helperType helperValue
  pure (PsElabDoLoopLiftResult.mk call
    { environment := environment
      declarationsRev := declaration :: work.declarationsRev
      nextIndex := work.nextIndex + 1 })

def psElabDoLoopLiftExpr
    (fuel : Nat) (owner : PsName) (ownerType : PsExpr) (marker : PsName)
    (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) :
    Except PsElabError PsElabDoLoopLiftResult :=
  if !psElabDoLoopOccurs marker term then
    .ok (PsElabDoLoopLiftResult.mk term work)
  else
    match fuel with
    | 0 => .error PsElabError.fuelExhausted
    | remaining + 1 =>
        let smaller := psElabDoLoopLiftExpr remaining owner ownerType marker
        match term with
        | .app fn argument => do
            let view := psExprAppView term
            match view.head, view.args with
            | .constE name [], [stateType, resultType, fallback, step, initial, unit] =>
                if psNameEq name marker then
                  if psElabDoLoopOccurs marker stateType ||
                      psElabDoLoopOccurs marker resultType then
                    throw PsElabError.doWhileUnsupportedBody
                  let fallback <- smaller locals work fallback
                  let step <- smaller locals fallback.state step
                  let initial <- smaller locals step.state initial
                  let unit <- smaller locals initial.state unit
                  psElabDoLoopSpecialize owner ownerType marker locals unit.state
                    stateType resultType fallback.term step.term initial.term unit.term
                else
                  let fn <- smaller locals work fn
                  let argument <- smaller locals fn.state argument
                  pure (PsElabDoLoopLiftResult.mk (PsExpr.app fn.term argument.term) argument.state)
            | _, _ =>
                let fn <- smaller locals work fn
                let argument <- smaller locals fn.state argument
                pure (PsElabDoLoopLiftResult.mk (PsExpr.app fn.term argument.term) argument.state)
        | .lam name type body binder => do
            if psElabDoLoopOccurs marker type then
              throw PsElabError.doWhileUnsupportedBody
            let pushed := psLocalPushBinding locals name type binder
            let body <- smaller pushed.context work
              (psExprInstantiate1 body (PsExpr.fvar pushed.id))
            pure (PsElabDoLoopLiftResult.mk
              (PsExpr.lam name type (psExprAbstractFVar pushed.id body.term) binder) body.state)
        | .letE name type value body => do
            if psElabDoLoopOccurs marker type then
              throw PsElabError.doWhileUnsupportedBody
            let value <- smaller locals work value
            let pushed := psLocalPushLet locals name type value.term
            let body <- smaller pushed.context value.state
              (psExprInstantiate1 body (PsExpr.fvar pushed.id))
            pure (PsElabDoLoopLiftResult.mk
              (PsExpr.letE name type value.term (psExprAbstractFVar pushed.id body.term)) body.state)
        | .proj name index value => do
            let value <- smaller locals work value
            pure (PsElabDoLoopLiftResult.mk (PsExpr.proj name index value.term) value.state)
        | _ => .error PsElabError.doWhileUnsupportedBody

def psElabDoLoopLiftDeclaration
    (environment : PsEnvironment) (owner : PsName) (levels : List PsName)
    (type value : PsExpr) : Except PsElabError (List PsDeclaration) := do
  let marker := psElabDoLoopName owner
  if !psElabDoLoopOccurs marker value then
    return [PsDeclaration.partialDecl owner levels type value]
  match levels with
  | [] => pure ()
  | _ => throw PsElabError.doWhileUnsupportedBody
  if psElabDoLoopOccurs marker type then throw PsElabError.doWhileUnsupportedBody
  let environment <- psElabDoLoopAddHeader environment owner type
  let environment <- psElabDoLoopAddHeader environment marker psElabDoLoopType
  let work := PsElabDoLoopLiftState.mk environment [] 0
  let lifted <- psElabDoLoopLiftExpr 4096 owner type marker psLocalEmpty work value
  if psElabDoLoopOccurs marker lifted.term then throw PsElabError.doWhileUnsupportedBody
  psElabDoLoopCheck lifted.state.environment psLocalEmpty lifted.term type
  pure (psListReverse lifted.state.declarationsRev ++
    [PsDeclaration.partialDecl owner levels type lifted.term])
