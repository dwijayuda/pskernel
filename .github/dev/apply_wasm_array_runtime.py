from pathlib import Path


def replace_once(path, old, new):
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one anchor, found {count}: {old[:80]!r}")
    p.write_text(text.replace(old, new, 1))


def replace_last_once(path, old, new):
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one last anchor, found {count}: {old[:80]!r}")
    index = text.rfind(old)
    p.write_text(text[:index] + new + text[index + len(old):])


# Target IR: add only backend-local instructions needed by persistent arrays
# and exact Nat index bridging.
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Model.lean",
    "  | localSet (index : Nat)\n  | call (name : String)\n",
    "  | localSet (index : Nat)\n  | drop\n  | unreachable\n  | call (name : String)\n",
)
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Model.lean",
    "  | i32Xor\n  | i32Extend8S\n",
    "  | i32Xor\n  | i32ShrU\n  | i32Extend8S\n",
)

replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Binary.lean",
    "  | .localSet index =>\n      Except.ok (psWasmByte 33 :: psWasmEncodeUleb index)\n  | .call name =>\n",
    "  | .localSet index =>\n      Except.ok (psWasmByte 33 :: psWasmEncodeUleb index)\n  | .drop => Except.ok [psWasmByte 26]\n  | .unreachable => Except.ok [psWasmByte 0]\n  | .call name =>\n",
)
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Binary.lean",
    "  | .i32Xor => Except.ok [psWasmByte 115]\n  | .i32Extend8S => Except.ok [psWasmByte 192]\n",
    "  | .i32Xor => Except.ok [psWasmByte 115]\n  | .i32ShrU => Except.ok [psWasmByte 118]\n  | .i32Extend8S => Except.ok [psWasmByte 192]\n",
)

# Exact Nat <-> Wasm u32 bridge. Conversion to u32 is used only after a
# structural <=32-bit guard, so huge Nat indices never silently truncate.
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/RuntimeNat.lean",
    'def psWasmNatModFn : String := "__ps_wasm_nat_mod"\n',
    'def psWasmNatModFn : String := "__ps_wasm_nat_mod"\n'
    'def psWasmNatFitsBitsFn : String := "__ps_wasm_nat_fits_bits"\n'
    'def psWasmNatFitsU32Fn : String := "__ps_wasm_nat_fits_u32"\n'
    'def psWasmNatToU32Fn : String := "__ps_wasm_nat_to_u32"\n'
    'def psWasmNatOfU32Fn : String := "__ps_wasm_nat_of_u32"\n',
)

nat_bridge_functions = r''',
    {
      name := psWasmNatFitsBitsFn
      typeName := none
      parameters := [psWasmNatRef, PsWasmValueType.i32]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 1,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq,
          PsWasmInstruction.ifStart (some PsWasmValueType.i32),
            PsWasmInstruction.i32Const 0,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.i32Const 1,
            PsWasmInstruction.i32Sub,
            PsWasmInstruction.call psWasmNatFitsBitsFn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatFitsU32Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 32,
        PsWasmInstruction.call psWasmNatFitsBitsFn
      ]
    },
    {
      name := psWasmNatToU32Fn
      typeName := none
      parameters := [psWasmNatRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (some PsWasmValueType.i32),
          PsWasmInstruction.i32Const 0,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatHalfFn,
          PsWasmInstruction.call psWasmNatToU32Fn,
          PsWasmInstruction.i32Const 2,
          PsWasmInstruction.i32Mul,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatLowFn,
          PsWasmInstruction.i32Add,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatOfU32Fn
      typeName := none
      parameters := [PsWasmValueType.i32]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32ShrU,
          PsWasmInstruction.call psWasmNatOfU32Fn,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32And,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.else_,
            PsWasmInstruction.call psWasmNatMkBit0Fn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    }
'''
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/RuntimeNat.lean",
    "  ]\n\ndef psWasmNatLiteralInstructionsWithFuel :\n",
    nat_bridge_functions + "  ]\n\ndef psWasmNatLiteralInstructionsWithFuel :\n",
)

