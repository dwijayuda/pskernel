import Ps.Host.NativeV7

namespace M3InputParityOracle
namespace Shared
section
variable (seed : Nat)
def addSeed (n : Nat) : Nat := Nat.add seed n
end
def withDefault (n : Nat := 3) : Nat := Nat.succ n
end Shared
open Shared
def m3parity (flag : Bool) : UInt64 :=
  UInt64.ofNat (if flag then addSeed 8 5 else withDefault 3)
def grouped {T : Type} {first value : T} := value
example : @grouped Nat 3 4 = 4 := rfl
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def shadow {T : Type} {T value : T} := value
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def lambdaShadow : (T : Type) → T → T → T := fun (T : Type) (T value : T) => value
/-- error: type expected -/
#guard_msgs (error, drop warning, substring := true) in
def globalShadow : Nat → Nat → Nat := fun (Nat value : Nat) => value
example : m3parity false = 4 := rfl
example : m3parity true = 13 := rfl
structure ParityBox where
  value : Nat
  deriving Inhabited, BEq
inductive ParityMaybe where
  | none
  | some (value : Nat)
  deriving Inhabited, BEq
class Sized (A : Type) where
  size : A → Nat
@[default_instance 200]
instance (priority := high) sizedNat : Sized Nat where
  size n := n
def m3data (flag : Bool) : UInt64 :=
  let b := ParityBox.mk (keep (if flag then 6 else 9))
  let packed := ParityMaybe.some (Sized.size b.value)
  UInt64.ofNat (match packed with
    | ParityMaybe.none => 0
    | ParityMaybe.some value => if b == b then value else 0)

where
  keep (n : Nat) : Nat :=
    match n with
    | 0 => 0
    | Nat.succ k => Nat.succ (keep k)
  termination_by n
  decreasing_by exact Nat.lt_succ_self k

example : m3data true = 6 := by simp [m3data, m3data.keep]; rfl
example : m3data false = 9 := by simp [m3data, m3data.keep]; rfl
def m3control (flag : Bool) : UInt64 :=
  let (left, right) : Nat × Nat := (2, 3)
  let amount : Option Nat := do
    let (x, y) : Nat × Nat ← Option.some (left, right)
    if !flag then
      if let .some n := Option.some (x + y) then
        return n
    else if flag then
      return 7
    return 11
  let extra : Id Nat := do { let n := 1; return n; }
  let extraValue : Nat := extra
  let extraApplied : Nat := (fun (f : Nat → Nat) => f extraValue) fun (n : Nat) => n
  UInt64.ofNat (if let .some n := amount then n + extraApplied else 0)

example : m3control false = 6 := rfl
example : m3control true = 8 := rfl
def doArgument : Option Nat := (fun (value : Option Nat) => value) do return 1
example : doArgument = Option.some 1 := rfl
mutual
def parityFirst {A : Type} (a : A) (n : Nat) : Nat → A :=
  fun (k : Nat) => match n with
    | 0 => a
    | Nat.succ m => let kept := a; paritySecond m A kept k
termination_by n
def paritySecond (n : Nat) (B : Type) (b : B) : Nat → B :=
  fun (k : Nat) => match n with
    | 0 => b
    | Nat.succ m => parityThird m b k
termination_by n
def parityThird {C : Type} (n : Nat) (c : C) : Nat → C :=
  fun (k : Nat) => match n with
    | 0 => c
    | Nat.succ m => parityFirst (n := m) c k
termination_by n
end
def m3mutual (flag : Bool) : UInt64 :=
  UInt64.ofNat (parityFirst (if flag then 7 else 11) (if flag then 6 else 4) 2)

