# PSC0 source-library identity and host disclosure

## Scope

This implements the source-only part of PSC0-ARCH/1's extension-disclosure obligation (INV-12) and strengthens its source-input binding (INV-02). It does **not** implement executable syntax/tactic/backend guests, full P3, new kernel rules or new language features. The original compiler's semantic source and selected kernel are unchanged.

## Ownership and wire facts

`npm-cli/library-disclosure.mjs` is the sole parent-owned source-library inventory/notice owner. `libraries.mjs` resolves source data using the existing declared namespace map. `source-graph.mjs` records every resolved external module, including aliases before compilation deduplication. `snapshot.mjs.fileEvidence` copies immutable fingerprints of bytes already captured; it neither reopens files nor hashes a decoded approximation. This preserves raw UTF-8/BOM identity.

The sealed inventory has schema `psc0-source-library-disclosure/1`. It records separately:

- `declaredLibraries`: root-project namespace/package mappings, including unused ones. Unused packages are not installed, opened or claimed loaded by this operation.
- `libraries`: actually resolved source packages, their reported version, namespace, raw manifest digest and input ID, declared script names, and resolved source-module names/input IDs/raw byte hashes.
- `executedExtensions: []`, `proofAuthority: "none"`, `registryAuthenticityVerified: false`, and `installationHistory: "not-observed"`.

The domain-separated inventory digest is `SHA256("PSC0/LIBRARY-DISCLOSURE/1\0" + JSON.stringify(inventory))`. Keys are constructed by the trusted host; library/module arrays are sorted using explicit code-unit ordering. This is a versioned host evidence encoding, not a universal JSON canonicalization standard or a portable proof certificate.

The digest is bound into the source snapshot and the parent/worker checked binding. Build/check audit schema4 includes the same inventory. The original canonical admission stream remains the compiler's output and still goes through the selected JS kernel. Disclosure cannot grant admission or replace a checked handle.

## User-visible diagnostics

After complete source graph capture and before admission, the parent writes one `PSC_SOURCE_LIBRARIES:` JSON summary and one `PSC_SOURCE_LIBRARY:` JSON record per loaded package to **stderr**. `--json` stdout remains the result document. Notices label source loading, not successful proof checking; later rejection is still possible. Failed graph capture cannot provide a complete inventory and is not represented as a complete zero-library load.

There is no package-supplied logger, suppression flag or callback. Package claims outside the source-library schema are not copied as authority. A malicious OS, modified trusted host, or user redirecting stderr is outside this guarantee. Diagnostics themselves are not a security boundary for hostile code running in the host process.

## Supported metadata and explicit refusals

The documented `proofscript.library` schema remains exactly `{schemaVersion:1, modulePrefix:<namespace>, sourceRoot:"src"}`. Unknown fields in this semantic subobject are refused rather than silently treated as hook/capability declarations. The installed version is recorded as bounded ASCII identity text; no new SemVer range resolver is introduced. Namespaces retain existing reserved `Ps` and `ProofScript` policies, and the optional `@proofscript/stdlib` receives no extra proof authority.

Any root-project or loaded-library `proofscript.extensions` field is refused, even an empty list: an executable extension protocol is not implemented. The field must be absent in this source-only edition. Other package metadata is not executed. JavaScript `main`, `exports`, lifecycle script bodies and self-reported verification claims are not compiler plugins.

At most256 declared libraries, 2,048 recorded modules,128 script names/package and256KiB rendered notice text are accepted. Existing source file/aggregate/import/process budgets remain in force. Script **names** are recorded without executing or printing their command bodies.

## Evidence plan and limits

Focused tests cover raw BOM hashes, snapshot changes, transitive/duplicate imports, filesystem aliases, unused declarations, unknown semantic fields, explicit executable requests, fabricated verification claims, immutable/deterministic inventories and bounded metadata.

Installed tests reuse the existing tiny compiler/library fixture. They verify receipt/checked binding/raw hashes; compare canonical admissions before/after adding nonsemantic package metadata; set an inert package entrypoint/script sentinel that must never execute; require host notices despite a suppression request; and refuse invalid library source or unsupported execution requests without replacing an existing output. Isolated fixture bytes are restored after testing. No compiler/kernel regeneration, source migration or full self-host cycle is needed.

This is not an npm installer sandbox, dependency-range/lockfile resolver, package publisher authentication, proof of all filesystem interleavings, full axiom/effect policy or formal compiler/kernel correctness. Source hashes cover **consumed modules and captured manifests**, not a whole-package SBOM. Built-in compiler/kernel/target tools are separately identified by existing receipts and are not counted as third-party extensions.

npm can execute lifecycle scripts during installation and packaging independently of PSC0; `installationHistory: "not-observed"` is deliberate. See the official [npm lifecycle documentation](https://docs.npmjs.com/cli/v11/using-npm/scripts/). The distinction between process output streams follows [Node's stderr documentation](https://nodejs.org/api/process.html#processstderr). Neither source-only import nor a no-executed-extensions inventory certifies a preceding installation safe.

Read `AI_WORK_STATE.md` and the later qualification record for actual run results; design text alone does not establish validation success.
