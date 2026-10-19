import Ps.KernelCore.Admission.Inductive.Nested.Rebase

/-
Nested-inductive auxiliary-family discovery.

This module identifies outer nested families, chooses collision-safe auxiliary
names, builds auxiliary constructors, and accumulates the additional mutual
declarations required by flattening.
-/

def psKernelSimpleNestedFindFamily
    (template : PsKernelExpr)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Option PsKernelSimpleNestedAuxFamily :=
  match families with
  | List.nil =>
      Option.none
  | List.cons family rest =>
      if
          psKernelExprEq
            family.nestedTemplate
            template then
        Option.some family
      else
        psKernelSimpleNestedFindFamily
          template
          rest

def psKernelSimpleNestedAuxNameTakenWorker
    (families : List PsKernelSimpleNestedAuxFamily) :
    PsKernelEnvironment ->
    PsKernelName ->
    Bool :=
  match families with
  | List.nil =>
      fun
        (environment : PsKernelEnvironment)
        (name : PsKernelName) =>
        psKernelEnvironmentContains
          environment
          name
  | List.cons family rest =>
      let smaller :
          PsKernelEnvironment ->
          PsKernelName ->
          Bool :=
        psKernelSimpleNestedAuxNameTakenWorker
          rest;
      fun
        (environment : PsKernelEnvironment)
        (name : PsKernelName) =>
        if psKernelEnvironmentContains environment name then
          true
        else if psKernelNameEq family.auxName name then
          true
        else
          smaller
            environment
            name

def psKernelSimpleNestedAuxNameTaken
    (environment : PsKernelEnvironment)
    (families : List PsKernelSimpleNestedAuxFamily)
    (name : PsKernelName) : Bool :=
  psKernelSimpleNestedAuxNameTakenWorker
    families
    environment
    name

def psKernelSimpleNestedFreshAuxNameWithFuel
    (fuel : Nat) :
    PsKernelEnvironment ->
    List PsKernelSimpleNestedAuxFamily ->
    PsKernelName ->
    Nat ->
    Except String (Prod PsKernelName Nat) :=
  match fuel with
  | Nat.zero =>
      fun
        (_environment : PsKernelEnvironment)
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_outer : PsKernelName)
        (_index : Nat) =>
        Except.error
          "nested auxiliary-name budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedFreshAuxNameWithFuel
          remaining;
      fun
        (environment : PsKernelEnvironment)
        (families : List PsKernelSimpleNestedAuxFamily)
        (outer : PsKernelName)
        (index : Nat) =>
        let base :=
          psKernelNameAppend
            psKernelSimpleNestedPrefix
            outer;
        let candidate :=
          psKernelNameAppendIndexAfter
            base
            index;
        if
            psKernelSimpleNestedAuxNameTaken
              environment
              families
              candidate then
          smaller
            environment
            families
            outer
            (Nat.succ index)
        else
          Except.ok
            (Prod.mk
              candidate
              (Nat.succ index))

def psKernelSimpleNestedFreshAuxName
    (environment : PsKernelEnvironment)
    (families : List PsKernelSimpleNestedAuxFamily)
    (outer : PsKernelName)
    (index : Nat) :
    Except String (Prod PsKernelName Nat) :=
  psKernelSimpleNestedFreshAuxNameWithFuel
    4096
    environment
    families
    outer
    index

def psKernelSimpleNestedCtorName
    (outerName : PsKernelName)
    (auxName : PsKernelName)
    (ctorName : PsKernelName) :
    Except String PsKernelName :=
  match
      psKernelNameReplacePrefix
        ctorName
        outerName
        auxName with
  | Option.some name =>
      Except.ok name
  | Option.none =>
      Except.error
        "nested outer constructor name is outside its inductive namespace"


structure PsKernelSimpleNestedAuxCtorsResult where
  ctors : List PsKernelSimpleConstructorDecl
  ctorMap : List PsKernelSimpleNestedAuxCtorMap

structure PsKernelSimpleNestedEnsureFamilyResult where
  family : PsKernelSimpleNestedAuxFamily
  state : PsKernelSimpleNestedMapState

