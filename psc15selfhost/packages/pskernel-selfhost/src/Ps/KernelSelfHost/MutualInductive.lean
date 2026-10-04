import Ps.KernelSelfHost.InductiveAdmission

structure PsKernelSimpleMutualTypeDecl where
  name : PsKernelName
  type : PsKernelExpr
  ctors : List PsKernelSimpleConstructorDecl

structure PsKernelSimpleMutualInductiveDecl where
  levelParams : List PsKernelName
  numParams : Nat
  types : List PsKernelSimpleMutualTypeDecl
  isUnsafe : Bool

structure PsKernelSimpleMutualTypeShape where
  decl : PsKernelSimpleMutualTypeDecl
  indices : List PsKernelOpenBinder

structure PsKernelSimpleMutualRecursiveField where
  field : PsKernelOpenBinder
  args : List PsKernelOpenBinder
  target : Nat
  indices : List PsKernelExpr

structure PsKernelSimpleMutualConstructorShape where
  owner : Nat
  ctor : PsKernelSimpleConstructorDecl
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleMutualRecursiveField
  resultIndices : List PsKernelExpr

structure PsKernelSimpleMutualAppInfo where
  target : Nat
  indices : List PsKernelExpr

structure PsKernelMutualRecursiveArgumentResult where
  session : PsKernelCheckerSession
  recursiveInfo : Option PsKernelSimpleMutualRecursiveField

structure PsKernelMutualOpenFieldsResult where
  session : PsKernelCheckerSession
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleMutualRecursiveField
  result : PsKernelExpr

def psKernelSimpleMutualNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      List.cons
        typeDecl.name
        (psKernelSimpleMutualNames rest)

def psKernelSimpleMutualContainsConstWorker
    (expr : PsKernelExpr) :
    List PsKernelName -> Bool :=
  match expr with
  | PsKernelExpr.const name _ =>
      fun (targets : List PsKernelName) =>
        psKernelNameMember name targets
  | PsKernelExpr.app fn arg =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker fn;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker arg;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.lam _ type body _ =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.forallE _ type body _ =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.letE _ type value body _ =>
      let typeCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let valueCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker value;
      let bodyCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if typeCheck targets then
          true
        else if valueCheck targets then
          true
        else
          bodyCheck targets
  | PsKernelExpr.mdata _ body =>
      let smaller :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        smaller targets
  | PsKernelExpr.proj typeName _ body =>
      let smaller :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if psKernelNameMember typeName targets then
          true
        else
          smaller targets
  | _ =>
      fun (_targets : List PsKernelName) =>
        false

def psKernelSimpleMutualContainsConst
    (targets : List PsKernelName)
    (expr : PsKernelExpr) : Bool :=
  psKernelSimpleMutualContainsConstWorker
    expr
    targets

