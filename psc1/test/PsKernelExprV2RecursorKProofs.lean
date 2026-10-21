import Ps.KernelCore.Checker.ExprV2.RecursorK

/- These local theorems establish the callback boundary, including complete
   returned-state retention. Construction and callback results are explicit
   premises, not trusted judgments. They do not assert global kernel soundness
   or semantic equivalence of complete K conversion. -/

namespace PsKernelExprV2RecursorKProofs

abbrev Unary := PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (PsKernelExprV2CheckState × Nat))
abbrev DefEq := PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
  Option (Except String (PsKernelExprV2CheckState × Bool))

theorem inferNone (whnf : Unary) (eq : DefEq)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (info : PsKernelRecursorInfo) (family : PsKernelName) (major : Nat) :
    psKernelExprV2RecursorKForFamilyOwnedWith whnf (fun _ _ _ => none)
      eq context state info family major = none := rfl

theorem inferError (whnf : Unary) (eq : DefEq)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (info : PsKernelRecursorInfo) (family : PsKernelName) (major : Nat) (message : String) :
    psKernelExprV2RecursorKForFamilyOwnedWith whnf
      (fun _ _ _ => some (.error message)) eq context state info family major =
        some (.error message) := rfl

theorem whnfNone (eq : DefEq) (context : PsKernelExprV2CheckContext)
    (initial inferred : PsKernelExprV2CheckState)
    (info : PsKernelRecursorInfo) (family : PsKernelName) (major type : Nat) :
    psKernelExprV2RecursorKForFamilyOwnedWith (fun _ _ _ => none)
      (fun _ _ _ => some (.ok (inferred,type))) eq context initial info family major = none := rfl

theorem whnfError (eq : DefEq) (context : PsKernelExprV2CheckContext)
    (initial inferred : PsKernelExprV2CheckState) (info : PsKernelRecursorInfo)
    (family : PsKernelName) (major type : Nat) (message : String) :
    psKernelExprV2RecursorKForFamilyOwnedWith (fun _ _ _ => some (.error message))
      (fun _ _ _ => some (.ok (inferred,type))) eq context initial info family major =
        some (.error message) := rfl

theorem candidateDecisionRetainsFullState
    (infer : Unary) (eq : DefEq) (context : PsKernelExprV2CheckContext)
    (initial inferred final : PsKernelExprV2CheckState) (major appType candidateType : Nat)
    (ctor : PsKernelName) (levels : List PsKernelLevel) (params : List Nat)
    (headArena candidateArena : PsKernelExprV2PagedArena) (head candidate : Nat) (decision : Bool)
    (hHead : psKernelExprV2PagedMkConst initial.whnf.arena ctor levels = .ok (headArena,head))
    (hApply : psKernelExprV2TransformApplyArgsOnCanonical params headArena head = .ok (candidateArena,candidate))
    (hInfer : infer context (psKernelExprV2CheckStateWithArena initial candidateArena) candidate =
      some (.ok (inferred,candidateType)))
    (hEqual : eq context inferred appType candidateType = some (.ok (final,decision))) :
    psKernelExprV2RecursorKCandidateOwnedWith infer eq context initial major appType ctor levels params =
      some (.ok (final,if decision then candidate else major)) := by
  simp only [psKernelExprV2RecursorKCandidateOwnedWith,hHead,hApply,hInfer,hEqual]

theorem candidateFalseRetainsFullState
    (infer : Unary) (eq : DefEq) (context : PsKernelExprV2CheckContext)
    (initial inferred final : PsKernelExprV2CheckState) (major appType candidateType : Nat)
    (ctor : PsKernelName) (levels : List PsKernelLevel) (params : List Nat)
    (headArena candidateArena : PsKernelExprV2PagedArena) (head candidate : Nat)
    (hHead : psKernelExprV2PagedMkConst initial.whnf.arena ctor levels = .ok (headArena,head))
    (hApply : psKernelExprV2TransformApplyArgsOnCanonical params headArena head = .ok (candidateArena,candidate))
    (hInfer : infer context (psKernelExprV2CheckStateWithArena initial candidateArena) candidate =
      some (.ok (inferred,candidateType)))
    (hEqual : eq context inferred appType candidateType = some (.ok (final,false))) :
    psKernelExprV2RecursorKCandidateOwnedWith infer eq context initial major appType ctor levels params =
      some (.ok (final,major)) := by
  simpa using candidateDecisionRetainsFullState infer eq context initial inferred final major appType
    candidateType ctor levels params headArena candidateArena head candidate false hHead hApply hInfer hEqual

end PsKernelExprV2RecursorKProofs

#print axioms PsKernelExprV2RecursorKProofs.inferNone
#print axioms PsKernelExprV2RecursorKProofs.inferError
#print axioms PsKernelExprV2RecursorKProofs.whnfNone
#print axioms PsKernelExprV2RecursorKProofs.whnfError
#print axioms PsKernelExprV2RecursorKProofs.candidateDecisionRetainsFullState
#print axioms PsKernelExprV2RecursorKProofs.candidateFalseRetainsFullState
