# PSC1 MinKernel R5 guideline and preservation ledger

Status: **R5 scoped compiler-stage batch qualified**, source `f58a1d8f98d1d438a9697371466e07d1416beec4`.
Verified 2026-10-28 07:16:29 UTC. Continuation setting: **GPT-6.1 Sol / High**. All project execution belongs to
**GitHub Actions Linux**. This document supersedes R4's continuation instructions
while retaining R4's immutable source-consistency and runtime-admission evidence.

## Exact scope

R5 establishes compiler-stage results for the actual shared scalar lowering,
application-capture wrapping and parameter-currying functions. Its proof library
imports the existing compiler modules directly and stays outside every executable
kernel and compiler import graph. The selected theorem batch has **21 unique
printed reports: five axiom-free and sixteen using only propext**. The final source run verifies those counts. The retained earlier suite has 204 reports (33 axiom-free, 171 propext only), including R4's 142.

The complete composite compiler-to-JavaScript preservation theorem remains open.
The exact scope and assumptions are in [the R5 profile](PSC1_MIN_KERNEL_R5_PROFILE.md).
R4's byte/source model theorem, R5's local stage theorems, actual emitted execution,
official admission and broader regressions are different evidence classes.

## Actual stages and their guarantees

| Actual function | Result | Boundary |
| --- | --- | --- |
| psErasureWrapApplicationCaptures | Evaluation iff an independent chronological lexical capture history and final body value exist | Scalar IR semantics; no claim that upstream capture names are fresh |
| psErasureCurryParameters | Invocation under an exact matching argument list iff the body evaluates in the sequentially extended lexical environment | Scalar-result bodies and the one-argument curried ABI |
| Both actual functions composed | CapturedInvoke for the actual wrapped curried expression | Does not prove arbitrary closure/call emission or generator execution |
| psEraseMappedIntrinsic and psEraseBinaryIntrinsicApplication | Local selected-operation erasure and scalar semantics when recursive operand erasures/values are supplied | No theorem for whole recursive erasure or source-name dispatch |
| psTsEmitIntrinsicFromPrinted | Exact selected token composition and arity refusal | Existing opaque token join, not character/ECMAScript semantics |
| psTsEmitLiteral | Exact Nat construction and Bool/Unit literal equations | Nat decimal rendering and opaque append remain unproved |

The scalar semantics covers Nat, Bool and Unit, lexical variables, lets,
conditionals, ten binary operations and Bool.not. Unsupported IR has no evaluation
derivation. The ten binary operations are Nat add/sub/mul/div/mod/beq/ble/blt and
Bool.and/or. This scalar compiler sub-stage includes operations beyond R4's
admitted user-language primitive profile; it widens no kernel admission rule.

Captures interpret the actual reverse accumulator tail first. Wrapping success
and reflection cover arbitrary capture lengths and lexical shadowing. Bindings
specify matching parameter/argument lists; the composed capstone evaluates capture
lets before invoking the actual nested curried lambdas.

The binary helper was extracted from the recognizer's existing local body, and
the actual recognizer calls it. The mathematical theorem targets this shared pure
body. The recognizer's string-based branch choice has separate finite native tests.

## Bootstrap-string finding

The pinned [Lean String bootstrap source](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Bootstrap.lean)
declares String.Internal.append, length, get, next and atEnd as opaque externs.
Their executable behavior does not supply kernel reduction laws for characters.
R5's first proof attempt failed when it treated those laws as definitional.

No new axiom or arbitrary string-model assumption repairs that failed claim.
The exact emission statements retain opaque token composition and psNatToString;
they do not prove that the resulting string has the intended character sequence.
The independent capture/currying and scalar-stage results avoid that premise.
Actual emitted strings are checked through TSC and Node separately.

Strict TSC also caught an invalid initial harness context: psTsEmitExpr can return yield* syntax and expects the surrounding generator/module runtime. Structural probes now pass four constructed declarations through psTsEmitCheckedModule and retain their complete module/runtime and exact IR. No generated text substitution or TSC relaxation repairs the error. Selected pure scalar/template expressions remain separate; this is an API-context correction, not a scheduler proof.

