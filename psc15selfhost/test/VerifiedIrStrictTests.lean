import Ps.CompilerIr.Validate

def psStrictTestNat : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psStrictTestBool : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

def psStrictTestBoxType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Box" List.nil

def psStrictTestChoiceType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Choice" List.nil

def psStrictTestPayloadType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Payload" List.nil

def psStrictTestBox : PsVerifiedIrStructure :=
  PsVerifiedIrStructure.mk
    "Box"
    List.nil
    (List.cons
      (PsVerifiedIrStructureField.mk
        "value"
        psStrictTestNat)
      List.nil)

def psStrictTestChoice : PsVerifiedIrInductive :=
  PsVerifiedIrInductive.mk
    "Choice"
    List.nil
    (List.cons
      (PsVerifiedIrConstructor.mk
        "left"
        List.nil)
      (List.cons
        (PsVerifiedIrConstructor.mk
          "right"
          List.nil)
        List.nil))

def psStrictTestPayload : PsVerifiedIrInductive :=
  PsVerifiedIrInductive.mk
    "Payload"
    List.nil
    (List.cons
      (PsVerifiedIrConstructor.mk
        "some"
        (List.cons
          (PsVerifiedIrConstructorField.mk
            "value"
            psStrictTestNat)
          List.nil))
      List.nil)

def psStrictTestDeclaration
    (name : String)
    (parameters : List PsVerifiedIrParameter)
    (resultType : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) :
    PsVerifiedIrDeclaration :=
  PsVerifiedIrDeclaration.mk
    name
    List.nil
    parameters
    resultType
    body

def psStrictTestModule
    (structures : List PsVerifiedIrStructure)
    (inductives : List PsVerifiedIrInductive)
    (declarations : List PsVerifiedIrDeclaration) :
    PsVerifiedIrModule :=
  PsVerifiedIrModule.mk
    List.nil
    structures
    inductives
    declarations

def psStrictTestAccepted
    (module : PsVerifiedIrModule) : Bool :=
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk module) with
  | Except.error _ => false
  | Except.ok _ => true

def psStrictTestDuplicateGlobal : Bool :=
  let first :=
    psStrictTestDeclaration
      "dup"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.literal
        (PsVerifiedIrLiteral.natural 1));
  let second :=
    psStrictTestDeclaration
      "dup"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.literal
        (PsVerifiedIrLiteral.natural 2));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons first
              (List.cons second List.nil)))) with
  | Except.error
      (PsVerifiedIrValidationError.duplicateGlobalName _) =>
      true
  | _ => false

def psStrictTestUnknownTypeName : Bool :=
  let declaration :=
    psStrictTestDeclaration
      "bad"
      List.nil
      (PsVerifiedIrType.named "Missing" List.nil)
      (PsVerifiedIrExpr.literal
        PsVerifiedIrLiteral.unit);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons declaration List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.unknownTypeName name) =>
      psStringEq name "Missing"
  | _ => false

def psStrictTestUnknownTypeParameter : Bool :=
  let declaration :=
    psStrictTestDeclaration
      "bad"
      List.nil
      (PsVerifiedIrType.typeParameter "T")
      (PsVerifiedIrExpr.literal
        PsVerifiedIrLiteral.unit);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons declaration List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.unknownTypeParameter name) =>
      psStringEq name "T"
  | _ => false

def psStrictTestUnknownVariable : Bool :=
  let declaration :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.var "missing");
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons declaration List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.unknownVariable name) =>
      psStringEq name "missing"
  | _ => false

def psStrictTestCallArity : Bool :=
  let identity :=
    psStrictTestDeclaration
      "idNat"
      (List.cons
        (PsVerifiedIrParameter.mk
          "value"
          psStrictTestNat)
        List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.var "value");
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.call
        (PsVerifiedIrExpr.var "idNat")
        List.nil
        List.nil);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons identity
              (List.cons bad List.nil)))) with
  | Except.error PsVerifiedIrValidationError.callArity =>
      true
  | _ => false

def psStrictTestIntrinsicArity : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.intrinsic
        PsVerifiedIrIntrinsic.natAdd
        List.nil
        (List.cons
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 1))
          List.nil));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons bad List.nil))) with
  | Except.error PsVerifiedIrValidationError.callArity =>
      true
  | _ => false

