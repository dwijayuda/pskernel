import Ps.KernelCore.Core.Expr.Basic

/-!
A PSKernel-owned semantic reading of every expression constructor.
Only lambdas and dependent products gain a codomain-sort annotation. These
annotations are untrusted data until validated at actual checker visits;
erasure alone does not certify them. This module contains no model or checker. Names, binder information, lets, metadata,
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

/-- Close a single free variable at the current binder depth. Just as in the
production operation, pre-existing bound indices are not shifted. -/
def close (name : PsKernelName) : AnnotatedExpr → Nat → AnnotatedExpr
  | .fvar n, k => if psKernelNameEq n name then .bvar k else .fvar n
  | .app f a, k => .app (close name f k) (close name a k)
  | .lam n A b bi v, k => .lam n (close name A k) (close name b (k + 1)) bi v
  | .forallE n A B bi v, k => .forallE n (close name A k) (close name B (k + 1)) bi v
  | .letE n A a b nd, k =>
      .letE n (close name A k) (close name a k) (close name b (k + 1)) nd
  | .mdata md e, k => .mdata md (close name e k)
  | .proj n i e, k => .proj n i (close name e k)
  | e, _ => e

def instLevels (names : List PsKernelName) (values : List PsKernelLevel) :
    AnnotatedExpr → AnnotatedExpr
  | .sort l => .sort (psKernelLevelInstantiateParams l names values)
  | .const n ls => .const n (psKernelInstantiateLevelList ls names values)
  | .app f a => .app (instLevels names values f) (instLevels names values a)
  | .lam n A b bi v =>
      .lam n (instLevels names values A) (instLevels names values b) bi
        (psKernelLevelInstantiateParams v names values)
  | .forallE n A B bi v =>
      .forallE n (instLevels names values A) (instLevels names values B) bi
        (psKernelLevelInstantiateParams v names values)
  | .letE n A a b nd =>
      .letE n (instLevels names values A) (instLevels names values a)
        (instLevels names values b) nd
  | .mdata md e => .mdata md (instLevels names values e)
  | .proj n i e => .proj n i (instLevels names values e)
  | e => e

end AnnotatedExpr
end PsKernelSemantics
