import PsKernelSelfHostFoundationTests

#eval psKernelWhnfDifferentialCase
  (PsKernelExpr.app
    (PsKernelExpr.lam PsKernelName.anonymous
      (PsKernelExpr.sort PsKernelLevel.zero)
      (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default)
    (PsKernelExpr.lit (PsKernelLiteral.nat 42)))
#eval psKernelWhnfDifferentialCase
  (PsKernelExpr.letE PsKernelName.anonymous
    (PsKernelExpr.sort PsKernelLevel.zero)
    (PsKernelExpr.lit (PsKernelLiteral.nat 9))
    (PsKernelExpr.bvar 0)
    false)
#eval psKernelWhnfDifferentialCase
  (PsKernelExpr.app
    (PsKernelExpr.const psKernelNatSuccName List.nil)
    (PsKernelExpr.lit (PsKernelLiteral.nat 5)))
#eval psKernelWhnfDifferentialCase
  (PsKernelExpr.app
    (PsKernelExpr.app
      (PsKernelExpr.const psKernelNatAddName List.nil)
      (PsKernelExpr.lit (PsKernelLiteral.nat 4)))
    (PsKernelExpr.lit (PsKernelLiteral.nat 9)))
#eval psKernelWhnfLocalLetDifferential
#eval psKernelWhnfCacheTest
#eval psKernelWhnfFuelExhaustionTest