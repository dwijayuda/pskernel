import Ps.KernelCore.Metatheory.SemanticCheckedAnnotations

/-!
The executable annotated comparator is closed under the syntax operations used
by checking. These are syntactic theorems, with no model, typing, cache or
recursive-checker soundness premise. Coherent mirrors exactly the comparator:
binder names/info are ignored, but metadata, let flags, projection labels,
ordinary sorts and constant level lists are retained.

This relation must not be confused with kernel definitional equality.
-/
namespace PsKernelSemantics.AnnotatedExpr

inductive Coherent : AnnotatedExpr → AnnotatedExpr → Prop where
  | bvar (i : Nat) : Coherent (.bvar i) (.bvar i)
  | fvar (n : PsKernelName) : Coherent (.fvar n) (.fvar n)
  | mvar (n : PsKernelName) : Coherent (.mvar n) (.mvar n)
  | sort (v : PsKernelLevel) : Coherent (.sort v) (.sort v)
  | const (n : PsKernelName) (vs : List PsKernelLevel) :
      Coherent (.const n vs) (.const n vs)
  | lit (v : PsKernelLiteral) : Coherent (.lit v) (.lit v)
  | app {f g a b : AnnotatedExpr} :
      Coherent f g → Coherent a b → Coherent (.app f a) (.app g b)
  | lam {n m : PsKernelName} {A B a b : AnnotatedExpr}
      {bi bj : PsKernelBinderInfo} {v w : PsKernelLevel} :
      UniverseRegime.check v w = true → Coherent A B → Coherent a b →
      Coherent (.lam n A a bi v) (.lam m B b bj w)
  | forallE {n m : PsKernelName} {A B a b : AnnotatedExpr}
      {bi bj : PsKernelBinderInfo} {v w : PsKernelLevel} :
      UniverseRegime.check v w = true → Coherent A B → Coherent a b →
      Coherent (.forallE n A a bi v) (.forallE m B b bj w)
  | letE {n m : PsKernelName} {A B a b e f : AnnotatedExpr} {nd : Bool} :
      Coherent A B → Coherent a b → Coherent e f →
      Coherent (.letE n A a e nd) (.letE m B b f nd)
  | mdata {md : Nat} {e f : AnnotatedExpr} :
      Coherent e f → Coherent (.mdata md e) (.mdata md f)
  | proj {n : PsKernelName} {i : Nat} {e f : AnnotatedExpr} :
      Coherent e f → Coherent (.proj n i e) (.proj n i f)

private theorem andBool_true {a b : Bool} :
    (if a then b else false) = true ↔ a = true ∧ b = true := by
  cases a <;> simp

private theorem boolEq_true {a b : Bool} :
    psKernelBoolEq a b = true ↔ a = b := by
  cases a <;> cases b <;> decide

private theorem literalEq_true {a b : PsKernelLiteral}
    (h : psKernelLiteralEq a b = true) : a = b := by
  cases a <;> cases b <;> simp [psKernelLiteralEq, psKernelStringEq] at h <;>
    cases h <;> rfl

