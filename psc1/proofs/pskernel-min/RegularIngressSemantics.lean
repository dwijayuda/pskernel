import RegularIngressSource

namespace Ps.MinKernel.RegularIngressSemantics
open Ps.MinKernel.RegularModel
open Ps.MinKernel.RegularProofs
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.CoreTranslation
open Ps.MinKernel.RegularIngressTranslation
open Ps.MinKernel.RegularIngressTerms
open Ps.MinKernel.RegularIngressOperationalModel
open Ps.MinKernel.RegularIngressSource

abbrev CheckedEval (specs : List PsMinRegSpec) (globals : List PsMinRegTy)
    (G : Model (dataModel specs) globals) (locals : List PsMinRegTy)
    (L : Model (dataModel specs) locals) (term : PsMinRegCoreTerm)
    (type : PsMinRegTy) (value : Denote (dataModel specs) type) : Prop :=
  Eval (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs) globals G locals L term type value

inductive PrimitiveDenotation (data : List Type) (total visible : Nat) (groups : List PsMinRegCorePlan) : PsMinCoreExpr → (type : PsMinRegTy) → Denote data type → Prop where
  | head0 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [85, 110, 105, 116]) [117, 110, 105, 116]) []) (.unit) (())
  | head1 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [102, 97, 108, 115, 101]) []) (.boolean) (false)
  | head2 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [116, 114, 117, 101]) []) (.boolean) (true)
  | head3 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [122, 101, 114, 111]) []) (.nat) ((0 : Nat))
  | head4 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 99, 99]) []) (.arr .nat .nat) (Nat.succ)
  | head5 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [97, 100, 100]) []) (.arr .nat (.arr .nat .nat)) (Nat.add)
  | head6 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 98]) []) (.arr .nat (.arr .nat .nat)) (Nat.sub)
  | head7 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 101, 113]) []) (.arr .nat (.arr .nat .boolean)) (Nat.beq)
  | head8 : PrimitiveDenotation data total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 108, 116]) []) (.arr .nat (.arr .nat .boolean)) (Nat.blt)
  | listNil (element a) (ht : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveDenotation data total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) []) element) (.list a) ([] : List (Denote data a))
  | listCons (element a) (ht : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveDenotation data total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) []) element) (.arr a (.arr (.list a) (.list a)))
        (@List.cons (Denote data a))
  | optionNone (element a) (ht : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveDenotation data total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) []) element) (.option a) (none : Option (Denote data a))
  | optionSome (element a) (ht : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveDenotation data total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) []) element) (.arr a (.option a))
        (@Option.some (Denote data a))

inductive RecursorDenotation (specs : List PsMinRegSpec) (total visible : Nat) (groups : List PsMinRegCorePlan) :
    PsMinCoreExpr → (type : PsMinRegTy) → Denote (dataModel specs) type → Prop where
  | nat (motive result)
      (meaning : MotiveImage total visible groups
        (.constant (.str PsMinCoreName.anonymous [78,97,116]) []) motive result) :
      RecursorDenotation specs total visible groups
        (.app (.constant (.str (.str PsMinCoreName.anonymous [78,97,116]) [114,101,99]) [1]) motive)
        (psMinOpPrimitiveSignature (.natRec result))
        (OperationalFoundation.primitiveValue (dataModel specs) (.natRec result))
  | list (element motive a result)
      (elementType : RegularIngressTranslation.TypeImage total visible groups element a)
      (elementSort : sourceSort a = 1)
      (meaning : MotiveImage total visible groups
        (.app (.constant (.str PsMinCoreName.anonymous [76,105,115,116]) []) element) motive result) :
      RecursorDenotation specs total visible groups
        (.app (.app (.constant (.str (.str PsMinCoreName.anonymous [76,105,115,116]) [114,101,99]) [1]) element) motive)
        (psMinOpPrimitiveSignature (.listRec a result))
        (OperationalFoundation.primitiveValue (dataModel specs) (.listRec a result))
  | option (element motive a result)
      (elementType : RegularIngressTranslation.TypeImage total visible groups element a)
      (elementSort : sourceSort a = 1)
      (meaning : MotiveImage total visible groups
        (.app (.constant (.str PsMinCoreName.anonymous [79,112,116,105,111,110]) []) element) motive result) :
      RecursorDenotation specs total visible groups
        (.app (.app (.constant (.str (.str PsMinCoreName.anonymous [79,112,116,105,111,110]) [114,101,99]) [1]) element) motive)
        (psMinOpPrimitiveSignature (.optionRec a result))
        (OperationalFoundation.primitiveValue (dataModel specs) (.optionRec a result))
  | regular (name owner slot minors motive result type)
      (binding : RecursorBinding total visible groups name owner slot minors)
      (meaning : MotiveImage total visible groups (.constant owner []) motive result)
      (signature : psMinRegCoreAmbientRecursorType specs slot result = some type) :
      RecursorDenotation specs total visible groups (.app (.constant name [1]) motive) type
        (actualRecursors specs slot result type signature)

