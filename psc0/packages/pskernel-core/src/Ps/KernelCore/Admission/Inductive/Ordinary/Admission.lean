import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission

/-
Ordinary inductive declaration admission.

This file intentionally contains only the top-level environment mutation path:
add checked constructors, validate fresh names/header/index information,
generate/check recursor metadata, and commit the checked bundle.

Supporting theory lives under Theory/Inductive.
-/

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
    [cachePolicy : PsKernelSemanticCachePolicy]
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
