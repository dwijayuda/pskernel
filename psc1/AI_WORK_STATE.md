# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Draft PR[202](https://github.com/dwijayuda/pskernel/pull/202). Active follow-up branch
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
The CI-only profile harness adds V8 statistical tick sampling at 5,000 microseconds while
retaining the private runtime, unchanged worker implementation, exact-file
permission restrictions, 4,096 MiB old-space setting and 3,600-second limit.
It first performs a small permission/profile compatibility probe, then compiles
all 125 modules, requires exact candidate/JS/admission/IR correspondence with B2,
and invokes the genuine independent checker freshly. Profiling artifacts are
observations, not selectable compiler generations.

The first Inspector CPU-profile preflight in run40630905618 failed because no
profile was produced, although the unchanged worker exited successfully. Pinned
Node22.23.3 source disables Inspector under permission mode. The correction uses
V8's tick logger with the same worker restrictions, and records native symbol
analysis tools (nm/objdump) as CI observation-only dependencies. No ordinary
runner or compiler acceptance policy is changed.

Profile40631714254 now passes exact complete candidate/IR/admission equality and fresh official checker admission. Worker1,236,092ms; maxRSS3,615,680KiB; checker2,029ms;243,356ticks. Sampled GC19.617%; nearest generated attribution to psIrSpecializeTypeKeyWithFuel18.721%; WeakCollectionSet top-frame12.579%. The selected first experiment defers the remaining-fuel closure until a type is supplied, preserving the fuel64 and all result/refusal cases. No cache, serialization or admission change is selected. Latency improvement remains unqualified until the new compiler and controlled old-source comparison pass.
Generated JS uses a generator trampoline, so weighted sampled self-time and
generated declaration locations are the initial views; JavaScript stack ancestry
is not the logical ProofScript call stack. Existing UTF-8 caches and balanced
text builders must not be duplicated based on speculation.

## Canonical ownership and environment progress

The intended canonical ownership inventory is151 portable compiler-package modules plus13 ordinary standard-library modules. All164 pass the actual parser. Native source-port equivalence40639393086 passes13 exact stdout/stderr/status comparisons,4 fresh independent admissions,9 definitional native API/default assertions, the lossless suite,28 modular and29 extended modular qualification cases. See docs/PSC1_NATIVE_PORT_QUALIFICATION_2026-10-28.json.

The fresh all151 repository graph reaches serialization but the ordinary32MiB helper cap refuses34,431,244 admission bytes (originalIR10,029,216 bytes), observed in40639435725. A separately named canonical-repository-40m profile is now limited to out-of-band graph files for the synthetic repository index. Ordinary five-argument helper invocations, requests, response/index/stdout, source/module limits, process limits and genuine kernel checks remain unchanged. The preparation verifies the ordinary32MiB refusal before using the40MiB audit profile. See docs/PSC1_CANONICAL_GRAPH_CAPACITY_2026-10-28.json.

No source owner is promoted until paired fresh admission/IR correspondence passes. Existing125 qualified ProofScript bytes and authored stdlib IO.ps must remain exact at initial promotion. Native Python/PHP optional-argument wrappers remain explicitly classified compatibility adapters pointing to their portable canonical implementations. The initial promotion prepares Git objects only; root reviews and integrates onto the latest branch without ref races. A separate staged refresh workflow permits authored PS edits, requires fresh checked references and native compatibility, and preserves untouched reference bytes. Ordinary source reads remain Git-free. Repository-wide SOURCE_OWNERSHIP.json and the fail-closed tracked.ps inventory are staged for activation with the canonical manifest.

The four-build measured type-key optimization qualification40634776830 remains in progress. It requires oldseed→O1→O2 byte-identical fixed point, followed by oldB2 and O2 compiling the identical old125-source workload on one runner. Every build independently admits and strictly checks original/transformed IR. Do not select O2 or claim an improvement before this run passes.

Broader regressions will modify real frontend and compiler behavior in an
isolated source workspace, execute positive and negative observations, and require
the changed compiler to rebuild itself. Additional Linux environments under
investigation are Ubuntu 22.04 x64 and Ubuntu 24.04 ARM64, using qualified native
Lean 4.35 checker payloads and matching private runtimes. ABI probes now pass on all three environments in40633426535: exact Node22.23.3, genuine Lean4.35 checker health and eight system libraries per environment. Full compiler and publication qualification remains pending actual execution. See docs/PSC1_ADDITIONAL_PLATFORM_ABI_QUALIFICATION_2026-10-28.json.

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
