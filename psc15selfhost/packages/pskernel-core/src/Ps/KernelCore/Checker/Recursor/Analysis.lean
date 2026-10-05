import Ps.KernelCore.Checker.Inference

/-
Recursor-major analysis and constructor conversion.

This module identifies the recursor's major inductive family and implements the
Lean 4.34 K-conversion / non-recursive-structure conversion prerequisites for
iota reduction. It does not perform recursor rule application itself.
-/


def psKernelFindRecursorRule
    (ctorName : PsKernelName)
    (rules : List PsKernelRecursorRule) :
    Option PsKernelRecursorRule :=
  match rules with
  | List.nil =>
      Option.none
  | List.cons rule rest =>
      if psKernelNameEq rule.ctor ctorName then
        Option.some rule
      else
        psKernelFindRecursorRule
          ctorName
          rest

def psKernelRecursorMajorInductWithFuel
    (fuel : Nat) :
    PsKernelExpr -> Nat -> Option PsKernelName :=
  match fuel with
  | Nat.zero =>
      fun
        (_expr : PsKernelExpr)
        (_index : Nat) =>
        Option.none
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr -> Nat -> Option PsKernelName :=
        psKernelRecursorMajorInductWithFuel remaining;
      fun
        (expr : PsKernelExpr)
        (index : Nat) =>
        match expr with
        | PsKernelExpr.forallE _ domain body _ =>
            match index with
            | Nat.zero =>
                match psKernelExprGetAppFn domain with
                | PsKernelExpr.const name _ =>
                    Option.some name
                | _ =>
                    Option.none
            | Nat.succ rest =>
                smaller
                  body
                  rest
        | _ =>
            Option.none

def psKernelRecursorMajorInduct
    (recursor : PsKernelRecursorInfo) :
    Option PsKernelName :=
  let majorIndex :=
    Nat.add
      recursor.numParams
      (Nat.add
        recursor.numMotives
        (Nat.add
          recursor.numMinors
          recursor.numIndices));
  psKernelRecursorMajorInductWithFuel
    (Nat.succ majorIndex)
    recursor.base.type
    majorIndex

def psKernelExprHasMVarForK
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVarForK fn then
        true
      else
        psKernelExprHasMVarForK arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVarForK type then
        true
      else
        psKernelExprHasMVarForK body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVarForK type then
        true
      else
        psKernelExprHasMVarForK body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVarForK type then
        true
      else if psKernelExprHasMVarForK value then
        true
      else
        psKernelExprHasMVarForK body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVarForK body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVarForK body
  | _ =>
      false

def psKernelExprListAnyMVar
    (values : List PsKernelExpr) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelExprHasMVarForK head then
        true
      else
        psKernelExprListAnyMVar tail

def psKernelIsConstructorApp
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) : Bool :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name _ =>
      match
          psKernelEnvironmentFind
            environment
            name with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.ctorInfo _ =>
              true
          | _ =>
              false
      | Option.none =>
          false
  | _ =>
      false

def psKernelRecursorIsPropWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state expr with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          publicWhnf
            context
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedResult =>
          match Prod.fst reducedResult with
          | PsKernelExpr.sort level =>
              Except.ok
                (Prod.mk
                  (psKernelLevelNormalizesToZero level)
                  (Prod.snd reducedResult))
          | _ =>
              Except.error "expected sort"

