# PSC0 platform implementation

## Current result: preview2 is qualified

The protected npm preview now includes **psc init**, project entry/output defaults, three runnable example directories, and a separately installed **psdev** one-shot command demo. An independently named **@psc-demo/pshello** package exercises the same extension boundary.

Qualified source: [e5c4a561b98ed9e2ae96c7da3f85ed6d844bf1d1](https://github.com/dwijayuda/pskernel/commit/e5c4a561b98ed9e2ae96c7da3f85ed6d844bf1d1), tree d2baf328fbd3aab84335352c35a719f179da09cc. [Run 37998655835](https://github.com/dwijayuda/pskernel/actions/runs/37998655835), attempt 1, passed all six jobs. It ran from 2026-10-09 22:20:19 UTC to the final successful update at 22:22:35 UTC, or 10 October 2026, 05:20–05:22 Asia/Jakarta.

This implements the requested onboarding/examples/command-demo slice. It does not finish the architecture plan, full psdev watch, T1 module/export and checked ABI, general language plugins, LSP or the formal-assurance program. The containing follow-up records evidence and documentation only; the qualified package source stays at e5c4a561.

The work remains on psc0/platform-v1 in [draft PR90](https://github.com/dwijayuda/pskernel/pull/90). Main was read at ed5d00aca0743bde583b45fe7756dd494ac3960f and was not changed. Nothing was published to npm.

## Download and install

Download the [preview2 candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/37998655835/artifacts/11648008841). It contains these three tarballs:

| Archive inside the artifact | Bytes | SHA256 |
| --- | ---: | --- |
| platform/proofscript-0.1.0-preview.2.tgz | 3,639,614 | 9ceab476924c39f73cc6fd8fe4a92b91228b03455d3ff6e0c56e17bf075842d9 |
| platform/psdev-0.1.0-preview.2.tgz | 1,791 | e3cd851c66a899e7d4fb4503becaab33df5e5b2db4ca71a51bc5b2ad67a46468 |
| platform/psc-demo-pshello-0.1.0-preview.2.tgz | 1,805 | 07aadc3b41f007cee0eb6cfc92f9d41d5ba52bfe77083ced1c8edd1c6c80a95c |

The product archive size excludes separately installed TypeScript dependencies. It is 14,538 bytes larger than preview1 and introduces no new required npm dependency. The candidate ZIP has 3,858,799 bytes and SHA256 065d0652d8aa28077ad8f7e17eb2503e6ea139fed03b0d398a4ce793545e37e7. Archive and inner-tarball hashes are different identities.

The Actions artifact expires at 2026-11-08 22:21:28 UTC, which is **9 November 2026, 05:21:28 Asia/Jakarta**. Keep the downloaded candidate if you need it beyond that time. Committed JSON retains evidence, not executable archive bytes.

From the extracted candidate directory in Windows PowerShell:

```powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.2.tgz"
psc.cmd version --json
psc.cmd init my-app
Set-Location my-app
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.2.tgz"
npm run check
npm run build
```

The global compiler provides a convenient initial command. The second installation pins the compiler in the new project so its generated scripts can use the explicit local launcher. Since this preview is unpublished, installing the local candidate is necessary before those npm scripts run; a global install alone does not satisfy the generated local dependency.

Linux users use psc and an absolute tarball path. Windows qualification uses npm's psc.cmd from PowerShell 7.6.6. Bare psc can resolve to psc.ps1 and depends on local execution policy; no policy bypass was used.

The full consumer guide is [release/README.md](release/README.md). The initializer also creates PROOFSCRIPT.md in the user project. Ordinary future registry installation remains npm install -g proofscript after an intentional public release; that command does not select this unpublished candidate.

## What changed

| Feature | Implemented behavior |
| --- | --- |
| psc init [directory] | Create package.json, src/Main.ps and PROOFSCRIPT.md for a new/empty directory; add only source and guide to an existing npm project. |
| Root defaults | package.json proofscript.entry and proofscript.out allow check/build/dev without repeated file arguments. |
| Neighboring default | An explicit entry without --out produces its neighboring .ts file and checked receipt. |
| psc examples | List installed checked-nat, existing-typescript and rejected-source example directories. |
| psc extensions | Resolve explicitly configured command package data; report configured identities with no guest execution. |
| psc dev --once | Run one enabled command guest, then honor its bounded request through the existing protected checked build. |
| Third-party package | @psc-demo/pshello uses the same protocol, resolver, validation, grants and disclosure as psdev. |
| Receipts | A dev build's saved receipt includes the exact completed extension record, and publication rechecks its captured inputs. |

Init executes no npm or project code. It preserves existing package.json, tsconfig.json, unrelated source, scripts and dependencies. Starter/output collisions are preflight refusals; writes create only absent files. Symlink/junction ancestors and ambiguous Windows path forms are refused. A partial I/O failure reports already-created starter files rather than claiming atomic creation. Suggested existing-project package additions are data in the guide and JSON result.

Project configuration uses package.json only; no competing proofscript.json was added. Configured paths are relative to the root and use forward slashes. Absolute, escaping and Windows drive-relative paths such as D:other.ts are rejected. Explicit CLI paths remain intentional user selections subject to the existing source-containment/output-ownership checks.

An implicit entry uses the configured root entry and output. An explicit source with no explicit output gets its own neighboring TS path; it does not accidentally reuse another entry's configured bundle. The CLI preserves caller cwd and never silently imports or switches to a local/global replacement compiler.

### Examples

There are eleven shipped example files, including a README in each example directory.

- [checked-nat](examples/platform/checked-nat/README.md) uses def answer : Nat := 42, the supported checked profile and local build scripts.
- [existing-typescript](examples/platform/existing-typescript/README.md) imports the generated answer as bigint under ES2022/NodeNext and executes it from handwritten TS.
- [rejected-source](examples/platform/rejected-source/README.md) gives answer the invalid value Type, exercising refusal and preservation of the previous completed output.

These are one-bundle examples. They do not claim cross-file datatype/runtime identity, inbound Nat argument validation, arbitrary FFI or separately compiled module compatibility. Copy examples into a user project before building; psc examples itself performs no code execution or file generation.

## Try the optional psdev demo

Within the initialized project, using the candidate variable established above:

```powershell
npm install --save-dev --save-exact --ignore-scripts "$candidate\psdev-0.1.0-preview.2.tgz"
npm pkg set 'proofscript.extensions[0].package=psdev' 'proofscript.extensions[0].enable[0]=command:dev'
node .\node_modules\proofscript\bin\psc.mjs extensions --json
node .\node_modules\proofscript\bin\psc.mjs dev --once --json
```

The npm pkg set shorthand uses npm's documented nested-object/array syntax and changes only the indicated configuration entries. [npm package editing reference](https://docs.npmjs.com/cli/v12/commands/npm-pkg/). The resulting configuration is:

```json
{
  "proofscript": {
    "profile": "checked",
    "entry": "src/Main.ps",
    "out": "src/Main.ts",
    "extensions": [
      { "package": "psdev", "enable": ["command:dev"] }
    ]
  }
}
```

Keep the existing package's other fields. The demo must be physically installed as a direct root npm dependency with its lockfile; installation alone does not activate it. The generated new project's compiler dependency must be installed from the product candidate first, as shown above, so npm does not attempt to fetch an unpublished version from the registry.

The result has command, extensions and receipt. src/Main.checked.json contains the same executed extension record. The guest can request one normal checked build; it cannot change entry/output paths or the assurance profile. A guest that declines, traps, times out or returns an unsupported value cannot authorize publication.

To try independent naming, install psc-demo-pshello-0.1.0-preview.2.tgz locally and replace the single configured package with @psc-demo/pshello. Then run dev --once again. This fixture demonstrates equal treatment of an independently named package; it is not a claim that the npm scope is owned or published. Neither demo is part of proofscript's required dependency closure. There is no publisher-name allowlist for this constrained protocol.

Only one provider of command:dev may be enabled. npm aliases, directory links, workspace/ancestor/global package search, floating version ranges and automatic downloads are outside this first resolver. Actual root package, lockfile, installed metadata, descriptor, module and engine identities are reported. The recorded npm SHA512 integrity is archive provenance, not a proof that the installed package tree still equals the archive. Editing a descriptor and module together before selection can select a different permitted module; its actual digest is disclosed and the same confinement checks apply.

## Protected extension and compilation boundaries

The [command SDK](docs/platform/command-extension-sdk.md) specifies the exact package shape and host API. Its essential boundary is deliberately small:

| Component | Authority |
| --- | --- |
| Command package | Supplies a 4 KiB maximum restricted Wasm module. Receives initial integer 0 and returns integer 0 or 1. |
| command-wasm-profile.mjs | Bounds binary structure and rejects imports, memory, tables, globals, starts, calls, references/GC and unsupported opcodes. |
| command-extension-worker.mjs | Fixed trusted adapter; validates/instantiates those bytes with V8 and no imports. No npm JavaScript is loaded. |
| command-extensions.mjs | Owns resolution, captured identities, private selections/completions, bounded execution and state records. |
| bin/psc.mjs | Owns activation, official disclosure, caller-selected files, fixed checked profile and invoking the protected build. |
| checked-build.mjs | Performs the unchanged admission/IR/TS checks, supplies actual extension provenance, rechecks eligibility and requests owned publication. |

The supplied module is 44 bytes, with SHA256 63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279. Both demo names deliberately use those same bytes. There is no new dependency or WAT compiler in ordinary installation.

The guest has no filesystem, network, process, environment, terminal, source, kernel, admission or publication capability. Its one integer cannot contain a proof, receipt, target path or arbitrary diagnostic. Only the host serializes PSC_EXTENSIONS records; it does so before execution and records attempted/instantiated/completed or failed state. Empty imports in those records describe the granted import policy. A failed worker with unacknowledged instantiation reports unknown status as null.

WebAssembly is the confinement boundary; the worker provides cancellation and a two-second parent wall deadline. It is not a general JavaScript sandbox or an OS boundary. Node/V8 and the small adapter/decoder remain implementation assumptions. The profile forbids guest memory and calls and limits locals/control nesting; Node worker heap limits do not establish a hard process-RSS or availability bound. This is not deterministic fuel, an engine-security proof or a side-channel guarantee. See [WebAssembly security](https://webassembly.org/docs/security/) and [Node worker limits](https://nodejs.org/download/release/v22.23.3/docs/api/worker_threads.html).

Completed command requests are private host-owned objects, not serializable guest capabilities. The builder rejects forged or declined results before loading the compiler. It rechecks root package, lockfile, package metadata, descriptor and module identities at build entry and through the existing publication eligibility callbacks. Altered or stale inputs cannot be represented as the current successful dev generation. An arbitrary local process that can replace the host installation remains outside this guest-confinement claim.

Ordinary check/build validate the root configuration but do not load command guests. extensions only inspects package data. The release's default extension list remains empty; no default watcher, server, prover or updater is started. A later release can adopt ready tooling explicitly, with its own default metadata and qualification.

### The checked path is preserved

The public host authenticates the exact F compiler bytes, reads an immutable source snapshot, admits canonical declarations through the pinned native Core provider, and emits only after validating the same original RuntimeIR. TypeScript 7.0.2 validates staged output before publication.

The publisher retains its existing ownership/lease/staging/recovery protocol. It refuses unowned or manually edited output, checks eligibility before publication and before receipt commitment, and writes the new receipt last. Rejected work preserves the last completed generation. It does not provide atomic multi-file visibility to arbitrary watchers or prove power-loss durability.

The guest can neither replace this path nor supply its successful result. Native provider algorithms, compiler algorithms and validators were not modified to support the demo.

## Exact qualification

| Source qualification | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| Linux22 host, init, CLI, extension, publication, assembly and smoke harness | 116 | 0 | 0 |
| Linux22 actual compiler/native integration | 17 | 0 | 0 |
| Windows26 host, init, CLI, extension, publication, assembly and smoke harness | 120 | 0 | 1 |
| Windows26 actual compiler/native integration | 14 | 0 | 3 |

The eighteen focused command-extension tests run within both host suites. They exercise genuine valid-Wasm import/memory fixtures being refused, other denied features/bounds, infinite-loop termination, cancellation, traps, invalid replies, opaque completions, stale metadata and compulsory disclosure. No failure was waived or acceptance gate weakened.

The Windows skips are inherited fixtures: one Unix directory-write-permission cleanup test and three POSIX-shebang fake transport tests. The actual Windows native provider/compiler tests and all new initializer/extension tests are mandatory and passed.

| Fresh installed job | npm | Passed observations |
| --- | --- | ---: |
| Linux / Node22.23.3 | 10.9.9 | 39 |
| Linux / Node26.7.0 | 12.0.2 | 39 |
| Windows / Node22.23.3 | 10.9.9 | 37 |
| Windows / Node26.7.0 | 12.0.2 | 37 |

All four jobs installed the same three exact tarballs. They had no source checkout or Lean installation and ran through a Node-only PATH. Windows used PowerShell7.6.6 and npm's actual psc.cmd. The tested Windows image is Windows Server2022, win22/20261004.326.1; Linux is Ubuntu24.04, ubuntu24/20261004.327.1.

The 152 installed observations cover initialization/default paths/examples, unchanged existing project files, native admission, checked neighboring TS, an ordinary changed rebuild, invalid-source preservation, both optional package installations and explicit activation, JavaScript entrypoint nonexecution, actual identity/disclosure/receipt binding, TypeScript consumer results 44/45 after guest-requested builds, tampered payload refusal and explicit unavailable-PSCV refusal. Linux additionally retains ELF library/interpreter/version inspection. Windows verifies the provider's twelve previously qualified system DLL imports. These are execution observations on the stated environments, not a theorem for every OS release, filesystem or shell policy.

Evidence is committed in:

- [Aggregate run, artifact and scope record](docs/platform/onboarding-command-preview-qualification-2026-10-09.json).
- [Windows26 installed result](docs/platform/installed-win32-node26.7.0-37998655835.json).
- [Windows22 installed result](docs/platform/installed-win32-node22.23.3-37998655835.json).
- [Linux26 installed result](docs/platform/installed-linux-node26.7.0-37998655835.json).
- [Linux22 installed result](docs/platform/installed-linux-node22.23.3-37998655835.json).

The implementation diff from 3a0d056 to e5c4a561 contains 40 files, 2,147 added lines and 199 deleted lines, including tests, examples, package data and documentation. The assembled product uses 21 maintained host files and 11 example files, one compiler and two platform-native artifacts. Its only required npm dependency remains TypeScript7.0.2. These counts are measured implementation scope, not a formal TCB-size or proof-cost claim.

## Self-host, native payloads and proof scope

The compiler's 61 raw portable source modules remain unchanged. Their closure SHA256 is 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7. F source remains fcd875c8f38db4b0524090bd10c7c2fd5024053d; its JavaScript remains 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15. [F fixed-point run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800) remains the applicable compiler evidence; no redundant C1/C2/C3 qualification was run for these host-only changes.

The selected authoring seed R remains fe2560aba0f347b1caf8d000d371464642d44f23. Bootstrap stays Node22.23.3/Lean4.34.0/TypeScript7.0.2. Consumer Node26 qualification does not claim a new Node26 bootstrap fixed point. Init, npm/OS adapters and optional command packages are outside the compiler's self-host import graph.

Native Core source remains 963030dc2d154008fccc82e7c8ed29331f138799: repository tree 80927150cbd6a5518762b4cc56e51ea24df8f374, psc0 subtree 38c8c55bd2b214753e56c58c15c4901c32c01b86. Linux binary SHA256 remains 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec; Windows remains 8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2. The previous [Windows native probe](https://github.com/dwijayuda/pskernel/actions/runs/37993071033) remains its artifact qualification. Separate Lean4.35 Arena work has a different protocol and is not substituted.

The Windows PE contains its ordinary link timestamp 1791581097. Its current recipe does not promise byte-identical later rebuilds. Exact F and Windows inputs are retained Actions artifacts; durable nonexpiring input retention and clean release recovery remain public-release work. Existing selected-R recovery evidence is preserved. No timestamp patch, invented replacement hash, seed promotion or kernel change was made.

Formal assurance remains a later gate, with psc0/proofs/**/*.proof.lean and full Lean tooling outside bootstrap. No new compiler/kernel theorem is claimed. The existing false receipt flags remain semanticPreservationProved, pscvVerified and strictSh1Qualified. Kernel acceptance does not establish logical consistency; RuntimeIR typing and TS7 acceptance do not prove executable semantic preservation.

For this extension slice, later proofs should concentrate on the restricted decoder, exclusive status/request authority, captured-input freshness and composition with the checked publication state machine. A pure scheduling function need not itself be proved when all it can request is an already checked host action. Refinement to Node/V8/OS behavior still requires explicit assumptions; a Lean state-machine proof alone would not verify the engine.

## Next milestones

1. Complete T1 source ownership/export mapping, one canonical runtime identity and the bounded checked TS ABI before full project watch or neighboring facades.
2. Develop real psdev scheduling, cancellation/invalidation/recovery and coherent downstream build coordination against that interface. The present --once demo proves the extension route is usable, not that T2 is finished.
3. Expand producer/validator extension protocols only for concrete macro/tactic/backend needs, with appropriate resource and admission contracts. A richer Wasm/Wasmtime or native compatibility profile earns separate qualification.
4. Add workspace/hoisting and ordinary ProofScript library resolution, deliberate default-package activation, final ps-prefixed source/package boundaries and durable release inputs.
5. Build pslsp and the VS Code client outside bootstrap, with analysis snapshots distinct from publishable accepted generations.
6. Continue mathematical/implementation proofs in their separate assurance workspace without making full proof completion an implementation-closing gate.

The accepted [architecture plan](PSC0_ARCHITECTURE_PLAN.md) retains its dated repository research and the complete proposed direction. Historical Linux-only preview0 and Windows preview1 records remain in Git history and docs/platform; this page describes preview2.
