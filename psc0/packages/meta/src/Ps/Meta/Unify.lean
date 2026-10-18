import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Infer

structure PsUnifyResult where
  context : PsMetaContext
  success : Bool
  resourceExceeded : Bool := false

def psUnifySuccess (context : PsMetaContext) : PsUnifyResult :=
  { context := context, success := true }

def psUnifyFailure (context : PsMetaContext) : PsUnifyResult :=
  { context := context, success := false }

def psMetaSetLevels
    (context : PsMetaContext)
    (levels : PsLevelMetaContext) : PsMetaContext :=
  {
    nextId := context.nextId
    declarations := context.declarations
    assignments := context.assignments
    delayed := context.delayed
    levels := levels
  }

def psMetaVarAssignable (context : PsMetaContext) (id : Nat) : Bool :=
  match psMetaFindDecl context id with
  | none => false
  | some declaration =>
      match declaration.kind with
      | .syntheticOpaque => false
      | _ => true

def psMetaVarIsNatural (context : PsMetaContext) (id : Nat) : Bool :=
  match psMetaFindDecl context id with
  | some declaration =>
      match declaration.kind with
      | .natural => true
      | _ => false
  | none => false

-- Resource refusal must survive speculative assignment and family fallbacks.
def psUnifyInferFailure (context : PsMetaContext) (error : PsInferError) : PsUnifyResult :=
  match error with
  | .fuelExhausted => { context, success := false, resourceExceeded := true }
  | _ => psUnifyFailure context

-- Assignment solves the candidate's type constraints as well as its value.
-- In particular ?A : Sort ?u := Nat must constrain ?u to 1; scope/occurs
-- checks alone would leave polymorphic constants with unresolved universes.
def psUnifyAssignWithInferError
    (onInferError : PsMetaContext → PsInferError → PsUnifyResult)
    (unifyTypes : PsMetaContext -> PsExpr -> PsExpr -> PsUnifyResult)
    (environment : PsEnvironment) (localContext : PsLocalContext)
    (context : PsMetaContext) (id : Nat) (value : PsExpr) : PsUnifyResult :=
  if !psMetaVarAssignable context id then psUnifyFailure context else
    match psMetaFindDecl context id with
    | none => psUnifyFailure context
    | some declaration =>
      match psInferType environment context localContext (psMetaInstantiate context value) with
      | .error error => onInferError context error
      | .ok type =>
        let checked := unifyTypes context declaration.type type
        if !checked.success then { checked with context } else
          match psMetaAssign checked.context id value with
          | none => psUnifyFailure context
          | some next => psUnifySuccess next

-- Existing assignment callers retain their established inference-error policy.
def psUnifyAssign
    (unifyTypes : PsMetaContext -> PsExpr -> PsExpr -> PsUnifyResult)
    (environment : PsEnvironment) (localContext : PsLocalContext)
    (context : PsMetaContext) (id : Nat) (value : PsExpr) : PsUnifyResult :=
  psUnifyAssignWithInferError (fun context _ => psUnifyFailure context)
    unifyTypes environment localContext context id value

def psUnifyLevelLists
    (leftLevels : List PsLevel) :
    PsMetaContext -> List PsLevel -> PsUnifyResult :=
  match leftLevels with
  | List.nil =>
      fun (context : PsMetaContext) (rightLevels : List PsLevel) =>
        match rightLevels with
        | List.nil => psUnifySuccess context
        | List.cons _ _ => psUnifyFailure context
  | List.cons left leftRest =>
      let smaller :
          PsMetaContext -> List PsLevel -> PsUnifyResult :=
        psUnifyLevelLists leftRest;
      fun (context : PsMetaContext) (rightLevels : List PsLevel) =>
        match rightLevels with
        | List.nil => psUnifyFailure context
        | List.cons right rightRest =>
            let unified := psLevelUnify context.levels left right;
            if unified.success then
              smaller
                (psMetaSetLevels context unified.context)
                rightRest
            else
              psUnifyFailure context

-- Lean's definitional equality identifies any two proofs of the same Prop.
-- This is a *typed, closed* proof-irrelevance rule, never a Boolean shortcut:
-- infer both proof types in the current context, require the propositions to
-- be definitionally equal, and verify that the proposition has sort Prop.
-- Defer when metavariables are unresolved instead of guessing assignments.
-- The official Lean kernel remains the final checker of constructed terms.
def psUnifyGroundProofIrrelevance (transparency : PsTransparency)
    (environment : PsEnvironment) (localContext : PsLocalContext)
    (context : PsMetaContext) (left right : PsExpr) : Bool :=
  psInferGroundProofIrrelevanceAt transparency (psInferType environment context)
    environment context localContext left right

