import PSKernelFast.GeneralPiFormation
import PSKernelFast.DependentSortFragment

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError message

private def expectCertifiedType (params : List KName)
    (expr expected : KExpr) : IO Unit :=
  match inferClosedGeneralPiCertified params expr with
  | .ok checked => do
      require (checked.val == expected)
        "certified inferred type disagrees with earlier judgment"
      require (checked.val.closedInput params)
        "certified inferred type escaped declaration scope"
  | .error _ =>
      throw (IO.userError "expected scope-certified type was declined")

private def expectCertifiedError (params : List KName)
    (expr : KExpr) (expected : GeneralPiError) : IO Unit :=
  match inferClosedGeneralPiCertified params expr with
  | .error actual =>
      require (actual == expected) "certified typing failure category changed"
  | .ok _ =>
      throw (IO.userError "invalid/unsupported certified typing accepted")

private def expectType (actual : Except GeneralPiError KExpr)
    (expected : KExpr) : IO Unit :=
  match actual with
  | .ok inferred =>
      require (inferred == expected)
        "general Pi formation produced a wrong inferred type"
  | .error _ => throw <| IO.userError "valid Pi formation was declined"

private def expectError (actual : Except GeneralPiError KExpr)
    (expected : GeneralPiError) : IO Unit :=
  match actual with
  | .error kind =>
      require (kind == expected) "general Pi failure category changed"
  | .ok _ => throw <| IO.userError
      "malformed or unsupported general Pi was accepted"

