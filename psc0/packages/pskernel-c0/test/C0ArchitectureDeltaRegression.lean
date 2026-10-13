import Ps.KernelCore.Architecture.Demand
import Ps.KernelCore.Admission.Declaration.Admission

def c0DeltaName (name : String) : PsKernelName :=
  .str .anonymous name

def c0DeltaCheck
    (name : String)
    (session : PsKernelCheckerSession)
    (input expected : PsKernelExpr) : IO Unit := do
  match psKernelC0ArchitectureObserveDelta 4096 session input with
  | .error err =>
      throw (IO.userError (name ++ ": source WHNF rejected: " ++ err))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue expected ||
          !((observation.candidateValue).any
            (fun value => psKernelExprEqual value expected)) then
        throw (IO.userError (name ++ ": candidate/source delta divergence"))

/-- Literal-spine fixtures use the same source Nat names and expression
    forms as the trusted checker. -/
def c0DeltaNatLit (n : Nat) : PsKernelExpr := .lit (.nat n)

def c0DeltaNatBinary
    (name : PsKernelName) (a b : PsKernelExpr) : PsKernelExpr :=
  .app (.app (.const name []) a) b

/-- Bounded constructor/local-context source differential: syntax can
    be untrusted, but the source checker remains the WHNF oracle. -/
def c0StructuralCheck
    (label : String)
    (session : PsKernelCheckerSession)
    (input expected : PsKernelExpr) : IO Unit := do
  match psKernelC0ArchitectureObserveStructural 4096 session input with
  | .error reason =>
      throw (IO.userError (label ++ ": source structural WHNF failed: " ++ reason))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue expected ||
          !observation.candidateValue.any (psKernelExprEqual expected) then
        throw (IO.userError (label ++ ": structural/source disagreement"))

/-- One global-budget, nested-demand source WHNF regression. -/
def c0DemandCheck
    (label : String)
    (session : PsKernelCheckerSession)
    (input expected : PsKernelExpr) : IO Unit := do
  match psKernelC0ArchitectureObserveDemand 4096 session input with
  | .error reason =>
      throw (IO.userError (label ++ ": source demand WHNF failed: " ++ reason))
  | .ok (observation, _) =>
      if !observation.agrees ||
          !psKernelExprEqual observation.sourceValue expected ||
          !observation.candidateValue.any (psKernelExprEqual expected) then
        throw (IO.userError (label ++ ": shared-demand/source disagreement"))

