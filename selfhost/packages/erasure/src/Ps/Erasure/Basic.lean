import Ps.CompilerIr.Model
import Ps.Core.Builtin
import Ps.Core.Subst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Infer
import Ps.Meta.Reduce

inductive PsErasedBinderKind where
  | type
  | proof
  | runtime

inductive PsErasureError where
  | fuelExhausted
  | binderMismatch
  | looseBoundVariable
  | unresolvedMetavariable
  | unknownLocal (id : Nat)
  | erasedLocalUsed (id : Nat)
  | unsupportedRuntimeTerm
  | unsupportedApplication
  | unknownConstant (name : PsName)

structure PsRuntimeConstructorField where
  sourceIndex : Nat
  name : String
  type : PsVerifiedIrType

structure PsRuntimeConstructorInfo where
  inductiveName : String
  name : String
  coreName : PsName
  numParams : Nat
  fields : List PsRuntimeConstructorField

structure PsRuntimeInductiveInfo where
  name : String
  coreName : PsName
  recursorName : PsName
  numParams : Nat
  typeParameters : List PsVerifiedIrTypeParameter
  constructors : List PsRuntimeConstructorInfo

structure PsErasureScope where
  localContext : PsLocalContext
  runtimeLocals : List (Nat × String)
  typeLocals : List (Nat × String)
  erasedLocals : List Nat
  declarationNames : List (PsName × String)
  runtimeConstructors : List (PsName × PsRuntimeConstructorInfo)
  runtimeRecursors : List (PsName × PsRuntimeInductiveInfo)

def psErasureScopeEmpty
    (declarationNames : List (PsName × String)) :
    PsErasureScope :=
  {
    localContext := psLocalEmpty
    runtimeLocals := []
    typeLocals := []
    erasedLocals := []
    declarationNames := declarationNames
    runtimeConstructors := []
    runtimeRecursors := []
  }

def psErasureLookupNat :
    List (Nat × String) -> Nat -> Option String
  | [], _ => none
  | entry :: rest, id =>
      if entry.1 == id then some entry.2
      else psErasureLookupNat rest id

def psErasureLookupName :
    List (PsName × String) -> PsName -> Option String
  | [], _ => none
  | entry :: rest, name =>
      if psNameEq entry.1 name then some entry.2
      else psErasureLookupName rest name

def psErasureLookupConstructor :
    List (PsName × PsRuntimeConstructorInfo) ->
    PsName ->
    Option PsRuntimeConstructorInfo
  | [], _ => none
  | entry :: rest, name =>
      if psNameEq entry.1 name then some entry.2
      else psErasureLookupConstructor rest name

def psErasureLookupRecursor :
    List (PsName × PsRuntimeInductiveInfo) ->
    PsName ->
    Option PsRuntimeInductiveInfo
  | [], _ => none
  | entry :: rest, name =>
      if psNameEq entry.1 name then some entry.2
      else psErasureLookupRecursor rest name

def psErasureNatInList : List Nat -> Nat -> Bool
  | [], _ => false
  | value :: rest, target =>
      value == target || psErasureNatInList rest target

def psLevelNormalizesToZero : PsLevel -> Bool
  | .zero => true
  | .succ _ => false
  | .max left right =>
      psLevelNormalizesToZero left
        && psLevelNormalizesToZero right
  | .imax _ right =>
      psLevelNormalizesToZero right
  | .param _ => false
  | .mvar _ => false

def psErasureIsProp
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (expr : PsExpr) : Bool :=
  match
      psInferType
        environment
        psMetaEmpty
        localContext
        expr with
  | Except.error _ => false
  | Except.ok inferred =>
      match
          psWhnf
            environment
            psMetaEmpty
            localContext
            inferred with
      | .sortE level =>
          psLevelNormalizesToZero level
      | _ => false

def psErasureClassifyBinder
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (type : PsExpr) : PsErasedBinderKind :=
  match
      psWhnf
        environment
        psMetaEmpty
        localContext
        type with
  | .sortE level =>
      if psLevelNormalizesToZero level then
        PsErasedBinderKind.proof
      else
        PsErasedBinderKind.type
  | _ =>
      if psErasureIsProp environment localContext type then
        PsErasedBinderKind.proof
      else
        PsErasedBinderKind.runtime

def psErasureSafeChar (char : Char) : Char :=
  if char.isAlphanum || char == '_' || char == '$' then
    char
  else
    '_'

def psErasureSafeChars : List Char -> List Char
  | [] => []
  | char :: rest =>
      psErasureSafeChar char :: psErasureSafeChars rest

