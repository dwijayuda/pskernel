import Ps.KernelCore.Checker.Reduction.IndexedWhnf
import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Checker.IndexedSession
import Ps.KernelCore.Admission.Declaration.Admission
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

/- Exact previous eager version, kept only for paired benchmark evidence. -/
def c0BenchEagerUnfoldDefinition
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  let fn :=
    psKernelExprGetAppFn expr;
  let args :=
    psKernelExprGetAppArgs expr;
  match fn with
  | PsKernelExpr.const name levels =>
      match
          psKernelEnvironmentFind
            context.environment
            name with
      | Option.none =>
          Option.none
      | Option.some info =>
          match
              psKernelConstantInfoDeltaValue info with
          | Option.none =>
              Option.none
          | Option.some value =>
              let params :=
                psKernelConstantInfoLevelParams info;
              if
                  Nat.beq
                    (psKernelNameListLength params)
                    (psKernelLevelListLength levels) then
                Option.some
                  (psKernelApplyArgs
                    (psKernelExprInstantiateLevelParams
                      value
                      params
                      levels)
                    args)
              else
                Option.none
  | _ =>
      Option.none


/-- Closed proof-function syntax shared between cold and warm inference. -/
def c0BenchLambdaChain : Nat -> PsKernelExpr
  | 0 => PsKernelExpr.bvar 0
  | n + 1 =>
      PsKernelExpr.lam PsKernelName.anonymous
        (PsKernelExpr.sort PsKernelLevel.zero)
        (c0BenchLambdaChain n)
        PsKernelBinderInfo.default

/-- Historical binder hash used as a benchmark-only reference.
    It omits binder names and binder info, creating dense collision buckets. -/
def c0BenchOldBinderHash
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) : Nat :=
  match node with
  | .lam _ ty body _ =>
      psKernelCacheMix
        (psKernelCacheMix 27 (psKernelC0ChildHash store ty))
        (psKernelC0ChildHash store body)
  | _ => psKernelC0NodeHash store node

def c0BenchOldBinderIntern
    (store : PsKernelC0TermStore)
    (node : PsKernelC0Node) :
    Option (Prod PsKernelC0TermStore Nat) :=
  if psKernelC0NodeValid store node then
    let hash := c0BenchOldBinderHash store node
    let bucket := psKernelC0TermTrieBucket psKernelC0IndexDepth store.index hash
    match psKernelC0FindNode store node bucket with
    | some id => some (store, id)
    | none =>
        let id := store.nodes.size
        let entry : PsKernelC0StoredNode :=
          { node := node, hash := hash, depth := psKernelC0NodeDepth store node,
            looseBVarRange := psKernelC0NodeLooseRange store node }
        let index := psKernelC0TermTrieReplace
          psKernelC0IndexDepth store.index hash (id :: bucket)
        some ({ nodes := store.nodes.push entry, index := index }, id)
  else
    none

def c0BenchBinderStore (historical : Bool) (count : Nat) :
    Option PsKernelC0TermStore := do
  let (initial, domainId) ←
    psKernelC0Intern psKernelC0StoreEmpty (.sort PsKernelLevel.zero)
  let (prepared, bodyId) ← psKernelC0Intern initial (.bvar 0)
  let mut store := prepared
  for i in [:count] do
    let name := PsKernelName.num PsKernelName.anonymous i
    let node : PsKernelC0Node :=
      .lam name domainId bodyId PsKernelBinderInfo.default
    let (next, _) ←
      if historical then c0BenchOldBinderIntern store node
      else psKernelC0Intern store node
    store := next
  pure store

