# PSC1 active work state

Updated 2026-10-22 (Asia/Jakarta). Continue draft PR #172 on
`fix/psc1-closure-normalization-20261021`; fetch the latest GitHub HEAD before
each guarded, non-force update. Use connected GitHub and Linux Actions only.
No local checkout, build or test; no merge or registry publication authorized.

## Latest full qualified checkpoint

Source 81824afb29cff6e22a693f7988797dd62a524026, tested merge
410bef1e0024c34297e1e8b94a3ea4886403bbc2, run 39672943069:
https://github.com/dwijayuda/pskernel/actions/runs/39672943069
Static, native, both focused jobs, all three complete compiler closures, G1,
host boundary, full Linux integration and aggregate gate pass. Every full job
step succeeds. All four frozen application categories now have scoped execution:
168 compiler-like process cases, 294 CLI/JSON cases and 28 library obligations,
plus separate minimum-Python counterparts. This is not complete release readiness.
At this source the machine report is 16 qualified / 21 blocked, releaseReady=false.
Permanent exact jobs, artifact digests/expiry, per-case output/source/admission
identities, measured bounds and G1 evidence:
docs/PSC1_COMPILER_APPLICATION_QUALIFICATION_2026-10-22.json.

The unchanged 100000-statement / 500000-byte bound is 120 s / 1048576 KiB.
Full TS uses 9.07/9.06 s and 193780/191096 KiB; Rust 41.04/41.83 s and about
13 MiB; PHP 55.18/55.38 s and about 81 MiB. Full Python is 70.82/67.54 s;
minimum Python 66.08/70.54 s. Focused Rust is 22.77/23.00 s versus 104-117 s
before borrowing. PHP's 400000 large-String lookup/next operations take 0.23 s.
The TS million-tail-call regression peaks at 59568 KiB under its 256-MiB bound.
These are measured workloads, not a universal performance or soundness claim.

Current qualified G1 service remains
81f03e636b4fcf5bf3863375b01422e435b29c37442dd27fdffabb63ab77e0b3,
85 modules, ten cases, one native seed and no later native delegation. Artifact
12382000308 has SHA256 51115642c82373e35a2650cacf33f6605cc9ea75d9211433f6c5e77b450b3314
and expires 2027-01-19T20:44:42Z. Source/admission/original/specialized IR hashes
are preserved in the exact qualification receipt. Earlier G1 identities remain
historical evidence.

## Active bounded acceptance continuation

The descendant source completes executable bindings for nine existing numeric,
short-circuit, inference/call and control/handler criteria. Both source grammars,
all old cases/refusals and the original limits remain. Order now has six cases
(84 all-target obligations); inference/control has ten (140 obligations).
Short circuit requires both skipped divergence and exact-commit seven-adapter
foreign-error skipping/control evidence. Missing either cannot qualify it.
See docs/PSC1_BOUNDED_CORE_ACCEPTANCE_2026-10-22.md.

This source continuation is implemented, UNQUALIFIED pending its own Linux CI.
It makes 25/37 criteria eligible; it does not change the latest qualified
checkpoint's 16/21 result. The twelve still-unbound criteria are for-loop
collections/ranges/streaming, while controller/divergence, partial pairing/
recursion, product patterns/identity, Array operations and namespace identity/
ownership. Continue that finite queue after diagnosing any new CI blocker.
G2/G3 remain deferred until complete Practical Core feature freeze.

## Historical qualified checkpoint

Implementation af0a5921aa2f3fa4dbf4959d5e2c3b14a843d972, tested merge
006ff602e2bce6dcbcad6b970f99307f3a3e7a34, Linux run 39655009732:
https://github.com/dwijayuda/pskernel/actions/runs/39655009732
Static, native, focused, all three complete compiler closures, G1, host boundary,
full scoped integration and aggregate gate pass. Historical benchmark is
correctly dependency-skipped. Readiness is 16 qualified / 21 blocked,
releaseReady=false. CLI, JSON/files and multi-module-library applications qualify;
the compiler-like application remains the next blocker.
Exact jobs, artifacts, source/admission identities and observed matrices:
docs/PSC1_ORDER_APPLICATION_QUALIFICATION_2026-10-22.json.

Constructive mathematical Nat/Int <, <=, >, >= (and Unicode spellings) have checked
total decisions; no new logical axiom or Boolean replacement for propositions.
Native regression includes 136 independent true/false inhabitation boundaries
and corrupted-decision refusal. Source conditions preserve immutable speculative
context rollback and left-before-right runtime operand evaluation.

