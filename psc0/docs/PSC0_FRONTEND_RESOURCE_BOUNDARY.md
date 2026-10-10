# Owned frontend resource boundary — qualified implementation slice

**Qualified source:** `29c2d611a39d7c3187b1b8d333e5d023090bba9f`.
**Starting source:** `81abfd94102a3628842d07de019f60e92e7b9ea4`.
**Successful run:** [38083824580](https://github.com/dwijayuda/pskernel/actions/runs/38083824580), Linux/Node22.23.3 and Windows/Node26.7.0.

Both platforms passed all50 host tests, source preservation, 23-workspace validation, retained-runtime offline installation and both PS/Lean installed compiler/library checks. New bounded correspondence tests verified exact direct/worker admissions and emitted TypeScript equality, actual selected-kernel admission, refusal of copied/closed handles, and timeout preserving prior output. [Machine evidence](PSC0_FRONTEND_RESOURCE_QUALIFICATION.json) and [AI work state](../AI_WORK_STATE.md) bind exact identities. No full compiler or kernel regeneration took place.

## Scope and reasoning

This narrow PSC0-ARCH/1 step bounds parser/elaborator execution. The preceding checked-host milestone froze inputs and protected publication but still ran potentially CPU-intensive compiler JavaScript in the CLI process. A timer in that same event loop cannot interrupt a synchronous loop.

A single disposable **owned Node child process** now holds the unchanged installed compiler, parses import lists, elaborates captured source texts and retains the existing `createCheckedPreparedSession` prepared graph. The parent retains source/package snapshots, selected-kernel invocation, TypeScript invocation and the only output-publication path. No arbitrary extension loading is introduced.

The child loads only the compiler resolved relative to the trusted installed worker and verifies its SHA-256 before and after loading. Prepared terms (including their generated Symbol tags) never cross serialization. Only source strings, canonical admissions, checking decisions and target-source strings cross private, ordered, length-bounded JSON pipes. The parent calls its existing pinned JS kernel and binds accepted admission bytes; copied JSON facts cannot mint a parent-local checked handle.

The worker is stopped and reaped before publication. A timeout, malformed response, duplicate/stale identity, failed kernel, cancelled request or worker exit permanently invalidates the session; no automatic restart, alternative checker or unchecked in-process fallback exists. Worker code is not given an output destination or public write operation. Host installation and OS remain trusted.

## Resource semantics

Default frontend request budget: **300000 milliseconds accumulated across requests**, including compiler startup, parsing, preparation, kernel handshake and emission. Default V8 old-space setting: **4096 MiB**. Explicit host-call/CLI resource settings can change these finite values; imported libraries cannot. They affect resources, not proof rules or accepted-byte binding. Larger explicit budgets retain a route for intentional long compiler development builds; routine CI never requests a full self-host cycle.

```
psc build Main.ps --frontend-timeout-ms 300000 --frontend-heap-mb 4096
```

These options apply to a build/install of this branch, not previously distributed ZIPs. No replacement public ZIP or npm publication is claimed by this milestone.

Frames are bounded at **64 MiB before UTF-8 decoding/JSON parsing**; stderr at **64 KiB**; total requests at **4096**. Existing source-graph and kernel bounds remain. Old-space limits are **not total resident memory** or OS resource quotas. The request timer is not a whole-build filesystem/TypeScript/publication deadline. While the parent runs the separately bounded kernel callback, the owned worker waits for its decision. Abrupt OS termination and complete descendant-process containment are not guaranteed by this protocol.

A separate owned process is not an OS capability sandbox for malicious plugin code. It has the installation's normal OS privileges; no arbitrary executable plugin may be promoted into this worker. Public release authentication, arbitrary guest isolation and complete formal semantics remain separate work.

## Ownership

- `frontend-wire.mjs`: shared bounded byte framing.
- `frontend-transport.mjs`: private child lifecycle, monotonic request budget, bounded diagnostics and strict response order.
- `frontend-worker.mjs`: compiler-only dispatch using the original shared checked-session implementation; no kernel selection or publication.
- `frontend-session.mjs`: host-local handle ownership and accepted-admission binding.
- `source-graph.mjs`: owns source snapshots, delegating only import parsing asynchronously.
- `build.mjs`: uses that session, closes the child before publication, keeps the selected JS kernel and TypeScript policy.

No portable compiler, kernel source/adapter, language, seed or toolchain pin changed. The inherited69 compiler files and64-module bootstrap closure remain identical. Bounded correspondence does not establish universal equivalence or a fresh C2/C3 fixed point. Net production growth was275 physical host lines; no additional npm dependency was introduced.

## Research basis

Node documents asynchronous child spawning and separate process/V8 instances. This implementation requests `SIGKILL`, not a catchable cooperative shutdown, and reaps the owned child before release. Worker-thread engine limits do not include all external allocation and global out-of-memory can still terminate the parent process; an owned child is the more suitable boundary here.

Primary sources: Node [child processes](https://nodejs.org/api/child_process.html), [worker thread limits](https://nodejs.org/api/worker_threads.html), [process signals](https://nodejs.org/api/process.html). Only APIs available in the pinned Node22/26 matrix are used. These APIs and finite CI tests are not a theorem of kernel soundness, target semantic preservation or hostile-extension security.
