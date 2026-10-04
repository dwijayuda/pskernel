import Lean
import Ps.KernelSelfHost.CheckerSession
import Ps.KernelSelfHost.InductiveAdmission
import Ps.KernelSelfHost.MutualInductive
import Ps.KernelSelfHost.NestedInductive

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

def psKernelBenchDepFamilyName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchDepFamily"

def psKernelBenchDepAppName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchDepApply"

def psKernelBenchLeanDepFamilyName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchDepFamily"

def psKernelBenchLeanDepAppName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchDepApply"

def psKernelBenchDependentResult
    (arity : Nat) :
    PsKernelExpr :=
  PsKernelExpr.app
    (PsKernelExpr.const
      psKernelBenchDepFamilyName
      List.nil)
    (PsKernelExpr.bvar
      (Nat.sub arity 1))

def psKernelBenchDependentArrowType
    (arity : Nat) :
    PsKernelExpr :=
  let result :=
    psKernelBenchDependentResult arity;
  let rec wrap
      (remaining : Nat) :
      PsKernelExpr :=
    match remaining with
    | Nat.zero =>
        result
    | Nat.succ rest =>
        PsKernelExpr.forallE
          PsKernelName.anonymous
          psKernelBenchNatType
          (wrap rest)
          PsKernelBinderInfo.default;
  wrap arity

def psKernelBenchLeanDependentResult
    (arity : Nat) :
    Lean.Expr :=
  Lean.Expr.app
    (Lean.Expr.const
      psKernelBenchLeanDepFamilyName
      [])
    (Lean.Expr.bvar
      (Nat.sub arity 1))

def psKernelBenchLeanDependentArrowType
    (arity : Nat) :
    Lean.Expr :=
  let result :=
    psKernelBenchLeanDependentResult arity;
  let rec wrap
      (remaining : Nat) :
      Lean.Expr :=
    match remaining with
    | Nat.zero =>
        result
    | Nat.succ rest =>
        Lean.Expr.forallE
          Lean.Name.anonymous
          psKernelBenchLeanNatType
          (wrap rest)
          Lean.BinderInfo.default;
  wrap arity

def psKernelBenchDependentApplicationEnvironment
    (arity : Nat) :
    PsKernelEnvironment :=
  let familyType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      psKernelBenchNatType
      (PsKernelExpr.sort PsKernelLevel.zero)
      PsKernelBinderInfo.default;
  let environment1 :=
    psKernelEnvironmentAddUnchecked
      psKernelBenchCheckerEnvironment
      (PsKernelConstantInfo.axiomInfo {
        base := {
          name := psKernelBenchDepFamilyName
          levelParams := List.nil
          type := familyType
        }
        isUnsafe := false
      });
  psKernelEnvironmentAddUnchecked
    environment1
    (PsKernelConstantInfo.axiomInfo {
      base := {
        name := psKernelBenchDepAppName
        levelParams := List.nil
        type :=
          psKernelBenchDependentArrowType
            arity
      }
      isUnsafe := false
    })

def psKernelBenchLeanDependentApplicationEnvironment
    (arity : Nat) :
    IO Lean.Environment := do
  let environment ←
    psKernelBenchLeanEnvironment
  let familyType :=
    Lean.Expr.forallE
      Lean.Name.anonymous
      psKernelBenchLeanNatType
      (Lean.Expr.sort Lean.Level.zero)
      Lean.BinderInfo.default
  let withFamily ←
    match
        Lean.Kernel.Environment.addDecl
          environment.toKernelEnv
          {}
          (.axiomDecl {
            name := psKernelBenchLeanDepFamilyName
            levelParams := []
            type := familyType
            isUnsafe := false
          }) with
    | .ok next =>
        pure next
    | .error _ =>
        throw
          (IO.userError
            "PSKERNEL_BENCH failed to create dependent family fixture")
  match
      Lean.Kernel.Environment.addDecl
        withFamily
        {}
        (.axiomDecl {
          name := psKernelBenchLeanDepAppName
          levelParams := []
          type :=
            psKernelBenchLeanDependentArrowType
              arity
          isUnsafe := false
        }) with
  | .ok next =>
      pure
        (Lean.Environment.ofKernelEnv next)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create dependent application fixture")

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

