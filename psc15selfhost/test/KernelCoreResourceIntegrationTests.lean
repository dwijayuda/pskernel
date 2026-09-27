import Ps.KernelCore.Admission
import Ps.KernelCore.Primitive

def psKernelCoreResourceIntegrationName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psKernelCoreResourceIntegrationConst
    (name : PsKernelCoreName) : PsKernelCoreExpr :=
  PsKernelCoreExpr.const name PsKernelCoreList.nil

def psKernelCoreResourceIntegrationNat (value : Nat) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat value)

def psKernelCoreResourceIntegrationApp2
    (fn left right : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app (PsKernelCoreExpr.app fn left) right

def psKernelCoreResourceIntegrationAxiom
    (name : PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreAxiomInfo :=
  {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := type
    }
    isUnsafe := false
  }

def psKernelCoreResourceIntegrationDefinition
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreDefinitionInfo :=
  {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := type
    }
    value := value
    hints := PsKernelCoreReducibilityHints.regular 0
    safety := PsKernelCoreDefinitionSafety.safe
  }

def psKernelCoreResourceIntegrationTheorem
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreTheoremInfo :=
  {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := type
    }
    value := value
  }

def psKernelCoreResourceIntegrationOpaque
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreOpaqueInfo :=
  {
    base := {
      name := name
      levelParams := PsKernelCoreList.nil
      type := type
    }
    value := value
    isUnsafe := false
  }

