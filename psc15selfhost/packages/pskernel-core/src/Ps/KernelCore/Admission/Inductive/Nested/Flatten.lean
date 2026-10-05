import Ps.KernelCore.Admission.Inductive.Nested.Discover

/-
Nested-inductive flattening.

This module maps nested applications into auxiliary families, rewrites
constructor types, and processes the discovery queue to a closed transformed
mutual declaration bundle.
-/

def psKernelSimpleNestedTryMapApplication
    (environment : PsKernelEnvironment)
    (declLevels : List PsKernelName)
    (newNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (currentParams : List PsKernelOpenBinder)
    (expr : PsKernelExpr)
    (state : PsKernelSimpleNestedMapState) :
    Except String (Option PsKernelSimpleNestedMapExprResult) :=
  let fn :=
    psKernelExprGetAppFn expr;
  let args :=
    psKernelExprGetAppArgs expr;
  match fn with
  | PsKernelExpr.const outerName outerLevels =>
      match
          psKernelEnvironmentFind
            environment
            outerName with
      | Option.some infoValue =>
          match infoValue with
          | PsKernelConstantInfo.inductInfo outer =>
              if
                  Nat.ble
                    outer.numParams
                    (psKernelExprListLength
                      args) then
                let fixed :=
                  psKernelExprListTake
                    outer.numParams
                    args;
                if
                    psKernelSimpleNestedExprListHasNew
                      newNames
                      fixed then
                  let canonicalFixed :=
                    psKernelSimpleNestedRebaseExprList
                      fixed
                      currentParams
                      canonicalParams;
                  let template :=
                    psKernelApplyArgs
                      (PsKernelExpr.const
                        outerName
                        outerLevels)
                      canonicalFixed;
                  match
                      psKernelSimpleNestedEnsureFamily
                        environment
                        declLevels
                        canonicalParams
                        currentParams
                        template
                        fixed
                        state with
                  | Except.error error =>
                      Except.error error
                  | Except.ok ensured =>
                      let auxLevels :=
                        psKernelLevelParamsToLevels
                          declLevels;
                      let auxArgs :=
                        psKernelExprListAppend
                          (psKernelOpenBinderExprs
                            currentParams)
                          (psKernelExprListDrop
                            outer.numParams
                            args);
                      Except.ok
                        (Option.some
                          (PsKernelSimpleNestedMapExprResult.mk
                            (psKernelApplyArgs
                              (PsKernelExpr.const
                                ensured.family.auxName
                                auxLevels)
                              auxArgs)
                            ensured.state))
                else
                  Except.ok Option.none
              else
                Except.ok Option.none
          | _ =>
              Except.ok Option.none
      | Option.none =>
          Except.ok Option.none
  | _ =>
      Except.ok Option.none

def psKernelSimpleNestedMapExprWithFuel
    (fuel : Nat) :
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    PsKernelSimpleNestedMapState ->
    Except String PsKernelSimpleNestedMapExprResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_environment : PsKernelEnvironment)
        (_declLevels : List PsKernelName)
        (_newNames : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_currentParams : List PsKernelOpenBinder)
        (_expr : PsKernelExpr)
        (_state : PsKernelSimpleNestedMapState) =>
        Except.error
          "nested expression mapping budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedMapExprWithFuel
          remaining;
      fun
        (environment : PsKernelEnvironment)
        (declLevels : List PsKernelName)
        (newNames : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (currentParams : List PsKernelOpenBinder)
        (expr : PsKernelExpr)
        (state : PsKernelSimpleNestedMapState) =>
        match
            psKernelSimpleNestedTryMapApplication
              environment
              declLevels
              newNames
              canonicalParams
              currentParams
              expr
              state with
        | Except.error error =>
            Except.error error
        | Except.ok mapped =>
            match mapped with
            | Option.some result =>
                Except.ok result
            | Option.none =>
                match expr with
                | PsKernelExpr.app fn arg =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          fn
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok fnResult =>
                        match
                            smaller
                              environment
                              declLevels
                              newNames
                              canonicalParams
                              currentParams
                              arg
                              fnResult.state with
                        | Except.error error =>
                            Except.error error
                        | Except.ok argResult =>
                            Except.ok
                              (PsKernelSimpleNestedMapExprResult.mk
                                (PsKernelExpr.app
                                  fnResult.expr
                                  argResult.expr)
                                argResult.state)
                | PsKernelExpr.lam
                    name
                    type
                    body
                    binderInfo =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          type
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok typeResult =>
                        match
                            smaller
                              environment
                              declLevels
                              newNames
                              canonicalParams
                              currentParams
                              body
                              typeResult.state with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            Except.ok
                              (PsKernelSimpleNestedMapExprResult.mk
                                (PsKernelExpr.lam
                                  name
                                  typeResult.expr
                                  bodyResult.expr
                                  binderInfo)
                                bodyResult.state)
                | PsKernelExpr.forallE
                    name
                    type
                    body
                    binderInfo =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          type
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok typeResult =>
                        match
                            smaller
                              environment
                              declLevels
                              newNames
                              canonicalParams
                              currentParams
                              body
                              typeResult.state with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            Except.ok
                              (PsKernelSimpleNestedMapExprResult.mk
                                (PsKernelExpr.forallE
                                  name
                                  typeResult.expr
                                  bodyResult.expr
                                  binderInfo)
                                bodyResult.state)
                | PsKernelExpr.letE
                    name
                    type
                    value
                    body
                    nondep =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          type
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok typeResult =>
                        match
                            smaller
                              environment
                              declLevels
                              newNames
                              canonicalParams
                              currentParams
                              value
                              typeResult.state with
                        | Except.error error =>
                            Except.error error
                        | Except.ok valueResult =>
                            match
                                smaller
                                  environment
                                  declLevels
                                  newNames
                                  canonicalParams
                                  currentParams
                                  body
                                  valueResult.state with
                            | Except.error error =>
                                Except.error error
                            | Except.ok bodyResult =>
                                Except.ok
                                  (PsKernelSimpleNestedMapExprResult.mk
                                    (PsKernelExpr.letE
                                      name
                                      typeResult.expr
                                      valueResult.expr
                                      bodyResult.expr
                                      nondep)
                                    bodyResult.state)
                | PsKernelExpr.mdata metadata body =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          body
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok bodyResult =>
                        Except.ok
                          (PsKernelSimpleNestedMapExprResult.mk
                            (PsKernelExpr.mdata
                              metadata
                              bodyResult.expr)
                            bodyResult.state)
                | PsKernelExpr.proj typeName index body =>
                    match
                        smaller
                          environment
                          declLevels
                          newNames
                          canonicalParams
                          currentParams
                          body
                          state with
                    | Except.error error =>
                        Except.error error
                    | Except.ok bodyResult =>
                        Except.ok
                          (PsKernelSimpleNestedMapExprResult.mk
                            (PsKernelExpr.proj
                              typeName
                              index
                              bodyResult.expr)
                            bodyResult.state)
                | _ =>
                    Except.ok
                      (PsKernelSimpleNestedMapExprResult.mk
                        expr
                        state)

def psKernelSimpleNestedMapExpr
    (environment : PsKernelEnvironment)
    (declLevels : List PsKernelName)
    (newNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (currentParams : List PsKernelOpenBinder)
    (expr : PsKernelExpr)
    (state : PsKernelSimpleNestedMapState) :
    Except String PsKernelSimpleNestedMapExprResult :=
  psKernelSimpleNestedMapExprWithFuel
    (Nat.succ
      (psKernelExprNodeCount expr))
    environment
    declLevels
    newNames
    canonicalParams
    currentParams
    expr
    state

def psKernelSimpleNestedMapConstructorsWorker
    (ctors : List PsKernelSimpleConstructorDecl) :
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelSimpleNestedMapState ->
    Except String PsKernelSimpleNestedMapConstructorsResult :=
  match ctors with
  | List.nil =>
      fun
        (_environment : PsKernelEnvironment)
        (_declLevels : List PsKernelName)
        (_newNames : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (state : PsKernelSimpleNestedMapState) =>
        Except.ok
          (PsKernelSimpleNestedMapConstructorsResult.mk
            List.nil
            state)
  | List.cons ctor rest =>
      let smaller :=
        psKernelSimpleNestedMapConstructorsWorker
          rest;
      fun
        (environment : PsKernelEnvironment)
        (declLevels : List PsKernelName)
        (newNames : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (state : PsKernelSimpleNestedMapState) =>
        match
            psKernelSimpleNestedOpenConstructorParams
              ctor.type
              numParams with
        | Except.error error =>
            Except.error error
        | Except.ok opened =>
            match
                psKernelSimpleNestedMapExpr
                  environment
                  declLevels
                  newNames
                  canonicalParams
                  opened.params
                  opened.result
                  state with
            | Except.error error =>
                Except.error error
            | Except.ok mapped =>
                let mappedCtor :=
                  PsKernelSimpleConstructorDecl.mk
                    ctor.name
                    (psKernelCloseOpenBinders
                      opened.params
                      mapped.expr);
                match
                    smaller
                      environment
                      declLevels
                      newNames
                      canonicalParams
                      numParams
                      mapped.state with
                | Except.error error =>
                    Except.error error
                | Except.ok later =>
                    Except.ok
                      (PsKernelSimpleNestedMapConstructorsResult.mk
                        (List.cons
                          mappedCtor
                          later.ctors)
                        later.state)

def psKernelSimpleNestedMapConstructors
    (environment : PsKernelEnvironment)
    (declLevels : List PsKernelName)
    (newNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (ctors : List PsKernelSimpleConstructorDecl)
    (state : PsKernelSimpleNestedMapState) :
    Except String PsKernelSimpleNestedMapConstructorsResult :=
  psKernelSimpleNestedMapConstructorsWorker
    ctors
    environment
    declLevels
    newNames
    canonicalParams
    numParams
    state

def psKernelSimpleNestedProcessQueueWithFuel
    (fuel : Nat) :
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    Nat ->
    List PsKernelSimpleMutualTypeDecl ->
    List PsKernelSimpleMutualTypeDecl ->
    PsKernelSimpleNestedMapState ->
    Except String PsKernelSimpleNestedProcessQueueResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_environment : PsKernelEnvironment)
        (_declLevels : List PsKernelName)
        (_newNames : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (_pending : List PsKernelSimpleMutualTypeDecl)
        (_done : List PsKernelSimpleMutualTypeDecl)
        (_state : PsKernelSimpleNestedMapState) =>
        Except.error
          "nested preprocessing queue budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedProcessQueueWithFuel
          remaining;
      fun
        (environment : PsKernelEnvironment)
        (declLevels : List PsKernelName)
        (newNames : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (pending : List PsKernelSimpleMutualTypeDecl)
        (done : List PsKernelSimpleMutualTypeDecl)
        (state : PsKernelSimpleNestedMapState) =>
        match pending with
        | List.nil =>
            Except.ok
              (PsKernelSimpleNestedProcessQueueResult.mk
                done
                state)
        | List.cons typeDecl rest =>
            let state0 :=
              PsKernelSimpleNestedMapState.mk
                state.aux
                state.fresh
                List.nil;
            match
                psKernelSimpleNestedMapConstructors
                  environment
                  declLevels
                  newNames
                  canonicalParams
                  numParams
                  typeDecl.ctors
                  state0 with
            | Except.error error =>
                Except.error error
            | Except.ok mappedCtors =>
                let mapped :=
                  PsKernelSimpleMutualTypeDecl.mk
                    typeDecl.name
                    typeDecl.type
                    mappedCtors.ctors;
                let nextPending :=
                  psKernelSimpleNestedTypeDeclListAppend
                    rest
                    mappedCtors.state.created;
                let nextDone :=
                  psKernelSimpleNestedTypeDeclListAppend
                    done
                    (List.cons
                      mapped
                      List.nil);
                let nextState :=
                  PsKernelSimpleNestedMapState.mk
                    mappedCtors.state.aux
                    mappedCtors.state.fresh
                    List.nil;
                smaller
                  environment
                  declLevels
                  newNames
                  canonicalParams
                  numParams
                  nextPending
                  nextDone
                  nextState

def psKernelSimpleNestedProcessQueue
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (declLevels : List PsKernelName)
    (newNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (pending : List PsKernelSimpleMutualTypeDecl)
    (done : List PsKernelSimpleMutualTypeDecl)
    (state : PsKernelSimpleNestedMapState) :
    Except String PsKernelSimpleNestedProcessQueueResult :=
  psKernelSimpleNestedProcessQueueWithFuel
    (Nat.succ fuel)
    environment
    declLevels
    newNames
    canonicalParams
    numParams
    pending
    done
    state
