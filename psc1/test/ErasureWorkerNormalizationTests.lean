import Ps.Erasure.Definition

namespace PsErasureWorkerReference
def psErasureIndexFindInBucket (Value : Type) (entries : List (Prod PsName Value)) : PsName -> Option Value :=
  match entries with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option Value := psErasureIndexFindInBucket Value rest;
      fun (target : PsName) =>
        match entry with
        | Prod.mk key value => if psNameEq key target then Option.some value else smaller target

def psErasureLookupRuntimeExpression
    (entries : List (Prod Nat PsVerifiedIrExpr)) :
    Nat -> Option PsVerifiedIrExpr :=
  match entries with
  | List.nil => fun (_target : Nat) => Option.none
  | List.cons entry rest =>
      let smaller : Nat -> Option PsVerifiedIrExpr := psErasureLookupRuntimeExpression rest;
      fun (target : Nat) =>
        match entry with
        | Prod.mk key value =>
            if Nat.beq key target then Option.some value
            else smaller target

def psErasureLookupNat
    (entries : List (Prod Nat String)) :
    Nat -> Option String :=
  match entries with
  | List.nil => fun (_target : Nat) => Option.none
  | List.cons entry rest =>
      let smaller : Nat -> Option String := psErasureLookupNat rest;
      fun (target : Nat) =>
        match entry with
        | Prod.mk key value =>
            if Nat.beq key target then Option.some value
            else smaller target

def psErasureNatInList (values : List Nat) : Nat -> Bool :=
  match values with
  | List.nil => fun (_target : Nat) => false
  | List.cons value rest =>
      let smaller := psErasureNatInList rest;
      fun (target : Nat) =>
        if Nat.beq value target then true else smaller target

def psErasureTypeValuedWithFuel
    (environment : PsEnvironment) (fuel : Nat) :
    PsLocalContext -> PsExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_locals : PsLocalContext) (_type : PsExpr) => false
  | Nat.succ remaining =>
      let smaller := psErasureTypeValuedWithFuel environment remaining;
      fun (locals : PsLocalContext) (type : PsExpr) =>
        match psWhnf environment psMetaEmpty locals type with
        | PsExpr.sortE _ => true
        | PsExpr.forallE name domain body binder =>
            let pushed := psLocalPushBinding locals name domain binder;
            smaller pushed.context (psExprInstantiate1 body (PsExpr.fvar pushed.id))
        | _ => false

def psErasureStringInList (values : List String) : String -> Bool :=
  match values with
  | List.nil => fun (_target : String) => false
  | List.cons value rest =>
      let smaller : String -> Bool := psErasureStringInList rest;
      fun (target : String) =>
        if psStringEq value target then true else smaller target

def psErasureLookupTypeSubstitution
    (entries : List (String × PsVerifiedIrType)) :
    String -> Option PsVerifiedIrType :=
  match entries with
  | List.nil => fun (name : String) => Option.none
  | List.cons entry rest =>
      let smaller := psErasureLookupTypeSubstitution rest;
      fun (name : String) =>
        match entry with
        | Prod.mk key value =>
            if psStringEq key name then Option.some value
            else smaller name

def psErasureFindStringIndex (target : String) (values : List String) : Nat -> Option Nat :=
  match values with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons value rest =>
      let smaller : Nat -> Option Nat := psErasureFindStringIndex target rest;
      fun (index : Nat) =>
        if psStringEq value target then Option.some index
        else smaller (Nat.succ index)
end PsErasureWorkerReference

theorem erasure_index_worker_eq (Value : Type) (entries : List (Prod PsName Value)) (target : PsName) :
    psErasureIndexFindInBucketWorker Value entries target =
      PsErasureWorkerReference.psErasureIndexFindInBucket Value entries target := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      rcases entry with ⟨key, value⟩
      change (if psNameEq key target then Option.some value else psErasureIndexFindInBucketWorker Value rest target) =
        (if psNameEq key target then Option.some value else PsErasureWorkerReference.psErasureIndexFindInBucket Value rest target)
      rw [ih]

