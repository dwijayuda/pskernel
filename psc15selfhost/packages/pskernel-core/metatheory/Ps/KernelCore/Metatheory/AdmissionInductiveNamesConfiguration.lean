import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
Canonical freshness of names before ordinary and mutual inductive admission.

The executable checker consults the accelerated environment.  This
independent predicate records absence from the authoritative declaration list,
not mere absence from the mutable hash index.  It is intentionally separate
from the bundle's internal-name uniqueness guard.
-/

inductive PsKernelInductiveNamesAbsent
    (environment : PsKernelEnvironment) :
    List PsKernelName -> Prop where
  | nil :
      PsKernelInductiveNamesAbsent environment List.nil
  | cons
      (name : PsKernelName)
      (rest : List PsKernelName)
      (hAbsent :
        psKernelFindConstantInList name environment.constants =
          Option.none)
      (hRest : PsKernelInductiveNamesAbsent environment rest) :
      PsKernelInductiveNamesAbsent
        environment (List.cons name rest)


theorem psKernelCheckFreshInductiveNames_refines_canonical
    (names : List PsKernelName) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      psKernelCheckFreshInductiveNames names environment =
        Except.ok () ->
      PsKernelInductiveNamesAbsent environment names := by
  induction names with
  | nil =>
      intro environment hIndex hRun
      exact PsKernelInductiveNamesAbsent.nil
  | cons name rest ih =>
      intro environment hIndex hRun
      cases hPresent :
          psKernelEnvironmentContains environment name with
      | true =>
          simp [
            psKernelCheckFreshInductiveNames,
            hPresent
          ] at hRun
      | false =>
          have hLookupNone :
              psKernelEnvironmentFind environment name =
                Option.none := by
            cases hFind :
                psKernelEnvironmentFind environment name with
            | none =>
                rfl
            | some declaration =>
                simp [
                  psKernelEnvironmentContains,
                  hFind
                ] at hPresent
          have hCanonicalNone :
              psKernelFindConstantInList
                  name environment.constants =
                Option.none := by
            calc
              psKernelFindConstantInList
                  name environment.constants =
                psKernelFindConstantInList
                  name
                  (psKernelEnvironmentIndexFind
                    environment.index name) :=
                (hIndex name).symm
              _ = Option.none := by
                simpa [psKernelEnvironmentFind] using
                  hLookupNone
          have hRestRun :
              psKernelCheckFreshInductiveNames
                  rest environment =
                Except.ok () := by
            simpa [
              psKernelCheckFreshInductiveNames,
              hPresent
            ] using hRun
          exact
            PsKernelInductiveNamesAbsent.cons
              name rest hCanonicalNone
              (ih environment hIndex hRestRun)


theorem psKernelSimpleNameListUnique_true_no_duplicates
    (names : List PsKernelName)
    (hUnique : psKernelSimpleNameListUnique names = true) :
    psKernelNameHasDuplicates names = false := by
  cases hDuplicates :
      psKernelNameHasDuplicates names with
  | false =>
      rfl
  | true =>
      simp [
        psKernelSimpleNameListUnique,
        hDuplicates
      ] at hUnique
