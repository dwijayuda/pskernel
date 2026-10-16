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
  "function m3normoutput(flag: Bool): UInt64 := UInt64.ofNat(m3normalizedChild(if (flag) { 17 } else { 9 }))\n"

private def refusals : List (String × String × String) := [
  ("nested", "inductive NestedHash where { | node(children: List NestedHash) } deriving Hashable\n",
    "recursive deriving requires the M3 data machinery"),
  ("indexed", "inductive IndexedHash: Nat -> Type where { | intro(n: Nat): IndexedHash n } deriving Hashable\n",
    "deriving indexed families is not yet implemented"),
  ("missing-field-dictionary", "inductive FunctionHash where { | leaf(value: Nat -> Nat) | node(next: FunctionHash) } deriving Hashable\n",
    "deriving field has no checked instance"),
  ("repr-nested", "inductive NestedRepr where { | node(children: List NestedRepr) } deriving Repr\n",
    "recursive deriving requires the M3 data machinery"),
  ("repr-indexed", "inductive IndexedRepr: Nat -> Type where { | intro(n: Nat): IndexedRepr n } deriving Repr\n",
    "deriving indexed families is not yet implemented"),
  ("repr-missing-field-dictionary", "inductive FunctionRepr where { | leaf(value: Nat -> Nat) | node(next: FunctionRepr) } deriving Repr\n",
    "deriving field has no checked instance"),
  ("beq-nested", "inductive NestedBEq where { | node(children: List NestedBEq) } deriving BEq\n",
    "recursive deriving requires the M3 data machinery"),
  ("beq-indexed", "inductive IndexedBEq: Nat -> Type where { | intro(n: Nat): IndexedBEq n } deriving BEq\n",
    "deriving indexed families is not yet implemented"),
  ("beq-missing-field-dictionary", "inductive FunctionBEq where { | leaf(value: Nat -> Nat) | node(next: FunctionBEq) } deriving BEq\n",
    "deriving field has no checked instance"),
  ("deceq-nested", "inductive NestedDecEq where { | node(children: List NestedDecEq) } deriving DecidableEq\n",
    "recursive deriving requires the M3 data machinery"),
  ("deceq-indexed", "inductive IndexedDecEq: Nat -> Type where { | intro(n: Nat): IndexedDecEq n } deriving DecidableEq\n",
    "deriving indexed families is not yet implemented"),
  ("deceq-missing-field-dictionary", "inductive FunctionDecEq where { | leaf(value: Nat -> Nat) | node(next: FunctionDecEq) } deriving DecidableEq\n",
    "deriving field has no checked instance")]

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  -- Preserve the actual submitted source even when qualification fails.
  IO.FS.writeFile (directory / "hashing.ps") source
  let request : PsV7Native.Request := {
    source, sourceName := "m3-recursive-hash.ps", outputStem := "hashing"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected ["m3hashnat", "m3hashbool", "m3reprnat", "m3reprbool", "m3eqnat", "m3eqbool", "m3eqatom", "m3decidenat", "m3decidebool", "m3decideatom", "m3decideproof", "m3normoutput"] }
  let requests := #[request] ++ (refusals.map fun (_, text, _) =>
    ({ source := text } : PsV7Native.Request)).toArray
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
  for ((label, _, expected), i) in refusals.zipIdx do
    let some outcome := batch.results[i + 1]? | throw (IO.userError "missing deriving refusal")
    match outcome with
    | .ok _ => throw (IO.userError ("deriving unexpectedly accepted " ++ label))
    | .error error =>
      if error.phase != "elaborate" || (error.message.splitOn expected).length < 2 then
        throw (IO.userError (label ++ " failed at wrong phase/rule: " ++ error.phase ++ ": " ++ error.message))
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
    ("reprNatText", Lean.toJson (M3RecursiveHashOracle.natText flag)),
    ("reprBoolText", Lean.toJson (M3RecursiveHashOracle.boolText flag))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_RECURSIVE_HASH: PASS generic direct-recursive derivation, checked defining law, five-target emission and three phase-correct Hashable refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_REPR: PASS generic Nat/Bool, two root precedences, exact native-oracle text at width 40, three phase-correct Repr refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_BEQ: PASS Nat/Bool comparison masks, independent non-reflexive field dictionary, checked recursive defining law, three phase-correct BEq refusals; runtime checks follow"
  IO.println "PSCV0_M3_RECURSIVE_DECEQ: PASS native decision masks, BEq-independent equality, dependent proof field, checked equal/different equations and three phase-correct refusals; runtime checks follow"
