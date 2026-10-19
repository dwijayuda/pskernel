import Ps.Environment.BootstrapData

-- An independently authored, empty-boundary declaration asset. This owner
-- installs its exact declarations and search transparency; it does not select
-- the compiler's default environment or claim source/Core completeness.
def psBootstrapEnvironment : PsEnvironment :=
  let environment := psCoreBootstrapCandidateDeclarations.foldl
    psEnvironmentInsert psEnvironmentEmpty
  psCoreBootstrapCandidateReducibility.foldl
    (fun current entry =>
      psEnvironmentSetReducibility current entry.fst entry.snd)
    environment
