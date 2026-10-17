import Ps.Host.NativeV7
import PsKernelLean.Admission
import Lean.Util.CollectAxioms

namespace M3PartialFixpointOracle

def countdown (seed n : Nat) : Nat :=
  match n with
  | 0 => seed
  | k + 1 => countdown seed k
partial_fixpoint

def optionCountdown (seed n : Nat) : Option Nat :=
  match n with
  | 0 => some seed
  | k + 1 => optionCountdown seed k
partial_fixpoint

mutual
  def left (n : Nat) : Nat :=
    match n with
    | 0 => 23
    | k + 1 => right k
  partial_fixpoint
  def right (n : Nat) : Nat :=
    match n with
    | 0 => 41
    | k + 1 => left k
  partial_fixpoint
end

theorem countdownEquation (seed n : Nat) :
    countdown seed n = (match n with | 0 => seed | k + 1 => countdown seed k) :=
  countdown.eq_def seed n

theorem optionEquation (seed n : Nat) :
    optionCountdown seed n =
      (match n with | 0 => some seed | k + 1 => optionCountdown seed k) :=
  optionCountdown.eq_def seed n

theorem leftEquation (n : Nat) :
    left n = (match n with | 0 => 23 | k + 1 => right k) :=
  left.eq_def n

theorem rightEquation (n : Nat) :
    right n = (match n with | 0 => 41 | k + 1 => left k) :=
  right.eq_def n

def countdownOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (countdown (if flag then 17 else 29) (if flag then 4 else 3))

def optionOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (match optionCountdown (if flag then 37 else 43) (if flag then 3 else 4) with
    | none => 997
    | some value => value + 5)

def mutualOutput (flag : Bool) : UInt64 :=
  let n := if flag then 2 else 3
  UInt64.ofNat (100 * left n + right n)

-- These exact source shapes used to be refused only by the two-axiom policy.
-- They are logical-only sentinels. Never evaluate either divergent function.
mutual
  def first (n : Nat) : Nat := first n
  partial_fixpoint
end

def bad (n : Nat) : Nat := helper n
where
  helper (k : Nat) : Nat := helper k
  partial_fixpoint

/-- error: Could not prove -/
#guard_msgs (error, drop warning, substring := true) in
def nonMonotone (n : Nat) : Nat := nonMonotone n + 1
partial_fixpoint

run_cmd do
  let environment ← Lean.getEnv
  for name in [``countdown, ``optionCountdown, ``left, ``right, ``first, ``bad] do
    match environment.find? name with
    | some (.defnInfo _) => pure ()
    | _ => throwError "native P1 source did not produce a checked definition: {name}"
  for name in [``countdown, ``optionCountdown, ``left, ``right,
      ``countdownEquation, ``optionEquation, ``leftEquation, ``rightEquation,
      ``first, ``bad] do
    let axioms ← Lean.collectAxioms name
    unless axioms.contains ``Classical.choice &&
        axioms.all (fun axiomName => axiomName == ``propext ||
          axiomName == ``Quot.sound || axiomName == ``Classical.choice) do
      throwError "native P1 assumption closure changed: {name}: {axioms}"
  Lean.logInfo "PSCV0_M3_P1_NATIVE: PASS checked fixpoint definitions and exact unfolding equations, three-axiom closure, retained logical-only source shapes and nonmonotone refusal"

end M3PartialFixpointOracle

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def elaborate (text : String) : IO PsElabModuleWithOriginsResult := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed).mapError
    psCompilerPscv0ElabError)

private def definitionsSource : String :=
  "function p1Countdown(seed: Nat, n: Nat): Nat := match n with { | 0 => seed | k + 1 => p1Countdown(seed, k) }\npartial_fixpoint\n" ++
  "function p1Option(seed: Nat, n: Nat): Option(Nat) := match n with { | 0 => Option.some(seed) | k + 1 => p1Option(seed, k) }\npartial_fixpoint\n" ++
  "mutual\n" ++
  "function p1Left(n: Nat): Nat := match n with { | 0 => 23 | k + 1 => p1Right(k) }\npartial_fixpoint\n" ++
  "function p1Right(n: Nat): Nat := match n with { | 0 => 41 | k + 1 => p1Left(k) }\npartial_fixpoint\n" ++
  "end\n"

