import Ps.KernelCore.Admission.Declaration.Admission

/-
Matched complete-checker benchmark that intentionally imports *only* APIs
shared by original PSKernel-Core and C0. CI runs this exact same source in two
independently built Lean 4.34.0 source trees on the same Linux runner.

Measurements are wall-clock samples, NOT formal correctness proofs or memory
allocation attribution. It runs no self-hosting or bootstrap tests.
-/

def c0CompareApps : Nat → PsKernelExpr → PsKernelExpr → PsKernelExpr
  | 0, fn, _ => fn
  | n + 1, fn, arg => c0CompareApps n (.app fn arg) arg

def c0CompareLambdas : Nat → PsKernelExpr
  | 0 => .bvar 0
  | n + 1 =>
      .lam PsKernelName.anonymous
        (.sort PsKernelLevel.zero)
        (c0CompareLambdas n)
        PsKernelBinderInfo.default

/-- An actual fully typed function, with 48 Sort 1 parameters and a
    Sort 0 result, shared by original-core and C0 benchmarks. -/
def c0CompareForalls : Nat → PsKernelExpr
  | 0 => .sort PsKernelLevel.zero
  | n + 1 =>
      .forallE PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0CompareForalls n)
        PsKernelBinderInfo.default

/-- Nested source definitions: each binder accepts a Sort 1 argument,
    while the innermost Sort 0 has type Sort 1. Both reference and C0
    verify the same declaration through their complete admission APIs. -/
def c0CompareCheckedPi : Nat → PsKernelExpr
  | 0 => .sort (.succ PsKernelLevel.zero)
  | n + 1 =>
      .forallE PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0CompareCheckedPi n)
        PsKernelBinderInfo.default

def c0CompareCheckedLambda : Nat → PsKernelExpr
  | 0 => .sort PsKernelLevel.zero
  | n + 1 =>
      .lam PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0CompareCheckedLambda n)
        PsKernelBinderInfo.default

