import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Core declaration validation shared by all admission operations.

This module checks universe-parameter discipline, rejects metavariables/free
variables, validates declaration headers as sorts, and checks definition bodies
against their declared types. It does not mutate the global environment.
-/


def psKernelSafetyEq
    (left : PsKernelDefinitionSafety)
    (right : PsKernelDefinitionSafety) : Bool :=
  match left with
  | PsKernelDefinitionSafety.unsafeDef =>
      match right with
      | PsKernelDefinitionSafety.unsafeDef => true
      | _ => false
  | PsKernelDefinitionSafety.safe =>
      match right with
      | PsKernelDefinitionSafety.safe => true
      | _ => false
  | PsKernelDefinitionSafety.partialDef =>
      match right with
      | PsKernelDefinitionSafety.partialDef => true
      | _ => false

def psKernelNameListsEq
    (left : List PsKernelName) :
    List PsKernelName -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelName) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelNameListsEq leftTail;
      fun (right : List PsKernelName) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelNameEq leftHead rightHead then
              smaller rightTail
            else
              false

def psKernelFindUndefExprLevelParam
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Option PsKernelName :=
  match expr with
  | PsKernelExpr.sort level =>
      psKernelFindUndefLevelParam
        level
        allowed
  | PsKernelExpr.const _ levels =>
      psKernelFindUndefInLevels
        levels
        allowed
  | PsKernelExpr.app fn arg =>
      match
          psKernelFindUndefExprLevelParam
            fn
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            arg
            allowed
  | PsKernelExpr.lam _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.forallE _ type body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          psKernelFindUndefExprLevelParam
            body
            allowed
  | PsKernelExpr.letE _ type value body _ =>
      match
          psKernelFindUndefExprLevelParam
            type
            allowed with
      | Option.some name =>
          Option.some name
      | Option.none =>
          match
              psKernelFindUndefExprLevelParam
                value
                allowed with
          | Option.some name =>
              Option.some name
          | Option.none =>
              psKernelFindUndefExprLevelParam
                body
                allowed
  | PsKernelExpr.mdata _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | PsKernelExpr.proj _ _ body =>
      psKernelFindUndefExprLevelParam
        body
        allowed
  | _ =>
      Option.none

/-!
A source-exact, per-query memo for the FIRST undefined universe level name in
an expression. The original recursive function above remains the specification.

The allowed universe-parameter list is FIXED for the entire memo's lifetime
and is a type-level index on every stored result. The immutable trie hashes
select a bucket only; every candidate uses proof-constrained pointer/structural
equality. Neither a hash collision nor any previously checked environment
can grant admission or change which offending name is reported.
-/

/-!
Native-only, *non-authoritative* syntax memo index for the previous
source-certified MVar and first-undefined-level-parameter scans. The old
depth-four shape selector is retained as a portable Lean source definition;
native compilation can use immutable runtime node identity as a bucket hint.

Every bucket hit is separately validated by a proof-producing exact
structural `Decidable (expr = entry.expr)`. The pointer index is NEVER a
proof of equality, a free-variable authorization, or a checking decision.
Crucially, this hint is captured on the ORIGINAL scrutinee before dependent
constructor matching may rebuild a root object. Therefore lookup and store
use the SAME key for a single source node even if its proof-carrying result
is represented by a reconstructed constructor.
-/
private unsafe def psKernelC0AdmissionNodeHintNative
    (expr : PsKernelExpr) : Nat :=
  (ptrAddrUnsafe expr).toNat / 16

@[implemented_by psKernelC0AdmissionNodeHintNative]
private def psKernelC0AdmissionNodeHint (expr : PsKernelExpr) : Nat :=
  psKernelC0MemoShapeHash 4 expr

structure PsKernelC0ExactUndef
    (allowed : List PsKernelName) (expr : PsKernelExpr) where
  value : Option PsKernelName
  source : value = psKernelFindUndefExprLevelParam expr allowed

structure PsKernelC0UndefMemoEntry (allowed : List PsKernelName) where
  expr : PsKernelExpr
  certified : PsKernelC0ExactUndef allowed expr

abbrev PsKernelC0UndefMemo (allowed : List PsKernelName) :=
  PsKernelC0HashTrie (PsKernelC0UndefMemoEntry allowed)

