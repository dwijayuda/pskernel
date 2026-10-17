import Ps.KernelCore.Runtime.Acceleration.CertifiedNodeCountMemo
import Std.Data.HashMap.Basic

/-
Non-semantic checker cache policy.

This module decides whether an inference result is worth memoizing. It does not
read or mutate checker state and must not change the inferred type or
accept/reject judgment.

Checked application nodes are intentionally not memoized. A cold checked spine
visits each node once, while memoizing every growing application tree can force
expensive structural hashing/promotion in the portable cache. Checked lambda
and forall nodes are likewise commonly one-shot in generated declaration and
recursor-rule validation. Infer-only application, lambda and forall results
remain memoized because whole-expression inference results are commonly reused.
-/

/-- Semantic facts cannot be reused across structurally forgeable FVar
identities introduced inside temporary local contexts. -/
def psKernelSemanticCacheEligible (expr : PsKernelExpr) : Bool :=
  !psKernelExprHasFVar expr

def psKernelSemanticPairCacheEligible
    (left right : PsKernelExpr) : Bool :=
  psKernelSemanticCacheEligible left &&
    psKernelSemanticCacheEligible right

/-- Historical source cache policy. Keep its exact definitional normal form
so existing native checker refinement and cache-state proofs continue to
reason about the same source function; compiler acceleration is separate. -/
def psKernelInferCacheEligible
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Bool :=
  if psKernelSemanticCacheEligible expr then
    match expr with
    | PsKernelExpr.lit _ => false
    | PsKernelExpr.app _ _ => inferOnly
    | PsKernelExpr.lam _ _ _ _ => inferOnly
    | PsKernelExpr.forallE _ _ _ _ => inferOnly
    | _ => true
  else
    false

/-- Faster but exactly equal native implementation. Checked application,
lambda and Pi nodes cannot be cached, regardless of FVar contents; do not
expand a shared DAG to find FVars before making that cheap decision.
For other forms and infer-only checking preserve the original eligibility. -/
def psKernelC0FastInferCacheEligible
    (inferOnly : Bool)
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | .lit _ => false
  | .app _ _ | .lam _ _ _ _ | .forallE _ _ _ _ =>
      inferOnly && psKernelSemanticCacheEligible expr
  | _ => psKernelSemanticCacheEligible expr

/-- All-input semantic equivalence of the fast candidate to the unmodified
source cache policy: this proves the complete Boolean decision, including
FVar scope restrictions, before any native compiler replacement is enabled. -/
theorem psKernelC0FastInferCacheEligible_source
    (inferOnly : Bool) (expr : PsKernelExpr) :
    psKernelC0FastInferCacheEligible inferOnly expr =
      psKernelInferCacheEligible inferOnly expr := by
  cases expr <;> cases inferOnly <;>
    simp [psKernelC0FastInferCacheEligible, psKernelInferCacheEligible]

/-- Retain the source checker and all existing kernel proofs verbatim.
The verified native compiler route only changes a pure selection algorithm;
it never inserts or reads unverified type, equality or admission facts. -/
@[csimp] theorem psKernelInferCacheEligible_csimp :
    @psKernelInferCacheEligible = @psKernelC0FastInferCacheEligible := by
  funext inferOnly expr
  exact (psKernelC0FastInferCacheEligible_source inferOnly expr).symm

/-!
Source-equivalent DAG-aware FVar membership for semantic cache eligibility.

The raw predicate in Core.Expr is the kernel specification and remains
available independently. A fully shared DAG can have exponentially many
expanded recursive occurrences, so an unconditional recursive FVar scan at
each cache decision is costly. The operation-local memo uses a bounded
shape hash only for bucket selection and exact proof-constrained expression
equality on hits. It never caches a type, DefEq result, admission, context,
or result from another kernel session.

Every returned Boolean has an all-input Lean proof of equality with the
unchanged source predicate. The cheap path remains the source predicate.
-/

