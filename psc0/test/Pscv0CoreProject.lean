import Ps.Compiler.Pscv0ModuleEngine
import Ps.CompilerIr.Checked
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript
import Ps.Environment.Logic
import Ps.Environment.Connectives
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
  let ordinaryFacade := input kind "Facade" (match kind with
    | .lean => "module\nimport Library\npublic " ++ identitySource kind "coreProjectFacade"
    | .proofScript => "import Library\n" ++ identitySource kind "coreProjectFacade")
  refuse profile "Entry" [reexportClient, ordinaryFacade, reexportLibrary] true
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
  let library := psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library"
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


private def componentScopeSources (kind : PsCompilerSourceKind) :
    List (String × String × List String) :=
  let header := match kind with | .lean => "module\n" | .proofScript => ""
  let publicSection := match kind with | .lean => "public section\n" | .proofScript => "section\n"
  let captured := fun name => match kind with
    | .lean => "def " ++ name ++ " (x : A) : A := x\n"
    | .proofScript => "function " ++ name ++ "(x: A): A := x\n"
  let start := header ++ publicSection
  let middle :=
    "variable (A : Type)\n" ++ captured "inner" ++ "end Inner\n" ++
    "variable (A : Type)\n" ++ captured "outer" ++ "end CoreDotted\n" ++
    "variable (A : Type)\n" ++ captured "componentRoot" ++ "end\n"
  let separate := "namespace CoreSeparate\nnamespace Inner\n" ++
    "variable (A : Type)\n" ++ captured "value"
  let afterSeparate := identitySource kind "componentAfterSeparate" ++ "end\n"
  let mixed := "namespace CoreMixed\nsection Local\n" ++
    "variable (A : Type)\n" ++ captured "value"
  let afterMixed := identitySource kind "componentAfterMixed" ++ "end\n"
  let sectionWord := match kind with | .lean => "public section " | .proofScript => "section "
  let sectionBody :=
    identitySource kind "componentSectionInner" ++ "end Inner\n" ++
    identitySource kind "componentSectionOuter" ++ "end CoreSection\n" ++
    (match kind with | .lean => "" | .proofScript => "private ") ++
    identitySource kind "componentSectionAfter" ++
    scopeIdentity kind (match kind with | .lean => "public " | .proofScript => "")
      "componentSectionFinal" "componentSectionAfter"
  [
    (start ++ "namespace CoreDotted.Inner\n" ++ middle,
     start ++ "namespace CoreDotted\nnamespace Inner\n" ++ middle,
     ["CoreDotted.Inner.inner", "CoreDotted.outer", "componentRoot"]),
    (start ++ separate ++ "end CoreSeparate.Inner\n" ++ afterSeparate,
     start ++ separate ++ "end Inner\nend CoreSeparate\n" ++ afterSeparate,
     ["CoreSeparate.Inner.value", "componentAfterSeparate"]),
    (start ++ mixed ++ "end CoreMixed.Local\n" ++ afterMixed,
     start ++ mixed ++ "end Local\nend CoreMixed\n" ++ afterMixed,
     ["CoreMixed.value", "componentAfterMixed"]),
    (header ++ sectionWord ++ "CoreSection.Inner\n" ++ sectionBody,
     header ++ sectionWord ++ "CoreSection\n" ++ sectionWord ++ "Inner\n" ++ sectionBody,
     ["componentSectionInner", "componentSectionOuter", "componentSectionFinal"])]

private def checkComponentScopes : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List (List String) := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let mut admissions : List String := []
    for (source, expanded, expectedNames) in componentScopeSources kind do
      let output ← prepare profile "Entry" [input kind "Entry" source]
      let reference ← prepare profile "Entry" [input kind "Entry" expanded]
      let _ ← admit seed output.admissions
      let _ ← admit seed reference.admissions
      ensure (output.admissions == reference.admissions)
        "component scopes differ from explicitly nested/closed scopes"
      let names := expectedNames.map fun name =>
        psSyntaxNameAppendSegments (name.splitOn ".") .anonymous
      let interface ← importVisibilityInterface output
      ensure (sameNames output.mainNames names &&
          sameNames (interface.declarations.map psDeclarationName) names)
        "component scope namespace or public visibility restoration changed"
      for name in names do
        let some declaration := output.prepared.declarations.find?
            (fun declaration => psNameEq (psDeclarationName declaration) name)
          | fail "component scope declaration missing"
        ensure ((psDeclarationLevelParams declaration).isEmpty &&
            psExprAlphaEq (psDeclarationType declaration) idType)
          "component scope did not restore and recapture the variable telescope"
      if expectedNames.contains "componentSectionFinal" then
        let privateName := psNameAppendStr
          (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Entry") "componentSectionAfter"
        let some receipt := output.moduleProfiles.find? (fun item => item.name == "Entry")
          | fail "component public-section receipt missing"
        ensure (sameNames receipt.privateNames [privateName])
          "dotted public section did not restore its prior private default"
      admissions := admissions ++ [output.admissions]
    paired := paired ++ [admissions]
    let header := match kind with | .lean => "module\n" | .proofScript => ""
    let refusals : List (String × String) := [
      ("namespace A\nend\n", "end requires the innermost scope name"),
      ("section A\nend\n", "end requires the innermost scope name"),
      ("namespace A\nnamespace B\nend A\n", "end name does not match the innermost scope"),
      ("namespace A.B\nend B.A\n", "end name does not match the innermost scope"),
      ("namespace A\nsection\nnamespace B\nend A.B\n", "end name does not match the innermost scope"),
      ("section\nend A\n", "end name does not match the innermost scope"),
      ("namespace A\nend X.A\n", "end name contains too many components"),
      ("end\n", "end without an open scope")]
    for (source, message) in refusals do
      refuse profile "Entry" [input kind "Entry" (header ++ source)] true
        ("PSCV0-SCOPE: " ++ message)
  let [leanAdmissions, psAdmissions] := paired
    | fail "component scope paired source count changed"
  ensure (leanAdmissions.length == 4 && leanAdmissions == psAdmissions)
    "Lean and PS component-scope canonical admissions differ"
  IO.println "PSCV0_CORE_COMPONENT_SCOPES: 16 positive projects, 16 owned refusals, paired canonical admission, component namespace/section closure, variable restoration and sequential public defaults passed"


private def legacyProviderPieces : List (String × String) := [
  ("public def coreLegacyDirect (A : Type) (x : A) : A := x\n",
   "function coreLegacyDirect(A: Type, x: A): A := x\n"),
  ("private def coreLegacyHelper (A : Type) (x : A) : A := x\n",
   "private function coreLegacyHelper(A: Type, x: A): A := x\n"),
  ("public def coreLegacyViaPrivate (A : Type) (x : A) : A := coreLegacyHelper A x\n",
   "function coreLegacyViaPrivate(A: Type, x: A): A := coreLegacyHelper(A, x)\n"),
  ("public abbrev coreLegacyAlias (A : Type) (x : A) : A := coreLegacyDirect A x\n",
   "abbrev coreLegacyAlias(A: Type, x: A): A := coreLegacyDirect(A, x)\n"),
  ("public opaque coreLegacyOpaque (A : Type) (x : A) : A := x\n",
   "opaque coreLegacyOpaque(A: Type, x: A): A := x\n"),
  ("public theorem coreLegacySpec (A : Type) (x : A) : coreLegacyViaPrivate A x = x := by rfl\n",
   "theorem coreLegacySpec(A: Type, x: A): coreLegacyViaPrivate(A, x) = x := by { rfl }\n")]

private def legacyProvider (kind : PsCompilerSourceKind) (nativeModule : Bool) :
    PsPscv0ModuleSource :=
  let body := legacyProviderPieces.foldl (fun acc piece => acc ++
    (match kind with | .lean => piece.fst | .proofScript => piece.snd)) ""
  input kind "Library" ((match kind with
    | .lean => if nativeModule then "module\n" else ""
    | .proofScript => "") ++ body)

private def legacyRfl (name callee : String) : String :=
  "theorem " ++ name ++ " (A : Type) (x : A) : " ++ callee ++ " A x = x := by rfl\n"

private def legacyClientBody : String :=
  legacyRfl "coreLegacyDirectRfl" "coreLegacyDirect" ++
  legacyRfl "coreLegacyPrivateRfl" "coreLegacyViaPrivate" ++
  legacyRfl "coreLegacyAliasRfl" "coreLegacyAlias" ++
  "theorem coreLegacyViaSpec (A : Type) (x : A) : coreLegacyViaPrivate A x = x := coreLegacySpec A x\n"

private def checkLegacyImports : IO Unit := do
  let (seed, profile) ← scopeContext
  let helperName := psNameAppendStr
    (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreLegacyHelper"
  let providerNames := [psRootName "coreLegacyDirect", helperName,
    psRootName "coreLegacyViaPrivate", psRootName "coreLegacyAlias",
    psRootName "coreLegacyOpaque", psRootName "coreLegacySpec"]
  let entryNames := ["coreLegacyDirectRfl", "coreLegacyPrivateRfl",
    "coreLegacyAliasRfl", "coreLegacyViaSpec"].map psRootName
  let entry := input .lean "Entry" ("import Library\n" ++ legacyClientBody)
  let legacy := legacyProvider .lean false
  let reference ← prepare profile "Entry" [entry, legacy]
  let check := fun (output : PsCompilerEngineProjectOutput) (modules : List String) => do
    let _ ← admit seed output.admissions
    ensure (output.admissions == reference.admissions &&
        sameNames (output.prepared.declarations.map psDeclarationName)
          (providerNames ++ entryNames) &&
        sameNames output.libraryNames providerNames &&
        sameNames output.mainNames entryNames)
      "legacy import changed canonical closure or entry ownership"
    ensure (output.moduleProfiles.length == modules.length &&
        modules.all (fun name => output.moduleProfiles.any (fun item => item.name == name)))
      "legacy import escaped its reachable module closure"
    ensure (output.prepared.profile.baseEnvironment.declarations.length == 4 &&
        !psEnvironmentContains output.prepared.profile.baseEnvironment (psRootName "coreLegacyDirect"))
      "legacy imported declarations mutated the caller base"
    let .definitionDecl _ _ _ body ← importVisibilityDeclaration output "coreLegacyViaPrivate"
      | fail "legacy wrapper lost its checked definition"
    ensure ((psPscv0ExprConstants body).any (psNameEq helperName))
      "legacy wrapper lost its private implementation dependency"
    let some (.definitionDecl ..) := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) helperName)
      | fail "legacy private helper missing from checked closure"
    let .opaqueDecl .. ← importVisibilityDeclaration output "coreLegacyOpaque"
      | fail "legacy import made a genuine opaque transparent"
    let .theoremDecl .. ← importVisibilityDeclaration output "coreLegacySpec"
      | fail "legacy import changed theorem kind"
    let some library := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "legacy library public receipt missing"
    ensure (sameNames library.privateNames [helperName] &&
        !library.interface.declarations.any (fun declaration =>
          psNameEq (psDeclarationName declaration) helperName))
      "legacy loading altered the public private-name boundary"
    let some (.opaqueDecl ..) := library.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) (psRootName "coreLegacyDirect"))
      | fail "legacy loading weakened the module public body view"
  check reference ["Library", "Entry"]
  let rflRefusal := "PSCV0-PROOF: rfl requires definitionally equal sides"
  for library in [legacy, legacyProvider .lean true, legacyProvider .proofScript true] do
    refuse profile "Entry"
      [input .lean "Entry" ("import Library\n" ++ legacyRfl "coreLegacyOpaqueRfl" "coreLegacyOpaque"), library]
      true rflRefusal
    refuse profile "Entry"
      [input .lean "Entry" ("import Library\ndef coreLegacyLeak (A : Type) (x : A) : A := coreLegacyHelper A x\n"), library]
      true "PSCV0-SCOPE: unknown name coreLegacyHelper"
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := legacyProvider kind true
    check (← prepare profile "Entry" [entry, library]) ["Library", "Entry"]
    let facade := importVisibilityInput kind "Facade" "import Library\n" []
    let transitive := input .lean "Entry" ("import Facade\n" ++ legacyClientBody)
    check (← prepare profile "Entry" [transitive, facade, library]) ["Library", "Facade", "Entry"]
    let left := importVisibilityInput kind "Left" "import Library\n" []
    let right := importVisibilityInput kind "Right" "import Library\n" []
    for imports in ["import Left\nimport Right\n", "import Right\nimport Left\n"] do
      check (← prepare profile "Entry"
        [input .lean "Entry" (imports ++ legacyClientBody), right, left, library])
        ["Library", "Left", "Right", "Entry"]
    let unreachable := input .lean "Unreachable"
      "module\npublic def coreLegacyUnused (A : Type) (x : A) : A := coreLegacyMissing A x\n"
    check (← prepare profile "Entry" [entry, unreachable, library]) ["Library", "Entry"]
    refuse profile "Entry"
      [input .lean "Entry" ("module\npublic import Library\npublic " ++
        legacyRfl "coreLegacyModuleRfl" "coreLegacyDirect"), library]
      true rflRefusal
    refuse profile "Entry"
      [input .lean "Entry" "module\npublic import Facade\npublic def coreLegacyHiddenTransitive (A : Type) (x : A) : A := coreLegacyDirect A x\n",
       facade, library]
      true "PSCV0-SCOPE: unknown name coreLegacyDirect"
  IO.println "PSCV0_CORE_LEGACY_IMPORT: 11 positive projects, 10 owned refusals, independent canonical admission, ordinary/private body closure, genuine opacity, transitive imports, diamond deduplication and reachable isolation passed"


private def checkLegacyLocalPrivate : IO Unit := do
  let (seed, profile) ← scopeContext
  let cases : List (List (String × String) × String × String × Bool) := [
    ([("private def coreLegacyType (A : Type) : Type := A\n",
       "private function coreLegacyType(A: Type): Type := A\n"),
      ("public def coreLegacySignature (A : Type) (x : coreLegacyType A) (y : A) : A := y\n",
       "function coreLegacySignature(A: Type, x: coreLegacyType(A), y: A): A := y\n")],
     "coreLegacySignature", "coreLegacyType", false),
    ([("private def coreLegacyHelper (A : Type) (x : A) : A := x\n",
       "private function coreLegacyHelper(A: Type, x: A): A := x\n"),
      ("public abbrev coreLegacyExposed (A : Type) (x : A) : A := coreLegacyHelper A x\n",
       "abbrev coreLegacyExposed(A: Type, x: A): A := coreLegacyHelper(A, x)\n")],
     "coreLegacyExposed", "coreLegacyHelper", true)]
  for (pieces, name, hidden, exposed) in cases do
    let body := pieces.foldl (fun acc piece => acc ++ piece.fst) ""
    let output ← prepare profile "Entry" [input .lean "Entry" body]
    let _ ← admit seed output.admissions
    let hiddenName := psNameAppendStr
      (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Entry") hidden
    let name := psRootName name
    ensure (sameNames (output.prepared.declarations.map psDeclarationName) [hiddenName, name] &&
        sameNames output.mainNames [name])
      "legacy local-private checked ownership changed"
    let some declaration := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) name)
      | fail "legacy local-private declaration missing"
    let dependencies ←
      if exposed then
        match declaration with
        | .definitionDecl _ _ _ value => pure (psPscv0ExprConstants value)
        | _ => fail "legacy private-dependent abbreviation changed kind"
      else
        pure (psPscv0ExprConstants (psDeclarationType declaration))
    ensure (dependencies.any (psNameEq hiddenName))
      "legacy local-private dependency was erased from the checked declaration"
    let some receipt := output.moduleProfiles.head?
      | fail "legacy local-private receipt missing"
    ensure (sameNames receipt.privateNames [hiddenName] &&
        sameNames (receipt.interface.declarations.map psDeclarationName) [name])
      "legacy local-private public identity boundary changed"
    if exposed then
      ensure (sameNames receipt.exposedNames [name])
        "legacy abbreviation exposure marker disappeared"
    for kind in [PsCompilerSourceKind.lean, .proofScript] do
      refuse profile "Entry" [importVisibilityInput kind "Entry" "" pieces] true
        ((if exposed then "PSCV0-MODULE: exposed body references private name in "
          else "PSCV0-MODULE: public signature references private name in ") ++ psNameToString name)
  IO.println "PSCV0_CORE_LEGACY_PRIVATE: two admitted local-private type/body projects, four module-mode refusals and retained checked dependencies passed"

