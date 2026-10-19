import Ps.Environment.CompilerSourceCandidateData

-- Assembly checks keep the authored roster and source metadata coherent.
-- Independent native admission remains the authority for types and bodies.
private def psCompilerSourceCandidateExprNames : PsExpr → List PsName
  | .constE name _ => [name]
  | .app fn arg =>
      psCompilerSourceCandidateExprNames fn ++ psCompilerSourceCandidateExprNames arg
  | .lam _ type body _ | .forallE _ type body _ =>
      psCompilerSourceCandidateExprNames type ++ psCompilerSourceCandidateExprNames body
  | .letE _ type value body =>
      psCompilerSourceCandidateExprNames type ++ psCompilerSourceCandidateExprNames value ++
        psCompilerSourceCandidateExprNames body
  | .proj owner _ value => owner :: psCompilerSourceCandidateExprNames value
  | _ => []

private def psCompilerSourceCandidateDeclNames (declaration : PsDeclaration) :
    List PsName :=
  let typeNames := psCompilerSourceCandidateExprNames (psDeclarationType declaration)
  typeNames ++ (match declaration with
    | .definitionDecl _ _ _ value | .theoremDecl _ _ _ value
    | .opaqueDecl _ _ _ value | .partialDecl _ _ _ value =>
        psCompilerSourceCandidateExprNames value
    | .inductiveDecl info => info.constructors
    | .constructorDecl info => [info.inductiveName]
    | .recursorDecl info => info.inductiveNames
    | _ => [])

-- The public owner below supplies the complete measured native tag list.
private def psCompilerSourceCandidateEnvironmentWithNoncomputable
    (noncomputableNames : List PsName) : Except String PsEnvironment := do
  if !psCoreFoundationCandidateBoundary.isEmpty then
    throw "CORE-SOURCE-CANDIDATE: external declaration boundary"
  let mut environment := psEnvironmentEmpty
  for declaration in psCoreFoundationCandidateDeclarations do
    match declaration with
    | .axiomDecl .. => throw "CORE-SOURCE-CANDIDATE: assumption in declaration roster"
    | .partialDecl .. => throw "CORE-SOURCE-CANDIDATE: partial declaration in source base"
    | _ => pure ()
    let some next := psEnvironmentAdd environment declaration
      | throw ("CORE-SOURCE-CANDIDATE: duplicate declaration " ++
          psNameToString (psDeclarationName declaration))
    environment := next
  for declaration in psCoreFoundationCandidateDeclarations do
    for name in psCompilerSourceCandidateDeclNames declaration do
      if !psEnvironmentContains environment name then
        throw ("CORE-SOURCE-CANDIDATE: missing declaration " ++ psNameToString name)
  let mut statuses : List PsName := []
  for (name, status) in psCoreFoundationCandidateReducibility do
    if statuses.any (psNameEq name) then
      throw ("CORE-SOURCE-CANDIDATE: duplicate reducibility " ++ psNameToString name)
    if !psEnvironmentContains environment name then
      throw ("CORE-SOURCE-CANDIDATE: missing reducibility target " ++ psNameToString name)
    statuses := name :: statuses
    environment := psEnvironmentSetReducibility environment name status
  let mut tagged : List PsName := []
  for name in noncomputableNames do
    if tagged.any (psNameEq name) then
      throw ("CORE-SOURCE-CANDIDATE: duplicate noncomputable tag " ++ psNameToString name)
    if !psEnvironmentContains environment name then
      throw ("CORE-SOURCE-CANDIDATE: missing noncomputable target " ++ psNameToString name)
    tagged := name :: tagged
    environment := psEnvironmentMarkNoncomputable environment name
  let className : PsName := .str .anonymous "OfNat"
  let some (.inductiveDecl _) := psEnvironmentFind environment className
    | throw "CORE-SOURCE-CANDIDATE: missing OfNat class declaration"
  let instanceName : PsName := .str .anonymous "instOfNatNat"
  let some (.definitionDecl _ levels type _) := psEnvironmentFind environment instanceName
    | throw "CORE-SOURCE-CANDIDATE: missing instOfNatNat definition"
  if !levels.isEmpty then
    throw "CORE-SOURCE-CANDIDATE: instOfNatNat universe metadata changed"
  if !psEnvironmentContains environment (psNameAppendStr (.str .anonymous "Bool") "decEq") then
    throw "CORE-SOURCE-CANDIDATE: missing direct Bool.decEq"
  let ordinary : PsInstanceEntry := {
    value := .constE instanceName []
    type := type
    priority := 1000
    className := some className
    levelParams := levels }
  let instances := psInstanceIndexAdd psInstanceIndexEmpty ordinary
  let instances := psInstanceIndexAddDefault instances { ordinary with priority := 100 }
  return {
    environment with
    classes := [className]
    classParameters := [(className, { outputs := [], outputLevels := [] })]
    instances := instances }

-- Exact native Init metadata measured at the pinned Lean commit by
-- auditCoreFoundationCandidateMetadata. Bool.not is reached by Bool.decEq;
-- retaining its native tag does not establish portable runtime correspondence.
def psCompilerSourceCandidateNoncomputableNames : List PsName :=
  [psNameAppendStr (.str .anonymous "Bool") "not"]

def psCompilerSourceCandidateEnvironment : Except String PsEnvironment :=
  psCompilerSourceCandidateEnvironmentWithNoncomputable
    psCompilerSourceCandidateNoncomputableNames