/- Exact historical production worker, isolated to native benchmark source. -/
def c0BenchLegacyInferAppOnlyLoopWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    PsKernelExpr ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_args : List PsKernelExpr)
        (_index : Nat)
        (_instantiated : Nat)
        (_current : PsKernelExpr) =>
        Except.error
          "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        c0BenchLegacyInferAppOnlyLoopWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (args : List PsKernelExpr)
        (index : Nat)
        (instantiated : Nat)
        (current : PsKernelExpr) =>
        let argCount :=
          psKernelExprListLength args;
        if psKernelNatLt index argCount then
          match current with
          | PsKernelExpr.forallE _ _ body _ =>
              smaller
                whnf
                context
                state
                args
                (Nat.succ index)
                instantiated
                body
          | _ =>
              let pending :=
                psKernelExprListTake
                  (Nat.sub index instantiated)
                  (psKernelExprListDrop
                    instantiated
                    args);
              let exposed :=
                psKernelExprInstantiateRev
                  current
                  pending;
              match
                  psKernelEnsureForallWith
                    whnf
                    context
                    state
                    exposed with
              | Except.error error =>
                  Except.error error
              | Except.ok forallResult =>
                  let view :=
                    Prod.fst forallResult;
                  smaller
                    whnf
                    context
                    (Prod.snd forallResult)
                    args
                    (Nat.succ index)
                    index
                    view.body
        else
          Except.ok
            (Prod.mk
              (psKernelExprInstantiateRev
                current
                (psKernelExprListDrop
                  instantiated
                  args))
              state)


/-- Large forall spine with a constant result, to isolate repeated argument
    counting rather than environment-dependent reduction or type checking. -/
def c0BenchForallSpine : Nat → PsKernelExpr
  | 0 => .sort PsKernelLevel.zero
  | n + 1 =>
      .forallE PsKernelName.anonymous
        (.sort PsKernelLevel.zero)
        (c0BenchForallSpine n)
        PsKernelBinderInfo.default

/-- Forall spine with one genuinely loose de Bruijn variable. -/
def c0BenchOpenForallSpine : Nat → Nat → PsKernelExpr
  | 0, loose => .bvar loose
  | n + 1, loose =>
      .forallE PsKernelName.anonymous
        (.sort PsKernelLevel.zero)
        (c0BenchOpenForallSpine n loose)
        PsKernelBinderInfo.default

/-- Actual fully checked native application-spine workload, not head-only
    inference; the caller preconstructs syntax outside the timed section. -/
def c0BenchCheckedSpine : Nat → PsKernelExpr
  | 0 => PsKernelExpr.bvar 0
  | n + 1 =>
      PsKernelExpr.lam PsKernelName.anonymous
        (PsKernelExpr.sort (.succ PsKernelLevel.zero))
        (c0BenchCheckedSpine n) PsKernelBinderInfo.default

