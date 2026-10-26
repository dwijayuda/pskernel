import Ps.KernelCore.API.DagNestedPreprocess
import Ps.KernelCore.Core.ExprV2.Validation

/- Private generated-syntax overlay for nested transformation. An unchanged
   node reuses its original ID; a changed parent keeps each unchanged child ID
   and appends only its novel smart-constructed node. A changed node kind uses
   the existing generated-syntax importer. No original canonical expression is
   reconstructed or imported, no input metadata is trusted before the established
   boundary validator, and no declaration is checked or published here.
   The state must be a synchronized continuation of that validated boundary.
   Results still require independent owning admission and restored validation.
   This is not a new equality/cache authority or a public nested route. -/

def psKernelExprV2NestedOverlayNodeSame
    (left right : PsKernelExprV2Node) : Bool :=
  match left with
  | PsKernelExprV2Node.bvar index =>
      match right with
      | PsKernelExprV2Node.bvar otherIndex =>
          Nat.beq index otherIndex
      | _ => false
  | PsKernelExprV2Node.fvar name =>
      match right with
      | PsKernelExprV2Node.fvar otherName =>
          psKernelNameEq name otherName
      | _ => false
  | PsKernelExprV2Node.mvar name =>
      match right with
      | PsKernelExprV2Node.mvar otherName =>
          psKernelNameEq name otherName
      | _ => false
  | PsKernelExprV2Node.sort level =>
      match right with
      | PsKernelExprV2Node.sort otherLevel =>
          psKernelLevelEq level otherLevel
      | _ => false
  | PsKernelExprV2Node.const name levels =>
      match right with
      | PsKernelExprV2Node.const otherName otherLevels =>
          if psKernelNameEq name otherName then psKernelLevelListEq levels otherLevels else false
      | _ => false
  | PsKernelExprV2Node.app fn arg =>
      match right with
      | PsKernelExprV2Node.app otherFn otherArg =>
          if Nat.beq fn otherFn then Nat.beq arg otherArg else false
      | _ => false
  | PsKernelExprV2Node.lam name type body info =>
      match right with
      | PsKernelExprV2Node.lam otherName otherType otherBody otherInfo =>
          if psKernelNameEq name otherName then if Nat.beq type otherType then if Nat.beq body otherBody then psKernelBinderInfoEq info otherInfo else false else false else false
      | _ => false
  | PsKernelExprV2Node.forallE name type body info =>
      match right with
      | PsKernelExprV2Node.forallE otherName otherType otherBody otherInfo =>
          if psKernelNameEq name otherName then if Nat.beq type otherType then if Nat.beq body otherBody then psKernelBinderInfoEq info otherInfo else false else false else false
      | _ => false
  | PsKernelExprV2Node.letE name type value body nondep =>
      match right with
      | PsKernelExprV2Node.letE otherName otherType otherValue otherBody otherNondep =>
          if psKernelNameEq name otherName then if Nat.beq type otherType then if Nat.beq value otherValue then if Nat.beq body otherBody then psKernelBoolEq nondep otherNondep else false else false else false else false
      | _ => false
  | PsKernelExprV2Node.lit value =>
      match right with
      | PsKernelExprV2Node.lit otherValue =>
          psKernelLiteralEq value otherValue
      | _ => false
  | PsKernelExprV2Node.mdata tag body =>
      match right with
      | PsKernelExprV2Node.mdata otherTag otherBody =>
          if Nat.beq tag otherTag then Nat.beq body otherBody else false
      | _ => false
  | PsKernelExprV2Node.proj name index body =>
      match right with
      | PsKernelExprV2Node.proj otherName otherIndex otherBody =>
          if psKernelNameEq name otherName then if Nat.beq index otherIndex then Nat.beq body otherBody else false else false
      | _ => false

def psKernelExprV2NestedOverlayFinish
    (source : PsKernelExpr) (original : Nat)
    (oldNode newNode : PsKernelExprV2Node) (state : PsKernelDagGeneratedState) :
    Except String (Prod PsKernelDagGeneratedState Nat) :=
  if psKernelExprV2NestedOverlayNodeSame oldNode newNode then
    Except.ok (Prod.mk state original)
  else
    psKernelDagGeneratedFinish source state
      (psKernelExprV2PagedReplayNode state.arena newNode)

def psKernelExprV2NestedOverlay
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
                  match psKernelExprV2NestedOverlay fn oldFn state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match psKernelExprV2NestedOverlay arg oldArg (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.app (Prod.snd child0) (Prod.snd child1)) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.lam name type body info =>
              match entry.node with
              | PsKernelExprV2Node.lam oldName oldType oldBody oldInfo =>
                  match psKernelExprV2NestedOverlay type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match psKernelExprV2NestedOverlay body oldBody (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.lam name (Prod.snd child0) (Prod.snd child1) info) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.forallE name type body info =>
              match entry.node with
              | PsKernelExprV2Node.forallE oldName oldType oldBody oldInfo =>
                  match psKernelExprV2NestedOverlay type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match psKernelExprV2NestedOverlay body oldBody (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          psKernelExprV2NestedOverlayFinish source original entry.node
                            (PsKernelExprV2Node.forallE name (Prod.snd child0) (Prod.snd child1) info) (Prod.fst child1)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.letE name type value body nondep =>
              match entry.node with
              | PsKernelExprV2Node.letE oldName oldType oldValue oldBody oldNondep =>
                  match psKernelExprV2NestedOverlay type oldType state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      match psKernelExprV2NestedOverlay value oldValue (Prod.fst child0) with
                      | Except.error error => Except.error error
                      | Except.ok child1 =>
                          match psKernelExprV2NestedOverlay body oldBody (Prod.fst child1) with
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
                  match psKernelExprV2NestedOverlay body oldBody state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      psKernelExprV2NestedOverlayFinish source original entry.node
                        (PsKernelExprV2Node.mdata tag (Prod.snd child0)) (Prod.fst child0)
              | _ => psKernelDagGeneratedImport source state
          | PsKernelExpr.proj name index body =>
              match entry.node with
              | PsKernelExprV2Node.proj oldName oldIndex oldBody =>
                  match psKernelExprV2NestedOverlay body oldBody state with
                  | Except.error error => Except.error error
                  | Except.ok child0 =>
                      psKernelExprV2NestedOverlayFinish source original entry.node
                        (PsKernelExprV2Node.proj name index (Prod.snd child0)) (Prod.fst child0)
              | _ => psKernelDagGeneratedImport source state
