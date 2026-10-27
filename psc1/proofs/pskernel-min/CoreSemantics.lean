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

noncomputable def evaluate_checked (fuel : Nat)
    (globals locals : List PsMinRegTy) (expression : PsMinOpTerm) (type : PsMinRegTy)
    (G : Model [] globals) (L : Model [] locals)
    (h : psMinOpInfer fuel [] globals locals expression = some type) :
    { value : Denote [] type // OpEval globals G locals L expression type value } := by
  induction fuel generalizing locals expression type with
  | zero => simp [psMinOpInfer] at h
  | succ remaining ih =>
    cases expression with
    | base expression =>
      exact ⟨RegularProofs.inferModel remaining [] [] globals locals expression type
        (signatures []) G L h, .base locals L expression type remaining h⟩
    | projection slot field => simp [psMinOpInfer, psMinOpProjectionType] at h
    | primitive schema level parameters indices motives minors =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount [])
        schema level parameters indices motives minors type h
      subst type
      exact ⟨OperationalFoundation.primitiveValue [] schema,
        .primitive locals L schema level parameters indices motives minors⟩
    | lam domain body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount []) domain with
      | false => simp [psMinOpInfer, hv] at h
      | true =>
        cases hb : psMinOpInfer remaining [] globals (domain :: locals) body with
        | none => simp [psMinOpInfer, hv, hb] at h
        | some result =>
          have ht : .arr domain result = type := by simpa [psMinOpInfer, hv, hb] using h
          subst type
          let values := fun value => ih (domain :: locals) body result (consModel [] value L) hb
          exact ⟨fun value => (values value).val,
            .lam locals L domain body result (fun value => (values value).val)
              (fun value => (values value).property)⟩
    | app fn argument =>
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
              let f := ih locals fn (.arr domain result) L hf
              let a := ih locals argument domain L ha
              exact ⟨f.val a.val, .app locals L fn argument domain result f.val a.val f.property a.property⟩
        | _ => simp [psMinOpInfer, hf] at h
    | letE annotation value body =>
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
            let v := ih locals value annotation L hb
            let b := ih (annotation :: locals) body type (consModel [] v.val L) hs
            exact ⟨b.val, .letE locals L annotation value body type v.val b.val v.property b.property⟩

theorem infer_evaluates (fuel : Nat) (globals locals : List PsMinRegTy)
    (expression : PsMinOpTerm) (type : PsMinRegTy) (G : Model [] globals) (L : Model [] locals)
    (h : psMinOpInfer fuel [] globals locals expression = some type) :
    OpEval globals G locals L expression type (evaluate_checked fuel globals locals expression type G L h).val :=
  (evaluate_checked fuel globals locals expression type G L h).property

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
      (evaluate_checked checkingFuel globals locals term type G L checked).val :=
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

theorem environment_head (names : List PsMinCoreName) (decl : PsMinCoreDeclaration)
    (rest : List PsMinCoreDeclaration) (head : PsMinOpDeclaration) (tail : List PsMinOpDeclaration)
    (image : EnvironmentImage names (decl :: rest) (head :: tail)) :
    psMinCoreFresh names decl.name = true ∧ TypeImage decl.type head.type ∧
    TermImage names decl.value head.value ∧ EnvironmentImage (decl.name :: names) rest tail := by
  cases image
  exact ⟨by assumption, by assumption, by assumption, by assumption⟩

