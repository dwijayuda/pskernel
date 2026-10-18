import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Native function eta and the exact Nat dictionary conversion are checked
-- independently of the portable synthesizer.
example (f : Nat → Nat) : (fun n => f n) = f := rfl
example : (show BEq Nat from ⟨Nat.beq⟩) =
    @instBEqOfDecidableEq Nat instDecidableEqNat := rfl
example : True := by
  fail_if_success
    have : (show BEq Nat from ⟨fun _ _ => false⟩) =
        @instBEqOfDecidableEq Nat instDecidableEqNat := rfl
  exact True.intro

example (h : Option.some (Nat.succ 0) = Option.some 1) :
    @Eq.rec (Option Nat) (Option.some (Nat.succ 0))
      (fun _ _ => Nat) 7 (Option.some 1) h = 7 := rfl

-- Independent pinned Lean deriving. These ordinary native declarations are
-- never substituted for the portable group AST or its generated instances.
-- Names are identical so Repr parity compares the complete printed document.
universe u
mutual
  inductive M3DeriveTree (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | node (children : M3DeriveForest A a)
    deriving Hashable, Repr, BEq
  inductive M3DeriveForest (A : Type u) (a : A) : Type u where
    | nil
    | cons (head : M3DeriveTree A a) (tail : M3DeriveForest A a)
    deriving Hashable, Repr, BEq
end

mutual
  inductive M3DeriveIndexedLeft (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | node (n : Nat) (next : M3DeriveIndexedRight A a n)
    deriving Hashable, Repr
  inductive M3DeriveIndexedRight (A : Type u) (a : A) : Nat → Type u where
    | stop : M3DeriveIndexedRight A a 0
    | step (n : Nat) (head : M3DeriveIndexedLeft A a)
        (tail : M3DeriveIndexedRight A a n) : M3DeriveIndexedRight A a (Nat.succ n)
    deriving Hashable, Repr
end

deriving instance BEq for M3DeriveIndexedLeft
deriving instance BEq for M3DeriveIndexedRight
deriving instance DecidableEq for M3DeriveIndexedLeft
deriving instance DecidableEq for M3DeriveIndexedRight

def m3GroupIndexedZero : M3DeriveIndexedLeft Nat 0 :=
  M3DeriveIndexedLeft.node 0 M3DeriveIndexedRight.stop
def m3GroupIndexedRight : M3DeriveIndexedRight Nat 0 1 :=
  M3DeriveIndexedRight.step 0 (M3DeriveIndexedLeft.leaf 5) M3DeriveIndexedRight.stop
def m3GroupIndexedRightChanged : M3DeriveIndexedRight Nat 0 1 :=
  M3DeriveIndexedRight.step 0 (M3DeriveIndexedLeft.leaf 6) M3DeriveIndexedRight.stop
def m3GroupIndexedOne : M3DeriveIndexedLeft Nat 0 :=
  M3DeriveIndexedLeft.node 1 m3GroupIndexedRight
def m3GroupIndexedChanged : M3DeriveIndexedLeft Nat 0 :=
  M3DeriveIndexedLeft.node 1 m3GroupIndexedRightChanged
def m3GroupIndexedLeaf : M3DeriveIndexedLeft Nat 0 := M3DeriveIndexedLeft.leaf 5

-- Pinned native BEq uses partial auxiliary methods for a mutual family.
-- Observe these methods by execution; the portable equations remain kernel checked.
def m3GroupIndexedBEqSame : Bool := m3GroupIndexedOne == m3GroupIndexedOne
theorem m3GroupIndexedDecEqSame : Decidable.decide (self := decEq m3GroupIndexedOne m3GroupIndexedOne) = true := by rfl

def m3GroupIndexedBEqIndex : Bool := m3GroupIndexedZero == m3GroupIndexedOne
theorem m3GroupIndexedDecEqIndex : Decidable.decide (self := decEq m3GroupIndexedZero m3GroupIndexedOne) = false := by rfl

def m3GroupIndexedBEqField : Bool := m3GroupIndexedOne == m3GroupIndexedChanged
theorem m3GroupIndexedDecEqField : Decidable.decide (self := decEq m3GroupIndexedOne m3GroupIndexedChanged) = false := by rfl

def m3GroupIndexedBEqCtor : Bool := m3GroupIndexedOne == m3GroupIndexedLeaf
theorem m3GroupIndexedDecEqCtor : Decidable.decide (self := decEq m3GroupIndexedOne m3GroupIndexedLeaf) = false := by rfl

def m3GroupIndexedBEqRightSame : Bool := m3GroupIndexedRight == m3GroupIndexedRight
theorem m3GroupIndexedDecEqRightSame : Decidable.decide (self := decEq m3GroupIndexedRight m3GroupIndexedRight) = true := by rfl

def m3GroupIndexedBEqRightField : Bool := m3GroupIndexedRight == m3GroupIndexedRightChanged
theorem m3GroupIndexedDecEqRightField : Decidable.decide (self := decEq m3GroupIndexedRight m3GroupIndexedRightChanged) = false := by rfl

-- The nonindexed member has an inhabited leaf. The indexed member has only
-- zero/successor results, so native constructor-directed defaults cannot
-- produce a value uniformly at an arbitrary rigid index.
deriving instance Inhabited for M3DeriveIndexedLeft

example {A : Type u} [Inhabited A] {a : A} :
    (default : M3DeriveIndexedLeft A a) = .leaf default := rfl

/-- error: failed to generate `Inhabited` instance for `M3DeriveIndexedRight` -/
#guard_msgs (error, drop warning, substring := true) in
deriving instance Inhabited for M3DeriveIndexedRight

inductive M3DeriveSourceIndexed : Nat → Type where
  | zero : M3DeriveSourceIndexed 0
  | step (n : Nat) : M3DeriveSourceIndexed (Nat.succ n)
  deriving Hashable, Repr

example (n : Nat) : hash (M3DeriveSourceIndexed.step n) =
    mixHash (UInt64.ofNat 1) (hash n) := rfl

inductive M3DeriveAtom where
  | atom (flag : Bool)

-- A BEq dictionary need not be reflexive. The generated recursive method must
-- still call this dictionary when the two complete values are identical.
instance : BEq M3DeriveAtom where
  beq _ _ := false

universe dataU dataV

inductive M3DataBox (A : Sort dataU) where
  | pack (value : A)
inductive M3DataEnum where
  | zero
  | one
structure M3DataProof (p : Prop) where
  witness : p
inductive M3DataUnused (A : Type dataU) where
  | pack (value : A)
inductive M3DataCtorUniverse where
  | pack (A : Type dataU) (value : A)
inductive M3DataPoly (A : Type _) where
  | pack (value : A)
inductive M3DataFieldSort : Type 1 where
  | pack (A : Type _) (value : A)
inductive M3DataUnitField : Type where
  | pack (value : PUnit)

inductive M3DataPromoted : Nat → Type where
  | intro (n : Nat) (value : Fin n) : M3DataPromoted n
  deriving Hashable, Repr, BEq
inductive M3DataDependent : Nat → Type where
  | stop : M3DataDependent 0
  | intro (n : Nat) (value : Fin n) : M3DataDependent n
  deriving Hashable, Repr
structure M3DataRecord where
  n : Nat
  value : Fin n
  deriving Hashable, Repr
inductive M3DataFixed : Nat → Type where
  | leaf (n : Nat) : M3DataFixed n
  | step (n : Nat) (tail : M3DataFixed n) : M3DataFixed n
  deriving Hashable, Repr
inductive M3DataChanging : Nat → Type where
  | start (n : Nat) : M3DataChanging n
  | next (n : Nat) (tail : M3DataChanging n) : M3DataChanging (Nat.succ n)
  deriving Hashable, Repr
inductive M3DataSecond : Bool → Nat → Type where
  | flag (n : Nat) : M3DataSecond true n

def m3DataParameter (n : Nat) (value : M3DataPromoted n) : Nat :=
  match value with
  | M3DataPromoted.intro n payload => payload.val

def m3DataNested (n : Nat) (value : M3DataPromoted n) : Nat :=
  match value with
  | .intro _ (.mk 0 _) => 0
  | .intro _ (.mk (Nat.succ k) _) => Nat.succ k

def m3DataDepth (n : Nat) (value : M3DataFixed n) : Nat :=
  match value with
  | .leaf _ => 0
  | .step _ tail => Nat.succ (m3DataDepth n tail)

section
variable (seed : Nat)
def m3DataPatternCapture : Nat :=
  match M3DataFixed.leaf _ with
  | M3DataFixed.leaf seed => 7
  | M3DataFixed.step seed _ => 9
end

theorem m3DataHashPromoted (n : Nat) (value : Fin n) :
    hash (M3DataPromoted.intro n value) = mixHash (UInt64.ofNat 0) (hash value) := by rfl
theorem m3DataHashDependent (n : Nat) (value : Fin n) :
    hash (M3DataDependent.intro n value) =
      mixHash (mixHash (UInt64.ofNat 1) (hash n)) (hash value) := by rfl
theorem m3DataHashRecord (n : Nat) (value : Fin n) :
    hash (M3DataRecord.mk n value) =
      mixHash (mixHash (UInt64.ofNat 0) (hash n)) (hash value) := by rfl
theorem m3DataPromotedBEq (n : Nat) (left right : Fin n) :
    (M3DataPromoted.intro n left == M3DataPromoted.intro n right) =
      (left == right) := by rfl
theorem m3DataParameterLaw (n : Nat) (value : Fin n) :
    m3DataParameter n (M3DataPromoted.intro n value) = value.val := by rfl
theorem m3DataPatternCaptureLaw (n : Nat) : m3DataPatternCapture n = 7 := by rfl

-- A real index remains because stop fixes zero. This cannot pass by promotion.
inductive M3BEqLast : Nat → Type where
  | stop : M3BEqLast 0
  | wrap (n : Nat) (value : Nat) : M3BEqLast n
  deriving BEq
theorem m3BEqLastLaw (n left right : Nat) :
    (M3BEqLast.wrap n left == M3BEqLast.wrap n right) = (left == right) := by rfl

example (A : Sort dataU) : Sort (max 1 dataU) := M3DataBox A
example : Type := M3DataEnum
example (p : Prop) : Prop := M3DataProof p
example (A : Type dataU) : Type dataU := M3DataUnused A
example : Type (dataU + 1) := M3DataCtorUniverse.{dataU}
example (A : Type) (value : A) : M3DataFieldSort := .pack A value

example (n : Nat) (left right : Fin n) :
    (left == right) = Nat.beq left.val right.val := rfl
example (n : Nat) :
    (inferInstance : BEq (Fin n)) =
      ⟨fun left right => Nat.beq left.val right.val⟩ := rfl
example (n : Nat) (value : Fin n) (prec : Nat) :
    reprPrec value prec = reprPrec value.val 0 := rfl

run_cmd do
  let environment ← Lean.getEnv
  for (name, parameters, indices) in [
      (``M3DataBox, 1, 0), (``M3DataEnum, 0, 0), (``M3DataProof, 1, 0),
      (``M3DataUnused, 1, 0), (``M3DataCtorUniverse, 0, 0),
      (``M3DataPoly, 1, 0), (``M3DataFieldSort, 0, 0), (``M3DataUnitField, 0, 0),
      (``M3DataPromoted, 1, 0), (``M3DataDependent, 0, 1),
      (``M3DataRecord, 0, 0), (``M3DataFixed, 1, 0),
      (``M3DataChanging, 0, 1), (``M3DataSecond, 0, 2), (``M3BEqLast, 0, 1)] do
    let some (.inductInfo info) := environment.find? name
      | throwError "native Data family missing: {name}"
    unless info.numParams == parameters && info.numIndices == indices do
      throwError "native Data promotion metadata differs: {name}"
  for (name, parameters, fields) in [
      (``M3DataPromoted.intro, 1, 1), (``M3DataDependent.intro, 0, 2),
      (``M3DataFixed.leaf, 1, 0), (``M3DataFixed.step, 1, 1),
      (``M3DataChanging.start, 0, 1), (``M3DataChanging.next, 0, 2),
      (``M3DataSecond.flag, 0, 1)] do
    let some (.ctorInfo info) := environment.find? name
      | throwError "native Data constructor missing: {name}"
    unless info.numParams == parameters && info.numFields == fields do
      throwError "native Data constructor metadata differs: {name}"
  for name in [``M3DataBox, ``M3DataUnused, ``M3DataCtorUniverse] do
    let some info := environment.find? name | throwError "native universe control missing"
    unless info.levelParams == [`dataU] do
      throwError "native unused universe was retained: {name}"
  let some info := environment.find? ``M3DataPoly
    | throwError "native implicit universe control missing"
  unless info.levelParams.length == 1 do
    throwError "native implicit header universe was not generalized once"

inductive IndexedSucc : Nat → Type where
  | intro (n : Nat) : IndexedSucc (Nat.succ n)
  deriving BEq
example (n : Nat) : (IndexedSucc.intro n == IndexedSucc.intro n) = true := rfl
inductive IndexedPayload : Nat → Type where
  | intro (n : Nat) (value : Fin n) : IndexedPayload n
  deriving BEq
example (n : Nat) (left right : Fin n) :
    (IndexedPayload.intro n left == IndexedPayload.intro n right) =
      (left == right) := rfl

/-- error: Failed to infer universe levels in type of binder -/
#guard_msgs (error, drop warning, substring := true) in
inductive M3DataAmbiguous : Type 1 where
  | pack (value : PUnit)

/-- error: Invalid universe polymorphic resulting type -/
#guard_msgs (error, drop warning, substring := true) in
inductive M3DataPropRisk (A : Sort dataU) : Sort dataU where
  | pack (value : A)

/-- error: Invalid universe level for field -/
#guard_msgs (error, drop warning, substring := true) in
structure M3DataTooSmall : Type where
  A : Type

/-- error: failed to synthesize -/
#guard_msgs (error, drop warning, substring := true) in
inductive M3DataMissingHash where
  | pack (value : Nat → Nat)
  deriving Hashable

/-- error: failed to synthesize -/
#guard_msgs (error, drop warning, substring := true) in
inductive M3DataMissingRepr where
  | pack (value : Nat → Nat)
  deriving Repr

namespace M3DataUnaryOracle

def payload (flag : Bool) : Nat := if flag then 71 else 13
def precedence (flag : Bool) : Nat := if flag then 1024 else 0
def fin (n : Nat) : Fin (Nat.succ n) := ⟨n, Nat.lt_succ_self n⟩
def zero (n : Nat) : Fin (Nat.succ n) := ⟨0, Nat.succ_le_succ (Nat.zero_le n)⟩
def fixed (n : Nat) : M3DataFixed n :=
  .step n (.step n (.leaf n))
def changing (n : Nat) : M3DataChanging (Nat.succ (Nat.succ n)) :=
  .next (Nat.succ n) (.next n (.start n))

def hashOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let bound := Nat.succ n
  mixHash (hash (M3DataPromoted.intro bound (fin n)))
    (mixHash (hash (M3DataDependent.intro bound (fin n)))
      (mixHash (hash (M3DataRecord.mk bound (fin n)))
        (mixHash (hash (fixed bound)) (hash (changing n)))))

def promotedText (flag : Bool) : String :=
  Std.Format.pretty (reprPrec (M3DataPromoted.intro (Nat.succ (payload flag))
    (fin (payload flag))) (precedence flag)) 40
def dependentText (flag : Bool) : String :=
  Std.Format.pretty (reprPrec (M3DataDependent.intro (Nat.succ (payload flag))
    (fin (payload flag))) (precedence flag)) 40
def recordText (flag : Bool) : String :=
  Std.Format.pretty (reprPrec (M3DataRecord.mk (Nat.succ (payload flag))
    (fin (payload flag))) (precedence flag)) 40
def fixedText (flag : Bool) : String :=
  Std.Format.pretty (reprPrec (fixed (Nat.succ (payload flag))) (precedence flag)) 40
def changingText (flag : Bool) : String :=
  Std.Format.pretty (reprPrec (changing (payload flag)) (precedence flag)) 40

def reprOutput (_flag : Bool) : UInt64 := 31

def patternOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let bound := Nat.succ n
  let value := M3DataPromoted.intro bound (fin n)
  UInt64.ofNat (m3DataParameter bound value + m3DataNested bound value +
    m3DataDepth bound (fixed bound) + m3DataPatternCapture bound)

def beqOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let x := M3DataPromoted.intro (Nat.succ n) (fin n)
  let y := M3DataPromoted.intro (Nat.succ n) (zero n)
  UInt64.ofNat ((if x == x then 1 else 0) + (if x == y then 2 else 0) +
    (if y == x then 4 else 0) + (if y == y then 8 else 0))

end M3DataUnaryOracle

namespace M3InductiveDerivingOracle

def forest (n m : Nat) : M3DeriveForest Nat 0 :=
  .cons (.leaf n) (.cons (.node (.cons (.leaf m) .nil)) .nil)

def tree (n m : Nat) : M3DeriveTree Nat 0 := .node (forest n m)

def indexedRight (n : Nat) : M3DeriveIndexedRight Nat 0 2 :=
  .step 1 (.leaf n) (.step 0 (.node 0 .stop) .stop)

def indexedLeft (n : Nat) : M3DeriveIndexedLeft Nat 0 :=
  .node 2 (indexedRight n)

def payload (flag : Bool) : Nat := if flag then 71 else 13
def precedence (flag : Bool) : Nat := if flag then 1024 else 0

def hashOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  mixHash (hash (tree n (n + 1))) (hash (forest n (n + 1)))

def treeText (flag : Bool) : String :=
  let n := payload flag
  (reprPrec (tree n (n + 1)) (precedence flag)).pretty 40

def forestText (flag : Bool) : String :=
  let n := payload flag
  (reprPrec (forest n (n + 1)) (precedence flag)).pretty 40

def eqBits (a b c d e f g : Bool) : UInt64 :=
  UInt64.ofNat ((if a then 1 else 0) + (if b then 2 else 0) +
    (if c then 4 else 0) + (if d then 8 else 0) + (if e then 16 else 0) +
    (if f then 32 else 0) + (if g then 64 else 0))

def beqOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let last := if flag then n + 1 else n + 2
  let x := tree n (n + 1)
  let y := tree n last
  let xs := forest n (n + 1)
  let ys := forest n last
  let zs := forest (n + 1) (n + 1)
  eqBits (x == x) (x == y) (y == x) (x == .leaf n) (.leaf n == x)
    (xs == ys) (xs == zs)

def atomOutput (flag : Bool) : UInt64 :=
  let x : M3DeriveTree M3DeriveAtom (.atom false) :=
    .node (.cons (.leaf (.atom flag)) .nil)
  if x == x then 0 else 1

def indexedHashOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  mixHash (hash (indexedLeft n)) (hash (indexedRight n))

def indexedLeftText (flag : Bool) : String :=
  (reprPrec (indexedLeft (payload flag)) (precedence flag)).pretty 40

def indexedRightText (flag : Bool) : String :=
  (reprPrec (indexedRight (payload flag)) (precedence flag)).pretty 40

end M3InductiveDerivingOracle

-- The index dictionary is deliberately nonreflexive. Derived comparison must
-- omit direct index fields while still calling a payload's actual dictionary.
inductive IndexedBEq : Nat → Type where
  | intro (n : Nat) : IndexedBEq n
  deriving BEq

inductive M3DeriveIndexedBEq (I A : Type) : I → Type where
  | first (index : I) (value : A) : M3DeriveIndexedBEq I A index
  | second (index : I) (value : A) : M3DeriveIndexedBEq I A index
  deriving BEq

run_cmd do
  let environment ← Lean.getEnv
  let some (.inductInfo family) := environment.find? ``M3DeriveIndexedBEq
    | throwError "native promoted BEq family missing"
  unless family.numParams == 3 && family.numIndices == 0 do
    throwError "native common value index was not promoted"
  let some info := environment.find? ``instBEqM3DeriveIndexedBEq
    | throwError "native promoted BEq instance missing"
  let .forallE _ iType
      (.forallE _ aType
        (.forallE _ indexType
          (.forallE _ iDictionary
            (.forallE _ aDictionary result .instImplicit) .instImplicit)
          .implicit) .implicit) .implicit := info.type
    | throwError "native promoted BEq instance does not have exactly five expected binders"
  unless !result.isForall && iType.isSort && aType.isSort &&
      indexType == Lean.Expr.bvar 1 &&
      iDictionary == Lean.mkApp (Lean.mkConst ``BEq [Lean.Level.zero]) (.bvar 2) &&
      aDictionary == Lean.mkApp (Lean.mkConst ``BEq [Lean.Level.zero]) (.bvar 2) do
    throwError "native promoted BEq instance changed its actual type/value requirements"

example (n : Nat) : (IndexedBEq.intro n == IndexedBEq.intro n) = true := rfl

example (index : M3DeriveAtom) (left right : Nat) :
    ((M3DeriveIndexedBEq.first index left : M3DeriveIndexedBEq M3DeriveAtom Nat index) ==
      M3DeriveIndexedBEq.first index right) = (left == right) := rfl

example (index : M3DeriveAtom) (left right : Bool) :
    ((M3DeriveIndexedBEq.second index left : M3DeriveIndexedBEq M3DeriveAtom Bool index) ==
      M3DeriveIndexedBEq.second index right) = (left == right) := rfl

namespace M3IndexedBEqOracle

def natOutput (flag : Bool) : UInt64 :=
  let index := M3DeriveAtom.atom flag
  let n : Nat := if flag then 71 else 13
  let x : M3DeriveIndexedBEq M3DeriveAtom Nat index := .first index n
  let y : M3DeriveIndexedBEq M3DeriveAtom Nat index :=
    .first index (if flag then n else n + 1)
  let other : M3DeriveIndexedBEq M3DeriveAtom Nat index := .second index n
  let payload : M3DeriveIndexedBEq Bool M3DeriveAtom flag := .first flag (.atom flag)
  M3InductiveDerivingOracle.eqBits (x == x) (x == y) (y == x)
    (x == other) (other == x) (other == other) (payload == payload)

def boolOutput (flag : Bool) : UInt64 :=
  let index := M3DeriveAtom.atom flag
  let x : M3DeriveIndexedBEq M3DeriveAtom Bool index := .first index flag
  let y : M3DeriveIndexedBEq M3DeriveAtom Bool index := .first index false
  let other : M3DeriveIndexedBEq M3DeriveAtom Bool index := .second index flag
  let payload : M3DeriveIndexedBEq Bool M3DeriveAtom flag := .second flag (.atom (!flag))
  M3InductiveDerivingOracle.eqBits (x == x) (x == y) (y == x)
    (x == other) (other == x) (other == other) (payload == payload)

example : natOutput false = 33 := rfl
example : natOutput true = 39 := rfl
example : boolOutput false = 39 := rfl
example : boolOutput true = 33 := rfl

end M3IndexedBEqOracle

namespace M3InductiveDeriving

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def dataTypesLeanSource : String :=
  "universe dataU dataV\n\ninductive M3DataBox (A : Sort dataU) where\n  | pack (value : A)\n\ninductive M3DataEnum where\n  | zero\n  | one\n\nstructure M3DataProof (p : Prop) where\n  witness : p\n\ninductive M3DataUnused (A : Type dataU) where\n  | pack (value : A)\n\ninductive M3DataCtorUniverse where\n  | pack (A : Type dataU) (value : A)\n\ninductive M3DataPoly (A : Type _) where\n  | pack (value : A)\n\ninductive M3DataFieldSort : Type 1 where\n  | pack (A : Type _) (value : A)\n\ninductive M3DataUnitField : Type where\n  | pack (value : PUnit)\n"

private def dataTypesPsSource : String :=
  "universe dataU dataV\n\ninductive M3DataBox(A: Sort dataU) where {\n  | pack(value: A)\n}\ninductive M3DataEnum where {\n  | zero\n  | one\n}\nstructure M3DataProof(p: Prop) where {\n  witness: p\n}\ninductive M3DataUnused(A: Type dataU) where {\n  | pack(value: A)\n}\ninductive M3DataCtorUniverse where {\n  | pack(A: Type dataU, value: A)\n}\ninductive M3DataPoly(A: Type _) where {\n  | pack(value: A)\n}\ninductive M3DataFieldSort: Type 1 where {\n  | pack(A: Type _, value: A)\n}\ninductive M3DataUnitField: Type where {\n  | pack(value: PUnit)\n}\n"

private def dataFinLeanSource : String :=
  "theorem m3DataFinBool (n : Nat) (left right : Fin n) :\n  (left == right) = Nat.beq left.val right.val := by rfl\n" ++
  "theorem m3DataFinRepr (n : Nat) (value : Fin n) (prec : Nat) :\n  Repr.reprPrec value prec = Repr.reprPrec value.val 0 := by rfl\n"

private def dataFinPsSource : String :=
  "theorem m3DataFinBool(n: Nat, left: Fin(n), right: Fin(n)):\n  (left == right) = Nat.beq(left.val, right.val) := by { rfl }\n" ++
  "theorem m3DataFinRepr(n: Nat, value: Fin(n), prec: Nat):\n  Repr.reprPrec(value, prec) = Repr.reprPrec(value.val, 0) := by { rfl }\n"

private def dataUnaryLeanSource : String :=
  "inductive M3DataPromoted : Nat → Type where\n  | intro (n : Nat) (value : Fin n) : M3DataPromoted n\n  deriving Hashable, Repr, BEq\n\ninductive M3DataDependent : Nat → Type where\n  | stop : M3DataDependent 0\n  | intro (n : Nat) (value : Fin n) : M3DataDependent n\n  deriving Hashable, Repr\n\nstructure M3DataRecord where\n  n : Nat\n  value : Fin n\n  deriving Hashable, Repr\n\ninductive M3DataFixed : Nat → Type where\n  | leaf (n : Nat) : M3DataFixed n\n  | step (n : Nat) (tail : M3DataFixed n) : M3DataFixed n\n  deriving Hashable, Repr\n\ninductive M3DataChanging : Nat → Type where\n  | start (n : Nat) : M3DataChanging n\n  | next (n : Nat) (tail : M3DataChanging n) : M3DataChanging (Nat.succ n)\n  deriving Hashable, Repr\n\ninductive M3DataSecond : Bool → Nat → Type where\n  | flag (n : Nat) : M3DataSecond true n\n\ndef m3DataParameter (n : Nat) (value : M3DataPromoted n) : Nat :=\n  match value with\n  | M3DataPromoted.intro n payload => payload.val\n\ndef m3DataNested (n : Nat) (value : M3DataPromoted n) : Nat :=\n  match value with\n  | .intro _ (.mk 0 _) => 0\n  | .intro _ (.mk (Nat.succ k) _) => Nat.succ k\n\ndef m3DataDepth (n : Nat) (value : M3DataFixed n) : Nat :=\n  match value with\n  | .leaf _ => 0\n  | .step _ tail => Nat.succ (m3DataDepth n tail)\n\nsection\nvariable (seed : Nat)\ndef m3DataPatternCapture : Nat :=\n  match M3DataFixed.leaf _ with\n  | M3DataFixed.leaf seed => 7\n  | M3DataFixed.step seed _ => 9\nend\n\ntheorem m3DataHashPromoted (n : Nat) (value : Fin n) :\n    Hashable.hash (M3DataPromoted.intro n value) = mixHash (UInt64.ofNat 0) (Hashable.hash value) := by rfl\ntheorem m3DataHashDependent (n : Nat) (value : Fin n) :\n    Hashable.hash (M3DataDependent.intro n value) =\n      mixHash (mixHash (UInt64.ofNat 1) (Hashable.hash n)) (Hashable.hash value) := by rfl\ntheorem m3DataHashRecord (n : Nat) (value : Fin n) :\n    Hashable.hash (M3DataRecord.mk n value) =\n      mixHash (mixHash (UInt64.ofNat 0) (Hashable.hash n)) (Hashable.hash value) := by rfl\ntheorem m3DataPromotedBEq (n : Nat) (left right : Fin n) :\n    (M3DataPromoted.intro n left == M3DataPromoted.intro n right) =\n      (left == right) := by rfl\ntheorem m3DataParameterLaw (n : Nat) (value : Fin n) :\n    m3DataParameter n (M3DataPromoted.intro n value) = value.val := by rfl\ntheorem m3DataPatternCaptureLaw (n : Nat) : m3DataPatternCapture n = 7 := by rfl\n\ninductive M3BEqLast : Nat → Type where\n  | stop : M3BEqLast 0\n  | wrap (n : Nat) (value : Nat) : M3BEqLast n\n  deriving BEq\ntheorem m3BEqLastLaw (n left right : Nat) :\n    (M3BEqLast.wrap n left == M3BEqLast.wrap n right) = (left == right) := by rfl\n"

private def dataUnaryPsSource : String :=
  "inductive M3DataPromoted: Nat -> Type where {\n  | intro(n: Nat, value: Fin(n)): M3DataPromoted(n)\n} deriving Hashable, Repr, BEq\n\ninductive M3DataDependent: Nat -> Type where {\n  | stop: M3DataDependent(0)\n  | intro(n: Nat, value: Fin(n)): M3DataDependent(n)\n} deriving Hashable, Repr\n\nstructure M3DataRecord where {\n  n: Nat\n  value: Fin(n)\n} deriving Hashable, Repr\n\ninductive M3DataFixed: Nat -> Type where {\n  | leaf(n: Nat): M3DataFixed(n)\n  | step(n: Nat, tail: M3DataFixed(n)): M3DataFixed(n)\n} deriving Hashable, Repr\n\ninductive M3DataChanging: Nat -> Type where {\n  | start(n: Nat): M3DataChanging(n)\n  | next(n: Nat, tail: M3DataChanging(n)): M3DataChanging(Nat.succ(n))\n} deriving Hashable, Repr\n\ninductive M3DataSecond: Bool -> Nat -> Type where {\n  | flag(n: Nat): M3DataSecond(true, n)\n}\n\nfunction m3DataParameter(n: Nat, value: M3DataPromoted(n)): Nat :=\n  match value with {\n  | M3DataPromoted.intro n payload => payload.val\n  }\n\nfunction m3DataNested(n: Nat, value: M3DataPromoted(n)): Nat :=\n  match value with {\n  | .intro _ (.mk 0 _) => 0\n  | .intro _ (.mk (Nat.succ k) _) => Nat.succ(k)\n  }\n\nfunction m3DataDepth(n: Nat, value: M3DataFixed(n)): Nat :=\n  match value with {\n  | .leaf _ => 0\n  | .step _ tail => Nat.succ(m3DataDepth(n, tail))\n  }\n\nsection\nvariable (seed: Nat)\nconst m3DataPatternCapture: Nat :=\n  match M3DataFixed.leaf(_) with {\n  | M3DataFixed.leaf seed => 7\n  | M3DataFixed.step seed _ => 9\n  }\nend\n\ntheorem m3DataHashPromoted(n: Nat, value: Fin(n)):\n  Hashable.hash(M3DataPromoted.intro(n, value)) =\n    mixHash(UInt64.ofNat(0), Hashable.hash(value)) := by { rfl }\ntheorem m3DataHashDependent(n: Nat, value: Fin(n)):\n  Hashable.hash(M3DataDependent.intro(n, value)) =\n    mixHash(mixHash(UInt64.ofNat(1), Hashable.hash(n)), Hashable.hash(value)) := by { rfl }\ntheorem m3DataHashRecord(n: Nat, value: Fin(n)):\n  Hashable.hash(M3DataRecord.mk(n, value)) =\n    mixHash(mixHash(UInt64.ofNat(0), Hashable.hash(n)), Hashable.hash(value)) := by { rfl }\ntheorem m3DataPromotedBEq(n: Nat, left: Fin(n), right: Fin(n)):\n  (M3DataPromoted.intro(n, left) == M3DataPromoted.intro(n, right)) =\n    (left == right) := by { rfl }\ntheorem m3DataParameterLaw(n: Nat, value: Fin(n)):\n  m3DataParameter(n, M3DataPromoted.intro(n, value)) = value.val := by { rfl }\ntheorem m3DataPatternCaptureLaw(n: Nat): m3DataPatternCapture(n) = 7 := by { rfl }\n\ninductive M3BEqLast: Nat -> Type where {\n  | stop: M3BEqLast(0)\n  | wrap(n: Nat, value: Nat): M3BEqLast(n)\n} deriving BEq\ntheorem m3BEqLastLaw(n: Nat, left: Nat, right: Nat):\n  (M3BEqLast.wrap(n, left) == M3BEqLast.wrap(n, right)) = (left == right) := by { rfl }\n"

private def indexedBEqAcceptedSource : String :=
  "inductive IndexedSucc: Nat -> Type where { | intro(n: Nat): IndexedSucc(Nat.succ(n)) } deriving BEq\n" ++
  "theorem indexedSuccAccepted(n: Nat): (IndexedSucc.intro(n) == IndexedSucc.intro(n)) = true := by { rfl }\n" ++
  "inductive IndexedPayload: Nat -> Type where { | intro(n: Nat, value: Fin(n)): IndexedPayload(n) } deriving BEq\n" ++
  "theorem indexedPayloadAccepted(n: Nat, left: Fin(n), right: Fin(n)): (IndexedPayload.intro(n, left) == IndexedPayload.intro(n, right)) = (left == right) := by { rfl }\n"

private def dataElaborated (kind : PsCompilerSourceKind) (source : String) :
    IO (PsEnvironment × List PsDeclaration) := do
  let program ← fromExcept (psCompilerParsePscv0 source kind)
  let elaborated ← fromExcept ((psCompilerElaboratePscv0 program).mapError psCompilerPscv0Error)
  return (elaborated.environment, elaborated.declarations)

private def compareDataDeclarations (left right : List PsDeclaration) : IO Unit := do
  ensure (left.length == right.length) "Data source adapters changed the declaration count"
  for (left, right) in left.zip right do
    match left, right with
    | .definitionDecl ln ll lt lv, .definitionDecl rn rl rt rv
    | .theoremDecl ln ll lt lv, .theoremDecl rn rl rt rv
    | .opaqueDecl ln ll lt lv, .opaqueDecl rn rl rt rv
    | .partialDecl ln ll lt lv, .partialDecl rn rl rt rv =>
      ensure (psNameEq ln rn && psElabMutualLevelNamesEqual ll rl &&
        psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("Data source adapters changed checked value " ++ psNameToString ln)
    | .inductiveDecl l, .inductiveDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && l.numParams == r.numParams && l.numIndices == r.numIndices &&
        psElabMutualLevelNamesEqual l.constructors r.constructors && l.isStructure == r.isStructure)
        "Data source adapters changed an inductive family"
    | .constructorDecl l, .constructorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psNameEq l.inductiveName r.inductiveName &&
        l.constructorIndex == r.constructorIndex && l.numParams == r.numParams &&
        l.numFields == r.numFields && l.recursiveFields == r.recursiveFields)
        "Data source adapters changed constructor field metadata"
    | .recursorDecl l, .recursorDecl r =>
      ensure (psNameEq l.name r.name && psElabMutualLevelNamesEqual l.levelParams r.levelParams &&
        psExprAlphaEq l.type r.type && psElabMutualLevelNamesEqual l.inductiveNames r.inductiveNames &&
        l.numParams == r.numParams && l.numIndices == r.numIndices &&
        l.numMotives == r.numMotives && l.numMinors == r.numMinors)
        "Data source adapters changed a recursor telescope"
    | _, _ => throw (IO.userError "Data source adapters changed a checked declaration kind")

private def checkDataMetadata (environment : PsEnvironment) (unary : Bool) : IO Unit := do
  let families := if unary then
      [("M3DataPromoted", 1, 0), ("M3DataDependent", 0, 1), ("M3DataRecord", 0, 0),
       ("M3DataFixed", 1, 0), ("M3DataChanging", 0, 1), ("M3DataSecond", 0, 2),
       ("M3BEqLast", 0, 1)]
    else
      [("M3DataBox", 1, 0), ("M3DataEnum", 0, 0), ("M3DataProof", 1, 0),
       ("M3DataUnused", 1, 0), ("M3DataCtorUniverse", 0, 0),
       ("M3DataPoly", 1, 0), ("M3DataFieldSort", 0, 0), ("M3DataUnitField", 0, 0)]
  for (name, parameters, indices) in families do
    let some info := psEnvironmentFindInductive environment (psRootName name)
      | throw (IO.userError ("portable Data family missing: " ++ name))
    ensure (info.numParams == parameters && info.numIndices == indices)
      ("portable Data parameter/index metadata differs: " ++ name)
    ensure (!psExprHasUnresolvedMeta info.type && psExprFVarsInContext psLocalEmpty info.type)
      ("portable Data type retained a metavariable or local: " ++ name)
  if unary then
    for (name, parameters, fields, recursiveFields) in [
        ("M3DataPromoted.intro", 1, 1, []), ("M3DataDependent.intro", 0, 2, []),
        ("M3DataFixed.leaf", 1, 0, []), ("M3DataFixed.step", 1, 1, [0]),
        ("M3DataChanging.start", 0, 1, []), ("M3DataChanging.next", 0, 2, [1]),
        ("M3DataSecond.flag", 0, 1, [])] do
      let fullName := (name.splitOn ".").foldl psNameAppendStr .anonymous
      let some info := psEnvironmentFindConstructor environment fullName
        | throw (IO.userError ("portable Data constructor missing: " ++ name))
      ensure (info.numParams == parameters && info.numFields == fields &&
        info.recursiveFields == recursiveFields)
        ("portable Data field/recursive ordinal differs: " ++ name)
    let some promoted := psEnvironmentFindConstructor environment
        (psNameAppendStr (psRootName "M3DataPromoted") "intro")
      | throw (IO.userError "promoted constructor is absent")
    let .forallE _ _ _ binder := promoted.type
      | throw (IO.userError "promoted constructor lost its explicit source parameter")
    ensure (psBinderInfoEq binder .explicit)
      "promotion changed the original constructor binder metadata"
  else
    for name in ["M3DataBox", "M3DataUnused", "M3DataCtorUniverse"] do
      let some info := psEnvironmentFindInductive environment (psRootName name)
        | throw (IO.userError "portable Data universe control missing")
      ensure (psElabMutualLevelNamesEqual info.levelParams [psRootName "dataU"])
        ("portable Data retained an unused or temporary universe: " ++ name)
    let some poly := psEnvironmentFindInductive environment (psRootName "M3DataPoly")
      | throw (IO.userError "portable implicit universe control missing")
    ensure (poly.levelParams.length == 1)
      "portable implicit header universe was not generalized once"
    let u := PsLevel.param (psRootName "dataU")
    for (name, resultLevel) in [
        ("M3DataBox", PsLevel.max (.succ .zero) u),
        ("M3DataEnum", .succ .zero), ("M3DataProof", .zero),
        ("M3DataUnused", .succ u), ("M3DataCtorUniverse", .succ (.succ u)),
        ("M3DataFieldSort", .succ (.succ .zero)), ("M3DataUnitField", .succ .zero)] do
      let some info := psEnvironmentFindInductive environment (psRootName name)
        | throw (IO.userError "portable Data result universe control missing")
      let opened ← fromExcept ((psElabOpenCoreTelescope 4096
        (psElabContextEmpty environment info.levelParams) info.type none).mapError
          psCompilerPscv0ElabError)
      let .sortE actual := opened.body
        | throw (IO.userError "portable Data family did not end in a sort")
      ensure (psLevelEquivalent actual resultLevel)
        ("portable Data inferred a different result universe: " ++ name)
    let some fieldSort := psEnvironmentFindConstructor environment
        (psNameAppendStr (psRootName "M3DataFieldSort") "pack")
      | throw (IO.userError "portable constructor universe control missing")
    let .forallE _ (.sortE level) _ _ := fieldSort.type
      | throw (IO.userError "portable inferred constructor domain is not a sort")
    ensure (psLevelEquivalent level (.succ .zero))
      "portable constructor-only universe was not uniquely solved"

private def dataFailure (expected : String) : PsElabError → Bool
  | .atDeclaration _ cause => dataFailure expected cause
  | .atContext _ cause => dataFailure expected cause
  | .unresolvedMetavariable => expected == "unresolved constructor universe"
  | .data message => message == expected
  | _ => false

private def checkDataRefusals : IO Unit := do
  for (label, leanSource, psSource, expected) in [
      ("ambiguous constructor universe",
        "inductive M3DataAmbiguous : Type 1 where\n  | pack (value : PUnit)\n",
        "inductive M3DataAmbiguous: Type 1 where { | pack(value: PUnit) }\n",
        "unresolved constructor universe"),
      ("possibly Prop result",
        "universe dataU\ninductive M3DataPropRisk (A : Sort dataU) : Sort dataU where\n  | pack (value : A)\n",
        "universe dataU\ninductive M3DataPropRisk(A: Sort dataU): Sort dataU where { | pack(value: A) }\n",
        "inductive resulting universe may be Prop under a level assignment"),
      ("field above result universe",
        "structure M3DataTooSmall : Type where\n  A : Type\n",
        "structure M3DataTooSmall: Type where {\n A: Type\n}\n",
        "constructor field universe exceeds the inductive resulting universe"),
      ("missing function Hashable",
        "inductive M3DataMissingHash where\n  | pack (value : Nat → Nat)\n  deriving Hashable\n",
        "inductive M3DataMissingHash where { | pack(value: Nat -> Nat) } deriving Hashable\n",
        "deriving field has no checked instance"),
      ("missing function Repr",
        "inductive M3DataMissingRepr where\n  | pack (value : Nat → Nat)\n  deriving Repr\n",
        "inductive M3DataMissingRepr where { | pack(value: Nat -> Nat) } deriving Repr\n",
        "deriving field has no checked instance")] do
    for (kind, source) in [(PsCompilerSourceKind.lean, leanSource), (.proofScript, psSource)] do
      let program ← fromExcept (psCompilerParsePscv0 source kind)
      match psCompilerElaboratePscv0 program with
      | .error (.elaboration cause) =>
        ensure (dataFailure expected cause)
          (label ++ " refused at the wrong owner: " ++ psCompilerPscv0ElabError cause)
      | .error error =>
        throw (IO.userError (label ++ " escaped elaboration: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError (label ++ " was unexpectedly accepted"))

private def checkNestedK (environment : PsEnvironment) : IO Unit := do
  let nat := PsExpr.constE psNatName []
  let family := PsExpr.app (.constE (psRootName "Option") [.zero]) nat
  let someNat := fun value => psExprApplyMany
    (.constE (psNameAppendStr (psRootName "Option") "some") [.zero]) [nat, value]
  let left := someNat (.app (.constE psNatSuccName []) (.lit (.natural 0)))
  let make := fun (right : PsExpr) =>
    let proposition := psLogicEq (.succ .zero) family left right
    let proof := psLocalPushBinding psLocalEmpty (psRootName "arbitraryProof")
      proposition .explicit
    let motive := psLogicLam 1 "value" family
      (psLogicLam 2 "proof"
        (psLogicEq (.succ .zero) family left (.fvar 1)) nat)
    let term := psExprApplyMany (.constE (psNameAppendStr psEqName "rec")
      [.succ .zero, .succ .zero])
      [family, left, motive, .lit (.natural 7), right, .fvar proof.id]
    (proof.context, term)
  for (right, expected) in [(someNat (.lit (.natural 1)), true),
      (someNat (.lit (.natural 2)), false)] do
    let (locals, term) := make right
    let type ← fromExcept ((psInferType environment psMetaEmpty locals term).mapError
      (fun error => psCompilerPscv0ElabError (.infer error)))
    ensure (psDefEqReadOnlyWithEnv environment psMetaEmpty locals type nat)
      "nested K control has an invalid actual type"
    ensure (psDefEqReadOnlyWithEnv environment psMetaEmpty locals term
        (.lit (.natural 7)) == expected)
      "nested K conversion lost a constructor argument or failed valid nested conversion"

private def checkTypedFunctionEta (environment : PsEnvironment) : IO Unit := do
  let nat : PsExpr := .constE psNatName []
  let bool : PsExpr := .constE psBoolName []
  let method : PsExpr := .constE psNatBeqName []
  let expanded := PsExpr.lam (psRootName "left") nat
    (.lam (psRootName "right") nat
      (psExprApplyMany method [.bvar 1, .bvar 0]) .explicit) .explicit
  let changed := PsExpr.lam (psRootName "left") nat
    (.lam (psRootName "right") nat (.constE psBoolFalseName []) .explicit) .explicit
  let reversed := PsExpr.lam (psRootName "left") nat
    (.lam (psRootName "right") nat
      (psExprApplyMany method [.bvar 0, .bvar 1]) .explicit) .explicit
  let wrongDomain := PsExpr.lam (psRootName "left") bool
    (.lam (psRootName "right") nat (.constE psBoolFalseName []) .explicit) .explicit
  let infer := psInferType environment psMetaEmpty
  let compare := psDefEqReadOnlyWithTransparencyTyped .instances environment psMetaEmpty
    (fun _ _ _ => false) (psInferFunctionType infer environment psMetaEmpty) 256 psLocalEmpty
  for (label, left, right, expected) in [
      ("eta forward", method, expanded, true),
      ("eta reverse", expanded, method, true),
      ("changed method", method, changed, false),
      ("argument permutation", method, reversed, false),
      ("domain mismatch", method, wrongDomain, false)] do
    let _ ← fromExcept ((infer psLocalEmpty left).mapError
      (fun _ => "eta control left is not typed: " ++ label))
    let _ ← fromExcept ((infer psLocalEmpty right).mapError
      (fun _ => "eta control right is not typed: " ++ label))
    let unified := psUnifyWithTransparency .instances environment psLocalEmpty psMetaEmpty left right
    ensure (!unified.resourceExceeded && unified.success == expected)
      ("typed eta unification disagrees: " ++ label)
    ensure (compare left right == expected)
      ("typed eta read-only conversion disagrees: " ++ label)
  let source : PsExpr := .constE (psDecisionName "Nat.instLawfulBEq") []
  let sourceType ← fromExcept ((infer psLocalEmpty source).mapError
    (fun _ => "selected native Nat law has no checked type"))
  let selected : PsExpr := .constE (psDecisionName "PsStandard.instBEqNat") []
  let target := psExprApplyMany (.constE (psRootName "LawfulBEq") [.zero]) [nat, selected]
  let unified := psUnifyWithTransparency .instances environment psLocalEmpty psMetaEmpty
    sourceType target
  ensure (!unified.resourceExceeded && unified.success && compare sourceType target)
    "selected/native Nat law targets differ after typed function eta"
  let probe ← fromExcept ((psElabResolvedTerm (psElabContextEmpty environment [])
    source (some target)).mapError psCompilerPscv0ElabError)
  ensure (psExprAlphaEq probe.term source)
    "Nat lawful conversion substituted another proof identity"
  IO.println "PSCV0_M3_TYPED_FUNCTION_ETA: PASS native eta/dictionary equations; typed two-way eta, changed method/domain/order refusal and unchanged Nat lawful proof identity"

private def literal (value : String) : String := (Lean.toJson value).compress

private def dataRuntimeSource : String :=
  "function m3DataFin(n: Nat): Fin(Nat.succ(n)) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
  "function m3DataZero(n: Nat): Fin(Nat.succ(n)) := Fin.mk(0, Nat.succ_le_succ(Nat.zero_le(n)))\n" ++
  "function m3DataFixedValue(n: Nat): M3DataFixed(n) := M3DataFixed.step(n, M3DataFixed.step(n, M3DataFixed.leaf(n)))\n" ++
  "function m3DataChangingValue(n: Nat): M3DataChanging(Nat.succ(Nat.succ(n))) := M3DataChanging.next(Nat.succ(n), M3DataChanging.next(n, M3DataChanging.start(n)))\n" ++
  "function m3datahash(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let bound: Nat := Nat.succ(n)\n" ++
  " mixHash(Hashable.hash(M3DataPromoted.intro(bound, m3DataFin(n))), mixHash(Hashable.hash(M3DataDependent.intro(bound, m3DataFin(n))), mixHash(Hashable.hash(M3DataRecord.mk(bound, m3DataFin(n))), mixHash(Hashable.hash(m3DataFixedValue(bound)), Hashable.hash(m3DataChangingValue(n))))))\n}\n" ++
  "function m3datarepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let bound: Nat := Nat.succ(n)\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let promotedExpected: String := if (flag) { " ++ literal (M3DataUnaryOracle.promotedText true) ++
    " } else { " ++ literal (M3DataUnaryOracle.promotedText false) ++ " }\n" ++
  " let dependentExpected: String := if (flag) { " ++ literal (M3DataUnaryOracle.dependentText true) ++
    " } else { " ++ literal (M3DataUnaryOracle.dependentText false) ++ " }\n" ++
  " let recordExpected: String := if (flag) { " ++ literal (M3DataUnaryOracle.recordText true) ++
    " } else { " ++ literal (M3DataUnaryOracle.recordText false) ++ " }\n" ++
  " let fixedExpected: String := if (flag) { " ++ literal (M3DataUnaryOracle.fixedText true) ++
    " } else { " ++ literal (M3DataUnaryOracle.fixedText false) ++ " }\n" ++
  " let changingExpected: String := if (flag) { " ++ literal (M3DataUnaryOracle.changingText true) ++
    " } else { " ++ literal (M3DataUnaryOracle.changingText false) ++ " }\n" ++
  " let promotedActual: String := Std.Format.pretty(Repr.reprPrec(M3DataPromoted.intro(bound, m3DataFin(n)), prec), 40, 0, 0)\n" ++
  " let dependentActual: String := Std.Format.pretty(Repr.reprPrec(M3DataDependent.intro(bound, m3DataFin(n)), prec), 40, 0, 0)\n" ++
  " let recordActual: String := Std.Format.pretty(Repr.reprPrec(M3DataRecord.mk(bound, m3DataFin(n)), prec), 40, 0, 0)\n" ++
  " let fixedActual: String := Std.Format.pretty(Repr.reprPrec(m3DataFixedValue(bound), prec), 40, 0, 0)\n" ++
  " let changingActual: String := Std.Format.pretty(Repr.reprPrec(m3DataChangingValue(n), prec), 40, 0, 0)\n" ++
  " UInt64.ofNat((if (promotedActual == promotedExpected) { 1 } else { 0 }) + (if (dependentActual == dependentExpected) { 2 } else { 0 }) + (if (recordActual == recordExpected) { 4 } else { 0 }) + (if (fixedActual == fixedExpected) { 8 } else { 0 }) + (if (changingActual == changingExpected) { 16 } else { 0 }))\n}\n" ++
  "function m3datapattern(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let bound: Nat := Nat.succ(n)\n" ++
  " let value: M3DataPromoted(bound) := M3DataPromoted.intro(bound, m3DataFin(n))\n" ++
  " UInt64.ofNat(m3DataParameter(bound, value) + m3DataNested(bound, value) + m3DataDepth(bound, m3DataFixedValue(bound)) + m3DataPatternCapture(bound))\n}\n" ++
  "function m3databeq(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let x: M3DataPromoted(Nat.succ(n)) := M3DataPromoted.intro(Nat.succ(n), m3DataFin(n))\n" ++
  " let y: M3DataPromoted(Nat.succ(n)) := M3DataPromoted.intro(Nat.succ(n), m3DataZero(n))\n" ++
  " UInt64.ofNat((if (x == x) { 1 } else { 0 }) + (if (x == y) { 2 } else { 0 }) + (if (y == x) { 4 } else { 0 }) + (if (y == y) { 8 } else { 0 }))\n}\n"

private def dataOutputCases : List (String × (Bool → UInt64)) :=
  [("m3datahash", M3DataUnaryOracle.hashOutput),
   ("m3datarepr", M3DataUnaryOracle.reprOutput),
   ("m3datapattern", M3DataUnaryOracle.patternOutput),
   ("m3databeq", M3DataUnaryOracle.beqOutput)]


-- The parser supplies existing single-declaration ASTs; the native group API
-- supplies their shared scope. This does not add mutual inductive source syntax.
-- The second header aliases dependent parameters A/a as B/b.
private def groupSource : String :=
  "universe u\n" ++
  "inductive M3DeriveTree(A: Type u, a: A): Type u where { | leaf(value: A) | node(children: M3DeriveForest(A, a)) }\n" ++
  "inductive M3DeriveForest(B: Type u, b: B): Type u where { | nil | cons(head: M3DeriveTree(B, b), tail: M3DeriveForest(B, b)) }\n"

private def indexedSource : String :=
  "universe u\n" ++
  "inductive M3DeriveIndexedLeft(A: Type u, a: A): Type u where { | leaf(value: A) | node(n: Nat, next: M3DeriveIndexedRight(A, a, n)) }\n" ++
  "inductive M3DeriveIndexedRight(B: Type u, b: B): Nat -> Type u where { | stop: M3DeriveIndexedRight(B, b, 0) | step(n: Nat, head: M3DeriveIndexedLeft(B, b), tail: M3DeriveIndexedRight(B, b, n)): M3DeriveIndexedRight(B, b, Nat.succ(n)) }\n"

private def indexedBEqSource : String :=
  "inductive IndexedBEq: Nat -> Type where { | intro(n: Nat): IndexedBEq n } deriving BEq\n" ++
  "theorem m3indexedBareEq(n: Nat): (IndexedBEq.intro(n) == IndexedBEq.intro(n)) = true := by { rfl }\n" ++
  "inductive M3DeriveAtom where { | atom(flag: Bool) }\n" ++
  "instance m3DeriveAtomBEq: BEq M3DeriveAtom where { beq(left: M3DeriveAtom, right: M3DeriveAtom): Bool := false }\n" ++
  "inductive M3DeriveIndexedBEq(I: Type, A: Type): I -> Type where { | first(index: I, value: A): M3DeriveIndexedBEq(I, A, index) | second(index: I, value: A): M3DeriveIndexedBEq(I, A, index) } deriving BEq\n" ++
  "theorem m3indexedNatLaw(index: M3DeriveAtom, left: Nat, right: Nat): ((M3DeriveIndexedBEq.first(index, left): M3DeriveIndexedBEq(M3DeriveAtom, Nat, index)) == M3DeriveIndexedBEq.first(index, right)) = (left == right) := by { rfl }\n" ++
  "theorem m3indexedBoolLaw(index: M3DeriveAtom, left: Bool, right: Bool): ((M3DeriveIndexedBEq.second(index, left): M3DeriveIndexedBEq(M3DeriveAtom, Bool, index)) == M3DeriveIndexedBEq.second(index, right)) = (left == right) := by { rfl }\n" ++
  "function m3IndexedBEqBits(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool, g: Bool): UInt64 := UInt64.ofNat((if (a) { 1 } else { 0 }) + (if (b) { 2 } else { 0 }) + (if (c) { 4 } else { 0 }) + (if (d) { 8 } else { 0 }) + (if (e) { 16 } else { 0 }) + (if (f) { 32 } else { 0 }) + (if (g) { 64 } else { 0 }))\n" ++
  "function m3indexedbeqnat(flag: Bool): UInt64 := {\n" ++
  " let index: M3DeriveAtom := M3DeriveAtom.atom(flag)\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let x: M3DeriveIndexedBEq(M3DeriveAtom, Nat, index) := M3DeriveIndexedBEq.first(index, n)\n" ++
  " let y: M3DeriveIndexedBEq(M3DeriveAtom, Nat, index) := M3DeriveIndexedBEq.first(index, if (flag) { n } else { n + 1 })\n" ++
  " let other: M3DeriveIndexedBEq(M3DeriveAtom, Nat, index) := M3DeriveIndexedBEq.second(index, n)\n" ++
  " let payload: M3DeriveIndexedBEq(Bool, M3DeriveAtom, flag) := M3DeriveIndexedBEq.first(flag, M3DeriveAtom.atom(flag))\n" ++
  " m3IndexedBEqBits(x == x, x == y, y == x, x == other, other == x, other == other, payload == payload)\n" ++
  "}\n" ++
  "function m3indexedbeqbool(flag: Bool): UInt64 := {\n" ++
  " let index: M3DeriveAtom := M3DeriveAtom.atom(flag)\n" ++
  " let x: M3DeriveIndexedBEq(M3DeriveAtom, Bool, index) := M3DeriveIndexedBEq.first(index, flag)\n" ++
  " let y: M3DeriveIndexedBEq(M3DeriveAtom, Bool, index) := M3DeriveIndexedBEq.first(index, false)\n" ++
  " let other: M3DeriveIndexedBEq(M3DeriveAtom, Bool, index) := M3DeriveIndexedBEq.second(index, flag)\n" ++
  " let payload: M3DeriveIndexedBEq(Bool, M3DeriveAtom, flag) := M3DeriveIndexedBEq.second(flag, M3DeriveAtom.atom(!flag))\n" ++
  " m3IndexedBEqBits(x == x, x == y, y == x, x == other, other == x, other == other, payload == payload)\n" ++
  "}\n"

private def logicalSource : String :=
  "theorem m3deriveHashLaw(n: Nat): Hashable.hash((M3DeriveTree.node(M3DeriveForest.cons(M3DeriveTree.leaf(n), M3DeriveForest.nil)) : M3DeriveTree(Nat, 0))) = mixHash(UInt64.ofNat(1), mixHash(mixHash(UInt64.ofNat(1), mixHash(UInt64.ofNat(0), Hashable.hash(n))), UInt64.ofNat(0))) := by { rfl }\n" ++
  "theorem m3deriveIndexedHashLaw(n: Nat): Hashable.hash((M3DeriveIndexedRight.step(0, M3DeriveIndexedLeft.leaf(n), M3DeriveIndexedRight.stop) : M3DeriveIndexedRight(Nat, 0, 1))) = mixHash(mixHash(mixHash(UInt64.ofNat(1), Hashable.hash((0 : Nat))), mixHash(UInt64.ofNat(0), Hashable.hash(n))), UInt64.ofNat(0)) := by { rfl }\n" ++
  "inductive M3DeriveSourceIndexed: Nat -> Type where { | zero: M3DeriveSourceIndexed(0) | step(n: Nat): M3DeriveSourceIndexed(Nat.succ(n)) } deriving Hashable, Repr\n" ++
  "theorem m3deriveSourceIndexedLaw(n: Nat): Hashable.hash(M3DeriveSourceIndexed.step(n)) = mixHash(UInt64.ofNat(1), Hashable.hash(n)) := by { rfl }\n"

private def runtimeSource : String :=
  "function m3DeriveForestValue(n: Nat, m: Nat): M3DeriveForest(Nat, 0) := M3DeriveForest.cons(M3DeriveTree.leaf(n), M3DeriveForest.cons(M3DeriveTree.node(M3DeriveForest.cons(M3DeriveTree.leaf(m), M3DeriveForest.nil)), M3DeriveForest.nil))\n" ++
  "function m3DeriveTreeValue(n: Nat, m: Nat): M3DeriveTree(Nat, 0) := M3DeriveTree.node(m3DeriveForestValue(n, m))\n" ++
  "function m3DeriveIndexedRightValue(n: Nat): M3DeriveIndexedRight(Nat, 0, 2) := M3DeriveIndexedRight.step(1, M3DeriveIndexedLeft.leaf(n), M3DeriveIndexedRight.step(0, M3DeriveIndexedLeft.node(0, M3DeriveIndexedRight.stop), M3DeriveIndexedRight.stop))\n" ++
  "function m3DeriveIndexedLeftValue(n: Nat): M3DeriveIndexedLeft(Nat, 0) := M3DeriveIndexedLeft.node(2, m3DeriveIndexedRightValue(n))\n" ++
  "function m3derivehash(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " mixHash(Hashable.hash(m3DeriveTreeValue(n, n + 1)), Hashable.hash(m3DeriveForestValue(n, n + 1)))\n}\n" ++
  "function m3deriverepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let treeExpected: String := if (flag) { " ++ literal (M3InductiveDerivingOracle.treeText true) ++
    " } else { " ++ literal (M3InductiveDerivingOracle.treeText false) ++ " }\n" ++
  " let forestExpected: String := if (flag) { " ++ literal (M3InductiveDerivingOracle.forestText true) ++
    " } else { " ++ literal (M3InductiveDerivingOracle.forestText false) ++ " }\n" ++
  " let treeActual: String := Std.Format.pretty(Repr.reprPrec(m3DeriveTreeValue(n, n + 1), prec), 40, 0, 0)\n" ++
  " let forestActual: String := Std.Format.pretty(Repr.reprPrec(m3DeriveForestValue(n, n + 1), prec), 40, 0, 0)\n" ++
  " UInt64.ofNat((if (treeActual == treeExpected) { 1 } else { 0 }) + (if (forestActual == forestExpected) { 2 } else { 0 }))\n}\n" ++
  "function m3DeriveEqBits(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool, g: Bool): UInt64 := UInt64.ofNat((if (a) { 1 } else { 0 }) + (if (b) { 2 } else { 0 }) + (if (c) { 4 } else { 0 }) + (if (d) { 8 } else { 0 }) + (if (e) { 16 } else { 0 }) + (if (f) { 32 } else { 0 }) + (if (g) { 64 } else { 0 }))\n" ++
  "function m3derivebeq(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let last: Nat := if (flag) { n + 1 } else { n + 2 }\n" ++
  " let x: M3DeriveTree(Nat, 0) := m3DeriveTreeValue(n, n + 1)\n" ++
  " let y: M3DeriveTree(Nat, 0) := m3DeriveTreeValue(n, last)\n" ++
  " let xs: M3DeriveForest(Nat, 0) := m3DeriveForestValue(n, n + 1)\n" ++
  " let ys: M3DeriveForest(Nat, 0) := m3DeriveForestValue(n, last)\n" ++
  " let zs: M3DeriveForest(Nat, 0) := m3DeriveForestValue(n + 1, n + 1)\n" ++
  " m3DeriveEqBits(x == x, x == y, y == x, x == M3DeriveTree.leaf(n), M3DeriveTree.leaf(n) == x, xs == ys, xs == zs)\n}\n" ++
  "inductive M3DeriveAtom where { | atom(flag: Bool) }\n" ++
  "instance m3DeriveAtomBEq: BEq M3DeriveAtom where { beq(left: M3DeriveAtom, right: M3DeriveAtom): Bool := false }\n" ++
  "function m3DeriveAtomProbe(flag: Bool): Bool := {\n" ++
  " let x: M3DeriveTree(M3DeriveAtom, M3DeriveAtom.atom(false)) := M3DeriveTree.node(M3DeriveForest.cons(M3DeriveTree.leaf(M3DeriveAtom.atom(flag)), M3DeriveForest.nil))\n" ++
  " x == x\n}\n" ++
  "function m3deriveatom(flag: Bool): UInt64 := if (m3DeriveAtomProbe(flag)) { UInt64.ofNat(0) } else { UInt64.ofNat(1) }\n" ++
  "function m3DeriveEqualityProbe(flag: Bool): Bool := m3DeriveForestValue(13, 14) == m3DeriveForestValue(13, if (flag) { 14 } else { 15 })\n" ++
  "function m3deriveindexedhash(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " mixHash(Hashable.hash(m3DeriveIndexedLeftValue(n)), Hashable.hash(m3DeriveIndexedRightValue(n)))\n}\n" ++
  "function m3deriveindexedrepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let leftExpected: String := if (flag) { " ++ literal (M3InductiveDerivingOracle.indexedLeftText true) ++
    " } else { " ++ literal (M3InductiveDerivingOracle.indexedLeftText false) ++ " }\n" ++
  " let rightExpected: String := if (flag) { " ++ literal (M3InductiveDerivingOracle.indexedRightText true) ++
    " } else { " ++ literal (M3InductiveDerivingOracle.indexedRightText false) ++ " }\n" ++
  " let leftActual: String := Std.Format.pretty(Repr.reprPrec(m3DeriveIndexedLeftValue(n), prec), 40, 0, 0)\n" ++
  " let rightActual: String := Std.Format.pretty(Repr.reprPrec(m3DeriveIndexedRightValue(n), prec), 40, 0, 0)\n" ++
  " UInt64.ofNat((if (leftActual == leftExpected) { 1 } else { 0 }) + (if (rightActual == rightExpected) { 2 } else { 0 }))\n}\n"

private def elaborateGroup (text : String) :
    Except String (PsElabDeclarationBatchResult × PsElabBatchOrigin) := do
  let parsed ← psPscv0ParseProgram text
  let sources := parsed.commands.filterMap fun command =>
    match command with
    | .declaration source => some source
    | _ => none
  let chunks ← sources.mapM fun source =>
    match source with
    | .inductiveDecl name params resultType constructors _ =>
      pure { name, params, resultType, constructors : PsElabInductiveSource }
    | _ => throw "deriving fixture expected native inductive members"
  let first :: _ := sources | throw "deriving fixture has no group source"
  let result ← (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks [psRootName "u"]).mapError
    psCompilerPscv0ElabError
  let origin := psElabBatchOriginAt 0 first (psElabStableMemberOrigins result.declarations 0) none
  return (result, origin)

private def add (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment :=
  fromExcept ((psAddDeclarationList environment declarations).mapError psCompilerPscv0ElabError)

private def derive (environment : PsEnvironment) (origin : PsElabBatchOrigin)
    (handlers : List String) : IO (List PsDeclaration) := do
  let families := origin.members.filterMap fun member =>
    match member.role with
    | .inductiveType | .structureType => some (psNameToString member.name)
    | _ => none
  let declarations ← fromExcept ((handlers.mapM fun handler =>
    (psElabDeriveGroupHandler environment origin
      { segments := [handler], span := origin.span }).mapError
      (.atContext ("deriving " ++ handler ++ " for " ++ String.intercalate ", " families))).mapError
      psCompilerPscv0ElabError)
  return declarations.flatten

private def register (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment := do
  let environment ← add environment declarations
  fromExcept ((declarations.foldlM (fun current declaration =>
    psElabRegisterInstance current (psDeclarationName declaration) 1000) environment).mapError
      psCompilerPscv0ElabError)

private def sourceResult (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)

private def indexedGroupBinarySource : String :=
  "const m3GroupIndexedZero: M3DeriveIndexedLeft(Nat, 0) :=\n  M3DeriveIndexedLeft.node(0, M3DeriveIndexedRight.stop)\nconst m3GroupIndexedRight: M3DeriveIndexedRight(Nat, 0, 1) :=\n  M3DeriveIndexedRight.step(0, M3DeriveIndexedLeft.leaf(5), M3DeriveIndexedRight.stop)\nconst m3GroupIndexedRightChanged: M3DeriveIndexedRight(Nat, 0, 1) :=\n  M3DeriveIndexedRight.step(0, M3DeriveIndexedLeft.leaf(6), M3DeriveIndexedRight.stop)\nconst m3GroupIndexedOne: M3DeriveIndexedLeft(Nat, 0) :=\n  M3DeriveIndexedLeft.node(1, m3GroupIndexedRight)\nconst m3GroupIndexedChanged: M3DeriveIndexedLeft(Nat, 0) :=\n  M3DeriveIndexedLeft.node(1, m3GroupIndexedRightChanged)\nconst m3GroupIndexedLeaf: M3DeriveIndexedLeft(Nat, 0) := M3DeriveIndexedLeft.leaf(5)\n\ntheorem m3GroupIndexedBEqSame: (m3GroupIndexedOne == m3GroupIndexedOne) = true := by { rfl }\ntheorem m3GroupIndexedDecEqSame: Decidable.decide(self := decEq(m3GroupIndexedOne, m3GroupIndexedOne)) = true := by { rfl }\n\ntheorem m3GroupIndexedBEqIndex: (m3GroupIndexedZero == m3GroupIndexedOne) = false := by { rfl }\ntheorem m3GroupIndexedDecEqIndex: Decidable.decide(self := decEq(m3GroupIndexedZero, m3GroupIndexedOne)) = false := by { rfl }\n\ntheorem m3GroupIndexedBEqField: (m3GroupIndexedOne == m3GroupIndexedChanged) = false := by { rfl }\ntheorem m3GroupIndexedDecEqField: Decidable.decide(self := decEq(m3GroupIndexedOne, m3GroupIndexedChanged)) = false := by { rfl }\n\ntheorem m3GroupIndexedBEqCtor: (m3GroupIndexedOne == m3GroupIndexedLeaf) = false := by { rfl }\ntheorem m3GroupIndexedDecEqCtor: Decidable.decide(self := decEq(m3GroupIndexedOne, m3GroupIndexedLeaf)) = false := by { rfl }\n\ntheorem m3GroupIndexedBEqRightSame: (m3GroupIndexedRight == m3GroupIndexedRight) = true := by { rfl }\ntheorem m3GroupIndexedDecEqRightSame: Decidable.decide(self := decEq(m3GroupIndexedRight, m3GroupIndexedRight)) = true := by { rfl }\n\ntheorem m3GroupIndexedBEqRightField: (m3GroupIndexedRight == m3GroupIndexedRightChanged) = false := by { rfl }\ntheorem m3GroupIndexedDecEqRightField: Decidable.decide(self := decEq(m3GroupIndexedRight, m3GroupIndexedRightChanged)) = false := by { rfl }\n"

private def checked (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonical declarations).mapError
    (fun _ => "canonical group deriving admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def checkIndexedLawfulRegistration (environment : PsEnvironment) : IO Unit := do
  let className := psRootName "LawfulBEq"
  ensure (environment.classes.any (psNameEq className))
    "indexed deriving lost the selected LawfulBEq class"
  let context := psElabContextEmpty environment []
  let nat : PsExpr := .constE psNatName []
  let dictionary : PsExpr := .constE (psDecisionName "PsStandard.instBEqNat") []
  let target := psExprApplyMany (.constE className [.zero]) [nat, dictionary]
  let evidence ← fromExcept (((psElabDeriveInstance context target).mapError
    (.atContext "indexed group selected Nat lawful probe")).mapError psCompilerPscv0ElabError)
  let _ ← fromExcept ((psElabResolvedTerm context evidence (some target)).mapError
    psCompilerPscv0ElabError)
  let falseDictionary := psExprApplyMany
    (.constE (psNameAppendStr (psRootName "BEq") "mk") [.zero])
    [nat, .lam (psRootName "left") nat
      (.lam (psRootName "right") nat (.constE psBoolFalseName []) .explicit) .explicit]
  let rejectedTarget := psExprApplyMany (.constE className [.zero]) [nat, falseDictionary]
  let rejected := psSynthInstance environment context.localContext context.instances
    context.metaContext rejectedTarget
  ensure rejected.value.isNone
    "indexed deriving granted lawfulness to an unrelated nonreflexive dictionary"

private def checkIndexedGroupBinary (prelude : Lean.Kernel.Environment)
    (environment : PsEnvironment) (groups : List PsDeclaration)
    (origin : PsElabBatchOrigin) : IO Unit := do
  checkIndexedLawfulRegistration environment
  for (label, actual, expected) in [
      ("same", m3GroupIndexedBEqSame, true),
      ("index", m3GroupIndexedBEqIndex, false),
      ("field", m3GroupIndexedBEqField, false),
      ("constructor", m3GroupIndexedBEqCtor, false),
      ("right same", m3GroupIndexedBEqRightSame, true),
      ("right field", m3GroupIndexedBEqRightField, false)] do
    ensure (actual == expected)
      ("native indexed mutual BEq execution disagrees at " ++ label)
  let instances ← derive environment origin ["BEq", "DecidableEq"]
  ensure (instances.length == 4)
    "indexed binary deriving omitted one class/member pair"
  let registered ← register environment instances
  let laws ← sourceResult registered indexedGroupBinarySource
  let _ ← checked prelude (groups ++ instances ++ laws.result.declarations)
  IO.println "PSCV0_M3_INDEXED_GROUP_BINARY: PASS fresh kernel-checked BEq/DecidableEq for both members, actual lawful Nat dictionary, nonreflexive dictionary refusal, six native BEq executions, six native DecidableEq equations and twelve portable constructor/index/field equations"

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (label expected : String) (result : Except PsElabError α) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected group deriving acceptance: " ++ label))
  | .error error => ensure (refusal error == expected)
      (label ++ " refused at the wrong rule: " ++ refusal error)

private def checkRefusals (environment : PsEnvironment)
    (origin indexedOrigin : PsElabBatchOrigin) : IO Unit := do
  expectRefused "indexed group Inhabited cannot cover arbitrary rigid indices"
    "Inhabited deriving requires a constructor with inhabitable fields"
    (psElabDeriveGroupHandler environment indexedOrigin
      { segments := ["Inhabited"], span := indexedOrigin.span })
  expectRefused "reordered retained group origin"
    "deriving origin does not retain the complete ordered group"
    (psElabDeriveGroupHandler environment { origin with members := origin.members.reverse }
      { segments := ["Hashable"], span := origin.span })
  let name := psNameAppendStr (psRootName "M3DeriveForest") "cons"
  let some constructor := psEnvironmentFindConstructor environment name
    | throw (IO.userError "two-child deriving constructor is absent")
  ensure (constructor.recursiveFields == [0, 1]) "two-child fixture lost its ordered direct fields"
  let reversed := psEnvironmentInsert environment
    (.constructorDecl { constructor with recursiveFields := [1, 0] })
  for handler in ["Hashable", "Repr"] do
    expectRefused ("reversed equal-result IHs for " ++ handler)
      "deriving recursive field metadata is invalid"
      (psElabDeriveGroupHandler reversed origin { segments := [handler], span := origin.span })
  let omitted := psEnvironmentInsert environment
    (.constructorDecl { constructor with recursiveFields := [1] })
  expectRefused "omitted direct child metadata" "deriving direct field is absent from recursive metadata"
    (psElabDeriveGroupHandler omitted origin { segments := ["Hashable"], span := origin.span })
  IO.println "PSCV0_M3_INDUCTIVE_DERIVING_REFUSALS: PASS exact group provenance, ordered real IH association and constructor-directed indexed Inhabited refusal"

private def checkPlans (environment : PsEnvironment)
    (origin indexedOrigin : PsElabBatchOrigin) : IO Unit := do
  for source in [origin, indexedOrigin] do
    for handler in ["Hashable", "Repr"] do
      let prepared ← fromExcept ((psElabDerivePrepare environment source
        { groups := true, indices := true }).mapError psCompilerPscv0ElabError)
      let prepared := psElabDeriveRequirements prepared (psRootName handler)
      ensure (prepared.parametersRev.length == 2 && prepared.requirementsRev.length == 1)
        "dependent value parameter acquired a fabricated class dictionary"
  let selected := indexedOrigin.members.filter fun member =>
    match member.role with
    | .inductiveType => psNameEq member.name (psRootName "M3DeriveIndexedRight")
    | _ => true
  let indexed ← fromExcept ((psElabDerivePrepare environment
    { indexedOrigin with members := selected } { groups := true, indices := true }).mapError
      psCompilerPscv0ElabError)
  ensure (indexed.indicesRev.length == 1 && indexed.group.members.length == 2)
    "indexed deriving did not retain the selected member's own index telescope"

-- Extract the actual generated Hashable method after opening its common
-- A/a/dictionary telescope. Only replace its major with cons (leaf a) nil;
-- motives and both child hypotheses remain the generated, checked terms.
private def twoChildProbe (environment : PsEnvironment) (instances : List PsDeclaration) : IO PsExpr := do
  let name := psNameAppendStr (psRootName "M3DeriveForest") "instHashable"
  let some (.definitionDecl _ _ type value) := instances.find?
      (fun declaration => psNameEq (psDeclarationName declaration) name)
    | throw (IO.userError "generated Forest Hashable instance is absent")
  let some opened := psRecursorOpenWorker 4096 3 psLocalEmpty type value
    | throw (IO.userError "generated Hashable parameter/dictionary telescope is invalid")
  let application : PsReduceAppView := psReduceAppView opened.value
  let some (PsExpr.lam _ _ body _) := application.args[1]?
    | throw (IO.userError "generated Hashable method is not an explicit lambda")
  let some view := psGroupRecursorApplication environment body
    | throw (IO.userError "generated Hashable method lost its complete group recursor")
  ensure (psNameEq view.family.name (psRootName "M3DeriveForest") && view.indices.isEmpty)
    "two-child probe did not select the second family"
  let [parameter, seed] := view.fixedArgs.take 2
    | throw (IO.userError "generated Hashable method lost dependent common parameters")
  let levels := view.family.levelParams.map PsLevel.param
  let leaf := psExprApplyMany
    (.constE (psNameAppendStr (psRootName "M3DeriveTree") "leaf") levels)
    [parameter, seed, seed]
  let empty := psExprApplyMany
    (.constE (psNameAppendStr (psRootName "M3DeriveForest") "nil") levels) [parameter, seed]
  let major := psExprApplyMany
    (.constE (psNameAppendStr (psRootName "M3DeriveForest") "cons") levels)
    [parameter, seed, leaf, empty]
  let probe := psExprApplyMany view.head (view.fixedArgs ++ [major])
  let _ ← fromExcept ((psInferType environment psMetaEmpty opened.locals probe).mapError
    (fun _ => "actual two-child recursor probe does not type check"))
  return probe

private def checkMetadataConsumers (environment : PsEnvironment)
    (declarations instances : List PsDeclaration) : IO Unit := do
  let probe ← twoChildProbe environment instances
  ensure (psReduceIota (fun value => value) environment probe).isSome
    "valid two-child constructor did not acquire its checked iota rule"
  ensure (psGroupRecursorApplication environment probe).isSome
    "valid two-child recursor application was refused"
  let name := psNameAppendStr (psRootName "M3DeriveForest") "cons"
  let some constructor := psEnvironmentFindConstructor environment name
    | throw (IO.userError "two-child constructor is absent")
  let reversed := PsDeclaration.constructorDecl { constructor with recursiveFields := [1, 0] }
  let environment := psEnvironmentInsert environment reversed
  ensure (psReduceIota (fun value => value) environment probe).isNone
    "reversed field metadata acquired a permuted iota rule"
  ensure (psGroupRecursorApplication environment probe).isNone
    "reversed field metadata acquired a runtime recursor view"
  let declarations := declarations.map fun declaration =>
    if psNameEq (psDeclarationName declaration) name then reversed else declaration
  match psEncodeCheckedAdmissionsCanonical declarations with
  | .error (.mismatchedConstructor actual) =>
    ensure (psNameEq actual name) "canonical admission attributed the wrong unordered constructor"
  | _ => throw (IO.userError "canonical admission erased reordered recursive field metadata")

private def checkPortableReduction (environment : PsEnvironment) : IO Unit := do
  for flag in [false, true] do
    let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
    let equality := PsExpr.app (.constE (psRootName "m3DeriveEqualityProbe") []) argument
    let atom := PsExpr.app (.constE (psRootName "m3DeriveAtomProbe") []) argument
    ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty equality) argument)
      "portable group equality differs from native deep-field comparison"
    ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty atom) (.constE psBoolFalseName []))
      "portable group equality ignored the nonreflexive field dictionary"

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3derivehash", M3InductiveDerivingOracle.hashOutput),
   ("m3deriverepr", fun _ => 3),
   ("m3derivebeq", M3InductiveDerivingOracle.beqOutput),
   ("m3deriveatom", M3InductiveDerivingOracle.atomOutput),
   ("m3deriveindexedhash", M3InductiveDerivingOracle.indexedHashOutput),
   ("m3deriveindexedrepr", fun _ => 3)]

private def indexedBEqOutputCases : List (String × (Bool → UInt64)) :=
  [("m3indexedbeqnat", M3IndexedBEqOracle.natOutput),
   ("m3indexedbeqbool", M3IndexedBEqOracle.boolOutput)]

private def witness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
  let value := PsExpr.app (.constE (psRootName name) []) argument
  let expected := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  let proposition := psExprApplyMany (.constE psEqName [.succ .zero]) [uint64, value, expected]
  let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "refl") [.succ .zero])
    [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def emit (ir : PsVerifiedIrModule) (sourceText : String := runtimeSource)
    (outputStem : String := "groupderive") (outputNames : List String := outputCases.map Prod.fst)
    (sourceName : String := "m3-group-deriving.ps") : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := { sourceName, sourceText, outputStem }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked outputStem []
    let exports := PsApiExposure.selected outputNames
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

private def checkIndexedBEq (directory : System.FilePath)
    (prelude : Lean.Kernel.Environment) : IO Unit := do
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "deriving.ps") indexedBEqSource
  let result ← sourceResult psSelfHostProdPreludeEnvironment indexedBEqSource
  let environment := result.result.environment
  for family in ["IndexedBEq", "M3DeriveIndexedBEq"] do
    let name := psNameAppendStr (psRootName family) "instBEq"
    let some (.definitionDecl _ _ type value) := psEnvironmentFind environment name
      | throw (IO.userError "indexed BEq did not generate an ordinary checked instance")
    ensure (!psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
      psExprFVarsInContext psLocalEmpty type && psExprFVarsInContext psLocalEmpty value)
      "indexed BEq instance retained a metavariable or an unbound local"
    ensure (psExprHasConst (psNameAppendStr (psRootName family) "rec") value)
      "indexed BEq lost the registered indexed recursor"
  let some (.definitionDecl _ levels type _) := psEnvironmentFind environment
      (psNameAppendStr (psRootName "M3DeriveIndexedBEq") "instBEq")
    | throw (IO.userError "generic indexed BEq instance is absent")
  let opened ← fromExcept ((psElabOpenCoreTelescope 4096
    (psElabContextEmpty environment levels) type (some 5)).mapError psCompilerPscv0ElabError)
  let [indexType, payloadType, indexValue, indexDictionary, payloadDictionary] :=
      opened.bindersRev.reverse
    | throw (IO.userError "indexed BEq changed its parameter, index or dictionary telescope")
  let indexClass ← fromExcept ((psElabDeriveClassType opened.context
    (psRootName "BEq") (.fvar indexType.id)).mapError psCompilerPscv0ElabError)
  let payloadClass ← fromExcept ((psElabDeriveClassType opened.context
    (psRootName "BEq") (.fvar payloadType.id)).mapError psCompilerPscv0ElabError)
  ensure (psBinderInfoEq indexType.binder .implicit &&
    psBinderInfoEq payloadType.binder .implicit && psBinderInfoEq indexValue.binder .implicit &&
    psBinderInfoEq indexDictionary.binder .instanceImplicit &&
    psBinderInfoEq payloadDictionary.binder .instanceImplicit &&
    psExprAlphaEq indexValue.type (.fvar indexType.id) &&
    psDefEqReadOnlyWithEnv environment psMetaEmpty opened.context.localContext
      indexDictionary.type indexClass &&
    psDefEqReadOnlyWithEnv environment psMetaEmpty opened.context.localContext
      payloadDictionary.type payloadClass)
    "indexed BEq inferred a dictionary for the value index or changed a parameter requirement"
  let accepted ← sourceResult psSelfHostProdPreludeEnvironment indexedBEqAcceptedSource
  let _ ← checked prelude accepted.result.declarations
  for (family, parameters, indices) in [("IndexedSucc", 0, 1), ("IndexedPayload", 1, 0)] do
    let some info := psEnvironmentFindInductive accepted.result.environment (psRootName family)
      | throw (IO.userError "accepted indexed BEq family is absent")
    ensure (info.numParams == parameters && info.numIndices == indices)
      ("accepted indexed BEq family changed its native index policy: " ++ family)
  IO.FS.writeFile (directory / "accepted.ps") indexedBEqAcceptedSource
  for (label, text, expected) in [
      ("missing payload dictionary",
        "inductive IndexedMissing: Nat -> Type where { | intro(n: Nat, value: Nat -> Nat): IndexedMissing(n) } deriving BEq\n",
        "deriving field has no checked instance")] do
    let parsed ← fromExcept (psPscv0ParseProgram text)
    expectRefused label expected (psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed)
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment, declarations := result.result.declarations }).mapError psCompilerPscv0Error)
  let admitted ← checked prelude prepared.prepared.declarations
  let equations := [false, true].flatMap fun flag =>
    indexedBEqOutputCases.map fun (name, oracle) => witness name flag (oracle flag)
  let _ ← checked admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir indexedBEqSource "indexedbeq"
    (indexedBEqOutputCases.map Prod.fst) "m3-indexed-beq.ps")
  ensure (artifacts.length == 5) "indexed BEq did not emit all five targets"
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      indexedBEqOutputCases.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INDEXED_BEQ: PASS checked Nat/Bool defining laws, constructor-directed successor indices, native fixed-prefix Fin payloads, ordinary recursor instances and parameter dictionaries, retained missing-function-dictionary refusal; five-target runtime parity follows"

private def checkDataUnary (directory : System.FilePath)
    (prelude : Lean.Kernel.Environment) : IO Unit := do
  IO.FS.createDirAll directory
  IO.println "PSCV0_M3_DATA_PHASE: omitted universe pair"
  let typesLean ← dataElaborated .lean dataTypesLeanSource
  let typesPs ← dataElaborated .proofScript dataTypesPsSource
  compareDataDeclarations typesLean.2 typesPs.2
  checkDataMetadata typesLean.1 false
  checkDataMetadata typesPs.1 false
  let _ ← checked prelude typesLean.2
  let _ ← checked prelude typesPs.2
  IO.FS.writeFile (directory / "types.lean") dataTypesLeanSource
  IO.FS.writeFile (directory / "types.ps") dataTypesPsSource
  IO.println "PSCV0_M3_DATA_PHASE: exact selected Fin method pair"
  let finLean ← dataElaborated .lean dataFinLeanSource
  let finPs ← dataElaborated .proofScript dataFinPsSource
  compareDataDeclarations finLean.2 finPs.2
  let _ ← checked prelude finLean.2
  let _ ← checked prelude finPs.2
  IO.println "PSCV0_M3_DATA_PHASE: promotion and dependent unary pair"
  let unaryLean ← dataElaborated .lean dataUnaryLeanSource
  let unaryPs ← dataElaborated .proofScript dataUnaryPsSource
  compareDataDeclarations unaryLean.2 unaryPs.2
  checkDataMetadata unaryLean.1 true
  checkDataMetadata unaryPs.1 true
  let _ ← checked prelude unaryLean.2
  let _ ← checked prelude unaryPs.2
  IO.FS.writeFile (directory / "logical.lean") dataUnaryLeanSource
  IO.FS.writeFile (directory / "logical.ps") dataUnaryPsSource
  checkDataRefusals
  IO.println "PSCV0_M3_DATA_PHASE: runtime construction"
  let runtime ← sourceResult unaryPs.1 dataRuntimeSource
  let source := dataUnaryPsSource ++ "\n" ++ dataRuntimeSource
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment,
      declarations := unaryPs.2 ++ runtime.result.declarations }).mapError psCompilerPscv0Error)
  let admitted ← checked prelude prepared.prepared.declarations
  -- Opaque mixHash and partial pretty-printing are observed by native execution.
  -- Pattern selection and Fin comparison also have closed kernel equations.
  let equations := [false, true].flatMap fun flag =>
    [witness "m3datapattern" flag (M3DataUnaryOracle.patternOutput flag),
     witness "m3databeq" flag (M3DataUnaryOracle.beqOutput flag)]
  let _ ← checked admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir source "dataunary"
    (dataOutputCases.map Prod.fst) "m3-data-unary.ps")
  ensure (artifacts.length == 5) "Data/unary did not emit all five targets"
  IO.FS.writeFile (directory / "deriving.ps") source
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      dataOutputCases.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_DATA_UNARY: PASS paired checked omitted universes and fixed-prefix metadata, ordinary constructor parameters and dependent nested fields, shifted real recursive ordinals, exact Fin dictionaries and nonempty indexed BEq law, native Hashable/Repr observations, retained ambiguous-universe and function-dictionary refusals, four exports and five-target emission; runtime parity follows"

end M3InductiveDeriving

open M3InductiveDeriving in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "group deriving qualification requires the pinned Lean"
  let (group, origin) ← fromExcept (elaborateGroup groupSource)
  let (indexed, indexedOrigin) ← fromExcept (elaborateGroup indexedSource)
  let groups := group.declarations ++ indexed.declarations
  let input ← add psSelfHostProdPreludeEnvironment groups
  checkTypedFunctionEta input
  checkNestedK input
  checkPlans input origin indexedOrigin
  checkRefusals input origin indexedOrigin
  -- Every handler sees the same input. None of the generated group instances
  -- can be searched as an assumed recursive dictionary while deriving another.
  let ordinary ← derive input origin ["Hashable", "Repr", "BEq"]
  IO.println "PSCV0_M3_DERIVING_PHASE: ordinary handlers"
  let dependent ← derive input indexedOrigin ["Hashable", "Repr"]
  IO.println "PSCV0_M3_DERIVING_PHASE: dependent handlers"
  let instances := ordinary ++ dependent
  ensure (instances.length == 10) "deriving did not generate one instance per requested group member"
  checkMetadataConsumers input groups instances
  IO.println "PSCV0_M3_DERIVING_PHASE: metadata"
  let registered ← register input instances
  let logical ← sourceResult registered logicalSource
  IO.println "PSCV0_M3_DERIVING_PHASE: logical source"
  let runtime ← sourceResult registered runtimeSource
  IO.println "PSCV0_M3_DERIVING_PHASE: runtime source"
  checkPortableReduction runtime.result.environment
  let declarations := groups ++ instances ++ runtime.result.declarations
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment, declarations }).mapError psCompilerPscv0Error)
  ensure (prepared.prepared.recursorWorkerGroups.length == 10 &&
    prepared.prepared.recursorWorkerGroups.all (fun group =>
      group.workers.length == 2 && group.captureCount == 3))
    "group deriving lost common A/a/dictionary captures or generated workers for right-only BEq inspection"
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  IO.println "PSCV0_M3_DERIVING_PHASE: indexed binary entry"
  checkIndexedGroupBinary prelude input groups indexedOrigin
  let admitted ← checked prelude prepared.prepared.declarations
  let _ ← checked admitted logical.result.declarations
  -- mixHash is opaque in pinned Lean. Generic hash equations above are checked;
  -- numeric hash and full pretty-text parity use the independent native oracle.
  -- BEq's logical computation supports these four closed kernel equations.
  let equations := [false, true].flatMap fun flag =>
    [witness "m3derivebeq" flag (M3InductiveDerivingOracle.beqOutput flag),
     witness "m3deriveatom" flag (M3InductiveDerivingOracle.atomOutput flag)]
  let _ ← checked admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "group deriving did not emit all five targets"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "deriving.ps") runtimeSource
  IO.FS.writeFile (directory / "logical.ps") logicalSource
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      outputCases.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INDUCTIVE_DERIVING: PASS native deriving oracles, fresh checked group instances/workers and constructor laws, ordered real child IHs, indexed Hashable/Repr, nonreflexive BEq and five-target emission; runtime parity follows"
  checkIndexedBEq (directory / "indexed-beq") prelude
  checkDataUnary (directory / "data-unary") prelude
