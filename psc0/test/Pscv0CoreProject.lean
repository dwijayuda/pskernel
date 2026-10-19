import Ps.Compiler.Pscv0ModuleEngine
import Ps.CompilerIr.Checked
import Ps.Environment.Logic
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
    (profile : PsCompilerProfileContext) (kind : PsCompilerSourceKind) : IO String := do
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
  let client := input kind "Entry" (entrySource kind "import Facade\n")
  let facade := input kind "Facade" (match kind with
    | .lean => "module\npublic import Library\npublic " ++ identitySource kind "coreProjectFacade"
    | .proofScript => "public import Library\n" ++ identitySource kind "coreProjectFacade")
  let reexportLibrary := match kind with
    | .lean => input .lean "Library"
        ("module\nnamespace ProjectLib\n" ++
          "public def copy (A : Type) (x : A) : A := CoreSelectedIdentity A x\nend ProjectLib\n")
    | .proofScript => library
  let reexportClient := match kind with
    | .lean => input .lean "Entry"
        ("module\nimport Facade\nnamespace ProjectEntry\n" ++
          "public def twice (A : Type) (f : A -> A) (x : A) : A := ProjectLib.copy A (f (f x))\n" ++
          "end ProjectEntry\n")
    | .proofScript => client
  let exported ← prepare profile "Entry" [reexportClient, facade, reexportLibrary]
  let _ ← admit seed exported.admissions
  ensure (sameNames exported.mainNames [mainName] &&
      exported.libraryNames.any (psNameEq libName))
    "re-export ownership changed"
  let some facadeReceipt := exported.moduleProfiles.find? (fun item => item.name == "Facade")
    | fail "public import receipt missing"
  ensure (facadeReceipt.source == facade.source &&
      facadeReceipt.imports == [("Library", true)])
    "public import receipt changed"
  let ordinaryFacade := input kind "Facade"
    ("import Library\n" ++ identitySource kind "coreProjectFacade")
  refuse profile "Entry" [client, ordinaryFacade, library] true
    "PSCV0-SCOPE: unknown name ProjectLib.copy"
  pure exported.admissions

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

private def checkModuleHeaders (seed : Lean.Kernel.Environment)
    (profile : PsCompilerProfileContext) : IO Unit := do
  let library := input .lean "Library"
    ("module\nnamespace ProjectLib\n" ++
      "def hidden (A : Type) (x : A) : A := CoreSelectedIdentity A x\n" ++
      "public def copy (A : Type) (x : A) : A := hidden A x\nend ProjectLib\n")
  let entry := input .lean "Entry"
    ("module\nimport Library\nnamespace ProjectEntry\n" ++
      "public def twice (A : Type) (f : A -> A) (x : A) : A := ProjectLib.copy A (f (f x))\n" ++
      "end ProjectEntry\n")
  let nativeSurface ← prepare profile "Entry" [entry, library]
  let paired ← prepare profile "Entry"
    [input .proofScript "Library" (privateSource .proofScript),
      input .proofScript "Entry" (entrySource .proofScript)]
  let _ ← admit seed nativeSurface.admissions
  let _ ← admit seed paired.admissions
  ensure (nativeSurface.admissions == paired.admissions)
    "module default privacy changed paired admissions"
  let some receipt := nativeSurface.moduleProfiles.find? (fun item => item.name == "Library")
    | fail "module library receipt missing"
  ensure (!receipt.privateNames.isEmpty && receipt.source == library.source &&
      receipt.privateNames.all (fun name =>
        !receipt.interface.declarations.any (fun decl => psNameEq (psDeclarationName decl) name)))
    "module default-private declaration leaked"
  refuse profile "Entry" [library, input .lean "Entry"
    ("module\nimport Library\n" ++
      "public def hiddenUse (A : Type) (x : A) : A := ProjectLib.hidden A x\n")] true
    "PSCV0-SCOPE: unknown name ProjectLib.hidden"
  -- Explicit public is harmless without a module header in pinned native Lean.
  let publicWithoutHeader ← prepare profile "Entry"
    [input .lean "Entry" ("public " ++ identitySource .lean "coreProjectPublic")]
  let _ ← admit seed publicWithoutHeader.admissions
  ensure (publicWithoutHeader.mainNames.any (psNameEq (psRootName "coreProjectPublic")))
    "explicit public lost its name"
  let definition := identitySource .lean "coreHeaderValue"
  let negatives : List (String × String) := [
    ("public import Library\n" ++ definition, "PSCV0-LEAN-MODULE-REQUIRED"),
    ("module\nmodule\n" ++ definition, "PSCV0-LEAN-MODULE-HEADER"),
    ("import Library\nmodule\n" ++ definition, "PSCV0-LEAN-MODULE-HEADER"),
    (definition ++ "module\n", "PSCV0-LEAN-MODULE-HEADER"),
    (definition ++ "import Library\n", "PSCV0-LEAN-IMPORT-ORDER"),
    ("module\npublic " ++ definition ++ "public import Library\n", "PSCV0-LEAN-IMPORT-ORDER"),
    ("module\npublic private " ++ definition, "PSCV0-LEAN-VISIBILITY-MODIFIER"),
    ("module\nprivate section\n" ++ definition, "PSCV0-LEAN-VISIBILITY-SCOPE-UNSUPPORTED"),
    ("module\npublic namespace Rejected\n" ++ definition, "PSCV0-LEAN-VISIBILITY-SCOPE-UNSUPPORTED"),
    ("module\nprivate namespace Rejected\n" ++ definition, "PSCV0-LEAN-VISIBILITY-SCOPE-UNSUPPORTED")]
  for (text, expected) in negatives do
    match psLex text with
    | .error _ => fail "module refusal fixture failed lexing"
    | .ok _ => pure ()
    match psCompilerParsePscv0Program .lean text with
    | .ok _ => fail ("module refusal disappeared: " ++ expected)
    | .error message =>
      ensure (message.startsWith expected) ("module refusal phase changed: " ++ message)
  IO.println "PSCV0_CORE_MODULE_HEADER: paired re-export, default privacy, explicit public and ten owned refusal controls passed"

