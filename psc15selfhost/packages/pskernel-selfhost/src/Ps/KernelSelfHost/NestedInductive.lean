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

def psKernelSimpleNestedAuxNameTaken
    (environment : PsKernelEnvironment)
    (families : List PsKernelSimpleNestedAuxFamily)
    (name : PsKernelName) : Bool :=
  if psKernelEnvironmentContains environment name then
    true
  else
    match families with
    | List.nil =>
        false
    | List.cons family rest =>
        if psKernelNameEq family.auxName name then
          true
        else
          psKernelSimpleNestedAuxNameTaken
            environment
            rest
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
