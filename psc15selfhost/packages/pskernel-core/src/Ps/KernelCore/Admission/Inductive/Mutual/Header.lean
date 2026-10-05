import Ps.KernelCore.Admission.Inductive.Mutual.Recursor

/-
Mutual-inductive header/setup helpers.

This module prepares a mutual bundle before constructor admission:
- collects type/constructor/recursor names;
- opens common parameters and remaining type headers;
- constructs initial inductive metadata;
- installs/replaces the working type information.

Constructor loops and recursor validation live in `AdmissionLoops.lean`.
-/

def psKernelMutualNameListAppend
    (left : List PsKernelName) :
    List PsKernelName -> List PsKernelName :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelName -> List PsKernelName :=
        psKernelMutualNameListAppend tail;
      fun (right : List PsKernelName) =>
        List.cons
          head
          (smaller right)

def psKernelMutualConstructorShapeListAppend
    (left : List PsKernelSimpleMutualConstructorShape) :
    List PsKernelSimpleMutualConstructorShape ->
    List PsKernelSimpleMutualConstructorShape :=
  match left with
  | List.nil =>
      fun
        (right : List PsKernelSimpleMutualConstructorShape) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleMutualConstructorShape ->
          List PsKernelSimpleMutualConstructorShape :=
        psKernelMutualConstructorShapeListAppend tail;
      fun
        (right : List PsKernelSimpleMutualConstructorShape) =>
        List.cons
          head
          (smaller right)

def psKernelSimpleMutualTypeCount
    (types : List PsKernelSimpleMutualTypeDecl) :
    Nat :=
  match types with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelSimpleMutualTypeCount rest)

def psKernelSimpleMutualRecNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      List.cons
        (psKernelSimpleRecName
          typeDecl.name)
        (psKernelSimpleMutualRecNames rest)

def psKernelSimpleMutualCtorNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      psKernelMutualNameListAppend
        (psKernelSimpleCtorNames
          typeDecl.ctors)
        (psKernelSimpleMutualCtorNames
          rest)

def psKernelSimpleMutualCtorTypes
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelExpr :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      psKernelExprListAppend
        (psKernelSimpleCtorTypes
          typeDecl.ctors)
        (psKernelSimpleMutualCtorTypes
          rest)

def psKernelOpenSimpleMutualRemainingTypesWorker
    (types : List PsKernelSimpleMutualTypeDecl) :
    Nat ->
    PsKernelEnvironment ->
    List PsKernelName ->
    PsKernelDefinitionSafety ->
    Nat ->
    Nat ->
    PsKernelCheckerSession ->
    List PsKernelOpenBinder ->
    PsKernelLevel ->
    Except String (List PsKernelSimpleMutualTypeShape) :=
  match types with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_environment : PsKernelEnvironment)
        (_levelParams : List PsKernelName)
        (_safety : PsKernelDefinitionSafety)
        (_maxRecDepth : Nat)
        (_maxNatSize : Nat)
        (_headerSession : PsKernelCheckerSession)
        (_params : List PsKernelOpenBinder)
        (_resultLevel : PsKernelLevel) =>
        Except.ok List.nil
  | List.cons typeDecl rest =>
      let smaller :=
        psKernelOpenSimpleMutualRemainingTypesWorker
          rest;
      fun
        (fuel : Nat)
        (environment : PsKernelEnvironment)
        (levelParams : List PsKernelName)
        (safety : PsKernelDefinitionSafety)
        (maxRecDepth : Nat)
        (maxNatSize : Nat)
        (headerSession : PsKernelCheckerSession)
        (params : List PsKernelOpenBinder)
        (resultLevel : PsKernelLevel) =>
        match
            psKernelCheckNoMVarNoFVar
              typeDecl.type with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelCheckLevelParams
                  typeDecl.type
                  levelParams with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                let closedSession :=
                  psKernelMkCheckerSession
                    environment
                    levelParams
                    safety
                    maxRecDepth
                    maxNatSize;
                match
                    psKernelSessionCheck
                      fuel
                      closedSession
                      typeDecl.type with
                | Except.error error =>
                    Except.error error
                | Except.ok typeType =>
                    match
                        psKernelSessionEnsureSort
                          fuel
                          (Prod.snd typeType)
                          (Prod.fst typeType) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok _ =>
                        match
                            psKernelOpenSimpleConstructorParams
                              fuel
                              headerSession
                              params
                              typeDecl.type with
                        | Except.error error =>
                            Except.error error
                        | Except.ok afterParams =>
                            match
                                psKernelOpenSimpleHeaderIndices
                                  fuel
                                  afterParams.session
                                  afterParams.result with
                            | Except.error error =>
                                Except.error error
                            | Except.ok indexResult =>
                                match indexResult.result with
                                | PsKernelExpr.sort level =>
                                    if
                                        psKernelLevelEquivalent
                                          level
                                          resultLevel then
                                      match
                                          smaller
                                            fuel
                                            environment
                                            levelParams
                                            safety
                                            maxRecDepth
                                            maxNatSize
                                            headerSession
                                            params
                                            resultLevel with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok tail =>
                                          Except.ok
                                            (List.cons
                                              (PsKernelSimpleMutualTypeShape.mk
                                                typeDecl
                                                indexResult.binders)
                                              tail)
                                    else
                                      Except.error
                                        "mutually inductive types must live in the same universe"
                                | _ =>
                                    Except.error
                                      "mutual inductive result must be a sort"

