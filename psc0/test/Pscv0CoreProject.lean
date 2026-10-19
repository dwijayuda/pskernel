import Ps.Compiler.Pscv0ModuleEngine
import Ps.CompilerIr.Checked
import PsKernelLean.Replay
import PsKernelLean.Protocol

private def baseName : PsName := psRootName "CoreSelectedIdentity"
private def aliasName : PsName := psRootName "CoreProjectAlias"
private def libName : PsName :=
  psNameAppendStr (psRootName "ProjectLib") "copy"
private def mainName : PsName :=
  psNameAppendStr (psRootName "ProjectEntry") "twice"

private def idType : PsExpr :=
  .forallE (psRootName "A") (.sortE (.succ .zero))
    (.forallE (psRootName "x") (.bvar 0) (.bvar 1) .explicit) .explicit

private def idValue : PsExpr :=
  .lam (psRootName "A") (.sortE (.succ .zero))
    (.lam (psRootName "x") (.bvar 0) (.bvar 0) .explicit) .explicit

private def baseDecl : PsDeclaration :=
  .definitionDecl baseName [] idType idValue

private def widthCode : Option PsVerifiedIrWordSize → Nat
  | none => 0
  | some .bits32 => 32
  | some .bits64 => 64

private def profileFor (environment : PsEnvironment)
    (width : Option PsVerifiedIrWordSize) : PsCompilerProfileContext := {
  baseEnvironment := environment
  runtimePrelude := fun env actualWidth =>
    if env.declarations.length == 3 &&
        psEnvironmentContains env libName &&
        psEnvironmentContains env mainName &&
        widthCode actualWidth == widthCode width then [baseDecl] else [] }

private def fail {α : Type} (message : String) : IO α :=
  throw (IO.userError ("CORE-PROJECT: " ++ message))

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

private def takeCompiler {α : Type} (result : Except PsCompilerError α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (psCompilerPscv0Error error))

private def prepare (profile : PsCompilerProfileContext) (entry : String)
    (sources : List PsPscv0ModuleSource) : IO PsCompilerEngineProjectOutput :=
  match psCompilerEnginePreparePscv0Project profile entry sources with
  | .ok output => pure output
  | .error message => fail message

private def input (kind : PsCompilerSourceKind) (name source : String) :
    PsPscv0ModuleSource := {
  name := name
  source := source
  sourceKind := kind
  sourceName := name ++ psCompilerSourceKindExtension kind }

private def librarySource (kind : PsCompilerSourceKind)
    (callee : String := "CoreSelectedIdentity") : String :=
  "namespace ProjectLib\n" ++ (match kind with
    | .lean => "def copy (A : Type) (x : A) : A := " ++ callee ++ " A x\n"
    | .proofScript => "function copy(A: Type, x: A): A := " ++ callee ++ "(A, x)\n") ++
  "end ProjectLib\n"

private def entrySource (kind : PsCompilerSourceKind)
    (imports : String := "import Library\n")
    (callee : String := "ProjectLib.copy") : String :=
  imports ++ "namespace ProjectEntry\n" ++ (match kind with
    | .lean =>
        "def twice (A : Type) (f : A -> A) (x : A) : A := " ++ callee ++ " A (f (f x))\n"
    | .proofScript =>
        "function twice(A: Type, f: A -> A, x: A): A := " ++ callee ++ "(A, f(f(x)))\n") ++
  "end ProjectEntry\n"

private def identitySource (kind : PsCompilerSourceKind) (name : String) : String :=
  match kind with
  | .lean => "def " ++ name ++ " (A : Type) (x : A) : A := x\n"
  | .proofScript => "function " ++ name ++ "(A: Type, x: A): A := x\n"

private def privateSource (kind : PsCompilerSourceKind) : String :=
  "namespace ProjectLib\n" ++ (match kind with
    | .lean =>
        "private def hidden (A : Type) (x : A) : A := CoreSelectedIdentity A x\n" ++
        "def copy (A : Type) (x : A) : A := hidden A x\n"
    | .proofScript =>
        "private function hidden(A: Type, x: A): A := CoreSelectedIdentity(A, x)\n" ++
        "function copy(A: Type, x: A): A := hidden(A, x)\n") ++
  "end ProjectLib\n"

private def sameNames (left right : List PsName) : Bool :=
  left.length == right.length && (left.zip right).all (fun (a, b) => psNameEq a b)

private def sameAliases (left right : List (PsName × PsName)) : Bool :=
  left.length == right.length && (left.zip right).all (fun (a, b) =>
    psNameEq a.fst b.fst && psNameEq a.snd b.snd)

private def admit (seed : Lean.Kernel.Environment) (admissions : String) :
    IO Lean.Kernel.Environment := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok declarations => pure declarations
    | .error error => throw (IO.userError error.message)
  let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    declarations.toList.foldlM (fun (current : Lean.Kernel.Environment)
        (declaration : Lean.Declaration) =>
      (current.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight current declaration) none).mapError
          PsKernelLean.kernelExceptionSummary) seed
  match checked with
  | .ok environment => pure environment
  | .error message => fail ("kernel: " ++ message)

