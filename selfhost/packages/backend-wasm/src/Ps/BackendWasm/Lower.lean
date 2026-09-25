import Ps.CompilerIr.Specialize
import Ps.BackendWasm.Binary
import Ps.BackendWasm.LowerInt
import Ps.BackendWasm.LowerFloat

inductive PsWasmLowerError where
  | unsupportedType
  | unsupportedExpression
  | unsupportedIntrinsic
  | invalidIntrinsicArity
  | invalidCallArity
  | unknownVariable (name : String)
  | unknownStructure (name : String)
  | unknownStructureField (structureName : String) (field : String)
  | missingRecordField (structureName : String) (field : String)
  | unknownInductive (name : String)
  | unknownConstructor (inductiveName : String) (constructorName : String)
  | unknownConstructorField
      (inductiveName : String)
      (constructorName : String)
      (field : String)
  | missingConstructorField
      (inductiveName : String)
      (constructorName : String)
      (field : String)
  | unsupportedModuleFeature

structure PsWasmLowerState where
  nextLocalIndex : Nat
  localTypes : List PsWasmValueType
  currentDefinition : String
  nextLambdaId : Nat
  generatedStructures : List PsWasmStructType
  generatedFunctionTypes : List PsWasmFunctionType
  generatedFunctions : List PsWasmFunction
  generatedFunctionRefs : List String

structure PsWasmLoweredExpr where
  instructions : List PsWasmInstruction
  state : PsWasmLowerState

structure PsWasmBinding where
  name : String
  index : Nat
  type : PsVerifiedIrType

structure PsWasmLoweredBindings where
  instructions : List PsWasmInstruction
  bindings : List PsWasmBinding
  state : PsWasmLowerState

def psWasmLowerParameterType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmValueType :=
  match psWasmValueTypeOfIrType? profile type with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some valueType => Except.ok valueType

def psWasmLowerResultType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match type with
  | .primitive .unit => Except.ok []
  | _ =>
      match psWasmValueTypeOfIrType? profile type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some valueType => Except.ok [valueType]

def psWasmLowerParameterTypes
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrParameter ->
    Except PsWasmLowerError (List PsWasmValueType)
  | [] => Except.ok []
  | parameter :: rest =>
      match psWasmLowerParameterType profile parameter.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerParameterTypes profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmExpectedResultType :
    List PsWasmValueType ->
    Except PsWasmLowerError (Option PsWasmValueType)
  | [] => Except.ok none
  | [result] => Except.ok (some result)
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmMachineIntegerValueType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType) :
    PsWasmValueType :=
  if psWasmMachineIntegerIs64 profile type then
    .i64
  else
    .i32

def psWasmFloatingValueType
    (type : PsVerifiedIrFloatingType) :
    PsWasmValueType :=
  match type with
  | .float32 => .f32
  | .float => .f64

def psWasmFunctionTypeListContains
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | none => false
  | some candidateKey =>
      types.any
        (fun existing =>
          match psWasmIrTypeKey existing with
          | none => false
          | some existingKey => existingKey == candidateKey)

def psWasmInsertFunctionType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match candidate with
  | .function _ _ =>
      if psWasmFunctionTypeListContains types candidate then
        types
      else
        types ++ [candidate]
  | _ => types

def psWasmCollectFunctionTypesFromTypeWithFuel :
    Nat ->
    PsVerifiedIrType ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, type, types =>
      match type with
      | .function parameters result =>
          let withSelf :=
            psWasmInsertFunctionType types type
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                psWasmCollectFunctionTypesFromTypeWithFuel
                  fuel parameter state)
              withSelf
          psWasmCollectFunctionTypesFromTypeWithFuel
            fuel result withParameters
      | .named _ arguments =>
          arguments.foldl
            (fun state argument =>
              psWasmCollectFunctionTypesFromTypeWithFuel
                fuel argument state)
            types
      | _ => types

def psWasmCollectFunctionTypesFromType
    (type : PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectFunctionTypesFromTypeWithFuel 64 type types

def psWasmCollectFunctionTypesFromParameters
    (parameters : List PsVerifiedIrParameter)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  parameters.foldl
    (fun state parameter =>
      psWasmCollectFunctionTypesFromType
        parameter.type
        state)
    types

def psWasmCollectFunctionTypesFromExprWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, expr, types =>
      let collect :=
        fun expression state =>
          psWasmCollectFunctionTypesFromExprWithFuel
            fuel expression state
      match expr with
      | .literal _ => types
      | .var _ => types
      | .intrinsic _ typeArguments arguments =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectFunctionTypesFromType type state)
              types
          arguments.foldl
            (fun state argument => collect argument state)
            withTypes
      | .lambda parameters resultType body =>
          let withParameters :=
            psWasmCollectFunctionTypesFromParameters
              parameters types
          let functionType :=
            PsVerifiedIrType.function
              (parameters.map (fun parameter => parameter.type))
              resultType
          let withFunction :=
            psWasmInsertFunctionType
              withParameters
              functionType
          let withResult :=
            psWasmCollectFunctionTypesFromType
              resultType
              withFunction
          collect body withResult
      | .call fn typeArguments arguments =>
          let withFn := collect fn types
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectFunctionTypesFromType type state)
              withFn
          arguments.foldl
            (fun state argument => collect argument state)
            withTypes
      | .letE _ type value body =>
          let withType :=
            psWasmCollectFunctionTypesFromType type types
          let withValue := collect value withType
          collect body withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition := collect condition types
          let withThen := collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ _ fields =>
          fields.foldl
            (fun state field => collect field.2 state)
            types
      | .projection _ _ target _ =>
          collect target types
      | .constructor _ _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectFunctionTypesFromType type state)
              types
          fields.foldl
            (fun state field => collect field.2 state)
            withTypes
      | .matchE _ _ scrutinee alternatives =>
          let withScrutinee := collect scrutinee types
          alternatives.foldl
            (fun state alternative =>
              let bindings := alternative.2.1
              let body := alternative.2.2
              let withBindings :=
                bindings.foldl
                  (fun inner binding =>
                    psWasmCollectFunctionTypesFromType
                      binding.type
                      inner)
                  state
              collect body withBindings)
            withScrutinee