-- Try congruence before delta-reducing a shared named head. Expanding a
-- dictionary constructor function too early turns its argument metavariables
-- into applied holes beneath implementation lambdas, losing a solvable match.
-- This is a sufficient equality rule, not an injectivity assumption: failed
-- argument matching discards every speculative assignment and falls back to
-- the ordinary definitional-equality path using the original context.
def psUnifyRigidApplication
    (unify : PsMetaContext → PsExpr → PsExpr → PsUnifyResult)
    (context : PsMetaContext) (localContext : PsLocalContext)
    (left right : PsExpr) : Option PsUnifyResult := do
  let left := psInferAppView (psWhnfCore context localContext left)
  let right := psInferAppView (psWhnfCore context localContext right)
  let .constE leftName leftLevels := left.head | none
  let .constE rightName rightLevels := right.head | none
  if !psNameEq leftName rightName || left.args.isEmpty ||
      left.args.length != right.args.length then none else
  let arguments := fun initial =>
    (left.args.zip right.args).foldl (fun current (a, b) =>
      if current.success then unify current.context a b else current) initial
  let levels := psUnifyLevelLists leftLevels context rightLevels
  let result := if levels.success then arguments levels else
    -- A composite level such as max ?u ?v need not be solvable until the
    -- typed arguments fix ?u and ?v. Defer that equation within this spine;
    -- retry from the original snapshot and require it before committing.
    let args := arguments (psUnifySuccess context)
    if args.success then psUnifyLevelLists leftLevels args.context rightLevels else args
  if result.success || result.resourceExceeded then some result else none

-- Solve flexible heads before delta reduction. In particular ?A := Alias
-- must retain the checked source identity: reducing Alias to Nat here would
-- silently change the later instance-search problem.
def psUnifyFlexible
    (assign : Nat → PsExpr → PsUnifyResult) (context : PsMetaContext)
    (left right : PsExpr) : Option PsUnifyResult := do
  let result ← match left, right with
    | .mvar a, .mvar b =>
      if a == b then some (psUnifySuccess context)
      else if psMetaVarIsNatural context b then
        if psMetaVarIsNatural context a && psMetaVarAssignable context a then
          some (assign a right)
        else some (assign b left)
      else if psMetaVarAssignable context a then some (assign a right)
      else some (assign b left)
    | .mvar a, _ => some (assign a right)
    | _, .mvar b => some (assign b left)
    | _, _ => none
  if result.success || result.resourceExceeded then some result else none

-- This manifest view is also used by application elaboration when deciding
-- whether an expected result is still unconstrained. No reduction occurs here.
def psUnifyResultFamilyView (context : PsMetaContext) (expression : PsExpr) :
    Option (PsMetaVarDecl × List PsExpr) := do
  let view := psInferAppView expression
  let .mvar id := view.head | none
  let declaration ← psMetaFindDecl context id
  let .natural := declaration.kind | none
  if declaration.numScopeArgs == 0 ||
      view.args.length != declaration.numScopeArgs ||
      (psMetaFindAssignment context id).isSome ||
      (psMetaFindDelayed context id).isSome then none
  else some (declaration, view.args)

-- Binding identity follows application order, which may differ from local-ID
-- order. Delayed readiness forbids closing over a hole that could later mention
-- one of the abstracted binders.
def psUnifyResultFamilyPattern (context : PsMetaContext) (locals : PsLocalContext)
    (declaration : PsMetaVarDecl) (arguments : List PsExpr) (value : PsExpr) :
    Option PsExpr := do
  let abstractions ← arguments.mapM fun argument => do
    let .fvar id := argument | none
    if psLocalContainsId declaration.localContext id then none else
    let some (.binding _ name type binder) := psLocalFindById locals id | none
    return PsMetaAbstraction.lambdaE id name type binder
  let ids := abstractions.map psMetaAbstractionId
  if ids.eraseDups.length != ids.length then none else
  psMetaTryClose context {
    id := declaration.id
    abstractions := abstractions.reverse
    body := value }