def psKernelSimpleMutualTargetIndexWorker
    (name : PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    Nat -> Option Nat :=
  match shapes with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons shape rest =>
      let smaller :
          Nat -> Option Nat :=
        psKernelSimpleMutualTargetIndexWorker
          name
          rest;
      fun (index : Nat) =>
        if psKernelNameEq name shape.decl.name then
          Option.some index
        else
          smaller (Nat.succ index)

def psKernelSimpleMutualTargetIndex
    (name : PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    Option Nat :=
  psKernelSimpleMutualTargetIndexWorker
    name
    shapes
    0

def psKernelMutualTypeShapeListGet
    (values : List PsKernelSimpleMutualTypeShape) :
    Nat -> Option PsKernelSimpleMutualTypeShape :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller :
          Nat -> Option PsKernelSimpleMutualTypeShape :=
        psKernelMutualTypeShapeListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelSimpleMutualIndicesContainTarget
    (targets : List PsKernelName)
    (indices : List PsKernelExpr) : Bool :=
  match indices with
  | List.nil =>
      false
  | List.cons head tail =>
      if
          psKernelSimpleMutualContainsConst
            targets
            head then
        true
      else
        psKernelSimpleMutualIndicesContainTarget
          targets
          tail

def psKernelSimpleMutualAppInfo
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (expr : PsKernelExpr) :
    Option PsKernelSimpleMutualAppInfo :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name foundLevels =>
      if psKernelLevelListEq foundLevels levels then
        match
            psKernelSimpleMutualTargetIndex
              name
              shapes with
        | Option.none =>
            Option.none
        | Option.some target =>
            match
                psKernelMutualTypeShapeListGet
                  shapes
                  target with
            | Option.none =>
                Option.none
            | Option.some shape =>
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
                          (psKernelOpenBinderListLength
                            shape.indices) then
                      if
                          psKernelSimpleMutualIndicesContainTarget
                            targets
                            indices then
                        Option.none
                      else
                        Option.some
                          (PsKernelSimpleMutualAppInfo.mk
                            target
                            indices)
                    else
                      Option.none
      else
        Option.none
  | _ =>
      Option.none

def psKernelSimpleMutualCtorApp
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (shape : PsKernelSimpleMutualConstructorShape) :
    PsKernelExpr :=
  psKernelApplyArgs
    (PsKernelExpr.const
      shape.ctor.name
      levels)
    (psKernelExprListAppend
      (psKernelSimpleParamArgs params)
      (psKernelOpenBinderExprs shape.fields))

def psKernelMutualOpenBinderListGet
    (values : List PsKernelOpenBinder) :
    Nat -> Option PsKernelOpenBinder :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller :
          Nat -> Option PsKernelOpenBinder :=
        psKernelMutualOpenBinderListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelSimpleMutualMotiveApp
    (motives : List PsKernelOpenBinder)
    (target : Nat)
    (indices : List PsKernelExpr)
    (major : PsKernelExpr) :
    Except String PsKernelExpr :=
  match
      psKernelMutualOpenBinderListGet
        motives
        target with
  | Option.none =>
      Except.error
        "mutual recursor motive target is out of bounds"
  | Option.some motive =>
      Except.ok
        (psKernelSimpleMotiveApp
          (PsKernelExpr.fvar
            motive.internalName)
          indices
          major)

def psKernelSimpleMutualHasRecursiveFields
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      match shape.recursiveFields with
      | List.nil =>
          psKernelSimpleMutualHasRecursiveFields rest
      | List.cons _ _ =>
          true

def psKernelSimpleMutualRecursiveFieldsHaveArgs
    (fields : List PsKernelSimpleMutualRecursiveField) :
    Bool :=
  match fields with
  | List.nil =>
      false
  | List.cons field rest =>
      match field.args with
      | List.nil =>
          psKernelSimpleMutualRecursiveFieldsHaveArgs rest
      | List.cons _ _ =>
          true

def psKernelSimpleMutualHasReflexiveFields
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      if
          psKernelSimpleMutualRecursiveFieldsHaveArgs
            shape.recursiveFields then
        true
      else
        psKernelSimpleMutualHasReflexiveFields
          rest


def psKernelReverseMutualRecursiveFieldsWorker
    (values : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelSimpleMutualRecursiveField ->
    List PsKernelSimpleMutualRecursiveField :=
  match values with
  | List.nil =>
      fun
        (acc : List PsKernelSimpleMutualRecursiveField) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleMutualRecursiveField ->
          List PsKernelSimpleMutualRecursiveField :=
        psKernelReverseMutualRecursiveFieldsWorker tail;
      fun
        (acc : List PsKernelSimpleMutualRecursiveField) =>
        smaller
          (List.cons head acc)

def psKernelReverseMutualRecursiveFields
    (values : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelSimpleMutualRecursiveField :=
  psKernelReverseMutualRecursiveFieldsWorker
    values
    List.nil

def psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
    (fuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelOpenBinder ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    Except String PsKernelMutualRecursiveArgumentResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_targets : List PsKernelName)
        (_shapes : List PsKernelSimpleMutualTypeShape)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_field : PsKernelOpenBinder)
        (_domain : PsKernelExpr)
        (_revArgs : List PsKernelOpenBinder)
        (_applied : PsKernelExpr) =>
        Except.error
          "mutual recursive-argument budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
          remaining;
      fun
        (session : PsKernelCheckerSession)
        (targets : List PsKernelName)
        (shapes : List PsKernelSimpleMutualTypeShape)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (field : PsKernelOpenBinder)
        (domain : PsKernelExpr)
        (revArgs : List PsKernelOpenBinder)
        (applied : PsKernelExpr) =>
        match
            psKernelSimpleMutualAppInfo
              targets
              shapes
              levels
              params
              domain with
        | Option.some directInfo =>
            Except.ok
              (PsKernelMutualRecursiveArgumentResult.mk
                session
                (Option.some
                  (PsKernelSimpleMutualRecursiveField.mk
                    field
                    (psKernelReverseOpenBinders revArgs)
                    directInfo.target
                    directInfo.indices)))
        | Option.none =>
            match
                psKernelSessionWhnf
                  remaining
                  session
                  domain with
            | Except.error error =>
                Except.error error
            | Except.ok reduced =>
                match
                    psKernelSimpleMutualAppInfo
                      targets
                      shapes
                      levels
                      params
                      (Prod.fst reduced) with
                | Option.some info =>
                    Except.ok
                      (PsKernelMutualRecursiveArgumentResult.mk
                        (Prod.snd reduced)
                        (Option.some
                          (PsKernelSimpleMutualRecursiveField.mk
                            field
                            (psKernelReverseOpenBinders revArgs)
                            info.target
                            info.indices)))
                | Option.none =>
                    match Prod.fst reduced with
                | PsKernelExpr.forallE
                    userName
                    argDomain
                    body
                    binderInfo =>
                    if
                        psKernelSimpleMutualContainsConst
                          targets
                          argDomain then
                      Except.error
                        "mutual inductive field has a non-positive recursive occurrence"
                    else
                      let localDomain :=
                        psKernelExprConsumeTypeAnnotations
                          argDomain;
                      let opened :=
                        psKernelSessionWithLocal
                          (Prod.snd reduced)
                          userName
                          localDomain
                          binderInfo;
                      let fresh :=
                        Prod.fst opened;
                      let child :=
                        Prod.snd opened;
                      let arg :=
                        PsKernelOpenBinder.mk
                          fresh
                          userName
                          localDomain
                          binderInfo;
                      smaller
                        child
                        targets
                        shapes
                        levels
                        params
                        field
                        (psKernelExprInstantiate1
                          body
                          (PsKernelExpr.fvar fresh))
                        (List.cons arg revArgs)
                        (PsKernelExpr.app
                          applied
                          (PsKernelExpr.fvar fresh))
                | _ =>
                    if
                        psKernelSimpleMutualContainsConst
                          targets
                          domain then
                      Except.error
                        "nested or invalid mutual inductive occurrence is not supported"
                    else if
                        psKernelSimpleMutualContainsConst
                          targets
                          (Prod.fst reduced) then
                      Except.error
                        "nested or invalid mutual inductive occurrence is not supported"
                    else
                      Except.ok
                        (PsKernelMutualRecursiveArgumentResult.mk
                          (Prod.snd reduced)
                          Option.none)

def psKernelAnalyzeSimpleMutualRecursiveArgument
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (field : PsKernelOpenBinder)
    (domain : PsKernelExpr) :
    Except String PsKernelMutualRecursiveArgumentResult :=
  psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
    (Nat.succ (psKernelExprNodeCount domain))
    session
    targets
    shapes
    levels
    params
    field
    domain
    List.nil
    (PsKernelExpr.fvar field.internalName)

def psKernelOpenSimpleMutualConstructorFieldsWithFuel
    (fuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelLevel ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    List PsKernelSimpleMutualRecursiveField ->
    Except String PsKernelMutualOpenFieldsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_targets : List PsKernelName)
        (_shapes : List PsKernelSimpleMutualTypeShape)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_resultLevel : PsKernelLevel)
        (_type : PsKernelExpr)
        (_revFields : List PsKernelOpenBinder)
        (_revRecursive : List PsKernelSimpleMutualRecursiveField) =>
        Except.error
          "mutual constructor field budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelOpenSimpleMutualConstructorFieldsWithFuel
          remaining;
      fun
        (session : PsKernelCheckerSession)
        (targets : List PsKernelName)
        (shapes : List PsKernelSimpleMutualTypeShape)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (resultLevel : PsKernelLevel)
        (type : PsKernelExpr)
        (revFields : List PsKernelOpenBinder)
        (revRecursive : List PsKernelSimpleMutualRecursiveField) =>
        match
            psKernelSessionWhnf
              remaining
              session
              type with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            match Prod.fst reduced with
            | PsKernelExpr.forallE
                userName
                domain
                body
                binderInfo =>
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
                        if
                            if
                                psKernelLevelLe
                                  (Prod.fst fieldLevel)
                                  resultLevel then
                              true
                            else
                              psKernelLevelNormalizesToZero
                                resultLevel then
                          let localDomain :=
                            psKernelExprConsumeTypeAnnotations
                              domain;
                          let opened :=
                            psKernelSessionWithLocal
                              (Prod.snd fieldLevel)
                              userName
                              localDomain
                              binderInfo;
                          let fresh :=
                            Prod.fst opened;
                          let child :=
                            Prod.snd opened;
                          let field :=
                            PsKernelOpenBinder.mk
                              fresh
                              userName
                              localDomain
                              binderInfo;
                          match
                              psKernelAnalyzeSimpleMutualRecursiveArgument
                                child
                                targets
                                shapes
                                levels
                                params
                                field
                                domain with
                          | Except.error error =>
                              Except.error error
                          | Except.ok recursiveResult =>
                              let child0 :=
                                child;
                              let analysisLocal :=
                                recursiveResult.session.context.localContext;
                              let continuationLocal :=
                                PsKernelLocalContext.mk
                                  child0.context.localContext.decls
                                  analysisLocal.nextIndex;
                              let continuation :=
                                PsKernelCheckerSession.mk
                                  (psKernelCheckerContextWithLocalContext
                                    child0.context
                                    continuationLocal)
                                  recursiveResult.session.state;
                              let nextRecursive :
                                  List PsKernelSimpleMutualRecursiveField :=
                                match
                                    recursiveResult.recursiveInfo with
                                | Option.none =>
                                    revRecursive
                                | Option.some recursive =>
                                    List.cons
                                      recursive
                                      revRecursive;
                              smaller
                                continuation
                                targets
                                shapes
                                levels
                                params
                                resultLevel
                                (psKernelExprInstantiate1
                                  body
                                  (PsKernelExpr.fvar fresh))
                                (List.cons field revFields)
                                nextRecursive
                        else
                          Except.error
                            "mutual inductive constructor field universe is too large"
            | _ =>
                Except.ok
                  (PsKernelMutualOpenFieldsResult.mk
                    (Prod.snd reduced)
                    (psKernelReverseOpenBinders revFields)
                    (psKernelReverseMutualRecursiveFields
                      revRecursive)
                    (Prod.fst reduced))

def psKernelOpenSimpleMutualConstructorFields
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (type : PsKernelExpr) :
    Except String PsKernelMutualOpenFieldsResult :=
  psKernelOpenSimpleMutualConstructorFieldsWithFuel
    (Nat.succ fuel)
    session
    targets
    shapes
    levels
    params
    resultLevel
    type
    List.nil
    List.nil


def psKernelSimpleMutualIHBindersWorker
    (fields : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelOpenBinder ->
    Nat ->
    Except String (List PsKernelOpenBinder) :=
  match fields with
  | List.nil =>
      fun
        (_motives : List PsKernelOpenBinder)
        (_index : Nat) =>
        Except.ok List.nil
  | List.cons recursive rest =>
      let smaller :=
        psKernelSimpleMutualIHBindersWorker rest;
      fun
        (motives : List PsKernelOpenBinder)
        (index : Nat) =>
        match
            psKernelSimpleMutualMotiveApp
              motives
              recursive.target
              recursive.indices
              (psKernelApplyArgs
                (PsKernelExpr.fvar
                  recursive.field.internalName)
                (psKernelOpenBinderExprs
                  recursive.args)) with
        | Except.error error =>
            Except.error error
        | Except.ok target =>
            let internalName :=
              PsKernelName.num
                (psKernelSimpleInternalName
                  "mutualIH")
                index;
            let binder :=
              PsKernelOpenBinder.mk
                internalName
                (psKernelNameAppendAfter
                  recursive.field.userName
                  "_ih")
                (psKernelCloseOpenBinders
                  recursive.args
                  target)
                PsKernelBinderInfo.default;
            match
                smaller
                  motives
                  (Nat.succ index) with
            | Except.error error =>
                Except.error error
            | Except.ok tail =>
                Except.ok
                  (List.cons binder tail)

def psKernelSimpleMutualIHBinders
    (motives : List PsKernelOpenBinder)
    (shape : PsKernelSimpleMutualConstructorShape) :
    Except String (List PsKernelOpenBinder) :=
  psKernelSimpleMutualIHBindersWorker
    shape.recursiveFields
    motives
    0

def psKernelMakeSimpleMutualMotivesWorker
    (shapes : List PsKernelSimpleMutualTypeShape) :
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelLevel ->
    Nat ->
    List PsKernelOpenBinder :=
  match shapes with
  | List.nil =>
      fun
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_elimLevel : PsKernelLevel)
        (_index : Nat) =>
        List.nil
  | List.cons shape rest =>
      let smaller :=
        psKernelMakeSimpleMutualMotivesWorker rest;
      fun
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (elimLevel : PsKernelLevel)
        (index : Nat) =>
        let inductExpr :=
          psKernelApplyArgs
            (PsKernelExpr.const
              shape.decl.name
              levels)
            (psKernelExprListAppend
              (psKernelSimpleParamArgs params)
              (psKernelOpenBinderExprs
                shape.indices));
        let internalName :=
          PsKernelName.num
            (psKernelSimpleInternalName
              "mutualMotive")
            index;
        let userName :=
          PsKernelName.str
            PsKernelName.anonymous
            (String.Internal.append
              "motive_"
              (psKernelNatToString
                (Nat.succ index)));
        let motive :=
          PsKernelOpenBinder.mk
            internalName
            userName
            (psKernelCloseOpenBinders
              shape.indices
              (psKernelMkArrow
                inductExpr
                (PsKernelExpr.sort
                  elimLevel)))
            PsKernelBinderInfo.default;
        List.cons
          motive
          (smaller
            levels
            params
            elimLevel
            (Nat.succ index))

def psKernelMakeSimpleMutualMotives
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (elimLevel : PsKernelLevel)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    List PsKernelOpenBinder :=
  psKernelMakeSimpleMutualMotivesWorker
    shapes
    levels
    params
    elimLevel
    0

def psKernelMakeSimpleMutualMinorsWorker
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Nat ->
    Except String (List PsKernelOpenBinder) :=
  match shapes with
  | List.nil =>
      fun
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_index : Nat) =>
        Except.ok List.nil
  | List.cons shape rest =>
      let smaller :=
        psKernelMakeSimpleMutualMinorsWorker rest;
      fun
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (index : Nat) =>
        match
            psKernelSimpleMutualIHBinders
              motives
              shape with
        | Except.error error =>
            Except.error error
        | Except.ok ihBinders =>
            match
                psKernelSimpleMutualMotiveApp
                  motives
                  shape.owner
                  shape.resultIndices
                  (psKernelSimpleMutualCtorApp
                    levels
                    params
                    shape) with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                let minor :=
                  PsKernelOpenBinder.mk
                    (PsKernelName.num
                      (psKernelSimpleInternalName
                        "mutualMinor")
                      index)
                    shape.ctor.name
                    (psKernelCloseOpenBinders
                      (psKernelOpenBinderListAppend
                        shape.fields
                        ihBinders)
                      result)
                    PsKernelBinderInfo.default;
                match
                    smaller
                      levels
                      params
                      motives
                      (Nat.succ index) with
                | Except.error error =>
                    Except.error error
                | Except.ok tail =>
                    Except.ok
                      (List.cons minor tail)

def psKernelMakeSimpleMutualMinors
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (motives : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Except String (List PsKernelOpenBinder) :=
  psKernelMakeSimpleMutualMinorsWorker
    shapes
    levels
    params
    motives
    0

def psKernelMakeSimpleMutualRecursiveCallsWorker
    (fields : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Except String (List PsKernelExpr) :=
  match fields with
  | List.nil =>
      fun
        (_recLevelParams : List PsKernelName)
        (_typeShapes : List PsKernelSimpleMutualTypeShape)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder) =>
        Except.ok List.nil
  | List.cons recursive rest =>
      let smaller :=
        psKernelMakeSimpleMutualRecursiveCallsWorker
          rest;
      fun
        (recLevelParams : List PsKernelName)
        (typeShapes : List PsKernelSimpleMutualTypeShape)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder) =>
        match
            psKernelMutualTypeShapeListGet
              typeShapes
              recursive.target with
        | Option.none =>
            Except.error
              "mutual recursive-call target is out of bounds"
        | Option.some targetShape =>
            let recLevels :=
              psKernelLevelParamsToLevels
                recLevelParams;
            let fixed :=
              psKernelExprListAppend
                (psKernelSimpleParamArgs params)
                (psKernelExprListAppend
                  (psKernelOpenBinderExprs motives)
                  (psKernelOpenBinderExprs minors));
            let applied :=
              psKernelApplyArgs
                (PsKernelExpr.fvar
                  recursive.field.internalName)
                (psKernelOpenBinderExprs
                  recursive.args);
            let call0 :=
              psKernelApplyArgs
                (PsKernelExpr.const
                  (psKernelSimpleRecName
                    targetShape.decl.name)
                  recLevels)
                (psKernelExprListAppend
                  fixed
                  (psKernelExprListAppend
                    recursive.indices
                    (List.cons
                      applied
                      List.nil)));
            let call : PsKernelExpr :=
              match recursive.args with
              | List.nil =>
                  call0
              | List.cons _ _ =>
                  psKernelCloseOpenLambdas
                    recursive.args
                    call0;
            match
                smaller
                  recLevelParams
                  typeShapes
                  params
                  motives
                  minors with
            | Except.error error =>
                Except.error error
            | Except.ok tail =>
                Except.ok
                  (List.cons call tail)

def psKernelMakeSimpleMutualRecursiveCalls
    (recLevelParams : List PsKernelName)
    (typeShapes : List PsKernelSimpleMutualTypeShape)
    (params : List PsKernelOpenBinder)
    (motives : List PsKernelOpenBinder)
    (minors : List PsKernelOpenBinder)
    (shape : PsKernelSimpleMutualConstructorShape) :
    Except String (List PsKernelExpr) :=
  psKernelMakeSimpleMutualRecursiveCallsWorker
    shape.recursiveFields
    recLevelParams
    typeShapes
    params
    motives
    minors

def psKernelMakeSimpleMutualRulesWorker
    (ctorShapes : List PsKernelSimpleMutualConstructorShape) :
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Nat ->
    Nat ->
    Except String (List PsKernelRecursorRule) :=
  match ctorShapes with
  | List.nil =>
      fun
        (_recLevelParams : List PsKernelName)
        (_typeShapes : List PsKernelSimpleMutualTypeShape)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_owner : Nat)
        (_minorIndex : Nat) =>
        Except.ok List.nil
  | List.cons shape rest =>
      let smaller :=
        psKernelMakeSimpleMutualRulesWorker rest;
      fun
        (recLevelParams : List PsKernelName)
        (typeShapes : List PsKernelSimpleMutualTypeShape)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (owner : Nat)
        (minorIndex : Nat) =>
        if Nat.beq shape.owner owner then
          match
              psKernelMutualOpenBinderListGet
                minors
                minorIndex with
          | Option.none =>
              Except.error
                "mutual minor index is out of bounds"
          | Option.some minor =>
              match
                  psKernelMakeSimpleMutualRecursiveCalls
                    recLevelParams
                    typeShapes
                    params
                    motives
                    minors
                    shape with
              | Except.error error =>
                  Except.error error
              | Except.ok recursiveCalls =>
                  let body :=
                    psKernelApplyArgs
                      (PsKernelExpr.fvar
                        minor.internalName)
                      (psKernelExprListAppend
                        (psKernelOpenBinderExprs
                          shape.fields)
                        recursiveCalls);
                  let rule :=
                    PsKernelRecursorRule.mk
                      shape.ctor.name
                      (psKernelOpenBinderListLength
                        shape.fields)
                      (psKernelCloseOpenLambdas
                        (psKernelOpenBinderListAppend
                          ruleBinders
                          shape.fields)
                        body);
                  match
                      smaller
                        recLevelParams
                        typeShapes
                        params
                        motives
                        minors
                        ruleBinders
                        owner
                        (Nat.succ minorIndex) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok tail =>
                      Except.ok
                        (List.cons rule tail)
        else
          smaller
            recLevelParams
            typeShapes
            params
            motives
            minors
            ruleBinders
            owner
            (Nat.succ minorIndex)

