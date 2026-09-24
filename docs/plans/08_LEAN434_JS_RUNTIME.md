# Lean 4.34 on JavaScript execution plan

Status: **experimental branch plan**  
Branch: `runtime/lean434-js-runtime`

This plan turns the research in
`docs/research/LEAN434_JS_RUNTIME_ARCHITECTURE.md` into executable gates.

It is intentionally isolated from `main` and from
`kernel/lean434-study-hardening`. The experiment may reuse pskernel's public
API, but it must not weaken or rewrite kernel semantics just to make Lean source
execute.

## Branch scope after architecture review

This branch does **not** continue the existing TypeScript ProofScript frontend as
the long-term Lean-on-JS implementation.

The intended permanent implementation surface is:

```text
study/lean4-4.34.0/src/**/*.lean
        |
        v
small bootstrap loader / source driver
        |
        +----------------------+
        |                      |
        v                      v
     pskernel           @proofscript/runtime/lean4
        |                      |
        +----------+-----------+
                   |
                   v
               JavaScript
```

Repository policy for this branch:

- `src/core`, `src/kernel`, and their public kernel facade remain the trusted
  kernel implementation;
- `packages/runtime` is the JavaScript execution/runtime compatibility layer;
- pinned upstream/adapted `.lean` source is the implementation source for
  Parser, Meta, Elab, and eventually compiler logic;
- small scripts/bootstrap drivers are allowed when they exist only to bring the
  Lean-written stack up;
- existing TypeScript packages such as `syntax`, `meta`, `elab`,
  `checked-core`, `erasure`, `compiler-ir`, and `compiler` are **not**
  to be expanded for this experiment. They may be consulted as references and
  test oracles, but they are not the target architecture;
- do not mass-delete those packages yet: deletion would create a very large,
  low-information branch diff and make comparison with `main` harder. Once
  the Lean-written bootstrap path reaches an independent gate, unused packages
  can be pruned from this branch in one deliberate cleanup;
- no change in the runtime may grant proof authority. pskernel remains the
  declaration checker.

A small bootstrap driver is still necessary before the Lean-written parser and
elaborator can compile themselves. That bootstrap is infrastructure, not a
second language implementation.

## Permanent invariants

1. pskernel remains the only trust boundary for declaration admission.
2. JavaScript runtime results are never proof evidence.
3. Unknown Lean externs fail closed.
4. `@[implemented_by]` is an execution choice, not a logical equality proof.
5. Runtime/host code stays outside the kernel package.
6. The experiment must eventually converge on the existing checked-core ->
   erasure -> verified IR -> TypeScript -> JavaScript path, not a second
   semantic checker.
7. Reuse is measured on real pinned Lean 4.34 source files.

## R0 — source/runtime census — **COMPLETE (baseline)**

Completed 2026-09-25 on this branch. The deterministic scanner covers 1,576 pinned Lean files and the baseline is recorded in `docs/research/LEAN434_JS_RUNTIME_CENSUS_BASELINE.md`.


Build an executable census over:

- `study/lean4-4.34.0/src/Init`;
- `study/lean4-4.34.0/src/Lean/Parser`;
- `study/lean4-4.34.0/src/Lean/Meta`;
- `study/lean4-4.34.0/src/Lean/Elab`;
- `study/lean4-4.34.0/src/Lean/Compiler`.

Record at least:

- `@[extern]` symbols;
- `@[implemented_by]`;
- `unsafe`;
- `partial def`;
- `opaque`;
- `builtin_initialize`;
- use of `IO`, `BaseIO`, `EIO`, `ST`, refs and tasks;
- key collection/object-model types.

Exit condition:

> The repository can regenerate a deterministic JSON census from the pinned
> source snapshot.

## R1 — core JS runtime contract — **COMPLETE (first scoped slice)**

Completed 2026-09-25 for the initial Nat/UInt/Array/String/ST.Ref surface. `@proofscript/runtime/lean4` exposes a versioned Lean 4.34 compatibility module with 30 explicit extern mappings. GitHub Actions run `36038614385` passed the runtime tests, census, and architecture gate.

This does not mean the entire Lean runtime is complete; later runtime primitives are pulled in only by dependency-closed source tranches.


