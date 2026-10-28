# PSC1 MinKernel R6 continuation guideline

Status: **source-qualified scoped R6 batch**, source `457c542f5f03f6b3f96245b76ad09190cfd4f879`.
Read the [R6 profile](PSC1_MIN_KERNEL_R6_PROFILE.md), [completed plan](PSC1_MIN_KERNEL_R6_PROFILE_PLAN.md)
and [dated receipt](PSC1_MIN_KERNEL_R6_QUALIFICATION_2026-10-28.json).
Execution setting: GPT-6.1 Sol / High. All project proofs, builds, compiler runs,
tests and measurements belong on GitHub Actions Linux.

## Completion contract and R5 reconciliation

R6 is complete only when all items have concrete evidence:
1. Linux decision gate establishes the supported constructive append byte law and native/generated compatibility before migration.
2. The actual two-call psTsJoin implementation uses constructive append; a general theorem covers arbitrary separator and fragment lists.
3. Exact byte equations connect the ten selected R5 binary templates to actual emission, with explicit add/and/sub grammar corollaries.
4. Native and actual generated modules pass byte comparisons (324 append pairs through both names, 50 joins and 30 selected-emitter cases), with exact source/IR/output identities and independent official admission.
5. R0–R5 trust guards pass unchanged; all new unique theorem reports obey no-axiom/propext-only policy. Connected R4 runtime self-admission and hostile/resource corpora pass; String fixture remains refused without delegation.
6. Fresh whole-compiler census, selected ordinary Linux and installed CLI workflows reach terminal success at the final source tree.
7. R5 status is reconciled; R6 profile, guideline and dated evidence receipt are committed, their selected reporting gates pass, and draft PR #194 describes the final scope.
The scoped batch can be complete while the explicitly listed whole-compiler, runtime-engine, primitive-foundation and minimal-admission obligations remain open.

R5 is complete as its declared scoped compiler-stage batch. Fresh remote checks
on 2026-10-28 confirm source f58a1d8f98d1d438a9697371466e07d1416beec4 has successful
focused 40557438637, main 40557451248 and installed 40557438460 workflows.
Reporting commit 8d156294cb4632f50abd09d19a9d1e701194cbde has successful selected
reporting workflow 40649323666. Its 21 theorem reports, ABI observations and
packet identities remain historical evidence at that source. R5 did not promise
complete recursive erasure or whole-compiler preservation. Those open obligations
remain explicit; R6 does not relabel them as proved.

Read the R6 profile/receipt, then the R5 guideline/receipt for the inherited
capture/currying/scalar semantics and R4 documents for byte admission consistency.

## Decision: constructive append, exact UTF-8 bytes

The actual psTsJoin had two calls to opaque String.Internal.append. The pinned
Lean String.Bootstrap extern declarations supply no theorem for the character or
byte behavior of that opaque operation. R6 does not invent one.

At Lean 4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
- String.append has a constructive logical definition: its toByteArray is the
  concatenation of the two input byte arrays, with a UTF-8 validity proof.
- ByteArray.append's logical representation concatenates its underlying lists.
- List.intercalate supplies an independent mathematical separator specification.
- String.append still has a native extern implementation. The logical definition
  is the theorem target; compiled native and JavaScript executions remain
  implementation observations, not a verified engine theorem.

