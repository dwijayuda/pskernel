import PSKernelFast.Proof.SourceCertificateSynthesis
import PSKernelFast.Proof.SourceModelExecution

/-!
Run the ACTUAL certificate generator on source only. No handwritten proof
certificate is passed to it. Native source checking remains an independently
required success. This corpus is not all-G4.3b certificate completeness.
-/

namespace PSKernelFast.Proof
open PSKernelFast.Core PSKernelFast.Spec

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw (IO.userError message)

private def checkSource (params : List KName) (ρ : KName → Nat)
    (source expectedType : KExpr)
    (expectedAnnotation expectedTypeAnnotation : AnnotatedModelTerm) : IO Unit := do
  let .ok c := certifyClosedModel params ρ source 48
    | throw (IO.userError "source-only certificate construction declined a positive fixture")
  require (c.typing.sourceType == expectedType) "wrong actual inferred source type"
  require (c.typing.termAnnotation == expectedAnnotation) "wrong synthesized source annotation"
  require (c.typing.typeAnnotation == expectedTypeAnnotation) "wrong synthesized type annotation"
  let .ok d := certifyClosedModel params ρ source 64
    | throw (IO.userError "larger-fuel synthesis declined a positive fixture")
  require (c.typing.termAnnotation == d.typing.termAnnotation &&
    c.typing.typeAnnotation == d.typing.typeAnnotation) "fuel changed source annotations"

private def expectError (source : KExpr) (fuel : Nat)
    (expected : ModelCertificateError) : IO Unit := do
  match certifyClosedModel [] (fun _ => 0) source fuel with
  | .error actual => require (actual == expected) "unexpected failure classification"
  | .ok _ => throw (IO.userError "unsupported/malformed/exhausted fixture was accepted")

def sourceCertificateSynthesisSmoke : IO Unit := do
  let ρ : KName → Nat := fun _ => 0
  let s0 : KExpr := .sort .zero
  let s1 : KExpr := .sort (.succ .zero)
  let x : KName := .str .anonymous "x"
  let ident : KExpr := .lam x s1 (.bvar 0) .default
  checkSource [] ρ s0 s1 (.sort 0) (.sort 1)
  checkSource [] ρ sourceBetaFixture s1 betaFixtureAnnotation (.sort 1)
  checkSource [] ρ sourceZetaFixture s1 zetaFixtureAnnotation (.sort 1)
  checkSource [] ρ (polyIdentitySource .zero) (polyIdentitySourceType .zero)
    (polyIdentityAnnotation 0) (polyIdentityTypeAnnotation 0)
  checkSource [] ρ (polyIdentitySource (.succ .zero)) (polyIdentitySourceType (.succ .zero))
    (polyIdentityAnnotation 1) (polyIdentityTypeAnnotation 1)
  checkSource [] ρ (forallPropPropSource x) (.sort (.imax (.succ .zero) .zero))
    (.pi 0 (.sort 0) (.bvar 0)) (.sort 0)

  let parameter : KName := .str .anonymous "u"
  checkSource [parameter] (fun _ => 3) (.sort (.param parameter))
    (.sort (.succ (.param parameter))) (.sort 3) (.sort 4)
  checkSource [parameter] (fun _ => 0) (.sort (.param parameter))
    (.sort (.succ (.param parameter))) (.sort 0) (.sort 1)

  let mut chain := s0
  let mut annotation : AnnotatedModelTerm := .sort 0
  for i in [0:10] do
    checkSource [] ρ chain s1 annotation (.sort 1)
    if i % 2 == 0 then
      chain := .app ident chain
      annotation := .app (.lam 2 (.sort 1) (.bvar 0)) annotation
    else
      chain := .letE x s1 chain (.bvar 0) false
      annotation := .letE (.sort 1) annotation (.bvar 0)

  expectError sourceBetaFixture 0 .fuelExhausted
  expectError sourceBetaFixture 1 .fuelExhausted
  expectError (.bvar 0) 48 .malformed
  expectError (.sort (.param parameter)) 48 .malformed
  expectError (.app ident s1) 48 .unresolved
  expectError (.letE x s1 s0 (.bvar 0) true) 48 .unresolved
  expectError (.const x []) 48 .unresolved

  IO.println "P1q source-only synthesis PASS: 18 positive cases at two fuels; 7 fail-closed controls"
  IO.println "Includes all six forms, proof/data identities, symbolic valuations, generated beta/let chains; no external source certificate"

end PSKernelFast.Proof

def main : IO Unit := PSKernelFast.Proof.sourceCertificateSynthesisSmoke