array_lower_helpers = r'''
structure PsWasmArrayLowerInfo where
  elementType : PsVerifiedIrType
  elementValueType : PsWasmValueType
  typeName : String
  refType : PsWasmValueType

def psWasmResolveArrayLowerInfo
    (profile : PsWasmTargetProfile)
    (typeArguments : List PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmArrayLowerInfo :=
  match typeArguments with
  | [elementType] =>
      match psWasmArrayTypeName elementType with
      | none => Except.error PsWasmLowerError.unsupportedType
      | some typeName =>
          match psWasmValueTypeOfIrType? profile elementType with
          | none => Except.error PsWasmLowerError.unsupportedType
          | some elementValueType =>
              Except.ok {
                elementType := elementType
                elementValueType := elementValueType
                typeName := typeName
                refType := PsWasmValueType.refT typeName
              }
  | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmArrayGetInstruction
    (typeName : String)
    (elementType : PsVerifiedIrType) : PsWasmInstruction :=
  match elementType with
  | .primitive .uint8 => PsWasmInstruction.arrayGetU typeName
  | .primitive .uint16 => PsWasmInstruction.arrayGetU typeName
  | .primitive .int8 => PsWasmInstruction.arrayGetS typeName
  | .primitive .int16 => PsWasmInstruction.arrayGetS typeName
  | _ => PsWasmInstruction.arrayGet typeName

def psWasmLowerArrayEmptyWithCapacityWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [capacity] =>
          match lower (some psWasmNatRef) state capacity with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++ [
                    PsWasmInstruction.drop,
                    PsWasmInstruction.arrayNewFixed info.typeName 0
                  ]
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArraySizeWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  lowered.instructions ++ [
                    PsWasmInstruction.arrayLen,
                    PsWasmInstruction.call psWasmNatOfU32Fn
                  ]
                state := lowered.state
              }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArrayPushWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array, value] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType
              let arrayLocal := allocatedArray.1
              match
                  lower
                    (some info.elementValueType)
                    allocatedArray.2
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  let allocatedValue :=
                    psWasmAddLocal
                      loweredValue.state
                      info.elementValueType
                  let valueLocal := allocatedValue.1
                  let allocatedOutput :=
                    psWasmAddLocal allocatedValue.2 info.refType
                  let outputLocal := allocatedOutput.1
                  Except.ok {
                    instructions :=
                      loweredArray.instructions ++ [
                        PsWasmInstruction.localSet arrayLocal
                      ] ++ loweredValue.instructions ++ [
                        PsWasmInstruction.localSet valueLocal,
                        PsWasmInstruction.localGet valueLocal,
                        PsWasmInstruction.localGet arrayLocal,
                        PsWasmInstruction.arrayLen,
                        PsWasmInstruction.i32Const 1,
                        PsWasmInstruction.i32Add,
                        PsWasmInstruction.arrayNew info.typeName,
                        PsWasmInstruction.localSet outputLocal,
                        PsWasmInstruction.localGet outputLocal,
                        PsWasmInstruction.i32Const 0,
                        PsWasmInstruction.localGet arrayLocal,
                        PsWasmInstruction.i32Const 0,
                        PsWasmInstruction.localGet arrayLocal,
                        PsWasmInstruction.arrayLen,
                        PsWasmInstruction.arrayCopy
                          info.typeName info.typeName,
                        PsWasmInstruction.localGet outputLocal
                      ]
                    state := allocatedOutput.2
                  }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArrayGetWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array, index] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType
              let arrayLocal := allocatedArray.1
              match lower (some psWasmNatRef) allocatedArray.2 index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef
                  let indexLocal := allocatedIndex.1
                  Except.ok {
                    instructions :=
                      loweredArray.instructions ++ [
                        PsWasmInstruction.localSet arrayLocal
                      ] ++ loweredIndex.instructions ++ [
                        PsWasmInstruction.localSet indexLocal,
                        PsWasmInstruction.localGet indexLocal,
                        PsWasmInstruction.call psWasmNatFitsU32Fn,
                        PsWasmInstruction.ifStart
                          (some info.elementValueType),
                          PsWasmInstruction.localGet arrayLocal,
                          PsWasmInstruction.localGet indexLocal,
                          PsWasmInstruction.call psWasmNatToU32Fn,
                          psWasmArrayGetInstruction
                            info.typeName info.elementType,
                        PsWasmInstruction.else_,
                          PsWasmInstruction.unreachable,
                        PsWasmInstruction.end_
                      ]
                    state := allocatedIndex.2
                  }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArrayGetDWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array, index, fallback] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType
              let arrayLocal := allocatedArray.1
              match lower (some psWasmNatRef) allocatedArray.2 index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef
                  let indexLocal := allocatedIndex.1
                  match
                      lower
                        (some info.elementValueType)
                        allocatedIndex.2
                        fallback with
                  | Except.error error => Except.error error
                  | Except.ok loweredFallback =>
                      let allocatedFallback :=
                        psWasmAddLocal
                          loweredFallback.state
                          info.elementValueType
                      let fallbackLocal := allocatedFallback.1
                      Except.ok {
                        instructions :=
                          loweredArray.instructions ++ [
                            PsWasmInstruction.localSet arrayLocal
                          ] ++ loweredIndex.instructions ++ [
                            PsWasmInstruction.localSet indexLocal
                          ] ++ loweredFallback.instructions ++ [
                            PsWasmInstruction.localSet fallbackLocal,
                            PsWasmInstruction.localGet indexLocal,
                            PsWasmInstruction.call psWasmNatFitsU32Fn,
                            PsWasmInstruction.ifStart
                              (some info.elementValueType),
                              PsWasmInstruction.localGet indexLocal,
                              PsWasmInstruction.call psWasmNatToU32Fn,
                              PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.arrayLen,
                              PsWasmInstruction.i32LtU,
                              PsWasmInstruction.ifStart
                                (some info.elementValueType),
                                PsWasmInstruction.localGet arrayLocal,
                                PsWasmInstruction.localGet indexLocal,
                                PsWasmInstruction.call psWasmNatToU32Fn,
                                psWasmArrayGetInstruction
                                  info.typeName info.elementType,
                              PsWasmInstruction.else_,
                                PsWasmInstruction.localGet fallbackLocal,
                              PsWasmInstruction.end_,
                            PsWasmInstruction.else_,
                              PsWasmInstruction.localGet fallbackLocal,
                            PsWasmInstruction.end_
                          ]
                        state := allocatedFallback.2
                      }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArraySetWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array, index, value] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType
              let arrayLocal := allocatedArray.1
              match lower (some psWasmNatRef) allocatedArray.2 index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef
                  let indexLocal := allocatedIndex.1
                  match
                      lower
                        (some info.elementValueType)
                        allocatedIndex.2
                        value with
                  | Except.error error => Except.error error
                  | Except.ok loweredValue =>
                      let allocatedValue :=
                        psWasmAddLocal
                          loweredValue.state
                          info.elementValueType
                      let valueLocal := allocatedValue.1
                      let allocatedOutput :=
                        psWasmAddLocal allocatedValue.2 info.refType
                      let outputLocal := allocatedOutput.1
                      Except.ok {
                        instructions :=
                          loweredArray.instructions ++ [
                            PsWasmInstruction.localSet arrayLocal
                          ] ++ loweredIndex.instructions ++ [
                            PsWasmInstruction.localSet indexLocal
                          ] ++ loweredValue.instructions ++ [
                            PsWasmInstruction.localSet valueLocal,
                            PsWasmInstruction.localGet indexLocal,
                            PsWasmInstruction.call psWasmNatFitsU32Fn,
                            PsWasmInstruction.ifStart (some info.refType),
                              PsWasmInstruction.localGet valueLocal,
                              PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.arrayLen,
                              PsWasmInstruction.arrayNew info.typeName,
                              PsWasmInstruction.localSet outputLocal,
                              PsWasmInstruction.localGet outputLocal,
                              PsWasmInstruction.i32Const 0,
                              PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.i32Const 0,
                              PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.arrayLen,
                              PsWasmInstruction.arrayCopy
                                info.typeName info.typeName,
                              PsWasmInstruction.localGet outputLocal,
                              PsWasmInstruction.localGet indexLocal,
                              PsWasmInstruction.call psWasmNatToU32Fn,
                              PsWasmInstruction.localGet valueLocal,
                              PsWasmInstruction.arraySet info.typeName,
                              PsWasmInstruction.localGet outputLocal,
                            PsWasmInstruction.else_,
                              PsWasmInstruction.unreachable,
                            PsWasmInstruction.end_
                          ]
                        state := allocatedOutput.2
                      }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerArraySetIfInBoundsWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmResolveArrayLowerInfo profile typeArguments with
  | Except.error error => Except.error error
  | Except.ok info =>
      match arguments with
      | [array, index, value] =>
          match lower (some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType
              let arrayLocal := allocatedArray.1
              match lower (some psWasmNatRef) allocatedArray.2 index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef
                  let indexLocal := allocatedIndex.1
                  match
                      lower
                        (some info.elementValueType)
                        allocatedIndex.2
                        value with
                  | Except.error error => Except.error error
                  | Except.ok loweredValue =>
                      let allocatedValue :=
                        psWasmAddLocal
                          loweredValue.state
                          info.elementValueType
                      let valueLocal := allocatedValue.1
                      let allocatedOutput :=
                        psWasmAddLocal allocatedValue.2 info.refType
                      let outputLocal := allocatedOutput.1
                      Except.ok {
                        instructions :=
                          loweredArray.instructions ++ [
                            PsWasmInstruction.localSet arrayLocal
                          ] ++ loweredIndex.instructions ++ [
                            PsWasmInstruction.localSet indexLocal
                          ] ++ loweredValue.instructions ++ [
                            PsWasmInstruction.localSet valueLocal,
                            PsWasmInstruction.localGet indexLocal,
                            PsWasmInstruction.call psWasmNatFitsU32Fn,
                            PsWasmInstruction.ifStart (some info.refType),
                              PsWasmInstruction.localGet indexLocal,
                              PsWasmInstruction.call psWasmNatToU32Fn,
                              PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.arrayLen,
                              PsWasmInstruction.i32LtU,
                              PsWasmInstruction.ifStart (some info.refType),
                                PsWasmInstruction.localGet valueLocal,
                                PsWasmInstruction.localGet arrayLocal,
                                PsWasmInstruction.arrayLen,
                                PsWasmInstruction.arrayNew info.typeName,
                                PsWasmInstruction.localSet outputLocal,
                                PsWasmInstruction.localGet outputLocal,
                                PsWasmInstruction.i32Const 0,
                                PsWasmInstruction.localGet arrayLocal,
                                PsWasmInstruction.i32Const 0,
                                PsWasmInstruction.localGet arrayLocal,
                                PsWasmInstruction.arrayLen,
                                PsWasmInstruction.arrayCopy
                                  info.typeName info.typeName,
                                PsWasmInstruction.localGet outputLocal,
                                PsWasmInstruction.localGet indexLocal,
                                PsWasmInstruction.call psWasmNatToU32Fn,
                                PsWasmInstruction.localGet valueLocal,
                                PsWasmInstruction.arraySet info.typeName,
                                PsWasmInstruction.localGet outputLocal,
                              PsWasmInstruction.else_,
                                PsWasmInstruction.localGet arrayLocal,
                              PsWasmInstruction.end_,
                            PsWasmInstruction.else_,
                              PsWasmInstruction.localGet arrayLocal,
                            PsWasmInstruction.end_
                          ]
                        state := allocatedOutput.2
                      }
      | _ => Except.error PsWasmLowerError.invalidIntrinsicArity

'''
replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "def psWasmLowerIntrinsicWith\n",
    array_lower_helpers + "def psWasmLowerIntrinsicWith\n",
)