def psKernelMakeSimpleMutualRules
    (recLevelParams : List PsKernelName)
    (typeShapes : List PsKernelSimpleMutualTypeShape)
    (params : List PsKernelOpenBinder)
    (motives : List PsKernelOpenBinder)
    (minors : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (owner : Nat)
    (ctorShapes : List PsKernelSimpleMutualConstructorShape) :
    Except String (List PsKernelRecursorRule) :=
  psKernelMakeSimpleMutualRulesWorker
    ctorShapes
    recLevelParams
    typeShapes
    params
    motives
    minors
    ruleBinders
    owner
    0

def psKernelValidateSimpleMutualRulesWorker
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Nat ->
    PsKernelCheckerSession ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Nat ->
    List PsKernelRecursorRule ->
    Except String PsKernelCheckerSession :=
  match shapes with
  | List.nil =>
      fun
        (_fuel : Nat)
        (session : PsKernelCheckerSession)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_owner : Nat)
        (pending : List PsKernelRecursorRule) =>
        match pending with
        | List.nil =>
            Except.ok session
        | List.cons _ _ =>
            Except.error
              "mutual recursor rule count mismatch"
  | List.cons shape rest =>
      let smaller :=
        psKernelValidateSimpleMutualRulesWorker
          rest;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (owner : Nat)
        (pending : List PsKernelRecursorRule) =>
        if Nat.beq shape.owner owner then
          match pending with
          | List.nil =>
              Except.error
                "mutual recursor rule count mismatch"
          | List.cons rule tail =>
              match
                  psKernelSessionCheck
                    fuel
                    session
                    rule.rhs with
              | Except.error error =>
                  Except.error error
              | Except.ok gotType =>
                  match
                      psKernelSimpleMutualMotiveApp
                        motives
                        owner
                        shape.resultIndices
                        (psKernelSimpleMutualCtorApp
                          levels
                          params
                          shape) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok expectedResult =>
                      let expectedType :=
                        psKernelCloseOpenBinders
                          (psKernelOpenBinderListAppend
                            ruleBinders
                            shape.fields)
                          expectedResult;
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
                            smaller
                              fuel
                              (Prod.snd equal)
                              levels
                              params
                              motives
                              minors
                              ruleBinders
                              owner
                              tail
                          else
                            Except.error
                              "generated mutual recursor rule is not type preserving"
        else
          smaller
            fuel
            session
            levels
            params
            motives
            minors
            ruleBinders
            owner
            pending