private def scopeIdentity (kind : PsCompilerSourceKind)
    (visibility name callee : String) : String :=
  visibility ++ match kind with
  | .lean =>
      "def " ++ name ++ " (A : Type) (x : A) : A := " ++ callee ++ " A x\n"
  | .proofScript =>
      "function " ++ name ++ "(A: Type, x: A): A := " ++ callee ++ "(A, x)\n"

private def scopeLibrarySource (kind : PsCompilerSourceKind) : String :=
  let header := match kind with
    | .lean => "module\n"
    | .proofScript => ""
  let publicSection := match kind with
    | .lean => "public section"
    | .proofScript => "section"
  let restoredPrivate := match kind with
    | .lean => ""
    | .proofScript => "private "
  let explicitPublic := match kind with
    | .lean => "public "
    | .proofScript => ""
  let decl := scopeIdentity kind
  header ++
    "namespace CoreVisibility\n" ++
    decl restoredPrivate "before" "CoreSelectedIdentity" ++
    publicSection ++ " Visible\n" ++
    decl "" "first" "before" ++
    "section Nested\n" ++
    decl "" "innerSection" "first" ++
    "end Nested\n" ++
    "namespace Nested\n" ++
    decl "" "innerNamespace" "innerSection" ++
    decl "private " "overridden" "before" ++
    decl "" "throughPrivate" "overridden" ++
    "end Nested\n" ++
    "mutual\n" ++
    decl "" "mutualPublic" "mutualPrivate" ++
    decl "private " "mutualPrivate" "Nested.throughPrivate" ++
    "end\n" ++
    decl "" "afterNamespace" "mutualPublic" ++
    "end Visible\n" ++
    decl restoredPrivate "afterPublic" "afterNamespace" ++
    decl explicitPublic "finalValue" "afterPublic" ++
    "end CoreVisibility\n" ++
    decl restoredPrivate "rootAfter" "CoreVisibility.finalValue" ++
    publicSection ++ "\n" ++
    decl "" "anonymousPublic" "CoreVisibility.finalValue" ++
    publicSection ++ " NestedPublic\n" ++
    decl "" "nestedPublic" "anonymousPublic" ++
    "end NestedPublic\n" ++
    decl "" "afterNestedPublic" "nestedPublic" ++
    "end\n" ++
    decl restoredPrivate "afterAnonymous" "afterNestedPublic" ++
    publicSection ++ "\n" ++
    "namespace AtEof\n" ++
    decl "" "value" "afterAnonymous"

