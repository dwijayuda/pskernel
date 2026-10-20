# PSC1 current work state — Practical Core control flow and data

Updated 2026-10-20. Branch: `feature/psc1-practical-control-data-20261020`.
Draft [PR #166](https://github.com/dwijayuda/pskernel/pull/166) is stacked on
seven-backend PR #165 at preserved head
`5539059a47c13a3dbc9806a504775b72f7bfd0fe`.
PRs #162, #163 and #165 remain intact; no merge or publication is performed.

## Implemented continuation and observed evidence

The shared procedural AST/controller now implements lexical mutable locals,
assignment, branch continuations, early return, finite List/Array/Nat-range
iteration, contextual pure, tuple/array expressions and optional array lookup.
Selected Id/Except while sites specialize to checked private ordinary helpers
with direct tail recurrence; generic markers never enter runtime graphs.

At source head `88487343a41b9ec79fa4646602a5f4d512de0ce7`,
[Linux run 39378507559](https://github.com/dwijayuda/pskernel/actions/runs/39378507559)
compiled all new code. Existing Do/Data native suites passed. New Nat/Except while
fixtures passed independent ordinary admission, strict IR and private JS expected
result execution, including 10,000 iterations, captures, source-self reference,
sequential loops and while inside a finite for. The all-seven run did not pass:
the regular corpus passed JS/TS, Rust exposed nested-closure lowering and empty-array
annotation failures, and the while divergence fixture exposed an overly narrow
Bool/Unit result-head gate. These are failed-check findings, not qualification.

The current repair keeps known primitive data heads separate from arbitrary opaque
or generic type heads, preserves strict typed let annotations in Rust, and adds
bounded nested closure support for private continuation signatures. Public Rust
signature and named function-storage gates remain. Runtime suites accumulate
per-target failures so one target cannot hide other observations, then fail the
overall check if any record failed.

## Assurance and selected limits

Official Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, remains the authoritative admission
provider. The owned kernel remains separately natively tested. No new admitted
axiom, unchecked loop primitive, runtime fuel or backend certificate is introduced.

Ordinary partial preparation is unchanged: constructive opaque witness plus exact
separately checked body, with immutable graph pairing revalidated before erasure.
Default checked and explicit verified requests refuse partial execution. Execution
tests are not formal backend-preservation proofs.

Finite continuations have linear construction space; optional array lookup scans
the array. While excludes nested procedural loops in its body, CompilerM, unknown
or function-valued computation result heads, and general dependent local-let
captures. All fourteen feature families remain incomplete. Tuple patterns,
throw/try/catch handlers, namespace scopes, Prop-valued ordering with checked
decision evidence and a bounded typed-IO contract remain future work.

## Next required checkpoint

Finish focused Linux qualification for this exact implementation; retain every
source/admission/IR/runtime/publication gate. Then reconcile README, architecture,
runtime/npm notes, the fourteen-family/seven-target status and an immutable exact
qualification receipt. Preserve historical five-target and seven-target receipts;
do not extend their scope retroactively. Full self-host, joint-census, fixed-point,
merge, release and npm registry publication remain excluded.

## Preserved seven-backend checkpoint and history

# PSC1 current work state — seven direct backends and npm

Updated 2026-10-20. Branch: `feature/psc1-seven-backend-architecture-20261020`.
Draft [PR #165](https://github.com/dwijayuda/pskernel/pull/165) is stacked on PR #163
at `ea03ce125ad4d4902070d6fef92d92b51cb2e857`; repair PR #162 stays intact.

## Observed qualification

Implementation head `1f59f46bca18e5eb2d8a6bc9670e6f632202af66` passed
[Linux run 39366310670](https://github.com/dwijayuda/pskernel/actions/runs/39366310670).
The tested merge commit was `951afe99a0c876cfc87b3bb6f192b6688b33b3e9`.
All seven direct targets executed the pinned reference corpus in both source
grammars. New scripting ABI/large-integer/recursion/failure tests, direct IR
boundaries, combined TS/JS publication, preserved source/native/kernel regressions
and native npm/source-library installation all passed.

This is an immutable observed checkpoint. Later heads require their own successful
PR check. The current workflow emits `SEVEN_BACKEND_QUALIFICATION.json` for its
exact tested and branch-head commits and additionally runs the full Python corpus
on both the minimum and current interpreter lines. See
[backend conformance](docs/PSC1_BACKEND_CONFORMANCE.md) and
[the checkpoint receipt](docs/PSC1_SEVEN_BACKENDS_QUALIFICATION_2026-10-20.json).

## Completed architecture

- One native Lean compiler, with JS, TS, Rust, core Wasm, component Wasm, Python and PHP.
- Shared target identity, public capability checks and closed specialization/
  revalidation; Rust retains the checked generic path.
- Structured public visibility before printing; no host stripping of export text.
- Independent direct TS and JS in a single admitted/atomic combined request.
- Selected backend-owned runtime helpers and dependencies, versioned runtime
  contracts, exact artifact hashes and explicit Wasm runtime digest encoding.
- Python `.py`/`.pyi` and PHP `.php`/Composer companions, actual interpreter
  validation before publication, and declaration-start source origins.
- Scalar host ABI guards, unbounded exact integers, raw UTF-8 semantics, lexical
  closures and deep recursion without generated execution fuel.
- Forward nullary values use pure thunks; PHP helper selection respects shadowing.
- Unpublished native npm tarball with all built-in targets and locked host tools.
- Importer-aware portable npm source libraries re-enter captured independent
  admission; actual two-library canary executes `answer = 42`.

## Preserved authority and scope

Official Lean **4.35.0**, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, remains authoritative for admission.
No admission policy or logical/runtime pairing shortcut was introduced. Raw IR
wrappers and npm manifests confer no logical authority. The owned PSKernel-Core
continues to compile and run its native regressions separately.

`--assurance ordinary` retains the qualified explicit partial-function path.
`--assurance verified` refuses because backend behavioral certificates are
unavailable. Execution tests do not constitute backend-preservation proofs.

All work and validation use GitHub and Linux cloud CI. No local repository build,
full self-host/census/fixed-point run, unrelated branch update, force push, merge,
release or npm publication was performed.

## Remaining boundaries

The compiler supports the retained subset and qualified Practical Core slice, not
all fourteen feature families or unrestricted Lean. Int division/modulo,
fixed-width/floating runtime scalars, general Python/PHP public aggregate ABIs and
non-Bool component exports remain unqualified. Python/PHP source origins cover
declaration starts. PHP tail recursion retains heap frames; nullary thunks can
repeat work. The initial npm binary package is Linux x64/glibc only.

Future source-language expansion, runtime adapters, additional platforms, formal
behavioral certificates and full self-host qualification require separate work.
Current commands, ABI/runtime details and installation are documented in
[README](README.md), [architecture](ARCHITECTURE.md),
[runtime semantics](docs/PSC1_RUNTIME_SEMANTICS.md) and
[the npm guide](docs/PSC1_NPM_ECOSYSTEM.md). Historical current-state documents and
the previous README/architecture/npm state remain preserved under `docs/history/`.