PracticalCli independently authors .lean/.ps argument parsing, JSON record
transformation, typed file/console effects and deterministic exits. Its actual
child processes verify malformed/duplicate/trailing-comma JSON, Unicode and
quoted argv, permissions, size/UTF8 failures, preflight denial, atomic writes and
old-output preservation. Shared JSON parsing now rejects post-comma closers.
PracticalLibrary independently authors multi-module persistent collection
transforms, private imports/entry exports and missing/duplicate-module refusals.
Public aggregate ABI qualification is separate from internal Bool observations.

Wasm String/IO labels preserve valid names or derive collision-free positional
labels for all public scalar slots. Internal hygienic IR names stay internal.
Source/schema regeneration rejects same-flattened-signature String/Bool forgeries.
Nineteen native ABI checks and actual renamed core/component consumers pass.

## Current source continuation: compiler-like application

The descendant source adds MiniCompiler/Syntax, Program and Run in both grammars,
a separate official-Lean reference and a twelve-case actual process corpus.
It streams decimal-addition statements, constructs/folds expression nodes and
renders canonical JSON, with typed UTF8 byte offsets and scalar line/column
diagnostics. It is an application acceptance workload, not PSC1 self-hosting.

The 100000-statement input is 500000 bytes. Each actual checked child must produce
the exact summary within 120 seconds and 1048576 KiB RSS, measured by Linux
/usr/bin/time. Failed workloads retain measurements before acceptance assertions.
No guest fuel or compiler/host/ABI resource limit is raised. The explicit 1 MiB
file configuration fits the existing 2 MiB Wasm IO ceiling and 16 MiB arena.

The initial source remained unqualified through the diagnosed parser, TS and PHP
failures below. Its corrected application is now qualified at the latest full
checkpoint above; later bounded acceptance changes need their own Linux gates.
Focused execution includes JS/TS/Rust and both Wasm consumers; full includes all
seven and minimum Python. Readiness binds compiler-like acceptance only to the
complete versioned application matrix and successful final qualification.
Run: `node scripts/practical-application-tests.mjs --compiler-application`.
Diagnose any measured failure through shared semantics/runtime mechanisms;
retain the corpus, limits, negative cases and earlier regressions.

## Single release authority and remaining queue

docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json freezes fourteen families, 37 finite
criteria, four applications, both grammars and seven targets.
docs/PSC1_DEVELOPMENT_ROADMAP.md is the single active roadmap. Exact-commit
scripts/practical-core-readiness.mjs derives implemented/tested/qualified/blocked
status. A generic source fixture or green subset never qualifies a complete
application, family or release.

After compiler-like/performance acceptance, finish the 21 unbound family
criteria in dependency order: operators and bounded inference, typed control/
ownership and collection evaluation, partial pairing/recursion, tuples,
handler/call/namespace refusal boundaries. Reuse and complete actual existing
regressions; do not infer coverage from filenames or bind a weaker case.
Feature freeze and --require-ready remain blocked until every criterion and all
four applications pass full exact-commit release qualification.

## Preserved historical G1, soundness and history

Qualified G1 service 3f64bd223c09ca0175b1cf249d1689d4934e0756cf2c43c01b086a5cdf07b2a5,
85 modules, ten-case v2 corpus, one native seed, no later native frontend/emitter
delegation. SourceClosure 00f66643fa9b19d6dd5540ea7ebffb89586e95693f164e0888d5482a489f6446;
admission 0a619f9a8f2fa8b859abd404aa4a170574a6721fcb818080b24290a029b60a57;
original IR 9b43e71282cb5b314464e4ac06aa6a344c8f4bbe6ad80a4dc21a43c1a26ba900;
specialized IR cccb67bb757bbd9b703d666704fdc98dbf598931acba42a3098b8f7dc2aaf677.
Artifact 12372321627 expires 2027-01-19T18:41:39Z; exact SHA256 in the receipt.

Earlier qualified typed IO implementation 74179eb664e132502a24ce60b52a3dbd52b1d0cc,
run 39627387430, and its qualification JSON remain historical evidence.
The f799 inference/protocol, 5a0f sequencing and 1fbf standalone checkpoints,
earlier G1 services/artifacts, sources, tests and successful receipts remain
preserved. Failed diagnostic commits through 66b/1e975/af0 remain in Git history.
Run 39647987402 did not qualify the full application matrix: both Wasm builds
refused internal parameter labels. Run 39652529384 failed native test-fixture
layout. Neither failed run is promoted by later unrelated successful steps.

G2/G3/fixed points remain separate manual qualification after stable freeze.
Preserve original V8 heap-exhaustion and later post-fusion timeout evidence and
old CPU replay identities; address shared defects when normal workloads expose
them. PSKernel-Core Expression V2 research stays independent. Official Lean
4.35.0 admission is pinned at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Strict original/transformed/target IR, ordinary pairing, security/resource limits
and all regression/negative tests remain required.