inductive CoreEval (specs : List PsMinRegSpec) (total visible : Nat) (groups : List PsMinRegCorePlan) (names : List PsMinCoreName) (globals : List PsMinRegTy) (G : Model (dataModel specs) globals) :
    (locals : List PsMinRegTy) → Model (dataModel specs) locals →
    PsMinCoreExpr → (type : PsMinRegTy) → Denote (dataModel specs) type → Prop where
  | variable (locals L index type) (lookup : psMinRegLookup locals index = some type) :
      CoreEval specs total visible groups names globals G locals L (.bvar index) type (L index type lookup)
  | constant (locals L name index type) (identity : nameAt names index = some name)
      (lookup : psMinRegLookup globals index = some type) :
      CoreEval specs total visible groups names globals G locals L (.constant name []) type (G index type lookup)
  | natural (locals L value) : CoreEval specs total visible groups names globals G locals L (.natural value) .nat value
  | primitive (locals L source type value) (meaning : PrimitiveDenotation (dataModel specs) total visible groups source type value) :
      CoreEval specs total visible groups names globals G locals L source type value
  | recursor (locals L source type value)
      (meaning : RecursorDenotation specs total visible groups source type value) :
      CoreEval specs total visible groups names globals G locals L source type value
  | construct (locals L name slot index type)
      (binding : ConstructorBinding total visible groups name slot index)
      (signature : psMinRegCtorTypeAt specs slot index = some type) :
      CoreEval specs total visible groups names globals G locals L (.constant name []) type
        ((signatures specs).ctorValue slot index type signature)
  | projection (locals L owner field major slot result)
      (ownerType : RegularIngressTranslation.TypeImage total visible groups (.constant owner []) (.data slot))
      (signature : psMinOpProjectionType specs slot field = some (.arr (.data slot) result))
      (value : Denote (dataModel specs) (.data slot))
      (majorValue : CoreEval specs total visible groups names globals G locals L major (.data slot) value) :
      CoreEval specs total visible groups names globals G locals L (.projection owner field major) result
        (OperationalProjection.projectionModel specs slot field (.arr (.data slot) result) signature value)

  | app (locals L fn argument domain result) (f : Denote (dataModel specs) domain → Denote (dataModel specs) result) (a : Denote (dataModel specs) domain)
      (hf : CoreEval specs total visible groups names globals G locals L fn (.arr domain result) f)
      (ha : CoreEval specs total visible groups names globals G locals L argument domain a) :
      CoreEval specs total visible groups names globals G locals L (.app fn argument) result (f a)
  | lam (locals L name binder sourceType body domain result) (fn : Denote (dataModel specs) domain → Denote (dataModel specs) result)
      (ht : RegularIngressTranslation.TypeImage total visible groups sourceType domain)
      (hb : ∀ value, CoreEval specs total visible groups names globals G (domain :: locals) (consModel (dataModel specs) value L) body result (fn value)) :
      CoreEval specs total visible groups names globals G locals L (.lam name binder sourceType body) (.arr domain result) fn
  | letE (locals L name sourceType value body type result) (v : Denote (dataModel specs) type) (b : Denote (dataModel specs) result)
      (ht : RegularIngressTranslation.TypeImage total visible groups sourceType type) (hv : CoreEval specs total visible groups names globals G locals L value type v)
      (hb : CoreEval specs total visible groups names globals G (type :: locals) (consModel (dataModel specs) v L) body result b) :
      CoreEval specs total visible groups names globals G locals L (.letE name sourceType value body) result b
  | conditional (locals L sourceType left right yes no result)
      (l r : Bool) (y n : Denote (dataModel specs) result)
      (ht : RegularIngressTranslation.TypeImage total visible groups sourceType result) (sort : sourceSort result = 1)
      (hl : CoreEval specs total visible groups names globals G locals L left .boolean l)
      (hr : CoreEval specs total visible groups names globals G locals L right .boolean r)
      (hy : CoreEval specs total visible groups names globals G locals L yes result y)
      (hn : CoreEval specs total visible groups names globals G locals L no result n) :
      CoreEval specs total visible groups names globals G locals L (conditionalSyntax sourceType left right yes no) result
        (@ite (Denote (dataModel specs) result) (l = r) (Bool.decEq l r) y n)

