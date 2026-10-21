import Ps.KernelCore.Checker.ExprV2.WhnfOwned

/- Local equations for String projection expansion and owning callback state.
These do not establish global kernel soundness or full recursive-checker
equivalence. The public callback retains the fuel chosen by its caller. -/
namespace PsKernelExprV2StringProjectionProofs

abbrev Callback := PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (PsKernelExprV2CheckState × Nat))

theorem expansion_lookup_error_precedes_callback
    (publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (major : Nat) (error : String)
    (invalid : psKernelExprV2PagedRequire state.whnf.arena major = .error error) :
    psKernelExprV2WhnfProjectionExpandOwnedWith publicWhnf context state major =
      some (.error error) := by
  simp [psKernelExprV2WhnfProjectionExpandOwnedWith, invalid]

theorem natural_major_retains_complete_state
    (publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (major value : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena major = .ok entry)
    (literal : entry.node = .lit (.nat value)) :
    psKernelExprV2WhnfProjectionExpandOwnedWith publicWhnf context state major =
      some (.ok (state,major)) := by
  simp [psKernelExprV2WhnfProjectionExpandOwnedWith, found, literal]

theorem string_expansion_uses_exact_public_callback
    (publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (major builtRoot : Nat) (value : String)
    (entry : PsKernelExprV2Entry) (arena : PsKernelExprV2PagedArena)
    (found : psKernelExprV2PagedRequire state.whnf.arena major = .ok entry)
    (literal : entry.node = .lit (.str value))
    (built : psKernelExprV2StringLitToConstructorOnCanonical state.whnf.arena value =
      .ok (arena,builtRoot)) :
    psKernelExprV2WhnfProjectionExpandOwnedWith publicWhnf context state major =
      publicWhnf context (psKernelExprV2CheckStateWithArena state arena) builtRoot := by
  simp [psKernelExprV2WhnfProjectionExpandOwnedWith, found, literal, built]

theorem cheap_initial_decline_precedes_expansion
    (recurse publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root index major : Nat) (name : PsKernelName)
    (declined : recurse context state major = none) :
    psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context state
      root name index major true = none := by
  simp [psKernelExprV2TryWhnfProjectionOwnedWith, declined]

theorem public_initial_error_precedes_expansion
    (recurse publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root index major : Nat) (name : PsKernelName)
    (error : String) (failed : publicWhnf context state major = some (.error error)) :
    psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context state
      root name index major false = some (.error error) := by
  simp [psKernelExprV2TryWhnfProjectionOwnedWith, failed]

theorem expansion_decline_preserved
    (recurse publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (before afterFirst : PsKernelExprV2CheckState)
    (root index major reduced : Nat) (name : PsKernelName) (cheapProj : Bool)
    (first : (if cheapProj then recurse context before major else publicWhnf context before major) =
      some (.ok (afterFirst,reduced)))
    (declined : psKernelExprV2WhnfProjectionExpandOwnedWith
      publicWhnf context afterFirst reduced = none) :
    psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context before
      root name index major cheapProj = none := by
  simp [psKernelExprV2TryWhnfProjectionOwnedWith, first, declined]

theorem expansion_error_preserved
    (recurse publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (before afterFirst : PsKernelExprV2CheckState)
    (root index major reduced : Nat) (name : PsKernelName) (cheapProj : Bool)
    (error : String)
    (first : (if cheapProj then recurse context before major else publicWhnf context before major) =
      some (.ok (afterFirst,reduced)))
    (failed : psKernelExprV2WhnfProjectionExpandOwnedWith
      publicWhnf context afterFirst reduced = some (.error error)) :
    psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context before
      root name index major cheapProj = some (.error error) := by
  simp [psKernelExprV2TryWhnfProjectionOwnedWith, first, failed]

theorem no_field_keeps_second_state_and_original_root
    (recurse publicWhnf : Callback) (context : PsKernelExprV2CheckContext)
    (before afterFirst afterSecond : PsKernelExprV2CheckState)
    (root index major reduced expanded : Nat) (name : PsKernelName)
    (first : recurse context before major = some (.ok (afterFirst,reduced)))
    (second : psKernelExprV2WhnfProjectionExpandOwnedWith
      publicWhnf context afterFirst reduced = some (.ok (afterSecond,expanded)))
    (noField : psKernelExprV2ReduceProjOnCanonical
      context.scalar afterSecond.whnf.arena name index expanded = .ok none) :
    psKernelExprV2TryWhnfProjectionOwnedWith recurse publicWhnf context before
      root name index major true = some (.ok (afterSecond,root)) := by
  simp [psKernelExprV2TryWhnfProjectionOwnedWith, first, second,
    psKernelExprV2WhnfProjectionSelectOwnedWith, noField,
    psKernelExprV2WhnfCoreOwnedFinishMode]

theorem selected_field_error_preserved
    (recurse : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root index major field : Nat)
    (name : PsKernelName) (cheapProj : Bool) (error : String)
    (selected : psKernelExprV2ReduceProjOnCanonical
      context.scalar state.whnf.arena name index major = .ok (some field))
    (failed : recurse context state field = some (.error error)) :
    psKernelExprV2WhnfProjectionSelectOwnedWith recurse context state
      root name index major cheapProj = some (.error error) := by
  simp [psKernelExprV2WhnfProjectionSelectOwnedWith, selected, failed,
    psKernelExprV2WhnfOwnedFinishAttempt]

theorem selected_field_finish_uses_complete_returned_state
    (recurse : Callback) (context : PsKernelExprV2CheckContext)
    (before afterField : PsKernelExprV2CheckState) (root index major field result : Nat)
    (name : PsKernelName) (cheapProj : Bool)
    (selected : psKernelExprV2ReduceProjOnCanonical
      context.scalar before.whnf.arena name index major = .ok (some field))
    (reduced : recurse context before field = some (.ok (afterField,result))) :
    psKernelExprV2WhnfProjectionSelectOwnedWith recurse context before
      root name index major cheapProj =
        some (psKernelExprV2WhnfCoreOwnedFinishMode cheapProj afterField root result) := by
  simp [psKernelExprV2WhnfProjectionSelectOwnedWith, selected, reduced,
    psKernelExprV2WhnfOwnedFinishAttempt]

#print axioms expansion_lookup_error_precedes_callback
#print axioms natural_major_retains_complete_state
#print axioms string_expansion_uses_exact_public_callback
#print axioms cheap_initial_decline_precedes_expansion
#print axioms public_initial_error_precedes_expansion
#print axioms expansion_decline_preserved
#print axioms expansion_error_preserved
#print axioms no_field_keeps_second_state_and_original_root
#print axioms selected_field_error_preserved
#print axioms selected_field_finish_uses_complete_returned_state

end PsKernelExprV2StringProjectionProofs