private def scopeClientSource (kind : PsCompilerSourceKind)
    (callee : String := "AtEof.value") : String :=
  (match kind with
    | .lean => "module\nimport Library\npublic "
    | .proofScript => "import Library\n") ++
  scopeIdentity kind "" "coreVisibilityClient" callee

private def scopePublicNames : List PsName :=
  [psNameAppendStr (psRootName "CoreVisibility") "first",
   psNameAppendStr (psRootName "CoreVisibility") "innerSection",
   psNameAppendStr
     (psNameAppendStr (psRootName "CoreVisibility") "Nested") "innerNamespace",
   psNameAppendStr
     (psNameAppendStr (psRootName "CoreVisibility") "Nested") "throughPrivate",
   psNameAppendStr (psRootName "CoreVisibility") "mutualPublic",
   psNameAppendStr (psRootName "CoreVisibility") "afterNamespace",
   psNameAppendStr (psRootName "CoreVisibility") "finalValue",
   psRootName "anonymousPublic",
   psRootName "nestedPublic",
   psRootName "afterNestedPublic",
   psNameAppendStr (psRootName "AtEof") "value"]

-- Mutual predefinitions emit checked equation theorems. Keep their dependency
-- explicit in this separate four-declaration fixture base; the other project
-- checks still use only CoreSelectedIdentity.
private def scopeContext :
    IO (Lean.Kernel.Environment × PsCompilerProfileContext) := do
  let eqNames := [psEqName, psNameAppendStr psEqName "refl",
    psNameAppendStr psEqName "rec"]
  let equality := psLogicDeclarations.filter fun declaration =>
    eqNames.any (psNameEq (psDeclarationName declaration))
  ensure (sameNames (equality.map psDeclarationName) eqNames)
    "scope equality-family roster changed"
  ensure (match equality with
    | [.inductiveDecl _, .constructorDecl _, .recursorDecl _] => true
    | _ => false) "scope equality-family kinds changed"
  let declarations := baseDecl :: equality
  let result ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations declarations
  let seed ← match result with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  let environment ← declarations.foldlM (fun environment declaration => do
    let some next := psEnvironmentAdd environment declaration
      | fail "duplicate scope base declaration"
    pure next) psEnvironmentEmpty
  ensure (environment.declarations.length == 4)
    "scope base declaration count changed"
  for name in ["Nat", "Bool", "False", "True"] do
    ensure (!(psEnvironmentContains environment (psRootName name)) &&
        (seed.find? (PsKernelLean.toLeanName (psRootName name))).isNone)
      ("unselected scope base declaration: " ++ name)
  let profile : PsCompilerProfileContext := {
    baseEnvironment := environment
    runtimePrelude := fun _ _ => [] }
  return (seed, profile)

private def scopePrivateNames : List PsName :=
  let library := psNameAppendStr (psRootName "$psc0Private") "Library"
  let visibility := psNameAppendStr library "CoreVisibility"
  [psNameAppendStr visibility "before",
   psNameAppendStr (psNameAppendStr visibility "Nested") "overridden",
   psNameAppendStr visibility "mutualPrivate",
   psNameAppendStr visibility "afterPublic",
   psNameAppendStr library "rootAfter",
   psNameAppendStr library "afterAnonymous",
   psNameAppendStr
     (psNameAppendStr (psRootName "CoreVisibility") "mutualPublic") "eq_def",
   psNameAppendStr (psNameAppendStr visibility "mutualPrivate") "eq_def"]

