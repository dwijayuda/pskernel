# PSKernel-C0 Core-first qualification contract (2026-10-19)

Status: **UNQUALIFIED / execution plan**, not a declaration that C0-Core is done.

## Purpose
Deliver the smallest **independently checked kernel closure actually required** by PSC0 Core Standard / Stage1–Stage3 self-host, while preserving the separately qualified Lean 4.35 full-checker research. Do not use an arbitrary handpicked mini-language or 76-declaration Bootstrap seed as evidence that a real compiler is covered.

## Source of truth and baseline
- Production base: `perf/pskernel-c0-v7-rust-20261012` at `41322875539de66acf9eb9b01ddf73df82a61bf2`.
- Target pinned Lean: official 4.35.0, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- PSC0 Core-first evidence currently lives in [PR #151](https://github.com/dwijayuda/pskernel/pull/151); this is a separate compiler-engine/environment project, not proof that PSKernel-C0 can self-host.
- Existing native C0 qualification: [CI 39013322401](https://github.com/dwijayuda/pskernel/actions/runs/39013322401) matched 177/193 adapted historical Arena bodies, zero observed incorrect verdicts on the comparable subset, 16 unqualified due to resource/reference limits.
- Real performance candidate: [PR #140](https://github.com/dwijayuda/pskernel/pull/140) one paired genuine Array run: 518.28s → 449.95s, unchanged fuel. Not a general speed guarantee or automatic production promotion.
- Rejected candidates [#141](https://github.com/dwijayuda/pskernel/pull/141) and [#143](https://github.com/dwijayuda/pskernel/pull/143) increased RSS about 9.8× and 14.4× on authentic app-lam, still timed out.
- Isolated [PR #150](https://github.com/dwijayuda/pskernel/pull/150) immutable computed MVar flag is not approved without native runtime and same-export A/B qualification.

## Exit gates (ALL mandatory)
1. **Real dependency manifest.** Generate a reproducible, exact-hash list of every proof-relevant declaration, inductive family, universe level, reduction primitive, assumption and dependency used by the *real* PSC0 Core compiler and its bootstrap sources (not only the independent Bootstrap seed). Record the precise PSC0 commit, compiler source closure, export and Lean pin. Resolve actual compiler modules that remain Full-bound before claiming Core closure.
2. **Trusted admission.** Replay that closure into an initially empty C0 environment in dependency order; verify declarations including inductives/recursors/quotient/native rules with the same Lean-approved assumption policy. Any unsupported/resource/timeout/missing dependency is *not accepted*. No unchecked constants or proof placeholders.
3. **Independent oracle.** Independently run the exact same immutable corpus through official pinned Lean 4.35 and require matching accept/reject results, checksums, and explanatory failure categorization. Keep negative/adversarial tests and the full historical Arena suite running as regression gates; do not change fuel to manufacture passes.
4. **Stage checkpoints.** Bootstrap stage0 reproducible source/compiled output; Stage1 compiles the complete actual Core compiler; Stage2 recompiles Stage1; Stage3 reproduces Stage2 byte-for-byte or with a precisely specified verified normalization. Explicitly record kernel, compiler, runtime and backend differences. No backend execution certification follows from a kernel verdict alone.
5. **Performance and memory.** Benchmark full checking of the actual compiler/Core closure on GitHub Linux, with source SHA and exact runner budget, peak RSS, wall time, and comparable official/previous C0 baseline. Confirm no unacceptable regression for real shared DAG cases. Microbenchmarks and helper-only measurements cannot close the gate.
6. **Release/integration.** Only after gates 1–5 pass, wire a non-default optional C0 Core provider into PSC0 and separately prove that the promoted provider runs the same checked replay. No automatic replacement of official Lean, no npm release, no Full Lean-compatibility claim.

## Fastest engineering sequence
- A: extract actual Stage0/Stage1 compiler dependency graph from PSC0 Core-first work; freeze hashes and identify the minimal *closed* kernel subset. If closure is Full, explicitly report it rather than silently dropping declarations.
- B: build/qualify a strict C0 replay command and CI job using this closed corpus, beginning with the smallest authentic Core module set and expanding until Stage1 is complete. A command must fail when any declaration cannot be checked.
- C: remove recurring tree traversals with immutable source-correct term metadata and measure actual app-lam/shared-subterm; do not merge #150 solely because the Lean source theorem compiles. Favor O(1) immutable flags plus sharing-preserving WHNF/DefEq; prove source equivalence and measure full checked workloads at unchanged fuel.
- D: qualify Stage1→Stage2→Stage3 and preserve independent official oracle and per-stage resource accounting.
- E: separately continue 193/193 Arena and Init/Std/Mathlib Full Lean research. These are **not** silently treated as complete when Core qualifies.

## Stop / rollback conditions
- Any discrepancy with official Lean on a supported case; any new wrong verdict; accepting from timeout, omitted declaration or unsupported metadata; changed soundness assumptions; cache/pointer/hash result authorizing a proof judgment; budget/fuel increase disguised as optimization; memory regression that destroys full-checker viability.
- Any proposed shortcut to define Core by what C0 already passes instead of the actual PSC0 compiler closure.
- Any unmeasured self-host or library completion claim.

## Evidence ledger
| Gate | State | Evidence or blocker |
| --- | --- | --- |
| Actual PSC0 Core dependency closure | OPEN | PR #151 Bootstrap has 76 declarations; not the whole compiler; isolated engine excludes Full project loader |
| Empty C0 replay of actual Core closure | OPEN | Not established by 177/193 Arena |
| Independent exact-corpus official Lean agreement | OPEN | Only bounded external and Arena suites qualified |
| Stage1/2/3 self-host | OPEN | PSC0 Core compiler itself not yet self-host-qualified |
| Genuine Core full-checker latency/RSS | OPEN | Genuine Array/selected Arena evidence exists, not actual Core closure |
| Optional integrated C0 provider | OPEN | Do not change current trusted default |

## Follow-up implementation discipline
Keep this branch separate from PR #150 and the active production C0 branch until a genuine exact-input kernel performance and correctness gate passes. Commit single coherent fixes, run GitHub Linux native tests and exact-source oracle comparisons. Update this ledger with immutable commit SHAs and GitHub Action run IDs. Reject speculative estimates of percent complete.
