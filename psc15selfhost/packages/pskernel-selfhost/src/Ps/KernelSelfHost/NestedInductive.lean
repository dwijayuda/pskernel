import Ps.KernelSelfHost.MutualInductive

structure PsKernelSimpleNestedAuxCtorMap where
  auxCtor : PsKernelName
  outerCtor : PsKernelName

structure PsKernelSimpleNestedAuxFamily where
  auxName : PsKernelName
  outerName : PsKernelName
  outerLevels : List PsKernelLevel
  fixedParams : List PsKernelExpr
  nestedTemplate : PsKernelExpr
  ctorMap : List PsKernelSimpleNestedAuxCtorMap

structure PsKernelSimpleNestedMapState where
  aux : List PsKernelSimpleNestedAuxFamily
  fresh : Nat
  created : List PsKernelSimpleMutualTypeDecl

def psKernelSimpleNestedPrefix : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "_nested"

def psKernelSimpleNestedExprUsesReserved
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.const name _ =>
      psKernelNameIsPrefixOf
        psKernelSimpleNestedPrefix
        name
  | PsKernelExpr.app fn arg =>
      if psKernelSimpleNestedExprUsesReserved fn then
        true
      else
        psKernelSimpleNestedExprUsesReserved arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelSimpleNestedExprUsesReserved type then
        true
      else if psKernelSimpleNestedExprUsesReserved value then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.mdata _ body =>
      psKernelSimpleNestedExprUsesReserved body
  | PsKernelExpr.proj typeName _ body =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            typeName then
        true
      else
        psKernelSimpleNestedExprUsesReserved body
  | _ =>
      false

def psKernelSimpleNestedCheckCtorReserved
    (ctors : List PsKernelSimpleConstructorDecl) :
    Except String Unit :=
  match ctors with
  | List.nil =>
      Except.ok ()
  | List.cons ctor rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            ctor.name then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive constructor"
      else if
          psKernelSimpleNestedExprUsesReserved
            ctor.type then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive constructor"
      else
        psKernelSimpleNestedCheckCtorReserved
          rest

def psKernelSimpleNestedCheckTypeReserved
    (types : List PsKernelSimpleMutualTypeDecl) :
    Except String Unit :=
  match types with
  | List.nil =>
      Except.ok ()
  | List.cons typeDecl rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            typeDecl.name then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive declaration"
      else if
          psKernelSimpleNestedExprUsesReserved
            typeDecl.type then
        Except.error
          "reserved prefix '_nested' occurs in nested inductive declaration"
      else
        match
            psKernelSimpleNestedCheckCtorReserved
              typeDecl.ctors with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            psKernelSimpleNestedCheckTypeReserved
              rest

def psKernelSimpleNestedCheckReserved
    (decl : PsKernelSimpleMutualInductiveDecl) :
    Except String Unit :=
  psKernelSimpleNestedCheckTypeReserved
    decl.types

def psKernelSimpleNestedInstantiateFirstParamsWorker
    (args : List PsKernelExpr) :
    PsKernelExpr -> Except String PsKernelExpr :=
  match args with
  | List.nil =>
      fun (type : PsKernelExpr) =>
        Except.ok type
  | List.cons arg rest =>
      let smaller :
          PsKernelExpr -> Except String PsKernelExpr :=
        psKernelSimpleNestedInstantiateFirstParamsWorker
          rest;
      fun (type : PsKernelExpr) =>
        match type with
        | PsKernelExpr.forallE _ _ body _ =>
            smaller
              (psKernelExprInstantiate1
                body
                arg)
        | _ =>
            Except.error
              "ill-formed nested inductive parameter instantiation"

def psKernelSimpleNestedInstantiateFirstParams
    (type : PsKernelExpr)
    (args : List PsKernelExpr) :
    Except String PsKernelExpr :=
  psKernelSimpleNestedInstantiateFirstParamsWorker
    args
    type

