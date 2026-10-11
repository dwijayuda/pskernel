import PSKernelFast.GeneralPiFormation
import PSKernelFast.DependentSortFragment

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw <| IO.userError message

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
      | none => throw <| IO.userError
          "dependent variable domain was not accepted after type checking"
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

  IO.println "PSKernel-Fast G4.4 restricted general-domain Pi formation PASS"
  IO.println "G4.4 limits: syntactic Sort only, no DefEq, lambda/app, full checking or admission"

end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.generalPiFormationSmoke
