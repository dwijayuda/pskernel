# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Active follow-up branch
`feat/psc1-canonical-latency-20261028`, from qualified PR #201 final head
`29c82adc77cbd1bf271acab75b6f8d51ef0a9ee6`.
GitHub-connected tools and GitHub Actions/Linux CI only. Non-force expected-head,
single-parent commits; no merge or registry publication.
[Previous work state](docs/history/AI_WORK_STATE_BEFORE_CANONICAL_LATENCY_2026-10-28.md)
preserves the independent-development milestone.

## Authorized next work

The user requests measured compiler rebuild-latency improvement, repository-wide
canonical `.ps` ownership, broader real changed-compiler regression coverage,
and additional installation environments/platforms. Fresh official kernel
admission and strict original/transformed IR checks must remain.

The first measurement reuses exact qualified sources and the current B2 compiler
from run [40618697529](https://github.com/dwijayuda/pskernel/actions/runs/40618697529).
The CI-only profile harness adds Node CPU sampling at 5,000 microseconds while
retaining the private runtime, unchanged worker implementation, exact-file
permission restrictions, 4,096 MiB old-space setting and 3,600-second limit.
It first performs a small permission/profile compatibility probe, then compiles
all 125 modules, requires exact candidate/JS/admission/IR correspondence with B2,
and invokes the genuine independent checker freshly. Profiling artifacts are
observations, not selectable compiler generations.

No optimization or latency reduction is claimed before that profile passes.
Generated JS uses a generator trampoline, so weighted sampled self-time and
generated declaration locations are the initial views; JavaScript stack ancestry
is not the logical ProofScript call stack. Existing UTF-8 caches and balanced
text builders must not be duplicated based on speculation.

## Parallel implementation investigations

The ownership audit enumerates every non-kernel package source. The 125-module
unified compiler is already representable in checked `.ps`; additional portable
modules and explicit native/bootstrap-only exceptions are being classified.
Canonical source promotion must retain one authored owner, explicit immutable
bootstrap references and fresh paired admission/IR correspondence. Reverse
conversion already exists, but official Lean compatibility of generated
projections needs an actual CI probe before replacing native bootstrap material.

Broader regressions will modify real frontend and compiler behavior in an
isolated source workspace, execute positive and negative observations, and require
the changed compiler to rebuild itself. Additional Linux environments under
investigation are Ubuntu 22.04 x64 and Ubuntu 24.04 ARM64, using qualified native
Lean 4.35 checker payloads and matching private runtimes. Platform/library and
publication claims remain pending actual execution.

## Inherited qualified baseline

Implementation `5484a04df34de1bbcfa46a248b6a93ce510035d6` passes dedicated
40618697529 and broader source gate40618701864 (16 selected jobs, 37 finite
Practical Core criteria). Documentation-only29c82adc passes40627266058 and has
exactly the tested tree. Full baseline B1/B2 and changed C1/C2 fixed points pass,
with actual changed wire diagnostic in both changed generations.

The complete editable unified source contains125 modules /2,382,708 UTF-8 bytes,
closure `9d0f097e79eb2b1e14d10362c6db9b4bc2370c26627658017bf6b2681b46fabf`.
B1/B2 emitted compiler SHA-256 is
`858c188024f0a7da221e0c26053437b3fac3fc0ab1cc9d14092df19b39d1465d`.
Measured workers took1,435,076–2,040,425 ms and about3.32–3.50 GiB RSS; independent
checking took about3 seconds. These are correctness observations, not a controlled
performance benchmark. The original240-second full-compiler target is unqualified.

## Preserved boundaries

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, independent admission,
ordinary logical/body pairing, explicit assumptions, strict original/transformed
IR, semantic fuel and established acceptance policies remain. Kernel internals,
PSKernel-Core and MinKernel are separate. Private runtime/checker components
remain explicit; no runtime-free or formal compiler-preservation claim.

See the [independent-development receipt](docs/PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
for exact baseline artifacts, measurements, dependency limits and failure history.
