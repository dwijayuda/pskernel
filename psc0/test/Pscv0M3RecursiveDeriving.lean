import Ps.Host.NativeV7

-- Independent pinned Lean oracle. The portable source is parsed/elaborated
-- separately. Use its exact family name so Repr compares text, not renamed text.
universe u
inductive M3HashTree (A : Type u) where
  | leaf : A → M3HashTree A
  | fork : M3HashTree A → M3HashTree A → M3HashTree A
  deriving Hashable, Repr, BEq, DecidableEq

-- BEq is not required to be reflexive. Recursive deriving must use the actual
-- field dictionary, not pointer identity or an assumed LawfulBEq instance.
inductive M3EqAtom where
  | atom : Bool → M3EqAtom
  deriving DecidableEq
instance : BEq M3EqAtom where
  beq _ _ := false

-- The certificate depends on the scalar field but has no runtime payload.
inductive M3EqProofChain where
  | stop
  | link (value : Nat) (next : M3EqProofChain) (certificate : value = value)
  deriving DecidableEq

namespace M3RecursiveHashOracle

def natTree (flag : Bool) : M3HashTree Nat :=
  let n : Nat := if flag then 71 else 13
  M3HashTree.fork (M3HashTree.leaf n)
    (M3HashTree.fork (M3HashTree.leaf (n + 1)) (M3HashTree.leaf (n + 2)))

def boolTree (flag : Bool) : M3HashTree Bool :=
  M3HashTree.fork (M3HashTree.leaf flag) (M3HashTree.leaf (!flag))

def natHash (flag : Bool) : UInt64 := hash (natTree flag)
def boolHash (flag : Bool) : UInt64 := hash (boolTree flag)

def natText (flag : Bool) : String :=
  (reprPrec (natTree flag) (if flag then 1024 else 0)).pretty 40

def boolText (flag : Bool) : String :=
  (reprPrec (boolTree flag) (if flag then 1024 else 0)).pretty 40

def eqBits (a b c d e f : Bool) : UInt64 :=
  UInt64.ofNat ((if a then 1 else 0) + (if b then 2 else 0) +
    (if c then 4 else 0) + (if d then 8 else 0) +
    (if e then 16 else 0) + (if f then 32 else 0))

def natEq (flag : Bool) : UInt64 :=
  let n : Nat := if flag then 71 else 13
  let x := natTree flag
  let y := M3HashTree.fork (M3HashTree.leaf n)
    (M3HashTree.fork (M3HashTree.leaf (n + 1))
      (M3HashTree.leaf (if flag then n + 2 else n + 3)))
  let z := M3HashTree.fork (M3HashTree.leaf (n + 1))
    (M3HashTree.fork (M3HashTree.leaf (n + 1)) (M3HashTree.leaf (n + 2)))
  eqBits (x == x) (x == y) (y == x) (x == M3HashTree.leaf n)
    (M3HashTree.leaf n == x) (x == z)

def boolEq (flag : Bool) : UInt64 :=
  let x := boolTree flag
  let y := M3HashTree.fork (M3HashTree.leaf flag) (M3HashTree.leaf true)
  let z := M3HashTree.fork (M3HashTree.leaf (!flag)) (M3HashTree.leaf (!flag))
  eqBits (x == x) (x == y) (y == x) (x == M3HashTree.leaf flag)
    (M3HashTree.leaf flag == x) (x == z)

def atomEq (flag : Bool) : UInt64 :=
  let x := M3HashTree.fork (M3HashTree.leaf (M3EqAtom.atom flag))
    (M3HashTree.leaf (M3EqAtom.atom (!flag)))
  if x == x then 0 else 1

def natDecision (flag : Bool) : UInt64 :=
  let n : Nat := if flag then 71 else 13
  let x := natTree flag
  let y := M3HashTree.fork (M3HashTree.leaf n)
    (M3HashTree.fork (M3HashTree.leaf (n + 1))
      (M3HashTree.leaf (if flag then n + 2 else n + 3)))
  let z := M3HashTree.fork (M3HashTree.leaf (n + 1))
    (M3HashTree.fork (M3HashTree.leaf (n + 1)) (M3HashTree.leaf (n + 2)))
  eqBits (decide (x = x)) (decide (x = y)) (decide (y = x))
    (decide (x = M3HashTree.leaf n)) (decide (M3HashTree.leaf n = x)) (decide (x = z))

def boolDecision (flag : Bool) : UInt64 :=
  let x := boolTree flag
  let y := M3HashTree.fork (M3HashTree.leaf flag) (M3HashTree.leaf true)
  let z := M3HashTree.fork (M3HashTree.leaf (!flag)) (M3HashTree.leaf (!flag))
  eqBits (decide (x = x)) (decide (x = y)) (decide (y = x))
    (decide (x = M3HashTree.leaf flag)) (decide (M3HashTree.leaf flag = x)) (decide (x = z))

def atomDecision (flag : Bool) : UInt64 :=
  let x := M3HashTree.fork (M3HashTree.leaf (M3EqAtom.atom flag))
    (M3HashTree.leaf (M3EqAtom.atom (!flag)))
  if decide (x = x) then 1 else 0

