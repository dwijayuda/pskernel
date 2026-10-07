import Ps.BackendWasm.Encode
import Ps.BackendWasm.ValidateIr

def psWasmIrTestFunction
    (name : String)
    (body : List PsWasmInstruction) :
    PsWasmFunction :=
  {
    name := name
    typeName := Option.none
    parameters := List.nil
    results := [PsWasmValueType.i32]
    locals := List.nil
    body := body
  }

def psWasmIrTestModule
    (functions : List PsWasmFunction)
    (exports : List (String × String)) :
    PsWasmModule :=
  {
    structures := List.nil
    arrays := List.nil
    functionTypes := List.nil
    functions := functions
    functionRefs := List.nil
    exports := exports
  }

def psWasmIrTestValidModule : PsWasmModule :=
  psWasmIrTestModule
    [
      psWasmIrTestFunction
        "answer"
        [PsWasmInstruction.i32Const 42]
    ]
    [Prod.mk "answer" "answer"]

def psWasmIrTestValid : Bool :=
  match psWasmIrValidateModule psWasmIrTestValidModule with
  | Except.error _ => false
  | Except.ok _ =>
      match psWasmIrEncodeModule psWasmIrTestValidModule with
      | Except.error _ => false
      | Except.ok encoded =>
          psStringEq
            encoded
            "[\"psc-wasm-ir-json/1\",[],[],[],[[\"answer\",[\"none\"],[],[[\"i32\"]],[],[[\"i32Const\",\"42\"]]]],[],[[\"answer\",\"answer\"]]]"

def psWasmIrTestDuplicateFunction : Bool :=
  let function :=
    psWasmIrTestFunction
      "answer"
      [PsWasmInstruction.i32Const 42];
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [function, function]
          List.nil) with
  | Except.error
      (PsWasmIrValidationError.duplicateFunctionName _) =>
      true
  | _ => false

def psWasmIrTestBadLocal : Bool :=
  let function :=
    psWasmIrTestFunction
      "answer"
      [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 42
      ];
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [function]
          List.nil) with
  | Except.error
      (PsWasmIrValidationError.invalidLocalIndex name index) =>
      if psStringEq name "answer" then
        Nat.beq index 0
      else
        false
  | _ => false

def psWasmIrTestUnknownCall : Bool :=
  let function :=
    psWasmIrTestFunction
      "answer"
      [PsWasmInstruction.call "missing"];
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [function]
          List.nil) with
  | Except.error
      (PsWasmIrValidationError.unknownFunction name) =>
      psStringEq name "missing"
  | _ => false

def psWasmIrTestBadExport : Bool :=
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [psWasmIrTestFunction
            "answer"
            [PsWasmInstruction.i32Const 42]]
          [Prod.mk "answer" "missing"]) with
  | Except.error
      (PsWasmIrValidationError.unknownFunction name) =>
      psStringEq name "missing"
  | _ => false

def psWasmIrTestControlFlow : Bool :=
  let function :=
    psWasmIrTestFunction
      "answer"
      [
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 42
      ];
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [function]
          List.nil) with
  | Except.error
      (PsWasmIrValidationError.invalidControlFlow name) =>
      psStringEq name "answer"
  | _ => false

def psWasmIrTestDuplicateExport : Bool :=
  match
      psWasmIrValidateModule
        (psWasmIrTestModule
          [psWasmIrTestFunction
            "answer"
            [PsWasmInstruction.i32Const 42]]
          [
            Prod.mk "answer" "answer",
            Prod.mk "answer" "answer"
          ]) with
  | Except.error
      (PsWasmIrValidationError.duplicateExportName _) =>
      true
  | _ => false

structure PsWasmIrNamedTest where
  name : String
  passed : Bool

def psWasmIrTests : List PsWasmIrNamedTest :=
  [
    { name := "valid", passed := psWasmIrTestValid },
    { name := "duplicate function", passed := psWasmIrTestDuplicateFunction },
    { name := "bad local", passed := psWasmIrTestBadLocal },
    { name := "unknown call", passed := psWasmIrTestUnknownCall },
    { name := "bad export", passed := psWasmIrTestBadExport },
    { name := "control flow", passed := psWasmIrTestControlFlow },
    { name := "duplicate export", passed := psWasmIrTestDuplicateExport }
  ]

def psRunWasmIrTests
    (tests : List PsWasmIrNamedTest) :
    IO Bool :=
  match tests with
  | List.nil =>
      pure true
  | List.cons test rest => do
      if test.passed then
        IO.println
          (String.Internal.append
            "PSCV_WASM_IR_PASS: "
            test.name)
      else
        IO.println
          (String.Internal.append
            "PSCV_WASM_IR_FAIL: "
            test.name)
      let restPassed ←
        psRunWasmIrTests rest
      pure
        (if test.passed then
          restPassed
        else
          false)

def main : IO Unit := do
  let passed ←
    psRunWasmIrTests
      psWasmIrTests
  if passed then
    IO.println
      "PSCV_WASM_IR_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSCV_WASM_IR_TESTS: FAIL")