private def checkVisibilityScopes : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := input kind "Library" (scopeLibrarySource kind)
    let entry := input kind "Entry" (scopeClientSource kind)
    let output ← prepare profile "Entry" [entry, library]
    let _ ← admit seed output.admissions
    let explicitlyClosed := { library with source := library.source ++ "end AtEof\nend\n" }
    let closed ← prepare profile "Entry" [entry, explicitlyClosed]
    ensure (closed.admissions == output.admissions)
      "EOF closure differs from explicit matching ends"
    let _ ← admit seed closed.admissions
    let some receipt := output.moduleProfiles.find?
        (fun item => item.name == "Library")
      | fail "visibility-scope module receipt missing"
    ensure (receipt.source == library.source &&
        receipt.sourceName == library.sourceName && receipt.imports.isEmpty)
      "visibility-scope source receipt changed"
    ensure (sameNames
        (receipt.interface.declarations.map psDeclarationName) scopePublicNames)
      "visibility-scope public roster changed"
    ensure (receipt.privateNames.length == scopePrivateNames.length &&
        scopePrivateNames.all (fun expected =>
          receipt.privateNames.any (psNameEq expected)) &&
        receipt.privateNames.all (fun name =>
          !receipt.interface.declarations.any
            (fun declaration => psNameEq (psDeclarationName declaration) name)))
      "visibility-scope six private declarations or two equation helpers changed"
    ensure (sameNames output.mainNames [psRootName "coreVisibilityClient"])
      "visibility-scope entry ownership changed"
    for hidden in
        ["CoreVisibility.before", "CoreVisibility.Nested.overridden",
         "CoreVisibility.mutualPrivate", "CoreVisibility.afterPublic",
         "rootAfter", "afterAnonymous", "CoreVisibility.mutualPrivate.eq_def"] do
      refuse profile "Entry"
        [library, input kind "Entry" (scopeClientSource kind hidden)] true
        ("PSCV0-SCOPE: unknown name " ++ hidden)
    refuse profile "Entry"
      [library, input kind "Entry"
        (scopeClientSource kind "CoreVisibility.mutualPublic.eq_def")]
      true "PSCV0-UNKNOWN-NAME: CoreVisibility.mutualPublic.eq_def"
    let publicSection := match kind with
      | .lean => "module\npublic section"
      | .proofScript => "section"
    let definition := identitySource kind "scopeEndControl"
    refuse profile "Entry"
      [input kind "Entry"
        (publicSection ++ " Open\n" ++ definition ++ "end Open\nend\n")]
      true "PSCV0-SCOPE: end without an open scope"
    refuse profile "Entry"
      [input kind "Entry"
        (publicSection ++ " Open\n" ++ definition ++ "end Wrong\n")]
      true "PSCV0-SCOPE: end name does not match the innermost scope"
    paired := paired ++ [output.admissions]
  let [leanAdmissions, psAdmissions] := paired
    | fail "visibility-scope paired source count changed"
  ensure (leanAdmissions == psAdmissions)
    "Lean and PS visibility-scope admissions differ"
  let headerless ← prepare profile "Entry"
    [input .lean "Entry"
      ("public section\n" ++ identitySource .lean "coreVisibilityHeaderless")]
  let _ ← admit seed headerless.admissions
  ensure (sameNames headerless.mainNames [psRootName "coreVisibilityHeaderless"])
    "headerless public section changed visibility"
  IO.println "PSCV0_CORE_VISIBILITY_SCOPES: paired nested scopes, mutual privacy, overrides, restoration, EOF equality, exact interfaces, six source-private declarations, two private equation helpers and end controls passed"

private def moduleKindRefusal : String :=
  "PSCV0-MODULE-KIND: module Entry cannot import non-module Library"

private def kindHeader (kind : PsCompilerSourceKind) (nativeModule : Bool) : String :=
  match kind with
  | .lean => if nativeModule then "module\n" else ""
  | .proofScript => ""

private def kindPublic (kind : PsCompilerSourceKind) (nativeModule : Bool) : String :=
  match kind with
  | .lean => if nativeModule then "public " else ""
  | .proofScript => ""

private def kindLibrary (kind : PsCompilerSourceKind) (nativeModule : Bool) :
    PsPscv0ModuleSource :=
  input kind "Library"
    (kindHeader kind nativeModule ++ kindPublic kind nativeModule ++
      identitySource kind "coreKindValue")

private def kindEntry (kind : PsCompilerSourceKind) (nativeModule : Bool)
    (publicImport : Bool := false) (withDeclaration : Bool := true) :
    PsPscv0ModuleSource :=
  input kind "Entry"
    (kindHeader kind nativeModule ++
      (if publicImport then "public import Library\n" else "import Library\n") ++
      (if withDeclaration then
        kindPublic kind nativeModule ++
          scopeIdentity kind "" "coreKindUse" "coreKindValue"
       else ""))

