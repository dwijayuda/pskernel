# @proofscript/pskernel-core

**0.1.0-checker.10 — private experimental dependent term-checker checkpoint.**

Regenerated with the pinned PSC seed, with all 489 tests passing and fresh build
and reference evidence. See `../../docs/continuity/OWNED_RECORD_ELIMINATION_2026-10-03.md`.

This is the default checker and part of the joint bootstrap source closure.
The host adapter runs the generated semantic machine and fails closed outside
its supported fragment. The exact preserved bootstrap prefix now admits the unit,
`PsSourcePos` and `PsSourceSpan`, after checking the initial `Nat` prelude.
The next entry, `PsLexCursor`, rejects an unknown dependency; the complete batch
now decodes projections and rejects the six-constructor PsTokenKind family at admission 14.
The new portable closure has 76 modules (55 compiler plus 21 owned kernel);
the default selection does not imply release readiness or complete Lean parity.

This package now executes an owned checking fragment, rather than data helpers
alone. It is **not the authoritative PSC2 kernel**, a full Lean-compatible
checker, a jointly self-hosted compiler/kernel, or a published npm release.

The public package export is still only immutable `kernelInfo`. The internal
machines check closed universe-polymorphic terms with dependent function types, typed
lambdas, applications, lets and earlier admitted transparent definitions.
Conversion implements beta, zeta, transparent delta and alpha comparison, with
bounded universe normalization. The generated unit-inductive admission machine
derives a recursor and implements its constructor iota rule. The fragment has
one family, no term parameters or indices, and one constructor with no fields.
The monomorphic zero/successor fragment also derives a dependent recursor and
checks its recursive iota rules. Generated bootstrap starts empty and checks the
fixed Nat declaration through that same admission machine before user declarations.
Natural literals check only after owned Nat-family metadata is validated;
conversion and recursor reduction share the bounded transition budget.
The new record fragment admits one monomorphic Type-valued family with closed,
nonrecursive Type-valued fields. It checks field and constructor types in bounded
source machines and derives a checked dependent eliminator type and field metadata.
Record iota and projection typing/reduction run against validated closed-record metadata. Parameters, indices,
dependent record fields, recursive records, Prop and higher-universe record families
remain rejected. Arithmetic, string literals and other prelude constants remain unsupported.
Sequential internal admission starts from the checked prelude,
rejects forward/self references and duplicates, and returns no environment on a
failed batch. The generated implementation is not edited by hand.

See the current continuity checkpoint and CAPABILITIES.json for supported
judgments and remaining release gates. **CHECKER.md** records the original
checker.0 judgments, tests and repaired defects as historical receipt evidence.
The target architecture remains in ARCHITECTURE.md. FOUNDATION.md and
BINDING_UNIVERSES.md describe earlier checkpoints, not current release readiness.

## Execute the installed development package

The tarball contains the generated JavaScript, canonical PS, TypeScript, source,
tests and pinned evidence. It has no runtime dependencies or installation hooks.

```sh
npm test
npm run verify:build
npm run verify:evidence
npm run release:check  # Expected to FAIL: this is not a release candidate.
```

Rebuilds and optional external reference tests require **explicitly supplied**
executables matching manifests/TOOLCHAIN.json and TypeScript 5.8.3 on PATH:

```sh
PSC1=/absolute/path/to/pinned/psc1 npm run build
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:oracle
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:semantic-oracle
PSC1=/absolute/path/to/pinned/psc1 LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:checker-oracle
LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:level-differential
LEAN_PROVIDER=/absolute/path/to/pinned/provider npm run test:checker-differential
```

The reference provider is test-only. It never supplies the new implementation's
runtime answers. No seed, toolchain or fallback checker is downloaded by these
commands, installation or verification.

Publication, full compatibility and joint self-hosting gates remain closed.
Do not use this checkpoint as a trusted proof-certification boundary.
