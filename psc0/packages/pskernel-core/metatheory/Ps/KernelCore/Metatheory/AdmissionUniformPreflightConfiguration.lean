import Ps.KernelCore.Metatheory.AdmissionUniformOccurrenceConfiguration
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Admission.Inductive.Nested.Admission

/-
Bundle-level uniform-occurrence refinement for each public inductive
admission entry point.

These theorems consume actual successful executable preflight checks,
and then the importable fuel-induction proof for every constructor type.
They are independent of checked-inference/DefEq/native-reduction assumptions:
the claim concerns only structural uniform occurrences.  They do not claim
constructor typing, strict positivity, recursor or environment soundness.
-/

theorem psKernelAddSimpleInductive_success_uniform_occurrences_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hRun :
      psKernelAddSimpleInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelUniformOccurrencesSafe
      (List.cons decl.name List.nil)
      (psKernelLevelParamsToLevels decl.levelParams)
      decl.numParams
      (psKernelSimpleCtorTypes decl.ctors) := by
  let allNames : List PsKernelName :=
    List.cons decl.name
      (List.cons (psKernelSimpleRecName decl.name)
        (psKernelSimpleCtorNames decl.ctors))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [psKernelAddSimpleInductive, hDuplicates] at hRun
  | false =>
      cases hUnique :
          psKernelSimpleNameListUnique allNames with
      | false =>
          simp [
            psKernelAddSimpleInductive, hDuplicates,
            allNames, hUnique
          ] at hRun
      | true =>
          cases hFresh :
              psKernelCheckFreshInductiveNames allNames environment with
          | error error =>
              simp [
                psKernelAddSimpleInductive, hDuplicates,
                allNames, hUnique, hFresh
              ] at hRun
          | ok fresh =>
              cases hOccurrences :
                  psKernelSimpleCheckUniformOccurrences
                    (List.cons decl.name List.nil)
                    decl.levelParams
                    decl.numParams
                    (psKernelSimpleCtorTypes decl.ctors) with
              | error error =>
                  simp [
                    psKernelAddSimpleInductive, hDuplicates,
                    allNames, hUnique, hFresh, hOccurrences
                  ] at hRun
              | ok checked =>
                  cases checked
                  exact
                    psKernelSimpleCheckUniformOccurrences_success_refines
                      (List.cons decl.name List.nil)
                      decl.levelParams
                      decl.numParams
                      (psKernelSimpleCtorTypes decl.ctors)
                      hOccurrences

theorem psKernelAddSimpleMutualInductive_success_uniform_occurrences_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hRun :
      psKernelAddSimpleMutualInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelUniformOccurrencesSafe
      (psKernelSimpleMutualNames decl.types)
      (psKernelLevelParamsToLevels decl.levelParams)
      decl.numParams
      (psKernelSimpleMutualCtorTypes decl.types) := by
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames decl.types)
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames decl.types)
        (psKernelSimpleMutualCtorNames decl.types))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [psKernelAddSimpleMutualInductive, hDuplicates] at hRun
  | false =>
      cases hMinTypes :
          psKernelNatLt
            (psKernelSimpleMutualTypeCount decl.types) 2 with
      | true =>
          simp [
            psKernelAddSimpleMutualInductive,
            hDuplicates, hMinTypes
          ] at hRun
      | false =>
          cases hUnique :
              psKernelSimpleNameListUnique allNames with
          | false =>
              simp [
                psKernelAddSimpleMutualInductive,
                hDuplicates, hMinTypes, allNames, hUnique
              ] at hRun
          | true =>
              cases hFresh :
                  psKernelCheckFreshInductiveNames
                    allNames environment with
              | error error =>
                  simp [
                    psKernelAddSimpleMutualInductive,
                    hDuplicates, hMinTypes, allNames,
                    hUnique, hFresh
                  ] at hRun
              | ok fresh =>
                  cases hOccurrences :
                      psKernelSimpleCheckUniformOccurrences
                        (psKernelSimpleMutualNames decl.types)
                        decl.levelParams
                        decl.numParams
                        (psKernelSimpleMutualCtorTypes decl.types) with
                  | error error =>
                      simp [
                        psKernelAddSimpleMutualInductive,
                        hDuplicates, hMinTypes, allNames,
                        hUnique, hFresh, hOccurrences
                      ] at hRun
                  | ok checked =>
                      cases checked
                      exact
                        psKernelSimpleCheckUniformOccurrences_success_refines
                          (psKernelSimpleMutualNames decl.types)
                          decl.levelParams
                          decl.numParams
                          (psKernelSimpleMutualCtorTypes decl.types)
                          hOccurrences

theorem psKernelAddSimpleNestedInductive_success_uniform_occurrences_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hRun :
      psKernelAddSimpleNestedInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelUniformOccurrencesSafe
      (psKernelSimpleMutualNames decl.types)
      (psKernelLevelParamsToLevels decl.levelParams)
      decl.numParams
      (psKernelSimpleMutualCtorTypes decl.types) := by
  cases hReserved :
      psKernelSimpleNestedCheckReserved decl with
  | error error =>
      simp [psKernelAddSimpleNestedInductive, hReserved] at hRun
  | ok reserved =>
      cases hOccurrences :
          psKernelSimpleCheckUniformOccurrences
            (psKernelSimpleMutualNames decl.types)
            decl.levelParams
            decl.numParams
            (psKernelSimpleMutualCtorTypes decl.types) with
      | error error =>
          simp [
            psKernelAddSimpleNestedInductive,
            hReserved, hOccurrences
          ] at hRun
      | ok checked =>
          cases checked
          exact
            psKernelSimpleCheckUniformOccurrences_success_refines
              (psKernelSimpleMutualNames decl.types)
              decl.levelParams
              decl.numParams
              (psKernelSimpleMutualCtorTypes decl.types)
              hOccurrences