def psKernelSimpleNestedLookupRebaseWorker
    (sourceParams : List PsKernelOpenBinder) :
    PsKernelName ->
    List PsKernelOpenBinder ->
    Option PsKernelExpr :=
  match sourceParams with
  | List.nil =>
      fun
        (_name : PsKernelName)
        (_targetParams : List PsKernelOpenBinder) =>
        Option.none
  | List.cons source rest =>
      let smaller :
          PsKernelName ->
          List PsKernelOpenBinder ->
          Option PsKernelExpr :=
        psKernelSimpleNestedLookupRebaseWorker
          rest;
      fun
        (name : PsKernelName)
        (targetParams : List PsKernelOpenBinder) =>
        match targetParams with
        | List.nil =>
            Option.none
        | List.cons target targetRest =>
            if
                psKernelNameEq
                  source.internalName
                  name then
              Option.some
                (PsKernelExpr.fvar
                  target.internalName)
            else
              smaller
                name
                targetRest

def psKernelSimpleNestedLookupRebase
    (name : PsKernelName)
    (sourceParams : List PsKernelOpenBinder)
    (targetParams : List PsKernelOpenBinder) :
    Option PsKernelExpr :=
  psKernelSimpleNestedLookupRebaseWorker
    sourceParams
    name
    targetParams

def psKernelSimpleNestedRebaseParamsWorker
    (expr : PsKernelExpr) :
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    PsKernelExpr :=
  match expr with
  | PsKernelExpr.fvar name =>
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        match
            psKernelSimpleNestedLookupRebase
              name
              sourceParams
              targetParams with
        | Option.some value =>
            value
        | Option.none =>
            expr
  | PsKernelExpr.app fn arg =>
      let left :=
        psKernelSimpleNestedRebaseParamsWorker
          fn;
      let right :=
        psKernelSimpleNestedRebaseParamsWorker
          arg;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.app
          (left sourceParams targetParams)
          (right sourceParams targetParams)
  | PsKernelExpr.lam name type body binderInfo =>
      let typeWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          type;
      let bodyWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          body;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.lam
          name
          (typeWorker
            sourceParams
            targetParams)
          (bodyWorker
            sourceParams
            targetParams)
          binderInfo
  | PsKernelExpr.forallE name type body binderInfo =>
      let typeWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          type;
      let bodyWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          body;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.forallE
          name
          (typeWorker
            sourceParams
            targetParams)
          (bodyWorker
            sourceParams
            targetParams)
          binderInfo
  | PsKernelExpr.letE name type value body nondep =>
      let typeWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          type;
      let valueWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          value;
      let bodyWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          body;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.letE
          name
          (typeWorker
            sourceParams
            targetParams)
          (valueWorker
            sourceParams
            targetParams)
          (bodyWorker
            sourceParams
            targetParams)
          nondep
  | PsKernelExpr.mdata metadata body =>
      let bodyWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          body;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.mdata
          metadata
          (bodyWorker
            sourceParams
            targetParams)
  | PsKernelExpr.proj typeName index body =>
      let bodyWorker :=
        psKernelSimpleNestedRebaseParamsWorker
          body;
      fun
        (sourceParams : List PsKernelOpenBinder)
        (targetParams : List PsKernelOpenBinder) =>
        PsKernelExpr.proj
          typeName
          index
          (bodyWorker
            sourceParams
            targetParams)
  | _ =>
      fun
        (_sourceParams : List PsKernelOpenBinder)
        (_targetParams : List PsKernelOpenBinder) =>
        expr

def psKernelSimpleNestedRebaseParams
    (expr : PsKernelExpr)
    (sourceParams : List PsKernelOpenBinder)
    (targetParams : List PsKernelOpenBinder) :
    PsKernelExpr :=
  psKernelSimpleNestedRebaseParamsWorker
    expr
    sourceParams
    targetParams

structure PsKernelSimpleNestedOpenParamsResult where
  params : List PsKernelOpenBinder
  result : PsKernelExpr

