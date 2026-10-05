import Ps.KernelCore.Environment.Operations
import Ps.KernelCore.Runtime.Capability.Lean434NativeReduction
import Ps.KernelCore.Core.LocalContext
import Ps.KernelCore.Core.Substitution.Abstract
import Ps.KernelCore.Checker.State

def psKernelLeanNatMaxSizeDefault : Nat :=
  Nat.mul
    (Nat.mul 128 1024)
    1024

structure PsKernelCheckerContext where
  environment : PsKernelEnvironment
  localContext : PsKernelLocalContext
  levelParams : List PsKernelName
  safety : PsKernelDefinitionSafety
  eagerReduce : Bool
  nativeEvaluator : Option PsKernelNativeEvaluator
  maxRecDepth : Nat
  maxNatSize : Nat
  recDepth : Nat

def psKernelCheckerContextEmpty
    (environment : PsKernelEnvironment) :
    PsKernelCheckerContext :=
  {
    environment := environment
    localContext := psKernelLocalContextEmpty
    levelParams := List.nil
    safety := PsKernelDefinitionSafety.safe
    eagerReduce := false
    nativeEvaluator := environment.runtime.nativeEvaluator
    maxRecDepth := 0
    maxNatSize := psKernelLeanNatMaxSizeDefault
    recDepth := 0
  }

def psKernelCheckerContextWithEnvironment
    (context : PsKernelCheckerContext)
    (environment : PsKernelEnvironment) :
    PsKernelCheckerContext :=
  {
    environment := environment
    localContext := context.localContext
    levelParams := context.levelParams
    safety := context.safety
    eagerReduce := context.eagerReduce
    nativeEvaluator := context.nativeEvaluator
    maxRecDepth := context.maxRecDepth
    maxNatSize := context.maxNatSize
    recDepth := context.recDepth
  }

def psKernelCheckerContextWithLocalContext
    (context : PsKernelCheckerContext)
    (localContext : PsKernelLocalContext) :
    PsKernelCheckerContext :=
  {
    environment := context.environment
    localContext := localContext
    levelParams := context.levelParams
    safety := context.safety
    eagerReduce := context.eagerReduce
    nativeEvaluator := context.nativeEvaluator
    maxRecDepth := context.maxRecDepth
    maxNatSize := context.maxNatSize
    recDepth := context.recDepth
  }

def psKernelCheckerContextWithEagerReduce
    (context : PsKernelCheckerContext)
    (eagerReduce : Bool) :
    PsKernelCheckerContext :=
  {
    environment := context.environment
    localContext := context.localContext
    levelParams := context.levelParams
    safety := context.safety
    eagerReduce := eagerReduce
    nativeEvaluator := context.nativeEvaluator
    maxRecDepth := context.maxRecDepth
    maxNatSize := context.maxNatSize
    recDepth := context.recDepth
  }

def psKernelCheckerContextWithNativeEvaluator
    (context : PsKernelCheckerContext)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    PsKernelCheckerContext :=
  {
    environment := context.environment
    localContext := context.localContext
    levelParams := context.levelParams
    safety := context.safety
    eagerReduce := context.eagerReduce
    nativeEvaluator := nativeEvaluator
    maxRecDepth := context.maxRecDepth
    maxNatSize := context.maxNatSize
    recDepth := context.recDepth
  }

def psKernelRecDepthFactor : Nat :=
  16

def psKernelCheckerContextEnterRecDepth
    (context : PsKernelCheckerContext) :
    Except String PsKernelCheckerContext :=
  let nextDepth :=
    Nat.succ context.recDepth;
  let limit :=
    Nat.mul
      context.maxRecDepth
      psKernelRecDepthFactor;
  if Nat.beq context.maxRecDepth 0 then
    Except.ok context
  else if psKernelNatGt nextDepth limit then
    Except.error
      "deep recursion detected, use maxRecDepth to increase the limit"
  else
    Except.ok {
      environment := context.environment
      localContext := context.localContext
      levelParams := context.levelParams
      safety := context.safety
      eagerReduce := context.eagerReduce
      nativeEvaluator := context.nativeEvaluator
      maxRecDepth := context.maxRecDepth
      maxNatSize := context.maxNatSize
      recDepth := nextDepth
    }

def psKernelNatName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Nat"

def psKernelStringName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "String"

def psKernelBoolName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Bool"

def psKernelBoolTrueName : PsKernelName :=
  PsKernelName.str
    psKernelBoolName
    "true"

def psKernelBoolFalseName : PsKernelName :=
  PsKernelName.str
    psKernelBoolName
    "false"

def psKernelLeanName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Lean"

def psKernelReduceBoolName : PsKernelName :=
  PsKernelName.str
    psKernelLeanName
    "reduceBool"

def psKernelReduceNatName : PsKernelName :=
  PsKernelName.str
    psKernelLeanName
    "reduceNat"

def psKernelEagerReduceName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "eagerReduce"