theorem erasure_runtime_expression_worker_eq (entries : List (Prod Nat PsVerifiedIrExpr)) (target : Nat) :
    psErasureLookupRuntimeExpressionWorker entries target =
      PsErasureWorkerReference.psErasureLookupRuntimeExpression entries target := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      rcases entry with ⟨key, value⟩
      change (if Nat.beq key target then Option.some value else psErasureLookupRuntimeExpressionWorker rest target) =
        (if Nat.beq key target then Option.some value else PsErasureWorkerReference.psErasureLookupRuntimeExpression rest target)
      rw [ih]

theorem erasure_nat_lookup_worker_eq (entries : List (Prod Nat String)) (target : Nat) :
    psErasureLookupNatWorker entries target =
      PsErasureWorkerReference.psErasureLookupNat entries target := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      rcases entry with ⟨key, value⟩
      change (if Nat.beq key target then Option.some value else psErasureLookupNatWorker rest target) =
        (if Nat.beq key target then Option.some value else PsErasureWorkerReference.psErasureLookupNat rest target)
      rw [ih]

theorem erasure_nat_membership_worker_eq (values : List Nat) (target : Nat) :
    psErasureNatInListWorker values target =
      PsErasureWorkerReference.psErasureNatInList values target := by
  induction values with
  | nil => rfl
  | cons value rest ih =>
      change (if Nat.beq value target then true else psErasureNatInListWorker rest target) =
        (if Nat.beq value target then true else PsErasureWorkerReference.psErasureNatInList rest target)
      rw [ih]

theorem erasure_string_membership_worker_eq (values : List String) (target : String) :
    psErasureStringInListWorker values target =
      PsErasureWorkerReference.psErasureStringInList values target := by
  induction values with
  | nil => rfl
  | cons value rest ih =>
      change (if psStringEq value target then true else psErasureStringInListWorker rest target) =
        (if psStringEq value target then true else PsErasureWorkerReference.psErasureStringInList rest target)
      rw [ih]

theorem erasure_type_substitution_worker_eq (entries : List (String × PsVerifiedIrType)) (target : String) :
    psErasureLookupTypeSubstitutionWorker entries target =
      PsErasureWorkerReference.psErasureLookupTypeSubstitution entries target := by
  induction entries with
  | nil => rfl
  | cons entry rest ih =>
      rcases entry with ⟨key, value⟩
      change (if psStringEq key target then Option.some value else psErasureLookupTypeSubstitutionWorker rest target) =
        (if psStringEq key target then Option.some value else PsErasureWorkerReference.psErasureLookupTypeSubstitution rest target)
      rw [ih]

theorem erasure_string_index_worker_eq (target : String) (values : List String) :
    ∀ index, psErasureFindStringIndexWorker target values index =
      PsErasureWorkerReference.psErasureFindStringIndex target values index := by
  induction values with
  | nil => intro index; rfl
  | cons value rest ih =>
      intro index
      change (if psStringEq value target then Option.some index else psErasureFindStringIndexWorker target rest (Nat.succ index)) =
        (if psStringEq value target then Option.some index else PsErasureWorkerReference.psErasureFindStringIndex target rest (Nat.succ index))
      rw [ih (Nat.succ index)]

theorem erasure_type_valued_worker_eq (environment : PsEnvironment) (fuel : Nat) :
    ∀ locals type, psErasureTypeValuedWithFuelWorker environment fuel locals type =
      PsErasureWorkerReference.psErasureTypeValuedWithFuel environment fuel locals type := by
  induction fuel with
  | zero => intro locals type; rfl
  | succ remaining ih =>
      intro locals type
      change
        (match psWhnf environment psMetaEmpty locals type with
        | PsExpr.sortE _ => true
        | PsExpr.forallE name domain body binder =>
            let pushed := psLocalPushBinding locals name domain binder
            psErasureTypeValuedWithFuelWorker environment remaining pushed.context
              (psExprInstantiate1 body (PsExpr.fvar pushed.id))
        | _ => false) =
        (match psWhnf environment psMetaEmpty locals type with
        | PsExpr.sortE _ => true
        | PsExpr.forallE name domain body binder =>
            let pushed := psLocalPushBinding locals name domain binder
            PsErasureWorkerReference.psErasureTypeValuedWithFuel environment remaining pushed.context
              (psExprInstantiate1 body (PsExpr.fvar pushed.id))
        | _ => false)
      cases h : psWhnf environment psMetaEmpty locals type <;> simp only [h] <;> try rfl
      exact ih _ _

