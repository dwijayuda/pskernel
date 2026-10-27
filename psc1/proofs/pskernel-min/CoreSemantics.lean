import CoreTranslation

namespace Ps.MinKernel.CoreSemantics
open Ps.MinKernel.RegularModel
open Ps.MinKernel.RegularProofs
open Ps.MinKernel.CoreTranslation
open Ps.MinKernel.CoreIngress

-- Independent denotational rules. These contain no call to source translation
-- or to the operational checker; their values use the concrete R2/R3 model.
inductive OpEval (globals : List PsMinRegTy)
    (G : Model ([]) globals) :
    (locals : List PsMinRegTy) → Model ([]) locals →
    PsMinOpTerm → (type : PsMinRegTy) → Denote ([]) type → Prop where
  | base (locals L expression type fuel)
      (h : psMinRegInfer fuel [] globals locals expression = some type) :
      OpEval globals G locals L (.base expression) type
        (RegularProofs.inferModel fuel [] ([]) globals locals expression type
          (signatures []) G L h)
  | primitive (locals L schema level parameters indices motives minors) :
      OpEval globals G locals L (.primitive schema level parameters indices motives minors)
        (psMinOpPrimitiveSignature schema) (OperationalFoundation.primitiveValue ([]) schema)
  | lam (locals L domain body result) (fn : Denote ([]) domain → Denote ([]) result)
      (hb : ∀ value, OpEval globals G (domain :: locals) (consModel ([]) value L)
        body result (fn value)) :
      OpEval globals G locals L (.lam domain body) (.arr domain result) fn
  | app (locals L fn argument domain result)
      (f : Denote ([]) domain → Denote ([]) result)
      (a : Denote ([]) domain)
      (hf : OpEval globals G locals L fn (.arr domain result) f)
      (ha : OpEval globals G locals L argument domain a) :
      OpEval globals G locals L (.app fn argument) result (f a)
  | letE (locals L type value body result) (v : Denote ([]) type)
      (b : Denote ([]) result)
      (hv : OpEval globals G locals L value type v)
      (hb : OpEval globals G (type :: locals) (consModel ([]) v L) body result b) :
      OpEval globals G locals L (.letE type value body) result b

