import Ps.BackendWasm.Type
import Ps.Foundation.List

/-!
# Wasm type discovery

Collect the function and array types needed before lowering executable bodies.
This module depends only on IR/Wasm type models and foundation helpers. It does
not lower instructions, specialize IR, perform admission or publish artifacts.

Traversal order, first-occurrence de-duplication and existing fuel bounds are
part of the retained representation contract. The accumulator workers and their
declaration bodies are moved verbatim from Lower.lean at 3089cbc3; no new
algorithm, semantic fuel, type-key equivalence or target capability is introduced.
See scripts/readability-module-check.mjs for exact extraction correspondence.
-/

def psWasmListFoldlWorker {Value State : Type}
    (step : State -> Value -> State)
    (values : List Value) :
    State -> State :=
  match values with
  | List.nil =>
      fun (state : State) => state
  | List.cons value rest =>
      fun (state : State) =>
        let smaller : State -> State :=
          psWasmListFoldlWorker step rest;
        smaller (step state value)

def psWasmListFoldl {Value State : Type}
    (step : State -> Value -> State)
    (values : List Value)
    (state : State) : State :=
  psWasmListFoldlWorker step values state

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
      fun (type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          let smaller :
              PsVerifiedIrType ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            psWasmCollectFunctionTypesFromTypeWithFuel fuel;
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
      fun (expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          let smaller :
              PsVerifiedIrExpr ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            psWasmCollectFunctionTypesFromExprWithFuel fuel;
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
      fun (type : PsVerifiedIrType) =>
        fun (types : List PsVerifiedIrType) =>
          let smaller :
              PsVerifiedIrType ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            psWasmCollectArrayTypesFromTypeWithFuel fuel;
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
      fun (expr : PsVerifiedIrExpr) =>
        fun (types : List PsVerifiedIrType) =>
          let smaller :
              PsVerifiedIrExpr ->
              List PsVerifiedIrType ->
              List PsVerifiedIrType :=
            psWasmCollectArrayTypesFromExprWithFuel fuel;
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