replace_once(
    "selfhost/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean",
    "  | .intLt =>\n      psWasmLowerIntCompareWith\n        lower state PsWasmInstruction.i32LtS arguments\n  | _ => Except.error PsWasmLowerError.unsupportedIntrinsic\n",
    "  | .intLt =>\n      psWasmLowerIntCompareWith\n        lower state PsWasmInstruction.i32LtS arguments\n"
    "  | .arrayEmptyWithCapacity =>\n"
    "      psWasmLowerArrayEmptyWithCapacityWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arraySize =>\n"
    "      psWasmLowerArraySizeWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arrayPush =>\n"
    "      psWasmLowerArrayPushWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arrayGet =>\n"
    "      psWasmLowerArrayGetWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arrayGetD =>\n"
    "      psWasmLowerArrayGetDWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arraySet =>\n"
    "      psWasmLowerArraySetWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | .arraySetIfInBounds =>\n"
    "      psWasmLowerArraySetIfInBoundsWith\n"
    "        profile lower state typeArguments arguments\n"
    "  | _ => Except.error PsWasmLowerError.unsupportedIntrinsic\n",
)

smoke_helpers = r'''
def psWasmSmokeNatType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psWasmSmokeArrayType
    (elementType : PsVerifiedIrType) : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [elementType]

def psWasmSmokeNatLiteral (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural value)

def psWasmSmokeU32Literal (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.machineInteger
      PsVerifiedIrMachineIntegerType.uint32
      value)

def psWasmSmokeArrayEmpty
    (elementType : PsVerifiedIrType)
    (capacity : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
    [elementType]
    [psWasmSmokeNatLiteral capacity]

def psWasmSmokeArraySize
    (elementType : PsVerifiedIrType)
    (array : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySize
    [elementType]
    [array]

def psWasmSmokeArrayPush
    (elementType : PsVerifiedIrType)
    (array value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayPush
    [elementType]
    [array, value]

def psWasmSmokeArrayGet
    (elementType : PsVerifiedIrType)
    (array index : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayGet
    [elementType]
    [array, index]

def psWasmSmokeArrayGetD
    (elementType : PsVerifiedIrType)
    (array index fallback : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayGetD
    [elementType]
    [array, index, fallback]

def psWasmSmokeArraySet
    (elementType : PsVerifiedIrType)
    (array index value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySet
    [elementType]
    [array, index, value]

def psWasmSmokeArraySetIfInBounds
    (elementType : PsVerifiedIrType)
    (array index value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySetIfInBounds
    [elementType]
    [array, index, value]

def psWasmSmokeU32ArrayTwo : PsVerifiedIrExpr :=
  psWasmSmokeArrayPush
    psWasmSmokeU32Type
    (psWasmSmokeArrayPush
      psWasmSmokeU32Type
      (psWasmSmokeArrayEmpty psWasmSmokeU32Type 2)
      (psWasmSmokeU32Literal 20))
    (psWasmSmokeU32Literal 22)

'''
replace_once(
    "selfhost/test/WasmBinarySmoke.lean",
    "def psWasmSmokeIrModule : PsVerifiedIrModule :=\n",
    smoke_helpers + "def psWasmSmokeIrModule : PsVerifiedIrModule :=\n",
)

