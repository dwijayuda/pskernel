import Ps.Elab.ProofApply
import Ps.Elab.RCases

-- Adapted from Lean 4.35.0 Lean/Elab/Tactic/Ext.lean at
-- eb6cafb7290e8bd5f2937522d8d804f58f02bafc (Apache-2.0).
-- The environment records actual registered theorem identities. A declaration
-- name or a source-written ".ext" suffix never registers a theorem.
def psProofExtOne (state : PsProofState) (span : PsSourceSpan) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let view := psExprAppView target
  match view.head, view.args with
  | .constE name _, [_, _, _] =>
    if !psNameEq name psEqName then throw (.proof "ext requires an equality target")
  | _, _ => throw (.proof "ext requires an equality target")
  for name in context.environment.extTheorems.reverse do
    let attempt := do
      let source : PsSyntaxName := {
        segments := psNameToSegments name, span, resolvedName := some name }
      let candidate ← psElabReference context source none
      let value ← psProofApplyTerm 4096 candidate target
      -- Native withNewMCtxDepth freezes the existing target while selecting
      -- a candidate. In particular, funext must not turn an unknown equality
      -- type into a function type and repeatedly invent arguments.
      if !psExprAlphaEq target (psMetaInstantiate value.context.metaContext target) then
        throw (.proof "ext candidate changed the existing equality target")
      psProofApplied state goal context.metaContext.nextId value true
    match attempt with
    | .ok result => return result
    | .error error => if psElabErrorIsResource error then throw error
  throw (.proof "ext found no applicable registered extensionality theorem")

def psProofExtPatterns (fuel : Nat) (patterns : List PsSyntaxRIntroPattern)
    (annotation : Option PsSyntaxTerm := none) :
    Except PsElabError (List PsSyntaxRCasesPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    patterns.foldlM (fun result pattern => do
      let patterns ← match pattern with
        | .group patterns type _ =>
          psProofExtPatterns fuel patterns (if type.isSome then type else annotation)
        | .pattern pattern => pure [match annotation with
            | none => pattern
            | some type => .typed pattern type (psSyntaxRCasesPatternSpan pattern)]
      return result ++ patterns) []

mutual
def psProofExtVisit (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel depth : Nat) (failIfUnchanged : Bool) (state : PsProofState)
    (patterns : List PsSyntaxRCasesPattern) (span : PsSourceSpan) :
    Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match depth with
    | 0 => pure state
    | depth + 1 =>
      let attempt := do
        let next ← psProofExtOne state span
        let mut current := next
        let mut goals := []
        for goal in next.goals do
          if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
          let result ← psProofExtIntros elaborate scope fuel depth
            { current with goals := [goal] } patterns span
          current := result
          goals := goals ++ result.goals
        psProofNormalize { current with goals }
      match attempt with
      | .ok next => pure next
      | .error error =>
        if failIfUnchanged || psElabErrorIsResource error then throw error
        -- Native withExtN catches the whole later ext/introduction attempt.
        -- Its immutable failed branch contributes no assignment or goal.
        pure state

def psProofExtIntros (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (fuel depth : Nat) (state : PsProofState)
    (patterns : List PsSyntaxRCasesPattern) (span : PsSourceSpan) :
    Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match patterns with
    | [] =>
      let next ← psProofIntros state []
      psProofExtVisit elaborate scope fuel depth false next [] span
    | pattern :: rest =>
      let (_, _, target) ← psProofMain state
      match target with
      | .forallE .. =>
        let next ← psProofRIntro elaborate scope state [.pattern pattern] none
        let mut current := next
        let mut goals := []
        for goal in next.goals do
          if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
          let result ← psProofExtIntros elaborate scope fuel depth
            { current with goals := [goal] } rest span
          current := result
          goals := goals ++ result.goals
        psProofNormalize { current with goals }
      | _ => psProofExtVisit elaborate scope fuel depth false state patterns span
end

def psProofExt (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (patterns : List PsSyntaxRIntroPattern)
    (depth : Nat) (span : PsSourceSpan) : Except PsElabError PsProofState := do
  let (goal, _, _) ← psProofMain state
  let patterns ← psProofExtPatterns 4096 patterns
  let saved := state.goals.drop 1
  let result ← psProofExtVisit elaborate scope 4096 depth true
    { state with goals := [goal] } patterns span
  psProofNormalize { result with goals := result.goals ++ saved }
