import Ps.KernelCore.Admission.Quot.Admission
import Ps.KernelCore.Metatheory.Admission

theorem psKernelAddQuot_idempotent_when_initialized
    (environment : PsKernelEnvironment)
    (h : environment.quotInitialized = true) :
    psKernelAddQuot environment = Except.ok environment := by
  simp [psKernelAddQuot, h]

def psKernelQuotReservedNamesForProof : List PsKernelName :=
  List.cons
    psKernelQuotName
    (List.cons
      psKernelQuotMkName
      (List.cons
        psKernelQuotLiftName
        (List.cons
          psKernelQuotIndName
          List.nil)))

theorem psKernelAddQuot_propagates_eq_failure
    (environment : PsKernelEnvironment)
    (error : String)
    (hInit : environment.quotInitialized = false)
    (hEq :
      psKernelCheckEqForQuot environment =
        Except.error error) :
    psKernelAddQuot environment =
      Except.error error := by
  simp [psKernelAddQuot, hInit, hEq]

theorem psKernelAddQuot_propagates_reserved_failure
    (environment : PsKernelEnvironment)
    (error : String)
    (hInit : environment.quotInitialized = false)
    (hEq :
      psKernelCheckEqForQuot environment =
        Except.ok Unit.unit)
    (hReserved :
      psKernelCheckQuotReservedNames
          environment
          psKernelQuotReservedNamesForProof =
        Except.error error) :
    psKernelAddQuot environment =
      Except.error error := by
  have hReservedConcrete :
      psKernelCheckQuotReservedNames
          environment
          (List.cons
            psKernelQuotName
            (List.cons
              psKernelQuotMkName
              (List.cons
                psKernelQuotLiftName
                (List.cons
                  psKernelQuotIndName
                  List.nil)))) =
        Except.error error := by
    simpa [psKernelQuotReservedNamesForProof] using hReserved
  simp [
    psKernelAddQuot,
    hInit,
    hEq,
    hReservedConcrete
  ]

theorem psKernelAddQuot_success_postconditions
    (environment result : PsKernelEnvironment)
    (hInit : environment.quotInitialized = false)
    (hSuccess :
      psKernelAddQuot environment =
        Except.ok result) :
    result.quotInitialized = true ∧
    result.runtime = environment.runtime ∧
    psKernelConstantListLength result.constants =
      Nat.succ
        (Nat.succ
          (Nat.succ
            (Nat.succ
              (psKernelConstantListLength
                environment.constants)))) := by
  cases hEq : psKernelCheckEqForQuot environment with
  | error error =>
      simp [psKernelAddQuot, hInit, hEq] at hSuccess
  | ok eqResult =>
      cases eqResult
      cases hReserved :
          psKernelCheckQuotReservedNames
            environment
            (List.cons
              psKernelQuotName
              (List.cons
                psKernelQuotMkName
                (List.cons
                  psKernelQuotLiftName
                  (List.cons
                    psKernelQuotIndName
                    List.nil)))) with
      | error error =>
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
      | ok reservedResult =>
          cases reservedResult
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
          subst result
          simp [
            psKernelEnvironmentAddUnchecked,
            psKernelEnvironmentMarkQuotInitialized,
            psKernelConstantListLength,
            hInit
          ]


def psKernelQuotUniverseNameForProof : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "u"

def psKernelQuotResultUniverseNameForProof : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous "v"

def psKernelQuotTypeInfoForProof : PsKernelConstantInfo :=
  PsKernelConstantInfo.quotInfo
    (PsKernelQuotInfo.mk
      (PsKernelConstantBase.mk
        psKernelQuotName
        (List.cons psKernelQuotUniverseNameForProof List.nil)
        (psKernelMakeQuotType psKernelQuotUniverseNameForProof))
      PsKernelQuotKind.typeQ)

