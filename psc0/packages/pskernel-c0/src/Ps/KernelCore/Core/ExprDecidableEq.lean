import Ps.KernelCore.Core.Expr

/-!
Single native source of proof-constrained, full structural DecidableEq
instances for kernel expression syntax.

The original certified-store transport and independently certified
hash/instantiation memo all need the SAME constructor equality witnesses.
Defining them in two modules makes it impossible to combine their
interfaces in one verified checker: the Lean environment rejects duplicate
declarations.

The constructors, representation, source semantics and generated decision
procedures are unchanged. Pointer equality can be used only through Lean's
proof-producing withPtrEqDecEq, never as an unchecked equality judgment.
-/

deriving instance DecidableEq for PsKernelName
deriving instance DecidableEq for PsKernelLevel
deriving instance DecidableEq for PsKernelBinderInfo
deriving instance DecidableEq for PsKernelLiteral
deriving instance DecidableEq for PsKernelExpr


/-!
A proof-carrying *deep* pointer shortcut for exact expression equality.

The historical deriving instance descends into each child with structural
DecidableEq. A source DAG such as `app child child` can therefore force
exponentially many repeated equality decisions even when the corresponding
children are the exact SAME runtime object.

This function instead invokes Lean 4.35's proof-constrained
`withPtrEqDecEq` at EVERY recursive expression pair, then uses only
constructor-injectivity proofs and complete comparisons of every field.
Pointer inequality NEVER means term inequality, and pointer equality cannot
produce an unchecked proposition: the native implementation's shortcut is
proof-constrained by `withPtrEqDecEq`. No source checker rule is changed.
-/

/-- Lift a decidable equivalence to an actual proof of the target proposition;
    there is no Boolean-equality or unchecked hash assumption. -/
private def psKernelC0DecidableViaIff
    {p q : Prop} (equivalence : p ↔ q) (d : Decidable q) :
    Decidable p :=
  match d with
  | .isTrue h => .isTrue (equivalence.mpr h)
  | .isFalse h => .isFalse (fun proof => h (equivalence.mp proof))

/-- Source-exact structural equality, with pointer-elimination applied
    recursively rather than only at the root of a large shared DAG. -/