def psWasmCollectFunctionTypesFromExpr
    (expr : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectFunctionTypesFromExprWithFuel 4096 expr types

def psWasmCollectModuleFunctionTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let fromStructures :=
    module.structures.foldl
      (fun state structureInfo =>
        structureInfo.fields.foldl
          (fun inner field =>
            psWasmCollectFunctionTypesFromType field.type inner)
          state)
      []
  let fromInductives :=
    module.inductives.foldl
      (fun state inductiveInfo =>
        inductiveInfo.constructors.foldl
          (fun inner constructorInfo =>
            constructorInfo.fields.foldl
              (fun fieldsState field =>
                psWasmCollectFunctionTypesFromType
                  field.type
                  fieldsState)
              inner)
          state)
      fromStructures
  module.declarations.foldl
    (fun state declaration =>
      let withParameters :=
        psWasmCollectFunctionTypesFromParameters
          declaration.parameters
          state
      let withResult :=
        psWasmCollectFunctionTypesFromType
          declaration.resultType
          withParameters
      psWasmCollectFunctionTypesFromExpr
        declaration.body
        withResult)
    fromInductives

structure PsWasmClosureSignature where
  baseStructure : PsWasmStructType
  codeType : PsWasmFunctionType

def psWasmLowerIrTypeList
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrType ->
    Except PsWasmLowerError (List PsWasmValueType)
  | [] => Except.ok []
  | type :: rest =>
      match psWasmValueTypeOfIrType? profile type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some lowered =>
          match psWasmLowerIrTypeList profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmLowerClosureSignature
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmClosureSignature :=
  match type with
  | .function parameters result =>
      match psWasmClosureBaseName type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some baseName =>
          match psWasmClosureCodeTypeName type with
          | none => Except.error PsWasmLowerError.unsupportedType
          | some codeTypeName =>
              match psWasmLowerIrTypeList profile parameters with
              | Except.error error => Except.error error
              | Except.ok loweredParameters =>
                  match psWasmLowerResultType profile result with
                  | Except.error error => Except.error error
                  | Except.ok loweredResults =>
                      Except.ok {
                        baseStructure := {
                          name := baseName
                          superType := none
                          isFinal := false
                          fields := [
                            {
                              name := "code"
                              storageType :=
                                PsWasmStorageType.value
                                  PsWasmValueType.funcRef
                            }
                          ]
                        }
                        codeType := {
                          name := codeTypeName
                          parameters :=
                            PsWasmValueType.refT baseName ::
                              loweredParameters
                          results := loweredResults
                        }
                      }
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmLowerClosureSignatures
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrType ->
    Except PsWasmLowerError
      (List PsWasmStructType × List PsWasmFunctionType)
  | [] => Except.ok ([], [])
  | type :: rest =>
      match psWasmLowerClosureSignature profile type with
      | Except.error error => Except.error error
      | Except.ok signature =>
          match psWasmLowerClosureSignatures profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (
                  signature.baseStructure :: loweredRest.1,
                  signature.codeType :: loweredRest.2
                )

def psWasmFindStructure :
    List PsVerifiedIrStructure -> String -> Option PsVerifiedIrStructure
  | [], _ => none
  | structInfo :: rest, name =>
      if structInfo.name == name then
        some structInfo
      else
        psWasmFindStructure rest name

def psWasmFindStructureFieldLoop
    (fieldName : String) :
    Nat ->
    List PsVerifiedIrStructureField ->
    Option (Nat × PsVerifiedIrStructureField)
  | _, [] => none
  | index, field :: rest =>
      if field.name == fieldName then
        some (index, field)
      else
        psWasmFindStructureFieldLoop
          fieldName (index + 1) rest

def psWasmFindStructureField
    (structInfo : PsVerifiedIrStructure)
    (fieldName : String) :
    Option (Nat × PsVerifiedIrStructureField) :=
  psWasmFindStructureFieldLoop fieldName 0 structInfo.fields

def psWasmFindRecordField :
    List (String × PsVerifiedIrExpr) ->
    String ->
    Option PsVerifiedIrExpr
  | [], _ => none
  | field :: rest, name =>
      if field.1 == name then
        some field.2
      else
        psWasmFindRecordField rest name

def psWasmStructGetInstruction
    (structureName : String)
    (fieldIndex : Nat)
    (type : PsVerifiedIrType) : PsWasmInstruction :=
  match type with
  | .primitive .uint8 =>
      .structGetU structureName fieldIndex
  | .primitive .uint16 =>
      .structGetU structureName fieldIndex
  | .primitive .int8 =>
      .structGetS structureName fieldIndex
  | .primitive .int16 =>
      .structGetS structureName fieldIndex
  | _ => .structGet structureName fieldIndex

def psWasmLowerStructureField
    (profile : PsWasmTargetProfile)
    (field : PsVerifiedIrStructureField) :
    Except PsWasmLowerError PsWasmStructField :=
  match psWasmStorageTypeOfIrType? profile field.type with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some storageType =>
      Except.ok {
        name := field.name
        storageType := storageType
      }

def psWasmLowerStructureFields
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrStructureField ->
    Except PsWasmLowerError (List PsWasmStructField)
  | [] => Except.ok []
  | field :: rest =>
      match psWasmLowerStructureField profile field with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerStructureFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmLowerStructure
    (profile : PsWasmTargetProfile)
    (structInfo : PsVerifiedIrStructure) :
    Except PsWasmLowerError PsWasmStructType :=
  match structInfo.typeParameters with
  | _ :: _ => Except.error PsWasmLowerError.unsupportedType
  | [] =>
      match psWasmLowerStructureFields profile structInfo.fields with
      | Except.error error => Except.error error
      | Except.ok fields =>
          Except.ok {
            name := structInfo.name
            superType := none
            isFinal := true
            fields := fields
          }

def psWasmLowerStructures
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrStructure ->
    Except PsWasmLowerError (List PsWasmStructType)
  | [] => Except.ok []
  | structInfo :: rest =>
      match psWasmLowerStructure profile structInfo with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerStructures profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmConstructorTypeName
    (inductiveName constructorName : String) : String :=
  inductiveName ++ "$" ++ constructorName

def psWasmFindInductive :
    List PsVerifiedIrInductive -> String -> Option PsVerifiedIrInductive
  | [], _ => none
  | inductiveInfo :: rest, name =>
      if inductiveInfo.name == name then
        some inductiveInfo
      else
        psWasmFindInductive rest name

def psWasmFindConstructor :
    List PsVerifiedIrConstructor -> String -> Option PsVerifiedIrConstructor
  | [], _ => none
  | constructorInfo :: rest, name =>
      if constructorInfo.name == name then
        some constructorInfo
      else
        psWasmFindConstructor rest name

def psWasmFindConstructorFieldLoop
    (fieldName : String) :
    Nat ->
    List PsVerifiedIrConstructorField ->
    Option (Nat × PsVerifiedIrConstructorField)
  | _, [] => none
  | index, field :: rest =>
      if field.name == fieldName then
        some (index, field)
      else
        psWasmFindConstructorFieldLoop
          fieldName (index + 1) rest

def psWasmFindConstructorField
    (constructorInfo : PsVerifiedIrConstructor)
    (fieldName : String) :
    Option (Nat × PsVerifiedIrConstructorField) :=
  psWasmFindConstructorFieldLoop
    fieldName
    0
    constructorInfo.fields

def psWasmLowerConstructorField
    (profile : PsWasmTargetProfile)
    (field : PsVerifiedIrConstructorField) :
    Except PsWasmLowerError PsWasmStructField :=
  match psWasmStorageTypeOfIrType? profile field.type with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some storageType =>
      Except.ok {
        name := field.name
        storageType := storageType
      }

def psWasmLowerConstructorFields
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrConstructorField ->
    Except PsWasmLowerError (List PsWasmStructField)
  | [] => Except.ok []
  | field :: rest =>
      match psWasmLowerConstructorField profile field with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerConstructorFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmLowerInductiveConstructors
    (profile : PsWasmTargetProfile)
    (inductiveInfo : PsVerifiedIrInductive) :
    List PsVerifiedIrConstructor ->
    Except PsWasmLowerError (List PsWasmStructType)
  | [] => Except.ok []
  | constructorInfo :: rest =>
      match
          psWasmLowerConstructorFields
            profile
            constructorInfo.fields with
      | Except.error error => Except.error error
      | Except.ok fields =>
          let lowered : PsWasmStructType := {
            name :=
              psWasmConstructorTypeName
                inductiveInfo.name
                constructorInfo.name
            superType := some inductiveInfo.name
            isFinal := true
            fields := fields
          }
          match
              psWasmLowerInductiveConstructors
                profile
                inductiveInfo
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmLowerInductive
    (profile : PsWasmTargetProfile)
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsWasmLowerError (List PsWasmStructType) :=
  match inductiveInfo.typeParameters with
  | _ :: _ => Except.error PsWasmLowerError.unsupportedType
  | [] =>
      let base : PsWasmStructType := {
        name := inductiveInfo.name
        superType := none
        isFinal := false
        fields := []
      }
      match
          psWasmLowerInductiveConstructors
            profile
            inductiveInfo
            inductiveInfo.constructors with
      | Except.error error => Except.error error
      | Except.ok constructors =>
          Except.ok (base :: constructors)

def psWasmLowerInductives
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrInductive ->
    Except PsWasmLowerError (List PsWasmStructType)
  | [] => Except.ok []
  | inductiveInfo :: rest =>
      match psWasmLowerInductive profile inductiveInfo with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerInductives profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered ++ loweredRest)

