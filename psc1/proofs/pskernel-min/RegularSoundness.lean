import RegularModel

namespace Ps.MinKernel.RegularProofs
open Ps.MinKernel.RegularModel

def Model (data : List Type) (types : List PsMinRegTy) : Type :=
  (index : Nat) → (type : PsMinRegTy) → psMinRegLookup types index = some type → Denote data type

def emptyModel (data : List Type) : Model data [] := by
  intro index type h
  simp [psMinRegLookup] at h

def consModel (data : List Type) {type : PsMinRegTy} {types : List PsMinRegTy}
    (value : Denote data type) (model : Model data types) : Model data (type :: types) := by
  intro index result h
  cases index with
  | zero =>
    have heq : type = result := by simpa [psMinRegLookup] using h
    cases heq
    exact value
  | succ index => exact model index result h

theorem typeEq_sound (fuel : Nat) (left right : PsMinRegTy)
    (h : psMinRegTyEq fuel left right = true) : left = right := by
  induction fuel generalizing left right with
  | zero => simp [psMinRegTyEq] at h
  | succ remaining ih =>
    cases left with
    | empty => cases right <;> simp_all [psMinRegTyEq]
    | unit => cases right <;> simp_all [psMinRegTyEq]
    | nat => cases right <;> simp_all [psMinRegTyEq]
    | boolean => cases right <;> simp_all [psMinRegTyEq]
    | data index => cases right <;> simp_all [psMinRegTyEq, Nat.beq_eq]
    | arr domain result =>
      cases right with
      | empty => simp [psMinRegTyEq] at h
      | unit => simp [psMinRegTyEq] at h
      | nat => simp [psMinRegTyEq] at h
      | boolean => simp [psMinRegTyEq] at h
      | data index => simp [psMinRegTyEq] at h
      | list element => simp [psMinRegTyEq] at h
      | option element => simp [psMinRegTyEq] at h
      | arr otherDomain otherResult =>
        cases hd : psMinRegTyEq remaining domain otherDomain with
        | false => simp [psMinRegTyEq, hd] at h
        | true =>
          have hr : psMinRegTyEq remaining result otherResult = true := by simpa [psMinRegTyEq, hd] using h
          cases ih domain otherDomain hd
          cases ih result otherResult hr
          rfl
    | list element =>
      cases right with
      | empty => simp [psMinRegTyEq] at h
      | unit => simp [psMinRegTyEq] at h
      | nat => simp [psMinRegTyEq] at h
      | boolean => simp [psMinRegTyEq] at h
      | data index => simp [psMinRegTyEq] at h
      | arr a b => simp [psMinRegTyEq] at h
      | option other => simp [psMinRegTyEq] at h
      | list other =>
        have heq : element = other := ih element other h
        cases heq
        rfl
    | option element =>
      cases right with
      | empty => simp [psMinRegTyEq] at h
      | unit => simp [psMinRegTyEq] at h
      | nat => simp [psMinRegTyEq] at h
      | boolean => simp [psMinRegTyEq] at h
      | data index => simp [psMinRegTyEq] at h
      | arr a b => simp [psMinRegTyEq] at h
      | list other => simp [psMinRegTyEq] at h
      | option other =>
        have heq : element = other := ih element other h
        cases heq
        rfl