private def source : String :=
  definitionsSource ++
  "function m3p1countdown(flag: Bool): UInt64 := UInt64.ofNat(p1Countdown(if (flag) { 17 } else { 29 }, if (flag) { 4 } else { 3 }))\n" ++
  "function m3p1option(flag: Bool): UInt64 := UInt64.ofNat(match p1Option(if (flag) { 37 } else { 43 }, if (flag) { 3 } else { 4 }) with { | Option.none => 997 | Option.some(value) => value + 5 })\n" ++
  "function m3p1mutual(flag: Bool): UInt64 := {\n let n: Nat := if (flag) { 2 } else { 3 }\n UInt64.ofNat(100 * p1Left(n) + p1Right(n)) }\n"

-- Byte-identical to the former P0 and Where policy-refusal requests.
private def logicalOnlySources : List (String × String) :=
  [("former-p1-assumption-refused",
    "mutual\nfunction first(n: Nat): Nat := first(n)\npartial_fixpoint\nend\n"),
   ("former-local-fixedpoint-policy",
    "function bad(n: Nat): Nat := helper(n)\nwhere { def helper(k: Nat): Nat := helper(k) partial_fixpoint }\n")]

private def exports : List (String × (Bool → UInt64)) :=
  [("m3p1countdown", M3PartialFixpointOracle.countdownOutput),
   ("m3p1option", M3PartialFixpointOracle.optionOutput),
   ("m3p1mutual", M3PartialFixpointOracle.mutualOutput)]

private def binderNames : PsExpr → List String
  | .forallE name _ body _ => psNameToString name :: binderNames body
  | _ => []

private def orderName (suffix : String) : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "Lean") "Order") suffix

private def project (path : List Nat) (value : PsExpr) : PsExpr :=
  path.foldl (fun value index => .proj (psRootName "PProd") index value) value

-- Use the actual official provider, including its normal canonical decoder,
-- definition heights and fresh finite kernel budget. This has no runtime path.
private def checkOfficial (prelude : Lean.Kernel.Environment)
    (prepared : PsCompilerAdmissionReadyModule) (label : String) : IO Unit := do
  let admissions ← fromExcept ((psCompilerAdmissionsFromPrepared prepared).mapError
    psCompilerPscv0Error)
  let declarations ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions admissions).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    (do
      let mut environment := prelude
      for original in declarations do
        let declaration := PsKernelLean.psKernelWithDefinitionHeight environment original
        match environment.addDeclCore 2000000 20000 declaration none with
        | .ok next => environment := next
        | .error error =>
          throw ("official P1 kernel rejected " ++ label ++ ": " ++
            PsKernelLean.kernelExceptionSummary error ++ PsKernelLean.kernelExceptionContext error)
      pure () : Except String Unit)
  fromExcept checked
  IO.println ("PSCV0_M3_P1_KERNEL: PASS " ++ label ++
    " kernel-heartbeat-limit=2000000 recursion-limit=20000")

private def expectRuntimeRefusal (declarations : List PsDeclaration)
    (expected : String) : IO Unit := do
  match psCompilerOrdinaryPartialRuntimeDeclarations declarations with
  | .error (.normalization message) =>
    ensure (message == expected) ("P1 runtime refusal changed: " ++ message)
  | _ => throw (IO.userError "malformed P1 runtime graph acquired an adapter result")

