import Lean
import Ps.KernelSelfHost.CheckerSession

def psKernelBenchName
    (index : Nat) :
    PsKernelName :=
  PsKernelName.num
    (PsKernelName.str
      PsKernelName.anonymous
      "bench")
    index

def psKernelBenchInfo
    (index : Nat) :
    PsKernelConstantInfo :=
  PsKernelConstantInfo.axiomInfo {
    base := {
      name := psKernelBenchName index
      levelParams := List.nil
      type := PsKernelExpr.sort PsKernelLevel.zero
    }
    isUnsafe := false
  }

def psKernelBenchBuildEnvironment
    (count : Nat) :
    PsKernelEnvironment :=
  let rec go
      (remaining : Nat)
      (index : Nat)
      (environment : PsKernelEnvironment) :
      PsKernelEnvironment :=
    match remaining with
    | Nat.zero =>
        environment
    | Nat.succ rest =>
        go
          rest
          (Nat.succ index)
          (psKernelEnvironmentAddUnchecked
            environment
            (psKernelBenchInfo index))
  go
    count
    0
    psKernelEnvironmentEmpty


partial def psKernelBenchEnvironmentIndexedLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (target : PsKernelName) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchEnvironmentIndexedLoop
          rest
          environment
          target
      match
          psKernelEnvironmentFind
            environment
            target with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail

partial def psKernelBenchEnvironmentLinearLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (target : PsKernelName) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchEnvironmentLinearLoop
          rest
          environment
          target
      match
          psKernelFindConstantInList
            target
            environment.constants with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail
def psKernelBenchBuildCache
    (count : Nat) :
    Prod
      PsKernelExprMap
      (List (Prod PsKernelExpr PsKernelExpr)) :=
  let rec go
      (remaining : Nat)
      (index : Nat)
      (cache : PsKernelExprMap)
      (entries : List (Prod PsKernelExpr PsKernelExpr)) :
      Prod
        PsKernelExprMap
        (List (Prod PsKernelExpr PsKernelExpr)) :=
    match remaining with
    | Nat.zero =>
        Prod.mk cache entries
    | Nat.succ rest =>
        let key :=
          PsKernelExpr.const
            (psKernelBenchName index)
            List.nil
        let value :=
          PsKernelExpr.lit
            (PsKernelLiteral.nat index)
        go
          rest
          (Nat.succ index)
          (psKernelExprMapInsert cache key value)
          (List.cons
            (Prod.mk key value)
            entries)
  go
    count
    0
    psKernelExprMapEmpty
    List.nil


