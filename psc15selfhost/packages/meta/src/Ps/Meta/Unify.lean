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

def psUnifyWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext) :
    Nat -> PsExpr -> PsExpr -> PsUnifyResult
  | 0, _, _ => psUnifyFailure context
  | fuel + 1, left, right =>
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
            | rightOther =>
                psUnifyAssign context leftId rightOther
        | leftOther =>
            match rightValue with
            | .mvar id =>
                psUnifyAssign context id leftOther
            | rightOther =>
                match leftOther with
                | .sortE leftLevel =>
                    match rightOther with
                    | .sortE rightLevel =>
                        let unified := psLevelUnify context.levels leftLevel rightLevel;
                        if unified.success then
                          psUnifySuccess (psMetaSetLevels context unified.context)
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .constE leftName leftLevels =>
                    match rightOther with
                    | .constE rightName rightLevels =>
                        if psNameEq leftName rightName then
                          psUnifyLevelLists leftLevels context rightLevels
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .app leftFn leftArg =>
                    match rightOther with
                    | .app rightFn rightArg =>
                        let fnResult :=
                          psUnifyWithFuel
                            environment
                            localContext
                            context
                            fuel
                            leftFn
                            rightFn;
                        if fnResult.success then
                          psUnifyWithFuel
                            environment
                            localContext
                            fnResult.context
                            fuel
                            leftArg
                            rightArg
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .lam leftName leftType leftBody _ =>
                    match rightOther with
                    | .lam rightName rightType rightBody _ =>
                        let typeResult :=
                          psUnifyWithFuel
                            environment
                            localContext
                            context
                            fuel
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
                          psUnifyWithFuel
                            environment
                            pushed.context
                            typeResult.context
                            fuel
                            (psExprInstantiate1 leftBody fvar)
                            (psExprInstantiate1 rightBody fvar)
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .forallE leftName leftType leftBody _ =>
                    match rightOther with
                    | .forallE rightName rightType rightBody _ =>
                        let typeResult :=
                          psUnifyWithFuel
                            environment
                            localContext
                            context
                            fuel
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
                          psUnifyWithFuel
                            environment
                            pushed.context
                            typeResult.context
                            fuel
                            (psExprInstantiate1 leftBody fvar)
                            (psExprInstantiate1 rightBody fvar)
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .lit leftLiteral =>
                    match rightOther with
                    | .lit rightLiteral =>
                        if psLiteralEq leftLiteral rightLiteral then
                          psUnifySuccess context
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .fvar leftId =>
                    match rightOther with
                    | .fvar rightId =>
                        if Nat.beq leftId rightId then
                          psUnifySuccess context
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .bvar leftIndex =>
                    match rightOther with
                    | .bvar rightIndex =>
                        if Nat.beq leftIndex rightIndex then
                          psUnifySuccess context
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | .proj leftType leftIndex leftValue =>
                    match rightOther with
                    | .proj rightType rightIndex rightValue =>
                        if psNameEq leftType rightType then
                          if Nat.beq leftIndex rightIndex then
                            psUnifyWithFuel
                              environment
                              localContext
                              context
                              fuel
                              leftValue
                              rightValue
                          else
                            psUnifyFailure context
                        else
                          psUnifyFailure context
                    | _ => psUnifyFailure context
                | _ => psUnifyFailure context

def psUnify
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (left : PsExpr)
    (right : PsExpr) : PsUnifyResult :=
  let result :=
    psUnifyWithFuel environment localContext context 512 left right;
  if result.success then result else psUnifyFailure context
