# Character-literal diagnostic correction

This slice repairs source locations in the existing lexer, after R1 lossless
capture exposed a malformed-character offset inside a UTF-8 scalar.

## Cause and change

The unescaped-character branch inspects a body scalar and a following scalar
that should be the closing apostrophe. On refusal, it previously advanced the
following scalar directly from the position after the opening apostrophe.
It skipped the body scalar's byte width and line/column effects.

The correction uses the existing cursor helper to advance **body, then following
scalar**. It changes one production expression in Lexer.lean. For apostrophe,
U+1F600 and U+03B1, the diagnostic stop changes from byte 3 (inside the emoji) to
byte 7 (the actual consumed prefix end). CR/LF, tab and prefixed-source locations
use the same existing cursor conventions. Invalid literals remain invalid.

No accepted-token construction, escape/hex handling, parser, elaborator, Core,
IR validation, checker, backend or resource-policy implementation is rewritten.

## Scoped formal evidence

CharacterDiagnosticTests.lean retains the qualified PR #182 character-reader leaf
verbatim under a reference name. A Git guard checks those exact bytes against
commit 4c977654b8ca39b5fb3568ca9ebea03eee9d4339.

Two ordinary Lean 4.35 kernel checked theorems establish:

- For every input list and cursor/accumulator state, accepted results retain all
  token/cursor/spelling fields, and refusals retain their constructor/reason when
  diagnostic spans are erased.
- In the corrected malformed unescaped branch, the returned stop position is the
  existing cursor's advancement over the actual two-scalar prefix, in order.

These are character-reader leaf properties. They are not a formal proof of
whole-compiler preservation, frontend completeness or generated-code correctness.
No additional axiom, sorry, unsafe implementation, native_decide shortcut or
checking-budget increase is introduced.

The immutable-reference guard and theorem build run in the selected development
lossless job. The stricter milestone guard additionally proves that this is the
only production expression changed, that all other 120 unified-module byte
identities are preserved, and that frozen package/resource inputs are unchanged.
Future intentional language changes must review the relevant scoped contract
rather than silently rewriting its immutable reference.

## Runtime and transport evidence

664 position cases cover both lexers, all UTF-8 scalar-width classes, malformed
and valid literals, escapes/hex failures, CR/LF, tabs, leading BOM and source
prefixes. The complete lossless corpus also reconstructs every compiler source
module under both lexers and exercises snapshot/edit refusal boundaries.

The snapshot API retains compatibility with a host-pinned older helper that
reports advisory coordinates inside a scalar. Such diagnostics remain marked
unverified and can never become token/trivia/edit spans. The corrected native
helper reports verified coordinates for the diagnosed input. Neither path grants
semantic-equivalence, admission, filesystem-editing or publication authority.

## Source identity and qualification boundary

The corrected 121-module unified source closure is
60dd756e29cf6fbd44386e342318c53b22f41f2f3beb21b05aa39505a366271a.
The prior R1 source keeps its own qualified digest
7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000.

[The dated qualification receipt](PSC1_CHARACTER_DIAGNOSTIC_QUALIFICATION_2026-10-25.json)
records implementation d70221c9 and its exact tested tree. Focused Linux run
40195964028 passes the two theorem builds, 664 position cases, 359 helper captures,
49 refusal cases and positive older advisory-wire compatibility. Maximum helper
wall time is 360ms; peak RSS is 159,684 KiB.

Genuine new-source Wasm G1 run 40196021448 passes both grammar censuses on all
121 modules, 40 cross-target cases and nine envelope refusals. The native seed
executables are removed before the generated corpus stage. Ordinary source run
40196244138 passes every selected dependency and 37/37 finite Practical Core criteria, zero blocked (releaseReady=true). This is finite-contract source qualification, not a
proof of whole-compiler preservation or universal distribution readiness. The frozen 120-module npm compiler and all four existing G2/G3/fixed
points retain their original identities. No new G2/G3 or npm promotion is claimed.

R2 still needs resolved declaration/binder identities, capture-avoiding edits,
affected-closure elaboration, independent admission and explicit API/identity
correspondence. This correction completes a location prerequisite; it is not a
semantic rename implementation.
