import Ps.Elab.DerivingInhabited
import Ps.Elab.DerivingHashable
import Ps.Elab.DerivingBEq
import Ps.Elab.DerivingRepr
import Ps.Elab.DerivingDecEq

-- The selected deriving registry is also consumed by the native Standard
-- surface audit. Keep this order stable; new handlers require explicit review.
def psElabSelectedDerivingHandlers : List String :=
  ["Inhabited", "BEq", "DecidableEq", "Repr", "Hashable"]

-- Handlers return ordinary Core definitions. The source command owns instance
-- registration and origin bookkeeping; official Lean still checks admission.
def psElabDeriveHandler (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (handler : PsSyntaxName) :
    Except PsElabError PsDeclaration :=
  match handler.segments with
  | ["Inhabited"] => psElabDeriveInhabited environment origin
  | ["BEq"] => psElabDeriveBEq environment origin
  | ["Hashable"] => psElabDeriveHashable environment origin
  | ["Repr"] => psElabDeriveRepr environment origin
  | ["DecidableEq"] => psElabDeriveDecEq environment origin
  | _ => .error (.data "deriving handler is selected but not yet implemented")

-- Native group API. Provenance must name exactly the registered family group;
-- the source command still selects singleton declarations under v7.2 grammar.
-- Every instance is built against the input environment, so another generated
-- group instance cannot become an assumed recursive field dictionary.
def psElabDeriveGroupHandler (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (handler : PsSyntaxName) :
    Except PsElabError (List PsDeclaration) := do
  match handler.segments with
  | ["Hashable"] | ["Repr"] | ["BEq"] => pure ()
  | _ => throw (.data "deriving handler does not provide a complete group motive family")
  let name ← psElabDeriveSourceFamily origin
  let some info := psEnvironmentFindInductive environment name
    | throw (.data "derived family is not an inductive")
  let some group := psInductiveGroupIdentityFor
      (psEnvironmentFindInductive environment) (psEnvironmentFindRecursor environment) info
    | throw (.data "deriving requires a complete inductive group")
  let names := origin.members.filterMap fun member =>
    match member.role with
    | .inductiveType | .structureType => some member.name
    | _ => none
  if !psInductiveGroupNamesEqual names (psInductiveGroupNames group) then
    throw (.data "deriving origin does not retain the complete ordered group")
  group.members.mapM fun member =>
    let selected := origin.members.filter fun entry =>
      match entry.role with
      | .inductiveType | .structureType => psNameEq entry.name member.name
      | _ => true
    psElabDeriveHandler environment { origin with members := selected } handler