def psWasmParameterBindingsLoop :
    Nat -> List PsVerifiedIrParameter -> List PsWasmBinding
  | _, [] => []
  | index, parameter :: rest =>
      {
        name := parameter.name
        index := index
        type := parameter.type
      } ::
        psWasmParameterBindingsLoop (index + 1) rest

def psWasmParameterBindings
    (parameters : List PsVerifiedIrParameter) :
    List PsWasmBinding :=
  psWasmParameterBindingsLoop 0 parameters

def psWasmFindBinding :
    List PsWasmBinding -> String -> Option PsWasmBinding
  | [], _ => none
  | binding :: rest, name =>
      if binding.name == name then
        some binding
      else
        psWasmFindBinding rest name

def psWasmFindBindingIndex
    (bindings : List PsWasmBinding)
    (name : String) : Option Nat :=
  match psWasmFindBinding bindings name with
  | none => none
  | some binding => some binding.index

def psWasmStringListContains :
    List String -> String -> Bool
  | [], _ => false
  | item :: rest, name =>
      if item == name then
        true
      else
        psWasmStringListContains rest name

def psWasmBindingListContains :
    List PsWasmBinding -> String -> Bool
  | [], _ => false
  | binding :: rest, name =>
      if binding.name == name then
        true
      else
        psWasmBindingListContains rest name

def psWasmAppendCaptureForName
    (outerBindings : List PsWasmBinding)
    (boundNames : List String)
    (captures : List PsWasmBinding)
    (name : String) : List PsWasmBinding :=
  if psWasmStringListContains boundNames name then
    captures
  else if psWasmBindingListContains captures name then
    captures
  else
    match psWasmFindBinding outerBindings name with
    | none => captures
    | some binding => captures ++ [binding]

def psWasmParameterNames :
    List PsVerifiedIrParameter -> List String
  | [] => []
  | parameter :: rest =>
      parameter.name :: psWasmParameterNames rest

def psWasmMatchBindingNames :
    List PsVerifiedIrMatchBinding -> List String
  | [] => []
  | binding :: rest =>
      binding.name :: psWasmMatchBindingNames rest

def psWasmCollectCapturesWithFuel
    (outerBindings : List PsWasmBinding)
    (boundNames : List String) :
    Nat ->
    PsVerifiedIrExpr ->
    List PsWasmBinding ->
    List PsWasmBinding
  | 0, _, captures => captures
  | fuel + 1, expr, captures =>
      let collect :=
        fun nested state =>
          psWasmCollectCapturesWithFuel
            outerBindings
            boundNames
            fuel
            nested
            state
      match expr with
      | .literal _ => captures
      | .var name =>
          psWasmAppendCaptureForName
            outerBindings
            boundNames
            captures
            name
      | .intrinsic _ typeArguments arguments =>
          arguments.foldl
            (fun state argument => collect argument state)
            captures
      | .lambda parameters _ body =>
          psWasmCollectCapturesWithFuel
            outerBindings
            (psWasmParameterNames parameters ++ boundNames)
            fuel
            body
            captures
      | .call fn _ arguments =>
          let withFn := collect fn captures
          arguments.foldl
            (fun state argument => collect argument state)
            withFn
      | .letE name _ value body =>
          let withValue := collect value captures
          psWasmCollectCapturesWithFuel
            outerBindings
            (name :: boundNames)
            fuel
            body
            withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition := collect condition captures
          let withThen := collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ _ fields =>
          fields.foldl
            (fun state field => collect field.2 state)
            captures
      | .projection _ _ target _ =>
          collect target captures
      | .constructor _ _ _ fields =>
          fields.foldl
            (fun state field => collect field.2 state)
            captures
      | .matchE _ _ scrutinee alternatives =>
          let withScrutinee := collect scrutinee captures
          alternatives.foldl
            (fun state alternative =>
              let matchBindings := alternative.2.1
              let body := alternative.2.2
              psWasmCollectCapturesWithFuel
                outerBindings
                (psWasmMatchBindingNames matchBindings ++ boundNames)
                fuel
                body
                state)
            withScrutinee

