import Ps.KernelCore.Admission.Inductive.Common.Parameters

/-
Ordinary inductive constructor analysis and positivity.

This module opens constructor parameters/fields, identifies recursive arguments,
rejects non-positive or nested occurrences from the ordinary path, checks field
universes, and validates that constructor results return the declared datatype
with the expected parameter/index shape.

Nested recursive occurrences are intentionally delegated to NestedInductive.
-/

structure PsKernelExprSessionResult where
  session : PsKernelCheckerSession
  result : PsKernelExpr

structure PsKernelAddConstructorsResult where
  environment : PsKernelEnvironment
  shapes : List PsKernelSimpleConstructorShape

def psKernelSessionWithEnvironment
    (session : PsKernelCheckerSession)
    (environment : PsKernelEnvironment) :
    PsKernelCheckerSession :=
  PsKernelCheckerSession.mk
    (psKernelCheckerContextWithEnvironment
      session.context
      environment)
    session.state

def psKernelOpenBinderListAppend
    (left : List PsKernelOpenBinder)
    (right : List PsKernelOpenBinder) :
    List PsKernelOpenBinder :=
  match left with
  | List.nil =>
      right
  | List.cons head tail =>
      List.cons
        head
        (psKernelOpenBinderListAppend
          tail
          right)

def psKernelReverseRecursiveFieldsWorker
    (values : List PsKernelSimpleRecursiveField) :
    List PsKernelSimpleRecursiveField ->
    List PsKernelSimpleRecursiveField :=
  match values with
  | List.nil =>
      fun
        (acc : List PsKernelSimpleRecursiveField) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleRecursiveField ->
          List PsKernelSimpleRecursiveField :=
        psKernelReverseRecursiveFieldsWorker tail;
      fun
        (acc : List PsKernelSimpleRecursiveField) =>
        smaller
          (List.cons head acc)

def psKernelReverseRecursiveFields
    (values : List PsKernelSimpleRecursiveField) :
    List PsKernelSimpleRecursiveField :=
  psKernelReverseRecursiveFieldsWorker
    values
    List.nil

def psKernelSimpleCtorNames
    (ctors : List PsKernelSimpleConstructorDecl) :
    List PsKernelName :=
  match ctors with
  | List.nil =>
      List.nil
  | List.cons ctor rest =>
      List.cons
        ctor.name
        (psKernelSimpleCtorNames rest)

def psKernelSimpleCtorTypes
    (ctors : List PsKernelSimpleConstructorDecl) :
    List PsKernelExpr :=
  match ctors with
  | List.nil =>
      List.nil
  | List.cons ctor rest =>
      List.cons
        ctor.type
        (psKernelSimpleCtorTypes rest)

def psKernelOpenSimpleConstructorParamsWithFuel
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    Except String PsKernelExprSessionResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_params : List PsKernelOpenBinder)
        (_type : PsKernelExpr) =>
        Except.error
          "simple inductive constructor parameter budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelOpenSimpleConstructorParamsWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (params : List PsKernelOpenBinder)
        (type : PsKernelExpr) =>
        match params with
        | List.nil =>
            Except.ok
              (PsKernelExprSessionResult.mk
                session
                type)
        | List.cons param rest =>
            match type with
            | PsKernelExpr.forallE _ domain body _ =>
                match
                    psKernelSessionIsDefEq
                      remaining
                      session
                      domain
                      param.type with
                | Except.error error =>
                    Except.error error
                | Except.ok equal =>
                    if Prod.fst equal then
                      smaller
                        (Prod.snd equal)
                        rest
                        (psKernelExprInstantiate1
                          body
                          (PsKernelExpr.fvar
                            param.internalName))
                    else
                      Except.error
                        "simple inductive constructor parameter does not match the datatype parameter"
            | _ =>
                Except.error
                  "simple inductive constructor has fewer parameters than the datatype"

def psKernelOpenSimpleConstructorParams
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr) :
    Except String PsKernelExprSessionResult :=
  psKernelOpenSimpleConstructorParamsWithFuel
    (Nat.succ fuel)
    session
    params
    type

def psKernelConsumeSimpleResultParams
    (params : List PsKernelOpenBinder) :
    List PsKernelExpr ->
    Option (List PsKernelExpr) :=
  match params with
  | List.nil =>
      fun (args : List PsKernelExpr) =>
        Option.some args
  | List.cons param rest =>
      let smaller :
          List PsKernelExpr ->
          Option (List PsKernelExpr) :=
        psKernelConsumeSimpleResultParams rest;
      fun (args : List PsKernelExpr) =>
        match args with
        | List.nil =>
            Option.none
        | List.cons arg tail =>
            if
                psKernelExprEq
                  arg
                  (PsKernelExpr.fvar
                    param.internalName) then
              smaller tail
            else
              Option.none

