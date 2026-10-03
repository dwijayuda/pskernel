# r3 Focused Specification-Completion Report

Date: 3 October 2026  
Scope: **documentation/design research only**

## Objective

Resolve the ten lingering specification flaws identified after the second r3 review, without changing the Lean semantic pin and without running compiler/backend/runtime experiments.

## Methodology

1. Re-read the accepted r3 reference and its design constitution/decision documents.
2. Reused the exact r2 baseline as immutable inherited authority rather than approximately rewriting unchanged semantics.
3. Compared the identified gaps with current official Lean, TypeScript/Node, Dafny, Verus, and WASI/Component Model documentation.
4. Converted every accepted decision into a normative grammar/data-format/profile rule.
5. Added machine-readable registries/schemas where prose alone was too vague.
6. Kept implementation/proof/usability evidence statuses separate from specification completion.

## Resolved results

### 1. Reference completeness

Resolved using a **complete exact r2 delta**, not a lossy re-transcription.

- vendored immutable r2 baseline;
- exact SHA-256;
- authority precedence;
- 89-section inheritance/override matrix.

### 2. Empty calls/default parameters

Resolved:

- `f()` is complete empty invocation;
- its canonical native request is `f ..`;
- native optional/default, automatic, implicit and instance arguments can be inserted normally;
- ordinary required explicit parameters are rejected even if ellipsis creates/inference solves a metavariable for them;
- `function f()` lowers to one optional Unit binder defaulting to `()`;
- `f(())` is explicit Unit and retains ordinary nonempty-call/partial-application behavior;
- r2 `f()` migrates to r3 `f(())` to preserve the old explicit Unit meaning.

### 3. Exact call/newline/brace grammar

Resolved:

- CallGap uses inherited horizontal Lean space trivia + no-newline Lean comments; r3 does not add tab-as-whitespace;
- physical newline breaks head-to-parenthesis ownership;
- multiline arguments begin after `(`;
- structural brace separators are explicit by category;
- field commas have no trailing comma;
- empty structure/class/inductive/instance brace bodies remain available where the corresponding native declaration is valid;
- the exact grammar permits native non-explicit binders before a zero-source-argument function's final empty explicit group.

### 4. Field notation

Resolved: native Lean dot adjacency is retained. `users .map(...)` is not an r3 feature.

### 5. ps-standard / semantic imports

Resolved at specification level:

- fixed `ps-standard-0.9-r3` machine-readable registry;
- dependency syntax/meta mutation forbidden;
- Semantic Bundle v1 manifest/import/recheck protocol;
- Standard bundles require no syntax/meta exports.

### 6. Contract core

Resolved:

- base r3 syntax freezes only total-pure `requires`/`ensures`;
- semantic FrameSpec added;
- higher-order CallableSpec / callRequires / callEnsures model added;
- state/loop/async convenience syntax explicitly staged instead of falsely normative.

### 7. Application semantics

Resolved:

- App is cold;
- Fiber is started;
- Exit contains success/failure/cancelled;
- RuntimeFault is separate;
- cancel is a request; join observes terminal outcome;
- child fibers are structured/scoped;
- cleanup is shielded from ordinary cancellation;
- capabilities are type-visible;
- native IO/Task are low-level/nonportable substrate;
- Promise and WASI async primitives are adapters.

### 8. InterfaceIR

Resolved:

- InterfaceIR v1 normative prose;
- JSON Schema;
- TypeScript resolver/version identity;
- conditions/export subpath/package.json/runtime/type-entry/declaration hash binding;
- explicit support classes;
- unsupported type machinery fails closed.

### 9. r2 primitive/runtime/module/compiler-assurance details

Resolved by exact inheritance authority and matrix. They remain normative unless r3 explicitly overrides them.

### 10. Pre-stable evidence

Still intentionally pending:

- usability study;
- formal overlay/refinement proof;
- backend preservation proof;
- reference applications;
- production parser/runtime/binding implementation.

These are evidence gates, not undefined base-language semantics.

## External research used

- Lean Function Application: optional/default/automatic argument insertion and native field-dot adjacency.
- Lean Elaborators: syntax/elaborator extension power and environment/IO effects.
- Node package exports: ordered conditional export selection.
- TypeScript module resolution: `types`, versioned types conditions, custom conditions and resolver-mode identity.
- Dafny: explicit framing/modifies concepts for stateful verification.
- Verus: higher-order callable pre/postcondition predicates.
- WASI 0.3 / Component Model: native `async func`, `future<T>`, `stream<T>` as target primitives.

Exact URLs are recorded in `RESEARCH-SOURCES.md`.

## Evidence boundary

No production implementation, formal theorem, human participant result, or full application execution is claimed by this pass.


### Final lexical consistency correction

The focused audit found that the initial completion draft said "spaces/tabs" in CallGap even though the inherited Lean lexer does not treat tabs as ordinary whitespace. The final r3 grammar therefore uses inherited horizontal Lean space trivia and does **not** add tab-as-whitespace as a call-only exception.

The same audit restored native-valid empty structure/class/inductive/instance bodies to the owned brace grammar.

These are specification corrections only; no compiler/runtime experiment was run.
