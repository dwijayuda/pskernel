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