theorem erasure_type_valued_eq (environment : PsEnvironment) (fuel : Nat) :
    psErasureTypeValuedWithFuel environment fuel =
      PsErasureWorkerReference.psErasureTypeValuedWithFuel environment fuel := by
  funext locals type
  exact erasure_type_valued_worker_eq environment fuel locals type

theorem erasure_string_membership_eq (values : List String) :
    psErasureStringInList values = PsErasureWorkerReference.psErasureStringInList values := by
  funext target
  exact erasure_string_membership_worker_eq values target

#print axioms erasure_type_valued_eq
#print axioms erasure_string_membership_eq

def main : IO Unit := do
  let sort := PsExpr.sortE PsLevel.zero
  let forallType := PsExpr.forallE PsName.anonymous sort sort PsBinderInfo.explicit
  let dependent := PsExpr.forallE PsName.anonymous sort (PsExpr.bvar 0) PsBinderInfo.explicit
  for fuel in [0,1,2,5,20] do
    for type in [sort, forallType, dependent, PsExpr.bvar 0, PsExpr.fvar 0, PsExpr.lit (.natural 7)] do
      if psErasureTypeValuedWithFuel psEnvironmentEmpty fuel psLocalEmpty type !=
          PsErasureWorkerReference.psErasureTypeValuedWithFuel psEnvironmentEmpty fuel psLocalEmpty type then
        throw (IO.userError "type-valued result or fuel changed")
  if psErasureTypeValuedWithFuel psEnvironmentEmpty 0 psLocalEmpty sort then
    throw (IO.userError "zero fuel")
  if psErasureTypeValuedWithFuel psEnvironmentEmpty 1 psLocalEmpty forallType then
    throw (IO.userError "forall fuel exhaustion")
  if !psErasureTypeValuedWithFuel psEnvironmentEmpty 2 psLocalEmpty forallType then
    throw (IO.userError "forall fuel consumption")
  if !psErasureTypeValuedWithFuel psEnvironmentEmpty 100001 psLocalEmpty sort then
    throw (IO.userError "head classification eagerly traversed fuel")
  let large := List.replicate 100001 "first"
  if !psErasureStringInList large "first" || psErasureStringInList large "absent" then
    throw (IO.userError "large membership")
  let naturals := List.replicate 100001 7
  if !psErasureNatInList naturals 7 || psErasureNatInList naturals 8 then
    throw (IO.userError "large Nat membership")
  if psErasureFindStringIndex "first" large 13 != .some 13 ||
      psErasureFindStringIndex "absent" large 13 != .none then
    throw (IO.userError "index order or miss")
  if psErasureLookupNat [(7,"first"),(7,"last")] 7 != .some "first" then
    throw (IO.userError "Nat duplicate precedence")
  let name := PsName.str PsName.anonymous "雪"
  if psErasureIndexFindInBucket Nat [(name,1),(name,2)] name != .some 1 then
    throw (IO.userError "name duplicate precedence")
  match psErasureLookupRuntimeExpression [(7,.literal (.natural 1)),(7,.literal (.natural 2))] 7 with
  | .some (.literal (.natural 1)) => pure ()
  | _ => throw (IO.userError "expression duplicate precedence")
  match psErasureLookupTypeSubstitution [("T",.primitive .nat),("T",.primitive .bool)] "T" with
  | .some (.primitive .nat) => pure ()
  | _ => throw (IO.userError "substitution duplicate precedence")
  IO.println "PSC1_ERASURE_WORKER_NORMALIZATION: eight all-input worker equalities proved; environment/fuel/local/expression preserved; zero/forall fuel, first duplicates and 100001-entry hit/miss passed; default classifier limits unchanged"
