import Ps.BackendWasm.Type
import Ps.BackendWasm.RuntimeNat

structure PsWasmArrayRuntime where
  structures : List PsWasmStructType
  functions : List PsWasmFunction

def psWasmArraySizeFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".size")

def psWasmArrayPushFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".push")

def psWasmArrayGetFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".get")

def psWasmArrayGetDFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".getD")

def psWasmArraySetFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".set")

def psWasmArraySetIfFunctionName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName => some (baseName ++ ".setIfInBounds")

def psWasmArrayHeadGet
    (consName : String)
    (elementType : PsVerifiedIrType) :
    PsWasmInstruction :=
  match elementType with
  | .primitive .uint8 => .structGetU consName 0
  | .primitive .uint16 => .structGetU consName 0
  | .primitive .int8 => .structGetS consName 0
  | .primitive .int16 => .structGetS consName 0
  | _ => .structGet consName 0

def psWasmBuildArrayRuntime
    (profile : PsWasmTargetProfile)
    (elementType : PsVerifiedIrType) :
    Option PsWasmArrayRuntime :=
  match psWasmArrayBaseName elementType with
  | none => none
  | some baseName =>
      match psWasmArrayNilName elementType with
      | none => none
      | some nilName =>
          match psWasmArrayConsName elementType with
          | none => none
          | some consName =>
              match psWasmValueTypeOfIrType? profile elementType with
              | none => none
              | some elementValueType =>
                  match psWasmStorageTypeOfIrType? profile elementType with
                  | none => none
                  | some elementStorageType =>
                      match psWasmArraySizeFunctionName elementType with
                      | none => none
                      | some sizeName =>
                          match psWasmArrayPushFunctionName elementType with
                          | none => none
                          | some pushName =>
                              match psWasmArrayGetFunctionName elementType with
                              | none => none
                              | some getName =>
                                  match psWasmArrayGetDFunctionName elementType with
                                  | none => none
                                  | some getDName =>
                                      match psWasmArraySetFunctionName elementType with
                                      | none => none
                                      | some setName =>
                                          match psWasmArraySetIfFunctionName elementType with
                                          | none => none
                                          | some setIfName =>
                                              let arrayRef :=
                                                PsWasmValueType.refT baseName
                                              let structures : List PsWasmStructType := [
                                                {
                                                  name := baseName
                                                  superType := none
                                                  isFinal := false
                                                  fields := []
                                                },
                                                {
                                                  name := nilName
                                                  superType := some baseName
                                                  isFinal := true
                                                  fields := []
                                                },
                                                {
                                                  name := consName
                                                  superType := some baseName
                                                  isFinal := true
                                                  fields := [
                                                    {
                                                      name := "head"
                                                      storageType := elementStorageType
                                                    },
                                                    {
                                                      name := "tail"
                                                      storageType :=
                                                        PsWasmStorageType.value arrayRef
                                                    }
                                                  ]
                                                }
                                              ]
                                              let sizeFunction : PsWasmFunction := {
                                                name := sizeName
                                                typeName := none
                                                parameters := [arrayRef]
                                                results := [psWasmNatRef]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some psWasmNatRef),
                                                    .localGet 0,
                                                    .refCast consName,
                                                    .structGet consName 1,
                                                    .call sizeName,
                                                    .structNew psWasmNatSuccName,
                                                  .else_,
                                                    .structNew psWasmNatZeroName,
                                                  .end_
                                                ]
                                              }
                                              let pushFunction : PsWasmFunction := {
                                                name := pushName
                                                typeName := none
                                                parameters := [arrayRef, elementValueType]
                                                results := [arrayRef]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some arrayRef),
                                                    .localGet 0,
                                                    .refCast consName,
                                                    psWasmArrayHeadGet consName elementType,
                                                    .localGet 0,
                                                    .refCast consName,
                                                    .structGet consName 1,
                                                    .localGet 1,
                                                    .call pushName,
                                                    .structNew consName,
                                                  .else_,
                                                    .localGet 1,
                                                    .structNew nilName,
                                                    .structNew consName,
                                                  .end_
                                                ]
                                              }
                                              let getDFunction : PsWasmFunction := {
                                                name := getDName
                                                typeName := none
                                                parameters := [
                                                  arrayRef,
                                                  psWasmNatRef,
                                                  elementValueType
                                                ]
                                                results := [elementValueType]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some elementValueType),
                                                    .localGet 1,
                                                    .refTest psWasmNatSuccName,
                                                    .ifStart (some elementValueType),
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .localGet 1,
                                                      .refCast psWasmNatSuccName,
                                                      .structGet psWasmNatSuccName 0,
                                                      .localGet 2,
                                                      .call getDName,
                                                    .else_,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      psWasmArrayHeadGet consName elementType,
                                                    .end_,
                                                  .else_,
                                                    .localGet 2,
                                                  .end_
                                                ]
                                              }
                                              let getFunction : PsWasmFunction := {
                                                name := getName
                                                typeName := none
                                                parameters := [arrayRef, psWasmNatRef]
                                                results := [elementValueType]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some elementValueType),
                                                    .localGet 1,
                                                    .refTest psWasmNatSuccName,
                                                    .ifStart (some elementValueType),
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .localGet 1,
                                                      .refCast psWasmNatSuccName,
                                                      .structGet psWasmNatSuccName 0,
                                                      .call getName,
                                                    .else_,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      psWasmArrayHeadGet consName elementType,
                                                    .end_,
                                                  .else_,
                                                    .unreachable,
                                                  .end_
                                                ]
                                              }
                                              let setIfFunction : PsWasmFunction := {
                                                name := setIfName
                                                typeName := none
                                                parameters := [
                                                  arrayRef,
                                                  psWasmNatRef,
                                                  elementValueType
                                                ]
                                                results := [arrayRef]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some arrayRef),
                                                    .localGet 1,
                                                    .refTest psWasmNatSuccName,
                                                    .ifStart (some arrayRef),
                                                      .localGet 0,
                                                      .refCast consName,
                                                      psWasmArrayHeadGet consName elementType,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .localGet 1,
                                                      .refCast psWasmNatSuccName,
                                                      .structGet psWasmNatSuccName 0,
                                                      .localGet 2,
                                                      .call setIfName,
                                                      .structNew consName,
                                                    .else_,
                                                      .localGet 2,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .structNew consName,
                                                    .end_,
                                                  .else_,
                                                    .localGet 0,
                                                  .end_
                                                ]
                                              }
                                              let setFunction : PsWasmFunction := {
                                                name := setName
                                                typeName := none
                                                parameters := [
                                                  arrayRef,
                                                  psWasmNatRef,
                                                  elementValueType
                                                ]
                                                results := [arrayRef]
                                                locals := []
                                                body := [
                                                  .localGet 0,
                                                  .refTest consName,
                                                  .ifStart (some arrayRef),
                                                    .localGet 1,
                                                    .refTest psWasmNatSuccName,
                                                    .ifStart (some arrayRef),
                                                      .localGet 0,
                                                      .refCast consName,
                                                      psWasmArrayHeadGet consName elementType,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .localGet 1,
                                                      .refCast psWasmNatSuccName,
                                                      .structGet psWasmNatSuccName 0,
                                                      .localGet 2,
                                                      .call setName,
                                                      .structNew consName,
                                                    .else_,
                                                      .localGet 2,
                                                      .localGet 0,
                                                      .refCast consName,
                                                      .structGet consName 1,
                                                      .structNew consName,
                                                    .end_,
                                                  .else_,
                                                    .unreachable,
                                                  .end_
                                                ]
                                              }
                                              some {
                                                structures := structures
                                                functions := [
                                                  sizeFunction,
                                                  pushFunction,
                                                  getFunction,
                                                  getDFunction,
                                                  setFunction,
                                                  setIfFunction
                                                ]
                                              }


