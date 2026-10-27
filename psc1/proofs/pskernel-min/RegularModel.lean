import Ps.MinKernel.Profile.RegularCheck

namespace Ps.MinKernel.RegularModel

def dataLookup : List Type → Nat → Type
  | [], _ => Empty
  | value :: _, 0 => value
  | _ :: rest, Nat.succ index => dataLookup rest index

def Denote (data : List Type) : PsMinRegTy → Type
  | .empty => Empty
  | .unit => Unit
  | .nat => Nat
  | .boolean => Bool
  | .data index => dataLookup data index
  | .arr domain result => Denote data domain → Denote data result
  | .list element => List (Denote data element)
  | .option element => Option (Denote data element)

theorem denote_lift (head : Type) (data : List Type) (type : PsMinRegTy) :
    Denote (head :: data) (psMinRegLiftTy type) = Denote data type := by
  induction type with
  | empty => rfl
  | unit => rfl
  | nat => rfl
  | boolean => rfl
  | data index => rfl
  | arr domain result ihDomain ihResult =>
    simp only [psMinRegLiftTy, Denote, ihDomain, ihResult]
  | list element ih => simp only [psMinRegLiftTy, Denote, ih]
  | option element ih => simp only [psMinRegLiftTy, Denote, ih]

-- All recursive occurrences are direct positive fields. Ground fields use only
-- previously interpreted type codes; the runtime validator bounds those slots.
def Grounds (data : List Type) : List PsMinRegField → Type
  | [] => Unit
  | .ground type :: rest => Denote data type × Grounds data rest
  | .recursive :: rest => Grounds data rest

def Args (data : List Type) (self : Type) : List PsMinRegField → Type
  | [] => Unit
  | .ground type :: rest => Denote data type × Args data self rest
  | .recursive :: rest => self × Args data self rest

def splitArgs (data : List Type) (self : Type) (fields : List PsMinRegField)
    (args : Args data self fields) : Grounds data fields × (Fin (psMinRegSelfCount fields) → self) :=
  match fields with
  | [] => ((), Fin.elim0)
  | .ground _ :: rest =>
    let result := splitArgs data self rest args.2
    ((args.1, result.1), result.2)
  | .recursive :: rest =>
    let result := splitArgs data self rest args.2
    (result.1, Fin.cases args.1 result.2)

def joinArgs (data : List Type) (self : Type) (fields : List PsMinRegField)
    (ground : Grounds data fields) (children : Fin (psMinRegSelfCount fields) → self) :
    Args data self fields :=
  match fields with
  | [] => ()
  | .ground _ :: rest => (ground.1, joinArgs data self rest ground.2 children)
  | .recursive :: rest => (children ⟨0, by change 0 < Nat.succ (psMinRegSelfCount rest); exact Nat.zero_lt_succ _⟩,
      joinArgs data self rest ground (fun i => children i.succ))

theorem join_split (data : List Type) (self : Type) (fields : List PsMinRegField)
    (args : Args data self fields) :
    joinArgs data self fields (splitArgs data self fields args).1
      (splitArgs data self fields args).2 = args := by
  induction fields with
  | nil => cases args; rfl
  | cons field rest ih =>
    cases field with
    | ground type =>
      rcases args with ⟨head, tail⟩
      change (head, joinArgs data self rest (splitArgs data self rest tail).1
        (splitArgs data self rest tail).2) = (head, tail)
      rw [ih tail]
    | recursive =>
      rcases args with ⟨head, tail⟩
      change (head, joinArgs data self rest (splitArgs data self rest tail).1
        (splitArgs data self rest tail).2) = (head, tail)
      rw [ih tail]

inductive RegularTree (shape : Type) (arity : shape → Nat) where
  | node (tag : shape) (children : Fin (arity tag) → RegularTree shape arity)

def Shape (data : List Type) (constructors : List (List PsMinRegField)) : Type :=
  Σ index : Fin constructors.length, Grounds data (constructors.get index)

def Carrier (spec : PsMinRegSpec) (data : List Type) : Type :=
  RegularTree (Shape data spec.constructors)
    (fun tag => psMinRegSelfCount (spec.constructors.get tag.1))

