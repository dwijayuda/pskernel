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
