# Owned natural literals checkpoint

Integration base: `bb0f71177173f260e95f59d230edadf0669841b8`.
Package: `@proofscript/pskernel-core@0.1.0-checker.8`, private and experimental.
The generated owned kernel is the default and its 20 source modules are in the
75-module portable compiler/bootstrap closure. Lean WASM and native Lean are
explicit reference alternatives outside that closure. There is no fallback.

## Change and trust boundary

Natural literals now type check after the owned bootstrap admits Nat. The
generated checker records an internal `natFamily` marker only after checking
the family and constructors. Literal checking requires this marker and the exact
standard zero/successor names. An opaque constant or unit family called Nat
cannot provide literal authority; ordinary admission rejects supplied markers.

Conversion expands literals to zero/successor one bounded step at a time, using
the source binary-natural predecessor. Literal typing, metadata lookup, name
comparison, reduction and bootstrap share the transition budget. Exhaustion,
unsupported input and failed checks reject. The host only decodes canonical
wire naturals and drives the generated checker. Generated JavaScript was built
from source, never repaired by hand.

This does not implement projections, string literals, arithmetic primitives,
general constructor fields, indexed or mutual families, proof irrelevance or
eta. Finite regression comparisons are evidence, not a soundness proof.

## Verified identities

| Item | SHA-256 |
| --- | --- |
| Source manifest | `1dc2ac98c0b0cb1c62b3bc939aebe8ad7e1e77ffd9935e0f5117215e5d33869c` |
| Generated kernel JavaScript | `b6cd263e52d02ac20f0937bc5e8758d3da9d48dcb3cf2aa7a5fc1e71f9054105` |
| Generated kernel TypeScript | `18cfa72bc9862a2e5aee80491e7d201c8d5b521a9566ff7c610f8f5891064cb4` |
| Literal comparison records | `a0ca588308b26dc9f9888854c8c63b611233e183802a52b050ae9f1336b5d2e9` |
| Preserved PSC build seed | `a0673677219da539df555961129385ae4cf5099f303f0c883dd3a26f726449ff` |

Lean 4.34.0 is pinned at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`;
TypeScript is 5.8.3. The isolated candidate passed both PSC frontends, canonical
PS/TypeScript parity, strict TypeScript compilation and native Lean checking of
all 20 modules (592 declarations). All 417 Linux tests pass, including the
original 264-test baseline and 21 new literal cases. Fresh native comparisons
match in 122 literal cases (70 accepted, 52 rejected). All previous oracle,
universe, term, polymorphic, unit and Nat evidence was regenerated and
`verify-evidence.mjs` passes against this source identity.

The integrated source guards and 72 focused Windows integration tests pass.
These include real Lean and ProofScript literal source passing the default owned
check, exact-module emission, TypeScript compilation and JavaScript execution
returning `42n`; canonical wire validation; forged metadata rejection; and budget
exhaustion. Longer integration/replay runs are recorded separately.

## Actual complete-input blocker

The full current closure was prepared and preserved in
`work/full-owned-literal-bb0f7117`. Its 75-source closure hash is
`6905d97ae41dc4d62eff1c80fe3bafe6e77586c77d3a56ae6249eb31b7280fe2`;
admissions hash is
`20715347d21c3151b02207cb0b17e4827fa098c1c97861c6438df79b2863a722`.
The default check rejects with `unsupported-expression:proj` at admission 9
(`psLexCursorDone`). The decoder visits the complete batch before semantic
checking, so this does not mean the preceding declarations all passed. The
exact prefix still independently demonstrates that admission 1, `PsSourcePos`,
requires constructor fields. Projection admission must depend on validated
record metadata and bounded typing/reduction; accepting its wire form alone
would not solve this blocker.

## Compiler result and release status

The protected 72-module reference replay completed successfully: native and
generated admissions, emitted TypeScript and recompiled JavaScript match.
All 72 canonical source translations also match, including stable PS re-emission.
See `REFERENCE_REPLAY_2026-10-03.md` for exact identities and limitations. The
ongoing canonical child replay uses that preserved snapshot and must not be
overwritten or interpreted as validation of this newer 75-module source.

The generated owned kernel has not admitted the complete compiler/kernel/prelude
closure. A generated owned pair has not rebuilt the next checked pair. Joint
self-hosting and authoritative release gates remain closed.
