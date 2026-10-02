import Ps.Bootstrap.SelfHost
import Ps.Host.ProjectCompiler
import Lean.Data.Json

-- Native-host regression and diagnostics only; not in the portable source closure.
theorem psAuditAppendRuntimeArgumentPreservesOrder
    (arguments : List PsVerifiedIrExpr) (argument : PsVerifiedIrExpr) :
    psErasureAppendRuntimeArgument arguments argument = arguments ++ [argument] := by
  induction arguments with
  | nil => rfl
  | cons head rest ih =>
      change List.cons head (psErasureAppendRuntimeArgument rest argument) =
        List.cons head (rest ++ [argument])
      exact congrArg (List.cons head) ih

def psAuditRuntimeNames (values : List PsVerifiedIrExpr) : List String :=
  values.map fun value => match value with
    | .var name => name
    | _ => "<not-var>"

def psAuditFinish (fuel : Nat) (type : PsExpr) (arguments : List PsVerifiedIrExpr) :=
  psEraseFinishApplicationWithFuel psBootstrapPreludeEnvironment
    (psErasureScopeEmpty []) (.var "f") [] fuel type [] arguments

def psAuditNat : PsExpr := PsExpr.constE psNatName []

def psAuditRuntimeBinders : Bool :=
  let type := PsExpr.forallE (psRootName "x") psAuditNat
    (PsExpr.forallE (psRootName "y") psAuditNat psAuditNat .explicit) .explicit
  match psAuditFinish 4 type [.var "existing"] with
  | Except.ok (.lambda parameters (.primitive .nat) (.call (.var "f") [] arguments)) =>
      parameters.map (fun parameter => parameter.name) == ["x$0", "y$1"] &&
        psAuditRuntimeNames arguments == ["existing", "x$0", "y$1"]
  | _ => false

def psAuditProofBinders : Bool :=
  let type := PsExpr.forallE (psRootName "p") (.sortE .zero)
    (PsExpr.forallE (psRootName "h") (.bvar 0)
      (PsExpr.forallE (psRootName "x") psAuditNat psAuditNat .explicit) .explicit) .explicit
  match psAuditFinish 5 type [] with
  | Except.ok (.lambda parameters (.primitive .nat) (.call (.var "f") [] arguments)) =>
      parameters.map (fun parameter => parameter.name) == ["x$2"] &&
        psAuditRuntimeNames arguments == ["x$2"]
  | _ => false

def psAuditName : Bool :=
  let type := PsExpr.forallE (psRootName "bad-name") psAuditNat psAuditNat .explicit
  match psAuditFinish 2 type [] with
  | Except.ok (.lambda parameters _ _) =>
      parameters.map (fun parameter => parameter.name) == ["bad_name$0"]
  | _ => false

def psAuditBaseCases : Bool :=
  let empty := match psAuditFinish 1 psAuditNat [] with
    | Except.ok (.var "f") => true
    | _ => false
  let ordered := match psAuditFinish 1 psAuditNat [.var "a", .var "b"] with
    | Except.ok (.call (.var "f") [] arguments) => psAuditRuntimeNames arguments == ["a", "b"]
    | _ => false
  let exhausted := match psAuditFinish 0 psAuditNat [] with
    | Except.error .fuelExhausted => true
    | _ => false
  let typeBinder := PsExpr.forallE (psRootName "T") (.sortE (.succ .zero)) psAuditNat .explicit
  let rejected := match psAuditFinish 2 typeBinder [] with
    | Except.error .unsupportedApplication => true
    | _ => false
  empty && ordered && exhausted && rejected

