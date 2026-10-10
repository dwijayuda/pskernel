import Ps.KernelCore.Core.AnnotatedSpines
import Ps.KernelCore.Metatheory.SemanticAnnotationCoherence
import Ps.KernelCore.Metatheory.SemanticErasure
import Ps.KernelCore.Core.Substitution.Beta

/-!
Exact correspondence with the production simultaneous substitution, reversed
binder arguments, application rebuilding and fuel-bounded spine exposure.
Coherence transport retains the comparator's selected binder regimes. These
syntax results require no typing/model premise; they do not license beta
reduction without the semantic argument-domain obligations.
-/
namespace PsKernelSemantics.AnnotatedExpr

private theorem erase_lookup (xs : List AnnotatedExpr) (i : Nat) :
    psKernelExprListGet (xs.map erase) i = (xs[i]?).map erase := by
  induction xs generalizing i with
  | nil => simp [psKernelExprListGet]
  | cons a xs ih => cases i <;> simp [psKernelExprListGet, ih]

private theorem erase_length (xs : List AnnotatedExpr) :
    psKernelExprListLength (xs.map erase) = xs.length := by
  induction xs <;> simp_all [psKernelExprListLength]

private theorem native_many_unchanged (e : PsKernelExpr) (start offset : Nat)
    (xs : List PsKernelExpr) :
    (psKernelExprInstantiateAtChanged e start xs offset).2 = false →
      (psKernelExprInstantiateAtChanged e start xs offset).1 = e := by
  cases e <;> simp only [psKernelExprInstantiateAtChanged]
  all_goals repeat' first | (solve | simp_all [psKernelExprListIsEmpty]) | split

theorem instManyAt_nil (e : AnnotatedExpr) (start offset : Nat) :
    instManyAt e start [] offset = e := by
  induction e generalizing offset <;> simp_all [instManyAt]

theorem erase_instManyAt (e : AnnotatedExpr) (start : Nat)
    (xs : List AnnotatedExpr) (offset : Nat) :
    (instManyAt e start xs offset).erase =
      (psKernelExprInstantiateAtChanged e.erase start (xs.map erase) offset).1 := by
  induction e generalizing offset with
  | bvar i =>
      simp only [instManyAt, erase, psKernelExprInstantiateAtChanged, erase_lookup]
      cases hlt : psKernelNatLt i (start + offset) with
      | true => simp [hlt, erase]
      | false =>
          cases hs : xs[i - (start + offset)]? with
          | some a => simp [hlt, hs, erase_liftN]
          | none =>
              cases xs <;>
                simp [hlt, hs, erase, erase_length, psKernelExprListIsEmpty]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      have h0 := ihf offset
      have h1 := iha offset
      cases hc0 : (psKernelExprInstantiateAtChanged f.erase start (xs.map erase) offset).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged a.erase start (xs.map erase) offset).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]
  | lam n A b bi v ihA ihb =>
      have h0 := ihA offset
      have h1 := ihb (offset + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase start (xs.map erase) offset).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged b.erase start (xs.map erase) (offset + 1)).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]
  | forallE n A B bi v ihA ihB =>
      have h0 := ihA offset
      have h1 := ihB (offset + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase start (xs.map erase) offset).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged B.erase start (xs.map erase) (offset + 1)).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]
  | letE n A a b nd ihA iha ihb =>
      have h0 := ihA offset
      have h1 := iha offset
      have h2 := ihb (offset + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase start (xs.map erase) offset).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged a.erase start (xs.map erase) offset).2 <;>
      cases hc2 : (psKernelExprInstantiateAtChanged b.erase start (xs.map erase) (offset + 1)).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]
  | mdata md e ih =>
      have h0 := ih offset
      cases hc0 : (psKernelExprInstantiateAtChanged e.erase start (xs.map erase) offset).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]
  | proj n i e ih =>
      have h0 := ih offset
      cases hc0 : (psKernelExprInstantiateAtChanged e.erase start (xs.map erase) offset).2 <;>
        simp_all [instManyAt, erase, psKernelExprInstantiateAtChanged, native_many_unchanged]

