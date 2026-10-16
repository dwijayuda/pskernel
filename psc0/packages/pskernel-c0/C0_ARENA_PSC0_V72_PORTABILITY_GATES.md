# PSKernel-C0: External Arena evidence and future PSC0 v7.2 portability gates

Status: native Lean engineering and qualification inventory — 17 October 2026.
Scope: dwijayuda/pskernel, branch perf/pskernel-c0-v7-rust-20261012.
**No Rust experiment and no compiler/self-host implementation in this phase.**

## Boundary and pinned versions

The admitting PSKernel-C0 checker is native Lean 4.35.0 at commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Only the original native checking and declaration-admission APIs authorize checked declarations. Cached syntax, hash identities, external test labels, build artifacts and archived verdict tables are untrusted inputs; they never authorize theorem acceptance.

Outcome categories must remain distinct: accepted, rejected, unsupported, malformed, resource exhausted, inconclusive, timeout and host error. An unsupported or historical-version input is a **decline**, not a rejection, and never a successful conformance case.

## External Lean Kernel Arena — frozen small suite

Source: https://github.com/leanprover/lean-kernel-arena/releases/tag/round-2026-09
Frozen source commit: 5d7ca987618f1136aaa296057b50a2c10c4ce77a.

Archive: lean-arena-round-2026-09-tests.tar.gz
SHA256: 98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d.

The September 2026 archived small suite contains 122 expected accepts and 71 expected rejects. It excludes the large Init/Std/Mathlib tests. The archive consists of older-version native Lean exports; their headers must not be spoofed or relaxed by the 4.35.0 production importer.

The new workflow pskernel-c0-external-arena.yml fetches the frozen release, checks SHA256, and uses test/arena_conformance.py to run each original file through the native C0 checker, emitting a per-case JSON verdict matrix and separate native 4.35 control receipts. Archive members are validated and used from a temporary directory, not extracted blindly.

First run: https://github.com/dwijayuda/pskernel/actions/runs/38973833964
Result: driver and SHA256 gates passed; all **193 historical cases explicitly declined**, with **zero external Arena accepts/rejects qualified** and **7/7 separate native 4.35 controls qualified**. This is not an external Arena compatibility pass.

The native 4.35 source adaptation workflow pskernel-c0-arena-native435.yml pins actual Arena-authored Lean source files at the upstream commit and compiles/exports them using the native 4.35.0 toolchain. It independently asks the official checker and C0 to judge the **same newly exported bytes**: large Nat literal addition/subtraction/boolean comparison and the forged wrong-result addition theorem. These are 4.35 adaptations, **not** matches on original 2026-09 archive bytes. They must be classified independently. No false acceptance or false rejection is permitted; a harness error must not be counted as a kernel verdict.

## Stronger acceptance gates

- Enforce **zero false acceptance** of each independently invalid, supported input. Correct negative result must be a checked rejection, not an unsupported parser or version error.
- Enforce zero false rejection of independently valid, supported inputs. Explicit declines are allowed for unsupported syntax/profiles but excluded from completeness success counts.
- Publish exact test IDs and denominators for true accepts, true rejects, declines, resource outcomes, timeouts and crashes. A green reporting workflow with 193 version-declines does not establish kernel compatibility.
- Gradually expand native-exported Arena examples to binder/universe checking, projections, inductive/recursor metadata, quotient behavior, and adversarial axiom/annotation policies with independent official evidence. Keep source identities pinned.
- Qualify full exact original Init (6,452,982 records), Std and Mathlib separately with realistic timing and memory budgets. Never infer performance from synthetic indexed-storage microbenchmarks.

## Native performance path

The known blocker is in large proof-body inference, not header checks or final theorem DefEq. A pinned 499,130-record official-accepted dependency stalls at theorem record 315928; the disposable stage profiler showed the original source proof-body checker running at timeout. The 15,758-record hard WF closure also remains unqualified.

Prioritize profiled operations: repeated checked inference, substituted binder bodies, WHNF and DefEq on shared expression DAGs. Optimization must have an all-input refinement claim where possible, with the entire source result (including errors, fuel, checker state, and local-scope provenance) preserved; never inject arbitrary memo facts as checked types or conversion results.

Measure actual accepted and rejected external corpora: cold/warm CPU, processed declarations, allocation bytes, peak RSS, timeouts and matched original-C0 baseline. A timeout can indicate performance failure, not a false kernel rejection.

## Future self-hosted PSKernel via PSC0 v7.2

This is an architectural target only. No assumption is made that the current PSC0 v7.2 compiler already handles all Lean-native kernel implementation or proof features.

**Portable semantic core:** explicit expression/level/declaration types; finite immutable context and environment; hygienic binder handling; inference, WHNF/DefEq and checked inductive/quotient/declaration admission; deterministically specified error/fuel behavior. These algorithms should not depend semantically on native pointer identity, Lean VM internals, Lake, JSON/NDJSON or GitHub Actions.

**Host-owned acceleration:** persistent arrays, tries, pointer equality, compiler rewrites and proof-carrying memo structures may remain fast native Lean implementations today. Behind each operation retain a portable, source-equivalent reference. Future PSC0 output must re-prove each optimization or use the reference; do not assume v7.2 supports Lean tactics, unsafe FFI or compiler-specific kernel hooks.

**Untrusted import and distribution:** exporters, external data parsers, reproducible downloads, source-index hints and process exit-code bridges remain separate from verified kernel judgments. Missing features produce typed declines, never synthetic admissions.

**Independent bootstrapping:** when implemented in PSC0 v7.2, the compiler-produced kernel cannot be its own sole acceptance oracle. Keep pinned native Lean C0 and at least one official independent checker as validation authorities through fixed-point builds, source/result differential tests and negative-corpus replay.

**Prerequisite feature closure:** audit the actual normative PSC0 v7.2 reference and implemented compiler for dependent universes, ADTs, binder substitution, structural recursion and termination, permitted partial/unsafe, proof types, persistent data structures, numeric semantics, errors and exported ABI. Track unsupported language features explicitly before planning a .lean-to-.ps port.

No self-hosting acceptance can be claimed until compilation is stable, complete source-equivalent verdicts match on independent backends, corpus gates hold and trusted assumptions remain explicit.

## Priority order

1. Finish native Arena 4.35 re-exported soundness and completeness fixtures.
2. Diagnose/accelerate the exact proof-body stall with source and state equivalence.
3. Requalify pinned WF, 499,130-record dependency and full Init; then Std/Mathlib.
4. Expand Arena coverage and formal soundness obligations with honest pass/decline accounting.
5. Only then scope and implement the PSC0 v7.2 portable kernel source.
