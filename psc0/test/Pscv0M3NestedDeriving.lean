import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Pinned native deriving is an independent runtime oracle. The portable
-- declarations and every generated instance below are built separately.
universe u
mutual
  inductive M3NestedDisplay (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | list (children : List (M3NestedBranch A a))
    | option (child : Option (M3NestedBranch A a))
    | array (children : Array (M3NestedBranch A a))
    | product (children : Prod (M3NestedDisplay A a)
        (Prod (M3NestedBranch A a) (M3NestedDisplay A a)))
    | mixed (children : Prod (M3NestedDisplay A a) (Prod Nat Nat))
  inductive M3NestedBranch (A : Type u) (a : A) : Type u where
    | branch (children : List (M3NestedDisplay A a))
    | direct (next : M3NestedDisplay A a)
end

-- This is an actual user-supplied marker, available before either native
-- Repr instance is generated. List Branch uses bracketFill; List Display
-- remains ordinary bracket, while Array always uses bracketFill.
instance {A : Type u} {a : A} : ReprAtom (M3NestedBranch A a) := ⟨⟩
deriving instance Repr, BEq for M3NestedDisplay, M3NestedBranch

inductive M3NestedIndexedDisplay (A : Type u) (a : A) : Nat → Type u where
  | leaf (value : A) : M3NestedIndexedDisplay A a 0
  | row (n : Nat) (children : List (M3NestedIndexedDisplay A a 0)) :
      M3NestedIndexedDisplay A a (Nat.succ n)
  deriving Repr

inductive M3NestedAtom where
  | atom (flag : Bool)

instance : BEq M3NestedAtom where
  beq _ _ := false

namespace M3NestedDerivingOracle

-- The actual native Array policy checks equal lengths, then compares the
-- final element first. These laws use the pinned container implementation,
-- independently of either generated nested BEq instance.
example (first last : Bool) :
    Array.isEqv (Array.mk [first, last]) (Array.mk [false, false])
      (fun left _ => left) = (last && first) := by
  cases first <;> cases last <;> rfl

example (first last : Bool) :
    @List.beq Bool ⟨fun left _ => left⟩ [first, last] [false, false] =
      (first && last) := by
  cases first <;> cases last <;> rfl

def branch (n m : Nat) : M3NestedBranch Nat 0 :=
  .branch [.leaf n, .option (some (.direct (.leaf m)))]

def children (n m : Nat) : List (M3NestedBranch Nat 0) :=
  [.direct (.leaf n), branch m (n + 1), .branch []]

def display (n m : Nat) : M3NestedDisplay Nat 0 :=
  .product (.array (Array.mk (children n m)),
    (.direct (.list (children n m)), .option none))

def mixed (n m : Nat) : M3NestedDisplay Nat 0 :=
  .mixed (.leaf n, (m, n + 1))

def indexed (n : Nat) : M3NestedIndexedDisplay Nat 0 3 :=
  .row 2 [.leaf n, .leaf (n + 1)]

def payload (flag : Bool) : Nat := if flag then 43 else 17
def precedence (flag : Bool) : Nat := if flag then 1024 else 0
def width (flag : Bool) : Nat := if flag then 120 else 23

def displayText (flag : Bool) : String :=
  let n := payload flag
  (reprPrec (display n (n + 1)) (precedence flag)).pretty (width flag)

def branchText (flag : Bool) : String :=
  let n := payload flag
  (reprPrec (branch n (n + 1)) (precedence flag)).pretty (width flag)

def tupleText (flag : Bool) : String :=
  let n := payload flag
  (reprPrec (mixed n (n + 2)) (precedence flag)).pretty (width flag)

def indexedText (flag : Bool) : String :=
  (reprPrec (indexed (payload flag)) (precedence flag)).pretty (width flag)

def bits (a b c d e f g : Bool) : UInt64 :=
  UInt64.ofNat ((if a then 1 else 0) + (if b then 2 else 0) +
    (if c then 4 else 0) + (if d then 8 else 0) + (if e then 16 else 0) +
    (if f then 32 else 0) + (if g then 64 else 0))

def beqOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let m := if flag then n + 1 else n + 2
  let x := display n (n + 1)
  let y := display n m
  let left := branch n (n + 1)
  let right := branch n m
  bits (x == x) (x == y) (y == x) (x == .leaf n) (.leaf n == x)
    (left == right) (left == .direct (.leaf n))

def arrayValue (n m : Nat) : M3NestedDisplay Nat 0 :=
  .array (Array.mk [.direct (.leaf n), .direct (.leaf m)])

def arrayOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  let m := if flag then n + 1 else n + 2
  let x := arrayValue n (n + 1)
  let short : M3NestedDisplay Nat 0 := .array (Array.mk [.direct (.leaf n)])
  let empty : M3NestedDisplay Nat 0 := .array (Array.mk [])
  bits (x == x) (x == arrayValue n m) (x == arrayValue m (n + 1))
    (x == short) (short == x) (empty == empty) (empty == short)

def atomOutput (flag : Bool) : UInt64 :=
  let leaf : M3NestedDisplay M3NestedAtom (.atom false) := .leaf (.atom flag)
  let child : M3NestedBranch M3NestedAtom (.atom false) := .direct leaf
  let list : M3NestedDisplay M3NestedAtom (.atom false) := .list [child]
  let option : M3NestedDisplay M3NestedAtom (.atom false) := .option (some child)
  let array : M3NestedDisplay M3NestedAtom (.atom false) := .array (Array.mk [child])
  let product : M3NestedDisplay M3NestedAtom (.atom false) := .product (leaf, (child, leaf))
  let mixed : M3NestedDisplay M3NestedAtom (.atom false) := .mixed (leaf, (1, 2))
  let empty : M3NestedDisplay M3NestedAtom (.atom false) := .list []
  bits (!(list == list)) (!(option == option)) (!(array == array))
    (!(product == product)) (!(mixed == mixed)) (empty == empty) (!(child == child))

end M3NestedDerivingOracle

namespace M3NestedDeriving

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

-- Failure context does not change the admitted source or any expected value.
-- Native fixture execution has several checked Core stages before publication.
private def inPhase (phase : String) (action : IO α) : IO α := do
  try action
  catch error => throw (IO.userError (phase ++ ": " ++ error.toString))

private def literal (value : String) : String := (Lean.toJson value).compress

private def groupSource : String :=
  "universe u\n" ++
  "inductive M3NestedDisplay(A: Type u, a: A): Type u where {\n" ++
  " | leaf(value: A)\n | list(children: List(M3NestedBranch(A, a)))\n" ++
  " | option(child: Option(M3NestedBranch(A, a)))\n" ++
  " | array(children: Array(M3NestedBranch(A, a)))\n" ++
  " | product(children: Prod(M3NestedDisplay(A, a), Prod(M3NestedBranch(A, a), M3NestedDisplay(A, a))))\n" ++
  " | mixed(children: Prod(M3NestedDisplay(A, a), Prod(Nat, Nat)))\n}\n" ++
  "inductive M3NestedBranch(B: Type u, b: B): Type u where { | branch(children: List(M3NestedDisplay(B, b))) | direct(next: M3NestedDisplay(B, b)) }\n"

private def indexedSource : String :=
  "universe u\n" ++
  "inductive M3NestedIndexedDisplay(A: Type u, a: A): Nat -> Type u where { | leaf(value: A): M3NestedIndexedDisplay(A, a, 0) | row(n: Nat, children: List(M3NestedIndexedDisplay(A, a, 0))): M3NestedIndexedDisplay(A, a, Nat.succ(n)) }\n"

private def logicalSource : String :=
  "inductive M3NestedSourceDeriving where { | leaf(value: Nat) | node(children: List(M3NestedSourceDeriving)) } deriving Repr, BEq\n" ++
  "theorem m3NestedSourceDerivingEquation: (M3NestedSourceDeriving.node(List.cons(M3NestedSourceDeriving.leaf(9), List.nil)) == M3NestedSourceDeriving.node(List.cons(M3NestedSourceDeriving.leaf(9), List.nil))) = true := by { rfl }\n"

private def runtimeSource : String :=
  "function m3NestedBranchValue(n: Nat, m: Nat): M3NestedBranch(Nat, 0) := M3NestedBranch.branch(List.cons(M3NestedDisplay.leaf(n), List.cons(M3NestedDisplay.option(Option.some(M3NestedBranch.direct(M3NestedDisplay.leaf(m)))), List.nil)))\n" ++
  "function m3NestedDisplayChildren(n: Nat, m: Nat): List(M3NestedBranch(Nat, 0)) := List.cons(M3NestedBranch.direct(M3NestedDisplay.leaf(n)), List.cons(m3NestedBranchValue(m, n + 1), List.cons(M3NestedBranch.branch(List.nil), List.nil)))\n" ++
  "function m3NestedDisplayValue(n: Nat, m: Nat): M3NestedDisplay(Nat, 0) := M3NestedDisplay.product(Prod.mk(M3NestedDisplay.array(Array.mk(m3NestedDisplayChildren(n, m))), Prod.mk(M3NestedBranch.direct(M3NestedDisplay.list(m3NestedDisplayChildren(n, m))), M3NestedDisplay.option(Option.none))))\n" ++
  "function m3NestedMixedValue(n: Nat, m: Nat): M3NestedDisplay(Nat, 0) := M3NestedDisplay.mixed(Prod.mk(M3NestedDisplay.leaf(n), Prod.mk(m, n + 1)))\n" ++
  "function m3NestedIndexedDisplayValue(n: Nat): M3NestedIndexedDisplay(Nat, 0, 3) := M3NestedIndexedDisplay.row(2, List.cons(M3NestedIndexedDisplay.leaf(n), List.cons(M3NestedIndexedDisplay.leaf(n + 1), List.nil)))\n" ++
  "function m3NestedArrayValue(n: Nat, m: Nat): M3NestedDisplay(Nat, 0) := M3NestedDisplay.array(Array.mk(List.cons(M3NestedBranch.direct(M3NestedDisplay.leaf(n)), List.cons(M3NestedBranch.direct(M3NestedDisplay.leaf(m)), List.nil))))\n" ++
  "function m3NestedDerivingBits(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool, g: Bool): UInt64 := UInt64.ofNat((if (a) { 1 } else { 0 }) + (if (b) { 2 } else { 0 }) + (if (c) { 4 } else { 0 }) + (if (d) { 8 } else { 0 }) + (if (e) { 16 } else { 0 }) + (if (f) { 32 } else { 0 }) + (if (g) { 64 } else { 0 }))\n" ++
  "function m3nestedrepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let width: Nat := if (flag) { 120 } else { 23 }\n" ++
  " let displayExpected: String := if (flag) { " ++ literal (M3NestedDerivingOracle.displayText true) ++
    " } else { " ++ literal (M3NestedDerivingOracle.displayText false) ++ " }\n" ++
  " let branchExpected: String := if (flag) { " ++ literal (M3NestedDerivingOracle.branchText true) ++
    " } else { " ++ literal (M3NestedDerivingOracle.branchText false) ++ " }\n" ++
  " let displayActual: String := Std.Format.pretty(Repr.reprPrec(m3NestedDisplayValue(n, n + 1), prec), width, 0, 0)\n" ++
  " let branchActual: String := Std.Format.pretty(Repr.reprPrec(m3NestedBranchValue(n, n + 1), prec), width, 0, 0)\n" ++
  " UInt64.ofNat((if (displayActual == displayExpected) { 1 } else { 0 }) + (if (branchActual == branchExpected) { 2 } else { 0 }))\n}\n" ++
  "function m3nestedtuplerepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let width: Nat := if (flag) { 120 } else { 23 }\n" ++
  " let expected: String := if (flag) { " ++ literal (M3NestedDerivingOracle.tupleText true) ++
    " } else { " ++ literal (M3NestedDerivingOracle.tupleText false) ++ " }\n" ++
  " let actual: String := Std.Format.pretty(Repr.reprPrec(m3NestedMixedValue(n, n + 2), prec), width, 0, 0)\n" ++
  " if (actual == expected) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n}\n" ++
  "function m3nestedindexedrepr(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let prec: Nat := if (flag) { 1024 } else { 0 }\n" ++
  " let width: Nat := if (flag) { 120 } else { 23 }\n" ++
  " let expected: String := if (flag) { " ++ literal (M3NestedDerivingOracle.indexedText true) ++
    " } else { " ++ literal (M3NestedDerivingOracle.indexedText false) ++ " }\n" ++
  " let actual: String := Std.Format.pretty(Repr.reprPrec(m3NestedIndexedDisplayValue(n), prec), width, 0, 0)\n" ++
  " if (actual == expected) { UInt64.ofNat(1) } else { UInt64.ofNat(0) }\n}\n" ++
  "function m3nestedbeq(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let m: Nat := if (flag) { n + 1 } else { n + 2 }\n" ++
  " let x: M3NestedDisplay(Nat, 0) := m3NestedDisplayValue(n, n + 1)\n" ++
  " let y: M3NestedDisplay(Nat, 0) := m3NestedDisplayValue(n, m)\n" ++
  " let left: M3NestedBranch(Nat, 0) := m3NestedBranchValue(n, n + 1)\n" ++
  " let right: M3NestedBranch(Nat, 0) := m3NestedBranchValue(n, m)\n" ++
  " m3NestedDerivingBits(x == x, x == y, y == x, x == M3NestedDisplay.leaf(n), M3NestedDisplay.leaf(n) == x, left == right, left == M3NestedBranch.direct(M3NestedDisplay.leaf(n)))\n}\n" ++
  "function m3nestedarraybeq(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let m: Nat := if (flag) { n + 1 } else { n + 2 }\n" ++
  " let x: M3NestedDisplay(Nat, 0) := m3NestedArrayValue(n, n + 1)\n" ++
  " let short: M3NestedDisplay(Nat, 0) := M3NestedDisplay.array(Array.mk(List.cons(M3NestedBranch.direct(M3NestedDisplay.leaf(n)), List.nil)))\n" ++
  " let empty: M3NestedDisplay(Nat, 0) := M3NestedDisplay.array(Array.mk(List.nil))\n" ++
  " m3NestedDerivingBits(x == x, x == m3NestedArrayValue(n, m), x == m3NestedArrayValue(m, n + 1), x == short, short == x, empty == empty, empty == short)\n}\n" ++
  "inductive M3NestedAtom where { | atom(flag: Bool) }\n" ++
  "instance m3NestedAtomBEq: BEq M3NestedAtom where { beq(left: M3NestedAtom, right: M3NestedAtom): Bool := false }\n" ++
  "function m3NestedAtomProbe(flag: Bool): Bool := {\n" ++
  " let leaf: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.leaf(M3NestedAtom.atom(flag))\n" ++
  " let child: M3NestedBranch(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedBranch.direct(leaf)\n" ++
  " let array: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.array(Array.mk(List.cons(child, List.nil)))\n" ++
  " array == array\n}\n" ++
  "function m3nestedatombeq(flag: Bool): UInt64 := {\n" ++
  " let leaf: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.leaf(M3NestedAtom.atom(flag))\n" ++
  " let child: M3NestedBranch(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedBranch.direct(leaf)\n" ++
  " let list: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.list(List.cons(child, List.nil))\n" ++
  " let option: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.option(Option.some(child))\n" ++
  " let array: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.array(Array.mk(List.cons(child, List.nil)))\n" ++
  " let product: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.product(Prod.mk(leaf, Prod.mk(child, leaf)))\n" ++
  " let mixed: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.mixed(Prod.mk(leaf, Prod.mk(1, 2)))\n" ++
  " let empty: M3NestedDisplay(M3NestedAtom, M3NestedAtom.atom(false)) := M3NestedDisplay.list(List.nil)\n" ++
  " m3NestedDerivingBits(if (list == list) { false } else { true }, if (option == option) { false } else { true }, if (array == array) { false } else { true }, if (product == product) { false } else { true }, if (mixed == mixed) { false } else { true }, empty == empty, if (child == child) { false } else { true })\n}\n"

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
    | _ => throw "nested deriving fixture expected native inductive members"
  let first :: _ := sources | throw "nested deriving fixture has no group source"
  let result ← (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks [psRootName "u"]).mapError
    psCompilerPscv0ElabError
  let origin := psElabBatchOriginAt 0 first (psElabStableMemberOrigins result.declarations 0) none
  return (result, origin)

private def add (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment :=
  fromExcept ((psAddDeclarationList environment declarations).mapError psCompilerPscv0ElabError)

private def register (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment := do
  let environment ← add environment declarations
  fromExcept ((declarations.foldlM (fun current declaration =>
    (psElabRegisterInstance current (psDeclarationName declaration) 1000).mapError
      (.atDeclaration (psDeclarationName declaration))) environment).mapError
      psCompilerPscv0ElabError)

private def call (name : PsName) (levels : List PsLevel) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE name levels) arguments

private def marker : PsDeclaration :=
  let level := PsLevel.param (psRootName "u")
  let parameter := PsExpr.fvar 0
  let seed := PsExpr.fvar 1
  let family := call (psRootName "M3NestedBranch") [level] [parameter, seed]
  let type := call (psRootName "ReprAtom") [level] [family]
  let value := call (psNameAppendStr (psRootName "ReprAtom") "mk") [level] [family]
  .definitionDecl (psNameAppendStr (psRootName "M3NestedBranch") "instReprAtom") [psRootName "u"]
    (psLogicPi 0 "A" (.sortE (.succ level))
      (psLogicPi 1 "a" parameter type .implicit) .implicit)
    (psLogicLam 0 "A" (.sortE (.succ level))
      (psLogicLam 1 "a" parameter value .implicit) .implicit)

-- Replay only a failing group through its same public member handler to retain
-- the precise generated declaration identity. Successful derivation is unchanged.
private def deriveFailure (environment : PsEnvironment) (origin : PsElabBatchOrigin)
    (handler : PsSyntaxName) (original : PsElabError) : String := Id.run do
  let members := origin.members.filter fun entry =>
    match entry.role with
    | .inductiveType | .structureType => true
    | _ => false
  for member in members do
    let selected := origin.members.filter fun entry =>
      match entry.role with
      | .inductiveType | .structureType => psNameEq entry.name member.name
      | _ => true
    match psElabDeriveHandler environment { origin with members := selected } handler with
    | .ok _ => pure ()
    | .error _ =>
      return "derive " ++ psNameToString member.name ++ "." ++
        String.intercalate "." handler.segments ++ ": " ++ psCompilerPscv0ElabError original
  return "derive group " ++ String.intercalate "." handler.segments ++ ": " ++
    psCompilerPscv0ElabError original

private def derive (environment : PsEnvironment) (origin : PsElabBatchOrigin)
    (handlers : List String) : IO (List PsDeclaration) := do
  let declarations ← handlers.mapM fun text => do
    let handler : PsSyntaxName := { segments := [text], span := origin.span }
    fromExcept ((psElabDeriveGroupHandler environment origin handler).mapError
      (deriveFailure environment origin handler))
  return declarations.flatten

private def commandLabel (command : PsSyntaxCommand) (index : Nat) : String :=
  let source := match command with
    | .declaration source | .privateDeclaration source
    | .registeredDeclaration source _ | .privateRegisteredDeclaration source _
    | .derivingDeclaration source _ _ => some source
    | _ => none
  match source with
  | none => "source command " ++ toString index
  | some source =>
    let (name, span) := psElabOriginSource source
    "source " ++ String.intercalate "." name.segments ++ " bytes " ++
      toString span.start.byteOffset ++ "-" ++ toString span.stop.byteOffset

-- The normal public program entry remains authoritative. Only a failure
-- replays its same command fold to attach the actual source name and span.
private def sourceFailure (environment : PsEnvironment) (program : PsSyntaxProgram)
    (original : PsElabError) : String := Id.run do
  let namespaces := environment.declarations.foldl (fun acc declaration =>
    ((psScopeNamePrefixes (psDeclarationName declaration)).drop 1).foldl psScopeRemember acc) []
  let mut state : PsCommandState := { environment, namespaces }
  for (command, index) in program.commands.zipIdx do
    match psElabCommand state command with
    | .ok next => state := next
    | .error _ => return commandLabel command index ++ ": " ++ psCompilerPscv0ElabError original
  return psCompilerPscv0ElabError original

private def sourceResult (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError (sourceFailure environment parsed))

private def checked (environment : PsEnvironment) (prelude : Lean.Kernel.Environment)
    (declarations : List PsDeclaration) : IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonicalIn environment declarations).mapError
    (fun _ => "canonical nested deriving admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def signatureWitnesses (declarations : List PsDeclaration) : List PsDeclaration :=
  declarations.filterMap fun declaration =>
    match declaration with
    | .recursorDecl info => some (.definitionDecl
      (psNameAppendStr info.name "_signature") info.levelParams info.type
      (.constE info.name (info.levelParams.map PsLevel.param)))
    | _ => none

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (label expected : String) (result : Except PsElabError α) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected nested deriving acceptance: " ++ label))
  | .error error =>
    ensure (refusal error == expected) (label ++ " refused at the wrong rule: " ++ refusal error)

private def checkPlans (environment : PsEnvironment)
    (origin indexedOrigin : PsElabBatchOrigin) : IO Unit := do
  let plan ← inPhase "psElabDerivePrepare M3NestedDisplay" <| fromExcept ((psElabDerivePrepare environment origin
    { groups := true, indices := true, nested := true }).mapError psCompilerPscv0ElabError)
  ensure (plan.parametersRev.length == 2 && plan.elimination.slots.length == 9 &&
    psInductiveEliminationNumMinors plan.elimination == 18)
    "nested deriving did not retain the complete dependent-parameter nine-slot group"
  let marked := psElabDeriveRequirements plan (psRootName "Repr")
  ensure (marked.requirementsRev.length == 1)
    "Repr generated a dictionary for the value parameter or a recursive family"
  let atomic ← fromExcept (plan.elimination.slots.mapM fun slot =>
    (psElabDeriveReprAtomicList marked slot).mapError fun error =>
      "psElabDeriveReprAtomicList " ++ psNameToString slot.recursorName ++ ": " ++
        psCompilerPscv0ElabError error)
  ensure (atomic == [false, false, true, false, false, false, false, false, false])
    "List specialization did not select the actual ReprAtom marker"
  let some listBranch := plan.elimination.slots[2]?
    | throw (IO.userError "List Branch slot is absent")
  let some arrayBranch := plan.elimination.slots[4]?
    | throw (IO.userError "Array Branch slot is absent")
  ensure (psNameEq listBranch.family.name psListName &&
    arrayBranch.constructors.any (fun constructor => constructor.recursiveFields == [(0, 2)]))
    "ordinary List and Array no longer share their real List Branch slot"
  let some listDisplay := plan.elimination.slots[7]?
    | throw (IO.userError "List Display slot is absent")
  let some wrongFamily := psInductiveEliminationInstantiate plan.elimination
      (plan.info.levelParams.map PsLevel.param) (psElabBinderArguments plan.parametersRev)
      listDisplay.typeFormer
    | throw (IO.userError "second List specialization did not instantiate")
  expectRefused "same-base wrong selected List specialization"
    "deriving field has incompatible specialization parameters or indices"
    (psElabDeriveEliminateSlotAt plan plan.context 2 wrongFamily true
      (fun _ _ _ _ => .constE psNatName []) (fun _ _ _ _ _ _ _ => pure (.lit (.natural 0))))
  let indexed ← inPhase "psElabDerivePrepare M3NestedIndexedDisplay" <| fromExcept ((psElabDerivePrepare environment indexedOrigin
    { groups := true, indices := true, nested := true }).mapError psCompilerPscv0ElabError)
  ensure (indexed.indicesRev.length == 1 &&
    indexed.elimination.slots.map (·.family.numIndices) == [1, 0])
    "nested Repr reused the public index telescope for the auxiliary List"
  expectRefused "indexed nested BEq" "deriving indexed families is not yet implemented"
    (psElabDeriveGroupHandler environment indexedOrigin
      { segments := ["BEq"], span := indexedOrigin.span })

private def boolAnd (left right : PsExpr) : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  call (psNameAppendStr psBoolName "rec") [.succ .zero]
    [.lam .anonymous bool bool .explicit, .constE psBoolFalseName [], right, left]

-- A real field dictionary returns its left Boolean. On an explicit two-child
-- spine, portable WHNF must therefore demand `first` for List and `last` for
-- Array. Unknown fields cannot be evaluated during a failed length check.
-- The full generated instance is applied; no motives/minors are reconstructed.
private def checkComparisonOrder (environment : PsEnvironment) : IO (List PsDeclaration) := do
  let bool := PsExpr.constE psBoolName []
  let no := PsExpr.constE psBoolFalseName []
  let yes := PsExpr.constE psBoolTrueName []
  let first := psLocalPushBinding psLocalEmpty (psRootName "first") bool .explicit
  let last := psLocalPushBinding first.context (psRootName "last") bool .explicit
  let display := call (psRootName "M3NestedDisplay") [.zero] [bool, no]
  let branch := call (psRootName "M3NestedBranch") [.zero] [bool, no]
  let child := fun value =>
    call (psNameAppendStr (psRootName "M3NestedBranch") "direct") [.zero]
      [bool, no, call (psNameAppendStr (psRootName "M3NestedDisplay") "leaf") [.zero]
        [bool, no, value]]
  let empty := call (psNameAppendStr psListName "nil") [.zero] [branch]
  let cons := fun value tail => call (psNameAppendStr psListName "cons") [.zero] [branch, value, tail]
  let left := cons (child (.fvar first.id)) (cons (child (.fvar last.id)) empty)
  let right := cons (child no) (cons (child no) empty)
  let short := cons (child no) empty
  let dictionary := call (psNameAppendStr (psRootName "BEq") "mk") [.zero]
    [bool, .lam .anonymous bool (.lam .anonymous bool (.bvar 1) .explicit) .explicit]
  let derivedDictionary := call (psNameAppendStr (psRootName "M3NestedDisplay") "instBEq") [.zero]
    [bool, no, dictionary]
  let compare := fun left right => call (psNameAppendStr (psRootName "BEq") "beq") [.zero]
    [display, derivedDictionary, left, right]
  let asList := fun children => call (psNameAppendStr (psRootName "M3NestedDisplay") "list") [.zero]
    [bool, no, children]
  let asArray := fun children => call (psNameAppendStr (psRootName "M3NestedDisplay") "array") [.zero]
    [bool, no, call (psNameAppendStr psArrayName "mk") [.zero] [branch, children]]
  let forward := compare (asList left) (asList right)
  let reverse := compare (asArray left) (asArray right)
  for (probe, expectedGuard) in [(forward, first.id), (reverse, last.id)] do
    let _ ← fromExcept ((psInferType environment psMetaEmpty last.context probe).mapError
      (fun _ => "generated nested comparison-order probe did not type check"))
    let reduced := psExprAppView (psWhnf environment psMetaEmpty last.context probe)
    let .constE name _ := reduced.head
      | throw (IO.userError "comparison did not demand its first unresolved Boolean guard")
    let some guard := reduced.args[3]?
      | throw (IO.userError "comparison guard is absent")
    ensure (psNameEq name (psNameAppendStr psBoolName "rec") &&
      psExprAlphaEq guard (.fvar expectedGuard)) "native List/Array comparison order changed"
  ensure (psExprAlphaEq (psWhnf environment psMetaEmpty last.context
    (compare (asArray left) (asArray short))) no)
    "Array demanded a field comparison before rejecting unequal lengths"
  ensure (psExprAlphaEq (psWhnf environment psMetaEmpty first.context
    (.app (psLogicLam last.id "last" bool reverse) yes)) (.fvar first.id))
    "reverse Array comparison did not next demand the first element"
  let equation := fun name probe expected =>
    let type := call psEqName [.succ .zero] [bool, probe, expected]
    let value := call (psNameAppendStr psEqName "refl") [.succ .zero] [bool, expected]
    PsDeclaration.theoremDecl (psRootName name) []
      (psLogicPi first.id "first" bool (psLogicPi last.id "last" bool type))
      (psLogicLam first.id "first" bool (psLogicLam last.id "last" bool value))
  return [equation "m3NestedListComparisonEquation" forward
      (boolAnd (.fvar first.id) (boolAnd (.fvar last.id) yes)),
    equation "m3NestedArrayComparisonEquation" reverse (boolAnd (.fvar last.id) (.fvar first.id))]

private def checkPortableReduction (environment : PsEnvironment) : IO Unit := do
  for flag in [false, true] do
    let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
    let atom := PsExpr.app (.constE (psRootName "m3NestedAtomProbe") []) argument
    ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty atom)
      (.constE psBoolFalseName [])) "nested Array BEq skipped the nonreflexive field dictionary"

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3nestedrepr", fun _ => 3),
   ("m3nestedtuplerepr", fun _ => 1),
   ("m3nestedindexedrepr", fun _ => 1),
   ("m3nestedbeq", M3NestedDerivingOracle.beqOutput),
   ("m3nestedarraybeq", M3NestedDerivingOracle.arrayOutput),
   ("m3nestedatombeq", M3NestedDerivingOracle.atomOutput)]

