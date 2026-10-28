import Ps.BackendTs.Expr

-- Test-only actual-emitter probe; not a minimal-kernel runtime module.
def psR6EmitAdd (left : String) (right : String) : String :=
  match psTsEmitIntrinsicFromPrinted PsVerifiedIrIntrinsic.natAdd
      (List.cons left (List.cons right List.nil)) with
  | Except.ok text => text
  | Except.error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"

def psR6EmitAnd (left : String) (right : String) : String :=
  match psTsEmitIntrinsicFromPrinted PsVerifiedIrIntrinsic.boolAnd
      (List.cons left (List.cons right List.nil)) with
  | Except.ok text => text
  | Except.error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"

def psR6EmitSub (left : String) (right : String) : String :=
  match psTsEmitIntrinsicFromPrinted PsVerifiedIrIntrinsic.natSub
      (List.cons left (List.cons right List.nil)) with
  | Except.ok text => text
  | Except.error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"