def psStrictTestIntrinsicTypeMismatch : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.intrinsic
        PsVerifiedIrIntrinsic.natAdd
        List.nil
        (List.cons
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.bool true))
          (List.cons
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1))
            List.nil)));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestRecordCompleteness : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestBoxType
      (PsVerifiedIrExpr.record
        "Box"
        List.nil
        List.nil);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            (List.cons psStrictTestBox List.nil)
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.fieldCompleteness name) =>
      psStringEq name "Box"
  | _ => false

def psStrictTestDuplicateRecordField : Bool :=
  let fields :=
    List.cons
      (Prod.mk
        "value"
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 1)))
      (List.cons
        (Prod.mk
          "value"
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 2)))
        List.nil);
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestBoxType
      (PsVerifiedIrExpr.record
        "Box"
        List.nil
        fields);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            (List.cons psStrictTestBox List.nil)
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.duplicateField _ _) =>
      true
  | _ => false

def psStrictTestRecordFieldType : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestBoxType
      (PsVerifiedIrExpr.record
        "Box"
        List.nil
        (List.cons
          (Prod.mk
            "value"
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.bool true)))
          List.nil));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            (List.cons psStrictTestBox List.nil)
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestProjectionTarget : Bool :=
  let parameter :=
    PsVerifiedIrParameter.mk
      "value"
      psStrictTestNat;
  let bad :=
    psStrictTestDeclaration
      "bad"
      (List.cons parameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.projection
        "Box"
        List.nil
        (PsVerifiedIrExpr.var "value")
        "value");
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            (List.cons psStrictTestBox List.nil)
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestConstructorCompleteness : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestPayloadType
      (PsVerifiedIrExpr.constructor
        "Payload"
        "some"
        List.nil
        List.nil);
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            (List.cons psStrictTestPayload List.nil)
            (List.cons bad List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.fieldCompleteness name) =>
      psStringEq name "some"
  | _ => false

def psStrictTestIfCondition : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.ifE
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 1))
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 2))
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 3)));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestIfBranchType : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.ifE
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.bool true))
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.natural 2))
        (PsVerifiedIrExpr.literal
          (PsVerifiedIrLiteral.bool false)));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            List.nil
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictChoiceParameter : PsVerifiedIrParameter :=
  PsVerifiedIrParameter.mk
    "choice"
    psStrictTestChoiceType

def psStrictChoiceAlternative
    (constructorName : String)
    (body : PsVerifiedIrExpr) :
    String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr :=
  Prod.mk
    constructorName
    (Prod.mk List.nil body)

def psStrictTestMatchExhaustiveness : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      (List.cons psStrictChoiceParameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.matchE
        "Choice"
        List.nil
        (PsVerifiedIrExpr.var "choice")
        (List.cons
          (psStrictChoiceAlternative
            "left"
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1)))
          List.nil));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            (List.cons psStrictTestChoice List.nil)
            (List.cons bad List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.matchExhaustiveness name) =>
      psStringEq name "Choice"
  | _ => false

def psStrictTestDuplicateAlternative : Bool :=
  let left :=
    psStrictChoiceAlternative
      "left"
      (PsVerifiedIrExpr.literal
        (PsVerifiedIrLiteral.natural 1));
  let bad :=
    psStrictTestDeclaration
      "bad"
      (List.cons psStrictChoiceParameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.matchE
        "Choice"
        List.nil
        (PsVerifiedIrExpr.var "choice")
        (List.cons left
          (List.cons left List.nil)));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            (List.cons psStrictTestChoice List.nil)
            (List.cons bad List.nil))) with
  | Except.error
      (PsVerifiedIrValidationError.duplicateAlternative _) =>
      true
  | _ => false