def main : IO Unit := do
  let type := PsKernelExpr.sort (.succ .zero)
  let sort := PsKernelExpr.sort .zero
  let first := c0DeltaName "C0DeltaFirst"
  let second := c0DeltaName "C0DeltaSecond"
  let a : PsKernelDefinitionInfo := {
    base := { name := first, levelParams := [], type := type }
    value := sort
    hints := .abbrevHint
    safety := .safe
  }
  let b : PsKernelDefinitionInfo := {
    base := { name := second, levelParams := [], type := type }
    value := .const first []
    hints := .abbrevHint
    safety := .safe
  }
  let env1 ← match psKernelAddDefinition 4096 psKernelEnvironmentEmpty a
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok env => pure env
    | .error err => throw (IO.userError ("setup first delta: " ++ err))
  let env2 ← match psKernelAddDefinition 4096 env1 b
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok env => pure env
    | .error err => throw (IO.userError ("setup second delta: " ++ err))
  let session := psKernelMkCheckerSession env2 []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  c0DeltaCheck "one-delta" session (.const first []) sort
  c0DeltaCheck "chained-delta" session (.const second []) sort
  c0DeltaCheck "neutral-constant" session
    (.const (c0DeltaName "UnboundNeutral") [])
    (.const (c0DeltaName "UnboundNeutral") [])
  let x := c0DeltaName "x"
  let ty := .sort .zero
  let lam : PsKernelExpr := .lam x ty (.bvar 0) .default
  let argument : PsKernelExpr := .const first []
  c0DeltaCheck "delta-under-beta" session
    (.app lam argument) sort
  c0DeltaCheck "delta-under-zeta" session
    (.letE x ty (.const second []) (.bvar 0) false) sort
  -- A delta body must instantiate the declaration's universe parameters
  -- using the actual constant occurrence, not a cached default level.
  let univParam := c0DeltaName "u"
  let polymorphic := c0DeltaName "C0PolymorphicAlias"
  let poly : PsKernelDefinitionInfo := {
    base := {
      name := polymorphic
      levelParams := [univParam]
      type := .sort (.succ (.param univParam))
    }
    value := .sort (.param univParam)
    hints := .abbrevHint
    safety := .safe
  }
  let polyEnv ← match psKernelAddDefinition 4096 env2 poly
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok env => pure env
    | .error err =>
        throw (IO.userError ("polymorphic setup rejected: " ++ err))
  let polySession := psKernelMkCheckerSession polyEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  c0DeltaCheck "universe-level-zero" polySession
    (.const polymorphic [.zero]) (.sort .zero)
  c0DeltaCheck "universe-level-one" polySession
    (.const polymorphic [.succ .zero]) (.sort (.succ .zero))
  -- An unsafe declaration can be syntactically represented in an
  -- untrusted test fixture but must never authorize candidate delta.
  let unsafeName := c0DeltaName "C0UnsafeAlias"
  let unsafeDefinition : PsKernelDefinitionInfo := {
    base := { name := unsafeName, levelParams := [], type := type }
    value := sort
    hints := .abbrevHint
    safety := .unsafeDef
  }
  let unsafeEnv := psKernelEnvironmentAddUnchecked polyEnv
    (.defnInfo unsafeDefinition)
  let unsafeSession := psKernelMkCheckerSession unsafeEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  match psKernelC0ArchitectureCandidateDelta 100 unsafeSession.context
      (.const unsafeName []) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "C0 candidate unfolded unsafe declaration")
  -- A reducible definition whose value is a lambda must hand control back
  -- to the lazy argument-spine machine for actual beta reduction.
  let functionName := c0DeltaName "C0DeltaFunction"
  let binder := c0DeltaName "argument"
  let identity : PsKernelDefinitionInfo := {
    base := {
      name := functionName
      levelParams := []
      type := .forallE binder sort sort .default
    }
    value := .lam binder sort (.bvar 0) .default
    hints := .abbrevHint
    safety := .safe
  }
  let functionEnv ← match psKernelAddDefinition 4096 polyEnv identity
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok env => pure env
    | .error err => throw (IO.userError ("delta function setup: " ++ err))
  let functionSession := psKernelMkCheckerSession functionEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  c0DeltaCheck "delta-then-beta" functionSession
    (.app (.const functionName []) (.sort .zero)) (.sort .zero)
  c0DeltaCheck "nested-delta-then-beta" functionSession
    (.app (.const functionName []) (.const first [])) (.sort .zero)
  let opaqueName := c0DeltaName "C0DeltaOpaque"
  let info : PsKernelOpaqueInfo := {
    base := { name := opaqueName, levelParams := [], type := type }
    value := sort
    isUnsafe := false
  }
  let opaqueEnv ← match psKernelAddOpaque 4096 env2 info
      4096 psKernelLeanNatMaxSizeDefault with
    | .ok env => pure env
    | .error err => throw (IO.userError ("setup opaque: " ++ err))
  c0DeltaCheck "opaque-is-neutral"
    (psKernelMkCheckerSession opaqueEnv [] .safe 4096 psKernelLeanNatMaxSizeDefault)
    (.const opaqueName []) (.const opaqueName [])
  match psKernelC0ArchitectureCandidateDelta 0 session.context (.const first []) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "C0 delta candidate accepted zero fuel")
  -- The source authority rejects an ill-typed application; even a candidate
  -- value must never convert that into a valid checked judgment.
  match psKernelSessionCheck 4096 session (.app sort sort) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "C0 checked invalid application")
  -- CDE-2: source-owned Nat primitives on a delayed candidate spine.
  c0DeltaCheck "nat-literal-successor" session
    (.app (.const psKernelNatSuccName []) (c0DeltaNatLit 9))
    (c0DeltaNatLit 10)
  c0DeltaCheck "nat-literal-add" session
    (c0DeltaNatBinary psKernelNatAddName
      (c0DeltaNatLit 17) (c0DeltaNatLit 25))
    (c0DeltaNatLit 42)
  c0DeltaCheck "nat-literal-sub" session
    (c0DeltaNatBinary psKernelNatSubName
      (c0DeltaNatLit 2) (c0DeltaNatLit 9))
    (c0DeltaNatLit 0)
  c0DeltaCheck "nat-literal-mul" session
    (c0DeltaNatBinary psKernelNatMulName
      (c0DeltaNatLit 6) (c0DeltaNatLit 7))
    (c0DeltaNatLit 42)
  c0DeltaCheck "nat-literal-div-zero" session
    (c0DeltaNatBinary psKernelNatDivName
      (c0DeltaNatLit 7) (c0DeltaNatLit 0))
    (c0DeltaNatLit 0)
  c0DeltaCheck "nat-literal-pow" session
    (c0DeltaNatBinary psKernelNatPowName
      (c0DeltaNatLit 2) (c0DeltaNatLit 5))
    (c0DeltaNatLit 32)
  c0DeltaCheck "nat-literal-gcd" session
    (c0DeltaNatBinary psKernelNatGcdName
      (c0DeltaNatLit 18) (c0DeltaNatLit 12))
    (c0DeltaNatLit 6)
  c0DeltaCheck "nat-literal-mod" session
    (c0DeltaNatBinary psKernelNatModName
      (c0DeltaNatLit 7) (c0DeltaNatLit 3))
    (c0DeltaNatLit 1)
  c0DeltaCheck "nat-literal-ble" session
    (c0DeltaNatBinary psKernelNatBleName
      (c0DeltaNatLit 3) (c0DeltaNatLit 5))
    (psKernelBoolExpr true)
  c0DeltaCheck "nat-literal-land" session
    (c0DeltaNatBinary psKernelNatLandName
      (c0DeltaNatLit 6) (c0DeltaNatLit 3))
    (c0DeltaNatLit 2)
  c0DeltaCheck "nat-literal-lor" session
    (c0DeltaNatBinary psKernelNatLorName
      (c0DeltaNatLit 6) (c0DeltaNatLit 3))
    (c0DeltaNatLit 7)
  c0DeltaCheck "nat-literal-xor" session
    (c0DeltaNatBinary psKernelNatXorName
      (c0DeltaNatLit 6) (c0DeltaNatLit 3))
    (c0DeltaNatLit 5)
  c0DeltaCheck "nat-literal-shift-left" session
    (c0DeltaNatBinary psKernelNatShiftLeftName
      (c0DeltaNatLit 3) (c0DeltaNatLit 2))
    (c0DeltaNatLit 12)
  c0DeltaCheck "nat-literal-shift-right" session
    (c0DeltaNatBinary psKernelNatShiftRightName
      (c0DeltaNatLit 9) (c0DeltaNatLit 2))
    (c0DeltaNatLit 2)
  c0DeltaCheck "nat-literal-eq" session
    (c0DeltaNatBinary psKernelNatBeqName
      (c0DeltaNatLit 7) (c0DeltaNatLit 7))
    (psKernelBoolExpr true)
  -- Delayed arguments must retain the beta/zeta environment until readback.
  let natBinder := c0DeltaName "n"
  let add2 := c0DeltaNatBinary psKernelNatAddName
    (.bvar 0) (c0DeltaNatLit 2)
  c0DeltaCheck "nat-beta-environment" session
    (.app (.lam natBinder (.sort .zero) add2 .default)
      (c0DeltaNatLit 40))
    (c0DeltaNatLit 42)
  c0DeltaCheck "nat-zeta-environment" session
    (.letE natBinder (.sort .zero) (c0DeltaNatLit 40)
      add2 false)
    (c0DeltaNatLit 42)
  -- Candidate size exhaustion must not silently turn into acceptance.
  let tinySession := psKernelMkCheckerSession env2 []
    .safe 4096 1
  match psKernelC0ArchitectureCandidateDelta 4096 tinySession.context
      (c0DeltaNatBinary psKernelNatAddName
        (c0DeltaNatLit 255) (c0DeltaNatLit 1)) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "Nat candidate bypassed checked numeral-size policy")
  let neutral : PsKernelExpr := .const (c0DeltaName "NatNeutral") []
  let stuckNat := c0DeltaNatBinary psKernelNatAddName neutral
    (c0DeltaNatLit 2)
  c0DeltaCheck "nat-nonliteral-remains-neutral" session
    stuckNat stuckNat
  match psKernelC0ArchitectureCandidateDelta 0 session.context
      (c0DeltaNatBinary psKernelNatMulName
        (c0DeltaNatLit 2) (c0DeltaNatLit 3)) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "Nat candidate accepted exhausted execution fuel")

  -- CDE-3: a local let is unfolded, while a local hypothesis is neutral.
  let localName := c0DeltaName "C0LocalLet"
  let letContext := psKernelLocalContextAddLet
    session.context.localContext localName localName type (.const first [])
  let localSession : PsKernelCheckerSession := {
    session with context := { session.context with localContext := letContext }
  }
  c0StructuralCheck "local-let-to-delta" localSession
    (.fvar localName) sort
  let localHypothesis := c0DeltaName "C0LocalHypothesis"
  let hypothesisContext := psKernelLocalContextAddLocal
    letContext localHypothesis localHypothesis type .default
  let hypothesisSession : PsKernelCheckerSession := {
    session with context := {
      session.context with localContext := hypothesisContext
    }
  }
  c0StructuralCheck "local-hypothesis-neutral" hypothesisSession
    (.fvar localHypothesis) (.fvar localHypothesis)
  -- A shadowing hypothesis must block an older let of the same name.
  let shadowContext := psKernelLocalContextAddLocal
    letContext localName localName type .default
  let shadowSession : PsKernelCheckerSession := {
    session with context := { session.context with localContext := shadowContext }
  }
  c0StructuralCheck "shadowed-local-let-neutral" shadowSession
    (.fvar localName) (.fvar localName)

  -- The checked source helper owns constructor membership and parameter
  -- offset. This fixture injects metadata only for WHNF differential tests;
  -- it must never be used as a declaration-admission acceptance fixture.
  let pairType := c0DeltaName "C0ProjectionPair"
  let ctorName := c0DeltaName "C0ProjectionPair.mk"
  let ctorInfo : PsKernelConstructorInfo := {
    base := { name := ctorName, levelParams := [], type := type }
    induct := pairType
    cidx := 0
    numParams := 1
    numFields := 2
    isUnsafe := false
  }
  let ctorEnv := psKernelEnvironmentAddUnchecked env2 (.ctorInfo ctorInfo)
  let ctorSession := psKernelMkCheckerSession ctorEnv []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let pairValue : PsKernelExpr :=
    .app (.app (.app (.const ctorName []) sort)
      (c0DeltaNatLit 11)) (c0DeltaNatLit 22)
  c0StructuralCheck "projection-field-zero-with-parameter"
    ctorSession (.proj pairType 0 pairValue) (c0DeltaNatLit 11)
  c0StructuralCheck "projection-field-one-with-parameter"
    ctorSession (.proj pairType 1 pairValue) (c0DeltaNatLit 22)
  let badType := c0DeltaName "C0UnrelatedStructure"
  c0StructuralCheck "projection-wrong-type-remains-neutral"
    ctorSession (.proj badType 1 pairValue) (.proj badType 1 pairValue)
  c0StructuralCheck "projection-invalid-field-remains-neutral"
    ctorSession (.proj pairType 3 pairValue) (.proj pairType 3 pairValue)
  let recordBinder := c0DeltaName "record"
  let projectionLambda : PsKernelExpr :=
    .lam recordBinder type (.proj pairType 1 (.bvar 0)) .default
  c0StructuralCheck "projection-captured-beta-scrutinee"
    ctorSession (.app projectionLambda pairValue) (c0DeltaNatLit 22)
  c0StructuralCheck "projection-captured-zeta-scrutinee"
    ctorSession (.letE recordBinder type pairValue
      (.proj pairType 0 (.bvar 0)) false) (c0DeltaNatLit 11)
  match psKernelC0ArchitectureCandidateStructural 0 ctorSession.context
      (.proj pairType 1 pairValue) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "structural candidate accepted exhausted fuel")
  -- CDE-4: nested major premises use one operation-local transition loop.
  let idRecord : PsKernelExpr :=
    .lam recordBinder type (.bvar 0) .default
  c0DemandCheck "nat-demand-nested-add" ctorSession
    (c0DeltaNatBinary psKernelNatAddName (c0DeltaNatLit 1)
      (c0DeltaNatBinary psKernelNatMulName
        (c0DeltaNatLit 6) (c0DeltaNatLit 7)))
    (c0DeltaNatLit 43)
  c0DemandCheck "nat-demand-nested-both-operands" ctorSession
    (c0DeltaNatBinary psKernelNatAddName
      (c0DeltaNatBinary psKernelNatAddName
        (c0DeltaNatLit 5) (c0DeltaNatLit 6))
      (c0DeltaNatBinary psKernelNatMulName
        (c0DeltaNatLit 2) (c0DeltaNatLit 3)))
    (c0DeltaNatLit 17)
  c0DemandCheck "projection-demand-beta-major" ctorSession
    (.proj pairType 1 (.app idRecord pairValue)) (c0DeltaNatLit 22)
  c0DemandCheck "projection-demand-zeta-major" ctorSession
    (.proj pairType 0
      (.letE recordBinder type pairValue (.bvar 0) false))
    (c0DeltaNatLit 11)
  c0DemandCheck "nat-demand-projection-major" ctorSession
    (c0DeltaNatBinary psKernelNatAddName
      (.proj pairType 1 (.app idRecord pairValue)) (c0DeltaNatLit 20))
    (c0DeltaNatLit 42)
  let localNatName := c0DeltaName "C0LocalNatLiteral"
  let natLocalContext := psKernelLocalContextAddLet
    session.context.localContext localNatName localNatName type (c0DeltaNatLit 40)
  let natLocalSession : PsKernelCheckerSession := {
    session with context := {
      session.context with localContext := natLocalContext
    }
  }
  c0DemandCheck "nat-demand-local-let" natLocalSession
    (c0DeltaNatBinary psKernelNatAddName
      (.fvar localNatName) (c0DeltaNatLit 2))
    (c0DeltaNatLit 42)
  let nestedNeutral : PsKernelExpr :=
    c0DeltaNatBinary psKernelNatAddName
      (c0DeltaNatBinary psKernelNatAddName
        (.const (c0DeltaName "UnboundNat") []) (c0DeltaNatLit 2))
      (c0DeltaNatLit 3)
  c0DemandCheck "nested-nat-neutral-preserves-original" ctorSession
    nestedNeutral nestedNeutral
  c0DemandCheck "demand-unrelated-structure-preserves-original"
    ctorSession (.proj badType 1 (.app idRecord pairValue))
    (.proj badType 1 (.app idRecord pairValue))
  -- CDE-5: quotient computation is enabled only by source environment
  -- initialization. These are WHNF-only syntax fixtures, not declarations.
  let quotEnvironment := psKernelEnvironmentMarkQuotInitialized env2
  let quotSession := psKernelMkCheckerSession quotEnvironment []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let quotRelation : PsKernelExpr :=
    .const (c0DeltaName "SyntheticQuotRelation") []
  let quotWitness : PsKernelExpr :=
    .const (c0DeltaName "SyntheticQuotSoundness") []
  let quotMk : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotMkName [.zero])
      [sort, quotRelation, c0DeltaNatLit 41]
  let quotFunction : PsKernelExpr :=
    .lam (c0DeltaName "quotValue") sort (.bvar 0) .default
  let quotLift : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotLiftName [.zero, .zero])
      [sort, quotRelation, sort, quotFunction, quotWitness, quotMk]
  let quotInd : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotIndName [.zero])
      [sort, quotRelation, sort, quotFunction, quotMk]
  c0DemandCheck "quot-lift-direct-constructor" quotSession
    quotLift (c0DeltaNatLit 41)
  c0DemandCheck "quot-ind-direct-constructor" quotSession
    quotInd (c0DeltaNatLit 41)
  let quotBinder := c0DeltaName "quotMajor"
  let quotIdentity : PsKernelExpr :=
    .lam quotBinder sort (.bvar 0) .default
  let delayedMajor : PsKernelExpr :=
    .app quotIdentity quotMk
  let quotLiftDelayed : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotLiftName [.zero, .zero])
      [sort, quotRelation, sort, quotFunction, quotWitness, delayedMajor]
  c0DemandCheck "quot-lift-beta-major" quotSession
    quotLiftDelayed (c0DeltaNatLit 41)
  let quotIndDelayed : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotIndName [.zero])
      [sort, quotRelation, sort, quotFunction,
        .letE quotBinder sort quotMk (.bvar 0) false]
  c0DemandCheck "quot-ind-zeta-major" quotSession
    quotIndDelayed (c0DeltaNatLit 41)
  c0DemandCheck "quot-lift-extra-argument" quotSession
    (.app quotLift (c0DeltaNatLit 8))
    (.app (c0DeltaNatLit 41) (c0DeltaNatLit 8))
  -- No quotient computation may occur without initialization.
  c0DemandCheck "quot-uninitialized-neutral" session
    quotLift quotLift
  let quotMkTooShort : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotMkName [.zero])
      [sort, quotRelation]
  let quotLiftStuck : PsKernelExpr :=
    psKernelExprApplyArgsCheap (.const psKernelQuotLiftName [.zero, .zero])
      [sort, quotRelation, sort, quotFunction, quotWitness, quotMkTooShort]
  c0DemandCheck "quot-constructor-wrong-arity" quotSession
    quotLiftStuck quotLiftStuck
  match psKernelC0ArchitectureCandidateDemand 2 quotSession.context
      quotLiftDelayed with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "nested Quot demand ignored shared fuel")
  IO.println "C0_ARCHITECTURE shared_budget_quot_lift_ind_differential=pass"

  match psKernelC0ArchitectureCandidateDemand 3 ctorSession.context
      (c0DeltaNatBinary psKernelNatAddName
        (c0DeltaNatLit 1)
        (c0DeltaNatBinary psKernelNatMulName
          (c0DeltaNatLit 6) (c0DeltaNatLit 7))) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "nested demand reset or ignored shared fuel")
  IO.println "C0_ARCHITECTURE shared_demand_stack_source_differential=pass"
  IO.println "C0_ARCHITECTURE local_let_constructor_projection_differential=pass"
  IO.println "C0_ARCHITECTURE checked_delta_and_closure_spine_differential=pass"
  IO.println "C0_ARCHITECTURE bounded_nat_literal_spine_differential=pass"
  IO.println "C0_ARCHITECTURE opaque_and_resource_boundaries=pass"