def psWasmCollectCaptures
    (outerBindings : List PsWasmBinding)
    (parameters : List PsVerifiedIrParameter)
    (body : PsVerifiedIrExpr) :
    List PsWasmBinding :=
  psWasmCollectCapturesWithFuel
    outerBindings
    (psWasmParameterNames parameters)
    4096
    body
    []

def psWasmParameterBindingsFrom
    (firstIndex : Nat) :
    List PsVerifiedIrParameter -> List PsWasmBinding
  | [] => []
  | parameter :: rest =>
      {
        name := parameter.name
        index := firstIndex
        type := parameter.type
      } ::
        psWasmParameterBindingsFrom
          (firstIndex + 1)
          rest

def psWasmAddLocal
    (state : PsWasmLowerState)
    (type : PsWasmValueType) :
    Nat × PsWasmLowerState :=
  let index := state.nextLocalIndex
  (
    index,
    {
      nextLocalIndex := index + 1
      localTypes := state.localTypes ++ [type]
      currentDefinition := state.currentDefinition
      nextLambdaId := state.nextLambdaId
      generatedStructures := state.generatedStructures
      generatedFunctionTypes := state.generatedFunctionTypes
      generatedFunctions := state.generatedFunctions
      generatedFunctionRefs := state.generatedFunctionRefs
    }
  )

def psWasmStateForNestedFunction
    (state : PsWasmLowerState)
    (parameterCount : Nat) : PsWasmLowerState :=
  {
    nextLocalIndex := parameterCount
    localTypes := []
    currentDefinition := state.currentDefinition
    nextLambdaId := state.nextLambdaId
    generatedStructures := state.generatedStructures
    generatedFunctionTypes := state.generatedFunctionTypes
    generatedFunctions := state.generatedFunctions
    generatedFunctionRefs := state.generatedFunctionRefs
  }

def psWasmStateRestoreOuterLocals
    (outerState generatedState : PsWasmLowerState) :
    PsWasmLowerState :=
  {
    nextLocalIndex := outerState.nextLocalIndex
    localTypes := outerState.localTypes
    currentDefinition := outerState.currentDefinition
    nextLambdaId := generatedState.nextLambdaId
    generatedStructures := generatedState.generatedStructures
    generatedFunctionTypes := generatedState.generatedFunctionTypes
    generatedFunctions := generatedState.generatedFunctions
    generatedFunctionRefs := generatedState.generatedFunctionRefs
  }

def psWasmLowerExprListWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (expected : Option PsWasmValueType) :
    PsWasmLowerState ->
    List PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | state, [] =>
      Except.ok {
        instructions := []
        state := state
      }
  | state, expr :: rest =>
      match lower expected state expr with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psWasmLowerExprListWith
                lower expected lowered.state rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                instructions :=
                  lowered.instructions ++ loweredRest.instructions
                state := loweredRest.state
              }

def psWasmLowerRecordFieldsWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (structInfo : PsVerifiedIrStructure)
    (fields : List (String × PsVerifiedIrExpr)) :
    PsWasmLowerState ->
    List PsVerifiedIrStructureField ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | state, [] =>
      Except.ok {
        instructions := []
        state := state
      }
  | state, field :: rest =>
      match psWasmFindRecordField fields field.name with
      | none =>
          Except.error
            (PsWasmLowerError.missingRecordField
              structInfo.name field.name)
      | some value =>
          match psWasmValueTypeOfIrType? profile field.type with
          | none => Except.error PsWasmLowerError.unsupportedType
          | some valueType =>
              match lower (some valueType) state value with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  match
                      psWasmLowerRecordFieldsWith
                        profile
                        lower
                        structInfo
                        fields
                        lowered.state
                        rest with
                  | Except.error error => Except.error error
                  | Except.ok loweredRest =>
                      Except.ok {
                        instructions :=
                          lowered.instructions ++
                            loweredRest.instructions
                        state := loweredRest.state
                      }

def psWasmLowerConstructorValuesWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor)
    (fields : List (String × PsVerifiedIrExpr)) :
    PsWasmLowerState ->
    List PsVerifiedIrConstructorField ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | state, [] =>
      Except.ok {
        instructions := []
        state := state
      }
  | state, field :: rest =>
      match psWasmFindRecordField fields field.name with
      | none =>
          Except.error
            (PsWasmLowerError.missingConstructorField
              inductiveName
              constructorInfo.name
              field.name)
      | some value =>
          match psWasmValueTypeOfIrType? profile field.type with
          | none => Except.error PsWasmLowerError.unsupportedType
          | some valueType =>
              match lower (some valueType) state value with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  match
                      psWasmLowerConstructorValuesWith
                        profile
                        lower
                        inductiveName
                        constructorInfo
                        fields
                        lowered.state
                        rest with
                  | Except.error error => Except.error error
                  | Except.ok loweredRest =>
                      Except.ok {
                        instructions :=
                          lowered.instructions ++
                            loweredRest.instructions
                        state := loweredRest.state
                      }

def psWasmLowerIntrinsicWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match operation with
  | .machineIntBinary type integerOperation =>
      match arguments with
      | [left, right] =>
          let expected :=
            some (psWasmMachineIntegerValueType profile type)
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++
                    psWasmLowerMachineIntegerBinary
                      profile type integerOperation
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .machineIntCompare type integerOperation =>
      match arguments with
      | [left, right] =>
          let expected :=
            some (psWasmMachineIntegerValueType profile type)
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++
                    psWasmLowerMachineIntegerCompare
                      profile type integerOperation
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .floatBinary type floatOperation =>
      match arguments with
      | [left, right] =>
          let expected := some (psWasmFloatingValueType type)
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++
                    psWasmLowerFloatBinary type floatOperation
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | .floatCompare type floatOperation =>
      match arguments with
      | [left, right] =>
          let expected := some (psWasmFloatingValueType type)
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++
                    psWasmLowerFloatCompare type floatOperation
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity
  | _ => Except.error PsWasmLowerError.unsupportedIntrinsic

def psWasmLowerTypedArgumentsWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr) :
    PsWasmLowerState ->
    List PsVerifiedIrType ->
    List PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | state, [], [] =>
      Except.ok {
        instructions := []
        state := state
      }
  | state, type :: restTypes, argument :: restArguments =>
      match psWasmValueTypeOfIrType? profile type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some expected =>
          match lower (some expected) state argument with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              match
                  psWasmLowerTypedArgumentsWith
                    profile
                    lower
                    lowered.state
                    restTypes
                    restArguments with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok {
                    instructions :=
                      lowered.instructions
                        ++ loweredRest.instructions
                    state := loweredRest.state
                  }
  | _, _, _ =>
      Except.error PsWasmLowerError.invalidCallArity

