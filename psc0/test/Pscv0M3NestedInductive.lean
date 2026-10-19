import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Independent pinned Lean declarations and runtime dictionaries. The portable
-- side below elaborates its own native AST groups and never imports these
-- declarations as Core metadata or recursive instance assumptions.
universe u

-- Preserve the formerly refused constructor-local program under native
-- automatic promotion. Its n becomes a common parameter before nesting.
inductive Captured : Nat → Type where
  | branch (n : Nat) (children : List (Captured n)) : Captured n

def capturedTag (value : Captured 2) : Nat :=
  match value with
  | .branch _ _ => 0

example : capturedTag (Captured.branch 2 []) = 0 := rfl

run_cmd do
  let family ← Lean.getConstInfoInduct ``Captured
  let some (.recInfo recursor) := (← Lean.getEnv).find? ``Captured.rec
    | throwError "native promoted nested recursor missing"
  unless family.numParams == 1 && family.numIndices == 0 &&
      recursor.numParams == 1 && recursor.numIndices == 0 &&
      recursor.numMotives == 2 && recursor.numMinors == 3 do
    throwError "native promoted nested parameter/recursor telescope changed"

private def expectNativeNestedLocalRefusal (command : Lean.Syntax) :
    Lean.Elab.Command.CommandElabM Unit := do
  let saved ← get
  let failed ← try
    modify fun (state : Lean.Elab.Command.State) =>
      { state with messages := Lean.MessageLog.empty, snapshotTasks := #[] }
    let messages ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages command
    let errors := messages.toList.filter fun message => message.severity == .error
    unless errors.length == 1 do
      throwError "native nested refusal expected one semantic error, got {errors.length}"
    let mut owned := false
    for message in errors do
      let content ← message.data.toString
      if ["heartbeat", "recursion depth", "maximum recursion", "timeout"].any
          (fun marker => (content.splitOn marker).length > 1) then
        throwError "native nested refusal exhausted resources: {content}"
      if (content.splitOn "nested inductive datatypes parameters cannot contain local variables").length > 1 then
        owned := true
      else
        throwError "native nested refusal reached the wrong owner: {content}"
    pure owned
  finally
    set saved
  unless failed do
    throwError "native nested family did not refuse its constructor-local specialization"

run_cmd do
  let source := "inductive CapturedLocal : Nat → Type where\n  | zero : CapturedLocal 0\n  | branch (n : Nat) (children : List (CapturedLocal n)) : CapturedLocal n\n"
  let command ← match Lean.Parser.runParserCategory (← Lean.getEnv) `command source
      "CapturedLocalNative.lean" with
    | .ok command => pure command
    | .error error => throwError "native nested refusal source did not parse: {error}"
  expectNativeNestedLocalRefusal command

inductive M3FunctionNested where
  | node (children : List (Nat → M3FunctionNested))
example : M3FunctionNested := .node [fun _ => .node []]

inductive M3NestedShape (A : Type u) (a : A) : Type u where
  | leaf (value : A)
  | direct (child : M3NestedShape A a)
  | list (children : List (M3NestedShape A a))
  | option (child : Option (M3NestedShape A a))
  | array (children : Array (M3NestedShape A a))
  | product (children : Prod (M3NestedShape A a) (M3NestedShape A a))
  | deep (children : List (List (M3NestedShape A a)))
  | again (children : List (M3NestedShape A a))
  deriving Hashable

mutual
  inductive M3NestedLeft (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | links (children : List (M3NestedRight A a))
    deriving Hashable
  inductive M3NestedRight (A : Type u) (a : A) : Type u where
    | node (children : List (M3NestedLeft A a))
    | direct (next : M3NestedLeft A a)
    deriving Hashable
end

inductive M3NestedIndexed (A : Type u) (a : A) : Nat → Type u where
  | stop (value : A) : M3NestedIndexed A a 0
  | branch (n : Nat) (children : List (M3NestedIndexed A a 0)) :
      M3NestedIndexed A a (Nat.succ n)
  deriving Hashable

-- The raw-vs-definitional key oracle below uses an independently constructed
-- Lean.Declaration.inductDecl. The native source command for that example
-- reaches maxRecDepth while also requesting automatic elaborator extras;
-- this fixture claims only the actual kernel declaration/recursor boundary.

namespace M3NestedInductiveOracle

-- These full recursor expressions are logical oracles. Native Lean's code
-- generator does not execute nested recursors directly. Runtime counts below
-- use separately written ordinary container traversals.
noncomputable def fold : M3NestedShape Nat 0 → Nat :=
  @M3NestedShape.rec Nat 0
    (fun _ => Nat) (fun _ => Nat) (fun _ => Nat)
    (fun _ => Nat) (fun _ => Nat) (fun _ => Nat)
    (fun _ => 1)
    (fun _ ih => 1 + ih) (fun _ ih => 1 + ih)
    (fun _ ih => 1 + ih) (fun _ ih => 1 + ih)
    (fun _ ih => 1 + ih) (fun _ ih => 1 + ih)
    (fun _ ih => 1 + ih)
    0 (fun _ _ head tail => head + tail)
    0 (fun _ ih => ih)
    (fun _ ih => ih)
    (fun _ _ left right => left + right)
    0 (fun _ _ head tail => head + tail)

noncomputable def indexedFold {n : Nat} : M3NestedIndexed Nat 0 n → Nat :=
  @M3NestedIndexed.rec Nat 0 (fun _ _ => Nat) (fun _ => Nat)
    (fun _ => 1) (fun _ _ ih => 1 + ih)
    0 (fun _ _ head tail => head + tail) n

example : fold (.array (Array.mk [.leaf 1, .direct (.leaf 2)])) = 4 := rfl
example : fold (.product (.leaf 2, .direct (.leaf 4))) = 4 := rfl
example : indexedFold (.branch 2 [.stop 1, .stop 2, .stop 3]) = 4 := rfl
example (n m k : Nat) : hash ([n, m, k] : List Nat) =
    mixHash (mixHash (mixHash 7 (hash n)) (hash m)) (hash k) := rfl

partial def count (value : M3NestedShape Nat 0) : Nat :=
  match value with
  | .leaf _ => 1
  | .direct child => 1 + count child
  | .list children => 1 + children.foldl (fun acc child => acc + count child) 0
  | .option child => 1 + (match child with | none => 0 | some child => count child)
  | .array children => 1 + children.foldl (fun acc child => acc + count child) 0
  | .product children => 1 + count children.1 + count children.2
  | .deep children => 1 + children.foldl
      (fun acc row => acc + row.foldl (fun acc child => acc + count child) 0) 0
  | .again children => 1 + children.foldl (fun acc child => acc + count child) 0

mutual
  partial def countLeft (value : M3NestedLeft Nat 0) : Nat :=
    match value with
    | .leaf _ => 1
    | .links children => 1 + children.foldl (fun acc child => acc + countRight child) 0
  partial def countRight (value : M3NestedRight Nat 0) : Nat :=
    match value with
    | .node children => 1 + children.foldl (fun acc child => acc + countLeft child) 0
    | .direct child => 1 + countLeft child
end

partial def countIndexed {n : Nat} (value : M3NestedIndexed Nat 0 n) : Nat :=
  match value with
  | .stop _ => 1
  | .branch _ children => 1 + children.foldl (fun acc child => acc + countIndexed child) 0

def directCount (value : M3NestedShape Nat 0) : Nat :=
  match value with
  | .direct child => 1 + directCount child
  | _ => 1

def value (n : Nat) : M3NestedShape Nat 0 :=
  let x := M3NestedShape.leaf (a := 0) n
  let y := M3NestedShape.leaf (a := 0) (n + 1)
  let z := M3NestedShape.leaf (a := 0) (n + 2)
  let children := [x, y, z]
  let ordinary := M3NestedShape.list children
  let optional := M3NestedShape.option (some (.direct x))
  let absent := M3NestedShape.option (a := 0) none
  let array := M3NestedShape.array (Array.mk children)
  let product := M3NestedShape.product (ordinary, array)
  .deep [[product, optional], [absent, .again children]]

def rightValue (n : Nat) (flag : Bool) : M3NestedRight Nat 0 :=
  let leaf := M3NestedLeft.leaf (a := 0) n
  let left := M3NestedLeft.links
    [.direct leaf, .node [leaf, .leaf (n + 1)]]
  if flag then .direct left else .node [left, .leaf (n + 2)]

def payload (flag : Bool) : Nat := if flag then 31 else 11

def selected (flag : Bool) : M3NestedShape Nat 0 :=
  let x := value (payload flag)
  if flag then .direct x else x

def foldOutput (flag : Bool) : UInt64 := UInt64.ofNat (count (selected flag))
def hashOutput (flag : Bool) : UInt64 := hash (selected flag)
def mutualFoldOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (countRight (rightValue (payload flag) flag))
def mutualHashOutput (flag : Bool) : UInt64 := hash (rightValue (payload flag) flag)
def indexedFoldOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  if flag then UInt64.ofNat (countIndexed (.branch 2 [.stop n, .stop (n + 1), .stop (n + 2)]))
  else UInt64.ofNat (countIndexed (.stop n))
def indexedHashOutput (flag : Bool) : UInt64 :=
  let n := payload flag
  if flag then hash (M3NestedIndexed.branch (a := 0) 2 [.stop n, .stop (n + 1), .stop (n + 2)])
  else hash (M3NestedIndexed.stop (a := 0) n)
def directOutput (flag : Bool) : UInt64 :=
  let x := value (payload flag)
  UInt64.ofNat (directCount (if flag then .direct (.direct x) else .direct x))

end M3NestedInductiveOracle

namespace M3NestedInductive

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def shapeSource : String :=
  "universe u\n" ++
  "inductive M3NestedShape(A: Type u, a: A): Type u where {\n" ++
  " | leaf(value: A)\n | direct(child: M3NestedShape(A, a))\n" ++
  " | list(children: List(M3NestedShape(A, a)))\n" ++
  " | option(child: Option(M3NestedShape(A, a)))\n" ++
  " | array(children: Array(M3NestedShape(A, a)))\n" ++
  " | product(children: Prod(M3NestedShape(A, a), M3NestedShape(A, a)))\n" ++
  " | deep(children: List(List(M3NestedShape(A, a))))\n" ++
  " | again(children: List(M3NestedShape(A, a)))\n}\n"

-- The public group aliases A/a as B/b. Its two List slots have the same actual
-- List.cons owner, different specialization keys and different rec_N names.
private def mutualSource : String :=
  "universe u\n" ++
  "inductive M3NestedLeft(A: Type u, a: A): Type u where { | leaf(value: A) | links(children: List(M3NestedRight(A, a))) }\n" ++
  "inductive M3NestedRight(B: Type u, b: B): Type u where { | node(children: List(M3NestedLeft(B, b))) | direct(next: M3NestedLeft(B, b)) }\n"

private def indexedSource : String :=
  "universe u\n" ++
  "inductive M3NestedIndexed(A: Type u, a: A): Nat -> Type u where { | stop(value: A): M3NestedIndexed(A, a, 0) | branch(n: Nat, children: List(M3NestedIndexed(A, a, 0))): M3NestedIndexed(A, a, Nat.succ(n)) }\n"

private def keySource : String :=
  "universe u\n" ++
  "inductive M3NestedKey(A: Type u): Type u where { | leaf | plain(children: List(M3NestedKey(A))) | aliased(children: List(Id(M3NestedKey(A)))) }\n"

private def logicalSource : String :=
  "theorem m3NestedListHashLaw(n: Nat, m: Nat, k: Nat): Hashable.hash((M3NestedShape.list(List.cons(M3NestedShape.leaf(n), List.cons(M3NestedShape.leaf(m), List.cons(M3NestedShape.leaf(k), List.nil)))) : M3NestedShape(Nat, 0))) = mixHash(UInt64.ofNat(2), mixHash(mixHash(mixHash(UInt64.ofNat(7), mixHash(UInt64.ofNat(0), Hashable.hash(n))), mixHash(UInt64.ofNat(0), Hashable.hash(m))), mixHash(UInt64.ofNat(0), Hashable.hash(k)))) := by { rfl }\n" ++
  "theorem m3NestedArrayHashLaw(n: Nat, m: Nat, k: Nat): Hashable.hash((M3NestedShape.array(Array.mk(List.cons(M3NestedShape.leaf(n), List.cons(M3NestedShape.leaf(m), List.cons(M3NestedShape.leaf(k), List.nil))))) : M3NestedShape(Nat, 0))) = mixHash(UInt64.ofNat(4), mixHash(mixHash(mixHash(UInt64.ofNat(7), mixHash(UInt64.ofNat(0), Hashable.hash(n))), mixHash(UInt64.ofNat(0), Hashable.hash(m))), mixHash(UInt64.ofNat(0), Hashable.hash(k)))) := by { rfl }\n" ++
  "theorem m3NestedNoneHashLaw: Hashable.hash((M3NestedShape.option(Option.none) : M3NestedShape(Nat, 0))) = mixHash(UInt64.ofNat(3), UInt64.ofNat(11)) := by { rfl }\n" ++
  "theorem m3NestedSomeHashLaw(n: Nat): Hashable.hash((M3NestedShape.option(Option.some(M3NestedShape.leaf(n))) : M3NestedShape(Nat, 0))) = mixHash(UInt64.ofNat(3), mixHash(mixHash(UInt64.ofNat(0), Hashable.hash(n)), UInt64.ofNat(13))) := by { rfl }\n" ++
  "theorem m3NestedProdHashLaw(n: Nat, m: Nat): Hashable.hash((M3NestedShape.product(Prod.mk(M3NestedShape.leaf(n), M3NestedShape.direct(M3NestedShape.leaf(m)))) : M3NestedShape(Nat, 0))) = mixHash(UInt64.ofNat(5), mixHash(mixHash(UInt64.ofNat(0), Hashable.hash(n)), mixHash(UInt64.ofNat(1), mixHash(UInt64.ofNat(0), Hashable.hash(m))))) := by { rfl }\n" ++
  "theorem m3NestedIndexedHashLaw(n: Nat): Hashable.hash((M3NestedIndexed.branch(2, List.cons(M3NestedIndexed.stop(n), List.nil)) : M3NestedIndexed(Nat, 0, 3))) = mixHash(mixHash(UInt64.ofNat(1), Hashable.hash((2 : Nat))), mixHash(UInt64.ofNat(7), mixHash(UInt64.ofNat(0), Hashable.hash(n)))) := by { rfl }\n" ++
  "theorem m3NestedCases(x: M3NestedShape(Nat, 0)): x = x := by {\n" ++
  " cases x\n case leaf value => rfl\n case direct child => rfl\n" ++
  " case list children => rfl\n case option child => rfl\n case array children => rfl\n" ++
  " case product children => rfl\n case deep children => rfl\n case again children => rfl\n}\n"

private def runtimeSource : String :=
  "function m3NestedValue(n: Nat): M3NestedShape(Nat, 0) := {\n" ++
  " let x: M3NestedShape(Nat, 0) := M3NestedShape.leaf(n)\n" ++
  " let y: M3NestedShape(Nat, 0) := M3NestedShape.leaf(n + 1)\n" ++
  " let z: M3NestedShape(Nat, 0) := M3NestedShape.leaf(n + 2)\n" ++
  " let children: List(M3NestedShape(Nat, 0)) := List.cons(x, List.cons(y, List.cons(z, List.nil)))\n" ++
  " let ordinary: M3NestedShape(Nat, 0) := M3NestedShape.list(children)\n" ++
  " let optional: M3NestedShape(Nat, 0) := M3NestedShape.option(Option.some(M3NestedShape.direct(x)))\n" ++
  " let absent: M3NestedShape(Nat, 0) := M3NestedShape.option(Option.none)\n" ++
  " let array: M3NestedShape(Nat, 0) := M3NestedShape.array(Array.mk(children))\n" ++
  " let product: M3NestedShape(Nat, 0) := M3NestedShape.product(Prod.mk(ordinary, array))\n" ++
  " let first: List(M3NestedShape(Nat, 0)) := List.cons(product, List.cons(optional, List.nil))\n" ++
  " let second: List(M3NestedShape(Nat, 0)) := List.cons(absent, List.cons(M3NestedShape.again(children), List.nil))\n" ++
  " M3NestedShape.deep(List.cons(first, List.cons(second, List.nil)))\n}\n" ++
  "function m3NestedSelected(flag: Bool): M3NestedShape(Nat, 0) := {\n" ++
  " let x: M3NestedShape(Nat, 0) := m3NestedValue(if (flag) { 31 } else { 11 })\n" ++
  " if (flag) { M3NestedShape.direct(x) } else { x }\n}\n" ++
  "function m3NestedRightValue(n: Nat, flag: Bool): M3NestedRight(Nat, 0) := {\n" ++
  " let leaf: M3NestedLeft(Nat, 0) := M3NestedLeft.leaf(n)\n" ++
  " let right: M3NestedRight(Nat, 0) := M3NestedRight.node(List.cons(leaf, List.cons(M3NestedLeft.leaf(n + 1), List.nil)))\n" ++
  " let left: M3NestedLeft(Nat, 0) := M3NestedLeft.links(List.cons(M3NestedRight.direct(leaf), List.cons(right, List.nil)))\n" ++
  " if (flag) { M3NestedRight.direct(left) } else { M3NestedRight.node(List.cons(left, List.cons(M3NestedLeft.leaf(n + 2), List.nil))) }\n}\n" ++
  "function m3NestedDirect(x: M3NestedShape(Nat, 0)): Nat := match x with {\n" ++
  " | .leaf value => 1\n | .direct child => 1 + m3NestedDirect(child)\n" ++
  " | .list children => 1\n | .option child => 1\n | .array children => 1\n" ++
  " | .product children => 1\n | .deep children => 1\n | .again children => 1\n}\n" ++
  "function m3nestedfold(flag: Bool): UInt64 := UInt64.ofNat(M3NestedShape.fold(m3NestedSelected(flag)))\n" ++
  "function m3nestedhash(flag: Bool): UInt64 := Hashable.hash(m3NestedSelected(flag))\n" ++
  "function m3nestedmutualfold(flag: Bool): UInt64 := UInt64.ofNat(M3NestedRight.fold(m3NestedRightValue(if (flag) { 31 } else { 11 }, flag)))\n" ++
  "function m3nestedmutualhash(flag: Bool): UInt64 := Hashable.hash(m3NestedRightValue(if (flag) { 31 } else { 11 }, flag))\n" ++
  "function m3nestedindexedfold(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 31 } else { 11 }\n" ++
  " if (flag) { UInt64.ofNat(M3NestedIndexed.fold((M3NestedIndexed.branch(2, List.cons(M3NestedIndexed.stop(n), List.cons(M3NestedIndexed.stop(n + 1), List.cons(M3NestedIndexed.stop(n + 2), List.nil)))) : M3NestedIndexed(Nat, 0, 3)))) } else { UInt64.ofNat(M3NestedIndexed.fold((M3NestedIndexed.stop(n) : M3NestedIndexed(Nat, 0, 0)))) }\n}\n" ++
  "function m3nestedindexedhash(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 31 } else { 11 }\n" ++
  " if (flag) { Hashable.hash((M3NestedIndexed.branch(2, List.cons(M3NestedIndexed.stop(n), List.cons(M3NestedIndexed.stop(n + 1), List.cons(M3NestedIndexed.stop(n + 2), List.nil)))) : M3NestedIndexed(Nat, 0, 3))) } else { Hashable.hash((M3NestedIndexed.stop(n) : M3NestedIndexed(Nat, 0, 0))) }\n}\n" ++
  "function m3nesteddirect(flag: Bool): UInt64 := {\n" ++
  " let x: M3NestedShape(Nat, 0) := m3NestedValue(if (flag) { 31 } else { 11 })\n" ++
  " UInt64.ofNat(m3NestedDirect(if (flag) { M3NestedShape.direct(M3NestedShape.direct(x)) } else { M3NestedShape.direct(x) }))\n}\n"

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
    | _ => throw "nested fixture expected native inductive members"
  let first :: _ := sources | throw "nested fixture has no group source"
  let result ← (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks [psRootName "u"]).mapError
    psCompilerPscv0ElabError
  let origin := psElabBatchOriginAt 0 first (psElabStableMemberOrigins result.declarations 0) none
  return (result, origin)

private def add (environment : PsEnvironment) (declarations : List PsDeclaration) : IO PsEnvironment :=
  fromExcept ((psAddDeclarationList environment declarations).mapError psCompilerPscv0ElabError)

private def selectedOrigin (origin : PsElabBatchOrigin) (name : PsName) : PsElabBatchOrigin :=
  {
    origin with
    members := origin.members.filter fun member =>
      match member.role with
      | .inductiveType => psNameEq member.name name
      | _ => true }

-- This fold is a real second consumer of the shared complete-motive owner.
-- It counts visible constructors and sums the actual child-slot hypotheses;
-- no metadata-synthesized recursive call or dictionary is used.
private def fold (environment : PsEnvironment) (origin : PsElabBatchOrigin) :
    Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin
    { groups := true, indices := true, nested := true }
  let nat := PsExpr.constE psNatName []
  let value ← psElabDeriveEliminateSlots plan plan.context true
    (fun _ _ _ _ => nat)
    (fun _ _ slot _ _ hypotheses _ =>
      pure (hypotheses.foldl (fun result hypothesis =>
        psExprApplyMany (.constE psNatAddName []) [result, hypothesis.value])
        (.lit (.natural (if slot.publicMember then 1 else 0)))))
  let type ← (psInferType environment plan.context.metaContext plan.context.localContext value).mapError
    PsElabError.infer
  psElabDeriveFinish plan "fold" type value

private def sourceResult (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)

private def encode (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except String String :=
  (psEncodeCheckedAdmissionsCanonicalIn environment declarations).mapError
    (fun _ => "canonical complete nested admission refused")

private def checked (environment : PsEnvironment) (prelude : Lean.Kernel.Environment)
    (declarations : List PsDeclaration) : IO Lean.Kernel.Environment := do
  let encoded ← fromExcept (encode environment declarations)
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

private def oneAdmission (environment : PsEnvironment) (declarations : List PsDeclaration)
    (members : Nat) : IO Unit := do
  let encoded ← fromExcept (encode environment declarations)
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError (fun error => error.message))
  match decoded.toList with
  | [.inductDecl _ _ types false] =>
    ensure (types.length == members) "nested plan serialized a private or duplicate container datatype"
  | _ => throw (IO.userError "nested public group was not one atomic checked admission")
  match psEncodeCheckedAdmissionsCanonical declarations with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "nested admission without actual container declarations was accepted")

private def planFor (environment : PsEnvironment) (name : String) :
    IO PsInductiveEliminationPlan := do
  let some family := psEnvironmentFindInductive environment (psRootName name)
    | throw (IO.userError "nested public family is absent")
  let some plan := psInductiveEliminationPlanFor (psWhnf environment psMetaEmpty psLocalEmpty)
      (psEnvironmentFindInductive environment) (psEnvironmentFindConstructor environment)
      (psEnvironmentFindRecursor environment) family
    | throw (IO.userError "complete registered nested plan is absent")
  return plan

private def call (name : PsName) (levels : List PsLevel) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE name levels) arguments

private def checkPlans (environment : PsEnvironment) : IO Unit := do
  let shape ← planFor environment "M3NestedShape"
  ensure (shape.parameters.length == 2 && shape.slots.length == 6 &&
    psInductiveEliminationNumMinors shape == 16) "wrong complete Shape slot telescope"
  let nat := PsExpr.constE psNatName []
  let zero := PsExpr.lit (.natural 0)
  let tree := call (psRootName "M3NestedShape") [.zero] [nat, zero]
  let list := call psListName [.zero] [tree]
  let expected := [
    tree, list, call psOptionName [.zero] [tree], call psArrayName [.zero] [tree],
    call psProdName [.zero, .zero] [tree, tree], call psListName [.zero] [list]]
  for (slot, expected) in shape.slots.zip expected do
    let some actual := psInductiveEliminationInstantiate shape [.zero] [nat, zero] slot.typeFormer
      | throw (IO.userError "nested slot template did not instantiate")
    ensure (psExprAlphaEq actual expected) "nested queue order or structural specialization identity changed"
  ensure ((shape.slots.drop 1).all (fun slot =>
    !slot.publicMember && slot.family.numIndices == 0)) "nested slot acquired public/indexed identity"
  let some array := shape.slots[3]? | throw (IO.userError "Array slot absent")
  let some product := shape.slots[4]? | throw (IO.userError "Prod slot absent")
  let some deep := shape.slots[5]? | throw (IO.userError "deep List slot absent")
  ensure (array.family.numParams == 1 && array.constructors.any (fun constructor =>
    constructor.recursiveFields == [(0, 1)])) "Array field did not select the existing List specialization"
  ensure (product.family.numParams == 2 && product.constructors.any (fun constructor =>
    constructor.recursiveFields == [(0, 0), (1, 0)])) "Prod did not retain both actual child hypotheses"
  ensure (deep.constructors.any (fun constructor =>
    constructor.recursiveFields == [(0, 1), (1, 5)])) "nested List head and tail lost distinct target slots"
  let mutualGroup ← planFor environment "M3NestedRight"
  ensure (mutualGroup.parameters.length == 2 && mutualGroup.slots.length == 4 &&
    psInductiveEliminationNumMinors mutualGroup == 8) "nested mutual closure differs from pinned Lean"
  let indexed ← planFor environment "M3NestedIndexed"
  ensure (indexed.parameters.length == 2 && indexed.slots.map (·.family.numIndices) == [1, 0] &&
    psInductiveEliminationNumMinors indexed == 4) "nested indexed slot reused the public index count"
  let key ← planFor environment "M3NestedKey"
  let [_, plain, aliased] := key.slots
    | throw (IO.userError "definitionally equal structural keys were merged")
  ensure (!psExprAlphaEq plain.typeFormer aliased.typeFormer &&
    psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty plain.typeFormer aliased.typeFormer)
    "structural-key oracle no longer distinguishes raw identity from definitional equality"

private def kernelShapes (environment : Lean.Kernel.Environment)
    (declarations : List PsDeclaration) : IO Unit := do
  for declaration in declarations do
    if let .recursorDecl expected := declaration then
      let some (.recInfo actual) := environment.find? (PsKernelLean.toLeanName expected.name)
        | throw (IO.userError "official kernel did not regenerate a public/auxiliary recursor")
      ensure (actual.numParams == expected.numParams && actual.numIndices == expected.numIndices &&
        actual.numMotives == expected.numMotives && actual.numMinors == expected.numMinors &&
        actual.all == expected.inductiveNames.map PsKernelLean.toLeanName)
        "official nested recursor telescope or visible-only group names differ"

-- Build the family and all constructor types directly with the official Lean
-- AST. No portable declaration, conversion, or generated telescope enters
-- this oracle. Id is retained in the aliased List parameter before admission.
private def independentKeyDeclaration : Lean.Declaration :=
  let level := Lean.Level.param `u
  let sort := Lean.Expr.sort (.succ level)
  let family := Lean.Expr.const `M3NestedKey [level]
  let atParameter := Lean.Expr.app family (.bvar 0)
  let result := Lean.Expr.app family (.bvar 1)
  let list := Lean.Expr.const `List [level]
  let plain := Lean.Expr.app list atParameter
  let aliased := Lean.Expr.app list (.app (.const `Id [level]) atParameter)
  let parameter := fun (body : Lean.Expr) => Lean.Expr.forallE `A sort body .implicit
  let constructors : List Lean.Constructor := [
    { name := `M3NestedKey.leaf, type := parameter atParameter },
    { name := `M3NestedKey.plain,
      type := parameter (.forallE `children plain result .default) },
    { name := `M3NestedKey.aliased,
      type := parameter (.forallE `children aliased result .default) }]
  .inductDecl [`u] 1 [{
    name := `M3NestedKey
    type := .forallE `A sort sort .default
    ctors := constructors }] false

private def checkKeyKernelOracle (environment : PsEnvironment)
    (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) : IO Unit := do
  let encoded ← fromExcept (encode environment declarations)
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  match independentKeyDeclaration, decoded.toList with
  | .inductDecl levels parameters [expected] false,
      [.inductDecl actualLevels actualParameters [actual] false] =>
    ensure (levels == actualLevels && parameters == actualParameters && actual == expected)
      "portable raw-key family/constructor types differ from the independent Lean AST"
  | _, _ => throw (IO.userError "raw-key oracle lost its one ordinary kernel declaration")
  -- Keep the native default recursion depth, below the unchanged provider's
  -- existing ceiling. An actual kernel refusal remains a fixture failure.
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    prelude.addDeclCore 2000000 1000 independentKeyDeclaration none
  let oracle ← fromExcept (result.mapError PsKernelLean.kernelExceptionSummary)
  let witnesses := signatureWitnesses declarations
  ensure (witnesses.length == 3) "raw-key oracle lost a public/auxiliary signature witness"
  let oracle ← checked environment oracle witnesses
  kernelShapes oracle declarations

private def reductionWitness (name : String) (value : PsExpr) (expected : Nat) : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let expected := PsExpr.lit (.natural expected)
  let proposition := call psEqName [.succ .zero] [nat, value, expected]
  let proof := call (psNameAppendStr psEqName "refl") [.succ .zero] [nat, expected]
  .theoremDecl (psRootName name) [] proposition proof

-- Start with the generated public fold's complete prefix, then call the
-- registered Prod specialization on two unequal children. This uses the
-- actual two-IH minor, not a separately reconstructed test approximation.
private def productProbe (environment : PsEnvironment) (folds : List PsDeclaration) : IO PsExpr := do
  let name := psNameAppendStr (psRootName "M3NestedShape") "fold"
  let some (.definitionDecl _ levels _ value) := folds.find?
      (fun declaration => psNameEq (psDeclarationName declaration) name)
    | throw (IO.userError "nested fold declaration absent")
  let nat := PsExpr.constE psNatName []
  let zero := PsExpr.lit (.natural 0)
  let tree := call (psRootName "M3NestedShape") [.zero] [nat, zero]
  let leaf := fun n => call (psNameAppendStr (psRootName "M3NestedShape") "leaf")
    [.zero] [nat, zero, .lit (.natural n)]
  let child := call (psNameAppendStr (psRootName "M3NestedShape") "direct")
    [.zero] [nat, zero, leaf 4]
  let some opened := psRecursorLiftBetaApply
      (psExprInstantiateLevelParams levels [.zero] value) [nat, zero, leaf 2]
    | throw (IO.userError "nested fold common telescope did not open")
  let some view := psEliminationRecursorApplication environment opened
    | throw (IO.userError "nested fold lost its complete checked recursor prefix")
  let .constE _ recursorLevels := view.head | throw (IO.userError "nested fold head is not a constant")
  let major := call (psNameAppendStr psProdName "mk") [.zero, .zero] [tree, tree, leaf 2, child]
  let probe := call (psNameAppendStr (psRootName "M3NestedShape") "rec_4")
    recursorLevels (view.fixedArgs ++ [major])
  let _ ← fromExcept ((psInferType environment psMetaEmpty psLocalEmpty probe).mapError
    (fun _ => "actual Prod-slot probe failed Core type inference"))
  ensure (psReduceIota (fun value => value) environment probe).isSome
    "actual Prod-slot probe did not reduce"
  ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty probe) (.lit (.natural 3)))
    "portable Prod specialization differs from independent unequal-child fold"
  ensure ((psGroupRecursorApplication environment probe).isNone &&
    (psRecursorApplication environment probe).isNone)
    "legacy direct/singleton recursor views silently accepted a nested specialization"
  return probe

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | .proof message => message
  | error => psCompilerPscv0ElabError error

private def expectSourceRefused (environment : PsEnvironment)
    (label text expected : String) : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  match psElabProgramWithOrigins environment parsed with
  | .ok _ => throw (IO.userError ("unexpected nested source acceptance: " ++ label))
  | .error error =>
    ensure (refusal error == expected) (label ++ " refused at wrong rule: " ++ refusal error)

private def expectCodecRefused (environment : PsEnvironment) (declarations : List PsDeclaration) : IO Unit :=
  match psEncodeCheckedAdmissionsCanonicalIn environment declarations with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "stale/incomplete nested plan survived canonical admission")

private def remove (environment : PsEnvironment) (name : PsName) : PsEnvironment :=
  let hash := psEnvironmentNameHash name
  let bucket := psEnvironmentIndexFindWorker 16 environment.index hash
  {
    environment with
    declarations := psEnvironmentRemoveName name environment.declarations
    index := psEnvironmentIndexSetWorker 16 environment.index hash
      (psEnvironmentRemoveName name bucket) }

private def capturedSource : String :=
  "inductive Captured: Nat -> Type where { | branch(n: Nat, children: List(Captured(n))): Captured(n) }\nfunction capturedTag(value: Captured(2)): Nat := match value with { | Captured.branch _ _ => 0 }\ntheorem capturedTagEquation: capturedTag(Captured.branch(2, List.nil)) = 0 := by { rfl }\n"

private def checkRefusals (environment : PsEnvironment) (shape : PsElabDeclarationBatchResult)
    (origin : PsElabBatchOrigin) (probe : PsExpr) : IO Unit := do
  expectSourceRefused environment "constructor-local specialization"
    "inductive CapturedLocal: Nat -> Type where { | zero: CapturedLocal(0) | branch(n: Nat, children: List(CapturedLocal(n))): CapturedLocal(n) }\n"
    "nested specialization requires selected containers and common parameters only"
  expectSourceRefused environment "negative function domain inside List"
    "inductive NegativeFunctionNested where { | node(children: List(NegativeFunctionNested -> Nat)) }\n"
    "recursive family occurs in a function-field domain"
  expectSourceRefused environment "nonuniform occurrence erased by beta reduction"
    "inductive ErasedNonuniform(A: Type) where { | hide(value: (fun (T: Type) => Nat)(ErasedNonuniform(Nat))) }\n"
    "constructor parameters must remain uniform"
  expectSourceRefused environment "default nested induction"
    "theorem bad(x: M3NestedShape(Nat, 0)): x = x := by { induction x }\n"
    "nested induction requires an explicit eliminator"
  -- Repr and nonindexed BEq have independent checked/native positives in
  -- Pscv0M3NestedDeriving; constructor-based nested Inhabited is checked in
  -- Pscv0M3GroupProofDeriving. Pinned native nested DecidableEq still refuses.
  for handler in ["DecidableEq"] do
    match psElabDeriveHandler environment origin { segments := [handler], span := origin.span } with
    | .error error =>
      ensure (refusal error == "recursive deriving requires the M3 data machinery")
        ("nested " ++ handler ++ " refused at wrong boundary: " ++ refusal error)
    | .ok _ => throw (IO.userError ("nested " ++ handler ++ " unexpectedly accepted"))
  let recName := psNameAppendStr (psRootName "M3NestedShape") "rec_5"
  let some recursor := psEnvironmentFindRecursor environment recName
    | throw (IO.userError "last nested recursor absent")
  let retained := shape.declarations.filter fun declaration =>
    !psNameEq (psDeclarationName declaration) recName
  let missing := remove environment recName
  expectCodecRefused missing retained
  ensure (psEliminationRecursorApplication missing probe).isNone "missing auxiliary recursor acquired a view"
  expectCodecRefused environment (shape.declarations ++ [.recursorDecl recursor])
  let badLevel := PsDeclaration.recursorDecl { recursor with levelParams := recursor.levelParams.reverse }
  let replace := fun (declarations : List PsDeclaration) (replacement : PsDeclaration) =>
    declarations.map fun declaration =>
      if psNameEq (psDeclarationName declaration) (psDeclarationName replacement) then replacement else declaration
  expectCodecRefused environment (replace shape.declarations badLevel)
  let listName := psNameAppendStr (psRootName "M3NestedShape") "list"
  let some list := psEnvironmentFindConstructor environment listName
    | throw (IO.userError "List constructor absent")
  let some deep := psEnvironmentFindConstructor environment (psNameAppendStr (psRootName "M3NestedShape") "deep")
    | throw (IO.userError "deep constructor absent")
  let stale := PsDeclaration.constructorDecl { list with type := deep.type }
  let staleEnvironment := psEnvironmentInsert environment stale
  let some family := psEnvironmentFindInductive staleEnvironment (psRootName "M3NestedShape")
    | throw (IO.userError "stale probe family absent")
  let some identity := psInductiveGroupIdentityFor (psEnvironmentFindInductive staleEnvironment)
      (psEnvironmentFindRecursor staleEnvironment) family
    | throw (IO.userError "stale probe unexpectedly changed visible group identity")
  let some stalePlan := psBuildInductiveEliminationPlan
      (psWhnf staleEnvironment psMetaEmpty psLocalEmpty)
      (psEnvironmentFindInductive staleEnvironment) (psEnvironmentFindConstructor staleEnvironment) identity
    | throw (IO.userError "stale specialization did not preserve a complete raw plan")
  ensure (stalePlan.slots.length == 6 && psInductiveEliminationNumMinors stalePlan == 16)
    "stale specialization test stopped exercising equal-count signatures"
  expectCodecRefused environment (replace shape.declarations stale)
  ensure ((psEliminationRecursorApplication staleEnvironment probe).isNone &&
    (psReduceIota (fun value => value) staleEnvironment probe).isNone)
    "equal-count stale recursor specialization survived full telescope validation"
  let prodName := psNameAppendStr psProdName "mk"
  let some prod := psEnvironmentFindConstructor environment prodName
    | throw (IO.userError "actual checked Prod constructor absent")
  let reversed := psEnvironmentInsert environment
    (.constructorDecl { prod with recursiveFields := [1, 0] })
  ensure ((psEliminationRecursorApplication reversed probe).isNone &&
    (psReduceIota (fun value => value) reversed probe).isNone)
    "reversed two-child metadata permuted the actual nested Prod hypotheses"
  match psEncodeCheckedAdmissionsCanonicalIn reversed shape.declarations with
  | .error (.mismatchedConstructor name) =>
    ensure (psNameEq name prodName) "canonical nested order refusal named the wrong constructor"
  | _ => throw (IO.userError "canonical nested admission lost reversed real constructor metadata")
  match psElabDeriveHandler reversed origin { segments := ["Hashable"], span := origin.span } with
  | .error error =>
    ensure (refusal error == "deriving recursive field metadata is invalid")
      ("reversed nested IH refused at wrong deriving rule: " ++ refusal error)
  | .ok _ => throw (IO.userError "nested Hashable accepted reversed equal-typed child hypotheses")
  IO.println "PSCV0_M3_NESTED_REFUSALS: PASS exact signatures, specialization/order, actual container metadata, missing/duplicate auxiliaries and explicit source/deriving boundaries"

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3nestedfold", M3NestedInductiveOracle.foldOutput),
   ("m3nestedhash", M3NestedInductiveOracle.hashOutput),
   ("m3nestedmutualfold", M3NestedInductiveOracle.mutualFoldOutput),
   ("m3nestedmutualhash", M3NestedInductiveOracle.mutualHashOutput),
   ("m3nestedindexedfold", M3NestedInductiveOracle.indexedFoldOutput),
   ("m3nestedindexedhash", M3NestedInductiveOracle.indexedHashOutput),
   ("m3nesteddirect", M3NestedInductiveOracle.directOutput)]

private def witness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
  let value := PsExpr.app (.constE (psRootName name) []) argument
  let expected := call (psNameAppendStr (psRootName "UInt64") "ofNat") [] [.lit (.natural expected.toNat)]
  let proposition := call psEqName [.succ .zero] [uint64, value, expected]
  let proof := call (psNameAppendStr psEqName "refl") [.succ .zero] [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def checkPortableReduction (environment : PsEnvironment) : IO Unit := do
  for flag in [false, true] do
    for (name, oracle) in outputCases.filter (fun pair =>
        !(pair.1 == "m3nestedhash" || pair.1 == "m3nestedmutualhash" || pair.1 == "m3nestedindexedhash")) do
      let probe := PsExpr.app (.constE (psRootName name) [])
        (.constE (if flag then psBoolTrueName else psBoolFalseName) [])
      let expected := call (psNameAppendStr (psRootName "UInt64") "ofNat") []
        [.lit (.natural (oracle flag).toNat)]
      ensure (psDefEqReadOnlyWithEnv environment psMetaEmpty psLocalEmpty probe expected)
        ("portable nested fold differs from independent native traversal: " ++ name)

private def checkWorkers (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  let some group := prepared.recursorWorkerGroups.find? (fun group => group.workers.length == 6)
    | throw (IO.userError "complete six-slot nested workers were not generated")
  let names := group.workers.map psRecursorWorkerRecursorName
  ensure (psInductiveGroupNamesEqual names (["rec", "rec_1", "rec_2", "rec_3", "rec_4", "rec_5"].map
    (psNameAppendStr (psRootName "M3NestedShape"))))
    "nested workers lost canonical public/auxiliary slot order"
  let refuse := fun (candidate : PsCompilerAdmissionReadyModule) (label : String) => do
    match psCompilerVerifiedIrFromPrepared candidate with
    | .error (.erasure _) => pure ()
    | .error error => throw (IO.userError (label ++ " refused at wrong phase: " ++ psCompilerPscv0Error error))
    | .ok _ => throw (IO.userError ("nested worker metadata unexpectedly accepted: " ++ label))
  refuse { prepared with recursorWorkerGroups := [] } "missing complete worker plan"
  let changed := prepared.recursorWorkerGroups.map fun current =>
    if current.workers.length == 6 then { current with workers := current.workers.reverse } else current
  refuse { prepared with recursorWorkerGroups := changed } "reordered auxiliary workers"
  let changed := prepared.recursorWorkerGroups.map fun current =>
    if current.workers.length == 6 then
      {
        current with
        workers := current.workers.map fun worker =>
          if psNameEq (psRecursorWorkerRecursorName worker)
              (psNameAppendStr (psRootName "M3NestedShape") "rec_5") then
            { worker with recursorName := some (psNameAppendStr (psRootName "M3NestedShape") "rec_1") }
          else worker }
    else current
  refuse { prepared with recursorWorkerGroups := changed } "same-base List specialization identity"

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-nested-inductive.ps", sourceText := runtimeSource, outputStem := "nestedfold" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "nestedfold" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

end M3NestedInductive

open M3NestedInductive in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "nested qualification requires the pinned Lean"
  let (shape, shapeOrigin) ← fromExcept (elaborateGroup shapeSource)
  let (mutualGroup, mutualOrigin) ← fromExcept (elaborateGroup mutualSource)
  let (indexed, indexedOrigin) ← fromExcept (elaborateGroup indexedSource)
  let (keyGroup, _) ← fromExcept (elaborateGroup keySource)
  let (functionGroup, _) ← fromExcept (elaborateGroup
    "inductive M3FunctionNested where { | node(children: List(Nat -> M3FunctionNested)) }\n")
  let groups := shape.declarations ++ mutualGroup.declarations ++ indexed.declarations ++ functionGroup.declarations
  let input ← add psSelfHostProdPreludeEnvironment (groups ++ keyGroup.declarations)
  oneAdmission input shape.declarations 1
  oneAdmission input mutualGroup.declarations 2
  oneAdmission input indexed.declarations 1
  oneAdmission input keyGroup.declarations 1
  oneAdmission input functionGroup.declarations 1
  checkPlans input
  let origins := [shapeOrigin,
    selectedOrigin mutualOrigin (psRootName "M3NestedLeft"),
    selectedOrigin mutualOrigin (psRootName "M3NestedRight"), indexedOrigin]
  let folds ← fromExcept ((origins.mapM (fold input)).mapError psCompilerPscv0ElabError)
  -- All handlers see the same pre-instance environment. Recursive children
  -- therefore cannot obtain a dictionary for a partially generated instance.
  let derived ← fromExcept (([shapeOrigin, mutualOrigin, indexedOrigin].mapM fun origin =>
    psElabDeriveGroupHandler input origin { segments := ["Hashable"], span := origin.span }).mapError
      psCompilerPscv0ElabError)
  let instances := derived.flatten
  ensure (folds.length == 4 && instances.length == 4) "nested group did not generate each selected method"
  let methods ← add input (folds ++ instances)
  let registered ← fromExcept ((instances.foldlM (fun environment declaration =>
    psElabRegisterInstance environment (psDeclarationName declaration) 1000) methods).mapError
      psCompilerPscv0ElabError)
  let probe ← productProbe registered folds
  checkRefusals registered shape shapeOrigin probe
  let logical ← sourceResult registered logicalSource
  let runtime ← sourceResult registered runtimeSource
  checkPortableReduction runtime.result.environment
  let declarations := groups ++ folds ++ instances ++ runtime.result.declarations
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment, declarations }).mapError psCompilerPscv0Error)
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let captured ← sourceResult psSelfHostProdPreludeEnvironment capturedSource
  let some capturedInfo := psEnvironmentFindInductive captured.result.environment (psRootName "Captured")
    | throw (IO.userError "promoted nested family missing")
  let some capturedRec := psEnvironmentFindRecursor captured.result.environment
      (psNameAppendStr (psRootName "Captured") "rec")
    | throw (IO.userError "promoted nested recursor missing")
  ensure (capturedInfo.numParams == 1 && capturedInfo.numIndices == 0 &&
    capturedRec.numParams == 1 && capturedRec.numIndices == 0 &&
    capturedRec.numMotives == 2 && capturedRec.numMinors == 3)
    "promoted nested family lost the independently checked native telescope"
  let capturedAdmitted ← checked captured.result.environment prelude
    (captured.result.declarations ++ signatureWitnesses captured.result.declarations)
  kernelShapes capturedAdmitted captured.result.declarations
  IO.println "PSCV0_M3_PROMOTED_NESTED: PASS native promotion, actual parameter/nesting metadata, checked reduction and genuine constructor-local refusal"
  checkKeyKernelOracle input prelude keyGroup.declarations
  let keyAdmitted ← checked input prelude
    (keyGroup.declarations ++ signatureWitnesses keyGroup.declarations)
  kernelShapes keyAdmitted keyGroup.declarations
  let admitted ← checked runtime.result.environment prelude prepared.prepared.declarations
  let admitted ← checked runtime.result.environment admitted
    (signatureWitnesses groups ++ [reductionWitness "m3NestedProdSlotEquation" probe 3])
  kernelShapes admitted groups
  let _ ← checked logical.result.environment admitted logical.result.declarations
  -- Opaque native mixHash is checked through generic defining laws and
  -- independent runtime parity, never a fabricated closed numeric rfl proof.
  let equations := [false, true].flatMap fun flag =>
    (outputCases.filter (fun pair =>
      !(pair.1 == "m3nestedhash" || pair.1 == "m3nestedmutualhash" || pair.1 == "m3nestedindexedhash"))).map
      (fun (name, oracle) => witness name flag (oracle flag))
  let _ ← checked runtime.result.environment admitted equations
  checkWorkers prepared.prepared
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "nested fold did not emit every target"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "nested.ps") (shapeSource ++ mutualSource ++ indexedSource ++ runtimeSource)
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
  IO.println "PSCV0_M3_NESTED_INDUCTIVE: PASS complete public/nested signature witnesses, real indexed folds, canonical specialization/worker refusals, direct-child source recursion and native container Hashable policies; five-target runtime parity follows"
