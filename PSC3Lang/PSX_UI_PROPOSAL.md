# Optional `.psx` UI extension

**Experimental proposal `PSC3-UI-0`. Not implemented, not stock Lean syntax, and not an unsafe escape hatch.**

## 1. Decision and alternatives

Recommended: a small, explicitly delimited UI quotation that expands into an ordinary typed view library. The library is fully usable from `.ps` and `.lean`; `.psx` is optional source ergonomics.

Alternative A, library-only UI, minimizes syntax/tooling cost and is the first implementation baseline. Alternative B, arbitrary TSX-compatible source, creates another language frontend, JS expression semantics and extensive compatibility obligations; it is rejected for the first extension. Alternative C, a wholly custom framework language, sacrifices interoperation and is deferred.

The markup recommendation remains experimental until user studies show material readability/maintenance benefit over the library form. JSX and React TS documentation demonstrate the relevance of typed UI props, children and events, but do not prove that this proposed syntax is better. [T11,E01](RESEARCH_SOURCES.md)

## 2. Source and Lean relationship

Ordinary `.ps`/`.lean` remain the strict profile. A `.psx` project explicitly selects `PSC3-UI-0` and a pinned `Psc.UI.Syntax` extension environment. Prefer implementing the quotation as a controlled Lean syntax/macro package, so official Lean can check the extended contents under that declared import as well as the plain expansion.

That does not make the extension stock Lean. The project must report strict source versus source-under-extension coverage separately. If the extension cannot be implemented with the promised Lean expansion/oracle behavior, it is not accepted by this design.

PSC2 used `.psx` for possible mixed/unverified source. Existing files keep that old-edition meaning. The new extension needs explicit migration and project metadata; the suffix alone cannot choose between dialects. [R01](RESEARCH_SOURCES.md#repository-baselines)

## 3. Candidate authoring example

The following is **illustrative syntax for an unimplemented extension**, not a claim that Lean or PSC accepts it today:

```text
import Psc.UI.Syntax

def counterView (count : Nat) : View CounterMsg :=
  view!
    <button onClick={CounterMsg.increment}>
      {toString count}
    </button>
```

Its proposed plain-library meaning is equivalent to:

```lean
-- Proposed library names; not a standalone compilable example.
def counterView (count : Nat) : View CounterMsg :=
  View.button CounterMsg.increment [View.text (toString count)]
```

Plain `.lean` applications never need markup. The extension must preserve the same messages, child order, props and view result as the ordinary expression. No arbitrary JS expression is allowed inside interpolation; terms are parsed by the selected Lean term grammar.

## 4. Minimal grammar contract

The quotation is confined to a term context after an unambiguous introducer. It contains known element/component tags, named typed attributes, literal text, term interpolation, nested children and fragments. The full tokenization/escaping grammar is a pre-freeze deliverable.

Interpolations are typed: text positions require String or an explicit supported conversion, not automatic host truthiness; event positions require the expected message or typed event-to-message function; component props follow the declared record/schema. Upper/lowercase heuristics must not be the sole semantic namespace rule.

No arbitrary spread of dynamic objects in the first version. A typed props record can be supplied through an explicit form whose duplicate-field behavior is specified. Do not copy JS prototype/property-descriptor spread semantics.

Loops/conditions remain ordinary Lean expressions and library combinators inside term positions, rather than a second directive/control language. Keyed lists use an explicit keyed constructor. Unique key constraints may be checked in a development profile or established by a suitable data invariant; do not silently rely on array position for identity-sensitive state.

## 5. Expansion and diagnostics

The expander produces owned syntax with source ranges and a mapping from every generated node back to its original quotation. Expansion is hygienic and deterministic for the locked environment. It constructs ordinary library calls, not privileged renderer nodes in the proof kernel.

A macro producing well-typed code is not proof that the expansion preserves the intended source meaning. Define a reference expansion relation, compare implementations and progressively prove it for the supported grammar. Use a trusted/verified printer or actual-file parsing when claiming correspondence to generated artifacts.

Errors should name the original component, prop, expected type, missing required field or unhandled event—not only a generated constructor several layers below. Formatter round trips and error recovery on incomplete markup are release gates.

## 6. Native component model

Propose a component library with Props, Model and Msg types; initialization; update returning state plus effect descriptions; pure view construction; and explicitly scoped subscriptions. These are ordinary data/functions and can expose contracts about updates and serializable models.

Views do not directly call arbitrary network operations. Effects are started by the runtime from declared descriptions, allowing request identity, cancellation and cleanup to have explicit semantics. Imported foreign widgets remain opaque components with reviewed boundary props and lifecycle behavior.

A custom component can later use a different state discipline through an explicit adapter. It cannot secretly mutate the native model while claiming to be a pure view.

## 7. React adapter

Generate a stable wrapper implementing the required subscriptions, lifecycle and event marshalling. Ordinary React hook calls must obey the framework's rules in that wrapper. Do not generate conditional hooks merely because a Lean `if` occurs in view code. [E02](RESEARCH_SOURCES.md#application-and-javascript-platform)

For foreign components, model callbacks, controlled/uncontrolled input differences, refs and children explicitly. A ReactNode-like foreign value is an opaque boundary case, not automatically a value in the native view semantics. Surface the renderer and adapter versions in build evidence.

## 8. Rendering, security and accessibility

Text children must use a renderer operation that performs the specified escaping. Raw HTML is a separate capability with a clearly marked sanitizer/trust policy; it is not an ordinary String prop. URLs and attributes need context-sensitive policies, not one universal escape function. Event handler values must not be serialized as source code.

ARIA/label/keyboard checks are useful tooling, not universal accessibility proofs. Server rendering and hydration need stable initial state, keys and component behavior. The adapter must test server/client agreement and report mismatches. [E03](RESEARCH_SOURCES.md#application-and-javascript-platform)

Preserving a pure view AST does not prove browser layout, accessibility, DOM-engine correctness or absence of every injection bug. Renderer/runtime assumptions remain explicit.

## 9. Required evidence before promotion

Paired plain-library/quotation examples; official-Lean-under-extension checks; owned frontend expansion checks; prop/children/event negative tests; nested namespace and hygiene tests; formatter/source-map tests; keyed-list state preservation; listener disposal; stale async events; clean React embedding; SSR/hydration cases for that profile; and side-by-side usability tasks.

No extension implementation or browser tests were executed in this design pass. Until these gates close, library-only views remain the normative application baseline.
