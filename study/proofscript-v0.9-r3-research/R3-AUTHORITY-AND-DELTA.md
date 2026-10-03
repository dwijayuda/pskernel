# r3 Authority and Complete r2 Delta

Status: **normative for the accepted `ps-0.9-r3` documentation baseline**

## 1. Why r3 is defined as a complete delta

r3 does not re-transcribe every unchanged Lean/ProofScript semantic rule. Instead it incorporates the exact accepted r2 reference by immutable content identity and overrides only the sections listed by this document and the r3 normative companions.

This makes r3 complete without risking accidental divergence in unchanged primitive/runtime/kernel/compiler-assurance text.

## 2. Immutable base

The inherited base is:

~~~text
baseline/ProofScript_Language_Reference_v0.9.0_r2.md
SHA-256 d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
grammar ps-0.9-r2
semantic pin Lean 4.34.0
commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

The vendored baseline is historical/immutable. r3 never edits its interpretation in place.

## 3. r3 composition

The normative r3 language is:

~~~text
ProofScript r3
  = exact r2 baseline
  + accepted r3 overrides
  + r3 machine-readable registries/schemas
~~~

If r3 says nothing about an r2 rule, the r2 rule remains normative.

## 4. Authority order

For `ps-0.9-r3`, conflicts are resolved in this order:

1. `ProofScript_Language_Reference_v0.9.0_r3.md`;
2. `R3-AUTHORITY-AND-DELTA.md` and `R3-GRAMMAR-AND-FEATURE-REGISTRY.md`;
3. machine-readable `FEATURE-REGISTRY-r3.json`, `PS-STANDARD-REGISTRY-r3.json`, `SEMANTIC-BUNDLE-v1.schema.json`, and `INTERFACEIR-v1.schema.json`, for the fields/categories they normatively define;
4. `SEMANTIC-BUNDLE-v1.md` and `INTERFACEIR-v1.md`;
5. accepted topic design documents and `DECISIONS.md`;
6. the exact r2 baseline for everything not overridden;
7. tutorials/research notes as informative only.

Machine-readable schemas do not silently override prose outside their explicitly defined data-format domain.

## 5. Semantic authority

The Lean semantic pin remains unchanged:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

A later Lean version is a different profile/revision.

Native `.lean` remains native Lean syntax. r3 surface rules apply only to `.ps` under an r3 profile.

## 6. Override families

r3 overrides/amends only these semantic families:

- application syntax around parenthesized calls and empty calls;
- structural-brace outer member delimitation;
- zero-argument `function` sugar;
- `const` acceptance policy;
- Standard versus Lean-Extensible source profiles;
- stable PSC-owned contract core;
- application effects/resources/async architecture;
- npm/`.d.ts` InterfaceIR;
- migration/formatting/diagnostics/feature registry affected by the above.

All unchanged r2 rules for primitives, exact Nat/Int behavior, universes, dependent types, theorem checking, source identity, modules, recursion, unsafe/partial computation, transactional admission, erasure, runtime primitives, compiler preservation, artifact binding, resource limits, evidence manifests and assumption reporting remain normative.

## 7. Evidence

r2 historical oracle/test evidence remains evidence about the exact programs and environment it recorded. It does not become new r3 frontend evidence merely because r3 inherits the corresponding semantic rule.

r3 design acceptance remains distinct from production implementation, formal refinement, backend preservation, human-study results and full-application execution.