Primary sources:
[String definition](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Defs.lean#L93),
[byte-array definition](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/ByteArray/Bootstrap.lean#L26),
[list specification](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/List/Basic.lean),
[opaque bootstrap boundary](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Bootstrap.lean).

PSC1's existing builtin catalogue identifies both names; its prelude already
registers modern String.append and its real eraser maps both names to stringAppend.
This support was inspected before substitution. See the exact source's
[builtin catalogue](https://github.com/dwijayuda/pskernel/blob/457c542f5f03f6b3f96245b76ad09190cfd4f879/psc1/packages/core/src/Ps/Core/Builtin.lean),
[prelude](https://github.com/dwijayuda/pskernel/blob/457c542f5f03f6b3f96245b76ad09190cfd4f879/psc1/packages/environment/src/Ps/Environment/Prelude.lean)
and [actual eraser](https://github.com/dwijayuda/pskernel/blob/457c542f5f03f6b3f96245b76ad09190cfd4f879/psc1/packages/erasure/src/Ps/Erasure/Expr.lean). It is distinct from proving all
PSC1 primitive foundation laws or admitting String into the minimal kernel.

The first Linux decision experiment left production psTsJoin unchanged. Its two
fresh theorem reports passed (append_utf8 propext-only; empty_utf8 axiom-free).
The native/source-generated paths passed 324 append pairs through both names and
50 actual joins. Independent official checks and unchanged public-min refusal
are required before the migration is qualified. Development attempts exposed host-harness namespace/reserved-keyword mistakes
and an unsupportedTerm refusal in the test wrapper source. The latter is distinct
from the imported emitter module. Portable wrapper sources use separate typed
binders and fully qualified constructor terms/patterns; native Lean acceptance
alone does not establish PSC1 source compatibility. Failed attempts supplied no
whole-bundle qualification. The dated receipt preserves their exact boundaries.

## Exact implementation and proof scope

Only the two append calls in Ps.BackendTs.Type.psTsJoin change to String.append.
There is no kernel-profile or foundational declaration change. Proof-only
TextComposition/TextCompositionTrust and test-only StringBridge/EmitterBridge are explicit
lakefile roots, excluded from connected checker roots. CompilerPreservation's
historical template comment is updated to identify its R6 byte refinement.

Define utf8(text) = text.toByteArray.data.toList, a List UInt8.
The general join theorem states:

    utf8 (psTsJoin separator values)
      = List.intercalate (utf8 separator) (values.map utf8)

It quantifies over arbitrary Lean strings and arbitrary finite fragment lists;
it is not a corpus-count claim. Empty separator composes flattened byte lists;
pair and concatenated-list corollaries expose separator placement and empty cases.
R5's exact binary-template equation then supplies a witness for the actual
psTsEmitIntrinsicFromPrinted result whose bytes flatten the independently stated
fragments, for all ten selected Nat/Bool binary operations. Add, Bool.and and
Nat.sub have explicit grammar-fragment byte corollaries.

These equations accept arbitrary operand fragments and therefore do not assert
that those fragments are syntactically valid TypeScript expressions. They do not
prove escaping, precedence in other contexts, psNatToString rendering, arbitrary
literal emission, TypeScript erasure or ECMAScript evaluation. R5's scalar model
and finite engine checks retain their own premises and boundary.

The ten fresh R6 trust reports are:

| Declaration in Ps.MinKernel.TextComposition | Result |
| --- | --- |
| append_utf8 | propext-only; constructive append bytes |
| empty_utf8 | axiom-free; exact empty bytes |
| join_utf8 | propext-only; arbitrary separator and list |
| join_empty_utf8 | propext-only; flatten with empty separator |
| join_pair_utf8 | propext-only; exact pair separator placement |
| join_concat_empty_utf8 | propext-only; composition across fragment-list concatenation |
| emit_binary_utf8 | propext-only; actual selected ten-operation output witness |
| emit_add_bytes | propext-only; explicit addition fragments |
| emit_and_bytes | propext-only; explicit conjunction fragments |
| emit_sub_bytes | propext-only; explicit saturating-subtraction fragments |

The retained suite has 204 unique reports (33 axiom-free, 171 propext-only);
R5 contributes 21 (5/16). Combined with R6 this is 235 unique reports (39/196).
This count is an audit of printed declaration dependencies, not a measure of
whole-compiler soundness. One repeated older build-log report is deduplicated;
the fresh R6 trust log contains exactly one report for each of its ten names.

## Runtime compatibility and Unicode boundary

The Linux host harness uses an independent chronological List Nat byte fold:
it never calls psTsJoin or String.append to compute expected bytes. It exercises
18 strings including ASCII/UTF-8 boundaries, combining sequences, NUL, newline,
quotes/backslash, supplementary scalars, empty strings and a 4096-character case.
There are 324 append pairs, 50 joins (including 64 empty and 256 nonempty
fragments), and 30 byte-template probes for actual add/and/sub emission.

The generated actual join is compiled from the exact six-module
Ps.BackendTs.Type source closure. Its Lists use the same generated module's
constructors. The standalone two-definition StringBridge tests append. Separate EmitterBridge
wrappers import the actual emitter; their eight-module connected closure is
recorded separately. Three source bundles are compiled and independently checked. Both test modules
are roots in the main compiler workspace. Only the standalone, import-free
StringBridge is a root in the isolated minimal-kernel package; importing the
emitter there would create an unnecessary compiler dependency. No structural values are exchanged between
modules with different private symbols or generator runtimes.

The Type closure's checked IR, strict TypeScript and generated JavaScript must
remain byte-identical to the pre-migration decision experiment. This hash
comparison is a bounded compiler-output regression, never an admission whitelist.
All source policy and IR traversal flags are checked; providerChecked,
semanticContractQualified and strictSh1Qualified remain false.

Lean String values are valid UTF-8. JavaScript permits raw unpaired UTF-16
surrogates. Concatenating a high half and low half before UTF-8 encoding differs
from encoding each half separately. Three retained JavaScript-only counterexample
checks document this excluded domain (modern append, legacy append, actual join).
No general correspondence for arbitrary externally supplied JavaScript strings,
surrogate normalization or all primitive string operations follows.

## Admissions, closure and execution fences

Retain source API transport bytes and canonical EOF bytes separately. The
canonical adapter removes exactly one final NDJSON LF and changes no other byte.
Independently check each exact source packet with the pinned official checker.
Require the standalone, ASCII-framed StringBridge packet to remain refused by
public R4B with PSC1_MIN_CORE_REFUSED and delegated=false. Record the expanded
emitter bundle's refusal separately: it may be PSC1_MIN_CORE_ASCII_PROFILE before
Core rules are reached. That earlier wire-profile refusal does not substitute
for the standalone Core witness. An official comparison is not minimal admission.

Repeat the complete connected R4 checker through its same public generated byte
API; include source/runtime/test/shared-generator scopes separately. Re-run all
hostile, universe and resource probes. No explicit String operation is injected
into the connected checker source; proof-only string imports grant it no new rule.

Re-measure the entire current Ps.CompilerUnified.Service graph and foundation.
Record source/IR/admission inventory identities, imports, partial-body pairing
obligations and unsupported categories. Origins choose a census scope and grant
no admission. Source-byte reduction or byte-identical Type output does not imply
a minimally admitted compiler closure.

Preserve all R0–R5 report guards, no-axiom/propext-only policy, 10/10/20 minute
focused budgets and 256 MiB V8 old-space setting. Print each new theorem's
dependencies exactly once in its fresh trust log. No sorryAx, choice, quotient,
new axiom, force-push, protected-base write, merge or npm publication.

Production official Lean Wasm stays default. Min/dual keep refusing
PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. Full compiler admission, Practical Core
coverage, minimal G1/G2/G3, self-hosting and release readiness remain open.

## Qualified packet and closure observations

| Bundle | Canonical bytes | SHA-256 | Official | Public R4B |
| --- | ---: | --- | --- | --- |
| Actual Type closure | 734561 | `a3dee278dd1a2276a57ce27e68f99b7112008219b44b6da73036980b5599123a` | accepted | not used as a min-qualification claim |
| Standalone append fixture | 1979 | `7357bf1f25a06777a42410177b852bb24eda4fbf1d59b9547ad365e05bbfa122` | accepted | PSC1_MIN_CORE_REFUSED; delegated=false |
| Actual emitter fixture closure | 1307184 | `dba0d7c26269879a2c6a78045f02ba1baede4d09a3aaef961eb2517cc54d1e00` | accepted | PSC1_MIN_CORE_ASCII_PROFILE; delegated=false |

Each source transport packet has exactly one final LF beyond the canonical
packet. The standalone fixture packet is byte-identical to the decision
experiment; its Core refusal is not replaced by the emitter's earlier ASCII
profile refusal.

The retained connected checker is still ten source modules, 103181 source bytes,
307 origin members, 206 records and 1804358 packet bytes, SHA-256
`041d55f110471b91b69d134a38daeb94ee555a71e797b48a0c00cc6aa66ee516`. Native and generated public entries accept it without delegation.
The source/test/shared-runtime graph has eleven modules; its generated TypeScript
is 591107 B and JavaScript 703128 B, with the unchanged file hashes in the receipt.
R4A 28 accepts/36 refusals/14 hostile cases, R4B 20/32/12, and 29 boundary probes
(including nine universe probes) remain checked.

The current compiler census has 124 modules, 4743 source Core members,
4748 logical members, 3466 records, 2685282 source bytes,
326 import edges and 115 prelude declarations. Its inventory SHA-256 is
`2e2e1a9f0bd6bf4f1daf31995273162a5532dcd13a87f51c2cb9dd8fffe65f2e`. There are 60 foundation axioms and 35 direct references
(34 before the modern append call), with no new foundational declaration.
All five exact partial-body pairing obligations remain. Blocker counts retain
7167 projections, 8737 literals, 12991 quantified types and 308 inductive groups.
Minimal compiler coverage is 0/124 and Practical Core 0/37; no min G1/G2/G3.

R5's retained current-source checks still pass 400 scalar comparisons, 294
same-physical-source calls, three literal probes, four checked structural IR
declarations, twelve trace probes and the unchanged arity/recognizer/refusal cases.
Their finite ABI/engine boundary and false semantic/strict-Sh1 qualification flags
are unchanged.

Generated checker self-admission observed 44.85 seconds and maxRSS 309520 KiB in
this one Linux process. The boundary-probe process observed maxRSS 155312 KiB;
the full R6 parent Node process observed 91544 KiB. These scope-specific process
observations do not bound child-process memory, total RSS, asymptotic complexity
or future run time. The 256 MiB V8 old-space limit remains unchanged.

## Terminal evidence and next batch

All selected source workflows below are terminal-success at
`457c542f5f03f6b3f96245b76ad09190cfd4f879`, tree `05f8eb4fec5f4da449c1ed312cf3cb5de46f613a`:

| Workflow | Jobs |
| --- | --- |
| [Focused 40656742989](https://github.com/dwijayuda/pskernel/actions/runs/40656742989) | Prior proof/native 122709639769; R5/R6 proof/ABI 122709639395; portability/census/public bytes 122710259222 |
| [Main 40656748193](https://github.com/dwijayuda/pskernel/actions/runs/40656748193) | Full Linux 122714658290; final gate 122726326428; every selected dependency succeeds; benchmark deliberately unselected |
| [Installed CLI 40656742940](https://github.com/dwijayuda/pskernel/actions/runs/40656742940) | Preflight 122709535920; installed 122709912699 |

The tested merge `5a4beaf8e695baf1e53c4cafc791179f6df6473f` has parents
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340` and the qualified source, with the identical source tree.
The existing PR 194 remains open, draft and unmerged.

The installed host candidate preserves 120 compiler/kernel/provider payload files.
Its unpublished 0.1.0-psc1.9 tarball is 3823978 B, SHA-256
`59ec2ee0dc59b8a71e7fd3c91d0b43239feaaa694d632b75769b8e28a5795bc6`. This is the current tarball identity, distinct from
the older R5 archive. Frozen application snapshot
`8383c6983e5fa2f2d945b02ba4b349ab64522c64` and closure digest
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9` keep their separate scope;
current-development-compiler promotion is false.

The [dated R6 receipt](PSC1_MIN_KERNEL_R6_QUALIFICATION_2026-10-28.json) records all
selected job conclusions, unique trust reports, code/source/IR/output identities,
transport/canonical packets, retained R4/R5 checks, current census, resource
observations and failed/superseded attempts. Read-only ZIP verification found:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| 12802365223 | 8328 | be4574855ef3c726273586fe7ee53fe20f870c9d3ec38025e168b5c134953dc1 |
| 12801409377 | 226359 | 35c597110216283bff7287e41859bf0f2ce06934a801d20459b55c8fc343c50e |
| 12801244624 | 24561 | 6da24ba2c26ab6e220490ed42d3957e006ca8eae9f59915531dc450b580ad838 |
| 12802630901 | 2286619 | c58e08728213f502193e79ba136fe2515052dc3d8d669d664a942b93754082b3 |
| 12801094901 | 46709 | 0defd3836adba4694599258cd1bddbfa90904e9abd8e966fc9ea83b372561aec |

The 206728065-byte installed toolchain archive
12804477142 has metadata digest
`f4c59c2c8883f547294576ebf03e8a5c1ac77b9a3558b2548977dc945824c901`; the large ZIP was not downloaded.
Artifact access follows GitHub authentication and retention; temporary signed
download URLs are not durable evidence links.

Source qualification is immutable at the source commit above. The reporting
commit changes documentation only; verify its selected static/final gates
separately. Its own SHA is not embedded in this source receipt, avoiding a
self-referential document identity.


For the next batch, first refresh remote HEAD and CI, read this receipt and use a
single-parent nonforce expected-HEAD update. Keep the protected base
94e0c13f6a4b434f73c859cc0c716cb6fb8d1340 immutable.

The next semantic priority is the actual recursive erasure caller: discharge the
R5 local-stage premises with independent source semantics, explicit type/proof
telescope omission invariants and name/capture freshness. Select a bounded
recursive source fragment and state its excluded cases before coding. Extend
closures/calls/regular carriers and generator continuation/tail simulation only
with actual implementation connections. Another append-law substitution alone
does not complete these obligations. Keep byte composition, primitive/ABI
assumptions, finite engine observations and whole-pipeline preservation separate.

Concrete caller map from the current Ps.Erasure.Expr source:
- psEraseRuntimeExprWithFuelWorker is the fuel-indexed recursive entry. Its
  smaller function clears currentDefinition via psErasureNestedRuntimeScope;
  preservation must account for that scope transition.
- psEraseApplicationArgumentsWorker advances the actual forall telescope with
  psExprInstantiate1 in all type/proof/runtime branches. Only runtime branches
  add runtime arguments and their pre-substitution domains. Prove this ordered
  filtering/substitution invariant before treating omission as semantics-free.
- psEraseGeneralApplication immediately instantiates applied erased lambda
  binders; other applications go through checked head types, canonical arguments
  or resolved known entries. These routes need separate explicit hypotheses.
- psErasureCaptureTypedApplicationValue checks local-name reuse and reserves
  generated names in byOutput; connect its successful-state freshness to R5's
  capture model before claiming source-level noncapture.

These are inspected implementation targets for the next plan, not R6 theorems.

## Linux Actions continuation commands

The existing focused workflow performs these commands in the main psc1 workspace
after installing the pinned tools; keep its prior R0–R5 steps intact:

```bash
set -euo pipefail
mkdir -p dist/pskernel-min/text-preservation
lake build PsMinCompilerPreservation PsMinTextPreservation PsHost PsMinStringBridgeFixture
lake env lean proofs/pskernel-min/TextCompositionTrust.lean 2>&1 | tee dist/pskernel-min/text-preservation/proof.log
node scripts/minkernel-text-preservation-guard.mjs
node --max-old-space-size=256 scripts/minkernel-text-preservation.mjs --abi-only
```

The complete text script must also run without --abi-only after the existing
portability job has built the pinned independent checker and generated R4B runtime.
Its dependencies are produced by that workflow; the fast command alone does not
qualify exact packets or the retained connected closure. Do not execute these
project commands locally.

The focused workflow has explicit push path filters. A future backend-only edit
that does not match those filters still requires a workflow_dispatch run at its
exact branch head (or an intentionally reviewed filter update). Generic main CI
success is not a substitute for these proof and full-packet checks. Fresh selected
CI must qualify every changed dependency before its reporting documentation.