def psKernelC0DeepPtrDecEq :
    (left right : PsKernelExpr) → Decidable (left = right)
  | .app lf la, .app rf ra =>
      withPtrEqDecEq (PsKernelExpr.app lf la) (PsKernelExpr.app rf ra) (fun _ =>
        letI : Decidable (lf = rf) := psKernelC0DeepPtrDecEq lf rf
        letI : Decidable (la = ra) := psKernelC0DeepPtrDecEq la ra
        psKernelC0DecidableViaIff
          (show PsKernelExpr.app lf la = PsKernelExpr.app rf ra ↔
            lf = rf ∧ la = ra by simp)
          (inferInstance : Decidable (lf = rf ∧ la = ra)))
  | .lam ln lt lb li, .lam rn rt rb ri =>
      withPtrEqDecEq (PsKernelExpr.lam ln lt lb li) (PsKernelExpr.lam rn rt rb ri) (fun _ =>
        letI : Decidable (lt = rt) := psKernelC0DeepPtrDecEq lt rt
        letI : Decidable (lb = rb) := psKernelC0DeepPtrDecEq lb rb
        psKernelC0DecidableViaIff
          (show PsKernelExpr.lam ln lt lb li = PsKernelExpr.lam rn rt rb ri ↔
            ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri by simp)
          (inferInstance :
            Decidable (ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri)))
  | .forallE ln lt lb li, .forallE rn rt rb ri =>
      withPtrEqDecEq (PsKernelExpr.forallE ln lt lb li) (PsKernelExpr.forallE rn rt rb ri) (fun _ =>
        letI : Decidable (lt = rt) := psKernelC0DeepPtrDecEq lt rt
        letI : Decidable (lb = rb) := psKernelC0DeepPtrDecEq lb rb
        psKernelC0DecidableViaIff
          (show PsKernelExpr.forallE ln lt lb li =
            PsKernelExpr.forallE rn rt rb ri ↔
            ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri by simp)
          (inferInstance :
            Decidable (ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri)))
  | .letE ln lt lv lb ld, .letE rn rt rv rb rd =>
      withPtrEqDecEq (PsKernelExpr.letE ln lt lv lb ld) (PsKernelExpr.letE rn rt rv rb rd) (fun _ =>
        letI : Decidable (lt = rt) := psKernelC0DeepPtrDecEq lt rt
        letI : Decidable (lv = rv) := psKernelC0DeepPtrDecEq lv rv
        letI : Decidable (lb = rb) := psKernelC0DeepPtrDecEq lb rb
        psKernelC0DecidableViaIff
          (show PsKernelExpr.letE ln lt lv lb ld =
            PsKernelExpr.letE rn rt rv rb rd ↔
            ln = rn ∧ lt = rt ∧ lv = rv ∧ lb = rb ∧ ld = rd by simp)
          (inferInstance :
            Decidable (ln = rn ∧ lt = rt ∧ lv = rv ∧ lb = rb ∧ ld = rd)))
  | .mdata lm le, .mdata rm re =>
      withPtrEqDecEq (PsKernelExpr.mdata lm le) (PsKernelExpr.mdata rm re) (fun _ =>
        letI : Decidable (le = re) := psKernelC0DeepPtrDecEq le re
        psKernelC0DecidableViaIff
          (show PsKernelExpr.mdata lm le = PsKernelExpr.mdata rm re ↔
            lm = rm ∧ le = re by simp)
          (inferInstance : Decidable (lm = rm ∧ le = re)))
  | .proj ln li le, .proj rn ri re =>
      withPtrEqDecEq (PsKernelExpr.proj ln li le) (PsKernelExpr.proj rn ri re) (fun _ =>
        letI : Decidable (le = re) := psKernelC0DeepPtrDecEq le re
        psKernelC0DecidableViaIff
          (show PsKernelExpr.proj ln li le = PsKernelExpr.proj rn ri re ↔
            ln = rn ∧ li = ri ∧ le = re by simp)
          (inferInstance : Decidable (ln = rn ∧ li = ri ∧ le = re)))
  | left, right =>
      -- Leaves and mixed constructor tags are decided by the pinned source
      -- instance; those contain no recursive PsKernelExpr child comparisons.
      withPtrEqDecEq left right (fun _ => inferInstance)



/-!
Exact **pair-memoized** DecidableEq for independently shared expression DAGs.

A root-only pointer shortcut is not enough: the two operands may be distinct
heap objects while each operand shares its own child twice. Comparing those
two shared children again without a pair memo creates 2^n recursive
comparisons. The memo below reuses a result ONLY after independent,
proof-producing equality checks of BOTH original source operands.

Its native pointer address is a bucket hint, not a semantic equality test.
False hints merely re-run full checking; collisions cannot grant equality.
Every entry stores `Decidable (lhs = rhs)`, so no cache can manufacture a
positive or negative proof from a hash. The portable source function is
ordinary constructor tagging, requiring no unsafe extension for PS0.
-/

private unsafe def psKernelC0PairIndexHintNative
    (expr : PsKernelExpr) : Nat :=
  (ptrAddrUnsafe expr).toNat / 16

@[implemented_by psKernelC0PairIndexHintNative]
private def psKernelC0PairIndexHint : PsKernelExpr → Nat
  | .bvar _ => 1
  | .fvar _ => 2
  | .mvar _ => 3
  | .sort _ => 4
  | .const _ _ => 5
  | .app _ _ => 6
  | .lam _ _ _ _ => 7
  | .forallE _ _ _ _ => 8
  | .letE _ _ _ _ _ => 9
  | .lit _ => 10
  | .mdata _ _ => 11
  | .proj _ _ _ => 12

