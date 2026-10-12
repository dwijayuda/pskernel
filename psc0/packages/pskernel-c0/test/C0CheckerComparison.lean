import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission

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

/-- Closed lambda source that genuinely uses a binder under the full
    spine. With depth binders, any index < depth refers to a local with type
    Sort 1; the expected function type is c0CompareCheckedPi depth.
    These cases exercise exact local-context lookup, unlike a constant body. -/
def c0CompareLocalRefLambdas : Nat → Nat → PsKernelExpr
  | 0, index => .bvar index
  | n + 1, index =>
      .lam PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0CompareLocalRefLambdas n index)
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
  -- Sixteen metadata-distinct but equally well-typed argument expressions.
  -- Reuse prebuilt source terms rather than charging syntax construction
  -- inside the timed checker loops.
  let applicationVariants :=
    (List.range 16).map (fun metadata =>
      c0CompareApps 48 (PsKernelExpr.const functionName [])
        (PsKernelExpr.mdata metadata sort0))

  -- Wider checked and infer-only spines measure complete checker behavior,
  -- not helper-level list traversal. All inputs are prebuilt and admitted
  -- through exactly the same public API in original-core and C0.
  let wideName := PsKernelName.str PsKernelName.anonymous "C0WideFunction"
  let wideDecl : PsKernelAxiomInfo := {
    base := { name := wideName, levelParams := [], type := c0CompareForalls 192 }
    isUnsafe := false
  }
  let wideEnv ←
    match psKernelAddAxiom 4096 empty wideDecl
        4096 psKernelLeanNatMaxSizeDefault with
    | Except.ok accepted => pure accepted
    | Except.error err =>
        throw (IO.userError ("matched wide benchmark axiom rejected: " ++ err))
  let wideSession := psKernelMkCheckerSession wideEnv []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let wideApp := c0CompareApps 192 (PsKernelExpr.const wideName []) sort0

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

  -- Ordinary inductives exercise checked datatype/constructor admission
  -- and recursor validation in both implementations, not only definitions.
  let enumName := PsKernelName.str PsKernelName.anonymous "C0ComparedEnum"
  let enumDecl : PsKernelSimpleInductiveDecl := {
    levelParams := []
    name := enumName
    type := PsKernelExpr.sort (.succ PsKernelLevel.zero)
    ctors := [
      { name := PsKernelName.str enumName "first",
        type := PsKernelExpr.const enumName [] },
      { name := PsKernelName.str enumName "second",
        type := PsKernelExpr.const enumName [] }
    ]
    isUnsafe := false
    numParams := 0
  }
  let malformedEnum : PsKernelSimpleInductiveDecl := {
    levelParams := []
    name := enumName
    type := enumDecl.type
    ctors := [
      { name := PsKernelName.str enumName "invalid",
        type := PsKernelExpr.sort (.succ PsKernelLevel.zero) }
    ]
    isUnsafe := false
    numParams := 0
  }

  let mutualLeft := PsKernelName.str PsKernelName.anonymous "C0MutualLeft"
  let mutualRight := PsKernelName.str PsKernelName.anonymous "C0MutualRight"
  let mutualDecl : PsKernelSimpleMutualInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [
      { name := mutualLeft
        type := PsKernelExpr.sort (.succ PsKernelLevel.zero)
        ctors := [
          { name := PsKernelName.str mutualLeft "mk",
            type := PsKernelExpr.const mutualLeft [] }
        ]
      },
      { name := mutualRight
        type := PsKernelExpr.sort (.succ PsKernelLevel.zero)
        ctors := [
          { name := PsKernelName.str mutualRight "mk",
            type := PsKernelExpr.const mutualRight [] }
        ]
      }
    ]
    isUnsafe := false
  }
  let invalidMutual : PsKernelSimpleMutualInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [
      { name := mutualLeft,
        type := PsKernelExpr.sort (.succ PsKernelLevel.zero),
        ctors := [] },
      { name := mutualLeft,
        type := PsKernelExpr.sort (.succ PsKernelLevel.zero),
        ctors := [] }
    ]
    isUnsafe := false
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

    let variedCount := 160
    let mut variedInferOk := 0
    let variedInferStart ← IO.monoMsNow
    for i in [:variedCount] do
      match psKernelExprListGet applicationVariants (i % 16) with
      | none => throw (IO.userError "matched varied-app fixture missing")
      | some nextExpr =>
          match psKernelSessionInfer 4096 functionSession nextExpr with
          | Except.ok (type, _) =>
              if psKernelExprEqual type sort0 then
                variedInferOk := variedInferOk + 1
              else throw (IO.userError "matched varied infer-only type mismatch")
          | Except.error err =>
              throw (IO.userError ("matched varied infer-only failed: " ++ err))
    let variedInferEnd ← IO.monoMsNow
    if variedInferOk != variedCount then
      throw (IO.userError "matched varied infer-only count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_infer_application_varied milliseconds={variedInferEnd-variedInferStart} samples={variedCount} variants=16"

    let mut variedCheckedOk := 0
    let variedCheckedStart ← IO.monoMsNow
    for i in [:variedCount] do
      match psKernelExprListGet applicationVariants (i % 16) with
      | none => throw (IO.userError "matched varied-check fixture missing")
      | some nextExpr =>
          match psKernelSessionCheck 4096 functionSession nextExpr with
          | Except.ok (type, _) =>
              if psKernelExprEqual type sort0 then
                variedCheckedOk := variedCheckedOk + 1
              else throw (IO.userError "matched varied checked type mismatch")
          | Except.error err =>
              throw (IO.userError ("matched varied checked failed: " ++ err))
    let variedCheckedEnd ← IO.monoMsNow
    if variedCheckedOk != variedCount then
      throw (IO.userError "matched varied checked count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=cold_check_application_varied milliseconds={variedCheckedEnd-variedCheckedStart} samples={variedCount} variants=16"

    let mut wideInferOk := 0
    let wideInferStart ← IO.monoMsNow
    for _ in [:48] do
      match psKernelSessionInfer 4096 wideSession wideApp with
      | Except.ok (result, _) =>
          if psKernelExprEqual result sort0 then
            wideInferOk := wideInferOk + 1
          else throw (IO.userError "matched wide infer-only type changed")
      | Except.error err =>
          throw (IO.userError ("matched wide infer-only failed: " ++ err))
    let wideInferEnd ← IO.monoMsNow
    if wideInferOk != 48 then throw (IO.userError "wide infer-only count changed")
    IO.println s!"C0_COMPARE round={round} operation=cold_infer_application_wide milliseconds={wideInferEnd-wideInferStart} samples=48 arguments=192"

    let mut wideCheckedOk := 0
    let wideCheckedStart ← IO.monoMsNow
    for _ in [:12] do
      match psKernelSessionCheck 4096 wideSession wideApp with
      | Except.ok (result, _) =>
          if psKernelExprEqual result sort0 then
            wideCheckedOk := wideCheckedOk + 1
          else throw (IO.userError "matched wide checked type changed")
      | Except.error err =>
          throw (IO.userError ("matched wide checked application failed: " ++ err))
    let wideCheckedEnd ← IO.monoMsNow
    if wideCheckedOk != 12 then throw (IO.userError "wide checked count changed")
    IO.println s!"C0_COMPARE round={round} operation=cold_check_application_wide milliseconds={wideCheckedEnd-wideCheckedStart} samples=12 arguments=192"

    -- Real checked-library admission: every declaration is verified against
    -- the same previously admitted wide function, and the environment is
    -- extended in the timed span. This measures acceptance, not just infer.
    let wideChainBase :=
      PsKernelName.str PsKernelName.anonymous "C0WideCheckedLibrary"
    let wideChainLength := 32
    let mut wideChainEnv := wideEnv
    let wideChainStart ← IO.monoMsNow
    for i in [:wideChainLength] do
      let declaration : PsKernelDefinitionInfo := {
        base := {
          name := PsKernelName.num wideChainBase i
          levelParams := []
          type := sort0
        }
        value := wideApp
        hints := PsKernelReducibilityHints.abbrevHint
        safety := PsKernelDefinitionSafety.safe
      }
      match psKernelAddDefinition 4096 wideChainEnv declaration
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched wide library admission rejected: " ++ err))
      | Except.ok next => wideChainEnv := next
    let wideChainEnd ← IO.monoMsNow
    for i in [:wideChainLength] do
      if !psKernelEnvironmentContains wideChainEnv
          (PsKernelName.num wideChainBase i) then
        throw (IO.userError "matched wide library dropped declaration")
    IO.println s!"C0_COMPARE round={round} operation=admit_wide_checked_library milliseconds={wideChainEnd-wideChainStart} declarations={wideChainLength} arguments=192"

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

    -- Actual growing checked declaration environment. Every eighth
    -- definition contains a nested 16-lambda body; all intervening
    -- definitions refer to the immediately preceding checked declaration.
    -- Environment index construction, dependency inference, checked type
    -- comparison and persistent admission are included in the timed span.
    let chainLength := 160
    let chainBase := PsKernelName.str PsKernelName.anonymous "C0LibraryChain"
    let chainType := c0CompareCheckedPi 16
    let chainBody := c0CompareCheckedLambda 16
    let mut chainEnv := psKernelEnvironmentEmpty
    let mut priorName := chainBase
    let chainStart ← IO.monoMsNow
    for i in [:chainLength] do
      let currentName := PsKernelName.num chainBase i
      let body :=
        if i % 8 == 0 then chainBody
        else PsKernelExpr.const priorName []
      let decl : PsKernelDefinitionInfo := {
        base := { name := currentName, levelParams := [], type := chainType }
        value := body
        hints := PsKernelReducibilityHints.abbrevHint
        safety := PsKernelDefinitionSafety.safe
      }
      match psKernelAddDefinition 4096 chainEnv decl
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched library chain rejected declaration: " ++ err))
      | Except.ok next =>
          chainEnv := next
          priorName := currentName
    let chainEnd ← IO.monoMsNow
    for i in [:chainLength] do
      if !psKernelEnvironmentContains chainEnv (PsKernelName.num chainBase i) then
        throw (IO.userError "matched library chain lost an admitted declaration")
    IO.println s!"C0_COMPARE round={round} operation=admit_library_chain milliseconds={chainEnd-chainStart} declarations={chainLength} nested_every=8 binder_depth=16"

    -- A separate deep-binding regime makes the adaptive-index tradeoff
    -- observable beyond its promotion threshold. This remains a complete
    -- checked declaration operation, not an isolated lookup benchmark.
    let deepCount := 64
    let deepBase := PsKernelName.str PsKernelName.anonymous "C0DeepLibraryChain"
    let deepType := c0CompareCheckedPi 48
    let deepBody := c0CompareCheckedLambda 48
    let mut deepEnv := psKernelEnvironmentEmpty
    let mut deepPrevious := deepBase
    let deepStart ← IO.monoMsNow
    for i in [:deepCount] do
      let name := PsKernelName.num deepBase i
      let body :=
        if i % 4 == 0 then deepBody
        else PsKernelExpr.const deepPrevious []
      let decl : PsKernelDefinitionInfo := {
        base := { name := name, levelParams := [], type := deepType }
        value := body
        hints := PsKernelReducibilityHints.abbrevHint
        safety := PsKernelDefinitionSafety.safe
      }
      match psKernelAddDefinition 4096 deepEnv decl
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched deep declaration rejected: " ++ err))
      | Except.ok next =>
          deepEnv := next
          deepPrevious := name
    let deepEnd ← IO.monoMsNow
    for i in [:deepCount] do
      if !psKernelEnvironmentContains deepEnv (PsKernelName.num deepBase i) then
        throw (IO.userError "matched deep library missing declaration")
    IO.println s!"C0_COMPARE round={round} operation=admit_deep_library_chain milliseconds={deepEnd-deepStart} declarations={deepCount} nested_every=4 binder_depth=48"

    -- A larger sample avoids sub-millisecond per-round observations.
    let inductiveRuns := 2000
    let mut inductiveAccepted := 0
    let inductiveStart ← IO.monoMsNow
    for _ in [:inductiveRuns] do
      match psKernelAddSimpleInductive 4096 empty enumDecl
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched ordinary inductive rejected: " ++ err))
      | Except.ok result =>
          if psKernelEnvironmentContains result enumName &&
              psKernelEnvironmentContains result
                (PsKernelName.str enumName "rec") then
            inductiveAccepted := inductiveAccepted + 1
          else throw (IO.userError "matched inductive incomplete admission")
    let inductiveEnd ← IO.monoMsNow
    if inductiveAccepted != inductiveRuns then
      throw (IO.userError "matched inductive count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=admit_ordinary_inductive milliseconds={inductiveEnd-inductiveStart} samples={inductiveRuns} constructors=2"

    let mut malformedRejected := 0
    let malformedStart ← IO.monoMsNow
    for _ in [:inductiveRuns] do
      match psKernelAddSimpleInductive 4096 empty malformedEnum
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error _ => malformedRejected := malformedRejected + 1
      | Except.ok _ =>
          throw (IO.userError "matched invalid inductive accepted")
    let malformedEnd ← IO.monoMsNow
    if malformedRejected != inductiveRuns then
      throw (IO.userError "matched invalid inductive count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=reject_ordinary_inductive milliseconds={malformedEnd-malformedStart} samples={inductiveRuns}"

    -- Validate checked mutual-inductive header/constructor/recursor machinery
    -- on the same positive and negative inputs in both reference kernels.
    let mutualRuns := 400
    let mut mutualAccepted := 0
    let mutualStart ← IO.monoMsNow
    for _ in [:mutualRuns] do
      match psKernelAddSimpleMutualInductive 4096 empty mutualDecl
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error err =>
          throw (IO.userError ("matched mutual inductive rejected: " ++ err))
      | Except.ok result =>
          if psKernelEnvironmentContains result mutualLeft &&
              psKernelEnvironmentContains result mutualRight then
            mutualAccepted := mutualAccepted + 1
          else throw (IO.userError "matched mutual inductive missing datatype")
    let mutualEnd ← IO.monoMsNow
    if mutualAccepted != mutualRuns then
      throw (IO.userError "matched mutual admission count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=admit_mutual_inductive milliseconds={mutualEnd-mutualStart} samples={mutualRuns} types=2"

    let mut mutualRejected := 0
    let mutualRejectStart ← IO.monoMsNow
    for _ in [:mutualRuns] do
      match psKernelAddSimpleMutualInductive 4096 empty invalidMutual
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.error _ => mutualRejected := mutualRejected + 1
      | Except.ok _ => throw (IO.userError "matched invalid mutual accepted")
    let mutualRejectEnd ← IO.monoMsNow
    if mutualRejected != mutualRuns then
      throw (IO.userError "matched mutual rejection count mismatch")
    IO.println s!"C0_COMPARE round={round} operation=reject_mutual_inductive milliseconds={mutualRejectEnd-mutualRejectStart} samples={mutualRuns}"

    -- Complete checked admission where the body uses an inner, middle or
    -- outer binder. Compare identical semantic decisions and runner-local
    -- costs against the untouched original package.
    for referenceDepth in [96, 192, 320, 512] do
      let referenceType := c0CompareCheckedPi referenceDepth
      let referenceBase := PsKernelName.str PsKernelName.anonymous "C0LocalReference"
      for offset in [0, referenceDepth / 2, referenceDepth - 1] do
        let referenceBody := c0CompareLocalRefLambdas referenceDepth offset
        let referenceRuns := if referenceDepth == 96 then 20 else if referenceDepth == 192 then 6 else if referenceDepth == 320 then 3 else 2
        let mut referenceAccepted := 0
        let referenceStart ← IO.monoMsNow
        for i in [:referenceRuns] do
          let declarationName := PsKernelName.num
            (PsKernelName.num referenceBase offset) i
          let declaration : PsKernelDefinitionInfo := {
            base := {
              name := declarationName
              levelParams := []
              type := referenceType
            }
            value := referenceBody
            hints := PsKernelReducibilityHints.abbrevHint
            safety := PsKernelDefinitionSafety.safe
          }
          match psKernelAddDefinition 4096 psKernelEnvironmentEmpty declaration
              4096 psKernelLeanNatMaxSizeDefault with
          | Except.ok accepted =>
              if psKernelEnvironmentContains accepted declarationName then
                referenceAccepted := referenceAccepted + 1
              else
                throw (IO.userError "local reference declaration missing after admission")
          | Except.error err =>
              throw (IO.userError ("valid local reference declaration rejected: " ++ err))
        let referenceEnd ← IO.monoMsNow
        if referenceAccepted != referenceRuns then
          throw (IO.userError "local reference benchmark admission mismatch")
        IO.println s!"C0_COMPARE round={round} operation=admit_local_reference milliseconds={referenceEnd-referenceStart} declarations={referenceRuns} binder_depth={referenceDepth} bvar_index={offset}"


    -- Deep *reused* local references: a curried axiom of type
    -- (Sort 1) -> ... -> Sort 1 is applied 24 times to the same bound
    -- local under deep checked lambdas. Unlike a single BVar reference,
    -- each checked argument independently invokes local-context lookup.
    -- This measures whether memoized local indexing repays construction.
    let reuseArity := 24
    let reuseAxiomName := PsKernelName.str PsKernelName.anonymous "C0ReuseLocal"
    let reuseAxiom : PsKernelAxiomInfo := {
      base := {
        name := reuseAxiomName
        levelParams := []
        type := c0CompareCheckedPi reuseArity
      }
      isUnsafe := false
    }
    let reuseEnv ←
      match psKernelAddAxiom 4096 psKernelEnvironmentEmpty reuseAxiom
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.ok accepted => pure accepted
      | Except.error err =>
          throw (IO.userError ("matched reusable local axiom rejected: " ++ err))
    for reuseDepth in [192, 320, 512] do
      let expectedType := c0CompareCheckedPi reuseDepth
      for offset in [0, reuseDepth / 2, reuseDepth - 1] do
        let applied := c0CompareApps reuseArity
          (PsKernelExpr.const reuseAxiomName [])
          (PsKernelExpr.bvar offset)
        let source := (List.range reuseDepth).foldl
          (fun body _ => PsKernelExpr.lam PsKernelName.anonymous
            (PsKernelExpr.sort (.succ PsKernelLevel.zero)) body
            PsKernelBinderInfo.default)
          applied
        let declarationName := PsKernelName.num
          (PsKernelName.str PsKernelName.anonymous "C0RepeatedReference")
          (reuseDepth + offset)
        let declaration : PsKernelDefinitionInfo := {
          base := {
            name := declarationName
            levelParams := []
            type := expectedType
          }
          value := source
          hints := PsKernelReducibilityHints.abbrevHint
          safety := PsKernelDefinitionSafety.safe
        }
        let repeats := if reuseDepth == 192 then 3 else 2
        let mut verified := 0
        let repeatedStart ← IO.monoMsNow
        for _ in [:repeats] do
          match psKernelAddDefinition 4096 reuseEnv declaration
              4096 psKernelLeanNatMaxSizeDefault with
          | Except.ok accepted =>
              if psKernelEnvironmentContains accepted declarationName then
                verified := verified + 1
              else
                throw (IO.userError "reused-local definition missing after checked admission")
          | Except.error err =>
              throw (IO.userError ("reused-local checked admission failed: " ++ err))
        let repeatedEnd ← IO.monoMsNow
        if verified != repeats then
          throw (IO.userError "reused-local checked admission count mismatch")
        IO.println s!"C0_COMPARE round={round} operation=admit_local_reference_reused milliseconds={repeatedEnd-repeatedStart} declarations={repeats} binder_depth={reuseDepth} bvar_index={offset} applications={reuseArity}"

  let status ← IO.FS.readFile "/proc/self/status"
  for line in status.splitOn "\n" do
    if line.startsWith "VmHWM:" then IO.println s!"C0_COMPARE process_peak {line}"
    else pure ()