def psKernelSimpleNestedOpenConstructorParamsWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    Nat ->
    Nat ->
    List PsKernelOpenBinder ->
    Except String PsKernelSimpleNestedOpenParamsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_type : PsKernelExpr)
        (_count : Nat)
        (_index : Nat)
        (_rev : List PsKernelOpenBinder) =>
        Except.error
          "nested constructor parameter budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedOpenConstructorParamsWithFuel
          remaining;
      fun
        (type : PsKernelExpr)
        (count : Nat)
        (index : Nat)
        (rev : List PsKernelOpenBinder) =>
        match count with
        | Nat.zero =>
            Except.ok
              (PsKernelSimpleNestedOpenParamsResult.mk
                (psKernelReverseOpenBinders rev)
                type)
        | Nat.succ countRest =>
            match type with
            | PsKernelExpr.forallE
                userName
                domain
                body
                binderInfo =>
                let internalName :=
                  PsKernelName.num
                    (psKernelSimpleInternalName
                      "nestedCtorParam")
                    index;
                let binder :=
                  PsKernelOpenBinder.mk
                    internalName
                    userName
                    domain
                    binderInfo;
                smaller
                  (psKernelExprInstantiate1
                    body
                    (PsKernelExpr.fvar
                      internalName))
                  countRest
                  (Nat.succ index)
                  (List.cons
                    binder
                    rev)
            | _ =>
                Except.error
                  "nested preprocessing constructor parameter mismatch"

def psKernelSimpleNestedOpenConstructorParams
    (type : PsKernelExpr)
    (count : Nat) :
    Except String PsKernelSimpleNestedOpenParamsResult :=
  psKernelSimpleNestedOpenConstructorParamsWithFuel
    (Nat.succ count)
    type
    count
    0
    List.nil

inductive PsKernelSimpleNestedBinderKind where
  | forallK
  | lambdaK

structure PsKernelSimpleNestedRestorationParamsResult where
  kind : PsKernelSimpleNestedBinderKind
  params : List PsKernelOpenBinder
  result : PsKernelExpr

def psKernelSimpleNestedOpenRestorationParamsWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    Nat ->
    Option PsKernelSimpleNestedBinderKind ->
    Nat ->
    List PsKernelOpenBinder ->
    Except String PsKernelSimpleNestedRestorationParamsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_expr : PsKernelExpr)
        (_count : Nat)
        (_kind : Option PsKernelSimpleNestedBinderKind)
        (_index : Nat)
        (_rev : List PsKernelOpenBinder) =>
        Except.error
          "nested restoration parameter budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedOpenRestorationParamsWithFuel
          remaining;
      fun
        (expr : PsKernelExpr)
        (count : Nat)
        (kind : Option PsKernelSimpleNestedBinderKind)
        (index : Nat)
        (rev : List PsKernelOpenBinder) =>
        match count with
        | Nat.zero =>
            let finalKind : PsKernelSimpleNestedBinderKind :=
              match kind with
              | Option.some value =>
                  value
              | Option.none =>
                  PsKernelSimpleNestedBinderKind.forallK;
            Except.ok
              (PsKernelSimpleNestedRestorationParamsResult.mk
                finalKind
                (psKernelReverseOpenBinders rev)
                expr)
        | Nat.succ countRest =>
            match expr with
            | PsKernelExpr.forallE
                userName
                domain
                body
                binderInfo =>
                let conflict : Bool :=
                  match kind with
                  | Option.some value =>
                      match value with
                      | PsKernelSimpleNestedBinderKind.lambdaK =>
                          true
                      | PsKernelSimpleNestedBinderKind.forallK =>
                          false
                  | Option.none =>
                      false;
                if conflict then
                  Except.error
                    "restored nested binders mix forall and lambda"
                else
                  let internalName :=
                    PsKernelName.num
                      (psKernelSimpleInternalName
                        "nestedRestoreParam")
                      index;
                  let binder :=
                    PsKernelOpenBinder.mk
                      internalName
                      userName
                      domain
                      binderInfo;
                  smaller
                    (psKernelExprInstantiate1
                      body
                      (PsKernelExpr.fvar
                        internalName))
                    countRest
                    (Option.some
                      PsKernelSimpleNestedBinderKind.forallK)
                    (Nat.succ index)
                    (List.cons binder rev)
            | PsKernelExpr.lam
                userName
                domain
                body
                binderInfo =>
                let conflict : Bool :=
                  match kind with
                  | Option.some value =>
                      match value with
                      | PsKernelSimpleNestedBinderKind.forallK =>
                          true
                      | PsKernelSimpleNestedBinderKind.lambdaK =>
                          false
                  | Option.none =>
                      false;
                if conflict then
                  Except.error
                    "restored nested binders mix forall and lambda"
                else
                  let internalName :=
                    PsKernelName.num
                      (psKernelSimpleInternalName
                        "nestedRestoreParam")
                      index;
                  let binder :=
                    PsKernelOpenBinder.mk
                      internalName
                      userName
                      domain
                      binderInfo;
                  smaller
                    (psKernelExprInstantiate1
                      body
                      (PsKernelExpr.fvar
                        internalName))
                    countRest
                    (Option.some
                      PsKernelSimpleNestedBinderKind.lambdaK)
                    (Nat.succ index)
                    (List.cons binder rev)
            | _ =>
                Except.error
                  "failed to restore nested inductive parameters"

