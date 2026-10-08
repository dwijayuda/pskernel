# PSCV0 V6 architecture map

**Status:** implementation migration staging document. Read [V6](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) and the [normative PSCV reference](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) for rules; this file is only an ownership guide.

## Desired shape

- Native `psc` built using Lean 4/Lake at **build time**. Standalone default operation must not require installed Lean/Lake/elan or npm.
- Native `.ps` frontend, provider-neutral checked Core, approved specifications, proof/erasure gates, strictly validated runtime IR, four first-class TS/JS/Wasm/Rust backends.
- Proofs in `.proof.ps` and/or optional `.proof.lean`; the latter use an isolated official Lean integration and require a checked proposition/semantics bridge.
- npm-first package delivery for compiler, libraries, proofs, optional extensions and target artifacts, with semantic/proof locks independent of npm integrity.
- Self-hosting preserved as an optional **later** evidence lane, not a blocker to a native standalone implementation.

## Transitional source layout

| Directory | V6 implementation reuse | Current boundary |
|---|---|---|
| `packages/` | compiler/frontend/Core/IR/backends, providers, CLI | Still includes older bootstrap and driver compatibility code required by Lake and tests |
| `host/` | native compiler composition | Native checked-service equivalence not yet established |
| `scripts/` | existing JS checked-service, capability/authority bridge and regression tooling | May contain legacy self-host scripts; selectively retire only after import-closure checks |
| `contracts/` | typed evidence, artifact, backend, interface, security and pass contracts | Legacy version IDs require explicit V6 revisions |
| `test/` | preserved regression and negative-conformance tests | Historical test success does not establish V6 conformance |
| `theory/`, `lean-checked/` | formal assurance and optional Lean checker integration | Not full `.lean` proof-bridge implementation |
| `stdlib/`, `savef/`, `factory/` | library, evidence reuse and factory foundation | Must stay outside source/kernel authority |
| `legacy/` | immutable historical materials | Not a production import root |

## Known blockers

1. The bootstrap native `psc check` path and JS production checked service have different checking/certification guarantees.
2. Exact PSCV Core to Lean proposition/program correspondence for `.proof.lean` remains an implementation and assurance obligation.
3. Standalone release packaging, correct platform runtimes, semantic-aware npm libraries and safe extension execution have not been validated.
4. Full V6 language/backend correctness and formal preservation have not been established.
5. Normative Standard-environment manifest regeneration/digest remains a separate release gate.

## Migration discipline

Preserve V5.1 invariants and historical evidence. Change sources or release claims only in separately reviewed implementation steps with typed pass contracts, checked provenance and fail-closed certified emission. **Do not** delete any transitional code solely because its name includes "selfhost" or "old" while it remains imported. For history see [legacy/ARCHITECTURE.md](legacy/ARCHITECTURE.md) and [legacy/AI_WORK_STATE.md](legacy/AI_WORK_STATE.md).
