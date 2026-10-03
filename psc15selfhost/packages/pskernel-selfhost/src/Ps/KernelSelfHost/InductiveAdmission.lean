import Ps.KernelSelfHost.Inductive

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
            match
                psKernelSessionWhnf
                  remaining
                  session
                  type with
            | Except.error error =>
                Except.error error
            | Except.ok reduced =>
                match Prod.fst reduced with
                | PsKernelExpr.forallE _ domain body _ =>
                    match
                        psKernelSessionIsDefEq
                          remaining
                          (Prod.snd reduced)
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

def psKernelAnalyzeSimpleRecursiveArgumentWithFuel
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
                        "simple inductive admission does not yet support nested recursive occurrences"
                    else
                      Except.ok
                        (PsKernelRecursiveArgumentResult.mk
                          (Prod.snd reducedResult)
                          Option.none)

def psKernelAnalyzeSimpleRecursiveArgument
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
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reducedResult =>
            match Prod.fst reducedResult with
            | PsKernelExpr.forallE userName domain body binderInfo =>
                match
                    psKernelSessionCheck
                      remaining
                      (Prod.snd reducedResult)
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
                              let analysisLocal :=
                                analysis.session.context.localContext;
                              let continuationLocal :=
                                PsKernelLocalContext.mk
                                  child0.context.localContext.decls
                                  analysisLocal.nextIndex;
                              let child :=
                                PsKernelCheckerSession.mk
                                  (psKernelCheckerContextWithLocalContext
                                    child0.context
                                    continuationLocal)
                                  analysis.session.state;
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
                    (Prod.snd reducedResult)
                    (psKernelReverseOpenBinders revFields)
                    (psKernelReverseRecursiveFields revRecursive)
                    (Prod.fst reducedResult))

def psKernelOpenSimpleConstructorFields
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

def psKernelSimpleMotiveApp
    (motive : PsKernelExpr)
    (indices : List PsKernelExpr)
    (major : PsKernelExpr) :
    PsKernelExpr :=
  psKernelApplyArgs
    motive
    (psKernelExprListAppend
      indices
      (List.cons major List.nil))

def psKernelSimpleCtorApp
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (shape : PsKernelSimpleConstructorShape) :
    PsKernelExpr :=
  psKernelApplyArgs
    (PsKernelExpr.const
      shape.ctor.name
      levels)
    (psKernelExprListAppend
      (psKernelSimpleParamArgs params)
      (psKernelSimpleFieldArgs shape))

def psKernelBindOpenLambdas
    (binders : List PsKernelOpenBinder)
    (body : PsKernelExpr) :
    PsKernelExpr :=
  psKernelCloseOpenLambdas
    binders
    body

def psKernelMakeSimpleIHBindersWorker
    (fields : List PsKernelSimpleRecursiveField) :
    PsKernelExpr -> Nat -> List PsKernelOpenBinder :=
  match fields with
  | List.nil =>
      fun
        (_motive : PsKernelExpr)
        (_index : Nat) =>
        List.nil
  | List.cons recursive rest =>
      let smaller :
          PsKernelExpr ->
          Nat ->
          List PsKernelOpenBinder :=
        psKernelMakeSimpleIHBindersWorker rest;
      fun
        (motive : PsKernelExpr)
        (index : Nat) =>
        let internalName :=
          PsKernelName.num
            (psKernelSimpleInternalName "ih")
            index;
        let appliedField :=
          psKernelApplyArgs
            (PsKernelExpr.fvar
              recursive.field.internalName)
            (psKernelOpenBinderExprs
              recursive.args);
        let binder :=
          PsKernelOpenBinder.mk
            internalName
            (psKernelNameAppendAfter
              recursive.field.userName
              "_ih")
            (psKernelCloseOpenBinders
              recursive.args
              (psKernelSimpleMotiveApp
                motive
                recursive.indices
                appliedField))
            PsKernelBinderInfo.default;
        List.cons
          binder
          (smaller
            motive
            (Nat.succ index))

def psKernelMakeSimpleIHBindersWithIndex
    (motive : PsKernelExpr)
    (fields : List PsKernelSimpleRecursiveField)
    (index : Nat) :
    List PsKernelOpenBinder :=
  psKernelMakeSimpleIHBindersWorker
    fields
    motive
    index

