import Ps.Core.Abstract
import Ps.Core.Builtin
import Ps.Core.LevelSubst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce

inductive PsInferError where
  | fuelExhausted
  | looseBoundVariable (index : Nat)
  | unknownFreeVariable (id : Nat)
  | unknownMetavariable (id : Nat)
  | unknownConstant (name : PsName)
  | incorrectUniverseArity (name : PsName)
  | expectedSort
  | expectedFunction
  | applicationTypeMismatch
  | letTypeMismatch
  | projectionUnsupported

structure PsForallView where
  name : PsName
  domain : PsExpr
  body : PsExpr
  binder : PsBinderInfo

def psInferBoolNot (value : Bool) : Bool :=
  if value then false else true

def psInferBoolOr (left right : Bool) : Bool :=
  if left then true else right

def psInferNatNe (left right : Nat) : Bool :=
  if Nat.beq left right then false else true

def psInferExprListLength
    (values : List PsExpr) : Nat :=
  match values with
  | [] => 0
  | _ :: rest =>
      Nat.succ (psInferExprListLength rest)

def psInferNameListLength
    (values : List PsName) : Nat :=
  match values with
  | [] => 0
  | _ :: rest =>
      Nat.succ (psInferNameListLength rest)

def psInferLevelListLength
    (values : List PsLevel) : Nat :=
  match values with
  | [] => 0
  | _ :: rest =>
      Nat.succ (psInferLevelListLength rest)

def psInferEnsureSort
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : Except PsInferError PsLevel :=
  match psWhnf environment metaContext localContext expr with
  | .sortE level => Except.ok level
  | _ => Except.error PsInferError.expectedSort

def psInferEnsureForall
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : Except PsInferError PsForallView :=
  match psWhnf environment metaContext localContext expr with
  | .forallE name domain body binder =>
      Except.ok {
        name := name
        domain := domain
        body := body
        binder := binder
      }
  | _ => Except.error PsInferError.expectedFunction

structure PsInferAppView where
  head : PsExpr
  args : List PsExpr

def psInferAppViewAcc
    (expr : PsExpr) : List PsExpr -> PsInferAppView :=
  match expr with
  | .app fn arg =>
      let smaller : List PsExpr -> PsInferAppView :=
        psInferAppViewAcc fn;
      fun (args : List PsExpr) =>
        smaller (List.cons arg args)
  | _ =>
      fun (args : List PsExpr) =>
        PsInferAppView.mk expr args

def psInferAppView (expr : PsExpr) : PsInferAppView :=
  psInferAppViewAcc expr []

def psInferApplyStructureParametersWorker
    (arguments : List PsExpr) :
    PsEnvironment ->
    PsMetaContext ->
    PsLocalContext ->
    PsExpr ->
    Except PsInferError PsExpr :=
  match arguments with
  | [] =>
      fun (_environment : PsEnvironment) =>
        fun (_metaContext : PsMetaContext) =>
          fun (_localContext : PsLocalContext) =>
            fun (cursor : PsExpr) =>
              Except.ok cursor
  | argument :: rest =>
      let smaller :
          PsEnvironment ->
          PsMetaContext ->
          PsLocalContext ->
          PsExpr ->
          Except PsInferError PsExpr :=
        psInferApplyStructureParametersWorker rest;
      fun (environment : PsEnvironment) =>
        fun (metaContext : PsMetaContext) =>
          fun (localContext : PsLocalContext) =>
            fun (cursor : PsExpr) =>
              match
                  psWhnf
                    environment
                    metaContext
                    localContext
                    cursor with
              | .forallE _ _ body _ =>
                  smaller
                    environment
                    metaContext
                    localContext
                    (psExprInstantiate1 body argument)
              | _ =>
                  Except.error PsInferError.projectionUnsupported

def psInferApplyStructureParameters
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (cursor : PsExpr)
    (arguments : List PsExpr) :
    Except PsInferError PsExpr :=
  psInferApplyStructureParametersWorker
    arguments
    environment
    metaContext
    localContext
    cursor