theorem coherent_of_checkedExprEq {a b : AnnotatedExpr}
    (h : checkedExprEq a b = true) : Coherent a b := by
  induction a generalizing b with
  | bvar i =>
      cases b <;> simp [checkedExprEq, erase, psKernelExprEq, checkRegimes] at h
      cases h
      exact .bvar i
  | fvar n =>
      cases b <;> simp [checkedExprEq, erase, psKernelExprEq, checkRegimes] at h
      have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ h
      cases hn
      exact .fvar n
  | mvar n =>
      cases b <;> simp [checkedExprEq, erase, psKernelExprEq, checkRegimes] at h
      have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ h
      cases hn
      exact .mvar n
  | sort v =>
      cases b <;> simp [checkedExprEq, erase, psKernelExprEq, checkRegimes] at h
      have hv := psKernelLevelEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ h
      cases hv
      exact .sort v
  | const n vs =>
      cases b <;>
        simp [checkedExprEq, erase, psKernelExprEq, checkRegimes, andBool_true] at h
      have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ h.1
      have hv := psKernelLevelListEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ h.2
      cases hn; cases hv
      exact .const n vs
  | lit v =>
      cases b <;> simp [checkedExprEq, erase, psKernelExprEq, checkRegimes] at h
      have hv := literalEq_true h
      cases hv
      exact .lit v
  | app f a ihf iha =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hf, ha⟩, hfr, har⟩
      exact .app (ihf (by simp [checkedExprEq, hf, hfr]))
        (iha (by simp [checkedExprEq, ha, har]))
  | lam n A a bi v ihA iha =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hA, ha⟩, hv, hAr, har⟩
      exact .lam hv (ihA (by simp [checkedExprEq, hA, hAr]))
        (iha (by simp [checkedExprEq, ha, har]))
  | forallE n A a bi v ihA iha =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hA, ha⟩, hv, hAr, har⟩
      exact .forallE hv (ihA (by simp [checkedExprEq, hA, hAr]))
        (iha (by simp [checkedExprEq, ha, har]))
  | letE n A a e nd ihA iha ihe =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hA, ha, he, hnd⟩, hAr, har, her⟩
      have hnd' := boolEq_true.mp hnd
      cases hnd'
      exact .letE (ihA (by simp [checkedExprEq, hA, hAr]))
        (iha (by simp [checkedExprEq, ha, har]))
        (ihe (by simp [checkedExprEq, he, her]))
  | mdata md e ih =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hmd, he⟩, her⟩
      have hmd' := Nat.eq_of_beq_eq_true hmd
      cases hmd'
      exact .mdata (ih (by simp [checkedExprEq, he, her]))
  | proj n i e ih =>
      cases b <;>
        simp only [checkedExprEq, erase, psKernelExprEq, checkRegimes,
          Bool.and_eq_true, andBool_true, Bool.false_eq_true, false_and] at h
      rcases h with ⟨⟨hn, hi, he⟩, her⟩
      have hn' := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 _ _ hn
      have hi' := Nat.eq_of_beq_eq_true hi
      cases hn'; cases hi'
      exact .proj (ih (by simp [checkedExprEq, he, her]))

theorem Coherent.checked {a b : AnnotatedExpr} (h : Coherent a b) :
    checkedExprEq a b = true := by
  induction h with
  | bvar i | fvar i | mvar i | sort i | lit i => exact checkedExprEq_refl _
  | const n vs => exact checkedExprEq_refl _
  | app hf ha ihf iha =>
      simp only [checkedExprEq, Bool.and_eq_true] at ihf iha ⊢
      simp [erase, psKernelExprEq, checkRegimes, ihf.1, ihf.2, iha.1, iha.2]
  | lam hv hA ha ihA iha | forallE hv hA ha ihA iha =>
      simp only [checkedExprEq, Bool.and_eq_true] at ihA iha ⊢
      simp [erase, psKernelExprEq, checkRegimes, hv, ihA.1, ihA.2, iha.1, iha.2]
  | letE hA ha he ihA iha ihe =>
      simp only [checkedExprEq, Bool.and_eq_true] at ihA iha ihe ⊢
      refine ⟨?_, ?_⟩
      · simp [erase, psKernelExprEq, ihA.1, iha.1, ihe.1, boolEq_true]
      · simp [checkRegimes, ihA.2, iha.2, ihe.2]
  | mdata he ih =>
      simpa [checkedExprEq, erase, psKernelExprEq, checkRegimes] using ih
  | proj he ih =>
      simp only [checkedExprEq, Bool.and_eq_true] at ih ⊢
      simp [erase, psKernelExprEq, checkRegimes, ih.1, ih.2,
        PsKernelSharing.psKernelNameEq_refl_of_string_law PsKernelSharing.string_reflexive]

theorem checkedExprEq_iff_coherent (a b : AnnotatedExpr) :
    checkedExprEq a b = true ↔ Coherent a b :=
  ⟨coherent_of_checkedExprEq, Coherent.checked⟩

theorem Coherent.liftN {a b : AnnotatedExpr} (h : Coherent a b)
    (amount cut : Nat) : Coherent (liftN amount a cut) (liftN amount b cut) := by
  induction h generalizing cut with
  | bvar i => exact .bvar _
  | fvar n => exact .fvar n
  | mvar n => exact .mvar n
  | sort v => exact .sort v
  | const n vs => exact .const n vs
  | lit v => exact .lit v
  | app hf ha ihf iha => exact .app (ihf cut) (iha cut)
  | lam hv hA ha ihA iha => exact .lam hv (ihA cut) (iha (cut + 1))
  | forallE hv hA ha ihA iha => exact .forallE hv (ihA cut) (iha (cut + 1))
  | letE hA ha he ihA iha ihe => exact .letE (ihA cut) (iha cut) (ihe (cut + 1))
  | mdata he ih => exact .mdata (ih cut)
  | proj he ih => exact .proj (ih cut)

