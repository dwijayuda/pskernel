import Ps.Host.NativeV7
import PsKernelLean.Admission

namespace CoreM3MatchOracle
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

theorem coreElimVisibleIH (n : Nat) : n = n := by
  induction n
  case zero => rfl
  case succ k ih =>
    have h : k = k := match k with
      | Nat.zero => ih
      | Nat.succ j => ih
    rfl

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
  by exact namedResult.eq_def n

def constCount : Nat → Nat := fun n =>
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (constCount k)

theorem constCountObserved : constCount 3 = 3 := Eq.refl 3

theorem constCountSourceEquation :
    constCount = (fun n => match n with
      | 0 => 0
      | Nat.succ k => Nat.succ (constCount k)) := constCount.eq_def

def ConstCountType : Type := Nat → Nat

def constAliasCount : ConstCountType := fun n =>
  match n with
  | 0 => 0
  | Nat.succ k => Nat.succ (constAliasCount k)

theorem constAliasCountObserved : constAliasCount 3 = 3 := Eq.refl 3

theorem constAliasCountSourceEquation :
    constAliasCount = (fun n => match n with
      | 0 => 0
      | Nat.succ k => Nat.succ (constAliasCount k)) := constAliasCount.eq_def

def m3const (flag : Bool) : UInt64 :=
  let n := if flag then 3 else 5
  UInt64.ofNat (constCount n + 10 * constAliasCount (Nat.succ n))

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


inductive CorePromoted : Nat → Type where
  | intro (n : Nat) : CorePromoted n
inductive CoreParametric (A : Type) : Nat → Type where
  | intro (n : Nat) (value : A) : CoreParametric A n
inductive CoreFixedChild : Nat → Type where
  | leaf (n : Nat) : CoreFixedChild n
  | next (n : Nat) (child : CoreFixedChild n) : CoreFixedChild n
inductive CorePrefix : Nat → Bool → Type where
  | make (n : Nat) : CorePrefix n true
inductive CoreVarying : Nat → Type where
  | zero : CoreVarying 0
  | step (n : Nat) (child : CoreVarying n) : CoreVarying (Nat.succ n)
inductive CoreOrder : Nat → Nat → Type where
  | make (left right : Nat) : CoreOrder right left
inductive CoreChanging : Nat → Type where
  | intro (n : Nat) (child : CoreChanging (Nat.succ n)) : CoreChanging n

theorem corePromotedInduction (n : Nat) (x : CorePromoted n) : True := by
  induction x
  case intro => exact True.intro

theorem coreFixedChildInduction (n : Nat) (x : CoreFixedChild n) : True := by
  induction x
  case leaf => exact True.intro
  case next child ih => exact ih

run_cmd do
  for (name, parameters, indices, minors) in [
      (``CorePromoted, 1, 0, 1),
      (``CoreParametric, 2, 0, 1),
      (``CoreFixedChild, 1, 0, 2),
      (``CorePrefix, 1, 1, 1),
      (``CoreVarying, 0, 1, 2),
      (``CoreOrder, 0, 2, 1),
      (``CoreChanging, 0, 1, 1)] do
    let family ← Lean.getConstInfoInduct name
    let some (.recInfo recursor) := (← Lean.getEnv).find? (Lean.Name.str name "rec")
      | throwError "native promotion recursor missing: {name}"
    unless family.numParams == parameters && family.numIndices == indices &&
        recursor.numParams == parameters && recursor.numIndices == indices &&
        recursor.numMotives == 1 && recursor.numMinors == minors do
      throwError "native promotion family/recursor counts changed: {name}"
  for (name, parameters, fields) in [
      (``CorePromoted.intro, 1, 0),
      (``CoreParametric.intro, 2, 1),
      (``CoreFixedChild.leaf, 1, 0),
      (``CoreFixedChild.next, 1, 1),
      (``CorePrefix.make, 1, 0),
      (``CoreVarying.zero, 0, 0),
      (``CoreVarying.step, 0, 2),
      (``CoreOrder.make, 0, 2),
      (``CoreChanging.intro, 0, 2)] do
    let constructor ← Lean.getConstInfoCtor name
    unless constructor.numParams == parameters && constructor.numFields == fields do
      throwError "native promotion constructor counts changed: {name}"

universe coreUniverseU coreUniverseUnused
inductive CoreUniverseTypeBox where
  | mk (A : Type)
inductive CoreUniverseProofBox (P : Prop) where
  | mk (proof : P)
structure CoreUniverseProofStructure (P : Prop) where
  proof : P
inductive CoreUniverseEmpty where
structure CoreUniverseEmptyStructure where
inductive CoreUniverseTwoProofs (P Q : Prop) where
  | left (proof : P)
  | right (proof : Q)
inductive CoreUniverseRecursiveProof (P : Prop) where
  | wrap (child : CoreUniverseRecursiveProof P)
inductive CoreUniverseLevel (A : Type coreUniverseU) where
  | mk (value : A)
inductive CoreUniverseSort (A : Sort coreUniverseU) where
  | mk (value : A)
inductive CoreUniversePromote : Type coreUniverseU → Sort _ where
  | mk (A : Type coreUniverseU) : CoreUniversePromote A
inductive CoreUniverseFixedSort (A : Type coreUniverseU) : Type _ where
  | mk (value : A)
structure CoreUniverseBigStructure where
  A : Type
  value : A
inductive CoreUniverseConstructorOnly where
  | mk (A : Type coreUniverseU)

private def nativeDataResultSort : Lean.Expr → Option Lean.Level
  | .forallE _ _ body _ => nativeDataResultSort body
  | .sort level => some level
  | _ => none
run_cmd do
  let u := Lean.Level.param `coreUniverseU
  let zero := Lean.Level.zero
  let one := Lean.Level.succ zero
  let two := Lean.Level.succ one
  let cases : List (Lean.Name × Lean.Level × Nat) := [
    (``CoreUniverseTypeBox, two, 0),
    (``CoreUniverseProofBox, zero, 0),
    (``CoreUniverseProofStructure, zero, 0),
    (``CoreUniverseEmpty, one, 0),
    (``CoreUniverseEmptyStructure, one, 0),
    (``CoreUniverseTwoProofs, one, 0),
    (``CoreUniverseRecursiveProof, one, 0),
    (``CoreUniverseLevel, .succ u, 1),
    (``CoreUniverseSort, .max one u, 1),
    (``CoreUniversePromote, one, 1),
    (``CoreUniverseFixedSort, .succ u, 1),
    (``CoreUniverseBigStructure, two, 0),
    (``CoreUniverseConstructorOnly, .succ (.succ u), 1)]
  for (name, expected, levels) in cases do
    let info ← Lean.getConstInfoInduct name
    let some actual := nativeDataResultSort info.type
      | throwError "native data result is not a sort: {name}"
    unless actual.normalize == expected.normalize && info.levelParams.length == levels do
      throwError "native data result-sort/universe roster changed: {name}: {info.type}"
    if levels == 1 then
      unless info.levelParams == [`coreUniverseU] do
        throwError "native retained an unused or incorrect data universe: {name}"
  let promoted ← Lean.getConstInfoInduct ``CoreUniversePromote
  unless promoted.numParams == 1 && promoted.numIndices == 0 do
    throwError "native data universe fixture lost index promotion"
  Lean.logInfo "CORE-DATA-UNIVERSES: native exact result-sort/level-roster assertions passed"

