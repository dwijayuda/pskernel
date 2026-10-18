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

example : m3data true = 6 := by simp only [m3data, m3data.keep]; rfl
example : m3data false = 9 := by simp only [m3data, m3data.keep]; rfl
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
    | .theoremDecl ln ll lt lv, .theoremDecl rn rl rt rv =>
      ensure (psNameEq ln rn && psElabMutualLevelNamesEqual ll rl &&
        psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("source adapters changed checked value " ++ psNameToString ln)
    | _, _ => throw (IO.userError "parity fixture expected matching definitions or generated equation theorems")

def check (root : System.FilePath) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "input parity requires pinned Lean4.35.0"
  let native ← fromExcept (checkedDeclarations .lean leanSource)
  let proofscript ← fromExcept (checkedDeclarations .proofScript psSource)
  compareCheckedValues native proofscript
  let grouped := "def grouped {T : Type} {first value : T} := value\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean grouped))
    (← fromExcept (checkedDeclarations .proofScript grouped))
  let richLean := "universe u\ndef identity {A : Type u} (a : A) : A := a\n" ++
    "def choose (x y : Nat) (flag : Bool) : Nat := if flag then x + y else x\n" ++
    "def chosen : Nat := choose (flag := true) (y := 4) (x := 3)\n" ++
    "def scalar : Float := 1.25\n"
  let richPs := "universe u\nfunction identity{A: Type u}(a: A): A := a\n" ++
    "function choose(x: Nat, y: Nat, flag: Bool): Nat := if (flag) { x + y } else { x }\n" ++
    "const chosen: Nat := choose(flag := true, y := 4, x := 3)\n" ++
    "const scalar: Float := 1.25\n"
  compareCheckedValues (← fromExcept (checkedDeclarations .lean richLean))
    (← fromExcept (checkedDeclarations .proofScript richPs))
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
  let provider : PsPscv0ModuleSource := {
    name := "Library", sourceKind := .lean
    source := "def library (n : Nat) : Nat := Nat.succ n\n" }
  let project ← fromExcept (psPscv0ProjectParse [provider,
    { name := "Main", source := "import Library\nconst answer: Nat := library(3)\n" }])
  ensure ((project.map (·.sourceName)) == ["Library.lean", "Main.ps"])
    "mixed input module planning lost source-kind provenance"
  let request := fun kind source stem => ({
    sourceKind := kind, source, sourceName := stem ++ psCompilerSourceKindExtension kind
    outputStem := "inputparity", exports := .selected ["m3parity", "m3data"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] } : PsV7Native.Request)
  let requests := #[
    request .lean (dataLeanSource ++ leanSource ++ "theorem observed : m3parity true = 13 := by rfl\n") "native-input", request .proofScript (dataPsSource ++ psSource ++ "theorem observed: m3parity(true) = 13 := by { rfl }\n") "proofscript-input",
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
          ("m3parity", Lean.toJson (toString (M3InputParityOracle.m3parity flag).toNat)),
          ("m3data", Lean.toJson (toString (M3InputParityOracle.m3data flag).toNat))]
        IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INPUT_PARITY: PASS native source routing, shared checked Core, universe/named/operator/scientific terms, native proofs, data/classes/instances/deriving, ordered binder scope/default ownership, both mixed-module directions, official kernel, five-target emission and assurance refusals; full native term/command parity remains open"
end M3InputParity
