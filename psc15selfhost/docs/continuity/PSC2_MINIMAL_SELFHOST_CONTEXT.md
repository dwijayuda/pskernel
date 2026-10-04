# PSC2 Minimal Self-Host Continuity Context

Status date: 2026-09-27
Branch: `psc2/minimal-selfhost-psc15`
Repository: `dwijayuda/pskernel`
Primary workspace: `psc15selfhost/`

## Why this document exists

This file is a continuity handoff for future chats, agents, and contributors. Read it before changing PSC2 self-host or `pskernel-core` work. The repository is the source of truth; this document records the intent and constraints that are easy to lose between sessions.

## Project goal

Build the smallest sound PSC2 self-hosting compiler/language core first, then grow capabilities around that core as libraries, elaborator features, controlled plugins, and backend packages.

The desired long-term layering is:

1. tiny semantic core + pskernel,
2. elaborator + controlled optional plugins,
3. libraries,
4. ecosystem integrations.

Features should move upward whenever possible. If something can be a library, prefer a library. If it can be syntax sugar, desugar it. Target-specific behavior belongs in target/backend capability layers, not the semantic core.

## Non-negotiable implementation rule

Trusted PSC2 kernel/self-host source must be written in the **actual PSC1-compatible `.lean` subset**, not merely valid Lean that looks simple.

Self-hostability is an executable gate. Trusted source must eventually pass through the PSC1 compiler itself. Do not weaken the gate to accept syntax or semantics PSC1 cannot compile.

Current trusted package:

`psc15selfhost/packages/pskernel-core/`

The package is intentionally isolated from the existing PSC1 bootstrap compiler closure. The compiler is allowed to build the kernel; the kernel must not become a dependency of the bootstrap compiler before the intended cutover.

## Language/reference policy

This historical continuity note is superseded for ProofScript source-language behavior by the root `PSC2_COMPLETE_LANGUAGE_AND_JS_PLATFORM.md` authority and `language-authority.json`. Active `.ps` source uses `ps-0.9-r3` / `ps-standard-0.9-r3`; the older v0.7/v0.6.1 syntax line is retained only as historical context and must not be accepted as a compatibility grammar.

Do not claim full Lean 4 semantic equivalence unless formally demonstrated by the relevant evidence. Differential parity against the mature PSC1Kernel/Lean behavior is evidence, not a blanket equivalence proof.

## Current Phase 1 strategy

Build foundational semantic modules in small RED -> GREEN slices:

1. package boundary,
2. Name,
3. Level,
4. Expr,
5. substitution/instantiation,
6. declarations/environment,
7. reduction/type checking,
8. trusted-kernel acceptance/parity gates.

Do not implement all PSC2 at once. The first target is the smallest kernel that can participate in a self-host fixed point.

## What has been added in this chat

### Package and isolation

Created:

- `packages/pskernel-core/package.json`
- `packages/pskernel-core/src/Ps/KernelCore.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Data.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Name.lean`
- `packages/pskernel-core/src/Ps/KernelCore/Level.lean`

The kernel package is `portable: true` and `bootstrap: false`.

`check-bootstrap-closure.mjs` explicitly forbids `pskernel-core` in the current PSC1 bootstrap compiler dependency closure.

### CI and gates

Created `.github/workflows/psc2-minimal-kernel.yml`.

Current foundational gates include:

- KernelCore boundary test,
- Name parity against `PSC1Kernel.Name`,
- Level parity against `PSC1Kernel.Level`,
- bootstrap closure isolation,
- dedicated PSC1-source/self-host source check.

### Trusted-source profile

Created `scripts/check-kernel-core-source.mjs`.

It rejects trusted-source conveniences that are outside the intended PSC1 subset, including Lean/Std implementation imports, unsafe/extern/macro/elaborator mechanisms, namespace/section conveniences, IO in trusted source, and other host-only escape hatches.

It also flattens the trusted internal import closure and invokes `lake exe psc1 check` so the actual PSC1 compiler validates the source.

### PSC1-subset lessons already discovered

The actual PSC1 compiler is stricter than Lean surface syntax. During this work the gate correctly rejected or exposed problems with:

- `&&` convenience syntax in trusted source,
- `==` convenience syntax in trusted source,
- nested constructor patterns,
- multi-scrutinee/multi-pattern matches,
- matching directly on host `List` in the isolated trusted closure,
- recursive functions whose decreasing argument is not obvious to PSC1,
- `partial def`, because checked-admission encoding does not accept partial declarations.

These are not reasons to weaken the gate. They are guidance for writing truly self-hostable PSC1-subset code.

### Tiny kernel-local data

To avoid depending on host `List`/`Option` implementation details, the trusted core now owns minimal containers:

- `PsKernelCoreOption`
- `PsKernelCoreList`

They are intentionally tiny. Do not grow them into a general standard library unless kernel semantics actually require it.

### Name

`PsKernelCoreName` currently has Lean-compatible foundational shape:

- anonymous,
- string segment,
- numeric segment.

Name equality and duplicate detection are implemented in PSC1-portable style.

String equality was rewritten as fuel-based structural recursion over UTF-8 traversal so it can be a total `def` instead of `partial def`.

### Level

`PsKernelCoreLevel` currently includes:

- zero,
- succ,
- max,
- imax,
- param,
- mvar.

Implemented minimal operations needed by current parity:

- structural equality,
- zero/nonzero classification,
- max/imax simplification,
- normalization,
- equivalence,
- parameter instantiation,
- metavariable detection.

Parameter substitution uses a single recursive spine `PsKernelCoreLevelSubst` rather than parallel parameter/value lists because the PSC1 structural recursion checker rejected the latter representation.

Level equivalence is being converted from `partial` recursion to total fuel-bounded recursion so the trusted source becomes admission-ready.

## What not to do

Do not:

- rewrite the repository from scratch,
- merge the new kernel into the compiler bootstrap closure prematurely,
- copy the entire mature PSC1Kernel implementation into the new core,
- bring replay, diagnostics, hashing, rendering, compatibility adapters, or test harness infrastructure into the trusted kernel just because the old kernel has them,
- add target-specific TS/Rust/Wasm behavior to the semantic kernel,
- use full Lean conveniences if PSC1 cannot compile them,
- call a semantic layer complete merely because Lean compiles it,
- remove differential tests to make CI green.

## Definition of self-hostable for this work

A trusted source module is not considered self-hostable merely because Lean accepts it.

For the current stage it should satisfy all of the following:

1. Lean 4.34 builds it.
2. The dedicated PSC1 source-profile audit accepts it.
3. The PSC1 compiler can parse/elaborate/check its flattened trusted closure.
4. It contains no unsupported partial/admission-only escape path.
5. Its observable semantic cases match the mature reference on the covered differential tests.

Later phases should strengthen this to generated compiler/kernel fixed-point evidence.

## Immediate continuation point

At the end of the current chat slice, Name and Level Lean parity are green, bootstrap isolation is green, and the remaining work is to make the total Name+Level trusted closure pass `psc1 check` at the admission-ready stage.

After that is green, start `Expr` with a new failing parity test before production implementation.