theorem infer_evaluates (fuel : Nat)
    (globals locals : List PsMinRegTy) (expression : PsMinOpTerm) (type : PsMinRegTy)
    (G : Model ([]) globals) (L : Model ([]) locals)
    (h : psMinOpInfer fuel [] globals locals expression = some type) :
    OpEval globals G locals L expression type
      (OperationalProofs.inferModel fuel [] globals locals expression type G L h) := by
  induction fuel generalizing locals expression type with
  | zero => simp [psMinOpInfer] at h
  | succ remaining ih =>
    cases expression with
    | base expression => exact .base locals L expression type remaining h
    | projection slot field => simp [psMinOpInfer, psMinOpProjectionType] at h
    | primitive schema level parameters indices motives minors =>
      have ht := OperationalFoundation.primitiveType_signature remaining (0)
        schema level parameters indices motives minors type h
      subst type
      simpa -implicitDefEqProofs only [OperationalProofs.inferModel, Nat.recAux, OperationalFoundation.primitiveModel] using!
        (OpEval.primitive (globals := globals) (G := G) locals L schema level parameters indices motives minors)
    | lam domain body =>
      unfold OperationalProofs.inferModel
      dsimp only [Nat.recAux]
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount []) domain with
      | false => simp [psMinOpInfer, hv] at h
      | true =>
        cases hb : psMinOpInfer remaining [] globals (domain :: locals) body with
        | none => simp [psMinOpInfer, hv, hb] at h
        | some result =>
          have ht : .arr domain result = type := by simpa [psMinOpInfer, hv, hb] using h
          cases ht
          apply OpEval.lam
          intro value
          simpa -implicitDefEqProofs only [] using!
            ih (domain :: locals) body result (consModel ([]) value L) hb
    | app fn argument =>
      unfold OperationalProofs.inferModel
      dsimp only [Nat.recAux]
      cases hf : psMinOpInfer remaining [] globals locals fn with
      | none => simp [psMinOpInfer, hf] at h
      | some functionType =>
        cases functionType with
        | arr domain result =>
          cases ha : psMinOpInfer remaining [] globals locals argument with
          | none => simp [psMinOpInfer, hf, ha] at h
          | some argumentType =>
            cases heq : psMinRegTyEq remaining domain argumentType with
            | false => simp [psMinOpInfer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [psMinOpInfer, hf, ha, heq] using h
              have same := typeEq_sound remaining _ _ heq
              cases same
              subst type
              simpa -implicitDefEqProofs only [] using!
                OpEval.app locals L fn argument domain result
                  (OperationalProofs.inferModel remaining [] globals locals fn (.arr domain result) G L hf)
                  (OperationalProofs.inferModel remaining [] globals locals argument domain G L ha)
                  (ih locals fn (.arr domain result) L hf) (ih locals argument domain L ha)
        | _ => simp [psMinOpInfer, hf] at h
    | letE annotation value body =>
      unfold OperationalProofs.inferModel
      dsimp only [Nat.recAux]
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount []) annotation with
      | false => simp [psMinOpInfer, hv] at h
      | true =>
        cases hb : psMinOpInfer remaining [] globals locals value with
        | none => simp [psMinOpInfer, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq remaining inferred annotation with
          | false => simp [psMinOpInfer, hv, hb, heq] at h
          | true =>
            have same := typeEq_sound remaining _ _ heq
            cases same
            have hs : psMinOpInfer remaining [] globals (annotation :: locals) body = some type := by
              simpa [psMinOpInfer, hv, hb, heq] using h
            let v := OperationalProofs.inferModel remaining [] globals locals value annotation G L hb
            simpa -implicitDefEqProofs only [] using!
              OpEval.letE locals L annotation value body type v
                (OperationalProofs.inferModel remaining [] globals (annotation :: locals) body type
                  G (consModel ([]) v L) hs)
                (ih locals value annotation L hb)
                (ih (annotation :: locals) body type (consModel ([]) v L) hs)

-- Direct meanings of the selected *source* constants and typed instances.
inductive PrimitiveDenotation : PsMinCoreExpr → (type : PsMinRegTy) → Denote [] type → Prop where
  | head0 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [85, 110, 105, 116]) [117, 110, 105, 116]) []) (.unit) (())
  | head1 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [102, 97, 108, 115, 101]) []) (.boolean) (false)
  | head2 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [116, 114, 117, 101]) []) (.boolean) (true)
  | head3 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [122, 101, 114, 111]) []) (.nat) ((0 : Nat))
  | head4 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 99, 99]) []) (.arr .nat .nat) (Nat.succ)
  | head5 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [97, 100, 100]) []) (.arr .nat (.arr .nat .nat)) (Nat.add)
  | head6 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 98]) []) (.arr .nat (.arr .nat .nat)) (Nat.sub)
  | head7 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 101, 113]) []) (.arr .nat (.arr .nat .boolean)) (Nat.beq)
  | head8 : PrimitiveDenotation (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 108, 116]) []) (.arr .nat (.arr .nat .boolean)) (Nat.blt)
  | listNil (element a) (ht : TypeImage element a) :
      PrimitiveDenotation (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) []) element) (.list a) ([] : List (Denote [] a))
  | listCons (element a) (ht : TypeImage element a) :
      PrimitiveDenotation (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) []) element) (.arr a (.arr (.list a) (.list a)))
        (@List.cons (Denote [] a))
  | optionNone (element a) (ht : TypeImage element a) :
      PrimitiveDenotation (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) []) element) (.option a) (none : Option (Denote [] a))
  | optionSome (element a) (ht : TypeImage element a) :
      PrimitiveDenotation (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) []) element) (.arr a (.option a))
        (@Option.some (Denote [] a))

inductive CoreEval (names : List PsMinCoreName) (globals : List PsMinRegTy) (G : Model [] globals) :
    (locals : List PsMinRegTy) → Model [] locals →
    PsMinCoreExpr → (type : PsMinRegTy) → Denote [] type → Prop where
  | variable (locals L index type) (lookup : psMinRegLookup locals index = some type) :
      CoreEval names globals G locals L (.bvar index) type (L index type lookup)
  | constant (locals L name index type) (identity : nameAt names index = some name)
      (lookup : psMinRegLookup globals index = some type) :
      CoreEval names globals G locals L (.constant name []) type (G index type lookup)
  | natural (locals L value) : CoreEval names globals G locals L (.natural value) .nat value
  | primitive (locals L source type value) (meaning : PrimitiveDenotation source type value) :
      CoreEval names globals G locals L source type value
  | app (locals L fn argument domain result) (f : Denote [] domain → Denote [] result) (a : Denote [] domain)
      (hf : CoreEval names globals G locals L fn (.arr domain result) f)
      (ha : CoreEval names globals G locals L argument domain a) :
      CoreEval names globals G locals L (.app fn argument) result (f a)
  | lam (locals L name binder sourceType body domain result) (fn : Denote [] domain → Denote [] result)
      (ht : TypeImage sourceType domain)
      (hb : ∀ value, CoreEval names globals G (domain :: locals) (consModel [] value L) body result (fn value)) :
      CoreEval names globals G locals L (.lam name binder sourceType body) (.arr domain result) fn
  | letE (locals L name sourceType value body type result) (v : Denote [] type) (b : Denote [] result)
      (ht : TypeImage sourceType type) (hv : CoreEval names globals G locals L value type v)
      (hb : CoreEval names globals G (type :: locals) (consModel [] v L) body result b) :
      CoreEval names globals G locals L (.letE name sourceType value body) result b
  | conditional (locals L sourceType left right yes no result)
      (l r : Bool) (y n : Denote [] result)
      (ht : TypeImage sourceType result)
      (hl : CoreEval names globals G locals L left .boolean l)
      (hr : CoreEval names globals G locals L right .boolean r)
      (hy : CoreEval names globals G locals L yes result y)
      (hn : CoreEval names globals G locals L no result n) :
      CoreEval names globals G locals L (conditionalSyntax sourceType left right yes no) result
        (@ite (Denote [] result) (l = r) (Bool.decEq l r) y n)

