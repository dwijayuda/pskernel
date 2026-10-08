# PSCVL — Lean-powered experimental PSCV frontend

**Status: narrow implementation prototype, NOT a PSCV-certified compiler.**

PSCVL is an independent Lean-written implementation lane on the `main` branch.
It delegates parsing of Lean-compatible source, macro expansion, elaboration,
dependent type checking and kernel checking to **official Lean 4.35.0-rc3**.
It does not copy/replace `pscv0`, `psc15selfhost`, `pskernel-lean`,
`pskernel-lean-wasm`, or any PSKernel checker.

## Normative basis

- [PSCV verified language reference](../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md):
  §§2, 8–9, 21, 28–30, 32 and appendices A/F/I.
- [PSCV V6 compiler reference](../pscv0/THE_PSCV_COMPILER_REFERENCE_VERSION_6.md).
- [Language authority lock](../pscv0/language-authority.json)
  (`ps-0.9-r3`, `pscv-v1`, `pscv-closed-v1`, `PSCV-VERIFY-v1`,
  `PSCV-CERT-v1`, official Lean 4.35.0-rc3 reference pin).

**Important architecture difference:** PSCVL deliberately uses the Lean
frontend *at build/check time*, whereas V6 proposes a standalone native PSCV
frontend. This is an experimental, separate shortcut to explore development
cost and reuse—not a silent revision of the V6 architectural contract.

## Build and check

Requires `elan` / `lake` and the pinned Lean toolchain. From `PSCVL/`:

```sh
lake build
lake exe pscvl check examples/pass.ps
```

Negative examples must fail:

```sh
! lake exe pscvl check examples/fail_unsafe.ps
! lake exe pscvl check examples/fail_partial.ps
! lake exe pscvl check examples/fail_axiom.ps
! lake exe pscvl check examples/fail_sorry.ps
! lake exe pscvl check examples/fail_missing_spec.ps
```

The check works in-process with `Lean.Elab.process`: Lean does the
real parsing/elaboration, and a mandatory, driver-injected `#pscv_gate`
inspects local elaborated constant information and transitive axioms of
marked executable roots. It does **not** emit binaries, Lean objects, or
`PSCV-CERT-v1` certificates.

## Current source contract

- File extension `.ps`. The Lean-compatible `def`, `theorem`, `example`
  and core term syntax is accepted through the official Lean frontend.
- Demonstration ProofScript aliases: `const name : T := expr`;
  `function name(x : T) : U := expr`;
  `function name(x : T, y : U) : V := expr`. These are limited syntax macros
  that lower to ordinary Lean `def`, not independent elaboration/type rules.
- At least one executable `def` must be tagged
  `@[pscv_export, pscv_type_spec]`. The tags signal a *candidate* approved
  specification; they do **not** authenticate an externally approved spec.
- New local `axiom`, `unsafe`, and `partial` declarations reject.
  Exported roots also reject transitive axioms outside `propext`,
  `Quot.sound` and `Classical.choice`; this is a preliminary conservative
  policy, not a complete trusted-closure audit.
- Source `import` lines are blocked as a basic v0 usability restriction.
  This is **not a malicious-input sandbox** or a complete grammar restriction.

## Not yet implemented — critical boundary

**A green check proves neither behavioral correctness nor PSCV conformance.**
PSCVL has no closed PSCV grammar validation, import/dependency manifest,
approved-spec digest, executable reachability graph, comprehensive effect
discipline, VC generation, module-by-module proof coverage, authoritative
assumption policy, semantic backend correspondence, checked erasure,
certification, or executable emission. Because Lean elaborators/macros run
programs, `check` is for *trusted source only*. Untrusted npm extensions
are not admitted or isolated.

In particular, source definitions may typecheck successfully while lacking
their intended behavioral specification. The simple type-spec tag cannot
be substituted for the approved specification identity required by
[§30](../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md#30-program-validation-and-verified-compilation).

## Next architecture milestones

1. Pre-elaboration closed grammar validation using Lean's syntax tree, not
   raw keyword filtering; exact support/rejection matrix from appendix I.
2. Full ProofScript binder/call/body syntax and verified contracts,
   `requires`/`ensures`, VC generation and proof-only constructs.
3. Immutable approved specification identity and explicit export/dependency
   closure; separately test proof closure and coverage.
4. Trusted extension capability firewall; input isolation.
5. Only after all certification conditions hold: native Lean code generation
   / artifact emission with honest `PSCV-CERT-v1` claims.
6. Evaluate retained frontend-via-Lean versus V6 standalone compilation on
   actual size, reliability, performance and distribution measurements.

The prototype deliberately avoids duplicating a parser, elaborator, kernel
or maintaining transitional self-host source just for historical continuity.