def psKernelValidateSimpleMutualRules
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (motives : List PsKernelOpenBinder)
    (minors : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (owner : Nat)
    (ctorShapes : List PsKernelSimpleMutualConstructorShape)
    (rules : List PsKernelRecursorRule) :
    Except String PsKernelCheckerSession :=
  psKernelValidateSimpleMutualRulesWorker
    ctorShapes
    fuel
    session
    levels
    params
    motives
    minors
    ruleBinders
    owner
    rules


structure PsKernelAddMutualConstructorsResult where
  environment : PsKernelEnvironment
  shapes : List PsKernelSimpleMutualConstructorShape

def psKernelMutualNameListAppend
    (left : List PsKernelName) :
    List PsKernelName -> List PsKernelName :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelName -> List PsKernelName :=
        psKernelMutualNameListAppend tail;
      fun (right : List PsKernelName) =>
        List.cons
          head
          (smaller right)

def psKernelMutualConstructorShapeListAppend
    (left : List PsKernelSimpleMutualConstructorShape) :
    List PsKernelSimpleMutualConstructorShape ->
    List PsKernelSimpleMutualConstructorShape :=
  match left with
  | List.nil =>
      fun
        (right : List PsKernelSimpleMutualConstructorShape) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleMutualConstructorShape ->
          List PsKernelSimpleMutualConstructorShape :=
        psKernelMutualConstructorShapeListAppend tail;
      fun
        (right : List PsKernelSimpleMutualConstructorShape) =>
        List.cons
          head
          (smaller right)

def psKernelSimpleMutualTypeCount
    (types : List PsKernelSimpleMutualTypeDecl) :
    Nat :=
  match types with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelSimpleMutualTypeCount rest)

def psKernelSimpleMutualRecNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      List.cons
        (psKernelSimpleRecName
          typeDecl.name)
        (psKernelSimpleMutualRecNames rest)

def psKernelSimpleMutualCtorNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      psKernelMutualNameListAppend
        (psKernelSimpleCtorNames
          typeDecl.ctors)
        (psKernelSimpleMutualCtorNames
          rest)

def psKernelSimpleMutualCtorTypes
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelExpr :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      psKernelExprListAppend
        (psKernelSimpleCtorTypes
          typeDecl.ctors)
        (psKernelSimpleMutualCtorTypes
          rest)

def psKernelOpenSimpleMutualRemainingTypesWorker
    (types : List PsKernelSimpleMutualTypeDecl) :
    Nat ->
    PsKernelEnvironment ->
    List PsKernelName ->
    PsKernelDefinitionSafety ->
    Nat ->
    Nat ->
    PsKernelCheckerSession ->
    List PsKernelOpenBinder ->
    PsKernelLevel ->
    Except String (List PsKernelSimpleMutualTypeShape) :=
  match types with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_environment : PsKernelEnvironment)
        (_levelParams : List PsKernelName)
        (_safety : PsKernelDefinitionSafety)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat)
        (_headerSession : PsKernelCheckerSession)
        (_params : List PsKernelOpenBinder)
        (_resultLevel : PsKernelLevel) =>
        Except.ok List.nil
  | List.cons typeDecl rest =>
      let smaller :=
        psKernelOpenSimpleMutualRemainingTypesWorker
          rest;
      fun
        (fuel : Nat)
        (environment : PsKernelEnvironment)
        (levelParams : List PsKernelName)
        (safety : PsKernelDefinitionSafety)
        (maxRecDepth : Nat)
        (maxNatSize : Nat)
        (headerSession : PsKernelCheckerSession)
        (params : List PsKernelOpenBinder)
        (resultLevel : PsKernelLevel) =>
        match
            psKernelCheckNoMVarNoFVar
              typeDecl.type with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelCheckLevelParams
                  typeDecl.type
                  levelParams with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                let closedSession :=
                  psKernelMkCheckerSession
                    environment
                    levelParams
                    safety
                    maxRecDepth
                    maxNatSize;
                match
                    psKernelSessionCheck
                      fuel
                      closedSession
                      typeDecl.type with
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
                    | Except.ok _ =>
                        match
                            psKernelOpenSimpleConstructorParams
                              fuel
                              headerSession
                              params
                              typeDecl.type with
                        | Except.error error =>
                            Except.error error
                        | Except.ok afterParams =>
                            match
                                psKernelOpenSimpleHeaderIndices
                                  fuel
                                  afterParams.session
                                  afterParams.result with
                            | Except.error error =>
                                Except.error error
                            | Except.ok indexResult =>
                                match indexResult.result with
                                | PsKernelExpr.sort level =>
                                    if
                                        psKernelLevelEquivalent
                                          level
                                          resultLevel then
                                      match
                                          smaller
                                            fuel
                                            environment
                                            levelParams
                                            safety
                                            maxRecDepth
                                            maxNatSize
                                            headerSession
                                            params
                                            resultLevel with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok tail =>
                                          Except.ok
                                            (List.cons
                                              (PsKernelSimpleMutualTypeShape.mk
                                                typeDecl
                                                indexResult.binders)
                                              tail)
                                    else
                                      Except.error
                                        "mutually inductive types must live in the same universe"
                                | _ =>
                                    Except.error
                                      "mutual inductive result must be a sort"

def psKernelMakeSimpleMutualBaseInfos
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    List PsKernelInductiveInfo :=
  match shapes with
  | List.nil =>
      List.nil
  | List.cons shape rest =>
      List.cons
        (PsKernelInductiveInfo.mk
          (PsKernelConstantBase.mk
            shape.decl.name
            decl.levelParams
            shape.decl.type)
          decl.numParams
          (psKernelOpenBinderListLength
            shape.indices)
          typeNames
          (psKernelSimpleCtorNames
            shape.decl.ctors)
          0
          false
          false
          decl.isUnsafe)
        (psKernelMakeSimpleMutualBaseInfos
          typeNames
          decl
          rest)

