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
  for (label, text, expected) in [
      ("non-pattern index",
        "inductive IndexedSucc: Nat -> Type where { | intro(n: Nat): IndexedSucc(Nat.succ(n)) } deriving BEq\n",
        "indexed BEq deriving requires direct constructor index fields"),
      ("dependent payload",
        "inductive IndexedPayload: Nat -> Type where { | intro(n: Nat, value: Fin(n)): IndexedPayload(n) } deriving BEq\n",
        "deriving requires independent runtime field types"),
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
  IO.println "PSCV0_M3_INDEXED_BEQ: PASS direct index fields, checked Nat/Bool defining laws and four closed native-oracle equations, ordinary recursor instances and parameter dictionaries, retained dependent/non-pattern/missing-dictionary refusals; five-target runtime parity follows"

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
