import Ps.BackendWasm.ValidateStructure

-- Validation for the GC/tail-call profile represented by PsWasmModule.
-- refT is non-nullable in Binary.lean; funcRef is nullable abstract funcref.
-- This checks target typing, not source-to-target semantic preservation.
inductive PsWasmOperandType where
  | value (type : PsWasmValueType)
  | function (name : String)
  | bottom

structure PsWasmTypingFrame where
  outer : List PsWasmOperandType
  outerUnreachable : Bool
  initialized : List Nat
  results : List PsWasmValueType
  seenElse : Bool

structure PsWasmTypingState where
  operands : List PsWasmOperandType
  unreachable : Bool
  initialized : List Nat
  frames : List PsWasmTypingFrame

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

def psWasmTypingValueMatches
    (module : PsWasmModule) (actual expected : PsWasmValueType) : Bool :=
  match actual with
  | PsWasmValueType.refT name =>
      match expected with
      | PsWasmValueType.refT parent =>
          psWasmTypingHeapSubtypeWithFuel module
            (Nat.succ (psListLength module.structures)) name parent
      | _ => false
  | _ => psWasmIrValueTypeEq actual expected

def psWasmTypingStorageMatches
    (module : PsWasmModule) (actual expected : PsWasmStorageType) : Bool :=
  match actual with
  | PsWasmStorageType.packedI8 =>
      match expected with
      | PsWasmStorageType.packedI8 => true
      | _ => false
  | PsWasmStorageType.packedI16 =>
      match expected with
      | PsWasmStorageType.packedI16 => true
      | _ => false
  | PsWasmStorageType.value value =>
      match expected with
      | PsWasmStorageType.value parent => psWasmTypingValueMatches module value parent
      | _ => false

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

def psWasmTypingNatIn (values : List Nat) (target : Nat) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if Nat.beq value target then true else psWasmTypingNatIn rest target

def psWasmTypingDefaultable (type : PsWasmValueType) : Bool :=
  match type with
  | PsWasmValueType.refT _ => false
  | PsWasmValueType.noValue => false
  | _ => true

def psWasmTypingUnpack (type : PsWasmStorageType) : PsWasmValueType :=
  match type with
  | PsWasmStorageType.value value => value
  | PsWasmStorageType.packedI8 => PsWasmValueType.i32
  | PsWasmStorageType.packedI16 => PsWasmValueType.i32

def psWasmTypingFieldType (field : PsWasmStructField) : PsWasmValueType :=
  psWasmTypingUnpack field.storageType

def psWasmTypingStoragePacked (type : PsWasmStorageType) : Bool :=
  match type with
  | PsWasmStorageType.value _ => false
  | _ => true

def psWasmTypingOperandMatches
    (module : PsWasmModule) (actual : PsWasmOperandType)
    (expected : PsWasmValueType) : Bool :=
  match actual with
  | PsWasmOperandType.bottom => true
  | PsWasmOperandType.value value => psWasmTypingValueMatches module value expected
  | PsWasmOperandType.function _ =>
      match expected with
      | PsWasmValueType.funcRef => true
      | _ => false

def psWasmTypingPush (type : PsWasmOperandType) (state : PsWasmTypingState) :
    PsWasmTypingState :=
  PsWasmTypingState.mk (List.cons type state.operands) state.unreachable state.initialized state.frames

def psWasmTypingPushValues (types : List PsWasmValueType) :
    PsWasmTypingState -> PsWasmTypingState :=
  match types with
  | List.nil => fun (state : PsWasmTypingState) => state
  | List.cons type rest =>
      let smaller : PsWasmTypingState -> PsWasmTypingState := psWasmTypingPushValues rest;
      fun (state : PsWasmTypingState) => smaller (psWasmTypingPush (PsWasmOperandType.value type) state)

def psWasmTypingPop (state : PsWasmTypingState) :
    Option (Prod PsWasmOperandType PsWasmTypingState) :=
  match state.operands with
  | List.nil =>
      if state.unreachable then Option.some (Prod.mk PsWasmOperandType.bottom state)
      else Option.none
  | List.cons value rest => Option.some (Prod.mk value (PsWasmTypingState.mk rest state.unreachable state.initialized state.frames))

def psWasmTypingPopValue
    (module : PsWasmModule) (expected : PsWasmValueType) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match psWasmTypingPop state with
  | Option.none => Option.none
  | Option.some popped =>
      if psWasmTypingOperandMatches module (Prod.fst popped) expected then
        Option.some (Prod.snd popped)
      else Option.none

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