private def expectNativeDataUniverseRefusal (command : Lean.Syntax) :
    Lean.Elab.Command.CommandElabM Unit := do
  let saved ← get
  let failed ← try
    modify fun (state : Lean.Elab.Command.State) =>
      { state with messages := Lean.MessageLog.empty, snapshotTasks := #[] }
    let messages ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages command
    let errors := messages.toList.filter fun message => message.severity == .error
    for message in errors do
      let content ← message.data.toString
      if ["heartbeat", "recursion depth", "maximum recursion", "timeout"].any
          (fun marker => (content.splitOn marker).length > 1) then
        throwError "native universe refusal exhausted resources: {content}"
    pure (!errors.isEmpty)
  finally
    set saved
  unless failed do
    throwError "native data universe unexpectedly accepted an invalid bound"

run_cmd do
  let command ← `(command| inductive BadTypeBox : Type where
    | mk (A : Type))
  expectNativeDataUniverseRefusal command
run_cmd do
  let command ← `(command| inductive BadMax : Sort (max _ _) where
    | mk (n : Nat))
  expectNativeDataUniverseRefusal command
run_cmd do
  let command ← `(command| inductive BadSort : Sort coreUniverseU where
    | mk (n : Nat))
  expectNativeDataUniverseRefusal command

end CoreM3MatchOracle

namespace CoreM3Matches
private def matchLeanSource : String :=
  "def matchDefault (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n\ndef matchTrue (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := true) a with\n  | true => h1 (Eq.refl true)\n  | false => h2 (Eq.refl false)\n\ndef matchFalse (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match (generalizing := false) h : a with\n  | true => h1 h\n  | false => h2 h\n\ndef matchLets (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  let first : a = true → Nat := h1\n  let second : a = false → Nat := h2\n  match h : a with\n  | true => first h\n  | false => second h\n\ndef matchComputed (a : Bool) (h1 : Bool.not a = true → Nat)\n    (h2 : Bool.not a = false → Nat) : Nat :=\n  match h : Bool.not a with\n  | true => h1 h\n  | false => h2 h\n\ndef matchMixed (a : Bool) (h1 : a = true → Nat) (h2 : a = false → Nat) : Nat :=\n  match a, Bool.not a with\n  | true, false => h1 (Eq.refl true)\n  | false, true => h2 (Eq.refl false)\n  | _, _ => 0\n\ndef matchOriginalValue (a b : Bool) (h : a = b) : Nat := if b then 13 else 17\n\ndef matchOriginal (a : Bool) : Nat :=\n  match h : a with\n  | true => matchOriginalValue a true h\n  | false => matchOriginalValue a false h\n\ntheorem matchDependentTarget (a : Bool) (h : a = a) : h = h :=\n  match a with\n  | true => Eq.refl h\n  | false => Eq.refl h\n\ndef m3matches (flag : Bool) : UInt64 :=\n  let first : flag = true → Nat := fun (_ : flag = true) => 3\n  let second : flag = false → Nat := fun (_ : flag = false) => 5\n  let computedFirst : Bool.not flag = true → Nat := fun (_ : Bool.not flag = true) => 7\n  let computedSecond : Bool.not flag = false → Nat := fun (_ : Bool.not flag = false) => 11\n  UInt64.ofNat (matchDefault flag first second +\n    10 * matchTrue flag first second +\n    100 * matchFalse flag first second +\n    1000 * matchLets flag first second +\n    10000 * matchComputed flag computedFirst computedSecond +\n    100000 * matchMixed flag first second +\n    1000000 * matchOriginal flag)\n"

private def matchPsSource : String :=
  "function matchDefault(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match a with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n\nfunction matchTrue(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := true) a with {\n  | true => h1(Eq.refl(true))\n  | false => h2(Eq.refl(false))\n  }\n\nfunction matchFalse(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match (generalizing := false) h: a with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n\nfunction matchLets(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  let first: a = true -> Nat := h1\n  let second: a = false -> Nat := h2\n  match h: a with {\n  | true => first(h)\n  | false => second(h)\n  }\n\nfunction matchComputed(a: Bool, h1: Bool.not(a) = true -> Nat, h2: Bool.not(a) = false -> Nat): Nat :=\n  match h: Bool.not(a) with {\n  | true => h1(h)\n  | false => h2(h)\n  }\n\nfunction matchMixed(a: Bool, h1: a = true -> Nat, h2: a = false -> Nat): Nat :=\n  match a, Bool.not(a) with {\n  | true, false => h1(Eq.refl(true))\n  | false, true => h2(Eq.refl(false))\n  | _, _ => 0\n  }\n\nfunction matchOriginalValue(a: Bool, b: Bool, h: a = b): Nat := if (b) { 13 } else { 17 }\n\nfunction matchOriginal(a: Bool): Nat :=\n  match h: a with {\n  | true => matchOriginalValue(a, true, h)\n  | false => matchOriginalValue(a, false, h)\n  }\n\ntheorem matchDependentTarget(a: Bool, h: a = a): h = h :=\n  match a with {\n  | true => Eq.refl(h)\n  | false => Eq.refl(h)\n  }\n\nfunction m3matches(flag: Bool): UInt64 :=\n  let first: flag = true -> Nat := fun (_: flag = true) => 3\n  let second: flag = false -> Nat := fun (_: flag = false) => 5\n  let computedFirst: Bool.not(flag) = true -> Nat := fun (_: Bool.not(flag) = true) => 7\n  let computedSecond: Bool.not(flag) = false -> Nat := fun (_: Bool.not(flag) = false) => 11\n  UInt64.ofNat(matchDefault(flag, first, second) +\n    10 * matchTrue(flag, first, second) +\n    100 * matchFalse(flag, first, second) +\n    1000 * matchLets(flag, first, second) +\n    10000 * matchComputed(flag, computedFirst, computedSecond) +\n    100000 * matchMixed(flag, first, second) +\n    1000000 * matchOriginal(flag))\n"

private def matchPolicyLeanSource : String :=
  "class MatchPolicyWitness (a : Bool) where\n  mark : Nat\n\ndef matchInstanceOriginal (a : Bool) (w : MatchPolicyWitness a)\n    (b : Bool) (h : a = b) : True := True.intro\n\ntheorem matchInstance (a : Bool) [w : MatchPolicyWitness a] : True :=\n  match h : a with\n  | true => matchInstanceOriginal a w true h\n  | false => matchInstanceOriginal a w false h\n\ndef matchAux (n : Nat) : Nat :=\n  match h : n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (matchAux k)\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n :=\n    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)\n  exact Nat.lt_succ_self k\n\ndef matchAuxFalse (n : Nat) : Nat :=\n  match (generalizing := false) h : n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (matchAuxFalse k)\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n :=\n    Eq.mpr (congrArg (fun (t : Nat) => Nat.lt k t) h) (Nat.lt_succ_self k)\n  exact Nat.lt_succ_self k\n\ndef matchAuxPrev (n : Nat) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k => k\n\ntheorem coreElimVisibleIH (n : Nat) : n = n := by\n  induction n\n  case zero => rfl\n  case succ k ih =>\n    have h : k = k := match k with\n      | Nat.zero => ih\n      | Nat.succ j => ih\n    rfl\n"

private def matchPolicyPsSource : String :=
  "class MatchPolicyWitness(a: Bool) where {\n  mark: Nat\n}\n\nfunction matchInstanceOriginal(a: Bool, w: MatchPolicyWitness a, b: Bool, h: a = b): True := True.intro\n\ntheorem matchInstance(a: Bool)[w: MatchPolicyWitness a]: True :=\n  match h: a with {\n  | true => matchInstanceOriginal(a, w, true, h)\n  | false => matchInstanceOriginal(a, w, false, h)\n  }\n\nfunction matchAux(n: Nat): Nat :=\n  match h: n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(matchAux(k))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(k, t), h), Nat.lt_succ_self(k))\n  exact Nat.lt_succ_self(k)\n}\n\nfunction matchAuxFalse(n: Nat): Nat :=\n  match (generalizing := false) h: n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(matchAuxFalse(k))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(k, t), h), Nat.lt_succ_self(k))\n  exact Nat.lt_succ_self(k)\n}\n\nfunction matchAuxPrev(n: Nat): Nat := match n with {\n  | 0 => 0\n  | Nat.succ k => k\n}\n\ntheorem coreElimVisibleIH(n: Nat): n = n := by {\n  induction n\n  case zero => rfl\n  case succ k ih =>\n    have h: k = k := match k with {\n      | Nat.zero => ih\n      | Nat.succ j => ih\n    }\n    rfl\n}\n"

private def matchLexicalLeanSource : String :=
  "def matchSwap (a b : Nat) : Nat :=\n  match a, b with\n  | b, a => 10 * a + b\n\ntheorem matchSwapObserved : matchSwap 2 7 = 72 := Eq.refl 72\n\ndef matchNamedOriginalB (b : Bool) : Nat :=\n  match hb : b with\n  | true => (fun (_ : b = true) => 37) hb\n  | false => (fun (_ : b = false) => 41) hb\n\ntheorem matchNamedOriginalBTrue : matchNamedOriginalB true = 37 := Eq.refl 37\ntheorem matchNamedOriginalBFalse : matchNamedOriginalB false = 41 := Eq.refl 41\n\ndef matchEqRight {left right : Nat} (_ : left = right) : Nat := right\n\ndef matchEquationShadow (n : Nat) : Nat :=\n  match h : n with\n  | 0 => matchEqRight h\n  | Nat.succ h => matchEqRight h\n\ntheorem matchEquationShadowZero : matchEquationShadow 0 = 0 := Eq.refl 0\ntheorem matchEquationShadowSucc : matchEquationShadow 4 = 4 := Eq.refl 4\n\ndef matchNestedBindings (a : Bool) (handle : a = a → Nat) : Nat :=\n  match (generalizing := true) a with\n  | x =>\n    match x with\n    | true => handle (Eq.refl true)\n    | false => handle (Eq.refl false)\n\ntheorem matchNestedBindingsTrue :\n    matchNestedBindings true (fun (_ : true = true) => 31) = 31 := Eq.refl 31\ntheorem matchNestedBindingsFalse :\n    matchNestedBindings false (fun (_ : false = false) => 43) = 43 := Eq.refl 43\n"

private def matchLexicalPsSource : String :=
  "function matchSwap(a: Nat, b: Nat): Nat :=\n  match a, b with {\n  | b, a => 10 * a + b\n  }\n\ntheorem matchSwapObserved: matchSwap(2, 7) = 72 := Eq.refl(72)\n\nfunction matchNamedOriginalB(b: Bool): Nat :=\n  match hb: b with {\n  | true => (fun (_: b = true) => 37)(hb)\n  | false => (fun (_: b = false) => 41)(hb)\n  }\n\ntheorem matchNamedOriginalBTrue: matchNamedOriginalB(true) = 37 := Eq.refl(37)\ntheorem matchNamedOriginalBFalse: matchNamedOriginalB(false) = 41 := Eq.refl(41)\n\nfunction matchEqRight {left right: Nat}(proof: left = right): Nat := right\n\nfunction matchEquationShadow(n: Nat): Nat :=\n  match h: n with {\n  | 0 => matchEqRight(h)\n  | Nat.succ h => matchEqRight(h)\n  }\n\ntheorem matchEquationShadowZero: matchEquationShadow(0) = 0 := Eq.refl(0)\ntheorem matchEquationShadowSucc: matchEquationShadow(4) = 4 := Eq.refl(4)\n\nfunction matchNestedBindings(a: Bool, handle: a = a -> Nat): Nat :=\n  match (generalizing := true) a with {\n  | x =>\n    match x with {\n    | true => handle(Eq.refl(true))\n    | false => handle(Eq.refl(false))\n    }\n  }\n\ntheorem matchNestedBindingsTrue:\n  matchNestedBindings(true, fun (_: true = true) => 31) = 31 := Eq.refl(31)\ntheorem matchNestedBindingsFalse:\n  matchNestedBindings(false, fun (_: false = false) => 43) = 43 := Eq.refl(43)\n"

private def matchIndexedLeanSource : String :=
  "inductive MatchIndexed : Bool → Type where\n  | yes (value : Nat) : MatchIndexed true\n  | no (value : Nat) : MatchIndexed false\n\ndef matchIndexMake (a : Bool) : MatchIndexed a :=\n  match a with\n  | true => MatchIndexed.yes 53\n  | false => MatchIndexed.no 59\n\ndef matchIndexBoolEqMark (a b : Bool) (_ : a = b) : Nat := 0\n\ndef matchIndexEqMark (a : Bool) (original current : MatchIndexed a)\n    (_ : original = current) : Nat := 0\n\ndef matchIndexHEqMark (a : Bool) (original : MatchIndexed a)\n    (b : Bool) (current : MatchIndexed b) (_ : HEq original current) : Nat := 0\n\ndef matchComputedLaterFalse (a : Bool) : Nat :=\n  match (generalizing := false) ha : a, hv : matchIndexMake a with\n  | true, MatchIndexed.yes n =>\n    n + matchIndexBoolEqMark a true ha +\n      matchIndexHEqMark a (matchIndexMake a) true (MatchIndexed.yes n) hv\n  | false, MatchIndexed.no n =>\n    n + matchIndexBoolEqMark a false ha +\n      matchIndexHEqMark a (matchIndexMake a) false (MatchIndexed.no n) hv\n\ntheorem matchComputedLaterFalseTrue : matchComputedLaterFalse true = 53 := Eq.refl 53\ntheorem matchComputedLaterFalseFalse : matchComputedLaterFalse false = 59 := Eq.refl 59\n\ndef matchIndexedNamed (a : Bool) (value : MatchIndexed a) : Nat :=\n  match (generalizing := false) h : value with\n  | MatchIndexed.yes n =>\n    n + matchIndexHEqMark a value true (MatchIndexed.yes n) h\n  | MatchIndexed.no n =>\n    n + matchIndexHEqMark a value false (MatchIndexed.no n) h\n\ntheorem matchIndexedNamedTrue :\n    matchIndexedNamed true (MatchIndexed.yes 61) = 61 := Eq.refl 61\ntheorem matchIndexedNamedFalse :\n    matchIndexedNamed false (MatchIndexed.no 67) = 67 := Eq.refl 67\n\ndef matchIndexedNamedEq (value : MatchIndexed true) : Nat :=\n  match h : value with\n  | MatchIndexed.yes n => n + matchIndexEqMark true value (MatchIndexed.yes n) h\n\ntheorem matchIndexedNamedEqObserved :\n    matchIndexedNamedEq (MatchIndexed.yes 71) = 71 := Eq.refl 71\n\ndef matchNestedIndexed (a : Bool) (value : MatchIndexed a)\n    (handle : value = value → Nat) : Nat :=\n  match a with\n  | true =>\n    match value with\n    | MatchIndexed.yes n => handle (Eq.refl (MatchIndexed.yes n))\n  | false =>\n    match value with\n    | MatchIndexed.no n => handle (Eq.refl (MatchIndexed.no n))\n\ntheorem matchNestedIndexedTrue :\n    matchNestedIndexed true (MatchIndexed.yes 2)\n      (fun (_ : MatchIndexed.yes 2 = MatchIndexed.yes 2) => 73) = 73 := Eq.refl 73\ntheorem matchNestedIndexedFalse :\n    matchNestedIndexed false (MatchIndexed.no 3)\n      (fun (_ : MatchIndexed.no 3 = MatchIndexed.no 3) => 79) = 79 := Eq.refl 79\n\ninductive MatchRowPack where\n  | pack (index : Bool) (value : MatchIndexed index)\n\ndef matchRowDependent (packed : MatchRowPack) : Nat :=\n  match packed with\n  | MatchRowPack.pack _ value =>\n    let same : value = value := Eq.refl value\n    83\n\ndef matchRowNested (packed : Option MatchRowPack) : Nat :=\n  match packed with\n  | Option.none => 0\n  | Option.some (MatchRowPack.pack _ value) =>\n    let same : value = value := Eq.refl value\n    89\n\ntheorem matchRowDependentObserved :\n    matchRowDependent (MatchRowPack.pack true (MatchIndexed.yes 2)) = 83 := Eq.refl 83\ntheorem matchRowNestedObserved :\n    matchRowNested (Option.some (MatchRowPack.pack false (MatchIndexed.no 3))) = 89 := Eq.refl 89\n"

private def matchIndexedPsSource : String :=
  "inductive MatchIndexed: Bool -> Type where {\n  | yes(value: Nat): MatchIndexed(true)\n  | no(value: Nat): MatchIndexed(false)\n}\n\nfunction matchIndexMake(a: Bool): MatchIndexed(a) :=\n  match a with {\n  | true => MatchIndexed.yes(53)\n  | false => MatchIndexed.no(59)\n  }\n\nfunction matchIndexBoolEqMark(a: Bool, b: Bool, proof: a = b): Nat := 0\n\nfunction matchIndexEqMark(a: Bool, original: MatchIndexed(a), current: MatchIndexed(a), proof: original = current): Nat := 0\n\nfunction matchIndexHEqMark(a: Bool, original: MatchIndexed(a), b: Bool, current: MatchIndexed(b), proof: HEq(original, current)): Nat := 0\n\nfunction matchComputedLaterFalse(a: Bool): Nat :=\n  match (generalizing := false) ha: a, hv: matchIndexMake(a) with {\n  | true, MatchIndexed.yes n =>\n    n + matchIndexBoolEqMark(a, true, ha) +\n      matchIndexHEqMark(a, matchIndexMake(a), true, MatchIndexed.yes(n), hv)\n  | false, MatchIndexed.no n =>\n    n + matchIndexBoolEqMark(a, false, ha) +\n      matchIndexHEqMark(a, matchIndexMake(a), false, MatchIndexed.no(n), hv)\n  }\n\ntheorem matchComputedLaterFalseTrue: matchComputedLaterFalse(true) = 53 := Eq.refl(53)\ntheorem matchComputedLaterFalseFalse: matchComputedLaterFalse(false) = 59 := Eq.refl(59)\n\nfunction matchIndexedNamed(a: Bool, value: MatchIndexed(a)): Nat :=\n  match (generalizing := false) h: value with {\n  | MatchIndexed.yes n =>\n    n + matchIndexHEqMark(a, value, true, MatchIndexed.yes(n), h)\n  | MatchIndexed.no n =>\n    n + matchIndexHEqMark(a, value, false, MatchIndexed.no(n), h)\n  }\n\ntheorem matchIndexedNamedTrue:\n  matchIndexedNamed(true, MatchIndexed.yes(61)) = 61 := Eq.refl(61)\ntheorem matchIndexedNamedFalse:\n  matchIndexedNamed(false, MatchIndexed.no(67)) = 67 := Eq.refl(67)\n\nfunction matchIndexedNamedEq(value: MatchIndexed(true)): Nat :=\n  match h: value with {\n  | MatchIndexed.yes n => n + matchIndexEqMark(true, value, MatchIndexed.yes(n), h)\n  }\n\ntheorem matchIndexedNamedEqObserved:\n  matchIndexedNamedEq(MatchIndexed.yes(71)) = 71 := Eq.refl(71)\n\nfunction matchNestedIndexed(a: Bool, value: MatchIndexed(a), handle: value = value -> Nat): Nat :=\n  match a with {\n  | true =>\n    match value with {\n    | MatchIndexed.yes n => handle(Eq.refl(MatchIndexed.yes(n)))\n    }\n  | false =>\n    match value with {\n    | MatchIndexed.no n => handle(Eq.refl(MatchIndexed.no(n)))\n    }\n  }\n\ntheorem matchNestedIndexedTrue:\n  matchNestedIndexed(true, MatchIndexed.yes(2),\n    fun (_: MatchIndexed.yes(2) = MatchIndexed.yes(2)) => 73) = 73 := Eq.refl(73)\ntheorem matchNestedIndexedFalse:\n  matchNestedIndexed(false, MatchIndexed.no(3),\n    fun (_: MatchIndexed.no(3) = MatchIndexed.no(3)) => 79) = 79 := Eq.refl(79)\n\ninductive MatchRowPack where {\n  | pack(index: Bool, value: MatchIndexed(index))\n}\n\nfunction matchRowDependent(packed: MatchRowPack): Nat :=\n  match packed with {\n  | MatchRowPack.pack _ value =>\n    let same: value = value := Eq.refl(value)\n    83\n  }\n\nfunction matchRowNested(packed: Option(MatchRowPack)): Nat :=\n  match packed with {\n  | Option.none => 0\n  | Option.some (MatchRowPack.pack _ value) =>\n    let same: value = value := Eq.refl(value)\n    89\n  }\n\ntheorem matchRowDependentObserved:\n    matchRowDependent(MatchRowPack.pack(true, MatchIndexed.yes(2))) = 83 := Eq.refl(83)\ntheorem matchRowNestedObserved:\n    matchRowNested(Option.some(MatchRowPack.pack(false, MatchIndexed.no(3)))) = 89 := Eq.refl(89)\n"

private def structuralLeanSource : String :=
  "def namedCount (n : Nat) : Nat :=\n  match h : n with\n  | 0 => let witness : n = 0 := h; 0\n  | Nat.succ k => let witness : n = Nat.succ k := h; Nat.succ (namedCount k)\ndef namedResult (n : Nat) : Nat → Nat :=\n  fun (bias : Nat) => match (generalizing := false) h : n with\n    | 0 => bias\n    | Nat.succ k => namedResult k (Nat.succ bias)\ndef namedRows (A : Type) (rows : List (List A)) : Nat :=\n  match h : rows with\n  | .nil => 0\n  | .cons row rest => Nat.succ (namedRows A rest)\ndef namedComputed (F : Nat → Type) (i : Nat) (values : List (F i)) : Nat :=\n  match (generalizing := true) h : values with\n  | .nil => 0\n  | .cons value rest => Nat.succ (namedComputed F i rest)\ninductive NamedNest (A : Type) where\n  | leaf (value : A)\n  | direct (child : NamedNest A)\n  | many (children : List (NamedNest A))\n  | deep (children : List (List (NamedNest A)))\nmutual\ndef namedTree (A : Type) (tree : NamedNest A) : Nat :=\n  match h : tree with\n  | .leaf value => 1\n  | .direct child => Nat.succ (namedTree A child)\n  | .many children => Nat.succ (namedForest A children)\n  | .deep children => Nat.succ (namedDeep A children)\ndef namedForest (A : Type) (children : List (NamedNest A)) : Nat :=\n  match h : children with\n  | .nil => 0\n  | .cons child rest => namedTree A child + namedForest A rest\ndef namedDeep (A : Type) (children : List (List (NamedNest A))) : Nat :=\n  match h : children with\n  | .nil => 0\n  | .cons row rest => namedForest A row + namedDeep A rest\nend\ndef m3structural (flag : Bool) : UInt64 :=\n  let amount := if flag then 3 else 5\n  let rows := List.cons (List.cons amount List.nil) (List.cons List.nil List.nil)\n  let leaf := NamedNest.leaf amount\n  let trees := List.cons leaf (List.cons (NamedNest.direct leaf) List.nil)\n  let tree := if flag then\n    NamedNest.deep (List.cons trees (List.cons (List.cons (NamedNest.direct leaf) List.nil) List.nil))\n    else NamedNest.many (List.cons (NamedNest.deep (List.cons trees List.nil)) (List.cons (NamedNest.direct leaf) List.nil))\n  UInt64.ofNat (namedCount amount + 10 * namedResult amount 4 +\n    100 * namedRows Nat rows +\n    1000 * namedComputed (fun (_ : Nat) => Nat) amount (List.cons amount List.nil) +\n    10000 * namedTree Nat tree)\ntheorem namedResultObserved : namedResult 3 5 = 8 := by rfl\ntheorem namedResultSource (n : Nat) :\n    namedResult n = (fun (bias : Nat) => match (generalizing := false) h : n with\n      | 0 => bias\n      | Nat.succ k => namedResult k (Nat.succ bias)) :=\n  by exact namedResult.eq_def n\n\ndef constCount : Nat → Nat := fun n =>\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (constCount k)\n\ntheorem constCountObserved : constCount 3 = 3 := Eq.refl 3\n\ntheorem constCountSourceEquation :\n    constCount = (fun n => match n with\n      | 0 => 0\n      | Nat.succ k => Nat.succ (constCount k)) := constCount.eq_def\n\ndef ConstCountType : Type := Nat → Nat\n\ndef constAliasCount : ConstCountType := fun n =>\n  match n with\n  | 0 => 0\n  | Nat.succ k => Nat.succ (constAliasCount k)\n\ntheorem constAliasCountObserved : constAliasCount 3 = 3 := Eq.refl 3\n\ntheorem constAliasCountSourceEquation :\n    constAliasCount = (fun n => match n with\n      | 0 => 0\n      | Nat.succ k => Nat.succ (constAliasCount k)) := constAliasCount.eq_def\n\ndef m3const (flag : Bool) : UInt64 :=\n  let n := if flag then 3 else 5\n  UInt64.ofNat (constCount n + 10 * constAliasCount (Nat.succ n))\n"

private def structuralPsSource : String :=
  "function namedCount(n: Nat): Nat := match h : n with {\n  | 0 => let witness: n = 0 := h\n    0\n  | Nat.succ k => let witness: n = Nat.succ(k) := h\n    Nat.succ(namedCount(k))\n}\nfunction namedResult(n: Nat): Nat -> Nat := fun (bias: Nat) => match (generalizing := false) h : n with {\n  | 0 => bias\n  | Nat.succ k => namedResult(k, Nat.succ(bias))\n}\nfunction namedRows(A: Type, rows: List(List(A))): Nat := match h : rows with {\n  | .nil => 0\n  | .cons row rest => Nat.succ(namedRows(A, rest))\n}\nfunction namedComputed(F: Nat -> Type, i: Nat, values: List(F(i))): Nat := match (generalizing := true) h : values with {\n  | .nil => 0\n  | .cons value rest => Nat.succ(namedComputed(F, i, rest))\n}\ninductive NamedNest(A: Type) where {\n  | leaf(value: A)\n  | direct(child: NamedNest(A))\n  | many(children: List(NamedNest(A)))\n  | deep(children: List(List(NamedNest(A))))\n}\nmutual\nfunction namedTree(A: Type, tree: NamedNest(A)): Nat := match h : tree with {\n  | .leaf value => 1\n  | .direct child => Nat.succ(namedTree(A, child))\n  | .many children => Nat.succ(namedForest(A, children))\n  | .deep children => Nat.succ(namedDeep(A, children))\n}\nfunction namedForest(A: Type, children: List(NamedNest(A))): Nat := match h : children with {\n  | .nil => 0\n  | .cons child rest => namedTree(A, child) + namedForest(A, rest)\n}\nfunction namedDeep(A: Type, children: List(List(NamedNest(A)))): Nat := match h : children with {\n  | .nil => 0\n  | .cons row rest => namedForest(A, row) + namedDeep(A, rest)\n}\nend\nfunction m3structural(flag: Bool): UInt64 :=\n  let amount := if (flag) { 3 } else { 5 }\n  let rows := List.cons(List.cons(amount, List.nil), List.cons(List.nil, List.nil))\n  let leaf := NamedNest.leaf(amount)\n  let trees := List.cons(leaf, List.cons(NamedNest.direct(leaf), List.nil))\n  let tree := if (flag) {\n    NamedNest.deep(List.cons(trees, List.cons(List.cons(NamedNest.direct(leaf), List.nil), List.nil)))\n  } else {\n    NamedNest.many(List.cons(NamedNest.deep(List.cons(trees, List.nil)), List.cons(NamedNest.direct(leaf), List.nil)))\n  }\n  UInt64.ofNat(namedCount(amount) + 10 * namedResult(amount, 4) +\n    100 * namedRows(Nat, rows) +\n    1000 * namedComputed(fun (_: Nat) => Nat, amount, List.cons(amount, List.nil)) +\n    10000 * namedTree(Nat, tree))\ntheorem namedResultObserved: namedResult(3, 5) = 8 := by { rfl }\ntheorem namedResultSource(n: Nat):\n    namedResult(n) = (fun (bias: Nat) => match (generalizing := false) h : n with {\n      | 0 => bias\n      | Nat.succ k => namedResult(k, Nat.succ(bias))\n    }) := by { exact namedResult.eq_def(n) }\n\nconst constCount: Nat -> Nat := fun (n: Nat) =>\n  match n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(constCount(k))\n  }\n\ntheorem constCountObserved: constCount(3) = 3 := Eq.refl(3)\n\ntheorem constCountSourceEquation:\n    constCount = (fun (n: Nat) => match n with {\n      | 0 => 0\n      | Nat.succ k => Nat.succ(constCount(k))\n    }) := constCount.eq_def\n\nconst ConstCountType: Type := Nat -> Nat\n\nconst constAliasCount: ConstCountType := fun (n: Nat) =>\n  match n with {\n  | 0 => 0\n  | Nat.succ k => Nat.succ(constAliasCount(k))\n  }\n\ntheorem constAliasCountObserved: constAliasCount(3) = 3 := Eq.refl(3)\n\ntheorem constAliasCountSourceEquation:\n    constAliasCount = (fun (n: Nat) => match n with {\n      | 0 => 0\n      | Nat.succ k => Nat.succ(constAliasCount(k))\n    }) := constAliasCount.eq_def\n\nfunction m3const(flag: Bool): UInt64 :=\n  let n := if (flag) { 3 } else { 5 }\n  UInt64.ofNat(constCount(n) + 10 * constAliasCount(Nat.succ(n)))\n"

private def inlineLeanSource : String :=
  "inductive InlineTree where\n  | node (children : List InlineTree)\ndef inlinePlain (tree : InlineTree) : Bool :=\n  match tree with\n  | .node [] => true\n  | .node [t] => inlinePlain t\n  | .node _ => false\ndef inlineNamed (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => let witness : tree = InlineTree.node [] := h; true\n  | .node [t] => let witness : tree = InlineTree.node [t] := h; inlineNamed t\n  | .node _ => false\ndef inlineDeep (tree : InlineTree) : Nat :=\n  match h : tree with\n  | .node [.node [t]] => Nat.succ (inlineDeep t)\n  | .node _ => 0\ndef inlineResult (tree : InlineTree) : Nat → Nat :=\n  fun (bias : Nat) => match (generalizing := false) h : tree with\n    | .node [] => bias\n    | .node [t] => inlineResult t (Nat.succ bias)\n    | .node _ => bias + 10\nmutual\ndef inlineEven (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => true\n  | .node [t] => inlineOdd t\n  | .node _ => false\ndef inlineOdd (tree : InlineTree) : Bool :=\n  match h : tree with\n  | .node [] => false\n  | .node [t] => inlineEven t\n  | .node _ => false\nend\ninductive InlineBranch where\n  | node (children : Bool → List InlineBranch)\nmutual\ndef inlineBranch (tree : InlineBranch) : Nat :=\n  match h : tree with\n  | .node children => inlineBranchChildren (children true)\ndef inlineBranchChildren (trees : List InlineBranch) : Nat :=\n  match hc : trees with\n  | [] => 0\n  | [t] => Nat.succ (inlineBranch t)\n  | _ => 0\nend\ninductive InlineIndexed : Nat → Type where\n  | node (children : List (InlineIndexed 0)) : InlineIndexed 0\ndef inlineIndexed (n : Nat) (tree : InlineIndexed n) : Nat :=\n  match h : tree with\n  | .node [] => 0\n  | .node [t] => Nat.succ (inlineIndexed 0 t)\n  | .node _ => 0\ndef m3inline (flag : Bool) : UInt64 :=\n  let leaf := InlineTree.node []\n  let link := InlineTree.node [leaf]\n  let chain := InlineTree.node [link]\n  let wide := InlineTree.node [leaf, leaf]\n  let tree := if flag then chain else wide\n  let branchEmpty := InlineBranch.node (fun (_ : Bool) => [])\n  let branchLink := InlineBranch.node (fun (_ : Bool) => [branchEmpty])\n  let branchChain := InlineBranch.node (fun (_ : Bool) => [branchLink])\n  let branchInput := if flag then branchLink else branchChain\n  let ix0 := InlineIndexed.node []\n  let ix1 := InlineIndexed.node [ix0]\n  let ix2 := InlineIndexed.node [ix1]\n  let indexInput := if flag then ix1 else ix2\n  let mutualInput := if flag then chain else link\n  UInt64.ofNat (\n    (if inlinePlain tree then 1 else 0) +\n    10 * (if inlineNamed tree then 1 else 0) +\n    100 * inlineResult tree 4 +\n    10000 * inlineDeep tree +\n    100000 * inlineBranch branchInput +\n    1000000 * inlineIndexed 0 indexInput +\n    10000000 * (if inlineEven mutualInput then 1 else 0) +\n    100000000 * (if inlineOdd mutualInput then 1 else 0))\ntheorem inlineResultObserved :\n    inlineResult (InlineTree.node [InlineTree.node []]) 5 = 6 := by rfl\n"

private def inlinePsSource : String :=
  "inductive InlineTree where {\n  | node(children: List(InlineTree))\n}\nfunction inlinePlain(tree: InlineTree): Bool := match tree with {\n  | .node [] => true\n  | .node [t] => inlinePlain(t)\n  | .node _ => false\n}\nfunction inlineNamed(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => let witness: tree = InlineTree.node([]) := h\n    true\n  | .node [t] => let witness: tree = InlineTree.node([t]) := h\n    inlineNamed(t)\n  | .node _ => false\n}\nfunction inlineDeep(tree: InlineTree): Nat := match h: tree with {\n  | .node [.node [t]] => Nat.succ(inlineDeep(t))\n  | .node _ => 0\n}\nfunction inlineResult(tree: InlineTree): Nat -> Nat :=\n  fun (bias: Nat) => match (generalizing := false) h: tree with {\n    | .node [] => bias\n    | .node [t] => inlineResult(t, Nat.succ(bias))\n    | .node _ => bias + 10\n  }\nmutual\nfunction inlineEven(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => true\n  | .node [t] => inlineOdd(t)\n  | .node _ => false\n}\nfunction inlineOdd(tree: InlineTree): Bool := match h: tree with {\n  | .node [] => false\n  | .node [t] => inlineEven(t)\n  | .node _ => false\n}\nend\ninductive InlineBranch where {\n  | node(children: Bool -> List(InlineBranch))\n}\nmutual {\nfunction inlineBranch(tree: InlineBranch): Nat := match h: tree with {\n  | .node children => inlineBranchChildren(children(true))\n}\nfunction inlineBranchChildren(trees: List(InlineBranch)): Nat := match hc: trees with {\n  | [] => 0\n  | [t] => Nat.succ(inlineBranch(t))\n  | _ => 0\n}\n}\ninductive InlineIndexed: Nat -> Type where {\n  | node(children: List(InlineIndexed(0))): InlineIndexed(0)\n}\nfunction inlineIndexed(n: Nat, tree: InlineIndexed(n)): Nat := match h: tree with {\n  | .node [] => 0\n  | .node [t] => Nat.succ(inlineIndexed(0, t))\n  | .node _ => 0\n}\nfunction m3inline(flag: Bool): UInt64 :=\n  let leaf := InlineTree.node([])\n  let link := InlineTree.node([leaf])\n  let chain := InlineTree.node([link])\n  let wide := InlineTree.node([leaf, leaf])\n  let tree := if (flag) { chain } else { wide }\n  let branchEmpty := InlineBranch.node(fun (_: Bool) => [])\n  let branchLink := InlineBranch.node(fun (_: Bool) => [branchEmpty])\n  let branchChain := InlineBranch.node(fun (_: Bool) => [branchLink])\n  let branchInput := if (flag) { branchLink } else { branchChain }\n  let ix0 := InlineIndexed.node([])\n  let ix1 := InlineIndexed.node([ix0])\n  let ix2 := InlineIndexed.node([ix1])\n  let indexInput := if (flag) { ix1 } else { ix2 }\n  let mutualInput := if (flag) { chain } else { link }\n  UInt64.ofNat(\n    (if (inlinePlain(tree)) { 1 } else { 0 }) +\n    10 * (if (inlineNamed(tree)) { 1 } else { 0 }) +\n    100 * inlineResult(tree, 4) +\n    10000 * inlineDeep(tree) +\n    100000 * inlineBranch(branchInput) +\n    1000000 * inlineIndexed(0, indexInput) +\n    10000000 * (if (inlineEven(mutualInput)) { 1 } else { 0 }) +\n    100000000 * (if (inlineOdd(mutualInput)) { 1 } else { 0 }))\ntheorem inlineResultObserved:\n  inlineResult(InlineTree.node([InlineTree.node([])]), 5) = 6 := by { rfl }\n"

private def wfBoundaryLeanSource : String :=
  "structure WfBoundaryBox (n : Nat) where\n  value : Nat\n\ndef wfBoundaryMeasure (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  WfBoundaryBox.value p\n\ndef wfBoundaryPair (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  match n, p with\n  | 0, _ => 0\n  | Nat.succ k, WfBoundaryBox.mk 0 => 0\n  | Nat.succ k, WfBoundaryBox.mk (Nat.succ v) =>\n    Nat.succ (wfBoundaryPair k (WfBoundaryBox.mk v))\ntermination_by wfBoundaryMeasure n p\ndecreasing_by\n  exact Nat.lt_succ_self v\n\ndef wfBoundaryGeneralized (n : Nat) (p : WfBoundaryBox n) : Nat :=\n  match n with\n  | 0 => 0\n  | Nat.succ k =>\n    match p with\n    | WfBoundaryBox.mk 0 => 0\n    | WfBoundaryBox.mk (Nat.succ v) =>\n      Nat.succ (wfBoundaryGeneralized k (WfBoundaryBox.mk v))\ntermination_by wfBoundaryMeasure n p\ndecreasing_by\n  exact Nat.lt_succ_self v\n\ndef wfBoundaryComputed (n : Nat) : Nat :=\n  match h : Nat.succ n with\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ (wfBoundaryComputed k)\ntermination_by Nat.succ n\ndecreasing_by\n  exact Eq.mpr (congrArg (fun (t : Nat) => Nat.lt (Nat.succ k) t) h)\n    (Nat.lt_succ_self (Nat.succ k))\n\ndef wfBoundaryUserRecursor (n : Nat) (impossible : n = n → False) : Nat :=\n  Nat.rec (motive := fun (_ : Nat) => Nat) 0\n    (fun (k : Nat) (ih : Nat) =>\n      wfBoundaryUserRecursor k (fun (_ : k = k) => impossible (Eq.refl n))) n\ntermination_by n\ndecreasing_by\n  have original : Nat.lt k n := False.elim (impossible (Eq.refl n))\n  exact original\n\ndef wfBoundaryCatchAll (n : Nat) (impossible : n = n → False) : Nat :=\n  match n with\n  | x => wfBoundaryCatchAll (Nat.succ x)\n      (fun (_ : Nat.succ x = Nat.succ x) => impossible (Eq.refl n))\ntermination_by n\ndecreasing_by\n  have original : Nat.lt (Nat.succ n) n := False.elim (impossible (Eq.refl n))\n  exact original\n\ndef m3wfboundaries (flag : Bool) : UInt64 :=\n  let n : Nat := if flag then 4 else 2\n  UInt64.ofNat (wfBoundaryPair n (WfBoundaryBox.mk 5) +\n    10 * wfBoundaryGeneralized n (WfBoundaryBox.mk 3) +\n    100 * wfBoundaryComputed n)\n"

private def wfBoundaryPsSource : String :=
  "structure WfBoundaryBox(n: Nat) where {\n  value: Nat\n}\n\nfunction wfBoundaryMeasure(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  WfBoundaryBox.value(p)\n\nfunction wfBoundaryPair(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  match n, p with {\n  | 0, _ => 0\n  | Nat.succ k, WfBoundaryBox.mk 0 => 0\n  | Nat.succ k, WfBoundaryBox.mk (Nat.succ v) =>\n    Nat.succ(wfBoundaryPair(k, WfBoundaryBox.mk(v)))\n  }\ntermination_by wfBoundaryMeasure(n, p)\ndecreasing_by by {\n  exact Nat.lt_succ_self(v)\n}\n\nfunction wfBoundaryGeneralized(n: Nat, p: WfBoundaryBox(n)): Nat :=\n  match n with {\n  | 0 => 0\n  | Nat.succ k =>\n    match p with {\n    | WfBoundaryBox.mk 0 => 0\n    | WfBoundaryBox.mk (Nat.succ v) =>\n      Nat.succ(wfBoundaryGeneralized(k, WfBoundaryBox.mk(v)))\n    }\n  }\ntermination_by wfBoundaryMeasure(n, p)\ndecreasing_by by {\n  exact Nat.lt_succ_self(v)\n}\n\nfunction wfBoundaryComputed(n: Nat): Nat :=\n  match h: Nat.succ(n) with {\n  | 0 => 0\n  | Nat.succ 0 => 0\n  | Nat.succ (Nat.succ k) => Nat.succ(wfBoundaryComputed(k))\n  }\ntermination_by Nat.succ(n)\ndecreasing_by by {\n  exact Eq.mpr(congrArg(fun (t: Nat) => Nat.lt(Nat.succ(k), t), h),\n    Nat.lt_succ_self(Nat.succ(k)))\n}\n\nfunction wfBoundaryUserRecursor(n: Nat, impossible: n = n -> False): Nat :=\n  Nat.rec(0,\n    fun (k: Nat) (ih: Nat) => wfBoundaryUserRecursor(k,\n      fun (_: k = k) => impossible(Eq.refl(n))),\n    n, motive := fun (_: Nat) => Nat)\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(k, n) := False.elim(impossible(Eq.refl(n)))\n  exact original\n}\n\nfunction wfBoundaryCatchAll(n: Nat, impossible: n = n -> False): Nat :=\n  match n with {\n  | x => wfBoundaryCatchAll(Nat.succ(x),\n      fun (_: Nat.succ(x) = Nat.succ(x)) => impossible(Eq.refl(n)))\n  }\ntermination_by n\ndecreasing_by by {\n  have original: Nat.lt(Nat.succ(n), n) := False.elim(impossible(Eq.refl(n)))\n  exact original\n}\n\nfunction m3wfboundaries(flag: Bool): UInt64 :=\n  let n: Nat := if (flag) { 4 } else { 2 }\n  UInt64.ofNat(wfBoundaryPair(n, WfBoundaryBox.mk(5)) +\n    10 * wfBoundaryGeneralized(n, WfBoundaryBox.mk(3)) +\n    100 * wfBoundaryComputed(n))\n"

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError message)

private def fromExcept {α : Type} (value : Except String α) : IO α :=
  match value with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

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



private def promotionLeanSource : String := "inductive CorePromoted : Nat → Type where\n  | intro (n : Nat) : CorePromoted n\ninductive CoreParametric (A : Type) : Nat → Type where\n  | intro (n : Nat) (value : A) : CoreParametric A n\ninductive CoreFixedChild : Nat → Type where\n  | leaf (n : Nat) : CoreFixedChild n\n  | next (n : Nat) (child : CoreFixedChild n) : CoreFixedChild n\ninductive CorePrefix : Nat → Bool → Type where\n  | make (n : Nat) : CorePrefix n true\ninductive CoreVarying : Nat → Type where\n  | zero : CoreVarying 0\n  | step (n : Nat) (child : CoreVarying n) : CoreVarying (Nat.succ n)\ninductive CoreOrder : Nat → Nat → Type where\n  | make (left right : Nat) : CoreOrder right left\ninductive CoreChanging : Nat → Type where\n  | intro (n : Nat) (child : CoreChanging (Nat.succ n)) : CoreChanging n\n\ntheorem corePromotedInduction (n : Nat) (x : CorePromoted n) : True := by\n  induction x\n  case intro => exact True.intro\n\ntheorem coreFixedChildInduction (n : Nat) (x : CoreFixedChild n) : True := by\n  induction x\n  case leaf => exact True.intro\n  case next child ih => exact ih\n"
private def promotionPsSource : String := "inductive CorePromoted: Nat -> Type where {\n  | intro(n: Nat): CorePromoted(n)\n}\ninductive CoreParametric(A: Type): Nat -> Type where {\n  | intro(n: Nat, value: A): CoreParametric(A, n)\n}\ninductive CoreFixedChild: Nat -> Type where {\n  | leaf(n: Nat): CoreFixedChild(n)\n  | next(n: Nat, child: CoreFixedChild(n)): CoreFixedChild(n)\n}\ninductive CorePrefix: Nat -> Bool -> Type where {\n  | make(n: Nat): CorePrefix(n, true)\n}\ninductive CoreVarying: Nat -> Type where {\n  | zero: CoreVarying(0)\n  | step(n: Nat, child: CoreVarying(n)): CoreVarying(Nat.succ(n))\n}\ninductive CoreOrder: Nat -> Nat -> Type where {\n  | make(left: Nat, right: Nat): CoreOrder(right, left)\n}\ninductive CoreChanging: Nat -> Type where {\n  | intro(n: Nat, child: CoreChanging(Nat.succ(n))): CoreChanging(n)\n}\ntheorem corePromotedInduction(n: Nat, x: CorePromoted(n)): True := by {\n  induction x\n  case intro => exact True.intro\n}\ntheorem coreFixedChildInduction(n: Nat, x: CoreFixedChild(n)): True := by {\n  induction x\n  case leaf => exact True.intro\n  case next child ih => exact ih\n}\n"

private def checkPromotionMetadata (environment : PsEnvironment) : IO Unit := do
  for (name, parameters, indices, minors) in [
      ("CorePromoted", 1, 0, 1),
      ("CoreParametric", 2, 0, 1),
      ("CoreFixedChild", 1, 0, 2),
      ("CorePrefix", 1, 1, 1),
      ("CoreVarying", 0, 1, 2),
      ("CoreOrder", 0, 2, 1),
      ("CoreChanging", 0, 1, 1)] do
    let some family := psEnvironmentFindInductive environment (psRootName name)
      | throw (IO.userError ("missing promoted family " ++ name))
    let some recursor := psEnvironmentFindRecursor environment
        (psNameAppendStr (psRootName name) "rec")
      | throw (IO.userError ("missing promoted recursor " ++ name))
    ensure (family.numParams == parameters && family.numIndices == indices &&
      recursor.numParams == parameters && recursor.numIndices == indices &&
      recursor.numMotives == 1 && recursor.numMinors == minors)
      ("index promotion changed family/recursor telescope: " ++ name)
  let constructors : List (String × String × Nat × Nat × List Nat) := [
    ("CorePromoted", "intro", 1, 0, []),
    ("CoreParametric", "intro", 2, 1, []),
    ("CoreFixedChild", "leaf", 1, 0, []),
    ("CoreFixedChild", "next", 1, 1, [0]),
    ("CorePrefix", "make", 1, 0, []),
    ("CoreVarying", "zero", 0, 0, []),
    ("CoreVarying", "step", 0, 2, [1]),
    ("CoreOrder", "make", 0, 2, []),
    ("CoreChanging", "intro", 0, 2, [1])]
  for (family, name, parameters, fields, recursive) in constructors do
    let some constructor := psEnvironmentFindConstructor environment
        (psNameAppendStr (psRootName family) name)
      | throw (IO.userError "missing promoted constructor")
    ensure (constructor.numParams == parameters && constructor.numFields == fields &&
      constructor.recursiveFields == recursive)
      ("index promotion changed constructor/child positions: " ++ family ++ "." ++ name)

private def universeLeanSource : String :=
  "universe coreUniverseU coreUniverseUnused\ninductive CoreUniverseTypeBox where\n  | mk (A : Type)\ninductive CoreUniverseProofBox (P : Prop) where\n  | mk (proof : P)\nstructure CoreUniverseProofStructure (P : Prop) where\n  proof : P\ninductive CoreUniverseEmpty where\nstructure CoreUniverseEmptyStructure where\ninductive CoreUniverseTwoProofs (P Q : Prop) where\n  | left (proof : P)\n  | right (proof : Q)\ninductive CoreUniverseRecursiveProof (P : Prop) where\n  | wrap (child : CoreUniverseRecursiveProof P)\ninductive CoreUniverseLevel (A : Type coreUniverseU) where\n  | mk (value : A)\ninductive CoreUniverseSort (A : Sort coreUniverseU) where\n  | mk (value : A)\ninductive CoreUniversePromote : Type coreUniverseU → Sort _ where\n  | mk (A : Type coreUniverseU) : CoreUniversePromote A\ninductive CoreUniverseFixedSort (A : Type coreUniverseU) : Type _ where\n  | mk (value : A)\nstructure CoreUniverseBigStructure where\n  A : Type\n  value : A\ninductive CoreUniverseConstructorOnly where\n  | mk (A : Type coreUniverseU)\n"
private def universePsSource : String :=
  "universe coreUniverseU coreUniverseUnused\ninductive CoreUniverseTypeBox where { | mk(A: Type) }\ninductive CoreUniverseProofBox(P: Prop) where { | mk(proof: P) }\nstructure CoreUniverseProofStructure(P: Prop) where { proof: P }\ninductive CoreUniverseEmpty where {}\nstructure CoreUniverseEmptyStructure where {}\ninductive CoreUniverseTwoProofs(P: Prop, Q: Prop) where {\n  | left(proof: P)\n  | right(proof: Q)\n}\ninductive CoreUniverseRecursiveProof(P: Prop) where {\n  | wrap(child: CoreUniverseRecursiveProof(P))\n}\ninductive CoreUniverseLevel(A: Type coreUniverseU) where { | mk(value: A) }\ninductive CoreUniverseSort(A: Sort coreUniverseU) where { | mk(value: A) }\ninductive CoreUniversePromote: Type coreUniverseU -> Sort _ where {\n  | mk(A: Type coreUniverseU): CoreUniversePromote(A)\n}\ninductive CoreUniverseFixedSort(A: Type coreUniverseU): Type _ where { | mk(value: A) }\nstructure CoreUniverseBigStructure where {\n  A: Type\n  value: A\n}\ninductive CoreUniverseConstructorOnly where { | mk(A: Type coreUniverseU) }\n"

private def dataResultSort : PsExpr → Option PsLevel
  | .forallE _ _ body _ => dataResultSort body
  | .sortE level => some level
  | _ => none

private def checkUniverseMetadata (environment : PsEnvironment) : IO Unit := do
  let u := PsLevel.param (psRootName "coreUniverseU")
  let zero := PsLevel.zero
  let one := PsLevel.succ zero
  let two := PsLevel.succ one
  let cases : List (String × PsLevel × Nat) := [
    ("CoreUniverseTypeBox", two, 0),
    ("CoreUniverseProofBox", zero, 0),
    ("CoreUniverseProofStructure", zero, 0),
    ("CoreUniverseEmpty", one, 0),
    ("CoreUniverseEmptyStructure", one, 0),
    ("CoreUniverseTwoProofs", one, 0),
    ("CoreUniverseRecursiveProof", one, 0),
    ("CoreUniverseLevel", .succ u, 1),
    ("CoreUniverseSort", .max one u, 1),
    ("CoreUniversePromote", one, 1),
    ("CoreUniverseFixedSort", .succ u, 1),
    ("CoreUniverseBigStructure", two, 0),
    ("CoreUniverseConstructorOnly", .succ (.succ u), 1)]
  for (name, expected, levels) in cases do
    let some family := psEnvironmentFindInductive environment (psRootName name)
      | throw (IO.userError ("missing inferred data family " ++ name))
    let some actual := dataResultSort family.type
      | throw (IO.userError ("data family result is not a sort: " ++ name))
    ensure (psLevelEquivalent actual expected && family.levelParams.length == levels)
      ("data result-sort/universe roster differs from native: " ++ name)
    if levels == 1 then
      ensure (family.levelParams.all (psNameEq (psRootName "coreUniverseU")))
        ("data declaration retained an unused or incorrect universe: " ++ name)
  let some promoted := psEnvironmentFindInductive environment (psRootName "CoreUniversePromote")
    | throw (IO.userError "missing promoted universe family")
  ensure (promoted.numParams == 1 && promoted.numIndices == 0)
    "data universe fixture lost index promotion"

private def checkUniverseRefusals : IO Unit := do
  for (label, rule, leanText, psText) in [
      ("field-universe", "constructor field universe exceeds the inductive resulting universe",
        "inductive BadTypeBox : Type where\n  | mk (A : Type)\n",
        "inductive BadTypeBox: Type where { | mk(A: Type) }\n"),
      ("multiple-result-universes", "cannot infer inductive resulting universe with multiple metavariables",
        "inductive BadMax : Sort (max _ _) where\n  | mk (n : Nat)\n",
        "inductive BadMax: Sort (max _ _) where { | mk(n: Nat) }\n"),
      ("possibly-propositional-universe", "inductive resulting universe may be Prop under a level assignment",
        "universe u\ninductive BadSort : Sort u where\n  | mk (n : Nat)\n",
        "universe u\ninductive BadSort: Sort u where { | mk(n: Nat) }\n")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
      | .error (.elaboration (.data actual)) =>
        ensure (actual == rule) ("data universe refusal changed owner: " ++ label ++ ": " ++ actual)
      | .error error => throw (IO.userError ("data universe refusal changed phase: " ++
          label ++ ": " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError ("invalid data universe accepted: " ++ label))

private def checkPair (label leanText psText : String) :
    IO (List PsCompilerEnginePreparationOutput) := do
  let inputs := [(PsCompilerSourceKind.lean, leanText), (.proofScript, psText)]
  let elaborated ← inputs.mapM fun (kind, source) => do
    let program ← fromExcept (psCompilerParsePscv0 source kind)
    fromExcept ((psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program).mapError
      (fun error => label ++ ": " ++ psCompilerPscv0Error error))
  let [left, right] := elaborated | throw (IO.userError "missing paired elaboration")
  compareCheckedValues left.declarations right.declarations
  if label == "promotion" then
    checkPromotionMetadata left.environment
    checkPromotionMetadata right.environment
  if label == "universes" then
    checkUniverseMetadata left.environment
    checkUniverseMetadata right.environment
  elaborated.mapM fun value => do
    let output ← fromExcept ((psCompilerEnginePrepareElaboratedWithOutput value).mapError psCompilerPscv0Error)
    let _ ← fromExcept ((← PsKernelLean.admitCanonicalAdmissions output.admissions).mapError (·.message))
    let ir ← fromExcept ((psCompilerEngineVerifiedIrFromPrepared output.prepared).mapError psCompilerPscv0Error)
    let _ ← fromExcept (psWithCheckedIr psIrCheckDefaultOptions ir fun _ => pure ())
    return output

private def checkRefusals : IO Unit := do
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
    match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
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
      match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
      | .error (.elaboration cause) =>
        ensure (matchPolicyTypeFailure cause)
          (label ++ " lost its type-checking refusal: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " was accepted"))
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
      match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
      | .error (.elaboration cause) =>
        ensure (wfBoundaryDecreaseFailure cause)
          (label ++ " lost its WF decrease refusal: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " failed outside elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " accepted an unrefined decrease proof"))


private def sourcePairs : List (String × String × String) := [
  ("match", matchLeanSource, matchPsSource),
  ("matchPolicy", matchPolicyLeanSource, matchPolicyPsSource),
  ("matchLexical", matchLexicalLeanSource, matchLexicalPsSource),
  ("matchIndexed", matchIndexedLeanSource, matchIndexedPsSource),
  ("structural", structuralLeanSource, structuralPsSource),
  ("inline", inlineLeanSource, inlinePsSource),
  ("wfBoundary", wfBoundaryLeanSource, wfBoundaryPsSource),
  ("promotion", promotionLeanSource, promotionPsSource),
  ("universes", universeLeanSource, universePsSource)]

private def checkRuntime (root : System.FilePath) : IO Unit := do
  let native := sourcePairs.foldl (fun acc (_, leanText, _) => acc ++ leanText ++ "\n") ""
  let proofscript := sourcePairs.foldl (fun acc (_, _, psText) => acc ++ psText ++ "\n") ""
  let sources := [(PsCompilerSourceKind.lean, native, "lean"),
    (.proofScript, proofscript, "ps")]
  let requests := sources.map fun (kind, source, stem) => ({
    sourceKind := kind, source, sourceName := "corematches" ++ psCompilerSourceKindExtension kind
    outputStem := "corematches"
    exports := .selected ["m3matches", "m3structural", "m3const", "m3inline", "m3wfboundaries"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] } : PsV7Native.Request)
  let batch ← match ← PsV7Native.runBatch requests.toArray with
    | .ok result => pure result
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == 2) "CORE-MATCHES: runtime omitted a paired source"
  for ((_, source, stem), result) in sources.zip batch.results.toList do
    let result ← match result with
      | .ok value => pure value
      | .error error => throw (IO.userError ("CORE-MATCHES runtime " ++ stem ++ ": " ++
          error.phase ++ ": " ++ error.message))
    ensure (result.artifacts.length == 5) "CORE-MATCHES: missing requested target"
    let directory := root / stem
    IO.FS.createDirAll directory
    IO.FS.writeFile (directory / "source.txt") source
    for artifact in result.artifacts do
      for file in artifact.files do
        match file.payload with
        | .text value => IO.FS.writeFile (directory / file.path) value
        | .binary value => IO.FS.writeBinFile (directory / file.path) value
    let rows := [false, true].map fun flag => Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
      ("m3matches", Lean.toJson (toString (CoreM3MatchOracle.m3matches flag).toNat)),
      ("m3structural", Lean.toJson (toString (CoreM3MatchOracle.m3structural flag).toNat)),
      ("m3const", Lean.toJson (toString (CoreM3MatchOracle.m3const flag).toNat)),
      ("m3inline", Lean.toJson (toString (CoreM3MatchOracle.m3inline flag).toNat)),
      ("m3wfboundaries", Lean.toJson (toString (CoreM3MatchOracle.m3wfboundaries flag).toNat))]
    IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
    IO.println ("CORE-MATCHES native observations " ++ stem ++ ": " ++
      (Lean.Json.arr rows.toArray).compress)
end CoreM3Matches

open CoreM3Matches in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  let root := System.FilePath.mk directory
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "CORE-MATCHES: expected pinned Lean 4.35.0"
  let _ ← fromExcept psCompilerValidatePscv0Standard
  checkCoreBoundaryControls
  for (label, leanText, psText) in sourcePairs do
    let outputs ← checkPair label leanText psText
    for (output, stem) in outputs.zip ["lean", "ps"] do
      let directory := root / "pairs" / label / stem
      IO.FS.createDirAll directory
      IO.FS.writeFile (directory / "admissions.jsonl") output.admissions
    IO.println ("CORE-MATCHES: checked pair " ++ label)
  checkRefusals
  checkUniverseRefusals
  checkRuntime root
  IO.println "PSCV0_CORE_MATCHES: PASS 9 independent source pairs; native positive/refusal oracle; checked declaration parity; fresh trust-zero admission per reader; checked IR; 46 owned portable refusals; five-target paired emission; native runtime comparison follows"
