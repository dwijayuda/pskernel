# r3 → r2 Inheritance / Override Matrix

Status: **historical inheritance/audit matrix; non-normative for current ps-0.9-r3 source meaning**

> Current r3 is standalone. This matrix is retained only as research/migration history and cannot supply missing language rules.

Base artifact: `baseline/ProofScript_Language_Reference_v0.9.0_r2.md`  
SHA-256: `d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`

"**Inherited unchanged**" means the r2 rule is normative in r3 with the same Lean 4.34 semantic pin. "Amended" means r2 remains in force except for the named r3 change. "Overridden" means the corresponding r3 rule replaces the r2 rule for r3 source.

| r2 § | Topic | r3 disposition |
|---:|---|---|
| 1 | Purpose and design principles | amended: accepted-r3 status/design commitment |
| 2 | Normative language and authority | overridden: r3 delta authority and precedence |
| 3 | The central semantic relationship | inherited unchanged |
| 4 | Source files and source identity | amended: profile identity/source authority |
| 5 | Capabilities and implementation profiles | overridden: ps-standard / ps-lean-extensible |
| 6 | Acceptance results and assurance labels | inherited unchanged |
| 7 | TypeScript-oriented design choices | amended: r3 TypeScript-familiarity decisions |
| 8 | Character stream, comments, and positions | inherited unchanged |
| 9 | Identifiers, keywords, and hygiene | inherited unchanged |
| 10 | Punctuation and grammatical categories | amended: category-specific punctuation incl. structural braces |
| 11 | Surface classes | amended: parenthesized call is E-class in r3 |
| 12 | Grammar composition and inherited grammar | amended: Standard has closed registry; Extensible records extensions |
| 13 | Precedence, grouping, and expression boundaries | overridden: call gap/newline/grouping rules |
| 14 | D-CALL: positional, empty, and grouped calls | overridden: E-CALL-PARENS-R3 + empty-call semantics |
| 15 | v0.9 call conveniences: explicit named arguments and trailing commas | amended: named calls/trailing commas remain category-specific |
| 16 | Declaration boundaries and native semicolons | overridden: structural owned braces and separators |
| 17 | Definition declarations and aliases | overridden: function() Unit sugar; const retained |
| 18 | Definition kinds, modifiers, and visibility | inherited unchanged |
| 19 | Binders, dependencies, and universes | inherited unchanged |
| 20 | Inference, annotations, and elaboration order | inherited unchanged |
| 21 | Named, default, automatic, and partially supplied arguments | overridden: empty call vs default/optional/auto parameters |
| 22 | Lambdas, closures, and higher-order functions | inherited unchanged |
| 23 | Operators, equality, and conditions | inherited unchanged |
| 24 | Braced conditionals | inherited unchanged |
| 25 | Structures and record values | overridden: structure/class field separators; no trailing field comma |
| 26 | Dependent fields and updates | inherited unchanged |
| 27 | Inductives, constructors, and pattern matching | amended: structural braced inductive/match sequences |
| 28 | Indexed, mutual, nested, and coinductive definitions | inherited unchanged |
| 29 | Classes, instances, and methods | amended: class/instance brace rules |
| 30 | Collections, absence, and error values | inherited unchanged |
| 31 | Local definitions, `where`, and recursion syntax | amended: local where brace separators |
| 32 | Pattern/equation functions and declaration suffixes | inherited unchanged |
| 33 | Scalars, literals, and primitive identity | inherited unchanged |
| 34 | Strings, characters, bytes, and identity | inherited unchanged |
| 35 | Pure computation and evaluation | inherited unchanged |
| 36 | Native `do`, local mutation, and control flow | inherited unchanged |
| 37 | Structural, well-founded, partial, and unsafe computation | inherited unchanged |
| 38 | Effects, state, and errors | inherited unchanged |
| 39 | IO, tasks, resources, and application libraries | overridden: App/Fiber/Resource/Stream/Capability model |
| 40 | Imports, namespaces, sections, and modules | amended: source profiles and semantic-bundle imports |
| 41 | Notation, macros, deriving, and metaprogramming | amended: Standard extension restrictions |
| 42 | The logical foundation | inherited unchanged |
| 43 | Propositions, types, and evidence | inherited unchanged |
| 44 | Theorems and structured proof forms | inherited unchanged |
| 45 | Rewriting, simplification, automation, and reflection | inherited unchanged |
| 46 | Axioms, classical mathematics, quotients, and noncomputability | inherited unchanged |
| 47 | Specifications as ordinary theorems | overridden: stable pure contract core |
| 48 | Native intrinsic contracts | amended: native intrinsic contracts are compatibility/oracle only |
| 49 | Assertions, invariants, termination clauses, and ghost state | amended: state/loop/async contract surface staged; frame/effect model added |
| 50 | Specification quality and assumption control | inherited unchanged |
| 51 | Required pipeline and phase invariants | inherited unchanged |
| 52 | Surface AST and feature registry | inherited unchanged |
| 53 | Parsing API and error recovery | inherited unchanged |
| 54 | Canonical lowering rules | inherited unchanged |
| 55 | Binding, provenance, and source maps | inherited unchanged |
| 56 | Elaboration and declaration admission | inherited unchanged |
| 57 | Comparing reference and production frontends | inherited unchanged |
| 58 | Erasure and executable IR | inherited unchanged |
| 59 | Preservation propositions and certificates | inherited unchanged |
| 60 | Target routes and external compilers | inherited unchanged |
| 61 | Exact emitted artifacts, linking, and release snapshots | inherited unchanged |
| 62 | Resource limits and checker build trust | inherited unchanged |
| 63 | Standard library layering | amended: Standard application-layer architecture |
| 64 | Packages and logical modules | amended: package profiles and semantic bundles |
| 65 | Foreign interfaces and typed boundary values | overridden: InterfaceIR raw/safe/spec boundary |
| 66 | Data conversion, callbacks, and Promise adaptation | amended: callbacks/Promise mapped through App/Stream semantics |
| 67 | Exporting libraries and complete applications | amended: npm export identity and generated bindings |
| 68 | Optional UI syntax and other extensions | inherited unchanged |
| 69 | Canonical formatting | amended: r3 formatter/call/brace rules |
| 70 | Diagnostics and language-server information | amended: r3 diagnostics |
| 71 | Migration from v0.7 and earlier PSC3/v0.9 drafts | overridden: r2->r3 migration |
| 72 | Source and specification compatibility | inherited unchanged |
| 73 | Conformance program | amended: r3 conformance matrix |
| 74 | Implementation and release gates | amended: design accepted, stable/1.0 evidence gates remain |
| 75 | Grammar notation and scope | inherited unchanged |
| 76 | Owned grammar | overridden: r3 owned grammar |
| 77 | Native category dependency map | amended: Standard registry closure |
| 78 | Feature registry summary | overridden: r3 feature registry |
| 79 | Diagnostic catalog | amended: r3 diagnostic additions |
| 80 | Normative lowering examples and pitfalls | overridden: r3 lowering examples |
| 81 | Evidence manifest contract | amended: profile/bundle/interface identities |
| 82 | What the study corpus established | inherited unchanged |
| 83 | Research conclusions and alternatives | amended: r3 research conclusions; call adjacency rationale retired |
| 84 | Programming-language theory used in the design | inherited unchanged |
| 85 | Executed evidence and its limitations | amended: historical evidence is not r3 frontend evidence |
| 86 | Formal obligations before stronger claims | amended: formal proof obligations |
| 87 | Practical implementation order | amended: implementation order |
| 88 | Reference register | amended: current official-source supplements |
| 89 | Final design commitment | amended: accepted r3 design commitment |

## Global inheritance

Subsections inherit the disposition of their containing numbered section unless a more specific r3 document says otherwise.

In particular, r2's exact primitive/runtime/compiler-assurance rules remain normative where this matrix says inherited unchanged. This includes exact Nat/Int operations, fixed-width values, strings/bytes, source/module identity, recursion/partiality/unsafe distinctions, theorem/axiom policies, transactional admission, erasure, primitive matrices, preservation propositions, emitted-artifact binding, resource limits and evidence-manifest discipline.

Historical r2 evidence remains historical evidence; inheritance of a rule does not relabel an r2 test as an r3 frontend test.
