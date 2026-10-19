import Ps.Host.NativeV7
import PsKernelLean.Admission

namespace CoreM3PatternOracle
inductive CorePatternTag where
  | off
  | on
open CorePatternTag
def corePatternLength (xs : List Nat) : Nat :=
  match xs with
  | [] => 0
  | _ :: tail => Nat.succ (corePatternLength tail)
def corePatternShape (xs : List Nat) : Nat :=
  match xs with
  | [] => 7
  | [x,] => x + 10
  | x :: y :: rest => x + y + corePatternLength rest
def corePatternPair (left right : List Nat) : Nat :=
  match left, right with
  | [], [x] | [x], [] => x
  | _, _ => 99
def corePatternNested (xs : List (Option (Nat × Nat))) : Nat :=
  match xs with
  | [Option.some (x, y)] => x + y
  | _ => 0
def corePatternSuccessor (xs : List Nat) : Nat :=
  match xs with
  | (k + 1) :: _ => k
  | _ => 17
def corePatternOpened (tag : CorePatternTag) : Nat :=
  match tag with
  | off => 11
  | on => 13
def corePatternQualified (tag : CorePatternTag) : Nat :=
  match tag with
  | CorePatternTag.off => 11
  | CorePatternTag.on => 13
def corePatternCatch (n : Nat) : Nat := match n with
  | number => number
def corePatternChoice (left right : Bool) : Nat :=
  match left, right with
  | true, _ | _, true => 1
  | _, _ => 2
def m3patterns (flag : Bool) : UInt64 :=
  let xs := if flag then [1, 2, 3] else [5]
  UInt64.ofNat (corePatternLength xs + corePatternShape xs +
    corePatternPair (if flag then [] else [8]) (if flag then [7] else []) +
    corePatternNested (if flag then [Option.some (4, 5)] else []) +
    corePatternSuccessor [if flag then 3 else 4] +
    corePatternOpened (if flag then CorePatternTag.on else CorePatternTag.off) +
    corePatternCatch (if flag then 11 else 7))
theorem corePatternLengthEquation : corePatternLength [1, 2, 3] = 3 := by rfl
theorem corePatternShapeEquation : corePatternShape [1, 2, 3] = 4 := by rfl
theorem corePatternPairLeftEquation : corePatternPair [] [7] = 7 := by rfl
theorem corePatternPairRightEquation : corePatternPair [8] [] = 8 := by rfl
theorem corePatternPairFallbackEquation : corePatternPair [8] [9] = 99 := by rfl
theorem corePatternNestedEquation : corePatternNested [Option.some (4, 5)] = 9 := by rfl
theorem corePatternOpenedEquation : corePatternOpened CorePatternTag.on = 13 := by rfl
theorem corePatternQualifiedEquation : corePatternQualified CorePatternTag.off = 11 := by rfl
theorem corePatternCatchEquation : corePatternCatch 29 = 29 := by rfl
theorem corePatternChoiceEquation : corePatternChoice false true = 1 := by rfl
theorem corePatternChoiceFallbackEquation : corePatternChoice false false = 2 := by rfl
theorem corePatternFalseEquation : m3patterns false = 45 := by rfl
theorem corePatternTrueEquation : m3patterns true = 49 := by rfl

end CoreM3PatternOracle

namespace CoreM3Patterns