theorem primitive_semantics (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (globals locals : List PsMinRegTy)
    (G : Model (dataModel specs) globals) (L : Model (dataModel specs) locals)
    (source : PsMinCoreExpr) (atom : PsMinOpTerm) (type : PsMinRegTy) (value : Denote (dataModel specs) type)
    (image : RegularIngressTerms.PrimitiveImage total visible groups source atom)
    (evaluation : CheckedEval specs globals G locals L (.ordinary atom) type value) :
    PrimitiveDenotation (dataModel specs) total visible groups source type value := by
  cases image with
  | head0 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have ht : PsMinRegTy.unit = type := by simpa [psMinOpInfer, psMinRegInfer] using checked
        subst type
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (PrimitiveDenotation.head0 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head1 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have ht : PsMinRegTy.boolean = type := by simpa [psMinOpInfer, psMinRegInfer] using checked
        subst type
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (PrimitiveDenotation.head1 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head2 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have ht : PsMinRegTy.boolean = type := by simpa [psMinOpInfer, psMinRegInfer] using checked
        subst type
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (PrimitiveDenotation.head2 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head3 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have ht : PsMinRegTy.nat = type := by simpa [psMinOpInfer, psMinRegInfer] using checked
        subst type
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (PrimitiveDenotation.head3 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head4 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natSucc 0 0 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.head4 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head5 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natAdd 0 0 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.head5 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head6 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natSub 0 0 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.head6 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head7 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natBeq 0 0 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.head7 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head8 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natBlt 0 0 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.head8 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | listNil element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listNil a) 0 1 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.listNil element a ht sort)
  | listCons element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listCons a) 0 1 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.listCons element a ht sort)
  | optionNone element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionNone a) 0 1 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.optionNone element a ht sort)
  | optionSome element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionSome a) 0 1 0 0 0 type checked
      subst type
      exact (PrimitiveDenotation.optionSome element a ht sort)

