import Ps.KernelCore.API.VerifiedProvider

/-!
Phase E.4I: source-equivalent independent Nat/String literal DefEq.

This checks the complete closed-form C0 literal comparison, exact source
result/cache proof receipts, Unicode content, recursion/resource guards,
and the separation between an untyped raw conversion query and a fully
type-checked verified-provider operation.
-/

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "literal DefEq source genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "literal DefEq work certification failed")
  let three : PsKernelExpr := .lit (.nat 3)
  let five : PsKernelExpr := .lit (.nat 5)
  let hello : PsKernelExpr := .lit (.str "hello")
  let world : PsKernelExpr := .lit (.str "world")
  let unicode : PsKernelExpr := .lit (.str "λ世界")

  -- Every selected direct result has an exact source DefEq equation
  -- on this checker state, including every positive cache insertion.
  for leftNat in [:5] do
    for rightNat in [:5] do
      let left : PsKernelExpr := .lit (.nat leftNat)
      let right : PsKernelExpr := .lit (.nat rightNat)
      let receipt ← match psKernelC0CertifiedWorkDefEqQualifiedOwned
          4096 work left right with
        | .ok value => pure value
        | .error e =>
            throw (IO.userError ("literal Nat source comparison failed: " ++ e))
      let _sourceEquation :
          psKernelC0CertifiedWorkDefEq 4096 work left right =
            .ok receipt.val :=
        receipt.property
      if receipt.val.fst != (leftNat == rightNat) then
        throw (IO.userError "Nat literal equality changed source result")
      if receipt.val.fst &&
          !psKernelExprPairSetContains
            receipt.val.snd.raw.checker.state.success left right then
        throw (IO.userError "equal Nat literals lost positive source cache")

  let textValues := ["", "hello", "world", "λ世界"]
  for leftText in textValues do
    for rightText in textValues do
      let left : PsKernelExpr := .lit (.str leftText)
      let right : PsKernelExpr := .lit (.str rightText)
      let receipt ← match psKernelC0CertifiedWorkDefEqQualifiedOwned
          4096 work left right with
        | .ok value => pure value
        | .error e =>
            throw (IO.userError ("String literal source comparison failed: " ++ e))
      let _sourceEquation :
          psKernelC0CertifiedWorkDefEq 4096 work left right =
            .ok receipt.val :=
        receipt.property
      if receipt.val.fst != (leftText == rightText) then
        throw (IO.userError "Unicode String literal source semantics changed")

  if (psKernelC0LiteralDefEqWithFuel 4096 checker.context checker.state
      (.nat 3) (.nat 5)).isNone then
    throw (IO.userError "unequal literals unexpectedly declined closed-form rule")
  let unequal ← match psKernelC0CertifiedWorkDefEqLiteralOwned
      4096 work (.nat 3) (.nat 5) with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("unequal Nat conversion failed: " ++ e))
  let _unequalProof :
      psKernelC0CertifiedWorkDefEq 4096 work three five =
        .ok unequal.val :=
    unequal.property
  if unequal.val.fst then
    throw (IO.userError "distinct Nat literals were falsely convertible")
  let textSame ← match psKernelC0CertifiedWorkDefEqLiteralOwned
      4096 work (.str "λ世界") (.str "λ世界") with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("equal Unicode literal failed: " ++ e))
  if !textSame.val.fst ||
      !psKernelExprPairSetContains
        textSame.val.snd.raw.checker.state.success unicode unicode then
    throw (IO.userError "Unicode equality lost positive source cache")
  let textDiff ← match psKernelC0CertifiedWorkDefEqLiteralOwned
      4096 work (.str "hello") (.str "world") with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("different String comparison failed: " ++ e))
  if textDiff.val.fst ||
      psKernelExprEqual hello world then
    throw (IO.userError "different String literals were accepted as equal")

  -- Even arbitrary caller-constructed raw success caches must yield the
  -- SAME result/state as original source DefEq, while verified providers
  -- never import that raw state as an accepting proof authority.
  let forgedCache := psKernelExprPairSetInsert checker.state.success three five
  let forgedState := psKernelCheckerStateWithSuccess checker.state forgedCache
  match psKernelC0LiteralDefEqWithFuel 4096 checker.context forgedState
      (.nat 3) (.nat 5) with
  | some (true, _) => pure ()
  | _ => throw (IO.userError "direct literal rule changed raw source cache behavior")

  match psKernelC0CertifiedWorkDefEqLiteralOwned 0 work (.nat 3) (.nat 3) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "literal equality bypassed source zero fuel")
  let exhaustedChecker : PsKernelCheckerSession := {
    checker with
    context := {
      checker.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  if (psKernelC0LiteralDefEqWithFuel 4096 exhaustedChecker.context
      exhaustedChecker.state (.nat 3) (.nat 3)).isSome then
    throw (IO.userError "literal equality bypassed source recursion limit")

  -- Conversion of raw literal syntax is never sufficient to establish
  -- checked status. Nat/String built-in typing must agree with the actual
  -- source checker, and a malformed application containing literals must
  -- fail full provider checking even when its two inputs are identical.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let verified ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "literal verified provider genesis failed")
  for literal in [three, hello] do
    let sourceChecked := psKernelSessionCheck resources.fuel
      (psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe
        resources.maxRecDepth resources.maxNatSize) literal
    let providerChecked := psKernelC0VerifiedProviderCheck verified literal
    match sourceChecked, providerChecked with
    | .ok (sourceType, _), .ok (providerType, _) =>
        if !psKernelExprEqual sourceType providerType then
          throw (IO.userError "source/provider checked literal type mismatch")
    | .error _, .error _ => pure ()
    | _, _ =>
        throw (IO.userError "verified literal full checking diverged from source")
  let malformedLiteralApp : PsKernelExpr := .app three three
  match psKernelC0VerifiedProviderDefEq verified
      malformedLiteralApp malformedLiteralApp with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "reflexive literal application bypassed full checking")

  IO.println "C0_LITERAL_DEFEQ full_nat_string_unicode_comparison_matrix=pass"
  IO.println "C0_LITERAL_DEFEQ source_equation_positive_cache_and_limits=pass"
  IO.println "C0_LITERAL_DEFEQ no_unchecked_literal_provider_publication=pass"