def psWasmLowerFunctionValueCall
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (binding : PsWasmBinding)
    (parameterTypes : List PsVerifiedIrType)
    (resultType : PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  let functionType :=
    PsVerifiedIrType.function parameterTypes resultType
  match psWasmClosureBaseName functionType with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some baseName =>
      match psWasmClosureCodeTypeName functionType with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some codeTypeName =>
          let allocated :=
            psWasmAddLocal
              state
              (PsWasmValueType.refT baseName)
          let closureLocal := allocated.1
          let nextState := allocated.2
          match
              psWasmLowerTypedArgumentsWith
                profile
                lower
                nextState
                parameterTypes
                arguments with
          | Except.error error => Except.error error
          | Except.ok loweredArguments =>
              Except.ok {
                instructions :=
                  [
                    PsWasmInstruction.localGet binding.index,
                    PsWasmInstruction.localSet closureLocal,
                    PsWasmInstruction.localGet closureLocal
                  ]
                    ++ loweredArguments.instructions
                    ++ [
                      PsWasmInstruction.localGet closureLocal,
                      PsWasmInstruction.structGet baseName 0,
                      PsWasmInstruction.refCastFunction codeTypeName,
                      PsWasmInstruction.callRef codeTypeName
                    ]
                state := loweredArguments.state
              }

def psWasmLowerCallWith
    (profile : PsWasmTargetProfile)
    (bindings : List PsWasmBinding)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (fn : PsVerifiedIrExpr)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match fn with
  | .var name =>
      match psWasmFindBinding bindings name with
      | some binding =>
          match binding.type with
          | .function parameterTypes resultType =>
              psWasmLowerFunctionValueCall
                profile
                lower
                state
                binding
                parameterTypes
                resultType
                arguments
          | _ =>
              Except.error PsWasmLowerError.unsupportedExpression
      | none =>
          match
              psWasmLowerExprListWith
                lower none state arguments with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++
                    [PsWasmInstruction.call name]
                state := lowered.state
              }
  | _ => Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerIfWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (expected : Option PsWasmValueType)
    (condition thenBranch elseBranch : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match expected with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some resultType =>
      match
          lower
            (some PsWasmValueType.i32)
            state
            condition with
      | Except.error error => Except.error error
      | Except.ok conditionCode =>
          match
              lower
                expected
                conditionCode.state
                thenBranch with
          | Except.error error => Except.error error
          | Except.ok thenCode =>
              match
                  lower
                    expected
                    thenCode.state
                    elseBranch with
              | Except.error error => Except.error error
              | Except.ok elseCode =>
                  Except.ok {
                    instructions :=
                      conditionCode.instructions
                        ++ [PsWasmInstruction.ifStart (some resultType)]
                        ++ thenCode.instructions
                        ++ [PsWasmInstruction.else_]
                        ++ elseCode.instructions
                        ++ [PsWasmInstruction.end_]
                    state := elseCode.state
                  }

def psWasmLowerMatchBindings
    (profile : PsWasmTargetProfile)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor)
    (scrutineeLocal : Nat)
    (baseBindings : List PsWasmBinding) :
    PsWasmLowerState ->
    List PsVerifiedIrMatchBinding ->
    Except PsWasmLowerError PsWasmLoweredBindings
  | state, [] =>
      Except.ok {
        instructions := []
        bindings := baseBindings
        state := state
      }
  | state, binding :: rest =>
      match
          psWasmFindConstructorField
            constructorInfo
            binding.field with
      | none =>
          Except.error
            (PsWasmLowerError.unknownConstructorField
              inductiveName
              constructorInfo.name
              binding.field)
      | some indexedField =>
          let fieldIndex := indexedField.1
          let field := indexedField.2
          match psWasmValueTypeOfIrType? profile field.type with
          | none => Except.error PsWasmLowerError.unsupportedType
          | some valueType =>
              let allocated := psWasmAddLocal state valueType
              let localIndex := allocated.1
              let nextState := allocated.2
              let constructorType :=
                psWasmConstructorTypeName
                  inductiveName
                  constructorInfo.name
              let fieldCode := [
                PsWasmInstruction.localGet scrutineeLocal,
                PsWasmInstruction.refCast constructorType,
                psWasmStructGetInstruction
                  constructorType
                  fieldIndex
                  field.type,
                PsWasmInstruction.localSet localIndex
              ]
              match
                  psWasmLowerMatchBindings
                    profile
                    inductiveName
                    constructorInfo
                    scrutineeLocal
                    ({
                      name := binding.name
                      index := localIndex
                      type := field.type
                    } :: baseBindings)
                    nextState
                    rest with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok {
                    instructions :=
                      fieldCode ++ loweredRest.instructions
                    bindings := loweredRest.bindings
                    state := loweredRest.state
                  }

