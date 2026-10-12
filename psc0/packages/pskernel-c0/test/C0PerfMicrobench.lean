import Ps.KernelCore.Checker.Reduction.IndexedWhnf
import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Core.Substitution.Instantiate
import Ps.KernelCore.Core.LocalContext

/-
Native Lean C0 performance microbenchmarks. No self-hosting or proof work.
Inputs vary across iterations to limit loop-invariant computation elimination.
All times are single-run runner observations, not kernel throughput claims.
-/

def c0BenchApps (count : Nat)
    (current : PsKernelExpr)
    (arg : PsKernelExpr) : PsKernelExpr :=
  match count with
  | 0 => current
  | Nat.succ rest =>
      c0BenchApps rest (PsKernelExpr.app current arg) arg

def c0BenchSuccLevel (count : Nat) (current : PsKernelLevel) : PsKernelLevel :=
  match count with
  | 0 => current
  | Nat.succ rest =>
      c0BenchSuccLevel rest (PsKernelLevel.succ current)

def main : IO Unit := do
  let arg := PsKernelExpr.bvar 2
  let first := c0BenchApps 512 (PsKernelExpr.bvar 0) arg
  let second := c0BenchApps 512 (PsKernelExpr.bvar 1) arg
  let iterations := 30000

  let mut legacyHits : Nat := 0
  let startedOld ← IO.monoMsNow
  for k in [:iterations] do
    let other := if k % 2 == 0 then first else second
    if psKernelExprEqLegacy first other then
      legacyHits := legacyHits + 1
  let finishedOld ← IO.monoMsNow
  let mut fastHits : Nat := 0
  let startedNew ← IO.monoMsNow
  for k in [:iterations] do
    let other := if k % 2 == 0 then first else second
    if psKernelExprEq first other then
      fastHits := fastHits + 1
  let finishedNew ← IO.monoMsNow
  if !(Nat.beq legacyHits fastHits) then
    throw (IO.userError "equality comparison results diverged")
  IO.println s!"C0_BENCH paired_equality legacy_ms={finishedOld - startedOld} paired_ms={finishedNew - startedNew} hits={fastHits} iterations={iterations}"

  let mut oldChanged : Nat := 0
  let oldStart ← IO.monoMsNow
  for k in [:iterations] do
    let result :=
      psKernelExprLiftLooseBVarsChangedWithFuel
        (Nat.succ (psKernelExprNodeCount first)) first (k % 3) (k % 4)
    if Prod.snd result then oldChanged := oldChanged + 1
  let oldEnd ← IO.monoMsNow
  let mut newChanged : Nat := 0
  let newStart ← IO.monoMsNow
  for k in [:iterations] do
    let result := psKernelExprLiftLooseBVarsChanged first (k % 3) (k % 4)
    if Prod.snd result then newChanged := newChanged + 1
  let newEnd ← IO.monoMsNow
  if !(Nat.beq oldChanged newChanged) then
    throw (IO.userError "lifting results diverged")
  IO.println s!"C0_BENCH lifting legacy_ms={oldEnd - oldStart} direct_ms={newEnd - newStart} changed={newChanged} iterations={iterations}"

  let mut genericApps : Nat := 0
  let subsStart ← IO.monoMsNow
  for k in [:iterations] do
    let result :=
      psKernelExprInstantiateAt first 0 [PsKernelExpr.bvar (k % 4)] 0
    match result with
    | PsKernelExpr.app _ _ => genericApps := genericApps + 1
    | _ => throw (IO.userError "generic substitution changed form")
  let subsEnd ← IO.monoMsNow
  let mut specializedApps : Nat := 0
  let c0Start ← IO.monoMsNow
  for k in [:iterations] do
    let result := psKernelExprInstantiate1 first (PsKernelExpr.bvar (k % 4))
    match result with
    | PsKernelExpr.app _ _ => specializedApps := specializedApps + 1
    | _ => throw (IO.userError "single substitution changed form")
  let c0End ← IO.monoMsNow
  if !(Nat.beq genericApps specializedApps) then
    throw (IO.userError "substitution counts diverged")
  IO.println s!"C0_BENCH instantiate1 generic_ms={subsEnd - subsStart} specialized_ms={c0End - c0Start} apps={specializedApps} iterations={iterations}"

  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let mut locals := psKernelLocalContextEmpty
  for k in [:512] do
    let name := PsKernelName.num PsKernelName.anonymous k
    locals := psKernelLocalContextAddLocal locals name name
      sort0 PsKernelBinderInfo.default
  let queries := 20000
  let mut legacyLookupHits : Nat := 0
  let lookupStart ← IO.monoMsNow
  for k in [:queries] do
    let name := PsKernelName.num PsKernelName.anonymous (k % 16)
    match psKernelLocalContextFindIn name locals.decls with
    | Option.some _ => legacyLookupHits := legacyLookupHits + 1
    | Option.none => throw (IO.userError "linear local lookup missing")
  let lookupEnd ← IO.monoMsNow
  let mut indexedLookupHits : Nat := 0
  let indexedStart ← IO.monoMsNow
  for k in [:queries] do
    let name := PsKernelName.num PsKernelName.anonymous (k % 16)
    match psKernelLocalContextFind locals name with
    | Option.some _ => indexedLookupHits := indexedLookupHits + 1
    | Option.none => throw (IO.userError "indexed local lookup missing")
  let indexedEnd ← IO.monoMsNow
  if !(Nat.beq legacyLookupHits indexedLookupHits) then
    throw (IO.userError "local lookup counts diverged")
  IO.println s!"C0_BENCH locals linear_ms={lookupEnd - lookupStart} indexed_ms={indexedEnd - indexedStart} entries=512 queries={queries}"



  -- The public WHNF core now performs a demand-driven spine probe:
  -- stuck heads need no argument-list materialization.
  let mut eagerHits : Nat := 0
  let eagerStart ← IO.monoMsNow
  for k in [:iterations] do
    let current := if k % 2 == 0 then first else second
    let pair := psKernelExprGetAppFnArgs current
    if Nat.beq (psKernelExprListLength (Prod.snd pair)) 512 then
      match Prod.fst pair with
      | PsKernelExpr.bvar _ => eagerHits := eagerHits + 1
      | _ => pure ()
  let eagerEnd ← IO.monoMsNow
  let mut lazyHits : Nat := 0
  let lazyStart ← IO.monoMsNow
  for k in [:iterations] do
    let current := if k % 2 == 0 then first else second
    let head := psKernelExprGetAppFn current
    match head with
    | PsKernelExpr.bvar _ => lazyHits := lazyHits + 1
    | _ => pure ()
  let lazyEnd ← IO.monoMsNow
  if !(Nat.beq eagerHits lazyHits) then
    throw (IO.userError "WHNF lazy-head probe changed observable head")
  IO.println s!"C0_BENCH lazy_spine eager_ms={eagerEnd - eagerStart} head_only_ms={lazyEnd - lazyStart} hits={lazyHits} iterations={iterations}"


  -- Compare two *identical indexed* representations: old recursive
  -- rewriting and the new memoized DAG rewrite. This is not a whole-kernel
  -- benchmark and includes all per-call memo table construction costs.
  match psKernelC0Intern psKernelC0StoreEmpty (.bvar 0) with
  | Option.none => throw (IO.userError "C0 benchmark leaf failed")
  | Option.some (initial, leaf) =>
      match psKernelC0Intern initial (.bvar 23) with
      | Option.none => throw (IO.userError "C0 benchmark replacement failed")
      | Option.some (prepared, replacement) =>
          let mut terms := prepared
          let mut input := leaf
          for _ in [:11] do
            match psKernelC0Intern terms (.app input input) with
            | Option.none => throw (IO.userError "C0 benchmark shared node failed")
            | Option.some (next, id) =>
                terms := next
                input := id
          let runs := 70
          let mut oldCount := 0
          let oldStart ← IO.monoMsNow
          for _ in [:runs] do
            match psKernelC0Instantiate1IndexedReference terms input replacement with
            | Option.some (next, result) =>
                if psKernelC0StoreValid next result then
                  oldCount := oldCount + 1
            | Option.none => throw (IO.userError "C0 recursive indexed rewrite failed")
          let oldEnd ← IO.monoMsNow
          let mut memoCount := 0
          let memoStart ← IO.monoMsNow
          for _ in [:runs] do
            match psKernelC0Instantiate1Indexed terms input replacement with
            | Option.some (next, result) =>
                if psKernelC0StoreValid next result then
                  memoCount := memoCount + 1
            | Option.none => throw (IO.userError "C0 memoized indexed rewrite failed")
          let memoEnd ← IO.monoMsNow
          if !(Nat.beq oldCount memoCount) then
            throw (IO.userError "C0 indexed rewrite changed success count")
          IO.println s!"C0_BENCH indexed_dag recursive_ms={oldEnd - oldStart} memoized_ms={memoEnd - memoStart} depth=11 runs={runs} passed={memoCount}"


  -- The old indexed WHNF stuck-head path reconstructed the entire application
  -- spine even if the head did not reduce.  Measure that eliminated work
  -- separately from full checker throughput: same canonical term store,
  -- same 256-node stuck spine, no metadata or local environment.
  match psKernelC0Intern psKernelC0StoreEmpty (.bvar 0) with
  | Option.none => throw (IO.userError "C0 indexed WHNF benchmark head failed")
  | Option.some (headStore, headId) =>
      match psKernelC0Intern headStore (.bvar 1) with
      | Option.none => throw (IO.userError "C0 indexed WHNF benchmark arg failed")
      | Option.some (initialStore, argId) =>
          let mut terms := initialStore
          let mut root := headId
          let mut args : List Nat := []
          for _ in [:256] do
            match psKernelC0Intern terms (.app root argId) with
            | Option.none => throw (IO.userError "C0 indexed WHNF benchmark build failed")
            | Option.some (next, id) =>
                terms := next
                root := id
                args := argId :: args
          let runs := 600
          let mut rebuiltHits := 0
          let rebuiltStart ← IO.monoMsNow
          for _ in [:runs] do
            match psKernelC0IndexedApplySpine terms headId args with
            | Option.some (next, id) =>
                if Nat.beq id root && Nat.beq next.nodes.size terms.nodes.size then
                  rebuiltHits := rebuiltHits + 1
            | Option.none => throw (IO.userError "C0 indexed spine rebuild failed")
          let rebuiltEnd ← IO.monoMsNow
          let mut originalHits := 0
          let nativeStart ← IO.monoMsNow
          for _ in [:runs] do
            match psKernelC0IndexedWhnf 1024 terms root with
            | Option.some (next, id) =>
                if Nat.beq id root && Nat.beq next.nodes.size terms.nodes.size then
                  originalHits := originalHits + 1
            | Option.none => throw (IO.userError "C0 indexed stuck-head WHNF failed")
          let nativeEnd ← IO.monoMsNow
          if !(Nat.beq rebuiltHits runs && Nat.beq originalHits runs) then
            throw (IO.userError "C0 indexed stuck-spine outcomes diverged")
          IO.println s!"C0_BENCH indexed_stuck_spine reassemble_only_ms={rebuiltEnd - rebuiltStart} unchanged_head_whnf_ms={nativeEnd - nativeStart} depth=256 runs={runs} hits={originalHits}"


  -- Public C0 native checking-path baseline (no self-hosting).
  -- Every call begins with a fresh state, so this is a cold WHNF sample,
  -- not artificially amplified cache hits. Both source forms are constructed
  -- outside the timed loop; only the head varies across runtime iterations.
  let checkerContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let variableName := PsKernelName.str PsKernelName.anonymous "C0BenchmarkStuck"
  let stuck0 := c0BenchApps 128 (PsKernelExpr.mvar variableName)
    (PsKernelExpr.bvar 2)
  let stuck1 := c0BenchApps 128 (PsKernelExpr.mvar variableName)
    (PsKernelExpr.bvar 3)
  let coldRuns := 400
  let mut coldHits := 0
  let coldStart ← IO.monoMsNow
  for k in [:coldRuns] do
    let current := if k % 2 == 0 then stuck0 else stuck1
    match psKernelWhnfNoRecursor 4096 checkerContext
        psKernelCheckerStateEmpty current with
    | Except.error message =>
        throw (IO.userError ("C0 native cold WHNF failed: " ++ message))
    | Except.ok (reduced, _) =>
        if psKernelExprEqual current reduced then
          coldHits := coldHits + 1
        else
          throw (IO.userError "C0 cold native WHNF changed stuck spine")
  let coldEnd ← IO.monoMsNow
  if !(Nat.beq coldHits coldRuns) then
    throw (IO.userError "C0 cold WHNF did not return all expected values")
  IO.println s!"C0_BENCH native_checker_cold_whnf ms={coldEnd - coldStart} depth=128 runs={coldRuns} hits={coldHits}"


  -- A first cold DefEq baseline through the actual Lean checker session API.
  -- Fresh sessions avoid conflating cache-hit throughput with checking costs.
  -- Both positive beta conversion and negative sort comparison are included.
  let defEqSession := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let sortZero := PsKernelExpr.sort PsKernelLevel.zero
  let sortOne := PsKernelExpr.sort
    (PsKernelLevel.succ PsKernelLevel.zero)
  let identity := PsKernelExpr.lam PsKernelName.anonymous
    sortZero (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let beta := PsKernelExpr.app identity sortZero
  let comparisons := 200
  let mut yesCount := 0
  let yesStart ← IO.monoMsNow
  for _ in [:comparisons] do
    match psKernelSessionIsDefEq 4096 defEqSession beta sortZero with
    | Except.error message =>
        throw (IO.userError ("C0 cold positive DefEq error: " ++ message))
    | Except.ok (ok, _) =>
        if ok then yesCount := yesCount + 1
        else throw (IO.userError "C0 beta equality unexpectedly rejected")
  let yesEnd ← IO.monoMsNow
  let mut noCount := 0
  let noStart ← IO.monoMsNow
  for _ in [:comparisons] do
    match psKernelSessionIsDefEq 4096 defEqSession sortZero sortOne with
    | Except.error message =>
        throw (IO.userError ("C0 cold negative DefEq error: " ++ message))
    | Except.ok (ok, _) =>
        if !ok then noCount := noCount + 1
        else throw (IO.userError "C0 distinct universes accepted")
  let noEnd ← IO.monoMsNow
  if !(Nat.beq yesCount comparisons && Nat.beq noCount comparisons) then
    throw (IO.userError "C0 cold DefEq case counts incorrect")
  IO.println s!"C0_BENCH native_checker_cold_defeq beta_true_ms={yesEnd - yesStart} sort_false_ms={noEnd - noStart} comparisons={comparisons}"


  -- Measure the duplicate work removed from accepting DefEq: the top-level
  -- recursive checker has *already* ruled out syntactic equality and prior
  -- successful cache hits before entering the shape-specific quick rules.
  -- Use long universe levels to make that repeated structural scan visible.
  let baseName := PsKernelName.str PsKernelName.anonymous "C0DeepUniverse"
  let leftDeep := PsKernelExpr.sort
    (c0BenchSuccLevel 256 PsKernelLevel.zero)
  let rightDeep := PsKernelExpr.sort
    (c0BenchSuccLevel 256 (PsKernelLevel.param baseName))
  let quickContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let quickState := psKernelCheckerStateEmpty
  let quickDefeq :=
    fun (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (lhs : PsKernelExpr)
        (rhs : PsKernelExpr) =>
      psKernelIsDefEq 256 context state lhs rhs
  if psKernelExprEq leftDeep rightDeep then
    throw (IO.userError "C0 deep quick benchmark guard unexpectedly succeeded")
  let deepIterations := 3000
  let mut generalFalse := 0
  let generalStart ← IO.monoMsNow
  for _ in [:deepIterations] do
    match psKernelDefEqQuick quickDefeq quickContext quickState leftDeep rightDeep with
    | Except.ok (Option.some false, _) => generalFalse := generalFalse + 1
    | _ => throw (IO.userError "C0 general deep quick comparison changed outcome")
  let generalEnd ← IO.monoMsNow
  let mut guardedFalse := 0
  let guardedStart ← IO.monoMsNow
  for _ in [:deepIterations] do
    match psKernelDefEqQuickAfterCommon quickDefeq quickContext quickState
        leftDeep rightDeep with
    | Except.ok (Option.some false, _) => guardedFalse := guardedFalse + 1
    | _ => throw (IO.userError "C0 guarded deep quick comparison changed outcome")
  let guardedEnd ← IO.monoMsNow
  if !(Nat.beq generalFalse guardedFalse) then
    throw (IO.userError "C0 guarded deep quick result count mismatch")
  IO.println s!"C0_BENCH guarded_defeq_quick general_ms={generalEnd - generalStart} guarded_ms={guardedEnd - guardedStart} depth=256 iterations={deepIterations} failures={guardedFalse}"
