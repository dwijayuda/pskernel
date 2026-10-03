import Init
set_option autoImplicit false

namespace ProofScript.R3.Overlay

inductive Term where
  | nat : Nat -> Term
  | add : Term
  | app : Term -> Term -> Term
  | unit : Term
  deriving DecidableEq, Repr

inductive CallArg where
  | positional : Term -> CallArg
  deriving DecidableEq, Repr

structure ParenthesizedCall where
  head : Term
  args : List CallArg
  deriving DecidableEq, Repr

def lowerArg : CallArg -> Term
  | .positional t => t

def lowerCall (c : ParenthesizedCall) : Term :=
  match c.args with
  | [] => .app c.head .unit
  | args => args.foldl (fun acc a => .app acc (lowerArg a)) c.head

inductive Value where
  | nat : Nat -> Value
  | add0
  | add1 : Nat -> Value
  | unit
  deriving DecidableEq, Repr

def applyValue : Value -> Value -> Option Value
  | .add0, .nat n => some (.add1 n)
  | .add1 n, .nat m => some (.nat (n + m))
  | _, _ => none

def eval : Term -> Option Value
  | .nat n => some (.nat n)
  | .add => some .add0
  | .unit => some .unit
  | .app f x =>
      match eval f, eval x with
      | some vf, some vx => applyValue vf vx
      | _, _ => none

def interpCall (c : ParenthesizedCall) : Option Value :=
  eval (lowerCall c)

theorem lowerCall_empty (h : Term) :
    lowerCall {head := h, args := []} = .app h .unit := by
  rfl

theorem lowerCall_single (h a : Term) :
    lowerCall {head := h, args := [.positional a]} = .app h a := by
  rfl

theorem lowerCall_two (h a b : Term) :
    lowerCall {head := h, args := [.positional a, .positional b]}
      = .app (.app h a) b := by
  rfl

theorem add_call_preserves (a b : Nat) :
    interpCall {head := .add, args := [.positional (.nat a), .positional (.nat b)]}
      = some (.nat (a + b)) := by
  rfl

end ProofScript.R3.Overlay