def construct (spec : PsMinRegSpec) (data : List Type) (index : Fin spec.constructors.length)
    (args : Args data (Carrier spec data) (spec.constructors.get index)) : Carrier spec data :=
  let fields := spec.constructors.get index
  let parts := splitArgs data (Carrier spec data) fields args
  RegularTree.node ⟨index, parts.1⟩ parts.2

def fold (spec : PsMinRegSpec) (data : List Type) (result : Type)
    (branches : (index : Fin spec.constructors.length) →
      Args data (Carrier spec data) (spec.constructors.get index) →
      (Fin (psMinRegSelfCount (spec.constructors.get index)) → result) → result)
    (tree : Carrier spec data) : result :=
  match tree with
  | .node tag children => branches tag.1
      (joinArgs data (Carrier spec data) (spec.constructors.get tag.1) tag.2 children)
      (fun i => fold spec data result branches (children i))
termination_by structural tree

theorem fold_construct (spec : PsMinRegSpec) (data : List Type) (result : Type)
    (branches : (index : Fin spec.constructors.length) →
      Args data (Carrier spec data) (spec.constructors.get index) →
      (Fin (psMinRegSelfCount (spec.constructors.get index)) → result) → result)
    (index : Fin spec.constructors.length)
    (args : Args data (Carrier spec data) (spec.constructors.get index)) :
    fold spec data result branches (construct spec data index args) =
      branches index args (fun i => fold spec data result branches
        ((splitArgs data (Carrier spec data) (spec.constructors.get index) args).2 i)) := by
  change branches index (joinArgs data (Carrier spec data) (spec.constructors.get index)
    (splitArgs data (Carrier spec data) (spec.constructors.get index) args).1
    (splitArgs data (Carrier spec data) (spec.constructors.get index) args).2) _ = _
  rw [join_split] <;> rfl

def FieldArrow (data : List Type) (self : Type) (fields : List PsMinRegField) (result : Type) : Type :=
  match fields with
  | [] => result
  | .ground type :: rest => Denote data type → FieldArrow data self rest result
  | .recursive :: rest => self → FieldArrow data self rest result

def curryFields (data : List Type) (self : Type) (fields : List PsMinRegField) (result : Type)
    (fn : Args data self fields → result) : FieldArrow data self fields result :=
  match fields with
  | [] => fn ()
  | .ground _ :: rest => fun value => curryFields data self rest result (fun args => fn (value, args))
  | .recursive :: rest => fun value => curryFields data self rest result (fun args => fn (value, args))

def applyFields (data : List Type) (self : Type) (fields : List PsMinRegField) (result : Type)
    (fn : FieldArrow data self fields result) (args : Args data self fields) : result :=
  match fields with
  | [] => fn
  | .ground _ :: rest => applyFields data self rest result (fn args.1) args.2
  | .recursive :: rest => applyFields data self rest result (fn args.1) args.2

theorem apply_curry (data : List Type) (self : Type) (fields : List PsMinRegField) (result : Type)
    (fn : Args data self fields → result) (args : Args data self fields) :
    applyFields data self fields result (curryFields data self fields result fn) args = fn args := by
  induction fields with
  | nil => cases args; rfl
  | cons field rest ih =>
    cases field <;> rcases args with ⟨head, tail⟩ <;> exact ih (fun xs => fn (head, xs)) tail

def Repeat (count : Nat) (domain result : Type) : Type :=
  match count with
  | 0 => result
  | Nat.succ remaining => domain → Repeat remaining domain result

def applyHyps (count : Nat) (result : Type) (fn : Repeat count result result)
    (values : Fin count → result) : result :=
  match count with
  | 0 => fn
  | Nat.succ remaining => applyHyps remaining result (fn (values 0)) (fun i => values i.succ)

def Minor (data : List Type) (self result : Type) (fields : List PsMinRegField) : Type :=
  FieldArrow data self fields (Repeat (psMinRegSelfCount fields) result result)

def BranchPack (data : List Type) (self result : Type) (constructors : List (List PsMinRegField)) : Type :=
  match constructors with
  | [] => Unit
  | fields :: rest => Minor data self result fields × BranchPack data self result rest

