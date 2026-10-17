import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Synthetic
import Ps.Syntax.Ast
import Ps.Elab.Info

structure PsElabStructuralRecursion where
  functionName : PsName
  parameterIds : List Nat
  explicitParameterIds : List Nat
  recursiveParameterIndex : Nat
  calls : List (Prod Nat Nat)
  resultType : PsExpr
  collectCalls : Bool
  indices : List (Nat × Nat) := []
  refined : Bool := false

-- Well-founded calls use a proof-restricted local function. Matching may
-- generalize that dependent local, so resolution follows its hygienic name,
-- never a stale pre-refinement local ID.
structure PsElabWellFoundedRecursion where
  functionName : PsName
  callbackName : PsName
  parameterIds : List Nat := []
  majorId : Nat := 0
  packedIds : List Nat := []
  stateIds : List Nat := []
  fixedIds : List Nat := []
  collectCalls : Bool := false
  sourceType : Option PsExpr := none

-- Typed call observations retain their actual branch scope. Invariant
-- analysis must compare these arguments, not the spelling of source names.
structure PsElabRecursionCall where
  localContext : PsLocalContext
  arguments : List PsExpr
  span : PsSourceSpan

def psElabStructuralRecursionFindCall
    (calls : List (Prod Nat Nat))
    (fieldId : Nat) : Option Nat :=
  match calls with
  | [] =>
      Option.none
  | entry :: rest =>
      if Nat.beq (Prod.fst entry) fieldId then
        Option.some (Prod.snd entry)
      else
        psElabStructuralRecursionFindCall rest fieldId

-- Saved lexical authority has no metavariable snapshot: a resumed job uses
-- current checked assignments with its original names, instances and locals.
structure PsElabSavedScope where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  structuralRecursion : Option PsElabStructuralRecursion
  levelNames : List PsName
  sourceSpan : Option PsSourceSpan := none
  wellFoundedRecursion : Option PsElabWellFoundedRecursion := none

inductive PsElabPendingWork where
  | core (scope : PsElabSavedScope) (constraint : PsSyntheticConstraint)
  | expectedTerm (scope : PsElabSavedScope) (id : Nat) (value type : PsExpr)
  | sourceTerm (scope : PsElabSavedScope) (id : Nat) (source : PsSyntaxTerm)

structure PsElabContext where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  metaContext : PsMetaContext
  structuralRecursion : Option PsElabStructuralRecursion
  levelNames : List PsName := []
  pending : List PsElabPendingWork := []
  postponing : Bool := false
  sourceSpan : Option PsSourceSpan := none
  collectInfo : Bool := true
  infoRev : List PsElabInfoEntry := []
  wellFoundedRecursion : Option PsElabWellFoundedRecursion := none
  -- Like infoRev, this is an event stream, not saved lexical authority.
  -- Each metavariable owns its original complete branch context.
  wellFoundedGoalsRev : List (Nat × PsSourceSpan) := []
  wellFoundedCallsRev : List PsElabRecursionCall := []

def psElabContextEmpty (environment : PsEnvironment) (levelNames : List PsName := []) : PsElabContext :=
  {
    environment := environment
    localContext := psLocalEmpty
    instances := environment.instances
    metaContext := psMetaEmpty
    structuralRecursion := Option.none
    levelNames := levelNames
  }

def psElabContextWithLocal (context : PsElabContext)
    (localContext : PsLocalContext) : PsElabContext :=
  { context with localContext }

def psElabContextWithMeta (context : PsElabContext)
    (metaContext : PsMetaContext) : PsElabContext :=
  { context with metaContext }

def psElabContextWithStructuralRecursion (context : PsElabContext)
    (structuralRecursion : Option PsElabStructuralRecursion) : PsElabContext :=
  { context with structuralRecursion }

def psElabSaveScope (context : PsElabContext) : PsElabSavedScope :=
  { environment := context.environment, localContext := context.localContext,
    instances := context.instances, structuralRecursion := context.structuralRecursion,
    levelNames := context.levelNames, sourceSpan := context.sourceSpan
    wellFoundedRecursion := context.wellFoundedRecursion }

def psElabRestoreScope (context : PsElabContext) (scope : PsElabSavedScope) : PsElabContext :=
  { context with
    environment := scope.environment
    localContext := { scope.localContext with
      nextId := max scope.localContext.nextId context.localContext.nextId }
    instances := scope.instances
    structuralRecursion := scope.structuralRecursion
    wellFoundedRecursion := scope.wellFoundedRecursion
    levelNames := scope.levelNames, sourceSpan := scope.sourceSpan }

-- Root fields keep their established call map in every nested body. Only the
-- whole declaration match may create that map; a nested fold has another IH.
def psElabContextAfterStructuralFields (context : PsElabContext) : PsElabContext :=
  match context.structuralRecursion with
  | Option.none => context
  | Option.some recursion =>
      psElabContextWithStructuralRecursion context
        (some { recursion with collectCalls := false })

-- Restore lexical visibility, retain solved constraints, and never recycle a
-- local identity still mentioned by the shared metavariable context.
def psElabLeaveScope (outer inner : PsElabContext) : PsElabContext :=
  { outer with
    localContext := {
      nextId := max outer.localContext.nextId inner.localContext.nextId
      declarations := outer.localContext.declarations }
    metaContext := inner.metaContext
    pending := inner.pending
    infoRev := inner.infoRev
    wellFoundedGoalsRev := inner.wellFoundedGoalsRev
    wellFoundedCallsRev := inner.wellFoundedCallsRev }

def psElabContextWithEnvironment (context : PsElabContext)
    (environment : PsEnvironment) : PsElabContext :=
  { context with environment }

-- Immutable context ownership gives failed speculation automatic rollback.
-- Saved lexical scopes intentionally exclude the event stream and assignments.
def psElabRecordInfo (context : PsElabContext) (info : PsElabInfo) : PsElabContext :=
  if context.collectInfo then
    { context with infoRev := { localContext := context.localContext, info } :: context.infoRev }
  else context

def psElabFinishSourceInfo (context : PsElabContext) (owner : PsName) : PsElabSourceInfo :=
  { owner, metaContext := context.metaContext, entries := context.infoRev.reverse }

