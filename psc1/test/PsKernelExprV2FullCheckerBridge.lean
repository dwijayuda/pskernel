import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Research.ExprV2PagedHeadMachine

/-
READ-ONLY RESEARCH CHECKER BRIDGE

This test compares the *fully trusted existing* PSC1 PSKernel-Core
check / WHNF / positive-DefEq operations against the V2 paged *restricted*
beta/zeta/metadata head machine on a declared subset of fully well-typed
closed expressions. This is NOT a checker backend and cannot admit proofs.

The full checker runs independently and supplies the expected result.
The V2 test intentionally measures:
  - initial legacy -> V2 import and full replay,
  - validated-once restricted head execution,
  - temporary test-only V2 -> legacy materialization,
  - the end-to-end cost including conversions.
Never infer a general speedup from raw V2 head-step timings.

A malformed application is rejected by the FULL checker; V2 must never
be used to turn a neutral head-step into proof acceptance.
The published production fuel policy is left unchanged. A V2 head
sequence has its own budget and is never compared as fuel-equivalent.
-/

private def bridgeSort0 : PsKernelExpr :=
  PsKernelExpr.sort PsKernelLevel.zero

private def bridgeSort1 : PsKernelExpr :=
  PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)

private def bridgeSession : PsKernelCheckerSession :=
  psKernelMkCheckerSession
    psKernelEnvironmentEmpty
    List.nil
    PsKernelDefinitionSafety.safe
    4096
    psKernelLeanNatMaxSizeDefault

private def bridgeZeta : Nat → PsKernelExpr
  | Nat.zero => bridgeSort0
  | Nat.succ remaining =>
      PsKernelExpr.letE
        PsKernelName.anonymous
        bridgeSort1
        (bridgeZeta remaining)
        (PsKernelExpr.bvar 0)
        false

private def bridgeRequire (label : String) (pass : Bool) : IO Unit := do
  unless pass do
    throw (IO.userError ("PSC1_V2_BRIDGE_FAIL " ++ label))

private def bridgeExpect {α : Type}
    (result : Except String α) : IO α := do
  match result with
  | Except.ok value => return value
  | Except.error error =>
      throw (IO.userError ("PSC1_V2_BRIDGE_ERROR " ++ error))

private def bridgeDecodePaged
    (source : PsKernelExprV2PagedArena)
    (root : Nat) : IO PsKernelExpr := do
  let checked ← bridgeExpect (psKernelExprV2PagedValidate source)
  let mut flat := psKernelExprV2Empty
  for id in [:checked.size] do
    let entry ← bridgeExpect (psKernelExprV2PagedRequire checked id)
    flat := (psKernelExprV2Push flat entry).fst
  bridgeExpect (psKernelExprV2Decode flat root)

private def bridgeCheckTrusted
    (depth : Nat) (term : PsKernelExpr) : IO Unit := do
  let inferred ← bridgeExpect
    (psKernelSessionCheck 4096 bridgeSession term)
  bridgeRequire s!"fully-checked-type-{depth}"
    (psKernelExprEq (Prod.fst inferred) bridgeSort1)
  let normalized ← bridgeExpect
    (psKernelSessionWhnf 4096 bridgeSession term)
  bridgeRequire s!"fully-checked-whnf-{depth}"
    (psKernelExprEq (Prod.fst normalized) bridgeSort0)
  let equal ← bridgeExpect
    (psKernelSessionIsDefEq 4096 bridgeSession term bridgeSort0)
  bridgeRequire s!"fully-checked-defeq-{depth}" (Prod.fst equal)

private def bridgeCheckV2
    (depth : Nat) (term : PsKernelExpr) : IO Unit := do
  let (imported,root) ← bridgeExpect
    (psKernelExprV2PagedImportChecked term)
  let (reduced,resultId) ← bridgeExpect
    (psKernelExprV2PagedHeadMachineChecked
      (Nat.succ depth) imported root)
  let result ← bridgeDecodePaged reduced resultId
  bridgeRequire s!"v2-exact-output-{depth}"
    (psKernelExprEqual result bridgeSort0 &&
      psKernelExprEq result bridgeSort0)
  let outcome ← bridgeExpect (psKernelExprV2PagedRequire reduced resultId)
  bridgeRequire s!"v2-result-metadata-{depth}"
    (outcome.looseRange == 0 && !outcome.hasFVar)
  bridgeRequire s!"v2-fuel-rejection-{depth}"
    (match psKernelExprV2PagedHeadMachineChecked depth imported root with
      | Except.error _ => true
      | Except.ok _ => false)