def BranchArrow (data : List Type) (self result : Type) (constructors : List (List PsMinRegField)) : Type :=
  match constructors with
  | [] => self → result
  | fields :: rest => Minor data self result fields → BranchArrow data self result rest

def getBranch (data : List Type) (self result : Type) (constructors : List (List PsMinRegField))
    (values : BranchPack data self result constructors) (index : Fin constructors.length) :
    Minor data self result (constructors.get index) :=
  match constructors with
  | [] => Fin.elim0 index
  | _ :: rest => Fin.cases values.1
      (fun i => getBranch data self result rest values.2 i) index

def curryBranches (data : List Type) (self result : Type) (constructors : List (List PsMinRegField))
    (fn : BranchPack data self result constructors → self → result) :
    BranchArrow data self result constructors :=
  match constructors with
  | [] => fn ()
  | _ :: rest => fun value => curryBranches data self result rest (fun args => fn (value, args))

def recursor (spec : PsMinRegSpec) (data : List Type) (result : Type) :
    BranchArrow data (Carrier spec data) result spec.constructors :=
  curryBranches data (Carrier spec data) result spec.constructors fun branches =>
    fold spec data result fun index args ih =>
      applyHyps (psMinRegSelfCount (spec.constructors.get index)) result
        (applyFields data (Carrier spec data) (spec.constructors.get index)
          (Repeat (psMinRegSelfCount (spec.constructors.get index)) result result)
          (getBranch data (Carrier spec data) result spec.constructors branches index) args) ih

theorem denote_fields (self : Type) (data : List Type) (fields : List PsMinRegField)
    (result : PsMinRegTy) :
    Denote (self :: data) (psMinRegFieldArrow fields result) =
      FieldArrow data self fields (Denote (self :: data) result) := by
  induction fields with
  | nil => rfl
  | cons field rest ih =>
    cases field with
    | ground type => simp only [psMinRegFieldArrow, Denote, denote_lift, FieldArrow, ih]
    | recursive => simp only [psMinRegFieldArrow, Denote, dataLookup, FieldArrow, ih]

theorem denote_repeat (data : List Type) (count : Nat) (domain result : PsMinRegTy) :
    Denote data (psMinRegRepeatArrow count domain result) = Repeat count (Denote data domain) (Denote data result) := by
  induction count with
  | zero => rfl
  | succ previous ih => simp only [psMinRegRepeatArrow, Denote, Repeat, ih]

theorem denote_minor (self : Type) (data : List Type) (result : PsMinRegTy) (fields : List PsMinRegField) :
    Denote (self :: data) (psMinRegMinorTy result fields) = Minor data self (Denote (self :: data) result) fields := by
  rw [psMinRegMinorTy, denote_fields, denote_repeat] <;> rfl

theorem denote_recursor (self : Type) (data : List Type) (result : PsMinRegTy)
    (constructors : List (List PsMinRegField)) :
    Denote (self :: data) (psMinRegRecursorTy result constructors) =
      BranchArrow data self (Denote (self :: data) result) constructors := by
  induction constructors with
  | nil => rfl
  | cons fields rest ih => simp only [psMinRegRecursorTy, Denote, denote_minor, BranchArrow, ih]

def constructorValue (spec : PsMinRegSpec) (data : List Type) (index : Fin spec.constructors.length) :
    Denote (Carrier spec data :: data)
      (psMinRegFieldArrow (spec.constructors.get index) (PsMinRegTy.data 0)) :=
  cast (denote_fields (Carrier spec data) data (spec.constructors.get index) (PsMinRegTy.data 0)).symm
    (curryFields data (Carrier spec data) (spec.constructors.get index) (Carrier spec data)
      (construct spec data index))

def recursorValue (spec : PsMinRegSpec) (data : List Type) (result : PsMinRegTy) :
    Denote (Carrier spec data :: data) (psMinRegRecursorTy result spec.constructors) :=
  cast (denote_recursor (Carrier spec data) data result spec.constructors).symm
    (recursor spec data (Denote (Carrier spec data :: data) result))

def dataModel : List PsMinRegSpec → List Type
  | [] => []
  | spec :: rest => Carrier spec (dataModel rest) :: dataModel rest

