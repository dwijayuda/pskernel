import Ps.PSCKernel.Core.Level

structure PsCKernelLevelNamedTest where
  name : String
  passed : Bool

def psCKernelLevelTestNameU : PsCKernelName :=
  psCKernelNameFromDotted "u"

def psCKernelLevelTestNameV : PsCKernelName :=
  psCKernelNameFromDotted "v"

def psCKernelLevelTestNameM : PsCKernelName :=
  psCKernelNameFromDotted "m"

def psCKernelLevelTestU : PsCKernelLevel :=
  psCKernelLevelParam psCKernelLevelTestNameU

def psCKernelLevelTestV : PsCKernelLevel :=
  psCKernelLevelParam psCKernelLevelTestNameV

def psCKernelLevelTestM : PsCKernelLevel :=
  psCKernelLevelMVar psCKernelLevelTestNameM

def psCKernelLevelTestOne : PsCKernelLevel :=
  psCKernelLevelSucc psCKernelLevelZero

def psCKernelLevelTestTwo : PsCKernelLevel :=
  psCKernelLevelSucc psCKernelLevelTestOne

def psCKernelLevelTestConstructors : Bool :=
  let z : PsCKernelLevel := psCKernelLevelZero
  let s : PsCKernelLevel := psCKernelLevelSucc z
  let mx : PsCKernelLevel := psCKernelLevelMaxRaw z s
  let imx : PsCKernelLevel := psCKernelLevelIMaxRaw z s
  let p : PsCKernelLevel := psCKernelLevelParam psCKernelLevelTestNameU
  let m : PsCKernelLevel := psCKernelLevelMVar psCKernelLevelTestNameM
  match z, s, mx, imx, p, m with
  | PsCKernelLevel.zero,
    PsCKernelLevel.succ _,
    PsCKernelLevel.max _ _,
    PsCKernelLevel.imax _ _,
    PsCKernelLevel.param _,
    PsCKernelLevel.mvar _ => true
  | _, _, _, _, _, _ => false

def psCKernelLevelTestFreshStructuralEquality : Bool :=
  let left : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      (psCKernelLevelSucc (psCKernelLevelParam psCKernelLevelTestNameU))
      (psCKernelLevelMVar psCKernelLevelTestNameM)
  let right : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      (psCKernelLevelSucc (psCKernelLevelParam psCKernelLevelTestNameU))
      (psCKernelLevelMVar psCKernelLevelTestNameM)
  psCKernelLevelEqStructural left right

def psCKernelLevelTestParamMVarDistinct : Bool :=
  !psCKernelLevelEqStructural
    (psCKernelLevelParam psCKernelLevelTestNameU)
    (psCKernelLevelMVar psCKernelLevelTestNameU)

def psCKernelLevelTestRawShapes : Bool :=
  let rawMax : PsCKernelLevel :=
    psCKernelLevelMaxRaw psCKernelLevelZero psCKernelLevelZero
  let rawIMax : PsCKernelLevel :=
    psCKernelLevelIMaxRaw psCKernelLevelZero psCKernelLevelZero
  let maxIsRaw : Bool :=
    match rawMax with
    | PsCKernelLevel.max _ _ => true
    | _ => false
  let imaxIsRaw : Bool :=
    match rawIMax with
    | PsCKernelLevel.imax _ _ => true
    | _ => false
  maxIsRaw && imaxIsRaw

def psCKernelLevelTestHasMVar : Bool :=
  let nested : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      psCKernelLevelTestU
      (psCKernelLevelIMaxRaw psCKernelLevelTestV psCKernelLevelTestM)
  psCKernelLevelHasMVar nested
    && !psCKernelLevelHasMVar
      (psCKernelLevelMaxRaw psCKernelLevelTestU psCKernelLevelTestV)

def psCKernelLevelTestParamNames : Bool :=
  let nested : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      psCKernelLevelTestU
      (psCKernelLevelMaxRaw psCKernelLevelTestV psCKernelLevelTestU)
  match psCKernelLevelParamNames nested with
  | [first, second] =>
      psCKernelNameEq first psCKernelLevelTestNameU
        && psCKernelNameEq second psCKernelLevelTestNameV
  | _ => false

def psCKernelLevelTestZeroPredicates : Bool :=
  psCKernelLevelIsZero psCKernelLevelZero
    && !psCKernelLevelIsZero psCKernelLevelTestU
    && psCKernelLevelIsNotZero psCKernelLevelTestOne
    && !psCKernelLevelIsNotZero psCKernelLevelTestU
    && psCKernelLevelNormalizesToZero
      (psCKernelLevelIMaxRaw psCKernelLevelTestU psCKernelLevelZero)
    && psCKernelLevelIsNotZero
      (psCKernelLevelIMaxRaw psCKernelLevelTestU psCKernelLevelTestOne)

def psCKernelLevelTestMkMax : Bool :=
  let u1 : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelTestU
  let u2 : PsCKernelLevel := psCKernelLevelSucc u1
  let uv : PsCKernelLevel :=
    psCKernelLevelMkMax psCKernelLevelTestU psCKernelLevelTestV
  psCKernelLevelEqStructural
      (psCKernelLevelMkMax psCKernelLevelZero psCKernelLevelTestU)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax psCKernelLevelTestU psCKernelLevelZero)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax psCKernelLevelTestU psCKernelLevelTestU)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax u1 u2)
      u2
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax psCKernelLevelTestOne psCKernelLevelTestTwo)
      psCKernelLevelTestTwo
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax psCKernelLevelTestU uv)
      uv
    && psCKernelLevelEqStructural
      (psCKernelLevelMkMax uv psCKernelLevelTestU)
      uv