private structure PsKernelC0ExactPairEqEntry where
  lhs : PsKernelExpr
  rhs : PsKernelExpr
  lhsHint : Nat
  rhsHint : Nat
  exact : Decidable (lhs = rhs)

private abbrev PsKernelC0ExactPairEqMemo :=
  List PsKernelC0ExactPairEqEntry

private def psKernelC0ExactPairEqFind
    (lhs rhs : PsKernelExpr)
    (hintL hintR : Nat) :
    PsKernelC0ExactPairEqMemo → Option (Decidable (lhs = rhs))
  | [] => none
  | entry :: tail =>
      if entry.lhsHint == hintL && entry.rhsHint == hintR then
        match psKernelC0DeepPtrDecEq lhs entry.lhs with
        | .isTrue hLeft =>
            match psKernelC0DeepPtrDecEq rhs entry.rhs with
            | .isTrue hRight =>
                some (by
                  cases hLeft
                  cases hRight
                  exact entry.exact)
            | .isFalse _ =>
                psKernelC0ExactPairEqFind lhs rhs hintL hintR tail
        | .isFalse _ =>
            psKernelC0ExactPairEqFind lhs rhs hintL hintR tail
      else psKernelC0ExactPairEqFind lhs rhs hintL hintR tail

private def psKernelC0ExactPairEqStore
    {lhs rhs : PsKernelExpr}
    (value : Decidable (lhs = rhs))
    (memo : PsKernelC0ExactPairEqMemo) :
    Decidable (lhs = rhs) × PsKernelC0ExactPairEqMemo :=
  let next : PsKernelC0ExactPairEqEntry := {
    lhs := lhs
    rhs := rhs
    lhsHint := psKernelC0PairIndexHint lhs
    rhsHint := psKernelC0PairIndexHint rhs
    exact := value
  }
  (value, next :: memo)

/-- Pair-cached exact dependent Eq/Not-Eq evidence. Recursive calls are
    structural on the left expression; every memo hit transports an actual
    decision only along proofs of BOTH source-operand equalities. -/