structure SignatureModel (specs : List PsMinRegSpec) (data : List Type) where
  ctorValue : (slot constructorIndex : Nat) → (type : PsMinRegTy) →
    psMinRegCtorTypeAt specs slot constructorIndex = some type → Denote data type
  recValue : (fuel slot sortLevel parameters indices motives minors : Nat) →
    (result type : PsMinRegTy) →
    psMinRegRecursorTypeAt fuel specs slot sortLevel parameters indices motives minors result = some type → Denote data type

-- These lemmas connect positional lookup to the actual constructor index.
theorem ctor_bound (constructors : List (List PsMinRegField)) (index : Nat) (fields : List PsMinRegField)
    (success : psMinRegCtorAt constructors index = some fields) : index < constructors.length := by
  induction constructors generalizing index with
  | nil => simp [psMinRegCtorAt] at success
  | cons head rest ih =>
    cases index with
    | zero => exact Nat.zero_lt_succ _
    | succ index => exact Nat.succ_lt_succ (ih index success)

theorem ctor_get (constructors : List (List PsMinRegField)) (index : Fin constructors.length) :
    psMinRegCtorAt constructors index.val = some (constructors.get index) := by
  induction constructors with
  | nil => exact Fin.elim0 index
  | cons head rest ih =>
    cases index with
    | mk value bound =>
      cases value with
      | zero => rfl
      | succ value => exact ih ⟨value, Nat.lt_of_succ_lt_succ bound⟩

def signatures (specs : List PsMinRegSpec) : SignatureModel specs (dataModel specs) := by
  cases specs with
  | nil =>
    constructor
    · intro slot index type success; simp [psMinRegCtorTypeAt] at success
    · intro fuel slot sortLevel parameters indices motives minors result type success
      simp [psMinRegRecursorTypeAt] at success
  | cons spec rest =>
    let ih := signatures rest
    constructor
    · intro slot index type success
      cases slot with
      | zero =>
        cases hf : psMinRegCtorAt spec.constructors index with
        | none => simp [psMinRegCtorTypeAt, hf] at success
        | some fields =>
          have ht : psMinRegFieldArrow fields (PsMinRegTy.data 0) = type := by
            simpa [psMinRegCtorTypeAt, hf] using success
          cases ht
          let position : Fin spec.constructors.length := ⟨index, ctor_bound _ _ _ hf⟩
          have heq : spec.constructors.get position = fields :=
            Option.some.inj ((ctor_get spec.constructors position).symm.trans hf)
          exact heq ▸ constructorValue spec (dataModel rest) position
      | succ slot =>
        cases ht : psMinRegCtorTypeAt rest slot index with
        | none => simp [psMinRegCtorTypeAt, ht] at success
        | some prior =>
          have heq : psMinRegLiftTy prior = type := by simpa [psMinRegCtorTypeAt, ht] using success
          cases heq
          exact cast (denote_lift (Carrier spec (dataModel rest)) (dataModel rest) prior).symm
            (ih.ctorValue slot index prior ht)
    · intro fuel slot sortLevel parameters indices motives minors result type success
      cases slot with
      | zero =>
        by_cases allowed : psMinRegRecursorAllowed fuel (Nat.succ (psMinRegSpecCount rest)) spec
            sortLevel parameters indices motives minors result = true
        · have ht : psMinRegRecursorTy result spec.constructors = type := by
            simpa [psMinRegRecursorTypeAt, allowed] using success
          cases ht
          exact recursorValue spec (dataModel rest) result
        · simp [psMinRegRecursorTypeAt, allowed] at success
      | succ slot =>
        cases ht : psMinRegRecursorTypeAt fuel rest slot sortLevel parameters indices motives minors result with
        | none => simp [psMinRegRecursorTypeAt, ht] at success
        | some prior =>
          have heq : psMinRegLiftTy prior = type := by simpa [psMinRegRecursorTypeAt, ht] using success
          cases heq
          exact cast (denote_lift (Carrier spec (dataModel rest)) (dataModel rest) prior).symm
            (ih.recValue fuel slot sortLevel parameters indices motives minors result prior ht)

termination_by structural specs

#print axioms join_split
#print axioms fold_construct
#print axioms constructorValue
#print axioms recursorValue
#print axioms signatures

end Ps.MinKernel.RegularModel
