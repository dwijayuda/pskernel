import Ps.Host.LeanChecked
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Validate

private def fail (label detail : String) : IO α :=
  throw (IO.userError ("PSC1_DATA_FAIL: " ++ label ++ ": " ++ detail))

private def prepare (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO PsCompilerAdmissionReadyModule := do
  let prepared ← match psCompilerPrepareSource kind source with
    | .ok value => pure value
    | .error (.leanFrontend (.lex error)) => fail label (psHostLexErrorText error)
    | .error (.leanFrontend (.parse error)) => fail label (psHostParseErrorText error)
    | .error (.proofScriptFrontend (.lex error)) => fail label (psHostLexErrorText error)
    | .error (.proofScriptFrontend (.parse error)) => fail label (psHostParseErrorText error)
    | .error (.elaboration error) => fail label (psHostElabErrorText error)
    | .error _ => fail label "preparation"
  match ← psHostLeanCheckPrepared prepared with
  | .error error => fail label error
  | .ok _ => pure ()
  let ir ← match psCompilerVerifiedIrFromPrepared prepared with
    | .error _ => fail label "erasure"
    | .ok value => pure value
  match psStrictValidateModule ir with
  | .error _ => fail label "strict typed IR validation"
  | .ok _ => pure ()
  return prepared

private def same (label : String) (kind : PsCompilerSourceKind)
    (actual expected : String) : IO Unit := do
  let first ← prepare label kind actual
  let second ← prepare (label ++ " named form") kind expected
  match psCompilerAdmissionsFromPrepared first, psCompilerAdmissionsFromPrepared second with
  | .ok left, .ok right =>
      if left != right then fail label "literal changed canonical checked Core"
  | _, _ => fail label "canonical admission encoding"
  IO.println ("PSC1_DATA_PASS: " ++ label)

private def rejectedParse (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  match psCompilerParseSource kind source with
  | .error _ => IO.println ("PSC1_DATA_PASS: " ++ label)
  | .ok _ => fail label "malformed source parsed"

private def rejectedType (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let parsed ← match psCompilerParseSource kind source with
    | .error _ => fail label "negative typing example failed to parse"
    | .ok value => pure value
  match psCompilerElaborateModule parsed with
  | .error _ => IO.println ("PSC1_DATA_PASS: " ++ label)
  | .ok _ => fail label "ill-typed source elaborated"

private def roundTrip (label : String) (kind other : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let initial ← prepare label kind source
  let translated ← match psCompilerTranslateSource kind other source with
    | .error _ => fail label "translation"
    | .ok text => pure text
  let restored ← prepare label other translated
  match psCompilerAdmissionsFromPrepared initial, psCompilerAdmissionsFromPrepared restored with
  | .ok first, .ok second =>
      if first != second then fail label "translation changed canonical admission"
  | _, _ => fail label "translation admission encoding"

def main : IO Unit := do
  same "Lean right-associated tuple with contextual Int" .lean
    "def result : Prod Int (Prod Bool Nat) := (1, true, 2)\n"
    "def result : Prod Int (Prod Bool Nat) := Prod.mk 1 (Prod.mk true 2)\n"
  same "PS right-associated tuple with contextual Int" .proofScript
    "def result : Prod(Int, Prod(Bool, Nat)) := (1, true, 2)\n"
    "def result : Prod(Int, Prod(Bool, Nat)) := Prod.mk(1, Prod.mk(true, 2))\n"
  same "Lean nested tuple with trailing comma" .lean
    "def result : Prod (Prod Nat Bool) Int := ((1, true), 2,)\n"
    "def result : Prod (Prod Nat Bool) Int := Prod.mk (Prod.mk 1 true) 2\n"
  same "PS nested tuple with trailing comma" .proofScript
    "def result : Prod(Prod(Nat, Bool), Int) := ((1, true), 2,)\n"
    "def result : Prod(Prod(Nat, Bool), Int) := Prod.mk(Prod.mk(1, true), 2)\n"
  same "Lean inferred tuple local and projection" .lean
    "def result : Nat := let pair := (7, true); Prod.fst pair\n"
    "def result : Nat := let pair := Prod.mk 7 true; Prod.fst pair\n"
  same "PS inferred tuple local and projection" .proofScript
    "def result : Nat := let pair := (7, true)\n Prod.fst(pair)\n"
    "def result : Nat := let pair := Prod.mk(7, true)\n Prod.fst(pair)\n"
  same "Lean tuple in application" .lean
    "def first (pair : Prod Int Bool) : Int := Prod.fst pair\ndef result : Int := first (9, false)\n"
    "def first (pair : Prod Int Bool) : Int := Prod.fst pair\ndef result : Int := first (Prod.mk 9 false)\n"
  same "PS tuple argument and two arguments stay distinct" .proofScript
    "def first(pair : Prod(Int, Bool)) : Int := Prod.fst(pair)\ndef two(left : Int, right : Bool) : Int := left\ndef result : Int := first((9, false)) + two(2, true)\n"
    "def first(pair : Prod(Int, Bool)) : Int := Prod.fst(pair)\ndef two(left : Int, right : Bool) : Int := left\ndef result : Int := first(Prod.mk(9, false)) + two(2, true)\n"
  same "Lean Unit and grouping" .lean
    "def unit : Unit := ()\ndef result : Int := (7)\n"
    "def unit : Unit := Unit.unit\ndef result : Int := 7\n"
  same "PS Unit and grouping" .proofScript
    "def unit : Unit := ()\ndef result : Int := (7)\n"
    "def unit : Unit := Unit.unit\ndef result : Int := 7\n"
  same "Lean typed empty array" .lean
    "def result : Array Int := #[]\n"
    "def result : Array Int := Array.emptyWithCapacity 0\n"
  same "PS typed empty array" .proofScript
    "def result : Array(Int) := #[]\n"
    "def result : Array(Int) := Array.emptyWithCapacity(0)\n"
  same "Lean array values preserve order and contextual Int" .lean
    "def result : Array Int := #[1, -2, 3,]\n"
    "def result : Array Int := Array.push (Array.push (Array.push (Array.emptyWithCapacity 0) 1) (-2)) 3\n"
  same "PS array values preserve order and contextual Int" .proofScript
    "def result : Array(Int) := #[1, -2, 3,]\n"
    "def result : Array(Int) := Array.push(Array.push(Array.push(Array.emptyWithCapacity(0), 1), -2), 3)\n"
  same "Lean inferred array passed without grouping" .lean
    "def result : Nat := Array.size #[7, 8]\n"
    "def result : Nat := Array.size (Array.push (Array.push (Array.emptyWithCapacity 0) 7) 8)\n"
  same "PS inferred array argument" .proofScript
    "def result : Nat := Array.size(#[7, 8])\n"
    "def result : Nat := Array.size(Array.push(Array.push(Array.emptyWithCapacity(0), 7), 8))\n"
  same "Lean array of tuples" .lean
    "def result : Array (Prod Int Bool) := #[(1, true), (2, false)]\n"
    "def result : Array (Prod Int Bool) := Array.push (Array.push (Array.emptyWithCapacity 0) (Prod.mk 1 true)) (Prod.mk 2 false)\n"
  same "PS array of tuples" .proofScript
    "def result : Array(Prod(Int, Bool)) := #[(1, true), (2, false)]\n"
    "def result : Array(Prod(Int, Bool)) := Array.push(Array.push(Array.emptyWithCapacity(0), Prod.mk(1, true)), Prod.mk(2, false))\n"
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    rejectedParse "singleton comma is not a tuple" kind "def result : Nat := (1,)\n"
    rejectedParse "tuple cannot omit its first element" kind "def result : Nat := (,1)\n"
    rejectedParse "tuple cannot omit an interior element" kind "def result : Nat := (1,,2)\n"
    rejectedParse "array separator required" kind "def result : Nat := #[1;2]\n"
    rejectedParse "array missing element" kind "def result : Nat := #[1,,2]\n"
    rejectedParse "array prefix is one lexical form" kind "def result : Nat := # [1,2]\n"
    rejectedType "tuple shape mismatch" kind "def result : Nat := (1,2)\n"
    rejectedType "array is not list" kind "def result : List Nat := #[1,2]\n"
    rejectedType "ambiguous unused empty array" kind
      (match kind with
       | .lean => "def result : Nat := let values := #[]; 1\n"
       | .proofScript => "def result : Nat := let values := #[]\n 1\n")
  rejectedType "Lean mixed array" .lean "def result : Array Nat := #[1, true]\n"
  rejectedType "PS mixed array" .proofScript "def result : Array(Nat) := #[1, true]\n"
  rejectedType "PS arguments cannot silently form a tuple" .proofScript
    "def first(pair : Prod(Int, Bool)) : Int := Prod.fst(pair)\ndef result : Int := first(9, false)\n"
  roundTrip "PS literal source translates via existing checked constructors"
    .proofScript .lean "def result : Array(Prod(Int, Bool)) := #[(1, true), (2, false)]\n"
  roundTrip "Lean literal source translates via existing checked constructors"
    .lean .proofScript "def result : Array (Prod Int Bool) := #[(1, true), (2, false)]\n"
  IO.println "PSC1_DATA_TESTS: PASS"