def psKernelMakeSimpleIHBinders
    (motive : PsKernelExpr)
    (shape : PsKernelSimpleConstructorShape) :
    List PsKernelOpenBinder :=
  psKernelMakeSimpleIHBindersWithIndex
    motive
    shape.recursiveFields
    0

def psKernelSimpleHasRecursiveFields
    (shapes : List PsKernelSimpleConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      match shape.recursiveFields with
      | List.nil =>
          psKernelSimpleHasRecursiveFields rest
      | List.cons _ _ =>
          true

def psKernelSimpleRecursiveFieldsHaveArgs
    (fields : List PsKernelSimpleRecursiveField) :
    Bool :=
  match fields with
  | List.nil =>
      false
  | List.cons field rest =>
      match field.args with
      | List.nil =>
          psKernelSimpleRecursiveFieldsHaveArgs rest
      | List.cons _ _ =>
          true

def psKernelSimpleHasReflexiveFields
    (shapes : List PsKernelSimpleConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      if
          psKernelSimpleRecursiveFieldsHaveArgs
            shape.recursiveFields then
        true
      else
        psKernelSimpleHasReflexiveFields rest

def psKernelMakeSimpleMinorBindersWorker
    (shapes : List PsKernelSimpleConstructorShape) :
    PsKernelExpr ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    Nat ->
    List PsKernelOpenBinder :=
  match shapes with
  | List.nil =>
      fun
        (_motive : PsKernelExpr)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_index : Nat) =>
        List.nil
  | List.cons shape rest =>
      let smaller :
          PsKernelExpr ->
          List PsKernelLevel ->
          List PsKernelOpenBinder ->
          Nat ->
          List PsKernelOpenBinder :=
        psKernelMakeSimpleMinorBindersWorker rest;
      fun
        (motive : PsKernelExpr)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (index : Nat) =>
        let internalName :=
          PsKernelName.num
            (psKernelSimpleInternalName "minor")
            index;
        let ihBinders :=
          psKernelMakeSimpleIHBinders
            motive
            shape;
        let allBinders :=
          psKernelOpenBinderListAppend
            shape.fields
            ihBinders;
        let binder :=
          PsKernelOpenBinder.mk
            internalName
            shape.ctor.name
            (psKernelCloseOpenBinders
              allBinders
              (psKernelSimpleMotiveApp
                motive
                shape.resultIndices
                (psKernelSimpleCtorApp
                  levels
                  params
                  shape)))
            PsKernelBinderInfo.default;
        List.cons
          binder
          (smaller
            motive
            levels
            params
            (Nat.succ index))

def psKernelMakeSimpleMinorBindersWithIndex
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape)
    (index : Nat) :
    List PsKernelOpenBinder :=
  psKernelMakeSimpleMinorBindersWorker
    shapes
    motive
    levels
    params
    index

def psKernelMakeSimpleMinorBinders
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape) :
    List PsKernelOpenBinder :=
  psKernelMakeSimpleMinorBindersWithIndex
    motive
    levels
    params
    shapes
    0

def psKernelOpenBinderListLength
    (values : List PsKernelOpenBinder) : Nat :=
  match values with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelOpenBinderListLength rest)

def psKernelMakeSimpleRecursiveCallsWorker
    (fields : List PsKernelSimpleRecursiveField) :
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelExpr ->
    List PsKernelExpr :=
  match fields with
  | List.nil =>
      fun
        (_recName : PsKernelName)
        (_recLevels : List PsKernelLevel)
        (_fixed : List PsKernelExpr) =>
        List.nil
  | List.cons recursive rest =>
      let smaller :=
        psKernelMakeSimpleRecursiveCallsWorker rest;
      fun
        (recName : PsKernelName)
        (recLevels : List PsKernelLevel)
        (fixed : List PsKernelExpr) =>
        let appliedField :=
          psKernelApplyArgs
            (PsKernelExpr.fvar
              recursive.field.internalName)
            (psKernelOpenBinderExprs
              recursive.args);
        let callArgs :=
          psKernelExprListAppend
            fixed
            (psKernelExprListAppend
              recursive.indices
              (List.cons
                appliedField
                List.nil));
        let recursiveCall :=
          psKernelApplyArgs
            (PsKernelExpr.const
              recName
              recLevels)
            callArgs;
        List.cons
          (psKernelCloseOpenLambdas
            recursive.args
            recursiveCall)
          (smaller
            recName
            recLevels
            fixed)

