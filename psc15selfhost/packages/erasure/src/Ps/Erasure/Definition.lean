import Ps.Erasure.Expr
import Ps.Erasure.Inductive
import Ps.Erasure.StructureRecursor
import Ps.Erasure.PrimitiveNat

structure PsOpenedErasedDefinition where
  typeParameters : List PsVerifiedIrTypeParameter
  parameters : List PsVerifiedIrParameter
  resultType : PsVerifiedIrType
  body : PsVerifiedIrExpr

def psEraseNormalizedRuntimeExpr
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (expr : PsExpr) :
    Except PsErasureError PsVerifiedIrExpr :=
  match psLowerPrimitiveNat scope expr with
  | Except.error error => Except.error error
  | Except.ok normalized =>
      psEraseRuntimeExpr environment scope normalized

def psErasureAddUniqueString
    (used : List String)
    (base : String) :
    Nat -> String
  | 0 => base ++ "_overflow"
  | attempts + 1 =>
      if used.contains base then
        psErasureAddUniqueString
          used
          (base ++ "_")
          attempts
      else
        base

def psErasureIrExprUsesNameWithFuel :
    Nat -> PsVerifiedIrExpr -> String -> Bool
  | 0, _, _ => false
  | fuel + 1, expr, target =>
      match expr with
      | .literal _ => false
      | .var name => name == target
      | .intrinsic _ _ arguments =>
          arguments.any
            (fun argument =>
              psErasureIrExprUsesNameWithFuel
                fuel argument target)
      | .lambda parameters _ body =>
          parameters.any
              (fun parameter => parameter.name == target)
            || psErasureIrExprUsesNameWithFuel
                fuel body target
      | .call fn _ arguments =>
          psErasureIrExprUsesNameWithFuel fuel fn target
            || arguments.any
              (fun argument =>
                psErasureIrExprUsesNameWithFuel
                  fuel argument target)
      | .letE name _ value body =>
          name == target
            || psErasureIrExprUsesNameWithFuel
                fuel value target
            || psErasureIrExprUsesNameWithFuel
                fuel body target
      | .ifE condition thenBranch elseBranch =>
          psErasureIrExprUsesNameWithFuel
              fuel condition target
            || psErasureIrExprUsesNameWithFuel
                fuel thenBranch target
            || psErasureIrExprUsesNameWithFuel
                fuel elseBranch target
      | .record _ _ fields =>
          fields.any
            (fun field =>
              psErasureIrExprUsesNameWithFuel
                fuel field.2 target)
      | .projection _ _ value _ =>
          psErasureIrExprUsesNameWithFuel
            fuel value target
      | .constructor _ _ _ fields =>
          fields.any
            (fun field =>
              psErasureIrExprUsesNameWithFuel
                fuel field.2 target)
      | .matchE _ _ scrutinee alternatives =>
          psErasureIrExprUsesNameWithFuel
              fuel scrutinee target
            || alternatives.any
              (fun alternative =>
                alternative.2.1.any
                    (fun binding => binding.name == target)
                  || psErasureIrExprUsesNameWithFuel
                    fuel alternative.2.2 target)

def psErasureIrExprUsesName
    (expr : PsVerifiedIrExpr)
    (target : String) : Bool :=
  psErasureIrExprUsesNameWithFuel 4096 expr target

def psErasureParameterNames :
    List PsVerifiedIrParameter -> List String
  | [] => []
  | parameter :: rest =>
      parameter.name :: psErasureParameterNames rest

def psErasureEtaFreshName
    (body : PsVerifiedIrExpr)
    (used : List String) :
    Nat -> Nat -> String
  | index, 0 =>
      "__ps_eta_overflow_" ++ toString index
  | index, attempts + 1 =>
      let candidate := "__ps_eta_" ++ toString index
      if
          used.contains candidate
            || psErasureIrExprUsesName body candidate then
        psErasureEtaFreshName
          body
          used
          (index + 1)
          attempts
      else
        candidate

structure PsErasureEtaState where
  parametersRev : List PsVerifiedIrParameter
  argumentsRev : List PsVerifiedIrExpr
  used : List String
  nextIndex : Nat