def psKernelToConstructorWhenK
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match psKernelRecursorMajorInduct recursor with
  | Option.none =>
      Except.ok (Prod.mk major state)
  | Option.some majorInduct =>
      match inferType context state major with
      | Except.error error =>
          Except.error error
      | Except.ok majorTypeResult =>
          match
              publicWhnf
                context
                (Prod.snd majorTypeResult)
                (Prod.fst majorTypeResult) with
          | Except.error error =>
              Except.error error
          | Except.ok appTypeResult =>
              let appType :=
                Prod.fst appTypeResult;
              match psKernelExprGetAppFn appType with
              | PsKernelExpr.const typeInduct typeLevels =>
                  if
                      psKernelNameEq
                        typeInduct
                        majorInduct then
                    let indices :=
                      psKernelExprListDrop
                        recursor.numParams
                        (psKernelExprGetAppArgs appType);
                    if
                        if psKernelExprHasMVarForK appType then
                          psKernelExprListAnyMVar indices
                        else
                          false then
                      Except.ok
                        (Prod.mk
                          major
                          (Prod.snd appTypeResult))
                    else
                      match
                          psKernelEnvironmentFind
                            context.environment
                            typeInduct with
                      | Option.some info =>
                          match info with
                          | PsKernelConstantInfo.inductInfo inductInfo =>
                              match inductInfo.ctors with
                              | List.nil =>
                                  Except.ok
                                    (Prod.mk
                                      major
                                      (Prod.snd appTypeResult))
                              | List.cons ctorName _ =>
                                  let params :=
                                    psKernelExprListTake
                                      recursor.numParams
                                      (psKernelExprGetAppArgs appType);
                                  if
                                      Nat.beq
                                        (psKernelExprListLength params)
                                        recursor.numParams then
                                    let candidate :=
                                      psKernelApplyArgs
                                        (PsKernelExpr.const
                                          ctorName
                                          typeLevels)
                                        params;
                                    match
                                        inferType
                                          context
                                          (Prod.snd appTypeResult)
                                          candidate with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok candidateTypeResult =>
                                        match
                                            defeq
                                              context
                                              (Prod.snd candidateTypeResult)
                                              appType
                                              (Prod.fst candidateTypeResult) with
                                        | Except.error error =>
                                            Except.error error
                                        | Except.ok equalResult =>
                                            if Prod.fst equalResult then
                                              Except.ok
                                                (Prod.mk
                                                  candidate
                                                  (Prod.snd equalResult))
                                            else
                                              Except.ok
                                                (Prod.mk
                                                  major
                                                  (Prod.snd equalResult))
                                  else
                                    Except.ok
                                      (Prod.mk
                                        major
                                        (Prod.snd appTypeResult))
                          | _ =>
                              Except.ok
                                (Prod.mk
                                  major
                                  (Prod.snd appTypeResult))
                      | Option.none =>
                          Except.ok
                            (Prod.mk
                              major
                              (Prod.snd appTypeResult))
                  else
                    Except.ok
                      (Prod.mk
                        major
                        (Prod.snd appTypeResult))
              | _ =>
                  Except.ok
                    (Prod.mk
                      major
                      (Prod.snd appTypeResult))

def psKernelExprListAppend
    (left : List PsKernelExpr)
    (right : List PsKernelExpr) :
    List PsKernelExpr :=
  match left with
  | List.nil =>
      right
  | List.cons head tail =>
      List.cons
        head
        (psKernelExprListAppend
          tail
          right)

def psKernelStructureFieldsWithFuel
    (fuel : Nat) :
    PsKernelName ->
    PsKernelExpr ->
    Nat ->
    Nat ->
    List PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_inductName : PsKernelName)
        (_major : PsKernelExpr)
        (_fieldCount : Nat)
        (_index : Nat) =>
        List.nil
  | Nat.succ remaining =>
      let smaller :=
        psKernelStructureFieldsWithFuel remaining;
      fun
        (inductName : PsKernelName)
        (major : PsKernelExpr)
        (fieldCount : Nat)
        (index : Nat) =>
        if psKernelNatLt index fieldCount then
          List.cons
            (PsKernelExpr.proj
              inductName
              index
              major)
            (smaller
              inductName
              major
              fieldCount
              (Nat.succ index))
        else
          List.nil

