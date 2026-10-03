# ProofScript Complete Reference

**ProofScript v0.9.0 draft revision 2 · `ps-0.9-r2` · 3 October 2026.**

A ProofScript-oriented writing guide followed by a complete, attributed adaptation of the substantive articles in the repository's Lean reference mirror. This is a reference collection, not a claim that all features have been implemented or proved.

**Semantic authority:** Lean 4.34.0 stable, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. **Source mirror:** `dwijayuda/pskernel` at `65369c75c7b63124f1ba7f2289e573181db281f0`, subtree `study/lean4-language-reference/`.

The mirror includes material labelled **Lean 4.34.0-rc2**. Historical or stale source details do not override the stable pin. In particular, references to the old `Lean.reduceBool`, `Lean.reduceNat`, `Lean.ofReduceBool`, `Lean.ofReduceNat`, and `Lean.trustCompiler` kernel mechanisms are not current PSC rules. Four HTML files are placeholders without a reference article; their names are retained in the coverage manifest.

**Writing policy:** no added general declaration semicolons; native layout remains significant, including within registered braced decorations. Keep `:=`, `fun`, native patterns, native namespace scopes and explicit assumptions. `function` and `const` are aliases of native definitions, not JavaScript runtime declarations.

**How to read the detail:** source-level examples may use inherited Lean spelling, which is part of the declared language profile where supported. Conservative presentation aliases are separately recorded. Signatures and EBNF are reference displays, not standalone programs. Original examples may deliberately fail or depend on an earlier context. Compiler diagnostics and proof states are retained separately from program text. Native C/FFI, Lake/Elan, platform and historical release material keeps its original identity.

Inherited prose and examples are derived from *The Lean Language Reference*, Lean FRO and contributors, under Apache-2.0. They are not independently reauthored claims about PSC implementation. This adaptation adds ProofScript writing guidance, explicit grammar/runtime boundaries, clean Markdown presentation and coverage records. See `licenses/Lean-Reference-Apache-2.0.txt` and `NOTICE.md`.

## Writing guide

# 1. Getting started with ProofScript

Use ProofScript as an ordinary programming and proof language. The surface changes presentation, not the underlying meaning. In this edition function and const are definition aliases, applications may use comma-separated calls, and selected declaration and match bodies may use braces. TypeScript familiarity does not introduce JavaScript truthiness, prototype objects, arbitrary nullability, or implicit returns. The inherited detail below remains a reference for the same logical foundation, not evidence that the current PSC compiler implements every feature.

**ProofScript presentation candidate:**


```proofscript
function greet(name: String): String :=
  "Hello, " ++ name

const greeting: String := greet("Ada")

theorem greetAda: greet("Ada") = "Hello, Ada" := by
  rfl
```

**Compiler obligation.** Keep the ps-0.9-r2 grammar identity, the stable Lean semantic pin, and implementation coverage separate. Do not rename the upstream history into ProofScript release history.


# 2. From source to checked declarations

Parse by grammatical category, lower owned syntax, and elaborate the result in the recorded environment. An application is elaborated with expected types, implicit arguments, default arguments, coercions, and instance search. Generalized field notation does not always put its receiver in the first explicit parameter. Admission of the resulting declarations establishes a different property from source correspondence. Executable compilation additionally needs relevance, primitive representations, and backend preservation.

**Compiler obligation.** Use separate candidate and checked-module APIs. Unknown syntax, unresolved proof obligations, failed checks and exhausted budgets must not become accepted output.


# 3. Inspecting types, values and proofs

Use native inspection commands in supported lifted command slots. A #check result describes typing; #reduce performs logical reduction; #eval uses an execution route. Runtime output is not automatically evidence of a proposition. Source maps should report original .ps locations, and theorem inspection should expose exact assumptions. Commands and command-line switches belonging to the Lean executable are reference-tool operations, not newly implemented PSC commands.

**ProofScript presentation candidate:**


```proofscript
#check Nat
#check Nat.add

#reduce Nat.add(2, 3)
#eval Nat.add(2, 3)
```

**Compiler obligation.** D-CALL in command term positions requires an explicit lifted category. Preserve options and imported registrations during incremental checking.


# 4. Dependent types and checked evidence

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**ProofScript presentation candidate:**


