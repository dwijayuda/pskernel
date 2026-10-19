import Ps.KernelCore.Runtime.Acceleration.CertifiedHashMemo
import Ps.KernelCore.Core.Substitution.Instantiate
import Lean
import Ps.KernelCore.Architecture.CertifiedLooseBVarBound

/-!
Source-exact, immutable operation-local memoization of single-variable
instantiation for heavily shared Lean expression DAGs.

Key: (exact source syntax, exact binder offset), under a type-level fixed
replacement. A cheap shallow expression shape hash selects buckets; it
NEVER decides equality. The lookup uses proof-constrained pointer equality,
then full propositional constructor equality on a possible collision.

Every result stores an independent Lean proof that it equals the original
psKernelC0ExprInstantiateOneChanged result, including the changed flag.
There are no new accepting kernel rules, untrusted hashes, admissions or
cross-context checked cache reuse. Existing source remains an oracle.
-/

private theorem c0NoSubstNatLt {a b : Nat} (h : a < b) :
    psKernelNatLt a b = true := by
  unfold psKernelNatLt
  have ne : a ≠ b := Nat.ne_of_lt h
  have eqFalse : Nat.beq a b = false := by
    cases k : Nat.beq a b with
    | false => rfl
    | true => exact False.elim (ne (Nat.eq_of_beq_eq_true k))
  simp [eqFalse, Nat.ble_eq_true_of_le (Nat.le_of_lt h)]

/-- All-input *proof* of no substitution when the cached bound excludes
    any free de Bruijn index at the required binder offset. The old source
    algorithm remains the independent oracle. This theorem does not claim
    a checked proof/type/DefEq judgment or relax any fuel/admission rule. -/
theorem c0NoSubstitutionFromBound (expr replacement : PsKernelExpr) :
    ∀ (offset : Nat), expr.psKernelC0LooseBVarBound ≤ offset →
      psKernelC0ExprInstantiateOneChanged expr replacement offset =
        (expr, false) := by
  induction expr with
  | bvar index =>
      intro offset h
      have hlt : index < offset := by
        simp only [PsKernelExpr.psKernelC0LooseBVarBound] at h
        omega
      simp [psKernelC0ExprInstantiateOneChanged, c0NoSubstNatLt hlt]
  | app fn arg ihf iha =>
      intro offset h
      have hmax : Nat.max fn.psKernelC0LooseBVarBound
          arg.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have hf : fn.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have ha : arg.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      simp [psKernelC0ExprInstantiateOneChanged, ihf offset hf, iha offset ha]
  | lam name ty body binder iht ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht, ihb (offset+1) hb]
  | forallE name ty body binder iht ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht, ihb (offset+1) hb]
  | letE name ty value body nondep iht ihv ihb =>
      intro offset h
      have hmax : Nat.max ty.psKernelC0LooseBVarBound
          (Nat.max value.psKernelC0LooseBVarBound
            (body.psKernelC0LooseBVarBound - 1)) ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      have ht : ty.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hmax
      have hrest : Nat.max value.psKernelC0LooseBVarBound
          (body.psKernelC0LooseBVarBound - 1) ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hmax
      have hv : value.psKernelC0LooseBVarBound ≤ offset :=
        Nat.le_trans (Nat.le_max_left ..) hrest
      have hb0 : body.psKernelC0LooseBVarBound - 1 ≤ offset :=
        Nat.le_trans (Nat.le_max_right ..) hrest
      have hb : body.psKernelC0LooseBVarBound ≤ offset + 1 := by omega
      simp [psKernelC0ExprInstantiateOneChanged, iht offset ht,
        ihv offset hv, ihb (offset+1) hb]
  | mdata md body ih =>
      intro offset h
      have hb : body.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      simp [psKernelC0ExprInstantiateOneChanged, ih offset hb]
  | proj name index body ih =>
      intro offset h
      have hb : body.psKernelC0LooseBVarBound ≤ offset := by
        simpa only [PsKernelExpr.psKernelC0LooseBVarBound] using h
      simp [psKernelC0ExprInstantiateOneChanged, ih offset hb]
  | _ =>
      intros offset h
      rfl


