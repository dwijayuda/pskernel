# Independent PSC1 compiler development

Status: qualified first Linux x64 independent-development milestone, 2026-10-28 UTC.
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

Repository source in `packages/*/src/**/*.lean` remains the maintained bootstrap
reference. The standalone distribution includes a complete editable `.ps`
compiler project in dependency order, derived from the selected current source.

The conversion reuses the existing lossless capture, source ownership and
checked converter. It requires exact canonical admissions and original IR
correspondence, preserved ordinary logical/body pairing and partial names,
ordered member ownership and actual independent admission of both endpoints.
The owner-notes comment policy preserves comment bytes and order while placing
body comments before their owner declaration. It is not an exact layout copy.

After conversion, standalone builds read the `.ps` files in the project.
They do not regenerate them from Lean source or invoke the translator.
An edit changes the compiler request source digest and the new compiler output.
The editable project is authoritative for that development workspace. Promoting
these files over every repository bootstrap reference is a separate migration,
not a claim attached to this first distribution.

Existing import/package names are retained. A small explicit project lists
source paths and modules; it supplies source data only. It cannot choose a
runtime, checker, command, output executor, network location or publication
policy. No package-manager service or install hook is needed.

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

## Next engineering priorities

Profile the measured full compiler path before selecting a latency optimization.
Persistent checked modules, incremental frontend state and reduced serialization
are candidates, not demonstrated bottleneck fixes. No optimization may replace
fresh checks with unjustified acceptance. The current profile recompiles the
whole ordered project and selects successors explicitly with `--compiler`.

Plan the repository-wide canonical `.ps` source-owner migration separately from
this already working editable workspace, then extend actual compiler-change and
platform coverage. The first milestone required no new backend, runtime, package
manager or core-language extension.
