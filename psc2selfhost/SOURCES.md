# Source and branch evidence register

Review date: 2026-09-27 Asia/Jakarta. Integration baseline:
`dd2fa706b4a462ef34ecbce32510b8c61e47819b`.

## Coverage and limits

The review inventoried first-party Markdown across 210 fetched remote branch
refs: 160 distinct paths and 223 distinct path/blob versions. It read the
directly relevant language, architecture, self-host, assurance and branch
documents and inspected implementation paths and scripts. The
[inventory](DOC_INVENTORY.md) records the survey; it is not a claim that every
historical document or vendored study manual was read line by line.

Third-party study documentation is a reference corpus, not a competing project
roadmap. Its authority/use is defined by the
[study policy](../docs/STUDY_REFERENCE_POLICY.md). No live Lean build, complete
kernel corpus or cross-host generation was executed during this documentation
review. No inherited branch PASS is promoted to local PASS.

## Primary document map

| Source | What this package carries forward |
| --- | --- |
| [PSC2 reference](../PSC2%20Lang/PSC2_LANGUAGE_REFERENCE.md) | Planned language, profiles, trust boundaries, conformance, 13 freeze obligations |
| [PSC2 profile](../PSC2%20Lang/PSC2_LANGUAGE_PROFILE.md) | Feature families and lowering above the kernel |
| [PSC2 bootstrap model](../PSC2%20Lang/SELF_HOSTING_AND_EXTENSION_MODEL.md) | Implementation vs accepted profiles, anti-circularity, official Lean anchor |
| [Contracts](../PSC2%20Lang/CONTRACTS_AND_VERIFICATION.md) | Pure/effectful contracts, proof obligations, runtime/proof distinction |
| [Feature research](../PSC2%20Lang/FEATURE_RESEARCH_MATRIX.md) and [migration](../PSC2%20Lang/MIGRATION_GUIDE.md) | Programming/prover/verification priorities and adoption goals |
| [PSC1 reference](../PSC1%20Lang/PSC1_LANGUAGE_REFERENCE.md) and [status](../PSC1%20Lang/CONFORMANCE_PORTABILITY_AND_STATUS.md) | Inherited bootstrap semantics and support-vs-intent distinction |
| [Foundation plan](../docs/plans/07_SELF_HOSTING_FOUNDATION.md) | Source closure, compositional fixture, JS first, source transition, native follow-up |
| [Lean bootstrap](../docs/selfhost/PSC1_LEAN_BOOTSTRAP.md) | Lean-first portable compiler, host separation and package responsibilities |
| [Existing self-host workflow](../selfhost/SELFHOSTING.md) and [architecture map](../selfhost/ARCHITECTURE_MAP.md) | Multiple hosts, package roots, responsibility parity rather than literal porting |
| [Post-PSC1 platform](../docs/selfhost/POST_PSC1_PLATFORM.md) | Versioned contracts, Meta/plugins, InterfaceIR, Task/Resource and compiler-service API |
| [Master plan](../docs/plans/00_MASTER_PLAN.md), [architecture](../docs/PROOFSCRIPT_ARCHITECTURE.md), [anti-drift](../docs/ANTI_DRIFT.md) | One admitted semantic path; no parallel legacy checker |
| [Conformance](../docs/CONFORMANCE.md) and [assurance ladder](../docs/research/KERNEL_ASSURANCE_FALLBACK_LADDER.md) | Exact corpus claims, resource-aware diagnosis, native-policy/version precision |
| [Embedded kernel](packages/pskernel/README.md), [K8](packages/pskernel/K8_ACCEPTANCE.md), [maturity](packages/pskernel/MATURITY_PARITY.md) | Bounded kernel capabilities and explicit remaining qualification |
| [IR contract](packages/compiler-ir/CONTRACT.md) and [Wasm plan](../docs/selfhost/WASM3_BACKEND.md) | Target-neutral semantics and separate backend/host milestones |

