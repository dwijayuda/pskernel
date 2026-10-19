import Ps.Elab.Elimination
import Ps.Elab.Postponed

-- Adapted from Lean 4.35.0 Lean/Elab/Tactic/ElabTerm.lean
-- (eb6cafb7290e8bd5f2937522d8d804f58f02bafc), runTermElab and
-- closeMainGoalUsing; upstream is Apache-2.0, Microsoft/Leonardo de Moura.
-- Complete a tactic-owned term before inspecting its holes or introducing
-- a local fact. Outer pending work retains its original owner and schedule.
-- Natural proof holes are not synthesized here: exact/local/refine retain
-- their existing separate refusal or goal-collection policies.
def psProofWithTermSynthesisAnd {α : Type} (elaborate : PsElaborator)
    (context : PsElabContext)
    (action : PsElabContext → Except PsElabError (PsElabTermResult × α)) :
    Except PsElabError (PsElabTermResult × α) := do
  let (value, extra) ← action { context with pending := [], postponing := true }
  let value ← psElabDrainPending elaborate value
  return ({ value with context := { value.context with
    pending := context.pending, postponing := context.postponing } }, extra)

def psProofWithTermSynthesis (elaborate : PsElaborator)
    (context : PsElabContext)
    (action : PsElabContext → Except PsElabError PsElabTermResult) :
    Except PsElabError PsElabTermResult := do
  let (value, _) ← psProofWithTermSynthesisAnd elaborate context fun current => do
    let value ← action current
    return (value, ())
  return value

