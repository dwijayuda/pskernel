# Standalone PSC1 compiler development

This Linux x64 profile packages PSC1 with its private pinned Node/V8 runtime and
the genuine precompiled official Lean 4.35.0 native checker. An editable
ProofScript compiler project is included. No separate Node, Bun, Lean, Lake,
TypeScript, Rust or C/C++ compiler installation belongs to the ordinary
compiler rebuild cycle.

**Qualification status:** see [AI_WORK_STATE.md](../AI_WORK_STATE.md).
Implementation and workflow presence alone are not passing evidence.

## Installation and first use

Extract the qualified standalone archive and enter its directory. The delivered
directory contains `bin/psc`, the private runtime, host and checker, a frozen
qualified seed compiler, licenses and `compiler/project.json` with editable
`.ps` modules. Keep these installation resources together.

```sh
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
executes the compiler just emitted in `build/g1`. Both read the same editable
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

The repository retains its existing bootstrap `.lean` source ownership.
The delivered `.ps` project is authoritative for edits in that standalone
workspace. A repository-wide switch of source owners is a separate migration.

## Resource and evidence policy

Ordinary requests retain a 240-second compiler limit. Complete compiler rebuilds
require the explicit 3,600-second correctness profile; the separate `selfhost`
command selects it by design. Independent checker calls retain 120 seconds.
Full compiler rebuilding historically took tens of minutes and several GiB of
memory. Read the new run's actual measurements before estimating your workload.

A source or tool mutation, semantic refusal, independent-checker rejection,
resource exhaustion or interrupted build must fail closed. Installed integrity
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
