# PSCV V6 — Lean-native compiler packages

**Status:** Initial Lean-native implementation foundation. Not a conformant PSCV compiler, a PSCV-certified executable, or a publicly published npm suite.

All compiler implementation and extension policy is written in **Lean 4**. A pinned Lean 4.35.0-rc3 compiler builds the native P0 tool. npm transports source modules and, later, per-platform prebuilt native tools. npm does not implement the compiler in JavaScript.

## References

- [Lean-native reuse research and migration](LEAN_NATIVE_REUSE_RESEARCH.md): existing Lean code inventory, reuse plan, package design, version tradeoffs and soundness risks.
- [V6 target compiler reference](../THE_PSCV_COMPILER_REFERENCE_VERSION_6.md).
- [Normative PSCV language reference](../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md): specifies .ps syntax and verified profiles. Lean is the implementation language, not the .ps grammar.
- [Core architecture and security criteria](CORE_NPM_ARCHITECTURE.md).

## Active Lean source packages

| Candidate npm package | Source | P0 capability |
|---|---|---|
| @proofscript/pscv-core | packages/core/src/Pscv/Core | lightweight Init-only source/profile contracts |
| @proofscript/pscv-extensions | packages/extensions/src/Pscv/Extensions | E0–E6 policy in Lean; no plugin code execution |
| @proofscript/pscv-kernel | packages/kernel/src/Pscv/Kernel | Lean 4.35 build-host kernel admission |
| @proofscript/pscv-cli | packages/cli/src | native development executable |

All four are **private development npm manifests** and ship Lean sources rather than handwritten compiler .mjs implementations. A future release will package compiled native executables and platform libraries. Node is optional for npm tooling, not necessary to run the native executable.

### Native build

From pscv0/v6 with the pinned Lean toolchain installed:

    lake build PscvCore PscvExtensions PscvKernel pscv_v6_dev pscv_v6_native_tests
    lake exe pscv_v6_native_tests
    lake exe pscv_v6_dev --version
    lake exe pscv_v6_dev core-smoke
    lake exe pscv_v6_kernel_dev kernel-empty-smoke

Tests check a real logical identity theorem and reject an incorrect proof body, and enforce extension restrictions. Separate CI calls the copied native/Wasm pskernel-lean 4.34 npm packages as **independent oracles**; their identities are not silently treated as the 4.35-rc3 checker.

### Not implemented yet

.ps frontend, source-to-Core fidelity, normative Standard manifest, .proof.ps/.proof.lean proof closure, PSCV-CERT, erasure, four backend packages, extension sandbox, release packaging, semantic preservation. The native development CLI rejects unsupported compilation.

There is no requirement to keep old PSC1/self-host source restrictions. Reuse existing Lean code selectively when it materially reduces work and preserves explicit correctness boundaries.

## Lean native binary-size research

Measured on Linux x64, the earlier CLI was 118.48 MB unstripped because its default Core model imported Lean.Declaration. After isolating those logical types and the checker in a separate native package, the **same Lean 4.35 toolchain built the new compiler CLI at 4.41 MB unstripped (4.15 MB debug-stripped; approximately 1.1 MB compressed npm tarball)**. The separate checker remains approximately 118.49 MB unstripped. This is a real size improvement, not evidence of completed .ps compilation. See the [measured source-import analysis](LEAN_NATIVE_REUSE_RESEARCH.md) and [successful CI](https://github.com/dwijayuda/pskernel/actions/runs/37760292461).

## Lean kernel packages copied directly into V6

The following complete provider packages are copied **byte for byte** from the already-working PSCV workspace, including their Lean provider sources, official kernel source snapshots, compiled native/Wasm binaries, pinned metadata, and npm compatibility adapters:

- [packages/pskernel-lean/](packages/pskernel-lean/) — @proofscript/pskernel-lean@4.34.0 (native).
- [packages/pskernel-lean-wasm/](packages/pskernel-lean-wasm/) — @proofscript/pskernel-lean-wasm@4.34.0 (Wasm).

Their original provider contracts, version pins, prebuilt integrity checks, and historical JS transport adapters are **unchanged**. Keeping an existing Node wrapper in these copied packages is an interim integration detail; the new PSCV compiler and extension policy continue to be implemented in Lean, and the normal native compiler must not silently depend on Node.

From this V6 directory, `npm install --ignore-scripts` links both local copies as npm workspaces. Run `npm run check:kernel-package-copies` to verify prebuilt artifacts and `npm run test:provider-oracles` to exercise real native/Wasm admission acceptance/rejection. A Lean-written `Pscv.Kernel.ProviderCatalog` lists exact package identities; `lake exe pscv_v6_dev providers` shows them without loading the full checker in the lightweight CLI.

These packages **can check the bounded Lean 4.34 kernel admission protocol**. V6's normative reference is Lean 4.35.0-rc3, so they cannot be promoted to 4.35 PSCV verified authority without matching versions or independently checked compatibility, complete specification/obligation closure, and the V6 KernelContract/PSCV-CERT gates. Native compiler checked-session transport integration remains a future implementation step.

Reuse of existing `.lean` compiler source and backends is explicitly welcome where correct; V6's reference remains the architecture authority. There is no requirement to preserve the old self-host composition or naming merely because source is reused.
