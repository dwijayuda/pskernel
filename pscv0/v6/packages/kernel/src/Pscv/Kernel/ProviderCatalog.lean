import Pscv.Core.Model

/-!
Version-pinned catalog of copied Lean 4.34 kernel npm packages.
Metadata here is not a checked capability. Full V6 has Lean 4.35 semantics.
The small CLI imports no Lean.Environment and never certifies from a catalog.
-/
namespace Pscv.Kernel

inductive ProviderTransport where
  | native | wasm
  deriving Repr, BEq, Inhabited

structure ProviderDescriptor where
  transport : ProviderTransport
  npmPackage : String
  protocol : String
  kernelProfile : String
  leanVersion : String
  leanCommit : String
  deriving Repr, BEq

def providerDescriptor : ProviderTransport → ProviderDescriptor
  | .native => {
      transport := .native
      npmPackage := "@proofscript/pskernel-lean"
      protocol := "pskernel-lean/1"
      kernelProfile := "lean4.34-core"
      leanVersion := "4.34.0"
      leanCommit := "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
    }
  | .wasm => {
      transport := .wasm
      npmPackage := "@proofscript/pskernel-lean-wasm"
      protocol := "pskernel-lean/1"
      kernelProfile := "lean4.34-core"
      leanVersion := "4.34.0"
      leanCommit := "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
    }

def availableProviders : Array ProviderDescriptor :=
  #[providerDescriptor .native, providerDescriptor .wasm]

/-- Exact *kernel profile identity* comparison only; not certification. -/
def providerSupportsKernelProfile (profileId : String) : Bool :=
  profileId == "lean4.34-core"

end Pscv.Kernel