private def legacyMetadataPieces : List (String × String) := [
  ("public class CoreLegacyEcho (A : Type) where\n  run : A -> A\n",
   "class CoreLegacyEcho(A: Type) where { run: A -> A }\n"),
  ("@[default_instance 700] private instance coreLegacyEcho {A : Type} : CoreLegacyEcho A where\n  run := fun (x : A) => x\n",
   "@[default_instance 700] private instance coreLegacyEcho{A: Type}: CoreLegacyEcho A where { run := fun (x: A) => x }\n"),
  ("public abbrev coreLegacyEchoAlias (A : Type) : Type := A\n",
   "abbrev coreLegacyEchoAlias(A: Type): Type := A\n")]

private def legacyMetadataEntry (priority : Nat) (entry : PsInstanceEntry) : Bool :=
  let hidden := psNameAppendStr
    (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreLegacyEcho"
  entry.priority == priority && entry.levelParams.isEmpty &&
    (match entry.value with
     | .constE name levels => psNameEq name hidden && levels.isEmpty
     | _ => false) &&
    (match entry.className with
     | some name => psNameEq name (psRootName "CoreLegacyEcho")
     | none => false)

private def checkLegacyMetadata : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := importVisibilityInput kind "Library" "" legacyMetadataPieces
    let client := input .lean "Entry"
      "import Library\ntheorem coreLegacyEchoRfl (A : Type) (x : A) : CoreLegacyEcho.run x (A := A) = x := by rfl\n"
    let output ← prepare profile "Entry" [client, library]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let some receipt := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "legacy metadata public receipt missing"
    ensure (receipt.interface.instances.isEmpty && receipt.interface.defaults.isEmpty)
      "private legacy dictionary leaked into the module public metadata"
    -- Inspect the same real source metadata, without adding anything to the checked seed.
    let parsed ← match psCompilerParsePscv0Program kind library.source with
      | .ok parsed => pure parsed
      | .error message => fail message
    let elaborated ← match psElabProgramWithOrigins profile.baseEnvironment parsed "Library" with
      | .ok elaborated => pure elaborated
      | .error error => fail (psCompilerPscv0ElabError error)
    let view := psPscv0DeclarationInterface elaborated.result.environment elaborated.result.declarations
    let diamond := psPscv0InterfaceMerge view view
    let imported ← match psPscv0InstallInterface profile.baseEnvironment diamond with
      | .ok imported => pure imported
      | .error message => fail message
    let imported ← match psPscv0InstallInterface imported diamond with
      | .ok imported => pure imported
      | .error message => fail message
    ensure (sameNames imported.classes [psRootName "CoreLegacyEcho"] &&
        imported.classParameters.length == 1 &&
        imported.classParameters.all (fun item =>
          psNameEq item.fst (psRootName "CoreLegacyEcho") &&
          item.snd.outputs.isEmpty && item.snd.outputLevels.isEmpty))
      "legacy class registration or parameter metadata changed"
    ensure (imported.instances.entries.length == 1 &&
        imported.instances.entries.all (legacyMetadataEntry 1000) &&
        imported.instances.defaults.length == 1 &&
        imported.instances.defaults.all (legacyMetadataEntry 700))
      "legacy diamond changed ordinary/default instance identity, priority or multiplicity"
    let hidden := psNameAppendStr
      (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreLegacyEcho"
    ensure ((match psEnvironmentReducibility imported hidden with
        | .instanceReducible => true | _ => false) &&
      (match psEnvironmentReducibility imported (psRootName "coreLegacyEchoAlias") with
        | .reducible => true | _ => false) &&
      imported.declarations.length == profile.baseEnvironment.declarations.length + view.declarations.length)
      "legacy installation lost reducibility or duplicated checked declarations"
    refuse profile "Entry"
      [input .lean "Entry"
        "import Library\ndef coreLegacyInstanceLeak (A : Type) : CoreLegacyEcho A := coreLegacyEcho\n",
       library] true "PSCV0-SCOPE: unknown name coreLegacyEcho"
  let [leanAdmissions, psAdmissions] := paired
    | fail "legacy metadata source pair missing"
  ensure (leanAdmissions == psAdmissions) "legacy metadata paired admissions differ"
  IO.println "PSCV0_CORE_LEGACY_METADATA: two paired admitted projects, two private-instance name refusals, actual legacy synthesis, ordinary/default registry identity and priority, reducibility and diamond installation passed"


private def rootedScopeSource (kind : PsCompilerSourceKind) : String :=
  match kind with
  | .lean =>
      "module\npublic section\nnamespace Outer\nnamespace _root_.Inner\n" ++
      "def nestedIdentity (A : Type) (x : A) : A := x\n" ++
      "end _root_.Inner\nend Outer\nnamespace _root_.Inner\n" ++
      "def directIdentity (A : Type) (x : A) : A := x\n" ++
      "abbrev exposedIdentity (A : Type) (x : A) : A := directIdentity A x\n" ++
      "def inferredIdentity (A : Type) (x : A) := x\n" ++
      "def whereIdentity (A : Type) (x : A) : A := whereIdentity.helper x\n" ++
      "where\n  helper (y : A) : A := y\n" ++
      "mutual\n" ++
      "  def mutualFirst (A : Type) (x : A) : A := mutualSecond A x\n" ++
      "  def mutualSecond (A : Type) (x : A) : A := x\nend\n" ++
      "private def privateIdentity (A : Type) (x : A) : A := x\n" ++
      "def privateBridge (A : Type) (x : A) : A := privateIdentity A x\n" ++
      "structure RootBox (A : Type) where\n  value : A\n" ++
      "def _root_.absoluteIdentity (A : Type) (x : A) : A := x\n" ++
      "end _root_.Inner\n" ++
      "def rootedClient (A : Type) (x : A) : A := _root_._root_.Inner.directIdentity A x\n" ++
      "def nestedClient (A : Type) (x : A) : A := Outer._root_.Inner.nestedIdentity A x\nend\n"
  | .proofScript =>
      "section\nnamespace Outer\nnamespace _root_.Inner\n" ++
      "function nestedIdentity(A: Type, x: A): A := x\n" ++
      "end _root_.Inner\nend Outer\nnamespace _root_.Inner\n" ++
      "function directIdentity(A: Type, x: A): A := x\n" ++
      "abbrev exposedIdentity(A: Type, x: A): A := directIdentity(A, x)\n" ++
      "function inferredIdentity(A: Type, x: A) := x\n" ++
      "function whereIdentity(A: Type, x: A): A := whereIdentity.helper(x)\n" ++
      "where {\n  def helper(y: A): A := y\n}\n" ++
      "mutual\n" ++
      "  function mutualFirst(A: Type, x: A): A := mutualSecond(A, x)\n" ++
      "  function mutualSecond(A: Type, x: A): A := x\nend\n" ++
      "private function privateIdentity(A: Type, x: A): A := x\n" ++
      "function privateBridge(A: Type, x: A): A := privateIdentity(A, x)\n" ++
      "structure RootBox(A: Type) where { value: A }\n" ++
      -- ProofScript declaration heads are unqualified. Closing this scope
      -- preserves the paired order; Lean above exercises the absolute head.
      "end _root_.Inner\n" ++
      "function absoluteIdentity(A: Type, x: A): A := x\n" ++
      "function rootedClient(A: Type, x: A): A := _root_._root_.Inner.directIdentity(A, x)\n" ++
      "function nestedClient(A: Type, x: A): A := Outer._root_.Inner.nestedIdentity(A, x)\nend\n"

private def checkRootedScopes : IO Unit := do
  let (seed, profile) ← scopeContext
  let literalRoot := psNameAppendStr (psRootName "_root_") "Inner"
  let nestedRoot := psNameAppendStr (psNameAppendStr (psRootName "Outer") "_root_") "Inner"
  let sourceNames := [psNameAppendStr nestedRoot "nestedIdentity"] ++
    (["directIdentity", "exposedIdentity", "inferredIdentity", "whereIdentity",
      "mutualFirst", "mutualSecond", "privateBridge", "RootBox"].map
      (psNameAppendStr literalRoot)) ++
    (["absoluteIdentity", "rootedClient", "nestedClient"].map psRootName)
  let box := psNameAppendStr literalRoot "RootBox"
  let hidden := psNameAppendStr
    (psNameAppendStr (psNameAppendStr (psNameAppendStr
      (PsName.num (psRootName "$psc0Private") 0) "Entry") "_root_") "Inner") "privateIdentity"
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let output ← prepare profile "Entry" [input kind "Entry" (rootedScopeSource kind)]
    let _ ← admit seed output.admissions
    let interface ← importVisibilityInterface output
    let publicNames := interface.declarations.map psDeclarationName
    ensure (sourceNames.all (fun name =>
        publicNames.any (psNameEq name) && output.mainNames.any (psNameEq name)))
      "literal root namespace lost a public source declaration"
    let find := fun name =>
      output.prepared.declarations.find? (fun declaration => psNameEq (psDeclarationName declaration) name)
    let some (.inductiveDecl info) := find box | fail "literal root structure missing"
    ensure (info.isStructure && sameNames info.constructors [psNameAppendStr box "mk"])
      "literal root structure constructor identity changed"
    let some (.constructorDecl constructor) := find (psNameAppendStr box "mk")
      | fail "literal root constructor missing"
    let some (.recursorDecl recursor) := find (psNameAppendStr box "rec")
      | fail "literal root recursor missing"
    ensure (psNameEq constructor.inductiveName box &&
        sameNames recursor.inductiveNames [box] &&
        ["mk", "rec", "value"].all (fun suffix =>
          publicNames.any (psNameEq (psNameAppendStr box suffix))))
      "literal root family or projection owner changed"
    let some (.definitionDecl _ _ projectionType _) := find (psNameAppendStr box "value")
      | fail "literal root projection missing"
    ensure ((psPscv0ExprConstants projectionType).any (psNameEq box))
      "literal root projection lost its actual structure dependency"
    let some (.definitionDecl ..) := find hidden | fail "literal root private helper missing"
    let some receipt := output.moduleProfiles.head? | fail "literal root receipt missing"
    ensure (receipt.privateNames.any (psNameEq hidden) &&
        receipt.privateNames.all (fun name => !publicNames.any (psNameEq name)))
      "literal root private implementation entered the public interface"
    let whereName := psNameAppendStr literalRoot "whereIdentity"
    let whereHelper := psNameAppendStr
      (psElabPrivateName ["Entry", "_root_", "Inner", "whereIdentity"]) "helper"
    let some (.definitionDecl ..) := find whereHelper
      | fail "literal root where helper lost its private checked name"
    let some (.definitionDecl _ _ _ whereBody) := find whereName
      | fail "literal root where parent missing"
    ensure (receipt.privateNames.any (psNameEq whereHelper) &&
        !publicNames.any (psNameEq whereHelper) &&
        (psPscv0ExprConstants whereBody).any (psNameEq whereHelper))
      "literal root where helper privacy or dependency changed"
    let some origin := output.origins.find? (fun item => item.moduleName == "Entry")
      | fail "literal root module provenance missing"
    let helpers := origin.batches.flatMap (·.localDefinitions)
    let some helperOrigin := helpers.find? (fun item => psNameEq item.name whereHelper)
      | fail "literal root where helper provenance missing"
    ensure (helperOrigin.declarations.any (psNameEq whereHelper) &&
        helperOrigin.declarations.all (fun name =>
          receipt.privateNames.any (psNameEq name) &&
          !publicNames.any (psNameEq name)))
      "literal root where helper provenance lost private ownership"
    let some (.definitionDecl _ _ _ bridge) := find (psNameAppendStr literalRoot "privateBridge")
      | fail "literal root private bridge missing"
    ensure ((psPscv0ExprConstants bridge).any (psNameEq hidden))
      "literal root private alias resolved to another namespace"
    let some (.definitionDecl _ _ _ client) := find (psRootName "rootedClient")
      | fail "literal root client missing"
    ensure ((psPscv0ExprConstants client).any
        (psNameEq (psNameAppendStr literalRoot "directIdentity")) &&
      !(output.prepared.declarations.any (fun declaration =>
        psNameEq (psDeclarationName declaration)
          (psNameAppendStr (psRootName "Inner") "directIdentity"))))
      "absolute reference confused a literal root namespace with a root marker"
    paired := paired ++ [output.admissions]
  let [leanAdmissions, psAdmissions] := paired | fail "literal root source pair missing"
  ensure (leanAdmissions == psAdmissions) "literal root paired canonical admissions differ"
  IO.println "PSCV0_CORE_ROOTED_SCOPES: two paired admitted projects, literal root namespaces, absolute declarations/references, direct/registered/inferred/where/mutual names, family ownership, private helper provenance and private aliases passed"

private def legacyWherePieces : List (String × String) := [
  ("public def coreLegacyWhere (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := y\n",
   "function coreLegacyWhere(A: Type, x: A): A := helper(x)\nwhere {\n  def helper(y: A): A := y\n}\n"),
  ("public def coreLegacyWhereLocal (A : Type) (x : A) : A := coreLegacyWhere.helper A x\n",
   "function coreLegacyWhereLocal(A: Type, x: A): A := coreLegacyWhere.helper(A, x)\n")]

private def legacyWhereClientBody : String :=
  legacyRfl "coreLegacyWhereRfl" "coreLegacyWhere" ++
  legacyRfl "coreLegacyWhereLocalRfl" "coreLegacyWhereLocal"

private def checkLegacyWhere : IO Unit := do
  let (seed, profile) ← scopeContext
  let wrapperName := psRootName "coreLegacyWhere"
  let localName := psRootName "coreLegacyWhereLocal"
  let sourceHelper := psNameAppendStr wrapperName "helper"
  let wrapperEq := psNameAppendStr wrapperName "eq_def"
  let entryNames := [psRootName "coreLegacyWhereRfl", psRootName "coreLegacyWhereLocalRfl"]
  let check := fun (output : PsCompilerEngineProjectOutput) (isModule : Bool) => do
    let _ ← admit seed output.admissions
    let helperName := if isModule then
      psNameAppendStr (psNameAppendStr
        (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreLegacyWhere") "helper"
      else sourceHelper
    let helperEq := psNameAppendStr helperName "eq_def"
    let expectedEntries := entryNames ++
      (if isModule then [] else [psRootName "coreLegacyWhereHelperRfl"])
    let expectedProvider := [helperName, helperEq, wrapperName, wrapperEq, localName]
    ensure (sameNames (output.prepared.declarations.map psDeclarationName)
        (expectedProvider ++ expectedEntries) &&
        sameNames output.libraryNames expectedProvider &&
        sameNames output.mainNames expectedEntries)
      "where helper checked closure or entry ownership changed"
    let some library := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "where helper library receipt missing"
    let hidden := if isModule then [wrapperEq, helperName, helperEq] else [wrapperEq, helperEq]
    ensure (library.privateNames.length == hidden.length &&
        hidden.all (fun name => library.privateNames.any (psNameEq name)))
      "where helper private ownership roster changed"
    let publicNames := (if isModule then [] else [sourceHelper]) ++ [wrapperName, localName]
    ensure (sameNames (library.interface.declarations.map psDeclarationName) publicNames)
      "where helper public interface changed"
    let some (.definitionDecl ..) := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) helperName)
      | fail "where helper lost its checked definition"
    for name in [wrapperEq, helperEq] do
      let some (.theoremDecl ..) := output.prepared.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail "where helper equation lost its checked theorem"
    for name in ["coreLegacyWhere", "coreLegacyWhereLocal"] do
      let .definitionDecl _ _ _ body ← importVisibilityDeclaration output name
        | fail "where wrapper/local caller changed declaration kind"
      ensure ((psPscv0ExprConstants body).any (psNameEq helperName))
        "where wrapper/local caller lost the real helper dependency"
    let some origin := output.origins.find? (fun item => item.moduleName == "Library")
      | fail "where helper module provenance missing"
    let some batch := origin.batches.head?
      | fail "where helper source batch missing"
    let [helperOrigin] := batch.localDefinitions
      | fail "where helper source ownership count changed"
    ensure (psNameEq helperOrigin.name helperName &&
        sameNames helperOrigin.declarations [helperName, helperEq])
      "where helper provenance differs from checked ownership"
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := importVisibilityInput kind "Library" "" legacyWherePieces
    let output ← prepare profile "Entry"
      [input .lean "Entry" ("import Library\n" ++ legacyWhereClientBody), library]
    check output true
    paired := paired ++ [output.admissions]
    for imports in ["import Library\n", "module\npublic import Library\n"] do
      refuse profile "Entry"
        [input .lean "Entry" (imports ++
          "public def coreLegacyWhereLeak (A : Type) (x : A) : A := coreLegacyWhere.helper A x\n"), library]
        true "PSCV0-UNKNOWN-NAME: coreLegacyWhere.helper"
    refuse profile "Entry"
      [input .lean "Entry" ("module\npublic import Library\npublic " ++
        legacyRfl "coreLegacyWhereModuleRfl" "coreLegacyWhere"), library]
      true "PSCV0-PROOF: rfl requires definitionally equal sides"
  let [leanAdmissions, psAdmissions] := paired
    | fail "where helper paired source count changed"
  ensure (leanAdmissions == psAdmissions) "where helper paired admissions differ"
  let legacyBody := legacyWherePieces.foldl (fun acc piece => acc ++ piece.fst) ""
  let legacy ← prepare profile "Entry"
    [input .lean "Entry" ("import Library\n" ++ legacyWhereClientBody ++
       legacyRfl "coreLegacyWhereHelperRfl" "coreLegacyWhere.helper"),
     input .lean "Library" legacyBody]
  check legacy false
  IO.println "PSCV0_CORE_LEGACY_WHERE: three admitted projects, six owned refusals, paired canonical admission, private module helper closure, provider-local alias retention, legacy public helper and checked provenance passed"

private def registeredValuePieces : List (String × String) := [
  ("public abbrev coreRegisteredIdentity (A : Type) (x : A) := x\n",
   "abbrev coreRegisteredIdentity(A: Type, x: A) := x\n"),
  ("public abbrev coreRegisteredWhere (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := y\n",
   "abbrev coreRegisteredWhere(A: Type, x: A): A := helper(x)\nwhere {\n  def helper(y: A): A := y\n}\n"),
  ("public class CoreRegisteredEcho (A : Type) where\n  run : A -> A\n",
   "class CoreRegisteredEcho(A: Type) where { run: A -> A }\n"),
  ("public instance coreRegisteredEcho {A : Type} : CoreRegisteredEcho A where\n  run := fun (x : A) => x\n",
   "instance coreRegisteredEcho{A: Type}: CoreRegisteredEcho A where { run := fun (x: A) => x }\n"),
  ("public class CoreRegisteredLaw (A : Type) (x : A) : Prop where\n  selfEq : x = x\n",
   "class CoreRegisteredLaw(A: Type, x: A): Prop where { selfEq: x = x }\n"),
  ("public instance coreRegisteredLaw {A : Type} (x : A) : CoreRegisteredLaw A x where\n  selfEq := by rfl\n",
   "instance coreRegisteredLaw{A: Type}(x: A): CoreRegisteredLaw(A, x) where { selfEq := by { rfl } }\n"),
  ("@[default_instance 700] public def coreRegisteredDefault {A : Type} := ({ run := fun (x : A) => x } : CoreRegisteredEcho A)\n",
   "@[default_instance 700] def coreRegisteredDefault{A: Type} := ({ run := fun (x: A) => x }: CoreRegisteredEcho(A))\n")]

private def registeredClientPieces : List (String × String) := [
  ("public theorem coreRegisteredIdentityRfl (A : Type) (x : A) : coreRegisteredIdentity A x = x := by rfl\n",
   "theorem coreRegisteredIdentityRfl(A: Type, x: A): coreRegisteredIdentity(A, x) = x := by { rfl }\n"),
  ("public theorem coreRegisteredWhereRfl (A : Type) (x : A) : coreRegisteredWhere A x = x := by rfl\n",
   "theorem coreRegisteredWhereRfl(A: Type, x: A): coreRegisteredWhere(A, x) = x := by { rfl }\n"),
  ("public theorem coreRegisteredHelperRfl (A : Type) (x : A) : coreRegisteredWhere.helper A x = x := by rfl\n",
   "theorem coreRegisteredHelperRfl(A: Type, x: A): coreRegisteredWhere.helper(A, x) = x := by { rfl }\n"),
  ("public theorem coreRegisteredEchoRfl (A : Type) (x : A) : CoreRegisteredEcho.run x (A := A) = x := by rfl\n",
   "theorem coreRegisteredEchoRfl(A: Type, x: A): CoreRegisteredEcho.run(x, A := A) = x := by { rfl }\n"),
  ("public theorem coreRegisteredProofValue (A : Type) (x : A) : CoreRegisteredLaw A x := coreRegisteredLaw x\n",
   "theorem coreRegisteredProofValue(A: Type, x: A): CoreRegisteredLaw(A, x) := coreRegisteredLaw(x)\n"),
  ("public theorem coreRegisteredProofField (A : Type) (x : A) : x = x := CoreRegisteredLaw.selfEq (A := A) (x := x)\n",
   "theorem coreRegisteredProofField(A: Type, x: A): x = x := CoreRegisteredLaw.selfEq(A := A, x := x)\n")]

private def checkRegisteredValues : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := importVisibilityInput kind "Library" "" registeredValuePieces
    let client := importVisibilityInput kind "Entry" "public import Library\n" registeredClientPieces
    let output ← prepare profile "Entry" [client, library]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let some receipt := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "registered value source receipt missing"
    for text in ["coreRegisteredIdentity", "coreRegisteredWhere", "coreRegisteredWhere.helper",
        "CoreRegisteredEcho.run", "coreRegisteredEcho"] do
      let name := psSyntaxNameAppendSegments (text.splitOn ".") .anonymous
      let some (.definitionDecl ..) := receipt.interface.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("registered public body not exposed: " ++ text)
      ensure (receipt.exposedNames.any (psNameEq name) &&
          !receipt.privateNames.any (psNameEq name))
        ("registered body visibility differs from retained interface: " ++ text)
    let proofName := psRootName "coreRegisteredLaw"
    let some (.theoremDecl ..) := receipt.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) proofName)
      | fail "proof-valued source instance lost theorem kind"
    ensure (!receipt.exposedNames.any (psNameEq proofName))
      "proof-valued source instance exposed its proof body"
    let decoded ← match PsKernelLean.decodeCanonicalAdmissions output.admissions with
      | .ok declarations => pure declarations
      | .error error => fail error.message
    ensure (decoded.toList.any fun declaration => match declaration with
      | .thmDecl info => info.name == PsKernelLean.toLeanName proofName
      | _ => false)
      "actual proof-valued instance admission is not a theorem"
    let defaultName := psRootName "coreRegisteredDefault"
    let some (.opaqueDecl ..) := receipt.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) defaultName)
      | fail "default attribute exposed an ordinary definition"
    ensure (!receipt.exposedNames.any (psNameEq defaultName) &&
        receipt.interface.instances.length == 2 && receipt.interface.defaults.length == 1)
      "registered source kind or registry count changed"
    ensure (receipt.interface.defaults.all (fun entry =>
      entry.priority == 700 && match entry.value with
      | .constE name _ => psNameEq name defaultName
      | _ => false))
      "inferred default lost its exact name or priority"
    -- Registered main declarations exclude eager equation publication. The
    -- actual where helper retains its checked private equation; no nonexistent
    -- lazy native equation is added to the source-private inventory.
    for text in ["coreRegisteredIdentity.eq_def", "coreRegisteredWhere.eq_def",
        "coreRegisteredDefault.eq_def"] do
      let name := psSyntaxNameAppendSegments (text.splitOn ".") .anonymous
      ensure (!receipt.privateNames.any (psNameEq name) &&
          !output.prepared.declarations.any (fun declaration =>
            psNameEq (psDeclarationName declaration) name) &&
          !receipt.interface.declarations.any (fun declaration =>
            psNameEq (psDeclarationName declaration) name))
        ("registered main unexpectedly published an equation: " ++ text)
    let helperEquation := psSyntaxNameAppendSegments
      ["coreRegisteredWhere", "helper", "eq_def"] .anonymous
    ensure (receipt.privateNames.any (psNameEq helperEquation) &&
        output.prepared.declarations.any (fun declaration => match declaration with
          | .theoremDecl name .. => psNameEq name helperEquation
          | _ => false) &&
        !receipt.interface.declarations.any (fun declaration =>
          psNameEq (psDeclarationName declaration) helperEquation))
      "registered where helper lost its checked private equation"
    let privateValue := importVisibilityInput kind "Library" "" [
  ("private def coreRegisteredHidden (A : Type) (x : A) : A := x\n",
   "private function coreRegisteredHidden(A: Type, x: A): A := x\n"),
  ("public abbrev coreRegisteredLeak (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := coreRegisteredHidden A y\n",
   "abbrev coreRegisteredLeak(A: Type, x: A): A := helper(x)\nwhere {\n  def helper(y: A): A := coreRegisteredHidden(A, y)\n}\n")]
    refuse profile "Library" [privateValue] true
      "PSCV0-MODULE: exposed body references private name"
    let nonClass := importVisibilityInput kind "Library" "" [
  ("@[default_instance] public def coreRegisteredBad (A : Type) (x : A) := x\n",
   "@[default_instance] def coreRegisteredBad(A: Type, x: A) := x\n")]
    refuse profile "Library" [nonClass] true
      "PSCV0-DATA: instance result must be a registered class"
  let [leanAdmissions, psAdmissions] := paired
    | fail "registered value reader pair missing"
  ensure (leanAdmissions == psAdmissions) "registered value paired admissions differ"
  IO.println "PSCV0_CORE_REGISTERED_VALUES: two paired admitted projects, four owned refusals, inferred abbrev/default registration, public where helpers, data-instance and projection reduction, ordinary default opacity and private computational dependency controls passed"

