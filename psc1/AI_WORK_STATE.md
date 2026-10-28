# PSC1 AI work state

Updated 2026-10-28 UTC. Active branch
`feat/psc1-independent-development-20261028`, based on qualified PR #198 HEAD
`ee9220e20e6b9fa202693c8226815a780cc5bbc0`.
GitHub-connected tools and Linux GitHub Actions only; single-parent expected-HEAD,
non-force history. Draft [PR #201](https://github.com/dwijayuda/pskernel/pull/201)
targets that umbrella branch. No merge or registry publication.
The previous state is preserved byte-for-byte in
[history](docs/history/AI_WORK_STATE_BEFORE_INDEPENDENT_DEVELOPMENT_2026-10-28.md).

## Qualified independent-development milestone

Implementation `5484a04df34de1bbcfa46a248b6a93ce510035d6` passes
[40618697529](https://github.com/dwijayuda/pskernel/actions/runs/40618697529):
bootstrap, isolated smoke, complete baseline B1/B2, real changed-source C1/C2,
and the same-run evidence gate. The
[dated receipt](docs/PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
records exact source inventories, generation identities, elapsed time, worker
RSS, independent-checker observations, process traces and delivery artifacts.

The package includes the qualified generated JS seed, private pinned Node/V8
22.23.3 runtime, genuine precompiled official Lean 4.35.0 native checker and a
complete editable 125-module `.ps` compiler project. PSC1 directly emits the next
compiler; no external emitted-source compiler is used. Both baseline generations
and both changed-source generations receive fresh independent admission.

The changed chain edits one literal in actual `Ps.CompilerUnified.Service`
ProofScript source. C1 and its self-rebuilt C2 both return
`request-arity:expected-three-fields` where the seed returns `request-arity`.
No generated JavaScript edit substitutes for the source change.
B1/B2 and C1/C2 each match exactly on `compiler.mjs`, `admissions.json`,
`original-ir.json`, `specialized-ir.json` and `sources.json`.
B1's canonical admissions also match the independently checked bootstrap
conversion. Its original IR bytes match the checked native bootstrap result as well.

| Generation | Compiler worker seconds | Worker maxRSS KiB | Worker maxRSS GiB | Independent checker seconds |
| --- | ---: | ---: | ---: | ---: |
| B1 (seed → baseline) | 1500.364 | 3,665,376 | 3.496 | 2.993 |
| B2 (B1 → baseline) | 1435.076 | 3,533,560 | 3.370 | 3.002 |
| C1 (seed → changed) | 2040.425 | 3,485,900 | 3.324 | 3.306 |
| C2 (C1 → changed) | 2029.305 | 3,515,936 | 3.353 | 3.290 |

These are observed correctness runs, not controlled performance benchmarks.
RSS describes the compiler worker, not the complete process tree. The 4,096 MiB
V8 old-space option is not a total RSS limit. Baseline and changed qualification
phases took 49.54 and 68.52 minutes respectively, including their
two builds and observations. The separate source conversion took
279.028 seconds during bootstrap.

## Source ownership and dependencies

Repository `packages/*/src/**/*.lean` remains the maintained bootstrap source.
The delivered `compiler/project.json` and its `.ps` files are authoritative for
ordinary development in that standalone workspace. Builds do not regenerate
those files from Lean. Repository-wide canonical source-owner migration remains
separate work.

Ordinary development requires the distributed PSC1 directory, Linux x64 shared
libraries, POSIX `/bin/sh` and Linux `/proc`. It needs no separately installed
Lean/Lake, Node/npm/Bun, TypeScript, Rust/Cargo, C/C++ compiler or Python.
Node/V8 is bundled and required; no runtime-free implementation is claimed.
The private host, runtime and native checker are prebuilt components.

Initial assembly/source conversion still uses pinned Lean/Lake and native build
tools, Node, Python 3, Git, curl and tar. CI's ldd, privilege, namespace and
strace tools assemble and observe the isolated test outside the developer root.
The exact system-library inventory is retained in the receipt. Rebuilding
the runtime/checker, and optional external target consumers, retain their own
explicit toolchain requirements.

## Preserved boundaries and supporting gates

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, genuine independent
admission, ordinary logical/body pairing, strict original/transformed IR,
semantic fuel and established acceptance policies remain.
Portable compiler bodies, kernel internals, PSKernel-Core, MinKernel and the
production npm host are unchanged by this standalone host/distribution work.

The broader [source gate 40618701864](https://github.com/dwijayuda/pskernel/actions/runs/40618701864)
passes all 16 selected jobs and 37/37 finite Practical Core criteria; benchmark
skipped. Its tested PR merge `58a80323b55a4a2fe0daa7c490a6451d8df1e1f1` has tree
`d39843e7db03ecc9b942b65494ecd7298dc9549f`, exactly the implementation tree.
Later documentation-only commits do not change that tested runtime.

The first standalone attempt
[40617744580](https://github.com/dwijayuda/pskernel/actions/runs/40617744580)
completed checked 125-module conversion but failed smoke because Node permission
mode prohibits worker `fsync`. The correction removes flushing only from the
unaccepted temporary response. Host verification and durable accepted-output
publication remain. The successful run repeated the full required qualification.

## Limits and next priorities

Ordinary compiler requests retain 240 seconds and independent checking 120
seconds. Full compiler rebuilds use the explicitly named 3,600-second correctness
profile. This qualifies a finite Linux x64 development cycle, not 240-second
performance, other platforms, arbitrary language changes, compiler semantic
preservation, diverse double compilation, or self-rebuilding runtime/kernel.
The existing npm product's broader targets retain their own qualification scope.

1. Profile the measured full compiler path and improve developer latency while
   retaining exact source identities, fresh admission and strict IR checks.
2. Design the repository-wide `.ps` source-owner migration with one canonical
   editable owner and explicit bootstrap references; do not create drifting
   parallel sources.
3. Extend actual changed-source regression coverage beyond the diagnostic case,
   then qualify installation and system-library behavior on additional platforms.
4. Continue the independent existing roadmap streams without treating this
   milestone as complete modular linking, incremental compilation or universal
   release qualification.

See the [standalone usage guide](standalone/README.md),
[architecture/dependency audit](docs/PSC1_INDEPENDENT_DEVELOPMENT.md) and
[remaining roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md).
