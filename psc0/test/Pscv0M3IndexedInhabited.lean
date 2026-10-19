import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Independent native constructors and defaults at the required Lean pin.
-- Result indices determine constructor fields before any defaults are chosen.
universe u

section NativeIndexedDefaults

-- An uninhabitable successor-result constructor keeps each selected index
-- genuine under the same default promotion policy used by both readers.

mutual
  inductive M3IndexedDefaultFirst (A : Type u) (a : A) : Nat → Type u where
    | mk (n : Nat) (value : A) : M3IndexedDefaultFirst A a n
    | blocked (n : Nat) (impossible : False) : M3IndexedDefaultFirst A a (Nat.succ n)
  inductive M3IndexedDefaultSecond (A : Type u) (a : A) : Nat → Type u where
    | mk (n : Nat) (parent : M3IndexedDefaultFirst A a n) :
        M3IndexedDefaultSecond A a n
    | blocked (n : Nat) (impossible : False) : M3IndexedDefaultSecond A a (Nat.succ n)
end

/-- error: failed to generate `Inhabited` instance for `M3IndexedDefaultSecond` -/
#guard_msgs (error, drop warning, substring := true) in
deriving instance Inhabited for M3IndexedDefaultSecond

deriving instance Inhabited for M3IndexedDefaultFirst, M3IndexedDefaultSecond

inductive M3IndexedDefaultDependent (A : Type u) (a : A) :
    (n : Nat) → Fin (Nat.succ n) → Type u where
  | mk (n : Nat) (point : Fin (Nat.succ n)) (value : A) :
      M3IndexedDefaultDependent A a n point
  | blocked (n : Nat) (point : Fin (Nat.succ (Nat.succ n))) (impossible : False) :
      M3IndexedDefaultDependent A a (Nat.succ n) point
  deriving Inhabited

inductive M3IndexedDefaultChoice (A : Type u) (a : A) : Nat → Type u where
  | needs (n : Nat) (value : A) : M3IndexedDefaultChoice A a n
  | empty (n : Nat) : M3IndexedDefaultChoice A a n
  | blocked (n : Nat) (impossible : False) : M3IndexedDefaultChoice A a (Nat.succ n)
  deriving Inhabited

inductive M3IndexedDefaultOnlyZero : Nat → Type where
  | zero : M3IndexedDefaultOnlyZero 0

/-- error: failed to generate `Inhabited` instance for `M3IndexedDefaultOnlyZero` -/
#guard_msgs (error, drop warning, substring := true) in
deriving instance Inhabited for M3IndexedDefaultOnlyZero

inductive M3IndexedDefaultLoop (A : Type u) (a : A) : Nat → Type u where
  | loop (n : Nat) (next : M3IndexedDefaultLoop A a n) : M3IndexedDefaultLoop A a n
  | blocked (n : Nat) (impossible : False) : M3IndexedDefaultLoop A a (Nat.succ n)

/-- error: failed to generate `Inhabited` instance for `M3IndexedDefaultLoop` -/
#guard_msgs (error, drop warning, substring := true) in
deriving instance Inhabited for M3IndexedDefaultLoop

-- Preserve the original fixed type-index program as its native positive.
inductive M3PromotedTypeDefault : Type u → Type (u + 1) where
  | mk (B : Type u) (value : B) : M3PromotedTypeDefault B
  deriving Inhabited

example {B : Type u} [Inhabited B] :
    (default : M3PromotedTypeDefault B) = M3PromotedTypeDefault.mk B default := rfl

-- B remains an index, so deriving may not invent an Inhabited B requirement.
inductive M3IndexedDefaultNoIndexInstance : Type u → Type (u + 1) where
  | mk (B : Type u) (value : B) : M3IndexedDefaultNoIndexInstance B
  | blocked (B : Type u) (impossible : False) : M3IndexedDefaultNoIndexInstance (B → B)

/-- error: failed to generate `Inhabited` instance for `M3IndexedDefaultNoIndexInstance` -/
#guard_msgs (error, drop warning, substring := true) in
deriving instance Inhabited for M3IndexedDefaultNoIndexInstance

