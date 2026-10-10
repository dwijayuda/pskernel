# PSC0 editor query and pslsp diagnostics contract (pilot)

## What is implemented

`psc-source-query/1` is a protected **admission-only** query over a selected `.ps` file and its **saved import closure**. An editor sends unsaved source text by standard input; the host overlays that one document **in memory**, loads the exact release-pinned generated compiler, and asks the release-pinned PSKernel Core admission provider to check the canonical declarations. It does not run erasure, TypeScript emission, project ABI validation, artifact publication, or any extension guest. The source graph and immutable source bytes are captured before checking, as in the existing protected build; persisted outputs cannot be inferred from this query.

Example, from a project directory with the exact local compiler installed:

```sh
node ./node_modules/proofscript/bin/psc.mjs query src/Main.ps --stdin --json
```

Write the complete UTF-8 document to stdin (not a JSON string). The result is exactly one JSON object on stdout with `kind: "psc-source-query/1"`; ordinary supervisor extension disclosure remains on stderr. Maximum query document size is **1 MiB**. Invalid encoding and unsupported file kinds are rejected. Query does not load npm JavaScript from editor/extension packages.

Output fields include `schemaVersion: 1`, `entryPath`, `sourceSha256`, `scope: "document-with-saved-import-closure"`, `stage: "kernel-admission-only"`, `status: "accepted" | "rejected" | "unavailable"`, `kernelAdmissionAccepted`, `diagnostics[]`, and assurance flags explicitly reporting that IR, ABI, target checking, compiler semantic preservation and PSCV were **not** established. Accepted results additionally report source-closure and selected compiler/kernel identities. They do not authorize emission: `psc build` still performs its separate protected checked/validated publication transaction.

### Diagnostic locations and categories

- Parser/lexer spans are taken from the **same pinned ProofScript parser** when a source parse fails. `PsSourceSpan` records UTF-8 byte offsets; the host converts them to **zero-based UTF-16** line/character offsets for LSP 3.17, rejecting partial UTF-8 scalar boundaries or invalid ranges.
- Other errors may lack reliable source spans. They use an explicit zero-width document position (0,0) and `location: "source-unlocated"`, not invented token locations.
- `status: "rejected"` means the supported preparation/admission path rejected the source. `status: "unavailable"` means a provider/host/input problem prevented a valid conclusion; the corresponding LSP diagnostic is a warning instead of a fabricated source error. Query success is not an executable correctness theorem or a whole-project assurance claim.
- A document with imported dependents is checked independently with its own imports, not automatically with every possible importing module, npm workspace or runtime ABI. True project-wide semantic queries and cross-document dependency attribution remain future work.

## Optional pslsp package

`pslsp@0.1.0-preview.5` is a separate, private preview package with an exact peer dependency on `proofscript@0.1.0-preview.5`. It is not part of the minimal self-host compiler source closure, and is not a privileged kernel/command:dev extension. No install scripts or background process are activated by installation. An editor launches the server explicitly:

```sh
node ./node_modules/pslsp/bin/pslsp.mjs --stdio
```

The server supports a bounded subset of LSP 3.17 over stdio-framed JSON-RPC: initialize, initialized, shutdown, exit; full-document didOpen, didChange, didSave and didClose; and versioned publishDiagnostics. It only advertises those capabilities, with `hoverProvider` and `definitionProvider` set to false. It does **not** invent hover types, reference resolution, completion, go-to-definition, or a VS Code extension.

Open document buffers remain entirely in the editor/server memory. Each query uses an independently supervised and cancellable exact local PSC CLI child; the LSP process never imports the compiler/kernel into the editor process. Document versions reject out-of-order updates, cancel superseded work and suppress stale results; closing a document clears its diagnostics. Only ordinary `.ps` files within the requested project root can be checked. Files which do not yet exist on disk are reported as unavailable, not quietly created.

Resource limits: **32 open documents**, **8 MiB** combined text, **1 MiB** per document, **2 MiB** maximum protocol input message, and a bounded **90-second** per-query child deadline. The server has no network listener. File/URI validation uses canonical containment and rejects symlinked file entries. These are operational limits, not a general OS sandbox or a memory/availability proof.

### Installation on Windows from the preview5 Actions artifact

From the extracted artifact directory:

```powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.5.tgz"
psc.cmd init my-app
Set-Location my-app
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.5.tgz" "$candidate\pslsp-0.1.0-preview.5.tgz"
node .\node_modules\pslsp\bin\pslsp.mjs --stdio
```

The final command speaks binary-framed LSP on stdin/stdout; use an LSP-capable editor/client, not an interactive terminal prompt. The installed smoke communicates with it using the actual LSP wire protocol and the actual release-pinned native Core. On Windows PowerShell, `psc.cmd` is the supported shim. Registry names and scope ownership remain subject to release policy; none of these preview5 packages is published to npm.

## Assurance and next milestones

The portable compiler's **62-module** self-host closure and selected authoring seed are unchanged by this host/editor slice. PSKernel Core is still the deliberately selected qualified **native** provider while its separately owned refinement work continues. The planned JS/Wasm Core runtime and optional native package remain later independent gates.

Additional milestones: stable semantic index/span query APIs with proven declaration ownership; full project diagnostics and imported dependent invalidation; actual hover/definition from admitted semantic data; thin VS Code client and plugin release defaults; durable binary archive retention, public license decision and intentional npm publication; full formal assurance under `.proof.lean` files outside the compiler bootstrap cycle.

Reference: Language Server Protocol 3.17 — https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
