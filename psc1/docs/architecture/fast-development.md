# Fast installed .ps development

The .9 retained-source host and the new G1 serializer have [separate finite Linux/Node qualification](../PSC1_WIRE_TRANSPORT_QUALIFICATION_2026-10-29.json).
The [transport walkthrough](../evidence/PSC1_WIRE_TRANSPORT_2026-10-29.md) explains the checked boundaries and source-cohort promotion gate.
The [.7 receipt](../PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json) retains its original scope.
The [.6 receipt](../PSC1_PERSISTENT_QUALIFICATION_2026-10-29.json) preserves its prior scope.
The previous [.5 receipt](../PSC1_DEVELOPMENT_QUALIFICATION_2026-10-29.json) and
[.4 cross-platform receipt](../PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json)
retain their distinct scopes. No compiler graph, kernel artifact or self-host
qualification is relabelled.

[Verified .7 Linux x64 ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40871621775/artifacts/12895314098)
contains the tested root, matching TypeScript SDKs, installation instructions,
checksums and exact qualification/comparison receipts. Sign in to GitHub first.
Adoption40871621775 verifies the tested bytes at1e104ecc; no rebuild.

[Verified .9 Linux ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40885379578/artifacts/12901169879)
contains the tested retained-G3 root, matching TypeScript SDKs and scoped receipts.
It includes duplicate-validation removal; native quoting is checked in the newer
G1 compiler and awaits that cohort's own G2/G3 promotion. See INSTALL.md.

## Use

Install the matching root and optional SDK tarballs with the exact offline
command in the delivery ZIP's INSTALL.md. Nothing is published to npm.
Node >=22.23.3 is the compatibility minimum; qualification records its exact runtime.

```sh
npm exec -- psc check Main.ps
npm exec -- psc check Main.ps --watch
npm exec -- psc build Main.ps --target js --out out --watch
npm exec -- psc build Main.ps --target ts --out out-ts --watch
npm exec -- psc build Main.ps --target js --out audit --evidence full
```

Both .ps and supported .lean source use the same compiler APIs. A check without
target omits emission; explicit --target/ABI retains complete target checks.
TS output still requires its exact SDK. Rust and optional provider requirements
and unsupported-ABI refusals remain. The two source grammars do not change which
backend consumer is required.

## Responsibilities and invariants

| Component | Responsibility | Required invariant |
| --- | --- | --- |
| CLI capture/watch | Explicit source snapshots and bounded polling | Byte/config identity; superseded work cannot publish |
| resource-capture.mjs | Coalesce duplicate reads during synchronous plan construction | Scope ends before execution; mutable resources are hashed fresh afterward |
| running-executable.mjs | Narrow running-image identity optimization | Local ext4/XFS, same loaded inode/path and fresh ETXTBSY proof; otherwise fresh SHA-256 |
| prepared-engine.mjs | Schedule unchanged generated preparation/build functions | Strict IR checks remain; exact source prefix reuse, suffix invalidation and reset on failure |
| warm-compiler.mjs | Private loaded compiler capabilities | Exact selected adapter path/hash; source data cannot supply a callback |
| warm-kernel.mjs | Supervise the official independent checker worker |120s/request,128MiB input,32MiB response,4096MiB heap/8MiB JS stack; checked response identity |
| warm-kernel-worker.mjs | Execute the exact official Emscripten launcher and Wasm | Fresh VM context, instance, memory and logical environment for each request |
| Existing target consumers/publisher | Validate requested output and commit it transactionally | Strict target checks, source guard, durable protocol and failure retention unchanged |

The VM is an adapter for trusted pinned kernel code, not a sandbox for source
programs. The kernel remains the official Lean4.35.0 C++ kernel compiled with
Emscripten into linear-memory WebAssembly. Neither a handwritten checker nor
Wasm GC is introduced. Retaining a compiled WebAssembly.Module avoids repeated
startup; it does not retain accepted declarations between requests.

