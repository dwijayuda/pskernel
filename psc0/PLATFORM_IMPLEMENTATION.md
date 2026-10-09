# PSC0 platform implementation status

**Milestone:** protected compilation and installable npm preview, qualified on 9 October 2026 UTC (10 October in Asia/Jakarta).

**Scope:** this is the first usable implementation milestone of [PSC0_ARCHITECTURE_PLAN.md](PSC0_ARCHITECTURE_PLAN.md). It does **not** complete all phases 0–4 of that plan. Isolated extension execution, stable extension/primitive contracts, the final ps-prefixed package split, npm library imports and the complete T1 module/ABI work remain open.

**Working branch:** `psc0/platform-v1`. **Review:** [draft PR90](https://github.com/dwijayuda/pskernel/pull/90), based on the architecture-plan branch. Main was read back unchanged at `ed5d00aca0743bde583b45fe7756dd494ac3960f`. No package was published to npm.

## Qualified result

The exact executable/package source is [48be48c0fd91407ca531692be2a3bd8bc24b058b](https://github.com/dwijayuda/pskernel/commit/48be48c0fd91407ca531692be2a3bd8bc24b058b), tree `0cbeb41c6016295be2247ee27c16d074d7b46810`.

[Run 37990210503](https://github.com/dwijayuda/pskernel/actions/runs/37990210503) passed both jobs on attempt 1 and completed at **2026-10-09 20:57:03 UTC**.

| Gate | Observed result |
| --- | --- |
| Prepared sessions, output publication, public CLI and release assembly | 61 tests passed; 0 failed; 0 skipped |
| Actual native provider and generated-compiler integration | 16 tests passed; 0 failed; 0 skipped |
| Source/preparation boundary guard | Passed |
| Portable compiler source closure | Exact qualified hash; 61 modules |
| Native provider executable | Exact qualified SHA-256 |
| Fresh global npm installation | Passed, with lifecycle scripts disabled |
| Installed compiler in an unrelated project | Passed without source checkout or Lean installation |
| Installed execution with only Node on PATH | Passed |
| Existing TS project imports generated neighboring TS | Typechecking and JavaScript execution passed |
| Invalid rebuild and requested PSCV profile | Refused; prior completed output preserved |
| Provider ELF and linked-library inspection | Passed in the same sanitized environment as compiler execution |

The installed smoke has **12 explicit observations**, all passed. Its runtime was Ubuntu **24.04.5**, image **ubuntu24/20261004.327.1**, Node **22.23.3**, npm **10.9.9**, Linux x64. Other systems have not been qualified by this milestone.

The exact logged result and Actions metadata are retained in:

- [qualification-2026-10-09.json](docs/platform/qualification-2026-10-09.json)
- [installed-package-qualification.json](docs/platform/installed-package-qualification.json)

The two preceding platform runs also passed. The final run adds the clarified packaged documentation and inspects the provider under the same sanitized environment as actual execution. None of these platform runs rebuilds or claims a new compiler fixed point.

## Try the tested npm preview

Download the [candidate artifact](https://github.com/dwijayuda/pskernel/actions/runs/37990210503/artifacts/11644293016). After extracting it, the package is `platform/proofscript-0.1.0-preview.0.tgz`.

```sh
npm install --global --ignore-scripts ./platform/proofscript-0.1.0-preview.0.tgz
psc --version
psc extensions --json
```

The tarball is **1,890,798 bytes**, approximately 1.89 MB. This excludes the separately installed TypeScript dependency and is not an installed-footprint measurement. Its SHA-256 is:

```text
f44034b3624f67660e252df919f0188991613ac7069e47805355e2760374f12c
```

The [installed evidence artifact](https://github.com/dwijayuda/pskernel/actions/runs/37990210503/artifacts/11645305653) contains the full build receipt and ELF/library reports. These Actions artifacts currently expire on **8 November 2026**. The committed evidence preserves their identities; it is not a permanent copy of their executable bytes.

The command `npm install --global proofscript` will select the package currently in the registry. This preview has **not** been published there. Use the exact tarball above to test this implementation.

### Existing TypeScript project example

Create `src/Main.ps` using the supported bounded grammar:

```text
def answer : Nat := 42
```

From that project's directory:

```sh
psc check src/Main.ps
psc build src/Main.ps --out src/Main.ts --json
```

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

The unchanged provider transport and contract code were reused. The old generated-owned provider is retained for historical/development comparisons, not silently selected under the protected Core name. The separate 4.35 Arena lane has a different protocol and remains independent.

### Output ownership and completion are explicit

[checked-artifact-publication.mjs](scripts/checked-artifact-publication.mjs) rejects existing unowned output and manually edited generated output. An output-directory lease coordinates cooperating publishers, including different stems whose sidecars overlap.

Private staging and a journal precede visible changes. The publisher checks the source eligibility callback before publication and again before receipt commitment. It then rechecks its lease, receipt absence, all candidate artifact bytes and retirement of obsolete owned files. The new receipt rename is the commit point.

Handled failures restore only bytes attributable to the failed transaction. Conflicting user changes are preserved. Incomplete rollback retains the lock, journal and backups and reports recovery-required status. Cleanup failure after commitment reports `PSC0_OUTPUT_COMMITTED_CLEANUP_REQUIRED` without rolling back valid new output.

This is a completion protocol for cooperating consumers. It does not make multiple file renames appear atomic to independent `tsc`/Vite watchers, prove power-loss durability, or prevent an arbitrary process with filesystem authority from racing the supervisor. Automatic crash recovery and coordinated watching are later tooling work.

### The release stays small and explicit

[assemble-release.mjs](scripts/assemble-release.mjs) copies an explicit **17-file maintained host closure**, the exact generated compiler, the exact native provider, and release metadata. It excludes tests, proofs, the legacy trees, optional provider packages and the Lean development toolchain. The grammar profile constant is separated from the large conformance test it previously imported.

The release has one exact TypeScript runtime dependency and no package lifecycle scripts. Five independently published npm packages are not created in this first slice. The future `pskernel-core`, `pscore`, `psfrontend`, `psc`, and `psbackend-ts` boundaries remain the accepted target; their compiler functionality currently ships as a bundled runtime plus the host.

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

The new host and release tooling sit outside the portable compiler closure. A future source/module reorganization must deliberately requalify its changed closure. A joint generated compiler/kernel fixed point is still separate.

The preview assembly job currently obtains F from its retained Actions artifact and rebuilds the pinned native provider as necessary. Before a durable public release, preserve/recover the exact release inputs through a nonexpiring release/seed channel and exercise the declared clean recovery route. The existing R recovery evidence is preserved; it is not an assertion that the new preview workflow can survive expiration of every external artifact.

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

At the qualified checkpoint, the operational diff from the architecture base is **33 files, 2,739 added lines and 421 deleted lines**, including tests, workflow, metadata and documentation. The compiler's portable Lean sources have zero changes. These are measured diff counts, not a claim about TCB size or the total remaining plan cost.

The next documentation/evidence-only commit records this result and does not change the qualified runtime package. Do not repeat completed compiler fixed-point work for those documentation changes or treat this preview as completion of the whole architecture.