private def psKernelC0UndefMemoFind
    {allowed : List PsKernelName} (expr : PsKernelExpr) :
    List (PsKernelC0UndefMemoEntry allowed) →
      Option (PsKernelC0ExactUndef allowed expr)
  | [] => none
  | entry :: rest =>
      match psKernelC0DeepPtrDecEq expr entry.expr with
      | .isTrue equal =>
          some (by
            cases equal
            exact entry.certified)
      | .isFalse _ =>
          psKernelC0UndefMemoFind expr rest

private def psKernelC0UndefMemoLookup
    (allowed : List PsKernelName) (expr : PsKernelExpr)
    (hint : Nat) (memo : PsKernelC0UndefMemo allowed) :
    Option (PsKernelC0ExactUndef allowed expr) :=
  psKernelC0UndefMemoFind expr
    (psKernelC0TrieBucket psKernelC0IndexDepth memo hint)

private def psKernelC0UndefMemoStore
    (hint : Nat)
    {allowed : List PsKernelName} {expr : PsKernelExpr}
    (memo : PsKernelC0UndefMemo allowed)
    (checked : PsKernelC0ExactUndef allowed expr) :
    PsKernelC0ExactUndef allowed expr × PsKernelC0UndefMemo allowed :=
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hint
  (checked, psKernelC0TrieSet psKernelC0IndexDepth memo hint
    ({expr := expr, certified := checked} :: bucket))

/-- Combine two source-proven independent results in original left-to-right
order, retaining the FIRST offender and never reordering two distinct names. -/
private def psKernelC0UndefFirst
    (first second : Option PsKernelName) : Option PsKernelName :=
  match first with
  | some name => some name
  | none => second

/-- Independently computes the exact original first offending name, threading
one certified immutable memo across descendants in a shared expression DAG. -/
def psKernelC0UndefMemoGo (allowed : List PsKernelName) :
    (expr : PsKernelExpr) → PsKernelC0UndefMemo allowed →
      PsKernelC0ExactUndef allowed expr × PsKernelC0UndefMemo allowed
  | expr, memo =>
      let hint := psKernelC0AdmissionNodeHint expr
      match psKernelC0UndefMemoLookup allowed expr hint memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0UndefMemoGo allowed fn memo
              let (a, m2) := psKernelC0UndefMemoGo allowed arg m1
              let checked : PsKernelC0ExactUndef allowed (.app fn arg) :=
                ⟨psKernelC0UndefFirst f.value a.value, by
                  change psKernelC0UndefFirst f.value a.value =
                    (match psKernelFindUndefExprLevelParam fn allowed with
                     | some name => some name
                     | none => psKernelFindUndefExprLevelParam arg allowed)
                  rw [← f.source, ← a.source]
                  rfl⟩
              psKernelC0UndefMemoStore hint m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0UndefMemoGo allowed ty memo
              let (b, m2) := psKernelC0UndefMemoGo allowed body m1
              let checked : PsKernelC0ExactUndef allowed (.lam name ty body info) :=
                ⟨psKernelC0UndefFirst t.value b.value, by
                  change psKernelC0UndefFirst t.value b.value =
                    (match psKernelFindUndefExprLevelParam ty allowed with
                     | some name => some name
                     | none => psKernelFindUndefExprLevelParam body allowed)
                  rw [← t.source, ← b.source]
                  rfl⟩
              psKernelC0UndefMemoStore hint m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0UndefMemoGo allowed ty memo
              let (b, m2) := psKernelC0UndefMemoGo allowed body m1
              let checked : PsKernelC0ExactUndef allowed (.forallE name ty body info) :=
                ⟨psKernelC0UndefFirst t.value b.value, by
                  change psKernelC0UndefFirst t.value b.value =
                    (match psKernelFindUndefExprLevelParam ty allowed with
                     | some name => some name
                     | none => psKernelFindUndefExprLevelParam body allowed)
                  rw [← t.source, ← b.source]
                  rfl⟩
              psKernelC0UndefMemoStore hint m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0UndefMemoGo allowed ty memo
              let (v, m2) := psKernelC0UndefMemoGo allowed val m1
              let (b, m3) := psKernelC0UndefMemoGo allowed body m2
              let checked : PsKernelC0ExactUndef allowed (.letE name ty val body nondep) :=
                ⟨psKernelC0UndefFirst t.value
                    (psKernelC0UndefFirst v.value b.value), by
                  change psKernelC0UndefFirst t.value
                      (psKernelC0UndefFirst v.value b.value) =
                    (match psKernelFindUndefExprLevelParam ty allowed with
                     | some name => some name
                     | none =>
                         match psKernelFindUndefExprLevelParam val allowed with
                         | some name => some name
                         | none => psKernelFindUndefExprLevelParam body allowed)
                  rw [← t.source, ← v.source, ← b.source]
                  rfl⟩
              psKernelC0UndefMemoStore hint m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0UndefMemoGo allowed body memo
              let checked : PsKernelC0ExactUndef allowed (.mdata md body) :=
                ⟨b.value, by
                  change b.value = psKernelFindUndefExprLevelParam body allowed
                  exact b.source⟩
              psKernelC0UndefMemoStore hint m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0UndefMemoGo allowed body memo
              let checked : PsKernelC0ExactUndef allowed (.proj name i body) :=
                ⟨b.value, by
                  change b.value = psKernelFindUndefExprLevelParam body allowed
                  exact b.source⟩
              psKernelC0UndefMemoStore hint m1 checked
          | .sort level =>
              psKernelC0UndefMemoStore hint memo
                (⟨psKernelFindUndefLevelParam level allowed, rfl⟩ :
                  PsKernelC0ExactUndef allowed (.sort level))
          | .const name levels =>
              psKernelC0UndefMemoStore hint memo
                (⟨psKernelFindUndefInLevels levels allowed, rfl⟩ :
                  PsKernelC0ExactUndef allowed (.const name levels))
          | .bvar index =>
              psKernelC0UndefMemoStore hint memo
                (⟨none, rfl⟩ : PsKernelC0ExactUndef allowed (.bvar index))
          | .fvar name =>
              psKernelC0UndefMemoStore hint memo
                (⟨none, rfl⟩ : PsKernelC0ExactUndef allowed (.fvar name))
          | .mvar name =>
              psKernelC0UndefMemoStore hint memo
                (⟨none, rfl⟩ : PsKernelC0ExactUndef allowed (.mvar name))
          | .lit literal =>
              psKernelC0UndefMemoStore hint memo
                (⟨none, rfl⟩ : PsKernelC0ExactUndef allowed (.lit literal))