private def checkModuleKinds (seed : Lean.Kernel.Environment)
    (profile : PsCompilerProfileContext) : IO Unit := do
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    for nativeModule in [false, true] do
      let source := kindLibrary kind nativeModule
      let parsed ← match psCompilerParsePscv0Program kind source.source with
        | .ok parsed => pure parsed
        | .error message => fail message
      let expected := match kind with
        | .lean => nativeModule
        | .proofScript => true
      ensure (parsed.isModule == expected) "source reader lost its module kind"
  let reference ← prepare profile "Entry"
    [kindEntry .lean false, kindLibrary .lean false]
  let check := fun (library entry : PsPscv0ModuleSource) => do
    let output ← prepare profile "Entry" [entry, library]
    ensure (output.admissions == reference.admissions)
      "module kind changed canonical declarations"
    ensure (sameNames output.mainNames [psRootName "coreKindUse"])
      "module kind changed entry ownership"
    let _ ← admit seed output.admissions
    pure output
  for clientModule in [false, true] do
    for providerModule in [false, true] do
      let library := kindLibrary .lean providerModule
      let entry := kindEntry .lean clientModule
      if clientModule && !providerModule then
        refuse profile "Entry" [entry, library] false moduleKindRefusal
      else
        let _ ← check library entry
        pure ()
  for (library, entry) in
      [(kindLibrary .proofScript true, kindEntry .proofScript true),
       (kindLibrary .lean true, kindEntry .proofScript true),
       (kindLibrary .proofScript true, kindEntry .lean true),
       (kindLibrary .proofScript true, kindEntry .lean false)] do
    let _ ← check library entry
    pure ()
  refuse profile "Entry"
    [kindEntry .proofScript true, kindLibrary .lean false]
    false moduleKindRefusal
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let publicEntry := kindEntry kind true true
    let publicOutput ← check (kindLibrary .lean true) publicEntry
    let some receipt := publicOutput.moduleProfiles.find?
        (fun item => item.name == "Entry")
      | fail "module-kind public import receipt missing"
    ensure (receipt.imports == [("Library", true)])
      "module-kind public import flag changed"
    refuse profile "Entry"
      [publicEntry, kindLibrary .lean false] false moduleKindRefusal
    for publicImport in [false, true] do
      refuse profile "Entry"
        [kindEntry kind true publicImport false, kindLibrary .lean false]
        false moduleKindRefusal
  IO.println "PSCV0_CORE_MODULE_KIND: native 2x2 matrix, mixed source directions, public imports and import-only refusals passed"

private def bodyLibrarySource (kind : PsCompilerSourceKind) : String :=
  match kind with
  | .lean =>
      "module\n" ++
      "public def coreBodyOpaque (A : Type) (x : A) : A := x\n" ++
      "public abbrev coreBodyExposed (A : Type) (x : A) : A := x\n" ++
      "public theorem coreBodySpec (A : Type) (x : A) : coreBodyOpaque A x = x := by rfl\n"
  | .proofScript =>
      "function coreBodyOpaque(A: Type, x: A): A := x\n" ++
      "abbrev coreBodyExposed(A: Type, x: A): A := x\n" ++
      "theorem coreBodySpec(A: Type, x: A): coreBodyOpaque(A, x) = x := by { rfl }\n"

private def bodyClientSource (kind : PsCompilerSourceKind) (forbidden : Bool) : String :=
  match kind with
  | .lean =>
      "module\npublic import Library\n" ++
      (if forbidden then
        "public theorem coreBodyForbidden (A : Type) (x : A) : coreBodyOpaque A x = x := by rfl\n"
       else
        "public theorem coreBodyProof (A : Type) (x : A) : coreBodyExposed A x = x := by rfl\n" ++
        "public theorem coreBodyViaSpec (A : Type) (x : A) : coreBodyOpaque A x = x := coreBodySpec A x\n")
  | .proofScript =>
      "public import Library\n" ++
      (if forbidden then
        "theorem coreBodyForbidden(A: Type, x: A): coreBodyOpaque(A, x) = x := by { rfl }\n"
       else
        "theorem coreBodyProof(A: Type, x: A): coreBodyExposed(A, x) = x := by { rfl }\n" ++
        "theorem coreBodyViaSpec(A: Type, x: A): coreBodyOpaque(A, x) = x := coreBodySpec(A, x)\n")