def psKernelCoreResourceIntegrationAddAxiomUnchecked
    (env : PsKernelCoreEnvironment)
    (name : PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreEnvironment :=
  psKernelCoreEnvironmentAddUnchecked env
    (PsKernelCoreConstantInfo.axiomInfo
      (psKernelCoreResourceIntegrationAxiom name type))

def psKernelCoreResourceIntegrationAddDefinitionUnchecked
    (env : PsKernelCoreEnvironment)
    (name : PsKernelCoreName)
    (type value : PsKernelCoreExpr) : PsKernelCoreEnvironment :=
  psKernelCoreEnvironmentAddUnchecked env
    (PsKernelCoreConstantInfo.defnInfo
      (psKernelCoreResourceIntegrationDefinition name type value))

def psKernelCoreResourceIntegrationExprResultEq
    (left right : PsKernelCoreResult String PsKernelCoreExpr) : Bool :=
  match left, right with
  | PsKernelCoreResult.error l, PsKernelCoreResult.error r => l == r
  | PsKernelCoreResult.ok l, PsKernelCoreResult.ok r => psKernelCoreExprEq l r
  | _, _ => false

def psKernelCoreResourceIntegrationBoolResultEq
    (left right : PsKernelCoreResult String Bool) : Bool :=
  match left, right with
  | PsKernelCoreResult.error l, PsKernelCoreResult.error r => l == r
  | PsKernelCoreResult.ok l, PsKernelCoreResult.ok r => psKernelCoreBoolEq l r
  | _, _ => false

def psKernelCoreResourceIntegrationLevelResultEq
    (left right : PsKernelCoreResult String PsKernelCoreLevel) : Bool :=
  match left, right with
  | PsKernelCoreResult.error l, PsKernelCoreResult.error r => l == r
  | PsKernelCoreResult.ok l, PsKernelCoreResult.ok r => psKernelCoreLevelEq l r
  | _, _ => false

def psKernelCoreResourceIntegrationEnvResultEq
    (target : PsKernelCoreName)
    (left right : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match left, right with
  | PsKernelCoreResult.error l, PsKernelCoreResult.error r => l == r
  | PsKernelCoreResult.ok l, PsKernelCoreResult.ok r =>
      Nat.beq (psKernelCoreEnvironmentSize l) (psKernelCoreEnvironmentSize r) &&
      psKernelCoreBoolEq
        (psKernelCoreEnvironmentContains l target)
        (psKernelCoreEnvironmentContains r target) &&
      psKernelCoreBoolEq l.quotInitialized r.quotInitialized
  | _, _ => false

def psKernelCoreResourceIntegrationExactExpr
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.ok actual => psKernelCoreExprEq actual expected
  | PsKernelCoreResult.error _ => false

def psKernelCoreResourceIntegrationExactBool
    (result : PsKernelCoreResult String Bool)
    (expected : Bool) : Bool :=
  match result with
  | PsKernelCoreResult.ok actual => psKernelCoreBoolEq actual expected
  | PsKernelCoreResult.error _ => false

def psKernelCoreResourceIntegrationExactErrorExpr
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psKernelCoreResourceIntegrationExactErrorEnv
    (result : PsKernelCoreResult String PsKernelCoreEnvironment)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psKernelCoreResourceIntegrationFixtures :
    PsKernelCoreEnvironment × PsKernelCoreExpr × PsKernelCoreExpr ×
    PsKernelCoreExpr × PsKernelCoreExpr × PsKernelCoreExpr :=
  let n := psKernelCoreResourceIntegrationName
  let natName := psKernelCorePrimitiveNatName
  let pName := n "P"
  let argName := n "argComputed"
  let acceptName := n "accept5"
  let aliasAddName := n "aliasAdd"
  let twoName := n "two"
  let natType := psKernelCoreResourceIntegrationConst natName
  let sort1 := PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)
  let pType :=
    PsKernelCoreExpr.forallE
      (n "n") natType sort1 PsKernelCoreBinderInfo.default
  let pConst := psKernelCoreResourceIntegrationConst pName
  let addConst := psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatAddName
  let add23 :=
    psKernelCoreResourceIntegrationApp2
      addConst
      (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationNat 3)
  let p5 := PsKernelCoreExpr.app pConst (psKernelCoreResourceIntegrationNat 5)
  let pAdd := PsKernelCoreExpr.app pConst add23
  let acceptType :=
    PsKernelCoreExpr.forallE
      (n "x") p5 natType PsKernelCoreBinderInfo.default
  let natBinaryType :=
    PsKernelCoreExpr.forallE
      (n "a") natType
      (PsKernelCoreExpr.forallE
        (n "b") natType natType PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
  let env0 := psKernelCoreEnvironmentEmpty
  let env1 := psKernelCoreResourceIntegrationAddAxiomUnchecked env0 natName sort1
  let env2 := psKernelCoreResourceIntegrationAddAxiomUnchecked env1 pName pType
  let env3 := psKernelCoreResourceIntegrationAddAxiomUnchecked env2 argName pAdd
  let env4 := psKernelCoreResourceIntegrationAddAxiomUnchecked env3 acceptName acceptType
  let env5 :=
    psKernelCoreResourceIntegrationAddDefinitionUnchecked
      env4 aliasAddName natBinaryType addConst
  let env6 :=
    psKernelCoreResourceIntegrationAddDefinitionUnchecked
      env5 twoName natType (psKernelCoreResourceIntegrationNat 2)
  let checkApp :=
    PsKernelCoreExpr.app
      (psKernelCoreResourceIntegrationConst acceptName)
      (psKernelCoreResourceIntegrationConst argName)
  (env6, add23, p5, pAdd, checkApp, natType)

def psKernelCoreResourceIntegrationWhnf : Bool :=
  let fixtures := psKernelCoreResourceIntegrationFixtures
  let env := fixtures.1
  let add23 := fixtures.2.1
  let natType := fixtures.2.2.2.2.2
  let n := psKernelCoreResourceIntegrationName
  let addConst := psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatAddName
  let expected5 := psKernelCoreResourceIntegrationNat 5
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let maxOneWord := Nat.sub psKernelCoreNatHeapLimbDivisor 1
  let sizeError :=
    "the kernel refused a Nat numeral because its size exceeds the maximum"
  let beta :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.lam
        (n "x") natType
        (psKernelCoreResourceIntegrationApp2
          addConst
          (PsKernelCoreExpr.bvar 0)
          (psKernelCoreResourceIntegrationNat 3))
        PsKernelCoreBinderInfo.default)
      (psKernelCoreResourceIntegrationNat 2)
  let zeta :=
    PsKernelCoreExpr.letE
      (n "x") natType (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationApp2
        addConst
        (PsKernelCoreExpr.bvar 0)
        (psKernelCoreResourceIntegrationNat 3))
      false
  let aliasExpr :=
    psKernelCoreResourceIntegrationApp2
      (psKernelCoreResourceIntegrationConst (n "aliasAdd"))
      (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationNat 3)
  let deltaOperand :=
    psKernelCoreResourceIntegrationApp2
      addConst
      (psKernelCoreResourceIntegrationConst (n "two"))
      (psKernelCoreResourceIntegrationNat 3)
  let malformed :=
    PsKernelCoreExpr.app addConst (psKernelCoreResourceIntegrationNat 2)
  let leveled :=
    psKernelCoreResourceIntegrationApp2
      (PsKernelCoreExpr.const
        psKernelCorePrimitiveNatAddName
        (PsKernelCoreList.cons PsKernelCoreLevel.zero PsKernelCoreList.nil))
      (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationNat 3)
  let nonliteral :=
    psKernelCoreResourceIntegrationApp2
      addConst
      (PsKernelCoreExpr.fvar (n "free"))
      (psKernelCoreResourceIntegrationNat 3)
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty add23)
      expected5 &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty beta)
      expected5 &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty zeta)
      expected5 &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty aliasExpr)
      expected5 &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty deltaOperand)
      expected5 &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty malformed)
      malformed &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty leveled)
      leveled &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty nonliteral)
      nonliteral &&
  psKernelCoreResourceIntegrationExactErrorExpr
      (psKernelCoreWhnfWithResources
        64 tiny env psKernelCoreLocalContextEmpty
        (psKernelCoreResourceIntegrationApp2
          addConst
          (psKernelCoreResourceIntegrationNat maxOneWord)
          (psKernelCoreResourceIntegrationNat 1)))
      sizeError &&
  psKernelCoreResourceIntegrationExactErrorExpr
      (psKernelCoreWhnfWithResources
        0 tiny env psKernelCoreLocalContextEmpty add23)
      "reduction budget exhausted"