def psAuditStringPositionSingletons : Bool :=
  ["String.Pos.Raw.mk", "String.Pos.Raw.byteIdx"].all fun name =>
    let run := fun (args : List PsExpr)
        (erase : PsExpr -> Except PsErasureError PsVerifiedIrExpr) =>
      psErasePrimitiveApplication psBootstrapPreludeEnvironment
        (psErasureScopeEmpty []) erase
        { head := .constE (psRootName name) [], args := args }
    let value := PsExpr.lit (.natural 7)
    let erase := fun expr => match expr with
      | .lit (.natural n) => Except.ok (PsVerifiedIrExpr.literal (.natural n))
      | _ => Except.error PsErasureError.unsupportedRuntimeTerm
    let accepted := match run [value] erase with
      | Except.ok (some (.literal (.natural n))) => n == 7
      | _ => false
    let propagated := match run [value] (fun _ => Except.error .fuelExhausted) with
      | Except.error .fuelExhausted => true
      | _ => false
    let rejected := [[], [value, value]].all fun args =>
      -- A distinct callback error also checks rejection happens before erasure.
      match run args (fun _ => Except.error .fuelExhausted) with
      | Except.error .unsupportedApplication => true
      | _ => false
    accepted && propagated && rejected

def psAuditConditionBranches : Bool :=
  let apply := fun (head : PsName) (args : List PsExpr) =>
    args.foldl PsExpr.app (.constE head [])
  let boolType := PsExpr.constE psBoolName []
  let stringType := PsExpr.constE psStringName []
  let left := PsExpr.lit (.string "left")
  let right := PsExpr.lit (.string "right")
  let erase := fun (expr : PsExpr) => match expr with
    | .lit (.string value) => Except.ok (PsVerifiedIrExpr.literal (.string value))
    | _ => Except.error PsErasureError.fuelExhausted
  let boolAccepted := match psEraseCondition erase
      (apply psEqName [boolType, left, .constE psBoolTrueName []]) with
    | Except.ok (.literal (.string value)) => value == "left"
    | _ => false
  let stringAccepted := match psEraseCondition erase
      (apply psEqName [stringType, left, right]) with
    | Except.ok (.intrinsic .stringEq [] [.literal (.string a), .literal (.string b)]) =>
        a == "left" && b == "right"
    | _ => false
  let malformed := [[], [stringType], [stringType, left], [stringType, left, right, right],
    [boolType, left, .constE psBoolFalseName []], [psAuditNat, left, right]]
  let rejected := malformed.all fun args =>
    match psEraseCondition erase (apply psEqName args) with
    | Except.error .unsupportedApplication => true
    | _ => false
  let errors := [([stringType, .fvar 0, right] : List PsExpr), [stringType, left, .fvar 0]]
  let propagated := errors.all fun args =>
    match psEraseCondition erase (apply psEqName args) with
    | Except.error .fuelExhausted => true
    | _ => false
  boolAccepted && stringAccepted && rejected && propagated

def psAuditSanitizer : Bool :=
  let original := fun (raw fallback : String) =>
    let mapped := String.ofList (raw.toList.map fun char =>
      if char.isAlphanum || char == '_' || char == '$' then char else '_')
    let base := if mapped.isEmpty then fallback else mapped
    match base.toList with
    | [] => fallback
    | first :: _ =>
        if first.isAlpha || first == '_' || first == '$' then base else "_" ++ base
  let ascii := (List.range 128).map fun value => String.singleton (Char.ofNat value)
  let samples := ascii ++ ["", "a-b", "123", "αβ", "雪", "😀", "á", "x😀2", "$_ok"]
  samples.all fun raw => ["", "fallback", "9fallback", "λ"].all fun fallback =>
    psErasureSafeIdentifier raw fallback == original raw fallback

def psAuditCollections : Bool :=
  let values : List Nat := [3, 1, 4, 1]
  let reject := fun (value : Nat) =>
    if value == 1 then Except.error "first" else
    if value == 4 then Except.error "later" else Except.ok (value + 10)
  let propagated := match psListMapExcept reject values with
    | Except.error message => message == "first"
    | _ => false
  let mapped := match psListMapExcept (fun (value : Nat) => (Except.ok (value + 10) : Except String Nat)) values with
    | Except.ok result => result == [13, 11, 14, 11]
    | _ => false
  psListLength values == 4 && !psListIsEmpty values && psListIsEmpty ([] : List Nat) &&
    psListReverse values == values.reverse && psListMap Nat.succ values == values.map Nat.succ &&
    (List.range 7).all (fun count => psListTake count values == values.take count) &&
    psListZip values ["a", "b"] == [(3, "a"), (1, "b")] &&
    psListZip ([] : List Nat) ["a"] == [] && mapped && propagated

