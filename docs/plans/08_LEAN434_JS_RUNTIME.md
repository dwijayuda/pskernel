# Lean 4.34 on JavaScript execution plan

Status: **experimental branch plan**  
Branch: `runtime/lean434-js-runtime`

This plan turns the research in
`docs/research/LEAN434_JS_RUNTIME_ARCHITECTURE.md` into executable gates.

It is intentionally isolated from `main` and from
`kernel/lean434-study-hardening`. The experiment may reuse pskernel's public
API, but it must not weaken or rewrite kernel semantics just to make Lean source
execute.

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

## R0 — source/runtime census

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

## R1 — core JS runtime contract

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

## R2 — extern lowering

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

## R3 — implemented_by policy

Parse/preserve the selected `implemented_by` attribute.

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

## R5 — Environment facade

Separate Lean's Environment responsibilities:

- constants/declarations -> pskernel;
- extension state -> untrusted persistent data;
- module metadata -> ProofScript module/project layer;
- compacted region/native loader features -> replacement/deferred.

Exit condition:

> A reused Meta/Elab function can read/update ordinary environment extension
> state while declaration admission still flows through pskernel.

## R6 — reusable Init tranche

Compile actual upstream files, not manually translated equivalents.

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

## R7 — Parser tranche

Reuse/adapt the Lean parser implementation.

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

