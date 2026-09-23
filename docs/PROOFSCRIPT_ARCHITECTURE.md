# ProofScript canonical architecture

Status: **normative anti-drift architecture**.

ProofScript is a small general-purpose language for the JavaScript ecosystem
with Lean-compatible dependent types, theorem proving, and formal
verification. Surface syntax may be smaller and more familiar than Lean, but
semantic acceptance must not bypass Lean-compatible elaboration and pskernel.

## Canonical pipeline

```text
ProofScript source
        |
        v
   syntax / names
        |
        v
 Lean-compatible elaboration
        |
        v
checked dependent core
        |
     +--+----------------+
     |                   |
 proofs / specs     executable terms
     |                   |
 pskernel           verified erasure
                         |
                         v
                    compiler IR
                         |
                         v
                   TypeScript
                         |
                         v
                  tsc -> JavaScript
```

## Package ownership

- `@proofscript/syntax`: source grammar and source ownership only.
- `@proofscript/meta` / `@proofscript/elab`: untrusted Lean-compatible
  elaboration.
- `@proofscript/checked-core`: stable boundary containing declarations
  re-admitted by pskernel.
- `lean-ts-kernel`: proof/type acceptance authority and TCB.
- `@proofscript/erasure`: removes type/proof-only content from checked core.
- `@proofscript/compiler-ir`: runtime-oriented executable representation.
- `@proofscript/backend-ts`: verified IR to TypeScript text.
- `@proofscript/compiler`: orchestration from checked core to TS/JS.
- TypeScript Compiler API: TypeScript type-checking/emission to JavaScript,
  declarations, and source maps.

## Non-negotiable invariants

1. The kernel never imports an outer ProofScript package.
2. Checked core cannot be created by trusting parser/compiler metadata; its
   declarations are replayed through pskernel.
3. Erasure consumes checked core, never raw syntax or the legacy software HIR.
4. The verified compiler consumes checked core/verified IR, never source AST.
5. TypeScript/JavaScript output has no authority over proof acceptance.
6. Erased proof/type values may not survive in executable code. If they do,
   compilation fails closed.
7. Unsupported elaboration/erasure never falls back automatically to the
   legacy software checker.
8. ProofScript conveniences may change syntax, not Lean-compatible meaning
   where dependent types, propositions, inductives, recursion, typeclasses,
   or theorem checking are involved.

## Transitional legacy software path

The existing `@proofscript/language` software checker and
`software.ts` compiler-IR lane remain temporarily because they cover more
ordinary programming constructs than the verified-core lane today.

They are **not** the target architecture and must not gain new foundational
semantics that compete with Meta/Elab/pskernel.

Migration policy:

1. add/repair the construct in Lean-compatible syntax/meta/elab;
2. obtain a pskernel-admitted checked-core declaration;
3. implement semantics-preserving erasure/lowering;
4. move backend/runtime coverage to verified IR;
5. only then retire the corresponding legacy software path.

## Current executable proof of architecture

The current vertical regression includes:

```proofscript
function identity {α : Type}(x : α) : α := x;
```

It is:

1. parsed as ProofScript;
2. dependently elaborated;
3. re-admitted into `@proofscript/checked-core` by pskernel;
4. erased so `α` is absent at runtime;
5. lowered to verified compiler IR;
6. emitted as TypeScript equivalent to
   `identity<T0>(x: T0): T0`;
7. compiled by TypeScript to JavaScript `identity(x)`;
8. emitted to `.d.ts` with the generic type preserved.

This is the reference direction for all future language/compiler work.


## Verified Nat programming checkpoint

The canonical path now also covers composing ordinary checked functions:

```proofscript
function add(x : Nat, y : Nat) : Nat := x + y;

function twice(x : Nat) : Nat :=
  add(x, x);
```

For the current bounded notation milestone, `+`, `-`, and `*` are accepted
only at `Nat`. Elaboration produces the real Lean constants
`Nat.add`, `Nat.sub`, and `Nat.mul`; erasure then maps those checked
applications to explicit verified-IR intrinsics.

This is intentionally narrower than pretending to have Lean's general
`HAdd`/typeclass notation already. General overloaded notation must wait for
the real typeclass-synthesis layer.