def psKernelCoreResourceIntegrationInferCheck : Bool :=
  let fixtures := psKernelCoreResourceIntegrationFixtures
  let env := fixtures.1
  let checkApp := fixtures.2.2.2.2.1
  let natType := fixtures.2.2.2.2.2
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let exact := Nat.sub psKernelCoreNatHeapLimbDivisor 1
  let over := psKernelCoreNatHeapLimbDivisor
  let sizeError :=
    "the kernel refused a Nat numeral because its size exceeds the maximum"
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreInferWithResources
        64 tiny env psKernelCoreLocalContextEmpty
        (psKernelCoreResourceIntegrationNat exact))
      natType &&
  psKernelCoreResourceIntegrationExactErrorExpr
      (psKernelCoreInferWithResources
        64 tiny env psKernelCoreLocalContextEmpty
        (psKernelCoreResourceIntegrationNat over))
      sizeError &&
  psKernelCoreResourceIntegrationExactExpr
      (psKernelCoreCheckWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        PsKernelCoreDefinitionSafety.safe checkApp)
      natType &&
  psKernelCoreResourceIntegrationExactErrorExpr
      (psKernelCoreCheckWithResources
        64 tiny env psKernelCoreLocalContextEmpty
        PsKernelCoreDefinitionSafety.safe
        (psKernelCoreResourceIntegrationNat over))
      sizeError

def psKernelCoreResourceIntegrationDefEq : Bool :=
  let fixtures := psKernelCoreResourceIntegrationFixtures
  let env := fixtures.1
  let add23 := fixtures.2.1
  let addConst := psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatAddName
  let mulConst := psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatMulName
  let beqConst := psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatBeqName
  let mul34 :=
    psKernelCoreResourceIntegrationApp2
      mulConst
      (psKernelCoreResourceIntegrationNat 3)
      (psKernelCoreResourceIntegrationNat 4)
  let beq22 :=
    psKernelCoreResourceIntegrationApp2
      beqConst
      (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationNat 2)
  let boolTrue :=
    psKernelCoreResourceIntegrationConst psKernelCorePrimitiveBoolTrueName
  psKernelCoreResourceIntegrationExactBool
      (psKernelCoreIsDefEqWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        add23 (psKernelCoreResourceIntegrationNat 5))
      true &&
  psKernelCoreResourceIntegrationExactBool
      (psKernelCoreIsDefEqWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        mul34 (psKernelCoreResourceIntegrationNat 12))
      true &&
  psKernelCoreResourceIntegrationExactBool
      (psKernelCoreIsDefEqWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        beq22 boolTrue)
      true