run_cmd do
  for (name, parameters, indices) in [
      (``M3IndexedDefaultFirst, 2, 1), (``M3IndexedDefaultSecond, 2, 1),
      (``M3IndexedDefaultDependent, 2, 2), (``M3IndexedDefaultChoice, 2, 1),
      (``M3IndexedDefaultOnlyZero, 0, 1), (``M3IndexedDefaultLoop, 2, 1),
      (``M3IndexedDefaultNoIndexInstance, 0, 1), (``M3PromotedTypeDefault, 1, 0)] do
    let info ← Lean.getConstInfoInduct name
    unless info.numParams == parameters && info.numIndices == indices do
      throwError "native indexed oracle changed its parameter/index telescope: {name}: {info.numParams}/{info.numIndices}"
  Lean.logInfo "PSCV0_M3_INDEXED_NATIVE: PASS exact declared parameter/index telescopes, including the uninhabited type index"

end NativeIndexedDefaults

namespace M3IndexedInhabitedOracle

example {A : Type u} [Inhabited A] (a : A) (n : Nat) :
    (default : M3IndexedDefaultFirst A a n) = .mk n default := rfl

example {A : Type u} [Inhabited A] (a : A) (n : Nat) :
    (default : M3IndexedDefaultSecond A a n) = .mk n (.mk n default) := rfl

example {A : Type u} [Inhabited A] (a : A) (n : Nat) (point : Fin (Nat.succ n)) :
    (default : M3IndexedDefaultDependent A a n point) = .mk n point default := rfl

-- The later constructor wins in the pass with no added parameter assumptions.
example {A : Type u} (a : A) (n : Nat) :
    (default : M3IndexedDefaultChoice A a n) = .empty n := rfl

-- Match a generalized index telescope, inspecting the actual constructor
-- fields of the native derived value before choosing the scalar observation.
private def firstScore : (n : Nat) → M3IndexedDefaultFirst Nat 0 n → Nat
  | _, .mk k item => 3 * k + item
  | _, .blocked _ impossible => False.elim impossible

private def parentScore : (n : Nat) → M3IndexedDefaultFirst Nat 0 n → Nat
  | _, .mk m item => 2 * m + item
  | _, .blocked _ impossible => False.elim impossible

private def secondScore : (n : Nat) → M3IndexedDefaultSecond Nat 0 n → Nat
  | _, .mk k parent => k + parentScore k parent
  | _, .blocked _ impossible => False.elim impossible

private def dependentScore :
    (n : Nat) → (point : Fin (Nat.succ n)) →
      M3IndexedDefaultDependent Nat 0 n point → Nat
  | _, _, .mk k selected item => k + 2 * selected.val + item
  | _, _, .blocked _ _ impossible => False.elim impossible

private def choiceScore : (n : Nat) → M3IndexedDefaultChoice Nat 0 n → Nat
  | _, .needs k item => 1000 + k + item
  | _, .empty k => k + 5
  | _, .blocked _ impossible => False.elim impossible

def firstOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let value : M3IndexedDefaultFirst Nat 0 n :=
    letI : Inhabited Nat := ⟨n + 7⟩
    default
  UInt64.ofNat (firstScore n value)

def secondOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let value : M3IndexedDefaultSecond Nat 0 n :=
    letI : Inhabited Nat := ⟨n + 11⟩
    default
  UInt64.ofNat (secondScore n value)

def dependentOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let point : Fin (Nat.succ n) := ⟨n, Nat.lt_succ_self n⟩
  let value : M3IndexedDefaultDependent Nat 0 n point :=
    letI : Inhabited Nat := ⟨n + 13⟩
    default
  UInt64.ofNat (dependentScore n point value)

def choiceOutput (flag : Bool) : UInt64 :=
  let n := if flag then 43 else 17
  let value : M3IndexedDefaultChoice Nat 0 n := default
  UInt64.ofNat (choiceScore n value)

end M3IndexedInhabitedOracle

namespace M3IndexedInhabited

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def groupSource : String :=
  "universe u\n" ++
  "inductive M3IndexedDefaultFirst(A: Type u, a: A): Nat -> Type u where { | mk(n: Nat, value: A): M3IndexedDefaultFirst(A, a, n) | blocked(n: Nat, impossible: False): M3IndexedDefaultFirst(A, a, Nat.succ(n)) }\n" ++
  "inductive M3IndexedDefaultSecond(B: Type u, b: B): Nat -> Type u where { | mk(n: Nat, parent: M3IndexedDefaultFirst(B, b, n)): M3IndexedDefaultSecond(B, b, n) | blocked(n: Nat, impossible: False): M3IndexedDefaultSecond(B, b, Nat.succ(n)) }\n"

