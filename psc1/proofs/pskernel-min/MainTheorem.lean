import Ps.MinKernel.Check

namespace Ps.MinKernel.Proofs

open Ps.MinKernel

/- The concrete model is constructed in Lean's Type universe. -/
def Denote : Ty → Type
  | Ty.empty => Empty
  | Ty.unit => Unit
  | Ty.nat => Nat
  | Ty.arr domain result => Denote domain → Denote result

def Model (types : List Ty) : Type :=
  (index : Nat) → (type : Ty) → lookup types index = some type → Denote type

def emptyModel : Model [] := by
  intro index type h
  simp [lookup] at h

def consModel {type : Ty} {types : List Ty} (value : Denote type)
    (model : Model types) : Model (type :: types) := by
  intro index result h
  cases index with
  | zero =>
    have heq : type = result := by simpa [lookup] using h
    cases heq
    exact value
  | succ index => exact model index result h

theorem tyEq_sound (fuel : Nat) (left right : Ty)
    (h : tyEq fuel left right = true) : left = right := by
  induction fuel generalizing left right with
  | zero => simp [tyEq] at h
  | succ remaining ih =>
    cases left with
    | empty => cases right <;> simp_all [tyEq]
    | unit => cases right <;> simp_all [tyEq]
    | nat => cases right <;> simp_all [tyEq]
    | arr a b =>
      cases right with
      | empty => simp [tyEq] at h
      | unit => simp [tyEq] at h
      | nat => simp [tyEq] at h
      | arr c d =>
        cases hac : tyEq remaining a c with
        | false => simp [tyEq, hac] at h
        | true =>
          have hbd : tyEq remaining b d = true := by
            simpa [tyEq, hac] using h
          cases ih a c hac
          cases ih b d hbd
          rfl

/- This function interprets the *actual executable inference success*.
   Its recursion follows inference fuel, including all failure branches. -/
def inferModel (fuel : Nat) (globals locals : List Ty) (expression : Expr)
    (type : Ty) (globalModel : Model globals) (localModel : Model locals)
    (h : infer fuel globals locals expression = some type) : Denote type := by
  cases fuel with
  | zero => simp [infer] at h
  | succ remaining =>
    cases expression with
    | var index => exact localModel index type h
    | constant index => exact globalModel index type h
    | unit =>
      have ht : Ty.unit = type := by simpa [infer] using h
      cases ht
      exact ()
    | nat value =>
      have ht : Ty.nat = type := by simpa [infer] using h
      cases ht
      exact value
    | lam domain body =>
      cases hb : infer remaining globals (domain :: locals) body with
      | none => simp [infer, hb] at h
      | some result =>
        have ht : Ty.arr domain result = type := by simpa [infer, hb] using h
        cases ht
        exact fun value => inferModel remaining globals (domain :: locals) body
          result globalModel (consModel value localModel) hb
    | app fn argument =>
      cases hf : infer remaining globals locals fn with
      | none => simp [infer, hf] at h
      | some functionType =>
        cases functionType with
        | empty => simp [infer, hf] at h
        | unit => simp [infer, hf] at h
        | nat => simp [infer, hf] at h
        | arr domain result =>
          cases ha : infer remaining globals locals argument with
          | none => simp [infer, hf, ha] at h
          | some argumentType =>
            cases heq : tyEq remaining domain argumentType with
            | false => simp [infer, hf, ha, heq] at h
            | true =>
              have ht : result = type := by simpa [infer, hf, ha, heq] using h
              have harg : domain = argumentType := tyEq_sound remaining _ _ heq
              cases harg
              have output : Denote result :=
                (inferModel remaining globals locals fn (Ty.arr domain result)
                globalModel localModel hf)
                (inferModel remaining globals locals argument domain
                  globalModel localModel ha)
              exact ht ▸ output
termination_by structural fuel

/- Successful sequential admission extends a model with the interpreted body.
   There is no assumption that an arbitrary supplied environment has a model. -/
def checkDeclarationsModel (termFuel declarationFuel : Nat)
    (globals : List Ty) (declarations : List Declaration) (result : List Ty)
    (initialModel : Model globals)
    (h : checkDeclarations termFuel declarationFuel globals declarations = some result) :
    Model result := by
  cases declarations with
  | nil =>
    have ht : globals = result := by simpa [checkDeclarations] using h
    cases ht
    exact initialModel
  | cons declaration rest =>
    cases declarationFuel with
    | zero => simp [checkDeclarations] at h
    | succ remaining =>
      cases hb : infer termFuel globals [] declaration.value with
      | none => simp [checkDeclarations, hb] at h
      | some inferred =>
        cases heq : tyEq termFuel inferred declaration.type with
        | false => simp [checkDeclarations, hb, heq] at h
        | true =>
          have hs : checkDeclarations termFuel remaining
              (declaration.type :: globals) rest = some result := by
            simpa [checkDeclarations, hb, heq] using h
          have value : Denote declaration.type := by
            have ht : inferred = declaration.type := tyEq_sound termFuel _ _ heq
            exact ht ▸ inferModel termFuel globals [] declaration.value inferred
              initialModel emptyModel hb
          exact checkDeclarationsModel termFuel remaining
            (declaration.type :: globals) rest result (consModel value initialModel) hs
termination_by structural declarationFuel

def environmentModel (termFuel declarationFuel : Nat)
    (declarations : List Declaration) (types : List Ty)
    (h : checkEnvironment termFuel declarationFuel declarations = some types) :
    Model types :=
  checkDeclarationsModel termFuel declarationFuel [] declarations types emptyModel h

theorem minKernel_hasModel (termFuel declarationFuel : Nat)
    (declarations : List Declaration) (types : List Ty)
    (h : checkEnvironment termFuel declarationFuel declarations = some types) :
    Nonempty (Model types) :=
  ⟨environmentModel termFuel declarationFuel declarations types h⟩

theorem minKernel_consistent (termFuel declarationFuel queryFuel : Nat)
    (declarations : List Declaration) (types : List Ty)
    (h : checkEnvironment termFuel declarationFuel declarations = some types)
    (expression : Expr) :
    infer queryFuel types [] expression ≠ some Ty.empty := by
  intro acceptedFalse
  exact Empty.elim (inferModel queryFuel types [] expression Ty.empty
    (environmentModel termFuel declarationFuel declarations types h)
    emptyModel acceptedFalse)

#print axioms tyEq_sound
#print axioms inferModel
#print axioms checkDeclarationsModel
#print axioms minKernel_hasModel
#print axioms minKernel_consistent

end Ps.MinKernel.Proofs
