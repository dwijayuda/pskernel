import Ps.BackendWasm.TailCalls
import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Validate
import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.BackendWasm.LowerInt
import Ps.BackendWasm.LowerFloat
import Ps.BackendWasm.RuntimeNat
import Ps.BackendWasm.RuntimeInt
import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.RuntimeIntRepr

inductive PsWasmLowerError where
  | unsupportedType
  | unsupportedTypeContext (context : String)
  | unsupportedExpression
  | unsupportedExpressionContext
      (context : String)
      (reason : String)
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
  | specializationFailed (error : PsIrSpecializeError)

def psWasmContextualizeUnsupportedType
    (context : String)
    (error : PsWasmLowerError) : PsWasmLowerError :=
  match error with
  | PsWasmLowerError.unsupportedType =>
      PsWasmLowerError.unsupportedTypeContext context
  | _ => error

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
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some valueType => Except.ok valueType

def psWasmLowerResultType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match type with
  | .primitive primitive =>
      match primitive with
      | .unit => Except.ok []
      | _ =>
          match psWasmValueTypeOfIrType? profile type with
          | Option.none => Except.error PsWasmLowerError.unsupportedType
          | Option.some valueType => Except.ok [valueType]
  | _ =>
      match psWasmValueTypeOfIrType? profile type with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some valueType => Except.ok [valueType]

-- Every source expression yields one runtime value. Only the function ABI
-- erases Unit results. Keep the conversion here instead of teaching individual
-- conditionals, matches and storage forms conflicting Unit representations.
def psWasmUnitType (type : PsVerifiedIrType) : Bool :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match primitive with
      | PsVerifiedIrPrimitiveType.unit => true
      | _ => false
  | _ => false

def psWasmCallValueInstructions (type : PsVerifiedIrType)
    (call : PsWasmInstruction) : List PsWasmInstruction :=
  if psWasmUnitType type then
    List.cons call (List.cons (PsWasmInstruction.i32Const 0) List.nil)
  else
    List.cons call List.nil

def psWasmFunctionBodyExpected (type : PsVerifiedIrType)
    (expected : Option PsWasmValueType) : Option PsWasmValueType :=
  if psWasmUnitType type then Option.some PsWasmValueType.i32 else expected

def psWasmFunctionBodyResult (type : PsVerifiedIrType)
    (body : List PsWasmInstruction) : List PsWasmInstruction :=
  if psWasmUnitType type then psWasmDiscardUnit body else body

def psWasmLowerParameterTypes
    (profile : PsWasmTargetProfile)
    (parameters : List PsVerifiedIrParameter) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match parameters with
  | List.nil => Except.ok []
  | List.cons parameter rest =>
      match psWasmLowerParameterType profile parameter.type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerParameterTypes profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psWasmExpectedResultType :
    List PsWasmValueType ->
    Except PsWasmLowerError (Option PsWasmValueType)
  | [] => Except.ok Option.none
  | result :: rest =>
      match rest with
      | [] => Except.ok (Option.some result)
      | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmMachineIntegerValueType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType) :
    PsWasmValueType :=
  if psWasmMachineIntegerIs64 profile type then
    PsWasmValueType.i64
  else
    PsWasmValueType.i32

def psWasmFloatingValueType
    (type : PsVerifiedIrFloatingType) :
    PsWasmValueType :=
  match type with
  | .float32 => PsWasmValueType.f32
  | .float => PsWasmValueType.f64


def psWasmListFoldlWorker {Value State : Type}
    (step : State -> Value -> State)
    (values : List Value) :
    State -> State :=
  match values with
  | List.nil =>
      fun (state : State) => state
  | List.cons value rest =>
      let smaller : State -> State :=
        psWasmListFoldlWorker step rest;
      fun (state : State) =>
        smaller (step state value)

def psWasmListFoldl {Value State : Type}
    (step : State -> Value -> State)
    (values : List Value)
    (state : State) : State :=
  psWasmListFoldlWorker step values state

def psWasmListPair? {Value : Type}
    (values : List Value) :
    Option (Value × Value) :=
  match values with
  | List.nil => Option.none
  | List.cons first rest =>
      match rest with
      | List.nil => Option.none
      | List.cons second tail =>
          match tail with
          | List.nil =>
              Option.some (Prod.mk first second)
          | List.cons _ _ => Option.none

def psWasmListTriple? {Value : Type}
    (values : List Value) :
    Option (Value × Value × Value) :=
  match values with
  | List.nil => Option.none
  | List.cons first rest =>
      match rest with
      | List.nil => Option.none
      | List.cons second tail =>
          match tail with
          | List.nil => Option.none
          | List.cons third final =>
              match final with
              | List.nil =>
                  Option.some
                    (Prod.mk
                      first
                      (Prod.mk second third))
              | List.cons _ _ => Option.none

def psWasmFunctionTypeListContains
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | Option.none => false
  | Option.some candidateKey =>
      let predicate :
          PsVerifiedIrType -> Bool :=
        fun (existing : PsVerifiedIrType) =>
          match psWasmIrTypeKey existing with
          | Option.none => false
          | Option.some existingKey => psStringEq existingKey candidateKey;
      psListAny predicate types

def psWasmInsertFunctionType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match candidate with
  | .function _ _ =>
      if psWasmFunctionTypeListContains types candidate then
        types
      else
        psListAppend types (List.cons candidate List.nil)
  | _ => types

def psWasmCollectFunctionTypesFromTypeWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          types
  | fuel + 1 =>
      let smaller :
          PsVerifiedIrType ->
          List PsVerifiedIrType ->
          List PsVerifiedIrType :=
        psWasmCollectFunctionTypesFromTypeWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          match type with
          | .function parameters result =>
              let withSelf :=
                psWasmInsertFunctionType types type;
              let collectParameter :
                  List PsVerifiedIrType ->
                  PsVerifiedIrType ->
                  List PsVerifiedIrType :=
                fun
                  (state : List PsVerifiedIrType)
                  (parameter : PsVerifiedIrType) =>
                  smaller parameter state;
              let withParameters :=
                psWasmListFoldl
                  collectParameter
                  parameters
                  withSelf;
              smaller result withParameters
          | .named _ arguments =>
              let collectArgument :
                  List PsVerifiedIrType ->
                  PsVerifiedIrType ->
                  List PsVerifiedIrType :=
                fun
                  (state : List PsVerifiedIrType)
                  (argument : PsVerifiedIrType) =>
                  smaller argument state;
              psWasmListFoldl
                collectArgument
                arguments
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
  let collectParameter :
      List PsVerifiedIrType ->
      PsVerifiedIrParameter ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (parameter : PsVerifiedIrParameter) =>
      psWasmCollectFunctionTypesFromType
        parameter.type
        state;
  psWasmListFoldl
    collectParameter
    parameters
    types

