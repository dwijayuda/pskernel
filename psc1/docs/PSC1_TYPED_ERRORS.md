# PSC1 typed errors: one checked handler boundary

Status: implementation awaiting its own focused Linux qualification.
Base: PR #166, `1e63628169459539783450e28c641f3f70bf701f`.
Semantic authority: official Lean 4.35.0,
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

## Selected syntax and semantics

Inside typed do, native Lean accepts `try ... catch error => ...` with
selected layout or braces. PS uses `try { ... } catch error => { ... }`.
`throw error` uses the current Except or checked CompilerM error type.
Contextual `throw(error)` is equivalent; existing local/global names win.
Wrong error types, missing error channels, escaping handler binders and
catch binders shadowing a mutable local fail closed.

This slice uses one catch binder. Finally, multiple handlers, annotated
or pattern catches and arbitrary MonadExcept instances remain deferred.
Existing while restrictions and public target ABI limits are unchanged.

## Checked construction

`DoTry.lean` constructs an internal control packet using existing checked
Except and Prod definitions: `Except ReturnValue MutableState` inside
the source base effect. The packet error tag means EARLY RETURN and is
distinct from the outer typed error. Successful fallthrough carries the
visible mutable values. A base-effect failure discards those values and
enters the handler from the original lexical state. Existing CompilerM
`compilerTryCatch` also restarts from its original library state.

The packet is eliminated only AFTER the base catch. Consequently a
later throw is not accidentally caught by the preceding handler, a
handler rethrow propagates outward, and early return skips the rest.
Nested handlers and parenthesized do computations preserve their own
return boundaries. No target exception instruction or unchecked control
primitive is added. Source admission and typed IR validate all terms.

The pinned design reference is Lean's
`src/Lean/Elab/BuiltinDo/TryCatch.lean`: it explicitly explains why a
following continuation cannot be pushed under tryCatch. The PSC1 code
is an independent bounded construction using its existing Core helpers.

## Evidence to collect

The exact reference fixtures compile under pinned native Lean and PSC1,
then translate to PS. Native tests cover admission, strict IR, canonical
graph roundtrips, lexical scopes and actual CompilerM rollback. Runtime
tests compare base error tags and payloads, success, nested/rethrown
errors, capture snapshots, loop exits and post-handler errors on seven
targets through public Bool predicates. Ordinary while is separately
classified. Minimum Python repeats both lanes and grammars.

Previous artifact generations must survive wrong-source, checked/partial
and unavailable-verified requests. Neither runtime comparisons nor
kernel admission proves backend semantic preservation. All original
qualification receipts remain historical and unchanged.
