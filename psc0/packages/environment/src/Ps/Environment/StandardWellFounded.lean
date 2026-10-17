import Ps.Environment.StandardWellFoundedData
import Ps.Environment.StandardClass

/-!
Pinned Lean 4.35.0 logical well-founded foundation. The data is the exact
34-declaration closure regenerated against the frozen pre-WF Standard.
Class registration is separate from reducibility: Nat.lt_wfRel and emptyWf
are named dictionary definitions, not native instances.

This stage prepares logical declarations and actual selected instance metadata.
Runtime relation representations and broader recursion construction belong to
their typed elaboration/erasure owners.
-/

def psStandardWellFoundedExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardWellFoundedDeclarations.foldl psEnvironmentInsert environment
  let environment := psStandardWellFoundedReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let environment := ["SizeOf", "WellFoundedRelation"].foldl (fun env name =>
    if env.classes.any (psNameEq (psDecisionName name)) then env
    else psStandardRegisterClass env name) environment
  let register := fun env className name priority =>
    psStandardRegisterInstances env className
      (psStandardWellFoundedDeclarations.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) (psDecisionName name))) priority
  -- Init/SizeOf.lean: ordinary low-priority instance, not default_instance.
  let environment := register environment "SizeOf" "instSizeOfDefault" 100
  let environment := register environment "SizeOf" "instSizeOfNat" 1000
  -- Init/WF.lean: size-based fallback is low; product lexicographic is default.
  let environment := register environment "WellFoundedRelation" "sizeOfWFRel" 100
  let environment := register environment "WellFoundedRelation" "Prod.instWellFoundedRelation" 1000
  { environment with exportedAliases :=
      (psRootName "sizeOf", psDecisionName "SizeOf.sizeOf") :: environment.exportedAliases }
