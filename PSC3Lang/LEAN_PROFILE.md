# PSC3 Lean compatibility and v0.7 lowering profile

**Proposed profile, not implemented conformance. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** The language requirements in [LANGUAGE_REFERENCE.md](LANGUAGE_REFERENCE.md) are subordinate to that reference.

## 1. Reference identity

| Item | Selected documentation value |
|---|---|
| Platform edition | `PSC3-0` review draft; separate from source-reference version |
| `.ps` syntax/grammar | ProofScript Language Reference v0.7.0 and registered L/D/E forms |
| Canonical semantic baseline | Lean `v4.34.0`, `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` |
| `.lean` source | Supported pinned native Lean subset; no ProofScript-only grammar |
| `.ps` source | Category-aware canonical lowering; not a byte-identical `.lean` alias |
| Base environment | Exact pinned Init/Std and enumerated ordinary PSC libraries |
| Optional UI dialect | Explicit `.psx` extension proposal outside the v0.7 ordinary surface |
| Earlier patch research | `v4.34.1` / `5045d0056413266e57c625dcd7c365b10e377c52`, upgrade candidate only |
| Existing repository pins | Unchanged |

The selected source reference identifies S1-specified semantics, not completed parser/lowering or independent-kernel proofs. Earlier patch notes/tag research [L01–L02](RESEARCH_SOURCES.md#lean-and-logical-foundations) does not change this reference automatically. An upgrade needs a new declared profile and regenerated evidence.

## 2. Meaning of subset and lowering

For native `.lean` source S under environment E, acceptance requires native parsing/elaboration under the pin, the supported capability closure, admitted declarations under policy and supported executable closure for requested targets. Successful official compilation alone does not prove the owned frontend/backend supports it.

For `.ps`, apply the v0.7 ownership and canonical-lowering rules before the reference Lean path. D/E syntax need not be valid original Lean. Compare intended lowered declarations, options, imports and dependency identity. Do not rename `.ps` bytes or use a stale `.lean` sibling as an oracle shortcut. L-only snippets may already be native Lean, but that is a case of the shared grammar—not a global file-alias rule.

Accepted constructs retain the meaning of their canonical Lean forms. Reject difficult instances, universes, coercions, recursion or dependent fields instead of approximating them. Source profile, implementation subset, logical profile, executable target and assurance remain separate axes. Source-generated helpers and mapping information are explicit artifacts, not hidden authority.

## 3. Proposed inclusion matrix

Every row needs positive, negative and interaction evidence. `First` is a target, not current implementation status.

| Family | Decision | Restrictions and tests |
|---|---|---|
| `def`, `const`, `function` | First | v0.7 alias restrictions; native Lean output uses `def`. |
| D-CALL and explicit header parameters | First | Preserve adjacency, tuple distinction and binder order; no stock-Lean requirement on decorated bytes. |
| `fun`, native application/binders | First | Inherited categories; no TS arrow lambda or generic-angle replacement. |
| Named/default arguments | Bounded native coverage | Exact native grammar and dependency semantics; no invented colon-named-call form. |
| `let`, `where`, local functions | First | Native scope plus registered E-WHERE-BODY; closure/recursion tests. |
| Namespaces, sections, imports, visibility | First | Native command grammar; no braced namespaces or ESM source grammar. |
| Structures/classes/inductives | First | v0.7 braced `where` forms and native equivalents; exact nominal/logical meaning. |
| Record values/updates | First | Native `:=` fields; dependent updates remain well typed. |
| Match/patterns | First | E-MATCH-BODY retains `with`; patterns stay native, not D-CALL. |
| Indexed/mutual/nested inductives | Staged logical/execution target | No weakened positivity/recursor checking; layouts separately gated. |
| Typeclasses/methods/coercions | Bounded inherited coverage | Preserve selected Lean resolution rather than a new convenient policy. |
| Structural/well-founded recursion | First | Ordinary termination evidence; failed search is not divergence proof. |
| `partial def` | Application profile | Native opaque logical role; runtime body is not automatically a proof equation. |
| Other partial/coinductive mechanisms | Separately gated | Exact pinned formation, placement and reasoning rules; registry/capability evidence. |
| `do`, loops, mutable locals | Bounded inherited coverage | Reference §18 gate, including braced forms; no universal statement-block syntax. |
| `IO`, exceptions/finally | Host profile | Explicit primitive and environment assumptions. |
| Native Lean `Task` | Gated compatibility capability | Not an alias for Promise or the proposed portable Async library. |
| `Psc.Async`, resource, UI APIs | Library proposals | Ordinary definitions with valid v0.7/native surfaces and explicit adapters. |
| Universes, Sort/Prop, dependent functions | Logical foundation | Exact selected theory, not a simplified incompatible calculus. |
| `theorem`, `by`, `have`, `calc`, tactics | Prover profile | Inherited proof/tactic categories and independently checked evidence. |
| Classical/noncomputable/quotient developments | Chosen mathematical profile | Exact rule/axiom dependencies; no automatic executable realization. |
| Intrinsic verification | Experimental inherited capability | Recheck exact selected pin/imports/options; not new PSC-owned syntax. |
| Deriving/scoped notation/macros | Declared extension environment | Respect v0.7 ownership and fail on unresolved collisions. |
| `unsafe`, externals/runtime replacement | Adapter-specific | Report runtime assumptions; no foreign proof oracle. |
| Holes/`sorry`/user axioms | Editor/research or explicit policy | No strict verified-release status from incomplete/assumed evidence. |

Native resolution and partiality constraints are preserved by lowering; they are not optional styling preferences. Later upstream manual descriptions are research until matched to the selected pin.

## 4. Core theory and policy

Retain the selected theory's universes, binding/substitution, conversion, propositions, proof irrelevance, inductives/recursors and relevant quotients. A partial checker may reject unsupported declarations, not silently approximate them.

Separate semantic rules from axiom policy. Exact reviewed foundations may be permitted by a Lean-oriented policy; a constructive policy can restrict dependencies without changing conversion. Report user assumptions, `sorryAx`, unsafe execution and native-result proof mechanisms separately.

Check exact statements/definitions and transitive dependencies, not merely names. A valid proof about a modified predicate is still the wrong requested result. Independent validation guidance supplies relevant methodology, not an implemented PSC proof. [L08–L09](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 5. Contracts and upstream evidence

The earlier draft inspected 4.34.1 parser/tests with one optional `requires`, one optional `ensures`, explicit imports/options and generated specification theorems. Keep that as candidate-upgrade research [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations), not evidence that every such form is implemented under v0.7/4.34.0.

Before claiming an inherited verification capability, inspect and execute the exact selected source grammar and lowering. Do not add repeated clauses or new proof-section spellings by analogy. Plain definitions and ordinary theorem statements remain the baseline. Library wrappers can stabilize APIs but cannot secretly extend grammar.

## 6. Library and elaboration closure

Inventory source imports/options, parser/macro/tactic/deriving/instance environment, and logical/runtime dependency closures separately. Importing Init or Std does not establish that the closure is small. No complete closure inventory is claimed here.

Mathematical packages need pinned compatible revisions and named proof/tactic coverage. No full mathlib source compatibility is claimed. Platform libraries may be authored in v0.7 `.ps` or supported `.lean` and share canonical meanings. Host-specific implementations remain explicit adapters, not redefinitions of Lean constants.

## 7. Optional UI extension boundary

A `Psc.UI.Syntax` package or a dedicated `.psx` parser is a proposal, not registered v0.7 syntax. Reference §27 supplies the explicit target-specific/non-Lean-compatible boundary. Each UI dialect must specify its own grammar, collision policy, version, lowering and source mapping.

A proposed Lean extension implementation would be checked under its declared extension environment, not advertised as stock Lean. Its plain-library canonical output must remain independently checkable. Ordinary `.ps` and `.lean` apps do not require markup.

## 8. Release gate

Check native `.lean` under the pin; classify and lower `.ps` using the v0.7 registry; check canonical output; compare/recheck exact declarations; audit executable closure; and reject negative/unsupported cases. Preserve protected neighbors and source maps. Oracle agreement is differential evidence, not a formal equivalence theorem or an S2 promotion.
