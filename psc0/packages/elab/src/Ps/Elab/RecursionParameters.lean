import Ps.Elab.Binders

/-
Typed fixed/evolving parameter ownership, following Lean 4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
Lean/Elab/PreDefinition/FixedParams.lean:107-120,180-237,250-268.
Call arguments are compared reducibly, without proof irrelevance, in their
real local contexts. The resulting plan is revalidated on the final body;
it does not supply an equation or permit an unchecked recursive call.
-/

structure PsElabRecursionParameterPlan where
  parameterIds : List Nat
  majorId : Nat
  packedIds : Option (Nat × Nat) := none
  fixedIds : List Nat
  stateIds : List Nat

def psElabRecursionParameterArgument (ids : List Nat) (arguments : List PsExpr)
    (id : Nat) : Option PsExpr :=
  ((ids.zip arguments).find? (fun entry => entry.fst == id)).map Prod.snd

def psElabRecursionParameterIsFixed (context : PsElabContext)
    (ids : List Nat) (calls : List PsElabRecursionCall) (id : Nat) : Bool :=
  calls.all fun call =>
    match psElabRecursionParameterArgument ids call.arguments id with
    | none => false
    | some argument =>
      !psExprHasUnresolvedMeta (psMetaInstantiate context.metaContext argument) &&
        psDefEqReadOnlyWithTransparency .reducible context.environment context.metaContext
          call.localContext (.fvar id) argument

-- Local declarations are dependency ordered. A single oldest-first pass
-- closes the transitive dependencies of both binder types and let values.
def psElabRecursionParameterDependencies (context : PsElabContext)
    (roots : List Nat) : List Nat :=
  context.localContext.declarations.reverse.foldl (fun known declaration =>
    let id := psLocalDeclId declaration
    let values := match declaration with
      | .binding _ _ type _ => [type]
      | .letDecl _ _ type value => [type, value]
    let dependencies := values.flatMap fun value =>
      psExprFVarIds (psMetaInstantiate context.metaContext value)
    if known.contains id || !dependencies.any known.contains then known
    else known ++ [id]) roots

def psElabRecursionMeasureParameterPlan (context : PsElabContext)
    (ids : List Nat) (calls : List PsElabRecursionCall) (measure : PsExpr) :
    Except PsElabError PsElabRecursionParameterPlan := do
  if calls.isEmpty then
    throw (.data "PSCV0-WF-NOT-RECURSIVE: termination_by was supplied for a nonrecursive declaration")
  let varying := psElabRecursionParameterDependencies context
    (ids.filter fun id => !psElabRecursionParameterIsFixed context ids calls id)
  let dependencies := psExprFVarIds measure
  let measuredVarying := ids.filter fun id => varying.contains id && dependencies.contains id
  -- Constant/same-size candidates still create their genuine impossible
  -- decrease goals, preserving the established DECREASE diagnostic.
  let some majorId := measuredVarying.head? <|>
      (ids.find? varying.contains) <|> (ids.find? dependencies.contains) <|> ids.head?
    | throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires an explicit header parameter")
  let some major := psLocalFindById context.localContext majorId
    | throw (.data "PSCV0-WF-INTERNAL: missing measured parameter binding")
  let majorDependencies := psExprFVarIds
    (psMetaInstantiate context.metaContext (psLocalDeclType major))
  -- A projection-only measure on the second slot need not mention its
  -- dependent domain in Core. Select from actual binder dependencies too,
  -- while leaving a first-only measure on the existing unary/state route.
  let dependentMajor := majorDependencies.any fun id => id != majorId && varying.contains id
  if measuredVarying.length > 1 || dependentMajor then do
    -- The additional route owns exactly two changing header binders in
    -- source order. A constant second family uses the same checked PSigma
    -- encoding; a third changing slot stays outside this bounded route.
    -- Full fixed-capture/type closure is rechecked by the source constructor.
    let [firstId, secondId] := ids.filter varying.contains
      | throw (.data "PSCV0-WF-MEASURE-STATE: pair packing requires exactly two changing parameters")
    let some _ := psLocalFindById context.localContext secondId
      | throw (.data "PSCV0-WF-INTERNAL: missing second packed parameter binding")
    return {
      parameterIds := ids, majorId := firstId, packedIds := some (firstId, secondId)
      fixedIds := ids.filter (fun id => !varying.contains id), stateIds := [] }
  let changing := psElabRecursionParameterDependencies context (varying ++ [majorId])
  let stateIds := ids.filter fun id => id != majorId && changing.contains id
  if stateIds.any dependencies.contains then
    throw (.data "PSCV0-WF-MEASURE-STATE: the measure depends on evolving state")
  return {
    parameterIds := ids
    majorId := majorId
    fixedIds := ids.filter (fun id => !changing.contains id)
    stateIds := stateIds }

def psElabRecursionValidateFixedParameters (context : PsElabContext)
    (plan : PsElabRecursionParameterPlan) (calls : List PsElabRecursionCall) :
    Except PsElabError Unit := do
  for id in plan.fixedIds do
    if !psElabRecursionParameterIsFixed context plan.parameterIds calls id then
      throw (.data "PSCV0-WF-FIXED: a final typed recursive call changes a captured fixed parameter")

structure PsElabRecursionArguments where
  context : PsElabContext
  values : List PsExpr
  abstractions : List PsMetaAbstraction
  resultType : PsExpr

-- A permutation must not reorder or repeat source argument computations.
-- Keep one checked Core let for each original argument, in source order,
-- including fixed arguments; only their bound references are rearranged.
def psElabRecursionCaptureArguments (elaborate : PsElaborator)
    (context : PsElabContext) (arguments : List PsSyntaxTerm) (sourceType : PsExpr) :
    Except PsElabError PsElabRecursionArguments := do
  let mut current := context
  let mut values := []
  let mut abstractions := []
  let mut cursor := sourceType
  for source in arguments do
    let parameter ← (psInferEnsureForall current.environment current.metaContext
      current.localContext cursor).mapError PsElabError.infer
    let .explicit := parameter.binder
      | throw (.data "PSCV0-WF-TELESCOPE: recursive calls require the complete explicit header telescope")
    let argument ← elaborate current source (some parameter.domain)
    let type := psMetaInstantiate argument.context.metaContext parameter.domain
    let name := psNameAppendNum (psRootName "_psc0CallArgument") argument.context.localContext.nextId
    let captured := psLocalPushLet argument.context.localContext name type argument.term
    current := { argument.context with localContext := captured.context }
    values := values ++ [.fvar captured.id]
    abstractions := .letE captured.id name type argument.term :: abstractions
    cursor := psExprInstantiate1 parameter.body (.fvar captured.id)
  return { context := current, values, abstractions, resultType := cursor }