Implement source-compatible runtime exports for the first primitive surface:

- Nat arithmetic/comparison;
- UInt normalization/conversion needed by bootstrap code;
- persistent Array primitives;
- UTF-8-position String primitives;
- single-threaded ST refs.

Add a versioned extern manifest whose keys are Lean's extern symbol names.

Exit condition:

> Runtime tests cover value semantics, UTF-8 positions, array persistence and
> ref identity/take/set behavior.

## R2 — extern lowering — **COMPLETE (first source-backed slice)**

Research constraint discovered during R0/R1: an upstream `@[extern] def` must remain an ordinary pskernel-checked logical definition with a separate executable override. It must **not** be converted into the existing ProofScript `extern function` axiom form.

Completed first slice 2026-09-25: `@proofscript/runtime/lean4` now has a source-verified declaration-to-extern binding layer. The evaluator resolves real pskernel-admitted `Nat.add` through `Nat.add -> lean_nat_add -> JS implementation`; GitHub Actions run `36041968767` executes the pinned Lean 4.34 `Init.Prelude` declaration and obtains `42`. The manifest checker verifies the declaration and extern symbol against the pinned source. Runtime argument erasure for polymorphic/proof-carrying externs is explicit metadata and fails closed when malformed.


Extend the Lean-compatible frontend/lowering so a whitelisted upstream form

`@[extern "symbol"]`

can resolve to a JS runtime import without rewriting the source declaration.

Requirements:

- mapping is pinned by Lean/runtime version;
- arbitrary extern strings are not accepted;
- source span and upstream declaration name are retained;
- assurance metadata reports runtime assumptions.

Exit condition:

> At least one real upstream Init declaration keeps its original extern
> attribute and executes through the JS runtime after pskernel admission.

## R3 — implemented_by policy — **IN PROGRESS (metadata/execution slice complete)**

Parse/preserve the selected `implemented_by` attribute.

Completed first slice 2026-09-25: source-verified bindings for parser-relevant `TSyntaxArray.raw -> TSyntaxArray.rawImpl` and `TSyntaxArray.mk -> TSyntaxArray.mkImpl` execute as representation-preserving identity adapters in JS. GitHub Actions run `36042195601` gates the adapters, while the manifest checker verifies the original `@[implemented_by ...]` attributes against pinned Lean 4.34 source. pskernel admission remains unchanged.

R3 remains open because the original differential exit condition still requires at least one ordinary reference/optimized pair whose executable behavior can be compared on a bounded corpus. `TSyntaxArray.raw/mk` are intentionally opaque runtime-representation bridges, so they are not suitable for that equivalence gate.

Execution order:

1. use reference definition by default;
2. enable optimized implementation only when explicitly mapped;
3. keep the optimized implementation outside proof authority.

Exit condition:

> Differential test shows reference and selected JS implementation agree on a
> bounded corpus, while kernel checking remains unchanged when the optimization
> is disabled.

## R4 — Name / Level / Expr compatibility

Create the source-facing object model needed by Parser/Meta/Elab.

Preferred result:

- Lean-facing `Name`, `Level`, `Expr` representations are either directly
  compatible with pskernel values or have a canonical one-time converter;
- no parallel trusted expression semantics.

Exit condition:

> Real Lean-written expression traversal/manipulation code can run in JS and its
> candidate declaration can be re-admitted by pskernel.

## R5 — Environment facade — **IN PROGRESS**

Milestones reached 2026-09-25:

- Lean-native runtime sidecars now export ordered initializer metadata from the
  pinned 4.34 environment;
- the JS initializer runner stores initialized globals outside pskernel and
  resolves generated/private Lean names by exact environment name;
- real upstream `IO.mkRef`, `ST.Prim.Ref.get/set`, and the Lean-written
  `ST.Prim.Ref.modify` do/bind implementation execute in JS;
- `IO.initializing` is scoped to initializer execution, preparing the
  `registerEnvExtension` guard without weakening the kernel.

Separate Lean's Environment responsibilities:

- constants/declarations -> pskernel;
- extension state -> untrusted persistent data;
- module metadata -> ProofScript module/project layer;
- compacted region/native loader features -> replacement/deferred.