def psAuditUniqueNames : Bool :=
  psErasureAddUniqueString ["x", "x_"] "x" 3 == "x__" &&
    psErasureAddUniqueString ["x", "x_"] "x" 2 == "x___overflow" &&
    psErasureAddUniqueString [] "free" 1 == "free" &&
    psErasureAddUniqueString [] "free" 0 == "free_overflow"

def psAuditIntRepr : Bool :=
  let compiled := psCompilerTypeScriptSource PsCompilerSourceKind.lean
    "def renderInt (value : Int) : String := Int.repr value"
  let emitted := match compiled with
    | Except.ok output => output.contains "return (value).toString();"
    | Except.error _ => false
  let run := fun args erase => psErasePrimitiveApplication psBootstrapPreludeEnvironment
    (psErasureScopeEmpty []) erase { head := .constE psIntReprName [], args := args }
  let rejected := [[], [.fvar 0, .fvar 1]].all fun args =>
    match run args (fun _ => Except.error .fuelExhausted) with
    | Except.error .unsupportedApplication => true
    | _ => false
  let propagated := match run [.fvar 0] (fun _ => Except.error .fuelExhausted) with
    | Except.error .fuelExhausted => true
    | _ => false
  emitted && rejected && propagated

def psAuditWatchModule (file : String) : IO UInt32 := do
  let initial ← psHostParseSource file (← IO.FS.readFile file)
  let root := psHostDirectoryOfPath file
  IO.println ("PSC2_REPLAY_WATCH_LOADING: " ++ file)
  let imported ← psHostLoadImportsWithFuel 4096 root [file] initial.imports {
    environment := psSelfHostProdPreludeEnvironment
    declarations := []
    loadedPaths := []
  }
  let snapshots ← imported.loadedPaths.mapM fun (path : String) => do
    return (path, ← IO.FS.readFile path)
  let importNames := initial.imports.map fun item => psHostModuleRelativePath item.moduleName
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  IO.println "PSC2_REPLAY_WATCH_READY: check or quit (diagnostic only)"
  stdout.flush
  repeat
    let command ← stdin.getLine
    if command.isEmpty || command.startsWith "quit" then return 0
    if !command.startsWith "check" then
      IO.println "PSC2_REPLAY_WATCH_COMMAND: expected check or quit"
    else
      for (path, original) in snapshots do
        if (← IO.FS.readFile path) != original then
          throw (IO.userError ("PSC2_REPLAY_WATCH_IMPORT_CHANGED: restart for " ++ path))
      try
        let current ← psHostParseSource file (← IO.FS.readFile file)
        if current.imports.map (fun item => psHostModuleRelativePath item.moduleName) != importNames then
          throw (IO.userError "PSC2_REPLAY_WATCH_IMPORT_LIST_CHANGED: restart")
        let elaborated ← psHostElabDeclarationsDetailed file imported.environment current.declarations []
        IO.println ("PSC2_REPLAY_WATCH_ELAB_PASS: " ++ toString elaborated.declarations.length ++ " declarations")
      catch error => IO.println error.toString
    stdout.flush
  return 0