partial def psKernelBenchCacheIndexedLoop
    (iterations : Nat)
    (cache : PsKernelExprMap)
    (target : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchCacheIndexedLoop
          rest
          cache
          target
      match psKernelExprMapGet cache target with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail

partial def psKernelBenchCacheLinearLoop
    (iterations : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (target : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchCacheLinearLoop
          rest
          entries
          target
      match
          psKernelExprMapGetIn
            target
            entries with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail
def psKernelBenchElapsed
    (start stop : Nat) :
    Nat :=
  Nat.sub stop start

partial def psKernelBenchNameHashLoop
    (iterations : Nat)
    (name : PsKernelName) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNameHashLoop
          rest
          name
      pure
        (Nat.add
          tail
          (psKernelEnvironmentNameHash name))

partial def psKernelBenchExprHashLoop
    (iterations : Nat)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchExprHashLoop
          rest
          expr
      pure
        (Nat.add
          tail
          (psKernelExprHash expr))

partial def psKernelBenchEnvironmentPrehashedLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (target : PsKernelName)
    (hash : Nat) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchEnvironmentPrehashedLoop
          rest
          environment
          target
          hash
      match
          psKernelFindConstantInList
            target
            (psKernelEnvironmentIndexFindWorker
              16
              environment.index
              hash) with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail

partial def psKernelBenchCachePrehashedLoop
    (iterations : Nat)
    (cache : PsKernelExprMap)
    (target : PsKernelExpr)
    (hash : Nat) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchCachePrehashedLoop
          rest
          cache
          target
          hash
      let result :=
        match cache.index with
        | Option.none =>
            psKernelExprMapGetIn
              target
              cache.small
        | Option.some index =>
            psKernelExprMapGetIn
              target
              (psKernelExprMapIndexBucket
                16
                index
                hash);
      match result with
      | Option.some _ =>
          pure (Nat.succ tail)
      | Option.none =>
          pure tail

def psKernelBenchLeanNatName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "Nat"

def psKernelBenchLeanDeltaName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchDelta"

def psKernelBenchLeanEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  let withNat ←
    match
        Lean.Kernel.Environment.addDecl
          base
          {}
          (.axiomDecl {
            name := psKernelBenchLeanNatName
            levelParams := []
            type :=
              Lean.Expr.sort
                (Lean.Level.succ Lean.Level.zero)
            isUnsafe := false
          }) with
    | .ok environment =>
        pure environment
    | .error _ =>
        throw
          (IO.userError
            "PSKERNEL_BENCH failed to create Lean Nat fixture")
  let withDef ←
    match
        Lean.Kernel.Environment.addDecl
          withNat
          {}
          (.defnDecl {
            name := psKernelBenchLeanDeltaName
            levelParams := []
            type :=
              Lean.Expr.const
                psKernelBenchLeanNatName
                []
            value :=
              Lean.Expr.lit
                (Lean.Literal.natVal 42)
            hints := Lean.ReducibilityHints.regular 0
            safety := Lean.DefinitionSafety.safe
          }) with
    | .ok environment =>
        pure environment
    | .error _ =>
        throw
          (IO.userError
            "PSKERNEL_BENCH failed to create Lean delta fixture")
  pure
    (Lean.Environment.ofKernelEnv
      withDef)

partial def psKernelBenchLeanWhnfLoop
    (iterations : Nat)
    (environment : Lean.Environment)
    (expr : Lean.Expr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanWhnfLoop
          rest
          environment
          expr
      match
          Lean.Kernel.whnf
            environment
            ({} : Lean.LocalContext)
            expr with
      | .ok _ =>
          pure (Nat.succ tail)
      | .error _ =>
          pure tail

partial def psKernelBenchLeanDefEqLoop
    (iterations : Nat)
    (environment : Lean.Environment)
    (left right : Lean.Expr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanDefEqLoop
          rest
          environment
          left
          right
      match
          Lean.Kernel.isDefEq
            environment
            ({} : Lean.LocalContext)
            left
            right with
      | .ok value =>
          if value then
            pure (Nat.succ tail)
          else
            pure tail
      | .error _ =>
          pure tail

def psKernelBenchDeltaName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchDelta"

def psKernelBenchCheckerEnvironment :
    PsKernelEnvironment :=
  let natBase : PsKernelConstantBase := {
    name := psKernelNatName
    levelParams := List.nil
    type :=
      PsKernelExpr.sort
        (PsKernelLevel.succ PsKernelLevel.zero)
  }
  let env1 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo {
        base := natBase
        isUnsafe := false
      })
  psKernelEnvironmentAddUnchecked
    env1
    (PsKernelConstantInfo.defnInfo {
      base := {
        name := psKernelBenchDeltaName
        levelParams := List.nil
        type :=
          PsKernelExpr.const
            psKernelNatName
            List.nil
      }
      value :=
        PsKernelExpr.lit
          (PsKernelLiteral.nat 42)
      hints := PsKernelReducibilityHints.regular 0
      safety := PsKernelDefinitionSafety.safe
    })

def psKernelBenchFreshSession
    (environment : PsKernelEnvironment) :
    PsKernelCheckerSession :=
  psKernelMkCheckerSession
    environment
    List.nil
    PsKernelDefinitionSafety.safe
    0
    psKernelLeanNatMaxSizeDefault

partial def psKernelBenchWhnfColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchWhnfColdLoop
          rest
          environment
          expr
      match
          psKernelSessionWhnf
            512
            (psKernelBenchFreshSession
              environment)
            expr with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchWhnfWarmLoop
    (iterations : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    IO (Prod Nat PsKernelCheckerSession) :=
  match iterations with
  | Nat.zero =>
      pure (Prod.mk 0 session)
  | Nat.succ rest =>
      match
          psKernelSessionWhnf
            512
            session
            expr with
      | Except.error _ =>
          psKernelBenchWhnfWarmLoop
            rest
            session
            expr
      | Except.ok result => do
          let tail ←
            psKernelBenchWhnfWarmLoop
              rest
              (Prod.snd result)
              expr
          pure
            (Prod.mk
              (Nat.succ (Prod.fst tail))
              (Prod.snd tail))

partial def psKernelBenchDefEqColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (left right : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchDefEqColdLoop
          rest
          environment
          left
          right
      match
          psKernelSessionIsDefEq
            1024
            (psKernelBenchFreshSession
              environment)
            left
            right with
      | Except.ok result =>
          if Prod.fst result then
            pure (Nat.succ tail)
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchDefEqWarmLoop
    (iterations : Nat)
    (session : PsKernelCheckerSession)
    (left right : PsKernelExpr) :
    IO (Prod Nat PsKernelCheckerSession) :=
  match iterations with
  | Nat.zero =>
      pure (Prod.mk 0 session)
  | Nat.succ rest =>
      match
          psKernelSessionIsDefEq
            1024
            session
            left
            right with
      | Except.error _ =>
          psKernelBenchDefEqWarmLoop
            rest
            session
            left
            right
      | Except.ok result =>
          if Prod.fst result then do
            let tail ←
              psKernelBenchDefEqWarmLoop
                rest
                (Prod.snd result)
                left
                right
            pure
              (Prod.mk
                (Nat.succ (Prod.fst tail))
                (Prod.snd tail))
          else
            psKernelBenchDefEqWarmLoop
              rest
              (Prod.snd result)
              left
              right

partial def psKernelBenchInferColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchInferColdLoop
          rest
          environment
          expr
      match
          psKernelSessionInfer
            1024
            (psKernelBenchFreshSession
              environment)
            expr with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchIsPropColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchIsPropColdLoop
          rest
          environment
          expr
      match
          psKernelSessionIsProp
            1024
            (psKernelBenchFreshSession
              environment)
            expr with
      | Except.ok result =>
          if Prod.fst result then
            pure tail
          else
            pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchProofProbeColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchProofProbeColdLoop
          rest
          environment
          expr
      let session :=
        psKernelBenchFreshSession environment
      match
          psKernelSessionInfer
            1024
            session
            expr with
      | Except.error _ =>
          pure tail
      | Except.ok typeResult =>
          match
              psKernelSessionIsProp
                1024
                (Prod.snd typeResult)
                (Prod.fst typeResult) with
          | Except.ok propResult =>
              if Prod.fst propResult then
                pure tail
              else
                pure (Nat.succ tail)
          | Except.error _ =>
              pure tail

partial def psKernelBenchLazyDeltaColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (left right : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLazyDeltaColdLoop
          rest
          environment
          left
          right
      let session :=
        psKernelBenchFreshSession environment
      let defeq :=
        psKernelIsDefEqWithFuel 1024
      let whnf :=
        psKernelWhnfWithRecursorFuel
          1024
          defeq
      let coreWhnf :=
        psKernelWhnfCoreWithRecursorFuel
          1024
          defeq
      match
          psKernelDefEqLazyReductionWithFuel
            1024
            defeq
            whnf
            coreWhnf
            session.context
            session.state
            left
            right with
      | Except.ok result =>
          match Prod.fst result with
          | PsKernelDeltaResult.decided value =>
              if value then
                pure (Nat.succ tail)
              else
                pure tail
          | PsKernelDeltaResult.residual _ _ =>
              pure tail
      | Except.error _ =>
          pure tail

def psKernelBenchAppName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchApply"

def psKernelBenchLeanAppName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchApply"

def psKernelBenchNatType : PsKernelExpr :=
  PsKernelExpr.const
    psKernelNatName
    List.nil

def psKernelBenchNatArrowType
    (arity : Nat) :
    PsKernelExpr :=
  match arity with
  | Nat.zero =>
      psKernelBenchNatType
  | Nat.succ rest =>
      PsKernelExpr.forallE
        PsKernelName.anonymous
        psKernelBenchNatType
        (psKernelBenchNatArrowType rest)
        PsKernelBinderInfo.default

def psKernelBenchLeanNatType : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNatName
    []

def psKernelBenchLeanNatArrowType
    (arity : Nat) :
    Lean.Expr :=
  match arity with
  | Nat.zero =>
      psKernelBenchLeanNatType
  | Nat.succ rest =>
      Lean.Expr.forallE
        Lean.Name.anonymous
        psKernelBenchLeanNatType
        (psKernelBenchLeanNatArrowType rest)
        Lean.BinderInfo.default

def psKernelBenchApplyNatArgs
    (remaining : Nat)
    (nextValue : Nat)
    (fn : PsKernelExpr) :
    PsKernelExpr :=
  match remaining with
  | Nat.zero =>
      fn
  | Nat.succ rest =>
      psKernelBenchApplyNatArgs
        rest
        (Nat.succ nextValue)
        (PsKernelExpr.app
          fn
          (PsKernelExpr.lit
            (PsKernelLiteral.nat nextValue)))

def psKernelBenchApplyLeanNatArgs
    (remaining : Nat)
    (nextValue : Nat)
    (fn : Lean.Expr) :
    Lean.Expr :=
  match remaining with
  | Nat.zero =>
      fn
  | Nat.succ rest =>
      psKernelBenchApplyLeanNatArgs
        rest
        (Nat.succ nextValue)
        (Lean.Expr.app
          fn
          (Lean.Expr.lit
            (Lean.Literal.natVal nextValue)))

def psKernelBenchApplicationEnvironment
    (arity : Nat) :
    PsKernelEnvironment :=
  psKernelEnvironmentAddUnchecked
    psKernelBenchCheckerEnvironment
    (PsKernelConstantInfo.axiomInfo {
      base := {
        name := psKernelBenchAppName
        levelParams := List.nil
        type := psKernelBenchNatArrowType arity
      }
      isUnsafe := false
    })

def psKernelBenchLeanApplicationEnvironment
    (arity : Nat) :
    IO Lean.Environment := do
  let environment ←
    psKernelBenchLeanEnvironment
  match
      Lean.Kernel.Environment.addDecl
        environment.toKernelEnv
        {}
        (.axiomDecl {
          name := psKernelBenchLeanAppName
          levelParams := []
          type := psKernelBenchLeanNatArrowType arity
          isUnsafe := false
        }) with
  | .ok next =>
      pure
        (Lean.Environment.ofKernelEnv next)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create application fixture")

partial def psKernelBenchCheckColdLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchCheckColdLoop
          rest
          environment
          expr
      match
          psKernelSessionCheck
            2048
            (psKernelBenchFreshSession
              environment)
            expr with
      | Except.ok _ =>
          pure (Nat.succ tail)
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanCheckLoop
    (iterations : Nat)
    (environment : Lean.Environment)
    (expr : Lean.Expr) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanCheckLoop
          rest
          environment
          expr
      match
          Lean.Kernel.check
            environment
            ({} : Lean.LocalContext)
            expr with
      | .ok _ =>
          pure (Nat.succ tail)
      | .error _ =>
          pure tail

def main : IO Unit := do
  let size := 2048
  let iterations := 2000
  let environment :=
    psKernelBenchBuildEnvironment size
  let targetName :=
    psKernelBenchName 0

  let envIndexedStart ← IO.monoNanosNow
  let envIndexedHits ←
    psKernelBenchEnvironmentIndexedLoop
      iterations
      environment
      targetName
  let envIndexedStop ← IO.monoNanosNow

  let envLinearStart ← IO.monoNanosNow
  let envLinearHits ←
    psKernelBenchEnvironmentLinearLoop
      iterations
      environment
      targetName
  let envLinearStop ← IO.monoNanosNow

  let cacheResult :=
    psKernelBenchBuildCache size
  let cache :=
    Prod.fst cacheResult
  let entries :=
    Prod.snd cacheResult
  let targetExpr :=
    PsKernelExpr.const
      targetName
      List.nil

  let cacheIndexedStart ← IO.monoNanosNow
  let cacheIndexedHits ←
    psKernelBenchCacheIndexedLoop
      iterations
      cache
      targetExpr
  let cacheIndexedStop ← IO.monoNanosNow

  let cacheLinearStart ← IO.monoNanosNow
  let cacheLinearHits ←
    psKernelBenchCacheLinearLoop
      iterations
      entries
      targetExpr
  let cacheLinearStop ← IO.monoNanosNow

  let targetNameHash :=
    psKernelEnvironmentNameHash targetName
  let targetExprHash :=
    psKernelExprHash targetExpr

  let nameHashStart ← IO.monoNanosNow
  let nameHashAccumulator ←
    psKernelBenchNameHashLoop
      iterations
      targetName
  let nameHashStop ← IO.monoNanosNow

  let exprHashStart ← IO.monoNanosNow
  let exprHashAccumulator ←
    psKernelBenchExprHashLoop
      iterations
      targetExpr
  let exprHashStop ← IO.monoNanosNow

  let envPrehashedStart ← IO.monoNanosNow
  let envPrehashedHits ←
    psKernelBenchEnvironmentPrehashedLoop
      iterations
      environment
      targetName
      targetNameHash
  let envPrehashedStop ← IO.monoNanosNow

  let cachePrehashedStart ← IO.monoNanosNow
  let cachePrehashedHits ←
    psKernelBenchCachePrehashedLoop
      iterations
      cache
      targetExpr
      targetExprHash
  let cachePrehashedStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH environment_indexed_ns=" ++
      toString
        (psKernelBenchElapsed
          envIndexedStart
          envIndexedStop) ++
      " environment_linear_ns=" ++
      toString
        (psKernelBenchElapsed
          envLinearStart
          envLinearStop) ++
      " environment_hits=" ++
      toString envIndexedHits ++
      "/" ++
      toString envLinearHits)
  IO.println
    ("PSKERNEL_BENCH cache_indexed_ns=" ++
      toString
        (psKernelBenchElapsed
          cacheIndexedStart
          cacheIndexedStop) ++
      " cache_linear_ns=" ++
      toString
        (psKernelBenchElapsed
          cacheLinearStart
          cacheLinearStop) ++
      " cache_hits=" ++
      toString cacheIndexedHits ++
      "/" ++
      toString cacheLinearHits)

  IO.println
    ("PSKERNEL_BENCH name_hash_ns=" ++
      toString
        (psKernelBenchElapsed
          nameHashStart
          nameHashStop) ++
      " expr_hash_ns=" ++
      toString
        (psKernelBenchElapsed
          exprHashStart
          exprHashStop) ++
      " accumulators=" ++
      toString nameHashAccumulator ++
      "/" ++
      toString exprHashAccumulator)
  IO.println
    ("PSKERNEL_BENCH environment_prehashed_ns=" ++
      toString
        (psKernelBenchElapsed
          envPrehashedStart
          envPrehashedStop) ++
      " cache_prehashed_ns=" ++
      toString
        (psKernelBenchElapsed
          cachePrehashedStart
          cachePrehashedStop) ++
      " hits=" ++
      toString envPrehashedHits ++
      "/" ++
      toString cachePrehashedHits)

  let checkerEnvironment :=
    psKernelBenchCheckerEnvironment
  let checkerExpr :=
    PsKernelExpr.const
      psKernelBenchDeltaName
      List.nil
  let checkerExpected :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 42)
  let checkerIterations := 1000

  let checkerNatType :=
    PsKernelExpr.const
      psKernelNatName
      List.nil

  let inferColdStart ← IO.monoNanosNow
  let inferColdHits ←
    psKernelBenchInferColdLoop
      checkerIterations
      checkerEnvironment
      checkerExpr
  let inferColdStop ← IO.monoNanosNow

  let isPropColdStart ← IO.monoNanosNow
  let isPropColdHits ←
    psKernelBenchIsPropColdLoop
      checkerIterations
      checkerEnvironment
      checkerNatType
  let isPropColdStop ← IO.monoNanosNow

  let proofProbeStart ← IO.monoNanosNow
  let proofProbeHits ←
    psKernelBenchProofProbeColdLoop
      checkerIterations
      checkerEnvironment
      checkerExpr
  let proofProbeStop ← IO.monoNanosNow

  let lazyDeltaStart ← IO.monoNanosNow
  let lazyDeltaHits ←
    psKernelBenchLazyDeltaColdLoop
      checkerIterations
      checkerEnvironment
      checkerExpr
      checkerExpected
  let lazyDeltaStop ← IO.monoNanosNow

  let whnfColdStart ← IO.monoNanosNow
  let whnfColdHits ←
    psKernelBenchWhnfColdLoop
      checkerIterations
      checkerEnvironment
      checkerExpr
  let whnfColdStop ← IO.monoNanosNow

  let whnfWarmSeed :=
    psKernelSessionWhnf
      512
      (psKernelBenchFreshSession
        checkerEnvironment)
      checkerExpr
  let whnfWarmSession :=
    match whnfWarmSeed with
    | Except.ok result =>
        Prod.snd result
    | Except.error _ =>
        psKernelBenchFreshSession
          checkerEnvironment
  let whnfWarmStart ← IO.monoNanosNow
  let whnfWarmResult ←
    psKernelBenchWhnfWarmLoop
      checkerIterations
      whnfWarmSession
      checkerExpr
  let whnfWarmStop ← IO.monoNanosNow

  let defeqColdStart ← IO.monoNanosNow
  let defeqColdHits ←
    psKernelBenchDefEqColdLoop
      checkerIterations
      checkerEnvironment
      checkerExpr
      checkerExpected
  let defeqColdStop ← IO.monoNanosNow

  let defeqWarmSeed :=
    psKernelSessionIsDefEq
      1024
      (psKernelBenchFreshSession
        checkerEnvironment)
      checkerExpr
      checkerExpected
  let defeqWarmSession :=
    match defeqWarmSeed with
    | Except.ok result =>
        Prod.snd result
    | Except.error _ =>
        psKernelBenchFreshSession
          checkerEnvironment
  let defeqWarmStart ← IO.monoNanosNow
  let defeqWarmResult ←
    psKernelBenchDefEqWarmLoop
      checkerIterations
      defeqWarmSession
      checkerExpr
      checkerExpected
  let defeqWarmStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH infer_cold_ns=" ++
      toString
        (psKernelBenchElapsed
          inferColdStart
          inferColdStop) ++
      " isprop_cold_ns=" ++
      toString
        (psKernelBenchElapsed
          isPropColdStart
          isPropColdStop) ++
      " hits=" ++
      toString inferColdHits ++
      "/" ++
      toString isPropColdHits)

  IO.println
    ("PSKERNEL_BENCH proof_probe_ns=" ++
      toString
        (psKernelBenchElapsed
          proofProbeStart
          proofProbeStop) ++
      " lazy_delta_ns=" ++
      toString
        (psKernelBenchElapsed
          lazyDeltaStart
          lazyDeltaStop) ++
      " hits=" ++
      toString proofProbeHits ++
      "/" ++
      toString lazyDeltaHits)

  IO.println
    ("PSKERNEL_BENCH whnf_cold_ns=" ++
      toString
        (psKernelBenchElapsed
          whnfColdStart
          whnfColdStop) ++
      " whnf_warm_ns=" ++
      toString
        (psKernelBenchElapsed
          whnfWarmStart
          whnfWarmStop) ++
      " whnf_hits=" ++
      toString whnfColdHits ++
      "/" ++
      toString (Prod.fst whnfWarmResult))
  IO.println
    ("PSKERNEL_BENCH defeq_cold_ns=" ++
      toString
        (psKernelBenchElapsed
          defeqColdStart
          defeqColdStop) ++
      " defeq_warm_ns=" ++
      toString
        (psKernelBenchElapsed
          defeqWarmStart
          defeqWarmStop) ++
      " defeq_hits=" ++
      toString defeqColdHits ++
      "/" ++
      toString (Prod.fst defeqWarmResult))

  let leanEnvironment ←
    psKernelBenchLeanEnvironment
  let leanExpr :=
    Lean.Expr.const
      psKernelBenchLeanDeltaName
      []
  let leanExpected :=
    Lean.Expr.lit
      (Lean.Literal.natVal 42)

  let leanWhnfStart ← IO.monoNanosNow
  let leanWhnfHits ←
    psKernelBenchLeanWhnfLoop
      checkerIterations
      leanEnvironment
      leanExpr
  let leanWhnfStop ← IO.monoNanosNow

  let leanDefEqStart ← IO.monoNanosNow
  let leanDefEqHits ←
    psKernelBenchLeanDefEqLoop
      checkerIterations
      leanEnvironment
      leanExpr
      leanExpected
  let leanDefEqStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH official_lean_whnf_ns=" ++
      toString
        (psKernelBenchElapsed
          leanWhnfStart
          leanWhnfStop) ++
      " pskernel_cold_whnf_ns=" ++
      toString
        (psKernelBenchElapsed
          whnfColdStart
          whnfColdStop) ++
      " hits=" ++
      toString leanWhnfHits ++
      "/" ++
      toString whnfColdHits)
  IO.println
    ("PSKERNEL_BENCH official_lean_defeq_ns=" ++
      toString
        (psKernelBenchElapsed
          leanDefEqStart
          leanDefEqStop) ++
      " pskernel_cold_defeq_ns=" ++
      toString
        (psKernelBenchElapsed
          defeqColdStart
          defeqColdStop) ++
      " hits=" ++
      toString leanDefEqHits ++
      "/" ++
      toString defeqColdHits)

  let betaBinder :=
    PsKernelName.str
      PsKernelName.anonymous
      "benchBeta"
  let psBeta :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        betaBinder
        (PsKernelExpr.const psKernelNatName List.nil)
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      checkerExpected
  let leanBeta :=
    Lean.Expr.app
      (Lean.Expr.lam
        (Lean.Name.str Lean.Name.anonymous "benchBeta")
        (Lean.Expr.const psKernelBenchLeanNatName [])
        (Lean.Expr.bvar 0)
        Lean.BinderInfo.default)
      leanExpected

  let psEmptySession :=
    psKernelBenchFreshSession
      checkerEnvironment
  let psSort :=
    PsKernelExpr.sort PsKernelLevel.zero
  let leanSort :=
    Lean.Expr.sort Lean.Level.zero

  let betaPsStart ← IO.monoNanosNow
  let betaPsHits ←
    psKernelBenchWhnfColdLoop
      checkerIterations
      checkerEnvironment
      psBeta
  let betaPsStop ← IO.monoNanosNow

  let betaLeanStart ← IO.monoNanosNow
  let betaLeanHits ←
    psKernelBenchLeanWhnfLoop
      checkerIterations
      leanEnvironment
      leanBeta
  let betaLeanStop ← IO.monoNanosNow

  let structuralPsStart ← IO.monoNanosNow
  let structuralPsHits ←
    psKernelBenchDefEqColdLoop
      checkerIterations
      checkerEnvironment
      psSort
      psSort
  let structuralPsStop ← IO.monoNanosNow

  let structuralLeanStart ← IO.monoNanosNow
  let structuralLeanHits ←
    psKernelBenchLeanDefEqLoop
      checkerIterations
      leanEnvironment
      leanSort
      leanSort
  let structuralLeanStop ← IO.monoNanosNow

  let _ := psEmptySession

  IO.println
    ("PSKERNEL_BENCH beta_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          betaPsStart
          betaPsStop) ++
      " beta_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          betaLeanStart
          betaLeanStop) ++
      " hits=" ++
      toString betaPsHits ++
      "/" ++
      toString betaLeanHits)
  let applicationArity := 8
  let applicationEnvironment :=
    psKernelBenchApplicationEnvironment
      applicationArity
  let applicationExpr :=
    psKernelBenchApplyNatArgs
      applicationArity
      1
      (PsKernelExpr.const
        psKernelBenchAppName
        List.nil)
  let leanApplicationEnvironment ←
    psKernelBenchLeanApplicationEnvironment
      applicationArity
  let leanApplicationExpr :=
    psKernelBenchApplyLeanNatArgs
      applicationArity
      1
      (Lean.Expr.const
        psKernelBenchLeanAppName
        [])

  let applicationInferStart ← IO.monoNanosNow
  let applicationInferHits ←
    psKernelBenchInferColdLoop
      checkerIterations
      applicationEnvironment
      applicationExpr
  let applicationInferStop ← IO.monoNanosNow

  let applicationPsStart ← IO.monoNanosNow
  let applicationPsHits ←
    psKernelBenchCheckColdLoop
      checkerIterations
      applicationEnvironment
      applicationExpr
  let applicationPsStop ← IO.monoNanosNow

  let applicationLeanStart ← IO.monoNanosNow
  let applicationLeanHits ←
    psKernelBenchLeanCheckLoop
      checkerIterations
      leanApplicationEnvironment
      leanApplicationExpr
  let applicationLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH application_infer_only_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          applicationInferStart
          applicationInferStop) ++
      " arity=" ++
      toString applicationArity ++
      " hits=" ++
      toString applicationInferHits)

  IO.println
    ("PSKERNEL_BENCH application_check_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          applicationPsStart
          applicationPsStop) ++
      " application_check_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          applicationLeanStart
          applicationLeanStop) ++
      " arity=" ++
      toString applicationArity ++
      " hits=" ++
      toString applicationPsHits ++
      "/" ++
      toString applicationLeanHits)

  IO.println
    ("PSKERNEL_BENCH structural_defeq_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          structuralPsStart
          structuralPsStop) ++
      " structural_defeq_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          structuralLeanStart
          structuralLeanStop) ++
      " hits=" ++
      toString structuralPsHits ++
      "/" ++
      toString structuralLeanHits)

