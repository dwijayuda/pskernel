# PSC0 SH/1 implementation and qualification

Status: initial implementation A and the Foundation.List migration B are compiler-qualified,
and their exact admission streams were accepted by the pinned native provider. B is
`70d6010ddccbdd6b4939f2fb3c088bfe4e607de0`; A remains the selected recoverable authoring seed.
This document supplements [SPEC.md](SPEC.md). Strict runtime profile activation remains
pending M6 enforcement. Exact results and retained receipts are indexed in
[qualification-evidence.json](qualification-evidence.json).

## Implemented capability

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
are unchanged. Parsed syntax has a separate LRU. Failures retain only the
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

This runs `lake build psc1` followed by
`node scripts/sh1-qualify.mjs native-candidate --native .lake/build/bin/psc1 --out dist/sh1`.
TypeScript 5.8.3 must be available to the existing resolver or on `PATH`; CI
installs an isolated pinned copy.

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

The workflow separates ordinary development from full semantic promotion.
Ordinary pushes run `native-candidate`: the current native PSC frontend builds
N1 from raw current compiler source, then N1 executes the bounded language,
preparation-session and resident-CLI corpus. The Foundation behavior matrix runs
when the library source differs from its preserved reference. Gate evidence is
`native-seeded-generated-compiler-candidate`. The selected bootstrap seed and
generated current-source fixed point are separate obligations.

A commit message containing `[sh1-qualify]`, or a manual workflow dispatch with
`full` enabled, selects the promotion path. It verifies or recovers the selected
authoring seed, runs `candidate` with that seed, and then runs `fixed-point`.
The current native compiler remains useful as an additional bounded behavior
comparison. A separately pinned provider job consumes the full run's exact
admission artifacts and records its own acceptance or rejection.

### Seed authority

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

B continues using Q from A while it stays within Q's authoring capability.
The current implementation retains that recovery route when B passes a new
fixed point. Promoting a later compiler that requires a newer bootstrap language
needs an explicit parent-seed recovery plan; the tooling does not replace A with
an unsupported assertion that S0 can compile B.

### Full current-source qualification

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

The existing surface printer remains syntax-only. Its result is **canonical
surface source**. The lowered worker representation is compared through
**canonical admissions**. Printing stability is one product comparison;
generated execution of raw authoring forms and actual provider decisions
supply their separate evidence.

## Independent acceptance axes

| Axis | Required evidence |
| --- | --- |
| Compiler-qualified capability | Current-source C2/C3 products, raw capability execution and conformance receipts |
| Kernel-checked products | Actual acceptance of exact canonical admissions by the separately pinned provider |
| Strict SH/1 runtime qualification | Complete runtime typing/layout/intrinsic obligations; an IR inventory alone is insufficient |

The native baseline at
`963030dc2d154008fccc82e7c8ed29331f138799` passed its historical full checked
self-host run [37825822957](https://github.com/dwijayuda/pskernel/actions/runs/37825822957).
That historical result does not accept newly generated worker admissions.
New products are checked through a separate pinned provider checkout.

`original-ir-inventory.mjs` examines the original PSC0 IR produced by the exact
compiler instance. It reports unknown types, scope/layout/arity findings and
unresolved obligations without expanding the portable compiler closure.
It is a diagnostic artifact and does not grant strict-profile acceptance.

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
categories. Those remaining obligations prevent strict SH/1 qualification even
though the compiler fixed point and Core admission checks passed.

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

A remains selected in `selfhost-seed.json`. B's successful fixed point does not
silently replace the historical S0 -> A -> B recovery path or claim S0 accepts B.

## Remaining runtime IR work

B's C1/C2/C3 inventories all completed with 244 call sites needing expression
typing and 19 type-argument arity findings, with no other recorded categories.
The retained A inventory had 245 and 19 respectively. All 19 detailed A records
have zero explicit type arguments: fifteen expect one, three expect two
(`psListMap`, `psListZip`, `psTsTailMap`), and one expects three (`psListMapExcept`).
The owning declarations are generic structurally recursive helpers.

A concrete omission exists in the unchanged original erasure path:
`PsErasureCurrentDefinition` stores only the name and runtime parameters;
opening a type binder does not add its type parameter to that record; and
`psOpenMatchMinorHypotheses` reconstructs a recursive application with an empty
type-argument list. This is consistent with the 19 records. The inventory
does not record callee identity or ancestry, so it does not prove a one-to-one
mapping from every finding to that path.

See [the current-definition record](../../packages/erasure/src/Ps/Erasure/Basic.lean),
[definition opening](../../packages/erasure/src/Ps/Erasure/Definition.lean), and
[recursive-IH reconstruction](../../packages/erasure/src/Ps/Erasure/Expr.lean).
The smallest follow-on erasure change is to retain ordered generic arguments
in the current-definition context and use their scoped instantiation when
reconstructing recursive calls, preserving them across runtime/proof binders.
Then add call-expression typing and scoped generic substitution to the
reporting checker. Keep monomorphic calls and their empty type arguments valid.

That continuation needs its own focused evidence. It is not part of this
already-qualified source migration, and neither the inventory counts nor
provider acceptance activates strict SH/1 runtime enforcement.

## Migration order

1. Qualify the implementation while it remains consumable by the historical
   seed. Preserve the exact qualified compiler/source identity.
2. Configure a recoverable, pinned qualified seed before adopting new authoring
   forms in compiler source.
3. Migrate one useful family: Foundation.List accumulator and paired-traversal
   workers. Preserve public names/types and numeric/list semantics. Compare
   behavior with the previous qualified implementation.
4. Qualify the migrated current source at the next promotion checkpoint.
   Expand to additional families only when this evidence is complete.
5. Use the native development gate for ordinary edits and prefix preparation reuse
   for suitable resident sessions. Reserve full fixed-point and provider checking
   for semantic promotion checkpoints.

Do not rewrite the whole compiler mechanically, rename the profile to claim
support, or overwrite the historical 55-module baseline. Exact progress,
qualified commit/run IDs and any remaining blocker live in
[AI_WORK_STATE.md](../../AI_WORK_STATE.md).