partial def psKernelBenchCheckWarmLoop
    (iterations : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr) :
    IO (Prod Nat PsKernelCheckerSession) :=
  match iterations with
  | Nat.zero =>
      pure (Prod.mk 0 session)
  | Nat.succ rest =>
      match
          psKernelSessionCheck
            2048
            session
            expr with
      | Except.error _ =>
          psKernelBenchCheckWarmLoop
            rest
            session
            expr
      | Except.ok result => do
          let tail ←
            psKernelBenchCheckWarmLoop
              rest
              (Prod.snd result)
              expr
          pure
            (Prod.mk
              (Nat.succ (Prod.fst tail))
              (Prod.snd tail))

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

def psKernelBenchRecName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchRec"

def psKernelBenchRecZeroName : PsKernelName :=
  PsKernelName.str
    psKernelBenchRecName
    "zero"

def psKernelBenchRecSuccName : PsKernelName :=
  PsKernelName.str
    psKernelBenchRecName
    "succ"

def psKernelBenchRecRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchRecName

def psKernelBenchRecExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchRecName
    List.nil

def psKernelBenchRecDecl : PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchRecName
    type :=
      PsKernelExpr.sort
        (PsKernelLevel.succ PsKernelLevel.zero)
    ctors :=
      List.cons
        {
          name := psKernelBenchRecZeroName
          type := psKernelBenchRecExpr
        }
        (List.cons
          {
            name := psKernelBenchRecSuccName
            type :=
              PsKernelExpr.forallE
                PsKernelName.anonymous
                psKernelBenchRecExpr
                psKernelBenchRecExpr
                PsKernelBinderInfo.default
          }
          List.nil)
    isUnsafe := false
    numParams := 0
  }

def psKernelBenchRecEnvironment :
    Except String PsKernelEnvironment :=
  psKernelAddSimpleInductive
    65536
    psKernelEnvironmentEmpty
    psKernelBenchRecDecl
    0
    psKernelLeanNatMaxSizeDefault

def psKernelBenchRecMotive : PsKernelExpr :=
  PsKernelExpr.lam
    PsKernelName.anonymous
    psKernelBenchRecExpr
    psKernelBenchRecExpr
    PsKernelBinderInfo.default

def psKernelBenchRecStep : PsKernelExpr :=
  PsKernelExpr.lam
    PsKernelName.anonymous
    psKernelBenchRecExpr
    (PsKernelExpr.lam
      PsKernelName.anonymous
      psKernelBenchRecExpr
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default)
    PsKernelBinderInfo.default

def psKernelBenchRecMajor : PsKernelExpr :=
  PsKernelExpr.app
    (PsKernelExpr.const
      psKernelBenchRecSuccName
      List.nil)
    (PsKernelExpr.app
      (PsKernelExpr.const
        psKernelBenchRecSuccName
        List.nil)
      (PsKernelExpr.const
        psKernelBenchRecZeroName
        List.nil))

def psKernelBenchRecInput : PsKernelExpr :=
  psKernelApplyArgs
    (PsKernelExpr.const
      psKernelBenchRecRecName
      (List.cons
        (PsKernelLevel.succ PsKernelLevel.zero)
        List.nil))
    (List.cons
      psKernelBenchRecMotive
      (List.cons
        (PsKernelExpr.const
          psKernelBenchRecZeroName
          List.nil)
        (List.cons
          psKernelBenchRecStep
          (List.cons
            psKernelBenchRecMajor
            List.nil))))

def psKernelBenchLeanRecName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchRec"

