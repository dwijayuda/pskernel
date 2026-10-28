import Ps.MinKernel.Profile.RankOneTypes
import CoreIngress

namespace Ps.MinKernel.RankOneTypes
open Ps.MinKernel.CoreIngress

-- Monotypes live in Type; a leading universal scheme lives in Type 1.
-- No code for schemes occurs inside Ty, so this does not collapse universes.
def Denote (env : Nat → Type) : PsMinRankTy → Type
  | .tvar index => env index
  | .natural => Nat
  | .boolean => Bool
  | .unit => Unit
  | .arr a b => Denote env a → Denote env b
  | .list a => List (Denote env a)
  | .option a => Option (Denote env a)
  | .except a b => Except (Denote env a) (Denote env b)
  | .prod a b => Prod (Denote env a) (Denote env b)

def Quantify : Nat → (List Type → Type) → Type 1
  | 0, body => ULift.{1,0} (body [])
  | Nat.succ n, body => (a : Type) → Quantify n (fun tail => body (a :: tail))

def parameterAt : List Type → Nat → Type
  | [], _ => Empty
  | a :: _, 0 => a
  | _ :: tail, Nat.succ n => parameterAt tail n

def SchemeDenote (scheme : PsMinRankScheme) : Type 1 :=
  Quantify scheme.arity (fun parameters => Denote (parameterAt parameters) scheme.body)

def Rename (mapping : Nat → Nat) : PsMinRankTy → PsMinRankTy
  | .tvar i => .tvar (mapping i)
  | .natural => .natural
  | .boolean => .boolean
  | .unit => .unit
  | .arr a b => .arr (Rename mapping a) (Rename mapping b)
  | .list a => .list (Rename mapping a)
  | .option a => .option (Rename mapping a)
  | .except a b => .except (Rename mapping a) (Rename mapping b)
  | .prod a b => .prod (Rename mapping a) (Rename mapping b)

def Substitute (substitution : Nat → PsMinRankTy) : PsMinRankTy → PsMinRankTy
  | .tvar i => substitution i
  | .natural => .natural
  | .boolean => .boolean
  | .unit => .unit
  | .arr a b => .arr (Substitute substitution a) (Substitute substitution b)
  | .list a => .list (Substitute substitution a)
  | .option a => .option (Substitute substitution a)
  | .except a b => .except (Substitute substitution a) (Substitute substitution b)
  | .prod a b => .prod (Substitute substitution a) (Substitute substitution b)

def WellFormed (n : Nat) : PsMinRankTy → Prop
  | .tvar i => i < n
  | .natural | .boolean | .unit => True
  | .arr a b | .except a b | .prod a b => WellFormed n a ∧ WellFormed n b
  | .list a | .option a => WellFormed n a

theorem denote_rename (env : Nat → Type) (rename : Nat → Nat) (type : PsMinRankTy) :
    Denote env (Rename rename type) = Denote (fun i => env (rename i)) type := by
  induction type <;> simp_all [Rename, Denote]

theorem denote_substitute (env : Nat → Type) (substitute : Nat → PsMinRankTy) (type : PsMinRankTy) :
    Denote env (Substitute substitute type) = Denote (fun i => Denote env (substitute i)) type := by
  induction type <;> simp_all [Substitute, Denote]

theorem wf_rename (type : PsMinRankTy) (h : WellFormed n type)
    (preserves : ∀ i, i < n → rename i < m) : WellFormed m (Rename rename type) := by
  induction type <;> simp_all [WellFormed, Rename]

theorem wf_substitute (type : PsMinRankTy) (h : WellFormed n type)
    (preserves : ∀ i, i < n → WellFormed m (substitute i)) :
    WellFormed m (Substitute substitute type) := by
  induction type <;> simp_all [WellFormed, Substitute]

inductive Lookup : List (Option Nat) → Nat → Nat → Prop where
  | here : Lookup (some slot :: tail) 0 slot
  | there (h : Lookup tail index slot) : Lookup (head :: tail) (Nat.succ index) slot

theorem lookup_sound (context : List (Option Nat)) (index slot : Nat)
    (h : psMinRankLookup context index = some slot) : Lookup context index slot := by
  induction context generalizing index with
  | nil => simp [psMinRankLookup] at h
  | cons head tail ih =>
    cases index with
    | zero =>
      simp only [psMinRankLookup] at h
      subst head
      exact .here
    | succ index => exact .there (ih index h)

inductive ContextWF (n : Nat) : List (Option Nat) → Prop where
  | nil : ContextWF n []
  | term (tail : ContextWF n context) : ContextWF n (none :: context)
  | type (bound : slot < n) (tail : ContextWF n context) :
      ContextWF n (some slot :: context)

