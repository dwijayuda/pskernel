import Ps.Host.LeanChecked
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Validate
import PracticalExecution

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

private def checkExecuted (label : String) (kind : PsCompilerSourceKind)
    (source : String) (type expected : PsExpr) : IO Unit := do
  let prepared ← prepare label kind source
  psPracticalCheckExecuted label prepared type expected

private def patternConstOccurrences (target : PsName) : PsExpr -> Nat
  | .constE name _ => if psNameEq target name then 1 else 0
  | .app fn arg => patternConstOccurrences target fn + patternConstOccurrences target arg
  | .lam _ type body _ | .forallE _ type body _ =>
      patternConstOccurrences target type + patternConstOccurrences target body
  | .letE _ type value body =>
      patternConstOccurrences target type + patternConstOccurrences target value +
        patternConstOccurrences target body
  | .proj _ _ value => patternConstOccurrences target value
  | _ => 0

private def hasPatternRhsLet (target : PsName) : PsExpr -> Bool
  | .letE _ _ value body =>
      (patternConstOccurrences target value == 1 && patternConstOccurrences target body == 0) ||
        hasPatternRhsLet target value || hasPatternRhsLet target body
  | .app fn arg => hasPatternRhsLet target fn || hasPatternRhsLet target arg
  | .lam _ _ body _ | .forallE _ _ body _ => hasPatternRhsLet target body
  | .proj _ _ value => hasPatternRhsLet target value
  | _ => false

