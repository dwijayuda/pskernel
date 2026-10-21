# JSON record processor acceptance core

Three authored modules per syntax resolve as real imports: JsonRecords.Input,
JsonRecords.Transform and JsonRecordApplication. The transform parses JSON
objects, looks up the text field, reads its first Unicode scalar, folds multiple
records and propagates typed JsonError. This is the pure processing core of the
finite JSON/file application; console/files, capability policies, large-input
measurements and public aggregate marshalling remain missing.

PSC1_JSON_APPLICATION_CASE_CONTRACT.json selects seven cases in both grammars
and all seven targets. The shared conformance runner compiles/admit/validates the
actual modules and executes each scalar observation separately. Exact module,
library, entry, artifact, oracle and manifest hashes are retained. Wrong record/
list types, duplicate prelude, verified mode and malformed component selections
must refuse without replacing prior publication.

Valid pairs, BMP neighbors, literal non-BMP characters and mixed hex casing use
native Lean4.35 Json.parse in a separate process as the expected-value source.
The minimum pair decodes U+10000; the maximum decodes U+10FFFF. Unpaired,
incorrect and truncated pairs retain PSC1's invalidUnicode policy. Native Lean
can substitute U+FFFD for malformed surrogates; that recovery is deliberately
not PSC1's selected strict policy. Existing jsonReadUnicode4 consumes one
four-digit scalar and continues to reject a surrogate even when followed by a
pair tail. jsonReadUnicodeEscape is the new pair-aware JSON-string operation.

No complete-family, typed-IO or production-release claim follows from these
finite internal observations. CI receipts establish only the exact recorded
implementation, source lanes, toolchain and target cases.
