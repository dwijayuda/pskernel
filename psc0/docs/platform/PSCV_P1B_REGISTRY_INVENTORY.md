# PSCV P1-B registry inventory and Standard surface mapping

**Status: qualified exploratory P1-B extraction and mapping inputs. NOT a frozen PSCV Standard environment, not PSCV-CERT-v1, no executable admission.**

## Recorded source and semantics identity

Exact PSCV-RC-v2 normative reference SHA256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`; Lean semantic pin `4.35.0-rc3`, commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. The currently selected PSC0 compiler/core remain pinned independently to the historical Lean4.34 environment; the concurrently refined PSKernel Core RC4 branch is not a substitute for this RC3 normative pin.

## 1. Observed actual imported Lean registries

`PSCVL/RegistryProbe.lean` imports PSCVL.Policy in the real pinned Lean 4.35.0-rc3 toolchain and retrieves actual environment-extension data through Lean native APIs; it does not infer registrations from source `@[simp]` tokens. It records observed instances with priorities, default instance groups, simp theorem origin names/unfoldable declarations, built-in/local simprocs, and selected grind ext/case sets. The module is run only in cloud CI via `lake env lean --run RegistryProbe.lean ...` and emits `psc-lean-ambient-registrations/0`.

At qualifying source commit `1cb7d874c37bd30d69f2482981a31e940ed581ed` the real imported environment contained:

| Observed category | Count |
| --- | ---: |
| Instances | 9,742 |
| Default-instance classes | 28 |
| Simp theorem origins | 20,786 |
| Unfoldable simp declarations | 46 |
| Built-in simprocs | 390 |
| Local simprocs | 0 |
| Grind extensionality names | 17 |
| Grind cases categories | 13 |

These are **ambient Lean and PSCVL.Policy implementation registrations**, including entries that the closed PSCV Standard language MUST NOT implicitly activate. In particular, the observation is neither the PSCV requested 194 snapshot IDs nor a proof of their resolution. Hash-map name sorting makes audit bytes deterministic; it does NOT reproduce priority ties, import visibility, active scope, or the precise Lean class-instance solver search order.

Node validator `packages/pscv/src/ambient-registry-inventory.mjs` refuses missing or forged schema fields, unauthenticated semantic pins, bogus completion flags, and malformed values. Its report has protocol `psc-ambient-registry-inventory/0`, identity SHA256 `07d84ebf5aafe1c581a32b9ca0022ffe1b3985f7a3e002fece939a3460997a61` and all Standard certification flags false. CI retains both raw Lean JSON and canonicalized review output. A hash of that observation is identity evidence, not a verification certificate.

## 2. Normative required overloaded surface — source-owned, unresolved

`packages/pscv/src/required-standard-surface.mjs` extracts **every** row from §24.3 of the exact hash-checked normative RC-v2 reference: **230 distinct type/operator/literal rows**, containing **194 distinct referenced snapshot IDs**. It records the guaranteed type/operator family and required IDs, while each mapping has `entryResolution: not-extracted`, `sourceLocator: null` and `semanticallyValidated: false`.

Source worksheet identity SHA256: `cf9b7ff27263332eb00903a26e6c48019f22c0793f77de215120684a3c904f56`. It is `psc-required-standard-surface/0`, NOT `STD-ENV-PSCV-V1-L435RC3-RC1.json`. Table rows identify semantics the eventual profile MUST supply but do not establish that Lean's imported environment selects the correct constants, instances, overloaded procedures or precedence.

The generator `packages/pscv/scripts/generate-required-standard-surface.mjs` always reads the exact Git blob for the normative document, avoiding Windows worktree line-ending re-encoding. The validator rejects changed source SHA, duplicate/extra rows and inferred authority. The resulting worksheet is stored inside the Actions evidence ZIP alongside the ambient snapshot; it is never shipped as an approved runtime profile.

## 3. Unresolved P1-B requirements, individually release-blocking

- **Instance/default-instance ordering:** capture correct environment scoped and imported entries, class parameter modes, priorities, equal-priority resolution and matched source locators. Alphabetically sorted observed names are NOT search order.
- **Coercions and instance-dependent overload resolution:** extract exact active registry and context, map all required overload snapshot IDs, reject absent/ambiguous mappings and forbidden implicit declarations.
- **Simp and simprocs:** capture actual registered declaration/theorem *entries* (not only origin names), pre/post/inversion, priorities, filters and activation order; exclude unapproved imported entries. Built-in procedure provenance must be pinned.
- **Ext/grind and tactic registry:** resolve all active entries, patterns, priorities, source-line provenance and the frozen Standard tactic grammar, not just grind ext/cases names.
- **Verified-effect registry:** generate specific PSCV-VERIFY-v1 WP-operation and law evidence, approval and clause registry, not ordinary Lean imports.
- **Provenance:** every included entry requires matching pinned Lean source path, Git blob SHA, exact source line/symbol, and any special class-mode locator.
- **Normative authority:** produce the complete canonical ordered Standard manifest with stable SHA256, explicitly review and publish that digest in a subsequent approved normative revision, and execute semantic positive/negative conformance tests against its exact identity.

Only then can the project attempt to activate `pscv-v1`. Until then the private `@proofscript/pscv` candidate has no executable entrypoint, and the supervisor-side PSCV-CERT-v1 entrypoint rejects any attempt to authorize `VerifiedExecutableModule`. The qualified ordinary compiler remains checked-only.

## 4. Qualification and exact evidence

All **six** jobs passed in [run 38050837575](https://github.com/dwijayuda/pskernel/actions/runs/38050837575), attempt 1 at source commit `1cb7d874c37bd30d69f2482981a31e940ed581ed`: Linux Node22, Linux Node26, Windows Node26 each passed 23 Node tests (69 combined); separate real Lean RC3 contract preflight, pinned Lean source-provenance 40-blob audit, and new real Lean environment registry observation succeeded. None creates an executable or PSCV certificate.

[Download ambient inventory + required surface worksheet](https://github.com/dwijayuda/pskernel/actions/runs/38050837575/artifacts/11669157884) (ZIP SHA256 `c2f07942b7012cfb89e4ad8910bd1b704b663f2a96fc361436433cb25a4eb5a7`; expires 9 November 2026 12:08 UTC). [Download pinned source provenance](https://github.com/dwijayuda/pskernel/actions/runs/38050837575/artifacts/11669657062) (ZIP SHA256 `915dfe9c774a184bb4b41e3e85369013f0be3d0baa4d8b2f7a2421224eddb2f1`).

No change to the qualified 62-module TypeScript self-host compiler, retained authoring seed, public `psc` host, kernel algorithms, selected native Core source `963030dc2d154008fccc82e7c8ed29331f138799`, Node/TS7 release pins or main branch. No npm publication. Continue cloud/GitHub only, with non-force leased commits and no Desktop Commander.

## 5. Next implementation

**P1-B continuation:** build exact deterministic registry-entry extraction under the bounded **closed** PSCV environment, including actual search/activation order and source-line provenance; map the 194 snapshot IDs to exact Lean declarations or PSCV-owned operations, and separately freeze the WP/effect registry. Keep each remaining type/kind explicitly unresolved until its evidence is independently checked.

**P2 after P1-B:** one approved pure contract with complete mandatory VCs, real kernel-checked evidence, transitive axiom/effect/import closure, ghost/erasure proof and protected certified artifact handoff. Do not replace missing evidence with a 'verified' metadata flag.
