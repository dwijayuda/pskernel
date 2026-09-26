# 7. Programming, Proving, and Performance

A verified language is most useful when proofs can support efficient code
instead of forcing every program into a slow specification style.

PSC1 follows the same principle.

## Specification and implementation can differ

A simple recursive function may be easiest to understand and prove correct.

A faster implementation may use:

- arrays;
- accumulator/tail-recursive loops;
- fixed-width arithmetic;
- backend-specialized data representation.

A theorem can relate the optimized version to the simpler specification.

## Structural recursion first

For the first language freeze, structural recursion is the preferred executable
and logical mechanism.

It is easy to explain, check, and reproduce across hosts.

## Tail-recursive implementations

A tail-recursive function can use an accumulator to improve runtime behavior.

If the transformed implementation is less obviously equivalent to the simple
definition, a proof of equivalence is valuable.

PSC1 should not add a semantic special case merely because one backend performs
tail calls differently.

## Arrays and bounds

Array algorithms often need efficient indexed access.

A proof of an index bound can justify an unchecked/verified internal access
without repeating a dynamic bounds check.

Whether a specific backend can eliminate the check is an optimization issue;
the source contract remains the proof.

## Controlled partiality

Some compiler algorithms are awkward under the deliberately small first
termination checker.

PSC1 therefore allows a controlled executable `partial def` boundary.

Partial executable code is not allowed to become proof authority.

## Machine integers

PSC1 freezes:

```text
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
```

These are not aliases for whatever integer representation a backend happens to
prefer.

Correct optimization requires the normative overflow/conversion semantics.

### Current freeze status

The type vocabulary is frozen.

The complete scalar operation/conversion matrix remains an explicit SH7 freeze
obligation in the baseline used by these docs.

Until it closes, backends must not invent corner-case behavior and label it
PSC1 semantics.

## Floating point

`Float` and `Float32` are computational types.

Proofs involving floating behavior must respect the frozen IEEE/Lean-compatible
contract; target fast-math or relaxed semantics cannot silently replace it.

## Backend optimization boundary

The shared pipeline is:

```text
CheckedCore
-> Erasure
-> VerifiedIR
-> target-specific lowering
```

Optimizations before target lowering should be stated in target-neutral PSC1
semantics.

Target-specific representation optimizations happen later.

## Proof correctness is not compiler correctness

Proving:

```text
fast(x) = spec(x)
```

inside PSC1 establishes a logical relationship between definitions.

It does not by itself prove that every backend translates `fast` correctly.

Backend conformance requires separate assurance and differential tests.

## Next

Continue to [Next Steps](./08-next-steps.md).
