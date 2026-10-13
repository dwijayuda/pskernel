import Init

/-!
  Independent Lean 4.35.0 source oracle for the selected PSCV0 GetElem
  foundation. This is compiled by the official Lean checker, not by the
  PSCV0 parser/elaborator, and is deliberately kept out of the selected
  Standard environment's TCB.
-/

namespace Pscv0GetElemOracle

structure IndexBox where
  value : Nat

instance : GetElem IndexBox Nat Nat (fun _ i => i = 0) where
  getElem xs _ _ := xs.value

def checkedAtZero (xs : IndexBox) : Nat := xs[0]
def checkedWithProof (xs : IndexBox) (i : Nat) (h : i = 0) : Nat := xs[i]'h
def checkedWithAssumption (xs : IndexBox) (i : Nat) (h : i = 0) : Nat := xs[i]

example : checkedAtZero ⟨23⟩ = 23 := rfl
example : checkedWithProof ⟨19⟩ 0 rfl = 19 := rfl
example : checkedWithAssumption ⟨17⟩ 0 rfl = 17 := rfl

structure AlwaysBox where
  value : Nat

instance : GetElem AlwaysBox Nat Nat (fun _ _ => True) where
  getElem xs _ _ := xs.value

example : (⟨29⟩ : AlwaysBox)[42] = 29 := rfl

structure ProductProofBox where
  value : Nat

instance : GetElem ProductProofBox Nat Nat (fun _ _ => True ∧ True) where
  getElem xs _ _ := xs.value

example : (⟨31⟩ : ProductProofBox)[42] = 31 := rfl

-- Upstream GetElem? is an actual superclass extension. These witnesses are
-- intentionally *oracle-only* until PSCV0 implements the lawful Option and
-- panic/default contracts without dropping genuine validity evidence.
example : (⟨23⟩ : IndexBox)[0]? = some 23 := by decide
example : (⟨23⟩ : IndexBox)[1]? = none := by decide

-- Independent order oracle for the M1 successor/inversion/reflection contract.
example : Nat.le 2 5 := show 2 ≤ 5 from by decide
example : ¬Nat.le 5 2 := show ¬(5 ≤ 2) from by decide
example (n : Nat) : Nat.le 0 n := Nat.zero_le n
example (n m : Nat) (h : Nat.le n m) :
    Nat.le (Nat.succ n) (Nat.succ m) := Nat.succ_le_succ h
example (n m : Nat) (h : Nat.le (Nat.succ n) (Nat.succ m)) :
    Nat.le n m := Nat.le_of_succ_le_succ h
example (n : Nat) : ¬Nat.lt n 0 := Nat.not_lt_zero n
example (n m k : Nat) (h : Nat.le n m) (q : Nat.le m k) :
    Nat.le n k := Nat.le_trans h q
example (n m : Nat) (h : Nat.lt (Nat.succ n) (Nat.succ m)) :
    Nat.lt n m := Nat.lt_of_succ_lt_succ h
example : decide (184467440737095516170 ≤ 184467440737095516171) = true := rfl

universe u v

structure UniverseBox (α : Type u) where
  value : α
instance {α : Type u} : GetElem (UniverseBox α) Nat α (fun _ _ => True) where
  getElem xs _ _ := xs.value
example {α : Type u} : LawfulGetElem (UniverseBox α) Nat α (fun _ _ => True) := inferInstance
def bindUniverses {α : Type u} {β : Type v} (f : α → β) (xs : Option α) : Option β :=
  xs.bind (fun x => some (f x))
def doUniverse {α β : Type u} (f : α → β) (xs : Option α) : Option β := do
  let x ← xs
  return f x
example : doUniverse (fun x : ULift.{1} Nat => x) (some ⟨373⟩) = some ⟨373⟩ := rfl
example : bindUniverses (fun n : Nat => ULift.up.{1} n) (some 373) = some ⟨373⟩ := rfl
example : (⟨ULift.up.{1} 359⟩ : UniverseBox (ULift.{1} Nat))[0]? = some ⟨359⟩ := rfl
example {α : Type u} : (default : Option α) = none := rfl
example (i j size : Nat) (h : i < j) (k : j ≤ size) : i < size := by omega


