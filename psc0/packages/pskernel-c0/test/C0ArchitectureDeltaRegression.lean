import Ps.KernelCore.Architecture.Delta
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
  let universe := c0DeltaName "u"
  let polymorphic := c0DeltaName "C0PolymorphicAlias"
  let poly : PsKernelDefinitionInfo := {
    base := {
      name := polymorphic
      levelParams := [universe]
      type := .sort (.succ (.param universe))
    }
    value := .sort (.param universe)
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
  IO.println "C0_ARCHITECTURE checked_delta_and_closure_spine_differential=pass"
  IO.println "C0_ARCHITECTURE opaque_and_resource_boundaries=pass"
