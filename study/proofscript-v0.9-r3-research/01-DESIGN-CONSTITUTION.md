# r3 Design Constitution

Status: **normative for this research workstream; not yet normative for ProofScript releases**

## 1. Preserve meaning before appearance

ProofScript exists to make Lean-oriented programming easier to approach without creating an approximate Lean.

For accepted r3 source <code>p</code> in environment <code>E</code>, the intended relationship remains:

~~~text
parsePS_r3(E, p) = surface
lower_r3(E, surface) = canonicalLean
meaningPS_r3(E, p) = meaningLean434(lowerEnv(E), canonicalLean)
~~~

Unsupported or ambiguous input rejects. The equation defines intended meaning; it does not prove that an implementation satisfies the relation.

## 2. One semantic language

<code>ps-standard</code>, <code>ps-lean-extensible</code>, and supported <code>.lean</code> source share the same logical foundation.

Profiles may restrict syntax, metaprogramming, runtime capabilities, or package behavior. They must not assign different meanings to the same admitted core declaration.

## 3. Ordinary programming must be straightforward

An application developer should be able to use functions, records, variants, collections, typed errors, IO, resources, async operations, npm packages, tests, and UI libraries without first learning advanced proof tactics.

Verification is progressively available on the same definitions rather than requiring a second implementation language.
## 4. Familiarity must not lie

A TypeScript-looking form is useful only when the resulting expectations are close enough to be teachable.

A feature is rejected when its visual similarity creates a materially wrong expectation about:
- arity;
- evaluation order;
- mutation;
- nullability;
- exceptions;
- async start/cancellation;
- object identity;
- structural assignability;
- theorem evidence.

This criterion motivates the r3 call and brace redesign.

## 5. Go-like simplicity is methodological

The project borrows Go's concern for compact, analyzable syntax, explicit dependency structure, integrated formatting, predictable tooling, long-term maintenance, and resistance to overlapping mechanisms.

ProofScript does not copy Go's type system, error model, concurrency syntax, or restriction on metaprogramming.

Instead, r3 isolates Lean's open syntax machinery in an explicitly extensible profile so ordinary application code can have a closed syntax environment.

## 6. Evidence is typed

The toolchain must distinguish parsed, elaborated, admitted, contract-theorem accepted, termination-proved, source-correspondence, erasure-preserved, target-preserved, artifact-bound, runtime-assumed, and test-observed states.

No single <code>verified=true</code> field is sufficient.
## 7. Keep the kernel small; evaluate frontend complexity separately

A feature can add no kernel rule and still make the language difficult to reason about.

Every frontend feature must report:
- parser ownership;
- composition with imported syntax;
- lowering;
- hygiene;
- diagnostics;
- formatter/LSP behavior;
- migration;
- proof obligations;
- backend effects.

## 8. Profiles and extensions fail closed

Unknown syntax registration, package capability, foreign type, proof assumption, runtime primitive, or target lowering is not treated as an invitation to guess.

The strict result is one of: unsupported; incompatible environment; elaboration failure; kernel rejection; incomplete proof; resource limit; cancelled; or internal error.

## 9. AI may propose; independent mechanisms decide

AI is allowed to generate implementation code, proof code, invariants, adapters, schemas, and candidate specifications.

An implementation repair must not silently weaken an approved postcondition, strengthen a precondition, redefine a predicate, add an axiom, enable a foreign capability, modify the verifier, or downgrade an assurance policy.

Specification changes remain legitimate but are a distinct review operation.
## 10. Application semantics do not come from JavaScript

Direct JS and direct Wasm are target routes.

JavaScript Promise, thrown exceptions, prototype objects, number arithmetic, garbage collection, and DOM identity do not define ProofScript's source semantics.

Likewise, Wasm validation establishes target well-formedness, not the source contract.

## 11. Compatibility has dimensions

Record separately source syntax, elaboration, logical theory, proof scripts, library APIs, package resolution, runtime ABI, FFI mapping, and target preservation.

A change can preserve one dimension and break another.

## 12. Freeze criteria

A surface feature can freeze only when:
1. its grammar and AST are explicit;
2. ownership and ambiguous neighbors are tested;
3. canonical lowering is explicit;
4. diagnostics and formatter behavior are defined;
5. migration is defined;
6. representative interactions are exercised;
7. the evidence status is honest;
8. user studies have tested high-risk familiarity decisions.

A language reference is not frozen merely because it is long or internally consistent.