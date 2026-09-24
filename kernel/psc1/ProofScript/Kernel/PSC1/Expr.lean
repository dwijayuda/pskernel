import ProofScript.Kernel.PSC1.Level

namespace ProofScript.Kernel.PSC1

inductive BinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive Literal where
  | natVal (value : Nat)
  | strVal (value : String)

/--
Portable expression syntax for the PSC1 kernel.

K0 intentionally models the kernel-relevant expression constructors except
`mdata`. Metadata is preserved by the existing production transport, but the
first direct-Lean semantic slice focuses on the constructors used by
lifting/instantiation. K1 will add exact KVMap/mdata representation.
-/
inductive Expr where
  | bvar (index : Nat)
  | fvar (name : Name)
  | mvar (name : Name)
  | sort (level : Level)
  | const (name : Name) (levels : List Level)
  | app (fn arg : Expr)
  | lam (name : Name) (type body : Expr) (binderInfo : BinderInfo)
  | forallE (name : Name) (type body : Expr) (binderInfo : BinderInfo)
  | letE (name : Name) (type value body : Expr) (nondep : Bool)
  | lit (literal : Literal)
  | proj (typeName : Name) (index : Nat) (expr : Expr)

namespace Expr

/--
Uncached form of Lean Expr.Data.looseBVarRange.
The runtime implementation may cache this value; the semantic implementation
does not depend on that optimization.
-/
def looseBVarRange : Expr → Nat
  | .bvar i => i + 1
  | .fvar _ => 0
  | .mvar _ => 0
  | .sort _ => 0
  | .const _ _ => 0
  | .app f a => Nat.max (looseBVarRange f) (looseBVarRange a)
  | .lam _ type body _ =>
      Nat.max (looseBVarRange type) (Nat.pred (looseBVarRange body))
  | .forallE _ type body _ =>
      Nat.max (looseBVarRange type) (Nat.pred (looseBVarRange body))
  | .letE _ type value body _ =>
      Nat.max
        (Nat.max (looseBVarRange type) (looseBVarRange value))
        (Nat.pred (looseBVarRange body))
  | .lit _ => 0
  | .proj _ _ e => looseBVarRange e

def hasLooseBVars (e : Expr) : Bool :=
  looseBVarRange e > 0

/-- Direct semantic transcription of Lean 4.34 `lift_loose_bvars`. -/
def liftLooseBVars : Expr → Nat → Nat → Expr
  | e, _, 0 => e
  | .bvar i, cutoff, amount + 1 =>
      if i >= cutoff then .bvar (i + amount + 1) else .bvar i
  | .fvar n, _, _ => .fvar n
  | .mvar n, _, _ => .mvar n
  | .sort u, _, _ => .sort u
  | .const n us, _, _ => .const n us
  | .app f a, cutoff, amount =>
      .app
        (liftLooseBVars f cutoff amount)
        (liftLooseBVars a cutoff amount)
  | .lam n type body bi, cutoff, amount =>
      .lam n
        (liftLooseBVars type cutoff amount)
        (liftLooseBVars body (cutoff + 1) amount)
        bi
  | .forallE n type body bi, cutoff, amount =>
      .forallE n
        (liftLooseBVars type cutoff amount)
        (liftLooseBVars body (cutoff + 1) amount)
        bi
  | .letE n type value body nondep, cutoff, amount =>
      .letE n
        (liftLooseBVars type cutoff amount)
        (liftLooseBVars value cutoff amount)
        (liftLooseBVars body (cutoff + 1) amount)
        nondep
  | .lit l, _, _ => .lit l
  | .proj n i e, cutoff, amount =>
      .proj n i (liftLooseBVars e cutoff amount)

def mkAppN : Expr → List Expr → Expr
  | f, [] => f
  | f, a :: rest => mkAppN (.app f a) rest

end Expr

end ProofScript.Kernel.PSC1
