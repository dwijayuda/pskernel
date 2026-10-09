# PSC0 SH/1 implementation and qualification

Status: bounded runtime IR typing M6 is compiler-qualified with independent
selected-provider acceptance in both its TypeScript 5 baseline and the current
TypeScript 7.0.2 integration. The exact qualifying source checkpoints are:

| Checkpoint | Source | Qualification |
| --- | --- | --- |
| M6, TypeScript 5.8.3 baseline | `1b5fd12382c920944924c9d03e0851984293caa2` | [Run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597) |
| M6 with current TypeScript 7.0.2 | `99786185f77edf952f11989d4c9bc44028f22f11` | [Run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506) |
| R2, new-only PS grammar and parameter projections | `fe2560aba0f347b1caf8d000d371464642d44f23` | [Run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635): compiler/provider/cold recovery passed; exact R successor explicitly selected |

The portable M6 source is the same in both checkpoints. The TypeScript integration
changes current host/CLI selection and qualification tooling; historical S0/A
recovery remains pinned to 5.8.3. Current seed identity is authenticated by
`selfhost-seed.json` and its receipts; the F candidate requires a qualified,
recoverable, explicitly selected projection-capable R successor.
The earlier qualified integration branch is `psc0/sh1-implementation-v1`;
its documentation descendants preserve the exact qualifying source references
above. R2 has earned its own compiler/provider results and verified cold source
recovery. The exact R successor is explicitly selected by [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6).
F is an **implemented candidate with qualification pending** and does not inherit
R2's compiler/provider results.

The installed checker verifies its bounded runtime type contract before emitting
the same IR. Strict SH/1 remains false because the remaining primitive/value,
bounds/text-position and lowering correspondence contracts are separate.
No named PSC1 profile or new seed is selected by these qualifications.

This document supplements [SPEC.md](SPEC.md). Exact receipts and historical
A/B/H/E records are indexed in [qualification-evidence.json](qualification-evidence.json).
[TYPESCRIPT7.md](TYPESCRIPT7.md) records the exact compiler profiles, recovery
proof and measured TypeScript phase.

## Current new-only source grammar checkpoint

The current `.ps` parser, printer, active fixtures and host source identity move
together to edition `ps-0.9-r3`, mode `new-only`, support
`bounded-selfhost-subset`. [PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md)
records the exact supplied reference SHA-256, finite enabled grammar and
unsupported forms. R2 has its own completed compiler/provider, cold-recovery and
explicit selection records below. The F candidate must use that authenticated
selected R compiler and satisfy its own source/runtime qualification.
Full Standard/PSCV conformance and strict SH/1 remain unearned, and Lean remains
4.34.0.

The implementation paths are:

| Path/API | Responsibility |
| --- | --- |
| `Ps/Syntax/Lexer.lean`, `psLexProofScript` | `.ps`-specific whitespace/BOM/CRLF policy with original UTF-8 byte offsets; the separate Lean lexer route is preserved |
| `Ps/Syntax/ParseProofScript.lean` | Newline sequences, typed declaration/constructor comma groups, typed lambda groups, distinct adjacent/native calls, and explicit refusal of unsupported syntax |
| `Ps/Syntax/PrintProofScript.lean` | One current canonical grammar; preserve binder order and call nesting; refuse a binder order it cannot express |
| `Ps/Elab/Term.lean` | Refuse unsupported explicit empty-call completion with `emptyCallUnsupported`; `f(())` remains an ordinary Unit argument |
| `scripts/sh1-grammar-conformance.mjs` | Synchronous generated-compiler API observations and a separate full captured-closure canonical round trip |

For example, the current generated spelling of the qualified recursion form is:

```text
def reverseInto {alpha : Type}(items : List alpha, out : List alpha) : List alpha :=
  match items with {
    | List.nil => out
    | List.cons item tail => reverseInto tail (List.cons item out)
  }
```

Typed callbacks can be grouped directly in `.ps`, such as
`use((fun (x : Nat) => x))`. Commands, local let sequences and structure fields
use newlines; record values and adjacent argument groups use commas. Annotated
parameterless `const` and positive-arity `function` aliases canonicalize to
`def`. Current `.ps` has no legacy parser mode. General `do`, omitted required
annotations, defaults, named arguments and tuples are explicitly outside the
subset. `f()` preserves an empty argument list through parsing and printing and
is refused during elaboration; it is never rewritten to `f(())` or erased from
`f() x`.

The small API gate runs for N1/C1/C2/C3. It checks independently authored
application trees, supported PS-to-PS printer round trips, nearest unsupported
forms, exact lexical positions and empty-call elaboration refusals. The separate
N1 closure function reuses the captured raw source manifest and compares every
module's canonical Lean text with Lean-to-new-PS-to-Lean translation, then checks
PS idempotence. Its canonical surface artifact digest binds the same already
translated strings to the C2/C3 product comparison; the full closure is not
reparsed at every stage. Raw-source execution, checked original IR, C2/C3 product
equality and separate exact-stream provider acceptance retain their own gates.

Handwritten compiler `.lean` remains authoritative. R is implemented in forms
that A can consume for immutable recovery. F's required R successor has verified
recovery and explicit selection; F itself remains unqualified. F removes
only the three scoped aliases described below. Historical S0/A source, canonical
products and recovery toolchains retain their immutable identities; current
products carry the new grammar identity.

### R2 compiler and provider evidence

