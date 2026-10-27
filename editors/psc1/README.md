# PSC1 editor tools

A standalone LSP and a VS Code extension using the genuine qualified PSC1 compiler and official Lean 4.35.0 linear-memory Wasm checker. Both tools are outside compiler self-hosting, G1/G2/G3, and kernel proof development.

**Qualified preview 0.1.2:** [download the VSIX and npm package](https://github.com/dwijayuda/pskernel/actions/runs/40602478756/artifacts/12779023197) · [successful Linux, Windows, and macOS CI](https://github.com/dwijayuda/pskernel/actions/runs/40602478756) · [complete qualification receipt](QUALIFICATION_0.1.2_2026-10-28.json). The same delivered packages passed 29 automated checks and actual installed-npm/VSIX checks on Linux x64, Windows x64, and macOS arm64. Nothing is published to a registry or Marketplace.

The controlled comparison against 0.1.1 measured **1013.36 ms → 749.65 ms** for the median of three distinct small-source edits at the same 50 ms debounce: **26.02% lower latency**. With each version's normal scheduling, the measured median fell from **1307.22 ms to 845.3 ms**, or **35.34% lower**. Opening the fixture under normal scheduling fell from 1298.26 ms to 969.46 ms. These are editor-protocol observations on one Linux runner, not a universal latency guarantee or a full VS Code startup comparison.

The improvement retains an isolated worker and verified provider health setup, prioritizes the current project, and reduces the default typing delay to 150 ms. Every distinct graph still receives genuine independent kernel checking. Unchanged saves start no new compiler job; exact repeated source can reuse its result. See the [earlier 0.1.1 receipt](QUALIFICATION_0.1.1_2026-10-28.json) for the previous performance update.

## Install

Download the `proofscript-psc1-editor-<commit>` artifact from the [editor workflow](https://github.com/dwijayuda/pskernel/actions/workflows/proofscript-editor.yml). Check the included `SHA256SUMS` and `BUILD.json` before using its artifacts.

- VS Code: use **Extensions: Install from VSIX…** with `proofscript-psc1-0.1.2.vsix`, or `code --install-extension proofscript-psc1-0.1.2.vsix`. Use the currently qualified VS Code version or newer, as stated in the extension manifest. Disable the old ProofScript extension if installed; both register `.ps`.
- Other editors: `npm install --global --offline --ignore-scripts ./proofscript-lsp-0.1.2.tgz`, then run `psc1-lsp --stdio`. Node >=22.23.3 is required. Configure the LSP client to send `initializationOptions: {trusted: true}` only for a workspace you trust.

The VSIX and npm package each contain the same unmodified qualified compiler package. Users need no Lean installation, compiler build, npm network access, external server executable, or install hooks. Native platform qualification results are recorded in the work-state document; compiler publication qualification is unchanged. The VS Code extension runs in the workspace extension host, including a Linux remote workspace.

Open a folder containing `proofscript.json` and `.ps` sources:

```json
{
  "schema": "proofscript-project/1",
  "entryModule": "Main",
  "files": [{"module": "Main", "path": "Main.ps"}]
}
```

```text
def answer : Nat := 42
```

Standalone saved-path `.ps` buffers also work without a project. New unsaved contents at a file URI are supported; untitled and virtual files must first receive a filesystem path.

## Editor experience

The right Secondary Side Bar hosts **ProofScript: Show Infoview**. It follows the current cursor and shows the selected declaration, its actual elaborated type when available, the current compiler/checking status, and messages. A bottom-left status item and declaration gutter markers track the current source snapshot. Editing any open project source immediately clears old verification markers.

`.lean` files remain owned by the normal Lean extension. In a PSC1 project, run **ProofScript: Use PSC1 for This Lean File** to explicitly select the PSC1 subset language mode. A project closure must use one grammar throughout; mixed `.ps`/`.lean` source lists are refused by the existing compiler.

Select that PSC1 mode for every open `.lean` dependency whose unsaved edits should participate in checking. Files left in the standard Lean language mode remain saved-file dependencies of this extension.

| Feature | Evidence and scope |
| --- | --- |
| Diagnostics | Actual compiler parser/elaboration refusals and actual checked-pipeline errors. Parse errors may have module-level positions; this is explicitly stated in the message. |
| Checked declaration status | Original compiler origins correlated with the actual independent-check receipt and canonical admissions hash. Ordinary partial bodies never receive verified markers. |
| Hover types | Presentation of actual elaborated Core types from those admissions. Exact-name lookup is labeled as spelling lookup, without claiming reference binding. |
| Document outline | Compiler declaration origins after checking; a clearly labeled lexical outline while checking or incomplete. |
| Go to definition | Compiler-origin declaration locations and explicit project imports. General reference resolution is deferred. |
| Completion | Syntax keywords and names of current project declarations. Availability/type-directed completion at the cursor is not inferred. |
| Highlighting | TextMate syntax highlighting, verified declaration semantic tokens, and lexical same-spelling document highlights. |
| Workspace symbols | Bounded inventory of declarations in open source documents. No unbounded disk index. |
| Infoview goals | No interactive proof-state API exists in the qualified distribution; the UI says so. It does not fabricate goals or show “Goals accomplished!” from a successful compile alone. |

Binding-aware references, safe rename, signature help, term-level inferred types, proof tactics/goals, and semantic quick fixes remain unavailable. They need new public compiler information rather than a second elaborator in the LSP.

## What a checked marker establishes

The existing public `compileCandidate()` API analyzes the captured source once. The existing public Wasm provider handle's `checkCanonicalAdmissions()` method independently checks that candidate's exact admissions. The editor retains verified health metadata from `createKernel()`; every new graph still goes through a fresh genuine Lean Wasm checking process. Release-pinned resources are verified before and after provider use. A positive status requires exact source/compiler/admissions identity and accepted checker results. The editor receipt records `targetValidation: "not-run"` and `publication: "not-requested"`: a checked declaration establishes logical admission, not target execution, artifact publication, or formal source-to-backend preservation. Compiler build/publication APIs and their platform restrictions are unchanged.

## Projects, responsiveness, and trust

The loader uses the nearest `proofscript.json` inside the applicable workspace folder and the existing strict `proofscript-project/1` contract. It preserves declared order and file inventory. The real compiler validates exact transitive closure, imports, and semantics. Unsaved buffers override disk files; no temporary edits are written into projects. Legacy inline-source project JSON is refused with an explicit mapping limitation because it does not establish which disk source corresponds to its inline text.

Edits use a 150 ms default delay; opening a source and manually checking it start immediately. The triggering project goes first. One isolated worker handles one immutable source job at a time and may retain imported host code and verified kernel health between completed jobs. It is retired after 128 requests, 30 seconds idle, cancellation, timeout, protocol or infrastructure failure, or workspace trust removal. Cancellation kills the entire compiler process tree, using the system taskkill utility on Windows. Each response must match its exact job identity and current source generation.

A 128-entry, 16 MiB LRU result cache reuses only byte-identical ordered source closures with the same assurance and compiler identity. Changed sources receive genuine new compiler analysis and kernel checking. Unchanged saves do not restart a check. Manual rechecking of a selected file bypasses only that project's cached result. Current document versions and every captured dependency version accompany terminal status. The global generation still invalidates open-project status and can cancel another project's in-flight job; this is not a per-project incremental scheduler. Limits remain 64 open source documents, 512 declared source files, and 8 MiB per project. Existing compiler/checker resource limits remain, with an additional 30-second editor deadline configurable up to 120 seconds.

Configuration and source files cannot select executables, load plugins, or change kernel authority. The extension uses only its bundled server. Untrusted workspaces retain syntax features without compiler execution. The Infoview uses escaped text and a script-disabled content-security policy; messages cannot execute HTML or scripts.

Commands include restart, recheck, show output, server information, show Infoview, and copy declared type. Settings are `proofscript.checkDelay`, `proofscript.checkTimeout`, and `proofscript.trace.server`. When checking fails or times out, the UI remains unverified. **ProofScript: Show Output** and **Show Server Information** expose the current runtime, compiler identity, limits, and job statistics.

## Build and qualify

All repository development and qualification for this lane use GitHub/cloud workflows. The following commands run in `editors/psc1` on the Linux runner:

```sh
npm ci --ignore-scripts
npm run prepare:compiler
npm run build
npm test
npm run test:performance
npm run package
npm run test:packed
xvfb-run -a npm run test:vscode
```

`prepare:compiler` downloads the exact artifact pinned by `compiler-input.json`, verifies both archive and tarball SHA-256, and extracts the complete unchanged compiler. It needs a GitHub token with artifact read access through `gh`. The committed dependency lock is used with `npm ci`. Native CI verifies and executes the same Linux-built tarball and VSIX rather than substituting rebuilt platform artifacts.

The build bundles the client and server libraries, retains upstream licenses, and copies the compiler unchanged into both distributables. No npm or Marketplace publication occurs. The integration suite uses real compiler outputs, genuine independent-admission receipts, and actual installed artifacts. It does not rerun compiler fixed points or kernel qualification.

See [research and architecture](RESEARCH.md), [work state](AI_WORK_STATE.md), and [compiler identity](compiler-input.json).