def psKernelBenchLeanRecZeroName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "zero"

def psKernelBenchLeanRecSuccName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "succ"

def psKernelBenchLeanRecRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanRecName
    "rec"

def psKernelBenchLeanRecExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanRecName
    []

def psKernelBenchLeanRecDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [{
      name := psKernelBenchLeanRecName
      type :=
        Lean.Expr.sort
          (Lean.Level.succ Lean.Level.zero)
      ctors := [
        {
          name := psKernelBenchLeanRecZeroName
          type := psKernelBenchLeanRecExpr
        },
        {
          name := psKernelBenchLeanRecSuccName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanRecExpr
              psKernelBenchLeanRecExpr
              Lean.BinderInfo.default
        }
      ]
    }]
    false


def psKernelBenchMutualEvenName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchMutualEven"

def psKernelBenchMutualOddName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchMutualOdd"

def psKernelBenchMutualEvenZeroName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualEvenName
    "zero"

def psKernelBenchMutualEvenStepName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualEvenName
    "step"

def psKernelBenchMutualOddStepName : PsKernelName :=
  PsKernelName.str
    psKernelBenchMutualOddName
    "step"

def psKernelBenchMutualEvenRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchMutualEvenName

def psKernelBenchMutualOddRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchMutualOddName

def psKernelBenchMutualEvenExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchMutualEvenName
    List.nil

def psKernelBenchMutualOddExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchMutualOddName
    List.nil

def psKernelBenchMutualDecl :
    PsKernelSimpleMutualInductiveDecl :=
  {
    levelParams := List.nil
    numParams := 0
    types :=
      List.cons
        {
          name := psKernelBenchMutualEvenName
          type :=
            PsKernelExpr.sort
              (PsKernelLevel.succ
                PsKernelLevel.zero)
          ctors :=
            List.cons
              {
                name := psKernelBenchMutualEvenZeroName
                type := psKernelBenchMutualEvenExpr
              }
              (List.cons
                {
                  name := psKernelBenchMutualEvenStepName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchMutualOddExpr
                      psKernelBenchMutualEvenExpr
                      PsKernelBinderInfo.default
                }
                List.nil)
        }
        (List.cons
          {
            name := psKernelBenchMutualOddName
            type :=
              PsKernelExpr.sort
                (PsKernelLevel.succ
                  PsKernelLevel.zero)
            ctors :=
              List.cons
                {
                  name := psKernelBenchMutualOddStepName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchMutualEvenExpr
                      psKernelBenchMutualOddExpr
                      PsKernelBinderInfo.default
                }
                List.nil
          }
          List.nil)
    isUnsafe := false
  }

def psKernelBenchLeanMutualEvenName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchMutualEven"

def psKernelBenchLeanMutualOddName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchMutualOdd"

def psKernelBenchLeanMutualEvenZeroName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "zero"

def psKernelBenchLeanMutualEvenStepName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "step"

def psKernelBenchLeanMutualOddStepName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualOddName
    "step"

def psKernelBenchLeanMutualEvenRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualEvenName
    "rec"

def psKernelBenchLeanMutualOddRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanMutualOddName
    "rec"

def psKernelBenchLeanMutualEvenExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanMutualEvenName
    []

def psKernelBenchLeanMutualOddExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanMutualOddName
    []

def psKernelBenchLeanMutualDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [
      {
        name := psKernelBenchLeanMutualEvenName
        type :=
          Lean.Expr.sort
            (Lean.Level.succ Lean.Level.zero)
        ctors := [
          {
            name := psKernelBenchLeanMutualEvenZeroName
            type := psKernelBenchLeanMutualEvenExpr
          },
          {
            name := psKernelBenchLeanMutualEvenStepName
            type :=
              Lean.Expr.forallE
                Lean.Name.anonymous
                psKernelBenchLeanMutualOddExpr
                psKernelBenchLeanMutualEvenExpr
                Lean.BinderInfo.default
          }
        ]
      },
      {
        name := psKernelBenchLeanMutualOddName
        type :=
          Lean.Expr.sort
            (Lean.Level.succ Lean.Level.zero)
        ctors := [
          {
            name := psKernelBenchLeanMutualOddStepName
            type :=
              Lean.Expr.forallE
                Lean.Name.anonymous
                psKernelBenchLeanMutualEvenExpr
                psKernelBenchLeanMutualOddExpr
                Lean.BinderInfo.default
          }
        ]
      }
    ]
    false


