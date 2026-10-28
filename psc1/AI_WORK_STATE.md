# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Draft [PR #202](https://github.com/dwijayuda/pskernel/pull/202) is stacked on qualified PR #201, base `29c82adc77cbd1bf271acab75b6f8d51ef0a9ee6`.
The active branch is `feat/psc1-canonical-latency-20261028`.
Use GitHub-connected tools and GitHub Actions/Linux CI only, with non-force
expected-head single-parent commits. No merge or registry publication.
[Previous state](docs/history/AI_WORK_STATE_BEFORE_CANONICAL_LATENCY_2026-10-28.md)
retains the preceding independent-development milestone.

## Requested outcome

Improve rebuild latency from measured compiler execution, establish repository-wide
canonical editable `.ps` ownership, broaden real frontend/compiler changes through
source → new compiler → self-rebuild, and qualify additional installation environments.
Preserve fresh official kernel admission and strict original/transformed IR checks.

## Measured optimization passed

[Profile 40631714254](https://github.com/dwijayuda/pskernel/actions/runs/40631714254)
used the immutable 125-module workload and unchanged restricted worker. It reproduced
the complete qualified candidate bytes and passed fresh independent checking.
The worker took 1,236,092 ms with 3,615,680 KiB peak RSS. Of 243,356 V8 ticks,
19.617% were GC samples and 18.721% had nearest generated attribution to
`psIrSpecializeTypeKeyWithFuel`. These are sampled shares, not wall-clock phases
or logical ProofScript stack attribution. See
[the profile receipt](docs/PSC1_REBUILD_PROFILE_2026-10-28.json).

[Qualification 40634776830](https://github.com/dwijayuda/pskernel/actions/runs/40634776830)
passed all four builds: old seed → O1 → O2, then old B2 and O2 each compiling the
identical immutable original workload. O1/O2 matched all six semantic payloads.
Both comparison builds reproduced the complete old B2 output bytes. Every build
freshly admitted and strictly checked original/transformed IR.

The matched worker times were 1,710,047 ms and 1,485,908 ms: 224,139 ms saved
(**13.107%**). Peak RSS fell from 3,619,020 to 3,435,212 KiB.
This is one sequential matched pair on one hosted runner; the 240-second target
remains unmet. The change defers the remaining-fuel recursive closure until a type
is supplied, preserving fuel, key construction, branches and refusal conditions.
No incremental-compilation, semantic cache or serialization change was selected.

[The exact qualification receipt](docs/PSC1_TYPE_KEY_LATENCY_QUALIFICATION_2026-10-28.json)
pins artifact 12796523762 and the selected `O2/` directory. O2 compiler SHA256 is
`49d851d26008abf116b9f4c680c0833311e835b90d6c58e369ca426f33ecd2e6`.
Its 125-module source closure is
`424c15ce2cf5bb87a293dd2aad1705fa801c07067c972578aa76111627d590d7`.
The separate `optimized-baseline/` output intentionally recreates old B2 and is
not the replacement seed. Selection must verify all retained O2 files and exact
current canonical source bytes before assembling a new distribution.

## Canonical sources promoted

[Preparation 40644035690](https://github.com/dwijayuda/pskernel/actions/runs/40644035690)
passed actual parsing and fresh compiler/library admission and strict-IR correspondence.
It prepared 164 editable owners: 151 compiler-package modules and 13 standard-library
modules. The initial promotion preserves the exact original 125 qualified PS sources
and authored `stdlib/ProofScript/System/IO.ps`. All existing native reference bytes
are retained. The whole reverse-rendered native build failed; that projection is
explicitly not promoted.

`CANONICAL_SOURCES.json` is the PSC1 ownership authority. The immutable initial
manifest is pinned by `bootstrap/CANONICAL_BASELINE.json`. Root
`SOURCE_OWNERSHIP.json` classifies every tracked `.ps` file without changing
independent project or kernel authority. Package defaults read canonical PS;
paired Lean files are explicitly checked bootstrap references. Generated standard-library
package views copy their single canonical source. Ordinary source reads remain Git-free.

The ordinary 32 MiB graph-file profile refused the measured 34,431,244-byte all-compiler
admission graph. The explicitly selected `canonical-repository-40m` profile changes
only graph-file capacity for the synthetic repository index. Requests, response/index
stdout, ordinary calls, source/module/process limits and checking remain unchanged.
Preparation requires the ordinary refusal before using this audit profile. See
[capacity evidence](docs/PSC1_CANONICAL_GRAPH_CAPACITY_2026-10-28.json).

[Native port equivalence 40639393086](https://github.com/dwijayuda/pskernel/actions/runs/40639393086)
passed 13 exact output/status comparisons, four fresh independent admissions, nine native
API/default equalities, lossless tests, 28 modular and 29 extended cases. Python/PHP
optional-argument wrappers remain explicitly classified native adapters pointing to
portable canonical implementations.

## Active integration and remaining qualification

The exact passed type-key source edit is committed as canonical `Specialize.ps`
at `0575b1a39a09c4253fd5691eec9fbc270fac6f5b`. The checked reference refresh is running
in [40646380001](https://github.com/dwijayuda/pskernel/actions/runs/40646380001)
against initial manifest commit `109e404586504cfe5f20352d1804d0cf0ac83310`. That workflow
freshly checks both grammars, preserves untouched references, natively builds changed
references and repeats correspondence with rebuilt helpers before preparing Git objects.
The host-only native projection adapter uses parser-owned constructor-pattern spans
and independently verified literal-dot insertions. It grants no admission authority.

The O2 bootstrap, broader frontend/compiler/protocol regression chain, environment
verifiers and reusable environment workflow are committed for review. The matrix
trigger remains staged until the checked source/reference refresh is integrated. The intended
matrix is Ubuntu 24.04 x64, Ubuntu 22.04 x64 and Ubuntu 24.04 ARM64. ABI probes already
passed in [40633426535](https://github.com/dwijayuda/pskernel/actions/runs/40633426535),
with exact private Node 22.23.3, official Lean 4.35 checker and eight linked system
libraries per environment. Full compiler/self-rebuild/publication qualification
remains pending actual execution. Retain exact runtime, OS, filesystem, linked-library,
archive and publication evidence for each environment.

## Preserved boundaries

Official Lean 4.35.0 / `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`,
independent admission, ordinary logical/body pairing, explicit assumptions, strict
original/transformed IR, semantic fuel and established acceptance policies remain.
Kernel internals, PSKernel-Core and MinKernel are separate. Private runtime/checker
components remain explicit; no runtime-free or formal compiler-preservation claim.
A source manifest, artifact or retained receipt never replaces fresh admission.
