> Historical checkpoint. See CHECKER.md and current manifests/EVIDENCE.json for
> the current implementation, repaired reproduction defects and limitations.

# Binding and universe checkpoint — 2026-10-02

**Status: executed internal foundation, not a proof checker or release candidate.**
Version: `@proofscript/pskernel-core@0.1.0-foundation.1` (private).
Based on repository commit `12b6c0f9d63b606eae893e759093b9ab9e008b68`.

## Implemented in this continuation

Eight owned semantic modules now implement Data, Structural, Natural, Expr,
Binding, Order, Universe and LevelCheck. The six new modules are portable source,
compiled by the pinned PSC seed to canonical PS and TypeScript. Generated semantic
code is not patched or independently hand-written.

Natural implements exact binary successor/predecessor plus small-step addition
and ordering. Expr includes bound/internal free variables, sorts, universe-
instantiated constants, application, lambdas, dependent function types, lets,
literals and projections. Binding implements lifting, single instantiation with
capture avoidance, free-variable abstraction, and relative variable-scope checks.
Abstraction preserves pre-existing bound variables, as Lean's abstraction does.
Scope checking is NOT typing or checking universe parameters, literals or axioms.

Universe implements a first-order normalization machine including successor
max-distribution, max-leaf ordering/deduplication/offset dominance, explicit-level
subsumption and imax smart construction. LevelCheck shares a single driver budget
across two normalizations and final structural comparison. A negative algorithmic
comparison is not a proof of mathematical universe inequivalence.

The custom structural ordering is not Lean's public name/hash ordering. Direct
native probes provide bounded evidence, not an all-input equivalence theorem.
The normalization implementation's organization differs from native flattening in
some raw nested-max cases; broader adversarial differential coverage is still needed.
Raw imax normalization is not universally idempotent: normalizing `succ (imax v
(succ u))` can expose a max which a second invocation treats differently. Tests do
not silently strengthen the algorithm into a complete universe decision procedure.

## Executed evidence

- Both source forms pass PSC with 226 reported declarations and identical TypeScript.
- Strict TypeScript 5.8.3 produces executable ESM and declarations.
- The test suite includes 46 binding fixtures, 35 normalization fixtures, 1,000
  generated-expression transformations against an independent recursive BigInt
  specification, 4,096 small-natural pairs, 512 carry/borrow boundaries, 128
  generated 256-bit pairs, 500 random universe trees under 25 assignments each,
  structural-order properties, shared-budget checks and package/source guards.
- The old 47 ground computation theorems still pass the pinned external Lean
  provider, and its false control is rejected.
- The new semantic oracle checks 88 ground computation theorems and rejects
  three wrong controls: captured substitution, wrong imax-zero reduction, and
  floating-point-style rounding of an exact natural sum.
- Direct serialized declarations compare 671 universe-equality outcomes with
  the actual pinned Lean provider. All 671 match on this bounded fixture set.
- The release gate rejects this checkpoint. Editing metadata flags alone does
  not manufacture the missing checker API or completed release evidence.

The final test count, digests and reproduction results are in EVIDENCE.json.
Ground theorem checking is performed by the EXTERNAL reference provider, not by
this new implementation. A reference check of a computation is not a general
correctness proof and does not establish compiler/backend soundness.

## Compiler limitation handled without generated-code edits

The seed mishandles some calls to function-returning recursive workers. Boxing
such functions also exposes a canonical-PS function-type parser limitation. The
new algorithms use explicit first-order state machines and a small fuel runner.
The recursive runner is created lazily only after a transition, avoiding the
old eager construction of a closure chain for the complete supplied fuel value.
The host may step the generated machine iteratively; the host loop is not a
hand-written implementation of the semantic transitions.

## Remaining limitations and release blockers

There is no full term checker, definitional conversion engine, inductive/recursor
admission, quotient checker, validated primitive/prelude admission, axiom policy,
canonical hostile-input decoder or CheckedModule. Compiler integration, complete
compiler/kernel dependency replay, a generated-kernel fixed point and promised
Lean library replay remain incomplete. The public API remains metadata-only.

Internal raw text needs UTF-8 and byte-range checks; generated objects are mutable
and not validated handles. Budgets count state-machine transitions, not every
allocation, helper recursion, input byte or host stack frame. Offset stripping and
successor/predecessor helpers are not individually fuel-metered. This is not a
complete hostile-input resource boundary. No unchecked public admission exists.

The historical compiler/oracle artifact expires 2026-10-08, and its complete
workflow failed elsewhere. A durable approved seed distribution/rebuild and
full workspace/Lean CI remain required. No seed is auto-downloaded at build,
installation or verification time. Neither the archive of the old kernel nor
compiler defaults are modified by this package-only continuation.

Public release is also blocked by unresolved license/provenance and missing npm
authentication in this session. Current GitHub connector actions provide reads
but no repository mutation action, and no usable authenticated GitHub CLI path
was available. The accompanying patch contains the continuation; it has not
been pushed or merged. Do not confuse this local package with a registry release.

## Reproduction

Use the exact seed/oracle executable hashes in TOOLCHAIN.json. With those locally
provided executables and TypeScript 5.8.3 on PATH:

```sh
PSC1=/absolute/path/to/psc1 npm run build
npm test
PSC1=/absolute/path/to/psc1 LEAN_PROVIDER=/absolute/path/to/provider npm run test:oracle
PSC1=/absolute/path/to/psc1 LEAN_PROVIDER=/absolute/path/to/provider npm run test:semantic-oracle
LEAN_PROVIDER=/absolute/path/to/provider npm run test:level-differential
npm run verify:build
npm run release:check  # MUST fail for this incomplete checkpoint
npm pack
```

The local tarball includes generated output, enabling installed-consumer tests
without Lean or PSC. It is an experimental development artifact, not a trusted
proof-checker release. `prepublishOnly` runs the explicit release gate; the package
also remains private. The gate is a process safeguard, not a soundness proof.