private def connectiveAttributePieces : List (String × String) := [
  ("public def coreAttrLogicalIdentity (A : Type) (x : A) : A := x\n",
   "def coreAttrLogicalIdentity(A: Type, x: A): A := x\n"),
  ("@[simp] public theorem coreAttrGoodIff (P Q : Prop) (h : Iff P Q) : Iff P Q := h\n",
   "@[simp] theorem coreAttrGoodIff(P: Prop, Q: Prop, h: Iff(P, Q)): Iff(P, Q) := h\n"),
  ("@[simp] public theorem coreAttrGoodAnd (P Q : Prop) (hp : P) (hq : Q) : And P Q := And.intro hp hq\n",
   "@[simp] theorem coreAttrGoodAnd(P: Prop, Q: Prop, hp: P, hq: Q): And(P, Q) := And.intro(hp, hq)\n"),
  ("@[simp] public theorem coreAttrGoodAndEq (A : Type) (x y : A) : And (coreAttrLogicalIdentity A x = x) (coreAttrLogicalIdentity A y = y) := And.intro (Eq.refl x) (Eq.refl y)\n",
   "@[simp] theorem coreAttrGoodAndEq(A: Type, x: A, y: A): And(coreAttrLogicalIdentity(A, x) = x, coreAttrLogicalIdentity(A, y) = y) := And.intro(Eq.refl(x), Eq.refl(y))\n")]

private def connectiveAttributeRefusals : List (String × String × String) := [
  ("IffReflexive",
   "@[simp] public theorem coreAttrBadIff (P : Prop) : Iff P P := Iff.intro (fun (h : P) => h) (fun (h : P) => h)\n",
   "@[simp] theorem coreAttrBadIff(P: Prop): Iff(P, P) := Iff.intro(fun (h: P) => h, fun (h: P) => h)\n"),
  ("AndLeftReflexive",
   "@[simp] public theorem coreAttrBadAndLeft (A : Type) (x : A) (P : Prop) (hp : P) : And (x = x) P := And.intro (Eq.refl x) hp\n",
   "@[simp] theorem coreAttrBadAndLeft(A: Type, x: A, P: Prop, hp: P): And(x = x, P) := And.intro(Eq.refl(x), hp)\n"),
  ("AndRightReflexive",
   "@[simp] public theorem coreAttrBadAndRight (A : Type) (x : A) (P : Prop) (hp : P) : And P (x = x) := And.intro hp (Eq.refl x)\n",
   "@[simp] theorem coreAttrBadAndRight(A: Type, x: A, P: Prop, hp: P): And(P, x = x) := And.intro(hp, Eq.refl(x))\n"),
  ("AndNestedReflexive",
   "@[simp] public theorem coreAttrBadAndNested (A : Type) (x : A) (P Q : Prop) (hp : P) (hq : Q) : And P (And Q (x = x)) := And.intro hp (And.intro hq (Eq.refl x))\n",
   "@[simp] theorem coreAttrBadAndNested(A: Type, x: A, P: Prop, Q: Prop, hp: P, hq: Q): And(P, And(Q, x = x)) := And.intro(hp, And.intro(hq, Eq.refl(x)))\n")]