theorem Coherent.inst {e f a b : AnnotatedExpr}
    (bodies : Coherent e f) (args : Coherent a b) (cut : Nat) :
    Coherent (inst a e cut) (inst b f cut) := by
  induction bodies generalizing cut with
  | bvar i =>
      simp only [inst]
      split
      · exact .bvar _
      · split
        · exact args.liftN cut 0
        · exact .bvar _
  | fvar n => exact .fvar n
  | mvar n => exact .mvar n
  | sort v => exact .sort v
  | const n vs => exact .const n vs
  | lit v => exact .lit v
  | app hf ha ihf iha => exact .app (ihf cut) (iha cut)
  | lam hv hA ha ihA iha => exact .lam hv (ihA cut) (iha (cut + 1))
  | forallE hv hA ha ihA iha => exact .forallE hv (ihA cut) (iha (cut + 1))
  | letE hA ha he ihA iha ihe => exact .letE (ihA cut) (iha cut) (ihe (cut + 1))
  | mdata he ih => exact .mdata (ih cut)
  | proj he ih => exact .proj (ih cut)

theorem Coherent.close {a b : AnnotatedExpr} (h : Coherent a b)
    (name : PsKernelName) (cut : Nat) : Coherent (close name a cut) (close name b cut) := by
  induction h generalizing cut with
  | fvar n =>
      simp only [close]
      split
      · exact .bvar _
      · exact .fvar _
  | bvar i => exact .bvar i
  | mvar n => exact .mvar n
  | sort v => exact .sort v
  | const n vs => exact .const n vs
  | lit v => exact .lit v
  | app hf ha ihf iha => exact .app (ihf cut) (iha cut)
  | lam hv hA ha ihA iha => exact .lam hv (ihA cut) (iha (cut + 1))
  | forallE hv hA ha ihA iha => exact .forallE hv (ihA cut) (iha (cut + 1))
  | letE hA ha he ihA iha ihe => exact .letE (ihA cut) (iha cut) (ihe (cut + 1))
  | mdata he ih => exact .mdata (ih cut)
  | proj he ih => exact .proj (ih cut)

theorem Coherent.instLevels {a b : AnnotatedExpr} (h : Coherent a b)
    (names : List PsKernelName) (values : List PsKernelLevel) :
    Coherent (instLevels names values a) (instLevels names values b) := by
  induction h with
  | bvar i => exact .bvar i
  | fvar n => exact .fvar n
  | mvar n => exact .mvar n
  | sort v => exact .sort _
  | const n vs => exact .const n _
  | lit v => exact .lit v
  | app hf ha ihf iha => exact .app ihf iha
  | lam hv hA ha ihA iha => exact .lam (UniverseRegime.check_instParams _ _ names values hv) ihA iha
  | forallE hv hA ha ihA iha => exact .forallE (UniverseRegime.check_instParams _ _ names values hv) ihA iha
  | letE hA ha he ihA iha ihe => exact .letE ihA iha ihe
  | mdata he ih => exact .mdata ih
  | proj he ih => exact .proj ih

theorem checkedExprEq_liftN {a b : AnnotatedExpr}
    (h : checkedExprEq a b = true) (amount cut : Nat) :
    checkedExprEq (liftN amount a cut) (liftN amount b cut) = true :=
  ((coherent_of_checkedExprEq h).liftN amount cut).checked

/-- Unlike semantic equality of the results alone, this theorem preserves the
actual executable guard needed at a later structural-comparison visit. -/
theorem checkedExprEq_inst {e f a b : AnnotatedExpr}
    (bodies : checkedExprEq e f = true) (args : checkedExprEq a b = true) (cut : Nat) :
    checkedExprEq (inst a e cut) (inst b f cut) = true :=
  ((coherent_of_checkedExprEq bodies).inst (coherent_of_checkedExprEq args) cut).checked

theorem checkedExprEq_close {a b : AnnotatedExpr}
    (h : checkedExprEq a b = true) (name : PsKernelName) (cut : Nat) :
    checkedExprEq (close name a cut) (close name b cut) = true :=
  ((coherent_of_checkedExprEq h).close name cut).checked

theorem checkedExprEq_instLevels {a b : AnnotatedExpr}
    (h : checkedExprEq a b = true) (names : List PsKernelName) (values : List PsKernelLevel) :
    checkedExprEq (instLevels names values a) (instLevels names values b) = true :=
  ((coherent_of_checkedExprEq h).instLevels names values).checked

end PsKernelSemantics.AnnotatedExpr
