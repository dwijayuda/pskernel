# PSCV V6 — fresh kernel-first npm core

**Status:** P0 architecture and runnable npm package slice, not a complete or verified PSCV compiler.

This folder is a new implementation. It does **not** import the old PSC2 compiler, self-host frontend, JS checked-service or old backend drivers. Their interfaces are not a V6 compatibility requirement. The only runtime reuse currently planned for the first checking capability is through the published npm APIs of the existing Lean 4.34 native and Wasm kernel packages.

Read [Core npm architecture](CORE_NPM_ARCHITECTURE.md), the [V6 reference](../THE_PSCV_COMPILER_REFERENCE_VERSION_6.md), and the [normative language reference](../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md).

## Package boundaries

- [pscv-extensions](packages/extensions/README.md): extension metadata, explicit activation, deterministic fingerprinting; no execution or trusted semantic changes.
- [pscv-kernel](packages/kernel/README.md): exact native/Wasm official Lean 4.34 provider selection, admission validation and kernel decision.
- [pscv-core](packages/core/README.md): profile-scoped compiler composition skeleton, source identity and kernel admission check.
- [pscv-cli](packages/cli/README.md): experimental Node development CLI, not the production standalone PSCV compiler.

## Develop

From this directory:

    npm install --ignore-scripts --no-audit --no-fund
    npm test
    npm run pack:dry
    node packages/cli/bin/psc-core.mjs capabilities

Integration CI additionally exercises real native and Wasm Lean kernel providers from the existing package artifacts.

## Claim discipline

Source inspection only hashes bytes. Kernel admission acceptance is not proof of source-to-Core fidelity, PSCV proof closure, program correctness, or backend semantics. build() and verify() reject until real implementations exist. The current provider pin is Lean 4.34, whereas normative PSCV V6 targets Lean 4.35.0-rc3; the version mismatch blocks full PSCV certification claims.

These are npm-packable development artifacts. They have not been published to the registry, do not implement the full compiler, and are not a certified release.