private def checkImportedBodies : IO Unit := do
  let (seed, profile) ← scopeContext
  let opaqueName := psRootName "coreBodyOpaque"
  let exposedName := psRootName "coreBodyExposed"
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := input kind "Library" (bodyLibrarySource kind)
    let entry := input kind "Entry" (bodyClientSource kind false)
    let output ← prepare profile "Entry" [entry, library]
    let _ ← admit seed output.admissions
    let some receipt := output.moduleProfiles.find?
        (fun item => item.name == "Library")
      | fail "body-visibility library receipt missing"
    ensure (sameNames receipt.exposedNames [exposedName])
      "body exposure ownership changed"
    let some (.opaqueDecl ..) := receipt.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) opaqueName)
      | fail "ordinary imported definition exposed its body"
    let some (.definitionDecl ..) := receipt.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) exposedName)
      | fail "imported abbreviation lost its exposed body"
    refuse profile "Entry"
      [library, input kind "Entry" (bodyClientSource kind true)]
      true "PSCV0-PROOF: rfl requires definitionally equal sides"
    paired := paired ++ [output.admissions]
  let [leanAdmissions, psAdmissions] := paired
    | fail "body-visibility paired source count changed"
  ensure (leanAdmissions == psAdmissions)
    "Lean and PS imported-body admissions differ"
  IO.println "PSCV0_CORE_IMPORTED_BODY: paired exposed abbreviation and exported theorem proofs, ordinary definition opacity and owned rfl refusal passed"


private def importVisibilityInput (kind : PsCompilerSourceKind)
    (name imports : String) (pieces : List (String × String)) :
    PsPscv0ModuleSource :=
  let body := pieces.foldl (fun acc piece =>
    acc ++ (match kind with
      | .lean => piece.fst
      | .proofScript => piece.snd)) ""
  input kind name ((match kind with
    | .lean => "module\n"
    | .proofScript => "") ++ imports ++ body)

private def importVisibilityProvider : List (String × String) := [
  ("public def coreImportType (A : Type) : Type := A\n",
   "function coreImportType(A: Type): Type := A\n"),
  ("public def coreImportValue (A : Type) (x : A) : A := x\n",
   "function coreImportValue(A: Type, x: A): A := x\n"),
  ("public theorem coreImportProof (A : Type) (x : A) : x = x := by rfl\n",
   "theorem coreImportProof(A: Type, x: A): x = x := by { rfl }\n")]

private def importVisibilitySignature : String × String :=
  ("public def coreImportSignature (A : Type) (x : coreImportType A) (y : A) : A := y\n",
   "function coreImportSignature(A: Type, x: coreImportType(A), y: A): A := y\n")

private def importVisibilityExposed : String × String :=
  ("public abbrev coreImportExposed (A : Type) (x : A) : A := coreImportValue A x\n",
   "abbrev coreImportExposed(A: Type, x: A): A := coreImportValue(A, x)\n")

private def importVisibilityOpaque : String × String :=
  ("public def coreImportOpaque (A : Type) (x : A) : A := coreImportValue A x\n",
   "function coreImportOpaque(A: Type, x: A): A := coreImportValue(A, x)\n")

private def importVisibilityProof : String × String :=
  ("public theorem coreImportViaProof (A : Type) (x : A) : x = x := coreImportProof A x\n",
   "theorem coreImportViaProof(A: Type, x: A): x = x := coreImportProof(A, x)\n")

private def importVisibilityBridge : String × String :=
  ("public def coreImportBridge (A : Type) (x : A) : A := coreImportValue A x\n",
   "function coreImportBridge(A: Type, x: A): A := coreImportValue(A, x)\n")

private def importVisibilityAcrossBridge : String × String :=
  ("public abbrev coreImportAcrossBridge (A : Type) (x : A) : A := coreImportBridge A x\n",
   "abbrev coreImportAcrossBridge(A: Type, x: A): A := coreImportBridge(A, x)\n")

private def importVisibilityDeclaration (output : PsCompilerEngineProjectOutput)
    (name : String) : IO PsDeclaration := do
  let some declaration := output.prepared.declarations.find?
      (fun declaration => psNameEq (psDeclarationName declaration) (psRootName name))
    | fail ("missing import-visibility declaration " ++ name)
  return declaration

private def importVisibilityInterface (output : PsCompilerEngineProjectOutput) :
    IO PsPscv0ModuleInterface := do
  let some entry := output.moduleProfiles.find? (fun item => item.name == "Entry")
    | fail "import-visibility entry receipt missing"
  return entry.interface