def psStrictTestMatchBranchType : Bool :=
  let bad :=
    psStrictTestDeclaration
      "bad"
      (List.cons psStrictChoiceParameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.matchE
        "Choice"
        List.nil
        (PsVerifiedIrExpr.var "choice")
        (List.cons
          (psStrictChoiceAlternative
            "left"
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1)))
          (List.cons
            (psStrictChoiceAlternative
              "right"
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.bool true)))
            List.nil)));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            (List.cons psStrictTestChoice List.nil)
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestBindingType : Bool :=
  let binding :=
    PsVerifiedIrMatchBinding.mk
      "value"
      "value"
      psStrictTestBool;
  let alternative :=
    Prod.mk
      "some"
      (Prod.mk
        (List.cons binding List.nil)
        (PsVerifiedIrExpr.var "value"));
  let parameter :=
    PsVerifiedIrParameter.mk
      "payload"
      psStrictTestPayloadType;
  let bad :=
    psStrictTestDeclaration
      "bad"
      (List.cons parameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.matchE
        "Payload"
        List.nil
        (PsVerifiedIrExpr.var "payload")
        (List.cons alternative List.nil));
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          (psStrictTestModule
            List.nil
            (List.cons psStrictTestPayload List.nil)
            (List.cons bad List.nil))) with
  | Except.error
      PsVerifiedIrValidationError.expressionTypeMismatch =>
      true
  | _ => false

def psStrictTestGenericCallAccepted : Bool :=
  let generic :=
    PsVerifiedIrDeclaration.mk
      "identity"
      (List.cons
        (PsVerifiedIrTypeParameter.mk "T")
        List.nil)
      (List.cons
        (PsVerifiedIrParameter.mk
          "value"
          (PsVerifiedIrType.typeParameter "T"))
        List.nil)
      (PsVerifiedIrType.typeParameter "T")
      (PsVerifiedIrExpr.var "value");
  let useGeneric :=
    psStrictTestDeclaration
      "useIdentity"
      List.nil
      psStrictTestNat
      (PsVerifiedIrExpr.call
        (PsVerifiedIrExpr.var "identity")
        (List.cons psStrictTestNat List.nil)
        (List.cons
          (PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42))
          List.nil));
  psStrictTestAccepted
    (psStrictTestModule
      List.nil
      List.nil
      (List.cons generic
        (List.cons useGeneric List.nil)))

def psStrictTestValidAggregateAndMatch : Bool :=
  let boxValue :=
    psStrictTestDeclaration
      "makeBox"
      List.nil
      psStrictTestBoxType
      (PsVerifiedIrExpr.record
        "Box"
        List.nil
        (List.cons
          (Prod.mk
            "value"
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42)))
          List.nil));
  let choice :=
    psStrictTestDeclaration
      "choose"
      (List.cons psStrictChoiceParameter List.nil)
      psStrictTestNat
      (PsVerifiedIrExpr.matchE
        "Choice"
        List.nil
        (PsVerifiedIrExpr.var "choice")
        (List.cons
          (psStrictChoiceAlternative
            "left"
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1)))
          (List.cons
            (psStrictChoiceAlternative
              "right"
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 2)))
            List.nil)));
  psStrictTestAccepted
    (psStrictTestModule
      (List.cons psStrictTestBox List.nil)
      (List.cons psStrictTestChoice List.nil)
      (List.cons boxValue
        (List.cons choice List.nil)))


def psStrictTestPhantomModule (argument : PsVerifiedIrType) : PsVerifiedIrModule :=
  let phantom := PsVerifiedIrInductive.mk "Phantom"
    [PsVerifiedIrTypeParameter.mk "T"]
    [PsVerifiedIrConstructor.mk "only" List.nil];
  let value := PsVerifiedIrExpr.constructor "Phantom" "only" [argument] List.nil;
  let body := PsVerifiedIrExpr.matchE "Phantom" [argument] value
    [Prod.mk "only" (Prod.mk List.nil
      (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)))];
  psStrictTestModule List.nil [phantom]
    [psStrictTestDeclaration "observe" List.nil psStrictTestNat body]

def psStrictTestPhantomUnknownType : Bool :=
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestPhantomModule (PsVerifiedIrType.named "Missing" List.nil))) with
  | Except.error (PsVerifiedIrValidationError.unknownTypeName _) => true
  | _ => false

def psStrictTestPhantomUnboundParameter : Bool :=
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestPhantomModule (PsVerifiedIrType.typeParameter "Unbound"))) with
  | Except.error (PsVerifiedIrValidationError.unknownTypeParameter _) => true
  | _ => false