private def checkConstruction (prelude : Lean.Kernel.Environment) :
    IO PsCompilerAdmissionReadyModule := do
  let compiled ← elaborate definitionsSource
  let declarations := compiled.result.declarations
  let environment := compiled.result.environment
  ensure ((declarations.filter (fun declaration =>
    match declaration with | .partialDecl .. => true | _ => false)).length == 4)
    "P1 source lost one of its four actual implementation bodies"
  let members : List (String × List String × String × List Nat) :=
    [("p1Countdown", ["seed", "n"], "p1Countdown", []),
     ("p1Option", ["seed", "n"], "p1Option", []),
     ("p1Left", ["n"], "p1Left", [0]),
     ("p1Right", ["n"], "p1Left", [1])]
  let auxiliaries := ["p1Countdown", "p1Option", "p1Left"].map fun name =>
    PsName.num (psRootName name) 1
  for (text, headers, auxiliaryOwner, path) in members do
    let name := psRootName text
    let auxiliary := PsName.num (psRootName auxiliaryOwner) 1
    let implementationName := PsName.num name 0
    let wholeName := PsName.num name 2
    let sourceEquationName := psNameAppendStr name "eq_def"
    let some (.definitionDecl _ levels type value) := psEnvironmentFind environment name
      | throw (IO.userError "P1 public member is not a checked definition")
    let some (.partialDecl _ bodyLevels bodyType body) :=
        psEnvironmentFind environment implementationName
      | throw (IO.userError "P1 source body marker is missing")
    ensure (levels.isEmpty && psElabMutualLevelNamesEqual levels bodyLevels &&
      psExprAlphaEq type bodyType && binderNames type == headers &&
      psExprAlphaEq value (project path (.constE auxiliary [])) &&
      !psExprHasUnresolvedMeta body && (psExprFVarIds body).isEmpty)
      "P1 public projection, source header, actual body or closed universe list changed"
    let some (.theoremDecl _ wholeLevels wholeType wholeProof) :=
        psEnvironmentFind environment wholeName
      | throw (IO.userError "P1 whole-function equation is missing")
    let whole := psReduceAppView wholeType
    let .constE wholeHead [_] := whole.head
      | throw (IO.userError "P1 whole-function equation head changed")
    let [wholeDomain, wholeLeft, wholeRight] := whole.args
      | throw (IO.userError "P1 whole-function equation arity changed")
    ensure (psNameEq wholeHead (psRootName "Eq") &&
      psElabMutualLevelNamesEqual levels wholeLevels &&
      psExprAlphaEq wholeDomain type && psExprAlphaEq wholeLeft (.constE name []) &&
      psExprAlphaEq wholeRight body && !psExprHasUnresolvedMeta wholeProof &&
      (psExprFVarIds wholeProof).isEmpty)
      "P1 whole equation does not state the exact retained source body"
    let some (.theoremDecl _ sourceLevels sourceType sourceProof) :=
        psEnvironmentFind environment sourceEquationName
      | throw (IO.userError "P1 public source equation is missing")
    ensure (psElabMutualLevelNamesEqual levels sourceLevels &&
      binderNames sourceType == headers && !psExprHasUnresolvedMeta sourceProof &&
      (psExprFVarIds sourceProof).isEmpty)
      "P1 eq_def changed its actual header or retained an unresolved proof"
    let opened ← fromExcept ((psElabPreDefinitionOpen headers.length
      (psElabContextEmpty environment levels) sourceType sourceProof).mapError
      psCompilerPscv0ElabError)
    let equation := psReduceAppView opened.type
    let [_domain, left, right] := equation.args
      | throw (IO.userError "opened P1 source equation is not a binary equality")
    let arguments := psElabBinderArguments opened.bindersRev
    let some sourceBody := psRecursorLiftBetaApply body arguments
      | throw (IO.userError "retained P1 body lost a source-header lambda")
    ensure (psExprAlphaEq left (psExprApplyMany (.constE name []) arguments) &&
      psExprAlphaEq right sourceBody)
      "P1 eq_def does not compare the public application to its exact source RHS"
    ensure (compiled.privateNames.any (psNameEq auxiliary) &&
      compiled.privateNames.any (psNameEq implementationName) &&
      compiled.privateNames.any (psNameEq wholeName) &&
      !(compiled.privateNames.any (psNameEq name)) &&
      compiled.privateNames.any (psNameEq sourceEquationName))
      "P1 reserved helper or source-equation visibility changed"
    let owners := compiled.origins.filter (fun origin =>
      origin.members.any (fun member => psNameEq member.name implementationName))
    ensure (owners.length == 1 && owners.all (fun origin =>
      [name, implementationName, wholeName, sourceEquationName].all (fun expected =>
        origin.members.any (fun member => psNameEq member.name expected))))
      "P1 source member lost its exact definition/equation/body provenance"
  for auxiliary in auxiliaries do
    let some (.definitionDecl _ levels type value) := psEnvironmentFind environment auxiliary
      | throw (IO.userError "P1 common auxiliary is not a checked definition")
    let fixed := psReduceAppView value
    let .constE name [_] := fixed.head
      | throw (IO.userError "P1 auxiliary lost its canonical fix head")
    let [carrier, _order, functional, _monotonicity] := fixed.args
      | throw (IO.userError "P1 fix does not have four checked arguments")
    let .lam _ domain _ .explicit := functional
      | throw (IO.userError "P1 functional is not a closed explicit lambda")
    ensure (psNameEq name (orderName "fix") && levels.isEmpty &&
      psExprAlphaEq carrier type && psExprAlphaEq domain type &&
      !psExprHasUnresolvedMeta value && (psExprFVarIds value).isEmpty &&
      !(members.any (fun member => psExprHasConst (psRootName member.1) functional)))
      "P1 auxiliary contains an unowned peer, wrong carrier or unresolved proof"
  let output ← fromExcept ((psCompilerPrepareElaboratedWithOutput compiled.result).mapError
    psCompilerPscv0Error)
  let prepared := output.prepared
  checkOfficial prelude prepared "four-source-members-three-components"
  let runtime ← fromExcept ((psCompilerOrdinaryPartialRuntimeDeclarations
    prepared.declarations).mapError psCompilerPscv0Error)
  ensure (!(runtime.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false)) &&
    !(runtime.any (fun declaration =>
      auxiliaries.any (psNameEq (psDeclarationName declaration)))))
    "P1 runtime view retained a logical fix auxiliary or private body marker"
  for (text, _, _, _) in members do
    let name := psRootName text
    let some (.partialDecl _ _ type body) := prepared.declarations.find? (fun declaration =>
      psNameEq (psDeclarationName declaration) (PsName.num name 0))
      | throw (IO.userError "prepared P1 source body is missing")
    let some (.definitionDecl _ _ runtimeType runtimeBody) := runtime.find? (fun declaration =>
      psNameEq (psDeclarationName declaration) name)
      | throw (IO.userError "P1 runtime view omitted a public entry")
    ensure (psExprAlphaEq type runtimeType && psExprAlphaEq body runtimeBody)
      "P1 runtime entry does not contain its actual retained source body"
  IO.println "PSCV0_M3_P1_CONSTRUCTION: PASS four source members, three actual fix auxiliaries, common PProd projections, complete checked whole/source equations, private ownership and exact runtime-body substitution"
  return prepared

