import Ps.KernelCore.API.Provider

/- Construct sessions through psKernelKernelSessionEmpty. Direct construction
   with a low-level environment explicitly belongs to the trusted integration
   boundary; this record is not a proof that arbitrary constants were admitted.
   Capability configuration belongs here, outside semantic declaration history. -/
structure PsKernelKernelSession where
  environment : PsKernelEnvironment
  resources : PsKernelResourcePolicy
  provider : PsKernelProviderCapability

def psKernelKernelSessionEmpty
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability) : Except PsKernelError PsKernelKernelSession :=
  if psKernelProviderCompatible provider then
    Except.ok
      (PsKernelKernelSession.mk psKernelEnvironmentEmpty resources provider)
  else
    Except.error (PsKernelError.declinedUnsupported "provider target does not match KernelContract-v1")

structure PsKernelAdmissionResult where
  session : PsKernelKernelSession
  declaration : PsKernelCheckedDeclaration

def psKernelKernelSessionPreflight
    (session : PsKernelKernelSession) : Except PsKernelError Unit :=
  if psKernelProviderCompatible session.provider then
    match psKernelResourcePreflight session.resources with
    | Option.none => Except.ok ()
    | Option.some resource =>
        Except.error (PsKernelError.resourceExhausted resource "resource policy declined operation before entry")
  else
    Except.error (PsKernelError.declinedUnsupported "provider target does not match KernelContract-v1")

def psKernelKernelSessionEnvironment
    (session : PsKernelKernelSession) : PsKernelEnvironment :=
  psKernelEnvironmentWithNativeEvaluator session.environment session.provider.nativeEvaluator

def psKernelKernelSessionChecker
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety) : PsKernelCheckerSession :=
  psKernelMkCheckerSession
    (psKernelKernelSessionEnvironment session) levelParams safety
    session.resources.maxRecDepth session.resources.maxNatSize