-- A scope-safe constant result needs no inversion of the actual arguments.
-- Build its lambda telescope from the declared family type, never guessed
-- domains or types taken from a non-pattern application.
def psUnifyResultFamilyConstant (environment : PsEnvironment)
    (context : PsMetaContext) (locals : PsLocalContext)
    (count : Nat) (type value : PsExpr) : Except PsInferError PsExpr := do
  match count with
  | 0 =>
    let _ ← psInferEnsureSort environment context locals type
    return value
  | count + 1 =>
    let pi ← psInferEnsureForall environment context locals type
    let pushed := psLocalPushBinding locals pi.name pi.domain pi.binder
    let body ← psUnifyResultFamilyConstant environment context pushed.context count
      (psExprInstantiate1 pi.body (.fvar pushed.id)) value
    return .lam pi.name pi.domain (psExprAbstractFVar pushed.id body) pi.binder

-- Every candidate is checked in the family's creation locals, then the entire
-- original comparison is retried in its actual locals. No failed type, scope,
-- occurs, or comparison attempt publishes assignments or universe constraints.
def psUnifyResultFamilyAssign
    (unify : PsLocalContext → PsMetaContext → PsExpr → PsExpr → PsUnifyResult)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (declaration : PsMetaVarDecl)
    (application value candidate : PsExpr) : PsUnifyResult :=
  if !psMetaExprScopeSafe context declaration.localContext candidate then
    psUnifyFailure context
  else
    let assigned := psUnifyAssignWithInferError psUnifyInferFailure
      (unify declaration.localContext) environment declaration.localContext
      context declaration.id candidate
    if !assigned.success || assigned.resourceExceeded then { assigned with context } else
      let checked := unify locals assigned.context application value
      if checked.success then checked else { checked with context }

def psUnifyResultFamilyAttempt
    (unify : PsLocalContext → PsMetaContext → PsExpr → PsExpr → PsUnifyResult)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (declaration : PsMetaVarDecl)
    (arguments : List PsExpr) (value : PsExpr) : PsUnifyResult :=
  let application := psReduceApply (.mvar declaration.id) arguments
  match psInferType environment context locals application with
  | .error error => psUnifyInferFailure context error
  | .ok type =>
    match psInferEnsureSort environment context locals type with
    | .error error => psUnifyInferFailure context error
    | .ok _ =>
      let pattern := match psUnifyResultFamilyPattern context locals declaration arguments value with
        | none => psUnifyFailure context
        | some candidate => psUnifyResultFamilyAssign unify environment locals
            context declaration application value candidate
      if pattern.success || pattern.resourceExceeded then pattern else
      if !psMetaExprScopeSafe context declaration.localContext value then psUnifyFailure context else
      match psUnifyResultFamilyConstant environment context declaration.localContext
          declaration.numScopeArgs declaration.type value with
      | .error error => psUnifyInferFailure context error
      | .ok candidate => psUnifyResultFamilyAssign unify environment locals
          context declaration application value candidate

-- An owned but blocked family remains blocked. Falling through to generic
-- application congruence could guess its whole head (for example R := Fin)
-- before the original body's unresolved index or numeral is determined.
def psUnifyResultFamily
    (unify : PsLocalContext → PsMetaContext → PsExpr → PsExpr → PsUnifyResult)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (left right : PsExpr) : Option PsUnifyResult :=
  let leftFamily := psUnifyResultFamilyView context left
  let rightFamily := psUnifyResultFamilyView context right
  if leftFamily.isNone && rightFamily.isNone then none else
  let first := match leftFamily with
    | none => psUnifyFailure context
    | some (declaration, arguments) =>
      psUnifyResultFamilyAttempt unify environment locals context declaration arguments right
  if first.success || first.resourceExceeded then some first else
  match rightFamily with
  | none => some first
  | some (declaration, arguments) =>
    some (psUnifyResultFamilyAttempt unify environment locals context declaration arguments left)

-- Function eta follows pinned Lean Meta/ExprDefEq.lean:224–234.
-- Expand only from the non-lambda's inferred Pi, preserving every binder
-- domain, level, application and local identity. Failed attempts roll back.
def psUnifyFunctionEta
    (unify : PsLocalContext → PsMetaContext → PsExpr → PsExpr → PsUnifyResult)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (left right : PsExpr) : Option PsUnifyResult :=
  let attempt := fun lambda other =>
    match psInferType environment context locals other with
    | .error error => some (psUnifyInferFailure context error)
    | .ok type =>
      match psWhnfWithTransparency .«default» environment context locals type with
      | .forallE name domain _ binder =>
        let expanded := PsExpr.lam name domain
          (.app (psExprLiftBVars 1 0 other) (.bvar 0)) binder
        let result := unify locals context lambda expanded
        some (if result.success then result else { result with context })
      | _ => none
  match left, right with
  | .lam _ _ _ _, .lam _ _ _ _ => none
  | lambda@(.lam _ _ _ _), other => attempt lambda other
  | other, lambda@(.lam _ _ _ _) => attempt lambda other
  | _, _ => none