def psWasmLowerMatchAlternativesWith
    (profile : PsWasmTargetProfile)
    (inductiveInfo : PsVerifiedIrInductive)
    (scrutineeLocal : Nat)
    (lowerWithBindings :
      List PsWasmBinding ->
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (baseBindings : List PsWasmBinding)
    (expected : Option PsWasmValueType) :
    PsWasmLowerState ->
    List
      (String ×
        List PsVerifiedIrMatchBinding ×
        PsVerifiedIrExpr) ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | _, [] =>
      Except.error PsWasmLowerError.unsupportedExpression
  | state, [alternative] =>
      let constructorName := alternative.1
      let matchBindings := alternative.2.1
      let body := alternative.2.2
      match
          psWasmFindConstructor
            inductiveInfo.constructors
            constructorName with
      | none =>
          Except.error
            (PsWasmLowerError.unknownConstructor
              inductiveInfo.name
              constructorName)
      | some constructorInfo =>
          match
              psWasmLowerMatchBindings
                profile
                inductiveInfo.name
                constructorInfo
                scrutineeLocal
                baseBindings
                state
                matchBindings with
          | Except.error error => Except.error error
          | Except.ok loweredBindings =>
              match
                  lowerWithBindings
                    loweredBindings.bindings
                    expected
                    loweredBindings.state
                    body with
              | Except.error error => Except.error error
              | Except.ok loweredBody =>
                  Except.ok {
                    instructions :=
                      loweredBindings.instructions ++
                        loweredBody.instructions
                    state := loweredBody.state
                  }
  | state, alternative :: rest =>
      match expected with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some resultType =>
          let constructorName := alternative.1
          let matchBindings := alternative.2.1
          let body := alternative.2.2
          match
              psWasmFindConstructor
                inductiveInfo.constructors
                constructorName with
          | none =>
              Except.error
                (PsWasmLowerError.unknownConstructor
                  inductiveInfo.name
                  constructorName)
          | some constructorInfo =>
              let constructorType :=
                psWasmConstructorTypeName
                  inductiveInfo.name
                  constructorName
              match
                  psWasmLowerMatchBindings
                    profile
                    inductiveInfo.name
                    constructorInfo
                    scrutineeLocal
                    baseBindings
                    state
                    matchBindings with
              | Except.error error => Except.error error
              | Except.ok loweredBindings =>
                  match
                      lowerWithBindings
                        loweredBindings.bindings
                        expected
                        loweredBindings.state
                        body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      match
                          psWasmLowerMatchAlternativesWith
                            profile
                            inductiveInfo
                            scrutineeLocal
                            lowerWithBindings
                            baseBindings
                            expected
                            loweredBody.state
                            rest with
                      | Except.error error => Except.error error
                      | Except.ok loweredRest =>
                          Except.ok {
                            instructions :=
                              [
                                PsWasmInstruction.localGet
                                  scrutineeLocal,
                                PsWasmInstruction.refTest
                                  constructorType,
                                PsWasmInstruction.ifStart
                                  (some resultType)
                              ]
                                ++ loweredBindings.instructions
                                ++ loweredBody.instructions
                                ++ [PsWasmInstruction.else_]
                                ++ loweredRest.instructions
                                ++ [PsWasmInstruction.end_]
                            state := loweredRest.state
                          }

def psWasmLowerCaptureFields
    (profile : PsWasmTargetProfile) :
    List PsWasmBinding ->
    Except PsWasmLowerError (List PsWasmStructField)
  | [] => Except.ok []
  | capture :: rest =>
      match psWasmStorageTypeOfIrType? profile capture.type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some storageType =>
          match psWasmLowerCaptureFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                ({
                  name := capture.name
                  storageType := storageType
                } :: loweredRest)

def psWasmPrepareCaptureBindings
    (profile : PsWasmTargetProfile)
    (subtypeName : String) :
    Nat ->
    PsWasmLowerState ->
    List PsWasmBinding ->
    Except PsWasmLowerError PsWasmLoweredBindings
  | _, state, [] =>
      Except.ok {
        instructions := []
        bindings := []
        state := state
      }
  | fieldIndex, state, capture :: rest =>
      match psWasmValueTypeOfIrType? profile capture.type with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some valueType =>
          let allocated := psWasmAddLocal state valueType
          let localIndex := allocated.1
          let nextState := allocated.2
          match
              psWasmPrepareCaptureBindings
                profile
                subtypeName
                (fieldIndex + 1)
                nextState
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                instructions :=
                  [
                    PsWasmInstruction.localGet 0,
                    PsWasmInstruction.refCast subtypeName,
                    psWasmStructGetInstruction
                      subtypeName
                      fieldIndex
                      capture.type,
                    PsWasmInstruction.localSet localIndex
                  ]
                    ++ loweredRest.instructions
                bindings :=
                  {
                    name := capture.name
                    index := localIndex
                    type := capture.type
                  } :: loweredRest.bindings
                state := loweredRest.state
              }

def psWasmCaptureConstructionInstructions :
    List PsWasmBinding -> List PsWasmInstruction
  | [] => []
  | capture :: rest =>
      PsWasmInstruction.localGet capture.index ::
        psWasmCaptureConstructionInstructions rest

def psWasmAdvanceLambdaId
    (state : PsWasmLowerState) : PsWasmLowerState :=
  {
    nextLocalIndex := state.nextLocalIndex
    localTypes := state.localTypes
    currentDefinition := state.currentDefinition
    nextLambdaId := state.nextLambdaId + 1
    generatedStructures := state.generatedStructures
    generatedFunctionTypes := state.generatedFunctionTypes
    generatedFunctions := state.generatedFunctions
    generatedFunctionRefs := state.generatedFunctionRefs
  }

def psWasmAddGeneratedLambda
    (outerState : PsWasmLowerState)
    (generatedState : PsWasmLowerState)
    (subtype : PsWasmStructType)
    (function : PsWasmFunction) :
    PsWasmLowerState :=
  psWasmStateRestoreOuterLocals
    outerState
    {
      nextLocalIndex := generatedState.nextLocalIndex
      localTypes := generatedState.localTypes
      currentDefinition := generatedState.currentDefinition
      nextLambdaId := generatedState.nextLambdaId
      generatedStructures :=
        generatedState.generatedStructures ++ [subtype]
      generatedFunctionTypes :=
        generatedState.generatedFunctionTypes
      generatedFunctions :=
        generatedState.generatedFunctions ++ [function]
      generatedFunctionRefs :=
        generatedState.generatedFunctionRefs ++ [function.name]
    }