def psStrictTestBuiltinArrayShadow : Bool :=
  let fakeArray := PsVerifiedIrStructure.mk "Array"
    [PsVerifiedIrTypeParameter.mk "T"]
    [PsVerifiedIrStructureField.mk "value" (PsVerifiedIrType.typeParameter "T")];
  let body := PsVerifiedIrExpr.record "Array" [psStrictTestNat]
    [Prod.mk "value" (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1))];
  let declaration := psStrictTestDeclaration "fake" List.nil
    (PsVerifiedIrType.named "Array" [psStrictTestNat]) body;
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule [fakeArray] List.nil [declaration])) with
  | Except.error (PsVerifiedIrValidationError.duplicateGlobalName _) => true
  | _ => false

def psStrictTestDeclarationRejected (declaration : PsVerifiedIrDeclaration) : Bool :=
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule List.nil List.nil [declaration])) with
  | Except.error PsVerifiedIrValidationError.expressionTypeMismatch => true
  | _ => false

def psStrictTestCallArgumentType : Bool :=
  psStrictTestDeclarationRejected
    (psStrictTestDeclaration "bad" List.nil psStrictTestNat
      (PsVerifiedIrExpr.call
        (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "x" psStrictTestNat]
          psStrictTestNat (PsVerifiedIrExpr.var "x"))
        List.nil [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true)]))

def psStrictTestCallResultType : Bool :=
  psStrictTestDeclarationRejected
    (psStrictTestDeclaration "bad" List.nil psStrictTestBool
      (PsVerifiedIrExpr.call
        (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "x" psStrictTestNat]
          psStrictTestNat (PsVerifiedIrExpr.var "x"))
        List.nil [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)]))

def psStrictTestDuplicateConstructorField : Bool :=
  let field := Prod.mk "value" (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1));
  let declaration := psStrictTestDeclaration "bad" List.nil psStrictTestPayloadType
    (PsVerifiedIrExpr.constructor "Payload" "some" List.nil [field, field]);
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule List.nil [psStrictTestPayload] [declaration])) with
  | Except.error (PsVerifiedIrValidationError.duplicateField _ _) => true
  | _ => false

def psStrictTestDuplicateBindingField : Bool :=
  let binding := PsVerifiedIrMatchBinding.mk "value" "x" psStrictTestNat;
  let body := PsVerifiedIrExpr.matchE "Payload" List.nil (PsVerifiedIrExpr.var "p")
    [Prod.mk "some" (Prod.mk [binding, binding] (PsVerifiedIrExpr.var "x"))];
  let declaration := psStrictTestDeclaration "bad"
    [PsVerifiedIrParameter.mk "p" psStrictTestPayloadType] psStrictTestNat body;
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule List.nil [psStrictTestPayload] [declaration])) with
  | Except.error (PsVerifiedIrValidationError.duplicateField _ _) => true
  | _ => false

def psStrictTestDuplicateBindingLocal : Bool :=
  let pair := PsVerifiedIrInductive.mk "Pair" List.nil
    [PsVerifiedIrConstructor.mk "pair"
      [PsVerifiedIrConstructorField.mk "first" psStrictTestNat,
       PsVerifiedIrConstructorField.mk "second" psStrictTestNat]];
  let body := PsVerifiedIrExpr.matchE "Pair" List.nil (PsVerifiedIrExpr.var "p")
    [Prod.mk "pair" (Prod.mk
      [PsVerifiedIrMatchBinding.mk "first" "x" psStrictTestNat,
       PsVerifiedIrMatchBinding.mk "second" "x" psStrictTestNat]
      (PsVerifiedIrExpr.var "x"))];
  let declaration := psStrictTestDeclaration "bad"
    [PsVerifiedIrParameter.mk "p" (PsVerifiedIrType.named "Pair" List.nil)]
    psStrictTestNat body;
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule List.nil [pair] [declaration])) with
  | Except.error (PsVerifiedIrValidationError.duplicateParameter _) => true
  | _ => false

def psStrictTestBuiltinTypeArity : Bool :=
  let declaration := psStrictTestDeclaration "bad"
    [PsVerifiedIrParameter.mk "xs" (PsVerifiedIrType.named "Array" List.nil)]
    psStrictTestNat (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1));
  match psValidateErasedIrModule (PsErasedIrModule.mk
      (psStrictTestModule List.nil List.nil [declaration])) with
  | Except.error (PsVerifiedIrValidationError.typeArgumentArity _) => true
  | _ => false

