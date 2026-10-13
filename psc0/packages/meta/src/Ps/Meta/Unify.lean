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

-- Assignment solves the candidate's type constraints as well as its value.
-- In particular ?A : Sort ?u := Nat must constrain ?u to 1; scope/occurs
-- checks alone would leave polymorphic constants with unresolved universes.
def psUnifyAssign
    (unifyTypes : PsMetaContext -> PsExpr -> PsExpr -> PsUnifyResult)
    (environment : PsEnvironment) (localContext : PsLocalContext)
    (context : PsMetaContext) (id : Nat) (value : PsExpr) : PsUnifyResult :=
  if !psMetaVarAssignable context id then psUnifyFailure context else
    match psMetaFindDecl context id with
    | none => psUnifyFailure context
    | some declaration =>
      match psInferType environment context localContext (psMetaInstantiate context value) with
      | .error _ => psUnifyFailure context
      | .ok type =>
        let checked := unifyTypes context declaration.type type
        if !checked.success then psUnifyFailure context else
          match psMetaAssign checked.context id value with
          | none => psUnifyFailure context
          | some next => psUnifySuccess next

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
def psUnifyGroundProofIrrelevance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (left right : PsExpr) : Bool :=
  if psExprHasUnresolvedMeta left || psExprHasUnresolvedMeta right then false else
  match psInferType environment context localContext left,
        psInferType environment context localContext right with
  | .ok leftType, .ok rightType =>
    if psExprHasUnresolvedMeta leftType ||
        psExprHasUnresolvedMeta rightType ||
        !psDefEqReadOnlyWithEnv environment context localContext leftType rightType then
      false
    else
      match psInferType environment context localContext leftType with
      | .ok sort =>
        match psWhnf environment context localContext sort with
        | .sortE level => psLevelEquivalent level .zero
        | _ => false
      | .error _ => false
  | _, _ => false

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
  let levels := psUnifyLevelLists leftLevels context rightLevels
  if !levels.success then none else
  let result := (left.args.zip right.args).foldl (fun current (a, b) =>
    if current.success then unify current.context a b else current) levels
  if result.success then some result else none

def psUnifyWithFuelWorker
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
        let smaller :
            PsEnvironment ->
            PsLocalContext ->
            PsMetaContext ->
            PsExpr ->
            PsExpr ->
            PsUnifyResult :=
          psUnifyWithFuelWorker remaining;
        let assign : Nat -> PsExpr -> PsUnifyResult :=
          psUnifyAssign (smaller environment localContext) environment localContext context;
        match psUnifyRigidApplication (smaller environment localContext)
            context localContext left right with
        | some result => result
        | none =>
          let leftValue := psWhnf environment context localContext left;
          let rightValue := psWhnf environment context localContext right;
          if psExprAlphaEq leftValue rightValue then
            psUnifySuccess context
          else if psUnifyGroundProofIrrelevance environment localContext context leftValue rightValue then
            psUnifySuccess context
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
                      psUnifyFailure context
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
                      psUnifyFailure context
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
                      psUnifyFailure context
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

def psUnifyWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (fuel : Nat)
    (left : PsExpr)
    (right : PsExpr) : PsUnifyResult :=
  psUnifyWithFuelWorker
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
  if result.success then result else psUnifyFailure context
