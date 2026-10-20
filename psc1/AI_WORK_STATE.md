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