def psKernelBenchNestedBoxName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedBox"

def psKernelBenchNestedBoxMkName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedBoxName
    "mk"

def psKernelBenchNestedTreeName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "BenchNestedTree"

def psKernelBenchNestedTreeLeafName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedTreeName
    "leaf"

def psKernelBenchNestedTreeNodeName : PsKernelName :=
  PsKernelName.str
    psKernelBenchNestedTreeName
    "node"

def psKernelBenchNestedTreeRecName : PsKernelName :=
  psKernelSimpleRecName
    psKernelBenchNestedTreeName

def psKernelBenchNestedType1 : PsKernelExpr :=
  PsKernelExpr.sort
    (PsKernelLevel.succ PsKernelLevel.zero)

def psKernelBenchNestedBoxExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedBoxName
    List.nil

def psKernelBenchNestedTreeExpr : PsKernelExpr :=
  PsKernelExpr.const
    psKernelBenchNestedTreeName
    List.nil

def psKernelBenchNestedBoxTreeExpr : PsKernelExpr :=
  PsKernelExpr.app
    psKernelBenchNestedBoxExpr
    psKernelBenchNestedTreeExpr

def psKernelBenchNestedBoxDecl :
    PsKernelSimpleInductiveDecl :=
  {
    levelParams := List.nil
    name := psKernelBenchNestedBoxName
    type :=
      PsKernelExpr.forallE
        PsKernelName.anonymous
        psKernelBenchNestedType1
        psKernelBenchNestedType1
        PsKernelBinderInfo.default
    ctors :=
      List.cons
        {
          name := psKernelBenchNestedBoxMkName
          type :=
            PsKernelExpr.forallE
              PsKernelName.anonymous
              psKernelBenchNestedType1
              (PsKernelExpr.forallE
                PsKernelName.anonymous
                (PsKernelExpr.bvar 0)
                (PsKernelExpr.app
                  psKernelBenchNestedBoxExpr
                  (PsKernelExpr.bvar 1))
                PsKernelBinderInfo.default)
              PsKernelBinderInfo.default
        }
        List.nil
    isUnsafe := false
    numParams := 1
  }

def psKernelBenchNestedDecl :
    PsKernelSimpleMutualInductiveDecl :=
  {
    levelParams := List.nil
    numParams := 0
    types :=
      List.cons
        {
          name := psKernelBenchNestedTreeName
          type := psKernelBenchNestedType1
          ctors :=
            List.cons
              {
                name := psKernelBenchNestedTreeLeafName
                type := psKernelBenchNestedTreeExpr
              }
              (List.cons
                {
                  name := psKernelBenchNestedTreeNodeName
                  type :=
                    PsKernelExpr.forallE
                      PsKernelName.anonymous
                      psKernelBenchNestedBoxTreeExpr
                      psKernelBenchNestedTreeExpr
                      PsKernelBinderInfo.default
                }
                List.nil)
        }
        List.nil
    isUnsafe := false
  }

def psKernelBenchNestedBaseEnvironment :
    IO PsKernelEnvironment := do
  match
      psKernelAddSimpleInductive
        65536
        psKernelEnvironmentEmpty
        psKernelBenchNestedBoxDecl
        0
        psKernelLeanNatMaxSizeDefault with
  | Except.ok environment =>
      pure environment
  | Except.error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create nested-inductive base fixture")

