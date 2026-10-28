import OperationalSoundness
import RegularIngressAmbient

namespace Ps.MinKernel.RegularIngressOperationalModel
open Ps.MinKernel.RegularModel
open Ps.MinKernel.RegularProofs

def OrdinaryModel (specs : List PsMinRegSpec) (data : List Type) : Type :=
  (fuel : Nat) → (globals locals : List PsMinRegTy) → (term : PsMinOpTerm) → (type : PsMinRegTy) →
  Model data globals → Model data locals →
  psMinOpInfer fuel specs globals locals term = some type → Denote data type

def RecursorModel (specs : List PsMinRegSpec) (data : List Type) : Type :=
  (slot : Nat) → (result type : PsMinRegTy) →
  psMinRegCoreAmbientRecursorType specs slot result = some type → Denote data type

-- Values follow evaluation rules; the executable inferencer is used only in the
-- two leaf certificates. The final model supplies the concrete existing models.
inductive Eval (data : List Type) (specs : List PsMinRegSpec)
    (ordinary : OrdinaryModel specs data) (recursors : RecursorModel specs data)
    (globals : List PsMinRegTy) (G : Model data globals) :
    (locals : List PsMinRegTy) → Model data locals →
    PsMinRegCoreTerm → (type : PsMinRegTy) → Denote data type → Prop where
  | ordinary (locals L atom type fuel)
      (h : psMinOpInfer fuel specs globals locals atom = some type) :
      Eval data specs ordinary recursors globals G locals L (.ordinary atom) type
        (ordinary fuel globals locals atom type G L h)
  | recursor (locals L slot result type)
      (h : psMinRegCoreAmbientRecursorType specs slot result = some type) :
      Eval data specs ordinary recursors globals G locals L (.recursor slot result) type
        (recursors slot result type h)
  | lam (locals L domain body result) (fn : Denote data domain → Denote data result)
      (hb : ∀ value, Eval data specs ordinary recursors globals G
        (domain :: locals) (consModel data value L) body result (fn value)) :
      Eval data specs ordinary recursors globals G locals L (.lam domain body) (.arr domain result) fn
  | app (locals L fn argument domain result) (f : Denote data domain → Denote data result) (a : Denote data domain)
      (hf : Eval data specs ordinary recursors globals G locals L fn (.arr domain result) f)
      (ha : Eval data specs ordinary recursors globals G locals L argument domain a) :
      Eval data specs ordinary recursors globals G locals L (.app fn argument) result (f a)
  | letE (locals L type value body result) (v : Denote data type) (b : Denote data result)
      (hv : Eval data specs ordinary recursors globals G locals L value type v)
      (hb : Eval data specs ordinary recursors globals G (type :: locals) (consModel data v L) body result b) :
      Eval data specs ordinary recursors globals G locals L (.letE type value body) result b

