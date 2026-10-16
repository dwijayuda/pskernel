import Ps.KernelCore.Runtime.Acceleration.CertifiedHashMemo
import Ps.KernelCore.Core.Substitution.Instantiate

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
      match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
      | .isTrue he =>
          if ho : entry.offset = offset then
            some (by
              cases he
              cases ho
              exact entry.exact)
          else
            psKernelC0InstOneMemoFind expr offset rest
      | .isFalse _ =>
          psKernelC0InstOneMemoFind expr offset rest

private def psKernelC0InstOneMemoLookup
    {replacement : PsKernelExpr}
    (expr : PsKernelExpr) (offset : Nat)
    (memo : PsKernelC0InstOneMemo replacement) :
    Option (PsKernelC0InstOneExact replacement expr offset) :=
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
                rfl
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
                rfl
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
                rfl
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
                rfl
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
                rfl
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
                rfl
              psKernelC0InstOneMemoStore m1 ⟨result, equality⟩
          | other =>
              let value := psKernelC0ExprInstantiateOneChanged other replacement offset
              psKernelC0InstOneMemoStore memo ⟨value, rfl⟩

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