def psKernelBenchLeanNestedBoxName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedBox"

def psKernelBenchLeanNestedBoxMkName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedBoxName
    "mk"

def psKernelBenchLeanNestedTreeName : Lean.Name :=
  Lean.Name.str
    Lean.Name.anonymous
    "BenchNestedTree"

def psKernelBenchLeanNestedTreeLeafName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "leaf"

def psKernelBenchLeanNestedTreeNodeName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "node"

def psKernelBenchLeanNestedTreeRecName : Lean.Name :=
  Lean.Name.str
    psKernelBenchLeanNestedTreeName
    "rec"

def psKernelBenchLeanNestedType1 : Lean.Expr :=
  Lean.Expr.sort
    (Lean.Level.succ Lean.Level.zero)

def psKernelBenchLeanNestedBoxExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedBoxName
    []

def psKernelBenchLeanNestedTreeExpr : Lean.Expr :=
  Lean.Expr.const
    psKernelBenchLeanNestedTreeName
    []

def psKernelBenchLeanNestedBoxTreeExpr : Lean.Expr :=
  Lean.Expr.app
    psKernelBenchLeanNestedBoxExpr
    psKernelBenchLeanNestedTreeExpr

def psKernelBenchLeanNestedBoxDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    1
    [{
      name := psKernelBenchLeanNestedBoxName
      type :=
        Lean.Expr.forallE
          Lean.Name.anonymous
          psKernelBenchLeanNestedType1
          psKernelBenchLeanNestedType1
          Lean.BinderInfo.default
      ctors := [{
        name := psKernelBenchLeanNestedBoxMkName
        type :=
          Lean.Expr.forallE
            Lean.Name.anonymous
            psKernelBenchLeanNestedType1
            (Lean.Expr.forallE
              Lean.Name.anonymous
              (Lean.Expr.bvar 0)
              (Lean.Expr.app
                psKernelBenchLeanNestedBoxExpr
                (Lean.Expr.bvar 1))
              Lean.BinderInfo.default)
            Lean.BinderInfo.default
      }]
    }]
    false

def psKernelBenchLeanNestedDecl : Lean.Declaration :=
  Lean.Declaration.inductDecl
    []
    0
    [{
      name := psKernelBenchLeanNestedTreeName
      type := psKernelBenchLeanNestedType1
      ctors := [
        {
          name := psKernelBenchLeanNestedTreeLeafName
          type := psKernelBenchLeanNestedTreeExpr
        },
        {
          name := psKernelBenchLeanNestedTreeNodeName
          type :=
            Lean.Expr.forallE
              Lean.Name.anonymous
              psKernelBenchLeanNestedBoxTreeExpr
              psKernelBenchLeanNestedTreeExpr
              Lean.BinderInfo.default
        }
      ]
    }]
    false

def psKernelBenchLeanNestedBaseEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  match
      Lean.Kernel.Environment.addDecl
        base
        {}
        psKernelBenchLeanNestedBoxDecl with
  | .ok environment =>
      pure
        (Lean.Environment.ofKernelEnv environment)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create Lean nested-inductive base fixture")

def psKernelBenchLeanRecEnvironment :
    IO Lean.Environment := do
  let base :=
    (← Lean.mkEmptyEnvironment).toKernelEnv
  match
      Lean.Kernel.Environment.addDecl
        base
        {}
        psKernelBenchLeanRecDecl with
  | .ok environment =>
      pure
        (Lean.Environment.ofKernelEnv environment)
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH failed to create recursive inductive fixture")

def psKernelBenchLeanRecMotive : Lean.Expr :=
  Lean.Expr.lam
    Lean.Name.anonymous
    psKernelBenchLeanRecExpr
    psKernelBenchLeanRecExpr
    Lean.BinderInfo.default