def psAuditTotalStringWorkers : Bool := Id.run do
  let strings : List String := ["", "ascii!", "éλ😀", "x\ny", "𐀀a"]
  for source in strings do
    if psLexStringToList source != String.toList source then return false
    for position in List.range (String.utf8ByteSize source + 2) do
      if !psStringEqFrom source source position position then return false
      if psErasureSafeStringFrom source position "prefix" !=
          "prefix" ++ String.ofList ((psLexStringToListFrom source position).map psErasureSafeChar) then
        return false
  for value in [0, 1, 9, 10, 999, 9007199254740993, 123456789012345678901234567890] do
    if psNatToString value != toString value then return false
    if psCheckedAdmissionNatToString value != toString value then return false
  for left in ["", "a", "é", "aa", "ab", "😀", "中x", "name", "namespace"] do
    for right in ["", "a", "é", "aa", "ab", "😀", "中x", "name", "namespace"] do
      if psStringEq left right != (left == right) then return false
  return true

def psAuditTotalJsonWorkers : Bool :=
  let conversion := Id.run do
    for source in ["", "abc", "é中😀", String.ofList (List.replicate 20000 'a')] do
      for fuel in [0, 1, 2, 3, 10, source.utf8ByteSize + 1] do
        if psJsonStringCharsWithFuel fuel source 0 != source.toList.take fuel then return false
    return true
  let exhausted := match psJsonEncodeCanonicalWithFuel 0 .nullE with
    | .error .fuelExhausted => true
    | _ => false
  let boundary := match psJsonEncodeCanonicalWithFuel 1 (.array [.nullE]) with
    | .error .fuelExhausted => true
    | _ => false
  let accepted := match psJsonEncodeCanonicalWithFuel 2 (.array [.nullE]) with
    | .ok "[null]" => true
    | _ => false
  let nested := match psJsonParse "{\"z\":[true,null],\"a\":-12}" with
    | .error _ => false
    | .ok value => match psJsonEncodeCanonical value with
      | .ok "{\"a\":-12,\"z\":[true,null]}" => true
      | _ => false
  let parserBoundary := match psJsonParseValueWithFuel (.error .fuelExhausted) 2 ['[', 'n', 'u', 'l', 'l', ']'] with
    | .error .fuelExhausted => true
    | _ => false
  conversion && exhausted && boundary && accepted && nested && parserBoundary

def psAuditLegacyMetaRounds (context : PsMetaContext) : Nat -> PsExpr -> PsExpr
  | 0, expr => expr
  | n + 1, expr => psAuditLegacyMetaRounds context n (psMetaInstantiateStep context expr)

def psAuditMetaFixedPoint : Bool := Id.run do
  for count in [0, 1, 2, 8, 32] do
    let assignments := (List.range count).map fun id =>
      PsMetaAssignment.mk id (if id + 1 < count then .mvar (id + 1) else .lit (.natural 17))
    let context := { psMetaEmpty with assignments := assignments }
    let name := psRootName "binder"
    let leaf : PsExpr := .mvar 0
    let samples := [leaf, .mvar 999, .app leaf leaf,
      .lam name leaf leaf .explicit, .forallE name leaf leaf .explicit,
      .letE name leaf leaf leaf, .proj name 0 leaf,
      .app (.constE psNatName []) (.lit (.natural 3))]
    for sample in samples do
      for fuel in [0, 1, 2, count, count + 1] do
        if !psExprAlphaEq (psMetaInstantiateRounds context fuel sample)
            (psAuditLegacyMetaRounds context fuel sample) then return false
  let cyclic := { psMetaEmpty with assignments := [⟨0, .mvar 1⟩, ⟨1, .mvar 0⟩] }
  let cycleOk := (List.range 12).all fun fuel =>
    psExprAlphaEq (psMetaInstantiateRounds cyclic fuel (.mvar 0))
      (psAuditLegacyMetaRounds cyclic fuel (.mvar 0))
  let levels := { psLevelMetaEmpty with assignments := [⟨0, .zero⟩] }
  let context := { psMetaEmpty with levels := levels }
  return cycleOk && psExprAlphaEq (psMetaInstantiate context (.sortE (.mvar 0))) (.sortE .zero)

