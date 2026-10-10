# Owned frontend resource boundary — implementation slice

Status: implementation under qualification; no new successful result is claimed yet.
Starting source: `81abfd94102a3628842d07de019f60e92e7b9ea4`.

## Scope and reasoning

The next narrow PSC0-ARCH/1 obligation is bounded parser/elaborator execution. The preceding checked-host milestone froze inputs and protected publication but still ran potentially CPU-intensive compiler JavaScript in the CLI process. A timer in that same event loop cannot interrupt a synchronous loop.

A single disposable **owned Node child process** now holds the unchanged installed compiler, parses import lists, elaborates captured source texts and retains the existing `createCheckedPreparedSession` prepared graph. The parent retains source/package snapshots, selected-kernel invocation, TypeScript invocation and the only output-publication path. No arbitrary extension loading is introduced.

The child loads only the compiler resolved relative to the trusted installed worker and verifies its SHA-256 before and after loading. Prepared terms (including their generated Symbol tags) never cross a serialization boundary. Only source strings, canonical admissions, checking decisions and target-source strings cross private, ordered, length-bounded JSON pipes. The parent calls its existing pinned JS kernel and binds accepted admission bytes; copied JSON facts cannot mint a parent-local checked handle.

The worker is stopped and reaped before publication. A timeout, malformed response, duplicate/stale identity, failed kernel, cancelled request or worker exit permanently invalidates the session; there is no automatic restart, alternative checker or unchecked in-process fallback. Worker code is not given an output destination or public write operation. Host installation and OS remain trusted.

## Resource semantics

Default frontend request budget: **300,000 milliseconds accumulated across requests**, including compiler startup, parsing, preparation, checking handshake and emission. Default V8 old-space setting: **4,096 MiB**. Only explicit host-call/CLI resource settings may change these values; imported project libraries cannot raise them. They change permitted resources, not proof rules or accepted-byte binding. Larger explicit budgets preserve a route for intentional long compiler development builds; routine CI never requests a full self-host cycle.

Frames are bounded at **64 MiB before UTF-8 decoding/JSON parsing**; stderr at **64 KiB**; total requests at **4,096**. Existing source-graph and kernel bounds remain. The memory setting limits V8 old space, **not total resident memory**, native allocations or system resources. Parent source IO, kernel/tsc invocations and filesystem publication retain their own limits and trust assumptions. A separate process is not an OS capability sandbox for malicious plugin code.

## Ownership

- `frontend-wire.mjs`: shared bounded byte framing.
- `frontend-transport.mjs`: private child lifecycle, monotonic time budget, bounded diagnostics and strict response order.
- `frontend-worker.mjs`: compiler-only dispatch using the original shared checked-session implementation; no kernel selection or publication.
- `frontend-session.mjs`: host-local handle ownership and accepted-admission binding.
- `source-graph.mjs`: owns source snapshots, delegating only import parsing to the worker.
- `build.mjs`: uses the session, closes the child before publishing, keeps the existing JS kernel and TypeScript identity policy.

No portable `.lean`/`.ps` compiler code, kernel implementation, kernel adapter, language, seed or toolchain pin changes. Qualification reuses the retained compiler artifact, source-identity guard, whole installed compiler-closure scan and bounded PS/Lean smoke checks. No C2/C3 generation or kernel regeneration is part of this slice.

## Research basis and explicit limits

Node documents that child processes have separate memory/V8 instances and asynchronous spawning permits the parent event loop to continue. Its `kill()` API sends a signal; this implementation requests `SIGKILL`, not a catchable cooperative shutdown, and reaps the owned child before release. Node worker-thread resource limits affect that JS engine, do not include all external allocation, and a global out-of-memory condition can still terminate the process; therefore an owned child is the more suitable boundary here.

Primary references: Node [child processes](https://nodejs.org/api/child_process.html), [worker thread limits](https://nodejs.org/api/worker_threads.html), [process signals](https://nodejs.org/api/process.html). Only APIs available in the pinned Node22/26 test matrix are used. Neither these APIs nor finite CI tests prove kernel soundness, semantic preservation or arbitrary-extension isolation.
