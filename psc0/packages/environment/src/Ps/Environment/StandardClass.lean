import Ps.Environment.StandardNumeric

-- Shared explicit registration; logical declarations and instance search inputs
-- remain separate. Importing a proof closure never silently adds instances.
def psStandardRegisterInstances (environment : PsEnvironment) (className : String)
    (declarations : List PsDeclaration) (priority : Nat := 1000) : PsEnvironment :=
  -- Standard factories create ordinary instance definitions. Apply the native
  -- instance-command default only when no status was provided; imported native
  -- metadata and explicit reducible/irreducible choices remain authoritative.
  let environment := declarations.foldl (fun env declaration =>
    let name := psDeclarationName declaration
    if (psDeclarationValue declaration).isSome &&
        (psEnvironmentReducibility? env name).isNone then
      psEnvironmentSetReducibility env name .instanceReducible
    else env) environment
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


-- Register the already checked Nat law after the frozen authoring bases.
def psStandardLawfulBEqExtend (environment : PsEnvironment) : PsEnvironment :=
  let className := psRootName "LawfulBEq"
  match psEnvironmentFindInductive environment className,
      psEnvironmentFind environment (psDecisionName "Nat.instLawfulBEq") with
  | some _, some dictionary =>
    let environment := if environment.classes.any (psNameEq className) then environment
      else psStandardRegisterClass environment "LawfulBEq"
    psStandardRegisterInstances environment "LawfulBEq" [dictionary] 1000
  | _, _ => environment
