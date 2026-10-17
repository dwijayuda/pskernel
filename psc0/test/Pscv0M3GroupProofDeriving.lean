import Ps.Host.NativeV7
import Pscv0M3IndexedInhabited
import PsKernelLean.Admission

-- Independent pinned native handlers. The portable declarations below are
-- elaborated separately and every generated decision/default is rechecked by
-- a fresh official kernel before its runtime observations are exported.
universe u

mutual
  inductive M3ProofTree (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | node (left : M3ProofForest A a) (right : M3ProofForest A a)
    | certified (value : Nat) (next : M3ProofTree A a) (certificate : value = value)
  inductive M3ProofForest (A : Type u) (a : A) : Type u where
    | nil
    | cons (head : M3ProofTree A a) (tail : M3ProofForest A a)
end
deriving instance DecidableEq for M3ProofTree, M3ProofForest

inductive M3ProofAtom where
  | atom (flag : Bool)
  deriving DecidableEq

instance : BEq M3ProofAtom where
  beq _ _ := false

mutual
  inductive M3DefaultFirst (A : Type u) (a : A) : Type u where
    | needs (value : A)
    | empty (children : Prod (List (M3DefaultSecond A a))
        (Prod (Option (M3DefaultSecond A a)) (Array (M3DefaultFirst A a))))
  inductive M3DefaultSecond (A : Type u) (a : A) : Type u where
    | fromFirst (parent : M3DefaultFirst A a)
end

-- The later member cannot assume a future default for the earlier member.
/-- error: failed to generate `Inhabited` instance for `M3DefaultSecond` -/
#guard_msgs in
deriving instance Inhabited for M3DefaultSecond, M3DefaultFirst

deriving instance Inhabited for M3DefaultFirst, M3DefaultSecond

example {A : Type u} {a : A} :
    (default : M3DefaultFirst A a) = .empty ([], (none, #[])) := rfl

example {A : Type u} {a : A} :
    (default : M3DefaultSecond A a) = .fromFirst (.empty ([], (none, #[]))) := rfl

mutual
  inductive M3RequiredFirst (A B : Type u) : Type u where
    | mk (value : A) (children : List (M3RequiredSecond A B))
  inductive M3RequiredSecond (A B : Type u) : Type u where
    | fromFirst (parent : M3RequiredFirst A B)
end
deriving instance Inhabited for M3RequiredFirst, M3RequiredSecond

example {A B : Type u} [Inhabited A] :
    (default : M3RequiredFirst A B) = .mk default [] := rfl

example {A B : Type u} [Inhabited A] :
    (default : M3RequiredSecond A B) = .fromFirst (.mk default []) := rfl

inductive M3DefaultLoop (A : Type u) : Type u where
  | loop (next : M3DefaultLoop A)

/-- error: failed to generate `Inhabited` instance for `M3DefaultLoop` -/
#guard_msgs in
deriving instance Inhabited for M3DefaultLoop

namespace M3GroupProofOracle

def forest (n m : Nat) : M3ProofForest Nat 0 :=
  .cons (.certified n (.leaf m) rfl) (.cons (.leaf (n + 1)) .nil)

def tree (n m : Nat) : M3ProofTree Nat 0 :=
  .node (forest n m) (forest (m + 1) (n + 2))

def bits (a b c d e f g : Bool) : UInt64 :=
  UInt64.ofNat ((if a then 1 else 0) + (if b then 2 else 0) +
    (if c then 4 else 0) + (if d then 8 else 0) + (if e then 16 else 0) +
    (if f then 32 else 0) + (if g then 64 else 0))

def decideOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let m := if flag then n + 1 else n + 2
  let x := tree n (n + 1)
  let y := tree n m
  let left := forest n (n + 1)
  let right := forest n m
  bits (decide (x = x)) (decide (x = y)) (decide (y = x))
    (decide (x = .leaf n)) (decide (.leaf n = x))
    (decide (left = right)) (decide (left = .nil))

def atomOutput (flag : Bool) : UInt64 :=
  let atom := M3ProofAtom.atom flag
  let other := M3ProofAtom.atom (!flag)
  let x : M3ProofTree M3ProofAtom (.atom false) :=
    .node (.cons (.leaf atom) .nil) (.cons (.leaf other) .nil)
  let y : M3ProofTree M3ProofAtom (.atom false) :=
    .node (.cons (.leaf other) .nil) (.cons (.leaf other) .nil)
  UInt64.ofNat ((if decide (x = x) then 1 else 0) +
    (if atom == atom then 0 else 2) + (if decide (x = y) then 4 else 0))

def emptyScore : M3DefaultFirst Nat 0 → Nat
  | .needs value => value + 1000
  | .empty children =>
    let optionScore := match children.2.1 with
      | none => 1
      | some _ => 1000
    optionScore + children.1.length + children.2.2.size

def defaultOutput (flag : Bool) : UInt64 :=
  let first : M3DefaultFirst Nat 0 := default
  let second : M3DefaultSecond Nat 0 := default
  let following := match second with
    | .fromFirst parent => 10 + emptyScore parent
  UInt64.ofNat ((if flag then 7 else 19) + emptyScore first + following)

def requiredOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let first : M3RequiredFirst Nat Bool :=
    letI : Inhabited Nat := ⟨n⟩
    default
  let second : M3RequiredSecond Nat Bool :=
    letI : Inhabited Nat := ⟨n + 2⟩
    default
  let score := match first, second with
    | .mk value children, .fromFirst (.mk other rest) =>
      value + 2 * other + children.length + rest.length
  UInt64.ofNat score

end M3GroupProofOracle

namespace M3GroupProofDeriving

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def groupSource : String :=
  "universe u\n" ++
  "inductive M3ProofTree(A: Type u, a: A): Type u where { | leaf(value: A) | node(left: M3ProofForest(A, a), right: M3ProofForest(A, a)) | certified(value: Nat, next: M3ProofTree(A, a), certificate: value = value) }\n" ++
  "inductive M3ProofForest(B: Type u, b: B): Type u where { | nil | cons(head: M3ProofTree(B, b), tail: M3ProofForest(B, b)) }\n"

private def defaultSource : String :=
  "universe u\n" ++
  "inductive M3DefaultFirst(A: Type u, a: A): Type u where { | needs(value: A) | empty(children: Prod(List(M3DefaultSecond(A, a)), Prod(Option(M3DefaultSecond(A, a)), Array(M3DefaultFirst(A, a))))) }\n" ++
  "inductive M3DefaultSecond(B: Type u, b: B): Type u where { | fromFirst(parent: M3DefaultFirst(B, b)) }\n"

private def requiredSource : String :=
  "universe u\n" ++
  "inductive M3RequiredFirst(A: Type u, B: Type u): Type u where { | mk(value: A, children: List(M3RequiredSecond(A, B))) }\n" ++
  "inductive M3RequiredSecond(X: Type u, Y: Type u): Type u where { | fromFirst(parent: M3RequiredFirst(X, Y)) }\n"

private def logicalSource : String :=
  "universe u\n" ++
  "function m3DefaultFirstValue(A: Type u, a: A): M3DefaultFirst(A, a) := Inhabited.default\n" ++
  "function m3DefaultSecondValue(A: Type u, a: A): M3DefaultSecond(A, a) := Inhabited.default\n" ++
  "theorem m3DefaultFirstEquation(A: Type u, a: A): m3DefaultFirstValue(A, a) = M3DefaultFirst.empty(Prod.mk(List.nil, Prod.mk(Option.none, #[]))) := by { rfl }\n" ++
  "theorem m3DefaultSecondEquation(A: Type u, a: A): m3DefaultSecondValue(A, a) = M3DefaultSecond.fromFirst(M3DefaultFirst.empty(Prod.mk(List.nil, Prod.mk(Option.none, #[])))) := by { rfl }\n" ++
  "section\nvariable {A: Type u} {B: Type u} [dictionary: Inhabited A]\n" ++
  "function m3RequiredFirstValue(dummy: Unit): M3RequiredFirst(A, B) := Inhabited.default\n" ++
  "function m3RequiredSecondValue(dummy: Unit): M3RequiredSecond(A, B) := Inhabited.default\n" ++
  "theorem m3RequiredFirstEquation(dummy: Unit): m3RequiredFirstValue(dummy, A := A, B := B) = M3RequiredFirst.mk(Inhabited.default, List.nil) := by { rfl }\n" ++
  "theorem m3RequiredSecondEquation(dummy: Unit): m3RequiredSecondValue(dummy, A := A, B := B) = M3RequiredSecond.fromFirst(M3RequiredFirst.mk(Inhabited.default, List.nil)) := by { rfl }\n" ++
  "end\n"

private def runtimeSource : String :=
  "inductive M3ProofAtom where { | atom(flag: Bool) } deriving DecidableEq\n" ++
  "instance m3ProofAtomBEq: BEq M3ProofAtom where { beq(left: M3ProofAtom, right: M3ProofAtom): Bool := false }\n" ++
  "function m3ProofForestValue(n: Nat, m: Nat): M3ProofForest(Nat, 0) := M3ProofForest.cons(M3ProofTree.certified(n, M3ProofTree.leaf(m), by { rfl }), M3ProofForest.cons(M3ProofTree.leaf(n + 1), M3ProofForest.nil))\n" ++
  "function m3ProofTreeValue(n: Nat, m: Nat): M3ProofTree(Nat, 0) := M3ProofTree.node(m3ProofForestValue(n, m), m3ProofForestValue(m + 1, n + 2))\n" ++
  "function m3GroupProofBits(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool, g: Bool): UInt64 := UInt64.ofNat((if (a) { 1 } else { 0 }) + (if (b) { 2 } else { 0 }) + (if (c) { 4 } else { 0 }) + (if (d) { 8 } else { 0 }) + (if (e) { 16 } else { 0 }) + (if (f) { 32 } else { 0 }) + (if (g) { 64 } else { 0 }))\n" ++
  "function m3groupdecide(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let m: Nat := if (flag) { n + 1 } else { n + 2 }\n" ++
  " let x: M3ProofTree(Nat, 0) := m3ProofTreeValue(n, n + 1)\n" ++
  " let y: M3ProofTree(Nat, 0) := m3ProofTreeValue(n, m)\n" ++
  " let left: M3ProofForest(Nat, 0) := m3ProofForestValue(n, n + 1)\n" ++
  " let right: M3ProofForest(Nat, 0) := m3ProofForestValue(n, m)\n" ++
  " m3GroupProofBits(Decidable.decide(self := decEq(x, x)), Decidable.decide(self := decEq(x, y)), Decidable.decide(self := decEq(y, x)), Decidable.decide(self := decEq(x, M3ProofTree.leaf(n))), Decidable.decide(self := decEq(M3ProofTree.leaf(n), x)), Decidable.decide(self := decEq(left, right)), Decidable.decide(self := decEq(left, M3ProofForest.nil)))\n}\n" ++
  "function m3groupdecideatom(flag: Bool): UInt64 := {\n" ++
  " let atom: M3ProofAtom := M3ProofAtom.atom(flag)\n" ++
  " let other: M3ProofAtom := M3ProofAtom.atom(Bool.not(flag))\n" ++
  " let x: M3ProofTree(M3ProofAtom, M3ProofAtom.atom(false)) := M3ProofTree.node(M3ProofForest.cons(M3ProofTree.leaf(atom), M3ProofForest.nil), M3ProofForest.cons(M3ProofTree.leaf(other), M3ProofForest.nil))\n" ++
  " let y: M3ProofTree(M3ProofAtom, M3ProofAtom.atom(false)) := M3ProofTree.node(M3ProofForest.cons(M3ProofTree.leaf(other), M3ProofForest.nil), M3ProofForest.cons(M3ProofTree.leaf(other), M3ProofForest.nil))\n" ++
  " UInt64.ofNat((if (Decidable.decide(self := decEq(x, x))) { 1 } else { 0 }) + (if (atom == atom) { 0 } else { 2 }) + (if (Decidable.decide(self := decEq(x, y))) { 4 } else { 0 }))\n}\n" ++
  "function m3DefaultEmptyScore(value: M3DefaultFirst(Nat, 0)): Nat := match value with {\n" ++
  " | M3DefaultFirst.needs payload => payload + 1000\n" ++
  " | M3DefaultFirst.empty children => let rest: Prod(Option(M3DefaultSecond(Nat, 0)), Array(M3DefaultFirst(Nat, 0))) := Prod.snd(children)\n" ++
  " let optionScore: Nat := match Prod.fst(rest) with { | Option.none => 1 | Option.some ignored => 1000 }\n" ++
  " optionScore + List.length(Prod.fst(children)) + Array.size(Prod.snd(rest))\n}\n" ++
  "function m3groupdefault(flag: Bool): UInt64 := {\n" ++
  " let first: M3DefaultFirst(Nat, 0) := Inhabited.default\n" ++
  " let second: M3DefaultSecond(Nat, 0) := Inhabited.default\n" ++
  " let following: Nat := match second with { | M3DefaultSecond.fromFirst parent => 10 + m3DefaultEmptyScore(parent) }\n" ++
  " UInt64.ofNat((if (flag) { 7 } else { 19 }) + m3DefaultEmptyScore(first) + following)\n}\n" ++
  "function m3grouprequired(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let first: M3RequiredFirst(Nat, Bool) := m3RequiredFirstWith(n)\n" ++
  " let second: M3RequiredSecond(Nat, Bool) := m3RequiredSecondWith(n + 2)\n" ++
  " let score: Nat := match first with { | M3RequiredFirst.mk value children => match second with { | M3RequiredSecond.fromFirst parent => match parent with { | M3RequiredFirst.mk other rest => value + 2 * other + List.length(children) + List.length(rest) } } }\n" ++
  " UInt64.ofNat(score)\n}\n"

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
    | _ => throw "group proof fixture expected native inductive members"
  let first :: _ := sources | throw "group proof fixture has no inductive source"
  let result ← (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks [psRootName "u"]).mapError
    psCompilerPscv0ElabError
  let origin := psElabBatchOriginAt 0 first (psElabStableMemberOrigins result.declarations 0) none
  return (result, origin)

private def add (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment :=
  fromExcept ((psAddDeclarationList environment declarations).mapError psCompilerPscv0ElabError)

private def register (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment := do
  let environment ← add environment declarations
  fromExcept ((declarations.foldlM (fun current declaration =>
    psElabRegisterInstance current (psDeclarationName declaration) 1000) environment).mapError
      psCompilerPscv0ElabError)

private def derive (environment : PsEnvironment) (origin : PsElabBatchOrigin)
    (handler : String) : IO (List PsDeclaration) :=
  fromExcept ((psElabDeriveGroupHandler environment origin
    { segments := [handler], span := origin.span }).mapError psCompilerPscv0ElabError)

private def sourceResult (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)

private def call (name : PsName) (levels : List PsLevel) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE name levels) arguments

-- These ordinary checked adapters pass a runtime-supplied Nat dictionary to
-- the actual generated defaults. They do not reconstruct either constructor.
private def requiredAdapter (familyName outputName : String) : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let bool := PsExpr.constE psBoolName []
  let family := call (psRootName familyName) [.zero] [nat, bool]
  let dictionary := psStandardInhabitedValue nat (.fvar 0)
  let derivedDictionary := call (psNameAppendStr (psRootName familyName) "instInhabited")
    [.zero] [nat, bool, dictionary]
  let value := psStandardInhabitedDefault (.succ .zero) family derivedDictionary
  .definitionDecl (psRootName outputName) [] (psLogicPi 0 "value" nat family)
    (psLogicLam 0 "value" nat value)

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (label expected : String) (result : Except PsElabError α) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected group proof acceptance: " ++ label))
  | .error error => ensure (refusal error == expected)
      (label ++ " refused at the wrong rule: " ++ refusal error)

private def expectError (label : String) (result : Except PsElabError α) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected projection acceptance: " ++ label))
  | .error _ => pure ()

private def checkRefusals (environment : PsEnvironment)
    (origin defaultOrigin : PsElabBatchOrigin) : IO Unit := do
  let later := defaultOrigin.members.filter fun member =>
    match member.role with
    | .inductiveType => psNameEq member.name (psRootName "M3DefaultSecond")
    | _ => true
  expectRefused "later default before the earlier instance"
    "Inhabited deriving requires a constructor with inhabitable fields"
    (psElabDeriveHandler environment { defaultOrigin with members := later }
      { segments := ["Inhabited"], span := defaultOrigin.span })
  let (loop, loopOrigin) ← fromExcept (elaborateGroup
    "universe u\ninductive M3DefaultLoop(A: Type u): Type u where { | loop(next: M3DefaultLoop(A)) }\n")
  let loopEnvironment ← add environment loop.declarations
  expectRefused "unseeded recursive default"
    "Inhabited deriving requires a constructor with inhabitable fields"
    (psElabDeriveGroupHandler loopEnvironment loopOrigin
      { segments := ["Inhabited"], span := loopOrigin.span })
  expectRefused "nested DecidableEq remains a pinned limitation"
    "recursive deriving requires the M3 data machinery"
    (psElabDeriveGroupHandler environment defaultOrigin
      { segments := ["DecidableEq"], span := defaultOrigin.span })
  expectRefused "reordered group provenance"
    "deriving origin does not retain the complete ordered group"
    (psElabDeriveGroupHandler environment { origin with members := origin.members.reverse }
      { segments := ["DecidableEq"], span := origin.span })
  let name := psNameAppendStr (psRootName "M3ProofTree") "node"
  let some constructor := psEnvironmentFindConstructor environment name
    | throw (IO.userError "two-child proof constructor is absent")
  ensure (constructor.recursiveFields == [0, 1]) "two-child proof fixture lost its real field order"
  let reversed := psEnvironmentInsert environment
    (.constructorDecl { constructor with recursiveFields := [1, 0] })
  expectRefused "reversed same-family decision hypotheses"
    "deriving recursive field metadata is invalid"
    (psElabDeriveGroupHandler reversed origin { segments := ["DecidableEq"], span := origin.span })

private def checkRequirements (environment : PsEnvironment)
    (declarations : List PsDeclaration) : IO Unit := do
  for (family, count) in [("M3ProofTree", 1), ("M3ProofForest", 1),
      ("M3DefaultFirst", 0), ("M3DefaultSecond", 0),
      ("M3RequiredFirst", 1), ("M3RequiredSecond", 1)] do
    let suffix := if family == "M3ProofTree" || family == "M3ProofForest" then
      "instDecidableEq" else "instInhabited"
    let name := psNameAppendStr (psRootName family) suffix
    let some declaration := declarations.find? (fun declaration => psNameEq (psDeclarationName declaration) name)
      | throw (IO.userError "requested group instance is absent")
    let opened ← fromExcept ((psElabOpenCoreTelescope 4096
      (psElabContextEmpty environment [psRootName "u"]) (psDeclarationType declaration)
        (some (2 + count))).mapError
        psCompilerPscv0ElabError)
    let requirements := opened.bindersRev.filter (fun binder => psBinderInfoIsInstance binder.binder)
    ensure (requirements.length == count && opened.bindersRev.length == 2 + count)
      ("group default/decision acquired an extra requirement: " ++ family)
    let .constE className _ := (psExprAppView opened.body).head
      | throw (IO.userError "group instance has an extra binder before its class result")
    let expectedClass := psRootName (if suffix == "instDecidableEq" then "DecidableEq" else "Inhabited")
    ensure (psNameEq className expectedClass) "group instance lost its declared class result"
    if count == 1 then
      let some parameter := opened.bindersRev.reverse[0]?
        | throw (IO.userError "instance lost its first parameter")
      let [requirement] := requirements | throw (IO.userError "instance requirement count changed")
      let view := psExprAppView requirement.type
      let .constE requirementClass _ := view.head
        | throw (IO.userError "instance requirement is not an actual class application")
      let [argument] := view.args | throw (IO.userError "instance requirement is not unary")
      ensure (psNameEq requirementClass expectedClass &&
        psExprAlphaEq argument (.fvar parameter.id))
        ("instance retained the wrong parameter dictionary: " ++ family)
  for (earlier, later) in [("M3DefaultFirst", "M3DefaultSecond"),
      ("M3RequiredFirst", "M3RequiredSecond")] do
    let earlierName := psNameAppendStr (psRootName earlier) "instInhabited"
    let laterName := psNameAppendStr (psRootName later) "instInhabited"
    let some (.definitionDecl _ _ _ value) := declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) laterName)
      | throw (IO.userError "later default is not an ordinary definition")
    ensure (psExprHasConst earlierName value && !psExprHasConst laterName value)
      "later default did not depend on the actual earlier registered instance"

private def equation (name : String) (level : PsLevel) (type left right : PsExpr) : PsDeclaration :=
  .theoremDecl (psRootName name) [] (psLogicEq level type left right)
    (psLogicRefl level type right)

-- Exercise the shared projection owner directly on the second family, with
-- distinct selected/fallback values, and recheck its reductions independently
-- of the derived DecidableEq proof bodies.
private def projectionEquations (environment : PsEnvironment) : IO (List PsDeclaration) := do
  let nat := PsExpr.constE psNatName []
  let seed := PsExpr.lit (.natural 0)
  let tree := call (psRootName "M3ProofTree") [.zero] [nat, seed]
  let forest := call (psRootName "M3ProofForest") [.zero] [nat, seed]
  let leaf := fun n => call (psNameAppendStr (psRootName "M3ProofTree") "leaf") [.zero]
    [nat, seed, .lit (.natural n)]
  let empty := call (psNameAppendStr (psRootName "M3ProofForest") "nil") [.zero] [nat, seed]
  let filled := call (psNameAppendStr (psRootName "M3ProofForest") "cons") [.zero]
    [nat, seed, leaf 7, empty]
  let context := psElabContextEmpty environment
  let getter ← fromExcept ((psElabIndexFunction context filled
    (psNameAppendStr (psRootName "M3ProofForest") "cons") (some 0) tree (leaf 9) (leaf 9)).mapError
      psCompilerPscv0ElabError)
  let selected := PsExpr.app getter filled
  let fallback := PsExpr.app getter empty
  ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty selected) (leaf 7) &&
    psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty fallback) (leaf 9))
    "complete-group projection lost the selected field or its actual fallback"
  let truth := PsExpr.constE (psRootName "True") []
  let falsity := PsExpr.constE (psRootName "False") []
  let predicate ← fromExcept ((psElabIndexFunction context empty
    (psNameAppendStr (psRootName "M3ProofForest") "nil") none (.sortE .zero) falsity truth).mapError
      psCompilerPscv0ElabError)
  ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty (.app predicate empty)) truth &&
    psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty (.app predicate filled)) falsity)
    "complete-group discriminator did not distinguish the actual constructors"
  expectError "constructor from another group member" (psElabIndexFunction context filled
    (psNameAppendStr (psRootName "M3ProofTree") "node") (some 0) tree (leaf 9) (leaf 9))
  expectError "ill-typed fallback" (psElabIndexFunction context filled
    (psNameAppendStr (psRootName "M3ProofForest") "cons") (some 0) tree
      (.constE psBoolTrueName []) (leaf 9))
  let _ ← fromExcept ((psElabResolvedTerm context getter
    (some (.forallE (psRootName "value") forest tree .explicit))).mapError psCompilerPscv0ElabError)
  return [equation "m3GroupProjectionSelected" (.succ .zero) tree selected (leaf 7),
    equation "m3GroupProjectionFallback" (.succ .zero) tree fallback (leaf 9),
    equation "m3GroupDiscriminatorSelected" (.succ .zero) (.sortE .zero) (.app predicate empty) truth,
    equation "m3GroupDiscriminatorOther" (.succ .zero) (.sortE .zero) (.app predicate filled) falsity]

