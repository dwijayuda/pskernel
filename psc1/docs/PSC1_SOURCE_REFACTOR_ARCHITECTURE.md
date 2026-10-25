# PSC1 checked source-refactoring architecture

Status: R1 lexical capture and staged byte edits qualified in Linux runs 40191237137 and 40191245319. No semantics-preserving automatic refactoring qualification is claimed. The original architectural inspection used `da880d864ca5f9e35729255fd7e4f8a17953cd39`; the additive R1 implementation follows PR #181 HEAD `d7e845b35e6c5cc80ffafe2f6f41fc475bf3842c`.

[Lossless capture contract and API](PSC1_LOSSLESS_SOURCE.md). R1 reused the original lexer. The subsequent [character-diagnostic correction](PSC1_CHARACTER_DIAGNOSTICS.md) changes one malformed-literal span expression with scoped formal correspondence and its own source qualification. The semantic AST remains unchanged. Resolved identities and independent before/after admission remain R2 work.

## Current source evidence

`packages/foundation/src/Ps/Foundation/Source.lean` stores `PsSourcePos {byteOffset,line,column}` and spans with start/stop positions; consumers must retain the established position convention rather than infer UTF-16 from a byte count. `packages/syntax/src/Ps/Syntax/Token.lean` retains token kind, text and span, but has no comment/trivia or stable-node field. `packages/syntax/src/Ps/Syntax/Lexer.lean` skips line/block comments and whitespace. Therefore the AST/printer path is currently a canonicalizer, not a lossless source editor.

`packages/syntax/src/Ps/Syntax/Ast.lean` has source spans on terms, names and declarations and `scopedDecl` namespace metadata. `PsSyntaxModule` contains imports/declarations, with no source identity, token tape or resolved binding identities. `packages/syntax/src/Ps/Syntax/Translate.lean` parses and prints a shared AST through `psTranslateLeanToProofScript`, `psTranslateProofScriptToLean` and canonicalizers. These functions return syntax/printing errors, but do not elaborate or independently admit output. Existing execution/admission roundtrip tests can qualify specific translations; the translation function alone proves no semantic equivalence.

`host/src/Ps/Host/SourceSnapshot.lean` already retains dependency-ordered exact source text and parsed modules, so lossless editing does not require replacing the semantic frontend. `host/src/Ps/Host/DirectBackend.lean` and `host-tools/artifacts.mjs` retain declaration provenance and format source maps after final formatting; this is useful infrastructure but not token-level edit provenance. Python/PHP artifact origins explicitly cover declaration starts only.

## Decision

Retain the existing shared semantic AST and elaborator and the qualified R1 token/trivia tape. Add resolved-source side tables through the bounded R2 ownership and reference-tracing steps below. Do not add a second elaborator or retrofit executable IR into a lossless syntax tree. Broad refactoring is outside the first JS/Rust self-host critical path.

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

## Next bounded step: R2a declaration ownership

Reuse `psCompilerPreparationStepParsedWithOrigins` and
`psElabModuleWithOrigins`. They already return `PsElabBatchOrigin` and its
source index/name/span, actual output members, roles and normalization ownership
from the same elaboration that produces declarations. Do not re-elaborate a
parallel interpretation merely to reconstruct provenance.

R2a acceptance is finite:

- Attach logical module, grammar/profile and exact snapshot identity to each
  actual source batch. Use source-local ordinal and member role/index with exact
  declaration identity; never treat display spelling as globally unique.
- Retain every actual batch member and synthesized ownership, including namespace
  qualification, inductive/structure constructors and recursors, and normalized
  workers/public wrappers. Refuse ambiguous or stale span-to-snapshot pairing.
- Compare original prepared declarations/admission bytes with the origin-aware
  path on successful inputs; preserve actual error attribution on refusal.
- Exercise both grammars, multiple modules, namespace/root names, generated-name
  collisions and malformed/stale ownership input. The output is a read-only
  ownership index, with no rename or publication authority.

A later R2b must record local binder/reference origins at actual elaboration
resolution points before any rename. `PsLocalContext.nextId` allocates local IDs
within contexts; a raw local ID is not a globally stable source binder identity.
Declaration ownership alone does not identify all references or establish
capture avoidance. R2a/R2b are pending, not implemented by the diagnostic fix.

## Milestones

R1 (qualified; see the lossless capture receipt): capture source IDs/digests and lossless token/trivia tape. Tests reconstruct exact bytes including nested comments, Unicode, CRLF, escaped literals and EOF trivia; reject stale edits. No semantic graph change.

R2: resolved binder/declaration side tables and one binding-aware rename. Test shadowing, namespaces, qualified/root names, imported private ownership, multiple modules and capture refusal. Independent admission and public API correspondence mandatory.

R3: checked cross-grammar conversion command with source-origin map and graph comparison. Reuse shared printers and their fail-closed unsupported-source errors. Include all selected Practical Core forms and ordinary partial helpers; preserve exact checked logical/runtime pairing.

R4: explicitly justified simplification passes with obligations. Keep unsupported effectful, partial or foreign transformations as proposed edits until behavioral evidence exists. Do not market this as verified automatic code improvement based only on parser or runtime tests.