def psWasmParameterTypes
    (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrType :=
  let parameterType :
      PsVerifiedIrParameter -> PsVerifiedIrType :=
    fun (parameter : PsVerifiedIrParameter) =>
      parameter.type;
  psListMap parameterType parameters

def psWasmCollectFunctionTypesFromExprWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          types
  | fuel + 1 =>
      let smaller :
          PsVerifiedIrExpr ->
          List PsVerifiedIrType ->
          List PsVerifiedIrType :=
        psWasmCollectFunctionTypesFromExprWithFuel fuel;
      fun (expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          let collect :
              PsVerifiedIrExpr ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            fun
              (expression : PsVerifiedIrExpr)
              (state : List PsVerifiedIrType) =>
              smaller expression state;
          let collectType :
              List PsVerifiedIrType ->
              PsVerifiedIrType ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (type : PsVerifiedIrType) =>
              psWasmCollectFunctionTypesFromType
                type
                state;
          let collectArgument :
              List PsVerifiedIrType ->
              PsVerifiedIrExpr ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (argument : PsVerifiedIrExpr) =>
              collect argument state;
          let collectField :
              List PsVerifiedIrType ->
              (String × PsVerifiedIrExpr) ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (field : String × PsVerifiedIrExpr) =>
              collect (Prod.snd field) state;
          match expr with
          | .literal _ => types
          | .var _ => types
          | .intrinsic operation typeArguments arguments =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              let withIntrinsicFunction : List PsVerifiedIrType :=
                match operation with
                | PsVerifiedIrIntrinsic.arrayMap =>
                    match typeArguments with
                    | List.cons inputType rest =>
                        match rest with
                        | List.cons outputType tail =>
                            match tail with
                            | List.nil =>
                                psWasmInsertFunctionType
                                  withTypes
                                  (PsVerifiedIrType.function
                                    (List.cons inputType List.nil)
                                    outputType)
                            | List.cons _ _ => withTypes
                        | List.nil => withTypes
                    | List.nil => withTypes
                | PsVerifiedIrIntrinsic.arrayFoldl =>
                    match typeArguments with
                    | List.cons elementType rest =>
                        match rest with
                        | List.cons accumulatorType tail =>
                            match tail with
                            | List.nil =>
                                psWasmInsertFunctionType
                                  withTypes
                                  (PsVerifiedIrType.function
                                    (List.cons
                                      accumulatorType
                                      (List.cons
                                        elementType
                                        List.nil))
                                    accumulatorType)
                            | List.cons _ _ => withTypes
                        | List.nil => withTypes
                    | List.nil => withTypes
                | _ => withTypes;
              psWasmListFoldl
                collectArgument
                arguments
                withIntrinsicFunction
          | .lambda parameters resultType body =>
              let withParameters :=
                psWasmCollectFunctionTypesFromParameters
                  parameters
                  types;
              let functionType :=
                PsVerifiedIrType.function
                  (psWasmParameterTypes parameters)
                  resultType;
              let withFunction :=
                psWasmInsertFunctionType
                  withParameters
                  functionType;
              let withResult :=
                psWasmCollectFunctionTypesFromType
                  resultType
                  withFunction;
              collect body withResult
          | .call fn typeArguments arguments =>
              let withFn := collect fn types;
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  withFn;
              psWasmListFoldl
                collectArgument
                arguments
                withTypes
          | .letE _ type value body =>
              let withType :=
                psWasmCollectFunctionTypesFromType type types;
              let withValue := collect value withType;
              collect body withValue
          | .ifE condition thenBranch elseBranch =>
              let withCondition := collect condition types;
              let withThen := collect thenBranch withCondition;
              collect elseBranch withThen
          | .record _ _ fields =>
              psWasmListFoldl
                collectField
                fields
                types
          | .projection _ _ target _ =>
              collect target types
          | .constructor _ _ typeArguments fields =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              psWasmListFoldl
                collectField
                fields
                withTypes
          | .matchE _ _ scrutinee alternatives =>
              let withScrutinee := collect scrutinee types;
              let collectAlternative :
                  List PsVerifiedIrType ->
                  (String ×
                    List PsVerifiedIrMatchBinding ×
                    PsVerifiedIrExpr) ->
                  List PsVerifiedIrType :=
                fun
                  (state : List PsVerifiedIrType)
                  (alternative :
                    String ×
                      List PsVerifiedIrMatchBinding ×
                      PsVerifiedIrExpr) =>
                  let bindings :=
                    Prod.fst (Prod.snd alternative);
                  let body :=
                    Prod.snd (Prod.snd alternative);
                  let collectBinding :
                      List PsVerifiedIrType ->
                      PsVerifiedIrMatchBinding ->
                      List PsVerifiedIrType :=
                    fun
                      (inner : List PsVerifiedIrType)
                      (binding : PsVerifiedIrMatchBinding) =>
                      psWasmCollectFunctionTypesFromType
                        binding.type
                        inner;
                  let withBindings :=
                    psWasmListFoldl
                      collectBinding
                      bindings
                      state;
                  collect body withBindings;
              psWasmListFoldl
                collectAlternative
                alternatives
                withScrutinee

def psWasmCollectFunctionTypesFromExpr
    (expr : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectFunctionTypesFromExprWithFuel 4096 expr types

def psWasmCollectFunctionTypesFromStructureFields
    (fields : List PsVerifiedIrStructureField)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectField :
      List PsVerifiedIrType ->
      PsVerifiedIrStructureField ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (field : PsVerifiedIrStructureField) =>
      psWasmCollectFunctionTypesFromType
        field.type
        state;
  psWasmListFoldl collectField fields types

def psWasmCollectFunctionTypesFromConstructorFields
    (fields : List PsVerifiedIrConstructorField)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectField :
      List PsVerifiedIrType ->
      PsVerifiedIrConstructorField ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (field : PsVerifiedIrConstructorField) =>
      psWasmCollectFunctionTypesFromType
        field.type
        state;
  psWasmListFoldl collectField fields types

def psWasmCollectFunctionTypesFromConstructors
    (constructors : List PsVerifiedIrConstructor)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectConstructor :
      List PsVerifiedIrType ->
      PsVerifiedIrConstructor ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (constructorInfo : PsVerifiedIrConstructor) =>
      psWasmCollectFunctionTypesFromConstructorFields
        constructorInfo.fields
        state;
  psWasmListFoldl
    collectConstructor
    constructors
    types

def psWasmCollectModuleFunctionTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let collectStructure :
      List PsVerifiedIrType ->
      PsVerifiedIrStructure ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (structureInfo : PsVerifiedIrStructure) =>
      psWasmCollectFunctionTypesFromStructureFields
        structureInfo.fields
        state;
  let fromStructures :=
    psWasmListFoldl
      collectStructure
      module.structures
      List.nil;
  let collectInductive :
      List PsVerifiedIrType ->
      PsVerifiedIrInductive ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (inductiveInfo : PsVerifiedIrInductive) =>
      psWasmCollectFunctionTypesFromConstructors
        inductiveInfo.constructors
        state;
  let fromInductives :=
    psWasmListFoldl
      collectInductive
      module.inductives
      fromStructures;
  let collectDeclaration :
      List PsVerifiedIrType ->
      PsVerifiedIrDeclaration ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (declaration : PsVerifiedIrDeclaration) =>
      let withParameters :=
        psWasmCollectFunctionTypesFromParameters
          declaration.parameters
          state;
      let withResult :=
        psWasmCollectFunctionTypesFromType
          declaration.resultType
          withParameters;
      psWasmCollectFunctionTypesFromExpr
        declaration.body
        withResult;
  psWasmListFoldl
    collectDeclaration
    module.declarations
    fromInductives

def psWasmArrayTypeListContains
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) : Bool :=
  match psWasmIrTypeKey candidate with
  | Option.none => false
  | Option.some candidateKey =>
      let predicate :
          PsVerifiedIrType -> Bool :=
        fun (existing : PsVerifiedIrType) =>
          match psWasmIrTypeKey existing with
          | Option.none => false
          | Option.some existingKey => psStringEq existingKey candidateKey;
      psListAny predicate types

def psWasmInsertArrayType
    (types : List PsVerifiedIrType)
    (candidate : PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match candidate with
  | .named name arguments =>
      if psStringEq name "Array" then
        match arguments with
        | List.nil => types
        | List.cons _ rest =>
            match rest with
            | List.nil =>
                if psWasmArrayTypeListContains types candidate then
                  types
                else
                  psListAppend
                    types
                    (List.cons candidate List.nil)
            | List.cons _ _ => types
      else
        types
  | _ => types

def psWasmCollectArrayTypesFromTypeWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          types
  | fuel + 1 =>
      let smaller :
          PsVerifiedIrType ->
          List PsVerifiedIrType ->
          List PsVerifiedIrType :=
        psWasmCollectArrayTypesFromTypeWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          match type with
          | .function parameters result =>
              let collectParameter :
                  List PsVerifiedIrType ->
                  PsVerifiedIrType ->
                  List PsVerifiedIrType :=
                fun
                  (state : List PsVerifiedIrType)
                  (parameter : PsVerifiedIrType) =>
                  smaller parameter state;
              let withParameters :=
                psWasmListFoldl
                  collectParameter
                  parameters
                  types;
              smaller result withParameters
          | .named name arguments =>
              if psStringEq name "Array" then
                match arguments with
                | List.nil => types
                | List.cons elementType rest =>
                    match rest with
                    | List.nil =>
                        let withSelf :=
                          psWasmInsertArrayType
                            types
                            type;
                        smaller elementType withSelf
                    | List.cons _ _ =>
                        let collectArgument :
                            List PsVerifiedIrType ->
                            PsVerifiedIrType ->
                            List PsVerifiedIrType :=
                          fun
                            (state : List PsVerifiedIrType)
                            (argument : PsVerifiedIrType) =>
                            smaller argument state;
                        psWasmListFoldl
                          collectArgument
                          arguments
                          types
              else
                let collectArgument :
                    List PsVerifiedIrType ->
                    PsVerifiedIrType ->
                    List PsVerifiedIrType :=
                  fun
                    (state : List PsVerifiedIrType)
                    (argument : PsVerifiedIrType) =>
                    smaller argument state;
                psWasmListFoldl
                  collectArgument
                  arguments
                  types
          | _ => types

def psWasmCollectArrayTypesFromType
    (type : PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromTypeWithFuel 64 type types

def psWasmCollectArrayTypesFromParameters
    (parameters : List PsVerifiedIrParameter)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectParameter :
      List PsVerifiedIrType ->
      PsVerifiedIrParameter ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (parameter : PsVerifiedIrParameter) =>
      psWasmCollectArrayTypesFromType
        parameter.type
        state;
  psWasmListFoldl
    collectParameter
    parameters
    types

def psWasmAddSingleArrayTypeArgument
    (typeArguments : List PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match typeArguments with
  | List.cons elementType rest =>
      match rest with
      | List.nil =>
          psWasmInsertArrayType
            types
            (PsVerifiedIrType.named
              "Array"
              (List.cons elementType List.nil))
      | List.cons _ _ => types
  | List.nil => types

def psWasmAddArrayTypesForIntrinsic
    (operation : PsVerifiedIrIntrinsic)
    (typeArguments : List PsVerifiedIrType)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  match operation with
  | .arrayMap =>
      match typeArguments with
      | List.cons inputType rest =>
          match rest with
          | List.cons outputType tail =>
              match tail with
              | List.nil =>
                  psWasmInsertArrayType
                    (psWasmInsertArrayType
                      types
                      (PsVerifiedIrType.named
                        "Array"
                        (List.cons inputType List.nil)))
                    (PsVerifiedIrType.named
                      "Array"
                      (List.cons outputType List.nil))
              | List.cons _ _ => types
          | List.nil => types
      | List.nil => types
  | .arrayFoldl =>
      match typeArguments with
      | List.cons elementType rest =>
          match rest with
          | List.cons _ tail =>
              match tail with
              | List.nil =>
                  psWasmInsertArrayType
                    types
                    (PsVerifiedIrType.named
                      "Array"
                      (List.cons elementType List.nil))
              | List.cons _ _ => types
          | List.nil => types
      | List.nil => types
  | .arrayEmptyWithCapacity =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arraySize =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arrayPush =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arrayGet =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arrayGetD =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arraySet =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | .arraySetIfInBounds =>
      psWasmAddSingleArrayTypeArgument typeArguments types
  | _ => types

def psWasmCollectArrayTypesFromExprWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr ->
    List PsVerifiedIrType ->
    List PsVerifiedIrType :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          types
  | fuel + 1 =>
      let smaller :
          PsVerifiedIrExpr ->
          List PsVerifiedIrType ->
          List PsVerifiedIrType :=
        psWasmCollectArrayTypesFromExprWithFuel fuel;
      fun (expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          let collect :
              PsVerifiedIrExpr ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            fun
              (expression : PsVerifiedIrExpr)
              (state : List PsVerifiedIrType) =>
              smaller expression state;
          let collectType :
              List PsVerifiedIrType ->
              PsVerifiedIrType ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (type : PsVerifiedIrType) =>
              psWasmCollectArrayTypesFromType
                type
                state;
          let collectArgument :
              List PsVerifiedIrType ->
              PsVerifiedIrExpr ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (argument : PsVerifiedIrExpr) =>
              collect argument state;
          let collectField :
              List PsVerifiedIrType ->
              (String × PsVerifiedIrExpr) ->
              List PsVerifiedIrType :=
            fun
              (state : List PsVerifiedIrType)
              (field : String × PsVerifiedIrExpr) =>
              collect (Prod.snd field) state;
          match expr with
          | .literal _ => types
          | .var _ => types
          | .intrinsic operation typeArguments arguments =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              let withArrayTypes :=
                psWasmAddArrayTypesForIntrinsic
                  operation
                  typeArguments
                  withTypes;
              psWasmListFoldl
                collectArgument
                arguments
                withArrayTypes
          | .lambda parameters resultType body =>
              let withParameters :=
                psWasmCollectArrayTypesFromParameters
                  parameters
                  types;
              let withResult :=
                psWasmCollectArrayTypesFromType
                  resultType
                  withParameters;
              collect body withResult
          | .call fn typeArguments arguments =>
              let withFn := collect fn types;
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  withFn;
              psWasmListFoldl
                collectArgument
                arguments
                withTypes
          | .letE _ type value body =>
              let withType :=
                psWasmCollectArrayTypesFromType
                  type
                  types;
              let withValue := collect value withType;
              collect body withValue
          | .ifE condition thenBranch elseBranch =>
              let withCondition := collect condition types;
              let withThen := collect thenBranch withCondition;
              collect elseBranch withThen
          | .record _ typeArguments fields =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              psWasmListFoldl
                collectField
                fields
                withTypes
          | .projection _ typeArguments target _ =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              collect target withTypes
          | .constructor _ _ typeArguments fields =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              psWasmListFoldl
                collectField
                fields
                withTypes
          | .matchE _ typeArguments scrutinee alternatives =>
              let withTypes :=
                psWasmListFoldl
                  collectType
                  typeArguments
                  types;
              let withScrutinee :=
                collect scrutinee withTypes;
              let collectAlternative :
                  List PsVerifiedIrType ->
                  (String ×
                    List PsVerifiedIrMatchBinding ×
                    PsVerifiedIrExpr) ->
                  List PsVerifiedIrType :=
                fun
                  (state : List PsVerifiedIrType)
                  (alternative :
                    String ×
                      List PsVerifiedIrMatchBinding ×
                      PsVerifiedIrExpr) =>
                  let bindings :=
                    Prod.fst (Prod.snd alternative);
                  let body :=
                    Prod.snd (Prod.snd alternative);
                  let collectBinding :
                      List PsVerifiedIrType ->
                      PsVerifiedIrMatchBinding ->
                      List PsVerifiedIrType :=
                    fun
                      (inner : List PsVerifiedIrType)
                      (binding : PsVerifiedIrMatchBinding) =>
                      psWasmCollectArrayTypesFromType
                        binding.type
                        inner;
                  let withBindings :=
                    psWasmListFoldl
                      collectBinding
                      bindings
                      state;
                  collect body withBindings;
              psWasmListFoldl
                collectAlternative
                alternatives
                withScrutinee

def psWasmCollectArrayTypesFromExpr
    (expr : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  psWasmCollectArrayTypesFromExprWithFuel 4096 expr types

def psWasmCollectArrayTypesFromStructureFields
    (fields : List PsVerifiedIrStructureField)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectField :
      List PsVerifiedIrType ->
      PsVerifiedIrStructureField ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (field : PsVerifiedIrStructureField) =>
      psWasmCollectArrayTypesFromType
        field.type
        state;
  psWasmListFoldl collectField fields types

def psWasmCollectArrayTypesFromConstructorFields
    (fields : List PsVerifiedIrConstructorField)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectField :
      List PsVerifiedIrType ->
      PsVerifiedIrConstructorField ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (field : PsVerifiedIrConstructorField) =>
      psWasmCollectArrayTypesFromType
        field.type
        state;
  psWasmListFoldl collectField fields types

def psWasmCollectArrayTypesFromConstructors
    (constructors : List PsVerifiedIrConstructor)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrType :=
  let collectConstructor :
      List PsVerifiedIrType ->
      PsVerifiedIrConstructor ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (constructorInfo : PsVerifiedIrConstructor) =>
      psWasmCollectArrayTypesFromConstructorFields
        constructorInfo.fields
        state;
  psWasmListFoldl
    collectConstructor
    constructors
    types

def psWasmCollectModuleArrayTypes
    (module : PsVerifiedIrModule) :
    List PsVerifiedIrType :=
  let collectStructure :
      List PsVerifiedIrType ->
      PsVerifiedIrStructure ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (structureInfo : PsVerifiedIrStructure) =>
      psWasmCollectArrayTypesFromStructureFields
        structureInfo.fields
        state;
  let fromStructures :=
    psWasmListFoldl
      collectStructure
      module.structures
      List.nil;
  let collectInductive :
      List PsVerifiedIrType ->
      PsVerifiedIrInductive ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (inductiveInfo : PsVerifiedIrInductive) =>
      psWasmCollectArrayTypesFromConstructors
        inductiveInfo.constructors
        state;
  let fromInductives :=
    psWasmListFoldl
      collectInductive
      module.inductives
      fromStructures;
  let collectDeclaration :
      List PsVerifiedIrType ->
      PsVerifiedIrDeclaration ->
      List PsVerifiedIrType :=
    fun
      (state : List PsVerifiedIrType)
      (declaration : PsVerifiedIrDeclaration) =>
      let withParameters :=
        psWasmCollectArrayTypesFromParameters
          declaration.parameters
          state;
      let withResult :=
        psWasmCollectArrayTypesFromType
          declaration.resultType
          withParameters;
      psWasmCollectArrayTypesFromExpr
        declaration.body
        withResult;
  psWasmListFoldl
    collectDeclaration
    module.declarations
    fromInductives


def psWasmLowerArrayType
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmArrayType :=
  match type with
  | .named name arguments =>
      if psStringEq name "Array" then
        match arguments with
        | List.nil =>
            Except.error PsWasmLowerError.unsupportedType
        | List.cons elementType rest =>
            match rest with
            | List.cons _ _ =>
                Except.error PsWasmLowerError.unsupportedType
            | List.nil =>
                match psWasmArrayTypeName elementType with
                | Option.none =>
                    Except.error PsWasmLowerError.unsupportedType
                | Option.some arrayName =>
                    match
                        psWasmStorageTypeOfIrType?
                          profile
                          elementType with
                    | Option.none =>
                        Except.error PsWasmLowerError.unsupportedType
                    | Option.some storageType =>
                        Except.ok {
                          name := arrayName
                          elementType := storageType
                          mutable := true
                        }
      else
        Except.error PsWasmLowerError.unsupportedType
  | _ =>
      Except.error PsWasmLowerError.unsupportedType

def psWasmLowerArrayTypes
    (profile : PsWasmTargetProfile)
    (types : List PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmArrayType) :=
  match types with
  | List.nil => Except.ok []
  | List.cons type rest =>
      match psWasmLowerArrayType profile type with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerArrayTypes profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

structure PsWasmClosureSignature where
  baseStructure : PsWasmStructType
  codeType : PsWasmFunctionType

def psWasmLowerIrTypeList
    (profile : PsWasmTargetProfile)
    (types : List PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmValueType) :=
  match types with
  | List.nil => Except.ok []
  | List.cons type rest =>
      match psWasmValueTypeOfIrType? profile type with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some lowered =>
          match psWasmLowerIrTypeList profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psWasmLowerClosureSignature
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmClosureSignature :=
  match type with
  | .function parameters result =>
      match psWasmClosureBaseName type with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some baseName =>
          match psWasmClosureCodeTypeName type with
          | Option.none => Except.error PsWasmLowerError.unsupportedType
          | Option.some codeTypeName =>
              match psWasmLowerIrTypeList profile parameters with
              | Except.error error => Except.error error
              | Except.ok loweredParameters =>
                  match psWasmLowerResultType profile result with
                  | Except.error error => Except.error error
                  | Except.ok loweredResults =>
                      Except.ok {
                        baseStructure := {
                          name := baseName
                          superType := Option.none
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
                            List.cons
                              (PsWasmValueType.refT baseName)
                              loweredParameters
                          results := loweredResults
                        }
                      }
  | _ => Except.error PsWasmLowerError.unsupportedType

def psWasmLowerClosureSignatures
    (profile : PsWasmTargetProfile)
    (types : List PsVerifiedIrType) :
    Except PsWasmLowerError (List PsWasmStructType × List PsWasmFunctionType) :=
  match types with
  | List.nil => Except.ok (Prod.mk List.nil List.nil)
  | List.cons type rest =>
      match psWasmLowerClosureSignature profile type with
      | Except.error error => Except.error error
      | Except.ok signature =>
          match psWasmLowerClosureSignatures profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (Prod.mk
                  (List.cons
                    signature.baseStructure
                    (Prod.fst loweredRest))
                  (List.cons
                    signature.codeType
                    (Prod.snd loweredRest)))

def psWasmFindStructure
    (structures : List PsVerifiedIrStructure)
    (name : String) :
    Option PsVerifiedIrStructure :=
  match structures with
  | List.nil => Option.none
  | List.cons structInfo rest =>
      if psStringEq structInfo.name name then
        Option.some structInfo
      else
        psWasmFindStructure rest name

def psWasmFindStructureFieldWorker
    (fieldName : String)
    (fields : List PsVerifiedIrStructureField) :
    Nat -> Option (Nat × PsVerifiedIrStructureField) :=
  match fields with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons field rest =>
      let smaller :
          Nat -> Option (Nat × PsVerifiedIrStructureField) :=
        psWasmFindStructureFieldWorker fieldName rest;
      fun (index : Nat) =>
        if psStringEq field.name fieldName then
          Option.some (Prod.mk index field)
        else
          smaller (Nat.add index 1)

def psWasmFindStructureFieldLoop
    (fieldName : String)
    (index : Nat)
    (fields : List PsVerifiedIrStructureField) :
    Option (Nat × PsVerifiedIrStructureField) :=
  psWasmFindStructureFieldWorker fieldName fields index

def psWasmFindStructureField
    (structInfo : PsVerifiedIrStructure)
    (fieldName : String) :
    Option (Nat × PsVerifiedIrStructureField) :=
  psWasmFindStructureFieldLoop fieldName 0 structInfo.fields

def psWasmFindRecordField
    (fields : List (String × PsVerifiedIrExpr))
    (name : String) :
    Option PsVerifiedIrExpr :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
      if psStringEq (Prod.fst field) name then
        Option.some (Prod.snd field)
      else
        psWasmFindRecordField rest name

def psWasmStructGetInstruction
    (structureName : String)
    (fieldIndex : Nat)
    (type : PsVerifiedIrType) : PsWasmInstruction :=
  match type with
  | .primitive primitive =>
      match primitive with
      | .uint8 =>
          PsWasmInstruction.structGetU structureName fieldIndex
      | .uint16 =>
          PsWasmInstruction.structGetU structureName fieldIndex
      | .int8 =>
          PsWasmInstruction.structGetS structureName fieldIndex
      | .int16 =>
          PsWasmInstruction.structGetS structureName fieldIndex
      | _ => PsWasmInstruction.structGet structureName fieldIndex
  | _ => PsWasmInstruction.structGet structureName fieldIndex

def psWasmLowerStructureField
    (profile : PsWasmTargetProfile)
    (field : PsVerifiedIrStructureField) :
    Except PsWasmLowerError PsWasmStructField :=
  match psWasmStorageTypeOfIrType? profile field.type with
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some storageType =>
      Except.ok {
        name := field.name
        storageType := storageType
      }

def psWasmLowerStructureFields
    (profile : PsWasmTargetProfile)
    (fields : List PsVerifiedIrStructureField) :
    Except PsWasmLowerError (List PsWasmStructField) :=
  match fields with
  | List.nil => Except.ok []
  | List.cons field rest =>
      match psWasmLowerStructureField profile field with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerStructureFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

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
            superType := Option.none
            isFinal := true
            fields := fields
          }

def psWasmLowerStructures
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure) :
    Except PsWasmLowerError (List PsWasmStructType) :=
  match structures with
  | List.nil => Except.ok []
  | List.cons structInfo rest =>
      match psWasmLowerStructure profile structInfo with
      | Except.error error =>
          Except.error
            (psWasmContextualizeUnsupportedType
              (String.Internal.append
                "structure:"
                structInfo.name)
              error)
      | Except.ok lowered =>
          match psWasmLowerStructures profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psWasmConstructorTypeName
    (inductiveName constructorName : String) : String :=
  String.Internal.append inductiveName (String.Internal.append "$" constructorName)

def psWasmFindInductive
    (inductives : List PsVerifiedIrInductive)
    (name : String) :
    Option PsVerifiedIrInductive :=
  match inductives with
  | List.nil => Option.none
  | List.cons inductiveInfo rest =>
      if psStringEq inductiveInfo.name name then
        Option.some inductiveInfo
      else
        psWasmFindInductive rest name

def psWasmFindConstructor
    (constructors : List PsVerifiedIrConstructor)
    (name : String) :
    Option PsVerifiedIrConstructor :=
  match constructors with
  | List.nil => Option.none
  | List.cons constructorInfo rest =>
      if psStringEq constructorInfo.name name then
        Option.some constructorInfo
      else
        psWasmFindConstructor rest name

def psWasmFindConstructorFieldWorker
    (fieldName : String)
    (fields : List PsVerifiedIrConstructorField) :
    Nat -> Option (Nat × PsVerifiedIrConstructorField) :=
  match fields with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons field rest =>
      let smaller :
          Nat -> Option (Nat × PsVerifiedIrConstructorField) :=
        psWasmFindConstructorFieldWorker fieldName rest;
      fun (index : Nat) =>
        if psStringEq field.name fieldName then
          Option.some (Prod.mk index field)
        else
          smaller (Nat.add index 1)

def psWasmFindConstructorFieldLoop
    (fieldName : String)
    (index : Nat)
    (fields : List PsVerifiedIrConstructorField) :
    Option (Nat × PsVerifiedIrConstructorField) :=
  psWasmFindConstructorFieldWorker fieldName fields index

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
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some storageType =>
      Except.ok {
        name := field.name
        storageType := storageType
      }

def psWasmLowerConstructorFields
    (profile : PsWasmTargetProfile)
    (fields : List PsVerifiedIrConstructorField) :
    Except PsWasmLowerError (List PsWasmStructField) :=
  match fields with
  | List.nil => Except.ok []
  | List.cons field rest =>
      match psWasmLowerConstructorField profile field with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psWasmLowerConstructorFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psWasmLowerInductiveConstructors
    (profile : PsWasmTargetProfile)
    (inductiveInfo : PsVerifiedIrInductive)
    (constructors : List PsVerifiedIrConstructor) :
    Except PsWasmLowerError (List PsWasmStructType) :=
  match constructors with
  | List.nil => Except.ok []
  | List.cons constructorInfo rest =>
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
            superType := Option.some inductiveInfo.name
            isFinal := true
            fields := fields
          };
          match
              psWasmLowerInductiveConstructors
                profile
                inductiveInfo
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psWasmLowerInductive
    (profile : PsWasmTargetProfile)
    (inductiveInfo : PsVerifiedIrInductive) :
    Except PsWasmLowerError (List PsWasmStructType) :=
  match inductiveInfo.typeParameters with
  | _ :: _ => Except.error PsWasmLowerError.unsupportedType
  | [] =>
      let base : PsWasmStructType := {
        name := inductiveInfo.name
        superType := Option.none
        isFinal := false
        fields := []
      };
      match
          psWasmLowerInductiveConstructors
            profile
            inductiveInfo
            inductiveInfo.constructors with
      | Except.error error => Except.error error
      | Except.ok constructors =>
          Except.ok (List.cons base constructors)

def psWasmLowerInductives
    (profile : PsWasmTargetProfile)
    (inductives : List PsVerifiedIrInductive) :
    Except PsWasmLowerError (List PsWasmStructType) :=
  match inductives with
  | List.nil => Except.ok []
  | List.cons inductiveInfo rest =>
      match psWasmLowerInductive profile inductiveInfo with
      | Except.error error =>
          Except.error
            (psWasmContextualizeUnsupportedType
              (String.Internal.append
                "inductive:"
                inductiveInfo.name)
              error)
      | Except.ok lowered =>
          match psWasmLowerInductives profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (psListAppend lowered loweredRest)

def psWasmParameterBindingsWorker
    (parameters : List PsVerifiedIrParameter) :
    Nat -> List PsWasmBinding :=
  match parameters with
  | List.nil =>
      fun (_index : Nat) => List.nil
  | List.cons parameter rest =>
      let smaller : Nat -> List PsWasmBinding :=
        psWasmParameterBindingsWorker rest;
      fun (index : Nat) =>
        List.cons
          (PsWasmBinding.mk
            parameter.name
            index
            parameter.type)
          (smaller (Nat.add index 1))

def psWasmParameterBindingsLoop
    (index : Nat)
    (parameters : List PsVerifiedIrParameter) :
    List PsWasmBinding :=
  psWasmParameterBindingsWorker parameters index

def psWasmParameterBindings
    (parameters : List PsVerifiedIrParameter) :
    List PsWasmBinding :=
  psWasmParameterBindingsLoop 0 parameters

def psWasmFindBinding
    (bindings : List PsWasmBinding)
    (name : String) :
    Option PsWasmBinding :=
  match bindings with
  | List.nil => Option.none
  | List.cons binding rest =>
      if psStringEq binding.name name then
        Option.some binding
      else
        psWasmFindBinding rest name

def psWasmFindBindingIndex
    (bindings : List PsWasmBinding)
    (name : String) : Option Nat :=
  match psWasmFindBinding bindings name with
  | Option.none => Option.none
  | Option.some binding => Option.some binding.index

def psWasmStringListContains
    (items : List String)
    (name : String) : Bool :=
  match items with
  | List.nil => false
  | List.cons item rest =>
      if psStringEq item name then
        true
      else
        psWasmStringListContains rest name

def psWasmBindingListContains
    (bindings : List PsWasmBinding)
    (name : String) : Bool :=
  match bindings with
  | List.nil => false
  | List.cons binding rest =>
      if psStringEq binding.name name then
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
    | Option.none => captures
    | Option.some binding => psListAppend captures (List.cons binding List.nil)

def psWasmParameterNames
    (parameters : List PsVerifiedIrParameter) :
    List String :=
  match parameters with
  | List.nil => []
  | List.cons parameter rest =>
      List.cons parameter.name (psWasmParameterNames rest)

def psWasmMatchBindingNames
    (bindings : List PsVerifiedIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil => []
  | List.cons binding rest =>
      List.cons binding.name (psWasmMatchBindingNames rest)

def psWasmCollectCapturesWorker
    (outerBindings : List PsWasmBinding)
    (remainingFuel : Nat) :
    List String ->
    PsVerifiedIrExpr ->
    List PsWasmBinding ->
    List PsWasmBinding :=
  match remainingFuel with
  | 0 =>
      fun (_boundNames : List String) =>
        fun (_expr : PsVerifiedIrExpr) =>
          fun (captures : List PsWasmBinding) =>
            captures
  | fuel + 1 =>
      let smaller :
          List String ->
          PsVerifiedIrExpr ->
          List PsWasmBinding ->
          List PsWasmBinding :=
        psWasmCollectCapturesWorker
          outerBindings
          fuel;
      fun (boundNames : List String) =>
        fun (expr : PsVerifiedIrExpr) =>
          fun (captures : List PsWasmBinding) =>
            let collect :
                PsVerifiedIrExpr ->
                List PsWasmBinding ->
                List PsWasmBinding :=
              fun
                (nested : PsVerifiedIrExpr)
                (state : List PsWasmBinding) =>
                smaller boundNames nested state;
            let collectArgument :
                List PsWasmBinding ->
                PsVerifiedIrExpr ->
                List PsWasmBinding :=
              fun
                (state : List PsWasmBinding)
                (argument : PsVerifiedIrExpr) =>
                collect argument state;
            let collectField :
                List PsWasmBinding ->
                (String × PsVerifiedIrExpr) ->
                List PsWasmBinding :=
              fun
                (state : List PsWasmBinding)
                (field : String × PsVerifiedIrExpr) =>
                collect (Prod.snd field) state;
            match expr with
            | .literal _ => captures
            | .var name =>
                psWasmAppendCaptureForName
                  outerBindings
                  boundNames
                  captures
                  name
            | .intrinsic _ _ arguments =>
                psWasmListFoldl
                  collectArgument
                  arguments
                  captures
            | .lambda parameters _ body =>
                smaller
                  (psListAppend
                    (psWasmParameterNames parameters)
                    boundNames)
                  body
                  captures
            | .call fn _ arguments =>
                let withFn := collect fn captures;
                psWasmListFoldl
                  collectArgument
                  arguments
                  withFn
            | .letE name _ value body =>
                let withValue := collect value captures;
                smaller
                  (List.cons name boundNames)
                  body
                  withValue
            | .ifE condition thenBranch elseBranch =>
                let withCondition := collect condition captures;
                let withThen := collect thenBranch withCondition;
                collect elseBranch withThen
            | .record _ _ fields =>
                psWasmListFoldl
                  collectField
                  fields
                  captures
            | .projection _ _ target _ =>
                collect target captures
            | .constructor _ _ _ fields =>
                psWasmListFoldl
                  collectField
                  fields
                  captures
            | .matchE _ _ scrutinee alternatives =>
                let withScrutinee := collect scrutinee captures;
                let collectAlternative :
                    List PsWasmBinding ->
                    (String ×
                      List PsVerifiedIrMatchBinding ×
                      PsVerifiedIrExpr) ->
                    List PsWasmBinding :=
                  fun
                    (state : List PsWasmBinding)
                    (alternative :
                      String ×
                        List PsVerifiedIrMatchBinding ×
                        PsVerifiedIrExpr) =>
                    let matchBindings :=
                      Prod.fst (Prod.snd alternative);
                    let body :=
                      Prod.snd (Prod.snd alternative);
                    smaller
                      (psListAppend
                        (psWasmMatchBindingNames matchBindings)
                        boundNames)
                      body
                      state;
                psWasmListFoldl
                  collectAlternative
                  alternatives
                  withScrutinee

def psWasmCollectCapturesWithFuel
    (outerBindings : List PsWasmBinding)
    (boundNames : List String)
    (remainingFuel : Nat)
    (expr : PsVerifiedIrExpr)
    (captures : List PsWasmBinding) :
    List PsWasmBinding :=
  psWasmCollectCapturesWorker
    outerBindings
    remainingFuel
    boundNames
    expr
    captures

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

def psWasmParameterBindingsFromWorker
    (parameters : List PsVerifiedIrParameter) :
    Nat -> List PsWasmBinding :=
  match parameters with
  | List.nil =>
      fun (_firstIndex : Nat) => List.nil
  | List.cons parameter rest =>
      let smaller : Nat -> List PsWasmBinding :=
        psWasmParameterBindingsFromWorker rest;
      fun (firstIndex : Nat) =>
        List.cons
          (PsWasmBinding.mk
            parameter.name
            firstIndex
            parameter.type)
          (smaller (Nat.add firstIndex 1))

def psWasmParameterBindingsFrom
    (firstIndex : Nat)
    (parameters : List PsVerifiedIrParameter) :
    List PsWasmBinding :=
  psWasmParameterBindingsFromWorker parameters firstIndex

def psWasmAddLocal
    (state : PsWasmLowerState)
    (type : PsWasmValueType) :
    Nat × PsWasmLowerState :=
  let index := state.nextLocalIndex;
  Prod.mk
    index
    {
      nextLocalIndex := Nat.add index 1
      localTypes := psListAppend state.localTypes (List.cons type List.nil)
      currentDefinition := state.currentDefinition
      nextLambdaId := state.nextLambdaId
      generatedStructures := state.generatedStructures
      generatedFunctionTypes := state.generatedFunctionTypes
      generatedFunctions := state.generatedFunctions
      generatedFunctionRefs := state.generatedFunctionRefs
    }

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

def psWasmLocalGetsForTypesWorker
    (types : List PsWasmValueType) :
    Nat -> List PsWasmInstruction :=
  match types with
  | List.nil =>
      fun (_index : Nat) => List.nil
  | List.cons _ rest =>
      let smaller : Nat -> List PsWasmInstruction :=
        psWasmLocalGetsForTypesWorker rest;
      fun (index : Nat) =>
        List.cons
          (PsWasmInstruction.localGet index)
          (smaller (Nat.add index 1))

def psWasmAppendGeneratedFunction
    (state : PsWasmLowerState)
    (function : PsWasmFunction)
    (referenced : Bool) : PsWasmLowerState :=
  {
    nextLocalIndex := state.nextLocalIndex
    localTypes := state.localTypes
    currentDefinition := state.currentDefinition
    nextLambdaId := state.nextLambdaId
    generatedStructures := state.generatedStructures
    generatedFunctionTypes := state.generatedFunctionTypes
    generatedFunctions :=
      psListAppend
        state.generatedFunctions
        (List.cons function List.nil)
    generatedFunctionRefs :=
      if referenced then
        psListAppend
          state.generatedFunctionRefs
          (List.cons function.name List.nil)
      else
        state.generatedFunctionRefs
  }

def psWasmAdvanceGeneratedId
    (state : PsWasmLowerState) : PsWasmLowerState :=
  {
    nextLocalIndex := state.nextLocalIndex
    localTypes := state.localTypes
    currentDefinition := state.currentDefinition
    nextLambdaId := Nat.add state.nextLambdaId 1
    generatedStructures := state.generatedStructures
    generatedFunctionTypes := state.generatedFunctionTypes
    generatedFunctions := state.generatedFunctions
    generatedFunctionRefs := state.generatedFunctionRefs
  }

def psWasmLowerTopLevelFunctionValue
    (profile : PsWasmTargetProfile)
    (state : PsWasmLowerState)
    (functionName : String)
    (parameterTypes : List PsVerifiedIrType)
    (resultType : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  let functionType : PsVerifiedIrType :=
    PsVerifiedIrType.function parameterTypes resultType;
  match psWasmClosureBaseName functionType with
  | Option.none =>
      Except.error PsWasmLowerError.unsupportedType
  | Option.some baseName =>
      match psWasmClosureCodeTypeName functionType with
      | Option.none =>
          Except.error PsWasmLowerError.unsupportedType
      | Option.some codeTypeName =>
          match psWasmLowerIrTypeList profile parameterTypes with
          | Except.error error => Except.error error
          | Except.ok loweredParameters =>
              match psWasmLowerResultType profile resultType with
              | Except.error error => Except.error error
              | Except.ok results =>
                  let adapterId : Nat := state.nextLambdaId;
                  let adapterName : String :=
                    String.Internal.append
                      state.currentDefinition
                      (String.Internal.append
                        "$functionAdapter$"
                        (psNatToString adapterId));
                  let advancedState : PsWasmLowerState :=
                    psWasmAdvanceGeneratedId state;
                  let generatedFunction : PsWasmFunction := {
                    name := adapterName
                    typeName := Option.some codeTypeName
                    parameters :=
                      List.cons
                        (PsWasmValueType.refT baseName)
                        loweredParameters
                    results := results
                    locals := List.nil
                    body :=
                      psListAppend
                        (psWasmLocalGetsForTypesWorker
                          loweredParameters
                          1)
                        (List.cons
                          (PsWasmInstruction.call functionName)
                          List.nil)
                  };
                  let finalState : PsWasmLowerState :=
                    psWasmAppendGeneratedFunction
                      advancedState
                      generatedFunction
                      true;
                  Except.ok {
                    instructions := [
                      PsWasmInstruction.refFunc adapterName,
                      PsWasmInstruction.structNew baseName
                    ]
                    state := finalState
                  }

def psWasmLowerHigherOrderFunctionValueWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (fn : PsVerifiedIrExpr)
    (parameterTypes : List PsVerifiedIrType)
    (resultType : PsVerifiedIrType) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  let functionType : PsVerifiedIrType :=
    PsVerifiedIrType.function parameterTypes resultType;
  match psWasmClosureBaseName functionType with
  | Option.none =>
      Except.error PsWasmLowerError.unsupportedType
  | Option.some baseName =>
      match
          lower
            (Option.some (PsWasmValueType.refT baseName))
            state
            fn with
      | Except.ok lowered => Except.ok lowered
      | Except.error error =>
          match error with
          | PsWasmLowerError.unknownVariable name =>
              match fn with
              | PsVerifiedIrExpr.var functionName =>
                  if psStringEq name functionName then
                    psWasmLowerTopLevelFunctionValue
                      profile
                      state
                      functionName
                      parameterTypes
                      resultType
                  else
                    Except.error
                      (PsWasmLowerError.unknownVariable name)
              | _ =>
                  Except.error
                    (PsWasmLowerError.unknownVariable name)
          | _ => Except.error error

def psWasmLowerExprListWorker
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (expected : Option PsWasmValueType)
    (expressions : List PsVerifiedIrExpr) :
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match expressions with
  | List.nil =>
      fun (state : PsWasmLowerState) =>
        Except.ok {
          instructions := []
          state := state
        }
  | List.cons expr rest =>
      let smaller :
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerExprListWorker lower expected rest;
      fun (state : PsWasmLowerState) =>
        match lower expected state expr with
        | Except.error error => Except.error error
        | Except.ok lowered =>
            match smaller lowered.state with
            | Except.error error => Except.error error
            | Except.ok loweredRest =>
                Except.ok {
                  instructions :=
                    psListAppend
                      lowered.instructions
                      loweredRest.instructions
                  state := loweredRest.state
                }

def psWasmLowerExprListWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (expressions : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprListWorker lower expected expressions state

def psWasmLowerRecordFieldsWorker
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (structInfo : PsVerifiedIrStructure)
    (fields : List (String × PsVerifiedIrExpr))
    (structureFields : List PsVerifiedIrStructureField) :
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match structureFields with
  | List.nil =>
      fun (state : PsWasmLowerState) =>
        Except.ok {
          instructions := []
          state := state
        }
  | List.cons field rest =>
      let smaller :
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerRecordFieldsWorker
          profile
          lower
          structInfo
          fields
          rest;
      fun (state : PsWasmLowerState) =>
        match psWasmFindRecordField fields field.name with
        | Option.none =>
            Except.error
              (PsWasmLowerError.missingRecordField
                structInfo.name field.name)
        | Option.some value =>
            match psWasmValueTypeOfIrType? profile field.type with
            | Option.none =>
                Except.error PsWasmLowerError.unsupportedType
            | Option.some valueType =>
                match lower (Option.some valueType) state value with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    match smaller lowered.state with
                    | Except.error error => Except.error error
                    | Except.ok loweredRest =>
                        Except.ok {
                          instructions :=
                            psListAppend
                              lowered.instructions
                              loweredRest.instructions
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
    (fields : List (String × PsVerifiedIrExpr))
    (state : PsWasmLowerState)
    (structureFields : List PsVerifiedIrStructureField) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerRecordFieldsWorker
    profile lower structInfo fields structureFields state

def psWasmLowerConstructorValuesWorker
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor)
    (fields : List (String × PsVerifiedIrExpr))
    (constructorFields : List PsVerifiedIrConstructorField) :
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match constructorFields with
  | List.nil =>
      fun (state : PsWasmLowerState) =>
        Except.ok {
          instructions := []
          state := state
        }
  | List.cons field rest =>
      let smaller :
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerConstructorValuesWorker
          profile
          lower
          inductiveName
          constructorInfo
          fields
          rest;
      fun (state : PsWasmLowerState) =>
        match psWasmFindRecordField fields field.name with
        | Option.none =>
            Except.error
              (PsWasmLowerError.missingConstructorField
                inductiveName
                constructorInfo.name
                field.name)
        | Option.some value =>
            match psWasmValueTypeOfIrType? profile field.type with
            | Option.none =>
                Except.error PsWasmLowerError.unsupportedType
            | Option.some valueType =>
                match lower (Option.some valueType) state value with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    match smaller lowered.state with
                    | Except.error error => Except.error error
                    | Except.ok loweredRest =>
                        Except.ok {
                          instructions :=
                            psListAppend
                              lowered.instructions
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
    (fields : List (String × PsVerifiedIrExpr))
    (state : PsWasmLowerState)
    (constructorFields : List PsVerifiedIrConstructorField) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerConstructorValuesWorker
    profile
    lower
    inductiveName
    constructorInfo
    fields
    constructorFields
    state

def psWasmLowerNatArgumentsWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprListWith
    lower
    (Option.some psWasmNatRef)
    state
    arguments

def psWasmLowerNatBinaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.some _ =>
      match psWasmLowerNatArgumentsWith lower state arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend
                lowered.instructions
                [PsWasmInstruction.call functionName]
            state := lowered.state
          }
  | Option.none => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerNatCompareWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (comparison : PsWasmInstruction)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.some _ =>
      match psWasmLowerNatArgumentsWith lower state arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend lowered.instructions [
                PsWasmInstruction.call psWasmNatCmpFn,
                PsWasmInstruction.i32Const 0,
                comparison
              ]
            state := lowered.state
          }
  | Option.none => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerIntArgumentsWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprListWith
    lower
    (Option.some psWasmIntRef)
    state
    arguments

def psWasmLowerIntBinaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.some _ =>
      match psWasmLowerIntArgumentsWith lower state arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend
                lowered.instructions
                [PsWasmInstruction.call functionName]
            state := lowered.state
          }
  | Option.none => Except.error PsWasmLowerError.invalidIntrinsicArity

def psWasmLowerIntUnaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | [] => Except.error PsWasmLowerError.invalidIntrinsicArity
  | value :: rest =>
      match rest with
      | _ :: _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | [] =>
          match
              lower
                (Option.some psWasmIntRef)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [PsWasmInstruction.call functionName]
                state := lowered.state
              }

def psWasmLowerNatToIntUnaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | [] => Except.error PsWasmLowerError.invalidIntrinsicArity
  | value :: rest =>
      match rest with
      | _ :: _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | [] =>
          match
              lower
                (Option.some psWasmNatRef)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [PsWasmInstruction.call functionName]
                state := lowered.state
              }

def psWasmLowerIntCompareWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (comparison : PsWasmInstruction)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.some _ =>
      match psWasmLowerIntArgumentsWith lower state arguments with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend lowered.instructions [
                PsWasmInstruction.call psWasmIntCmpFn,
                PsWasmInstruction.i32Const 0,
                comparison
              ]
            state := lowered.state
          }
  | Option.none => Except.error PsWasmLowerError.invalidIntrinsicArity


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
  | [] => Except.error PsWasmLowerError.invalidIntrinsicArity
  | elementType :: rest =>
      match rest with
      | _ :: _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | [] =>
          match psWasmArrayTypeName elementType with
          | Option.none => Except.error PsWasmLowerError.unsupportedType
          | Option.some typeName =>
              match psWasmValueTypeOfIrType? profile elementType with
              | Option.none => Except.error PsWasmLowerError.unsupportedType
              | Option.some elementValueType =>
                  Except.ok {
                    elementType := elementType
                    elementValueType := elementValueType
                    typeName := typeName
                    refType := PsWasmValueType.refT typeName
                  }

def psWasmArrayGetInstruction
    (typeName : String)
    (elementType : PsVerifiedIrType) : PsWasmInstruction :=
  match elementType with
  | .primitive primitive =>
      match primitive with
      | .uint8 => PsWasmInstruction.arrayGetU typeName
      | .uint16 => PsWasmInstruction.arrayGetU typeName
      | .int8 => PsWasmInstruction.arrayGetS typeName
      | .int16 => PsWasmInstruction.arrayGetS typeName
      | _ => PsWasmInstruction.arrayGet typeName
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
      | [] => Except.error PsWasmLowerError.invalidIntrinsicArity
      | capacity :: rest =>
          match rest with
          | _ :: _ =>
              Except.error PsWasmLowerError.invalidIntrinsicArity
          | [] =>
              match lower (Option.some psWasmNatRef) state capacity with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    instructions :=
                      psListAppend lowered.instructions [
                        PsWasmInstruction.drop,
                        PsWasmInstruction.arrayNewFixed info.typeName 0
                      ]
                    state := lowered.state
                  }

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
      | [] => Except.error PsWasmLowerError.invalidIntrinsicArity
      | array :: rest =>
          match rest with
          | _ :: _ =>
              Except.error PsWasmLowerError.invalidIntrinsicArity
          | [] =>
              match lower (Option.some info.refType) state array with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    instructions :=
                      psListAppend lowered.instructions [
                        PsWasmInstruction.arrayLen,
                        PsWasmInstruction.call psWasmNatOfU32Fn
                      ]
                    state := lowered.state
                  }

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
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let array := Prod.fst pair;
          let value := Prod.snd pair;
          match lower (Option.some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType;
              let arrayLocal := (Prod.fst allocatedArray);
              match
                  lower
                    (Option.some info.elementValueType)
                    (Prod.snd allocatedArray)
                    value with
              | Except.error error => Except.error error
              | Except.ok loweredValue =>
                  let allocatedValue :=
                    psWasmAddLocal
                      loweredValue.state
                      info.elementValueType;
                  let valueLocal := (Prod.fst allocatedValue);
                  let allocatedOutput :=
                    psWasmAddLocal (Prod.snd allocatedValue) info.refType;
                  let outputLocal := (Prod.fst allocatedOutput);
                  Except.ok {
                    instructions :=
                      psListAppend
                        loweredArray.instructions
                        (psListAppend
                          [
                                                  PsWasmInstruction.localSet arrayLocal
                                                ]
                          (psListAppend
                            loweredValue.instructions
                            [
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
                                                  ]))
                    state := (Prod.snd allocatedOutput)
                  }

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
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let array := Prod.fst pair;
          let index := Prod.snd pair;
          match lower (Option.some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType;
              let arrayLocal := (Prod.fst allocatedArray);
              match lower (Option.some psWasmNatRef) (Prod.snd allocatedArray) index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef;
                  let indexLocal := (Prod.fst allocatedIndex);
                  Except.ok {
                    instructions :=
                      psListAppend
                        loweredArray.instructions
                        (psListAppend
                          [
                                                  PsWasmInstruction.localSet arrayLocal
                                                ]
                          (psListAppend
                            loweredIndex.instructions
                            [
                                                    PsWasmInstruction.localSet indexLocal,
                                                    PsWasmInstruction.localGet indexLocal,
                                                    PsWasmInstruction.call psWasmNatFitsU32Fn,
                                                    PsWasmInstruction.ifStart
                                                      (Option.some info.elementValueType),
                                                      PsWasmInstruction.localGet arrayLocal,
                                                      PsWasmInstruction.localGet indexLocal,
                                                      PsWasmInstruction.call psWasmNatToU32Fn,
                                                      psWasmArrayGetInstruction
                                                        info.typeName info.elementType,
                                                    PsWasmInstruction.else_,
                                                      PsWasmInstruction.unreachable,
                                                    PsWasmInstruction.end_
                                                  ]))
                    state := (Prod.snd allocatedIndex)
                  }

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
      match psWasmListTriple? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some triple =>
          let array := Prod.fst triple;
          let tail := Prod.snd triple;
          let index := Prod.fst tail;
          let fallback := Prod.snd tail;
          match lower (Option.some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType;
              let arrayLocal := (Prod.fst allocatedArray);
              match lower (Option.some psWasmNatRef) (Prod.snd allocatedArray) index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef;
                  let indexLocal := (Prod.fst allocatedIndex);
                  match
                      lower
                        (Option.some info.elementValueType)
                        (Prod.snd allocatedIndex)
                        fallback with
                  | Except.error error => Except.error error
                  | Except.ok loweredFallback =>
                      let allocatedFallback :=
                        psWasmAddLocal
                          loweredFallback.state
                          info.elementValueType;
                      let fallbackLocal := (Prod.fst allocatedFallback);
                      Except.ok {
                        instructions :=
                          psListAppend
                            loweredArray.instructions
                            (psListAppend
                              [
                                                          PsWasmInstruction.localSet arrayLocal
                                                        ]
                              (psListAppend
                                loweredIndex.instructions
                                (psListAppend
                                  [
                                                              PsWasmInstruction.localSet indexLocal
                                                            ]
                                  (psListAppend
                                    loweredFallback.instructions
                                    [
                                                                PsWasmInstruction.localSet fallbackLocal,
                                                                PsWasmInstruction.localGet indexLocal,
                                                                PsWasmInstruction.call psWasmNatFitsU32Fn,
                                                                PsWasmInstruction.ifStart
                                                                  (Option.some info.elementValueType),
                                                                  PsWasmInstruction.localGet indexLocal,
                                                                  PsWasmInstruction.call psWasmNatToU32Fn,
                                                                  PsWasmInstruction.localGet arrayLocal,
                                                                  PsWasmInstruction.arrayLen,
                                                                  PsWasmInstruction.i32LtU,
                                                                  PsWasmInstruction.ifStart
                                                                    (Option.some info.elementValueType),
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
                                                              ]))))
                        state := (Prod.snd allocatedFallback)
                      }

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
      match psWasmListTriple? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some triple =>
          let array := Prod.fst triple;
          let tail := Prod.snd triple;
          let index := Prod.fst tail;
          let value := Prod.snd tail;
          match lower (Option.some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType;
              let arrayLocal := (Prod.fst allocatedArray);
              match lower (Option.some psWasmNatRef) (Prod.snd allocatedArray) index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef;
                  let indexLocal := (Prod.fst allocatedIndex);
                  match
                      lower
                        (Option.some info.elementValueType)
                        (Prod.snd allocatedIndex)
                        value with
                  | Except.error error => Except.error error
                  | Except.ok loweredValue =>
                      let allocatedValue :=
                        psWasmAddLocal
                          loweredValue.state
                          info.elementValueType;
                      let valueLocal := (Prod.fst allocatedValue);
                      let allocatedOutput :=
                        psWasmAddLocal (Prod.snd allocatedValue) info.refType;
                      let outputLocal := (Prod.fst allocatedOutput);
                      Except.ok {
                        instructions :=
                          psListAppend
                            loweredArray.instructions
                            (psListAppend
                              [
                                                          PsWasmInstruction.localSet arrayLocal
                                                        ]
                              (psListAppend
                                loweredIndex.instructions
                                (psListAppend
                                  [
                                                              PsWasmInstruction.localSet indexLocal
                                                            ]
                                  (psListAppend
                                    loweredValue.instructions
                                    [
                                                                PsWasmInstruction.localSet valueLocal,
                                                                PsWasmInstruction.localGet indexLocal,
                                                                PsWasmInstruction.call psWasmNatFitsU32Fn,
                                                                PsWasmInstruction.ifStart (Option.some info.refType),
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
                                                              ]))))
                        state := (Prod.snd allocatedOutput)
                      }

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
      match psWasmListTriple? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some triple =>
          let array := Prod.fst triple;
          let tail := Prod.snd triple;
          let index := Prod.fst tail;
          let value := Prod.snd tail;
          match lower (Option.some info.refType) state array with
          | Except.error error => Except.error error
          | Except.ok loweredArray =>
              let allocatedArray :=
                psWasmAddLocal loweredArray.state info.refType;
              let arrayLocal := (Prod.fst allocatedArray);
              match lower (Option.some psWasmNatRef) (Prod.snd allocatedArray) index with
              | Except.error error => Except.error error
              | Except.ok loweredIndex =>
                  let allocatedIndex :=
                    psWasmAddLocal loweredIndex.state psWasmNatRef;
                  let indexLocal := (Prod.fst allocatedIndex);
                  match
                      lower
                        (Option.some info.elementValueType)
                        (Prod.snd allocatedIndex)
                        value with
                  | Except.error error => Except.error error
                  | Except.ok loweredValue =>
                      let allocatedValue :=
                        psWasmAddLocal
                          loweredValue.state
                          info.elementValueType;
                      let valueLocal := (Prod.fst allocatedValue);
                      let allocatedOutput :=
                        psWasmAddLocal (Prod.snd allocatedValue) info.refType;
                      let outputLocal := (Prod.fst allocatedOutput);
                      Except.ok {
                        instructions :=
                          psListAppend
                            loweredArray.instructions
                            (psListAppend
                              [
                                                          PsWasmInstruction.localSet arrayLocal
                                                        ]
                              (psListAppend
                                loweredIndex.instructions
                                (psListAppend
                                  [
                                                              PsWasmInstruction.localSet indexLocal
                                                            ]
                                  (psListAppend
                                    loweredValue.instructions
                                    [
                                                                PsWasmInstruction.localSet valueLocal,
                                                                PsWasmInstruction.localGet indexLocal,
                                                                PsWasmInstruction.call psWasmNatFitsU32Fn,
                                                                PsWasmInstruction.ifStart (Option.some info.refType),
                                                                  PsWasmInstruction.localGet indexLocal,
                                                                  PsWasmInstruction.call psWasmNatToU32Fn,
                                                                  PsWasmInstruction.localGet arrayLocal,
                                                                  PsWasmInstruction.arrayLen,
                                                                  PsWasmInstruction.i32LtU,
                                                                  PsWasmInstruction.ifStart (Option.some info.refType),
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
                                                              ]))))
                        state := (Prod.snd allocatedOutput)
                      }

def psWasmLowerArrayMapWith
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
  match typeArguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons inputType typeRest =>
      match typeRest with
      | List.nil =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.cons outputType typeTail =>
          match typeTail with
          | List.cons _ _ =>
              Except.error PsWasmLowerError.invalidIntrinsicArity
          | List.nil =>
              match
                  psWasmResolveArrayLowerInfo
                    profile
                    (List.cons inputType List.nil) with
              | Except.error error => Except.error error
              | Except.ok inputInfo =>
                  match
                      psWasmResolveArrayLowerInfo
                        profile
                        (List.cons outputType List.nil) with
                  | Except.error error => Except.error error
                  | Except.ok outputInfo =>
                      match psWasmListPair? arguments with
                      | Option.none =>
                          Except.error
                            PsWasmLowerError.invalidIntrinsicArity
                      | Option.some pair =>
                          let fn : PsVerifiedIrExpr := Prod.fst pair;
                          let array : PsVerifiedIrExpr := Prod.snd pair;
                          let parameterTypes : List PsVerifiedIrType :=
                            List.cons inputType List.nil;
                          let functionType : PsVerifiedIrType :=
                            PsVerifiedIrType.function
                              parameterTypes
                              outputType;
                          match psWasmClosureBaseName functionType with
                          | Option.none =>
                              Except.error PsWasmLowerError.unsupportedType
                          | Option.some baseName =>
                              match
                                  psWasmClosureCodeTypeName
                                    functionType with
                              | Option.none =>
                                  Except.error
                                    PsWasmLowerError.unsupportedType
                              | Option.some codeTypeName =>
                                  match
                                      psWasmLowerHigherOrderFunctionValueWith
                                        profile
                                        lower
                                        state
                                        fn
                                        parameterTypes
                                        outputType with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok loweredFunction =>
                                      let allocatedFunction :=
                                        psWasmAddLocal
                                          loweredFunction.state
                                          (PsWasmValueType.refT
                                            baseName);
                                      let functionLocal : Nat :=
                                        Prod.fst allocatedFunction;
                                      match
                                          lower
                                            (Option.some
                                              inputInfo.refType)
                                            (Prod.snd
                                              allocatedFunction)
                                            array with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok loweredArray =>
                                          let allocatedArray :=
                                            psWasmAddLocal
                                              loweredArray.state
                                              inputInfo.refType;
                                          let arrayLocal : Nat :=
                                            Prod.fst allocatedArray;
                                          let allocatedOutput :=
                                            psWasmAddLocal
                                              (Prod.snd
                                                allocatedArray)
                                              outputInfo.refType;
                                          let outputLocal : Nat :=
                                            Prod.fst allocatedOutput;
                                          let helperState : PsWasmLowerState :=
                                            Prod.snd allocatedOutput;
                                          let helperId : Nat :=
                                            helperState.nextLambdaId;
                                          let helperName : String :=
                                            String.Internal.append
                                              helperState.currentDefinition
                                              (String.Internal.append
                                                "$arrayMap$"
                                                (psNatToString helperId));
                                          let advancedState : PsWasmLowerState :=
                                            psWasmAdvanceGeneratedId
                                              helperState;
                                          let helperFunction : PsWasmFunction := {
                                            name := helperName
                                            typeName := Option.none
                                            parameters := [
                                              PsWasmValueType.refT
                                                baseName,
                                              inputInfo.refType,
                                              PsWasmValueType.i32,
                                              outputInfo.refType
                                            ]
                                            results := [
                                              outputInfo.refType
                                            ]
                                            locals := [
                                              outputInfo.elementValueType
                                            ]
                                            body := psListAppend [
                                              PsWasmInstruction.localGet 2,
                                              PsWasmInstruction.localGet 1,
                                              PsWasmInstruction.arrayLen,
                                              PsWasmInstruction.i32LtU,
                                              PsWasmInstruction.ifStart
                                                (Option.some
                                                  outputInfo.refType),
                                                PsWasmInstruction.localGet 0,
                                                PsWasmInstruction.localGet 1,
                                                PsWasmInstruction.localGet 2,
                                                psWasmArrayGetInstruction
                                                  inputInfo.typeName
                                                  inputInfo.elementType,
                                                PsWasmInstruction.localGet 0,
                                                PsWasmInstruction.structGet
                                                  baseName
                                                  0,
                                                PsWasmInstruction.refCastFunction
                                                  codeTypeName
                                            ] (psListAppend
                                              (psWasmCallValueInstructions outputType
                                                (PsWasmInstruction.callRef codeTypeName))
                                              [
                                                PsWasmInstruction.localSet 4,
                                                PsWasmInstruction.localGet 3,
                                                PsWasmInstruction.localGet 2,
                                                PsWasmInstruction.localGet 4,
                                                PsWasmInstruction.arraySet
                                                  outputInfo.typeName,
                                                PsWasmInstruction.localGet 0,
                                                PsWasmInstruction.localGet 1,
                                                PsWasmInstruction.localGet 2,
                                                PsWasmInstruction.i32Const 1,
                                                PsWasmInstruction.i32Add,
                                                PsWasmInstruction.localGet 3,
                                                PsWasmInstruction.call helperName,
                                              PsWasmInstruction.else_,
                                                PsWasmInstruction.localGet 3,
                                              PsWasmInstruction.end_
                                            ])
                                          };
                                          let finalState : PsWasmLowerState :=
                                            psWasmAppendGeneratedFunction
                                              advancedState
                                              helperFunction
                                              false;
                                          Except.ok {
                                            instructions :=
                                              psListAppend
                                                loweredFunction.instructions
                                                (psListAppend
                                                  [
                                                    PsWasmInstruction.localSet
                                                      functionLocal
                                                  ]
                                                  (psListAppend
                                                    loweredArray.instructions
                                                    (psListAppend [
                                                      PsWasmInstruction.localSet
                                                        arrayLocal,
                                                      PsWasmInstruction.localGet
                                                        arrayLocal,
                                                      PsWasmInstruction.arrayLen,
                                                      PsWasmInstruction.i32Const 0,
                                                      PsWasmInstruction.i32Eq,
                                                      PsWasmInstruction.ifStart
                                                        (Option.some
                                                          outputInfo.refType),
                                                        PsWasmInstruction.arrayNewFixed
                                                          outputInfo.typeName
                                                          0,
                                                      PsWasmInstruction.else_,
                                                        PsWasmInstruction.localGet
                                                          functionLocal,
                                                        PsWasmInstruction.localGet
                                                          arrayLocal,
                                                        PsWasmInstruction.i32Const
                                                          0,
                                                        psWasmArrayGetInstruction
                                                          inputInfo.typeName
                                                          inputInfo.elementType,
                                                        PsWasmInstruction.localGet
                                                          functionLocal,
                                                        PsWasmInstruction.structGet
                                                          baseName
                                                          0,
                                                        PsWasmInstruction.refCastFunction
                                                          codeTypeName
                                                    ] (psListAppend
                                                      (psWasmCallValueInstructions outputType
                                                        (PsWasmInstruction.callRef codeTypeName))
                                                      [
                                                        PsWasmInstruction.localGet
                                                          arrayLocal,
                                                        PsWasmInstruction.arrayLen,
                                                        PsWasmInstruction.arrayNew
                                                          outputInfo.typeName,
                                                        PsWasmInstruction.localSet
                                                          outputLocal,
                                                        PsWasmInstruction.localGet
                                                          functionLocal,
                                                        PsWasmInstruction.localGet
                                                          arrayLocal,
                                                        PsWasmInstruction.i32Const
                                                          1,
                                                        PsWasmInstruction.localGet
                                                          outputLocal,
                                                        PsWasmInstruction.call
                                                          helperName,
                                                      PsWasmInstruction.end_
                                                    ]))))
                                            state := finalState
                                          }

def psWasmLowerArrayFoldlWith
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
  match typeArguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons elementType typeRest =>
      match typeRest with
      | List.nil =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.cons accumulatorType typeTail =>
          match typeTail with
          | List.cons _ _ =>
              Except.error PsWasmLowerError.invalidIntrinsicArity
          | List.nil =>
              match
                  psWasmResolveArrayLowerInfo
                    profile
                    (List.cons elementType List.nil) with
              | Except.error error => Except.error error
              | Except.ok arrayInfo =>
                  match
                      psWasmValueTypeOfIrType?
                        profile
                        accumulatorType with
                  | Option.none =>
                      Except.error PsWasmLowerError.unsupportedType
                  | Option.some accumulatorValueType =>
                      match arguments with
                      | List.nil =>
                          Except.error
                            PsWasmLowerError.invalidIntrinsicArity
                      | List.cons fn argumentRest =>
                          match argumentRest with
                          | List.nil =>
                              Except.error
                                PsWasmLowerError.invalidIntrinsicArity
                          | List.cons init afterInit =>
                              match afterInit with
                              | List.nil =>
                                  Except.error
                                    PsWasmLowerError.invalidIntrinsicArity
                              | List.cons array afterArray =>
                                  match afterArray with
                                  | List.nil =>
                                      Except.error
                                        PsWasmLowerError.invalidIntrinsicArity
                                  | List.cons start afterStart =>
                                      match afterStart with
                                      | List.nil =>
                                          Except.error
                                            PsWasmLowerError.invalidIntrinsicArity
                                      | List.cons stop finalArguments =>
                                          match finalArguments with
                                          | List.cons _ _ =>
                                              Except.error
                                                PsWasmLowerError.invalidIntrinsicArity
                                          | List.nil =>
                                              let parameterTypes :
                                                  List PsVerifiedIrType :=
                                                List.cons
                                                  accumulatorType
                                                  (List.cons
                                                    elementType
                                                    List.nil);
                                              let functionType :
                                                  PsVerifiedIrType :=
                                                PsVerifiedIrType.function
                                                  parameterTypes
                                                  accumulatorType;
                                              match
                                                  psWasmClosureBaseName
                                                    functionType with
                                              | Option.none =>
                                                  Except.error
                                                    PsWasmLowerError.unsupportedType
                                              | Option.some baseName =>
                                                  match
                                                      psWasmClosureCodeTypeName
                                                        functionType with
                                                  | Option.none =>
                                                      Except.error
                                                        PsWasmLowerError.unsupportedType
                                                  | Option.some codeTypeName =>
                                                      match
                                                          psWasmLowerHigherOrderFunctionValueWith
                                                            profile
                                                            lower
                                                            state
                                                            fn
                                                            parameterTypes
                                                            accumulatorType with
                                                      | Except.error error =>
                                                          Except.error error
                                                      | Except.ok loweredFunction =>
                                                          let allocatedFunction :=
                                                            psWasmAddLocal
                                                              loweredFunction.state
                                                              (PsWasmValueType.refT
                                                                baseName);
                                                          let functionLocal : Nat :=
                                                            Prod.fst
                                                              allocatedFunction;
                                                          match
                                                              lower
                                                                (Option.some
                                                                  accumulatorValueType)
                                                                (Prod.snd
                                                                  allocatedFunction)
                                                                init with
                                                          | Except.error error =>
                                                              Except.error error
                                                          | Except.ok loweredInit =>
                                                              let allocatedInit :=
                                                                psWasmAddLocal
                                                                  loweredInit.state
                                                                  accumulatorValueType;
                                                              let initLocal : Nat :=
                                                                Prod.fst
                                                                  allocatedInit;
                                                              match
                                                                  lower
                                                                    (Option.some
                                                                      arrayInfo.refType)
                                                                    (Prod.snd
                                                                      allocatedInit)
                                                                    array with
                                                              | Except.error error =>
                                                                  Except.error error
                                                              | Except.ok loweredArray =>
                                                                  let allocatedArray :=
                                                                    psWasmAddLocal
                                                                      loweredArray.state
                                                                      arrayInfo.refType;
                                                                  let arrayLocal : Nat :=
                                                                    Prod.fst
                                                                      allocatedArray;
                                                                  match
                                                                      lower
                                                                        (Option.some
                                                                          psWasmNatRef)
                                                                        (Prod.snd
                                                                          allocatedArray)
                                                                        start with
                                                                  | Except.error error =>
                                                                      Except.error error
                                                                  | Except.ok loweredStart =>
                                                                      let allocatedStart :=
                                                                        psWasmAddLocal
                                                                          loweredStart.state
                                                                          psWasmNatRef;
                                                                      let startLocal : Nat :=
                                                                        Prod.fst
                                                                          allocatedStart;
                                                                      match
                                                                          lower
                                                                            (Option.some
                                                                              psWasmNatRef)
                                                                            (Prod.snd
                                                                              allocatedStart)
                                                                            stop with
                                                                      | Except.error error =>
                                                                          Except.error error
                                                                      | Except.ok loweredStop =>
                                                                          let allocatedStop :=
                                                                            psWasmAddLocal
                                                                              loweredStop.state
                                                                              psWasmNatRef;
                                                                          let stopLocal : Nat :=
                                                                            Prod.fst
                                                                              allocatedStop;
                                                                          let allocatedEnd :=
                                                                            psWasmAddLocal
                                                                              (Prod.snd
                                                                                allocatedStop)
                                                                              PsWasmValueType.i32;
                                                                          let endLocal : Nat :=
                                                                            Prod.fst
                                                                              allocatedEnd;
                                                                          let helperState :
                                                                              PsWasmLowerState :=
                                                                            Prod.snd
                                                                              allocatedEnd;
                                                                          let helperId : Nat :=
                                                                            helperState.nextLambdaId;
                                                                          let helperName : String :=
                                                                            String.Internal.append
                                                                              helperState.currentDefinition
                                                                              (String.Internal.append
                                                                                "$arrayFoldl$"
                                                                                (psNatToString
                                                                                  helperId));
                                                                          let advancedState :
                                                                              PsWasmLowerState :=
                                                                            psWasmAdvanceGeneratedId
                                                                              helperState;
                                                                          let helperFunction :
                                                                              PsWasmFunction := {
                                                                            name := helperName
                                                                            typeName := Option.none
                                                                            parameters := [
                                                                              PsWasmValueType.refT
                                                                                baseName,
                                                                              arrayInfo.refType,
                                                                              PsWasmValueType.i32,
                                                                              PsWasmValueType.i32,
                                                                              accumulatorValueType
                                                                            ]
                                                                            results := [
                                                                              accumulatorValueType
                                                                            ]
                                                                            locals := [
                                                                              accumulatorValueType
                                                                            ]
                                                                            body := psListAppend [
                                                                              PsWasmInstruction.localGet
                                                                                2,
                                                                              PsWasmInstruction.localGet
                                                                                3,
                                                                              PsWasmInstruction.i32LtU,
                                                                              PsWasmInstruction.ifStart
                                                                                (Option.some
                                                                                  accumulatorValueType),
                                                                                PsWasmInstruction.localGet
                                                                                  0,
                                                                                PsWasmInstruction.localGet
                                                                                  4,
                                                                                PsWasmInstruction.localGet
                                                                                  1,
                                                                                PsWasmInstruction.localGet
                                                                                  2,
                                                                                psWasmArrayGetInstruction
                                                                                  arrayInfo.typeName
                                                                                  arrayInfo.elementType,
                                                                                PsWasmInstruction.localGet
                                                                                  0,
                                                                                PsWasmInstruction.structGet
                                                                                  baseName
                                                                                  0,
                                                                                PsWasmInstruction.refCastFunction
                                                                                  codeTypeName
                                                                            ] (psListAppend
                                                                              (psWasmCallValueInstructions accumulatorType
                                                                                (PsWasmInstruction.callRef codeTypeName))
                                                                              [
                                                                                PsWasmInstruction.localSet
                                                                                  5,
                                                                                PsWasmInstruction.localGet
                                                                                  0,
                                                                                PsWasmInstruction.localGet
                                                                                  1,
                                                                                PsWasmInstruction.localGet
                                                                                  2,
                                                                                PsWasmInstruction.i32Const
                                                                                  1,
                                                                                PsWasmInstruction.i32Add,
                                                                                PsWasmInstruction.localGet
                                                                                  3,
                                                                                PsWasmInstruction.localGet
                                                                                  5,
                                                                                PsWasmInstruction.call
                                                                                  helperName,
                                                                              PsWasmInstruction.else_,
                                                                                PsWasmInstruction.localGet
                                                                                  4,
                                                                              PsWasmInstruction.end_
                                                                            ])
                                                                          };
                                                                          let finalState :
                                                                              PsWasmLowerState :=
                                                                            psWasmAppendGeneratedFunction
                                                                              advancedState
                                                                              helperFunction
                                                                              false;
                                                                          let foldInstructions :
                                                                              List PsWasmInstruction := [
                                                                            PsWasmInstruction.localSet
                                                                              stopLocal,
                                                                            PsWasmInstruction.localGet
                                                                              startLocal,
                                                                            PsWasmInstruction.call
                                                                              psWasmNatFitsU32Fn,
                                                                            PsWasmInstruction.ifStart
                                                                              (Option.some
                                                                                accumulatorValueType),
                                                                              PsWasmInstruction.localGet
                                                                                stopLocal,
                                                                              PsWasmInstruction.call
                                                                                psWasmNatFitsU32Fn,
                                                                              PsWasmInstruction.ifStart
                                                                                (Option.some
                                                                                  PsWasmValueType.i32),
                                                                                PsWasmInstruction.localGet
                                                                                  stopLocal,
                                                                                PsWasmInstruction.call
                                                                                  psWasmNatToU32Fn,
                                                                                PsWasmInstruction.localGet
                                                                                  arrayLocal,
                                                                                PsWasmInstruction.arrayLen,
                                                                                PsWasmInstruction.i32LeU,
                                                                                PsWasmInstruction.ifStart
                                                                                  (Option.some
                                                                                    PsWasmValueType.i32),
                                                                                  PsWasmInstruction.localGet
                                                                                    stopLocal,
                                                                                  PsWasmInstruction.call
                                                                                    psWasmNatToU32Fn,
                                                                                PsWasmInstruction.else_,
                                                                                  PsWasmInstruction.localGet
                                                                                    arrayLocal,
                                                                                  PsWasmInstruction.arrayLen,
                                                                                PsWasmInstruction.end_,
                                                                              PsWasmInstruction.else_,
                                                                                PsWasmInstruction.localGet
                                                                                  arrayLocal,
                                                                                PsWasmInstruction.arrayLen,
                                                                              PsWasmInstruction.end_,
                                                                              PsWasmInstruction.localSet
                                                                                endLocal,
                                                                              PsWasmInstruction.localGet
                                                                                functionLocal,
                                                                              PsWasmInstruction.localGet
                                                                                arrayLocal,
                                                                              PsWasmInstruction.localGet
                                                                                startLocal,
                                                                              PsWasmInstruction.call
                                                                                psWasmNatToU32Fn,
                                                                              PsWasmInstruction.localGet
                                                                                endLocal,
                                                                              PsWasmInstruction.localGet
                                                                                initLocal,
                                                                              PsWasmInstruction.call
                                                                                helperName,
                                                                            PsWasmInstruction.else_,
                                                                              PsWasmInstruction.localGet
                                                                                initLocal,
                                                                            PsWasmInstruction.end_
                                                                          ];
                                                                          let withStopInstructions :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              loweredStop.instructions
                                                                              foldInstructions;
                                                                          let withStartStore :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              [
                                                                                PsWasmInstruction.localSet
                                                                                  startLocal
                                                                              ]
                                                                              withStopInstructions;
                                                                          let withStartInstructions :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              loweredStart.instructions
                                                                              withStartStore;
                                                                          let withArrayStore :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              [
                                                                                PsWasmInstruction.localSet
                                                                                  arrayLocal
                                                                              ]
                                                                              withStartInstructions;
                                                                          let withArrayInstructions :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              loweredArray.instructions
                                                                              withArrayStore;
                                                                          let withInitStore :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              [
                                                                                PsWasmInstruction.localSet
                                                                                  initLocal
                                                                              ]
                                                                              withArrayInstructions;
                                                                          let withInitInstructions :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              loweredInit.instructions
                                                                              withInitStore;
                                                                          let withFunctionStore :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              [
                                                                                PsWasmInstruction.localSet
                                                                                  functionLocal
                                                                              ]
                                                                              withInitInstructions;
                                                                          let allInstructions :
                                                                              List PsWasmInstruction :=
                                                                            psListAppend
                                                                              loweredFunction.instructions
                                                                              withFunctionStore;
                                                                          Except.ok {
                                                                            instructions :=
                                                                              allInstructions
                                                                            state := finalState
                                                                          }

def psWasmLowerBoolUnaryWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons value rest =>
      match rest with
      | List.cons _ _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.nil =>
          match
              lower
                (Option.some PsWasmValueType.i32)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [
                      PsWasmInstruction.i32Const 0,
                      PsWasmInstruction.i32Eq
                    ]
                state := lowered.state
              }

def psWasmLowerBoolBinaryWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (instruction : PsWasmInstruction)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.none =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | Option.some pair =>
      let left := Prod.fst pair;
      let right := Prod.snd pair;
      match
          psWasmLowerExprListWith
            lower
            (Option.some PsWasmValueType.i32)
            state
            [left, right] with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend
                lowered.instructions
                [instruction]
            state := lowered.state
          }

def psWasmLowerCharOfNatWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons value rest =>
      match rest with
      | List.cons _ _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.nil =>
          match lower (Option.some psWasmNatRef) state value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              let allocatedNat :=
                psWasmAddLocal lowered.state psWasmNatRef;
              let natLocal := Prod.fst allocatedNat;
              let allocatedCodepoint :=
                psWasmAddLocal
                  (Prod.snd allocatedNat)
                  PsWasmValueType.i32;
              let codepointLocal := Prod.fst allocatedCodepoint;
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [
                      PsWasmInstruction.localSet natLocal,
                      PsWasmInstruction.localGet natLocal,
                      PsWasmInstruction.call psWasmNatFitsU32Fn,
                      PsWasmInstruction.ifStart
                        (Option.some PsWasmValueType.i32),
                        PsWasmInstruction.localGet natLocal,
                        PsWasmInstruction.call psWasmNatToU32Fn,
                        PsWasmInstruction.localSet codepointLocal,
                        PsWasmInstruction.localGet codepointLocal,
                        PsWasmInstruction.i32Const 55296,
                        PsWasmInstruction.i32LtU,
                        PsWasmInstruction.ifStart
                          (Option.some PsWasmValueType.i32),
                          PsWasmInstruction.localGet codepointLocal,
                        PsWasmInstruction.else_,
                          PsWasmInstruction.localGet codepointLocal,
                          PsWasmInstruction.i32Const 57343,
                          PsWasmInstruction.i32GtU,
                          PsWasmInstruction.localGet codepointLocal,
                          PsWasmInstruction.i32Const 1114112,
                          PsWasmInstruction.i32LtU,
                          PsWasmInstruction.i32And,
                          PsWasmInstruction.ifStart
                            (Option.some PsWasmValueType.i32),
                            PsWasmInstruction.localGet codepointLocal,
                          PsWasmInstruction.else_,
                            PsWasmInstruction.i32Const 0,
                          PsWasmInstruction.end_,
                        PsWasmInstruction.end_,
                      PsWasmInstruction.else_,
                        PsWasmInstruction.i32Const 0,
                      PsWasmInstruction.end_
                    ]
                state := Prod.snd allocatedCodepoint
              }

def psWasmLowerCharToNatWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons value rest =>
      match rest with
      | List.cons _ _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.nil =>
          match
              lower
                (Option.some PsWasmValueType.i32)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [PsWasmInstruction.call psWasmNatOfU32Fn]
                state := lowered.state
              }

def psWasmLowerStringUnaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons value rest =>
      match rest with
      | List.cons _ _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.nil =>
          match
              lower
                (Option.some psWasmStringRef)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [PsWasmInstruction.call functionName]
                state := lowered.state
              }

def psWasmLowerCharToStringUnaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match arguments with
  | List.nil =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | List.cons value rest =>
      match rest with
      | List.cons _ _ =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.nil =>
          match
              lower
                (Option.some PsWasmValueType.i32)
                state
                value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    [PsWasmInstruction.call functionName]
                state := lowered.state
              }

def psWasmLowerStringBinaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.none =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | Option.some pair =>
      match
          psWasmLowerExprListWith
            lower
            (Option.some psWasmStringRef)
            state
            [Prod.fst pair, Prod.snd pair] with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          Except.ok {
            instructions :=
              psListAppend
                lowered.instructions
                [PsWasmInstruction.call functionName]
            state := lowered.state
          }

def psWasmLowerStringCharBinaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.none =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | Option.some pair =>
      match
          lower
            (Option.some psWasmStringRef)
            state
            (Prod.fst pair) with
      | Except.error error => Except.error error
      | Except.ok loweredString =>
          match
              lower
                (Option.some PsWasmValueType.i32)
                loweredString.state
                (Prod.snd pair) with
          | Except.error error => Except.error error
          | Except.ok loweredChar =>
              Except.ok {
                instructions :=
                  psListAppend
                    loweredString.instructions
                    (psListAppend
                      loweredChar.instructions
                      [PsWasmInstruction.call functionName])
                state := loweredChar.state
              }

def psWasmLowerStringNatBinaryCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListPair? arguments with
  | Option.none =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | Option.some pair =>
      match
          lower
            (Option.some psWasmStringRef)
            state
            (Prod.fst pair) with
      | Except.error error => Except.error error
      | Except.ok loweredString =>
          match
              lower
                (Option.some psWasmNatRef)
                loweredString.state
                (Prod.snd pair) with
          | Except.error error => Except.error error
          | Except.ok loweredNat =>
              Except.ok {
                instructions :=
                  psListAppend
                    loweredString.instructions
                    (psListAppend
                      loweredNat.instructions
                      [PsWasmInstruction.call functionName])
                state := loweredNat.state
              }

def psWasmLowerStringNatNatCallWith
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (functionName : String)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match psWasmListTriple? arguments with
  | Option.none =>
      Except.error PsWasmLowerError.invalidIntrinsicArity
  | Option.some triple =>
      let value := Prod.fst triple;
      let positions := Prod.snd triple;
      match
          lower
            (Option.some psWasmStringRef)
            state
            value with
      | Except.error error => Except.error error
      | Except.ok loweredString =>
          match
              lower
                (Option.some psWasmNatRef)
                loweredString.state
                (Prod.fst positions) with
          | Except.error error => Except.error error
          | Except.ok loweredBegin =>
              match
                  lower
                    (Option.some psWasmNatRef)
                    loweredBegin.state
                    (Prod.snd positions) with
              | Except.error error => Except.error error
              | Except.ok loweredEnd =>
                  Except.ok {
                    instructions :=
                      psListAppend
                        loweredString.instructions
                        (psListAppend
                          loweredBegin.instructions
                          (psListAppend
                            loweredEnd.instructions
                            [PsWasmInstruction.call functionName]))
                    state := loweredEnd.state
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
    (typeArguments : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match operation with
  | .machineIntBinary type integerOperation =>
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let left := Prod.fst pair;
          let right := Prod.snd pair;
          let expected :=
            Option.some (psWasmMachineIntegerValueType profile type);
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    (psWasmLowerMachineIntegerBinary
                      profile type integerOperation)
                state := lowered.state
              }
  | .machineIntCompare type integerOperation =>
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let left := Prod.fst pair;
          let right := Prod.snd pair;
          let expected :=
            Option.some (psWasmMachineIntegerValueType profile type);
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    (psWasmLowerMachineIntegerCompare
                      profile type integerOperation)
                state := lowered.state
              }
  | .uint8OfNat =>
      match arguments with
      | List.nil =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | List.cons value rest =>
          match rest with
          | List.cons _ _ =>
              Except.error PsWasmLowerError.invalidIntrinsicArity
          | List.nil =>
              match
                  lower
                    (Option.some psWasmNatRef)
                    state
                    value with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    instructions :=
                      psListAppend
                        lowered.instructions
                        [
                          PsWasmInstruction.call psWasmNatToU32Fn,
                          PsWasmInstruction.i32Const 255,
                          PsWasmInstruction.i32And
                        ]
                    state := lowered.state
                  }
  | .floatBinary type floatOperation =>
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let left := Prod.fst pair;
          let right := Prod.snd pair;
          let expected := Option.some (psWasmFloatingValueType type);
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    (psWasmLowerFloatBinary type floatOperation)
                state := lowered.state
              }
  | .floatCompare type floatOperation =>
      match psWasmListPair? arguments with
      | Option.none =>
          Except.error PsWasmLowerError.invalidIntrinsicArity
      | Option.some pair =>
          let left := Prod.fst pair;
          let right := Prod.snd pair;
          let expected := Option.some (psWasmFloatingValueType type);
          match
              psWasmLowerExprListWith
                lower expected state [left, right] with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok {
                instructions :=
                  psListAppend
                    lowered.instructions
                    (psWasmLowerFloatCompare type floatOperation)
                state := lowered.state
              }
  | .natAdd =>
      psWasmLowerNatBinaryCallWith
        lower state psWasmNatAddFn arguments
  | .natSub =>
      psWasmLowerNatBinaryCallWith
        lower state psWasmNatSubFn arguments
  | .natMul =>
      psWasmLowerNatBinaryCallWith
        lower state psWasmNatMulFn arguments
  | .natDiv =>
      psWasmLowerNatBinaryCallWith
        lower state psWasmNatDivFn arguments
  | .natMod =>
      psWasmLowerNatBinaryCallWith
        lower state psWasmNatModFn arguments
  | .natEq =>
      psWasmLowerNatCompareWith
        lower state PsWasmInstruction.i32Eq arguments
  | .natNe =>
      psWasmLowerNatCompareWith
        lower state PsWasmInstruction.i32Ne arguments
  | .natLe =>
      psWasmLowerNatCompareWith
        lower state PsWasmInstruction.i32LeS arguments
  | .natLt =>
      psWasmLowerNatCompareWith
        lower state PsWasmInstruction.i32LtS arguments
  | .intOfNat =>
      psWasmLowerNatToIntUnaryCallWith
        lower state psWasmIntOfNatFn arguments
  | .intRepr =>
      psWasmLowerIntUnaryCallWith
        lower state psWasmIntReprFn arguments
  | .intNegSucc =>
      psWasmLowerNatToIntUnaryCallWith
        lower state psWasmIntNegSuccFn arguments
  | .intNeg =>
      psWasmLowerIntUnaryCallWith
        lower state psWasmIntNegFn arguments
  | .intAdd =>
      psWasmLowerIntBinaryCallWith
        lower state psWasmIntAddFn arguments
  | .intSub =>
      psWasmLowerIntBinaryCallWith
        lower state psWasmIntSubFn arguments
  | .intMul =>
      psWasmLowerIntBinaryCallWith
        lower state psWasmIntMulFn arguments
  | .intEq =>
      psWasmLowerIntCompareWith
        lower state PsWasmInstruction.i32Eq arguments
  | .intLe =>
      psWasmLowerIntCompareWith
        lower state PsWasmInstruction.i32LeS arguments
  | .intLt =>
      psWasmLowerIntCompareWith
        lower state PsWasmInstruction.i32LtS arguments
  | .boolNot =>
      psWasmLowerBoolUnaryWith
        lower state arguments
  | .boolAnd =>
      psWasmLowerBoolBinaryWith
        lower state PsWasmInstruction.i32And arguments
  | .boolOr =>
      psWasmLowerBoolBinaryWith
        lower state PsWasmInstruction.i32Or arguments
  | .boolEq =>
      psWasmLowerBoolBinaryWith
        lower state PsWasmInstruction.i32Eq arguments
  | .boolNe =>
      psWasmLowerBoolBinaryWith
        lower state PsWasmInstruction.i32Ne arguments
  | .charOfNat =>
      psWasmLowerCharOfNatWith
        lower state arguments
  | .charToNat =>
      psWasmLowerCharToNatWith
        lower state arguments
  | .stringPush =>
      psWasmLowerStringCharBinaryCallWith
        lower state psWasmStringPushFn arguments
  | .stringSingleton =>
      psWasmLowerCharToStringUnaryCallWith
        lower state psWasmStringSingletonFn arguments
  | .stringLength =>
      psWasmLowerStringUnaryCallWith
        lower state psWasmStringLengthFn arguments
  | .stringAppend =>
      psWasmLowerStringBinaryCallWith
        lower state psWasmStringAppendFn arguments
  | .stringUtf8ByteSize =>
      psWasmLowerStringUnaryCallWith
        lower state psWasmStringUtf8ByteSizeFn arguments
  | .stringNext =>
      psWasmLowerStringNatBinaryCallWith
        lower state psWasmStringNextFn arguments
  | .stringGet =>
      psWasmLowerStringNatBinaryCallWith
        lower state psWasmStringGetFn arguments
  | .stringAtEnd =>
      psWasmLowerStringNatBinaryCallWith
        lower state psWasmStringAtEndFn arguments
  | .stringExtract =>
      psWasmLowerStringNatNatCallWith
        lower state psWasmStringExtractFn arguments
  | .stringEq =>
      psWasmLowerStringBinaryCallWith
        lower state psWasmStringEqFn arguments
  | .arrayEmptyWithCapacity =>
      psWasmLowerArrayEmptyWithCapacityWith
        profile lower state typeArguments arguments
  | .arraySize =>
      psWasmLowerArraySizeWith
        profile lower state typeArguments arguments
  | .arrayPush =>
      psWasmLowerArrayPushWith
        profile lower state typeArguments arguments
  | .arrayGet =>
      psWasmLowerArrayGetWith
        profile lower state typeArguments arguments
  | .arrayGetD =>
      psWasmLowerArrayGetDWith
        profile lower state typeArguments arguments
  | .arraySet =>
      psWasmLowerArraySetWith
        profile lower state typeArguments arguments
  | .arraySetIfInBounds =>
      psWasmLowerArraySetIfInBoundsWith
        profile lower state typeArguments arguments
  | .arrayMap =>
      psWasmLowerArrayMapWith
        profile lower state typeArguments arguments
  | .arrayFoldl =>
      psWasmLowerArrayFoldlWith
        profile lower state typeArguments arguments

