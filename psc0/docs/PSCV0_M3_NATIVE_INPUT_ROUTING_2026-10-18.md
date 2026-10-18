# M3+B native v7.2 input ownership

Status: implemented candidate, GitHub Linux qualification pending. This closes
routing architecture, not all native syntax or M3+B acceptance.

## Pinned reference study

Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
- src/Lean/Elab/Frontend.lean: parser state and command elaboration state remain
  separate; parsing supplies scoped source commands to one elaborator.
- src/Lean/Parser/Module.lean:119-179, topLevelCommandParserFn and parseCommand:
  native source positions and command ownership matter; arbitrary Lean parsing
  also depends on extensible environments, which is outside portable v7.2.
- src/Lean/Parser/Command.lean:114-162,188-205,333-383,516,899-904:
  modifiers, binders, namespace/section/open, declaration bodies and mutual/end.
- src/Lean/Parser/Term.lean:615-713: strategy suffixes belong to declarations;
  proof-producing construction is a separate elaboration responsibility.
- tests/elab/variable.lean, defaultValueParamIssue.lean and the existing native
  section/default/mutual controls are semantic references. The new paired
  fixture includes independent native equations at exactly the project pin.

These are architectural adaptations to the smaller language, not copied host
implementation or host fallback. Apache-2.0 attribution remains in
THIRD_PARTY_NOTICES.md and licenses/LEAN-APACHE-2.0.txt.

## Design and invariants

PsCompilerSourceKind is explicit on Request and PsPscv0ModuleSource; sourceName
is provenance, not hidden semantic authority. Only the CLI maps .ps/.lean
suffixes to the enum. Project default source paths follow their actual kind.
Mixed source projects share dependency ordering, imported visibility and policy.

Ps.Syntax.Lean.Program reads native syntax into the same PsSyntaxProgram used by
ProofScript. Shared scope syntax takes a source-owned binder reader. Multi-name
native groups retain one annotation node until elaboration introduces all names.
Use native application/layout and native modifier/suffix ownership; never add
braces or run a .ps printer to approximate Lean.

The portable compiler validates Standard, resolves/elaborates, prepares and
checks the exact logical graph, applies execution/assurance rules, erases and
validates IR once. Backend choice cannot change input meaning. No assumptions,
budgets or approved foundation assets change.

## Candidate coverage and remaining work

This first native program slice routes scopes, native value headers/defaults,
private/noncomputable/abbrev/opaque/P0/P1 heads, measure-only total suffixes and
mutual ownership. Existing native term/data readers remain bounded. Native
class/instance/deriving commands, explicit universes, rich applications/operators,
tactic blocks, complete data grammar, local where/let-rec and decreasing_by
still require coherent adapters and paired qualification. Unsupported forms
remain errors. Legacy declaration-only translation is not the v7.2 compiler API.

The focused fixture compares actual checked definitions for .ps and .lean,
checks grouped shadowing, imports both source kinds across the same module graph,
uses the official kernel and emits JS/TS/Rust/Wasm core/component/WAT/WIT.
The existing runtime observer executes both outputs against native UInt64
equations for two Bool inputs on JS, compiled TS, Rust, V8 GC and Wasmtime.
Claim execution only after the corresponding steps pass.

The same audit corrects a Rust observer ordering bug: P1's generated harness was
overwritten by the noncomputable harness before Cargo ran. Generate/run must be
adjacent for every shared harness consumer. Earlier job success alone cannot
qualify that overwritten lane; current same-SHA integration must run it again.

Full mutual-WF source construction, exact body equations, validated typed
runtime adaptation, native syntax parity and same-SHA five-gate acceptance stay
in existing M3+B exits. No additional milestone or architecture track is created.


Preparation9223dd76/run39086928911 failed at the native authoring build because
`scoped` was used as a local name; it is a Lean keyword. The child renames those
locals and the analogous `syntax` local in the paired fixture. No parser rule,
semantic assertion, foundation or budget changes. Execution remains pending.

## Native term and binder-prefix correction — qualification pending

Preparation2f82244c/run39087221158/job117556210481 completed FAILURE. The native
compiler built; packing found a .ps fixture semicolon (the selected separator is
newline), and the new native control rejected the shadowing group {T value : T}.
The fixture also used unavailable Except.isError; the child uses !isOk.

