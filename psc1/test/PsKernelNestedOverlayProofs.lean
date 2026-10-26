import Lean
import Ps.KernelCore.API.DagNestedOverlay

namespace PsKernelNestedOverlayProofs

private def overlayBeforePortableMatch
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState Nat) :=
  match psKernelExprV2DecodedRequire state.built original with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelExprV2PagedRequire state.arena original with
      | Except.error error => Except.error error
      | Except.ok entry =>
          match source with
          | PsKernelExpr.bvar index =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.bvar index) state
          | PsKernelExpr.fvar name =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.fvar name) state
          | PsKernelExpr.mvar name =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.mvar name) state
          | PsKernelExpr.sort level =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.sort level) state
          | PsKernelExpr.const name levels =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.const name levels) state
          | PsKernelExpr.app fn arg =>
              match entry.node with
              | PsKernelExprV2Node.app oldFn oldArg =>
                  match overlayBeforePortableMatch fn oldFn state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match overlayBeforePortableMatch arg oldArg (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.app (Prod.snd child0) (Prod.snd child1)) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.lam name type body info =>
              match entry.node with
              | PsKernelExprV2Node.lam oldName oldType oldBody oldInfo =>
                  match overlayBeforePortableMatch type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match overlayBeforePortableMatch body oldBody (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.lam name (Prod.snd child0) (Prod.snd child1) info) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.forallE name type body info =>
              match entry.node with
              | PsKernelExprV2Node.forallE oldName oldType oldBody oldInfo =>
                  match overlayBeforePortableMatch type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match overlayBeforePortableMatch body oldBody (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.forallE name (Prod.snd child0) (Prod.snd child1) info) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.letE name type value body nondep =>
              match entry.node with
              | PsKernelExprV2Node.letE oldName oldType oldValue oldBody oldNondep =>
                  match overlayBeforePortableMatch type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match overlayBeforePortableMatch value oldValue (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          match overlayBeforePortableMatch body oldBody (Prod.fst child1) with
                          | Except.error error => Except.error error
                          | Except.ok child2 =>
                              psKernelExprV2NestedOverlayFinish source original entry.node
                                (PsKernelExprV2Node.letE name (Prod.snd child0) (Prod.snd child1) (Prod.snd child2) nondep) (Prod.fst child2)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.lit value =>
              psKernelExprV2NestedOverlayFinish source original entry.node
                (PsKernelExprV2Node.lit value) state
          | PsKernelExpr.mdata tag body =>
              match entry.node with
              | PsKernelExprV2Node.mdata oldTag oldBody =>
                  match overlayBeforePortableMatch body oldBody state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      psKernelExprV2NestedOverlayFinish source original entry.node
                        (PsKernelExprV2Node.mdata tag (Prod.snd child0)) (Prod.fst child0)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.proj name index body =>
              match entry.node with
              | PsKernelExprV2Node.proj oldName oldIndex oldBody =>
                  match overlayBeforePortableMatch body oldBody state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      psKernelExprV2NestedOverlayFinish source original entry.node
                        (PsKernelExprV2Node.proj name index (Prod.snd child0)) (Prod.fst child0)
              | _ => psKernelDagGeneratedImport source state

/- These are conditional private-machine protocols. They neither assume a
   caller arena is valid nor establish the still-open global replay theorem.
   Successful owning admission/restoration remains mandatory before publish. -/

theorem original_decoded_error_is_first
    (source : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (error : String)
    (missing : psKernelExprV2DecodedRequire state.built original = .error error) :
    psKernelExprV2NestedOverlay source original state = .error error := by
  cases source <;> simp only [psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,missing]

theorem original_arena_error_is_preserved
    (source decoded : PsKernelExpr) (original : Nat) (state : PsKernelDagGeneratedState)
    (error : String)
    (readable : psKernelExprV2DecodedRequire state.built original = .ok decoded)
    (missing : psKernelExprV2PagedRequire state.arena original = .error error) :
    psKernelExprV2NestedOverlay source original state = .error error := by
  cases source <;> simp only [psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,readable,missing]

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
  simp only [psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,readable,found,shape]

theorem portable_match_retains_every_original_state_and_error (source : PsKernelExpr) :
    ∀ original state, overlayBeforePortableMatch source original state =
      psKernelExprV2NestedOverlay source original state := by
  induction source with
  | bvar index =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | fvar name =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | mvar name =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | sort level =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | const name levels =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | lit value =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal]
  | app fn arg ihFn ihArg =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihFn,ihArg]
  | lam name domain body info ihDomain ihBody =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihDomain,ihBody]
  | forallE name domain body info ihDomain ihBody =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihDomain,ihBody]
  | letE name domain value body nondep ihDomain ihValue ihBody =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihDomain,ihValue,ihBody]
  | mdata tag body ihBody =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihBody]
  | proj name index body ihBody =>
      intro original state
      cases decoded : psKernelExprV2DecodedRequire state.built original <;>
        cases found : psKernelExprV2PagedRequire state.arena original <;>
          simp only [decoded,found,overlayBeforePortableMatch,psKernelExprV2NestedOverlay,psKernelExprV2NestedOverlayReadOriginal,ihBody]

end PsKernelNestedOverlayProofs
#print axioms PsKernelNestedOverlayProofs.original_decoded_error_is_first
#print axioms PsKernelNestedOverlayProofs.original_arena_error_is_preserved
#print axioms PsKernelNestedOverlayProofs.unchanged_node_reuses_entire_owner_and_original_id
#print axioms PsKernelNestedOverlayProofs.novel_node_uses_exact_existing_smart_replay
#print axioms PsKernelNestedOverlayProofs.novel_smart_construction_error_never_returns_an_owner
#print axioms PsKernelNestedOverlayProofs.changed_node_kind_uses_exact_generated_import
#print axioms PsKernelNestedOverlayProofs.portable_match_retains_every_original_state_and_error
