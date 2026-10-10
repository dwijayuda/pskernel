# PSC0 PSCV P1-I — immutable upstream source modules and explicit instance candidates qualified

**Qualified source `f408f374ab6b4484dd79923806b01094b9364b8a`:** [run 38058712867](https://github.com/dwijayuda/pskernel/actions/runs/38058712867), all **4** jobs successful including exact Lean4.35rc3 original selected declaration types and pinned Git source blob inspection on Linux and Windows review. Exact upstream Lean commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. Three Git blob identities: Prelude `f87ee970af5149d74434f09a89aedff1a8fdb2d2`, String.Defs `f2502b701ef21070b4eaaefe6642ee8d7e58cede`, Int.Basic `13eb3c86d79160bb9bda2edd33772d6d4439ce0c`. For **11** imported constants, **6** unique explicit named-instance lexical line candidates, **5** module-only. Machine evidence [pscv-p1i-qualification-2026-10-10.json](docs/platform/pscv-p1i-qualification-2026-10-10.json), report SHA256 `b640f6295926272724fb922f55d4d433bdfe23f5f7971713c219a99ba7da748a`, [artifact 11671518917](https://github.com/dwijayuda/pskernel/actions/runs/38058712867/artifacts/11671518917). Draft [PR #104](https://github.com/dwijayuda/pskernel/pull/104), stacked on P1-H.

**No source-to-Core elaboration proof, no imported instance-selection ordering theorem, no approved Standard mapping.** Exact source-module/blob/lexical matching is diagnostic: selected Lean constants may have compiler-generated names. Of 194 required IDs, only previous 3 Bool source locations have the P1-C evidence; **191** remain unresolved. P2–P5 source/proof/erasure/backend/release stages still gated by [P1_TO_P5_SOUND_GATES.md](docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md). The next useful P1 work is a scalable typed per-operator resolver and closed Standard registry selection; do not add more arbitrary seven-item probes. Compiler/TS7/self-host seed, selected native Core and production certification gate unchanged. GitHub/cloud only, preserve live branch history and expected-HEAD writes.

---

# PSC0 PSCV P1-H — imported declaration type and module origin evidence qualified

Qualified source `f5a5322db8f9493df6be27a425239cd5e5f6d43c`, [run 38058186775](https://github.com/dwijayuda/pskernel/actions/runs/38058186775): four jobs passed (Linux22, Linux26, Windows26, actual Lean4.35.0-rc3). Eleven imported constant types and module identities observed; nine arise from `Init.Prelude`, one each from `Init.Data.String.Defs` and `Init.Data.Int.Basic`. Report SHA256 `8246970bdb3a79da9879bca1b191c5ddcd552589a54e4ef11a33cca6447925c5`; [artifact 11671233631](https://github.com/dwijayuda/pskernel/actions/runs/38058186775/artifacts/11671233631). [Qualification JSON](docs/platform/pscv-p1h-qualification-2026-10-10.json). Branch `psc0/platform-pscv-p1h-declaration-types-v1`, [draft PR103](https://github.com/dwijayuda/pskernel/pull/103) stacked on P1-G.

P1-H does not establish exact source file/blob/line for individual instances or their generic dependencies, complete Standard instance search, source-to-runtime refinement, or any P2 certificate. Normative requirements still: 230 rows /194 snapshot IDs, only previous three direct Bool source-located, 191 unresolved. Continue with exact pinned Lean Git file/blob source provenance for the observed modules and lexically explicit declarations, then a scalable elaborator-driven resolver. Compiler, kernel, TS7 release, authoring seed and certification gate unchanged. P2–P5 remain sound-gated. Use GitHub/cloud only, expected-HEAD ref updates, no history rewrites.

---

# PSC0 PSCV P1-G — exact required-ID work ledger qualified

Source commit `76bcf6f01cec41e36b736e548f98bca862ec5877`, [run 38057594392](https://github.com/dwijayuda/pskernel/actions/runs/38057594392): **all 4 cloud jobs passed**, including pinned Lean4.35.0-rc3 P1-E/P1-F witness regeneration and Linux22/Linux26/Windows26 negative tests. Artifact [11671753807](https://github.com/dwijayuda/pskernel/actions/runs/38057594392/artifacts/11671753807), ledger digest `e562efe944af9a55eff7c2960fd2a143877cf9ec6c85a5e7b826983ade74b8c0`.

P1-G supplies a reusable requirements ledger of **230 source surface rows / 194 snapshot IDs**, 7 observed pilot rows, three previously source-located direct Bool IDs and **191 still unresolved** mappings. The source-scope and instance-mapping flags remain false and no PSCV-CERT-v1 or verified executable is available. Compiler, selected native kernel, TypeScript7, seed and release source unchanged. Working branch `psc0/platform-pscv-p1g-coverage-ledger-v1`, draft [PR102](https://github.com/dwijayuda/pskernel/pull/102), stacked on P1-F. [Qualification JSON](docs/platform/pscv-p1g-qualification-2026-10-10.json) and [work ledger technical summary](docs/platform/PSCV_P1G_STANDARD_WORK_LEDGER.md).

**Next root cause:** actual machine-readable Lean declaration type and pinned source-module/line provenance for selected dictionaries, followed by scalable typed resolution of all 191 unresolved IDs and close-scoped ordered Standard registries. Never map a normative ID by name alone. P2–P5 stay subject to [the sound gates](docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md). GitHub cloud only, preserve concurrent branch history, verify HEAD/lease before writes. No bulk package renaming or kernel changes.

---

# PSC0 PSCV P1-F — concrete imported Lean dictionary selections qualified

**Qualified P1-F source:** `d8a8e2a9b5d4ab2294316af74671a02af1815ce0`. [Run 38056463990](https://github.com/dwijayuda/pskernel/actions/runs/38056463990), attempt 1, all four jobs passed: Linux Node22/Node26, Windows Node26 unit and negative review, plus real pinned Lean 4.35.0-rc3 synthesis/typechecking. Seven selected terms: `instAddNat`, `instMulNat`, `instSubNat`, `Int.instAdd`, `instDecidableEqNat`, `instDecidableEqBool`, `instAppendString`. Non-authoritative evidence SHA256 `215f6e60a0319320690035dbbfa34deb812c53466f53f6dd8892daa99757cc29`; [artifact 11670981656](https://github.com/dwijayuda/pskernel/actions/runs/38056463990/artifacts/11670981656), ZIP SHA256 `fb38e67c7eb9cdf9dd26ba17eb0b7f910f35c42c4641aed25e4d3e47e777237a`.

No generic→concrete dependency graph, class/basis/source-line proof, scoped tie resolution, backend equivalence or closed normative PSCV registry is claimed. The 191 remaining required snapshot IDs are **still unresolved**. Compiler/kernel/seed and production PSCV refusal are unchanged.

Branch `psc0/platform-pscv-p1f-concrete-dictionaries-v1`, [draft PR #101](https://github.com/dwijayuda/pskernel/pull/101), stacked on qualified P1-E PR100 and P1-D PR99. The next useful P1 work is an **automatic typed class and source-provenance resolver** for the complete normative snapshot inventory, with Lean elaborator checks and controlled registries, not another handful of name-only probes. P2–P5 remain gated by [sound acceptance criteria](docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md).

---

# PSC0 PSCV P1-E — typed instance witnesses qualified

**Qualified P1-E source:** `07daca7e83950a5ad242369dd2f131aa7c249d86`. [Run 38055826619](https://github.com/dwijayuda/pskernel/actions/runs/38055826619), attempt 1: all **four jobs successful** (Linux Node22, Linux Node26, Windows Node26 strict tests, plus actual Lean4.35.0-rc3 witness elaboration). Typed observation digest `0a5cdad32ace1492158fab973a9da60d9b430ff529c71a9804e415e80efea712`. [Observed Lean transcript and non-authoritative review](https://github.com/dwijayuda/pskernel/actions/runs/38055826619/artifacts/11671591053); artifact ZIP SHA256 `12d4d529be5c4783c119f0f62d485ad39e730872606c97cbb82cd90090b0a10a`.

Actual imported selections: `instHAdd`, `instHMul`, `instHSub`, `instHAdd`, `instAppendString`, `instBEqOfDecidableEq`, `instBEqOfDecidableEq`. Generic selection is not a proof of the underlying concrete `Add Nat`, `Mul Nat`, or `DecidableEq Nat` dictionary mapping to a required PSCV `std.*` ID. **3** direct Boolean IDs remain source-located; **191** required IDs remain unresolved. No Standard freeze, P2 certificate, or verified executable.

Branch `psc0/platform-pscv-p1e-typed-resolution-v1`, [draft PR #100](https://github.com/dwijayuda/pskernel/pull/100), stacked on P1-D PR99. No compiler, release, selected kernel, self-host seed or certification gate changes. The full P1 closure and P2–P5 work remain outstanding. For sound gating see [P1_TO_P5_SOUND_GATES.md](docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md).

---

# PSC0 PSCV P1-D — imported instance result-class review index qualified

**Qualified source:** `80570393844e08876c3356c553845b6f89846b88`. [GitHub Actions run 38053043569](https://github.com/dwijayuda/pskernel/actions/runs/38053043569), attempt 1, all six jobs passed: Linux Node22, Linux Node26, Windows Node26 each **29/29** tests (87 unit tests), actual Lean4.35.0-rc3 imported environment/class-head probe, 40-root source provenance and positive/negative Lean contract preflight. Branch `psc0/platform-pscv-p1d-classes-v1`, [draft PR99](https://github.com/dwijayuda/pskernel/pull/99) stacked on qualified P1-C PR98. No npm publication/merges/core/seed/compiler changes.

## Implemented

- `PSCVL/RegistryProbe.lean` now reads each actual Lean imported `InstanceEntry` from `PSCVL.Policy`: declared type's **syntactic result-class head** after Pi elimination, registered priority, `synthOrder` array and imported/module status. This is type/declaration observation, not definitional equality, solver success, scoped instance search or complete provenance.
- Strict `packages/pscv/src/ambient-registry-inventory.mjs` validator refuses fake class-head, import and synthesis-order metadata while preserving previous Boolean source audit, source pin, required-surface and non-certifying status.
- `packages/pscv/src/instance-class-index.mjs` and cloud generator group all actual imported instance declarations by class-head, preserving a candidate-only review index. Entries are sorted for display by priority/name and **not** labeled Lean's real scoped/imported equal-priority synthesis order. No source snapshot ID is automatically assigned to a class or proof authority.
- Real pinned environment: **9,742 registered instance declarations, 411 distinct syntactic class heads, zero null heads, 9,742 marked imported**. Index SHA256 `e9512a596111f2fb095698d0704d3122e0ac1aa1074922acb18ffae5c9dc63db`; revised ambient data SHA256 `c4710a375287b8b45884b0030f1fd8055020b1e849543fae3c837ec0fca0e17c`. The normative §24.3 worksheet has 230 required rows, 194 IDs; P1-C located only 3 Bool direct IDs. **191 still unresolved**.

## Exact evidence and limitations

Qualified output [class-head index and ambient archive artifact 11670241857](https://github.com/dwijayuda/pskernel/actions/runs/38053043569/artifacts/11670241857), ZIP SHA256 `d015f8b3ec6b67b652b50a06ff44c2004af19f728e859fe7b030411b91425481`; 40-root [pinned source provenance artifact 11670701127](https://github.com/dwijayuda/pskernel/actions/runs/38053043569/artifacts/11670701127), ZIP SHA256 `f91dbd38b7069412cd6e264c7b5539fe21f5ca44071405348e0d503a01ae6698`. Both expire 9 November 2026. [P1-D technical procedure](docs/platform/PSCV_P1D_IMPORTED_CLASS_INDEX.md) and [machine-readable qualification](docs/platform/pscv-p1d-qualification-2026-10-10.json).

**Not complete P1-B/P1-D Standard freeze:** result class heads are preliminary candidate indexes only. Resolve 191 `std.*` IDs via exact basis type, class, chosen instance/constant, priority, imported scope and tie order, deterministic Lean elaboration and immutable source-line provenance; then include approved ordered default instances, coercions, simp, simproc, ext/grind and WP/verification effects in a complete frozen manifest with approved normative digest and conformance. A parsed/observed Lean import environment is far broader than PSCV's permitted Standard.

**P2 not started:** the private PSCV package has no certified language activation; `PSCV-CERT-v1` gate remains fail-closed, `VerifiedExecutableModule` cannot be constructed from these review indexes or proof hashes, and no PSCV verified executable can be emitted. The historical selected native Core and 62-module compiler self-host TS7 fixed point remain unchanged; independent Lean4.35rc4 kernel refinement is not silently selected for the normative rc3 profile.

Cloud GitHub Actions and GitHub connector-only source changes; no Desktop Commander/local checkout/build/test; preserve concurrent branches/history, check HEAD and use non-force expected-HEAD ref updates.

---

# PSC0 PSCV P1-C — pinned direct Boolean source and theorem mapping qualified

**Source commit:** `3153fe5732794f2e96cde994085b9a2ec28acfa9`. [GitHub Actions run 38052355776](https://github.com/dwijayuda/pskernel/actions/runs/38052355776), attempt 1, passed all six cloud jobs: Linux22, Linux26, Windows26 each **26/26 tests** (78 total), actual Lean 4.35.0-rc3 imported-env probe, pinned 40-root source audit and Lean contract preflight. New stacked branch `psc0/platform-pscv-p1c-mapping-v1` in [draft PR98](https://github.com/dwijayuda/pskernel/pull/98) on PR97. No npm publication or merges. **This is partial source/declaration mapping, NOT a frozen PSCV Standard environment or PSCV-CERT-v1.**

## Concrete implementation and evidence

- `PSCVL/RegistryProbe.lean` now observes the exact imported `Bool.not`, `Bool.and`, `Bool.or` logical declarations, their `Bool.Internal.*` runtime-oriented definitions and the three named equality (`@[csimp]`) theorems. The Lean source marks the public Bool functions `noncomputable`. Observing those equality theorems does not independently prove PSKernel replay or TypeScript/Wasm preservation.
- `packages/pscv/src/ambient-registry-inventory.mjs` and tests validate all three exact logical/internal/theorem names, imported presence, logical noncomputability and lack of runtime/certified permission. Forged Boolean flags, missing evidence, altered source, changed pin and false conformance claims are rejected.
- `packages/pscv/src/direct-bool-mapping.mjs` plus cloud-only `scripts/audit-direct-bool-mapping.mjs` bind the immutable `src/Init/Prelude.lean` Git tree/blob, exact source lines, required PSCV-RC-v2 §24.3 snapshot IDs and real imported Lean observations. The private report locates **3 of 194** required snapshot IDs; the remaining **191** are explicitly unresolved. It has no `allowedInClosedStandard` or `verifiedExecutableAuthorized` branch.
- Pinned Prelude source blob SHA-1 `f87ee970af5149d74434f09a89aedff1a8fdb2d2`, source byte SHA256 `cc9f337a5d8bd00768121701bceb0661ac63e01831a9aa34b282f37c689a6c39`. Mapping report SHA256 `c9e5dce7f97646779dc8a00d5c441226550a353190c9ebbe7c9b1aac70c70b9d`. Source verified via Git `cat-file`; avoid worktree newline transformations.
- Source locators: `Bool.or` logical line 1053, internal 1056, equality theorem `Bool.or_eq_internalOr` line 1098; `Bool.and` lines 1071,1074, theorem `Bool.and_eq_internalAnd` 1094; `Bool.not` lines 1086,1089, theorem `Bool.not_eq_internalNot` 1102. Source types and noncomputability distinction require qualified compiler/backend lowering before runtime evidence can be claimed.

**Retained GitHub Actions artifacts:** [actual ambient registry plus direct Boolean mapping](https://github.com/dwijayuda/pskernel/actions/runs/38052355776/artifacts/11670325503) ZIP SHA256 `cf62cc227fd79ca1fe6f64bf8eb0d7b787e8f13a76d271ff340ef5d8ddd51ee6`; [independent 40-source provenance](https://github.com/dwijayuda/pskernel/actions/runs/38052355776/artifacts/11670400315) ZIP SHA256 `d33e06c8314c35ffdab734162e4abfe99ff5fd4d7c784632db42d63020e90f5d`. Both expire 9 November 2026 UTC. [P1-C mapping procedure](docs/platform/PSCV_P1C_DIRECT_BOOL_MAPPING.md) and [machine-readable CI record](docs/platform/pscv-p1c-qualification-2026-10-10.json).

## P1-B still unfinished; next implementation P1-D

The 191 other snapshot IDs, including `std.generic.*`, `std.nat.*`, numeric `std.int*/uint*` and other operations, must be resolved using actual Lean instance class/type and priority/order, not spelling guesses. Full PSCV Standard instance/default instance/coercion/simp/simproc/ext/grind registries require complete source-line provenance, deterministic selected ordering, class-parameter modes and WP/effect law evidence. Audit/replay and an approved later normative digest remain mandatory. The independent rc4 PSKernel refinement is not silently substituted for the reference's Lean rc3 semantics.

**P2 certified pure contract is not authorized**: current private `@proofscript/pscv` remains data-only, selected native PSC0 kernel and 62-module self-host compiler remain unchanged, production `checked` build refuses PSCV, and supervisor `PSCV-CERT-v1` authorization remains fail-closed. No verified executable or artifacts issued.

**Execution constraints:** GitHub and cloud Actions only; no local checkout, Desktop Commander, kernel edits or force updates. Recheck remote HEAD before all writes and preserve PR90–98 history. Continue updating `AI_WORK_STATE.md` with exact source, CI and known gaps.

---

# PSC0 PSCV P1-B — actual Lean registry observation and normative mapping inputs qualified

**Qualification:** [GitHub Actions run 38050837575](https://github.com/dwijayuda/pskernel/actions/runs/38050837575), attempt1, all six jobs successful at source commit `1cb7d874c37bd30d69f2482981a31e940ed581ed`. Branch `psc0/platform-pscv-p1b-v1` and [draft PR97](https://github.com/dwijayuda/pskernel/pull/97) stacked on P1-A PR96. **Status:** P1-B extraction and source-coverage worksheet qualified; the *complete closed PSCV Standard registry and P2 certification are not implemented*. No branch merge or npm publication.

## What was actually implemented

- `PSCVL/RegistryProbe.lean` runs in the exact pinned Lean4.35.0-rc3 environment, imports `PSCVL.Policy` and reads native Lean environment-extension data for instance priorities, default-instance groups, simp theorem origins/unfold declarations, built-in/local simprocs, and selected grind extension/cases names. This is **ambient Lean registration data**, NOT PSCV Standard activation. It is source-incompatible with an implicit claim of complete ordered registry meaning.
- `packages/pscv/src/ambient-registry-inventory.mjs` validates the bounded observed data and rejects forged completion/certification flags, bad metadata, malformed priorities and arrays. `packages/pscv/scripts/validate-ambient-registry.mjs` saves canonical review output with every conformance/proof/verified executable claim false.
- `packages/pscv/src/required-standard-surface.mjs` reads the exact SHA-pinned normative PSCV-RC-v2 §24.3 and extracts all **230** required type/operator/literal rows and **194** unique named referenced snapshot IDs. All source-to-declaration mappings remain explicitly unresolved. `packages/pscv/scripts/generate-required-standard-surface.mjs` writes a source-owned coverage worksheet without approving any registry entries.
- No source-level/compiler folders renamed, no new public npm backend, no change to the 62-module compiler self-host closure, selected seed, native Core implementation or checked build/publication. Existing private `@proofscript/pscv` remains data-only, no scripts, no active PSCV compiler; `PSCV-CERT-v1` gate remains unavailable.

## Actual measured source inputs

The imported Lean environment had **9,742 instances; 28 default-instance classes; 20,786 simp origins; 46 explicit unfold declarations; 390 built-in simprocs; 0 local simprocs; 17 grind-ext names; 13 grind-cases entries.** Canonical observation SHA256 `07d84ebf5aafe1c581a32b9ca0022ffe1b3985f7a3e002fece939a3460997a61`. §24.3 source coverage digest SHA256 `cf9b7ff27263332eb00903a26e6c48019f22c0793f77de215120684a3c904f56`. **These are not the PSCV closed registry selection.** Hash-map sorting does not reproduce equal-priority search, scoped activation or import order.

Normative source reference remains SHA256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`, Lean4.35.0-rc3 commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. The independently advancing Core rc4 branch and platform Core4.34 baseline are unchanged and not treated as semantic substitutes.

## Qualified executed tests and artifacts

Six green jobs: Linux Node22 **23/23** tests; Linux Node26 **23/23**; Windows Node26 **23/23**; pinned Lean RC3 pure-contract preflight; pinned 40/40 source-root provenance audit; and the new real registry-observation extraction plus 230-row source worksheet. Total **69 Node unit passes**, no test failures. No PSCV executable or certificate produced.

[Download ambient registry observation and source worksheet](https://github.com/dwijayuda/pskernel/actions/runs/38050837575/artifacts/11669157884), ZIP SHA256 `c2f07942b7012cfb89e4ad8910bd1b704b663f2a96fc361436433cb25a4eb5a7`, expires 9 November 2026. [Download corresponding 40-source provenance audit](https://github.com/dwijayuda/pskernel/actions/runs/38050837575/artifacts/11669657062), ZIP SHA256 `915dfe9c774a184bb4b41e3e85369013f0be3d0baa4d8b2f7a2421224eddb2f1`. Both archives expire; committed digests are not durable binaries or approved Standard manifests.

[P1-B implementation details](docs/platform/PSCV_P1B_REGISTRY_INVENTORY.md) · [P1-B machine-readable qualification](docs/platform/pscv-p1b-qualification-2026-10-10.json).

## Still blocking full P1-B and P2

Complete, closed and **ordered** Standard `instances/default_instances/coercions/simp/simprocs/ext/grind` entries, exact source line/blob/symbol locators and non-default class-parameter-mode provenance, effect/WP verification registry, required snapshot ID resolution for all 194 IDs, deterministic conformance tests and final normalized manifest digest in an *approved future normative revision* have not been established. The existing environment-derived 9,742 instances and 20,786 simp origins are far broader than the permitted PSCV Standard closure. Never silently include all of them.

Only after those gates may P2 attempt one genuinely **certified** pure contract with independently complete required VCs, kernel-replayed proof terms, approved spec and trust/erasure/ABI closure, and a protected `VerifiedExecutableModule` transition. Do not change `allowedToEmitVerifiedExecutable`, bypass `PSC_PSCV_CERT_GATE_UNQUALIFIED`, or use preview `check-preview` as a certified source profile.

**Workflow:** always re-fetch GitHub HEAD before writes, use expected-head non-force updates; GitHub/cloud CI exclusively. Preserve concurrent kernel metatheory/refinement work, self-host seed and previous branches. Do not use Desktop Commander or local checkouts/builds/tests.

---

# PSC0 PSCV P1-A semantic source pin and read-only profile identity — qualified

**Source commit:** `829a1945a78965ed87ae3835a48642b6dcff013b`, 10 October 2026. [Run 38049559622](https://github.com/dwijayuda/pskernel/actions/runs/38049559622) passed **all five** jobs on attempt 1. Branch `psc0/platform-pscv-p1-v1`, stacked on P0 at [draft PR96](https://github.com/dwijayuda/pskernel/pull/96). Runtime/core/compiler/seed and selected release paths are unchanged. This is P1-A, not a complete P1 Standard environment or a PSCV-certified build.

## Implemented and qualified

- Exact PSCV-RC-v2 semantic source reference `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`, Lean **4.35.0-rc3** commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. Preserve the independently advancing PSKernel RC4 work as separate and explicitly unqualified for this normative profile; no silent re-pin from current PSC0 4.34 provider.
- `packages/pscv/src/lean-provenance.mjs` extracts Appendix K.1's 23 semantic and K.2's 17 prover roots, with entire normative document SHA verification and exact canonical JSON. `packages/pscv/scripts/audit-pinned-lean.mjs` verifies the upstream pinned Lean commit's actual 40 Git tree path/blob identities and reads their bytes/line counts in an isolated official Lean read-only source checkout. It does NOT activate registrations or issue a Standard registry manifest.
- Exact source audit from GitHub Actions: provenance blueprint SHA256 `23f633fa3089794fa6b3e7a34c23df2ed9ca4fa1a425afd84f5d53b43135eafb`, source audit SHA256 `d913a29822d19158c69dfd8a6bf5ac2e16a53ba2aa8a8370fc12d977df2965c0`, 40/40 pinned blobs validated. The archived source-only audit is [artifact 11669400259](https://github.com/dwijayuda/pskernel/actions/runs/38049559622/artifacts/11669400259), ZIP SHA256 `b1cc83cd212301ec01de180fbcfa4965cee508deaa9d7ff53d535ff23f263d41`, expires 9 November 2026.
- `scripts/pscv-profile-inspection.mjs`: strictly checks explicit root `pscv-v1` selection, closed/boundary policy, private candidate descriptor and normative RC3/manifest-absent identity. Rejects forged executable fields, changed semantic pin, fake registry digest, unknown keys, nonempty package capabilities, source-profile downgrades, and implicit activation. Every valid inspection reports **blocked-unqualified**, and `activatePSCVProfile` always throws.
- Previously qualified P0 proof preflight and publisher remain unchanged: only the historical production `checked` profile is accepted; no `PSCV-CERT-v1`, `VerifiedExecutableModule`, or verified executable is issued.

**Cloud tests:** Linux Node22.23.3 **16/16 passed**; Linux Node26.7.0 **16/16 passed**; Windows Node26.7.0 **16/16 passed**. Additional source audit and pinned Lean contract-preflight jobs also passed. The Windows test now reads the exact normative **Git blob** rather than a possibly CRLF-converted checkout file; no relaxation of source hash policy. The Lean preflight accepted a valid contract as UNCERTIFIED and rejected a wrong postcondition with unresolved VCs and disallowed `sorryAx`. Total five successful jobs, zero failures.

Machine evidence: [pscv-p1a-qualification-2026-10-10.json](docs/platform/pscv-p1a-qualification-2026-10-10.json). Interface and semantics notes: [PSCV_P1_SEMANTIC_PIN_AND_PROVENANCE.md](docs/platform/PSCV_P1_SEMANTIC_PIN_AND_PROVENANCE.md). P0 feature-owner map and protected supervisor boundaries remain authoritative design notes.

## Remaining P1-B and P2 blockers

**P1-B** must extract/validate/freeze actual ordered `instances`, `default_instances`, `coercions`, `simp`, `simprocs`, `ext`, and `grind` registrations; non-default class-parameter-mode provenance; and versioned verification/WP-effect registry. It must bind all entries to pinned Lean source path, Git blob and source line, test observable instance/notation/prover behavior and publish canonical SHA256 into an approved subsequent PSCV normative revision. Checking 40 source Git blobs does **not** establish those semantic registries.

**P2** needs at least one real approved source specification; independently justified completeness of pure-contract VCs; exact kernel-admitted proof evidence; axioms/effect/import/totality/erasure closure; a protected `VerifiedExecutableModule` constructor; and checked output policy. Existing PSCVL demonstrates real Lean proof preflight but does not authorize PSCV executable output, because source grammar and environment semantics remain incomplete. Do NOT promote P0/P1 advisory proposal hashes or booleans to proof authority.

**No local checkout/tests/Desktop Commander**. GitHub and cloud Actions exclusively. Preserve current proof/kernel branches and history, and check remote HEAD before any non-force leased write. Do not publish npm or merge PR96 automatically.

---

# PSC0 PSCV P0 modular ownership and verification preflight — qualified

**Date:** 10 October 2026 (UTC). **Exact qualified source and metadata HEAD:**
`c6e65c7b2333cb1ff634bdcf2f867a1c62510832`. **Cloud evidence:**
[PSC0 PSCV P0 run 38036616386](https://github.com/dwijayuda/pskernel/actions/runs/38036616386)
(attempt 1, all four jobs successful), plus
[pscv-p0-qualification-2026-10-10.json](docs/platform/pscv-p0-qualification-2026-10-10.json).
**Branch:** `psc0/platform-pscv-foundation-v1`, stacked on the T3 platform
branch `psc0/platform-t3-lsp-v1`. Draft [PR #95](https://github.com/dwijayuda/pskernel/pull/95).
No main merge, npm registry publication or changes to compiler/kernel logic.

## Decision and implemented P0 scope

- **Keep all existing source folders.** `core/`, `syntax/`, `environment/`, `meta/`,
  `elab/`, `compiler-ir/`, `erasure/`, `backend-ts/`, `pskernel-core/` etc remain
  canonical maintained paths. `pscore`, `psfrontend`, `psc`, `psbackend-ts`
  remain *logical* ownership/distribution design names. No bulk rename,
  bootstrap closure churn or forced npm package consolidation.
- [Complete feature-owner and authority map](docs/platform/PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md):
  general type theory and language forms stay in base compiler/kernel,
  proof goals/tactics belong to reusable prover/tactic components when needed,
  VC/WP and termination/effect semantics to reusable verification services,
  approved specification tooling separately, `@proofscript/pscv` as the optional
  **official closed profile composition**, and final certificate/evidence/
  executable authorization solely in the release supervisor.
- **New `psc0/packages/verification/`:** private `@proofscript/verification-internal`
  non-authoritative `psc-required-obligations/0`, proof-proposal and preflight
  contracts. Rejects duplicate/mismatched/unknown goals, fake authority fields
  and malformed/empty obligations. Even all supplied proof candidate SHA hashes
  matching a caller-provided obligation set yield **uncertified** because list
  completeness, kernel replay, approved specifications, imported/effect trust
  closure and compiler preservation have not been validated.
- **New `psc0/packages/pscv/`:** `@proofscript/pscv@0.0.0-experimental.1`
  private, data-only candidate; npm `pack --dry-run` verified only
  `README.md`, `package.json`, `profile.json` are included. `private:true`,
  no JavaScript executable/entry/install scripts. `profile.json` binds the
  existing PSCV RC-v2/reference hash and Lean4.35.0-rc3 source pin; freezes
  **no** fictitious Standard registry digest; lists no verified features and
  `allowedToEmitVerifiedExecutable:false`. Installation cannot activate
  language syntax or claim PSCV.
- **New supervisor-owned `scripts/pscv-certification-gate.mjs`:** policy
  state `unqualified`; `authorizePSCVExecutable()` **always rejects**.
  Current production `scripts/checked-build.mjs` separately still refuses
  `profile !== 'checked'`. No issued `PSCV-CERT-v1`, private
  `VerifiedExecutableModule`, proof handoff or verified executable artifacts.

## Qualified executed evidence

Cloud workflow [`psc0-pscv-foundation.yml`](../.github/workflows/psc0-pscv-foundation.yml)
(at runtime commit c6e65c7) passed all 4 jobs:
1. Linux/Node22.23.3: 10 proposal/gate unit tests passed, no failures;
   inspected private npm tarball inclusion and unchanged compiler/kernel pins.
2. Linux/Node26.7.0: same 10 passed; all invariant/packaging checks succeeded.
3. Windows/Node26.7.0: same 10 passed; all invariant/packaging checks succeeded.
4. Pinned Lean4.35.0-rc3 `PSCVL/`: `check-preview`
   `examples/pass_contract.ps` admitted real intrinsic/WP contract preflight
   (still UNCERTIFIED); `fail_unproved_contract.ps` rejected with
   **unproved verification conditions** and **disallowed axiom sorryAx**;
   strict bounded `check examples/normative/pass_minimal.ps` succeeded
   while reporting UNCERTIFIED. No generated PSCV executable/certificate.

**This is P0 only.** Prototype `check-preview` includes some source syntax
not conforming to the PSCV closed Standard grammar. Three passing examples
and 30 JavaScript tests do not establish complete VCG correctness,
specification coverage, PSCV v1 conformance, executable semantics or
logical consistency. Refuse publication rather than infer any of these.

Existing T3 (preview5) qualified compiler fixed point **62 modules**,
source closure `3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea`,
selected JS `6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617`,
selected native Core source `963030dc2d154008fccc82e7c8ed29331f138799`,
TS7.0.2 and authoring seed remain exactly unchanged. PSCVL reference is
Lean4.35rc3 but the separately evolving Core work targets rc4; **never
silently switch** pin/kernel/environment.

## Next milestones

**P1:** explicit rc3 versus rc4 semantic/version decision, generate/freeze
ordered Standard environment and verification registry manifests, qualify
source/profile/goal interfaces and official package activation without
letting arbitrary npm modules execute as compiler code.

**P2:** one actually **certified** pure contract, with approved formal spec,
independently justified complete VC set, kernel admitted proof, exact
axiom/effect/import/erasure closures, protected token and verified artifact
handoff. Both wrong and omitted proofs MUST block output. Do not implement
P2 by changing the Boolean in `profile.json` or by adding an unvalidated
`accept` branch to the current preflight.

**P3+** full PSCV-RC-v2 normative Appendix A grammar, complete Standard
tactics, pure/mutable control flow, effects, invariants/ghost/termination,
certified imports, general proof-service integrations, backend preservation
and conformance/proof replay. Create new folders only for concrete reusable
algorithms, not empty package placeholders.

**Workflow:** GitHub remains source of truth; use GitHub connector/MCP only
for repository mutations and Actions cloud tests. Always re-fetch HEAD,
lease writes, preserve remote history and concurrent kernel metatheory lanes.
Do not use Desktop Commander or local source checkouts/build/tests. Keep
this AI_WORK_STATE current on each checkpoint.

---


# PSC0 T3 checked editor diagnostics — completed

## T3 qualified editor queries and optional pslsp

**Checkpoint:** 10 October 2026, 06:39:22 UTC. Runtime/source commit `fe62c189aac09cdfe1c156864a329b4db5a0a9e5` passed [all six jobs in run 38031535192](https://github.com/dwijayuda/pskernel/actions/runs/38031535192), attempt 1. T3 branch `psc0/platform-t3-lsp-v1`, stacked on completed T2 in [draft PR #94](https://github.com/dwijayuda/pskernel/pull/94). T3 changes maintained host/editor JavaScript only; 62 portable compiler modules, selected R seed, TypeScript 7.0.2, and pinned native Core source `963030dc2d154008fccc82e7c8ed29331f138799` remain unchanged. No npm publication or main merge.

**Delivered:** `psc query entry.ps --stdin --json` accepts a bounded in-memory unsaved `.ps` buffer and checks declaration admission with the qualified generated compiler and PSKernel Core over its saved-import closure. It returns `psc-source-query/1` structured accepted/rejected/unavailable status and diagnostics; parser spans become UTF-16 when provided, and other failures are explicitly source-unlocated. It neither performs erasure nor target, ABI, PSCV or compiler semantic-preservation checking, and never writes output or a publication receipt. An optional separately installed `pslsp@0.1.0-preview.5` provides LSP 3.17 stdio initialize/shutdown/exit, full-document open/change/save/close and versioned diagnostics through cancellable child queries. Hover, definition, completion, project semantic indexing and VS Code integration are NOT yet implemented.

**Watch follow-up:** An inherited T2 Linux `fs.watch` race observed transient `.psc-output-lock` retirement. The fixed T3 host uses bounded 110ms content polling on both Linux and Windows, excluding compiler-owned temporary directories; source and publisher checks remain unchanged. Polling is only an advisory scheduling signal, not a guarantee of instantaneous filesystem observation or atomic multi-file visibility to other watchers.

**Executed cloud qualification:** [run 38031535192](https://github.com/dwijayuda/pskernel/actions/runs/38031535192): Linux source 143 host +18 native/integration passed; Windows source 147 host +15 native/integration passed with four inherited POSIX-only fixture skips; no failures. Four clean-install jobs: Linux Node22/26 each 48 existing +5 watch +5 LSP observations; Windows Node22/26 each 46 existing +5 watch +5 LSP. Totals **323 source/integration passes** and **228 installed observations**. The Windows Node26 job used Node 26.7.0 and npm 12.0.2. Installed tests include real in-memory valid kernel admission, syntax failure diagnostics, unsaved correction, versioning, document-close diagnostic clearing, zero TS output from query, and watch checked generations.

**Candidate archive:** [artifact 11661484886](https://github.com/dwijayuda/pskernel/actions/runs/38031535192/artifacts/11661484886), ZIP 3,908,781 bytes, SHA256 `b5849bf805567f012768d9b0967e00019bcf21fa891beeaa1e0aac108b054e1d`, expires 2026-11-09 06:37:44 UTC. Contents: `proofscript-0.1.0-preview.5.tgz` (3,665,055 bytes, SHA256 `3c59c56eaa3f23bda83708b796af520db5c7042692c27bd555d9d7c427fbb440`); `psdev-0.1.0-preview.5.tgz` (1,996 bytes, SHA256 `4d0e619661de46dc8c6e53d534a8757b4185bf482f16d961d773c7a1f96262cc`); `psc-demo-pshello-0.1.0-preview.5.tgz` (1,934 bytes, SHA256 `815ad4e1624373a90fe506581cb2c51ffeafeaaf161bd01c8104635cff0736a3`); and the optional `pslsp-0.1.0-preview.5.tgz` (its exact tarball SHA is retained in installed job LSP evidence rather than invented here). Evidence: [machine-readable T3 record](docs/platform/t3-editor-query-qualification-2026-10-10.json). Downloadable Actions artifacts expire; committed hashes are not durable executable storage.

**Usage:** Extract the candidate, install exact `proofscript` and `pslsp` tarballs locally with `npm install --save-dev --save-exact --ignore-scripts`, and launch `node ./node_modules/pslsp/bin/pslsp.mjs --stdio` from the intended project root through an LSP client. The command speaks framed JSON-RPC, not an interactive terminal. [Editor query/LSP contract](docs/platform/editor-query-and-lsp.md) describes bounds, LSP messages, source-span accuracy, privilege isolation and limitations.

**Next work:** Qualified compiler semantic query endpoints/index for hover and declaration navigation, followed by a thin VS Code client; concurrently improve packaging/licensing and durable artifact retention. Full PSCV contracts and formal proofs in `psc0/proofs/**/*.proof.lean`, generic npm source/backend/tactic extension APIs, and qualified same-source Core-JS/Core-Wasm execution remain separate future milestones. Keep native admission default until explicitly qualified replacement. Preserve branch stack PR90 → PR91 → PR92 → PR94 and all remote history. GitHub connector/MCP only for repository edits; Actions/cloud CI only for source builds/tests; no Desktop Commander/local checkouts/tests. Re-fetch HEAD before updates and use leased non-force refs.

---

# PSC0 T2 checked watch — completed

**Updated:** 10 October 2026, 05:14:26 UTC. T2 source commit **130e9501ccb39b11fe20bfe762718c9df896ebdd** passed all six jobs in [run 38026670864](https://github.com/dwijayuda/pskernel/actions/runs/38026670864), attempt 1: Linux source, Windows source, and four clean installed-package runs (Linux/Windows, Node 22.23.3 and 26.7.0). Integration branch **psc0/platform-t2-watch-v1**, stacked on qualified T1 in [draft PR92](https://github.com/dwijayuda/pskernel/pull/92). Main, selected seed R, 62-module compiler closure, native PSKernel algorithms and the TS7.0.2 pin are unchanged; no npm registry publication or merge.

### Packages and exact evidence

The [qualified preview4 candidate](https://github.com/dwijayuda/pskernel/actions/runs/38026670864/artifacts/11659064861) (ZIP 3,896,027 bytes, SHA256 0c066d5ceb6b3b0e81124a41d782b63f52f4bd78a54626e45d1fb96f575dbff6) contains:

| Archive | Bytes | SHA256 |
| --- | ---: | --- |
| proofscript-0.1.0-preview.4.tgz | 3,661,914 | 652aa526f71f1111ee4292b73c3c888840c8ece921a6aeff5e20718c71800ab2 |
| psdev-0.1.0-preview.4.tgz | 1,996 | d569a61af0f9161aa04bcc79650e903f38191c9fc69fe8d12d17f259cbf64d27 |
| psc-demo-pshello-0.1.0-preview.4.tgz | 1,934 | 66b773f77d2a2deaa968ff08617a90d7fe991fceb856d3f3c08190bef5d57b50 |

Artifact expires **9 November 2026 05:12:54 UTC**. JSON evidence is not durable executable storage. Source tests: Linux 136 host +18 native/integration passed; Windows 140 host +15 native/integration passed, with four inherited POSIX/permission-only skips. Installed jobs: Linux22 48 regular +5 watch observations, Linux26 48+5, Windows22 46+5, Windows26 46+5. Exact jobs and checks: [t2-watch-qualification-2026-10-10.json](docs/platform/t2-watch-qualification-2026-10-10.json).

### User workflow and implemented boundaries

With a private installed psdev package explicitly enabled for command:dev in project package.json, users run:

~~~sh
node ./node_modules/proofscript/bin/psc.mjs dev --watch --tsc --json
~~~

This uses the **same checked dev --once host** for each generation via bounded abortable Node child processes, and starts pinned TypeScript 7 project checking **only after** PSC admission and checked bundle/facade publication. Watch emits pending, checking, checked, ready, rejected and stopped generation states. It neither grants extension guests filesystem/proof/publication authority nor executes extension JavaScript entrypoints.

The qualified checked-library smoke created an initial generation (TS consumer 42), detected an imported-module edit (43), rejected malformed source while preserving all last accepted bundle/facade/receipt bytes, recovered after correction, and rejected a modified command.wasm while preserving prior output.

Linux uses recursive fs.watch plus periodic accepted-input freshness checks. Windows uses bounded 110 ms **content polling** for source/configuration/selected-extension inputs, because pinned Windows Node 22/26 libuv fs_event can fatally abort on alias paths. Poll caps: at most 16 nesting levels, 512 directories, 2,048 files, 2 MiB per file and 64 MiB total per snapshot. Exceeding those caps halts watch; it never weakens kernel admission. This is an initial small-project scheduling profile, not an instantaneous filesystem freshness guarantee. Source bytes and receipt eligibility are rechecked by the unchanged checked publisher.

An invalid revision leaves prior owned generated output intact; no **ready** state is emitted for that revision. A failing downstream --tsc run reports rejected, even though the preceding PSC generation was already successfully published. The supervisor coordinates its own downstream TS build; independent watchers are not promised atomically visible multi-file writes. If the entry or active extension identity changes, restart watch. Bare psc init projects do not include tsconfig.json; use --tsc in a TypeScript project or the checked-library example.

### Try on Windows PowerShell

Download/extract the candidate and from its extracted root:

~~~powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.4.tgz"
psc.cmd examples --json
~~~

Copy the installed checked-library example to a writable project directory. Inside that copied project:

~~~powershell
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.4.tgz" "$candidate\psdev-0.1.0-preview.4.tgz"
npm pkg set 'proofscript.extensions[0].package=psdev' 'proofscript.extensions[0].enable[0]=command:dev'
node .\node_modules\proofscript\bin\psc.mjs dev --watch --tsc --json
~~~

Save Quantity.ps or Main.ps to trigger new checked generations; stop using Ctrl-C. The optional extension remains inactive until explicitly enabled.

### Assurance and remaining work

Compiler portable closure is still 62 modules SHA256 **3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea**, generated compiler JS SHA256 **6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617**, selected native Core source **963030dc2d154008fccc82e7c8ed29331f138799**. The existing T1 fixed-point qualification remains valid; host-only watch did not require recompilation or seed promotion. New proofs were not established: full semantic preservation, PSCV and strict SH1 remain explicitly unproved.

Still outstanding: durable executable archive retention and public npm licensing/release; larger npm library/workspace resolution and package consolidation; generic plugin extensions; LSP/VS Code; independently qualified PSKernel Core JS then Wasm runtime candidates; later formal proof companions outside the self-host cycle. Do not silently switch the selected native provider, weaken admission, merge main, or publish npm.

---

# PSC0 T1 checked TypeScript library adoption — completed

Updated: 2026-10-10 03:14:33 UTC. T1 implementation, exact current-source compiler qualification and all six preview3 platform jobs are complete. This handoff records the qualified release source and exact artifacts; subsequent documentation commits do not replace those identities. No npm publication, main merge, seed promotion, kernel algorithm change or default-provider switch was performed.

## User-authorized scope and implementation

The user accepted T1: pure acyclic local ProofScript modules, explicit source-owned public exports, one checked project bundle, mechanically thin neighboring TypeScript facades, a handwritten TypeScript consumer, a bounded runtime ABI, and protected publication before full psdev watch. This is implemented as psc-ts-library/1. The user also asks whether the same PSKernel Core can execute as generated JavaScript before Wasm; investigate and qualify that route separately without an automatic provider switch.

Integration branch: psc0/platform-t1-v1, based on platform-v1 HEAD 4265f1d614d15fc9e6ed133a923779ba7af16db8. Draft PR91 targets platform-v1 and is stacked on PR90. Preserve the compiler and qualification slice histories.

One preparation retains exact authored source, import order and export ownership. Mandatory native admission feeds checked original RuntimeIR, an exact public descriptor, one TS bundle and neighboring facades. The ABI covers Nat/Int bigint, Bool, scalar-valid String, Unit and supported monomorphic opaque datatype/structure handles. Implicit, dependent, generic and higher-order public signatures fail explicitly. Project erasure structurally applies __ps$source$ through the existing name index; actual generated tests cover top-level/local intrinsic capture, __proto__/tag fields and private Prod construction/projection. Legacy lowering retains its empty-prefix route.

The existing publication transaction covers bundle/facade destinations, source/configuration/extension freshness, exact descriptor coverage and globally unique bindings, directory capitalization, old/new directory leases, previously owned bytes, retired facades and rollback. Its fixed staging buckets are next/, previous/ and restore/. It preserves handwritten or concurrently edited outputs; incomplete rollback retains its journal/leases/backups and no success receipt. Receipt-last publication does not establish atomic multi-file visibility, protection against arbitrary same-user filesystem races, or power-loss durability.

## Completed compiler qualification

Run 38013991001, attempt 2, at source 5fe0045dcb0bf30e1d2519f900458d1407822eed and tree 23dfb56a84cdce585e5c4b1a5ccff3b2de92f0e5 passed both compiler job114101357176 and native replay job114114935728. The first attempt stopped at the existing 180-second native full-IR process timeout; the unchanged-head rerun passed without increasing budgets or changing source. C1 passed at 02:13:19 UTC; C2/C3 fixed point passed at 02:56:18; exact-C3 T1 conformance passed at 02:56:20; native replay completed at 02:57:54.

- Portable closure: 62 modules, SHA256 3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea.
- C1/C2/C3 all retain equal canonical surface e91f3bfaaedf755b0fb027a3c6ffe752784c2f19cd41641ba8b015a90e37fe3e, normalized admissions 403d7b83ab62150a6f059cd5ed9dcfe18fd68e18f1c54cd8527abf173e20e1d5, TS 8923672fbc4b78a8bc1e25ab172162356ae4ffae6179eddc930c7955c73c1b3d and JS 6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617.
- Original RuntimeIR checking and all 12 complete public Core/IR ABI builds passed. The 87-case migration comparison retains raw reports and projects only the two exact empty legacy runtimePrefix fields under empty-legacy-erasure-namespace/1. Seven negative regression groups protect that comparison.
- Exact-C3 conformance passed all 11 recorded ownership, shared opaque identity, selected binding, runtime guard, unsupported ABI, name/field and IR-budget observations. Its canonical admissions hash is 6920fe26543ce11c9454d92154f1ee347c791bcd55bdbfdadbbcdacb296255fc and TS bundle hash is c3829e8032a2c48a633607c66499105f234feff88ffbe877723c516021cc2a40.
- Native replay accepted four deduplicated streams covering C2/C3 compiler sources, raw Lean and ProofScript capabilities, and recursive-generic fixtures. Logs identify the successful artifact11657766675 and its current C3 hash. This replay does not cover the separate T1 conformance stream; actual T1 native admission is required in platform source and installed example tests.
- Successful compiler artifact: 11657766675, 5,567,845 bytes, uploaded ZIP SHA256 8d6309b0a526b6987922ebb34cb4d5892ad48ca9e31f3bbb7dfb30ae7319754d. Older failed-attempt artifact11654548418 has the same name; release workflow pins the exact successful ID. Native replay artifact11656759460 is separate.
- The selected R reproduction is cold:false, not a new isolated cold-recovery qualification. Fixed-point equality is not a compiler semantic-preservation or logical-consistency proof; strictSh1Qualified remains false.

Exact fixed-point, generated-conformance and native-admission receipts are retained in docs/platform with run38013991001 in their filenames. Earlier focused run38010115595 at e698a663b7b86ea89987beb757c35eb555fe653c passed 63 host tests and 11 native-generated conformance observations; the current full qualification independently supplies successor evidence.

## First platform fixture correction

Release checkpoint49ab05830e34c35e8df0f51389d430e88a046b8d / run38019059404 stopped before artifact download or native assembly: the synthetic installed CLI fixture omitted checked-project.mjs from its copy list. All15 CLI cases failed at module loading, while115 other source tests passed. The actual release assembler already includes the module, whose only dependencies are node:path and node:crypto. Add that one fixture copy entry; retain all15 CLI expectations, including the already correct four-example catalog. Compiler qualification, release pins and production behavior are unchanged. Retry all platform gates.

## Windows source-shape correction

Run38019185667 at10fb98c3a3aab466073d210dd7f160da756c33eb passed Linux source130/130 host tests and18/18 real native integration, package assembly, and all four clean installed jobs (48 Linux observations each,46 Windows observations each). Both Windows jobs use PowerShell7.6.6 through npm psc.cmd with Node22.23.3/npm10.9.9 and Node26.7.0/npm12.0.2. All record real native T1 library admission,42→43 consumer rebuild, whole-generation refusal/preservation and both isolated command demos. Candidate11656994979 contains proofscript tarball SHA2560273e5f18a3cea66b0f4deaa44fbfe1214510fd59d146956355985e555c4db7e,3,656,980bytes.

The remaining Windows source job114116349238 passed135 discovered unit tests (134pass,0fail,1existing Unix-permission skip), then failed check-modular-preparation-source.mjs:82. The closed-emitter marker contains a literal LF; the only cross-platform correction is CRLF→LF in that script's read-only session-source inspection view. Keep every exact marker, the two checked emitter names, punctuation/indentation, ordering/readback and no-raw-fallback checks unchanged. Runtime source bytes, canonical admissions, receipts, compiler/backend code and release/kernel pins are not normalized or modified. The retry must reach and pass Windows native source integration and record one coherent completed platform run. Do not call the previous5/6 run wholly qualified.

## Completed preview3 platform qualification

Final release source b01281b46aa62cbb09ed47a24ebad08b72c6265f, tree d54208569a708fef53fab913ad3b11ac5a496f00. Run38019471955, attempt1, completed SUCCESS in all six jobs; GitHub run updated at2026-10-10T03:10:04Z. Root and the independent qualification reviewer read the actual completed logs and all four installed records.

- Linux Node22.23.3 source job114117024606:130 host/policy tests passed;18 real native/integration tests passed.
- Windows Node26.7.0 source job114117239372:134 host/policy tests passed,1 Unix-permission fixture skipped;15 native/integration tests passed,3 POSIX shebang transport fixtures skipped. No failures. New T1 and actual packaged native admission ran. The closed-emitter source-shape guard now passes with its exact assertions unchanged.
- Four clean installed jobs: Linux Node22/npm10.9.9 and Node26/npm12.0.2 each48 recorded observations; Windows Node22/npm10.9.9 and Node26/npm12.0.2 each46. Windows routes through PowerShell7.6.6 and npm psc.cmd. No source checkout or Lean toolchain is needed in these installed tests.
- Every installed record matches qualified compiler6ab7d603..., the proper pinned native artifact, two source modules, one bundle/two facades and shared opaque identity. Consumer starts42, imported-body edit produces43, invalid source preserves all3 artifacts and completed receipt, and handwritten facade collision refuses the whole new generation. Both optional command demos disclose actual bytes, remain inactive until configured, execute only their restricted Wasm request and refuse tampering.
- Candidate artifact11657608168:3,887,650bytes, ZIP SHA2560a202234723940b86b9370303a3ab0d952003f41a6970b332c30117afb222f04; expires2026-11-09T03:08:56Z.
- proofscript-0.1.0-preview.3.tgz:3,656,980bytes, SHA2560273e5f18a3cea66b0f4deaa44fbfe1214510fd59d146956355985e555c4db7e.
- psdev-0.1.0-preview.3.tgz:1,914bytes, SHA25620e6270726247f559129fa496aa0ae51cd0a8bf4ad679bfc99d91cb9b136e34e.
- psc-demo-pshello-0.1.0-preview.3.tgz:1,933bytes, SHA25665adbd54131fc69e4e73df08501e5f59f82fbee29b8965bde5f27f2b577c4ded.
- The product tarball is byte-identical to the preceding run's artifact. Test fixture and source-inspection EOL corrections changed no shipped runtime.
- Exact final records: docs/platform/t1-checked-library-preview-qualification-2026-10-10.json and installed-{linux,win32}-node{22.23.3,26.7.0}-38019471955.json. Compiler/native receipts retain run38013991001 in their filenames. PLATFORM_IMPLEMENTATION.md and PSC0_ARCHITECTURE_PLAN.md distinguish completed bounded features, exact qualifications, proposals and unproved claims. Final wording review passed interface/ABI/publication/proof/JS scope.

The installed product remains one proofscript bundle with TypeScript7.0.2 as its only required npm dependency. The two command tarballs are optional local demonstrations, not claims of registry name ownership. Four examples ship: checked-nat, existing-typescript, rejected-source and checked-library. psc init is available; full watch is not. Use a fresh copied checked-library example; an old single-file receipt cannot silently transfer ownership to the new library receipt. The guide explains explicit archival of still-owned generated files while preserving handwritten or edited bytes.

## Next milestones after this completed slice

1. Real psdev watch over the existing checked transaction: import invalidation, cancellation, generation identity, receipt/recovery and downstream sequencing. Keep unsupported PSCV/contracts and unproved semantic claims explicit.
2. The proposed ordinary Nat.max support-unit diagnostic in KERNEL_JS_PLAN.md, then same-source JS generation/adapter/parity/budget/artifact/Windows/Linux qualification. It is not executed or qualified by T1; native remains selected.
3. Durable retention of exact bootstrap/release executable inputs and clean recovery before intentional public npm release. Expiring Actions artifacts and JSON identities do not supply durable binary storage.
4. Broader local/npm/workspace library resolution, final ps-prefixed package boundaries, deliberate default extensions and concrete producer/validator protocols. LSP/VS Code remain outside bootstrap.
5. Full Lean and later PSCV assurance work in proofs/**/*.proof.lean outside bootstrap, without turning full formal completion into the closing gate for every bounded implementation milestone.

Do not rerun or modify the completed T1 compiler merely to prove its metadata again. Re-fetch live HEAD and relevant handoffs before any new slice. Existing selected R/native pins and pending Core refinement remain independent.

## Core-JS finding and planned next diagnostic

The four-file Core-JS plan/probe from psc0/kernel-js-probe-v1 commit6a51a209410bf81d5ab6d8cdf6688be211889e7d is integrated with history. Its workflow remains scoped to the diagnostic branch. Original J0 source b94a6c552d8cc208ce2202527f7f30e28e8836ee / run38007233891 authenticates the previously qualified F compiler and current selected Core, passes seven native public-admission cases, and prepares20 unchanged Core modules before refusing psKernelCheckerStateExitLocalScope in Checker/State.lean. F has no Nat.max in its standard environment. No current Core-JS artifact or qualified JS provider was produced.

KERNEL_JS_PLAN.md now contains a reviewed, unexecuted next diagnostic: retain an explicit ordinary PSC Lean-syntax definition Nat.max(a,b) = Nat.add a (Nat.sub b a) before each fresh canonical batch, admit it with the existing native provider, test its emitted runtime behavior, then retry the79 unchanged Core modules. Existing Nat/add/sub admission avoids a new trusted primitive; source review indicates the current compiler and provider can remain pinned for that diagnostic. Qualified definition names require PSC Lean syntax because the current .ps declaration parser consumes one identifier. Full Lean already owns Nat.max, so this fixture must be outside full-Lean targets and the compiler/Core bootstrap closure. Typing Nat→Nat→Nat does not prove maximum equivalence; the mathematical model proof and source-to-executable refinement remain later obligations. The plan does not claim this diagnostic has run or that it clears later Core gaps.

Intended order: qualified native today; separately qualified same-source pskernel-core-js; qualified Wasm option. JS provider qualification needs canonical codec, native parity, budgets, artifact authentication and installation evidence. A Node child process is not an arbitrary npm-JS sandbox. Do not remove the scope-exit algorithm, add a hidden runtime helper, change the default, or infer current qualification from the historical older three-case JS demonstration.

## Preserved identities and proof scope

Selected authoring seed R remains fe2560aba0f347b1caf8d000d371464642d44f23; both seed manifests are byte-identical. Bootstrap remains Node22.23.3 / Lean4.34.0 / TypeScript7.0.2. Native Core source remains963030dc2d154008fccc82e7c8ed29331f138799 with its qualified Linux and Windows artifacts. No implicit4.35 Arena substitution, native evaluator, semantic fallback, kernel algorithm/cache change or selected-seed promotion.

Formal work remains later in psc0/proofs/**/*.proof.lean, outside self-host bootstrap. Proposed obligations cover source ownership, admission/emission correspondence, name hygiene, guarded ABI, shared bundle/facades, publication state and executable bootstrap refinement. Runtime admission and validation are mandatory now. No new formal theorem, full PSCV assurance, compiler semantic-preservation proof or logical-consistency proof is claimed.

## Execution and ownership

GitHub connector/MCP exclusively for repository reads/writes; builds/tests/source execution only in GitHub Actions. No local files, checkout, shell/source execution, browser or Desktop Commander. Pure in-memory text/JSON transformation and evidence hashing are permitted. Before every ref update read live HEAD and use a non-force expected-HEAD lease. Preserve concurrent changes and slice histories. Avoid branch pushes while qualification is active because concurrency can cancel runs.

Root owns integration/release/evidence/docs; the compiler slice owns portable preparation/erasure/emission; the qualification slice owns generated conformance, the example and installed smoke. Core-JS work is separately scoped. Finish the authorized T1 release qualification and document concrete limits.

## Historical qualification corrections

The following retains the earlier failure analysis; current success is recorded above.

## Recovery authentication correction

Full run38010366876 at c9fa06aecc48d9bd4f9b6c5d6b6aac245e76fabe stopped before compiler execution: scripts/sh1-grammar-conformance.mjs had actual git blob6a4085cc0aea031ff96c7bd5915f82093f0f0345 but the selected native recovery policy pins48efa9b0c90e7904a1df49f43253395841bff90c. Root traced this to prior platform commit033f1c6e20459cdb89a24d861697a06f64eca225, outside T1: it replaced one inline immutable grammar-profile constant with import/re-export from source-grammar-profile.mjs.

Restore exact pinned blob48efa9b0c90e7904a1df49f43253395841bff90c. The grammar/conformance algorithm is identical; only the original metadata location is restored. The runtime host keeps its lightweight metadata file with exactly matching values, while the recovery runner again has its authenticated closed import set. Both selfhost-seed.json and selfhost-seed-recovery.json remain byte-identical. Do not repin policy files, remove authentication or substitute a new seed. This is a recovery of the existing recipe, not a newly qualified recovery route.

## Checked-session source guard correction

Retry run38010642642 at61f45ef2f1a182910e3e421543968a2d81e56720 passed the selected R/policy authentication, exact TS7 contract and portable-source/root checks, then stopped before compiler generation on three stale source-shape assertions in check-modular-preparation-source.mjs. The live session still freezes the prepared graph before serialization, binds reserialization to its private project mode and selects only the two checked emitters. The assertions still expected the earlier two-argument serializer and direct single-emitter call.

Align those three guard forms with the actual closed checked paths and require both freeze/serialization markers to exist before comparing order. The former index-only comparison could accept a missing freeze marker as -1. The existing63 host tests already exercise frozen graph ownership, mode/handle forgery, refusal and publication; no session behavior, compiler, kernel, seed policy or acceptance expectation changes here. The full retry remains mandatory.


## Authenticated recovery and source-isolation harness

Run38010922748 at dbcf9d9a6f4ed3a8e9a4f75550bf99d99cb3bbf4 passed selected-R authentication, source/host guards, successor/cache contracts and exact native-TS7 reproduction of all four pinned R products. Its receipt is explicitly cold:false; this is not a new isolated cold-recovery qualification. Identity47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225 and JS70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061 match the preserved selection. Both seed policy files remain unchanged.

The current native compiler build (146 jobs), native parser/translation/erasure regressions and native seed build (141 jobs) passed. The run stopped before candidate/C2/C3 because the old filesystem-isolation double lacked psCompilerPrepareSource, which the protected compile-with-generated path now requires. Do not reopen raw emission to satisfy a filesystem fixture.

Integrate qualification commit2a3f51cd8360ae8d359787ac93ebeaf4f216cc17: retain all14 original isolation scenarios and expected diagnostics, but exercise readProofScriptImports and readCheckedSourceSnapshot directly with the existing bounded parser double. Success verifies raw source bytes, parser inputs, closure order/digest, entry/root and frozen records; refusal must return no snapshot. This harness claims filesystem/snapshot isolation only. Actual native/generated compiler, target TypeScript, admission and self-host checks remain separate mandatory gates. The downstream actual-native replay/name-index harnesses were reviewed and need no speculative fixture rewrite.


## C1 generation and migration report compatibility

Full run38011957573 at e81ec3baeec0e9a46d2e50ea255afe96259a6fac passed all preceding host/native/grammar/CLI gates, used the authenticated R cache and generated C1. C1's62-module closure remains3932952ddb743692ceab3fe2d48e5c3d5f61aa04d2da47e562f5fa4e3aa689ea. TS8923672fbc4b78a8bc1e25ab172162356ae4ffae6179eddc930c7955c73c1b3d and JS6ab7d603cb612aaaa710a9dd0367ff8fdc4edadb893b3f6f217873444c167617 equal the actual native-generated candidate. C1 canonical surface e91f3bfaaedf755b0fb027a3c6ffe752784c2f19cd41641ba8b015a90e37fe3e and normalized admissions403d7b83ab62150a6f059cd5ed9dcfe18fd68e18f1c54cd8527abf173e20e1d5 are recorded, but C2/C3 have not run. All12 complete worker Core/IR ABI checks passed, observation hashb23c28c75aa3f7955ecbe54fa4580b4278f62c2ed77f1e7ff2a2dbbea6999b49.

The failure is PSC0_SH1_MIGRATION_WORKER_REFERENCE_CORRESPONDENCE at sh1-qualify.mjs:989 after generation and capability execution. Root and compiler agent recursively compared the actual JSON reports. Only F2 cases structures-empty-reverse-accumulator and inductives-empty-reverse-accumulator gain result.scope.declarationNames.runtimePrefix with exact value empty string; the F2 and aggregate hashes consequently differ. All other87-case report values match. Keep raw reports/hashes; assert these exact new fields before a narrow cross-revision comparison view. Do not generically discard fields, bypass ABI or change compiler/Core algorithms. Candidate and later C1/C2/C3 behavioral comparisons must use the same explicit compatibility rule. The isolated ABI runner stays unchanged.

Failed-run artifact11655101607 contains3036362bytes, ZIP SHA2569ba4c9c738a87f95770adb10d32e8a0481c548dd959c8908edebc6f36d857ca6. It is diagnostic evidence, not a qualified successor/release artifact. C1 generation took869718.580168ms; prior successful F candidate13.10min/C2-C3 comparison26.12min explains the long checkpoint. Do not substitute this failed-checkpoint C1 into a new receipt or skip required regeneration.

The reviewed harness follow-up ab10f55660efb97b1cc4017aa26a321f6781594b adds an explicit empty-legacy-erasure-namespace/1 comparison view. It validates raw family/whole-report hashes and case coverage, requires the two exact current fields to exist and equal empty string, preserves every other field, and records both raw hashes plus the comparison hash. C1/C2/C3 recompute and compare this receipt. The ABI harness is unchanged. Seven data-only test groups use the already retained immutable R report, reproduce the exact logged current hash, and reject missing/nonempty fields, unrelated same-named fields, changed observations, dropped cases and invalid raw hashes. The existing early SH1 host step runs them before any long generation. The three harness files and workflow are outside the immutable seven-file native recovery recipe. The remaining iteration gate was reviewed and uses same-compiler comparisons, with no old scope-layout assumption. The next full run still regenerates C1 and must establish C2/C3 and native replay.


---

# Previous completed Wasm planning checkpoint

# PSC0 Wasm Core direction — research complete, implementation pending

Updated: 2026-10-09 22:52:02 UTC. This section is active and supersedes the completed onboarding checkpoint below.

## Current result

The user's requested direction is recorded in [docs/platform/wasm-core-provider-plan.md](docs/platform/wasm-core-provider-plan.md) and integrated into [PSC0_ARCHITECTURE_PLAN.md](PSC0_ARCHITECTURE_PLAN.md): pursue a qualified **pskernel-core-wasm default** with an **explicit optional pskernel-core-native runtime**, using one semantic Core implementation.

This follow-up changes documentation only. No Core Wasm artifact was built or qualified, no default was switched, no tests were rerun and no npm package was published. The current installed product remains the native-backed proofscript 0.1.0-preview.2 qualified at e5c4a561b98ed9e2ae96c7da3f85ed6d844bf1d1 in run37998655835. Its download and instructions remain in PLATFORM_IMPLEMENTATION.md and the preceding completed checkpoint.

## Evidence and architectural boundaries

- Platform source inspected at cb7b241d9387e7d2095f1a2a94db182290f93e09. The selected Core source is separately pinned at 963030dc2d154008fccc82e7c8ed29331f138799.
- The Core admission function is pure; the native process shell is a separate small wrapper. The explicit provider source graph includes78Core+7host+16bridge/data/foundation modules, excluding implicit LeanInit. This is not a linked-artifact or TCB size claim.
- Existing pskernel-lean-wasm is Lean4.34's C++ checker, protocol pskernel-lean/1, not Core. Its target-width/i386/current-runtime/ABI build work can be reused. Its 2,177,471-byte artifact is not a Core size estimate.
- Historical Lean-Wasm run36933643176 succeeded for an earlier artifact. Run37014379617 passed provider/host steps but was cancelled during its fixed-point step. Do not claim a completed Wasm fixed point from it.
- Prefer a release-owned Node subprocess with a minimal Wasm admission ABI, inspected imports and explicit bounds. A generic Emscripten launcher, NODEFS or node:wasi is not automatically the proposed security boundary. The tiny psc-command/1 profile stays separate.
- Proposed --kernel-runtime wasm|native selects an approved execution artifact before admission, never an arbitrary plugin checker. Keep nativeEvaluator=none for both; native execution does not enable native reduction. No fallback after rejection, timeout, trap or missing payload.
- Source proofs can be reused when their source/profile/assumptions match. Lean/C/runtime/LLVM/Wasm/engine refinement remains a substantial separate obligation or explicit assumption. Wasm validation, hashes and finite differential tests are not proofs of logical soundness or compilation correctness.

## Next implementation checkpoint

The new document defines W0 actual same-source cross-build, W1 bounded provider/identity qualification, W2 installed product/native option and full-current-F admission replay, and W3 default promotion. It includes exact evidence distinctions, rough line estimates, measured-resource requirements, clean-build reproducibility and twelve acceptance criteria. Start with one cold build feasibility checkpoint before assuming the existing recipe suffices.

The present research/planning follow-up is complete. W0–W3 are not implemented by this documentation commit. Main, bootstrap pins, selected seed and qualified runtime bytes remain unchanged. Keep formal proofs as a later assurance gate in proofs/**/*.proof.lean, outside the bootstrap cycle; mandatory operational admission/isolation/package checks still gate a default release.

## Execution rules for continuation

Use a fresh live head and this handoff before writes. Repository source reads/writes remain GitHub connector/MCP only; actual builds/tests run only in GitHub Actions. No local checkout/source execution/shell build/test/browser/DesktopCommander. Pure in-memory text/JSON transformations and evidence hashing are allowed. Git-backed deliverables remain in the repository.

Use leased non-force updates, preserve all concurrent history and slice ancestry, and do not change kernel algorithms/metatheory/defeq/cache as incidental porting work. Preserve the 61-module F closure and selected R seed. Bootstrap remains Node22.23.3/Lean4.34.0/TypeScript7.0.2 with no TS5/6 fallback. No automatic 4.35 Arena substitution, seed promotion, main merge or npm publication.

---

# Previous completed onboarding checkpoint

# PSC0 onboarding and isolated command demo — complete

Updated: 2026-10-09 22:28:35 UTC. This section is active and supersedes the completed Windows-preview checkpoint below.

## Current result

The user's requested psc init, examples and psdev extension demo are implemented and qualified in **proofscript 0.1.0-preview.2**. The product adds init, examples, root entry/output defaults and a one-shot dev command. Optional private psdev and independently named @psc-demo/pshello packages are separate tarballs and require explicit root activation.

Qualified runtime/package source: **e5c4a561b98ed9e2ae96c7da3f85ed6d844bf1d1**, tree **d2baf328fbd3aab84335352c35a719f179da09cc**. [Run 37998655835](https://github.com/dwijayuda/pskernel/actions/runs/37998655835), attempt 1, passed all six jobs. Created 2026-10-09 22:20:19 UTC; final successful update 22:22:35 UTC (10 October 2026, 05:20–05:22 Asia/Jakarta).

| Source scope | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| Linux22 host/init/CLI/extension/publication/assembly/smoke | 116 | 0 | 0 |
| Linux22 real compiler/native integration | 17 | 0 | 0 |
| Windows26 host/init/CLI/extension/publication/assembly/smoke | 120 | 0 | 1 |
| Windows26 real compiler/native integration | 14 | 0 | 3 |

The Windows skips are the inherited Unix permission cleanup fixture and three POSIX-shebang fake transport fixtures. All new initializer/command-extension tests and real Windows provider/compiler integration passed. No acceptance gate was weakened and no failure was waived.

Four fresh installed jobs passed: Linux22/npm10.9.9 and Linux26/npm12.0.2 each passed 39 observations; Windows22/npm10.9.9 and Windows26/npm12.0.2 each passed 37. All installed the same product and both demo tarballs with --ignore-scripts. They had no source checkout or Lean installation, and runtime PATH contained only Node. Windows used PowerShell7.6.6 and npm's actual psc.cmd. Total: 152 installed observations.

The full consumer instructions and precise boundaries are in [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) and [release/README.md](release/README.md). The complete command protocol is in [docs/platform/command-extension-sdk.md](docs/platform/command-extension-sdk.md).

## Candidate and retained evidence

[Download candidate artifact 11648008841](https://github.com/dwijayuda/pskernel/actions/runs/37998655835/artifacts/11648008841).

| Tarball within the extracted artifact | Bytes | SHA256 |
| --- | ---: | --- |
| platform/proofscript-0.1.0-preview.2.tgz | 3,639,614 | 9ceab476924c39f73cc6fd8fe4a92b91228b03455d3ff6e0c56e17bf075842d9 |
| platform/psdev-0.1.0-preview.2.tgz | 1,791 | e3cd851c66a899e7d4fb4503becaab33df5e5b2db4ca71a51bc5b2ad67a46468 |
| platform/psc-demo-pshello-0.1.0-preview.2.tgz | 1,805 | 07aadc3b41f007cee0eb6cfc92f9d41d5ba52bfe77083ced1c8edd1c6c80a95c |

The product size excludes separately installed TypeScript dependencies. It adds 14,538 tarball bytes over preview1 with no new required npm dependency. Candidate ZIP SHA256 is 065d0652d8aa28077ad8f7e17eb2503e6ea139fed03b0d398a4ce793545e37e7, size 3,858,799 bytes. It expires 2026-11-08 22:21:28 UTC / 9 November 2026 05:21:28 Asia/Jakarta. Retained JSON is evidence, not executable archive retention.

Installed artifacts: Windows26 11648223020, Windows22 11648631536, Linux26 11647723033, Linux22 11648706220. Exact parsed results are committed as docs/platform/installed-*-37998655835.json, with complete run/artifact/scope metadata in docs/platform/onboarding-command-preview-qualification-2026-10-09.json.

The work remains on psc0/platform-v1, [draft PR90](https://github.com/dwijayuda/pskernel/pull/90), against psc0/architecture-plan-v1. Main was re-read at ed5d00aca0743bde583b45fe7756dd494ac3960f and was not changed. Nothing was published to npm. Owning proofscript does not establish ownership of the private demo names/scope. The product remains UNLICENSED pending the separate public-distribution decision.

## Implemented behavior and security boundary

- Init creates a new pinned project, or adds only src/Main.ps and PROOFSCRIPT.md to an existing npm project. Existing package.json/tsconfig/scripts/dependencies/unrelated sources remain byte-identical. Conflicts and directory links are refused; partial I/O failures report already-created files. It executes no npm/project code.
- Root package.json remains the one configuration source. entry/out defaults are relative paths using forward slashes. Escape/absolute/Windows drive-relative forms are refused. An explicit entry without --out gets its own neighboring TS output.
- Eleven example files ship inside examples/platform; psc examples lists their actual locations.
- psdev is a one-shot command demo: dev --once. Full watch is explicitly refused with PSC_DEV_WATCH_UNSUPPORTED because T1 source ownership/export/ABI work remains incomplete. Do not relabel this as full T2 or generic extension-framework completion.
- The psc-command/1 guest is a restricted no-import Wasm function. The 44-byte demo module SHA256 is 63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279. It receives only event 0 and returns 0/1 for no action/one host-selected checked build.
- The profile bounds modules to 4096 bytes, locals to 32 and control depth to32, and forbids imports, memory, tables, globals, starts, calls, references/GC and other unsupported instructions. V8 performs full validation. A fixed trusted worker adapter supplies a two-second parent wall deadline and cancellation. Worker threads alone are not a JavaScript sandbox; heap limits are not a hard process-RSS guarantee. Node/V8, the decoder/adapter and OS remain assumptions.
- Root activation plus a direct, nonlinked installed dependency and matching npm v3 lock entry selects a package. No JS entrypoint is imported, no ancestor/global/workspace fallback or download occurs, and no publisher-name allowlist gives privileged access.
- Lock integrity is recorded archive provenance. It does not authenticate every installed file against the archive. Actual root/package/lock/descriptor/module bytes are hashed and disclosed; any changed captured input invalidates publication eligibility. Descriptor+module changes before selection can choose a different profile-valid module, whose actual digest is reported.
- The supervisor owns all reporting. attempted/executing/instantiated/completed or failed records are immutable, escaped and emitted outside guest control. imports=[] states the grant policy; an unacknowledged instantiation after worker launch is reported as null.
- Only a private host-owned completed request can supply receipt extension records. checked-build verifies it before compiler loading and rechecks captured inputs through the existing publication eligibility callbacks. Actual dev receipt.extensions equals the final execution record. The guest cannot supply sources, targets, kernel objects, proofs, receipts, flags or filesystem/network/process/terminal actions.
- Ordinary check/build do not run command guests; extensions only inspects data. Default extension activation remains empty.

The smoke qualifies both independent package names, ignored poisoned JS main entries, real npm lock integrity against the supplied archives, ordinary TS consumers returning 44/45 after guest-requested builds, invalid source and tampered module refusal preserving the prior output. This does not establish all OS versions, filesystem/shell policies, arbitrary Wasm features or complete third-party ecosystem support.

## Preserved self-host and proof scope

All **61 raw portable compiler modules** remain unchanged, with closure SHA256 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7. F source remains fcd875c8f38db4b0524090bd10c7c2fd5024053d and JavaScript remains 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15. Existing F fixed-point run 37947341800 remains applicable; no full compiler requalification was needed for host-only changes.

Selected seed R remains fe2560aba0f347b1caf8d000d371464642d44f23. Bootstrap remains Node22.23.3/Lean4.34.0/TypeScript7.0.2, with no TS5/TS6 fallback. Node26 consumer support does not claim a Node26 bootstrap fixed point. Init and optional tooling do not enter the compiler's self-host import closure.

Both native Core providers and algorithms remain exactly the preview1 inputs. Their source is 963030dc2d154008fccc82e7c8ed29331f138799; Linux binary 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec, Windows binary 8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2. Retain the previous source-root/subtree distinction, Windows PE timestamp/reproducibility limitation and retained-artifact recovery boundaries. No 4.35 Arena provider substitution.

Formal assurance remains a **later gate** with proofs/**/*.proof.lean and full Lean outside bootstrap. No new compiler preservation, foundation consistency, PSCV verification or strict SH/1 theorem is claimed. Receipt assurance flags remain false. Later extension proofs should target the bounded decoder, exclusive authority, state/provenance and checked-request composition; each scheduling guest need not be proved.

## Integration and next work

The integrated implementation diff from 3a0d056 to e5c4a561 changes 40 files, adds 2,147 lines and deletes 199, mostly feature code, tests, examples, package data and documentation. The product has 21 maintained host files and 11 example files. No portable compiler file changed.

Preserved slice branches/parents:
- psc0/platform-onboarding-host:6972a20d5c090d9962e376fb0265d87663fc8852.
- psc0/platform-init-examples:ff176be2aa9291dc21ec9a984abeeb6e2b7d4e63.
- psc0/platform-dev-smoke:d564e8520597179220b5462647a2fea18953c468.
- psc0/platform-command-demo:b885371b9c17ab20e2da60091277e66ebdbd48ae.

This requested bounded task is complete. The containing final follow-up changes Markdown and retained JSON evidence only. Do not rerun the completed qualification for it, repeat compiler fixed-point testing, or automatically start another milestone.

Future requested work should follow T1 module/export/ABI, then full psdev scheduling/invalidation/recovery/downstream coordination, richer producer/validator interfaces, explicit default activation, package/library/workspace organization, durable release inputs and separate LSP/VS Code integration.

## Execution rules for continuation

Read a fresh branch head and this active handoff before future writes. All repository reads/writes remain GitHub connector/MCP only; actual builds/tests run only in GitHub Actions. No local checkout/source execution/shell build/test/browser/DesktopCommander. Pure in-memory text/JSON transforms and evidence hashing are allowed. Git-backed deliverables stay in the repository.

Use fresh head leases and non-force updates, preserve concurrent history and all slice ancestry. Do not modify kernel/provider/metatheory/defeq/cache algorithms, promote a seed, alter bootstrap pins, weaken acceptance, merge main or publish npm as incidental work. A new user request may authorize the next bounded milestone; completed proof work and historical TODOs do not authorize starting unrelated work automatically.

---

# Previous completed Windows-preview checkpoint

# PSC0 platform — Windows and Node26 correction complete

Updated: 2026-10-09 21:38:25 UTC. This section is the active continuation and supersedes the earlier Linux-only preview checkpoint below.

## Current result

The user's Windows x64 / Node26.7.0 / npm12.0.2 installation failure is addressed by **proofscript 0.1.0-preview.1**. One tarball contains the unchanged F compiler and separate authenticated Linux x64 and Windows x64 native Core providers. The implementation remains on `psc0/platform-v1`, [draft PR90](https://github.com/dwijayuda/pskernel/pull/90); main was re-read at `ed5d00aca0743bde583b45fe7756dd494ac3960f` and was not changed. Nothing was published to npm.

Exact qualified source: `3fd25db1bbd8d508252682fd0efe5a948a5ea5fd`, tree `7c606d0b6910fdd04250a5d1c7a58aa800f47d43`. [Run37993872945](https://github.com/dwijayuda/pskernel/actions/runs/37993872945), attempt1, passed all six jobs; final successful run update 2026-10-09 21:32:52 UTC.

| Qualification | Passed | Failed | Skipped |
| --- | --- | --- | --- |
| Linux22 host/session/publication/source/CLI/assembly/smoke harness | 84 | 0 | 0 |
| Linux22 real provider/compiler integration | 17 | 0 | 0 |
| Windows26 host/session/publication/source/CLI/assembly/smoke harness | 87 | 0 | 1 |
| Windows26 real provider/compiler integration | 14 | 0 | 3 |

The one Windows host skip is the existing Unix directory-permission cleanup fixture. The three Windows transport skips use POSIX shebang executables. Actual Windows native-provider and generated-compiler tests are mandatory and passed; no gate was weakened or failure waived.

Four fresh installed jobs also passed: Windows22/npm10.9.9 and Windows26/npm12.0.2 each passed13 observations; Linux22/npm10.9.9 and Linux26/npm12.0.2 each passed15. Every job installed the same tarball globally with `--ignore-scripts`, with no source checkout or Lean installation. Actual execution used a Node-only PATH. Windows tested npm's `psc.cmd` from PowerShell7.6.6; bare `psc` may select `psc.ps1` and depends on local shell policy.

The workflow checked admission, neighboring TypeScript publication, existing TS project import/typechecking/execution, a successful changed rebuild from42 to43, rejected-rebuild preservation and explicit PSCV refusal. Windows image: win22/20261004.326.1, Windows Server2022 10.0.20348 x64. Linux image: ubuntu24/20261004.327.1, Ubuntu24.04 x64. Do not claim every Windows release, Linux distribution, filesystem or shell has been qualified.

## Package and evidence

- Candidate artifact [11646426537](https://github.com/dwijayuda/pskernel/actions/runs/37993872945/artifacts/11646426537).
- Tarball within the extracted artifact: `platform/proofscript-0.1.0-preview.1.tgz`.
- Tarball size: **3,625,076 bytes**, excluding separately installed npm dependencies.
- SHA256: `77b0d6c596c8b77af99b4676ce998d58d713b5596762eef928ed284018449ba0`.
- Windows26 installed evidence artifact11646800613; Windows22 artifact11646216847; Linux22 artifact11645973348; Linux26 artifact11645898259.
- All five platform artifacts expire on **8 November 2026**. The committed JSON retains identities and evidence, not executable archives.
- Exact retained results: `docs/platform/windows-preview-qualification-2026-10-09.json` and four `installed-*-37993872945.json` files.
- Read [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) for copyable PowerShell/Linux instructions and bounded claims.

The old preview0 tarball remains Linux-only. Removing its npm OS restriction or using force cannot provide the missing Windows executable. Use preview1. The registry name is still `proofscript`, command `psc`; ordinary registry installation does not select this unpublished candidate.

## Preserved source and new native artifact

- F compiler source `fcd875c8f38db4b0524090bd10c7c2fd5024053d`; qualification run37947341800 remains applicable.
- Its **61-module raw source closure** remains `6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7`.
- F JavaScript remains `5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15`.
- Selected authoring seed R remains `fe2560aba0f347b1caf8d000d371464642d44f23`; seed manifest and recovery recipe are unchanged.
- **Bootstrap stays Node22.23.3 / Lean4.34.0 / TS7.0.2.** Consumer Node26 support does not claim a new Node26 bootstrap fixed point. No TS5/TS6 fallback.
- Native Core source remains `963030dc2d154008fccc82e7c8ed29331f138799`. Its repository tree is `80927150cbd6a5518762b4cc56e51ea24df8f374`; `38c8c55bd2b214753e56c58c15c4901c32c01b86` is specifically its `psc0` subtree. Metadata now records `sourceTreePath: "psc0"`.
- Linux provider SHA256 remains `88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
- Windows provider SHA256 is `8264a5e8551a1040d81956fa5b2a7f429355b365df06b9b705e20df8640419e2`; 5,509,120 bytes, PE32+/AMD64. Exact native build/protocol qualification: run37993071033 at `fbf06f94b9b13366ebd1e7a3fa9602b43ea386a3`, candidate artifact11646570443. Seven fresh native observations passed before package integration.
- Both providers need no bundled non-system DLLs. Windows imports twelve recorded OS DLLs; OS/runtime libraries remain assumptions. No Lean installation is required by the tested package.
- The Windows PE includes link timestamp1791581097. An ordinary later rebuild is not byte-reproducible under this recipe; retain/use the exact artifact. A deterministic native build recipe must earn its own qualification. Do not patch the timestamp or invent a replacement hash.
- Separate Lean4.35 Arena work has a different protocol and is not substituted.

## Implementation and remaining scope

The corrected host selects the native byte pin only from actual platform/architecture, checks it before and after admission, runs the native child from its own directory, and validates Windows output aliases before target staging. One release contains both payloads with the same 17-file maintained host import closure; no platform-package loader or DLL framework was introduced. The correction from158a5d9 to3fd25db changes25 files,1986 added lines and287 deleted lines, mostly qualification/tests/metadata. No portable compiler or kernel algorithm changed.

This completes the Windows portability correction to the first protected-host/installable-preview milestone. It does **not** complete architecture phases0–4. External extension execution remains unsupported and disclosed as an empty set. The final ps-prefixed source/package split, library imports, full T1 export map/ABI, watch/LSP and isolated extension runner remain subsequent milestones in the accepted Markdown plan.

Formal assurance remains a **later gate**, with `proofs/**/*.proof.lean` and a proof-only full-Lean environment outside bootstrap. No compiler semantic-preservation theorem, logical-consistency theorem, PSCV verification, strict SH/1 result or joint compiler/kernel fixed point is claimed here.

## Execution rules for continuation

All repository source reads/writes remain through GitHub connector/MCP, with actual builds/tests only in GitHub Actions. No local checkout, source execution, shell builds/tests, browser or DesktopCommander. Pure in-memory text/JSON transforms and evidence hashing are allowed. Git-backed deliverables remain in the repository.

Use fresh head leases and non-force updates, preserve concurrent history, and do not change kernel/provider/metatheory/definitional-equality/cache algorithms. Do not promote F as seed, change bootstrap pins, weaken acceptance, merge main or publish npm as an incidental continuation. The containing follow-up is documentation/evidence only; do not repeat the completed qualification or compiler fixed-point runs for it.

---

# Previous Linux-only preview checkpoint

Updated: 2026-10-09 21:02 UTC. This section supersedes the historical handoff below for the newly authorized platform implementation.

## Current result

The **first protected-host and installable-preview milestone is implemented and cloud-qualified** on `psc0/platform-v1`, [draft PR90](https://github.com/dwijayuda/pskernel/pull/90), based on architecture plan commit `ab23c842077ad6dd9224335e52ccdc4e6dfeb39e`. This is not completion of all architecture phases 0–4 or the complete T1 module/ABI milestone.

Read [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) for the exact behavior, user workflow, remaining scope and evidence. [PSC0_ARCHITECTURE_PLAN.md](PSC0_ARCHITECTURE_PLAN.md) remains the accepted full plan.

Qualified runtime/package source: `48be48c0fd91407ca531692be2a3bd8bc24b058b`, tree `0cbeb41c6016295be2247ee27c16d074d7b46810`. [Run 37990210503](https://github.com/dwijayuda/pskernel/actions/runs/37990210503), attempt 1, passed both jobs and completed at 2026-10-09 20:57:03 UTC. The containing follow-up only records documentation and evidence; it does not change runtime/package bytes.

- Host/session/publication/CLI/assembly: **61 passed, 0 failed, 0 skipped**.
- Actual native-provider and generated-compiler integration: **16 passed, 0 failed, 0 skipped**.
- Separate fresh installed-package job: **12 observations passed**, including a real existing TS project importing and executing neighboring generated TS.
- Actual installed environment: Ubuntu 24.04.5 x64, image ubuntu24/20261004.327.1, Node 22.23.3/npm 10.9.9, TS7.0.2. Execution PATH contains only a dedicated Node symlink. No source checkout or Lean installation is required for that tested package.
- Tarball `proofscript-0.1.0-preview.0.tgz`: 1,890,798 bytes, SHA-256 `f44034b3624f67660e252df919f0188991613ac7069e47805355e2760374f12c`. This size excludes separately installed npm dependencies.
- Candidate artifact **11644293016**; installed evidence artifact **11645305653**. Both expire 8 November 2026. Compact exact logged evidence and API metadata are committed under `docs/platform/`; they are not a permanent copy of executable archive bytes.
- Earlier runs 37989444677 and37989830598 also passed. No test failure was waived or gate weakened. Do not rerun compiler fixed-point qualification or these completed gates for documentation-only changes.

Main was re-read at `ed5d00aca0743bde583b45fe7756dd494ac3960f` and was not changed. No PR was merged and **nothing was published to npm**.

## Implemented boundary

The release-owned public `bin/psc.mjs` preserves caller cwd and routes builds through authenticated compiler bytes, immutable source/prepared state, exact native Core admission, checked emission of the same original RuntimeIR, TS7 target validation and owned output publication. The old raw generated build driver now delegates to that host. A native seed's raw emit protocol is explicitly unqualified for this protected build route.

`psc check` is admission-only and reports RuntimeIR as not requested. `psc build` adds the IR/target/publication gates. Requested .ts output creates only TS and its receipt; .js output includes the bundle sidecars. Existing unowned or manually edited generated files are preserved by refusal.

Publication uses a directory-wide lease, staged old/new inventories, final eligibility/artifact checks and receipt commitment last. Conservative rollback preserves conflicting user writes. Incomplete recovery retains a visible lock and backups; postcommit cleanup failure reports committed status. Multiple filesystem files do not become atomically visible to independent watchers, and power-loss durability is not claimed.

All external-extension execution is currently **unsupported**. The supervisor always discloses an empty external set. Root-project unsupported profiles, verification settings and extension requests fail explicitly. This is not an implemented plugin sandbox or a claim that arbitrary npm code can safely share the host process.

The release assembler has a complete 17-file maintained host import closure, exact compiler/native-provider pins, one exact TS7 dependency and no lifecycle scripts. The compiler remains bundled; the final ps-prefixed source/package split is still planned. Host sources currently remain Node .mjs modules; no TypeScript rewrite of the portable compiler is claimed.

## Preserved compiler and kernel inputs

- F compiler source `fcd875c8f38db4b0524090bd10c7c2fd5024053d`; its existing full qualification is run 37947341800.
- Exact 61-module raw compiler closure: `6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7`.
- F JavaScript: `5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15`.
- Selected authoring seed R remains `fe2560aba0f347b1caf8d000d371464642d44f23`; manifest, active TS7 recovery policy and historical identities unchanged.
- Native compiler-admission provider source `963030dc2d154008fccc82e7c8ed29331f138799`, binary `88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`, Lean 4.34.0. Its algorithms are unchanged.
- Separate Lean 4.35 Arena work uses a different protocol; do not substitute its binary or transfer its proof results to the pinned 4.34 admission path.
- Toolchain policy: Node 22.23.3 and TypeScript 7.0.2, no TS5/TS6 fallback.

No portable compiler source changed, so the existing fixed-point evidence remains the applicable compiler evidence. The new host earned separate execution/refusal evidence. No joint generated compiler/kernel fixed point, semantic-preservation theorem, logical-consistency result, PSCV verification or strict SH/1 qualification is claimed.

## Next complete milestones

1. One constrained isolated extension runner and data protocol; explicit project activation; actual-load disclosure; complete official and third-party examples. Never grant guest code provider/admission/reporting/final-output authority or use in-process npm imports as isolation.
2. Stable primitive/runtime identities and extension contracts, narrow SDK and bounded producer/validator examples.
3. Final ps-prefixed module/package boundaries, ordinary npm ProofScript libraries, locked project installs and durable release-input recovery. The preview workflow currently reads a retained F Actions artifact, so source/release retention must be closed before a durable public release. The current preview is UNLICENSED pending a distribution-license decision.
4. Full T1 export map, neighboring facades and narrow checked ABI before psdev/watch; then cancellation/invalidation/recovery/downstream coordination and separate LSP/editor snapshots.

The user prefers `proofscript` as npm product, `psc` as command, ps-prefixed components and TS as the required reference backend. Other backends, dev/watch, LSP and editor tooling can be added incrementally outside the compiler self-host closure.

Formal assurance stays a **later gate**. Use `proofs/**/*.proof.lean` plus ordinary shared Lean model/lemma modules, full Lean tooling and a proof-only environment outside bootstrap. The plan already defines the layout and direct-file runner approach. No proof workspace or new compiler theorem suite was implemented in this milestone. Do not turn incomplete proofs into an implementation-closing gate or describe runtime typing as compiler correctness.

## Execution and workstream boundaries

All repository source reads/writes use GitHub connector/MCP. Actual builds/tests run only in GitHub Actions. Do not clone, build, test or execute repository code locally, or switch to browser/Desktop Commander. Pure in-memory text/JSON transformations and evidence hashing are allowed. Git-backed deliverables stay in the repository.

Use fresh head leases, non-force branch updates and preserved ancestry. Do not change kernel/provider/metatheory/definitional-equality/cache algorithms, select F as authoring seed, weaken acceptance gates, merge main or publish npm as an incidental continuation. Read live branch/lane handoffs before later integration. Preserve concurrent 4.35/strict/proof work and its separate evidence.

---

# Historical completed compiler/TypeScript handoff

The complete prior handoff below is retained as evidence. Its “current”, “complete”, and “next” wording describes its own earlier checkpoint, not the active platform work above.


Updated: 2026-10-09 16:02:49 UTC. All evidence times in this file are UTC. The prior session recorded Asia/Jakarta (UTC+07:00) for user-facing time conversions.

## Read this first

This is the completed handoff for the authorized dwijayuda/pskernel implementation, qualification and migration work. The user explicitly requested this detailed committed AI_WORK_STATE.md so a new chat can resume from verified facts without drifting. The bounded task is complete. Future chats should read this active section and the current developer guide, preserve the decisions below, and act on the user's next requested change. Do not restart completed research, repeat successful qualifications or treat archived TODOs as current work.

**Current result: all requested source qualification scopes have passed.** F has completed C1/C2/C3, all four fixed-point products, native/final TS and JS parity, the complete 87-case R/F behavior correspondence, all twelve public Core/IR signatures, new-only grammar/runtime gates and separate exact-stream provider acceptance. The TypeScript 7-only native recovery of selected R is independently cold-proven. The separate repository-root TypeScript 7 migration passed all seven commands and all eleven adapter obligations. TypeScript 5 is retired from current development and recovery; immutable old producer metadata stays historical.

**Publication and branch integration are complete.** Commit 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 retains the authenticated evidence, eleven reconciled PSC0 guides, current ledgers and detailed handoff. At 2026-10-09 16:02:49 UTC, all four authorized working/canonical branches were independently read back at that commit after ordinary non-force fast-forwards. This containing documentation-only closeout records those actual writes and preserves every qualified executable and selected-R identity. No source qualification, compiler repair, test, retry, additional research or seed promotion is outstanding. Live branch heads can later advance; re-read them before any future write.

Everything at and below the later heading "Historical completed M6 and TypeScript 7 result" is archival. Some historical subsections contain words such as "Current", "next" or "selected"; those describe their old checkpoints, not today's active instructions. This active section takes precedence.

## User intent and persistent decisions

- Research why self-hosting is constrained, implement a suitable finite language subset and source migration, and make iteration faster and more effective.
- Create/use working branches for changes. Continue autonomously on already authorized work. Main remains untouched.
- Use the supplied new .ps grammar only. Do not keep an active old-grammar fallback or add backward compatibility.
- Retire TypeScript 5 from future development. Current PSC0 compilation, recovery, root workspace compilation and remaining compiler launchers must require TypeScript 7.0.2; do not install TS5/TS6 API fallbacks.
- Preserve immutable historical source revisions, original producer-version facts, seed identities and receipts. Historical 5.8.3 text is not permission to execute that compiler in today's workflow.
- Avoid a repeated guess/test/fix loop. Diagnose a demonstrated class, review related obligations together, use cheap preflight, and run the full qualification only at a coherent semantic checkpoint.
- Keep this file accurate after concrete milestones and before a handoff.

### Execution and scope boundaries

This continuation uses GitHub connector/MCP reads and writes, with actual builds/tests only in GitHub Actions. Do not clone, build, test or execute repository code locally; do not switch to a local shell, browser or DesktopCommander workflow. Pure in-memory text/JSON transformations and evidence hashing are permitted. Git-backed deliverables remain in the repository.

Use fresh branch-head leases for every update, preserve concurrent work and ancestry, and never force-push. Do not change provider/kernel/metatheory/definitional-equality/cache algorithms. The exporter correction below changes a TypeScript declaration only, not process behavior. Do not weaken gates, select F as a seed, merge main, or claim strict SH/1, unrestricted PSC1, full Standard or PSCV.

Pins: Lean 4.34.0, Node 22.23.3, TypeScript 7.0.2. Continue useful work while Actions runs; communicate meaningful progress to the user.

## Branches, exact sources and qualification runs

Read live refs before any future write. The following is the verified publication boundary at 2026-10-09 16:02:49 UTC, not an assertion about an unseen later HEAD. Publication 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 has parent 8d922c3f47f59a8d7285bfdf998791f042b483b9 and tree 2935b38a17157fc214e4a0ec09d99a91469ef522. The parent is the committed handoff checkpoint following qualified root source 9d150afbec1feda8c97058aa56aa5ab92347d96d. The documentation-only closeout containing this file is a descendant of the publication; source qualifications remain pinned to their original commits below.

| Branch or evidence | Verified publication identity | Meaning |
| --- | --- | --- |
| psc0/typescript-7-only-v1 | 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 | Combined qualified PSC0/root result and retained evidence; integration complete |
| psc0/sh1-projection-grammar-v1 | 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 | Fast-forwarded from qualified F source fcd875c8f38db4b0524090bd10c7c2fd5024053d |
| psc0/sh1-implementation-v1 | 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 | Canonical branch integrated by normal fast-forward from 5e3a991088aaa735c8f324c4e70a7a3dee4cd69a |
| psc0/typescript-7-v1 | 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 | Earlier TS7 alias integrated by normal fast-forward from the same 5e3a991088aaa735c8f324c4e70a7a3dee4cd69a |
| main | 37f63c39d4a07189938046c64152bba25d789450 | Re-read unchanged; never updated by this work |
| Qualified F/PSC0 source | fcd875c8f38db4b0524090bd10c7c2fd5024053d; tree 0bda17a81be9f790fa12a5fc38bd32d36f38f6ae | Immutable source for successful compiler/provider and native cold runs |
| Qualified root TS7 source | 9d150afbec1feda8c97058aa56aa5ab92347d96d; tree c97468df9855bb7379b49e0771ed5e373e39c8b2 | Immutable source for successful root package/adapter run |
| Selected R source | fe2560aba0f347b1caf8d000d371464642d44f23 | Fully qualified, explicitly selected authoring compiler; not replaced by F |

### Completed F qualification — no relaunch or repair remains

[Run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800), workflow 378853677, attempt 1, completed successfully at source fcd875c8f38db4b0524090bd10c7c2fd5024053d on psc0/sh1-projection-grammar-v1.

- Compiler job 113876931430 ran from 14:51:45 to 15:36:17 UTC and succeeded. Required steps 3,6,7,8,9,11,14,17,18,19,20,21,22,23,24,25,28 succeeded; step 26 was skipped, so no F seed was selected.
- Provider job 113896228512 ran from 15:36:21 to 15:37:18 UTC and succeeded. All eight exact C2/C3 admission roles were accepted, grouped into four distinct streams derived from the actual hashes, using the unchanged provider binary.
- The run's final conclusion is success; it was last updated at 15:37:19 UTC. No retired successor-recovery job ran. Native cold recovery is the separate successful run listed below.
- The recorded 75/10/16 native suites passed. The host source/import/session file recorded 27 passing tests, zero failures and zero skips, including the three reusable PS/Lean boundary cases at compiler-log lines 1971, 1977 and 1983. Both N1 and C1 SESSION_CONFORMANCE markers passed.
- Native and generated checks exercised the current grammar, structural state parameters, exact projections, generic erasure, helper/runtime behavior and refusal boundaries. All 87 worker observations and all 12 complete public Core/ordered-IR signatures were retained, not reduced to summary hashes.

Exact F source closure: 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7, 61 raw authoritative Lean modules. The common N1/C1/C2/C3 recipe SHA-256 is 90a5fc6131e151a7ed24c8a1e5f2d424c8b14e7eda813b34b5b301f37623a0b1. Its ordered source-file recipe is in every complete generation receipt; sh1-qualify.mjs at this source is blob 0cbc8354046ce71a17efc588180864fabcbf5dba.

| Exact final F product | SHA-256 |
| --- | --- |
| Canonical new PS source JSON | 8b060f40c279f81abb9f81ab5903457e295e431fc67c945ccd312663cd76e3c3 |
| Canonical admissions | 9fffa1ecd53f4befe3c0296cbbe0069dfb8cf1a91169a6dc44f3f1d6dbf1b8d5 |
| TypeScript | 0d90517192bba53dbc6190c774158559b64871b7222ba37b0df5a65a325db99a |
| JavaScript | 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15 |

C2 and C3 match on all four products. N1 matches the final TypeScript and JavaScript, and the fixed-point record binds C1/C2/C3 to the actual selected-R execution chain. The native original IR accepted 56,602 expressions in 728,064 steps with zero findings. Every generated build checked its complete original IR before synchronous emission of that same object.

The complete behavior observation digest is 697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be across R/N1/C1/C2/C3. The ABI observation digest is b23c28c75aa3f7955ecbe54fa4580b4278f62c2ed77f1e7ff2a2dbbea6999b49 across C1/C2/C3; reference-type digest a65845d1f9f30b55f1b8b3599c264ae39e4c35fe7c84367575ea6b504644ab82. The supported isolated probe has 19 one-constructor monomorphic inductives, 12 signature annotations and 12 typed generic partial wrappers; it produced 69 prepared declarations. Probe source SHA-256: b8a51317306f4803aaba1a7553999aa41599861d5d0677a2d8f8686f69a3f41b. It is isolated, never merged into the compiler closure, never erased/emitted and never executed as a separate runtime artifact. Actual public Core/IR is observed from the objects already prepared for each build, with no repeated full R-closure preparation.

N1 performed full Lean -> new PS -> Lean canonical correspondence and PS idempotence for all 61 modules, producing 902,538 PS bytes. The full grammar artifact's observed digest is 6d6bdb15cb1c4dacebee92104dd11538058118b072637575f1f39f7e4bb8878c. Its original file bytes were not available through the compact logs; the reviewer validates its N1/final receipt linkage and the source-pinned qualifier's final canonical-product checks. The finite grammar gate separately recorded 18 application boundaries, 22 supported forms, 40 canonical round trips, 35 parse refusals, 2 lexical-position cases, 5 lexical refusals, 3 empty-call refusals and 1 printer refusal. The recursive-generic runtime gate recorded 19 observations per generated stage.

| Retained F evidence | Exact identity |
| --- | --- |
| Complete 47-file path manifest | 5ed0a4f6cff3d48672df34076b7ac8801c9299a4 |
| Path manifest SHA-256 | d6fac3c607da92e9ccae914b971e141587eb7354b2b64b37e8c16e4b1a8ec0f1 |
| worker-migration-qualification.json | blob 1820e4519018365abbe520ab3dc362b535fdbd45; SHA-256 a2ee15bb0c45a465c2f437fc7d74fcb87bfb8a05a3449f202c3670232c70e1a3; 5,284 bytes |
| worker-migration-provider.json | blob 87ec0c66613ff6c5936d79b56e8e9f000a49bb8c; exact file SHA-256 5e674b2808523ff5c3c40d9220ac0810905f248945d3c20813c27a4e1b2f8913; 3,532 bytes |
| worker-migration-evidence.json | blob b2ca50c9e353b91220a5280e90ff7cd45b6b9a7e; SHA-256 7eb162e121ce97f4a9836daa44a85d0c03b30ac1aaa2b90cf43a1a3d69d9d069 |
| Complete compiler log | blob 5ab3fc932628afac4ff099727663ce45a25b8af8; SHA-256 0029eccaf74c06b1fef9c3f06987cb0dc82003c649912bb1959bf3f13068e931; 757,271 UTF-8 bytes |
| Complete provider log | blob 41f4e3a7546f9b05f5b27981d247a34a699aed49; SHA-256 99e3e9d913d9322f042d69f0981358bee36fa478849ee249062f6f59c07e80fd; 62,929 UTF-8 bytes |
| Compiler artifact | 11627040677; archive digest a05e427bb580fea603c1cad9946977910ab85e044caf605fe5b4b5f6f271e728 |
| Provider artifact | 11626368937; archive digest 2466b46c77d4122a553a3a5a3fccdbf3d142062fadf0bcbb920f0521aa476ae8 |

All paths above are under psc0/docs/selfhost-language; full logs are under evidence-logs, and the remaining complete receipts/APIs/reviews are under seed-evidence/fcd875c8f38db4b0524090bd10c7c2fd5024053d/F/. The main qualification file is the exact compact FIXED_POINT JSON substring plus LF, explicitly labelled as that representation. It is not advertised as original pretty artifact bytes. The provider file is the actual read-back file content from its envelope. All 32 compiler and 2 provider marker records, full observation arrays and both independent reviews are retained. Artifact archive bytes were not downloaded.

The pure-data toolkit used successfully by both independent reviewers is blob 490cc9d968bddd92da1ad67e39b3880a35349580; its input/audit manifest is 31293d61303666b1b6f82071c0bfc1f20316254b. Its provider checker derives the distinct digest groups from all eight role hashes and requires the exact qualified-R provider binary. Reviewer/hash source is retained only as inactive .factory.txt evidence. Successful data review does not create a kernel proof or broaden the admitted language profile.

### Completed root TypeScript 7 qualification

- [Run 37951869293](https://github.com/dwijayuda/pskernel/actions/runs/37951869293), source 9d150afbec1feda8c97058aa56aa5ab92347d96d.
- Root job 113892421469, workflow ID 379741182, attempt 1.
- Completed successfully: all seven required commands exited zero. The receipt spans 2026-10-09T15:27:57.441Z through 15:28:22.403Z; the job completed at 15:28:26 UTC. Root and projection_repair independently authenticated the full primary log, actual completed API objects, all five original receipt files, all 21 package bindings, the unchanged exact lock (lockGenerated=false), and the 11-obligation adapter record.
- Dedicated workflow: .github/workflows/root-typescript7-qualify.yml.
- The passing ordered commands are npm ci; root build; test:packages; conformance build; lean4export build; package integration; check:packages. Their recorded command times total 24,845 ms. This is a run measurement, not a TS5/TS7 benchmark.
- This root gate does not qualify PSC0, run Lean corpus/oracle tests, change provider acceptance, or promote a seed.
- The workflow is branch/path plus [root-ts7-qualify] gated. Do not add the marker to evidence/documentation-only commits or rerun after sufficient proof.

The source-pinned root recipe is scripts/root-typescript7-qualify.mjs, blob 1dc573166836765fc7b8d0fa4714b5d1d29ae609, driven by .github/workflows/root-typescript7-qualify.yml, blob 348ab35eaf3210b5a96ac53c08d7c5b201c29c1e, with the committed exact lock below. Its actual ordered command receipt is:

| Phase | Exact command | Actual exit | Recorded milliseconds |
| --- | --- | --- | --- |
| install | npm ci --ignore-scripts --no-audit --no-fund | 0 | 1635 |
| root-build | npm run build | 0 | 336 |
| package-tests | npm run test:packages | 0 | 13474 |
| conformance-build | npm run build --workspace @proofscript/conformance | 0 | 201 |
| lean4export-build | npm run build --workspace @proofscript/lean4export | 0 | 208 |
| package-integration | npm run test:package-integration | 0 | 8507 |
| package-boundaries | npm run check:packages | 0 | 484 |

## Why the subset was needed and what actually changed

The original root configuration did not actively select PSC1-selfhost-stable/1 or PSC1-portable-selfhost/1 as the compiler source contract. The practical restrictions came from the owned parser, elaborator, structural recursion normalizer, prelude, erasure and backend coverage. Acceptance by host Lean or a broader language/profile label did not prove that the generated compiler could consume and rebuild that source.

The old recursion normalization required non-decreasing arguments to stay unchanged. Source used returned-function state adapters to work around that implementation boundary. The implemented bounded normalization supports ordinary changing parameters around accepted structural Nat/List/regular-inductive descent and preserves the public function types. Shared exact-name / first-segment / longest proper local-prefix resolution fixes recursive record-parameter projections without changing structural identity checks or adding error fallbacks.

This is a finite practical authoring subset, not unrestricted Lean/PSC1. Do not broaden it by changing a profile string. Current .ps parser/printer/import/session handling is new-only ps-0.9-r3; the 61-module handwritten .lean closure remains authoritative. Switching all handwritten compiler authority to .ps is not part of the completed claim.

### New-only .ps contract

Grammar identity:

    {"edition":"ps-0.9-r3","mode":"new-only","support":"bounded-selfhost-subset","referenceSha256":"4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71","fullStandardConformance":false,"fullPscvConformance":false}

The supplied reference is 401,569 bytes / 8,546 lines and is a design RC with broader Standard/environment conformance pending. Implemented forms include newline-oriented sequences, one explicit comma-separated declaration/constructor binder group, strict record commas, bar cases, grouped/adjacent/native-gap calls and typed lambdas. f(()) remains one Unit argument; empty f() is not silently rewritten to Unit and unsupported completion is refused.

PS lexical boundaries preserve raw UTF-8 positions and LF/CRLF handling, allow a leading BOM only, and reject tabs, lone CR and later BOMs outside the documented literal/comment boundaries. Host decoding is fatal for invalid UTF-8. There is no active legacy PS parser/semicolon mode. Historical Lean/seed source remains at immutable historical refs.

Current unsupported boundaries are explicit: general do, omitted required types, defaults/named arguments, automatic empty-call completion, tuple terms/patterns, arbitrary result projection such as f(x).field, nested patterns, general equation normalization, class/instance synthesis and broader verified effects. Legacy semicolon sequences and repeated explicit PS declaration groups are refused. Typed lambdas and function-valued results remain legitimate constructs; the finite worker cleanup does not ban them. See docs/selfhost-language/CURRENT.md and SPEC.md for authoring rules and PS_GRAMMAR_ADOPTION.md for the source-reference mapping and errata.

### Finite F production migration

Production edits first landed at 9ee0b1fd38dd1456a187d4675f9027440a989f2d and remain unchanged through fcd and the root branch. F changes twelve workers in nine Lean files and removes three projection aliases in a tenth; seven existing source guards were aligned. Public types, parameter order, fuel/zero behavior, reversal/order rules and collision limit 4096 are preserved requirements.

The exact twelve-worker -> nine-file mapping was independently read at fcd and retained in audit blob 48fdd86397ba8fff5d5ba48a3bcf75d40c5b509b. Paths below are repository-relative. Three typed projection aliases are removed in a separate tenth source file; it contains no additional migrated worker.

| Production source file | Ordinary-parameter workers |
| --- | --- |
| psc0/packages/erasure/src/Ps/Erasure/Basic.lean | psErasureLocalNameWithFuel |
| psc0/packages/erasure/src/Ps/Erasure/Expr.lean | psErasureEtaNameWithFuel |
| psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean | psTsFreshMatchTempWorker |
| psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean | psTsFreshInternalWorker; psTsBuildSymbolMap |
| psc0/packages/compiler/src/Ps/Compiler/Api.lean | psCompilerPreparationSourcesWorker |
| psc0/packages/elab/src/Ps/Elab/Declaration.lean | psAddDeclarationListWorker; psElabDeclarationsWorker |
| psc0/packages/erasure/src/Ps/Erasure/Definition.lean | psBuildErasureDeclarationNamesWorker; psEraseDefinitionsLoopWorker |
| psc0/packages/erasure/src/Ps/Erasure/Structure.lean | psPrepareRuntimeStructures |
| psc0/packages/erasure/src/Ps/Erasure/Inductive.lean | psPrepareRuntimeInductives |

The tenth source file is psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean, blob 94b80cd7fe617e62c9a95446ff019e088d57b0b3. Its cleanup removes one limits : PsIrCheckOptions := options alias in psIrCheckMatchBindings and two currentState : PsIrCheckState := state aliases in psIrCheckRun. Historical inventory line numbers are locators at their old source, not current line numbers.

The original F1/F2 function-scoped source manifests are fbb5cabc6d48f16a0e91c1c4a92c6849791968b7 and ce035d30d64341e3214f241d682c61dac4922649. The current mapping audit preserves exact current source blobs and one declaration occurrence for every name. Use those immutable records and fresh source reads before any later migration.

The twelve signature arities in probe order are [4,4,3,4,2,2,3,2,4,5,5,3]; original partial splits are [3+1,3+1,2+1,3+1,1+1,1+1,1+2,1+1,3+1,3+2,3+2,2+1]. The migration is F1=4 workers plus F2=8 workers, with 44 direct cases + 7 wrapper cases + 36 state cases = 87 unique behavior cases per compiler.

The complete original inventory has 241 locators; 226 remain explicitly deferred. Not every function-valued result is a workaround. Do not perform a wholesale rewrite or silently mark those deferred entries done.

### Earlier F failures are preserved, not hidden

1. Run 37939061854 at 9ee failed a new host fixture's nonexistent structure-constructor call. f62c38c890af13b1e8ccb2a4d2650b9c7c6d2d5f corrected all 48 invalid calls across 20 structure types with existing neutral factories, same-compiler template copies and three explicit non-IR host records. All independent expectations were retained.
2. Run 37941485695, compiler job 113856701970, at f62 passed the complete R and N1 87-case reports. Their observation SHA-256 is 697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be. Native original IR accepted 56,602 expressions / 728,064 visited steps / zero findings; all 61 modules round-tripped with 902,538 PS bytes. It then failed before C1 emission because the isolated ABI fixture used unsupported axiom declarations.
3. fcd replaces that fixture with 19 one-constructor monomorphic inductives and the same 12 explicitly typed partial wrappers. The complete first explicit binder type supplies each reference signature. The corrected preflight and all actual prepared Core/IR ABI checks then passed in every required generation of successful run 37947341800. No worker/compiler behavior was changed by these fixture repairs. The failed runs remain failed records; their successful earlier phases are not relabelled as whole-run qualification.

Attempt-2 F closure was 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7, with N1 JavaScript 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15 and TS 0d90517192bba53dbc6190c774158559b64871b7222ba37b0df5a65a325db99a. These remain attempt-2 observations. The same products were independently established in the later complete successful fcd run; the final proof is its actual retained receipts, not a substitution of the earlier native result.

Existing files in docs/selfhost-language retain worker-migration-attempt-1.json, worker-migration-fixture-repair.json, worker-migration-attempt-2.json, worker-migration-abi-repair.json and their primary logs. Preserve them alongside the actual final worker-migration-qualification.json, worker-migration-provider.json and worker-migration-evidence.json. The final publication also updates the candidate/qualification ledgers to the proven fcd result; it does not erase failed history or create another qualification.

## Selected R and proven TypeScript 7-only native recovery

R source fe2560aba0f347b1caf8d000d371464642d44f23 qualified in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635). Compiler job 113804052074, independent provider job 113827136830 and original parent-based cold job 113827137018 passed. Explicit selection is commit e65606397fb679d7cb96f4f0e92700a6cf0944a6. The later collector run 37938411520 retained 18 exact receipt files.

- R source closure: f96c811f575cae2be58ccca3ffe587ead83bffa6f8bd862d40936bef28ef3226.
- R selected identity: 47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225.
- Selected manifest actual file SHA-256: 7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694.
- Selected manifest Git blob: 44a05964c49000478c282afc013c84fca8c2de65.
- Current selection does not depend on promoting F.

| Exact selected R product | SHA-256 |
| --- | --- |
| Canonical PS source JSON | 985cf39d4a68df68a03123883105b6bdd9b81783c4bab98c8ec86ec683ac3b07 |
| Canonical admissions | 200e5881d1554f72530a0395524ee28dd3a64a6bd45f55cddd4fad1336981bf0 |
| TypeScript | 38fea23209f561efcab0c0111a2a15fa1e5761d33f31100fac8d6bfb1e032935 |
| JavaScript | 70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061 |

### New cold proof — already successful

[Run 37947341899](https://github.com/dwijayuda/pskernel/actions/runs/37947341899), job 113876930974, source fcd, passed at 14:54:23 UTC. It used no restored compiler artifact, seed cache or native build cache. All 75 recorded commands, including 61 native PS translations, succeeded. All four products above matched, and the tracked raw source, closure and selected manifest remained unchanged.

The native recipe is native-lean-original-ir-four-products-ts7/1. Its original IR check accepted 56,391 expressions / 725,484 visited steps / zero findings, then emitted that same IR. No generated compiler, historical A/S0 compiler, or TypeScript 5 was executed. The exact selected-R seed identity is preserved; this is a new recovery recipe, not a re-identification of the seed.

- Recipe SHA-256: 4ed186c2604bcfaee756881686e70f14569720d72fcd799d9997d2d92217b82a.
- Policy SHA-256: 0cf0480524ba713e0bcdbeb3cfa3d345e37508743ee5e169b83ba8ee0de160fc.
- Runner scripts/sh1-native-seed-recovery.mjs blob: 4e2fe462ba5c8160ff5c08f70ce52152173b0d6f.
- selfhost-seed-recovery.json blob: fd75854159544e431497bc7dee8482bea727b5e4.
- Independent workflow .github/workflows/psc0-sh1-ts7-recovery.yml blob: 4512b46247642f2ab6043a5d81ba8d2a62fd703f.
- Exact receipt SHA-256: 0d5606c25e634082da39d80ffa5974b3c390d2765ded71bcf1abaf442b7e3919, 64,164 bytes; blob c495ddf6e7d5075e204e4b0c5957c8c0d3d6a24b.
- Full decoded log SHA-256: 6f47360b88446d7a06f12561772e8d9e317b1f3bfb6d34d610791436f99b3957; blob d5ae70f7459ad82ba2aa3a23043e374921fb2316.
- Artifact ID 11624048503, ZIP digest 967adc94a58d02e4e166e24601252f177a372dc5e6fd50ba01a7125cec9dfae5. Archive bytes were not downloaded by the reviewers.

Recorded recovery work was 86.497 seconds; the whole job was 158 seconds. The old parent-based recipe recorded 2,728.787 seconds in a separate run. This is not a controlled benchmark or a measured PSC parsing/self-compilation speedup.

Root and grammar_adoption_audit independently checked the actual completed run/jobs, complete log, 75-command receipt, all four hashes, source/manifest invariance and policy pins. The final cold retention/evidence bundle dd600ce1b24a4e7090ba9d5fa47012b875174d82 is published in 4c2cfec187ec0b48d1dfbc091066b9f1dd763215, with five retained evidence files plus the provenance record (six paths total). Its verified paths are listed below; no additional cold job remains:

- docs/selfhost-language/typescript7-native-recovery.json.
- docs/selfhost-language/typescript7-native-recovery-evidence.json.
- docs/selfhost-language/evidence-logs/typescript7-native-recovery.log.
- API metadata under docs/selfhost-language/seed-evidence/fcd875c8f38db4b0524090bd10c7c2fd5024053d/.

Current PSC0 rejects seed-identity, recover-seed, recover-qualified-seed and recover-successor-seed before resolving TypeScript. Cache misses use the pinned native runner. Do not restore the old TS5 dispatch or repeat the retired full-source TS5/TS7 comparison.

The independent provider remains source 963030dc2d154008fccc82e7c8ed29331f138799, tree 38c8c55bd2b214753e56c58c15c4901c32c01b86, binary 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec. Lean commit is 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b; fuel 131072 and timeout 60000. Its acceptance is a separate post-emission gate.

## Root workspace TypeScript 5 retirement

The root workspace is distinct from psc0. TypeScript 7.0 has no old programmatic compiler API, so changing version strings alone was insufficient. The implementation replaces the one API importer in packages/backend-ts/src/typescript-compiler.ts with an exact installed-7.0.2 CLI adapter. Microsoft primary reference: https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/.

All 21 root/package TypeScript pins are now 7.0.2. Ten unsupported baseUrl fields were removed without changing paths or output layouts; existing rootDir/outDir preserve dist/src exports. Root/backend Node types are explicit at 22.15.3. Two remaining selfhost launchers require 7.0.2 before compilation and use --ignoreConfig.

### Root source commits and bounded corrections

| Source | Change and actual evidence |
| --- | --- |
| a02f03b97bb3385b66ad670dabf7f13d334fc79f | 40-file initial root migration. Run 37949490366/job 113884245962 passed lock resolution, clean TS7 install/profile and root build, then the new map-footer test required a trailing newline that the adapter already makes optional. |
| 3fce771a3607341ce0c9dfc1f1fa3974e2f0dbab | Committed exact npm lock and changed only that footer assertion to accept EOF/LF/CRLF after the same URI. Run 37950075083/job 113886266262 passed complete package tests and all 11 adapter obligations plus conformance build; the additional lean4export build exposed an existing inaccurate stdin type. |
| 5d3cbc82cb8759b909d1a957d6a22d542509d8c5 | Type-only ChildProcessByStdio<null,Readable,Readable> declaration matching the unchanged ignored-stdin/piped-output spawn. Run 37950522687/job 113887806499 passed all builds, package tests, 11 adapter obligations and package integration; final package-map check found a pre-existing source-language metadata mismatch. |
| 9d150afbec1feda8c97058aa56aa5ab92347d96d | Aligns the compiler map with its existing mixed-source manifest and paired files; replaces the stale Compiler API note; strengthens exact nonempty language matching across all 20 outer packages. Full root run 37951869293 passed all seven command phases and all eleven adapter obligations; no additional source correction is needed. |

No adapter implementation changed after the initial reviewed CLI replacement. The footer correction changes one test formatting assumption; the exporter correction changes types only; the map correction preserves actual paired-source inventory and every other boundary rule. No native bootstrap target is qualified by the root gate.

Before the latest root run, independent static review read all 178 TS files in the exact twelve source-shape scopes, all ten editor inputs, all 20 package manifests, the complete package tree and all remaining architecture obligations. No further violations were found: maximum TS 300 lines / 201 characters; editor modules 228 lines / 88 characters. This was source review, not a substitute for the actual gate.

### Adapter contract

compileTypeScript remains synchronous and preserves its result fields. It verifies installed package metadata and actual launcher version, creates an exclusive unique sibling source in the logical source directory, emits into a private temporary directory, selects root JS/declaration/map products, restores logical diagnostic/map names, and removes private files in finally. Original logical source and existing output products are not overwritten.

It supports ordinary .ts input names in an existing writable parent directory. The real project CLI creates that directory before calling it. Relative TS imports and package exports are covered. Original-basename self references, unsupported source kinds, malformed maps and basename-dependent emitted output are explicit refusals. This is not a general arbitrary virtual-filesystem compiler host. No TypeScript 5/6 API fallback is permitted.

The actual completed PS_ROOT_TYPESCRIPT7_CONTRACT record has schema psc-root-typescript7-contract-v1, TypeScript 7.0.2, passed=true and these eleven exact obligations: virtual-source-and-existing-products, logical-map-name, config-independent-positional, relative-typescript-import, package-export-import, root-output-selection, logical-diagnostic-position, self-reference-refusal, declaration-input-refusal, missing-directory-refusal, stage-cleanup. The record is at primary-log line 392 and is preserved as compact stdout evidence; it is not invented as a standalone original artifact. The root qualification establishes the supported CLI-host/package contract at the exact source, without claiming arbitrary virtual compiler-host compatibility.

Key current blobs: adapter 1f178560ba824e58538235e93d348a7c97ab54e9; contract test b57719346e08faec054bb1287fc1c36459d79cd7; root gate runner 1dc573166836765fc7b8d0fa4714b5d1d29ae609; workflow 348ab35eaf3210b5a96ac53c08d7c5b201c29c1e; exporter type correction b9b86b7f10584756fda519221e47895ce526038f.

### Exact root lock

package-lock.json is the actual 21,592-byte npm-generated file from the initial cloud run. SHA-256: 69c5e49b040ff3d45909e15cf1e2123af39fa223b00a7241b533c022a49e33e1. Git blob: 19fef24fac3018dcac4949b79a4d0dcdd5d6d0eb.

It was resolved with --package-lock-only --ignore-scripts before any installation, then installed with npm ci and rehashed. Every one of the 21 source/lock/profile manifest bindings was independently checked. The exact file has remained identical in subsequent runs. Do not fabricate, reserialize or invent registry metadata/integrity.

Final installed-profile file SHA-256 is 630d6c0e07ca2eba789b21fbe978303b174979c25be192b8e0167fb7969d3dbe (4,644 bytes); installed TypeScript package metadata SHA-256 is 3722b30210616a13a3213ded11575ba6b2dbab10c32a5ef67afca8513e27017e (3,087 bytes); the uploaded five-file evidence-index SHA-256 is 209cd0b9a0bce52405579a1f7c2dc9878b8beb4f890a2bda15e6dd4dcf6a82b4 (820 bytes). The final passing run used lockGenerated=false and npm ci only. The root gate records command/output and installed-profile/lock evidence; the four-product self-host fixed point belongs to the separate PSC0 F gate.

The root runner logs exact JSON file content in PS_ROOT_TS7_EVIDENCE_FILE or ordered MANIFEST/CHUNK records. Concatenate decoded content with no separators and verify actual UTF-8 byte count/SHA. The adapter's PS_ROOT_TYPESCRIPT7_CONTRACT is a compact stdout record, not a standalone receipt file. Preserve that distinction.

The successful root result has been independently authenticated and is published in 4c2cfec187ec0b48d1dfbc091066b9f1dd763215. Its path bundle c3b0275e848fa93f3f33528a8fe239766486a115 maps 48 files, comprising the current root guide update and 47 evidence files; the bundle manifest itself is also committed. Failed attempts remain failed; their earlier completed phases do not imply whole-run qualification. Root source correction, evidence publication and integration are complete; no qualification retry is pending.

| Successful root proof | Exact identity |
| --- | --- |
| Evidence index blob | 87dc087ead86d551a6b2e48f0594dd858e7b1b83 |
| Complete primary log blob | f59f0590c714205f93826c9512c1c0c438a41418 |
| Primary log SHA-256 / UTF-8 bytes | 5836caa0146f2002bec6954ce285ab7789e7ac1758ede4da80248448cdc79e86 / 84,888 |
| Full API + exact manifest sources + inheritance proof blob | 45b848ea37dacd4f9aba554b8d90fd794c7cfdb6 |
| Complete authenticated report blob | 83977c047ba4a382d0512ec9294ba1bbcf30d29e |
| Original qualification.json blob | 31ec99a5260603659e38ad24c33028c510b46e93 |
| Original qualification SHA-256 / bytes | a6f2b2e31ca61a8249954d43849bb622d01b876db7f8046a67353ce82e9de39a / 3,485 |
| Original installed-profile.json blob | 68ab7c2309f8722988d71d05f05743693f794851 |
| Original installed TypeScript metadata blob | f4242a69df961fcaf5210ac08ace176ced18c6a4 |
| Original uploaded evidence-index.json blob | c77c051646afea76427cb175cb14f85c80b0a8cd |
| Artifact ID / size | 11626670229 / 13,228 bytes |
| Artifact archive SHA-256 | a424a5c9bacbc31caf51160c471266401d0d4c520b87bce7cb3100c60d552cf6 |

Final root evidence paths are under psc0/docs/selfhost-language: root-typescript7-qualification.json for the exact receipt; root-typescript7-evidence.json for provenance; evidence-logs/root-typescript7-qualification.log for the full log; and seed-evidence/9d150afbec1feda8c97058aa56aa5ab92347d96d/root-typescript7/ for the five exact files, APIs, complete reviews, source-inheritance proof and all three failed attempts. The root developer guide is docs/TYPESCRIPT7.md, blob 5f36452b237599396b54365deb356cbb8b90b14a. All final path mappings are complete in bundle c3b0275e848fa93f3f33528a8fe239766486a115.

## Completed integration and future continuation

All requested bounded source/toolchain/recovery qualifications, evidence publication and canonical branch integration are complete. There is no outstanding agent result, source fix, test suite or broader research to await for this task.

1. Begin future changes from the live canonical branch psc0/sh1-implementation-v1 after reading this handoff and docs/selfhost-language/CURRENT.md. Use a new work branch when appropriate, preserve concurrent work and record fresh head leases before non-force updates.
2. Preserve the immutable qualifying source identities, selected-R manifest and current TS7-only recovery policy. Documentation descendants do not change what source a successful run qualified.
3. Keep future authoring within the implemented ps-0.9-r3/new-only/bounded-selfhost-subset contract. The 61 handwritten Lean modules remain authoritative. The 226 deferred inventory locators and broader Standard/PSCV/strict-SH1 work are future scope, not hidden unfinished steps in this completed finite migration.
4. For a newly requested source change, diagnose and review the affected class first, use the resident preparation loop for short iteration, and reserve complete qualification for a coherent semantic/toolchain/recovery checkpoint. Do not relaunch successful qualifications for documentation, evidence retention or a branch fast-forward.
5. Keep this file current after concrete milestones and before any handoff. Explain new risks or unsupported forms from exact evidence; do not revive TS5, old grammar fallback or an archived seed-recovery instruction.

### Integration publication record — completed actual writes

The final evidence publication is [4c2cfec187ec0b48d1dfbc091066b9f1dd763215](https://github.com/dwijayuda/pskernel/commit/4c2cfec187ec0b48d1dfbc091066b9f1dd763215), tree 2935b38a17157fc214e4a0ec09d99a91469ef522, sole parent 8d922c3f47f59a8d7285bfdf998791f042b483b9. It contains exactly 121 planned file changes: 15 modifications and 106 additions, with zero deletions or unexpected deltas. Every new blob matched the prepared path manifest. Only the root docs and psc0 tree entries changed; the other 36 root entries are identical. Complete non-truncated PSC0 subtree comparison proved the executable packages, host, scripts, test, lean-checked and stdlib subtrees unchanged.

The retirement branch publication used expected head 8d922c3f47f59a8d7285bfdf998791f042b483b9 and force false. Projection advanced from fcd875c8f38db4b0524090bd10c7c2fd5024053d; canonical implementation and the earlier TS7 alias advanced from 5e3a991088aaa735c8f324c4e70a7a3dee4cd69a. Each write used the freshly read expected head and force false. All four branches were independently read back at 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 at 2026-10-09 16:02:49 UTC; main was independently read back unchanged at 37f63c39d4a07189938046c64152bba25d789450.

The protected selected-R manifest is still Git blob 44a05964c49000478c282afc013c84fca8c2de65, SHA-256 7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694, with selected identity 47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225. psc0/selfhost-seed-recovery.json remains blob fd75854159544e431497bc7dee8482bea727b5e4. No executable source, provider, kernel, toolchain pin, recipe, seed selection or qualification result changed in publication or this documentation-only closeout.

The machine-readable actual snapshot and protected-tree review are in docs/selfhost-language/integration.json. The complete initial publication catalog is docs/selfhost-language/completion-publication.json, blob e8c936151435a59e1e26237bc311b1f55f866cfa. That catalog describes the initial 4c2cfec187ec0b48d1dfbc091066b9f1dd763215 snapshot; the final handoff and qualification ledger are deliberately updated in this containing documentation-only descendant to record completion. Re-read live refs instead of assuming a historical snapshot equals a future branch HEAD. No extra test or qualification run was needed for these documentation-only updates.

An unforeseen future publication guard mismatch should be diagnosed from its exact diff; it does not invalidate a successful immutable source qualification or justify fabricating a pass. A data-reviewer schema mistake likewise remains distinct from a pipeline failure.

## Durable final bundles and developer entry points

The final state is recoverable without live agents or in-memory store keys. All the following identities are immutable Git blobs. Fetch them through the GitHub connector/API; no local checkout, build or test is needed in this cloud-only session. A functions-store reset previously occurred around 15:23 UTC; the retained blobs and committed source, not a private scratch key, are continuation authority.

| Published immutable bundle | Blob and scope |
| --- | --- |
| Complete F primary evidence and provenance | 5ed0a4f6cff3d48672df34076b7ac8801c9299a4; 47 mapped files plus its own manifest target; successful compiler/provider runs, full logs, all 32+2 receipts, all worker/Core/IR/generic/capability/probe arrays and exact APIs |
| Root TypeScript 7 guide/evidence | c3b0275e848fa93f3f33528a8fe239766486a115; 48 files, including docs/TYPESCRIPT7.md and complete successful/three-failed-attempt evidence |
| TS7-only native selected-R cold evidence | dd600ce1b24a4e7090ba9d5fa47012b875174d82; five retained evidence files plus the provenance record (six paths total), no new cold run |
| Final eleven PSC0 guides | a609ae5dceef9b20fecab5d4b68413d8e9ed954f; supersedes d4c9cc45dbf539f4bf85e1bca0bca1085a3ec947 after the final three stale-sentence corrections |
| Actual guarded F document inputs | b2a8a19c506f52316ed30f4ec88682d69e794b87; exact successful source/run/job/product parameters and seven actual evidence objects |
| Final narrow guide correction pass | 0dcff689d07bc590d78332b70bcfb7f340c88e33; three exact guarded current-F status corrections, no source change |
| Qualification ledger at initial evidence publication | 9efa5cb3f82f03fb49cfc5b847aeae49ab272759; historical publication snapshot. The current docs/selfhost-language/qualification-evidence.json in this containing closeout supersedes its integration-pending status; every source-proof/history field is preserved |
| Final worker candidate ledger | 0a9decf3c75c45898697a4284d3877eb6bb5d732; actual successful finite F evidence with failed history and selected R preserved |
| Exact worker-to-source mapping and document review | 48fdd86397ba8fff5d5ba48a3bcf75d40c5b509b; twelve workers in nine files, three aliases in a tenth, protected 226 deferred locators |
| Successful F pure-data reader | 490cc9d968bddd92da1ad67e39b3880a35349580; both compiler/provider reviewers applied successfully to complete authenticated primary inputs |
| F reader contract | 31293d61303666b1b6f82071c0bfc1f20316254b; exact input/representation and bounded-claim contract |
| Successful root pure-data reader | fe3478ead5638f8647e67a5ef2a2f2de4e2eb896; original passing and failing file evidence authentication, retained as inactive .txt |

The guide reconciliation has already passed all 108 original operation guards (16 source-status plus 92 qualification operations), 24 TS7 post-pass operations, ten disjoint prose guards, seven immutable locator hashes and nine global guards. The final eleven-guide independent check verified ten source/hash bindings, nine evidence copies and 24 links, then applied the three recorded stale-status corrections. Selected R, all 226 deferred locators and immutable historical proofs remain intact.

The final eleven PSC0 guide paths are psc0/README.md and psc0/docs/selfhost-language/{README.md, IMPLEMENTATION.md, MIGRATION.md, SPEC.md, proposal.json, migration-backlog.json, MIGRATION_BACKLOG.md, CURRENT.md, PS_GRAMMAR_ADOPTION.md, TYPESCRIPT7.md}. The root workspace entry point is docs/TYPESCRIPT7.md. TYPESCRIPT7_CHECKPOINT.md is explicitly archival; old TS5 comparison/producer facts are preserved there without a current execution path.

Begin future authoring at psc0/docs/selfhost-language/CURRENT.md. Use SPEC.md for implementation boundaries, MIGRATION.md and migration-backlog.json for the finite completed/deferred scope, PS_GRAMMAR_ADOPTION.md for syntax/reference errata, and TYPESCRIPT7.md for current PSC0 TS7/recovery behavior. Receipt identities, rather than an old heading containing the word current, determine which claim is established.

### Evidence interpretation and immutable render provenance

Pure evidence readers inspect authenticated data; they do not execute compiler code or create kernel proof. Both reviewers independently checked the complete F run/jobs/logs. Compiler compact JSON plus LF is retained with its own explicitly labelled digest. The native cold receipt is exact because the complete logged object reserializes to its separately emitted original file digest. Provider and root envelopes preserve actual read-back file content and byte counts. Artifact ZIP digests are separate from file/log digests; no archive download is implied.

The completed guide-render provenance remains available as template 947971df08c812200f9f71138d6ce4a7c4741a0e, pure-data instantiator 697e9a1f4e635c446a237b1bb268955a003a04da, TS7 post-pass 9b719316fd4297bab7e73cfd8b1bdd7bf6999cd3 and disjoint prose pass 9aa835eaac9e6dc69ae8227e57503b2637432d52. They describe already applied and reviewed transformations; they are not pending tasks or an invitation to replay old inputs against current files. The actual completed input bundle and final guide manifest above supersede obsolete draft/base lists.

For earlier implementation/history reconstruction, root's initial 40-file TS7 bundle is c423053bd360ed4db193c450f52aec8fe9e24a1c and its metadata-correction/static-audit bundle is e712fce4a08e4bc9723a91523a2de54502f21957. The initial native cold retention review is 310c41f7a9b4d7a4052d9ab3c5a81795bd606ab3; the final cold bundle above maps its files to the agreed repository paths. These are completed provenance, not outstanding source work.

Root completed publication and branch integration. The projection, grammar and migration agents completed their source, evidence and document reviews. New chats should use the committed handoff, current guides and immutable manifests; no unavailable old agent or scratch store is required. Do not repeat an already successful audit without a concrete new change or mismatch.

## Daily development from the completed checkpoint

From psc0, the supported short cycle is:

    npm install
    npm run check:typescript-profile
    npm run dev:sh1
    PSC0_ITERATION_SHA256="$(node -p "require('./dist/sh1/N1/receipt.json').artifacts.javascriptSha256")"
    npm run iterate:sh1 -- --compiler dist/sh1/N1/index.js --compiler-sha256 "$PSC0_ITERATION_SHA256" --loop

These are developer commands, not permission to execute repository code locally in this cloud-only session. The resident loop accepts prepare/Enter, emit, reset and quit. It retains preparation state and invalidates the changed module and dependent suffix. Restart when the compiler changes. emit produces TypeScript; it does not replace fixed-point/provider qualification. Use full qualification for coherent semantic/toolchain/recovery checkpoints, not for every small edit.

Root development uses the committed TS7 lock with npm ci and the documented package commands in docs/TYPESCRIPT7.md. The active root API is the TS7 CLI adapter. Historical TS5/TS7 measurements remain historical; no whole-pipeline or worker speedup is claimed without a suitable measured comparison.

## Historical completed M6 and TypeScript 7 result

This section preserves the completed checkpoint before the active R/F continuation.
Its selected-seed, integration and next-step descriptions are historical; the
active status above is authoritative for this continuation.

The bounded portable runtime IR checker, same-IR checked emission and scoped-let
backend correction are qualified under TypeScript 5.8.3 at
`1b5fd12382c920944924c9d03e0851984293caa2`
([run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597)).
Current PSC0 TypeScript 7.0.2 integration is qualified at
`99786185f77edf952f11989d4c9bc44028f22f11`
([run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506)).
The second source retains the same portable M6 code. Both checkpoints have
separate compiler and selected-provider receipts.

Canonical integration uses a normal fast-forward of
`psc0/sh1-implementation-v1` to the qualified TS7 descendant and documentation.
The exact qualifying source remains the immutable reference above; a later
documentation commit does not claim a fresh compiler run.

The independently qualified M6 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` records:

| Evidence | Observed result |
| --- | --- |
| Portable compiler source | 61 modules; 1,088,337 bytes |
| Native full original IR | 54,879 expressions; 707,753 visited steps; complete; accepted; zero findings |
| Native fixtures | Eight cases passed |
| N1/C1/C2/C3 runtime conformance | 59 observations per generation, including 29 observations across four let-scope cases |
| Generated checker refusals | 36 negative IR cases and five malformed/foreign carrier cases per generation; resource and direct type-operation cases also passed |
| Current C2/C3 full original IR | Complete; accepted; zero findings; same original IR checked before emission |
| Current C2/C3 products | Canonical surface source, normalized admissions, TS and JS agree; N1 TS/JS also agree |
| Independent selected provider | Three exact admission streams accepted after emission |

The generated C2/C3 summaries do not print their full expression or visited-step
counts. Those fields are not inferred from the native counts; their full reports
remain in `dist/sh1/C2/original-ir-inventory.json` and the corresponding C3 artifact path.

The native development gate's internal total was 144.586 seconds. The C1/C2/C3
generation totals were 1,145.486 / 1,187.825 / 1,199.391 seconds.
Across those three generations, preparation accounted for 60.17% of the recorded
total; `tscAndWrite` accounted for 30.655 seconds, or about 0.87%. The latter
includes evidence writes, hashing and identity work as well as TypeScript.
These are observed phase timings from one qualification run, not controlled benchmarks.

The compiler bundle preserves all 28 complete logged JSON receipts, including
their original provider-not-attempted fields. The separate later provider receipt
records `accepted: true` and `emissionWasGatedByThisCheck: false`.
Compiler qualification, bounded IR typing and exact-stream provider acceptance
are earned; strict SH/1 and profile activation remain false.

See [runtime-ir-checker-qualification.json](docs/selfhost-language/runtime-ir-checker-qualification.json),
[runtime-ir-checker-provider.json](docs/selfhost-language/runtime-ir-checker-provider.json) and
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json)
for complete receipts and the retained attempt history.

Current emission uses exact TypeScript 7.0.2. Historical S0/A recovery uses exact
5.8.3, including a byte-checked TypeScript replay when reusing authenticated A.
Frozen recovery receives and verifies its actual historical child launcher
before building. The root workspace still uses the old TypeScript programmatic
API and remains on 5.8.3. Lean 4.34.0 and Node 22.23.3 keep their pins.

The completed same-source comparison compiled the full emitted compiler with
TypeScript 5.8.3 in **9,281.561787 ms** and 7.0.2 in **2,866.119670 ms**.
That single sequential pair gives a **3.238× direct-CLI speed ratio** and
**69.12% less elapsed time**. It includes startup, checking and emission; it does
not measure the complete self-host pipeline. The input TS SHA-256 is
`f20c9132ae2f8adade08346b0457f6bb02b6e5145097116d2a827121304a8f70`.
See [TYPESCRIPT7.md](docs/selfhost-language/TYPESCRIPT7.md) and
[typescript7-qualification.json](docs/selfhost-language/typescript7-qualification.json)
for the exact measurement and scope.

A remains the selected authoring seed. Compiler qualification, bounded runtime
IR typing, exact provider acceptance and strict SH/1 are separate. Strict SH/1
and named-profile activation remain false. Kernel/provider implementation,
defeq/cache internals and metatheory are unchanged.

The execution histories retain all source-form and emission findings, without
rewriting earlier failures as passes:
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json),
[first complete native acceptance](docs/selfhost-language/runtime-ir-checker-first-native.json)
and [typescript7-execution.json](docs/selfhost-language/typescript7-execution.json).
The source-compatible callback/match/record-alias forms are documented in
[SPEC.md](docs/selfhost-language/SPEC.md). The general projection-normalizer
repair remains future work; no syntax exception or checker weakening was added.

## Current source and qualification checkpoints

The current qualified integration source is the TypeScript 7 M6 checkpoint
`99786185f77edf952f11989d4c9bc44028f22f11` above. The earlier recursive
generic-argument repair E,
`cf8fbd784944a98b1e390b709685ca54c2511827`, was independently qualified on
`psc0/sh1-generic-erasure-v1`: compiler and pinned-provider jobs passed on the
first execution of [run 37852341550](https://github.com/dwijayuda/pskernel/actions/runs/37852341550).
Its parent helper migration H,
`671685c3f0059574405a1e630dd965d421a26f05`, independently passed both jobs on
the first execution of [run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475).

The canonical integration branch is `psc0/sh1-implementation-v1`; integration
preserves each feature branch's source/qualification provenance and uses normal
fast-forwards. Documentation-only descendants preserve the exact qualified
executable sources.

| Checkpoint | Source commit | Result |
| --- | --- | --- |
| A: recursion capability and preparation/session implementation | `e91b9558d665879871b8bf0893915ae64b27c7fe` | Compiler-qualified and exact admissions accepted; remains the selected authoring seed |
| B: Foundation.List migration | `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0` | Compiler-qualified and exact admissions accepted on its first migration execution |
| H: three compiler helpers | `671685c3f0059574405a1e630dd965d421a26f05` | Compiler-qualified and exact admissions accepted on its first execution |
| E: recursive generic-argument erasure | `cf8fbd784944a98b1e390b709685ca54c2511827` | Compiler-qualified and exact admissions accepted on its first execution |
| M6: bounded runtime IR checker and scoped-let correction | `1b5fd12382c920944924c9d03e0851984293caa2` | Qualified under TypeScript 5.8.3, with current IR typing and separate provider acceptance |
| Current TypeScript 7.0.2 integration | `99786185f77edf952f11989d4c9bc44028f22f11` | Same portable M6 source qualified under 7.0.2; historical recovery remains 5.8.3 |

Compiler qualification, Core-provider acceptance and strict runtime SH/1 remain
separate axes. Strict SH/1 is still false, and psconfig retains the existing PSC1
bootstrap lane. No named profile was activated by these changes.

## Completed implementation in this continuation

The helper migration H changes only `Elab/Term.lean` and
`Erasure/Definition.lean` inside the portable closure:

- `psExprApplyManyWorker` now takes its expression accumulator as an ordinary
  explicit parameter.
- `psExprAppViewAccWorker` now takes its argument accumulator as an ordinary
  explicit parameter.
- `psErasureAddUniqueStringWorker` now takes its changing candidate base as an
  ordinary explicit parameter while descending through Nat fuel.

All public worker/wrapper names, complete types, argument order and algorithms
are preserved. The unique-name helper retains its exact zero-fuel and collision
exhaustion suffixes. The three guards accept historical and qualified forms
while retaining wrapper, primitive and unrelated source/admission checks.

The correspondence gate compiles preserved/current raw helper slices with actual
Name/Level/Expr dependencies. It checks seven public types and 2,198 observations
per compiled slice, including typed partial applications. A separate 1,568-observation
check exercises actual exported helpers in each generated compiler. All of these
checks passed on the first compiler execution of both H and E.

The isolated E repair changes `Erasure/Basic.lean`, `Erasure/Definition.lean`
and `Erasure/Expr.lean`. `PsErasureCurrentDefinition` now retains a reversed
accumulator of the current declaration's generic arguments. Type binders record
their assigned Tn in order; runtime and erased proof binders preserve the context.
Recursive induction-hypothesis calls receive the restored declaration order.
The implementation neither captures unrelated local types nor whitelists helper
names.

The focused fixture checks exact original-IR argument order for one, two and
three generics, interleaved proposition/proof/runtime binders, and a monomorphic
control. It emits the same IR object whose calls were asserted. All N1/C1/C2/C3
executions passed 19 behavior observations; N1/C1 also passed native parity.
Kernel/provider implementation and metatheory were unchanged.

## H evidence before the erasure repair

H's compiler job `113565800146` passed on its first execution in
[run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475);
provider job `113583716467` also passed on that first execution.

H contains 56 raw modules / 991,563 Git blob bytes, a reduction of 327 bytes
from B. Raw source closure SHA256:
`03c493835b44507fbe692f065f953f9c8252a44edcdf7e62932c3608831d0903`.
C1/C2/C3 agree on canonical surface, ordered admissions, TypeScript and JavaScript.
N1's TypeScript/JavaScript also agree with the generated generations.
The generated JavaScript SHA256 is
`fb7708698c333c1985ae82c0eb5b061c8738f41feffc12f3fddccb1c74fc6855`.

All three full-source inventories complete with 244 expression-typing obligations
and 19 type-argument arity findings. E's isolated repair resolves the latter
category below. H recovered the pinned A seed from its verified cache.

The unchanged pinned provider accepted H's two deduplicated compiler/capability
admission streams after emission. Its preserved receipts are
[qualification](docs/selfhost-language/helper-migration-qualification.json),
[helper correspondence](docs/selfhost-language/helper-migration-correspondence.json),
[small compiler receipts](docs/selfhost-language/helper-migration-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/helper-migration-provider.json).
The provider identity and checked-emission boundary are the same as E below.

## Historical E evidence before the portable checker

Run 37852341550: compiler job `113568120771` and provider job
`113579690742` both succeeded on the first execution.

E contains 56 raw modules / 992,338 Git blob bytes. Raw source closure SHA256:
`d7866a3c8da745db5b0f6c7ce67381915f6265263615c13a243ec674c1ab13e2`.

C2 and C3 agree on canonical surface, ordered admissions, TypeScript and
JavaScript. Their generated JavaScript SHA256 is
`b6783f5d3ae25fe2da233da3a2c607445efa007a62bbde0275cfa6b8b8b04816`;
native-generated N1 has the same JavaScript bytes. C1's JavaScript is
`d3fd03481ce03d4d2f962f932d4987aff28a7dcf68a395467be2dc57f1d60a2c`.
Its difference is permitted by the C2-versus-C3 contract: the older Q produced
C1's IR, while the new C1 executable contains the repaired erasure used for C2.

The complete C2/C3 IR inventories have **zero type-argument arity findings** and
**244 call-expression typing obligations**, with no other recorded categories.
C1 retains the historical 19 type-argument arity findings in its Q-produced IR.
B's 244-plus-19 result and its empty generic erasure context are historical;
the new repair must not be listed as future work again. The remaining 244
records identify unfinished expression typing, not 244 proven runtime failures.

The unchanged pinned provider source is
`963030dc2d154008fccc82e7c8ed29331f138799`, with binary SHA256
`88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
It accepted three deduplicated streams: E compiler admissions, raw .lean/.ps
capabilities, and the focused generic-erasure fixture. Default fuel 131,072 and
timeout 60,000 ms were unchanged. Emission preceded this separate check;
`emissionWasGatedByThisCheck` remains false.

Exact qualification, correspondence, compiler and provider receipts are indexed
in [docs/selfhost-language/qualification-evidence.json](docs/selfhost-language/qualification-evidence.json).
E's preserved receipts include
[qualification](docs/selfhost-language/recursive-generic-erasure-qualification.json),
[C2 generic conformance](docs/selfhost-language/recursive-generic-erasure-conformance.json),
[small compiler receipts](docs/selfhost-language/recursive-generic-erasure-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/recursive-generic-erasure-provider.json).

## Seed, development workflow and next work

The selected authoring compiler Q remains A from
`e91b9558d665879871b8bf0893915ae64b27c7fe`, with JavaScript SHA256
`9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096`.
Do not silently promote E, M6 or the TS7 compiler as the seed, or claim the
historical S0 can consume the migrated source. Preserve the authenticated S0 -> A recovery route and A's
qualified seed cache/artifact identities.

Ordinary edits use `npm run dev:sh1`; `npm run iterate:sh1 -- ... --loop`
provides optional resident preparation reuse. Full runs also execute the bounded
native gate before expensive selected-Q generation. Source-family and semantic
milestones receive C1/C2/C3 plus exact provider checks, selected by
`[sh1-qualify]` or full manual dispatch. Independent checkpoint branches may
qualify in parallel. H and E passed their native, compiler and provider gates on their first
execution. M6 and TS7 preserve their separate attempt histories above.

H's bounded native gate took 39.951 seconds, and E's took 25.886 seconds.
Full C1/C2/C3 generation totals were 993.651/1,011.667/991.582 seconds for H and
607.562/606.556/632.401 seconds for E. These are recorded single-run scopes,
not a benchmark or a general speedup claim. The earlier 14.590-second
development result used a smaller bounded gate; warm resident preparation
measurements exclude source reads and optional emission.

The current TS7 native development gate recorded **106.462 seconds** internally
(`106461.999493 ms`), excluding the preceding `lake build`. Current C1/C2/C3
generation totals were 1,065.963 / 1,111.846 / 1,153.540 seconds. These
single-run stage totals are separate from the direct CLI comparison and do not
attribute all cross-run timing differences to TypeScript.

The qualified bounded M6 implementation is described in
[docs/selfhost-language/RUNTIME_IR_PLAN.md](docs/selfhost-language/RUNTIME_IR_PLAN.md).
Its portable expression checker covers the active current IR, with scoped
simultaneous type substitution, checked body/initializer annotations, exact
function grouping, global value/function distinction and explicit resource
failures. The current host inventory reports that portable checker.

The recommended next language slice is the bounded parameter-projection
normalizer repair in MIGRATION.md. Keep its implementation consumable by A and
qualify direct raw-source uses of the repaired form. Replace compatibility aliases
only after a separate explicit qualification and selection of a seed that accepts
that authored source.

Strict runtime enforcement additionally needs enabled primitive/layout/import
and scalar/bounds/text-position contracts, erasure/backend correspondence and
generated evidence for the enforced path. Neither zero type-arity findings nor
Core admission acceptance grants strict SH/1. Broader optional source conveniences
and .ps authority remain separately gated future work.

## Scope of this work

Implement the accepted self-host authoring and iteration plan from research commit
80d04e7ab0e9214ffecf093a6272865f0eaca096. Start with ordinary structural recursion
that changes nondependent value parameters, a pure preparation seam, and focused
generated-compiler qualification. Migrate source families only after capability
evidence passes.

M6 TS5 qualification branch: psc0/sh1-ir-checker-v1.
Current TS7 qualification branch: psc0/typescript-7-v1.
Qualified integration branch: psc0/sh1-implementation-v1.
Historical compiler baseline: 37f63c39d4a07189938046c64152bba25d789450.
The historical 55-module record remains immutable.

## Boundaries

- GitHub/cloud only; no local checkout, builds or tests.
- Kernel/provider implementation and metatheory belong to the native workstream.
- No profile activation or checked/native success claim without corresponding evidence.
- Keep current public compiler APIs and source signatures compatible.
- Solve shared semantic/architectural causes; do not weaken gates to obtain a pass.
- Use focused validation for a complete implementation slice, then current-source
  C2/C3 qualification at the milestone.

## Historical execution notes

The following notes retain their original execution-time status from the initial
implementation and first migration. Pending statements below are historical;
the current checkpoint and next work are stated above.

### Implemented architecture

- Recursion: canonical stable/major worker plus function-valued generalized state;
  preserve public binder kinds and argument order with a wrapper. Reject unsupported
  dependent telescopes and escaping self references.
- Provenance: inspect and enforce which nested matches may introduce decreasing children.
- Preparation: pure start/parsed-step/source-step/finish with both environment and
  ordered declaration accumulator. Session caches retain a valid exact-source prefix
  within one compiler import.
- Qualification: pinned historical seed; isolated TypeScript5.8.3 installation;
  branch-scoped cloud workflow; raw .lean/.ps capability examples; candidate execution;
  explicit C2/C3 canonical source/admission/TS/JS equality.
- Native integration coordination: observed branch psc0/native-core-selfhost-v1 at
  963030dc2d154008fccc82e7c8ed29331f138799. Named native workflow run37825822957,
  job113478295740 completed its actual full checked compiler fixedpoint successfully.
  Source hash ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7;
  TypeScript hash fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033.
  This is evidence for the historical native baseline, not acceptance of our new worker
  admissions. New admissions will be checked through a separate pinned provider checkout.

### Design clarification

Canonical surface source is the output of the existing syntax translator. Lowered
worker/core structure is represented by canonical admissions. The minimum checkpoint
does not add a second elaboration-aware source printer. Generated compilers must
consume raw authored forms, so the new lowering path is exercised directly.

### Initial implementation checkpoint (historical)

The first coherent implementation checkpoint contains portable recursion lowering,
preparation/session reuse, raw capability fixtures, C2/C3 qualification, diagnostic IR
inventory and a separate pinned native-provider acceptance job. Its commit requests
[sh1-qualify]; compiler and provider outcomes are pending cloud execution. After earned capability
qualification, migrate a bounded Foundation.List family using a pinned qualified seed.
The independent host IR report is diagnostic evidence; full strict runtime typing and
PSC0-SH/1 strict profile activation remain separate obligations.

### Review decisions before first execution

The child-provenance boundary also requires alpha-equality of the nested expected
result telescope and the whole worker result. This prevents a narrower induction
hypothesis from disguising missing state application. Fixtures include the rejection
and preservation of valid outer hypotheses. Session results are deeply immutable;
parsed cache limits are entry/source-text limits, not a hard compiler-heap bound.

### Setup checkpoint after first cloud attempt

Commit e67647ec4821d609188e6feb5a4de2380857767e started run37831018572.
Job113496067989 stopped in Lean Action configuration because the historical branch
had no lake-manifest.json; no semantic tests or compiler generation ran. Add the
correct dependency-free manifest and explicitly register Ps.Elab.Recursion in Lake.
Preserve the historical changed-argument refusal test by selecting BatchStable; the
enhanced path is covered by the generated raw-source capability corpus. Rerun the
same coherent qualification after these integration corrections.

### Native build checkpoint

Run37831457914 at e52c30313b1e9124864a304a41f3b4b4c8f74bd0 recovered and
cached S0 successfully (JavaScript SHA25674dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76).
The new recursion module, context and term changes compiled natively. The wrapper
used two Lean4.34 reserved words as local names (`meta` and `public`); rename them
to metaContext and publicDeclaration together. No semantic acceptance rule changed.
Candidate and full qualification remain pending; reuse the cached seed/build outputs.

### Development gate validation checkpoint

Run37831951758 at e91b9558d665879871b8bf0893915ae64b27c7fe has passed native
compilation and the generated C1 candidate, including raw capability and session
conformance. Current-source C2/C3 and subsequent provider decisions remain pending.
The implementation branch is held at that immutable revision while qualification runs.

A separate psc0/sh1-development-gate-v1 checkpoint adds host-only iteration/recovery
tooling for one bounded native-candidate validation. Portable compiler source remains
identical to e91b9558. No active selfhost-seed.json or Foundation source migration is
included. The temporary workflow branch filter and ref-scoped concurrency preserve
the running full qualification.

Ordinary pushes build the current native PSC frontend and use it to emit N1, then
execute raw capabilities, preparation sessions and a two-module resident CLI smoke.
This evidence is native-seeded development execution, not selected-seed ancestry or
a self-host fixed point. Full qualification retains selected-seed C1/C2/C3 and the
independent provider job. The frozen diagnostic ownership case shares the existing
session conformance boundary. Historical recovery verifies complete provenance and
all four seed products; a malformed cache reconstructs rather than becoming selected.

Once A is qualified, pin its actual source/toolchain/product identities, restore the
implementation workflow branch filter, and apply the staged Foundation.List migration
with its bounded behavior/public-type correspondence gate. Preserve A's historical
source recovery path before allowing B to use the new authoring capability.

### Bounded development result

Commit9641928bcf7d5394f46e19a31a8ae3fd096d44b5 passed run37834854232 on its
first execution. Job113509175107 took74seconds including a15second incremental
native build. The native-candidate receipt reports14590.443683milliseconds for
N1 generation and bounded capability/session/CLI checks. The raw closure has56
modules and SHA2567e18013c260de84b08d57e923aef184993b0c5fea4de4775a68288a8ff9e157a.
N1 JavaScript SHA2569d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096.
These are single cached Linux x64 development measurements, not a fixed-point or
provider claim. The Foundation behavior matrix correctly skipped unchanged source.
See docs/selfhost-language/qualification-evidence.json for this durable checkpoint.

The next migration checkpoint is staged with additive dev:sh1/iterate:sh1 commands,
the same verified-seed Foundation comparison moved ahead of expensive C1 generation,
and a focused update of check-modular-preparation-source.mjs. That legacy guard
still assumed the old worker spelling and accidentally scanned two structures after
the new state type was added. Its replacement preserves prepared declarations-only
ownership and all unchanged admission/provider-session boundaries; generated session
correspondence already supplies the semantic evidence. Run it in B's early source
checks. Portable compiler source and selected seed remain at A until full evidence.