def psWasmLowerTypedArgumentsWorker
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (types : List PsVerifiedIrType) :
    List PsVerifiedIrExpr ->
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match types with
  | List.nil =>
      fun (arguments : List PsVerifiedIrExpr) =>
        fun (state : PsWasmLowerState) =>
          match arguments with
          | List.nil =>
              Except.ok {
                instructions := []
                state := state
              }
          | List.cons _ _ =>
              Except.error PsWasmLowerError.invalidCallArity
  | List.cons type restTypes =>
      let smaller :
          List PsVerifiedIrExpr ->
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerTypedArgumentsWorker
          profile
          lower
          restTypes;
      fun (arguments : List PsVerifiedIrExpr) =>
        fun (state : PsWasmLowerState) =>
          match arguments with
          | List.nil =>
              Except.error PsWasmLowerError.invalidCallArity
          | List.cons argument restArguments =>
              match psWasmValueTypeOfIrType? profile type with
              | Option.none =>
                  Except.error PsWasmLowerError.unsupportedType
              | Option.some expected =>
                  match lower (Option.some expected) state argument with
                  | Except.error error => Except.error error
                  | Except.ok lowered =>
                      match smaller restArguments lowered.state with
                      | Except.error error => Except.error error
                      | Except.ok loweredRest =>
                          Except.ok {
                            instructions :=
                              psListAppend
                                lowered.instructions
                                loweredRest.instructions
                            state := loweredRest.state
                          }

