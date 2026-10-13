import Ps.Elab.DerivingInhabited
import Ps.Elab.DerivingHashable
import Ps.Elab.DerivingBEq
import Ps.Elab.DerivingRepr
import Ps.Elab.DerivingDecEq

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