-- Recovery is supplied by a higher layer to resolve a checked reduction blocker.
-- The default public worker uses no recovery, so Meta does not depend on
-- typeclass search or elaborator work queues.
def psUnifyWithFuelRecoverWorker
    (recover : Option (PsMetaContext → PsExpr → PsExpr → Option PsUnifyResult))
    (transparency : PsTransparency)
    (fuel : Nat) :
    PsEnvironment ->
    PsLocalContext ->
    PsMetaContext ->
    PsExpr ->
    PsExpr ->
    PsUnifyResult :=
  match fuel with
  | Nat.zero =>
      fun (environment : PsEnvironment)
          (localContext : PsLocalContext)
          (context : PsMetaContext)
          (left : PsExpr)
          (right : PsExpr) =>
        psUnifyFailure context
  | Nat.succ remaining =>
      fun (environment : PsEnvironment)
          (localContext : PsLocalContext)
          (context : PsMetaContext)
          (left : PsExpr)
          (right : PsExpr) =>
        let attempted : PsUnifyResult :=
          -- Structural reflexivity is sufficient and must precede speculative
          -- congruence, proof inference and normalization. No assignments arise.
          let left := psMetaInstantiate context left
          let right := psMetaInstantiate context right
          if psExprAlphaEq left right then psUnifySuccess context else
          let smaller :
              PsEnvironment ->
              PsLocalContext ->
              PsMetaContext ->
              PsExpr ->
              PsExpr ->
              PsUnifyResult :=
            psUnifyWithFuelRecoverWorker recover transparency remaining;
          let assign : Nat -> PsExpr -> PsUnifyResult :=
            psUnifyAssign (smaller environment localContext) environment localContext context;
          let leftCore := psWhnfCore context localContext left
          let rightCore := psWhnfCore context localContext right
          let flexible := psUnifyFlexible assign context leftCore rightCore
          match flexible.orElse (fun _ =>
            let family := psUnifyResultFamily (smaller environment) environment localContext
              context leftCore rightCore
            (family.bind (fun result =>
              if result.success || result.resourceExceeded then some result else none)).orElse
                (fun _ => psUnifyRigidApplication (smaller environment localContext)
                  context localContext left right)) with
          | some result => result
          | none =>
            let leftValue := psWhnfWithTransparency transparency environment context localContext left;
            let rightValue := psWhnfWithTransparency transparency environment context localContext right;
            if psExprAlphaEq leftValue rightValue then
              psUnifySuccess context
            else if psUnifyGroundProofIrrelevance transparency environment localContext context leftValue rightValue then
              psUnifySuccess context
            else if let some result :=
                (psUnifyFlexible assign context leftValue rightValue).orElse (fun _ =>
                  psUnifyResultFamily (smaller environment) environment localContext
                    context leftValue rightValue) then result
            else if let some result := psUnifyFunctionEta (smaller environment)
                environment localContext context leftValue rightValue then result
            else
              match leftValue with
              | .mvar leftId =>
                  match rightValue with
                  | .mvar rightId =>
                      if Nat.beq leftId rightId then
                        psUnifySuccess context
                      else if psMetaVarIsNatural context rightId then
                        if psMetaVarIsNatural context leftId then
                          if psMetaVarAssignable context leftId then
                            assign leftId rightValue
                          else
                            assign rightId leftValue
                        else
                          assign rightId leftValue
                      else if psMetaVarAssignable context leftId then
                        assign leftId rightValue
                      else
                        assign rightId leftValue
                  | _ =>
                      assign leftId rightValue
              | .sortE leftLevel =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .sortE rightLevel =>
                      let unified := psLevelUnify context.levels leftLevel rightLevel;
                      if unified.success then
                        psUnifySuccess (psMetaSetLevels context unified.context)
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
              | .constE leftName leftLevels =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .constE rightName rightLevels =>
                      if psNameEq leftName rightName then
                        psUnifyLevelLists leftLevels context rightLevels
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
              | .app leftFn leftArg =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .app rightFn rightArg =>
                      let fnResult :=
                        smaller
                          environment
                          localContext
                          context
                          leftFn
                          rightFn;
                      if fnResult.success then
                        smaller
                          environment
                          localContext
                          fnResult.context
                          leftArg
                          rightArg
                      else
                        { fnResult with context }
                  | _ => psUnifyFailure context
              | .lam leftName leftType leftBody _ =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .lam rightName rightType rightBody _ =>
                      let typeResult :=
                        smaller
                          environment
                          localContext
                          context
                          leftType
                          rightType;
                      if typeResult.success then
                        let pushed :=
                          psLocalPushBinding
                            localContext
                            rightName
                            rightType
                            PsBinderInfo.explicit;
                        let fvar := PsExpr.fvar pushed.id;
                        smaller
                          environment
                          pushed.context
                          typeResult.context
                          (psExprInstantiate1 leftBody fvar)
                          (psExprInstantiate1 rightBody fvar)
                      else
                        { typeResult with context }
                  | _ => psUnifyFailure context
              | .forallE leftName leftType leftBody _ =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .forallE rightName rightType rightBody _ =>
                      let typeResult :=
                        smaller
                          environment
                          localContext
                          context
                          leftType
                          rightType;
                      if typeResult.success then
                        let pushed :=
                          psLocalPushBinding
                            localContext
                            rightName
                            rightType
                            PsBinderInfo.explicit;
                        let fvar := PsExpr.fvar pushed.id;
                        smaller
                          environment
                          pushed.context
                          typeResult.context
                          (psExprInstantiate1 leftBody fvar)
                          (psExprInstantiate1 rightBody fvar)
                      else
                        { typeResult with context }
                  | _ => psUnifyFailure context
              | .letE _ _ _ _ =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | _ => psUnifyFailure context
              | .lit leftLiteral =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .lit rightLiteral =>
                      if psLiteralEq leftLiteral rightLiteral then
                        psUnifySuccess context
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
              | .fvar leftId =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .fvar rightId =>
                      if Nat.beq leftId rightId then
                        psUnifySuccess context
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
              | .bvar leftIndex =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .bvar rightIndex =>
                      if Nat.beq leftIndex rightIndex then
                        psUnifySuccess context
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
              | .proj leftType leftIndex leftProjValue =>
                  match rightValue with
                  | .mvar id =>
                      assign id leftValue
                  | .proj rightType rightIndex rightProjValue =>
                      if psNameEq leftType rightType then
                        if Nat.beq leftIndex rightIndex then
                          smaller
                            environment
                            localContext
                            context
                            leftProjValue
                            rightProjValue
                        else
                          psUnifyFailure context
                      else
                        psUnifyFailure context
                  | _ => psUnifyFailure context
        if attempted.success || attempted.resourceExceeded then attempted else
          match recover with
          | none => attempted
          | some recover =>
            -- Retry from the subcomparison's original snapshot, never from an
            -- unsuccessful congruence branch's speculative assignments.
            match recover context
                (psWhnfWithTransparency transparency environment context localContext left)
                (psWhnfWithTransparency transparency environment context localContext right) with
            | none => attempted
            | some recovered =>
              if recovered.resourceExceeded then { recovered with context } else
              if !recovered.success then attempted else
                let retried := psUnifyWithFuelRecoverWorker (some recover) transparency remaining
                  environment localContext recovered.context left right
                if retried.success then retried else { retried with context }