def psKernelSimpleNestedOpenRestorationParams
    (expr : PsKernelExpr)
    (count : Nat) :
    Except String PsKernelSimpleNestedRestorationParamsResult :=
  psKernelSimpleNestedOpenRestorationParamsWithFuel
    (Nat.succ count)
    expr
    count
    Option.none
    0
    List.nil

def psKernelSimpleNestedCloseRestoration
    (kind : PsKernelSimpleNestedBinderKind)
    (params : List PsKernelOpenBinder)
    (body : PsKernelExpr) :
    PsKernelExpr :=
  match kind with
  | PsKernelSimpleNestedBinderKind.forallK =>
      psKernelCloseOpenBinders
        params
        body
  | PsKernelSimpleNestedBinderKind.lambdaK =>
      psKernelCloseOpenLambdas
        params
        body

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


def psKernelSimpleNestedFindAuxByName
    (name : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Option PsKernelSimpleNestedAuxFamily :=
  match families with
  | List.nil =>
      Option.none
  | List.cons family rest =>
      if psKernelNameEq family.auxName name then
        Option.some family
      else
        psKernelSimpleNestedFindAuxByName
          name
          rest

structure PsKernelSimpleNestedCtorLookup where
  family : PsKernelSimpleNestedAuxFamily
  outerCtor : PsKernelName

def psKernelSimpleNestedFindCtorInMap
    (name : PsKernelName)
    (family : PsKernelSimpleNestedAuxFamily)
    (entries : List PsKernelSimpleNestedAuxCtorMap) :
    Option PsKernelSimpleNestedCtorLookup :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if psKernelNameEq entry.auxCtor name then
        Option.some
          (PsKernelSimpleNestedCtorLookup.mk
            family
            entry.outerCtor)
      else
        psKernelSimpleNestedFindCtorInMap
          name
          family
          rest

def psKernelSimpleNestedFindCtorMapWorker
    (families : List PsKernelSimpleNestedAuxFamily) :
    PsKernelName ->
    Option PsKernelSimpleNestedCtorLookup :=
  match families with
  | List.nil =>
      fun
        (_name : PsKernelName) =>
        Option.none
  | List.cons family rest =>
      let smaller :
          PsKernelName ->
          Option PsKernelSimpleNestedCtorLookup :=
        psKernelSimpleNestedFindCtorMapWorker
          rest;
      fun
        (name : PsKernelName) =>
        match
            psKernelSimpleNestedFindCtorInMap
              name
              family
              family.ctorMap with
        | Option.some found =>
            Option.some found
        | Option.none =>
            smaller name

def psKernelSimpleNestedFindCtorMap
    (name : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Option PsKernelSimpleNestedCtorLookup :=
  psKernelSimpleNestedFindCtorMapWorker
    families
    name

def psKernelSimpleNestedFindRename
    (name : PsKernelName)
    (renames : List (Prod PsKernelName PsKernelName)) :
    Option PsKernelName :=
  match renames with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if
          psKernelNameEq
            name
            (Prod.fst entry) then
        Option.some
          (Prod.snd entry)
      else
        psKernelSimpleNestedFindRename
          name
          rest

def psKernelSimpleNestedMapExprList
    (transform : PsKernelExpr -> PsKernelExpr)
    (values : List PsKernelExpr) :
    List PsKernelExpr :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (transform head)
        (psKernelSimpleNestedMapExprList
          transform
          tail)

def psKernelSimpleNestedRestoreOpenWithFuel
    (fuel : Nat) :
    List PsKernelSimpleNestedAuxFamily ->
    List (Prod PsKernelName PsKernelName) ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_renames : List (Prod PsKernelName PsKernelName))
        (_canonicalParams : List PsKernelOpenBinder)
        (_currentParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (expr : PsKernelExpr) =>
        expr
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedRestoreOpenWithFuel
          remaining;
      fun
        (families : List PsKernelSimpleNestedAuxFamily)
        (renames : List (Prod PsKernelName PsKernelName))
        (canonicalParams : List PsKernelOpenBinder)
        (currentParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (expr : PsKernelExpr) =>
        match expr with
        | PsKernelExpr.app _ _ =>
            let fn : PsKernelExpr :=
              psKernelExprGetAppFn expr;
            let restoreOne : PsKernelExpr -> PsKernelExpr :=
              fun (arg : PsKernelExpr) =>
                smaller
                  families
                  renames
                  canonicalParams
                  currentParams
                  numParams
                  arg;
            let args : List PsKernelExpr :=
              psKernelSimpleNestedMapExprList
                restoreOne
                (psKernelExprGetAppArgs expr);
            match fn with
            | PsKernelExpr.const name levels =>
                match
                    psKernelSimpleNestedFindRename
                      name
                      renames with
                | Option.some renamed =>
                    psKernelApplyArgs
                      (PsKernelExpr.const
                        renamed
                        levels)
                      args
                | Option.none =>
                    match
                        psKernelSimpleNestedFindAuxByName
                          name
                          families with
                    | Option.some family =>
                        let nested : PsKernelExpr :=
                          psKernelSimpleNestedRebaseParams
                            family.nestedTemplate
                            canonicalParams
                            currentParams;
                        if
                            psKernelNatLt
                              (psKernelExprListLength args)
                              numParams then
                          psKernelApplyArgs
                            (PsKernelExpr.const
                              name
                              levels)
                            args
                        else
                          psKernelApplyArgs
                            nested
                            (psKernelExprListDrop
                              numParams
                              args)
                    | Option.none =>
                        match
                            psKernelSimpleNestedFindCtorMap
                              name
                              families with
                        | Option.some found =>
                            if
                                psKernelNatLt
                                  (psKernelExprListLength args)
                                  numParams then
                              psKernelApplyArgs
                                (PsKernelExpr.const
                                  name
                                  levels)
                                args
                            else
                              let fixed : List PsKernelExpr :=
                                psKernelSimpleNestedRebaseExprList
                                  found.family.fixedParams
                                  canonicalParams
                                  currentParams;
                              psKernelApplyArgs
                                (PsKernelExpr.const
                                  found.outerCtor
                                  found.family.outerLevels)
                                (psKernelExprListAppend
                                  fixed
                                  (psKernelExprListDrop
                                    numParams
                                    args))
                        | Option.none =>
                            let fnRestored : PsKernelExpr :=
                              smaller
                                families
                                renames
                                canonicalParams
                                currentParams
                                numParams
                                fn;
                            psKernelApplyArgs
                              fnRestored
                              args
            | _ =>
                let fnRestored : PsKernelExpr :=
                  smaller
                    families
                    renames
                    canonicalParams
                    currentParams
                    numParams
                    fn;
                psKernelApplyArgs
                  fnRestored
                  args
        | PsKernelExpr.lam
            name
            type
            body
            binderInfo =>
            PsKernelExpr.lam
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              binderInfo
        | PsKernelExpr.forallE
            name
            type
            body
            binderInfo =>
            PsKernelExpr.forallE
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              binderInfo
        | PsKernelExpr.letE
            name
            type
            value
            body
            nondep =>
            PsKernelExpr.letE
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                value)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              nondep
        | PsKernelExpr.mdata metadata body =>
            PsKernelExpr.mdata
              metadata
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
        | PsKernelExpr.proj typeName index body =>
            let restoredTypeName : PsKernelName :=
              match
                  psKernelSimpleNestedFindAuxByName
                    typeName
                    families with
              | Option.some family =>
                  family.outerName
              | Option.none =>
                  typeName;
            PsKernelExpr.proj
              restoredTypeName
              index
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
        | PsKernelExpr.const name levels =>
            match
                psKernelSimpleNestedFindRename
                  name
                  renames with
            | Option.some renamed =>
                PsKernelExpr.const
                  renamed
                  levels
            | Option.none =>
                match
                    psKernelSimpleNestedFindAuxByName
                      name
                      families with
                | Option.some family =>
                    if Nat.beq numParams 0 then
                      psKernelSimpleNestedRebaseParams
                        family.nestedTemplate
                        canonicalParams
                        currentParams
                    else
                      expr
                | Option.none =>
                    match
                        psKernelSimpleNestedFindCtorMap
                          name
                          families with
                    | Option.some found =>
                        if Nat.beq numParams 0 then
                          let fixed : List PsKernelExpr :=
                            psKernelSimpleNestedRebaseExprList
                              found.family.fixedParams
                              canonicalParams
                              currentParams;
                          psKernelApplyArgs
                            (PsKernelExpr.const
                              found.outerCtor
                              found.family.outerLevels)
                            fixed
                        else
                          expr
                    | Option.none =>
                        expr
        | _ =>
            expr

def psKernelSimpleNestedRestoreOpen
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (currentParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (expr : PsKernelExpr) :
    PsKernelExpr :=
  psKernelSimpleNestedRestoreOpenWithFuel
    (Nat.succ
      (psKernelExprNodeCount expr))
    families
    renames
    canonicalParams
    currentParams
    numParams
    expr

def psKernelSimpleNestedRestoreExpr
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (expr : PsKernelExpr) :
    Except String PsKernelExpr :=
  if Nat.beq numParams 0 then
    Except.ok
      (psKernelSimpleNestedRestoreOpen
        families
        renames
        canonicalParams
        List.nil
        0
        expr)
  else
    match
        psKernelSimpleNestedOpenRestorationParams
          expr
          numParams with
    | Except.error error =>
        Except.error error
    | Except.ok opened =>
        let restored :=
          psKernelSimpleNestedRestoreOpen
            families
            renames
            canonicalParams
            opened.params
            numParams
            opened.result;
        Except.ok
          (psKernelSimpleNestedCloseRestoration
            opened.kind
            opened.params
            restored)

def psKernelSimpleNestedRestoreRule
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (mapCtor : Bool)
    (rule : PsKernelRecursorRule) :
    Except String PsKernelRecursorRule :=
  let ctor : PsKernelName :=
    if mapCtor then
      match
          psKernelSimpleNestedFindCtorMap
            rule.ctor
            families with
      | Option.some found =>
          found.outerCtor
      | Option.none =>
          rule.ctor
    else
      rule.ctor;
  match
      psKernelSimpleNestedRestoreExpr
        families
        renames
        canonicalParams
        numParams
        rule.rhs with
  | Except.error error =>
      Except.error error
  | Except.ok rhs =>
      Except.ok
        (PsKernelRecursorRule.mk
          ctor
          rule.nFields
          rhs)

def psKernelSimpleNestedRestoreRules
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (mapCtor : Bool)
    (rules : List PsKernelRecursorRule) :
    Except String (List PsKernelRecursorRule) :=
  match rules with
  | List.nil =>
      Except.ok List.nil
  | List.cons rule rest =>
      match
          psKernelSimpleNestedRestoreRule
            families
            renames
            canonicalParams
            numParams
            mapCtor
            rule with
      | Except.error error =>
          Except.error error
      | Except.ok restored =>
          match
              psKernelSimpleNestedRestoreRules
                families
                renames
                canonicalParams
                numParams
                mapCtor
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok tail =>
              Except.ok
                (List.cons
                  restored
                  tail)

def psKernelSimpleNestedRestoreRecursor
    (originalNames : List PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (newName : PsKernelName)
    (mapCtor : Bool)
    (info : PsKernelRecursorInfo) :
    Except String PsKernelRecursorInfo :=
  match
      psKernelSimpleNestedRestoreExpr
        families
        renames
        canonicalParams
        numParams
        info.base.type with
  | Except.error error =>
      Except.error error
  | Except.ok restoredType =>
      match
          psKernelSimpleNestedRestoreRules
            families
            renames
            canonicalParams
            numParams
            mapCtor
            info.rules with
      | Except.error error =>
          Except.error error
      | Except.ok restoredRules =>
          Except.ok
            (PsKernelRecursorInfo.mk
              (PsKernelConstantBase.mk
                newName
                info.base.levelParams
                restoredType)
              originalNames
              info.numParams
              info.numIndices
              info.numMotives
              info.numMinors
              restoredRules
              info.k
              info.isUnsafe)