def psInferStructureProjectionFieldWorker
    (remainingFuel : Nat) :
    PsEnvironment ->
    PsMetaContext ->
    PsLocalContext ->
    PsName ->
    PsExpr ->
    Nat ->
    Nat ->
    PsExpr ->
    Except PsInferError PsExpr :=
  match remainingFuel with
  | Nat.zero =>
      fun (_environment : PsEnvironment) =>
        fun (_metaContext : PsMetaContext) =>
          fun (_localContext : PsLocalContext) =>
            fun (_typeName : PsName) =>
              fun (_target : PsExpr) =>
                fun (_requestedIndex : Nat) =>
                  fun (_fieldIndex : Nat) =>
                    fun (_cursor : PsExpr) =>
                      Except.error PsInferError.fuelExhausted
  | Nat.succ fuel =>
      fun (environment : PsEnvironment) =>
        fun (metaContext : PsMetaContext) =>
          fun (localContext : PsLocalContext) =>
            fun (typeName : PsName) =>
              fun (target : PsExpr) =>
                fun (requestedIndex : Nat) =>
                  fun (fieldIndex : Nat) =>
                    fun (cursor : PsExpr) =>
                      let smaller :
                          PsEnvironment ->
                          PsMetaContext ->
                          PsLocalContext ->
                          PsName ->
                          PsExpr ->
                          Nat ->
                          Nat ->
                          PsExpr ->
                          Except PsInferError PsExpr :=
                        psInferStructureProjectionFieldWorker fuel;
                      match
                          psWhnf
                            environment
                            metaContext
                            localContext
                            cursor with
                      | .forallE _ domain body _ =>
                          if Nat.beq requestedIndex fieldIndex then
                            Except.ok domain
                          else
                            smaller
                              environment
                              metaContext
                              localContext
                              typeName
                              target
                              requestedIndex
                              (Nat.succ fieldIndex)
                              (psExprInstantiate1
                                body
                                (PsExpr.proj typeName fieldIndex target))
                      | _ =>
                          Except.error PsInferError.projectionUnsupported

def psInferStructureProjectionField
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (typeName : PsName)
    (target : PsExpr)
    (remainingFuel : Nat)
    (requestedIndex : Nat)
    (fieldIndex : Nat)
    (cursor : PsExpr) :
    Except PsInferError PsExpr :=
  psInferStructureProjectionFieldWorker
    remainingFuel
    environment
    metaContext
    localContext
    typeName
    target
    requestedIndex
    fieldIndex
    cursor

def psInferProjectionType
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (targetType : PsExpr)
    (typeName : PsName)
    (index : Nat)
    (target : PsExpr) :
    Except PsInferError PsExpr :=
  let view :=
    psInferAppView
      (psWhnf
        environment
        metaContext
        localContext
        targetType);
  match view.head with
  | .constE actualName _ =>
      if psInferBoolNot (psNameEq actualName typeName) then
        Except.error PsInferError.projectionUnsupported
      else
        match psEnvironmentFindInductive environment typeName with
        | none => Except.error PsInferError.projectionUnsupported
        | some info =>
            if
                psInferBoolOr
                  (psInferBoolNot info.isStructure)
                  (psInferBoolOr
                    (psInferNatNe info.numIndices 0)
                    (psInferNatNe (psInferExprListLength view.args) info.numParams)) then
              Except.error PsInferError.projectionUnsupported
            else
              match info.constructors with
              | List.nil =>
                  Except.error PsInferError.projectionUnsupported
              | List.cons constructorName remainingConstructors =>
                  match remainingConstructors with
                  | List.nil =>
                      match
                          psEnvironmentFindConstructor
                            environment
                            constructorName with
                      | none =>
                          Except.error PsInferError.projectionUnsupported
                      | some constructorInfo =>
                          if
                              psInferBoolOr
                                (psInferNatNe constructorInfo.numParams info.numParams)
                                (Nat.ble constructorInfo.numFields index) then
                            Except.error PsInferError.projectionUnsupported
                          else
                            match
                                psInferApplyStructureParameters
                                  environment
                                  metaContext
                                  localContext
                                  constructorInfo.type
                                  view.args with
                            | Except.error error => Except.error error
                            | Except.ok fieldCursor =>
                                psInferStructureProjectionField
                                  environment
                                  metaContext
                                  localContext
                                  typeName
                                  target
                                  4096
                                  index
                                  0
                                  fieldCursor
                  | List.cons _ _ =>
                      Except.error PsInferError.projectionUnsupported
  | _ => Except.error PsInferError.projectionUnsupported