private def checked (environment : PsEnvironment) (prelude : Lean.Kernel.Environment)
    (declarations : List PsDeclaration) : IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonicalIn environment declarations).mapError
    (fun _ => "canonical group proof admission refused"))
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

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3groupdecide", M3GroupProofOracle.decideOutput),
   ("m3groupdecideatom", M3GroupProofOracle.atomOutput),
   ("m3groupdefault", M3GroupProofOracle.defaultOutput),
   ("m3grouprequired", M3GroupProofOracle.requiredOutput)]

private def outputWitness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
  let left := PsExpr.app (.constE (psRootName name) []) argument
  let right := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  equation (name ++ (if flag then "TrueEquation" else "FalseEquation"))
    (.succ .zero) uint64 left right

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-group-proof-deriving.ps", sourceText := runtimeSource, outputStem := "groupproof" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "groupproof" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

end M3GroupProofDeriving

open M3GroupProofDeriving in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "group proof qualification requires the pinned Lean"
  let (group, origin) ← fromExcept (elaborateGroup groupSource)
  let (defaults, defaultOrigin) ← fromExcept (elaborateGroup defaultSource)
  let (required, requiredOrigin) ← fromExcept (elaborateGroup requiredSource)
  let groups := group.declarations ++ defaults.declarations ++ required.declarations
  let input ← add psSelfHostProdPreludeEnvironment groups
  checkRefusals input origin defaultOrigin
  let decisions ← derive input origin "DecidableEq"
  let defaultInstances ← derive input defaultOrigin "Inhabited"
  let requiredInstances ← derive input requiredOrigin "Inhabited"
  let instances := decisions ++ defaultInstances ++ requiredInstances
  ensure (instances.length == 6) "proof/default group did not generate every requested member"
  checkRequirements input instances
  let registered ← register input instances
  let projections ← projectionEquations registered
  let adapters := [requiredAdapter "M3RequiredFirst" "m3RequiredFirstWith",
    requiredAdapter "M3RequiredSecond" "m3RequiredSecondWith"]
  let adapted ← add registered adapters
  let runtime ← sourceResult adapted runtimeSource
  let logical ← sourceResult runtime.result.environment logicalSource
  let declarations := groups ++ instances ++ adapters ++ runtime.result.declarations
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment, declarations }).mapError psCompilerPscv0Error)
  let workers := prepared.prepared.recursorWorkerGroups
  let workerDescription := String.intercalate "; " (workers.map fun group =>
    "captures=" ++ toString group.captureCount ++ " workers=[" ++
      String.intercalate ", " (group.workers.map fun worker =>
        psNameToString worker.name ++ ":" ++ psNameToString (psRecursorWorkerRecursorName worker)) ++ "]")
  ensure (workers.length == 2 && workers.all (fun group =>
    group.workers.length == 2 && group.captureCount == 3))
    ("mutual decisions lost actual left IH workers or traversed right-side/projection IHs; " ++
      "actual groups=" ++ toString workers.length ++ " [" ++ workerDescription ++ "]")
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let admitted ← checked runtime.result.environment prelude prepared.prepared.declarations
  let signatures := signatureWitnesses groups
  ensure (signatures.length == 13) "proof/default groups lost complete public/auxiliary recursor witnesses"
  let admitted ← checked runtime.result.environment admitted (signatures ++ projections)
  let _ ← checked logical.result.environment admitted logical.result.declarations
  let equations := [false, true].flatMap fun flag =>
    outputCases.map (fun (name, oracle) => outputWitness name flag (oracle flag))
  let _ ← checked runtime.result.environment admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "group proof/default fixture did not emit every target"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "deriving.ps") (groupSource ++ defaultSource ++ requiredSource ++ runtimeSource)
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
  IO.println "PSCV0_M3_GROUP_PROOF_DERIVING: PASS checked direct mutual DecidableEq with dependent proof fields, complete group projections/discriminators, native ordered nested defaults and exact parameter requirements; nested DecidableEq/indexed boundaries retained; five-target parity follows"
  M3IndexedInhabited.check ((directory / "indexed-inhabited").toString)
