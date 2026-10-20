# PSC1 typed-error continuation — implementation awaiting CI

Branch: `feature/psc1-typed-errors-20261020`. Base: qualified PR #166 head
`1e63628169459539783450e28c641f3f70bf701f` (Linux run 39408221046).
Existing PRs #162/#163/#165/#166 remain intact. No merge or publication.

New source work: contextual typed throw and a single try/catch inside do.
Both frontends share one AST and handler elaborator. The handler returns
checked `Except ReturnValue MutableState` packets inside the base effect;
only the base error is caught, and the following continuation runs outside
that catch. Catch arms start from pre-try lexical mutable values. Existing
checked CompilerM catch additionally restarts from its original effect state.
Local/global bindings named throw keep precedence. No host exceptions,
runtime traps, admission failures, timeouts or compiler resource errors
become caught source values.

Qualification is pending: native admission/IR/roundtrip/scope tests,
exact-source pinned Lean oracle, checked and ordinary loops on all seven
targets, minimum Python and failure/publication boundaries are wired into
scoped Linux CI. No full self-host/census/fixed-point tests. `verified`
remains fail-closed. No added axiom, runtime fuel or backend certificate.

Read `docs/PSC1_TYPED_ERRORS.md`. Do not claim this new slice qualified
until its own exact-head focused CI succeeds. Prior receipts below retain
their original scope. All fourteen complete flags remain false.

---

# PSC1 current work state — Practical Core control flow and data

Updated 2026-10-20. Branch: `feature/psc1-practical-control-data-20261020`.
Draft [PR #166](https://github.com/dwijayuda/pskernel/pull/166) is stacked on
seven-backend PR #165 at preserved head
`5539059a47c13a3dbc9806a504775b72f7bfd0fe`.
PRs #162, #163 and #165 remain intact; no merge or publication was performed.

## Qualified implementation checkpoint

Implementation head `8d6f80ea5813edd0644440971095abffd9dddacd` passed all 34 steps in
[focused Linux run 39407097682](https://github.com/dwijayuda/pskernel/actions/runs/39407097682). The workflow tested
GitHub merge commit `164fb133a8da410140cc3a84dcd51382c4a230a6` against preserved PR #165.

The [immutable qualification receipt](docs/PSC1_PRACTICAL_CORE_CONTROL_DATA_QUALIFICATION_2026-10-20.json)
records the exact compiler/tool identities, observed checks and package hashes.
[Retained evidence archive](https://github.com/dwijayuda/pskernel/actions/runs/39407097682/artifacts/12257218795): 38,733,488 bytes,
SHA-256 `2b59e2401d4d68149360e5bce8ac91a371d904bfec715141705c8c85bd6edd98`.
This is a scoped execution checkpoint; later heads require their own successful
focused check. All fourteen feature families remain incomplete.

The shared procedural AST/controller implements lexical mutable locals,
assignment, branch continuations, early return, finite List/Array/Nat-range
iteration, contextual pure, tuple/array expressions and optional array lookup.
Selected Id/Except while sites specialize to checked private ordinary helpers
with direct tail recurrence; generic markers never enter runtime graphs.

The focused Linux evidence covers 101 Do, 71 Data and 27 While native outcomes;
14 regular target/source bundles; 14 ordinary finite-while bundles with eight
loop predicates; 14 external divergence deadlines; and 16 while refusals.
The authentic pinned native-Lean oracle has 78 fields: 76 result observations
and two toolchain identity fields. Two additional Rust
private-closure records check reused captures and preserve the public nested
function-signature refusal. Minimum Python repeats both grammars.

Wasm computed calls now derive the complete closed callee type with the bounded
strict IR checker before typed closure lowering. PHP direct self-tail calls reuse
their declaration frame with argument snapshots and lexical-shadow checks; non-tail
calls retain scheduler continuations. Rust keeps typed local lets and supports the
needed private direct nested closures. The public component Bool-only and scripting
aggregate boundaries remain.

The scripting suite retains 24 bundles plus four boundary records; minimum Python
retains 12 bundles plus two boundary records. Tiny interpreter cases distinguish
simultaneous parameter updates, stable closure captures and shadowed self names.
The focused backend suite has 26 groups. The installed two-package npm canary now
uses checked Id mutation/branch/early return and still returns 42 through a
four-source independently admitted import closure.

## Assurance and selected limits

Official Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, remains the authoritative admission
provider. The owned kernel remains separately natively tested. No new admitted
axiom, unchecked loop primitive, runtime fuel or backend certificate is introduced.

Ordinary partial preparation is unchanged: constructive opaque witness plus exact
separately checked body, with immutable graph pairing revalidated before erasure.
Default checked and explicit verified requests refuse partial execution and
preserve previously published artifacts. Execution tests are not formal backend
preservation proofs.

Finite continuations have linear construction space; optional array lookup scans
the array. While excludes nested procedural loops in its body, CompilerM, unknown
or function heads of the complete computation type, and general dependent local-let
captures. All fourteen feature families remain incomplete. Tuple patterns,
throw/try/catch handlers, namespace scopes, Prop-valued ordering with checked
decision evidence and a bounded typed-IO contract remain future work.

## Resume from here

Read `docs/PSC1_PRACTICAL_CORE_CONTROL_DATA.md`, the machine-readable
`docs/PSC1_PRACTICAL_CORE_STATUS.json`, and the new immutable qualification
receipt before making a broader claim. Each later branch head needs its own
successful focused check. Historical five-target and seven-target receipts keep
their original scope.

Future source work should choose one explicitly missing family boundary and carry
it through parser, typed elaboration, independent admission, strict IR, both
grammars and all affected target consumers. Typed IO requires console line
input/output plus bounded UTF-8 file read/write, with root/path, EOF/newline,
size/error and publication refusal contracts. Stdout alone is insufficient.

Full self-host, joint-census, fixed-point, merge, release and npm registry
publication remain excluded from this continuation.

## Preserved seven-backend checkpoint and history

### Historical PSC1 work state — seven direct backends and npm

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
declaration starts. At that checkpoint, PHP tail recursion retained heap frames; nullary thunks can
repeat work. The initial npm binary package is Linux x64/glibc only.

Future source-language expansion, runtime adapters, additional platforms, formal
behavioral certificates and full self-host qualification require separate work.
Current commands, ABI/runtime details and installation are documented in
[README](README.md), [architecture](ARCHITECTURE.md),
[runtime semantics](docs/PSC1_RUNTIME_SEMANTICS.md) and
[the npm guide](docs/PSC1_NPM_ECOSYSTEM.md). Historical current-state documents and
the previous README/architecture/npm state remain preserved under `docs/history/`.
