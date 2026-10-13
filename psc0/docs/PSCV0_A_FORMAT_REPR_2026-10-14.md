# Faithful Std.Format and Repr design

Current pin: Lean 4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
This design continues existing M2+A, not a new milestone sequence.

## Source and regression study

Studied Init/Data/Format/Basic.lean, Init/Data/Format/Instances.lean,
Init/Data/Repr.lean and Lean/Elab/Deriving/Repr.lean at the pin.
Relevant upstream tests: tests/elab/Format.lean (fill and oversized groups),
formatHardLineBreaks.lean (hard newlines and re-flattening), derivingRepr.lean
(structures, proofs/types, recursive/indexed cases) and charQuote.lean.

These files are unchanged in the complete RC4-to-stable comparison.
Upstream sources are Apache-2.0; retain attribution and license for adaptations.

## Architectural choice

Retain the actual Std.Format inductive and FlattenBehavior enumeration.
Public Repr.reprPrec returns a document, never an ersatz String. Use ordinary
checked Core definitions, the existing typed IR, algebraic data and closures.
The portable closure must not import Lean's elaborator, formatter or compiler.

Follow the upstream Wadler-style two-stage algorithm: spaceUptoLine measures
documents with flattening and indentation context; pretty processes work groups
with allOrNone/fill behavior and flatten-allowed state. Preserve hard lines,
forced alignment, signed nesting, Unicode scalar column counts, group remainder
fitting and precedence. Tags do not alter pure pretty output; effectful
MonadPrettyFormat callbacks are a separate API, not silently discarded there.

A total implementation may replace upstream private partial worklists with an
input-derived bound. Use the invariant: remaining weight equals two per Format
node, plus each text's remaining UTF-8 bytes, plus one per work group. Each
render transition strictly decreases this weight: a newly pushed group costs one
while consuming a two-weight group node; text splitting consumes at least one
byte; an empty-group transition consumes one group. Initialize with the exact
document weight plus the initial group. No fixed limit or truncated user output.
This algorithm/invariant needs validation; it is not a formal proof claim.

Keep the document fold, layout measurement, worklist renderer and Repr handlers
separate. Use existing Core binder/recursor builders where suitable; a small
static telescope helper may remove repeated declaration-construction details,
but must not become a second parser/elaborator or alter source semantics.

## Handler semantics

Use shared parameter/universe telescopes, class lookup and eliminator generation.
Repr's structure field labels/default indentation and constructor qualification,
explicit argument filtering, application precedence, proof/type placeholders and
quoting follow the pinned handler. Scalar and selected collection instances need
faithful documents/formatting too. Format.joinSep is polymorphic through ToFormat;
do not replace it with a monomorphic List Format API.

Keep recursive/indexed deriving and computational dependent fields with M3+B's
shared data/termination mechanisms, as already assigned. The current M2 scope is
independent nonrecursive families; no claims for the deferred upstream cases.

## Validation boundary

Use a compact shared document/deriving batch against native Lean, including
upstream hard-line and fill counterexamples, negative nesting, Unicode, narrow
width and application parentheses. Then use existing kernel/strict IR and
JS/TS/Rust/GC-Wasm integration gates. Do not add backend-specific format printers,
weaken unknown-type checks or use formatting axioms to obtain green output.

Current status: pure Format is implemented and qualified below; ToFormat/Repr
and the effectful callback API remain pending.

## Pure layout implementation

StandardFormatData/Basic own the real algebra and document operations;
Support owns scalar scanning and Core construction vocabulary; Measure and Work
own fitting; Render owns pure transitions and the input-weight-bounded driver.
StandardFormat integrates this closure with normal kernel admission and typed
runtime erasure. No backend formatter, new axiom or runtime primitive is added.
The static data helper allocates constructor fields beyond every minor's binder
IDs and is limited to closed nonindexed Type-0 declarations.

Eleven shared observations cover upstream hard-line/fill regressions, scalar
column widths, negative nesting, alignment/forced alignment, initial column,
and empty-versus-nil. The independent native oracle checks the same expected
values. Profile /55 identifies this expansion. Signature/status/digest review
and full cross-target qualification are pending. Repr, ToFormat, polymorphic
joinSep and effectful prettyM are not implemented by this foundation.

