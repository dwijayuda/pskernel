import Ps.BackendTs.Expr

-- Test-only compatibility probe; not a minimal-kernel runtime module.
def psR6ModernAppend (left : String) (right : String) : String :=
  String.append left right

def psR6LegacyAppend (left : String) (right : String) : String :=
  String.Internal.append left right

def psR6EmitAdd (left right : String) : String :=
  match psTsEmitIntrinsicFromPrinted .natAdd [left, right] with
  | .ok text => text
  | .error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"

def psR6EmitAnd (left right : String) : String :=
  match psTsEmitIntrinsicFromPrinted .boolAnd [left, right] with
  | .ok text => text
  | .error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"

def psR6EmitSub (left right : String) : String :=
  match psTsEmitIntrinsicFromPrinted .natSub [left, right] with
  | .ok text => text
  | .error _ => "R6_UNEXPECTED_EMITTER_REFUSAL"
