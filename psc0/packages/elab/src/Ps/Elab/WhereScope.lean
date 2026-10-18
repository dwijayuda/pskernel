import Ps.Elab.Scope

-- A termination suffix is resolved only if checked dependency dispatch uses it.
-- Keep the original header scope separately from the untouched source syntax.
structure PsWhereTerminationScope where
  resolver : PsScopeResolver
  bound : List String

structure PsScopedLocalDefinition where
  source : PsSyntaxLocalDefinition
  name : PsName
  alias : PsSyntaxName
  terminationScope : Option PsWhereTerminationScope := none

structure PsScopedPreDefinition where
  source : PsSyntaxDeclaration
  alias : PsSyntaxName
  locals : List PsScopedLocalDefinition
  used : List String
  isPrivate : Bool
  registration : Option PsSyntaxRegistration
  terminationScope : Option PsWhereTerminationScope := none

def psWhereSourceParts (source : PsSyntaxDeclaration) :
    Except PsElabError (PsSyntaxDeclaration × List PsSyntaxLocalDefinition × Option PsSourceSpan) := do
  match source with
  | .whereDeclaration parent locals span =>
    if locals.isEmpty then throw (.scope "PSCV0-D-WHERE-01: where requires local definitions")
    match parent with
    | .whereDeclaration .. => throw (.scope "PSCV0-D-WHERE-01: nested where is not selected")
    | _ => return (parent, locals, some span)
  | _ => return (source, [], none)

def psWhereValueParts (source : PsSyntaxDeclaration) :
    Except PsElabError (PsSyntaxName × List PsScopeBinder × PsSyntaxTerm × PsSyntaxTerm) :=
  match source with
  | .definition name binders type value _ | .partialDefinition name binders type value _
  | .noncomputableDefinition name binders type value _
  | .fixedpointDefinition name binders type value _
  | .wellFoundedDefinition name binders type value _ _ => pure (name, binders, type, value)
  | _ => throw (.scope "PSCV0-D-WHERE-01: typed recursive groups require selected value declarations")

def psWhereMapValue (source : PsSyntaxDeclaration) (name : PsSyntaxName)
    (binders : List PsScopeBinder) (type value : PsSyntaxTerm)
    (termination : Option PsSyntaxTermination) : Except PsElabError PsSyntaxDeclaration :=
  match source with
  | .definition _ _ _ _ span => pure (.definition name binders type value span)
  | .partialDefinition _ _ _ _ span => pure (.partialDefinition name binders type value span)
  | .noncomputableDefinition _ _ _ _ span => pure (.noncomputableDefinition name binders type value span)
  | .fixedpointDefinition _ _ _ _ span => pure (.fixedpointDefinition name binders type value span)
  | .wellFoundedDefinition _ _ _ _ _ span =>
    match termination with
    | some suffix => pure (.wellFoundedDefinition name binders type value suffix span)
    | none => throw (.scope "PSCV0-D-WHERE-01: lost total recursion suffix")
  | _ => throw (.scope "PSCV0-D-WHERE-01: invalid parent declaration")

def psWhereLocalAlias (parent : PsSyntaxName) (index : Nat) (span : PsSourceSpan) : PsSyntaxName :=
  PsSyntaxName.mk (["$psc0Where"] ++ parent.segments ++ [psNatToString index]) span

def psScopeWhereTermination (resolver : PsScopeResolver) (bound : List String)
    (termination : PsSyntaxTermination) : Except PsElabError (PsSyntaxTermination × List String) := do
  let measure ← psScopeTerm 4096 resolver bound termination.measure
  let proof ← termination.decreasing.mapM (psScopeTerm 4096 resolver bound)
  return ({ termination with measure := measure.term, decreasing := proof.map (·.term) },
    psScopeUnion measure.used (proof.map (·.used) |>.getD []))

