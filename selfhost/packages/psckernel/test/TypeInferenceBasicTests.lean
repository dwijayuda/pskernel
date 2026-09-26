import Ps.PSCKernel.Core.TypeInferenceBasic

structure PsCKernelTypeInferenceBasicNamedTest where
  name : String
  passed : Bool

def psCKernelTypeInferenceBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelTypeInferenceBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelTypeInferenceBasicName text) []

def psCKernelTypeInferenceBasicAxiom
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelTypeInferenceBasicName name
      levelParams := levelParams
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelTypeInferenceBasicAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelTypeInferenceBasicBaseEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelTypeInferenceBasicConst "A"
  let env0 := psCKernelTypeInferenceBasicAdd
    psCKernelEnvironmentEmpty
    (psCKernelTypeInferenceBasicAxiom "A" [] sort0)
  let env1 := psCKernelTypeInferenceBasicAdd
    env0
    (psCKernelTypeInferenceBasicAxiom "a" [] aType)
  let env2 := psCKernelTypeInferenceBasicAdd
    env1
    (psCKernelTypeInferenceBasicAxiom "B" [] sort0)
  psCKernelTypeInferenceBasicAdd
    env2
    (psCKernelTypeInferenceBasicAxiom "b" [] (psCKernelTypeInferenceBasicConst "B"))

def psCKernelTypeInferenceBasicEqOption
    (actual : Option PsCKernelExpr)
    (expected : Option PsCKernelExpr) : Bool :=
  match actual, expected with
  | none, none => true
  | some left, some right => psCKernelExprEqStructural left right
  | _, _ => false

def psCKernelTypeInferenceBasicTestSort : Bool :=
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv
      psCKernelLocalContextEmpty
      (PsCKernelExpr.sortE psCKernelLevelZero))
    (some (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)))

def psCKernelTypeInferenceBasicTestKnownFVar : Bool :=
  let id : PsCKernelFVarId := { name := psCKernelTypeInferenceBasicName "xId" }
  let ty := psCKernelTypeInferenceBasicConst "A"
  let ctx := psCKernelLocalContextMkLocalDecl
    psCKernelLocalContextEmpty id (psCKernelTypeInferenceBasicName "x") ty
    PsCKernelBinderInfo.default PsCKernelLocalDeclKind.default
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic? psCKernelTypeInferenceBasicBaseEnv ctx (PsCKernelExpr.fvar id))
    (some ty)

def psCKernelTypeInferenceBasicTestUnknownFVar : Bool :=
  let id : PsCKernelFVarId := { name := psCKernelTypeInferenceBasicName "missing" }
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty (PsCKernelExpr.fvar id))
    none

def psCKernelTypeInferenceBasicTestKnownConst : Bool :=
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty
      (psCKernelTypeInferenceBasicConst "a"))
    (some (psCKernelTypeInferenceBasicConst "A"))

def psCKernelTypeInferenceBasicTestUniverseConst : Bool :=
  let u := psCKernelTypeInferenceBasicName "u"
  let polyType := PsCKernelExpr.sortE (psCKernelLevelParam u)
  let env := psCKernelTypeInferenceBasicAdd
    psCKernelTypeInferenceBasicBaseEnv
    (psCKernelTypeInferenceBasicAxiom "Poly" [u] polyType)
  let expr := PsCKernelExpr.constE
    (psCKernelTypeInferenceBasicName "Poly") [psCKernelLevelZero]
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic? env psCKernelLocalContextEmpty expr)
    (some (PsCKernelExpr.sortE psCKernelLevelZero))

def psCKernelTypeInferenceBasicTestBadUniverseArity : Bool :=
  let u := psCKernelTypeInferenceBasicName "u"
  let env := psCKernelTypeInferenceBasicAdd
    psCKernelTypeInferenceBasicBaseEnv
    (psCKernelTypeInferenceBasicAxiom
      "Poly" [u] (PsCKernelExpr.sortE (psCKernelLevelParam u)))
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      env psCKernelLocalContextEmpty (psCKernelTypeInferenceBasicConst "Poly"))
    none

def psCKernelTypeInferenceBasicTestApp : Bool :=
  let aType := psCKernelTypeInferenceBasicConst "A"
  let fType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceBasicName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let env := psCKernelTypeInferenceBasicAdd
    psCKernelTypeInferenceBasicBaseEnv
    (psCKernelTypeInferenceBasicAxiom "f" [] fType)
  let expr := PsCKernelExpr.app
    (psCKernelTypeInferenceBasicConst "f")
    (psCKernelTypeInferenceBasicConst "a")
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic? env psCKernelLocalContextEmpty expr)
    (some (psCKernelTypeInferenceBasicConst "a"))

def psCKernelTypeInferenceBasicTestAppDoesNotCheckArgument : Bool :=
  let aType := psCKernelTypeInferenceBasicConst "A"
  let bType := psCKernelTypeInferenceBasicConst "B"
  let fType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceBasicName "x") aType bType PsCKernelBinderInfo.default
  let env := psCKernelTypeInferenceBasicAdd
    psCKernelTypeInferenceBasicBaseEnv
    (psCKernelTypeInferenceBasicAxiom "f" [] fType)
  let expr := PsCKernelExpr.app
    (psCKernelTypeInferenceBasicConst "f")
    (psCKernelTypeInferenceBasicConst "missingArgument")
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic? env psCKernelLocalContextEmpty expr)
    (some bType)

