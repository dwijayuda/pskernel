import Std
set_option autoImplicit false

namespace CompleteReferenceExamples

def greet (name : String) : String := "Hello, " ++ name
def greeting : String := greet "Ada"
theorem greetAda : greet "Ada" = "Hello, Ada" := by rfl

def decorate (name : String) (suffix : String := "!") : String := name ++ suffix
def label : String := decorate "Ada" (suffix := "?")
theorem namedDefault : decorate "Ada" = "Ada!" := by rfl
theorem namedExplicit : label = "Ada?" := by rfl

universe u
def identity {α : Type u} (x : α) : α := x
def retain (n : Nat) (i : Fin n) : Fin n := i
theorem retainedBound (n : Nat) (i : Fin n) : (retain n i).val < n := i.isLt

structure User where
  name : String
  active : Bool
def activate (user : User) : User := { user with active := true }
def decoratedNames (users : List User) : List String := users.map (fun user => user.name ++ "!")
theorem activation (user : User) : (activate user).active = true := by rfl

def getOrElse (value : Option Nat) (fallback : Nat) : Nat :=
  match value with
  | .none => fallback
  | .some n => n
theorem someValue (n fallback : Nat) : getOrElse (.some n) fallback = n := by rfl
theorem noneValue (fallback : Nat) : getOrElse .none fallback = fallback := by rfl

inductive Tree (α : Type) where
  | leaf (value : α)
  | branch (left : Tree α) (right : Tree α)

class Sized (α : Type) where
  size : α → Nat
instance : Sized String where
  size (s : String) : Nat := s.length

structure Count where
  value : Nat
instance : Coe Count Nat where
  coe c := c.value
def countValue (c : Count) : Nat := c
theorem coercedCount (c : Count) : countValue c = c.value := by rfl

def total (xs : List Nat) : Nat := Id.run do
  let mut result := 0
  for x in xs do
    result := result + x
  return result
theorem totalExample : total [1,2,3] = 6 := by decide

def incrementTwice (n : Nat) : Nat := helper (helper n)
where
  helper (x : Nat) : Nat := x + 1
theorem helperExample : incrementTwice 2 = 4 := by rfl

theorem twoTruths : True ∧ True := by { constructor; trivial; trivial }
theorem twoTruthsAll : True ∧ True := by { constructor <;> trivial }
theorem swapAnd {P Q : Prop} (h : P ∧ Q) : Q ∧ P := by exact ⟨h.right,h.left⟩
theorem existsSelf (n : Nat) : ∃ m : Nat, m = n := by exact ⟨n,rfl⟩
theorem equalityChain {α : Type} (a b c : α) (hab : a = b) (hbc : b = c) : a = c := by grind

theorem underflow : (2 : Nat) - 5 = 0 := by decide
theorem integerEuclidean : (-5 : Int) / 2 = -3 := by decide
infixl:65 " <+> " => Nat.add
def combined (x y : Nat) : Nat := x <+> y
theorem operatorExample : combined 2 3 = 5 := by rfl

def announce (name : String) : IO Unit := do
  IO.println ("Hello, " ++ name)
  IO.println "Done"

#print axioms equalityChain
#print axioms totalExample
end CompleteReferenceExamples