def psKernelC0MemoizedFindUndefExprLevelParam
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    Option PsKernelName :=
  (psKernelC0UndefMemoGo allowed expr .empty).1.value

theorem psKernelC0MemoizedFindUndefExprLevelParam_source
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    psKernelC0MemoizedFindUndefExprLevelParam expr allowed =
      psKernelFindUndefExprLevelParam expr allowed :=
  (psKernelC0UndefMemoGo allowed expr .empty).1.source

/-- Pure DAG-shape selector only; the original source remains the exact
fallback for shallow linear expressions. -/
def psKernelC0AdaptiveFindUndefExprLevelParam
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    Option PsKernelName :=
  if psKernelC0FVarMemoComplexApp 8 expr ||
      psKernelC0FVarMemoBinderPrefix 12 expr then
    psKernelC0MemoizedFindUndefExprLevelParam expr allowed
  else psKernelFindUndefExprLevelParam expr allowed

theorem psKernelC0AdaptiveFindUndefExprLevelParam_source
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    psKernelC0AdaptiveFindUndefExprLevelParam expr allowed =
      psKernelFindUndefExprLevelParam expr allowed := by
  unfold psKernelC0AdaptiveFindUndefExprLevelParam
  split
  · exact psKernelC0MemoizedFindUndefExprLevelParam_source expr allowed
  · rfl

def psKernelLevelHasMVar
    (level : PsKernelLevel) : Bool :=
  match level with
  | PsKernelLevel.mvar _ =>
      true
  | PsKernelLevel.succ inner =>
      psKernelLevelHasMVar inner
  | PsKernelLevel.max left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | PsKernelLevel.imax left right =>
      if psKernelLevelHasMVar left then
        true
      else
        psKernelLevelHasMVar right
  | _ =>
      false

def psKernelLevelsHaveMVar
    (levels : List PsKernelLevel) : Bool :=
  match levels with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelLevelHasMVar head then
        true
      else
        psKernelLevelsHaveMVar tail

