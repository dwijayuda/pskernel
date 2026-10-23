# PSC1 self-host qualification profiles

The default `performance-240s` profile retains the existing 240000 ms hard deadline
for every G1/G2/G3 request, tool build and corpus execution. The existing 15-minute
performance workflows remain separate and unchanged.

The opt-in `correctness-1800s` profile changes only actual `G2-self` and `G3-self`
generated compiler requests to 1800000 ms each. G1 bootstrap, every generation's
ten positive/refusal corpus cases, independent admission and target tool builds
retain their existing limits. No semantic fuel, heap, stack, output, wire, strict
IR, negative-test or independent Lean 4.35.0 checking policy changes.

The explicit longer-profile workflow has a 120-minute job and a 110-minute
qualification step, leaving setup and evidence retention time. Each Python
process supervisor enforces its selected child deadline; the Node guard permits
only five additional seconds for supervisor cleanup. Nested Rust supervision
receives the same explicit request profile. Unknown profiles, unauthorized
standard deadlines above 240000, and long deadlines above 1800000 are refused
before child creation. Process-tree cleanup also covers nested sessions.

Run on Linux with the pinned tools and registered native proof/test roots:

```sh
node scripts/generated-target-qualification.mjs rust --self-host performance-240s
node scripts/generated-target-qualification.mjs ts --self-host performance-240s
node scripts/generated-target-qualification.mjs rust --self-host correctness-1800s
node scripts/generated-target-qualification.mjs ts --self-host correctness-1800s
```

The longer workflow uses an explicit request-only commit whose parent is exactly
the tested immutable source parent. Its request schema is
`psc1-rust-ts-selfhost-request/2`, profile `correctness-1800s`.
The unchanged performance request schema/default remains available.
Profiles use separate concurrency groups and artifact names.

A correctness pass still requires one native seed, removal of native compiler
executables, actual generated G1/G2/G3 compilation and execution, independent
official admission of each candidate, exact source closure/source/admission/
original and transformed IR fixed points, and identical ten-case observations.
A longer-profile pass never grants the separate 240-second performance badge.

Receipts pin compiler source inventory, request, producer, tools and tested
commit. Every generated request records elapsed wall time and failure before
assertion, including Linux wait4 child maxRSS and a sampled descendant RSS sum.
The latter can double-count shared pages and uses a 100 ms sampling target; it is
reported separately from successful service maxRSS. A failed or timed-out
request grants no candidate admission or fixed-point qualification.

Actual runs and their exact identities are recorded in AI_WORK_STATE.md,
the development roadmap and qualification receipts. Historical 240-second
failures remain evidence of unmet performance qualification.

Current results are in [the canonical qualification receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).
The initial PSC1_SELFHOST_PROFILES_2026-10-23.json is a historical profile-declaration
snapshot from before the attempts completed, not the current qualification status.
Rust correctness-1800s passes G1/G2/G3/fixed point in run39908529181; performance240s
remains failed. TypeScript shared-codec correctness1800s times out in G2 in
run39908439190. A later direct-predicate source is under test in run39913434540.
