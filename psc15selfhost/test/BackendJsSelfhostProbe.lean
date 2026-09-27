import Ps.BackendJs.Module

-- Portable test input compiled together with the real backend closure.
def psJsSelfhostProbe (_value : Unit) : String :=
  let declaration := PsVerifiedIrDeclaration.mk
    "answer" List.nil List.nil
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 9007199254740993123456789));
  let module := PsVerifiedIrModule.mk List.nil List.nil List.nil
    (List.cons declaration List.nil);
  match psJsEmitModule module with
  | Except.error _ => "BACKEND_JS_PROBE_ERROR"
  | Except.ok output => output
