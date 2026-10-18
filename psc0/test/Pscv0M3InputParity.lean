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
def shadow {T : Type} {T value : T} := value
example : @shadow Nat 3 4 = 4 := rfl
example : m3parity false = 4 := rfl
example : m3parity true = 13 := rfl
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

private def checkedDeclarations (kind : PsCompilerSourceKind) (source : String) :
    Except String (List PsDeclaration) := do
  let syntax ← psCompilerParsePscv0 source kind
  let elaborated ← (psCompilerElaboratePscv0 syntax).mapError psCompilerPscv0Error
  return elaborated.declarations

private def compareDefinitions (left right : List PsDeclaration) : IO Unit := do
  ensure (left.length == right.length) "source adapters changed the declaration count"
  for (left, right) in left.zip right do
    match left, right with
    | .definitionDecl ln ll lt lv, .definitionDecl rn rl rt rv =>
      ensure (psNameEq ln rn && psElabMutualLevelNamesEqual ll rl &&
        psExprAlphaEq lt rt && psExprAlphaEq lv rv)
        ("source adapters changed checked definition " ++ psNameToString ln)
    | _, _ => throw (IO.userError "parity fixture expected ordinary definitions")

def check (root : System.FilePath) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "input parity requires pinned Lean4.35.0"
  let native ← fromExcept (checkedDeclarations .lean leanSource)
  let proofscript ← fromExcept (checkedDeclarations .proofScript psSource)
  compareDefinitions native proofscript
  let grouped := "def shadow {T : Type} {T value : T} := value\n"
  compareDefinitions (← fromExcept (checkedDeclarations .lean grouped))
    (← fromExcept (checkedDeclarations .proofScript grouped))
  -- Real input routing, not a host oracle or source-printer round trip.
  for (kind, wrong) in [(PsCompilerSourceKind.lean, psSource),
      (PsCompilerSourceKind.proofScript, leanSource)] do
    ensure ((psCompilerParsePscv0 wrong kind).isError)
      "source-kind selection silently accepted the other grammar"
  for source in ["axiom unapproved : Nat\n",
      "def f (n : Nat) : Nat := n\ntermination_by structural n\n",
      "def f (n : Nat) : Nat := n\npartial_fixpoint monotonicity by exact id\n"] do
    ensure ((psCompilerParsePscv0 source .lean).isError)
      "native source selection admitted an unselected declaration or strategy"
  let provider : PsPscv0ModuleSource := {
    name := "Library", sourceKind := .lean
    source := "def library (n : Nat) : Nat := Nat.succ n\n" }
  let project ← fromExcept (psPscv0ProjectParse [provider,
    { name := "Main", source := "import Library\nconst answer: Nat := library(3)\n" }])
  ensure ((project.map (·.sourceName)) == ["Library.lean", "Main.ps"])
    "mixed input module planning lost source-kind provenance"
  let request := fun kind source stem => ({
    sourceKind := kind, source, sourceName := stem ++ psCompilerSourceKindExtension kind
    outputStem := "inputparity", exports := .selected ["m3parity"]
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] } : PsV7Native.Request)
  let requests := #[
    request .lean leanSource "native-input", request .proofScript psSource "proofscript-input",
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
          ("m3parity", Lean.toJson (toString (M3InputParityOracle.m3parity flag).toNat))]
        IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INPUT_PARITY: PASS native source routing, shared checked Core, scope/default/group ownership, both mixed-module directions, official kernel, five-target emission and assurance refusals; full native term/command parity remains open"
end M3InputParity
