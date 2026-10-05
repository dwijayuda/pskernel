import KernelCore.Bench.Foundation

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