The exact R2 source is `fe2560aba0f347b1caf8d000d371464642d44f23`.
[compiler job 113804052074](https://github.com/dwijayuda/pskernel/actions/runs/37925722635/job/113804052074) in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635) passed the current-source
qualification. This result is separate from the historical TS5/TS7 M6 receipts.

| Observation | R2 result |
| --- | --- |
| Raw authoritative source closure | 61 modules; SHA-256 `f96c811f575cae2be58ccca3ffe587ead83bffa6f8bd862d40936bef28ef3226` |
| Current fixed point | All four declared C2/C3 products agree: canonical source, admissions, TypeScript and JavaScript |
| N1 canonical correspondence | All 61 captured modules passed Lean-to-new-PS-to-Lean correspondence and PS idempotence |
| Native original-IR check | 56,391 expressions; 725,484 steps; zero findings |
| Independent provider | [provider job 113827136830](https://github.com/dwijayuda/pskernel/actions/runs/37925722635/job/113827136830) accepted four distinct exact streams covering eight roles; provider implementation unchanged |
| Cold source recovery | Passed in job `113827137018`; [receipt](grammar-migration-cold-recovery.json), SHA-256 `2aa93517b848da1493386ab9be50527275fe1a7a1c7e12f422d8d8431d8d9f1d` |
| Explicit successor selection | [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6); selected manifest SHA-256 `7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694`; seed identity `47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225` |
| F source/runtime qualification | Pending; F is a separate implementation candidate |

The retained [qualification file](seed-evidence/fe2560aba0f347b1caf8d000d371464642d44f23/qualification.json)
has SHA-256 `b3e9a277a7ce5ee9e0bccc449c9ca20a06766cd94cabd34fe4d722c6425e6fac`; the independent
[provider receipt](grammar-migration-provider.json) has SHA-256
`1736aa0c1b3fdd5d59b4c2653c053261e3ada36ea82b68d6b88400e17fc1ab77`. Cold recovery and explicit selection have the
separate records above. The selected compiler SHA-256 is
`70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061`. These records establish the bounded,
recoverable selected R checkpoint. F qualification, strict SH/1 and full PSCV
remain separate.

## F checkpoint: ordinary worker parameters

Status: **implemented candidate; qualification pending**. F applies the frozen
practical-v1 scope using the now-qualified, cold-recovered and explicitly selected
projection-capable R seed. It changes twelve worker definitions and removes three
typed projection aliases; it does not extend the accepted language or alter the
new-only `.ps` grammar.

| Family | Workers | Required ordered runtime arities |
| --- | --- | --- |
| F1: fresh names | `psErasureLocalNameWithFuel`, `psErasureEtaNameWithFuel`, `psTsFreshMatchTempWorker`, `psTsFreshInternalWorker` | 4, 4, 3, 4 |
| F2: preparation and elaboration | `psCompilerPreparationSourcesWorker`, `psAddDeclarationListWorker`, `psElabDeclarationsWorker` | 2, 2, 3 |
| F2: erasure | `psBuildErasureDeclarationNamesWorker`, `psEraseDefinitionsLoopWorker`, `psPrepareRuntimeStructures`, `psPrepareRuntimeInductives` | 2, 4, 5, 5 |
| F2: symbols | `psTsBuildSymbolMap` | 3 |

Each former returned-function state binder moves to the end of the existing
declaration parameters, and recursive calls pass the same state expressions in
the same order. Public names, complete curried types and wrapper interfaces stay
unchanged. Old erasure already eta-expanded the result-state arguments into the
runtime parameter group; the ABI gate checks that the candidate preserves those
ordered types and arities without requiring old parameter display names.

The three `CompilerIr/Check.lean` changes replace `limits`/two `currentState`
aliases with direct `options`/`state` projections in
`psIrCheckMatchBindings` and `psIrCheckRun`. They retain the root structural
matches, explicit match-result types and existing resource/error behavior.
The exact target inventory and seven guard updates are in
[migration-backlog.json](migration-backlog.json).

| Gate | Responsibility |
| --- | --- |
| [sh1-fresh-name-conformance.mjs](../../scripts/sh1-fresh-name-conformance.mjs) | 44 F1 worker cases plus 7 wrapper cases, including distinct exhaustion policies, collisions and scan boundaries |
| [sh1-migration-worker-conformance.mjs](../../scripts/sh1-migration-worker-conformance.mjs) | One synchronous 87-case gate: F1's 51 cases and F2's 36 cases; each R/F compiler constructs its own values and only JSON observations cross the comparison |
| [sh1-migration-worker-abi.mjs](../../scripts/sh1-migration-worker-abi.mjs) | `runMigrationWorkerAbi(compiler, prepared, ir, valueTag)` checks all twelve actual public Core types and ordered signatures in the already produced IR |

The ABI hook elaborates one small isolated module of signature axioms and typed
generic partial-application wrappers. These declarations are never merged into
the authoritative closure, erased, emitted or runtime-executed. Existing SH1
runtime partial-application checks cover lowering separately. The hook avoids
another full baseline preparation and runs before the original-IR check; no
asynchronous operation or mutation separates a successful original-IR check from
emission of that exact object.

Qualification records the paired R/F behavior, ABI observations, one coherent
current-source generation chain, C2/C3 canonical-source/admissions/TS/JS equality
and separate exact-stream provider acceptance. Candidate implementation and
static review do not satisfy those pending gates. Historical A/B/H/E/M6/TS7
receipts retain their identities; no provider, kernel, metatheory, general PSC1,
strict SH/1 or full PSCV claim is added by F.

### F host boundary completion

The reusable `createGeneratedPreparationSession` entry enforces the current
ProofScript grammar before any PS parsing, preparation or cache hit. Its PS
closure hash and receipt include the exact grammar profile. The existing Lean
serialization, receipt shape and cache behavior are preserved. Three focused
host-boundary cases cover the new refusal and cache contract; the existing real
generated PS session supplies compiler execution evidence. F qualification is
still pending.

The independent provider script additionally logs the exact read-back receipt
file content, byte count and SHA-256. This permits later evidence retrieval from
the same run without another artifact-collection workflow. The provider decision,
resource policy and acceptance gates are unchanged.

## Implemented recursion capability

The portable declaration-batch elaborator first uses the existing stable path.
Only `structuralRecursionInvariantArgument` invokes the new typed normalization
attempt. A definition accepted by the stable path keeps its previous lowering.
Other errors propagate; failed normalization is not retried recursively.

For a supported definition, the normalizer identifies changing explicit value
parameters by lexical binding identity. It retains the structural major and
unchanged parameters outside a private worker, moves changing state into the
worker result telescope, and applies recursive state arguments to induction
hypotheses. A separately type-checked public wrapper preserves the original
name, full type, binder kinds and argument order, including erased proof and
implicit type arguments.

For example, the qualified authoring form is:

```lean
def reverseInto {alpha : Type}
    (items : List alpha) (out : List alpha) : List alpha :=
  match items with
  | List.nil => out
  | List.cons item tail => reverseInto tail (List.cons item out)
```

The compiler performs the worker transformation. It is implemented in the older
accepted subset, so the historical compiler can build the first candidate.

### Deliberate boundaries

- The definition body starts with an existing flat constructor match on an
  explicit parameter. This checkpoint does not add equation compilation,
  arbitrary wrapper peeling, mutual recursion or general termination proofs.
- Changed parameters must be runtime value parameters. Parameter domains and
  the result must not depend on the major or generalized state.
- Self calls must supply exactly the explicit parameter telescope; they may
  only recurse on an admitted constructor child. An escaping self reference is
  rejected. Ordinary partial application of the completed public definition
  remains supported.
- Name decisions use lexical identities. All internal worker parameters are
  alpha-renamed to names unavailable in source syntax. The global worker uses
  a numeric internal name component, and environment insertion checks collision.
- Unrelated nested matches retain available outer induction hypotheses but
  cannot introduce decreasing children. Descendant hypotheses are available
  only when their expected result telescope agrees with the whole worker
  result; narrower nested motives are outside this checkpoint.

The kernel/provider implementation and metatheory are unchanged on this branch.

## Preparation sessions

`PsCompilerPreparationState` stores both the environment and reversed ordered
declarations. Start, parsed-step, source-step and finish are pure portable
operations. Existing aggregate public functions delegate to the same seam.

`scripts/generated-preparation-session.mjs` retains an exact-source prefix
inside one compiler instance. Any changed module invalidates the entire later
preparation suffix, including body-only changes whose exported names and types
are unchanged. Parsed syntax has a separate LRU. Source grammar edition, mode,
support scope and reference digest are part of current source provenance;
cache reuse must bind those to the exact executing parser/compiler identity.
Failures retain only the
successfully prepared prefix, so repaired input cannot reuse a failed suffix.

Returned preparation data is deeply frozen before the caller can observe it.
The caller must resolve/read current source on every request and bind compiler
identity to the bytes actually loaded. Compiler values cannot cross module
instances. A warm no-change request performs zero parse/elaboration/finish work.

The LRU bounds entry count and retained source-text bytes; it does not promise a
hard AST or whole-prefix heap bound. Receipts report cache reuse, invalidation,
source identities and separate timings. Preparation produces admission-ready
data, never reusable provider acceptance.

### Routine iteration

Use the bounded native-seeded gate for ordinary edits. It builds the current
native front end incrementally, uses that executable to emit the current
standalone generated compiler, and exercises the bounded capability and
iteration corpus through that compiler. From `psc0`:

```sh
npm run dev:sh1
```

This runs `lake build psc1 psc1_ir_check_tests` followed by
`node scripts/sh1-qualify.mjs native-candidate --native .lake/build/bin/psc1 --out dist/sh1`.
Current PSC0 compilation requires exact TypeScript 7.0.2. Install the `psc0` development dependency or provide the installed
launcher through `PSC0_TSC`; `PSC0_TYPESCRIPT_VERSION` defaults to `7.0.2`.
CI installs separate exact current and historical profiles. The historical
recovery commands require `5.8.3` and its matching launcher; source manifests
and recovery product hashes retain that version. See [TYPESCRIPT7.md](TYPESCRIPT7.md)
for scope, profile selection and the qualification evidence boundary.

The first execution of this gate at
`9641928bcf7d5394f46e19a31a8ae3fd096d44b5` passed in
[run 37834854232](https://github.com/dwijayuda/pskernel/actions/runs/37834854232).
Its native-candidate receipt measured **14.590 seconds** for the bounded gate;
the native build took about 15 seconds and the complete CI job about 74 seconds.
This was one Linux x64 run with restored build caches, Node v22.23.3 and
TypeScript 5.8.3. The Foundation comparison matrix was skipped because the
library source still matched its reference. These numbers describe that single cached run. The measured work is a native
build of N1 plus bounded cases; full generated self-application is a separate
workload, so these times do not establish a speed multiplier between them.

The gate writes N1 with `native-seeded-generated-compiler-candidate` evidence.
Its `artifacts.javascriptSha256` identifies N1 itself;
`nativeCompiler.binarySha256` separately identifies the native executable.
Full selected-seed compilation, current-source C2/C3 qualification and provider
acceptance remain separate promotion evidence.

For repeated requests within one compiler instance, an optional resident loop
retains preparation state. Its first request still prepares the entire current
compiler closure using the generated compiler, which can be expensive. It is
most useful for unchanged input and late-module edits across a longer session:

```sh
PSC0_ITERATION_SHA256="$(node -p "require('./dist/sh1/N1/receipt.json').artifacts.javascriptSha256")"
npm run iterate:sh1 -- --compiler dist/sh1/N1/index.js --compiler-sha256 "$PSC0_ITERATION_SHA256" --loop
```

Choose the development route by the work being done:

| Work | Route | Evidence |
| --- | --- | --- |
| One coherent source change, including an early dependency | `dev:sh1` | Incremental native build and bounded current generated execution |
| Repeated unchanged or late-module edits in a long session | Resident `iterate:sh1` with an explicit compiler pin | Reused preparation and admission-ready development products |
| Language, source-family, runtime or toolchain promotion | Full C1/C2/C3 and separate provider gate | Exact-source qualification under the recorded profile |
| Documentation-only descendant with identical executable sources | Preserve the existing qualified source and receipts | No new compiler execution is implied |

A resident session still pays its first whole-closure preparation cost. It is
useful when repeated requests amortize that startup; it does not establish a new
self-host fixed point for edited source. The last qualified checkpoint keeps its
original identity while development continues.

The resident CLI checks the supplied pin before importing the exact JavaScript
bytes. Select a compiler with the preparation API; the historical S0 lacks it.
Restart with a new explicit pin when changing compilers. Values and cached
environments stay inside one loaded compiler instance.

The loop prepares once, then accepts Enter or `prepare`, `emit`, `reset` and
`quit`. Each preparation reads the entire current raw bootstrap closure and
checks its identity again after work. Changing imports therefore recomputes the
current dependency order. Cache reuse compares exact import-stripped compiler
inputs; receipts also identify the raw source snapshot. A failed request keeps
the process alive so the source can be repaired. Prepared data and exposed
compiler diagnostic graphs are frozen. `--once` performs one request;
`--emit` also emits on that initial request.

`emit` writes canonical admissions, TypeScript, the raw source manifest and a
receipt into a new directory under `dist/sh1-iteration` (or `--out`). The complete
set is staged and then published with one directory rename. Earlier emissions
remain available. These are admission-ready development products. TypeScript
compilation, provider checking and full fixed-point qualification are separate
operations.

Existing `build:psc`, `build:auto` and `psc build` commands still use fresh
processes. The resident loop is the preparation reuse path. Its warm guarantee
concerns parse/elaboration/finish work; resolving and hashing current source,
optional emission and output publication still take time. Changing an early
dependency invalidates its full later suffix, and finishing changed input still
serializes the complete preparation result. Receipts report these costs
separately, including graph freezing. End-to-end speed claims require
measurements; zero warm preparation work only describes the retained
preparation stage.

## Qualification architecture

Ordinary pushes run the bounded native development gate. It builds current
native PSC incrementally, emits N1 from exact raw compiler source, then
executes the capability, helper, generic-erasure, preparation-session and
resident-CLI checks. The Foundation comparison runs when that source differs
from its preserved reference. Native-seeded development evidence remains
separate from selected-seed ancestry and current-source fixed-point evidence.

A commit containing `[sh1-qualify]`, or a full manual workflow dispatch, runs
the same native gate before expensive selected-seed generation. The native
outputs go to `dist/sh1/development`; selected-Q/C1/C2/C3 products remain in
`dist/sh1`. Their receipts and compiler identities stay separate.

The full path verifies or recovers Q, compares preserved/current raw Foundation
and helper sources using Q, builds and tests C1, then builds/tests C2 and C3.
The generic-erasure fixture runs on the new N1/C1/C2/C3 executables, whose
implementation includes that repair; it is not required of old Q.
Only C2-versus-C3 product equality is required. A separate pinned-provider job
checks the exact admission streams after compiler artifact generation.

Concurrency is scoped by branch. H and E qualified concurrently on their
separate immutable source checkpoints. Routine edits remain native-gated;
full self-application is reserved for coherent semantic or source-family
promotion checkpoints.

### Seed authority

The current selected authoring seed is R, source `fe2560aba0f347b1caf8d000d371464642d44f23`,
compiler SHA-256 `70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061`, selected by
[selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6). Its versioned manifest retains immutable A as
its parent. The S0/A/Q descriptions below document that historical parent chain;
they do not describe A as the current selected seed.

| Name | Meaning |
| --- | --- |
| S0 | The generated historical seed recovered from the immutable original 55-module source |
| A | The implementation source checkpoint that S0 can still compile |
| Q | The exact generated compiler bytes qualified from A and pinned for later authoring |
| B | Current source after adopting authoring forms implemented by Q |

S0's source is
`37f63c39d4a07189938046c64152bba25d789450`. Its ordered source blobs are checked
against the preserved baseline. Recovery uses pinned Lean and TypeScript 5.8.3;
the seed identity includes the historical source, toolchain and versioned native
recovery recipe. Updating a capability test or iteration helper does not change
that historical compiler input.

Without `psc0/selfhost-seed.json`, the selected authoring seed remains S0.
After A's full qualification, the workflow can produce `seed-promotion.json`
and retain Q's verified bytes. Activating Q requires an explicit reviewed seed
manifest in `psc0/selfhost-seed.json`; producing a candidate or cache entry does
not change source authority automatically.

The qualified manifest binds A's source revision and raw closure, S0's compiler
digest, Q's canonical surface/admission/TypeScript/JavaScript product hashes,
the toolchain/runtime tuple, the normalizer capability/version, and the target.
The exact source closure and generated compiler bind the prelude and runtime
implementations. It identifies the supported authoring capability as
compiler-qualified while retaining `strictSh1Qualified: false`. Provider
evidence is a separate reference. Evidence links can change without changing
the identity of the compiler bytes used for generation.

### Recovery without relying on mutable dist

Qualified seed reuse follows three routes:

1. Verify the content-addressed seed cache against the manifest, including the
   JavaScript and TypeScript bytes and the recorded source/toolchain identity.
2. If needed, validate a retained immutable qualification artifact, including
   the C2/C3 receipts and all four pinned product hashes, and materialize Q.
3. If that artifact is unavailable or invalid, check out pinned raw A, verify
   S0, rebuild `S0(A)` and then that first generation on A, and compare the
   resulting products with Q's pinned hashes before accepting the recovered
   compiler.

The last route reconstructs an already qualified identity. It does not depend
on mutable `dist`, artifact retention, or the current migrated source B.
Explicit compiler-path overrides must still match the selected seed's expected
JavaScript digest, which is checked before the bytes are imported.

The historical B checkpoints used Q from A while staying within Q's authoring
capability. That recovery route remains immutable. R adds the explicit parent
edge and verified source reconstruction needed for its newer capability; F uses
selected R. The tooling does not assert that historical S0 can consume F.

### Full current-source qualification

For the pending F checkpoint, the selected R compiler consumes the exact raw F
source: `C1 = R(F)`, `C2 = C1(F)`, `C3 = C2(F)`. Required current C2/C3 products,
original-IR/runtime checks and provider decisions remain F's own evidence. The
initial A and later Q/B equations below retain their historical meaning.

The initial A checkpoint evaluates:

```text
C1 = S0(A)
C2 = C1(A)
C3 = C2(A)
```

Q is selected from the converged C2/C3 compiler products. After migration, the
full checkpoint evaluates:

```text
C1 = Q(B)
C2 = C1(B)
C3 = C2(B)
```

Every generation consumes the current raw authored source. C2 and C3 must agree
on canonical surface source, canonical admissions, TypeScript and JavaScript.
C1/C2 equality is not required: the new compiler may change the lowering of its
own source. Receipts distinguish the executing compiler's digest from the
generated artifact's digest and record the exact raw source closure, source
revision, recipe, toolchain and product hashes. Recipe identity includes the
shared source/loader helper, preparation session, resident CLI and its
conformance helper, original-IR inventory, and language/Foundation harnesses.
Foundation reference/probe files are included in the recipe; raw language
fixture hashes are also recorded and checked in capability receipts.

The generated compilers also consume raw `.lean` and `.ps` capability examples.
The corpus covers changing accumulators, simultaneous state swapping, state
before the major, function results, generic values, proof erasure, public partial
application and lexical shadowing; negative examples exercise the boundary.
Session checks record their oracle's identity: the historical aggregate
implementation supplies an independent old implementation when selected, while
the ordinary native-seeded gate explicitly labels its aggregate comparison as
the same implementation. Cold/warm reuse, body edits, suffix invalidation,
failure repair, source kinds, fresh instances, frozen data/diagnostics and cache
eviction are checked without repeating a full compiler closure for each case.

The current new-only `.ps` surface printer remains syntax-only. Its result is
**canonical surface source**, identified by the source grammar and executing
compiler. The lowered worker representation is compared through
**canonical admissions**. Printing stability is one product comparison;
generated execution of raw authoring forms and actual provider decisions
supply their separate evidence.

## Independent acceptance axes

| Axis | Required evidence |
| --- | --- |
| Compiler-qualified capability | Current-source C2/C3 products, raw capability execution and conformance receipts |
| Bounded source grammar | New-only parser/printer/API observations and captured-closure canonical correspondence, bound to exact current generation products |
| Bounded runtime IR typing | Complete portable compositional check of the exact IR supplied to checked emission |
| Kernel-checked products | Actual acceptance of exact canonical admissions by the separately pinned provider |
| Strict SH/1 runtime qualification | Complete mandatory runtime and semantic obligations plus strict profile enforcement; bounded typing alone is insufficient |

The native baseline at
`963030dc2d154008fccc82e7c8ed29331f138799` passed its historical full checked
self-host run [37825822957](https://github.com/dwijayuda/pskernel/actions/runs/37825822957).
That historical result does not accept newly generated worker admissions.
New products are checked through a separate pinned provider checkout.

`original-ir-inventory.mjs` validates generated value carriers, invokes the
portable checker in the exact current compiler instance, and serializes its
bounded runtime typing report. The checked backend emits that same original IR
only after acceptance. The old diagnostic inventory remains available solely at
the authenticated S0/A producer boundary, where the older compiler lacks the
new checker. Its unresolved observations never count as runtime typing acceptance.
Neither report grants strict-profile qualification.

## Qualified implementation checkpoint

A is `e91b9558d665879871b8bf0893915ae64b27c7fe`, qualified by
[run 37831951758](https://github.com/dwijayuda/pskernel/actions/runs/37831951758).
Its raw closure contains 56 modules and 992334 bytes. S0, C1 and C2
each consumed that exact raw A; all C1/C2/C3 surface-source, admission, TypeScript
and JavaScript products agreed. The bounded native development route also emitted
the same JavaScript bytes at this checkpoint.

| Product | SHA256 |
| --- | --- |
| Raw source closure | `7e18013c260de84b08d57e923aef184993b0c5fea4de4775a68288a8ff9e157a` |
| Canonical surface source | `bb7fd97996339bdde40c3a92280d69a05d57f01f51626226a10a85aa548ebf41` |
| Canonical admissions | `15c85c7b8b6102472ff261c96c6901d4eb133c5a9443e06323a7d4b012ae6397` |
| TypeScript | `b7d57fc37a85d8f75c7bdfcac934d8022399a8543251b172dfaab91cab5e30b1` |
| Qualified JavaScript | `9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096` |

The pinned provider at `963030dc2d154008fccc82e7c8ed29331f138799`
accepted the exact compiler admission stream and the shared raw-capability stream.
Identical C2/C3 and Lean/PS streams were checked once per distinct byte stream.
Compiler-stream acceptance took about 1.346 seconds on that run. The receipt records
the provider binary digest, protocol, toolchain and unchanged resource policy.

Cold generated preparation took about 617 seconds in C2; a repeated request with
the same already-read inputs took 1.724 ms, reused all 56 modules, and performed
zero parse, elaboration, finish or freeze work. The full generation also serialized
admissions, printed canonical surface source, erased/inventoried/emitted IR and ran
TypeScript; it took about 985 seconds. These are separate stages and workloads.
The resident CLI still rereads and hashes source; optional emission remains whole-module work.

The original-IR traversal completed. It reported 245 call-arity cases requiring
expression typing and 19 call type-arity findings, with no other recorded finding
categories. That historical inventory did not establish strict SH/1 qualification.
E's later historical inventory and M6's bounded typing result are recorded below.

## Qualified Foundation.List migration

Source B is `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0`. Both jobs in
[run 37840481558](https://github.com/dwijayuda/pskernel/actions/runs/37840481558)
passed on the first execution of this migration checkpoint. B contains 56 raw
source modules and 991,890 bytes, 444 bytes fewer than A. Only Foundation.List
changed within the portable compiler closure at this checkpoint.

The selected Q compiler was recovered from A's retained artifact with all four
pinned products verified before use. Q consumed the current raw B source to make
C1; C1 and C2 consumed that same B closure to make C2 and C3. All four products
actually agree across C1, C2 and C3, including the optional stronger C1 equality.

| Identity | SHA-256 |
| --- | --- |
| Raw B source closure | `4b0e8ed609bdf1c6b7063d2d763f39f0d1c8d33ca7be375fa46bcece018c85ae` |
| Canonical surface source | `a115bb9328c7d7a2d2f354294e09cb4c658fe0a2b2b662e176b2420abd6305f4` |
| Canonical admissions | `117d89527f1a8dfad2a945203b64bc1087b3a35b55a12bf356f21a7b457b22d2` |
| TypeScript | `d63adb13b3d17842409b39e4b9745af6c285de1290ad4b7bec33a909831992bf` |
| JavaScript | `7a095596679cf53de213deb354610de22e29146e5d3265f07dc1720ea920836d` |

### Source correspondence

`psListReverseAcc`, `psListAppend`, `psListTake` and `psListZip` now use ordinary
explicit value parameters. The verified selected seed prepared the preserved
reference library and the current library before expensive C1 generation.
`psExprAlphaEq` passed for all ten public List declaration types; the checks
include binder kinds, complete telescopes and typed partial-application probes.

Each library passed 1,666 observations against independent JavaScript sequence
expectations: all 15 binary lists of length at most three, all 225 ordered list
pairs, take counts zero through eight, and a separate Nat/String generic zip.
Both libraries are checked against those expectations. The receipt explicitly
records that these finite observations are not exhaustive for all inputs.
Reference and current admission/TS/JS hashes legitimately differ.

The raw .lean and .ps capability corpus passed in all three generations, with
matching admissions and generated products across the two source spellings.
The seven refusal cases, aggregate/session correspondence, exact-prefix reuse,
body-edit invalidation, failure repair, frozen parsed diagnostics and resident
CLI checks also passed. The existing modular-preparation source guard passed
after its ownership assertions were updated to the actual pure prefix API.

### Measured preparation and full generation

| Generation | Cold preparation, seconds | Warm unchanged preparation, milliseconds | Full generation, seconds |
| --- | ---: | ---: | ---: |
| C1 | 621.311 | 1.734 | 983.965 |
| C2 | 606.305 | 1.726 | 968.930 |
| C3 | 614.434 | 1.731 | 984.134 |

Each warm request reused all 56 modules and did zero parse, prepare, finish or
freeze work. It reused already-read in-memory input; filesystem reads, source
resolution, optional emissions and publication are outside this warm number.
These are single CI observations, not a controlled speedup claim for the
generated compiler. The native gate remains the preferred ordinary workflow.

### Exact provider result and retained seed

The unchanged pinned provider accepted B's compiler admissions in about
1.170 seconds and the deduplicated raw capability admissions in about 7.918 milliseconds.
Default fuel 131072 and the existing provider semantics were retained. Artifacts
were generated before the separate provider check; the receipt records
`emissionWasGatedByThisCheck: false`.

Original machine receipts are preserved as
[foundation-qualification.json](foundation-qualification.json),
[foundation-correspondence.json](foundation-correspondence.json), and
[foundation-provider.json](foundation-provider.json). The complete generation
timings and provenance remain in the evidence index.

At B's qualification, A remained selected in `selfhost-seed.json`. B's successful fixed point did not
silently replace the historical S0 -> A -> B recovery path or claim S0 accepts B.

## Qualified three-helper migration

H is `671685c3f0059574405a1e630dd965d421a26f05`, qualified on its first
execution in [run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475).
Only `Elab/Term.lean` and `Erasure/Definition.lean` changed inside the
portable closure. It contains 56 raw modules / 991,563 bytes, 327 fewer than B.

| Source helper | Change | Preserved contract |
| --- | --- | --- |
| `psExprApplyManyWorker` | Ordinary expression accumulator parameter | Left-associated application order and the starting expression |
| `psExprAppViewAccWorker` | Ordinary argument-list accumulator parameter | Head, argument order and accumulator suffix |
| `psErasureAddUniqueStringWorker` | Ordinary changing String base parameter | Used-name membership, fuel and exact exhaustion suffix |

The compiler owns the worker/closure transformation. Public worker and wrapper
names, complete types and argument order remain unchanged. The source guards
accept both historical and qualified forms while retaining primitive,
wrapper-order and unrelated admission/module-sequencing checks.

The native N1 and selected-Q routes each compiled the preserved and current
helper slices using the real Name/Level/Expr dependency source. All seven
public types passed `psExprAlphaEq`, including binder kinds and order.
Each source slice passed 2,198 observations covering expression spines, partial
application, collision lists, Unicode/empty names and exhaustion. Separately,
each exported N1/C1/C2/C3 helper runtime passed 1,568 observations.

The unique-name algorithm deliberately retains its existing edge behavior:
zero attempts with `x` yields `x_overflow`; one collision with one attempt can
yield `x__overflow`. The correspondence checks are bounded observations and
type comparisons, not a universal semantic-equivalence theorem.

H's C2 and C3 agree on canonical source, canonical admissions, TS and JS.
C1 also matches those products. Its generated JS SHA256 is
`fb7708698c333c1985ae82c0eb5b061c8738f41feffc12f3fddccb1c74fc6855`. All three report traversals completed with 244
expression-typing obligations and 19 generic-argument arity findings.
The unchanged provider accepted 2 distinct admission streams
covering the full compiler and raw language capabilities. Helper-slice admission
streams are not included in that provider claim.

## Qualified recursive generic-erasure repair

E is `cf8fbd784944a98b1e390b709685ca54c2511827`. Both jobs in
[run 37852341550](https://github.com/dwijayuda/pskernel/actions/runs/37852341550)
passed on its first execution. E contains 56 raw modules / 992,338 bytes.
Its source closure is
`d7866a3c8da745db5b0f6c7ce67381915f6265263615c13a243ec674c1ab13e2`.

The historical A/B erasure context retained the current definition's name and
runtime parameter names, but not its declaration generic arguments.
`psOpenMatchMinorHypotheses` consequently reconstructed recursive calls with
an empty type-argument list. The historical report did not record enough
callee ancestry to prove a one-to-one source mapping for all 19 findings.

The bounded repair addresses that shared omission:

| Portable source | Implementation |
| --- | --- |
| [Erasure/Basic.lean](../../packages/erasure/src/Ps/Erasure/Basic.lean) | Add `typeArgumentsRev` to the current-definition context |
| [Erasure/Definition.lean](../../packages/erasure/src/Ps/Erasure/Definition.lean) | Accumulate the assigned declaration `Tn` arguments; preserve them across runtime and erased proof binders |
| [Erasure/Expr.lean](../../packages/erasure/src/Ps/Erasure/Expr.lean) | Restore declaration order and pass the arguments during recursive-IH reconstruction |

Only declaration binders contribute. The change does not collect unrelated
local type bindings, add declaration-name exceptions or modify the inventory
checker. Monomorphic calls retain an empty generic list. Accumulation uses
constant-time cons; order is restored when constructing a recursive call.

The focused raw fixture checks one, two and three generic parameters, including
type parameters interleaved with erased proposition/proof and runtime binders,
plus a monomorphic control. N1/C1/C2/C3 each passed exact original-IR type
argument order and runtime arity assertions, followed by 19 behavior
observations. N1 and C1 also passed exact native TS and behavior correspondence.
The harness emits the same original IR object that it inspects.

### Generation handoff and measured results

C1 is built by old Q; its full-source IR inventory therefore records Q's
lowering. Executing C1 already runs E's repaired implementation. C2 and C3 then
exercise the repaired compiler on E itself.

| Full-source generation | Executing compiler | Generic-argument arity findings | Call-expression typing obligations |
| --- | --- | ---: | ---: |
| C1 | Old selected Q | 19 | 244 |
| C2 | New C1 | 0 | 244 |
| C3 | New C2 | 0 | 244 |

Every traversal completed. C1's TS/JS legitimately differ from C2/C3; canonical
source and admissions agree. C2 and C3 agree on all four required products.
N1 independently produces the same TS/JS as C2/C3.

| E identity | SHA256 |
| --- | --- |
| C1 generated JS | `d3fd03481ce03d4d2f962f932d4987aff28a7dcf68a395467be2dc57f1d60a2c` |
| C2/C3 and N1 JS | `b6783f5d3ae25fe2da233da3a2c607445efa007a62bbde0275cfa6b8b8b04816` |
| C2/C3 TS | `d63c80ca1c0d087b4f4d8cc6fa97693fcd7ddb7fb89aaeb67413f4d904109837` |
| Canonical surface | `0ddb544ccd1784907511cfe60f59a21a03616c2e17e0a92188cf1b1034950dd8` |
| Canonical admissions | `f55cf731f7c0d6e8a0d025b92b97620cd336011a2164e8d649c16cf81c950d29` |

The bounded E native-candidate gate took 25.886 seconds after the native build.
The three full generation totals were 607.562s, 606.556s and 632.401s.
C2 cold preparation took 375.724s; unchanged in-memory preparation reused all
56 modules with zero parse/prepare/finish work in 1.085ms.

These are single-run measurements on the recorded Linux x64 runner with
Node v22.23.3, Lean 4.34 and TS 5.8.3. The warm measurement excludes source reads
and emission. Native and self-application timings describe different workloads;
runner differences also prevent attributing the difference from A/B/H timings
to a generated-compiler speedup.

### Exact provider acceptance

The provider remains `963030dc2d154008fccc82e7c8ed29331f138799`, binary SHA256
`88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
Default fuel 131072 and timeout 60000ms are unchanged. It accepted three
deduplicated streams:

- The exact E C2/C3 compiler admissions.
- The existing raw `.lean`/`.ps` capability admissions from C2/C3.
- The new raw generic-recursion fixture admissions from C2/C3.

Compiler artifacts were emitted before this separate check. The original
compiler/fixture receipts keep their then-current provider status; later
acceptance is preserved in
[recursive-generic-erasure-provider.json](recursive-generic-erasure-provider.json).
No kernel/provider implementation or metatheory changed.

## Qualified bounded runtime IR typing

The earlier E inventories contained 244 unfinished call-expression typing
obligations after the generic-argument repair. M6 replaces that limited current
inventory with one portable compositional checker for the original IR.
The old E receipts retain their original counts.

The checker validates signatures, scoped bindings, exact function parameter
groups, ordered generic schemes with simultaneous substitution, annotated
initializers and function results, layout fields/projections/matches and active
intrinsic types. Unknown types, unsupported capabilities and resource exhaustion
are failures. A host adapter validates generated carriers and serializes the
portable result; it has no separate expression-typing implementation.

[Check.lean](../../packages/compiler-ir/src/Ps/CompilerIr/Check.lean),
[CheckTypes.lean](../../packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean)
and [CheckSize.lean](../../packages/compiler-ir/src/Ps/CompilerIr/CheckSize.lean)
own those rules.
[BackendTs/Checked.lean](../../packages/backend-ts/src/Ps/BackendTs/Checked.lean)
checks the exact IR supplied to emission.
[Construct.lean](../../packages/compiler-ir/src/Ps/CompilerIr/Construct.lean)
provides ordinary portable constructors for the generated host boundary.

The independently qualified M6 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` records:

| Evidence | Observed result |
| --- | --- |
| Portable compiler source | 61 modules; 1,088,337 bytes |
| Native full original IR | 54,879 expressions; 707,753 visited steps; complete; accepted; zero findings |
| Native fixtures | Eight cases passed |
| N1/C1/C2/C3 runtime conformance | 59 observations per generation, including 29 observations across four let-scope cases |
| Generated checker refusals | 36 negative IR cases and five malformed/foreign carrier cases per generation; resource and direct type-operation cases also passed |
| Current C2/C3 full original IR | Complete; accepted; zero findings; same original IR checked before emission |
| Current C2/C3 products | Canonical surface source, normalized admissions, TS and JS agree; N1 TS/JS also agree |
| Independent selected provider | Three exact admission streams accepted after emission |

The generated C2/C3 summaries do not print their full expression or visited-step
counts. Those fields are not inferred from the native counts; their full reports
remain in `dist/sh1/C2/original-ir-inventory.json` and the corresponding C3 artifact path.

The native development gate's internal total was 144.586 seconds. The C1/C2/C3
generation totals were 1,145.486 / 1,187.825 / 1,199.391 seconds.
Across those three generations, preparation accounted for 60.17% of the recorded
total; `tscAndWrite` accounted for 30.655 seconds, or about 0.87%. The latter
includes evidence writes, hashing and identity work as well as TypeScript.
These are observed phase timings from one qualification run, not controlled benchmarks.

The compiler bundle preserves all 28 complete logged JSON receipts, including
their original provider-not-attempted fields. The separate later provider receipt
records `accepted: true` and `emissionWasGatedByThisCheck: false`.
Compiler qualification, bounded IR typing and exact-stream provider acceptance
are earned; strict SH/1 and profile activation remain false.

See [runtime-ir-checker-qualification.json](runtime-ir-checker-qualification.json),
[runtime-ir-checker-provider.json](runtime-ir-checker-provider.json) and
[runtime-ir-checker-execution.json](runtime-ir-checker-execution.json)
for complete receipts and the retained attempt history.

The selected old Q can still produce a legacy C1 inventory: that report belongs
to Q's produced IR. The new C1 executable contains the checker, executes its
conformance cases, and uses it for current C2 generation; C2 does the same for C3.
The explicitly authenticated legacy boundary never grants runtime typing
acceptance. No current checker failure falls back to the legacy inventory.

A valid let-shadowing fixture also exposed a backend scope defect. The repaired
generator evaluates a same-named initializer in the outer scope and introduces
the new binding for the body. It handles a suspended initializer and a closure
capturing the old binding; the tail optimizer declines the affected direct-loop
case. The original fixture remains, with focused coverage for the complete
affected family.

[RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md) defines the installed API, its resource
and diagnostic counters, active/refused capabilities and remaining contracts.
Successful typing does not establish primitive laws, valid bounds/UTF-8
positions or general erasure/backend preservation. Optional scalar and import
capabilities remain disabled until their own contracts are qualified.
Provider acceptance of exact admissions is a separate receipt.

## Current authoring boundaries

The supported authoring subset now includes qualified ordinary structural
recursion with changing nondependent value parameters, as used by Foundation.List
and the three migrated compiler helpers. Its grammar and inference remain bounded.

Use explicitly typed local callbacks in authored compiler `.lean`; its argument
parser remains bounded. Current `.ps` accepts grouped typed callbacks but does
not infer omitted lambda domains. Give match-valued let initializers an explicit
result type. F uses direct original-parameter projections at the three scoped
cleanup sites, with the qualified and explicitly selected R seed as a prerequisite.
The historical A-compatible aliases remain documented as evidence of the earlier
boundary, not as the current F authoring requirement.
[SPEC.md](SPEC.md#current-authoring-forms) gives the precise forms and
[MIGRATION.md](MIGRATION.md#follow-on-repair--parameter-projections-in-recursion-normalization)
defines that repair's scope.

## Migration order

1. Completed: qualify the bounded recursion implementation A while S0 can still
   build it, then select recoverable Q from A.
2. Completed: migrate Foundation.List B with preserved public types and bounded
   reference/runtime correspondence, then qualify its exact source.
3. Completed: migrate the three compiler helpers H using the same qualified
   capability and qualify H independently.
4. Completed: repair ordered recursive generic arguments in isolated E,
   qualify its original-IR/runtime behavior and current-source C2/C3, and obtain
   exact-stream provider acceptance.
5. Completed: implement and qualify the bounded portable runtime IR checker,
   same-IR checked emission and old-scope let correction under both the TS5
   baseline and current TS7 profile.
6. R compiler/provider checkpoint completed: R2 qualified the parameter-projection
   repair and new-only `ps-0.9-r3` lexer/parser/printer, fixtures and provenance.
   Its source remains A-consumable for recovery. Cold recovery is verified and
   the exact R successor is selected; F's own migration qualification is pending.
7. F implemented candidate, qualification pending: migrate the twelve frozen
   workers, remove the three scoped aliases, update the seven affected guards,
   and qualify the coherent final source with the 87-case gate, actual Core/IR
   ABI observations, current C2/C3 products and exact provider decisions.
8. Routine iteration: use the native development gate and suitable resident
   preparation reuse. Reserve full fixed-point/provider work for semantic
   promotion checkpoints.

The selected manifest and receipts determine the current seed; this candidate
record does not assert a new selection. The historical 55-module baseline and
each later qualified checkpoint retain their original evidence. Exact current branch,
source identities and remaining work live in
[AI_WORK_STATE.md](../../AI_WORK_STATE.md).
