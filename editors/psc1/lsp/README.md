# @proofscript/lsp

Standalone PSC1 language server over LSP stdio. Install the delivered tarball with `npm install --global --offline --ignore-scripts ./proofscript-lsp-0.1.0.tgz` and configure your editor to run `psc1-lsp --stdio`.

Requires Node >=22.23.3. The distribution bundles the unchanged qualified `proofscript@0.1.0-psc1.12` compiler and genuine official Lean4.35.0 linear-memory Wasm checker; no Lean installation or compiler source build is needed. Linux is the currently qualified runtime scope.

Use `initializationOptions: {trusted: true, enableLean: false, debounceMs: 350, timeoutMs: 30000}` after deciding to trust the project. The default is untrusted and does not execute the compiler. `enableLean` applies only to project-backed `.lean` files explicitly opened under `proofscript-lean` or `lean`. `.ps` uses `proofscript`.

The server implements synchronization, push diagnostics, declaration hover/outline, import/declaration navigation, completion, declaration semantic tokens, lexical highlights, and open-document workspace symbols. No binding-aware rename/references, tactic goals, or term-type inference is claimed.

Custom requests:

- `psc1/infoview`: `{textDocument:{uri},position,version}` returns current status and selected declaration; old versions return ContentModified.
- `psc1/serverInfo`: installation identity, process runtime, configuration, metrics, and limitations.
- `psc1/recheck`: schedules a fresh generation.
- `psc1/configuration` notification: updates `trusted`, `enableLean`, `debounceMs`, and `timeoutMs`.
- `psc1/documentStatus` server notification: `{uri,version,projectGeneration,state,summary,diagnostics,declarations,goalsAvailable:false}` plus checked receipt details when available.

States are `pending`, `checking`, `checked`, `partial`, `rejected`, `error`, `unsupported`, and `untrusted`. A declaration is verified only when `verified === true` in a current result. `partial` never means a partial runtime body was proved. Clients must invalidate current status on source or imported-source changes and reject older versions/generations.

Send watched-file notifications for `.ps`, `.lean`, and `proofscript.json` changes. Open-buffer contents override the disk. Limits: 64 open source documents, 512 files and 8 MiB per project; default 30-second compiler deadline. No project configuration selects executables or plugins.

Full source and instructions: https://github.com/dwijayuda/pskernel/tree/feat/psc1-lsp-vscode-20261028/editors/psc1
