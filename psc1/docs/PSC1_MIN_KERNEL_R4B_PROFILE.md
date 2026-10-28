# PSC1 MinKernel R4B regular canonical ingress

Status: qualified at `e6bcb88e16ee42937d474e48ef5f98f5e12fc57a`.
The [R4 guideline](PSC1_MIN_KERNEL_R4_GUIDELINE.md) is the authoritative continuation
document. All project execution ran on GitHub Actions Linux with the user-confirmed
GPT-6.1 Sol / High continuation setting.

## Qualification

[Run 40519651550](https://github.com/dwijayuda/pskernel/actions/runs/40519651550)
passes proof/native 122242943719 and portability/closure 122242944053.
R4B has 95 unique printed trust reports: six axiom-free, 89 propext-only.
Together with R4A there are 142 reports, 17 axiom-free and 125 propext-only.

The actual native and PSC1-generated public byte APIs agree on 20 accepts and
32 refusals. All positives separately pass the pinned official native checker.
Twelve hostile host inputs refuse, own length/iterator accessors are ignored,
and 29 further source-sort/resource probes pass, including nine universe probes.

The complete connected ten-module runtime passes both native and generated
self-admission through the same byte API: 103181 source bytes, 307 source-origin
members, 206 admission records, 1804358 packet bytes. Packet SHA-256:
`041d55f110471b91b69d134a38daeb94ee555a71e797b48a0c00cc6aa66ee516`.
Source/test graph admission, strict TS compilation and emitted JS execution are
separate evidence steps. Eleven modules include the test vectors; their bundle
is 591107 B TS / 703128 B JS. The exact identities are in the dated receipt.

Terminal broader regressions pass in
[main run 40519663163](https://github.com/dwijayuda/pskernel/actions/runs/40519663163):
full Linux **122252188875**, gate **122269623462**, and every selected dependency
succeed; the benchmark is deliberately unselected. The tested merge
`0010ff8fe52d8423f45f693fd7ce6b6256934e6b` has the exact qualified source tree
`48c15ca4509efd25822045727f6dae78a2e79947`.
[Installed CLI run 40515328367](https://github.com/dwijayuda/pskernel/actions/runs/40515328367)
also passes (installed job **122228057662**) at runtime commit
`68887377c1c6bead518c5aa91832d6b967248859`. A verified comparison shows only
proofs, qualification workflow and separate host tests changed afterward.
These broader runs do not qualify compiler min G1/G2/G3.

## Mechanism

createRegularCoreIngress(generated) accepts an intrinsic snapshot of an
exact-prototype Uint8Array. The host parser proposes typed syntax only.
RegularIngressBytes matches every canonical token, interprets decimal bytes in
base ten and requires EOF. Unknown/duplicate/reordered fields and extra metadata
refuse. The independently proved Wire grammar retains structure and numeric values.

Groups are single-family, Type-0, zero-parameter/index, with direct self or earlier
closed ground fields. Freshness reservations cover definitions, owners,
constructors and generated recursors in one namespace. Ordered plans prove the
computed nominal slot is the actual registry entry. Every original constructor
type is independently translated and compared with its derived ambient signature.

RegularIngressOperational uses a separate PsMinRegCoreTerm. Ordinary atoms retain
actual R3 checking and canonical proved foundation/projection interpretations.
Owned regular recursors keep result codes in the full ambient registry; a result
carrier declared after the selected family must already be visible at the use site. Their
field domains are lifted from the selected family's older prefix. Existing
positive carriers fold into the concrete ambient result type; prefix, field and
branch lemmas justify every cast. R2/R3 source and proofs remain unchanged.

Exact source-domain/universe checks recognize constant motives. Nat/List/Option,
conditional and owned recursor schemas retain their source type arguments.
Projections retain owner/index/major; actual descriptor and type checks enforce
one constructor, a valid field and the matching major type. Closed type grammar
prevents dependency erasure. List/Option elements and level-1 results must be
Type-sorted, preserving the source Prop/Type distinction.

Source image grammars, concrete denotations and SourceHistory interpret original
bodies in their declaration-time name/value contexts. The final byte capstone
composes exact original bytes, source syntax and source-body values.
byte_admission_consistent rules out a direct declaration of the exact canonical
empty proposition. Final models instantiate actual concrete interpretations,
without assuming an arbitrary foundation model.

The first prefix-only attempt passed finite examples but refused the connected
runtime. Explicit lowering repaired psMinRegLiftTy, then
psMinCoreConditionalView exposed a valid later-carrier result outside R2's domain.
The ambient term layer solves that general mechanism. The earlier lowering
comparison remains proof-only, excluded from the runtime closure.

## Bounds and boundary observations

The regular profile limits bytes to 2097152, entries/constructors to 512, expression
depth to 256, name depth including the anonymous root to 16, component text to
128 ASCII bytes, and scalar naturals to 65536 inclusive. Numeric name components
remain below 4096. JSON depth is 768; JSON containers and proposed AST nodes are
each capped at 131072. A prior nine-module packet measured 80054 objects, providing
the sizing evidence for this new profile. R4A limits remain unchanged.

Entry translation uses fuel 512, expression translation 256, inference and
definition checking 512. Conservative exhaustion refuses. Tests accept 512
definitions, depth 256, 512 constructors and 512 empty groups, and reject tested
over-limit variants. A valid 512-group packet needing a ground-type check at the
oldest group refuses when registry fuel exhausts; the official checker accepts it.

V8 old-space stays capped at 256 MiB; proof/portability workflows stay at
10/20 minutes. At this run generated self-admission took about 31.7 s in the call,
maxRSS 301416 KiB. The 29-probe process reported maxRSS 154984 KiB. These observed
values are not total-memory caps, complexity theorems or performance guarantees.

## Trust and next work

The ten modules are RegularProfile, RegularCheck, OperationalProfile,
OperationalCheck, CoreBytes, CoreIngress, RegularIngressProfile,
RegularIngressOperational, RegularIngressCheck and RegularIngressBytes.
They contain no String/Char operation. The old default Check, R1 helpers, test
vectors, native IO/JSON harness, host JS and compiler/shared runtime are separately
identified scopes.

No general Lean conformance or compiler/emitter/JavaScript preservation theorem
is claimed. Production min/dual still refuse PSC1_MIN_CANONICAL_BRIDGE_UNPROVED;
official Lean Wasm remains the default. Compiler min coverage stays 0/124,
Practical Core 0/37, and no min-qualified G1/G2/G3. R5 must address explicit
preservation/integration obligations and broader declared domains before promotion.
