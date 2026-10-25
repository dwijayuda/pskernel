# Lossless source capture (R1)

This is a lexical foundation for source refactoring. It retains exact UTF-8 bytes,
tokens and trivia without changing the existing lexer, parser, AST, elaborator,
checked IR, independent Lean admission or backend behavior. It does not certify
semantic equivalence and cannot publish edits.

## Components and ownership

- **Ps.Syntax.Lossless** calls the existing psLex or psLexProofScript, follows their
  token spans, and uses their existing comment and cursor helpers to recover gaps.
  There is no second tokenizer.
- **scripts/LosslessSourceMain.lean** serializes that tape through a closed JSON
  protocol. It is a native developer tool outside the unified compiler closure.
- **host-tools/source-refactoring.mjs** captures byte inputs into opaque snapshots.
  A trusted caller selects and pins the helper by absolute path and SHA-256.
  Source text never selects tools, policies, paths, checkers or plugins.
- **test/LosslessSourceTests.lean** compares the projection directly with the old
  lexers. **scripts/lossless-source-tests.mjs** exercises the real native helper,
  snapshots, staged edits, malformed transports and the authored compiler corpus.
- **.github/workflows/psc1-lossless-source.yml** runs the focused Linux checks.
  The ordinary development gate also requires them when selecting focused tests.

## Bytes, positions and trivia

All input is strict UTF-8. Invalid byte sequences are refused before decoding;
they are never replaced with U+FFFD. No newline, Unicode or BOM normalization
occurs. Each piece records an ordinal, kind, raw spelling, byte span and optional
original semantic token. Accepted tapes end with exactly one zero-width EOF token.
Whitespace, line comments and nested block comments remain separate pieces.

Positions retain the existing frontend convention: zero-based byte offsets,
one-based Unicode scalar columns, and line increments at LF. CR and tab each
advance a column; CRLF increments the line only at its LF. In .ps, a leading
BOM occupies bytes 0–3 while remaining column-neutral, as in the existing lexer.
The .lean lexer retains its own existing BOM token behavior. UTF-16 offsets
from an editor must be translated explicitly before creating byte edits.

A valid UTF-8 source with a lexical error is retained as one **unlexed** piece
with the original error. No partial token acceptance is invented. The status
"accepted" means only lexical acceptance; neither status runs a parser or checker.
Capture failures (including piece exhaustion) produce no snapshot.

The host checks the closed response shape, piece order, complete byte coverage,
raw slices, UTF-8 boundaries, position progression, EOF and exact token projection.
It reconstructs the tape and compares it with the original bytes before retention.

## Snapshot and candidate API

After building the native helper in Linux CI, a trusted host can use:

~~~js
const tool = createLosslessSourceTool({
  executable: absoluteHelperPath,
  sha256: expectedHelperSha256,
});
const snapshot = tool.capture({
  module: 'Example.Main',
  grammar: 'lean', // or 'ps'
  bytes: originalBytes,
  uri: 'editor:///Example/Main.lean', // optional provenance, never read
});
const identicalBytes = tool.reconstruct(snapshot);
const candidate = tool.stageTextEdits(snapshot, currentBytes, [
  { startByte: 10, endByte: 15, replacement: replacementBytes },
]);
~~~

The source ID hashes a domain-separated tuple of protocol, logical module,
grammar, fixed language/lexical profile and exact-byte SHA-256. A URI change does
not change identity. A byte, module or grammar change does. Piece IDs are stable
only within the exact snapshot; they are not AST nodes or resolved binder IDs.

Snapshot metadata is deeply frozen. Captured bytes live in a private WeakMap;
inputs and returned buffers are copied. Deserializing or copying the public object
does not create an edit capability, and another tool instance cannot consume it.

Staging requires exact equality between current bytes and the captured snapshot.
It refuses stale or foreign snapshots, malformed UTF-8 replacements, out-of-range
or split-code-point boundaries, unsorted or overlapping edits, and ambiguous edits
with the same start. Ranges are half-open and simultaneous in the old coordinates;
adjacent edits are allowed. Unaffected byte ranges are copied exactly.

Candidates explicitly record admission "not-run", semantic equivalence
"not-claimed" and publication authority false. The API performs no filesystem
editing, source resolution, independent checking, artifact emission or publication.
A caller that later writes files must separately handle races, complete the
relevant assurance gates and obtain publication authority.
This slice adds no installed npm CLI command or arbitrary extension interface.

## Resource envelope

The helper and host cap a source at 1 MiB, pieces at 262,144, a response at 32 MiB,
and edits at 4,096. The fixed helper envelope is distinct from unchanged compiler
and kernel policies. The existing Linux process-tree supervisor enforces its
240-second standard policy and bounded stdout/stderr, cleans descendants and
records wall time and sampled/wait4 peak RSS. Host configuration cannot enlarge
these limits through source input. Capture refuses unsupported host platforms;
only Linux development tooling is qualified here.

The helper has a 1 GiB address-space cap and an 8 MiB process-stack cap. Pinned
Lean runtime controls select the main process stack and disable the unused task
worker pool, avoiding the default large thread-stack reservations. The lexical
helper performs no parallel task operations. These settings affect only the new lexical helper.
The pinned runtime documents these controls in
[thread.cpp](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/runtime/thread.cpp)
and [object.cpp](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/runtime/object.cpp).

The ordinary lexer retains its existing fuel and errors. New traversal fuel is
derived from source bytes and a separate finite piece limit. No partial function,
unsafe implementation, unchecked proof or semantic fuel increase is introduced.

## Verification and next boundary

The qualification receipt records exact source/helper identities, Linux runs,
measurements and preserved baseline closure. Corpus coverage is lexical capture
under both lexers; it is not .ps parser translation or a new self-hosting chain.
The previously qualified compiler generations and npm artifacts remain unchanged.

R2 still requires resolved declarations/binders, capture-avoiding rename,
whole affected-closure elaboration and independent admission, public API and
explicit identity correspondence. R3 checked cross-grammar conversion and R4
behavioral transformations retain their separate obligations in
[the refactoring architecture](PSC1_SOURCE_REFACTOR_ARCHITECTURE.md).