def psWasmLowerTypedArgumentsWith
    (profile : PsWasmTargetProfile)
    (lower :
      Option PsWasmValueType ->
      PsWasmLowerState ->
      PsVerifiedIrExpr ->
        Except PsWasmLowerError PsWasmLoweredExpr)
    (state : PsWasmLowerState)
    (types : List PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerTypedArgumentsWorker
    profile
    lower
    types
    arguments
    state

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
    PsVerifiedIrType.function parameterTypes resultType;
  match psWasmClosureBaseName functionType with
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some baseName =>
      match psWasmClosureCodeTypeName functionType with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some codeTypeName =>
          let allocated :=
            psWasmAddLocal
              state
              (PsWasmValueType.refT baseName);
          let closureLocal := (Prod.fst allocated);
          let nextState := (Prod.snd allocated);
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
                  psListAppend
                    [
                                        PsWasmInstruction.localGet binding.index,
                                        PsWasmInstruction.localSet closureLocal,
                                        PsWasmInstruction.localGet closureLocal
                                      ]
                    (psListAppend
                      loweredArguments.instructions
                      (psListAppend
                        [PsWasmInstruction.localGet closureLocal,
                          PsWasmInstruction.structGet baseName 0,
                          PsWasmInstruction.refCastFunction codeTypeName]
                        (psWasmCallValueInstructions resultType
                          (PsWasmInstruction.callRef codeTypeName))))
                state := loweredArguments.state
              }

def psWasmBindingTypes
    (bindings : List PsWasmBinding) :
    List (String × PsVerifiedIrType) :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest =>
      List.cons
        (Prod.mk binding.name binding.type)
        (psWasmBindingTypes rest)

def psWasmLowerCallWith
    (profile : PsWasmTargetProfile)
    (module : PsVerifiedIrModule)
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
      | Option.some binding =>
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
              Except.error
                (PsWasmLowerError.unsupportedExpressionContext
                  state.currentDefinition
                  (String.Internal.append
                    "call-binding-not-function:"
                    name))
      | Option.none =>
          match psStrictFindDeclaration module.declarations name with
          | Option.none => Except.error (PsWasmLowerError.unknownVariable name)
          | Option.some declaration =>
              match
                  psWasmLowerTypedArgumentsWith profile lower state
                    (psWasmParameterTypes declaration.parameters) arguments with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    instructions :=
                      psListAppend lowered.instructions
                        (psWasmCallValueInstructions declaration.resultType
                          (PsWasmInstruction.call name))
                    state := lowered.state
                  }
  | _ =>
      match
          psStrictInferExprWithFuel
            module List.nil 4096 (psWasmBindingTypes bindings) fn with
      | Except.error _ =>
          Except.error
            (PsWasmLowerError.unsupportedExpressionContext
              state.currentDefinition "call-target-type")
      | Except.ok functionType =>
          match functionType with
          | .function parameterTypes resultType =>
              match psWasmLowerParameterType profile functionType with
              | Except.error error => Except.error error
              | Except.ok valueType =>
                  match lower (Option.some valueType) state fn with
                  | Except.error error => Except.error error
                  | Except.ok loweredFunction =>
                      let allocated : Nat × PsWasmLowerState :=
                        psWasmAddLocal loweredFunction.state valueType;
                      let index : Nat := Prod.fst allocated;
                      let binding : PsWasmBinding :=
                        PsWasmBinding.mk "" index functionType;
                      match
                          psWasmLowerFunctionValueCall
                            profile lower (Prod.snd allocated) binding
                            parameterTypes resultType arguments with
                      | Except.error error => Except.error error
                      | Except.ok loweredCall =>
                          Except.ok {
                            instructions :=
                              psListAppend loweredFunction.instructions
                                (List.cons (PsWasmInstruction.localSet index)
                                  loweredCall.instructions)
                            state := loweredCall.state
                          }
          | _ =>
              Except.error
                (PsWasmLowerError.unsupportedExpressionContext
                  state.currentDefinition "call-target-not-function")

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
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some resultType =>
      match
          lower
            (Option.some PsWasmValueType.i32)
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
                      psListAppend
                        conditionCode.instructions
                        (psListAppend
                          [PsWasmInstruction.ifStart (Option.some resultType)]
                          (psListAppend
                            thenCode.instructions
                            (psListAppend
                              [PsWasmInstruction.else_]
                              (psListAppend
                                elseCode.instructions
                                [PsWasmInstruction.end_]))))
                    state := elseCode.state
                  }

def psWasmLowerMatchBindingsWorker
    (profile : PsWasmTargetProfile)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor)
    (scrutineeLocal : Nat)
    (matchBindings : List PsVerifiedIrMatchBinding) :
    List PsWasmBinding ->
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredBindings :=
  match matchBindings with
  | List.nil =>
      fun (baseBindings : List PsWasmBinding) =>
        fun (state : PsWasmLowerState) =>
          Except.ok {
            instructions := []
            bindings := baseBindings
            state := state
          }
  | List.cons binding rest =>
      let smaller :
          List PsWasmBinding ->
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredBindings :=
        psWasmLowerMatchBindingsWorker
          profile
          inductiveName
          constructorInfo
          scrutineeLocal
          rest;
      fun (baseBindings : List PsWasmBinding) =>
        fun (state : PsWasmLowerState) =>
          match
              psWasmFindConstructorField
                constructorInfo
                binding.field with
          | Option.none =>
              Except.error
                (PsWasmLowerError.unknownConstructorField
                  inductiveName
                  constructorInfo.name
                  binding.field)
          | Option.some indexedField =>
              let fieldIndex := Prod.fst indexedField;
              let field := Prod.snd indexedField;
              match psWasmValueTypeOfIrType? profile field.type with
              | Option.none =>
                  Except.error PsWasmLowerError.unsupportedType
              | Option.some valueType =>
                  let allocated := psWasmAddLocal state valueType;
                  let localIndex := Prod.fst allocated;
                  let nextState := Prod.snd allocated;
                  let constructorType :=
                    psWasmConstructorTypeName
                      inductiveName
                      constructorInfo.name;
                  let fieldCode := [
                    PsWasmInstruction.localGet scrutineeLocal,
                    PsWasmInstruction.refCast constructorType,
                    psWasmStructGetInstruction
                      constructorType
                      fieldIndex
                      field.type,
                    PsWasmInstruction.localSet localIndex
                  ];
                  match
                      smaller
                        (List.cons
                          (PsWasmBinding.mk
                            binding.name
                            localIndex
                            field.type)
                          baseBindings)
                        nextState with
                  | Except.error error => Except.error error
                  | Except.ok loweredRest =>
                      Except.ok {
                        instructions :=
                          psListAppend
                            fieldCode
                            loweredRest.instructions
                        bindings := loweredRest.bindings
                        state := loweredRest.state
                      }

