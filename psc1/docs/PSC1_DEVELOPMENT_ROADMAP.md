# PSC1 development roadmap

Updated 2026-10-23. Release authority:
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](PSC1_PRACTICAL_CORE_V1_CONTRACT.json)
(14 frozen families, 37 finite criteria, both grammars, seven targets, four
application categories). Preserve working features and existing correctness
boundaries. [AI_WORK_STATE.md](../AI_WORK_STATE.md) owns the current continuation
checkpoint; [the receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json)
owns exact evidence.

## Qualified finite release baseline

Branch HEAD `ea10eff9b3de063941c6029bb6c821f9cc10cc3f`, tested merge
`4e5f4d2c8c90178aa7cf301717004cfc6182596f`, passes Linux
[39880807914](https://github.com/dwijayuda/pskernel/actions/runs/39880807914).
All selected gates, all 47 full-job steps and 37/37 finite release criteria pass.
This includes all seven mappings, both source grammars, typed IO, ordering,
collections/control, real CLI/JSON/file/library/compiler-like workloads,
negative/ABI refusals, official Lean admission, strict IR and package installation.
The native npm artifact is qualified for its scoped platform and unpublished.
This is not unrestricted language or formal backend correctness qualification.

## Dependency-ordered active queue

| Order | Work item | Current evidence | Acceptance before completion |
| --- | --- | --- | --- |
| 1 | Rust full compiler request throughput | G1 frozen ten cases qualified; G2 timeout; exact stack shows request String cloning | General ownership correction passes retained-old/current guards, full corpus, actual G2 request at unchanged limits |
| 2 | TypeScript full compiler execution throughput | Checked result annotations resolve strict tsc stall; actual G1 ten cases pass in 39887064597; G2 still times out | Profile actual generated G2 execution and fix measured bottlenecks at unchanged limits; retain strict/noEmitOnError |
| 3 | Independent Rust G1 → G2 → G3 | Manual pipeline implemented; only G1 qualified | Independently admit and execute every generation; all ten frozen cases; exact closure/source/admission/original-IR/transformed-IR fixed point |
| 4 | Independent TypeScript G1 → G2 → G3 | G1 ten cases pass on annotated source; G2 timeout | Same independent generation/fixed-point acceptance; no native compiler fallback |
| 5 | Promote measured backend fixes | Rust ownership prototype isolated on its own branch | Review actual workload evidence, preserve compatibility/refusals, fresh full normal seven-backend CI on integrated source |
| 6 | Reproducible readable distribution and performance comparison | Exact tools/Cargo lock, process bounds, hash-bound artifacts implemented | Record generated compiler build/runtime/RSS/source sizes for both targets and real applications; solve large-source formatting without semantic changes; no npm publish without authorization |

Rust and TypeScript reuse `Ps.Compiler.Service`, existing frontend/elaborator,
strict checked IR and verification. Target facades call existing production
backends; no handwritten target compiler or duplicated language semantics.
Rust prioritizes native performance; TypeScript prioritizes readable portable
npm-compatible output. Source normalization must serve both grammars.

## Current engineering mechanism

Rust prototype `fix/psc1-rust-owned-string-moves-20261023` tests borrowed
forwarding wrappers, owned rvalue moves and invariant String loop movement
after all changing arguments are evaluated. Source-layout and dependency
errors were corrected. Old/current native guards and runtime comparisons
pass, then the frozen generated handler exposed missing struct grouping;
that correction passes G1 in 39886083977. Actual G2 then aborts with stack
overflow at 103782 ms; exact replay diagnosis remains in String cloning, so the
crash's origin is not yet established. Keep the candidate isolated. No prototype qualification or
integration is assumed until terminal evidence.

TypeScript actual native checker diagnosis 39886224622 finds repeated contextual
return/yield/conditional inference. Checked-IR result annotations now pass strict
checking and all ten G1 cases in 39887064597; G2 execution times out. The source
is promoted for fresh normal seven-backend CI; do not inherit normal qualification
from the previous source. Profile actual generated execution next.
Do not use `noCheck`, disable strictness, inject `any`, enlarge limits or skip
admission to obtain a pass. Preserve explicit unsupported public ABI refusals.
A conservative unreachable-function estimate is diagnostic only; no reachability
or constant-outlining rewrite has been implemented or justified by that estimate.

## Independent development and deferred scope

Practical Core language/compiler/backend maintenance and PSKernel-Core
Expression V2 research remain independent. The official Lean 4.35.0 checker
remains authoritative; incomplete owned-kernel research does not gate compiler
development. New optional language families remain deferred beyond the finite
v1 contract, preserving already working behavior.

The user has now resumed manual self-host qualification after v1 freeze.
Expensive G2/G3 remain separate manual/release jobs and never block normal
development. DirectJS G1 remains a regression/reference. Its diagnosed G2
JavaScript heap defect and prior evidence remain tracked; DirectJS-specific G2
optimization is not the priority. Do not confuse a reference pass with Rust/TS
fixed-point qualification.

Tiered static/focused/integration/full Linux CI, dependency-aware selection,
source/tool/lock caching and concurrency controls remain. Avoid duplicate full
runs without changed source or a concrete unresolved concern. Keep exact
evidence and a small remaining-work queue current; archive narrative history
instead of repeating audits and plans.

No force pushes, history rewriting, merges or registry publication. Fetch
latest remote HEAD and preserve concurrent changes. Official independent
checking, strict original/transformed IR, semantics, resource policies,
negative tests and final release qualification are non-negotiable.
