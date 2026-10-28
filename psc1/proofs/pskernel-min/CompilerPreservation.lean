import Ps.Erasure.Expr
import Ps.BackendTs.Expr

/- R5: semantics of actual compiler sub-stages. This module is proof-only.
   Eval covers a pure scalar IR fragment. Invoke describes only the curried
   single-argument ABI, with an exact supplied parameter list. Neither relation
   asserts a theorem about a JavaScript parser, engine, or the complete compiler. -/
namespace Ps.MinKernel.CompilerPreservation

inductive Value where
  | natural (value : Nat)
  | boolean (value : Bool)
  | unit

abbrev Env := List (String × Value)

def lookup (env : Env) (name : String) : Option Value :=
  match env with
  | [] => none
  | (key, value) :: rest => if name = key then some value else lookup rest name

inductive Binary where
  | add
  | sub
  | mul
  | div
  | mod
  | eq
  | le
  | lt
  | and
  | or

def irOperation : Binary → PsVerifiedIrIntrinsic
  | .add => .natAdd
  | .sub => .natSub
  | .mul => .natMul
  | .div => .natDiv
  | .mod => .natMod
  | .eq => .natEq
  | .le => .natLe
  | .lt => .natLt
  | .and => .boolAnd
  | .or => .boolOr

def coreName : Binary → PsName
  | .add => psNatAddName
  | .sub => psNatSubName
  | .mul => psNatMulName
  | .div => psNatDivName
  | .mod => psNatModName
  | .eq => psNatBeqName
  | .le => psNatBleName
  | .lt => psNatBltName
  | .and => (PsName.str (PsName.str PsName.anonymous "Bool") "and")
  | .or => (PsName.str (PsName.str PsName.anonymous "Bool") "or")

-- Independent mathematical scalar semantics; malformed operand types have no value.
def meaning : Binary → Value → Value → Option Value
  | .add, .natural a, .natural b => some (.natural (a + b))
  | .sub, .natural a, .natural b => some (.natural (a - b))
  | .mul, .natural a, .natural b => some (.natural (a * b))
  | .div, .natural a, .natural b => some (.natural (a / b))
  | .mod, .natural a, .natural b => some (.natural (a % b))
  | .eq, .natural a, .natural b => some (.boolean (a == b))
  | .le, .natural a, .natural b => some (.boolean (Nat.ble a b))
  | .lt, .natural a, .natural b => some (.boolean (Nat.blt a b))
  | .and, .boolean a, .boolean b => some (.boolean (a && b))
  | .or, .boolean a, .boolean b => some (.boolean (a || b))
  | _, _, _ => none

inductive Eval : Env → PsVerifiedIrExpr → Value → Prop where
  | natural (env n) : Eval env (.literal (.natural n)) (.natural n)
  | boolean (env b) : Eval env (.literal (.bool b)) (.boolean b)
  | unit (env) : Eval env (.literal .unit) .unit
  | variable (h : lookup env name = some value) : Eval env (.var name) value
  | binary (ha : Eval env left a) (hb : Eval env right b)
      (hm : meaning op a b = some value) :
      Eval env (.intrinsic (irOperation op) [] [left, right]) value
  | boolNot (h : Eval env arg (.boolean b)) :
      Eval env (.intrinsic .boolNot [] [arg]) (.boolean (!b))
  | letValue (hv : Eval env value v)
      (hb : Eval ((name, v) :: env) body result) :
      Eval env (.letE name type value body) result
  | ifTrue (hc : Eval env condition (.boolean true))
      (ht : Eval env yes value) : Eval env (.ifE condition yes no) value
  | ifFalse (hc : Eval env condition (.boolean false))
      (hf : Eval env no value) : Eval env (.ifE condition yes no) value

-- bindingsRev is the actual compiler accumulator: its tail runs first.
inductive Captures : Env → List (PsVerifiedIrParameter × PsVerifiedIrExpr) → Env → Prop where
  | nil (env) : Captures env [] env
  | cons {binding : PsVerifiedIrParameter × PsVerifiedIrExpr}
      (history : Captures env rest middle)
      (value : Eval middle binding.2 v) :
      Captures env (binding :: rest) ((binding.1.name, v) :: middle)

theorem wrap_preserves (history : Captures env bindings final)
    (bodyValue : Eval final body result) :
    Eval env (psErasureWrapApplicationCaptures bindings body) result := by
  induction history generalizing body with
  | nil => exact bodyValue
  | cons history value ih =>
      change Eval _ (psErasureWrapApplicationCaptures _
        (.letE _ _ _ body)) result
      exact ih (Eval.letValue value bodyValue)

theorem wrap_reflects (h : Eval env
    (psErasureWrapApplicationCaptures bindings body) result) :
    ∃ final, Captures env bindings final ∧ Eval final body result := by
  induction bindings generalizing env body with
  | nil =>
      exact ⟨env, Captures.nil env, h⟩
  | cons binding rest ih =>
      change Eval env (psErasureWrapApplicationCaptures rest
        (.letE binding.1.name binding.1.type binding.2 body)) result at h
      obtain ⟨middle, history, value⟩ := ih h
      cases value with
      | letValue hv hb => exact ⟨_, Captures.cons history hv, hb⟩