noncomputable def evaluate_checked (data : List Type) (specs : List PsMinRegSpec)
    (ordinary : OrdinaryModel specs data) (recursors : RecursorModel specs data)
    (fuel : Nat) (globals locals : List PsMinRegTy) (term : PsMinRegCoreTerm) (type : PsMinRegTy)
    (G : Model data globals) (L : Model data locals)
    (h : psMinRegCoreInfer fuel specs globals locals term = some type) :
    { value : Denote data type // Eval data specs ordinary recursors globals G locals L term type value } := by
  induction fuel generalizing locals term type with
  | zero => simp [psMinRegCoreInfer] at h
  | succ remaining ih =>
    cases term with
    | ordinary atom =>
      exact ⟨ordinary remaining globals locals atom type G L h, .ordinary locals L atom type remaining h⟩
    | recursor slot result =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) result with
      | false => simp [psMinRegCoreInfer, hv] at h
      | true =>
        have hs : psMinRegCoreAmbientRecursorType specs slot result = some type := by
          simpa only [psMinRegCoreInfer, hv, ↓reduceIte] using h
        exact ⟨recursors slot result type hs, .recursor locals L slot result type hs⟩
    | lam domain body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) domain with
      | false => simp [psMinRegCoreInfer, hv] at h
      | true =>
        cases hb : psMinRegCoreInfer remaining specs globals (domain :: locals) body with
        | none => simp [psMinRegCoreInfer, hv, hb] at h
        | some result =>
          have ht : .arr domain result = type := by simpa [psMinRegCoreInfer, hv, hb] using h
          subst type
          let values := fun value => ih (domain :: locals) body result (consModel data value L) hb
          exact ⟨fun value => (values value).val,
            .lam locals L domain body result (fun value => (values value).val)
              (fun value => (values value).property)⟩
    | app fn argument =>
      cases hf : psMinRegCoreInfer remaining specs globals locals fn with
      | none => simp [psMinRegCoreInfer, hf] at h
      | some functionType =>
        cases functionType with
        | arr domain result =>
          cases ha : psMinRegCoreInfer remaining specs globals locals argument with
          | none => simp [psMinRegCoreInfer, hf, ha] at h
          | some argumentType =>
            cases heq : psMinRegTyEq remaining domain argumentType with
            | false => simp [psMinRegCoreInfer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [psMinRegCoreInfer, hf, ha, heq] using h
              have same := typeEq_sound remaining _ _ heq
              cases same
              subst type
              let f := ih locals fn (.arr domain result) L hf
              let a := ih locals argument domain L ha
              exact ⟨f.val a.val, .app locals L fn argument domain result f.val a.val f.property a.property⟩
        | _ => simp [psMinRegCoreInfer, hf] at h
    | letE annotation value body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) annotation with
      | false => simp [psMinRegCoreInfer, hv] at h
      | true =>
        cases hb : psMinRegCoreInfer remaining specs globals locals value with
        | none => simp [psMinRegCoreInfer, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq remaining inferred annotation with
          | false => simp [psMinRegCoreInfer, hv, hb, heq] at h
          | true =>
            have same := typeEq_sound remaining _ _ heq
            cases same
            have hs : psMinRegCoreInfer remaining specs globals (annotation :: locals) body = some type := by
              simpa [psMinRegCoreInfer, hv, hb, heq] using h
            let v := ih locals value annotation L hb
            let b := ih (annotation :: locals) body type (consModel data v.val L) hs
            exact ⟨b.val, .letE locals L annotation value body type v.val b.val v.property b.property⟩

inductive DefinitionHistory (data : List Type) (specs : List PsMinRegSpec)
    (ordinary : OrdinaryModel specs data) (recursors : RecursorModel specs data) :
    (globals : List PsMinRegTy) → List PsMinRegCoreDefinition → (result : List PsMinRegTy) →
    Model data globals → Model data result → Prop where
  | done (globals) (model : Model data globals) :
      DefinitionHistory data specs ordinary recursors globals [] globals model model
  | step (globals result) (declaration : PsMinRegCoreDefinition) (rest)
      (initial : Model data globals) (output : Model data result) (value : Denote data declaration.type)
      (body : Eval data specs ordinary recursors globals initial [] (emptyModel data)
        declaration.value declaration.type value)
      (tail : DefinitionHistory data specs ordinary recursors (declaration.type :: globals)
        rest result (consModel data value initial) output) :
      DefinitionHistory data specs ordinary recursors globals (declaration :: rest) result initial output

noncomputable def definitions_history (data : List Type) (specs : List PsMinRegSpec)
    (ordinary : OrdinaryModel specs data) (recursors : RecursorModel specs data)
    (termFuel declarationFuel : Nat) (globals : List PsMinRegTy)
    (declarations : List PsMinRegCoreDefinition) (result : List PsMinRegTy)
    (initial : Model data globals)
    (h : psMinRegCoreCheckDefinitions termFuel declarationFuel specs globals declarations = some result) :
    { output : Model data result // DefinitionHistory data specs ordinary recursors globals declarations result initial output } := by
  cases declarations with
  | nil =>
    have ht : globals = result := by simpa [psMinRegCoreCheckDefinitions] using h
    subst result
    exact ⟨initial, .done globals initial⟩
  | cons declaration rest =>
    cases hFuel : declarationFuel with
    | zero => simp [hFuel, psMinRegCoreCheckDefinitions] at h
    | succ remaining =>
      cases hv : psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type with
      | false => simp [hFuel, psMinRegCoreCheckDefinitions, hv] at h
      | true =>
        cases hb : psMinRegCoreInfer termFuel specs globals [] declaration.value with
        | none => simp [hFuel, psMinRegCoreCheckDefinitions, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq termFuel inferred declaration.type with
          | false => simp [hFuel, psMinRegCoreCheckDefinitions, hv, hb, heq] at h
          | true =>
            have same := typeEq_sound termFuel _ _ heq
            cases same
            have hs : psMinRegCoreCheckDefinitions termFuel remaining specs
                (declaration.type :: globals) rest = some result := by
              simpa [hFuel, psMinRegCoreCheckDefinitions, hv, hb, heq] using h
            let value := evaluate_checked data specs ordinary recursors termFuel globals []
              declaration.value declaration.type initial (emptyModel data) hb
            let tail := definitions_history data specs ordinary recursors termFuel remaining
              (declaration.type :: globals) rest result (consModel data value.val initial) hs
            exact ⟨tail.val, .step globals result declaration rest initial tail.val value.val value.property tail.property⟩
termination_by declarationFuel
decreasing_by all_goals simpa only [hFuel] using (Nat.lt_succ_self remaining)

-- Canonical atomic denotations use the already proved foundation/projection
-- models directly. The general R3 evaluator interprets the remaining terms.
noncomputable def actualOrdinary (specs : List PsMinRegSpec) : OrdinaryModel specs (dataModel specs) :=
  fun fuel globals locals term type G L checked => by
    cases term with
    | primitive schema level parameters indices motives minors =>
      cases fuel with
      | zero => simp [psMinOpInfer] at checked
      | succ remaining =>
        exact OperationalFoundation.primitiveModel (dataModel specs) remaining (psMinRegSpecCount specs)
          schema level parameters indices motives minors type checked
    | projection slot field =>
      cases fuel with
      | zero => simp [psMinOpInfer] at checked
      | succ remaining => exact OperationalProjection.projectionModel specs slot field type checked
    | _ => exact OperationalProofs.inferModel fuel specs globals locals _ type G L checked

noncomputable def actualRecursors (specs : List PsMinRegSpec) : RecursorModel specs (dataModel specs) :=
  RegularIngressAmbient.recursorModel specs

noncomputable def environment_history (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegCoreDefinition) (types : List PsMinRegTy)
    (h : psMinRegCoreCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    { output : Model (dataModel specs) types //
      DefinitionHistory (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs)
        [] declarations types (emptyModel (dataModel specs)) output } := by
  cases hv : psMinRegRegistryValid termFuel specs with
  | false => simp [psMinRegCoreCheckEnvironment, hv] at h
  | true =>
    have hs : psMinRegCoreCheckDefinitions termFuel declarationFuel specs [] declarations = some types := by
      simpa [psMinRegCoreCheckEnvironment, hv] using h
    exact definitions_history (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs)
      termFuel declarationFuel [] declarations types (emptyModel (dataModel specs)) hs

theorem environment_has_model (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegCoreDefinition) (types : List PsMinRegTy)
    (h : psMinRegCoreCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    Nonempty (Model (dataModel specs) types) :=
  ⟨(environment_history termFuel declarationFuel specs declarations types h).val⟩

theorem environment_consistent (termFuel declarationFuel queryFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegCoreDefinition) (types : List PsMinRegTy)
    (h : psMinRegCoreCheckEnvironment termFuel declarationFuel specs declarations = some types)
    (term : PsMinRegCoreTerm) :
    psMinRegCoreInfer queryFuel specs types [] term ≠ some PsMinRegTy.empty := by
  intro impossible
  let model := (environment_history termFuel declarationFuel specs declarations types h).val
  exact Empty.elim (evaluate_checked (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs)
    queryFuel types [] term .empty model (emptyModel (dataModel specs)) impossible).val

#print axioms evaluate_checked
#print axioms definitions_history
#print axioms environment_history
#print axioms environment_has_model
#print axioms environment_consistent
end Ps.MinKernel.RegularIngressOperationalModel