def psKernelBenchLeanRecStep : Lean.Expr :=
  Lean.Expr.lam
    Lean.Name.anonymous
    psKernelBenchLeanRecExpr
    (Lean.Expr.lam
      Lean.Name.anonymous
      psKernelBenchLeanRecExpr
      (Lean.Expr.bvar 0)
      Lean.BinderInfo.default)
    Lean.BinderInfo.default

def psKernelBenchLeanRecMajor : Lean.Expr :=
  Lean.Expr.app
    (Lean.Expr.const
      psKernelBenchLeanRecSuccName
      [])
    (Lean.Expr.app
      (Lean.Expr.const
        psKernelBenchLeanRecSuccName
        [])
      (Lean.Expr.const
        psKernelBenchLeanRecZeroName
        []))

def psKernelBenchLeanRecInput : Lean.Expr :=
  Lean.mkAppN
    (Lean.Expr.const
      psKernelBenchLeanRecRecName
      [Lean.Level.succ Lean.Level.zero])
    #[
      psKernelBenchLeanRecMotive,
      Lean.Expr.const psKernelBenchLeanRecZeroName [],
      psKernelBenchLeanRecStep,
      psKernelBenchLeanRecMajor
    ]

partial def psKernelBenchInductiveAdmissionLoop
    (iterations : Nat) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchInductiveAdmissionLoop rest
      match
          psKernelAddSimpleInductive
            65536
            psKernelEnvironmentEmpty
            psKernelBenchRecDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          if
              psKernelEnvironmentContains
                environment
                psKernelBenchRecRecName then
            pure (Nat.succ tail)
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanInductiveAdmissionLoop
    (iterations : Nat)
    (environment : Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanInductiveAdmissionLoop
          rest
          environment
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanRecDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanRecRecName with
          | some (.recInfo _) =>
              pure (Nat.succ tail)
          | _ =>
              pure tail
      | .error _ =>
          pure tail


partial def psKernelBenchMutualAdmissionLoop
    (iterations : Nat) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchMutualAdmissionLoop rest
      match
          psKernelAddSimpleMutualInductive
            65536
            psKernelEnvironmentEmpty
            psKernelBenchMutualDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok environment =>
          if
              psKernelEnvironmentContains
                environment
                psKernelBenchMutualEvenRecName then
            if
                psKernelEnvironmentContains
                  environment
                  psKernelBenchMutualOddRecName then
              pure (Nat.succ tail)
            else
              pure tail
          else
            pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanMutualAdmissionLoop
    (iterations : Nat)
    (environment : Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanMutualAdmissionLoop
          rest
          environment
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanMutualDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanMutualEvenRecName,
              next.find?
                psKernelBenchLeanMutualOddRecName with
          | some (.recInfo _), some (.recInfo _) =>
              pure (Nat.succ tail)
          | _, _ =>
              pure tail
      | .error _ =>
          pure tail


partial def psKernelBenchNestedAdmissionLoop
    (iterations : Nat)
    (environment : PsKernelEnvironment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchNestedAdmissionLoop
          rest
          environment
      match
          psKernelAddSimpleNestedInductive
            65536
            environment
            psKernelBenchNestedDecl
            0
            psKernelLeanNatMaxSizeDefault with
      | Except.ok next =>
          match
              psKernelEnvironmentFind
                next
                psKernelBenchNestedTreeName with
          | Option.some
              (PsKernelConstantInfo.inductInfo _) =>
              if
                  psKernelEnvironmentContains
                    next
                    psKernelBenchNestedTreeRecName then
                pure (Nat.succ tail)
              else
                pure tail
          | _ =>
              pure tail
      | Except.error _ =>
          pure tail

partial def psKernelBenchLeanNestedAdmissionLoop
    (iterations : Nat)
    (environment : Lean.Environment) :
    IO Nat :=
  match iterations with
  | Nat.zero =>
      pure 0
  | Nat.succ rest => do
      let tail ←
        psKernelBenchLeanNestedAdmissionLoop
          rest
          environment
      match
          Lean.Kernel.Environment.addDecl
            environment.toKernelEnv
            {}
            psKernelBenchLeanNestedDecl with
      | .ok next =>
          match
              next.find?
                psKernelBenchLeanNestedTreeName,
              next.find?
                psKernelBenchLeanNestedTreeRecName with
          | some (.inductInfo _), some (.recInfo _) =>
              pure (Nat.succ tail)
          | _, _ =>
              pure tail
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

  let applicationWarmSeed :=
    psKernelSessionCheck
      2048
      (psKernelBenchFreshSession
        applicationEnvironment)
      applicationExpr
  let applicationWarmSession :=
    match applicationWarmSeed with
    | Except.ok result =>
        Prod.snd result
    | Except.error _ =>
        psKernelBenchFreshSession
          applicationEnvironment
  let applicationWarmStart ← IO.monoNanosNow
  let applicationWarmResult ←
    psKernelBenchCheckWarmLoop
      checkerIterations
      applicationWarmSession
      applicationExpr
  let applicationWarmStop ← IO.monoNanosNow

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
      " application_check_warm_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          applicationWarmStart
          applicationWarmStop) ++
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
      toString (Prod.fst applicationWarmResult) ++
      "/" ++
      toString applicationLeanHits)

  let dependentEnvironment :=
    psKernelBenchDependentApplicationEnvironment
      applicationArity
  let dependentExpr :=
    psKernelBenchApplyNatArgs
      applicationArity
      1
      (PsKernelExpr.const
        psKernelBenchDepAppName
        List.nil)
  let leanDependentEnvironment ←
    psKernelBenchLeanDependentApplicationEnvironment
      applicationArity
  let leanDependentExpr :=
    psKernelBenchApplyLeanNatArgs
      applicationArity
      1
      (Lean.Expr.const
        psKernelBenchLeanDepAppName
        [])

  let dependentPsStart ← IO.monoNanosNow
  let dependentPsHits ←
    psKernelBenchCheckColdLoop
      checkerIterations
      dependentEnvironment
      dependentExpr
  let dependentPsStop ← IO.monoNanosNow

  let dependentLeanStart ← IO.monoNanosNow
  let dependentLeanHits ←
    psKernelBenchLeanCheckLoop
      checkerIterations
      leanDependentEnvironment
      leanDependentExpr
  let dependentLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH dependent_application_check_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          dependentPsStart
          dependentPsStop) ++
      " dependent_application_check_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          dependentLeanStart
          dependentLeanStop) ++
      " arity=" ++
      toString applicationArity ++
      " hits=" ++
      toString dependentPsHits ++
      "/" ++
      toString dependentLeanHits)

  let recEnvironment ←
    match psKernelBenchRecEnvironment with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH recursive PSKernel fixture failed: " ++ error))
  let leanRecEnvironment ←
    psKernelBenchLeanRecEnvironment

  match
      psKernelSessionWhnf
        4096
        (psKernelBenchFreshSession recEnvironment)
        psKernelBenchRecInput with
  | Except.ok result =>
      if
          psKernelExprEq
            (Prod.fst result)
            (PsKernelExpr.const
              psKernelBenchRecZeroName
              List.nil) then
        pure ()
      else
        throw
          (IO.userError
            "PSKERNEL_BENCH PSKernel recursor fixture did not reduce to zero")
  | Except.error error =>
      throw
        (IO.userError
          ("PSKERNEL_BENCH PSKernel recursor reduction failed: " ++ error))

  match
      Lean.Kernel.whnf
        leanRecEnvironment
        ({} : Lean.LocalContext)
        psKernelBenchLeanRecInput with
  | .ok result =>
      if
          result ==
            Lean.Expr.const
              psKernelBenchLeanRecZeroName
              [] then
        pure ()
      else
        throw
          (IO.userError
            "PSKERNEL_BENCH Lean recursor fixture did not reduce to zero")
  | .error _ =>
      throw
        (IO.userError
          "PSKERNEL_BENCH Lean recursor reduction failed")

  let recursorPsStart ← IO.monoNanosNow
  let recursorPsHits ←
    psKernelBenchWhnfColdLoop
      checkerIterations
      recEnvironment
      psKernelBenchRecInput
  let recursorPsStop ← IO.monoNanosNow

  let recursorLeanStart ← IO.monoNanosNow
  let recursorLeanHits ←
    psKernelBenchLeanWhnfLoop
      checkerIterations
      leanRecEnvironment
      psKernelBenchLeanRecInput
  let recursorLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH recursor_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          recursorPsStart
          recursorPsStop) ++
      " recursor_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          recursorLeanStart
          recursorLeanStop) ++
      " hits=" ++
      toString recursorPsHits ++
      "/" ++
      toString recursorLeanHits)

  let admissionIterations := 100
  let leanAdmissionBase ←
    Lean.mkEmptyEnvironment

  let admissionPsStart ← IO.monoNanosNow
  let admissionPsHits ←
    psKernelBenchInductiveAdmissionLoop
      admissionIterations
  let admissionPsStop ← IO.monoNanosNow

  let admissionLeanStart ← IO.monoNanosNow
  let admissionLeanHits ←
    psKernelBenchLeanInductiveAdmissionLoop
      admissionIterations
      leanAdmissionBase
  let admissionLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH inductive_admission_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          admissionPsStart
          admissionPsStop) ++
      " inductive_admission_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          admissionLeanStart
          admissionLeanStop) ++
      " iterations=" ++
      toString admissionIterations ++
      " hits=" ++
      toString admissionPsHits ++
      "/" ++
      toString admissionLeanHits)


  let mutualAdmissionIterations := 100

  let mutualAdmissionPsStart ← IO.monoNanosNow
  let mutualAdmissionPsHits ←
    psKernelBenchMutualAdmissionLoop
      mutualAdmissionIterations
  let mutualAdmissionPsStop ← IO.monoNanosNow

  let mutualAdmissionLeanStart ← IO.monoNanosNow
  let mutualAdmissionLeanHits ←
    psKernelBenchLeanMutualAdmissionLoop
      mutualAdmissionIterations
      leanAdmissionBase
  let mutualAdmissionLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH mutual_inductive_admission_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          mutualAdmissionPsStart
          mutualAdmissionPsStop) ++
      " mutual_inductive_admission_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          mutualAdmissionLeanStart
          mutualAdmissionLeanStop) ++
      " iterations=" ++
      toString mutualAdmissionIterations ++
      " hits=" ++
      toString mutualAdmissionPsHits ++
      "/" ++
      toString mutualAdmissionLeanHits)


  let nestedAdmissionIterations := 100
  let nestedAdmissionPsBase ←
    psKernelBenchNestedBaseEnvironment
  let nestedAdmissionLeanBase ←
    psKernelBenchLeanNestedBaseEnvironment

  let nestedAdmissionPsStart ← IO.monoNanosNow
  let nestedAdmissionPsHits ←
    psKernelBenchNestedAdmissionLoop
      nestedAdmissionIterations
      nestedAdmissionPsBase
  let nestedAdmissionPsStop ← IO.monoNanosNow

  let nestedAdmissionLeanStart ← IO.monoNanosNow
  let nestedAdmissionLeanHits ←
    psKernelBenchLeanNestedAdmissionLoop
      nestedAdmissionIterations
      nestedAdmissionLeanBase
  let nestedAdmissionLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_inductive_admission_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedAdmissionPsStart
          nestedAdmissionPsStop) ++
      " nested_inductive_admission_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedAdmissionLeanStart
          nestedAdmissionLeanStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedAdmissionPsHits ++
      "/" ++
      toString nestedAdmissionLeanHits)

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

