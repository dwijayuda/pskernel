import Ps.PSCKernel.Core.Level

def psCKernelLevelFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelLevelFixtureEmit (key : String) (value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def main : IO Unit := do
  let uName : PsCKernelName := psCKernelNameFromDotted "u"
  let vName : PsCKernelName := psCKernelNameFromDotted "v"
  let wName : PsCKernelName := psCKernelNameFromDotted "w"
  let u : PsCKernelLevel := psCKernelLevelParam uName
  let v : PsCKernelLevel := psCKernelLevelParam vName
  let w : PsCKernelLevel := psCKernelLevelParam wName
  let mU : PsCKernelLevel := psCKernelLevelMVar uName
  let one : PsCKernelLevel := psCKernelLevelSucc psCKernelLevelZero
  let u1 : PsCKernelLevel := psCKernelLevelSucc u
  let u2 : PsCKernelLevel := psCKernelLevelSucc u1
  let v1 : PsCKernelLevel := psCKernelLevelSucc v
  let canonicalInput : PsCKernelLevel :=
    psCKernelLevelMaxRaw
      (psCKernelLevelMaxRaw v u)
      w
  let imaxInput : PsCKernelLevel := psCKernelLevelIMaxRaw v u1
  let incompleteLeft : PsCKernelLevel := psCKernelLevelMkMax v u
  let incompleteRight : PsCKernelLevel :=
    psCKernelLevelMkMax
      (psCKernelLevelMkIMax u v)
      u

  psCKernelLevelFixtureEmit
    "smart.max.zero"
    (psCKernelLevelToString (psCKernelLevelMkMax psCKernelLevelZero u))
  psCKernelLevelFixtureEmit
    "smart.max.sameBase"
    (psCKernelLevelToString (psCKernelLevelMkMax u1 u2))
  psCKernelLevelFixtureEmit
    "smart.imax.nonzero"
    (psCKernelLevelToString (psCKernelLevelMkIMax u v1))
  psCKernelLevelFixtureEmit
    "instantiate.changed"
    (psCKernelLevelToString
      (psCKernelInstantiateLevel
        (psCKernelLevelMaxRaw u v)
        [uName]
        [psCKernelLevelZero]))
  psCKernelLevelFixtureEmit
    "normalize.atomic"
    (psCKernelLevelToString
      (psCKernelNormalizeLevel (psCKernelLevelSucc u1)))
  psCKernelLevelFixtureEmit
    "normalize.maxCanonical"
    (psCKernelLevelToString (psCKernelNormalizeLevel canonicalInput))
  psCKernelLevelFixtureEmit
    "normalize.sameBase"
    (psCKernelLevelToString
      (psCKernelNormalizeLevel (psCKernelLevelMaxRaw u1 u2)))
  psCKernelLevelFixtureEmit
    "normalize.explicit"
    (psCKernelLevelToString
      (psCKernelNormalizeLevel (psCKernelLevelMaxRaw one u1)))
  psCKernelLevelFixtureEmit
    "normalize.imaxOnePass"
    (psCKernelLevelToString (psCKernelNormalizeLevel imaxInput))
  psCKernelLevelFixtureEmit
    "normalize.imaxTwice"
    (psCKernelLevelToString
      (psCKernelNormalizeLevel (psCKernelNormalizeLevel imaxInput)))
  psCKernelLevelFixtureEmit
    "equivalent.maxCommutative"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelEquivalent
        (psCKernelLevelMaxRaw u v)
        (psCKernelLevelMaxRaw v u)))
  psCKernelLevelFixtureEmit
    "equivalent.symbolKinds"
    (psCKernelLevelFixtureBoolText (psCKernelLevelEquivalent u mU))
  psCKernelLevelFixtureEmit
    "le.zeroU"
    (psCKernelLevelFixtureBoolText (psCKernelLevelLe psCKernelLevelZero u))
  psCKernelLevelFixtureEmit
    "le.uU1"
    (psCKernelLevelFixtureBoolText (psCKernelLevelLe u u1))
  psCKernelLevelFixtureEmit
    "le.u1U"
    (psCKernelLevelFixtureBoolText (psCKernelLevelLe u1 u))
  psCKernelLevelFixtureEmit
    "le.maxU"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelLe u (psCKernelLevelMaxRaw u v)))
  psCKernelLevelFixtureEmit
    "le.maxGeqFallthrough"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelLe
        (psCKernelLevelMkIMax u v)
        (psCKernelLevelMaxRaw u v)))
  psCKernelLevelFixtureEmit
    "equivalent.incomplete"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelEquivalent incompleteLeft incompleteRight))
  psCKernelLevelFixtureEmit
    "le.incomplete.forward"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelLe incompleteLeft incompleteRight))
  psCKernelLevelFixtureEmit
    "le.incomplete.reverse"
    (psCKernelLevelFixtureBoolText
      (psCKernelLevelLe incompleteRight incompleteLeft))
