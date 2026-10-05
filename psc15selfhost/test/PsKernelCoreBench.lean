import KernelCore.Bench.Nested

set_option maxRecDepth 100000

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
  let (psAdmissionBases, leanAdmissionBases) ← psKernelBenchAdmissionBases
  psKernelBenchAdmissionInputGuards psAdmissionBases leanAdmissionBases

  let admissionPsStart ← IO.monoNanosNow
  let admissionPsHits ←
    psKernelBenchInductiveAdmissionLoop
      admissionIterations
      psAdmissionBases
  let admissionPsStop ← IO.monoNanosNow

  let admissionLeanStart ← IO.monoNanosNow
  let admissionLeanHits ←
    psKernelBenchLeanInductiveAdmissionLoop
      admissionIterations
      leanAdmissionBases
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



  let indexedAdmissionIterations := 100

  let indexedAdmissionPsStart ← IO.monoNanosNow
  let indexedAdmissionPsHits ←
    psKernelBenchIndexedAdmissionLoop
      indexedAdmissionIterations
      psAdmissionBases
  let indexedAdmissionPsStop ← IO.monoNanosNow

  let indexedAdmissionLeanStart ← IO.monoNanosNow
  let indexedAdmissionLeanHits ←
    psKernelBenchLeanIndexedAdmissionLoop
      indexedAdmissionIterations
      leanAdmissionBases
  let indexedAdmissionLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH indexed_inductive_admission_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          indexedAdmissionPsStart
          indexedAdmissionPsStop) ++
      " indexed_inductive_admission_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          indexedAdmissionLeanStart
          indexedAdmissionLeanStop) ++
      " iterations=" ++
      toString indexedAdmissionIterations ++
      " hits=" ++
      toString indexedAdmissionPsHits ++
      "/" ++
      toString indexedAdmissionLeanHits)

  let mutualAdmissionIterations := 100

  let mutualAdmissionPsStart ← IO.monoNanosNow
  let mutualAdmissionPsHits ←
    psKernelBenchMutualAdmissionLoop
      mutualAdmissionIterations
      psAdmissionBases
  let mutualAdmissionPsStop ← IO.monoNanosNow

  let mutualAdmissionLeanStart ← IO.monoNanosNow
  let mutualAdmissionLeanHits ←
    psKernelBenchLeanMutualAdmissionLoop
      mutualAdmissionIterations
      leanAdmissionBases
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


  let nestedWideIterations := 50
  let nestedWidePsBase ←
    psKernelBenchNestedWideBaseEnvironment
  let nestedWideLeanBase ←
    psKernelBenchLeanNestedWideBaseEnvironment

  match
      psKernelAddSimpleNestedInductive
        65536
        nestedWidePsBase
        psKernelBenchNestedWideDecl
        0
        psKernelLeanNatMaxSizeDefault with
  | Except.ok _ =>
      IO.println
        "PSKERNEL_BENCH nested_wide_setup=ok"
  | Except.error error =>
      IO.println
        ("PSKERNEL_BENCH nested_wide_setup_error=" ++
          error)

  let nestedWideProcessed ←
    match
        psKernelBenchNestedWideProcess
          nestedWidePsBase with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH wide preprocessing failed: " ++
              error))

  let nestedWideTransformed ←
    match
        psKernelBenchNestedWideTransform
          nestedWidePsBase
          nestedWideProcessed with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH wide transform failed: " ++
              error))

  let nestedWideFinal ←
    match
        psKernelBenchNestedWideRestore
          nestedWidePsBase
          nestedWideTransformed
          nestedWideProcessed with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH wide restore failed: " ++
              error))

  match
      psKernelSimpleNestedValidateTemplates
        65536
        nestedWideFinal
        psKernelBenchNestedWideDecl.levelParams
        PsKernelDefinitionSafety.safe
        List.nil
        0
        psKernelLeanNatMaxSizeDefault
        nestedWideProcessed.state.aux with
  | Except.ok _ =>
      IO.println
        "PSKERNEL_BENCH nested_wide_validate_templates=ok"
  | Except.error error =>
      IO.println
        ("PSKERNEL_BENCH nested_wide_validate_templates_error=" ++
          error)

  match
      psKernelSimpleNestedValidateOriginals
        65536
        nestedWideFinal
        psKernelBenchNestedWideDecl
        PsKernelDefinitionSafety.safe
        0
        psKernelLeanNatMaxSizeDefault
        psKernelBenchNestedWideDecl.types with
  | Except.ok _ =>
      IO.println
        "PSKERNEL_BENCH nested_wide_validate_originals=ok"
  | Except.error error =>
      IO.println
        ("PSKERNEL_BENCH nested_wide_validate_originals_error=" ++
          error)

  match
      psKernelSimpleNestedValidateAux
        65536
        nestedWideTransformed
        nestedWideFinal
        psKernelBenchNestedWideDecl
        PsKernelDefinitionSafety.safe
        List.nil
        0
        psKernelLeanNatMaxSizeDefault
        nestedWideProcessed.state.aux
        (psKernelBenchNestedWideRenames
          nestedWideProcessed)
        nestedWideProcessed.state.aux with
  | Except.ok _ =>
      IO.println
        "PSKERNEL_BENCH nested_wide_validate_aux=ok"
  | Except.error error =>
      IO.println
        ("PSKERNEL_BENCH nested_wide_validate_aux_error=" ++
          error)

  let nestedWidePsStart ← IO.monoNanosNow
  let nestedWidePsHits ←
    psKernelBenchNestedWideAdmissionLoop
      nestedWideIterations
      nestedWidePsBase
  let nestedWidePsStop ← IO.monoNanosNow

  let nestedWideLeanStart ← IO.monoNanosNow
  let nestedWideLeanHits ←
    psKernelBenchLeanNestedWideAdmissionLoop
      nestedWideIterations
      nestedWideLeanBase
  let nestedWideLeanStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_wide_admission_pskernel_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWidePsStart
          nestedWidePsStop) ++
      " nested_wide_admission_lean_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideLeanStart
          nestedWideLeanStop) ++
      " iterations=" ++
      toString nestedWideIterations ++
      " hits=" ++
      toString nestedWidePsHits ++
      "/" ++
      toString nestedWideLeanHits)


  let nestedWidePreprocessStart ← IO.monoNanosNow
  let nestedWidePreprocessHits ←
    psKernelBenchNestedWidePreprocessLoop
      nestedWideIterations
      nestedWidePsBase
  let nestedWidePreprocessStop ← IO.monoNanosNow

  let nestedWideTransformStart ← IO.monoNanosNow
  let nestedWideTransformHits ←
    psKernelBenchNestedWideTransformLoop
      nestedWideIterations
      nestedWidePsBase
      nestedWideProcessed
  let nestedWideTransformStop ← IO.monoNanosNow

  let nestedWideRestoreStart ← IO.monoNanosNow
  let nestedWideRestoreHits ←
    psKernelBenchNestedWideRestoreLoop
      nestedWideIterations
      nestedWidePsBase
      nestedWideTransformed
      nestedWideProcessed
  let nestedWideRestoreStop ← IO.monoNanosNow

  let nestedWideValidateStart ← IO.monoNanosNow
  let nestedWideValidateHits ←
    psKernelBenchNestedWideValidateLoop
      nestedWideIterations
      nestedWideTransformed
      nestedWideFinal
      nestedWideProcessed
  let nestedWideValidateStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_wide_stage_preprocess_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWidePreprocessStart
          nestedWidePreprocessStop) ++
      " nested_wide_stage_transform_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideTransformStart
          nestedWideTransformStop) ++
      " nested_wide_stage_restore_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideRestoreStart
          nestedWideRestoreStop) ++
      " nested_wide_stage_validate_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideValidateStart
          nestedWideValidateStop) ++
      " iterations=" ++
      toString nestedWideIterations ++
      " hits=" ++
      toString nestedWidePreprocessHits ++
      "/" ++
      toString nestedWideTransformHits ++
      "/" ++
      toString nestedWideRestoreHits ++
      "/" ++
      toString nestedWideValidateHits)

  let nestedWideValidateTemplatesStart ← IO.monoNanosNow
  let nestedWideValidateTemplatesHits ←
    psKernelBenchNestedWideValidateTemplatesLoop
      nestedWideIterations
      nestedWideFinal
      nestedWideProcessed
  let nestedWideValidateTemplatesStop ← IO.monoNanosNow

  let nestedWideValidateOriginalsStart ← IO.monoNanosNow
  let nestedWideValidateOriginalsHits ←
    psKernelBenchNestedWideValidateOriginalsLoop
      nestedWideIterations
      nestedWideFinal
  let nestedWideValidateOriginalsStop ← IO.monoNanosNow

  let nestedWideValidateAuxStart ← IO.monoNanosNow
  let nestedWideValidateAuxHits ←
    psKernelBenchNestedWideValidateAuxLoop
      nestedWideIterations
      nestedWideTransformed
      nestedWideFinal
      nestedWideProcessed
  let nestedWideValidateAuxStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_wide_validate_templates_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideValidateTemplatesStart
          nestedWideValidateTemplatesStop) ++
      " nested_wide_validate_originals_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideValidateOriginalsStart
          nestedWideValidateOriginalsStop) ++
      " nested_wide_validate_aux_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideValidateAuxStart
          nestedWideValidateAuxStop) ++
      " iterations=" ++
      toString nestedWideIterations ++
      " hits=" ++
      toString nestedWideValidateTemplatesHits ++
      "/" ++
      toString nestedWideValidateOriginalsHits ++
      "/" ++
      toString nestedWideValidateAuxHits)

  let nestedWideMainRulesCurrentStart ← IO.monoNanosNow
  let nestedWideMainRulesCurrentHits ←
    psKernelBenchNestedWideMainRulesCurrentLoop
      nestedWideIterations
      nestedWideFinal
  let nestedWideMainRulesCurrentStop ← IO.monoNanosNow

  let nestedWideMainRulesThreadedStart ← IO.monoNanosNow
  let nestedWideMainRulesThreadedHits ←
    psKernelBenchNestedWideMainRulesThreadedLoop
      nestedWideIterations
      nestedWideFinal
  let nestedWideMainRulesThreadedStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_wide_main_rules_current_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideMainRulesCurrentStart
          nestedWideMainRulesCurrentStop) ++
      " nested_wide_main_rules_threaded_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedWideMainRulesThreadedStart
          nestedWideMainRulesThreadedStop) ++
      " iterations=" ++
      toString nestedWideIterations ++
      " hits=" ++
      toString nestedWideMainRulesCurrentHits ++
      "/" ++
      toString nestedWideMainRulesThreadedHits)

  let nestedProcessed ←
    match
        psKernelBenchNestedProcess
          nestedAdmissionPsBase with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH nested preprocessing setup failed: " ++
              error))

  let nestedTransformed ←
    match
        psKernelBenchNestedTransform
          nestedAdmissionPsBase
          nestedProcessed with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH nested transformed setup failed: " ++
              error))

  let nestedFinal ←
    match
        psKernelBenchNestedRestore
          nestedAdmissionPsBase
          nestedTransformed
          nestedProcessed with
    | Except.ok value =>
        pure value
    | Except.error error =>
        throw
          (IO.userError
            ("PSKERNEL_BENCH nested restore setup failed: " ++
              error))

  match
      psKernelBenchNestedValidate
        nestedTransformed
        nestedFinal
        nestedProcessed with
  | Except.ok _ =>
      pure ()
  | Except.error error =>
      throw
        (IO.userError
          ("PSKERNEL_BENCH nested validation setup failed: " ++
            error))

  let nestedPreprocessStart ← IO.monoNanosNow
  let nestedPreprocessHits ←
    psKernelBenchNestedPreprocessLoop
      nestedAdmissionIterations
      nestedAdmissionPsBase
  let nestedPreprocessStop ← IO.monoNanosNow

  let nestedTransformStart ← IO.monoNanosNow
  let nestedTransformHits ←
    psKernelBenchNestedTransformLoop
      nestedAdmissionIterations
      nestedAdmissionPsBase
      nestedProcessed
  let nestedTransformStop ← IO.monoNanosNow

  let nestedRestoreStart ← IO.monoNanosNow
  let nestedRestoreHits ←
    psKernelBenchNestedRestoreLoop
      nestedAdmissionIterations
      nestedAdmissionPsBase
      nestedTransformed
      nestedProcessed
  let nestedRestoreStop ← IO.monoNanosNow

  let nestedValidateStart ← IO.monoNanosNow
  let nestedValidateHits ←
    psKernelBenchNestedValidateLoop
      nestedAdmissionIterations
      nestedTransformed
      nestedFinal
      nestedProcessed
  let nestedValidateStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_stage_preprocess_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedPreprocessStart
          nestedPreprocessStop) ++
      " nested_stage_transform_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedTransformStart
          nestedTransformStop) ++
      " nested_stage_restore_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedRestoreStart
          nestedRestoreStop) ++
      " nested_stage_validate_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateStart
          nestedValidateStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedPreprocessHits ++
      "/" ++
      toString nestedTransformHits ++
      "/" ++
      toString nestedRestoreHits ++
      "/" ++
      toString nestedValidateHits)


  let nestedValidateTemplatesStart ← IO.monoNanosNow
  let nestedValidateTemplatesHits ←
    psKernelBenchNestedValidateTemplatesLoop
      nestedAdmissionIterations
      nestedFinal
      nestedProcessed
  let nestedValidateTemplatesStop ← IO.monoNanosNow

  let nestedValidateOriginalsStart ← IO.monoNanosNow
  let nestedValidateOriginalsHits ←
    psKernelBenchNestedValidateOriginalsLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedValidateOriginalsStop ← IO.monoNanosNow

  let nestedValidateAuxStart ← IO.monoNanosNow
  let nestedValidateAuxHits ←
    psKernelBenchNestedValidateAuxLoop
      nestedAdmissionIterations
      nestedTransformed
      nestedFinal
      nestedProcessed
  let nestedValidateAuxStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_validate_templates_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateTemplatesStart
          nestedValidateTemplatesStop) ++
      " nested_validate_originals_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateOriginalsStart
          nestedValidateOriginalsStop) ++
      " nested_validate_aux_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateAuxStart
          nestedValidateAuxStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedValidateTemplatesHits ++
      "/" ++
      toString nestedValidateOriginalsHits ++
      "/" ++
      toString nestedValidateAuxHits)


  let nestedValidateOriginalConstructorsStart ← IO.monoNanosNow
  let nestedValidateOriginalConstructorsHits ←
    psKernelBenchNestedValidateOriginalConstructorsLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedValidateOriginalConstructorsStop ← IO.monoNanosNow

  let nestedValidateOriginalRecursorStart ← IO.monoNanosNow
  let nestedValidateOriginalRecursorHits ←
    psKernelBenchNestedValidateOriginalRecursorLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedValidateOriginalRecursorStop ← IO.monoNanosNow

  let nestedValidateAuxRulesStart ← IO.monoNanosNow
  let nestedValidateAuxRulesHits ←
    psKernelBenchNestedValidateAuxRulesLoop
      nestedAdmissionIterations
      nestedTransformed
      nestedFinal
      nestedProcessed
  let nestedValidateAuxRulesStop ← IO.monoNanosNow

  let nestedValidateAuxRecursorStart ← IO.monoNanosNow
  let nestedValidateAuxRecursorHits ←
    psKernelBenchNestedValidateAuxRecursorLoop
      nestedAdmissionIterations
      nestedFinal
      nestedProcessed
  let nestedValidateAuxRecursorStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_validate_original_ctors_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateOriginalConstructorsStart
          nestedValidateOriginalConstructorsStop) ++
      " nested_validate_original_recursor_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateOriginalRecursorStart
          nestedValidateOriginalRecursorStop) ++
      " nested_validate_aux_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateAuxRulesStart
          nestedValidateAuxRulesStop) ++
      " nested_validate_aux_recursor_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedValidateAuxRecursorStart
          nestedValidateAuxRecursorStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedValidateOriginalConstructorsHits ++
      "/" ++
      toString nestedValidateOriginalRecursorHits ++
      "/" ++
      toString nestedValidateAuxRulesHits ++
      "/" ++
      toString nestedValidateAuxRecursorHits)


  let nestedOriginalRecursorTypeStart ← IO.monoNanosNow
  let nestedOriginalRecursorTypeHits ←
    psKernelBenchNestedValidateOriginalRecursorTypeLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedOriginalRecursorTypeStop ← IO.monoNanosNow

  let nestedOriginalRulesStart ← IO.monoNanosNow
  let nestedOriginalRulesHits ←
    psKernelBenchNestedValidateOriginalRulesLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedOriginalRulesStop ← IO.monoNanosNow

  let nestedAuxOldRulesStart ← IO.monoNanosNow
  let nestedAuxOldRulesHits ←
    psKernelBenchNestedValidateAuxOldRulesLoop
      nestedAdmissionIterations
      nestedTransformed
      nestedProcessed
  let nestedAuxOldRulesStop ← IO.monoNanosNow

  let nestedAuxNewRulesStart ← IO.monoNanosNow
  let nestedAuxNewRulesHits ←
    psKernelBenchNestedValidateAuxNewRulesLoop
      nestedAdmissionIterations
      nestedFinal
      nestedProcessed
  let nestedAuxNewRulesStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_original_rec_type_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedOriginalRecursorTypeStart
          nestedOriginalRecursorTypeStop) ++
      " nested_original_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedOriginalRulesStart
          nestedOriginalRulesStop) ++
      " nested_aux_old_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedAuxOldRulesStart
          nestedAuxOldRulesStop) ++
      " nested_aux_new_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedAuxNewRulesStart
          nestedAuxNewRulesStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedOriginalRecursorTypeHits ++
      "/" ++
      toString nestedOriginalRulesHits ++
      "/" ++
      toString nestedAuxOldRulesHits ++
      "/" ++
      toString nestedAuxNewRulesHits)

  let nestedInferOriginalRulesStart ← IO.monoNanosNow
  let nestedInferOriginalRulesHits ←
    psKernelBenchNestedInferOriginalRulesLoop
      nestedAdmissionIterations
      nestedFinal
  let nestedInferOriginalRulesStop ← IO.monoNanosNow

  let nestedInferAuxOldRulesStart ← IO.monoNanosNow
  let nestedInferAuxOldRulesHits ←
    psKernelBenchNestedInferAuxOldRulesLoop
      nestedAdmissionIterations
      nestedTransformed
      nestedProcessed
  let nestedInferAuxOldRulesStop ← IO.monoNanosNow

  let nestedInferAuxNewRulesStart ← IO.monoNanosNow
  let nestedInferAuxNewRulesHits ←
    psKernelBenchNestedInferAuxNewRulesLoop
      nestedAdmissionIterations
      nestedFinal
      nestedProcessed
  let nestedInferAuxNewRulesStop ← IO.monoNanosNow

  IO.println
    ("PSKERNEL_BENCH nested_infer_original_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedInferOriginalRulesStart
          nestedInferOriginalRulesStop) ++
      " nested_infer_aux_old_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedInferAuxOldRulesStart
          nestedInferAuxOldRulesStop) ++
      " nested_infer_aux_new_rules_ns=" ++
      toString
        (psKernelBenchElapsed
          nestedInferAuxNewRulesStart
          nestedInferAuxNewRulesStop) ++
      " iterations=" ++
      toString nestedAdmissionIterations ++
      " hits=" ++
      toString nestedInferOriginalRulesHits ++
      "/" ++
      toString nestedInferAuxOldRulesHits ++
      "/" ++
      toString nestedInferAuxNewRulesHits)

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

  psKernelBenchProfileRecursorCache "nested_main_rules" nestedFinal psKernelBenchNestedTreeRecName
  psKernelBenchProfileRecursorCache "nested_wide_main_rules" nestedWideFinal psKernelBenchNestedWideRecName