def proofDecision (flag : Bool) : UInt64 :=
  let leftTail := M3EqProofChain.link 4 .stop rfl
  let rightTail := M3EqProofChain.link (if flag then 4 else 5) .stop rfl
  let left := M3EqProofChain.link 3 leftTail rfl
  let right := M3EqProofChain.link 3 rightTail rfl
  if decide (left = right) then 1 else 0
-- This independent native definition requires the actual strict-child proof.
def normalizedChild (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => normalizedChild (Nat.add k 0) + 1
termination_by structural n

example (n : Nat) : normalizedChild (Nat.succ n) = normalizedChild n + 1 := by rfl

-- Fixed prefix precedes the structural argument. It is an unchanged binder.
def laterChild (flag : Bool) (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => laterChild flag (Nat.add k 0) + (if flag then 2 else 1)
termination_by structural n

example (flag : Bool) (n : Nat) :
    laterChild flag (Nat.succ n) =
      laterChild flag n + (if flag then 2 else 1) := by rfl

-- A changing prefix can be a checked accumulator/state parameter.
-- Unlike a fixed prefix, its update is handled by worker normalization.
def flipPrefix (flag : Bool) (n : Nat) : Nat :=
  match n with
  | 0 => if flag then 1 else 0
  | k + 1 => flipPrefix (!flag) (Nat.add k 0)
termination_by structural n

example (flag : Bool) (n : Nat) :
    flipPrefix flag (Nat.succ n) = flipPrefix (!flag) n := by rfl

-- Nat.sub a 0 is definitionally a in pinned Lean 4.35.0.
def normalizedSubChild (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => normalizedSubChild (Nat.sub k 0) + 1
termination_by structural n

example (n : Nat) :
    normalizedSubChild (Nat.succ n) = normalizedSubChild n + 1 := by rfl

-- Definitional open Nat addition via the pinned HAdd Nat dictionary.
def infixChild (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => infixChild (k + 0) + 1
termination_by structural n

example (n : Nat) : infixChild (Nat.succ n) = infixChild n + 1 := by rfl

-- Two-column pattern elimination, no recursion fallback or unproved branch.
def matrixSelect (flag : Bool) (n : Nat) : Nat :=
  match flag, n with
  | true, 0 => 3
  | true, Nat.succ k => k + 20
  | false, _ => 11

example (k : Nat) : matrixSelect true (Nat.succ k) = k + 20 := by rfl
-- Independent pinned Lean 4.35.0: a strictly positive nested family
-- with a shallow nonrecursive elimination over its actual constructor cases.
inductive M3NestedRose where
  | leaf
  | node : List M3NestedRose → M3NestedRose

def nestedRoseTag : M3NestedRose → Nat
  | .leaf => 0
  | .node _ => 1

example (xs : List M3NestedRose) :
    nestedRoseTag (.node xs) = 1 := rfl

-- Pinned Lean models Array α as a List α-backed structure.
inductive M3NestedArrayRose where
  | leaf
  | node : Array M3NestedArrayRose → M3NestedArrayRose

def nestedArrayRoseTag : M3NestedArrayRose → Nat
  | .leaf => 0
  | .node _ => 1

example (xs : Array M3NestedArrayRose) :
    nestedArrayRoseTag (.node xs) = 1 := rfl

inductive M3NestedOptionRose where
  | leaf
  | node : Option M3NestedOptionRose → M3NestedOptionRose

def nestedOptionRoseTag : M3NestedOptionRose → Nat
  | .leaf => 0
  | .node _ => 1

example (xs : Option M3NestedOptionRose) :
    nestedOptionRoseTag (.node xs) = 1 := rfl

inductive M3NestedProdRose where
  | leaf
  | node : Prod M3NestedProdRose M3NestedProdRose → M3NestedProdRose

def nestedProdRoseTag : M3NestedProdRose → Nat
  | .leaf => 0
  | .node _ => 1

example (xs : Prod M3NestedProdRose M3NestedProdRose) :
    nestedProdRoseTag (.node xs) = 1 := rfl

def nestedOptionRoseOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (nestedOptionRoseTag
    (if flag then M3NestedOptionRose.leaf else M3NestedOptionRose.node none))

def nestedProdRoseOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (nestedProdRoseTag
    (if flag then M3NestedProdRose.leaf else
      M3NestedProdRose.node (M3NestedProdRose.leaf, M3NestedProdRose.leaf)))

def nestedArrayRoseOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (nestedArrayRoseTag
    (if flag then M3NestedArrayRose.leaf else M3NestedArrayRose.node #[]))

-- Lean's partial executable body is distinct from its logical opaque value.
partial def partialIncrement (n : Nat) : Nat := n + 5

-- The executable body has a real self reference, but its logical declaration
-- is still opaque. Native Lean computes only selected finite executions.
partial def partialCount (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 => partialCount k + 1

def applyPartialCapture (step : Nat → Nat) (n : Nat) : Nat := step n

-- The recursive call crosses a higher-order argument and captures changing
-- prefix state. This tests ordinary body identity through closure lowering.
partial def partialCapture (bias n : Nat) : Nat :=
  match n with
  | 0 => bias
  | k + 1 => applyPartialCapture (fun rest => partialCapture (bias + 1) rest) k

def partialOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (partialIncrement (if flag then 17 else 9))

def partialCountOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (partialCount (if flag then 7 else 3))

def partialCaptureOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (partialCapture (if flag then 7 else 11) (if flag then 3 else 5))

def nestedRoseOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (nestedRoseTag
    (if flag then M3NestedRose.leaf else M3NestedRose.node []))
end M3RecursiveHashOracle

private def oracleLiteral (value : String) : String := (Lean.toJson value).compress

private def source : String :=
  "universe u\n" ++
  "inductive M3HashTree(A: Type u): Type u where {\n" ++
  " | leaf(value: A)\n" ++
  " | fork(left: M3HashTree A, right: M3HashTree A)\n" ++
  "} deriving Hashable, Repr, BEq, DecidableEq\n" ++
  "function m3hashnat(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " Hashable.hash(M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2))))\n" ++
  "}\n" ++
  "function m3hashbool(flag: Bool): UInt64 := Hashable.hash(M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(Bool.not(flag))))\n" ++
  "theorem m3hashlaw(n: Nat, m: Nat): Hashable.hash(M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.leaf(m))) = mixHash(mixHash(UInt64.ofNat(1), mixHash(UInt64.ofNat(0), Hashable.hash(n))), mixHash(UInt64.ofNat(0), Hashable.hash(m))) := by { rfl }\n" ++
  "function m3reprnat(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let tree: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2)))\n" ++
  " let expected: String := if (flag) { " ++ oracleLiteral (M3RecursiveHashOracle.natText true) ++
    " } else { " ++ oracleLiteral (M3RecursiveHashOracle.natText false) ++ " }\n" ++
  " let actual: String := Std.Format.pretty(Repr.reprPrec(tree, prec), 40, 0, 0)\n" ++
  " if (actual == expected) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n" ++
  "}\n" ++
  "function m3reprbool(flag: Bool): UInt64 := {\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let tree: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(Bool.not(flag)))\n" ++
  " let expected: String := if (flag) { " ++ oracleLiteral (M3RecursiveHashOracle.boolText true) ++
    " } else { " ++ oracleLiteral (M3RecursiveHashOracle.boolText false) ++ " }\n" ++
  " let actual: String := Std.Format.pretty(Repr.reprPrec(tree, prec), 40, 0, 0)\n" ++
  " if (actual == expected) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n" ++
  "}\n" ++
  "function m3eqbits(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool): UInt64 := UInt64.ofNat((if (a) { 1 } else { 0 }) + (if (b) { 2 } else { 0 }) + (if (c) { 4 } else { 0 }) + (if (d) { 8 } else { 0 }) + (if (e) { 16 } else { 0 }) + (if (f) { 32 } else { 0 }))\n" ++
  "function m3eqnat(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let last: Nat := if (flag) { n + 2 } else { n + 3 }\n" ++
  " let x: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2)))\n" ++
  " let y: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(last)))\n" ++
  " let z: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2)))\n" ++
  " m3eqbits(x == x, x == y, y == x, x == M3HashTree.leaf(n), M3HashTree.leaf(n) == x, x == z)\n" ++
  "}\n" ++
  "function m3eqbool(flag: Bool): UInt64 := {\n" ++
  " let x: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(Bool.not(flag)))\n" ++
  " let y: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(true))\n" ++
  " let z: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(Bool.not(flag)), M3HashTree.leaf(Bool.not(flag)))\n" ++
  " m3eqbits(x == x, x == y, y == x, x == M3HashTree.leaf(flag), M3HashTree.leaf(flag) == x, x == z)\n" ++
  "}\n" ++
  "inductive M3EqAtom where { | atom(value: Bool) } deriving DecidableEq\n" ++
  "instance m3atomBEq: BEq M3EqAtom where { beq(left: M3EqAtom, right: M3EqAtom): Bool := false }\n" ++
  "function m3eqatom(flag: Bool): UInt64 := {\n" ++
  " let x: M3HashTree M3EqAtom := M3HashTree.fork(M3HashTree.leaf(M3EqAtom.atom(flag)), M3HashTree.leaf(M3EqAtom.atom(Bool.not(flag))))\n" ++
  " if (x == x) { UInt64.ofNat(0) } else { UInt64.ofNat(1) }\n" ++
  "}\n" ++
  "theorem m3beqlaw(n: Nat, m: Nat, k: Nat, l: Nat): (M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.leaf(m)) == M3HashTree.fork(M3HashTree.leaf(k), M3HashTree.leaf(l))) = Bool.and(n == k, m == l) := by { rfl }\n" ++
  "function m3decidenat(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " let last: Nat := if (flag) { n + 2 } else { n + 3 }\n" ++
  " let x: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2)))\n" ++
  " let y: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(last)))\n" ++
  " let z: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2)))\n" ++
  " m3eqbits(Decidable.decide(self := decEq(x, x)), Decidable.decide(self := decEq(x, y)), Decidable.decide(self := decEq(y, x)), Decidable.decide(self := decEq(x, M3HashTree.leaf(n))), Decidable.decide(self := decEq(M3HashTree.leaf(n), x)), Decidable.decide(self := decEq(x, z)))\n" ++
  "}\n" ++
  "function m3decidebool(flag: Bool): UInt64 := {\n" ++
  " let x: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(Bool.not(flag)))\n" ++
  " let y: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(true))\n" ++
  " let z: M3HashTree Bool := M3HashTree.fork(M3HashTree.leaf(Bool.not(flag)), M3HashTree.leaf(Bool.not(flag)))\n" ++
  " m3eqbits(Decidable.decide(self := decEq(x, x)), Decidable.decide(self := decEq(x, y)), Decidable.decide(self := decEq(y, x)), Decidable.decide(self := decEq(x, M3HashTree.leaf(flag))), Decidable.decide(self := decEq(M3HashTree.leaf(flag), x)), Decidable.decide(self := decEq(x, z)))\n" ++
  "}\n" ++
  "function m3decideatom(flag: Bool): UInt64 := {\n" ++
  " let x: M3HashTree M3EqAtom := M3HashTree.fork(M3HashTree.leaf(M3EqAtom.atom(flag)), M3HashTree.leaf(M3EqAtom.atom(Bool.not(flag))))\n" ++
  " if (Decidable.decide(self := decEq(x, x))) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n" ++
  "}\n" ++
  "inductive M3EqProofChain where { | stop | link(value: Nat, next: M3EqProofChain, certificate: value = value) } deriving DecidableEq\n" ++
  "function m3decideproof(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 4 } else { 5 }\n" ++
  " let empty: M3EqProofChain := M3EqProofChain.stop\n" ++
  " let leftTail: M3EqProofChain := M3EqProofChain.link(4, empty, by { rfl })\n" ++
  " let rightTail: M3EqProofChain := M3EqProofChain.link(n, empty, by { rfl })\n" ++
  " let left: M3EqProofChain := M3EqProofChain.link(3, leftTail, by { rfl })\n" ++
  " let right: M3EqProofChain := M3EqProofChain.link(3, rightTail, by { rfl })\n" ++
  " if (Decidable.decide(self := decEq(left, right))) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n" ++
  "}\n" ++
  "const m3decisionLeft: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(1), M3HashTree.leaf(2))\n" ++
  "const m3decisionRight: M3HashTree Nat := M3HashTree.fork(M3HashTree.leaf(1), M3HashTree.leaf(3))\n" ++
  "theorem m3decisionEqual: Decidable.decide(self := decEq(m3decisionLeft, m3decisionLeft)) = true := by { rfl }\n" ++
  "theorem m3decisionDifferent: Decidable.decide(self := decEq(m3decisionLeft, m3decisionRight)) = false := by { rfl }\n" ++
  -- The recursive argument is definitionally, not syntactically, the child.
  "function m3normalizedChild(n: Nat): Nat := match n with { | 0 => 0 | k+1 => m3normalizedChild(Nat.add(k, 0)) + 1 }\n" ++
  "theorem m3normalizedStep(n: Nat): m3normalizedChild(Nat.succ(n)) = m3normalizedChild(n) + 1 := by { rfl }\n" ++
  "function m3normoutput(flag: Bool): UInt64 := UInt64.ofNat(m3normalizedChild(if (flag) { 17 } else { 9 }))\n" ++
  "function m3laterChild(flag: Bool, n: Nat): Nat := match n with { | 0 => 0 | k+1 => m3laterChild(flag, Nat.add(k, 0)) + (if (flag) { 2 } else { 1 }) }\n" ++
  "theorem m3laterStep(flag: Bool, n: Nat): m3laterChild(flag, Nat.succ(n)) = m3laterChild(flag, n) + (if (flag) { 2 } else { 1 }) := by { rfl }\n" ++
  "function m3lateroutput(flag: Bool): UInt64 := UInt64.ofNat(m3laterChild(flag, if (flag) { 17 } else { 9 }))\n" ++
  "function m3flipPrefix(flag: Bool, n: Nat): Nat := match n with { | 0 => if (flag) { 1 } else { 0 } | k+1 => m3flipPrefix(Bool.not(flag), Nat.add(k, 0)) }\n" ++
  "theorem m3flipStep(flag: Bool, n: Nat): m3flipPrefix(flag, Nat.succ(n)) = m3flipPrefix(Bool.not(flag), n) := by { rfl }\n" ++
  "function m3flipoutput(flag: Bool): UInt64 := UInt64.ofNat(m3flipPrefix(flag, if (flag) { 17 } else { 9 }))\n" ++
  "function m3normalizedSub(n: Nat): Nat := match n with { | 0 => 0 | k+1 => m3normalizedSub(Nat.sub(k, 0)) + 1 }\n" ++
  "theorem m3subStep(n: Nat): m3normalizedSub(Nat.succ(n)) = m3normalizedSub(n) + 1 := by { rfl }\n" ++
  "function m3suboutput(flag: Bool): UInt64 := UInt64.ofNat(m3normalizedSub(if (flag) { 17 } else { 9 }))\n" ++
  "function m3infixChild(n: Nat): Nat := match n with { | 0 => 0 | k+1 => m3infixChild(k + 0) + 1 }\n" ++
  "theorem m3infixStep(n: Nat): m3infixChild(Nat.succ(n)) = m3infixChild(n) + 1 := by { rfl }\n" ++
  "function m3infixoutput(flag: Bool): UInt64 := UInt64.ofNat(m3infixChild(if (flag) { 17 } else { 9 }))\n" ++
  "function m3matrixSelect(flag: Bool, n: Nat): Nat := match flag, n with { | true, 0 => 3 | true, k+1 => k+20 | false, _ => 11 }\n" ++
  "theorem m3matrixStep(k: Nat): m3matrixSelect(true, Nat.succ(k)) = k+20 := by { rfl }\n" ++
  "function m3matrixoutput(flag: Bool): UInt64 := UInt64.ofNat(m3matrixSelect(flag, if (flag) { 5 } else { 0 }))\n" ++
  "inductive M3NestedRose where { | leaf | node(children: List M3NestedRose) }\n" ++
  "function m3nestedtag(r: M3NestedRose): Nat := match r with { | M3NestedRose.leaf => 0 | M3NestedRose.node children => 1 }\n" ++
  "function m3nestedoutput(flag: Bool): UInt64 := UInt64.ofNat(m3nestedtag(if (flag) { M3NestedRose.leaf } else { M3NestedRose.node(List.nil) }))\n" ++
  "inductive M3NestedArrayRose where { | leaf | node(children: Array M3NestedArrayRose) }\n" ++
  "function m3nestedarraytag(r: M3NestedArrayRose): Nat := match r with { | M3NestedArrayRose.leaf => 0 | M3NestedArrayRose.node children => 1 }\n" ++
  "function m3nestedarrayoutput(flag: Bool): UInt64 := UInt64.ofNat(m3nestedarraytag(if (flag) { M3NestedArrayRose.leaf } else { M3NestedArrayRose.node(#[]) }))\n" ++
  "inductive M3NestedOptionRose where { | leaf | node(child: Option M3NestedOptionRose) }\n" ++
  "function m3nestedoptiontag(r: M3NestedOptionRose): Nat := match r with { | M3NestedOptionRose.leaf => 0 | M3NestedOptionRose.node child => 1 }\n" ++
  "function m3nestedoptionoutput(flag: Bool): UInt64 := UInt64.ofNat(m3nestedoptiontag(if (flag) { M3NestedOptionRose.leaf } else { M3NestedOptionRose.node(Option.none) }))\n" ++
  "inductive M3NestedProdRose where { | leaf | node(children: Prod M3NestedProdRose M3NestedProdRose) }\n" ++
  "function m3nestedprodtag(r: M3NestedProdRose): Nat := match r with { | M3NestedProdRose.leaf => 0 | M3NestedProdRose.node children => 1 }\n" ++
  "function m3nestedprodoutput(flag: Bool): UInt64 := UInt64.ofNat(m3nestedprodtag(if (flag) { M3NestedProdRose.leaf } else { M3NestedProdRose.node(Prod.mk(M3NestedProdRose.leaf, M3NestedProdRose.leaf)) }))\n" ++
  "partial function m3partial(n: Nat): Nat := n + 5\n" ++
  "function m3partialoutput(flag: Bool): UInt64 := UInt64.ofNat(m3partial(if (flag) { 17 } else { 9 }))\n" ++
  "partial function m3partialCount(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => m3partialCount(k) + 1 }\n" ++
  "function m3partialcountoutput(flag: Bool): UInt64 := UInt64.ofNat(m3partialCount(if (flag) { 7 } else { 3 }))\n" ++
  "function m3applyPartialCapture(step: Nat -> Nat, n: Nat): Nat := step(n)\n" ++
  "partial function m3partialCapture(bias: Nat, n: Nat): Nat := match n with { | 0 => bias | k + 1 => m3applyPartialCapture((fun (rest: Nat) => m3partialCapture(bias + 1, rest)), k) }\n" ++
  "function m3partialcaptureoutput(flag: Bool): UInt64 := UInt64.ofNat(m3partialCapture(if (flag) { 7 } else { 11 }, if (flag) { 3 } else { 5 }))\n"

-- Parser/source identity is tested independently from the P1 elaboration gate.
-- A valid suffix must not disappear, become a prefix, or use P0 opacity.
private def checkFixedpointSource : IO Unit := do
  for (text, isPrivate) in [
      ("def fixed(n: Nat): Nat := fixed(n)\npartial_fixpoint\n", false),
      ("function fixed(n: Nat): Nat := fixed(n) partial_fixpoint\n", false),
      ("function fixed(n: Nat): Nat := fixed(n)\n  partial_fixpoint\n", false),
      ("function fixed(n: Nat): Nat := { fixed(n) }\npartial_fixpoint\n", false),
      ("function fixed(): Nat := fixed()\npartial_fixpoint\n", false),
      ("private function fixed(n: Nat): Nat := fixed(n)\npartial_fixpoint\n", true)] do
    let program ← match psPscv0ParseProgram (text ++ "const following: Nat := 1\n") with
      | .ok value => pure value
      | .error message => throw (IO.userError ("fixedpoint parse: " ++ message))
    let declaration ← match program.commands with
      | [.declaration value, .declaration (.definition ..)] =>
        if isPrivate then throw (IO.userError "fixedpoint privacy lost") else pure value
      | [.privateDeclaration value, .declaration (.definition ..)] =>
        if isPrivate then pure value else throw (IO.userError "unexpected fixedpoint privacy")
      | _ => throw (IO.userError "fixedpoint suffix consumed the following declaration")
    match declaration with
    | .fixedpointDefinition name _ _ _ span =>
      if name.segments != ["fixed"] ||
          span.start.byteOffset != (if isPrivate then 8 else 0) ||
          span.stop.byteOffset != text.utf8ByteSize - 1 then
        throw (IO.userError "fixedpoint strategy/source span was not retained")
    | _ => throw (IO.userError "fixedpoint strategy was relabeled as total or partial")
  let body := "function fixed(n: Nat): Nat := fixed(n)\n"
  for (text, expected) in [
      ("partial_fixpoint " ++ body, "PSCV0-FIXPOINT-01"),
      ("const fixed: Nat := 0\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      ("theorem fixed: True := True.intro\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      ("abbrev fixed: Nat := 0\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      ("opaque fixed: Nat := 0\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      ("partial " ++ body ++ "partial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint\ntermination_by n\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint\ndecreasing_by by { rfl }\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint\npartial_fixpoint\n", "PSCV0-REC-STRATEGY-01"),
      (body ++ "partial_fixpoint monotonicity by { rfl }\n", "PSCV0-FIXPOINT-01")] do
    match psPscv0ParseProgram text with
    | .ok _ => throw (IO.userError ("invalid fixedpoint strategy accepted: " ++ text))
    | .error message =>
      if !message.startsWith expected then
        throw (IO.userError ("fixedpoint wrong source refusal: " ++ message))
  let surface ← match psPscv0ParseSource true (body ++ "partial_fixpoint\n") with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let lowered ← match psPscv0LowerModule surface with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  match lowered.declarations with
  | [.fixedpointDefinition ..] => pure ()
  | _ => throw (IO.userError "flat source lowering discarded fixedpoint strategy")
  IO.println "PSCV0_M3_FIXEDPOINT_SOURCE: PASS retained suffix, nullary/private/span ownership and incompatible strategy refusals; assumption admission checked separately"

private def refusals : List (String × String × String) := [
  ("fixedpoint-choice",
    "function fixed(n: Nat): Nat := fixed(n)\npartial_fixpoint\n",
    "PSCV0-FIXPOINT-ASSUMPTION"),
  ("fixedpoint-private-choice",
    "namespace Fix\nprivate function fixed(n: Nat): Nat := fixed(n)\npartial_fixpoint\nend Fix\n",
    "PSCV0-FIXPOINT-ASSUMPTION"),
  ("nested-function-field", "inductive NestedHash where { | node(children: List(Nat -> NestedHash)) } deriving Hashable\n",
    "unsupported recursive field; expected a positive direct family occurrence"),
  ("nested-nonuniform-parameter",
    "inductive BadNested(A: Type) where { | branch(children: List(BadNested(Nat))) }\n",
    "constructor parameters must remain uniform"),
  ("indexed-dependent-field", "inductive IndexedHash: Nat -> Type where { | intro(n: Nat, value: Fin(n)): IndexedHash(n) } deriving Hashable\n",
    "deriving requires independent runtime field types"),
  ("missing-field-dictionary", "inductive FunctionHash where { | leaf(value: Nat -> Nat) | node(next: FunctionHash) } deriving Hashable\n",
    "deriving field has no checked instance"),
  ("repr-nested-function-field", "inductive NestedRepr where { | node(children: List(Nat -> NestedRepr)) } deriving Repr\n",
    "unsupported recursive field; expected a positive direct family occurrence"),
  ("repr-indexed-dependent-field", "inductive IndexedRepr: Nat -> Type where { | intro(n: Nat, value: Fin(n)): IndexedRepr(n) } deriving Repr\n",
    "deriving requires independent runtime field types"),
  ("repr-missing-field-dictionary", "inductive FunctionRepr where { | leaf(value: Nat -> Nat) | node(next: FunctionRepr) } deriving Repr\n",
    "deriving field has no checked instance"),
  ("beq-nested-function-field", "inductive NestedBEq where { | node(children: List(Nat -> NestedBEq)) } deriving BEq\n",
    "unsupported recursive field; expected a positive direct family occurrence"),
  ("beq-indexed", "inductive IndexedBEq: Nat -> Type where { | intro(n: Nat): IndexedBEq n } deriving BEq\n",
    "deriving indexed families is not yet implemented"),
  ("beq-missing-field-dictionary", "inductive FunctionBEq where { | leaf(value: Nat -> Nat) | node(next: FunctionBEq) } deriving BEq\n",
    "deriving field has no checked instance"),
  ("deceq-nested", "inductive NestedDecEq where { | node(children: List NestedDecEq) } deriving DecidableEq\n",
    "recursive deriving requires the M3 data machinery"),
  ("deceq-indexed", "inductive IndexedDecEq: Nat -> Type where { | intro(n: Nat): IndexedDecEq n } deriving DecidableEq\n",
    "deriving indexed families is not yet implemented"),
  ("deceq-missing-field-dictionary", "inductive FunctionDecEq where { | leaf(value: Nat -> Nat) | node(next: FunctionDecEq) } deriving DecidableEq\n",
    "deriving field has no checked instance"),
  ("nondecreasing-major", "function badMajor(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => badMajor(Nat.succ(k)) }\n",
    "recursive major must be a direct recursive field"),
  ("nondecreasing-later-major",
    "function badLaterMajor(flag: Bool, n: Nat): Nat := match n with { | 0 => 0 | k+1 => badLaterMajor(flag, Nat.succ(k)) }\n",
    "recursive major must be a direct recursive field"),
  ("non-child-subtraction",
    "function badSubMajor(n: Nat): Nat := match n with { | 0 => 0 | k+1 => badSubMajor(Nat.sub(k, 1)) }\n",
    "recursive major must be a direct recursive field"),
  ("non-child-infix",
    "function badInfixMajor(n: Nat): Nat := match n with { | 0 => 0 | k+1 => badInfixMajor(k + 1) }\n",
    "recursive major must be a direct recursive field"),
  ("matrix-nonexhaustive",
    "function badMatrix(flag: Bool, n: Nat): Nat := match flag, n with { | true, 0 => 1 }\n",
    "PSCV0-MATCH: missing feasible constructor branch")]

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  checkFixedpointSource
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  -- Preserve the actual submitted source even when qualification fails.
  IO.FS.writeFile (directory / "hashing.ps") source
  let request : PsV7Native.Request := {
    source, sourceName := "m3-recursive-hash.ps", outputStem := "hashing"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected ["m3hashnat", "m3hashbool", "m3reprnat", "m3reprbool", "m3eqnat", "m3eqbool", "m3eqatom", "m3decidenat", "m3decidebool", "m3decideatom", "m3decideproof", "m3normoutput", "m3lateroutput", "m3flipoutput", "m3suboutput", "m3infixoutput", "m3matrixoutput", "m3nestedoutput", "m3nestedarrayoutput", "m3partialoutput", "m3partialcountoutput", "m3nestedoptionoutput", "m3nestedprodoutput", "m3partialcaptureoutput"] }
  let nestedRequest : PsV7Native.Request := {
    source :=
      "inductive M3NestedRose where { | leaf | node(children: List M3NestedRose) }\n" ++
      "function m3nestedtag(r: M3NestedRose): Nat := match r with { | M3NestedRose.leaf => 0 | M3NestedRose.node children => 1 }\n"
    sourceName := "m3-nested-rose.ps" }
  let nestedArrayRequest : PsV7Native.Request := {
    source :=
      "inductive M3NestedArrayRose where { | leaf | node(children: Array M3NestedArrayRose) }\n" ++
      "function m3nestedarraytag(r: M3NestedArrayRose): Nat := match r with { | M3NestedArrayRose.leaf => 0 | M3NestedArrayRose.node children => 1 }\n"
    sourceName := "m3-nested-array-rose.ps" }
  let nestedOptionRequest : PsV7Native.Request := {
    source :=
      "inductive M3NestedOptionRose where { | leaf | node(children: Option M3NestedOptionRose) }\n" ++
      "function m3nestedoptiontag(r: M3NestedOptionRose): Nat := match r with { | M3NestedOptionRose.leaf => 0 | M3NestedOptionRose.node children => 1 }\n"
    sourceName := "m3-nested-option-rose.ps" }
  let nestedProdRequest : PsV7Native.Request := {
    source :=
      "inductive M3NestedProdRose where { | leaf | node(children: Prod M3NestedProdRose M3NestedProdRose) }\n" ++
      "function m3nestedprodtag(r: M3NestedProdRose): Nat := match r with { | M3NestedProdRose.leaf => 0 | M3NestedProdRose.node children => 1 }\n"
    sourceName := "m3-nested-prod-rose.ps" }
  let verifiedRequest : PsV7Native.Request := {
    source, sourceName := "m3-verified-request.ps"
    assurance := .closedVerified
    targets := [.javascript] }
  let requests := #[request, nestedRequest, nestedArrayRequest, nestedOptionRequest,
    nestedProdRequest] ++ (refusals.map fun (_, text, _) =>
    ({ source := text } : PsV7Native.Request)).toArray ++ #[verifiedRequest]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  if batch.results.size != requests.size then
    throw (IO.userError "recursive deriving result count mismatch")
  let some outcome := batch.results[0]? | throw (IO.userError "missing recursive deriving result")
  let result ← match outcome with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  if result.artifacts.length != request.targets.length then
    throw (IO.userError "recursive deriving did not emit every requested target")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let some nestedOutcome := batch.results[1]? | throw (IO.userError "missing nested admission")
  match nestedOutcome with
  | .error error =>
    throw (IO.userError ("nested check-only: " ++ error.phase ++ ": " ++ error.message))
  | .ok nested =>
    if !nested.artifacts.isEmpty || nested.declarationCount < 4 then
      throw (IO.userError "nested check-only failed declaration/artifact boundary")
  let some arrayOutcome := batch.results[2]? | throw (IO.userError "missing nested Array admission")
  match arrayOutcome with
  | .error error =>
    throw (IO.userError ("nested Array check-only: " ++ error.phase ++ ": " ++ error.message))
  | .ok nested =>
    if !nested.artifacts.isEmpty || nested.declarationCount < 4 then
      throw (IO.userError "nested Array check-only failed declaration/artifact boundary")
  for (label, index) in [("Option", 3), ("Prod", 4)] do
    let some outcome := batch.results[index]? |
      throw (IO.userError ("missing nested " ++ label ++ " admission"))
    match outcome with
    | .error error =>
      throw (IO.userError ("nested " ++ label ++ " check-only: " ++
        error.phase ++ ": " ++ error.message))
    | .ok nested =>
      if !nested.artifacts.isEmpty || nested.declarationCount < 4 then
        throw (IO.userError ("nested " ++ label ++ " admission/artifact boundary"))
  for ((label, _, expected), i) in refusals.zipIdx do
    let some outcome := batch.results[i + 5]? | throw (IO.userError "missing deriving refusal")
    match outcome with
    | .ok _ => throw (IO.userError ("deriving unexpectedly accepted " ++ label))
    | .error error =>
      if error.phase != "elaborate" || (error.message.splitOn expected).length < 2 then
        throw (IO.userError (label ++ " failed at wrong phase/rule: " ++ error.phase ++ ": " ++ error.message))
  let some verified := batch.results[requests.size - 1]? |
    throw (IO.userError "missing explicit verified refusal")
  match verified with
  | .ok _ => throw (IO.userError "verified request incorrectly downgraded to ordinary output")
  | .error error =>
    if error.phase != "assurance" ||
        (error.message.splitOn "PSCV0-ASSURANCE-DOWNGRADE").length < 2 then
      throw (IO.userError ("verified request wrong phase/rule: " ++
        error.phase ++ ": " ++ error.message))
  let rows := [false, true].map fun flag => Lean.Json.mkObj [
    ("flag", Lean.toJson flag),
    ("m3hashnat", Lean.toJson (toString ((M3RecursiveHashOracle.natHash flag).toNat))),
    ("m3hashbool", Lean.toJson (toString ((M3RecursiveHashOracle.boolHash flag).toNat))),
    ("m3reprnat", Lean.toJson "1"), ("m3reprbool", Lean.toJson "1"),
    ("m3eqnat", Lean.toJson (toString ((M3RecursiveHashOracle.natEq flag).toNat))),
    ("m3eqbool", Lean.toJson (toString ((M3RecursiveHashOracle.boolEq flag).toNat))),
    ("m3eqatom", Lean.toJson (toString ((M3RecursiveHashOracle.atomEq flag).toNat))),
    ("m3decidenat", Lean.toJson (toString ((M3RecursiveHashOracle.natDecision flag).toNat))),
    ("m3decidebool", Lean.toJson (toString ((M3RecursiveHashOracle.boolDecision flag).toNat))),
    ("m3decideatom", Lean.toJson (toString ((M3RecursiveHashOracle.atomDecision flag).toNat))),
    ("m3decideproof", Lean.toJson (toString ((M3RecursiveHashOracle.proofDecision flag).toNat))),
    ("m3normoutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.normalizedChild (if flag then 17 else 9))).toNat))),
    ("m3lateroutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.laterChild flag (if flag then 17 else 9))).toNat))),
    ("m3flipoutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.flipPrefix flag (if flag then 17 else 9))).toNat))),
    ("m3suboutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.normalizedSubChild (if flag then 17 else 9))).toNat))),
    ("m3infixoutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.infixChild (if flag then 17 else 9))).toNat))),
    ("m3matrixoutput", Lean.toJson (toString ((UInt64.ofNat
      (M3RecursiveHashOracle.matrixSelect flag (if flag then 5 else 0))).toNat))),
    ("m3nestedoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.nestedRoseOutput flag).toNat)),
    ("m3nestedarrayoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.nestedArrayRoseOutput flag).toNat)),
    ("m3partialoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.partialOutput flag).toNat)),
    ("m3partialcountoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.partialCountOutput flag).toNat)),
    ("m3partialcaptureoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.partialCaptureOutput flag).toNat)),
    ("m3nestedoptionoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.nestedOptionRoseOutput flag).toNat)),
    ("m3nestedprodoutput", Lean.toJson (toString
      (M3RecursiveHashOracle.nestedProdRoseOutput flag).toNat)),
    ("reprNatText", Lean.toJson (M3RecursiveHashOracle.natText flag)),
    ("reprBoolText", Lean.toJson (M3RecursiveHashOracle.boolText flag))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_RECURSIVE_HASH: PASS generic direct-recursive derivation, checked defining law, five-target emission and three phase-correct Hashable refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_REPR: PASS generic Nat/Bool, two root precedences, exact native-oracle text at width 40, three phase-correct Repr refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_BEQ: PASS Nat/Bool comparison masks, independent non-reflexive field dictionary, checked recursive defining law, three phase-correct BEq refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_DECEQ: PASS native decision masks, BEq-independent equality, dependent proof field, checked equal/different equations and three phase-correct refusals; runtime checks follow"

