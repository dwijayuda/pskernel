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

Status: design recorded; Format/Repr source implementation remains pending.