structure PsKernelC0InstOneExact
    (replacement expr : PsKernelExpr) (offset : Nat) where
  value : PsKernelExpr × Bool
  source : value = psKernelC0ExprInstantiateOneChanged expr replacement offset

structure PsKernelC0InstOneMemoEntry (replacement : PsKernelExpr) where
  expr : PsKernelExpr
  offset : Nat
  exact : PsKernelC0InstOneExact replacement expr offset

abbrev PsKernelC0InstOneMemo (replacement : PsKernelExpr) :=
  PsKernelC0HashTrie (PsKernelC0InstOneMemoEntry replacement)

/-!
Native-only non-authoritative index hint for the *operation-local*
proof-carrying substitution cache. The old source hash remains unchanged
below. Original immutable child addresses survive dependent root matching,
unlike a reconstructed parent object's address. Collisions and false misses
affect only performance: a cache HIT must still pass the existing
withPtrEqDecEq proof and exact binder-offset equality before reuse.

This is a compiler/runtime trust and portability obligation separate from
the pure source theorem; no hash/pointer alone can accept a declaration.
-/
private unsafe def psKernelC0InstOneMemoHashNative
    (expr : PsKernelExpr) (offset : Nat) : Nat :=
  let childHint (child : PsKernelExpr) : Nat :=
    (ptrAddrUnsafe child).toNat / 16
  let shape :=
    match expr with
    | .app fn arg =>
        psKernelCacheMix
          (psKernelCacheMix 26 (childHint fn)) (childHint arg)
    | .lam _ ty body _ =>
        psKernelCacheMix
          (psKernelCacheMix 27 (childHint ty)) (childHint body)
    | .forallE _ ty body _ =>
        psKernelCacheMix
          (psKernelCacheMix 28 (childHint ty)) (childHint body)
    | .letE _ ty value body nondep =>
        psKernelCacheMix
          (psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix 29 (childHint ty))
              (childHint value))
            (childHint body))
          (if nondep then 1 else 0)
    | .mdata md body =>
        psKernelCacheMix (psKernelCacheMix 31 md) (childHint body)
    | .proj _ index body =>
        psKernelCacheMix (psKernelCacheMix 32 index) (childHint body)
    | other =>
        psKernelC0MemoShapeHash 1 other
  psKernelCacheMix shape offset

/-- Pure source remains the original three-layer shape hash;
    native code uses only a shallow, operation-local index hint. -/
@[implemented_by psKernelC0InstOneMemoHashNative]
private def psKernelC0InstOneMemoHash
    (expr : PsKernelExpr) (offset : Nat) : Nat :=
  psKernelCacheMix (psKernelC0MemoShapeHash 3 expr) offset

private def psKernelC0InstOneMemoFind
    {replacement : PsKernelExpr}
    (expr : PsKernelExpr) (offset : Nat) :
    List (PsKernelC0InstOneMemoEntry replacement) →
      Option (PsKernelC0InstOneExact replacement expr offset)
  | [] => none
  | entry :: rest =>
      -- The binder offset is an integral part of the certified key.
      -- Reject a different offset BEFORE running potentially expensive
      -- exact structural equality on a collision-heavy syntax bucket.
      if ho : entry.offset = offset then
        match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
        | .isTrue he =>
            some (by
              cases he
              cases ho
              exact entry.exact)
        | .isFalse _ =>
            psKernelC0InstOneMemoFind expr offset rest
      else
        psKernelC0InstOneMemoFind expr offset rest

/-- Unlike BVars, these atom forms cannot be substituted by the
single-binder instantiator. Their original changed-flag result is exactly
(expr, false); memo lookup/insertion is needless work, even for large
name/level-bearing constants. -/
private def psKernelC0InstOneMemoCheapLeaf : PsKernelExpr → Bool
  | .fvar _ => true
  | .mvar _ => true
  | .sort _ => true
  | .const _ _ => true
  | .lit _ => true
  | _ => false