def psKernelExprHasMVar
    (expr : PsKernelExpr) : Bool :=
  match expr with
  | PsKernelExpr.mvar _ =>
      true
  | PsKernelExpr.sort level =>
      psKernelLevelHasMVar level
  | PsKernelExpr.const _ levels =>
      psKernelLevelsHaveMVar levels
  | PsKernelExpr.app fn arg =>
      if psKernelExprHasMVar fn then
        true
      else
        psKernelExprHasMVar arg
  | PsKernelExpr.lam _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.forallE _ type body _ =>
      if psKernelExprHasMVar type then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.letE _ type value body _ =>
      if psKernelExprHasMVar type then
        true
      else if psKernelExprHasMVar value then
        true
      else
        psKernelExprHasMVar body
  | PsKernelExpr.mdata _ body =>
      psKernelExprHasMVar body
  | PsKernelExpr.proj _ _ body =>
      psKernelExprHasMVar body
  | _ =>
      false

/-!
Proof-bearing, per-query DAG-aware metavariable membership. The exact source
algorithm above remains independently available; only the native compiler
gets a proved equal implementation. Ordinary metadata leaves and linear
syntax pay no memo allocation. Every hash collision is checked by equality.
-/

structure PsKernelC0ExactMVar (expr : PsKernelExpr) where
  value : Bool
  source : value = psKernelExprHasMVar expr

structure PsKernelC0MVarMemoEntry where
  expr : PsKernelExpr
  certified : PsKernelC0ExactMVar expr

abbrev PsKernelC0MVarMemo :=
  PsKernelC0HashTrie PsKernelC0MVarMemoEntry

private def psKernelC0MVarMemoFind (expr : PsKernelExpr) :
    List PsKernelC0MVarMemoEntry →
      Option (PsKernelC0ExactMVar expr)
  | [] => none
  | entry :: rest =>
      match psKernelC0DeepPtrDecEq expr entry.expr with
      | .isTrue equal =>
          some (by
            cases equal
            exact entry.certified)
      | .isFalse _ =>
          psKernelC0MVarMemoFind expr rest

private def psKernelC0MVarMemoLookup
    (expr : PsKernelExpr) (hint : Nat)
    (memo : PsKernelC0MVarMemo) :
    Option (PsKernelC0ExactMVar expr) :=
  psKernelC0MVarMemoFind expr
    (psKernelC0TrieBucket psKernelC0IndexDepth memo hint)

private def psKernelC0MVarMemoStore
    (hint : Nat)
    {expr : PsKernelExpr}
    (memo : PsKernelC0MVarMemo)
    (checked : PsKernelC0ExactMVar expr) :
    PsKernelC0ExactMVar expr × PsKernelC0MVarMemo :=
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hint
  (checked, psKernelC0TrieSet psKernelC0IndexDepth memo hint
    ({ expr := expr, certified := checked } :: bucket))

