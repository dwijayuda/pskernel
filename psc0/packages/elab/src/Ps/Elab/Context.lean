import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context

structure PsElabStructuralRecursion where
  functionName : PsName
  explicitParameterIds : List Nat
  recursiveParameterIndex : Nat
  calls : List (Prod Nat Nat)
  resultType : PsExpr
  collectCalls : Bool

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

structure PsElabContext where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  metaContext : PsMetaContext
  structuralRecursion : Option PsElabStructuralRecursion

def psElabContextEmpty (environment : PsEnvironment) : PsElabContext :=
  {
    environment := environment
    localContext := psLocalEmpty
    instances := psInstanceIndexEmpty
    metaContext := psMetaEmpty
    structuralRecursion := Option.none
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
  }
