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
