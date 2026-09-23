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
        +---- pinned Lean 4.34 environment
        |     (pskernel-admitted Init.Prelude)
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
- `@proofscript/environment`: shared pinned Lean 4.34 environment replay used by compiler and tooling.
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

For the current bounded notation milestone, `+`, `-`, `*`, `/`, and `%`
are accepted only at `Nat`. Elaboration produces the real Lean constants
`Nat.add`, `Nat.sub`, `Nat.mul`, `Nat.div`, and `Nat.mod`; erasure then
maps those checked applications to explicit verified-IR intrinsics. Runtime
division/modulo preserve Lean's total Nat semantics: division by zero yields
`0`, while modulo by zero returns the dividend.

The bounded primitive equality surface follows Lean's existing `==`/`!=`
meaning rather than redefining it as propositional equality. Nat operands use
`Nat.beq`; Bool operands use `Bool.beq`; both produce `Bool`. Inequality is
`Bool.not` of the corresponding checked equality, matching Lean 4.34's
`bne` definition. Generic `BEq` synthesis is intentionally not claimed.

The same verified Bool lane now covers `!x`, `x && y`, and `x || y` through
the actual Lean constants `Bool.not`, `Bool.and`, and `Bool.or`. Any
supported expression already checked to have type `Bool` may be used as an
`if` condition. The frontend reflects that Bool to the proposition
`Eq Bool condition true` with `Bool.decEq`; proposition-native Nat ordering
conditions continue through `LE.le`/`LT.lt` with their Nat instances and
checked deciders. Only after pskernel admission does erasure lower these
checked forms to boolean verified-IR conditions.

This is intentionally narrower than pretending to have Lean's general
`HAdd`/typeclass notation or generic `BEq` synthesis already. General
overloaded notation must wait for the real typeclass-synthesis layer.


Verified runtime intrinsics have one shared compiler-IR contract for operation
identity and arity. Validation consumes that contract, and backend-ts emits the
operation union exhaustively. There is no catch-all emission fallback: adding a
new verified intrinsic without defining its backend semantics is a TypeScript
compile-time error rather than silently changing meaning.


## Verified execution checkpoint

The CLI runtime path now consumes the semantic types retained in verified IR.
For primitive entrypoints, the complete developer flow is executable:

```proofscript
function main(x : Nat) : Nat :=
  x + x;
```

```text
psc run --verified -- 21
source
-> shared Lean 4.34 Init.Prelude environment
-> elaboration
-> pskernel checked core
-> verified erasure/IR
-> TypeScript
-> tsc JavaScript
-> verified runtime ABI (Nat)
-> main(21n)
-> 42
```

The verified CLI ABI supports primitive `Nat`, `Int`, `Bool`, `String`,
and `Unit` values plus kernel-derived structure/ADT types whose runtime fields
are representable by the verified IR. Structured values cross the CLI boundary
as strict JSON: nested Nat/Int values are decimal strings, structures are exact
field objects, and ADTs use `{"$ctor":"constructor", ...fields}`. ADT inputs
are reconstructed through the generated constructor exports so verified match
tags are genuine; results are encoded from the runtime representation back to
the same JSON-safe shape.

This boundary is untrusted input handling, not proof evidence. The accepted
shape is derived from pskernel-admitted verified IR. Function-typed values,
unknown types, unresolved type parameters, malformed constructors/fields, and
unsupported dependent runtime shapes remain fail-closed.


## Verified structure checkpoint

The preferred pipeline now also covers simple nominal structures:

```proofscript
structure User where { age : Nat; }

function make(age : Nat) : User :=
  { age := age : User };

function get(user : User) : Nat :=
  user.age;
```

The structure is first admitted as a pskernel inductive. Checked-core structure
metadata is accepted only after validation against the generated constructor.
Erasure then lowers constructor applications to branded runtime records and
kernel projections to field access. TypeScript receives a readonly nominally
branded interface.

Dependent/existential structures such as `{ T : Type; value : T }` remain
fail-closed in verified compilation until their runtime existential packaging
semantics are designed; they are not flattened into unsound structural types.


## Verified ADT constructor checkpoint

The preferred pipeline now covers simple unparameterized, non-recursive
algebraic data types and constructor values:

```proofscript
inductive MaybeNat where {
  | none;
  | some(value : Nat);
}

const noneValue : MaybeNat := MaybeNat.none;
const oneValue : MaybeNat := MaybeNat.some(1);
```

The inductive and constructors are admitted by pskernel first. Erasure derives
runtime constructor shape from pskernel `ConstructorInfo`, then verified IR
represents the ADT as a nominal tagged union. TypeScript emits an internal
unique-symbol tag plus a constructor object; JavaScript therefore preserves
constructor identity without trusting source-only ADT metadata.

Parameterized, indexed, recursive inductives and pattern matching remain
separate milestones and fail closed until their Lean-compatible core semantics
are implemented.


## Local class-instance checkpoint

ProofScript class declarations now follow Lean's kernel boundary:

```proofscript
class Boxed(α : Type) where {
  value : α;
}

function reuse {α : Type}[inst : Boxed(α)](x : α) : α :=
  x;

function caller {α : Type}[inst : Boxed(α)](x : α) : α :=
  reuse(x);
```

`Boxed` is admitted by pskernel as the same single-constructor inductive shape
used for structures. "Class" is elaborator metadata only; it does not extend
the kernel's type theory.

The first instance-synthesis slice began local-only. The current bounded
layer searches local `instImplicit` binders first and then registered global
instance definitions. When the requested class target still contains
metavariables, synthesis is postponed until later explicit arguments/result
constraints have had a chance to solve them; only then is the instance goal
retried. This prevents declaration order from prematurely fixing an otherwise
unresolved type parameter.

The resulting checked core contains the ordinary dictionary argument, so
verified erasure/backend compilation needs no typeclass-specific escape hatch.
Priorities, parameterized-instance application, recursive/table-based search,
`outParam`/`semiOutParam`, ambiguity diagnostics, and imported Lean instance
indexes remain future Meta milestones.


## Global instance checkpoint

The bounded typeclass layer now also supports definition-like global
instances:

```proofscript
class Boxed(α : Type) where {
  value : α;
}

instance boxedNat : Boxed(Nat) :=
  { value := 7 : Boxed(Nat) };

function get {α : Type}[inst : Boxed(α)](x : α) : α :=
  inst.value;

function read(x : Nat) : Nat :=
  get(x);
```

The instance is first elaborated and admitted as an ordinary pskernel
definition. Checked-core records only validated instance-registry metadata
whose final result head is a previously admitted class. Later application
elaboration may select that constant as an instance candidate. The resulting
core term contains the ordinary dictionary argument, and verified erasure
therefore lowers `read` to an ordinary runtime call equivalent to
`get(boxedNat, x)`.

Instance lookup remains intentionally smaller than Lean 4.34 `SynthInstance`:
it is non-recursive and has no priorities, parameterized-instance application,
out-parameters, ambiguity diagnostics, or imported/prelude instance index.
A regression with competing `Boxed(Nat)` and `Boxed(Boxed(Nat))` instances
locks the rule that an unresolved `Boxed(?α)` goal is postponed until a later
explicit argument fixes `?α`.

The theorem-prover slice also includes bounded single-premise `apply`.
`by apply f; next` requires the elaborated candidate to expose one explicit
Pi/function premise. The continuation constructs that premise proof; applying
it to the candidate must then be definitionally equal to the original goal.
The produced term is an ordinary application rechecked by pskernel. Candidates
requiring multiple generated goals or unresolved implicit-instance search fail
closed until the tactic state supports those cases.
