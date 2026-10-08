namespace PsKernelLean

inductive PsKernelLeanErrorKind where
  | protocolVersion
  | malformedRequest
  | unsupportedCoreForm
  | preludeMismatch
  | providerVersionMismatch
  | kernelRejection
  | providerInternalError
  deriving Repr, BEq

def PsKernelLeanErrorKind.code : PsKernelLeanErrorKind -> String
  | .protocolVersion => "protocol-version"
  | .malformedRequest => "malformed-request"
  | .unsupportedCoreForm => "unsupported-core-form"
  | .preludeMismatch => "prelude-mismatch"
  | .providerVersionMismatch => "provider-version-mismatch"
  | .kernelRejection => "kernel-rejection"
  | .providerInternalError => "provider-internal-error"

structure PsKernelLeanError where
  kind : PsKernelLeanErrorKind
  message : String
  declarationIndex : Option Nat := none
  deriving Repr

end PsKernelLean
