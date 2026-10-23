import Ps.BackendWasm.CompilerService

-- Retained production definitions, test-only: delay construction until inputs exist.
namespace WasmPrefixReference

def psWasmNatLiteralInstructionsWithFuel
    (remainingFuel : Nat) :
    Nat -> List PsWasmInstruction :=
  match remainingFuel with
  | 0 =>
      fun (_value : Nat) =>
        [PsWasmInstruction.structNew psWasmNatZeroName]
  | fuel + 1 =>
      let smaller : Nat -> List PsWasmInstruction :=
        psWasmNatLiteralInstructionsWithFuel fuel;
      fun (value : Nat) =>
        if Nat.beq value 0 then
          [PsWasmInstruction.structNew psWasmNatZeroName]
        else
          let half := Nat.div value 2;
          let low := Nat.mod value 2;
          let suffix :=
            if Nat.beq low 0 then
              [PsWasmInstruction.structNew psWasmNatBit0Name]
            else
              [PsWasmInstruction.call psWasmNatBit1Fn];
          psListAppend
            (smaller half)
            suffix


def psWasmStringLiteralChunksWithFuel
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat -> Bool ->
    List PsWasmInstruction -> List PsWasmInstruction :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) (byteCount : Nat) (charCount : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        psListReverse
          (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev)
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Nat -> Bool ->
          List PsWasmInstruction -> List PsWasmInstruction :=
        psWasmStringLiteralChunksWithFuel remaining;
      fun (value : String) (position : Nat) (byteCount : Nat) (charCount : Nat)
          (hasPrevious : Bool) (instructionsRev : List PsWasmInstruction) =>
        if String.Internal.atEnd value (String.Pos.Raw.mk position) then
          psListReverse
            (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev)
        else
          let char : Char := String.Internal.get value (String.Pos.Raw.mk position);
          let nextPosition : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next value (String.Pos.Raw.mk position));
          let bytes : List Nat := psWasmStringLiteralScalarBytes char;
          let added : List PsWasmInstruction :=
            psListReverse (psListMap psWasmStringLiteralByte bytes);
          let width : Nat := psListLength bytes;
          if Nat.ble 4092 byteCount then
            smaller value nextPosition width 1 true
              (psListAppend added
                (psWasmStringLiteralFinishChunk byteCount charCount hasPrevious instructionsRev))
          else
            smaller value nextPosition (Nat.add byteCount width) (Nat.succ charCount)
              hasPrevious (psListAppend added instructionsRev)


def psWasmIrTypeKeyWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Option String :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => Option.none
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Option String :=
        psWasmIrTypeKeyWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown => Option.none
        | .typeParameter _ => Option.none
        | .primitive primitive =>
            match primitive with
            | .nat => Option.some "Nat"
            | .int => Option.some "Int"
            | .uint8 => Option.some "U8"
            | .uint16 => Option.some "U16"
            | .uint32 => Option.some "U32"
            | .uint64 => Option.some "U64"
            | .usize => Option.some "USize"
            | .int8 => Option.some "I8"
            | .int16 => Option.some "I16"
            | .int32 => Option.some "I32"
            | .int64 => Option.some "I64"
            | .isize => Option.some "ISize"
            | .float => Option.some "F64"
            | .float32 => Option.some "F32"
            | .bool => Option.some "Bool"
            | .char => Option.some "Char"
            | .string => Option.some "String"
            | .unit => Option.some "Unit"
        | .named name arguments =>
            let argumentKeys :=
              psWasmMapTypeKeysWith
                smaller
                arguments;
            match psWasmJoinTypeKeys argumentKeys with
            | Option.none => Option.none
            | Option.some keys =>
                if psStringEq keys "" then
                  Option.some
                    (String.Internal.append
                      "N{"
                      (String.Internal.append name "}"))
                else
                  Option.some
                    (String.Internal.append
                      "N{"
                      (String.Internal.append
                        name
                        (String.Internal.append
                          "}<"
                          (String.Internal.append keys ">"))))
        | .function parameters result =>
            let parameterKeys :=
              psWasmMapTypeKeysWith
                smaller
                parameters;
            match psWasmJoinTypeKeys parameterKeys with
            | Option.none => Option.none
            | Option.some parameterKey =>
                match smaller result with
                | Option.none => Option.none
                | Option.some resultKey =>
                    Option.some
                      (String.Internal.append
                        "Fn{"
                        (String.Internal.append
                          parameterKey
                          (String.Internal.append
                            "}->{"
                            (String.Internal.append resultKey "}"))))


