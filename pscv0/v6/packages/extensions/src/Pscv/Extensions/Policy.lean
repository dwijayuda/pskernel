import Pscv.Core.Model

/-!
Third-party npm extensions are never admitted as trusted code merely because
an artifact exists or an extension manifest names a capability. P0 only checks
immutable descriptors; no extension executable is loaded by this module.
-/
namespace Pscv.Extensions

inductive ExtensionClass where
  | library | syntax | proofProducer | optimizer | backend
  | semanticElaborator | foundation
  deriving Repr, BEq, Inhabited

inductive ExecutionClass where
  | dataOnly | wasmComponent | isolatedProcess | trustedInProcess
  deriving Repr, BEq, Inhabited

structure Descriptor where
  name : String
  className : ExtensionClass
  execution : ExecutionClass
  apiIdentity : String
  deriving Repr

def validate (profile : Pscv.Profile) (descriptor : Descriptor) : Except String Descriptor := do
  if descriptor.name.isEmpty || descriptor.apiIdentity != "pscv-extension/1" then
    throw "PSCV_EXTENSION_IDENTITY_INVALID"
  if descriptor.execution == .trustedInProcess then
    throw "PSCV_EXTENSION_INPROCESS_DENIED"
  match descriptor.className with
  | .foundation | .semanticElaborator =>
      throw "PSCV_EXTENSION_SEMANTIC_AUTHORITY_DENIED"
  | .syntax =>
      if profile != .leanExtensible then
        throw "PSCV_EXTENSION_CLOSED_SOURCE_PROFILE"
      if descriptor.execution == .dataOnly then
        throw "PSCV_EXTENSION_EXECUTION_HOST_NOT_CONFIGURED"
  | .library =>
      if descriptor.execution != .dataOnly then
        throw "PSCV_LIBRARY_EXECUTION_DENIED"
  | .proofProducer | .optimizer | .backend =>
      if descriptor.execution == .dataOnly then
        throw "PSCV_EXTENSION_EXECUTION_HOST_NOT_CONFIGURED"
  return descriptor

end Pscv.Extensions
