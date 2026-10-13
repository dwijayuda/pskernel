import Ps.Environment.StandardNumeric

-- Shared explicit registration; logical declarations and instance search inputs
-- remain separate. Importing a proof closure never silently adds instances.
def psStandardRegisterInstances (environment : PsEnvironment) (className : String)
    (declarations : List PsDeclaration) (priority : Nat := 1000) : PsEnvironment :=
  let instances := declarations.foldl (fun index declaration =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some (psDecisionName className)
      priority }) environment.instances
  { environment with instances }

def psStandardRegisterClass (environment : PsEnvironment) (name : String) : PsEnvironment :=
  let name := psDecisionName name
  { environment with
    classes := name :: environment.classes
    classParameters := (name, { outputs := [], outputLevels := [] }) :: environment.classParameters }

