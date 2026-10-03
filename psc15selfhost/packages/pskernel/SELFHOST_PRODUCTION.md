# PSC1Kernel self-host / production migration

Branch target: `psc2/psc1kernel-selfhost-production`.

The goal is to preserve the mature Lean-4.34 behavior of PSC1Kernel while making
the checker itself compilable by the PSC1/PSC2 compiler and suitable for a
portable owned-kernel bootstrap.

## Trust rule

Do not simplify kernel semantics merely to make PSC1 compilation easier.

Lean 4.34 remains the semantic authority. Existing PSC1Kernel differential and
replay evidence remains the compatibility oracle. Source refactors must preserve
accept/reject behavior before they are allowed to replace an established path.

## Portable semantic closure

`PSC1KernelSelfHost.lean` is the production migration root. It intentionally
excludes replay/import codecs, JSON parsing, test modules, native-result map
adapters, and frontend/compiler integration. Those components may consume the
kernel, but they are not part of the semantic checker itself.

## Migration order

1. Remove host-library dependencies from the semantic closure.
2. Replace structurally recursive `partial def` declarations with total `def`.
3. Convert non-structural recursive checker loops to explicit bounded state
   machines where PSC1 cannot preserve the existing executable boundary safely.
4. Compile the complete semantic root with PSC1.
5. Translate the same root to canonical `.ps` and require checked-core parity.
6. Emit TypeScript/JavaScript and run the existing Lean-4.34 differential corpus.
7. Package the generated checker behind the checked-provider interface.
8. Only after parity, make the generated kernel eligible to replace Lean WASM.
9. Establish a joint compiler/kernel bootstrap and repeat-generation fixed point.

## Partial definitions

PSC1 permits controlled executable `partial def`, but partiality is not proof
authority. During migration they are tracked as explicit debt rather than being
silently accepted as a final trusted-kernel design.

A partial definition may remain temporarily only when failure or nontermination
cannot manufacture an accepted declaration, the boundary stays fail-closed, and
the function remains covered by direct Lean-4.34 differential evidence.

## First portability slice

The first implementation slice removes `Std.HashMap` from declaration-scoped
checker caches. The replacement uses fixed buckets backed only by portable
Array/List values and resolves collisions using `Expr.eq`. Cache hashing is
therefore non-semantic: collisions may affect performance but cannot change
kernel acceptance.

The same slice converts recursion to ordinary total definitions where direct
structural descent is already evident to Lean and PSC1.