theorem recursor_semantics (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (globals locals : List PsMinRegTy)
    (G : Model (dataModel specs) globals) (L : Model (dataModel specs) locals)
    (source : PsMinCoreExpr) (term : PsMinRegCoreTerm) (type : PsMinRegTy) (value : Denote (dataModel specs) type)
    (image : RecursorImage total visible groups source term)
    (evaluation : CheckedEval specs globals G locals L term type value) :
    RecursorDenotation specs total visible groups source type value := by
  cases image with
  | nat motive result meaning =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.natRec result) 1 0 0 1 2 type checked
      subst type
      exact (RecursorDenotation.nat motive result meaning)
  | list element motive a result elementType elementSort meaning =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listRec a result) 1 1 0 1 2 type checked
      subst type
      exact (RecursorDenotation.list element motive a result elementType elementSort meaning)
  | option element motive a result elementType elementSort meaning =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionRec a result) 1 1 0 1 2 type checked
      subst type
      exact (RecursorDenotation.option element motive a result elementType elementSort meaning)
  | regular name owner slot minors motive result binding meaning =>
    cases evaluation
    exact RecursorDenotation.regular name owner slot minors motive result type binding meaning (by assumption)

theorem projection_type_domain (specs : List PsMinRegSpec) (slot field : Nat) (type : PsMinRegTy)
    (h : psMinOpProjectionType specs slot field = some type) :
    ∃ result, type = .arr (.data slot) result := by
  induction specs generalizing slot type with
  | nil => simp [psMinOpProjectionType] at h
  | cons spec rest ih =>
    cases slot with
    | zero =>
      cases hc : spec.constructors with
      | nil => simp [psMinOpProjectionType, hc] at h
      | cons fields others =>
        cases others with
        | cons other more => simp [psMinOpProjectionType, hc] at h
        | nil =>
          cases hf : psMinOpFieldType fields field with
          | none => simp [psMinOpProjectionType, hc, hf] at h
          | some result =>
            have equal : .arr (.data 0) result = type := by
              simpa [psMinOpProjectionType, hc, hf] using h
            exact ⟨result, equal.symm⟩
    | succ slot =>
      cases hp : psMinOpProjectionType rest slot field with
      | none => simp [psMinOpProjectionType, hp] at h
      | some prior =>
        obtain ⟨result, equal⟩ := ih slot prior hp
        subst prior
        have lifted : psMinRegLiftTy (.arr (.data slot) result) = type := by
          simpa [psMinOpProjectionType, hp] using h
        subst type
        exact ⟨psMinRegLiftTy result, rfl⟩

theorem translation_preserves_semantics (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (names : List PsMinCoreName)
    (source : PsMinCoreExpr) (term : PsMinRegCoreTerm)
    (image : TermImage total visible groups names source term)
    (globals locals : List PsMinRegTy) (G : Model (dataModel specs) globals)
    (L : Model (dataModel specs) locals) (type : PsMinRegTy) (value : Denote (dataModel specs) type)
    (evaluation : CheckedEval specs globals G locals L term type value) :
    CoreEval specs total visible groups names globals G locals L source type value := by
  induction image generalizing locals type with
  | «variable» index =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (CoreEval.variable locals L index type checked)
  | natural value =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have equal : PsMinRegTy.nat = type := by simpa [psMinOpInfer, psMinRegInfer] using checked
        subst type
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (CoreEval.natural locals L value)
  | constant name index identity =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (CoreEval.constant locals L name index type identity checked)
  | primitive source atom image =>
    exact CoreEval.primitive locals L source type value
      (primitive_semantics _ _ _ _ _ _ _ _ _ _ _ _ image evaluation)
  | recursor source term image =>
    exact CoreEval.recursor locals L source type value
      (recursor_semantics _ _ _ _ _ _ _ _ _ _ _ _ image evaluation)
  | construct name slot index binding =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      cases remaining with
      | zero => simp [psMinOpInfer, psMinRegInfer] at checked
      | succ remaining =>
        have signature : psMinRegCtorTypeAt specs slot index = some type := checked
        simpa only [actualOrdinary, OperationalProofs.inferModel, RegularProofs.inferModel] using
          (CoreEval.construct locals L name slot index type binding signature)
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
  | projection owner field major slot term ownerType majorImage ih =>
    cases evaluation
    rename_i domain argument majorEval fn headEval
    cases headEval
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      obtain ⟨result, identity⟩ := projection_type_domain specs slot field (.arr domain type) checked
      cases identity
      simpa only [actualOrdinary, OperationalProofs.inferModel] using
        (CoreEval.projection locals L owner field major slot type ownerType checked argument
          (ih _ _ _ _ majorEval))
  | conditional sourceType left right yes no t l r y n ht sort hl hr hy hn ihl ihr ihy ihn =>
    cases evaluation
    rename_i domain0 arg0 noEval fn0 head0
    cases head0
    rename_i domain1 arg1 yesEval fn1 head1
    cases head1
    rename_i domain2 arg2 rightEval fn2 head2
    cases head2
    rename_i domain3 arg3 leftEval fn3 primitiveEval
    cases primitiveEval
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have signature := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.boolEqIte t) 1 1 0 0 0 (.arr domain3 (.arr domain2 (.arr domain1 (.arr domain0 type)))) checked
      cases signature
      apply CoreEval.conditional
      · exact ht
      · exact sort
      · exact ihl _ _ _ _ leftEval
      · exact ihr _ _ _ _ rightEval
      · exact ihy _ _ _ _ yesEval
      · exact ihn _ _ _ _ noEval