```proofscript
universe u

function identity {α: Type u}(x: α): α := x

function retain(n: Nat, i: Fin n): Fin n := i

theorem keepProof {P: Prop}(h: P): P := by
  exact h
```

**Compiler obligation.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.


# 5. Files, imports and module identities

A .ps module uses the selected ProofScript grammar; .lean uses native syntax. Canonical .lean output is a trace, not a fallback sibling. Select one source snapshot per logical module and reject ambiguous candidates. Imports retain native module syntax. Package resolution may use npm, but the resolved logical imports, options, extensions and executable capabilities must be explicit.

**Compiler obligation.** Keep source, elaboration and executable dependency closures separate. Do not silently process earlier commands in the final module environment.


# 6. Organizing declarations

Retain namespace ... end and section ... end. These commands control names, local variables, options and registrations; they do not create JavaScript objects. Section-variable inclusion follows native rules, including the distinction between theorem statement dependencies and proof-body usage. Scoped notation and instances must retain their exact environments.

**ProofScript presentation candidate:**


```proofscript
namespace Arithmetic

function square(n: Nat): Nat := n * n

theorem squareZero: square(0) = 0 := by
  rfl

end Arithmetic
```

**Compiler obligation.** Do not replace command scopes with a generic brace parser or move declarations past environment-changing commands.


# 7. Definitions, aliases and recursive programs

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**ProofScript presentation candidate:**


```proofscript
function decorate(
  name: String,
  suffix: String := "!"
): String := name ++ suffix

const label: String := decorate("Ada", suffix := "?")

function incrementTwice(n: Nat): Nat :=
  helper(helper(n))
where {
  helper(x: Nat): Nat := x + 1
}
```

**Compiler obligation.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.


# 8. Assumptions are part of the theorem

An axiom adds an assumption, not an implementation. Classical mathematics may use reviewed foundational assumptions, while stricter constructive profiles can restrict them. Report the transitive dependencies of each requested theorem. Research/editor placeholders are not strict-release evidence. A theorem about a foreign model does not by itself prove the external service implements that model.

**ProofScript presentation candidate:**


```proofscript
theorem implicationIdentity {P: Prop}(h: P): P := by
  exact h

#print axioms implicationIdentity
```

**Compiler obligation.** Check the exact statement, referenced definitions and approved axiom identities. Do not restore pre-final native-evaluation kernel hooks from the mirror.


# 9. Attributes and registrations

Attributes attach native metadata or invoke registered handlers. They may affect elaboration, simplification, instances, code generation or documentation. They do not grant proof authority. Keep the actual attribute names, scopes and handler identities rather than replacing them with TypeScript decorators.

**Compiler obligation.** Unknown attributes are unsupported unless declared in the environment. Tactic or derive outputs still require normal checking, and host execution permissions are a separate boundary.


# 10. Interfaces through typeclasses

Classes are native type-directed interfaces, not JavaScript classes. Instances provide dictionaries and associated evidence. Inference uses the pinned priority and search behavior, so importing an instance can affect elaboration. Derived instances are generated declarations that must be checked. Boolean equality and hashing require laws when used for logical claims.

**ProofScript presentation candidate:**


```proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length
}
```

**Compiler obligation.** Braced class fields use native field-declaration layout. Instance initializers use their own native sequence grammar, including semicolons only where that grammar permits them.


# 11. Explicitly explainable conversions

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler obligation.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.


# 12. Runtime representations and external implementations

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler obligation.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.


# 13. Expressions, calls, records and matches

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**ProofScript presentation candidate:**


```proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some n => n
  }

function bounded(n: Nat): Nat :=
  if (n <= 10) { n } else { 10 }
```

**Compiler obligation.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.


# 14. Constructing proofs with tactics

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**ProofScript presentation candidate:**


```proofscript
theorem twoTruths: True ∧ True := by {
  constructor; trivial; trivial
}

theorem twoTruthsAll: True ∧ True := by {
  constructor <;> trivial
}
```

**Compiler obligation.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.


# 15. Simplification and normal forms

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**ProofScript presentation candidate:**


```proofscript
function plusZero(n: Nat): Nat := n + 0

theorem plusZeroIdentity(n: Nat): plusZero(n) = n := by
  simp [plusZero]
```

**Compiler obligation.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.


# 16. Integrated proof search with grind

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**ProofScript presentation candidate:**