def psWasmIrAppend
    (left : List String) :
    List String -> List String :=
  match left with
  | List.nil =>
      fun (right : List String) => right
  | List.cons value rest =>
      let smaller : List String -> List String :=
        psWasmIrAppend rest;
      fun (right : List String) =>
        List.cons value (smaller right)


def psWasmIrValueTypeListsEq
    (left : List PsWasmValueType) :
    List PsWasmValueType -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsWasmValueType) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons value rest =>
      let smaller :
          List PsWasmValueType -> Bool :=
        psWasmIrValueTypeListsEq rest;
      fun (right : List PsWasmValueType) =>
        match right with
        | List.nil => false
        | List.cons other otherRest =>
            if psWasmIrValueTypeEq value other then
              smaller otherRest
            else
              false


def psWasmIrValidateControl
    (functionName : String)
    (instructions : List PsWasmInstruction) :
    List Bool ->
    Except PsWasmIrValidationError Unit :=
  match instructions with
  | List.nil =>
      fun (stack : List Bool) =>
        match stack with
        | List.nil => Except.ok Unit.unit
        | List.cons _ _ =>
            Except.error
              (PsWasmIrValidationError.invalidControlFlow
                functionName)
  | List.cons instruction rest =>
      let smaller :
          List Bool ->
          Except PsWasmIrValidationError Unit :=
        psWasmIrValidateControl
          functionName
          rest;
      fun (stack : List Bool) =>
        match instruction with
        | PsWasmInstruction.ifStart _ =>
            smaller (List.cons false stack)
        | PsWasmInstruction.else_ =>
            match stack with
            | List.nil =>
                Except.error
                  (PsWasmIrValidationError.invalidControlFlow
                    functionName)
            | List.cons seenElse tail =>
                if seenElse then
                  Except.error
                    (PsWasmIrValidationError.invalidControlFlow
                      functionName)
                else
                  smaller (List.cons true tail)
        | PsWasmInstruction.end_ =>
            match stack with
            | List.nil =>
                Except.error
                  (PsWasmIrValidationError.invalidControlFlow
                    functionName)
            | List.cons _ tail =>
                smaller tail
        | _ =>
            smaller stack


def psWasmTypingHeapSubtypeWithFuel
    (module : PsWasmModule) (remainingFuel : Nat) : String -> String -> Bool :=
  match remainingFuel with
  | Nat.zero => fun (_actual : String) => fun (_expected : String) => false
  | Nat.succ fuel =>
      let smaller : String -> String -> Bool := psWasmTypingHeapSubtypeWithFuel module fuel;
      fun (actual : String) =>
        fun (expected : String) =>
          if psStringEq actual expected then true
          else
            match psWasmIrFindStructure module.structures actual with
            | Option.none => false
            | Option.some structType =>
                match structType.superType with
                | Option.none => false
                | Option.some parent => smaller parent expected


def psWasmTypingFieldsMatch
    (module : PsWasmModule) (parents : List PsWasmStructField) :
    List PsWasmStructField -> Bool :=
  match parents with
  | List.nil => fun (_fields : List PsWasmStructField) => true
  | List.cons parent rest =>
      let smaller : List PsWasmStructField -> Bool := psWasmTypingFieldsMatch module rest;
      fun (fields : List PsWasmStructField) =>
        match fields with
        | List.nil => false
        | List.cons field tail =>
            if psWasmTypingStorageMatches module field.storageType parent.storageType then
              smaller tail
            else false