structure PsKernelC0ExactFVar (expr : PsKernelExpr) where
  value : Bool
  source : value = psKernelExprHasFVar expr

structure PsKernelC0FVarMemoEntry where
  expr : PsKernelExpr
  certified : PsKernelC0ExactFVar expr

/-- Per-operation full-key hashed lookup, not a 16-bit shape-trie.
    HashMap only chooses candidate lists; every hit is still rechecked by
    exact proof-constrained expression equality. -/
abbrev PsKernelC0FVarMemo :=
  Std.HashMap Nat (List PsKernelC0FVarMemoEntry)

private def psKernelC0FVarMemoFind (expr : PsKernelExpr) :
    List PsKernelC0FVarMemoEntry →
      Option (PsKernelC0ExactFVar expr)
  | [] => none
  | entry :: rest =>
      match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
      | .isTrue equal =>
          some (by
            cases equal
            exact entry.certified)
      | .isFalse _ =>
          psKernelC0FVarMemoFind expr rest

/-!
A memo hash is a NON-SEMANTIC index, never a decision about FVars.
The native identity hash can miss structurally-equal values with different
addresses, but such misses only recompute the fully checked source result.
Every hit still verifies exact typed expression equality before reusing
the attached Lean proof, even if addresses collide. Portable PSC0 v7.2
uses the structural shape-hash fallback.

The theorem below proves the memo's Boolean result equals the original
source check for EVERY hash function; identity hashing does not add any
assumption to kernel admission or convertibility.
-/
private unsafe def psKernelC0FVarMemoIdentityHashNative
    (expr : PsKernelExpr) : Nat :=
  -- Lean runtime objects are word-aligned; discard the pointer's low
  -- alignment nibble to use all four radix-16 index levels. This shift
  -- affects performance ONLY: hash collisions and even inconsistent
  -- hash observations cannot make an exact checked hit.
  (ptrAddrUnsafe expr).toNat / psKernelC0Radix

@[implemented_by psKernelC0FVarMemoIdentityHashNative]
private def psKernelC0FVarMemoIdentityHash
    (expr : PsKernelExpr) : Nat :=
  psKernelC0MemoShapeHash 4 expr

private def psKernelC0FVarMemoLookup
    (indexHash : PsKernelExpr → Nat)
    (expr : PsKernelExpr) (memo : PsKernelC0FVarMemo) :
    Option (PsKernelC0ExactFVar expr) :=
  match memo[indexHash expr]? with
  | some entries => psKernelC0FVarMemoFind expr entries
  | none => none

private def psKernelC0FVarMemoStore
    (indexHash : PsKernelExpr → Nat)
    {expr : PsKernelExpr}
    (memo : PsKernelC0FVarMemo)
    (checked : PsKernelC0ExactFVar expr) :
    PsKernelC0ExactFVar expr × PsKernelC0FVarMemo :=
  let hash := indexHash expr
  let bucket := (memo[hash]?).getD []
  (checked, memo.insert hash
    ({ expr := expr, certified := checked } :: bucket))

