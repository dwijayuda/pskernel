# The ProofScript Language Reference v0.9.0

**Compiler-oriented reference candidate · draft revision 2 · 3 October 2026**  
**Design:** a small, TypeScript-friendly surface over faithfully preserved Lean 4 semantics.  
**Normative semantic pin:** Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.  
**Source lineage:** ProofScript v0.7.0; v0.6.1 supplies compatible historical context.  
**Grammar identity:** `ps-0.9-r2` / `lean-native-separators`; supersedes the earlier v0.9 draft's ProofScript-only semicolon rules.  
**Status:** proposed specification, not a released compiler, a proof of soundness, or a claim of complete Lean frontend implementation.

This document specifies the ProofScript-owned grammar, its composition with a pinned Lean grammar, canonical lowering, semantic and runtime boundaries, compiler interfaces, and conformance obligations. It is designed to be implemented rather than merely to describe attractive future features. The inherited language is specified by exact reference, not by a second, approximate transcription of Lean's entire extensible grammar.

A feature marked **specified** has a proposed contract. **Oracle-tested examples** are particular canonical Lean programs checked during this research. Neither label means that a production ProofScript parser has been proved correct. The original research and execution record is in [the study audit](research/STUDY_AUDIT.md). Revision-specific changes and validation are in [the revision notes](REVISION_NOTES_R2.md) and [semicolon evidence](research/SEMICOLON_REVISION_AUDIT.md).

> **Make Lean easier to approach; do not make its meaning approximate.**

## Contents

