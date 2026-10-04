import Ps.KernelSelfHost.CheckerState
import Ps.KernelSelfHost.Environment

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

def psKernelBenchEnvironmentIndexedLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (target : PsKernelName) :
    Nat :=
  let rec go
      (remaining : Nat)
      (hits : Nat) :
      Nat :=
    match remaining with
    | Nat.zero =>
        hits
    | Nat.succ rest =>
        match
            psKernelEnvironmentFind
              environment
              target with
        | Option.some _ =>
            go rest (Nat.succ hits)
        | Option.none =>
            go rest hits
  go iterations 0

def psKernelBenchEnvironmentLinearLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment)
    (target : PsKernelName) :
    Nat :=
  let rec go
      (remaining : Nat)
      (hits : Nat) :
      Nat :=
    match remaining with
    | Nat.zero =>
        hits
    | Nat.succ rest =>
        match
            psKernelFindConstantInList
              target
              environment.constants with
        | Option.some _ =>
            go rest (Nat.succ hits)
        | Option.none =>
            go rest hits
  go iterations 0

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

def psKernelBenchCacheIndexedLoop
    (iterations : Nat)
    (cache : PsKernelExprMap)
    (target : PsKernelExpr) :
    Nat :=
  let rec go
      (remaining : Nat)
      (hits : Nat) :
      Nat :=
    match remaining with
    | Nat.zero =>
        hits
    | Nat.succ rest =>
        match psKernelExprMapGet cache target with
        | Option.some _ =>
            go rest (Nat.succ hits)
        | Option.none =>
            go rest hits
  go iterations 0

def psKernelBenchCacheLinearLoop
    (iterations : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (target : PsKernelExpr) :
    Nat :=
  let rec go
      (remaining : Nat)
      (hits : Nat) :
      Nat :=
    match remaining with
    | Nat.zero =>
        hits
    | Nat.succ rest =>
        match
            psKernelExprMapGetIn
              target
              entries with
        | Option.some _ =>
            go rest (Nat.succ hits)
        | Option.none =>
            go rest hits
  go iterations 0

def psKernelBenchElapsed
    (start stop : Nat) :
    Nat :=
  Nat.sub stop start

def main : IO Unit := do
  let size := 2048
  let iterations := 2000
  let environment :=
    psKernelBenchBuildEnvironment size
  let targetName :=
    psKernelBenchName 0

  let envIndexedStart ← IO.monoNanosNow
  let envIndexedHits :=
    psKernelBenchEnvironmentIndexedLoop
      iterations
      environment
      targetName
  let envIndexedStop ← IO.monoNanosNow

  let envLinearStart ← IO.monoNanosNow
  let envLinearHits :=
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
  let cacheIndexedHits :=
    psKernelBenchCacheIndexedLoop
      iterations
      cache
      targetExpr
  let cacheIndexedStop ← IO.monoNanosNow

  let cacheLinearStart ← IO.monoNanosNow
  let cacheLinearHits :=
    psKernelBenchCacheLinearLoop
      iterations
      entries
      targetExpr
  let cacheLinearStop ← IO.monoNanosNow

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
