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


## Foundation checkpoint

Phase C now has executable TypeScript foundations for compiler IR, runtime values, and TypeScript emission. The current IR supports literals, variables, lambdas, calls, lets, conditionals, and tagged constructors, with traversal/free-variable analysis. Runtime coverage is intentionally narrow (Nat/Int basics, UInt8, tagged constructors). The TS backend emits deterministic ESM for this structural subset.

Kernel-Expr lowering, erasure proofs, closure conversion, optimization passes, source maps, and direct workspace wiring remain open milestones.


## Verified-core architecture checkpoint

The compiler stack no longer needs a source-level checker on its preferred
path. `@proofscript/checked-core` is the input contract.

```text
CheckedCoreModule
  -> @proofscript/erasure
  -> VerifiedIrModule
  -> @proofscript/backend-ts
  -> TypeScript Compiler API
```

The first supported verified-core erasure slice handles generic functions,
runtime functions/variables, applications, lambdas, lets and literals.
Type binders become TypeScript generics for API fidelity but disappear from
JavaScript; proof binders are removed entirely. Unsupported executable core
forms fail closed.

The older `CheckedSoftwareModule -> SoftwareIrModule` path is transitional
and must shrink as verified-core lowering expands.

## Full-stack web / JSX backend extension

Detailed execution plan:

- `docs/plans/07_FULLSTACK_WEB_PSX.md`

The TypeScript/JavaScript backend remains the primary host path. Web support
extends it rather than creating a second compiler.

The intended framework-neutral layering is:

```text
checked core
  -> erasure
  -> verified runtime IR
  -> JSX/component lowering where applicable
  -> ESM JavaScript / automatic JSX-runtime calls
  -> Vite / Next.js / host runtime
```

Requirements:

- JSX syntax is gone before checked-core/compiler trust boundaries that do not
  explicitly own it;
- React-specific runtime calls are introduced only in outer compiler/adapter
  packages;
- source maps preserve `.psx` locations;
- direct Vite/Next loader output and any generated-shadow-tree fallback must
  derive from the same checked core / verified IR;
- React/Next/DOM/Node behavior is external runtime behavior, not a theorem
  checker oracle;
- compiler/runtime correctness claims remain distinct from source proof
  checking.

A generated `.tsx`/`.ts` shadow tree is permitted as a diagnostic/fallback
integration strategy, but the target developer experience is direct
`.ps`/`.psx` authoring through supported Vite/Turbopack transform hooks.

