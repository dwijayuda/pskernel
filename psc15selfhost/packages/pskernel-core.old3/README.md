# @proofscript/pskernel-core.old3

This is the preserved experimental predecessor. The canonical portable kernel
now lives in [../pskernel-core](../pskernel-core/README.md). Active callers use
the explicit `pskernel-core.old3` selector; historical manifests and generated
evidence retain their original identity and bytes. The default provider remains
`lean434-wasm`.

**0.1.0-checker.14 — private experimental dependent term-checker checkpoint.**

Regenerated with the pinned PSC seed, with all 651 tests passing and fresh build
and reference evidence. See `../../docs/continuity/OWNED_UNIFORM_ALGEBRAIC_2026-10-03.md`.

This checker is preserved as an explicit private experimental alternative. It is no
longer the default checker and is no longer part of the compiler bootstrap source
closure. The host adapter runs the generated semantic machine and fails closed outside
its supported fragment. Historical owned-prefix evidence admits the unit,
`PsSourcePos` and `PsSourceSpan`, after checking the initial `Nat` prelude.
The next entry, `PsLexCursor`, rejects an unknown dependency; the preserved complete
batch decodes all 1,714 entries and rejects semantically at PsLexCursor (index 3).
The former joint closure had 91 modules (55 compiler plus 36 owned kernel); the
current compiler-only bootstrap deliberately excludes those 36 kernel modules.

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
Record iota and projection typing/reduction run against validated closed-record metadata.
Parameterized projections, dependent/indexed fields and Prop/higher-universe record families
remain outside this fragment. String literals are validated against a fixed intrinsic String type; String operations,
arithmetic and other missing prelude constants remain unsupported. See PRIMITIVE_POLICY.md.
Nullary enumerations derive checked dependent recursors and computed branch reduction.
Closed nonrecursive payload sums are checked. The uniform algebraic route additionally checks
Type0 type parameters and direct recursion, derives dependent eliminators and computes
recursive hypotheses. Nested, indexed, mutual and universe-polymorphic families remain
unsupported. See ALGEBRAIC.md for the production routing boundary and the separately
recorded native reference scope discrepancy.
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
