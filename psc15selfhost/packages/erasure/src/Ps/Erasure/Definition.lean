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

def psErasureAddUniqueStringWorker (used : List String) (attempts : Nat) : String -> String :=
  match attempts with
  | Nat.zero => fun (base : String) => String.Internal.append base "_overflow"
  | Nat.succ remaining =>
      let smaller : String -> String := psErasureAddUniqueStringWorker used remaining;
      fun (base : String) =>
        if psErasureStringInList used base then smaller (String.Internal.append base "_")
        else base

def psErasureAddUniqueString (used : List String) (base : String) (attempts : Nat) : String :=
  psErasureAddUniqueStringWorker used attempts base

structure PsErasureNameState where
  used : List String
  entriesRev : List (PsName × String)

def psBuildErasureDeclarationNamesWorker
    (declarations : List PsDeclaration) :
    PsErasureNameState -> PsErasureNameState :=
  match declarations with
  | List.nil =>
      fun (state : PsErasureNameState) => state
  | List.cons declaration rest =>
      let smaller : PsErasureNameState -> PsErasureNameState :=
        psBuildErasureDeclarationNamesWorker rest;
      fun (state : PsErasureNameState) =>
        let sourceName : Option PsName :=
          match declaration with
          | PsDeclaration.definitionDecl name _ _ _ => Option.some name
          | PsDeclaration.partialDecl name _ _ _ => Option.some name
          | PsDeclaration.theoremDecl name _ _ _ => Option.some name
          | PsDeclaration.inductiveDecl info => Option.some info.name
          | _ => Option.none;
        match sourceName with
        | Option.none => smaller state
        | Option.some name =>
            let raw :=
              psErasureSafeIdentifier (psNameToString name) "decl";
            let candidate :=
              psErasureAddUniqueString state.used raw 4096;
            smaller
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
      let smaller :
          PsErasureScope ->
          PsExpr ->
          PsExpr ->
          Nat ->
          List PsVerifiedIrTypeParameter ->
          List PsVerifiedIrParameter ->
          Except PsErasureError PsOpenedErasedDefinition :=
        psEraseOpenDefinitionWithFuel environment remaining;
      fun (scope : PsErasureScope)
          (currentType : PsExpr)
          (currentValue : PsExpr)
          (typeIndex : Nat)
          (typeParametersRev : List PsVerifiedIrTypeParameter)
          (parametersRev : List PsVerifiedIrParameter) =>
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
                        scope.currentDefinition;
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

def psEraseDefinition
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (name : PsName)
    (type value : PsExpr) :
    Except PsErasureError (Option PsVerifiedIrDeclaration) :=
  if psErasureIsProp environment psLocalEmpty type then
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
    let definitionScope : PsErasureScope :=
      PsErasureScope.mk
        scope.localContext
        scope.runtimeLocals
        scope.typeLocals
        scope.erasedLocals
        scope.declarationNames
        scope.runtimeConstructors
        scope.runtimeRecursors
        scope.runtimeStructures
        scope.runtimeStructureConstructors
        scope.runtimeExpressions
        (Option.some
          (PsErasureCurrentDefinition.mk outputName List.nil));
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
            match psErasureEtaFunction opened.parameters opened.resultType opened.body with
            | Except.error error => Except.error error
            | Except.ok expanded =>
                match expanded with
                | PsVerifiedIrExpr.lambda parameters resultType body =>
                    Except.ok
                      (Option.some
                        (PsVerifiedIrDeclaration.mk outputName opened.typeParameters parameters resultType body))
                | _ => Except.error PsErasureError.unsupportedRuntimeTerm

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
    (declarations : List PsDeclaration) :
    List PsVerifiedIrDeclaration ->
    Except PsErasureError (List PsVerifiedIrDeclaration) :=
  match declarations with
  | List.nil =>
      fun (declarationsRev : List PsVerifiedIrDeclaration) =>
        Except.ok (psErasureReverseIrDeclarationsAcc declarationsRev List.nil)
  | List.cons declaration rest =>
      let smaller :
          List PsVerifiedIrDeclaration ->
          Except PsErasureError (List PsVerifiedIrDeclaration) :=
        psEraseDefinitionsLoopWorker environment scope rest;
      fun (declarationsRev : List PsVerifiedIrDeclaration) =>
        match declaration with
        | PsDeclaration.definitionDecl name _ type value =>
            match psEraseDefinition environment scope name type value with
            | Except.error error => Except.error error
            | Except.ok result =>
                match result with
                | Option.none => smaller declarationsRev
                | Option.some lowered =>
                    smaller (List.cons lowered declarationsRev)
        | PsDeclaration.partialDecl name _ type value =>
            match psEraseDefinition environment scope name type value with
            | Except.error error => Except.error error
            | Except.ok result =>
                match result with
                | Option.none => smaller declarationsRev
                | Option.some lowered =>
                    smaller (List.cons lowered declarationsRev)
        | _ => smaller declarationsRev

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

def psEraseCoreModuleWithRuntimePrelude
    (environment : PsEnvironment)
    (runtimePreludeDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  let runtimeDeclarations :=
    psErasureAppendDeclarations runtimePreludeDeclarations declarations;
  let names := psErasureDeclarationNames runtimeDeclarations;
  let baseScope := psErasureScopeEmpty names;
  match
      psPrepareRuntimeStructures
        environment
        runtimeDeclarations
        runtimeDeclarations
        baseScope
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
                declarations
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
