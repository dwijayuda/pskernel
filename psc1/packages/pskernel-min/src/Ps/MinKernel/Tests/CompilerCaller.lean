import Ps.Erasure.Expr

-- Test-only callers of the actual recursive eraser; no checker input authority.
def psCallerLetChain (depth : Nat) (typeBinder : Bool) (body : PsExpr) : PsExpr :=
  match depth with
  | Nat.zero => body
  | Nat.succ remaining =>
      let domain := if typeBinder then PsExpr.sortE (PsLevel.succ PsLevel.zero) else PsExpr.sortE PsLevel.zero;
      let value := if typeBinder then PsExpr.sortE PsLevel.zero
        else PsExpr.forallE PsName.anonymous (PsExpr.sortE PsLevel.zero) (PsExpr.bvar 0) PsBinderInfo.explicit;
      PsExpr.letE PsName.anonymous domain value (psCallerLetChain remaining typeBinder body)

def psCallerNatProbe (depth : Nat) (typeBinder : Bool) (fuel : Nat) (value : Nat) : Bool :=
  let source := psCallerLetChain depth typeBinder (PsExpr.lit (PsLiteral.natural value));
  match psEraseRuntimeExprWithFuelWorker psEnvironmentEmpty fuel (psErasureScopeEmpty List.nil) source with
  | Except.ok result =>
      match result with
      | PsVerifiedIrExpr.literal literal =>
          match literal with
          | PsVerifiedIrLiteral.natural actual => Nat.beq value actual
          | _ => false
      | _ => false
  | Except.error _ => false

def psCallerTextProbe (depth : Nat) (typeBinder : Bool) (fuel : Nat) (value : String) : String :=
  let source := psCallerLetChain depth typeBinder (PsExpr.lit (PsLiteral.string value));
  match psEraseRuntimeExprWithFuelWorker psEnvironmentEmpty fuel (psErasureScopeEmpty List.nil) source with
  | Except.ok result =>
      match result with
      | PsVerifiedIrExpr.literal literal =>
          match literal with
          | PsVerifiedIrLiteral.string actual => String.append "ok:" actual
          | _ => "refused"
      | _ => "refused"
  | Except.error _ => "refused"
