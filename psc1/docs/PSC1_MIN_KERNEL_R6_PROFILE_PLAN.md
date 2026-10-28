# PSC1 MinKernel R6: constructive text composition

Status: completed plan; final source `457c542f5f03f6b3f96245b76ad09190cfd4f879` is qualified.
Read the [result profile](PSC1_MIN_KERNEL_R6_PROFILE.md), [current guideline](PSC1_MIN_KERNEL_R6_GUIDELINE.md)
and [dated receipt](PSC1_MIN_KERNEL_R6_QUALIFICATION_2026-10-28.json). Base: R5 reporting head `8d156294cb4632f50abd09d19a9d1e701194cbde`.
Protected base `94e0c13f6a4b434f73c859cc0c716cb6fb8d1340` remains immutable.
Follow [R5 guideline](PSC1_MIN_KERNEL_R5_GUIDELINE.md).

## Selected boundary and decision gate

The actual TypeScript emitter joins fragments with `psTsJoin`, whose two
append calls currently use opaque `String.Internal.append`. Pinned Lean
4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`) exposes constructive
`String.append` through UTF-8 ByteArray concatenation; the logical ByteArray
append is list append. PSC1 already declares both append names in its prelude
and erases both to the same string-append intrinsic.

First run an Actions Linux experiment without changing `psTsJoin`:
print dependencies for the exact constructive UTF-8 equation; compare native
modern/legacy append and actual generated append/join on Unicode, combining,
control, empty and long inputs; independently check exact source admissions.
Proceed with the two-call migration only after compatibility and the existing
axiom policy pass. No laws for opaque append are assumed.

## R6 completion criteria

R6 is complete only when all items have concrete evidence:
1. Linux decision gate establishes the supported constructive append byte law and native/generated compatibility before migration.
2. The actual two-call psTsJoin implementation uses constructive append; a general theorem covers arbitrary separator and fragment lists.
3. Exact byte equations connect the ten selected R5 binary templates to actual emission, with explicit add/and/sub grammar corollaries.
4. Native and actual generated modules pass byte comparisons (324 append pairs through both names, 50 joins and 30 selected-emitter cases), with exact source/IR/output identities and independent official admission.
5. R0–R5 trust guards pass unchanged; all new unique theorem reports obey no-axiom/propext-only policy. Connected R4 runtime self-admission and hostile/resource corpora pass; String fixture remains refused without delegation.
6. Fresh whole-compiler census, selected ordinary Linux and installed CLI workflows reach terminal success at the final source tree.
7. R5 status is reconciled; R6 profile, guideline and dated evidence receipt are committed, their selected reporting gates pass, and draft PR #194 describes the final scope.
The scoped batch can be complete while the explicitly listed whole-compiler, runtime-engine, primitive-foundation and minimal-admission obligations remain open.

## Planned implementation and evidence

After the gate, replace the two actual join append calls with constructive
`String.append`. Prove general UTF-8 byte-list composition of the actual
recursive join, then selected actual binary-emitter fragment templates using
R5's expression-template theorem. These are byte equations, not ECMAScript
parser semantics or numeral-rendering theorems.

Register proof and fixture roots explicitly. Proof-only imports stay outside
all compiler/runtime source graphs. Test fixture scope is separate from the
connected checker. Preserve every R0–R5 theorem report guard, 10/10/20 minute
job budgets and the 256 MiB generated-runtime old-space limit. All proofs,
builds, compiler execution and tests run only on GitHub Actions Linux.

Run native and strict emitted-module byte comparisons; independently validate
the exact source packets with the pinned official checker; require public
R4B to refuse the String-bearing fixture with delegated=false. Run the full
connected R4 checker self-admission, hostile-input/resource cases, fresh compiler
census and ordinary Linux/installed regression workflows. Retain receipts,
identities and logs. Require terminal source CI before a docs-only reporting
commit and a dated R6 guideline/evidence handoff.

## Claim boundary

No min-profile expansion, fixture whitelist, new foundation law, axiom,
`sorryAx`, choice or quotient dependency is authorized. New proof reports must
be axiom-free or exactly propext-only. Official Lean Wasm remains the default;
min/dual production refusal remains `PSC1_MIN_CANONICAL_BRIDGE_UNPROVED`.
Compiler preservation stays partial; no complete recursive erasure, source
freshness/name semantics, closures/scheduling, ECMAScript semantics, full
compiler admission, self-hosting, G1/G2/G3 or release claim follows.
Native constructive String semantics and PSC1's primitive prelude declaration
remain distinct evidence layers. No merge, protected-base write or package
publication is part of R6.

## Decision gate evidence

Focused run [40651548170](https://github.com/dwijayuda/pskernel/actions/runs/40651548170)
completed successfully at the unchanged-join experiment source. Proof job
122692549964, compiler-preservation/text proof and ABI job 122692549676, and
portability/census/public-byte job 122693070674 all succeeded.
The two new reports were one axiom-free and one propext-only. Native/generated
append/join checks passed. Independent official checks accepted the exact
734619-byte actual Type closure packet and 1979-byte test fixture packet.
Public R4B refused the fixture with PSC1_MIN_CORE_REFUSED and delegated=false.
R5 source and reporting workflows were separately rechecked terminal-success.
This satisfies the decision gate; final R6 source qualification is now recorded in the result profile and dated receipt.

## Separate refusal witnesses

Keep standalone Ps.MinKernel.Tests.StringBridge as its exact two-definition,
one-module append fixture. Register Ps.MinKernel.Tests.EmitterBridge separately;
its actual emitter dependency graph is independently captured and checked.
The expanded emitter packet may fail the ASCII wire profile before Core rules
are reached. That refusal is recorded separately and cannot substitute for
the standalone fixture's PSC1_MIN_CORE_REFUSED result after valid ASCII framing.
Neither witness grants String admission or changes a checker rule.

## Completion result

The final source passes focused 40656742989, main 40656748193 and installed
40656742940. All ten theorem reports, three exact source bundles, native/generated
byte checks, separate Core/ASCII refusal witnesses, retained runtime/census and
R0–R5 gates are checked. R5's scoped source/reporting batch is reconciled complete.
The reporting-only follow-up must pass its selected documentation gates before
the chat reports completion. The result profile and guideline state the remaining
whole-compiler and engine obligations separately.