def psKernelSimpleInductiveAppIndices
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (expr : PsKernelExpr) :
    Option (List PsKernelExpr) :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const resultName resultLevels =>
      if
          if psKernelNameEq resultName target then
            psKernelLevelListEq resultLevels levels
          else
            false then
        match
            psKernelConsumeSimpleResultParams
              params
              (psKernelExprGetAppArgs expr) with
        | Option.none =>
            Option.none
        | Option.some indices =>
            if
                Nat.beq
                  (psKernelExprListLength indices)
                  numIndices then
              Option.some indices
            else
              Option.none
      else
        Option.none
  | _ =>
      Option.none

def psKernelSimpleIndicesContainTarget
    (target : PsKernelName)
    (indices : List PsKernelExpr) : Bool :=
  match indices with
  | List.nil =>
      false
  | List.cons index rest =>
      if psKernelExprContainsConst target index then
        true
      else
        psKernelSimpleIndicesContainTarget
          target
          rest

-- After WHNF, a recursive occurrence beneath a stuck recursor is not a
-- nested inductive family. Lean's positivity check rejects this shape.
-- Keep the unsupported result for other shapes handled by nested admission.
def psKernelSimpleRecursiveOccurrenceDiagnostic
    (environment : PsKernelEnvironment)
    (target : PsKernelName)
    (reduced : PsKernelExpr) : String :=
  if psKernelExprContainsConst target reduced then
    match psKernelExprGetAppFn reduced with
    | PsKernelExpr.const name _ =>
        match psKernelEnvironmentFind environment name with
        | Option.some (PsKernelConstantInfo.recInfo _) =>
            "recursive argument contains the datatype under a stuck recursor"
        | _ =>
            "simple inductive admission does not yet support nested recursive occurrences"
    | _ =>
        "simple inductive admission does not yet support nested recursive occurrences"
  else
    "simple inductive admission does not yet support nested recursive occurrences"

def psKernelAnalyzeSimpleRecursiveArgumentWithFuel
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    Except String PsKernelRecursiveArgumentResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_target : PsKernelName)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_numIndices : Nat)
        (_type : PsKernelExpr)
        (_revArgs : List PsKernelOpenBinder) =>
        Except.error
          "simple inductive recursive-argument budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelAnalyzeSimpleRecursiveArgumentWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (target : PsKernelName)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (numIndices : Nat)
        (type : PsKernelExpr)
        (revArgs : List PsKernelOpenBinder) =>
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reducedResult =>
            let reduced :=
              Prod.fst reducedResult;
            match
                psKernelSimpleInductiveAppIndices
                  target
                  levels
                  params
                  numIndices
                  reduced with
            | Option.some indices =>
                if
                    psKernelSimpleIndicesContainTarget
                      target
                      indices then
                  Except.error
                    "recursive argument index contains a recursive occurrence"
                else
                  Except.ok
                    (PsKernelRecursiveArgumentResult.mk
                      (Prod.snd reducedResult)
                      (Option.some
                        (Prod.mk
                          (psKernelReverseOpenBinders revArgs)
                          indices)))
            | Option.none =>
                match reduced with
                | PsKernelExpr.forallE userName domain body binderInfo =>
                    match
                        psKernelSessionWhnf
                          remaining
                          (Prod.snd reducedResult)
                          domain with
                    | Except.error error =>
                        Except.error error
                    | Except.ok domainReduced =>
                        if
                            if
                                psKernelExprContainsConst
                                  target
                                  domain then
                              true
                            else
                              psKernelExprContainsConst
                                target
                                (Prod.fst domainReduced) then
                          Except.error
                            "recursive function argument contains a negative recursive occurrence"
                        else
                          match
                              psKernelSessionCheck
                                remaining
                                (Prod.snd domainReduced)
                                domain with
                          | Except.error error =>
                              Except.error error
                          | Except.ok domainType =>
                              match
                                  psKernelSessionEnsureSort
                                    remaining
                                    (Prod.snd domainType)
                                    (Prod.fst domainType) with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok sortResult =>
                                  let localDomain :=
                                    psKernelExprConsumeTypeAnnotations
                                      domain;
                                  let localResult :=
                                    psKernelSessionWithLocal
                                      (Prod.snd sortResult)
                                      userName
                                      localDomain
                                      binderInfo;
                                  let fresh :=
                                    Prod.fst localResult;
                                  let arg :=
                                    PsKernelOpenBinder.mk
                                      fresh
                                      userName
                                      localDomain
                                      binderInfo;
                                  smaller
                                    (Prod.snd localResult)
                                    target
                                    levels
                                    params
                                    numIndices
                                    (psKernelExprInstantiate1
                                      body
                                      (PsKernelExpr.fvar fresh))
                                    (List.cons arg revArgs)
                | _ =>
                    if
                        if
                            psKernelExprContainsConst
                              target
                              type then
                          true
                        else
                          psKernelExprContainsConst
                            target
                            reduced then
                      Except.error
                        (psKernelSimpleRecursiveOccurrenceDiagnostic
                          session.context.environment
                          target
                          reduced)
                    else
                      Except.ok
                        (PsKernelRecursiveArgumentResult.mk
                          (Prod.snd reducedResult)
                          Option.none)

