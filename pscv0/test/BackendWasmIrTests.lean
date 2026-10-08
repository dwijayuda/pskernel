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

def psWasmIrTestBody (body : List PsWasmInstruction) : Bool :=
  match psWasmIrValidateModule (psWasmIrTestModule [psWasmIrTestFunction "f" body] []) with
  | Except.ok _ => true
  | Except.error _ => false

def psWasmIrTestTypingRejects : Bool :=
  !psWasmIrTestBody [] &&
  !psWasmIrTestBody [.i64Const 42] &&
  !psWasmIrTestBody [.i32Add] &&
  !psWasmIrTestBody [.i32Const 1, .i32Const 2] &&
  !psWasmIrTestBody [.i32Const 1, .ifStart (some .i32), .i32Const 2, .end_] &&
  !psWasmIrTestBody [.i32Const 1, .ifStart (some .i32), .i32Const 2, .else_, .i64Const 3, .end_] &&
  !psWasmIrTestBody [.unreachable, .i32Const 1, .i64Add] &&
  !psWasmIrTestBody [.i32Const 1, .arrayLen] &&
  !psWasmIrTestBody [.i32Const 1, .localSet 0]

def psWasmIrTestTypingAccepts : Bool :=
  psWasmIrTestBody [.unreachable] &&
  psWasmIrTestBody [.i32Const 1, .return_] &&
  psWasmIrTestBody [.i32Const 1, .i32Const 2, .i32Add] &&
  psWasmIrTestBody [.i32Const 1, .ifStart (some .i32), .i32Const 2, .else_, .unreachable, .end_] &&
  psWasmIrTestBody [.i32Const 1, .ifStart none, .else_, .end_, .i32Const 3]

def psWasmIrTestGcModule (body : List PsWasmInstruction) : PsWasmModule :=
  {
    structures := [
      { name := "Base", superType := none, isFinal := false, fields := [] },
      { name := "Child", superType := some "Base", isFinal := true, fields := [
        { name := "byte", storageType := .packedI8 }
      ] }
    ]
    arrays := [
      { name := "Bytes", elementType := .packedI8, mutable := true },
      { name := "Frozen", elementType := .packedI8, mutable := false },
      { name := "Refs", elementType := .value (.refT "Base"), mutable := true }
    ]
    functionTypes := []
    functions := [{ (psWasmIrTestFunction "f" body) with locals := [.refT "Base"] }]
    functionRefs := []
    exports := []
  }

def psWasmIrTestModuleAccepts (module : PsWasmModule) : Bool :=
  match psWasmIrValidateModule module with
  | Except.ok _ => true
  | Except.error _ => false

def psWasmIrTestGcTyping : Bool :=
  let accepts := fun body => psWasmIrTestModuleAccepts (psWasmIrTestGcModule body)
  accepts [.i32Const 7, .structNew "Child", .structGetU "Child" 0] &&
  !accepts [.i32Const 7, .structNew "Child", .structGet "Child" 0] &&
  accepts [.i32Const 7, .structNew "Child", .localSet 0, .localGet 0, .drop, .i32Const 0] &&
  !accepts [.localGet 0, .drop, .i32Const 0] &&
  !accepts [.i32Const 1, .ifStart none, .structNew "Base", .localSet 0, .end_, .localGet 0, .drop, .i32Const 0] &&
  accepts [.i32Const 8, .arrayNewDefault "Bytes", .arrayLen] &&
  !accepts [.i32Const 8, .arrayNewDefault "Refs", .arrayLen] &&
  accepts [.i32Const 8, .arrayNewDefault "Bytes", .i32Const 0, .arrayGetU "Bytes"] &&
  !accepts [.i32Const 8, .arrayNewDefault "Bytes", .i32Const 0, .arrayGet "Bytes"] &&
  !accepts [.i32Const 8, .arrayNewDefault "Frozen", .i32Const 0, .i32Const 9, .arraySet "Frozen", .i32Const 0]

def psWasmIrTestParentTyping : Bool :=
  let base := psWasmIrTestGcModule [.i32Const 0]
  let reversed := { base with structures := base.structures.reverse }
  let finalParent := { base with structures := [
    { name := "Base", superType := none, isFinal := true, fields := [] },
    { name := "Child", superType := some "Base", isFinal := true, fields := [] }
  ] }
  let badField := { base with structures := [
    { name := "Base", superType := none, isFinal := false, fields := [{ name := "x", storageType := .value .i32 }] },
    { name := "Child", superType := some "Base", isFinal := true, fields := [{ name := "x", storageType := .value .i64 }] }
  ] }
  psWasmIrTestModuleAccepts base && !psWasmIrTestModuleAccepts reversed &&
  !psWasmIrTestModuleAccepts finalParent && !psWasmIrTestModuleAccepts badField

def psWasmIrTestCallTyping : Bool :=
  let callee := { (psWasmIrTestFunction "callee" [.localGet 0]) with
    typeName := some "Unary", parameters := [.i32] }
  let build := fun body => {
    (psWasmIrTestModule [callee, psWasmIrTestFunction "caller" body] []) with
    functionTypes := [{ name := "Unary", parameters := [.i32], results := [.i32] }]
    functionRefs := ["callee"]
  }
  psWasmIrTestModuleAccepts (build [.i32Const 7, .call "callee"]) &&
  !psWasmIrTestModuleAccepts (build [.call "callee"]) &&
  !psWasmIrTestModuleAccepts (build [.i64Const 7, .call "callee"]) &&
  psWasmIrTestModuleAccepts (build [.i32Const 7, .returnCall "callee"]) &&
  psWasmIrTestModuleAccepts (build [.i32Const 7, .refFunc "callee", .callRef "Unary"]) &&
  psWasmIrTestModuleAccepts (build [.i32Const 7, .refFunc "callee", .returnCallRef "Unary"]) &&
  !psWasmIrTestModuleAccepts { (build [.i32Const 7, .refFunc "callee", .callRef "Unary"]) with functionRefs := [] }

def psWasmIrTestNoValue : Bool :=
  !psWasmIrTestModuleAccepts
    (psWasmIrTestModule [{ (psWasmIrTestFunction "f" []) with results := [.noValue] }] [])

structure PsWasmIrNamedTest where
  name : String
  passed : Bool

def psWasmIrTests : List PsWasmIrNamedTest :=
  [
    { name := "valid", passed := psWasmIrTestValid },
    { name := "operand and control typing rejection", passed := psWasmIrTestTypingRejects },
    { name := "unreachable and control typing acceptance", passed := psWasmIrTestTypingAccepts },
    { name := "GC field array and local initialization typing", passed := psWasmIrTestGcTyping },
    { name := "structure parent typing", passed := psWasmIrTestParentTyping },
    { name := "direct and indirect call typing", passed := psWasmIrTestCallTyping },
    { name := "noValue is not a value type", passed := psWasmIrTestNoValue },
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