def psKernelC0ExactPairEqGo :
    (lhs rhs : PsKernelExpr) →
    PsKernelC0ExactPairEqMemo →
    Decidable (lhs = rhs) × PsKernelC0ExactPairEqMemo
  | .app lf la, .app rf ra, memo =>
      let lhs := PsKernelExpr.app lf la
      let rhs := PsKernelExpr.app rf ra
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (f, m1) := psKernelC0ExactPairEqGo lf rf memo
          let (a, m2) := psKernelC0ExactPairEqGo la ra m1
          letI : Decidable (lf = rf) := f
          letI : Decidable (la = ra) := a
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔ lf = rf ∧ la = ra by
                simp [lhs, rhs])
              (inferInstance : Decidable (lf = rf ∧ la = ra))
          psKernelC0ExactPairEqStore decided m2
  | .lam ln lt lb li, .lam rn rt rb ri, memo =>
      let lhs := PsKernelExpr.lam ln lt lb li
      let rhs := PsKernelExpr.lam rn rt rb ri
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0ExactPairEqGo lt rt memo
          let (b, m2) := psKernelC0ExactPairEqGo lb rb m1
          letI : Decidable (lt = rt) := t
          letI : Decidable (lb = rb) := b
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔
                ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri by simp [lhs, rhs])
              (inferInstance : Decidable
                (ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri))
          psKernelC0ExactPairEqStore decided m2
  | .forallE ln lt lb li, .forallE rn rt rb ri, memo =>
      let lhs := PsKernelExpr.forallE ln lt lb li
      let rhs := PsKernelExpr.forallE rn rt rb ri
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0ExactPairEqGo lt rt memo
          let (b, m2) := psKernelC0ExactPairEqGo lb rb m1
          letI : Decidable (lt = rt) := t
          letI : Decidable (lb = rb) := b
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔
                ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri by simp [lhs, rhs])
              (inferInstance : Decidable
                (ln = rn ∧ lt = rt ∧ lb = rb ∧ li = ri))
          psKernelC0ExactPairEqStore decided m2
  | .letE ln lt lv lb ld, .letE rn rt rv rb rd, memo =>
      let lhs := PsKernelExpr.letE ln lt lv lb ld
      let rhs := PsKernelExpr.letE rn rt rv rb rd
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0ExactPairEqGo lt rt memo
          let (v, m2) := psKernelC0ExactPairEqGo lv rv m1
          let (b, m3) := psKernelC0ExactPairEqGo lb rb m2
          letI : Decidable (lt = rt) := t
          letI : Decidable (lv = rv) := v
          letI : Decidable (lb = rb) := b
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔
                ln = rn ∧ lt = rt ∧ lv = rv ∧ lb = rb ∧ ld = rd by
                simp [lhs, rhs])
              (inferInstance : Decidable
                (ln = rn ∧ lt = rt ∧ lv = rv ∧ lb = rb ∧ ld = rd))
          psKernelC0ExactPairEqStore decided m3
  | .mdata lm le, .mdata rm re, memo =>
      let lhs := PsKernelExpr.mdata lm le
      let rhs := PsKernelExpr.mdata rm re
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (e, m1) := psKernelC0ExactPairEqGo le re memo
          letI : Decidable (le = re) := e
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔ lm = rm ∧ le = re by simp [lhs, rhs])
              (inferInstance : Decidable (lm = rm ∧ le = re))
          psKernelC0ExactPairEqStore decided m1
  | .proj ln li le, .proj rn ri re, memo =>
      let lhs := PsKernelExpr.proj ln li le
      let rhs := PsKernelExpr.proj rn ri re
      match psKernelC0ExactPairEqFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (e, m1) := psKernelC0ExactPairEqGo le re memo
          letI : Decidable (le = re) := e
          let decided : Decidable (lhs = rhs) :=
            psKernelC0DecidableViaIff
              (show lhs = rhs ↔ ln = rn ∧ li = ri ∧ le = re by
                simp [lhs, rhs])
              (inferInstance : Decidable (ln = rn ∧ li = ri ∧ le = re))
          psKernelC0ExactPairEqStore decided m1
  | lhs, rhs, memo =>
      (psKernelC0DeepPtrDecEq lhs rhs, memo)

/-- A fully proof-producing decision for arbitrary exact expressions.
    Source semantics do not depend on pointer address or memo hints. -/
def psKernelC0ExactPairEq (lhs rhs : PsKernelExpr) : Decidable (lhs = rhs) :=
  (psKernelC0ExactPairEqGo lhs rhs []).1

/-!
## Exact legacy-semantic DAG equality

The historical Boolean comparator is NOT structural PsKernelExpr equality:
it intentionally ignores lambda/Pi binder names and BinderInfo, and let
binder names. Full DecidableEq is therefore not a correct replacement.

For a given pair of ORIGINAL expression objects (retained with Lean's
as-patterns rather than freshly rebuilt constructor nodes), every memo entry contains a
dependent all-input proof that its Boolean result is exactly the old
psKernelC0FullPairedExprEq. The memo stores only source-syntax facts, no
DefEq decision, type, proof, environment or local-context assumption.

Native pointer identity merely selects a candidate memo entry; both
operands MUST still be independently checked by typed structural equality
before transporting the Boolean proof. Different identities can miss
and cause recomputation, not a false semantic decision. A hash collision
can only trigger additional exact equality work, not admission.
-/

private structure PsKernelC0LegacyPairProof
    (left right : PsKernelExpr) where
  value : Bool
  source : value = psKernelC0FullPairedExprEq left right

