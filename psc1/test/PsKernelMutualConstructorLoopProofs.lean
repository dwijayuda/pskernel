import Ps.KernelCore.API.DagMutualConstructorLoop

/- Local algebraic owner/list equations. Components are separate premises;
   arbitrary callbacks are not checker certificates. This private loop does
   not establish public publication, recursor admission or global soundness. -/
namespace PsKernelMutualConstructorLoopProofs
abbrev Analyze := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  PsKernelDagConstructor → Option (Except String PsKernelExprV2MutualConstructorAnalysis)
variable (analyze : Analyze) (fuel : Nat) (input : PsKernelExprV2Decoded)
  (target : PsKernelName) (owner numParams index : Nat)
  (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
  (ctor : PsKernelDagConstructor) (rest : List PsKernelDagConstructor)

theorem empty_constructors_succeed_at_zero
    : psKernelExprV2MutualAddConstructorsForTypeWorker [] analyze 0 input target owner numParams context state index =
      some (.ok (PsKernelExprV2MutualConstructorsResult.mk context state [])) := rfl

theorem empty_constructors_keep_exact_owner
    : psKernelExprV2MutualAddConstructorsForTypeWorker [] analyze fuel input target owner numParams context state index =
      some (.ok (PsKernelExprV2MutualConstructorsResult.mk context state [])) := rfl

theorem analysis_decline_precedes_metadata
    
    (attempted : analyze fuel context state owner ctor = none) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = none := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted]

theorem analysis_error_precedes_metadata
    (error : String)
    (attempted : analyze fuel context state owner ctor = some (.error error)) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = some (.error error) := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted]

theorem metadata_error_precedes_tail
    (analyzed : PsKernelExprV2MutualConstructorAnalysis) (error : String)
    (attempted : analyze fuel context state owner ctor = some (.ok analyzed))
    (installed : psKernelExprV2MutualInstallConstructor input target numParams index
      context state ctor analyzed = .error error) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = some (.error error) := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted, installed]

theorem tail_decline_returns_no_partial_result
    (analyzed : PsKernelExprV2MutualConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    
    (attempted : analyze fuel context state owner ctor = some (.ok analyzed))
    (installed : psKernelExprV2MutualInstallConstructor input target numParams index
      context state ctor analyzed = .ok (nextContext,nextState))
    (tail : psKernelExprV2MutualAddConstructorsForTypeWorker rest analyze fuel input target owner numParams
      nextContext nextState (Nat.succ index) = none) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = none := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted, installed, tail]

theorem tail_error_returns_no_partial_result
    (analyzed : PsKernelExprV2MutualConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (error : String)
    (attempted : analyze fuel context state owner ctor = some (.ok analyzed))
    (installed : psKernelExprV2MutualInstallConstructor input target numParams index
      context state ctor analyzed = .ok (nextContext,nextState))
    (tail : psKernelExprV2MutualAddConstructorsForTypeWorker rest analyze fuel input target owner numParams
      nextContext nextState (Nat.succ index) = some (.error error)) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = some (.error error) := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted, installed, tail]

