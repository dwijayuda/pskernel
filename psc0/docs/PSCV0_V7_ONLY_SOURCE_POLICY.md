# PSCV0 v7 — sole source-language policy for PSC0

**Decision (11 October 2026):** The byte-identical [PSCV0 v7 language reference](../PSCV0_LANGUAGE_REFERENCE.md) is the **only forward-looking normative source-language design** for `.ps` in PSC0. No source-level backwards compatibility is required for PSC1, earlier PSCV0 drafts, or `ps-0.9-r3`. The initial bridge advertises only `declaration-except-do/1`, NOT full v7 conformance; unsupported v7 features must be explicit refusals, never implicitly accepted from an older edition.

## Boundaries, not compatibility exceptions

- The existing frozen PSC0/PSC1 JavaScript compiler and older `.lean` source archive remain **bootstrap tools and reproducibility evidence**, not accepted v7 `.ps` grammar selection or public semantic fallback. Do not delete old history/seed or rewrite previous CI receipts; these are not language features.
- Lean-native `.lean` parsing/printing is a **distinct source kind and reference/projection lane**. It can use the pinned Lean grammar where intentionally selected; it cannot silently rescue rejected v7 `.ps` input.
- The new `psPscv0ParseSource(true,...)` has a closed command dispatch. The currently **implemented v7 subset** explicitly recognizes selected `def`, `const`, `function`, `structure`, `inductive` and `theorem` bootstrap forms. This is not a claim of complete v7 support. The last three reuse narrow existing parser algorithms, not another compatibility profile.
- Source `partial`, `unsafe`, `axiom`, obsolete `verify`, and `ghost` command forms are explicitly refused **by v7 source parsing**. Unknown or unregistered command introductions (such as user `syntax`) fail closed with `PSCV0-V7-COMMAND-NOT-YET-SUPPORTED`, rather than being accepted by a permissive fallback.
- `sorry`/generated `sorryAx`, dependent `noncomputable` executable closure, effect/spec/assumption obligations and unknown imported axioms require their **distinct emission/assurance** checks. An early parser rejection is not proof that those full semantic/assurance policies are implemented. This source-policy change neither adds a second kernel nor grants executable status.

## Regression and qualification

Native `Pscv0BridgeSourceSmoke.lean` adds six negative source tests: source `partial`, `unsafe`, `axiom`, obsolete `verify`, `ghost`, and unsupported `syntax`; expected diagnostic ownership is checked explicitly. The generated bridge test adds five corresponding negative cases. Preserve existing do/format/first-error/source-correspondence tests. These checks are **bounded v7 policy enforcement only**, not full syntax/elaboration conformance or general kernel soundness.

Do not promote the `.ps` source-authority candidate until its separately running generated 20-module and Linux/Windows/RC4 gates qualify it. The v7 document and its immutable digest remain the sole new-language authority even if those gates are pending. Any claim of complete v7 Standard requires the frozen RC4 environment snapshot and differential parser/elaborator/proof/assurance tests.

**Migration order:** small portable grammar/typed lowering families → readable `.ps` source modules → entire measured 64-module source closure → deliberately qualified compiler-only C0–C3 fixed point. Neither preservation of old parser logic in the bootstrap seed nor a historical `.lean` build is a reason to implement an old edition in the new compiler.