def psKernelReduceNative
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Except String (Option PsKernelExpr) :=
  psKernelReduceNativeWith
    context.nativeEvaluator
    psKernelReduceBoolName
    psKernelReduceNatName
    psKernelBoolTrueName
    psKernelBoolFalseName
    expr

def psKernelNatZeroName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "zero"

def psKernelNatSuccName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "succ"

def psKernelNatAddName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "add"

def psKernelNatSubName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "sub"

def psKernelNatMulName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "mul"

def psKernelNatPowName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "pow"

def psKernelNatGcdName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "gcd"

def psKernelNatModName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "mod"

def psKernelNatDivName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "div"

def psKernelNatBeqName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "beq"

def psKernelNatBleName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "ble"

def psKernelNatLandName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "land"

def psKernelNatLorName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "lor"

def psKernelNatXorName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "xor"

def psKernelNatShiftLeftName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "shiftLeft"

def psKernelNatShiftRightName : PsKernelName :=
  PsKernelName.str
    psKernelNatName
    "shiftRight"

def psKernelCharName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Char"

def psKernelListName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "List"

def psKernelListNilName : PsKernelName :=
  PsKernelName.str
    psKernelListName
    "nil"

def psKernelListConsName : PsKernelName :=
  PsKernelName.str
    psKernelListName
    "cons"

def psKernelStringOfListName : PsKernelName :=
  PsKernelName.str
    psKernelStringName
    "ofList"

def psKernelCharOfNatName : PsKernelName :=
  PsKernelName.str
    psKernelCharName
    "ofNat"

def psKernelExprIsEagerReduce
    (expr : PsKernelExpr) : Bool :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name _ =>
      if
          psKernelNameEq
            name
            psKernelEagerReduceName then
        Nat.beq
          (psKernelExprGetAppNumArgs expr)
          2
      else
        false
  | _ =>
      false

def psKernelExprIsNatZero
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.nat value =>
          Nat.beq value 0
      | PsKernelLiteral.str _ =>
          false
  | PsKernelExpr.const name levels =>
      match levels with
      | List.nil =>
          psKernelNameEq
            name
            psKernelNatZeroName
      | List.cons _ _ =>
          false
  | _ =>
      false

def psKernelExprNatPred
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match expr with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.nat value =>
          match value with
          | Nat.zero =>
              Option.none
          | Nat.succ predecessor =>
              Option.some
                (PsKernelExpr.lit
                  (PsKernelLiteral.nat predecessor))
      | PsKernelLiteral.str _ =>
          Option.none
  | _ =>
      let fn :=
        psKernelExprGetAppFn expr;
      match fn with
      | PsKernelExpr.const name levels =>
          match levels with
          | List.nil =>
              if
                  psKernelNameEq
                    name
                    psKernelNatSuccName then
                if
                    Nat.beq
                      (psKernelExprGetAppNumArgs expr)
                      1 then
                  psKernelExprListGet
                    (psKernelExprGetAppArgs expr)
                    0
                else
                  Option.none
              else
                Option.none
          | List.cons _ _ =>
              Option.none
      | _ =>
          Option.none

def psKernelExprNatLiteralValue
    (expr : PsKernelExpr) :
    Option Nat :=
  match expr with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.nat value =>
          Option.some value
      | PsKernelLiteral.str _ =>
          Option.none
  | PsKernelExpr.const name levels =>
      match levels with
      | List.nil =>
          if
              psKernelNameEq
                name
                psKernelNatZeroName then
            Option.some 0
          else
            Option.none
      | List.cons _ _ =>
          Option.none
  | _ =>
      Option.none

def psKernelLeanUInt32Max : Nat :=
  4294967295

def psKernelLeanMaxSmallNat : Nat :=
  9223372036854775807

def psKernelCheckerContextFreshName
    (context : PsKernelCheckerContext)
    (base : PsKernelName) :
    PsKernelName :=
  PsKernelName.num
    base
    context.localContext.nextIndex

def psKernelCheckerContextWithLocal
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Prod PsKernelName PsKernelCheckerContext :=
  let fresh :=
    psKernelCheckerContextFreshName
      context
      userName;
  let nextLocal :=
    psKernelLocalContextAddLocal
      context.localContext
      fresh
      userName
      type
      binderInfo;
  Prod.mk
    fresh
    {
      environment := context.environment
      localContext := nextLocal
      levelParams := context.levelParams
      safety := context.safety
      eagerReduce := context.eagerReduce
      nativeEvaluator := context.nativeEvaluator
      maxRecDepth := context.maxRecDepth
      maxNatSize := context.maxNatSize
      recDepth := context.recDepth
    }

def psKernelCheckerContextWithLet
    (context : PsKernelCheckerContext)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (value : PsKernelExpr) :
    Prod PsKernelName PsKernelCheckerContext :=
  let fresh :=
    psKernelCheckerContextFreshName
      context
      userName;
  let nextLocal :=
    psKernelLocalContextAddLet
      context.localContext
      fresh
      userName
      type
      value;
  Prod.mk
    fresh
    {
      environment := context.environment
      localContext := nextLocal
      levelParams := context.levelParams
      safety := context.safety
      eagerReduce := context.eagerReduce
      nativeEvaluator := context.nativeEvaluator
      maxRecDepth := context.maxRecDepth
      maxNatSize := context.maxNatSize
      recDepth := context.recDepth
    }

