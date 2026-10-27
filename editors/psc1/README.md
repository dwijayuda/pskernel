# PSC1 editor tools

A standalone LSP and a VS Code extension using the genuine qualified PSC1 compiler and official Lean 4.35.0 linear-memory Wasm checker. Both tools are outside compiler self-hosting, G1/G2/G3, and kernel proof development. No compiler or kernel implementation is changed.

**Preview 0.1.1 performance and platform repair:** editor checking now performs one genuine compiler analysis and independent admission of its exact logical graph. It does not create a target publication store. The workflow measures the previous and updated packages on the same Linux runner and runs the delivered packages on native Windows and macOS. See [work state](AI_WORK_STATE.md) for qualification progress; [0.1.0 evidence](QUALIFICATION_2026-10-28.json) is retained as historical baseline evidence. Nothing is published to a package registry or Marketplace.

## Install

Download the `proofscript-psc1-editor-<commit>` artifact from the [editor workflow](https://github.com/dwijayuda/pskernel/actions/workflows/proofscript-editor.yml). Check the included `SHA256SUMS` and `BUILD.json` before using its artifacts.

- VS Code: use **Extensions: Install from VSIX…** with `proofscript-psc1-0.1.1.vsix`, or `code --install-extension proofscript-psc1-0.1.1.vsix`. Use the currently qualified VS Code version or newer, as stated in the extension manifest. Disable the old ProofScript extension if installed; both register `.ps`.
- Other editors: `npm install --global --offline --ignore-scripts ./proofscript-lsp-0.1.1.tgz`, then run `psc1-lsp --stdio`. Node >=22.23.3 is required. Configure the LSP client to send `initializationOptions: {trusted: true}` only for a workspace you trust.

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

The existing public `compileCandidate()` API analyzes the captured source once. The existing public `checkCanonicalAdmissions()` API independently checks that candidate's exact admissions with the genuine pinned Wasm kernel. A positive status requires exact source/compiler/admissions identity and accepted checker results. The editor receipt records `targetValidation: "not-run"` and `publication: "not-requested"`: a checked declaration establishes logical admission, not target execution, artifact publication, or formal source-to-backend preservation. Compiler build/publication APIs and their platform restrictions are unchanged.

## Projects, responsiveness, and trust

The loader uses the nearest `proofscript.json` inside the applicable workspace folder and the existing strict `proofscript-project/1` contract. It preserves declared order and file inventory. The real compiler validates exact transitive closure, imports, and semantics. Unsaved buffers override disk files; no temporary edits are written into projects. Legacy inline-source project JSON is refused with an explicit mapping limitation because it does not establish which disk source corresponds to its inline text.

Checks are debounced (350 ms by default) and run in a separate child process. Changes cancel the old process group, including compiler descendants on Linux, and supersede every response associated with the earlier project generation. Current document versions accompany diagnostics. One compiler job runs at a time. An eight-entry, 16 MiB LRU result cache reuses only byte-identical ordered source closures with the same assurance and compiler identity. Changed sources still receive genuine new analysis and kernel checking. Unchanged saves do not restart a check; explicit recheck bypasses the cache. Current document versions and all captured dependency versions accompany each terminal status. Windows cancellation terminates the compiler process tree through the system taskkill utility. Limits are 64 open source documents, 512 declared source files, and 8 MiB per project. Existing compiler/checker resource limits remain unchanged; the editor applies an additional 30-second default job deadline, configurable up to 120 seconds.

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