private def checkMissingBase (admissions : String) : IO Unit := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok declarations => pure declarations
    | .error error => throw (IO.userError error.message)
  let [.defnDecl first, .defnDecl second] := declarations.toList
    | fail "canonical roster"
  ensure (first.name == PsKernelLean.toLeanName libName &&
      second.name == PsKernelLean.toLeanName mainName &&
      (first.value.foldConsts false fun name seen =>
        seen || name == PsKernelLean.toLeanName baseName) &&
      (second.value.foldConsts false fun name seen =>
        seen || name == PsKernelLean.toLeanName libName))
    "canonical dependency lost"
  let emptyKernel := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    emptyKernel.addDeclCore 2000000 20000
      (PsKernelLean.psKernelWithDefinitionHeight emptyKernel (.defnDecl first)) none
  match result with
  | .error (.unknownConstant _ missing) =>
      ensure (missing == PsKernelLean.toLeanName baseName)
        "wrong missing constant"
  | .error error => fail ("wrong-base refusal: " ++ PsKernelLean.kernelExceptionSummary error)
  | .ok _ => fail "missing base was kernel-admitted"

private def refuse (profile : PsCompilerProfileContext) (entry : String)
    (sources : List PsPscv0ModuleSource) (graphValid : Bool)
    (expected : String) : IO Unit := do
  for item in sources do
    match psCompilerParsePscv0Program item.sourceKind item.source with
    | .ok _ => pure ()
    | .error message => fail ("negative parser failure: " ++ message)
  match psPscv0ProjectParse sources with
  | .ok _ => ensure graphValid "manifest refusal disappeared"
  | .error message =>
      ensure (!graphValid && message.startsWith expected)
        ("manifest phase: " ++ message)
  match psCompilerEnginePreparePscv0Project profile entry sources with
  | .error message =>
      ensure (message.startsWith expected) ("refusal phase: " ++ message)
  | .ok _ => fail ("refused source accepted: " ++ expected)

private def checkProject (profile : PsCompilerProfileContext)
    (library entry : PsPscv0ModuleSource) (output : PsCompilerEngineProjectOutput) :
    IO Unit := do
  let prepared := output.prepared
  ensure (sameNames (prepared.declarations.map psDeclarationName)
      [libName, mainName] && sameNames output.mainNames [mainName] &&
      sameNames output.libraryNames [libName])
    "module exports changed"
  let base := prepared.profile.baseEnvironment
  ensure (base.declarations.length == 1 &&
      psEnvironmentContains base baseName &&
      !psEnvironmentContains base libName &&
      !psEnvironmentContains base mainName &&
      !psEnvironmentContains base psNatName &&
      sameAliases base.exportedAliases profile.baseEnvironment.exportedAliases)
    "caller base or aliases changed"
  let some (.definitionDecl _ levels type value) := psEnvironmentFind base baseName
    | fail "base kind changed"
  ensure (levels.isEmpty && psExprAlphaEq type idType &&
      psExprAlphaEq value idValue) "base declaration changed"
  let canonical ← takeCompiler (psCompilerEngineAdmissionsFromPrepared prepared)
  ensure (canonical == output.admissions) "wire changed"
  ensure ((output.origins.map (·.moduleName)) == ["Library", "Entry"] &&
      (output.moduleProfiles.map (·.name)) == ["Library", "Entry"])
    "provenance order changed"
  for ((item, origin), receipt) in
      (([library, entry].zip output.origins).zip output.moduleProfiles) do
    ensure (origin.source == item.source && origin.sourceName == item.sourceName &&
        receipt.source == item.source && receipt.sourceName == item.sourceName &&
        receipt.imports == (if item.name == "Entry" then [("Library", false)] else []))
      "source receipt changed"

private def checkRuntime (prepared : PsCompilerEnginePrepared)
    (width : Option PsVerifiedIrWordSize) : IO Unit := do
  let env ← takeCompiler (psCompilerEngineEnvironmentFromPrepared prepared)
  ensure (env.declarations.length == 3 &&
      !psEnvironmentContains env psNatName)
    "runtime environment changed"
  let ir ← takeCompiler (psCompilerEngineVerifiedIrFromPrepared prepared width)
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
  let expected := [baseName, libName, mainName].map fun name =>
    psErasureSafeIdentifier (psNameToString name) "decl"
  ensure (report.accepted && report.traversalComplete &&
      ir.declarations.length == expected.length &&
      expected.all (fun name => ir.declarations.any (fun decl => decl.name == name)))
    "typed runtime selection failed"
  ensure (ir.internalNames == [psNameToString baseName])
    "runtime ownership changed"