def psKernelAddMutualInductiveInfos
    (infos : List PsKernelInductiveInfo) :
    PsKernelEnvironment -> PsKernelEnvironment :=
  match infos with
  | List.nil =>
      fun
        (environment : PsKernelEnvironment) =>
        environment
  | List.cons info rest =>
      let smaller :
          PsKernelEnvironment -> PsKernelEnvironment :=
        psKernelAddMutualInductiveInfos rest;
      fun
        (environment : PsKernelEnvironment) =>
        smaller
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.inductInfo
              info))

def psKernelReplaceMutualInductiveInfos
    (infos : List PsKernelInductiveInfo) :
    Bool ->
    Bool ->
    PsKernelEnvironment ->
    PsKernelEnvironment :=
  match infos with
  | List.nil =>
      fun
        (_isRecursive : Bool)
        (_isReflexive : Bool)
        (environment : PsKernelEnvironment) =>
        environment
  | List.cons info rest =>
      let smaller :
          Bool ->
          Bool ->
          PsKernelEnvironment ->
          PsKernelEnvironment :=
        psKernelReplaceMutualInductiveInfos rest;
      fun
        (isRecursive : Bool)
        (isReflexive : Bool)
        (environment : PsKernelEnvironment) =>
        let finalInfo :=
          PsKernelInductiveInfo.mk
            info.base
            info.numParams
            info.numIndices
            info.all
            info.ctors
            info.numNested
            isRecursive
            isReflexive
            info.isUnsafe;
        smaller
          isRecursive
          isReflexive
          (psKernelEnvironmentReplaceUnchecked
            environment
            (PsKernelConstantInfo.inductInfo
              finalInfo))

def psKernelAddSimpleMutualConstructorsForTypeWorker
    (ctors : List PsKernelSimpleConstructorDecl) :
    Nat ->
    PsKernelDefinitionSafety ->
    PsKernelLevel ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    PsKernelSimpleMutualTypeShape ->
    Nat ->
    PsKernelCheckerSession ->
    PsKernelEnvironment ->
    Nat ->
    Except String PsKernelAddMutualConstructorsResult :=
  match ctors with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_safety : PsKernelDefinitionSafety)
        (_resultLevel : PsKernelLevel)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_typeNames : List PsKernelName)
        (_typeShapes : List PsKernelSimpleMutualTypeShape)
        (_typeShape : PsKernelSimpleMutualTypeShape)
        (_owner : Nat)
        (_headerSession : PsKernelCheckerSession)
        (work : PsKernelEnvironment)
        (_ctorIndex : Nat) =>
        Except.ok
          (PsKernelAddMutualConstructorsResult.mk
            work
            List.nil)
  | List.cons ctor rest =>
      let smaller :=
        psKernelAddSimpleMutualConstructorsForTypeWorker
          rest;
      fun
        (fuel : Nat)
        (safety : PsKernelDefinitionSafety)
        (resultLevel : PsKernelLevel)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (typeNames : List PsKernelName)
        (typeShapes : List PsKernelSimpleMutualTypeShape)
        (typeShape : PsKernelSimpleMutualTypeShape)
        (owner : Nat)
        (headerSession : PsKernelCheckerSession)
        (work : PsKernelEnvironment)
        (ctorIndex : Nat) =>
        match psKernelCheckNoMVarNoFVar ctor.type with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelCheckLevelParams
                  ctor.type
                  headerSession.context.levelParams with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                let closedSession :=
                  psKernelMkCheckerSession
                    work
                    headerSession.context.levelParams
                    safety
                    headerSession.context.maxRecDepth
                    headerSession.context.maxNatSize;
                match
                    psKernelSessionCheck
                      fuel
                      closedSession
                      ctor.type with
                | Except.error error =>
                    Except.error error
                | Except.ok ctorType =>
                    match
                        psKernelSessionEnsureSort
                          fuel
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
                              fuel
                              ctorSession
                              params
                              ctor.type with
                        | Except.error error =>
                            Except.error error
                        | Except.ok afterParams =>
                            match
                                psKernelOpenSimpleMutualConstructorFields
                                  fuel
                                  afterParams.session
                                  typeNames
                                  typeShapes
                                  levels
                                  params
                                  resultLevel
                                  afterParams.result with
                            | Except.error error =>
                                Except.error error
                            | Except.ok fieldsResult =>
                                match
                                    psKernelSimpleMutualAppInfo
                                      typeNames
                                      typeShapes
                                      levels
                                      params
                                      fieldsResult.result with
                                | Option.none =>
                                    Except.error
                                      "mutual constructor has invalid return type"
                                | Option.some appInfo =>
                                    if Nat.beq appInfo.target owner then
                                      let ctorInfo :=
                                        PsKernelConstructorInfo.mk
                                          (PsKernelConstantBase.mk
                                            ctor.name
                                            headerSession.context.levelParams
                                            ctor.type)
                                          typeShape.decl.name
                                          ctorIndex
                                          (psKernelOpenBinderListLength
                                            params)
                                          (psKernelOpenBinderListLength
                                            fieldsResult.fields)
                                          (psKernelDefinitionSafetyIsUnsafe
                                            safety);
                                      let nextWork :=
                                        psKernelEnvironmentAddUnchecked
                                          work
                                          (PsKernelConstantInfo.ctorInfo
                                            ctorInfo);
                                      match
                                          smaller
                                            fuel
                                            safety
                                            resultLevel
                                            levels
                                            params
                                            typeNames
                                            typeShapes
                                            typeShape
                                            owner
                                            headerSession
                                            nextWork
                                            (Nat.succ ctorIndex) with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok tailResult =>
                                          let shape :=
                                            PsKernelSimpleMutualConstructorShape.mk
                                              owner
                                              ctor
                                              fieldsResult.fields
                                              fieldsResult.recursiveFields
                                              appInfo.indices;
                                          Except.ok
                                            (PsKernelAddMutualConstructorsResult.mk
                                              tailResult.environment
                                              (List.cons
                                                shape
                                                tailResult.shapes))
                                    else
                                      Except.error
                                        "mutual constructor returns the wrong datatype"

