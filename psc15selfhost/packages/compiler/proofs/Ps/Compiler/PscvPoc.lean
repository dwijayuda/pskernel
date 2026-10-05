import Ps.Compiler.Api

/-
PSCV self-host proof-of-concept.

This theorem records a real definitional relationship in the current compiler API
without changing the runtime compiler or its bootstrap prelude.

The premise is a reflexive equality witness for the preparation result. The proof
term is just that witness. It checks against the conclusion only because
`psCompilerCheckElaborated elaborated` unfolds definitionally to
`psCompilerPrepareElaborated elaborated`.

The PoC therefore demonstrates that a proof-only module can state and check a
property of the existing compiler while staying outside the executable self-host
closure. It does NOT claim that AdmissionReady is kernel-checked.
-/
theorem pscvPocCheckElaboratedIsPrepare
    (elaborated : PsElabModuleResult)
    (h :
      psCompilerPrepareElaborated elaborated =
        psCompilerPrepareElaborated elaborated) :
    psCompilerCheckElaborated elaborated =
      psCompilerPrepareElaborated elaborated :=
  h
