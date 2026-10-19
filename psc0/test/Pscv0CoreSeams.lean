import Ps.Environment.Fingerprint
import PsKernelLean.Replay

private def requireSeam (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError message)

private def identityName : PsName := .str .anonymous "CoreSeamIdentity"
private def referenceName : PsName := .str .anonymous "CoreSeamReference"

private def identityType : PsExpr :=
  .forallE (.str .anonymous "p") (.sortE .zero)
    (.forallE (.str .anonymous "proof") (.bvar 0) (.bvar 1) .explicit)
    .explicit

private def identityValue : PsExpr :=
  .lam (.str .anonymous "p") (.sortE .zero)
    (.lam (.str .anonymous "proof") (.bvar 0) (.bvar 0) .explicit)
    .explicit

def main : IO Unit := do
  requireSeam
    (psStandardSnapshotSHA256 "" ==
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    "CORE-SEAM: empty SHA-256 vector changed"
  requireSeam
    (psStandardSnapshotSHA256 "abc" ==
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    "CORE-SEAM: abc SHA-256 vector changed"
  let declarations : List PsDeclaration := [
    .definitionDecl identityName [] identityType identityValue,
    .definitionDecl referenceName [] identityType (.constE identityName [])]
  -- Replay reverses this roster, so the reference is initially deferred.
  let checked ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations declarations
  let environment ← match checked with
    | .ok environment => pure environment
    | .error error => throw (IO.userError error.message)
  requireSeam (environment.find? (PsKernelLean.toLeanName identityName)).isSome
    "CORE-SEAM: checked identity is missing"
  requireSeam (environment.find? (PsKernelLean.toLeanName referenceName)).isSome
    "CORE-SEAM: checked dependent definition is missing"
  requireSeam (!(environment.find? `Nat).isSome)
    "CORE-SEAM: a selected prelude leaked into the fresh kernel"
  let rejected ← PsKernelLean.buildLeanPreludeEnvironmentFromDeclarations [
    .definitionDecl (.str .anonymous "CoreSeamIllTyped") []
      (.sortE .zero) (.sortE .zero)]
  match rejected with
  | .ok _ => throw (IO.userError "CORE-SEAM: ill-typed definition was admitted")
  | .error error =>
      requireSeam (error.kind == .preludeMismatch)
        "CORE-SEAM: unexpected rejection owner"
  IO.println "PSCV0_CORE_SEAMS: isolated fingerprint and trust-zero replay passed"
