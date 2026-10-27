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
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.head4 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head5 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natAdd 0 0 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.head5 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head6 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natSub 0 0 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.head6 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head7 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natBeq 0 0 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.head7 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | head8 =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        .natBlt 0 0 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.head8 (data := dataModel specs) (total := total) (visible := visible) (groups := groups))
  | listNil element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listNil a) 0 1 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.listNil element a ht sort)
  | listCons element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listCons a) 0 1 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.listCons element a ht sort)
  | optionNone element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionNone a) 0 1 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.optionNone element a ht sort)
  | optionSome element a ht sort =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have equal := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionSome a) 0 1 0 0 0 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel,
        OperationalFoundation.primitiveValue] using
          (PrimitiveDenotation.optionSome element a ht sort)

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
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel] using
        (RecursorDenotation.nat motive result meaning)
  | list element motive a result elementType elementSort meaning =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.listRec a result) 1 1 0 1 2 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel] using
        (RecursorDenotation.list element motive a result elementType elementSort meaning)
  | option element motive a result elementType elementSort meaning =>
    cases evaluation
    rename_i fuel checked
    cases fuel with
    | zero => simp [psMinOpInfer] at checked
    | succ remaining =>
      have ht := OperationalFoundation.primitiveType_signature remaining (psMinRegSpecCount specs)
        (.optionRec a result) 1 1 0 1 2 type checked
      subst type
      simpa only [actualOrdinary, OperationalProofs.inferModel, OperationalFoundation.primitiveModel] using
        (RecursorDenotation.option element motive a result elementType elementSort meaning)
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

#print axioms primitive_semantics
#print axioms recursor_semantics
#print axioms projection_type_domain
end Ps.MinKernel.RegularIngressSemantics
