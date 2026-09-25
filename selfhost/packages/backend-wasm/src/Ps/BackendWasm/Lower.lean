import Ps.BackendWasm.Binary
import Ps.BackendWasm.LowerInt
import Ps.BackendWasm.LowerFloat

inductive PsWasmLowerError where
  | unsupportedType
  | unsupportedExpression
  | unsupportedIntrinsic
  | invalidIntrinsicArity
  | unknownVariable (name : String)
  | unsupportedModuleFeature

structure PsWasmLowerState where
  nextLocalIndex : Nat
  localTypes : List PsWasmValueType

structure PsWasmLoweredExpr where
  instructions : List PsWasmInstruction
  state : PsWasmLowerState

def psWasmLowerParameterType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmValueType :=
  match type with
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => Except.error PsWasmLowerError.unsupportedType
      | .refT _ => Except.error PsWasmLowerError.unsupportedType
      | valueType => Except.ok valueType
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmLowerResultType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match type with
  | .primitive .unit => Except.ok []
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => Except.ok []
      | .refT _ => Except.error PsWasmLowerError.unsupportedType
      | valueType => Except.ok [valueType]
  | _ => Except.error PsWasmLowerError.unsupportedType

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

def psWasmParameterBindingsLoop :
    Nat -> List PsVerifiedIrParameter -> List (String × Nat)
  | _, [] => []
  | index, parameter :: rest =>
      (parameter.name, index) ::
        psWasmParameterBindingsLoop (index + 1) rest

def psWasmParameterBindings
    (parameters : List PsVerifiedIrParameter) :
    List (String × Nat) :=
  psWasmParameterBindingsLoop 0 parameters

def psWasmFindBindingIndex :
    List (String × Nat) -> String -> Option Nat
  | [], _ => none
  | binding :: rest, name =>
      if binding.1 == name then
        some binding.2
      else
        psWasmFindBindingIndex rest name

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
    }
  )

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

def psWasmLowerCallWith
    (bindings : List (String × Nat))
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
      match psWasmFindBindingIndex bindings name with
      | some _ =>
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

def psWasmLowerExprWithFuel
    (profile : PsWasmTargetProfile)
    (bindings : List (String × Nat))
    (expected : Option PsWasmValueType) :
    Nat ->
    PsWasmLowerState ->
    PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr
  | 0, _, _ =>
      Except.error PsWasmLowerError.unsupportedExpression
  | fuel + 1, state, expr =>
      let lower :=
        fun expectedType nestedState nestedExpr =>
          psWasmLowerExprWithFuel
            profile bindings expectedType fuel nestedState nestedExpr
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
      | .intrinsic operation arguments =>
          psWasmLowerIntrinsicWith
            profile lower state operation arguments
      | .call fn _ arguments =>
          psWasmLowerCallWith
            bindings lower state fn arguments
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
                    (name, localIndex) :: bindings
                  match
                      psWasmLowerExprWithFuel
                        profile
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
      | .ifE condition thenBranch elseBranch =>
          psWasmLowerIfWith
            lower state expected condition thenBranch elseBranch
      | _ =>
          Except.error PsWasmLowerError.unsupportedExpression

def psWasmLowerExpr
    (profile : PsWasmTargetProfile)
    (bindings : List (String × Nat))
    (expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprWithFuel
    profile bindings expected 4096 state expr

def psWasmLowerDeclaration
    (profile : PsWasmTargetProfile)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsWasmLowerError PsWasmFunction :=
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
              }
              match
                  psWasmLowerExpr
                    profile
                    bindings
                    expected
                    initialState
                    declaration.body with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    name := declaration.name
                    parameters := parameters
                    results := results
                    locals := lowered.state.localTypes
                    body := lowered.instructions
                  }

def psWasmLowerDeclarations
    (profile : PsWasmTargetProfile) :
    List PsVerifiedIrDeclaration ->
    Except PsWasmLowerError (List PsWasmFunction)
  | [] => Except.ok []
  | declaration :: rest =>
      match psWasmLowerDeclaration profile declaration with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerDeclarations profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (lowered :: loweredRest)

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
  | [] =>
      match module.structures with
      | _ :: _ => true
      | [] =>
          match module.inductives with
          | _ :: _ => true
          | [] => false

def psWasmLowerModule
    (profile : PsWasmTargetProfile)
    (module : PsVerifiedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  if psWasmModuleHasUnsupportedData module then
    Except.error PsWasmLowerError.unsupportedModuleFeature
  else
    match psWasmLowerDeclarations profile module.declarations with
    | Except.error error => Except.error error
    | Except.ok functions =>
        Except.ok {
          functions := functions
          exports := psWasmExportsOfDeclarations module.declarations
        }
