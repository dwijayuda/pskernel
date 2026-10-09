# PSC0 platform implementation status

**Milestone:** protected compilation and installable npm preview, qualified on 9 October 2026 UTC (10 October in Asia/Jakarta).

**Scope:** this is the first usable implementation milestone of [PSC0_ARCHITECTURE_PLAN.md](PSC0_ARCHITECTURE_PLAN.md). It does **not** complete all phases 0–4 of that plan. Isolated extension execution, stable extension/primitive contracts, the final ps-prefixed package split, npm library imports and the complete T1 module/ABI work remain open.

**Working branch:** `psc0/platform-v1`. **Review:** [draft PR90](https://github.com/dwijayuda/pskernel/pull/90), based on the architecture-plan branch. Main was read back unchanged at `ed5d00aca0743bde583b45fe7756dd494ac3960f`. No package was published to npm.

## Qualified result

The exact executable/package source is [3fd25db1bbd8d508252682fd0efe5a948a5ea5fd](https://github.com/dwijayuda/pskernel/commit/3fd25db1bbd8d508252682fd0efe5a948a5ea5fd), tree `7c606d0b6910fdd04250a5d1c7a58aa800f47d43`.

[Run 37993872945](https://github.com/dwijayuda/pskernel/actions/runs/37993872945), attempt 1, passed **all six jobs**. GitHub recorded the completed successful run at **2026-10-09 21:32:52 UTC**.

| Source qualification | Host/session/publication/CLI/assembly/smoke-harness tests | Actual native-provider and compiler integration |
| --- | --- | --- |
| Ubuntu 24.04 x64, Node 22.23.3 | 84 passed; 0 failed; 0 skipped | 17 passed; 0 failed; 0 skipped |
| Windows Server 2022 x64, Node 26.7.0 | 87 passed; 0 failed; 1 skipped | 14 passed; 0 failed; 3 skipped |

The Windows host skip is the existing Unix directory-permission cleanup fixture; Unix permission bits do not model Windows ACLs. The three transport skips use POSIX shebang executables. The actual pinned Windows provider and compiler integration are mandatory and passed. Windows-specific device/stream rejection, path casing, spaces/Unicode, linked-source escape, source-byte preservation, publication and rollback cases ran.

Both source jobs also passed the preparation boundary guard. The exact F compiler bytes and all **61 raw source modules** still match the existing qualified closure.

| Fresh installed-package qualification | npm | Observations | Result |
| --- | --- | --- | --- |
| Windows x64, Node 26.7.0 | 12.0.2 | 13 | Passed |
| Windows x64, Node 22.23.3 | 10.9.9 | 13 | Passed |
| Linux x64, Node 26.7.0 | 12.0.2 | 15 | Passed |
| Linux x64, Node 22.23.3 | 10.9.9 | 15 | Passed |

All four jobs installed **the same tarball** globally with lifecycle scripts disabled. They checked and compiled source, imported the neighboring generated TypeScript into an existing TS project, executed the result, replaced a valid build from `42` to `43`, and preserved the completed output when a later build was rejected. Requested PSCV failed explicitly.

The installed jobs performed no source checkout or Lean installation. Runtime PATH contained only a dedicated Node executable. Windows used npm's actual **`psc.cmd`** through PowerShell **7.6.6**; bare `psc` can resolve `psc.ps1` and depends on the user's shell policy. The tested Windows image was **win22/20261004.326.1**, Windows Server 2022 **10.0.20348**. The tested Linux image was **ubuntu24/20261004.327.1**, Ubuntu 24.04. This is not qualification of every Windows version, Linux distribution, filesystem or shell policy.

The exact results and artifact metadata are retained in:

- [windows-preview-qualification-2026-10-09.json](docs/platform/windows-preview-qualification-2026-10-09.json)
- [Windows Node26/npm12 installed result](docs/platform/installed-win32-node26.7.0-37993872945.json)
- [Windows Node22 installed result](docs/platform/installed-win32-node22.23.3-37993872945.json)
- [Linux Node26 installed result](docs/platform/installed-linux-node26.7.0-37993872945.json)
- [Linux Node22 installed result](docs/platform/installed-linux-node22.23.3-37993872945.json)

The earlier Linux-only preview0 qualified at `48be48c0fd91407ca531692be2a3bd8bc24b058b` in [run 37990210503](https://github.com/dwijayuda/pskernel/actions/runs/37990210503). Its [original qualification](docs/platform/qualification-2026-10-09.json) and [installed result](docs/platform/installed-package-qualification.json) remain unchanged historical evidence. Preview1 fixes the Windows installation limitation; it does not replace or re-prove the compiler fixed point.

## Try the tested npm preview

Download the [preview1 candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/37993872945/artifacts/11646426537). After extracting it, the package is `platform/proofscript-0.1.0-preview.1.tgz`.

In Windows PowerShell, from the extracted candidate directory:

```powershell
npm install --global --ignore-scripts ".\platform\proofscript-0.1.0-preview.1.tgz"
psc.cmd version --json
psc.cmd extensions --json
```

Use this new archive with Node 26.7.0/npm 12.0.2 or Node 22.23.3/npm 10.9.9. The old preview0 archive remains Linux-only; overriding its npm platform guard cannot supply a Windows executable.

On Linux:

```sh
npm install --global --ignore-scripts ./platform/proofscript-0.1.0-preview.1.tgz
psc version --json
psc extensions --json
```

The tarball is **3,625,076 bytes**, approximately **3.63 MB**, excluding separately installed npm dependencies. Its SHA-256, independently reported by all four installed jobs, is:

```text
77b0d6c596c8b77af99b4676ce998d58d713b5596762eef928ed284018449ba0
```

The [Windows Node26 installed evidence artifact](https://github.com/dwijayuda/pskernel/actions/runs/37993872945/artifacts/11646800613) contains the complete checked-build receipt and native import report. All five artifacts from this run expire on **8 November 2026**. The committed JSON preserves evidence and identities, not a permanent copy of executable archives.

`npm install --global proofscript` selects the package currently in the registry. This preview has **not** been published there. Use the exact tarball above.

### Existing TypeScript project example

Create `src/Main.ps` using the supported bounded grammar:

```text
def answer : Nat := 42
```

From that project's directory on Windows:

```powershell
psc.cmd check .\src\Main.ps
psc.cmd build .\src\Main.ps --out .\src\Main.ts --json
```

On Linux, use `psc` with the same arguments. The commands below use that spelling.

The second command creates `src/Main.ts` and `src/Main.checked.json`. It publishes no neighboring JavaScript or declaration file for a requested `.ts` output. Existing handwritten TypeScript can import the generated module:

```ts
import { answer } from './Main.js';

const result: bigint = answer;
```

This exact pattern was typechecked with TypeScript 7.0.2 using NodeNext module settings and executed successfully. The tested Nat constant evaluates to `42n`.

The compiler currently emits **one bundle for the entry's source closure**. Choosing a neighboring output path does not implement per-source module facades, shared datatype identities across separately compiled bundles, general FFI, arbitrary module cycles, or live watching. Those remain the T1/T2/T4 work described in the architecture plan.

For a JavaScript bundle and its sidecars:

```sh
psc build src/Main.ps --out dist/Main.js --json
```

This publishes TS, JS, declarations, the JS source map, canonical admissions and a completion receipt.

## What changed and why

### One protected public build path

The public launcher [bin/psc.mjs](bin/psc.mjs) uses release-owned runtime paths and compiler identity. Its build reaches [checked-build.mjs](scripts/checked-build.mjs), which:

1. Authenticates and imports the same generated-compiler bytes.
2. Captures the ordered source closure and prepares it.
3. Checks canonical admissions through the exact native PSKernel Core provider.
4. Uses the existing checked backend entry to check and emit the same original RuntimeIR.
5. Compiles staged TypeScript with the required TS7.0.2 settings.
6. Rechecks known source changes and publishes only through the owned-output transaction.

The prior raw-emitter route in `compile-with-generated.mjs` is replaced by a thin adapter to this path. Repository CLI build/check operations also use it. Internal historical/bootstrap harnesses retain their own explicit evidence scopes; this milestone does not retroactively change how old fixed-point artifacts were produced.

The immutable session has no raw-emitter fallback. A native seed's old admission-only/raw-emission protocol is refused for protected emission. The public npm launcher exposes no alternate compiler, kernel or TypeScript override.

### The kernel name now identifies the actual provider

The protected `pskernel-core` selector points to the qualified **native Core 4.34** provider at source `963030dc2d154008fccc82e7c8ed29331f138799`. Its binary is checked before execution and again before the decision is retained. The descriptor records the canonical input digest and actual executable identity.

The provider implementation and contract are unchanged. The transport now runs the native child from the release-owned provider directory, and the host selects a platform-specific fixed executable hash. The Windows artifact is a PE32+ x64 executable; the Linux artifact remains the existing ELF x64 executable. The old generated-owned provider is retained for historical/development comparisons, not silently selected under the protected Core name. The separate 4.35 Arena lane has a different protocol and remains independent.

The Windows provider source was cold-built and exercised separately in [run 37993071033](https://github.com/dwijayuda/pskernel/actions/runs/37993071033). Its executable SHA-256 is `8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2`. The package does not carry Lean, MinGW or Visual C++ redistributable DLLs. The twelve observed Windows OS imports remain platform assumptions; the PE inventory is not a proof about arbitrary dynamic library loading.

Provider source metadata now explicitly distinguishes repository tree `80927150cbd6a5518762b4cc56e51ea24df8f374` from its `psc0` subtree `38c8c55bd2b214753e56c58c15c4901c32c01b86`. The latter was the historical `sourceTree` field; `sourceTreePath: "psc0"` now makes that scope explicit.

### Output ownership and completion are explicit

[checked-artifact-publication.mjs](scripts/checked-artifact-publication.mjs) rejects existing unowned output and manually edited generated output. An output-directory lease coordinates cooperating publishers, including different stems whose sidecars overlap.

Windows output paths are checked before compiler loading and target staging, and again at publication. Device basenames, alternate data streams, ambiguous trailing-dot/space components and non-filesystem namespaces are refused. Ordinary spaces, Unicode and native path casing remain supported. UNC/extended-root syntax tests do not claim network-share filesystem qualification.

Private staging and a journal precede visible changes. The publisher checks the source eligibility callback before publication and again before receipt commitment. It then rechecks its lease, receipt absence, all candidate artifact bytes and retirement of obsolete owned files. The new receipt rename is the commit point.

Handled failures restore only bytes attributable to the failed transaction. Conflicting user changes are preserved. Incomplete rollback retains the lock, journal and backups and reports recovery-required status. Cleanup failure after commitment reports `PSC0_OUTPUT_COMMITTED_CLEANUP_REQUIRED` without rolling back valid new output.

This is a completion protocol for cooperating consumers. It does not make multiple file renames appear atomic to independent `tsc`/Vite watchers, prove power-loss durability, or prevent an arbitrary process with filesystem authority from racing the supervisor. Automatic crash recovery and coordinated watching are later tooling work.

### The release stays small and explicit

[assemble-release.mjs](scripts/assemble-release.mjs) copies an explicit **17-file maintained host closure**, the exact generated compiler, both exact native providers, and release metadata. It excludes tests, proofs, the legacy trees, optional provider packages and the Lean development toolchain. The grammar profile constant is separated from the large conformance test it previously imported.

The one package contains both small native artifacts instead of introducing a platform-package loader. Its release profile refuses additional native DLL declarations because neither qualified provider needs bundled DLLs. The release has one exact TypeScript runtime dependency and no package lifecycle scripts. Five independently published npm packages are not created in this first slice. The future `pskernel-core`, `pscore`, `psfrontend`, `psc`, and `psbackend-ts` boundaries remain the accepted target; their compiler functionality currently ships as a bundled runtime plus the host.

The host continues the existing Node `.mjs` implementation style. The portable compiler remains the existing supported Lean/ProofScript implementation. This milestone does not rename its twelve source groups or claim that the compiler has been rewritten in TypeScript.

## Meaning of check, build and proof

| Command or evidence | Actual claim |
| --- | --- |
| `psc check` | Canonical declarations were accepted by the pinned kernel provider for this source snapshot. RuntimeIR checking is explicitly not requested. |
| `psc build` | Admission succeeded; the current RuntimeIR checker accepted and completed; that same IR was emitted; TS7 accepted the staged TS; publication completed. |
| Checked-build receipt | Audit bindings among source, runtime identities, admissions, checks and artifact hashes. It is not a portable proof capability. |
| Existing F fixed point | Reproducibility evidence for its exact source, seed, toolchain and generated products. |
| This platform qualification | Focused execution and refusal evidence for this host/package implementation on the stated machine. |

The receipts explicitly keep `semanticPreservationProved`, `pscvVerified`, and `strictSh1Qualified` false. Kernel acceptance does not establish logical consistency; IR typing does not prove erasure/backend semantic preservation; TS7 typechecking does not prove correctness of emitted JavaScript.

The only supported project policy is `profile: "checked"` with an empty external-extension list. Unsupported profile names, verification configuration, commands and requested extensions fail explicitly. No project that requests PSCV receives ordinary checked output as a fallback.

## Self-host and kernel work preserved

The release compiler comes from qualified F source `fcd875c8f38db4b0524090bd10c7c2fd5024053d` and [F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800). Its JavaScript SHA-256 remains:

```text
5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15
```

All 61 raw compiler source modules still produce the qualified source-closure identity:

```text
6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7
```

The selected authoring seed R remains `fe2560aba0f347b1caf8d000d371464642d44f23`. Its manifest, active TS7 recovery policy and historical evidence are unchanged. No provider algorithm, kernel metatheory, compiler algorithm or source-language profile is changed by this milestone.

Consumer support for Node 26 is separate from bootstrap qualification. The compiler reproduction recipe remains Node 22.23.3, Lean 4.34.0 and TypeScript 7.0.2. The Node26 installed checks do not claim a Node26 compiler fixed point.

The new host and release tooling sit outside the portable compiler closure. A future source/module reorganization must deliberately requalify its changed closure. A joint generated compiler/kernel fixed point is still separate.

The preview assembly job obtains F and the Windows provider from their retained exact Actions artifacts; it obtains the existing Linux provider through its pinned-source build/cache and authenticates its unchanged bytes. The Windows PE records its ordinary link timestamp (`1791581097`), so a later ordinary build is not claimed to reproduce the same executable hash. A deterministic native link recipe remains a separate qualification task; the existing exact Windows payload must be retained in the meantime. Before a durable public release, preserve/recover the exact release inputs through a nonexpiring release/seed channel and exercise the declared clean recovery route. The existing R recovery evidence is preserved; it is not an assertion that the new preview workflow can survive expiration of every external artifact.

## Later proof work

The requested layout remains `psc0/proofs/**/*.proof.lean`, with ordinary `.lean` files for reusable models and lemmas, a separate proof-only Lake environment and claim ledger. Full Lean tactics and useful proof libraries may be used outside the self-host cycle. Full PSCV is a later authoring capability when implemented.

The architecture plan already defines this layout and a direct-file runner pattern. No new compiler theorem suite or proof workspace is claimed as implemented here. Formal assurance remains a later gate.

| Boundary | Later obligation |
| --- | --- |
| Kernel foundation and admission | Codec/admission refinement, well-formed environments and explicit assumptions; a separate model/relative-consistency argument |
| Source/prepared/admission state | Source-to-Core correspondence and implementation refinement of the owned session |
| RuntimeIR | Checker soundness for independently defined invariants; separate semantic preservation of erasure and transformations |
| TS backend/runtime | Semantics of the emitted fragment, runtime representations and remaining TS7/JS assumptions |
| Publication | Transaction-state-machine refinement under stated filesystem and cooperating-writer assumptions |
| Bootstrap | Composition of source/seed/toolchain/generation relations; reproducibility alone is insufficient |
| Extensions | Capability, message, disclosure and isolation refinement once the actual runner is implemented |

## Next implementation milestones and gates

1. **One isolated extension slice.** Introduce the small constrained runner and data protocol, explicit root-project activation, compulsory actual-load reporting, and complete official/third-party examples. Guest code must have no provider, admission, final-output or reporting authority. Arbitrary in-process npm plugins are not a shortcut.
2. **Stable semantic and extension contracts.** Bind primitive identities and runtime assumptions, publish a narrow SDK, and qualify a bounded producer/validator path. Do not accept type-preserving changes as semantic-preservation certificates.
3. **Final package and library organization.** Apply the ps-prefixed boundaries without adding a second compiler. Qualify project-local locked installs, library imports, durable release-input recovery and supported platform artifacts. Public npm release also needs an explicit project distribution license; the current preview is UNLICENSED.
4. **Complete T1 before watch/LSP.** Add the accepted export map, neighboring facades and checked ABI, then test cross-file datatype identity, initialization and calls. Follow with `psdev` invalidation/cancellation/recovery and coordinated downstream builds. LSP/editor snapshots remain separate from publishable checked builds.
5. **Formal assurance in parallel when useful.** Develop independently scoped proofs without making full proof completion a closing gate for the implementation milestones.

The earlier preview0 operational diff from the architecture base was **33 files, 2,739 added lines and 421 deleted lines**. The qualified preview1 correction from documented head `158a5d9` to `3fd25db` changes **25 files, 1,986 added lines and 287 deleted lines**, including the native probe recipe, tests, workflow, metadata and retained evidence. The compiler's portable Lean sources have zero changes. These are measured diff counts, not a claim about TCB size or the total remaining plan cost.

The containing documentation/evidence-only follow-up records this result and does not change the qualified runtime package. Do not repeat completed compiler fixed-point work for those documentation changes or treat this preview as completion of the whole architecture.