def psStrictTestConstructorArgumentScope : Bool :=
  let module := psStrictTestPhantomModule psStrictTestNat;
  match psStrictInferExprWithFuel module List.nil 20 List.nil
      (PsVerifiedIrExpr.constructor "Phantom" "only"
        [PsVerifiedIrType.named "Missing" List.nil] List.nil) with
  | Except.error (PsVerifiedIrValidationError.unknownTypeName _) => true
  | _ => false

structure PsStrictVerifiedIrNamedTest where
  name : String
  passed : Bool

def psStrictVerifiedIrTests :
    List PsStrictVerifiedIrNamedTest :=
  [
    { name := "phantom unknown type", passed := psStrictTestPhantomUnknownType },
    { name := "phantom unbound type parameter", passed := psStrictTestPhantomUnboundParameter },
    { name := "valid phantom type", passed := psStrictTestAccepted (psStrictTestPhantomModule psStrictTestNat) },
    { name := "builtin Array shadow", passed := psStrictTestBuiltinArrayShadow },
    { name := "call argument type", passed := psStrictTestCallArgumentType },
    { name := "call result type", passed := psStrictTestCallResultType },
    { name := "duplicate constructor field", passed := psStrictTestDuplicateConstructorField },
    { name := "duplicate binding field", passed := psStrictTestDuplicateBindingField },
    { name := "duplicate binding local", passed := psStrictTestDuplicateBindingLocal },
    { name := "builtin type arity", passed := psStrictTestBuiltinTypeArity },
    { name := "constructor type argument scope", passed := psStrictTestConstructorArgumentScope },
    { name := "duplicate global", passed := psStrictTestDuplicateGlobal },
    { name := "unknown type name", passed := psStrictTestUnknownTypeName },
    { name := "unknown type parameter", passed := psStrictTestUnknownTypeParameter },
    { name := "unknown variable", passed := psStrictTestUnknownVariable },
    { name := "call arity", passed := psStrictTestCallArity },
    { name := "intrinsic arity", passed := psStrictTestIntrinsicArity },
    { name := "intrinsic type mismatch", passed := psStrictTestIntrinsicTypeMismatch },
    { name := "record completeness", passed := psStrictTestRecordCompleteness },
    { name := "duplicate record field", passed := psStrictTestDuplicateRecordField },
    { name := "record field type", passed := psStrictTestRecordFieldType },
    { name := "projection target", passed := psStrictTestProjectionTarget },
    { name := "constructor completeness", passed := psStrictTestConstructorCompleteness },
    { name := "if condition", passed := psStrictTestIfCondition },
    { name := "if branch type", passed := psStrictTestIfBranchType },
    { name := "match exhaustiveness", passed := psStrictTestMatchExhaustiveness },
    { name := "duplicate alternative", passed := psStrictTestDuplicateAlternative },
    { name := "match branch type", passed := psStrictTestMatchBranchType },
    { name := "binding type", passed := psStrictTestBindingType },
    { name := "generic call accepted", passed := psStrictTestGenericCallAccepted },
    { name := "valid aggregate and match", passed := psStrictTestValidAggregateAndMatch }
  ]

def psRunStrictVerifiedIrTests
    (tests : List PsStrictVerifiedIrNamedTest) :
    IO Bool :=
  match tests with
  | List.nil =>
      pure true
  | List.cons test rest => do
      if test.passed then
        IO.println
          (String.Internal.append
            "PSCV_VERIFIED_IR_STRICT_PASS: "
            test.name)
      else
        IO.println
          (String.Internal.append
            "PSCV_VERIFIED_IR_STRICT_FAIL: "
            test.name)
      let restPassed ←
        psRunStrictVerifiedIrTests rest
      pure
        (if test.passed then
          restPassed
        else
          false)

def main : IO Unit := do
  let passed ←
    psRunStrictVerifiedIrTests
      psStrictVerifiedIrTests
  if passed then
    IO.println "PSCV_VERIFIED_IR_STRICT_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSCV_VERIFIED_IR_STRICT_TESTS: FAIL")
