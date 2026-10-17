import Ps.Environment.StandardPartialFixpointData
import Ps.Environment.StandardClass

/-!
Pinned Lean 4.35.0 fixedpoint order library, with the exact 117-declaration
closure retained from Init.Internal.Order.Basic. Importing a logical closure
does not register every native instance that happens to occur in its proofs.

The two classes and eleven ordinary dictionaries below were inspected through
the pinned native environment extensions. Both classes have no output
parameters or output levels; every selected instance has priority 1000.
Classical.propDecidable remains a checked logical definition, not an
automatically selected runtime decision procedure.
-/

def psStandardPartialFixpointExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardPartialFixpointCandidateDeclarations.foldl
    psEnvironmentInsert environment
  let environment := psStandardPartialFixpointCandidateReducibility.foldl
    (fun env (name, status) => psEnvironmentSetReducibility env name status) environment
  let environment := ["Lean.Order.PartialOrder", "Lean.Order.CCPO"].foldl (fun env name =>
    if env.classes.any (psNameEq (psDecisionName name)) then env
    else psStandardRegisterClass env name) environment
  let registrations : List (String × String) := [
    ("Lean.Order.CCPO.toPartialOrder", "Lean.Order.PartialOrder"),
    ("Lean.Order.instOrderPi", "Lean.Order.PartialOrder"),
    ("Lean.Order.instCCPOPi", "Lean.Order.CCPO"),
    ("Lean.Order.instPartialOrderPProd", "Lean.Order.PartialOrder"),
    ("Lean.Order.instCCPOPProd", "Lean.Order.CCPO"),
    ("Lean.Order.instPartialOrderOption", "Lean.Order.PartialOrder"),
    ("Lean.Order.instCCPOOption", "Lean.Order.CCPO"),
    ("Lean.Order.instPartialOrderUnit", "Lean.Order.PartialOrder"),
    ("Lean.Order.instCCPOUnit", "Lean.Order.CCPO"),
    ("Lean.Order.FlatOrder.instOrder", "Lean.Order.PartialOrder"),
    ("Lean.Order.FlatOrder.instCCPO", "Lean.Order.CCPO")]
  registrations.foldl (fun env (name, className) =>
    psStandardRegisterInstances env className
      (psStandardPartialFixpointCandidateDeclarations.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) (psDecisionName name))) 1000) environment
