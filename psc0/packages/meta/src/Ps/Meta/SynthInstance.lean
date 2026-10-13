import Ps.Meta.Synthetic

-- Each invocation owns its graph; callers receive diagnostics, never a cache
-- that could accidentally outlive the local context or instance registry.
def psSynthInstanceWithTable (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (fuel : Nat) (target : PsExpr) :
    PsInstanceTabledResult :=
  psSynthInstanceWithLimits environment localContext index context fuel {} target

def psSynthInstanceWithFuelWorker (fuel : Nat) (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (target : PsExpr) : PsSynthInstanceResult :=
  (psSynthInstanceWithTable environment localContext index context fuel target).result

def psSynthInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (fuel : Nat)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuelWorker fuel environment localContext index context target

def psSynthInstance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuel environment localContext index context 64 target
