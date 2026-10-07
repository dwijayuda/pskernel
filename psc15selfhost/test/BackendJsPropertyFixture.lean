import Ps.CompilerIr.Interface
import Ps.BackendJs.Print
import Ps.BackendTs.Module

-- Shared validated input exercises own-data-property semantics in both backends.
def psPropertyNat : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psPropertyRecordType : PsVerifiedIrType :=
  PsVerifiedIrType.named "PropertyRecord" []

def psPropertyObjectType : PsVerifiedIrType :=
  PsVerifiedIrType.named "PropertyObject" []

def psPropertySumType : PsVerifiedIrType :=
  PsVerifiedIrType.named "PropertySum" []

def psPropertyRecord (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.record "PropertyRecord" []
    [("__proto__", value), ("constructor", value), ("prototype", value), ("toString", value)]

def psPropertyPayload (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.constructor "PropertySum" "__proto__" [] [("__proto__", value)]

def psPropertyFixture : PsVerifiedIrModule :=
  PsVerifiedIrModule.mk []
    [PsVerifiedIrStructure.mk "PropertyRecord" []
      [PsVerifiedIrStructureField.mk "__proto__" psPropertyNat,
       PsVerifiedIrStructureField.mk "constructor" psPropertyNat,
       PsVerifiedIrStructureField.mk "prototype" psPropertyNat,
       PsVerifiedIrStructureField.mk "toString" psPropertyNat],
     PsVerifiedIrStructure.mk "PropertyObject" []
      [PsVerifiedIrStructureField.mk "__proto__" psPropertyRecordType]]
    [PsVerifiedIrInductive.mk "PropertySum" []
      [PsVerifiedIrConstructor.mk "__proto__"
        [PsVerifiedIrConstructorField.mk "__proto__" psPropertyNat],
       PsVerifiedIrConstructor.mk "constructor" []],
     PsVerifiedIrInductive.mk "PropertyEmpty" []
      [PsVerifiedIrConstructor.mk "__proto__" []]]
    [PsVerifiedIrDeclaration.mk "primitiveRecord" []
      [PsVerifiedIrParameter.mk "value" psPropertyNat] psPropertyRecordType
      (psPropertyRecord (PsVerifiedIrExpr.var "value")),
     PsVerifiedIrDeclaration.mk "objectRecord" []
      [PsVerifiedIrParameter.mk "value" psPropertyNat] psPropertyObjectType
      (PsVerifiedIrExpr.record "PropertyObject" []
        [("__proto__", psPropertyRecord (PsVerifiedIrExpr.var "value"))]),
     PsVerifiedIrDeclaration.mk "readRecord" []
      [PsVerifiedIrParameter.mk "value" psPropertyNat] psPropertyNat
      (PsVerifiedIrExpr.projection "PropertyRecord" []
        (psPropertyRecord (PsVerifiedIrExpr.var "value")) "__proto__"),
     PsVerifiedIrDeclaration.mk "payload" []
      [PsVerifiedIrParameter.mk "value" psPropertyNat] psPropertySumType
      (psPropertyPayload (PsVerifiedIrExpr.var "value")),
     PsVerifiedIrDeclaration.mk "readPayload" []
      [PsVerifiedIrParameter.mk "value" psPropertyNat] psPropertyNat
      (PsVerifiedIrExpr.matchE "PropertySum" [] (psPropertyPayload (PsVerifiedIrExpr.var "value"))
        [("__proto__", [PsVerifiedIrMatchBinding.mk "__proto__" "field" psPropertyNat],
          PsVerifiedIrExpr.var "field"),
         ("constructor", [], PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0))]),
     PsVerifiedIrDeclaration.mk "emptyPayload" [] [] psPropertySumType
      (PsVerifiedIrExpr.constructor "PropertySum" "constructor" [] []),
     PsVerifiedIrDeclaration.mk "emptyProto" [] [] (PsVerifiedIrType.named "PropertyEmpty" [])
      (PsVerifiedIrExpr.constructor "PropertyEmpty" "__proto__" [] []),
     PsVerifiedIrDeclaration.mk "orderedRecord" []
      [PsVerifiedIrParameter.mk "next" (PsVerifiedIrType.function [psPropertyNat] psPropertyNat)]
      psPropertyRecordType
      (PsVerifiedIrExpr.record "PropertyRecord" []
        [("__proto__", PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "next") []
          [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)]),
         ("constructor", PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "next") []
          [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2)]),
         ("prototype", PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "next") []
          [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 3)]),
         ("toString", PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "next") []
          [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 4)])])]

def psPropertyEmit (target : String) : Except String String :=
  match psValidateErasedIrModule (PsErasedIrModule.mk psPropertyFixture) with
  | Except.error _ => Except.error "PROPERTY_VALIDATION"
  | Except.ok validated =>
      if psStringEq target "properties-ts" then
        match psTsEmitValidatedModule validated with
        | Except.error _ => Except.error "PROPERTY_TS"
        | Except.ok output => Except.ok output
      else
        match psJsLowerValidatedModule validated with
        | Except.error _ => Except.error "PROPERTY_JS_LOWER"
        | Except.ok lowered =>
            match psJsValidateModule lowered with
            | Except.error _ => Except.error "PROPERTY_JS_VALIDATE"
            | Except.ok _ =>
                let emitted := if psStringEq target "properties-js-stack" then
                  psJsPrintModuleStackSafe lowered else psJsPrintModule lowered;
                match emitted with
                | Except.error _ => Except.error "PROPERTY_JS_PRINT"
                | Except.ok output => Except.ok output