- [Part I — Identity, authority, and conformance](#part-i--identity-authority-and-conformance)
- [Part II — Lexical syntax and grammar composition](#part-ii--lexical-syntax-and-grammar-composition)
- [Part III — Declarations, functions, and data](#part-iii--declarations-functions-and-data)
- [Part IV — Computation, effects, and modules](#part-iv--computation-effects-and-modules)
- [Part V — Logic, theorem proving, and verification](#part-v--logic-theorem-proving-and-verification)
- [Part VI — Compiler and preservation contracts](#part-vi--compiler-and-preservation-contracts)
- [Part VII — Libraries, interoperability, and applications](#part-vii--libraries-interoperability-and-applications)
- [Part VIII — Tooling, migration, and release assurance](#part-viii--tooling-migration-and-release-assurance)
- [Part IX — Consolidated grammar and reference tables](#part-ix--consolidated-grammar-and-reference-tables)
- [Part X — Research basis and implementation sequence](#part-x--research-basis-and-implementation-sequence)

---

# Part I — Identity, authority, and conformance

## 1. Purpose and design principles

ProofScript is a general-purpose programming and theorem-proving language whose verified meaning is obtained through Lean-compatible elaboration and kernel admission. It supports ordinary application programming, mathematical definitions, proofs, and explicit program specifications. A developer need not prove a functional-correctness theorem for every function merely to write a typed application.

The design chooses a small number of visible decorations: familiar declaration aliases, comma-separated calls and parameters, and braces in named grammatical categories. It retains Lean vocabulary where changing the spelling would hide an important concept: `Prop`, `Type`, `Sort`, `def`, `theorem`, `structure`, `inductive`, `class`, `instance`, `fun`, `match`, `with`, `where`, `by`, `do`, `:=`, and equality.

The priorities, in order, are:

1. Preserve the declared meaning and accurately report evidence and assumptions.
2. Keep the surface grammar regular within each category and preserve established source distinctions.
3. Make everyday functions, records, collection APIs, errors, modules, and application tooling approachable.
4. Reuse existing semantic mechanisms instead of introducing parallel type, effect, or proof systems.
5. Make elaboration, lowering, and foreign boundaries inspectable.
6. Optimize only under the relevant semantic and representation obligations.

Small kernel size and user-facing simplicity are separate budgets. Moving a complicated feature into an elaborator removes neither its learning cost nor its interactions. Go's engineering account informs the emphasis on tools, dependency control, and maintenance; it does not require copying Go's type system. [G1]

**Non-goals of the base surface:** parsing arbitrary TypeScript; preserving arbitrary JavaScript dynamic behavior; changing Lean's typeclass search; adding prototype inheritance, truthiness, unchecked casts, implicit nullability, or a new effect calculus; making every mathematical definition executable; or equating type checking with verified application behavior.

## 2. Normative language and authority

**MUST**, **MUST NOT**, **SHOULD**, and **MAY** express requirements for a future implementation claiming this reference. An example is informative unless identified as a conformance case. An example's spelling alone does not authorize a new production.

Authority is ordered as follows:

| Concern | Authority |
|---|---|
| ProofScript-owned syntax and lowering | This v0.9 document and its matching feature registry. |
| Inherited syntax and elaboration | The pinned Lean source, its selected imports, parser registrations, and options. |
| Logical declaration checking | The selected pinned Lean logical profile and explicit axiom policy. |
| Executable primitives | Exact selected declaration/runtime definitions and the executable profile. |
| Historical source interpretation | The specification selected by that source's declared edition. |
| Tutorial and design explanation | Informative only; cannot override the authorities above. |

The repository baseline inspected was `65369c75c7b63124f1ba7f2289e573181db281f0`. The v0.7 reference blob is `8b4097363c5ade7d594b66706b94dff62400ff53`. Its canonical Lean pin is retained. Choosing a newer Lean patch requires an explicit reference revision and new evidence; the word “latest” is not a semantic identity. [R1, R2]

The v0.7 package describes a candidate reference with S1 evidence and a production-migration caveat. This new candidate does not retroactively close those gates, supersede old repository policies, or activate v0.9 in the current compiler. A compiler MAY reject the entire v0.9 profile until it implements the relevant contracts.

## 3. The central semantic relationship

For source `p` in environment `E`, define the intended meaning by the partial canonical lowering relation:

```text
parsePS09(E, p) = syntax
lower09(E, syntax) = canonicalLeanSyntax
meaningPS09(E, p) := meaningLean434(lowerEnv(E), canonicalLeanSyntax)
```

“Partial” here means that unsupported, malformed, or incompatible input is rejected. It is not permission for successful lowering to leave semantic holes.

The environment includes imports, module identities, macro and notation registrations, options, instances, declaration dependencies, and the selected profile. Meaning is not a function of source characters in isolation.

For a logical claim, the native interpretation is the admitted declaration environment. For an execution claim, it also includes the selected native executable semantics and primitive/runtime models. Kernel normalization alone is not an execution model for arbitrary partial definitions, IO, or runtime replacements. The execution relation must be stated separately where those constructs are involved.

A reference implementation MAY use official Lean to elaborate the canonical output. A standalone implementation MAY implement the same supported elaboration itself. Absence of Lean at runtime changes implementation dependencies, not the meaning of accepted programs.

This definition does not by itself prove that a parser, lowerer, source printer, standalone elaborator, kernel executable, or backend implements the intended relation. Each has its own proof or validation obligation. A valid proof of a changed proposition remains a proof of the wrong claim.

## 4. Source files and source identity

### 4.1 `.ps`

A `.ps` file uses the selected ProofScript edition. It may contain inherited Lean forms and the registered decorations/exceptions of that edition. It is not a `.lean` file with a different extension. Canonical lowering may change punctuation, declaration keywords, and AST structure while preserving the specified meaning.

### 4.2 `.lean`

A `.lean` file uses native Lean syntax under the pinned environment. ProofScript-only productions MUST NOT be injected into its parser. A standalone compiler can support a documented subset; valid native Lean outside that subset is **unsupported**, not a license to reinterpret it.

### 4.3 `.psx`

The suffix identifies an explicitly selected non-base source or extension profile. It does not imply automatic verification, JSX compatibility, or a particular UI language. An optional UI profile must name its grammar, expansion, environment, and assurance boundaries. The ordinary component library must remain usable from `.ps` and supported `.lean`.

### 4.4 Unique module input

Each logical module resolves to one exact source snapshot. When both `M.ps` and `M.lean` are present, a manifest must explicitly select one or the build rejects ambiguity. A generated `.lean` trace is not a fallback source. Missing dependencies MUST NOT be replaced with stale siblings, different branches, or host-installed packages silently.

Generated inputs must identify their generator and source provenance. Incremental checks and release publication must operate on the bytes actually checked, not reread a mutable file after approval.

## 5. Capabilities and implementation profiles

There is one semantic language, with separately reported implementation capabilities. Capabilities restrict coverage; they MUST NOT change a construct's meaning.

| Profile family | Meaning |
|---|---|
| `reference-lean434` | The overlay lowers supported source for the pinned official Lean environment. |
| `standalone-lean434` | An owned frontend/checker implements an explicitly listed subset of that meaning. |
| `exec-js`, `exec-ts`, `exec-rust`, `exec-wasm` | A supported executable closure and target runtime/ABI. |
| `intrinsic-contracts-434` | The experimental pinned intrinsic-verification environment. |
| `host-meta` | Explicit host metaprogramming and its execution permissions. |
| Named extension profile | Additional versioned syntax or library environment with its own evidence. |

An implementation manifest MUST enumerate supported feature IDs and inherited category registrations, with their dependencies. “Supports Lean” is insufficient. Grammar coverage, elaboration coverage, logical coverage, tactic/library coverage, runtime coverage, and preservation coverage are different fields.

A bootstrap implementation subset can be smaller than the public profile. A compiler does not need to use every feature it implements. Full applications are a platform goal, not a requirement that the compiler bootstrap depend on all platform libraries.

## 6. Acceptance results and assurance labels

The public checking interface distinguishes at least:

```text
accepted
malformed-source
unsupported-feature
incompatible-environment
elaboration-rejected
kernel-rejected
proof-search-incomplete
resource-limit
cancelled
internal-error
```

Only the appropriate accepted result authorizes the exact requested claim. Unknown versions, exhaustion, internal exceptions, or failed checks MUST NOT become successful verification. A resource limit is not evidence that the proposition is false.

Reports distinguish: source parsed; source elaborated; declarations admitted; contract theorem proved; termination proved; source correspondence evidenced; erasure preserved; target preserved; and external assumptions. Tests and execution observations are separately recorded.

Retain the v0.7 evidence ladder where useful: S1 specified, S2 reference properties proved, S3 production implementation refined/validated, S4 formal-model connection, and S5 correspondence to a pinned official implementation. An ordinary successful Lean example is not S2 for a ProofScript overlay.

## 7. TypeScript-oriented design choices

TypeScript's documented strengths include contextual inference, generics, object-shaped APIs, discriminated unions, modules, and editor-oriented workflows. Its structural compatibility and deliberate soundness tradeoffs serve JavaScript compatibility. ProofScript uses the workflow lessons without importing those tradeoffs into its logic. [T1–T4]

| Familiar task | ProofScript mechanism | Deliberate difference |
|---|---|---|
| Define a function | `function f(x: T): U := e` | No hoisting, `this`, or universal return statement. |
| Define a constant | `const x: T := e` | Alias of a Lean definition, not object freezing. |
| Call with arguments | `f(x, y)` | Canonically curried Lean application. |
| Model records | `structure ... where { ... }` | Declared nominal/logical identity. |
| Model alternatives | `inductive` plus `match` | Exhaustive, potentially dependent elimination. |
| Generic function | Implicit `{α: Type}` and inference | No substitution of TS `<T>` for dependent binders. |
| Callback | `fun x => e` | One unambiguous lambda vocabulary. |
| Optional data | `Option α` | No implicit null/undefined. |
| Recoverable failure | `Except ε α` or an explicit user-defined result type | No silent import of host exceptions. |
| Async platform work | Native effects or a separately named library model | Promise does not define Lean `Task`. |
| Dynamic API input | Opaque foreign value followed by validation | No unchecked path to arbitrary proof-bearing data. |

The base does not add every attractive spelling. Optional chaining, JSX, bare arrow lambdas, ES-style imports, and brace-bodied functions can each be studied, but none is implicitly accepted by this reference.

---

# Part II — Lexical syntax and grammar composition

## 8. Character stream, comments, and positions

The base uses the pinned Lean lexical treatment of identifiers, literals, Unicode, escaping, and tokens. Compiler transport accepts UTF-8 source and MUST preserve a mapping from original byte offsets to editor positions. An implementation must not silently normalize identifiers or Unicode characters into different names.

Lean comments are retained:

```proofscript
-- A line comment.
/- A block comment, with /- nesting -/ where Lean allows it. -/
```

Documentation comments retain their native categories. Text inside comments, strings, character literals, quotations, and antiquotations is not rewritten as ordinary expression syntax.

JavaScript `//` and `/* ... */` comments are not added by the base profile. The v0.7 discussion used C-style comment-shaped text in an adjacency example; this reference uses the actual inherited spelling `f/- comment -/(x)`. That source declines D-CALL ownership. It does not turn arbitrary C-style text into a Lean comment.

Source spans MUST preserve the distinction between actual adjacency and separation by whitespace or comments. Normalizing away trivia before deciding ownership is incorrect.

## 9. Identifiers, keywords, and hygiene

Inherited identifier forms include the pinned native escaped and hierarchical identifiers. `const` and `function` are contextual declaration-head aliases. Their ownership requires the matching declaration production; the implementation MUST NOT globally rewrite every occurrence of those words.

An identifier with a familiar foreign spelling is not necessarily forbidden. A user may define an ordinary Lean-compatible name. The prohibition is on introducing a privileged `any` type, implicit truthiness, or another semantic escape merely from a spelling.

Names introduced by lowering MUST be hygienic. Preserve user binding identity and native macro scopes/pre-resolved references; do not rely on a “sufficiently unusual” textual prefix. Generated name allocation must either establish freshness or reject exhaustion. An unchecked `_overflow` fallback is not a freshness algorithm.

ProofScript-owned lowering normally introduces no new logical names. When auxiliaries are unavoidable, their scope, dependency, provenance, and relationship to source declarations must be explicit. [L7]

## 10. Punctuation and grammatical categories

| Token | Meaning in its relevant category |
|---|---|
| `:=` | Definition body, binding, named-argument assignment, or structure update as specified. |
| `=` | Propositional equality, not native assignment. |
| `==` | Boolean comparison through the selected Lean machinery. |
| `=>` | Native lambda/match/tactic binder delimiter where that category admits it. |
| `->` / `→` | Native function/Pi arrow. |
| `{ ... }` | A specific registered body, native record, binder, tactic block, or do sequence—not one universal block. |
| `;` | Only the role assigned by the corresponding pinned native Lean category; never a general ProofScript declaration terminator. |
| `<;>` | Native tactic combinator; distinct from a plain tactic-sequence `;`. |
| `,` | Call/header separator in a registered decoration; native meaning elsewhere. |
| `.` | Native hierarchical name/projection/generalized field notation under its own rules. |

No pass may globally erase semicolons, replace braces, introduce spaces before every parenthesis, replace `=` with `:=`, or strip `then` from arbitrary source. Canonical lowering operates on owned AST nodes and declared child slots.

## 11. Surface classes

| Class | Name | Requirement |
|---|---|---|
| L | Inherited Lean | Use the pinned category and its meaning. |
| D | Conservative decoration | Match a specified discriminator without displacing protected native neighbors. |
| E | Surface exception | Own an explicitly delimited category/context, with deterministic canonical lowering. |
| X | Semantic divergence | Excluded from the Lean-compatible base. |

A registered E form may intentionally differ from native parsing. The reference therefore does not promise that every string accepted by Lean receives identical parsing as `.ps`. It promises inherited behavior for L forms, protected-neighbor preservation for D forms, and documented ownership for E forms.

The parser must commit after a decisive owned prefix. A malformed owned construct cannot be retried as a permissive native fragment merely to get a successful parse. Conversely, when the discriminator never matched, ordinary native parsing remains available.

## 12. Grammar composition and inherited grammar

For each category `C`, parsing uses:

```text
1. the registered E production whose context and discriminator match;
2. the registered D production whose discriminator matches;
3. the exact selected native parser for C;
4. a diagnostic when no supported production succeeds.
```

`DEFER` is a parser-ownership result, not an assertion that input is valid. A standalone parser must implement the inherited forms it advertises. It cannot store unparsed strings and treat them as semantically admitted.

The composition operator is:

```text
Lift(P) = native production P with only its registered child-category slots
          replaced by the corresponding ProofScript-aware parser/lowerer.
```

All other children, delimiters, precedence, options, and binding information are preserved. A lifted `fun` body may contain a decorated term; its binder grammar remains native. A match RHS may contain D-CALL; its patterns do not gain constructor-call syntax. A tactic's explicit term argument can use the selected term category without changing tactic semicolon combinators.

The exact inherited production source is `study/lean4-4.34.0/src/Lean/Parser/`, including `Basic`, `Term`, `Do`, `Command`, `Tactic`, `Module`, `Level`, `Attr`, `StrInterpolation`, and `Syntax`, plus parser registrations introduced by the pinned declared imports. This is normative incorporation by reference. It is not a claim that a small EBNF reproduces all of Lean's extensible grammar. [L1–L3]

## 13. Precedence, grouping, and expression boundaries

Native precedences and operator registrations remain authoritative. D-CALL is a postfix operation on a syntactically completed callable head. It binds before an enclosing whitespace application consumes that head as an argument.

```text
f(x) + y       lowers to (f x) + y
g f(x)         lowers to g (f x)
(g f)(x)       lowers to (g f) x
f(x).field     lowers to (f x).field
f(x)(y)        preserves the two syntactic application groups
```

Preserve grouping boundaries that can affect elaboration, optional arguments, or expected types. Lowering MUST NOT flatten every nested call into one argument list. Within a single D-CALL, preserve one native application argument sequence for elaboration; binary core application is constructed later by the native elaborator.

A completed head is an identifier (including a supported dotted constructor identifier), a parenthesized term, a projection/indexing expression whose native grammar produces a completed head, or an already completed D-CALL. Imported syntax may serve as a head only through an explicit compatible category registration. Parenthesize an arbitrary lower-precedence term before calling it.

Argument parsing stops at a comma or the matching `)` only at the call's own delimiter depth. Delimiters in records, strings, lambdas, nested calls, quotations, or native syntax are not separators of the outer call.

## 14. D-CALL: positional, empty, and grouped calls

**Feature ID:** `D-CALL`.

The opening `(` must begin immediately after the end of the callable head in the original source. Whitespace or a comment breaks that discriminator.

```proofscript
add(1, 2)
normalize(transform(x))
f()
f((x, y))
```

Canonical forms:

```lean
add 1 2
normalize (transform x)
f ()
f (x, y)
```

An empty argument list denotes **one Unit argument**. It does not mean “invoke a zero-parameter function,” “instantiate only implicit parameters,” or “supply every default.” Parameterless constants are referred to without a call; a thunk has an explicit `Unit → α` type or another named suspension abstraction.

Protected neighbors:

| Source | Ownership and interpretation |
|---|---|
| `f(x, y)` | D-CALL; two native application arguments. |
| `f((x, y))` | D-CALL; one product/tuple argument. |
| `f (x, y)` | Native application to one tuple. |
| `f (x)` | Native application to one parenthesized term. |
| `f/- comment -/(x)` | No D-CALL ownership; the native parser decides. |

D-CALL is not enabled in patterns. `.some(x)` is not a constructor pattern. A constructor term `.some(x)` is a term-level call when its native contextual constructor resolution is supported.

## 15. v0.9 call conveniences: explicit named arguments and trailing commas

Two narrowly defined additions are specified for the v0.9 overlay. They are new S1 requirements, not claims of existing compiler implementation.

### 15.1 `D-NAMED-CALL`

An argument in a D-CALL can be `name := PS_TERM`. It lowers to the native named-argument node `(name := loweredTerm)` within the same application sequence.

```proofscript
connect(host, timeout := 5000)
```

```lean
connect host (timeout := 5000)
```

A named argument is recognized only at an argument start when the next tokens are an identifier and `:=`. It is not a general assignment expression. `timeout: 5000` is not this grammar.

Duplicate names within the same call are rejected with a direct diagnostic. Names are resolved according to native parameter names; unavailable names and impossible applications are elaboration errors. Positional and named arguments retain native matching, implicit insertion, dependent elaboration, and default semantics. The lowerer must not invent TS overload dispatch or reorder evaluation on the basis of source keyword order.

Native named arguments in whitespace application remain available without this feature. This addition removes no protected neighbor.

### 15.2 `D-TRAILING-COMMA`

A **nonempty** decorated call or comma-separated explicit header group MAY end with one trailing comma. The comma carries no argument or binder and is omitted in canonical lowering.

```proofscript
add(1, 2,)
function add(x: Nat, y: Nat,): Nat := x + y
```

Empty entries, doubled commas, and `f(,)` are rejected. A trailing comma is not applied to inherited tuple/pattern syntax by this rule. These constraints make multiline editing convenient without changing the function model.

## 16. Declaration boundaries and native semicolons

**Policy:** ProofScript introduces no general statement/declaration terminator. Semicolons occur only where the corresponding pinned Lean category admits them. This policy is part of grammar revision `ps-0.9-r2`, not a formatting-only option.

The ordinary decorated definition shape is:

```text
[modifiers] (def | const | function) name header := body suffixes
```

No outer `;` follows the definition. Its body and suffixes have the same boundary discipline as the canonical native definition. This applies equally to a literal, application, record, conditional, match, proof term, or `do` expression. Aliases and decorations do not choose a different termination convention.

```proofscript
function activate(user: User): User :=
  { user with active := true }

function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some x => x
  }
```

The brace closes its own record or match construct. A declaration boundary is determined by the enclosing native-compatible grammar, including layout, nesting, and suffixes—not by appending a semicolon or treating every newline as an end token.

### 16.1 Native roles are preserved

| Context | Revision-2 rule |
|---|---|
| `def`, `const`, `function`, theorem and other declaration kinds | No added command terminator; use the corresponding native body/suffix boundary. |
| Structure/class field **declarations** | Native `structFields` layout; no added field semicolons. |
| Inductive constructors and match alternatives | Native constructor/alternative markers and layout; no added alternative terminator. |
| Instance `where` field **initializers** | Preserve native `whereStructInst` / `sepByIndent` separators, including `;` where admitted. |
| Local `where` declarations | Preserve native local-declaration sequence separators, including optional/trailing `;` where admitted. |
| Local `let` expression | Preserve native `let x := value; body` and its layout form. |
| `do` sequence | Preserve native semicolon/newline sequencing and its nested scopes. |
| Tactic sequence | Preserve native `;` sequencing and the different `<;>` combinator. |
| Record **values** | Preserve native field-assignment syntax and comma/layout rules; do not substitute structure-declaration separators. |
| Literal, comment, quotation, or antiquotation | Never edit punctuation by textual appearance; parse in its own category. |

A semicolon that happens to be the last token on a line is not necessarily a declaration terminator. For example, it can belong to the final native `do` element, an instance-field sequence, or a local-declaration sequence. The parser and formatter must decide ownership from the syntax tree, not from a trailing-character test. [L2–L3]

```proofscript
function calculate(x: Nat): Nat :=
  let y := x + 1; y * 2

function compact(_: Unit): Nat :=
  Id.run(do { let mut x := 1; x := x + 1; return x; })

theorem twoTruths: True ∧ True := by {
  constructor; trivial; trivial
}

theorem twoTruthsAll: True ∧ True := by {
  constructor <;> trivial
}
```

Plain `;` sequences tactics; `<;>` applies the second tactic to each goal produced by the first. They must not be interchanged by desugaring or formatting. These examples illustrate inherited forms; the new evidence tests their canonical Lean counterparts, not a production PSC parser.

### 16.2 Braced decorations retain category structure

Braces remain optional registered surface decorations, not JavaScript statement blocks. `E-STRUCT-BODY` and `E-CLASS-BODY` wrap lifted native field sequences; `E-INDUCTIVE-BODY` wraps native constructor sequences; `E-MATCH-BODY` wraps native alternatives. `E-INSTANCE-BODY` and `E-WHERE-BODY` preserve the native sequence parsers that already admit semicolons in those contexts.

At an owned opening brace, establish a sequence-local position/layout scope. The first member establishes the sequence position according to the native sequence parser; subsequent members and continuation lines retain that parser's indentation and boundary checks. The matching closing brace ends only that owned sequence. Nested records, matches, quotations, tactics and `do` blocks establish their own scopes. Braces MUST NOT disable the native indentation checks inside members or turn each newline into a separator. Section 76 incorporates the exact native sequence combinators.

A single-member body may be compact where the native member grammar permits it. Multiple field declarations should use separate, consistently indented lines. Do not replace removed match/constructor/field terminators with commas or another invented general separator. Native marker and sequence rules decide which compact forms are possible. A same-line sequence accepted by native grammar remains distinct from a newline-based formatting convention.

A match RHS can contain `let y := e; body`, `by { ...; ... }`, or `do { ...; ... }`. Those nested semicolons remain part of the RHS; they never terminate the match alternative. An inner match's `|` must not be stolen as an outer alternative. Native layout, delimiter depth and parser continuation state resolve that nesting.

### 16.3 Boundaries, errors and migration

Keep native continuation rules for multiline applications, expressions, tactic bodies, `termination_by`, `decreasing_by`, `where`, and supported verification suffixes. Do not add JavaScript-style automatic semicolon insertion, a global newline-termination heuristic, or a preprocessing pass that strips semicolons.

A `;` that no valid active native subcategory can consume is rejected with `PS_UNEXPECTED_SEMICOLON` or the corresponding precise native syntax error. The diagnostic may suggest an explicit v0.7/earlier-draft migration, but the compiler MUST NOT retry another grammar silently. Missing layout/boundary structure is `PS_INVALID_LAYOUT` where attributable to the owned sequence, not permission to merge members or infer a missing terminator.

`D-DECL-SEMI` and `PS_MISSING_DECL_SEMICOLON` are retired from this revised default grammar. Historical source keeps its old interpretation through an explicitly selected legacy reader. Migration removes only obsolete punctuation identified by the old AST. This revision does not authorize modifying strings, native sequences, tactic combinators, or old archived evidence.


---

# Part III — Declarations, functions, and data

## 17. Definition declarations and aliases

`def` remains the canonical general definition keyword. `const` and `function` are declaration-head decorations lowering to `def`, not independent semantic kinds.

```proofscript
const answer: Nat := 42
const increment: Nat -> Nat := fun n => n + 1

function add(x: Nat, y: Nat): Nat :=
  x + y

def identity {α: Type}(x: α): α := x
```

Canonical Lean:

```lean
def answer : Nat := 42
def increment : Nat → Nat := fun n => n + 1

def add (x : Nat) (y : Nat) : Nat := x + y

def identity {α : Type} (x : α) : α := x
```

`const` has no declaration binders. It may have a function-valued type or inferred value type. Generic value definitions use `def` or `function` rather than hiding declaration parameters behind `const`.

`function` requires at least one nonempty explicit declaration parameter group. Implicit and instance binders may surround explicit groups in supported native order. A function taking no meaningful input can take `(_: Unit)`; it is then called with `f()`. No Unit binder is silently added to an empty header.

Rejected owned forms include:

```text
const add(x: Nat): Nat := x
function answer: Nat := 42
function answer(): Nat := 42
function square(x: Nat): Nat { x * x }
const answer = 42
```

The first misuses `const`; the next two do not supply an explicit parameter; the fourth is an unregistered statement-body grammar; the last replaces Lean binding syntax. These are syntax/profile errors, not logical theorems about the proposed bodies.

A definition becomes available according to native declaration and recursion rules. Aliases do not introduce JavaScript hoisting, overload sets, prototype methods, hidden receivers, or runtime object freezing.

## 18. Definition kinds, modifiers, and visibility

`theorem`, `example`, `abbrev`, `opaque`, `axiom`, and native definition modifiers retain their selected Lean meaning. Lowering MUST preserve the declaration kind, name, universe parameters, type, body, safety information, reducibility/opacity metadata, and relevant attributes.

An `abbrev` is a transparent abbreviation, not a distinct nominal type. A domain identifier that must not be confused with arbitrary natural numbers should use a structure, not merely `abbrev UserId := Nat`.

An `opaque` declaration is not a freely unfoldable definition. Opacity is semantically relevant to conversion and proof behavior; it must not be erased as a cosmetic attribute. A theorem declaration is not emitted as an ordinary runtime function merely because its proof can be represented by a term.

`private`, `protected`, `noncomputable`, `partial`, `unsafe`, native module modes, and supported public/meta annotations are inherited only with their exact upstream behavior. Source visibility is not a security sandbox. Module export policy and the name of a JavaScript export do not grant or remove logical derivability.

A compiler may implement only selected native modifiers, but it MUST reject unsupported ones instead of dropping them. A release profile should distinguish ordinary declarations, research axioms, runtime assumptions, and unavailable executable definitions.

## 19. Binders, dependencies, and universes

Binders preserve native roles:

```proofscript
(x: A)        -- explicit
{α: Type}     -- implicit
{{α: Type}}   -- strict implicit, where the pinned grammar admits this spelling
[C α]         -- instance implicit
```

Native Unicode variants are accepted according to the pin. The lowerer records binder kind and order; it does not infer that braces mean “generic type parameter” regardless of the enclosed type.

`D-EXPLICIT-PARAMS` comma-groups **complete single-name explicit binders** in registered declaration headers:

```proofscript
function select(n: Nat, i: Fin n): Fin n := i
```

```lean
def select (n : Nat) (i : Fin n) : Fin n := i
```

The type and any native default of a later parameter may depend on earlier parameters. The lowerer expands each group into native explicit binders in the same order. It does not make dependent parameters independent or reorder them for target calling conventions.

A comma group has a type for each entry. Forms such as `(x, y: Nat)` are not shorthand for `(x: Nat, y: Nat)`. Native shared-type binders such as `(x y : Nat)` remain native, without commas. Grouping rules do not automatically apply to lambda binders or pattern binders.

Universe declarations and polymorphism remain native. `Type u` abbreviates the appropriate sort; `Prop` and `Sort u` retain the pinned universe rules. Do not replace universe expressions with machine integer ranks or approximate level equality in a standalone checker. The source grammar does not add TypeScript `<T>` binders.

## 20. Inference, annotations, and elaboration order

Local type inference, implicit arguments, coercions, overloaded literals, and typeclass synthesis follow the chosen Lean elaboration environment. They are not reimplemented as TypeScript assignability.

Public signatures SHOULD expose useful types, effects, and dependencies, but explicit signatures are a style/interface recommendation unless a selected build policy requires them. A template MAY explicitly set `autoImplicit false`; the compiler MUST NOT silently use different options from the reference environment.

An application is elaborated as a whole native application syntax object. The native algorithm matches positional and named arguments to the function type, creates metavariables, uses expected types, handles missing explicit parameters/defaults, and schedules instance synthesis. Elaborating each argument first against an independently inferred type may change the result and is not an equivalent implementation. [L4]

Native instance priorities and declaration/import order may affect search. A standalone frontend must reproduce the accepted choice or report an unsupported case. It cannot replace that behavior with a different tie-breaking rule while retaining the same profile name.

Resource limits bound the implementation's search. A budget-exhausted request is incomplete, not permission to guess a candidate, insert an axiom, or weaken the expected type. The diagnostic should expose the unresolved constraint and selected environment.

## 21. Named, default, automatic, and partially supplied arguments

Defaults use supported native parameter syntax:

```proofscript
function connect(host: String, timeout: Nat := 5000): String × Nat :=
  (host, timeout)
```

The body above is a simple illustrative value, not an implemented network API.

Native call syntax remains valid:

```proofscript
connect "example" (timeout := 1000)
```

The v0.9 named-call decoration provides the corresponding term:

```proofscript
connect("example", timeout := 1000)
```

Defaults are native elaboration metadata associated with parameter types. They are not a runtime overload mechanism. Automatic parameters invoking tactics remain native capabilities and create ordinary proof obligations. The compiler must preserve their environment and not rerun them under a different namespace or option set.

Passing fewer explicit parameters can yield a function according to the native application algorithm. Named arguments can fill a later parameter while leaving an earlier one abstracted. Do not implement missing parameters by inserting JavaScript `undefined`.

A value explicitly representing absence is still an argument. Omission, `Option.none`, and a foreign `undefined` argument are not interchangeable.

## 22. Lambdas, closures, and higher-order functions

Lambdas use `fun`:

```proofscript
fun x => x + 1
fun (x: Nat) => x + 1
fun {α: Type} (x: α) => x
```

Their binder and pattern-lambda forms remain native. A term-level call in the body is recursively lowered, but a comma in the outer call is not allowed to split an inner parenthesized lambda or record.

```proofscript
users.map(fun user => user.name)
```

Function types retain native arrows and dependent Pi structure. The base does not add `(x) => e`, callback parameter destructuring with JavaScript semantics, or function objects carrying arbitrary dynamic properties.

Closures capture the values and lexical relationships specified by native elaboration. The runtime representation may be a JS closure or a code/environment record, but calling conventions and captured data must preserve the source meaning. Returning a function from a function is not a special case that may bypass erasure or omit parameters.

Compiler optimization must respect the distinction between total pure computation, partial computation, and observable effects. A closure capturing a logical value is not automatically a handle to mutable foreign state.

## 23. Operators, equality, and conditions

Operators are selected native notation over declarations. Their precedence, associativity, scoping, and elaboration are those of the registered environment. A convenient operator name does not authorize a new primitive.

Three relationships remain different:

| Relationship | Role |
|---|---|
| Definitional equality | Kernel conversion after the allowed reductions. |
| Propositional equality `x = y` | A type/proposition whose inhabitant is evidence. |
| Boolean comparison `x == y` | Computation through the selected `BEq`-style instance. |

A Boolean comparison returning true does not automatically prove equality. Verified use requires the relevant laws or a suitable decision procedure. Likewise, a programmer-supplied Boolean predicate cannot be treated as a sound refinement test without evidence connecting it to the proposition.

Conditions follow native Lean treatment of propositions with decidability and supported Boolean coercion. There is no numeric, string, or object truthiness. Native evidence-binding conditionals such as `if h : p then ... else ...` retain their branch contexts.

## 24. Braced conditionals

**Feature ID:** `E-IF-BRACE`.

```proofscript
function bounded(n: Nat): Nat :=
  if (n <= 10) { n } else { 10 }
```

Canonical Lean:

```lean
def bounded (n : Nat) : Nat :=
  if n <= 10 then n else 10
```

Each branch is exactly one term. The condition is parenthesized. There is no generic statement list inside these braces. A branch requiring sequencing uses a native `do` term or another explicitly supported term abstraction.

The parser recognizes this exception only after the complete owned discriminator `if ( ... ) {` is established in a term context. Native `if (c) then ... else ...` is still inherited. Once the E form has committed, a missing branch or missing `else` is an error.

An `else if` chain can use a nested native or decorated conditional as the single else term; the canonical presentation encloses the else term explicitly. No special C/JS dangling-else rule is introduced.

The lowerer preserves each condition/branch once in syntax and does not evaluate both branches or duplicate effectful subterms. The relationship of logical reduction to target execution is still a separate compiler obligation.

## 25. Structures and record values

**Feature ID:** `E-STRUCT-BODY`.

```proofscript
structure UserId where {
  value: Nat
}

structure User where {
  id: UserId
  name: String
  active: Bool
}
```

Canonical Lean uses the same declarations and fields with native layout. Fields are parsed as native field declarations, lifted only at registered term/header child slots. Field order, binder kinds, defaults, documentation, and attributes remain significant. The body uses lifted native `structFields` layout, not semicolon-separated field declarations.

The braces are not an object literal or a namespace. They delimit the declaration's field sequence. Empty or unusual structure forms are accepted only when their lowered native structure is supported and well-formed; braces do not invent constructor validity.

Record values and updates retain native syntax:

```proofscript
const example: User := {
  id := { value := 7 },
  name := "Ada",
  active := false
}

function activate(user: User): User :=
  { user with active := true }
```

Default fields, inherited fields, field-name resolution, source records in updates, and type ascription follow native elaboration. A backend cannot reinterpret construction as copying JS property descriptors or prototypes.

Native structure inheritance through `extends` remains available when supported. It is Lean parent-structure composition, not JavaScript prototype inheritance. A blanket ban on the word `extends` would wrongly remove an inherited semantic mechanism.

## 26. Dependent fields and updates

A structure may contain a field whose type depends on another field:

```proofscript
structure SizedData where {
  n: Nat
  data: Fin n -> Nat
}

function replaceData(n: Nat, f: Fin n -> Nat): SizedData :=
  { n := n, data := f }
```

Changing `n` can change the required type of `data`. The compiler must reconstruct a well-typed record under the native rules. It may use valid transport/equality evidence when available; it may not retain a mismatched field using a cast, resize it silently, or erase the dependency merely because it is inconvenient to emit.

A candidate update `{ s with n := s.n + 1 }` with arbitrary old `data` was rejected by the pinned Lean oracle in this research. That observation is a concrete negative example, not a proof of all dependent-update behavior.

Runtime erasure may remove type/proof fields only after relevance analysis. The data indexed by a size can still be runtime-relevant even when the size's type-level use disappears.

## 27. Inductives, constructors, and pattern matching

**Feature IDs:** `E-INDUCTIVE-BODY`, `E-MATCH-BODY`.

```proofscript
inductive LoadState(ε: Type, α: Type) where {
  | idle
  | loading(requestId: Nat)
  | ready(requestId: Nat, value: α)
  | failed(requestId: Nat, error: ε)
}
```

Constructors lower to native constructor declarations in the same order, with the same parameters, indices, universe expressions, result types, and metadata. Braces are presentation; they do not relax positivity, constructor result requirements, or elimination restrictions.

```proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some n => n
  }
```

The discriminants and RHS terms are ProofScript-aware term slots. Patterns remain native. Their variables, inaccessible patterns, literal interpretation, constructor resolution, and dependent refinement follow Lean.

Rejected as a pattern:

```text
| .some(n) => n
```

This does not prohibit `.some(n)` in a **term** context. Constructor declaration parameters, constructor applications, and constructor patterns are distinct categories.

A braced match has at least one alternative. Its lifted native alternative sequence uses `|`, `=>`, and native layout; there is no added `;` after an alternative. Preserve native multiple-discriminant and alternative-pattern groups. An RHS containing a local `let`, tactic sequence, or `do` retains the separators of that nested category. The grammar must not split alternatives by scanning for semicolons or every `|`.

```proofscript
function both(x: Option Nat, y: Option Nat): Nat :=
  match x, y with {
    | .some a, .some b => a + b
    | _, _ => 0
  }
```

Exhaustiveness and motives are elaborator obligations. A wildcard is not permission to ignore an unsupported indexed elimination. “Pattern lowering succeeded” does not establish that its recursor is valid until the declarations are admitted.

## 28. Indexed, mutual, nested, and coinductive definitions

The theorem profile can use the corresponding native capabilities. A standalone implementation must report exact coverage for mutual inductives, nested inductives, indexed families, generated recursors, and the native coinductive/fixpoint facilities of the selected environment.

The overlay does not create new positivity or termination rules. Parameters and indices must not be conflated. Constructor tables supplied by a frontend are not trusted merely because they are syntactically decodable.

Native mutual blocks retain `mutual ... end` command structure. Braced command scopes are not added. The version-specific `monotonicity_by` suffix remains inherited in the native contexts that support it; a declaration suffix is not a general proof-automation keyword usable anywhere.

Logical admission and executable support remain separate. A backend may reject an executable use of a valid theorem-level construction it cannot represent, while retaining the proof-only declaration.

## 29. Classes, instances, and methods

**Feature IDs:** `E-CLASS-BODY`, `E-INSTANCE-BODY`.

Classes are Lean typeclasses:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
```

The v0.7 prose includes braced instances without a separate registry entry. v0.9 makes that family explicit rather than hiding it in implementation behavior:

```proofscript
instance : Sized String where {
  size(s: String): Nat := s.length
}
```

`E-INSTANCE-BODY` parses the native instance header, then `where { fieldEntries }`. Entries use the lifted native `whereStructInst` field sequence and registered header/term decoration. Semicolons are permitted only as the native sequence already permits them; they are not mandatory per-field or outer-declaration terminators. Canonical examples prefer native layout. Lower to the same native `where` field AST, preserving field binders, result ascriptions, and bodies. Do not confuse this initializer sequence with `structFields`, which declares a structure/class and does not add semicolon separators.

Named instances, priorities, scoped/local modifiers, and deriving must be preserved when advertised. An unsupported modifier is an error. A generated instance is checked like any other declaration.

Generalized field notation is native type-directed resolution. The receiver is inserted at the native matching explicit parameter, which is not necessarily the first parameter. For instance, a collection API may have an earlier function parameter and later collection receiver. Lowering `xs.map(f)` by blindly constructing `map xs f` is incorrect. Construct native field/application syntax and let the compatible elaborator resolve it. [L4]

There is no automatic OO class hierarchy, method overriding, prototype mutation, `new`, or dynamic `this` in this class model. A foreign JS receiver is modeled separately at the interop boundary.

## 30. Collections, absence, and error values

`List`, `Array`, `ByteArray`, `Option`, `Prod`, `Sum`, `Subtype`, `Fin`, and other selected native declarations retain their own definitions. Their names must not become aliases for whichever target container is convenient.

`Option α` is the default portable absence vocabulary. A live JS object can distinguish missing property, explicit undefined, null, and present value; an interop codec may deliberately collapse those states but cannot call that a lossless conversion.

Native `Except ε α` is error-first. The v0.7 example defines a user `Result(α, ε)` as success-first. Both are ordinary types with different parameter conventions. This reference does not silently rename or reorder either. A standard application library SHOULD choose one documented convention consistently; adopting native `Except` avoids inventing an additional fundamental error hierarchy.

A list is not an array. An ordered map is not an unordered hash map. Equality and hashing require laws when used in proofs. Collection iteration order is a library contract, not JS object order or a Rust container's current iteration behavior.

Array indexing, optional access, proof-indexed access, and panic/defaulting access are different native APIs. A compiler MUST NOT substitute an unsafe/defaulting operation for proof-indexed access to make generated code run.

## 31. Local definitions, `where`, and recursion syntax

Ordinary `let`, `let rec`, and native `where` remain available. A local definition captures exactly its native lexical environment. Promoting it to a top-level helper requires correct capture and name handling, not text movement.

`E-WHERE-BODY` offers a braced local-declaration sequence in a declaration suffix:

```proofscript
function incrementTwice(x: Nat): Nat :=
  helper(helper(x))
where {
  helper(y: Nat): Nat := y + 1
}
```

Canonical Lean:

```lean
def incrementTwice (x : Nat) : Nat :=
  helper (helper x)
where
  helper (y : Nat) : Nat := y + 1
```

Entries are native local declaration shapes, not arbitrary top-level commands. Do not add `namespace`, imports, axioms, or environment-changing commands to this body through generic command parsing. Nested local declarations and termination suffixes follow the selected native grammar when supported.

For a decorated simple definition, native termination suffixes precede its native/registered `where` suffix in the underlying declaration AST. No added command terminator follows that suffix. The local declaration sequence preserves native `sepByIndent` semicolons where supported, including a trailing separator belonging to that sequence. Native equation-style definitions retain their own native boundaries, with no invented C-style body syntax.

The current example's canonical form is illustrative unless listed in the executed oracle corpus. The presence of local recursion in the public reference does not claim that every existing compiler backend implements closure conversion for it.

## 32. Pattern/equation functions and declaration suffixes

Native equation-style functions are supported through the pinned `declValEqns` and `matchAltsWhereDecls` categories. Their ordering, pattern discrimination, termination analysis, and scope are not redefined by the overlay.

Where an implementation advertises header decoration on an equation declaration, it must lower the header first while preserving the native equation body and suffix structure. It must not interpret an equation alternative as an ordinary do statement or silently terminate the declaration at an inner tactic semicolon.

The default teaching form for decorated application code is `:= expression` with native declaration boundaries; native equation forms are useful for recursive algorithms and theorem code. A canonical formatter can preserve both by category rather than forcing every native form into an unproved rewrite.

Unsupported mixtures of decorators and suffix categories must produce a capability diagnostic naming the combination. A claimed whole-profile implementation eventually needs interaction coverage, not only successful isolated features.

---

# Part IV — Computation, effects, and modules

## 33. Scalars, literals, and primitive identity

The selected native types include `Nat`, `Int`, supported `UInt*`/`Int*` families, target-word types, floating types, `Bool`, `Char`, `String`, and `Unit`. A name is supported only with its actual declaration and primitive/runtime mapping. The reference does not invent a native declaration because a similarly named type appears in a target language.

Literal overloading, `OfNat`, negative syntax, decimal/scientific literals, characters, string escapes, and string interpolation follow the pinned grammar and elaborator. A bare numeral is not universally a JavaScript `number`. Context and instances determine its type.

Primitive recognition must validate the expected declaration identity, type, and role. An arbitrary user declaration named `Nat.add` cannot obtain a trusted reduction rule. A manifest containing a primitive name or hash does not replace checking its required semantics.

### 33.1 Exact naturals

For the ordinary native natural-number operations, the required values include:

| Operation | Meaning |
|---|---|
| `a + b`, `a * b` | Exact arithmetic over nonnegative integers. |
| `a - b` | Truncated subtraction: zero when `b > a`. |
| `a / b`, `b > 0` | Natural quotient. |
| `a % b`, `b > 0` | Natural remainder. |
| `a / 0` | Zero under the pinned ordinary Nat division operation. |
| `a % 0` | `a` under the pinned ordinary Nat remainder operation. |
| Comparisons | Native numerical relationships; Bool/Prop result depends on the chosen operation. |

The oracle corpus checked examples of underflow and zero division/remainder. Backend conformance requires the entire operation contract, not just those instances.

### 33.2 Exact integers

Ordinary pinned `Int` `/` and `%` use their selected native Euclidean operations. Distinct APIs such as truncating division must retain their distinct names and rules. For example, the oracle checked `(-5 : Int) / 2 = -3` and `(-5 : Int) % 2 = 1`. A JS BigInt expression using truncation toward zero is not automatically equivalent.

Zero-divisor, negative-divisor, conversion, and machine-boundary behavior are inherited per exact declaration. A backend's primitive matrix MUST name these operations explicitly rather than specify “use host integer division.”

### 33.3 Fixed-width and target-word values

Width, wrapping/checking behavior, shifts, narrowing, sign conversion, division, and conversion to/from exact integers are defined by the selected native operations. A Rust debug flag or Wasm opcode does not establish their meaning.

Target-word values include the target width in executable-profile identity. Code whose results depend on width is not promised bit-identical across 32-bit and 64-bit targets. A backend must not silently pick one width while advertising another.

### 33.4 Floating point

A floating contract concerns the selected floating model or a proved relation to a mathematical model. It is not automatically real-number arithmetic. Record rounding, NaN/infinity, signed zero, bit conversion, permitted nondeterminism, and runtime-library dependencies for every advertised operation.

If the native reference leaves behavior dependent on a platform primitive, that dependency must remain visible. A backend must either match the stated profile or reject the requested stronger deterministic claim. Fast-math, reassociation, and relaxed transformations are not silently allowed under a faithful profile.

### 33.5 Primitive-matrix completeness

The language's primitive meaning is fixed by the pin; executable support is declared in a matrix with one entry per reachable primitive and transitive runtime dependency. The matrix contains declaration identity, input/output representation, exceptional/resource outcomes, target implementation, and evidence. Missing entries reject execution for that target. This avoids replacing an incomplete implementation with an unspecified semantic default.

## 34. Strings, characters, bytes, and identity

Native `Char`, `String`, string positions/slices, and `ByteArray` operations retain their exact selected definitions. A backend may use UTF-8 buffers, JS strings, or another representation only with a relation preserving the operations it exposes.

JS string indexing and length operate on a different representation from many native text operations. A lossless foreign JS string may contain lone surrogates that cannot simply be treated as an ordinary Unicode-scalar string. Foreign interoperation must preserve such states in an explicit boundary type or reject/normalize them under a documented policy.

Do not use native memory layout as a network format. Specify encoding, endianness, bounds, and versioning for byte codecs. A conversion that rejects malformed text is different from one replacing invalid sequences.

Pure data identity is not target pointer identity. Copying, sharing, boxing, or garbage-collecting a logical value may be implementation choices when the observable semantics is preserved. Conversely, a foreign DOM node or resource handle has explicit identity/lifetime behavior and must not be smuggled into a pure record model.

## 35. Pure computation and evaluation

A type-theoretic reduction relation is not the entire executable semantics. Define separately the logical interpretation, admissible compiled implementation, and observable runtime behavior.

Native logical conversion may unfold and reduce according to the kernel's rules. Compiled code may use optimized representations and separate runtime implementations. Classical axioms and quotient-related constructions can obstruct kernel normalization without preventing suitable proof-erased execution. Choice used to construct data can require noncomputability. Do not assert that every closed kernel-accepted natural-number term necessarily reduces to a numeral under every admitted assumption policy. [B3]

In the executable profile, observable ordering is preserved according to the native computation and its specified primitive models. Effectful order is expressed through bind/do or another explicit computation abstraction, not guessed from pretty-printing.

Purity alone does not justify every code motion when partiality or failures are observable. Under a strict evaluation model, deleting an unused divergent argument may turn divergence into termination. Optimizations must state the hypotheses under which duplication, reordering, or erasure preserves behavior.

## 36. Native `do`, local mutation, and control flow

The pinned `Lean/Parser/Do.lean` explicitly supports a nonempty braced do sequence. Thus `do { ... }` is inherited, not a new JavaScript statement block. This was both source-inspected and exercised with the pinned Lean toolchain. [L2]

```proofscript
function sum(xs: List Nat): Nat :=
  Id.run(do {
    let mut total := 0;
    for x in xs do {
      total := total + x;
    };
    return total;
  })
```

The illustration uses native do syntax with ProofScript-aware term child slots. Its intended canonical counterpart is a native `Id.run do` program. An empty `do {}` is not introduced; use an appropriate explicit `pure ()` or other native action.

Native `let`, monadic binding with `←`/`<-`, `let mut`, assignment with `:=`, `for ... do`, `while`, `break`, `continue`, `return`, and error/recovery syntax retain their elaboration and scope. `=` is not reassignment. A loop does not acquire JavaScript iterator semantics because its body uses braces.

The do-element parser owns its separators and nested term slots. It must not strip every semicolon and hope a native parser will reconstruct the original sequencing. Likewise, an E-IF single-term branch is not itself a do sequence.

Mutable locals are elaborated under native restrictions. Capturing mutable-looking state in a closure must follow the pinned elaboration; the backend cannot independently choose between snapshot capture and a shared mutable cell.

Early return is meaningful only in the native contexts supporting it. It does not jump out of arbitrary nested pure expressions or callbacks as if they were JS statement functions.

## 37. Structural, well-founded, partial, and unsafe computation

Structural and well-founded recursive definitions use native termination analysis and proof mechanisms. A failed termination search establishes neither divergence nor an excuse to mark the definition total. Explicit `termination_by` and `decreasing_by` forms keep their native scopes and syntax.

`partial def` retains its native logical interpretation. The logical constant can appear in statements, but the executable body's equations are not automatically available as definitional equalities. A theorem about that opaque logical object is not automatically a theorem about every behavior of its compiled runtime body.

Native `partial_fixpoint`, inductive/coinductive fixpoints, and associated reasoning principles are individually gated inherited capabilities. Their monotonicity/order obligations cannot be replaced with “the test terminated.”

`unsafe`, external implementations, and runtime replacement mechanisms require explicit execution-trust accounting. A safe logical signature around an unsafe implementation may preserve logical consistency while the executable behavior diverges from the proved model. Certified execution must audit/reject or justify those replacements; type checking alone does not close the gap. [L5]

Long-running services and event loops are legitimate applications. Their useful properties may be trace safety, partial correctness, resource invariants, or conditional liveness—not total termination of the server. These claims require a corresponding model and must not be fabricated by unfolding opaque partial constants.

## 38. Effects, state, and errors

Lean effect types and native abstractions remain the base model. ProofScript does not replace `IO`, `StateT`, `ExceptT`, `ReaderT`, or native typeclasses with a different effect system by changing syntax.

Transformer order matters:

```text
StateT S (Except E) A     ~ S -> Except E (A × S)
ExceptT E (StateM S) A    ~ S -> (Except E A × S)
```

The first shape does not return a successful state pair on failure; the second returns final state alongside either outcome. A library alias must disclose its concrete semantics. Recovering from an error can produce different states under these arrangements. Discarding logical state does not undo a file write or network request. [B2]

Recoverable domain failures should use explicit typed values/effects. Host exceptions and rejected promises are translated only by a specified adapter. An arbitrary thrown JS value is not automatically a member of the application's declared error type.

A proposed application library may provide convenient ordinary definitions for state, capability descriptions, tasks, or resource handling. Such libraries require their own semantics and evidence. The base grammar does not silently introduce an `App` effect, a universal `try` propagation operator, or algebraic effects.

## 39. IO, tasks, resources, and application libraries

Native Lean `IO` and `Task` retain their pinned logical/runtime distinction. A JS Promise is not a native Lean Task merely because both eventually produce a value.

A portable library may use separately named types, such as `Psc.Async`, to describe different start, cancellation, and cleanup policies. Such names in this reference are **architectural examples, not installed or standardized APIs**. No `async function`, `await`, `using`, or `component` keyword is admitted by the base overlay.

Before a task/resource library is promoted, its contract must state:

| Question | Required answer |
|---|---|
| Start | Is constructing a task pure/cold, or does it schedule work? |
| Reuse | Does reuse start new work or await one shared handle? |
| Failure | Which typed and unexpected foreign failures can occur? |
| Cancellation | Is it a request, a terminal state, or both at different stages? |
| Children | Which scope owns them, and what does scope completion require? |
| Cleanup | What happens on success, failure, cancellation, and cleanup failure? |
| Timeout | Which clock/deadline is used, and what happens to late effects? |
| Resources | What is copied, shared, released, or explicitly detached? |

These are library/runtime requirements, not new kernel rules. A target lacking the required behavior must reject the capability or report a separately named weaker contract. A cancellation result does not prove a remote side effect was reversed.

Pure `.ps` or `.lean` library calls must remain an alternative to any future convenience syntax. Full-app readiness is measured by real supported workflows, not by the number of new keywords.

## 40. Imports, namespaces, sections, and modules

Imports use native logical module syntax:

```proofscript
import Init
import MyApp.Domain

namespace MyApp

function square(x: Nat): Nat := x * x

end MyApp
```

Namespaces, sections, variables, `open`, local/scoped declarations, native exports, attributes, options, and supported module visibility modes retain their exact upstream meaning. `namespace N { ... }`, `section { ... }`, and `import { x } from "pkg"` are not base replacements.

Module resolution maps logical names to one selected source snapshot and pinned package versions. Mapping into npm package exports is a build/interop concern; it does not turn native imports into Node runtime resolution accidentally.

Commands are processed in their declared environment order. A notation, macro, instance, or option registration can affect later parsing/elaboration. Do not parse all commands under the final environment or reorder them by file name. Speculative parsing/elaboration must roll back state on failure.

Module initialization and native module modes are supported only with exact declared semantics. A platform template SHOULD use explicit application entry points rather than inventing hidden top-level side effects. Build-time registration effects and runtime application effects are separately recorded.

## 41. Notation, macros, deriving, and metaprogramming

Native notation and macro facilities are powerful inherited capabilities, not permission for arbitrary unrecorded syntax. A reference environment records its parser/notation/macro/elaborator registrations. A standalone environment may support a bounded selection.

A third-party production colliding with an owned D/E region must have an explicit compatibility rule or be rejected. Imported syntax cannot silently override a ProofScript discriminator. The same rule applies to newly reserved command heads.

Macro expansion preserves hygiene, source references, and pre-resolved identities. Capturing an unrelated local variable is a source-correspondence defect even if the resulting term happens to type-check. The source and Core ASTs must remain distinct; a macro is not a global string substitution. [L7, P2]

Deriving and registries produce ordinary declarations and proof candidates. Registered `simp` or `spec` metadata is an index, not proof authority. Unknown attributes are rejected unless defined in the selected environment.

Native quotations/antiquotations preserve their category. Term decoration does not recursively rewrite arbitrary quoted text. Syntax-building Meta code and tactic implementations may be substantially larger than the kernel while remaining non-authoritative logically. Their operating-system permissions are a separate security issue.

---

# Part V — Logic, theorem proving, and verification

## 42. The logical foundation

ProofScript reuses the pinned dependent type theory rather than defining a weaker approximate calculus. The relevant foundation includes sorts/universes, dependent functions, binding/substitution, conversion, propositions, proof irrelevance, inductive families/recursors, and the selected quotient facilities.

A standalone checker must validate the actual inputs under its declared rules and policy: closedness, bound variables, universe parameters, types, bodies, positivity, recursor information, primitive identities, and environment consistency. Successful decoding is not successful admission.

An implementation may progress through smaller subsets, but its accepted results must be sound for the advertised subset. It cannot approximate level equivalence, replace dependent elimination with nondependent matching, or accept caller-supplied recursor tables merely because those shortcuts cover current examples.

Independent checkers are useful differential references, not interchangeable definitions. The repository's `lean4lean-master/divergences.md` documents intentional differences from upstream, including universe comparison and checking details. Reusing its algorithms does not automatically establish exact pinned acceptance equivalence. [R4]

## 43. Propositions, types, and evidence

A proposition is a type in `Prop`; a proof is an inhabitant admitted under the selected theory and assumptions. Data and propositions are related but not interchangeable.

```proofscript
theorem identityProof {P: Prop}(h: P): P := by {
  exact h
}
```

The proposition's meaning comes from the admitted declarations, not the theorem name or source comment. A function with Boolean output can be useful in a decision procedure, but its `true` output becomes logical evidence only through a justified bridge.

Dependent types can express invariants directly, for example `Fin n`, indexed vectors, or a subtype whose constructor carries a proof. Runtime use must preserve the data witness while erasing only justified irrelevant evidence.

Holes and unfinished proofs may exist in the editor. They must never be serialized as successful release proof evidence. Ordinary user axioms remain visible assumptions, not hidden implementations of unfinished proof search.

## 44. Theorems and structured proof forms

The theorem profile supports native proof terms and the selected tactic environment. Familiar structured forms include `have`, `show`, `suffices`, `calc`, explicit lambdas, and constructors.

```proofscript
function twice {α: Type}(f: α -> α, x: α): α :=
  f(f(x))

theorem twiceIdentity {α: Type}(x: α): twice((fun y => y), x) = x := by {
  rfl
}
```

The intended native theorem was included in the oracle examples in an equivalent native presentation. That does not certify the decorated header/call parser.

The tactic category keeps its own combinators and delimiters. Term arguments accepted by tactics may use the declared term overlay only in registered slots. Do not treat every `;` in a proof as a discarded declaration terminator: it may control tactic execution.

The standard prover should supply the relevant native capabilities for rewriting, simplification, cases, induction, and goal management. The base grammar does not freeze every tactic implementation or claim source compatibility with all third-party tactics.

## 45. Rewriting, simplification, automation, and reflection

`rw`, `simp`, induction, arithmetic procedures, search, and AI-generated proofs construct evidence. They do not authorize declarations independently of the kernel.

A simplifier must justify the rewrites and congruence steps used in its final proof. Fast untrusted search may choose candidate lemmas, but the resulting term or reconstructed certificate must be checked. A solver's bare `sat`/`unsat`/`valid` response is not proof authority in a strict profile.

Reflection is allowed when an ordinary theorem establishes a checker's soundness and the actual checker result is justified through accepted logical mechanisms. Compiling that checker to native code and trusting a returned Boolean without the required bridge introduces a separate trust assumption; naming the function “verified” does not remove it.

The pinned reference removed historical kernel native-reduction hooks. This profile MUST NOT revive `Lean.reduceBool`, `Lean.reduceNat`, or `Lean.trustCompiler` as silent kernel computation rules. Native/meta proof tactics, if admitted by a larger profile, report their actual assumptions. [R1]

Proof scripts and proof terms have different stability. Pin tactic/notation environments, retain replayable evidence where useful, and report script repair separately from statement or axiom changes.

## 46. Axioms, classical mathematics, quotients, and noncomputability

Axiom policy is independent of syntax version and checker package version. It specifies exact permitted declarations and tracks transitive dependencies. Names alone are insufficient.

Classical mathematics and noncomputable definitions are legitimate theorem-development activities. The standard mathematical profile may allow reviewed foundational assumptions, while a constructive profile may restrict them. Neither policy silently changes conversion rules.

Proof-irrelevant classical reasoning does not necessarily make an otherwise executable function noncomputable. Conversely, choice used to manufacture runtime data cannot be erased as though it were only a proof. Quotient computations and elimination restrictions must retain the selected native meaning. [B3]

Strict proof acceptance excludes unresolved `sorry`/`sorryAx`, fabricated native-result axioms, and arbitrary unapproved assumptions. A research build may display them, but must report the weaker claim accurately.

An external implementation specification is not automatically a logical axiom. Prefer explicit model parameters/hypotheses and separately reported implementation relationships. This keeps “the theorem follows from the model” distinct from “the external service implements the model.”

## 47. Specifications as ordinary theorems

The baseline specification mechanism is an ordinary theorem about an ordinary definition:

```proofscript
function debit(balance: Nat, amount: Nat): Except String Nat :=
  if (amount <= balance) {
    .ok(balance - amount)
  } else {
    .error("insufficient balance")
  }

theorem debitSuccess(balance: Nat, amount: Nat)(h: amount <= balance):
    debit(balance, amount) = .ok(balance - amount) := by {
  simp [debit, h]
}
```

This example states a successful-input property. It does not establish authorization, concurrency, financial units, or correct persistence. A complete application contract should also state relevant error and state-preservation behavior.

The final admitted theorem must identify the **actual implementation**, approved specification, and their fixed dependencies. Proving unrelated obligations generated by a buggy VC generator is insufficient.

For a total pure function the target relationship is conceptually:

```text
∀ x, Pre x → Post x (implementation x)
```

For stateful, partial, or asynchronous computations, use the corresponding program logic and outcome relation. The existence of a total function constructing an IO value does not establish total termination of the external computation represented by that value.

## 48. Native intrinsic contracts

The pinned intrinsic-verification mechanism is an **experimental inherited capability**, enabled under its exact imports/options. It is not rebranded as a newly stable proof primitive.

The inspected and executed native form uses:

```lean
import Std.Internal.Do
set_option experimental.intrinsic true

def unchanged (n : Nat) : Id Nat
    ensures result => result = n :=
  pure n
```

The oracle generated `unchanged.spec` and warned that `vcgen` remains experimental. The reference must preserve that warning/status rather than describe the feature as production-proved.

The pinned grammar accepts one optional `requires` followed by one optional `ensures`. Compound requirements use conjunction or ordinary predicates; repeated clause keywords are not silently concatenated. The postcondition may use supported native lambda/match forms. [L3]

If a decorated `def`/`function` header is combined with this capability, lower to the same native definition and contract clauses before native elaboration, preserving binders, native clause structure, and the declaration's native body/suffix boundary. No outer semicolon is introduced. The compiler must advertise and test this composition explicitly.

The native generated specification theorem remains separate from the function's ordinary executable type. A type-checked caller has not necessarily established the precondition. Verified callers discharge what their correctness argument needs; a proof-bearing API can require evidence explicitly through dependent binders.

## 49. Assertions, invariants, termination clauses, and ghost state

Native verification `assert` creates proof obligations under the selected intrinsic/program-logic environment. `assert!` is a runtime operation with its native panic behavior. The same English word does not give them the same assurance.

Loop invariants need initialization, preservation, exit, and supported control-flow obligations. The inspected native invariant facility is not universally available on every iterator: supported collection and effect interfaces, including relevant `PureForIn` requirements, are part of its capability contract. Multiple collections or unsupported containers must not silently bypass these restrictions. [L3]

Termination syntax remains native `termination_by`/`decreasing_by` or the selected fixpoint mechanism. This base does not invent a universal `decreasing` keyword on arbitrary loops. A future surface convenience must name its exact lowering and obligations.

Residual verification conditions use the pinned native proof-section grammar, including the supported `where finally | spec => ...` form. A braced `E-WHERE-BODY` is not automatically a replacement grammar for that proof section.

Native `erased` bindings and proof-only values must preserve their native scope and relevance semantics. Runtime data cannot depend on a removed witness. A failed relevance proof rejects the claimed erasure; it does not emit a default value.

## 50. Specification quality and assumption control

A sound proof of a weak specification can certify an unwanted program. A sorted-output contract alone can permit an always-empty implementation. A success-only postcondition may permit always failing. An impossible precondition can make a correctness implication vacuous.

Tooling SHOULD expose these possibilities using examples, witnesses, model checks where justified, and deliberately broken implementations. Such checks are evidence about specification quality, not proof that the specification captures every human requirement.

An approved specification includes semantic dependencies: predicate definitions, relevant types, imported declarations, axiom policy, and environment. Protecting only the text of `ensures P` is insufficient if an agent can redefine `P` to mean `True`.

A requirement change remains possible, but must be reviewed as a different operation from an implementation repair. An AI agent must not obtain a successful build by changing the verifier, release policy, specification dependency, or allowed assumptions without explicit authorization.

A counterexample is confirmed only when the reported model/input corresponds to the selected program semantics. A timeout, unknown solver result, or unsupported theory is not a counterexample.

---

# Part VI — Compiler and preservation contracts

## 51. Required pipeline and phase invariants

A conforming implementation separates the following roles even if some are fused for performance:

```text
Exact source + edition + environment
                  |
        Lexing and category-aware parsing
                  |
       Owned surface AST + source provenance
                  |
          Canonical syntax lowering
                  |
       Native-compatible elaboration / Meta
                  |
       Candidate canonical declarations
                  |
           Genuine kernel admission
                  |
               CheckedModule
                  |
        Relevance / erasure / runtime lowering
                  |
                 RuntimeIR
       +-----------+-------------+-----------+
       |           |             |           |
     TS AST      JS AST        Rust AST    Wasm IR
       |           |             |           |
      .ts         .js            .rs        .wasm
```

The parser does not decide theorem truth. The elaborator does not authorize its own declarations. A canonical codec does not replace kernel admission. A kernel proof does not establish erasure correctness. A target type checker does not establish ProofScript source correctness.

Each phase output must carry enough identity for diagnostics, reproducible checking, and evidence binding. Phase invariants are substantive: e.g. no unresolved metavariables at admission; no erased runtime dependencies in executable IR; no unknown target primitives at emission.

An API named `check` must describe what it actually checks. An admission-ready candidate must not be renamed `CheckedCore` or given a “kernel-admitted” generated-file banner until real admission occurs.

## 52. Surface AST and feature registry

Owned syntax nodes carry a feature ID, category, source span, child nodes, and the exact grammar-profile identity. Preserve native syntax information needed for elaboration, including identifier scopes and pre-resolved references.

A conceptual schema is:

```typescript
type SourceSpan = Readonly<{
  fileId: string;
  byteStart: number;
  byteEnd: number;
}>;

type OwnedNode = Readonly<{
  featureId: string;
  category: "term" | "command" | "header" | "field" | "localDecl";
  span: SourceSpan;
  children: readonly SurfaceNode[];
}>;

type SurfaceNode =
  | Readonly<{ kind: "owned"; value: OwnedNode }>
  | Readonly<{ kind: "native"; syntaxId: string; span: SourceSpan }>;
```

This is a transport/API illustration, not the full internal AST and not a security mechanism. A native node's `syntaxId` must refer to an actually parsed native tree with the required data; it must not hide arbitrary unchecked text.

The registry entry for every D/E feature includes category, discriminator, committed-error behavior, child-slot lifting, lowering relation, native target category, compatibility cost, introduced-version identity, dependencies, and positive/negative cases. New features cannot be enabled merely because their parser function happens to be linked.

The v0.9 additions are explicit: named arguments inside D-CALL, trailing commas in nonempty decorated lists, and the formerly implicit braced-instance family. Everything else in the owned base preserves or clarifies the v0.7 contract.

## 53. Parsing API and error recovery

A parser-ownership operation distinguishes:

```typescript
type Ownership<T> =
  | Readonly<{ kind: "owned"; node: T }>
  | Readonly<{ kind: "defer" }>
  | Readonly<{ kind: "committedError"; diagnostic: Diagnostic }>;
```

Once an owned discriminator commits, its grammar failure is not deferral. This distinction prevents malformed source from being reinterpreted through an unrelated permissive production.

Editor recovery may produce incomplete syntax nodes so that later declarations can still be displayed. Such nodes are provisional; they cannot enter an accepted module. A recovery parser and a release parser must agree on fully accepted source, and recovery must not change a valid earlier declaration to make a later error disappear.

Use explicit delimiter stacks and category stop conditions. Do not infer declaration ends from a raw brace counter that ignores strings, quotations, records, and nested tactics. A deterministic parser can still require environment state because imported notation and declarations affect native parsing.

An implementation must test committed-error behavior, not just successful lowering. Inputs with unmatched delimiters, duplicate named arguments, dangling commas, incomplete contracts, and unsupported patterns should identify the owned category and original source span.

## 54. Canonical lowering rules

The lowerer constructs native syntax trees with known categories. Producing text is a separate serialization step.

Let `L` be syntax-directed lowering and `Args` be one native application argument sequence:

```text
L(Call(h, [a1, ..., an])) = NativeApp(L(h), [LArg(a1), ..., LArg(an)])
L(Call(h, []))           = NativeApp(L(h), [NativeUnit])
LArg(Positional(e))      = NativePositional(L(e))
LArg(Named(n, e))        = NativeNamed(n, L(e))

L(Const(n, T?, e))       = NativeDef(n, [], L(T?)?, L(e))
L(Function(n, bs, T?, e))= NativeDef(n, flattenBinders(bs), L(T?)?, L(e))
L(IfBrace(c, t, e))      = NativeIf(L(c), L(t), L(e))
L(MatchBrace(ds, as))    = NativeMatch(map LDiscr ds, map LAlt as)
LAlt(patterns, rhs)     = NativeAlt(preserveNativePatterns(patterns), L(rhs))
```

Decorated call/list punctuation lowers to native syntax structure; it does not add core operations. Native sequence separators are interpreted in their own category, not discarded by a global punctuation pass. Names, binder kinds, order, modifiers, attributes, result annotations, and native options do survive where they affect meaning.

Class, structure, inductive, instance, and local `where` bodies lower to their corresponding native sequence categories. It is incorrect to collapse every braced form to a record or to convert every declaration to `def`.

Lowering should preserve each user subtree once unless the rule explicitly introduces a semantically justified transformation. Expected type propagation and elaboration happen after syntax construction. A textual unfolding of applications can lose expected-type information or alter insertion of defaults; use the native syntax relationship.

## 55. Binding, provenance, and source maps

Every user-originated node retains its original source association. Synthesized punctuation may have synthetic positions, but it must point through a provenance map to the owning source construct. Preserve nested expansion chains for imported macros and generated schema code.

The source map must distinguish:

```text
original source span
owned feature span
canonical syntax span
elaborated declaration/symbol
erased/runtime source association
final target position
```

Not every target instruction has a one-to-one source character. The mapping should represent generated/combined spans honestly rather than fabricate precision.

Renaming and formatting must operate on binding-aware structures. A fresh local name inserted by the lowerer cannot capture a free source name. Imported declaration names must resolve under the same environment as the intended canonical source, not the lowerer's current convenience namespace.

A formatter should preserve parser ownership. It may reformat an AST into a canonical equivalent spelling when the corresponding structural transformation is defined; it must not treat trivia changes as universally harmless around D-CALL.

## 56. Elaboration and declaration admission

Reference elaboration uses the exact selected Lean environment. Standalone elaboration owes the same claimed result relation for supported source, including typeclass/coercion selection and generated auxiliaries.

A successful declaration bundle has resolved names and metavariables, scoped universe parameters, correct dependencies, and explicit declaration kinds. A module checker reconstructs or imports only genuinely checked dependency state. Caller-provided environments must not smuggle unchecked declarations into erasure.

Admission should be transactional: a failed declaration/module does not leave partially installed constants or cache facts visible to subsequent accepted checks. Caches must be keyed by relevant environment, context, transparency, universe, and policy identities. A type inferred under one context is not globally reusable by expression hash alone.

A checked artifact should be an instance-owned immutable handle or equivalent validated state, not merely a caller-constructible TS object with a Boolean field. Serialized artifacts are rechecked or imported through a sound evidence protocol. TypeScript branding alone cannot sandbox malicious same-process code.

## 57. Comparing reference and production frontends

Conformance must name the relation being checked:

| Relation | What is compared |
|---|---|
| Syntax identity | Native syntax trees, including required category/binding structure. |
| Defined normalization | Trees after a precisely specified, semantics-preserving normalization. |
| Elaborated correspondence | Admitted declarations related under a stated mapping of names/environments. |
| Runtime preservation | Observable execution under a representation/effect/resource relation. |

Hash equality can identify exact byte equality. Unequal hashes say nothing decisive about semantic equality; equal untrusted labels do not prove that the checked objects match. A normalization must not delete an important modifier, assumption, or side effect to force agreement.

Use the reference corpus to compare decorated source with its canonical Lean output. Include intentional mismatches and altered dependencies. The oracle should check the expected statement, not only whatever statement the candidate exporter supplied.

“Lean accepted it” is not proof that it means what the source intended. “Two checkers accepted it” is not a formal equivalence theorem between the checkers. These remain valuable but bounded observations.

## 58. Erasure and executable IR

Erasure operates on genuinely admitted declarations and a relevant executable environment. It removes proofs/types only where computational irrelevance is justified.

The erasure result records runtime parameters, retained values, constructor tags/fields, dependencies, and capability requirements. It must preserve the order and identity of runtime arguments after proof-parameter removal. It must not confuse a proof argument with a data argument whose type mentions a proof.

RuntimeIR describes the selected PSC/Lean executable meaning. It may contain functions, calls, bindings, constructor/projection operations, structured control flow, semantic primitive identities, and explicit capability operations. It must not define `Nat` as JS `number`, a structure as a Rust layout, or an effect as a Wasm opcode.

Backend representation choices belong in later target IR. The name `VerifiedIR` in an implementation is not a preservation theorem. Its acceptance conditions and associated evidence must be explicit.

If a runtime dependency is noncomputable, unsupported, unknown, or unsafely replaced without sufficient assurance, the compiler rejects the requested executable claim. It must not insert a stub, throw at an arbitrary reachable point, or call another checker as a hidden fallback.

## 59. Preservation propositions and certificates

A useful pure-program preservation theorem relates source and target through representation functions/relations:

```text
For every admitted input x and related target input tx:
    source execution and target execution have corresponding outcomes,
    with related results and the specified termination/resource behavior.
```

For effects, include observable traces and state relations. For nondeterministic models, refinement may be the appropriate relation. One must state which direction is proved; agreement only when both terminate is weaker than total-correctness preservation.

Prove regular transformations and runtime representation lemmas once. For changing or complex transformations, a proof-producing compiler may emit a certificate `c` for the concrete pair `(S,T)`, checked by a validator with the theorem:

```text
validate(S, T, c) = accepted  ->  Preserves(S, T)
```

The validator's soundness, evidence evaluation, and connection to actual artifacts are obligations. A checker named `validate` or a solver-generated Boolean is not sufficient.

Semantics and preservation relations can be ordinary formal definitions over ASTs. The logical kernel need not grow trusted TS/Rust/Wasm instructions. CompCert is a methodological precedent for carefully scoped compiler preservation, not a source of automatically applicable PSC proofs. [P4]

## 60. Target routes and external compilers

The language permits multiple routes over one meaning:

| Route | Use | Additional assurance boundary |
|---|---|---|
| TS source → external TS compiler → JS | Readable `.ts`, ecosystem integration, bootstrap. | Actual TS transformations/configuration and final JS. |
| Direct JS | ESM/application output. | JS lowering, printer, runtime helpers, engine. |
| Rust source → native/Wasm toolchain | `.rs` libraries and native/Wasm deployment. | Rust lowering, dependencies, compiler/linker/target behavior. |
| Direct Wasm | Explicit portable runtime/ABI profile. | Runtime representation, binary encoder, imports, engine. |

Owning a backend does not prove it. Using an external compiler does not invalidate the source theorem, but transfers to final-executable guarantees need the intervening relationships or explicit assumptions.

A restricted TS profile can support validation of actual `tsc` output against certified type-erased TS meaning. This is downstream translation validation, not an additional JS emitter. Every allowed transform or normalization still needs justification.

For Rust, safe source and successful `rustc` checks do not prove functional equivalence. Native and Wasm have different capabilities and target assumptions. A bounded validator for one optimization stage does not certify the whole downstream toolchain.

A Wasm validator checks module well-formedness, not the source contract. Direct Wasm still needs exact numbers, strings, ADTs, closures, memory/resource behavior, and host interfaces. No route may use a foreign runtime operation as hidden logical evidence.

## 61. Exact emitted artifacts, linking, and release snapshots

A proof about a target AST does not cover a printer that changes an operator or swaps arguments. Establish a verified/certified serializer or independently parse the emitted file and validate it against the proved target.

The checked identity covers the source, canonical declarations, runtime IR, target files, linked runtime, imports, compile options, ABI, and allowed assumptions. The release must use that exact immutable snapshot.

Bundling, minification, tree shaking, link-time optimization, framework transforms, or post-check edits may change behavior. They need evidence under the claimed preservation endpoint or must remain explicit assumptions. A source map or checksum does not prove that they are correct.

External consumers need interfaces that enforce or state the represented input domain. A TS `bigint` parameter is not a proof that the supplied integer is nonnegative. Proof-erased internal APIs should be exported through appropriate validators or a clearly restricted internal ABI.

## 62. Resource limits and checker build trust

A mathematical termination proof does not guarantee sufficient time, memory, stack, or operating-system resources on every machine. A certified executable profile either proves required bounds, permits specified resource outcomes, or states environmental assumptions.

Resource bounds on checking and compilation are equally explicit. Exhaustion cannot turn into a success stub, incomplete emitted artifact, or an unbounded hidden retry through another provider. Partial work is not accepted state.

A compiler generating proof candidates may be outside logical authority when an independent checker checks them. A compiler building the checker executable has a build-trust role: miscompilation could alter its acceptance behavior. Record and strengthen that chain through pinned builds, independent replay, diverse implementations where useful, and ultimately appropriate preservation evidence.

Self-hosting is actual generated-compiler execution and a stated fixed-point relationship. It is not a logical consistency proof and does not remove a compromised-seed concern merely by repetition. The compiler and kernel can be jointly bootstrapped without claiming that their source admission proves their implementations correct.

---

# Part VII — Libraries, interoperability, and applications

## 63. Standard library layering

The language foundation is small; the useful platform need not be. Application capabilities should be ordinary definitions, specifications, generators, and explicit adapters rather than a collection of new trusted constructs.

A standard distribution should separate:

| Layer | Responsibility |
|---|---|
| Pinned native foundation | The selected `Init`/`Std` declarations and exact logical semantics. |
| Portable data | Collections, text/bytes, codecs, domain data, and algorithms. |
| Specification libraries | Laws, program models, invariants, and admitted specification theorems. |
| Platform interfaces | IO, network, time, randomness, storage, process, UI, and resource models. |
| Runtime adapters | Actual JS/native/Wasm operations and their stated assumptions/evidence. |
| Tooling | Build, editor, test, document, import-generation, and migration services. |

The exact library API is independently versioned. This reference does not claim that the illustrative `Psc.*` namespaces exist today. A package may implement them without adding a new parser production when ordinary Lean definitions suffice.

Proof-only library dependencies may be removed from runtime only through justified erasure. Conversely, importing a theorem package must not implicitly enable browser capabilities or execute an unapproved build script.

## 64. Packages and logical modules

Follow the v0.7 JS-ecosystem direction: npm/package.json is the primary JS package substrate, with a namespaced ProofScript configuration and a reproducible dependency lock. Do not create an accidental second package-resolution authority in competition with npm while claiming the same dependency identities. A Lean/Lake oracle workspace can be generated explicitly from the selected source/module manifest.

The configuration records source edition, semantic pin, entry modules, unique source mapping, allowed compiler extensions, dependencies, target profiles, runtime ABI, capabilities, and assurance policy. Each identifier has a distinct role; package semver does not stand in for a Lean semantic version.

The logical source graph, elaboration/plugin graph, proof dependency graph, and runtime graph are distinct. All can be recorded without making every graph a bootstrap prerequisite.

Canonical `.ps` generation is an artifact, not a competing handwritten source implementation. A manifest identifies authoritative source and generated traces. Duplicate logical sources, import cycles unsupported by the module model, missing modules, symlink escapes, and target-incompatible dependencies must be diagnosed before a release claim is produced.

Package installation, macro execution, and proof checking are different permissions. Reading an import does not authorize an arbitrary installation script. Integrity/signature checks establish origin or byte identity, not semantic correctness.

## 65. Foreign interfaces and typed boundary values

Foreign interfaces are not part of the logical kernel. A versioned InterfaceIR or equivalent adapter contract can generate native declarations, `.ps` interfaces, wrappers, target bindings, and documentation.

Distinguish:

1. **Owned data:** decoded/copied values satisfying the PSC representation invariant.
2. **Foreign handles:** identity-bearing or mutable objects whose operations are explicit effects.
3. **Foreign operations:** calls with specified argument/result conversions, receiver, effects, and lifetime.

A foreign API declaration records package/export identity, target-resolution conditions, parameter/result representations, optionality, receiver binding, errors, synchrony, callbacks, resource behavior, and model/assumption status.

No arbitrary external signature returning a proof of `P` or a value of an unconstrained empty type can become a proof oracle. At a dependent boundary, runtime data must be validated or accompanied by independently checked evidence before it receives an invariant-bearing type.

A `.d.ts` importer supports a declared subset and rejects unsupported structural/type-level machinery rather than lowering it to a native unchecked `any`. An imported type annotation is not a theorem about a foreign implementation. Advanced conditional/mapped/template types may be specialized in an untrusted import phase, but the resulting interface still needs a correct mapping and an honest runtime boundary. [T2–T4]

## 66. Data conversion, callbacks, and Promise adaptation

For a JS data boundary, distinguish missing field, present undefined, null, and present value when the API does. A codec may deliberately map some of these to `Option.none`; it must not claim a general inverse if information was lost.

A decoder of arbitrary JS objects must account for getters, proxies, mutation, and reentrancy. “Read a property” may itself be an effect. Prefer a controlled data snapshot or explicitly model the operation. A structural TypeScript type is not proof that an object is immutable plain data.

Numeric conversions check the required domain. JS `number` to Nat needs the selected finite/integral/range contract. JS BigInt to Nat still needs nonnegativity. Exact large integers may require a specified JSON string/tag encoding rather than ordinary JSON numeric precision.

Foreign methods preserve the receiver. Callback interfaces specify whether calls are immediate/deferred, one-shot/repeated, reentrant, retained, and allowed after disposal. Registration should return a scoped handle when lifetime management is required.

An existing Promise may already be running. Attaching to it differs from starting a cold cancellable computation. Abort/cancellation support, rejection reasons, and late completions are explicit adapter semantics. The base does not assert Promise equivalence to native Lean `Task` or a proposed `Psc.Async` model.

## 67. Exporting libraries and complete applications

A JS package may contain ESM, `.d.ts`, source maps, runtime dependency identities, canonical declaration/proof bundles, and an assurance manifest. TS and Rust source artifacts remain valid deliverables when those routes are selected.

Erased proof parameters are not advertised as runtime arguments. APIs with constrained inputs require validating wrappers or a documented restricted ABI; nominal branding in `.d.ts` assists static users but does not constrain arbitrary JavaScript callers.

Complete supported applications should be authorable in `.ps` or `.lean`: domain models, codecs, routing, services, UI definitions, orchestration, and selected proofs. Foreign adapters inside the distribution do not require every user to hand-write TS glue, nor do they imply that the browser/database/framework was rewritten or verified.

Client/server separation needs transitive capability checks and explicit serialization, not merely shared type names. Framework transforms, secret access, side effects during module initialization, worker packaging, and server rendering each require tested deployment profiles.

A full-app acceptance corpus should include a browser/service application with typed errors, malformed-input handling, persistence, cancellation, and one useful verified domain transition. A proof about the in-memory transition does not automatically establish database isolation or network correctness.

## 68. Optional UI syntax and other extensions

The base does not admit JSX/TSX, a `component` declaration, or a new brace-return language. An optional `.psx` dialect must have an explicit extension ID and grammar, typed interpolation categories, hygienic expansion, source maps, and paired plain-library examples.

Prefer a term-local quotation over a second whole application language. The expansion should construct ordinary view/component values that can also be written using base `.ps` or native `.lean`. No unchecked JavaScript expression is silently accepted inside interpolation.

Props, children, events, keys, raw HTML, resource lifetimes, and renderer operations require defined library meanings. A React adapter must obey the framework's lifecycle constraints; well-typed view construction alone does not prove renderer correctness, hydration equivalence, accessibility, or injection freedom.

New syntax passes the same proposal test as the base: exact category, discriminator, lowering, environment, interaction cases, evidence status, and migration. Until that contract exists, a markup illustration is **extension pseudocode**, not v0.9 source.

---

# Part VIII — Tooling, migration, and release assurance

## 69. Canonical formatting

A conforming formatter preserves parsed meaning, ownership categories, names, comments, and the selected environment. Suggested `.ps` style uses `name: Type`, spaces around `:=`, adjacent decorated calls, and multiline native-compatible layout. It emits no ProofScript-only declaration, field-declaration, constructor, or match-alternative semicolons. Native `.lean` traces use ordinary Lean style.

```text
f(x, y)       not interchangeable by whitespace alone with f (x, y)
.some x       a pattern; do not format it into .some(x)
function ... := { ... }     no added declaration terminator
match ... with { ... }     native alternatives without added terminators
let x := e; body            preserve native let/body separation
do { action; return x; }    preserve native sequence separators
by { t1; t2 }               preserve native sequencing
by { t1 <;> t2 }            preserve the different all-goals combinator
```

Use layout rather than optional native separators where that is the canonical presentation and reparsing preserves the same AST. Compact native `let`, `do`, instance-initializer and local-`where` sequences may retain their legal semicolons. Never infer ownership by matching `};` or by deleting every line-ending `;`. A `;` inside a literal, comment or quotation is not formatting punctuation at all.

The formatter must round-trip AST/category identity up to its stated normalization. Test multiline applications, nested matches, nested proof/do sequences, suffix attachment, and native `;`/`<;>` separately. Formatting incomplete source may preserve unrecovered regions verbatim or report inability; it must not hide an error by producing accepted code with another meaning.

Formatting and migration are distinct operations. The r2 formatter rejects or preserves unsupported legacy syntax for an explicit migrator; it does not silently parse it under the previous draft and emit a new interpretation. A formatting rule cannot broaden the grammar or establish compiler preservation.

## 70. Diagnostics and language-server information

Diagnostics include a stable code, category, original span, related/expanded spans, selected profile, and actionable explanation. Avoid opaque target-language errors when the actual failure concerns an unsupported source feature or missing adapter.

The LSP/CLI should expose inferred types, selected methods, inserted arguments, coercions, instances, constraints, proof goals, assumption dependencies, canonical lowering, and target-capability requirements.

Cached diagnostics and proof results must be tied to source/environment identities. Changed imports, instances, options, specification predicates, or runtime implementations invalidate affected evidence. Stale successful results must not be displayed as current verification.

Suggested CLI capabilities—not claims of currently implemented commands—are source checking, canonical Lean emission, conformance testing, explanation, manifest inspection, formatting, tests, target builds, and independent artifact verification. Command spelling can evolve without changing the underlying language protocol.

## 71. Migration from v0.7 and earlier PSC3/v0.9 drafts

This is v0.9.0 **draft revision 2**, grammar identity `ps-0.9-r2`. Existing v0.7, PSC1/PSC2 and earlier v0.9-draft source keeps its declared interpretation. Version `0.9.0` alone is insufficient to distinguish these unfrozen drafts: record the grammar revision and exact registry/reference identity. The migrator parses the old grammar first and produces an explicit new source artifact.

| Earlier construct or proposal | Revised v0.9 treatment |
|---|---|
| `def`, `const`, `function` aliases, explicit parameters, D-CALL | Retained with faithful native semantics. |
| `D-DECL-SEMI` at the end of owned definitions | Retired from the r2 default. Remove only the old AST's added command terminator. |
| Added `;` after structure/class field declarations, constructors or match alternatives | Replace with native-compatible member/alternative layout; do not concatenate entries blindly. |
| Semicolons inside native `let`, `do`, tactics, instance initializers and local `where` sequences | Retain according to the corresponding native category. |
| Plain tactic `;` versus `<;>` | Preserve the original combinator and goal behavior. |
| Omitting `;` only after a closing brace | Replaced by the uniform rule: no added command terminator, regardless of the body's last token. |
| `.ps` as byte-identical `.lean` | Not adopted; D/E source still has explicit canonical lowering. |
| Removing D-CALL adjacency | Not adopted; tuple/protected-neighbor behavior is unchanged. |
| Bare `function ... { ... }`, TS arrow lambdas or implicit nullability | Still outside the base grammar. |
| Named arguments and trailing commas in D-CALL | Retained with their existing narrow contracts. |
| `E-INSTANCE-BODY` / `E-WHERE-BODY` | Retained; follow native sequence rules rather than impose mandatory semicolons. |
| Mandatory direct JS/Wasm switch | Still not a syntax-revision requirement; existing backend plans remain independently gated. |

A legacy top-level `const x: Nat := 1;` becomes `const x: Nat := 1`. A legacy body containing `let y := e; y` keeps that **inner** semicolon. A braced `do` ending in a native sequence semicolon retains it while any separate legacy declaration terminator is removed. A literal such as `"const x = 1;"` remains byte-identical.

No regex/global punctuation deletion is a valid migrator. Preserve binders, native application groups, tuple arity, layout-sensitive boundaries, suffix association, source positions, proof statements and assumptions. A changed grammar revision invalidates dependent parser/formatter caches and source-correspondence certificates; unchanged canonical Lean evidence may be reused only under the independently specified evidence policy.

The original v0.7 corpus remains untouched at its pinned repository location. The earlier v0.9 artifact is an archived draft, not a second silently accepted default grammar. Current conformance expectations identify r2 explicitly, retain case IDs where revised, and record changed outcomes in the revision notes.

## 72. Source and specification compatibility

Source syntax, elaboration behavior, logical assumptions, library APIs, proof scripts, portable bundles, runtime ABI, and backend preservation profiles have separate compatibility dimensions. Record them independently.

A tactic change may break proof-script replay while leaving the theorem meaningful. A source-compatible library change may alter runtime behavior or add a trusted assumption. A new optional syntax registration may collide with a previously imported parser. Each requires the appropriate version/review boundary.

A `.ps` file is not silently reclassified by its contents. Project metadata selects edition and extension environment. Mixed-version packages either use a supported adapter/canonical bundle boundary or are rejected.

Source compatibility is not a reason to retain an unsound implementation bug. A corrective release should identify the change and replay the relevant negative corpus. It must not conceal a reduced acceptance set as “no changes” merely because the surface grammar is unchanged.

## 73. Conformance program

The included `conformance/cases.jsonl` is an authored contract corpus. Cases state source category, required features, expected phase outcome, and canonical form or diagnostic where specified. They are not a claim that an owned parser already executes them.

Required test families include:

| Family | Essential positive and negative cases |
|---|---|
| Lexical/category ownership | Native comments, Unicode, delimiters in strings, committed failures, unknown extensions. |
| Calls | Unit, tuple, currying, nested groups, receiver position, named/default args, trailing commas. |
| Headers/declarations | Alias restrictions, binders, dependent order, modifiers, native boundaries, invalid layout, obsolete added terminators, suffixes. |
| Data/patterns | Dependent records, inherited parents, constructor terms versus patterns, indexed motives. |
| Effects/control | Native braced do, loops, mutation/capture, transformer order, partiality-sensitive optimization. |
| Proofs | False proofs, hidden assumptions, tactic categories, exact statement/dependency binding. |
| Intrinsic contracts | Valid and false clauses, duplicate clauses, missing evidence, loop capability restrictions. |
| Runtime/FFI | Numeric/string boundaries, stale callbacks, foreign receivers, malformed values and unknown capabilities. |
| Artifacts | Altered emitted bytes, wrong runtime identity, forged checked handles, cache context mismatches. |

The actual v0.7 positive/negative/lowering corpus remains a compatibility input. Updating v0.9 must not silently redefine those earlier expectations. Any case whose source relies on an under-specified v0.7 combination must be classified explicitly as clarified, newly specified, or unsupported.

## 74. Implementation and release gates

A useful sequence is:

1. Load the pinned environment/feature registry and validate version identities.
2. Implement category-preserving parsing and diagnostic ownership.
3. Implement canonical lowering for the old core decorations and new explicit v0.9 additions.
4. Compare canonical outputs and negative cases against pinned Lean.
5. Establish genuine declaration admission and immutable checked-state handling.
6. Complete an explicit executable primitive/data/call profile and target conformance.
7. Build a useful application and theorem corpus with exact assumptions.
8. Prove reference properties and incrementally establish production refinement/preservation.

Tests, proofs, and usability studies provide different evidence. The release label must not exceed its weakest relevant required boundary. A compiler that parses all examples but cannot check them is not a complete implementation. A kernel that checks generated proofs but cannot relate them to the requested source is not an end-to-end source verifier.

The language can support useful type-checked applications before every preservation theorem exists, provided their compilation/runtime assumptions are explicit. It must not call those applications fully proved simply because the user selected a strict-sounding flag.

---

# Part IX — Consolidated grammar and reference tables

## 75. Grammar notation and scope

This grammar specifies the owned overlay. `Native<C>` denotes the exact selected native parser/category `C`; `Lift<C>` replaces only approved recursive child slots with the corresponding ProofScript parser. It is a typed grammar dependency, not “any text until the next delimiter.”

`ADJ` means byte-adjacent token boundaries with no intervening whitespace/comment. `?`, `*`, and `+` are grammar multiplicities; quoted tokens are literal tokens. Square brackets in productions below indicate optional grammar unless quoted. Semantic predicates after productions are mandatory.

The composition, precedence, and committed-error rules in §§11–16 resolve overlaps. A parser generator must not treat the displayed alternatives as an unordered permissive union. Native declaration and tactic end conditions are supplied by their exact categories, not a universal newline heuristic.

## 76. Owned grammar

```ebnf
PSFile              ::= Lift<NativeCommandSequence(PSCommand)> EOF ;
PSCommand           ::= OwnedValueDecl
                      | BracedStructure | BracedClass | BracedInductive
                      | BracedInstance | Lift<NativeCommand> ;
OwnedValueDecl      ::= Native<DefModifiers> ConstDecl
                      | Native<DefModifiers> FunctionDecl
                      | Native<DefModifiers> DecoratedDef ;
ConstDecl           ::= "const" Native<DeclId> ResultSpec? OwnedValue ;
FunctionDecl        ::= "function" Native<DeclId> HeaderBinders
                        ResultSpec? NativeContracts? OwnedValue ;
DecoratedDef        ::= "def" Native<DeclId> HeaderBinders?
                        ResultSpec? NativeContracts? OwnedValue ;
HeaderBinders       ::= HeaderBinder+ ;
HeaderBinder        ::= ExplicitGroup | Native<OtherDeclarationBinder> ;
ExplicitGroup       ::= "(" ExplicitEntry ("," ExplicitEntry)* ","? ")" ;
ExplicitEntry       ::= Native<BinderIdent> ":" PSTerm Native<DefaultSuffix>? ;
ResultSpec          ::= ":" PSTerm ;
OwnedValue          ::= ":=" PSDeclBody Native<TerminationSuffix>?
                        WhereSuffix? ;
PSDeclBody          ::= Lift<NativeDeclBody> ;
WhereSuffix         ::= BracedWhere | Lift<NativeWhereDecls> ;
BracedWhere         ::= "where" "{" NativeLocalSequence "}" ;
NativeLocalSequence ::= Lift<NativeWhereLocalSequence> ;
BracedStructure     ::= Native<StructurePrefixAndHeader> "where"
                        "{" NativeFieldSequence "}" Native<DerivingSuffix>? ;
BracedClass         ::= Native<ClassStructurePrefixAndHeader> "where"
                        "{" NativeFieldSequence "}" Native<DerivingSuffix>? ;
NativeFieldSequence ::= Lift<NativeStructFields> ;
BracedInductive     ::= Native<InductivePrefixAndHeader> "where"
                        "{" NativeConstructorSequence "}" Native<InductiveSuffix>? ;
NativeConstructorSequence ::= Lift<NativeConstructorSequence> ;
BracedInstance      ::= Native<InstancePrefixAndHeader> "where"
                        "{" NativeInstanceFieldSequence "}" ;
NativeInstanceFieldSequence ::= Lift<NativeWhereStructInstFields> ;
PSTerm              ::= Lift<NativeTerm> | DecoratedCall | BracedIf | BracedMatch ;
DecoratedCall       ::= CallableHead ADJ "(" CallArguments? ")" ;
CallArguments       ::= CallArgument ("," CallArgument)* ","? ;
CallArgument        ::= NamedCallArgument | PositionalCallArgument ;
NamedCallArgument   ::= Native<Ident> ":=" PSTerm ;
PositionalCallArgument ::= PSTerm ;
CallableHead        ::= Native<CompatibleCompletedHead> | "(" PSTerm ")"
                      | DecoratedCall | NativeProjectionOfCompletedHead ;
BracedIf            ::= "if" "(" PSTerm ")" "{" PSTerm "}"
                        "else" "{" PSTerm "}" ;
BracedMatch         ::= Native<MatchPrefixAndDiscriminantsWithLiftedTerms>
                        "with" "{" NativeMatchSequence "}" ;
NativeMatchSequence ::= Lift<NativeMatchAlts> ;
PSDo                ::= Lift<NativeDoTerm> ;
PSProof             ::= Lift<NativeProofTerm> ;
PSTactic            ::= Lift<NativeTactic> ;
PSPattern           ::= Native<Pattern> ;
```

Mandatory predicates and clarifications:

- `function` has at least one nonempty explicit parameter group; `const` has no declaration binders.
- The single-entry explicit group follows native binder meaning. The comma-list owns the additional complete entries; no missing per-entry type is inferred by punctuation.
- Native multi-name binders and implicit/instance binders are inherited, not comma-rewritten.
- A trailing comma requires at least one entry and is owned only by `D-TRAILING-COMMA`.
- Duplicate named arguments in one D-CALL are rejected. Named matching remains native elaboration.
- Empty structure/inductive bodies are syntactic candidates only where the native lowered declaration is legal; formation/elaboration can reject them.
- Native structure parent/constructor and inductive result information resides in the header categories and must be preserved.
- There is no quoted `";"` production in an owned declaration or wrapper. Rule-final unquoted semicolons above are **EBNF notation**, not ProofScript tokens. All source semicolons come from the incorporated native categories.
- `NativeContracts` is the exact pinned optional requires/ensures category, enabled only with the declared intrinsic capability.
- The `where finally` verification suffix remains native unless an exact composition rule enables it. It is not an arbitrary command inside `NativeLocalSequence`.
- `PSTerm` does not create `PSTactic` or `PSPattern` productions implicitly.
- A native parenthesized tuple remains one term. An outer decorated comma never splits its contents.

### 76.1 Exact sequence dependencies

The sequence nonterminals above are incorporated parser compositions, not new permissive repetitions:

| Nonterminal | Pinned composition | Semicolon ownership |
|---|---|---|
| `PSDeclBody` | `Command.declBody`, with registered term slots lifted | No additional terminator; preserve the special native `by` boundary handling. |
| `NativeFieldSequence` | `Command.structFields` with its native field binders and layout checks | No extra field separators. |
| `NativeConstructorSequence` | The `many ctor` constructor sequence of `Command.inductive` | Native constructor marker/header boundaries, no extra `;`. |
| `NativeMatchSequence` | `Term.matchAlts`, using `matchAlt` and native pattern groups with a lifted RHS | No extra alternative separator. |
| `NativeInstanceFieldSequence` | The `Term.structInstFields (sepByIndent Term.structInstField "; " (allowTrailingSep := true))` portion of `Command.whereStructInst` | Native semicolons retained. |
| `NativeLocalSequence` | The `sepByIndent (ppGroup letRecDecl) "; " (allowTrailingSep := true)` portion of `Term.whereDecls` | Native semicolons retained. |
| Native `do` / tactic sequence | `Parser.Do` / `Parser.Tactic` and selected registrations | Preserve each category's exact sequence/combinator grammar. |

The owned braces add only a delimiter-scoped sequence position and matching-close condition; the native member parser, relative layout checks and nested continuations remain active. Canonical text printing may reindent an already parsed AST with a source map; it may not first strip braces/newlines and ask Lean to guess the AST. Unsupported layout combinations reject explicitly. Every wrapper requires standalone/reference composition tests before implementation support is claimed. [L2–L3]

## 77. Native category dependency map

These dependencies identify where a compiler must obtain inherited grammar behavior. Paths are relative to `study/lean4-4.34.0/src/Lean/` at the pinned repository snapshot.

| Category/concept | Primary source dependency | Required preservation |
|---|---|---|
| Tokenization and parser combinators | `Parser/Basic.lean`, `Parser/Types.lean` and lexer support | Token boundaries, trivia, positions, commit/recovery. |
| Native terms and arguments | `Parser/Term.lean`, `Parser/Term/Basic.lean` | Application groups, named/default arguments, binders, records, matches. |
| Native do sequences | `Parser/Do.lean` | Braced/layout sequence, separators, nested actions, loops, return. |
| Commands/declarations | `Parser/Command.lean` | Declaration kinds, modifiers, contracts, suffixes, stateful scopes. |
| Proof/tactic sequences | `Parser/Tactic.lean` and imported tactic registrations | Tactic combinators, term slots, proof state. |
| Modules | `Parser/Module.lean`, `Parser/Module/Syntax.lean` | Imports, module modes, visibility and dependency state. |
| Universes | `Parser/Level.lean` plus semantic level definitions | Exact level expressions and parameter scope. |
| Attributes/notation/macros | `Parser/Attr.lean`, `Parser/Syntax.lean`, `Parser/Extension.lean` | Registrations, scope, hygiene, collision policy. |
| String interpolation | `Parser/StrInterpolation.lean` | Literal segments and term-interpolation boundaries. |
| Intrinsic verification | `Parser/Command.lean`, `Parser/Do.lean`, `Std.Internal.Do` | Native clauses, assertions, invariants, generated specs. |

The exact transitive source and registration set is an environment manifest requirement. The root paths alone do not claim a complete dependency-closure audit. Imported libraries can introduce further syntax; they are pinned and registered explicitly.

A compiler may vendor or mechanically derive its native grammar tables, or use the official frontend as an oracle. It may not replace a difficult category with an approximate textual grammar while advertising identical coverage.

## 78. Feature registry summary

| ID | Class | Category | v0.9 disposition | Canonical target |
|---|---|---|---|---|
| `L-CORE-LEAN` | L | Registered native categories | Inherited, capability-scoped. | Same native syntax and meaning. |
| `L-DO-BRACKETED-434` | L | Term/do sequence | Confirmed in pinned source and canonical example. | Native braced/layout do AST. |
| `L-INTRINSIC-CONTRACTS-434` | L | Declaration/do | Experimental, explicitly selected. | Native specification mechanism. |
| `L-ERASED-DO-434` | L | Do element | Inherited capability. | Native verification-only binding. |
| `L-RECALL-434` | L | Command | Inherited capability. | Native checked restatement, not new declaration. |
| `L-MONOTONICITY-BY-434` | L | Declaration suffix | Inherited capability. | Native contextual suffix. |
| `L-LIA-GROBNER-PARAMS-434` | L | Tactic | Inherited capability. | Native tactic parameter parsing. |
| `D-CALL` | D | Term | Retained. | One native application argument sequence. |
| `D-EXPLICIT-PARAMS` | D | Decl/field/local header | Retained; scope explicit. | Ordered explicit native binders. |
| `D-CONST-ALIAS` | D | Command head | Retained. | Parameterless native `def`. |
| `D-FUNCTION-ALIAS` | D | Command head | Retained. | Native `def`, explicit parameter required. |
| `D-NAMED-CALL` | D | D-CALL argument | Newly specified. | Native named argument. |
| `D-TRAILING-COMMA` | D | Decorated nonempty list | Newly specified. | No additional argument/binder. |
| `E-IF-BRACE` | E | Term | Retained. | Native conditional, one term per branch. |
| `E-STRUCT-BODY` | E | Structure fields | Retained, r2 native-layout body. | Native field sequence, no added semicolons. |
| `E-CLASS-BODY` | E | Class fields | Retained, r2 native-layout body. | Native class field sequence, no added semicolons. |
| `E-INDUCTIVE-BODY` | E | Constructor list | Retained, r2 native sequence. | Native constructors/suffixes, no added terminators. |
| `E-INSTANCE-BODY` | E | Instance fields | Newly explicit registration. | Native instance field sequence. |
| `E-MATCH-BODY` | E | Match alternatives | Retained, r2 native sequence. | Native patterns/RHS boundaries, no added terminators. |
| `E-WHERE-BODY` | E | Local declarations | Retained. | Native local declaration sequence. |

The machine-readable registry contains **20 active feature records** and a separate retired-feature record for `D-DECL-SEMI`. The registry includes the grammar revision; unchanged feature IDs do not imply unchanged old separator contracts. Historical feature ID aliases must have an explicit mapping rather than silently claiming new proof status. Every row's present implementation-proof status is specified/inherited-contract, not production-proved by this document.

## 79. Diagnostic catalog

The following diagnostic categories are normative; wording and additional payloads can improve without changing meaning.

| Code | Condition |
|---|---|
| `PS_VERSION_MISMATCH` | Source/reference/environment identity incompatible. |
| `PS_UNSUPPORTED_FEATURE` | The selected implementation cannot honor a required feature. |
| `PS_UNREGISTERED_EXCEPTION` | An unregistered owned syntax extension is requested. |
| `PS_AMBIGUOUS_OWNERSHIP` | Competing source productions lack a declared compatibility rule. |
| `PS_CONST_WITH_PARAMS` | Declaration binders supplied to `const`. |
| `PS_FUNCTION_WITHOUT_PARAMS` | `function` lacks a nonempty explicit parameter group. |
| `PS_EMPTY_PARAMETER_GROUP` | Empty group used where an explicit declaration parameter is required. |
| `PS_UNEXPECTED_SEMICOLON` | A semicolon is not consumed by any valid active native category; legacy added terminators are not accepted in r2. |
| `PS_INVALID_LAYOUT` | An owned body fails its incorporated native layout/member-boundary contract. |
| `PS_EXPECTED_COLON_EQUALS` | An owned definition/binding uses an inadmissible body delimiter. |
| `PS_BLOCK_BODY_NOT_ADMITTED` | Bare brace-bodied function syntax requested. |
| `PS_EMPTY_LIST_ENTRY` | Empty/doubled decorated call/header entry. |
| `PS_DUPLICATE_NAMED_ARGUMENT` | Duplicate explicit named key in one decorated call. |
| `PS_NAMED_ARGUMENT_SYNTAX` | Unregistered named-argument spelling, such as `name: value`. |
| `PS_IF_REQUIRES_PARENS` | Braced conditional missing its condition parentheses. |
| `PS_BRANCH_REQUIRES_SINGLE_TERM` | A braced conditional branch contains an unregistered statement list. |
| `PS_PATTERN_CALL_NOT_ADMITTED` | D-CALL attempted in a native pattern position. |
| `PS_UNSUPPORTED_COMPOSITION` | Individually known features combined in an unsupported native category. |
| `PS_NATIVE_ELABORATION` | Canonical native elaboration rejects the candidate. |
| `PS_UNRESOLVED_METAVARIABLE` | A release declaration still contains an unresolved semantic hole. |
| `PS_KERNEL_REJECTION` | Actual declaration admission fails. |
| `PS_ASSUMPTION_POLICY` | A theorem depends on a disallowed assumption or shortcut. |
| `PS_INCOMPLETE_PROOF` | Required evidence was not established. |
| `PS_DEPENDENT_FIELD_MISMATCH` | An update/constructor cannot retain a field at its required type. |
| `PS_MODULE_AMBIGUITY` | More than one unselected source for a logical module. |
| `PS_MISSING_DEPENDENCY` | A required source/declaration/runtime dependency is unavailable. |
| `PS_NONCOMPUTABLE_EXECUTION` | A runtime request reaches an unavailable noncomputable realization. |
| `PS_RUNTIME_PRIMITIVE_UNSUPPORTED` | No faithful selected target implementation for a primitive. |
| `PS_FOREIGN_BOUNDARY` | Input/output conversion or external capability fails its contract. |
| `PS_ARTIFACT_IDENTITY_MISMATCH` | Evidence does not bind the bytes/dependencies being consumed. |
| `PS_RESOURCE_LIMIT` | Explicit time/fuel/memory/size budget exhausted. |
| `PS_CANCELLED` | The operation was cancelled without accepted completion. |
| `PS_INTERNAL_ERROR` | An unexpected implementation failure, never successful evidence. |

Native diagnostics can be attached as structured causes rather than replaced with an invented exact code. For example, the current Lean oracle reports a type mismatch for an invalid dependent update; an owned frontend can map that to a more specific user-facing category.

## 80. Normative lowering examples and pitfalls

The following table defines small relationships for the overlay, assuming identifiers/types exist in the declared environment. Parsing a term is not the same as elaborating a complete program.

| Source | Canonical relationship / outcome |
|---|---|
| `f(x)` | Native application `f x`. |
| `f(x, y)` | Native application with two arguments `f x y`. |
| `f((x, y))` | Native application with one tuple `f (x, y)`. |
| `f (x, y)` | Inherited application to a tuple. |
| `f()` | Native `f ()`. |
| `f(x,)` | Native `f x`, trailing-comma feature recorded. |
| `f(,)` | Reject an empty entry. |
| `f(x,,y)` | Reject an empty entry. |
| `f(x, n := 2)` | Native `f x (n := 2)`, named feature recorded. |
| `f(n := 1, n := 2)` | Reject duplicate named argument. |
| `f(n: 2)` | Not a named argument in this grammar. |
| `g f(x)` | Native `g (f x)`. |
| `f(x)(y)` | Preserve nested native application grouping. |
| `f/- c -/(x)` | Decline D-CALL; use native parser result. |
| `const x: Nat := 1` | Native parameterless definition. |
| `const f: Nat -> Nat := fun x => x` | Native function-valued definition. |
| `function f(x: Nat): Nat := x` | Native definition with one explicit binder. |
| `function f(): Nat := 1` | Reject empty declaration parameter group. |
| `function f(x: Nat): Nat { x }` | Reject bare block body. |
| `function f(x: Nat): Box := { value := x }` | No outer terminator; the declared Box representation must separately type-check. |
| `if (p) { a } else { b }` | Native `if p then a else b`. |
| `if p { a } else { b }` | Reject this unregistered braced conditional spelling. |
| `match o with { | .some x => f(x) | .none => 0 }` | Native patterns; recursively lowered RHS. |
| `match o with { | .some(x) => x }` | Reject decorated call syntax in pattern. |
| `fun x => f(x)` | Native lambda with lowered body. |
| `(x) => x` | No TS lambda production in the base. |
| `structure S where { x: Nat }` | Native structure field sequence. |
| `namespace N { ... }` | No braced namespace in the base. |
| `do { return x; }` | Inherited do sequence, meaningful only in native effect context. |
| `return x` in arbitrary pure context | No universal JS early-return production. |

A compiler should include contextual tests where the same punctuation occurs inside strings, quotes, proofs, indices, dependent types, and other nested categories. Simple string substitutions may appear to pass this table while failing those interactions.

## 81. Evidence manifest contract

A build manifest must separate reference identities from results. A representative shape is:

```json
{
  "proofscriptSpecVersion": "0.9.0",
  "sourceEdition": "ps-0.9",
  "grammarRevision": "ps-0.9-r2",
  "semicolonPolicy": "lean-native-separators",
  "leanSemantics": {
    "version": "4.34.0",
    "commit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
  },
  "featureRegistryVersion": "0.9.0-r2",
  "compilerRevision": "<exact-revision>",
  "moduleFormatVersion": "<exact-version>",
  "implementationProfile": "<declared-capability-manifest>",
  "environmentIdentity": "<imports-options-registration-closure>",
  "axiomPolicy": "<policy-identity>",
  "sourceIdentity": "<checked-source-snapshot>",
  "kernelIdentity": "<checker-revision-and-profile>",
  "runtimeProfile": "<target-abi-and-primitive-manifest>",
  "evidence": {
    "sourceCorrespondence": "not-established",
    "logicalAdmission": "not-established",
    "contractProof": "not-requested",
    "terminationProof": "not-requested",
    "erasurePreservation": "not-established",
    "targetPreservation": "not-established"
  },
  "externalAssumptions": [],
  "artifactIdentities": []
}
```

Angle-bracket fields above are explanatory placeholders, not valid production identities. A production validator rejects missing, placeholder, unknown, or incompatible required fields.

A manifest is a report and routing object. It is not authority to create a checked module. The actual evidence must be checked through the selected protocol and bound to exact inputs. An empty external-assumption list must be established, not assumed merely because the compiler omitted one.

---

# Part X — Research basis and implementation sequence

## 82. What the study corpus established

The full `study/` tree was inventoried at the pinned repository baseline. It contains nine top-level collections, 16,279 tree entries, and 14,750 files. The text-document selection contains 1,062 paths corresponding to 930 unique Git blobs. With selected parser, scalar, example, and conformance sources, 1,135 unique blobs totaling 222,986,706 bytes were retrieved and checked against their Git blob identities.

This is complete inventory/retrieval coverage for the stated text selection—not a claim that every document received an equally deep line-by-line review. Close reading prioritized the v0.7 reference, parser/lowering contract, native declaration/term/do parsers, function application, recursion, macros, monad transformers, theorem foundations, TypeScript functions/compatibility, and the independent checker's divergence notes.

The HTPI PDF was inventoried as an additional format; its HTML companion was used for this study. Web assets/fonts/search scripts are not prose documents and were not treated as language specifications. No third-party books or mirrored website contents are redistributed by this package.

The corpus includes duplicate pages and historical releases. A tutorial, saved website mirror, or independent checker snapshot may target a different release. Exact pinned Lean source and toolchain behavior take precedence for the selected profile. [R1–R6]

## 83. Research conclusions and alternatives

### 83.1 Why a thin decoration is preferred

A new JS-like type/effect system would need a separate semantic account, elaborate interoperation rules, and additional preservation arguments. A small syntax overlay can instead preserve the mature dependent language while improving common declaration and call presentation.

The chosen surface is intentionally not a token-for-token TypeScript imitation. `fun`, native binders, `:=`, native pattern syntax, and Lean command scopes make the semantic model visible. Their learning cost should be measured, but removing them by inventing partial substitutes would not be a free simplification.

### 83.2 Why the reference keeps call adjacency

A whitespace-insensitive native call design could be reasonable in a wholly new language. It would, however, alter v0.7's protected tuple/application neighbor and require an explicit migration. This version favors compatibility and a small lowering relation. The formatter exposes the distinction consistently.

### 83.3 Why bare brace-bodied functions are excluded

A bare body would need a decision about expression blocks, statement sequencing, implicit return, mutation, and termination punctuation. Native-boundary `:= expression` and `:= do { ... }` already distinguish pure term construction from effect sequencing. The simpler base avoids importing JS expectations about every brace block. Revision 2 also removes the old ProofScript-only declaration and alternative terminators; it preserves only native category-specific semicolons.

### 83.4 Why the additions are small

Named arguments inside decorated calls reuse native named-argument semantics. Trailing commas reuse an existing nonempty list without introducing an argument. Braced instance registration closes an existing prose/registry gap. Each has a specific grammar/lowering test rather than a broad new semantic mechanism.

### 83.5 Why “familiar” is not a completed empirical result

Official TypeScript documentation identifies common programming mechanisms; it is not a population-frequency study. No participant study or AI productivity benchmark was performed here. Adoption should be measured with API data, collection pipelines, callbacks, modules, errors, full applications, and proof-repair tasks—not only preferences about punctuation.

## 84. Programming-language theory used in the design

Harper's *Practical Foundations for Programming Languages* supplies the methodological separation of abstract syntax, static judgments, dynamics, and type-safety arguments. This reference applies that discipline by separating parsing, elaboration, logical checking, and runtime preservation; it does not borrow a small example calculus as a substitute for Lean. [P1]

Krishnamurthi's *Programming Languages: Application and Interpretation* distinguishes surface syntax from a smaller core and examines desugaring and lexical binding. That motivates separate ASTs, structural recursive lowering, and explicit hygiene/evaluation obligations rather than text replacement. [P2]

*Software Foundations* illustrates preservation/progress and Hoare-style reasoning in precisely specified example languages. The corresponding PSC obligations must be proved for PSC's actual relations. Partial correctness is not termination, and source type safety is not correctness of a foreign runtime. [P3]

These are selected chapter-level studies and methodological precedents—not a claim of reading every edition of every language-design book or transferring their proofs automatically. Go's engineering history adds a practical constraint: language, tools, dependencies, and maintainability should be designed together. [G1]

## 85. Executed evidence and its limitations

The authorized Windows environment had an existing Lean v4.34.0 toolchain. Its version output identified the exact semantic commit used by this reference. No compiler installation or global toolchain change was required.

The original research executed (retained historical evidence, not rerun by this revision):

- One canonical example file with record updates, Option matching, curried/tuple/Unit calls, dependent data, named/default arguments, braced do/loops, and 14 small theorems: **accepted**.
- One native intrinsic contract example: **accepted**, with an upstream experimental warning and a generated `.spec` theorem.
- Six negative canonical cases—false proof, invalid dependent update, numeric truthiness, tuple/arity mismatch, repeated native `ensures`, and false contract: **all rejected as expected**.
- A further assumption inspection of the intrinsic theorem reported `propext`, `Classical.choice`, and `Quot.sound`; those assumptions are not hidden or described as an assumption-free proof.

These are native Lean oracle checks of hand-authored canonical examples. They do not test a production ProofScript parser, execute a v0.9 lowerer, prove the overlay sound, or establish JS/Rust/Wasm equivalence. Positive syntax examples in this document remain candidate conformance inputs unless the accompanying record explicitly says what was executed.

The original evidence description is in [STUDY_AUDIT.md](research/STUDY_AUDIT.md), with authored source files and machine-readable observed results. The r2 native-separator checks have their own [audit](research/SEMICOLON_REVISION_AUDIT.md), exact source hashes and outcomes; they do not promote these original checks into new PSC frontend evidence. Documentation validation checks links, section/registry consistency, JSON, and case IDs; it is not a semantic checker.

## 86. Formal obligations before stronger claims

The first formal targets should be explicit and compositional:

| Obligation | Intended result |
|---|---|
| Ownership determinism | An accepted owned node has one declared category/feature interpretation. |
| Protected-neighbor preservation | A nonmatching decoration does not displace the selected native parse. |
| Syntax lowering well-formedness | Owned syntax lowers to an appropriate native syntax category. |
| Binding/hygiene preservation | Lowering preserves user references and introduces no accidental capture. |
| Environment correspondence | Imports/options/registrations and declarations relate to the intended environment. |
| Source theorem correspondence | The checked proposition is the one requested by the source/specification. |
| Standalone refinement | The owned implementation agrees with the defined reference on its claimed domain. |
| Erasure preservation | Removing irrelevant content preserves retained computation. |
| Target preservation | Runtime/target programs relate under stated representation/effect/resource models. |
| Artifact binding | Checked evidence covers the exact emitted and linked bytes consumed. |

Type-theoretic faithfulness is a design constraint and a proof target; it is not established simply by writing the equation defining intended meaning. The S1 reference becomes stronger only when these obligations are discharged for a stated scope.

## 87. Practical implementation order

Start with the registry, exact grammar/source/profile identities, lexer trivia, D-CALL, aliases, explicit headers, and native declaration/sequence boundaries. Implement braced if/data/match/where forms with separate category tests. Make native braced do a supported inherited capability, not a duplicate effect language.

Then implement the named/trailing-comma conveniences and explicit instance-body rule with native-oracle comparisons. Extend native coverage by coherent families: patterns/data, inference/typeclasses, recursion, modules, prover support, and explicitly selected intrinsic verification. Preserve failure and transactional boundaries throughout.

Keep one useful executable route stable while the language reference matures. UI and optional backend work should not destabilize the current compiler/kernel bootstrap. Full applications require libraries, interoperation, and tooling in addition to parser support.

For certification, prove a small complete path first: a useful source function and specification, correct lowering/erasure, a target implementation, and exact-file binding. Expand compositional coverage rather than claiming a universal compiler theorem from a fixed point or a large number of passing examples.

## 88. Reference register

All repository references below use base commit `65369c75c7b63124f1ba7f2289e573181db281f0` unless another exact commit is stated. External live pages are explanatory sources, not version pins. The source hashes and research classification belong in the audit/manifests.

### Repository and source lineage

- **[R1] ProofScript v0.7.0.** [Authoritative draft](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md), [feature registry](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.7.0/appendices/A-complete-feature-registry.md), and conformance corpus. Main-reference blob `8b4097363c5ade7d594b66706b94dff62400ff53`.
- **[R2] ProofScript v0.6.1.** [Historical reference package](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/proofscript-language-reference-v0.6.1). Earlier semantic pin and compiler-facing contracts; not the v0.9 semantic authority.
- **[R3] Lean reference mirror.** [Repository collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference). Full text inventory includes reference chapters, APIs, diagnostics, and historical release pages.
- **[R4] Lean4Lean.** [Divergence notes](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4lean-master/divergences.md). Useful independent-checker research, not automatic exact acceptance equivalence.
- **[R5] TypeScript mirror.** [Repository collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/www.typescriptlang.org). Workflow/API/type-system study; not a new PSC type theory.
- **[R6] Study tree.** [Pinned collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study). Tree identity `d7cb9ece9bda552b960ba488fca0895c6ee92278`.

### Pinned Lean implementation and native semantics

- **[L1] Native term parser.** [Term.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Term.lean). Application, named arguments, records, functions, matches, and suffix categories.
- **[L2] Native do parser.** [Do.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Do.lean). Blob `611c62724a004dc4a635549275cc7ab23f40931c`; braced and layout do sequences.
- **[L3] Native declarations/contracts.** [Command.lean](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Lean/Parser/Command.lean), blob `0b4083ac78f7a04ae6f6f29cb02c529ff76ed9e8`, and [intrinsic verification tests](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/tests/elab/intrinsicVerification.lean).
- **[L4] Function application.** [Mirrored native account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Function-Application/index.html). Whole-application elaboration, implicit/default/named parameters, generalized field notation.
- **[L5] Recursion.** [Mirrored recursive-definition account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Recursive-Definitions/index.html). Total, partial, unsafe, and logical/runtime distinctions.
- **[L6] Scalar sources.** [Pinned Init/Data](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-4.34.0/src/Init/Data). Exact selected primitive declarations and operation definitions.
- **[L7] Macro hygiene.** [Mirrored macro account](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Macros/index.html). Categories, scopes, pre-resolved names, and capture.

### Programming and theorem-development books in the study folder

- **[B1] How To Prove It with Lean.** [HTML collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/HTPIwL). Proof pedagogy and feedback. Its imported teaching tactics must not be misreported as default Lean syntax.
- **[B2] Functional Programming in Lean.** [Collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/functional_programming_in_lean), especially `Monad-Transformers/Ordering-Monad-Transformers/index.html`. Effects, data, dependent programming, and runtime considerations.
- **[B3] Theorem Proving in Lean 4.** [Collection](https://github.com/dwijayuda/pskernel/tree/65369c75c7b63124f1ba7f2289e573181db281f0/study/theorem_proving_in_lean4), especially `Axioms-and-Computation/index.html`. Logical foundations, proof development, classical assumptions, and executable meaning.

### TypeScript language design and use

- **[T1] Functions and inference.** [Official functions documentation](https://www.typescriptlang.org/docs/handbook/2/functions.html); also the pinned mirror. Contextual callbacks, generics, optional/rest parameters, and overloads.
- **[T2] Type compatibility.** [Official compatibility documentation](https://www.typescriptlang.org/docs/handbook/type-compatibility.html). Structural typing and deliberate soundness tradeoffs.
- **[T3] Narrowing and data.** [Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) and [object types](https://www.typescriptlang.org/docs/handbook/2/objects.html). Motivation for inspectable refinement and practical data APIs.
- **[T4] Generic/type-level APIs.** [Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html) and the mirror's mapped/conditional/template-type chapters. Interoperability requirements, not a proposal to duplicate TypeScript's type checker in the kernel.

### Language theory and compiler methodology

- **[P1] Robert Harper, Practical Foundations for Programming Languages, second edition.** [Author page](https://www.cs.cmu.edu/~rwh/pfpl/) and [abbreviated online edition](https://www.cs.cmu.edu/~rwh/pfpl/abbrev.pdf). Selected syntax, static/dynamic semantics, and type-safety material; not a full-book audit.
- **[P2] Shriram Krishnamurthi, Programming Languages: Application and Interpretation.** [Desugaring](https://cs.brown.edu/courses/cs173/2012/book/first-desugar.html), [desugaring as a language feature](https://cs.brown.edu/courses/cs173/2012/book/Desugaring_as_a_Language_Feature.html), and [substitution/environments](https://cs.brown.edu/courses/cs173/2012/book/From_Substitution_to_Environments.html). Selected chapters from the 2012 online edition.
- **[P3] Software Foundations, Programming Language Foundations.** [Types](https://softwarefoundations.cis.upenn.edu/plf-current/Types.html) and [Hoare logic](https://softwarefoundations.cis.upenn.edu/plf-current/Hoare.html). Precise example-language proof obligations and partial-correctness reasoning.
- **[P4] CompCert.** [Compiler overview and correctness](https://compcert.org/man/manual001.html). Scope of behavioral preservation and external boundaries.
- **[G1] Rob Pike, Go at Google: Language Design in the Service of Software Engineering.** [Original design account](https://go.dev/talks/2012/splash.article). Build/tooling/dependency and maintenance discipline.

## 89. Final design commitment

ProofScript v0.9 should be understandable as **Lean with a carefully specified, modest TypeScript-friendly surface**, supported by excellent libraries, tools, and explicit assurance. It should not grow a competing logical type system merely to resemble familiar punctuation.

The practical promise is precise: accepted decorations have declared categories and canonical Lean meanings; unsupported features fail explicitly; proofs are independently checked; executable guarantees identify their compiler/runtime assumptions. Stronger claims require stronger evidence.

This reference is a substantial compiler contract and a proposed design baseline. It is not a substitute for implementing the parser, proving its lowering, measuring adoption, or establishing complete compiler preservation.