## Compiler-like first Linux diagnosis

Head 5893484fca3c01266a973c5739a827436deb4c83, run 39659059072, passes
static and native. Focused job 119427257285 refuses MiniCompiler/Syntax.lean at
53:5 before executing any application case. Native inline else-if chains were
anchored at the later if column, allowing their final else to be stolen by an
enclosing conditional. The parser now carries the original chain layout owner
through a structurally bounded helper and closes only the chain, preserving
following statements, source spans and the strict PS brace grammar. New native
execution/roundtrip/refusal cases cover all eight nested branch combinations,
a braced chain and its continuation. The authored application stays unchanged.
This fix and the application remain unqualified pending fresh Linux gates.

## Parser regression pass; TypeScript publication diagnosis

Parser fix 4bf65cfd00c59a66b65970351c1cd028a64409f3 passes native run
39660161726, including all nested/continuation/translation/PS-refusal cases and
strict source census. Focused Lean/JS passes all twelve compiler application
cases; the 100000-statement process takes 1.79 s and 443316 KiB RSS. This is a
single-consumer result, not complete application qualification. Lean/TS then
refuses PSC1_FORMATTING_CHANGED_SYNTAX_TREE before publication. The exact AST
guard remains unchanged; its diagnostic now identifies the first before/after
field difference to diagnose the formatter/emitter class instead of bypassing
formatting or changing source fixtures. Full/closure/G1 lanes correctly skip
after the focused failure. Fresh Linux evidence is required.

Diagnostic commit acc561e8ee91d5deb0e4a4bafe23baf7631da856 failed static
Node syntax checking in run 39661066232. A JavaScript string replacement expanded
a replacement token in the inserted diagnostic text. The edit is reconstructed
from the prior source with literal callback replacement; no compiler lane ran
and no formatter refusal was bypassed. All failed commits remain preserved.

## TypeScript single-constructor emission correction

Run 39661381346 at 2cd3b64027205b203f7883f800aac3f96504690b passes static
and native gates. Focused Lean/JS repeats all twelve application cases, including
100000 statements at 1.79 s / 305596 KiB RSS. The exact formatter diagnostic is
root.body[79].typeAnnotation.members: the single MiniExpr constructor was emitted
as a one-member leading-pipe union, while Prettier emits its object type literal.
The TS backend now emits canonical zero/single/multiple-variant type shapes.
The host's complete syntax-tree equality remains unchanged. New host tests
require canonical shapes to stay equal and the redundant union to keep refusing;
the actual single-constructor application and independent TS checker remain the
execution regression. No source fixture or admission/IR policy is changed.
Full application and release readiness remain pending fresh Linux evidence.

## Measured TypeScript tail-continuation blocker

Run 39662002050 at 908cbc300ef0f3e96c1112e458da66b558c4782e passes native
and the TS formatter/type-check boundary. The actual Lean/TS 100000-statement
child returns correct output, but peaks at 3463956 KiB RSS (13.29 s), exceeding
the unchanged 1048576-KiB bound. Lean/JS passes at 1.53 s / 304400 KiB. No other
backend is inferred tested after the focused fail-fast boundary.

The general TS emitter now propagates tail context only through complete
function/lambda results, let bodies, branch results and match alternatives.
Operands, callees, local values and other surrounding continuations remain
ordinary. The private driver replaces a complete-result frame for tail calls,
including mutual/indirect calls. All existing fast paths stay intact.
A registered native strict-IR fixture plus independent TS checker/actual consumer
verify mutual/non-tail recursion, context boundaries, captures, exact-once
operand order, traps and strict divergence. Focused/full gates require it;
final consolidation binds its exact commit/hashes and bounded RSS evidence.
Failed application cases now retain checked bundles before execution.
See PSC1_TS_TAIL_CONTINUATION_DEFECT_2026-10-22.md. The new correction and all
application/performance acceptance remain UNQUALIFIED until fresh Linux CI.

## Seven-target compiler application diagnosis and String performance continuation

Implementation 5fa88fa1842d8d8d9fa1881592ed2801d2778b37, tested merge
5f730e3fd798cfa5597d35c204c3aed03842fe0d, run 39664407902 passes native,
focused, all three complete closures, G1 and host boundary. Full job 119453141986
fails the authored application step: Lean/PHP's 100000-statement child times out
at the outer 180-second guard. All later independent steps pass, including both
minimum-Python consumers; they do not override the failed step. No new full
qualification or four-application completion exists. Exact diagnostic evidence:
docs/PSC1_APPLICATION_PERFORMANCE_PROGRESS_2026-10-22.json.