theorem erase_instantiateAt (e : AnnotatedExpr) (start : Nat)
    (xs : List AnnotatedExpr) (offset : Nat) :
    (instManyAt e start xs offset).erase =
      psKernelExprInstantiateAt e.erase start (xs.map erase) offset := by
  cases xs with
  | nil => simp [instManyAt_nil, psKernelExprInstantiateAt, psKernelExprListIsEmpty]
  | cons a xs =>
      simpa [psKernelExprInstantiateAt, psKernelExprListIsEmpty] using
        erase_instManyAt e start (a :: xs) offset

private theorem native_reverse (xs acc : List PsKernelExpr) :
    psKernelExprListReverseWorker xs acc = xs.reverse ++ acc := by
  induction xs generalizing acc with
  | nil => rfl
  | cons a xs ih => simp [psKernelExprListReverseWorker, ih, List.reverse_cons,
      List.append_assoc]

theorem erase_instantiateRev (e : AnnotatedExpr) (args : List AnnotatedExpr) :
    (instantiateRev e args).erase =
      psKernelExprInstantiateRev e.erase (args.map erase) := by
  simp [instantiateRev, erase_instantiateAt, psKernelExprInstantiateRev,
    psKernelExprInstantiate, psKernelExprListReverse, native_reverse]

theorem erase_applyArgs (fn : AnnotatedExpr) (args : List AnnotatedExpr) :
    (applyArgs fn args).erase = psKernelExprApplyArgsCheap fn.erase (args.map erase) := by
  induction args generalizing fn with
  | nil => rfl
  | cons a xs ih =>
      simpa only [applyArgs, List.map, psKernelExprApplyArgsCheap,
        psKernelExprApplyArgsCheapWorker, erase] using ih (.app fn a)

theorem erase_consumeLambdas (fuel : Nat) (fn : AnnotatedExpr)
    (args : List AnnotatedExpr) (count : Nat) :
    let r := consumeLambdas fuel fn args.length count
    (r.1.erase, r.2) =
      psKernelExprConsumeLambdaSpineWithFuel fuel fn.erase (args.map erase) count := by
  induction fuel generalizing fn count with
  | zero => rfl
  | succ fuel ih =>
      cases fn <;>
        simp only [consumeLambdas, erase, psKernelExprConsumeLambdaSpineWithFuel,
          erase_length]
      case lam n A b bi v =>
        split
        · exact ih b (count + 1)
        · rfl

private theorem coherent_list_length {xs ys : List AnnotatedExpr}
    (h : List.Forall₂ Coherent xs ys) : xs.length = ys.length := by
  induction h <;> simp_all

private theorem coherent_list_lookup {xs ys : List AnnotatedExpr}
    (h : List.Forall₂ Coherent xs ys) (i : Nat) :
    match xs[i]?, ys[i]? with
    | none, none => True
    | some a, some b => Coherent a b
    | _, _ => False := by
  induction h generalizing i with
  | nil => trivial
  | cons ha hs ih => cases i <;> simp_all

theorem Coherent.instManyAt {e f : AnnotatedExpr} (bodies : Coherent e f)
    {xs ys : List AnnotatedExpr} (args : List.Forall₂ Coherent xs ys)
    (start offset : Nat) :
    Coherent (instManyAt e start xs offset) (instManyAt f start ys offset) := by
  have hlen := coherent_list_length args
  induction bodies generalizing offset with
  | bvar i =>
      have hg := coherent_list_lookup args (i - (start + offset))
      cases hlt : psKernelNatLt i (start + offset) with
      | true => simpa [AnnotatedExpr.instManyAt, hlt] using (Coherent.bvar i)
      | false =>
          cases hx : xs[i - (start + offset)]? <;>
          cases hy : ys[i - (start + offset)]? <;>
            simp only [hx, hy] at hg
          · simpa [AnnotatedExpr.instManyAt, hlt, hx, hy, hlen] using
              (Coherent.bvar (i - ys.length))
          · contradiction
          · contradiction
          · simpa [AnnotatedExpr.instManyAt, hlt, hx, hy] using hg.liftN offset 0
  | fvar n => exact .fvar n
  | mvar n => exact .mvar n
  | sort v => exact .sort v
  | const n vs => exact .const n vs
  | lit v => exact .lit v
  | app hf ha ihf iha => exact .app (ihf offset) (iha offset)
  | lam hv hA ha ihA iha => exact .lam hv (ihA offset) (iha (offset + 1))
  | forallE hv hA ha ihA iha => exact .forallE hv (ihA offset) (iha (offset + 1))
  | letE hA ha he ihA iha ihe => exact .letE (ihA offset) (iha offset) (ihe (offset + 1))
  | mdata he ih => exact .mdata (ih offset)
  | proj he ih => exact .proj (ih offset)