private def bridgePositiveAndNegative : IO Unit := do
  for depth in [1,8,32,96] do
    let term := bridgeZeta depth
    bridgeCheckTrusted depth term
    bridgeCheckV2 depth term
    IO.println s!"PSC1_V2_BRIDGE_VERDICT: PASS depth={depth}"
  let invalid := PsKernelExpr.app bridgeSort0 bridgeSort0
  bridgeRequire "full-checker-rejects-invalid-application"
    (match psKernelSessionCheck 4096 bridgeSession invalid with
      | Except.error _ => true
      | Except.ok _ => false)
  -- The research head machine is NOT an admission checker. A neutral head
  -- remains neutral rather than implying that its typing was checked.
  let (arena,root) ← bridgeExpect (psKernelExprV2PagedImportChecked invalid)
  let (head,next) ← bridgeExpect
    (psKernelExprV2PagedHeadMachineChecked 1 arena root)
  bridgeRequire "neutral-head-is-not-a-typing-judgment"
    (next == root && head.size == arena.size)
  IO.println "PSC1_V2_BRIDGE_REJECTION: PASS"

private def bridgeBenchmark
    (label : String) (depth calls : Nat)
    (operation : Nat → IO Nat) : IO Unit := do
  let mut checksum : Nat := 0
  let started ← IO.monoMsNow
  for i in [:calls] do
    checksum := checksum + (← operation i)
  let finished ← IO.monoMsNow
  bridgeRequire ("bench-calls-" ++ label) (checksum == calls)
  IO.println s!"PSC1_V2_BRIDGE_TIMING variant={label} depth={depth} calls={calls} ms={finished-started} checksum={checksum}"

private def bridgeRunBenchmark (depth calls : Nat) : IO Unit := do
  let term := bridgeZeta depth
  let (imported,root) ← bridgeExpect (psKernelExprV2PagedImportChecked term)

  -- Check all verdicts separately before timing.
  bridgeCheckTrusted depth term
  bridgeCheckV2 depth term

  let fullWhnf : Nat → IO Nat := fun _ => do
    let result ← bridgeExpect
      (psKernelSessionWhnf 4096 bridgeSession term)
    if psKernelExprEq (Prod.fst result) bridgeSort0 then return 1
    throw (IO.userError "PSC1_V2_BRIDGE_TRUSTED_WHNF_MISMATCH")

  let v2HeadOnly : Nat → IO Nat := fun _ => do
    let (a,r) ← bridgeExpect
      (psKernelExprV2PagedHeadMachineChecked (Nat.succ depth) imported root)
    let e ← bridgeExpect (psKernelExprV2PagedRequire a r)
    match e.node with
    | PsKernelExprV2Node.sort level =>
        if psKernelLevelEq level PsKernelLevel.zero then return 1
        throw (IO.userError "PSC1_V2_BRIDGE_HEAD_MISMATCH")
    | _ => throw (IO.userError "PSC1_V2_BRIDGE_HEAD_NOT_SORT")

  let v2WithImport : Nat → IO Nat := fun _ => do
    let (a,r) ← bridgeExpect (psKernelExprV2PagedImportChecked term)
    let (out,id) ← bridgeExpect
      (psKernelExprV2PagedHeadMachineChecked (Nat.succ depth) a r)
    let e ← bridgeExpect (psKernelExprV2PagedRequire out id)
    match e.node with
    | PsKernelExprV2Node.sort level =>
        if psKernelLevelEq level PsKernelLevel.zero then return 1
        throw (IO.userError "PSC1_V2_BRIDGE_IMPORTED_HEAD_MISMATCH")
    | _ => throw (IO.userError "PSC1_V2_BRIDGE_IMPORTED_NOT_SORT")

  let fullCheck : Nat → IO Nat := fun _ => do
    let result ← bridgeExpect
      (psKernelSessionCheck 4096 bridgeSession term)
    if psKernelExprEq (Prod.fst result) bridgeSort1 then return 1
    throw (IO.userError "PSC1_V2_BRIDGE_CHECK_TYPE_MISMATCH")

  let fullDefEq : Nat → IO Nat := fun _ => do
    let result ← bridgeExpect
      (psKernelSessionIsDefEq 4096 bridgeSession term bridgeSort0)
    if Prod.fst result then return 1
    throw (IO.userError "PSC1_V2_BRIDGE_DEFEQ_MISMATCH")

  -- A-B-B-A for the two comparable observed WHNF outputs. The V2 machine
  -- is deliberately *subset-only* and has a different research step budget.
  bridgeBenchmark "trusted_whnf" depth calls fullWhnf
  bridgeBenchmark "v2_with_import" depth calls v2WithImport
  bridgeBenchmark "v2_with_import" depth calls v2WithImport
  bridgeBenchmark "trusted_whnf" depth calls fullWhnf

  -- Separately report the performance that excludes V2 conversion cost.
  bridgeBenchmark "v2_head_preimported" depth calls v2HeadOnly
  bridgeBenchmark "trusted_check_type" depth calls fullCheck
  bridgeBenchmark "trusted_defeq_positive" depth calls fullDefEq

def main : IO Unit := do
  bridgePositiveAndNegative
  bridgeRunBenchmark 32 12
  bridgeRunBenchmark 96 8
  bridgeRunBenchmark 192 4
  IO.println "PSC1_V2_FULL_CHECKER_BRIDGE: PASS"
