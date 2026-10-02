# PSC2 to PSC3 Migration

Status: **migration design draft**

PSC3 is a proposed language edition.

It must not silently reinterpret PSC2 source.

## 1. Migration principle

The migration objective is semantic continuity where intended, not textual identity.

For each changed construct:
- parse it under the PSC2 profile;
- identify its existing meaning;
- produce explicit PSC3 source;
- compare canonical meaning where possible;
- report constructs that cannot be migrated automatically.

## 2. Edition/profile selection

Projects should declare a source edition/profile.

Conceptually:

~~~text
edition = "psc2"
edition = "psc3"
~~~

The compiler does not guess based on syntax when ambiguity could change meaning.

## 3. Call syntax

PSC2 native source can distinguish adjacent calls from whitespace-separated Lean-neighbor syntax.

PSC3 .ps removes this distinction.

Migration tool:
- parses with PSC2 grammar;
- rewrites the existing AST to explicit PSC3 calls/tuples;
- formats canonical PSC3;
- reports any ambiguous/unsupported source.

It must not perform a text replacement.

## 4. Imports/exports

PSC3 proposes explicit ESM-like native import/export syntax.

PSC2 module declarations/imports should be rewritten through module-graph-aware migration.

Visibility changes require warnings because package public API may change.

## 5. Declaration spelling

If PSC3 selects function/const as canonical native application declarations while retaining def for compatibility:
- migration may preserve def by default;
- formatter/profile may offer an application-style rewrite;
- semantic behavior must stay unchanged.

This is not a reason to reject existing theorem-oriented style.

## 6. Result parameter order

PSC3 standardizes:

~~~text
Result(A, E)
~~~

PSC2 source/docs that use inconsistent order must be resolved from actual declaration meaning, not string position assumptions.

Migration tests should catch all standard-library call sites.

## 7. Optional syntax

If PSC3 adopts:

~~~text
field?: T
x?.f()
x ?? y
~~~

PSC2 Option code need not be rewritten.

These are convenience forms over Option, not a new required model.

## 8. Modules and package manifests

PSC2 project configuration should be convertible to the PSC3 package manifest.

Migration reports:
- target profiles;
- package dependencies;
- plugin dependencies;
- FFI capabilities;
- public exports;
- backend-specific assumptions.

## 9. Backend changes

PSC3 proposes direct JS and direct Wasm as strategic targets.

A PSC2 project that emitted TS/Rust/Wasm should preserve target selection explicitly during migration.

Possible statuses:
- direct equivalent available;
- compatibility emitter;
- unsupported target;
- requires adapter.

Do not silently change runtime semantics because the backend implementation changes.

## 10. .lean source

Existing supported .lean source remains governed by its pinned Lean profile.

Migrating a project to PSC3 does not rewrite .lean into .ps automatically unless the developer explicitly requests translation.

Lean version/profile changes are separate migration events.

## 11. Verification

PSC2 contracts/proofs migrate only when:
- specification meaning is preserved;
- referenced definitions are mapped;
- assumption policy is preserved;
- proof evidence can be rechecked/reconstructed.

A successful syntax rewrite is not proof-preservation evidence.

## 12. FFI

Foreign declarations need PSC3 effect/trust metadata.

Migration should classify old bindings:
- safely inferred;
- requires review;
- unverified dynamic;
- unsupported.

It must not label old foreign code verified.

## 13. Plugins/extensions

PSC2 experimental extension mechanisms may not have direct PSC3 equivalents.

Migration should favor:
- libraries;
- source sugar;
- typed registries;
- controlled plugins;

rather than preserving unrestricted extension behavior for compatibility.

## 14. Formatter

After semantic migration, PSC3 formatter produces canonical source.

Formatting-only changes should be separated from semantic migration in tooling/diffs where practical.

## 15. Migration command

Proposed UX:

~~~text
psc migrate --from psc2 --to psc3
~~~

Modes:
- check only;
- generate patch;
- apply;
- explain changes.

Every semantic rewrite receives a diagnostic/change code.

## 16. Migration assurance

For modules in the supported common profile, the tool should compare:
- canonical declarations;
- type/proof statements;
- RuntimeIR for executable definitions;
- relevant assumptions.

Exact source text differs by design.

## 17. Deprecation policy

PSC3 should not carry every PSC2 surface indefinitely.

Deprecations need:
- rationale;
- automated migration where possible;
- release schedule;
- clear error after removal.

Compatibility aliases that add little complexity may remain.

## 18. Migration test corpus

Use:
- PSC2 compiler source;
- stdlib modules;
- theorem examples;
- application-style programs;
- contract examples;
- FFI packages.

Migration is successful when representative projects continue to mean the same thing—not merely when they parse.

## 19. No silent downgrade

If a PSC2 feature cannot retain its proof/portability semantics in PSC3, migration fails with an explicit explanation.

The tool never silently emits an unverified escape and calls migration successful.
