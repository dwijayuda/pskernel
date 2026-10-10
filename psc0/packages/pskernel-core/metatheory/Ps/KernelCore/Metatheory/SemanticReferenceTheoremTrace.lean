import Ps.KernelCore.Metatheory.SemanticReferenceTheoremAdmission

/-!
Execution-derived evidence for the real safe-theorem admission path.

This is NOT a theorem about semantic validity of the accepted proof.
It records the exact results and checker sessions selected by the already
executed PSKernel reference checker. The full mutual inference/WHNF/DefEq
soundness theorem must consume these readings, then justify a model of the
new theorem without postulating it.

A theorem trace cannot be constructed from an arbitrary raw syntax
certificate; it is extracted from the concrete successful admission run.
-/
namespace PsKernelSemantics.SetModel

/-- The header, proposition test, guards, checked proof, definitional
equality and final insertion actually executed in a successful theorem
admission, with the same source and returned sessions at every step. -/
structure ReferenceTheoremAdmissionTrace
    (fuel : Nat) (env : PsKernelEnvironment)
    (value : PsKernelTheoremInfo) (maxDepth maxNatSize : Nat)
    (next : PsKernelEnvironment) : Prop where
  headerSession : PsKernelCheckerSession
  propositionSession : PsKernelCheckerSession
  guardWitness : Unit
  levelWitness : Unit
  inferredType : PsKernelExpr
  proofSession : PsKernelCheckerSession
  equalitySession : PsKernelCheckerSession
  headerRun : @psKernelCheckConstantBaseWithSession psKernelReferenceCachePolicy
    fuel (psKernelMkCheckerSession env value.base.levelParams
      PsKernelDefinitionSafety.safe maxDepth maxNatSize)
    value.base = .ok headerSession
  propositionRun : @psKernelSessionIsProp psKernelReferenceCachePolicy
    fuel headerSession value.base.type = .ok (true, propositionSession)
  variableGuard : psKernelCheckNoMVarNoFVar value.value = .ok guardWitness
  universeGuard :
    psKernelCheckLevelParams value.value value.base.levelParams = .ok levelWitness
  proofRun : @psKernelSessionCheck psKernelReferenceCachePolicy
    fuel propositionSession value.value = .ok (inferredType, proofSession)
  equalityRun : @psKernelSessionIsDefEq psKernelReferenceCachePolicy
    fuel proofSession inferredType value.base.type = .ok (true, equalitySession)
  insertionRun : psKernelEnvironmentAdd env (.thmInfo value) = .ok next

/-- Invert the FULL executed safe-theorem admission, keeping every selected
intermediate checker result. No one can construct this from a favorable
annotation alone; failure and resource-decline paths have no trace. -/
theorem referenceAddTheorem_success_trace
    (fuel : Nat) (env next : PsKernelEnvironment)
    (value : PsKernelTheoremInfo) (maxDepth maxNatSize : Nat)
    (run : @psKernelAddTheorem psKernelReferenceCachePolicy
      fuel env value maxDepth maxNatSize = .ok next) :
    ReferenceTheoremAdmissionTrace fuel env value maxDepth maxNatSize next := by
  have inserted := referenceAddTheorem_returns_insert
    fuel env next value maxDepth maxNatSize run
  cases hHeader : @psKernelCheckConstantBaseWithSession
      psKernelReferenceCachePolicy fuel
      (psKernelMkCheckerSession env value.base.levelParams
        PsKernelDefinitionSafety.safe maxDepth maxNatSize) value.base with
  | error err =>
      simp [psKernelAddTheorem, hHeader] at run
  | ok header =>
      cases hProp : @psKernelSessionIsProp psKernelReferenceCachePolicy
          fuel header value.base.type with
      | error err =>
          simp [psKernelAddTheorem, hHeader, hProp] at run
      | ok proposition =>
          rcases proposition with ⟨propBool, propSession⟩
          cases propBool with
          | false =>
              simp [psKernelAddTheorem, hHeader, hProp] at run
          | true =>
              cases hGuard : psKernelCheckNoMVarNoFVar value.value with
              | error err =>
                  simp [psKernelAddTheorem, hHeader, hProp, hGuard] at run
              | ok guard =>
                  cases hLevels : psKernelCheckLevelParams
                      value.value value.base.levelParams with
                  | error err =>
                      simp [psKernelAddTheorem, hHeader, hProp,
                        hGuard, hLevels] at run
                  | ok lvl =>
                      cases hProof : @psKernelSessionCheck psKernelReferenceCachePolicy
                          fuel propSession value.value with
                      | error err =>
                          simp [psKernelAddTheorem, hHeader, hProp,
                            hGuard, hLevels, hProof] at run
                      | ok checked =>
                          rcases checked with ⟨proofType, proofSession⟩
                          cases hEq : @psKernelSessionIsDefEq
                              psKernelReferenceCachePolicy fuel proofSession
                              proofType value.base.type with
                          | error err =>
                              simp [psKernelAddTheorem, hHeader, hProp,
                                hGuard, hLevels, hProof, hEq] at run
                          | ok eqResult =>
                              rcases eqResult with ⟨equalBool, eqSession⟩
                              cases equalBool with
                              | false =>
                                  simp [psKernelAddTheorem, hHeader, hProp,
                                    hGuard, hLevels, hProof, hEq] at run
                              | true =>
                                  exact {
                                    headerSession := header
                                    propositionSession := propSession
                                    guardWitness := guard
                                    levelWitness := lvl
                                    inferredType := proofType
                                    proofSession := proofSession
                                    equalitySession := eqSession
                                    headerRun := hHeader
                                    propositionRun := hProp
                                    variableGuard := hGuard
                                    universeGuard := hLevels
                                    proofRun := hProof
                                    equalityRun := hEq
                                    insertionRun := inserted
                                  }

end PsKernelSemantics.SetModel