private def dependentSource : String :=
  "universe u\n" ++
  "inductive M3IndexedDefaultDependent(A: Type u, a: A): (n: Nat) -> Fin(Nat.succ(n)) -> Type u where { | mk(n: Nat, point: Fin(Nat.succ(n)), value: A): M3IndexedDefaultDependent(A, a, n, point) | blocked(n: Nat, point: Fin(Nat.succ(Nat.succ(n))), impossible: False): M3IndexedDefaultDependent(A, a, Nat.succ(n), point) }\n"

private def choiceSource : String :=
  "universe u\n" ++
  "inductive M3IndexedDefaultChoice(A: Type u, a: A): Nat -> Type u where { | needs(n: Nat, value: A): M3IndexedDefaultChoice(A, a, n) | empty(n: Nat): M3IndexedDefaultChoice(A, a, n) | blocked(n: Nat, impossible: False): M3IndexedDefaultChoice(A, a, Nat.succ(n)) }\n"

private def promotedSource : String :=
  "universe u\ninductive M3PromotedTypeDefault: Type u -> Type (u + 1) where {\n  | mk(B: Type u, value: B): M3PromotedTypeDefault(B)\n} deriving Inhabited\nsection\nvariable {B: Type u} [dictionary: Inhabited B]\ntheorem m3PromotedTypeDefaultEquation:\n  (Inhabited.default: M3PromotedTypeDefault(B)) =\n    M3PromotedTypeDefault.mk(B, Inhabited.default) := by { rfl }\nend\n"

private def logicalSource : String :=
  "universe u\n" ++
  "section\nvariable {A: Type u} [dictionary: Inhabited A]\n" ++
  "function m3IndexedFirstValue(a: A, n: Nat): M3IndexedDefaultFirst(A, a, n) := Inhabited.default\n" ++
  "function m3IndexedSecondValue(a: A, n: Nat): M3IndexedDefaultSecond(A, a, n) := Inhabited.default\n" ++
  "function m3IndexedDependentValue(a: A, n: Nat, point: Fin(Nat.succ(n))): M3IndexedDefaultDependent(A, a, n, point) := Inhabited.default\n" ++
  "theorem m3IndexedFirstEquation(a: A, n: Nat): m3IndexedFirstValue(a, n, A := A) = M3IndexedDefaultFirst.mk(n, Inhabited.default) := by { rfl }\n" ++
  "theorem m3IndexedSecondEquation(a: A, n: Nat): m3IndexedSecondValue(a, n, A := A) = M3IndexedDefaultSecond.mk(n, M3IndexedDefaultFirst.mk(n, Inhabited.default)) := by { rfl }\n" ++
  "theorem m3IndexedDependentEquation(a: A, n: Nat, point: Fin(Nat.succ(n))): m3IndexedDependentValue(a, n, point, A := A) = M3IndexedDefaultDependent.mk(n, point, Inhabited.default) := by { rfl }\n" ++
  "end\n" ++
  "function m3IndexedChoiceValue(A: Type u, a: A, n: Nat): M3IndexedDefaultChoice(A, a, n) := Inhabited.default\n" ++
  "theorem m3IndexedChoiceEquation(A: Type u, a: A, n: Nat): m3IndexedChoiceValue(A, a, n) = M3IndexedDefaultChoice.empty(n) := by { rfl }\n"

