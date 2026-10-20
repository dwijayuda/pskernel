import Ps.Erasure.Expr
import Ps.Erasure.Inductive
import Ps.Erasure.StructureRecursor

structure PsOpenedErasedDefinition where
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  resultType : PsVerifiedIrType
  body : PsVerifiedIrExpr

def psErasureStringInList (values : List String) : String -> Bool :=
  match values with
  | List.nil => fun (_target : String) => false
  | List.cons value rest =>
      let smaller : String -> Bool := psErasureStringInList rest;
      fun (target : String) =>
        if psStringEq value target then true else smaller target

def psErasureAddUniqueStringWorker
    (used : List String)
    (attempts : Nat)
    (base : String) : String :=
  match attempts with
  | Nat.zero => String.Internal.append base "_overflow"
  | Nat.succ remaining =>
      if psErasureStringInList used base then
        psErasureAddUniqueStringWorker used remaining
          (String.Internal.append base "_")
      else base

def psErasureAddUniqueString (used : List String) (base : String) (attempts : Nat) : String :=
  psErasureAddUniqueStringWorker used attempts base

structure PsErasureNameState where
  used : List String
  entriesRev : List (PsName × String)

def psBuildErasureDeclarationNamesWorker
    (declarations : List PsDeclaration)
    (state : PsErasureNameState) : PsErasureNameState :=
  match declarations with
  | List.nil =>
      state
  | List.cons declaration rest =>
      let sourceName : Option PsName :=
        match declaration with
        | PsDeclaration.definitionDecl name _ _ _ => Option.some name
        | PsDeclaration.partialDecl name _ _ _ => Option.some name
        | PsDeclaration.theoremDecl name _ _ _ => Option.some name
        | PsDeclaration.inductiveDecl info => Option.some info.name
        | _ => Option.none;
      match sourceName with
      | Option.none => psBuildErasureDeclarationNamesWorker rest state
      | Option.some name =>
          let raw :=
            psErasureSafeIdentifier (psNameToString name) "decl";
          let candidate :=
            psErasureAddUniqueString state.used raw 4096;
          psBuildErasureDeclarationNamesWorker
            rest
            (PsErasureNameState.mk
              (List.cons candidate state.used)
              (List.cons (Prod.mk name candidate) state.entriesRev))

def psBuildErasureDeclarationNames
    (declarations : List PsDeclaration)
    (state : PsErasureNameState) : PsErasureNameState :=
  psBuildErasureDeclarationNamesWorker declarations state

def psErasureReverseDeclarationNamesAcc
    (entries : List (PsName × String)) :
    List (PsName × String) -> List (PsName × String) :=
  match entries with
  | List.nil =>
      fun (acc : List (PsName × String)) => acc
  | List.cons entry rest =>
      let smaller : List (PsName × String) -> List (PsName × String) :=
        psErasureReverseDeclarationNamesAcc rest;
      fun (acc : List (PsName × String)) =>
        smaller (List.cons entry acc)

def psErasureDeclarationNames
    (declarations : List PsDeclaration) :
    List (PsName × String) :=
  let state :=
    psBuildErasureDeclarationNames
      declarations
      (PsErasureNameState.mk List.nil List.nil);
  psErasureReverseDeclarationNamesAcc state.entriesRev List.nil

def psErasureReverseTypeParametersAcc
    (parameters : List PsVerifiedIrTypeParameter) :
    List PsVerifiedIrTypeParameter -> List PsVerifiedIrTypeParameter :=
  match parameters with
  | List.nil =>
      fun (acc : List PsVerifiedIrTypeParameter) => acc
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrTypeParameter -> List PsVerifiedIrTypeParameter :=
        psErasureReverseTypeParametersAcc rest;
      fun (acc : List PsVerifiedIrTypeParameter) =>
        smaller (List.cons parameter acc)