array_declarations = r'''
      {
        name := "arrayEmptySizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArraySize
                psWasmSmokeU32Type
                (psWasmSmokeArrayEmpty psWasmSmokeU32Type 100),
              psWasmSmokeNatLiteral 0
            ]
      },
      {
        name := "arrayPushGet"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArrayPush
              psWasmSmokeU32Type
              (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
              (psWasmSmokeU32Literal 42))
            (psWasmSmokeNatLiteral 0)
      },
      {
        name := "arrayPushSizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArraySize
                psWasmSmokeU32Type
                psWasmSmokeU32ArrayTwo,
              psWasmSmokeNatLiteral 2
            ]
      },
      {
        name := "arrayGetDInBounds"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 1)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arrayGetDOob"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 7)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arrayGetDHugeIndex"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 1208925819614629174706176)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arraySetPersistent"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "original"
            (psWasmSmokeArrayType psWasmSmokeU32Type)
            (psWasmSmokeArrayPush
              psWasmSmokeU32Type
              (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
              (psWasmSmokeU32Literal 20))
            (PsVerifiedIrExpr.letE
              "updated"
              (psWasmSmokeArrayType psWasmSmokeU32Type)
              (psWasmSmokeArraySet
                psWasmSmokeU32Type
                (PsVerifiedIrExpr.var "original")
                (psWasmSmokeNatLiteral 0)
                (psWasmSmokeU32Literal 42))
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.machineIntBinary
                  PsVerifiedIrMachineIntegerType.uint32
                  PsVerifiedIrIntegerBinaryOp.add)
                []
                [
                  psWasmSmokeArrayGet
                    psWasmSmokeU32Type
                    (PsVerifiedIrExpr.var "original")
                    (psWasmSmokeNatLiteral 0),
                  psWasmSmokeArrayGet
                    psWasmSmokeU32Type
                    (PsVerifiedIrExpr.var "updated")
                    (psWasmSmokeNatLiteral 0)
                ]))
      },
      {
        name := "arraySetIfInBoundsOob"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArraySetIfInBounds
              psWasmSmokeU32Type
              (psWasmSmokeArrayPush
                psWasmSmokeU32Type
                (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
                (psWasmSmokeU32Literal 20))
              (psWasmSmokeNatLiteral 1208925819614629174706176)
              (psWasmSmokeU32Literal 99))
            (psWasmSmokeNatLiteral 0)
      },
      {
        name := "arrayNatRoundTripExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArrayGet
                psWasmSmokeNatType
                (psWasmSmokeArrayPush
                  psWasmSmokeNatType
                  (psWasmSmokeArrayEmpty psWasmSmokeNatType 1)
                  (psWasmSmokeNatLiteral 42))
                (psWasmSmokeNatLiteral 0),
              psWasmSmokeNatLiteral 42
            ]
      }
'''
replace_last_once(
    "selfhost/test/WasmBinarySmoke.lean",
    "\n      }\n    ]\n  }\n\ndef psWasmGcArraySmokeTypeName",
    "\n      },\n" + array_declarations + "    ]\n  }\n\ndef psWasmGcArraySmokeTypeName",
)

