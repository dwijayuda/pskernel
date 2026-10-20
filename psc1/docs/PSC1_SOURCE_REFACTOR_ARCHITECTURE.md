# PSC1 checked source-refactoring architecture

Status: selected future design; no semantics-preserving automatic refactoring qualification is claimed. Inspected baseline: `da880d864ca5f9e35729255fd7e4f8a17953cd39`.

## Current source evidence

`packages/foundation/src/Ps/Foundation/Source.lean` stores `PsSourcePos {byteOffset,line,column}` and spans with start/stop positions; consumers must retain the established position convention rather than infer UTF-16 from a byte count. `packages/syntax/src/Ps/Syntax/Token.lean` retains token kind, text and span, but has no comment/trivia or stable-node field. `packages/syntax/src/Ps/Syntax/Lexer.lean` skips line/block comments and whitespace. Therefore the AST/printer path is currently a canonicalizer, not a lossless source editor.

`packages/syntax/src/Ps/Syntax/Ast.lean` has source spans on terms, names and declarations and `scopedDecl` namespace metadata. `PsSyntaxModule` contains imports/declarations, with no source identity, token tape or resolved binding identities. `packages/syntax/src/Ps/Syntax/Translate.lean` parses and prints a shared AST through `psTranslateLeanToProofScript`, `psTranslateProofScriptToLean` and canonicalizers. These functions return syntax/printing errors, but do not elaborate or independently admit output. Existing execution/admission roundtrip tests can qualify specific translations; the translation function alone proves no semantic equivalence.

`host/src/Ps/Host/SourceSnapshot.lean` already retains dependency-ordered exact source text and parsed modules, so lossless editing does not require replacing the semantic frontend. `host/src/Ps/Host/DirectBackend.lean` and `host-tools/artifacts.mjs` retain declaration provenance and format source maps after final formatting; this is useful infrastructure but not token-level edit provenance. Python/PHP artifact origins explicitly cover declaration starts only.

## Decision

Retain the existing shared semantic AST and elaborator. Add a separate token/trivia tape and resolved-source side tables only when a first source-editing feature is implemented. Do not add a second elaborator or retrofit executable IR into a lossless syntax tree. Broad refactoring is outside the first JS/Rust self-host critical path.

Record the following at source capture/elaboration boundaries:

- Source ID from logical module identity plus digest of exact bytes and grammar/profile; retain URI/path as provenance, not global declaration identity.
- Byte spans into the immutable source snapshot, stable per-snapshot node IDs, original token spelling and all comment/trivia ranges.
- Resolved declaration IDs and local binder IDs. Retain existing collision-aware Core-to-runtime mappings separately; runtime-mangled names are not source identity.
- Inferred types, implicit argument choices and source-node-to-Core origin mapping in a side table. Synthesized nodes record origin, pass and inputs.
- Import/public ownership and namespace scope; a rename must resolve every affected reference without textual global replacement.

Ordinary editing should patch the smallest token ranges and preserve unaffected bytes. Cross-grammar conversion produces newly formatted source with an origin map; it cannot promise identical comments/formatting unless trivia migration is implemented.

## Assurance pipeline

Capture source closure; parse; elaborate and resolve; propose typed edit; apply to staged bytes; parse/elaborate the entire affected closure; recompute exact admission; independently check; compare public API, resolved identities and the selected equivalence relation; publish only when every required gate succeeds. A stale source digest cancels the edit. Preserve original bytes and prior artifacts on failure.

Use different acceptance relations for different edits:

| Edit | Required relation |
| --- | --- |
| Whitespace/comment edits | Equal token semantics/resolved graph and exact public API; preserve comments requested by user |
| Alpha rename | Binder/declaration correspondence, capture avoidance and checked types; compare canonical Core modulo the explicit renaming map |
| `.lean`/`.ps` canonical conversion | Equivalent resolved/admitted Core with normalized generated-name correspondence, preserved ordinary logical/body pairing and public API |
| Definitional simplification | Independently checked before/after terms and kernel definitional equality at the same type |
| Control-flow/runtime transformation | Explicit behavioral equivalence obligations, including effect/evaluation order, divergence and foreign assumptions; ordinary testing alone cannot certify it |

Exact raw graph-byte equality is a useful strong gate when expected, but may reject harmless generated-name changes. Do not weaken equality silently; specify and test a canonical identity correspondence. Definitional equality does not establish foreign effect equivalence, and successful reparse does not establish either.

## Milestones

R1 (later, small foundation): capture source IDs/digests and lossless token/trivia tape. Tests reconstruct exact bytes including nested comments, Unicode, CRLF, escaped literals and EOF trivia; reject stale edits. No semantic graph change.

R2: resolved binder/declaration side tables and one lexical rename. Test shadowing, namespaces, qualified/root names, imported private ownership, multiple modules and capture refusal. Independent admission and public API correspondence mandatory.

R3: checked cross-grammar conversion command with source-origin map and graph comparison. Reuse shared printers and their fail-closed unsupported-source errors. Include all selected Practical Core forms and ordinary partial helpers; preserve exact checked logical/runtime pairing.

R4: explicitly justified simplification passes with obligations. Keep unsupported effectful, partial or foreign transformations as proposed edits until behavioral evidence exists. Do not market this as verified automatic code improvement based only on parser or runtime tests.
