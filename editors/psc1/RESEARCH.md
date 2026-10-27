# PSC1 editor integration research and architecture

Research date: 2026-10-28, Asia/Jakarta. Base: PR197, commit `9d0e23c34484e4b1159f3e2428f5452139df530a`. Final package qualification at that HEAD passed in run [40502746428](https://github.com/dwijayuda/pskernel/actions/runs/40502746428); the immutable compiler input is from [40501926898](https://github.com/dwijayuda/pskernel/actions/runs/40501926898) and has identical qualified tarball bytes.

## Authoritative compiler observations

Read `psc1/npm-cli/compiler-api.mjs`, `universal.d.ts`, `cli-project.mjs`, `host-tools/runtime-policy.mjs`, compiler `Service.lean`, bridge `CheckedAdmissions.lean`, syntax `Cursor.lean`, and the package qualification receipt.

The installed public `compile()` API accepts in-memory module sources and returns an independently checked result, but converts compiler refusals into broad exceptions. The separate `compileCandidate()` public API exposes real structured phase/code/module/declaration information and source origins. It cannot grant logical admission. A successful candidate also includes the compiler's canonical admission text with actual elaborated declaration types.

The 0.1.0 worker called both APIs; the 0.1.1 worker calls `compileCandidate()` once and then the existing public `checkCanonicalAdmissions()` API. Before presenting a checked declaration/type, it validates the captured source closure, compiler identity, candidate transport metadata, and accepted genuine checker receipt for the exact SHA-256 of the canonical admissions. Types are rendered from existing Core expressions only. No inference, reduction, elaboration, or proof checker is implemented in editor code.

Positions use one-based Unicode scalar columns in the compiler and zero-based UTF-16 in LSP. The adapter performs an explicit conversion. Parse failures do not contain precise positions; elaboration refusals identify declaration starts. Origin start locations are real compiler information, while the source-name selection range and declaration outline end are lexical presentation boundaries. The editor does not claim term-level provenance.

Project files are data only. Current supported projects use `proofscript-project/1` with strict `{entryModule,files,assurance?}` metadata. All sources in a closure must have the same kind, retain topological declared order, and describe the entry module's exact dependency closure. The adapter preserves these rules and lets the compiler reject an invalid closure. Legacy inline project sources lack a reliable disk-file mapping and are explicitly unsupported for editor checking.

Source bindings exist in compiler development sources, but are not a callable public low-level service in the qualified npm package. Interactive goal snapshots and safe reference/rename information are unavailable. Introducing a new compiler build solely for editor features would expand qualification and couple the lane back to compiler development; it is deferred.

## Standards and editor decisions

Primary references examined:

- [LSP specification](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/): initialization, UTF-16 positions, incremental text synchronization, cancellation, diagnostics, workspace folders, and semantic tokens.
- [VS Code language-server guide](https://code.visualstudio.com/api/language-extensions/language-server-extension-guide): a lightweight extension client and a separate language-server process.
- [Official Node LSP libraries](https://github.com/microsoft/vscode-languageserver-node) and [server11.0.0 release](https://github.com/microsoft/vscode-languageserver-node/releases/tag/release/server/11.0.0): pin matching client/server11.0.0 and textdocument1.0.16; only stable implemented LSP features are advertised.
- [Lean4 VS Code](https://github.com/leanprover/vscode-lean4): cursor-following Infoview, declaration/proof feedback, clear messages, and language-server separation.
- [VS Code workspace trust](https://code.visualstudio.com/api/extension-guides/workspace-trust): checking is gated by trusted workspace state.
- [VS Code webviews](https://code.visualstudio.com/api/extension-guides/webview): script-disabled rendering, escaped external text, no workspace resources, restrictive CSP.
- [VS Code extension tests](https://code.visualstudio.com/api/working-with-extensions/testing-extension): real Electron extension host. The smoke test installs the generated VSIX and uses a different minimal harness extension, ensuring the test cannot silently substitute source-tree extension files.
- [VS Code1.143.1 source](https://github.com/microsoft/vscode/tree/1.143.1): current runtime and secondary-sidebar support. The extension requires a runtime meeting the compiler's actual Node>=22.23.3 policy.

The supplied ProofScript0.45 VSIX was inspected only for its manifest, UI contributions, documentation and visual assets. Its old compiler, language-server code, runtime and custom protocol were not transplanted. The new UI preserves the desired right sidebar, bottom-left status, messages, declaration markers and diagnostic commands while reporting capabilities of the current compiler honestly.

## Implementation layout and decisions

`editors/psc1/lsp` owns the standalone server, project-data adapter and compiler worker. `editors/psc1/vscode` owns only editor integration, a grammar and Infoview rendering. Shared development/packaging tools live in `editors/psc1/scripts`. This separate tree avoids changing existing npm package names, compiler sources, kernel providers, self-hosting inputs or core qualification workflows.

The server remains responsive while a synchronous public compiler API executes in a forked process. Linux process-group cancellation terminates that worker's compiler descendants. Each job receives its own temporary directory, removed after cancellation or completion. A project generation and document version protect every publication against unsaved dependency changes. Checks serialize globally and debounce; no unbounded incremental database or alternate compiler service is introduced.

One immutable qualified compiler package is extracted and hash-verified during packaging. The complete unchanged package is included in each independently installable editor artifact, including its upstream licenses and internal integrity manifest. A VSIX installation does not need Lean or a second npm installation. The standalone LSP tarball has its runtime libraries bundled and installs offline without scripts.

The bounded lexical helpers deliberately provide limited outline, name completion and same-spelling highlights. General reference navigation, rename, signature inference and semantic fixes are deferred. Verified semantic highlighting uses only current checked declaration origins.

The editor's assurance is independent logical admission of the original compiler's exact canonical graph. Its receipt explicitly excludes target validation/execution and publication. Neither a green marker nor a successful LSP test establishes formal source-to-backend preservation, a compiler fixed point, or a new kernel consistency theorem.

## Packaging dependency audit

The locked development dependency tree currently reports one advisory across three affected dependency nodes: [GHSA-xcx6-jx8p-x3h5](https://github.com/AzureAD/microsoft-authentication-library-for-js/security/advisories/GHSA-xcx6-jx8p-x3h5), through `@vscode/vsce@4.0.0` → `@azure/identity@4.14.0` → `@azure/msal-node@6.0.1`. The advisory concerns an authentication-code flow. This workflow invokes only offline VSIX packaging, with no Marketplace/Azure sign-in or publishing. These development dependencies are absent from the editor's runtime bundles; the build records its actual bundled package inventory and refuses Azure/publisher modules in those bundles.

The upstream fix is MSAL7.1.0, while the current Identity4.14.0 dependency contract requires MSAL6. A forced major-version override was not substituted without compatibility evidence. Downgrading vsce3.9.2 alone still resolves the affected Identity through its broad dependency range. The full audit is retained with CI evidence; packaging authentication/publication remains outside this deliverable. Revisit the development dependency when upstream Identity updates its supported MSAL range. This is a scoped build-tool limitation, not a claim of a clean audit for every development dependency.

## Performance and native-platform correction, 0.1.1

The user reported slow checking and provided a screenshot with `PSC1_SERVICE_PUBLICATION_PLATFORM_UNQUALIFIED` in Problems while Infoview remained pending. Source inspection found three separate issues.

1. [`compile()`](../../psc1/npm-cli/compiler-api.mjs) creates a temporary artifact session. [`openPublicationStore()`](../../psc1/host-tools/transactional-publication.mjs) unconditionally requires Linux, even for compile-only staging. This editor operation was unnecessary. The existing public `checkCanonicalAdmissions()` delegates to [`checkInstalledAdmissions()`](../../psc1/host-tools/installed-engine-resolver.mjs), retaining genuine Wasm health/check execution and pinned-resource verification. No platform guard or compiler implementation was changed.
2. The former path repeated compiler analysis and performed target validation, executable hashing and artifact staging. The editor now performs one candidate analysis and independent admission, with candidate/kernel/metadata timings. The kernel public API still starts separate health/check processes; this is not a warm-Wasm or incremental-compiler claim. A bounded exact-source cache and no-op-save handling remove redundant repeat checks.
3. Node file URLs and VS Code URIs can differ in escaping and drive spelling. Exact string lookup lost Windows unsaved overlays and terminal custom statuses. The loader now compares decoded filesystem identities, preserves client URIs, and checks filesystem identity before accepting existing-file case aliases. The client consumes exact dependency-version snapshots, normalizes URI keys and never predicts server generations.

The same Linux workflow measures the immutable 0.1.0 package and new server on actual distinct source edits. Separate native Windows/macOS jobs verify and install the exact Linux-built npm/VSIX bytes. UI unit tests establish rendering/state behavior only; actual language checking is exercised using the real compiler. Windows cancellation uses the system taskkill process-tree operation with no shell; cleanup retries retain failed temporary paths for shutdown.

## Qualified 0.1.2 host lifetime and checking latency

[Run 40602478756](https://github.com/dwijayuda/pskernel/actions/runs/40602478756) qualifies the external editor optimization at `09bfcea90879e5a7f821bc2a988753d77a18f169`. The [complete receipt](QUALIFICATION_0.1.2_2026-10-28.json) retains controlled measurements, process profiles, and installed-platform evidence.

The unchanged public compiler API always launches the generated candidate runner. The universal root checker wrapper creates a public provider handle for each call, which adds a health subprocess before the admission subprocess. Retaining only imported API modules does not retain either heavy process. The selected design retains an editor-owned isolated worker and the public provider handle, while preserving a fresh genuine Wasm admission process per graph. No Lean environment or admitted declaration state crosses requests.

Expected resource hashes come from the exact previously qualified ZIP and compiler tarball. The build compares extracted resources against those archive bytes before emitting a static frozen pin module. The worker revalidates that inventory before and after provider initialization and every admission operation. It submits the exact candidate admissions and uses the genuine provider result; no universal agreement flag or acceptance result is synthesized. The resource-alteration test runs only against a disposable copy.

Same-delay changed-edit latency fell 26.02%; normal-default latency fell 35.34% on the small Linux fixture. Retained-worker profiling shows zero subsequent health initialization; the current compiler process and genuine admission remain substantial. A larger reduction requires a supported persistent compiler session and eventually dependency-aware incremental analysis, with corresponding source and proof-state invalidation. That work is not implemented by this editor patch.

The 29-check suite also covers cancellation/worker replacement, exact source and admission identities, real semantic refusal after health reuse, nine-project cache retention, targeted manual checks, and idle worker cleanup. The identical packaged artifacts passed native Windows/macOS and actual installed VS Code qualification. Earlier single-use-worker descriptions in this research document are historical.