## Reviewed snapshot

Linux [38442009692](https://github.com/dwijayuda/pskernel/actions/runs/38442009692)
at `32aab6ae2be26d101449489c4a0a14ea011ab686` compiled all 198 portable /
206 native modules, including the independent native formatting oracle, and
passed primitive signature/reducibility audits. The strict registry gate then
reported the expected 79-declaration expansion: no new axiom, primitive, class,
instance or alias. Expected roster: 394 declarations /18 classes /54 instances.
Reviewed FNV `fnv1a64:17804548636281664114`; SHA-256
`sha256:ec394b9e9c70bf92cb829060fcfee1e36aaf38f1f5e92b198a646c553ff259b1`.
Full kernel/IR/runtime qualification follows; it is not established by compilation.

## Constructor field identity correction

At `f8832f0` / Linux 38442244676, native source/oracle, all semantic
and official-kernel checks, selected snapshot (394/18/54), typed IR and project
emission passed. WAT round-trip parsing exposed a pre-existing target naming
error: a compiler discriminator called `tag` collided with Format.tag's payload.

Before changing the layout, studied pinned Lean
[NameMangling](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/NameMangling.lean),
[EmitC](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/LCNF/EmitC.lean)
and [mangling tests](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/mangling.lean).
Lean separates runtime constructor tags from source-name mangling; it has no
corresponding WAT emitter. The WebAssembly
[text type rules](https://webassembly.github.io/spec/core/text/types.html#composite-types)
require a well-formed local field identifier context.

PSC0 now allocates the backend discriminator once per family against every
constructor's payload names using the existing fresh-name allocator. The base
and every subtype retain the same allocated spelling; field indices and physical
layout are unchanged. The target validator rejects duplicate names in every
structure before rendering. WAT and binary debug metadata consume the same
layout field table. No Format-specific field rename or printer exception.

The sibling-backend review found ECMAScript discriminator keys use fresh Symbols
(rather than source string field keys), while Rust uses native enum variants;
neither shares this WAT field-name collision. One existing Wasm qualification
batch now also requires early refusal of a duplicate target field table.

## Qualification complete

Executable `49324765c1dc4e1c601dc0cded6118822c1922bc`;
[green Linux 38442705296](https://github.com/dwijayuda/pskernel/actions/runs/38442705296).
**313 shared runtime observations**, four panic contracts, **198 portable /
206 native modules**, profile `pscv0-v7-native-bounded/55`.
Official **Lean 4.35.0** at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`;
independent oracle, official kernel, semantic/refusal and graph gates, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, project and existing performance
gates passed. These measurements do not establish performance parity.

Standard: **394 declarations /18 classes /54 instances**, canonical v2:
FNV `fnv1a64:17804548636281664114`;
SHA `sha256:ec394b9e9c70bf92cb829060fcfee1e36aaf38f1f5e92b198a646c553ff259b1`.
The pure Std.Format algebra, measurement and renderer are ordinary checked
definitions over the shared IR, including hard-line/fill behavior, Unicode
columns, signed nesting, alignment and initial column. No formatting axiom,
backend formatter or new runtime primitive. WAT constructor discriminator names
are allocated separately from payload fields; physical indices are unchanged.

Quoting and checked Int.toNat remain qualified. Quoting comparisons use native
evaluation because upstream String.Internal.append is kernel-opaque; they are
not kernel equality proofs. Int runtime conversion preserves arbitrary precision.
Historical RC4 receipts retain their original identities.

Full M2+A is **not complete**. Next: ToFormat/Repr and remaining A/M2.

The weight argument justifies termination for public pretty's derived bound;
it is not a formally checked termination or renderer-equivalence theorem.
Repr-specific source study additionally includes pinned Init/Data/Int/Repr.lean
(negative integer parentheses), tests/elab/repr.lean (tuples/atomic lists),
repr_empty.lean (Empty as a parameter) and repr_issue.lean (opaque Id wrappers).
Keep those requirements distinct from this qualified pure Format boundary.

The additional early-refusal case and full existing integration suite also pass
at `a2bcf0375c5f9acfa0d50847d44253657d5cd3cd`,
[Linux 38443246672](https://github.com/dwijayuda/pskernel/actions/runs/38443246672).
This is the newest qualified source/test boundary; 313 shared observations,
394/18/54 Standard roster and both digests are unchanged.

## ToFormat/Repr implementation phase (qualification pending)

Reference: official Lean **4.35.0**, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Studied [Format Basic](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Format/Basic.lean),
[Format Instances](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Format/Instances.lean),
[Repr](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Repr.lean),
[Int Repr](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Int/Repr.lean),
[deriving Repr](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Deriving/Repr.lean),
Init/Notation.lean (`max_prec = 1024`), Init/Prelude.lean and
Init/Data/List/Basic.lean. Relevant tests: derivingRepr, repr, repr_empty,
repr_issue, Format, formatHardLineBreaks and charQuote.

The old Type-0 List declaration cannot implement the actual universe-polymorphic
joinSep API. Replace its handwritten telescope with the same explicit-local
builder used for Option; List.rec has levels [resultSort, elementUniverse].
Promote the selected List operations, including independent map/fold input and
output universes. Ground collection adapters explicitly instantiate zero.
Proof-bearing List indexing and the Array/Prod model remain selected Type-0
APIs and are not claimed to be promoted by this phase.

Formatting dictionaries are ordinary one-field structures. Std.ToFormat's
ToString fallback has priority 100; identity/structural instances have 1000.
Join combinators reuse the shared checked List.foldl; no duplicate traversal
or backend formatter is introduced. ReprAtom is an empty ordinary class and
selects the later atomic-list instance at the same priority as Lean.

Deriving plans each field printer once in the parameter context. Structures use
projections and field labels; constructors print qualified names and explicit
fields only. Proof/type values print underscores; constructor arguments use
precedence 1024, including nullary constructors in application contexts.
Formatting is a checked Format term, never a string-generation shortcut.
Dependent runtime field types, recursive and indexed families stay with M3+B.
Generated declarations retain the existing source-command origin machinery.

Qualification: 17 compact observations, independently checked by native Lean,
are added to the existing shared backend table. Repr missing-dictionary and
recursive refusal cases extend the existing boundary group. Both Standard
digest guards remain strict pending explicit review of the new roster.
Remaining selected formatting APIs/instances, Hashable/numeric dependencies,
broader M2 evidence and the Phase A manifest remain open; this is not M2+A
completion.

The first kernel pass found one old alias constructor that copied List.get?'s
type while discarding its universe parameters. Replace that pattern with
psDeclarationAlias: target identity, universe telescope and type travel together.
The sibling copied-type registrations were reviewed; they already retain their
levels. List.get?Internal now shares the actual polymorphic target.

The same phase also supplies String.toFormat soft-line conversion, Format
append/coercion/default instances, tuple flattening through ReprTuple, Array
fill rendering, Fin display and the explicit Id instance. String conversion
uses one byte-bounded UTF-8 cursor pass and no intermediate split list. Tuple
formatting accumulates a reversed document list and reverses once, as upstream.
Array Repr always uses bracketFill, independently of ReprAtom.
Eight additional shared observations extend the same small native oracle group.
No new runtime primitive. Prod/Array retain their explicit selected Type-0
boundary. Kernel/runtime qualification is still pending.

Kernel admission now accepts the promoted prelude. Executable qualification
then exposed a second part of the alias contract: a bare polymorphic constant
has no raw lambda entry prefix in the portable IR. After studying pinned
Lean/Compiler/LCNF/ToLCNF.lean (etaExpandN, etaIfUnderApplied, visitLambda,
mkOverApplication), tests/compile/arity_bug1.lean, tests/elab/eta_lambda_lift.lean
and compiler_reduce_arity_fully.lean, psDeclarationAlias now builds precisely
the target's existing raw lambda prefix around the reference. It does not copy
the implementation or expand a computed function result. The ordinary kernel
checks the resulting alias, and the established erasure entry/calling convention
remains shared across all backends. This preserves the earlier M0 evaluation
boundary rather than introducing an alias-specific backend path.

## Shared public methods and default completion

The same checked bodies now own public Bool.repr, Nat.repr, Option.repr,
List.repr and List.repr' plus their dictionaries. Decidable.repr examines the
checked computational Bool; reflection proofs remain erased. This adds seven
declarations and one instance to the pending display roster, without an axiom
or primitive. Char.repr already existed and is retained.

A nested generic call exposed an M2 application invariant: an unconstrained
expected metavariable must not preserve an omitted optParam as a function value.
Study: stable Lean src/Lean/Elab/App.lean processExplicitArg/finalize and
 tests/elab/optParam.lean, floatOptParam.lean, defaultValueParamIssue.lean.
The shared application engine now fills such defaults before assigning the
unknown expected type. PSCV0's previously qualified explicit expected-function
partial applications remain intact. displayIdentity exercises this through the
independent Lean oracle and every runtime target. Diagnostics distinguish
instance failure and resource exhaustion instead of reporting a generic failure.
Three additional existing-batch observations cover positive/negative decision
representations and direct public numeric representation. Qualification pending.

Reviewed stable public-method extension, Linux 38449538089: the native build,
independent oracle and signature/reducibility audit passed. The strict digest
guard intentionally refused the seven added declarations (five shared public
methods plus Decidable method/instance), one added instance and changed printer
references. New FNV fnv1a64:2066895107454337978; SHA-256
sha256:94a92697fa582ab59fd6b0e466a4dd68b8386f2503af16d703d5603f7b07644b.
Both guards remain strict. Runtime qualification still pending.

Id display revealed its missing upstream numeral dictionary, not a Repr or
unification defect. Stable Init/Control/Id.lean explicitly declares
[OfNat α n] : OfNat (Id α) n because Id is not instance-transparent. The
portable Numeric module now reproduces that universe-aware checked dictionary
and records its level parameters in the instance index. General instance
transparency remains unchanged. The existing Id observation covers the path;
no duplicate fixture or special-case literal rewrite is added.

Reviewed Id dictionary delta (one declaration/instance only), Linux38450100204:
FNV fnv1a64:10063720084149863531; SHA-256
sha256:eef203f0a5b182e3cc21330d1d39e670013e48b9aab48b6485f8d9eb89bafce5.
Native build and oracle pass. Strict guard values updated to this exact roster;
341 shared runtime observations and four panic contracts await qualification.

## Universe and empty-marker representation closure

Stable Init/Prelude.lean and Init/Data/List/Basic.lean define Inhabited List
without an element dictionary and BEq/List.beq at the element universe.
The remaining ground-only dictionaries now carry that universe, including the
function-valued outer recursor result sort. Public List.beq and the dictionary
share one body; the private duplicate worker name is removed. One existing
kernel conformance group and its pinned Lean oracle cover arbitrary universes
and the Type-valued empty-list default. Selected Array remains Type-0.

Linux 38450541085 passed every native semantic/module/deriving/search gate,
then strict IR rejected a reference to an omitted ReprAtom dictionary. This
was a mismatch between definition filtering and ordinary binder representation:
a vacuous all-fields-erased predicate discarded zero-field Type-valued classes,
while applications correctly retained their singleton values. Studied pinned
Lean/Compiler/LCNF/ToLCNF.lean visit/visitAppArg/visitCtor: proofs and type formers
are erased; ordinary constructors remain data. Restrict specialized dictionary
filtering to classes with actual erased fields. Empty classes now use the
existing shared empty-structure representation at definitions and uses.
No Repr-specific erasure/backend exception; existing atomic-list observations
exercise the invariant on all targets. Runtime qualification remains pending.

Reviewed List-universe delta after the native build/oracle in Linux38451439577:
List Inhabited/BEq now bind the element universe; the former private comparison
worker is the public List.beq with its pinned reducibility. Roster counts remain
460/22/88. FNV fnv1a64:2548399426123262483; SHA-256
sha256:79e34c4fd2bb8e491d624c86ccb644bf96b2442e090137d01b3c74ca72bfaeaf.
Both strict digest guards are updated to the reviewed semantics, not bypassed.

## Next dependency: checked scalar library reuse

Hashable's UInt64 API requires modular arithmetic and a genuine bounded-value
logical model. Pinned Prelude.lean, UInt/Basic.lean, UInt/BasicAux.lean,
BitVec/Basic.lean, Nat/Div/Basic.lean, runtime/hash.h, runtime/hash.cpp and
runtime/object.cpp were reviewed. The portable Nat.mod axiom supports closed
kernel literal reduction but cannot justify the general Nat.mod_lt theorem.
Do not fake that theorem or replace UInt64's public type with Nat.

Before choosing manual proof adaptation versus importing a small checked Core
closure, a native-only authoring audit measures the upstream dependencies of
Nat.mod_lt, BitVec.ofNat, UInt64.ofNat/xor, mixHash, String.hash and Float's
scientific conversion. Source references: pinned Lean/Declaration.lean and
Lean/Util/CollectAxioms.lean (visited-before-descent, type plus proof/body
traversal); this audit also follows mutual families and recursor rules. It
reports name collisions with the selected portable environment as boundaries
requiring review, not as compatible imports. It admits no declarations and is
not a conformance test or an implementation of the missing scalar operations.
The native audit is outside the portable dependency graph; no host elaborator
enters the eventual portable/self-host closure.

## Full display qualification — ToFormat/Repr (14 October 2026)

Executable `e565bbe6bab75baf4fa511640e1f82744f400032`;
[green Linux 38451656694](https://github.com/dwijayuda/pskernel/actions/runs/38451656694).
**341 shared runtime observations**, four panic contracts, **204 portable /
212 native modules**, profile `pscv0-v7-native-bounded/56`.
Official **Lean 4.35.0**, independent oracle, semantic/refusal/search checks,
strict IR, JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI, projects and
existing performance gates pass. Performance parity is not established.

Standard: **460 declarations /22 classes /88 instances**.
FNV `fnv1a64:2548399426123262483`;
SHA `sha256:79e34c4fd2bb8e491d624c86ccb644bf96b2442e090137d01b3c74ca72bfaeaf`.

Genuine ToFormat/Repr/ReprAtom/ReprTuple classes, checked scalar/collection
display methods, selected nonrecursive Repr deriving, precedence, quoting,
proof/type placeholders, UTF-8 soft lines, tuple flattening and fill layouts
are qualified. List and selected APIs/defaults/BEq retain element universes;
map/folds retain independent result universes. Array/Prod and proof-taking
List indexing retain their documented Type-0 boundary.

Shared fixes preserve aliases' actual raw lambda entry prefixes, complete
omitted defaults under unknown expected types, and retain empty Type-valued
class dictionaries as runtime singletons. Explicit OfNat Id follows upstream;
no broader instance transparency or special literal rewrite was introduced.

[Design, sources and qualification](PSCV0_A_FORMAT_REPR_2026-10-14.md).
**Full M2+A remains incomplete.** Continue Hashable/scalar dependencies,
remaining selected Standard APIs, comprehensive manifest, broader M2 evidence
and C5 semantic retention. Recursive/indexed/dependent deriving remains M3+B.

The next commit adds only a host-side dependency audit; its new native module
has not yet been qualified at this receipt. Portable sources are unchanged.

Pinned-source closure audit qualified in green Linux38452305890 at
41773101289525e4b1e5c062cb0c6721323740b7 (204 portable/213 native modules;
all 341 existing observations remain green). Counts: Nat.mod_lt 211,
BitVec.ofNat 249, UInt64.ofNat 252, UInt64.xor 550, mixHash 156,
String.hash 337, Float 739 and Float.ofScientific 2288. The first three
closures contain no axioms; UInt64.xor/Float include propext/Quot.sound and
scientific conversion additionally includes Classical.choice. This argues
against a blanket full scalar-library import. Source tests studied include
collectAxioms.lean and the native ofScientific bit-pattern harness (including
subnormal double-rounding vectors); decimal text equality is insufficient.

Next authoring experiment: cut Nat.mod_lt's native dependency graph at existing
portable names and submit its remaining genuine upstream declarations to a
fresh officially checked portable prelude. Regenerate inductive constructors/
recursors through the kernel; reject new axioms, quotient primitives, unsafe and
partial declarations. Record exact rejected declarations and blocked dependents.
The experiment discards its environment; no imports or failures enter production
compilation. Its purpose is to identify which old logical models must change
coherently before exporting a small reviewed closure, rather than assuming
shared names imply compatible semantics.