This is a real semantic finding, not just a fixture repair. Pinned Lean
Elab/Binders.lean:136-168,208-235,423-456 expands names into binder views and
elaborates each annotation in the preceding names' context. PSC0's earlier
group-wide annotation cache incorrectly ignored shadowing. Shared Scope and
Binders now process names in order. Group-origin metadata preserves the existing
multi-name source receipt and actual ordered local IDs after scope expansion.
Old successful outputs keep their values using valid non-shadowing names; the
exact rejected shadowing forms remain explicit native/portable negative controls.
The canonical v7.2 ordered telescope rule is unchanged. Earlier bounded M2 job
success does not establish correctness of the contradicted binder interpretation.

The native program now uses an owned rich term reader, sharing v7 literals,
sort/universe nodes, operators, named-call AST, binder groups, projections/indexing
and tactic nodes. Native application checks actual whitespace and indentation
per Parser.Term.argument:885-897. Native conditional, match-row and tactic layout
remain grammar-owned. ProofScript keeps comma calls, braced blocks and newline
term separators. This is not conversion through .ps or a host compiler fallback.

Shared Core comparisons now cover grouped parameters, universe inference,
operators, named arguments and a scientific Float literal; actual native input
proofs reach the official kernel. Five target emissions and two mixed-module
directions remain in the existing paired fixture. Native data/class/instance/
deriving/where/do/full-termination syntax and complete mutual WF remain open.
No foundation, assumption, budget or runtime acceptance is relaxed. Do not
promote until complete preparation and exact-SHA integration qualify the child.

## Binder-view construction and complete prefix ownership — qualification pending

43a91de8 / run39088233267 / job117559220561 failed production compilation:
the new optional source-origin field is an explicit constructor argument in Lean.
Both constructor sites now supply it. No semantic qualification ran on that SHA.

Subsystem review also applies ordered annotation resolution to section-variable
groups, not just declaration/lambda binders. Selected section captures retain only
their selected origin names and IDs. Native tactic termination recognizes the
lexer's explicit EOF token, and native command separation permits EOF without a
final newline. These are shared syntax/scope invariants, not weakened assertions.
The exact native/portable shadowing rejections and prior positive observations
remain required. Main stays 037fda49; the new preparation child must qualify first.

## Native data and dictionary syntax — design and qualification plan

Pinned Lean4.35.0 sources studied before this slice:
Parser/Command.lean:188-242,270-311; Parser/Extra.lean:196-215;
Parser/Term/Basic.lean:39-92; tests/elab/instanceWhere.lean,
tests/elab/derivingRepr.lean, tests/elab/defaultInstanceWithPrio.lean.
All references use eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
The v7.2 data/class/instance/deriving selection remains authoritative.

Shared field-header construction accepts caller-owned term/binder readers.
Shared registration parsing accepts a caller-owned command reader. This removes
duplicate semantic lowering: structures, constructors, classes, priorities,
default-instance attributes, field lambda/ascription ordering and deriving
requests reach their existing checked owners. The .ps sequence wrappers keep
braces/comma headers/newline-only fields; native wrappers own indentation and
native instance semicolons/inferred field parameters. Native data declarations
stop using the older limited ParseLean data path.

The existing paired fixture gains one data/class/instance/BEq export with two
pinned-native observations per source kind, reused by the five backend observers.
No extra workflow, foundation axiom or runtime intrinsic is introduced.
Full native where/do/termination syntax and mutual WF remain separate open work.
Qualification is pending; source emission is not runtime observation.

## Native local definitions and termination proofs — qualification pending

Studied pinned Parser/Term.lean:594-746 (Termination.suffix and whereDecls),
Parser/Extra.lean:196-215, Elab/Binders.expandWhereDecls,
Elab/MutualDef.declValToTerm, Elab/LetRec (typed headers, remembered parameters
and lifting), and tests/elab/termination_by_where.lean. The upstream test has
axiom declarations for its illustrative decreasing functions; no such axiom or
proof authority is imported here.

Native Declarations owns the selected header/suffix/local-declaration grammar.
It constructs the same PsSyntaxTermination and PsSyntaxLocalDefinition nodes.
The native where list owns indentation and optional semicolons; .ps retains
local def heads/braces/newlines. Native decreasing_by reads a native tactic
sequence; .ps retains decreasing_by by { ... }. The common native tactic reader
is shared by by terms and decrease proofs. Existing scope/capture/dependency,
strategy selection, measure/decrease construction, equation and runtime owners
are unchanged. Nested where, explicit structural hints and unselected
monotonicity still refuse according to v7.2.

The existing two-source data export now traverses a local well-founded identity
helper with an explicit checked decrease proof. Its same native6/9 observations
remain the required five-backend oracle. No new executable fixture or workflow.
This is input adaptation, not completion of source mutual WF.
