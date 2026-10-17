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
