import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context

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

def psElabContextEmpty (environment : PsEnvironment) : PsElabContext :=
  {
    environment := environment
    localContext := psLocalEmpty
    instances := psInstanceIndexEmpty
    metaContext := psMetaEmpty
    structuralRecursion := Option.none
    whileHelper := Option.none
    currentNamespace := PsName.anonymous
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
    context.metaContext context.structuralRecursion (Option.some helper) context.currentNamespace

def psElabContextForDeclaration
    (environment : PsEnvironment) (name : PsName) : PsElabContext :=
  let currentNamespace : PsName :=
    match name with
    | PsName.anonymous => PsName.anonymous
    | PsName.str parent _ => parent
    | PsName.num parent _ => parent;
  let context : PsElabContext := psElabContextEmpty environment;
  PsElabContext.mk context.environment context.localContext context.instances
    context.metaContext context.structuralRecursion context.whileHelper currentNamespace
