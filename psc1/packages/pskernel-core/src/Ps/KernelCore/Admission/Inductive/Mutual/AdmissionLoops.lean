import Ps.KernelCore.Admission.Inductive.Mutual.Header

/-
Mutual-inductive constructor and recursor admission loops.

After the shared header has been established, this module:
- checks and installs constructors for each family;
- accumulates constructor shapes across the mutual bundle;
- constructs generated recursor information;
- installs and validates those recursors.

The final all-or-nothing bundle transaction remains in `Admission.lean`.
-/

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
    List PsKernelSimpleMutualTypeShape ->
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
        (_allShapes : List PsKernelSimpleMutualTypeShape)
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
        (allShapes : List PsKernelSimpleMutualTypeShape)
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
                  allShapes
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
                      allShapes
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

