import Ps.KernelCore.Runtime.Acceleration.Cache

/-!
Source-certified DAG-aware expression-node counting.

The original psKernelExprNodeCount is the unchanged semantic oracle.
Counting a structurally shared tree as a tree is required for identical
finite traversal/resource budgets; counting only unique DAG nodes would
silently weaken that contract. This memo computes the EXACT expanded
node count compositionally while visiting shared subexpressions once.

No cached result is used for typing, definitional equality or admission.
A shallow hash only chooses a bucket; exact proof-constrained equality
determines whether an entry applies. Every memo entry carries its
original source equation, and the memo lifetime is one operation.
-/

structure PsKernelC0ExactNodeCount (expr : PsKernelExpr) where
  value : Nat
  source : value = psKernelExprNodeCount expr

structure PsKernelC0NodeCountMemoEntry where
  expr : PsKernelExpr
  certified : PsKernelC0ExactNodeCount expr

abbrev PsKernelC0NodeCountMemo :=
  PsKernelC0HashTrie PsKernelC0NodeCountMemoEntry

private def psKernelC0NodeCountMemoFind (expr : PsKernelExpr) :
    List PsKernelC0NodeCountMemoEntry →
      Option (PsKernelC0ExactNodeCount expr)
  | [] => none
  | entry :: rest =>
      match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
      | .isTrue equal =>
          some (by
            cases equal
            exact entry.certified)
      | .isFalse _ => psKernelC0NodeCountMemoFind expr rest

private def psKernelC0NodeCountMemoLookup
    (expr : PsKernelExpr) (memo : PsKernelC0NodeCountMemo) :
    Option (PsKernelC0ExactNodeCount expr) :=
  psKernelC0NodeCountMemoFind expr
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0MemoShapeHash 4 expr))

private def psKernelC0NodeCountMemoStore
    {expr : PsKernelExpr}
    (memo : PsKernelC0NodeCountMemo)
    (checked : PsKernelC0ExactNodeCount expr) :
    PsKernelC0ExactNodeCount expr × PsKernelC0NodeCountMemo :=
  let hash := psKernelC0MemoShapeHash 4 expr
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  (checked, psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ({ expr := expr, certified := checked } :: bucket))

/-- The invariant includes the exact expanded (not unique-DAG) count. -/
def psKernelC0NodeCountMemoGo :
    (expr : PsKernelExpr) → PsKernelC0NodeCountMemo →
      PsKernelC0ExactNodeCount expr × PsKernelC0NodeCountMemo
  | expr, memo =>
      match psKernelC0NodeCountMemoLookup expr memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0NodeCountMemoGo fn memo
              let (a, m2) := psKernelC0NodeCountMemoGo arg m1
              let checked : PsKernelC0ExactNodeCount (.app fn arg) :=
                ⟨Nat.succ (f.value + a.value), by
                  change Nat.succ (f.value + a.value) =
                    Nat.succ (psKernelExprNodeCount fn +
                      psKernelExprNodeCount arg)
                  rw [f.source, a.source]⟩
              psKernelC0NodeCountMemoStore m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0NodeCountMemoGo ty memo
              let (b, m2) := psKernelC0NodeCountMemoGo body m1
              let checked : PsKernelC0ExactNodeCount
                  (.lam name ty body info) :=
                ⟨Nat.succ (t.value + b.value), by
                  change Nat.succ (t.value + b.value) =
                    Nat.succ (psKernelExprNodeCount ty +
                      psKernelExprNodeCount body)
                  rw [t.source, b.source]⟩
              psKernelC0NodeCountMemoStore m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0NodeCountMemoGo ty memo
              let (b, m2) := psKernelC0NodeCountMemoGo body m1
              let checked : PsKernelC0ExactNodeCount
                  (.forallE name ty body info) :=
                ⟨Nat.succ (t.value + b.value), by
                  change Nat.succ (t.value + b.value) =
                    Nat.succ (psKernelExprNodeCount ty +
                      psKernelExprNodeCount body)
                  rw [t.source, b.source]⟩
              psKernelC0NodeCountMemoStore m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0NodeCountMemoGo ty memo
              let (v, m2) := psKernelC0NodeCountMemoGo val m1
              let (b, m3) := psKernelC0NodeCountMemoGo body m2
              let checked : PsKernelC0ExactNodeCount
                  (.letE name ty val body nondep) :=
                ⟨Nat.succ (t.value + (v.value + b.value)), by
                  change Nat.succ (t.value + (v.value + b.value)) =
                    Nat.succ (psKernelExprNodeCount ty +
                      (psKernelExprNodeCount val +
                        psKernelExprNodeCount body))
                  rw [t.source, v.source, b.source]⟩
              psKernelC0NodeCountMemoStore m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0NodeCountMemoGo body memo
              let checked : PsKernelC0ExactNodeCount (.mdata md body) :=
                ⟨Nat.succ b.value, by
                  change Nat.succ b.value =
                    Nat.succ (psKernelExprNodeCount body)
                  rw [b.source]⟩
              psKernelC0NodeCountMemoStore m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0NodeCountMemoGo body memo
              let checked : PsKernelC0ExactNodeCount
                  (.proj name i body) :=
                ⟨Nat.succ b.value, by
                  change Nat.succ b.value =
                    Nat.succ (psKernelExprNodeCount body)
                  rw [b.source]⟩
              psKernelC0NodeCountMemoStore m1 checked
          | .bvar index =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.bvar index))
          | .fvar name =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.fvar name))
          | .mvar name =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.mvar name))
          | .sort level =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.sort level))
          | .const name levels =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.const name levels))
          | .lit literal =>
              psKernelC0NodeCountMemoStore memo
                (⟨1, rfl⟩ : PsKernelC0ExactNodeCount (.lit literal))