private theorem coherent_list_append {xs ys as bs : List AnnotatedExpr}
    (h : List.Forall₂ Coherent xs ys) (k : List.Forall₂ Coherent as bs) :
    List.Forall₂ Coherent (xs ++ as) (ys ++ bs) := by
  induction h with
  | nil => exact k
  | cons ha hs ih => exact .cons ha ih

private theorem coherent_list_reverse {xs ys : List AnnotatedExpr}
    (h : List.Forall₂ Coherent xs ys) : List.Forall₂ Coherent xs.reverse ys.reverse := by
  induction h with
  | nil => exact .nil
  | cons ha hs ih =>
      simpa only [List.reverse_cons] using
        coherent_list_append ih (.cons ha .nil)

theorem Coherent.instantiateRev {e f : AnnotatedExpr} (bodies : Coherent e f)
    {xs ys : List AnnotatedExpr} (args : List.Forall₂ Coherent xs ys) :
    Coherent (instantiateRev e xs) (instantiateRev f ys) :=
  bodies.instManyAt (coherent_list_reverse args) 0 0

theorem Coherent.applyArgs {f g : AnnotatedExpr} (fn : Coherent f g)
    {xs ys : List AnnotatedExpr} (args : List.Forall₂ Coherent xs ys) :
    Coherent (applyArgs f xs) (applyArgs g ys) := by
  induction args generalizing f g with
  | nil => exact fn
  | cons ha hs ih => exact ih (Coherent.app fn ha)

theorem Coherent.consumeLambdas {f g : AnnotatedExpr} (fn : Coherent f g)
    (fuel argc count : Nat) :
    Coherent (consumeLambdas fuel f argc count).1 (consumeLambdas fuel g argc count).1 ∧
      (consumeLambdas fuel f argc count).2 = (consumeLambdas fuel g argc count).2 := by
  induction fuel generalizing f g count with
  | zero => exact ⟨fn, rfl⟩
  | succ fuel ih =>
      cases fn <;> simp only [consumeLambdas]
      all_goals try exact ⟨by constructor <;> assumption, rfl⟩
      case lam hv hA hb =>
        split
        · exact ih hb (count + 1)
        · exact ⟨.lam hv hA hb, rfl⟩

theorem checkedExprEq_instManyAt {e f : AnnotatedExpr}
    (bodies : checkedExprEq e f = true) {xs ys : List AnnotatedExpr}
    (args : List.Forall₂ Coherent xs ys) (start offset : Nat) :
    checkedExprEq (instManyAt e start xs offset) (instManyAt f start ys offset) = true :=
  ((coherent_of_checkedExprEq bodies).instManyAt args start offset).checked

theorem checkedExprEq_instantiateRev {e f : AnnotatedExpr}
    (bodies : checkedExprEq e f = true) {xs ys : List AnnotatedExpr}
    (args : List.Forall₂ Coherent xs ys) :
    checkedExprEq (instantiateRev e xs) (instantiateRev f ys) = true :=
  ((coherent_of_checkedExprEq bodies).instantiateRev args).checked

/-- Open replacements must not be recursively altered by later entries. -/
theorem simultaneous_is_not_sequential :
    (instManyAt (.bvar 0) 0 [.bvar 0, .fvar .anonymous] 0).erase ≠
      (inst (.fvar .anonymous) (inst (.bvar 0) (.bvar 0) 0) 0).erase := by
  simp [instManyAt, inst, liftN, erase, psKernelNatLt]

end PsKernelSemantics.AnnotatedExpr
