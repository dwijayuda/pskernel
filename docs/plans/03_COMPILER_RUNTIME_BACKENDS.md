# Compiler, runtime and backend plan

Status: after frontend can produce stable checked declarations.

Lean 4.34 analogues:
- `Lean.Compiler.IR`
- `Lean.Compiler.LCNF`
- lowering/codegen passes
- `src/runtime`

## Principle

Do not use kernel Expr as the final code-generation IR.

Logical expressions optimize for type theory and checking; executable IR needs explicit runtime structure.

## @proofscript/compiler-ir MVP

- typed runtime-oriented IR
- erased/proof-irrelevant nodes
- functions/closures
- ADTs/constructors
- primitive operations
- control flow
- module imports/exports
- pass framework

Early passes:
- erasure
- normalization/lowering
- closure conversion
- lambda lifting
- simple specialization
- dead-code elimination

## @proofscript/runtime MVP

Use JavaScript primitives where Lean-compatible semantics are cheap and clear.

Provide explicit runtime support only where needed:
- Nat/Int edge semantics
- UInt families
- Char/String
- arrays/byte arrays
- ADT tagging
- hashing/equality helpers
- selected IO/task abstractions

Avoid cloning Lean's native allocator/GC.

## @proofscript/backend-ts MVP

- compiler IR → ESM JS/TS
- deterministic imports
- source maps
- readable generated names
- runtime imports
- Node + modern browser targets

## Correctness strategy

Separate:
1. logical proof-checking correctness,
2. compiler semantic preservation,
3. runtime behavior.

Initially test compiler/runtime differentially. Formal compiler correctness can be layered later.

## Non-goals

- multiple backends before TS is stable
- pretending compilation is trusted because source proofs are trusted
- embedding host JS evaluation into the kernel
