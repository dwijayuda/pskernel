namespace PsKernelCoreProvider

inductive PsKernelCoreProviderErrorKind where
  | protocolVersion
  | malformedRequest
  | unsupportedCoreForm
  | preludeMismatch
  | providerVersionMismatch
  | kernelRejection
  | resourceExhausted
  | providerInternalError
  deriving Repr, BEq

def PsKernelCoreProviderErrorKind.code : PsKernelCoreProviderErrorKind -> String
  | .protocolVersion => "protocol-version"
  | .malformedRequest => "malformed-request"
  | .unsupportedCoreForm => "unsupported-core-form"
  | .preludeMismatch => "prelude-mismatch"
  | .providerVersionMismatch => "provider-version-mismatch"
  | .resourceExhausted => "resource-exhausted"
  | .kernelRejection => "kernel-rejection"
  | .providerInternalError => "provider-internal-error"

structure PsKernelCoreProviderError where
  kind : PsKernelCoreProviderErrorKind
  message : String
  declarationIndex : Option Nat := none
  deriving Repr

end PsKernelCoreProvider