def psErasureReverseParametersAcc
    (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrParameter -> List PsVerifiedIrParameter :=
  match parameters with
  | List.nil =>
      fun (acc : List PsVerifiedIrParameter) => acc
  | List.cons parameter rest =>
      let smaller : List PsVerifiedIrParameter -> List PsVerifiedIrParameter :=
        psErasureReverseParametersAcc rest;
      fun (acc : List PsVerifiedIrParameter) =>
        smaller (List.cons parameter acc)

def psErasureAppendRuntimeParameter
    (parameters : List String)
    (name : String) : List String :=
  match parameters with
  | List.nil => List.cons name List.nil
  | List.cons parameter rest =>
      List.cons parameter (psErasureAppendRuntimeParameter rest name)

def psEraseOpenDefinitionWithFuel
    (environment : PsEnvironment)
    (fuel : Nat) :
    PsErasureScope ->
    PsExpr ->
    PsExpr ->
    Nat ->
    List PsVerifiedIrTypeParameter ->
    List PsVerifiedIrParameter ->
    Except PsErasureError PsOpenedErasedDefinition :=
  match fuel with
  | Nat.zero =>
      fun (_scope : PsErasureScope)
          (_currentType : PsExpr)
          (_currentValue : PsExpr)
          (_typeIndex : Nat)
          (_typeParametersRev : List PsVerifiedIrTypeParameter)
          (_parametersRev : List PsVerifiedIrParameter) =>
        Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      fun (scope : PsErasureScope)
          (currentType : PsExpr)
          (currentValue : PsExpr)
          (typeIndex : Nat)
          (typeParametersRev : List PsVerifiedIrTypeParameter)
          (parametersRev : List PsVerifiedIrParameter) =>
        let smaller :
            PsErasureScope ->
            PsExpr ->
            PsExpr ->
            Nat ->
            List PsVerifiedIrTypeParameter ->
            List PsVerifiedIrParameter ->
            Except PsErasureError PsOpenedErasedDefinition :=
          psEraseOpenDefinitionWithFuel environment remaining;
        match currentType with
        | PsExpr.forallE typeName domain typeBody binder =>
            match currentValue with
            | PsExpr.lam valueName _ valueBody _ =>
                let kind :=
                  psErasureClassifyBinder
                    environment
                    scope.localContext
                    domain;
                let pushed :=
                  psLocalPushBinding
                    scope.localContext
                    typeName
                    domain
                    binder;
                let openedVariable := PsExpr.fvar pushed.id;
                let nextType :=
                  psExprInstantiate1 typeBody openedVariable;
                let nextValue :=
                  psExprInstantiate1 valueBody openedVariable;
                match kind with
                | PsErasedBinderKind.type =>
                    let parameterName :=
                      String.Internal.append "T" (psNatToString typeIndex);
                    let nextCurrentDefinition : Option PsErasureCurrentDefinition :=
                      match scope.currentDefinition with
                      | Option.none => Option.none
                      | Option.some current =>
                          Option.some
                            (PsErasureCurrentDefinition.mk
                              current.name
                              (List.cons (PsVerifiedIrType.typeParameter parameterName) current.typeArgumentsRev)
                              current.runtimeParameters);
                    let nextScope : PsErasureScope :=
                      PsErasureScope.mk
                        pushed.context
                        scope.runtimeLocals
                        (List.cons (Prod.mk pushed.id parameterName) scope.typeLocals)
                        (List.cons pushed.id scope.erasedLocals)
                        scope.declarationNames
                        scope.runtimeConstructors
                        scope.runtimeRecursors
                        scope.runtimeStructures
                        scope.runtimeStructureConstructors
                        scope.runtimeExpressions
                        nextCurrentDefinition;
                    smaller
                      nextScope
                      nextType
                      nextValue
                      (Nat.succ typeIndex)
                      (List.cons
                        (PsVerifiedIrTypeParameter.mk parameterName)
                        typeParametersRev)
                      parametersRev
                | PsErasedBinderKind.proof =>
                    let nextScope : PsErasureScope :=
                      PsErasureScope.mk
                        pushed.context
                        scope.runtimeLocals
                        scope.typeLocals
                        (List.cons pushed.id scope.erasedLocals)
                        scope.declarationNames
                        scope.runtimeConstructors
                        scope.runtimeRecursors
                        scope.runtimeStructures
                        scope.runtimeStructureConstructors
                        scope.runtimeExpressions
                        scope.currentDefinition;
                    smaller
                      nextScope
                      nextType
                      nextValue
                      typeIndex
                      typeParametersRev
                      parametersRev
                | PsErasedBinderKind.runtime =>
                    let parameterName :=
                      psErasureLocalName scope
                        (psNameToString valueName)
                        "arg" pushed.id;
                    match
                        psEraseRuntimeType
                          environment
                          scope
                          domain with
                    | Except.error error => Except.error error
                    | Except.ok parameterType =>
                        let nextCurrentDefinition : Option PsErasureCurrentDefinition :=
                          match scope.currentDefinition with
                          | Option.none => Option.none
                          | Option.some current =>
                              Option.some
                                (PsErasureCurrentDefinition.mk
                                  current.name
                                  current.typeArgumentsRev
                                  (psErasureAppendRuntimeParameter current.runtimeParameters parameterName));
                        let nextScope : PsErasureScope :=
                          PsErasureScope.mk
                            pushed.context
                            (List.cons (Prod.mk pushed.id parameterName) scope.runtimeLocals)
                            scope.typeLocals
                            scope.erasedLocals
                            scope.declarationNames
                            scope.runtimeConstructors
                            scope.runtimeRecursors
                            scope.runtimeStructures
                            scope.runtimeStructureConstructors
                            scope.runtimeExpressions
                            nextCurrentDefinition;
                        smaller
                          nextScope
                          nextType
                          nextValue
                          typeIndex
                          typeParametersRev
                          (List.cons
                            (PsVerifiedIrParameter.mk parameterName parameterType)
                            parametersRev)
            | _ =>
                match
                    psEraseRuntimeType
                      environment
                      scope
                      currentType with
                | Except.error error => Except.error error
                | Except.ok resultType =>
                    match
                        psEraseRuntimeExpr
                          environment
                          scope
                          currentValue with
                    | Except.error error => Except.error error
                    | Except.ok body =>
                        Except.ok
                          (PsOpenedErasedDefinition.mk
                            (psErasureReverseTypeParametersAcc typeParametersRev List.nil)
                            (psErasureReverseParametersAcc parametersRev List.nil)
                            resultType
                            body)
        | _ =>
            match
                psEraseRuntimeType
                  environment
                  scope
                  currentType with
            | Except.error error => Except.error error
            | Except.ok resultType =>
                match
                    psEraseRuntimeExpr
                      environment
                      scope
                      currentValue with
                | Except.error error => Except.error error
                | Except.ok body =>
                    Except.ok
                      (PsOpenedErasedDefinition.mk
                        (psErasureReverseTypeParametersAcc typeParametersRev List.nil)
                        (psErasureReverseParametersAcc parametersRev List.nil)
                        resultType
                        body)

def psEraseOpenDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (type value : PsExpr) :
    Except PsErasureError PsOpenedErasedDefinition :=
  psEraseOpenDefinitionWithFuel
    environment
    4096
    scope
    type
    value
    0
    []
    []

-- A direct single-definition caller can supply a value before that definition
-- replaces its self axiom in the environment. Seed only this missing entry from
-- the supplied raw type/value; module erasure has already prepared the catalogue.
def psErasureEnsureDefinitionEntry
    (environment : PsEnvironment) (scope : PsErasureScope)
    (name : PsName) (type value : PsExpr) : Except PsErasureError PsErasureScope :=
  match psErasureLookupEntry scope.declarationNames name with
  | Option.some _ => Except.ok scope
  | Option.none =>
      match psErasureAddDeclarationEntry environment name type value
          scope.declarationNames.entries with
      | Except.error error => Except.error error
      | Except.ok entries =>
          let names := PsErasureDeclarationNames.mk
            scope.declarationNames.byCore scope.declarationNames.byOutput
            scope.declarationNames.count entries;
          Except.ok
            (PsErasureScope.mk scope.localContext scope.runtimeLocals scope.typeLocals
              scope.erasedLocals names scope.runtimeConstructors scope.runtimeRecursors
              scope.runtimeStructures scope.runtimeStructureConstructors
              scope.runtimeExpressions scope.currentDefinition)

def psEraseDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (name : PsName)
    (type value : PsExpr) :
    Except PsErasureError (Option PsVerifiedIrDeclaration) :=
  if psErasureDefinitionIsErased environment type then
    Except.ok Option.none
  else
    let outputName : String :=
      match psErasureLookupName
          scope.declarationNames
          name with
      | Option.some known => known
      | Option.none =>
          psErasureSafeIdentifier
            (psNameToString name)
            "decl";
    match psErasureEnsureDefinitionEntry environment scope name type value with
    | Except.error error => Except.error error
    | Except.ok entryScope =>
        let definitionScope : PsErasureScope :=
          PsErasureScope.mk
            entryScope.localContext
            entryScope.runtimeLocals
            entryScope.typeLocals
            entryScope.erasedLocals
            entryScope.declarationNames
            entryScope.runtimeConstructors
            entryScope.runtimeRecursors
            entryScope.runtimeStructures
            entryScope.runtimeStructureConstructors
            entryScope.runtimeExpressions
            (Option.some
              (PsErasureCurrentDefinition.mk outputName List.nil List.nil));
        match psLowerStructureRecursors environment value with
        | Except.error error => Except.error error
        | Except.ok normalizedValue =>
            match
                psEraseOpenDefinition
                  environment
                  definitionScope
                  type
                  normalizedValue with
            | Except.error error => Except.error error
            | Except.ok opened =>
                -- Keep the actual aligned Core entry prefix. A computed function
                -- result is evaluated here and returned as a canonical unary value.
                if psListIsEmpty opened.parameters then
                  if psListIsEmpty opened.typeParameters then
                    Except.ok
                      (Option.some
                        (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                          opened.parameters opened.resultType opened.body))
                  else
                    match psErasureIgnoredUnitNameWithFuel
                        definitionScope opened.body 4096 0 with
                    | Except.error error => Except.error error
                    | Except.ok unitName =>
                        Except.ok
                          (Option.some
                            (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                              [PsVerifiedIrParameter.mk unitName
                                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.unit)]
                              opened.resultType opened.body))
                else
                  Except.ok
                    (Option.some
                      (PsVerifiedIrDeclaration.mk outputName opened.typeParameters
                        opened.parameters opened.resultType opened.body))