def psWasmLowerMatchBindings
    (profile : PsWasmTargetProfile)
    (inductiveName : String)
    (constructorInfo : PsVerifiedIrConstructor)
    (scrutineeLocal : Nat)
    (baseBindings : List PsWasmBinding)
    (state : PsWasmLowerState)
    (matchBindings : List PsVerifiedIrMatchBinding) :
    Except PsWasmLowerError PsWasmLoweredBindings :=
  psWasmLowerMatchBindingsWorker
    profile
    inductiveName
    constructorInfo
    scrutineeLocal
    matchBindings
    baseBindings
    state

def psWasmLowerMatchAlternativesWorker
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
    (expected : Option PsWasmValueType)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match alternatives with
  | List.nil =>
      fun (state : PsWasmLowerState) =>
        Except.error
          (PsWasmLowerError.unsupportedExpressionContext
            state.currentDefinition
            "empty-match")
  | List.cons alternative rest =>
      let smaller :
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerMatchAlternativesWorker
          profile
          inductiveInfo
          scrutineeLocal
          lowerWithBindings
          baseBindings
          expected
          rest;
      fun (state : PsWasmLowerState) =>
        let constructorName := Prod.fst alternative;
        let matchBindings :=
          Prod.fst (Prod.snd alternative);
        let body :=
          Prod.snd (Prod.snd alternative);
        match rest with
        | List.nil =>
            match
                psWasmFindConstructor
                  inductiveInfo.constructors
                  constructorName with
            | Option.none =>
                Except.error
                  (PsWasmLowerError.unknownConstructor
                    inductiveInfo.name
                    constructorName)
            | Option.some constructorInfo =>
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
                            psListAppend
                              loweredBindings.instructions
                              loweredBody.instructions
                          state := loweredBody.state
                        }
        | List.cons _ _ =>
            match expected with
            | Option.none =>
                Except.error PsWasmLowerError.unsupportedType
            | Option.some resultType =>
                match
                    psWasmFindConstructor
                      inductiveInfo.constructors
                      constructorName with
                | Option.none =>
                    Except.error
                      (PsWasmLowerError.unknownConstructor
                        inductiveInfo.name
                        constructorName)
                | Option.some constructorInfo =>
                    let constructorType :=
                      psWasmConstructorTypeName
                        inductiveInfo.name
                        constructorName;
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
                        | Except.error error =>
                            Except.error error
                        | Except.ok loweredBody =>
                            match smaller loweredBody.state with
                            | Except.error error =>
                                Except.error error
                            | Except.ok loweredRest =>
                                Except.ok {
                                  instructions :=
                                    psListAppend
                                      (List.cons
                                        (PsWasmInstruction.localGet
                                          scrutineeLocal)
                                        (List.cons
                                          (PsWasmInstruction.refTest
                                            constructorType)
                                          (List.cons
                                            (PsWasmInstruction.ifStart
                                              (Option.some resultType))
                                            List.nil)))
                                      (psListAppend
                                        loweredBindings.instructions
                                        (psListAppend
                                          loweredBody.instructions
                                          (List.cons
                                            PsWasmInstruction.else_
                                            (psListAppend
                                              loweredRest.instructions
                                              (List.cons
                                                PsWasmInstruction.end_
                                                List.nil)))))
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
    (expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerMatchAlternativesWorker
    profile
    inductiveInfo
    scrutineeLocal
    lowerWithBindings
    baseBindings
    expected
    alternatives
    state

def psWasmLowerCaptureFields
    (profile : PsWasmTargetProfile)
    (captures : List PsWasmBinding) :
    Except PsWasmLowerError (List PsWasmStructField) :=
  match captures with
  | List.nil => Except.ok []
  | List.cons capture rest =>
      match psWasmStorageTypeOfIrType? profile capture.type with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some storageType =>
          match psWasmLowerCaptureFields profile rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (List.cons
                  (PsWasmStructField.mk
                    capture.name
                    storageType)
                  loweredRest)

def psWasmPrepareCaptureBindingsWorker
    (profile : PsWasmTargetProfile)
    (subtypeName : String)
    (captures : List PsWasmBinding) :
    Nat ->
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredBindings :=
  match captures with
  | List.nil =>
      fun (_fieldIndex : Nat) =>
        fun (state : PsWasmLowerState) =>
          Except.ok {
            instructions := []
            bindings := []
            state := state
          }
  | List.cons capture rest =>
      let smaller :
          Nat ->
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredBindings :=
        psWasmPrepareCaptureBindingsWorker
          profile
          subtypeName
          rest;
      fun (fieldIndex : Nat) =>
        fun (state : PsWasmLowerState) =>
          match psWasmValueTypeOfIrType? profile capture.type with
          | Option.none =>
              Except.error PsWasmLowerError.unsupportedType
          | Option.some valueType =>
              let allocated := psWasmAddLocal state valueType;
              let localIndex := Prod.fst allocated;
              let nextState := Prod.snd allocated;
              match smaller (Nat.add fieldIndex 1) nextState with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok {
                    instructions :=
                      psListAppend
                        [
                          PsWasmInstruction.localGet 0,
                          PsWasmInstruction.refCast subtypeName,
                          psWasmStructGetInstruction
                            subtypeName
                            fieldIndex
                            capture.type,
                          PsWasmInstruction.localSet localIndex
                        ]
                        loweredRest.instructions
                    bindings :=
                      List.cons
                        (PsWasmBinding.mk
                          capture.name
                          localIndex
                          capture.type)
                        loweredRest.bindings
                    state := loweredRest.state
                  }

def psWasmPrepareCaptureBindings
    (profile : PsWasmTargetProfile)
    (subtypeName : String)
    (fieldIndex : Nat)
    (state : PsWasmLowerState)
    (captures : List PsWasmBinding) :
    Except PsWasmLowerError PsWasmLoweredBindings :=
  psWasmPrepareCaptureBindingsWorker
    profile subtypeName captures fieldIndex state

def psWasmCaptureConstructionInstructions
    (captures : List PsWasmBinding) :
    List PsWasmInstruction :=
  match captures with
  | List.nil => []
  | List.cons capture rest =>
      List.cons
        (PsWasmInstruction.localGet capture.index)
        (psWasmCaptureConstructionInstructions rest)

def psWasmAdvanceLambdaId
    (state : PsWasmLowerState) : PsWasmLowerState :=
  {
    nextLocalIndex := state.nextLocalIndex
    localTypes := state.localTypes
    currentDefinition := state.currentDefinition
    nextLambdaId := Nat.add state.nextLambdaId 1
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
        psListAppend
          generatedState.generatedStructures
          (List.cons subtype List.nil)
      generatedFunctionTypes :=
        generatedState.generatedFunctionTypes
      generatedFunctions :=
        psListAppend
          generatedState.generatedFunctions
          (List.cons function List.nil)
      generatedFunctionRefs :=
        psListAppend
          generatedState.generatedFunctionRefs
          (List.cons function.name List.nil)
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
    psWasmParameterTypes parameters;
  let functionType :=
    PsVerifiedIrType.function parameterTypes resultType;
  match psWasmClosureBaseName functionType with
  | Option.none => Except.error PsWasmLowerError.unsupportedType
  | Option.some baseName =>
      match psWasmClosureCodeTypeName functionType with
      | Option.none => Except.error PsWasmLowerError.unsupportedType
      | Option.some codeTypeName =>
          match psWasmLowerIrTypeList profile parameterTypes with
          | Except.error error => Except.error error
          | Except.ok loweredParameters =>
              match psWasmLowerResultType profile resultType with
              | Except.error error => Except.error error
              | Except.ok results =>
                  match psWasmExpectedResultType results with
                  | Except.error error => Except.error error
                  | Except.ok expected =>
                      let lambdaId := state.nextLambdaId;
                      let lambdaName :=
                        String.Internal.append
                          state.currentDefinition
                          (String.Internal.append
                            "$lambda$"
                            (psNatToString lambdaId));
                      let subtypeName :=
                        String.Internal.append
                          baseName
                          (String.Internal.append
                            "$"
                            (lambdaName));
                      let captures :=
                        psWasmCollectCaptures
                          bindings
                          parameters
                          body;
                      match psWasmLowerCaptureFields profile captures with
                      | Except.error error => Except.error error
                      | Except.ok captureFields =>
                          let subtype : PsWasmStructType := {
                            name := subtypeName
                            superType := Option.some baseName
                            isFinal := true
                            fields :=
                              List.cons
                                (PsWasmStructField.mk
                                  "code"
                                  (PsWasmStorageType.value
                                    PsWasmValueType.funcRef))
                                captureFields
                          };
                          let advancedState :=
                            psWasmAdvanceLambdaId state;
                          let nestedState :=
                            psWasmStateForNestedFunction
                              advancedState
                              (Nat.add (psListLength parameters) 1);
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
                                  parameters;
                              let bodyBindings :=
                                psListAppend
                                  parameterBindings
                                  (preparedCaptures.bindings);
                              match
                                  lowerWithBindings
                                    bodyBindings
                                    (psWasmFunctionBodyExpected resultType expected)
                                    preparedCaptures.state
                                    body with
                              | Except.error error => Except.error error
                              | Except.ok loweredBody =>
                                  let generatedFunction : PsWasmFunction := {
                                    name := lambdaName
                                    typeName := Option.some codeTypeName
                                    parameters :=
                                      List.cons
                                        (PsWasmValueType.refT baseName)
                                        loweredParameters
                                    results := results
                                    locals :=
                                      loweredBody.state.localTypes
                                    body :=
                                      psListAppend
                                        preparedCaptures.instructions
                                        (psWasmFunctionBodyResult resultType loweredBody.instructions)
                                  };
                                  let finalState :=
                                    psWasmAddGeneratedLambda
                                      state
                                      loweredBody.state
                                      subtype
                                      generatedFunction;
                                  Except.ok {
                                    instructions :=
                                      psListAppend
                                        [PsWasmInstruction.refFunc lambdaName]
                                        (psListAppend
                                          (psWasmCaptureConstructionInstructions
                                            captures)
                                          [PsWasmInstruction.structNew
                                            subtypeName])
                                    state := finalState
                                  }

def psWasmGlobalFunctionParameters
    (name : String)
    (parameters : List PsVerifiedIrParameter) :
    Nat -> List PsVerifiedIrParameter :=
  match parameters with
  | List.nil => fun (_index : Nat) => List.nil
  | List.cons parameter rest =>
      let smaller : Nat -> List PsVerifiedIrParameter :=
        psWasmGlobalFunctionParameters name rest;
      fun (index : Nat) =>
        List.cons
          (PsVerifiedIrParameter.mk
            (String.Internal.append name
              (String.Internal.append "$arg$" (psNatToString index)))
            parameter.type)
          (smaller (Nat.succ index))

def psWasmGlobalFunctionArguments
    (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrExpr :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons (PsVerifiedIrExpr.var parameter.name)
        (psWasmGlobalFunctionArguments rest)

def psWasmLowerExprWorker
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (remainingFuel : Nat) :
    List PsWasmBinding ->
    Option PsWasmValueType ->
    PsWasmLowerState ->
    PsVerifiedIrExpr ->
    Except PsWasmLowerError PsWasmLoweredExpr :=
  match remainingFuel with
  | 0 =>
      fun (_bindings : List PsWasmBinding) =>
        fun (_expected : Option PsWasmValueType) =>
          fun (state : PsWasmLowerState) =>
            fun (_expr : PsVerifiedIrExpr) =>
              Except.error
                (PsWasmLowerError.unsupportedExpressionContext
                  state.currentDefinition
                  "fuel-exhausted")
  | fuel + 1 =>
      let smaller :
          List PsWasmBinding ->
          Option PsWasmValueType ->
          PsWasmLowerState ->
          PsVerifiedIrExpr ->
          Except PsWasmLowerError PsWasmLoweredExpr :=
        psWasmLowerExprWorker
          profile
          allDeclarations
          structures
          inductives
          fuel;
      fun (bindings : List PsWasmBinding) =>
        fun (expected : Option PsWasmValueType) =>
          fun (state : PsWasmLowerState) =>
            fun (expr : PsVerifiedIrExpr) =>
              let lowerWithBindings :
                  List PsWasmBinding ->
                  Option PsWasmValueType ->
                  PsWasmLowerState ->
                  PsVerifiedIrExpr ->
                  Except PsWasmLowerError PsWasmLoweredExpr :=
                fun
                (nextBindings : List PsWasmBinding)
                (expectedType : Option PsWasmValueType)
                (nestedState : PsWasmLowerState)
                (nestedExpr : PsVerifiedIrExpr) =>
                  smaller
                    nextBindings
                    expectedType
                    nestedState
                    nestedExpr;
              let lower :
                  Option PsWasmValueType ->
                  PsWasmLowerState ->
                  PsVerifiedIrExpr ->
                  Except PsWasmLowerError PsWasmLoweredExpr :=
                lowerWithBindings bindings;
              match expr with
              | .literal literal =>
                  match literal with
                  | .natural value =>
                      Except.ok {
                        instructions := psWasmNatLiteralInstructions value
                        state := state
                      }
                  | .integer value =>
                      Except.ok {
                        instructions := psWasmIntLiteralInstructions value
                        state := state
                      }
                  | .machineInteger type value =>
                      Except.ok {
                        instructions :=
                          psWasmLowerMachineIntegerLiteral profile type value
                        state := state
                      }
                  | .string value =>
                      Except.ok {
                        instructions :=
                          psWasmStringLiteralInstructions value
                        state := state
                      }
                  | .bool value =>
                      let encodedValue : Int :=
                        if value then 1 else 0;
                      Except.ok {
                        instructions :=
                          [PsWasmInstruction.i32Const encodedValue]
                        state := state
                      }
                  | .unit =>
                      match expected with
                      | Option.none =>
                          Except.ok {
                            instructions := [PsWasmInstruction.i32Const 0]
                            state := state
                          }
                      | Option.some valueType =>
                          match valueType with
                          | PsWasmValueType.i32 =>
                              Except.ok {
                                instructions :=
                                  [PsWasmInstruction.i32Const 0]
                                state := state
                              }
                          | _ =>
                              Except.error
                                PsWasmLowerError.unsupportedType
              | .var name =>
                  match psWasmFindBindingIndex bindings name with
                  | Option.none =>
                      match psStrictFindDeclaration allDeclarations name with
                      | Option.none =>
                          Except.error (PsWasmLowerError.unknownVariable name)
                      | Option.some declaration =>
                          match declaration.parameters with
                          | List.nil =>
                              Except.ok {
                                instructions := psWasmCallValueInstructions declaration.resultType (PsWasmInstruction.call name)
                                state := state
                              }
                          | List.cons _ _ =>
                              let parameters : List PsVerifiedIrParameter :=
                                psWasmGlobalFunctionParameters
                                  name declaration.parameters 0;
                              let body : PsVerifiedIrExpr :=
                                PsVerifiedIrExpr.call (PsVerifiedIrExpr.var name)
                                  List.nil (psWasmGlobalFunctionArguments parameters);
                              psWasmLowerLambdaWith
                                profile bindings lowerWithBindings state
                                parameters declaration.resultType body
                  | Option.some index =>
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
                    profile
                    (PsVerifiedIrModule.mk List.nil structures inductives allDeclarations)
                    bindings lower state fn arguments
              | .letE name type value body =>
                  match psWasmLowerParameterType profile type with
                  | Except.error error => Except.error error
                  | Except.ok localType =>
                      match
                          lower
                            (Option.some localType)
                            state
                            value with
                      | Except.error error => Except.error error
                      | Except.ok loweredValue =>
                          let allocated :=
                            psWasmAddLocal loweredValue.state localType;
                          let localIndex := (Prod.fst allocated);
                          let localState := (Prod.snd allocated);
                          let bodyBindings :=
                            List.cons
                              (PsWasmBinding.mk
                                name
                                localIndex
                                type)
                              bindings;
                          match
                              smaller
                                bodyBindings
                                expected
                                localState
                                body with
                          | Except.error error => Except.error error
                          | Except.ok loweredBody =>
                              Except.ok {
                                instructions :=
                                  psListAppend
                                    loweredValue.instructions
                                    (psListAppend
                                      [PsWasmInstruction.localSet localIndex]
                                      (loweredBody.instructions))
                                state := loweredBody.state
                              }
              | .record structureName _ fields =>
                  match psWasmFindStructure structures structureName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownStructure structureName)
                  | Option.some structInfo =>
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
                                  psListAppend
                                    lowered.instructions
                                    [PsWasmInstruction.structNew structureName]
                                state := lowered.state
                              }
              | .projection structureName _ target fieldName =>
                  match psWasmFindStructure structures structureName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownStructure structureName)
                  | Option.some structInfo =>
                      match psWasmFindStructureField structInfo fieldName with
                      | Option.none =>
                          Except.error
                            (PsWasmLowerError.unknownStructureField
                              structureName fieldName)
                      | Option.some indexedField =>
                          let fieldIndex := (Prod.fst indexedField);
                          let field := (Prod.snd indexedField);
                          match
                              lower
                                (Option.some (PsWasmValueType.refT structureName))
                                state
                                target with
                          | Except.error error => Except.error error
                          | Except.ok lowered =>
                              Except.ok {
                                instructions :=
                                  psListAppend
                                    lowered.instructions
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
                      | Option.none =>
                          Except.error
                            (PsWasmLowerError.unknownInductive inductiveName)
                      | Option.some inductiveInfo =>
                          match inductiveInfo.typeParameters with
                          | _ :: _ =>
                              Except.error PsWasmLowerError.unsupportedType
                          | [] =>
                              match
                                  psWasmFindConstructor
                                    inductiveInfo.constructors
                                    constructorName with
                              | Option.none =>
                                  Except.error
                                    (PsWasmLowerError.unknownConstructor
                                      inductiveName
                                      constructorName)
                              | Option.some constructorInfo =>
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
                                          psListAppend
                                            lowered.instructions
                                            [PsWasmInstruction.structNew
                                                                                  (psWasmConstructorTypeName
                                                                                    inductiveName
                                                                                    constructorName)]
                                        state := lowered.state
                                      }
              | .matchE inductiveName _ scrutinee alternatives =>
                  match psWasmFindInductive inductives inductiveName with
                  | Option.none =>
                      Except.error
                        (PsWasmLowerError.unknownInductive inductiveName)
                  | Option.some inductiveInfo =>
                      match inductiveInfo.typeParameters with
                      | _ :: _ =>
                          Except.error PsWasmLowerError.unsupportedType
                      | [] =>
                          match
                              lower
                                (Option.some (PsWasmValueType.refT inductiveName))
                                state
                                scrutinee with
                          | Except.error error => Except.error error
                          | Except.ok loweredScrutinee =>
                              let allocated :=
                                psWasmAddLocal
                                  loweredScrutinee.state
                                  (PsWasmValueType.refT inductiveName);
                              let scrutineeLocal := (Prod.fst allocated);
                              let nextState := (Prod.snd allocated);
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
                                      psListAppend
                                        loweredScrutinee.instructions
                                        (psListAppend
                                          [PsWasmInstruction.localSet
                                                                            scrutineeLocal]
                                          (loweredMatch.instructions))
                                    state := loweredMatch.state
                                  }
              | .ifE condition thenBranch elseBranch =>
                  psWasmLowerIfWith
                    lower state expected condition thenBranch elseBranch
        