/-- One memo per query, never transported across checker or expression states. -/
def psKernelC0FVarMemoGoWithHash
    (indexHash : PsKernelExpr → Nat) :
    (expr : PsKernelExpr) → PsKernelC0FVarMemo →
      PsKernelC0ExactFVar expr × PsKernelC0FVarMemo
  | expr, memo =>
      match psKernelC0FVarMemoLookup indexHash expr memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0FVarMemoGoWithHash indexHash fn memo
              -- The source predicate short-circuits on the function side.
              -- Do not traverse a potentially enormous argument DAG when
              -- the left child already certifies the presence of an FVar.
              if h : f.value = true then
                let checked : PsKernelC0ExactFVar (.app fn arg) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar fn then true
                       else psKernelExprHasFVar arg)
                    rw [← f.source]
                    simp [h]⟩
                psKernelC0FVarMemoStore indexHash m1 checked
              else
                let (a, m2) := psKernelC0FVarMemoGoWithHash indexHash arg m1
                let checked : PsKernelC0ExactFVar (.app fn arg) :=
                  ⟨a.value, by
                    change a.value =
                      (if psKernelExprHasFVar fn then true
                       else psKernelExprHasFVar arg)
                    rw [← f.source, ← a.source]
                    simp [h]⟩
                psKernelC0FVarMemoStore indexHash m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0FVarMemoGoWithHash indexHash ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactFVar (.lam name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore indexHash m1 checked
              else
                let (b, m2) := psKernelC0FVarMemoGoWithHash indexHash body m1
                let checked : PsKernelC0ExactFVar (.lam name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore indexHash m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0FVarMemoGoWithHash indexHash ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactFVar (.forallE name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore indexHash m1 checked
              else
                let (b, m2) := psKernelC0FVarMemoGoWithHash indexHash body m1
                let checked : PsKernelC0ExactFVar (.forallE name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore indexHash m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0FVarMemoGoWithHash indexHash ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactFVar
                    (.letE name ty val body nondep) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar ty then true
                       else if psKernelExprHasFVar val then true
                       else psKernelExprHasFVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore indexHash m1 checked
              else
                let (v, m2) := psKernelC0FVarMemoGoWithHash indexHash val m1
                if hv : v.value = true then
                  let checked : PsKernelC0ExactFVar
                      (.letE name ty val body nondep) :=
                    ⟨true, by
                      change true =
                        (if psKernelExprHasFVar ty then true
                         else if psKernelExprHasFVar val then true
                         else psKernelExprHasFVar body)
                      rw [← t.source, ← v.source]
                      simp [ht, hv]⟩
                  psKernelC0FVarMemoStore indexHash m2 checked
                else
                  let (b, m3) := psKernelC0FVarMemoGoWithHash indexHash body m2
                  let checked : PsKernelC0ExactFVar
                      (.letE name ty val body nondep) :=
                    ⟨b.value, by
                      change b.value =
                        (if psKernelExprHasFVar ty then true
                         else if psKernelExprHasFVar val then true
                         else psKernelExprHasFVar body)
                      rw [← t.source, ← v.source, ← b.source]
                      simp [ht, hv]⟩
                  psKernelC0FVarMemoStore indexHash m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0FVarMemoGoWithHash indexHash body memo
              let checked : PsKernelC0ExactFVar (.mdata md body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasFVar body
                  exact b.source⟩
              psKernelC0FVarMemoStore indexHash m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0FVarMemoGoWithHash indexHash body memo
              let checked : PsKernelC0ExactFVar (.proj name i body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasFVar body
                  exact b.source⟩
              psKernelC0FVarMemoStore indexHash m1 checked
          | .fvar name =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨true, rfl⟩ : PsKernelC0ExactFVar (.fvar name))
          | .bvar index =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.bvar index))
          | .mvar name =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.mvar name))
          | .sort level =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.sort level))
          | .const name levels =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.const name levels))
          | .lit literal =>
              psKernelC0FVarMemoStore indexHash memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.lit literal))

/-- The source Boolean is independent of the index-hash function.
This is stronger than proving equality to any particular structural hash. -/
theorem psKernelC0FVarMemoGoWithHash_source
    (indexHash : PsKernelExpr → Nat)
    (expr : PsKernelExpr)
    (memo : PsKernelC0FVarMemo) :
    (psKernelC0FVarMemoGoWithHash indexHash expr memo).1.value =
      psKernelExprHasFVar expr :=
  (psKernelC0FVarMemoGoWithHash indexHash expr memo).1.source

/-- Exact original public result and proof, with native hash only a hint. -/
def psKernelC0FVarMemoGo
    (expr : PsKernelExpr)
    (memo : PsKernelC0FVarMemo) :
    PsKernelC0ExactFVar expr × PsKernelC0FVarMemo :=
  psKernelC0FVarMemoGoWithHash psKernelC0FVarMemoIdentityHash expr memo

