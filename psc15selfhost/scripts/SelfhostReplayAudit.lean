import Ps.Bootstrap.SelfHost
import Ps.Host.ProjectCompiler

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

def main (arguments : List String) : IO UInt32 := do
  match arguments with
  | ["--watch", file] => return ← psAuditWatchModule file
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
        ("unique-name collision order and fuel boundary", psAuditUniqueNames)] do
      if passed then IO.println ("PSC2_FIXED_POINT_ERASURE_CASE: PASS " ++ label)
      else throw (IO.userError ("PSC2_FIXED_POINT_ERASURE_CASE: FAIL " ++ label))
    IO.println "PSC2_FIXED_POINT_ERASURE_FINISH_APPLICATION: PASS (native behavior and append-order theorem)"
    for name in ["Basic", "Expr", "Inductive", "Structure", "StructureRecursor"] do
      let path := "packages/erasure/src/Ps/Erasure/" ++ name ++ ".lean"
      let _ ← psHostParseSource path (← IO.FS.readFile path)
      IO.println ("PSC2_FIXED_POINT_ERASURE_PARSE: PASS " ++ name)
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
