import Lean
import Ps.KernelCore.API.DagNestedOverlay

namespace PsKernelNestedOverlayProofs

/- These are conditional private-machine protocols. They neither assume a
   caller arena is valid nor establish the still-open global replay theorem.
   Successful owning admission/restoration remains mandatory before publish. -/

theorem original_decoded_error_is_first
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (error : String)
    (missing : psKernelExprV2DecodedRequire state.built original = .error error) :
    psKernelExprV2NestedOverlay source original state = .error error := by
  cases source <;> simp only [psKernelExprV2NestedOverlay,missing]

theorem original_arena_error_is_preserved
    (source decoded : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (error : String)
    (readable : psKernelExprV2DecodedRequire state.built original = .ok decoded)
    (missing : psKernelExprV2PagedRequire state.arena original = .error error) :
    psKernelExprV2NestedOverlay source original state = .error error := by
  cases source <;> simp only [psKernelExprV2NestedOverlay,readable,missing]

theorem unchanged_node_reuses_entire_owner_and_original_id
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (oldNode newNode : PsKernelExprV2Node)
    (same : psKernelExprV2NestedOverlayNodeSame oldNode newNode = true) :
    psKernelExprV2NestedOverlayFinish source original oldNode newNode state = .ok (state,original) := by
  simp only [psKernelExprV2NestedOverlayFinish,same] <;> rfl

theorem novel_node_uses_exact_existing_smart_replay
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (oldNode newNode : PsKernelExprV2Node)
    (different : psKernelExprV2NestedOverlayNodeSame oldNode newNode = false) :
    psKernelExprV2NestedOverlayFinish source original oldNode newNode state =
      psKernelDagGeneratedFinish source state (psKernelExprV2PagedReplayNode state.arena newNode) := by
  simp only [psKernelExprV2NestedOverlayFinish,different] <;> rfl

theorem novel_smart_construction_error_never_returns_an_owner
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (oldNode newNode : PsKernelExprV2Node) (error : String)
    (different : psKernelExprV2NestedOverlayNodeSame oldNode newNode = false)
    (failed : psKernelExprV2PagedReplayNode state.arena newNode = .error error) :
    psKernelExprV2NestedOverlayFinish source original oldNode newNode state = .error error := by
  simp only [psKernelExprV2NestedOverlayFinish,different,failed,psKernelDagGeneratedFinish] <;> rfl

theorem changed_node_kind_uses_exact_generated_import
    (fn arg decoded : PsKernelExpr) (original oldIndex : Nat)
    (state : PsKernelDagGeneratedState) (entry : PsKernelExprV2Entry)
    (readable : psKernelExprV2DecodedRequire state.built original = .ok decoded)
    (found : psKernelExprV2PagedRequire state.arena original = .ok entry)
    (shape : entry.node = .bvar oldIndex) :
    psKernelExprV2NestedOverlay (.app fn arg) original state =
      psKernelDagGeneratedImport (.app fn arg) state := by
  simp only [psKernelExprV2NestedOverlay,readable,found,shape]

end PsKernelNestedOverlayProofs
#print axioms PsKernelNestedOverlayProofs.original_decoded_error_is_first
#print axioms PsKernelNestedOverlayProofs.original_arena_error_is_preserved
#print axioms PsKernelNestedOverlayProofs.unchanged_node_reuses_entire_owner_and_original_id
#print axioms PsKernelNestedOverlayProofs.novel_node_uses_exact_existing_smart_replay
#print axioms PsKernelNestedOverlayProofs.novel_smart_construction_error_never_returns_an_owner
#print axioms PsKernelNestedOverlayProofs.changed_node_kind_uses_exact_generated_import
