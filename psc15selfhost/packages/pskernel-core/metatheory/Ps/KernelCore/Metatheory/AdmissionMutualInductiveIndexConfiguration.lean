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


theorem psKernelAddMutualInductiveInfos_refines_extension
    (infos : List PsKernelInductiveInfo)
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentExtendsBy
      environment
      (psKernelAddMutualInductiveInfos infos environment)
      (List.reverse
        (List.map
          (fun info : PsKernelInductiveInfo =>
            PsKernelConstantInfo.inductInfo info)
          infos)) := by
  induction infos generalizing environment with
  | nil =>
      exact psKernelEnvironmentExtendsBy_refl environment
  | cons info rest ih =>
      have hTail :=
        ih (psKernelEnvironmentAddUnchecked
          environment (PsKernelConstantInfo.inductInfo info))
      simpa [
        psKernelAddMutualInductiveInfos,
        PsKernelEnvironmentExtendsBy,
        psKernelEnvironmentAddUnchecked,
        List.map,
        List.reverse_cons,
        List.append_assoc
      ] using hTail


theorem psKernelAddMutualRecursorInfos_refines_extension
    (infos : List PsKernelRecursorInfo)
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentExtendsBy
      environment
      (psKernelAddMutualRecursorInfos infos environment)
      (List.reverse
        (List.map
          (fun info : PsKernelRecursorInfo =>
            PsKernelConstantInfo.recInfo info)
          infos)) := by
  induction infos generalizing environment with
  | nil =>
      exact psKernelEnvironmentExtendsBy_refl environment
  | cons info rest ih =>
      have hTail :=
        ih (psKernelEnvironmentAddUnchecked
          environment (PsKernelConstantInfo.recInfo info))
      simpa [
        psKernelAddMutualRecursorInfos,
        PsKernelEnvironmentExtendsBy,
        psKernelEnvironmentAddUnchecked,
        List.map,
        List.reverse_cons,
        List.append_assoc
      ] using hTail