Setup coalescing never spans compiler/checker/consumer execution or publication.
The executable optimization hashes the actual loaded image via /proc/self/exe,
then checks pathname/inode binding and active write denial on every use.
Only local ext4/XFS are enabled. Writable/unprovable images, unsupported hosts
and replacements fall back to fresh reads/hashes. A different inode is never
accepted through the retained image record. Receipt timings expose
setupRunningExecutableBindings so the active path can be diagnosed.
Linux kernel mechanisms are documented in
[fs.h](https://github.com/torvalds/linux/blob/master/include/linux/fs.h)
and [exec.c](https://github.com/torvalds/linux/blob/master/fs/exec.c).

Preparation caches stay in private memory. Exact source bytes, module order,
grammar, entry and assurance determine reuse. Source changes invalidate the
affected prefix suffix; errors clear reuse. Build emission invokes the existing
generated compilePreparedWithOutputAbi and existing backend emitters.24 exact
candidate comparisons cover both generated data representations. Fresh independent
admission and strict IR validation still run for every issued checked request.

Unchanged successful check saves retain the previous result and emit an unchanged
event, without a new request, new acceptance claim or publication. Failed attempts
clear that reuse. Builds continue through output/publication validation.
Watch uses one private sequential Linux/Node worker,240s/request,4096MiB heap,
8MiB stack and64 attempts/lifetime; termination owns the process group.
Other hosts/runtimes retain their previous one-shot route and lack new .6 evidence.

## Bounded reuse of compiler values

[prepared-engine.mjs](../../host-tools/prepared-engine.mjs) invokes the unchanged
generated [prepare/compilePreparedWithOutputAbi functions](../../packages/compiler/src/Ps/Compiler/Service.lean).
Preparation is a pure function of assurance and the complete generated elaborated
result, including environment and declarations. Fresh source capture, exact closure
checking and origins remain outside reuse. A structural comparison accepts only
equal private immutable inputs; it does not approximate equality from source text
or public signatures. Changed bodies recompute. Request IDs/digests and origins
are rendered freshly by the generated compiler.

[compiler-data-equality.mjs](../../host-tools/compiler-data-equality.mjs) compares
all own keys, property flags, values and hidden constructor symbols. Equal shared
nodes can be skipped only because these private generated values are immutable;
this is not a comparator for arbitrary stateful JavaScript objects. Distinct
accessors, unsupported prototypes, cycles or traversal/time-budget exhaustion
produce a cache miss. Iteration avoids recursion overflow. Bounds: one million
visited nodes/keys,100ms comparison,8192 own keys/object.

One target emitter input/result graph may be retained, with at most4,194,304
source characters. Its complete validated-module and public-name inputs must
match. The generated target pipeline, original/transformed IR validation, resource
checks, independent kernel admission, target consumer and transactional publisher
still run. Errors and reset discard reuse. There is no disk or admission cache.

The .7 installed suite and exact parity gate pass both engines. A controlled
same-runner11-module application comparison measures7213→4566ms stable warm
comment-edit rebuilds; first requests10147/10037ms show no material cold gain.
All six builds independently admit and execute Unicode JSON/file processing.
These are finite observations, not body-edit or universal latency guarantees.
Body changes/refusals/recovery are separately compared byte-for-byte with the
original compiler, including comments prefixed to shift source positions.

## Evidence and remaining work

[Integrated qualification40860864442](https://github.com/dwijayuda/pskernel/actions/runs/40860864442)
tests exact producer41d4b5db. Cold standalone commands still launch a compiler
subprocess. Warm compiler/kernel reuse is available through Linux watch and
private in-process infrastructure.

The delivery job compares .5/.6 on one runner, includes measurements and executes
the existing multi-module CLI/JSON application's Unicode-record case. Read its
COMPARISON.json and MEASUREMENTS.md. Timings are observational, not general bounds.
Profile maxRssKiB covers the parent and workers, excluding subprocesses.
The producer's watchBuild.editMs includes a later refusal test and is not isolated
rebuild latency.

The dependency-ordered queue is: remaining graph identity/metadata costs; reusable
target consumers compatible with the pinned native TypeScript7 checker; finer
dependency invalidation; cold module loading; then measured algorithmic hotspots.
No disk admission cache or general query framework is required for this milestone.
Optional maps/declarations/archives require explicit output contracts and never
replace strict target checking. Full installed qualification is manual; source
adoption reuses the exact tested tarball, without new G1/G2/G3 or a platform matrix.