private structure PsKernelC0LegacyPairEntry where
  left : PsKernelExpr
  right : PsKernelExpr
  leftHint : Nat
  rightHint : Nat
  certified : PsKernelC0LegacyPairProof left right

private abbrev PsKernelC0LegacyPairMemo := List PsKernelC0LegacyPairEntry

private def psKernelC0LegacyPairFind
    (left right : PsKernelExpr) (leftHint rightHint : Nat) :
    PsKernelC0LegacyPairMemo →
      Option (PsKernelC0LegacyPairProof left right)
  | [] => none
  | entry :: tail =>
      if entry.leftHint == leftHint && entry.rightHint == rightHint then
        match psKernelC0DeepPtrDecEq left entry.left with
        | .isTrue hl =>
            match psKernelC0DeepPtrDecEq right entry.right with
            | .isTrue hr =>
                some (by
                  cases hl
                  cases hr
                  exact entry.certified)
            | .isFalse _ =>
                psKernelC0LegacyPairFind left right leftHint rightHint tail
        | .isFalse _ =>
            psKernelC0LegacyPairFind left right leftHint rightHint tail
      else
        psKernelC0LegacyPairFind left right leftHint rightHint tail

private def psKernelC0LegacyPairStore
    {left right : PsKernelExpr}
    (certified : PsKernelC0LegacyPairProof left right)
    (memo : PsKernelC0LegacyPairMemo) :
    PsKernelC0LegacyPairProof left right × PsKernelC0LegacyPairMemo :=
  (certified, {
    left := left
    right := right
    leftHint := psKernelC0PairIndexHint left
    rightHint := psKernelC0PairIndexHint right
    certified := certified
  } :: memo)

/-- Exact old semantics on each nested shared pair, with memo hits
    proof-checked for both original operand identities. -/