def psErasureBuildEtaState
    (body : PsVerifiedIrExpr) :
    List PsVerifiedIrType ->
    PsErasureEtaState ->
    PsErasureEtaState
  | [], state => state
  | type :: rest, state =>
      let name :=
        psErasureEtaFreshName
          body
          state.used
          state.nextIndex
          4096
      psErasureBuildEtaState
        body
        rest
        {
          parametersRev :=
            { name := name, type := type } ::
              state.parametersRev
          argumentsRev :=
            PsVerifiedIrExpr.var name ::
              state.argumentsRev
          used := name :: state.used
          nextIndex := state.nextIndex + 1
        }

def psErasureEtaBindLambda :
    List PsVerifiedIrParameter ->
    List PsVerifiedIrExpr ->
    PsVerifiedIrExpr ->
    Option PsVerifiedIrExpr
  | [], [], body => some body
  | parameter :: restParameters,
    argument :: restArguments,
    body =>
      match
          psErasureEtaBindLambda
            restParameters
            restArguments
            body with
      | none => none
      | some inner =>
          some
            (PsVerifiedIrExpr.letE
              parameter.name
              parameter.type
              argument
              inner)
  | _, _, _ => none

def psErasureEtaMapAlternatives
    (apply : PsVerifiedIrExpr -> PsVerifiedIrExpr) :
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) ->
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr)
  | [] => []
  | alternative :: rest =>
      (alternative.1,
        alternative.2.1,
        apply alternative.2.2) ::
        psErasureEtaMapAlternatives apply rest

def psErasureEtaApplyWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    List PsVerifiedIrExpr ->
    PsVerifiedIrExpr
  | 0, expr, arguments =>
      PsVerifiedIrExpr.call expr [] arguments
  | fuel + 1, expr, arguments =>
      match arguments with
      | [] => expr
      | _ =>
          let apply :=
            fun body =>
              psErasureEtaApplyWithFuel
                fuel body arguments
          match expr with
          | .lambda parameters resultType body =>
              match
                  psErasureEtaBindLambda
                    parameters
                    arguments
                    body with
              | some applied => applied
              | none =>
                  PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.lambda
                      parameters resultType body)
                    []
                    arguments
          | .letE name type value body =>
              PsVerifiedIrExpr.letE
                name
                type
                value
                (apply body)
          | .ifE condition thenBranch elseBranch =>
              PsVerifiedIrExpr.ifE
                condition
                (apply thenBranch)
                (apply elseBranch)
          | .matchE inductiveName typeArguments scrutinee alternatives =>
              PsVerifiedIrExpr.matchE
                inductiveName
                typeArguments
                scrutinee
                (psErasureEtaMapAlternatives
                  apply alternatives)
          | _ =>
              PsVerifiedIrExpr.call
                expr
                []
                arguments

def psErasureEtaApply
    (expr : PsVerifiedIrExpr)
    (arguments : List PsVerifiedIrExpr) :
    PsVerifiedIrExpr :=
  psErasureEtaApplyWithFuel 4096 expr arguments

def psErasureFlattenOpenedDefinition
    (opened : PsOpenedErasedDefinition) :
    PsOpenedErasedDefinition :=
  if
      opened.typeParameters.isEmpty
        && opened.parameters.isEmpty then
    opened
  else
    match opened.resultType with
    | .function etaTypes finalResultType =>
        match etaTypes with
        | [] => opened
        | _ =>
            let state :=
              psErasureBuildEtaState
                opened.body
                etaTypes
                {
                  parametersRev := []
                  argumentsRev := []
                  used := psErasureParameterNames opened.parameters
                  nextIndex := 0
                }
            let etaParameters := state.parametersRev.reverse
            let etaArguments := state.argumentsRev.reverse
            {
              typeParameters := opened.typeParameters
              parameters := opened.parameters ++ etaParameters
              resultType := finalResultType
              body := psErasureEtaApply opened.body etaArguments
            }
    | _ => opened

structure PsErasureNameState where
  used : List String
  entriesRev : List (PsName × String)

