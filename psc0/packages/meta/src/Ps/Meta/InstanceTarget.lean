import Ps.Meta.Infer

structure PsInstanceTarget where
  context : PsMetaContext
  type : PsExpr
  -- Non-semantic search key: outputs are placeholders, including output levels.
  key : PsExpr

def psInstanceTargetArguments (fuel : Nat) (environment : PsEnvironment)
    (locals : PsLocalContext) (outputs : List Nat) (position : Nat)
    (context : PsMetaContext) (type target key : PsExpr) (arguments : List PsExpr)
    (requireReady : Bool := true) :
    Option PsInstanceTarget := do
  match fuel, arguments with
  | _, [] =>
    let key := psMetaInstantiate context key
    if requireReady && psExprHasUnresolvedMeta key then none
    else some { context, type := target, key }
  | 0, _ => none
  | fuel + 1, argument :: arguments =>
    let .forallE _ domain body _ := psWhnfWithTransparency .instances environment context locals type | none
    let (context, value, keyValue) :=
      if outputs.contains position then
        let fresh := psMetaFresh context locals domain .natural
        (fresh.context, fresh.expr, PsExpr.bvar position)
      else (context, argument, argument)
    psInstanceTargetArguments fuel environment locals outputs (position + 1) context
      (psExprInstantiate1 body value) (.app target value) (.app key keyValue) arguments requireReady

-- Output arguments and output-only universes are fresh during search, even
-- when the caller supplied them. Reconciliation happens after a solution is
-- selected, so output preferences cannot silently select a lower-priority instance.
def psPrepareInstanceTarget (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) (requireReady : Bool := true) :
    Option PsInstanceTarget := do
  let target := psMetaInstantiate context target
  let view := psInferAppView (psWhnfWithTransparency .instances environment context locals target)
  let .constE name levels := view.head | none
  let some declaration := psEnvironmentFind environment name | none
  let parameters := ((environment.classParameters.find? fun entry =>
    psNameEq entry.fst name).map (·.snd)).getD {}
  let (context, levelsRev, keysRev) := levels.zipIdx.foldl
    (fun (state : PsMetaContext × List PsLevel × List PsLevel) (level, position) =>
      if parameters.outputLevels.contains position then
        let fresh := psMetaFreshLevel state.1
        (fresh.context, fresh.level :: state.2.1, PsLevel.zero :: state.2.2)
      else (state.1, level :: state.2.1, level :: state.2.2)) (context, [], [])
  let levels := levelsRev.reverse
  let type := psExprInstantiateLevelParams (psDeclarationLevelParams declaration) levels
    (psDeclarationType declaration)
  psInstanceTargetArguments 4096 environment locals parameters.outputs 0 context type
    (.constE name levels) (.constE name keysRev.reverse) view.args requireReady
