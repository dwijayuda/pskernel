# ProofScript PSC1 for VS Code

Edit ProofScript with feedback from the current PSC1 compiler. This extension is separate from compiler self-hosting and bundles its own matching language server and compiler distribution.

## Install and open a project

Install the generated `proofscript-psc1-0.1.1.vsix` using **Extensions → … → Install from VSIX**. Disable the previous **ProofScript** extension in this workspace if it is installed: the previous release and this extension both register `.ps` files and ProofScript commands.

Open a folder containing your `proofscript.json` project and a `.ps` source file. The compiler uses the open editor buffers, including unsaved edits. The first source check performs real compiler and kernel work; unchanged saves and previously checked identical source reuse their results. Open **ProofScript: Show Infoview** or press **Ctrl+Shift+Enter** (**Cmd+Shift+Enter** on macOS) to show the right-side Infoview.

VS Code 1.143.1 or newer is required; this is the editor baseline used for qualification. See the parent work-state document for exact Linux, Windows, and macOS qualification evidence. The bundled server uses VS Code's Node runtime, which must be at least 22.23.3 under the compiler's existing runtime policy. The extension checks that minimum before starting and reports a clear error on an older runtime. Compiler checking does not require a manual Lean installation.

## Understand the feedback

- **Checking / Waiting for check**: current source has no completed check result yet. Previous success markers are removed immediately on edits.
- **Checked**: the real PSC1 compiler analyzed the current source and the genuine kernel accepted its exact logical declarations. A blue double check beside a declaration is shown only when the server explicitly reports that declaration as verified.
- **Partially checked**: some declarations have a weaker assurance boundary, such as partial runtime declarations. The overall status stays amber. Those declarations receive no verified marker.
- **Rejected**: the compiler rejected the current source. Read the diagnostic or Infoview message.
- **Check unavailable / Unsupported**: the service failed or the compiler could not support this case. These states never imply proof success.
- **Workspace not trusted**: syntax highlighting is available; compiler checking waits for VS Code workspace trust.

The Infoview follows your cursor and shows a declaration, its declared type when available, compiler messages at the cursor, and all messages in the file. These are declaration checks. Cursor-level tactic goals and expected types remain unavailable until PSC1 exposes the necessary elaborator snapshots. An empty diagnostic list by itself is never treated as proof verification.

Navigation and completion may include explicitly labelled syntactic information. Their availability is described in the parent language-server documentation.

## PSC1-supported Lean files

The extension leaves normal `.lean` language associations unchanged. To use the PSC1-supported subset, open a `.lean` file inside a `proofscript.json` project and run **ProofScript: Use PSC1 for This Lean File**. That buffer switches to the explicit **ProofScript Lean subset** language mode. Switch back to Lean using VS Code's language mode picker to resume the standard Lean extension.

This mode is scoped to PSC1 projects and does not advertise support for the full Lean language.

Unsaved `.lean` edits are synchronized only after explicitly choosing this mode. A `.lean` import open in the standard Lean editor remains a saved-file dependency for PSC1 until you opt that buffer in.

## Commands and settings

- **ProofScript: Show Infoview**
- **ProofScript: Check Current File**
- **ProofScript: Restart Language Server**
- **ProofScript: Show Server Information**
- **ProofScript: Show Output**
- **ProofScript: Copy Declared Type**
- **ProofScript: Use PSC1 for This Lean File**

`proofscript.checkDelay` controls the edit debounce (350 ms by default). `proofscript.checkTimeout` bounds one check (30 seconds by default). `proofscript.trace.server` enables protocol logging in the ProofScript output channel. Verbose logs may contain your source text; review them before sharing.

The extension runs its bundled server. Project manifests and workspace settings cannot select a shell command, alternate server, or proof checker.

## Troubleshooting

If a check appears stuck, open **ProofScript: Show Output**, inspect **ProofScript: Show Server Information**, then use **ProofScript: Restart Language Server**. The client automatically retries unexpected server exits up to three times in three minutes. Repeated failures leave an explicit stopped state.

Confirm that the folder is trusted, the source language is ProofScript (or the explicit PSC1 Lean subset), and imports stay within the supported project boundary. Check `proofscript.json` and the compiler diagnostics for unsupported configuration. A missing compiler distribution is an installation error; reinstall the complete VSIX rather than pointing the extension at an older compiler.

## Development

Source lives in `editors/psc1/vscode`; the standalone server is in `editors/psc1/lsp`. Follow `editors/psc1/README.md` for reproducible packaging and Linux qualification. These tools are outside G1/G2/G3 and kernel proof obligations.

The attached v0.45.0 VSIX informed the layout only. No previous compiler, server, protocol, runtime implementation, or source was transplanted.

## 0.1.1 performance and status repair

The editor no longer calls the compiler artifact-publication pipeline during editing. This removes duplicate compilation and the Linux-only publication-store error while retaining genuine logical checking. Infoview cursor movement uses current compiler-reported declaration ranges locally. Windows file URI aliases preserve unsaved source buffers, and terminal errors appear as **Check unavailable** rather than remaining **Waiting for check**. Exact timings and platform results are retained with the workflow artifacts.