example : m3mutual true = 7 := by simp [m3mutual, parityFirst, paritySecond, parityThird]
example : m3mutual false = 11 := by simp [m3mutual, parityFirst, paritySecond, parityThird]
partial def parityPartial (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (parityPartial k)
def parityFixed (seed : Nat) (n : Nat) : Nat :=
  match n with
  | 0 => seed
  | Nat.succ k => parityFixed seed k
partial_fixpoint
def m3strategies (flag : Bool) : UInt64 :=
  UInt64.ofNat (parityPartial (if flag then 4 else 3) +
    100 * parityFixed (if flag then 7 else 9) (if flag then 3 else 4))

instance parityFunctionHash {A : Type} : Hashable (forall (i : Nat), i = i → A) where
  hash (_ : forall (i : Nat), i = i → A) := UInt64.ofNat 17
inductive ParityBranch where
  | leaf (value : Nat)
  | node (children : forall (i : Nat), i = i → ParityBranch)
  deriving Hashable
theorem branchNodeHash (children : forall (i : Nat), i = i → ParityBranch) :
    Hashable.hash (ParityBranch.node children) = mixHash (UInt64.ofNat 1) (UInt64.ofNat 17) := rfl
def branchFold (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => value
  | ParityBranch.node children => Nat.succ (branchFold (children 2 (Eq.refl 2)))
mutual
def branchFirst (bias : Nat) (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => bias + value
  | ParityBranch.node children => branchSecond (children 3 (Eq.refl 3)) (bias + 1)
def branchSecond (tree : ParityBranch) (bias : Nat) : Nat :=
  match tree with
  | ParityBranch.leaf value => bias + value
  | ParityBranch.node children => branchFirst (bias + 2) (children 4 (Eq.refl 4))
end
noncomputable def branchByRec (tree : ParityBranch) : Nat :=
  ParityBranch.rec (motive := fun (_ : ParityBranch) => Nat)
    (fun (value : Nat) => value)
    (fun (children : forall (i : Nat), i = i → ParityBranch) (ih : forall (i : Nat), i = i → Nat) =>
      Nat.succ (ih 5 (Eq.refl 5))) tree
theorem branchRefl (tree : ParityBranch) : branchFold tree = branchFold tree :=
  ParityBranch.rec (motive := fun (t : ParityBranch) => branchFold t = branchFold t)
    (fun (value : Nat) => Eq.refl value)
    (fun (children : forall (i : Nat), i = i → ParityBranch)
      (ih : forall (i : Nat) (h : i = i), branchFold (children i h) = branchFold (children i h)) =>
      congrArg Nat.succ (ih 2 (Eq.refl 2))) tree
-- Lean's code generator does not execute this primitive recursor. Retain its
-- checked definition and prove the separately executable structural oracle.
def branchByRecExec (tree : ParityBranch) : Nat :=
  match tree with
  | ParityBranch.leaf value => value
  | ParityBranch.node children => Nat.succ (branchByRecExec (children 5 (Eq.refl 5)))

theorem branchByRec_agrees (tree : ParityBranch) : branchByRec tree = branchByRecExec tree := by
  induction tree with
  | leaf value => rfl
  | node children ih => exact congrArg Nat.succ (ih 5 (Eq.refl 5))

def m3fields (flag : Bool) : UInt64 :=
  let seed := if flag then 7 else 11
  let tree := ParityBranch.node (fun (i : Nat) (h : i = i) =>
    ParityBranch.node (fun (j : Nat) (g : j = j) => ParityBranch.leaf (seed + i + j)))
  let mark : Nat := if Hashable.hash tree == mixHash (UInt64.ofNat 1) (UInt64.ofNat 17) then 0 else 1
  UInt64.ofNat (branchFold tree + 100 * branchFirst 3 tree + 10000 * branchByRecExec tree + mark)

example : m3fields true = 192013 := by
  simp only [m3fields, branchNodeHash, BEq.rfl, ite_true]
  rfl
example : m3fields false = 232417 := by
  simp only [m3fields, branchNodeHash, BEq.rfl, ite_true]
  rfl

def argumentOrder (x y z : Nat) : Nat := 100 * x + 10 * y + z
example : argumentOrder (y := 2) 1 3 = 123 := rfl
example : argumentOrder 1 (x := 2) 3 = 213 := rfl

mutual
def proofFirst (n : Nat) : n = n :=
  match n with
  | 0 => Eq.refl 0
  | Nat.succ k => congrArg Nat.succ (proofSecond k)
def proofSecond (n : Nat) : n = n :=
  match n with
  | 0 => Eq.refl 0
  | Nat.succ k => congrArg Nat.succ (proofThird k)
def proofThird (n : Nat) : n = n :=
  match n with
  | 0 => Eq.refl 0
  | Nat.succ k => congrArg Nat.succ (proofFirst k)
end
theorem proofObserved : proofFirst 5 = Eq.refl 5 := rfl

inductive ParityProof : Prop where
  | done
  | next (children : Nat → ParityProof)
mutual
def predicateFirst (tree : ParityProof) : True :=
  match tree with
  | ParityProof.done => True.intro
  | ParityProof.next children => predicateSecond (children 2)
def predicateSecond (tree : ParityProof) : True :=
  match tree with
  | ParityProof.done => True.intro
  | ParityProof.next children => predicateFirst (children 3)
end
theorem predicateObserved : predicateFirst ParityProof.done = True.intro := rfl

-- The selected Standard recursors have native public source telescopes.
-- Keep these primitive calls as independent kernel controls; executable host
-- observations use separately checked structural oracles, as above.
noncomputable def recursorNat (n : Nat) : Nat :=
  Nat.rec (succ := fun (k : Nat) (ih : Nat) => ih + k + 2)
    (motive := fun (_ : Nat) => Nat) 3 n

noncomputable def recursorExcept (value : Except Nat Nat) : Nat :=
  Except.rec (ok := fun (n : Nat) => n + 20)
    (motive := fun (_ : Except Nat Nat) => Nat)
    (fun (n : Nat) => n + 10) value

theorem recursorEmpty (value : Empty) : value = value :=
  Empty.rec (fun (t : Empty) => t = t) value

theorem recursorFalse (h : False) : h = h :=
  False.rec (fun (t : False) => t = t) h

def recursorNatExec (n : Nat) : Nat :=
  match n with
  | 0 => 3
  | Nat.succ k => recursorNatExec k + k + 2

def recursorExceptExec (value : Except Nat Nat) : Nat :=
  match value with
  | Except.error n => n + 10
  | Except.ok n => n + 20

theorem recursorNat_agrees (n : Nat) : recursorNat n = recursorNatExec n := by
  induction n with
  | zero => rfl
  | succ k ih => exact congrArg (fun (value : Nat) => value + k + 2) ih

theorem recursorExcept_agrees (value : Except Nat Nat) :
    recursorExcept value = recursorExceptExec value := by
  cases value <;> rfl

def m3recursors (flag : Bool) : UInt64 :=
  let n := if flag then 4 else 3
  let error : Except Nat Nat := Except.error n
  let ok : Except Nat Nat := Except.ok (n + 1)
  UInt64.ofNat (recursorNatExec n +
    100 * recursorExceptExec error + 10000 * recursorExceptExec ok)

example : m3recursors true = 251417 := rfl
example : m3recursors false = 241312 := rfl

def matchDefault (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=
  match a with
  | true => h1 (Eq.refl true)
  | false => h2 (Eq.refl false)

def matchTrue (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=
  match (generalizing := true) a with
  | true => h1 (Eq.refl true)
  | false => h2 (Eq.refl false)

def matchFalse (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=
  match (generalizing := false) h : a with
  | true => h1 h
  | false => h2 h

def matchLets (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=
  let first : a = true → Nat := h1
  let second : a = false → Nat := h2
  match h : a with
  | true => first h
  | false => second h

def matchComputed (a : Bool) (h1 : Bool.not a = true → Nat)
    (h2 : Bool.not a = false → Nat) : Nat :=
  match h : Bool.not a with
  | true => h1 h
  | false => h2 h

def matchMixed (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=
  match a, Bool.not a with
  | true, false => h1 (Eq.refl true)
  | false, true => h2 (Eq.refl false)
  | _, _ => 0

def matchOriginalValue (a b : Bool) (h : a = b) : Nat := if b then 13 else 17

def matchOriginal (a : Bool) : Nat :=
  match h : a with
  | true => matchOriginalValue a true h
  | false => matchOriginalValue a false h

theorem matchDependentTarget (a : Bool) (h : a = a) : h = h :=
  match a with
  | true => Eq.refl h
  | false => Eq.refl h

def m3matches (flag : Bool) : UInt64 :=
  let first : flag = true → Nat := fun (_ : flag = true) => 3
  let second : flag = false → Nat := fun (_ : flag = false) => 5
  let computedFirst : Bool.not flag = true → Nat := fun (_ : Bool.not flag = true) => 7
  let computedSecond : Bool.not flag = false → Nat := fun (_ : Bool.not flag = false) => 11
  UInt64.ofNat (matchDefault flag first second +
    10 * matchTrue flag first second +
    100 * matchFalse flag first second +
    1000 * matchLets flag first second +
    10000 * matchComputed flag computedFirst computedSecond +
    100000 * matchMixed flag first second +
    1000000 * matchOriginal flag)

example : m3matches true = 13413333 := rfl
example : m3matches false = 17575555 := rfl

class MatchPolicyWitness (a : Bool) where
  mark : Nat

def matchInstanceOriginal (a : Bool) (w : MatchPolicyWitness a)
    (b : Bool) (h : a = b) : True := True.intro

theorem matchInstance (a : Bool) [w : MatchPolicyWitness a] : True :=
  match h : a with
  | true => matchInstanceOriginal a w true h
  | false => matchInstanceOriginal a w false h

def matchAux (n : Nat) : Nat :=
  match h : n with
  | 0 => 0
  | Nat.succ k => Nat.succ (matchAux k)
termination_by n
decreasing_by
  have original : Nat.lt k n :=
    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)
  exact Nat.lt_succ_self k

def matchAuxFalse (n : Nat) : Nat :=
  match (generalizing := false) h : n with
  | 0 => 0
  | Nat.succ k => Nat.succ (matchAuxFalse k)
termination_by n
decreasing_by
  have original : Nat.lt k n :=
    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)
  exact Nat.lt_succ_self k

def matchAuxPrev (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | Nat.succ k => k

example (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match (generalizing := false) a with
      | true => h1 (Eq.refl true)
      | false => h2 (Eq.refl false)
  exact True.intro

example (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match h : a with
      | true => h1 h
      | false => h2 h
  exact True.intro

example (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match (generalizing := true) h : a with
      | true => h1 h
      | false => h2 h
  exact True.intro

example (a : Bool) (h1 : Bool.not a = true → Nat) (h2 : Bool.not a = false → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match Bool.not a with
      | true => h1 (Eq.refl true)
      | false => h2 (Eq.refl false)
  exact True.intro

example (a : Bool) (h : a = a) : True := by
  fail_if_success
    have rejected : h = h :=
      match (generalizing := false) a with
      | true => Eq.refl h
      | false => Eq.refl h
  exact True.intro

example (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match (generalizing := false) a, Bool.not a with
      | true, false => h1 (Eq.refl true)
      | false, true => h2 (Eq.refl false)
      | _, _ => 0
  exact True.intro

def matchSwap (a b : Nat) : Nat :=
  match a, b with
  | b, a => 10 * a + b

theorem matchSwapObserved : matchSwap 2 7 = 72 := Eq.refl 72

def matchNamedOriginalB (b : Bool) : Nat :=
  match hb : b with
  | true => (fun (_ : b = true) => 37) hb
  | false => (fun (_ : b = false) => 41) hb

theorem matchNamedOriginalBTrue : matchNamedOriginalB true = 37 := Eq.refl 37
theorem matchNamedOriginalBFalse : matchNamedOriginalB false = 41 := Eq.refl 41

def matchEqRight {left right : Nat} (_ : left = right) : Nat := right

def matchEquationShadow (n : Nat) : Nat :=
  match h : n with
  | 0 => matchEqRight h
  | Nat.succ h => matchEqRight h

theorem matchEquationShadowZero : matchEquationShadow 0 = 0 := Eq.refl 0
theorem matchEquationShadowSucc : matchEquationShadow 4 = 4 := Eq.refl 4

def matchNestedBindings (a : Bool) (handle : a = a → Nat) : Nat :=
  match (generalizing := true) a with
  | x =>
    match x with
    | true => handle (Eq.refl true)
    | false => handle (Eq.refl false)

theorem matchNestedBindingsTrue :
    matchNestedBindings true (fun (_ : true = true) => 31) = 31 := Eq.refl 31
theorem matchNestedBindingsFalse :
    matchNestedBindings false (fun (_ : false = false) => 43) = 43 := Eq.refl 43

example (a : Bool) (handle : a = a → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match a with
      | x =>
        match x with
        | true => handle (Eq.refl true)
        | false => handle (Eq.refl false)
  exact True.intro

inductive MatchIndexed : Bool → Type where
  | yes (value : Nat) : MatchIndexed true
  | no (value : Nat) : MatchIndexed false

def matchIndexMake (a : Bool) : MatchIndexed a :=
  match a with
  | true => MatchIndexed.yes 53
  | false => MatchIndexed.no 59

def matchIndexBoolEqMark (a b : Bool) (_ : a = b) : Nat := 0

def matchIndexEqMark (a : Bool) (original current : MatchIndexed a)
    (_ : original = current) : Nat := 0

def matchIndexHEqMark (a : Bool) (original : MatchIndexed a)
    (b : Bool) (current : MatchIndexed b) (_ : HEq original current) : Nat := 0

def matchComputedLaterFalse (a : Bool) : Nat :=
  match (generalizing := false) ha : a, hv : matchIndexMake a with
  | true, MatchIndexed.yes n =>
    n + matchIndexBoolEqMark a true ha +
      matchIndexHEqMark a (matchIndexMake a) true (MatchIndexed.yes n) hv
  | false, MatchIndexed.no n =>
    n + matchIndexBoolEqMark a false ha +
      matchIndexHEqMark a (matchIndexMake a) false (MatchIndexed.no n) hv

theorem matchComputedLaterFalseTrue : matchComputedLaterFalse true = 53 := Eq.refl 53
theorem matchComputedLaterFalseFalse : matchComputedLaterFalse false = 59 := Eq.refl 59

def matchIndexedNamed (a : Bool) (value : MatchIndexed a) : Nat :=
  match (generalizing := false) h : value with
  | MatchIndexed.yes n =>
    n + matchIndexHEqMark a value true (MatchIndexed.yes n) h
  | MatchIndexed.no n =>
    n + matchIndexHEqMark a value false (MatchIndexed.no n) h

theorem matchIndexedNamedTrue :
    matchIndexedNamed true (MatchIndexed.yes 61) = 61 := Eq.refl 61
theorem matchIndexedNamedFalse :
    matchIndexedNamed false (MatchIndexed.no 67) = 67 := Eq.refl 67

def matchIndexedNamedEq (value : MatchIndexed true) : Nat :=
  match h : value with
  | MatchIndexed.yes n => n + matchIndexEqMark true value (MatchIndexed.yes n) h

theorem matchIndexedNamedEqObserved :
    matchIndexedNamedEq (MatchIndexed.yes 71) = 71 := Eq.refl 71

def matchNestedIndexed (a : Bool) (value : MatchIndexed a)
    (handle : value = value → Nat) : Nat :=
  match a with
  | true =>
    match value with
    | MatchIndexed.yes n => handle (Eq.refl (MatchIndexed.yes n))
  | false =>
    match value with
    | MatchIndexed.no n => handle (Eq.refl (MatchIndexed.no n))

theorem matchNestedIndexedTrue :
    matchNestedIndexed true (MatchIndexed.yes 2)
      (fun (_ : MatchIndexed.yes 2 = MatchIndexed.yes 2) => 73) = 73 := Eq.refl 73
theorem matchNestedIndexedFalse :
    matchNestedIndexed false (MatchIndexed.no 3)
      (fun (_ : MatchIndexed.no 3 = MatchIndexed.no 3) => 79) = 79 := Eq.refl 79

inductive MatchRowPack where
  | pack (index : Bool) (value : MatchIndexed index)

def matchRowDependent (packed : MatchRowPack) : Nat :=
  match packed with
  | MatchRowPack.pack _ value =>
    let same : value = value := Eq.refl value
    83

def matchRowNested (packed : Option MatchRowPack) : Nat :=
  match packed with
  | Option.none => 0
  | Option.some (MatchRowPack.pack _ value) =>
    let same : value = value := Eq.refl value
    89

theorem matchRowDependentObserved :
    matchRowDependent (MatchRowPack.pack true (MatchIndexed.yes 2)) = 83 := Eq.refl 83
theorem matchRowNestedObserved :
    matchRowNested (Option.some (MatchRowPack.pack false (MatchIndexed.no 3))) = 89 := Eq.refl 89

example (b : Bool) : True := by
  fail_if_success
    have rejected : Nat :=
      match b with
      | true => (fun (_ : b = true) => 37) (Eq.refl true)
      | false => 41
  exact True.intro

example (n : Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match h : n with
      | 0 => 0
      | Nat.succ h => Nat.succ h
  exact True.intro

example (a : Bool) (handle : a = a → Nat) : True := by
  fail_if_success
    have rejected : Nat :=
      match a with
      | x =>
        match (generalizing := false) x with
        | true => handle (Eq.refl true)
        | false => handle (Eq.refl false)
  exact True.intro

example (b : Bool) : True := by
  fail_if_success
    have rejected : Nat :=
      match b with
      | true => 0
      | x =>
        let h : x = false := Eq.refl false
        1
  exact True.intro

def namedCount (n : Nat) : Nat :=
  match h : n with
  | 0 => let witness : n = 0 := h; 0
  | Nat.succ k => let witness : n = Nat.succ k := h; Nat.succ (namedCount k)
def namedResult (n : Nat) : Nat → Nat :=
  fun (bias : Nat) => match (generalizing := false) h : n with
    | 0 => bias
    | Nat.succ k => namedResult k (Nat.succ bias)
def namedRows (A : Type) (rows : List (List A)) : Nat :=
  match h : rows with
  | .nil => 0
  | .cons row rest => Nat.succ (namedRows A rest)
def namedComputed (F : Nat → Type) (i : Nat) (values : List (F i)) : Nat :=
  match (generalizing := true) h : values with
  | .nil => 0
  | .cons value rest => Nat.succ (namedComputed F i rest)
inductive NamedNest (A : Type) where
  | leaf (value : A)
  | direct (child : NamedNest A)
  | many (children : List (NamedNest A))
  | deep (children : List (List (NamedNest A)))
mutual
def namedTree (A : Type) (tree : NamedNest A) : Nat :=
  match h : tree with
  | .leaf value => 1
  | .direct child => Nat.succ (namedTree A child)
  | .many children => Nat.succ (namedForest A children)
  | .deep children => Nat.succ (namedDeep A children)
def namedForest (A : Type) (children : List (NamedNest A)) : Nat :=
  match h : children with
  | .nil => 0
  | .cons child rest => namedTree A child + namedForest A rest
def namedDeep (A : Type) (children : List (List (NamedNest A))) : Nat :=
  match h : children with
  | .nil => 0
  | .cons row rest => namedForest A row + namedDeep A rest
end
def m3structural (flag : Bool) : UInt64 :=
  let amount := if flag then 3 else 5
  let rows := List.cons (List.cons amount List.nil) (List.cons List.nil List.nil)
  let leaf := NamedNest.leaf amount
  let trees := List.cons leaf (List.cons (NamedNest.direct leaf) List.nil)
  let tree := if flag then
    NamedNest.deep (List.cons trees (List.cons (List.cons (NamedNest.direct leaf) List.nil) List.nil))
    else NamedNest.many (List.cons (NamedNest.deep (List.cons trees List.nil)) (List.cons (NamedNest.direct leaf) List.nil))
  UInt64.ofNat (namedCount amount + 10 * namedResult amount 4 +
    100 * namedRows Nat rows +
    1000 * namedComputed (fun (_ : Nat) => Nat) amount (List.cons amount List.nil) +
    10000 * namedTree Nat tree)
theorem namedResultObserved : namedResult 3 5 = 8 := by rfl
theorem namedResultSource (n : Nat) :
    namedResult n = (fun (bias : Nat) => match (generalizing := false) h : n with
      | 0 => bias
      | Nat.succ k => namedResult k (Nat.succ bias)) :=
  by
    funext bias
    exact namedResult.eq_def n bias

def constCount : Nat → Nat := fun n =>
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (constCount k)

theorem constCountObserved : constCount 3 = 3 := Eq.refl 3

theorem constCountSourceEquation :
    constCount = (fun n => match n with
      | 0 => 0
      | Nat.succ k => Nat.succ (constCount k)) := by
  funext n
  cases n <;> rfl

def ConstCountType : Type := Nat → Nat

def constAliasCount : ConstCountType := fun n =>
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (constAliasCount k)

theorem constAliasCountObserved : constAliasCount 3 = 3 := Eq.refl 3

theorem constAliasCountSourceEquation :
    constAliasCount = (fun n => match n with
      | 0 => 0
      | Nat.succ k => Nat.succ (constAliasCount k)) := by
  funext n
  cases n <;> rfl

def m3const (flag : Bool) : UInt64 :=
  let n := if flag then 3 else 5
  UInt64.ofNat (constCount n + 10 * constAliasCount (Nat.succ n))

example : m3const true = 43 := rfl
example : m3const false = 65 := rfl

example : m3structural true = 61273 := rfl
example : m3structural false = 71295 := rfl

example (values : List Bool) : True := by
  fail_if_success
    have rejected : Nat :=
      match values with
      | List.cons true _ => 0
      | List.cons x _ =>
        let h : x = false := Eq.refl false
        1
      | List.nil => 0
  exact True.intro

inductive InlineTree where
  | node (children : List InlineTree)
def inlinePlain (tree : InlineTree) : Bool :=
  match tree with
  | .node [] => true
  | .node [t] => inlinePlain t
  | .node _ => false
def inlineNamed (tree : InlineTree) : Bool :=
  match h : tree with
  | .node [] => let witness : tree = InlineTree.node [] := h; true
  | .node [t] => let witness : tree = InlineTree.node [t] := h; inlineNamed t
  | .node _ => false
def inlineDeep (tree : InlineTree) : Nat :=
  match h : tree with
  | .node [.node [t]] => Nat.succ (inlineDeep t)
  | .node _ => 0
def inlineResult (tree : InlineTree) : Nat → Nat :=
  fun (bias : Nat) => match (generalizing := false) h : tree with
    | .node [] => bias
    | .node [t] => inlineResult t (Nat.succ bias)
    | .node _ => bias + 10
mutual
def inlineEven (tree : InlineTree) : Bool :=
  match h : tree with
  | .node [] => true
  | .node [t] => inlineOdd t
  | .node _ => false
def inlineOdd (tree : InlineTree) : Bool :=
  match h : tree with
  | .node [] => false
  | .node [t] => inlineEven t
  | .node _ => false
end
inductive InlineBranch where
  | node (children : Bool → List InlineBranch)
mutual
def inlineBranch (tree : InlineBranch) : Nat :=
  match h : tree with
  | .node children => inlineBranchChildren (children true)
def inlineBranchChildren (trees : List InlineBranch) : Nat :=
  match hc : trees with
  | [] => 0
  | [t] => Nat.succ (inlineBranch t)
  | _ => 0
end
inductive InlineIndexed : Nat → Type where
  | node (children : List (InlineIndexed 0)) : InlineIndexed 0
def inlineIndexed (n : Nat) (tree : InlineIndexed n) : Nat :=
  match h : tree with
  | .node [] => 0
  | .node [t] => Nat.succ (inlineIndexed 0 t)
  | .node _ => 0
def m3inline (flag : Bool) : UInt64 :=
  let leaf := InlineTree.node []
  let link := InlineTree.node [leaf]
  let chain := InlineTree.node [link]
  let wide := InlineTree.node [leaf, leaf]
  let tree := if flag then chain else wide
  let branchEmpty := InlineBranch.node (fun (_ : Bool) => [])
  let branchLink := InlineBranch.node (fun (_ : Bool) => [branchEmpty])
  let branchChain := InlineBranch.node (fun (_ : Bool) => [branchLink])
  let branchInput := if flag then branchLink else branchChain
  let ix0 := InlineIndexed.node []
  let ix1 := InlineIndexed.node [ix0]
  let ix2 := InlineIndexed.node [ix1]
  let indexInput := if flag then ix1 else ix2
  let mutualInput := if flag then chain else link
  UInt64.ofNat (
    (if inlinePlain tree then 1 else 0) +
    10 * (if inlineNamed tree then 1 else 0) +
    100 * inlineResult tree 4 +
    10000 * inlineDeep tree +
    100000 * inlineBranch branchInput +
    1000000 * inlineIndexed 0 indexInput +
    10000000 * (if inlineEven mutualInput then 1 else 0) +
    100000000 * (if inlineOdd mutualInput then 1 else 0))
theorem inlineResultObserved :
    inlineResult (InlineTree.node [InlineTree.node []]) 5 = 6 := by rfl

example : m3inline true = 11110611 := by
  simp [m3inline, inlinePlain, inlineNamed, inlineDeep, inlineResult,
    inlineEven, inlineOdd, inlineBranch, inlineBranchChildren, inlineIndexed]
example : m3inline false = 102201400 := by
  simp [m3inline, inlinePlain, inlineNamed, inlineDeep, inlineResult,
    inlineEven, inlineOdd, inlineBranch, inlineBranchChildren, inlineIndexed]

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
def inlineReconstructedRefusal (tree : InlineTree) : Nat :=
  match h : tree with
  | .node [] => 0
  | .node [child] =>
    inlineReconstructedRefusal child +
      inlineReconstructedRefusal (InlineTree.node [child])
  | .node _ => 0

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
def inlineUnrelatedRefusal (tree spare : InlineTree) : Nat :=
  match h : tree with
  | .node [] => 0
  | .node [child] =>
    inlineUnrelatedRefusal child spare + inlineUnrelatedRefusal spare spare
  | .node _ => 0

opaque registeredOpaque (n : Nat) : Nat :=
  match h : n with
  | 0 => 2
  | Nat.succ k => Nat.succ (registeredOpaque k)
abbrev registeredAbbrev (n : Nat) : Nat :=
  match h : n with
  | 0 => 3
  | Nat.succ k => Nat.succ (registeredAbbrev k)
class RegisteredValue (n : Nat) where
  value : Nat
instance registeredInstance (n : Nat) : RegisteredValue n where
  value := match h : n with
    | 0 => 4
    | Nat.succ k => Nat.succ (@RegisteredValue.value k (registeredInstance k))
class RegisteredDefault (n : Nat) where
  value : Nat
@[default_instance 200]
instance registeredDefault (n : Nat) : RegisteredDefault n where
  value := match h : n with
    | 0 => 5
    | Nat.succ k => Nat.succ (@RegisteredDefault.value k (registeredDefault k))
def m3registered (flag : Bool) : UInt64 :=
  let n := if flag then 3 else 5
  UInt64.ofNat (registeredOpaque n + 10 * registeredAbbrev n +
    100 * (@RegisteredValue.value n (registeredInstance n)) +
    1000 * (@RegisteredDefault.value n (registeredDefault n)))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
opaque refuseRegisteredOpaque (n : Nat) : Nat :=
  match h : n with
  | 0 => 2
  | Nat.succ k => Nat.succ (refuseRegisteredOpaque (Nat.succ k))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
abbrev refuseRegisteredAbbrev (n : Nat) : Nat :=
  match h : n with
  | 0 => 3
  | Nat.succ k => Nat.succ (refuseRegisteredAbbrev (Nat.succ k))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
instance refuseRegisteredInstance (n : Nat) : RegisteredValue n where
  value := match h : n with
    | 0 => 4
    | Nat.succ k => Nat.succ (@RegisteredValue.value (Nat.succ k)
        (refuseRegisteredInstance (Nat.succ k)))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
@[default_instance 200]
instance refuseRegisteredDefault (n : Nat) : RegisteredDefault n where
  value := match h : n with
    | 0 => 5
    | Nat.succ k => Nat.succ (@RegisteredDefault.value (Nat.succ k)
        (refuseRegisteredDefault (Nat.succ k)))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
def inlineFunctionContainerRefusal (tree : InlineBranch) : Nat :=
  match h : tree with
  | .node children =>
    match hc : children true with
    | [] => 0
    | [t] => Nat.succ (inlineFunctionContainerRefusal t)
    | _ => 0

inductive PlainPredicate : Prop where
  | base
  | step (children : Nat → PlainPredicate)
def predicatePlain (proof : PlainPredicate) : True :=
  match proof with
  | .base => True.intro
  | .step children =>
    match children 1 with
    | .base => True.intro
    | .step grandchildren => predicatePlain (grandchildren 1)
theorem predicatePlainObserved :
    predicatePlain (PlainPredicate.step (fun (_ : Nat) =>
      PlainPredicate.step (fun (_ : Nat) => PlainPredicate.base))) = True.intro := by rfl

inductive NamedPredicate : Prop where
  | base
  | step (children : Nat → NamedPredicate)
def predicateNamed (proof : NamedPredicate) : True :=
  match hp : proof with
  | .base => let witness : proof = NamedPredicate.base := hp; True.intro
  | .step children =>
    match hc : children 1 with
    | .base => True.intro
    | .step grandchildren => predicateNamed (grandchildren 1)
theorem predicateNamedObserved :
    predicateNamed (NamedPredicate.step (fun (_ : Nat) =>
      NamedPredicate.step (fun (_ : Nat) => NamedPredicate.base))) = True.intro := by rfl

inductive ProofIndex : Nat → Prop where
  | base : ProofIndex 0
  | step (n : Nat) (child : ProofIndex n) : ProofIndex (Nat.succ n)
def predicateIndex (n : Nat) (proof : ProofIndex n) : n = n :=
  match h : proof with
  | .base => Eq.refl 0
  | .step k child =>
    match hc : child with
    | .base => Eq.refl 1
    | .step j grandchild =>
      congrArg Nat.succ (congrArg Nat.succ (predicateIndex j grandchild))
theorem predicateIndexObserved :
    predicateIndex 2 (ProofIndex.step 1 (ProofIndex.step 0 ProofIndex.base)) = Eq.refl 2 := by rfl

inductive RefusalPredicate : Prop where
  | base
  | step (children : Nat → RefusalPredicate)
inductive RefusalResult : Prop where
  | base
  | combine (left right : RefusalResult)

def acceptedPredicateParent (proof : RefusalPredicate) : RefusalResult :=
  match hp : proof with
  | .base => RefusalResult.base
  | .step children =>
    match hc : children 1 with
    | .base => RefusalResult.base
    | .step grandchildren =>
      RefusalResult.combine (acceptedPredicateParent (grandchildren 1))
        (acceptedPredicateParent (grandchildren 1))

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
def rejectedPredicateParent (proof : RefusalPredicate) : RefusalResult :=
  match hp : proof with
  | .base => RefusalResult.base
  | .step children =>
    match hc : children 1 with
    | .base => RefusalResult.base
    | .step grandchildren =>
      RefusalResult.combine (rejectedPredicateParent (grandchildren 1))
        (rejectedPredicateParent (RefusalPredicate.step children))

def acceptedPredicateSpare (proof spare : RefusalPredicate) : RefusalResult :=
  match hp : proof with
  | .base => RefusalResult.base
  | .step children =>
    match hc : children 1 with
    | .base => RefusalResult.base
    | .step grandchildren =>
      RefusalResult.combine (acceptedPredicateSpare (grandchildren 1) spare)
        (acceptedPredicateSpare (grandchildren 1) spare)

/-- error: fail to show termination for -/
#guard_msgs (error, drop warning, substring := true) in
def rejectedPredicateSpare (proof spare : RefusalPredicate) : RefusalResult :=
  match hp : proof with
  | .base => RefusalResult.base
  | .step children =>
    match hc : children 1 with
    | .base => RefusalResult.base
    | .step grandchildren =>
      RefusalResult.combine (rejectedPredicateSpare (grandchildren 1) spare)
        (rejectedPredicateSpare spare spare)

inductive AuditIndexedDecEq : Nat → Type where
  | intro (n : Nat) : AuditIndexedDecEq n
  deriving DecidableEq
example (n : Nat) : decide (AuditIndexedDecEq.intro n = AuditIndexedDecEq.intro n) = true := rfl

inductive AuditIndexedBEq : Nat → Type where
  | stop : AuditIndexedBEq 0
  | next (n : Nat) (child : AuditIndexedBEq n) : AuditIndexedBEq (Nat.succ n)
  deriving BEq
example : (AuditIndexedBEq.next 0 AuditIndexedBEq.stop ==
    AuditIndexedBEq.next 0 AuditIndexedBEq.stop) = true := rfl

structure WfBoundaryBox (n : Nat) where
  value : Nat

def wfBoundaryMeasure (n : Nat) (p : WfBoundaryBox n) : Nat :=
  WfBoundaryBox.value p

def wfBoundaryPair (n : Nat) (p : WfBoundaryBox n) : Nat :=
  match n, p with
  | 0, _ => 0
  | Nat.succ k, WfBoundaryBox.mk 0 => 0
  | Nat.succ k, WfBoundaryBox.mk (Nat.succ v) =>
    Nat.succ (wfBoundaryPair k (WfBoundaryBox.mk v))
termination_by wfBoundaryMeasure n p
decreasing_by
  exact Nat.lt_succ_self v

def wfBoundaryGeneralized (n : Nat) (p : WfBoundaryBox n) : Nat :=
  match n with
  | 0 => 0
  | Nat.succ k =>
    match p with
    | WfBoundaryBox.mk 0 => 0
    | WfBoundaryBox.mk (Nat.succ v) =>
      Nat.succ (wfBoundaryGeneralized k (WfBoundaryBox.mk v))
termination_by wfBoundaryMeasure n p
decreasing_by
  exact Nat.lt_succ_self v

def wfBoundaryComputed (n : Nat) : Nat :=
  match h : Nat.succ n with
  | 0 => 0
  | Nat.succ 0 => 0
  | Nat.succ (Nat.succ k) => Nat.succ (wfBoundaryComputed k)
termination_by Nat.succ n
decreasing_by
  exact Eq.mpr (congrArg (fun (t : Nat) => Nat.lt (Nat.succ k) t) h)
    (Nat.lt_succ_self (Nat.succ k))

def wfBoundaryUserRecursor (n : Nat) (impossible : n = n → False) : Nat :=
  Nat.rec (motive := fun (_ : Nat) => Nat) 0
    (fun (k : Nat) (ih : Nat) =>
      wfBoundaryUserRecursor k (fun (_ : k = k) => impossible (Eq.refl n))) n
termination_by n
decreasing_by
  have original : Nat.lt k n := False.elim (impossible (Eq.refl n))
  exact original

def wfBoundaryCatchAll (n : Nat) (impossible : n = n → False) : Nat :=
  match n with
  | x => wfBoundaryCatchAll (Nat.succ x)
      (fun (_ : Nat.succ x = Nat.succ x) => impossible (Eq.refl n))
termination_by n
decreasing_by
  have original : Nat.lt (Nat.succ n) n := False.elim (impossible (Eq.refl n))
  exact original

def m3wfboundaries (flag : Bool) : UInt64 :=
  let n : Nat := if flag then 4 else 2
  UInt64.ofNat (wfBoundaryPair n (WfBoundaryBox.mk 5) +
    10 * wfBoundaryGeneralized n (WfBoundaryBox.mk 3) +
    100 * wfBoundaryComputed n)

private def expectNativeWfBoundaryRefusal (command : Lean.Syntax) :
    Lean.Elab.Command.CommandElabM Unit := do
  let saved ← get
  let failed ← try
    modify fun (state : Lean.Elab.Command.State) =>
      { state with messages := Lean.MessageLog.empty, snapshotTasks := #[] }
    let messages ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages command
    pure (messages.toList.any fun message => message.severity == .error)
  finally
    set saved
  unless failed do
    throwError "native WF boundary unexpectedly accepted an unrefined decrease proof"

run_cmd do
  let command ← `(command|
    def wfBoundaryComputedRefusal (n : Nat) : Nat :=
      match h : Nat.succ n with
      | 0 => 0
      | Nat.succ 0 => 0
      | Nat.succ (Nat.succ k) => Nat.succ (wfBoundaryComputedRefusal k)
    termination_by Nat.succ n
    decreasing_by
      exact Nat.lt_succ_self (Nat.succ k))
  expectNativeWfBoundaryRefusal command

run_cmd do
  let command ← `(command|
    def wfBoundaryUserRecursorRefusal (n : Nat) : Nat :=
      Nat.rec (motive := fun (_ : Nat) => Nat) 0
        (fun (k : Nat) (ih : Nat) => wfBoundaryUserRecursorRefusal k) n
    termination_by n
    decreasing_by
      exact Nat.lt_succ_self k)
  expectNativeWfBoundaryRefusal command

run_cmd do
  let command ← `(command|
    def matchAuxCatchAll (n : Nat) : Nat :=
      match n with
      | 0 => 0
      | x => Nat.succ (matchAuxCatchAll (matchAuxPrev x))
    termination_by n
    decreasing_by
      exact Nat.lt_succ_self _)
  expectNativeWfBoundaryRefusal command

run_cmd do
  let command ← `(command|
    def wfBoundaryUserRecursorCleanupRefusal (n : Nat) (impossible : False) : Nat :=
      Nat.rec (motive := fun (_ : Nat) => Nat) 0
        (fun (k : Nat) (ih : Nat) => wfBoundaryUserRecursorCleanupRefusal k impossible) n
    termination_by n
    decreasing_by
      have original : Nat.lt k n := False.elim impossible
      exact original)
  expectNativeWfBoundaryRefusal command

run_cmd do
  let command ← `(command|
    def wfBoundaryCatchAllFixedRefusal (n : Nat) (impossible : False) : Nat :=
      match n with
      | x => wfBoundaryCatchAllFixedRefusal x impossible
    termination_by n
    decreasing_by
      have original : Nat.lt n n := False.elim impossible
      exact original)
  expectNativeWfBoundaryRefusal command


inductive OpaquePredicate : Prop where
  | base
  | step (children : Nat → OpaquePredicate)
opaque registeredProofOpaque (proof : OpaquePredicate) : True :=
  match hp : proof with
  | .base => True.intro
  | .step children =>
    match hc : children 1 with
    | .base => True.intro
    | .step grandchildren => registeredProofOpaque (grandchildren 1)

inductive AbbrevPredicate : Prop where
  | base
  | step (children : Nat → AbbrevPredicate)
abbrev registeredProofAbbrev (proof : AbbrevPredicate) : True :=
  match hp : proof with
  | .base => True.intro
  | .step children =>
    match hc : children 1 with
    | .base => True.intro
    | .step grandchildren => registeredProofAbbrev (grandchildren 1)

inductive InstancePredicate : Prop where
  | base
  | step (children : Nat → InstancePredicate)
class PredicateWitness (proof : InstancePredicate) : Prop where
  value : True
instance registeredProofInstance (proof : InstancePredicate) : PredicateWitness proof where
  value := match hp : proof with
    | .base => True.intro
    | .step children =>
      match hc : children 1 with
      | .base => True.intro
      | .step grandchildren =>
        @PredicateWitness.value (grandchildren 1)
          (registeredProofInstance (grandchildren 1))
theorem registeredProofUse (proof : InstancePredicate) : PredicateWitness proof := inferInstance

inductive DefaultPredicate : Prop where
  | base
  | step (children : Nat → DefaultPredicate)
class DefaultPredicateWitness (proof : DefaultPredicate) : Prop where
  value : True
@[default_instance 200]
instance registeredProofDefault (proof : DefaultPredicate) : DefaultPredicateWitness proof where
  value := match hp : proof with
    | .base => True.intro
    | .step children =>
      match hc : children 1 with
      | .base => True.intro
      | .step grandchildren =>
        @DefaultPredicateWitness.value (grandchildren 1)
          (registeredProofDefault (grandchildren 1))
theorem registeredProofDefaultUse (proof : DefaultPredicate) : DefaultPredicateWitness proof := inferInstance

class UnindexedRegistration where
  value : Nat

/-- error: This instance has 1 argument that cannot be inferred using typeclass synthesis. -/
#guard_msgs (error, drop warning, substring := true) in
instance impossibleRegistration (n : Nat) : UnindexedRegistration where
  value := n

/-- error: This instance has 1 argument that cannot be inferred using typeclass synthesis. -/
#guard_msgs (error, drop warning, substring := true) in
@[default_instance 200]
instance impossibleDefaultRegistration (n : Nat) : UnindexedRegistration where
  value := n

run_cmd do
  let environment ← Lean.getEnv
  match environment.find? ``registeredProofOpaque with
  | some (.opaqueInfo _) => pure ()
  | _ => throwError "registered predicate opaque changed its native kind"
  match environment.find? ``registeredProofAbbrev with
  | some (.defnInfo _) => pure ()
  | _ => throwError "registered predicate abbrev changed its native kind"
  unless (Lean.getReducibilityStatusCore environment ``registeredProofAbbrev) == .reducible do
    throwError "registered predicate abbrev lost native reducibility"
  for name in [``registeredProofInstance, ``registeredProofDefault] do
    match environment.find? name with
    | some (.thmInfo _) => pure ()
    | _ => throwError "registered proof instance changed its native kind: {name}"
    let some entry := (Lean.Meta.instanceExtension.getState environment).instanceNames.find? name
      | throwError "registered proof instance lost ordinary registration: {name}"
    unless entry.priority == 1000 do
      throwError "registered proof instance changed ordinary priority: {name}"
  let ordinaryDefaults ← Lean.Meta.getDefaultInstances ``PredicateWitness
  unless !(ordinaryDefaults.any (fun entry => entry.1 == ``registeredProofInstance)) do
    throwError "ordinary proof instance acquired a native default registration"
  let defaults ← Lean.Meta.getDefaultInstances ``DefaultPredicateWitness
  unless defaults.filter (fun entry => entry.1 == ``registeredProofDefault) ==
      [(``registeredProofDefault, 200)] do
    throwError "registered proof default-instance metadata changed"

universe indexedU

inductive IndexedPayload (A : Type indexedU) : Nat → Type indexedU where
  | left (index : Nat) (value : A) : IndexedPayload A index
  | right (index : Nat) (value : A) : IndexedPayload A index
  | next (index : Nat) (value : A) (child : IndexedPayload A index) :
      IndexedPayload A (Nat.succ index)
  deriving BEq, DecidableEq

def indexedOriginal : IndexedPayload Bool 1 :=
  IndexedPayload.next 0 true (IndexedPayload.left 0 false)
def indexedFieldChanged : IndexedPayload Bool 1 :=
  IndexedPayload.next 0 false (IndexedPayload.left 0 false)
def indexedChildChanged : IndexedPayload Bool 1 :=
  IndexedPayload.next 0 true (IndexedPayload.left 0 true)
def indexedCtorChanged : IndexedPayload Bool 1 :=
  IndexedPayload.next 0 true (IndexedPayload.right 0 false)
def indexedMajorChanged : IndexedPayload Bool 1 := IndexedPayload.right 1 true

theorem indexedBEqSame : (indexedOriginal == indexedOriginal) = true := by rfl
theorem indexedBEqField : (indexedOriginal == indexedFieldChanged) = false := by rfl
theorem indexedBEqChild : (indexedOriginal == indexedChildChanged) = false := by rfl
theorem indexedBEqCtor : (indexedOriginal == indexedCtorChanged) = false := by rfl
theorem indexedBEqMajor : (indexedOriginal == indexedMajorChanged) = false := by rfl
theorem indexedDecEqSame :
    Decidable.decide (self := decEq indexedOriginal indexedOriginal) = true := by rfl
theorem indexedDecEqField :
    Decidable.decide (self := decEq indexedOriginal indexedFieldChanged) = false := by rfl
theorem indexedDecEqChild :
    Decidable.decide (self := decEq indexedOriginal indexedChildChanged) = false := by rfl
theorem indexedDecEqCtor :
    Decidable.decide (self := decEq indexedOriginal indexedCtorChanged) = false := by rfl
theorem indexedDecEqMajor :
    Decidable.decide (self := decEq indexedOriginal indexedMajorChanged) = false := by rfl

inductive IndexedAtom where
  | atom (value : Bool)
instance indexedAtomBEq : BEq IndexedAtom where
  beq (_left : IndexedAtom) (_right : IndexedAtom) : Bool := false
theorem indexedBEqUsesActualDictionary :
    (IndexedPayload.left 0 (IndexedAtom.atom true) ==
      IndexedPayload.left 0 (IndexedAtom.atom true)) = false := by rfl

inductive IndexedErasedDependency : Nat → Type where
  | intro (value : Nat) :
      IndexedErasedDependency ((fun (_ : Nat) => 0) value)
  deriving BEq, DecidableEq
theorem indexedBetaFieldBEq :
    (IndexedErasedDependency.intro 1 == IndexedErasedDependency.intro 2) = false := by rfl
theorem indexedBetaFieldDecEq :
    Decidable.decide (self := decEq (IndexedErasedDependency.intro 1)
      (IndexedErasedDependency.intro 2)) = false := by rfl

inductive IndexedDependent : Nat → Type where
  | wrap (index : Nat) (child : IndexedPayload Bool index) : IndexedDependent 0
  deriving DecidableEq
theorem indexedDependentSame :
    Decidable.decide (self := decEq (IndexedDependent.wrap 1 indexedOriginal)
      (IndexedDependent.wrap 1 indexedOriginal)) = true := by rfl
theorem indexedDependentChild :
    Decidable.decide (self := decEq (IndexedDependent.wrap 1 indexedOriginal)
      (IndexedDependent.wrap 1 indexedChildChanged)) = false := by rfl
theorem indexedDependentIndex :
    Decidable.decide (self := decEq
      (IndexedDependent.wrap 0 (IndexedPayload.left 0 true))
      (IndexedDependent.wrap 1 indexedOriginal)) = false := by rfl

run_cmd do
  let environment ← Lean.getEnv
  for (name, parameters, indices) in [
      (``M3InputParityOracle.IndexedPayload, 1, 1),
      (``M3InputParityOracle.IndexedErasedDependency, 0, 1),
      (``M3InputParityOracle.IndexedDependent, 0, 1)] do
    let some (.inductInfo info) := environment.find? name
      | throwError "indexed deriving witness is not an inductive: {name}"
    unless info.numParams == parameters && info.numIndices == indices do
      throwError "indexed deriving witness changed its parameter/index telescope: {name}"

/-- error: failed to synthesize -/
#guard_msgs (error, drop warning, substring := true) in
inductive IndexedMissingBEq : Nat → Type where
  | intro (index : Nat) (value : Nat → Nat) : IndexedMissingBEq index
  deriving BEq

/-- error: failed to synthesize -/
#guard_msgs (error, drop warning, substring := true) in
inductive IndexedMissingDecEq : Nat → Type where
  | intro (index : Nat) (value : Nat → Nat) : IndexedMissingDecEq index
  deriving DecidableEq

def wfConstReturned (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k => Nat.succ (wfConstReturned k (Nat.succ bias))
termination_by n
decreasing_by exact Nat.lt_succ_self k

def wfConstClosed : (n : Nat) → (proof : n = n → False) → Nat :=
  fun (n : Nat) (proof : n = n → False) =>
    wfConstClosed (Nat.succ n)
      (fun (_ : Nat.succ n = Nat.succ n) => proof (Eq.refl n))
termination_by 0
decreasing_by
  have original : Nat.lt 0 0 := False.elim (proof (Eq.refl n))
  exact original

theorem wfConstReturnedSource (n : Nat) :
    wfConstReturned n = (fun (bias : Nat) => match h : n with
      | 0 => bias
      | Nat.succ k => Nat.succ (wfConstReturned k (Nat.succ bias))) :=
  by
    funext bias
    exact wfConstReturned.eq_def n bias

theorem wfConstClosedSource :
    wfConstClosed = (fun (n : Nat) (proof : n = n → False) =>
      wfConstClosed (Nat.succ n)
        (fun (_ : Nat.succ n = Nat.succ n) => proof (Eq.refl n))) :=
  by
    funext n proof
    exact wfConstClosed.eq_def n proof

def wfConstRetained (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k =>
      let step := wfConstRetained k
      Nat.succ (step (Nat.succ bias))
termination_by n
decreasing_by exact Nat.lt_succ_self k

mutual
def wfConstMutualLeft (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k => Nat.succ (wfConstMutualRight k (Nat.succ bias))
termination_by n
decreasing_by exact Nat.lt_succ_self k

def wfConstMutualRight (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k =>
      let step := wfConstMutualLeft k
      Nat.succ (step (Nat.succ bias))
termination_by n
decreasing_by exact Nat.lt_succ_self k
end

theorem wfConstMutualSource (n : Nat) :
    wfConstMutualLeft n = (fun (bias : Nat) => match h : n with
      | 0 => bias
      | Nat.succ k => Nat.succ (wfConstMutualRight k (Nat.succ bias))) :=
  by
    funext bias
    exact wfConstMutualLeft.eq_def n bias

mutual
def wfConstFixedLeft (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k => Nat.succ (wfConstFixedRight k bias)
termination_by n
decreasing_by exact Nat.lt_succ_self k

def wfConstFixedRight (n : Nat) : Nat → Nat :=
  fun (bias : Nat) =>
    match h : n with
    | 0 => bias
    | Nat.succ k => Nat.succ (wfConstFixedLeft k bias)
termination_by n
decreasing_by exact Nat.lt_succ_self k
end

def m3constwf (flag : Bool) : UInt64 :=
  let n := if flag then 4 else 2
  let direct := wfConstReturned n 3
  let retained := wfConstRetained n 3
  let mutualResult := wfConstMutualLeft n 3
  let fixedResult := wfConstFixedLeft (n + n) 3
  UInt64.ofNat (if direct == retained && direct == mutualResult && direct == fixedResult
    then direct else 0)

run_cmd do
  let command ← `(command|
    def wfConstUnbound : Nat → Nat :=
      fun (n : Nat) => wfConstUnbound (Nat.succ n)
    termination_by n)
  expectNativeWfBoundaryRefusal command

run_cmd do
  let command ← `(command|
    def wfConstConstantBad : Nat → Nat :=
      fun (n : Nat) => wfConstConstantBad (Nat.succ n)
    termination_by 0
    decreasing_by exact Nat.lt_succ_self 0)
  expectNativeWfBoundaryRefusal command

def layoutCombine (left right : Nat) : Nat := Nat.add left right
def layoutAccept (value : Nat) : Nat := value

def layoutNamed : Nat := layoutAccept (value := layoutCombine 1
2)
def layoutParen : Nat := (layoutCombine 4
5)
def layoutAscribed : Nat := (layoutCombine 6
7 : Nat)
def layoutTuple : Nat × Nat := (layoutCombine 6
7, layoutCombine 8
9)
def layoutNested : Nat := layoutAccept (value := layoutAccept (value := layoutCombine 10
11))
def layoutLambda : Nat := ((fun (n : Nat) => layoutCombine n
12) 13)
def layoutLet : Nat := (let saved := layoutCombine 1 2
saved)
def layoutDo : Option Nat := (do
  let saved := layoutCombine 1 2
  return saved)

theorem layoutNamedObserved : layoutNamed = 3 := by rfl
theorem layoutParenObserved : layoutParen = 9 := by rfl
theorem layoutAscribedObserved : layoutAscribed = 13 := by rfl
theorem layoutTupleObserved : layoutTuple = (13, 17) := by rfl
theorem layoutNestedObserved : layoutNested = 21 := by rfl
theorem layoutLambdaObserved : layoutLambda = 25 := by rfl
theorem layoutLetObserved : layoutLet = 3 := by rfl
theorem layoutDoObserved : layoutDo = Option.some 3 := by rfl

def parserLayoutRefusals : List (String × String) := [
  ("unparenthesized indentation", "def layoutUnparenthesized : Nat :=\n  Nat.add 1\n2\n"),
  ("parenthesized whitespace", "def layoutAdjacent : Nat := (Nat.succ(3))\n"),
  ("named-value whitespace", "def layoutNamedAdjacent : Nat := Nat.succ (n := Nat.succ(3))\n"),
  ("parenthesis restores position", "def layoutParenEscaped : Nat :=\n  Nat.add (Nat.add 1\n0)\n2\n"),
  ("named value restores position", "def layoutNamedEscaped : Nat :=\n  Nat.add (n := Nat.add 1\n0)\n2\n"),
  ("missing closing delimiter", "def layoutMissingClose : Nat := (Nat.add 1\n2\n")]

run_cmd do
  let environment ← Lean.getEnv
  for (label, source) in parserLayoutRefusals do
    let inputContext := Lean.Parser.mkInputContext source "<native-layout-refusal>"
    let parser := Lean.Parser.andthenFn Lean.Parser.whitespace
      Lean.Parser.topLevelCommandParserFn
    let state := parser.run inputContext { env := environment, options := {} }
      (Lean.Parser.getTokenTable environment) (Lean.Parser.mkParserState source)
    if state.allErrors.isEmpty && inputContext.atEnd state.pos then
      throwError "native top-level layout parser accepted {label}"

end M3InputParityOracle

namespace M3InputParity
private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (value : Except String α) : IO α :=
  match value with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def leanSource : String :=
  "namespace Shared\nsection\nvariable (seed : Nat)\n" ++
  "def addSeed (n : Nat) : Nat := Nat.add seed n\nend\n" ++
  "def withDefault (n : Nat := 3) : Nat := Nat.succ n\nend Shared\nopen Shared\n" ++
  "def m3parity (flag : Bool) : UInt64 := UInt64.ofNat (if flag then addSeed 8 5 else withDefault 3)\n"

private def psSource : String :=
  "namespace Shared\nsection\nvariable (seed: Nat)\n" ++
  "function addSeed(n: Nat): Nat := Nat.add(seed, n)\nend\n" ++
  "function withDefault(n: Nat := 3): Nat := Nat.succ(n)\nend Shared\nopen Shared\n" ++
  "function m3parity(flag: Bool): UInt64 := UInt64.ofNat(if (flag) { addSeed(8, 5) } else { withDefault(3) })\n"

private def dataLeanSource : String :=
  "structure ParityBox where\n  value : Nat\n  deriving Inhabited, BEq\ninductive ParityMaybe where\n  | none\n  | some (value : Nat)\n  deriving Inhabited, BEq\nclass Sized (A : Type) where\n  size : A → Nat\n@[default_instance 200]\ninstance (priority := high) sizedNat : Sized Nat where\n  size n := n\ndef m3data (flag : Bool) : UInt64 :=\n  let b := ParityBox.mk (keep (if flag then 6 else 9))\n  let packed := ParityMaybe.some (Sized.size b.value)\n  UInt64.ofNat (match packed with\n    | ParityMaybe.none => 0\n    | ParityMaybe.some value => if b == b then value else 0)\nwhere\n  keep (n : Nat) : Nat :=\n    match n with\n    | 0 => 0\n    | Nat.succ k => Nat.succ (keep k)\n  termination_by n\n  decreasing_by exact Nat.lt_succ_self k\n"

private def dataPsSource : String :=
  "structure ParityBox where {\n  value: Nat\n} deriving Inhabited, BEq\ninductive ParityMaybe where {\n  | none\n  | some(value: Nat)\n} deriving Inhabited, BEq\nclass Sized(A: Type) where {\n  size: A -> Nat\n}\n@[default_instance 200]\ninstance (priority := high) sizedNat: Sized Nat where {\n  size(n: Nat): Nat := n\n}\nfunction m3data(flag: Bool): UInt64 :=\n  let b := ParityBox.mk(keep(if (flag) { 6 } else { 9 }))\n  let packed := ParityMaybe.some(Sized.size(b.value))\n  UInt64.ofNat(match packed with {\n    | ParityMaybe.none => 0\n    | ParityMaybe.some value => if (b == b) { value } else { 0 }\n  })\nwhere {\n  def keep(n: Nat): Nat := match n with {\n    | 0 => 0\n    | Nat.succ k => Nat.succ(keep(k))\n  }\n  termination_by n\n  decreasing_by by { exact Nat.lt_succ_self(k) }\n}\n"

private def controlLeanSource : String :=
  "def m3control (flag : Bool) : UInt64 :=\n  let (left, right) : Nat × Nat := (2, 3)\n  let amount : Option Nat := do\n    let (x, y) : Nat × Nat ← Option.some (left, right)\n    if !flag then\n      if let .some n := Option.some (x + y) then\n        return n\n    else if flag then\n      return 7\n    return 11\n  let extra : Id Nat := do { let n := 1; return n; }\n  let extraValue : Nat := extra\n  let extraApplied : Nat := (fun (f : Nat → Nat) => f extraValue) fun (n : Nat) => n\n  UInt64.ofNat (if let .some n := amount then n + extraApplied else 0)\n"

private def controlPsSource : String :=
  "function m3control(flag: Bool): UInt64 :=\n  let (left, right): Nat × Nat := (2, 3)\n  let amount: Option Nat := do {\n    let (x, y): Nat × Nat ← Option.some((left, right))\n    if (!flag) {\n      if let .some n := Option.some(x + y) {\n        return n\n      }\n    } else {\n      if (flag) {\n        return 7\n      }\n    }\n    return 11\n  }\n  let extra: Id Nat := do {\n    let n := 1\n    return n\n  }\n  let extraValue: Nat := extra\n  let extraApplied: Nat := (fun (f: Nat -> Nat) => f(extraValue))(fun (n: Nat) => n)\n  UInt64.ofNat(if let .some n := amount { n + extraApplied } else { 0 })\n"

private def mutualLeanSource : String :=
  "mutual\ndef parityFirst {A : Type} (a : A) (n : Nat) : Nat → A :=\n  fun (k : Nat) => match n with\n    | 0 => a\n    | Nat.succ m => let kept := a; paritySecond m A kept k\ntermination_by n\ndef paritySecond (n : Nat) (B : Type) (b : B) : Nat → B :=\n  fun (k : Nat) => match n with\n    | 0 => b\n    | Nat.succ m => parityThird m b k\ntermination_by n\ndef parityThird {C : Type} (n : Nat) (c : C) : Nat → C :=\n  fun (k : Nat) => match n with\n    | 0 => c\n    | Nat.succ m => parityFirst (n := m) c k\ntermination_by n\nend\ndef m3mutual (flag : Bool) : UInt64 :=\n  UInt64.ofNat (parityFirst (if flag then 7 else 11) (if flag then 6 else 4) 2)\n"

private def mutualPsSource : String :=
  "mutual\ndef parityFirst {A : Type} (a : A, n : Nat) : Nat -> A := fun (k : Nat) => match n with { | 0 => a | Nat.succ m => let kept := a\nparitySecond(m, A, kept)(k) } termination_by n\ndef paritySecond (n : Nat, B : Type, b : B) : Nat -> B := fun (k : Nat) => match n with { | 0 => b | Nat.succ m => parityThird(m, b)(k) } termination_by n\ndef parityThird {C : Type} (n : Nat, c : C) : Nat -> C := fun (k : Nat) => match n with { | 0 => c | Nat.succ m => parityFirst(c, m)(k) } termination_by n\nend\nfunction m3mutual(flag: Bool): UInt64 := UInt64.ofNat(parityFirst(if (flag) { 7 } else { 11 }, if (flag) { 6 } else { 4 })(2))\n"

private def strategyLeanSource : String :=
  "partial def parityPartial (n : Nat) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (parityPartial k)\ndef parityFixed (seed : Nat) (n : Nat) : Nat :=\n  match n with\n  | 0 => seed\n  | Nat.succ k => parityFixed seed k\npartial_fixpoint\ndef m3strategies (flag : Bool) : UInt64 :=\n  UInt64.ofNat (parityPartial (if flag then 4 else 3) +\n    100 * parityFixed (if flag then 7 else 9) (if flag then 3 else 4))\n"

private def strategyPsSource : String :=
  "partial def parityPartial(n: Nat): Nat := match n with { | 0 => 0 | Nat.succ k => Nat.succ(parityPartial(k)) }\ndef parityFixed(seed: Nat, n: Nat): Nat := match n with { | 0 => seed | Nat.succ k => parityFixed(seed, k) }\npartial_fixpoint\nfunction m3strategies(flag: Bool): UInt64 := UInt64.ofNat(parityPartial(if (flag) { 4 } else { 3 }) + 100 * parityFixed(if (flag) { 7 } else { 9 }, if (flag) { 3 } else { 4 }))\n"

private def fieldsLeanSource : String :=
  "instance parityFunctionHash {A : Type} : Hashable (forall (i : Nat), i = i → A) where\n  hash (_ : forall (i : Nat), i = i → A) := UInt64.ofNat 17\ninductive ParityBranch where\n  | leaf (value : Nat)\n  | node (children : forall (i : Nat), i = i → ParityBranch)\n  deriving Hashable\ndef branchFold (tree : ParityBranch) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => value\n  | ParityBranch.node children => Nat.succ (branchFold (children 2 (Eq.refl 2)))\nmutual\ndef branchFirst (bias : Nat) (tree : ParityBranch) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchSecond (children 3 (Eq.refl 3)) (bias + 1)\ndef branchSecond (tree : ParityBranch) (bias : Nat) : Nat :=\n  match tree with\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchFirst (bias + 2) (children 4 (Eq.refl 4))\nend\ndef branchByRec (tree : ParityBranch) : Nat :=\n  ParityBranch.rec (motive := fun (_ : ParityBranch) => Nat)\n    (fun (value : Nat) => value)\n    (fun (children : forall (i : Nat), i = i → ParityBranch) (ih : forall (i : Nat), i = i → Nat) =>\n      Nat.succ (ih 5 (Eq.refl 5))) tree\ntheorem branchRefl (tree : ParityBranch) : branchFold tree = branchFold tree :=\n  ParityBranch.rec (motive := fun (t : ParityBranch) => branchFold t = branchFold t)\n    (fun (value : Nat) => Eq.refl value)\n    (fun (children : forall (i : Nat), i = i → ParityBranch)\n      (ih : forall (i : Nat) (h : i = i), branchFold (children i h) = branchFold (children i h)) =>\n      congrArg Nat.succ (ih 2 (Eq.refl 2))) tree\ndef m3fields (flag : Bool) : UInt64 :=\n  let seed := if flag then 7 else 11\n  let tree := ParityBranch.node (fun (i : Nat) (h : i = i) =>\n    ParityBranch.node (fun (j : Nat) (g : j = j) => ParityBranch.leaf (seed + i + j)))\n  let mark : Nat := if Hashable.hash tree == mixHash (UInt64.ofNat 1) (UInt64.ofNat 17) then 0 else 1\n  UInt64.ofNat (branchFold tree + 100 * branchFirst 3 tree + 10000 * branchByRec tree + mark)\nmutual\ndef proofFirst (n : Nat) : n = n :=\n  match n with\n  | 0 => Eq.refl 0\n  | Nat.succ k => congrArg Nat.succ (proofSecond k)\ndef proofSecond (n : Nat) : n = n :=\n  match n with\n  | 0 => Eq.refl 0\n  | Nat.succ k => congrArg Nat.succ (proofThird k)\ndef proofThird (n : Nat) : n = n :=\n  match n with\n  | 0 => Eq.refl 0\n  | Nat.succ k => congrArg Nat.succ (proofFirst k)\nend\ntheorem proofObserved : proofFirst 5 = Eq.refl 5 := by rfl\ninductive ParityProof : Prop where\n  | done\n  | next (children : Nat → ParityProof)\nmutual\ndef predicateFirst (tree : ParityProof) : True :=\n  match tree with\n  | ParityProof.done => True.intro\n  | ParityProof.next children => predicateSecond (children 2)\ndef predicateSecond (tree : ParityProof) : True :=\n  match tree with\n  | ParityProof.done => True.intro\n  | ParityProof.next children => predicateFirst (children 3)\nend\ntheorem predicateObserved : predicateFirst ParityProof.done = True.intro := by rfl\n"

private def fieldsPsSource : String :=
  "instance parityFunctionHash {A: Type}: Hashable(forall (i: Nat), i = i -> A) where {\n  hash(value: forall (i: Nat), i = i -> A): UInt64 := UInt64.ofNat(17)\n}\ninductive ParityBranch where {\n  | leaf(value: Nat)\n  | node(children: forall (i: Nat), i = i -> ParityBranch)\n} deriving Hashable\nfunction branchFold(tree: ParityBranch): Nat := match tree with {\n  | ParityBranch.leaf value => value\n  | ParityBranch.node children => Nat.succ(branchFold(children(2, Eq.refl(2))))\n}\nmutual\nfunction branchFirst(bias: Nat, tree: ParityBranch): Nat := match tree with {\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchSecond(children(3, Eq.refl(3)), bias + 1)\n}\nfunction branchSecond(tree: ParityBranch, bias: Nat): Nat := match tree with {\n  | ParityBranch.leaf value => bias + value\n  | ParityBranch.node children => branchFirst(bias + 2, children(4, Eq.refl(4)))\n}\nend\nfunction branchByRec(tree: ParityBranch): Nat :=\n  ParityBranch.rec(fun (value: Nat) => value,\n    fun (children: forall (i: Nat), i = i -> ParityBranch) (ih: forall (i: Nat), i = i -> Nat) =>\n      Nat.succ(ih(5, Eq.refl(5))), tree, motive := fun (_: ParityBranch) => Nat)\ntheorem branchRefl(tree: ParityBranch): branchFold(tree) = branchFold(tree) :=\n  ParityBranch.rec(fun (value: Nat) => Eq.refl(value),\n    fun (children: forall (i: Nat), i = i -> ParityBranch)\n      (ih: forall (i: Nat) (h: i = i), branchFold(children(i, h)) = branchFold(children(i, h))) =>\n      congrArg(Nat.succ, ih(2, Eq.refl(2))), tree, motive := fun (t: ParityBranch) => branchFold(t) = branchFold(t))\nfunction m3fields(flag: Bool): UInt64 :=\n  let seed := if (flag) { 7 } else { 11 }\n  let tree := ParityBranch.node(fun (i: Nat) (h: i = i) =>\n    ParityBranch.node(fun (j: Nat) (g: j = j) => ParityBranch.leaf(seed + i + j)))\n  let mark: Nat := if (Hashable.hash(tree) == mixHash(UInt64.ofNat(1), UInt64.ofNat(17))) { 0 } else { 1 }\n  UInt64.ofNat(branchFold(tree) + 100 * branchFirst(3, tree) + 10000 * branchByRec(tree) + mark)\nmutual\nfunction proofFirst(n: Nat): n = n := match n with {\n  | 0 => Eq.refl(0)\n  | Nat.succ k => congrArg(Nat.succ, proofSecond(k))\n}\nfunction proofSecond(n: Nat): n = n := match n with {\n  | 0 => Eq.refl(0)\n  | Nat.succ k => congrArg(Nat.succ, proofThird(k))\n}\nfunction proofThird(n: Nat): n = n := match n with {\n  | 0 => Eq.refl(0)\n  | Nat.succ k => congrArg(Nat.succ, proofFirst(k))\n}\nend\ntheorem proofObserved: proofFirst(5) = Eq.refl(5) := by { rfl }\ninductive ParityProof: Prop where {\n  | done\n  | next(children: Nat -> ParityProof)\n}\nmutual\nfunction predicateFirst(tree: ParityProof): True := match tree with {\n  | ParityProof.done => True.intro\n  | ParityProof.next children => predicateSecond(children(2))\n}\nfunction predicateSecond(tree: ParityProof): True := match tree with {\n  | ParityProof.done => True.intro\n  | ParityProof.next children => predicateFirst(children(3))\n}\nend\ntheorem predicateObserved: predicateFirst(ParityProof.done) = True.intro := by { rfl }\n"

private def recursorLeanSource : String :=
  "def recursorNat (n : Nat) : Nat :=\n  Nat.rec (succ := fun (k : Nat) (ih : Nat) => ih + k + 2)\n    (motive := fun (_ : Nat) => Nat) 3 n\ndef recursorExcept (value : Except Nat Nat) : Nat :=\n  Except.rec (ok := fun (n : Nat) => n + 20)\n    (motive := fun (_ : Except Nat Nat) => Nat)\n    (fun (n : Nat) => n + 10) value\ntheorem recursorEmpty (value : Empty) : value = value :=\n  Empty.rec (fun (t : Empty) => t = t) value\ntheorem recursorFalse (h : False) : h = h :=\n  False.rec (fun (t : False) => t = t) h\ntheorem recursorNatZero : recursorNat 0 = 3 := by rfl\ntheorem recursorExceptError (n : Nat) : recursorExcept (Except.error n) = n + 10 := by rfl\ntheorem recursorExceptOk (n : Nat) : recursorExcept (Except.ok n) = n + 20 := by rfl\ndef m3recursors (flag : Bool) : UInt64 :=\n  let n := if flag then 4 else 3\n  let error : Except Nat Nat := Except.error n\n  let ok : Except Nat Nat := Except.ok (n + 1)\n  UInt64.ofNat (recursorNat n + 100 * recursorExcept error + 10000 * recursorExcept ok)\n"

private def recursorPsSource : String :=
  "function recursorNat(n: Nat): Nat :=\n  Nat.rec(3, succ := fun (k: Nat) (ih: Nat) => ih + k + 2,\n    t := n, motive := fun (_: Nat) => Nat)\nfunction recursorExcept(value: Except(Nat, Nat)): Nat :=\n  Except.rec(fun (n: Nat) => n + 10, ok := fun (n: Nat) => n + 20,\n    t := value, motive := fun (_: Except(Nat, Nat)) => Nat)\ntheorem recursorEmpty(value: Empty): value = value :=\n  Empty.rec(fun (t: Empty) => t = t, value)\ntheorem recursorFalse(h: False): h = h :=\n  False.rec(fun (t: False) => t = t, h)\ntheorem recursorNatZero: recursorNat(0) = 3 := by { rfl }\ntheorem recursorExceptError(n: Nat): recursorExcept(Except.error(n)) = n + 10 := by { rfl }\ntheorem recursorExceptOk(n: Nat): recursorExcept(Except.ok(n)) = n + 20 := by { rfl }\nfunction m3recursors(flag: Bool): UInt64 :=\n  let n := if (flag) { 4 } else { 3 }\n  let error: Except(Nat, Nat) := Except.error(n)\n  let ok: Except(Nat, Nat) := Except.ok(n + 1)\n  UInt64.ofNat(recursorNat(n) + 100 * recursorExcept(error) + 10000 * recursorExcept(ok))\n"

private def matchLeanSource : String :=
  "def matchDefault (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n\ndef matchTrue (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := true) a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n\ndef matchFalse (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := false) h : a with\n  | true => h1 h\n  | false => h2 h\n\ndef matchLets (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  let first : a = true → Nat := h1\n  let second : a = false → Nat := h2\n  match h : a with\n  | true => first h\n  | false => second h\n\ndef matchComputed (a : Bool) (h1 : Bool.not a = true → Nat)\n    (h2 : Bool.not a = false → Nat) : Nat :=\n  match h : Bool.not a with\n  | true => h1 h\n  | false => h2 h\n\ndef matchMixed (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match a, Bool.not a with\n  | true, false => h1 (Eq.refl true)\n  | false, true => h2 (Eq.refl false)\n  | _, _ => 0\n\ndef matchOriginalValue (a b : Bool) (h : a = b) : Nat := if b then 13 else 17\n\ndef matchOriginal (a : Bool) : Nat :=\n  match h : a with\n  | true => matchOriginalValue a true h\n  | false => matchOriginalValue a false h\n\ntheorem matchDependentTarget (a : Bool) (h : a = a) : h = h :=\n  match a with\n  | true => Eq.refl h\n  | false => Eq.refl h\n\ndef m3matches (flag : Bool) : UInt64 :=\n  let first : flag = true → Nat := fun (_ : flag = true) => 3\n  let second : flag = false → Nat := fun (_ : flag = false) => 5\n  let computedFirst : Bool.not flag = true → Nat := fun (_ : Bool.not flag = true) => 7\n  let computedSecond : Bool.not flag = false → Nat := fun (_ : Bool.not flag = false) => 11\n  UInt64.ofNat (matchDefault flag first second +\n    10 * matchTrue flag first second +\n    100 * matchFalse flag first second +\n    1000 * matchLets flag first second +\n    10000 * matchComputed flag computedFirst computedSecond +\n    100000 * matchMixed flag first second +\n    1000000 * matchOriginal flag)\n"

private def matchPsSource : String :=
  "function matchDefault(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match a with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n\nfunction matchTrue(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := true) a with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n\nfunction matchFalse(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := false) h: a with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n\nfunction matchLets(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  let first: a = true -> Nat := h1\n  let second: a = false -> Nat := h2\n  match h: a with {\n  | true => first(h)\n  | false => second(h)\n  }\n\nfunction matchComputed(a: Bool, h1: Bool.not(a) = true -> Nat, h2: Bool.not(a) = false -> Nat): Nat :=\n  match h: Bool.not(a) with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n\nfunction matchMixed(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match a, Bool.not(a) with {\n  | true, false => h1(Eq.refl(true))\n  | false, true => h2(Eq.refl(false))\n  | _, _ => 0\n  }\n\nfunction matchOriginalValue(a: Bool, b: Bool, h: a = b): Nat := if (b) { 13 } else { 17 }\n\nfunction matchOriginal(a: Bool): Nat :=\n  match h: a with {\n  | true => matchOriginalValue(a, true, h)\n  | false => matchOriginalValue(a, false, h)\n  }\n\ntheorem matchDependentTarget(a: Bool, h: a = a): h = h :=\n  match a with {\n  | true => Eq.refl(h)\n  | false => Eq.refl(h)\n  }\n\nfunction m3matches(flag: Bool): UInt64 :=\n  let first: flag = true -> Nat := fun (_: flag = true) => 3\n  let second: flag = false -> Nat := fun (_: flag = false) => 5\n  let computedFirst: Bool.not(flag) = true -> Nat := fun (_: Bool.not(flag) = true) => 7\n  let computedSecond: Bool.not(flag) = false -> Nat := fun (_: Bool.not(flag) = false) => 11\n  UInt64.ofNat(matchDefault(flag, first, second) +\n    10 * matchTrue(flag, first, second) +\n    100 * matchFalse(flag, first, second) +\n    1000 * matchLets(flag, first, second) +\n    10000 * matchComputed(flag, computedFirst, computedSecond) +\n    100000 * matchMixed(flag, first, second) +\n    1000000 * matchOriginal(flag))\n"

private def matchPolicyLeanSource : String :=
  "class MatchPolicyWitness (a : Bool) where\n  mark : Nat\n\ndef matchInstanceOriginal (a : Bool) (w : MatchPolicyWitness a)\n    (b : Bool) (h : a = b) : True := True.intro\n\ntheorem matchInstance (a : Bool) [w : MatchPolicyWitness a] : True :=\n  match h : a with\n  | true => matchInstanceOriginal a w true h\n  | false => matchInstanceOriginal a w false h\n\ndef matchAux (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (matchAux k)\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n :=\n    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)\n  exact Nat.lt_succ_self k\n\ndef matchAuxFalse (n : Nat) : Nat :=\n  match (generalizing := false) h : n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (matchAuxFalse k)\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n :=\n    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)\n  exact Nat.lt_succ_self k\n\ndef matchAuxPrev (n : Nat) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k => k\n"

private def matchPolicyPsSource : String :=
  "class MatchPolicyWitness(a: Bool) where {\n  mark: Nat\n}\n\nfunction matchInstanceOriginal(a: Bool, w: MatchPolicyWitness a, b: Bool, h: a = b): True := True.intro\n\ntheorem matchInstance(a: Bool)[w: MatchPolicyWitness a]: True :=\n  match h: a with {\n  | true => matchInstanceOriginal(a, w, true, h)\n  | false => matchInstanceOriginal(a, w, false, h)\n  }\n\nfunction matchAux(n: Nat): Nat :=\n  match h: n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(matchAux(k))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(k, t), h), Nat.lt_succ_self(k))\n  exact Nat.lt_succ_self(k)\n}\n\nfunction matchAuxFalse(n: Nat): Nat :=\n  match (generalizing := false) h: n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(matchAuxFalse(k))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(k, t), h), Nat.lt_succ_self(k))\n  exact Nat.lt_succ_self(k)\n}\n\nfunction matchAuxPrev(n: Nat): Nat := match n with {\n  | 0 => 0\n  | Nat.succ k => k\n}\n"

private def matchLexicalLeanSource : String :=  "def matchSwap (a b : Nat) : Nat :=\n  match a, b with\n  | b, a => 10 * a + b\n\ntheorem matchSwapObserved : matchSwap 2 7 = 72 := Eq.refl 72\n\ndef matchNamedOriginalB (b : Bool) : Nat :=\n  match hb : b with\n  | true => (fun (_ : b = true) => 37) hb\n  | false => (fun (_ : b = false) => 41) hb\n\ntheorem matchNamedOriginalBTrue : matchNamedOriginalB true = 37 := Eq.refl 37\ntheorem matchNamedOriginalBFalse : matchNamedOriginalB false = 41 := Eq.refl 41\n\ndef matchEqRight {left right : Nat} (_ : left = right) : Nat := right\n\ndef matchEquationShadow (n : Nat) : Nat :=\n  match h : n with\n  | 0 => matchEqRight h\n  | Nat.succ h => matchEqRight h\n\ntheorem matchEquationShadowZero : matchEquationShadow 0 = 0 := Eq.refl 0\ntheorem matchEquationShadowSucc : matchEquationShadow 4 = 4 := Eq.refl 4\n\ndef matchNestedBindings (a : Bool) (handle : a = a → Nat) : Nat :=\n  match (generalizing := true) a with\n  | x =>\n    match x with\n    | true => handle (Eq.refl true)\n    | false => handle (Eq.refl false)\n\ntheorem matchNestedBindingsTrue :\n    matchNestedBindings true (fun (_ : true = true) => 31) = 31 := Eq.refl 31\ntheorem matchNestedBindingsFalse :\n    matchNestedBindings false (fun (_ : false = false) => 43) = 43 := Eq.refl 43\n"

private def matchLexicalPsSource : String :=  "function matchSwap(a: Nat, b: Nat): Nat :=\n  match a, b with {\n  | b, a => 10 * a + b\n  }\n\ntheorem matchSwapObserved: matchSwap(2, 7) = 72 := Eq.refl(72)\n\nfunction matchNamedOriginalB(b: Bool): Nat :=\n  match hb: b with {\n  | true => (fun (_: b = true) => 37)(hb)\n  | false => (fun (_: b = false) => 41)(hb)\n  }\n\ntheorem matchNamedOriginalBTrue: matchNamedOriginalB(true) = 37 := Eq.refl(37)\ntheorem matchNamedOriginalBFalse: matchNamedOriginalB(false) = 41 := Eq.refl(41)\n\nfunction matchEqRight {left right: Nat}(proof: left = right): Nat := right\n\nfunction matchEquationShadow(n: Nat): Nat :=\n  match h: n with {\n  | 0 => matchEqRight(h)\n  | Nat.succ h => matchEqRight(h)\n  }\n\ntheorem matchEquationShadowZero: matchEquationShadow(0) = 0 := Eq.refl(0)\ntheorem matchEquationShadowSucc: matchEquationShadow(4) = 4 := Eq.refl(4)\n\nfunction matchNestedBindings(a: Bool, handle: a = a -> Nat): Nat :=\n  match (generalizing := true) a with {\n  | x =>\n    match x with {\n    | true => handle(Eq.refl(true))\n    | false => handle(Eq.refl(false))\n    }\n  }\n\ntheorem matchNestedBindingsTrue:\n  matchNestedBindings(true, fun (_: true = true) => 31) = 31 := Eq.refl(31)\ntheorem matchNestedBindingsFalse:\n  matchNestedBindings(false, fun (_: false = false) => 43) = 43 := Eq.refl(43)\n"

private def matchIndexedLeanSource : String :=  "inductive MatchIndexed : Bool → Type where\n  | yes (value : Nat) : MatchIndexed true\n  | no (value : Nat) : MatchIndexed false\n\ndef matchIndexMake (a : Bool) : MatchIndexed a :=\n  match a with\n  | true => MatchIndexed.yes 53\n  | false => MatchIndexed.no 59\n\ndef matchIndexBoolEqMark (a b : Bool) (_ : a = b) : Nat := 0\n\ndef matchIndexEqMark (a : Bool) (original current : MatchIndexed a)\n    (_ : original = current) : Nat := 0\n\ndef matchIndexHEqMark (a : Bool) (original : MatchIndexed a)\n    (b : Bool) (current : MatchIndexed b) (_ : HEq original current) : Nat := 0\n\ndef matchComputedLaterFalse (a : Bool) : Nat :=\n  match (generalizing := false) ha : a, hv : matchIndexMake a with\n  | true, MatchIndexed.yes n =>\n    n + matchIndexBoolEqMark a true ha +\n      matchIndexHEqMark a (matchIndexMake a) true (MatchIndexed.yes n) hv\n  | false, MatchIndexed.no n =>\n    n + matchIndexBoolEqMark a false ha +\n      matchIndexHEqMark a (matchIndexMake a) false (MatchIndexed.no n) hv\n\ntheorem matchComputedLaterFalseTrue : matchComputedLaterFalse true = 53 := Eq.refl 53\ntheorem matchComputedLaterFalseFalse : matchComputedLaterFalse false = 59 := Eq.refl 59\n\ndef matchIndexedNamed (a : Bool) (value : MatchIndexed a) : Nat :=\n  match (generalizing := false) h : value with\n  | MatchIndexed.yes n =>\n    n + matchIndexHEqMark a value true (MatchIndexed.yes n) h\n  | MatchIndexed.no n =>\n    n + matchIndexHEqMark a value false (MatchIndexed.no n) h\n\ntheorem matchIndexedNamedTrue :\n    matchIndexedNamed true (MatchIndexed.yes 61) = 61 := Eq.refl 61\ntheorem matchIndexedNamedFalse :\n    matchIndexedNamed false (MatchIndexed.no 67) = 67 := Eq.refl 67\n\ndef matchIndexedNamedEq (value : MatchIndexed true) : Nat :=\n  match h : value with\n  | MatchIndexed.yes n => n + matchIndexEqMark true value (MatchIndexed.yes n) h\n\ntheorem matchIndexedNamedEqObserved :\n    matchIndexedNamedEq (MatchIndexed.yes 71) = 71 := Eq.refl 71\n\ndef matchNestedIndexed (a : Bool) (value : MatchIndexed a)\n    (handle : value = value → Nat) : Nat :=\n  match a with\n  | true =>\n    match value with\n    | MatchIndexed.yes n => handle (Eq.refl (MatchIndexed.yes n))\n  | false =>\n    match value with\n    | MatchIndexed.no n => handle (Eq.refl (MatchIndexed.no n))\n\ntheorem matchNestedIndexedTrue :\n    matchNestedIndexed true (MatchIndexed.yes 2)\n      (fun (_ : MatchIndexed.yes 2 = MatchIndexed.yes 2) => 73) = 73 := Eq.refl 73\ntheorem matchNestedIndexedFalse :\n    matchNestedIndexed false (MatchIndexed.no 3)\n      (fun (_ : MatchIndexed.no 3 = MatchIndexed.no 3) => 79) = 79 := Eq.refl 79\n\ninductive MatchRowPack where\n  | pack (index : Bool) (value : MatchIndexed index)\n\ndef matchRowDependent (packed : MatchRowPack) : Nat :=\n  match packed with\n  | MatchRowPack.pack _ value =>\n    let same : value = value := Eq.refl value\n    83\n\ndef matchRowNested (packed : Option MatchRowPack) : Nat :=\n  match packed with\n  | Option.none => 0\n  | Option.some (MatchRowPack.pack _ value) =>\n    let same : value = value := Eq.refl value\n    89\n\ntheorem matchRowDependentObserved :\n    matchRowDependent (MatchRowPack.pack true (MatchIndexed.yes 2)) = 83 := Eq.refl 83\ntheorem matchRowNestedObserved :\n    matchRowNested (Option.some (MatchRowPack.pack false (MatchIndexed.no 3))) = 89 := Eq.refl 89\n"

private def matchIndexedPsSource : String :=  "inductive MatchIndexed: Bool -> Type where {\n  | yes(value: Nat): MatchIndexed(true)\n  | no(value: Nat): MatchIndexed(false)\n}\n\nfunction matchIndexMake(a: Bool): MatchIndexed(a) :=\n  match a with {\n  | true => MatchIndexed.yes(53)\n  | false => MatchIndexed.no(59)\n  }\n\nfunction matchIndexBoolEqMark(a: Bool, b: Bool, proof: a = b): Nat := 0\n\nfunction matchIndexEqMark(a: Bool, original: MatchIndexed(a), current: MatchIndexed(a), proof: original = current): Nat := 0\n\nfunction matchIndexHEqMark(a: Bool, original: MatchIndexed(a), b: Bool, current: MatchIndexed(b), proof: HEq(original, current)): Nat := 0\n\nfunction matchComputedLaterFalse(a: Bool): Nat :=\n  match (generalizing := false) ha: a, hv: matchIndexMake(a) with {\n  | true, MatchIndexed.yes n =>\n    n + matchIndexBoolEqMark(a, true, ha) +\n      matchIndexHEqMark(a, matchIndexMake(a), true, MatchIndexed.yes(n), hv)\n  | false, MatchIndexed.no n =>\n    n + matchIndexBoolEqMark(a, false, ha) +\n      matchIndexHEqMark(a, matchIndexMake(a), false, MatchIndexed.no(n), hv)\n  }\n\ntheorem matchComputedLaterFalseTrue: matchComputedLaterFalse(true) = 53 := Eq.refl(53)\ntheorem matchComputedLaterFalseFalse: matchComputedLaterFalse(false) = 59 := Eq.refl(59)\n\nfunction matchIndexedNamed(a: Bool, value: MatchIndexed(a)): Nat :=\n  match (generalizing := false) h: value with {\n  | MatchIndexed.yes n =>\n    n + matchIndexHEqMark(a, value, true, MatchIndexed.yes(n), h)\n  | MatchIndexed.no n =>\n    n + matchIndexHEqMark(a, value, false, MatchIndexed.no(n), h)\n  }\n\ntheorem matchIndexedNamedTrue:\n  matchIndexedNamed(true, MatchIndexed.yes(61)) = 61 := Eq.refl(61)\ntheorem matchIndexedNamedFalse:\n  matchIndexedNamed(false, MatchIndexed.no(67)) = 67 := Eq.refl(67)\n\nfunction matchIndexedNamedEq(value: MatchIndexed(true)): Nat :=\n  match h: value with {\n  | MatchIndexed.yes n => n + matchIndexEqMark(true, value, MatchIndexed.yes(n), h)\n  }\n\ntheorem matchIndexedNamedEqObserved:\n  matchIndexedNamedEq(MatchIndexed.yes(71)) = 71 := Eq.refl(71)\n\nfunction matchNestedIndexed(a: Bool, value: MatchIndexed(a), handle: value = value -> Nat): Nat :=\n  match a with {\n  | true =>\n    match value with {\n    | MatchIndexed.yes n => handle(Eq.refl(MatchIndexed.yes(n)))\n    }\n  | false =>\n    match value with {\n    | MatchIndexed.no n => handle(Eq.refl(MatchIndexed.no(n)))\n    }\n  }\n\ntheorem matchNestedIndexedTrue:\n  matchNestedIndexed(true, MatchIndexed.yes(2),\n    fun (_: MatchIndexed.yes(2) = MatchIndexed.yes(2)) => 73) = 73 := Eq.refl(73)\ntheorem matchNestedIndexedFalse:\n  matchNestedIndexed(false, MatchIndexed.no(3),\n    fun (_: MatchIndexed.no(3) = MatchIndexed.no(3)) => 79) = 79 := Eq.refl(79)\n\ninductive MatchRowPack where {\n  | pack(index: Bool, value: MatchIndexed(index))\n}\n\nfunction matchRowDependent(packed: MatchRowPack): Nat :=\n  match packed with {\n  | MatchRowPack.pack _ value =>\n    let same: value = value := Eq.refl(value)\n    83\n  }\n\nfunction matchRowNested(packed: Option(MatchRowPack)): Nat :=\n  match packed with {\n  | Option.none => 0\n  | Option.some (MatchRowPack.pack _ value) =>\n    let same: value = value := Eq.refl(value)\n    89\n  }\n\ntheorem matchRowDependentObserved:\n    matchRowDependent(MatchRowPack.pack(true, MatchIndexed.yes(2))) = 83 := Eq.refl(83)\ntheorem matchRowNestedObserved:\n    matchRowNested(Option.some(MatchRowPack.pack(false, MatchIndexed.no(3)))) = 89 := Eq.refl(89)\n"

private def structuralLeanSource : String :=
  "def namedCount (n : Nat) : Nat :=\n  match h : n with\n  | 0 => let witness : n = 0 := h; 0\n  | Nat.succ k => let witness : n = Nat.succ k := h; Nat.succ (namedCount k)\ndef namedResult (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) => match (generalizing := false) h : n with\n    | 0 => bias\n    | Nat.succ k => namedResult k (Nat.succ bias)\ndef namedRows (A : Type) (rows : List (List A)) : Nat :=\n  match h : rows with\n  | .nil => 0\n  | .cons row rest => Nat.succ (namedRows A rest)\ndef namedComputed (F : Nat → Type) (i : Nat) (values : List (F i)) : Nat :=\n  match (generalizing := true) h : values with\n  | .nil => 0\n  | .cons value rest => Nat.succ (namedComputed F i rest)\ninductive NamedNest (A : Type) where\n  | leaf (value : A)\n  | direct (child : NamedNest A)\n  | many (children : List (NamedNest A))\n  | deep (children : List (List (NamedNest A)))\nmutual\ndef namedTree (A : Type) (tree : NamedNest A) : Nat :=\n  match h : tree with\n  | .leaf value => 1\n  | .direct child => Nat.succ (namedTree A child)\n  | .many children => Nat.succ (namedForest A children)\n  | .deep children => Nat.succ (namedDeep A children)\ndef namedForest (A : Type) (children : List (NamedNest A)) : Nat :=\n  match h : children with\n  | .nil => 0\n  | .cons child rest => namedTree A child + namedForest A rest\ndef namedDeep (A : Type) (children : List (List (NamedNest A))) : Nat :=\n  match h : children with\n  | .nil => 0\n  | .cons row rest => namedForest A row + namedDeep A rest\nend\ndef m3structural (flag : Bool) : UInt64 :=\n  let amount := if flag then 3 else 5\n  let rows := List.cons (List.cons amount List.nil) (List.cons List.nil List.nil)\n  let leaf := NamedNest.leaf amount\n  let trees := List.cons leaf (List.cons (NamedNest.direct leaf) List.nil)\n  let tree := if flag then\n    NamedNest.deep (List.cons trees (List.cons (List.cons (NamedNest.direct leaf) List.nil) List.nil))\n    else NamedNest.many (List.cons (NamedNest.deep (List.cons trees List.nil)) (List.cons (NamedNest.direct leaf) List.nil))\n  UInt64.ofNat (namedCount amount + 10 * namedResult amount 4 +\n    100 * namedRows Nat rows +\n    1000 * namedComputed (fun (_ : Nat) => Nat) amount (List.cons amount List.nil) +\n    10000 * namedTree Nat tree)\ntheorem namedResultObserved : namedResult 3 5 = 8 := by rfl\ntheorem namedResultSource (n : Nat) :\n    namedResult n = (fun (bias : Nat) => match (generalizing := false) h : n with\n      | 0 => bias\n      | Nat.succ k => namedResult k (Nat.succ bias)) :=\n  by exact namedResult.eq_def n\n\ndef constCount : Nat → Nat := fun n =>\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (constCount k)\n\ntheorem constCountObserved : constCount 3 = 3 := Eq.refl 3\n\ntheorem constCountSourceEquation :\n    constCount = (fun n => match n with\n      | 0 => 0\n      | Nat.succ k => Nat.succ (constCount k)) := constCount.eq_def\n\ndef ConstCountType : Type := Nat → Nat\n\ndef constAliasCount : ConstCountType := fun n =>\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (constAliasCount k)\n\ntheorem constAliasCountObserved : constAliasCount 3 = 3 := Eq.refl 3\n\ntheorem constAliasCountSourceEquation :\n    constAliasCount = (fun n => match n with\n      | 0 => 0\n      | Nat.succ k => Nat.succ (constAliasCount k)) := constAliasCount.eq_def\n\ndef m3const (flag : Bool) : UInt64 :=\n  let n := if flag then 3 else 5\n  UInt64.ofNat (constCount n + 10 * constAliasCount (Nat.succ n))\n"

private def structuralPsSource : String :=
  "function namedCount(n: Nat): Nat := match h : n with {\n  | 0 => let witness: n = 0 := h\n    0\n  | Nat.succ k => let witness: n = Nat.succ(k) := h\n    Nat.succ(namedCount(k))\n}\nfunction namedResult(n: Nat): Nat -> Nat := fun (bias: Nat) => match (generalizing := false) h : n with {\n  | 0 => bias\n  | Nat.succ k => namedResult(k, Nat.succ(bias))\n}\nfunction namedRows(A: Type, rows: List(List(A))): Nat := match h : rows with {\n  | .nil => 0\n  | .cons row rest => Nat.succ(namedRows(A, rest))\n}\nfunction namedComputed(F: Nat -> Type, i: Nat, values: List(F(i))): Nat := match (generalizing := true) h : values with {\n  | .nil => 0\n  | .cons value rest => Nat.succ(namedComputed(F, i, rest))\n}\ninductive NamedNest(A: Type) where {\n  | leaf(value: A)\n  | direct(child: NamedNest(A))\n  | many(children: List(NamedNest(A)))\n  | deep(children: List(List(NamedNest(A))))\n}\nmutual\nfunction namedTree(A: Type, tree: NamedNest(A)): Nat := match h : tree with {\n  | .leaf value => 1\n  | .direct child => Nat.succ(namedTree(A, child))\n  | .many children => Nat.succ(namedForest(A, children))\n  | .deep children => Nat.succ(namedDeep(A, children))\n}\nfunction namedForest(A: Type, children: List(NamedNest(A))): Nat := match h : children with {\n  | .nil => 0\n  | .cons child rest => namedTree(A, child) + namedForest(A, rest)\n}\nfunction namedDeep(A: Type, children: List(List(NamedNest(A)))): Nat := match h : children with {\n  | .nil => 0\n  | .cons row rest => namedForest(A, row) + namedDeep(A, rest)\n}\nend\nfunction m3structural(flag: Bool): UInt64 :=\n  let amount := if (flag) { 3 } else { 5 }\n  let rows := List.cons(List.cons(amount, List.nil), List.cons(List.nil, List.nil))\n  let leaf := NamedNest.leaf(amount)\n  let trees := List.cons(leaf, List.cons(NamedNest.direct(leaf), List.nil))\n  let tree := if (flag) {\n    NamedNest.deep(List.cons(trees, List.cons(List.cons(NamedNest.direct(leaf), List.nil), List.nil)))\n  } else {\n    NamedNest.many(List.cons(NamedNest.deep(List.cons(trees, List.nil)), List.cons(NamedNest.direct(leaf), List.nil)))\n  }\n  UInt64.ofNat(namedCount(amount) + 10 * namedResult(amount, 4) +\n    100 * namedRows(Nat, rows) +\n    1000 * namedComputed(fun (_: Nat) => Nat, amount, List.cons(amount, List.nil)) +\n    10000 * namedTree(Nat, tree))\ntheorem namedResultObserved: namedResult(3, 5) = 8 := by { rfl }\ntheorem namedResultSource(n: Nat):\n    namedResult(n) = (fun (bias: Nat) => match (generalizing := false) h : n with {\n      | 0 => bias\n      | Nat.succ k => namedResult(k, Nat.succ(bias))\n    }) := by { exact namedResult.eq_def(n) }\n\nconst constCount: Nat -> Nat := fun (n: Nat) =>\n  match n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(constCount(k))\n  }\n\ntheorem constCountObserved: constCount(3) = 3 := Eq.refl(3)\n\ntheorem constCountSourceEquation:\n    constCount = (fun (n: Nat) => match n with {\n      | 0 => 0\n      | Nat.succ k => Nat.succ(constCount(k))\n    }) := constCount.eq_def\n\nconst ConstCountType: Type := Nat -> Nat\n\nconst constAliasCount: ConstCountType := fun (n: Nat) =>\n  match n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(constAliasCount(k))\n  }\n\ntheorem constAliasCountObserved: constAliasCount(3) = 3 := Eq.refl(3)\n\ntheorem constAliasCountSourceEquation:\n    constAliasCount = (fun (n: Nat) => match n with {\n      | 0 => 0\n      | Nat.succ k => Nat.succ(constAliasCount(k))\n    }) := constAliasCount.eq_def\n\nfunction m3const(flag: Bool): UInt64 :=\n  let n := if (flag) { 3 } else { 5 }\n  UInt64.ofNat(constCount(n) + 10 * constAliasCount(Nat.succ(n)))\n"

private def inlineLeanSource : String :=
  "inductive InlineTree where\n  | node (children : List InlineTree)\ndef inlinePlain (tree : InlineTree) : Bool :=\n  match tree with\n  | .node [] => true\n  | .node [t] => inlinePlain t\n  | .node _ => false\ndef inlineNamed (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => let witness : tree = InlineTree.node [] := h; true\n  | .node [t] => let witness : tree = InlineTree.node [t] := h; inlineNamed t\n  | .node _ => false\ndef inlineDeep (tree : InlineTree) : Nat :=\n  match h : tree with\n  | .node [.node [t]] => Nat.succ (inlineDeep t)\n  | .node _ => 0\ndef inlineResult (tree : InlineTree) : Nat → Nat :=\n  fun (bias : Nat) => match (generalizing := false) h : tree with\n    | .node [] => bias\n    | .node [t] => inlineResult t (Nat.succ bias)\n    | .node _ => bias + 10\nmutual\ndef inlineEven (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => true\n  | .node [t] => inlineOdd t\n  | .node _ => false\ndef inlineOdd (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => false\n  | .node [t] => inlineEven t\n  | .node _ => false\nend\ninductive InlineBranch where\n  | node (children : Bool → List InlineBranch)\nmutual\ndef inlineBranch (tree : InlineBranch) : Nat :=\n  match h : tree with\n  | .node children => inlineBranchChildren (children true)\ndef inlineBranchChildren (trees : List InlineBranch) : Nat :=\n  match hc : trees with\n  | [] => 0\n  | [t] => Nat.succ (inlineBranch t)\n  | _ => 0\nend\ninductive InlineIndexed : Nat → Type where\n  | node (children : List (InlineIndexed 0)) : InlineIndexed 0\ndef inlineIndexed (n : Nat) (tree : InlineIndexed n) : Nat :=\n  match h : tree with\n  | .node [] => 0\n  | .node [t] => Nat.succ (inlineIndexed 0 t)\n  | .node _ => 0\ndef m3inline (flag : Bool) : UInt64 :=\n  let leaf := InlineTree.node []\n  let link := InlineTree.node [leaf]\n  let chain := InlineTree.node [link]\n  let wide := InlineTree.node [leaf, leaf]\n  let tree := if flag then chain else wide\n  let branchEmpty := InlineBranch.node (fun (_ : Bool) => [])\n  let branchLink := InlineBranch.node (fun (_ : Bool) => [branchEmpty])\n  let branchChain := InlineBranch.node (fun (_ : Bool) => [branchLink])\n  let branchInput := if flag then branchLink else branchChain\n  let ix0 := InlineIndexed.node []\n  let ix1 := InlineIndexed.node [ix0]\n  let ix2 := InlineIndexed.node [ix1]\n  let indexInput := if flag then ix1 else ix2\n  let mutualInput := if flag then chain else link\n  UInt64.ofNat (\n    (if inlinePlain tree then 1 else 0) +\n    10 * (if inlineNamed tree then 1 else 0) +\n    100 * inlineResult tree 4 +\n    10000 * inlineDeep tree +\n    100000 * inlineBranch branchInput +\n    1000000 * inlineIndexed 0 indexInput +\n    10000000 * (if inlineEven mutualInput then 1 else 0) +\n    100000000 * (if inlineOdd mutualInput then 1 else 0))\ntheorem inlineResultObserved :\n    inlineResult (InlineTree.node [InlineTree.node []]) 5 = 6 := by rfl\n"

private def inlinePsSource : String :=
  "inductive InlineTree where {\n  | node(children: List(InlineTree))\n}\nfunction inlinePlain(tree: InlineTree): Bool := match tree with {\n  | .node [] => true\n  | .node [t] => inlinePlain(t)\n  | .node _ => false\n}\nfunction inlineNamed(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => let witness: tree = InlineTree.node([]) := h\n    true\n  | .node [t] => let witness: tree = InlineTree.node([t]) := h\n    inlineNamed(t)\n  | .node _ => false\n}\nfunction inlineDeep(tree: InlineTree): Nat := match h: tree with {\n  | .node [.node [t]] => Nat.succ(inlineDeep(t))\n  | .node _ => 0\n}\nfunction inlineResult(tree: InlineTree): Nat -> Nat :=\n  fun (bias: Nat) => match (generalizing := false) h: tree with {\n    | .node [] => bias\n    | .node [t] => inlineResult(t, Nat.succ(bias))\n    | .node _ => bias + 10\n  }\nmutual\nfunction inlineEven(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => true\n  | .node [t] => inlineOdd(t)\n  | .node _ => false\n}\nfunction inlineOdd(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => false\n  | .node [t] => inlineEven(t)\n  | .node _ => false\n}\nend\ninductive InlineBranch where {\n  | node(children: Bool -> List(InlineBranch))\n}\nmutual {\nfunction inlineBranch(tree: InlineBranch): Nat := match h: tree with {\n  | .node children => inlineBranchChildren(children(true))\n}\nfunction inlineBranchChildren(trees: List(InlineBranch)): Nat := match hc: trees with {\n  | [] => 0\n  | [t] => Nat.succ(inlineBranch(t))\n  | _ => 0\n}\n}\ninductive InlineIndexed: Nat -> Type where {\n  | node(children: List(InlineIndexed(0))): InlineIndexed(0)\n}\nfunction inlineIndexed(n: Nat, tree: InlineIndexed(n)): Nat := match h: tree with {\n  | .node [] => 0\n  | .node [t] => Nat.succ(inlineIndexed(0, t))\n  | .node _ => 0\n}\nfunction m3inline(flag: Bool): UInt64 :=\n  let leaf := InlineTree.node([])\n  let link := InlineTree.node([leaf])\n  let chain := InlineTree.node([link])\n  let wide := InlineTree.node([leaf, leaf])\n  let tree := if (flag) { chain } else { wide }\n  let branchEmpty := InlineBranch.node(fun (_: Bool) => [])\n  let branchLink := InlineBranch.node(fun (_: Bool) => [branchEmpty])\n  let branchChain := InlineBranch.node(fun (_: Bool) => [branchLink])\n  let branchInput := if (flag) { branchLink } else { branchChain }\n  let ix0 := InlineIndexed.node([])\n  let ix1 := InlineIndexed.node([ix0])\n  let ix2 := InlineIndexed.node([ix1])\n  let indexInput := if (flag) { ix1 } else { ix2 }\n  let mutualInput := if (flag) { chain } else { link }\n  UInt64.ofNat(\n    (if (inlinePlain(tree)) { 1 } else { 0 }) +\n    10 * (if (inlineNamed(tree)) { 1 } else { 0 }) +\n    100 * inlineResult(tree, 4) +\n    10000 * inlineDeep(tree) +\n    100000 * inlineBranch(branchInput) +\n    1000000 * inlineIndexed(0, indexInput) +\n    10000000 * (if (inlineEven(mutualInput)) { 1 } else { 0 }) +\n    100000000 * (if (inlineOdd(mutualInput)) { 1 } else { 0 }))\ntheorem inlineResultObserved:\n  inlineResult(InlineTree.node([InlineTree.node([])]), 5) = 6 := by { rfl }\n"

private def registeredLeanSource : String :=
  "opaque registeredOpaque (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 2\n  | Nat.succ k => Nat.succ (registeredOpaque k)\nabbrev registeredAbbrev (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 3\n  | Nat.succ k => Nat.succ (registeredAbbrev k)\nclass RegisteredValue (n : Nat) where\n  value : Nat\ninstance registeredInstance (n : Nat) : RegisteredValue n where\n  value := match h : n with\n    | 0 => 4\n    | Nat.succ k => Nat.succ (@RegisteredValue.value k (registeredInstance k))\nclass RegisteredDefault (n : Nat) where\n  value : Nat\n@[default_instance 200]\ninstance registeredDefault (n : Nat) : RegisteredDefault n where\n  value := match h : n with\n    | 0 => 5\n    | Nat.succ k => Nat.succ (@RegisteredDefault.value k (registeredDefault k))\ndef m3registered (flag : Bool) : UInt64 :=\n  let n := if flag then 3 else 5\n  UInt64.ofNat (registeredOpaque n + 10 * registeredAbbrev n +\n    100 * (@RegisteredValue.value n (registeredInstance n)) +\n    1000 * (@RegisteredDefault.value n (registeredDefault n)))\n"

private def registeredPsSource : String :=
  "opaque registeredOpaque(n: Nat): Nat := match h: n with {\n  | 0 => 2\n  | Nat.succ k => Nat.succ(registeredOpaque(k))\n}\nabbrev registeredAbbrev(n: Nat): Nat := match h: n with {\n  | 0 => 3\n  | Nat.succ k => Nat.succ(registeredAbbrev(k))\n}\nclass RegisteredValue(n: Nat) where {\n  value: Nat\n}\ninstance registeredInstance(n: Nat): RegisteredValue(n) where {\n  value := match h: n with {\n    | 0 => 4\n    | Nat.succ k => Nat.succ(@RegisteredValue.value(k, registeredInstance(k)))\n  }\n}\nclass RegisteredDefault(n: Nat) where {\n  value: Nat\n}\n@[default_instance 200]\ninstance registeredDefault(n: Nat): RegisteredDefault(n) where {\n  value := match h: n with {\n    | 0 => 5\n    | Nat.succ k => Nat.succ(@RegisteredDefault.value(k, registeredDefault(k)))\n  }\n}\nfunction m3registered(flag: Bool): UInt64 :=\n  let n := if (flag) { 3 } else { 5 }\n  UInt64.ofNat(registeredOpaque(n) + 10 * registeredAbbrev(n) +\n    100 * (@RegisteredValue.value(n, registeredInstance(n))) +\n    1000 * (@RegisteredDefault.value(n, registeredDefault(n))))\n"

private def checkCoreBoundaryControls : IO Unit := do
  let name := psRootName "x"
  let prop := PsExpr.sortE .zero
  let type := PsExpr.forallE name prop prop .explicit
  let value := PsExpr.lam name prop (.bvar 0) .explicit
  let argument := PsExpr.forallE name prop (.bvar 0) .explicit
  let initial := psElabContextEmpty psEnvironmentEmpty
  let opened ← fromExcept ((psElabCoreBoundaryOpen initial .row value type).mapError
    psCompilerPscv0ElabError)
  let applied ← fromExcept ((psElabApplyCore opened.context (.fvar opened.id) [argument]).mapError
    psCompilerPscv0ElabError)
  let closed ← fromExcept ((psElabCoreBoundaryClose opened applied (some prop)).mapError
    psCompilerPscv0ElabError)
  let .letE key actualType actualValue body := closed.term
    | throw (IO.userError "checked Core boundary lost its actual let")
  let view := psExprAppView body
  ensure (psExprAlphaEq view.head (.bvar 0) && view.args.length == 1 &&
    view.args.all (fun arg => psElabCoreBoundaryClosed arg))
    "checked Core boundary lost its direct owned application"
  let matched ← fromExcept ((psElabCoreBoundaryMatch closed.context key actualType actualValue).mapError
    psCompilerPscv0ElabError)
  ensure matched.isSome "checked Core boundary rejected its own checked template"
  let restored := psElabRestoreScope closed.context (psElabSaveScope initial)
  let second ← fromExcept ((psElabCoreBoundaryOpen restored .row value type).mapError
    psCompilerPscv0ElabError)
  ensure (!psNameEq second.name key && second.outer.coreBoundaries.length == 2)
    "checked Core boundary identity was reused after scope restoration"
  let accept := fun template actual =>
    (psElabCoreBoundaryTemplate [0, 1] template actual []).isSome
  ensure (accept (.app (.fvar 0) (.fvar 1)) (.app (.fvar 10) (.fvar 11)))
    "checked Core boundary rejected consistent caller specialization"
  for (label, template, actual) in [
      ("repeated caller identity", PsExpr.app (.fvar 0) (.fvar 0),
        PsExpr.app (.fvar 10) (.fvar 11)),
      ("binder capture", PsExpr.lam name prop (.fvar 0) .explicit,
        PsExpr.lam name prop (.bvar 0) .explicit),
      ("bound index", PsExpr.lam name prop (.bvar 0) .explicit,
        PsExpr.lam name prop (.bvar 1) .explicit),
      ("binder kind", PsExpr.forallE name prop prop .explicit,
        PsExpr.forallE name prop prop .implicit),
      ("logical constructor", PsExpr.lam name prop (.bvar 0) .explicit,
        PsExpr.forallE name prop (.bvar 0) .explicit),
      ("constant universe", PsExpr.constE name [.zero],
        PsExpr.constE name [.succ .zero]),
      ("projection index", PsExpr.proj name 0 (.fvar 0),
        PsExpr.proj name 1 (.fvar 0))] do
    ensure (!(accept template actual)) ("checked Core boundary ignored " ++ label)
  let entry : PsElabCoreBoundary := {
    name := key, kind := .row
    type := .forallE name (.fvar 0) (.fvar 0) .explicit
    value := .lam name (.fvar 0) (.bvar 0) .explicit
    localIds := [0] }
  let context := { initial with coreBoundaries := [entry] }
  let matched ← fromExcept ((psElabCoreBoundaryMatch context key type value).mapError
    psCompilerPscv0ElabError)
  ensure matched.isSome "checked Core boundary rejected shared type/value specialization"
  let changed := PsExpr.lam name (.sortE (.succ .zero)) (.bvar 0) .explicit
  let mismatch ← fromExcept ((psElabCoreBoundaryMatch context key type changed).mapError
    psCompilerPscv0ElabError)
  ensure mismatch.isNone "checked Core boundary used independent type/value substitutions"
  let safe := psMetaFresh initial.metaContext initial.localContext prop .natural
  let safeEntry := { entry with type := prop, value := safe.expr, localIds := [] }
  let safeContext := { initial with metaContext := safe.context, coreBoundaries := [safeEntry] }
  let matched ← fromExcept ((psElabCoreBoundaryMatch safeContext key prop safe.expr).mapError
    psCompilerPscv0ElabError)
  ensure matched.isSome "Core boundary rejected a scope-safe unresolved metavariable"
  let hidden := psLocalPushBinding initial.localContext name prop .explicit
  let escaping := psMetaFresh initial.metaContext hidden.context prop .natural
  let escapingEntry := { entry with type := prop, value := escaping.expr, localIds := [] }
  let escapingContext := {
    initial with metaContext := escaping.context, coreBoundaries := [escapingEntry] }
  let matched ← fromExcept ((psElabCoreBoundaryMatch escapingContext key prop escaping.expr).mapError
    psCompilerPscv0ElabError)
  ensure matched.isNone "Core boundary allowed a future assignment to capture a hidden local"
  let invalid := { entry with type := prop, value := prop, localIds := [] }
  match psElabCoreBoundaryMatch { initial with coreBoundaries := [invalid] } key prop prop with
  | .error (.infer .letTypeMismatch) => pure ()
  | .error error => throw (IO.userError ("Core boundary type check changed failure: " ++
      psCompilerPscv0ElabError error))
  | .ok _ => throw (IO.userError "Core boundary trusted metadata instead of checking its value")

private def predicatePlainLeanSource : String :=
  "inductive PlainPredicate : Prop where\n  | base\n  | step (children : Nat → PlainPredicate)\ndef predicatePlain (proof : PlainPredicate) : True :=\n  match proof with\n  | .base => True.intro\n  | .step children =>\n    match children 1 with\n    | .base => True.intro\n    | .step grandchildren => predicatePlain (grandchildren 1)\ntheorem predicatePlainObserved :\n    predicatePlain (PlainPredicate.step (fun (_ : Nat) =>\n      PlainPredicate.step (fun (_ : Nat) => PlainPredicate.base))) = True.intro := by rfl\n"

private def predicatePlainPsSource : String :=
  "inductive PlainPredicate: Prop where {\n  | base\n  | step(children: Nat -> PlainPredicate)\n}\nfunction predicatePlain(proof: PlainPredicate): True := match proof with {\n  | .base => True.intro\n  | .step children => match children(1) with {\n    | .base => True.intro\n    | .step grandchildren => predicatePlain(grandchildren(1))\n  }\n}\ntheorem predicatePlainObserved:\n  predicatePlain(PlainPredicate.step(fun (_: Nat) =>\n    PlainPredicate.step(fun (_: Nat) => PlainPredicate.base))) = True.intro := by { rfl }\n"

private def predicateNamedLeanSource : String :=
  "inductive NamedPredicate : Prop where\n  | base\n  | step (children : Nat → NamedPredicate)\ndef predicateNamed (proof : NamedPredicate) : True :=\n  match hp : proof with\n  | .base => let witness : proof = NamedPredicate.base := hp; True.intro\n  | .step children =>\n    match hc : children 1 with\n    | .base => True.intro\n    | .step grandchildren => predicateNamed (grandchildren 1)\ntheorem predicateNamedObserved :\n    predicateNamed (NamedPredicate.step (fun (_ : Nat) =>\n      NamedPredicate.step (fun (_ : Nat) => NamedPredicate.base))) = True.intro := by rfl\n"

private def predicateNamedPsSource : String :=
  "inductive NamedPredicate: Prop where {\n  | base\n  | step(children: Nat -> NamedPredicate)\n}\nfunction predicateNamed(proof: NamedPredicate): True := match hp: proof with {\n  | .base => let witness: proof = NamedPredicate.base := hp\n    True.intro\n  | .step children => match hc: children(1) with {\n    | .base => True.intro\n    | .step grandchildren => predicateNamed(grandchildren(1))\n  }\n}\ntheorem predicateNamedObserved:\n  predicateNamed(NamedPredicate.step(fun (_: Nat) =>\n    NamedPredicate.step(fun (_: Nat) => NamedPredicate.base))) = True.intro := by { rfl }\n"

private def predicateIndexLeanSource : String :=
  "inductive ProofIndex : Nat → Prop where\n  | base : ProofIndex 0\n  | step (n : Nat) (child : ProofIndex n) : ProofIndex (Nat.succ n)\ndef predicateIndex (n : Nat) (proof : ProofIndex n) : n = n :=\n  match h : proof with\n  | .base => Eq.refl 0\n  | .step k child =>\n    match hc : child with\n    | .base => Eq.refl 1\n    | .step j grandchild =>\n      congrArg Nat.succ (congrArg Nat.succ (predicateIndex j grandchild))\ntheorem predicateIndexObserved :\n    predicateIndex 2 (ProofIndex.step 1 (ProofIndex.step 0 ProofIndex.base)) = Eq.refl 2 := by rfl\n"

private def predicateIndexPsSource : String :=
  "inductive ProofIndex: Nat -> Prop where {\n  | base: ProofIndex(0)\n  | step(n: Nat, child: ProofIndex(n)): ProofIndex(Nat.succ(n))\n}\nfunction predicateIndex(n: Nat, proof: ProofIndex(n)): n = n := match h: proof with {\n  | .base => Eq.refl(0)\n  | .step k child => match hc: child with {\n    | .base => Eq.refl(1)\n    | .step j grandchild =>\n      congrArg(Nat.succ, congrArg(Nat.succ, predicateIndex(j, grandchild)))\n  }\n}\ntheorem predicateIndexObserved:\n  predicateIndex(2, ProofIndex.step(1, ProofIndex.step(0, ProofIndex.base))) = Eq.refl(2) := by { rfl }\n"

private def registeredProofOpaqueLeanSource : String :=
  "inductive OpaquePredicate : Prop where\n  | base\n  | step (children : Nat → OpaquePredicate)\nopaque registeredProofOpaque (proof : OpaquePredicate) : True :=\n  match hp : proof with\n  | .base => True.intro\n  | .step children =>\n    match hc : children 1 with\n    | .base => True.intro\n    | .step grandchildren => registeredProofOpaque (grandchildren 1)\n"


private def registeredProofOpaquePsSource : String :=
  "inductive OpaquePredicate: Prop where {\n  | base\n  | step(children: Nat -> OpaquePredicate)\n}\nopaque registeredProofOpaque(proof: OpaquePredicate): True := match hp: proof with {\n  | .base => True.intro\n  | .step children => match hc: children(1) with {\n    | .base => True.intro\n    | .step grandchildren => registeredProofOpaque(grandchildren(1))\n  }\n}\n"


private def registeredProofAbbrevLeanSource : String :=
  "inductive AbbrevPredicate : Prop where\n  | base\n  | step (children : Nat → AbbrevPredicate)\nabbrev registeredProofAbbrev (proof : AbbrevPredicate) : True :=\n  match hp : proof with\n  | .base => True.intro\n  | .step children =>\n    match hc : children 1 with\n    | .base => True.intro\n    | .step grandchildren => registeredProofAbbrev (grandchildren 1)\n"


private def registeredProofAbbrevPsSource : String :=
  "inductive AbbrevPredicate: Prop where {\n  | base\n  | step(children: Nat -> AbbrevPredicate)\n}\nabbrev registeredProofAbbrev(proof: AbbrevPredicate): True := match hp: proof with {\n  | .base => True.intro\n  | .step children => match hc: children(1) with {\n    | .base => True.intro\n    | .step grandchildren => registeredProofAbbrev(grandchildren(1))\n  }\n}\n"


private def registeredProofInstanceLeanSource : String :=
  "inductive InstancePredicate : Prop where\n  | base\n  | step (children : Nat → InstancePredicate)\nclass PredicateWitness (proof : InstancePredicate) : Prop where\n  value : True\ninstance registeredProofInstance (proof : InstancePredicate) : PredicateWitness proof where\n  value := match hp : proof with\n    | .base => True.intro\n    | .step children =>\n      match hc : children 1 with\n      | .base => True.intro\n      | .step grandchildren =>\n        @PredicateWitness.value (grandchildren 1)\n          (registeredProofInstance (grandchildren 1))\n"


private def registeredProofInstancePsSource : String :=
  "inductive InstancePredicate: Prop where {\n  | base\n  | step(children: Nat -> InstancePredicate)\n}\nclass PredicateWitness(proof: InstancePredicate): Prop where {\n  value: True\n}\ninstance registeredProofInstance(proof: InstancePredicate): PredicateWitness(proof) where {\n  value := match hp: proof with {\n    | .base => True.intro\n    | .step children => match hc: children(1) with {\n      | .base => True.intro\n      | .step grandchildren => @PredicateWitness.value(grandchildren(1), registeredProofInstance(grandchildren(1)))\n    }\n  }\n}\n"


private def registeredProofDefaultLeanSource : String :=
  "inductive DefaultPredicate : Prop where\n  | base\n  | step (children : Nat → DefaultPredicate)\nclass DefaultPredicateWitness (proof : DefaultPredicate) : Prop where\n  value : True\n@[default_instance 200]\ninstance registeredProofDefault (proof : DefaultPredicate) : DefaultPredicateWitness proof where\n  value := match hp : proof with\n    | .base => True.intro\n    | .step children =>\n      match hc : children 1 with\n      | .base => True.intro\n      | .step grandchildren =>\n        @DefaultPredicateWitness.value (grandchildren 1)\n          (registeredProofDefault (grandchildren 1))\n"


private def registeredProofDefaultPsSource : String :=
  "inductive DefaultPredicate: Prop where {\n  | base\n  | step(children: Nat -> DefaultPredicate)\n}\nclass DefaultPredicateWitness(proof: DefaultPredicate): Prop where {\n  value: True\n}\n@[default_instance 200]\ninstance registeredProofDefault(proof: DefaultPredicate): DefaultPredicateWitness(proof) where {\n  value := match hp: proof with {\n    | .base => True.intro\n    | .step children => match hc: children(1) with {\n      | .base => True.intro\n      | .step grandchildren => @DefaultPredicateWitness.value(grandchildren(1), registeredProofDefault(grandchildren(1)))\n    }\n  }\n}\n"

private def indexedDerivingLeanSource : String :=
  "universe indexedU\n\ninductive IndexedPayload (A : Type indexedU) : Nat → Type indexedU where\n  | left (index : Nat) (value : A) : IndexedPayload A index\n  | right (index : Nat) (value : A) : IndexedPayload A index\n  | next (index : Nat) (value : A) (child : IndexedPayload A index) :\n      IndexedPayload A (Nat.succ index)\n  deriving BEq, DecidableEq\n\ndef indexedOriginal : IndexedPayload Bool 1 :=\n  IndexedPayload.next 0 true (IndexedPayload.left 0 false)\ndef indexedFieldChanged : IndexedPayload Bool 1 :=\n  IndexedPayload.next 0 false (IndexedPayload.left 0 false)\ndef indexedChildChanged : IndexedPayload Bool 1 :=\n  IndexedPayload.next 0 true (IndexedPayload.left 0 true)\ndef indexedCtorChanged : IndexedPayload Bool 1 :=\n  IndexedPayload.next 0 true (IndexedPayload.right 0 false)\ndef indexedMajorChanged : IndexedPayload Bool 1 := IndexedPayload.right 1 true\n\ntheorem indexedBEqSame : (indexedOriginal == indexedOriginal) = true := by rfl\ntheorem indexedBEqField : (indexedOriginal == indexedFieldChanged) = false := by rfl\ntheorem indexedBEqChild : (indexedOriginal == indexedChildChanged) = false := by rfl\ntheorem indexedBEqCtor : (indexedOriginal == indexedCtorChanged) = false := by rfl\ntheorem indexedBEqMajor : (indexedOriginal == indexedMajorChanged) = false := by rfl\ntheorem indexedDecEqSame :\n    Decidable.decide (self := decEq indexedOriginal indexedOriginal) = true := by rfl\ntheorem indexedDecEqField :\n    Decidable.decide (self := decEq indexedOriginal indexedFieldChanged) = false := by rfl\ntheorem indexedDecEqChild :\n    Decidable.decide (self := decEq indexedOriginal indexedChildChanged) = false := by rfl\ntheorem indexedDecEqCtor :\n    Decidable.decide (self := decEq indexedOriginal indexedCtorChanged) = false := by rfl\ntheorem indexedDecEqMajor :\n    Decidable.decide (self := decEq indexedOriginal indexedMajorChanged) = false := by rfl\n\ninductive IndexedAtom where\n  | atom (value : Bool)\ninstance indexedAtomBEq : BEq IndexedAtom where\n  beq (_left : IndexedAtom) (_right : IndexedAtom) : Bool := false\ntheorem indexedBEqUsesActualDictionary :\n    (IndexedPayload.left 0 (IndexedAtom.atom true) ==\n      IndexedPayload.left 0 (IndexedAtom.atom true)) = false := by rfl\n\ninductive IndexedErasedDependency : Nat → Type where\n  | intro (value : Nat) :\n      IndexedErasedDependency ((fun (_ : Nat) => 0) value)\n  deriving BEq, DecidableEq\ntheorem indexedBetaFieldBEq :\n    (IndexedErasedDependency.intro 1 == IndexedErasedDependency.intro 2) = false := by rfl\ntheorem indexedBetaFieldDecEq :\n    Decidable.decide (self := decEq (IndexedErasedDependency.intro 1)\n      (IndexedErasedDependency.intro 2)) = false := by rfl\n\ninductive IndexedDependent : Nat → Type where\n  | wrap (index : Nat) (child : IndexedPayload Bool index) : IndexedDependent 0\n  deriving DecidableEq\ntheorem indexedDependentSame :\n    Decidable.decide (self := decEq (IndexedDependent.wrap 1 indexedOriginal)\n      (IndexedDependent.wrap 1 indexedOriginal)) = true := by rfl\ntheorem indexedDependentChild :\n    Decidable.decide (self := decEq (IndexedDependent.wrap 1 indexedOriginal)\n      (IndexedDependent.wrap 1 indexedChildChanged)) = false := by rfl\ntheorem indexedDependentIndex :\n    Decidable.decide (self := decEq\n      (IndexedDependent.wrap 0 (IndexedPayload.left 0 true))\n      (IndexedDependent.wrap 1 indexedOriginal)) = false := by rfl\n"

private def indexedDerivingPsSource : String :=
  "universe indexedU\n\ninductive IndexedPayload(A: Type indexedU): Nat -> Type indexedU where {\n  | left(index: Nat, value: A): IndexedPayload(A, index)\n  | right(index: Nat, value: A): IndexedPayload(A, index)\n  | next(index: Nat, value: A, child: IndexedPayload(A, index)):\n      IndexedPayload(A, Nat.succ(index))\n} deriving BEq, DecidableEq\n\nconst indexedOriginal: IndexedPayload(Bool, 1) :=\n  IndexedPayload.next(0, true, IndexedPayload.left(0, false))\nconst indexedFieldChanged: IndexedPayload(Bool, 1) :=\n  IndexedPayload.next(0, false, IndexedPayload.left(0, false))\nconst indexedChildChanged: IndexedPayload(Bool, 1) :=\n  IndexedPayload.next(0, true, IndexedPayload.left(0, true))\nconst indexedCtorChanged: IndexedPayload(Bool, 1) :=\n  IndexedPayload.next(0, true, IndexedPayload.right(0, false))\nconst indexedMajorChanged: IndexedPayload(Bool, 1) := IndexedPayload.right(1, true)\n\ntheorem indexedBEqSame: (indexedOriginal == indexedOriginal) = true := by { rfl }\ntheorem indexedBEqField: (indexedOriginal == indexedFieldChanged) = false := by { rfl }\ntheorem indexedBEqChild: (indexedOriginal == indexedChildChanged) = false := by { rfl }\ntheorem indexedBEqCtor: (indexedOriginal == indexedCtorChanged) = false := by { rfl }\ntheorem indexedBEqMajor: (indexedOriginal == indexedMajorChanged) = false := by { rfl }\ntheorem indexedDecEqSame:\n  Decidable.decide(self := decEq(indexedOriginal, indexedOriginal)) = true := by { rfl }\ntheorem indexedDecEqField:\n  Decidable.decide(self := decEq(indexedOriginal, indexedFieldChanged)) = false := by { rfl }\ntheorem indexedDecEqChild:\n  Decidable.decide(self := decEq(indexedOriginal, indexedChildChanged)) = false := by { rfl }\ntheorem indexedDecEqCtor:\n  Decidable.decide(self := decEq(indexedOriginal, indexedCtorChanged)) = false := by { rfl }\ntheorem indexedDecEqMajor:\n  Decidable.decide(self := decEq(indexedOriginal, indexedMajorChanged)) = false := by { rfl }\n\ninductive IndexedAtom where { | atom(value: Bool) }\ninstance indexedAtomBEq: BEq IndexedAtom where {\n  beq(_left: IndexedAtom, _right: IndexedAtom): Bool := false\n}\ntheorem indexedBEqUsesActualDictionary:\n  (IndexedPayload.left(0, IndexedAtom.atom(true)) ==\n    IndexedPayload.left(0, IndexedAtom.atom(true))) = false := by { rfl }\n\ninductive IndexedErasedDependency: Nat -> Type where {\n  | intro(value: Nat): IndexedErasedDependency((fun (_: Nat) => 0)(value))\n} deriving BEq, DecidableEq\ntheorem indexedBetaFieldBEq:\n  (IndexedErasedDependency.intro(1) == IndexedErasedDependency.intro(2)) = false := by { rfl }\ntheorem indexedBetaFieldDecEq:\n  Decidable.decide(self := decEq(IndexedErasedDependency.intro(1),\n    IndexedErasedDependency.intro(2))) = false := by { rfl }\n\ninductive IndexedDependent: Nat -> Type where {\n  | wrap(index: Nat, child: IndexedPayload(Bool, index)): IndexedDependent(0)\n} deriving DecidableEq\ntheorem indexedDependentSame:\n  Decidable.decide(self := decEq(IndexedDependent.wrap(1, indexedOriginal),\n    IndexedDependent.wrap(1, indexedOriginal))) = true := by { rfl }\ntheorem indexedDependentChild:\n  Decidable.decide(self := decEq(IndexedDependent.wrap(1, indexedOriginal),\n    IndexedDependent.wrap(1, indexedChildChanged))) = false := by { rfl }\ntheorem indexedDependentIndex:\n  Decidable.decide(self := decEq(\n    IndexedDependent.wrap(0, IndexedPayload.left(0, true)),\n    IndexedDependent.wrap(1, indexedOriginal))) = false := by { rfl }\n"

private def parserLayoutLeanSource : String :=
  "def layoutCombine (left right : Nat) : Nat := Nat.add left right\ndef layoutAccept (value : Nat) : Nat := value\n\ndef layoutNamed : Nat := layoutAccept (value := layoutCombine 1\n2)\ndef layoutParen : Nat := (layoutCombine 4\n5)\ndef layoutAscribed : Nat := (layoutCombine 6\n7 : Nat)\ndef layoutTuple : Nat × Nat := (layoutCombine 6\n7, layoutCombine 8\n9)\ndef layoutNested : Nat := layoutAccept (value := layoutAccept (value := layoutCombine 10\n11))\ndef layoutLambda : Nat := ((fun (n : Nat) => layoutCombine n\n12) 13)\ndef layoutLet : Nat := (let saved := layoutCombine 1 2\nsaved)\ndef layoutDo : Option Nat := (do\n  let saved := layoutCombine 1 2\n  return saved)\n\ntheorem layoutNamedObserved : layoutNamed = 3 := by rfl\ntheorem layoutParenObserved : layoutParen = 9 := by rfl\ntheorem layoutAscribedObserved : layoutAscribed = 13 := by rfl\ntheorem layoutTupleObserved : layoutTuple = (13, 17) := by rfl\ntheorem layoutNestedObserved : layoutNested = 21 := by rfl\ntheorem layoutLambdaObserved : layoutLambda = 25 := by rfl\ntheorem layoutLetObserved : layoutLet = 3 := by rfl\ntheorem layoutDoObserved : layoutDo = Option.some 3 := by rfl\n"

private def parserLayoutPsSource : String :=
  "function layoutCombine(left: Nat, right: Nat): Nat := Nat.add(left, right)\nfunction layoutAccept(value: Nat): Nat := value\n\nconst layoutNamed: Nat := layoutAccept(value := layoutCombine(1, 2))\nconst layoutParen: Nat := (layoutCombine(4, 5))\nconst layoutAscribed: Nat := (layoutCombine(6, 7): Nat)\nconst layoutTuple: Nat × Nat := (layoutCombine(6, 7), layoutCombine(8, 9))\nconst layoutNested: Nat := layoutAccept(value := layoutAccept(value := layoutCombine(10, 11)))\nconst layoutLambda: Nat := (fun (n: Nat) => layoutCombine(n, 12))(13)\nconst layoutLet: Nat := let saved := layoutCombine(1, 2)\nsaved\nconst layoutDo: Option Nat := do {\n  let saved := layoutCombine(1, 2)\n  return saved\n}\n\ntheorem layoutNamedObserved: layoutNamed = 3 := by { rfl }\ntheorem layoutParenObserved: layoutParen = 9 := by { rfl }\ntheorem layoutAscribedObserved: layoutAscribed = 13 := by { rfl }\ntheorem layoutTupleObserved: layoutTuple = (13, 17) := by { rfl }\ntheorem layoutNestedObserved: layoutNested = 21 := by { rfl }\ntheorem layoutLambdaObserved: layoutLambda = 25 := by { rfl }\ntheorem layoutLetObserved: layoutLet = 3 := by { rfl }\ntheorem layoutDoObserved: layoutDo = Option.some(3) := by { rfl }\n"

private def checkedDeclarations (kind : PsCompilerSourceKind) (source : String) :
    Except String (List PsDeclaration) := do
  let program ← psCompilerParsePscv0 source kind
  let elaborated ← (psCompilerElaboratePscv0 program).mapError psCompilerPscv0Error
  return elaborated.declarations

private def compareCheckedValues (left right : List PsDeclaration) : IO Unit := do
  ensure (left.length == right.length) "source adapters changed the declaration count"
  for (left, right) in left.zip right do
    match left, right with
    | .definitionDecl ln ll lt lv, .definitionDecl rn rl rt rv
    | .theoremDecl ln ll lt lv, .theoremDecl rn rl rt rv
    | .opaqueDecl ln ll lt lv, .opaqueDecl rn rl rt rv
    | .partialDecl ln ll lt lv, .partialDecl rn rl rt rv =>
      ensure (psNameEq ln rn && psElabMutualLevelNamesEqual ll rl &&
        psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("source adapters changed checked value " ++ psNameToString ln)
    | .inductiveDecl l, .inductiveDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && l.numParams == r.numParams && l.numIndices == r.numIndices &&
        psElabMutualLevelNamesEqual l.constructors r.constructors && l.isStructure == r.isStructure)
        "source adapters changed an inductive family"
    | .constructorDecl l, .constructorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psNameEq l.inductiveName r.inductiveName &&
        l.constructorIndex == r.constructorIndex && l.numParams == r.numParams &&
        l.numFields == r.numFields && l.recursiveFields == r.recursiveFields)
        "source adapters changed constructor field metadata"
    | .recursorDecl l, .recursorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psElabMutualLevelNamesEqual l.inductiveNames r.inductiveNames &&
        l.numParams == r.numParams && l.numIndices == r.numIndices &&
        l.numMotives == r.numMotives && l.numMinors == r.numMinors)
        "source adapters changed a recursor telescope"
    | _, _ => throw (IO.userError "source adapters changed a checked declaration kind")

private def recursorMotiveTypeFailure : PsElabError → Bool
  | .atDeclaration _ cause => recursorMotiveTypeFailure cause
  | .atContext _ cause => recursorMotiveTypeFailure cause
  | .typeMismatch => true
  | _ => false

private def wfBoundaryLeanSource : String :=
  "structure WfBoundaryBox (n : Nat) where\n  value : Nat\n\ndef wfBoundaryMeasure (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  WfBoundaryBox.value p\n\ndef wfBoundaryPair (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  match n, p with\n  | 0, _ => 0\n  | Nat.succ k, WfBoundaryBox.mk 0 => 0\n  | Nat.succ k, WfBoundaryBox.mk (Nat.succ v) =>\n    Nat.succ (wfBoundaryPair k (WfBoundaryBox.mk v))\ntermination_by wfBoundaryMeasure n p\ndecreasing_by\n  exact Nat.lt_succ_self v\n\ndef wfBoundaryGeneralized (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k =>\n    match p with\n    | WfBoundaryBox.mk 0 => 0\n    | WfBoundaryBox.mk (Nat.succ v) =>\n      Nat.succ (wfBoundaryGeneralized k (WfBoundaryBox.mk v))\ntermination_by wfBoundaryMeasure n p\ndecreasing_by\n  exact Nat.lt_succ_self v\n\ndef wfBoundaryComputed (n : Nat) : Nat :=\n  match h : Nat.succ n with\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ (wfBoundaryComputed k)\ntermination_by Nat.succ n\ndecreasing_by\n  exact Eq.mpr (congrArg (fun (t : Nat) => Nat.lt (Nat.succ k) t) h)\n    (Nat.lt_succ_self (Nat.succ k))\n\ndef wfBoundaryUserRecursor (n : Nat) (impossible : n = n → False) : Nat :=\n  Nat.rec (motive := fun (_ : Nat) => Nat) 0\n    (fun (k : Nat) (ih : Nat) =>\n      wfBoundaryUserRecursor k (fun (_ : k = k) => impossible (Eq.refl n))) n\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n := False.elim (impossible (Eq.refl n))\n  exact original\n\ndef wfBoundaryCatchAll (n : Nat) (impossible : n = n → False) : Nat :=\n  match n with\n  | x => wfBoundaryCatchAll (Nat.succ x)\n      (fun (_ : Nat.succ x = Nat.succ x) => impossible (Eq.refl n))\ntermination_by n\ndecreasing_by\n  have original : Nat.lt (Nat.succ n) n := False.elim (impossible (Eq.refl n))\n  exact original\n\ndef m3wfboundaries (flag : Bool) : UInt64 :=\n  let n : Nat := if flag then 4 else 2\n  UInt64.ofNat (wfBoundaryPair n (WfBoundaryBox.mk 5) +\n    10 * wfBoundaryGeneralized n (WfBoundaryBox.mk 3) +\n    100 * wfBoundaryComputed n)\n"

private def wfBoundaryPsSource : String :=
  "structure WfBoundaryBox(n: Nat) where {\n  value: Nat\n}\n\nfunction wfBoundaryMeasure(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  WfBoundaryBox.value(p)\n\nfunction wfBoundaryPair(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  match n, p with {\n  | 0, _ => 0\n  | Nat.succ k, WfBoundaryBox.mk 0 => 0\n  | Nat.succ k, WfBoundaryBox.mk (Nat.succ v) =>\n    Nat.succ(wfBoundaryPair(k, WfBoundaryBox.mk(v)))\n  }\ntermination_by wfBoundaryMeasure(n, p)\ndecreasing_by by {\n  exact Nat.lt_succ_self(v)\n}\n\nfunction wfBoundaryGeneralized(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  match n with {\n  | 0 => 0\n  | Nat.succ k =>\n    match p with {\n    | WfBoundaryBox.mk 0 => 0\n    | WfBoundaryBox.mk (Nat.succ v) =>\n      Nat.succ(wfBoundaryGeneralized(k, WfBoundaryBox.mk(v)))\n    }\n  }\ntermination_by wfBoundaryMeasure(n, p)\ndecreasing_by by {\n  exact Nat.lt_succ_self(v)\n}\n\nfunction wfBoundaryComputed(n: Nat): Nat :=\n  match h: Nat.succ(n) with {\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ(wfBoundaryComputed(k))\n  }\ntermination_by Nat.succ(n)\ndecreasing_by by {\n  exact Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(Nat.succ(k), t), h),\n    Nat.lt_succ_self(Nat.succ(k)))\n}\n\nfunction wfBoundaryUserRecursor(n: Nat, impossible: n = n -> False): Nat :=\n  Nat.rec(0,\n    fun (k: Nat) (ih: Nat) => wfBoundaryUserRecursor(k,\n      fun (_: k = k) => impossible(Eq.refl(n))),\n    n, motive := fun (_: Nat) => Nat)\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := False.elim(impossible(Eq.refl(n)))\n  exact original\n}\n\nfunction wfBoundaryCatchAll(n: Nat, impossible: n = n -> False): Nat :=\n  match n with {\n  | x => wfBoundaryCatchAll(Nat.succ(x),\n      fun (_: Nat.succ(x) = Nat.succ(x)) => impossible(Eq.refl(n)))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(Nat.succ(n), n) := False.elim(impossible(Eq.refl(n)))\n  exact original\n}\n\nfunction m3wfboundaries(flag: Bool): UInt64 :=\n  let n: Nat := if (flag) { 4 } else { 2 }\n  UInt64.ofNat(wfBoundaryPair(n, WfBoundaryBox.mk(5)) +\n    10 * wfBoundaryGeneralized(n, WfBoundaryBox.mk(3)) +\n    100 * wfBoundaryComputed(n))\n"

private def constWfLeanSource : String :=
  "def wfConstReturned (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k => Nat.succ (wfConstReturned k (Nat.succ bias))\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\n\ndef wfConstClosed : (n : Nat) → (proof : n = n → False) → Nat :=\n  fun (n : Nat) (proof : n = n → False) =>\n    wfConstClosed (Nat.succ n)\n      (fun (_ : Nat.succ n = Nat.succ n) => proof (Eq.refl n))\ntermination_by 0\ndecreasing_by\n  have original : Nat.lt 0 0 := False.elim (proof (Eq.refl n))\n  exact original\n\ntheorem wfConstReturnedSource (n : Nat) :\n    wfConstReturned n = (fun (bias : Nat) => match h : n with\n      | 0 => bias\n      | Nat.succ k => Nat.succ (wfConstReturned k (Nat.succ bias))) :=\n  wfConstReturned.eq_def n\n\ntheorem wfConstClosedSource :\n    wfConstClosed = (fun (n : Nat) (proof : n = n → False) =>\n      wfConstClosed (Nat.succ n)\n        (fun (_ : Nat.succ n = Nat.succ n) => proof (Eq.refl n))) :=\n  wfConstClosed.eq_def\n\ndef wfConstRetained (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k =>\n      let step := wfConstRetained k\n      Nat.succ (step (Nat.succ bias))\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\n\nmutual\ndef wfConstMutualLeft (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k => Nat.succ (wfConstMutualRight k (Nat.succ bias))\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\n\ndef wfConstMutualRight (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k =>\n      let step := wfConstMutualLeft k\n      Nat.succ (step (Nat.succ bias))\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\nend\n\ntheorem wfConstMutualSource (n : Nat) :\n    wfConstMutualLeft n = (fun (bias : Nat) => match h : n with\n      | 0 => bias\n      | Nat.succ k => Nat.succ (wfConstMutualRight k (Nat.succ bias))) :=\n  wfConstMutualLeft.eq_def n\n\nmutual\ndef wfConstFixedLeft (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k => Nat.succ (wfConstFixedRight k bias)\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\n\ndef wfConstFixedRight (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) =>\n    match h : n with\n    | 0 => bias\n    | Nat.succ k => Nat.succ (wfConstFixedLeft k bias)\ntermination_by n\ndecreasing_by exact Nat.lt_succ_self k\nend\n\ndef m3constwf (flag : Bool) : UInt64 :=\n  let n := if flag then 4 else 2\n  let direct := wfConstReturned n 3\n  let retained := wfConstRetained n 3\n  let mutualResult := wfConstMutualLeft n 3\n  let fixedResult := wfConstFixedLeft (n + n) 3\n  UInt64.ofNat (if direct == retained && direct == mutualResult && direct == fixedResult\n    then direct else 0)\n"

private def constWfPsSource : String :=
  "function wfConstReturned(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k => Nat.succ(wfConstReturned(k, Nat.succ(bias)))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\n\nconst wfConstClosed: forall n : Nat, forall proof : (n = n -> False), Nat :=\n  fun (n: Nat) (proof: n = n -> False) =>\n    wfConstClosed(Nat.succ(n),\n      fun (_: Nat.succ(n) = Nat.succ(n)) => proof(Eq.refl(n)))\ntermination_by 0\ndecreasing_by by {\n  have original: Nat.lt(0, 0) := False.elim(proof(Eq.refl(n)))\n  exact original\n}\n\ntheorem wfConstReturnedSource(n: Nat):\n    wfConstReturned(n) = (fun (bias: Nat) => match h: n with {\n      | 0 => bias\n      | Nat.succ k => Nat.succ(wfConstReturned(k, Nat.succ(bias)))\n    }) := wfConstReturned.eq_def(n)\n\ntheorem wfConstClosedSource:\n    wfConstClosed = (fun (n: Nat) (proof: n = n -> False) =>\n      wfConstClosed(Nat.succ(n),\n        fun (_: Nat.succ(n) = Nat.succ(n)) => proof(Eq.refl(n)))) :=\n  wfConstClosed.eq_def\n\nfunction wfConstRetained(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k =>\n      let step := wfConstRetained(k)\n      Nat.succ(step(Nat.succ(bias)))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\n\nmutual\nfunction wfConstMutualLeft(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k => Nat.succ(wfConstMutualRight(k, Nat.succ(bias)))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\n\nfunction wfConstMutualRight(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k =>\n      let step := wfConstMutualLeft(k)\n      Nat.succ(step(Nat.succ(bias)))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\nend\n\ntheorem wfConstMutualSource(n: Nat):\n    wfConstMutualLeft(n) = (fun (bias: Nat) => match h: n with {\n      | 0 => bias\n      | Nat.succ k => Nat.succ(wfConstMutualRight(k, Nat.succ(bias)))\n    }) := wfConstMutualLeft.eq_def(n)\n\nmutual\nfunction wfConstFixedLeft(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k => Nat.succ(wfConstFixedRight(k, bias))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\n\nfunction wfConstFixedRight(n: Nat): Nat -> Nat :=\n  fun (bias: Nat) => match h: n with {\n    | 0 => bias\n    | Nat.succ k => Nat.succ(wfConstFixedLeft(k, bias))\n  }\ntermination_by n\ndecreasing_by by { exact Nat.lt_succ_self(k) }\nend\n\nfunction m3constwf(flag: Bool): UInt64 :=\n  let n := if (flag) { 4 } else { 2 }\n  let direct := wfConstReturned(n, 3)\n  let retained := wfConstRetained(n, 3)\n  let mutualResult := wfConstMutualLeft(n, 3)\n  let fixedResult := wfConstFixedLeft(n + n, 3)\n  UInt64.ofNat(if (direct == retained && direct == mutualResult && direct == fixedResult) {\n    direct\n  } else { 0 })\n"

private def wfSelectedPhaseFailure (phase : String) : PsElabError → Bool
  | .atDeclaration _ cause => wfSelectedPhaseFailure phase cause
  | .atContext label cause =>
    if label == "well-founded " ++ phase then !psElabErrorIsResource cause
    else wfSelectedPhaseFailure phase cause
  | _ => false

private def wfBoundaryDecreaseFailure : PsElabError → Bool
  | .atDeclaration _ cause => wfBoundaryDecreaseFailure cause
  | .atContext label cause =>
    if label == "well-founded decrease goals" then !psElabErrorIsResource cause
    else wfBoundaryDecreaseFailure cause
  | _ => false


private def matchPolicyTypeFailure : PsElabError → Bool
  | .atDeclaration _ cause => matchPolicyTypeFailure cause
  | .atContext _ cause => matchPolicyTypeFailure cause
  | .typeMismatch | .infer .applicationTypeMismatch | .infer .letTypeMismatch => true
  | _ => false

private def structuralRuleFailure (rule : String) : PsElabError → Bool
  | .atDeclaration _ cause => structuralRuleFailure rule cause
  | .atContext _ cause => structuralRuleFailure rule cause
  | .data message => message.startsWith ("PSCV0-MUTUAL-TOTAL: " ++ rule ++ ":")
  | _ => false

private def impossibleInstanceFailure : PsElabError → Bool
  | .atDeclaration _ cause => impossibleInstanceFailure cause
  | .atContext _ cause => impossibleInstanceFailure cause
  | .data message =>
    message == "instance has an argument that cannot be inferred from its result or instance premises"
  | _ => false

private def indexedDerivingDictionaryFailure : PsElabError → Bool
  | .atDeclaration _ cause => indexedDerivingDictionaryFailure cause
  | .atContext _ cause => indexedDerivingDictionaryFailure cause
  | .data message => message == "deriving field has no checked instance"
  | _ => false

private def checkIndependentSourcePair (label leanText psText : String) : IO Unit := do
  let native ← fromExcept ((checkedDeclarations .lean leanText).mapError (fun message => label ++ ": " ++ message))
  let proofscript ← fromExcept ((checkedDeclarations .proofScript psText).mapError
    (fun message => label ++ ": " ++ message))
  compareCheckedValues native proofscript
  for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    let elaborated ← fromExcept ((psCompilerElaboratePscv0 program).mapError psCompilerPscv0Error)
    let ir ← fromExcept ((psCompilerVerifiedIrFromElaborated elaborated).mapError psCompilerPscv0Error)
    let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions ir fun _ => pure ())

private def checkRegisteredPredicateMetadata (kind : PsCompilerSourceKind)
    (source name expectedKind : String) (className? : Option String := none)
    (defaultPriority? : Option Nat := none) : IO Unit := do
  let program ← fromExcept (psCompilerParsePscv0 source kind)
  let compiled ← fromExcept ((psElabProgramWithOrigins
    psSelfHostProdPreludeEnvironment program).mapError psCompilerPscv0ElabError)
  let declarations := compiled.result.declarations
  let environment := compiled.result.environment
  let sourceName := psRootName name
  let [owner] := compiled.origins.filter (fun origin =>
      origin.members.any (fun member => psNameEq member.name sourceName))
    | throw (IO.userError ("registered predicate lost its unique source origin: " ++ name))
  let owned := declarations.filter (fun declaration =>
    owner.members.any (fun member => psNameEq member.name (psDeclarationName declaration)))
  ensure (owned.length == owner.members.length)
    ("registered predicate origin has missing or duplicate declarations: " ++ name)
  let [declaration] := owned.filter (fun declaration =>
      psNameEq (psDeclarationName declaration) sourceName)
    | throw (IO.userError ("registered predicate source name is not unique: " ++ name))
  ensure (match declaration with
    | .opaqueDecl .. => expectedKind == "opaque"
    | .definitionDecl .. => expectedKind == "abbrev"
    | .theoremDecl .. => expectedKind == "instance" || expectedKind == "default"
    | _ => false) ("registered predicate changed its native declaration kind: " ++ name)
  let helpers := owned.filter (fun declaration =>
    !psNameEq (psDeclarationName declaration) sourceName)
  ensure (!helpers.isEmpty && helpers.all (fun declaration =>
    match declaration with
    | .inductiveDecl .. | .constructorDecl .. | .recursorDecl .. => true
    | _ => false)) ("registered predicate lost its exact structural helper group: " ++ name)
  let families := helpers.filterMap fun declaration =>
    match declaration with | .inductiveDecl family => some family | _ => none
  ensure (!families.isEmpty)
    ("registered predicate has no checked logical helper family: " ++ name)
  for family in families do
    let level ← fromExcept ((psInductiveResultLevel environment family).mapError
      (fun error => psCompilerPscv0ElabError (.infer error)))
    ensure (psLevelEquivalent level .zero)
      ("registered predicate helper left Prop: " ++ psNameToString family.name)
  ensure (helpers.all (fun declaration =>
    compiled.privateNames.any (psNameEq (psDeclarationName declaration))) &&
    !(compiled.privateNames.any (psNameEq sourceName)))
    ("registered predicate changed helper/source privacy: " ++ name)
  ensure (!(declarations.any (fun declaration =>
    psNameEq (psDeclarationName declaration) (psNameAppendStr sourceName "eq_def"))))
    ("registered predicate emitted an unowned source equation: " ++ name)
  if expectedKind == "abbrev" then
    ensure (match psEnvironmentReducibility environment sourceName with
      | .reducible => true
      | _ => false) "registered predicate abbrev lost reducibility"
  let entryNamed := fun (entry : PsInstanceEntry) =>
    match (psExprAppView entry.value).head with
    | .constE actual _ => psNameEq actual sourceName
    | _ => false
  let ordinary := environment.instances.entries.filter entryNamed
  let defaults := environment.instances.defaults.filter entryNamed
  match className? with
  | none =>
    ensure (ordinary.isEmpty && defaults.isEmpty)
      ("registered predicate acquired an unrequested instance registration: " ++ name)
  | some className =>
    let className := psRootName className
    ensure ((environment.classes.filter (psNameEq className)).length == 1 &&
      ordinary.length == 1 && ordinary.all (fun entry =>
        entry.priority == 1000 && entry.className.any (psNameEq className)))
      ("registered predicate ordinary class/instance metadata changed: " ++ name)
    match defaultPriority? with
    | none =>
      ensure defaults.isEmpty
        ("ordinary predicate instance entered the default registry: " ++ name)
    | some priority =>
      ensure (defaults.length == 1 && defaults.all (fun entry =>
        entry.priority == priority && entry.className.any (psNameEq className)))
        ("registered predicate default-instance metadata changed: " ++ name)

def check (root : System.FilePath) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "input parity requires pinned Lean4.35.0"
  checkCoreBoundaryControls
  checkIndependentSourcePair "scoped parenthesis and named-value layout"
    parserLayoutLeanSource parserLayoutPsSource
  for (label, source) in M3InputParityOracle.parserLayoutRefusals do
    match psCompilerParsePscv0 source .lean with
    | .error error =>
      ensure (error.startsWith "PSCV0-PARSE:")
        (label ++ " refused outside the selected parser: " ++ error)
    | .ok _ => throw (IO.userError (label ++ " escaped its parser boundary"))
  checkIndependentSourcePair "indexed binary deriving"
    indexedDerivingLeanSource indexedDerivingPsSource
  for (label, leanText, psText) in [
      ("indexed BEq dictionary",
        "inductive IndexedMissingBEq : Nat → Type where\n  | intro (index : Nat) (value : Nat → Nat) : IndexedMissingBEq index\n  deriving BEq\n",
        "inductive IndexedMissingBEq: Nat -> Type where { | intro(index: Nat, value: Nat -> Nat): IndexedMissingBEq(index) } deriving BEq\n"),
      ("indexed DecidableEq dictionary",
        "inductive IndexedMissingDecEq : Nat → Type where\n  | intro (index : Nat) (value : Nat → Nat) : IndexedMissingDecEq index\n  deriving DecidableEq\n",
        "inductive IndexedMissingDecEq: Nat -> Type where { | intro(index: Nat, value: Nat -> Nat): IndexedMissingDecEq(index) } deriving DecidableEq\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (indexedDerivingDictionaryFailure cause)
          (label ++ " refused at the wrong owner: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " escaped elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " fabricated a field dictionary"))
  checkIndependentSourcePair "impossible instance family prefix"
    "class UnindexedRegistration where\n  value : Nat\n" "class UnindexedRegistration where {\n  value: Nat\n}\n"
  for (label, leanText, psText) in [
      ("impossibleRegistration",
        "class UnindexedRegistration where\n  value : Nat\ninstance impossibleRegistration (n : Nat) : UnindexedRegistration where\n  value := n\n",
        "class UnindexedRegistration where {\n  value: Nat\n}\ninstance impossibleRegistration(n: Nat): UnindexedRegistration where {\n  value := n\n}\n"),
      ("impossibleDefaultRegistration",
        "class UnindexedRegistration where\n  value : Nat\n@[default_instance 200]\ninstance impossibleDefaultRegistration (n : Nat) : UnindexedRegistration where\n  value := n\n",
        "class UnindexedRegistration where {\n  value: Nat\n}\n@[default_instance 200]\ninstance impossibleDefaultRegistration(n: Nat): UnindexedRegistration where {\n  value := n\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (impossibleInstanceFailure cause)
          (label ++ " lost its instance inferability refusal: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " registered an uninferable argument"))
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "inductive InlineBranch where\n  | node (children : Bool → List InlineBranch)\ndef inlineFunctionContainerRefusal (tree : InlineBranch) : Nat :=\n  match h : tree with\n  | .node children =>\n    match hc : children true with\n    | [] => 0\n    | [t] => Nat.succ (inlineFunctionContainerRefusal t)\n    | _ => 0\n"),
      (.proofScript, "inductive InlineBranch where {\n  | node(children: Bool -> List(InlineBranch))\n}\nfunction inlineFunctionContainerRefusal(tree: InlineBranch): Nat := match h: tree with {\n  | .node children => match hc: children(true) with {\n    | [] => 0\n    | [t] => Nat.succ(inlineFunctionContainerRefusal(t))\n    | _ => 0\n  }\n}\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error (.elaboration cause) =>
      ensure (structuralRuleFailure "DECREASE" cause)
        ("inline function-container call lost its native reflexive-field refusal: " ++
          psCompilerPscv0ElabError cause)
    | .error error =>
      throw (IO.userError ("inline function-container call failed outside elaboration: " ++
        psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError "inline function-container call invented a reflexive-field argument")
  ensure ((M3InputParityOracle.m3wfboundaries false).toNat == 222 &&
      (M3InputParityOracle.m3wfboundaries true).toNat == 434)
    "native whole-match WF boundary observations changed"
  checkIndependentSourcePair "opaque predicate registration"
    registeredProofOpaqueLeanSource registeredProofOpaquePsSource
  for (kind, source) in [(PsCompilerSourceKind.lean, registeredProofOpaqueLeanSource),
      (.proofScript, registeredProofOpaquePsSource)] do
    checkRegisteredPredicateMetadata kind source "registeredProofOpaque" "opaque"
  checkIndependentSourcePair "abbrev predicate registration"
    registeredProofAbbrevLeanSource registeredProofAbbrevPsSource
  for (kind, source) in [(PsCompilerSourceKind.lean, registeredProofAbbrevLeanSource),
      (.proofScript, registeredProofAbbrevPsSource)] do
    checkRegisteredPredicateMetadata kind source "registeredProofAbbrev" "abbrev"
  checkIndependentSourcePair "proof instance registration"
    registeredProofInstanceLeanSource registeredProofInstancePsSource
  for (kind, source) in [(PsCompilerSourceKind.lean, registeredProofInstanceLeanSource),
      (.proofScript, registeredProofInstancePsSource)] do
    checkRegisteredPredicateMetadata kind source "registeredProofInstance" "instance" (some "PredicateWitness")
  checkIndependentSourcePair "proof instance registration synthesis use"
    (registeredProofInstanceLeanSource ++ "theorem registeredProofUse (proof : InstancePredicate) : PredicateWitness proof := inferInstance\n")
    (registeredProofInstancePsSource ++ "theorem registeredProofUse(proof: InstancePredicate): PredicateWitness(proof) := inferInstance\n")
  checkIndependentSourcePair "proof default instance registration"
    registeredProofDefaultLeanSource registeredProofDefaultPsSource
  for (kind, source) in [(PsCompilerSourceKind.lean, registeredProofDefaultLeanSource),
      (.proofScript, registeredProofDefaultPsSource)] do
    checkRegisteredPredicateMetadata kind source "registeredProofDefault" "default" (some "DefaultPredicateWitness") (some 200)
  checkIndependentSourcePair "proof default instance registration synthesis use"
    (registeredProofDefaultLeanSource ++ "theorem registeredProofDefaultUse (proof : DefaultPredicate) : DefaultPredicateWitness proof := inferInstance\n")
    (registeredProofDefaultPsSource ++ "theorem registeredProofDefaultUse(proof: DefaultPredicate): DefaultPredicateWitness(proof) := inferInstance\n")
  checkIndependentSourcePair "whole-match well-founded boundaries"
    wfBoundaryLeanSource wfBoundaryPsSource
  for (label, leanText, psText) in [
      ("computed discriminator",
        "def wfBoundaryComputedRefusal (n : Nat) : Nat :=\n  match h : Nat.succ n with\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ (wfBoundaryComputedRefusal k)\ntermination_by Nat.succ n\ndecreasing_by\n  exact Nat.lt_succ_self (Nat.succ k)\n",
        "function wfBoundaryComputedRefusal(n: Nat): Nat :=\n  match h: Nat.succ(n) with {\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ(wfBoundaryComputedRefusal(k))\n  }\ntermination_by Nat.succ(n)\ndecreasing_by by {\n  exact Nat.lt_succ_self(Nat.succ(k))\n}\n"),
      ("ordinary user recursor",
        "def wfBoundaryUserRecursorRefusal (n : Nat) : Nat :=\n  Nat.rec (motive := fun (_ : Nat) => Nat) 0\n    (fun (k : Nat) (ih : Nat) => wfBoundaryUserRecursorRefusal k) n\ntermination_by n\ndecreasing_by\n  exact Nat.lt_succ_self k\n",
        "function wfBoundaryUserRecursorRefusal(n: Nat): Nat :=\n  Nat.rec(0, fun (k: Nat) (ih: Nat) => wfBoundaryUserRecursorRefusal(k), n,\n    motive := fun (_: Nat) => Nat)\ntermination_by n\ndecreasing_by by {\n  exact Nat.lt_succ_self(k)\n}\n"),
      ("mixed catch-all row",
        "def matchAuxPrev (n : Nat) : Nat := match n with\n  | 0 => 0\n  | Nat.succ k => k\n\ndef matchAuxCatchAll (n : Nat) : Nat :=\n  match n with\n  | 0 => 0\n  | x => Nat.succ (matchAuxCatchAll (matchAuxPrev x))\ntermination_by n\ndecreasing_by\n  exact Nat.lt_succ_self _\n",
        "function matchAuxPrev(n: Nat): Nat := match n with {\n  | 0 => 0\n  | Nat.succ k => k\n}\n\nfunction matchAuxCatchAll(n: Nat): Nat := match n with {\n  | 0 => 0\n  | x => Nat.succ(matchAuxCatchAll(matchAuxPrev(x)))\n}\ntermination_by n\ndecreasing_by by {\n  exact Nat.lt_succ_self(_)\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (wfBoundaryDecreaseFailure cause)
          (label ++ " lost its WF decrease refusal: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " accepted an unrefined decrease proof"))
  for (label, phase, leanText, psText) in [
      ("unrelated False is removed from decrease scope",
        "decrease goals",
        "def wfBoundaryUserRecursorCleanupRefusal (n : Nat) (impossible : False) : Nat :=\n  Nat.rec (motive := fun (_ : Nat) => Nat) 0\n    (fun (k : Nat) (ih : Nat) => wfBoundaryUserRecursorCleanupRefusal k impossible) n\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n := False.elim impossible\n  exact original\n",
        "function wfBoundaryUserRecursorCleanupRefusal(n: Nat, impossible: False): Nat :=\n  Nat.rec(0, fun (k: Nat) (ih: Nat) => wfBoundaryUserRecursorCleanupRefusal(k, impossible), n,\n    motive := fun (_: Nat) => Nat)\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := False.elim(impossible)\n  exact original\n}\n"),
      ("all-fixed catch-all has no WF source argument",
        "fixed parameters",
        "def wfBoundaryCatchAllFixedRefusal (n : Nat) (impossible : False) : Nat :=\n  match n with\n  | x => wfBoundaryCatchAllFixedRefusal x impossible\ntermination_by n\ndecreasing_by\n  have original : Nat.lt n n := False.elim impossible\n  exact original\n",
        "function wfBoundaryCatchAllFixedRefusal(n: Nat, impossible: False): Nat :=\n  match n with {\n  | x => wfBoundaryCatchAllFixedRefusal(x, impossible)\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(n, n) := False.elim(impossible)\n  exact original\n}\n"),
      ("bare measure cannot name a returned lambda binder",
        "measure",
        "def wfConstUnbound : Nat → Nat :=\n  fun (n : Nat) => wfConstUnbound (Nat.succ n)\ntermination_by n\n",
        "const wfConstUnbound: Nat -> Nat :=\n  fun (n: Nat) => wfConstUnbound(Nat.succ(n))\ntermination_by n\n"),
      ("closed measure retains its actual decrease goal",
        "decrease goals",
        "def wfConstConstantBad : Nat → Nat :=\n  fun (n : Nat) => wfConstConstantBad (Nat.succ n)\ntermination_by 0\ndecreasing_by exact Nat.lt_succ_self 0\n",
        "const wfConstConstantBad: Nat -> Nat :=\n  fun (n: Nat) => wfConstConstantBad(Nat.succ(n))\ntermination_by 0\ndecreasing_by by { exact Nat.lt_succ_self(0) }\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (wfSelectedPhaseFailure phase cause)
          (label ++ " lost its expected WF phase: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " was accepted"))
  checkIndependentSourcePair "function-valued well-founded source"
    constWfLeanSource constWfPsSource
  ensure ((M3InputParityOracle.m3constwf false).toNat == 7 &&
    (M3InputParityOracle.m3constwf true).toNat == 11)
    "native function-valued WF observations changed"
  checkIndependentSourcePair "plain predicate" predicatePlainLeanSource predicatePlainPsSource
  checkIndependentSourcePair "named predicate" predicateNamedLeanSource predicateNamedPsSource
  checkIndependentSourcePair "indexed predicate" predicateIndexLeanSource predicateIndexPsSource
  checkIndependentSourcePair "predicate refusal family prefix"
    "inductive RefusalPredicate : Prop where\n  | base\n  | step (children : Nat → RefusalPredicate)\ninductive RefusalResult : Prop where\n  | base\n  | combine (left right : RefusalResult)\n"
    "inductive RefusalPredicate: Prop where {\n  | base\n  | step(children: Nat -> RefusalPredicate)\n}\ninductive RefusalResult: Prop where {\n  | base\n  | combine(left: RefusalResult, right: RefusalResult)\n}\n"
  for (label, leanText, psText) in [
      ("reconstructed predicate parent", "inductive RefusalPredicate : Prop where\n  | base\n  | step (children : Nat → RefusalPredicate)\ninductive RefusalResult : Prop where\n  | base\n  | combine (left right : RefusalResult)\ndef rejectedParent (proof : RefusalPredicate) : RefusalResult :=\n  match hp : proof with\n  | .base => RefusalResult.base\n  | .step children =>\n    match hc : children 1 with\n    | .base => RefusalResult.base\n    | .step grandchildren =>\n      RefusalResult.combine (rejectedParent (grandchildren 1))\n        (rejectedParent (RefusalPredicate.step children))\n",
        "inductive RefusalPredicate: Prop where {\n  | base\n  | step(children: Nat -> RefusalPredicate)\n}\ninductive RefusalResult: Prop where {\n  | base\n  | combine(left: RefusalResult, right: RefusalResult)\n}\nfunction rejectedParent(proof: RefusalPredicate): RefusalResult := match hp: proof with {\n  | .base => RefusalResult.base\n  | .step children => match hc: children(1) with {\n    | .base => RefusalResult.base\n    | .step grandchildren =>\n      RefusalResult.combine(rejectedParent(grandchildren(1)),\n        rejectedParent(RefusalPredicate.step(children)))\n  }\n}\n"),
      ("unrelated predicate parameter", "inductive RefusalPredicate : Prop where\n  | base\n  | step (children : Nat → RefusalPredicate)\ninductive RefusalResult : Prop where\n  | base\n  | combine (left right : RefusalResult)\ndef rejectedSpare (proof spare : RefusalPredicate) : RefusalResult :=\n  match hp : proof with\n  | .base => RefusalResult.base\n  | .step children =>\n    match hc : children 1 with\n    | .base => RefusalResult.base\n    | .step grandchildren =>\n      RefusalResult.combine (rejectedSpare (grandchildren 1) spare)\n        (rejectedSpare spare spare)\n",
        "inductive RefusalPredicate: Prop where {\n  | base\n  | step(children: Nat -> RefusalPredicate)\n}\ninductive RefusalResult: Prop where {\n  | base\n  | combine(left: RefusalResult, right: RefusalResult)\n}\nfunction rejectedSpare(proof: RefusalPredicate, spare: RefusalPredicate): RefusalResult := match hp: proof with {\n  | .base => RefusalResult.base\n  | .step children => match hc: children(1) with {\n    | .base => RefusalResult.base\n    | .step grandchildren =>\n      RefusalResult.combine(rejectedSpare(grandchildren(1), spare), rejectedSpare(spare, spare))\n  }\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (structuralRuleFailure "DECREASE" cause)
          ("predicate strict-child refusal changed ownership for " ++ label ++ ": " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError ("predicate strict-child refusal escaped elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ =>
        throw (IO.userError ("predicate recursion accepted a nonchild: " ++ label))
  let native ← fromExcept (checkedDeclarations .lean leanSource)
  let proofscript ← fromExcept (checkedDeclarations .proofScript psSource)
  compareCheckedValues native proofscript
  compareCheckedValues (← fromExcept (checkedDeclarations .lean controlLeanSource))
    (← fromExcept (checkedDeclarations .proofScript controlPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean mutualLeanSource))
    (← fromExcept (checkedDeclarations .proofScript mutualPsSource))
  -- Exercise total-only runtime admission independently of the combined
  -- ordinary P0/P1 host path used by the emitted paired module below.
  let totalProgram ← fromExcept (psCompilerParsePscv0 mutualLeanSource .lean)
  let totalElaborated ← fromExcept ((psCompilerElaboratePscv0 totalProgram).mapError psCompilerPscv0Error)
  let totalIr ← fromExcept ((psCompilerVerifiedIrFromElaborated totalElaborated).mapError psCompilerPscv0Error)
  let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions totalIr fun _ => pure ())
  compareCheckedValues (← fromExcept (checkedDeclarations .lean strategyLeanSource))
    (← fromExcept (checkedDeclarations .proofScript strategyPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean fieldsLeanSource))
    (← fromExcept (checkedDeclarations .proofScript fieldsPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean recursorLeanSource))
    (← fromExcept (checkedDeclarations .proofScript recursorPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean matchLeanSource))
    (← fromExcept (checkedDeclarations .proofScript matchPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean matchPolicyLeanSource))
    (← fromExcept (checkedDeclarations .proofScript matchPolicyPsSource))
  compareCheckedValues
    (← fromExcept (checkedDeclarations .lean matchLexicalLeanSource))
    (← fromExcept (checkedDeclarations .proofScript matchLexicalPsSource))
  compareCheckedValues
    (← fromExcept (checkedDeclarations .lean matchIndexedLeanSource))
    (← fromExcept (checkedDeclarations .proofScript matchIndexedPsSource))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean structuralLeanSource))
    (← fromExcept (checkedDeclarations .proofScript structuralPsSource))
  let structuralProgram ← fromExcept (psCompilerParsePscv0 structuralLeanSource .lean)
  let structuralElaborated ← fromExcept ((psCompilerElaboratePscv0 structuralProgram).mapError psCompilerPscv0Error)
  let structuralIr ← fromExcept ((psCompilerVerifiedIrFromElaborated structuralElaborated).mapError psCompilerPscv0Error)
  let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions structuralIr fun _ => pure ())
  compareCheckedValues (← fromExcept (checkedDeclarations .lean inlineLeanSource))
    (← fromExcept (checkedDeclarations .proofScript inlinePsSource))
  let inlineProgram ← fromExcept (psCompilerParsePscv0 inlineLeanSource .lean)
  let inlineElaborated ← fromExcept ((psCompilerElaboratePscv0 inlineProgram).mapError psCompilerPscv0Error)
  let inlineIr ← fromExcept ((psCompilerVerifiedIrFromElaborated inlineElaborated).mapError psCompilerPscv0Error)
  let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions inlineIr fun _ => pure ())
  for (label, leanText, psText) in [
      ("reconstructed parent after a valid nested child call",
        "inductive InlineRefusal where\n  | node (children : List InlineRefusal)\ndef inlineBad (tree : InlineRefusal) : Nat :=\n  match h : tree with\n  | .node [] => 0\n  | .node [child] => inlineBad child + inlineBad (InlineRefusal.node [child])\n  | .node _ => 0\n",
        "inductive InlineRefusal where {\n  | node(children: List(InlineRefusal))\n}\nfunction inlineBad(tree: InlineRefusal): Nat := match h: tree with {\n  | .node [] => 0\n  | .node [child] => inlineBad(child) + inlineBad(InlineRefusal.node([child]))\n  | .node _ => 0\n}\n"),
      ("unrelated header major after a valid nested child call",
        "inductive InlineRefusal where\n  | node (children : List InlineRefusal)\ndef inlineBad (tree spare : InlineRefusal) : Nat :=\n  match h : tree with\n  | .node [] => 0\n  | .node [child] => inlineBad child spare + inlineBad spare spare\n  | .node _ => 0\n",
        "inductive InlineRefusal where {\n  | node(children: List(InlineRefusal))\n}\nfunction inlineBad(tree: InlineRefusal, spare: InlineRefusal): Nat := match h: tree with {\n  | .node [] => 0\n  | .node [child] => inlineBad(child, spare) + inlineBad(spare, spare)\n  | .node _ => 0\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (structuralRuleFailure "DECREASE" cause)
          ("inline strict-child refusal changed ownership for " ++ label ++ ": " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError ("inline strict-child refusal escaped elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ =>
        throw (IO.userError ("inline recursion accepted a nonchild: " ++ label))
  compareCheckedValues (← fromExcept (checkedDeclarations .lean registeredLeanSource))
    (← fromExcept (checkedDeclarations .proofScript registeredPsSource))
  for (kind, source) in [(PsCompilerSourceKind.lean, registeredLeanSource),
      (.proofScript, registeredPsSource)] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    let elaborated ← fromExcept ((psCompilerElaboratePscv0 program).mapError psCompilerPscv0Error)
    let ir ← fromExcept ((psCompilerVerifiedIrFromElaborated elaborated).mapError psCompilerPscv0Error)
    let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions ir fun _ => pure ())
    let environment := elaborated.environment
    for name in ["RegisteredValue", "RegisteredDefault"] do
      ensure ((environment.classes.filter (psNameEq (psRootName name))).length == 1)
        ("recursive instance lost its unique class registration: " ++ name)
    ensure (match psEnvironmentReducibility environment (psRootName "registeredAbbrev") with
      | .reducible => true
      | _ => false) "recursive abbrev lost reducibility"
    let entryNamed := fun (name : String) (entry : PsInstanceEntry) =>
      match (psExprAppView entry.value).head with
      | .constE valueName _ => psNameEq valueName (psRootName name)
      | _ => false
    for (name, className) in [("registeredInstance", "RegisteredValue"),
        ("registeredDefault", "RegisteredDefault")] do
      let entries := environment.instances.entries.filter (entryNamed name)
      ensure (entries.length == 1 && entries.all (fun entry =>
        entry.priority == 1000 && entry.className.any (psNameEq (psRootName className))))
        ("recursive ordinary instance registration changed: " ++ name)
    let defaults := environment.instances.defaults.filter (entryNamed "registeredDefault")
    ensure (defaults.length == 1 && defaults.all (fun entry =>
      entry.priority == 200 &&
      entry.className.any (psNameEq (psRootName "RegisteredDefault"))))
      "recursive default instance registration changed"
    for name in ["registeredOpaque", "registeredAbbrev", "registeredInstance", "registeredDefault"] do
      let owned := elaborated.declarations.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) (psRootName name))
      ensure (owned.length == 1 && owned.all (fun declaration =>
        match declaration with
        | .opaqueDecl .. => name == "registeredOpaque"
        | .definitionDecl .. => name != "registeredOpaque"
        | _ => false)) ("registered recursive declaration changed its owned kind: " ++ name)
      ensure (!(elaborated.declarations.any (fun declaration =>
        psNameEq (psDeclarationName declaration) (psNameAppendStr (psRootName name) "eq_def"))))
        ("registered recursive declaration emitted an unowned equation: " ++ name)
    let collisionPrefix := (["registeredOpaque", "registeredAbbrev", "registeredInstance",
      "registeredDefault"].map fun name =>
        (match kind with | .lean => "def " | .proofScript => "const ") ++ name ++ ".eq_def : Nat := 73\n")
      |>.foldl (· ++ ·) ""
    let collision ← fromExcept (checkedDeclarations kind (collisionPrefix ++ source))
    for name in ["registeredOpaque", "registeredAbbrev", "registeredInstance", "registeredDefault"] do
      let equations := collision.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) (psNameAppendStr (psRootName name) "eq_def"))
      ensure (equations.length == 1 && equations.all (fun declaration =>
        psExprAlphaEq (psDeclarationType declaration) (.constE (psRootName "Nat") [])))
        ("registered owner reserved or replaced an existing source name: " ++ name)
  ensure (!(psCompilerParsePscv0
    "class RegisteredRefusal where { value: Nat }\ninstance invalid: RegisteredRefusal := RegisteredRefusal.mk(4)\n"
    .proofScript).isOk) "ProofScript instance accepted an unselected value-body grammar"
  for (label, leanText, psText) in [
      ("registeredOpaque rejects an unchanged major",
        "opaque registeredOpaque (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 2\n  | Nat.succ k => Nat.succ (registeredOpaque (Nat.succ k))\n",
        "opaque registeredOpaque(n: Nat): Nat := match h: n with {\n  | 0 => 2\n  | Nat.succ k => Nat.succ(registeredOpaque(Nat.succ(k)))\n}\n"),
      ("registeredAbbrev rejects an unchanged major",
        "abbrev registeredAbbrev (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 3\n  | Nat.succ k => Nat.succ (registeredAbbrev (Nat.succ k))\n",
        "abbrev registeredAbbrev(n: Nat): Nat := match h: n with {\n  | 0 => 3\n  | Nat.succ k => Nat.succ(registeredAbbrev(Nat.succ(k)))\n}\n"),
      ("registeredInstance rejects an unchanged major",
        "class RegisteredValue (n : Nat) where\n  value : Nat\ninstance registeredInstance (n : Nat) : RegisteredValue n where\n  value := match h : n with\n    | 0 => 4\n    | Nat.succ k => Nat.succ (@RegisteredValue.value (Nat.succ k)\n        (registeredInstance (Nat.succ k)))\n",
        "class RegisteredValue(n: Nat) where {\n  value: Nat\n}\ninstance registeredInstance(n: Nat): RegisteredValue(n) where {\n  value := match h: n with {\n    | 0 => 4\n    | Nat.succ k => Nat.succ(@RegisteredValue.value(Nat.succ(k), registeredInstance(Nat.succ(k))))\n  }\n}\n"),
      ("registeredDefault rejects an unchanged major",
        "class RegisteredDefault (n : Nat) where\n  value : Nat\n@[default_instance 200]\ninstance registeredDefault (n : Nat) : RegisteredDefault n where\n  value := match h : n with\n    | 0 => 5\n    | Nat.succ k => Nat.succ (@RegisteredDefault.value (Nat.succ k)\n        (registeredDefault (Nat.succ k)))\n",
        "class RegisteredDefault(n: Nat) where {\n  value: Nat\n}\n@[default_instance 200]\ninstance registeredDefault(n: Nat): RegisteredDefault(n) where {\n  value := match h: n with {\n    | 0 => 5\n    | Nat.succ k => Nat.succ(@RegisteredDefault.value(Nat.succ(k), registeredDefault(Nat.succ(k))))\n  }\n}\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (structuralRuleFailure "DECREASE" cause)
          ("registered recursion lost its checked decrease refusal for " ++ label ++ ": " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError ("registered decrease refusal escaped elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError ("registered recursion accepted a nondecreasing call: " ++ label))
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "def plain (n : Nat) : Nat := n\n"),
      (.proofScript, "function plain(n: Nat): Nat := n\n"),
      (.lean, "abbrev plain (n : Nat) : Nat := n\n"),
      (.proofScript, "abbrev plain (n: Nat): Nat := n\n")] do
    let declarations ← fromExcept (checkedDeclarations kind source)
    ensure (declarations.length == 1 &&
      declarations.all (fun declaration => psNameEq (psDeclarationName declaration) (psRootName "plain")))
      "plain nonrecursive or registered ownership changed its one-declaration contract"
  for (kind, rule, source) in [
      (PsCompilerSourceKind.lean, "DECREASE", "def bad (n : Nat) : Nat := match h : n with\n  | 0 => 0\n  | Nat.succ k => bad n\n"),
      (.proofScript, "DECREASE", "function bad(n: Nat): Nat := match h : n with { | 0 => 0 | Nat.succ k => bad(n) }\n"),
      (.lean, "DECREASE", "def bad (n : Nat) : Nat → Nat := fun (bias : Nat) => match h : n with\n  | 0 => bias\n  | Nat.succ k => bad (Nat.succ k) bias\n"),
      (.proofScript, "DECREASE", "function bad(n: Nat): Nat -> Nat := fun (bias: Nat) => match h : n with { | 0 => bias | Nat.succ k => bad(Nat.succ(k), bias) }\n"),
      (.lean, "FIXED-CALL", "def bad (A : Type) (rows : List (List A)) : Nat := match h : rows with\n  | .nil => 0\n  | .cons row rest => bad Bool List.nil\n"),
      (.proofScript, "FIXED-CALL", "function bad(A: Type, rows: List(List(A))): Nat := match h : rows with { | .nil => 0 | .cons row rest => bad(Bool, List.nil) }\n"),
      (.lean, "DECREASE", "inductive NestedRefusal where\n  | leaf\n  | node (children : List NestedRefusal)\nmutual\ndef bad (tree : NestedRefusal) : Nat := match h : tree with\n  | .leaf => 0\n  | .node children => badForest children\ndef badForest (children : List NestedRefusal) : Nat := match h : children with\n  | .nil => 0\n  | .cons child rest => bad (NestedRefusal.node (List.cons child List.nil)) + badForest rest\nend\n"),
      (.proofScript, "DECREASE", "inductive NestedRefusal where { | leaf | node(children: List(NestedRefusal)) }\nmutual\nfunction bad(tree: NestedRefusal): Nat := match h : tree with { | .leaf => 0 | .node children => badForest(children) }\nfunction badForest(children: List(NestedRefusal)): Nat := match h : children with { | .nil => 0 | .cons child rest => bad(NestedRefusal.node(List.cons(child, List.nil))) + badForest(rest) }\nend\n"),
      (.lean, "DECREASE", "inductive NestedRefusal where\n  | leaf\n  | node (children : List NestedRefusal)\nmutual\ndef bad (tree : NestedRefusal) : Nat := match h : tree with\n  | .leaf => 0\n  | .node children => badForest children\ndef badForest (children : List NestedRefusal) : Nat := match h : children with\n  | .nil => 0\n  | .cons child rest => bad child + badForest (List.cons child rest)\nend\n"),
      (.proofScript, "DECREASE", "inductive NestedRefusal where { | leaf | node(children: List(NestedRefusal)) }\nmutual\nfunction bad(tree: NestedRefusal): Nat := match h : tree with { | .leaf => 0 | .node children => badForest(children) }\nfunction badForest(children: List(NestedRefusal)): Nat := match h : children with { | .nil => 0 | .cons child rest => bad(child) + badForest(List.cons(child, rest)) }\nend\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error (.elaboration cause) =>
      ensure (structuralRuleFailure rule cause)
        ("named structural refusal changed phase or ownership: " ++ psCompilerPscv0ElabError cause)
    | .error error => throw (IO.userError ("named structural refusal escaped elaboration: " ++ psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError "named structural recursion accepted a nonchild or varying uniform dependency")
  for (label, leanText, psText) in [
      ("false keeps handlers at the original major",
        "def bad (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := false) a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n",
        "function bad(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := false) a with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n"),
      ("default generalizes handlers but preserves named equation originals",
        "def bad (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match h : a with\n  | true => h1 h\n  | false => h2 h\n",
        "function bad(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match h: a with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n"),
      ("true generalizes handlers but preserves named equation originals",
        "def bad (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := true) h : a with\n  | true => h1 h\n  | false => h2 h\n",
        "function bad(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := true) h: a with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n"),
      ("computed majors do not seed optional local generalization",
        "def bad (a : Bool) (h1 : Bool.not a = true → Nat) (h2 : Bool.not a = false → Nat) : Nat :=\n  match Bool.not a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n",
        "function bad(a: Bool, h1: Bool.not(a) = true -> Nat, h2: Bool.not(a) = false -> Nat): Nat :=\n  match Bool.not(a) with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n"),
      ("false does not repair a dependent result by optional binding",
        "theorem bad (a : Bool) (h : a = a) : h = h :=\n  match (generalizing := false) a with\n  | true => Eq.refl h\n  | false => Eq.refl h\n",
        "theorem bad(a: Bool, h: a = a): h = h :=\n  match (generalizing := false) a with {\n  | true => Eq.refl(h)\n  | false => Eq.refl(h)\n  }\n"),
      ("false remains false for mixed majors",
        "def bad (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := false) a, Bool.not a with\n  | true, false => h1 (Eq.refl true)\n  | false, true => h2 (Eq.refl false)\n  | _, _ => 0\n",
        "function bad(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := false) a, Bool.not(a) with {\n  | true, false => h1(Eq.refl(true))\n  | false, true => h2(Eq.refl(false))\n  | _, _ => 0\n  }\n"),
      ("unnamed discriminator preserves original b",
        "def bad (b : Bool) : Nat :=\n  match b with\n  | true => (fun (_ : b = true) => 37) (Eq.refl true)\n  | false => 41\n",
        "function bad(b: Bool): Nat :=\n  match b with {\n  | true => (fun (_: b = true) => 37)(Eq.refl(true))\n  | false => 41\n  }\n"),
      ("named equation shadows the same-name pattern",
        "def bad (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 0\n  | Nat.succ h => Nat.succ h\n",
        "function bad(n: Nat): Nat :=\n  match h: n with {\n  | 0 => 0\n  | Nat.succ h => Nat.succ(h)\n  }\n"),
      ("single variable match retains ordinary let generalization policy",
        "def bad (a : Bool) (handle : a = a → Nat) : Nat :=\n  match a with\n  | x =>\n    match x with\n    | true => handle (Eq.refl true)\n    | false => handle (Eq.refl false)\n",
        "function bad(a: Bool, handle: a = a -> Nat): Nat :=\n  match a with {\n  | x =>\n    match x with {\n    | true => handle(Eq.refl(true))\n    | false => handle(Eq.refl(false))\n    }\n  }\n"),
      ("nested false preserves the generalized outer binding",
        "def bad (a : Bool) (handle : a = a → Nat) : Nat :=\n  match (generalizing := true) a with\n  | x =>\n    match (generalizing := false) x with\n    | true => handle (Eq.refl true)\n    | false => handle (Eq.refl false)\n",
        "function bad(a: Bool, handle: a = a -> Nat): Nat :=\n  match (generalizing := true) a with {\n  | x =>\n    match (generalizing := false) x with {\n    | true => handle(Eq.refl(true))\n    | false => handle(Eq.refl(false))\n    }\n  }\n"),
      ("catch-all RHS keeps its pre-specialization pattern variable",
        "def bad (b : Bool) : Nat :=\n  match b with\n  | true => 0\n  | x =>\n    let h : x = false := Eq.refl false\n    1\n",
        "function bad(b: Bool): Nat :=\n  match b with {\n  | true => 0\n  | x =>\n    let h: x = false := Eq.refl(false)\n    1\n  }\n"),
      ("nested catch-all RHS keeps its pre-specialization field",
        "def bad (values : List Bool) : Nat :=\n  match values with\n  | List.cons true _ => 0\n  | List.cons x _ =>\n    let h : x = false := Eq.refl false\n    1\n  | List.nil => 0\n",
        "function bad(values: List(Bool)): Nat :=\n  match values with {\n  | List.cons true _ => 0\n  | List.cons x _ =>\n    let h: x = false := Eq.refl(false)\n    1\n  | List.nil => 0\n  }\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (matchPolicyTypeFailure cause)
          (label ++ " lost its type-checking refusal: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " was accepted"))
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "inductive Negative where\n  | wrap (f : Negative → Nat)\n"),
      (.proofScript, "inductive Negative where { | wrap(f: Negative -> Nat) }\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error error =>
      ensure (((psCompilerPscv0Error error).splitOn "recursive family occurs in a function-field domain").length > 1)
        "negative function-field occurrence lost its positivity diagnosis"
    | .ok _ => throw (IO.userError "negative function-field occurrence was admitted")
  let grouped := "def grouped {T : Type} {first value : T} := value\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean grouped))
    (← fromExcept (checkedDeclarations .proofScript grouped))
  let richLean := "universe u\ndef identity {A : Type u} (a : A) : A := a\n" ++
    "def choose (x y : Nat) (flag : Bool) : Nat := if flag then x + y else x\n" ++
    "def chosen : Nat := choose (flag := true) (y := 4) (x := 3)\n" ++
    "def scalar : Float := 1.25\n" ++
    "def doArgument : Option Nat := (fun (value : Option Nat) => value) do return 1\n" ++
    "def argumentOrder (x y z : Nat) : Nat := 100 * x + 10 * y + z\n" ++
    "def orderFirst : Nat := argumentOrder (y := 2) 1 3\n" ++
    "def orderSecond : Nat := argumentOrder 1 (x := 2) 3\n"
  let richPs := "universe u\nfunction identity{A: Type u}(a: A): A := a\n" ++
    "function choose(x: Nat, y: Nat, flag: Bool): Nat := if (flag) { x + y } else { x }\n" ++
    "const chosen: Nat := choose(flag := true, y := 4, x := 3)\n" ++
    "const scalar: Float := 1.25\n" ++
    "const doArgument: Option Nat := (fun (value: Option Nat) => value)(do { return 1 })\n" ++
    "function argumentOrder(x: Nat, y: Nat, z: Nat): Nat := 100 * x + 10 * y + z\n" ++
    "const orderFirst: Nat := argumentOrder(1, 2, 3)\n" ++
    "const orderSecond: Nat := argumentOrder(2, 1, 3)\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean richLean))
    (← fromExcept (checkedDeclarations .proofScript richPs))
  -- Positional-prefix placement is grammar-owned; overlap is telescope-owned.
  -- Keep both refusals and check their actual phase, not a weakened isError.
  match psCompilerParsePscv0
      "function order(x: Nat, y: Nat): Nat := x + y\nconst bad: Nat := order(y := 2, 1)\n"
      .proofScript with
  | .error error =>
    ensure (error.startsWith "PSCV0-PARSE: named argument after named argument")
      ("ProofScript placement lost its parser diagnosis: " ++ error)
  | .ok _ => throw (IO.userError "ProofScript parsed a positional argument after a named argument")
  let overlap ← fromExcept (psCompilerParsePscv0
    "function order(x: Nat, y: Nat): Nat := x + y\nconst bad: Nat := order(1, x := 2)\n" .proofScript)
  match psCompilerElaboratePscv0 overlap with
  | .error error =>
    ensure ((psCompilerPscv0Error error).startsWith
      "PSCV0-ARGUMENT: argument supplied both positionally and by name")
      ("ProofScript overlap lost its telescope diagnosis: " ++ psCompilerPscv0Error error)
  | .ok _ => throw (IO.userError "ProofScript accepted positional/name overlap")
  for source in [
      "def order (x y : Nat) : Nat := x + y\ndef bad : Nat := order (x := 1) (x := 2)\n",
      "def order (x y : Nat) : Nat := x + y\ndef bad : Nat := order (missing := 1) 2\n"] do
    let program ← fromExcept (psCompilerParsePscv0 source .lean)
    ensure (!(psCompilerElaboratePscv0 program).isOk)
      "native named-priority placement admitted duplicate or unknown names"
  -- The corrected public source surface has no private-motive alias.
  for (kind, source) in [
      (PsCompilerSourceKind.lean, "def bad (n : Nat) : Nat :=\n  Nat.rec (motive := fun (_ : Nat) => Nat) 3\n    (fun (k : Nat) (ih : Nat) => ih + k + 2) n\n    (_motive := fun (_ : Nat) => Nat)\n"),
      (.proofScript, "function bad(n: Nat): Nat :=\n  Nat.rec(3, fun (k: Nat) (ih: Nat) => ih + k + 2, n,\n    motive := fun (_: Nat) => Nat, _motive := fun (_: Nat) => Nat)\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error error =>
      ensure ((psCompilerPscv0Error error).startsWith "PSCV0-ARGUMENT: unknown named argument")
        ("recursor legacy motive lost its telescope diagnosis: " ++ psCompilerPscv0Error error)
    | .ok _ => throw (IO.userError "recursor accepted a legacy private-motive source alias")
  for (label, kind, source) in [
      ("Empty native omitted motive", PsCompilerSourceKind.lean,
        "theorem bad (value : Empty) : value = value := Empty.rec value\n"),
      ("Empty ProofScript omitted motive", .proofScript,
        "theorem bad(value: Empty): value = value := Empty.rec(value)\n"),
      ("False native omitted motive", .lean,
        "theorem bad (h : False) : h = h := False.rec h\n"),
      ("False ProofScript omitted motive", .proofScript,
        "theorem bad(h: False): h = h := False.rec(h)\n"),
      ("Nat native non-function motive", .lean,
        "def bad (n : Nat) : Nat := Nat.rec (motive := Nat) 3 (fun (k : Nat) (ih : Nat) => ih + k + 2) n\n"),
      ("Nat ProofScript non-function motive", .proofScript,
        "function bad(n: Nat): Nat := Nat.rec(3, fun (k: Nat) (ih: Nat) => ih + k + 2, n, motive := Nat)\n")] do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    match psCompilerElaboratePscv0 program with
    | .error (.elaboration cause) =>
      ensure (recursorMotiveTypeFailure cause)
        (label ++ " lost its motive type-checking refusal: " ++ psCompilerPscv0ElabError cause)
    | .error error =>
      throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError (label ++ " was accepted"))
  ensure (!(psCompilerParsePscv0 "def bad : Nat := Nat.succ(3)\n" .lean).isOk)
    "native application lost Lean's whitespace requirement"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean "section\nvariable (x y : Nat)\ndef selected := y\nend\n"))
    (← fromExcept (checkedDeclarations .proofScript "section\nvariable (x y: Nat)\nconst selected: Nat := y\nend\n"))
  -- Real input routing, not a host oracle or source-printer round trip.
  for (kind, wrong) in [(PsCompilerSourceKind.lean, psSource),
      (PsCompilerSourceKind.proofScript, leanSource)] do
    ensure (!(psCompilerParsePscv0 wrong kind).isOk)
      "source-kind selection silently accepted the other grammar"
  for source in ["axiom unapproved : Nat\n",
      "def f (n : Nat) : Nat := n\ntermination_by structural n\n",
      "def f (n : Nat) : Nat := n\npartial_fixpoint monotonicity by exact id\n"] do
    ensure (!(psCompilerParsePscv0 source .lean).isOk)
      "native source selection admitted an unselected declaration or strategy"
  for (kind, text) in [
      (PsCompilerSourceKind.lean, "def shadow {T : Type} {T value : T} := value\n"),
      (.proofScript, "def shadow {T : Type} {T value : T} := value\n"),
      (.lean, "def bad : (T : Type) -> T -> T -> T := fun (T : Type) (T value : T) => value\n"),
      (.lean, "section\nvariable (Nat value : Nat)\nend\n"),
      (.proofScript, "section\nvariable (Nat value: Nat)\nend\n"),
      (.proofScript, "const bad: forall (T: Type), T -> T -> T := fun (T: Type) (T value: T) => value\n")] do
    ensure (!(checkedDeclarations kind text).isOk)
      "binder annotation ignored native prefix shadowing"
  for source in [
      "def bad : Option Nat := do\n  let mut n := 0\n  return n\n",
      "def bad : Option Nat := do\n  if let .some n ← Option.some 1 then\n    return n\n  return 0\n",
      "def bad : Nat := if let .some n := Option.some 1 then n\n"] do
    ensure (!(psCompilerParsePscv0 source .lean).isOk)
      "native control admitted unselected mutation, monadic if-let or incomplete term if"
  let provider : PsPscv0ModuleSource := {
    name := "Library", sourceKind := .lean
    source := "def library (n : Nat) : Nat := Nat.succ n\n" }
  let project ← fromExcept (psPscv0ProjectParse [provider,
    { name := "Main", source := "import Library\nconst answer: Nat := library(3)\n" }])
  ensure ((project.map (·.sourceName)) == ["Library.lean", "Main.ps"])
    "mixed input module planning lost source-kind provenance"
  let request := fun kind source stem => ({
    sourceKind := kind, source, sourceName := stem ++ psCompilerSourceKindExtension kind
    outputStem := "inputparity", exports := .selected ["m3parity", "m3data", "m3control", "m3mutual", "m3strategies", "m3fields", "m3recursors", "m3matches", "m3structural", "m3inline", "m3registered", "m3const", "m3wfboundaries", "m3constwf"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] } : PsV7Native.Request)
  let requests := #[
    request .lean (constWfLeanSource ++ wfBoundaryLeanSource ++ predicatePlainLeanSource ++ predicateNamedLeanSource ++ predicateIndexLeanSource ++ inlineLeanSource ++ registeredLeanSource ++ structuralLeanSource ++ matchIndexedLeanSource ++ matchLexicalLeanSource ++ matchPolicyLeanSource ++ matchLeanSource ++ recursorLeanSource ++ fieldsLeanSource ++ dataLeanSource ++ controlLeanSource ++ mutualLeanSource ++ strategyLeanSource ++ leanSource ++ "theorem observed : m3parity true = 13 := by rfl\n") "native-input", request .proofScript (constWfPsSource ++ wfBoundaryPsSource ++ predicatePlainPsSource ++ predicateNamedPsSource ++ predicateIndexPsSource ++ inlinePsSource ++ registeredPsSource ++ structuralPsSource ++ matchIndexedPsSource ++ matchLexicalPsSource ++ matchPolicyPsSource ++ matchPsSource ++ recursorPsSource ++ fieldsPsSource ++ dataPsSource ++ controlPsSource ++ mutualPsSource ++ strategyPsSource ++ psSource ++ "theorem observed: m3parity(true) = 13 := by { rfl }\n") "proofscript-input",
    { sourceKind := .lean, source := "import Library\ndef answer : Nat := library 3\n"
      modules := [{ name := "Library", source := "function library(n: Nat): Nat := Nat.succ(n)\n" }] },
    { source := "import Library\nconst answer: Nat := library(3)\n", modules := [provider] },
    { sourceKind := .lean, source := leanSource, assurance := .closedVerified },
    { sourceKind := .lean, source :=
      "noncomputable def hidden (n : Nat) : Nat := n\ndef bad : Nat := hidden 3\n"
      targets := [.javascript] }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requests.size) "input parity omitted a requested result"
  for (result, index) in batch.results.toList.zipIdx do
    if index >= 4 then
      match result with
      | .error error =>
        ensure (error.phase == "assurance" && error.message.startsWith
          (if index == 4 then "PSCV0-ASSURANCE-DOWNGRADE:" else "PSCV0-NONCOMPUTABLE-EXEC:"))
          ("native input escaped assurance policy: " ++ error.message)
      | .ok _ => throw (IO.userError "native input acquired an unauthorized executable")
    else
      let result ← match result with
        | .ok result => pure result
        | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
      if index < 2 then
        ensure (result.artifacts.length == 5) "native input lost a selected backend"
        let directory := root / (if index == 0 then "lean" else "ps")
        IO.FS.createDirAll directory
        for artifact in result.artifacts do
          for file in artifact.files do
            match file.payload with
            | .text value => IO.FS.writeFile (directory / file.path) value
            | .binary value => IO.FS.writeBinFile (directory / file.path) value
        let rows := [false, true].map fun flag => Lean.Json.mkObj [
          ("flag", Lean.toJson flag),
          ("m3inline", Lean.toJson (toString (M3InputParityOracle.m3inline flag).toNat)),
          ("m3registered", Lean.toJson (toString (M3InputParityOracle.m3registered flag).toNat)),
          ("m3const", Lean.toJson (toString (M3InputParityOracle.m3const flag).toNat)),
          ("m3wfboundaries", Lean.toJson (toString (M3InputParityOracle.m3wfboundaries flag).toNat)),
          ("m3constwf", Lean.toJson (toString (M3InputParityOracle.m3constwf flag).toNat)),
          ("m3structural", Lean.toJson (toString (M3InputParityOracle.m3structural flag).toNat)),
          ("m3parity", Lean.toJson (toString (M3InputParityOracle.m3parity flag).toNat)),
          ("m3data", Lean.toJson (toString (M3InputParityOracle.m3data flag).toNat)),
          ("m3control", Lean.toJson (toString (M3InputParityOracle.m3control flag).toNat)),
          ("m3mutual", Lean.toJson (toString (M3InputParityOracle.m3mutual flag).toNat)),
          ("m3strategies", Lean.toJson (toString (M3InputParityOracle.m3strategies flag).toNat)),
          ("m3fields", Lean.toJson (toString (M3InputParityOracle.m3fields flag).toNat)),
          ("m3recursors", Lean.toJson (toString (M3InputParityOracle.m3recursors flag).toNat)),
          ("m3matches", Lean.toJson (toString (M3InputParityOracle.m3matches flag).toNat))]
        IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INPUT_PARITY: PASS native source routing, shared checked Core, universe/named/operator/scientific terms, native proofs, data/classes/instances/deriving, positive dependent function fields with singleton/mutual recursion and explicit induction, native public Nat/Except recursors and Empty/False motives, source match names/generalizing policy with checked equation origins and paired type refusals, where, singleton/mutual WF, ordinary partial P0 and selected fixedpoint P1, pattern lets, conditional patterns and typed do control, ordered binder scope/default ownership, both mixed-module directions, official kernel, five-target emission and assurance refusals; full native term/command parity remains open"
end M3InputParity