-- List algorithms and Fin adapters retain the collection-specific bound.
example : ([401, 409] : List Nat)[1] = 409 := rfl
example : ([431, 433] : List Nat)[1]? = some 433 := rfl
example : ([] : List Nat)[0]? = none := rfl
example : ([449] : List Nat)[184467440737095516170]? = none := rfl
def finSeed : Fin 10 := ⟨1, by decide⟩
example : ([463, 467] : List Nat)[finSeed]? = some 467 := rfl
example : ([479] : List Nat)[finSeed]? = none := rfl
example : LawfulGetElem (List Nat) Nat Nat (fun xs i => i < xs.length) := inferInstance
example : LawfulGetElem (List Nat) (Fin 10) Nat (fun xs i => i.val < xs.length) := inferInstance
example : (List.get [509, 521] ⟨1, by decide⟩) = 521 := rfl

-- The logical Array structure and optimized operations have the same observables.
example : (#[541, 547] : Array Nat)[1] = 547 := rfl
example : (#[577] : Array Nat)[184467440737095516170]? = none := rfl
example : (#[587] : Array Nat)[finSeed]? = none := rfl
example : LawfulGetElem (Array Nat) Nat Nat (fun xs i => i < xs.size) := inferInstance
example : (Array.mk [613, 617])[1] = 617 := rfl
example : ([619, 631].toArray.toList)[1]? = some 631 := rfl
example : (Array.mk [false, true]).toList[1]? = some true := rfl
example : (#[2, 3, 5, 7] : Array Nat).foldl Nat.add 0 1 3 = 8 := rfl
example : (#[2, 3] : Array Nat).foldl Nat.add 661
    184467440737095516170 184467440737095516171 = 661 := rfl
example : (#[653] : Array Nat).setIfInBounds 184467440737095516170 0 = #[653] := rfl

structure CustomIndex where
  value : Nat
instance : GetElem CustomIndex Nat Nat (fun _ _ => True) where
  getElem xs _ _ := xs.value
instance (priority := high) customOptional : GetElem? CustomIndex Nat Nat (fun _ _ => True) where
  getElem? _ _ := none
  getElem! _ _ := default
example : (CustomIndex.mk 701)[0]? = none := rfl
example : (CustomIndex.mk 701)[finSeed]? = none := rfl
example : True := by
  fail_if_success have := (inferInstance : LawfulGetElem CustomIndex Nat Nat (fun _ _ => True))
  fail_if_success have := (inferInstance : LawfulGetElem CustomIndex (Fin 10) Nat (fun _ _ => True))
  trivial

end Pscv0GetElemOracle

-- Independent pinned-Lean oracle for deterministic seeded-cycle resolution.
namespace Pscv0InstanceGraphOracle
class A where
  value : Nat
class B where
  value : Nat
class Result where
  value : Nat
instance seed : A where
  value := 733
instance (priority := high) fromB [B] : A where
  value := B.value
instance fromA [A] : B where
  value := A.value
instance combine [A] [B] : Result where
  value := A.value + B.value
example : Result.value = 1466 := rfl
end Pscv0InstanceGraphOracle

-- Pinned deriving semantics, independent of the portable Core generator.
namespace Pscv0DerivingOracle
universe u v
inductive Choice (α : Type u) : Type u where
  | value (payload : α)
  | empty
deriving Inhabited, BEq
structure Pair (α : Type u) (β : Type v) where
  first : α
  second : β
deriving Inhabited, BEq
structure Phantom (α : Type u) (β : Type v) where
  value : α
deriving Inhabited
structure Tagged (α : Type u) (n : Nat) where
  value : α
deriving Inhabited, BEq
structure Lift (α : Type) : Type 1 where
  value : α
deriving Inhabited, BEq
structure SortBox (α : Sort u) where
  value : α
deriving Inhabited
example {α : Type u} : (default : Choice α) = .empty := rfl
example {α : Type u} {β : Type v} [Inhabited α] :
    (default : Phantom α β).value = (default : α) := rfl
example {α : Sort u} [Inhabited α] : (default : SortBox α).value = (default : α) := rfl
example : ((default : Pair (Lift Nat) Nat).first).value = 0 := rfl
example : (Pair.mk (Lift.mk 751) 3 == Pair.mk (Lift.mk 751) 3) = true := rfl
example : (Pair.mk (Lift.mk 751) 3 == Pair.mk (Lift.mk 751) 4) = false := rfl
example : (Choice.value (Lift.mk 757) == Choice.value (Lift.mk 757)) = true := rfl
example : (Choice.value (Lift.mk 757) == Choice.empty) = false := rfl
example : ((Tagged.mk 5 : Tagged Nat 7) == Tagged.mk 5) = true := rfl
structure Nested (α : Type u) where
  value : Option α
deriving Inhabited, BEq
example {α : Type u} : (default : Nested α).value = none := rfl
example : ((Nested.mk (some (Lift.mk 761))).value.getD (Lift.mk 0)).value = 761 := rfl
end Pscv0DerivingOracle

-- Generalized instance answers are specialized by later dependencies; the
-- same generic generator must be reusable at independent output types.
namespace Pscv0GeneralizedOracle
universe u
class Evidence (A : outParam (Type u)) where
  value : Nat
def generic (A : Type u) : Evidence A := ⟨773⟩
class Select (n : Nat) (A : outParam Type) where
  value : Nat
instance : Select 0 Nat where
  value := 5
instance : Select 1 Bool where
  value := 7
class Branch (n : Nat) where
  value : Nat
instance {n : Nat} {A : Type} [Evidence A] [Select n A] : Branch n where
  value := Evidence.value (A := A) + Select.value (n := n) (A := A)
class Result where
  value : Nat
instance [Branch 0] [Branch 1] : Result where
  value := Branch.value (n := 0) + Branch.value (n := 1)
def combined [poly : (A : Type) → Evidence A] (_ : Unit) : Nat := Result.value
example : combined (poly := generic) () = 1558 := rfl
def selected (A : Type := Nat) [Inhabited A] (value : A := default) : A := value
def expected {A : Type} [Inhabited A] (_ : Unit) (value : A := default) : A := value
example : selected = 0 := rfl
example : expected () = false := rfl
example [poly : (A : Type) → Evidence A] : True := by
  fail_if_success have : Nat := Evidence.value
  fail_if_success have : Bool := selected
  trivial
end Pscv0GeneralizedOracle

namespace Pscv0GeneralizedIndexOracle
class Evidence (n : outParam Nat) where
  value : Nat
def generic (n : Nat) : Evidence n := ⟨n⟩
class Select (key : Nat) (n : outParam Nat) where
  value : Nat
instance : Select 0 5 where
  value := 773
instance : Select 1 7 where
  value := 773
class Branch (key : Nat) where
  value : Nat
instance {key n : Nat} [Evidence n] [Select key n] : Branch key where
  value := Evidence.value (n := n) + Select.value (key := key) (n := n)
class Result where
  value : Nat
instance [Branch 0] [Branch 1] : Result where
  value := Branch.value (key := 0) + Branch.value (key := 1)
def combined [poly : (n : Nat) → Evidence n] (_ : Unit) : Nat := Result.value
example : combined (poly := generic) () = 1558 := rfl
end Pscv0GeneralizedIndexOracle

-- Equality/defaults oracle uses upstream handlers, independently of Core generation.
namespace Pscv0DerivingEqualityOracle
universe u v
structure Pair (A : Type u) (B : Type v) where
  first : A
  second : B
deriving DecidableEq, BEq
inductive Event (A : Type u) : Type u where
  | empty
  | value (payload : A)
  | label (text : String)
deriving DecidableEq, BEq
structure Lift (A : Type) : Type 1 where
  value : A
deriving DecidableEq
structure Checked where
  count : Nat := 797
  witness : count = count := by rfl
deriving Inhabited, BEq, DecidableEq
structure Seeded (A : Type u) (seed : A) where
  value : A := seed
deriving Inhabited
inductive Void where
deriving BEq, DecidableEq
example : decide (Pair.mk (Lift.mk 787) "x" = Pair.mk (Lift.mk 787) "x") = true := rfl
example : decide (Event.value 787 = Event.value 788) = false := rfl
example : decide (Event.value 787 = Event.label "x") = false := rfl
example : decide ((Event.label "λ😀" : Event Nat) = Event.label "λ😀") = true := rfl
example : (default : Checked).count = 797 := rfl
example : ({} : Checked).count = 797 := rfl
example : ({ count := 809 } : Checked).count = 809 := rfl
example {A : Type u} (seed : A) : (default : Seeded A seed).value = seed := rfl
example : (({} : Checked) == {}) = true := rfl
example : decide (({} : Checked) = {}) = true := rfl
example : decide (({} : Checked) = { count := 809 }) = false := rfl
end Pscv0DerivingEqualityOracle

namespace Pscv0PostponedOracle
structure Box where
  value : Nat
def choose {A : Type} (first second : A) : A := first
def apply {A B : Type} (fn : A → B) (value : A) : B := fn value
def proof {P : Prop} (_ _ : P) : Nat := 823
def readLater {A : Type} (first _ : A) (read : A → Nat) : Nat := read first
example : readLater { value := 821 } (Box.mk 0) Box.value = 821 := rfl
example : apply (fun x => x.value) (Box.mk 827) = 827 := rfl
example : proof (by constructor) True.intro = 823 := rfl
example : choose 829 (Int.ofNat 0) = (829 : Int) := rfl
example : choose 839 0 = 839 := rfl
example : (choose (second := Box.mk 0) (first := { value := 853 })).value = 853 := rfl
end Pscv0PostponedOracle

namespace Pscv0NumericOracle
structure Ticket where
  value : Nat
instance {n : Nat} : OfNat Ticket n where
  ofNat := Ticket.mk n
def generic {A : Type} [OfNat A 857] (_ : Unit) : A := 857
structure Lift (A : Type) : Type 1 where
  value : A
instance {n : Nat} : OfNat (Lift Nat) n where
  ofNat := Lift.mk n
example : (859 : Ticket).value = 859 := rfl
example : (generic () : Ticket).value = 857 := rfl
example : (863 : Lift Nat).value = 863 := rfl
end Pscv0NumericOracle

namespace Pscv0CoercionOracle
structure Box where
  value : Nat
instance : Coe Box Nat where
  coe := Box.value
def boxed (_ : Unit) : Box := Box.mk 877
def accept (value : Nat) := value
structure Callable where
  run : Nat → Nat
instance : CoeFun Callable (fun _ => Nat → Nat) where
  coe := Callable.run
structure Action where
  run : Unit → Nat
instance : CoeFun Action (fun _ => Unit → Nat) where
  coe := Action.run
structure Carrier where
  carrier : Type
instance : CoeSort Carrier Type where
  coe := Carrier.carrier
def natural : Carrier := Carrier.mk Nat
def identity (value : natural) : natural := value
def fromLocal {A : Type} [Coe A Nat] (value : A) : Nat := value
example : accept (Box.mk 877) = 877 := rfl
example : (boxed () : Nat) = 877 := rfl
example : (Callable.mk (fun x => x + 1)) 880 = 881 := rfl
example : (Action.mk (fun _ => 883)) () = 883 := rfl
example : identity (887 : Nat) = (887 : Nat) := rfl
example : fromLocal (Box.mk 907) = 907 := rfl
def invoke [CoeFun Callable (fun _ => Nat → Nat)] (value : Callable) : Nat := value 919
structure FamilyBox (A : Type) (F : A → Type) where
  value : (x : A) → F x
def familyBox : FamilyBox Nat (fun _ => Nat) := ⟨fun x => x + 2⟩
example : invoke (Callable.mk (fun x => x + 1)) = 920 := rfl
example : familyBox.value 927 = 929 := rfl
end Pscv0CoercionOracle

namespace Pscv0TransparencyOracle
def Hidden : Type := Nat
abbrev Clear : Type := Nat
example : Clear := 937
example : Inhabited Clear := inferInstance
example [Inhabited Hidden] : Inhabited Hidden := inferInstance
example : Hidden := (937 : Nat)
example : True := by
  fail_if_success have : Inhabited Hidden := inferInstance
  fail_if_success have : Hidden := 937
  trivial
class Evidence (A : Type) where
  value : A
example [Evidence Nat] : Evidence (optParam Nat 0) := inferInstance
example [Evidence Nat] : True := by
  fail_if_success have : Evidence (Id Nat) := inferInstance
  trivial
end Pscv0TransparencyOracle

namespace Pscv0QuoteOracle
-- Upstream String.Internal.append is opaque to kernel reduction. Compare the
-- native implementation directly; these are runtime oracle checks, not proofs.
#eval show IO Unit from do
  let cases : List (String × String) :=
    [(String.quote "", "\"\""),
     (String.quote "a\\b\"c\n\t\r\x7f", "\"a\\\\b\\\"c\\n\\t\\x0d\\x7f\""),
     (String.quote "λ😀'", "\"λ😀'\""),
     (Char.quote (Char.ofNat 39), "'\\''"),
     (Char.quoteCore (Char.ofNat 39) true, "'")]
  for (actual, expected) in cases do
    unless actual == expected do
      throw (IO.userError s!"quoting oracle mismatch: {String.quote actual} != {String.quote expected}")
end Pscv0QuoteOracle

namespace Pscv0IntConversionOracle
-- Structural definition cases plus the boundary from upstream int_to_nat_bug.
example : Int.toNat (-184467440737095516170) = 0 := rfl
example : Int.toNat 0 = 0 := rfl
example : Int.toNat 184467440737095516170 = 184467440737095516170 := rfl
def useConversion (convert : Int → Nat) (value : Int) : Nat := convert value
example : useConversion Int.toNat 4294967295 = 4294967295 := rfl
end Pscv0IntConversionOracle

namespace Pscv0FormatOracle
open Std.Format
def pair (a b : Std.Format) := append a (append line b)
#eval show IO Unit from do
  let hard := pair (text "A\nB") (text "C")
  let filled := append (fill (pair (text "a") (pair (text "b\nlooooooooong") (text "c"))))
    (append line (text "d"))
  let unicode := group (pair (text "λ😀") (text "x"))
  let aligned := fun force => append (text ".") (append (align force) (pair (text "a") (text "b")))
  let cases : List (String × String) := [
    (pretty hard, "A\nB\nC"),
    (pretty (group hard) 10, "A\nB C"),
    (pretty filled 5, "a b\nlooooooooong\nc\nd"),
    (pretty unicode 4, "λ😀 x"),
    (pretty unicode 3, "λ😀\nx"),
    (pretty (nest (-4) (group (pair (text "a") (text "b")))) 1 2, "a\nb"),
    (pretty (nest 2 (aligned false)), ". a\n  b"),
    (pretty (nest 2 (group (aligned true))), ". a b"),
    (pretty (group (pair (text "a") (text "b"))) 3 2 1, "a\n  b")]
  for (actual, expected) in cases do
    unless actual == expected do
      throw (IO.userError s!"format oracle mismatch: {String.quote actual} != {String.quote expected}")
  unless isEmpty (tag 17 (append (text "") (align false))) && !isNil (text "") do
    throw (IO.userError "format empty/nil oracle mismatch")
end Pscv0FormatOracle

-- Same compact cases through the pinned upstream classes and deriving handler.
namespace Display
universe u
structure Box (A : Type u) where
  value : A
deriving Repr
structure Checked where
  count : Nat
  witness : count = count
deriving Repr
structure Types : Type 1 where
  carrier : Type
  witness : True
deriving Repr
inductive Event (A : Type u) where
  | empty
  | value (payload : A)
deriving Repr
inductive Hidden where
  | item {secret : Nat} (value : Nat)
deriving Repr
inductive Void where
deriving Repr
#eval show IO Unit from do
  let cases : List (String × String) := [
    (reprStr "λ😀\n", "\"λ😀\\n\""),
    ((reprArg (-17 : Int)).pretty, "(-17)"),
    (reprStr (some (some (17 : Nat))), "some (some 17)"),
    (reprStr (Box.mk "x"), "{ value := \"x\" }"),
    (reprStr (Checked.mk 19 rfl), "{ count := 19, witness := _ }"),
    (reprStr (Types.mk Nat True.intro), "{ carrier := _, witness := _ }"),
    (reprStr (Event.value (some (23 : Nat))), "Display.Event.value (some 23)"),
    ((reprArg (Event.empty : Event Nat)).pretty, "(Display.Event.empty)"),
    (reprStr (Hidden.item (secret := 41) 43), "Display.Hidden.item 43"),
    ((repr ([1, 2, 3, 4] : List Nat)).pretty 8, "[1, 2,\n 3, 4]"),
    ((repr [some (1 : Nat), some 2, some 3]).pretty 18, "[some 1,\n some 2,\n some 3]"),
    ((Std.format (Std.Format.group (Std.Format.append (Std.Format.text "a")
      (Std.Format.append Std.Format.line (Std.Format.text "b"))))).pretty 3, "a b"),
    ((Std.format (29 : Nat)).pretty, "29"),
    ((Std.Format.joinSep ["a", "b", "c"] (Std.Format.text "|")).pretty, "a|b|c"),
    ((Std.Format.prefixJoin (Std.Format.text ">") ["a", "b"]).pretty, ">a>b"),
    ((Std.Format.joinSuffix ["a", "b"] (Std.Format.text "!")).pretty, "a!b!"),
    (reprStr (Box.mk (Types.mk Nat True.intro)), "{ value := { carrier := _, witness := _ } }")]
  for (actual, expected) in cases do
    unless actual == expected do
      throw (IO.userError s!"Repr/ToFormat oracle: {String.quote actual} != {String.quote expected}")
-- Polymorphic collection operations retain independent input/output universes.
example {A : Type u} (xs : List A) : List.map (fun x => x) xs = xs := by simp
example {A : Type u} [Std.ToFormat A] : Std.Format :=
  Std.Format.joinSep ([] : List A) Std.Format.line
end Display

namespace Pscv0CollectionDisplayOracle
#eval show IO Unit from do
  let cases : List (String × String) := [
    (reprStr ((3 : Nat), "x", true), "(3, \"x\", true)"),
    ((repr #[some (1 : Nat), some 2, some 3]).pretty 20, "#[some 1, some 2,\n  some 3]"),
    (reprStr (⟨3, by decide⟩ : Fin 4), "3"),
    ((Std.Format.group (String.toFormat "λ\n\nx")).pretty, "λ  x"),
    ((Std.Format.group (("a" : Std.Format) ++ Std.Format.line ++ "b")).pretty 3, "a b"),
    ((Std.format ("x", true)).pretty, "(x, true)"),
    ((Std.format (#[1, 2, 3] : Array Nat)).pretty, "#[1, 2, 3]"),
    (reprStr (31 : Id Nat), "31"),
    ((reprArg (Decidable.isTrue True.intro)).pretty, "(isTrue _)"),
    (reprStr (Nat.decLt 4 3), "isFalse _"),
    (Nat.repr 47, "47")]
  for (actual, expected) in cases do
    unless actual == expected do
      throw (IO.userError s!"collection display oracle: {String.quote actual} != {String.quote expected}")
end Pscv0CollectionDisplayOracle

namespace Pscv0ListUniverseOracle
universe u
def emptyList {A : Type u} (_ : Unit) : List A := default
def equalLists {A : Type u} [BEq A] (xs ys : List A) : Bool := List.beq xs ys
example : emptyList (A := Type) () = [] := rfl
example {A : Type u} [BEq A] : equalLists ([] : List A) [] = true := rfl
end Pscv0ListUniverseOracle

namespace Pscv0ArithmeticModelOracle
example (n : Nat) : Nat.add n 0 = n := rfl
example (n m : Nat) : Nat.add n (Nat.succ m) = Nat.succ (Nat.add n m) := rfl
example (n : Nat) : Nat.sub n 0 = n := rfl
example (n m : Nat) : Nat.sub n (Nat.succ m) = Nat.pred (Nat.sub n m) := rfl
example (n m : Nat) : Nat.mul n (Nat.succ m) = Nat.add (Nat.mul n m) n := rfl
example (n m : Nat) : Nat.beq (Nat.succ n) (Nat.succ m) = Nat.beq n m := rfl
end Pscv0ArithmeticModelOracle

-- Nondependent conditionals retain the decision's checked computational branch.
example (P : Prop) (h : P) (n : Nat) : @ite Nat P (.isTrue h) n 0 = n := rfl
example (P : Prop) (h : ¬P) (n : Nat) : @ite Nat P (.isFalse h) 0 n = n := rfl

-- Genuine upstream modulus reduction and proof, independent of exported Core.
example (n : Nat) : Nat.mod 0 n = 0 := rfl
example (x y : Nat) (h : Nat.lt 0 y) : Nat.lt (Nat.mod x y) y := Nat.mod_lt x h
def boundedModOracle (x y : Nat) (h : Nat.lt 0 y) : Fin y := ⟨Nat.mod x y, Nat.mod_lt x h⟩

-- Pinned native conversion oracle, independent of the portable Core asset.
namespace Pscv0UnsignedOracle
example (value : UInt64) : Nat.lt (UInt64.toNat value) UInt64.size := Fin.isLt (UInt64.toFin value)
#guard (UInt8.ofNat 259).toNat == 3
#guard (UInt16.ofNat 65539).toNat == 3
#guard (UInt32.ofNat 4294967299).toNat == 3
#guard (UInt64.ofNat 340282366920938463481821351505477763075).toNat == 3
#guard (UInt64.ofNat 18446744073709551615).toNat == 18446744073709551615
#guard (18446744073709551619 : UInt64).toNat == 3
#guard (BitVec.ofNat 0 15).toNat == 0
#guard (BitVec.ofNat 4 17).toNat == 1
#guard (BitVec.ofNat 128 340282366920938463463374607431768211459).toNat == 3
#guard Nat.pow 0 0 == 1
#guard Nat.pow 3 40 == 12157665459056928801
end Pscv0UnsignedOracle
