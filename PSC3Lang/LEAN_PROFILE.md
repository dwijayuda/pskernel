# PSC3 Lean compatibility profile

**Proposed profile, not an implemented conformance claim.** The authoritative language requirements are in [LANGUAGE_REFERENCE.md](LANGUAGE_REFERENCE.md).

## 1. Reference identity

| Item | Proposed value |
|---|---|
| Edition | `PSC3-0` (review draft) |
| Lean tag | `v4.34.1` |
| Source commit | `5045d0056413266e57c625dcd7c365b10e377c52` |
| Ordinary source | Native pinned Lean forms in `.lean`; byte-identical `.ps` staging |
| Base environment | Pinned `Init` plus enumerated `Std` and ordinary PSC library modules |
| Optional UI extension | `PSC3-UI-0`, distinct from strict stock syntax |
| Existing project pin | Unchanged; migration is a separate gated change |

The patch tag was resolved, and its official release notes recommend runtime fixes. This does not demonstrate independent-checker parity, nor does it authorize mixing 4.34.0 and 4.34.1 artifacts. [L01–L02](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 2. Meaning of subset

For source S and a declared environment E, acceptance requires native parsing/elaboration under the pin, allowed syntax and elaboration dependencies, admitted declarations under the selected logical policy, and supported executable closure for requested targets. A lexical allowlist or successful stock-Lean build alone is insufficient for owned PSC frontend/backend support.

Accepted constructs must retain their Lean meaning. Reject a difficult case rather than choose a different instance, truncate a universe, invent a coercion, reinterpret partial recursion or silently discard a dependent field. The source profile, compiler implementation subset, logical profile, executable target set and assurance claims are separate dimensions.

Ordinary `.ps` staging changes only the filename extension. Source contents, options, logical module mapping and dependencies remain the same. Source-generated helpers belong in explicit generated modules with provenance, not invisible prefixes added to user files.

## 3. Proposed inclusion matrix

Every row needs positive, negative and interaction tests before a release advertises it. `First` means a target for the first coherent profile, not current implementation status.

| Family | Decision | Restrictions and tests |
|---|---|---|
| `def`, `fun`, curried application | First | Canonical teaching forms; no extra adjacent comma-call semantics. |
| Explicit/implicit/instance binders | First | Native elaboration; public signatures and inserted arguments inspectable. |
| Named/default arguments | First | Native binders and dependency order; no backend reordering of effects. |
| `let`, `where`, local functions | First | Native lexical scope; closure capture and recursion tested. |
| Namespaces, sections, imports, visibility | First | Pin the old/new module mode and exact supported forms; do not invent visibility defaults. |
| Structures and updates | First | Nominal identity; dependent updates reconstruct a well-typed value. |
| Inductives and patterns | First | Native formation/elimination; nested/dependent patterns need elaborator coverage. |
| Indexed/mutual/nested inductives | Logical target; staged execution | No weakened positivity or recursor checking; layouts separately gated. |
| Typeclasses, method notation, coercions | First bounded coverage | Preserve native search resolution; do not replace priority/order with a new rule. |
| Structural/well-founded recursion | First | Ordinary termination evidence; failed search is not proof of divergence. |
| `partial def` | Application profile | Native opaque logical role; runtime body is not automatically its own proof equation. |
| `partial_fixpoint` | Experimental | Exact monotonicity/order machinery and generated reasoning principles required. |
| `do`, local mutation, loops | First | Native elaboration; test closures, early exits and transformer order. |
| `IO`, selected exceptions/finally | Host profile | Explicit primitive/runtime mapping and environmental assumptions. |
| Native Lean `Task` | Compatibility capability, gated | Do not alias to Promise or a portable task library. |
| `Psc.Async`, resources, UI | Ordinary library proposals | Legal Lean definitions and separate interpreter/adapter correctness. |
| Universes, `Sort`, `Prop`, dependent functions | Logical foundation | Exact selected theory, not a simpler incompatible calculus. |
| Equality, inductive proofs, `theorem` | First | Kernel evidence; Boolean equality needs laws before logical use. |
| `have`, `calc`, `rw`, `simp`, induction | Prover profile | Native/proven-equivalent construction; independently checked proof results. |
| Classical/noncomputable mathematics | Mathematical profile | Exact assumption tracking; no automatic executable realization. |
| Quotients/extensionality | Chosen logical profile | Full relevant rule and dependency checking; no runtime identity substitute. |
| Intrinsic contracts/invariants | Experimental native profile | Pinned syntax/imports/options; not a new default grammar. |
| Deriving/scoped notation | Bounded extension environment | Enumerate handler identities; same expansion meaning under official Lean. |
| Arbitrary macros/elaborators/initializers | Host extension profile | Not silently available in strict application compilation. |
| `unsafe`, `extern`, runtime replacements | Adapter-specific | Distinguish logical role from runtime assumptions; no foreign proof oracle. |
| Holes/`sorry`/user axioms | Editor/research only or explicit assumptions | Cannot obtain strict verified-release status. |

Lean's native instance synthesis uses priorities and declaration order; its partial definitions have a weak opaque equational theory. These concrete rules constrain the PSC frontend rather than being optional design preferences. [L05,L07](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 4. Core theory and policy

Retain the selected dependent theory's sorts/universes, substitution, conversion, propositions, proof irrelevance, inductives/recursors and quotient facilities. The independent checker may reject unsupported constructs during development, but cannot claim the full profile while approximating them. The upstream type-system account supplies the reference concepts; it is not a proof of PSC's implementation. [L09](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Separate semantic rules from an axiom policy. A Lean-oriented mathematics policy may allow exact reviewed foundational declarations associated with propositional extensionality, choice and quotient soundness. A constructive policy may reject those dependencies without changing conversion behavior. User assumptions, `sorryAx`, unsafe execution and native-result proof mechanisms must remain distinguishable.

Check declaration identity/types and transitive dependencies, not names alone. A kernel proof about a modified specification is still the wrong artifact. The independent validation guidance emphasizes statement and definition binding as well as proof checking. [L08](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 5. Contracts: exact upstream finding

At the proposed pin, `src/Lean/Parser/Command.lean` defines one optional `requires` followed by one optional `ensures`. Repeated conditions use conjunction or ordinary predicates rather than multiple copies of the keyword. The inspected test imports `Std.Internal.Do`, enables `experimental.intrinsic`, and checks generated specification theorems. It distinguishes proof-oriented `assert` from runtime `assert!`. [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Do not call the experimental intrinsic interface frozen. Plain definitions plus ordinary theorems remain the baseline. Wrapping an experimental API in a library can stabilize a library-facing interface; it does not retroactively make arbitrary syntax part of stock Lean.

## 6. Library and elaboration closure

Before a freeze, inventory three different closures: source imports/options; parser/macro/tactic/deriving/instance environment; and logical declarations plus runtime primitives. An `Init` or `Std` import is not a certificate of a small closure. The entire concrete closure has not been computed in this pass.

Mathematical packages require a separately pinned compatible mathlib or other library revision, named tactic support and proof replay. No full mathlib migration claim or compatible mathlib commit is asserted here.

Ordinary platform libraries must be legal pinned Lean source. When their implementation uses a native host feature unavailable in a backend, provide a separately named adapter and report the assumption; do not redefine Lean's own constant. Full `.lean` applications may use PSC libraries just as they use other declared libraries.

## 7. Optional UI extension boundary

A possible `Psc.UI.Syntax` package can use Lean's extension facilities to provide an explicit UI quotation. Such source is legal under that declared extension environment, not a member of the strict stock-syntax profile. A `.psx` frontend must reproduce the specified expansion and the extension must have a plain-library desugaring.

Do not call arbitrary JSX Lean syntax because a preprocessor could translate it. Native Lean supports extensible syntax and hygienic macros, but each PSC extension still needs its own compatibility and tooling evidence. [L10](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 8. Release gate

Official Lean checks the intended source/environment; PSC independently accepts the declared subset; exact logical statements are compared/rechecked; target coverage is audited; negative cases reject; and the promised source/executable correspondence is evidenced. Oracle agreement is differential evidence, not by itself a formal equivalence theorem.