private def leanSource : String := "inductive CorePatternTag where\n  | off\n  | on\nopen CorePatternTag\ndef corePatternLength (xs : List Nat) : Nat :=\n  match xs with\n  | [] => 0\n  | _ :: tail => Nat.succ (corePatternLength tail)\ndef corePatternShape (xs : List Nat) : Nat :=\n  match xs with\n  | [] => 7\n  | [x,] => x + 10\n  | x :: y :: rest => x + y + corePatternLength rest\ndef corePatternPair (left right : List Nat) : Nat :=\n  match left, right with\n  | [], [x] | [x], [] => x\n  | _, _ => 99\ndef corePatternNested (xs : List (Option (Nat × Nat))) : Nat :=\n  match xs with\n  | [Option.some (x, y)] => x + y\n  | _ => 0\ndef corePatternSuccessor (xs : List Nat) : Nat :=\n  match xs with\n  | (k + 1) :: _ => k\n  | _ => 17\ndef corePatternOpened (tag : CorePatternTag) : Nat :=\n  match tag with\n  | off => 11\n  | on => 13\ndef corePatternQualified (tag : CorePatternTag) : Nat :=\n  match tag with\n  | CorePatternTag.off => 11\n  | CorePatternTag.on => 13\ndef corePatternCatch (n : Nat) : Nat := match n with\n  | number => number\ndef corePatternChoice (left right : Bool) : Nat :=\n  match left, right with\n  | true, _ | _, true => 1\n  | _, _ => 2\ndef m3patterns (flag : Bool) : UInt64 :=\n  let xs := if flag then [1, 2, 3] else [5]\n  UInt64.ofNat (corePatternLength xs + corePatternShape xs +\n    corePatternPair (if flag then [] else [8]) (if flag then [7] else []) +\n    corePatternNested (if flag then [Option.some (4, 5)] else []) +\n    corePatternSuccessor [if flag then 3 else 4] +\n    corePatternOpened (if flag then CorePatternTag.on else CorePatternTag.off) +\n    corePatternCatch (if flag then 11 else 7))\ntheorem corePatternLengthEquation : corePatternLength [1, 2, 3] = 3 := by rfl\ntheorem corePatternShapeEquation : corePatternShape [1, 2, 3] = 4 := by rfl\ntheorem corePatternPairLeftEquation : corePatternPair [] [7] = 7 := by rfl\ntheorem corePatternPairRightEquation : corePatternPair [8] [] = 8 := by rfl\ntheorem corePatternPairFallbackEquation : corePatternPair [8] [9] = 99 := by rfl\ntheorem corePatternNestedEquation : corePatternNested [Option.some (4, 5)] = 9 := by rfl\ntheorem corePatternOpenedEquation : corePatternOpened CorePatternTag.on = 13 := by rfl\ntheorem corePatternQualifiedEquation : corePatternQualified CorePatternTag.off = 11 := by rfl\ntheorem corePatternCatchEquation : corePatternCatch 29 = 29 := by rfl\ntheorem corePatternChoiceEquation : corePatternChoice false true = 1 := by rfl\ntheorem corePatternChoiceFallbackEquation : corePatternChoice false false = 2 := by rfl\ntheorem corePatternFalseEquation : m3patterns false = 45 := by rfl\ntheorem corePatternTrueEquation : m3patterns true = 49 := by rfl\n"
private def psSource : String := "inductive CorePatternTag where {\n  | off\n  | on\n}\nopen CorePatternTag\nfunction corePatternLength(xs: List(Nat)): Nat :=\n  match xs with {\n  | [] => 0\n  | _ :: tail => Nat.succ(corePatternLength(tail))\n  }\nfunction corePatternShape(xs: List(Nat)): Nat :=\n  match xs with {\n  | [] => 7\n  | [x,] => x + 10\n  | x :: y :: rest => x + y + corePatternLength(rest)\n  }\nfunction corePatternPair(left: List(Nat), right: List(Nat)): Nat :=\n  match left, right with {\n  | [], [x] | [x], [] => x\n  | _, _ => 99\n  }\nfunction corePatternNested(xs: List(Option(Nat × Nat))): Nat :=\n  match xs with {\n  | [Option.some (x, y)] => x + y\n  | _ => 0\n  }\nfunction corePatternSuccessor(xs: List(Nat)): Nat :=\n  match xs with {\n  | (k + 1) :: _ => k\n  | _ => 17\n  }\nfunction corePatternOpened(tag: CorePatternTag): Nat :=\n  match tag with {\n  | off => 11\n  | on => 13\n  }\nfunction corePatternQualified(tag: CorePatternTag): Nat :=\n  match tag with {\n  | CorePatternTag.off => 11\n  | CorePatternTag.on => 13\n  }\nfunction corePatternCatch(n: Nat): Nat := match n with {\n  | number => number\n}\nfunction corePatternChoice(left: Bool, right: Bool): Nat :=\n  match left, right with {\n  | true, _ | _, true => 1\n  | _, _ => 2\n  }\nfunction m3patterns(flag: Bool): UInt64 :=\n  let xs := if (flag) { [1, 2, 3] } else { [5] }\n  UInt64.ofNat(corePatternLength(xs) + corePatternShape(xs) +\n    corePatternPair(if (flag) { [] } else { [8] }, if (flag) { [7] } else { [] }) +\n    corePatternNested(if (flag) { [Option.some((4, 5))] } else { [] }) +\n    corePatternSuccessor([if (flag) { 3 } else { 4 }]) +\n    corePatternOpened(if (flag) { CorePatternTag.on } else { CorePatternTag.off }) +\n    corePatternCatch(if (flag) { 11 } else { 7 }))\ntheorem corePatternLengthEquation: corePatternLength([1, 2, 3]) = 3 := by { rfl }\ntheorem corePatternShapeEquation: corePatternShape([1, 2, 3]) = 4 := by { rfl }\ntheorem corePatternPairLeftEquation: corePatternPair([], [7]) = 7 := by { rfl }\ntheorem corePatternPairRightEquation: corePatternPair([8], []) = 8 := by { rfl }\ntheorem corePatternPairFallbackEquation: corePatternPair([8], [9]) = 99 := by { rfl }\ntheorem corePatternNestedEquation: corePatternNested([Option.some((4, 5))]) = 9 := by { rfl }\ntheorem corePatternOpenedEquation: corePatternOpened(CorePatternTag.on) = 13 := by { rfl }\ntheorem corePatternQualifiedEquation: corePatternQualified(CorePatternTag.off) = 11 := by { rfl }\ntheorem corePatternCatchEquation: corePatternCatch(29) = 29 := by { rfl }\ntheorem corePatternChoiceEquation: corePatternChoice(false, true) = 1 := by { rfl }\ntheorem corePatternChoiceFallbackEquation: corePatternChoice(false, false) = 2 := by { rfl }\ntheorem corePatternFalseEquation: m3patterns(false) = 45 := by { rfl }\ntheorem corePatternTrueEquation: m3patterns(true) = 49 := by { rfl }\n"

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError message)