def psErasureReverseIrDeclarationsAcc
    (declarations : List PsVerifiedIrDeclaration) :
    List PsVerifiedIrDeclaration -> List PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil =>
      fun (acc : List PsVerifiedIrDeclaration) => acc
  | List.cons declaration rest =>
      let smaller : List PsVerifiedIrDeclaration -> List PsVerifiedIrDeclaration :=
        psErasureReverseIrDeclarationsAcc rest;
      fun (acc : List PsVerifiedIrDeclaration) =>
        smaller (List.cons declaration acc)

def psEraseDefinitionsLoopWorker
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (declarations : List PsDeclaration)
    (declarationsRev : List PsVerifiedIrDeclaration) :
    Except PsErasureError (List PsVerifiedIrDeclaration) :=
  match declarations with
  | List.nil =>
      Except.ok (psErasureReverseIrDeclarationsAcc declarationsRev List.nil)
  | List.cons declaration rest =>
      match declaration with
      | PsDeclaration.definitionDecl name _ type value =>
          match psEraseDefinition environment scope name type value with
          | Except.error error => Except.error error
          | Except.ok result =>
              match result with
              | Option.none =>
                  psEraseDefinitionsLoopWorker environment scope rest declarationsRev
              | Option.some lowered =>
                  psEraseDefinitionsLoopWorker environment scope rest
                    (List.cons lowered declarationsRev)
      | PsDeclaration.partialDecl name _ type value =>
          match psEraseDefinition environment scope name type value with
          | Except.error error => Except.error error
          | Except.ok result =>
              match result with
              | Option.none =>
                  psEraseDefinitionsLoopWorker environment scope rest declarationsRev
              | Option.some lowered =>
                  psEraseDefinitionsLoopWorker environment scope rest
                    (List.cons lowered declarationsRev)
      | _ =>
          psEraseDefinitionsLoopWorker environment scope rest declarationsRev