def psKernelC0MemoizedExprNodeCount (expr : PsKernelExpr) : Nat :=
  (psKernelC0NodeCountMemoGo expr .empty).1.value

theorem psKernelC0MemoizedExprNodeCount_source (expr : PsKernelExpr) :
    psKernelC0MemoizedExprNodeCount expr = psKernelExprNodeCount expr :=
  (psKernelC0NodeCountMemoGo expr .empty).1.source

/-- Independent direct algorithm, not a call back into the compiler-replaced
source name. Plain linear trees avoid memo allocation on this path. -/
def psKernelC0DirectExprNodeCount : PsKernelExpr → Nat
  | .app f a => Nat.succ (Nat.add
      (psKernelC0DirectExprNodeCount f)
      (psKernelC0DirectExprNodeCount a))
  | .lam _ ty body _ => Nat.succ (Nat.add
      (psKernelC0DirectExprNodeCount ty)
      (psKernelC0DirectExprNodeCount body))
  | .forallE _ ty body _ => Nat.succ (Nat.add
      (psKernelC0DirectExprNodeCount ty)
      (psKernelC0DirectExprNodeCount body))
  | .letE _ ty val body _ => Nat.succ (Nat.add
      (psKernelC0DirectExprNodeCount ty)
      (Nat.add (psKernelC0DirectExprNodeCount val)
        (psKernelC0DirectExprNodeCount body)))
  | .mdata _ body => Nat.succ (psKernelC0DirectExprNodeCount body)
  | .proj _ _ body => Nat.succ (psKernelC0DirectExprNodeCount body)
  | _ => 1

theorem psKernelC0DirectExprNodeCount_source (expr : PsKernelExpr) :
    psKernelC0DirectExprNodeCount expr = psKernelExprNodeCount expr := by
  induction expr <;>
    simp [psKernelC0DirectExprNodeCount, psKernelExprNodeCount, *]
    
/-- Bounded selector: expensive shared application shapes and large binder
prefixes use the certified memo; trivial/linear roots retain direct work. -/
def psKernelC0NodeCountComplexApp : Nat → PsKernelExpr → Bool
  | 0, _ => false
  | n + 1, .app fn arg =>
      match arg with
      | .app _ _ | .lam _ _ _ _ | .forallE _ _ _ _ | .letE _ _ _ _ _ =>
          true
      | _ => psKernelC0NodeCountComplexApp n fn
  | _, _ => false

def psKernelC0NodeCountBinderPrefix : Nat → PsKernelExpr → Bool
  | 0, _ => true
  | n + 1, .lam _ _ body _ => psKernelC0NodeCountBinderPrefix n body
  | n + 1, .forallE _ _ body _ => psKernelC0NodeCountBinderPrefix n body
  | _, _ => false

def psKernelC0AdaptiveExprNodeCount (expr : PsKernelExpr) : Nat :=
  if psKernelC0NodeCountComplexApp 8 expr ||
      psKernelC0NodeCountBinderPrefix 12 expr then
    psKernelC0MemoizedExprNodeCount expr
  else psKernelC0DirectExprNodeCount expr

theorem psKernelC0AdaptiveExprNodeCount_source (expr : PsKernelExpr) :
    psKernelC0AdaptiveExprNodeCount expr = psKernelExprNodeCount expr := by
  unfold psKernelC0AdaptiveExprNodeCount
  split
  · exact psKernelC0MemoizedExprNodeCount_source expr
  · exact psKernelC0DirectExprNodeCount_source expr

/-- Full all-input numerical equivalence: semantic checker fuel and
source resource limits are completely unchanged by the native rewrite. -/
@[csimp] theorem psKernelExprNodeCount_csimp :
    @psKernelExprNodeCount = @psKernelC0AdaptiveExprNodeCount := by
  funext expr
  exact (psKernelC0AdaptiveExprNodeCount_source expr).symm
