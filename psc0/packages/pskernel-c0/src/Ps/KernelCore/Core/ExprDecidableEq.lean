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
termination_by sizeOf left
decreasing_by simp_wf
