# PSC1 — Practical Core and seven-backend development

Updated 2026-10-21. Active draft [PR172](https://github.com/dwijayuda/pskernel/pull/172)
on fix/psc1-closure-normalization-20261021. Inspected remote HEAD before pivot:
1d5c45e01f9016365a440c8b8c05916249cfaa4c. Base #171 remains immutable at
1fad9ed53cda9b23ac30be9cea85e7857437564e. All commits/history preserved.
Use GitHub tools and Linux CI only.

## Active priority pivot (explicit user instruction)

The [development roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) supersedes the
self-host-first order in the older Sol High prompt. Continue actual Practical
Core, both authored grammars, seven backend mappings, architecture, practical
application compilation and runtime work. Do not stop at planning changes.
G2/G3/fixed-point qualification is deferred until a stable feature freeze.

Normal generated-compiler CI retains the full existing8-case G1 functionality
corpus, one native seed, complete-source admission/IR and host authority/refusal
checks. Full G1->G2->G3 uses the same controller with --self-host in the separate
manual psc1-selfhost-qualification workflow. No generation assertion is removed.
Expensive G2 CPU and fixed compiler profile workflows are also manual. Existing
scoped/native/closure/target/package gates remain unchanged. G1 artifacts use90-day
retention; exact historical source and qualification receipts remain preserved.

Latest pre-pivot HEAD1d5: scoped39552904242 SUCCESS; all3 whole-closure jobs
39552904236 SUCCESS; native39552904280 SUCCESS; fixed-input native comparison
39552904261 SUCCESS. Actual39552904167 passes all8 G1 cases, then G2 timeout
240177ms before publication. No G3/fixed point. Latest exact CPU replay
39552904187 is diagnostic success, G2 execution ETIMEDOUT240278ms.
[Tracked open performance defect](docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md)
retains the original proven heap exhaustion, fusion correction and later timeout.

Next development: close CompilerM all-target state/error/control coverage and
finite versioned grammar×target receipt enforcement, then follow remaining
Practical Core decisions. Preserve complete compiler sources, checker pins,
strict IR, exact ordinary pairing and all prior regression/refusal tests.
Pivot changes are pending Linux CI until exact runs are recorded below.

## Historical evidence and implementation record

The entries below retain their original chronology and pending-at-the-time
language. Their old instructions to prioritize G2/G3 are superseded above.

## Earlier fusion source/harness corrections

Atd70c910b Native Lean compiled the new pass and tests. Both source grammars
refused WorkerFusion.sink164:1 with unknownName:sink because its recursive fuel
match sat inside an outer empty-arguments conditional. Put the fuel match at the
top and retain the same zero/empty behavior in its branches.

The raw fixture was correctly refused before fusion for external-import-abi-
unqualified. Remove that unsupported import; observe operand order/count through
private language-function parameters and an explicitly authored scalar JS harness.
Retain an assertion that imported raw wrappers refuse, and report exact checker
findings on any invalid fixture. No import/public ABI or checker rule changes.

The profiler now includes the actual shared closed plan. Compare identical graph/
original/pre-fusion inputs; actual closed IR and source are expected to change
under fusion and are validated separately. The prior quoting-only byte identity
receipt remains valid for its immutable pre-fusion checkpoint.

## Typed worker application fusion, Linux pending

The exact retained IR confirms psJsonStringCharsAccWithFuel has1 declaration
parameter and3 returned unary lambdas. Its saturated recursive alias application
was printed as nested generator invokes, retaining one chain per input byte.
[Typed worker design](docs/PSC1_TYPED_WORKER_FUSION.md).

Add the general CompilerIr.WorkerFusion pass to the shared closed backend plan.
It retains original declarations/partial uses, adds private full-arity companions
only for total guarded lambda-producing prefixes, preserves lexical scopes via
typed beta lets and exact-once alias captures, rewrites saturated applications,
and strictly rechecks the complete transformed module. Unsafe/unrecognized
prefixes stay untouched. No arbitrary recursor IH is globally delayed.
Normalize all11 structural returned-state helpers in Bridge.Json consistently;
their partial smaller worker is evaluated inside the state lambda.

New Linux tests compare baseline/fused early/full work, closures, shadowing,
strict operand order and divergence; forged typed wrappers still refuse.
The new module is an explicit Lake/import root with maintained parse/elab gates
in both grammars. Expected backend closures gain1 module; qualify actual counts.
All this code is PENDING native/source/target/G1/G2/G3 CI. Do not infer success.
Compiler limits and default Node heap/stack remain unchanged.

## Earlier measured G2 process abort

At3b189f589b0a4ad06eb1bcc666014220e72268df, actual G1 again passed all8 corpus
cases with recorded scalar observations. Real G2 self-compilation was then
attempted on identical captured compiler sources. The generated Node process
aborted withSIGABRT after131880ms, before any candidate/publication. No G3.
[Exact attempt](docs/PSC1_G2_FIRST_ATTEMPT_2026-10-21.json), run39545154962,
job119041551702. Request SHA256:
1353995b84b1e33f3c0942a758e94a41c68dcb8f8b5fbc74d8f19fc6db73b331.
Exact replay39546176974 now CONFIRMS a JavaScript heap exhaustion at125656ms.
[CPU/failure receipt](docs/PSC1_G2_CPU_FAILURE_2026-10-21.json).
89848 sampled ticks: WeakCollectionSet26.1%, WeakMapLookupHashIndex10.1%;
hot JS locations are the nested lambdas of psJsonStringCharsAccWithFuel at
G1.mjs626. UTF-8 helper itself accounts for0.1%; do not guess a cache patch.
The emitted scanner allocates wrapped worker closures while traversing input.
Inspect its EXACT retained original/specialized IR and emitted function next;
a read-only hash-checked inspector job is added to the profile workflow.
Then fix the general narrow worker/application mechanism and verify unchanged
strict evaluation/capture/escaping behavior. Existing Js tail aliases require
saturated declaration arity; a returned function worker does not satisfy that
condition merely because its recursive state call is in source tail position.
Do not globally delay arbitrary recursor hypotheses or alter memory limits.

The original host session recorded status/signal/time but discarded stderr.
Its rejected .stage directory was hidden from default artifact upload. Correct
the host diagnostic mechanism: retain stdout/stderr on process failure and move
rejected stages to non-hidden failed generations; retain failure state/events
without granting publication. Print a bounded stderr tail in Linux logs.
Publication failures preserve the prior pointer, including injected failures.

A separate Linux CPU-sampling replay downloads the exact qualified G1 artifact,
checks its known service hash and the exact failed G2 request hash, and executes
only that G1 through the fixed runner with Node --prof. No native compiler/checker
is installed/called and no response is adopted. Existing240s cap/default heap/
stack remain. A green profile collector is diagnostic only, never G2 qualification.
Use actual stderr and sampled hot code to correct the reached compiler mechanism,
then repeat real G1/G2/G3. Continue continuously.

## Latest actual G1 execution

Qualified implementation921eb1d7b8a5dc539d192ccda5a4ceb14c21ac52.
Tested mergeece4925682d426509868564f663c26c482f91a2a.
Generated workflow39543944316 is completed/success, including host boundary.
[Durable G1 receipt](docs/PSC1_G1_EXECUTION_QUALIFICATION_2026-10-21.json).
Actual G1 service SHA256:
7a1efe8d3e03e5c507d00e034651b81fa7d4062c5a459e9a356c9753aaaa531d.
Full compiler source closure83 modules, canonical admissions
1bbdfa80eb942ce1930b0889f77ff9c2bbe4115c6b22cdd83ce36bd7ab6e2d76;
original IR1b92f8a5a779211d187a3e70273d5e7337a8c096a650bc885d97124d3a5ce888;
specialized IRfd46ee97e13e06002abf33719e97c521036408333bcb3be87f5ed308669bb969.

Native stage0 generated G1 once. Its exact graph was independently admitted.
Native compiler binaries were then disabled; the explicit independent checker
remained. Actual G1 compiled/admitted/published/executed:
- Lean multi-module/internal ownership1546ms/564428KiB;
- PS exact huge integer/Unicode1055ms/391292KiB;
- Lean typed handler/pattern3593ms/387964KiB;
- Lean explicit Id ordinary while4732ms/409288KiB.
G1 refused wrong bodies, missing imports, checked-only partial and verified requests.
These are selected cases, not complete language families or preservation.

Focused39543944344 and all3 exact closure jobs39543944319 passed. Both grammar
lanes accept EVERY selected module: semantic68, DirectJS83, Rust86. Exact logical
counts2439,3254,3033; checked semantic and ordinary-checked backend graphs.
Owned PS compiler input is canonical translation from Lean, not independent PS
compiler authorship. Original graph/IR bytes match both lanes in each phase.
Full scoped39543944381 is now completed/success. [Full G1 qualification](docs/PSC1_G1_FULL_QUALIFICATION_2026-10-21.json) retains the complete scoped result and artifact identities.
The earlier fully scoped checkpointadcb8157 passed39541282484, focused39541282570
and closures39541282485; [complete earlier receipt](docs/PSC1_SCHEDULER_FULL_QUALIFICATION_2026-10-21.json).

## Current candidate — actual repeated JS generations

The new controller now attempts G1->G2->G3 over the IDENTICAL captured83-module
compiler+JS closure. No native frontend/eraser/emitter is available after G1.
The same official checker and target Node remain. Before successor publication,
canonical admissions, original/specialized IR and generated source must equal
G1. Each generation then executes the same corpus and actual observations.

Versioned psc1-js-generation/4.35.0-v1 manifests retain exact source-file inventory,
producer/service/seed/Node/checker/runner/host-controller identities and corpus
observations. Closed bundle verification rejects missing/extra/changed files,
stale graph/tool/manifest context and historical schemas; tests preserve originals.
Readers return DATA, not publication authority. The private live host session
still owns real execution/admission/target checks and the atomic pointer commit.
G2/G3 and fixed point are PENDING actual CI. On failure retain the process event,
stage files and last completed generation, then fix the reached mechanism.
Do not raise240s process,16384 specialization or existing stack/heap/checker caps.

## Mechanisms corrected and measured

ParseDo124:67 and every subsequent complete selected source blocker are normalized,
with original decisions/refusals/budgets retained and maintained both-lane gates.
Private compiler helpers retain explicit Ps.Internal owners, shared public-root
filtering and full internal source/admission/runtime graphs. Native deriving
instances live outside the portable closure. Canonical IR encoding retains all
data and exact decimal integer strings; it supplies identity, never authority.

Specialization formerly charged29185 repeated seed references against16384.
Stable canonical-key scheduling reduces these to653 initial unique requests;
752 final instances/2230 declarations complete without omitting source entries.
Hash trie buckets always check full strings. The same-input synthetic fixture
retains all128 concrete entries plus1 instance; baseline refuses, candidate finishes.
[Queue receipt](docs/PSC1_SPECIALIZATION_QUEUE_COMPARISON_2026-10-21.json).

Actual G0 then hit240s while quoting its19MB admission graph. Balanced immutable
UTF-8 span quoting preserves exact bytes. Fixed immutableadcb workload comparison
39543395472 completed/success: baseline times out in encode-admission-request;
candidate completes the full40217563-byte response33710ms (quoting769ms).
Admissions, original/specialized IR and generated JS hashes are IDENTICAL.
Independent ECMAScript serialization validates the transport bytes.
[Full comparison](docs/PSC1_COMPILER_TRANSPORT_COMPARISON_2026-10-21.json).
The profiler is diagnostic only; its output is never adopted as G1.

The host-only session pins inputs/options, whole candidate and tool identities;
it performs actual generated invocation, independent exact graph admission,
target syntax/export checks and closed inventory/hash rechecks under a lock.
One atomic current-pointer rename publishes an immutable generation. Prior
generations remain.24 host boundary checks passed on real checker/publication
state with explicitly native-prepared replay fixtures. Actual G1 uses this same
publisher. [Protocol](docs/PSC1_GENERATED_COMPILER_SERVICE.md).

The first ordinary fixture used unsupported plain Nat do and Prop '<'. Corrected
to the existing Id Nat / Bool Nat.blt contract, with both authored grammar cases
admitted and executed through the native facade. No language rule was widened.
The earlier3-case partial receipt remains immutable.

## Authority, remaining work and durable commands

Official checker: Lean4.35.0,
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Owned kernel evidence is separate.
Keep ubuntu24.04, Node22.23.3, TS7.0.2, Rust1.90.0, Python3.14.8/3.15.0,
PHP8.5.11+GMP, wasm-tools1.254.0 and Wasmtime49.0.4 pins.
Use expected-HEAD guarded non-force descendant updates; no main merge/release/npm.

Next: inspect new generated workflow at exact candidate head, complete real
G2/G3 or resolve its actual bottleneck; verify current full scoped final state.
Then follow Rust owned callbacks and R1/R2/R3, measured collections/control,
finite fourteen-family grammar×target contract and typed console+UTF-8 file IO.
Wasm W1-W6, optional adapters and source refactoring stay in dependency order.
No formal erasure/backend preservation, broad conformance, complete14 families,
Rust fixed point or unrestricted self-host claim is made.

Linux reproduction:
lake build psc1_js_service_tests psc1_js_service_seed psc1_source_census_probe psc1_independent_checker;
.lake/build/bin/psc1_js_service_tests;
node scripts/compiler-source-census.mjs --strict-phase directjs-compiler;
node scripts/compiler-closure-qualification.mjs --phase directjs-compiler --assurance ordinary-checked;
node scripts/generated-compiler-diagnostic.mjs.
The diagnostic calls stage0 once, disables native tools, then runs generated
semantics and repeated-generation attempts; use its retained records on failure.