def psWasmLowerExprWithFuel
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (bindings : List PsWasmBinding)
    (expected : Option PsWasmValueType)
    (remainingFuel : Nat)
    (state : PsWasmLowerState)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprWorker
    profile
    allDeclarations
    structures
    inductives
    remainingFuel
    bindings
    expected
    state
    expr

def psWasmLowerExpr
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (bindings : List PsWasmBinding)
    (expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  psWasmLowerExprWithFuel
    profile allDeclarations structures inductives bindings expected 4096 state expr

structure PsWasmLoweredFunction where
  function : PsWasmFunction
  state : PsWasmLowerState

structure PsWasmLoweredFunctions where
  functions : List PsWasmFunction
  state : PsWasmLowerState

def psWasmLowerDeclaration
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
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
                psWasmParameterBindings declaration.parameters;
              let initialState : PsWasmLowerState := {
                nextLocalIndex := (psListLength declaration.parameters)
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
              };
              match
                  psWasmLowerExpr
                    profile
                    allDeclarations
                    structures
                    inductives
                    bindings
                    (psWasmFunctionBodyExpected declaration.resultType expected)
                    initialState
                    declaration.body with
              | Except.error error => Except.error error
              | Except.ok lowered =>
                  Except.ok {
                    function := {
                      name := declaration.name
                      typeName := Option.none
                      parameters := parameters
                      results := results
                      locals := lowered.state.localTypes
                      body := psWasmFunctionBodyResult declaration.resultType lowered.instructions
                    }
                    state := lowered.state
                  }

def psWasmLowerDeclarationsWorker
    (profile : PsWasmTargetProfile)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (declarations : List PsVerifiedIrDeclaration) :
    PsWasmLowerState ->
    Except PsWasmLowerError PsWasmLoweredFunctions :=
  match declarations with
  | List.nil =>
      fun (state : PsWasmLowerState) =>
        Except.ok {
          functions := []
          state := state
        }
  | List.cons declaration rest =>
      let smaller :
          PsWasmLowerState ->
          Except PsWasmLowerError PsWasmLoweredFunctions :=
        psWasmLowerDeclarationsWorker
          profile
          allDeclarations
          structures
          inductives
          rest;
      fun (state : PsWasmLowerState) =>
        match
            psWasmLowerDeclaration
              profile
              allDeclarations
              structures
              inductives
              state
              declaration with
        | Except.error error =>
            Except.error
              (psWasmContextualizeUnsupportedType
                (String.Internal.append
                  "declaration:"
                  declaration.name)
                error)
        | Except.ok lowered =>
            match smaller lowered.state with
            | Except.error error => Except.error error
            | Except.ok loweredRest =>
                Except.ok {
                  functions :=
                    List.cons
                      lowered.function
                      loweredRest.functions
                  state := loweredRest.state
                }

def psWasmLowerDeclarations
    (profile : PsWasmTargetProfile)
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (state : PsWasmLowerState)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsWasmLowerError PsWasmLoweredFunctions :=
  psWasmLowerDeclarationsWorker
    profile declarations structures inductives declarations state

def psWasmTypeUsesNatWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Bool :=
        psWasmTypeUsesNatWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .nat => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesNat
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesNatWithFuel 64 type

def psWasmIntrinsicUsesNat
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .natAdd => true
  | .natSub => true
  | .natMul => true
  | .natDiv => true
  | .natMod => true
  | .natEq => true
  | .natNe => true
  | .natLe => true
  | .natLt => true
  | .uint8OfNat => true
  | .intOfNat => true
  | .intRepr => true
  | .intNegSucc => true
  | .charOfNat => true
  | .charToNat => true
  | .stringLength => true
  | .stringUtf8ByteSize => true
  | .stringNext => true
  | .stringGet => true
  | .stringAtEnd => true
  | .stringExtract => true
  | .arrayEmptyWithCapacity => true
  | .arraySize => true
  | .arrayGet => true
  | .arrayGetD => true
  | .arraySet => true
  | .arraySetIfInBounds => true
  | .arrayFoldl => true
  | _ => false

def psWasmExprUsesNatWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrExpr -> Bool :=
        psWasmExprUsesNatWithFuel fuel;
      fun (expr : PsVerifiedIrExpr) =>
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesNat parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesNat binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .natural _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesNat operation then
              true
            else if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesNat resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesNat type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesNat typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesNat
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesNatWithFuel 4096 expr

def psWasmTypeUsesIntWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Bool :=
        psWasmTypeUsesIntWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .int => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesInt
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesIntWithFuel 64 type

def psWasmIntrinsicUsesInt
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .intOfNat => true
  | .intNegSucc => true
  | .intNeg => true
  | .intAdd => true
  | .intSub => true
  | .intMul => true
  | .intEq => true
  | .intLe => true
  | .intLt => true
  | _ => false

def psWasmExprUsesIntWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrExpr -> Bool :=
        psWasmExprUsesIntWithFuel fuel;
      fun (expr : PsVerifiedIrExpr) =>
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesInt parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesInt binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .integer _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesInt operation then
              true
            else if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesInt resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesInt type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesInt typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesInt
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesIntWithFuel 4096 expr

def psWasmTypeUsesStringWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Bool :=
        psWasmTypeUsesStringWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        let usesType :
            PsVerifiedIrType -> Bool :=
          fun (value : PsVerifiedIrType) =>
            smaller value;
        match type with
        | .primitive primitive =>
            match primitive with
            | .string => true
            | _ => false
        | .function parameters result =>
            if psListAny usesType parameters then
              true
            else
              usesType result
        | .named _ arguments =>
            psListAny usesType arguments
        | _ => false

def psWasmTypeUsesString
    (type : PsVerifiedIrType) : Bool :=
  psWasmTypeUsesStringWithFuel 64 type

def psWasmIntrinsicUsesString
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match operation with
  | .intRepr => true
  | .stringPush => true
  | .stringSingleton => true
  | .stringLength => true
  | .stringAppend => true
  | .stringUtf8ByteSize => true
  | .stringNext => true
  | .stringGet => true
  | .stringAtEnd => true
  | .stringExtract => true
  | .stringEq => true
  | _ => false

def psWasmExprUsesStringWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrExpr -> Bool :=
  match remainingFuel with
  | 0 =>
      fun (_expr : PsVerifiedIrExpr) => false
  | fuel + 1 =>
      let smaller : PsVerifiedIrExpr -> Bool :=
        psWasmExprUsesStringWithFuel fuel;
      fun (expr : PsVerifiedIrExpr) =>
        let uses :
            PsVerifiedIrExpr -> Bool :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller nested;
        let fieldUses :
            (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            uses (Prod.snd field);
        let parameterUses :
            PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) =>
            psWasmTypeUsesString parameter.type;
        let bindingUses :
            PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) =>
            psWasmTypeUsesString binding.type;
        let alternativeUses :
            (String ×
              List PsVerifiedIrMatchBinding ×
              PsVerifiedIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsVerifiedIrMatchBinding ×
                PsVerifiedIrExpr) =>
            if
                psListAny
                  bindingUses
                  (Prod.fst (Prod.snd alternative)) then
              true
            else
              uses (Prod.snd (Prod.snd alternative));
        match expr with
        | .literal literal =>
            match literal with
            | .string _ => true
            | _ => false
        | .var _ => false
        | .intrinsic operation typeArguments arguments =>
            if psWasmIntrinsicUsesString operation then
              true
            else if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny uses arguments
        | .lambda parameters resultType body =>
            if psListAny parameterUses parameters then
              true
            else if psWasmTypeUsesString resultType then
              true
            else
              uses body
        | .call fn typeArguments arguments =>
            if uses fn then
              true
            else if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny uses arguments
        | .letE _ type value body =>
            if psWasmTypeUsesString type then
              true
            else if uses value then
              true
            else
              uses body
        | .ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | .record _ typeArguments fields =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny fieldUses fields
        | .projection _ typeArguments target _ =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              uses target
        | .constructor _ _ typeArguments fields =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else
              psListAny fieldUses fields
        | .matchE _ typeArguments scrutinee alternatives =>
            if psListAny psWasmTypeUsesString typeArguments then
              true
            else if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psWasmExprUsesString
    (expr : PsVerifiedIrExpr) : Bool :=
  psWasmExprUsesStringWithFuel 4096 expr

def psWasmStructureUsesNat
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesNat field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesNat
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesNat field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesNat
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesNat
    inductiveInfo.constructors

def psWasmDeclarationUsesNat
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesNat parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesNat declaration.resultType then
    true
  else
    psWasmExprUsesNat declaration.body

def psWasmModuleUsesNat
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesNat importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesNat module.structures then
    true
  else if psListAny psWasmInductiveUsesNat module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesNat module.declarations

def psWasmStructureUsesInt
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesInt field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesInt
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesInt field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesInt
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesInt
    inductiveInfo.constructors

def psWasmDeclarationUsesInt
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesInt parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesInt declaration.resultType then
    true
  else
    psWasmExprUsesInt declaration.body

def psWasmModuleUsesInt
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesInt importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesInt module.structures then
    true
  else if psListAny psWasmInductiveUsesInt module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesInt module.declarations


def psWasmStructureUsesString
    (structureInfo : PsVerifiedIrStructure) : Bool :=
  let fieldUses :
      PsVerifiedIrStructureField -> Bool :=
    fun (field : PsVerifiedIrStructureField) =>
      psWasmTypeUsesString field.type;
  psListAny fieldUses structureInfo.fields

def psWasmConstructorUsesString
    (constructorInfo : PsVerifiedIrConstructor) : Bool :=
  let fieldUses :
      PsVerifiedIrConstructorField -> Bool :=
    fun (field : PsVerifiedIrConstructorField) =>
      psWasmTypeUsesString field.type;
  psListAny fieldUses constructorInfo.fields

def psWasmInductiveUsesString
    (inductiveInfo : PsVerifiedIrInductive) : Bool :=
  psListAny
    psWasmConstructorUsesString
    inductiveInfo.constructors

def psWasmDeclarationUsesString
    (declaration : PsVerifiedIrDeclaration) : Bool :=
  let parameterUses :
      PsVerifiedIrParameter -> Bool :=
    fun (parameter : PsVerifiedIrParameter) =>
      psWasmTypeUsesString parameter.type;
  if psListAny parameterUses declaration.parameters then
    true
  else if psWasmTypeUsesString declaration.resultType then
    true
  else
    psWasmExprUsesString declaration.body

def psWasmModuleUsesString
    (module : PsVerifiedIrModule) : Bool :=
  let importUses :
      PsVerifiedIrExternalImport -> Bool :=
    fun (importInfo : PsVerifiedIrExternalImport) =>
      psWasmTypeUsesString importInfo.type;
  if psListAny importUses module.imports then
    true
  else if psListAny psWasmStructureUsesString module.structures then
    true
  else if psListAny psWasmInductiveUsesString module.inductives then
    true
  else
    psListAny psWasmDeclarationUsesString module.declarations


def psWasmExportsOfDeclarations
    (declarations : List PsVerifiedIrDeclaration) :
    List (String × String) :=
  match declarations with
  | List.nil => []
  | List.cons declaration rest =>
      List.cons
        (Prod.mk declaration.name declaration.name)
        (psWasmExportsOfDeclarations rest)

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
            let semanticArrayTypes :=
              psWasmCollectModuleArrayTypes module;
            match psWasmLowerArrayTypes profile semanticArrayTypes with
            | Except.error error =>
                Except.error
                  (psWasmContextualizeUnsupportedType
                    "module:arrays"
                    error)
            | Except.ok arrays =>
                let semanticFunctionTypes :=
                  psWasmCollectModuleFunctionTypes module;
                match
                    psWasmLowerClosureSignatures
                      profile
                      semanticFunctionTypes with
                | Except.error error =>
                    Except.error
                      (psWasmContextualizeUnsupportedType
                        "module:closures"
                        error)
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
                };
                match
                    psWasmLowerDeclarations
                      profile
                      module.structures
                      module.inductives
                      initialState
                      module.declarations with
                | Except.error error => Except.error error
                | Except.ok lowered =>
                    let needsInt :=
                      psWasmModuleUsesInt module;
                    let needsString :=
                      psWasmModuleUsesString module;
                    let needsNat :=
                      if psWasmModuleUsesNat module then
                        true
                      else if needsInt then
                        true
                      else
                        needsString;
                    let natRuntimeStructures :=
                      if needsNat then psWasmNatRuntimeStructures else [];
                    let intRuntimeStructures :=
                      if needsInt then psWasmIntRuntimeStructures else [];
                    let stringRuntimeStructures :=
                      if needsString then psWasmStringRuntimeStructures else [];
                    let runtimeStructures :=
                      psListAppend
                        natRuntimeStructures
                        (psListAppend
                          intRuntimeStructures
                          stringRuntimeStructures);
                    let stringRuntimeArrays :=
                      if needsString then psWasmStringRuntimeArrays else [];
                    let runtimeArrays :=
                      psListAppend stringRuntimeArrays arrays;
                    let natRuntimeFunctions :=
                      if needsNat then psWasmNatRuntimeFunctions else [];
                    let intRuntimeFunctions :=
                      if needsInt then psWasmIntRuntimeFunctions else [];
                    let stringRuntimeFunctions :=
                      if needsString then psWasmStringRuntimeFunctions else [];
                    let intReprRuntimeFunctions : List PsWasmFunction :=
                      if needsInt then
                        if needsString then
                          psWasmIntReprRuntimeFunctions
                        else
                          []
                      else
                        [];
                    let runtimeFunctions :=
                      psListAppend
                        natRuntimeFunctions
                        (psListAppend
                          intRuntimeFunctions
                          (psListAppend
                            stringRuntimeFunctions
                            intReprRuntimeFunctions));
                    Except.ok {
                      structures :=
                        psListAppend
                          runtimeStructures
                          (psListAppend
                            structures
                            (psListAppend
                              inductiveTypes
                              (psListAppend
                                (Prod.fst closureSignatures)
                                (lowered.state.generatedStructures))))
                      arrays := runtimeArrays
                      functionTypes :=
                        psListAppend
                          (Prod.snd closureSignatures)
                          (lowered.state.generatedFunctionTypes)
                      functions :=
                        psWasmTailCallFunctions
                          (psListAppend
                            runtimeFunctions
                            (psListAppend
                              lowered.functions
                              lowered.state.generatedFunctions))
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
  | Except.error error =>
      Except.error (PsWasmLowerError.specializationFailed error)
  | Except.ok specialized =>
      psWasmLowerSpecializedModule profile specialized

def psWasmLowerSpecializedValidatedModule
    (profile : PsWasmTargetProfile)
    (specialized : PsSpecializedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  psWasmLowerSpecializedModule profile specialized.raw

def psWasmLowerValidatedModule
    (profile : PsWasmTargetProfile)
    (validated : PsValidatedIrModule) :
    Except PsWasmLowerError PsWasmModule :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error =>
      Except.error (PsWasmLowerError.specializationFailed error)
  | Except.ok specialized =>
      psWasmLowerSpecializedValidatedModule profile specialized