private def runtimeSource : String :=
  "function m3indexedfirst(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let value: M3IndexedDefaultFirst(Nat, 0, n) := m3IndexedFirstWith(n, n + 7)\n" ++
  " let score: Nat := match value with { | M3IndexedDefaultFirst.mk k item => 3 * k + item | M3IndexedDefaultFirst.blocked _ impossible => False.elim(impossible) }\n" ++
  " UInt64.ofNat(score)\n}\n" ++
  "function m3indexedsecond(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let value: M3IndexedDefaultSecond(Nat, 0, n) := m3IndexedSecondWith(n, n + 11)\n" ++
  " let score: Nat := match value with { | M3IndexedDefaultSecond.mk k parent => match parent with { | M3IndexedDefaultFirst.mk m item => k + 2 * m + item | M3IndexedDefaultFirst.blocked _ impossible => False.elim(impossible) } | M3IndexedDefaultSecond.blocked _ impossible => False.elim(impossible) }\n" ++
  " UInt64.ofNat(score)\n}\n" ++
  "function m3indexeddependent(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let point: Fin(Nat.succ(n)) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
  " let value: M3IndexedDefaultDependent(Nat, 0, n, point) := m3IndexedDependentWith(n, point, n + 13)\n" ++
  " let score: Nat := match value with { | M3IndexedDefaultDependent.mk k selected item => k + 2 * selected.val + item | M3IndexedDefaultDependent.blocked _ _ impossible => False.elim(impossible) }\n" ++
  " UInt64.ofNat(score)\n}\n" ++
  "function m3indexedchoice(flag: Bool): UInt64 := {\n" ++
  " let n: Nat := if (flag) { 43 } else { 17 }\n" ++
  " let value: M3IndexedDefaultChoice(Nat, 0, n) := Inhabited.default\n" ++
  " let score: Nat := match value with { | M3IndexedDefaultChoice.needs k item => 1000 + k + item | M3IndexedDefaultChoice.empty k => k + 5 | M3IndexedDefaultChoice.blocked _ impossible => False.elim(impossible) }\n" ++
  " UInt64.ofNat(score)\n}\n"

private def elaborateGroup (text : String) (levelNames : List PsName := [psRootName "u"]) :
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
    | _ => throw "indexed default fixture expected inductive members"
  let first :: _ := sources | throw "indexed default fixture has no inductive source"
  let result ← (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks levelNames).mapError
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

private def derive (environment : PsEnvironment) (origin : PsElabBatchOrigin) : IO (List PsDeclaration) :=
  fromExcept ((psElabDeriveGroupHandler environment origin
    { segments := ["Inhabited"], span := origin.span }).mapError psCompilerPscv0ElabError)

private def sourceResult (environment : PsEnvironment) (text : String) :
    IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)

private def call (name : PsName) (levels : List PsLevel) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (.constE name levels) arguments

-- Pass a runtime-provided field dictionary to the actual generated instance.
-- Constructor fields and indices are never reconstructed by these adapters.
private def requiredAdapter (familyName outputName : String) (dependent : Bool := false) : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let index := PsExpr.fvar 0
  let point := PsExpr.fvar 1
  let payloadId := if dependent then 2 else 1
  let indices := if dependent then [index, point] else [index]
  let family := call (psRootName familyName) [.zero] ([nat, .lit (.natural 0)] ++ indices)
  let dictionary := psStandardInhabitedValue nat (.fvar payloadId)
  let derived := call (psNameAppendStr (psRootName familyName) "instInhabited") [.zero]
    ([nat, .lit (.natural 0)] ++ indices ++ [dictionary])
  let value := psStandardInhabitedDefault (.succ .zero) family derived
  let type := psLogicPi payloadId "payload" nat family
  let value := psLogicLam payloadId "payload" nat value
  let pointType := call (psRootName "Fin") [] [.app (.constE psNatSuccName []) index]
  let type := if dependent then psLogicPi 1 "point" pointType type else type
  let value := if dependent then psLogicLam 1 "point" pointType value else value
  .definitionDecl (psRootName outputName) [] (psLogicPi 0 "n" nat type)
    (psLogicLam 0 "n" nat value)

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .data message => message
  | error => psCompilerPscv0ElabError error

private def expectRefused (label : String) (result : Except PsElabError α) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected indexed default acceptance: " ++ label))
  | .error error =>
    ensure (refusal error == "Inhabited deriving requires a constructor with inhabitable fields")
      (label ++ " refused at the wrong owner: " ++ refusal error)