def main : IO Unit := do
  let empty := psKernelEnvironmentEmpty
  let context := psKernelCheckerContextEmpty empty
  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let sort1 := PsKernelExpr.sort (.succ PsKernelLevel.zero)
  let name := PsKernelName.str PsKernelName.anonymous "C0MatchedBenchmark"
  let stuck := c0CompareApps 256 (.mvar name) (.bvar 3)
  let identity := PsKernelExpr.lam PsKernelName.anonymous sort0
    (.bvar 0) PsKernelBinderInfo.default
  let beta := PsKernelExpr.app identity sort0
  let lambda := c0CompareLambdas 32
  let session := psKernelMkCheckerSession empty []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let valid : PsKernelDefinitionInfo := {
    base := { name := name, levelParams := [], type := sort1 }
    value := sort0
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }
  let invalid : PsKernelDefinitionInfo := {
    base := valid.base
    value := sort1
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }

  -- Admit the benchmark function through the accepting admission API.
  -- Applications use Sort 0, whose inferred type is Sort 1 as required.
  let functionName := PsKernelName.str PsKernelName.anonymous "C0CompareFunction"
  let functionDecl : PsKernelAxiomInfo := {
    base := {
      name := functionName
      levelParams := []
      type := c0CompareForalls 48
    }
    isUnsafe := false
  }
  let functionEnvironment ←
    match psKernelAddAxiom 4096 empty functionDecl
        4096 psKernelLeanNatMaxSizeDefault with
    | Except.ok accepted => pure accepted
    | Except.error err =>
        throw (IO.userError ("matched benchmark axiom rejected: " ++ err))
  let functionSession := psKernelMkCheckerSession functionEnvironment []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let application := c0CompareApps 48
    (PsKernelExpr.const functionName []) sort0

  let safeDefinition : PsKernelDefinitionInfo := {
    base := {
      name := PsKernelName.str PsKernelName.anonymous "C0ComparedSafeDef"
      levelParams := []
      type := c0CompareCheckedPi 24
    }
    value := c0CompareCheckedLambda 24
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }
  let invalidDefinition : PsKernelDefinitionInfo := {
    base := safeDefinition.base
    value := c0CompareCheckedLambda 23
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }

  for round in [:3] do
    -- Full WHNF, not the isolated application-head probe.
    let mut whnfOk := 0
    let whnfStart ← IO.monoMsNow
    for _ in [:1600] do
      match psKernelCheckerWhnf 4096 context psKernelCheckerStateEmpty stuck with
      | Except.ok (normalized, _) =>
          if psKernelExprEqual normalized stuck then
            whnfOk := whnfOk + 1
          else
            throw (IO.userError "matched WHNF changed a stuck term")
      | Except.error err => throw (IO.userError ("matched WHNF failed: " ++ err))
    let whnfEnd ← IO.monoMsNow
    if whnfOk != 1600 then throw (IO.userError "matched WHNF count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_whnf milliseconds={whnfEnd-whnfStart} samples=1600"

    let mut eqYes := 0
    let mut eqNo := 0
    let eqStart ← IO.monoMsNow
    for _ in [:2000] do
      match psKernelSessionIsDefEq 4096 session beta sort0 with
      | Except.ok (yes, _) =>
          if yes then eqYes := eqYes + 1
          else throw (IO.userError "matched positive DefEq rejected")
      | Except.error err => throw (IO.userError ("matched positive DefEq failed: " ++ err))
      match psKernelSessionIsDefEq 4096 session sort0 sort1 with
      | Except.ok (yes, _) =>
          if !yes then eqNo := eqNo + 1
          else throw (IO.userError "matched distinct Sorts accepted")
      | Except.error err => throw (IO.userError ("matched negative DefEq failed: " ++ err))
    let eqEnd ← IO.monoMsNow
    if eqYes != 2000 || eqNo != 2000 then
      throw (IO.userError "matched DefEq count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_defeq milliseconds={eqEnd-eqStart} samples=4000"

    let mut inferOk := 0
    let inferStart ← IO.monoMsNow
    for _ in [:800] do
      match psKernelSessionInfer 4096 session lambda with
      | Except.ok (type, _) =>
          match type with
          | .forallE _ _ _ _ => inferOk := inferOk + 1
          | _ => throw (IO.userError "matched inference unexpected shape")
      | Except.error err => throw (IO.userError ("matched inference failed: " ++ err))
    let inferEnd ← IO.monoMsNow
    if inferOk != 800 then throw (IO.userError "matched inference count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_infer milliseconds={inferEnd-inferStart} samples=800"

    let mut warmSession := session
    let mut warmOk := 0
    let warmStart ← IO.monoMsNow
    for _ in [:800] do
      match psKernelSessionInfer 4096 warmSession lambda with
      | Except.ok (type, next) =>
          match type with
          | .forallE _ _ _ _ =>
              warmOk := warmOk + 1
              warmSession := next
          | _ => throw (IO.userError "matched warm inference unexpected shape")
      | Except.error err => throw (IO.userError ("matched warm inference failed: " ++ err))
    let warmEnd ← IO.monoMsNow
    if warmOk != 800 then throw (IO.userError "matched warm inference count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=warm_infer milliseconds={warmEnd-warmStart} samples=800"

    let mut appInferOk := 0
    let appInferStart ← IO.monoMsNow
    for _ in [:200] do
      match psKernelSessionInfer 4096 functionSession application with
      | Except.ok (type, _) =>
          if psKernelExprEqual type sort0 then appInferOk := appInferOk + 1
          else throw (IO.userError "matched application inference changed type")
      | Except.error err =>
          throw (IO.userError ("matched application inference failed: " ++ err))
    let appInferEnd ← IO.monoMsNow
    if appInferOk != 200 then
      throw (IO.userError "matched application inference count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_infer_application milliseconds={appInferEnd-appInferStart} samples=200"

    let mut appCheckedOk := 0
    let appCheckedStart ← IO.monoMsNow
    for _ in [:80] do
      match psKernelSessionCheck 4096 functionSession application with
      | Except.ok (type, _) =>
          if psKernelExprEqual type sort0 then appCheckedOk := appCheckedOk + 1
          else throw (IO.userError "matched checked application changed type")
      | Except.error err =>
          throw (IO.userError ("matched checked application failed: " ++ err))
    let appCheckedEnd ← IO.monoMsNow
    if appCheckedOk != 80 then
      throw (IO.userError "matched checked application count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_check_application milliseconds={appCheckedEnd-appCheckedStart} samples=80"

    let mut admitted := 0
    let mut rejected := 0
    let admissionStart ← IO.monoMsNow
    for _ in [:600] do
      match psKernelAddDefinition 4096 empty valid 4096
          psKernelLeanNatMaxSizeDefault with
      | Except.ok env =>
          if psKernelEnvironmentContains env name then
            admitted := admitted + 1
          else throw (IO.userError "matched admitted declaration missing")
      | Except.error err => throw (IO.userError ("matched admission failed: " ++ err))
      match psKernelAddDefinition 4096 empty invalid 4096
          psKernelLeanNatMaxSizeDefault with
      | Except.error _ => rejected := rejected + 1
      | Except.ok _ => throw (IO.userError "matched invalid declaration accepted")
    let admissionEnd ← IO.monoMsNow
    if admitted != 600 || rejected != 600 then
      throw (IO.userError "matched admission count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=admission milliseconds={admissionEnd-admissionStart} samples=1200"

    let complexCount := 32
    let mut complexYes := 0
    let complexStart ← IO.monoMsNow
    for _ in [:complexCount] do
      match psKernelAddDefinition 4096 empty safeDefinition
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched nested safe definition rejected: " ++ err))
      | Except.ok result =>
          if psKernelEnvironmentContains result safeDefinition.base.name then
            complexYes := complexYes + 1
          else
            throw (IO.userError "matched nested safe definition not admitted")
    let complexEnd ← IO.monoMsNow
    if complexYes != complexCount then
      throw (IO.userError "matched nested admission count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=admit_nested_safe milliseconds={complexEnd-complexStart} samples={complexCount} binder_depth=24"

    let mut complexNo := 0
    let complexNoStart ← IO.monoMsNow
    for _ in [:complexCount] do
      match psKernelAddDefinition 4096 empty invalidDefinition
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error _ => complexNo := complexNo + 1
      | Except.ok _ =>
          throw (IO.userError "matched invalid nested definition accepted")
    let complexNoEnd ← IO.monoMsNow
    if complexNo != complexCount then
      throw (IO.userError "matched nested rejection count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=reject_nested_invalid milliseconds={complexNoEnd-complexNoStart} samples={complexCount} binder_depth=24"

  let status ← IO.FS.readFile "/proc/self/status"
  for line in status.splitOn "\n" do
    if line.startsWith "VmHWM:" then IO.println s!"C0_COMPARE process_peak {line}"
    else pure ()