def psAuditLexerInputBound : Bool :=
  let sources := ["42", "    42", "-- é中😀\n42", "/- outer /- inner -/ done -/42"]
  let oneToken := sources.all fun source =>
    match psLexAllWithFuel 1 (psLexCursorFromString source) with
    | .ok [token, eof] =>
        psTokenKindEq token.kind .natural && token.text == "42" &&
        token.span.stop.byteOffset == source.utf8ByteSize &&
        psTokenKindEq eof.kind .endOfInput && eof.span.start.byteOffset == source.utf8ByteSize
    | _ => false
  let exhausted := match psLexAllWithFuel 0 (psLexCursorFromString "42") with
    | .error .fuelExhausted => true | _ => false
  let empty := match psLexAllWithFuel 0 (psLexCursorFromString "") with
    | .ok [token] => psTokenKindEq token.kind .endOfInput | _ => false
  let malformed := match psLexAllWithFuel 1 (psLexCursorFromString "/- unfinished") with
    | .error (.unterminatedBlockComment _) => true | _ => false
  oneToken && exhausted && empty && malformed

def psAuditModularPreparation : Bool :=
  let sources := [
    "inductive ReplayChoice where | first | second\n",
    "def replayChoice (choice : ReplayChoice) : Nat := match choice with | ReplayChoice.first => 1 | ReplayChoice.second => 2\n",
    "def replaySelected : Nat := replayChoice ReplayChoice.second\n"]
  let same := match psCompilerPrepareSources .lean sources,
      psCompilerPrepareSource .lean (String.intercalate "\n\n" sources) with
    | .ok modules, .ok flat =>
        match psCompilerAdmissionsFromPrepared modules, psCompilerAdmissionsFromPrepared flat with
        | .ok left, .ok right => left == right
        | _, _ => false
    | _, _ => false
  let rejects := match psCompilerPrepareSources .lean ["def first : Nat := 1", "def bad : Nat := Type"] with
    | .error _ => true
    | .ok _ => false
  same && rejects

def psAuditErasureError (error : PsErasureError) : String :=
  match error with
  | .fuelExhausted => "fuelExhausted"
  | .binderMismatch => "binderMismatch"
  | .looseBoundVariable => "looseBoundVariable"
  | .unresolvedMetavariable => "unresolvedMetavariable"
  | .unknownLocal id => "unknownLocal:" ++ toString id
  | .erasedLocalUsed id => "erasedLocalUsed:" ++ toString id
  | .unsupportedRuntimeTerm => "unsupportedRuntimeTerm"
  | .unsupportedApplication => "unsupportedApplication"
  | .unknownConstant name => "unknownConstant:" ++ psNameToString name

