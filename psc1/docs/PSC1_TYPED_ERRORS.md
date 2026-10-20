# PSC1 typed errors: one checked handler boundary

Status: qualified selected subset at 5496943a30423269654fffcd7579b3c5dd16b4f9 in [PR #169](https://github.com/dwijayuda/pskernel/pull/169), [Linux run 39495181966](https://github.com/dwijayuda/pskernel/actions/runs/39495181966).
Preserved integration: latest PR #166 at da880d864ca5f9e35729255fd7e4f8a17953cd39 plus PR #167 a830668d2c23886843e616951836d8d990aa2ff5 through #168.
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

## Qualified evidence

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

The final corpus has 34 native Lean result observations (plus two tool identities),
28 target/source bundles and 70 refusal checks; minimum Python repeats four bundles
and ten refusals. All seven fast native control groups pass, including reverse
canonical graph roundtrips and exact pattern-handler scalar observations.
The errorPatternFor fixture distinguishes false=ok3 and true=error9; a later
iteration's error cannot enter the preceding pattern arm's catch. Terminal compound
printing keeps match alternatives grouped rather than relaxing dedent ownership.
See the immutable foundation receipt for exact commits, run, tools and artifact hash.