def psKernelMakeSimpleRecursiveCalls
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (minors : List PsKernelOpenBinder)
    (shape : PsKernelSimpleConstructorShape) :
    List PsKernelExpr :=
  let fixed :=
    psKernelExprListAppend
      (psKernelSimpleParamArgs params)
      (List.cons
        motive
        (psKernelOpenBinderExprs minors));
  psKernelMakeSimpleRecursiveCallsWorker
    shape.recursiveFields
    recName
    recLevels
    fixed

def psKernelMakeSimpleRecursorRules
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (allMinors : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape)
    (minors : List PsKernelOpenBinder) :
    List PsKernelRecursorRule :=
  match shapes with
  | List.nil =>
      List.nil
  | List.cons shape shapeRest =>
      match minors with
      | List.nil =>
          List.nil
      | List.cons minor minorRest =>
          let recursiveCalls :=
            psKernelMakeSimpleRecursiveCalls
              recName
              recLevels
              params
              motive
              allMinors
              shape;
          let args :=
            psKernelExprListAppend
              (psKernelSimpleFieldArgs shape)
              recursiveCalls;
          let body :=
            psKernelApplyArgs
              (PsKernelExpr.fvar
                minor.internalName)
              args;
          let binders :=
            psKernelOpenBinderListAppend
              ruleBinders
              shape.fields;
          List.cons
            (PsKernelRecursorRule.mk
              shape.ctor.name
              (psKernelOpenBinderListLength
                shape.fields)
              (psKernelCloseOpenLambdas
                binders
                body))
            (psKernelMakeSimpleRecursorRules
              recName
              recLevels
              params
              motive
              allMinors
              ruleBinders
              shapeRest
              minorRest)

def psKernelValidateSimpleRecursorRules
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape)
    (rules : List PsKernelRecursorRule) :
    Except String Unit :=
  match shapes with
  | List.nil =>
      match rules with
      | List.nil => Except.ok ()
      | List.cons _ _ =>
          Except.error
            "generated simple recursor rule count mismatch"
  | List.cons shape shapeRest =>
      match rules with
      | List.nil =>
          Except.error
            "generated simple recursor rule count mismatch"
      | List.cons rule ruleRest =>
          match
              psKernelSessionCheck
                fuel
                session
                rule.rhs with
          | Except.error error =>
              Except.error error
          | Except.ok gotType =>
              let binders :=
                psKernelOpenBinderListAppend
                  ruleBinders
                  shape.fields;
              let expectedType :=
                psKernelCloseOpenBinders
                  binders
                  (psKernelSimpleMotiveApp
                    motive
                    shape.resultIndices
                    (psKernelSimpleCtorApp
                      levels
                      params
                      shape));
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd gotType)
                    (Prod.fst gotType)
                    expectedType with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    psKernelValidateSimpleRecursorRules
                      fuel
                      (Prod.snd equal)
                      params
                      ruleBinders
                      motive
                      levels
                      shapeRest
                      ruleRest
                  else
                    Except.error
                      "generated simple recursor rule is not type preserving"

def psKernelSimpleExprMember
    (needle : PsKernelExpr)
    (values : List PsKernelExpr) :
    Bool :=
  match values with
  | List.nil =>
      false
  | List.cons item rest =>
      if psKernelExprEq needle item then
        true
      else
        psKernelSimpleExprMember
          needle
          rest

def psKernelSimpleAllExprsMember
    (values : List PsKernelExpr)
    (haystack : List PsKernelExpr) :
    Bool :=
  match values with
  | List.nil =>
      true
  | List.cons item rest =>
      if psKernelSimpleExprMember item haystack then
        psKernelSimpleAllExprsMember
          rest
          haystack
      else
        false

