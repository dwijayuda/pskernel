import Ps.Elab.Declaration

-- Qualified projections are ordinary closed definitions over Core projections.
-- Class methods change only the dictionary binder to instance-implicit.
def psElabStructureProjections (fuel : Nat) (context : PsElabContext) (proofFamily : Bool)
    (info : PsInductiveInfo) (bindersRev : List PsElabTypedBinder)
    (major : PsExpr) (index : Nat) (cursor : PsExpr) :
    Except PsElabError (List PsDeclaration) := do
  match fuel with
  | 0 => return []
  | fuel + 1 =>
    let field ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    if proofFamily then
      let fieldLevel ← psElabExpressionSort context field.domain
      if !psLevelEquivalent fieldLevel .zero then
        throw (.data "Prop structure fields must be propositions")
    let value := PsExpr.proj info.name index major
    let closed := psCloseElabTypedBinders context.metaContext bindersRev value field.domain
    let declaration := PsDeclaration.definitionDecl
      (psNameAppendStr info.name (psNameLastComponent field.name)) info.levelParams
      closed.snd closed.fst
    let rest ← psElabStructureProjections fuel context proofFamily info bindersRev major (index + 1)
      (psExprInstantiate1 field.body value)
    return declaration :: rest

def psElabAddStructureProjections (environment : PsEnvironment) (isClass : Bool)
    (batch : PsElabDeclarationBatchResult) :
    Except PsElabError PsElabDeclarationBatchResult := do
  let some (.inductiveDecl info) := batch.declarations.head? | return batch
  if !info.isStructure then return batch
  let environment ← psAddDeclarationList environment batch.declarations
  let some ctorName := info.constructors.head? | throw (.data "structure constructor missing")
  let some constructor := psEnvironmentFindConstructor environment ctorName
    | throw (.data "structure constructor missing")
  let parameters ← psElabOpenCoreTelescope 4096 (psElabContextEmpty environment)
    info.type (some info.numParams)
  let arguments := psElabBinderArguments parameters.bindersRev
  let family := psExprApplyMany (.constE info.name (info.levelParams.map PsLevel.param)) arguments
  let binder := if isClass then PsBinderInfo.instanceImplicit else .explicit
  let majorName := psRootName "self"
  let major := psLocalPushBinding parameters.context.localContext majorName family binder
  let context := psElabContextWithLocal parameters.context major.context
  let parametersRev := parameters.bindersRev.map fun entry => { entry with binder := .implicit }
  let bindersRev := PsElabTypedBinder.mk major.id majorName family binder :: parametersRev
  let cursor ← psElabProjectionApplyParameters context arguments constructor.type
  let proofFamily ← (psInductiveIsProp environment info).mapError PsElabError.infer
  let projections ← psElabStructureProjections constructor.numFields context proofFamily info bindersRev
    (.fvar major.id) 0 cursor
  return { declarations := batch.declarations ++ projections }

structure PsClassParameterState where
  inputs : PsLocalContext := psLocalEmpty
  inputLevels : List PsName := []
  outputs : List Nat := []
  position : Nat := 0

-- Check the entire class telescope once at registration. An ordinary input
-- cannot depend on an output; dependent instance binders are outputs as in RC4.
def psElabClassParameters (environment : PsEnvironment) (info : PsInductiveInfo) :
    Except PsElabError PsClassParameters := do
  let telescope ← psElabOpenCoreTelescope 4096 (psElabContextEmpty environment) info.type none
  let state ← telescope.bindersRev.reverse.foldlM (fun (state : PsClassParameterState) binder => do
    let marked := match binder.type with
      | .app (.constE name _) _ => psNameEq name (psRootName "outParam")
      | _ => false
    let dependent := !psExprFVarsInContext state.inputs binder.type
    let output := marked || (dependent && psBinderInfoIsInstance binder.binder)
    if dependent && !output then
      throw (.data "class input parameter depends on an output parameter")
    if output then
      return { state with outputs := state.outputs ++ [state.position], position := state.position + 1 }
    else
      let inputs := { state.inputs with
        declarations := .binding binder.id binder.name binder.type binder.binder :: state.inputs.declarations
        nextId := max state.inputs.nextId (binder.id + 1) }
      return {
        inputs
        inputLevels := state.inputLevels ++ (psElabExprLevels binder.type).flatMap psElabLevelParams
        outputs := state.outputs
        position := state.position + 1 }) {}
  let outputLevels := info.levelParams.zipIdx |>.filterMap fun (name, index) =>
    if state.inputLevels.any (psNameEq name) then none else some index
  return { outputs := state.outputs, outputLevels }

def psElabRegisterClass (environment : PsEnvironment) (name : PsName) :
    Except PsElabError PsEnvironment := do
  let some info := psEnvironmentFindInductive environment name
    | throw (.data "class requires a structure declaration")
  if !info.isStructure then throw (.data "class requires a structure declaration")
  let parameters ← psElabClassParameters environment info
  return { environment with
    classes := name :: environment.classes
    classParameters := (name, parameters) :: environment.classParameters }

def psElabRegisterInstance (environment : PsEnvironment) (name : PsName) (priority : Nat) :
    Except PsElabError PsEnvironment := do
  let some declaration := psEnvironmentFind environment name
    | throw (.data "instance declaration missing")
  let telescope ← psElabOpenCoreTelescope 4096 (psElabContextEmpty environment)
    (psDeclarationType declaration) none
  let head := (psExprAppView (psWhnf environment telescope.context.metaContext
    telescope.context.localContext telescope.body)).head
  let .constE className _ := head | throw (.data "instance result must be a registered class")
  if !environment.classes.any (psNameEq className) then
    throw (.data "instance result must be a registered class")
  let entry : PsInstanceEntry := {
    value := .constE name ((psDeclarationLevelParams declaration).map PsLevel.param)
    levelParams := psDeclarationLevelParams declaration
    type := psDeclarationType declaration
    priority
    className := some className }
  return { environment with instances := psInstanceIndexAdd environment.instances entry }