def psKernelCoreResourceIntegrationAdmission : Bool :=
  let fixtures := psKernelCoreResourceIntegrationFixtures
  let env := fixtures.1
  let p5 := fixtures.2.2.1
  let natType := fixtures.2.2.2.2.2
  let n := psKernelCoreResourceIntegrationName
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let argExpr := psKernelCoreResourceIntegrationConst (n "argComputed")
  let normalizedName := n "normalizedDef"
  let normalized :=
    psKernelCoreResourceIntegrationDefinition normalizedName p5 argExpr
  let hugeName := n "oversizedDef"
  let huge := psKernelCoreNatHeapLimbDivisor
  let oversized :=
    psKernelCoreResourceIntegrationDefinition
      hugeName natType (psKernelCoreResourceIntegrationNat huge)
  let originalSize := psKernelCoreEnvironmentSize env
  let oversizedResult :=
    psKernelCoreAddDefinitionWithResources 96 tiny env oversized
  let sizeError :=
    "the kernel refused a Nat numeral because its size exceeds the maximum"
  let powName := n "powArg"
  let powExpr :=
    psKernelCoreResourceIntegrationApp2
      (psKernelCoreResourceIntegrationConst psKernelCorePrimitiveNatPowName)
      (psKernelCoreResourceIntegrationNat 2)
      (psKernelCoreResourceIntegrationNat 64)
  let pConst := psKernelCoreResourceIntegrationConst (n "P")
  let pPow := PsKernelCoreExpr.app pConst powExpr
  let envNested := psKernelCoreResourceIntegrationAddAxiomUnchecked env powName pPow
  let nestedName := n "nestedFail"
  let nested :=
    psKernelCoreResourceIntegrationDefinition
      nestedName
      (PsKernelCoreExpr.app pConst (psKernelCoreResourceIntegrationNat 1))
      (psKernelCoreResourceIntegrationConst powName)
  let growthError :=
    "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
  let normalizedResult :=
    psKernelCoreAddDefinitionWithResources
      96 psKernelCoreResourceConfigDefault env normalized
  match normalizedResult with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok normalizedEnv =>
      psKernelCoreEnvironmentContains normalizedEnv normalizedName &&
      Nat.beq (psKernelCoreEnvironmentSize normalizedEnv) (Nat.succ originalSize) &&
      psKernelCoreResourceIntegrationExactErrorEnv oversizedResult sizeError &&
      Nat.beq (psKernelCoreEnvironmentSize env) originalSize &&
      psKernelCoreEnvironmentContains env (n "argComputed") &&
      !psKernelCoreEnvironmentContains env hugeName &&
      !env.quotInitialized &&
      psKernelCoreResourceIntegrationExactErrorEnv
        (psKernelCoreAddDefinitionWithResources 96 tiny envNested nested)
        growthError

