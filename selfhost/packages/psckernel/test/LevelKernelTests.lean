import Ps.PSCKernel.Core.Level

structure PsCKernelLevelKernelNamedTest where
  name : String
  passed : Bool

def psCKernelLevelKernelNameU : PsCKernelName :=
  psCKernelNameFromDotted "u"

def psCKernelLevelKernelNameV : PsCKernelName :=
  psCKernelNameFromDotted "v"

def psCKernelLevelKernelNameW : PsCKernelName :=
  psCKernelNameFromDotted "w"

def psCKernelLevelKernelU : PsCKernelLevel :=
  psCKernelLevelParam psCKernelLevelKernelNameU

def psCKernelLevelKernelV : PsCKernelLevel :=
  psCKernelLevelParam psCKernelLevelKernelNameV

def psCKernelLevelKernelW : PsCKernelLevel :=
  psCKernelLevelParam psCKernelLevelKernelNameW

def psCKernelLevelKernelOne : PsCKernelLevel :=
  psCKernelLevelSucc psCKernelLevelZero

def psCKernelLevelKernelTestAtomicOffsetNormalize : Bool :=
  let input : PsCKernelLevel :=
    psCKernelLevelSucc
      (psCKernelLevelSucc psCKernelLevelKernelU)
  psCKernelLevelEqStructural
    (psCKernelNormalizeLevel input)
    input

def psCKernelLevelKernelTestMaxCanonicalAssociationOrder : Bool :=
  let left : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      (psCKernelLevelMaxRaw psCKernelLevelKernelV psCKernelLevelKernelU)
      psCKernelLevelKernelW
  let right : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      psCKernelLevelKernelW
      (psCKernelLevelMaxRaw psCKernelLevelKernelU psCKernelLevelKernelV)
  psCKernelLevelEqStructural
    (psCKernelNormalizeLevel left)
    (psCKernelNormalizeLevel right)

def psCKernelLevelKernelTestSameBaseGreatestOffset : Bool :=
  let u1 : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelKernelU
  let u2 : PsCKernelLevel := psCKernelLevelSucc u1
  psCKernelLevelEqStructural
    (psCKernelNormalizeLevel (psCKernelLevelMaxRaw u1 u2))
    u2

def psCKernelLevelKernelTestExplicitSubsumption : Bool :=
  let u1 : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelKernelU
  psCKernelLevelEqStructural
    (psCKernelNormalizeLevel
      (psCKernelLevelMaxRaw psCKernelLevelKernelOne u1))
    u1

def psCKernelLevelKernelTestIMaxStopsAfterSmartMax : Bool :=
  let u1 : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelKernelU
  let input : PsCKernelLevel :=
    psCKernelLevelIMaxRaw psCKernelLevelKernelV u1
  let expectedOnePass : PsCKernelLevel :=
    psCKernelLevelMaxRaw psCKernelLevelKernelV u1
  let result : PsCKernelLevel := psCKernelNormalizeLevel input
  psCKernelLevelEqStructural result expectedOnePass
    && !psCKernelLevelEqStructural
      result
      (psCKernelNormalizeLevel result)

def psCKernelLevelKernelTestMaxCommutativeEquivalent : Bool :=
  psCKernelLevelEquivalent
    (psCKernelLevelMaxRaw psCKernelLevelKernelU psCKernelLevelKernelV)
    (psCKernelLevelMaxRaw psCKernelLevelKernelV psCKernelLevelKernelU)

def psCKernelLevelKernelTestSymbolKindsRemainDistinct : Bool :=
  let u2 : PsCKernelLevel :=
    psCKernelLevelParam (psCKernelNameFromDotted "u2")
  let m1 : PsCKernelLevel :=
    psCKernelLevelMVar psCKernelLevelKernelNameU
  let m2 : PsCKernelLevel :=
    psCKernelLevelMVar (psCKernelNameFromDotted "m2")
  !psCKernelLevelEquivalent psCKernelLevelKernelU u2
    && !psCKernelLevelEquivalent m1 m2
    && !psCKernelLevelEquivalent psCKernelLevelKernelU m1

def psCKernelLevelKernelTestBasicLe : Bool :=
  let u1 : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelKernelU
  psCKernelLevelLe psCKernelLevelZero psCKernelLevelKernelU
    && psCKernelLevelLe psCKernelLevelKernelU psCKernelLevelKernelU
    && psCKernelLevelLe psCKernelLevelKernelU u1
    && !psCKernelLevelLe u1 psCKernelLevelKernelU

def psCKernelLevelKernelTestMaxLeShortcut : Bool :=
  let uv : PsCKernelLevel :=
    psCKernelLevelMaxRaw psCKernelLevelKernelU psCKernelLevelKernelV
  psCKernelLevelLe psCKernelLevelKernelU uv
    && psCKernelLevelLe psCKernelLevelKernelV uv

def psCKernelLevelKernelTestMaxGeqFallthrough : Bool :=
  psCKernelLevelLe
    (psCKernelLevelMkIMax psCKernelLevelKernelU psCKernelLevelKernelV)
    (psCKernelLevelMaxRaw psCKernelLevelKernelU psCKernelLevelKernelV)

def psCKernelLevelKernelTestIntentionalEquivalenceIncompleteness : Bool :=
  let left : PsCKernelLevel :=
    psCKernelLevelMkMax psCKernelLevelKernelV psCKernelLevelKernelU
  let right : PsCKernelLevel :=
    psCKernelLevelMkMax
      (psCKernelLevelMkIMax psCKernelLevelKernelU psCKernelLevelKernelV)
      psCKernelLevelKernelU
  !psCKernelLevelEquivalent left right
    && psCKernelLevelLe left right
    && psCKernelLevelLe right left

def psCKernelLevelKernelTests : List PsCKernelLevelKernelNamedTest := [
  { name := "atomic level offsets stay normalized", passed := psCKernelLevelKernelTestAtomicOffsetNormalize },
  { name := "max association and order canonicalize", passed := psCKernelLevelKernelTestMaxCanonicalAssociationOrder },
  { name := "same base keeps greatest offset", passed := psCKernelLevelKernelTestSameBaseGreatestOffset },
  { name := "explicit universe is subsumed", passed := psCKernelLevelKernelTestExplicitSubsumption },
  { name := "imax smart-max result is not normalized twice", passed := psCKernelLevelKernelTestIMaxStopsAfterSmartMax },
  { name := "max is equivalent modulo normalization", passed := psCKernelLevelKernelTestMaxCommutativeEquivalent },
  { name := "params and mvars remain distinct symbolic atoms", passed := psCKernelLevelKernelTestSymbolKindsRemainDistinct },
  { name := "basic levelLe offset behavior", passed := psCKernelLevelKernelTestBasicLe },
  { name := "max positive shortcut", passed := psCKernelLevelKernelTestMaxLeShortcut },
  { name := "max-geq falls through to imax rules", passed := psCKernelLevelKernelTestMaxGeqFallthrough },
  { name := "Lean kernel equivalence incompleteness", passed := psCKernelLevelKernelTestIntentionalEquivalenceIncompleteness }
]

def psCKernelRunLevelKernelTests
    (tests : List PsCKernelLevelKernelNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_LEVEL_KERNEL_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_LEVEL_KERNEL_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunLevelKernelTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunLevelKernelTests psCKernelLevelKernelTests
  if passed then
    IO.println "PSCKERNEL_LEVEL_KERNEL_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_LEVEL_KERNEL_TESTS: FAIL")