theorem context_mono (h : ContextWF n context) (bound : n ≤ m) : ContextWF m context := by
  induction h with
  | nil => exact .nil
  | term _ ih => exact .term ih
  | type lower _ ih => exact .type (Nat.lt_of_lt_of_le lower bound) ih

theorem lookup_bound (h : Lookup context index slot) (valid : ContextWF n context) :
    slot < n := by
  induction h with
  | here => cases valid with | type bound _ => exact bound
  | there _ ih =>
    cases valid with
    | term tail => exact ih tail
    | type _ tail => exact ih tail

inductive BaseImage : PsMinCoreName → PsMinRankTy → Prop where
  | natural : BaseImage (.str .anonymous [78,97,116]) .natural
  | boolean : BaseImage (.str .anonymous [66,111,111,108]) .boolean
  | unit : BaseImage (.str .anonymous [85,110,105,116]) .unit
inductive UnaryImage : PsMinCoreName → PsMinRankTy → PsMinRankTy → Prop where
  | list : UnaryImage (.str .anonymous [76,105,115,116]) a (.list a)
  | option : UnaryImage (.str .anonymous [79,112,116,105,111,110]) a (.option a)
inductive BinaryImage : PsMinCoreName → PsMinRankTy → PsMinRankTy → PsMinRankTy → Prop where
  | except : BinaryImage (.str .anonymous [69,120,99,101,112,116]) a b (.except a b)
  | prod : BinaryImage (.str .anonymous [80,114,111,100]) a b (.prod a b)

theorem base_translation (h : psMinRankBase name = some type) : BaseImage name type := by
  unfold psMinRankBase at h
  repeat' split at h
  all_goals try contradiction
  all_goals cases h
  all_goals first
    | simpa only [nameEq_sound _ _ (by assumption)] using BaseImage.natural
    | simpa only [nameEq_sound _ _ (by assumption)] using BaseImage.boolean
    | simpa only [nameEq_sound _ _ (by assumption)] using BaseImage.unit

theorem unary_translation (h : psMinRankUnary name element = some type) : UnaryImage name element type := by
  unfold psMinRankUnary at h
  repeat' split at h
  all_goals try contradiction
  all_goals cases h
  all_goals first
    | simpa only [nameEq_sound _ _ (by assumption)] using (UnaryImage.list (a := element))
    | simpa only [nameEq_sound _ _ (by assumption)] using (UnaryImage.option (a := element))

theorem binary_translation (h : psMinRankBinary name left right = some type) :
    BinaryImage name left right type := by
  unfold psMinRankBinary at h
  repeat' split at h
  all_goals try contradiction
  all_goals cases h
  all_goals first
    | simpa only [nameEq_sound _ _ (by assumption)] using (BinaryImage.except (a := left) (b := right))
    | simpa only [nameEq_sound _ _ (by assumption)] using (BinaryImage.prod (a := left) (b := right))

-- Independent rank-one type grammar. No executable parser call appears here.
inductive TypeImage : List (Option Nat) → PsMinCoreExpr → PsMinRankTy → Prop where
  | tvar (h : Lookup context index slot) : TypeImage context (.bvar index) (.tvar slot)
  | base (h : BaseImage name type) : TypeImage context (.constant name []) type
  | arr (a : TypeImage context domain left) (b : TypeImage (none :: context) body right) :
      TypeImage context (.forallE name binder domain body) (.arr left right)
  | unary (a : TypeImage context argument element) (head : UnaryImage name element type) :
      TypeImage context (.app (.constant name []) argument) type
  | binary (a : TypeImage context first left) (b : TypeImage context second right)
      (head : BinaryImage name left right type) :
      TypeImage context (.app (.app (.constant name []) first) second) type