def psKernelSimpleNestedFamilyListAppend
    (left : List PsKernelSimpleNestedAuxFamily) :
    List PsKernelSimpleNestedAuxFamily ->
    List PsKernelSimpleNestedAuxFamily :=
  match left with
  | List.nil =>
      fun
        (right : List PsKernelSimpleNestedAuxFamily) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleNestedAuxFamily ->
          List PsKernelSimpleNestedAuxFamily :=
        psKernelSimpleNestedFamilyListAppend
          tail;
      fun
        (right : List PsKernelSimpleNestedAuxFamily) =>
        List.cons
          head
          (smaller right)

def psKernelSimpleNestedTypeDeclListAppend
    (left : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelSimpleMutualTypeDecl ->
    List PsKernelSimpleMutualTypeDecl :=
  match left with
  | List.nil =>
      fun
        (right : List PsKernelSimpleMutualTypeDecl) =>
        right
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleMutualTypeDecl ->
          List PsKernelSimpleMutualTypeDecl :=
        psKernelSimpleNestedTypeDeclListAppend
          tail;
      fun
        (right : List PsKernelSimpleMutualTypeDecl) =>
        List.cons
          head
          (smaller right)

def psKernelSimpleNestedBuildAuxCtorsWorker
    (ctorNames : List PsKernelName) :
    PsKernelEnvironment ->
    PsKernelName ->
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelExpr ->
    List PsKernelOpenBinder ->
    Except String PsKernelSimpleNestedAuxCtorsResult :=
  match ctorNames with
  | List.nil =>
      fun
        (_environment : PsKernelEnvironment)
        (_familyName : PsKernelName)
        (_auxName : PsKernelName)
        (_outerLevels : List PsKernelLevel)
        (_fixedCurrent : List PsKernelExpr)
        (_currentParams : List PsKernelOpenBinder) =>
        Except.ok
          (PsKernelSimpleNestedAuxCtorsResult.mk
            List.nil
            List.nil)
  | List.cons outerCtorName more =>
      let smaller :=
        psKernelSimpleNestedBuildAuxCtorsWorker
          more;
      fun
        (environment : PsKernelEnvironment)
        (familyName : PsKernelName)
        (auxName : PsKernelName)
        (outerLevels : List PsKernelLevel)
        (fixedCurrent : List PsKernelExpr)
        (currentParams : List PsKernelOpenBinder) =>
        match
            psKernelEnvironmentFind
              environment
              outerCtorName with
        | Option.none =>
            Except.error
              "nested outer constructor metadata is missing"
        | Option.some info =>
            match info with
            | PsKernelConstantInfo.ctorInfo outerCtor =>
                match
                    psKernelSimpleNestedCtorName
                      familyName
                      auxName
                      outerCtorName with
                | Except.error error =>
                    Except.error error
                | Except.ok auxCtorName =>
                    let ctorType0 :=
                      psKernelExprInstantiateLevelParams
                        outerCtor.base.type
                        outerCtor.base.levelParams
                        outerLevels;
                    match
                        psKernelSimpleNestedInstantiateFirstParams
                          ctorType0
                          fixedCurrent with
                    | Except.error error =>
                        Except.error error
                    | Except.ok auxCtorOpen =>
                        let auxCtorType :=
                          psKernelCloseOpenBinders
                            currentParams
                            auxCtorOpen;
                        match
                            smaller
                              environment
                              familyName
                              auxName
                              outerLevels
                              fixedCurrent
                              currentParams with
                        | Except.error error =>
                            Except.error error
                        | Except.ok later =>
                            Except.ok
                              (PsKernelSimpleNestedAuxCtorsResult.mk
                                (List.cons
                                  (PsKernelSimpleConstructorDecl.mk
                                    auxCtorName
                                    auxCtorType)
                                  later.ctors)
                                (List.cons
                                  (PsKernelSimpleNestedAuxCtorMap.mk
                                    auxCtorName
                                    outerCtorName)
                                  later.ctorMap))
            | _ =>
                Except.error
                  "nested outer constructor metadata is missing"

def psKernelSimpleNestedRebaseExprList
    (values : List PsKernelExpr)
    (sourceParams : List PsKernelOpenBinder)
    (targetParams : List PsKernelOpenBinder) :
    List PsKernelExpr :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (psKernelSimpleNestedRebaseParams
          head
          sourceParams
          targetParams)
        (psKernelSimpleNestedRebaseExprList
          tail
          sourceParams
          targetParams)

def psKernelSimpleNestedEnsureFamiliesWorker
    (names : List PsKernelName) :
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    PsKernelName ->
    List PsKernelLevel ->
    List PsKernelExpr ->
    PsKernelSimpleNestedMapState ->
    Option PsKernelSimpleNestedAuxFamily ->
    Except String PsKernelSimpleNestedEnsureFamilyResult :=
  match names with
  | List.nil =>
      fun
        (_environment : PsKernelEnvironment)
        (_declLevels : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_currentParams : List PsKernelOpenBinder)
        (_outerName : PsKernelName)
        (_outerLevels : List PsKernelLevel)
        (_canonicalFixed : List PsKernelExpr)
        (work : PsKernelSimpleNestedMapState)
        (selected : Option PsKernelSimpleNestedAuxFamily) =>
        match selected with
        | Option.some family =>
            Except.ok
              (PsKernelSimpleNestedEnsureFamilyResult.mk
                family
                work)
        | Option.none =>
            Except.error
              "nested family selection failed"
  | List.cons familyName rest =>
      let smaller :=
        psKernelSimpleNestedEnsureFamiliesWorker
          rest;
      fun
        (environment : PsKernelEnvironment)
        (declLevels : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (currentParams : List PsKernelOpenBinder)
        (outerName : PsKernelName)
        (outerLevels : List PsKernelLevel)
        (canonicalFixed : List PsKernelExpr)
        (work : PsKernelSimpleNestedMapState)
        (selected : Option PsKernelSimpleNestedAuxFamily) =>
        match
            psKernelEnvironmentFind
              environment
              familyName with
        | Option.none =>
            Except.error
              "invalid outer mutual inductive metadata"
        | Option.some infoValue =>
            match infoValue with
            | PsKernelConstantInfo.inductInfo info =>
                match
                    psKernelEnvironmentFind
                      environment
                      outerName with
                | Option.some outerValue =>
                    match outerValue with
                    | PsKernelConstantInfo.inductInfo outer =>
                        if
                            Nat.beq
                              info.numParams
                              outer.numParams then
                          let familyTemplate :=
                            psKernelApplyArgs
                              (PsKernelExpr.const
                                familyName
                                outerLevels)
                              canonicalFixed;
                          match
                              psKernelSimpleNestedFindFamily
                                familyTemplate
                                work.aux with
                          | Option.some existing =>
                              let nextSelected :=
                                if
                                    psKernelNameEq
                                      familyName
                                      outerName then
                                  Option.some existing
                                else
                                  selected;
                              smaller
                                environment
                                declLevels
                                canonicalParams
                                currentParams
                                outerName
                                outerLevels
                                canonicalFixed
                                work
                                nextSelected
                          | Option.none =>
                              match
                                  psKernelSimpleNestedFreshAuxName
                                    environment
                                    work.aux
                                    familyName
                                    work.fresh with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok freshResult =>
                                  let auxName :=
                                    Prod.fst freshResult;
                                  let freshNext :=
                                    Prod.snd freshResult;
                                  let outerType0 :=
                                    psKernelExprInstantiateLevelParams
                                      info.base.type
                                      info.base.levelParams
                                      outerLevels;
                                  let fixedCurrent :=
                                    psKernelSimpleNestedRebaseExprList
                                      canonicalFixed
                                      canonicalParams
                                      currentParams;
                                  match
                                      psKernelSimpleNestedInstantiateFirstParams
                                        outerType0
                                        fixedCurrent with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok auxTypeOpen =>
                                      let auxType :=
                                        psKernelCloseOpenBinders
                                          currentParams
                                          auxTypeOpen;
                                      match
                                          psKernelSimpleNestedBuildAuxCtorsWorker
                                            info.ctors
                                            environment
                                            familyName
                                            auxName
                                            outerLevels
                                            fixedCurrent
                                            currentParams with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok ctorResult =>
                                          let family :=
                                            PsKernelSimpleNestedAuxFamily.mk
                                              auxName
                                              familyName
                                              outerLevels
                                              canonicalFixed
                                              familyTemplate
                                              ctorResult.ctorMap;
                                          let auxTypeDecl :=
                                            PsKernelSimpleMutualTypeDecl.mk
                                              auxName
                                              auxType
                                              ctorResult.ctors;
                                          let nextWork :=
                                            PsKernelSimpleNestedMapState.mk
                                              (psKernelSimpleNestedFamilyListAppend
                                                work.aux
                                                (List.cons
                                                  family
                                                  List.nil))
                                              freshNext
                                              (psKernelSimpleNestedTypeDeclListAppend
                                                work.created
                                                (List.cons
                                                  auxTypeDecl
                                                  List.nil));
                                          let nextSelected :=
                                            if
                                                psKernelNameEq
                                                  familyName
                                                  outerName then
                                              Option.some family
                                            else
                                              selected;
                                          smaller
                                            environment
                                            declLevels
                                            canonicalParams
                                            currentParams
                                            outerName
                                            outerLevels
                                            canonicalFixed
                                            nextWork
                                            nextSelected
                        else
                          Except.error
                            "outer mutual inductive parameters are inconsistent"
                    | _ =>
                        Except.error
                          "nested family head is not an inductive datatype"
                | Option.none =>
                    Except.error
                      "nested family head is not an inductive datatype"
            | _ =>
                Except.error
                  "invalid outer mutual inductive metadata"

def psKernelSimpleNestedEnsureFamily
    (environment : PsKernelEnvironment)
    (declLevels : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (currentParams : List PsKernelOpenBinder)
    (template : PsKernelExpr)
    (fixedCurrent : List PsKernelExpr)
    (state : PsKernelSimpleNestedMapState) :
    Except String PsKernelSimpleNestedEnsureFamilyResult :=
  match
      psKernelSimpleNestedFindFamily
        template
        state.aux with
  | Option.some family =>
      Except.ok
        (PsKernelSimpleNestedEnsureFamilyResult.mk
          family
          state)
  | Option.none =>
      match psKernelExprGetAppFn template with
      | PsKernelExpr.const outerName outerLevels =>
          match
              psKernelEnvironmentFind
                environment
                outerName with
          | Option.none =>
              Except.error
                "nested family head is not an inductive datatype"
          | Option.some infoValue =>
              match infoValue with
              | PsKernelConstantInfo.inductInfo outer =>
                  let canonicalFixed :=
                    psKernelExprGetAppArgs
                      template;
                  if
                      Nat.beq
                        (psKernelExprListLength canonicalFixed)
                        outer.numParams then
                    if
                        Nat.beq
                          (psKernelExprListLength fixedCurrent)
                          outer.numParams then
                      psKernelSimpleNestedEnsureFamiliesWorker
                        outer.all
                        environment
                        declLevels
                        canonicalParams
                        currentParams
                        outerName
                        outerLevels
                        canonicalFixed
                        state
                        Option.none
                    else
                      Except.error
                        "nested template does not contain exactly the fixed outer parameters"
                  else
                    Except.error
                      "nested template does not contain exactly the fixed outer parameters"
              | _ =>
                  Except.error
                    "nested family head is not an inductive datatype"
      | _ =>
          Except.error
            "nested family head is not a constant"


structure PsKernelSimpleNestedMapExprResult where
  expr : PsKernelExpr
  state : PsKernelSimpleNestedMapState

structure PsKernelSimpleNestedMapConstructorsResult where
  ctors : List PsKernelSimpleConstructorDecl
  state : PsKernelSimpleNestedMapState

structure PsKernelSimpleNestedProcessQueueResult where
  types : List PsKernelSimpleMutualTypeDecl
  state : PsKernelSimpleNestedMapState

def psKernelSimpleNestedHasNew
    (newNames : List PsKernelName)
    (expr : PsKernelExpr) : Bool :=
  psKernelSimpleMutualContainsConst
    newNames
    expr

def psKernelSimpleNestedExprListHasNew
    (newNames : List PsKernelName)
    (values : List PsKernelExpr) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if
          psKernelSimpleNestedHasNew
            newNames
            head then
        true
      else
        psKernelSimpleNestedExprListHasNew
          newNames
          tail
