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


/-
G4.3 continuation: capture-avoiding *reference* lifting on the exact G3
KExpr constructors. This is structural infrastructure only, not a typing
judgment, an optimized WHNF algorithm or a proof-admission operation.
-/

/-- Raise free indices at or above cutoff, descending under actual binders. -/
def KExpr.liftBVars (amount cutoff : Nat) : KExpr → KExpr
  | .bvar index =>
      if index < cutoff then .bvar index else .bvar (index + amount)
  | .app fn arg =>
      .app (fn.liftBVars amount cutoff) (arg.liftBVars amount cutoff)
  | .lam name domain body style =>
      .lam name (domain.liftBVars amount cutoff)
        (body.liftBVars amount (cutoff + 1)) style
  | .forallE name domain body style =>
      .forallE name (domain.liftBVars amount cutoff)
        (body.liftBVars amount (cutoff + 1)) style
  | .letE name ty value body nondep =>
      .letE name (ty.liftBVars amount cutoff)
        (value.liftBVars amount cutoff)
        (body.liftBVars amount (cutoff + 1)) nondep
  | .mdata tag inner => .mdata tag (inner.liftBVars amount cutoff)
  | .proj name index inner =>
      .proj name index (inner.liftBVars amount cutoff)
  | atom => atom

/--
Every structurally scoped expression remains structurally scoped when
its *free* indices are raised. The required cutoff ≤ depth hypothesis
prevents treating indices free to an inner binder as locally bound.
This is not proof that an expression has a type.
-/
theorem KExpr.liftBVars_structurallyValid
    (params : List KName) (amount cutoff depth : Nat) (expr : KExpr)
    (hCutoff : cutoff ≤ depth)
    (h : KExpr.StructurallyValid params depth expr) :
    KExpr.StructurallyValid params (depth + amount)
      (expr.liftBVars amount cutoff) := by
  induction expr generalizing depth cutoff with
  | bvar index =>
      change index < depth at h
      by_cases hIndex : index < cutoff
      · have hRaised : index < depth + amount := by omega
        simpa [KExpr.liftBVars, hIndex, KExpr.StructurallyValid]
          using hRaised
      · have hRaised : index + amount < depth + amount := by omega
        simpa [KExpr.liftBVars, hIndex, KExpr.StructurallyValid]
          using hRaised
  | fvar _ => exact False.elim h
  | mvar _ => exact False.elim h
  | sort _ =>
      simpa [KExpr.liftBVars, KExpr.StructurallyValid] using h
  | const _ _ =>
      simpa [KExpr.liftBVars, KExpr.StructurallyValid] using h
  | app fn arg ihFn ihArg =>
      exact ⟨ihFn cutoff depth hCutoff h.1,
        ihArg cutoff depth hCutoff h.2⟩
  | lam name domain body style ihDomain ihBody =>
      exact ⟨ihDomain cutoff depth hCutoff h.1,
        ihBody (cutoff + 1) (depth + 1) (by omega) h.2⟩
  | forallE name domain body style ihDomain ihBody =>
      exact ⟨ihDomain cutoff depth hCutoff h.1,
        ihBody (cutoff + 1) (depth + 1) (by omega) h.2⟩
  | letE name ty value body nondep ihTy ihValue ihBody =>
      exact ⟨⟨ihTy cutoff depth hCutoff h.1.1,
        ihValue cutoff depth hCutoff h.1.2⟩,
        ihBody (cutoff + 1) (depth + 1) (by omega) h.2⟩
  | lit _ => trivial
  | mdata tag inner ih =>
      exact ih cutoff depth hCutoff h
  | proj name index inner ih =>
      exact ih cutoff depth hCutoff h


end PSKernelFast.Core