private def checkRefusals (environment : PsEnvironment) (origin : PsElabBatchOrigin) : IO Unit := do
  let later := origin.members.filter fun member =>
    match member.role with
    | .inductiveType => psNameEq member.name (psRootName "M3IndexedDefaultSecond")
    | _ => true
  expectRefused "later indexed group default before the earlier dictionary"
    (psElabDeriveHandler environment { origin with members := later }
      { segments := ["Inhabited"], span := origin.span })
  for (label, text, levels) in [
      ("zero-only constructor cannot supply all rigid indices",
        "inductive M3IndexedDefaultOnlyZero: Nat -> Type where { | zero: M3IndexedDefaultOnlyZero(0) }\n", []),
      ("unseeded indexed recursion",
        "universe u\ninductive M3IndexedDefaultLoop(A: Type u, a: A): Nat -> Type u where { | loop(n: Nat, next: M3IndexedDefaultLoop(A, a, n)): M3IndexedDefaultLoop(A, a, n) | blocked(n: Nat, impossible: False): M3IndexedDefaultLoop(A, a, Nat.succ(n)) }\n", [psRootName "u"]),
      ("a type index does not acquire an Inhabited requirement",
        "universe u\ninductive M3IndexedDefaultNoIndexInstance: Type u -> Type (u + 1) where { | mk(B: Type u, value: B): M3IndexedDefaultNoIndexInstance(B) | blocked(B: Type u, impossible: False): M3IndexedDefaultNoIndexInstance(B -> B) }\n", [psRootName "u"])] do
    let (group, refusedOrigin) ← fromExcept (elaborateGroup text levels)
    let input ← add environment group.declarations
    expectRefused label (psElabDeriveGroupHandler input refusedOrigin
      { segments := ["Inhabited"], span := refusedOrigin.span })

private def checkRequirements (environment : PsEnvironment)
    (declarations : List PsDeclaration) : IO Unit := do
  for (family, indexCount, count) in [
      ("M3IndexedDefaultFirst", 1, 1), ("M3IndexedDefaultSecond", 1, 1),
      ("M3IndexedDefaultDependent", 2, 1), ("M3IndexedDefaultChoice", 1, 0)] do
    let name := psNameAppendStr (psRootName family) "instInhabited"
    let some declaration := declarations.find? (fun item => psNameEq (psDeclarationName item) name)
      | throw (IO.userError "indexed default instance is absent")
    ensure (!psExprHasUnresolvedMeta (psDeclarationType declaration) &&
      (psExprFVarIds (psDeclarationType declaration)).isEmpty)
      ("indexed default retained a metavariable or free local: " ++ family)
    let opened ← fromExcept ((psElabOpenCoreTelescope 4096
      (psElabContextEmpty environment [psRootName "u"]) (psDeclarationType declaration)
        (some (2 + indexCount + count))).mapError psCompilerPscv0ElabError)
    let requirements := opened.bindersRev.filter (fun binder => psBinderInfoIsInstance binder.binder)
    ensure (requirements.length == count && opened.bindersRev.length == 2 + indexCount + count)
      ("indexed default acquired an index or value parameter requirement: " ++ family)
    let view := psExprAppView opened.body
    let .constE className _ := view.head
      | throw (IO.userError "indexed instance has an extra binder before its class result")
    ensure (psNameEq className (psRootName "Inhabited")) "indexed instance lost its class result"
    if count == 1 then
      let some parameter := opened.bindersRev.reverse[0]?
        | throw (IO.userError "indexed instance lost its uniform type parameter")
      let [requirement] := requirements | throw (IO.userError "indexed requirement count changed")
      let view := psExprAppView requirement.type
      let .constE requirementClass _ := view.head
        | throw (IO.userError "indexed requirement is not a class application")
      let [argument] := view.args | throw (IO.userError "indexed requirement is not unary")
      ensure (psNameEq requirementClass className && psExprAlphaEq argument (.fvar parameter.id))
        ("indexed default retained the wrong dictionary: " ++ family)
  let earlier := psNameAppendStr (psRootName "M3IndexedDefaultFirst") "instInhabited"
  let later := psNameAppendStr (psRootName "M3IndexedDefaultSecond") "instInhabited"
  let some (.definitionDecl _ _ _ value) := declarations.find?
      (fun declaration => psNameEq (psDeclarationName declaration) later)
    | throw (IO.userError "later indexed default is not an ordinary definition")
  ensure (psExprHasConst earlier value && !psExprHasConst later value)
    "later indexed default did not use the actual earlier registered instance"

private def checked (environment : PsEnvironment) (prelude : Lean.Kernel.Environment)
    (declarations : List PsDeclaration) : IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonicalIn environment declarations).mapError
    (fun _ => "canonical indexed default admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def signatureWitnesses (declarations : List PsDeclaration) : List PsDeclaration :=
  declarations.filterMap fun declaration =>
    match declaration with
    | .recursorDecl info => some (.definitionDecl
      (psNameAppendStr info.name "_indexedDefaultSignature") info.levelParams info.type
      (.constE info.name (info.levelParams.map PsLevel.param)))
    | _ => none

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3indexedfirst", M3IndexedInhabitedOracle.firstOutput),
   ("m3indexedsecond", M3IndexedInhabitedOracle.secondOutput),
   ("m3indexeddependent", M3IndexedInhabitedOracle.dependentOutput),
   ("m3indexedchoice", M3IndexedInhabitedOracle.choiceOutput)]