def psWasmTypingValidateParents
    (module : PsWasmModule) (structures : List PsWasmStructType) :
    List PsWasmStructType -> Except PsWasmIrValidationError Unit :=
  match structures with
  | List.nil => fun (_previous : List PsWasmStructType) => Except.ok Unit.unit
  | List.cons structType rest =>
      let smaller : List PsWasmStructType -> Except PsWasmIrValidationError Unit :=
        psWasmTypingValidateParents module rest;
      fun (previous : List PsWasmStructType) =>
        match structType.superType with
        | Option.none => smaller (List.cons structType previous)
        | Option.some name =>
            match psWasmIrFindStructure previous name with
            | Option.none => Except.error (PsWasmIrValidationError.invalidTypeDeclaration structType.name)
            | Option.some parent =>
                if parent.isFinal then
                  Except.error (PsWasmIrValidationError.invalidTypeDeclaration structType.name)
                else if psWasmTypingFieldsMatch module parent.fields structType.fields then
                  smaller (List.cons structType previous)
                else Except.error (PsWasmIrValidationError.invalidTypeDeclaration structType.name)


def psWasmTypingNth {alpha : Type} (values : List alpha) : Nat -> Option alpha :=
  match values with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons value rest =>
      let smaller : Nat -> Option alpha := psWasmTypingNth rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => Option.some value
        | Nat.succ preceding => smaller preceding


def psWasmTypingPushValues (types : List PsWasmValueType) :
    PsWasmTypingState -> PsWasmTypingState :=
  match types with
  | List.nil => fun (state : PsWasmTypingState) => state
  | List.cons type rest =>
      let smaller : PsWasmTypingState -> PsWasmTypingState := psWasmTypingPushValues rest;
      fun (state : PsWasmTypingState) => smaller (psWasmTypingPush (PsWasmOperandType.value type) state)


def psWasmTypingPopReversed
    (module : PsWasmModule) (types : List PsWasmValueType) :
    PsWasmTypingState -> Option PsWasmTypingState :=
  match types with
  | List.nil => fun (state : PsWasmTypingState) => Option.some state
  | List.cons type rest =>
      let smaller : PsWasmTypingState -> Option PsWasmTypingState :=
        psWasmTypingPopReversed module rest;
      fun (state : PsWasmTypingState) =>
        match psWasmTypingPopValue module type state with
        | Option.none => Option.none
        | Option.some next => smaller next


def psWasmTypingRepeatPop
    (module : PsWasmModule) (type : PsWasmValueType) (count : Nat) :
    PsWasmTypingState -> Option PsWasmTypingState :=
  match count with
  | Nat.zero => fun (state : PsWasmTypingState) => Option.some state
  | Nat.succ remaining =>
      let smaller : PsWasmTypingState -> Option PsWasmTypingState :=
        psWasmTypingRepeatPop module type remaining;
      fun (state : PsWasmTypingState) =>
        match state.operands with
        | List.nil =>
            if state.unreachable then Option.some state else Option.none
        | List.cons _ _ =>
            match psWasmTypingPopValue module type state with
            | Option.none => Option.none
            | Option.some next => smaller next


def psWasmTypingInstructions
    (module : PsWasmModule) (function : PsWasmFunction) (locals : List PsWasmValueType)
    (instructions : List PsWasmInstruction) :
    PsWasmTypingState -> Option PsWasmTypingState :=
  match instructions with
  | List.nil => fun (state : PsWasmTypingState) => Option.some state
  | List.cons instruction rest =>
      let smaller : PsWasmTypingState -> Option PsWasmTypingState :=
        psWasmTypingInstructions module function locals rest;
      fun (state : PsWasmTypingState) =>
        match psWasmTypingInstruction module function locals instruction state with
        | Option.none => Option.none
        | Option.some next => smaller next


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


def psWasmEncodeUlebWithFuel
    (remainingFuel : Nat) : Nat -> List Nat :=
  match remainingFuel with
  | 0 =>
      fun (_value : Nat) => List.nil
  | fuel + 1 =>
      let smaller : Nat -> List Nat :=
        psWasmEncodeUlebWithFuel fuel;
      fun (value : Nat) =>
        let low := Nat.mod value 128;
        let rest := Nat.div value 128;
        if Nat.beq rest 0 then
          [Ps.Internal.WasmBinaryBytes.psWasmByte low]
        else
          List.cons
            (Ps.Internal.WasmBinaryBytes.psWasmByte (Nat.add low 128))
            (smaller rest)


