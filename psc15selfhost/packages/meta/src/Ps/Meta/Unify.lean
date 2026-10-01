import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce

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

def psUnifyAssign
    (context : PsMetaContext)
    (id : Nat)
    (value : PsExpr) : PsUnifyResult :=
  if psMetaVarAssignable context id then
    match psMetaAssign context id value with
    | none => psUnifyFailure context
    | some next => psUnifySuccess next
  else
    psUnifyFailure context

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
      let smaller :
          PsEnvironment ->
          PsLocalContext ->
          PsMetaContext ->
          PsExpr ->
          PsExpr ->
          PsUnifyResult :=
        psUnifyWithFuelWorker remaining;
      fun (environment : PsEnvironment)
          (localContext : PsLocalContext)
          (context : PsMetaContext)
          (left : PsExpr)
          (right : PsExpr) =>
        let leftValue := psWhnf environment context localContext left;
        let rightValue := psWhnf environment context localContext right;
        if psExprAlphaEq leftValue rightValue then
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
                        psUnifyAssign context leftId rightValue
                      else
                        psUnifyAssign context rightId leftValue
                    else
                      psUnifyAssign context rightId leftValue
                  else if psMetaVarAssignable context leftId then
                    psUnifyAssign context leftId rightValue
                  else
                    psUnifyAssign context rightId leftValue
              | _ =>
                  psUnifyAssign context leftId rightValue
          | .sortE leftLevel =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
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
                  psUnifyAssign context id leftValue
              | .constE rightName rightLevels =>
                  if psNameEq leftName rightName then
                    psUnifyLevelLists leftLevels context rightLevels
                  else
                    psUnifyFailure context
              | _ => psUnifyFailure context
          | .app leftFn leftArg =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
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
                  psUnifyAssign context id leftValue
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
                  psUnifyAssign context id leftValue
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
                  psUnifyAssign context id leftValue
              | _ => psUnifyFailure context
          | .lit leftLiteral =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
              | .lit rightLiteral =>
                  if psLiteralEq leftLiteral rightLiteral then
                    psUnifySuccess context
                  else
                    psUnifyFailure context
              | _ => psUnifyFailure context
          | .fvar leftId =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
              | .fvar rightId =>
                  if Nat.beq leftId rightId then
                    psUnifySuccess context
                  else
                    psUnifyFailure context
              | _ => psUnifyFailure context
          | .bvar leftIndex =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
              | .bvar rightIndex =>
                  if Nat.beq leftIndex rightIndex then
                    psUnifySuccess context
                  else
                    psUnifyFailure context
              | _ => psUnifyFailure context
          | .proj leftType leftIndex leftProjValue =>
              match rightValue with
              | .mvar id =>
                  psUnifyAssign context id leftValue
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
