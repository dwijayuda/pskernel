# 4. Definitions and Declarations

PSC1 uses a small declaration set.

## `def`

Canonical general definition:

```proofscript
def answer: Nat := 42;
```

## `const`

Parameterless alias of `def`:

```proofscript
const answer: Nat := 42;
```

It does not mean JavaScript deep immutability.

## `function`

Parameterized alias of `def`:

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

At least one explicit declaration parameter group is required.

It does not add JavaScript function semantics.

## `theorem`

```proofscript
theorem selfEq(x: Nat): x = x := by rfl;
```

A theorem elaborates a proof term whose type is a proposition.

Its admission is checked by pskernel.

## `structure`

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

Introduces structure type, constructor, and projections according to the
supported semantic model.

## `inductive`

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

Introduces type constructor, constructors, and recursor/elimination data.

## `class`

Declares typeclass evidence.

A class is not an OOP class.

## `instance`

Registers/supplies evidence for bounded instance synthesis.

The exact source forms are determined by the PSC1 feature matrix rather than
all Lean instance conveniences.

## `extern function`

Current repository-defined runtime extension:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

It carries logical signature plus runtime binding metadata.

It is not proof evidence.

## Local `where`

The registered braced `where` form supports bounded local declarations.

Local/mutual recursion convenience beyond the implemented subset is not
implicitly inherited from Lean.

## Declaration semicolons

PSC1-owned declaration forms may use the v0.7 declaration terminator style.

Canonical Lean output omits ProofScript-only semicolons where Lean syntax does.

## Canonical formatting

PSC1 source printer uses:

```proofscript
name: Type
```

while canonical Lean output uses:

```lean
name : Type
```

Spacing is stylistic, not semantic.