def psCKernelTypeInferenceBasicTestAppWhnfFunctionType : Bool :=
  let aType := psCKernelTypeInferenceBasicConst "A"
  let bType := psCKernelTypeInferenceBasicConst "B"
  let piType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceBasicName "x") aType bType PsCKernelBinderInfo.default
  let wrappedType := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicName "T")
    (PsCKernelExpr.sortE psCKernelLevelZero)
    piType
    (PsCKernelExpr.bvar 0)
    false
  let env := psCKernelTypeInferenceBasicAdd
    psCKernelTypeInferenceBasicBaseEnv
    (psCKernelTypeInferenceBasicAxiom "wrapped" [] wrappedType)
  let expr := PsCKernelExpr.app
    (psCKernelTypeInferenceBasicConst "wrapped")
    (psCKernelTypeInferenceBasicConst "a")
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic? env psCKernelLocalContextEmpty expr)
    (some bType)

def psCKernelTypeInferenceBasicTestLet : Bool :=
  let aType := psCKernelTypeInferenceBasicConst "A"
  let expr := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicName "x") aType
    (psCKernelTypeInferenceBasicConst "a")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty expr)
    (some aType)

def psCKernelTypeInferenceBasicTestNestedLet : Bool :=
  let aType := psCKernelTypeInferenceBasicConst "A"
  let inner := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicName "y") aType
    (PsCKernelExpr.bvar 0)
    (PsCKernelExpr.bvar 0)
    false
  let expr := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicName "x") aType
    (psCKernelTypeInferenceBasicConst "a") inner false
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty expr)
    (some aType)

def psCKernelTypeInferenceBasicTestNatLiteral : Bool :=
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.lit (PsCKernelLiteral.natVal 7)))
    (some (psCKernelTypeInferenceBasicConst "Nat"))

def psCKernelTypeInferenceBasicTestStringLiteral : Bool :=
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.lit (PsCKernelLiteral.strVal "psc1")))
    (some (psCKernelTypeInferenceBasicConst "String"))

def psCKernelTypeInferenceBasicTestLooseBVarFails : Bool :=
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty (PsCKernelExpr.bvar 0))
    none

def psCKernelTypeInferenceBasicTestMVarFails : Bool :=
  let id : PsCKernelMVarId := { name := psCKernelTypeInferenceBasicName "m" }
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty (PsCKernelExpr.mvar id))
    none

def psCKernelTypeInferenceBasicTestNonFunctionAppFails : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelTypeInferenceBasicConst "a")
    (psCKernelTypeInferenceBasicConst "a")
  psCKernelTypeInferenceBasicEqOption
    (psCKernelInferBasic?
      psCKernelTypeInferenceBasicBaseEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelTypeInferenceBasicTests : List PsCKernelTypeInferenceBasicNamedTest := [
  { name := "sort inference increments universe", passed := psCKernelTypeInferenceBasicTestSort },
  { name := "known free variable returns local type", passed := psCKernelTypeInferenceBasicTestKnownFVar },
  { name := "unknown free variable fails closed", passed := psCKernelTypeInferenceBasicTestUnknownFVar },
  { name := "known constant returns declared type", passed := psCKernelTypeInferenceBasicTestKnownConst },
  { name := "constant inference instantiates universes", passed := psCKernelTypeInferenceBasicTestUniverseConst },
  { name := "wrong constant universe arity fails", passed := psCKernelTypeInferenceBasicTestBadUniverseArity },
  { name := "application inference instantiates Pi body", passed := psCKernelTypeInferenceBasicTestApp },
  { name := "infer-only application does not check argument", passed := psCKernelTypeInferenceBasicTestAppDoesNotCheckArgument },
  { name := "application exposes reducible function type", passed := psCKernelTypeInferenceBasicTestAppWhnfFunctionType },
  { name := "let inference substitutes value", passed := psCKernelTypeInferenceBasicTestLet },
  { name := "nested let inference composes substitutions", passed := psCKernelTypeInferenceBasicTestNestedLet },
  { name := "Nat literal infers Nat", passed := psCKernelTypeInferenceBasicTestNatLiteral },
  { name := "String literal infers String", passed := psCKernelTypeInferenceBasicTestStringLiteral },
  { name := "loose bound variable fails closed", passed := psCKernelTypeInferenceBasicTestLooseBVarFails },
  { name := "metavariable fails closed", passed := psCKernelTypeInferenceBasicTestMVarFails },
  { name := "non-function application fails closed", passed := psCKernelTypeInferenceBasicTestNonFunctionAppFails }
]

def psCKernelRunTypeInferenceBasicTests
    (tests : List PsCKernelTypeInferenceBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_TYPE_INFERENCE_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_TYPE_INFERENCE_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunTypeInferenceBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunTypeInferenceBasicTests psCKernelTypeInferenceBasicTests
  if passed then
    IO.println "PSCKERNEL_TYPE_INFERENCE_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_TYPE_INFERENCE_BASIC_TESTS: FAIL")
