import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Synthetic
import Ps.Syntax.Ast

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

inductive PsElabPendingWork where
  | core (scope : PsElabSavedScope) (constraint : PsSyntheticConstraint)
  | sourceTerm (scope : PsElabSavedScope) (id : Nat) (source : PsSyntaxTerm)
      (defaulting : Bool)

structure PsElabContext where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  metaContext : PsMetaContext
  structuralRecursion : Option PsElabStructuralRecursion
  levelNames : List PsName := []
  pending : List PsElabPendingWork := []
  postponing : Bool := false

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
    levelNames := context.levelNames }

def psElabRestoreScope (context : PsElabContext) (scope : PsElabSavedScope) : PsElabContext :=
  { context with environment := scope.environment,
    localContext := { scope.localContext with
      nextId := max scope.localContext.nextId context.localContext.nextId },
    instances := scope.instances, structuralRecursion := scope.structuralRecursion,
    levelNames := scope.levelNames }

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
    pending := inner.pending }

def psElabContextWithEnvironment (context : PsElabContext)
    (environment : PsEnvironment) : PsElabContext :=
  { context with environment }
