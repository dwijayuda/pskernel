import Init
set_option autoImplicit false

namespace ProofScript.R3.Backend

inductive RExpr where
  | nat : Nat -> RExpr
  | add : RExpr -> RExpr -> RExpr
  | let1 : RExpr -> RExpr -> RExpr
  | var0 : RExpr
  deriving DecidableEq, Repr

def reval : RExpr -> Option Nat -> Nat
  | .nat n, _ => n
  | .add a b, env => reval a env + reval b env
  | .let1 v body, env => reval body (some (reval v env))
  | .var0, some v => v
  | .var0, none => 0

inductive JExpr where
  | bigNat : Nat -> JExpr
  | plus : JExpr -> JExpr -> JExpr
  | let1 : JExpr -> JExpr -> JExpr
  | var0 : JExpr
  deriving DecidableEq, Repr

def jeval : JExpr -> Option Nat -> Nat
  | .bigNat n, _ => n
  | .plus a b, env => jeval a env + jeval b env
  | .let1 v body, env => jeval body (some (jeval v env))
  | .var0, some v => v
  | .var0, none => 0

def lower : RExpr -> JExpr
  | .nat n => .bigNat n
  | .add a b => .plus (lower a) (lower b)
  | .let1 v body => .let1 (lower v) (lower body)
  | .var0 => .var0

theorem lower_preserves_eval (e : RExpr) (env : Option Nat) :
    jeval (lower e) env = reval e env := by
  induction e generalizing env with
  | nat n => rfl
  | add a b iha ihb =>
      simp [lower, jeval, reval, iha, ihb]
  | let1 v body ihv ihbody =>
      simp [lower, jeval, reval, ihv, ihbody]
  | var0 =>
      cases env <;> rfl

def serialize : JExpr -> String
  | .bigNat n => toString n ++ "n"
  | .plus a b => "(" ++ serialize a ++ " + " ++ serialize b ++ ")"
  | .let1 v body => "(()=>{const x=" ++ serialize v ++ ";return " ++ serialize body ++ ";})()"
  | .var0 => "x"

structure Emitted where
  ast : JExpr
  bytes : String
  evidence : bytes = serialize ast

def emit (e : RExpr) : Emitted :=
  let ast := lower e
  { ast := ast, bytes := serialize ast, evidence := rfl }

theorem emitted_ast_preserves (e : RExpr) (env : Option Nat) :
    jeval (emit e).ast env = reval e env := by
  simpa [emit] using lower_preserves_eval e env

theorem emitted_bytes_bound (e : RExpr) :
    (emit e).bytes = serialize (emit e).ast := by
  exact (emit e).evidence

end ProofScript.R3.Backend