private def checkConnectiveAttributes : IO Unit := do
  let (_, scopeProfile) ← scopeContext
  let connectives := psLogicBinaryStructure "And" false ++ psLogicBinaryStructure "Iff" true
  ensure (connectives.length == 10 && connectives.all (fun declaration =>
    match declaration with
    | .inductiveDecl _ | .constructorDecl _ | .recursorDecl _ | .definitionDecl .. => true
    | _ => false)) "connective attribute seed introduced another declaration kind"
  let declarations := scopeProfile.baseEnvironment.declarations.reverse ++ connectives
  let checked ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations declarations
  let seed ← match checked with
    | .ok value => pure value
    | .error error => fail ("connective attribute seed: " ++ error.message)
  let environment ← connectives.foldlM (fun environment declaration => do
    let some next := psEnvironmentAdd environment declaration
      | fail "duplicate connective attribute seed declaration"
    pure next) scopeProfile.baseEnvironment
  ensure (environment.declarations.length == 14 &&
      !(psEnvironmentContains environment (psRootName "Nat")) &&
      (seed.find? `Nat).isNone)
    "connective attribute seed roster changed"
  let profile := { scopeProfile with baseEnvironment := environment }
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let source := importVisibilityInput kind "Library" "" connectiveAttributePieces
    let output ← prepare profile "Library" [source]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let some receipt := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "connective attribute module receipt missing"
    let expected := ["coreAttrGoodAndEq", "coreAttrGoodAnd", "coreAttrGoodIff"]
    ensure (receipt.interface.simpEntries.length == expected.length &&
      (receipt.interface.simpEntries.zip expected).all (fun (entry, text) =>
        psNameEq entry.name (psRootName text) && entry.kind == .proof && entry.priority == 1000))
      "connective simp registrations lost source identity, proof kind or deterministic order"
    for (label, leanText, psText) in connectiveAttributeRefusals do
      let source := importVisibilityInput kind "Entry" "" [(leanText, psText)]
      refuse profile "Entry" [source] true
        "PSCV0-DATA: PSCV0-SIMP-ATTRIBUTE: equation is equivalent to variable reflexivity"
      IO.println ("CORE-CONNECTIVE-ATTRIBUTES: refused " ++ label ++
        psCompilerSourceKindExtension kind)
  let [left, right] := paired | fail "missing connective attribute source pair"
  ensure (left == right) "connective attribute canonical declarations differ between readers"
  IO.println "PSCV0_CORE_CONNECTIVE_ATTRIBUTES: paired program; 14 checked seed declarations without axioms; three logical simp registrations; eight owned portable refusals; exact canonical reader parity passed"

private def attributeLibraryPieces : List (String × String) := [
  ("public class CoreAttrEcho (A : Type) where\n  run : A -> A\n",
   "class CoreAttrEcho(A: Type) where { run: A -> A }\n"),
  ("@[simp] public def coreAttrIdentity (A : Type) (x : A) : A := x\n",
   "@[simp] def coreAttrIdentity(A: Type, x: A): A := x\n"),
  ("@[simp] public theorem coreAttrIdentityEq (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n",
   "@[simp] theorem coreAttrIdentityEq(A: Type, x: A): coreAttrIdentity(A, x) = x := by { rfl }\n"),
  ("@[simp] private theorem coreAttrPrivateEq (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n",
   "@[simp] private theorem coreAttrPrivateEq(A: Type, x: A): coreAttrIdentity(A, x) = x := by { rfl }\n"),
  ("@[instance] public def coreAttrInstance {A : Type} := ({ run := fun (x : A) => x } : CoreAttrEcho A)\n",
   "@[instance] def coreAttrInstance{A: Type} := ({ run := fun (x: A) => x }: CoreAttrEcho(A))\n"),
  ("@[simp, instance, default_instance 700] public def coreAttrCombined {A : Type} : CoreAttrEcho A := helper\nwhere\n  helper : CoreAttrEcho A := { run := fun (x : A) => x }\n",
   "@[simp, instance, default_instance 700] def coreAttrCombined{A: Type}: CoreAttrEcho(A) := helper\nwhere {\n  def helper: CoreAttrEcho(A) := { run := fun (x: A) => x }\n}\n"),
  ("@[default_instance] public abbrev coreAttrAbbrev {A : Type} : CoreAttrEcho A := { run := fun (x : A) => x }\n",
   "@[default_instance] abbrev coreAttrAbbrev{A: Type}: CoreAttrEcho(A) := { run := fun (x: A) => x }\n"),
  ("mutual\n  @[simp] public def coreAttrFirst (A : Type) (x : A) : A := coreAttrSecond A x\n  @[simp] public def coreAttrSecond (A : Type) (x : A) : A := x\nend\n",
   "mutual\n  @[simp] def coreAttrFirst(A: Type, x: A): A := coreAttrSecond(A, x)\n  @[simp] def coreAttrSecond(A: Type, x: A): A := x\nend\n"),
  ("@[simp] public theorem coreAttrProposition (P : Prop) (h : P) : P := h\n",
   "@[simp] theorem coreAttrProposition(P: Prop, h: P): P := h\n")]

private def attributeClientPieces : List (String × String) := [
  ("public theorem coreAttrViaSpec (A : Type) (x : A) : coreAttrIdentity A x = x := coreAttrIdentityEq A x\n",
   "theorem coreAttrViaSpec(A: Type, x: A): coreAttrIdentity(A, x) = x := coreAttrIdentityEq(A, x)\n"),
  ("public def coreAttrCall (A : Type) (x : A) : A := CoreAttrEcho.run x (A := A)\n",
   "def coreAttrCall(A: Type, x: A): A := CoreAttrEcho.run(x, A := A)\n")]

private def attributeRefusals : List ((String × String) × String) := [
  (("@[simp] public theorem coreAttrBad (A : Type) (x : A) : x = x := by rfl\n",
    "@[simp] theorem coreAttrBad(A: Type, x: A): x = x := by { rfl }\n"),
   "PSCV0-DATA: PSCV0-SIMP-ATTRIBUTE: equation is equivalent to variable reflexivity"),
  (("@[simp] public theorem coreAttrBad (A B : Type) (f : A -> B) : (fun (x : A) => f x) = f := by rfl\n",
    "@[simp] theorem coreAttrBad(A: Type, B: Type, f: A -> B): (fun (x: A) => f(x)) = f := by { rfl }\n"),
   "PSCV0-DATA: PSCV0-SIMP-ATTRIBUTE: equation is equivalent to variable reflexivity"),
  (("public abbrev coreAttrAlias (A : Type) (x : A) : A := x\n@[simp] public theorem coreAttrBad (A : Type) (x : A) : coreAttrAlias A x = x := by rfl\n",
    "abbrev coreAttrAlias(A: Type, x: A): A := x\n@[simp] theorem coreAttrBad(A: Type, x: A): coreAttrAlias(A, x) = x := by { rfl }\n"),
   "PSCV0-DATA: PSCV0-SIMP-ATTRIBUTE: equation is equivalent to variable reflexivity"),
  (("@[simp] public opaque coreAttrBad (A : Type) (x : A) : A := x\n",
    "@[simp] opaque coreAttrBad(A: Type, x: A): A := x\n"),
   "PSCV0-DATA: PSCV0-SIMP-ATTRIBUTE: expected proposition or definition"),
  (("@[instance] public def coreAttrBad (A : Type) (x : A) := x\n",
    "@[instance] def coreAttrBad(A: Type, x: A) := x\n"),
   "PSCV0-DATA: instance result must be a registered class"),
  (("@[simp, instance] public def coreAttrBad (A : Type) (x : A) : A := x\n",
    "@[simp, instance] def coreAttrBad(A: Type, x: A): A := x\n"),
   "PSCV0-DATA: instance result must be a registered class")]

private def attributeSimpRoster : List (String × PsSimpEntryKind) :=
  [("coreAttrProposition", .proof),
   ("coreAttrSecond", .unfoldDefinition), ("coreAttrFirst", .unfoldDefinition),
   ("coreAttrCombined", .unfoldDefinition), ("coreAttrIdentityEq", .proof),
   ("coreAttrIdentity", .unfoldDefinition)]

private def checkAttributeSimpRoster (entries : List PsSimpEntry) : IO Unit := do
  ensure (entries.length == attributeSimpRoster.length &&
      (entries.zip attributeSimpRoster).all (fun (entry, expected) =>
        psNameEq entry.name (psRootName expected.fst) &&
        entry.kind == expected.snd && entry.priority == 1000))
    "selected simp source identity, kind, priority or order changed"

private theorem coreNativeEtaForward (A B : Type) (f : A → B) :
    (fun x => f x) = f := by rfl
private theorem coreNativeEtaReverse (A B : Type) (f : A → B) :
    f = (fun x => f x) := by rfl
private theorem coreNativeEtaNested (A B : Type) (f : A → A → B) :
    (fun x => fun y => f x y) = f := by rfl
private theorem coreNativeEtaLet (A B : Type) (f : A → B) :
    (fun x => let y := x; f y) = f := by rfl

private def functionEtaPieces : List (String × String) := [
  ("public theorem coreEtaForward (A B : Type) (f : A -> B) : (fun (x : A) => f x) = f := by rfl\n",
   "theorem coreEtaForward(A: Type, B: Type, f: A -> B): (fun (x: A) => f(x)) = f := by { rfl }\n"),
  ("public theorem coreEtaReverse (A B : Type) (f : A -> B) : f = (fun (x : A) => f x) := by rfl\n",
   "theorem coreEtaReverse(A: Type, B: Type, f: A -> B): f = (fun (x: A) => f(x)) := by { rfl }\n"),
  ("public theorem coreEtaNested (A B : Type) (f : A -> A -> B) : (fun (x : A) => fun (y : A) => f x y) = f := by rfl\n",
   "theorem coreEtaNested(A: Type, B: Type, f: A -> A -> B): (fun (x: A) => fun (y: A) => f(x, y)) = f := by { rfl }\n"),
  ("public theorem coreEtaLet (A B : Type) (f : A -> B) : (fun (x : A) => let y := x; f y) = f := by rfl\n",
   "theorem coreEtaLet(A: Type, B: Type, f: A -> B): (fun (x: A) => let y := x\n  f(y)) = f := by { rfl }\n")]

private def checkSourceAttributes : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List String := []
  let mut etaAdmissions : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let eta ← prepare profile "Eta" [importVisibilityInput kind "Eta" "" functionEtaPieces]
    let _ ← admit seed eta.admissions
    etaAdmissions := etaAdmissions ++ [eta.admissions]
    refuse profile "Eta" [importVisibilityInput kind "Eta" "" [
      ("public theorem coreEtaCaptured (A B : Type) (f : A -> A -> B) (a b : A) : (fun (x : A) => f x a) = (fun (x : A) => f x b) := by rfl\n",
       "theorem coreEtaCaptured(A: Type, B: Type, f: A -> A -> B, a: A, b: A): (fun (x: A) => f(x, a)) = (fun (x: A) => f(x, b)) := by { rfl }\n")]]
      true "PSCV0-PROOF: rfl requires definitionally equal sides"
    let library := importVisibilityInput kind "Library" "" attributeLibraryPieces
    let client := importVisibilityInput kind "Entry" "public import Library\n" attributeClientPieces
    let output ← prepare profile "Entry" [client, library]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let some receipt := output.moduleProfiles.find? (fun item => item.name == "Library")
      | fail "attribute library receipt missing"
    checkAttributeSimpRoster receipt.interface.simpEntries
    let hidden := psNameAppendStr
      (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreAttrPrivateEq"
    ensure (receipt.privateNames.any (psNameEq hidden) &&
        !receipt.interface.simpEntries.any (fun entry => psNameEq entry.name hidden) &&
        output.prepared.declarations.any (fun declaration =>
          psNameEq (psDeclarationName declaration) hidden))
      "private simp theorem was lost or entered public metadata"
    for text in ["coreAttrIdentity", "coreAttrInstance", "coreAttrCombined",
        "coreAttrFirst", "coreAttrSecond"] do
      let name := psRootName text
      let some (.opaqueDecl ..) := receipt.interface.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("source attribute exposed an ordinary definition: " ++ text)
      ensure (!receipt.exposedNames.any (psNameEq name))
        ("source attribute changed body exposure: " ++ text)
    let abbrevName := psRootName "coreAttrAbbrev"
    let some (.definitionDecl ..) := receipt.interface.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) abbrevName)
      | fail "default attribute lost the abbreviation's source kind"
    ensure (receipt.exposedNames.any (psNameEq abbrevName))
      "default attribute lost abbreviation exposure"
    ensure (receipt.interface.instances.length == 2 &&
        (receipt.interface.instances.zip ["coreAttrCombined", "coreAttrInstance"]).all
          (fun (entry, name) => entry.priority == 1000 && match entry.value with
            | .constE actual _ => psNameEq actual (psRootName name)
            | _ => false))
      "instance attribute lost class validation, tie order or identity"
    ensure (receipt.interface.defaults.length == 2 &&
        (receipt.interface.defaults.zip [("coreAttrAbbrev", 1000), ("coreAttrCombined", 700)]).all
          (fun (entry, expected) => entry.priority == expected.snd && match entry.value with
            | .constE actual _ => psNameEq actual (psRootName expected.fst)
            | _ => false))
      "attribute list lost separate default identity or priority"
    let some (.definitionDecl _ _ _ call) := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) (psRootName "coreAttrCall"))
      | fail "imported attribute synthesis client missing"
    ensure ((psPscv0ExprConstants call).any (psNameEq (psRootName "coreAttrCombined")) &&
        !(psPscv0ExprConstants call).any (psNameEq (psRootName "coreAttrInstance")))
      "imported ordinary instance tie order did not select the latest checked declaration"
    let left := importVisibilityInput kind "Left" "public import Library\n" []
    let right := importVisibilityInput kind "Right" "public import Library\n" []
    let diamondClient := importVisibilityInput kind "Entry"
      "public import Left\npublic import Right\n" attributeClientPieces
    let diamond ← prepare profile "Entry" [diamondClient, right, library, left]
    ensure (diamond.admissions == output.admissions)
      "public attribute diamond changed checked declaration admissions"
    let diamondInterface ← importVisibilityInterface diamond
    checkAttributeSimpRoster diamondInterface.simpEntries
    ensure (diamondInterface.instances.length == 2 && diamondInterface.defaults.length == 2)
      "public attribute diamond duplicated ordinary/default registrations"
    let parsed ← match psCompilerParsePscv0Program kind library.source with
      | .ok parsed => pure parsed
      | .error message => fail message
    let elaborated ← match psElabProgramWithOrigins profile.baseEnvironment parsed "Library" with
      | .ok result => pure result
      | .error error => fail (psCompilerPscv0ElabError error)
    let fullView := psPscv0DeclarationInterface
      elaborated.result.environment elaborated.result.declarations
    ensure (fullView.simpEntries.length == 7 &&
        fullView.simpEntries.any (fun entry =>
          psNameEq entry.name hidden && entry.kind == .proof))
      "checked private source simp registration was discarded"
    let merged := psPscv0InterfaceMerge fullView fullView
    let installed ← match psPscv0InstallInterface profile.baseEnvironment merged with
      | .ok result => pure result
      | .error message => fail message
    let installed ← match psPscv0InstallInterface installed merged with
      | .ok result => pure result
      | .error message => fail message
    ensure (sameNames (installed.simpEntries.map (·.name)) (fullView.simpEntries.map (·.name)) &&
        installed.instances.entries.length == 2 && installed.instances.defaults.length == 2)
      "legacy attribute installation lost private registration, stable order or deduplication"
    for negative in attributeRefusals do
      refuse profile "Library"
        [importVisibilityInput kind "Library" "" [negative.fst]] true negative.snd
    refuse profile "Entry" [library,
      importVisibilityInput kind "Entry" "public import Library\n" [
        ("public theorem coreAttrLeak (A : Type) (x : A) : coreAttrIdentity A x = x := coreAttrPrivateEq A x\n",
         "theorem coreAttrLeak(A: Type, x: A): coreAttrIdentity(A, x) = x := coreAttrPrivateEq(A, x)\n")]]
      true "PSCV0-SCOPE: unknown name coreAttrPrivateEq"
    refuse profile "Entry" [library,
      importVisibilityInput kind "Entry" "public import Library\n" [
        ("public theorem coreAttrOpaqueBad (A : Type) (x : A) : coreAttrIdentity A x = x := by rfl\n",
         "theorem coreAttrOpaqueBad(A: Type, x: A): coreAttrIdentity(A, x) = x := by { rfl }\n")]]
      true "PSCV0-PROOF: rfl requires definitionally equal sides"
    for attributes in ["@[]", "@[unknown]", "@[simp,]", "@[simp 700]", "@[instance 700]"] do
      let source := importVisibilityInput kind "Library" "" [
        (attributes ++ " public def coreAttrSyntax (A : Type) (x : A) : A := x\n",
         attributes ++ " def coreAttrSyntax(A: Type, x: A): A := x\n")]
      match psCompilerParsePscv0Program kind source.source with
      | .error _ => pure ()
      | .ok _ => fail ("unselected attribute syntax accepted: " ++ attributes)
  let [etaLean, etaPs] := etaAdmissions | fail "eta reader pair missing"
  ensure (etaLean == etaPs) "function eta canonical declarations differ between readers"
  IO.println "PSCV0_CORE_FUNCTION_ETA: PASS four pinned native theorems, four paired admitted forward/reverse/nested/let programs and two captured-argument refusals"
  let [leanAdmissions, psAdmissions] := paired | fail "attribute reader pair missing"
  ensure (leanAdmissions == psAdmissions) "source attribute paired admissions differ"
  IO.println "PSCV0_CORE_SOURCE_ATTRIBUTES: paired kernel admissions, selected lists and mutual/where/inferred owners, checked simp identity, public/private and diamond metadata, ordinary/default ordering, source-kind preservation and sixteen owned semantic refusals passed"

private def exposedProofSecret : String × String :=
  ("private theorem coreSecretEq (A : Type) (x : A) : x = x := by rfl\n",
   "private theorem coreSecretEq(A: Type, x: A): x = x := by { rfl }\n")

private def exposedProofPieces : List (String × String) := [
  exposedProofSecret,
  ("public abbrev coreProofKeep (A : Type) (unused x : A) : A := (fun (_h : x = x) => x) (by exact coreSecretEq A x)\n",
   "abbrev coreProofKeep(A: Type, unused x: A): A := (fun (_h: x = x) => x)(by { exact coreSecretEq(A, x) })\n"),
  ("public abbrev coreProofLet (A : Type) (unused x : A) : A :=\n  let witness : A := x\n  (fun (_h : witness = witness) => x) (by exact coreSecretEq A witness)\n",
   "abbrev coreProofLet(A: Type, unused x: A): A := {\n  let witness: A := x\n  (fun (_h: witness = witness) => x)(by { exact coreSecretEq(A, witness) })\n}\n"),
  ("public def coreProofSignature (A : Type) (x : A) : (fun (_h : x = x) => A) (by exact coreSecretEq A x) := x\n",
   "function coreProofSignature(A: Type, x: A): (fun (_h: x = x) => A)(by { exact coreSecretEq(A, x) }) := x\n")]

private def exposedProofClient : List (String × String) := [
  ("public theorem coreProofKeepRfl (A : Type) (unused x : A) : coreProofKeep A unused x = x := by rfl\n",
   "theorem coreProofKeepRfl(A: Type, unused x: A): coreProofKeep(A, unused, x) = x := by { rfl }\n"),
  ("public theorem coreProofLetRfl (A : Type) (unused x : A) : coreProofLet A unused x = x := by rfl\n",
   "theorem coreProofLetRfl(A: Type, unused x: A): coreProofLet(A, unused, x) = x := by { rfl }\n"),
  ("public def coreProofSignatureUse (A : Type) (x : A) : A := coreProofSignature A x\n",
   "function coreProofSignatureUse(A: Type, x: A): A := coreProofSignature(A, x)\n")]

private def exposedProofImportProvider : List (String × String) := [
  ("public theorem coreImportedSecretEq (A : Type) (x : A) : x = x := by rfl\n",
   "theorem coreImportedSecretEq(A: Type, x: A): x = x := by { rfl }\n")]

private def exposedProofImportLibrary : List (String × String) := [
  ("public abbrev coreImportedProofKeep (A : Type) (x : A) : A := (fun (_h : x = x) => x) (by exact coreImportedSecretEq A x)\n",
   "abbrev coreImportedProofKeep(A: Type, x: A): A := (fun (_h: x = x) => x)(by { exact coreImportedSecretEq(A, x) })\n")]

private def exposedProofImportClient : List (String × String) := [
  ("public theorem coreImportedProofRfl (A : Type) (x : A) : coreImportedProofKeep A x = x := by rfl\n",
   "theorem coreImportedProofRfl(A: Type, x: A): coreImportedProofKeep(A, x) = x := by { rfl }\n")]

private def exposedProofBinderCount : PsExpr → Nat
  | .forallE _ _ body _ => 1 + exposedProofBinderCount body
  | _ => 0

private def checkExposedProofMissing (seed : Lean.Kernel.Environment)
    (admissions : String) (missing : PsName) : IO Unit := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok declarations => pure declarations
    | .error error => fail error.message
  let target := PsKernelLean.toLeanName missing
  let remaining := declarations.toList.filter fun declaration => match declaration with
    | .thmDecl info => info.name != target
    | _ => true
  ensure (remaining.length + 1 == declarations.size)
    "missing-proof replay did not remove exactly one actual theorem"
  let mut current := seed
  let mut refused := false
  for declaration in remaining do
    if !refused then
      let checked ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        current.addDeclCore 2000000 20000
          (PsKernelLean.psKernelWithDefinitionHeight current declaration) none
      match checked with
      | .ok next => current := next
      | .error (.unknownConstant _ actual) =>
          ensure (actual == target) "missing-proof replay failed for another dependency"
          refused := true
      | .error error => fail ("missing-proof replay: " ++ PsKernelLean.kernelExceptionSummary error)
  ensure refused "private proof dependency was not required by kernel admission"

private def checkExposedProofArtifacts (output : PsCompilerEngineProjectOutput)
    (library : String) (owner dependency : PsName) : IO PsName := do
  let parent := psNameAppendStr owner "$proof"
  let proofs := output.prepared.declarations.filter fun declaration =>
    match psDeclarationName declaration with
    | .num name _ => psNameEq name parent
    | _ => false
  let [.theoremDecl proofName _ type value] := proofs
    | fail "exporting proof did not produce one actual checked theorem"
  ensure (exposedProofBinderCount type == 2 &&
      !psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
      psExprFVarsInContext psLocalEmpty type && psExprFVarsInContext psLocalEmpty value)
    "proof closure captured an unused/let binding or left an open dependency"
  ensure ((psPscv0ExprConstants value).any (psNameEq dependency) &&
      !(psPscv0ExprConstants type).any (psNameEq dependency))
    "checked proof body or public expected type lost its dependency boundary"
  let some receipt := output.moduleProfiles.find? (fun item => item.name == library)
    | fail "proof abstraction module receipt missing"
  ensure (receipt.interface.declarations.any (fun declaration =>
        psNameEq (psDeclarationName declaration) proofName) &&
      !receipt.interface.declarations.any (fun declaration =>
        psNameEq (psDeclarationName declaration) dependency))
    "proof abstraction exposed its private dependency or lost the public theorem type"
  let some declaration := output.prepared.declarations.find?
      (fun declaration => psNameEq (psDeclarationName declaration) owner)
    | fail "proof abstraction source owner missing"
  let expressions := psDeclarationType declaration ::
    (psDeclarationValue declaration).toList
  ensure (expressions.any (fun expression =>
        (psPscv0ExprConstants expression).any (psNameEq proofName)) &&
      !expressions.any (fun expression =>
        (psPscv0ExprConstants expression).any (psNameEq dependency)))
    "exposed source did not replace the private proof with its checked public type"
  let some origin := output.origins.find? (fun item => item.moduleName == library)
    | fail "proof abstraction project origin missing"
  ensure (origin.batches.any (fun batch =>
      batch.members.any (fun member => psNameEq member.name owner) &&
      batch.members.any (fun member => psNameEq member.name proofName) &&
      batch.sourceInfo.any (fun info =>
        info.proofBoundaries.any psElabExposedProofIsBoundaryName)))
    "proof abstraction lost its actual source batch or tactic provenance"
  return proofName

private def checkExposedProofs : IO Unit := do
  let (seed, profile) ← scopeContext
  let privateProof :=
    psNameAppendStr (psNameAppendStr (PsName.num (psRootName "$psc0Private") 0) "Library") "coreSecretEq"
  let mut localPairs : List String := []
  let mut importedPairs : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let library := importVisibilityInput kind "Library" "" exposedProofPieces
    let client := importVisibilityInput kind "Entry" "public import Library\n" exposedProofClient
    let output ← prepare profile "Entry" [client, library]
    let _ ← admit seed output.admissions
    localPairs := localPairs ++ [output.admissions]
    ensure (!output.prepared.declarations.any psElabExposedProofDeclarationHasBoundary)
      "typed proof marker survived final admission preparation"
    let keepProof ← checkExposedProofArtifacts output "Library"
      (psRootName "coreProofKeep") privateProof
    let _ ← checkExposedProofArtifacts output "Library"
      (psRootName "coreProofLet") privateProof
    let _ ← checkExposedProofArtifacts output "Library"
      (psRootName "coreProofSignature") privateProof
    checkExposedProofMissing seed output.admissions privateProof
    checkExposedProofMissing seed output.admissions keepProof
    let direct := importVisibilityInput kind "Library" "" [
      exposedProofSecret,
      ("public abbrev coreProofDirect (A : Type) (x : A) : A := (fun (_h : x = x) => x) (coreSecretEq A x)\n",
       "abbrev coreProofDirect(A: Type, x: A): A := (fun (_h: x = x) => x)(coreSecretEq(A, x))\n")]
    refuse profile "Library" [direct] true
      "PSCV0-MODULE: exposed body references private name"
    let dataProof := importVisibilityInput kind "Library" "" [
      ("private def coreSecretValue (A : Type) (x : A) : A := x\n",
       "private function coreSecretValue(A: Type, x: A): A := x\n"),
      ("public abbrev coreProofData (A : Type) (x : A) : A := by exact coreSecretValue A x\n",
       "abbrev coreProofData(A: Type, x: A): A := by { exact coreSecretValue(A, x) }\n")]
    refuse profile "Library" [dataProof] true
      "PSCV0-MODULE: exposed body references private name"
    let hiddenType := importVisibilityInput kind "Library" "" [
      ("private def CoreHiddenProp (A : Type) (x : A) : Prop := x = x\n",
       "private function CoreHiddenProp(A: Type, x: A): Prop := x = x\n"),
      ("private theorem coreHiddenProof (A : Type) (x : A) : CoreHiddenProp A x := by rfl\n",
       "private theorem coreHiddenProof(A: Type, x: A): CoreHiddenProp(A, x) := by { rfl }\n"),
      ("public abbrev coreProofHiddenType (A : Type) (x : A) : A := (fun (_h : CoreHiddenProp A x) => x) (by exact coreHiddenProof A x)\n",
       "abbrev coreProofHiddenType(A: Type, x: A): A := (fun (_h: CoreHiddenProp(A, x)) => x)(by { exact coreHiddenProof(A, x) })\n")]
    refuse profile "Library" [hiddenType] true
      "PSCV0-MODULE: public signature references private name"
    let privateClient := importVisibilityInput kind "Entry" "public import Library\n" [
      ("public theorem coreProofPrivateAlias (A : Type) (x : A) : x = x := coreSecretEq A x\n",
       "theorem coreProofPrivateAlias(A: Type, x: A): x = x := coreSecretEq(A, x)\n")]
    refuse profile "Entry" [privateClient, library] true
      "PSCV0-SCOPE: unknown name coreSecretEq"
    let provider := importVisibilityInput kind "ProofProvider" "" exposedProofImportProvider
    let bridge := importVisibilityInput kind "Library" "import ProofProvider\n"
      exposedProofImportLibrary
    let consumer := importVisibilityInput kind "Entry" "public import Library\n"
      exposedProofImportClient
    let imported ← prepare profile "Entry" [consumer, bridge, provider]
    let _ ← admit seed imported.admissions
    importedPairs := importedPairs ++ [imported.admissions]
    let importedName := psRootName "coreImportedSecretEq"
    let _ ← checkExposedProofArtifacts imported "Library"
      (psRootName "coreImportedProofKeep") importedName
    checkExposedProofMissing seed imported.admissions importedName
    let importClient := importVisibilityInput kind "Entry" "public import Library\n" [
      ("public theorem coreProofImportAlias (A : Type) (x : A) : x = x := coreImportedSecretEq A x\n",
       "theorem coreProofImportAlias(A: Type, x: A): x = x := coreImportedSecretEq(A, x)\n")]
    refuse profile "Entry" [importClient, bridge, provider] true
      "PSCV0-SCOPE: unknown name coreImportedSecretEq"
  let [leanLocal, psLocal] := localPairs | fail "local proof pair missing"
  let [leanImported, psImported] := importedPairs | fail "imported proof pair missing"
  ensure (leanLocal == psLocal && leanImported == psImported)
    "proof abstraction differs between the two selected readers"
  let sourceName := psSyntaxNameAppendSegments ["$psc0ProofBoundary", "0"] .anonymous
  ensure (!psElabExposedProofIsBoundaryName sourceName)
    "source string segments forged a numeric proof identity"
  let counterfeit := PsExpr.letE (.num psElabExposedProofBoundaryName 0)
    (.sortE .zero) (.sortE .zero) (.bvar 0)
  match psElabExposedProofVisit 32 true (psRootName "counterfeit") []
      psLocalEmpty { environment := profile.baseEnvironment } counterfeit with
  | .error (.data message) =>
      ensure (message.startsWith "PSCV0-PROOF-ABSTRACTION-ORIGIN:")
        "counterfeit proof boundary reached a different refusal"
  | .error _ => fail "counterfeit proof boundary returned an unrelated elaboration refusal"
  | .ok _ => fail "counterfeit proof marker was accepted without checked source provenance"
  IO.println "PSCV0_CORE_EXPOSED_PROOFS: four paired admitted projects, ten source refusals, closed checked private proofs, typed let expansion, exact dependencies, public header proofs, private import closure, source provenance and independent missing-proof kernel refusals passed"

private def escapedProviderPieces : List (String × String) := [
  ("namespace CoreEscaped\n",
   "namespace CoreEscaped\n"),
  ("public def «if» (A : Type) («_» : A) : A := «_»\n",
   "function «if»(A: Type, «_»: A): A := «_»\n"),
  ("public def «Type» (A : Type) (x : A) : A := «if» A x\n",
   "function «Type»(A: Type, x: A): A := «if»(A, x)\n"),
  ("public def «Prop» (A : Type) (x : A) : A := «Type» A x\n",
   "function «Prop»(A: Type, x: A): A := «Type»(A, x)\n"),
  ("public def «a.b» (A : Type) (x : A) : A := x\n",
   "function «a.b»(A: Type, x: A): A := x\n"),
  ("namespace a\npublic def b (A : Type) (x : A) : A := x\nend a\n",
   "namespace a\nfunction b(A: Type, x: A): A := x\nend a\n"),
  ("public def «_root_.value» (A : Type) (x : A) : A := x\n",
   "function «_root_.value»(A: Type, x: A): A := x\n"),
  ("public def «unicode λ name» (A : Type) («two words» : A) : A := «two words»\n",
   "function «unicode λ name»(A: Type, «two words»: A): A := «two words»\n"),
  ("public def «» (A : Type) (x : A) : A := x\n",
   "function «»(A: Type, x: A): A := x\n"),
  ("public def rooted (A : Type) (x : A) : A := «_root_».CoreEscaped.«Type» A x\n",
   "function rooted(A: Type, x: A): A := «_root_».CoreEscaped.«Type»(A, x)\n"),
  ("public structure «box.type» (A : Type) where\n  «value.dot» : A\n",
   "structure «box.type»(A: Type) {\n  «value.dot»: A\n}\n"),
  ("public def boxed (A : Type) (x : A) : «box.type» A := { «value.dot» := x }\n",
   "function boxed(A: Type, x: A): «box.type»(A) := { «value.dot» := x }\n"),
  ("public def projected (A : Type) (box : «box.type» A) : A := box.«value.dot»\n",
   "function projected(A: Type, box: «box.type»(A)): A := box.«value.dot»\n"),
  ("private theorem «hidden proof» (A : Type) (x : A) : x = x := by rfl\n",
   "private theorem «hidden proof»(A: Type, x: A): x = x := by { rfl }\n"),
  ("public theorem «visible.proof» (A : Type) (x : A) : x = x := «hidden proof» A x\n",
   "theorem «visible.proof»(A: Type, x: A): x = x := «hidden proof»(A, x)\n"),
  ("public def «with.local» (A : Type) (x : A) : A := «helper.dot» x\nwhere\n  «helper.dot» (y : A) : A := y\n",
   "function «with.local»(A: Type, x: A): A := «helper.dot»(x)\nwhere {\n  def «helper.dot»(y: A): A := y\n}\n"),
  ("universe «u.level»\npublic def universeIdentity (A : Type «u.level») (x : A) : A := x\nend CoreEscaped\n",
   "universe «u.level»\nfunction universeIdentity(A: Type «u.level», x: A): A := x\nend CoreEscaped\n")]

private def escapedClientPieces : List (String × String) := [
  ("public def coreEscapedClient (A : Type) (x : A) : A := CoreEscaped.«Type» A (CoreEscaped.a.b A (CoreEscaped.«a.b» A x))\n",
   "function coreEscapedClient(A: Type, x: A): A := CoreEscaped.«Type»(A, CoreEscaped.a.b(A, CoreEscaped.«a.b»(A, x)))\n"),
  ("public theorem coreEscapedClientProof (A : Type) (x : A) : x = x := CoreEscaped.«visible.proof» A x\n",
   "theorem coreEscapedClientProof(A: Type, x: A): x = x := CoreEscaped.«visible.proof»(A, x)\n"),
  ("public def coreEscapedClientField (A : Type) (x : A) : A := CoreEscaped.projected A (CoreEscaped.boxed A x)\n",
   "function coreEscapedClientField(A: Type, x: A): A := CoreEscaped.projected(A, CoreEscaped.boxed(A, x))\n"),
  ("public def coreEscapedClientEmpty (A : Type) (x : A) : A := CoreEscaped.«» A x\n",
   "function coreEscapedClientEmpty(A: Type, x: A): A := CoreEscaped.«»(A, x)\n")]

private def escapedMarkerPieces : List (String × String) := [
  ("public def «$psc0Private» (A : Type) (x : A) : A := helper x\nwhere\n  helper (y : A) : A := y\n",
   "function «$psc0Private»(A: Type, x: A): A := helper(x)\nwhere {\n  def helper(y: A): A := y\n}\n"),
  ("public def coreEscapedPublicMarker (A : Type) (x : A) : A := «$psc0Private» A x\n",
   "function coreEscapedPublicMarker(A: Type, x: A): A := «$psc0Private»(A, x)\n")]

private def escapedSingleModulePieces : List (String × String) := [
  ("private def coreEscapedModuleSecret (A : Type) (x : A) : A := x\n",
   "private function coreEscapedModuleSecret(A: Type, x: A): A := x\n"),
  ("public def coreEscapedSingle (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n",
   "function coreEscapedSingle(A: Type, x: A): A := coreEscapedModuleSecret(A, x)\n")]

private def escapedSeparateModulePieces : List (String × String) := [
  ("private def coreEscapedModuleSecret (A : Type) (x : A) : A := x\n",
   "private function coreEscapedModuleSecret(A: Type, x: A): A := x\n"),
  ("public def coreEscapedSeparate (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n",
   "function coreEscapedSeparate(A: Type, x: A): A := coreEscapedModuleSecret(A, x)\n")]

private def escapedKeywordModulePieces : List (String × String) := [
  ("private def coreEscapedModuleSecret (A : Type) (x : A) : A := x\n",
   "private function coreEscapedModuleSecret(A: Type, x: A): A := x\n"),
  ("public def coreEscapedKeyword (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n",
   "function coreEscapedKeyword(A: Type, x: A): A := coreEscapedModuleSecret(A, x)\n")]

private def escapedTypeModulePieces : List (String × String) := [
  ("private def coreEscapedModuleSecret (A : Type) (x : A) : A := x\n",
   "private function coreEscapedModuleSecret(A: Type, x: A): A := x\n"),
  ("public def coreEscapedTypeModule (A : Type) (x : A) : A := coreEscapedModuleSecret A x\n",
   "function coreEscapedTypeModule(A: Type, x: A): A := coreEscapedModuleSecret(A, x)\n")]

private def escapedModuleClientPieces : List (String × String) := [
  ("public def coreEscapedModuleClient (A : Type) (x : A) : A := coreEscapedSeparate A (coreEscapedSingle A (coreEscapedKeyword A (coreEscapedTypeModule A x)))\n",
   "function coreEscapedModuleClient(A: Type, x: A): A := coreEscapedSeparate(A, coreEscapedSingle(A, coreEscapedKeyword(A, coreEscapedTypeModule(A, x))))\n")]

private def escapedExposureRefusalPieces : List (String × String) := [
  ("private def «hidden.value» (A : Type) (x : A) : A := x\npublic abbrev coreEscapedExposed (A : Type) (x : A) : A := «hidden.value» A x\n",
   "private function «hidden.value»(A: Type, x: A): A := x\nabbrev coreEscapedExposed(A: Type, x: A): A := «hidden.value»(A, x)\n")]

private def escapedSignatureRefusalPieces : List (String × String) := [
  ("private def «hidden.type» (A : Type) : Type := A\npublic def coreEscapedSignature (A : Type) (x : «hidden.type» A) (y : A) : A := y\n",
   "private function «hidden.type»(A: Type): Type := A\nfunction coreEscapedSignature(A: Type, x: «hidden.type»(A), y: A): A := y\n")]

private def escapedPrivateAlias : String × String :=
  ("public theorem coreEscapedLeak (A : Type) (x : A) : x = x := CoreEscaped.«hidden proof» A x\n",
   "theorem coreEscapedLeak(A: Type, x: A): x = x := CoreEscaped.«hidden proof»(A, x)\n")

private def escapedCanonicalGuess : String × String :=
  ("public theorem coreEscapedGuess (A : Type) (x : A) : x = x := «$psc0Private».«0».EscapedNamesProvider.CoreEscaped.«hidden proof» A x\n",
   "theorem coreEscapedGuess(A: Type, x: A): x = x := «$psc0Private».«0».EscapedNamesProvider.CoreEscaped.«hidden proof»(A, x)\n")

private def escapedReadName (source : String) : IO PsSyntaxName := do
  let tokens ← match psLex source with
    | .ok tokens => pure tokens
    | .error _ => fail ("escaped name did not lex: " ++ source)
  let parsed ← match psParseSyntaxNameWith true { remaining := tokens } with
    | .ok parsed => pure parsed
    | .error _ => fail ("escaped name did not parse: " ++ source)
  ensure (psTokenCursorDone parsed.cursor) "escaped name left trailing tokens"
  pure parsed.value

private def escapedScopeRefusal {α : Type} (result : Except PsElabError α)
    (label : String) (expected : String := "source syntax contains an internal resolved name") :
    IO Unit := do
  match result with
  | .error (.scope message) =>
      ensure (message == expected) (label ++ ": wrong source boundary refusal: " ++ message)
  | .error _ => fail (label ++ ": source boundary reached an unrelated refusal")
  | .ok _ => fail (label ++ ": internal source metadata was accepted")

private def checkEscapedLexicalNames : IO Unit := do
  let samples : List (String × List String) := [
    ("«Type»", ["Type"]), ("«_»", ["_"]), ("«»", [""]),
    ("CoreEscaped.«a.b»", ["CoreEscaped", "a.b"]),
    ("«_root_».CoreEscaped.«Type»", ["_root_", "CoreEscaped", "Type"]),
    ("«unicode λ name»", ["unicode λ name"]),
    ("«line\nbreak»", ["line\nbreak"])]
  for (source, segments) in samples do
    let name ← escapedReadName source
    ensure (name.segments == segments && name.escaped && name.resolvedName.isNone &&
        name.span.start.byteOffset == 0 &&
        name.span.stop.byteOffset == source.utf8ByteSize)
      "escaped name lost structural components, source spelling or byte span"
    let printed ← match psPrintSyntaxName name with
      | .ok printed => pure printed
      | .error _ => fail "escaped source name was not printable"
    let reparsed ← escapedReadName printed
    ensure (reparsed.segments == segments && reparsed.escaped &&
        reparsed.resolvedName.isNone)
      "escaped source name printing changed its identity"
  let underscore ← escapedReadName "«_»"
  ensure (!psSyntaxNameIsAnonymous underscore &&
      psSyntaxNameIsAnonymous (PsSyntaxName.mk ["_"] underscore.span))
    "quoted underscore was treated as an anonymous binder"
  for lexer in [psLex, psLexProofScript] do
    match lexer "«unfinished" with
    | .error (.invalidSource message _) =>
        ensure (message == "unterminated identifier escape")
          "unterminated identifier escape reached the wrong lexical refusal"
    | .error _ => fail "unterminated identifier escape returned an unrelated refusal"
    | .ok _ => fail "unterminated identifier escape was accepted"
  let marker ← escapedReadName "«$psc0ProofBoundary».«0»"
  let some markerName := psSyntaxNameToName marker | fail "escaped proof marker name is empty"
  ensure (!psElabExposedProofIsBoundaryName markerName)
    "escaped source spelling forged a numeric proof boundary"

private def checkEscapedAstBoundary (environment : PsEnvironment) (hidden : PsName) :
    IO Unit := do
  ensure (psEnvironmentContains environment hidden)
    "source boundary test did not retain its actual checked private dependency"
  let program ← match psCompilerParsePscv0Program .lean
      "theorem coreEscapedBoundary (A : Type) (x : A) : x = x := by rfl\n" with
    | .ok program => pure program
    | .error message => fail ("source boundary control parse: " ++ message)
  let [.declaration (.theoremDecl name binders type value span)] := program.commands
    | fail "source boundary control command shape changed"
  let original := PsSyntaxDeclaration.theoremDecl name binders type value span
  let forged : PsSyntaxName := {
    segments := ["forged"]
    span := span
    resolvedName := some hidden }
  let a := PsSyntaxTerm.reference (PsSyntaxName.mk ["A"] span)
  let x := PsSyntaxTerm.reference (PsSyntaxName.mk ["x"] span)
  let badValue := PsSyntaxTerm.app (.reference forged) [a, x] span
  let badBody := PsSyntaxDeclaration.theoremDecl name binders type badValue span
  let badHead := PsSyntaxDeclaration.theoremDecl forged binders type value span
  let forgedBinder : PsSyntaxBinderHead := .mk forged .explicit span
  let forgedOrigin : PsSyntaxBinderHead := {
    name := PsSyntaxName.mk ["y"] span
    kind := .explicit
    span := span
    origin := some { names := [forged], index := 0 } }
  let sources := [badBody, badHead,
    .theoremDecl name [(forgedBinder, a)] type value span,
    .theoremDecl name [(forgedOrigin, a)] type value span,
    .whereDeclaration original [{
      name := forged, binders := [], type := some a, value := x,
      recursion := none, span := span }] span,
    .inductiveDecl name [] none [{
      name := forged, fields := [], span := span }] span]
  for source in sources do
    escapedScopeRefusal
      (psElabProgramWithOrigins environment { program with commands := [.declaration source] })
      "program source"
    escapedScopeRefusal (psElabDeclarations environment [source] []) "legacy declaration source"
    escapedScopeRefusal (psElabModule environment { imports := [], declarations := [source] })
      "legacy module source"
  let terms : List PsSyntaxTerm := [
    .record [(forged, x)] span,
    .recordUpdate x [(forged, x)] span,
    .call x [(some forged, x)] span,
    .letE forged none x x span,
    .haveE forged none x x span,
    .ifE (some forged) x x x span,
    .matchMany [{ term := x, equationName? := some forged }] [] none span,
    .matchMany [{ term := x }] [([.inaccessible (.ctor forged [] span)], x, span)] none span,
    .doE [.conditional (some forged) x [] [] span] span,
    .doE [.binding (.variable forged) none x false span] span,
    .byE [.intro [forged] span] {} span,
    .byE [.caseE (some forged) [] [] span] {} span]
  for term in terms do
    escapedScopeRefusal
      (psElabCommand { environment := environment }
        (.declaration (.theoremDecl name binders type term span)))
      "nested source name"
  let commands : List PsSyntaxCommand := [
    .namespaceCmd forged span, .sectionCmd (some forged) span,
    .endCmd (some forged) span, .universeCmd [forged] span,
    .openCmd [forged] span, .includeCmd [forged] span, .omitCmd [forged] span,
    .variableCmd [(forgedBinder, a)] span,
    .attributedDeclaration badHead none false [.simpAttribute],
    .derivingDeclaration original [forged] false,
    .attributedDerivingDeclaration original [forged] false [.simpAttribute],
    .mutualDeclarations [{ declaration := badHead }] span,
    .inspectionCmd (.checkTerm badValue) span,
    .inspectionCmd (.printDeclaration forged false) span,
    .inspectionCmd (.printDeclaration forged true) span,
    .inspectionCmd (.reduceTerm badValue) span,
    .inspectionCmd (.evalTerm badValue) span]
  for command in commands do
    escapedScopeRefusal (psElabCommand { environment := environment } command)
      "source command target"
  let internalProof := PsSyntaxTerm.byE []
    { privateAliases := [(["stolen"], hidden)] } span
  escapedScopeRefusal
    (psElabCommand { environment := environment }
      (.declaration (.theoremDecl name binders type internalProof span)))
    "source proof scope" "source syntax contains an internal proof scope"
  let forgedImport : PsSyntaxImport := { moduleName := forged, span := span }
  escapedScopeRefusal
    (psElabProgramWithOrigins environment { program with imports := [forgedImport] })
    "program import identity"
  escapedScopeRefusal
    (psElabModule environment { imports := [forgedImport], declarations := [] })
    "legacy import identity"
  match psElabProgramWithOrigins environment program with
  | .ok _ => pure ()
  | .error _ => fail "source boundary rejected its unmodified parsed theorem control"

private def checkEscapedAlias (profile : PsCompilerProfileContext) : IO Unit := do
  let actual := psNameAppendStr (psRootName "External") "a.b"
  let declaration := PsDeclaration.definitionDecl actual [] idType idValue
  let some environment := psEnvironmentAdd profile.baseEnvironment declaration
    | fail "escaped exported-alias base declaration collided"
  let aliasProfile := { profile with baseEnvironment := {
    environment with exportedAliases := [(psRootName "EscapedAlias", actual)] } }
  let seed ← match (← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations
      (profile.baseEnvironment.declarations.reverse ++ [declaration])) with
    | .ok seed => pure seed
    | .error error => fail ("escaped alias base kernel: " ++ error.message)
  let mut pairs : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let source := importVisibilityInput kind "EscapedAliasClient" "" [
      ("public def coreEscapedAlias (A : Type) (x : A) : A := EscapedAlias A x\n",
       "function coreEscapedAlias(A: Type, x: A): A := EscapedAlias(A, x)\n")]
    let output ← prepare aliasProfile "EscapedAliasClient" [source]
    let _ ← admit seed output.admissions
    let some result := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) (psRootName "coreEscapedAlias"))
      | fail "escaped exported-alias client missing"
    let some body := psDeclarationValue result | fail "escaped alias body missing"
    ensure ((psPscv0ExprConstants body).any (psNameEq actual) &&
        !(psPscv0ExprConstants body).any
          (psNameEq (psNameAppendStr (psNameAppendStr (psRootName "External") "a") "b")))
      "exported alias identity was recovered through rendered string splitting"
    pairs := pairs ++ [output.admissions]
  let [left, right] := pairs | fail "escaped alias reader pair missing"
  ensure (left == right) "escaped exported alias differs between readers"

private def checkEscapedIdentifiers : IO Unit := do
  checkEscapedLexicalNames
  let (seed, profile) ← scopeContext
  checkEscapedAlias profile
  let hidden := psElabPrivateName ["EscapedNamesProvider", "CoreEscaped", "hidden proof"]
  let helper := psElabPrivateName
    ["EscapedNamesProvider", "CoreEscaped", "with.local", "helper.dot"]
  let literalDot := psNameAppendStr (psRootName "CoreEscaped") "a.b"
  let separateDot := psNameAppendStr (psNameAppendStr (psRootName "CoreEscaped") "a") "b"
  ensure (!psNameEq literalDot separateDot) "quoted dot lost structural name identity"
  let keys := ["«EscapeModules.Dot»", "EscapeModules.Dot", "«if»", "«Type»"]
  ensure (keys.all psPscv0ValidModuleKey &&
      psPscv0ModuleKey ["EscapeModules.Dot"] == "«EscapeModules.Dot»" &&
      psPscv0ModuleKey ["EscapeModules", "Dot"] == "EscapeModules.Dot" &&
      psPscv0ModuleKey ["if"] == "«if»" &&
      psPscv0ModuleKey ["Type"] == "«Type»")
    "canonical module keys lost escaped dot or reserved keyword components"
  ensure ((["EscapeModules..Dot", "EscapeModules. Dot", "if", "Type", "«Library»"] :
      List String).all (fun key => !psPscv0ValidModuleKey key))
    "noncanonical external module key was accepted"
  let mut providerPairs : List String := []
  let mut markerPairs : List String := []
  let mut modulePairs : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let provider := importVisibilityInput kind "EscapedNamesProvider" "" escapedProviderPieces
    let client := importVisibilityInput kind "EscapedNamesClient"
      "public import EscapedNamesProvider\n" escapedClientPieces
    let output ← prepare profile "EscapedNamesClient" [client, provider]
    let _ ← admit seed output.admissions
    providerPairs := providerPairs ++ [output.admissions]
    let some receipt := output.moduleProfiles.find?
        (fun receipt => receipt.name == "EscapedNamesProvider")
      | fail "escaped provider receipt missing"
    let environment ← takeCompiler (psCompilerEngineEnvironmentFromPrepared output.prepared)
    for name in [hidden, helper] do
      ensure (psEnvironmentContains environment name &&
          receipt.privateNames.any (psNameEq name) &&
          !receipt.interface.declarations.any
            (fun declaration => psNameEq (psDeclarationName declaration) name))
        "escaped private dependency was dropped or exposed as a source declaration"
    let publicNames := [literalDot, separateDot,
      psNameAppendStr (psRootName "CoreEscaped") "Type",
      psNameAppendStr (psRootName "CoreEscaped") "Prop",
      psNameAppendStr (psRootName "CoreEscaped") "_root_.value",
      psNameAppendStr (psRootName "CoreEscaped") "",
      psNameAppendStr (psRootName "CoreEscaped") "unicode λ name",
      psNameAppendStr (psNameAppendStr (psRootName "CoreEscaped") "box.type") "value.dot"]
    ensure (publicNames.all fun name =>
        receipt.interface.declarations.any
          (fun declaration => psNameEq (psDeclarationName declaration) name))
      "escaped public names or field projection lost a structural component"
    let proofName := psNameAppendStr (psRootName "CoreEscaped") "visible.proof"
    let some (.theoremDecl _ _ _ proof) := psEnvironmentFind environment proofName
      | fail "escaped visible proof changed its checked declaration kind"
    ensure ((psPscv0ExprConstants proof).any (psNameEq hidden))
      "escaped public theorem lost its checked private proof dependency"
    checkEscapedAstBoundary environment hidden
    for bad in [escapedPrivateAlias, escapedCanonicalGuess] do
      refuse profile "EscapedLeak"
        [provider, importVisibilityInput kind "EscapedLeak"
          "public import EscapedNamesProvider\n" [bad]] true
        "PSCV0-SCOPE: unknown name"
      let legacy := input .lean "EscapedLegacyLeak"
        ("import EscapedNamesProvider\n" ++ bad.fst)
      refuse profile "EscapedLegacyLeak" [provider, legacy] true
        "PSCV0-SCOPE: unknown name"
    refuse profile "EscapedExposure"
      [importVisibilityInput kind "EscapedExposure" "" escapedExposureRefusalPieces] true
      "PSCV0-MODULE: exposed body references private name in coreEscapedExposed"
    refuse profile "EscapedSignature"
      [importVisibilityInput kind "EscapedSignature" "" escapedSignatureRefusalPieces] true
      "PSCV0-MODULE: public signature references private name in coreEscapedSignature"
    let markerSource := importVisibilityInput kind "Marker" "" escapedMarkerPieces
    let marker ← prepare profile "Marker" [markerSource]
    let _ ← admit seed marker.admissions
    markerPairs := markerPairs ++ [marker.admissions]
    let some markerReceipt := marker.moduleProfiles.find? (fun receipt => receipt.name == "Marker")
      | fail "escaped public marker receipt missing"
    let markerHelper := psElabPrivateName ["Marker", "$psc0Private", "helper"]
    let publicMarker := psRootName "$psc0Private"
    ensure (markerReceipt.interface.declarations.any
        (fun declaration => psNameEq (psDeclarationName declaration) publicMarker) &&
        !markerReceipt.privateNames.any (psNameEq publicMarker) &&
        markerReceipt.privateNames.any (psNameEq markerHelper) &&
        !markerReceipt.interface.declarations.any
          (fun declaration => psNameEq (psDeclarationName declaration) markerHelper))
      "legitimate escaped public marker acquired private-name authority"
    let single := importVisibilityInput kind "«EscapeModules.Dot»" "" escapedSingleModulePieces
    let separate := importVisibilityInput kind "EscapeModules.Dot" "" escapedSeparateModulePieces
    let keyword := importVisibilityInput kind "«if»" "" escapedKeywordModulePieces
    let typeModule := importVisibilityInput kind "«Type»" "" escapedTypeModulePieces
    let moduleClient := importVisibilityInput kind "EscapedModuleClient"
      ("public import «EscapeModules.Dot»\npublic import EscapeModules.Dot\n" ++
        "public import «if»\npublic import «Type»\n") escapedModuleClientPieces
    let modules ← prepare profile "EscapedModuleClient"
      [moduleClient, single, separate, keyword, typeModule]
    let _ ← admit seed modules.admissions
    modulePairs := modulePairs ++ [modules.admissions]
    let secrets := keys.map fun key => psElabPrivateName [key, "coreEscapedModuleSecret"]
    ensure ((secrets.zipIdx).all fun (name, index) =>
        (secrets.drop (index + 1)).all (fun other => !psNameEq name other))
      "distinct escaped module identities minted the same private declaration"
    for (key, secret) in keys.zip secrets do
      let some moduleReceipt := modules.moduleProfiles.find? (fun receipt => receipt.name == key)
        | fail "canonical escaped module receipt missing"
      ensure (moduleReceipt.privateNames.any (psNameEq secret) &&
          modules.prepared.declarations.any
            (fun declaration => psNameEq (psDeclarationName declaration) secret) &&
          !moduleReceipt.interface.declarations.any
            (fun declaration => psNameEq (psDeclarationName declaration) secret))
        "escaped module private identity was collapsed or exposed"
    let some clientReceipt := modules.moduleProfiles.find?
        (fun receipt => receipt.name == "EscapedModuleClient")
      | fail "escaped module client receipt missing"
    ensure (clientReceipt.imports == keys.map (fun key => (key, true)))
      "escaped module import receipt flattened a quoted component"
    refuse profile "EscapedMissing"
      [single, importVisibilityInput kind "EscapedMissing" "import EscapeModules.Dot\n" []]
      false "PSCV0-MODULE: missing module EscapeModules.Dot imported by EscapedMissing"
    refuse profile "EscapedMissing"
      [separate, importVisibilityInput kind "EscapedMissing" "import «EscapeModules.Dot»\n" []]
      false "PSCV0-MODULE: missing module «EscapeModules.Dot» imported by EscapedMissing"
  for pair in [providerPairs, markerPairs, modulePairs] do
    let [left, right] := pair | fail "escaped identifier paired reader result missing"
    ensure (left == right) "escaped names changed canonical admissions between readers"
  IO.println "PSCV0_CORE_ESCAPED_IDENTIFIERS: paired checked modules, quoted keywords and underscores, structural dots and fields, Unicode and empty identifiers, private numeric identities, public marker names, module-key collisions, source AST provenance, exported aliases and owned visibility/graph refusals passed"

private def declarationUniverseProvider : List (String × String) := [
  ("namespace CoreUniverses\n", "namespace CoreUniverses\n"),
  ("public def identity.{a} (A : Type a) (x : A) : A := x\n",
   "function identity.{a}(A: Type a, x: A): A := x\n"),
  ("public def ordered.{v, u} (A : Type u) (B : Type v) (x : A) : A := x\n",
   "function ordered.{v, u}(A: Type u, B: Type v, x: A): A := x\n"),
  ("universe u\n", "universe u\n"),
  ("public def inherited.{v} (A : Type u) (B : Type v) (x : A) : A := x\n",
   "function inherited.{v}(A: Type u, B: Type v, x: A): A := x\n"),
  ("public def scopeDrop.{w} (A : Type w) (x : A) : A := x\n",
   "function scopeDrop.{w}(A: Type w, x: A): A := x\n"),
  ("public def repeatA.{r} (A : Type r) (x : A) : A := x\n",
   "function repeatA.{r}(A: Type r, x: A): A := x\n"),
  ("public def repeatB.{r} (A : Type r) (x : A) : A := x\n",
   "function repeatB.{r}(A: Type r, x: A): A := x\n"),
  ("public def constant.{q} : (A : Type q) -> A -> A := fun (A : Type q) => fun (x : A) => x\n",
   "const constant.{q}: (A: Type q) -> A -> A := fun (A: Type q) => fun (x: A) => x\n"),
  ("public abbrev alias.{b} (A : Type b) (x : A) : A := x\n",
   "abbrev alias.{b}(A: Type b, x: A): A := x\n"),
  ("public opaque sealed.{o} (A : Type o) (x : A) : A := x\n",
   "opaque sealed.{o}(A: Type o, x: A): A := x\n"),
  ("public theorem reflexive.{p} (A : Sort p) (x : A) : x = x := by rfl\n",
   "theorem reflexive.{p}(A: Sort p, x: A): x = x := by { rfl }\n"),
  ("private def hidden.{h} (A : Type h) (x : A) : A := x\n",
   "private function hidden.{h}(A: Type h, x: A): A := x\n"),
  ("public def fromHidden.{h} (A : Type h) (x : A) : A := hidden A x\n",
   "function fromHidden.{h}(A: Type h, x: A): A := hidden(A, x)\n"),
  ("public def withHelper.{k} (A : Type k) (x : A) : A := helper x\nwhere\n  helper (value : A) : A := value\n",
   "function withHelper.{k}(A: Type k, x: A): A := helper(x)\nwhere {\n  def helper(value: A): A := value\n}\n"),
  ("public structure Box.{s} (A : Type s) where\n  value : A\n",
   "structure Box.{s}(A: Type s) where { value: A }\n"),
  ("public inductive Tag.{t} (A : Type t) where\n  | mk (value : A)\n",
   "inductive Tag.{t}(A: Type t) where { | mk(value: A) }\n"),
  ("public class Picker.{c} (A : Type c) where\n  run : A -> A\n",
   "class Picker.{c}(A: Type c) where { run: A -> A }\n"),
  ("public instance picker.{i} {A : Type i} : Picker A where\n  run := fun (x : A) => x\n",
   "instance picker.{i}{A: Type i}: Picker A where { run := fun (x: A) => x }\n"),
  ("public def quoted.{first.level, «first.level»} (A : Sort first.level) (B : Sort «first.level») (x : A) : A := x\n",
   "function quoted.{first.level, «first.level»}(A: Sort first.level, B: Sort «first.level», x: A): A := x\n"),
  ("universe command.level «command.level»\n", "universe command.level «command.level»\n"),
  ("public def globalIdentity (A : Sort command.level) (B : Sort «command.level») (x : A) : A := x\n",
   "function globalIdentity(A: Sort command.level, B: Sort «command.level», x: A): A := x\n"),
  ("end CoreUniverses\n", "end CoreUniverses\n")]

private def declarationUniverseClient : List (String × String) := [
  ("public def coreUniverseClient.{u} (A : Type u) (x : A) : A := CoreUniverses.identity A (CoreUniverses.fromHidden A x)\n",
   "function coreUniverseClient.{u}(A: Type u, x: A): A := CoreUniverses.identity(A, CoreUniverses.fromHidden(A, x))\n"),
  ("public theorem coreUniverseAlias.{u} (A : Type u) (x : A) : CoreUniverses.alias A x = x := by rfl\n",
   "theorem coreUniverseAlias.{u}(A: Type u, x: A): CoreUniverses.alias(A, x) = x := by { rfl }\n"),
  ("public theorem coreUniverseInstance.{u} (A : Type u) (x : A) : CoreUniverses.Picker.run x (A := A) = x := by rfl\n",
   "theorem coreUniverseInstance.{u}(A: Type u, x: A): CoreUniverses.Picker.run(x, A := A) = x := by { rfl }\n"),
  ("public theorem coreUniverseProof.{u} (A : Sort u) (x : A) : x = x := CoreUniverses.reflexive A x\n",
   "theorem coreUniverseProof.{u}(A: Sort u, x: A): x = x := CoreUniverses.reflexive(A, x)\n")]

private def declarationUniverseMutual : List (String × String) := [
  ("mutual\npublic def universeLeft.{u} (A : Type u) (x : A) : A := universeRight A x\npublic def universeRight.{u} (A : Type u) (x : A) : A := x\nend\n",
   "mutual {\nfunction universeLeft.{u}(A: Type u, x: A): A := universeRight(A, x)\nfunction universeRight.{u}(A: Type u, x: A): A := x\n}\n")]

private def declarationUniverseRefusals : List (String × String × String × String) := [
  ("Duplicate", "public def bad.{u, u} (A : Type u) (x : A) : A := x\n",
   "function bad.{u, u}(A: Type u, x: A): A := x\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-DUPLICATE:"),
  ("ScopeDuplicate", "universe u\npublic def bad.{u} (A : Type u) (x : A) : A := x\n",
   "universe u\nfunction bad.{u}(A: Type u, x: A): A := x\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-DUPLICATE:"),
  ("Unused", "public def bad.{u} (A : Type) (x : A) : A := x\n",
   "function bad.{u}(A: Type, x: A): A := x\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-UNUSED:"),
  ("TheoremUnused", "public theorem bad.{u} (A : Type) (x : A) : x = x := by rfl\n",
   "theorem bad.{u}(A: Type, x: A): x = x := by { rfl }\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-UNUSED:"),
  ("DataUnused", "public structure Bad.{u} (A : Type) where\n  value : A\n",
   "structure Bad.{u}(A: Type) where { value: A }\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-UNUSED:"),
  ("InstanceUnused", "public class C (A : Type) where\n  run : A -> A\npublic instance bad.{u} {A : Type} : C A where\n  run := fun (x : A) => x\n",
   "class C(A: Type) where { run: A -> A }\ninstance bad.{u}{A: Type}: C A where { run := fun (x: A) => x }\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-UNUSED:"),
  ("MutualMismatch", "mutual\npublic def left.{u} (A : Type u) (x : A) : A := x\npublic def right.{v} (A : Type v) (x : A) : A := x\nend\n",
   "mutual {\nfunction left.{u}(A: Type u, x: A): A := x\nfunction right.{v}(A: Type v, x: A): A := x\n}\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-MUTUAL:"),
  ("MutualOrder", "mutual\npublic def left.{u, v} (A : Type u) (B : Type v) (x : A) : A := x\npublic def right.{v, u} (A : Type u) (B : Type v) (x : A) : A := x\nend\n",
   "mutual {\nfunction left.{u, v}(A: Type u, B: Type v, x: A): A := x\nfunction right.{v, u}(A: Type u, B: Type v, x: A): A := x\n}\n",
   "PSCV0-SCOPE: PSCV0-DECL-UNIVERSE-MUTUAL:"),
  ("ScopeLeak", "public def localOnly.{Private.level} (A : Sort Private.level) (x : A) : A := x\npublic def bad (A : Sort Private.level) (x : A) : A := x\n",
   "function localOnly.{Private.level}(A: Sort Private.level, x: A): A := x\nfunction bad(A: Sort Private.level, x: A): A := x\n",
   "PSCV0-SCOPE: unknown universe Private.level")]

private def declarationUniverseLevels : List (String × List String) := [
  ("identity", ["a"]), ("ordered", ["v", "u"]), ("inherited", ["u", "v"]),
  ("scopeDrop", ["w"]), ("repeatA", ["r"]), ("repeatB", ["r"]),
  ("constant", ["q"]), ("alias", ["b"]), ("sealed", ["o"]),
  ("reflexive", ["p"]), ("fromHidden", ["h"]), ("withHelper", ["k"]),
  ("Box", ["s"]), ("Tag", ["t"]), ("Picker", ["c"]), ("picker", ["i"])]

private def checkDeclarationUniverseSyntax (environment : PsEnvironment) : IO Unit := do
  let source := "def coreUniverseSyntax.{u.v, «u.v»} (A : Sort u.v) (B : Sort «u.v») (x : A) : A := x\n"
  let program ← match psCompilerParsePscv0Program .lean source with
    | .ok program => pure program
    | .error message => fail ("universe syntax control: " ++ message)
  let [.declaration original] := program.commands
    | fail "universe syntax command shape changed"
  let .definition name binders type value span := original
    | fail "universe syntax declaration shape changed"
  ensure (name.universeBinders.map (·.segments) == [["u", "v"], ["u.v"]] &&
      name.resolvedName.isNone &&
      name.span.stop.byteOffset == ("def coreUniverseSyntax.{u.v, «u.v»}").utf8ByteSize)
    "declaration universe components or complete source span changed"
  match psElabProgramWithOrigins environment program with
  | .ok _ => pure ()
  | .error _ => fail "parsed declaration universe source failed its positive AST control"
  for (kind, printer) in
      [(PsCompilerSourceKind.lean, psPrintLeanDeclaration),
       (PsCompilerSourceKind.proofScript, psPrintProofScriptDeclaration)] do
    let printed ← match printer original with
      | .ok printed => pure printed
      | .error _ => fail "declaration-only printer refused an owned universe suffix"
    let reparsed ← match psCompilerParsePscv0Program kind printed with
      | .ok parsed => pure parsed
      | .error message => fail ("printed universe declaration: " ++ message)
    let [.declaration declaration] := reparsed.commands
      | fail "printed declaration changed command kind"
    let head := (psElabOriginSource declaration).fst
    ensure (head.segments == name.segments &&
        head.universeBinders.map (·.segments) == name.universeBinders.map (·.segments) &&
        head.resolvedName.isNone)
      "declaration-only printer lost structural universe metadata"
  let misplaced := { name with segments := ["x"] }
  let badTerm := PsSyntaxTerm.reference misplaced
  let badBinder : PsSyntaxBinderHead := .mk misplaced .explicit span
  let sources : List PsSyntaxDeclaration := [
    .definition name binders type badTerm span,
    .definition name [(badBinder, type)] type value span,
    .whereDeclaration original [{
      name := misplaced, binders := [], type := some type, value := value,
      recursion := none, span := span }] span,
    .inductiveDecl { name with universeBinders := [] } [] none [{
      name := misplaced, fields := [], span := span }] span]
  for bad in sources do
    escapedScopeRefusal
      (psElabProgramWithOrigins environment { program with commands := [.declaration bad] })
      "misplaced universe source"
      "declaration universe binders occur outside a declaration head"
    escapedScopeRefusal (psElabDeclarations environment [bad] [])
      "misplaced legacy universe source"
      "declaration universe binders occur outside a declaration head"
  let commands : List PsSyntaxCommand := [
    .universeCmd [misplaced] span,
    .namespaceCmd misplaced span,
    .inspectionCmd (.printDeclaration misplaced false) span,
    .derivingDeclaration original [misplaced] false]
  for command in commands do
    escapedScopeRefusal (psElabCommand { environment := environment } command)
      "misplaced universe command target"
      "declaration universe binders occur outside a declaration head"
  let badImport : PsSyntaxImport := { moduleName := misplaced, span := span }
  escapedScopeRefusal
    (psElabProgramWithOrigins environment { program with imports := [badImport] })
    "misplaced universe import"
    "declaration universe binders occur outside a declaration head"
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    for head in ["bad.{}", "bad.{u,}", "bad.{u v}", "bad.{0}",
        "bad.{_}", "bad .{u}", "bad. {u}", "bad.{u"] do
      let malformed := match kind with
        | .lean => "def " ++ head ++ " (A : Type u) (x : A) : A := x\n"
        | .proofScript => "function " ++ head ++ "(A: Type u, x: A): A := x\n"
      match psCompilerParsePscv0Program kind malformed with
      | .error message =>
          ensure (message.startsWith "PSCV0-PARSE:")
            ("declaration universe grammar refusal phase: " ++ message)
      | .ok _ => fail ("malformed declaration universe suffix accepted: " ++ head)

private def checkDeclarationUniverses : IO Unit := do
  let (seed, profile) ← scopeContext
  checkDeclarationUniverseSyntax profile.baseEnvironment
  let mut paired : List String := []
  let mut mutualPairs : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let provider := importVisibilityInput kind "UniverseProvider" "" declarationUniverseProvider
    let client := importVisibilityInput kind "UniverseClient"
      "public import UniverseProvider\n" declarationUniverseClient
    let output ← prepare profile "UniverseClient" [client, provider]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let some receipt := output.moduleProfiles.find? (fun item => item.name == "UniverseProvider")
      | fail "declaration universe provider receipt missing"
    for (shortName, levelNames) in declarationUniverseLevels do
      let name := psNameAppendStr (psRootName "CoreUniverses") shortName
      let some declaration := output.prepared.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("declaration universe owner missing: " ++ shortName)
      ensure (sameNames (psDeclarationLevelParams declaration) (levelNames.map psRootName))
        ("declaration universe order changed: " ++ shortName)
      let some exposed := receipt.interface.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("declaration universe interface owner missing: " ++ shortName)
      ensure (sameNames (psDeclarationLevelParams exposed) (levelNames.map psRootName))
        ("declaration universe interface order changed: " ++ shortName)
    for (shortName, structural, quoted) in
        [("quoted", ["first", "level"], "first.level"),
         ("globalIdentity", ["command", "level"], "command.level")] do
      let name := psNameAppendStr (psRootName "CoreUniverses") shortName
      let some declaration := output.prepared.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("structural universe owner missing: " ++ shortName)
      ensure (sameNames (psDeclarationLevelParams declaration)
          [psSyntaxNameAppendSegments structural .anonymous, psRootName quoted])
        "qualified and quoted universe names collided or changed order"
    for (parts, levels) in
        [(["UniverseProvider", "CoreUniverses", "hidden"], ["h"]),
         (["UniverseProvider", "CoreUniverses", "withHelper", "helper"], ["k"])] do
      let name := psElabPrivateName parts
      let some declaration := output.prepared.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail "private universe owner disappeared from checked declarations"
      ensure (sameNames (psDeclarationLevelParams declaration) (levels.map psRootName) &&
          receipt.privateNames.any (psNameEq name) &&
          !receipt.interface.declarations.any
            (fun declaration => psNameEq (psDeclarationName declaration) name))
        "private universe identity, levels or visibility changed"
    ensure (receipt.interface.instances.any (fun entry =>
      sameNames entry.levelParams [psRootName "i"] && match entry.value with
        | .constE name _ => psNameEq name (psNameAppendStr (psRootName "CoreUniverses") "picker")
        | _ => false))
      "polymorphic instance import metadata lost declaration-owned universes"
    let mutualSource := importVisibilityInput kind "UniverseMutual" "" declarationUniverseMutual
    let mutualOutput ← prepare profile "UniverseMutual" [mutualSource]
    let _ ← admit seed mutualOutput.admissions
    mutualPairs := mutualPairs ++ [mutualOutput.admissions]
    for name in ["universeLeft", "universeRight"] do
      let declaration ← importVisibilityDeclaration mutualOutput name
      ensure (sameNames (psDeclarationLevelParams declaration) [psRootName "u"])
        "mutual declaration universe suffix expanded twice or lost order"
    for (label, lean, ps, expected) in declarationUniverseRefusals do
      let refused := importVisibilityInput kind ("Universe" ++ label) "" [(lean, ps)]
      refuse profile refused.name [refused] true expected
  let [left, right] := paired | fail "declaration universe source pair missing"
  ensure (left == right) "declaration universe paired admissions differ"
  let [left, right] := mutualPairs | fail "mutual universe source pair missing"
  ensure (left == right) "mutual universe paired admissions differ"
  IO.println "PSCV0_CORE_DECLARATION_UNIVERSES: four paired admitted projects, exact inherited/explicit order, private/where/instance ownership, structural universe names, 18 owned semantic refusals, 16 parse refusals, printers and source AST boundary controls passed"

private def qualifiedHeadProvider : List (String × String) := [
  ("namespace QualifiedHeads\n", "namespace QualifiedHeads\n"),
  ("public abbrev T.{u} (A : Type u) : Type u := A\n",
   "abbrev T.{u}(A: Type u): Type u := A\n"),
  ("public def choose.{u} (A : Type u) (x y : A) : A := x\n",
   "function choose.{u}(A: Type u, x: A, y: A): A := x\n"),
  ("private def hidden.{u} (A : Type u) (x y : A) : A := x\n",
   "private function hidden.{u}(A: Type u, x: A, y: A): A := x\n"),
  ("namespace Inner\n", "namespace Inner\n"),
  ("public abbrev Only.{u} (A : Type u) : Type u := A\n",
   "abbrev Only.{u}(A: Type u): Type u := A\n"),
  ("end Inner\nnamespace Left\n", "end Inner\nnamespace Left\n"),
  ("public def choose.{u} (A : Type u) (x y : A) : A := y\n",
   "function choose.{u}(A: Type u, x: A, y: A): A := y\n"),
  ("namespace Deep\n", "namespace Deep\n"),
  ("public def only.{u} (A : Type u) (x : A) : A := x\n",
   "function only.{u}(A: Type u, x: A): A := x\n"),
  ("end Deep\nend Left\nnamespace Right\n", "end Deep\nend Left\nnamespace Right\n"),
  ("public def choose.{u} (A : Type u) (x y : A) : A := y\n",
   "function choose.{u}(A: Type u, x: A, y: A): A := y\n"),
  ("end Right\nend QualifiedHeads\n", "end Right\nend QualifiedHeads\n"),
  ("public def QualifiedHeads.copy.{u} (A : Type u) (x y : T A) : T A := choose A x y\n",
   "function QualifiedHeads.copy.{u}(A: Type u, x: T A, y: T A): T A := choose(A, x, y)\n"),
  ("public def QualifiedHeads.withHelper.{u} (A : Type u) (x y : T A) : T A := helper x y\nwhere\n  helper (left right : T A) : T A := choose A left right\n",
   "function QualifiedHeads.withHelper.{u}(A: Type u, x: T A, y: T A): T A := helper(x, y)\nwhere {\n  def helper(left: T A, right: T A): T A := choose(A, left, right)\n}\n"),
  ("public theorem QualifiedHeads.law.{u} (A : Type u) (x y : T A) : choose A x y = x := by rfl\n",
   "theorem QualifiedHeads.law.{u}(A: Type u, x: T A, y: T A): choose(A, x, y) = x := by { rfl }\n"),
  ("public structure QualifiedHeads.Box.{u} (A : Type u) where\n  value : T A\n",
   "structure QualifiedHeads.Box.{u}(A: Type u) where { value: T A }\n"),
  ("public class QualifiedHeads.Echo.{u} (A : Type u) where\n  run : T A -> T A\n",
   "class QualifiedHeads.Echo.{u}(A: Type u) where { run: T A -> T A }\n"),
  ("public instance QualifiedHeads.echo.{u} {A : Type u} : Echo A where\n  run := fun (x : T A) => x\n",
   "instance QualifiedHeads.echo.{u}{A: Type u}: Echo A where { run := fun (x: T A) => x }\n"),
  ("private def QualifiedHeads.secret.{u} (A : Type u) (x y : T A) : T A := hidden A x y\n",
   "private function QualifiedHeads.secret.{u}(A: Type u, x: T A, y: T A): T A := hidden(A, x, y)\n"),
  ("public def QualifiedHeads.fromSecret.{u} (A : Type u) (x y : T A) : T A := secret A x y\n",
   "function QualifiedHeads.fromSecret.{u}(A: Type u, x: T A, y: T A): T A := secret(A, x, y)\n"),
  ("mutual\npublic def QualifiedHeads.Left.common.{u} (A : Type u) (x y : T A) : T A := choose A x y\npublic def QualifiedHeads.Right.common.{u} (A : Type u) (x y : T A) : T A := choose A x y\nend\n",
   "mutual {\nfunction QualifiedHeads.Left.common.{u}(A: Type u, x: T A, y: T A): T A := choose(A, x, y)\nfunction QualifiedHeads.Right.common.{u}(A: Type u, x: T A, y: T A): T A := choose(A, x, y)\n}\n"),
  ("public theorem QualifiedHeads.commonLeftRfl.{u} (A : Type u) (x y : A) : Left.common A x y = x := by rfl\n",
   "theorem QualifiedHeads.commonLeftRfl.{u}(A: Type u, x: A, y: A): Left.common(A, x, y) = x := by { rfl }\n"),
  ("public theorem QualifiedHeads.commonRightRfl.{u} (A : Type u) (x y : A) : Right.common A x y = x := by rfl\n",
   "theorem QualifiedHeads.commonRightRfl.{u}(A: Type u, x: A, y: A): Right.common(A, x, y) = x := by { rfl }\n"),
  ("namespace OuterQualified\n", "namespace OuterQualified\n"),
  ("public abbrev T.{u} (A : Type u) : Type u := A\n",
   "abbrev T.{u}(A: Type u): Type u := A\n"),
  ("public def outerOnly.{u} (A : Type u) (x : A) : A := x\n",
   "function outerOnly.{u}(A: Type u, x: A): A := x\n"),
  ("public def _root_.QualifiedHeads.rooted.{u} (A : Type u) (x : T A) : T A := outerOnly A x\n",
   "function _root_.QualifiedHeads.rooted.{u}(A: Type u, x: T A): T A := outerOnly(A, x)\n"),
  ("end OuterQualified\n", "end OuterQualified\n"),
  ("public def qualifiedFollowing.{u} (A : Type u) (x y : A) : A := QualifiedHeads.copy A x y\n",
   "function qualifiedFollowing.{u}(A: Type u, x: A, y: A): A := QualifiedHeads.copy(A, x, y)\n")]

private def qualifiedHeadClient : List (String × String) := [
  ("public def qualifiedClient.{u} (A : Type u) (x y : A) : A := QualifiedHeads.withHelper A (QualifiedHeads.fromSecret A x y) y\n",
   "function qualifiedClient.{u}(A: Type u, x: A, y: A): A := QualifiedHeads.withHelper(A, QualifiedHeads.fromSecret(A, x, y), y)\n"),
  ("public theorem qualifiedClientProof.{u} (A : Type u) (x y : A) : QualifiedHeads.Left.common A x y = x := QualifiedHeads.commonLeftRfl A x y\n",
   "theorem qualifiedClientProof.{u}(A: Type u, x: A, y: A): QualifiedHeads.Left.common(A, x, y) = x := QualifiedHeads.commonLeftRfl(A, x, y)\n"),
  ("public theorem qualifiedClientInstance.{u} (A : Type u) (x : A) : QualifiedHeads.Echo.run x (A := A) = x := by rfl\n",
   "theorem qualifiedClientInstance.{u}(A: Type u, x: A): QualifiedHeads.Echo.run(x, A := A) = x := by { rfl }\n")]

private def qualifiedHeadRefusals : List (String × String × String × String) := [
  ("Rooted", "public def _root_.QualifiedHeads.bad (A : Type) (x : Inner.Only A) : A := x\n",
   "function _root_.QualifiedHeads.bad(A: Type, x: Inner.Only A): A := x\n",
   "PSCV0-SCOPE: unknown name Inner.Only"),
  ("MutualChildren", "mutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def QualifiedHeads.Right.bad (A : Type) (x : A) : A := x\nend\n",
   "mutual {\nfunction QualifiedHeads.Left.bad(A: Type, x: A): A := Deep.only(A, x)\nfunction QualifiedHeads.Right.bad(A: Type, x: A): A := x\n}\n",
   "PSCV0-SCOPE: unknown name Deep.only"),
  ("MutualPlain", "mutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def qualifiedPlain (A : Type) (x : A) : A := x\nend\n",
   "mutual {\nfunction QualifiedHeads.Left.bad(A: Type, x: A): A := Deep.only(A, x)\nfunction qualifiedPlain(A: Type, x: A): A := x\n}\n",
   "PSCV0-SCOPE: unknown name Deep.only"),
  ("MutualRooted", "mutual\npublic def QualifiedHeads.Left.bad (A : Type) (x : A) : A := Deep.only A x\npublic def _root_.QualifiedHeads.Right.bad (A : Type) (x : A) : A := x\nend\n",
   "mutual {\nfunction QualifiedHeads.Left.bad(A: Type, x: A): A := Deep.only(A, x)\nfunction _root_.QualifiedHeads.Right.bad(A: Type, x: A): A := x\n}\n",
   "PSCV0-SCOPE: unknown name Deep.only")]

private def checkQualifiedDeclarationHeads : IO Unit := do
  let (seed, profile) ← scopeContext
  let mut paired : List String := []
  for kind in [PsCompilerSourceKind.lean, .proofScript] do
    let provider := importVisibilityInput kind "QualifiedProvider" "" qualifiedHeadProvider
    let client := importVisibilityInput kind "QualifiedClient"
      "public import QualifiedProvider\n" qualifiedHeadClient
    let output ← prepare profile "QualifiedClient" [client, provider]
    let _ ← admit seed output.admissions
    paired := paired ++ [output.admissions]
    let nameOf := fun (text : String) => psSyntaxNameAppendSegments (text.splitOn ".") .anonymous
    let findDeclaration : String → IO PsDeclaration := fun text => do
      let name := nameOf text
      let some declaration := output.prepared.declarations.find?
          (fun declaration => psNameEq (psDeclarationName declaration) name)
        | fail ("qualified declaration owner missing: " ++ text)
      pure declaration
    for text in ["QualifiedHeads.copy", "QualifiedHeads.withHelper", "QualifiedHeads.law",
        "QualifiedHeads.Box", "QualifiedHeads.Echo", "QualifiedHeads.echo",
        "QualifiedHeads.fromSecret", "QualifiedHeads.Left.common",
        "QualifiedHeads.Right.common", "QualifiedHeads.rooted", "qualifiedFollowing"] do
      let declaration ← findDeclaration text
      ensure (sameNames (psDeclarationLevelParams declaration) [psRootName "u"])
        ("qualified declaration lost its single universe suffix: " ++ text)
    let copy ← findDeclaration "QualifiedHeads.copy"
    ensure ((psPscv0ExprConstants (psDeclarationType copy)).any
        (psNameEq (nameOf "QualifiedHeads.T")))
      "qualified declaration header did not use its temporary namespace"
    let rooted ← findDeclaration "QualifiedHeads.rooted"
    ensure ((psPscv0ExprConstants (psDeclarationType rooted)).any
        (psNameEq (nameOf "OuterQualified.T")))
      "rooted declaration incorrectly entered its declaration's parent namespace"
    for text in ["QualifiedHeads.copy", "QualifiedHeads.Left.common",
        "QualifiedHeads.Right.common"] do
      let declaration ← findDeclaration text
      let some body := psDeclarationValue declaration
        | fail "qualified definition body missing"
      ensure ((psPscv0ExprConstants body).any
          (psNameEq (nameOf "QualifiedHeads.choose")) &&
          !(psPscv0ExprConstants body).any
            (psNameEq (nameOf "QualifiedHeads.Left.choose")) &&
          !(psPscv0ExprConstants body).any
            (psNameEq (nameOf "QualifiedHeads.Right.choose")))
        "qualified/mutual body lookup selected a child namespace instead of the native common scope"
    let hidden := psElabPrivateName ["QualifiedProvider", "QualifiedHeads", "secret"]
    let some secret := output.prepared.declarations.find?
        (fun declaration => psNameEq (psDeclarationName declaration) hidden)
      | fail "qualified private declaration lost its canonical identity"
    ensure (sameNames (psDeclarationLevelParams secret) [psRootName "u"] &&
        (psPscv0ExprConstants (psDeclarationType secret)).any
          (psNameEq (nameOf "QualifiedHeads.T")))
      "qualified private header used its internal identity as a source namespace"
    for (label, lean, ps, expected) in qualifiedHeadRefusals do
      let refused := importVisibilityInput kind ("Qualified" ++ label)
        "public import QualifiedProvider\n" [(lean, ps)]
      refuse profile refused.name [refused, provider] true expected
  let [left, right] := paired | fail "qualified declaration source pair missing"
  ensure (left == right) "qualified declaration paired admissions differ"
  IO.println "PSCV0_CORE_QUALIFIED_DECLARATIONS: two paired admitted projects, ordinary/where/theorem/data/instance/private heads, exact rooted and common-mutual namespace behavior, preserved universe suffixes and following scope, eight owned refusals passed"

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
  checkComponentScopes
  checkRootedScopes
  checkLegacyImports
  checkLegacyLocalPrivate
  checkLegacyMetadata
  checkLegacyWhere
  checkRegisteredValues
  checkSourceAttributes
  checkConnectiveAttributes
  checkExposedProofs
  checkEscapedIdentifiers
  checkDeclarationUniverses
  checkQualifiedDeclarationHeads
  IO.println "PSCV0_CORE_PROJECT: paired modules, profile, kernel, graph, visibility and typed runtime controls passed"
