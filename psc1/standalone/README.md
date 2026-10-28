# Standalone PSC1 compiler development

This Linux x64 profile packages PSC1 with its private pinned Node/V8 runtime and
the genuine precompiled official Lean 4.35.0 native checker. An editable
ProofScript compiler project is included. No separate Node, Bun, Lean, Lake,
TypeScript, Rust or C/C++ compiler installation belongs to the ordinary
compiler rebuild cycle.

**Initial standalone qualification:** complete baseline and changed-source
compiler rebuilds pass
[40618697529](https://github.com/dwijayuda/pskernel/actions/runs/40618697529) at
`5484a04df34de1bbcfa46a248b6a93ce510035d6`.
The [initial receipt](../docs/PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json)
binds that distribution. A subsequent measured source optimization passes
[40634776830](https://github.com/dwijayuda/pskernel/actions/runs/40634776830), with
[separate profile and O2 evidence](../docs/PSC1_INDEPENDENT_DEVELOPMENT.md#measured-rebuild-profile-and-type-key-improvement).

Download the [qualified Linux x64 artifact](https://github.com/dwijayuda/pskernel/actions/runs/40618697529/artifacts/12788978661).
It contains `psc1-independent-linux-x64.tar.gz`, the completed evidence summary
and `SHA256SUMS`. The tar is 46,905,678 bytes with SHA-256:

```text
c227da916348087550f696a1b9f8ad0c6faacaad6bd86d6e72244ed4d96d2fe3
```

Actions retains this artifact until 2027-01-26T02:03:45Z. Ubuntu 24.04 Linux x64
is the tested environment; compatible system libraries, `/bin/sh` and Linux
`/proc` remain required.

## Installation and first use

Extract the qualified standalone archive and enter its directory. The delivered
directory contains `bin/psc`, the private runtime, host and checker, a frozen
qualified seed compiler, licenses and `compiler/project.json` with editable
`.ps` modules. Keep these installation resources together.

```sh
tar -xzf psc1-independent-linux-x64.tar.gz
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

The qualification driver uses a concrete example: the actual unified compiler's
invalid request-arity diagnostic changes from `request-arity` to
`request-arity:expected-three-fields`. It executes the changed compiler and its
self-rebuilt successor to observe the new refusal. This changes compiler
behavior without inventing a new language feature.

## What this profile covers

The first profile develops the complete unified semantic compiler and checks its
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
The download above identifies the initial qualified distribution. Expanded
installation/publication qualification for the refreshed O2 distribution is pending.

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
explain the implementation choice. The dedicated
[Linux workflow](../../.github/workflows/psc1-independent-development.yml) separates
one-time package/source preparation from builds inside a minimal, network-disabled
filesystem with no external compiler/runtime tools. Its actual executable trace
and generation receipts provide evidence for the ordinary-dependency claim.
