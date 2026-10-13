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