def main : IO Unit := do
  let arg := PsKernelExpr.bvar 2
  let first := c0BenchApps 512 (PsKernelExpr.bvar 0) arg
  let second := c0BenchApps 512 (PsKernelExpr.bvar 1) arg
  let iterations := 30000

  -- Same-run matched direct application argument selection. Deep constructor
  -- spines expose the cost of allocating a full intermediate argument list.
  let selectionName := PsKernelName.str PsKernelName.anonymous "C0.argSelector"
  let selectionTerm := (List.range 512).foldl
    (fun term i => PsKernelExpr.app term (PsKernelExpr.bvar i))
    (PsKernelExpr.const selectionName [])
  let selectionRuns := 18000
  let mut oldSelected := 0
  let oldSelectStart ← IO.monoMsNow
  for k in [:selectionRuns] do
    let pos := k % 512
    match psKernelExprListGet (psKernelExprGetAppArgs selectionTerm) pos with
    | Option.some value =>
        match value with
        | PsKernelExpr.bvar i =>
            if Nat.beq i pos then oldSelected := oldSelected + 1
            else throw (IO.userError "C0 eager selector returned wrong index")
        | _ => throw (IO.userError "C0 eager selector returned wrong kind")
    | Option.none => throw (IO.userError "C0 eager selector missing argument")
  let oldSelectEnd ← IO.monoMsNow
  let mut newSelected := 0
  let directSelectStart ← IO.monoMsNow
  for k in [:selectionRuns] do
    let pos := k % 512
    match psKernelExprGetAppArgAt selectionTerm pos with
    | Option.some value =>
        match value with
        | PsKernelExpr.bvar i =>
            if Nat.beq i pos then newSelected := newSelected + 1
            else throw (IO.userError "C0 direct selector returned wrong index")
        | _ => throw (IO.userError "C0 direct selector returned wrong kind")
    | Option.none => throw (IO.userError "C0 direct selector missing argument")
  let directSelectEnd ← IO.monoMsNow
  if !(Nat.beq oldSelected newSelected && Nat.beq newSelected selectionRuns) then
    throw (IO.userError "C0 direct argument selection diverged")
  IO.println s!"C0_BENCH app_arg_selection list_ms={oldSelectEnd - oldSelectStart} direct_ms={directSelectEnd - directSelectStart} depth=512 queries={selectionRuns}"
  -- Matched same-run hot-path benchmark, not a full kernel comparison.
  -- Both paths perform the exact delta lookup; the reference eagerly
  -- allocates the entire argument spine even when the head is stuck.
  let stuckName := PsKernelName.str PsKernelName.anonymous "C0MissingDefinition"
  let missingConst := c0BenchApps 512 (PsKernelExpr.const stuckName [])
    (PsKernelExpr.bvar 0)
  let missingMvar := c0BenchApps 512 (PsKernelExpr.mvar stuckName)
    (PsKernelExpr.bvar 0)
  let unfoldingCtx := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let mut eagerMisses := 0
  let eagerStart ← IO.monoMsNow
  for k in [:12000] do
    let current := if k % 2 == 0 then missingConst else missingMvar
    match c0BenchEagerUnfoldDefinition unfoldingCtx current with
    | Option.none => eagerMisses := eagerMisses + 1
    | Option.some _ => throw (IO.userError "C0 eager delta fixture unexpectedly unfolded")
  let eagerEnd ← IO.monoMsNow
  let mut lazyMisses := 0
  let lazyStart ← IO.monoMsNow
  for k in [:12000] do
    let current := if k % 2 == 0 then missingConst else missingMvar
    match psKernelUnfoldDefinition unfoldingCtx current with
    | Option.none => lazyMisses := lazyMisses + 1
    | Option.some _ => throw (IO.userError "C0 lazy delta fixture unexpectedly unfolded")
  let lazyEnd ← IO.monoMsNow
  if !(Nat.beq eagerMisses lazyMisses) then
    throw (IO.userError "C0 delta comparison outcomes diverged")
  IO.println s!"C0_BENCH lazy_delta_miss eager_ms={eagerEnd - eagerStart} lazy_ms={lazyEnd - lazyStart} depth=512 queries={lazyMisses}"


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

  -- Exact (binder-name-sensitive) equality also feeds syntax interning and
  -- session-owned term retention. Keep a paired historical comparison rather
  -- than treating equality's reduced allocation as a throughput guarantee.
  let nameA := PsKernelName.str PsKernelName.anonymous "ExactA"
  let nameB := PsKernelName.str PsKernelName.anonymous "ExactB"
  let closedA := PsKernelExpr.lam nameA (PsKernelExpr.sort PsKernelLevel.zero)
    first PsKernelBinderInfo.default
  let closedB := PsKernelExpr.lam nameB (PsKernelExpr.sort PsKernelLevel.zero)
    first PsKernelBinderInfo.default
  let exactRuns := 15000
  let mut legacyExact := 0
  let exactLegacyStart ← IO.monoMsNow
  for k in [:exactRuns] do
    let right := if k % 2 == 0 then closedA else closedB
    if psKernelExprEqualLegacy closedA right then
      legacyExact := legacyExact + 1
  let exactLegacyEnd ← IO.monoMsNow
  let mut directExact := 0
  let exactDirectStart ← IO.monoMsNow
  for k in [:exactRuns] do
    let right := if k % 2 == 0 then closedA else closedB
    if psKernelExprEqual closedA right then
      directExact := directExact + 1
  let exactDirectEnd ← IO.monoMsNow
  if legacyExact != directExact then
    throw (IO.userError "C0 exact equality implementation changed matches")
  IO.println s!"C0_BENCH exact_equality legacy_ms={exactLegacyEnd-exactLegacyStart} direct_ms={exactDirectEnd-exactDirectStart} iterations={exactRuns} hits={directExact}"

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

  -- Compare whole fully checked application judgments in two C0 paths.
  -- Preserve the original recursive accepting checker as differential oracle.
  let spineArgs := 48
  let checkedSpine := (List.range spineArgs).foldl
    (fun expr _ => PsKernelExpr.app expr
      (PsKernelExpr.sort PsKernelLevel.zero))
    (c0BenchCheckedSpine spineArgs)
  let checkedContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let checkedIterations := 80
  let originalStart ← IO.monoMsNow
  let mut originalOk := 0
  for _ in [:checkedIterations] do
    let defeq := psKernelIsDefEqWithFuel 4096
    let whnf := psKernelWhnfWithRecursorFuel 4096 defeq
    match psKernelCheckWithFuel 4096 whnf defeq checkedContext
        psKernelCheckerStateEmpty checkedSpine with
    | Except.ok (type, _) =>
        if psKernelExprEqual type (PsKernelExpr.sort (.succ PsKernelLevel.zero)) then
          originalOk := originalOk + 1
        else throw (IO.userError "original checked spine type mismatch")
    | Except.error err => throw (IO.userError ("original checked spine: " ++ err))
  let originalEnd ← IO.monoMsNow
  let framesStart ← IO.monoMsNow
  let mut framesOk := 0
  for _ in [:checkedIterations] do
    let defeq := psKernelIsDefEqWithFuel 4096
    let whnf := psKernelWhnfWithRecursorFuel 4096 defeq
    match psKernelC0CheckAppSpineWithFuel 4096 whnf defeq checkedContext
        psKernelCheckerStateEmpty checkedSpine with
    | Except.ok (type, _) =>
        if psKernelExprEqual type (PsKernelExpr.sort (.succ PsKernelLevel.zero)) then
          framesOk := framesOk + 1
        else throw (IO.userError "framed checked spine type mismatch")
    | Except.error err => throw (IO.userError ("framed checked spine: " ++ err))
  let framesEnd ← IO.monoMsNow
  if originalOk != checkedIterations || framesOk != checkedIterations then
    throw (IO.userError "C0 checked application counts diverged")
  IO.println s!"C0_BENCH checked_spine_full recursive_ms={originalEnd-originalStart} frames_ms={framesEnd-framesStart} iterations={checkedIterations} args={spineArgs}"

  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  -- Build cost includes all radix allocations. Compare against an
  -- identical immutable list-only context while preserving name/order.
  -- This distinguishes index maintenance overhead from deep lookup savings.
  for entryCount in [16, 32, 64, 128, 512] do
    let buildRuns := if entryCount == 512 then 15 else 160
    let buildStart ← IO.monoMsNow
    let mut indexedEntries := 0
    for _ in [:buildRuns] do
      let mut next := psKernelLocalContextEmpty
      for k in [:entryCount] do
        let name := PsKernelName.num PsKernelName.anonymous k
        next := psKernelLocalContextAddLocal next name name
          sort0 PsKernelBinderInfo.default
      indexedEntries := indexedEntries + next.decls.length
    let buildEnd ← IO.monoMsNow
    let linearStart ← IO.monoMsNow
    let mut linearEntries := 0
    for _ in [:buildRuns] do
      let mut next := psKernelLocalContextEmpty
      for k in [:entryCount] do
        let name := PsKernelName.num PsKernelName.anonymous k
        let decl := PsKernelLocalDecl.localDecl
          next.nextIndex name name sort0 PsKernelBinderInfo.default
        next := {
          decls := decl :: next.decls
          nextIndex := next.nextIndex + 1
          index := Option.none
        }
      linearEntries := linearEntries + next.decls.length
    let linearEnd ← IO.monoMsNow
    if indexedEntries != linearEntries ||
        indexedEntries != entryCount * buildRuns then
      throw (IO.userError "C0 local construction benchmark mismatch")
    IO.println s!"C0_BENCH locals_build list_ms={linearEnd-linearStart} adaptive_ms={buildEnd-buildStart} entries={entryCount} runs={buildRuns}"
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



  -- Isolate the redundant structural-equality traversal eliminated from the
  -- accepting DefEq path. The pair-cache is empty, both application spines
  -- differ at the deeply nested head, and the input varies at runtime.
  -- The general quick API checks equality again; the guarded API does not.
  let leftDeep := first
  let rightDeepA := second
  let rightDeepB := c0BenchApps 512 (PsKernelExpr.bvar 3) arg
  let quickContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let quickState := psKernelCheckerStateEmpty
  let quickDefeq :=
    fun (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (lhs : PsKernelExpr)
        (rhs : PsKernelExpr) =>
      psKernelIsDefEq 256 context state lhs rhs
  if psKernelExprEq leftDeep rightDeepA || psKernelExprEq leftDeep rightDeepB then
    throw (IO.userError "C0 deep quick benchmark guard unexpectedly succeeded")
  let deepIterations := 12000
  let mut generalMisses := 0
  let generalStart ← IO.monoMsNow
  for k in [:deepIterations] do
    let current := if k % 2 == 0 then rightDeepA else rightDeepB
    match psKernelDefEqQuick quickDefeq quickContext quickState leftDeep current with
    | Except.ok (Option.none, _) => generalMisses := generalMisses + 1
    | _ => throw (IO.userError "C0 general deep quick comparison changed outcome")
  let generalEnd ← IO.monoMsNow
  let mut guardedMisses := 0
  let guardedStart ← IO.monoMsNow
  for k in [:deepIterations] do
    let current := if k % 2 == 0 then rightDeepA else rightDeepB
    match psKernelDefEqQuickAfterCommon quickDefeq quickContext quickState
        leftDeep current with
    | Except.ok (Option.none, _) => guardedMisses := guardedMisses + 1
    | _ => throw (IO.userError "C0 guarded deep quick comparison changed outcome")
  let guardedEnd ← IO.monoMsNow
  if !(Nat.beq generalMisses guardedMisses) then
    throw (IO.userError "C0 guarded deep quick result count mismatch")
  IO.println s!"C0_BENCH guarded_defeq_quick general_ms={generalEnd - generalStart} guarded_ms={guardedEnd - guardedStart} depth=512 iterations={deepIterations} misses={guardedMisses}"


  -- Actual checker-session inference: cold results always start from a
  -- fresh cache; warm results reuse only the same unchanged environment and
  -- session. Both must compute a forall expression rather than shortcutting
  -- to an assumed success on raw indexed nodes.
  let inferTerm := c0BenchLambdaChain 24
  let inferSession := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let inferRuns := 180
  let mut coldInferCount := 0
  let coldInferStart ← IO.monoMsNow
  for _ in [:inferRuns] do
    match psKernelSessionInfer 4096 inferSession inferTerm with
    | Except.error error =>
        throw (IO.userError ("C0 cold inference failed: " ++ error))
    | Except.ok (type, _) =>
        match type with
        | PsKernelExpr.forallE _ _ _ _ =>
            coldInferCount := coldInferCount + 1
        | _ => throw (IO.userError "C0 cold inference returned non-function")
  let coldInferEnd ← IO.monoMsNow
  let mut warmSession := inferSession
  let mut warmInferCount := 0
  let warmInferStart ← IO.monoMsNow
  for _ in [:inferRuns] do
    match psKernelSessionInfer 4096 warmSession inferTerm with
    | Except.error error =>
        throw (IO.userError ("C0 warm inference failed: " ++ error))
    | Except.ok (type, next) =>
        match type with
        | PsKernelExpr.forallE _ _ _ _ =>
            warmInferCount := warmInferCount + 1
            warmSession := next
        | _ => throw (IO.userError "C0 warm inference returned non-function")
  let warmInferEnd ← IO.monoMsNow
  if !(Nat.beq coldInferCount warmInferCount &&
       Nat.beq coldInferCount inferRuns) then
    throw (IO.userError "C0 cold/warm inference count divergence")
  IO.println s!"C0_BENCH native_checker_infer cold_ms={coldInferEnd - coldInferStart} warm_ms={warmInferEnd - warmInferStart} lambda_depth=24 runs={inferRuns}"

  -- Admission is a complete checked kernel operation, unlike isolated
  -- substitution/probe measurements. Use the same immutable base environment
  -- and the same well-typed declaration on every fresh invocation.
  let admitName := PsKernelName.str PsKernelName.anonymous "C0.checkedWitness"
  let sortOne := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  let validDef : PsKernelDefinitionInfo := {
    base := { name := admitName, levelParams := [], type := sortOne }
    value := PsKernelExpr.sort PsKernelLevel.zero
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }
  let invalidDef : PsKernelDefinitionInfo := {
    base := validDef.base
    value := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }
  let admissionRuns := 120
  let mut admitted := 0
  let admitStart ← IO.monoMsNow
  for _ in [:admissionRuns] do
    match psKernelAddDefinition 4096 psKernelEnvironmentEmpty validDef
        4096 psKernelLeanNatMaxSizeDefault with
    | Except.error error =>
        throw (IO.userError ("C0 valid declaration rejected: " ++ error))
    | Except.ok next =>
        if psKernelEnvironmentContains next admitName then
          admitted := admitted + 1
        else throw (IO.userError "C0 declaration missing after admission")
  let admitEnd ← IO.monoMsNow
  let mut rejected := 0
  let rejectStart ← IO.monoMsNow
  for _ in [:admissionRuns] do
    match psKernelAddDefinition 4096 psKernelEnvironmentEmpty invalidDef
        4096 psKernelLeanNatMaxSizeDefault with
    | Except.error _ => rejected := rejected + 1
    | Except.ok _ => throw (IO.userError "C0 invalid declaration accepted")
  let rejectEnd ← IO.monoMsNow
  if !(Nat.beq admitted admissionRuns && Nat.beq rejected admissionRuns) then
    throw (IO.userError "C0 declaration admission result count mismatch")
  IO.println s!"C0_BENCH native_checker_admission accepted_ms={admitEnd - admitStart} rejected_ms={rejectEnd - rejectStart} runs={admissionRuns}"

  -- Linux process high-water RSS includes the full native benchmark process,
  -- not a per-case allocation count. Report it separately from throughput.
  let status ← IO.FS.readFile "/proc/self/status"
  for line in status.splitOn "\n" do
    if line.startsWith "VmHWM:" then
      IO.println s!"C0_BENCH process_peak_rss {line}"
    else if line.startsWith "VmRSS:" then
      IO.println s!"C0_BENCH process_current_rss {line}"
    else pure ()


  -- Opt-in persistent indexed retention around *actual* checked WHNF.
  -- The semantic result must be unchanged. Report overhead rather than
  -- treating structural sharing as an automatic performance improvement.
  let rootExpr := c0BenchApps 48 (PsKernelExpr.mvar PsKernelName.anonymous)
    (PsKernelExpr.bvar 4)
  let wrappedChecker := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    PsKernelDefinitionSafety.safe 4096 psKernelLeanNatMaxSizeDefault
  let optRuns := 1200
  let mut plainSession := wrappedChecker
  let plainStart ← IO.monoMsNow
  for _ in [:optRuns] do
    match psKernelSessionWhnf 4096 plainSession rootExpr with
    | Except.ok (value, next) =>
        if !(psKernelExprEqual value rootExpr) then
          throw (IO.userError "C0 baseline session changed stuck WHNF")
        plainSession := next
    | Except.error err =>
        throw (IO.userError ("C0 baseline session failed: " ++ err))
  let plainEnd ← IO.monoMsNow
  let mut ownedSession := psKernelC0IndexedSessionNew wrappedChecker
  let ownedStart ← IO.monoMsNow
  for _ in [:optRuns] do
    match psKernelC0IndexedSessionWhnf 4096 ownedSession rootExpr with
    | Except.ok (value, next) =>
        if !(psKernelExprEqual value rootExpr) then
          throw (IO.userError "C0 opt-in indexed session changed stuck WHNF")
        ownedSession := next
    | Except.error err =>
        throw (IO.userError ("C0 opt-in indexed session failed: " ++ err))
  let ownedEnd ← IO.monoMsNow
  if psKernelC0IndexedSessionRootCount ownedSession != 1 then
    throw (IO.userError "C0 indexed session repeatedly stored the same root")
  IO.println s!"C0_BENCH optin_indexed_whnf plain_ms={plainEnd-plainStart} indexed_ms={ownedEnd-ownedStart} runs={optRuns} roots={psKernelC0IndexedSessionRootCount ownedSession} nodes={psKernelC0IndexedSessionNodeCount ownedSession}"


  -- Same-run canonical-DAG binder-storm measurement. Exactly the same nodes
  -- and structural collision checks; only identity hashing differs.
  let binderRuns := 8
  let binderCount := 160
  let mut legacyNodeTotal := 0
  let legacyBinderStart ← IO.monoMsNow
  for _ in [:binderRuns] do
    match c0BenchBinderStore true binderCount with
    | none => throw (IO.userError "C0 historical binder benchmark failed")
    | some store => legacyNodeTotal := legacyNodeTotal + store.nodes.size
  let legacyBinderEnd ← IO.monoMsNow
  let mut nextNodeTotal := 0
  let exactBinderStart ← IO.monoMsNow
  for _ in [:binderRuns] do
    match c0BenchBinderStore false binderCount with
    | none => throw (IO.userError "C0 exact binder benchmark failed")
    | some store => nextNodeTotal := nextNodeTotal + store.nodes.size
  let exactBinderEnd ← IO.monoMsNow
  if legacyNodeTotal != nextNodeTotal ||
      nextNodeTotal != binderRuns * (binderCount + 2) then
    throw (IO.userError "C0 canonical binder benchmark node divergence")
  IO.println s!"C0_BENCH binder_intern_hash legacy_ms={legacyBinderEnd-legacyBinderStart} exact_ms={exactBinderEnd-exactBinderStart} runs={binderRuns} binders={binderCount}"


  let piDepth := 192
  let piArgs : List PsKernelExpr :=
    List.replicate piDepth (PsKernelExpr.sort PsKernelLevel.zero)
  let piType := c0BenchForallSpine piDepth
  let count := psKernelExprListLength piArgs
  let piContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let piWhnf :=
    fun (_ctx : PsKernelCheckerContext)
        (st : PsKernelCheckerState)
        (term : PsKernelExpr) =>
      Except.ok (term, st)
  let piRuns := 350
  let mut oldPiPassed := 0
  let oldPiStart ← IO.monoMsNow
  for _ in [:piRuns] do
    match c0BenchLegacyInferAppOnlyLoopWithFuel
        (count+1) piWhnf piContext psKernelCheckerStateEmpty piArgs
        0 0 piType with
    | Except.ok (result, _) =>
        if psKernelExprEqual result (PsKernelExpr.sort PsKernelLevel.zero) then
          oldPiPassed := oldPiPassed + 1
        else throw (IO.userError "C0 old infer-only spine returned unexpected type")
    | Except.error err => throw (IO.userError ("C0 old infer-only spine failed: " ++ err))
  let oldPiEnd ← IO.monoMsNow
  let mut newPiPassed := 0
  let newPiStart ← IO.monoMsNow
  for _ in [:piRuns] do
    match psKernelInferAppOnlyLoopWithFuelCount
        (count+1) count piWhnf piContext psKernelCheckerStateEmpty piArgs
        0 0 piType with
    | Except.ok (result, _) =>
        if psKernelExprEqual result (PsKernelExpr.sort PsKernelLevel.zero) then
          newPiPassed := newPiPassed + 1
        else throw (IO.userError "C0 counted infer-only spine returned unexpected type")
    | Except.error err => throw (IO.userError ("C0 counted infer-only spine failed: " ++ err))
  let newPiEnd ← IO.monoMsNow
  if oldPiPassed != piRuns || newPiPassed != piRuns then
    throw (IO.userError "C0 infer-only spine results diverged")
  IO.println s!"C0_BENCH infer_only_arity historical_ms={oldPiEnd-oldPiStart} counted_ms={newPiEnd-newPiStart} depth={piDepth} runs={piRuns}"


  -- Diagnosis for a complete checked-application slowdown observed in the
  -- matched original-vs-C0 benchmark. Closed forall codomains exercise the
  -- old loose-variable prepass and C0's always-traversing specialization.
  let closedCodomain := c0BenchForallSpine 48
  let instReplacement := PsKernelExpr.sort PsKernelLevel.zero
  let closedRuns := 9000
  let mut originalClosedCount := 0
  let originalClosedStart ← IO.monoMsNow
  for _ in [:closedRuns] do
    let result :=
      if psKernelExprHasLooseBVar closedCodomain then
        psKernelExprInstantiate closedCodomain [instReplacement]
      else closedCodomain
    if psKernelExprEqual result closedCodomain then
      originalClosedCount := originalClosedCount + 1
    else throw (IO.userError "C0 reference closed instantiate changed term")
  let originalClosedEnd ← IO.monoMsNow
  let mut c0ClosedCount := 0
  let c0ClosedStart ← IO.monoMsNow
  for _ in [:closedRuns] do
    let result := psKernelExprInstantiate1 closedCodomain instReplacement
    if psKernelExprEqual result closedCodomain then
      c0ClosedCount := c0ClosedCount + 1
    else throw (IO.userError "C0 specialized closed instantiate changed term")
  let c0ClosedEnd ← IO.monoMsNow
  if originalClosedCount != c0ClosedCount || c0ClosedCount != closedRuns then
    throw (IO.userError "C0 closed substitution result divergence")
  IO.println s!"C0_BENCH instantiate_closed legacy_prepass_ms={originalClosedEnd-originalClosedStart} specialized_ms={c0ClosedEnd-c0ClosedStart} depth=48 runs={closedRuns}"


  let openCodomain := c0BenchOpenForallSpine 48 48
  let openRuns := 4000
  let mut legacyOpenCount := 0
  let legacyOpenStart ← IO.monoMsNow
  for _ in [:openRuns] do
    let result :=
      if psKernelExprHasLooseBVar openCodomain then
        psKernelExprInstantiate openCodomain [instReplacement]
      else openCodomain
    if !(psKernelExprEqual result openCodomain) then
      legacyOpenCount := legacyOpenCount + 1
    else throw (IO.userError "C0 open oracle unexpectedly unchanged")
  let legacyOpenEnd ← IO.monoMsNow
  let mut specializedOpenCount := 0
  let specializedOpenStart ← IO.monoMsNow
  for _ in [:openRuns] do
    let result := psKernelExprInstantiate1 openCodomain instReplacement
    if !(psKernelExprEqual result openCodomain) then
      specializedOpenCount := specializedOpenCount + 1
    else throw (IO.userError "C0 open specialization unexpectedly unchanged")
  let specializedOpenEnd ← IO.monoMsNow
  if legacyOpenCount != specializedOpenCount ||
      specializedOpenCount != openRuns then
    throw (IO.userError "C0 open substitution outcomes diverged")
  IO.println s!"C0_BENCH instantiate_open legacy_prepass_ms={legacyOpenEnd-legacyOpenStart} specialized_ms={specializedOpenEnd-specializedOpenStart} depth=48 runs={openRuns}"


  -- A whole indexed DAG can be closed under its own binders. The stored
  -- exact loose range allows an unchanged root to bypass *all* recursive
  -- memo-table setup and subtree reconstruction. Same-store comparison
  -- retains exact syntax and does not issue any kernel acceptance verdict.
  match psKernelC0Intern psKernelC0StoreEmpty (.sort PsKernelLevel.zero) with
  | none => throw (IO.userError "C0 closed DAG sort creation failed")
  | some (s0, tyId) =>
      match psKernelC0Intern s0 (.bvar 0) with
      | none => throw (IO.userError "C0 closed DAG bound leaf failed")
      | some (s1, bodyId) =>
          match psKernelC0Intern s1 (.lam PsKernelName.anonymous
              tyId bodyId PsKernelBinderInfo.default) with
          | none => throw (IO.userError "C0 closed DAG binder failed")
          | some (initial, lamId) =>
              let mut store := initial
              let mut root := lamId
              for _ in [:11] do
                match psKernelC0Intern store (.app root root) with
                | none => throw (IO.userError "C0 closed DAG sharing failed")
                | some (next, shared) =>
                    store := next
                    root := shared
              let runs := 100
              let oldStart ← IO.monoMsNow
              let mut oldKept := 0
              for _ in [:runs] do
                match psKernelC0Instantiate1IndexedReference store root bodyId with
                | none => throw (IO.userError "C0 closed DAG old rewrite failed")
                | some (_, result) =>
                    if result == root then oldKept := oldKept + 1
              let oldEnd ← IO.monoMsNow
              let newStart ← IO.monoMsNow
              let mut newKept := 0
              for _ in [:runs] do
                match psKernelC0Instantiate1Indexed store root bodyId with
                | none => throw (IO.userError "C0 closed DAG new rewrite failed")
                | some (_, result) =>
                    if result == root then newKept := newKept + 1
              let newEnd ← IO.monoMsNow
              if oldKept != runs || newKept != runs then
                throw (IO.userError "C0 closed DAG unchanged handle was not retained")
              IO.println s!"C0_BENCH cached_loose_range old_recursive_ms={oldEnd-oldStart} pruned_memo_ms={newEnd-newStart} depth=11 runs={runs}"
