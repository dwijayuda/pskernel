import Lean
import PsKernelLean.Error

namespace PsKernelLean

def providerProtocol : String := "pskernel-lean/1"
def providerName : String := "lean4-cpp"
def providerVersion : String := "4.34.0"
def providerProfile : String := "lean4.34-core"

def providerMetadataJson (status : String) : String :=
  String.append
    "{\"protocol\":\"pskernel-lean/1\",\"provider\":\"lean4-cpp\",\"leanVersion\":\"4.34.0\",\"profile\":\"lean4.34-core\",\"status\":\""
    (String.append status "\"}")

def providerNotReadyJson : String :=
  "{\"protocol\":\"pskernel-lean/1\",\"accepted\":false,\"provider\":\"lean4-cpp\",\"leanVersion\":\"4.34.0\",\"profile\":\"lean4.34-core\",\"errorKind\":\"provider-internal-error\",\"message\":\"kernel admission not initialized\"}"

end PsKernelLean
