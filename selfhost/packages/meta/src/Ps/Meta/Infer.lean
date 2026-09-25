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
    (expr : PsExpr)
    (args : List PsExpr) : PsInferAppView :=
  match expr with
  | .app fn arg =>
      psInferAppViewAcc fn (arg :: args)
  | head =>
      {
        head := head
        args := args
      }

def psInferAppView (expr : PsExpr) : PsInferAppView :=
  psInferAppViewAcc expr []

def psInferApplyStructureParameters
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (cursor : PsExpr)
    (arguments : List PsExpr) :
    Except PsInferError PsExpr :=
  match arguments with
  | [] =>
      Except.ok cursor
  | argument :: rest =>
      match
          psWhnf
            environment
            metaContext
            localContext
            cursor with
      | .forallE _ _ body _ =>
          psInferApplyStructureParameters
            environment
            metaContext
            localContext
            (psExprInstantiate1 body argument)
            rest
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
  match remainingFuel with
  | 0 =>
      Except.error PsInferError.fuelExhausted
  | fuel + 1 =>
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
            psInferStructureProjectionField
              environment
              metaContext
              localContext
              typeName
              target
              fuel
              requestedIndex
              (Nat.succ fieldIndex)
              (psExprInstantiate1
                body
                (PsExpr.proj typeName fieldIndex target))
      | _ =>
          Except.error PsInferError.projectionUnsupported

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
        targetType)
  match view.head with
  | .constE actualName _ =>
      if !psNameEq actualName typeName then
        Except.error PsInferError.projectionUnsupported
      else
        match psEnvironmentFindInductive environment typeName with
        | none => Except.error PsInferError.projectionUnsupported
        | some info =>
            if
                !info.isStructure
                  || info.numIndices != 0
                  || view.args.length != info.numParams then
              Except.error PsInferError.projectionUnsupported
            else
              match info.constructors with
              | [constructorName] =>
                  match
                      psEnvironmentFindConstructor
                        environment
                        constructorName with
                  | none =>
                      Except.error PsInferError.projectionUnsupported
                  | some constructorInfo =>
                      if
                          constructorInfo.numParams != info.numParams
                            || index >= constructorInfo.numFields then
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
              | _ => Except.error PsInferError.projectionUnsupported
  | _ => Except.error PsInferError.projectionUnsupported

def psInferTypeWithFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : Nat -> PsExpr -> Except PsInferError PsExpr
  | 0, _ => Except.error PsInferError.fuelExhausted
  | fuel + 1, expr =>
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
              let parameters := psDeclarationLevelParams declaration
              if parameters.length == levels.length then
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
          match psInferTypeWithFuel environment metaContext localContext fuel fn with
          | Except.error error => Except.error error
          | Except.ok fnType =>
              match psInferEnsureForall environment metaContext localContext fnType with
              | Except.error error => Except.error error
              | Except.ok forallView =>
                  match psInferTypeWithFuel environment metaContext localContext fuel arg with
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
          match psInferTypeWithFuel environment metaContext localContext fuel type with
          | Except.error error => Except.error error
          | Except.ok typeType =>
              match psInferEnsureSort environment metaContext localContext typeType with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  let pushed := psLocalPushBinding localContext name type binder
                  let openedBody := psExprInstantiate1 body (PsExpr.fvar pushed.id)
                  match psInferTypeWithFuel
                      environment
                      metaContext
                      pushed.context
                      fuel
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
          match psInferTypeWithFuel environment metaContext localContext fuel type with
          | Except.error error => Except.error error
          | Except.ok typeType =>
              match psInferEnsureSort environment metaContext localContext typeType with
              | Except.error error => Except.error error
              | Except.ok domainLevel =>
                  let pushed := psLocalPushBinding localContext name type binder
                  let openedBody := psExprInstantiate1 body (PsExpr.fvar pushed.id)
                  match psInferTypeWithFuel
                      environment
                      metaContext
                      pushed.context
                      fuel
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
          match psInferTypeWithFuel environment metaContext localContext fuel type with
          | Except.error error => Except.error error
          | Except.ok typeType =>
              match psInferEnsureSort environment metaContext localContext typeType with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  match psInferTypeWithFuel environment metaContext localContext fuel value with
                  | Except.error error => Except.error error
                  | Except.ok valueType =>
                      if psDefEqReadOnlyWithEnv
                          environment
                          metaContext
                          localContext
                          type
                          valueType then
                        psInferTypeWithFuel
                          environment
                          metaContext
                          localContext
                          fuel
                          (psExprInstantiate1 body value)
                      else
                        Except.error PsInferError.letTypeMismatch
      | .proj typeName index target =>
          match
              psInferTypeWithFuel
                environment
                metaContext
                localContext
                fuel
                target with
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