private def psKernelC0InstOneMemoLookup
    {replacement : PsKernelExpr}
    (expr : PsKernelExpr) (offset : Nat)
    (memo : PsKernelC0InstOneMemo replacement) :
    Option (PsKernelC0InstOneExact replacement expr offset) :=
  -- Proof-carrying *whole-subtree* fast path: no loose variables can be
  -- substituted or shifted in this expression at this exact binder offset.
  -- Unlike a hash hint, this decision carries a Lean theorem establishing
  -- the exact unchanged expression AND original changed flag.
  if h : expr.psKernelC0LooseBVarBound ≤ offset then
    some ⟨(expr, false), (c0NoSubstitutionFromBound expr replacement offset h).symm⟩
  else if psKernelC0InstOneMemoCheapLeaf expr then
    none
  else
    psKernelC0InstOneMemoFind expr offset
      (psKernelC0TrieBucket psKernelC0IndexDepth memo
        (psKernelC0InstOneMemoHash expr offset))

private def psKernelC0InstOneMemoInsert
    {replacement : PsKernelExpr}
    {expr : PsKernelExpr} {offset : Nat}
    (memo : PsKernelC0InstOneMemo replacement)
    (checked : PsKernelC0InstOneExact replacement expr offset) :
    PsKernelC0InstOneMemo replacement :=
  let hash := psKernelC0InstOneMemoHash expr offset
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ({ expr := expr, offset := offset, exact := checked } :: bucket)

private def psKernelC0InstOneMemoStore
    {replacement expr : PsKernelExpr} {offset : Nat}
    (memo : PsKernelC0InstOneMemo replacement)
    (checked : PsKernelC0InstOneExact replacement expr offset) :
    PsKernelC0InstOneExact replacement expr offset ×
      PsKernelC0InstOneMemo replacement :=
  (checked, psKernelC0InstOneMemoInsert memo checked)

/-- Bottom-up memoization whose proof is compositional over exact source
child results and exact source-state-free binder substitutions. -/
def psKernelC0InstOneMemoGo
    (replacement : PsKernelExpr) :
    (expr : PsKernelExpr) →
    (offset : Nat) →
    PsKernelC0InstOneMemo replacement →
      PsKernelC0InstOneExact replacement expr offset ×
        PsKernelC0InstOneMemo replacement
  | expr, offset, memo =>
      match psKernelC0InstOneMemoLookup expr offset memo with
      | some existing => (existing, memo)
      | none =>
          match expr with
          | .app fn arg =>
              let (f, m1) := psKernelC0InstOneMemoGo replacement fn offset memo
              let (a, m2) := psKernelC0InstOneMemoGo replacement arg offset m1
              let result :=
                if f.value.2 then (.app f.value.1 a.value.1, true)
                else if a.value.2 then (.app f.value.1 a.value.1, true)
                else (.app fn arg, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.app fn arg) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← f.source, ← a.source]
              psKernelC0InstOneMemoStore m2 ⟨result, equality⟩
          | .lam name ty body info =>
              let (t, m1) := psKernelC0InstOneMemoGo replacement ty offset memo
              let (b, m2) := psKernelC0InstOneMemoGo replacement body (offset + 1) m1
              let result :=
                if t.value.2 then (.lam name t.value.1 b.value.1 info, true)
                else if b.value.2 then (.lam name t.value.1 b.value.1 info, true)
                else (.lam name ty body info, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.lam name ty body info) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← t.source, ← b.source]
              psKernelC0InstOneMemoStore m2 ⟨result, equality⟩
          | .forallE name ty body info =>
              let (t, m1) := psKernelC0InstOneMemoGo replacement ty offset memo
              let (b, m2) := psKernelC0InstOneMemoGo replacement body (offset + 1) m1
              let result :=
                if t.value.2 then (.forallE name t.value.1 b.value.1 info, true)
                else if b.value.2 then (.forallE name t.value.1 b.value.1 info, true)
                else (.forallE name ty body info, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.forallE name ty body info) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← t.source, ← b.source]
              psKernelC0InstOneMemoStore m2 ⟨result, equality⟩
          | .letE name ty value body nondep =>
              let (t, m1) := psKernelC0InstOneMemoGo replacement ty offset memo
              let (v, m2) := psKernelC0InstOneMemoGo replacement value offset m1
              let (b, m3) := psKernelC0InstOneMemoGo replacement body (offset + 1) m2
              let result :=
                if t.value.2 then (.letE name t.value.1 v.value.1 b.value.1 nondep, true)
                else if v.value.2 then (.letE name t.value.1 v.value.1 b.value.1 nondep, true)
                else if b.value.2 then (.letE name t.value.1 v.value.1 b.value.1 nondep, true)
                else (.letE name ty value body nondep, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.letE name ty value body nondep) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← t.source, ← v.source, ← b.source]
              psKernelC0InstOneMemoStore m3 ⟨result, equality⟩
          | .mdata md body =>
              let (b, m1) := psKernelC0InstOneMemoGo replacement body offset memo
              let result := if b.value.2 then (.mdata md b.value.1, true)
                            else (.mdata md body, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.mdata md body) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← b.source]
              psKernelC0InstOneMemoStore m1 ⟨result, equality⟩
          | .proj name i body =>
              let (b, m1) := psKernelC0InstOneMemoGo replacement body offset memo
              let result := if b.value.2 then (.proj name i b.value.1, true)
                            else (.proj name i body, false)
              let equality :
                  result = psKernelC0ExprInstantiateOneChanged
                    (.proj name i body) replacement offset := by
                simp only [psKernelC0ExprInstantiateOneChanged]
                rw [← b.source]
              psKernelC0InstOneMemoStore m1 ⟨result, equality⟩
          | .bvar n =>
              -- Bound variables can select/lift the replacement; keep exact
              -- per-offset memoization and dependent proof transport.
              let value := psKernelC0ExprInstantiateOneChanged (.bvar n)
                replacement offset
              psKernelC0InstOneMemoStore memo ⟨value, rfl⟩
          | other =>
              -- The remaining atom constructors cannot be substituted.
              -- Return source's exact changed flag without touching memo.
              let value := psKernelC0ExprInstantiateOneChanged other
                replacement offset
              (⟨value, rfl⟩, memo)

