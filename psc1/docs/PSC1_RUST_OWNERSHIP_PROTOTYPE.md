# Isolated Rust ownership correction

Base: ea10eff9b3de063941c6029bb6c821f9cc10cc3f (PR #172 source lineage).
The main branch's all-seven qualification continues unchanged while this
prototype is checked on fix/psc1-rust-owned-string-moves-20261023. No merge or publication is authorized.

Exact G1 in run 39880803794 passes all ten frozen cases. G2 request SHA256
cd614f55803117ab2a696bcb8e12e9f4940ee1d0f5fcb70a1a1b28d208806aeb times out.
Diagnostic 39882471895 at c380c7e899fe7d156443c73b43208ab0ecb6936e samples
the identical executable/request after 12 and 60 seconds. Both stacks are in
String::clone/memcpy in psJsonStringToChars, before frontend elaboration.
Neither diagnostic response is adopted or admitted.

The correction moves unchanged, initialized, unshadowed String parameters
back into direct tail-loop state after evaluating every changing argument.
Captured aliases retain their old path. Exact monomorphic forwarding wrappers
around eager String intrinsics may use the existing borrowed intrinsic path:
ordered parameter forwarding only, no local callable shadow or type arguments.
Ordinary expression results are already owned; fresh rvalues no longer receive
an additional Clone. Ordinary operand emission, fuel/errors and all strict
IR/admission/unsupported-ABI checks remain.

Tests retain the prior expression/tail emitters, compare actual old/current
generated Rust, cover shadowing, computed arguments, reserved identifiers,
wrong arity and fuel refusal, and retain the fixed 60000-byte/100000-step
Unicode workload. Actual G1/G2/G3 remains separately required with the same
240000 ms child, 32 MiB stream and 15-minute job limits. This prototype is
unqualified until Linux evidence says otherwise.
