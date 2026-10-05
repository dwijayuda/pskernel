import Ps.KernelCore.Checker.Session

/-
Core declaration validation shared by all admission operations.

This module checks universe-parameter discipline, rejects metavariables/free
variables, validates declaration headers as sorts, and checks definition bodies
against their declared types. It does not mutate the global environment.
-/


def psKernelSafetyEq
    (left : PsKernelDefinitionSafety)
    (right : PsKernelDefinitionSafety) : Bool :=
  match left with
  | PsKernelDefinitionSafety.unsafeDef =>
      match right with
      | PsKernelDefinitionSafety.unsafeDef => true
      | _ => false
  | PsKernelDefinitionSafety.safe =>
      match right with
      | PsKernelDefinitionSafety.safe => true
      | _ => false
  | PsKernelDefinitionSafety.partialDef =>
      match right with
      | PsKernelDefinitionSafety.partialDef => true
      | _ => false

def psKernelNameListsEq
    (left : List PsKernelName) :
    List PsKernelName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelNameListsEq leftTail;
      fun (right : List PsKernelName) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelNameEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelNameMember
    (target : PsKernelName)
    (values : List PsKernelName) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelNameEq target head then
        true
      else
        psKernelNameMember target tail

def psKernelFindUndefLevelParam
    (level : PsKernelLevel)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match level with
  | PsKernelLevel.zero =>
      Option.none
  | PsKernelLevel.mvar _ =>
      Option.none
  | PsKernelLevel.param name =>
      if psKernelNameMember name allowed then
        Option.none
      else
        Option.some name
  | PsKernelLevel.succ inner =>
      psKernelFindUndefLevelParam
        inner
        allowed
  | PsKernelLevel.max left right =>
      match
          psKernelFindUndefLevelParam
            left
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefLevelParam
            right
            allowed
  | PsKernelLevel.imax left right =>
      match
          psKernelFindUndefLevelParam
            left
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefLevelParam
            right
            allowed

def psKernelFindUndefInLevels
    (levels : List PsKernelLevel)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match levels with
  | List.nil =>
      Option.none
  | List.cons head tail =>
      match
          psKernelFindUndefLevelParam
            head
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefInLevels
            tail
            allowed

def psKernelFindUndefExprLevelParam
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match expr with
  | PsKernelExpr.sort level =>
      psKernelFindUndefLevelParam
        level
        allowed
  | PsKernelExpr.const _ levels =>
      psKernelFindUndefInLevels
        levels
        allowed
  | PsKernelExpr.app fn arg =>
      match
          psKernelFindUndefExprLevelParam
            fn
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            arg
            allowed
  | PsKernelExpr.lam _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.forallE _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.letE _ type value body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          match
              psKernelFindUndefExprLevelParam
                value
                allowed with
          | Option.some name =>
              Option.some name
          | Option.none =>
              psKernelFindUndefExprLevelParam
                body
                allowed
  | PsKernelExpr.mdata _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | PsKernelExpr.proj _ _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | _ =>
      Option.none

def psKernelLevelHasMVar
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.mvar _ =>
      true
  | PsKernelLevel.succ inner =>
      psKernelLevelHasMVar inner
  | PsKernelLevel.max left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | PsKernelLevel.imax left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | _ =>
      false

def psKernelLevelsHaveMVar
    (levels : List PsKernelLevel) : Bool :=
  match levels with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelLevelHasMVar head then
        true
      else
        psKernelLevelsHaveMVar tail

def psKernelExprHasMVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.sort level =>
      psKernelLevelHasMVar level
  | PsKernelExpr.const _ levels =>
      psKernelLevelsHaveMVar levels
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVar fn then
        true
      else
        psKernelExprHasMVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVar type then
        true
      else if psKernelExprHasMVar value then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVar body
  | _ =>
      false

def psKernelCheckNoMVarNoFVar
    (expr : PsKernelExpr) :
    Except String Unit :=
  if psKernelExprHasMVar expr then
    Except.error
      "declaration has metavariables"
  else if psKernelExprHasFVar expr then
    Except.error
      "declaration has free variables"
  else
    Except.ok ()

def psKernelCheckLevelParams
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Except String Unit :=
  match
      psKernelFindUndefExprLevelParam
        expr
        allowed with
  | Option.some _ =>
      Except.error
        "invalid reference to undefined universe level parameter"
  | Option.none =>
      Except.ok ()

def psKernelCheckConstantBaseWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (base : PsKernelConstantBase) :
    Except String PsKernelCheckerSession :=
  if
      psKernelEnvironmentContains
        session.context.environment
        base.name then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        base.levelParams then
    Except.error
      "duplicate universe parameter"
  else
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match
            psKernelCheckLevelParams
              base.type
              base.levelParams with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  base.type with
            | Except.error error =>
                Except.error error
            | Except.ok typeType =>
                match
                    psKernelSessionEnsureSort
                      fuel
                      (Prod.snd typeType)
                      (Prod.fst typeType) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.snd result)

def psKernelCheckDefinitionBodyWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo) :
    Except String PsKernelCheckerSession :=
  match psKernelCheckNoMVarNoFVar value.value with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSessionCheck
                fuel
                session
                value.value with
          | Except.error error =>
              Except.error error
          | Except.ok valueType =>
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd valueType)
                    (Prod.fst valueType)
                    value.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    Except.ok
                      (Prod.snd equal)
                  else
                    Except.error
                      "definition type mismatch"