private def checkAdapterNegatives (prelude : Lean.Kernel.Environment)
    (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  let name := psRootName "p1Countdown"
  let auxiliary := PsName.num name 1
  let implementationName := PsName.num name 0
  let wholeName := PsName.num name 2
  let sourceEquationName := psNameAppendStr name "eq_def"
  let some (.partialDecl _ levels type _) := prepared.declarations.find? (fun declaration =>
    psNameEq (psDeclarationName declaration) implementationName)
    | throw (IO.userError "P1 negative control lost its actual body")
  let some (.theoremDecl _ _ wholeType _) := prepared.declarations.find? (fun declaration =>
    psNameEq (psDeclarationName declaration) wholeName)
    | throw (IO.userError "P1 negative control lost its whole equation")
  let .constE _ [sort] := (psReduceAppView wholeType).head
    | throw (IO.userError "P1 negative control lost its equality universe")
  let self := PsExpr.constE name (levels.map PsLevel.param)
  let selfEquality := psLogicEq sort type self self
  let selfProof := psExprApplyMany
    (.constE (psNameAppendStr (psRootName "Eq") "refl") [sort]) [type, self]
  -- The old eq_def used the old whole equation; omit it from this deliberately
  -- smaller adversarial graph instead of retaining an invalid dependent proof.
  -- The original complete source graph was checked independently above.
  let changed := prepared.declarations.filterMap fun declaration =>
    if psNameEq (psDeclarationName declaration) sourceEquationName then none else
      match declaration with
      | .partialDecl actual .. =>
        if psNameEq actual implementationName then
          some (.partialDecl actual levels type self)
        else some declaration
      | .theoremDecl actual .. =>
        if psNameEq actual wholeName then
          some (.theoremDecl actual levels selfEquality selfProof)
        else some declaration
      | _ => some declaration
  checkOfficial prelude { prepared with declarations := changed }
    "welltyped-self-equation-mismatched-functional"
  expectRuntimeRefusal changed
    "PSCV0-FIXPOINT-RUNTIME: retained source bodies do not reconstruct the checked fixedpoint functional"
  expectRuntimeRefusal (prepared.declarations.filter (fun declaration =>
    !psNameEq (psDeclarationName declaration) auxiliary))
    "PSCV0-FIXPOINT-RUNTIME: missing unique checked fixedpoint auxiliary"
  let opaqueAuxiliary := prepared.declarations.map fun declaration =>
    match declaration with
    | .definitionDecl actual levels type value =>
      if psNameEq actual auxiliary then .opaqueDecl actual levels type value else declaration
    | _ => declaration
  expectRuntimeRefusal opaqueAuxiliary
    "PSCV0-FIXPOINT-RUNTIME: missing unique checked fixedpoint auxiliary"
  let missingRight := prepared.declarations.filter fun declaration =>
    !psNameEq (psDeclarationName declaration) (PsName.num (psRootName "p1Right") 0)
  expectRuntimeRefusal missingRight
    "PSCV0-FIXPOINT-RUNTIME: missing or duplicate packed member projection"
  IO.println "PSCV0_M3_P1_ADAPTER: PASS kernel-valid equation/body mismatch refusal, missing or opaque auxiliary refusal and incomplete packed-component refusal"

private def checkLogicalOnly (prelude : Lean.Kernel.Environment) : IO Unit := do
  for (label, text) in logicalOnlySources do
    let compiled ← elaborate text
    ensure (compiled.result.declarations.any (fun declaration =>
      match declaration with | .partialDecl .. => true | _ => false))
      ("former P1 source no longer exercises a recursive implementation: " ++ label)
    let output ← fromExcept ((psCompilerPrepareElaboratedWithOutput compiled.result).mapError
      psCompilerPscv0Error)
    checkOfficial prelude output.prepared label
  IO.println "PSCV0_M3_P1_LOGICAL_ONLY: PASS both exact former policy-refusal programs are kernel-checked logical definitions; neither was emitted or executed"

private def checkNonmonotoneRefusal : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram
    "function nonMonotone(n: Nat): Nat := nonMonotone(n) + 1\npartial_fixpoint\n")
  match psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed with
  | .error error =>
    let message := psCompilerPscv0ElabError error
    ensure (message.startsWith "PSCV0-DATA: PSCV0-FIXPOINT-MONOTONICITY:")
      ("nonmonotone source failed at the wrong boundary: " ++ message)
  | .ok _ => throw (IO.userError "nonmonotone Nat functional was accepted")
  IO.println "PSCV0_M3_P1_NONMONOTONE: PASS exact checked-monotonicity refusal"

