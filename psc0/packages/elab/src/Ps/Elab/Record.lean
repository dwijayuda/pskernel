import Ps.Elab.Application
import Ps.Elab.Binders

structure PsElabRecordShape where
  familyName : PsName
  constructorName : PsName
  fieldNames : List String

-- Select the nominal structure from its type; field names never guess a shape.
def psElabRecordFieldNames (skip count : Nat) (type : PsExpr) : Option (List String) := do
  match skip with
  | skip + 1 =>
    let .forallE _ _ body _ := type | none
    psElabRecordFieldNames skip count body
  | 0 => match count with
    | 0 => some []
    | count + 1 =>
      let .forallE name _ body _ := type | none
      let rest ← psElabRecordFieldNames 0 count body
      some (psNameLastComponent name :: rest)

def psElabRecordShape (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsElabRecordShape := do
  let view := psInferAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE familyName _ := view.head
    | throw (.invalidArgument "record requires an expected nominal structure type")
  let some info := psEnvironmentFindInductive context.environment familyName
    | throw (.invalidArgument "record requires an expected nominal structure type")
  if !info.isStructure || view.args.length != info.numParams then
    throw (.invalidArgument "record requires an expected nominal structure type")
  let [constructorName] := info.constructors | throw .unsupportedTerm
  let some constructor := psEnvironmentFindConstructor context.environment constructorName
    | throw .unsupportedTerm
  let some fieldNames := psElabRecordFieldNames constructor.numParams constructor.numFields constructor.type
    | throw .unsupportedTerm
  return { familyName, constructorName, fieldNames }

def psElabRecordFields (shape : PsElabRecordShape)
    (fields : List (PsSyntaxName × PsSyntaxTerm)) : Except PsElabError PsElabNamedArguments := do
  fields.foldlM (fun names (source, value) => do
    let [label] := source.segments | throw (.invalidArgument "record field must be an identifier")
    if !shape.fieldNames.contains label then throw (.invalidArgument "unknown record field")
    let name := psRootName label
    if (psElabTakeNamed name names).fst.isSome then throw (.invalidArgument "duplicate record field")
    return names ++ [(name, value)]) []

-- Seed known uniform parameters before elaborating fields. Field lambdas and
-- dependent proof fields then receive the actual expected dictionary/record type.
def psElabRecordConstructor (context : PsElabContext) (found : PsElabRecordShape)
    (target : PsExpr) : Except PsElabError PsElabTermResult := do
  let (context, term) ← psElabResolvedReference context (.global found.constructorName)
  let constructor ← psElabResolvedTerm context term none
  let some info := psEnvironmentFindConstructor context.environment found.constructorName
    | throw .unsupportedTerm
  let view := psInferAppView (psWhnf context.environment context.metaContext context.localContext target)
  let .constE name _ := view.head | return constructor
  if !psNameEq name info.inductiveName then return constructor
  if view.args.length != info.numParams then throw .unsupportedTerm
  view.args.foldlM (fun current value => do
    let pi ← (psInferEnsureForall current.context.environment current.context.metaContext
      current.context.localContext current.type).mapError PsElabError.infer
    let argument ← psElabResolvedTerm current.context value (some pi.domain)
    return psElabApplyValue current argument pi.body) constructor

inductive PsElabRecordArgument where
  | source (term : PsSyntaxTerm)
  | retained (value : PsExpr)

def psElabRecordArgument (elaborate : PsElaborator) (context : PsElabContext)
    (argument : PsElabRecordArgument) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match argument with
  | .source source => elaborate context source expected
  | .retained value => psElabResolvedTerm context value expected

def psElabBuildRecord (elaborate : PsElaborator) (context : PsElabContext)
    (shape : PsElabRecordShape) (target : PsExpr)
    (fields : List (PsName × PsElabRecordArgument)) : Except PsElabError PsElabTermResult := do
  let constructor ← psElabRecordConstructor context shape target
  let application ← psElabApplyOrderedWith (psElabRecordArgument elaborate) 4096
    constructor [] fields [] true (some target)
  psElabFinishApplication application (some target)

def psElabRecord (elaborate : PsElaborator) (context : PsElabContext)
    (fields : List (PsSyntaxName × PsSyntaxTerm)) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some target := expected
    | throw (.invalidArgument "record requires an expected nominal structure type")
  let shape ← psElabRecordShape context target
  let names ← psElabRecordFields shape fields
  -- The shared application queue fills declared defaults and instance fields;
  -- any missing required field leaves an unapplied telescope and is rejected.
  psElabBuildRecord elaborate context shape target (names.map fun (name, value) =>
    (name, PsElabRecordArgument.source value))

-- The source is bound once. Every retained projection is checked against the
-- current constructor domain after earlier replacements have been substituted.
def psElabRecordUpdate (elaborate : PsElaborator) (context : PsElabContext)
    (source : PsSyntaxTerm) (fields : List (PsSyntaxName × PsSyntaxTerm))
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let value ← elaborate context source expected
  let shape ← psElabRecordShape value.context value.type
  let names ← psElabRecordFields shape fields
  let sourceName := PsName.num .anonymous value.context.localContext.nextId
  let pushed := psLocalPushLet value.context.localContext sourceName value.type value.term
  let inner := psElabContextWithLocal value.context pushed.context
  let arguments := shape.fieldNames.zipIdx |>.map fun (label, index) =>
    let name := psRootName label
    let argument := match (psElabTakeNamed name names).fst with
      | some source => PsElabRecordArgument.source source
      | none => .retained (.proj shape.familyName index (.fvar pushed.id))
    (name, argument)
  let result ← psElabBuildRecord elaborate inner shape value.type arguments
  psElabCloseLetScope context result pushed.id sourceName value.type value.term expected
