import Ps.KernelCore.Runtime.Acceleration.CertifiedNodeCountMemo

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

abbrev PsKernelC0FVarMemo :=
  PsKernelC0HashTrie PsKernelC0FVarMemoEntry

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

private def psKernelC0FVarMemoLookup
    (expr : PsKernelExpr) (memo : PsKernelC0FVarMemo) :
    Option (PsKernelC0ExactFVar expr) :=
  psKernelC0FVarMemoFind expr
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0MemoShapeHash 4 expr))

private def psKernelC0FVarMemoStore
    {expr : PsKernelExpr}
    (memo : PsKernelC0FVarMemo)
    (checked : PsKernelC0ExactFVar expr) :
    PsKernelC0ExactFVar expr × PsKernelC0FVarMemo :=
  let hash := psKernelC0MemoShapeHash 4 expr
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  (checked, psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ({ expr := expr, certified := checked } :: bucket))

/-- One memo per query, never transported across checker or expression states. -/
def psKernelC0FVarMemoGo :
    (expr : PsKernelExpr) → PsKernelC0FVarMemo →
      PsKernelC0ExactFVar expr × PsKernelC0FVarMemo
  | expr, memo =>
      match psKernelC0FVarMemoLookup expr memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0FVarMemoGo fn memo
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
                psKernelC0FVarMemoStore m1 checked
              else
                let (a, m2) := psKernelC0FVarMemoGo arg m1
                let checked : PsKernelC0ExactFVar (.app fn arg) :=
                  ⟨a.value, by
                    change a.value =
                      (if psKernelExprHasFVar fn then true
                       else psKernelExprHasFVar arg)
                    rw [← f.source, ← a.source]
                    simp [h]⟩
                psKernelC0FVarMemoStore m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0FVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactFVar (.lam name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore m1 checked
              else
                let (b, m2) := psKernelC0FVarMemoGo body m1
                let checked : PsKernelC0ExactFVar (.lam name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0FVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactFVar (.forallE name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore m1 checked
              else
                let (b, m2) := psKernelC0FVarMemoGo body m1
                let checked : PsKernelC0ExactFVar (.forallE name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasFVar ty then true
                       else psKernelExprHasFVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0FVarMemoStore m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0FVarMemoGo ty memo
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
                psKernelC0FVarMemoStore m1 checked
              else
                let (v, m2) := psKernelC0FVarMemoGo val m1
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
                  psKernelC0FVarMemoStore m2 checked
                else
                  let (b, m3) := psKernelC0FVarMemoGo body m2
                  let checked : PsKernelC0ExactFVar
                      (.letE name ty val body nondep) :=
                    ⟨b.value, by
                      change b.value =
                        (if psKernelExprHasFVar ty then true
                         else if psKernelExprHasFVar val then true
                         else psKernelExprHasFVar body)
                      rw [← t.source, ← v.source, ← b.source]
                      simp [ht, hv]⟩
                  psKernelC0FVarMemoStore m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0FVarMemoGo body memo
              let checked : PsKernelC0ExactFVar (.mdata md body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasFVar body
                  exact b.source⟩
              psKernelC0FVarMemoStore m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0FVarMemoGo body memo
              let checked : PsKernelC0ExactFVar (.proj name i body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasFVar body
                  exact b.source⟩
              psKernelC0FVarMemoStore m1 checked
          | .fvar name =>
              psKernelC0FVarMemoStore memo
                (⟨true, rfl⟩ : PsKernelC0ExactFVar (.fvar name))
          | .bvar index =>
              psKernelC0FVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.bvar index))
          | .mvar name =>
              psKernelC0FVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.mvar name))
          | .sort level =>
              psKernelC0FVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.sort level))
          | .const name levels =>
              psKernelC0FVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.const name levels))
          | .lit literal =>
              psKernelC0FVarMemoStore memo
                (⟨false, rfl⟩ : PsKernelC0ExactFVar (.lit literal))

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
