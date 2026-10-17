import Ps.Host.NativeV7
import PsKernelLean.Admission

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

namespace M3InductiveDeriving

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

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
  let declarations ← fromExcept ((handlers.mapM fun handler =>
    psElabDeriveGroupHandler environment origin { segments := [handler], span := origin.span }).mapError
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

private def checked (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonical declarations).mapError
    (fun _ => "canonical group deriving admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

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
  expectRefused "indexed member through an unindexed selected family"
    "deriving indexed families is not yet implemented"
    (psElabDeriveGroupHandler environment indexedOrigin
      { segments := ["BEq"], span := indexedOrigin.span })
  expectRefused "indexed group Inhabited cannot cover arbitrary rigid indices"
    "Inhabited deriving requires a constructor with inhabitable fields"
    (psElabDeriveGroupHandler environment indexedOrigin
      { segments := ["Inhabited"], span := indexedOrigin.span })
  expectRefused "indexed group DecidableEq" "deriving indexed families is not yet implemented"
    (psElabDeriveHandler environment indexedOrigin
      { segments := ["DecidableEq"], span := indexedOrigin.span })
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
  IO.println "PSCV0_M3_INDUCTIVE_DERIVING_REFUSALS: PASS exact group provenance, ordered real IH association, indexed BEq/DecidableEq boundaries and constructor-directed indexed Inhabited refusal"

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

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-group-deriving.ps", sourceText := runtimeSource, outputStem := "groupderive" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "groupderive" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

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
  checkPlans input origin indexedOrigin
  checkRefusals input origin indexedOrigin
  -- Every handler sees the same input. None of the generated group instances
  -- can be searched as an assumed recursive dictionary while deriving another.
  let ordinary ← derive input origin ["Hashable", "Repr", "BEq"]
  let dependent ← derive input indexedOrigin ["Hashable", "Repr"]
  let instances := ordinary ++ dependent
  ensure (instances.length == 10) "deriving did not generate one instance per requested group member"
  checkMetadataConsumers input groups instances
  let registered ← register input instances
  let logical ← sourceResult registered logicalSource
  let runtime ← sourceResult registered runtimeSource
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