def psInferTypeWithFuelWorker
    (remainingFuel : Nat) :
    PsEnvironment ->
    PsMetaContext ->
    PsLocalContext ->
    PsExpr ->
    Except PsInferError PsExpr :=
  match remainingFuel with
  | Nat.zero =>
      fun (_environment : PsEnvironment) =>
        fun (_metaContext : PsMetaContext) =>
          fun (_localContext : PsLocalContext) =>
            fun (_expr : PsExpr) =>
              Except.error PsInferError.fuelExhausted
  | Nat.succ fuel =>
      fun (environment : PsEnvironment) =>
        fun (metaContext : PsMetaContext) =>
          fun (localContext : PsLocalContext) =>
            fun (expr : PsExpr) =>
              let smaller :
                  PsEnvironment ->
                  PsMetaContext ->
                  PsLocalContext ->
                  PsExpr ->
                  Except PsInferError PsExpr :=
                psInferTypeWithFuelWorker fuel;
              match expr with
              | .bvar index =>
                  Except.error (PsInferError.looseBoundVariable index)
              | .fvar id =>
                  match psLocalFindById localContext id with
                  | none => Except.error (PsInferError.unknownFreeVariable id)
                  | some declaration =>
                      Except.ok (psMetaInstantiate metaContext (psLocalDeclType declaration))
              | .mvar id =>
                  match psMetaFindDecl metaContext id with
                  | none => Except.error (PsInferError.unknownMetavariable id)
                  | some declaration =>
                      Except.ok (psMetaInstantiate metaContext declaration.type)
              | .sortE level =>
                  Except.ok (PsExpr.sortE (PsLevel.succ level))
              | .constE name levels =>
                  match psEnvironmentFind environment name with
                  | none => Except.error (PsInferError.unknownConstant name)
                  | some declaration =>
                      let parameters := psDeclarationLevelParams declaration;
                      if
                          Nat.beq
                            (psInferNameListLength parameters)
                            (psInferLevelListLength levels) then
                        Except.ok
                          (psExprInstantiateLevelParams
                            parameters
                            levels
                            (psDeclarationType declaration))
                      else
                        Except.error (PsInferError.incorrectUniverseArity name)
              | .lit literal =>
                  match literal with
                  | .natural _ => Except.ok (PsExpr.constE psNatName [])
                  | .string _ => Except.ok (PsExpr.constE psStringName [])
              | .app fn arg =>
                  match smaller environment metaContext localContext fn with
                  | Except.error error => Except.error error
                  | Except.ok fnType =>
                      match psInferEnsureForall environment metaContext localContext fnType with
                      | Except.error error => Except.error error
                      | Except.ok forallView =>
                          match smaller environment metaContext localContext arg with
                          | Except.error error => Except.error error
                          | Except.ok argType =>
                              if psDefEqReadOnlyWithEnv
                                  environment
                                  metaContext
                                  localContext
                                  forallView.domain
                                  argType then
                                Except.ok (psExprInstantiate1 forallView.body arg)
                              else
                                Except.error PsInferError.applicationTypeMismatch
              | .lam name type body binder =>
                  match smaller environment metaContext localContext type with
                  | Except.error error => Except.error error
                  | Except.ok typeType =>
                      match psInferEnsureSort environment metaContext localContext typeType with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          let pushed := psLocalPushBinding localContext name type binder;
                          let openedBody := psExprInstantiate1 body (PsExpr.fvar pushed.id);
                          match
                              smaller
                                environment
                                metaContext
                                pushed.context
                                openedBody with
                          | Except.error error => Except.error error
                          | Except.ok bodyType =>
                              Except.ok
                                (PsExpr.forallE
                                  name
                                  type
                                  (psExprAbstractFVar pushed.id bodyType)
                                  binder)
              | .forallE name type body binder =>
                  match smaller environment metaContext localContext type with
                  | Except.error error => Except.error error
                  | Except.ok typeType =>
                      match psInferEnsureSort environment metaContext localContext typeType with
                      | Except.error error => Except.error error
                      | Except.ok domainLevel =>
                          let pushed := psLocalPushBinding localContext name type binder;
                          let openedBody := psExprInstantiate1 body (PsExpr.fvar pushed.id);
                          match
                              smaller
                                environment
                                metaContext
                                pushed.context
                                openedBody with
                          | Except.error error => Except.error error
                          | Except.ok bodyType =>
                              match psInferEnsureSort
                                  environment
                                  metaContext
                                  pushed.context
                                  bodyType with
                              | Except.error error => Except.error error
                              | Except.ok bodyLevel =>
                                  Except.ok
                                    (PsExpr.sortE (PsLevel.imax domainLevel bodyLevel))
              | .letE _ type value body =>
                  match smaller environment metaContext localContext type with
                  | Except.error error => Except.error error
                  | Except.ok typeType =>
                      match psInferEnsureSort environment metaContext localContext typeType with
                      | Except.error error => Except.error error
                      | Except.ok _ =>
                          match smaller environment metaContext localContext value with
                          | Except.error error => Except.error error
                          | Except.ok valueType =>
                              if psDefEqReadOnlyWithEnv
                                  environment
                                  metaContext
                                  localContext
                                  type
                                  valueType then
                                smaller
                                  environment
                                  metaContext
                                  localContext
                                  (psExprInstantiate1 body value)
                              else
                                Except.error PsInferError.letTypeMismatch
              | .proj typeName index target =>
                  match smaller environment metaContext localContext target with
                  | Except.error error => Except.error error
                  | Except.ok targetType =>
                      psInferProjectionType
                        environment
                        metaContext
                        localContext
                        targetType
                        typeName
                        index
                        target

def psInferTypeWithFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (fuel : Nat)
    (expr : PsExpr) : Except PsInferError PsExpr :=
  psInferTypeWithFuelWorker
    fuel
    environment
    metaContext
    localContext
    expr

def psInferDefaultFuel : Nat :=
  4096

def psInferType
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : Except PsInferError PsExpr :=
  psInferTypeWithFuel
    environment
    metaContext
    localContext
    psInferDefaultFuel
    expr