def psEraseDefinitionsLoop
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (declarations : List PsDeclaration)
    (declarationsRev : List PsVerifiedIrDeclaration) :
    Except PsErasureError (List PsVerifiedIrDeclaration) :=
  psEraseDefinitionsLoopWorker environment scope declarations declarationsRev

def psErasureAppendDeclarations (declarations : List PsDeclaration) : List PsDeclaration -> List PsDeclaration :=
  match declarations with
  | List.nil => fun (tail : List PsDeclaration) => tail
  | List.cons declaration rest =>
      let smaller : List PsDeclaration -> List PsDeclaration := psErasureAppendDeclarations rest;
      fun (tail : List PsDeclaration) => List.cons declaration (smaller tail)

-- Data metadata remains available unconditionally. Checked runtime prelude
-- definitions are emitted only when referenced, including transitive calls.
-- This is closure selection over Core identities, not an intrinsic name rule.
def psErasureExprReferences (target : PsName) (expr : PsExpr) : Bool :=
  match expr with
  | PsExpr.constE name _ => psNameEq name target
  | PsExpr.app fn argument =>
      if psErasureExprReferences target fn then true
      else psErasureExprReferences target argument
  | PsExpr.lam _ type body _ =>
      if psErasureExprReferences target type then true
      else psErasureExprReferences target body
  | PsExpr.forallE _ type body _ =>
      if psErasureExprReferences target type then true
      else psErasureExprReferences target body
  | PsExpr.letE _ type value body =>
      if psErasureExprReferences target type then true
      else if psErasureExprReferences target value then true
      else psErasureExprReferences target body
  | PsExpr.proj name _ value =>
      if psNameEq name target then true else psErasureExprReferences target value
  | _ => false