theorem wrap_iff :
    Eval env (psErasureWrapApplicationCaptures bindings body) result ↔
      ∃ final, Captures env bindings final ∧ Eval final body result :=
  ⟨wrap_reflects, fun ⟨_, history, value⟩ => wrap_preserves history value⟩

theorem two_captures_order (first second : PsVerifiedIrParameter × PsVerifiedIrExpr)
    (body : PsVerifiedIrExpr) :
    psErasureWrapApplicationCaptures [second, first] body =
      .letE first.1.name first.1.type first.2
        (.letE second.1.name second.1.type second.2 body) := rfl

theorem shadowing (env : Env) (name : String) (old fresh : Value) :
    lookup ((name, fresh) :: (name, old) :: env) name = some fresh := by
  simp [lookup]

inductive Bindings : Env → List PsVerifiedIrParameter → List Value → Env → Prop where
  | nil (env) : Bindings env [] [] env
  | cons {p : PsVerifiedIrParameter}
      (tail : Bindings ((p.name, v) :: env) rest values final) :
      Bindings env (p :: rest) (v :: values) final

inductive Invoke : Env → PsVerifiedIrExpr → List Value → Value → Prop where
  | done (h : Eval env body result) : Invoke env body [] result
  | argument {p : PsVerifiedIrParameter}
      (h : Invoke ((p.name, v) :: env) body values result) :
      Invoke env (.lambda [p] type body) (v :: values) result

theorem curry_iff (bindings : Bindings env parameters arguments final) :
    Invoke env (psErasureCurryParameters parameters type body).2 arguments result ↔
      Eval final body result := by
  induction bindings with
  | nil =>
      change Invoke _ body [] result ↔ Eval _ body result
      constructor
      · intro h; cases h with | done h => exact h
      · exact Invoke.done
  | cons tail ih =>
      change Invoke _ (.lambda [_] _ _) (_ :: _) result ↔ _
      constructor
      · intro h; cases h with | argument h => exact ih.mp h
      · intro h; exact Invoke.argument (ih.mpr h)

theorem curry_result_type_nil (type : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    (psErasureCurryParameters [] type body).1 = type := rfl

theorem curry_result_type_cons (p : PsVerifiedIrParameter) (rest : List PsVerifiedIrParameter)
    (type : PsVerifiedIrType) (body : PsVerifiedIrExpr) :
    (psErasureCurryParameters (p :: rest) type body).1 =
      .function [p.type] (psErasureCurryParameters rest type body).1 := rfl

-- First evaluate capture lets, then invoke the resulting curried value.
-- This separate phase relation keeps captures outside each later argument call.
inductive CapturedInvoke : Env → PsVerifiedIrExpr → List Value → Value → Prop where
  | invoke (h : Invoke env body arguments result) :
      CapturedInvoke env body arguments result
  | bind (value : Eval env expression v)
      (body : CapturedInvoke ((name, v) :: env) rest arguments result) :
      CapturedInvoke env (.letE name type expression rest) arguments result

theorem wrap_invocation_preserves (history : Captures env bindings final)
    (bodyValue : CapturedInvoke final body arguments result) :
    CapturedInvoke env (psErasureWrapApplicationCaptures bindings body) arguments result := by
  induction history generalizing body with
  | nil => exact bodyValue
  | cons history value ih =>
      change CapturedInvoke _ (psErasureWrapApplicationCaptures _
        (.letE _ _ _ body)) arguments result
      exact ih (CapturedInvoke.bind value bodyValue)

theorem capture_curry_preservation
    (captures : Captures env bindings captured)
    (parameters : Bindings captured params values final)
    (bodyValue : Eval final body result) :
    CapturedInvoke env (psErasureWrapApplicationCaptures bindings
      (psErasureCurryParameters params type body).2) values result :=
  wrap_invocation_preserves captures
    (CapturedInvoke.invoke ((curry_iff parameters).mpr bodyValue))

theorem mapped_binary (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (ha : erase a = .ok left) (hb : erase b = .ok right)
    (operation : PsVerifiedIrIntrinsic) :
    psEraseMappedIntrinsic erase operation [a, b] =
      .ok (.intrinsic operation [] [left, right]) := by
  simp only [psEraseMappedIntrinsic, psListMapExcept, psListMapExceptAcc,
    ha, hb, psListReverse, psListReverseAcc]

theorem erase_binary (operation : Binary)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (ha : erase a = .ok left) (hb : erase b = .ok right)
    :
    psEraseBinaryIntrinsicApplication erase (irOperation operation) [a, b] =
      .ok (some (.intrinsic (irOperation operation) [] [left, right])) := by
  change (match psEraseMappedIntrinsic erase (irOperation operation) [a, b] with
      | .error e => Except.error e
      | .ok value => Except.ok (some value)) = _
  rw [mapped_binary erase ha hb]

theorem erase_binary_empty_refuses (operation : Binary)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr)
    :
    psEraseBinaryIntrinsicApplication erase (irOperation operation) [] =
      .error .unsupportedApplication := by
  cases operation <;> rfl

theorem erase_binary_overapplied_refuses (operation : Binary)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (a b c : PsExpr) :
    psEraseBinaryIntrinsicApplication erase (irOperation operation) [a, b, c] =
      .error .unsupportedApplication := by
  cases operation <;> rfl

theorem primitive_stage_preserves
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (ha : erase a = .ok left) (hb : erase b = .ok right)
    (leftValue : Eval env left av) (rightValue : Eval env right bv)
    (value : meaning operation av bv = some result)
    :
    ∃ ir, psEraseBinaryIntrinsicApplication erase (irOperation operation) [a, b] = .ok (some ir) ∧ Eval env ir result :=
  ⟨_, erase_binary operation erase ha hb,
    Eval.binary leftValue rightValue value⟩

-- Independently stated exact output templates. These equations do not assert
-- that arbitrary operand text is safe or that an ECMAScript engine is verified.
def binaryTokens : Binary → String → String → List String
  | .add, left, right => ["(", left, " + ", right, ")"]
  | .sub, left, right => ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(", left, ", ", right, ")"]
  | .mul, left, right => ["(", left, " * ", right, ")"]
  | .div, left, right => ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_b === 0n ? 0n : __ps_a / __ps_b))(", left, ", ", right, ")"]
  | .mod, left, right => ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_b === 0n ? __ps_a : __ps_a % __ps_b))(", left, ", ", right, ")"]
  | .eq, left, right => ["(((", left, ") as bigint) === ((", right, ") as bigint))"]
  | .le, left, right => ["(", left, " <= ", right, ")"]
  | .lt, left, right => ["(", left, " < ", right, ")"]
  | .and, left, right => ["(", left, " && ", right, ")"]
  | .or, left, right => ["(", left, " || ", right, ")"]

