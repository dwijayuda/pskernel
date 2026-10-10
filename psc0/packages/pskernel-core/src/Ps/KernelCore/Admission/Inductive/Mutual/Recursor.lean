import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

/-
Mutual-inductive recursor construction.

This module builds motives, minors, recursive calls, computation rules, and
validates those rules. Environment admission remains in the separate Admission
module so recursor theory can be studied independently.
-/

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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
