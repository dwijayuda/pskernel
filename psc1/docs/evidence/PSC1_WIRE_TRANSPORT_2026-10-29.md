# Checked wire transport and validation reuse

This change has two separately measured parts. The installed host removes a
duplicate original-IR pass. The shared Lean source adds a serializer parameter
that allows a fixed private host adapter to use native JSON string quoting.

[Qualification receipt](../PSC1_WIRE_TRANSPORT_QUALIFICATION_2026-10-29.json)
records the exact source, graph, package, job and artifact identities. PR #215's
source40872117065 and retained CLI40871621864 are terminal green.

## Required checks

| Responsibility | Owner and invariant |
| --- | --- |
| Check-only original IR | [prepared-engine](../../host-tools/prepared-engine.mjs) validates each issued check, including preparation reuse |
| Build original IR | [compilePreparedWithQuote](../../packages/compiler/src/Ps/Compiler/Service.lean) validates before target transforms; the adapter no longer repeats it |
| Transformed IR and public ABI | Existing generated target pipeline remains unchanged |
| Wire string escaping | [wire-quote](../../host-tools/wire-quote.mjs) supplies one fixed Node callback; UTF-8 scalar roundtrip and JSON roundtrip must match the input; otherwise use the generated serializer |
| Admission request construction | [CompilerHost](../../packages/bridge/src/Ps/Bridge/CompilerHost.lean) constructs transport data; the request itself grants no checking authority |
| Logical admission | The official independent Lean 4.35.0 kernel checks the exact canonical bytes freshly |
| Target consumption/publication | Existing checked consumers, resource guards and transactional publisher remain |

Project configuration and wire data cannot supply callbacks. Other runtimes and
non-scalar UTF-16 inputs conservatively use the normative generated quoter.
Compiler/checker timeouts, heap/stack, response limits and semantic fuel remain.
The quote traversal is transport work; source-program execution fuel is unchanged.

Existing Lean entry points apply the new implementation to psJsonQuote. CI copies
the exact prior bodies into test references, checks their correspondence and proves
both legacy function equations with rfl. Lean reports [propext] dependencies;
no sorryAx was observed. These equations concern legacy transport behavior, not
a general compiler preservation theorem.

## Actual evidence

[Generated compiler40879970347](https://github.com/dwijayuda/pskernel/actions/runs/40879970347)
builds and independently admits all 4907 logical declarations, strictly validates
original/transformed IR, and emits 134 units in 15 source-owned packages.
All packages pass strict TypeScript 7.0.2 checks. The original five partial names
remain explicit. Nine graph-integrity negatives still refuse.

Each generated JS/TS engine compares native and portable quote bytes over all
1,112,064 Unicode scalars, control/escape boundaries and four fallback inputs.
Each engine executes 13 candidate cases: both grammars, four core output targets,
typing refusals and an 11-module application with initial/body/comment edits.
Candidate bytes match both the generated legacy service and qualified .7 reference.
Successful candidates independently admit natively; all six large applications
also admit through the official Wasm kernel and execute Unicode JSON/file processing.

[Paired40882916436](https://github.com/dwijayuda/pskernel/actions/runs/40882916436)
reuses that exact graph and host sources. A test-only adapter disables the native
entry selection; capture, reuse, original/transformed checking and graph identity
are otherwise identical. Both sides independently admit and execute each application.

| Prepared candidate case | Portable | Native | Saved |
| --- | ---: | ---: | ---: |
| JS body edit |10885 ms|8677 ms|2209 ms|
| JS comment edit |6293 ms|4018 ms|2275 ms|
| TS body edit |11959 ms|9170 ms|2789 ms|
| TS comment edit |6674 ms|4179 ms|2495 ms|

These are candidate-only observations, not end-to-end CLI bounds. Initial samples
include JIT/order effects. Main-process peak RSS for the paired tests was
643752 KiB (JS) and 768328 KiB (TS); child checker memory is excluded.

Installed [40881471194](https://github.com/dwijayuda/pskernel/actions/runs/40881471194)
passes both engines/grammars, 12 executed JS/strict-TS/Wasm builds, four typing
refusals, 24 candidate comparisons, 14 original/14 warm kernel fixtures, tamper
refusal, dependency edits, error repair, publication retention and shutdown.
Same-runner .7/.9 comment-edit means were 7369/6762 ms, about 8.2% less time.
The report's candidate-.8 label is historical controller text; the actual .9
tarball SHA and package receipt identify the tested bytes. The controller is
corrected for future runs. Earlier isolated .8 sampling measured 4.6% less time;
none of these observations is a universal speed guarantee.

## Source cohorts and promotion

The installed .9 root retains source17ce1991, graph74e14f56, and that source's
qualified JS/TS G1/G2/G3 fixed points. Its nativeQuoteCalls are zero because the
older graph lacks the new entry point. Its immediate runtime change is duplicate
validation removal, with a tested quote-ready host fallback.

The new source7e25050f cohort has digest120bbbc5 and G1 manifest5ba70eff.
It genuinely executes the native-quote path above. New G2/G3/fixed points have
not been run for it, and it is not substituted into the G3-locked distribution.
The existing strict provenance gate remains. No merge or registry publication.

Next: batch any further shared-source changes, then run the manual exact
new-cohort G1/G2/G3 promotion gate once stable. The old correctness requests took
about 49–51 minutes each; preserve the 3600s correctness and separate 240s
performance profiles. Do not repeat that chain for benchmark-controller edits.
Preserve .7, optional Python/PHP, all seven backend semantics and prior platform
evidence. Native Rust/Wasm compiler executors retain their existing cohort limits.
