import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Elab.SourceTrace

structure PsElabStructuralRecursion where
  functionName : PsName
  parameterIds : List Nat
  explicitParameterIds : List Nat
  recursiveParameterIndex : Nat
  calls : List (Prod Nat Nat)
  resultType : PsExpr
  collectCalls : Bool

def psElabStructuralRecursionFindCall
    (calls : List (Prod Nat Nat))
    (fieldId : Nat) : Option Nat :=
  match calls with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if Nat.beq (Prod.fst entry) fieldId then
        Option.some (Prod.snd entry)
      else
        psElabStructuralRecursionFindCall rest fieldId

structure PsElabContext where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  metaContext : PsMetaContext
  structuralRecursion : Option PsElabStructuralRecursion
  whileHelper : Option PsName
  currentNamespace : PsName
  sourceTrace : PsElabSourceTrace

def psElabContextEmpty (environment : PsEnvironment) : PsElabContext :=
  {
    environment := environment
    localContext := psLocalEmpty
    instances := psInstanceIndexEmpty
    metaContext := psMetaEmpty
    structuralRecursion := Option.none
    whileHelper := Option.none
    currentNamespace := PsName.anonymous
    sourceTrace := psElabSourceTraceEmpty false
  }

def psElabContextWithLocal
    (context : PsElabContext)
    (localContext : PsLocalContext) : PsElabContext :=
  {
    environment := context.environment
    localContext := localContext
    instances := context.instances
    metaContext := context.metaContext
    structuralRecursion := context.structuralRecursion
    whileHelper := context.whileHelper
    currentNamespace := context.currentNamespace
    sourceTrace := psElabSourceTraceWithLocals context.sourceTrace localContext
  }

def psElabContextWithMeta
    (context : PsElabContext)
    (metaContext : PsMetaContext) : PsElabContext :=
  {
    environment := context.environment
    localContext := context.localContext
    instances := context.instances
    metaContext := metaContext
    structuralRecursion := context.structuralRecursion
    whileHelper := context.whileHelper
    currentNamespace := context.currentNamespace
    sourceTrace := context.sourceTrace
  }

def psElabContextWithStructuralRecursion
    (context : PsElabContext)
    (structuralRecursion : Option PsElabStructuralRecursion) :
    PsElabContext :=
  {
    environment := context.environment
    localContext := context.localContext
    instances := context.instances
    metaContext := context.metaContext
    structuralRecursion := structuralRecursion
    whileHelper := context.whileHelper
    currentNamespace := context.currentNamespace
    sourceTrace := context.sourceTrace
  }

-- Root fields keep their established call map in every nested body. Only the
-- whole declaration match may create that map; a nested fold has another IH.
def psElabContextAfterStructuralFields (context : PsElabContext) : PsElabContext :=
  match context.structuralRecursion with
  | Option.none => context
  | Option.some recursion =>
      psElabContextWithStructuralRecursion context
        (Option.some (PsElabStructuralRecursion.mk
          recursion.functionName recursion.parameterIds recursion.explicitParameterIds
          recursion.recursiveParameterIndex recursion.calls recursion.resultType false))

-- Only an explicitly partial source declaration supplies this capability.
def psElabContextWithWhileHelper
    (context : PsElabContext) (helper : PsName) : PsElabContext :=
  PsElabContext.mk context.environment context.localContext context.instances
    context.metaContext context.structuralRecursion (Option.some helper) context.currentNamespace context.sourceTrace

def psElabContextForDeclaration
    (environment : PsEnvironment) (name : PsName) : PsElabContext :=
  let currentNamespace : PsName :=
    match name with
    | PsName.anonymous => PsName.anonymous
    | PsName.str parent _ => parent
    | PsName.num parent _ => parent;
  let context : PsElabContext := psElabContextEmpty environment;
  PsElabContext.mk context.environment context.localContext context.instances
    context.metaContext context.structuralRecursion context.whileHelper currentNamespace context.sourceTrace

-- Tracing is explicitly host/developer selected, never source selected.
def psElabContextWithSourceTrace (context : PsElabContext) (enabled : Bool) : PsElabContext :=
  PsElabContext.mk context.environment context.localContext context.instances
    context.metaContext context.structuralRecursion context.whileHelper context.currentNamespace
    (psElabSourceTraceWithLocals (psElabSourceTraceEmpty enabled) context.localContext)

def psElabContextSourceBinder (context : PsElabContext)
    (localId : Nat) (span : PsSourceSpan) : PsElabContext :=
  if context.sourceTrace.enabled then
    PsElabContext.mk context.environment context.localContext context.instances
      context.metaContext context.structuralRecursion context.whileHelper context.currentNamespace
      (psElabSourceTraceAtBinder context.sourceTrace localId span)
  else context

def psElabContextSourceReference (context : PsElabContext)
    (name : PsName) (span : PsSourceSpan) (baseSegments : Nat)
    (target : PsElabSourceTarget) : PsElabContext :=
  if context.sourceTrace.enabled then
    PsElabContext.mk context.environment context.localContext context.instances
      context.metaContext context.structuralRecursion context.whileHelper context.currentNamespace
      (psElabSourceTraceReference context.sourceTrace name span baseSegments target)
  else context

def psElabContextRestoreScope (outer inner : PsElabContext) : PsElabContext :=
  PsElabContext.mk outer.environment outer.localContext outer.instances
    inner.metaContext outer.structuralRecursion outer.whileHelper outer.currentNamespace
    (psElabSourceTraceRestore outer.sourceTrace inner.sourceTrace)

-- Some existing special forms resolve structural arguments directly rather than
-- through term elaboration. Refuse editing until every source edge is recorded.
def psElabContextSourceIncomplete (context : PsElabContext) : PsElabContext :=
  if context.sourceTrace.enabled then
    let trace := context.sourceTrace;
    PsElabContext.mk context.environment context.localContext context.instances
      context.metaContext context.structuralRecursion context.whileHelper context.currentNamespace
      (PsElabSourceTrace.mk true trace.nextId trace.bindersRev trace.referencesRev trace.active false)
  else context
