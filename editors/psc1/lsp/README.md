# @proofscript/lsp

Standalone PSC1 language server over LSP stdio. Install the delivered tarball with `npm install --global --offline --ignore-scripts ./proofscript-lsp-0.1.2.tgz` and configure your editor to run `psc1-lsp --stdio`.

Requires Node >=22.23.3. The distribution bundles the unchanged qualified `proofscript@0.1.0-psc1.12` compiler and genuine official Lean4.35.0 linear-memory Wasm checker; no Lean installation or compiler source build is needed. The qualification workflow covers Linux, native Windows, and macOS; consult the parent work-state document for exact passing runs.

Use `initializationOptions: {trusted: true, enableLean: false, debounceMs: 150, timeoutMs: 30000}` after deciding to trust the project. The default is untrusted and does not execute the compiler. `enableLean` applies only to project-backed `.lean` files explicitly opened under `proofscript-lean` or `lean`. `.ps` uses `proofscript`.

The server implements synchronization, push diagnostics, declaration hover/outline, import/declaration navigation, completion, declaration semantic tokens, lexical highlights, and open-document workspace symbols. No binding-aware rename/references, tactic goals, or term-type inference is claimed.

Custom requests:

- `psc1/infoview`: `{textDocument:{uri},position,version}` returns current status and selected declaration; old versions return ContentModified.
- `psc1/serverInfo`: installation identity, process runtime, configuration, metrics, and limitations.
- `psc1/recheck`: `{uri}` immediately checks that open file's project, bypassing only its cached analysis. Omitting `uri` requests a fresh check of all open projects.
- `psc1/configuration` notification: updates `trusted`, `enableLean`, `debounceMs`, and `timeoutMs`.
- `psc1/documentStatus` server notification: `{uri,version,projectGeneration,state,summary,diagnostics,declarations,goalsAvailable:false}` plus `snapshotVersions` (all captured file URIs mapped to open-document versions or null for saved-only sources), `cacheHit`, phase timings, `reusedKernelHealth`, and checked receipt details when available.

States are `pending`, `checking`, `checked`, `partial`, `rejected`, `error`, `unsupported`, and `untrusted`. A declaration is verified only when `verified === true` in a current result. `partial` never means a partial runtime body was proved. Clients must invalidate current status on source or imported-source changes and reject older versions/generations.

Send watched-file notifications for `.ps`, `.lean`, and `proofscript.json` changes. Open-buffer contents override the disk. Limits: 64 open source documents, 512 files and 8 MiB per project; default 30-second compiler deadline. No project configuration selects executables or plugins.

Full source and instructions: https://github.com/dwijayuda/pskernel/tree/perf/psc1-editor-checking-20261028/editors/psc1

Checking uses the existing compiler `compileCandidate()` API once, followed by the public Wasm provider handle's `checkCanonicalAdmissions()` method. The isolated worker retains verified health metadata from `createKernel()`; each new canonical graph still receives a fresh genuine Lean Wasm check. Immutable resource pins come from the qualified compiler archive and are verified before and after provider use. The receipt scope is logical admission; target execution/validation and publication are not performed. A positive result requires exact source and admissions identity. Never infer success from the absence of diagnostics.

An unchanged save re-emits the current status with `reused: true, trigger: "save"` without increasing the generation or starting another compiler job. The bounded 128-entry/16 MiB exact-source cache remaps results to newly captured document versions. Clients can validate `snapshotVersions` against every open project buffer before rendering verified markers; null entries refer to saved sources. File URI escaping is normalized for filesystem lookup while responses preserve the client's URI.

Typing uses a 150 ms default delay; opening a file and manually checking it start immediately. The triggering project goes first. A retained worker handles one immutable request at a time and is retired on cancellation, timeout, failure, 128 requests, or 30 seconds idle. The compiler still analyzes the entire declared source closure; there is no declaration-level incremental compiler cache.