structure PsKernelCheckerCloseBinder where
  internalName : PsKernelName
  userName : PsKernelName
  type : PsKernelExpr
  binderInfo : PsKernelBinderInfo
  value : Option PsKernelExpr
  nondep : Bool

def psKernelCloseCheckerBinders
    (binders : List PsKernelCheckerCloseBinder) :
    PsKernelExpr -> Bool -> PsKernelExpr :=
  match binders with
  | List.nil =>
      fun
        (body : PsKernelExpr)
        (_removeDeadLets : Bool) =>
        body
  | List.cons binder rest =>
      let smaller :
          PsKernelExpr -> Bool -> PsKernelExpr :=
        psKernelCloseCheckerBinders rest;
      fun
        (body : PsKernelExpr)
        (removeDeadLets : Bool) =>
        let inner :=
          smaller body removeDeadLets;
        let names :=
          List.cons
            binder.internalName
            List.nil;
        match binder.value with
        | Option.none =>
            PsKernelExpr.forallE
              binder.userName
              binder.type
              (psKernelExprAbstractFVars
                inner
                names)
              binder.binderInfo
        | Option.some value =>
            let abstracted :=
              psKernelExprAbstractFVars
                inner
                names;
            if removeDeadLets then
              if
                  psKernelExprHasLooseBVarAt
                    abstracted
                    0 then
                PsKernelExpr.letE
                  binder.userName
                  binder.type
                  value
                  abstracted
                  binder.nondep
              else
                inner
            else
              PsKernelExpr.letE
                binder.userName
                binder.type
                value
                abstracted
                binder.nondep

def psKernelReduceProjCore
    (context : PsKernelCheckerContext)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    Option PsKernelExpr :=
  if psKernelNatGt index psKernelLeanUInt32Max then
    Option.none
  else
    let fn :=
      psKernelExprGetAppFn structValue;
    let args :=
      psKernelExprGetAppArgs structValue;
    match fn with
    | PsKernelExpr.const ctorName _ =>
        match
            psKernelEnvironmentFind
              context.environment
              ctorName with
        | Option.some info =>
            match info with
            | PsKernelConstantInfo.ctorInfo ctor =>
                if
                    psKernelNameEq
                      ctor.induct
                      typeName then
                  psKernelExprListGet
                    args
                    (Nat.add
                      ctor.numParams
                      index)
                else
                  Option.none
            | _ =>
                Option.none
        | Option.none =>
            Option.none
    | _ =>
        Option.none

def psKernelApplyArgsWorker
    (args : List PsKernelExpr) :
    PsKernelExpr -> PsKernelExpr :=
  match args with
  | List.nil =>
      fun (fn : PsKernelExpr) =>
        fn
  | List.cons arg rest =>
      let smaller :
          PsKernelExpr -> PsKernelExpr :=
        psKernelApplyArgsWorker rest;
      fun (fn : PsKernelExpr) =>
        smaller
          (PsKernelExpr.app fn arg)

def psKernelApplyArgs
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) :
    PsKernelExpr :=
  psKernelApplyArgsWorker
    args
    fn

def psKernelUnfoldDefinition
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  let fn :=
    psKernelExprGetAppFn expr;
  let args :=
    psKernelExprGetAppArgs expr;
  match fn with
  | PsKernelExpr.const name levels =>
      match
          psKernelEnvironmentFind
            context.environment
            name with
      | Option.none =>
          Option.none
      | Option.some info =>
          match
              psKernelConstantInfoDeltaValue info with
          | Option.none =>
              Option.none
          | Option.some value =>
              let params :=
                psKernelConstantInfoLevelParams info;
              if
                  Nat.beq
                    (psKernelNameListLength params)
                    (psKernelLevelListLength levels) then
                Option.some
                  (psKernelApplyArgs
                    (psKernelExprInstantiateLevelParams
                      value
                      params
                      levels)
                    args)
              else
                Option.none
  | _ =>
      Option.none

def psKernelQuotName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Quot"

def psKernelQuotMkName : PsKernelName :=
  PsKernelName.str
    psKernelQuotName
    "mk"

def psKernelQuotLiftName : PsKernelName :=
  PsKernelName.str
    psKernelQuotName
    "lift"

def psKernelQuotIndName : PsKernelName :=
  PsKernelName.str
    psKernelQuotName
    "ind"

inductive PsKernelDeltaResult where
  | decided (value : Bool)
  | residual
      (left : PsKernelExpr)
      (right : PsKernelExpr)

inductive PsKernelDeltaStepResult where
  | continue
      (left : PsKernelExpr)
      (right : PsKernelExpr)
  | unknown
      (left : PsKernelExpr)
      (right : PsKernelExpr)
  | equal
  | different
      (left : PsKernelExpr)
      (right : PsKernelExpr)
