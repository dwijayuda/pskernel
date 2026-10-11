import PSKernelFast.CoreSyntax

/-!
Fresh independent G3 proof obligations. The executive checker remains
unimplemented; these results prove only syntactic/parameter preflight.
-/

namespace PSKernelFast.Core

/-- Separate declarative predicate for universe parameter admissibility. -/
def ULevel.WellFormed (params : List KName) : ULevel → Prop
  | .zero => True
  | .succ inner => ULevel.WellFormed params inner
  | .max left right =>
      ULevel.WellFormed params left ∧ ULevel.WellFormed params right
  | .imax left right =>
      ULevel.WellFormed params left ∧ ULevel.WellFormed params right
  | .param name => name ∈ params
  | .mvar _ => False

theorem ULevel.validParams_sound (params : List KName) (level : ULevel)
    (h : level.validParams params = true) :
    ULevel.WellFormed params level := by
  induction level with
  | zero => trivial
  | succ inner ih =>
      exact ih (by simpa [ULevel.validParams] using h)
  | max left right ihLeft ihRight =>
      have both : left.validParams params = true ∧
          right.validParams params = true := by
        simpa [ULevel.validParams, Bool.and_eq_true] using h
      exact ⟨ihLeft both.1, ihRight both.2⟩
  | imax left right ihLeft ihRight =>
      have both : left.validParams params = true ∧
          right.validParams params = true := by
        simpa [ULevel.validParams, Bool.and_eq_true] using h
      exact ⟨ihLeft both.1, ihRight both.2⟩
  | param name =>
      exact of_decide_eq_true (by simpa [ULevel.validParams] using h)
  | mvar name =>
      simp [ULevel.validParams] at h

/-- Declarative preflight. This is not a typing or environment judgment. -/
def KExpr.StructurallyValid (params : List KName) (depth : Nat) :
    KExpr → Prop
  | .bvar index => index < depth
  | .fvar _ => False
  | .mvar _ => False
  | .sort level => ULevel.WellFormed params level
  | .const _ levels => ∀ l ∈ levels, ULevel.WellFormed params l
  | .app fn arg =>
      KExpr.StructurallyValid params depth fn ∧
        KExpr.StructurallyValid params depth arg
  | .lam _ domain body _ =>
      KExpr.StructurallyValid params depth domain ∧
        KExpr.StructurallyValid params (depth + 1) body
  | .forallE _ domain body _ =>
      KExpr.StructurallyValid params depth domain ∧
        KExpr.StructurallyValid params (depth + 1) body
  | .letE _ type value body _ =>
      (KExpr.StructurallyValid params depth type ∧
        KExpr.StructurallyValid params depth value) ∧
        KExpr.StructurallyValid params (depth + 1) body
  | .lit _ => True
  | .mdata _ expr => KExpr.StructurallyValid params depth expr
  | .proj _ _ expr => KExpr.StructurallyValid params depth expr

theorem KExpr.validAt_sound (params : List KName) (depth : Nat)
    (expr : KExpr) (h : expr.validAt params depth = true) :
    KExpr.StructurallyValid params depth expr := by
  induction expr generalizing depth with
  | bvar index =>
      exact of_decide_eq_true (by simpa [KExpr.validAt] using h)
  | fvar name =>
      simp [KExpr.validAt] at h
  | mvar name =>
      simp [KExpr.validAt] at h
  | sort level =>
      exact ULevel.validParams_sound params level
        (by simpa [KExpr.validAt] using h)
  | const name levels =>
      have validAll : levels.all (ULevel.validParams params) = true := by
        simpa [KExpr.validAt] using h
      intro level member
      exact ULevel.validParams_sound params level
        ((List.all_eq_true.mp validAll) level member)
  | app fn arg ihFn ihArg =>
      have both : fn.validAt params depth = true ∧
          arg.validAt params depth = true := by
        simpa [KExpr.validAt, Bool.and_eq_true] using h
      exact ⟨ihFn depth both.1, ihArg depth both.2⟩
  | lam name domain body binder ihDomain ihBody =>
      have both : domain.validAt params depth = true ∧
          body.validAt params (depth + 1) = true := by
        simpa [KExpr.validAt, Bool.and_eq_true] using h
      exact ⟨ihDomain depth both.1, ihBody (depth + 1) both.2⟩
  | forallE name domain body binder ihDomain ihBody =>
      have both : domain.validAt params depth = true ∧
          body.validAt params (depth + 1) = true := by
        simpa [KExpr.validAt, Bool.and_eq_true] using h
      exact ⟨ihDomain depth both.1, ihBody (depth + 1) both.2⟩
  | letE name type value body nondep ihType ihValue ihBody =>
      have allValid : (type.validAt params depth = true ∧
          value.validAt params depth = true) ∧
          body.validAt params (depth + 1) = true := by
        simpa [KExpr.validAt, Bool.and_eq_true] using h
      exact ⟨⟨ihType depth allValid.1.1, ihValue depth allValid.1.2⟩,
        ihBody (depth + 1) allValid.2⟩
  | lit value => trivial
  | mdata tag expr ih =>
      exact ih depth (by simpa [KExpr.validAt] using h)
  | proj name index expr ih =>
      exact ih depth (by simpa [KExpr.validAt] using h)

theorem KExpr.closedInput_sound (params : List KName)
    (expr : KExpr) (h : expr.closedInput params = true) :
    KExpr.StructurallyValid params 0 expr :=
  KExpr.validAt_sound params 0 expr h

end PSKernelFast.Core