def psKernelCoreResourceIntegrationDefaultWrappers : Bool :=
  let fixtures := psKernelCoreResourceIntegrationFixtures
  let env := fixtures.1
  let add23 := fixtures.2.1
  let checkApp := fixtures.2.2.2.2.1
  let n := psKernelCoreResourceIntegrationName
  let sort1 := PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)
  let aName := n "Adefault"
  let aExpr := psKernelCoreResourceIntegrationConst aName
  let pName := n "Pdefault"
  let pExpr := psKernelCoreResourceIntegrationConst pName
  let aValName := n "adefault"
  let pValName := n "pdefault"
  let env1 := psKernelCoreResourceIntegrationAddAxiomUnchecked env aName sort1
  let env2 :=
    psKernelCoreResourceIntegrationAddAxiomUnchecked
      env1 pName (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
  let env3 := psKernelCoreResourceIntegrationAddAxiomUnchecked env2 aValName aExpr
  let env4 := psKernelCoreResourceIntegrationAddAxiomUnchecked env3 pValName pExpr
  let axName := n "axDefault"
  let defName := n "defDefault"
  let thmName := n "thmDefault"
  let opaqueName := n "opaqueDefault"
  let ax := psKernelCoreResourceIntegrationAxiom axName aExpr
  let defn :=
    psKernelCoreResourceIntegrationDefinition
      defName aExpr (psKernelCoreResourceIntegrationConst aValName)
  let thm :=
    psKernelCoreResourceIntegrationTheorem
      thmName pExpr (psKernelCoreResourceIntegrationConst pValName)
  let opaque :=
    psKernelCoreResourceIntegrationOpaque
      opaqueName aExpr (psKernelCoreResourceIntegrationConst aValName)
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreWhnf 64 env psKernelCoreLocalContextEmpty add23)
      (psKernelCoreWhnfWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty add23) &&
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreInfer 64 env psKernelCoreLocalContextEmpty
        (psKernelCoreResourceIntegrationNat 2))
      (psKernelCoreInferWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        (psKernelCoreResourceIntegrationNat 2)) &&
  psKernelCoreResourceIntegrationBoolResultEq
      (psKernelCoreIsDefEq
        64 env psKernelCoreLocalContextEmpty add23
        (psKernelCoreResourceIntegrationNat 5))
      (psKernelCoreIsDefEqWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        add23 (psKernelCoreResourceIntegrationNat 5)) &&
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreCheck
        64 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe checkApp)
      (psKernelCoreCheckWithResources
        64 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        PsKernelCoreDefinitionSafety.safe checkApp) &&
  psKernelCoreResourceIntegrationEnvResultEq axName
      (psKernelCoreAddAxiom 96 env4 ax)
      (psKernelCoreAddAxiomWithResources
        96 psKernelCoreResourceConfigDefault env4 ax) &&
  psKernelCoreResourceIntegrationEnvResultEq defName
      (psKernelCoreAddDefinition 96 env4 defn)
      (psKernelCoreAddDefinitionWithResources
        96 psKernelCoreResourceConfigDefault env4 defn) &&
  psKernelCoreResourceIntegrationEnvResultEq thmName
      (psKernelCoreAddTheorem 96 env4 thm)
      (psKernelCoreAddTheoremWithResources
        96 psKernelCoreResourceConfigDefault env4 thm) &&
  psKernelCoreResourceIntegrationEnvResultEq opaqueName
      (psKernelCoreAddOpaque 96 env4 opaque)
      (psKernelCoreAddOpaqueWithResources
        96 psKernelCoreResourceConfigDefault env4 opaque) &&
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreWhnf 0 env psKernelCoreLocalContextEmpty add23)
      (psKernelCoreWhnfWithResources
        0 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty add23) &&
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreInfer 0 env psKernelCoreLocalContextEmpty add23)
      (psKernelCoreInferWithResources
        0 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty add23) &&
  psKernelCoreResourceIntegrationBoolResultEq
      (psKernelCoreIsDefEq
        0 env psKernelCoreLocalContextEmpty add23 add23)
      (psKernelCoreIsDefEqWithResources
        0 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty add23 add23) &&
  psKernelCoreResourceIntegrationExprResultEq
      (psKernelCoreCheck
        0 env psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe checkApp)
      (psKernelCoreCheckWithResources
        0 psKernelCoreResourceConfigDefault env psKernelCoreLocalContextEmpty
        PsKernelCoreDefinitionSafety.safe checkApp) &&
  psKernelCoreResourceIntegrationEnvResultEq axName
      (psKernelCoreAddAxiom 0 env4 ax)
      (psKernelCoreAddAxiomWithResources
        0 psKernelCoreResourceConfigDefault env4 ax) &&
  psKernelCoreResourceIntegrationEnvResultEq defName
      (psKernelCoreAddDefinition 0 env4 defn)
      (psKernelCoreAddDefinitionWithResources
        0 psKernelCoreResourceConfigDefault env4 defn) &&
  psKernelCoreResourceIntegrationEnvResultEq thmName
      (psKernelCoreAddTheorem 0 env4 thm)
      (psKernelCoreAddTheoremWithResources
        0 psKernelCoreResourceConfigDefault env4 thm) &&
  psKernelCoreResourceIntegrationEnvResultEq opaqueName
      (psKernelCoreAddOpaque 0 env4 opaque)
      (psKernelCoreAddOpaqueWithResources
        0 psKernelCoreResourceConfigDefault env4 opaque)

def psKernelCoreResourceIntegration : Bool :=
  psKernelCoreResourceIntegrationWhnf &&
  psKernelCoreResourceIntegrationInferCheck &&
  psKernelCoreResourceIntegrationDefEq &&
  psKernelCoreResourceIntegrationAdmission &&
  psKernelCoreResourceIntegrationDefaultWrappers

def main : IO Unit := do
  if !psKernelCoreResourceIntegration then
    throw (IO.userError "PSC2_KERNEL_CORE_RESOURCE_INTEGRATION: FAIL")
  IO.println "PSC2_KERNEL_CORE_RESOURCE_INTEGRATION: PASS"