def psErasureDeclarationReferences (target : PsName) (declaration : PsDeclaration) : Bool :=
  if psErasureExprReferences target (psDeclarationType declaration) then true
  else
    match declaration with
    | PsDeclaration.definitionDecl _ _ _ value => psErasureExprReferences target value
    | PsDeclaration.theoremDecl _ _ _ value => psErasureExprReferences target value
    | PsDeclaration.partialDecl _ _ _ value => psErasureExprReferences target value
    | PsDeclaration.opaqueDecl _ _ _ value => psErasureExprReferences target value
    | _ => false

def psErasureDeclarationsReference
    (target : PsName) (declarations : List PsDeclaration) : Bool :=
  match declarations with
  | List.nil => false
  | List.cons declaration rest =>
      if psErasureDeclarationReferences target declaration then true
      else psErasureDeclarationsReference target rest

def psErasureSelectRuntimePrelude
    (roots : List PsDeclaration) (candidates : List PsDeclaration) : List PsDeclaration :=
  match candidates with
  | List.nil => List.nil
  | List.cons declaration rest =>
      let tail := psErasureSelectRuntimePrelude roots rest;
      match declaration with
      | PsDeclaration.definitionDecl name _ _ _ =>
          if psErasureDeclarationsReference name roots then List.cons declaration tail
          else tail
      | _ => List.cons declaration tail

def psErasureRuntimePreludeClosure
    (roots candidates : List PsDeclaration) (fuel : Nat) :
    List PsDeclaration -> List PsDeclaration :=
  match fuel with
  | Nat.zero => fun (selected : List PsDeclaration) => selected
  | Nat.succ remaining =>
      fun (selected : List PsDeclaration) =>
        let next := psErasureSelectRuntimePrelude
          (psErasureAppendDeclarations roots selected) candidates;
        if Nat.beq (psListLength next) (psListLength selected) then next
        else psErasureRuntimePreludeClosure roots candidates remaining next

-- Host ownership/name planning and runtime erasure must use this same ordered
-- closure, including whether a prelude runtime definition is actually needed.
def psErasureRuntimeDeclarations
    (runtimePreludeDeclarations declarations : List PsDeclaration) : List PsDeclaration :=
  let selectedRuntimePrelude :=
    psErasureRuntimePreludeClosure declarations runtimePreludeDeclarations
      (Nat.succ (psListLength runtimePreludeDeclarations)) [];
  psErasureAppendDeclarations selectedRuntimePrelude declarations

def psEraseCoreModuleWithRuntimePrelude
    (environment : PsEnvironment)
    (runtimePreludeDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  let runtimeDeclarations :=
    psErasureRuntimeDeclarations runtimePreludeDeclarations declarations;
  let names := psErasureDeclarationNames runtimeDeclarations;
  let baseScope := psErasureScopeEmpty names;
  match psErasurePrepareDeclarationEntries environment runtimeDeclarations baseScope with
  | Except.error error => Except.error error
  | Except.ok entryScope =>
      match
          psPrepareRuntimeStructures
            environment
            runtimeDeclarations
            runtimeDeclarations
            entryScope
            [] with
      | Except.error error => Except.error error
      | Except.ok preparedStructures =>
          match
              psPrepareRuntimeInductives
                environment
                runtimeDeclarations
                runtimeDeclarations
                preparedStructures.scope
                [] with
          | Except.error error => Except.error error
          | Except.ok preparedInductives =>
              match
                  psEraseDefinitionsLoop
                    environment
                    preparedInductives.scope
                    runtimeDeclarations
                    [] with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    imports := []
                    structures := preparedStructures.ir
                    inductives := preparedInductives.ir
                    declarations := lowered
                  }

def psEraseCoreModule
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  psEraseCoreModuleWithRuntimePrelude
    environment
    List.nil
    declarations