/-- Original source's *changed-flag* algorithm, memoized precisely. -/
def psKernelC0InstOneMemoizedChanged
    (expr replacement : PsKernelExpr) (offset : Nat) :
    PsKernelExpr × Bool :=
  (psKernelC0InstOneMemoGo replacement expr offset .empty).1.value

/-- All-input verified equality to the complete original substitution
judgment, including the changed flag and capture-safe binder offsets. -/
theorem psKernelC0InstOneMemoizedChanged_source
    (expr replacement : PsKernelExpr) (offset : Nat) :
    psKernelC0InstOneMemoizedChanged expr replacement offset =
      psKernelC0ExprInstantiateOneChanged expr replacement offset :=
  (psKernelC0InstOneMemoGo replacement expr offset .empty).1.source


/-- Exact public single-variable instantiation, retaining the existing
binder-headed loose-variable fast path and every capture-avoidance decision.
The only substituted computation is the source-proved changed-flag worker. -/
def psKernelC0MemoizedInstantiate1All
    (expr replacement : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | .lam _ _ _ _
  | .forallE _ _ _ _
  | .letE _ _ _ _ _ =>
      if psKernelExprHasLooseBVar expr then
        (psKernelC0InstOneMemoizedChanged expr replacement 0).1
      else expr
  | _ =>
      (psKernelC0InstOneMemoizedChanged expr replacement 0).1

/-- Full behavioral equivalence for the public beta/zeta instantiation API,
including all original binder-headed shortcut decisions. -/
theorem psKernelC0MemoizedInstantiate1All_source
    (expr replacement : PsKernelExpr) :
    psKernelC0MemoizedInstantiate1All expr replacement =
      psKernelExprInstantiate1 expr replacement := by
  cases expr <;>
    simp only [psKernelC0MemoizedInstantiate1All,
      psKernelExprInstantiate1,
      psKernelC0InstOneMemoizedChanged_source]


/-!
The exact full DAG memo has a large per-node indexing cost on ordinary
linear application spines, which the original source's one-pass worker
already handles efficiently. Native performance A/B (CI 38895203082)
found a 20× regression from choosing DAG memoization indiscriminately.

This selector inspects only a bounded left application spine, or a finite
binder prefix. A negative selection performs the ORIGINAL specialized
single-binder algorithm, not a false rejection. Positive selection
reuses the existing proof-certified DAG memo. This decision affects only
runtime work, never the source semantic result.
-/

/-- Detect a complex argument on at most eight outer application nodes.
A single linear spine with atomic arguments is deliberately cheap. -/
def psKernelC0InstMemoComplexApp : Nat → PsKernelExpr → Bool
  | 0, _ => false
  | remaining + 1, .app fn arg =>
      match arg with
      | .app _ _ | .lam _ _ _ _ | .forallE _ _ _ _ | .letE _ _ _ _ _ =>
          true
      | _ => psKernelC0InstMemoComplexApp remaining fn
  | _, _ => false

/-- A long dependent binder chain is a useful candidate for per-subtree
memoization; the check inspects at most twelve binder heads. -/
def psKernelC0InstMemoBinderPrefix : Nat → PsKernelExpr → Bool
  | 0, _ => true
  | remaining + 1, .lam _ _ body _ =>
      psKernelC0InstMemoBinderPrefix remaining body
  | remaining + 1, .forallE _ _ body _ =>
      psKernelC0InstMemoBinderPrefix remaining body
  | _, _ => false

/-- Read-only, bounded shape selector. It never establishes equality, typing,
capture safety, or an admission outcome. -/
def psKernelC0InstMemoWorthwhile (expr : PsKernelExpr) : Bool :=
  psKernelC0InstMemoComplexApp 8 expr ||
    psKernelC0InstMemoBinderPrefix 12 expr

/-- Complete original specialized source algorithm, maintained as an
independent executable oracle and the cheap path for ordinary terms. -/
def psKernelC0DirectInstantiate1
    (expr replacement : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | .lam _ _ _ _ | .forallE _ _ _ _ | .letE _ _ _ _ _ =>
      if psKernelExprHasLooseBVar expr then
        (psKernelC0ExprInstantiateOneChanged expr replacement 0).1
      else expr
  | _ => (psKernelC0ExprInstantiateOneChanged expr replacement 0).1

theorem psKernelC0DirectInstantiate1_source
    (expr replacement : PsKernelExpr) :
    psKernelC0DirectInstantiate1 expr replacement =
      psKernelExprInstantiate1 expr replacement := by
  rfl

/-- Select DAG memo ONLY for suitable source shapes; ordinary linear spines
keep the original source's one-pass behavior. Both branches have independent
Lean proofs of FULL equality to psKernelExprInstantiate1. -/
def psKernelC0MemoizedInstantiate1
    (expr replacement : PsKernelExpr) : PsKernelExpr :=
  if psKernelC0InstMemoWorthwhile expr then
    psKernelC0MemoizedInstantiate1All expr replacement
  else
    psKernelC0DirectInstantiate1 expr replacement

theorem psKernelC0MemoizedInstantiate1_source
    (expr replacement : PsKernelExpr) :
    psKernelC0MemoizedInstantiate1 expr replacement =
      psKernelExprInstantiate1 expr replacement := by
  unfold psKernelC0MemoizedInstantiate1
  split
  · exact psKernelC0MemoizedInstantiate1All_source expr replacement
  · exact psKernelC0DirectInstantiate1_source expr replacement

/-- Source-exact native compiler replacement. Lean checks the full
function equality, so codegen may accelerate every consumer importing this
module without changing the formal meaning or accepting unchecked terms. -/
@[csimp] theorem psKernelExprInstantiate1_csimp :
    @psKernelExprInstantiate1 = @psKernelC0MemoizedInstantiate1 := by
  funext expr replacement
  exact (psKernelC0MemoizedInstantiate1_source expr replacement).symm