private def checkPatternRhsOnce (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO Unit := do
  let prepared ← prepare label kind source
  let declaration := prepared.declarations.find? (fun declaration =>
    match declaration with
    | .definitionDecl name _ _ _ => psNameEq name (psRootName "result")
    | _ => false)
  let body ← match declaration with
    | some (.definitionDecl _ _ _ value) => pure value
    | _ => fail label "missing result definition"
  let target := psRootName "pairSource"
  unless patternConstOccurrences target body == 1 do
    fail label "pattern RHS was duplicated or discarded"
  unless hasPatternRhsLet target body do
    fail label "pattern RHS has no strict Core let"
  IO.println ("PSC1_DATA_PASS: " ++ label)

private def testBindingPatterns : IO Unit := do
  let natType : PsExpr := .constE psNatName []
  let intType : PsExpr := .constE psIntName []
  let intNine := PsExpr.app (.constE psIntOfNatName []) (.lit (.natural 9))
  let leanNested :=
    "def result : Int := let (left, (right, flag)) : Int × (Nat × Bool) := (7, (3, true)); if flag then left + 2 else left\n"
  let psNested :=
    "def result : Int := let (left, (right, flag)) : Int × (Nat × Bool) := (7, (3, true))\n if (flag) { left + 2 } else { left }\n"
  checkExecuted "Lean nested annotated tuple binding" .lean leanNested intType intNine
  checkExecuted "PS nested annotated tuple binding" .proofScript psNested intType intNine
  roundTrip "nested pattern Lean to PS" .lean .proofScript leanNested
  roundTrip "nested pattern PS to Lean" .proofScript .lean psNested
  roundTrip "grouped name pattern Lean to PS" .lean .proofScript
    "def result : Nat := let (x) := 7; x\n"
  roundTrip "grouped name pattern PS to Lean" .proofScript .lean
    "def result : Nat := let (x) := 7\n x\n"
  roundTrip "grouped wildcard pattern Lean to PS" .lean .proofScript
    "def result : Nat := let (_) := 7; 9\n"
  roundTrip "grouped wildcard pattern PS to Lean" .proofScript .lean
    "def result : Nat := let (_) := 7\n 9\n"
  let leanCapture :=
    "def result : Id Nat := do\n" ++
    "  let x : Nat := 5\n" ++
    "  let old : Nat -> Nat := fun (n : Nat) => x + n\n" ++
    "  let (x, y) := (x + 1, 3)\n" ++
    "  return old 0 + x + y\n"
  let psCapture :=
    "def result : Id Nat := do {\n" ++
    "  let x : Nat := 5\n" ++
    "  let old : Nat -> Nat := fun (n : Nat) => x + n\n" ++
    "  let (x, y) := (x + 1, 3)\n" ++
    "  return old(0) + x + y\n}\n"
  checkExecuted "Lean pattern shadowing preserves RHS scope and old closure" .lean
    leanCapture natType (.lit (.natural 14))
  checkExecuted "PS pattern shadowing preserves RHS scope and old closure" .proofScript
    psCapture natType (.lit (.natural 14))
  roundTrip "procedural pattern Lean to PS" .lean .proofScript leanCapture
  roundTrip "procedural pattern PS to Lean" .proofScript .lean psCapture
  checkExecuted "Lean pattern finite-loop mutation and early return" .lean
    ("def result : Id Nat := do\n" ++
      "  let mut total : Nat := 0\n" ++
      "  for n in #[1,2,3] do\n" ++
      "    let (left, right) := (n, n + 1)\n" ++
      "    total := total + left\n" ++
      "    if right == 3 then\n" ++
      "      return total\n" ++
      "  return total\n") natType (.lit (.natural 3))
  checkExecuted "PS pattern finite-loop mutation and early return" .proofScript
    ("def result : Id Nat := do {\n" ++
      "  let mut total : Nat := 0\n" ++
      "  for n in #[1,2,3] {\n" ++
      "    let (left, right) := (n, n + 1)\n" ++
      "    total := total + left\n" ++
      "    if (right == 3) { return total }\n" ++
      "  }\n  return total\n}\n") natType (.lit (.natural 3))
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    let separator := match kind with | .lean => "; " | .proofScript => "\n "
    let expression := fun (binding body : String) =>
      "def result : Nat := " ++ binding ++ separator ++ body ++ "\n"
    checkExecuted "wildcard and nested Unit pattern" kind
      (expression "let (_, ((), right)) : Nat × (Unit × Nat) := (3, ((), 8))" "right")
      natType (.lit (.natural 8))
    checkExecuted "Unit binding pattern" kind (expression "let () := ()" "9")
      natType (.lit (.natural 9))
    checkExecuted "three tuple binders associate right" kind
      (expression "let (x, y, z) : Nat × Nat × Nat := (1,2,3)" "x + y + z")
      natType (.lit (.natural 6))
    rejectedType "tuple binding requires a product" kind
      (expression "let (x, y) := 1" "0")
    rejectedType "unused tuple pattern still checks product shape" kind
      (expression "let (_, _) := 1" "0")
    rejectedType "nested tuple binding checks shape" kind
      (expression "let (x, (y, z)) := (1,2)" "x")
    rejectedType "tuple pattern arity checks right-associated shape" kind
      (expression "let (x, y, z) := (1,2)" "x")
    rejectedType "duplicate nested tuple binder refuses" kind
      (expression "let (x, (y, x)) := (1,(2,3))" "x")
    rejectedType "tuple binding annotation checks fields" kind
      (expression "let (x, y) : Nat × Bool := (1,2)" "x")
    rejectedType "Unit pattern checks its field type" kind
      (expression "let ((), x) := (1,2)" "x")
    rejectedType "pattern names are unavailable in their RHS" kind
      (expression "let (x, y) := (x,1)" "x")
    rejectedType "tuple pattern binder cannot escape" kind
      ("def first : Nat := let (x, y) := (1,2)" ++ separator ++
        "x\ndef result : Nat := y\n")
    rejectedParse "singleton comma pattern refuses" kind
      (expression "let (x,) := (1,2)" "x")
    rejectedParse "missing first pattern refuses" kind
      (expression "let (,x) := (1,2)" "x")
    rejectedParse "missing interior pattern refuses" kind
      (expression "let (x,,y) := (1,2)" "x")
    let mutableConflict := match kind with
      | .lean => "def result : Id Nat := do { let mut x := 0; let (x, y) := (1,2); return y }\n"
      | .proofScript => "def result : Id Nat := do {\n let mut x := 0\n let (x, y) := (1,2)\n return y\n}\n"
    rejectedType "pattern cannot shadow an existing mutable local" kind mutableConflict
    let immutableAssignment := match kind with
      | .lean => "def result : Id Nat := do { let (x, y) := (1,2); x := 4; return x }\n"
      | .proofScript => "def result : Id Nat := do {\n let (x, y) := (1,2)\n x := 4\n return x\n}\n"
    rejectedType "pattern bindings remain immutable" kind immutableAssignment
    let mutablePattern := match kind with
      | .lean => "def result : Id Nat := do { let mut (x, y) := (1,2); return x }\n"
      | .proofScript => "def result : Id Nat := do {\n let mut (x, y) := (1,2)\n return x\n}\n"
    rejectedParse "mutable tuple pattern remains outside selected scope" kind mutablePattern
    let monadicPattern := match kind with
      | .lean => "def result : Id Nat := do { let (x, y) <- pure (1,2); return x }\n"
      | .proofScript => "def result : Id Nat := do {\n let (x, y) <- pure((1,2))\n return x\n}\n"
    rejectedParse "monadic tuple pattern remains outside selected scope" kind monadicPattern
    let helper := match kind with
      | .lean => "def pairSource (n : Nat) : Nat × Nat := (n, n + 1)\n"
      | .proofScript => "def pairSource(n : Nat) : Nat × Nat := (n, n + 1)\n"
    let call := match kind with | .lean => "pairSource 4" | .proofScript => "pairSource(4)"
    checkPatternRhsOnce "used tuple RHS occurs once in a strict Core let" kind
      (helper ++ expression ("let (left, right) := " ++ call) "left + right")
    checkPatternRhsOnce "unused tuple RHS remains once in a strict Core let" kind
      (helper ++ expression ("let (_, _) := " ++ call) "7")

private def testConstructorNotationHygiene : IO Unit := do
  let natType : PsExpr := .constE psNatName []
  let leanPrelude :=
    "def makePair (left : Nat) (right : Nat) : Nat × Nat := (left, right)\n" ++
    "def makeArray (value : Nat) : Array Nat := #[value]\n" ++
    "namespace Capture\nnamespace Prod\n" ++
    "def mk (left : Nat) (right : Nat) : Nat × Nat := makePair right left\n" ++
    "end Prod\nnamespace Array\n" ++
    "def emptyWithCapacity (capacity : Nat) : Array Nat := makeArray 88\n" ++
    "def push (values : Array Nat) (value : Nat) : Array Nat := makeArray 99\n" ++
    "end Array\ndef Prod : Type := Nat\n"
  let psPrelude :=
    "def makePair(left : Nat, right : Nat) : Nat × Nat := (left, right)\n" ++
    "def makeArray(value : Nat) : Array(Nat) := #[value]\n" ++
    "namespace Capture\nnamespace Prod\n" ++
    "def mk(left : Nat, right : Nat) : Nat × Nat := makePair(right, left)\n" ++
    "end Prod\nnamespace Array\n" ++
    "def emptyWithCapacity(capacity : Nat) : Array(Nat) := makeArray(88)\n" ++
    "def push(values : Array(Nat), value : Nat) : Array(Nat) := makeArray(99)\n" ++
    "end Array\ndef Prod : Type := Nat\n"
  let leanTuple := leanPrelude ++
    "def tupleBoundary : Nat := let (left, right) : Nat × Nat := (1,2); " ++
    "let named : Nat × Nat := Prod.mk 1 2; left * 10 + Prod.fst named\n" ++
    "end Capture\ndef result : Nat := Capture.tupleBoundary\n"
  let psTuple := psPrelude ++
    "def tupleBoundary : Nat := let (left, right) : Nat × Nat := (1,2)\n" ++
    " let named : Nat × Nat := Prod.mk(1,2)\n left * 10 + Prod.fst(named)\n" ++
    "end Capture\ndef result : Nat := Capture.tupleBoundary\n"
  checkExecuted "Lean tuple notation is hygienic and explicit names remain relative" .lean
    leanTuple natType (.lit (.natural 12))
  checkExecuted "PS tuple notation is hygienic and explicit names remain relative" .proofScript
    psTuple natType (.lit (.natural 12))
  roundTrip "tuple constructor hygiene Lean to PS" .lean .proofScript leanTuple
  roundTrip "tuple constructor hygiene PS to Lean" .proofScript .lean psTuple
  let leanArray := leanPrelude ++
    "def arrayBoundary : Nat := let empty : Array Nat := #[]; " ++
    "let values : Array Nat := #[11,22]; " ++
    "let namedEmpty : Array Nat := Array.emptyWithCapacity 0; " ++
    "let namedPush : Array Nat := Array.push values 5; " ++
    "Array.size empty * 1000 + Array.size values * 100 + " ++
    "Array.size namedEmpty * 10 + Array.size namedPush\n" ++
    "end Capture\ndef result : Nat := Capture.arrayBoundary\n"
  let psArray := psPrelude ++
    "def arrayBoundary : Nat := let empty : Array(Nat) := #[]\n" ++
    " let values : Array(Nat) := #[11,22]\n" ++
    " let namedEmpty : Array(Nat) := Array.emptyWithCapacity(0)\n" ++
    " let namedPush : Array(Nat) := Array.push(values,5)\n" ++
    " Array.size(empty) * 1000 + Array.size(values) * 100 + " ++
    "Array.size(namedEmpty) * 10 + Array.size(namedPush)\n" ++
    "end Capture\ndef result : Nat := Capture.arrayBoundary\n"
  checkExecuted "Lean array notation is hygienic and explicit names remain relative" .lean
    leanArray natType (.lit (.natural 211))
  checkExecuted "PS array notation is hygienic and explicit names remain relative" .proofScript
    psArray natType (.lit (.natural 211))
  roundTrip "array constructor hygiene Lean to PS" .lean .proofScript leanArray
  roundTrip "array constructor hygiene PS to Lean" .proofScript .lean psArray

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
  let natType : PsExpr := .constE psNatName []
  let optionNat := psSelfHostOptionOf natType
  let noneNat := psSelfHostOptionNoneOf natType
  let someEleven := psSelfHostOptionSomeOf natType (.lit (.natural 11))
  let someTwentyTwo := psSelfHostOptionSomeOf natType (.lit (.natural 22))
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    checkExecuted "optional first element" kind
      "def result : Option Nat := #[11,22][0]?\n" optionNat someEleven
    checkExecuted "optional last element" kind
      "def result : Option Nat := #[11,22][1]?\n" optionNat someTwentyTwo
    checkExecuted "optional at length" kind
      "def result : Option Nat := #[11,22][2]?\n" optionNat noneNat
    checkExecuted "optional far out of range" kind
      "def result : Option Nat := #[11,22][999999999999999999999999999999]?\n" optionNat noneNat
    checkExecuted "empty array inferred from optional result" kind
      "def result : Option Nat := #[][0]?\n" optionNat noneNat
    checkExecuted "parenthesized array keeps suffix adjacency" kind
      "def result : Option Nat := (#[11,22])[1]?\n" optionNat someTwentyTwo
    rejectedParse "plain indexing is not optional indexing" kind
      "def result : Nat := #[1][0]\n"
    rejectedParse "panic indexing remains unselected" kind
      "def result : Nat := #[1][0]!\n"
    rejectedParse "optional suffix must be adjacent" kind
      "def result : Option Nat := #[1][0] ?\n"
    rejectedType "optional index has fixed Nat type" kind
      "def result : Option Nat := #[1][true]?\n"
    rejectedType "optional negative Int index rejected" kind
      "def result : Option Nat := #[1][-1]?\n"
    rejectedType "optional result cannot silently unwrap" kind
      "def result : Nat := #[1][0]?\n"
  checkExecuted "Lean suffix binds before its enclosing application" .lean
    "def pick (value : Option Nat) : Nat := match value with | Option.none => 0 | Option.some item => item\ndef result : Nat := let xs := #[11,22]; pick xs[1]?\n"
    natType (.lit (.natural 22))
  checkExecuted "PS optional argument" .proofScript
    "def pick(value : Option(Nat)) : Nat := match value with { | Option.none => 0 | Option.some item => item }\ndef result : Nat := let xs := #[11,22]\n pick(xs[1]?)\n"
    natType (.lit (.natural 22))
  rejectedType "Lean nonarray receiver" .lean
    "def bad(xs : List Nat) : Option Nat := xs[0]?\n"
  rejectedType "PS nonarray receiver" .proofScript
    "def bad(xs : List(Nat)) : Option(Nat) := xs[0]?\n"
  roundTrip "optional index Lean to PS" .lean .proofScript
    "def result : Option Nat := (#[11,22])[1]?\n"
  roundTrip "optional index PS to Lean" .proofScript .lean
    "def result : Option(Nat) := (#[11,22])[1]?\n"
  testBindingPatterns
  testConstructorNotationHygiene
  IO.println "PSC1_DATA_TESTS: PASS"