def psKernelToConstructorWhenStructure
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  if
      psKernelIsConstructorApp
        context.environment
        major then
    Except.ok
      (Prod.mk major state)
  else
    match psKernelRecursorMajorInduct recursor with
    | Option.none =>
        Except.ok
          (Prod.mk major state)
    | Option.some inductName =>
        if
            psKernelEnvironmentIsNonRecStructure
              context.environment
              inductName then
          match inferType context state major with
          | Except.error error =>
              Except.error error
          | Except.ok majorTypeResult =>
              match
                  publicWhnf
                    context
                    (Prod.snd majorTypeResult)
                    (Prod.fst majorTypeResult) with
              | Except.error error =>
                  Except.error error
              | Except.ok reducedTypeResult =>
                  let majorType :=
                    Prod.fst reducedTypeResult;
                  match psKernelExprGetAppFn majorType with
                  | PsKernelExpr.const typeName levels =>
                      if psKernelNameEq typeName inductName then
                        match
                            psKernelRecursorIsPropWith
                              publicWhnf
                              inferType
                              context
                              (Prod.snd reducedTypeResult)
                              majorType with
                        | Except.error error =>
                            Except.error error
                        | Except.ok propResult =>
                            if Prod.fst propResult then
                              Except.ok
                                (Prod.mk
                                  major
                                  (Prod.snd propResult))
                            else
                              match
                                  psKernelEnvironmentFind
                                    context.environment
                                    inductName with
                              | Option.some info =>
                                  match info with
                                  | PsKernelConstantInfo.inductInfo inductInfo =>
                                      match inductInfo.ctors with
                                      | List.cons ctorName ctorTail =>
                                          match ctorTail with
                                          | List.nil =>
                                              match
                                                  psKernelEnvironmentFind
                                                    context.environment
                                                    ctorName with
                                              | Option.some ctorValue =>
                                                  match ctorValue with
                                                  | PsKernelConstantInfo.ctorInfo ctorInfo =>
                                                      let args :=
                                                        psKernelExprGetAppArgs
                                                          majorType;
                                                      if
                                                          Nat.ble
                                                            ctorInfo.numParams
                                                            (psKernelExprListLength args) then
                                                        let params :=
                                                          psKernelExprListTake
                                                            ctorInfo.numParams
                                                            args;
                                                        let fields :=
                                                          psKernelStructureFieldsWithFuel
                                                            (Nat.succ ctorInfo.numFields)
                                                            inductName
                                                            major
                                                            ctorInfo.numFields
                                                            0;
                                                        Except.ok
                                                          (Prod.mk
                                                            (psKernelApplyArgs
                                                              (PsKernelExpr.const
                                                                ctorName
                                                                levels)
                                                              (psKernelExprListAppend
                                                                params
                                                                fields))
                                                            (Prod.snd propResult))
                                                      else
                                                        Except.ok
                                                          (Prod.mk
                                                            major
                                                            (Prod.snd propResult))
                                                  | _ =>
                                                      Except.ok
                                                        (Prod.mk
                                                          major
                                                          (Prod.snd propResult))
                                              | Option.none =>
                                                  Except.ok
                                                    (Prod.mk
                                                      major
                                                      (Prod.snd propResult))
                                          | List.cons _ _ =>
                                              Except.ok
                                                (Prod.mk
                                                  major
                                                  (Prod.snd propResult))
                                      | List.nil =>
                                          Except.ok
                                            (Prod.mk
                                              major
                                              (Prod.snd propResult))
                                  | _ =>
                                      Except.ok
                                        (Prod.mk
                                          major
                                          (Prod.snd propResult))
                              | Option.none =>
                                  Except.ok
                                    (Prod.mk
                                      major
                                      (Prod.snd propResult))
                      else
                        Except.ok
                          (Prod.mk
                            major
                            (Prod.snd reducedTypeResult))
                  | _ =>
                      Except.ok
                        (Prod.mk
                          major
                          (Prod.snd reducedTypeResult))
        else
          Except.ok
            (Prod.mk major state)
