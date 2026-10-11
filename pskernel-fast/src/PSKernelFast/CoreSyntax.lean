import Lean

/-!
Independent, logic-neutral syntax substrate for the Lean 4.35 kernel target.
This file does NOT implement inference, DefEq, conversion, or declaration
acceptance. Its only executable claim is strict structural preflight.

Compared to official Lean v4.35.0-rc4 src/kernel/{level.h,expr.h}:
  Level: zero, succ, max, imax, param, metavariable
  Expr: bvar, fvar, mvar, sort, const, app, lam, Pi, let, nat/string
        literal, metadata wrapper, projection.
BinderStyle.recursive corresponds to official binder_info::Rec.
MData is represented by an opaque Nat placeholder; no compatibility claim
about full Lean metadata values or protocol formatting is made.
-/

namespace PSKernelFast.Core

inductive KName where
  | anonymous
  | str (parent : KName) (value : String)
  | num (parent : KName) (value : Nat)
  deriving Repr, Inhabited, BEq, ReflBEq, LawfulBEq, DecidableEq, Hashable

inductive ULevel where
  | zero
  | succ (inner : ULevel)
  | max (left right : ULevel)
  | imax (left right : ULevel)
  | param (name : KName)
  | mvar (name : KName)
  deriving Repr, Inhabited, BEq, DecidableEq, Hashable

inductive BinderStyle where
  | default
  | implicit
  | strictImplicit
  | instImplicit
  | recursive
  deriving Repr, Inhabited, BEq, DecidableEq

inductive KLiteral where
  | nat (value : Nat)
  | str (value : String)
  deriving Repr, Inhabited, BEq, DecidableEq

inductive KExpr where
  | bvar (index : Nat)
  | fvar (name : KName)
  | mvar (name : KName)
  | sort (level : ULevel)
  | const (name : KName) (levels : List ULevel)
  | app (fn arg : KExpr)
  | lam (name : KName) (domain body : KExpr) (binder : BinderStyle)
  | forallE (name : KName) (domain body : KExpr) (binder : BinderStyle)
  | letE (name : KName) (type value body : KExpr) (nondep : Bool)
  | lit (value : KLiteral)
  | mdata (opaqueTag : Nat) (expr : KExpr)
  | proj (typeName : KName) (index : Nat) (expr : KExpr)
  deriving Repr, Inhabited, BEq, DecidableEq

/--
  Under a ground numerical assignment, imax u v = 0 if v = 0,
  otherwise max(u,v). This is *not* symbolic Lean universe equivalence.
-/
def numericImax (u v : Nat) : Nat :=
  if v == 0 then 0 else Nat.max u v

/--
  Partial ground evaluation for diagnostics/oracle testing only.
  Missing parameters/metavariables produce none, never false success.
-/
def ULevel.groundEval (assignment : KName → Option Nat) :
    ULevel → Option Nat
  | .zero => some 0
  | .succ level => do
      let n ← ULevel.groundEval assignment level
      pure (n + 1)
  | .max left right => do
      let l ← ULevel.groundEval assignment left
      let r ← ULevel.groundEval assignment right
      pure (Nat.max l r)
  | .imax left right => do
      let l ← ULevel.groundEval assignment left
      let r ← ULevel.groundEval assignment right
      pure (numericImax l r)
  | .param name => assignment name
  | .mvar _ => none

/-- Input universe parameters must be declared. Metavariables are forbidden. -/
def ULevel.validParams (params : List KName) : ULevel → Bool
  | .zero => true
  | .succ level => ULevel.validParams params level
  | .max left right =>
      ULevel.validParams params left && ULevel.validParams params right
  | .imax left right =>
      ULevel.validParams params left && ULevel.validParams params right
  | .param name => decide (name ∈ params)
  | .mvar _ => false

/--
  Structural input preflight for a would-be closed declaration expression.
  It does not type-check, check environment constant existence, arity,
  reduction policy, opaque bodies, or inductive/quotient rules.
-/
def KExpr.validAt (params : List KName) (depth : Nat) : KExpr → Bool
  | .bvar index => decide (index < depth)
  | .fvar _ => false
  | .mvar _ => false
  | .sort level => ULevel.validParams params level
  | .const _ levels => levels.all (ULevel.validParams params)
  | .app fn arg =>
      KExpr.validAt params depth fn && KExpr.validAt params depth arg
  | .lam _ domain body _ =>
      KExpr.validAt params depth domain &&
        KExpr.validAt params (depth + 1) body
  | .forallE _ domain body _ =>
      KExpr.validAt params depth domain &&
        KExpr.validAt params (depth + 1) body
  | .letE _ type value body _ =>
      KExpr.validAt params depth type &&
        KExpr.validAt params depth value &&
        KExpr.validAt params (depth + 1) body
  | .lit _ => true
  | .mdata _ expr => KExpr.validAt params depth expr
  | .proj _ _ expr => KExpr.validAt params depth expr

def KExpr.closedInput (params : List KName) (expr : KExpr) : Bool :=
  KExpr.validAt params 0 expr

end PSKernelFast.Core