def psWasmEncodeSlebWithFuel
    (remainingFuel : Nat) : Int -> List Nat :=
  match remainingFuel with
  | 0 =>
      fun (_value : Int) => List.nil
  | fuel + 1 =>
      let smaller : Int -> List Nat :=
        psWasmEncodeSlebWithFuel fuel;
      fun (value : Int) =>
        let lowInt := psWasmIntEModNat value 128;
        let low := psWasmIntToNat lowInt;
        let rest := psWasmIntEDivNat value 128;
        let signSet := Nat.ble 64 low;
        let donePositive :=
          if psWasmIntIsZero rest then
            if signSet then false else true
          else
            false;
        let doneNegative :=
          if psWasmIntIsNegativeOne rest then signSet else false;
        if donePositive then
          [Ps.Internal.WasmBinaryBytes.psWasmByte low]
        else if doneNegative then
          [Ps.Internal.WasmBinaryBytes.psWasmByte low]
        else
          List.cons
            (Ps.Internal.WasmBinaryBytes.psWasmByte (Nat.add low 128))
            (smaller rest)


def psWasmStringToListFromWithFuel
    (remainingFuel : Nat) : String -> Nat -> List Char :=
  match remainingFuel with
  | Nat.zero =>
      fun (_source : String) =>
        fun (_position : Nat) =>
          List.nil
  | Nat.succ fuel =>
      let smaller : String -> Nat -> List Char :=
        psWasmStringToListFromWithFuel fuel;
      fun (source : String) =>
        fun (position : Nat) =>
          if
              String.Internal.atEnd
                source
                (String.Pos.Raw.mk position) then
            List.nil
          else
            let char : Char :=
              String.Internal.get
                source
                (String.Pos.Raw.mk position);
            let nextPosition : Nat :=
              String.Pos.Raw.byteIdx
                (String.Internal.next
                  source
                  (String.Pos.Raw.mk position));
            List.cons char (smaller source nextPosition)


def psWasmFindStructureIndexWorker
    (name : String)
    (structures : List PsWasmStructType) :
    Nat -> Option Nat :=
  match structures with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons structType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindStructureIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq structType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)


def psWasmFindArrayIndexWorker
    (name : String)
    (arrays : List PsWasmArrayType) :
    Nat -> Option Nat :=
  match arrays with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons arrayType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindArrayIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq arrayType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)


def psWasmFindFunctionTypeIndexWorker
    (name : String)
    (functionTypes : List PsWasmFunctionType) :
    Nat -> Option Nat :=
  match functionTypes with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons functionType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindFunctionTypeIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq functionType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)


def psWasmFindFunctionIndexWorker
    (name : String)
    (functions : List PsWasmFunction) :
    Nat -> Option Nat :=
  match functions with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons function rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindFunctionIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq function.name name then
          Option.some index
        else
          smaller (Nat.add index 1)


def psWasmEncodeFunctionTypeIndicesAcc
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Nat -> List Nat -> Except PsWasmEncodeError (List Nat) :=
  match functions with
  | List.nil =>
      fun (_functionIndex : Nat) =>
        fun (reversed : List Nat) => Except.ok (psListReverse reversed)
  | List.cons function rest =>
      let smaller : Nat -> List Nat -> Except PsWasmEncodeError (List Nat) :=
        psWasmEncodeFunctionTypeIndicesAcc structures arrays functionTypes rest;
      fun (functionIndex : Nat) =>
        fun (reversed : List Nat) =>
          match Ps.Internal.WasmBinaryBytes.psWasmFunctionTypeIndex structures arrays functionTypes functionIndex function with
          | Except.error error => Except.error error
          | Except.ok typeIndex =>
              smaller (Nat.add functionIndex 1)
                (psListReverseAcc (Ps.Internal.WasmBinaryBytes.psWasmEncodeUleb typeIndex) reversed)


end WasmPrefixReference