def psKernelAddSimpleMutualTypesWorker
    (types : List PsKernelSimpleMutualTypeShape) :
    Nat ->
    PsKernelDefinitionSafety ->
    PsKernelLevel ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    PsKernelCheckerSession ->
    PsKernelEnvironment ->
    Nat ->
    Except String PsKernelAddMutualConstructorsResult :=
  match types with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_safety : PsKernelDefinitionSafety)
        (_resultLevel : PsKernelLevel)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_typeNames : List PsKernelName)
        (_allShapes : List PsKernelSimpleMutualTypeShape)
        (_headerSession : PsKernelCheckerSession)
        (work : PsKernelEnvironment)
        (_owner : Nat) =>
        Except.ok
          (PsKernelAddMutualConstructorsResult.mk
            work
            List.nil)
  | List.cons typeShape rest =>
      let smaller :=
        psKernelAddSimpleMutualTypesWorker rest;
      fun
        (fuel : Nat)
        (safety : PsKernelDefinitionSafety)
        (resultLevel : PsKernelLevel)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (typeNames : List PsKernelName)
        (allShapes : List PsKernelSimpleMutualTypeShape)
        (headerSession : PsKernelCheckerSession)
        (work : PsKernelEnvironment)
        (owner : Nat) =>
        match
            psKernelAddSimpleMutualConstructorsForTypeWorker
              typeShape.decl.ctors
              fuel
              safety
              resultLevel
              levels
              params
              typeNames
              allShapes
              typeShape
              owner
              headerSession
              work
              0 with
        | Except.error error =>
            Except.error error
        | Except.ok ownResult =>
            match
                smaller
                  fuel
                  safety
                  resultLevel
                  levels
                  params
                  typeNames
                  allShapes
                  headerSession
                  ownResult.environment
                  (Nat.succ owner) with
            | Except.error error =>
                Except.error error
            | Except.ok later =>
                Except.ok
                  (PsKernelAddMutualConstructorsResult.mk
                    later.environment
                    (psKernelMutualConstructorShapeListAppend
                      ownResult.shapes
                      later.shapes))


def psKernelBuildSimpleMutualRecInfosFromConstructorsWorker
    (shapes : List PsKernelSimpleMutualTypeShape) :
    List PsKernelName ->
    List PsKernelName ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelSimpleMutualConstructorShape ->
    Nat ->
    Bool ->
    Except String (List PsKernelRecursorInfo) :=
  match shapes with
  | List.nil =>
      fun
        (_recLevelParams : List PsKernelName)
        (_typeNames : List PsKernelName)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_ctorShapes : List PsKernelSimpleMutualConstructorShape)
        (_owner : Nat)
        (_isUnsafe : Bool) =>
        Except.ok List.nil
  | List.cons shape rest =>
      let smaller :=
        psKernelBuildSimpleMutualRecInfosFromConstructorsWorker
          rest;
      fun
        (recLevelParams : List PsKernelName)
        (typeNames : List PsKernelName)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (ctorShapes : List PsKernelSimpleMutualConstructorShape)
        (owner : Nat)
        (isUnsafe : Bool) =>
        match
            psKernelMutualOpenBinderListGet
              motives
              owner with
        | Option.none =>
            Except.error
              "mutual motive index is out of bounds"
        | Option.some motive =>
            let indexArgs :=
              psKernelOpenBinderExprs
                shape.indices;
            let inductExpr :=
              psKernelApplyArgs
                (PsKernelExpr.const
                  shape.decl.name
                  levels)
                (psKernelExprListAppend
                  (psKernelSimpleParamArgs params)
                  indexArgs);
            let major :=
              PsKernelOpenBinder.mk
                (PsKernelName.num
                  (psKernelSimpleInternalName
                    "mutualMajor")
                  owner)
                (PsKernelName.str
                  PsKernelName.anonymous
                  "t")
                inductExpr
                PsKernelBinderInfo.default;
            let recTypeRaw :=
              psKernelCloseOpenBinders
                (psKernelOpenBinderListAppend
                  ruleBinders
                  (psKernelOpenBinderListAppend
                    shape.indices
                    (List.cons
                      major
                      List.nil)))
                (psKernelSimpleMotiveApp
                  (PsKernelExpr.fvar
                    motive.internalName)
                  indexArgs
                  (PsKernelExpr.fvar
                    major.internalName));
            let recType :=
              psKernelExprInferImplicitAll
                recTypeRaw
                true;
            match
                psKernelMakeSimpleMutualRules
                  recLevelParams
                  shapes
                  params
                  motives
                  minors
                  ruleBinders
                  owner
                  ctorShapes with
            | Except.error error =>
                Except.error error
            | Except.ok rules =>
                let info :=
                  PsKernelRecursorInfo.mk
                    (PsKernelConstantBase.mk
                      (psKernelSimpleRecName
                        shape.decl.name)
                      recLevelParams
                      recType)
                    typeNames
                    (psKernelOpenBinderListLength params)
                    (psKernelOpenBinderListLength
                      shape.indices)
                    (psKernelOpenBinderListLength motives)
                    (psKernelOpenBinderListLength minors)
                    rules
                    false
                    isUnsafe;
                match
                    smaller
                      recLevelParams
                      typeNames
                      levels
                      params
                      motives
                      minors
                      ruleBinders
                      ctorShapes
                      (Nat.succ owner)
                      isUnsafe with
                | Except.error error =>
                    Except.error error
                | Except.ok tail =>
                    Except.ok
                      (List.cons info tail)

def psKernelAddMutualRecursorInfos
    (infos : List PsKernelRecursorInfo) :
    PsKernelEnvironment -> PsKernelEnvironment :=
  match infos with
  | List.nil =>
      fun
        (environment : PsKernelEnvironment) =>
        environment
  | List.cons info rest =>
      let smaller :
          PsKernelEnvironment -> PsKernelEnvironment :=
        psKernelAddMutualRecursorInfos rest;
      fun
        (environment : PsKernelEnvironment) =>
        smaller
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.recInfo
              info))

