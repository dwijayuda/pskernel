# Standalone PSC1 compiler development

PSC1 packages its private Node 22.23.3/V8 runtime, the genuine precompiled official
Lean 4.35.0 native checker, and an editable ProofScript compiler project.
The refreshed O2 distribution passes complete independent-development qualification
on Ubuntu 24.04 x64, Ubuntu 22.04 x64 and Ubuntu 24.04 ARM64 in
[run 40655419917](https://github.com/dwijayuda/pskernel/actions/runs/40655419917)
at `a4ca02ef9af1859dfb532a051f6ea4760ed113d0`.
The [environment receipt](../docs/PSC1_INDEPENDENT_ENVIRONMENTS_QUALIFICATION_2026-10-28.json)
retains exact runtime, system-library, filesystem, source, generation and publication
evidence for each environment.

Ordinary compiler rebuilding requires no separate Node, Bun, Lean, Lake,
TypeScript, Rust or C/C++ compiler installation. Keep the installation's private
runtime, host, checker and sources together. Compatible Linux system libraries,
`/bin/sh` and Linux `/proc` remain required.

## Qualified downloads

| Environment | Platform | Runtime glibc | Qualified download and exact evidence |
| --- | --- | --- | --- |
| Ubuntu 24.04.5 LTS x64 | `linux-x64` | 2.39 | [ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40655419917/artifacts/12804843660) · [phase records](../docs/PSC1_UBUNTU_2404_X64_INDEPENDENT_QUALIFICATION_2026-10-28.json) |
| Ubuntu 22.04.5 LTS x64 | `linux-x64` | 2.35 | [ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40655419917/artifacts/12804362999) · [phase records](../docs/PSC1_UBUNTU_2204_X64_INDEPENDENT_QUALIFICATION_2026-10-28.json) |
| Ubuntu 24.04.5 LTS ARM64 | `linux-arm64` | 2.39 | [ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40655419917/artifacts/12806507601) · [phase records](../docs/PSC1_UBUNTU_2404_ARM64_INDEPENDENT_QUALIFICATION_2026-10-28.json) |

Each ZIP contains its environment's `psc1-independent-linux-x64.tar.gz` or
`psc1-independent-linux-arm64.tar.gz`, completed `summary.json`, and
`SHA256SUMS`. The exact tarball identities are:

| Environment | Archive | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Ubuntu 24.04.5 LTS x64 | `psc1-independent-linux-x64.tar.gz` | 46,588,589 | `dc4b2eb52e59b6eea8c5085bf5efa12b4972835e89ddb06fc991d35f1c01d200` |
| Ubuntu 22.04.5 LTS x64 | `psc1-independent-linux-x64.tar.gz` | 46,588,594 | `7ce2f354c794e13a217e80fda7ac7520b92449bff8fcb6e4bb3532c58d3f8b41` |
| Ubuntu 24.04.5 LTS ARM64 | `psc1-independent-linux-arm64.tar.gz` | 46,330,627 | `e87cb2872921218a70de1929e93853720b003c3fb5aba46166a24741e1f8559d` |

Actions retains these artifacts until 2027-01-26T08:14:52Z. macOS, Windows and Linux
environments beyond the listed evidence are not qualified by this run.

The [initial standalone receipt](../docs/PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
and its [original run](https://github.com/dwijayuda/pskernel/actions/runs/40618697529)
remain historical evidence. The current downloads use the separately measured
and qualified O2 seed.

## Installation and first use

Extract the downloaded ZIP, then unpack its platform tarball and enter the resulting
toolchain directory. The delivered
directory contains `bin/psc`, the private runtime, host and checker, a frozen
qualified seed compiler, licenses and `compiler/project.json` with editable
`.ps` modules. Keep these installation resources together.

```sh
tar -xzf psc1-independent-linux-x64.tar.gz  # use linux-arm64 on ARM64
cd toolchain
./bin/psc identity
./bin/psc diagnostic
```

The identity output reports the actual installed resource identities.
The diagnostic command deliberately exercises the compiler's envelope-arity
refusal; it does not grant proof admission.

## Rebuild the compiler

```sh
./bin/psc build compiler/project.json \
  --profile correctness-3600s --out build/g1

./bin/psc build compiler/project.json \
  --profile correctness-3600s --compiler build/g1 --out build/g2
```

The first build uses the distributed qualified generated compiler. The second
executes the compiler just emitted in `build/g1`. Selecting a new generation is
explicit: building it does not replace the default installed seed. Both read the same editable
`.ps` files and independently check their new admission graph. There is no
Lean-source translator or target-language compiler on these commands' path.

Output directories must be new. A failed check must not produce an accepted
generation. Each generation retains its compiler source output and exact
source/admission/IR/executable identities and observations.

For a two-generation repeatability check:

```sh
./bin/psc selfhost compiler/project.json --out build/repeat
```

This explicit whole-compiler operation selects the correctness profile, produces
`generation-1/` and `generation-2/`, and records their comparison in
`selfhost.json`. It is a finite fixed-point check, not a formal compiler proof.

## Develop a changed compiler

Edit a module listed by `compiler/project.json`, then build into a fresh directory:

```sh
./bin/psc build compiler/project.json \
  --profile correctness-3600s --compiler build/g2 --out build/changed

./bin/psc build compiler/project.json \
  --profile correctness-3600s --compiler build/changed --out build/changed-repeat
```

Use ordinary edits to the `.ps` files. Do not edit emitted compiler JavaScript to
simulate a source change, and do not regenerate your working sources from the
bootstrap reference. The development project supplies exact ordered source
paths; it cannot select executables or proof-checking policy.

The qualification driver edits three real modules in a copied compiler workspace:
the unified protocol diagnostic, ProofScript declaration parser, and compiler parse
diagnostic. It builds C1 from those sources, executes C1, then uses C1 to build C2
from the same changed sources and executes C2. The five canonical payloads agree
between C1 and C2: emitted compiler, admissions, original IR, transformed IR and sources.

The copied parser accepts a test-only `defconst` alias. The installed grammar
remains unchanged. Six programs run against the seed, C1 and C2:

| Case | Seed | C1 and C2 |
| --- | --- | --- |
| Existing `const answer : Nat := 42` | Execute 42 | Execute 42 |
| `defconst` with a typed function call | Parse refusal | Execute 42 |
| Malformed existing `const` | Parse refusal | Updated parse refusal |
| New declaration without a type | Parse refusal | Updated parse refusal |
| New constant with parameters | Parse refusal | Updated parse refusal |
| New declaration with `Nat := true` | Parse refusal | Elaboration refusal |

The separate invalid-envelope observation changes from `request-arity` to
`request-arity:expected-three-fields` in C1 and C2. Existing positive behavior
and refusal/publication boundaries are checked alongside each new behavior.

## What this profile covers

The standalone profile develops the complete unified semantic compiler and checks its
generated JavaScript compiler artifact. The established npm CLI remains the
broader application product for the seven output selections and optional target
SDKs. The standalone profile is deliberately small; it does not silently install
npm packages or add a new package manager.

The distributed runtime and host implement execution, filesystem/process control
and the developer command. The independent native checker validates logical
declarations using official Lean kernel rules. The kernel, host and runtime are
prebuilt components. Rebuilding those components themselves can require their
bootstrap toolchains.

The repository now has one canonical editable `.ps` owner for each portable
compiler/library module, with explicit paired bootstrap references. The
[ownership guide](../docs/CANONICAL_SOURCE_OWNERSHIP.md) explains how repository
edits are checked. The installed `.ps` project remains authoritative for edits
in its standalone workspace.

## Measured rebuild improvement

The [TypeKey qualification](../docs/PSC1_TYPE_KEY_LATENCY_QUALIFICATION_2026-10-28.json)
compares original B2 and optimized O2 on the same immutable 125-module project,
in one sequential pair on the same runner.

| Observation | B2 control | Optimized O2 | Observed reduction |
| --- | ---: | ---: | ---: |
| Compiler worker | 1,710.047 s | 1,485.908 s | 13.107% |
| Complete host invocation | 1,720.972 s | 1,496.718 s | 13.031% |

The measured source change delays recursive-function construction in
`psIrSpecializeTypeKeyWithFuel` until a type is inspected, preserving fuel, keys
and refusal conditions. O1 and self-rebuilt O2 have identical compiler, candidate,
admission, original/transformed IR and source payloads. Both benchmark builds
reproduce every original candidate byte. All four builds perform fresh independent
admission and strict IR checks.

O2 is retained in
[artifact 12796523762](https://github.com/dwijayuda/pskernel/actions/runs/40634776830/artifacts/12796523762),
with compiler SHA-256
`49d851d26008abf116b9f4c680c0833311e835b90d6c58e369ca426f33ecd2e6`.
The downloads above contain the refreshed O2 distribution qualified through the
complete three-environment matrix. Every environment freshly checks source
correspondence, builds B1/B2 and C1/C2, executes the changed behavior after
self-rebuild, and verifies publication and refusal boundaries.

The result is one observed pair; it does not establish a statistical guarantee.
The optimized full rebuild still exceeds the 240-second target and uses the
explicit 3,600-second correctness profile. Exact provenance and interpretation are
in the [development account](../docs/PSC1_INDEPENDENT_DEVELOPMENT.md#measured-rebuild-profile-and-type-key-improvement).

## Resource and evidence policy

Ordinary requests retain a 240-second compiler limit. Complete compiler rebuilds
require the explicit 3,600-second correctness profile; the separate `selfhost`
command selects it by design. Independent checker calls retain 120 seconds.
Full compiler rebuilding processes the entire ordered project; this profile has
no incremental module cache. Read the qualified run's actual timing and worker
RSS measurements before estimating your workload. The runtime's 4,096 MiB
old-space setting is a V8 heap limit, not a total-process or process-tree RSS limit.

A source or tool mutation, semantic refusal, independent-checker rejection or
resource exhaustion prevents publication of a new accepted generation. Failures
before the completion marker preserve the rule that incomplete generations
cannot be selected as compilers. An error reported as
`PSC1_INDEPENDENT_PUBLICATION_COMMITTED_UNCERTAIN` occurs after that marker was
written and may leave a complete generation. Inspect the recorded output rather
than assume rollback or retry into the same directory. Installed integrity
pins detect changes relative to the manifest; they do not authenticate a fully
replaced installation. The supplied archive's external digest is the starting
identity.

Kernel admission, strict IR validation, target execution and self-host fixed
points are distinct assurances. No formal compiler semantic-preservation theorem
or performance claim follows just from byte equality.

[Research, alternatives, dependency audit and acceptance design](../docs/PSC1_INDEPENDENT_DEVELOPMENT.md)
explain the implementation choice. The
[environment matrix](../../.github/workflows/psc1-independent-environments.yml) and
[per-environment workflow](../../.github/workflows/psc1-independent-environment.yml)
separate one-time package/source preparation from builds inside a minimal,
network-disabled filesystem with no external compiler/runtime tools.
Actual executable traces, private-runtime/checker hashes, linked-library identities
and generation receipts provide the evidence. Smoke checks include a relocated
installation and output path containing spaces, a real read-only-parent refusal
under UID/GID 65534, preserved accepted output, incomplete generations and tampering.