noncomputable def checked_source_history (declarationFuel : Nat) (names : List PsMinCoreName)
    (globals : List PsMinRegTy) (source : List PsMinCoreDeclaration) (normalized : List PsMinOpDeclaration)
    (result : List PsMinRegTy) (initial : Model [] globals)
    (image : EnvironmentImage names source normalized)
    (checked : psMinOpCheckDeclarations 128 declarationFuel [] globals normalized = some result) :
    { output : Model [] result // SourceHistory names globals source result initial output } := by
  induction declarationFuel generalizing names globals source normalized result with
  | zero =>
    cases normalized with
    | nil =>
      have hs : source = [] := by cases image; rfl
      subst source
      have ht : globals = result := by simpa [psMinOpCheckDeclarations] using checked
      subst result
      exact ⟨initial, .done names globals initial⟩
    | cons head tail => simp [psMinOpCheckDeclarations] at checked
  | succ fuel ih =>
    cases normalized with
    | nil =>
      have hs : source = [] := by cases image; rfl
      subst source
      have ht : globals = result := by simpa [psMinOpCheckDeclarations] using checked
      subst result
      exact ⟨initial, .done names globals initial⟩
    | cons head tail =>
      cases source with
      | nil =>
        have impossible : False := by cases image
        exact False.elim impossible
      | cons decl rest =>
        obtain ⟨fresh, ht, hv, next⟩ := environment_head names decl rest head tail image
        cases valid : psMinRegTyValid 128 (psMinRegSpecCount []) head.type with
        | false => simp [psMinOpCheckDeclarations, valid] at checked
        | true =>
          cases body : psMinOpInfer 128 [] globals [] head.value with
          | none => simp [psMinOpCheckDeclarations, valid, body] at checked
          | some inferred =>
            cases same : psMinRegTyEq 128 inferred head.type with
            | false => simp [psMinOpCheckDeclarations, valid, body, same] at checked
            | true =>
              have heq := typeEq_sound 128 _ _ same
              have onward : psMinOpCheckDeclarations 128 fuel [] (head.type :: globals) tail = some result := by
                simpa [psMinOpCheckDeclarations, valid, body, same] using checked
              let value := evaluate_checked 128 globals [] head.value inferred initial (emptyModel []) body
              have meaning := translation_preserves_semantics names decl.value head.value hv
                globals [] initial (emptyModel []) inferred value.val value.property
              let admitted : Denote [] head.type := heq ▸ value.val
              have sourceBody : CoreEval names globals initial [] (emptyModel []) decl.value head.type admitted := by
                cases heq
                exact meaning
              let remaining := ih (decl.name :: names) (head.type :: globals) rest tail result
                (consModel [] admitted initial) next onward
              exact ⟨remaining.val, .step names globals decl rest result head.type initial remaining.val
                admitted fresh ht sourceBody remaining.property⟩

theorem checked_history_preserves_source (declarationFuel : Nat) (names : List PsMinCoreName)
    (globals : List PsMinRegTy) (source : List PsMinCoreDeclaration) (normalized : List PsMinOpDeclaration)
    (result : List PsMinRegTy) (initial : Model [] globals)
    (image : EnvironmentImage names source normalized)
    (checked : psMinOpCheckDeclarations 128 declarationFuel [] globals normalized = some result) :
    ∃ output, SourceHistory names globals source result initial output :=
  ⟨_, (checked_source_history declarationFuel names globals source normalized result initial image checked).property⟩

theorem canonical_source_model (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) :
    WellFormedBytes bytes accepted.source ∧
    EnvironmentImage [] accepted.source accepted.normalized ∧
    ∃ model, SourceHistory [] [] accepted.source accepted.types (emptyModel []) model := by
  unfold psMinCoreAdmit at h
  cases hd : psMinCoreDecodeCertificate bytes candidate with
  | none => simp [hd] at h
  | some source =>
    cases ht : psMinCoreTranslateDeclarations 64 128 [] source with
    | none => simp [hd, ht] at h
    | some normalized =>
      cases hc : psMinOpCheckEnvironment 128 128 [] normalized with
      | none => simp [hd, ht, hc] at h
      | some types =>
        simp only [hd, ht, hc, Option.some.injEq] at h
        subst accepted
        have image := environment_translation 64 [] source normalized
          (translate_environment_preserves_identity 64 128 [] source normalized ht)
        have checked : psMinOpCheckDeclarations 128 128 [] [] normalized = some types := by
          simpa [psMinOpCheckEnvironment, psMinRegRegistryValid] using hc
        exact ⟨(decode_success_is_well_formed _ _ _ hd).2, image,
          checked_history_preserves_source 128 [] [] source normalized types (emptyModel []) image checked⟩

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