def psKernelValidateMutualRecursorInfosWorker
    (infos : List PsKernelRecursorInfo) :
    Nat ->
    PsKernelEnvironment ->
    List PsKernelName ->
    PsKernelDefinitionSafety ->
    Nat ->
    Nat ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelSimpleMutualConstructorShape ->
    Nat ->
    Except String Unit :=
  match infos with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_environment : PsKernelEnvironment)
        (_recLevelParams : List PsKernelName)
        (_safety : PsKernelDefinitionSafety)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_motives : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_ctorShapes : List PsKernelSimpleMutualConstructorShape)
        (_owner : Nat) =>
        Except.ok ()
  | List.cons info rest =>
      let smaller :=
        psKernelValidateMutualRecursorInfosWorker
          rest;
      fun
        (fuel : Nat)
        (environment : PsKernelEnvironment)
        (recLevelParams : List PsKernelName)
        (safety : PsKernelDefinitionSafety)
        (maxRecDepth : Nat)
        (maxNatSize : Nat)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (motives : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (ctorShapes : List PsKernelSimpleMutualConstructorShape)
        (owner : Nat) =>
        let recSession :=
          psKernelMkCheckerSession
            environment
            recLevelParams
            safety
            maxRecDepth
            maxNatSize;
        match
            psKernelSessionCheck
              fuel
              recSession
              info.base.type with
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
            | Except.ok recSort =>
                match
                    psKernelValidateSimpleMutualRules
                      fuel
                      (Prod.snd recSort)
                      levels
                      params
                      motives
                      minors
                      ruleBinders
                      owner
                      ctorShapes
                      info.rules with
                | Except.error error =>
                    Except.error error
                | Except.ok _ =>
                    smaller
                      fuel
                      environment
                      recLevelParams
                      safety
                      maxRecDepth
                      maxNatSize
                      levels
                      params
                      motives
                      minors
                      ruleBinders
                      ctorShapes
                      (Nat.succ owner)

def psKernelAddSimpleMutualInductive
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  if psKernelNameHasDuplicates decl.levelParams then
    Except.error
      "duplicate universe parameter"
  else if
      psKernelNatLt
        (psKernelSimpleMutualTypeCount
          decl.types)
        2 then
    Except.error
      "mutual inductive admission requires at least two datatypes"
  else
    let typeNames :=
      psKernelSimpleMutualNames
        decl.types;
    let recNames :=
      psKernelSimpleMutualRecNames
        decl.types;
    let ctorNames :=
      psKernelSimpleMutualCtorNames
        decl.types;
    let allNames :=
      psKernelMutualNameListAppend
        typeNames
        (psKernelMutualNameListAppend
          recNames
          ctorNames);
    if psKernelSimpleNameListUnique allNames then
      match
          psKernelCheckFreshInductiveNames
            allNames
            environment with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSimpleCheckUniformOccurrences
                typeNames
                decl.levelParams
                decl.numParams
                (psKernelSimpleMutualCtorTypes
                  decl.types) with
          | Except.error error =>
              Except.error error
          | Except.ok _ =>
              match decl.types with
              | List.nil =>
                  Except.error
                    "empty mutual inductive declaration"
              | List.cons first remaining =>
                  match
                      psKernelCheckNoMVarNoFVar
                        first.type with
                  | Except.error error =>
                      Except.error error
                  | Except.ok _ =>
                      match
                          psKernelCheckLevelParams
                            first.type
                            decl.levelParams with
                      | Except.error error =>
                          Except.error error
                      | Except.ok _ =>
                          let safety :=
                            if decl.isUnsafe then
                              PsKernelDefinitionSafety.unsafeDef
                            else
                              PsKernelDefinitionSafety.safe;
                          let levels :=
                            psKernelLevelParamsToLevels
                              decl.levelParams;
                          let firstSession :=
                            psKernelMkCheckerSession
                              environment
                              decl.levelParams
                              safety
                              maxRecDepth
                              maxNatSize;
                          match
                              psKernelSessionCheck
                                fuel
                                firstSession
                                first.type with
                          | Except.error error =>
                              Except.error error
                          | Except.ok firstTypeType =>
                              match
                                  psKernelSessionEnsureSort
                                    fuel
                                    (Prod.snd firstTypeType)
                                    (Prod.fst firstTypeType) with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok firstSort =>
                                  match
                                      psKernelOpenSimpleHeaderParams
                                        fuel
                                        (Prod.snd firstSort)
                                        first.type
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
                                      | Except.ok firstIndices =>
                                          match firstIndices.result with
                                          | PsKernelExpr.sort resultLevel =>
                                              let params :=
                                                paramResult.binders;
                                              let firstShape :=
                                                PsKernelSimpleMutualTypeShape.mk
                                                  first
                                                  firstIndices.binders;
                                              match
                                                  psKernelOpenSimpleMutualRemainingTypesWorker
                                                    remaining
                                                    fuel
                                                    environment
                                                    decl.levelParams
                                                    safety
                                                    maxRecDepth
                                                    maxNatSize
                                                    paramResult.session
                                                    params
                                                    resultLevel with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok tailShapes =>
                                                  let typeShapes :=
                                                    List.cons
                                                      firstShape
                                                      tailShapes;
                                                  let baseInfos :=
                                                    psKernelMakeSimpleMutualBaseInfos
                                                      typeNames
                                                      decl
                                                      typeShapes;
                                                  let work0 :=
                                                    psKernelAddMutualInductiveInfos
                                                      baseInfos
                                                      environment;
                                                  match
                                                      psKernelAddSimpleMutualTypesWorker
                                                        typeShapes
                                                        fuel
                                                        safety
                                                        resultLevel
                                                        levels
                                                        params
                                                        typeNames
                                                        typeShapes
                                                        paramResult.session
                                                        work0
                                                        0 with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok ctorResult =>
                                                      let ctorShapes :=
                                                        ctorResult.shapes;
                                                      let isRecursive :=
                                                        psKernelSimpleMutualHasRecursiveFields
                                                          ctorShapes;
                                                      let isReflexive :=
                                                        psKernelSimpleMutualHasReflexiveFields
                                                          ctorShapes;
                                                      let work1 :=
                                                        psKernelReplaceMutualInductiveInfos
                                                          baseInfos
                                                          isRecursive
                                                          isReflexive
                                                          ctorResult.environment;
                                                      let elimOnlyAtZero :=
                                                        if
                                                            psKernelLevelIsNotZero
                                                              resultLevel then
                                                          false
                                                        else
                                                          true;
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
                                                      let motives :=
                                                        psKernelMakeSimpleMutualMotives
                                                          levels
                                                          params
                                                          elimLevel
                                                          typeShapes;
                                                      match
                                                          psKernelMakeSimpleMutualMinors
                                                            levels
                                                            params
                                                            motives
                                                            ctorShapes with
                                                      | Except.error error =>
                                                          Except.error error
                                                      | Except.ok minors =>
                                                          let ruleBinders :=
                                                            psKernelOpenBinderListAppend
                                                              params
                                                              (psKernelOpenBinderListAppend
                                                                motives
                                                                minors);
                                                          match
                                                              psKernelBuildSimpleMutualRecInfosFromConstructorsWorker
                                                                typeShapes
                                                                recLevelParams
                                                                typeNames
                                                                levels
                                                                params
                                                                motives
                                                                minors
                                                                ruleBinders
                                                                ctorShapes
                                                                0
                                                                decl.isUnsafe with
                                                          | Except.error error =>
                                                              Except.error error
                                                          | Except.ok recInfos =>
                                                              let work2 :=
                                                                psKernelAddMutualRecursorInfos
                                                                  recInfos
                                                                  work1;
                                                              match
                                                                  psKernelValidateMutualRecursorInfosWorker
                                                                    recInfos
                                                                    fuel
                                                                    work2
                                                                    recLevelParams
                                                                    safety
                                                                    maxRecDepth
                                                                    maxNatSize
                                                                    levels
                                                                    params
                                                                    motives
                                                                    minors
                                                                    ruleBinders
                                                                    ctorShapes
                                                                    0 with
                                                              | Except.error error =>
                                                                  Except.error error
                                                              | Except.ok _ =>
                                                                  Except.ok
                                                                    work2
                                          | _ =>
                                              Except.error
                                                "mutual inductive result must be a sort"
    else
      Except.error
        "duplicate mutual inductive, constructor, or recursor name"