def psBuildErasureDeclarationNames :
    List PsDeclaration ->
    PsErasureNameState ->
    PsErasureNameState
  | [], state => state
  | declaration :: rest, state =>
      let sourceName :=
        match declaration with
        | .definitionDecl name _ _ _ => some name
        | .partialDecl name _ _ _ => some name
        | .theoremDecl name _ _ _ => some name
        | .inductiveDecl info => some info.name
        | _ => none
      match sourceName with
      | none =>
          psBuildErasureDeclarationNames rest state
      | some name =>
          let raw :=
            psErasureSafeIdentifier
              (psNameToString name)
              "decl"
          let candidate :=
            psErasureAddUniqueString state.used raw 4096
          psBuildErasureDeclarationNames
            rest
            {
              used := candidate :: state.used
              entriesRev := (name, candidate) :: state.entriesRev
            }

def psErasureDeclarationNames
    (declarations : List PsDeclaration) :
    List (PsName × String) :=
  let state :=
    psBuildErasureDeclarationNames
      declarations
      { used := [], entriesRev := [] }
  state.entriesRev.reverse

def psEraseOpenDefinitionWithFuel
    (environment : PsEnvironment) :
    Nat ->
    PsErasureScope ->
    PsExpr ->
    PsExpr ->
    Nat ->
    List PsVerifiedIrTypeParameter ->
    List PsVerifiedIrParameter ->
    Except PsErasureError PsOpenedErasedDefinition
  | 0, _, _, _, _, _, _ =>
      Except.error PsErasureError.fuelExhausted
  | fuel + 1,
    scope,
    currentType,
    currentValue,
    typeIndex,
    typeParametersRev,
    parametersRev =>
      match currentType with
      | .forallE typeName domain typeBody binder =>
          match currentValue with
          | .lam valueName _ valueBody _ =>
              let kind :=
                psErasureClassifyBinder
                  environment
                  scope.localContext
                  domain
              let pushed :=
                psLocalPushBinding
                  scope.localContext
                  typeName
                  domain
                  binder
              let openedVariable := PsExpr.fvar pushed.id
              let nextType :=
                psExprInstantiate1 typeBody openedVariable
              let nextValue :=
                psExprInstantiate1 valueBody openedVariable
              match kind with
              | .type =>
                  let parameterName :=
                    "T" ++ toString typeIndex
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals := scope.runtimeLocals
                    typeLocals :=
                      (pushed.id, parameterName) ::
                        scope.typeLocals
                    erasedLocals :=
                      pushed.id :: scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  }
                  psEraseOpenDefinitionWithFuel
                    environment
                    fuel
                    nextScope
                    nextType
                    nextValue
                    (typeIndex + 1)
                    ({ name := parameterName } ::
                      typeParametersRev)
                    parametersRev
              | .proof =>
                  let nextScope : PsErasureScope := {
                    localContext := pushed.context
                    runtimeLocals := scope.runtimeLocals
                    typeLocals := scope.typeLocals
                    erasedLocals :=
                      pushed.id :: scope.erasedLocals
                    declarationNames := scope.declarationNames
                    runtimeConstructors := scope.runtimeConstructors
                    runtimeRecursors := scope.runtimeRecursors
                    runtimeStructures := scope.runtimeStructures
                    runtimeStructureConstructors := scope.runtimeStructureConstructors
                    runtimeExpressions := scope.runtimeExpressions
                    currentDefinition := scope.currentDefinition
                  }
                  psEraseOpenDefinitionWithFuel
                    environment
                    fuel
                    nextScope
                    nextType
                    nextValue
                    typeIndex
                    typeParametersRev
                    parametersRev
              | .runtime =>
                  let parameterName :=
                    psErasureSafeIdentifier
                      (psNameToString valueName)
                      "arg"
                  match
                      psEraseRuntimeType
                        environment
                        scope
                        domain with
                  | Except.error error => Except.error error
                  | Except.ok parameterType =>
                      let nextScope : PsErasureScope := {
                        localContext := pushed.context
                        runtimeLocals :=
                          (pushed.id, parameterName) ::
                            scope.runtimeLocals
                        typeLocals := scope.typeLocals
                        erasedLocals := scope.erasedLocals
                        declarationNames := scope.declarationNames
                        runtimeConstructors := scope.runtimeConstructors
                        runtimeRecursors := scope.runtimeRecursors
                        runtimeStructures := scope.runtimeStructures
                        runtimeStructureConstructors := scope.runtimeStructureConstructors
                        runtimeExpressions := scope.runtimeExpressions
                        currentDefinition :=
                          match scope.currentDefinition with
                          | none => none
                          | some current =>
                              some {
                                current with
                                runtimeParameters :=
                                  current.runtimeParameters ++
                                    [parameterName]
                              }
                      }
                      psEraseOpenDefinitionWithFuel
                        environment
                        fuel
                        nextScope
                        nextType
                        nextValue
                        typeIndex
                        typeParametersRev
                        ({
                          name := parameterName
                          type := parameterType
                        } :: parametersRev)
          | _ =>
              match
                  psEraseRuntimeType
                    environment
                    scope
                    currentType with
              | Except.error error => Except.error error
              | Except.ok resultType =>
                  match
                      psEraseNormalizedRuntimeExpr
                        environment
                        scope
                        currentValue with
                  | Except.error error => Except.error error
                  | Except.ok body =>
                      Except.ok {
                        typeParameters := typeParametersRev.reverse
                        parameters := parametersRev.reverse
                        resultType := resultType
                        body := body
                      }
      | _ =>
          match
              psEraseRuntimeType
                environment
                scope
                currentType with
          | Except.error error => Except.error error
          | Except.ok resultType =>
              match
                  psEraseNormalizedRuntimeExpr
                    environment
                    scope
                    currentValue with
              | Except.error error => Except.error error
              | Except.ok body =>
                  Except.ok {
                    typeParameters := typeParametersRev.reverse
                    parameters := parametersRev.reverse
                    resultType := resultType
                    body := body
                  }

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
    Except.ok none
  else
    let outputName :=
      match psErasureLookupName
          scope.declarationNames
          name with
      | some known => known
      | none =>
          psErasureSafeIdentifier
            (psNameToString name)
            "decl"
    let definitionScope : PsErasureScope := {
      scope with
      currentDefinition := some {
        name := outputName
        runtimeParameters := []
      }
    }
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
            let flattened :=
              psErasureFlattenOpenedDefinition opened
            Except.ok
              (some {
                name := outputName
                typeParameters := flattened.typeParameters
                parameters := flattened.parameters
                resultType := flattened.resultType
                body := flattened.body
              })

