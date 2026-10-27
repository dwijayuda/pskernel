# PSC1 MinKernel R4 canonical ingress

Status: implementation and proof qualification in progress. This first R4 domain
is `psc1-min-core-simple/1`. The complete R4 regular-data/recursor/projection
bridge and runtime self-admission remain open. Production min/dual still refuse
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
closed simple arrows, and monomorphic List/Option of another closed type.
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

Generic Nat/List/Option recursors, user regular groups and projections are not
translated by this first domain. Their normalized R2/R3 models remain qualified;
raw recognition and generated-member binding are the next R4 obligation.

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

These new semantic/rendering capstones are still undergoing Linux qualification.
No incomplete development run qualifies them. Printed axiom guards remain
restricted to no axioms or exactly propext; sorryAx, Classical.choice and Quot.sound
are not admitted by the qualification workflow.

## Execution and limits

The corrected runtime passed standalone Linux at
`e0c4cadde836645492a4f0b1c273a3c5468c2b71`:
28 accepted cases, 36 refusals, 14 hostile-host cases. All 28 accepted packets also
passed the official native checker. Native canonical bytes and actual PSC1-generated
JS outcomes agree. Later proof changes retain that tested runtime identity.

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

## Connected source view and remaining R4 work

The actual connected explicit runtime comprises RegularProfile, RegularCheck,
OperationalProfile, OperationalCheck, CoreBytes and CoreIngress: six modules,
50191 UTF-8 bytes before any further R4 expansion. Same-compile source origins
identify 172 runtime members and 102 admission records. The seven-module test
graph includes the separate 53724-byte vector source.

The runtime syntactic foundation reaches 26 declarations. The interpreted source
language additionally requires Unit, Unit.unit and Nat.sub; its selected contracts
and the runtime references have a 29-declaration union. These are selected source
contracts, not ambient theorem axioms or a complete compiler foundation.

No String/Char operation occurs in the six explicit runtime sources. The actual
generated bundle still includes shared runtime/harness code. The census is
diagnostic and does not establish self-admission. The old Check-only 12 records,
R2's 37 records and R3's 56 records are preserved as different source scopes.

Remaining R4: regular-group byte grammar and declaration-order/freshness validation;
exact generated constructor/recursor identities and projection ownership; all
required source recursor motives and instances; full connected runtime admission
through this route; complete foundation adequacy at that scope. Keep the public
production modes gated until their declared domain is complete and qualified.
Full compiler min coverage remains 0/124 modules and 0/37 Practical Core, with no
qualified min-checked G1/G2/G3. Do not relabel official-checker evidence.