/-- One memo per query, never transported across checker or expression states. -/
def psKernelC0MVarMemoGo :
    (expr : PsKernelExpr) → PsKernelC0MVarMemo →
      PsKernelC0ExactMVar expr × PsKernelC0MVarMemo
  | expr, memo =>
      let hint := psKernelC0AdmissionNodeHint expr
      match psKernelC0MVarMemoLookup expr hint memo with
      | some checked => (checked, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0MVarMemoGo fn memo
              -- The source predicate short-circuits on the function side.
              -- Do not traverse a potentially enormous argument DAG when
              -- the left child already certifies the presence of an MVar.
              if h : f.value = true then
                let checked : PsKernelC0ExactMVar (.app fn arg) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar fn then true
                       else psKernelExprHasMVar arg)
                    rw [← f.source]
                    simp [h]⟩
                psKernelC0MVarMemoStore hint m1 checked
              else
                let (a, m2) := psKernelC0MVarMemoGo arg m1
                let checked : PsKernelC0ExactMVar (.app fn arg) :=
                  ⟨a.value, by
                    change a.value =
                      (if psKernelExprHasMVar fn then true
                       else psKernelExprHasMVar arg)
                    rw [← f.source, ← a.source]
                    simp [h]⟩
                psKernelC0MVarMemoStore hint m2 checked
          | .lam name ty body info =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar (.lam name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore hint m1 checked
              else
                let (b, m2) := psKernelC0MVarMemoGo body m1
                let checked : PsKernelC0ExactMVar (.lam name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore hint m2 checked
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar (.forallE name ty body info) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore hint m1 checked
              else
                let (b, m2) := psKernelC0MVarMemoGo body m1
                let checked : PsKernelC0ExactMVar (.forallE name ty body info) :=
                  ⟨b.value, by
                    change b.value =
                      (if psKernelExprHasMVar ty then true
                       else psKernelExprHasMVar body)
                    rw [← t.source, ← b.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore hint m2 checked
          | .letE name ty val body nondep =>
              let (t, m1) := psKernelC0MVarMemoGo ty memo
              if ht : t.value = true then
                let checked : PsKernelC0ExactMVar
                    (.letE name ty val body nondep) :=
                  ⟨true, by
                    change true =
                      (if psKernelExprHasMVar ty then true
                       else if psKernelExprHasMVar val then true
                       else psKernelExprHasMVar body)
                    rw [← t.source]
                    simp [ht]⟩
                psKernelC0MVarMemoStore hint m1 checked
              else
                let (v, m2) := psKernelC0MVarMemoGo val m1
                if hv : v.value = true then
                  let checked : PsKernelC0ExactMVar
                      (.letE name ty val body nondep) :=
                    ⟨true, by
                      change true =
                        (if psKernelExprHasMVar ty then true
                         else if psKernelExprHasMVar val then true
                         else psKernelExprHasMVar body)
                      rw [← t.source, ← v.source]
                      simp [ht, hv]⟩
                  psKernelC0MVarMemoStore hint m2 checked
                else
                  let (b, m3) := psKernelC0MVarMemoGo body m2
                  let checked : PsKernelC0ExactMVar
                      (.letE name ty val body nondep) :=
                    ⟨b.value, by
                      change b.value =
                        (if psKernelExprHasMVar ty then true
                         else if psKernelExprHasMVar val then true
                         else psKernelExprHasMVar body)
                      rw [← t.source, ← v.source, ← b.source]
                      simp [ht, hv]⟩
                  psKernelC0MVarMemoStore hint m3 checked
          | .mdata md body =>
              let (b, m1) := psKernelC0MVarMemoGo body memo
              let checked : PsKernelC0ExactMVar (.mdata md body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasMVar body
                  exact b.source⟩
              psKernelC0MVarMemoStore hint m1 checked
          | .proj name i body =>
              let (b, m1) := psKernelC0MVarMemoGo body memo
              let checked : PsKernelC0ExactMVar (.proj name i body) :=
                ⟨b.value, by
                  change b.value = psKernelExprHasMVar body
                  exact b.source⟩
              psKernelC0MVarMemoStore hint m1 checked
          | .mvar name =>
              psKernelC0MVarMemoStore hint memo
                (⟨true, rfl⟩ : PsKernelC0ExactMVar (.mvar name))
          | .bvar index =>
              psKernelC0MVarMemoStore hint memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.bvar index))
          | .fvar name =>
              psKernelC0MVarMemoStore hint memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.fvar name))
          | .sort level =>
              psKernelC0MVarMemoStore hint memo
                (⟨psKernelLevelHasMVar level, rfl⟩ :
                  PsKernelC0ExactMVar (.sort level))
          | .const name levels =>
              psKernelC0MVarMemoStore hint memo
                (⟨psKernelLevelsHaveMVar levels, rfl⟩ :
                  PsKernelC0ExactMVar (.const name levels))
          | .lit literal =>
              psKernelC0MVarMemoStore hint memo
                (⟨false, rfl⟩ : PsKernelC0ExactMVar (.lit literal))


/-- Shared-DAG metavariable check, certified equal to the original
source-level checking predicate (including universe metavariables). -/
def psKernelC0MemoizedHasMVar (expr : PsKernelExpr) : Bool :=
  (psKernelC0MVarMemoGo expr .empty).1.value

theorem psKernelC0MemoizedHasMVar_source (expr : PsKernelExpr) :
    psKernelC0MemoizedHasMVar expr = psKernelExprHasMVar expr :=
  (psKernelC0MVarMemoGo expr .empty).1.source

/-- Reuse FVar's PURE shape heuristics: neither searches for an FVar nor
introduces any shared source context. The source predicate remains the fast
path for a shallow linear expression; the memo is per-call and immutable. -/
def psKernelC0AdaptiveHasMVar (expr : PsKernelExpr) : Bool :=
  if psKernelC0FVarMemoComplexApp 8 expr ||
      psKernelC0FVarMemoBinderPrefix 12 expr then
    psKernelC0MemoizedHasMVar expr
  else psKernelExprHasMVar expr