Exit condition:

> A reused Meta/Elab function can read/update ordinary environment extension
> state while declaration admission still flows through pskernel.

## R6 — reusable Init tranche — **IN PROGRESS (executable foundation proven)**

Compile actual upstream files, not manually translated equivalents.

Milestones reached 2026-09-25:

- pinned `Init.Prelude` definitions execute after pskernel replay:
  `Nat.add`, polymorphic `id`, recursive `List.lengthTRAux`, Array and
  UTF-8 String paths;
- runtime selection is source-backed through Lean's real `@[extern]` and
  `@[implemented_by]` metadata;
- real Lean ST/IO source executes over the JS primitive boundary rather than a
  TypeScript reimplementation of its bind/control logic.

Maintain a generated matrix:

- DIRECT;
- SHIM;
- ADAPT;
- REPLACE;
- DEFER.

Start with files required by:

- core collections;
- control/state;
- strings/source positions;
- names/syntax;
- Meta dependencies.

Exit condition:

> A nontrivial dependency-closed Init tranche executes as JS with a recorded
> reuse ratio and no native Lean runtime.

## R7 — Parser tranche — **IN PROGRESS (first upstream algorithms + initializer running)**

Reuse/adapt the Lean parser implementation.

Milestones reached 2026-09-25:

- `Lean.Parser.Types` has 0 direct extern declarations and 0 direct
  `implemented_by` bindings in the pinned environment;
- real upstream `Lean.Parser.FirstTokens.toOptional`, `seq`, and `merge`
  execute through pskernel + the JS evaluator;
- `Lean.Parser.Basic` has 0 direct extern declarations and 0 direct
  `implemented_by` bindings; its runtime work is initialization;
- the real builtin initializer for `Lean.Parser.categoryParserFnRef` executes
  in JS and stores a Lean-written parser closure in a JS-backed Lean `IO.Ref`;
- the next active gate is
  `Lean.Parser.categoryParserFnExtension`, which exercises upstream
  `registerEnvExtension`.

Differential gates:

- tokenization;
- representative terms;
- declarations;
- module headers;
- source spans;
- normalized Syntax shape.

Exit condition:

> The JS-hosted parser handles the frozen compiler source subset with
> differential agreement against Lean 4.34.

## R8 — Meta tranche

Bring up:

- metavariable context;
- saved-state rollback;
- WHNF;
- infer type;
- defeq/unification;
- instance synthesis.

Exit condition:

> Reused/adapted Lean Meta code elaborates representative compiler terms and
> pskernel independently rechecks all admitted declarations.

## R9 — Elab tranche

Reuse command/term elaboration needed by the compiler source.

Do not initially port native incremental snapshot persistence or compacted
region loading.

Exit condition:

> Real compiler modules elaborate through the JS-hosted frontend.

## R10 — JS compiler bootstrap

Compile the compiler implementation itself to JavaScript.

Fixed point:

```text
bootstrap compiler -> source -> compiler-1.js
compiler-1.js      -> source -> compiler-2.js
```

Require canonical equality/equivalence for:

- checked-core fingerprint;
- verified IR fingerprint;
- normalized generated TypeScript where appropriate;
- executable behavior.

## R11 — ProofScript source transition

Once the Lean-source compiler is stable:

- canonical/adapted `.lean -> .ps`;
- require equal checked-core/IR behavior;
- promote `.ps` as source of truth only after parity holds.

## R12 — optional broader Lean compatibility

After the compiler self-hosts, evaluate:

- more Init/Std;
- richer macros/quotations;
- tasks/concurrency;
- browser host;
- `.olean` import compatibility;
- selected LCNF optimization passes;
- Lean source packages outside the compiler bootstrap subset.

These do not block R10/R11 unless real compiler source demonstrates a need.

## Merge policy

Do not merge this experiment to `main` merely because isolated runtime tests
pass.

A mainline merge should require at minimum:

1. R0 deterministic census;
2. R1 runtime contract;
3. one real upstream source file executing with its original extern spelling;
4. no architecture/check regressions;
5. a documented relationship with
   `docs/plans/07_SELF_HOSTING_FOUNDATION.md`.

