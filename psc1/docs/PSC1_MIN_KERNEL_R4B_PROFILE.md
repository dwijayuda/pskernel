# R4B regular canonical ingress — in progress

This is the experimental continuation of qualified R4A at a90054c94b283c45e67afff91196ac474b92e49b.
R4 is not complete. All proof checks, compilation, execution, measurements and tests
run on GitHub Actions Linux using the user-confirmed GPT-6.1 Sol / High continuation.
Production min/dual continue to refuse PSC1_MIN_CANONICAL_BRIDGE_UNPROVED; official
Lean Wasm remains the default.

## Source and byte domain

The bytes-only createRegularCoreIngress(generated) factory is separate from R4A.
It accepts safe, closed definitions and single-family, zero-parameter/index,
Type-0 regular groups. Fields are direct self references or closed ground types
from earlier groups. Nested/negative self occurrences and dependent types refuse.
The validator retains exact structured names, metadata, original declaration
order, constructor types, source recursor motives and projection owners.

An untrusted JSON parser only proposes typed syntax. The source-owned streaming
verifier matches every canonical token and interprets decimal bytes in base ten.
Unknown/duplicate/reordered fields and trailing input refuse. The separately proved
token grammar gives canonical structure and numeric-value derivations, without
taking parser output or an executable byte-equality test as semantic authority.

The initial B limits are 2 MiB input, 512 entries/constructors, expression depth
256, name depth 16 and 128 ASCII bytes per component. Scalar values are at most
65536; names retain the stricter R4A component rules. JSON depth is 768; aggregate
JSON containers and proposed AST nodes are each bounded by 131072. The earlier
nine-module packet alone measured 80054 objects, so 65536 was inadequate for this
new domain. R4A's 65536-byte/4096-node limits remain unchanged. Execution retains
the 256 MiB V8 old-space cap and existing 10/20-minute workflow timeouts.

## Ambient regular recursion

The nine-module trial passed 52 native/generated cases with independently accepted
positive source packets, but refused whole-runtime admission. Diagnostics first
found an ambient/result-prefix mismatch in psMinRegLiftTy. Explicit lowering fixed
that narrower case. It then exposed psMinCoreConditionalView, whose syntax match
returns a later-declared record. That valid Type-0 result is outside R2's prefix
recursor domain; lowering cannot represent it.

RegularIngressOperational therefore defines a separate PsMinRegCoreTerm.
Ordinary atoms preserve actual R3 checking and semantics. Its explicit regular
recursor retains the result code in the complete ambient registry. Field domains
are lifted from the selected family's older prefix; its self domain is the actual
ambient slot. Motives must be closed constant Type-sorted motives, with exact
source domain and universe instances. Minor signatures come from the checked
regular descriptor.

The model folds the existing positive carrier into the concrete ambient result
type. Prefix-lift, field, branch and recursor-denotation lemmas justify every cast.
The operational model constructs evaluation witnesses and histories of actual
checked bodies; its final consistency theorem supplies actual R3 and ambient
models, without an arbitrary foundation-model premise. Existing R2/R3 runtime
and proof modules remain unchanged.

## Remaining qualification

The ambient model and operational consistency lemmas have passed Linux axiom
checks (no axioms or propext only). Connecting the byte translator, complete
source-body semantics, exact nominal/constructor/recursor/projection correspondence,
and native/generated whole-runtime admission is still in progress. The source
compiler/emitter and JavaScript wrapper remain explicit trust boundaries; finite
execution comparisons do not prove compiler preservation.

The legacy prefix-lowering helper is retained in the proof file as a comparison
with the earlier R2 domain; it is excluded from the new runtime closure. It is
not a special rule for a fixture, name or hash. The ten-module runtime closure
will be selected from same-compile origins and submitted to the same public byte
entry as arbitrary supported callers.

No full compiler minimal-checker coverage is claimed: 0/124 modules, 0/37 Practical
Core, and no min-qualified G1/G2/G3. Full R4 reporting awaits terminal evidence.
