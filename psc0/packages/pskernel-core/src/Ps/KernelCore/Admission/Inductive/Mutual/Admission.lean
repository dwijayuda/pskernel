import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops

/-
Mutual-inductive top-level environment admission.

This module is intentionally the readable transaction boundary: validate the
bundle-level invariants, prepare shared headers, admit constructors, build and
validate recursors, then commit the checked mutual bundle.

Detailed setup and loops live in `Header.lean` and `AdmissionLoops.lean`.
-/

def psKernelAddSimpleMutualInductive
    [cachePolicy : PsKernelSemanticCachePolicy]
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
