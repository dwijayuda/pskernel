# ProofScript for VS Code

This is the pskernel repository's dogfood VS Code integration.

It reuses the earlier ProofScript editor architecture but is deliberately narrower than the older extension. The current extension provides:

- .ps syntax highlighting;
- parser/elaboration/kernel diagnostics;
- hover with canonical Lean lowering and declaration verification status;
- document symbols;
- a declaration-level ProofScript Infoview;
- a status-bar indicator;
- server restart and server-information commands.

## Trust boundary

The editor is not a proof authority.

"kernel verified" and "Goals accomplished!" are shown only when the current
ProofScript elaborator produced a closed pskernel declaration and pskernel
admitted it. Parse success, editor caches, syntax highlighting, hover,
completion/navigation metadata, and VS Code state never count as proof.

The LSP attempts to replay the repository's pinned Lean 4.34
Init.Prelude fixture into a pskernel environment. If that environment cannot
be loaded, the server reports the degradation and unresolved names remain
unsupported instead of being assumed valid.

Cursor-sensitive tactic snapshots are not implemented yet. The current
Infoview is declaration-level and does not fabricate intermediate goals.

## Development use

Build the repository packages first, then open the repository with this
extension in an Extension Development Host. By default the extension launches
editors/vscode/server/run-lsp.mjs, which loads the built
packages/lsp/dist/src/bin.js.

proofscript.lsp.path can override the LSP entry script.