theorem primitive_semantics (globals locals : List PsMinRegTy) (G : Model [] globals)
    (L : Model [] locals) (source : PsMinCoreExpr) (term : PsMinOpTerm)
    (type : PsMinRegTy) (value : Denote [] type)
    (image : PrimitiveImage source term) (evaluation : OpEval globals G locals L term type value) :
    PrimitiveDenotation source type value := by
  cases image with
  | head0 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      have ht : .unit = type := by simpa [psMinRegInfer] using checked
      cases ht
      simpa only [RegularProofs.inferModel] using PrimitiveDenotation.head0
  | head1 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      have ht : .boolean = type := by simpa [psMinRegInfer] using checked
      cases ht
      simpa only [RegularProofs.inferModel] using PrimitiveDenotation.head1
  | head2 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      have ht : .boolean = type := by simpa [psMinRegInfer] using checked
      cases ht
      simpa only [RegularProofs.inferModel] using PrimitiveDenotation.head2
  | head3 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      have ht : .nat = type := by simpa [psMinRegInfer] using checked
      cases ht
      simpa only [RegularProofs.inferModel] using PrimitiveDenotation.head3
  | head4 =>
    cases evaluation
    exact PrimitiveDenotation.head4
  | head5 =>
    cases evaluation
    exact PrimitiveDenotation.head5
  | head6 =>
    cases evaluation
    exact PrimitiveDenotation.head6
  | head7 =>
    cases evaluation
    exact PrimitiveDenotation.head7
  | head8 =>
    cases evaluation
    exact PrimitiveDenotation.head8

  | listNil element a ht => cases evaluation; exact PrimitiveDenotation.listNil element a ht
  | listCons element a ht => cases evaluation; exact PrimitiveDenotation.listCons element a ht
  | optionNone element a ht => cases evaluation; exact PrimitiveDenotation.optionNone element a ht
  | optionSome element a ht => cases evaluation; exact PrimitiveDenotation.optionSome element a ht

theorem translation_preserves_semantics (names : List PsMinCoreName)
    (source : PsMinCoreExpr) (term : PsMinOpTerm) (image : TermImage names source term)
    (globals locals : List PsMinRegTy) (G : Model [] globals) (L : Model [] locals)
    (type : PsMinRegTy) (value : Denote [] type)
    (evaluation : OpEval globals G locals L term type value) :
    CoreEval names globals G locals L source type value := by
  induction image generalizing locals type with
  | «variable» index =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      exact CoreEval.variable locals L index type checked
  | natural value =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      have ht : PsMinRegTy.nat = type := by simpa [psMinRegInfer] using checked
      cases ht
      exact CoreEval.natural locals L value
  | constant name index identity =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinRegInfer] at checked
    | succ remaining =>
      exact CoreEval.constant locals L name index type identity checked
  | primitive source term image =>
    exact CoreEval.primitive locals L source type value (primitive_semantics _ _ _ _ _ _ _ _ image evaluation)
  | app fn arg f a hf ha ihf iha =>
    cases evaluation
    apply CoreEval.app
    · exact ihf _ _ _ _ (by assumption)
    · exact iha _ _ _ _ (by assumption)
  | lam name binder sourceType body t b ht hb ih =>
    cases evaluation
    rename_i bodyEval
    apply CoreEval.lam
    · exact ht
    · intro argument
      exact ih _ _ _ _ (bodyEval argument)
  | letE name sourceType sourceValue body t v b ht hv hb ihv ihb =>
    cases evaluation
    apply CoreEval.letE
    · exact ht
    · exact ihv _ _ _ _ (by assumption)
    · exact ihb _ _ _ _ (by assumption)
  | conditional sourceType left right yes no t l r y n ht hl hr hy hn ihl ihr ihy ihn =>
    cases evaluation
    rename_i domain0 arg0 noEval fn0 head0
    cases head0
    rename_i domain1 arg1 yesEval fn1 head1
    cases head1
    rename_i domain2 arg2 rightEval fn2 head2
    cases head2
    rename_i domain3 arg3 leftEval fn3 primitiveEval
    cases primitiveEval
    apply CoreEval.conditional
    · exact ht
    · exact ihl _ _ _ _ leftEval
    · exact ihr _ _ _ _ rightEval
    · exact ihy _ _ _ _ yesEval
    · exact ihn _ _ _ _ noEval