def psWasmArrayElementTypesContain
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | none => false
  | some candidateKey =>
      types.any
        (fun existing =>
          match psWasmIrTypeKey existing with
          | none => false
          | some key => key == candidateKey)

def psWasmInsertArrayElementType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  if psWasmArrayElementTypesContain types candidate then
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
      match type with
      | .named "Array" [elementType] =>
          psWasmCollectArrayTypesFromTypeWithFuel
            fuel
            elementType
            (psWasmInsertArrayElementType types elementType)
      | .named _ arguments =>
          arguments.foldl
            (fun state argument =>
              psWasmCollectArrayTypesFromTypeWithFuel
                fuel argument state)
            types
      | .function parameters result =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                psWasmCollectArrayTypesFromTypeWithFuel
                  fuel parameter state)
              types
          psWasmCollectArrayTypesFromTypeWithFuel
            fuel result withParameters
      | _ => types

def psWasmCollectArrayTypesFromType
    (type : PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromTypeWithFuel 64 type types

def psWasmCollectArrayTypesFromIntrinsic
    (operation : PsVerifiedIrIntrinsic)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match operation with
  | .arrayEmptyWithCapacity elementType =>
      psWasmInsertArrayElementType types elementType
  | .arraySize elementType =>
      psWasmInsertArrayElementType types elementType
  | .arrayPush elementType =>
      psWasmInsertArrayElementType types elementType
  | .arrayGet elementType =>
      psWasmInsertArrayElementType types elementType
  | .arrayGetD elementType =>
      psWasmInsertArrayElementType types elementType
  | .arraySet elementType =>
      psWasmInsertArrayElementType types elementType
  | .arraySetIfInBounds elementType =>
      psWasmInsertArrayElementType types elementType
  | .arrayMap sourceType targetType =>
      psWasmInsertArrayElementType
        (psWasmInsertArrayElementType types sourceType)
        targetType
  | .arrayFoldl elementType accumulatorType =>
      psWasmCollectArrayTypesFromType
        accumulatorType
        (psWasmInsertArrayElementType types elementType)
  | _ => types

def psWasmCollectArrayTypesFromExprWithFuel :
    Nat ->
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType
  | 0, _, types => types
  | fuel + 1, expr, types =>
      let collect :=
        fun nested state =>
          psWasmCollectArrayTypesFromExprWithFuel
            fuel nested state
      match expr with
      | .literal _ => types
      | .var _ => types
      | .intrinsic operation arguments =>
          arguments.foldl
            (fun state argument => collect argument state)
            (psWasmCollectArrayTypesFromIntrinsic operation types)
      | .lambda parameters resultType body =>
          let withParameters :=
            parameters.foldl
              (fun state parameter =>
                psWasmCollectArrayTypesFromType
                  parameter.type state)
              types
          let withResult :=
            psWasmCollectArrayTypesFromType
              resultType withParameters
          collect body withResult
      | .call fn typeArguments arguments =>
          let withFn := collect fn types
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              withFn
          arguments.foldl
            (fun state argument => collect argument state)
            withTypes
      | .letE _ type value body =>
          let withType :=
            psWasmCollectArrayTypesFromType type types
          let withValue := collect value withType
          collect body withValue
      | .ifE condition thenBranch elseBranch =>
          let withCondition := collect condition types
          let withThen := collect thenBranch withCondition
          collect elseBranch withThen
      | .record _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          fields.foldl
            (fun state field => collect field.2 state)
            withTypes
      | .projection _ typeArguments target _ =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          collect target withTypes
      | .constructor _ _ typeArguments fields =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          fields.foldl
            (fun state field => collect field.2 state)
            withTypes
      | .matchE _ typeArguments scrutinee alternatives =>
          let withTypes :=
            typeArguments.foldl
              (fun state type =>
                psWasmCollectArrayTypesFromType type state)
              types
          let withScrutinee := collect scrutinee withTypes
          alternatives.foldl
            (fun state alternative =>
              let withBindings :=
                alternative.2.1.foldl
                  (fun inner binding =>
                    psWasmCollectArrayTypesFromType
                      binding.type inner)
                  state
              collect alternative.2.2 withBindings)
            withScrutinee

def psWasmCollectModuleArrayElementTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let fromImports :=
    module.imports.foldl
      (fun state importInfo =>
        psWasmCollectArrayTypesFromType
          importInfo.type state)
      []
  let fromStructures :=
    module.structures.foldl
      (fun state structureInfo =>
        structureInfo.fields.foldl
          (fun inner field =>
            psWasmCollectArrayTypesFromType
              field.type inner)
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
                  field.type fieldsState)
              inner)
          state)
      fromStructures
  module.declarations.foldl
    (fun state declaration =>
      let withParameters :=
        declaration.parameters.foldl
          (fun inner parameter =>
            psWasmCollectArrayTypesFromType
              parameter.type inner)
          state
      let withResult :=
        psWasmCollectArrayTypesFromType
          declaration.resultType
          withParameters
      psWasmCollectArrayTypesFromExprWithFuel
        4096
        declaration.body
        withResult)
    fromInductives

def psWasmBuildArrayRuntimes
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrType ->
    Option PsWasmArrayRuntime
  | [] =>
      some {
        structures := []
        functions := []
      }
  | elementType :: rest =>
      match psWasmBuildArrayRuntime profile elementType with
      | none => none
      | some runtime =>
          match psWasmBuildArrayRuntimes profile rest with
          | none => none
          | some runtimeRest =>
              some {
                structures :=
                  runtime.structures ++ runtimeRest.structures
                functions :=
                  runtime.functions ++ runtimeRest.functions
              }