The ten focused compiler consumers pass all 120 cases. TS now uses about 189 MiB
instead of 3.30 GiB; its million-tail-call regression uses about 57 MiB while
preserving non-tail contexts, traps and strict divergence. Lean/full Python is
59.95 s; minimum-Python Lean/PS are 73.07/64.83 s. Rust is 104-117 s in focused
and 116.15 s in full, close to the unchanged 120-second bound.

The active correction caches two completed PHP UTF8 validations, uses scalar
byte boundaries for constant-time lookups, and reuses validation in the selected
module's String guards. Runtime-free String echo stays unchanged. A separate
focused PHP lane adds malformed/boundary/cache/copy-on-write and common-prefix
lookup regressions plus both actual applications, without removing any existing
focused target or increasing job/process limits. Rust borrows only immutable
local String operands in existing read-only helper slots; every operand still
passes normal emission/fuel checks. New negative fuel/arity tests remain required.
Both corrections are implemented but UNQUALIFIED until fresh Linux gates.

New G1 service 81f03e636b4fcf5bf3863375b01422e435b29c37442dd27fdffabb63ab77e0b3
passes its 85-module, ten-case regression at this failed full checkpoint.
Artifact 12376913803 expires 2027-01-19T19:45:30Z; source/admission/IR digests
are in the diagnostic receipt. Earlier qualified G1 services and the af0a full
checkpoint remain preserved. G2/G3 remain deferred. The 21 unbound finite family
criteria and compiler-like application remain release blockers.

## Bounded acceptance first focused diagnosis

Source f7807b31aabd3ed1d06d7763c9d70e5450849cca, tested merge
47e892ac63ecf934ed0d7c5797e3dca6f86eed19, run 39679135943 passes static and
native. Both core-Wasm source/control observations pass. Focused component
consumers fail the new second independent negative probe with Wasmtime's
"cannot enter component instance" after the original expected foreign trap.
No full qualification or new criterion completion is inferred.
Each expected component trap now runs in its own fresh process/store, retaining
both exact trap assertions, both source grammars and all existing IO effects.
The corrected acceptance group remains unqualified pending fresh Linux CI.
The prior full qualified source remains 81824afb and its permanent receipt.

## Checked signed equality continuation

Source 27817c3e78d5f624ccb42308272384a36b940313, run 39679904247 passes
static, native and both grammars of the isolated core/component foreign-error
probes. Focused execution then refuses numericCase in both grammars before
publication: Boolean == accepted Nat/Bool but not Int. This is a shared
elaboration gap, not a backend or application fixture error.
Int ==/!= now use two constructive checked Int order decisions and strict
left/right Core lets. No logical axiom, builtin runtime equality shortcut or
mixed-domain conversion is added. Fifty independent pinned-kernel true/false
conversion boundaries and strict operand-let checks supplement an actual
signed/zero/huge equality case on both source surfaces. Order grows to seven
cases (98 complete obligations). Earlier 84-obligation wording is historical.
This correction and the bounded acceptance group remain unqualified until
fresh Linux gates. Keep the original numeric acceptance fixture unchanged.

## Constructive conditional admission

At f3c601569e30381bd829a3df1813624cc1da1f2d, run 39680854096, native
admission reaches all 136 existing order boundaries but refuses the new signed
Bool conversion. The prelude still declares ite as opaque, so a type-correct
conditional cannot compute to its selected Bool in the independent kernel.
Keep the stronger conversion assertion. The prelude now registers Decidable's
recursor metadata and replaces the old ite axiom with a total definition over
the existing checked constructors, preserving the exact public type/universes.
Runtime conditional lowering is unchanged. No axiom, fuel or validation bypass
is added. Fresh independent admission and all source/backend gates are required.

Focused execution now runs the inexpensive inference/control suite immediately
after checked order, before the measured applications. The test command set,
targets, resource bounds and final qualification remain unchanged; grammar/type
failures should no longer pay for an unnecessary application replay first.

Run 39681838046 at 93f2ca958cb2cc79248e9cbfe9b07631143acd76 stops the native
test build at OperatorTests.lean:90: the new multiline diagnostic continued
outside an inline match branch. The production conditional module compiles.
Move the diagnostic application into the branch's owned indented body; all
fifty conversion assertions and existing 136 order boundaries remain required.
No successful full or new-criterion qualification is inferred from this run.

The reordered focused stage in that run passes all 42 selected order
obligations, then the independent native reference diagnoses two authored-Lean
notation issues before any inference target runs: adjacent boundedUnit(())
needs native whitespace, and unbraced nested try/catch ownership is ambiguous.
Use native-spaced explicit Unit application and owned braces in the same Lean
fixture, preserving the PS fixture and expected semantic cases. A separate
registered native frontend/admission regression retains adjacent f(()) in both
PSC1 source grammars, so native-oracle spelling cannot hide a parser gap.