theorem checked_source_semantics (translationFuel checkingFuel : Nat) (names : List PsMinCoreName)
    (source : PsMinCoreExpr) (term : PsMinOpTerm) (globals locals : List PsMinRegTy)
    (G : Model [] globals) (L : Model [] locals) (type : PsMinRegTy)
    (translated : psMinCoreTranslate translationFuel names source = some term)
    (checked : psMinOpInfer checkingFuel [] globals locals term = some type) :
    CoreEval names globals G locals L source type
      (OperationalProofs.inferModel checkingFuel [] globals locals term type G L checked) :=
  translation_preserves_semantics _ _ _ (term_translation _ _ _ _ translated)
    _ _ _ _ _ _ (infer_evaluates _ _ _ _ _ _ _ checked)

-- Source bodies keep their definition-time name and value contexts.
-- This history mentions only source syntax and the independent CoreEval rules.
inductive SourceHistory :
    (names : List PsMinCoreName) → (globals : List PsMinRegTy) →
    List PsMinCoreDeclaration → (result : List PsMinRegTy) →
    Model [] globals → Model [] result → Prop where
  | done (names globals) (model : Model [] globals) :
      SourceHistory names globals [] globals model model
  | step (names globals) (decl : PsMinCoreDeclaration) (rest result declaredType)
      (initial : Model [] globals) (output : Model [] result) (value : Denote [] declaredType)
      (fresh : psMinCoreFresh names decl.name = true)
      (typeMeaning : TypeImage decl.type declaredType)
      (bodyMeaning : CoreEval names globals initial [] (emptyModel []) decl.value declaredType value)
      (tail : SourceHistory (decl.name :: names) (declaredType :: globals) rest result
        (consModel [] value initial) output) :
      SourceHistory names globals (decl :: rest) result initial output

theorem checked_history_preserves_source (names : List PsMinCoreName) (globals : List PsMinRegTy)
    (source : List PsMinCoreDeclaration) (normalized : List PsMinOpDeclaration)
    (result : List PsMinRegTy) (initial : Model [] globals) (output : Model [] result)
    (image : EnvironmentImage names source normalized)
    (history : OperationalProofs.DefinitionHistory 128 [] globals normalized result initial output) :
    SourceHistory names globals source result initial output := by
  induction image generalizing globals result initial output with
  | nil names =>
    cases history using @OperationalProofs.DefinitionHistory.casesOn 128 []
    exact .done names globals initial
  | step names decl rest type value tail fresh ht hv next ih =>
    cases history using @OperationalProofs.DefinitionHistory.casesOn 128 [] with
    | step declaration rest inferred valid checked same output history =>
      have heq : inferred = type := typeEq_sound 128 _ _ same
      have body := translation_preserves_semantics names decl.value value hv
        globals [] initial (emptyModel []) inferred
        (OperationalProofs.inferModel 128 [] globals [] value inferred initial (emptyModel []) checked)
        (infer_evaluates 128 globals [] value inferred initial (emptyModel []) checked)
      cases heq
      exact .step names globals decl rest result type initial output
        (OperationalProofs.inferModel 128 [] globals [] value type initial (emptyModel []) checked)
        fresh ht body (ih _ _ _ _ history)

theorem canonical_source_model (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) :
    WellFormedBytes bytes accepted.source ∧
    EnvironmentImage [] accepted.source accepted.normalized ∧
    ∃ model, SourceHistory [] [] accepted.source accepted.types (emptyModel []) model := by
  obtain ⟨bytesExact, correspondence, modelExists, model, history⟩ :=
    canonical_admission_has_model bytes candidate accepted h
  have image := environment_translation 64 [] accepted.source accepted.normalized correspondence
  exact ⟨bytesExact, image, model,
    checked_history_preserves_source [] [] accepted.source accepted.normalized accepted.types
      (emptyModel []) model image history⟩

theorem canonical_no_empty_constant (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) (index : Nat) :
    psMinRegLookup accepted.types index ≠ some PsMinRegTy.empty := by
  intro impossible
  obtain ⟨_, _, modelExists, _⟩ := canonical_admission_has_model bytes candidate accepted h
  obtain ⟨model⟩ := modelExists
  exact Empty.elim (model index .empty impossible)

#print axioms infer_evaluates
#print axioms primitive_semantics
#print axioms translation_preserves_semantics
#print axioms checked_source_semantics
#print axioms checked_history_preserves_source
#print axioms canonical_source_model
#print axioms canonical_no_empty_constant
end Ps.MinKernel.CoreSemantics
