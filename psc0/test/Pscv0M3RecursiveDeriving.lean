import Ps.Host.NativeV7

-- Independent pinned Lean oracle. The portable source below is parsed and
-- elaborated separately, and its defining law is checked by the official kernel.
namespace M3RecursiveHashOracle
inductive Tree (A : Type) where
  | leaf : A → Tree A
  | fork : Tree A → Tree A → Tree A
  deriving Hashable

def natHash (flag : Bool) : UInt64 :=
  let n : Nat := if flag then 71 else 13
  hash (Tree.fork (Tree.leaf n)
    (Tree.fork (Tree.leaf (n + 1)) (Tree.leaf (n + 2))))

def boolHash (flag : Bool) : UInt64 :=
  hash (Tree.fork (Tree.leaf flag) (Tree.leaf (!flag)))
end M3RecursiveHashOracle

private def source : String :=
  "universe u\n" ++
  "inductive M3HashTree(A: Type u): Type u where {\n" ++
  " | leaf(value: A)\n" ++
  " | fork(left: M3HashTree A, right: M3HashTree A)\n" ++
  "} deriving Hashable\n" ++
  "function m3hashnat(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 71 } else { 13 }\n" ++
  " Hashable.hash(M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.fork(M3HashTree.leaf(n + 1), M3HashTree.leaf(n + 2))))\n" ++
  "}\n" ++
  "function m3hashbool(flag: Bool): UInt64 := Hashable.hash(M3HashTree.fork(M3HashTree.leaf(flag), M3HashTree.leaf(Bool.not(flag))))\n" ++
  "theorem m3hashlaw(n: Nat, m: Nat): Hashable.hash(M3HashTree.fork(M3HashTree.leaf(n), M3HashTree.leaf(m))) = mixHash(mixHash(UInt64.ofNat(1), mixHash(UInt64.ofNat(0), Hashable.hash(n))), mixHash(UInt64.ofNat(0), Hashable.hash(m))) := by { rfl }\n"

private def refusals : List (String × String × String) := [
  ("nested", "inductive NestedHash where { | node(children: List NestedHash) } deriving Hashable\n",
    "recursive deriving requires the M3 data machinery"),
  ("indexed", "inductive IndexedHash: Nat -> Type where { | intro(n: Nat): IndexedHash n } deriving Hashable\n",
    "deriving indexed families is not yet implemented"),
  ("missing-field-dictionary", "inductive FunctionHash where { | leaf(value: Nat -> Nat) | node(next: FunctionHash) } deriving Hashable\n",
    "deriving field has no checked instance")]

def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  let request : PsV7Native.Request := {
    source, sourceName := "m3-recursive-hash.ps", outputStem := "hashing"
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent]
    exports := .selected ["m3hashnat", "m3hashbool"] }
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
    ("m3hashbool", Lean.toJson (toString ((M3RecursiveHashOracle.boolHash flag).toNat)))]
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.FS.writeFile (directory / "hashing.ps") source
  IO.println "PSCV0_M3_RECURSIVE_HASH: PASS generic direct-recursive derivation, checked defining law, five-target emission and three phase-correct refusals; runtime checks follow"
