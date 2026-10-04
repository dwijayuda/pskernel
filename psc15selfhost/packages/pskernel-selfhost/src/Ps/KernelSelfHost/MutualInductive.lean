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
