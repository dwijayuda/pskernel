# 1. Processing, Elaboration, and Trust

PSC1 source moves through distinct stages. Keeping their responsibilities
separate is part of the language design.

## Pipeline

```text
.ps / supported .lean
        |
        v
source frontend
        |
        v
shared syntax / semantic AST
        |
        v
Meta / elaboration
        |
        v
pskernel admission
        |
        v
CheckedCore
        |
        v
Erasure
        |
        v
VerifiedIR
        |
        +--> TypeScript -> tsc -> JavaScript
        +--> Rust
        +--> direct Wasm
```

## Parsing

Parsing determines syntactic structure and source ownership.

PSC1 parsing is fail-closed.

It recognizes:

- registered PSC1-owned forms;
- bounded compatible Lean forms;
- no arbitrary "if Lean might parse it, accept it" fallback in the standalone
  compiler.

## Surface normalization

Source conveniences such as:

- D-CALL `f(x, y)`;
- braced `if`;
- braced structure/inductive/match bodies;
- `const`;
- `function`;

normalize toward a smaller semantic AST.

They must not create alternate semantics.

## Elaboration

Elaboration resolves user-friendly syntax into explicit typed terms.

Responsibilities include the supported subset of:

- expected-type propagation;
- implicit arguments;
- universe information;
- metavariables;
- unification;
- typeclass synthesis;
- overloaded notation;
- tactic proof construction.

Elaboration is not trusted to assert validity by itself.

## Kernel checking

pskernel checks the resulting declarations/proof terms.

A frontend bug may propose an invalid term, but the kernel must reject it.

The kernel does not execute JavaScript/Rust/Wasm to decide whether a theorem is
true.

## CheckedCore

CheckedCore is the post-admission representation used as the source for
executable erasure/lowering.

Serialized checked admissions do not become trusted merely because they were
previously serialized; they are replayed through pskernel when admitted.

## Erasure

Erasure removes proof/type information that is irrelevant to runtime execution.

It must preserve executable meaning.

Kernel soundness does not automatically prove the erasure pass correct.

## VerifiedIR

VerifiedIR is target-neutral executable semantics.

It MUST NOT encode target assumptions such as:

- JavaScript `number`/`bigint`;
- Rust ownership/lifetimes;
- Wasm opcodes or memory layout.

## Compiler output

Backends lower VerifiedIR to target-specific code.

A successful target compiler proves only that the target artifact satisfies the
target compiler's checks, not that the source theorem was valid.

## Trust layers

PSC1 therefore distinguishes:

- parser/elaborator correctness;
- kernel soundness;
- erasure correctness;
- IR transformation correctness;
- backend correctness;
- external runtime assumptions.

This separation is essential to honest assurance claims.