/--
Test general well-formed non-Sort domain types and dependent term binders.
These results are only from the three-rule fragment, not Lean kernel admission.
-/
def generalPiFormationSmoke : IO Unit := do
  let a : KName := .str .anonymous "A"
  let x : KName := .str .anonymous "x"
  let f : KName := .str .anonymous "f"
  let u : KName := .str .anonymous "u"
  let unknown : KName := .str .anonymous "unknown"

  let one : ULevel := .succ .zero
  let two : ULevel := .succ one
  let dependent : KExpr :=
    .forallE a (.sort one)
      (.forallE x (.bvar 0) (.bvar 1) .default) .default
  let expectedDependent : KExpr :=
    .sort (.imax two (.imax one one))
  require (dependent.closedInput [])
    "well-formed dependent example failed closed-input preflight"
  expectType (inferClosedGeneralPi [] dependent) expectedDependent

  -- A Pi expression is a legal binder domain once independently inferred
  -- to have Sort type; earlier Sort-only-context code could not express it.
  let functionDomain : KExpr :=
    .forallE a (.sort .zero) (.sort .zero) .default
  let generalDomain : KExpr :=
    .forallE f functionDomain (.sort .zero) .default
  let expectedGeneral : KExpr :=
    .sort (.imax (.imax one one) one)
  expectType (inferClosedGeneralPi [] generalDomain) expectedGeneral

  let ordinary : KExpr :=
    .forallE a (.sort (.param u)) (.bvar 0) .default
  let expectedOrdinary : KExpr :=
    .sort (.imax (.succ (.param u)) (.param u))
  expectType (inferClosedGeneralPi [u] ordinary) expectedOrdinary
  match inferClosedDependentSort [u] ordinary with
  | .ok level =>
      require (expectedOrdinary == .sort level)
        "general inference disagreed with earlier Sort-only dependent fragment"
  | .error _ =>
      throw <| IO.userError "previous certified dependent fragment declined"

  -- Lambda introduction: the type is synthesized from ACTUAL checked body
  -- inference, not a caller-supplied Pi or inferred-only advertisement.
  let identity : KExpr :=
    .lam a (.sort one)
      (.lam x (.bvar 0) (.bvar 0) .default) .default
  expectType (inferClosedGeneralPi [] identity) dependent

  let simpleLambda : KExpr :=
    .lam a (.sort one) (.bvar 0) .default
  expectType (inferClosedGeneralPi [] simpleLambda)
    (.forallE a (.sort one) (.sort one) .default)

  let unknownLambda : KExpr :=
    .lam a (.sort (.param unknown)) (.bvar 0) .default
  expectError (inferClosedGeneralPi [] unknownLambda) .malformed
  let unsupportedLambdaBody : KExpr :=
    .lam a (.sort .zero)
      (.app (.bvar 0) (.sort .zero)) .default
  expectError (inferClosedGeneralPi [] unsupportedLambdaBody) .unsupported

  -- Application: an affirmative result requires both inferred function Pi
  -- shape and EXACT equality of the checked argument type to its domain.
  let applied : KExpr := .app identity (.sort .zero)
  let expectedAppliedType : KExpr :=
    .forallE x (.sort .zero) (.sort .zero) .default
  expectType (inferClosedGeneralPi [] applied) expectedAppliedType

  let idHigher : KExpr :=
    .lam a (.sort two) (.lam x (.bvar 0) (.bvar 0) .default) .default
  let twoApplications : KExpr :=
    .app (.app idHigher (.sort one)) (.sort .zero)
  expectType (inferClosedGeneralPi [] twoApplications) (.sort one)

  let mismatchedArg : KExpr := .app identity (.sort one)
  expectError (inferClosedGeneralPi [] mismatchedArg) .unsupported
  let invalidHead : KExpr := .app (.sort .zero) (.sort .zero)
  expectError (inferClosedGeneralPi [] invalidHead) .unsupported
  let malformedArg : KExpr := .app identity (.bvar 0)
  expectError (inferClosedGeneralPi [] malformedArg) .malformed

  -- Let typing: the declared type is checked as a Sort and the value
  -- must infer EXACTLY that type. Type substitution uses G4.3's
  -- certified capture-avoiding reference substitution.
  let simpleLet : KExpr :=
    .letE a (.sort one) (.sort .zero) (.bvar 0) false
  expectType (inferClosedGeneralPi [] simpleLet) (.sort one)

  let dependentLet : KExpr :=
    .letE a (.sort two) (.sort one)
      (.lam x (.bvar 0) (.bvar 0) .default) false
  let expectedLetType : KExpr :=
    .forallE x (.sort one) (.sort one) .default
  expectType (inferClosedGeneralPi [] dependentLet) expectedLetType

  let mismatchedLet : KExpr :=
    .letE a (.sort one) (.sort one) (.bvar 0) false
  expectError (inferClosedGeneralPi [] mismatchedLet) .unsupported

  let badLetValue : KExpr :=
    .letE a (.sort one) (.bvar 0) (.bvar 0) false
  expectError (inferClosedGeneralPi [] badLetValue) .malformed

  let nondepLet : KExpr :=
    .letE a (.sort one) (.sort .zero) (.sort .zero) true
  expectError (inferClosedGeneralPi [] nondepLet) .unsupported

  -- Context formation has to run actual inference: it cannot be extended
  -- by a dangling variable or a lambda with no applicable type rule.
  let empty := GeneralPiContext.empty []
  require ((empty.extend (.bvar 0)).isNone)
    "unbound context variable was admitted"
  require ((empty.extend (.lam a (.sort .zero) (.bvar 0) .default)).isNone)
    "unsupported lambda was admitted as a context domain"
  match empty.extend (.sort one) with
  | none => throw <| IO.userError "valid first context domain rejected"
  | some context1 =>
      match context1.extend (.bvar 0) with
      | none => throw (IO.userError "dependent variable domain was declined")
      | some context2 =>
          match context2.infer (.bvar 0) with
          | none => throw <| IO.userError "certified context lookup failed"
          | some inferred =>
              require (inferred.val == .bvar 1)
                "context lookup failed to shift a dependent binder type"
          match context2.infer (.bvar 1) with
          | none => throw <| IO.userError "outer context lookup failed"
          | some inferred =>
              require (inferred.val == .sort one)
                "outer binder type incorrectly shifted"
          require ((context1.infer (.bvar 1)).isNone)
            "immutable parent context changed after extension"

  expectError (inferClosedGeneralPi [] (.bvar 0)) .malformed
  expectError (inferClosedGeneralPi []
    (.forallE a (.bvar 0) (.sort .zero) .default)) .malformed
  expectError (inferClosedGeneralPi [u]
    (.forallE a (.sort (.param unknown)) (.sort .zero) .default))
    .malformed
  expectError (inferClosedGeneralPi []
    (.forallE a (.sort .zero)
      (.app (.bvar 0) (.sort .zero)) .default)) .unsupported
  expectError (inferClosedGeneralPi []
    (.forallE a (.sort .zero)
      (.lam x (.sort .zero) (.bvar 0) .default) .default)) .unsupported

  -- The strict entry point checks the exact *output* scope, in addition to
  -- the source and the independently certified fragment rules.
  expectCertifiedType [] dependent expectedDependent
  expectCertifiedType [] identity dependent
  expectCertifiedType [] twoApplications (.sort one)
  expectCertifiedType [] dependentLet expectedLetType
  expectCertifiedError [] mismatchedArg .unsupported
  expectCertifiedError [] badLetValue .malformed
  expectCertifiedError [] nondepLet .unsupported
  IO.println "PSKernel-Fast G4.4 source/output scoped certificates PASS"

  IO.println "PSKernel-Fast G4.4 certified Pi/lambda/app/restricted-let fragment PASS"
  IO.println "G4.4 limits: syntactic type equality only; no DefEq/constants/nondep-let/admission"

end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.generalPiFormationSmoke