```proofscript
theorem equalityChain {α: Type}(a: α, b: α, c: α)
    (hab: a = b)(hbc: b = c): a = c := by
  grind
```

**Compiler obligation.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.


# 17. Verification conditions and program logic

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**ProofScript presentation candidate:**


```proofscript
import Std.Internal.Do
set_option experimental.intrinsic true

def unchanged (n : Nat) : Id Nat
    ensures result => result = n :=
  pure n
```

**Compiler obligation.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.


# 18. Sequencing through native monads

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

**ProofScript presentation candidate:**


```proofscript
function total(xs: List Nat): Nat :=
  Id.run(do {
    let mut result := 0
    for x in xs do {
      result := result + x
    }
    return result
  })
```

**Compiler obligation.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.


# 19. Truth, connectives, quantifiers and equality

Truth and falsity, conjunction/disjunction, implication, negation, universal/existential quantification and equality keep their native definitions. An existential proof contains logical witness evidence, but elimination restrictions determine when it can construct runtime data. Equality transports dependent values only through justified terms. Computed Boolean comparison does not automatically produce equality evidence.

**ProofScript presentation candidate:**


```proofscript
theorem swapAnd {P: Prop}{Q: Prop}(h: P ∧ Q): Q ∧ P := by
  exact ⟨h.right, h.left⟩

theorem existsSelf(n: Nat): ∃ m: Nat, m = n := by
  exact ⟨n, rfl⟩
```

**Compiler obligation.** Preserve Prop elimination, proof irrelevance and universe rules. Erasure may remove irrelevant proofs but not the data they certify.


# 20. Values, collections and exact operations

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**ProofScript presentation candidate:**


```proofscript
structure User where {
  name: String
  active: Bool
}

function activate(user: User): User :=
  { user with active := true }

function decoratedNames(users: List User): List String :=
  users.map(fun user => user.name ++ "!")
```

**Compiler obligation.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.


# 21. IO and real application boundaries

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**ProofScript presentation candidate:**


```proofscript
function announce(name: String): IO Unit := do {
  IO.println("Hello, " ++ name)
  IO.println("Done")
}
```

**Compiler obligation.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.


# 22. Iteration, consumers and proofs

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler obligation.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.


# 23. Extending syntax without changing logic

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**ProofScript presentation candidate:**


```proofscript
infixl:65 " <+> " => Nat.add

function combined(x: Nat, y: Nat): Nat := x <+> y
```

**Compiler obligation.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.


# 24. Build tools, packages and reference oracles

Lake and Elan in the source are Lean tools. Their commands, configuration and APIs remain native-host reference documentation. ProofScript may use npm package metadata, lockfiles and generated canonical sources, but that does not turn a Lake API into a PSC API. Pin source edition, grammar, semantic commit, dependencies, axiom policy, runtime and target separately.

**Compiler obligation.** Reference-tool execution does not imply a standalone dependency on Lean at runtime. Self-hosting and repeatable builds are engineering evidence, not compiler-preservation proofs.


# 25. Independent validation of exact claims

Validate the requested statement and its definitions in the intended environment, not simply the theorem name. A proof of a modified predicate can be valid but irrelevant to the approved requirement. Check transitive axioms, incomplete evidence, external models and compiler assumptions separately. Independent checkers and replays strengthen evidence only within their measured scopes.

**Compiler obligation.** A checker executable has its own build-trust boundary. Unsigned or signed reports and artifact hashes identify data but do not replace declaration admission.


# 26. Errors in ProofScript source

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler obligation.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.


# 27. Lean release history and compatibility context

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler obligation.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.


# 28. Native platforms versus PSC target profiles

Upstream platform support describes the native Lean distribution at the source snapshot. It is not a promise of all ProofScript backends, npm bindings, browsers or Wasm embeddings. Target architecture, word width, runtime primitives and external capabilities belong in a separate executable profile.

**Compiler obligation.** An unsupported platform capability must reject or select an explicitly weaker named profile; no hidden substitution is permitted.


# 29. Finding declarations and syntax

The inherited index is retained as a navigation aid to names, technical terms and grammar entries. The new API inventory records source page, entry kind, exact signature and source identity. An entry appearing in the index does not establish standalone compiler coverage or runtime availability.

**Compiler obligation.** Use explicit coverage and capability manifests. Repeated documentation entries and overload families must not be counted as distinct proved implementations.

