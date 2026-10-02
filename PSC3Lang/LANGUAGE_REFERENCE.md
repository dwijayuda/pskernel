# PSC3 language reference

**Authoritative proposed requirements for `PSC3Lang/` · review draft 0.2 · 3 October 2026.**

This is not a frozen specification or an implementation report. MUST, MUST NOT, SHOULD and MAY below constrain a future conforming implementation. No capability is implemented or proved by its inclusion here. Existing PSC1/PSC2 editions retain their own specifications.

## 1. Scope

PSC3 combines general-purpose programming, theorem proving and formal verification over a declared Lean-based foundation. Ordinary programming is not conditional on proving every application contract. The requested assurance is a separate, inspectable property of a build and its exports.

The strict source profile is a syntactic and semantic subset of Lean v4.34.1 at `5045d0056413266e57c625dcd7c365b10e377c52`, with an enumerated import/elaboration environment. The [Lean profile](LEAN_PROFILE.md) defines inclusion targets and restrictions. The [semantics companion](SEMANTICS_AND_EFFECTS.md) defines proposed library policies without changing native Lean constructs. [L01–L10](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 2. Source files, editions and environments

### 2.1 Ordinary source

An ordinary `.lean` file MUST be accepted by the pinned official frontend under the declared environment, in addition to satisfying PSC's supported-subset restrictions. An ordinary `.ps` file MUST have the same contents as its staged `.lean` source. Staging changes only the extension and declared filesystem layout; it MUST NOT rewrite calls, add imports, strip punctuation or alter options.

Each logical module resolves to exactly one source snapshot. A project MUST reject ambiguous `.ps` and `.lean` candidates unless an explicit manifest selects one. It MUST NOT silently use a stale sibling to make a build succeed. Source/import maps, relevant compiler options and the exact dependency environment are part of evidence identity.

The project declares the source edition independently of extension. A PSC2 file is not PSC3 merely because its suffix is `.ps`. Old meanings MUST remain available through explicit legacy support or be rejected with a migration diagnostic.

### 2.2 Extensions

The strict default does not add TS-like syntax. A syntax extension MUST have an explicit name/version, parser/expansion contract, allowed imports, source mapping and conformance gate. Its expansion must enter the same ordinary semantic checking path. Extension code has no independent proof authority.

`.psx` selects the proposed `PSC3-UI-0` extension only in an explicitly configured project. The UI extension is outside stock syntax; it is not an unsafe mode. Every UI behavior expressible through it SHOULD have a plain `.ps`/`.lean` library expression. See [PSX](PSX_UI_PROPOSAL.md).

### 2.3 Compatibility dimensions

Report source syntax, elaboration environment, logical rules/axioms, executable closure, target profile and assurance separately. Supporting exported Lean proofs does not imply support for their original tactic scripts. A working runtime backend does not imply a theorem library is supported. A feature excluded from execution may still be useful in proof-only code.

## 3. Lexing, formatting and declarations

Pinned Lean lexical rules govern identifiers, Unicode, comments, precedence and layout in ordinary source. Formatting MUST preserve the parsed meaning and module identity. PSC3 adds no extra adjacency-sensitive call convention.

`def` is the canonical ordinary definition. `theorem`, `example`, `abbrev`, `opaque`, `structure`, `inductive`, `class` and `instance` retain native meanings in the supported profile. `const` and `function` from PSC2 are not new ordinary PSC3 declarations. Native modifiers, visibility, namespaces and sections retain the exact selected Lean behavior; unsupported module modes fail explicitly.

The recommended project template includes `set_option autoImplicit false` explicitly. This is a convention using a native option, not an invisible frontend change. Other conventions MUST NOT cause the PSC and Lean oracle to check different environments.

Every accepted declaration MUST have closed, well-scoped admitted content under its environment. Unknown metavariables, malformed universe parameters and unfinished proofs do not gain release authority.

## 4. Functions and elaboration

Functions use native curried application and binders. Explicit, implicit, strict-implicit and instance-implicit binders retain their roles. A caller-facing type is not changed into TS generic-angle syntax or a new n-ary kernel operation.

Local inference is encouraged; public signatures SHOULD expose important data, effects and dependencies. Contextual typing of lambdas and automatic insertion of inferable arguments MUST remain inspectable in tooling.

### 4.1 Names, methods and typeclasses

For accepted source, name resolution, generalized field notation, coercions and instance synthesis MUST choose the terms specified by the pinned Lean environment. If the implementation cannot support a resolution case, it reports that restriction; it does not select a different candidate and label it compatible.

Import, priority and declaration-order influence is part of the environment. Search budgets are explicit. Exhausting a budget MUST NOT be treated as permission to choose a different meaning. Diagnostics SHOULD show the requested class/method, candidates, selected arguments and the relevant imported declarations. [L07](RESEARCH_SOURCES.md#lean-and-logical-foundations)

### 4.2 Named and default arguments

Accept the pinned native forms. Parameter identity is part of the exported source interface when used by name. Dependent argument elaboration follows native rules; defaults are not new runtime overloading. Distinguish the elaborator's processing order from the target program's execution order.

An options record is an ordinary structure, not a second parameter system. A library may choose it for stable application APIs. Foreign overloads/variadics are handled in [InterfaceIR](JS_INTEROP_AND_INTERFACE_IR.md), not by changing the core function type.

### 4.3 Higher-order functions

Functions remain first-class in the logical fragment. Their executable representation and supported polymorphism must be recorded. A backend cannot emit a different calling convention for a function returned from another function without preserving the same application meaning. Closure environment layout and partial application belong in representation evidence.

## 5. Data, schemas and equality

Structures and inductives retain nominal identity and native formation/elimination rules. Plain records are values, not JS objects whose prototype, address or mutable property identity defines equality. Constructors, projections and pattern motives must be checked.

Dependent fields are not optional verification metadata. When updating an index changes another field's type, reconstruct that field or supply appropriate evidence. The compiler MUST NOT resize data, discard a field or insert an unchecked cast. The simplest initial implementation may reject complicated updates with an actionable diagnostic.

Pattern matching MUST preserve constructor and index refinement. Exhaustiveness, inaccessible patterns and motive synthesis follow the supported native rules. Refutable pattern bindings need the native explicit failure context. A wildcard cannot hide an unsupported dependent motive.

`Option α` is the recommended application absence type and `Except ε α` the standard error type. A foreign boundary requiring more than two absence states MUST use a more precise ordinary data type; it cannot silently collapse them into Option.

Schema and codec libraries are ordinary definitions and generated declarations. They may supply DTO projections, typed paths and endpoint interfaces. They MUST NOT introduce general structural subtyping or prove foreign implementations from declaration shapes.

Propositional equality, definitional conversion and Boolean equality are distinct. A `BEq` instance does not automatically prove that true means logical equality; verified algorithms require the relevant laws or a verified decision procedure.

## 6. Logical foundation

The logical profile MUST implement the selected Lean rules for sorts/universes, dependent functions, binding/substitution, conversion, propositions, proof irrelevance, inductives/recursors and required quotient facilities. It must not substitute a simpler approximate calculus while claiming this profile. [L09](RESEARCH_SOURCES.md#lean-and-logical-foundations)

The checker may evolve through explicitly partial development coverage. Unsupported terms are not accepted. The public release profile and the minimum compiler implementation subset need not be identical.

### 6.1 Assumptions

Axiom policy is independent of package version and semantic-profile identity. A Lean-oriented mathematical policy MAY allow exact reviewed foundational declarations; a constructive policy may restrict them. Reports MUST expose the transitive logical assumptions of requested theorems.

Checking names alone is insufficient. A user axiom with the same spelling as a foundation declaration must not inherit its authority. `sorry`/`sorryAx`, incomplete proof artifacts and arbitrary native-result assumptions cannot qualify for strict verified release.

Native execution, external solvers and plugins may construct candidates. Unless justified by independently checked evidence, their answers are not new logical rules. Larger trust profiles may be selected explicitly and must say what they assume. [L08](RESEARCH_SOURCES.md#lean-and-logical-foundations)

### 6.2 Mathematics

Universe-polymorphic abstractions, indexed inductives, equality reasoning, classical and noncomputable developments are legitimate user programs in their declared logical profiles. A noncomputable definition is not forced into a runtime artifact. Its executable use requires an explicit realization and the appropriate correspondence evidence.

Tactic and notation environments are versioned. Successful elaboration of a mathematical example under official Lean does not establish owned-frontend compatibility or a complete mathlib port.

## 7. Computation, partiality and effects

Ordinary total definitions use accepted structural or well-founded mechanisms. A failed termination search is a failure to establish evidence, not a theorem of divergence.

`partial def` retains its native opaque logical interpretation. Referring to it in a theorem is different from establishing a property of its actual executable body. Its runtime equations must not be invented by the verifier. `partial_fixpoint` is a separately gated native feature with its own reasoning principles. [L05](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Typed application execution may include partiality and host effects. It MUST report what is established: type safety, conditional/partial correctness, total correctness, trace safety or another precise property. No global filename-based verified/unverified dichotomy may replace this evidence model.

`do`, state/error monads, loops, local mutation and control flow retain native elaboration. Observable effect sequencing is explicit in the computation. Logical reduction and execution are not interchangeable evaluators. Optimizations must respect relevant termination/effect assumptions; deleting an unused divergent computation is not justified merely by calling it pure.

The language MUST preserve the difference between state/error transformer orders. Discarding a pure state result on failure does not undo actual network or database effects.

Resources, async and platform capabilities are governed by separately named ordinary libraries. Native Lean Task and IO operations are not silently redefined to match JS Promise or Rust futures. See [SEMANTICS_AND_EFFECTS.md](SEMANTICS_AND_EFFECTS.md).

## 8. Scalars and runtime primitives

Nat/Int denote their exact native values. Fixed-width integers, target-word values, floats, characters, strings and byte arrays require operation-level bindings to the selected reference and runtime implementation. The baseline repository's complete scalar matrix is not closed by this draft. [R03,L11–L13](RESEARCH_SOURCES.md)

A backend MUST reject unimplemented primitive semantics for a requested executable profile. It MUST NOT fall back to JS number, Rust debug/release overflow, host string length or arbitrary unchecked conversion.

Target-word values require an explicit width profile. Float contracts concern specified floating behavior or a proved relation to a mathematical model; they are not automatically real-number theorems. Invalid numeric/string boundary conversions use a specified error path.

## 9. Specifications and contracts

A specification can be an ordinary proposition/theorem about an ordinary definition. The final checked theorem MUST refer to the actual implementation, requested specification and fixed semantic dependencies. Proving unrelated generated obligations is insufficient.

The native intrinsic verification capability is experimental. At the proposed pin it uses one optional requires and one optional ensures clause; compound conditions use predicates/conjunction. It generates a separate specification theorem and uses the pinned library/options. PSC3 MUST NOT silently invent a stronger function type or a different contract semantics. [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Verified callers establish the preconditions needed by their correctness argument. A merely type-checked caller does not inherit that proof. A proof-bearing API may instead explicitly request a proof/subtype using ordinary dependent types. Foreign callers need appropriate validating wrappers; `.d.ts` is not a runtime guard.

Stateful, error and asynchronous contracts must state the relevant outcomes and assumptions. A successful-result clause alone cannot establish that success occurs. Total correctness needs termination/liveness evidence under stated resource/environment conditions.

Ghost erasure MUST retain runtime-relevant witnesses and data. Proof fields, Booleans and indices cannot be removed solely because they sound verification-related.

## 10. Modules, initialization and platform interfaces

Logical imports are deterministic and mapped to exact package versions/contents. Foreign package resolution is an adapter/build responsibility recorded by deployment profile, not the meaning of Lean imports. Native module initialization and visibility need exact supported semantics; application startup SHOULD be explicit entry points rather than hidden top-level side effects.

Source, elaboration and runtime dependency closures are separately recorded. Private source visibility is not a security sandbox. Build-time plugins require independent capability permissions and isolation appropriate to untrusted code.

The platform offers typed interfaces for network, storage, time, randomness, UI and process services. Exported API and contract information is generated from the same schema/declaration definitions where applicable. External operations remain assumptions unless their implementation/model relation is established.

## 11. UI and full-app authorship

The standard application profile SHOULD allow complete browser, service and CLI applications without user-authored TS/JS glue for its supported APIs. Runtime and framework adapters may be foreign implementations with explicit identities and assumptions.

UI is available as ordinary library values and functions. The optional `.psx` form expands to those same values. A framework-specific adapter cannot skip Core checking or grant broad proof status to the renderer, browser or remote services.

Source sharing across server/client requires capability and serialization checks. A shared type name alone does not prevent a client dependency from reaching server-only code. Code splitting, workers, SSR and hydration are individually profiled features.

## 12. Compilation and evidence

The shared path is source interpretation, kernel admission, erasure, Runtime IR and target lowering. Existing TS/Rust and proposed direct JS/Wasm consume the same semantic representation. Target-specific layout must not become a new source interpretation.

Preservation is behavioral equivalence/refinement under explicit representation, effect and resource relations, not textual identity. A proof about an internal AST does not cover a faulty printer; bind evidence to the exact emitted files, linked runtime and dependencies. [C01](RESEARCH_SOURCES.md#compilation-and-targets)

A compiler building the checker executable has a build-trust role distinct from a compiler producing candidate proof terms. Self-hosting, reproducibility and differential agreement are useful evidence but not soundness theorems.

## 13. Diagnostics, incomplete work and release policy

Editors may retain incomplete goals and source. A release policy MUST distinguish admitted evidence from provisional results. Statuses include accepted, rejected, unsupported, search incomplete, resource limit, cancelled and internal error. A timeout is not proof that the requested property is false.

Diagnostics identify source span, expansion span when relevant, logical module, expected/actual types, unresolved obligation, target capability and actionable alternatives. The same information SHOULD be machine-readable for tools and AI agents.

No agent may resolve a failure by changing an approved specification, its dependencies or assumption policy without an explicit reviewed change. Changes to the verifier, CI or release authority are outside an implementation agent's implicit permission.

## 14. Freeze conditions

A stable edition requires exact source/library closure, essential scalar/collection bindings, complete semantics for its advertised effects, accepted example corpus, migration rules and independently reviewable evidence labels. A full-app release additionally needs actual application workflows and tool integration; a compiler fixed point alone is insufficient.

Deferred features may remain outside a release. They must not be silently accepted with weaker semantics. See [ROADMAP_AND_CONFORMANCE.md](ROADMAP_AND_CONFORMANCE.md) for concrete promotion gates.
