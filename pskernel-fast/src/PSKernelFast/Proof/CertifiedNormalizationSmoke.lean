import PSKernelFast.Proof.CertifiedNormalization
import PSKernelFast.Proof.SourceModelExecution

namespace PSKernelFast.Proof
open PSKernelFast.Core PSKernelFast.Spec

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw (IO.userError message)

private def checkJoin (lhs rhs expected : KExpr)
    (fuel leftSteps rightSteps : Nat) : IO Unit := do
  let .ok join := compareCertifiedWH [] (fun _ => 0) lhs rhs fuel 64
    | throw (IO.userError "certified closed reduction declined a supported join")
  require (join.left.normal.value == expected && join.right.normal.value == expected)
    "wrong certified common head"
  require (join.left.normal.steps == leftSteps && join.right.normal.steps == rightSteps)
    "wrong certified reduction count"
  require (join.left.normal.certificate.typing.termAnnotation ==
    join.right.normal.certificate.typing.termAnnotation) "incoherent common annotation"
  require (compareTypedWH (GeneralPiContext.empty []) lhs rhs fuel).isEqual
    "existing raw G4.4b path disagreed with supported certified fixture"

private def expectError (lhs rhs : KExpr) (reductions certificates : Nat)
    (expected : ModelCertificateError) : IO Unit := do
  match compareCertifiedWH [] (fun _ => 0) lhs rhs reductions certificates with
  | .ok _ => throw (IO.userError "unresolved, invalid or exhausted join was accepted")
  | .error actual => require (actual == expected) "wrong failure classification"

def certifiedNormalizationSmoke : IO Unit := do
  let x : KName := .str .anonymous "x"
  let a : KName := .str .anonymous "A"
  let p : KName := .str .anonymous "P"
  let q : KName := .str .anonymous "Q"
  let s0 : KExpr := .sort .zero
  let s1 : KExpr := .sort (.succ .zero)
  let s2 : KExpr := .sort (.succ (.succ .zero))
  let ident : KExpr := .lam x s1 (.bvar 0) .default
  let beta := fun e => KExpr.app ident e
  let zeta := fun e => KExpr.letE x s1 e (.bvar 0) false
  let mut chain := s0
  let mut checks : Nat := 0
  for i in [0:12] do
    checkJoin chain s0 s0 (i + 1) i 0
    checkJoin s0 chain s0 (i + 1) 0 i
    checks := checks + 2
    chain := if i % 2 == 0 then beta chain else zeta chain
  checkJoin (beta (zeta s0)) (zeta (beta s0)) s0 3 2 2
  checks := checks + 1

  let higher : KExpr := .lam a s2 (.lam x (.bvar 0) (.bvar 0) .default) .default
  let spine : KExpr := .app (.app higher s1) s0
  checkJoin spine s0 s0 3 2 0
  checks := checks + 1
  let identTy : KExpr := .forallE x s1 s1 .default
  let letHead : KExpr := .app (.letE x identTy ident (.bvar 0) false) s0
  checkJoin letHead s0 s0 3 2 0
  checks := checks + 1

  let proofId := polyIdentitySource .zero
  let dataId := polyIdentitySource (.succ .zero)
  checkJoin proofId proofId proofId 1 0 0
  checkJoin dataId dataId dataId 1 0 0
  let falseType := forallPropPropSource x
  checkJoin falseType falseType falseType 1 0 0
  checks := checks + 3
  require (checks == 30) "positive certified-normalization fixture count changed"

  expectError (beta s0) s0 1 64 .fuelExhausted
  expectError s0 s0 0 64 .fuelExhausted
  expectError (beta s0) s0 2 1 .fuelExhausted
  expectError (.bvar 0) s0 8 64 .malformed
  expectError (.app ident s1) s0 8 64 .unresolved
  expectError (.letE x s1 s0 (.bvar 0) true) s0 8 64 .unresolved
  expectError (.const x []) s0 8 64 .unresolved
  let underBinder : KExpr := .lam x s1 (.app ident (.bvar 0)) .default
  expectError ident underBinder 16 64 .unresolved
  let first : KExpr := .lam p s0 (.lam q s0 (.bvar 1) .default) .default
  let second : KExpr := .lam p s0 (.lam q s0 (.bvar 0) .default) .default
  expectError first second 16 64 .unresolved

  IO.println "P1s certified model normalization PASS: 30 positive joins, 9 fail-closed controls"
  IO.println "Source-only inputs; exact intermediate types; structural annotation transport; existing G4.4b fixture agreement"

end PSKernelFast.Proof

def main : IO Unit := PSKernelFast.Proof.certifiedNormalizationSmoke
