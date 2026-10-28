# Independent PSC1 compiler development

Status: first Linux x64 independent-development milestone and measured TypeKey
improvement qualified, 2026-10-28 UTC; expanded O2 installation qualification pending.
Implementation `5484a04df34de1bbcfa46a248b6a93ce510035d6` passes
[40618697529](https://github.com/dwijayuda/pskernel/actions/runs/40618697529).
The [dated receipt](PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
binds the exact implementation, source, generations, checker and archive.
This document describes that standalone profile; [AI work state](../AI_WORK_STATE.md)
records its scope and the next engineering priorities.

## Decision and scope

Distribute the existing PSC1-generated JavaScript compiler with a private pinned
Node/V8 runtime and the precompiled official Lean 4.35.0 native checker.
PSC1 emits the next compiler directly as JavaScript. The packaged runtime
executes it; no external language compiler converts it into an executable.

The runtime is an explicit component of the PSC1 installation. This removes
the requirement to install Node or Bun separately; it does not claim that the
implementation contains no JavaScript runtime. The native checker likewise
contains the precompiled Lean kernel and provider, while requiring no Lean
frontend, Lake, Lean SDK, C/C++ compiler or Emscripten installation.

The portable semantic compiler is the self-developed component. The small host,
runtime executable, independent kernel and source-conversion bootstrap remain
prebuilt components. Extending those components themselves can still require
their implementation toolchains. This first profile does not claim the entire
operating system, proof kernel or runtime is written in ProofScript.

## Selected repository checkpoint

The dedicated branch starts at `ee9220e20e6b9fa202693c8226815a780cc5bbc0`
on `feat/psc1-npm-umbrella-20261027` ([PR #198](https://github.com/dwijayuda/pskernel/pull/198)).
This is 22 commits ahead of the qualified transform-origin branch
`173ecdc9f7131366d376c80886a7843a402d363b`, with no intervening portable
compiler-body changes. It includes the source ownership, checked conversion,
modular-origin and package work. The unqualified intermediate partition branch,
editor branches and independent MinKernel research are separate.

Evidence predating this work:

| Subject | Actual qualification |
| --- | --- |
| Current source and modular-origin integration | [40509034008](https://github.com/dwijayuda/pskernel/actions/runs/40509034008), all 16 selected jobs and 37 finite Practical Core criteria; no performance claim |
| Exact base package distribution | [40546073325](https://github.com/dwijayuda/pskernel/actions/runs/40546073325), 53 finite cases and 125 advertised exports |
| Exact base static/aggregate gate | [40546073429](https://github.com/dwijayuda/pskernel/actions/runs/40546073429) |
| Frozen full generated compiler | 122 modules / 4,742 Core members, source closure `073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`; four engine G1/G2/G3 fixed points |
| Later maintained source | 125 source-import modules recorded at the selected base; selected-service G1, native source and modular component qualifications, with no inherited full G2/G3 claim |

The old fixed points compile the supported Lean-like grammar through the
generated PSC1 frontend. They are genuine self-hosting evidence, but do not
already establish canonical `.ps` development or a standalone developer
installation. Read [the frozen generated-IO receipt](PSC1_GENERATED_IO_QUALIFICATION_2026-10-26.json)
separately from the current source inventory.

## Architecture alternatives

| Alternative | Reuse and advantage | Recurring dependency or new work | Decision |
| --- | --- | --- | --- |
| Generated Rust compiler | Existing qualified native engine; lower measured RSS | Every newly emitted Rust compiler currently invokes Cargo/rustc | Preserve as optional engine/bootstrap; insufficient alone |
| Generated TypeScript compiler | Existing qualified semantic pipeline | Current next-generation build invokes tsc | Avoid on the first independent path |
| Generated JavaScript with private runtime | Existing direct emitter and qualified runtime behavior; no emitted-source compiler | Package runtime and host, provide source workspace and new checked generations | Selected |
| Generated compiler-Wasm with embedded runtime | PSC1 directly emits binary Wasm; existing GC ABI | Integrate and qualify GC embedding; eliminate current external validator/host requirements | Useful later alternative |
| New Core/IR interpreter | Could execute compiler artifacts directly | New runtime semantics, performance work and qualification burden | Not justified before reusing existing execution |
| Native machine-code backend | Would avoid a JS/Wasm execution substrate | New lowering, allocator, object/link format and platform/runtime work | Not necessary for the current objective |

The actual implementation in
[`generated-target-tools.mjs`](../host-tools/generated-target-tools.mjs)
invokes Cargo/rustc for Rust and TypeScript for TS. The JS path writes and
loads directly emitted JS. Compiler-Wasm calls the owned binary encoder and
transports hex bytes; `wasm-tools validate` is a validator, not the generator.

A single-file Node SEA or Bun executable was also considered. Both support
bundled runtimes, but the current host and Wasm provider use
`process.execPath` as a general runtime executable. A private runtime preserves
this behavior without adding a new application-dispatch emulation layer.
The first distribution therefore favors a simple directory installation over
an additional single-file packager.

Primary runtime references:
[Node 22.23.3 SEA](https://nodejs.org/download/release/v22.23.3/docs/api/single-executable-applications.html),
[Node process API](https://nodejs.org/download/release/v22.23.3/docs/api/process.html),
[Bun standalone executables](https://bun.sh/docs/bundler/executables).
These describe runtime packaging capabilities, not PSC1 qualification.

## Source ownership and one-time bootstrap

The repository now uses the canonical `.ps` owners listed in
[`CANONICAL_SOURCES.json`](../CANONICAL_SOURCES.json): 151 portable compiler
modules and 13 ordinary standard-library modules. Their paired `.lean` files
are explicit, pinned bootstrap references. The
[ownership guide](CANONICAL_SOURCE_OWNERSHIP.md) describes the sole editable
authority, native adapter boundaries, package views and checked refresh process.

The initial standalone milestone converted selected native sources into the
editable project and freshly checked both grammar endpoints. The canonical
promotion retained those exact 125 PS source bytes. The measured TypeKey change
then edits that canonical project and uses the checked reference workflow.
Refreshed standalone assembly copies current canonical PS bytes directly and
checks their correspondence with the pinned native references.

Ordinary installed builds capture their editable `.ps` files again. They do
not regenerate working sources from a bootstrap reference or call a translator.
An edit changes the compiler request source digest and the new compiler output.
Native tools are required only for repository bootstrap/reference maintenance in CI.

Existing import/package names remain. The explicit project lists ordered module
paths and source data. It cannot select runtime/checker policy, commands, network
locations or publication policy. No package-manager service or install hook is needed.

## Admission and executable boundaries

Every successful build must capture exact source bytes, execute the selected
generated compiler, validate the response identities and source coverage, and
send its exact new canonical admission graph to the independent checker.
The existing compiler pipeline performs strict original IR validation and
strict transformed IR validation before emitting the candidate.

The host reuses
[`createCompilerHostSession`](../host-tools/compiler-host-protocol.mjs).
Its private session binds request ID, output target, source closure digest and
literal admission bytes. A candidate or copied acceptance field cannot grant
publication authority. Checker identity is fixed:

- Protocol `pskernel-lean/1`, provider `lean4-cpp`, profile `lean4.35-core`.
- Official Lean 4.35.0 commit
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- Actual `--check` process for each graph, with the existing 120-second limit.
- Existing provider declaration admission and explicit unsupported-form refusals.

The official native provider translates canonical PSC terms and invokes the
pinned kernel. It does not compile Lean source.
Its [admission implementation](../packages/pskernel-lean/provider/PsKernelLean/Admission.lean)
remains unchanged. PSKernel-Core and MinKernel remain separate projects.

Resource hashes bind the installed runtime, seed compiler, checker, host and
runner before and after work. Generated compiler artifacts remain compiler
implementations, not trusted proof checkers. Hashes detect resource changes
relative to the installed manifest; an attacker who can replace the whole
installation and manifest is outside this integrity guarantee.
Kernel acceptance checks logical declarations. It does not prove arbitrary
compiler or JavaScript behavior safe.

Output completion is marked by `files.json`. Pre-commit failures cannot publish
an accepted incomplete generation. A directory-flush failure after that marker
can report `PSC1_INDEPENDENT_PUBLICATION_COMMITTED_UNCERTAIN`; the output may
already be committed and must be inspected instead of assuming rollback.

The standalone profile uses the native official checker explicitly. The existing
npm product's default Wasm provider is unchanged. Compiler Wasm uses GC; kernel
Wasm is official C++/Emscripten linear memory. Those components are not interchangeable.

## Dependency audit

| Activity | External development tools |
| --- | --- |
| Initial package assembly and checked source conversion | Pinned Lean/Lake and their native build tools, Node 22.23.3, Python 3 for artifact extraction/native-process bootstrap helpers, Git, curl and tar; repository helpers are built only here |
| Install the resulting archive | Archive extraction and the documented Linux system environment |
| Edit and rebuild the distributed compiler `.ps` project | PSC1 installation, its private runtime and precompiled checker; no separately installed Lean, Lake, Node, npm, Bun, tsc, Rust, Cargo, gcc, clang or Python |
| Execute the next emitted compiler and rebuild it | Same installed host/runtime/checker, with the new emitted compiler artifact |
| Full independent-development verification | Bundled driver and toolchain inside the minimal root; outside it, CI uses Node, ldd, sudo, coreutils, unshare, chroot and strace to assemble and observe isolation |
| Rebuild the runtime or native checker itself | Their own bootstrap/toolchain requirements remain |
| Select another output/consumer workflow | Target-specific runtime/SDK dependencies remain explicit; existing npm product covers the broader workflows |

The independent-development gate must exclude absolute-path access to the CI
runner's compiler SDKs as well as remove tool names from PATH. Its minimal root
contains only the distribution, required system shared libraries and the system
shell used by the launcher. Network isolation prevents fallback downloads.
The executable trace records real process launches. CI setup utilities do not
become ordinary developer dependencies.

## Qualification workflow and interpretation

The dedicated workflow separates bootstrap from ordinary compiler development:

1. Verify qualified input artifacts and assemble the distribution.
2. Convert the complete selected compiler source once and record exact identities.
3. Exercise installed positive, semantic-refusal, independent-checker-refusal and
   integrity cases before long generation work.
4. Inside a minimal isolated environment, compile the complete `.ps` project
   with the frozen qualified seed to produce B1.
5. Execute B1 and rebuild that project to produce B2; compare canonical source
   closure, admissions, original/transformed IR and executable bytes.
6. Independently copy the `.ps` workspace and change one real compiler
   diagnostic. Compile it to C1 and exercise the changed diagnostic.
7. Execute C1 and rebuild the modified source to C2; require the change and fixed
   point to persist.
8. Retain exact results, process observations and source artifacts.

The baseline and modified chains can run in parallel because neither consumes
the other's result. Each chain still executes the newly generated compiler for
its second build. The modified behavior must be observed; source-string presence
alone is insufficient.

Historical frozen-cohort JS self-compilations took 1,603,085 and 1,682,611 ms,
with reported maxRSS 3,434,572 and 3,600,140 KiB. These explain the separate
long correctness profile; they do not predict or qualify current-source speed.
Ordinary application requests retain their 240-second policy, checker requests
120 seconds, and full compiler rebuilds use a separately named 3,600-second
correctness ceiling. Existing semantic fuel and acceptance conditions are unchanged.

A finite fixed point provides repeatability evidence. It is not a
source-to-target preservation theorem, diverse-double-compilation result,
formal proof of compiler correctness or an unrestricted language guarantee.

## Qualified results and measured cost

The same-run gate passed bootstrap, smoke, B1/B2 and C1/C2. The editable baseline
contains 125 modules / 2,382,708 UTF-8 source bytes. Its closure is
`9d0f097e79eb2b1e14d10362c6db9b4bc2370c26627658017bf6b2681b46fabf`.
B1 and B2 have identical five canonical payloads; the changed C1/C2 pair also
matches exactly. Timing-bearing build receipts are outside that comparison.
B1 matches the checked bootstrap's canonical admission bytes. Its original IR bytes match the checked native bootstrap result as well.

The modified project changes exactly one diagnostic literal in
`Ps.CompilerUnified.Service`: `request-arity` becomes
`request-arity:expected-three-fields`. Both C1 and C2 exercise the changed
refusal. Its 125 modules contain 2,382,730 UTF-8 bytes and have closure
`1c29bbc077c9a35ca0d2e80f11794e7f6afbec0f662b3abddc3be88d1f832815`.
This qualifies a real diagnostic change, not an untested new syntax feature.

All three isolated phases recorded no unexpected executable invocation.
The smoke trace records 3 genuine checker executions, and each full chain records
2. The recorded Linux dependencies include glibc/loader, libstdc++, libgcc_s,
libm, libdl, libpthread and librt, plus the system dash shell. Exact paths, versions
where encoded by file names, sizes and hashes are in the receipt.

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

The broader [source gate 40618701864](https://github.com/dwijayuda/pskernel/actions/runs/40618701864)
also passes all 16 selected jobs and all 37 finite Practical Core criteria.
Benchmark was skipped. Its tested synthetic merge has exactly the implementation
tree `d39843e7db03ecc9b942b65494ecd7298dc9549f`.

The [qualified delivery artifact](https://github.com/dwijayuda/pskernel/actions/runs/40618697529/artifacts/12788978661) contains the tested
`psc1-independent-linux-x64.tar.gz`, final `summary.json` and `SHA256SUMS`.
The tar is 46,905,678 bytes and has SHA-256
`c227da916348087550f696a1b9f8ad0c6faacaad6bd86d6e72244ed4d96d2fe3`.
The delivery artifact is retained by Actions until 2027-01-26T02:03:45Z; this is
a qualified development artifact, not a published npm or universal release.
B1/B2 and C1/C2, complete changed source and raw traces are retained in the
separate baseline/changed evidence artifacts linked by the dated receipt.

Independent bootstrap tarballs are not claimed byte-identical: the embedded
source-conversion manifest records timing/RSS. This does not change the observed
same-source equality of the five deterministic compiler payloads.

The first attempt [40617744580](https://github.com/dwijayuda/pskernel/actions/runs/40617744580)
passed checked conversion but failed smoke on worker `fsync` under Node permission
mode. The correction removed only flushing of unaccepted temporary responses;
host verification and durable accepted-output publication remain. Qualification
was repeated from bootstrap through both chains and the final gate.

## Measured rebuild profile and type key improvement

The initial correctness timings above motivated a separate measured experiment.
The [profile receipt](PSC1_REBUILD_PROFILE_2026-10-28.json) records
[run 40631714254](https://github.com/dwijayuda/pskernel/actions/runs/40631714254),
which executes the qualified B2 compiler on the exact 125-module project:
2,382,708 UTF-8 source bytes and source closure
`9d0f097e79eb2b1e14d10362c6db9b4bc2370c26627658017bf6b2681b46fabf`.
The compiler worker took 1,236.092 seconds under observation. The result matched
the complete qualified candidate bytes and passed fresh independent admission.

The CI observer uses V8 statistical ticks at a 5 ms interval, with a small
logging-and-processing preflight before the full workload. It retains permission
mode, the 4,096 MiB old-space setting and bounded execution. Ordinary host and
runner code remain unchanged. Raw and preprocessed profiles, observation-tool
identities and the acceptance evidence are retained in
[artifact 12792955597](https://github.com/dwijayuda/pskernel/actions/runs/40631714254/artifacts/12792955597).
`nm` and `objdump` are CI observation dependencies.

Of 243,356 ticks, nearest generated-frame attribution assigned 18.721% to
`psIrSpecializeTypeKeyWithFuel`; sampled GC accounted for 19.617% overall.
These are statistical tick shares, not exact wall-clock phase times, and physical
generator stacks differ from logical ProofScript call stacks. The source showed
that the successor-fuel case constructed the remaining recursive-function chain
before receiving a type.

The selected source change moves the type lambda before the `smaller` binding
in `Ps.CompilerIr.Specialize`. It prepares the recursive function when a type is
inspected while preserving fuel, branches, type keys and refusal conditions.
The change is confined to one `.ps` module; its before and after files are both
60,198 bytes. The runtime, serialization, cache policy, independent checker and
strict IR rules are unchanged. Exact definitions and anchors are retained in
[the TypeKey receipt](PSC1_TYPE_KEY_LATENCY_QUALIFICATION_2026-10-28.json).

### Controlled qualification

[Run 40634776830](https://github.com/dwijayuda/pskernel/actions/runs/40634776830),
job `122639100927`, passes at
`bc983a806a2995bed7851512a175652cbf4b5226` using the
[qualification harness](../standalone/qualify-type-key-latency.mjs).
It verifies immutable distribution artifact `12788978661` and B2 artifact
`12787934687`, then performs four ordinary builds:

1. The frozen qualified seed compiles the changed source to O1.
2. O1 compiles that same source to O2.
3. Original B2 compiles the immutable original source as the control.
4. O2 compiles that identical original source as the optimized comparison.

All four builds perform fresh independent admission and strict original and
transformed IR checks. O1 and O2 have identical `compiler.mjs`, `candidate.json`,
`admissions.json`, `original-ir.json`, `specialized-ir.json` and `sources.json`.
Each publication also retains its timing-bearing `build.json` and verified
`files.json` completion marker.

Both benchmark builds reproduce every byte of the original 73,800,724-byte
candidate, SHA-256
`532081726b246297e30fd0a0975f95a6198510e295338a2bcfbe74ed602c4978`.
The original compiler, admission, original/transformed IR and source payloads
also match exactly. The controlled pair uses the same machine, private Node
22.23.3 runtime and ordinary runtime flags.

| Observation | Original B2 control | Optimized O2 | Observed reduction |
| --- | ---: | ---: | ---: |
| Compiler worker | 1,710.047 s | 1,485.908 s | 224.139 s / 13.107% |
| Complete host invocation, measured by the harness | 1,720.972 s | 1,496.718 s | 224.254 s / 13.031% |
| Compiler-worker peak RSS | 3,619,020 KiB | 3,435,212 KiB | 183,808 KiB / 5.079% |

The RSS decrease is 179.5 MiB. RSS describes the compiler worker. Fresh independent
checking took 2.848 seconds for the control and 2.843 seconds for the optimized
invocation; it remains part of ordinary build and publication.

This is one sequential matched pair on one hosted runner. It establishes the
observed reduction for this workload; other machines and projects need their own
measurements. The separate profiled run is not the denominator for these percentages.
No post-change GC-time reduction was measured.

### O2 seed provenance and installation boundary

The qualified seed input is `O2/` in
[artifact 12796523762](https://github.com/dwijayuda/pskernel/actions/runs/40634776830/artifacts/12796523762).
The archive is 24,777,348 bytes, SHA-256
`c17a4d364810714e4dd7ed775fb9ff3547de87ebf89501e402d75fc9a7fb7af1`.
Its ancestry starts with the qualified frozen seed
`e7d9c7b6eb9ea22aaaecad2bbf21adcf9856a0518dba0079eb63e8db0d03a0aa`;
O1 and O2 both emit the compiler identity below.

| O2 identity | SHA-256 |
| --- | --- |
| Compiler | `49d851d26008abf116b9f4c680c0833311e835b90d6c58e369ca426f33ecd2e6` |
| Publication `files.json` | `aa1ca6b19585a7be8b21d78b9ab4cbb024abd633466f41a7bfc292380696f80c` |
| Complete changed 125-module source closure | `424c15ce2cf5bb87a293dd2aad1705fa801c07067c972578aa76111627d590d7` |
| Changed `Ps.CompilerIr.Specialize` source | `74fb1bb1c8f9beef611300e06fff3010121ed2589e828b7102f539217a09ad93` |

The artifact retains `summary.json`, `source-change.json`, complete before and
after source files, O1/O2 publications and both benchmark publications.
Its `optimized-baseline/` output intentionally recreates historical B2.
The optimized seed is selected from `O2/`.

The initial standalone download remains separately pinned by its original receipt.
Refreshed assembly binds the O2 archive and all seven publication files, requires
exact current `.ps` source correspondence, and freshly establishes native
source/admission/IR correspondence before selecting O2. The expanded installation
and publication matrix for that refreshed distribution is pending.

[Runtime/checker ABI preflight](PSC1_ADDITIONAL_PLATFORM_ABI_QUALIFICATION_2026-10-28.json)
passes on Ubuntu 24.04 x64, Ubuntu 22.04 x64 and Ubuntu 24.04 ARM64 in
[run 40633426535](https://github.com/dwijayuda/pskernel/actions/runs/40633426535).
That receipt retains runtime, native-checker, system-library and shell identities;
it records `fullCompilerQualified: false` and `publicationQualified: false`.
Full compiler chains, installed behavior and publication boundaries require their
own completed environment evidence.

The optimized worker still takes 1,485.908 seconds on this workload. The original
240-second full-compiler target remains unmet; the successful run uses the
explicit 3,600-second correctness profile. Ordinary 240-second requests,
120-second independent checking, semantic fuel and strict acceptance conditions
retain their existing policies.

## Next engineering priorities

Use qualified O2 as the next full-workload measurement baseline. Repeat controlled
pairs and profile the optimized compiler before selecting the next change to
persistent checked modules, frontend state or serialization. The 240-second
full-compiler target remains open. Every optimization must retain fresh
independent admission, strict original/transformed IR checks, semantic fuel and
refusal conditions.

Complete current-source/native correspondence and O2 assembly, then qualify the
broader changed-compiler chains and installation matrix. Each supported environment
needs exact runtime, native checker, system-library, generation and publication
evidence. Full environment qualification remains pending actual execution.