/-- Exact memoized source predicate for any syntax DAG. -/
def psKernelC0MemoizedHasFVar (expr : PsKernelExpr) : Bool :=
  (psKernelC0FVarMemoGo expr .empty).1.value

theorem psKernelC0MemoizedHasFVar_source (expr : PsKernelExpr) :
    psKernelC0MemoizedHasFVar expr = psKernelExprHasFVar expr :=
  (psKernelC0FVarMemoGo expr .empty).1.source

/-- A bounded lookahead avoids constructing a memo for ordinary linear apps. -/
def psKernelC0FVarMemoComplexApp : Nat → PsKernelExpr → Bool
  | 0, _ => false
  | n + 1, .app fn arg =>
      match arg with
      | .app _ _ | .lam _ _ _ _ | .forallE _ _ _ _ | .letE _ _ _ _ _ =>
          true
      | _ => psKernelC0FVarMemoComplexApp n fn
  | _, _ => false

def psKernelC0FVarMemoBinderPrefix : Nat → PsKernelExpr → Bool
  | 0, _ => true
  | n + 1, .lam _ _ body _ => psKernelC0FVarMemoBinderPrefix n body
  | n + 1, .forallE _ _ body _ => psKernelC0FVarMemoBinderPrefix n body
  | _, _ => false

/-- Selector only influences work; both branches return the same source fact. -/
def psKernelC0AdaptiveHasFVar (expr : PsKernelExpr) : Bool :=
  if psKernelC0FVarMemoComplexApp 8 expr ||
      psKernelC0FVarMemoBinderPrefix 12 expr then
    psKernelC0MemoizedHasFVar expr
  else psKernelExprHasFVar expr

theorem psKernelC0AdaptiveHasFVar_source (expr : PsKernelExpr) :
    psKernelC0AdaptiveHasFVar expr = psKernelExprHasFVar expr := by
  unfold psKernelC0AdaptiveHasFVar
  split
  · exact psKernelC0MemoizedHasFVar_source expr
  · rfl

/-- An all-input source-certified native replacement, never a checker fact. -/
@[csimp] theorem psKernelExprHasFVar_csimp :
    @psKernelExprHasFVar = @psKernelC0AdaptiveHasFVar := by
  funext expr
  exact (psKernelC0AdaptiveHasFVar_source expr).symm

/-!
**Pinned Lean 4.35 WHNF optimization boundary.**

The real `shared-subterm` profiler repeatedly entered
`psKernelSemanticCacheEligible` from WHNF. Existing compiler-only
`psKernelExprHasFVar_csimp` does not itself establish that the call site
has been rewritten. Certify the *complete cache-eligibility decision* and
replace that function at the compiler boundary. All source-level kernel
terms, trusted cache admission conditions, scopes and DefEq outcomes stay
exactly unchanged.
-/

/-- Context-free exact cache eligibility, not a memoized checked result. -/
def psKernelC0AdaptiveSemanticCacheEligible
    (expr : PsKernelExpr) : Bool :=
  !psKernelC0AdaptiveHasFVar expr

/-- Every compiled Boolean decision equals the original semantic
    cache guard, including all FVar-positive and shared-DAG cases. -/
theorem psKernelC0AdaptiveSemanticCacheEligible_source
    (expr : PsKernelExpr) :
    psKernelC0AdaptiveSemanticCacheEligible expr =
      psKernelSemanticCacheEligible expr := by
  simp only [psKernelC0AdaptiveSemanticCacheEligible,
    psKernelSemanticCacheEligible, psKernelC0AdaptiveHasFVar_source]

/-- Source-preserving native compilation route for the actual WHNF
    eligibility service; never permits a checked inference or DefEq
    result without the original semantic local-context guard. -/
@[csimp] theorem psKernelSemanticCacheEligible_csimp :
    @psKernelSemanticCacheEligible =
      @psKernelC0AdaptiveSemanticCacheEligible := by
  funext expr
  exact (psKernelC0AdaptiveSemanticCacheEligible_source expr).symm