def psEraseDefinitionsLoop
    (environment : PsEnvironment)
    (scope : PsErasureScope) :
    List PsDeclaration ->
    List PsVerifiedIrDeclaration ->
    Except PsErasureError (List PsVerifiedIrDeclaration)
  | [], declarationsRev =>
      Except.ok declarationsRev.reverse
  | declaration :: rest, declarationsRev =>
      match declaration with
      | .definitionDecl name _ type value =>
          match
              psEraseDefinition
                environment
                scope
                name
                type
                value with
          | Except.error error => Except.error error
          | Except.ok none =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                declarationsRev
          | Except.ok (some lowered) =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                (lowered :: declarationsRev)
      | .partialDecl name _ type value =>
          match
              psEraseDefinition
                environment
                scope
                name
                type
                value with
          | Except.error error => Except.error error
          | Except.ok none =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                declarationsRev
          | Except.ok (some lowered) =>
              psEraseDefinitionsLoop
                environment
                scope
                rest
                (lowered :: declarationsRev)
      | _ =>
          psEraseDefinitionsLoop
            environment
            scope
            rest
            declarationsRev

def psEraseCoreModuleWithRuntimePrelude
    (environment : PsEnvironment)
    (runtimePreludeDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    Except PsErasureError PsVerifiedIrModule :=
  let runtimeDeclarations :=
    List.append runtimePreludeDeclarations declarations
  let names := psErasureDeclarationNames runtimeDeclarations
  let baseScope := psErasureScopeEmpty names
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
