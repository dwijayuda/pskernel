import Lean
import Ps.KernelCore.API.DagNestedHeader

namespace PsKernelNestedHeaderProofs
abbrev Check := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
variable (check whnf : Check) (fuel type numParams : Nat)
variable (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)

theorem check_decline_precedes_sort_and_parameter_work
    (step : check fuel context state type = none) :
    psKernelExprV2NestedInitialPhasesWith check whnf fuel context state type numParams = none := by
  simp only [psKernelExprV2NestedInitialPhasesWith,step]

theorem check_error_precedes_sort_and_parameter_work
    (error : String) (step : check fuel context state type = some (.error error)) :
    psKernelExprV2NestedInitialPhasesWith check whnf fuel context state type numParams =
      some (.error error) := by
  simp only [psKernelExprV2NestedInitialPhasesWith,step]

theorem mandatory_public_sort_decline_precedes_parameter_work
    (next : PsKernelExprV2CheckState) (typeType : Nat)
    (checked : check fuel context state type = some (.ok (next,typeType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) context next typeType = none) :
    psKernelExprV2NestedInitialPhasesWith check whnf fuel context state type numParams = none := by
  simp only [psKernelExprV2NestedInitialPhasesWith,checked,sorted]

theorem mandatory_public_sort_error_precedes_parameter_work
    (next : PsKernelExprV2CheckState) (typeType : Nat) (error : String)
    (checked : check fuel context state type = some (.ok (next,typeType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) context next typeType = some (.error error)) :
    psKernelExprV2NestedInitialPhasesWith check whnf fuel context state type numParams =
      some (.error error) := by
  simp only [psKernelExprV2NestedInitialPhasesWith,checked,sorted]

theorem parameter_result_returns_without_index_or_final_sort_work
    (next sortedState : PsKernelExprV2CheckState) (typeType : Nat) (level : PsKernelLevel)
    (checked : check fuel context state type = some (.ok (next,typeType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) context next typeType =
      some (.ok (sortedState,level))) :
    psKernelExprV2NestedInitialPhasesWith check whnf fuel context state type numParams =
      psKernelExprV2OrdinaryOpenHeaderParamsWith check whnf fuel context sortedState type numParams := by
  simp only [psKernelExprV2NestedInitialPhasesWith,checked,sorted]

theorem reserved_error_precedes_uniform_occurrence_analysis
    (decl : PsKernelSimpleMutualInductiveDecl) (error : String)
    (guard : psKernelSimpleNestedCheckReserved decl = .error error) :
    psKernelExprV2NestedHeaderGuards decl = .error error := by
  simp only [psKernelExprV2NestedHeaderGuards,guard]

theorem actual_original_reserved_error_precedes_every_checker
    (environment : PsKernelEnvironment) (decl : PsKernelSimpleMutualInductiveDecl)
    (depth maxNat : Nat) (error : String)
    (guard : psKernelSimpleNestedCheckReserved decl = .error error) :
    psKernelAddSimpleNestedInductive fuel environment decl depth maxNat = .error error := by
  simp only [psKernelAddSimpleNestedInductive,guard]

theorem original_boundary_table_error_precedes_all_guards_and_callbacks
    (environment : PsKernelEnvironment) (depth maxNat : Nat)
    (input : PsKernelExprV2Decoded) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (value : PsKernelDagInductiveGroup)
    (error : String) (decoded : psKernelDagDecodeGroup input value = .error error) :
    psKernelExprV2NestedAnalyzeHeaderWith check whnf fuel environment depth maxNat input arena
      declarations value = some (.error error) := by
  simp only [psKernelExprV2NestedAnalyzeHeaderWith,decoded]

theorem guard_error_precedes_fresh_owner_and_checking
    (environment : PsKernelEnvironment) (depth maxNat : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (decl : PsKernelSimpleMutualInductiveDecl) (value : PsKernelDagInductiveGroup)
    (error : String) (guard : psKernelExprV2NestedHeaderGuards decl = .error error) :
    psKernelExprV2NestedHeaderAfterDecodeWith check whnf fuel environment depth maxNat arena
      declarations decl value = some (.error error) := by
  simp only [psKernelExprV2NestedHeaderAfterDecodeWith,guard]

theorem empty_group_keeps_original_error_after_guards
    (environment : PsKernelEnvironment) (depth maxNat : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (decl : PsKernelSimpleMutualInductiveDecl) (value : PsKernelDagInductiveGroup)
    (guard : psKernelExprV2NestedHeaderGuards decl = .ok ()) (empty : value.types = []) :
    psKernelExprV2NestedHeaderAfterDecodeWith check whnf fuel environment depth maxNat arena
      declarations decl value = some (.error "empty nested inductive declaration") := by
  simp only [psKernelExprV2NestedHeaderAfterDecodeWith,guard,empty]

theorem actual_wrapper_uses_owned_check_and_public_whnf_at_entry_fuel
    (environment : PsKernelEnvironment) (depth maxNat : Nat)
    (input : PsKernelExprV2Decoded) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (value : PsKernelDagInductiveGroup) :
    psKernelExprV2NestedAnalyzeHeaderWithFuel fuel environment depth maxNat input arena declarations value =
      psKernelExprV2NestedAnalyzeHeaderWith psKernelExprV2TryCheckStateWithFuel
        psKernelExprV2TryWhnfCheckStateWithFuel fuel environment depth maxNat input arena declarations value := rfl

end PsKernelNestedHeaderProofs

#print axioms PsKernelNestedHeaderProofs.check_decline_precedes_sort_and_parameter_work
#print axioms PsKernelNestedHeaderProofs.check_error_precedes_sort_and_parameter_work
#print axioms PsKernelNestedHeaderProofs.mandatory_public_sort_decline_precedes_parameter_work
#print axioms PsKernelNestedHeaderProofs.mandatory_public_sort_error_precedes_parameter_work
#print axioms PsKernelNestedHeaderProofs.parameter_result_returns_without_index_or_final_sort_work
#print axioms PsKernelNestedHeaderProofs.reserved_error_precedes_uniform_occurrence_analysis
#print axioms PsKernelNestedHeaderProofs.actual_original_reserved_error_precedes_every_checker
#print axioms PsKernelNestedHeaderProofs.original_boundary_table_error_precedes_all_guards_and_callbacks
#print axioms PsKernelNestedHeaderProofs.guard_error_precedes_fresh_owner_and_checking
#print axioms PsKernelNestedHeaderProofs.empty_group_keeps_original_error_after_guards
#print axioms PsKernelNestedHeaderProofs.actual_wrapper_uses_owned_check_and_public_whnf_at_entry_fuel