def psKernelC0LegacyPairGo :
    (left right : PsKernelExpr) →
    PsKernelC0LegacyPairMemo →
      PsKernelC0LegacyPairProof left right × PsKernelC0LegacyPairMemo
  | (.app lf la), (.app rf ra), memo =>
       let lhs := PsKernelExpr.app lf la
       let rhs := PsKernelExpr.app rf ra
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (f, m1) := psKernelC0LegacyPairGo lf rf memo
          if hf : f.value = true then
            let (a, m2) := psKernelC0LegacyPairGo la ra m1
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨a.value, by
                change a.value =
                  (psKernelC0FullPairedExprEq lf rf &&
                   psKernelC0FullPairedExprEq la ra)
                rw [← f.source, ← a.source]
                simp [hf]⟩
            psKernelC0LegacyPairStore proof m2
          else
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨false, by
                change false =
                  (psKernelC0FullPairedExprEq lf rf &&
                   psKernelC0FullPairedExprEq la ra)
                rw [← f.source]
                simp [hf]⟩
            psKernelC0LegacyPairStore proof m1
  | (.lam ln lt lb li), (.lam rn rt rb ri), memo =>
       let lhs := PsKernelExpr.lam ln lt lb li
       let rhs := PsKernelExpr.lam rn rt rb ri
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0LegacyPairGo lt rt memo
          if ht : t.value = true then
            let (b, m2) := psKernelC0LegacyPairGo lb rb m1
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨b.value, by
                change b.value =
                  (psKernelC0FullPairedExprEq lt rt &&
                   psKernelC0FullPairedExprEq lb rb)
                rw [← t.source, ← b.source]
                simp [ht]⟩
            psKernelC0LegacyPairStore proof m2
          else
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨false, by
                change false =
                  (psKernelC0FullPairedExprEq lt rt &&
                   psKernelC0FullPairedExprEq lb rb)
                rw [← t.source]
                simp [ht]⟩
            psKernelC0LegacyPairStore proof m1
  | (.forallE ln lt lb li), (.forallE rn rt rb ri), memo =>
       let lhs := PsKernelExpr.forallE ln lt lb li
       let rhs := PsKernelExpr.forallE rn rt rb ri
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0LegacyPairGo lt rt memo
          if ht : t.value = true then
            let (b, m2) := psKernelC0LegacyPairGo lb rb m1
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨b.value, by
                change b.value =
                  (psKernelC0FullPairedExprEq lt rt &&
                   psKernelC0FullPairedExprEq lb rb)
                rw [← t.source, ← b.source]
                simp [ht]⟩
            psKernelC0LegacyPairStore proof m2
          else
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨false, by
                change false =
                  (psKernelC0FullPairedExprEq lt rt &&
                   psKernelC0FullPairedExprEq lb rb)
                rw [← t.source]
                simp [ht]⟩
            psKernelC0LegacyPairStore proof m1
  | (.letE ln lt lv lb ld), (.letE rn rt rv rb rd), memo =>
       let lhs := PsKernelExpr.letE ln lt lv lb ld
       let rhs := PsKernelExpr.letE rn rt rv rb rd
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (t, m1) := psKernelC0LegacyPairGo lt rt memo
          if ht : t.value = true then
            let (v, m2) := psKernelC0LegacyPairGo lv rv m1
            if hv : v.value = true then
              let (b, m3) := psKernelC0LegacyPairGo lb rb m2
              let proof : PsKernelC0LegacyPairProof lhs rhs :=
                ⟨b.value && psKernelBoolEq ld rd, by
                  change (b.value && psKernelBoolEq ld rd) =
                    (psKernelC0FullPairedExprEq lt rt &&
                     psKernelC0FullPairedExprEq lv rv &&
                     psKernelC0FullPairedExprEq lb rb &&
                     psKernelBoolEq ld rd)
                  rw [← t.source, ← v.source, ← b.source]
                  simp [ht, hv]⟩
              psKernelC0LegacyPairStore proof m3
            else
              let proof : PsKernelC0LegacyPairProof lhs rhs :=
                ⟨false, by
                  change false =
                    (psKernelC0FullPairedExprEq lt rt &&
                     psKernelC0FullPairedExprEq lv rv &&
                     psKernelC0FullPairedExprEq lb rb &&
                     psKernelBoolEq ld rd)
                  rw [← t.source, ← v.source]
                  simp [ht, hv]⟩
              psKernelC0LegacyPairStore proof m2
          else
            let proof : PsKernelC0LegacyPairProof lhs rhs :=
              ⟨false, by
                change false =
                  (psKernelC0FullPairedExprEq lt rt &&
                   psKernelC0FullPairedExprEq lv rv &&
                   psKernelC0FullPairedExprEq lb rb &&
                   psKernelBoolEq ld rd)
                rw [← t.source]
                simp [ht]⟩
            psKernelC0LegacyPairStore proof m1
  | (.mdata lm le), (.mdata rm re), memo =>
       let lhs := PsKernelExpr.mdata lm le
       let rhs := PsKernelExpr.mdata rm re
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (e, m1) := psKernelC0LegacyPairGo le re memo
          let proof : PsKernelC0LegacyPairProof lhs rhs :=
            ⟨decide (lm = rm) && e.value, by
              change (decide (lm = rm) && e.value) =
                (decide (lm = rm) && psKernelC0FullPairedExprEq le re)
              rw [e.source]⟩
          psKernelC0LegacyPairStore proof m1
  | (.proj ln li le), (.proj rn ri re), memo =>
       let lhs := PsKernelExpr.proj ln li le
       let rhs := PsKernelExpr.proj rn ri re
      match psKernelC0LegacyPairFind lhs rhs
          (psKernelC0PairIndexHint lhs) (psKernelC0PairIndexHint rhs) memo with
      | some cached => (cached, memo)
      | none =>
          let (e, m1) := psKernelC0LegacyPairGo le re memo
          let proof : PsKernelC0LegacyPairProof lhs rhs :=
            ⟨psKernelNameEq ln rn && decide (li = ri) && e.value, by
              change (psKernelNameEq ln rn && decide (li = ri) && e.value) =
                (psKernelNameEq ln rn && decide (li = ri) &&
                 psKernelC0FullPairedExprEq le re)
              rw [e.source]⟩
          psKernelC0LegacyPairStore proof m1
  | left, right, memo =>
      let proof : PsKernelC0LegacyPairProof left right :=
        ⟨psKernelC0FullPairedExprEq left right, rfl⟩
      (proof, memo)

