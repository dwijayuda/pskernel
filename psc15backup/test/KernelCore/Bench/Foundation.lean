import Lean
import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Admission.Inductive.Nested.Admission

set_option maxRecDepth 100000

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

