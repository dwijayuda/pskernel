import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
The mutual-inductive transaction adds a checked group of inductive headers
before checking constructors, and later adds the resulting recursor metadata.
Both passes are pure folds over the canonical environment insertion operation.

Each step preserves authoritative index refinement for *arbitrary* public
index roots; no assumption of an initially empty/trie-shaped index is made.
These lemmas do not claim constructor or recursor typing soundness.
-/

theorem psKernelAddMutualInductiveInfos_index_refines
    (infos : List PsKernelInductiveInfo) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelEnvironmentIndexRefines
        (psKernelAddMutualInductiveInfos infos environment) := by
  induction infos with
  | nil =>
      intro environment hIndex
      simpa [psKernelAddMutualInductiveInfos] using hIndex
  | cons info rest ih =>
      intro environment hIndex
      change
        PsKernelEnvironmentIndexRefines
          (psKernelAddMutualInductiveInfos
            rest
            (psKernelEnvironmentAddUnchecked
              environment
              (PsKernelConstantInfo.inductInfo info)))
      exact
        ih
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.inductInfo info))
          (psKernelEnvironmentAddUnchecked_index_refines
            environment (PsKernelConstantInfo.inductInfo info) hIndex)


theorem psKernelAddMutualRecursorInfos_index_refines
    (infos : List PsKernelRecursorInfo) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelEnvironmentIndexRefines
        (psKernelAddMutualRecursorInfos infos environment) := by
  induction infos with
  | nil =>
      intro environment hIndex
      simpa [psKernelAddMutualRecursorInfos] using hIndex
  | cons info rest ih =>
      intro environment hIndex
      change
        PsKernelEnvironmentIndexRefines
          (psKernelAddMutualRecursorInfos
            rest
            (psKernelEnvironmentAddUnchecked
              environment
              (PsKernelConstantInfo.recInfo info)))
      exact
        ih
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.recInfo info))
          (psKernelEnvironmentAddUnchecked_index_refines
            environment (PsKernelConstantInfo.recInfo info) hIndex)
