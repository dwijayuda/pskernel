import Ps.KernelCore.Core.Expr

/-!
A PSKernel-owned semantic reading of every expression constructor.
Only lambdas and dependent products gain a codomain-sort annotation. The
annotation is semantic evidence to be checked by the eventual checker bridge;
erasure alone does not certify it. Names, binder information, lets, metadata,
projections and symbolic levels are retained exactly.
-/

namespace PsKernelSemantics

inductive AnnotatedExpr where
  | bvar (index : Nat)
  | fvar (name : PsKernelName)
  | mvar (name : PsKernelName)
  | sort (level : PsKernelLevel)
  | const (name : PsKernelName) (levels : List PsKernelLevel)
  | app (fn arg : AnnotatedExpr)
  | lam (name : PsKernelName) (type body : AnnotatedExpr)
      (binderInfo : PsKernelBinderInfo) (rangeSort : PsKernelLevel)
  | forallE (name : PsKernelName) (type body : AnnotatedExpr)
      (binderInfo : PsKernelBinderInfo) (rangeSort : PsKernelLevel)
  | letE (name : PsKernelName) (type value body : AnnotatedExpr) (nondep : Bool)
  | lit (value : PsKernelLiteral)
  | mdata (metadata : Nat) (expr : AnnotatedExpr)
  | proj (typeName : PsKernelName) (index : Nat) (expr : AnnotatedExpr)

namespace AnnotatedExpr

def erase : AnnotatedExpr → PsKernelExpr
  | .bvar i => .bvar i
  | .fvar n => .fvar n
  | .mvar n => .mvar n
  | .sort l => .sort l
  | .const n ls => .const n ls
  | .app f a => .app f.erase a.erase
  | .lam n A b bi _ => .lam n A.erase b.erase bi
  | .forallE n A B bi _ => .forallE n A.erase B.erase bi
  | .letE n A a b nd => .letE n A.erase a.erase b.erase nd
  | .lit l => .lit l
  | .mdata m e => .mdata m e.erase
  | .proj n i e => .proj n i e.erase

/-- This describes scope only, not typing or annotation validity. -/
def Scoped : AnnotatedExpr → Nat → Prop
  | .bvar i, n => i < n
  | .app f a, n => f.Scoped n ∧ a.Scoped n
  | .lam _ A b _ _, n => A.Scoped n ∧ b.Scoped (n + 1)
  | .forallE _ A B _ _, n => A.Scoped n ∧ B.Scoped (n + 1)
  | .letE _ A a b _, n => A.Scoped n ∧ a.Scoped n ∧ b.Scoped (n + 1)
  | .mdata _ e, n => e.Scoped n
  | .proj _ _ e, n => e.Scoped n
  | _, _ => True

def liftN (amount : Nat) : AnnotatedExpr → Nat → AnnotatedExpr
  | .bvar i, k => .bvar (if i < k then i else i + amount)
  | .app f a, k => .app (liftN amount f k) (liftN amount a k)
  | .lam n A b bi v, k =>
      .lam n (liftN amount A k) (liftN amount b (k + 1)) bi v
  | .forallE n A B bi v, k =>
      .forallE n (liftN amount A k) (liftN amount B (k + 1)) bi v
  | .letE n A a b nd, k =>
      .letE n (liftN amount A k) (liftN amount a k) (liftN amount b (k + 1)) nd
  | .mdata m e, k => .mdata m (liftN amount e k)
  | .proj n i e, k => .proj n i (liftN amount e k)
  | e, _ => e

/-- Single substitution at a binder depth. Level annotations are unaffected. -/
def inst (a : AnnotatedExpr) : AnnotatedExpr → Nat → AnnotatedExpr
  | .bvar i, k =>
      if i < k then .bvar i else if i = k then liftN k a 0 else .bvar (i - 1)
  | .app f b, k => .app (inst a f k) (inst a b k)
  | .lam n A b bi v, k => .lam n (inst a A k) (inst a b (k + 1)) bi v
  | .forallE n A B bi v, k => .forallE n (inst a A k) (inst a B (k + 1)) bi v
  | .letE n A b c nd, k =>
      .letE n (inst a A k) (inst a b k) (inst a c (k + 1)) nd
  | .mdata m e, k => .mdata m (inst a e k)
  | .proj n i e, k => .proj n i (inst a e k)
  | e, _ => e

end AnnotatedExpr
end PsKernelSemantics
