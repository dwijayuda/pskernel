# Foundation checkpoint — 2026-10-02

Status: implemented and executed data/structural foundation. **Not a proof checker.**
Package: `@proofscript/pskernel-core@0.1.0-foundation.0` (private).
The old `pskernel-core.old` source, compiler defaults, and bootstrap closure are unchanged.

## Implemented

`src/Ps/Kernel/Data.lean` owns canonical binary positive/natural data, raw text
byte sequences, hierarchical names, closed universe syntax (`zero`, `succ`, `max`,
`imax`, and parameters), a work list, finite fuel, and a three-way result.
`src/Ps/Kernel/Structural.lean` implements one fuel-bounded work-list comparator.
Numeric identifiers are not converted to floating-point numbers. Structural equality
preserves name segments, distinguishes text/numeric names and universe constructors,
and shares a single fuel budget across all scheduled children, bytes and numeral bits.

The semantic modules import no Lean/Std implementation, compiler service, old kernel,
KernelOne, IO or runtime evaluator. Their generated JavaScript is produced by the
actual pinned PSC compiler; it is not a handwritten replacement or patched output.

## Tested evidence

- Both flattened `.lean` and generated canonical `.ps` pass the PSC frontend.
- Both inputs emit byte-identical TypeScript; TypeScript 5.8.3 checks it with strict
  checking and `noEmitOnError`, and generates executable ESM plus declarations.
- 73 Node tests pass with no skips: 47 named fixtures, symmetry and larger-fuel checks,
  256 small-natural pairs, total work-budget checks, source-profile escape tests,
  source identity, symlink rejection, package identity and absence of checking authority.
- The pinned Lean-backed provider checks 47 concrete computation theorems about the
  same fixture results, and rejects one deliberately false theorem. The fixture
  adapter admits an ordinary indexed equality family, not an extra axiom.
- The oracle initially could not reduce PSC's opaque String.Internal helpers. The
  final implementation does not use those helpers: it compares owned byte sequences.

These are bounded implementation tests and ground computation checks, not a proof
of general correctness, full Lean equivalence, or self-hosting. The oracle validates
PSC-emitted Core on its own pinned prelude, not a separate native Lean frontend parse
of the original source. Full Lean source and imported-library replay remain pending.

## Explicit limitations

There is no term type checker, universe normalization/equivalence, conversion,
inductive admission engine, quotient checker, parser/decoder, CheckedModule, proof
admission API or compiler-authority promotion. `max 0 u` and `u` intentionally compare
as structurally different here; this result must never substitute for conversion.

Text is raw internal UTF-8 byte data represented with owned naturals. Future ingress
must validate byte range, UTF-8, bounds and ownership; the current structural operation
does not validate any of them. Test adapters only construct well-formed values.
Generated ADTs are internal mutable JavaScript objects, not yet trusted immutable
handles. The package root does not expose these experimental internals.

Fuel bounds comparison tasks, not wall time or allocations. The generated fuel worker
eagerly builds a closure chain and uses the host stack. This is not the final resource
safety implementation and should not receive hostile objects. There is no public
checking entry point through which such input can be admitted.

The seed has limitations in built-in Nat recursion and in some direct applications
of function-returning workers. This foundation uses an owned finite fuel datatype and
tests the curried worker directly. No compiler or generated-output patch is hidden.

## Reproduction

`manifests/TOOLCHAIN.json` identifies the exact PSC seed and test-only native oracle
executables from GitHub Actions artifact 11198192443, source commit c680b2016ff8e23bdae2bc102128b1308fb5a324.
The complete historical workflow failed elsewhere; that is not a passing integration
claim. Downloading the artifact is a separate explicit action; build scripts do not
fetch binaries. The recorded artifact expires on 2026-10-08, so a durable approved
seed distribution/rebuild procedure remains a release requirement.

```sh
PSC1=/absolute/path/to/pinned/psc1 npm run build
npm test
PSC1=/absolute/path/to/pinned/psc1 \
  LEAN_PROVIDER=/absolute/path/to/pinned/psc2_lean_kernel_provider npm run test:oracle
npm run verify:build
npm pack
```

TypeScript 5.8.3 must be on PATH, or supplied through `TSC`. Seed digests are checked;
unrecognized binaries fail closed. Builds preserve source/PS parity and generated
output hashes in BUILD.json. ORACLE.json records the actual external verdicts and
request digests. The source manifest must be explicitly reviewed and updated when
semantic source changes; a build never silently blesses an edited source hash.

Normal tarball installation needs neither seed nor Lean. The packed generated
files permit installed-consumer tests to run without a build; source checkouts must
run the pinned build first. Generated dist files are intentionally not Git sources. No npm publication or namespace reservation
is performed. `npm test` on this checkpoint is not the full repository/Lake test suite.

## Next semantic gate

Implement owned expression/binding operations and universe normalization against the
pinned rules, preserving resource-exhaustion distinctions. Then add typing/conversion
and transactional admission. The root checking API stays unavailable until the
relevant admission and rejection tests exist.
