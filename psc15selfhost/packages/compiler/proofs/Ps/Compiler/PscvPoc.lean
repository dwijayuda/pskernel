import Ps.Compiler.Api

/-
PSCV self-host proof-of-concept.

This theorem records a real property of the current compiler API:
`psCompilerCheckElaborated` is definitionally the same operation as
`psCompilerPrepareElaborated`.

That fact is expected in the current PSC2 bootstrap architecture: preparation is
AdmissionReady, not independent kernel checking. The theorem deliberately makes
that boundary explicit so a later PSCV migration can replace this alias with a
real Checked/Verified capability transition.

The proof is a direct proof term rather than tactic syntax so it is suitable for
translation into the current small ProofScript self-host surface.
-/
theorem pscvPocCheckElaboratedIsPrepare
    (elaborated : PsElabModuleResult) :
    psCompilerCheckElaborated elaborated =
      psCompilerPrepareElaborated elaborated :=
  Eq.refl (psCompilerPrepareElaborated elaborated)
