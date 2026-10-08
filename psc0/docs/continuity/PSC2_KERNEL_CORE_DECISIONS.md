# PSC2 Kernel-Core Decisions

Status date: 2026-09-27
Branch: `psc2/minimal-selfhost-psc15`

This file records architectural decisions made while implementing the minimal self-host kernel. Future work should preserve these unless repository evidence justifies a deliberate revision.

## D1 — Build the smallest self-host kernel first

Do not attempt to implement all PSC2 language/compiler features in the trusted kernel at once.

The kernel should contain only semantics required to validate trusted terms/declarations. Everything else should live above it where possible.

Rationale:

- smaller trusted computing base,
- easier differential testing,
- easier self-host fixed point,
- less coupling to TypeScript/Rust/Wasm backend concerns,
- easier future formal reasoning.

## D2 — PSC1 subset is a compiler-enforced contract

Kernel source is authored as `.lean`, but the allowed source language is the PSC1-compatible subset actually accepted by the PSC1 compiler.

Lean acceptance alone is insufficient.

If a construct passes Lean but fails `psc1 check`, rewrite the trusted source rather than weakening the self-host gate, unless the construct is intentionally added to PSC1 with its own tests and semantics.

## D3 — Keep current bootstrap compiler and new kernel separated

`@proofscript/pskernel-core` is `bootstrap: false` during the current build-out.

The current compiler bootstrap closure must remain independent of the new kernel until the planned cutover/self-host stage. This prevents circular dependency and lets the mature compiler serve as the bootstrap tool that builds its successor kernel.

## D4 — Trusted kernel must be total/admission-ready

Avoid `partial def` in trusted kernel code.

The current PSC1 checked-admission bridge intentionally rejects unsupported declaration forms such as partial declarations. A self-host kernel that only parses but cannot enter checked admissions is not sufficient.

When general recursion is convenient, prefer one of:

- direct structural recursion,
- a structurally recursive helper over an explicit spine,
- an explicit fuel argument justified by a structural size bound.

Do not add `unsafe` or host runtime escapes to bypass this.

## D5 — Prefer single-scrutinee, explicit PSC1-native control flow

The current trusted source style should prefer:

- one `match` scrutinee at a time,
- explicit constructor names,
- nested `if` rather than convenience boolean syntax when needed,
- simple first-order helpers,
- structurally obvious recursive arguments.

Avoid relying on Lean syntax sugar not supported by the PSC1 parser/elaborator.

## D6 — Kernel-local data structures stay minimal

`PsKernelCoreList` and `PsKernelCoreOption` exist only to make the trusted closure self-contained and structurally matchable by PSC1.

They should remain tiny semantic support types, not become a duplicate general-purpose standard library.

If richer collection behavior is needed outside trusted semantics, put it in libraries.

## D7 — New core reuses semantics, not implementation bulk

The mature `PSC1Kernel` package is the semantic reference/differential oracle, not a file-copy target.

Port only behavior required for the minimal kernel. Keep reference-only machinery out of the trusted core unless a kernel rule truly needs it.

Examples of things to keep outside unless required:

- rendering/debug formatting,
- replay infrastructure,
- compatibility reporting,
- benchmark helpers,
- external trace formats,
- target/backend code,
- CLI concerns.

## D8 — Differential parity is incremental evidence

Every foundational semantic slice should be introduced RED -> GREEN:

1. write a test against the intended public behavior/reference,
2. observe the intended failure,
3. implement the smallest production change,
4. make parity green,
5. make PSC1 self-host/source gate green,
6. only then move upward.

Parity does not imply complete Lean 4 equivalence. Claims must stay scoped to tested behavior.

## D9 — Keep foundational names aligned with Lean/ProofScript policy

Do not casually rename foundational semantic concepts for stylistic reasons. The wider project preserves Lean-compatible foundational vocabulary such as `Nat`, `Int`, fixed-width integers, `USize`, floats, `Bool`, `Char`, `String`, and `Unit`.

Kernel representation names may be package-prefixed to avoid collisions, but their semantics should remain deliberately mapped.

## D10 — Shared semantics must remain target-neutral

Nothing in `pskernel-core` should become TypeScript-, Rust-, Wasm-, PHP-, Python-, or Java-shaped.

Backends consume target-neutral compiler/kernel semantics through later IR/capability layers. Backend convenience must not leak downward into trusted semantics.

## D11 — Self-host completion requires stronger future gates

The current source gate is necessary but not the final self-host proof.

Future milestones should include, in order:

- PSC1 compiler accepts the complete trusted kernel source,
- compiler can emit executable backend code for it where required,
- generated kernel can validate the required corpus,
- successor compiler/kernel can rebuild the next generation,
- fixed-point/source equivalence evidence is recorded,
- regression/differential corpus remains green.

Do not call PSC2 fully self-hosted before those fixed-point stages exist.