private def checkImportVisibilityDependencies
    (output : PsCompilerEngineProjectOutput) (withPublicUses : Bool) : IO Unit := do
  let ordinary ← importVisibilityDeclaration output "coreImportOpaque"
  let some ordinaryBody := psDeclarationValue ordinary
    | fail "ordinary implementation body disappeared from checked declarations"
  ensure ((psPscv0ExprConstants ordinaryBody).any
      (psNameEq (psRootName "coreImportValue")))
    "ordinary implementation lost its imported dependency"
  let proof ← importVisibilityDeclaration output "coreImportViaProof"
  let .theoremDecl _ _ _ proofBody := proof
    | fail "imported proof changed declaration kind"
  ensure ((psPscv0ExprConstants proofBody).any
      (psNameEq (psRootName "coreImportProof")))
    "theorem lost its private imported proof dependency"
  if withPublicUses then
    let signature ← importVisibilityDeclaration output "coreImportSignature"
    ensure ((psPscv0ExprConstants (psDeclarationType signature)).any
        (psNameEq (psRootName "coreImportType")))
      "imported signature dependency disappeared"
    let exposed ← importVisibilityDeclaration output "coreImportExposed"
    let some exposedBody := psDeclarationValue exposed
      | fail "exposed implementation body missing"
    ensure ((psPscv0ExprConstants exposedBody).any
        (psNameEq (psRootName "coreImportValue")))
      "exposed implementation lost its imported dependency"