def psWasmTypingApply
    (module : PsWasmModule) (parameters results : List PsWasmValueType)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmTypingPopReversed module (psListReverse parameters) state with
  | Option.none => Option.none
  | Option.some next => Option.some (psWasmTypingPushValues results next)

def psWasmTypingUnreachable (state : PsWasmTypingState) : PsWasmTypingState :=
  PsWasmTypingState.mk List.nil true state.initialized state.frames

def psWasmTypingFinish
    (module : PsWasmModule) (results : List PsWasmValueType)
    (state : PsWasmTypingState) : Bool :=
  match psWasmTypingPopReversed module (psListReverse results) state with
  | Option.none => false
  | Option.some next => psListIsEmpty next.operands

def psWasmTypingReturn
    (module : PsWasmModule) (results : List PsWasmValueType)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmTypingPopReversed module (psListReverse results) state with
  | Option.none => Option.none
  | Option.some next => Option.some (psWasmTypingUnreachable next)

def psWasmTypingEnterIf
    (module : PsWasmModule) (result : Option PsWasmValueType)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmTypingPopValue module PsWasmValueType.i32 state with
  | Option.none => Option.none
  | Option.some next =>
      let results : List PsWasmValueType :=
        match result with
        | Option.none => List.nil
        | Option.some value => [value];
      let frame : PsWasmTypingFrame :=
        PsWasmTypingFrame.mk next.operands next.unreachable next.initialized results false;
      Option.some (PsWasmTypingState.mk List.nil false next.initialized (List.cons frame next.frames))

def psWasmTypingElse (module : PsWasmModule) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match state.frames with
  | List.nil => Option.none
  | List.cons frame rest =>
      if frame.seenElse then Option.none
      else if psWasmTypingFinish module frame.results state then
        Option.some (PsWasmTypingState.mk List.nil false frame.initialized
          (List.cons (PsWasmTypingFrame.mk frame.outer frame.outerUnreachable frame.initialized frame.results true) rest))
      else Option.none

def psWasmTypingEnd (module : PsWasmModule) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match state.frames with
  | List.nil => Option.none
  | List.cons frame rest =>
      let implicitElseValid : Bool :=
        if frame.seenElse then true else psListIsEmpty frame.results;
      if implicitElseValid then
        if psWasmTypingFinish module frame.results state then
          Option.some (psWasmTypingPushValues frame.results
            (PsWasmTypingState.mk frame.outer frame.outerUnreachable frame.initialized rest))
        else Option.none
      else Option.none

