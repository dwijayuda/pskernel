import PSKernelFast.Substitution

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError message

private def expectFailure (result : Except ScopedError α)
    (error : ScopedError) : IO Unit :=
  match result with
  | .error actual => require (actual == error) "scope failure category changed"
  | .ok _ => throw <| IO.userError "malformed binder was unexpectedly stored"

private def expectScopedDomain {params : List KName} {depth : Nat}
    (result : Option {domain : KExpr //
      KExpr.StructurallyValid params depth domain})
    (expected : KExpr) : IO Unit :=
  match result with
  | none => throw <| IO.userError "certified binder domain was absent"
  | some domain =>
      require (domain.val == expected) "certified binder domain shifted incorrectly"

/-- Runtime structural-only behavior; the type signature carries the proof. -/
private def expectOk (result : Except ScopedError (AnyScopedFrame params)) :
    IO (AnyScopedFrame params) :=
  match result with
  | .ok frame => pure frame
  | .error _ => throw <| IO.userError "valid binder entry was declined"

/-- Scope *structure* and unchanged-parent regression, not dependent typing. -/
def scopedContextSmoke : IO Unit := do
  let u : KName := .str .anonymous "u"
  let v : KName := .str .anonymous "v"
  let outer := AnyScopedFrame.empty [u]

  require (outer.depth == 0 && (outer.rawDomainAt 0).isNone)
    "empty local context contained a binder"
  expectFailure (outer.extend (.bvar 0)) .malformedBinder
  expectFailure (outer.extend (.sort (.param v))) .malformedBinder
  expectFailure (outer.extend (.mvar u)) .malformedBinder

  let c1 ← expectOk <| outer.extend (.sort (.param u))
  require (c1.depth == 1) "scoped parent depth not incremented"
  require (c1.rawDomainAt 0 == some (.sort (.param u)))
    "stored outer binder domain lost"
  require (outer.depth == 0 && (outer.rawDomainAt 0).isNone)
    "immutable parent was changed by extension"

  let c2 ← expectOk <| c1.extend (.bvar 0)
  require (c2.depth == 2) "second binder depth not incremented"
  require (c2.rawDomainAt 0 == some (.bvar 0))
    "newest raw binder domain was not stored exactly"
  require (c2.rawDomainAt 1 == some (.sort (.param u)))
    "outer raw binder domain was lost"
  require ((c2.rawDomainAt 2).isNone)
    "nonexistent binder index was accepted"

  expectFailure (c2.extend (.bvar 2)) .malformedBinder
  expectFailure (c2.extend (.fvar u)) .malformedBinder
  let c3 ← expectOk <| c2.extend (.bvar 1)
  require (c3.depth == 3) "third binder did not increment depth"
  require (c2.depth == 2 && (c2.rawDomainAt 2).isNone)
    "failed or successful extension mutated prior scope"


  -- Lifting is structural: outer free variables shift, local binder indices do not.
  let original : KExpr :=
    .lam u (.sort (.param u)) (.app (.bvar 1) (.bvar 0)) .default
  let shifted : KExpr := original.liftBVars 2 0
  let expected : KExpr :=
    .lam u (.sort (.param u)) (.app (.bvar 3) (.bvar 0)) .default
  require (original.validAt [u] 1) "lift fixture was not valid in its original scope"
  require (shifted == expected && shifted.validAt [u] 3)
    "lambda lifting captured or failed to shift an outer variable"

  let layered : KExpr :=
    .forallE u (.sort (.param u))
      (.letE u (.sort (.param u)) (.bvar 1) (.bvar 2) false) .default
  let liftedLayered := layered.liftBVars 2 0
  let expectedLayered : KExpr :=
    .forallE u (.sort (.param u))
      (.letE u (.sort (.param u)) (.bvar 3) (.bvar 4) false) .default
  require (layered.validAt [u] 1) "Pi/let lifting fixture is unscoped"
  require (liftedLayered == expectedLayered &&
    liftedLayered.validAt [u] 3)
    "Pi/let lifting shifted a local binder or lost an outer variable"

  -- A stored binder domain is from its parent context: index 0 must be
  -- raised by one before inspecting it in the extended context.
  let rawDomain := c2.rawDomainAt 0
  require (rawDomain == some (.bvar 0)) "scope fixture unexpectedly changed"
  require (((.bvar 0 : KExpr).liftBVars 1 0) == .bvar 1)
    "stored-domain reference lifting failed"


  -- Every observed domain is shifted from its ORIGINAL parent context.
  -- The returned subtype carries the actual current-depth scoping proof.
  expectScopedDomain (c1.scopedDomainAt 0) (.sort (.param u))
  expectScopedDomain (c2.scopedDomainAt 0) (.bvar 1)
  expectScopedDomain (c2.scopedDomainAt 1) (.sort (.param u))
  expectScopedDomain (c3.scopedDomainAt 0) (.bvar 2)
  expectScopedDomain (c3.scopedDomainAt 1) (.bvar 2)
  expectScopedDomain (c3.scopedDomainAt 2) (.sort (.param u))
  require ((c3.scopedDomainAt 3).isNone)
    "out-of-range certified binder lookup unexpectedly succeeded"

  -- New independent reference instantiation: variable capture is forbidden.
  let sortZero : KExpr := .sort .zero
  let simpleBody : KExpr := .app (.bvar 0) (.bvar 2)
  let simpleResult : KExpr := .app sortZero (.bvar 1)
  require (simpleBody.validAt [u] 3)
    "ordinary substitution fixture was not structurally valid"
  require (simpleBody.instantiateBVar sortZero 0 == simpleResult &&
    simpleResult.validAt [u] 2)
    "substitution did not replace target and decrement outer index"

  let outerReplacement : KExpr := .bvar 1
  let nestedBody : KExpr :=
    .lam u sortZero (.app (.bvar 0) (.bvar 1)) .default
  let expectedNested : KExpr :=
    .lam u sortZero (.app (.bvar 0) (.bvar 2)) .default
  require (nestedBody.validAt [u] 3 &&
    outerReplacement.validAt [u] 2)
    "nested substitution fixture invalid"
  require (nestedBody.instantiateBVar outerReplacement 0 == expectedNested &&
    expectedNested.validAt [u] 2)
    "substitution captured a local lambda variable"

  let piLetBody : KExpr :=
    .forallE u sortZero
      (.letE u sortZero (.bvar 1)
        (.app (.bvar 0) (.bvar 2)) false) .default
  let expectedPiLet : KExpr :=
    .forallE u sortZero
      (.letE u sortZero (.bvar 2)
        (.app (.bvar 0) (.bvar 3)) false) .default
  require (piLetBody.validAt [u] 3 &&
    piLetBody.instantiateBVar outerReplacement 0 == expectedPiLet &&
    expectedPiLet.validAt [u] 2)
    "Pi/let binder substitution failed lifting, scope or decrement"

  let wrapped : KExpr := .mdata 27 (.proj u 0 (.bvar 0))
  let expectedWrapped : KExpr := .mdata 27 (.proj u 0 sortZero)
  require (wrapped.instantiateBVar sortZero 0 == expectedWrapped)
    "reference substitution skipped metadata/projection wrapper"
  require (!(KExpr.validAt [u] 1 (.bvar 2)))
    "malformed substitution body was not classified unscoped"

  match KExpr.instantiateTopScoped [u] 2 simpleBody sortZero with
  | .ok certified =>
      require (certified.val == simpleResult)
        "checked-scope substitution result differs from reference substitution"
  | .error _ =>
      throw <| IO.userError "valid checked-scope substitution rejected"

  match KExpr.instantiateTopScoped [u] 0 (.bvar 2) sortZero with
  | .error .malformedBody => pure ()
  | _ => throw <| IO.userError "malformed substitution body was accepted"

  match KExpr.instantiateTopScoped [u] 0 (.bvar 0) (.bvar 0) with
  | .error .malformedReplacement => pure ()
  | _ => throw <| IO.userError "malformed substitution replacement was accepted"

  match KExpr.instantiateTopScoped [u] 0 (.sort (.param v)) sortZero with
  | .error .malformedBody => pure ()
  | _ => throw <| IO.userError "undeclared level parameter bypassed preflight"
  IO.println "PSKernel-Fast G4.3: checked-scope substitution rejection PASS"

  IO.println "PSKernel-Fast G4.3 substitution: capture-avoiding cases PASS"

  IO.println "PSKernel-Fast G4.3: scope-certified current-context lookup PASS"

  IO.println "PSKernel-Fast G4.3 lifting: scoped capture-avoidance tests PASS"

  IO.println "PSKernel-Fast G4.3: proof-carrying structural binder frame PASS"
  IO.println "G4.3 limit: stored domains are raw observations, not inferred types"
end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.scopedContextSmoke
