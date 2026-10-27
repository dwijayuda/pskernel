# PSC1 MinKernel R4 canonical ingress

Status: R4A and R4B qualified. See the [current R4 guideline](PSC1_MIN_KERNEL_R4_GUIDELINE.md)
and [R4B profile](PSC1_MIN_KERNEL_R4B_PROFILE.md). This first R4 domain
is `psc1-min-core-simple/1`. The separate R4B regular-data/ambient-recursion/projection bridge and connected
runtime self-admission are now qualified at e6bcb88e16ee42937d474e48ef5f98f5e12fc57a. Production min/dual still refuse
with PSC1_MIN_CANONICAL_BRIDGE_UNPROVED; official Lean Wasm remains the default.
Requested continuation: GPT-6.1 Sol / High. All builds, proofs, compiler execution,
tests and measurements run exclusively on GitHub Actions Linux.

## Exact byte entry

The research-only host factory is `createCoreIngress(generated)` in
`packages/pskernel-min/host/ingress.mjs`. The trusted host supplies the actual
generated module. Untrusted callers supply only an exact-prototype Uint8Array.
The function snapshots its bytes using intrinsic length/buffer access and numeric
indices. It rejects AST objects, arrays, Buffer, DataView, subclasses, proxies
and shared backing buffers before reading caller getters.

JSON.parse proposes a candidate; it has no checking authority. A source-owned
constructor builds the typed candidate. CoreBytes validates the bounded candidate,
re-encodes every field and compares the complete original byte snapshot with the
encoding. CoreIngress translates that exact candidate and calls the actual
OperationalCheck admission function. There is no provider fallback.

The accepted spelling is compact canonical JSON v2 in the repository encoder's
field order, without a final newline. ASCII name components are 32–126 excluding
quote and backslash; escapes and Unicode are outside this initial profile.
Unknown/duplicate fields, altered field order, trailing input, exponents,
leading-zero decimal strings, extra metadata and parser coercions fail exact
re-encoding. Structured name components are retained: a literal component A.B
differs from nested A/B, and numeric components differ from string digits.

## Initial source grammar

Only safe, universe-closed constant definitions with regular-height metadata and
an empty level-parameter list are supported. Height is retained but grants no
conversion authority. Arbitrary user axioms, theorems, opaque/partial declarations,
inductive admissions and generated members are currently refused.

Types are the exact foundation names _psc1OrderFalse, Unit, Nat and Bool,
closed simple arrows, and monomorphic List/Option of another closed Type-sorted type.
`psMinCoreIsType` tracks the source sort through arrow codomains: False and
arrows ending in False are propositions, and cannot inhabit List/Option or the
level-1 conditional result. Source universes are checked before type-code erasure.
The source type grammar excludes bound variables everywhere, so a Pi never
silently erases dependency. List, Option and their constructors have zero universe
arguments in the pinned PSC1 prelude. Eq Bool and ite use level 1.

Terms include scoped variables, exact earlier named constants, literals,
annotated lambdas/applications/lets, Unit/Bool/Nat values, Nat successor,
addition/subtraction/equality/less-than, and explicitly typed List/Option
constructors. Names are resolved newest-first; duplicate, anonymous and reserved
foundation-root declarations refuse. The body sees only the earlier global name
context; a let value sees the original local context.

The only proof/decision macro is the complete source ite spine with Eq.{1} Bool
left right and Bool.decEq left right. Both operands are compared structurally,
including nested syntax, binder names, levels and annotations. Wrong propositions,
reversed operands, arbitrary decisions and altered universes refuse.

Generic recursors, user groups and projections remain outside this first API.
The separate R4B byte API qualifies their supported raw recognition, nominal
binding and source models; it does not widen R4A.

## Formal components

CoreIngress proves byte/name/expression equality soundness, exact byte and
candidate binding, newest-first name identity, freshness and declaration-order
correspondence. CoreTranslation defines an independent type/term image grammar
and proves actual translation success belongs to it. Its conditional equation
identifies the entire retained proposition/decision spine.

CoreSemantics defines independent concrete CoreEval rules. Evaluation witnesses
are built constructively from actual OperationalCheck inference equations.
The declaration fold constructs a SourceHistory whose values interpret each
actual source body in its definition-time name/value context. This avoids
reinterpretation of relative constants in a later environment.