private def witness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
  let value := PsExpr.app (.constE (psRootName name) []) argument
  let expected := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  let proposition := call psEqName [.succ .zero] [uint64, value, expected]
  let proof := call (psNameAppendStr psEqName "refl") [.succ .zero] [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-nested-deriving.ps", sourceText := runtimeSource, outputStem := "nestedderive" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "nestedderive" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

end M3NestedDeriving

open M3NestedDeriving in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "nested deriving qualification requires the pinned Lean"
  let (group, origin) ← inPhase "elaborate visible group" <| fromExcept (elaborateGroup groupSource)
  let (indexed, indexedOrigin) ← inPhase "elaborate indexed group" <| fromExcept (elaborateGroup indexedSource)
  let groups := group.declarations ++ indexed.declarations
  let input ← inPhase "admit data groups" <| add psSelfHostProdPreludeEnvironment groups
  let input ← inPhase "admit ReprAtom marker" <| register input [marker]
  inPhase "check slot plans" <| checkPlans input origin indexedOrigin
  -- Both handlers see the same pre-instance environment. They cannot search
  -- for a partially generated self/group dictionary during induction.
  let ordinary ← derive input origin ["Repr", "BEq"]
  let dependent ← derive input indexedOrigin ["Repr"]
  let instances := ordinary ++ dependent
  ensure (instances.length == 5) "nested deriving did not generate each requested public instance"
  let registered ← inPhase "admit derived instances" <| register input instances
  let orderEquations ← inPhase "check comparison order" <| checkComparisonOrder registered
  let logical ← inPhase "elaborate logical source" <| sourceResult registered logicalSource
  let runtime ← inPhase "elaborate runtime source" <| sourceResult registered runtimeSource
  inPhase "check portable reduction" <| checkPortableReduction runtime.result.environment
  let declarations := groups ++ [marker] ++ instances ++ runtime.result.declarations
  let prepared ← inPhase "prepare checked runtime" <| fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment, declarations }).mapError psCompilerPscv0Error)
  let workers := prepared.prepared.recursorWorkerGroups
  ensure (workers.length == 5 &&
    (workers.filter (fun group => group.workers.length == 9 && group.captureCount == 3)).length == 4 &&
    (workers.filter (fun group => group.workers.length == 2 && group.captureCount == 3)).length == 1)
    "nested deriving lost heterogeneous slot closures or traversed right-side BEq hypotheses"
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let admitted ← inPhase "kernel admit prepared declarations" <|
    checked runtime.result.environment prelude prepared.prepared.declarations
  let signatures := signatureWitnesses groups
  ensure (signatures.length == 11) "nested deriving lost a full visible/auxiliary signature witness"
  let admitted ← inPhase "kernel admit signatures and order equations" <|
    checked runtime.result.environment admitted (signatures ++ orderEquations)
  let _ ← inPhase "kernel admit logical source" <|
    checked logical.result.environment admitted logical.result.declarations
  -- Repr compares full independently rendered native text in the runtime
  -- lanes. Every BEq output additionally has a fresh-kernel closed equation.
  let equations := [false, true].flatMap fun flag =>
    (outputCases.drop 3).map (fun (name, oracle) => witness name flag (oracle flag))
  let _ ← inPhase "kernel admit runtime equations" <|
    checked runtime.result.environment admitted equations
  let ir ← inPhase "erase prepared runtime" <|
    fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← inPhase "emit targets" <| fromExcept (emit ir)
  ensure (artifacts.length == 5) "nested deriving did not emit every target"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "deriving.ps") (groupSource ++ indexedSource ++ runtimeSource)
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
  IO.println "PSCV0_M3_NESTED_DERIVING: PASS checked heterogeneous visible/nested Repr and nonindexed BEq, native collection/tuple formatting, List/Array comparison order, real dictionaries and all recursor signatures; five-target parity follows"
