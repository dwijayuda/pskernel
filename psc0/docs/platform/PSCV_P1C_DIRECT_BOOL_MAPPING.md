# PSCV P1-C: source-audited Boolean mapping and runtime separation

**Status:** Qualified partial mapping, not a complete/frozen Standard registry or an executable-soundness proof.

## Basis and exact source

Uses the canonical PSCV-RC-v2 source (SHA256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`) and exact Lean **4.35.0-rc3** commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. §24.3 contains 230 overloaded surface rows referencing 194 unique snapshot IDs. Three are exact direct Boolean declaration IDs; 191 are `std.*` and remain unresolved.

The pinned Appendix K.1 `src/Init/Prelude.lean` Git blob SHA1 is `f87ee970af5149d74434f09a89aedff1a8fdb2d2`; raw byte SHA256 `cc9f337a5d8bd00768121701bceb0661ac63e01831a9aa34b282f37c689a6c39`. In the exact pinned source, the public `Bool.or`, `Bool.and`, and `Bool.not` are `noncomputable def`s. Lean provides separately declared `Bool.Internal.or`, `.and` and `.not`, and equality theorems tagged `@[csimp]` linking those public and internal symbols. These are **not** automatically backend-preservation theorems for PSCV/TS or Wasm.

| Source-required ID | Logical declaration line | Internal implementation line | Equality theorem line |
| --- | ---: | ---: | ---: |
| `Bool.or` | 1053 | 1056 | `Bool.or_eq_internalOr` line 1098 |
| `Bool.and` | 1071 | 1074 | `Bool.and_eq_internalAnd` line 1094 |
| `Bool.not` | 1086 | 1089 | `Bool.not_eq_internalNot` line 1102 |

All three entries are verified against immutable Git **blob and source bytes**, not Windows worktree line-ending transformations. The Lean `RegistryProbe.lean` additionally checks that each logical constant, internal constant and equality theorem exists in the actual imported environment and that each public declaration carries the noncomputable marker. The source auditor requires the exact theorem proposition text `Eq Bool.<op> Bool.Internal.<op>`. It does not independently replay imported Lean proof terms in PSKernel Core and does not establish correct JS/TS/wasm lowering or runtime semantics.

## Implementation

- `PSCVL/RegistryProbe.lean` emits three strongly identified `directBool` observations, each with present/noncomputable flags, the internal declaration, and actual Lean theorem presence. All semantic/emission flags remain false.
- `psc0/packages/pscv/src/ambient-registry-inventory.mjs` now validates directBoolean data rather than trusting a package-supplied `BooleanSupported: true` flag. It rejects missing/false logical noncomputable declarations, absent equality theorems, changed names, forged runtime equivalence, extra identities, and fake PSCV certification.
- `psc0/packages/pscv/src/direct-bool-mapping.mjs` joins the canonical reference §24.3 source IDs, the authenticated Appendix K.1 provenance root, raw pinned Lean source lines, and the observed imported environment into a **mapping review**. It reports exactly three source-located mappings and 191 unresolved IDs. The flags `runtimeBridgeQualified`, `independentlyKernelReplayed`, `allowedInClosedStandard`, `completeStandardEnvironment`, `verifiedExecutableAuthorized`, and `pscvVerified` remain false.
- `psc0/packages/pscv/scripts/audit-direct-bool-mapping.mjs` runs only in GitHub CI, verifies exact git commit, tree/blob identity and unmodified normative bytes, then writes source-located review evidence. It is not a compiler plugin or profile activation path.

## Qualification

Cloud GitHub Actions [run 38052355776](https://github.com/dwijayuda/pskernel/actions/runs/38052355776), attempt 1, all **six** jobs passed at source commit `3153fe5732794f2e96cde994085b9a2ec28acfa9`. Linux Node22, Linux Node26 and Windows Node26 each passed **26/26** unit tests (78 combined); actual Lean imported-environment registry observation and direct mapping, pinned 40-source provenance audit and positive/negative Lean contract preflight all passed. No new language compiler, kernel or backend code was compiled or selected.

The mapping evidence SHA256 is `c9e5dce7f97646779dc8a00d5c441226550a353190c9ebbe7c9b1aac70c70b9d`. Source/declaration audit archive: [artifact 11670325503](https://github.com/dwijayuda/pskernel/actions/runs/38052355776/artifacts/11670325503), ZIP SHA256 `cf62cc227fd79ca1fe6f64bf8eb0d7b787e8f13a76d271ff340ef5d8ddd51ee6`. Pinned original source-provenance archive: [artifact 11670400315](https://github.com/dwijayuda/pskernel/actions/runs/38052355776/artifacts/11670400315), ZIP SHA256 `d33e06c8314c35ffdab734162e4abfe99ff5fd4d7c784632db42d63020e90f5d`. Both expire 9 November 2026 UTC; GitHub release publication and durable binary retention remain future work.

## Remaining 191 snapshots and next implementation

The other **191** referenced snapshot IDs include direct basis class/operation requirements and common class-instance provider IDs such as `std.generic.hadd`, numerical `std.int*/uint*` and `std.nat` families. These are **specification identifiers**, not necessarily literal Lean declaration names. Do not infer one-to-one mapping by spelling or enable every imported Lean instance; the pinned environment has 9,742 instances and 20,786 simp origins that are much larger than the closed Standard profile.

Next, build a typed, semantic-class-candidate resolver: inspect actual Lean `InstanceEntry` value/type, class-head arguments, priority, synth order and scope; connect only explicit required basis-type/class obligations to candidate constants, resolve exact source provenance and reject ambiguous or unresolved lookup. Then construct and check a properly ordered closed whitelist, the seven Standard registries, class parameter modes, source locations, and WP/effect laws. Only after a complete, independently conformance-tested manifest and approved normative digest may profile selection be considered. An actual P2 PSCV-CERT-v1 still requires separately justified VC completeness, PSKernel proof replay and runtime translation/erasure evidence.

**No change** to existing 62-module self-host compiler, authoring seed, selected native PSKernel Core, TS7 backend, current checked-only `psc` build or npm release. Workstream remains cloud GitHub-only; preserve concurrent kernel/metatheory branches and expected-HEAD writes.