def psWasmTypingLocalGet
    (moduleFunction : PsWasmFunction) (locals : List PsWasmValueType)
    (index : Nat) (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmTypingNth locals index with
  | Option.none => Option.none
  | Option.some type =>
      let initialized : Bool :=
        if Nat.blt index (psListLength moduleFunction.parameters) then true
        else if psWasmTypingDefaultable type then true
        else psWasmTypingNatIn state.initialized index;
      if initialized then Option.some (psWasmTypingPush (PsWasmOperandType.value type) state)
      else Option.none

def psWasmTypingLocalSet
    (module : PsWasmModule) (locals : List PsWasmValueType)
    (index : Nat) (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmTypingNth locals index with
  | Option.none => Option.none
  | Option.some type =>
      match psWasmTypingPopValue module type state with
      | Option.none => Option.none
      | Option.some next =>
          if psWasmTypingDefaultable type then Option.some next
          else if psWasmTypingNatIn next.initialized index then Option.some next
          else Option.some (PsWasmTypingState.mk next.operands next.unreachable (List.cons index next.initialized) next.frames)

def psWasmTypingCall
    (module : PsWasmModule) (function : PsWasmFunction) (name : String)
    (tail : Bool) (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmIrFindFunction module.functions name with
  | Option.none => Option.none
  | Option.some callee =>
      if tail then
        if psWasmIrValueTypeListsEq callee.results function.results then
          match psWasmTypingApply module callee.parameters List.nil state with
          | Option.none => Option.none
          | Option.some next => Option.some (psWasmTypingUnreachable next)
        else Option.none
      else psWasmTypingApply module callee.parameters callee.results state

def psWasmTypingFunctionOperandMatches
    (operand : PsWasmOperandType) (name : String) : Bool :=
  match operand with
  | PsWasmOperandType.bottom => true
  | PsWasmOperandType.function actual => psStringEq actual name
  | _ => false

def psWasmTypingCallRef
    (module : PsWasmModule) (function : PsWasmFunction) (name : String)
    (tail : Bool) (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmIrFindFunctionType module.functionTypes name with
  | Option.none => Option.none
  | Option.some type =>
      match psWasmTypingPop state with
      | Option.none => Option.none
      | Option.some popped =>
          if psWasmTypingFunctionOperandMatches (Prod.fst popped) name then
            if tail then
              if psWasmIrValueTypeListsEq type.results function.results then
                match psWasmTypingApply module type.parameters List.nil (Prod.snd popped) with
                | Option.none => Option.none
                | Option.some next => Option.some (psWasmTypingUnreachable next)
              else Option.none
            else psWasmTypingApply module type.parameters type.results (Prod.snd popped)
          else Option.none
def psWasmTypingGcOperand (operand : PsWasmOperandType) : Bool :=
  match operand with
  | PsWasmOperandType.bottom => true
  | PsWasmOperandType.value type =>
      match type with
      | PsWasmValueType.refT _ => true
      | _ => false
  | _ => false

def psWasmTypingFuncOperand (operand : PsWasmOperandType) : Bool :=
  match operand with
  | PsWasmOperandType.bottom => true
  | PsWasmOperandType.function _ => true
  | PsWasmOperandType.value type =>
      match type with
      | PsWasmValueType.funcRef => true
      | _ => false

def psWasmTypingReference
    (module : PsWasmModule) (instruction : PsWasmInstruction)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match instruction with
  | PsWasmInstruction.refFunc name =>
      if psWasmIrStringIn name module.functionRefs then
        match psWasmIrFindFunction module.functions name with
        | Option.none => Option.none
        | Option.some function =>
            match function.typeName with
            | Option.none =>
                Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.funcRef) state)
            | Option.some type =>
                Option.some (psWasmTypingPush (PsWasmOperandType.function type) state)
      else Option.none
  | PsWasmInstruction.refCastFunction name =>
      match psWasmTypingPop state with
      | Option.none => Option.none
      | Option.some popped =>
          if psWasmTypingFuncOperand (Prod.fst popped) then
            Option.some (psWasmTypingPush (PsWasmOperandType.function name) (Prod.snd popped))
          else Option.none
  | PsWasmInstruction.refCast name =>
      match psWasmTypingPop state with
      | Option.none => Option.none
      | Option.some popped =>
          if psWasmTypingGcOperand (Prod.fst popped) then
            Option.some (psWasmTypingPush (PsWasmOperandType.value (PsWasmValueType.refT name)) (Prod.snd popped))
          else Option.none
  | PsWasmInstruction.refTest _ =>
      match psWasmTypingPop state with
      | Option.none => Option.none
      | Option.some popped =>
          if psWasmTypingGcOperand (Prod.fst popped) then
            Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.i32) (Prod.snd popped))
          else Option.none
  | _ => Option.none

def psWasmTypingStructGet
    (module : PsWasmModule) (name : String) (index : Nat) (packed : Bool)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmIrFindStructure module.structures name with
  | Option.none => Option.none
  | Option.some structType =>
      match psWasmTypingNth structType.fields index with
      | Option.none => Option.none
      | Option.some field =>
          if (if packed then psWasmTypingStoragePacked field.storageType else if psWasmTypingStoragePacked field.storageType then false else true) then
            psWasmTypingApply module [PsWasmValueType.refT name]
              [psWasmTypingUnpack field.storageType] state
          else Option.none

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

def psWasmTypingArrayNew
    (module : PsWasmModule) (name : String) (defaultValue : Bool)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmIrFindArray module.arrays name with
  | Option.none => Option.none
  | Option.some array =>
      let type : PsWasmValueType := psWasmTypingUnpack array.elementType;
      if defaultValue then
        if psWasmTypingDefaultable type then
          psWasmTypingApply module [PsWasmValueType.i32] [PsWasmValueType.refT name] state
        else Option.none
      else
        psWasmTypingApply module [type, PsWasmValueType.i32] [PsWasmValueType.refT name] state