/-- Source-pure, all-input semantic (binder-name-erasing) DAG equality. -/
def psKernelC0LegacyMemoExprEq
    (left right : PsKernelExpr) : Bool :=
  (psKernelC0LegacyPairGo left right []).1.value

/-- Runtime memo reuse cannot alter the original source comparator for
    any pair, including cases where binders differ only in annotations. -/
theorem psKernelC0LegacyMemoExprEq_source
    (left right : PsKernelExpr) :
    psKernelC0LegacyMemoExprEq left right =
      psKernelExprEqLegacy left right := by
  calc
    psKernelC0LegacyMemoExprEq left right =
        psKernelC0FullPairedExprEq left right :=
      (psKernelC0LegacyPairGo left right []).1.source
    _ = psKernelExprEqLegacy left right :=
      psKernelC0FullPairedExprEq_source left right

/-- Exactly one source-equal compiler optimization for the historic
    curried semantic expression equality; the source is unchanged. -/
@[csimp] theorem psKernelExprEqLegacy_compiler_eq_certifiedMemo :
    @psKernelExprEqLegacy = @psKernelC0LegacyMemoExprEq := by
  funext left right
  exact (psKernelC0LegacyMemoExprEq_source left right).symm

/-- Source-exact top-level semantic comparator. The historical checker
    uses psKernelExprEq at the DefEq root; its recursive children call the
    older curried comparator. Explicitly route only those children through
    the previously certified operation-local semantic pair memo instead of
    depending on delayed compiler substitution in Core.Expr. Binder display
    names and annotations remain deliberately ignored, as before. -/
def psKernelC0MemoizedExprEq : PsKernelExpr → PsKernelExpr → Bool
  | .app af aa, .app bf ba =>
      psKernelC0LegacyMemoExprEq af bf &&
      psKernelC0LegacyMemoExprEq aa ba
  | .lam _ aty ab _, .lam _ bty bb _ =>
      psKernelC0LegacyMemoExprEq aty bty &&
      psKernelC0LegacyMemoExprEq ab bb
  | .forallE _ aty ab _, .forallE _ bty bb _ =>
      psKernelC0LegacyMemoExprEq aty bty &&
      psKernelC0LegacyMemoExprEq ab bb
  | .letE _ aty av ab an, .letE _ bty bv bb bn =>
      psKernelC0LegacyMemoExprEq aty bty &&
      psKernelC0LegacyMemoExprEq av bv &&
      psKernelC0LegacyMemoExprEq ab bb &&
      psKernelBoolEq an bn
  | .mdata am ab, .mdata bm bb =>
      Nat.beq am bm && psKernelC0LegacyMemoExprEq ab bb
  | .proj an ai ab, .proj bn bi bb =>
      psKernelNameEq an bn && Nat.beq ai bi &&
      psKernelC0LegacyMemoExprEq ab bb
  | left, right => psKernelExprEq left right

/-- Every top-level root comparison exactly matches the original checker
    Boolean on ALL inputs. This does not infer type equality or bypass any
    reduction/resource checks. -/
theorem psKernelC0MemoizedExprEq_source
    (left right : PsKernelExpr) :
    psKernelC0MemoizedExprEq left right = psKernelExprEq left right := by
  cases left <;> cases right <;>
    simp [psKernelC0MemoizedExprEq, psKernelExprEq,
      psKernelC0LegacyMemoExprEq_source]