def psKernelMakeSimpleMutualBaseInfos
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    List PsKernelInductiveInfo :=
  match shapes with
  | List.nil =>
      List.nil
  | List.cons shape rest =>
      List.cons
        (PsKernelInductiveInfo.mk
          (PsKernelConstantBase.mk
            shape.decl.name
            decl.levelParams
            shape.decl.type)
          decl.numParams
          (psKernelOpenBinderListLength
            shape.indices)
          typeNames
          (psKernelSimpleCtorNames
            shape.decl.ctors)
          0
          false
          false
          decl.isUnsafe)
        (psKernelMakeSimpleMutualBaseInfos
          typeNames
          decl
          rest)

def psKernelAddMutualInductiveInfos
    (infos : List PsKernelInductiveInfo) :
    PsKernelEnvironment -> PsKernelEnvironment :=
  match infos with
  | List.nil =>
      fun
        (environment : PsKernelEnvironment) =>
        environment
  | List.cons info rest =>
      let smaller :
          PsKernelEnvironment -> PsKernelEnvironment :=
        psKernelAddMutualInductiveInfos rest;
      fun
        (environment : PsKernelEnvironment) =>
        smaller
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.inductInfo
              info))

def psKernelReplaceMutualInductiveInfos
    (infos : List PsKernelInductiveInfo) :
    Bool ->
    Bool ->
    PsKernelEnvironment ->
    PsKernelEnvironment :=
  match infos with
  | List.nil =>
      fun
        (_isRecursive : Bool)
        (_isReflexive : Bool)
        (environment : PsKernelEnvironment) =>
        environment
  | List.cons info rest =>
      let smaller :
          Bool ->
          Bool ->
          PsKernelEnvironment ->
          PsKernelEnvironment :=
        psKernelReplaceMutualInductiveInfos rest;
      fun
        (isRecursive : Bool)
        (isReflexive : Bool)
        (environment : PsKernelEnvironment) =>
        let finalInfo :=
          PsKernelInductiveInfo.mk
            info.base
            info.numParams
            info.numIndices
            info.all
            info.ctors
            info.numNested
            isRecursive
            isReflexive
            info.isUnsafe;
        smaller
          isRecursive
          isReflexive
          (psKernelEnvironmentReplaceUnchecked
            environment
            (PsKernelConstantInfo.inductInfo
              finalInfo))