def psWasmLowerLambdaWith
    (profile : PsWasmTargetProfile)
    (bindings : List PsWasmBinding)
    (lowerWithBindings :
      List PsWasmBinding ->
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (parameters : List PsVerifiedIrParameter)
    (resultType : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  let parameterTypes :=
    parameters.map (fun parameter => parameter.type)
  let functionType :=
    PsVerifiedIrType.function parameterTypes resultType
  match psWasmClosureBaseName functionType with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some baseName =>
      match psWasmClosureCodeTypeName functionType with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some codeTypeName =>
          match psWasmLowerIrTypeList profile parameterTypes with
          | Except.error error => Except.error error
          | Except.ok loweredParameters =>
              match psWasmLowerResultType profile resultType with
              | Except.error error => Except.error error
              | Except.ok results =>
                  match psWasmExpectedResultType results with
                  | Except.error error => Except.error error
                  | Except.ok expected =>
                      let lambdaId := state.nextLambdaId
                      let lambdaName :=
                        state.currentDefinition
                          ++ "$lambda$"
                          ++ toString lambdaId
                      let subtypeName :=
                        baseName ++ "$" ++ lambdaName
                      let captures :=
                        psWasmCollectCaptures
                          bindings
                          parameters
                          body
                      match psWasmLowerCaptureFields profile captures with
                      | Except.error error => Except.error error
                      | Except.ok captureFields =>
                          let subtype : PsWasmStructType := {
                            name := subtypeName
                            superType := some baseName
                            isFinal := true
                            fields :=
                              {
                                name := "code"
                                storageType :=
                                  PsWasmStorageType.value
                                    PsWasmValueType.funcRef
                              } :: captureFields
                          }
                          let advancedState :=
                            psWasmAdvanceLambdaId state
                          let nestedState :=
                            psWasmStateForNestedFunction
                              advancedState
                              (parameters.length + 1)
                          match
                              psWasmPrepareCaptureBindings
                                profile
                                subtypeName
                                1
                                nestedState
                                captures with
                          | Except.error error => Except.error error
                          | Except.ok preparedCaptures =>
                              let parameterBindings :=
                                psWasmParameterBindingsFrom
                                  1
                                  parameters
                              let bodyBindings :=
                                parameterBindings
                                  ++ preparedCaptures.bindings
                              match
                                  lowerWithBindings
                                    bodyBindings
                                    expected
                                    preparedCaptures.state
                                    body with
                              | Except.error error => Except.error error
                              | Except.ok loweredBody =>
                                  let generatedFunction : PsWasmFunction := {
                                    name := lambdaName
                                    typeName := some codeTypeName
                                    parameters :=
                                      PsWasmValueType.refT baseName ::
                                        loweredParameters
                                    results := results
                                    locals :=
                                      loweredBody.state.localTypes
                                    body :=
                                      preparedCaptures.instructions
                                        ++ loweredBody.instructions
                                  }
                                  let finalState :=
                                    psWasmAddGeneratedLambda
                                      state
                                      loweredBody.state
                                      subtype
                                      generatedFunction
                                  Except.ok {
                                    instructions :=
                                      [PsWasmInstruction.refFunc lambdaName]
                                        ++ psWasmCaptureConstructionInstructions
                                          captures
                                        ++ [PsWasmInstruction.structNew
                                          subtypeName]
                                    state := finalState
                                  }

def psWasmLowerExprWithFuel
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (bindings : List PsWasmBinding)
    (expected : Option PsWasmValueType) :
    Nat ->
    PsWasmLowerState ->
    PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | 0, _, _ =>
      Except.error PsWasmLowerError.unsupportedExpression
  | fuel + 1, state, expr =>
      let lowerWithBindings :=
        fun nextBindings expectedType nestedState nestedExpr =>
          psWasmLowerExprWithFuel
            profile
            structures
            inductives
            nextBindings
            expectedType
            fuel
            nestedState
            nestedExpr
      let lower :=
        lowerWithBindings bindings
      match expr with
      | .literal literal =>
          match literal with
          | .machineInteger type value =>
              Except.ok {
                instructions :=
                  psWasmLowerMachineIntegerLiteral profile type value
                state := state
              }
          | .bool value =>
              Except.ok {
                instructions :=
                  [PsWasmInstruction.i32Const
                    (if value then 1 else 0)]
                state := state
              }
          | .unit =>
              Except.ok {
                instructions := []
                state := state
              }
          | _ =>
              Except.error PsWasmLowerError.unsupportedExpression
      | .var name =>
          match psWasmFindBindingIndex bindings name with
          | none =>
              Except.error (PsWasmLowerError.unknownVariable name)
          | some index =>
              Except.ok {
                instructions := [PsWasmInstruction.localGet index]
                state := state
              }
      | .lambda parameters resultType body =>
          psWasmLowerLambdaWith
            profile
            bindings
            lowerWithBindings
            state
            parameters
            resultType
            body
      | .intrinsic operation typeArguments arguments =>
          psWasmLowerIntrinsicWith
            profile lower state operation typeArguments arguments
      | .call fn _ arguments =>
          psWasmLowerCallWith
            profile bindings lower state fn arguments
      | .letE name type value body =>
          match psWasmLowerParameterType profile type with
          | Except.error error => Except.error error
          | Except.ok localType =>
              match
                  lower
                    (some localType)
                    state
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  let allocated :=
                    psWasmAddLocal loweredValue.state localType
                  let localIndex := allocated.1
                  let localState := allocated.2
                  let bodyBindings :=
                    {
                      name := name
                      index := localIndex
                      type := type
                    } :: bindings
                  match
                      psWasmLowerExprWithFuel
                        profile
                        structures
                        inductives
                        bodyBindings
                        expected
                        fuel
                        localState
                        body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok {
                        instructions :=
                          loweredValue.instructions
                            ++ [PsWasmInstruction.localSet localIndex]
                            ++ loweredBody.instructions
                        state := loweredBody.state
                      }
      | .record structureName _ fields =>
          match psWasmFindStructure structures structureName with
          | none =>
              Except.error
                (PsWasmLowerError.unknownStructure structureName)
          | some structInfo =>
              match structInfo.typeParameters with
              | _ :: _ =>
                  Except.error PsWasmLowerError.unsupportedType
              | [] =>
                  match
                      psWasmLowerRecordFieldsWith
                        profile
                        lower
                        structInfo
                        fields
                        state
                        structInfo.fields with
                  | Except.error error => Except.error error
                  | Except.ok lowered =>
                      Except.ok {
                        instructions :=
                          lowered.instructions ++
                            [PsWasmInstruction.structNew structureName]
                        state := lowered.state
                      }
      | .projection structureName _ target fieldName =>
          match psWasmFindStructure structures structureName with
          | none =>
              Except.error
                (PsWasmLowerError.unknownStructure structureName)
          | some structInfo =>
              match psWasmFindStructureField structInfo fieldName with
              | none =>
                  Except.error
                    (PsWasmLowerError.unknownStructureField
                      structureName fieldName)
              | some indexedField =>
                  let fieldIndex := indexedField.1
                  let field := indexedField.2
                  match
                      lower
                        (some (PsWasmValueType.refT structureName))
                        state
                        target with
                  | Except.error error => Except.error error
                  | Except.ok lowered =>
                      Except.ok {
                        instructions :=
                          lowered.instructions ++
                            [psWasmStructGetInstruction
                              structureName
                              fieldIndex
                              field.type]
                        state := lowered.state
                      }
      | .constructor
          inductiveName
          constructorName
          typeArguments
          fields =>
          match typeArguments with
          | _ :: _ =>
              Except.error PsWasmLowerError.unsupportedType
          | [] =>
              match psWasmFindInductive inductives inductiveName with
              | none =>
                  Except.error
                    (PsWasmLowerError.unknownInductive inductiveName)
              | some inductiveInfo =>
                  match inductiveInfo.typeParameters with
                  | _ :: _ =>
                      Except.error PsWasmLowerError.unsupportedType
                  | [] =>
                      match
                          psWasmFindConstructor
                            inductiveInfo.constructors
                            constructorName with
                      | none =>
                          Except.error
                            (PsWasmLowerError.unknownConstructor
                              inductiveName
                              constructorName)
                      | some constructorInfo =>
                          match
                              psWasmLowerConstructorValuesWith
                                profile
                                lower
                                inductiveName
                                constructorInfo
                                fields
                                state
                                constructorInfo.fields with
                          | Except.error error =>
                              Except.error error
                          | Except.ok lowered =>
                              Except.ok {
                                instructions :=
                                  lowered.instructions ++
                                    [PsWasmInstruction.structNew
                                      (psWasmConstructorTypeName
                                        inductiveName
                                        constructorName)]
                                state := lowered.state
                              }
      | .matchE inductiveName _ scrutinee alternatives =>
          match psWasmFindInductive inductives inductiveName with
          | none =>
              Except.error
                (PsWasmLowerError.unknownInductive inductiveName)
          | some inductiveInfo =>
              match inductiveInfo.typeParameters with
              | _ :: _ =>
                  Except.error PsWasmLowerError.unsupportedType
              | [] =>
                  match
                      lower
                        (some (PsWasmValueType.refT inductiveName))
                        state
                        scrutinee with
                  | Except.error error => Except.error error
                  | Except.ok loweredScrutinee =>
                      let allocated :=
                        psWasmAddLocal
                          loweredScrutinee.state
                          (PsWasmValueType.refT inductiveName)
                      let scrutineeLocal := allocated.1
                      let nextState := allocated.2
                      match
                          psWasmLowerMatchAlternativesWith
                            profile
                            inductiveInfo
                            scrutineeLocal
                            lowerWithBindings
                            bindings
                            expected
                            nextState
                            alternatives with
                      | Except.error error => Except.error error
                      | Except.ok loweredMatch =>
                          Except.ok {
                            instructions :=
                              loweredScrutinee.instructions ++
                                [PsWasmInstruction.localSet
                                  scrutineeLocal] ++
                                loweredMatch.instructions
                            state := loweredMatch.state
                          }
      | .ifE condition thenBranch elseBranch =>
          psWasmLowerIfWith
            lower state expected condition thenBranch elseBranch

def psWasmLowerExpr
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (bindings : List PsWasmBinding)
    (expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprWithFuel
    profile structures inductives bindings expected 4096 state expr

structure PsWasmLoweredFunction where
  function : PsWasmFunction
  state : PsWasmLowerState

structure PsWasmLoweredFunctions where
  functions : List PsWasmFunction
  state : PsWasmLowerState

def psWasmLowerDeclaration
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (generationState : PsWasmLowerState)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsWasmLowerError PsWasmLoweredFunction :=
  match psWasmLowerParameterTypes profile declaration.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmLowerResultType profile declaration.resultType with
      | Except.error error => Except.error error
      | Except.ok results =>
          match psWasmExpectedResultType results with
          | Except.error error => Except.error error
          | Except.ok expected =>
              let bindings :=
                psWasmParameterBindings declaration.parameters
              let initialState : PsWasmLowerState := {
                nextLocalIndex := declaration.parameters.length
                localTypes := []
                currentDefinition := declaration.name
                nextLambdaId := 0
                generatedStructures :=
                  generationState.generatedStructures
                generatedFunctionTypes :=
                  generationState.generatedFunctionTypes
                generatedFunctions :=
                  generationState.generatedFunctions
                generatedFunctionRefs :=
                  generationState.generatedFunctionRefs
              }
              match
                  psWasmLowerExpr
                    profile
                    structures
                    inductives
                    bindings
                    expected
                    initialState
                    declaration.body with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    function := {
                      name := declaration.name
                      typeName := none
                      parameters := parameters
                      results := results
                      locals := lowered.state.localTypes
                      body := lowered.instructions
                    }
                    state := lowered.state
                  }

def psWasmLowerDeclarations
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive) :
    PsWasmLowerState ->
    List PsVerifiedIrDeclaration ->
    Except PsWasmLowerError PsWasmLoweredFunctions
  | state, [] =>
      Except.ok {
        functions := []
        state := state
      }
  | state, declaration :: rest =>
      match
          psWasmLowerDeclaration
            profile
            structures
            inductives
            state
            declaration with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psWasmLowerDeclarations
                profile
                structures
                inductives
                lowered.state
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok {
                functions :=
                  lowered.function :: loweredRest.functions
                state := loweredRest.state
              }

def psWasmExportsOfDeclarations :
    List PsVerifiedIrDeclaration -> List (String × String)
  | [] => []
  | declaration :: rest =>
      (declaration.name, declaration.name) ::
        psWasmExportsOfDeclarations rest

def psWasmModuleHasUnsupportedData
    (module : PsVerifiedIrModule) : Bool :=
  match module.imports with
  | _ :: _ => true
  | [] => false

def psWasmLowerSpecializedModule
    (profile : PsWasmTargetProfile)
    (module : PsVerifiedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  if psWasmModuleHasUnsupportedData module then
    Except.error PsWasmLowerError.unsupportedModuleFeature
  else
    match psWasmLowerStructures profile module.structures with
    | Except.error error => Except.error error
    | Except.ok structures =>
        match psWasmLowerInductives profile module.inductives with
        | Except.error error => Except.error error
        | Except.ok inductiveTypes =>
            let semanticFunctionTypes :=
              psWasmCollectModuleFunctionTypes module
            match
                psWasmLowerClosureSignatures
                  profile
                  semanticFunctionTypes with
            | Except.error error => Except.error error
            | Except.ok closureSignatures =>
                let initialState : PsWasmLowerState := {
                  nextLocalIndex := 0
                  localTypes := []
                  currentDefinition := ""
                  nextLambdaId := 0
                  generatedStructures := []
                  generatedFunctionTypes := []
                  generatedFunctions := []
                  generatedFunctionRefs := []
                }
                match
                    psWasmLowerDeclarations
                      profile
                      module.structures
                      module.inductives
                      initialState
                      module.declarations with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    Except.ok {
                      structures :=
                        structures
                          ++ inductiveTypes
                          ++ closureSignatures.1
                          ++ lowered.state.generatedStructures
                      functionTypes :=
                        closureSignatures.2
                          ++ lowered.state.generatedFunctionTypes
                      functions :=
                        lowered.functions
                          ++ lowered.state.generatedFunctions
                      functionRefs :=
                        lowered.state.generatedFunctionRefs
                      exports :=
                        psWasmExportsOfDeclarations
                          module.declarations
                    }


def psWasmLowerModule
    (profile : PsWasmTargetProfile)
    (module : PsVerifiedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  match psIrSpecializeModule module with
  | Except.error _ =>
      Except.error PsWasmLowerError.unsupportedModuleFeature
  | Except.ok specialized =>
      psWasmLowerSpecializedModule profile specialized