private def visibility (seed : Lean.Kernel.Environment)
    (profile : PsCompilerProfileContext) (kind : PsCompilerSourceKind) : IO Unit := do
  let library := input kind "Library" (librarySource kind)
  let ordinary := input kind "Entry" (entrySource kind)
  refuse profile "Entry" [library, input kind "Entry" (entrySource kind "")] true
    "PSCV0-SCOPE: unknown name ProjectLib.copy"
  let hiddenLibrary := input kind "Library" (privateSource kind)
  let privateOutput ← prepare profile "Entry" [ordinary, hiddenLibrary]
  let _ ← admit seed privateOutput.admissions
  let some view := privateOutput.moduleProfiles.find? (fun item => item.name == "Library")
    | fail "private module receipt missing"
  ensure (!view.privateNames.isEmpty && view.privateNames.all (fun name =>
      !view.interface.declarations.any (fun decl => psNameEq (psDeclarationName decl) name)))
    "private interface leak"
  refuse profile "Entry"
    [hiddenLibrary, input kind "Entry"
      (entrySource kind "import Library\n" "ProjectLib.hidden")] true
    "PSCV0-SCOPE: unknown name ProjectLib.hidden"
  let facade := input kind "Facade"
    ("public import Library\n" ++ identitySource kind "coreProjectFacade")
  let client := input kind "Entry" (entrySource kind "import Facade\n")
  let exported ← prepare profile "Entry" [client, facade, library]
  let _ ← admit seed exported.admissions
  ensure (sameNames exported.mainNames [mainName] &&
      exported.libraryNames.any (psNameEq libName))
    "re-export ownership changed"
  let ordinaryFacade := input kind "Facade"
    ("import Library\n" ++ identitySource kind "coreProjectFacade")
  refuse profile "Entry" [client, ordinaryFacade, library] true
    "PSCV0-SCOPE: unknown name ProjectLib.copy"

private def graph (profile : PsCompilerProfileContext)
    (kind : PsCompilerSourceKind) : IO Unit := do
  let a := input kind "A" (identitySource kind "coreProjectA")
  let b := input kind "B" (identitySource kind "coreProjectB")
  refuse profile "A" [a, a] false "PSCV0-MODULE: duplicate module identity"
  let samePath := { b with sourceName := a.sourceName }
  refuse profile "A" [a, samePath] false "PSCV0-MODULE: duplicate source path identity"
  refuse profile "A" [input kind "A" ("import Missing\n" ++ a.source)] false
    "PSCV0-MODULE: missing module Missing imported by A"
  refuse profile "A"
    [input kind "A" ("import B\n" ++ a.source), input kind "B" ("import A\n" ++ b.source)]
    true "PSCV0-MODULE: circular import dependency"

def main : IO Unit := do
  let result ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations [baseDecl]
  let seed ← match result with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  let some environment := psEnvironmentAdd psEnvironmentEmpty baseDecl
    | fail "duplicate base"
  ensure (seed.find? `Nat).isNone "Nat leaked into seed"
  let emptyProfile : PsCompilerProfileContext := {
    baseEnvironment := psEnvironmentEmpty
    runtimePrelude := fun _ _ => [] }
  let profile := profileFor environment none
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := input kind "Library" (librarySource kind)
    let entry := input kind "Entry" (entrySource kind)
    let output ← prepare profile "Entry" [entry, library]
    checkProject profile library entry output
    let reordered ← prepare profile "Entry" [library, entry]
    checkProject profile library entry reordered
    ensure (reordered.admissions == output.admissions) "source order changed Core"
    let admitted ← admit seed output.admissions
    ensure ((admitted.find? (PsKernelLean.toLeanName mainName)).isSome &&
        (admitted.find? `Nat).isNone) "kernel closure changed"
    checkMissingBase output.admissions
    refuse emptyProfile "Entry" [entry, library] true
      "PSCV0-SCOPE: unknown name CoreSelectedIdentity"
    let aliasEnvironment := {
      environment with exportedAliases := [(aliasName, baseName)] }
    let aliasProfile := profileFor aliasEnvironment none
    let aliasLibrary := input kind "Library" (librarySource kind "CoreProjectAlias")
    let aliased ← prepare aliasProfile "Entry" [entry, aliasLibrary]
    checkProject aliasProfile aliasLibrary entry aliased
    ensure (aliased.admissions == output.admissions)
      "alias changed Core"
    refuse profile "Entry" [entry, aliasLibrary] true
      "PSCV0-SCOPE: unknown name CoreProjectAlias"
    for width in [none, some PsVerifiedIrWordSize.bits32, some .bits64] do
      let runtimeProfile := profileFor environment width
      let runtimeOutput ← prepare runtimeProfile "Entry" [entry, library]
      ensure (runtimeOutput.admissions == output.admissions)
        "runtime changed admissions"
      checkRuntime runtimeOutput.prepared width
    visibility seed profile kind
    graph profile kind
    paired := paired ++ [output.admissions]
  let [leanAdmissions, psAdmissions] := paired
    | fail "paired source count changed"
  ensure (leanAdmissions == psAdmissions) "Lean and PS module admissions differ"
  IO.println "PSCV0_CORE_PROJECT: paired modules, profile, kernel, graph, visibility and typed runtime controls passed"
