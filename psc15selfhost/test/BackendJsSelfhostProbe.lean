import Ps.BackendJs.Module

-- Portable test input compiled together with the real backend closure.
def psJsSelfhostProbe (_value : Unit) : String :=
  -- Keep this source-admission probe modest. Exact huge-Nat BigInt semantics are
  -- covered by the hosted backend execution/differential fixture instead.
  let body := PsVerifiedIrExpr.letE
    "a-b"
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 42))
    (PsVerifiedIrExpr.var "a-b");
  match
      psJsEmitModule
        (PsVerifiedIrModule.mk
          List.nil
          List.nil
          List.nil
          (List.cons
            (PsVerifiedIrDeclaration.mk
              "answer"
              List.nil
              List.nil
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              body)
            List.nil)) with
  | Except.error _ => "BACKEND_JS_PROBE_ERROR"
  | Except.ok output => output