-- Header annotations/defaults see the enclosing header before local helpers
-- enter. Bodies see the local helper frame; own/nested binders shadow it.
def psScopePreDefinition (resolver : PsScopeResolver) (member : PsSyntaxMutualMember)
    (alias : PsSyntaxName) (inheritedPartial : Bool := false) :
    Except PsElabError PsScopedPreDefinition := do
  let (base, locals, whereSpan) ← psWhereSourceParts member.declaration
  let (sourceName, sourceBinders, sourceType, sourceValue) ← psWhereValueParts base
  let qualified := psScopeQualified resolver.scope sourceName
  let name := { qualified with
    segments := (psScopePrivateRewrite resolver qualified.segments).getD qualified.segments }
  let some coreName := psSyntaxNameToName name | throw .emptyName
  let headerResolver := { resolver with mutualAliases := [], localAliases := [] }
  let binders ← psScopeBinders (psScopeTerm 4096 headerResolver) [] sourceBinders
  let type ← psScopeTerm 4096 headerResolver binders.bound sourceType
  let helperNames ← locals.mapM fun localDefinition => do
    if localDefinition.name.segments.length != 1 then
      throw (.scope "PSCV0-D-WHERE-01: local name must be one identifier")
    let some shortName := localDefinition.name.segments.head? | throw .emptyName
    if (locals.filter (fun other => other.name.segments == localDefinition.name.segments)).length != 1 then
      throw (.scope "PSCV0-D-WHERE-01: duplicate local definition")
    return shortName
  let helperAliases := locals.zipIdx.map fun (localDefinition, index) =>
    psWhereLocalAlias name index localDefinition.name.span
  let localFrame := helperNames.zip (helperAliases.map (·.segments))
  let qualifiedFrame := (locals.zip helperAliases).map fun (localDefinition, localAlias) =>
    (name.segments ++ localDefinition.name.segments, localAlias.segments)
  let bodyResolver := { resolver with
    localAliases := localFrame ++ resolver.localAliases
    mutualAliases := qualifiedFrame ++ resolver.mutualAliases }
  let parentBound := binders.bound.filter (fun key => !helperNames.contains key)
  let value ← psScopeTerm 4096 bodyResolver parentBound sourceValue
  let termination := match base with
    | .wellFoundedDefinition _ _ _ _ suffix _ => some suffix
    | _ => none
  let terminationScope := termination.map fun _ =>
    ({ resolver, bound := binders.bound } : PsWhereTerminationScope)
  let scopedLocals ← (locals.zip helperAliases).mapM fun (localDefinition, localAlias) => do
    let localBinders ← psScopeBinders (psScopeTerm 4096 resolver) binders.bound localDefinition.binders
    let localType ← localDefinition.type.mapM (psScopeTerm 4096 resolver localBinders.bound)
    let ownNames := localDefinition.binders.flatMap (fun binder => psScopeBinderKeys binder.fst)
    let localBound := ownNames ++ parentBound
    let localValue ← psScopeTerm 4096 bodyResolver localBound localDefinition.value
    -- Header and body lookup remain checked above. Hints never contribute
    -- section capture keys or decide whether the typed body is recursive.
    let terminationScope := if inheritedPartial then none else
      match localDefinition.recursion with
      | some (.total _) =>
        some ({ resolver, bound := localBinders.bound } : PsWhereTerminationScope)
      | _ => none
    let some shortName := localDefinition.name.segments.head? | throw .emptyName
    let scopedLocal : PsScopedLocalDefinition := {
      source := { localDefinition with
        binders := localBinders.binders
        type := localType.map (·.term)
        value := localValue.term
        recursion := localDefinition.recursion }
      name := psNameAppendStr coreName shortName
      alias := localAlias
      terminationScope }
    let used := psScopeUnion localBinders.used (psScopeUnion (localType.map (·.used) |>.getD [])
      localValue.used)
    return (scopedLocal, used)
  let mapped ← psWhereMapValue base name binders.binders type.term value.term termination
  let source := match whereSpan with
    | some span => PsSyntaxDeclaration.whereDeclaration mapped (scopedLocals.map (·.fst.source)) span
    | none => mapped
  return {
    source, alias
    locals := scopedLocals.map Prod.fst
    used := scopedLocals.foldl (fun used entry => psScopeUnion used entry.snd)
      (psScopeUnion binders.used (psScopeUnion type.used value.used))
    isPrivate := member.isPrivate
    registration := member.registration
    terminationScope }