-- Exact token composition under the actual join operation.
-- R6 TextComposition connects its constructive join to UTF-8 bytes.
theorem emit_binary_template (op : Binary) (left right : String) :
    psTsEmitIntrinsicFromPrinted (irOperation op) [left, right] =
      .ok (psTsJoin "" (binaryTokens op left right)) := by
  cases op <;> rfl

theorem emit_binary_empty_refuses (op : Binary) :
    psTsEmitIntrinsicFromPrinted (irOperation op) [] = .error .intrinsicArity := by
  cases op <;> rfl

theorem emit_binary_overapplied_refuses (op : Binary) (a b c : String) :
    psTsEmitIntrinsicFromPrinted (irOperation op) [a, b, c] =
      .error .intrinsicArity := by
  cases op <;> rfl

theorem emit_nat_abi (n : Nat) :
    psTsEmitLiteral (.natural n) = .ok (String.Internal.append (psNatToString n) "n") := rfl

theorem emit_bool_abi (b : Bool) :
    psTsEmitLiteral (.bool b) = .ok (if b then "true" else "false") := by
  cases b <;> rfl

theorem emit_unit_abi : psTsEmitLiteral .unit = .ok "undefined" := rfl

end Ps.MinKernel.CompilerPreservation

#print axioms Ps.MinKernel.CompilerPreservation.wrap_preserves
#print axioms Ps.MinKernel.CompilerPreservation.wrap_reflects
#print axioms Ps.MinKernel.CompilerPreservation.wrap_iff
#print axioms Ps.MinKernel.CompilerPreservation.two_captures_order
#print axioms Ps.MinKernel.CompilerPreservation.shadowing
#print axioms Ps.MinKernel.CompilerPreservation.curry_iff
#print axioms Ps.MinKernel.CompilerPreservation.curry_result_type_nil
#print axioms Ps.MinKernel.CompilerPreservation.curry_result_type_cons
#print axioms Ps.MinKernel.CompilerPreservation.wrap_invocation_preserves
#print axioms Ps.MinKernel.CompilerPreservation.capture_curry_preservation
#print axioms Ps.MinKernel.CompilerPreservation.mapped_binary
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary_empty_refuses
#print axioms Ps.MinKernel.CompilerPreservation.erase_binary_overapplied_refuses
#print axioms Ps.MinKernel.CompilerPreservation.primitive_stage_preserves
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_template
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_empty_refuses
#print axioms Ps.MinKernel.CompilerPreservation.emit_binary_overapplied_refuses
#print axioms Ps.MinKernel.CompilerPreservation.emit_nat_abi
#print axioms Ps.MinKernel.CompilerPreservation.emit_bool_abi
#print axioms Ps.MinKernel.CompilerPreservation.emit_unit_abi