def psErasureSafeIdentifier
    (raw : String)
    (fallback : String) : String :=
  let mapped := String.ofList (psErasureSafeChars raw.toList)
  let base := if mapped.isEmpty then fallback else mapped
  match base.toList with
  | [] => fallback
  | first :: _ =>
      if first.isAlpha || first == '_' || first == '$' then
        base
      else
        "_" ++ base

structure PsErasureAppView where
  head : PsExpr
  args : List PsExpr

def psErasureAppViewAcc :
    PsExpr -> List PsExpr -> PsErasureAppView
  | .app fn arg, args =>
      psErasureAppViewAcc fn (arg :: args)
  | head, args =>
      { head := head, args := args }

def psErasureAppView (expr : PsExpr) : PsErasureAppView :=
  psErasureAppViewAcc expr []

def psErasurePrimitiveType
    (name : PsName) : Option PsVerifiedIrType :=
  if psNameEq name psNatName then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.nat)
  else if psNameToString name == "Int" then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int)
  else if psNameEq name psBoolName then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.bool)
  else if psNameEq name psCharName then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.char)
  else if psNameEq name psStringName then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.string)
  else if psNameEq name psUnitName then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.unit)
  else if psNameToString name == "String.Pos.Raw" then
    some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.nat)
  else
    none

def psEraseRuntimeTypeWithFuel
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    Nat -> PsExpr -> Except PsErasureError PsVerifiedIrType
  | 0, _ => Except.error PsErasureError.fuelExhausted
  | fuel + 1, type =>
      let value :=
        psWhnf
          environment
          psMetaEmpty
          scope.localContext
          type
      match value with
      | .fvar id =>
          match psErasureLookupNat scope.typeLocals id with
          | some name =>
              Except.ok (PsVerifiedIrType.typeParameter name)
          | none =>
              Except.ok PsVerifiedIrType.unknown
      | .constE name _ =>
          match psErasurePrimitiveType name with
          | some primitive => Except.ok primitive
          | none =>
              let outputName :=
                match psErasureLookupName
                    scope.declarationNames
                    name with
                | some known => known
                | none =>
                    psErasureSafeIdentifier
                      (psNameToString name)
                      "Type"
              Except.ok
                (PsVerifiedIrType.named outputName [])
      | .app _ _ =>
          let view := psErasureAppView value
          match view.head with
          | .constE name _ =>
              let outputName :=
                match psErasureLookupName
                    scope.declarationNames
                    name with
                | some known => known
                | none =>
                    psErasureSafeIdentifier
                      (psNameToString name)
                      "Type"
              match view.args.mapM
                  (psEraseRuntimeTypeWithFuel
                    environment
                    scope
                    fuel) with
              | Except.error error => Except.error error
              | Except.ok arguments =>
                  Except.ok
                    (PsVerifiedIrType.named
                      outputName
                      arguments)
          | _ => Except.ok PsVerifiedIrType.unknown
      | .forallE name domain body binder =>
          match
              psErasureClassifyBinder
                environment
                scope.localContext
                domain with
          | .runtime =>
              let pushed :=
                psLocalPushBinding
                  scope.localContext
                  name
                  domain
                  binder
              let runtimeName :=
                psErasureSafeIdentifier
                  (psNameToString name)
                  "_arg"
              let nextScope : PsErasureScope := {
                localContext := pushed.context
                runtimeLocals :=
                  (pushed.id, runtimeName) ::
                    scope.runtimeLocals
                typeLocals := scope.typeLocals
                erasedLocals := scope.erasedLocals
                declarationNames := scope.declarationNames
                runtimeConstructors := scope.runtimeConstructors
                runtimeRecursors := scope.runtimeRecursors
              }
              match
                  psEraseRuntimeTypeWithFuel
                    environment
                    scope
                    fuel
                    domain with
              | Except.error error => Except.error error
              | Except.ok parameter =>
                  match
                      psEraseRuntimeTypeWithFuel
                        environment
                        nextScope
                        fuel
                        (psExprInstantiate1
                          body
                          (PsExpr.fvar pushed.id)) with
                  | Except.error error => Except.error error
                  | Except.ok result =>
                      match result with
                      | .function parameters finalResult =>
                          Except.ok
                            (PsVerifiedIrType.function
                              (parameter :: parameters)
                              finalResult)
                      | _ =>
                          Except.ok
                            (PsVerifiedIrType.function
                              [parameter]
                              result)
          | _ =>
              Except.ok PsVerifiedIrType.unknown
      | _ =>
          Except.ok PsVerifiedIrType.unknown

def psEraseRuntimeType
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (type : PsExpr) :
    Except PsErasureError PsVerifiedIrType :=
  psEraseRuntimeTypeWithFuel environment scope 4096 type
