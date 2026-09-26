import Ps.PSCKernel.Core.Name

def psCKernelFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelFixtureEmit (key : String) (value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def main : IO Unit := do
  let anonymousName : PsCKernelName := psCKernelAnonymous
  let a : PsCKernelName := psCKernelNameFromDotted "A"
  let ab : PsCKernelName := psCKernelNameFromDotted "A.B"
  let ab3 : PsCKernelName := psCKernelNumName ab 3
  let x : PsCKernelName := psCKernelNameFromDotted "X"
  let z : PsCKernelName := psCKernelNameFromDotted "Z"
  let appendBase : PsCKernelName := psCKernelNumName a 2
  let appendSuffix : PsCKernelName :=
    psCKernelNumName (psCKernelNameFromDotted "B") 3
  let freshLeft : PsCKernelName :=
    psCKernelStrName
      (psCKernelStrName psCKernelAnonymous "A")
      "B"
  let freshRight : PsCKernelName :=
    psCKernelStrName
      (psCKernelStrName psCKernelAnonymous "A")
      "B"
  let numeral : PsCKernelName := psCKernelNumName a 1
  let text : PsCKernelName := psCKernelStrName a "x"
  let bmpText : String := String.singleton (Char.ofNat 57344)
  let astralText : String := String.singleton (Char.ofNat 65536)
  let bmp : PsCKernelName := psCKernelStrName a bmpText
  let astral : PsCKernelName := psCKernelStrName a astralText

  psCKernelFixtureEmit
    "fromDotted.empty.key"
    (psCKernelNameKey (psCKernelNameFromDotted ""))
  psCKernelFixtureEmit
    "fromDotted.dotted.toString"
    (psCKernelNameToString (psCKernelNameFromDotted "A..B"))
  psCKernelFixtureEmit
    "appendAfter.toString"
    (psCKernelNameToString (psCKernelNameAppendAfter ab "_x"))
  psCKernelFixtureEmit
    "appendIndexAfter.toString"
    (psCKernelNameToString (psCKernelNameAppendIndexAfter ab 7))
  psCKernelFixtureEmit
    "prefix.true"
    (psCKernelFixtureBoolText (psCKernelNameIsPrefixOf a ab3))
  psCKernelFixtureEmit
    "append.key"
    (psCKernelNameKey (psCKernelNameAppend appendBase appendSuffix))
  psCKernelFixtureEmit
    "replace.match.key"
    (psCKernelNameKey (psCKernelNameReplacePrefix ab3 a x))
  psCKernelFixtureEmit
    "fresh.eq"
    (psCKernelFixtureBoolText (psCKernelNameEq freshLeft freshRight))
  psCKernelFixtureEmit
    "fresh.key"
    (psCKernelNameKey freshLeft)
  psCKernelFixtureEmit
    "cmp.numString"
    (toString (psCKernelNameCmp numeral text))
  psCKernelFixtureEmit
    "cmp.unicode"
    (toString (psCKernelNameCmp bmp astral))
  psCKernelFixtureEmit
    "unicode.key"
    (psCKernelNameKey astral)
  psCKernelFixtureEmit
    "anonymous.toString"
    (psCKernelNameToString anonymousName)
  psCKernelFixtureEmit
    "replace.miss.key"
    (psCKernelNameKey (psCKernelNameReplacePrefix ab3 z x))