private def fromExcept {α : Type} (value : Except String α) : IO α :=
  match value with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def causeTag : PsElabError → String
  | .atDeclaration _ cause | .atContext _ cause => causeTag cause
  | .matchNonExhaustive => "coverage"
  | .scope message =>
    if message.startsWith "duplicate pattern variable" then "duplicate"
    else if message.startsWith "unknown name x" then "missing-alternative-binder"
    else "other-scope"
  | .refinement message =>
    if message == "pattern row/discriminant arity mismatch" then "row-arity" else "other-refinement"
  | .matchConstructorUnknown name => "constructor:" ++ psNameToString name
  | _ => "other"

private def requireElaborationRefusal (tag : String)
    (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  let program ← fromExcept (psCompilerParsePscv0 source kind)
  match psCompilerEngineElaboratePscv0 psCompilerFullProfileContext program with
  | .error (.elaboration cause) =>
    ensure (causeTag cause == tag)
      ("CORE-PATTERNS: " ++ tag ++ " refusal changed owner: " ++ psCompilerPscv0ElabError cause)
  | .error error => throw (IO.userError ("CORE-PATTERNS: refusal changed phase: " ++ psCompilerPscv0Error error))
  | .ok _ => throw (IO.userError ("CORE-PATTERNS: accepted " ++ tag ++ " refusal"))

private def checkRefusals : IO Unit := do
  let cases : List (String × String × String) := [
    ("coverage", "def bad (xs : List Nat) : Nat := match xs with\n  | [] => 0\n", "function bad(xs: List(Nat)): Nat := match xs with { | [] => 0 }\n"),
    ("duplicate", "def bad (xs : List Nat) : Nat := match xs with\n  | [x, x] => 0\n  | _ => 1\n", "function bad(xs: List(Nat)): Nat := match xs with { | [x, x] => 0 | _ => 1 }\n"),
    ("missing-alternative-binder", "def bad (left right : List Nat) : Nat := match left, right with\n  | [], [x] | [], [] => x\n  | _, _ => 0\n", "function bad(left: List(Nat), right: List(Nat)): Nat := match left, right with { | [], [x] | [], [] => x | _, _ => 0 }\n"),
    ("row-arity", "def bad (left right : List Nat) : Nat := match left, right with\n  | [] | [], [] => 0\n  | _, _ => 1\n", "function bad(left: List(Nat), right: List(Nat)): Nat := match left, right with { | [] | [], [] => 0 | _, _ => 1 }\n"),
    ("constructor:List.nil", "def bad (flag : Bool) : Nat := match flag with\n  | [] => 0\n  | _ => 1\n", "function bad(flag: Bool): Nat := match flag with { | [] => 0 | _ => 1 }\n"),
    ("constructor:Nat.succ", "def bad (xs : List Nat) : Nat := match xs with\n  | x :: k + 1 => x\n  | _ => 0\n", "function bad(xs: List(Nat)): Nat := match xs with { | x :: k + 1 => x | _ => 0 }\n")]
  for (tag, lean, ps) in cases do
    requireElaborationRefusal tag .lean lean
    requireElaborationRefusal tag .proofScript ps
  let parseCases : List (String × String) := [
    ("def bad (xs : List Nat) : Nat := match xs with\n  | k + 1 :: rest => k\n  | _ => 0\n", "function bad(xs: List(Nat)): Nat := match xs with { | k + 1 :: rest => k | _ => 0 }\n"),
    ("def bad (n : Nat) : Nat := match n with\n  | 1 + k => k\n  | _ => 0\n", "function bad(n: Nat): Nat := match n with { | 1 + k => k | _ => 0 }\n"),
    ("def bad (x : Option (Nat × Nat)) : Nat := match x with\n  | .some(x,y) => x\n  | _ => 0\n", "function bad(x: Option(Nat × Nat)): Nat := match x with { | .some(x,y) => x | _ => 0 }\n"),
    ("def bad (x : Option (List Nat)) : Nat := match x with\n  | .some[x] => x\n  | _ => 0\n", "function bad(x: Option(List(Nat))): Nat := match x with { | .some[x] => x | _ => 0 }\n"),
    ("def bad (pair : Nat × Nat) : Nat := match pair with\n  | Prod.mk (x)(y) => x\n", "function bad(pair: Nat × Nat): Nat := match pair with { | Prod.mk (x)(y) => x }\n")]
  for (lean, ps) in parseCases do
    ensure (!(psCompilerParsePscv0 lean .lean).isOk) "CORE-PATTERNS: invalid native pattern parsed"
    ensure (!(psCompilerParsePscv0 ps .proofScript).isOk) "CORE-PATTERNS: invalid ProofScript pattern parsed"

private def emit (sourceName source : String) (ir : PsVerifiedIrModule) :
    Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := { sourceName, sourceText := source, outputStem := "corepatterns" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "corepatterns" []
    return [js, ts, rust]
  return artifacts

end CoreM3Patterns

open CoreM3Patterns in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "CORE-PATTERNS: expected pinned Lean 4.35.0"
  let _ ← fromExcept psCompilerValidatePscv0Standard
  let sources : List (PsCompilerSourceKind × String × String) :=
    [(.lean, leanSource, "lean"), (.proofScript, psSource, "ps")]
  let outputs ← sources.mapM fun (kind, source, _) =>
    fromExcept ((psCompilerEnginePreparePscv0WithOutput psCompilerFullProfileContext kind source).mapError psCompilerPscv0Error)
  let [left, right] := outputs | throw (IO.userError "CORE-PATTERNS: paired preparation missing")
  ensure (left.admissions == right.admissions) "CORE-PATTERNS: paired canonical admissions differ"
  let _ ← fromExcept ((← PsKernelLean.admitCanonicalAdmissions left.admissions).mapError (·.message))
  checkRefusals
  for ((kind, source, stem), output) in sources.zip outputs do
    let ir ← fromExcept ((psCompilerEngineVerifiedIrFromPrepared output.prepared).mapError psCompilerPscv0Error)
    let artifacts ← fromExcept (emit ("corepatterns" ++ psCompilerSourceKindExtension kind) source ir)
    ensure (artifacts.length == 3) "CORE-PATTERNS: missing required target"
    let root := System.FilePath.mk directory / stem
    IO.FS.createDirAll root
    IO.FS.writeFile (root / ("source" ++ psCompilerSourceKindExtension kind)) source
    IO.FS.writeFile (root / "admissions.jsonl") output.admissions
    for artifact in artifacts do
      for file in artifact.files do
        match file.payload with
        | .text value => IO.FS.writeFile (root / file.path) value
        | .binary value => IO.FS.writeBinFile (root / file.path) value
    let rows := [false, true].map fun flag => Lean.Json.mkObj [
      ("flag", Lean.toJson flag),
      ("m3patterns", Lean.toJson (toString (CoreM3PatternOracle.m3patterns flag).toNat))]
    IO.FS.writeFile (root / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_CORE_PATTERNS: PASS 2 paired programs, 13 equations per program, 12 owned elaboration refusals, 10 parser refusals, canonical equality, independent trust-zero admission, native oracle and TS/JS/Rust emission; runtime execution follows"
