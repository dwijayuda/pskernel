import Ps.BackendJs.Validate

def psJsValidationTestDeclaration
    (name : String)
    (body : PsJsIrExpr) :
    PsJsIrDeclaration :=
  PsJsIrDeclaration.mk
    name
    List.nil
    body

def psJsValidationTestModule
    (imports : List PsJsIrImport)
    (declarations : List PsJsIrDeclaration) :
    PsJsIrModule :=
  PsJsIrModule.mk imports declarations

def psJsValidationAccepted
    (module : PsJsIrModule) : Bool :=
  match psJsValidateModule module with
  | Except.error _ => false
  | Except.ok _ => true

def psJsValidationTestValid : Bool :=
  psJsValidationAccepted
    (psJsValidationTestModule
      List.nil
      (List.cons
        (psJsValidationTestDeclaration
          "answer"
          (PsJsIrExpr.literal
            (PsJsIrLiteral.natural 42)))
        List.nil))

def psJsValidationTestDuplicateGlobal : Bool :=
  let first :=
    psJsValidationTestDeclaration
      "answer"
      (PsJsIrExpr.literal
        (PsJsIrLiteral.natural 1));
  let second :=
    psJsValidationTestDeclaration
      "answer"
      (PsJsIrExpr.literal
        (PsJsIrLiteral.natural 2));
  match
      psJsValidateModule
        (psJsValidationTestModule
          List.nil
          (List.cons first
            (List.cons second List.nil))) with
  | Except.error
      (PsJsIrValidationError.duplicateGlobal _) =>
      true
  | _ => false

def psJsValidationTestUnknownVariable : Bool :=
  match
      psJsValidateModule
        (psJsValidationTestModule
          List.nil
          (List.cons
            (psJsValidationTestDeclaration
              "answer"
              (PsJsIrExpr.var "missing"))
            List.nil)) with
  | Except.error
      (PsJsIrValidationError.unknownVariable name) =>
      psStringEq name "missing"
  | _ => false

def psJsValidationTestRuntimeArity : Bool :=
  let body :=
    PsJsIrExpr.runtime
      PsJsIrRuntimeOp.natSub
      (List.cons
        (PsJsIrExpr.literal
          (PsJsIrLiteral.natural 1))
        List.nil);
  match
      psJsValidateModule
        (psJsValidationTestModule
          List.nil
          (List.cons
            (psJsValidationTestDeclaration
              "answer"
              body)
            List.nil)) with
  | Except.error
      PsJsIrValidationError.invalidRuntimeArity =>
      true
  | _ => false

def psJsValidationTestDuplicateField : Bool :=
  let field :=
    Prod.mk
      "value"
      (PsJsIrExpr.literal
        (PsJsIrLiteral.natural 1));
  let body :=
    PsJsIrExpr.record
      (List.cons field
        (List.cons field List.nil));
  match
      psJsValidateModule
        (psJsValidationTestModule
          List.nil
          (List.cons
            (psJsValidationTestDeclaration
              "answer"
              body)
            List.nil)) with
  | Except.error
      (PsJsIrValidationError.duplicateField _) =>
      true
  | _ => false

def psJsValidationTestBadMachineLiteral : Bool :=
  let body :=
    PsJsIrExpr.literal
      (PsJsIrLiteral.machineInteger
        PsJsIrMachineIntegerType.uint8
        256);
  match
      psJsValidateModule
        (psJsValidationTestModule
          List.nil
          (List.cons
            (psJsValidationTestDeclaration
              "answer"
              body)
            List.nil)) with
  | Except.error
      PsJsIrValidationError.invalidMachineIntegerLiteral =>
      true
  | _ => false

def psJsValidationTestImportCollision : Bool :=
  let importInfo :=
    PsJsIrImport.mk
      "answer"
      "host"
      "answer";
  match
      psJsValidateModule
        (psJsValidationTestModule
          (List.cons importInfo List.nil)
          (List.cons
            (psJsValidationTestDeclaration
              "answer"
              (PsJsIrExpr.literal
                PsJsIrLiteral.unit))
            List.nil)) with
  | Except.error
      (PsJsIrValidationError.duplicateGlobal _) =>
      true
  | _ => false

def psJsValidationTestLambdaScope : Bool :=
  let body :=
    PsJsIrExpr.lambda
      (List.cons "value" List.nil)
      (PsJsIrExpr.var "value");
  psJsValidationAccepted
    (psJsValidationTestModule
      List.nil
      (List.cons
        (psJsValidationTestDeclaration
          "identity"
          body)
        List.nil))

structure PsJsValidationNamedTest where
  name : String
  passed : Bool

def psJsValidationTests :
    List PsJsValidationNamedTest :=
  [
    { name := "valid", passed := psJsValidationTestValid },
    { name := "duplicate global", passed := psJsValidationTestDuplicateGlobal },
    { name := "unknown variable", passed := psJsValidationTestUnknownVariable },
    { name := "runtime arity", passed := psJsValidationTestRuntimeArity },
    { name := "duplicate field", passed := psJsValidationTestDuplicateField },
    { name := "machine literal", passed := psJsValidationTestBadMachineLiteral },
    { name := "import collision", passed := psJsValidationTestImportCollision },
    { name := "lambda scope", passed := psJsValidationTestLambdaScope }
  ]

def psRunJsValidationTests
    (tests : List PsJsValidationNamedTest) :
    IO Bool :=
  match tests with
  | List.nil =>
      pure true
  | List.cons test rest => do
      if test.passed then
        IO.println
          (String.Internal.append
            "PSCV_JS_IR_VALIDATION_PASS: "
            test.name)
      else
        IO.println
          (String.Internal.append
            "PSCV_JS_IR_VALIDATION_FAIL: "
            test.name)
      let tailPassed ←
        psRunJsValidationTests rest
      pure
        (if test.passed then
          tailPassed
        else
          false)

def main : IO Unit := do
  let passed ←
    psRunJsValidationTests
      psJsValidationTests
  if passed then
    IO.println
      "PSCV_JS_IR_VALIDATION_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSCV_JS_IR_VALIDATION_TESTS: FAIL")