def psKernelAnalyzeSimpleRecursiveArgument
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (type : PsKernelExpr) :
    Except String PsKernelRecursiveArgumentResult :=
  psKernelAnalyzeSimpleRecursiveArgumentWithFuel
    (Nat.succ fuel)
    session
    target
    levels
    params
    numIndices
    type
    List.nil

def psKernelOpenSimpleConstructorFieldsWithFuel
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelLevel ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    List PsKernelSimpleRecursiveField ->
    Except String PsKernelOpenFieldsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_target : PsKernelName)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_numIndices : Nat)
        (_resultLevel : PsKernelLevel)
        (_type : PsKernelExpr)
        (_revFields : List PsKernelOpenBinder)
        (_revRecursive : List PsKernelSimpleRecursiveField) =>
        Except.error
          "simple inductive field budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelOpenSimpleConstructorFieldsWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (target : PsKernelName)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (numIndices : Nat)
        (resultLevel : PsKernelLevel)
        (type : PsKernelExpr)
        (revFields : List PsKernelOpenBinder)
        (revRecursive : List PsKernelSimpleRecursiveField) =>
        match type with
        | PsKernelExpr.forallE userName domain body binderInfo =>
            match
                psKernelSessionCheck
                  remaining
                  session
                  domain with
            | Except.error error =>
                Except.error error
            | Except.ok domainType =>
                match
                    psKernelSessionEnsureSort
                      remaining
                      (Prod.snd domainType)
                      (Prod.fst domainType) with
                | Except.error error =>
                    Except.error error
                | Except.ok fieldSort =>
                    if
                        if
                            psKernelLevelLe
                              (Prod.fst fieldSort)
                              resultLevel then
                          true
                        else
                          psKernelLevelNormalizesToZero
                            resultLevel then
                      let localDomain :=
                        psKernelExprConsumeTypeAnnotations
                          domain;
                      let localResult :=
                        psKernelSessionWithLocal
                          (Prod.snd fieldSort)
                          userName
                          localDomain
                          binderInfo;
                      let fresh :=
                        Prod.fst localResult;
                      let field :=
                        PsKernelOpenBinder.mk
                          fresh
                          userName
                          localDomain
                          binderInfo;
                      match
                          psKernelAnalyzeSimpleRecursiveArgument
                            remaining
                            (Prod.snd localResult)
                            target
                            levels
                            params
                            numIndices
                            domain with
                      | Except.error error =>
                          Except.error error
                      | Except.ok analysis =>
                          let child0 :=
                            Prod.snd localResult;
                          let child :=
                            psKernelSessionRestoreLocalScope child0 analysis.session;
                          let nextRecursive :
                              List PsKernelSimpleRecursiveField :=
                            match analysis.recursiveInfo with
                            | Option.none =>
                                revRecursive
                            | Option.some info =>
                                List.cons
                                  (PsKernelSimpleRecursiveField.mk
                                    field
                                    (Prod.fst info)
                                    (Prod.snd info))
                                  revRecursive;
                          smaller
                            child
                            target
                            levels
                            params
                            numIndices
                            resultLevel
                            (psKernelExprInstantiate1
                              body
                              (PsKernelExpr.fvar fresh))
                            (List.cons field revFields)
                            nextRecursive
                    else
                      Except.error
                        "simple inductive constructor field universe is too large"
        | _ =>
            Except.ok
              (PsKernelOpenFieldsResult.mk
                session
                (psKernelReverseOpenBinders revFields)
                (psKernelReverseRecursiveFields revRecursive)
                type)

def psKernelOpenSimpleConstructorFields
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (resultLevel : PsKernelLevel)
    (type : PsKernelExpr) :
    Except String PsKernelOpenFieldsResult :=
  psKernelOpenSimpleConstructorFieldsWithFuel
    (Nat.succ fuel)
    session
    target
    levels
    params
    numIndices
    resultLevel
    type
    List.nil
    List.nil

def psKernelSimpleFieldArgs
    (shape : PsKernelSimpleConstructorShape) :
    List PsKernelExpr :=
  psKernelOpenBinderExprs shape.fields

def psKernelSimpleParamArgs
    (params : List PsKernelOpenBinder) :
    List PsKernelExpr :=
  psKernelOpenBinderExprs params

def psKernelValidateSimpleConstructorResult
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr) :
    Except String (List PsKernelExpr) :=
  match
      psKernelSimpleInductiveAppIndices
        target
        levels
        params
        numIndices
        result with
  | Option.none =>
      Except.error
        "simple inductive constructor must return the declared datatype with matching parameters and index arity"
  | Option.some indices =>
      if
          psKernelSimpleIndicesContainTarget
            target
            indices then
        Except.error
          "simple inductive constructor return index contains a recursive occurrence"
      else
        Except.ok indices