theorem type_translation (fuel : Nat) (source : PsMinCoreExpr) (context : List (Option Nat))
    (h : psMinRankMono fuel context source = some type) : TypeImage context source type := by
  induction fuel generalizing source context type with
  | zero => simp [psMinRankMono] at h
  | succ fuel ih =>
    cases source with
    | bvar index =>
      cases hl : psMinRankLookup context index with
      | none => simp [psMinRankMono, hl] at h
      | some slot =>
        simp only [psMinRankMono, hl, Option.some.injEq] at h
        subst type
        exact .tvar (lookup_sound _ _ _ hl)
    | constant name levels =>
      simp only [psMinRankMono] at h
      split at h
      next empty =>
        have same := byteEq_sound _ _ empty
        subst levels
        exact .base (base_translation h)
      next => contradiction
    | forallE name binder domain body =>
      cases ha : psMinRankMono fuel context domain with
      | none => simp [psMinRankMono, ha] at h
      | some a =>
        cases hb : psMinRankMono fuel (none :: context) body with
        | none => simp [psMinRankMono, ha, hb] at h
        | some b =>
          simp only [psMinRankMono, ha, hb, Option.some.injEq] at h
          subst type
          exact .arr (ih _ _ ha) (ih _ _ hb)
    | app fn arg =>
      cases fn with
      | constant name levels =>
        simp only [psMinRankMono] at h
        split at h
        next empty =>
          have same := byteEq_sound _ _ empty
          subst levels
          cases ha : psMinRankMono fuel context arg with
          | none => simp [ha] at h
          | some a =>
            simp only [ha] at h
            exact .unary (ih _ _ ha) (unary_translation h)
        next => contradiction
      | app operator first =>
        cases operator with
        | constant name levels =>
          simp only [psMinRankMono] at h
          split at h
          next empty =>
            have same := byteEq_sound _ _ empty
            subst levels
            cases ha : psMinRankMono fuel context first with
            | none => simp [ha] at h
            | some a =>
              cases hb : psMinRankMono fuel context arg with
              | none => simp [ha, hb] at h
              | some b =>
                simp only [ha, hb] at h
                exact .binary (ih _ _ ha) (ih _ _ hb) (binary_translation h)
          next => contradiction
        | _ => simp [psMinRankMono] at h
      | _ => simp [psMinRankMono] at h
    | _ => simp [psMinRankMono] at h

theorem type_wf (h : TypeImage context source type) (valid : ContextWF n context) :
    WellFormed n type := by
  revert valid
  induction h with
  | tvar lookup => intro valid; exact lookup_bound lookup valid
  | base base => intro valid; cases base <;> trivial
  | arr _ _ ihA ihB => intro valid; exact ⟨ihA valid, ihB (.term valid)⟩
  | unary _ head ih =>
    intro valid
    cases head <;> exact ih valid
  | binary _ _ head ihA ihB =>
    intro valid
    cases head <;> exact ⟨ihA valid, ihB valid⟩

inductive SchemeImage : Nat → List (Option Nat) → PsMinCoreExpr → PsMinRankScheme → Prop where
  | mono (h : TypeImage context source type) : SchemeImage count context source ⟨count, type⟩
  | parameter (h : SchemeImage (Nat.succ count) (some count :: context) body scheme) :
      SchemeImage count context (.forallE name binder (.sort 1) body) scheme

theorem finish_translation (h : psMinRankFinish fuel count context source = some scheme) :
    SchemeImage count context source scheme := by
  unfold psMinRankFinish at h
  cases hm : psMinRankMono fuel context source with
  | none => simp [hm] at h
  | some type =>
    simp only [hm, Option.some.injEq] at h
    subst scheme
    exact .mono (type_translation _ _ _ hm)

theorem scheme_translation (fuel : Nat) (source : PsMinCoreExpr)
    (h : psMinRankSchemeWith fuel count context source = some scheme) :
    SchemeImage count context source scheme := by
  induction fuel generalizing source count context scheme with
  | zero => simp [psMinRankSchemeWith] at h
  | succ fuel ih =>
    cases source with
    | forallE name binder domain body =>
      cases domain with
      | sort level =>
        simp only [psMinRankSchemeWith] at h
        split at h
        next one =>
          have same := Nat.eq_of_beq_eq_true one
          subst level
          exact .parameter (ih _ h)
        next => exact finish_translation (fuel := Nat.succ fuel) h
      | _ => exact finish_translation (fuel := Nat.succ fuel) h
    | _ => exact finish_translation (fuel := Nat.succ fuel) h

theorem scheme_wf (h : SchemeImage count context source scheme) (valid : ContextWF count context) :
    WellFormed scheme.arity scheme.body := by
  revert valid
  induction h with
  | mono image => intro valid; exact type_wf image valid
  | parameter _ ih =>
    intro valid
    exact ih (.type (Nat.lt_succ_self _) (context_mono valid (Nat.le_succ _)))

theorem signature_wellformed (h : psMinRankSignature fuel source = some scheme) :
    WellFormed scheme.arity scheme.body :=
  scheme_wf (scheme_translation _ _ h) .nil

theorem universal_variable_empty : SchemeDenote ⟨1, .tvar 0⟩ → False := by
  intro value
  exact Empty.elim ((value Empty).down)

theorem identity_scheme_inhabited : Nonempty (SchemeDenote ⟨1, .arr (.tvar 0) (.tvar 0)⟩) :=
  ⟨fun _ => ⟨fun x => x⟩⟩

end Ps.MinKernel.RankOneTypes
