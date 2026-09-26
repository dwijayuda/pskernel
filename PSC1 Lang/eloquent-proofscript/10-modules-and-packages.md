# 10. Modules and Packages

Large programs need boundaries.

Modules make names and dependencies explicit.

Packages make modules reusable across projects.

## Imports

PSC1 uses logical imports:

```proofscript
import ProofScript.Data.Option
import ProofScript.Data.List
```

A logical name resolves below configured source roots.

## Source candidates

For:

```text
Foo.Bar
```

a source root may contain:

```text
Foo/Bar.ps
Foo/Bar.lean
```

Exactly one candidate must win.

If more than one exists, resolution fails.

## Why ambiguity fails

A module graph should not change meaning because someone reordered
`sourceRoots`.

Deterministic resolution is part of reproducible compilation.

## Mixed-source projects

PSC1 supports native ProofScript and the bounded Lean subset in one project.

Example:

```text
App.ps
  -> Data.lean
     -> Logic.ps
```

The source extension chooses the frontend.

All declarations eventually enter the same checked environment.

## Module design

A good module has a small public idea.

For example, a data module might expose:

```text
PsOption
optionMap
optionBind
optionGetOrElse
selected theorems
```

and keep representation-specific helpers internal to the package convention.

## Packages

ProofScript intends to use the npm ecosystem rather than inventing another
package registry.

A package can contain:

- `.ps` sources;
- generated JS;
- declarations/source maps;
- package metadata;
- assurance/trust metadata.

## package.json and psconfig.json

They have different responsibilities.

`package.json` belongs to the npm/runtime ecosystem.

`psconfig.json` configures ProofScript compilation, including:

- entry;
- source roots;
- runtime dependencies;
- compiler output.

## Runtime dependencies

The current FFI policy requires exact package-root versions in
`runtimeDependencies`.

This makes host assumptions easier to reproduce and audit.

## Reuse without copying

A package should let many applications depend on the same maintained code
rather than copying modules into each project.

This is especially valuable for verified libraries: one carefully checked
implementation and theorem set can become shared vocabulary.

## Semantic versioning is not proof

A version number helps humans manage compatibility.

It does not prove that a theorem still holds or that a backend is correct.

Proof and conformance artifacts need their own evidence.

## Exercises

1. Split a small program into `Data`, `Logic`, and `Main` modules.
2. Construct an example that would be ambiguous if two source roots contained
   the same logical module.
3. Decide which metadata belongs in `package.json` and which belongs in
   `psconfig.json`.
4. Design a minimal public interface for a reusable queue library.
