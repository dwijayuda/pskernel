# Decisions and unresolved design obligations

Established 2026-09-27 from current source, repository plans and user direction.
These decisions govern this workspace; donor branches retain their own history.

## Resolved for planning

| ID | Decision | Reason/source |
| --- | --- | --- |
| D01 | `psc2selfhost/` is the implementation home | Explicit current user direction; keep existing modular code |
| D02 | PSC1 stays frozen; PSC2 adds productivity above it | PSC2 reference and user decisions |
| D03 | Use G0/G1/G2/G3 for generations | Avoid older PSC2-generation vs PSC2-language ambiguity |
| D04 | Lean-first source, generated `.ps`, explicit authority transition | Existing bootstrap plans and repeated user constraints |
| D05 | Official Lean is the initial build anchor | Do not wait for legacy TS frontend feature completion; still require owned source/admission closure |
| D06 | Prefer an adapter to the embedded kernel; retain TS oracle | Staged migration over a flag-day rewrite; adapter/profile must be implemented and tested |
| D07 | JS fixed point first; distinguish full kernel closure | Keeps measurable milestones without weakening the final compiler+kernel target |
| D08 | Preserve TS/Rust/Wasm and target-neutral IR | Existing code and explicit multi-backend contract |
| D09 | Preserve current package/host/stdlib layout during closure | Avoid unnecessary import/root churn; no monolithic compiler rewrite |
| D10 | Record compiler, language, kernel, target and assurance claims independently | Prevent inherited branch prose from certifying this workspace |
| D11 | No `.bak` bridge as an implicit production fallback | Missing provider is an explicit failure; choose/wire an adapter deliberately |
| D12 | Draft open semantics remain open until resolved for their profile | Documentation breadth is not implementation readiness |

## Conflicting historical statements

- Older plans call a generated second compiler “PSC2”; current language documents
  also call the richer language “PSC2”. D03 resolves terminology locally.
- Older master plans assume the TS kernel permanently; newer user decisions
  target a Lean-authored/generated kernel. D06 preserves TS independence while
  allowing staged production migration.
- Some older bootstrap prose mentions sibling `.lean`/`.ps` files, while its
  explicit source-transition rule forbids manual mirroring. D04 makes generated
  ownership unambiguous.
- Older backend plans defer integration until JS closure, but this directory
  already imports Rust and includes Wasm. D08 preserves landed implementation;
  it does not invent completed native/Wasm self-host gates.
- Old memories claimed native reduction was removed from final Lean 4.34.
  `docs/CONFORMANCE.md` distinguishes the pinned tag's optional native path from
  a later removal commit. Use the exact pinned source and explicitly disclose
  native-evaluator trust; do not derive semantics from an old summary.
- Kernel README/K8 statements are bounded historical evidence. They do not
  certify compiler integration, generated-kernel execution, full environments
  or formal equivalence at this workspace revision.

## Open decisions and their closure criteria

Do not silently pick a backend-specific answer. Each row needs a written
semantic decision plus positive/negative tests before claiming its capability.

| ID | Obligation | Owner/when | Closure evidence |
| --- | --- | --- | --- |
| O01 | Concrete provider request/result types and checked artifact construction | bridge/kernel, M1 | Codec/version/transaction/forgery tests and real compiler admission |
| O02 | Complete kernel implementation profile and source adaptation scope | kernel/compiler, M0-M4 | All 40 current kernel/test modules classified; runtime closure distinguished from tests |
| O03 | Canonical admitted-Core and IR serialization | core/bridge/compiler-ir, before M3 | Versioned algorithm; semantic-field sensitivity and permitted normalization tests |
| O04 | Native `.ps` re-export syntax | syntax/project, F1 | Resolution/visibility/round-trip cases |
| O05 | Final contract proof-section spelling | syntax/verification, F9 | Both supported frontends produce the same checked specification |
| O06 | Task cancellation/failure/scheduling and async contracts | stdlib/platform, F11 | Observable cross-target model including cancellation/failure |
| O07 | Registry set and controlled notation grammar/scopes | extensions, F8 | Deterministic imports, conflicts, expansion and proof checking |
| O08 | Output-parameter/coercion compatibility subset | meta, F6 | Search rollback, cycle/depth/ambiguity and Lean differential cases |
| O09 | Quot/extensionality and opacity across providers | kernel/prover, F6-F8 | Explicit profile matrix and acceptance/rejection cases |
| O10 | Well-founded recursion source/proof behavior | elab, F4 | Generated termination theorem, failed measure and dual-source cases |
| O11 | Plugin capability/version/permission model | extensions, F11 | Deterministic replay, incompatible version and unauthorized capability failures |
| O12 | Reachable noncomputable executable declarations | elab/erasure, F6 | Executable rejection; theorem-only acceptance under explicit assumptions |
| O13 | Exact advertised Lean compatibility level | release owner, M5 | Named source/library corpus, version and unsupported cases |
| O14 | Release resource budgets and supported host profiles | release owner, M3/M6 | Measured compiler closure on declared host/toolchain, reproducible limits |

The source language's full open list remains in PSC2 reference section 108.
This table adds implementation obligations and does not replace that list.
