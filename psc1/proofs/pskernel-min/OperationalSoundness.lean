import RegularSoundness
import OperationalProjection
import OperationalFoundation
import Ps.MinKernel.Profile.OperationalCheck

namespace Ps.MinKernel.OperationalProofs
open Ps.MinKernel.RegularModel
open Ps.MinKernel.RegularProofs

-- The same executable-success equations determine every semantic value.
noncomputable def inferModel (fuel : Nat) (specs : List PsMinRegSpec)
    (globals locals : List PsMinRegTy) (expression : PsMinOpTerm) (type : PsMinRegTy)
    (globalModel : Model (dataModel specs) globals) (localModel : Model (dataModel specs) locals)
    (h : psMinOpInfer fuel specs globals locals expression = some type) : Denote (dataModel specs) type := by
  induction fuel generalizing globals locals expression type with
  | zero => simp [psMinOpInfer] at h
  | succ remaining ih =>
    cases expression with
    | base term =>
      exact RegularProofs.inferModel remaining specs (dataModel specs) globals locals term type
        (signatures specs) globalModel localModel h
    | projection slot field => exact OperationalProjection.projectionModel specs slot field type h
    | primitive schema level parameters indices motives minors =>
      exact OperationalFoundation.primitiveModel (dataModel specs) remaining (psMinRegSpecCount specs)
        schema level parameters indices motives minors type h
    | lam domain body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) domain with
      | false => simp [psMinOpInfer, hv] at h
      | true =>
        cases hb : psMinOpInfer remaining specs globals (domain :: locals) body with
        | none => simp [psMinOpInfer, hv, hb] at h
        | some result =>
          have ht : PsMinRegTy.arr domain result = type := by simpa [psMinOpInfer, hv, hb] using h
          cases ht
          exact fun value => ih globals (domain :: locals) body result globalModel
            (consModel (dataModel specs) value localModel) hb
    | app fn argument =>
      cases hf : psMinOpInfer remaining specs globals locals fn with
      | none => simp [psMinOpInfer, hf] at h
      | some functionType =>
        cases functionType with
        | empty => simp [psMinOpInfer, hf] at h
        | unit => simp [psMinOpInfer, hf] at h
        | nat => simp [psMinOpInfer, hf] at h
        | boolean => simp [psMinOpInfer, hf] at h
        | data index => simp [psMinOpInfer, hf] at h
        | list element => simp [psMinOpInfer, hf] at h
        | option element => simp [psMinOpInfer, hf] at h
        | arr domain result =>
          cases ha : psMinOpInfer remaining specs globals locals argument with
          | none => simp [psMinOpInfer, hf, ha] at h
          | some argumentType =>
            cases heq : psMinRegTyEq remaining domain argumentType with
            | false => simp [psMinOpInfer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [psMinOpInfer, hf, ha, heq] using h
              have harg : domain = argumentType := typeEq_sound remaining _ _ heq
              cases harg
              exact ht ▸ (ih globals locals fn (.arr domain result) globalModel localModel hf)
                (ih globals locals argument domain globalModel localModel ha)
    | letE annotation value body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) annotation with
      | false => simp [psMinOpInfer, hv] at h
      | true =>
        cases hb : psMinOpInfer remaining specs globals locals value with
        | none => simp [psMinOpInfer, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq remaining inferred annotation with
          | false => simp [psMinOpInfer, hv, hb, heq] at h
          | true =>
            have ht : inferred = annotation := typeEq_sound remaining _ _ heq
            have hs : psMinOpInfer remaining specs globals (annotation :: locals) body = some type := by
              simpa [psMinOpInfer, hv, hb, heq] using h
            have bound : Denote (dataModel specs) annotation :=
              ht ▸ ih globals locals value inferred globalModel localModel hb
            exact ih globals (annotation :: locals) body type globalModel
              (consModel (dataModel specs) bound localModel) hs

-- This history records actual checked bodies, not arbitrary inhabitants.
inductive DefinitionHistory (termFuel : Nat) (specs : List PsMinRegSpec) :
    (globals : List PsMinRegTy) → List PsMinOpDeclaration → (result : List PsMinRegTy) →
    Model (dataModel specs) globals → Model (dataModel specs) result → Prop where
  | done {globals : List PsMinRegTy} (model : Model (dataModel specs) globals) :
      DefinitionHistory termFuel specs globals [] globals model model
  | step {globals result : List PsMinRegTy} {initial : Model (dataModel specs) globals}
      (declaration : PsMinOpDeclaration) (rest : List PsMinOpDeclaration)
      (inferred : PsMinRegTy) (valid : psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type = true)
      (checked : psMinOpInfer termFuel specs globals [] declaration.value = some inferred)
      (same : psMinRegTyEq termFuel inferred declaration.type = true)
      (output : Model (dataModel specs) result)
      (tail : DefinitionHistory termFuel specs (declaration.type :: globals) rest result
        (consModel (dataModel specs)
          ((typeEq_sound termFuel _ _ same) ▸ inferModel termFuel specs globals [] declaration.value inferred
            initial (emptyModel (dataModel specs)) checked) initial) output) :
      DefinitionHistory termFuel specs globals (declaration :: rest) result initial output

noncomputable def declarationsWithHistory (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (globals : List PsMinRegTy) (declarations : List PsMinOpDeclaration) (result : List PsMinRegTy)
    (initial : Model (dataModel specs) globals)
    (h : psMinOpCheckDeclarations termFuel declarationFuel specs globals declarations = some result) :
    { output : Model (dataModel specs) result //
      DefinitionHistory termFuel specs globals declarations result initial output } := by
  cases declarations with
  | nil =>
    have ht : globals = result := by simpa [psMinOpCheckDeclarations] using h
    cases ht
    exact ⟨initial, .done initial⟩
  | cons declaration rest =>
    cases hFuel : declarationFuel with
    | zero => simp [hFuel, psMinOpCheckDeclarations] at h
    | succ remaining =>
      simp only [hFuel] at h
      cases hv : psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type with
      | false => simp [psMinOpCheckDeclarations, hv] at h
      | true =>
        cases hb : psMinOpInfer termFuel specs globals [] declaration.value with
        | none => simp [psMinOpCheckDeclarations, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq termFuel inferred declaration.type with
          | false => simp [psMinOpCheckDeclarations, hv, hb, heq] at h
          | true =>
            have hs : psMinOpCheckDeclarations termFuel remaining specs (declaration.type :: globals) rest = some result := by
              simpa [psMinOpCheckDeclarations, hv, hb, heq] using h
            let value : Denote (dataModel specs) declaration.type :=
              (typeEq_sound termFuel _ _ heq) ▸ inferModel termFuel specs globals [] declaration.value inferred
                initial (emptyModel (dataModel specs)) hb
            let tail := declarationsWithHistory termFuel remaining specs (declaration.type :: globals) rest result
              (consModel (dataModel specs) value initial) hs
            exact ⟨tail.val, .step declaration rest inferred hv hb heq tail.val tail.property⟩
termination_by declarationFuel
decreasing_by all_goals simpa only [hFuel] using (Nat.lt_succ_self remaining)

noncomputable def environmentWithHistory (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) (types : List PsMinRegTy)
    (h : psMinOpCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    { output : Model (dataModel specs) types //
      DefinitionHistory termFuel specs [] declarations types (emptyModel (dataModel specs)) output } := by
  cases hv : psMinRegRegistryValid termFuel specs with
  | false => simp [psMinOpCheckEnvironment, hv] at h
  | true =>
    exact declarationsWithHistory termFuel declarationFuel specs [] declarations types
      (emptyModel (dataModel specs)) (by simpa [psMinOpCheckEnvironment, hv] using h)

theorem operational_hasModel (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) (types : List PsMinRegTy)
    (h : psMinOpCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    Nonempty (Model (dataModel specs) types) :=
  ⟨(environmentWithHistory termFuel declarationFuel specs declarations types h).val⟩

theorem operational_hasBodyHistory (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) (types : List PsMinRegTy)
    (h : psMinOpCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    ∃ model, DefinitionHistory termFuel specs [] declarations types (emptyModel (dataModel specs)) model :=
  ⟨_, (environmentWithHistory termFuel declarationFuel specs declarations types h).property⟩

theorem operational_consistent (termFuel declarationFuel queryFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinOpDeclaration) (types : List PsMinRegTy)
    (h : psMinOpCheckEnvironment termFuel declarationFuel specs declarations = some types)
    (expression : PsMinOpTerm) : psMinOpInfer queryFuel specs types [] expression ≠ some PsMinRegTy.empty := by
  intro accepted
  exact Empty.elim (inferModel queryFuel specs types [] expression .empty
    (environmentWithHistory termFuel declarationFuel specs declarations types h).val
    (emptyModel (dataModel specs)) accepted)

theorem latest_definition_value (specs : List PsMinRegSpec) (globals : List PsMinRegTy)
    (initial : Model (dataModel specs) globals) (type : PsMinRegTy) (value : Denote (dataModel specs) type) :
    consModel (dataModel specs) value initial 0 type rfl = value := rfl

theorem previous_definition_value (specs : List PsMinRegSpec) (globals : List PsMinRegTy)
    (initial : Model (dataModel specs) globals) (head type : PsMinRegTy)
    (value : Denote (dataModel specs) head) (index : Nat) (h : psMinRegLookup globals index = some type) :
    consModel (dataModel specs) value initial (Nat.succ index) type h = initial index type h := rfl

#print axioms inferModel
#print axioms operational_hasModel
#print axioms operational_hasBodyHistory
#print axioms operational_consistent
#print axioms latest_definition_value
#print axioms previous_definition_value
end Ps.MinKernel.OperationalProofs