def psKernelQuotMkInfoForProof : PsKernelConstantInfo :=
  PsKernelConstantInfo.quotInfo
    (PsKernelQuotInfo.mk
      (PsKernelConstantBase.mk
        psKernelQuotMkName
        (List.cons psKernelQuotUniverseNameForProof List.nil)
        (psKernelMakeQuotMkType psKernelQuotUniverseNameForProof))
      PsKernelQuotKind.ctorQ)

def psKernelQuotLiftInfoForProof : PsKernelConstantInfo :=
  PsKernelConstantInfo.quotInfo
    (PsKernelQuotInfo.mk
      (PsKernelConstantBase.mk
        psKernelQuotLiftName
        (List.cons
          psKernelQuotUniverseNameForProof
          (List.cons
            psKernelQuotResultUniverseNameForProof
            List.nil))
        (psKernelMakeQuotLiftType
          psKernelQuotUniverseNameForProof
          psKernelQuotResultUniverseNameForProof))
      PsKernelQuotKind.liftQ)

def psKernelQuotIndInfoForProof : PsKernelConstantInfo :=
  PsKernelConstantInfo.quotInfo
    (PsKernelQuotInfo.mk
      (PsKernelConstantBase.mk
        psKernelQuotIndName
        (List.cons psKernelQuotUniverseNameForProof List.nil)
        (psKernelMakeQuotIndType psKernelQuotUniverseNameForProof))
      PsKernelQuotKind.indQ)

theorem psKernelAddQuot_success_semantic_history
    (environment result : PsKernelEnvironment)
    (hInit : environment.quotInitialized = false)
    (hSuccess :
      psKernelAddQuot environment =
        Except.ok result) :
    result.constants =
      List.cons
        psKernelQuotIndInfoForProof
        (List.cons
          psKernelQuotLiftInfoForProof
          (List.cons
            psKernelQuotMkInfoForProof
            (List.cons
              psKernelQuotTypeInfoForProof
              environment.constants))) := by
  cases hEq : psKernelCheckEqForQuot environment with
  | error error =>
      simp [psKernelAddQuot, hInit, hEq] at hSuccess
  | ok eqResult =>
      cases eqResult
      cases hReserved :
          psKernelCheckQuotReservedNames
            environment
            (List.cons
              psKernelQuotName
              (List.cons
                psKernelQuotMkName
                (List.cons
                  psKernelQuotLiftName
                  (List.cons
                    psKernelQuotIndName
                    List.nil)))) with
      | error error =>
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
      | ok reservedResult =>
          cases reservedResult
          simp [
            psKernelAddQuot,
            hInit,
            hEq,
            hReserved
          ] at hSuccess
          subst result
          simp [
            psKernelEnvironmentAddUnchecked,
            psKernelEnvironmentMarkQuotInitialized,
            psKernelQuotUniverseNameForProof,
            psKernelQuotResultUniverseNameForProof,
            psKernelQuotTypeInfoForProof,
            psKernelQuotMkInfoForProof,
            psKernelQuotLiftInfoForProof,
            psKernelQuotIndInfoForProof,
            hInit
          ]


theorem psKernelAddQuot_success_refines_extension
    (environment result : PsKernelEnvironment)
    (hInit : environment.quotInitialized = false)
    (hSuccess :
      psKernelAddQuot environment =
        Except.ok result) :
    PsKernelQuotExtension
      environment
      result
      (List.cons
        psKernelQuotIndInfoForProof
        (List.cons
          psKernelQuotLiftInfoForProof
          (List.cons
            psKernelQuotMkInfoForProof
            (List.cons
              psKernelQuotTypeInfoForProof
              List.nil)))) := by
  have hHistory :=
    psKernelAddQuot_success_semantic_history
      environment result hInit hSuccess
  have hPost :=
    psKernelAddQuot_success_postconditions
      environment result hInit hSuccess
  unfold PsKernelQuotExtension
  constructor
  · unfold PsKernelEnvironmentExtendsBy
    constructor
    · simpa using hHistory
    · exact hPost.2.1
  · exact ⟨hInit, hPost.1⟩
