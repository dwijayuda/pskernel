# r3 Migration from v0.9-r2

Status: **accepted r3 migration plan; migrator not implemented.**

## Rule

Migration parses r2 under r2 grammar first. It never reinterprets raw text directly as r3 when that could change meaning.

## D-CALL

A nonempty r2 owned call such as `f(x,y)` remains an r3 call.

An **empty** r2 D-CALL `f()` meant an explicit Unit application. To preserve r2 meaning mechanically, the migrator emits:

~~~proofscript
f(())
~~~

in r3.

The new r3 `f()` empty-invocation semantics (defaults/auto insertion plus one possible Unit synthesis, with required-non-Unit rejection) is available only to source authored/accepted under r3. Migration does not silently reinterpret an old empty call.

r2 native f (x,y), which means one tuple argument, becomes:

~~~proofscript
f((x, y))
~~~

in r3.

Comments/trivia move structurally with source maps.

## Structural braces

r2 owned structure/class fields are emitted with commas **between** r3 fields; the migrator does not add a trailing field comma.

Match/inductive markers remain bars.

Instance/where brace sequences receive the explicit separator required by the r3 owned-brace grammar.

Nested native do/tactic syntax is preserved by AST category.

## Zero-argument functions

r2 rejected function f() can become valid only when r3 edition is explicitly selected. No existing accepted r2 declaration silently gains a Unit parameter.

## const

No semantic migration while const remains retained. If future usability study removes it, parameterless const maps mechanically to def.

## Profiles

Analyze dependency syntax/meta registrations.

- projects within closed Standard closure may select ps-standard;
- projects requiring custom notation/macros/elaborators use ps-lean-extensible;
- Standard packages may consume Extensible semantic bundles without importing syntax/meta exports.

No silent profile downgrade.

## Contracts

r2/experimental Lean intrinsic contracts are not silently relabelled as stable PSC-owned contracts.

Migrator classifies each contract:

- directly expressible in stable r3 contract core;
- requires compatibility/oracle profile;
- needs manual specification rewrite;
- unsupported.

Proof evidence must be rebound to normalized r3 specification identity.

## Runtime/application APIs

Do not rewrite Promise/Task/error/resource behavior by source syntax alone. Library migration requires explicit API/version adapters.

## Verification

Migration success means:

- source parsed under old grammar;
- intended r3 AST produced;
- canonical meaning compared where supported;
- theorem/spec dependencies preserved;
- assumptions not strengthened silently.

Formatting alone is not migration.

## Diagnostics

- PS_R3_CALL_TUPLE_MIGRATION_REQUIRED
- PS_R3_PROFILE_SELECTION_REQUIRED
- PS_R3_CONTRACT_REVIEW_REQUIRED
- PS_R3_EXTENSION_NOT_STANDARD
- PS_R3_RUNTIME_MODEL_CHANGED

## Rollback

Keep r2 source and build metadata available until r3 migration is reviewed. Generated r3 source is a new artifact, not retroactive reinterpretation of archived r2 evidence.