private def emitRuntime (directory : System.FilePath) : IO Unit := do
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "p1fixedpoint.ps") source
  ensure (M3PartialFixpointOracle.countdownOutput false == 29 &&
    M3PartialFixpointOracle.countdownOutput true == 17 &&
    M3PartialFixpointOracle.optionOutput false == 48 &&
    M3PartialFixpointOracle.optionOutput true == 42 &&
    M3PartialFixpointOracle.mutualOutput false == 4123 &&
    M3PartialFixpointOracle.mutualOutput true == 2341)
    "independent native P1 terminating observations changed"
  let ordinary : PsV7Native.Request := {
    source, sourceName := "p1fixedpoint.ps", outputStem := "p1fixedpoint"
    assurance := .ordinaryChecked
    exports := .selected (exports.map Prod.fst)
    targets := [.javascript, .typescript, .rust, .wasmCore, .wasmComponent] }
  let requests := #[ordinary,
    { ordinary with assurance := .closedVerified },
    { ordinary with assurance := .boundaryQualifiedVerified }]
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok batch => pure batch
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  ensure (batch.results.size == requests.size) "P1 batch omitted an assurance result"
  let some first := (batch.results[0]? :
      Option (Except PsV7Native.Diagnostic PsV7Native.Result))
    | throw (IO.userError "P1 ordinary result is missing")
  let result : PsV7Native.Result ← match first with
    | .ok result => pure result
    | .error error => throw (IO.userError ("P1 ordinary request failed at " ++
        error.phase ++ ": " ++ error.message))
  ensure (PsV7Native.assuranceLabel result.assurance == "ordinary-checked" &&
    result.declarationCount > 0 && result.artifacts.map (·.target) == ordinary.targets &&
    result.artifacts.all (fun artifact => !artifact.files.isEmpty))
    "P1 changed assurance or omitted a requested target bundle"
  for index in ([1, 2] : List Nat) do
    match (batch.results[index]? :
        Option (Except PsV7Native.Diagnostic PsV7Native.Result)) with
    | some (.error error) =>
      ensure (error.phase == "assurance" &&
        error.message.startsWith "PSCV0-ASSURANCE-DOWNGRADE:")
        ("P1 verified request failed at the wrong boundary: " ++
          error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError "P1 verified request acquired an ordinary fallback or artifacts")
  for artifact in result.artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      exports.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag).toNat))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_P1_EMISSION: PASS fresh official-kernel ordinary five-target emission and both exact verified-assurance refusals; 30 terminating runtime comparisons follow"

def main (args : List String) : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "P1 fixture is not running on the pinned native Lean toolchain"
  let [directory] := args
    | throw (IO.userError "usage: pscv0M3PartialFixpoint DIRECTORY")
  fromExcept psCompilerValidatePscv0Standard
  let prelude ← match ← PsKernelLean.buildLeanPreludeEnvironment with
    | .ok environment => pure environment
    | .error error => throw (IO.userError (error.kind.code ++ ": " ++ error.message))
  let prepared ← checkConstruction prelude
  checkAdapterNegatives prelude prepared
  checkLogicalOnly prelude
  checkNonmonotoneRefusal
  emitRuntime (System.FilePath.mk directory)
  IO.println "PSCV0_M3_P1: PASS native logical/runtime separation, checked packed fixpoint ownership, exact unfolding equations, adversarial adapter refusal and retained nonmonotone/verified boundaries"