def psWasmTypingArrayNewFixed
    (module : PsWasmModule) (name : String) (count : Nat)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  if Nat.ble count 4294967295 then
    match psWasmIrFindArray module.arrays name with
    | Option.none => Option.none
    | Option.some array =>
        match psWasmTypingRepeatPop module (psWasmTypingUnpack array.elementType) count state with
        | Option.none => Option.none
        | Option.some next =>
            Option.some (psWasmTypingPush (PsWasmOperandType.value (PsWasmValueType.refT name)) next)
  else Option.none

def psWasmTypingArrayGet
    (module : PsWasmModule) (name : String) (packed : Bool)
    (state : PsWasmTypingState) : Option PsWasmTypingState :=
  match psWasmIrFindArray module.arrays name with
  | Option.none => Option.none
  | Option.some array =>
      if (if packed then psWasmTypingStoragePacked array.elementType else if psWasmTypingStoragePacked array.elementType then false else true) then
        psWasmTypingApply module [PsWasmValueType.refT name, PsWasmValueType.i32]
          [psWasmTypingUnpack array.elementType] state
      else Option.none

def psWasmTypingArraySet
    (module : PsWasmModule) (name : String) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match psWasmIrFindArray module.arrays name with
  | Option.none => Option.none
  | Option.some array =>
      if array.mutable then
        psWasmTypingApply module
          [PsWasmValueType.refT name, PsWasmValueType.i32, psWasmTypingUnpack array.elementType]
          List.nil state
      else Option.none

def psWasmTypingArrayLen (module : PsWasmModule) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match psWasmTypingPop state with
  | Option.none => Option.none
  | Option.some popped =>
      let valid : Bool :=
        match Prod.fst popped with
        | PsWasmOperandType.bottom => true
        | PsWasmOperandType.value type =>
            match type with
            | PsWasmValueType.refT name =>
                match psWasmIrFindArray module.arrays name with
                | Option.none => false
                | Option.some _ => true
            | _ => false
        | _ => false;
      if valid then
        Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.i32) (Prod.snd popped))
      else Option.none

def psWasmTypingArrayCopy
    (module : PsWasmModule) (destination source : String) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match psWasmIrFindArray module.arrays destination with
  | Option.none => Option.none
  | Option.some target =>
      match psWasmIrFindArray module.arrays source with
      | Option.none => Option.none
      | Option.some origin =>
          if target.mutable then
            if psWasmTypingStorageMatches module origin.elementType target.elementType then
              psWasmTypingApply module
                [PsWasmValueType.refT destination, PsWasmValueType.i32,
                 PsWasmValueType.refT source, PsWasmValueType.i32, PsWasmValueType.i32]
                List.nil state
            else Option.none
          else Option.none

