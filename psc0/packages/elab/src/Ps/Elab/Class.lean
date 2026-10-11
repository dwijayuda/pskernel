import Ps.Elab.Declaration

-- Qualified projections are ordinary closed definitions over Core projections.
-- Class methods change only the dictionary binder to instance-implicit.
def psElabStructureProjections (fuel : Nat) (context : PsElabContext)
    (info : PsInductiveInfo) (bindersRev : List PsElabTypedBinder)
    (major : PsExpr) (index : Nat) (cursor : PsExpr) :
    Except PsElabError (List PsDeclaration) := do
  match fuel with
  | 0 => return []
  | fuel + 1 =>
    let field ← (psInferEnsureForall context.environment context.metaContext
      context.localContext cursor).mapError PsElabError.infer
    let value := PsExpr.proj info.name index major
    let closed := psCloseElabTypedBinders context.metaContext bindersRev value field.domain
    let declaration := PsDeclaration.definitionDecl
      (psNameAppendStr info.name (psNameLastComponent field.name)) info.levelParams
      closed.snd closed.fst
    let rest ← psElabStructureProjections fuel context info bindersRev major (index + 1)
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
  let family := psExprApplyMany (.constE info.name []) arguments
  let binder := if isClass then PsBinderInfo.instanceImplicit else .explicit
  let majorName := psRootName "self"
  let major := psLocalPushBinding parameters.context.localContext majorName family binder
  let context := psElabContextWithLocal parameters.context major.context
  let parametersRev := parameters.bindersRev.map fun entry => { entry with binder := .implicit }
  let bindersRev := PsElabTypedBinder.mk major.id majorName family binder :: parametersRev
  let cursor ← psElabProjectionApplyParameters context arguments constructor.type
  let projections ← psElabStructureProjections constructor.numFields context info bindersRev
    (.fvar major.id) 0 cursor
  return { declarations := batch.declarations ++ projections }

def psElabRegisterClass (environment : PsEnvironment) (name : PsName) :
    Except PsElabError PsEnvironment := do
  let some info := psEnvironmentFindInductive environment name
    | throw (.data "class requires a structure declaration")
  if !info.isStructure then throw (.data "class requires a structure declaration")
  return { environment with classes := name :: environment.classes }

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
    value := .constE name []
    type := psDeclarationType declaration
    priority
    className := some className }
  return { environment with instances := psInstanceIndexAdd environment.instances entry }