private def checkImportVisibility : IO Unit := do
  let (seed, profile) ← scopeContext
  let ordinaryPieces := [importVisibilityOpaque, importVisibilityProof]
  let allPieces := [importVisibilitySignature, importVisibilityExposed,
    importVisibilityOpaque, importVisibilityProof]
  let ordinaryNames := ["coreImportOpaque", "coreImportViaProof"].map psRootName
  let allNames := ["coreImportSignature", "coreImportExposed",
    "coreImportOpaque", "coreImportViaProof"].map psRootName
  let providerNames := ["coreImportType", "coreImportValue", "coreImportProof"].map psRootName
  let signatureRefusal :=
    "PSCV0-MODULE: public signature references private import in coreImportSignature"
  let exposedRefusal :=
    "PSCV0-MODULE: exposed body references private import in coreImportExposed"
  let mut ordinaryPairs : List String := []
  let mut bridgePairs : List String := []
  let mut publicReference : Option String := none
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := importVisibilityInput kind "Library" "" importVisibilityProvider
    let facade := importVisibilityInput kind "Facade" "public import Library\n" []
    let left := importVisibilityInput kind "Left" "public import Library\n" []
    let right := importVisibilityInput kind "Right" "public import Library\n" []
    let ordinary ← prepare profile "Entry"
      [importVisibilityInput kind "Entry" "import Library\n" ordinaryPieces, library]
    let _ ← admit seed ordinary.admissions
    checkImportVisibilityDependencies ordinary false
    let ordinaryView ← importVisibilityInterface ordinary
    ensure (sameNames ordinary.mainNames ordinaryNames &&
        sameNames (ordinaryView.declarations.map psDeclarationName) ordinaryNames)
      "ordinary import leaked provider names into the interface"
    ordinaryPairs := ordinaryPairs ++ [ordinary.admissions]
    for (imports, intermediate) in
        [("public import Library\n", []),
         ("public import Facade\n", [facade]),
         ("import Left\npublic import Right\n", [left, right]),
         ("public import Right\nimport Left\n", [left, right])] do
      let output ← prepare profile "Entry"
        (importVisibilityInput kind "Entry" imports allPieces :: intermediate ++ [library])
      let _ ← admit seed output.admissions
      checkImportVisibilityDependencies output true
      ensure (sameNames output.mainNames allNames)
        "public import changed executable entry ownership"
      let view ← importVisibilityInterface output
      ensure (sameNames (view.declarations.map psDeclarationName) (allNames ++ providerNames))
        "public import did not retain its exact transitive interface"
      for name in providerNames do
        ensure ((view.declarations.filter (fun declaration =>
            psNameEq (psDeclarationName declaration) name)).length == 1)
          "public import diamond duplicated a declaration"
      match publicReference with
      | none => publicReference := some output.admissions
      | some reference =>
          ensure (output.admissions == reference)
            "public import route, order or source kind changed canonical declarations"
    refuse profile "Entry"
      [importVisibilityInput kind "Entry" "import Library\n" [importVisibilitySignature], library]
      true signatureRefusal
    refuse profile "Entry"
      [importVisibilityInput kind "Entry" "import Library\n" [importVisibilityExposed], library]
      true exposedRefusal
    refuse profile "Entry"
      [importVisibilityInput kind "Entry" "import Facade\n" [importVisibilitySignature],
       facade, library]
      true signatureRefusal
    let bridgeFacade := importVisibilityInput kind "Facade" "import Library\n"
      [importVisibilityBridge]
    let bridge ← prepare profile "Entry"
      [importVisibilityInput kind "Entry" "public import Facade\n"
         [importVisibilityAcrossBridge], bridgeFacade, library]
    let _ ← admit seed bridge.admissions
    let bridgeView ← importVisibilityInterface bridge
    let bridgeName := psRootName "coreImportBridge"
    let acrossName := psRootName "coreImportAcrossBridge"
    ensure (sameNames (bridgeView.declarations.map psDeclarationName) [acrossName, bridgeName])
      "opaque bridge leaked its private import or lost its public name"
    let some (.opaqueDecl ..) := bridgeView.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) bridgeName)
      | fail "ordinary bridge exposed its hidden implementation"
    let some (.definitionDecl _ _ _ acrossBody) := bridgeView.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) acrossName)
      | fail "client abbreviation lost its exposed bridge call"
    ensure ((psPscv0ExprConstants acrossBody).any (psNameEq bridgeName))
      "client bridge dependency disappeared"
    let bridgeDecl ← importVisibilityDeclaration bridge "coreImportBridge"
    let some bridgeBody := psDeclarationValue bridgeDecl
      | fail "bridge implementation missing from checked declarations"
    ensure ((psPscv0ExprConstants bridgeBody).any
        (psNameEq (psRootName "coreImportValue")))
      "bridge implementation lost its private imported dependency"
    refuse profile "Entry"
      [importVisibilityInput kind "Entry" "public import Facade\n"
         [importVisibilityExposed], bridgeFacade, library]
      true "PSCV0-SCOPE: unknown name coreImportValue"
    bridgePairs := bridgePairs ++ [bridge.admissions]
  let [leanOrdinary, psOrdinary] := ordinaryPairs
    | fail "ordinary import paired source count changed"
  ensure (leanOrdinary == psOrdinary) "ordinary-import paired admissions differ"
  let [leanBridge, psBridge] := bridgePairs
    | fail "bridge paired source count changed"
  ensure (leanBridge == psBridge) "bridge paired admissions differ"
  let legacyBody := allPieces.foldl (fun acc piece => acc ++ piece.fst) ""
  let legacy ← prepare profile "Entry"
    [input .lean "Entry" ("import Library\n" ++ legacyBody),
     importVisibilityInput .lean "Library" "" importVisibilityProvider]
  let _ ← admit seed legacy.admissions
  let some reference := publicReference
    | fail "public import canonical reference missing"
  ensure (legacy.admissions == reference)
    "legacy name-visibility exemption changed canonical declarations"
  IO.println "PSCV0_CORE_IMPORT_VISIBILITY: 13 positive projects, eight owned refusals, paired canonical admission, retained type/body/proof dependencies, public diamonds, opaque bridges and legacy exemption passed"

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
  let mut pairedExports : List String := []
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
    let exported ← visibility seed profile kind
    pairedExports := pairedExports ++ [exported]
    graph profile kind
    paired := paired ++ [output.admissions]
  let [leanAdmissions, psAdmissions] := paired
    | fail "paired source count changed"
  ensure (leanAdmissions == psAdmissions) "Lean and PS module admissions differ"
  let [leanExports, psExports] := pairedExports
    | fail "paired re-export source count changed"
  ensure (leanExports == psExports) "Lean and PS re-export admissions differ"
  checkModuleHeaders seed profile
  checkVisibilityScopes
  checkModuleKinds seed profile
  checkImportedBodies
  checkImportVisibility
  IO.println "PSCV0_CORE_PROJECT: paired modules, profile, kernel, graph, visibility and typed runtime controls passed"
