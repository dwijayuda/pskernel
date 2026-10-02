# Optional `.psx` UI extension

**Experimental proposal `PSC3-UI-0`. Not implemented and not admitted ordinary v0.7 `.ps` syntax.** [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md), especially reference §27, controls the source-profile boundary.

## 1. Decision and alternatives

The library-only UI model is the first baseline. A small optional markup/quotation dialect may improve authoring, but it requires explicit grammar, version, canonical lowering and evidence before acceptance. Arbitrary TSX semantics and a separate framework language are not initial goals.

v0.7 describes `.psx` as explicitly target-specific/non-Lean-compatible source. The UI proposal lives within that boundary; it does not redefine `.psx` as ordinary verified `.ps`. Source extension identity and assurance are independent. No suffix grants trust, and existing `.psx` files must not be silently treated as UI.

JSX/React documentation motivates studying typed props, children and events, not a claim that this candidate is better. User studies and maintenance tasks must justify markup over ordinary APIs. [T11,E01](RESEARCH_SOURCES.md)

## 2. Source and Lean relationship

Ordinary `.ps` uses v0.7 L/D/E syntax and canonical lowering. Ordinary `.lean` stays native. Both can call the proposed view libraries without markup.

A `.psx` project explicitly selects `PSC3-UI-0`, its parser/expansion version and any extension imports. The extension must describe how embedded `.ps` terms use the v0.7 term category and how the result lowers to canonical Lean/Core. D-CALL inside an interpolation does not automatically change markup, attribute, pattern or tactic grammar.

A controlled Lean macro implementation is an option for the canonical extension stage, not a requirement that original `.psx` bytes be stock Lean. Checks under an imported Lean syntax package are separately labelled extension-environment checks. The unextended `.lean` subset promise remains intact.

## 3. Candidate authoring example

**Extension pseudocode only; `view!` and markup below are not registered v0.7 forms and were not parsed or implemented:**

```text
import Psc.UI.Syntax

function counterView(count : Nat) : View CounterMsg :=
  view! <button onClick={CounterMsg.increment}>
    {toString(count)}
  </button>;
```

Proposed ordinary-library `.ps` expansion, using v0.7 syntax and unimplemented library names:

```proofscript
function counterView(count : Nat) : View CounterMsg :=
  View.button(CounterMsg.increment, [View.text(toString(count))]);
```

Corresponding canonical/native Lean expression:

```lean
def counterView (count : Nat) : View CounterMsg :=
  View.button CounterMsg.increment [View.text (toString count)]
```

Preserve messages, child order, props and result. Interpolation is PSC term syntax, not arbitrary JS evaluation. A `component` keyword, raw TSX arrow functions or universal statement blocks are not implicitly added.

## 4. Minimal grammar contract

A future registry entry must give the exact introducer, tokenization/escaping, element/component resolution, attributes, interpolation boundaries, children and fragments. Unknown or colliding syntax fails closed. The proposal is not a registered E form simply because a document calls it one.

Text positions require String or an explicit conversion; events require typed messages or functions; props follow a declared record/schema. Case conventions alone must not define namespaces. Avoid dynamic object spread in the first version. If typed props spreading is later supported, specify duplicate-field behavior without importing JS prototypes/descriptors.

Loops and conditionals use ordinary v0.7 expressions/library combinators inside term positions, not a second control language. Keyed lists use explicit identities; array positions are not silently treated as stable keys for stateful elements.

## 5. Expansion and diagnostics

Produce owned syntax with original ranges and generated-to-source mappings. Expansion is hygienic and deterministic in the locked environment. It constructs ordinary library calls, not privileged renderer nodes in the proof kernel.

A well-typed expansion is not by itself a preservation theorem. Specify the expansion relation and test/prove it at the claimed scope. Exact generated-file claims also need justified printing/parsing.

Report errors on the original component/attribute/span, expected type and missing fields. Formatter round trips must preserve markup and v0.7 interpolation ownership, including comment/adjacency behavior. Incomplete markup should still produce useful editor diagnostics.

## 6. Component library

Proposed Props, Model and Msg types support initialization, update, effect descriptions, pure views and scoped subscriptions. They are ordinary definitions usable from both source surfaces. No new component declaration grammar is required for the baseline.

Effects are started from descriptions by an explicit runtime; views do not conceal arbitrary network calls. Imported widgets remain opaque foreign components with reviewed props and lifetimes. Alternative state disciplines need explicit adapters rather than hidden mutation of the native pure model.

## 7. React adapter

Generate stable wrappers for lifecycle, subscriptions and event marshalling. Framework hook rules apply within those wrappers; a source conditional does not justify emitting conditional hooks. [E02](RESEARCH_SOURCES.md#application-and-javascript-platform)

Model controlled/uncontrolled inputs, refs, callbacks and children explicitly. A foreign ReactNode is not automatically a native view value. Runtime/adapter identities and assumptions remain part of evidence.

## 8. Rendering, security and accessibility

Use renderer operations with specified text escaping. Raw HTML has a separate sanitizer/trust policy; URLs and attributes need context-specific handling. Events must not be serialized as executable source.

Accessibility checks are useful evidence, not universal proofs. SSR/hydration needs compatible initial state, keys and component behavior. Test agreement and expose mismatches. [E03](RESEARCH_SOURCES.md#application-and-javascript-platform)

Preserving a view AST does not prove browser layout, DOM correctness, accessibility or freedom from every injection bug. A checked expansion never grants broad assurance to unmodeled renderers or hosts.

## 9. Required evidence before promotion

Require an explicitly registered dialect; paired markup/v0.7-library/canonical-Lean examples; checking of the lowered output; extension-environment checks where used; negative props/children/event cases; hygiene and source maps; formatting; keyed-state and listener lifetime tests; stale-event handling; clean React embedding; applicable SSR/hydration tests; and user-task comparisons.

No extension implementation or browser tests are claimed by this repair. Library-only views remain the baseline, and ordinary `.ps` grammar remains v0.7.
