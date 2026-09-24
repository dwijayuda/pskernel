import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context

structure PsElabContext where
  environment : PsEnvironment
  localContext : PsLocalContext
  instances : PsInstanceIndex
  metaContext : PsMetaContext

def psElabContextEmpty (environment : PsEnvironment) : PsElabContext :=
  {
    environment := environment
    localContext := psLocalEmpty
    instances := psInstanceIndexEmpty
    metaContext := psMetaEmpty
  }

def psElabContextWithLocal
    (context : PsElabContext)
    (localContext : PsLocalContext) : PsElabContext :=
  {
    environment := context.environment
    localContext := localContext
    instances := context.instances
    metaContext := context.metaContext
  }

def psElabContextWithMeta
    (context : PsElabContext)
    (metaContext : PsMetaContext) : PsElabContext :=
  {
    environment := context.environment
    localContext := context.localContext
    instances := context.instances
    metaContext := metaContext
  }
