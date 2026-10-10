import Ps.KernelCore.Admission.Inductive.Common.Elimination

/-
Ordinary inductive constructor admission.

This module performs the checked constructor loop after the inductive header
has been validated. For each constructor it:

1. checks closure and universe parameters;
2. checks that the constructor type itself has a sort;
3. opens common parameters and constructor fields;
4. validates recursive-field positivity/elimination constraints;
5. validates the constructor result indices;
6. installs checked constructor metadata into the working environment.

The top-level bundle transaction remains in `InductiveAdmission.lean`.
-/

def psKernelAddSimpleConstructorsWithFuel
    [cachePolicy : PsKernelSemanticCachePolicy]
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
