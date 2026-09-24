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


def binderInfoBeq : BinderInfo → BinderInfo → Bool
  | .default, .default => true
  | .implicit, .implicit => true
  | .strictImplicit, .strictImplicit => true
  | .instImplicit, .instImplicit => true
  | _, _ => false

def literalBeq : Literal → Literal → Bool
  | .natVal a, .natVal b => a == b
  | .strVal a, .strVal b => a == b
  | _, _ => false

def levelListBeq : List Level → List Level → Bool
  | [], [] => true
  | a :: as, b :: bs => Level.beq a b && levelListBeq as bs
  | _, _ => false

/--
Lean kernel structural expression equality (`Expr.eqv`) for the K0
representation. Binder names and BinderInfo are intentionally ignored.
-/
def eqv : Expr → Expr → Bool
  | .bvar a, .bvar b => a == b
  | .fvar a, .fvar b => Name.beq a b
  | .mvar a, .mvar b => Name.beq a b
  | .sort a, .sort b => Level.beq a b
  | .const an aus, .const bn bus => Name.beq an bn && levelListBeq aus bus
  | .app af aa, .app bf ba => eqv aa ba && eqv af bf
  | .lam _ at ab _, .lam _ bt bb _ => eqv at bt && eqv ab bb
  | .forallE _ at ab _, .forallE _ bt bb _ => eqv at bt && eqv ab bb
  | .letE _ at av ab an, .letE _ bt bv bb bn =>
      eqv at bt && eqv av bv && eqv ab bb && an == bn
  | .lit a, .lit b => literalBeq a b
  | .proj an ai ae, .proj bn bi be =>
      eqv ae be && Name.beq an bn && ai == bi
  | _, _ => false

/--
Lean `Expr.equal` behavior for the K0 representation. Unlike `eqv`, binder
names and BinderInfo are significant.
-/
def equal : Expr → Expr → Bool
  | .bvar a, .bvar b => a == b
  | .fvar a, .fvar b => Name.beq a b
  | .mvar a, .mvar b => Name.beq a b
  | .sort a, .sort b => Level.beq a b
  | .const an aus, .const bn bus => Name.beq an bn && levelListBeq aus bus
  | .app af aa, .app bf ba => equal aa ba && equal af bf
  | .lam an at ab abi, .lam bn bt bb bbi =>
      equal at bt && equal ab bb && Name.beq an bn && binderInfoBeq abi bbi
  | .forallE an at ab abi, .forallE bn bt bb bbi =>
      equal at bt && equal ab bb && Name.beq an bn && binderInfoBeq abi bbi
  | .letE an at av ab anondep, .letE bn bt bv bb bnondep =>
      equal at bt && equal av bv && equal ab bb &&
      anondep == bnondep && Name.beq an bn
  | .lit a, .lit b => literalBeq a b
  | .proj an ai ae, .proj bn bi be =>
      equal ae be && Name.beq an bn && ai == bi
  | _, _ => false

def hasLooseBVarAt : Expr → Nat → Nat → Bool
  | .bvar i, target, depth => i == target + depth
  | .fvar _, _, _ => false
  | .mvar _, _, _ => false
  | .sort _, _, _ => false
  | .const _ _, _, _ => false
  | .app f a, target, depth =>
      hasLooseBVarAt f target depth || hasLooseBVarAt a target depth
  | .lam _ type body _, target, depth =>
      hasLooseBVarAt type target depth ||
      hasLooseBVarAt body target (depth + 1)
  | .forallE _ type body _, target, depth =>
      hasLooseBVarAt type target depth ||
      hasLooseBVarAt body target (depth + 1)
  | .letE _ type value body _, target, depth =>
      hasLooseBVarAt type target depth ||
      hasLooseBVarAt value target depth ||
      hasLooseBVarAt body target (depth + 1)
  | .lit _, _, _ => false
  | .proj _ _ e, target, depth => hasLooseBVarAt e target depth

def hasLooseBVar (e : Expr) (index : Nat) : Bool :=
  hasLooseBVarAt e index 0

def lowerLooseBVarsCore : Expr → Nat → Nat → Expr
  | .bvar i, cutoff, amount =>
      if i >= cutoff then .bvar (i - amount) else .bvar i
  | .fvar n, _, _ => .fvar n
  | .mvar n, _, _ => .mvar n
  | .sort u, _, _ => .sort u
  | .const n us, _, _ => .const n us
  | .app f a, cutoff, amount =>
      .app
        (lowerLooseBVarsCore f cutoff amount)
        (lowerLooseBVarsCore a cutoff amount)
  | .lam n type body bi, cutoff, amount =>
      .lam n
        (lowerLooseBVarsCore type cutoff amount)
        (lowerLooseBVarsCore body (cutoff + 1) amount)
        bi
  | .forallE n type body bi, cutoff, amount =>
      .forallE n
        (lowerLooseBVarsCore type cutoff amount)
        (lowerLooseBVarsCore body (cutoff + 1) amount)
        bi
  | .letE n type value body nondep, cutoff, amount =>
      .letE n
        (lowerLooseBVarsCore type cutoff amount)
        (lowerLooseBVarsCore value cutoff amount)
        (lowerLooseBVarsCore body (cutoff + 1) amount)
        nondep
  | .lit l, _, _ => .lit l
  | .proj n i e, cutoff, amount =>
      .proj n i (lowerLooseBVarsCore e cutoff amount)

/--
Lean 4.34 `lower_loose_bvars`. Lean's exported API returns the input unchanged
when `cutoff < amount`; this function preserves that fail-safe behavior.
-/
def lowerLooseBVars (e : Expr) (cutoff amount : Nat) : Expr :=
  if amount == 0 then e
  else if cutoff < amount then e
  else lowerLooseBVarsCore e cutoff amount

end Expr

end ProofScript.Kernel.PSC1