def psWasmTypingInstruction
    (module : PsWasmModule) (function : PsWasmFunction) (locals : List PsWasmValueType)
    (instruction : PsWasmInstruction) (state : PsWasmTypingState) :
    Option PsWasmTypingState :=
  match instruction with
  | PsWasmInstruction.localGet index => psWasmTypingLocalGet function locals index state
  | PsWasmInstruction.localSet index => psWasmTypingLocalSet module locals index state
  | PsWasmInstruction.drop =>
      match psWasmTypingPop state with
      | Option.none => Option.none
      | Option.some popped => Option.some (Prod.snd popped)
  | PsWasmInstruction.unreachable => Option.some (psWasmTypingUnreachable state)
  | PsWasmInstruction.return_ => psWasmTypingReturn module function.results state
  | PsWasmInstruction.call name => psWasmTypingCall module function name false state
  | PsWasmInstruction.returnCall name => psWasmTypingCall module function name true state
  | PsWasmInstruction.callRef name => psWasmTypingCallRef module function name false state
  | PsWasmInstruction.returnCallRef name => psWasmTypingCallRef module function name true state
  | PsWasmInstruction.ifStart result => psWasmTypingEnterIf module result state
  | PsWasmInstruction.else_ => psWasmTypingElse module state
  | PsWasmInstruction.end_ => psWasmTypingEnd module state
  | PsWasmInstruction.i32Const _ =>
      Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.i32) state)
  | PsWasmInstruction.i64Const _ =>
      Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.i64) state)
  | PsWasmInstruction.f32ConstBits _ =>
      Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.f32) state)
  | PsWasmInstruction.f64ConstBits _ =>
      Option.some (psWasmTypingPush (PsWasmOperandType.value PsWasmValueType.f64) state)
  | PsWasmInstruction.i32Add =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Sub =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Mul =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32And =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Or =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Xor =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32ShrU =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64Add =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.i64Sub =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.i64Mul =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.i64And =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.i64Or =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.i64Xor =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i64] state
  | PsWasmInstruction.f32Add =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.f32] state
  | PsWasmInstruction.f32Sub =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.f32] state
  | PsWasmInstruction.f32Mul =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.f32] state
  | PsWasmInstruction.f32Div =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.f32] state
  | PsWasmInstruction.f64Add =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.f64] state
  | PsWasmInstruction.f64Sub =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.f64] state
  | PsWasmInstruction.f64Mul =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.f64] state
  | PsWasmInstruction.f64Div =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.f64] state
  | PsWasmInstruction.i32Eq =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Ne =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32LtS =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32LtU =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32LeS =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32LeU =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32GtS =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32GtU =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32GeS =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32GeU =>
      psWasmTypingApply module [PsWasmValueType.i32, PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64Eq =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64Ne =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64LtS =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64LtU =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64LeS =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64LeU =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64GtS =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64GtU =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64GeS =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i64GeU =>
      psWasmTypingApply module [PsWasmValueType.i64, PsWasmValueType.i64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Eq =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Ne =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Lt =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Le =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Gt =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f32Ge =>
      psWasmTypingApply module [PsWasmValueType.f32, PsWasmValueType.f32] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Eq =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Ne =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Lt =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Le =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Gt =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.f64Ge =>
      psWasmTypingApply module [PsWasmValueType.f64, PsWasmValueType.f64] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Extend8S =>
      psWasmTypingApply module [PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.i32Extend16S =>
      psWasmTypingApply module [PsWasmValueType.i32] [PsWasmValueType.i32] state
  | PsWasmInstruction.structNew name =>
      match psWasmIrFindStructure module.structures name with
      | Option.none => Option.none
      | Option.some structType =>
          psWasmTypingApply module (psListMap psWasmTypingFieldType structType.fields)
            [PsWasmValueType.refT name] state
  | PsWasmInstruction.structGet name index => psWasmTypingStructGet module name index false state
  | PsWasmInstruction.structGetS name index => psWasmTypingStructGet module name index true state
  | PsWasmInstruction.structGetU name index => psWasmTypingStructGet module name index true state
  | PsWasmInstruction.arrayNew name => psWasmTypingArrayNew module name false state
  | PsWasmInstruction.arrayNewDefault name => psWasmTypingArrayNew module name true state
  | PsWasmInstruction.arrayNewFixed name count => psWasmTypingArrayNewFixed module name count state
  | PsWasmInstruction.arrayGet name => psWasmTypingArrayGet module name false state
  | PsWasmInstruction.arrayGetS name => psWasmTypingArrayGet module name true state
  | PsWasmInstruction.arrayGetU name => psWasmTypingArrayGet module name true state
  | PsWasmInstruction.arraySet name => psWasmTypingArraySet module name state
  | PsWasmInstruction.arrayLen => psWasmTypingArrayLen module state
  | PsWasmInstruction.arrayCopy destination source => psWasmTypingArrayCopy module destination source state
  | PsWasmInstruction.refTest _ => psWasmTypingReference module instruction state
  | PsWasmInstruction.refCast _ => psWasmTypingReference module instruction state
  | PsWasmInstruction.refFunc _ => psWasmTypingReference module instruction state
  | PsWasmInstruction.refCastFunction _ => psWasmTypingReference module instruction state

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

def psWasmTypingValidateFunction
    (module : PsWasmModule) (function : PsWasmFunction) : Bool :=
  let initial : PsWasmTypingState :=
    PsWasmTypingState.mk List.nil false List.nil List.nil;
  let locals : List PsWasmValueType := psListAppend function.parameters function.locals;
  match psWasmTypingInstructions module function locals function.body initial with
  | Option.none => false
  | Option.some finalState =>
      if psListIsEmpty finalState.frames then
        psWasmTypingFinish module function.results finalState
      else false

def psWasmTypingValidateFunctions
    (module : PsWasmModule) (functions : List PsWasmFunction) :
    Except PsWasmIrValidationError Unit :=
  match functions with
  | List.nil => Except.ok Unit.unit
  | List.cons function rest =>
      if psWasmTypingValidateFunction module function then
        psWasmTypingValidateFunctions module rest
      else Except.error (PsWasmIrValidationError.invalidFunctionBody function.name)