def psUnifyWithFuelWorker (transparency : PsTransparency) (fuel : Nat) :
    PsEnvironment → PsLocalContext → PsMetaContext → PsExpr → PsExpr → PsUnifyResult :=
  psUnifyWithFuelRecoverWorker none transparency fuel

def psUnifyWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (fuel : Nat)
    (left : PsExpr)
    (right : PsExpr) : PsUnifyResult :=
  psUnifyWithFuelWorker .all
    fuel
    environment
    localContext
    context
    left
    right

def psUnify
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (left : PsExpr)
    (right : PsExpr) : PsUnifyResult :=
  let result :=
    psUnifyWithFuel environment localContext context 512 left right;
  if result.success then result else { result with context }

-- Search restricts delta reduction without changing kernel conversion.
-- Roll back the entire attempt on failure, including universes.
def psUnifyWithTransparency (transparency : PsTransparency)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (left right : PsExpr) : PsUnifyResult :=
  let result := psUnifyWithFuelWorker transparency 512 environment locals context left right
  if result.success then result else { result with context }

-- Only a complete equality commits recovery work. All term and universe
-- assignments, including checked instance evidence, roll back on failure.
def psUnifyWithRecovery
    (recover : PsMetaContext → PsExpr → PsExpr → Option PsUnifyResult)
    (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (left right : PsExpr) : PsUnifyResult :=
  let result := psUnifyWithFuelRecoverWorker (some recover) .all 512
    environment locals context left right
  if result.success then result else { result with context }
