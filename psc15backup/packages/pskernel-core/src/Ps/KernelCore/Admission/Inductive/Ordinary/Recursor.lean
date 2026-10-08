import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor

/-
Ordinary inductive recursor construction and validation.

This module constructs motives, minor premises, recursive hypotheses/calls and
recursor rules, then rechecks generated rule types against the kernel checker.
It does not decide whether large elimination or K-style reduction is allowed;
those restrictions live in Theory/Inductive/Elimination.
-/

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

def psKernelMakeSimpleRecursorRulesWorker
    (shapes : List PsKernelSimpleConstructorShape) :
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    List PsKernelRecursorRule :=
  match shapes with
  | List.nil =>
      fun
        (_recName : PsKernelName)
        (_recLevels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_motive : PsKernelExpr)
        (_allMinors : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_minors : List PsKernelOpenBinder) =>
        List.nil
  | List.cons shape shapeRest =>
      let smaller :
          PsKernelName ->
          List PsKernelLevel ->
          List PsKernelOpenBinder ->
          PsKernelExpr ->
          List PsKernelOpenBinder ->
          List PsKernelOpenBinder ->
          List PsKernelOpenBinder ->
          List PsKernelRecursorRule :=
        psKernelMakeSimpleRecursorRulesWorker shapeRest;
      fun
        (recName : PsKernelName)
        (recLevels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (motive : PsKernelExpr)
        (allMinors : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (minors : List PsKernelOpenBinder) =>
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
              (smaller
                recName
                recLevels
                params
                motive
                allMinors
                ruleBinders
                minorRest)

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
  psKernelMakeSimpleRecursorRulesWorker
    shapes
    recName
    recLevels
    params
    motive
    allMinors
    ruleBinders
    minors

