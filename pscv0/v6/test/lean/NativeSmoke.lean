import Pscv.Kernel.Checker
import Pscv.Extensions.Policy

namespace Pscv.NativeSmoke

def name (s : String) : Lean.Name := .str .anonymous s

def identityType : Lean.Expr :=
  .forallE (name "P") (.sort .zero)
    (.forallE (name "h") (.bvar 0) (.bvar 1) .default)
    .default

def identityProof (bodyIndex : Nat) : Lean.Expr :=
  .lam (name "P") (.sort .zero)
    (.lam (name "h") (.bvar 0) (.bvar bodyIndex) .default)
    .default

def theoremCandidate (index : Nat) : Pscv.CoreCandidate := {
  sourceId := "native-smoke"
  declarations := #[.thmDecl {
    name := name "IdentityProof"
    levelParams := []
    type := identityType
    value := identityProof index
  }]
}

def unapprovedAxiomCandidate : Pscv.CoreCandidate := {
  sourceId := "untrusted-extension"
  declarations := #[.axiomDecl {
    name := name "FalseProofFromUnapprovedAxiom"
    levelParams := []
    type := .sort .zero
    isUnsafe := false
  }]
}

def extension : Pscv.Extensions.Descriptor := {
  name := "@example/syntax"
  className := .syntax
  execution := .isolatedProcess
  apiIdentity := "pscv-extension/1"
}

def mainTest : IO Bool := do
  let accepted ← Pscv.Kernel.checkCandidate (theoremCandidate 0)
  let rejected ← Pscv.Kernel.checkCandidate (theoremCandidate 1)
  let axiomRejected ← Pscv.Kernel.checkCandidate unapprovedAxiomCandidate
  let good := match accepted with
    | .ok report => report.checkedDeclarations == 1
    | .error _ => false
  let bad := match rejected with
    | .error _ => true
    | .ok _ => false
  let axiomDenied := match axiomRejected with
    | .error error => error == "PSCV_CLOSED_PROFILE_AXIOM_DENIED"
    | .ok _ => false
  let closedRejects := match Pscv.Extensions.validate .verified extension with
    | .error _ => true
    | .ok _ => false
  let extensibleAccepts := match Pscv.Extensions.validate .leanExtensible extension with
    | .ok _ => true
    | .error _ => false
  let semanticDenied := match Pscv.Extensions.validate .leanExtensible {
    extension with className := .semanticElaborator
  } with
    | .error _ => true
    | .ok _ => false
  return good && bad && axiomDenied && closedRejects && extensibleAccepts && semanticDenied

end Pscv.NativeSmoke

def main : IO UInt32 := do
  if ← Pscv.NativeSmoke.mainTest then
    IO.println "PSCV_V6_NATIVE_KERNEL_AND_EXTENSION_SMOKE: PASS"
    return 0
  else
    IO.eprintln "PSCV_V6_NATIVE_KERNEL_AND_EXTENSION_SMOKE: FAIL"
    return 1