def psAuditErasureDetails (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  let environment ← match psCompilerEnvironmentFromPrepared prepared with
    | .error _ => throw (IO.userError "PSC2_REPLAY_ENVIRONMENT_FAILED")
    | .ok environment => pure environment
  let declarations := prepared.declarations
  let runtimeDeclarations := psSelfHostRuntimePreludeDeclarationsWithProd ++ declarations
  let scope := psErasureScopeEmpty (psErasureDeclarationNames runtimeDeclarations)
  let structures ← match psPrepareRuntimeStructures environment runtimeDeclarations runtimeDeclarations scope [] with
    | .error error => throw (IO.userError ("PSC2_REPLAY_STRUCTURES_FAILED: " ++ psAuditErasureError error))
    | .ok result => pure result
  let inductives ← match psPrepareRuntimeInductives environment runtimeDeclarations runtimeDeclarations structures.scope [] with
    | .error error => throw (IO.userError ("PSC2_REPLAY_INDUCTIVES_FAILED: " ++ psAuditErasureError error))
    | .ok result => pure result
  let mut failures := 0
  for declaration in declarations do
    match declaration with
    | .definitionDecl name _ type value =>
        match psEraseDefinition environment inductives.scope name type value with
        | .error error =>
            failures := failures + 1
            IO.println ("PSC2_REPLAY_ERASURE_FAILED: " ++ psNameToString name ++ ": " ++ psAuditErasureError error)
        | .ok _ => pure ()
    | _ => pure ()
  IO.println ("PSC2_REPLAY_ERASURE_FAILURE_COUNT: " ++ toString failures)

def psAuditEnvironmentIndex : Bool := Id.run do
  let names := [psRootName "Aa", psRootName "BB", psRootName "é", psRootName "中",
    .num .anonymous 0, .num .anonymous 65521, .num (.str .anonymous "n") 9007199254740993]
    ++ (List.range 1000).map (fun index => psRootName ("declaration" ++ toString index))
  let mut environment := psEnvironmentEmpty
  let mut number := 0
  for name in names do
    let declaration := PsDeclaration.definitionDecl name [] (.constE psNatName []) (.lit (.natural number))
    let .some next := psEnvironmentAdd environment declaration | return false
    if (psEnvironmentFind environment name).isSome then return false
    if (psEnvironmentAdd next declaration).isSome then return false
    environment := next
    number := number + 1
  number := 0
  for name in names do
    let .some (.definitionDecl actual _ _ value) := psEnvironmentFind environment name | return false
    if !psNameEq actual name || !psExprAlphaEq value (.lit (.natural number)) then return false
    let .some reference := psEnvironmentFindInList name environment.declarations | return false
    if !psNameEq (psDeclarationName reference) actual then return false
    number := number + 1
  if (psEnvironmentFind environment (psRootName "missing")).isSome then return false
  let replaceName := psRootName "placeholder"
  let .some before := psEnvironmentAdd environment (.axiomDecl replaceName [] (.constE psNatName [])) | return false
  let replacement := PsDeclaration.definitionDecl replaceName [] (.constE psNatName []) (.lit (.natural 42))
  let .some after := psEnvironmentAddReplacingAxiom before replacement | return false
  let .some (.axiomDecl _ _ _) := psEnvironmentFind before replaceName | return false
  let .some (.definitionDecl _ _ _ value) := psEnvironmentFind after replaceName | return false
  return psExprAlphaEq value (.lit (.natural 42)) &&
    before.declarations.length == after.declarations.length &&
    (psEnvironmentAddReplacingAxiom after replacement).isNone &&
    psEnvironmentNameHash (psRootName "Aa") == psEnvironmentNameHash (psRootName "BB")

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["--watch", file] => return ← psAuditWatchModule file
  | ["--prepare-modules", file, output] =>
      let start ← IO.monoMsNow
      let .ok json := Lean.Json.parse (← IO.FS.readFile file)
        | throw (IO.userError "PSC2_MODULES_JSON_FAILED")
      let .ok entries := json.getArr?
        | throw (IO.userError "PSC2_MODULES_ARRAY_FAILED")
      let sources ← entries.toList.mapM fun entry =>
        match entry.getStr? with
        | .error _ => throw (IO.userError "PSC2_MODULES_TEXT_FAILED")
        | .ok text => pure text
      let .ok prepared := psCompilerPrepareSources .lean sources
        | throw (IO.userError "PSC2_MODULES_PREPARE_FAILED")
      IO.println ("PSC2_MODULES_PREPARE_PASS: " ++ toString prepared.declarations.length ++ " declarations in " ++ toString ((← IO.monoMsNow) - start) ++ "ms")
      (← IO.getStdout).flush
      let .ok admissions := psCompilerAdmissionsFromPrepared prepared
        | throw (IO.userError "PSC2_MODULES_INTEGRITY_FAILED")
      IO.FS.writeFile output admissions
      IO.println ("PSC2_MODULES_ADMISSIONS_PASS: " ++ toString admissions.utf8ByteSize ++ " bytes in " ++ toString ((← IO.monoMsNow) - start) ++ "ms")
      return 0
  | ["--profile-source", file] =>
      let source ← IO.FS.readFile file
      let stdout ← IO.getStdout
      let start ← IO.monoMsNow
      IO.println ("PSC2_PROFILE_SOURCE_BYTES: " ++ toString source.utf8ByteSize)
      stdout.flush
      let parsed ← match psCompilerParseSource .lean source with
        | .error _ => throw (IO.userError "PSC2_PROFILE_PARSE_FAILED")
        | .ok parsed => pure parsed
      IO.println ("PSC2_PROFILE_PARSE_MS: " ++ toString ((← IO.monoMsNow) - start))
      stdout.flush
      let elaborated ← match psCompilerElaborateModule parsed with
        | .error _ => throw (IO.userError "PSC2_PROFILE_ELAB_FAILED")
        | .ok elaborated => pure elaborated
      IO.println ("PSC2_PROFILE_ELAB_MS: " ++ toString ((← IO.monoMsNow) - start))
      stdout.flush
      let prepared ← match psCompilerPrepareElaborated elaborated with
        | .error _ => throw (IO.userError "PSC2_PROFILE_PREPARE_FAILED")
        | .ok prepared => pure prepared
      IO.println ("PSC2_PROFILE_PREPARE_MS: " ++ toString ((← IO.monoMsNow) - start))
      stdout.flush
      let admissions ← match psCompilerAdmissionsFromPrepared prepared with
        | .error _ => throw (IO.userError "PSC2_PROFILE_VALIDATE_FAILED")
        | .ok admissions => pure admissions
      IO.println ("PSC2_PROFILE_ADMISSION_BYTES: " ++ toString admissions.utf8ByteSize)
      IO.println ("PSC2_PROFILE_VALIDATE_MS: " ++ toString ((← IO.monoMsNow) - start))
      stdout.flush
      let quoted := psJsonQuote admissions
      IO.println ("PSC2_PROFILE_QUOTE_MS: " ++ toString ((← IO.monoMsNow) - start) ++ " bytes=" ++ toString quoted.utf8ByteSize)
      return 0
  | ["--compile", file, output] =>
      let elaborated ← psHostLoadProject psSelfHostProdPreludeEnvironment file
      IO.println ("PSC2_REPLAY_PROJECT_ELAB_PASS: " ++ toString elaborated.declarations.length ++ " declarations")
      let prepared ← match psCompilerPrepareElaborated elaborated with
        | .error _ => throw (IO.userError "PSC2_REPLAY_PROJECT_PREPARE_FAILED")
        | .ok prepared => pure prepared
      IO.println "PSC2_REPLAY_PROJECT_PREPARE_PASS"
      match psCompilerTypeScriptFromPrepared prepared with
      | .error (.compiler (.erasure error)) =>
          IO.println ("PSC2_REPLAY_PROJECT_ERASURE_FAILED: " ++ psAuditErasureError error)
          psAuditErasureDetails prepared
          return 1
      | .error _ => throw (IO.userError "PSC2_REPLAY_PROJECT_EMIT_FAILED")
      | .ok source =>
          IO.FS.writeFile output source
          IO.println ("PSC2_REPLAY_PROJECT_EMIT_PASS: " ++ output)
          return 0
  | ["--prepare", file] =>
      let elaborated ← psHostLoadProject psSelfHostProdPreludeEnvironment file
      IO.println ("PSC2_REPLAY_PROJECT_ELAB_PASS: " ++ toString elaborated.declarations.length ++ " declarations")
      match psCompilerPrepareElaborated elaborated with
      | Except.ok _ =>
          IO.println "PSC2_REPLAY_PROJECT_PREPARE_PASS"
          return 0
      | Except.error (.admission error) =>
          let detail := match error with
            | .universeMetavariable => "universeMetavariable"
            | .freeVariable => "freeVariable"
            | .expressionMetavariable => "expressionMetavariable"
            | .missingConstructor name => "missingConstructor:" ++ psNameToString name
            | .mismatchedConstructor name => "mismatchedConstructor:" ++ psNameToString name
            | .unsupportedDeclaration => "unsupportedDeclaration"
          IO.println ("PSC2_REPLAY_PROJECT_PREPARE_FAILED: " ++ detail)
          for declaration in elaborated.declarations do
            match declaration with
            | .partialDecl name _ _ _ => IO.println ("PSC2_REPLAY_PARTIAL_DECLARATION: " ++ psNameToString name)
            | .axiomDecl name _ _ => IO.println ("PSC2_REPLAY_AXIOM_DECLARATION: " ++ psNameToString name)
            | .opaqueDecl name _ _ _ => IO.println ("PSC2_REPLAY_OPAQUE_DECLARATION: " ++ psNameToString name)
            | _ => pure ()
          return 1
      | Except.error _ => throw (IO.userError "PSC2_REPLAY_PROJECT_PREPARE_FAILED: compiler error")
  | _ => pure ()
  if arguments == ["--behavior"] then
    for (label, passed) in [("runtime argument and parameter order", psAuditRuntimeBinders),
        ("proof erasure and local IDs", psAuditProofBinders),
        ("sanitized parameter names", psAuditName),
        ("base cases, fuel and unsupported type binder", psAuditBaseCases),
        ("String.Pos.Raw singleton arity and error propagation", psAuditStringPositionSingletons),
        ("condition arity, Bool/String branches and error propagation", psAuditConditionBranches),
        ("sanitizer ASCII, Unicode and fallback equivalence", psAuditSanitizer),
        ("portable collections preserve order, bounds and first errors", psAuditCollections),
        ("unique-name collision order and fuel boundary", psAuditUniqueNames),
        ("Int.repr compilation, arity rejection and error propagation", psAuditIntRepr),
        ("total string workers, UTF-8 positions and large decimal values", psAuditTotalStringWorkers),
        ("total JSON workers, canonical order and fuel boundaries", psAuditTotalJsonWorkers),
        ("module preparation preserves combined admissions and rejects bad modules", psAuditModularPreparation),
        ("lexer shares its input bound while preserving low fuel, nested comments and UTF-8 spans", psAuditLexerInputBound),
        ("meta early exit preserves substitution chains, unresolved terms, fuel, cycles and levels", psAuditMetaFixedPoint),
        ("persistent environment index preserves collisions, duplicates, ordering and axiom replacement", psAuditEnvironmentIndex)] do
      if passed then IO.println ("PSC2_FIXED_POINT_ERASURE_CASE: PASS " ++ label)
      else throw (IO.userError ("PSC2_FIXED_POINT_ERASURE_CASE: FAIL " ++ label))
    IO.println "PSC2_FIXED_POINT_ERASURE_FINISH_APPLICATION: PASS (native behavior and append-order theorem)"
    for name in ["Basic", "Expr", "Inductive", "Structure", "StructureRecursor"] do
      let path := "packages/erasure/src/Ps/Erasure/" ++ name ++ ".lean"
      let _ ← psHostParseSource path (← IO.FS.readFile path)
      IO.println ("PSC2_FIXED_POINT_ERASURE_PARSE: PASS " ++ name)
    for name in ["Type", "Expr", "Module"] do
      let path := "packages/backend-ts/src/Ps/BackendTs/" ++ name ++ ".lean"
      let _ ← psHostParseSource path (← IO.FS.readFile path)
      IO.println ("PSC2_FIXED_POINT_BACKEND_TS_PARSE: PASS " ++ name)
    return 0
  let mut failures := 0
  for file in arguments do
    try
      let source ← IO.FS.readFile file
      let _ ← psHostParseSource file source
      IO.println ("PSC2_FIXED_POINT_PARSE_FILE: PASS " ++ file)
    catch error =>
      failures := failures + 1
      IO.println ("PSC2_FIXED_POINT_PARSE_FILE: FAIL " ++ file ++ " | " ++ error.toString)
  IO.println ("PSC2_FIXED_POINT_PARSE_SUMMARY: files=" ++ toString arguments.length ++
    " failures=" ++ toString failures)
  return if failures == 0 then 0 else 1