def psKernelSimpleCtorAllowsLargeElimWithFuel
    (fuel : Nat) :
    PsKernelCheckerSession ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Except String Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_type : PsKernelExpr)
        (_revNonProp : List PsKernelExpr) =>
        Except.error
          "simple inductive elimination budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleCtorAllowsLargeElimWithFuel remaining;
      fun
        (session : PsKernelCheckerSession)
        (type : PsKernelExpr)
        (revNonProp : List PsKernelExpr) =>
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            match Prod.fst reduced with
            | PsKernelExpr.forallE userName domain body binderInfo =>
                match
                    psKernelSessionCheck
                      remaining
                      (Prod.snd reduced)
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
                    | Except.ok fieldLevel =>
                        let localDomain :=
                          psKernelExprConsumeTypeAnnotations
                            domain;
                        let localResult :=
                          psKernelSessionWithLocal
                            (Prod.snd fieldLevel)
                            userName
                            localDomain
                            binderInfo;
                        let fresh :=
                          Prod.fst localResult;
                        let nextNonProp :=
                          if
                              psKernelLevelNormalizesToZero
                                (Prod.fst fieldLevel) then
                            revNonProp
                          else
                            List.cons
                              (PsKernelExpr.fvar fresh)
                              revNonProp;
                        smaller
                          (Prod.snd localResult)
                          (psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh))
                          nextNonProp
            | _ =>
                let resultArgs :=
                  psKernelExprGetAppArgs
                    (Prod.fst reduced);
                Except.ok
                  (psKernelSimpleAllExprsMember
                    revNonProp
                    resultArgs)

def psKernelSimpleCtorAllowsLargeElim
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr) :
    Except String Bool :=
  match
      psKernelOpenSimpleConstructorParams
        fuel
        session
        params
        type with
  | Except.error error =>
      Except.error error
  | Except.ok afterParams =>
      psKernelSimpleCtorAllowsLargeElimWithFuel
        (Nat.succ fuel)
        afterParams.session
        afterParams.result
        List.nil

def psKernelSimpleElimOnlyAtZero
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (ctors : List PsKernelSimpleConstructorDecl) :
    Except String Bool :=
  if psKernelLevelIsNotZero resultLevel then
    Except.ok false
  else
    match ctors with
    | List.nil =>
        Except.ok false
    | List.cons ctor rest =>
        match rest with
        | List.nil =>
            match
                psKernelSimpleCtorAllowsLargeElim
                  fuel
                  session
                  params
                  ctor.type with
            | Except.error error =>
                Except.error error
            | Except.ok canLarge =>
                if canLarge then
                  Except.ok false
                else
                  Except.ok true
        | List.cons _ _ =>
            Except.ok true

def psKernelSimpleKTarget
    (resultLevel : PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape) :
    Bool :=
  if psKernelLevelNormalizesToZero resultLevel then
    match shapes with
    | List.cons shape rest =>
        match rest with
        | List.nil =>
            match shape.fields with
            | List.nil => true
            | List.cons _ _ => false
        | List.cons _ _ => false
    | List.nil => false
  else
    false

