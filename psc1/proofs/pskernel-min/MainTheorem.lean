import Ps.MinKernel.Check

namespace Ps.MinKernel.Proofs


/- The concrete model is constructed in Lean's Type universe. -/
def Denote : PsMinTy → Type
  | PsMinTy.empty => Empty
  | PsMinTy.unit => Unit
  | PsMinTy.nat => Nat
  | PsMinTy.arr domain result => Denote domain → Denote result

def Model (types : List PsMinTy) : Type :=
  (index : Nat) → (type : PsMinTy) → psMinLookup types index = some type → Denote type

def emptyModel : Model [] := by
  intro index type h
  simp [psMinLookup] at h

def consModel {type : PsMinTy} {types : List PsMinTy} (value : Denote type)
    (model : Model types) : Model (type :: types) := by
  intro index result h
  cases index with
  | zero =>
    have heq : type = result := by simpa [psMinLookup] using h
    cases heq
    exact value
  | succ index => exact model index result h

theorem tyEq_sound (fuel : Nat) (left right : PsMinTy)
    (h : psMinTyEq fuel left right = true) : left = right := by
  induction fuel generalizing left right with
  | zero => simp [psMinTyEq] at h
  | succ remaining ih =>
    cases left with
    | empty => cases right <;> simp_all [psMinTyEq]
    | unit => cases right <;> simp_all [psMinTyEq]
    | nat => cases right <;> simp_all [psMinTyEq]
    | arr a b =>
      cases right with
      | empty => simp [psMinTyEq] at h
      | unit => simp [psMinTyEq] at h
      | nat => simp [psMinTyEq] at h
      | arr c d =>
        cases hac : psMinTyEq remaining a c with
        | false => simp [psMinTyEq, hac] at h
        | true =>
          have hbd : psMinTyEq remaining b d = true := by
            simpa [psMinTyEq, hac] using h
          cases ih a c hac
          cases ih b d hbd
          rfl

/- This function interprets the *actual executable inference success*.
   Its recursion follows inference fuel, including all failure branches. -/
def inferModel (fuel : Nat) (globals locals : List PsMinTy) (expression : PsMinExpr)
    (type : PsMinTy) (globalModel : Model globals) (localModel : Model locals)
    (h : psMinInfer fuel globals locals expression = some type) : Denote type := by
  cases hFuel : fuel with
  | zero => simp [hFuel, psMinInfer] at h
  | succ remaining =>
    simp only [hFuel] at h
    cases expression with
    | var index => exact localModel index type h
    | constant index => exact globalModel index type h
    | unit =>
      have ht : PsMinTy.unit = type := by simpa [psMinInfer] using h
      cases ht
      exact ()
    | nat value =>
      have ht : PsMinTy.nat = type := by simpa [psMinInfer] using h
      cases ht
      exact value
    | lam domain body =>
      cases hb : psMinInfer remaining globals (domain :: locals) body with
      | none => simp [psMinInfer, hb] at h
      | some result =>
        have ht : PsMinTy.arr domain result = type := by simpa [psMinInfer, hb] using h
        cases ht
        exact fun value => inferModel remaining globals (domain :: locals) body
          result globalModel (consModel value localModel) hb
    | app fn argument =>
      cases hf : psMinInfer remaining globals locals fn with
      | none => simp [psMinInfer, hf] at h
      | some functionType =>
        cases functionType with
        | empty => simp [psMinInfer, hf] at h
        | unit => simp [psMinInfer, hf] at h
        | nat => simp [psMinInfer, hf] at h
        | arr domain result =>
          cases ha : psMinInfer remaining globals locals argument with
          | none => simp [psMinInfer, hf, ha] at h
          | some argumentType =>
            cases heq : psMinTyEq remaining domain argumentType with
            | false => simp [psMinInfer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [psMinInfer, hf, ha, heq] using h
              have harg : domain = argumentType := tyEq_sound remaining _ _ heq
              cases harg
              have output : Denote result :=
                (inferModel remaining globals locals fn (PsMinTy.arr domain result)
                globalModel localModel hf)
                (inferModel remaining globals locals argument domain
                  globalModel localModel ha)
              exact ht ▸ output
termination_by fuel
decreasing_by all_goals simpa only [hFuel] using (Nat.lt_succ_self remaining)

/- Successful sequential admission extends a model with the interpreted body.
   There is no assumption that an arbitrary supplied environment has a model. -/
def checkDeclarationsModel (termFuel declarationFuel : Nat)
    (globals : List PsMinTy) (declarations : List PsMinDeclaration) (result : List PsMinTy)
    (initialModel : Model globals)
    (h : psMinCheckDeclarations termFuel declarationFuel globals declarations = some result) :
    Model result := by
  cases declarations with
  | nil =>
    have ht : globals = result := by simpa [psMinCheckDeclarations] using h
    cases ht
    exact initialModel
  | cons declaration rest =>
    cases hFuel : declarationFuel with
    | zero => simp [hFuel, psMinCheckDeclarations] at h
    | succ remaining =>
      simp only [hFuel] at h
      cases hb : psMinInfer termFuel globals [] declaration.value with
      | none => simp [psMinCheckDeclarations, hb] at h
      | some psMinInferred =>
        cases heq : psMinTyEq termFuel psMinInferred declaration.type with
        | false => simp [psMinCheckDeclarations, hb, heq] at h
        | true =>
          have hs : psMinCheckDeclarations termFuel remaining
              (declaration.type :: globals) rest = some result := by
            simpa [psMinCheckDeclarations, hb, heq] using h
          have value : Denote declaration.type := by
            have ht : psMinInferred = declaration.type := tyEq_sound termFuel _ _ heq
            exact ht ▸ inferModel termFuel globals [] declaration.value psMinInferred
              initialModel emptyModel hb
          exact checkDeclarationsModel termFuel remaining
            (declaration.type :: globals) rest result (consModel value initialModel) hs
termination_by declarationFuel
decreasing_by all_goals simpa only [hFuel] using (Nat.lt_succ_self remaining)

def environmentModel (termFuel declarationFuel : Nat)
    (declarations : List PsMinDeclaration) (types : List PsMinTy)
    (h : psMinCheckEnvironment termFuel declarationFuel declarations = some types) :
    Model types :=
  checkDeclarationsModel termFuel declarationFuel [] declarations types emptyModel h

theorem minKernel_hasModel (termFuel declarationFuel : Nat)
    (declarations : List PsMinDeclaration) (types : List PsMinTy)
    (h : psMinCheckEnvironment termFuel declarationFuel declarations = some types) :
    Nonempty (Model types) :=
  ⟨environmentModel termFuel declarationFuel declarations types h⟩

theorem minKernel_consistent (termFuel declarationFuel queryFuel : Nat)
    (declarations : List PsMinDeclaration) (types : List PsMinTy)
    (h : psMinCheckEnvironment termFuel declarationFuel declarations = some types)
    (expression : PsMinExpr) :
    psMinInfer queryFuel types [] expression ≠ some PsMinTy.empty := by
  intro acceptedFalse
  exact Empty.elim (inferModel queryFuel types [] expression PsMinTy.empty
    (environmentModel termFuel declarationFuel declarations types h)
    emptyModel acceptedFalse)

#print axioms tyEq_sound
#print axioms inferModel
#print axioms checkDeclarationsModel
#print axioms minKernel_hasModel
#print axioms minKernel_consistent

end Ps.MinKernel.Proofs
