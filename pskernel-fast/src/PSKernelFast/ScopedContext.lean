import PSKernelFast.CoreSyntaxProofs

/-!
G4.3 proof-carrying *structural* local binder context.

This context contains only well-scoped candidate binder domains, checked at
their entry depth by the actual G3 preflight. It does NOT certify typing,
DefEq, binder-sort validity or any proof and cannot admit declarations.
Raw stored domains are NOT valid current-context inferred types until the
future checker performs exact index shifting/instantiation.
-/

namespace PSKernelFast.Core

/--
  A proof-carrying chain: a newly added domain was structurally valid at the
  parent's binder depth before it was stored. There is no unchecked push.
-/
inductive ScopedFrame (params : List KName) : Nat → Type where
  | empty : ScopedFrame params 0
  | extend {depth : Nat}
      (parent : ScopedFrame params depth)
      (domain : KExpr)
      (valid : KExpr.StructurallyValid params depth domain) :
      ScopedFrame params (depth + 1)

/--
  Runtime carrier for the statically indexed depth. Only structural evidence
  is carried; no general inference, no untrusted "checked type" cast.
-/
structure AnyScopedFrame (params : List KName) where
  depth : Nat
  frame : ScopedFrame params depth

def AnyScopedFrame.empty (params : List KName) : AnyScopedFrame params :=
  ⟨0, .empty⟩

inductive ScopedError where
  | malformedBinder
  deriving Inhabited, Repr, BEq

/-- Controlled O(1) frame extension, gated by a compiling soundness theorem. -/
def AnyScopedFrame.extend {params : List KName}
    (current : AnyScopedFrame params) (domain : KExpr) :
    Except ScopedError (AnyScopedFrame params) :=
  if h : domain.validAt params current.depth = true then
    .ok ⟨current.depth + 1,
      .extend current.frame domain
        (KExpr.validAt_sound params current.depth domain h)⟩
  else
    .error .malformedBinder

/--
  Exact **stored** domain at a depth-relative binder index. This is NOT a
  type lookup: a domain stored in its original context must be lifted under
  later binders before it can be used as a dependent type judgment.
-/
def ScopedFrame.rawDomainAt {params : List KName} :
    {depth : Nat} → ScopedFrame params depth → Nat → Option KExpr
  | _, .empty, _ => none
  | _, .extend _ domain _, 0 => some domain
  | _, .extend parent _ _, index + 1 =>
      ScopedFrame.rawDomainAt parent index

def AnyScopedFrame.rawDomainAt {params : List KName}
    (context : AnyScopedFrame params) (index : Nat) : Option KExpr :=
  context.frame.rawDomainAt index

/-- Raw top lookup is definitionally exact, without interpreting its type. -/
theorem ScopedFrame.rawDomainAt_top {params : List KName} {depth : Nat}
    (parent : ScopedFrame params depth) (domain : KExpr)
    (valid : KExpr.StructurallyValid params depth domain) :
    ScopedFrame.rawDomainAt (.extend parent domain valid) 0 = some domain := rfl

/--
  Successful extension advances the actual runtime depth by exactly one.
  It does not upgrade structural validity into dependent type correctness.
-/
theorem AnyScopedFrame.extend_depth {params : List KName}
    (current next : AnyScopedFrame params) (domain : KExpr)
    (h : current.extend domain = .ok next) :
    next.depth = current.depth + 1 := by
  unfold AnyScopedFrame.extend at h
  by_cases good : domain.validAt params current.depth = true
  · simp [good] at h
    cases h
    rfl
  · simp [good] at h

end PSKernelFast.Core