def psKernelAddSimpleConstructorsWithFuel
    (fuel : Nat) :
    PsKernelSimpleInductiveDecl ->
    PsKernelDefinitionSafety ->
    PsKernelLevel ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelCheckerSession ->
    PsKernelEnvironment ->
    Nat ->
    List PsKernelSimpleConstructorDecl ->
    Except String PsKernelAddConstructorsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_decl : PsKernelSimpleInductiveDecl)
        (_safety : PsKernelDefinitionSafety)
        (_resultLevel : PsKernelLevel)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_numIndices : Nat)
        (_headerSession : PsKernelCheckerSession)
        (_work : PsKernelEnvironment)
        (_index : Nat)
        (_ctors : List PsKernelSimpleConstructorDecl) =>
        Except.error
          "simple inductive constructor admission budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelAddSimpleConstructorsWithFuel remaining;
      fun
        (decl : PsKernelSimpleInductiveDecl)
        (safety : PsKernelDefinitionSafety)
        (resultLevel : PsKernelLevel)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (numIndices : Nat)
        (headerSession : PsKernelCheckerSession)
        (work : PsKernelEnvironment)
        (index : Nat)
        (ctors : List PsKernelSimpleConstructorDecl) =>
        match ctors with
        | List.nil =>
            Except.ok
              (PsKernelAddConstructorsResult.mk
                work
                List.nil)
        | List.cons ctor rest =>
            match psKernelCheckNoMVarNoFVar ctor.type with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                match
                    psKernelCheckLevelParams
                      ctor.type
                      decl.levelParams with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    let closedSession :=
                      psKernelMkCheckerSession
                        work
                        decl.levelParams
                        safety
                        headerSession.context.maxRecDepth
                        headerSession.context.maxNatSize;
                    match
                        psKernelSessionCheck
                          remaining
                          closedSession
                          ctor.type with
                    | Except.error error =>
                        Except.error error
                    | Except.ok ctorType =>
                        match
                            psKernelSessionEnsureSort
                              remaining
                              (Prod.snd ctorType)
                              (Prod.fst ctorType) with
                        | Except.error error =>
                            Except.error error
                        | Except.ok _ =>
                            let ctorSession :=
                              psKernelSessionWithEnvironment
                                headerSession
                                work;
                            match
                                psKernelOpenSimpleConstructorParams
                                  remaining
                                  ctorSession
                                  params
                                  ctor.type with
                            | Except.error error =>
                                Except.error error
                            | Except.ok afterParams =>
                                match
                                    psKernelOpenSimpleConstructorFields
                                      remaining
                                      afterParams.session
                                      decl.name
                                      levels
                                      params
                                      numIndices
                                      resultLevel
                                      afterParams.result with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok fieldsResult =>
                                    match
                                        psKernelValidateSimpleConstructorResult
                                          decl.name
                                          levels
                                          params
                                          numIndices
                                          fieldsResult.result with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok resultIndices =>
                                        let ctorInfo :=
                                          PsKernelConstructorInfo.mk
                                            (PsKernelConstantBase.mk
                                              ctor.name
                                              decl.levelParams
                                              ctor.type)
                                            decl.name
                                            index
                                            decl.numParams
                                            (psKernelOpenBinderListLength
                                              fieldsResult.fields)
                                            decl.isUnsafe;
                                        let nextWork :=
                                          psKernelEnvironmentAddUnchecked
                                            work
                                            (PsKernelConstantInfo.ctorInfo
                                              ctorInfo);
                                        match
                                            smaller
                                              decl
                                              safety
                                              resultLevel
                                              levels
                                              params
                                              numIndices
                                              headerSession
                                              nextWork
                                              (Nat.succ index)
                                              rest with
                                        | Except.error error =>
                                            Except.error error
                                        | Except.ok tailResult =>
                                            let shape :=
                                              PsKernelSimpleConstructorShape.mk
                                                ctor
                                                fieldsResult.fields
                                                fieldsResult.recursiveFields
                                                resultIndices;
                                            Except.ok
                                              (PsKernelAddConstructorsResult.mk
                                                tailResult.environment
                                                (List.cons
                                                  shape
                                                  tailResult.shapes))

def psKernelCheckFreshInductiveNames
    (names : List PsKernelName) :
    PsKernelEnvironment -> Except String Unit :=
  match names with
  | List.nil =>
      fun (_environment : PsKernelEnvironment) =>
        Except.ok ()
  | List.cons name rest =>
      let smaller :
          PsKernelEnvironment -> Except String Unit :=
        psKernelCheckFreshInductiveNames rest;
      fun (environment : PsKernelEnvironment) =>
        if
            psKernelEnvironmentContains
              environment
              name then
          Except.error
            "inductive declaration name is already declared"
        else
          smaller environment

