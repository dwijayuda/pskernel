import PSKernelFast.TermStore

/-!
A deliberately non-authoritative G2 comparison of two weak-head beta-reducers
over the same closed RawExpr decoded from the V3 compact term store.

Eager: leftmost weak-head beta with capture-avoiding de Bruijn substitution.
Lazy: call-by-name environment machine with delayed substitution and readback.

There are NO Lean typing, universes, DefEq, recursor, or proof admission rules here.
-/

namespace PSKernelFast

inductive EvalError where
  | betaBudgetExhausted
  | machineBudgetExhausted
  | readbackBudgetExhausted
  | unboundVariable (index : Nat)
  | invalidStore (issue : StoreError)
  deriving Repr, BEq, Inhabited

/-- Structural size for test digests; not an instruction count or memory metric. -/
def rawSize : RawExpr → Nat
  | .bvar _ => 1
  | .sort _ => 1
  | .app fn arg => 1 + rawSize fn + rawSize arg
  | .lam domain body => 1 + rawSize domain + rawSize body

/-- Shift free de Bruijn indices by amount, respecting all lambda binders. -/
def liftFrom (amount cutoff : Nat) : RawExpr → RawExpr
  | .bvar i => if i < cutoff then .bvar i else .bvar (i + amount)
  | .sort level => .sort level
  | .app fn arg =>
      .app (liftFrom amount cutoff fn) (liftFrom amount cutoff arg)
  | .lam domain body =>
      .lam (liftFrom amount cutoff domain) (liftFrom amount (cutoff + 1) body)

/-- β instantiation: replace index cutoff; decrement indices above cutoff. -/
def instantiateAt (argument : RawExpr) (cutoff : Nat) : RawExpr → RawExpr
  | .bvar i =>
      if i < cutoff then
        .bvar i
      else if i == cutoff then
        liftFrom cutoff 0 argument
      else
        .bvar (i - 1)
  | .sort level => .sort level
  | .app fn arg =>
      .app (instantiateAt argument cutoff fn) (instantiateAt argument cutoff arg)
  | .lam domain body =>
      .lam (instantiateAt argument cutoff domain)
        (instantiateAt argument (cutoff + 1) body)

/-- Inductive reference relation for a single legal weak-head beta step. -/
inductive HeadBeta : RawExpr → RawExpr → Prop where
  | beta (domain body arg : RawExpr) :
      HeadBeta (.app (.lam domain body) arg) (instantiateAt arg 0 body)
  | head {fn fn' arg : RawExpr} :
      HeadBeta fn fn' → HeadBeta (.app fn arg) (.app fn' arg)

/--
  Implement the deterministic eager step WITH a proof of its precise
  weak-head contraction relation. Runtime erases the proof; the result is
  not a theorem-proving kernel acceptance certificate.