The [BigInt specification](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html)
and [logical evaluation rules](https://tc39.es/ecma262/multipage/ecmascript-language-expressions.html#sec-binary-logical-operators-runtime-semantics-evaluation)
give the intended external engine contracts, not imported formal theorems.
Nat subtraction is saturating; zero division/modulus have the selected Nat
behavior; Boolean operators short-circuit in the target. A pure scalar evaluation
model cannot justify arbitrary effectful or divergent operand behavior.

## Linux execution contract

The host driver reads the registered test-only module
Ps.MinKernel.Tests.CompilerScalar. Native Lean executes that same physical source,
and the actual atomic SH/1 API compiles its text. The original IR, structured source
origins, admissions and TypeScript are retained from that one compilation.
The flags providerChecked, strictSh1Qualified and semanticContractQualified remain
false; separate admissions do not overwrite their meanings.

The final Linux observations are:

- 400 actual scalar-emitter results versus native mathematical oracles, including
  zero divisors, saturation, the 2^53 boundary and naturals beyond 2^256.
- 294 calls from the same registered source under native Lean and generated JS,
  covering scalar functions, computed partial applications and lexical closures.
- Three standalone Bool/Unit literal checks, actual capture ordering, composed
  capture/currying, both curry branch results and shadowing.
- Twelve emitted operand traces: eight Nat left/right single evaluations and four
  Boolean short-circuit observations. These traces are finite observations.
- Thirty emitter arity refusals, thirty pure binary-stage arity refusals, thirty
  recognizer arity refusals and ten nominal recognizer checks.
- Four invalid original-IR modules refused by the actual checked-emission entry.
- Independent pinned official admission of the original source-API transport line and its canonical packet, plus generated R4B admission of the exact canonical packet. The original terminal-LF transport form must refuse R4B, without delegation.
- Every earlier R0–R4 guard, source/native/generated corpus and source-sort/resource
  boundary check, plus complete connected checker self-admission and fresh census.

The finite generated ABI uses nonnegative bigint for Nat, primitive boolean
for Bool, and undefined for Unit. Zero-runtime-parameter declarations export values. Known declaration entries use flat runtime parameters; first-class function values follow the curried one-argument ABI.
These typed exports are not hostile-object ingress validators. The existing
R4 Uint8Array factory remains the public untrusted-byte boundary. R5 adds no
unproved promotion or host-side acceptance shortcut.

Strict TSC and Node run only on Actions. The V8 old-space cap remains 256 MiB.
The existing proof/portability limits remain 10/20 minutes; the separate new compiler-preservation job also has a 10-minute ceiling and runs strict TSC plus finite ABI checks first. Its fast receipt explicitly excludes official/R4B admission. Superseded focused runs cancel, and only terminal success at the final stable source qualifies. Source-module ownership
checks remain active. The first fixture's unregistered R5.Scalar module was
correctly refused; the registered test module resolves ownership without bypass.

## Exact packet framing

The source API returns an NDJSON transport line ending in one LF. R4B requires
compact bytes and EOF. The retained original fixture message is 8834 bytes and
must refuse the R4B public API (its host ASCII preflight reports PSC1_MIN_CORE_ASCII_PROFILE). The harness asserts its last byte is LF, removes exactly that
framing byte, preserves every preceding byte, and retains the distinct canonical
packet and hash. Both forms receive independent official checks. Only the
canonical form is required to pass the public R4B entry. This is an explicit
transport adapter in the test harness, not a wider decoder or an identity claim
between different byte strings.

## Retained actual IR

The retained original fixture IR has no external imports, six declarations,
one Prod structure layout and List/Option/Except inductive layouts. Those
foundation layouts are retained metadata, rather than evidence that R5's scalar
semantics covers data representations.

In the actual psR5Capture body, computed arguments become chronological lets
named _psAppArg and _psAppArg$4 before a one-argument lambda c$3 calls psR5Three.
That is a retained finite observation of the real producer. The general theorem
covers the actual wrapping/currying functions, while producer freshness and
recursive source-to-IR composition remain open.

## Actual generated representation ledger

The retained fixture bundle exposes the following representations. This is an
inspection of actual emitted code and finite execution, not a new representation
preservation theorem.

| Source/runtime entity | Actual emitted representation | Qualification boundary |
| --- | --- | --- |
| Nat / Bool / Unit | bigint / boolean / undefined | Selected finite literal/operator tests; Nat inputs are nonnegative bigint |
| Known declaration parameters | Flat runtime arguments | Six source functions tested |
| Function-valued results | Nested one-argument functions backed by __ps$wrap(function*) | Currying/capture observations; scheduler proof open |
| Call continuation | Module-local WeakMap implementations and __ps$run/invoke/tail protocol | Runtime present in the checked structural module; general simulation open |
| Prod | Interface with a private unique-symbol brand and fst/snd fields | Retained metadata; no new record-value proof from this fixture |
| List / Option / Except | Private unique-symbol tag keys with named payload fields | Retained layouts; data representation proof remains open |
| Generic nullary constructors | Actual List.nil()/Option.none() factory functions | Do not treat them as nongeneric constant constructor values |

Tag/brand symbols are allocated within a generated module. Structurally similar
objects from another generated module do not automatically share that identity.
The public R4 host factory receives one trusted actual generated module and
constructs candidates with that module's own constructors/source factories.
Untrusted callers submit bytes, not typed AST objects. A future proof must bind
the actual symbol/name maps, constructor arities, field layout and caller module
identity. It cannot replace these with a presumed universal string-tag ABI.

## Exact connected scopes

R5 adds no minimal-kernel runtime source. The complete public R4B byte-checker
route still has ten connected runtime modules. The separate R5 fixture, native IO
driver, proof libraries, compiler, shared JS runtime and test vectors are distinct
scopes. The final run repeats the actual full runtime packet through the same public byte API: 103181 source bytes, 307 origin members, 206 records and 1804358 packet bytes, SHA-256 041d55f110471b91b69d134a38daeb94ee555a71e797b48a0c00cc6aa66ee516. Both native and generated entries accept it; R4A's 28/36 and R4B's 20/32 corpora and 29 boundary probes remain green.

A compiler origin selects the source census being measured; it never grants
admission. A successful six-declaration fixture cannot stand for the complete
compiler closure. Re-measure the current Ps.CompilerUnified.Service graph and
retain its source/admission hashes and blocker categories. The qualified census has 124 modules, 4743 source Core members, 4748 logical members, 3466 admission records, 2685300 source bytes and 115 prelude declarations. It retains 60 foundational axioms, 34 directly referenced, and five partial-body pairing obligations. Source inventory SHA-256: ba6334e20d685e69f2cf188167712850079bb3a861583d1b239860f6cd44f6d9.

Minimal compiler and Practical Core coverage, and min-qualified G1/G2/G3, remain
unqualified by this stage batch. Production official Lean Wasm remains default,
and min/dual continue to refuse PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. No fallback,
fixture admission whitelist, protected-base update, merge or npm publication.

## Terminal qualification and immutable evidence

All runs below succeed at source `f58a1d8f98d1d438a9697371466e07d1416beec4`:

| Run | Jobs |
| --- | --- |
| [Focused 40557438637](https://github.com/dwijayuda/pskernel/actions/runs/40557438637) | Prior proof/native 122377152332; new preservation/ABI 122377151932; portability/census/public bytes 122378533905 |
| [Main 40557451248](https://github.com/dwijayuda/pskernel/actions/runs/40557451248) | Full Linux 122385846634; gate 122396946024; every selected dependency succeeds; benchmark deliberately unselected |
| [Installed CLI 40557438460](https://github.com/dwijayuda/pskernel/actions/runs/40557438460) | Preflight 122377512189; installed 122377910156 |

The tested merge `85800efb9693944d8e3a32406ac3f8f0b90469eb` has parents
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340` and the qualified source, and shares
source tree `8e7685693165f6e443979052764373e3fbcadea2`. The existing PR #194 remains open and draft.

The installed host-only package preserves 120 payload files. Its unpublished
0.1.0-psc1.9 tarball is 3823974 B, SHA-256
`a94ab7f2a335187abf3bf8df8295e2e11977007c13498d4b99e1da392a566993`.
Frozen application snapshot `8383c6983e5fa2f2d945b02ba4b349ab64522c64`
and compiler closure digest
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`
retain their own boundary. Current-development-compiler promotion is false.

The [dated R5 receipt](PSC1_MIN_KERNEL_R5_QUALIFICATION_2026-10-28.json) records
every selected job conclusion, 225 printed trust reports, exact source/IR/output
hashes, source policy flags, both packet framings, census, resource observations,
artifact identities and failed development attempts. Verified ZIP identities are:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| 12758760032 | 8352 | 9f1d1ce73531d64f275d623892e3d84add86fbedbba9d0e70ffd122606e62d6d |
| 12758251140 | 24558 | f4a9df2261e9c276a30a5218a1498498bfebefaf553e9b33b598f57c7b8162f6 |
| 12756794448 | 1997065 | 9f1a91c1997e045dcba9de26ccbaf7c480dca4fdd7680fc98687f9c048792151 |
| 12757633572 | 46516 | a2196c244d826c471d4ce91daab8a5a89ce4557ecf6a6616b0429171ed1f3ab6 |

The 206729103-byte installed toolchain archive 12760513999 has metadata digest
`a9f55ed1bbb6ac75a0a849cd4e78a2c9139de1f4e0ac4e792552f15bbab267f2`;
its large ZIP was not downloaded. Artifact availability follows GitHub retention
and authentication. No temporary signed download URL is a durable evidence link.

Generated checker self-admission observed about 46.0 s and maxRSS 305180 KiB in
one Linux run. The 29-probe process observed maxRSS 154048 KiB; the R5 ABI/public
byte process observed maxRSS 93904 KiB. These individual measurements include their
documented process scopes. They are not total-memory bounds or speed guarantees.

## Next proof batch

Begin by reading fresh remote HEAD, selected CI and the dated R5 receipt.
Preserve the immutable base 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340 and concurrent
branch history with single-parent, nonforce expected-HEAD updates.

First resolve one actual bootstrap-string composition boundary with a bounded
experiment. Inspect pinned PSC1 prelude and erasure support before substituting
modern Lean String functions: Lean compilation alone does not establish PSC1
source compatibility or canonical admission. The options are a constructive
supported representation/operation with proved laws, or independently validated
target bytes with a complete grammar and semantic refinement proof. Record the
decision and actual connected closure; do not assert opaque extern character laws
or add axioms for convenience.

Then connect actual recursive Core erasure to independent source semantics.
Prove type/proof telescope omission invariants and upstream capture freshness,
and extend the model to function closures, calls and regular values before
claiming higher-order preservation. The current local stage premises remain
explicit until that real recursive caller discharges them.

Record/tag/field and nominal carrier representations require a connection to
actual constructor/projection/match emission. The generator protocol requires a
simulation of continuation-preserving and complete-result tail requests. Finally
bind proved target syntax to exact emitted bytes and state TypeScript/ECMAScript
implementation assumptions. Whole compiler minimal admission remains a different
obligation from preservation of these compiler stages.

For every extension, register exact roots, print fresh unique theorem reports,
preserve no-axiom/propext-only guards, test native and actual generated paths, and
submit the full newly connected runtime. Keep source proofs, engine observations,
official comparisons, resource measurements and whole-pipeline gaps separate.
Wait for terminal source CI before a reporting-only documentation commit, then
verify that commit's selected gates and update the existing draft PR.
