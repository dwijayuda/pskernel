import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Independent ordinary Lean source. These functions use Lean's structural
-- mutual elaborator, not the portable implementation's recursor terms.
universe u
mutual
  inductive M3StructuralLeft (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | self (previous : M3StructuralLeft A a)
    | link (n : Nat) (next : M3StructuralRight A a n)
  inductive M3StructuralRight (A : Type u) (a : A) : Nat → Type u where
    | zero (previous : M3StructuralLeft A a) : M3StructuralRight A a 0
    | step (n : Nat) (previous : M3StructuralLeft A a) : M3StructuralRight A a (Nat.succ n)
end

namespace M3MutualStructuralOracle

mutual
  def first (bias n : Nat) : Nat :=
    match n with
    | 0 => bias + 3
    | k + 1 => second k (bias + 2) 5
  def second (n bias delta : Nat) : Nat :=
    match n with
    | 0 => bias + delta + 7
    | k + 1 => first (bias + delta) k
end

mutual
  def leftFirst (A : Type u) (a : A) (bias : Nat) (x : M3StructuralLeft A a) : Nat :=
    match x with
    | .leaf _ => bias + 1
    | .self previous => leftSecond A a previous (bias + 2)
    | .link n next => right A a n next (bias + 3)
  def leftSecond (A : Type u) (a : A) (x : M3StructuralLeft A a) (bias : Nat) : Nat :=
    match x with
    | .leaf _ => bias + 11
    | .self previous => leftFirst A a (bias + 4) previous
    | .link n next => right A a n next (bias + 5) + 1
  def right (A : Type u) (a : A) (n : Nat) (x : M3StructuralRight A a n) (bias : Nat) : Nat :=
    match x with
    | .zero previous => leftSecond A a previous (bias + 6)
    | .step k previous => leftFirst A a (bias + k + 7) previous
end

-- The right family owns no function here. Its actual motive is still needed.
def keep (A : Type u) (a : A) (x : M3StructuralLeft A a) : A :=
  match x with
  | .leaf value => value
  | .self previous => keep A a previous
  | .link _ _ => a

section
variable {A : Type u} [dictionary : Inhabited A] (fallback : A) (h : True)
mutual
  def pick (n : Nat) : A :=
    match n with
    | 0 => default
    | k + 1 => let _witness : True := h; pickOther k
  def pickOther (n : Nat) : A :=
    match n with
    | 0 => fallback
    | k + 1 => pick k
end
end

example : ∀ (A : Type u), Inhabited A → A → True → Nat → A := @pick
example : ∀ (A : Type u), Inhabited A → A → True → Nat → A := @pickOther

def tree (flag : Bool) : M3StructuralLeft Nat 0 :=
  if flag then .self (.link 5 (.step 4 (.self (.leaf 17))))
  else .link 0 (.zero (.self (.leaf 13)))
def firstOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (first (if flag then 7 else 13) (if flag then 3 else 4))
def secondOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (second (if flag then 3 else 4) (if flag then 17 else 11) (if flag then 2 else 4))
def leftFirstOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (leftFirst Nat 0 (if flag then 7 else 13) (tree flag))
def leftSecondOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (leftSecond Nat 0 (tree flag) (if flag then 7 else 13))
def keepOutput (flag : Bool) : UInt64 :=
  let fallback := if flag then 7 else 13
  let x : M3StructuralLeft Nat fallback :=
    if flag then .self (.leaf 17) else .self (.link 0 (.zero (.leaf 19)))
  UInt64.ofNat (keep Nat fallback x)
def genericOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (pick (if flag then 7 else 13) True.intro (if flag then 3 else 4))

example : firstOutput false = 30 := rfl
example : firstOutput true = 28 := rfl
example : secondOutput false = 36 := rfl
example : secondOutput true = 29 := rfl
example : leftFirstOutput false = 27 := rfl
example : leftFirstOutput true = 39 := rfl
example : leftSecondOutput false = 30 := rfl
example : leftSecondOutput true = 38 := rfl
example : keepOutput false = 13 := rfl
example : keepOutput true = 17 := rfl
example : genericOutput false = 0 := rfl
example : genericOutput true = 7 := rfl

end M3MutualStructuralOracle

namespace M3MutualStructural

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def groupSource : String :=
  "universe u\n" ++
  "inductive M3StructuralLeft(A: Type u, a: A): Type u where { | leaf(value: A) | self(previous: M3StructuralLeft(A, a)) | link(n: Nat, next: M3StructuralRight(A, a, n)) }\n" ++
  "inductive M3StructuralRight(B: Type u, b: B): Nat -> Type u where { | zero(previous: M3StructuralLeft(B, b)): M3StructuralRight(B, b, 0) | step(n: Nat, previous: M3StructuralLeft(B, b)): M3StructuralRight(B, b, Nat.succ(n)) }\n"

private def source : String :=
  "universe u\n" ++
  "mutual\n" ++
  "  function msFirst(bias: Nat, n: Nat): Nat := match n with { | 0 => bias + 3 | k + 1 => msSecond(k, bias + 2, 5) }\n" ++
  "  function msSecond(n: Nat, bias: Nat, delta: Nat): Nat := match n with { | 0 => bias + delta + 7 | k + 1 => msFirst(bias + delta, k) }\n" ++
  "end\n" ++
  "mutual\n" ++
  "  function msLeftFirst(A: Type u, a: A, bias: Nat, x: M3StructuralLeft(A, a)): Nat := match x with { | .leaf value => bias + 1 | .self previous => msLeftSecond(A, a, previous, bias + 2) | .link n next => msRight(A, a, n, next, bias + 3) }\n" ++
  "  function msLeftSecond(B: Type u, b: B, x: M3StructuralLeft(B, b), bias: Nat): Nat := match x with { | .leaf value => bias + 11 | .self previous => msLeftFirst(B, b, bias + 4, previous) | .link n next => msRight(B, b, n, next, bias + 5) + 1 }\n" ++
  "  function msRight(C: Type u, c: C, n: Nat, x: M3StructuralRight(C, c, n), bias: Nat): Nat := match x with { | .zero previous => msLeftSecond(C, c, previous, bias + 6) | .step k previous => msLeftFirst(C, c, bias + k + 7, previous) }\n" ++
  "end\n" ++
  "mutual\n" ++
  "  function msKeep(A: Type u, a: A, x: M3StructuralLeft(A, a)): A := match x with { | .leaf value => value | .self previous => msKeep(A, a, previous) | .link n next => a }\n" ++
  "end\n" ++
  "section\nvariable {A: Type u} [dictionary: Inhabited A] (fallback: A) (h: True)\n" ++
  "mutual\n" ++
  "  function msPick(n: Nat): A := match n with { | 0 => Inhabited.default | k + 1 => { let witness: True := h\n msPickOther(k) } }\n" ++
  "  function msPickOther(n: Nat): A := match n with { | 0 => fallback | k + 1 => msPick(k) }\n" ++
  "end\nend\n"

private def equationSource : String :=
  "universe u\n" ++
  "theorem msFirstExact(bias: Nat, n: Nat): msFirst(bias, n) = (match n with { | 0 => bias + 3 | k + 1 => msSecond(k, bias + 2, 5) }) := by { exact msFirst.eq_def(bias, n) }\n" ++
  "theorem msSecondExact(n: Nat, bias: Nat, delta: Nat): msSecond(n, bias, delta) = (match n with { | 0 => bias + delta + 7 | k + 1 => msFirst(bias + delta, k) }) := by { exact msSecond.eq_def(n, bias, delta) }\n" ++
  "theorem msRightExact(A: Type u, a: A, n: Nat, x: M3StructuralRight(A, a, n), bias: Nat): msRight(A, a, n, x, bias) = (match x with { | .zero previous => msLeftSecond(A, a, previous, bias + 6) | .step k previous => msLeftFirst(A, a, bias + k + 7, previous) }) := by { exact msRight.eq_def(A, a, n, x, bias) }\n"

private def wrappers : String :=
  "function msTree(flag: Bool): M3StructuralLeft(Nat, 0) := if (flag) { M3StructuralLeft.self(M3StructuralLeft.link(5, M3StructuralRight.step(4, M3StructuralLeft.self(M3StructuralLeft.leaf(17))))) } else { M3StructuralLeft.link(0, M3StructuralRight.zero(M3StructuralLeft.self(M3StructuralLeft.leaf(13)))) }\n" ++
  "function m3structfirst(flag: Bool): UInt64 := UInt64.ofNat(msFirst(if (flag) { 7 } else { 13 }, if (flag) { 3 } else { 4 }))\n" ++
  "function m3structsecond(flag: Bool): UInt64 := UInt64.ofNat(msSecond(if (flag) { 3 } else { 4 }, if (flag) { 17 } else { 11 }, if (flag) { 2 } else { 4 }))\n" ++
  "function m3structleftfirst(flag: Bool): UInt64 := UInt64.ofNat(msLeftFirst(Nat, 0, if (flag) { 7 } else { 13 }, msTree(flag)))\n" ++
  "function m3structleftsecond(flag: Bool): UInt64 := UInt64.ofNat(msLeftSecond(Nat, 0, msTree(flag), if (flag) { 7 } else { 13 }))\n" ++
  "function m3structkeep(flag: Bool): UInt64 := { let fallback: Nat := if (flag) { 7 } else { 13 }\n let x: M3StructuralLeft(Nat, fallback) := if (flag) { M3StructuralLeft.self(M3StructuralLeft.leaf(17)) } else { M3StructuralLeft.self(M3StructuralLeft.link(0, M3StructuralRight.zero(M3StructuralLeft.leaf(19)))) }\n UInt64.ofNat(msKeep(Nat, fallback, x)) }\n" ++
  "function m3structgeneric(flag: Bool): UInt64 := UInt64.ofNat(msPick(if (flag) { 7 } else { 13 }, True.intro, if (flag) { 3 } else { 4 }))\n"

private def outputs : List (String × (Bool → UInt64)) :=
  [("m3structfirst", M3MutualStructuralOracle.firstOutput),
   ("m3structsecond", M3MutualStructuralOracle.secondOutput),
   ("m3structleftfirst", M3MutualStructuralOracle.leftFirstOutput),
   ("m3structleftsecond", M3MutualStructuralOracle.leftSecondOutput),
   ("m3structkeep", M3MutualStructuralOracle.keepOutput),
   ("m3structgeneric", M3MutualStructuralOracle.genericOutput)]

private def elaborateGroup : Except String PsElabDeclarationBatchResult := do
  let parsed ← psPscv0ParseProgram groupSource
  let chunks ← parsed.commands.mapM fun command =>
    match command with
    | .universeCmd _ _ => pure []
    | .declaration (.inductiveDecl name params resultType constructors _) =>
      pure [{ name, params, resultType, constructors : PsElabInductiveSource }]
    | _ => throw "structural fixture expected native inductive members"
  (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks.flatten [psRootName "u"]).mapError
    psCompilerPscv0ElabError

private def elaborate (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)

private def checked (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonical declarations).mapError
    (fun _ => "canonical structural mutual admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let admitted ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (admitted.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def sameSpan (left right : PsSourceSpan) : Bool :=
  left.start.byteOffset == right.start.byteOffset && left.stop.byteOffset == right.stop.byteOffset &&
  left.start.line == right.start.line && left.stop.line == right.stop.line &&
  left.start.column == right.start.column && left.stop.column == right.stop.column

private def binderNames : PsExpr → List String
  | .forallE name _ body _ => psNameToString name :: binderNames body
  | _ => []

private def checkConstruction (compiled : PsElabModuleWithOriginsResult) : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram source)
  let groups := parsed.commands.filterMap fun command =>
    match command with | .mutualDeclarations members span => some (members, span) | _ => none
  ensure (groups.map (fun entry => entry.fst.length) == [2, 3, 1, 2])
    "structural source lost atomic function membership"
  let names := ["msFirst", "msSecond", "msLeftFirst", "msLeftSecond", "msRight", "msKeep", "msPick", "msPickOther"]
  ensure (compiled.origins.length == names.length &&
    compiled.result.declarations.length == 2 * names.length)
    "structural batch must publish one real definition and one exact equation per source member"
  let mut sourceIndex := 0
  for (members, span) in groups do
    for (member, memberIndex) in members.zipIdx do
      let some origin := compiled.origins[sourceIndex + memberIndex]?
        | throw (IO.userError "missing structural member origin")
      let some group := origin.mutualGroup
        | throw (IO.userError "structural batch discarded its full group origin")
      ensure (origin.sourceIndex == sourceIndex + memberIndex &&
        group.firstSourceIndex == sourceIndex && group.memberIndex == memberIndex &&
        group.memberCount == members.length && sameSpan group.span span &&
        sameSpan origin.span (psElabOriginSource member.declaration).snd && origin.members.length == 2)
        "structural member/group spans, source indices or equation ownership changed"
    sourceIndex := sourceIndex + members.length
  for name in names do
    let some (.definitionDecl actual levels type value) :=
        psEnvironmentFind compiled.result.environment (psRootName name)
      | throw (IO.userError "structural member is not a real total definition")
    ensure (psNameEq actual (psRootName name) && (psExprFVarIds value).isEmpty &&
      !(names.any (fun peer => psExprHasConst (psRootName peer) value)))
      "closed structural definition retained a provisional peer or recursive global"
    let some (.theoremDecl equation equationLevels _ proof) :=
        psEnvironmentFind compiled.result.environment (psNameAppendStr actual "eq_def")
      | throw (IO.userError "structural member has no checked exact source equation")
    ensure (psNameEq equation (psNameAppendStr actual "eq_def") &&
      psElabMutualLevelNamesEqual levels equationLevels && (psExprFVarIds proof).isEmpty)
      "structural equation changed its source identity, universe union or closure"
    if name == "msPick" || name == "msPickOther" then
      ensure (binderNames type == ["A", "dictionary", "fallback", "h", "n"] &&
        psElabMutualLevelNamesEqual levels [psRootName "u"])
        "structural capture lost an implicit, instance, value, proof or shared universe"
      match type with
      | .forallE _ _ (.forallE _ _ _ .instanceImplicit) .implicit => pure ()
      | _ => throw (IO.userError "structural capture changed binder kinds")
  IO.println "PSCV0_M3_MUTUAL_STRUCTURAL_CONSTRUCTION: PASS real definitions, exact equation ownership, complete source-function positions, shared all-kind capture and ordered group/member origins"

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (environment : PsEnvironment) (label text rule : String) : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  match psElabProgramWithOrigins environment parsed with
  | .ok _ => throw (IO.userError ("unexpected total-mutual acceptance: " ++ label))
  | .error error =>
    ensure ((refusal error).startsWith ("PSCV0-MUTUAL-TOTAL: " ++ rule ++ ":"))
      (label ++ " refused at the wrong rule: " ++ refusal error)

private def checkRefusals (environment : PsEnvironment) : IO Unit := do
  expectRefused environment "unconstructed total recursion"
    "mutual\nfunction bad(n: Nat): Nat := bad(n)\nend\n" "ROOT"
  expectRefused environment "unchanged recursive major"
    "mutual\nfunction bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(n) }\nend\n" "DECREASE"
  expectRefused environment "reconstructed recursive major"
    "mutual\nfunction bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => bad(Nat.succ(k)) }\nend\n" "DECREASE"
  expectRefused environment "partial peer application"
    ("function apply(f: Nat -> Nat, n: Nat): Nat := f(n)\n" ++
      "mutual\nfunction bad(n: Nat, bias: Nat): Nat := match n with { | 0 => bias | k + 1 => bias + apply(bad(k), bias) }\nend\n") "CALL-ARITY"
  expectRefused environment "changed uniform parameter"
    "mutual\nfunction bad(A: Type, xs: List(A)): Nat := match xs with { | .nil => 0 | .cons head tail => bad(Bool, List.nil) }\nend\n" "FIXED-CALL"
  expectRefused environment "incompatible motive universes"
    ("universe u\nsection\nvariable (A: Type u) (a: A)\nmutual\n" ++
      "function bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => 1 }\n" ++
      "function other(n: Nat): A := match n with { | 0 => a | k + 1 => a }\nend\nend\n") "SORT"
  expectRefused environment "function-valued recursive field"
    ("inductive M3Higher: Type where { | leaf | node(next: Nat -> M3Higher) }\n" ++
      "mutual\nfunction bad(x: M3Higher): Nat := match x with { | .leaf => 0 | .node next => bad(next(0)) }\nend\n") "DIRECT-FIELD"
  expectRefused environment "different structural groups"
    ("mutual\nfunction bad(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => 1 }\n" ++
      "function other(x: Bool): Nat := match x with { | .false => 0 | .true => 1 }\nend\n") "GROUP"
  let failed ← fromExcept (psPscv0ParseProgram
    ("mutual\nfunction atomicFirst(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => atomicSecond(k) }\n" ++
      "function atomicSecond(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => atomicSecond(n) }\nend\n"))
  match psElabProgramWithOrigins environment failed with
  | .error error =>
    ensure ((refusal error).startsWith "PSCV0-MUTUAL-TOTAL: DECREASE:")
      "late member failure lost its exact decrease refusal"
  | .ok _ => throw (IO.userError "late nondecreasing member was admitted")
  ensure ((psEnvironmentFind environment (psRootName "atomicFirst")).isNone &&
    (psEnvironmentFind environment (psRootName "atomicSecond")).isNone)
    "failed mutual construction published provisional headers"
  let repaired ← elaborate environment
    ("mutual\nfunction atomicFirst(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => atomicSecond(k) }\n" ++
      "function atomicSecond(n: Nat): Nat := match n with { | 0 => 1 | k + 1 => atomicFirst(k) }\nend\n")
  ensure (repaired.result.declarations.length == 4)
    "a failed mutual group prevented atomic reuse of its original names"
  IO.println "PSCV0_M3_MUTUAL_STRUCTURAL_REFUSALS: PASS root, strict child, complete peer arity, uniform fixed mapping, motive universe, direct-field/group and late-member atomicity boundaries"

private def witness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (psNameAppendStr psBoolName (if flag then "true" else "false")) []
  let value := PsExpr.app (.constE (psRootName name) []) argument
  let expected := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  let proposition := psExprApplyMany (.constE psEqName [.succ .zero]) [uint64, value, expected]
  let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "refl") [.succ .zero]) [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-mutual-structural.ps"
    sourceText := source ++ wrappers
    outputStem := "mutualstructural" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "mutualstructural" []
    let exposure := PsApiExposure.selected (outputs.map Prod.fst)
    let core ← PsWasm.emit checked context false exposure
    let component ← PsWasm.emit checked context true exposure
    return [js, ts, rust, core, component]
  return artifacts

end M3MutualStructural

open M3MutualStructural in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "structural mutual qualification requires the pinned Lean"
  let group ← fromExcept elaborateGroup
  let environment ← fromExcept
    ((psAddDeclarationList psSelfHostProdPreludeEnvironment group.declarations).mapError psCompilerPscv0ElabError)
  let compiled ← elaborate environment source
  checkConstruction compiled
  checkRefusals environment
  let equations ← elaborate compiled.result.environment equationSource
  let runtime ← elaborate compiled.result.environment wrappers
  let declarations := group.declarations ++ compiled.result.declarations ++ runtime.result.declarations
  let environment ← fromExcept
    ((psAddDeclarationList psSelfHostProdPreludeEnvironment declarations).mapError psCompilerPscv0ElabError)
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let admitted ← checked prelude (declarations ++ equations.result.declarations)
  let closedEquations := [false, true].flatMap fun flag =>
    outputs.map fun (name, oracle) => witness name flag (oracle flag)
  let _ ← checked admitted closedEquations
  let prepared ← fromExcept
    ((psCompilerPrepareElaboratedWithOutput { environment, declarations }).mapError psCompilerPscv0Error)
  ensure (!prepared.prepared.recursorWorkerGroups.isEmpty &&
    prepared.prepared.recursorWorkerGroups.any (fun group => group.workers.length == 2))
    "structural mutual recursion did not produce checked companion workers"
  let _ ← checked prelude prepared.prepared.declarations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "structural mutual did not emit all five targets"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "mutualstructural.ps") (source ++ wrappers)
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      outputs.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_MUTUAL_STRUCTURAL: PASS native structural oracle, fresh-kernel exact equations, multiple equal-typed functions per family, changed argument arity/order, cross-family indices, zero-owned companion at its real universe, all-kind capture and five-target emission; runtime parity follows"
