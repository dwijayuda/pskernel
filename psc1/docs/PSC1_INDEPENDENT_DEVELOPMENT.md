# Independent PSC1 compiler development

Status: implementation under qualification, 2026-10-28 (Asia/Jakarta).
This document describes the standalone compiler-development profile. Exact
passed runs, source identities and remaining failures belong to the dated
qualification receipt and [AI work state](../AI_WORK_STATE.md). A pending run
is not a passed milestone.

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

The standalone profile uses the native official checker explicitly. The existing
npm product's default Wasm provider is unchanged. Compiler Wasm uses GC; kernel
Wasm is official C++/Emscripten linear memory. Those components are not interchangeable.

## Dependency audit

| Activity | External development tools |
| --- | --- |
| Initial package assembly and checked source conversion | Existing CI bootstrap uses pinned Lean/Lake, Node and repository native helpers; artifact/download/archive tools are assembly dependencies |
| Install the resulting archive | Archive extraction and the documented Linux system environment |
| Edit and rebuild the distributed compiler `.ps` project | PSC1 installation, its private runtime and precompiled checker; no separately installed Lean, Lake, Node, npm, Bun, tsc, Rust, Cargo, gcc or clang |
| Execute the next emitted compiler and rebuild it | Same installed host/runtime/checker, with the new emitted compiler artifact |
| Full independent-development verification | Bundled driver and toolchain inside an isolated minimal Linux environment; external CI isolation/tracing tools observe the process |
| Rebuild the runtime or native checker itself | Their own bootstrap/toolchain requirements remain |
| Select another output/consumer workflow | Target-specific runtime/SDK dependencies remain explicit; existing npm product covers the broader workflows |

The independent-development gate must exclude absolute-path access to the CI
runner's compiler SDKs as well as remove tool names from PATH. Its minimal root
contains only the distribution, required system shared libraries and the system
shell used by the launcher. Network isolation prevents fallback downloads.
The executable trace records real process launches. CI setup utilities do not
become ordinary developer dependencies.

## Qualification plan and interpretation

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

## Next decisions after measured results

First qualify actual current-source `.ps` rebuilding and a meaningful changed
compiler. Then address the largest measured development cost. Full rebuilding
may justify persistent checked modules, incremental frontend state or less
repeated serialization, but no optimization may replace fresh checks with
unjustified acceptance. The initial workflow deliberately avoids a new backend,
runtime or package-manager project before this cycle works.