def psKernelAddSimpleInductive
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  if psKernelNameHasDuplicates decl.levelParams then
    Except.error "duplicate universe parameter"
  else
    let recName :=
      psKernelSimpleRecName decl.name;
    let allNames :=
      List.cons
        decl.name
        (List.cons
          recName
          (psKernelSimpleCtorNames decl.ctors));
    if
        psKernelSimpleNameListUnique
          allNames then
      match
          psKernelCheckFreshInductiveNames
            allNames
            environment with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSimpleCheckUniformOccurrences
                (List.cons decl.name List.nil)
                decl.levelParams
                decl.numParams
                (psKernelSimpleCtorTypes decl.ctors) with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match psKernelCheckNoMVarNoFVar decl.type with
              | Except.error error =>
                  Except.error error
              | Except.ok _ =>
                  match
                      psKernelCheckLevelParams
                        decl.type
                        decl.levelParams with
                  | Except.error error =>
                      Except.error error
                  | Except.ok _ =>
                      let safety :=
                        if decl.isUnsafe then
                          PsKernelDefinitionSafety.unsafeDef
                        else
                          PsKernelDefinitionSafety.safe;
                      let headerSession0 :=
                        psKernelMkCheckerSession
                          environment
                          decl.levelParams
                          safety
                          maxRecDepth
                          maxNatSize;
                      match
                          psKernelSessionCheck
                            fuel
                            headerSession0
                            decl.type with
                      | Except.error error =>
                          Except.error error
                      | Except.ok headerType =>
                          match
                              psKernelSessionEnsureSort
                                fuel
                                (Prod.snd headerType)
                                (Prod.fst headerType) with
                          | Except.error error =>
                              Except.error error
                          | Except.ok headerSort =>
                              match
                                  psKernelOpenSimpleHeaderParams
                                    fuel
                                    (Prod.snd headerSort)
                                    decl.type
                                    decl.numParams with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok paramResult =>
                                  match
                                      psKernelOpenSimpleHeaderIndices
                                        fuel
                                        paramResult.session
                                        paramResult.result with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok indexResult =>
                                      match indexResult.result with
                                      | PsKernelExpr.sort resultLevel =>
                                          let params :=
                                            paramResult.binders;
                                          let indices :=
                                            indexResult.binders;
                                          let levels :=
                                            psKernelLevelParamsToLevels
                                              decl.levelParams;
                                          let paramArgs :=
                                            psKernelSimpleParamArgs params;
                                          let indexArgs :=
                                            psKernelOpenBinderExprs indices;
                                          let inductExpr :=
                                            psKernelApplyArgs
                                              (PsKernelExpr.const
                                                decl.name
                                                levels)
                                              (psKernelExprListAppend
                                                paramArgs
                                                indexArgs);
                                          let initialInfo :=
                                            PsKernelInductiveInfo.mk
                                              (PsKernelConstantBase.mk
                                                decl.name
                                                decl.levelParams
                                                decl.type)
                                              decl.numParams
                                              (psKernelOpenBinderListLength
                                                indices)
                                              (List.cons
                                                decl.name
                                                List.nil)
                                              (psKernelSimpleCtorNames
                                                decl.ctors)
                                              0
                                              false
                                              false
                                              decl.isUnsafe;
                                          let work0 :=
                                            psKernelEnvironmentAddUnchecked
                                              environment
                                              (PsKernelConstantInfo.inductInfo
                                                initialInfo);
                                          match
                                              psKernelAddSimpleConstructorsWithFuel
                                                (Nat.succ fuel)
                                                decl
                                                safety
                                                resultLevel
                                                levels
                                                params
                                                (psKernelOpenBinderListLength indices)
                                                paramResult.session
                                                work0
                                                0
                                                decl.ctors with
                                          | Except.error error =>
                                              Except.error error
                                          | Except.ok ctorResult =>
                                              let shapes :=
                                                ctorResult.shapes;
                                              let finalInfo :=
                                                PsKernelInductiveInfo.mk
                                                  initialInfo.base
                                                  initialInfo.numParams
                                                  initialInfo.numIndices
                                                  initialInfo.all
                                                  initialInfo.ctors
                                                  initialInfo.numNested
                                                  (psKernelSimpleHasRecursiveFields
                                                    shapes)
                                                  (psKernelSimpleHasReflexiveFields
                                                    shapes)
                                                  initialInfo.isUnsafe;
                                              let work1 :=
                                                psKernelEnvironmentReplaceUnchecked
                                                  ctorResult.environment
                                                  (PsKernelConstantInfo.inductInfo
                                                    finalInfo);
                                              let elimSession :=
                                                psKernelSessionWithEnvironment
                                                  paramResult.session
                                                  work1;
                                              match
                                                  psKernelSimpleElimOnlyAtZero
                                                    fuel
                                                    elimSession
                                                    params
                                                    resultLevel
                                                    decl.ctors with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok elimOnlyAtZero =>
                                                  let kTarget :=
                                                    psKernelSimpleKTarget
                                                      resultLevel
                                                      shapes;
                                                  let elimName :=
                                                    psKernelSimpleFreshElimName
                                                      decl.levelParams;
                                                  let elimLevel :=
                                                    if elimOnlyAtZero then
                                                      PsKernelLevel.zero
                                                    else
                                                      PsKernelLevel.param
                                                        elimName;
                                                  let recLevelParams :=
                                                    if elimOnlyAtZero then
                                                      decl.levelParams
                                                    else
                                                      List.cons
                                                        elimName
                                                        decl.levelParams;
                                                  let motiveInternal :=
                                                    psKernelSimpleInternalName
                                                      "motive";
                                                  let motive :=
                                                    PsKernelExpr.fvar
                                                      motiveInternal;
                                                  let motiveBinder :=
                                                    PsKernelOpenBinder.mk
                                                      motiveInternal
                                                      (PsKernelName.str
                                                        PsKernelName.anonymous
                                                        "motive")
                                                      (psKernelCloseOpenBinders
                                                        indices
                                                        (psKernelMkArrow
                                                          inductExpr
                                                          (PsKernelExpr.sort
                                                            elimLevel)))
                                                      PsKernelBinderInfo.default;
                                                  let minorBinders :=
                                                    psKernelMakeSimpleMinorBinders
                                                      motive
                                                      levels
                                                      params
                                                      shapes;
                                                  let majorInternal :=
                                                    psKernelSimpleInternalName
                                                      "major";
                                                  let major :=
                                                    PsKernelExpr.fvar
                                                      majorInternal;
                                                  let majorBinder :=
                                                    PsKernelOpenBinder.mk
                                                      majorInternal
                                                      (PsKernelName.str
                                                        PsKernelName.anonymous
                                                        "t")
                                                      inductExpr
                                                      PsKernelBinderInfo.default;
                                                  let coreRuleBinders :=
                                                    List.cons
                                                      motiveBinder
                                                      minorBinders;
                                                  let ruleBinders :=
                                                    psKernelOpenBinderListAppend
                                                      params
                                                      coreRuleBinders;
                                                  let recBinders :=
                                                    psKernelOpenBinderListAppend
                                                      ruleBinders
                                                      (psKernelOpenBinderListAppend
                                                        indices
                                                        (List.cons
                                                          majorBinder
                                                          List.nil));
                                                  let recTypeRaw :=
                                                    psKernelCloseOpenBinders
                                                      recBinders
                                                      (psKernelSimpleMotiveApp
                                                        motive
                                                        indexArgs
                                                        major);
                                                  let recType :=
                                                    psKernelExprInferImplicitAll
                                                      recTypeRaw
                                                      true;
                                                  let recLevels :=
                                                    psKernelLevelParamsToLevels
                                                      recLevelParams;
                                                  let rules :=
                                                    psKernelMakeSimpleRecursorRules
                                                      recName
                                                      recLevels
                                                      params
                                                      motive
                                                      minorBinders
                                                      ruleBinders
                                                      shapes
                                                      minorBinders;
                                                  let recInfo :=
                                                    PsKernelRecursorInfo.mk
                                                      (PsKernelConstantBase.mk
                                                        recName
                                                        recLevelParams
                                                        recType)
                                                      (List.cons
                                                        decl.name
                                                        List.nil)
                                                      decl.numParams
                                                      (psKernelOpenBinderListLength indices)
                                                      1
                                                      (psKernelOpenBinderListLength
                                                        minorBinders)
                                                      rules
                                                      kTarget
                                                      decl.isUnsafe;
                                                  let recSession :=
                                                    psKernelMkCheckerSession
                                                      work1
                                                      recLevelParams
                                                      safety
                                                      maxRecDepth
                                                      maxNatSize;
                                                  match
                                                      psKernelSessionCheck
                                                        fuel
                                                        recSession
                                                        recType with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok recTypeType =>
                                                      match
                                                          psKernelSessionEnsureSort
                                                            fuel
                                                            (Prod.snd recTypeType)
                                                            (Prod.fst recTypeType) with
                                                      | Except.error error =>
                                                          Except.error error
                                                      | Except.ok _ =>
                                                          let work2 :=
                                                            psKernelEnvironmentAddUnchecked
                                                              work1
                                                              (PsKernelConstantInfo.recInfo
                                                                recInfo);
                                                          let ruleSession :=
                                                            psKernelMkCheckerSession
                                                              work2
                                                              recLevelParams
                                                              safety
                                                              maxRecDepth
                                                              maxNatSize;
                                                          match
                                                              psKernelValidateSimpleRecursorRules
                                                                fuel
                                                                ruleSession
                                                                params
                                                                ruleBinders
                                                                motive
                                                                levels
                                                                shapes
                                                                rules with
                                                          | Except.error error =>
                                                              Except.error error
                                                          | Except.ok _ =>
                                                              Except.ok work2
                                      | _ =>
                                          Except.error
                                            "simple inductive result must be a sort"
    else
      Except.error
        "duplicate inductive, constructor, or recursor name"