theorem tail_success_keeps_fuel_and_source_order
    (analyzed : PsKernelExprV2MutualConstructorAnalysis)
    (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
    (result : PsKernelExprV2MutualConstructorsResult)
    (attempted : analyze fuel context state owner ctor = some (.ok analyzed))
    (installed : psKernelExprV2MutualInstallConstructor input target numParams index
      context state ctor analyzed = .ok (nextContext,nextState))
    (tail : psKernelExprV2MutualAddConstructorsForTypeWorker rest analyze fuel input target owner numParams
      nextContext nextState (Nat.succ index) = some (.ok result)) :
    psKernelExprV2MutualAddConstructorsForTypeWorker (ctor :: rest) analyze fuel input target owner numParams context state index = some (.ok (PsKernelExprV2MutualConstructorsResult.mk
      result.context result.state (analyzed.shape :: result.shapes))) := by
  simp only [psKernelExprV2MutualAddConstructorsForTypeWorker, attempted, installed, tail]

theorem metadata_lookup_error_keeps_original_root
    (analyzed : PsKernelExprV2MutualConstructorAnalysis) (error : String)
    (lookup : psKernelExprV2DecodedRequire input ctor.type = .error error) :
    psKernelExprV2MutualInstallConstructor input target numParams index context state ctor analyzed = .error error := by
  simp only [psKernelExprV2MutualInstallConstructor, lookup]

theorem install_owner_and_original_root
    (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2MutualConstructorAnalysis) (type : PsKernelExpr)
    (h : psKernelExprV2DecodedRequire input ctor.type = Except.ok type) :
    psKernelExprV2MutualInstallConstructor
      input target numParams index context state ctor analyzed =
    let info := PsKernelConstructorInfo.mk
      (PsKernelConstantBase.mk ctor.name context.scalar.levelParams type)
      target index numParams
      (psKernelExprV2OrdinaryOpenBinderCount analyzed.shape.fields)
      (psKernelDefinitionSafetyIsUnsafe context.scalar.safety);
    let work := psKernelEnvironmentAddUnchecked context.scalar.environment
      (PsKernelConstantInfo.ctorInfo info);
    let reference := PsKernelExprV2DeclarationRef.mk
      ctor.name context.scalar.levelParams ctor.type Option.none
      PsKernelExprV2DeclarationRefKind.constructorDecl;
    Except.ok
      (Prod.mk
        (PsKernelExprV2CheckContext.mk
          (psKernelCheckerContextWithEnvironment context.scalar work) context.locals)
        (psKernelExprV2CheckStateWithWhnf state
          (PsKernelExprV2WhnfState.mk
            analyzed.state.whnf.arena state.whnf.coreCache state.whnf.publicCache
            (List.cons reference state.whnf.declarations)))) := by
  simp only [psKernelExprV2MutualInstallConstructor, h]

theorem empty_types_succeed_at_zero
    : psKernelExprV2MutualAddTypesWorker [] analyze 0 input numParams context state owner =
      some (.ok (PsKernelExprV2MutualConstructorsResult.mk context state [])) := rfl

theorem type_empty_constructors_keep_same_fuel
    (first : PsKernelExprV2MutualTypeHeader) (later : List PsKernelExprV2MutualTypeHeader)
    (empty : first.declaration.ctors = []) :
    psKernelExprV2MutualAddTypesWorker (first :: later) analyze fuel input numParams context state owner =
      psKernelExprV2MutualAddTypesWorker later analyze fuel input numParams context state (Nat.succ owner) := by
  simp only [psKernelExprV2MutualAddTypesWorker, empty,
    psKernelExprV2MutualAddConstructorsForTypeWorker]
  cases result : psKernelExprV2MutualAddTypesWorker later analyze fuel input numParams context state (Nat.succ owner) with
  | none => rfl
  | some attempted => cases attempted <;> rfl

theorem type_decline_precedes_later_family
    (first : PsKernelExprV2MutualTypeHeader) (later : List PsKernelExprV2MutualTypeHeader)
    
    (attempted : psKernelExprV2MutualAddConstructorsForTypeWorker first.declaration.ctors analyze fuel input first.declaration.name
      owner numParams context state 0 = none) :
    psKernelExprV2MutualAddTypesWorker (first :: later) analyze fuel input numParams context state owner = none := by
  simp only [psKernelExprV2MutualAddTypesWorker, attempted]

theorem type_error_precedes_later_family
    (first : PsKernelExprV2MutualTypeHeader) (later : List PsKernelExprV2MutualTypeHeader)
    (error : String)
    (attempted : psKernelExprV2MutualAddConstructorsForTypeWorker first.declaration.ctors analyze fuel input first.declaration.name
      owner numParams context state 0 = some (.error error)) :
    psKernelExprV2MutualAddTypesWorker (first :: later) analyze fuel input numParams context state owner = some (.error error) := by
  simp only [psKernelExprV2MutualAddTypesWorker, attempted]

theorem type_success_resets_ctor_index_and_orders_families
    (first : PsKernelExprV2MutualTypeHeader) (later : List PsKernelExprV2MutualTypeHeader)
    (ownResult result : PsKernelExprV2MutualConstructorsResult)
    (attempted : psKernelExprV2MutualAddConstructorsForTypeWorker first.declaration.ctors analyze fuel input first.declaration.name
      owner numParams context state 0 = some (.ok ownResult))
    (tail : psKernelExprV2MutualAddTypesWorker later analyze fuel input numParams
      ownResult.context ownResult.state (Nat.succ owner) = some (.ok result)) :
    psKernelExprV2MutualAddTypesWorker (first :: later) analyze fuel input numParams context state owner =
      some (.ok (PsKernelExprV2MutualConstructorsResult.mk result.context result.state
        (psKernelExprV2MutualConstructorShapeAppend ownResult.shapes result.shapes))) := by
  simp only [psKernelExprV2MutualAddTypesWorker, attempted, tail]

theorem shape_append_nil
    (shapes : List PsKernelExprV2MutualConstructorShape) :
    psKernelExprV2MutualConstructorShapeAppend [] shapes = shapes := rfl

#print axioms empty_constructors_succeed_at_zero
#print axioms empty_constructors_keep_exact_owner
#print axioms analysis_decline_precedes_metadata
#print axioms analysis_error_precedes_metadata
#print axioms metadata_error_precedes_tail
#print axioms tail_decline_returns_no_partial_result
#print axioms tail_error_returns_no_partial_result
#print axioms tail_success_keeps_fuel_and_source_order
#print axioms metadata_lookup_error_keeps_original_root
#print axioms install_owner_and_original_root
#print axioms empty_types_succeed_at_zero
#print axioms type_empty_constructors_keep_same_fuel
#print axioms type_decline_precedes_later_family
#print axioms type_error_precedes_later_family
#print axioms type_success_resets_ctor_index_and_orders_families
#print axioms shape_append_nil
end PsKernelMutualConstructorLoopProofs
