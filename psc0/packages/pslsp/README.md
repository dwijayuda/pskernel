# pslsp — ProofScript diagnostics language server

Private `0.1.0-preview.5` pilot. Install the matching `proofscript` and `pslsp`
candidate tarballs together using `--save-dev --save-exact --ignore-scripts`.

Start from the intended project directory:

```sh
node ./node_modules/pslsp/bin/pslsp.mjs --stdio
```

The server implements a deliberately small subset of LSP 3.17 over framed
stdio JSON-RPC: initialize/shutdown/exit, textDocument/didOpen/didChange
(full content sync only)/didSave/didClose and versioned publishDiagnostics.
It does not advertise hover, go-to-definition, completion or arbitrary
workspace symbol navigation. A future VS Code client can start this executable
without bundling a second parser or privileged compiler.

For each open `.ps` document, the server sends its **unsaved in-memory text**
to the pinned local `proofscript` CLI using `psc query entry.ps --stdin --json`.
The compiler performs actual checked declaration admission for the selected
document and the saved imports it depends on. The kernel and compiler remain
selected/authenticated by the installed `proofscript` release, not the editor
or `pslsp`. No output files, IR, target JavaScript or build receipts are
published by this query.

Compiler syntax-token spans are reported when safely available; elsewhere a
document-level diagnostic explicitly says that the precise location is
unavailable. These results are **not** general source-semantic hover/definition
data, proof of executable correctness, verification of every project export,
or a fresh multi-file PSCV proof. A check of an imported file alone is not
necessarily a complete check of its dependents.

The server limits each document to 1 MiB, at most 32 open documents and
8 MiB combined; queries have bounded output and wall time. Versioned
requests cancel superseded children and stale responses cannot clear newer
diagnostics. Only file URIs inside the chosen project root are eligible for
checks, and the host accepts ordinary regular saved files (not symlinks).
New unsaved files without a disk path receive an unavailable diagnostic rather
than creating project files.

This package is an **editor transport**, not a `psc-command/1` extension,
not a kernel provider, and not included in the minimal compiler/bootstrap
closure. No npm install hooks or VS Code installation scripts are run.
`proofscript` is an explicit exact-version peer dependency. Names are private
candidate names until a deliberate public registry release.

LSP specification: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