private def outputWitness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (if flag then psBoolTrueName else psBoolFalseName) []
  let left := PsExpr.app (.constE (psRootName name) []) argument
  let right := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation"))) []
    (psLogicEq (.succ .zero) uint64 left right) (psLogicRefl (.succ .zero) uint64 right)

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-indexed-inhabited.ps", sourceText := runtimeSource, outputStem := "indexedinhabited" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "indexedinhabited" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

def check (directory : String) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "indexed defaults require the pinned Lean"
  let (group, origin) ← fromExcept (elaborateGroup groupSource)
  let (dependent, dependentOrigin) ← fromExcept (elaborateGroup dependentSource)
  let (choice, choiceOrigin) ← fromExcept (elaborateGroup choiceSource)
  let groups := group.declarations ++ dependent.declarations ++ choice.declarations
  let input ← add psSelfHostProdPreludeEnvironment groups
  for (family, indices) in [("M3IndexedDefaultFirst", 1), ("M3IndexedDefaultSecond", 1),
      ("M3IndexedDefaultDependent", 2), ("M3IndexedDefaultChoice", 1)] do
    let some info := psEnvironmentFindInductive input (psRootName family)
      | throw (IO.userError ("indexed default family missing: " ++ family))
    ensure (info.numParams == 2 && info.numIndices == indices)
      ("indexed default fixture lost its actual index telescope: " ++ family)
  checkRefusals input origin
  let groupInstances ← derive input origin
  let dependentInstances ← derive input dependentOrigin
  let choiceInstances ← derive input choiceOrigin
  let instances := groupInstances ++ dependentInstances ++ choiceInstances
  ensure (instances.length == 4) "indexed defaults did not generate every requested instance"
  checkRequirements input instances
  let registered ← register input instances
  let adapters := [
    requiredAdapter "M3IndexedDefaultFirst" "m3IndexedFirstWith",
    requiredAdapter "M3IndexedDefaultSecond" "m3IndexedSecondWith",
    requiredAdapter "M3IndexedDefaultDependent" "m3IndexedDependentWith" true]
  let adapted ← add registered adapters
  let runtime ← sourceResult adapted runtimeSource
  let logical ← sourceResult runtime.result.environment logicalSource
  let declarations := groups ++ instances ++ adapters ++ runtime.result.declarations
  let prepared ← fromExcept ((psCompilerPrepareElaboratedWithOutput
    { environment := runtime.result.environment, declarations }).mapError psCompilerPscv0Error)
  ensure prepared.prepared.recursorWorkerGroups.isEmpty
    "constructor defaults or ordinary case inspection introduced recursive workers"
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let promoted ← sourceResult psSelfHostProdPreludeEnvironment promotedSource
  let some promotedInfo := psEnvironmentFindInductive promoted.result.environment
      (psRootName "M3PromotedTypeDefault")
    | throw (IO.userError "promoted type default family missing")
  ensure (promotedInfo.numParams == 1 && promotedInfo.numIndices == 0)
    "fixed type index did not promote before deriving its real Inhabited requirement"
  let _ ← checked promoted.result.environment prelude promoted.result.declarations
  let admitted ← checked runtime.result.environment prelude prepared.prepared.declarations
  let signatures := signatureWitnesses groups
  ensure (signatures.length == 4) "indexed defaults lost a complete public group recursor signature"
  let admitted ← checked runtime.result.environment admitted signatures
  let _ ← checked logical.result.environment admitted logical.result.declarations
  let equations := [false, true].flatMap fun flag =>
    outputCases.map (fun (name, oracle) => outputWitness name flag (oracle flag))
  let _ ← checked runtime.result.environment admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "indexed default fixture did not emit every target"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "deriving.ps") (groupSource ++ dependentSource ++ choiceSource ++ runtimeSource)
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
  IO.println "PSCV0_M3_INDEXED_INHABITED: PASS native constructor-result inference before defaults, dependent index telescope, ordered group dictionaries, parameter-only requirements, exact refusals and complete checked recursor signatures; five-target parity follows"

end M3IndexedInhabited