-- The model follows the actual executable inference, including every refusal.
def inferModel (fuel : Nat) (specs : List PsMinRegSpec) (data : List Type)
    (globals locals : List PsMinRegTy) (expression : PsMinRegTerm) (type : PsMinRegTy)
    (signatureModel : SignatureModel specs data) (globalModel : Model data globals)
    (localModel : Model data locals)
    (h : psMinRegInfer fuel specs globals locals expression = some type) : Denote data type := by
  cases fuel with
  | zero => simp [psMinRegInfer] at h
  | succ remaining =>
    cases expression with
    | var index => exact localModel index type h
    | constant index => exact globalModel index type h
    | unit =>
      have ht : PsMinRegTy.unit = type := by simpa [psMinRegInfer] using h
      cases ht
      exact ()
    | nat value =>
      have ht : PsMinRegTy.nat = type := by simpa [psMinRegInfer] using h
      cases ht
      exact value
    | boolean value =>
      have ht : PsMinRegTy.boolean = type := by simpa [psMinRegInfer] using h
      cases ht
      exact value
    | ctor slot index => exact signatureModel.ctorValue slot index type h
    | recursor slot sortLevel parameters indices motives minors result =>
      exact signatureModel.recValue remaining slot sortLevel parameters indices motives minors result type h
    | lam domain body =>
      cases hv : psMinRegTyValid remaining (psMinRegSpecCount specs) domain with
      | false => simp [psMinRegInfer, hv] at h
      | true =>
        cases hb : psMinRegInfer remaining specs globals (domain :: locals) body with
        | none => simp [psMinRegInfer, hv, hb] at h
        | some result =>
          have ht : PsMinRegTy.arr domain result = type := by simpa [psMinRegInfer, hv, hb] using h
          cases ht
          exact fun value => inferModel remaining specs data globals (domain :: locals) body result
            signatureModel globalModel (consModel data value localModel) hb
    | app fn argument =>
      cases hf : psMinRegInfer remaining specs globals locals fn with
      | none => simp [psMinRegInfer, hf] at h
      | some functionType =>
        cases functionType with
        | empty => simp [psMinRegInfer, hf] at h
        | unit => simp [psMinRegInfer, hf] at h
        | nat => simp [psMinRegInfer, hf] at h
        | boolean => simp [psMinRegInfer, hf] at h
        | data index => simp [psMinRegInfer, hf] at h
        | list element => simp [psMinRegInfer, hf] at h
        | option element => simp [psMinRegInfer, hf] at h
        | arr domain result =>
          cases ha : psMinRegInfer remaining specs globals locals argument with
          | none => simp [psMinRegInfer, hf, ha] at h
          | some argumentType =>
            cases heq : psMinRegTyEq remaining domain argumentType with
            | false => simp [psMinRegInfer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [psMinRegInfer, hf, ha, heq] using h
              have harg : domain = argumentType := typeEq_sound remaining _ _ heq
              cases harg
              have output : Denote data result :=
                (inferModel remaining specs data globals locals fn (PsMinRegTy.arr domain result)
                  signatureModel globalModel localModel hf)
                (inferModel remaining specs data globals locals argument domain
                  signatureModel globalModel localModel ha)
              exact ht ▸ output
termination_by structural fuel

def declarationsModel (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec) (data : List Type)
    (globals : List PsMinRegTy) (declarations : List PsMinRegDeclaration) (result : List PsMinRegTy)
    (signatureModel : SignatureModel specs data) (initialModel : Model data globals)
    (h : psMinRegCheckDeclarations termFuel declarationFuel specs globals declarations = some result) :
    Model data result := by
  cases declarations with
  | nil =>
    have ht : globals = result := by simpa [psMinRegCheckDeclarations] using h
    cases ht
    exact initialModel
  | cons declaration rest =>
    cases hFuel : declarationFuel with
    | zero => simp [hFuel, psMinRegCheckDeclarations] at h
    | succ remaining =>
      simp only [hFuel] at h
      cases hv : psMinRegTyValid termFuel (psMinRegSpecCount specs) declaration.type with
      | false => simp [psMinRegCheckDeclarations, hv] at h
      | true =>
        cases hb : psMinRegInfer termFuel specs globals [] declaration.value with
        | none => simp [psMinRegCheckDeclarations, hv, hb] at h
        | some inferred =>
          cases heq : psMinRegTyEq termFuel inferred declaration.type with
          | false => simp [psMinRegCheckDeclarations, hv, hb, heq] at h
          | true =>
            have hs : psMinRegCheckDeclarations termFuel remaining specs
                (declaration.type :: globals) rest = some result := by
              simpa [psMinRegCheckDeclarations, hv, hb, heq] using h
            have value : Denote data declaration.type := by
              have ht : inferred = declaration.type := typeEq_sound termFuel _ _ heq
              exact ht ▸ inferModel termFuel specs data globals [] declaration.value inferred
                signatureModel initialModel (emptyModel data) hb
            exact declarationsModel termFuel remaining specs data (declaration.type :: globals) rest result
              signatureModel (consModel data value initialModel) hs
termination_by declarationFuel
decreasing_by all_goals simpa only [hFuel] using (Nat.lt_succ_self remaining)

def environmentModel (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegDeclaration) (types : List PsMinRegTy)
    (h : psMinRegCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    Model (dataModel specs) types := by
  cases hv : psMinRegRegistryValid termFuel specs with
  | false => simp [psMinRegCheckEnvironment, hv] at h
  | true =>
    have hs : psMinRegCheckDeclarations termFuel declarationFuel specs [] declarations = some types := by
      simpa [psMinRegCheckEnvironment, hv] using h
    exact declarationsModel termFuel declarationFuel specs (dataModel specs) [] declarations types
      (signatures specs) (emptyModel (dataModel specs)) hs

theorem regular_hasModel (termFuel declarationFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegDeclaration) (types : List PsMinRegTy)
    (h : psMinRegCheckEnvironment termFuel declarationFuel specs declarations = some types) :
    Nonempty (Model (dataModel specs) types) :=
  ⟨environmentModel termFuel declarationFuel specs declarations types h⟩

theorem regular_consistent (termFuel declarationFuel queryFuel : Nat) (specs : List PsMinRegSpec)
    (declarations : List PsMinRegDeclaration) (types : List PsMinRegTy)
    (h : psMinRegCheckEnvironment termFuel declarationFuel specs declarations = some types)
    (expression : PsMinRegTerm) :
    psMinRegInfer queryFuel specs types [] expression ≠ some PsMinRegTy.empty := by
  intro acceptedFalse
  exact Empty.elim (inferModel queryFuel specs (dataModel specs) types [] expression PsMinRegTy.empty
    (signatures specs) (environmentModel termFuel declarationFuel specs declarations types h)
    (emptyModel (dataModel specs)) acceptedFalse)

#print axioms typeEq_sound
#print axioms inferModel
#print axioms regular_hasModel
#print axioms regular_consistent

end Ps.MinKernel.RegularProofs
