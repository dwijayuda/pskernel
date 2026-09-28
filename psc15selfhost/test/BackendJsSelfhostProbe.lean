import Ps.BackendJs.Module

-- Portable test input compiled together with the real backend closure.
def psJsSelfhostProbe (_value : Unit) : String :=
  -- Keep the exact > Number.MAX_SAFE_INTEGER Nat runtime value, but construct it
  -- from small PSC1-admitted source literals so checked admission does not need
  -- to recursively decimalize one enormous source numeral.
  let n1 := Nat.add (Nat.mul 9 1000) 7;
  let n2 := Nat.add (Nat.mul n1 1000) 199;
  let n3 := Nat.add (Nat.mul n2 1000) 254;
  let n4 := Nat.add (Nat.mul n3 1000) 740;
  let n5 := Nat.add (Nat.mul n4 1000) 993;
  let n6 := Nat.add (Nat.mul n5 1000) 123;
  let n7 := Nat.add (Nat.mul n6 1000) 456;
  let hugeNat := Nat.add (Nat.mul n7 1000) 789;
  let body := PsVerifiedIrExpr.letE
    "a-b"
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural hugeNat))
    (PsVerifiedIrExpr.var "a-b");
  let declaration := PsVerifiedIrDeclaration.mk
    "answer" List.nil List.nil
    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
    body;
  let module := PsVerifiedIrModule.mk List.nil List.nil List.nil
    (List.cons declaration List.nil);
  match psJsEmitModule module with
  | Except.error _ => "BACKEND_JS_PROBE_ERROR"
  | Except.ok output => output