theorem checked_source_semantics (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (names : List PsMinCoreName)
    (translationFuel checkingFuel : Nat) (source : PsMinCoreExpr) (term : PsMinRegCoreTerm)
    (globals locals : List PsMinRegTy) (G : Model (dataModel specs) globals)
    (L : Model (dataModel specs) locals) (type : PsMinRegTy)
    (translated : psMinRegCoreTranslate translationFuel total visible groups names source = some term)
    (checked : psMinRegCoreInfer checkingFuel specs globals locals term = some type) :
    CoreEval specs total visible groups names globals G locals L source type
      (evaluate_checked (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs)
        checkingFuel globals locals term type G L checked).val :=
  translation_preserves_semantics specs total visible groups names source term
    (term_translation _ _ _ _ _ _ _ translated) globals locals G L type _
    (evaluate_checked (dataModel specs) specs (actualOrdinary specs) (actualRecursors specs)
      checkingFuel globals locals term type G L checked).property

#print axioms translation_preserves_semantics
#print axioms checked_source_semantics

-- The source history keeps each original body in its declaration-time context.
inductive SourceHistory (specs : List PsMinRegSpec) (total : Nat) (groups : List PsMinRegCorePlan) :
    Nat → List PsMinCoreName → (globals : List PsMinRegTy) →
    List PsMinRegCoreEntry → (result : List PsMinRegTy) →
    Model (dataModel specs) globals → Model (dataModel specs) result → Prop where
  | done (visible names globals) (model : Model (dataModel specs) globals) :
      SourceHistory specs total groups visible names globals [] globals model model
  | group (visible names globals) (source : PsMinRegCoreGroup) (rest result)
      (initial : Model (dataModel specs) globals) (output : Model (dataModel specs) result)
      (tail : SourceHistory specs total groups (Nat.succ visible) names globals rest result initial output) :
      SourceHistory specs total groups visible names globals (.inductiveE source :: rest) result initial output
  | definition (visible names globals) (source : PsMinCoreDeclaration) (rest result type)
      (initial : Model (dataModel specs) globals) (output : Model (dataModel specs) result)
      (value : Denote (dataModel specs) type)
      (typeExact : psMinRegCoreType 256 total visible groups source.type = some type)
      (typeMeaning : RegularIngressTranslation.TypeImage total visible groups source.type type)
      (body : CoreEval specs total visible groups names globals initial [] (emptyModel (dataModel specs))
        source.value type value)
      (tail : SourceHistory specs total groups visible (source.name :: names) (type :: globals)
        rest result (consModel (dataModel specs) value initial) output) :
      SourceHistory specs total groups visible names globals (.definition source :: rest) result initial output

theorem normalized_history_head (specs : List PsMinRegSpec) (globals result : List PsMinRegTy)
    (type : PsMinRegTy) (term : PsMinRegCoreTerm) (rest : List PsMinRegCoreDefinition)
    (initial : Model (dataModel specs) globals) (output : Model (dataModel specs) result)
    (history : RegularIngressOperationalModel.DefinitionHistory (dataModel specs) specs
      (actualOrdinary specs) (actualRecursors specs) globals (⟨type,term⟩ :: rest) result initial output) :
    ∃ value : Denote (dataModel specs) type,
      CheckedEval specs globals initial [] (emptyModel (dataModel specs)) term type value ∧
      RegularIngressOperationalModel.DefinitionHistory (dataModel specs) specs
        (actualOrdinary specs) (actualRecursors specs) (type :: globals) rest result
        (consModel (dataModel specs) value initial) output := by
  cases history
  exact ⟨_, by assumption, by assumption⟩

theorem history_preserves_source (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (names : List PsMinCoreName)
    (source : List PsMinRegCoreEntry) (normalized : List PsMinRegCoreDefinition)
    (image : EnvironmentImage total groups visible names source normalized)
    (globals result : List PsMinRegTy) (initial : Model (dataModel specs) globals)
    (output : Model (dataModel specs) result)
    (history : RegularIngressOperationalModel.DefinitionHistory (dataModel specs) specs
      (actualOrdinary specs) (actualRecursors specs) globals normalized result initial output) :
    SourceHistory specs total groups visible names globals source result initial output := by
  induction image generalizing globals result with
  | nil visible names =>
    cases history
    exact .done visible names globals initial
  | group visible names source rest normalized tail ih =>
    exact .group visible names globals source rest result initial output (ih _ _ _ _ history)
  | definition visible names source rest type term normalized typeExact typeMeaning body tail ih =>
    obtain ⟨value, bodyEval, tailHistory⟩ := normalized_history_head specs globals result type term normalized initial output history
    exact .definition visible names globals source rest result type initial output value typeExact typeMeaning
      (translation_preserves_semantics specs total visible groups names source.value term body globals []
        initial (emptyModel (dataModel specs)) type value bodyEval)
      (ih _ _ _ _ tailHistory)

theorem checked_entries_source_image (source : List PsMinRegCoreEntry) (checked : PsMinRegCoreChecked)
    (h : psMinRegCoreCheckEntries source = some checked) :
    EnvironmentImage checked.plans.count checked.plans.groups 0 [] source checked.normalized := by
  unfold psMinRegCoreCheckEntries at h
  cases hp : psMinRegCorePlans source with
  | none => simp [hp] at h
  | some state =>
    simp only [hp] at h
    split at h
    next signatures =>
      cases ht : psMinRegCoreTranslateEntries 512 state.count 0 state.groups [] source with
      | none => simp [ht] at h
      | some normalized =>
        cases hc : psMinRegCoreCheckEnvironment 512 512 (psMinRegCoreSpecs state.groups) normalized with
        | none => simp [ht, hc] at h
        | some types =>
          simp only [ht, hc, Option.some.injEq] at h
          subst checked
          exact environment_translation _ _ _ _ _ _ _ ht
    next => contradiction

theorem checked_source_model (source : List PsMinRegCoreEntry) (checked : PsMinRegCoreChecked)
    (h : psMinRegCoreCheckEntries source = some checked) :
    ∃ output : Model (dataModel (psMinRegCoreSpecs checked.plans.groups)) checked.types,
      SourceHistory (psMinRegCoreSpecs checked.plans.groups) checked.plans.count checked.plans.groups
        0 [] [] source checked.types (emptyModel (dataModel (psMinRegCoreSpecs checked.plans.groups))) output := by
  obtain ⟨_, output, history⟩ := RegularIngressModel.checked_entries_has_normalized_model source checked h
  exact ⟨output, history_preserves_source _ _ _ _ _ _ _ (checked_entries_source_image source checked h)
    _ _ _ _ history⟩

theorem byte_admission_source_model (bytes : List Nat) (candidate : List PsMinRegCoreEntry)
    (accepted : PsMinRegCoreAdmission) (h : psMinRegCoreAdmit bytes candidate = some accepted) :
    accepted.source = candidate ∧
    RegularIngressWire.Wire (RegularIngressEncoding.packetTokens accepted.source) bytes ∧
    ∃ output : Model (dataModel (psMinRegCoreSpecs accepted.checked.plans.groups)) accepted.checked.types,
      SourceHistory (psMinRegCoreSpecs accepted.checked.plans.groups) accepted.checked.plans.count accepted.checked.plans.groups
        0 [] [] accepted.source accepted.checked.types
        (emptyModel (dataModel (psMinRegCoreSpecs accepted.checked.plans.groups))) output := by
  unfold psMinRegCoreAdmit at h
  cases hd : psMinRegCoreDecodeCertificate bytes candidate with
  | none => simp [hd] at h
  | some source =>
    cases hc : psMinRegCoreCheckEntries source with
    | none => simp [hd, hc] at h
    | some checked =>
      simp only [hd, hc, Option.some.injEq] at h
      subst accepted
      obtain ⟨identity, valid, grammar⟩ := RegularIngressEncoding.decode_has_wire_derivation bytes candidate source hd
      exact ⟨identity, grammar, checked_source_model source checked hc⟩

def falseSourceType : PsMinCoreExpr :=
  .constant (.str PsMinCoreName.anonymous [95,112,115,99,49,79,114,100,101,114,70,97,108,115,101]) []

theorem false_type_exact (total visible : Nat) (groups : List PsMinRegCorePlan) (type : PsMinRegTy)
    (h : psMinRegCoreType 256 total visible groups falseSourceType = some type) : type = .empty := by
  change some PsMinRegTy.empty = some type at h
  exact (Option.some.inj h).symm

def NoFalseDeclarations : List PsMinRegCoreEntry → Prop
  | [] => True
  | .inductiveE _ :: rest => NoFalseDeclarations rest
  | .definition source :: rest => source.type ≠ falseSourceType ∧ NoFalseDeclarations rest

theorem source_history_no_false (specs : List PsMinRegSpec) (total visible : Nat)
    (groups : List PsMinRegCorePlan) (names : List PsMinCoreName) (globals result : List PsMinRegTy)
    (source : List PsMinRegCoreEntry) (initial : Model (dataModel specs) globals)
    (output : Model (dataModel specs) result)
    (history : SourceHistory specs total groups visible names globals source result initial output) :
    NoFalseDeclarations source := by
  induction history with
  | done => trivial
  | group visible names globals source rest result initial output tail ih => exact ih
  | definition visible names globals source rest result type initial output value typeExact typeMeaning body tail ih =>
    refine ⟨?_, ih⟩
    intro sameSourceType
    rw [sameSourceType] at typeExact
    have emptyType := false_type_exact total visible groups type typeExact
    subst type
    exact Empty.elim value

theorem byte_admission_consistent (bytes : List Nat) (candidate : List PsMinRegCoreEntry)
    (accepted : PsMinRegCoreAdmission) (h : psMinRegCoreAdmit bytes candidate = some accepted) :
    NoFalseDeclarations accepted.source := by
  obtain ⟨_, _, output, history⟩ := byte_admission_source_model bytes candidate accepted h
  exact source_history_no_false _ _ _ _ _ _ _ _ _ _ history

#print axioms normalized_history_head
#print axioms history_preserves_source
#print axioms checked_entries_source_image
#print axioms checked_source_model
#print axioms byte_admission_source_model
#print axioms false_type_exact
#print axioms source_history_no_false
#print axioms byte_admission_consistent

#print axioms primitive_semantics
#print axioms recursor_semantics
#print axioms projection_type_domain
end Ps.MinKernel.RegularIngressSemantics
