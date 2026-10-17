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
        if !checked.success then { checked with context } else
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
          let flexible := psUnifyFlexible assign context
            (psWhnfCore context localContext left) (psWhnfCore context localContext right)
          match flexible.orElse (fun _ =>
            psUnifyRigidApplication (smaller environment localContext)
              context localContext left right) with
          | some result => result
          | none =>
            let leftValue := psWhnfWithTransparency transparency environment context localContext left;
            let rightValue := psWhnfWithTransparency transparency environment context localContext right;
            if psExprAlphaEq leftValue rightValue then
              psUnifySuccess context
            else if psUnifyGroundProofIrrelevance transparency environment localContext context leftValue rightValue then
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