-/
def eagerHeadStepCertified :
    (expr : RawExpr) → Option { next : RawExpr // HeadBeta expr next }
  | .app (.lam domain body) arg =>
      some ⟨instantiateAt arg 0 body, .beta domain body arg⟩
  | .app fn arg =>
      match eagerHeadStepCertified fn with
      | some ⟨next, valid⟩ =>
          some ⟨.app next arg, .head valid⟩
      | none => none
  | _ => none

/-- Erased, executing portion of the certified eager step. -/
def eagerHeadStep (expr : RawExpr) : Option RawExpr :=
  (eagerHeadStepCertified expr).map Subtype.val

/-- Every actual affirmative eager step is a valid weak-head beta step. -/
theorem eagerHeadStep_sound (expr next : RawExpr)
    (h : eagerHeadStep expr = some next) : HeadBeta expr next := by
  unfold eagerHeadStep at h
  cases hc : eagerHeadStepCertified expr with
  | none =>
      simp [hc] at h
  | some result =>
      simp [hc] at h
      cases h
      exact result.property

/-- Eager weak-head beta normalization with a genuine beta-contraction budget. -/
def eagerWHNF : Nat → RawExpr → Except EvalError RawExpr
  | 0, expr =>
      match eagerHeadStep expr with
      | none => .ok expr
      | some _ => .error .betaBudgetExhausted
  | remaining + 1, expr =>
      match eagerHeadStep expr with
      | none => .ok expr
      | some next => eagerWHNF remaining next

/-- Delayed environment; no eager β substitution is performed by the machine. -/
inductive Closure where
  | mk (term : RawExpr) (env : List Closure)

/-- WHNF head: a lambda closure or an inert sort with pending argument spine. -/
inductive LazyHead where
  | lam (domain body : RawExpr) (env : List Closure)
  | sort (level : Nat) (pendingArgs : List Closure)

/--
  Call-by-name machine. The scan budget counts transitions, NOT the same unit
  as eagerWHNF's beta-contraction budget. Never compare exhaustion verdicts
  as if their limits were identical.
-/
def lazyRun : Nat → Closure → List Closure → Except EvalError LazyHead
  | 0, _, _ => .error .machineBudgetExhausted
  | remaining + 1, .mk term env, pending =>
      match term with
      | .bvar index =>
          match env[index]? with
          | some captured => lazyRun remaining captured pending
          | none => .error (.unboundVariable index)
      | .app fn arg =>
          lazyRun remaining (.mk fn env) ((.mk arg env) :: pending)
      | .lam domain body =>
          match pending with
          | [] => .ok (.lam domain body env)
          | arg :: rest =>
              lazyRun remaining (.mk body (arg :: env)) rest
      | .sort level => .ok (.sort level pending)

/--
  Total bounded readback, with separate lexical binder depth. Substituted
  closure values are lifted by the local binder depth to avoid variable capture.
-/
def readback : Nat → Nat → Closure → Except EvalError RawExpr
  | 0, _, _ => .error .readbackBudgetExhausted
  | remaining + 1, depth, .mk term env =>
      match term with
      | .bvar index =>
          if index < depth then
            .ok (.bvar index)
          else
            match env[index - depth]? with
            | some captured => do
                let value ← readback remaining 0 captured
                pure (liftFrom depth 0 value)
            | none =>
                .error (.unboundVariable index)
      | .sort level => .ok (.sort level)
      | .app fn arg => do
          let newFn ← readback remaining depth (.mk fn env)
          let newArg ← readback remaining depth (.mk arg env)
          pure (.app newFn newArg)
      | .lam domain body => do
          let newDomain ← readback remaining depth (.mk domain env)
          let newBody ← readback remaining (depth + 1) (.mk body env)
          pure (.lam newDomain newBody)

/-- Quote a lazy WHNF to ordinary RawExpr for exact differential comparison. -/
def readbackHead (fuel : Nat) : LazyHead → Except EvalError RawExpr
  | .lam domain body env =>
      readback fuel 0 (.mk (.lam domain body) env)
  | .sort level pending => do
      let mut result : RawExpr := .sort level
      for arg in pending do
        let rawArg ← readback fuel 0 arg
        result := .app result rawArg
      return result

/-- Same raw input, full lazy machine and readback, all explicitly bounded. -/
def lazyWHNF (machineFuel readbackFuel : Nat) (term : RawExpr) :
    Except EvalError RawExpr := do
  let head ← lazyRun machineFuel (.mk term []) []
  readbackHead readbackFuel head

/--
  Decode from the checked G1 store before either engine runs. A forged or
  malformed store can never produce a semantic success by being ignored.
-/
def decodeForEvaluation (store : Store) (root decodeFuel : Nat) :
    Except EvalError RawExpr :=
  match decode store decodeFuel root with
  | .ok term => .ok term
  | .error e => .error (.invalidStore e)

/-- Typed-experiment-only identity function. Not a Lean kernel identity proof. -/
def rawId : RawExpr := .lam (.sort 0) (.bvar 0)

/-- A beta-heavy, closed left-spine workload generator. -/
def identityChain : Nat → RawExpr → RawExpr
  | 0, term => term
  | n + 1, term => .app rawId (identityChain n term)

end PSKernelFast
