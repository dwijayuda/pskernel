import Ps.KernelCore.Admission.Inductive.Ordinary.Admission

/-
Mutual-inductive declaration analysis.

This module discovers mutual family targets, opens constructor fields, checks
recursive occurrences, and records the shape information consumed by recursor
construction. It intentionally contains no environment mutation.
-/


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