def psCKernelLevelTestMkIMax : Bool :=
  psCKernelLevelEqStructural
      (psCKernelLevelMkIMax psCKernelLevelTestU psCKernelLevelZero)
      psCKernelLevelZero
    && psCKernelLevelEqStructural
      (psCKernelLevelMkIMax psCKernelLevelZero psCKernelLevelTestU)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkIMax psCKernelLevelTestOne psCKernelLevelTestU)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkIMax psCKernelLevelTestU psCKernelLevelTestU)
      psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelMkIMax psCKernelLevelTestU psCKernelLevelTestOne)
      (psCKernelLevelMkMax psCKernelLevelTestU psCKernelLevelTestOne)

def psCKernelLevelTestOffsets : Bool :=
  let level : PsCKernelLevel :=
    psCKernelLevelSucc
      (psCKernelLevelSucc psCKernelLevelTestU)
  let offset : PsCKernelLevelOffset := psCKernelLevelToOffset level
  Nat.beq offset.offset 2
    && psCKernelLevelEqStructural offset.base psCKernelLevelTestU
    && psCKernelLevelEqStructural
      (psCKernelLevelAddOffset offset.base offset.offset)
      level

def psCKernelLevelTestInstantiatePreservesRaw : Bool :=
  let rawMax : PsCKernelLevel :=
    psCKernelLevelMaxRaw psCKernelLevelZero psCKernelLevelZero
  let rawIMax : PsCKernelLevel :=
    psCKernelLevelIMaxRaw psCKernelLevelTestV psCKernelLevelZero
  let noParams : PsCKernelLevel :=
    psCKernelInstantiateLevel rawMax [] []
  let unmatched : PsCKernelLevel :=
    psCKernelInstantiateLevel
      rawIMax
      [psCKernelLevelTestNameU]
      [psCKernelLevelZero]
  let noParamsRaw : Bool :=
    match noParams with
    | PsCKernelLevel.max _ _ => true
    | _ => false
  let unmatchedRaw : Bool :=
    match unmatched with
    | PsCKernelLevel.imax _ _ => true
    | _ => false
  noParamsRaw
    && unmatchedRaw
    && psCKernelLevelEqStructural noParams rawMax
    && psCKernelLevelEqStructural unmatched rawIMax

def psCKernelLevelTestInstantiateChangedBranch : Bool :=
  let rawMax : PsCKernelLevel :=
    psCKernelLevelMaxRaw psCKernelLevelTestU psCKernelLevelZero
  let collapsed : PsCKernelLevel :=
    psCKernelInstantiateLevel
      rawMax
      [psCKernelLevelTestNameU]
      [psCKernelLevelZero]
  let nested : PsCKernelLevel :=
    psCKernelLevelIMaxRaw
      (psCKernelLevelSucc psCKernelLevelTestU)
      psCKernelLevelTestV
  let nestedResult : PsCKernelLevel :=
    psCKernelInstantiateLevel
      nested
      [psCKernelLevelTestNameU]
      [psCKernelLevelZero]
  psCKernelLevelEqStructural collapsed psCKernelLevelZero
    && psCKernelLevelEqStructural nestedResult psCKernelLevelTestV

def psCKernelLevelTestToString : Bool :=
  psCKernelStringEq
      (psCKernelLevelToString psCKernelLevelZero)
      "0"
    && psCKernelStringEq
      (psCKernelLevelToString (psCKernelLevelSucc psCKernelLevelTestU))
      "(u+1)"
    && psCKernelStringEq
      (psCKernelLevelToString
        (psCKernelLevelMaxRaw psCKernelLevelTestU psCKernelLevelTestV))
      "max u v"
    && psCKernelStringEq
      (psCKernelLevelToString
        (psCKernelLevelIMaxRaw psCKernelLevelTestU psCKernelLevelTestV))
      "imax u v"
    && psCKernelStringEq
      (psCKernelLevelToString psCKernelLevelTestM)
      "?m"

def psCKernelLevelBasicTests : List PsCKernelLevelNamedTest := [
  { name := "six constructors", passed := psCKernelLevelTestConstructors },
  { name := "fresh structural equality", passed := psCKernelLevelTestFreshStructuralEquality },
  { name := "param and mvar remain distinct", passed := psCKernelLevelTestParamMVarDistinct },
  { name := "raw max and imax shapes", passed := psCKernelLevelTestRawShapes },
  { name := "nested metavariable traversal", passed := psCKernelLevelTestHasMVar },
  { name := "unique parameter name order", passed := psCKernelLevelTestParamNames },
  { name := "zero predicates", passed := psCKernelLevelTestZeroPredicates },
  { name := "mkMax simplifications", passed := psCKernelLevelTestMkMax },
  { name := "mkIMax simplifications", passed := psCKernelLevelTestMkIMax },
  { name := "offset round trip", passed := psCKernelLevelTestOffsets },
  { name := "instantiation preserves raw shape when unchanged", passed := psCKernelLevelTestInstantiatePreservesRaw },
  { name := "instantiation smart-rebuilds changed branches", passed := psCKernelLevelTestInstantiateChangedBranch },
  { name := "TypeScript-facing levelToString", passed := psCKernelLevelTestToString }
]

def psCKernelRunLevelBasicTests : List PsCKernelLevelNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_LEVEL_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_LEVEL_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunLevelBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunLevelBasicTests psCKernelLevelBasicTests
  if passed then
    IO.println "PSCKERNEL_LEVEL_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_LEVEL_BASIC_TESTS: FAIL")
