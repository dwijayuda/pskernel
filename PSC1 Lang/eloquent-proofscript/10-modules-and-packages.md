# 10. Modules and Packages

Large programs need boundaries.

A module gives a piece of source:

- a logical name;
- explicit dependencies;
- a checked environment;
- an interface to other modules.

## Imports

```proofscript
import ProofScript.Data.Option
import ProofScript.Data.List
```

PSC1 uses logical module names.

A module can resolve to a supported `.ps` or bounded `.lean` source.

## Deterministic resolution

For a logical module, the project must find exactly one source candidate.

If both:

```text
Foo/Bar.ps
Foo/Bar.lean
```

are viable, that is ambiguity, not priority.

Likewise, multiple source roots must not silently make "first one wins" part of
the language.

## Interfaces

A good module exposes a small vocabulary that lets callers solve one coherent
problem.

Examples:

```text
ProofScript.Data.Option
ProofScript.Data.Result
ProofScript.Data.List
ProofScript.Data.Map
ProofScript.Text.Lexer
```

This is the PSC1 counterpart of keeping a module focused and predictable.

## Dependency direction

Avoid circular architecture where parser, elaborator, kernel bridge, backend,
and CLI all depend on one another.

A useful compiler dependency direction is:

```text
foundation
-> syntax
-> environment/meta
-> elaboration
-> checked core
-> erasure
-> IR
-> backend
-> CLI
```

Exact package layout may differ, but semantic layering should remain visible.

## npm as package substrate

PSC1 intentionally participates in the JavaScript/npm ecosystem.

`package.json` handles ecosystem packaging.

`psconfig.json` handles ProofScript compilation.

These roles are distinct.

## Runtime dependencies

For named ESM FFI, runtime package roots are declared separately and pinned
according to the current reproducibility policy.

npm metadata does not become proof evidence.

## Mixed-source modules

A project can contain:

```text
App.ps
Data.lean
Logic.ps
```

Source kind is a frontend fact.

All modules converge before semantic admission.

## Exercises

1. Split the Delivery Planner project into `Model`, `Route`, and `Main`
   modules.
2. Draw the dependency graph.
3. Construct an ambiguous module-resolution example and predict the compiler
   error.
4. Explain why package-lock integrity and pskernel proof validity are different
   forms of assurance.
