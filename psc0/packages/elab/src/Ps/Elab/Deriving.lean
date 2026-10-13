import Ps.Elab.DerivingInhabited
import Ps.Elab.DerivingBEq

-- Handlers return ordinary Core definitions. The source command owns instance
-- registration and origin bookkeeping; official Lean still checks admission.
def psElabDeriveHandler (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) (handler : PsSyntaxName) :
    Except PsElabError PsDeclaration :=
  match handler.segments with
  | ["Inhabited"] => psElabDeriveInhabited environment origin
  | ["BEq"] => psElabDeriveBEq environment origin
  | _ => .error (.data "deriving handler is selected but not yet implemented")
