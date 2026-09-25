import Ps.BackendWasm.Type

def psWasmArrayTypeListContains
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | none => false
  | some candidateKey =>
      types.any
        (fun existing =>
          match psWasmIrTypeKey existing with
          | none => false
          | some existingKey =>
              existingKey == candidateKey)

def psWasmInsertArrayElementType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  if psWasmArrayTypeListContains types candidate then
    types
  else
    types ++ [candidate]

def psWasmCollectArrayTypesFromTypeWithFuel :
    Nat ->
    PsVerifiedIrType ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, type, types =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayTypesFromTypeWithFuel
            fuel
            nested
            state
      match type with
      | .function parameters result =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                collect parameter state)
              types
          collect result withParameters
      | .named "Array" [elementType] =>
          let withNested :=
            collect elementType types
          psWasmInsertArrayElementType
            withNested
            elementType
      | .named _ arguments =>
          arguments.foldl
            (fun state argument =>
              collect argument state)
            types
      | _ => types

def psWasmCollectArrayTypesFromType
    (type : PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromTypeWithFuel
    64
    type
    types

def psWasmCollectArrayTypesFromIntrinsic
    (operation : PsVerifiedIrIntrinsic)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match operation with
  | .arrayEmptyWithCapacity elementType
  | .arraySize elementType
  | .arrayPush elementType
  | .arrayGet elementType
  | .arrayGetD elementType
  | .arraySet elementType
  | .arraySetIfInBounds elementType =>
      psWasmCollectArrayTypesFromType
        elementType
        (psWasmInsertArrayElementType
          types
          elementType)
  | .arrayMap sourceType resultType =>
      let withSource :=
        psWasmCollectArrayTypesFromType
          sourceType
          (psWasmInsertArrayElementType
            types
            sourceType)
      psWasmCollectArrayTypesFromType
        resultType
        (psWasmInsertArrayElementType
          withSource
          resultType)
  | .arrayFoldl elementType accumulatorType =>
      let withElement :=
        psWasmCollectArrayTypesFromType
          elementType
          (psWasmInsertArrayElementType
            types
            elementType)
      psWasmCollectArrayTypesFromType
        accumulatorType
        withElement
  | _ => types

def psWasmCollectArrayTypesFromExprWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, expression, types =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayTypesFromExprWithFuel
            fuel
            nested
            state
      match expression with
      | .literal _ => types
      | .var _ => types
      | .intrinsic operation arguments =>
          let withOperation :=
            psWasmCollectArrayTypesFromIntrinsic
              operation
              types
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withOperation
      | .lambda parameters resultType body =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                psWasmCollectArrayTypesFromType
                  parameter.type
                  state)
              types
          let withResult :=
            psWasmCollectArrayTypesFromType
              resultType
              withParameters
          collect body withResult
      | .call fn typeArguments arguments =>
          let withFn := collect fn types
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              withFn
          arguments.foldl
            (fun state argument =>
              collect argument state)
            withTypes
      | .letE _ type value body =>
          let withType :=
            psWasmCollectArrayTypesFromType
              type
              types
          let withValue := collect value withType
          collect body withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition :=
            collect condition types
          let withThen :=
            collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          fields.foldl
            (fun state field =>
              collect field.2 state)
            withTypes
      | .projection _ typeArguments target _ =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          collect target withTypes
      | .constructor _ _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          fields.foldl
            (fun state field =>
              collect field.2 state)
            withTypes
      | .matchE _ typeArguments scrutinee alternatives =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType
                  type
                  state)
              types
          let withScrutinee :=
            collect scrutinee withTypes
          alternatives.foldl
            (fun state alternative =>
              let bindings := alternative.2.1
              let body := alternative.2.2
              let withBindings :=
                bindings.foldl
                  (fun inner binding =>
                    psWasmCollectArrayTypesFromType
                      binding.type
                      inner)
                  state
              collect body withBindings)
            withScrutinee

def psWasmCollectArrayTypesFromExpr
    (expression : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromExprWithFuel
    4096
    expression
    types

def psWasmCollectModuleArrayElementTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let fromImports :=
    module.imports.foldl
      (fun state importInfo =>
        psWasmCollectArrayTypesFromType
          importInfo.type
          state)
      []
  let fromStructures :=
    module.structures.foldl
      (fun state structureInfo =>
        structureInfo.fields.foldl
          (fun inner field =>
            psWasmCollectArrayTypesFromType
              field.type
              inner)
          state)
      fromImports
  let fromInductives :=
    module.inductives.foldl
      (fun state inductiveInfo =>
        inductiveInfo.constructors.foldl
          (fun inner constructorInfo =>
            constructorInfo.fields.foldl
              (fun fieldsState field =>
                psWasmCollectArrayTypesFromType
                  field.type
                  fieldsState)
              inner)
          state)
      fromStructures
  module.declarations.foldl
    (fun state declaration =>
      let withParameters :=
        declaration.parameters.foldl
          (fun inner parameter =>
            psWasmCollectArrayTypesFromType
              parameter.type
              inner)
          state
      let withResult :=
        psWasmCollectArrayTypesFromType
          declaration.resultType
          withParameters
      psWasmCollectArrayTypesFromExpr
        declaration.body
        withResult)
    fromInductives

def psWasmLowerArrayType
    (profile : PsWasmTargetProfile)
    (elementType : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmArrayType :=
  match psWasmArrayTypeName elementType with
  | none => Except.error PsWasmLowerError.unsupportedType
  | some name =>
      match psWasmStorageTypeOfIrType? profile elementType with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some storageType =>
          Except.ok {
            name := name
            elementType := storageType
            mutable := true
          }

def psWasmLowerArrayTypes
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrType ->
    Except PsWasmLowerError (List PsWasmArrayType)
  | [] => Except.ok []
  | elementType :: rest =>
      match
          psWasmLowerArrayType
            profile
            elementType with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerArrayTypes profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

def psWasmArrayGetInstruction
    (arrayTypeName : String)
    (elementType : PsVerifiedIrType) : PsWasmInstruction :=
  match elementType with
  | .primitive .uint8 =>
      PsWasmInstruction.arrayGetU arrayTypeName
  | .primitive .uint16 =>
      PsWasmInstruction.arrayGetU arrayTypeName
  | .primitive .int8 =>
      PsWasmInstruction.arrayGetS arrayTypeName
  | .primitive .int16 =>
      PsWasmInstruction.arrayGetS arrayTypeName
  | _ =>
      PsWasmInstruction.arrayGet arrayTypeName
