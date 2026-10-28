# PSC1 AI work state

Updated 2026-10-28 Asia/Jakarta. Active branch
`feat/psc1-independent-development-20261028`, created from qualified PR #198 HEAD
`ee9220e20e6b9fa202693c8226815a780cc5bbc0`.
GitHub-connected tools and Linux GitHub Actions only; single-parent expected-HEAD,
non-force history. No merge or registry publication.
The previous state is preserved byte-for-byte in
[history](docs/history/AI_WORK_STATE_BEFORE_INDEPENDENT_DEVELOPMENT_2026-10-28.md).

## Current objective

Develop a complete editable ProofScript compiler project using a qualified
generated PSC1 compiler, with no separately installed external language toolchain.
The user explicitly permits a distributed prebuilt runtime and independent
precompiled proof checker.

The [architecture and dependency audit](docs/PSC1_INDEPENDENT_DEVELOPMENT.md)
selects direct generated JS plus a private pinned Node/V8 runtime and the genuine
native official Lean 4.35.0 checker. The ordinary cycle emits and executes a new
compiler directly. Rust/TS emitted-source recompilation and a new IR interpreter
are unnecessary for this first milestone.

## Implementation under qualification

The new standalone profile owns its CLI/runner, bootstrap and acceptance workflow.
It packages qualified frozen JS compiler and native checker inputs, captures and
checks the complete selected compiler's conversion to editable `.ps` modules,
and runs fresh independent admission on each rebuilt generation.

The dedicated Linux workflow first runs installation/refusal/integrity checks,
then two parallel full compiler chains inside a network-disabled minimal root:

- Baseline: seed -> current `.ps` compiler B1 -> B2.
- Changed: seed -> real modified `.ps` diagnostic compiler C1 -> C2, with
  observed changed behavior in both generated compilers.

Source closure, canonical admissions, original/transformed IR and executable
identities are compared within each same-source chain. Full compiler compilation
uses the explicit 3,600-second correctness profile. Ordinary requests remain
240 seconds and independent checking 120 seconds. No full-cycle success or
performance qualification is claimed until completed Actions evidence is recorded.

## Preserved boundaries

Existing portable source/compiler/kernel/production npm host implementations are
unchanged by this host/distribution batch. The repository's Lean-like source
remains the bootstrap reference; the delivered standalone `.ps` project is the
editable source consumed in independent development. This is not a silent
whole-repository source-ownership migration.

The private runtime and small JS host are distributed components; changing their
implementation, or rebuilding the native kernel, still has bootstrap-toolchain
requirements. No separate Node/Bun installation is needed by the proposed
ordinary cycle. Exact minimal-environment execution must demonstrate that claim.

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, genuine admission,
ordinary logical/body pairing, strict original/transformed IR and semantic fuel
remain. Kernel internals, PSKernel-Core and MinKernel are untouched.
Finite self-host fixed points are not formal compiler-correctness proofs.

## Inherited qualified checkpoint

PR #198 base is 22 commits ahead of qualified transform-origin PR #196 with no
portable compiler-body changes in that interval. Base full source run 40509034008 and
exact-base package run 40546073325/static run 40546073429 pass. The .13 cohort contains
frozen G3 executors for 122 modules / 4,742 members, closure
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
The maintained source records 125 import modules. Historical fixed points do not
qualify the newer source or its `.ps` conversion automatically.

## Next action

Inspect the dedicated workflow, correct any actual failures, and retain exact
source/tool/package/run evidence. Only promote the independent-development
milestone after both complete compiler chains and refusal checks pass.
Measure the resulting compile time and RSS before selecting an optimization.
