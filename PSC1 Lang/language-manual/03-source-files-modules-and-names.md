# 3. Source Files, Modules, and Names

PSC1 projects are deterministic module graphs.

## Source kinds

```text
.ps       native ProofScript
.lean     bounded supported Lean subset
```

The source kind selects a frontend/printer.

It does not select a different kernel or backend semantics.

## Imports

```proofscript
import Foo.Bar
```

A logical module name maps to a relative path:

```text
Foo/Bar.ps
Foo/Bar.lean
```

under configured source roots.

## Source roots

`psconfig.json` may define:

```json
{
  "sourceRoots": ["src", "vendor"]
}
```

Every root is project-relative.

If no roots are configured, resolution falls back to the entry source
directory.

## Ambiguity

Exactly one source candidate must exist for a logical module.

If multiple roots or both extensions provide candidates, resolution fails.

Root order is not precedence.

## Names

PSC1 preserves qualified-name semantics suitable for Lean-compatible
environments and deterministic module resolution.

The self-host compiler requires names as data because parser/elaborator
environments manipulate declarations by name.

## Environment visibility

A module sees its imported checked dependencies according to the deterministic
dependency graph.

Unrelated sibling declarations must not leak into elaboration through ambient
global process state.

## Mixed-source graph

A valid graph may contain:

```text
App.ps -> Data.lean -> Logic.ps
```

All nodes converge into the same checked environment model.

## Canonical source identity

Equivalent supported `.ps` and `.lean` forms may canonicalize to a common
semantic/source identity for cache and regression purposes.

Textual formatting identity is not required.

## Namespaces/sections

Full Lean namespace/section/open behavior is not a first-freeze requirement.

PSC1 implements only the bounded naming/environment features needed by the
frozen compiler and supported source profile.

## Module integrity

Build artifacts may record:

- direct dependency integrity;
- module semantic compatibility;
- canonical source hash;
- ordered project integrity.

Integrity identifies what was checked. It does not replace kernel checking.