node_assertions = r'''          if (instance.exports.arrayEmptySizeExact() !== 1) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_EMPTY_SIZE_RESULT');
          }
          if (instance.exports.arrayPushGet() !== 42) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_PUSH_GET_RESULT');
          }
          if (instance.exports.arrayPushSizeExact() !== 1) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_PUSH_SIZE_RESULT');
          }
          if (instance.exports.arrayGetDInBounds() !== 22) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_GETD_IN_BOUNDS_RESULT');
          }
          if (instance.exports.arrayGetDOob() !== 99) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_GETD_OOB_RESULT');
          }
          if (instance.exports.arrayGetDHugeIndex() !== 99) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_GETD_HUGE_INDEX_RESULT');
          }
          if (instance.exports.arraySetPersistent() !== 62) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_SET_PERSISTENT_RESULT');
          }
          if (instance.exports.arraySetIfInBoundsOob() !== 20) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_SET_IF_OOB_RESULT');
          }
          if (instance.exports.arrayNatRoundTripExact() !== 1) {
            throw new Error('PSC1_WASM_RUNTIME_ARRAY_NAT_ROUNDTRIP_RESULT');
          }
'''
for workflow in [
    ".github/workflows/wasm3-backend.yml",
    ".github/workflows/psc1-lean-bootstrap.yml",
]:
    replace_once(
        workflow,
        "          console.log('PSC1_BACKEND_WASM_NODE_RUNTIME: PASS');\n",
        node_assertions + "          console.log('PSC1_BACKEND_WASM_NODE_RUNTIME: PASS');\n",
    )

print("WASM_ARRAY_RUNTIME_PATCH: APPLIED")