theorem psKernelC0AdaptiveHasMVar_source (expr : PsKernelExpr) :
    psKernelC0AdaptiveHasMVar expr = psKernelExprHasMVar expr := by
  unfold psKernelC0AdaptiveHasMVar
  split
  · exact psKernelC0MemoizedHasMVar_source expr
  · rfl

/-- Compiler-only source-equivalent native optimization. No new logical
admission premise, no unsound cross-environment cache and no fuel changes. -/
@[csimp] theorem psKernelExprHasMVar_csimp :
    @psKernelExprHasMVar = @psKernelC0AdaptiveHasMVar := by
  funext expr
  exact (psKernelC0AdaptiveHasMVar_source expr).symm

def psKernelCheckNoMVarNoFVar
    (expr : PsKernelExpr) :
    Except String Unit :=
  -- Consume the independent source-certified MVar and FVar predicates
  -- directly: compiler csimp application inside the module defining the
  -- old predicates is not assumed. Each predicate has an all-input proof,
  -- so the exact historical MVar-before-FVar error order is preserved.
  if psKernelC0AdaptiveHasMVar expr then
    Except.error
      "declaration has metavariables"
  else if psKernelC0AdaptiveHasFVar expr then
    Except.error
      "declaration has free variables"
  else
    Except.ok ()

/-- All-input exact old declaration-screening result, including error
    precedence and message. This does NOT authorize an unchecked term. -/
theorem psKernelC0CheckNoMVarNoFVar_source (expr : PsKernelExpr) :
    psKernelCheckNoMVarNoFVar expr =
      (if psKernelExprHasMVar expr then
        (Except.error "declaration has metavariables" : Except String Unit)
       else if psKernelExprHasFVar expr then
        Except.error "declaration has free variables"
       else Except.ok ()) := by
  simp only [psKernelCheckNoMVarNoFVar,
    psKernelC0AdaptiveHasMVar_source,
    psKernelC0AdaptiveHasFVar_source]

def psKernelCheckLevelParams
    (expr : PsKernelExpr)
    (allowed : List PsKernelName) :
    Except String Unit :=
  -- Source-verified FIRST undefined name, computed without unfolding a
  -- shared expression DAG exponentially.
  match
      psKernelC0AdaptiveFindUndefExprLevelParam
        expr
        allowed with
  | Option.some _ =>
      Except.error
        "invalid reference to undefined universe level parameter"
  | Option.none =>
      Except.ok ()

/-- Prove the COMPLETE original declaration universe-validation result,
including the first offending parameter and exact error message. -/
theorem psKernelC0CheckLevelParams_source
    (expr : PsKernelExpr) (allowed : List PsKernelName) :
    psKernelCheckLevelParams expr allowed =
      (match psKernelFindUndefExprLevelParam expr allowed with
       | some _ =>
           (Except.error "invalid reference to undefined universe level parameter" :
             Except String Unit)
       | none => Except.ok ()) := by
  simp only [psKernelCheckLevelParams,
    psKernelC0AdaptiveFindUndefExprLevelParam_source]

def psKernelCheckConstantBaseWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (base : PsKernelConstantBase) :
    Except String PsKernelCheckerSession :=
  if
      psKernelEnvironmentContains
        session.context.environment
        base.name then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        base.levelParams then
    Except.error
      "duplicate universe parameter"
  else
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error =>
        Except.error error
    | Except.ok _ =>
        match
            psKernelCheckLevelParams
              base.type
              base.levelParams with
        | Except.error error =>
            Except.error error
        | Except.ok _ =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  base.type with
            | Except.error error =>
                Except.error error
            | Except.ok typeType =>
                match
                    psKernelSessionEnsureSort
                      fuel
                      (Prod.snd typeType)
                      (Prod.fst typeType) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.snd result)

def psKernelCheckDefinitionBodyWithSession
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo) :
    Except String PsKernelCheckerSession :=
  match psKernelCheckNoMVarNoFVar value.value with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match
              psKernelSessionCheck
                fuel
                session
                value.value with
          | Except.error error =>
              Except.error error
          | Except.ok valueType =>
              match
                  psKernelSessionIsDefEq
                    fuel
                    (Prod.snd valueType)
                    (Prod.fst valueType)
                    value.base.type with
              | Except.error error =>
                  Except.error error
              | Except.ok equal =>
                  if Prod.fst equal then
                    Except.ok
                      (Prod.snd equal)
                  else
                    Except.error
                      "definition type mismatch"