The first-party inventory also covers package/tooling plans, handbooks and study
summaries. They inform later delivery and examples; they do not override the
critical path or certify source support.

## Inspected branch checkpoints

These SHAs are review snapshots, not claims that branches will stay unchanged.
Use immutable links when recovering them and recheck before integration.

| Branch | Commit | Lesson/candidate work |
| --- | --- | --- |
| `main` | `dd2fa706b4a462ef34ecbce32510b8c61e47819b` | Current PSC2 directory and latest post-PSC1 platform document |
| `PSC2-lang` | `4b7a1ce2f8aba0a8beb2fd67ab9a0b8640131150` | PSC2 language/source snapshot merged into main |
| `selfhost/psc1-lean-bootstrap` | `20c44dec16de2aacfaaba8447ad7c3c5ed4cc972` | More recent compiler/IR/backend integration; phase-separated documentation |
| `kernel/psc1-lean-reference` | `b9ee638cf76d3233b2484591610245f4239260ae` | Lean-authored checker and runtime-maturity work |
| `integration/psc1-lean-native-provider` | `ceca4d589f26e8bbb3d61bfed31ce78b42aea8cc` | Optional native-evaluation map/provider fixture; not by itself compiler-admission integration |
| `selfhost/kernel-lean-bootstrap` | `c999e1338b2baa057edb6fd2c3bdecba2e43418b` | Smaller PSC1-shaped kernel port; correctly distinguishes structural admission from checking |
| `backend/rust-native` | `847411079ad53da8cc64a49449ce3c9b66254d87` | Rust source/backend integration is distinct from native self-host completion |
| `backend/wasm3-owned` | `3f82e9a6841afed7412441ab1a7c79ba4dcfd5bf` | Owned Wasm target architecture and non-blocking host policy |
| `integrate/wasm3-array-runtime` | `131437c3e16b2819798d051b0765393eb034f4b5` | Persistent-array runtime integration candidate; inspect exact tree before reuse |
| `research/formal-soundness` | `624a6ddb025d1eba5525ac1cbb497bfee77bb07b` | Optional exact-stream verified co-signing, not checker equivalence |

Important branch-only documents:

- [Kernel bootstrap](https://github.com/dwijayuda/pskernel/blob/c999e1338b2baa057edb6fd2c3bdecba2e43418b/docs/selfhost/PSC1_KERNEL_BOOTSTRAP.md).
- [Rust/native plan](https://github.com/dwijayuda/pskernel/blob/847411079ad53da8cc64a49449ce3c9b66254d87/docs/plans/08_RUST_BACKEND_NATIVE.md).
- [Formal soundness scope](https://github.com/dwijayuda/pskernel/blob/624a6ddb025d1eba5525ac1cbb497bfee77bb07b/docs/research/FORMAL_SOUNDNESS_V1.md).
- [Native-map workflow](https://github.com/dwijayuda/pskernel/blob/ceca4d589f26e8bbb3d61bfed31ce78b42aea8cc/.github/workflows/psc1-lean-native-provider.yml).

## Chat decisions carried forward

Retrieved history confirms the user's intent to keep PSC1 small, make migration
from Lean/TS practical, support `.lean`/`.ps` parity and contracts, retain one
shared Core/IR across TS/Rust/Wasm, and use this directory for PSC2. Earlier
decisions preserve `.lean` authority until generated parity/fixed point, `tsc`,
modular workspaces and independent kernel assurance. Later kernel migration
decisions allow a Lean-authored production target while retaining TS as oracle.

Historical percentages, branch frontiers and “complete” statements were not
used as current evidence. Conflicting historical recommendations are resolved
explicitly in [DECISIONS.md](DECISIONS.md).

## Refresh procedure

Fetch branch refs; record exact heads; compare relevant source/document blobs;
read only changed authoritative or task-relevant material; rerun affected gates.
Update this register and STATUS independently: new source text may inform a
plan without demonstrating a gate. Preserve the original snapshot inventory
as historical provenance rather than silently editing its counts.
