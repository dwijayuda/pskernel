import Ps.PSCKernel.Core.Name

structure PsCKernelNameNamedTest where
  name : String
  passed : Bool

def psCKernelTestNameA : PsCKernelName :=
  psCKernelStrName psCKernelAnonymous "A"

def psCKernelTestNameB : PsCKernelName :=
  psCKernelStrName psCKernelTestNameA "B"

def psCKernelTestNameAB3 : PsCKernelName :=
  psCKernelNumName psCKernelTestNameB 3

def psCKernelTestNameX : PsCKernelName :=
  psCKernelStrName psCKernelAnonymous "X"

def psCKernelTestNameZ : PsCKernelName :=
  psCKernelStrName psCKernelAnonymous "Z"

def psCKernelTestAnonymousDisplay : Bool :=
  psCKernelNameToString psCKernelAnonymous == "[anonymous]"

def psCKernelTestFromDottedEmpty : Bool :=
  psCKernelNameEq (psCKernelNameFromDotted "") psCKernelAnonymous

def psCKernelTestFromDottedUnderscore : Bool :=
  psCKernelNameEq (psCKernelNameFromDotted "_") psCKernelAnonymous

def psCKernelTestFromDottedFiltersEmpty : Bool :=
  psCKernelNameToString (psCKernelNameFromDotted "A..B") == "A.B"

def psCKernelTestAppendAfter : Bool :=
  psCKernelNameToString
    (psCKernelNameAppendAfter psCKernelTestNameB "_x") == "A.B_x"

def psCKernelTestAppendIndexAfter : Bool :=
  psCKernelNameToString
    (psCKernelNameAppendIndexAfter psCKernelTestNameB 7) == "A.B_7"

def psCKernelTestPrefix : Bool :=
  psCKernelNameIsPrefixOf psCKernelTestNameA psCKernelTestNameAB3

def psCKernelTestStructuralAppend : Bool :=
  let base : PsCKernelName := psCKernelNumName psCKernelTestNameA 2
  let suffix : PsCKernelName :=
    psCKernelNumName
      (psCKernelStrName psCKernelAnonymous "B")
      3
  let expected : PsCKernelName :=
    psCKernelNumName
      (psCKernelStrName base "B")
      3
  psCKernelNameEq (psCKernelNameAppend base suffix) expected

def psCKernelTestReplacePrefix : Bool :=
  let expected : PsCKernelName :=
    psCKernelNumName
      (psCKernelStrName psCKernelTestNameX "B")
      3
  psCKernelNameEq
    (psCKernelNameReplacePrefix
      psCKernelTestNameAB3
      psCKernelTestNameA
      psCKernelTestNameX)
    expected

def psCKernelTestReplaceMissingPrefixKeepsName : Bool :=
  psCKernelNameEq
    (psCKernelNameReplacePrefix
      psCKernelTestNameAB3
      psCKernelTestNameZ
      psCKernelTestNameX)
    psCKernelTestNameAB3

def psCKernelTestFreshEqualityAndKey : Bool :=
  let left : PsCKernelName :=
    psCKernelStrName
      (psCKernelStrName psCKernelAnonymous "A")
      "B"
  let right : PsCKernelName :=
    psCKernelStrName
      (psCKernelStrName psCKernelAnonymous "A")
      "B"
  psCKernelNameEq left right
    && psCKernelNameKey left == psCKernelNameKey right

def psCKernelTestNumeralBeforeString : Bool :=
  let numeral : PsCKernelName := psCKernelNumName psCKernelTestNameA 1
  let text : PsCKernelName := psCKernelStrName psCKernelTestNameA "x"
  psCKernelNameCmp numeral text == -1

def psCKernelTestUnicodeScalarOrdering : Bool :=
  let bmp : PsCKernelName := psCKernelStrName psCKernelTestNameA "\u{E000}"
  let astral : PsCKernelName := psCKernelStrName psCKernelTestNameA "\u{10000}"
  psCKernelNameCmp bmp astral == -1

def psCKernelNameTests : List PsCKernelNameNamedTest := [
  { name := "anonymous display", passed := psCKernelTestAnonymousDisplay },
  { name := "fromDotted empty", passed := psCKernelTestFromDottedEmpty },
  { name := "fromDotted underscore", passed := psCKernelTestFromDottedUnderscore },
  { name := "fromDotted filters empty components", passed := psCKernelTestFromDottedFiltersEmpty },
  { name := "appendAfter", passed := psCKernelTestAppendAfter },
  { name := "appendIndexAfter", passed := psCKernelTestAppendIndexAfter },
  { name := "prefix", passed := psCKernelTestPrefix },
  { name := "structural append", passed := psCKernelTestStructuralAppend },
  { name := "replace prefix", passed := psCKernelTestReplacePrefix },
  { name := "missing prefix keeps name", passed := psCKernelTestReplaceMissingPrefixKeepsName },
  { name := "fresh equality and key", passed := psCKernelTestFreshEqualityAndKey },
  { name := "numeral before string", passed := psCKernelTestNumeralBeforeString },
  { name := "Unicode scalar ordering", passed := psCKernelTestUnicodeScalarOrdering }
]

def psCKernelRunNameTests : List PsCKernelNameNamedTest -> IO Bool
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_NAME_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_NAME_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunNameTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunNameTests psCKernelNameTests
  if passed then
    IO.println "PSCKERNEL_NAME_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_NAME_TESTS: FAIL")