CoreEncoding defines a separate JSON wire grammar through mathematical byte
concatenation, ASCII text, canonical decimal digit lists and decimal place values.
The numeric proof retains the exact natural value. Decoder success must produce
a complete grammar derivation for the original bytes. The final capstones compose
that derivation, source translation and a source-body model, with a no-declaration
corollary for the exact canonical _psc1OrderFalse type.

All 47 new printed theorem reports passed standalone Linux at
`a90054c94b283c45e67afff91196ac474b92e49b`: 11 are axiom-free and 36 use only
propext. This qualifies the closed-definition source and wire capstones for R4A. Printed axiom guards remain
restricted to no axioms or exactly propext; sorryAx, Classical.choice and Quot.sound
are not admitted by the qualification workflow.

## Execution and limits

The corrected runtime and complete R4A proofs passed standalone Linux
[40502224984](https://github.com/dwijayuda/pskernel/actions/runs/40502224984) at
`a90054c94b283c45e67afff91196ac474b92e49b`:
28 accepted cases, 36 refusals, 14 hostile-host cases. All 28 accepted packets also
passed the official native checker. Native canonical bytes and actual PSC1-generated
JS outcomes agree. Six separate source-universe probes include List/Option of
propositions and conditional result sorts. A valid level-0 proposition conditional
is deliberately refused as outside this domain. Earlier green finite runs did not
cover this boundary; the a900 source-sort guard closes that discovered defect.

The full repository run [40502238308](https://github.com/dwijayuda/pskernel/actions/runs/40502238308)
and installed CLI run [40502224679](https://github.com/dwijayuda/pskernel/actions/runs/40502224679)
both completed successfully at the same source commit. The dated
[R4 receipt](PSC1_MIN_KERNEL_R4_QUALIFICATION_2026-10-27.json) records exact evidence.

The first boundary run additionally exercises maximum/over-limit numbers,
height, name text, structured-name depth, declaration count and byte input, and
verifies own length/iterator getters are ignored. The host qualification process
uses a 256 MiB V8 old-space cap; this is not a total RSS bound or a general
compiler/runtime preservation theorem.

Explicit input bounds: 65536 bytes, 128 declarations, 4096 AST nodes, 112 JSON
container depth, 4096 JSON containers, expression depth 48, name depth 16 including
the anonymous root, 128 bytes per name component, and scalar naturals below 4096.
Translation fuel is 64 and operational inference fuel 128. Exhaustion refuses.

The standalone proof/native and portability workflows retain their existing
10/20-minute limits. The source proof, generated execution, finite official
comparison and runtime resource observations remain separate evidence classes.

## Connected source view and later R4B qualification

The actual connected explicit runtime comprises RegularProfile, RegularCheck,
OperationalProfile, OperationalCheck, CoreBytes and CoreIngress: six modules,
50672 UTF-8 bytes at the initial a900 checkpoint. With explicit sort/projection
syntax branches needed by R4B, the same six-module scope is 51787 B at e6bcb88. Same-compile source origins
identify 175 runtime members and 103 admission records at e6bcb88 (173 members
at the initial a900 checkpoint). The seven-module test
graph includes the separate 53714-byte vector source.

The runtime syntactic foundation reaches 26 declarations. The interpreted source
language additionally requires Unit, Unit.unit and Nat.sub; its selected contracts
and the runtime references have a 29-declaration union. These are selected source
contracts, not ambient theorem axioms or a complete compiler foundation.

No String/Char operation occurs in the six explicit runtime sources. The actual
generated bundle still includes shared runtime/harness code. The census is
diagnostic and does not establish self-admission. The old Check-only 12 records,
R2's 37 records and R3's 56 records are preserved as different source scopes.

R4B now qualifies the separate regular-group wire grammar, ordered/fresh nominal
bindings, actual source models and native/generated connected-runtime admission.
The complete connected R4B route is ten modules / 206 records, distinct from this
six-module / 103-record simple-profile census. See the current guideline and dated
receipt. Production promotion and compiler preservation remain open beyond R4.
Compiler minimal-checker coverage remains 0/124 modules and 0/37 Practical Core,
with no min-qualified G1/G2/G3. Official-checker evidence retains its own label.
