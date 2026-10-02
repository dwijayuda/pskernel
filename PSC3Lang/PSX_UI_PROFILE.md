# PSC3 .psx UI and Component Profile

Status: **proposal**

.psx is a proposed source profile for typed component/markup programming.

It exists because JSX/TSX-style component construction is a major part of the JavaScript/TypeScript application ecosystem.

.psx must not turn HTML/React behavior into kernel semantics.

## 1. Core rule

.psx is:

~~~text
.ps
+ component markup syntax
+ UI-oriented diagnostics/tooling
~~~

The markup syntax lowers to ordinary typed expressions before core admission.

The logical/type/effect language is PSC3.

## 2. Framework-neutral syntax

Example:

~~~proofscript
component UserCard(user: User): Ui Node {
  <article class="user-card">
    <h2>{user.name}</h2>
    <p>{user.email ?? "No email"}</p>
  </article>
}
~~~

Conceptually lowers to typed component calls:

~~~proofscript
Ui.element(
  "article",
  props { class = "user-card" },
  [
    Ui.element("h2", {}, [Ui.text(user.name)]),
    Ui.element("p", {}, [Ui.text(user.email ?? "No email")])
  ]
)
~~~

The exact target API is selected by the UI adapter/profile.

## 3. Not React semantics

The same .psx syntax should be able to target:
- React;
- Preact;
- DOM construction;
- server-rendered HTML;
- a PSC-native virtual tree;
- another component library.

A component profile declares:
- Element/Node representation;
- component calling convention;
- property model;
- child model;
- event model;
- runtime effects.

## 4. Components are functions

A component is fundamentally a typed function.

Draft sugar:

~~~proofscript
component Greeting(name: String): Ui Node {
  <h1>Hello {name}</h1>
}
~~~

may lower to an ordinary function declaration.

There is no special "class component" semantic category.

## 5. Props

Props are ordinary typed data/arguments.

~~~proofscript
structure ButtonProps {
  label: String
  disabled: Bool = false
  onClick: UiEvent MouseEvent Unit
}
~~~

Markup:

~~~proofscript
<Button
  label="Save"
  disabled={saving}
  onClick={save}
/>
~~~

must elaborate using the component's declared parameter/prop interface.

Unknown props fail.

Missing required props fail.

## 6. Children

Children should use one explicit standard abstraction per adapter.

Avoid JavaScript's unrestricted "anything renderable" semantics as the language definition.

Possible abstraction:

~~~text
Children Node
~~~

with conversions from:
- text;
- a node;
- lists/iterables of nodes;
- Option nodes.

The adapter determines permitted conversions through typed declarations.

## 7. Conditionals and lists

Normal PSC expressions work inside markup.

~~~proofscript
<div>
  {
    match user {
      | .some(u) => <UserCard user={u}/>
      | .none => <LoginPrompt/>
    }
  }

  {items.map(item => <Row item={item}/>)}
</div>
~~~

There should be no second mini-language for control flow.

## 8. Events

Event handlers are typed effectful callbacks.

A browser adapter may expose:

~~~text
UiEvent MouseEvent Unit
~~~

or an equivalent App/Task effect.

DOM/browser mutation stays in the adapter capability model.

## 9. State

PSC3 should not bake a React hook model into .psx.

State may come from:
- framework hooks through a typed adapter;
- signals;
- explicit model/update architecture;
- PSC state/effect abstractions.

The language should enable each without privileging one as core semantics.

## 10. Async UI

Async effects use PSC Task semantics.

Framework adapters bridge Task to the host scheduler.

A Promise returned by a foreign framework does not become PSC Task without an adapter specifying cancellation/failure behavior.

## 11. HTML safety

A standard HTML adapter should make escaping safe by default.

Distinguish:
- Text;
- Html/TrustedHtml;
- attribute values;
- URLs;
- style values.

Raw HTML insertion is an explicit capability with an obvious trust/security boundary.

This is an example where a stronger typed platform can improve on ordinary JSX ergonomics.

## 12. CSS

PSC3 should not put a CSS language into the logical core.

Possible profiles:
- ordinary class/string names;
- typed generated CSS modules;
- CSS-in-PSC library;
- framework adapters.

Any compile-time CSS extension remains an ordinary typed build/plugin capability.

## 13. Server/client boundaries

A full web platform may add typed annotations/profiles for:
- server-only modules;
- client-only modules;
- shared modules;
- serializable boundary values.

These are application/package constraints, not proof-kernel rules.

A framework plugin can generate routing/build metadata without gaining proof authority.

## 14. Verification opportunities

.psx can benefit from PSC verification without requiring every UI component to be proved.

Examples:
- prop invariants;
- sanitized HTML guarantees;
- accessibility constraints for generated structures;
- state-machine transitions;
- form validation;
- serialization contracts;
- pure view functions.

Claims involving real browser behavior or layout require an explicit model/assumption and must not be exaggerated.

## 15. Native markup grammar constraints

To preserve tooling quality:
- markup syntax has a fixed grammar;
- arbitrary runtime grammar mutation is not allowed;
- component names resolve through ordinary modules;
- braces contain ordinary PSC expressions;
- formatting is canonical;
- parser errors identify markup versus expression context.

## 16. .lean relationship

.psx syntax is ProofScript-owned.

It is not accepted in .lean.

Lean users can construct the same component values through valid Lean terms/functions in the supported platform API.

Thus:

~~~text
.psx markup
      |
      v
ordinary component calls
      ^
      |
supported .lean source
~~~

can share semantic component libraries without pretending JSX is Lean syntax.

## 17. Adoption gate

.psx should not freeze until at least:
- one React adapter;
- one framework-neutral/DOM or SSR adapter;
- typed events;
- conditionals/lists;
- source maps;
- formatter;
- LSP completion in tags/props;
- a real browser application;
- SSR/hydration or an explicit deferral decision;

have been exercised.

.psx is justified by full-app adoption only if it remains smaller and more predictable than implementing a JSX-compatible macro ecosystem.
