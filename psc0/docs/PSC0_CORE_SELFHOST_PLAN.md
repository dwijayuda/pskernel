# Core selfhost qualification plan — final phase

This phase follows acceptance of Core language/compiler M1–M5, per the user's 19 October 2026 10:21 Asia/Jakarta directive. Its full authoritative source manifest, representation conversions, runtime correspondence and Stage1–3 fixed-point requirements are retained. Preparatory evidence remains reusable; compiler-source conversion does not displace an open Core language/compiler exit. [The immediate completion register](PSC0_CORE_LANGUAGE_COMPLETION_PLAN.md) owns work before this phase.

Before Stage1, record the exact M1–M5-qualified Lean-backed compiler that will execute it, including code/profile/runtime/checker identities. Keep the historical Stage0 baseline and its receipts separately; a newer executor does not inherit those receipts automatically.

## Stage definitions

| Stage | Required result | Insufficient evidence |
| --- | --- | --- |
| Stage0 / stage executor | Preserve qualified Lean-backed baseline `33676076bcda7b0de5ec1f9803f49b8b1d28a058`; before Stage1 independently pin the actual M1–M5-qualified executor and its reference/Core/runtime/checker identities | Repository default branch, arbitrary native Lean, unfinished Full tip or automatic reuse of historical receipts |
| Stage1 | Stage0 compiles every authoritative Core source module expressed in selected v7.2; resulting executable contains the actual selected parser/project/elaboration/preparation/erasure/codegen API | A sample, native implementation build, syntax transport demo, old BackendTs.Compiler facade |
| Stage2 | Stage1 recompiles that entire frozen source manifest and produces a runnable compiler | Reused Stage0 parse/elaboration output, hidden old compiler implementation, a smaller manifest or unchecked incremental state |
| Stage3 | Stage2 builds the next compiler from the same sources; declared fixed-point products agree, independent checking succeeds, and runtime/applicable target correspondence passes | One matching JS file, kernel checks without source/behavior correspondence, historical PSC1/PSC2 receipts |

The independent kernel need not selfhost. Its adapter and exact checked prelude remain explicit external inputs. Compiler semantics cannot migrate into an unrecorded host shim. Select one authoring authority per module and declare readable projections; independently edited .ps and .lean masters do not establish deterministic source authority.

## Frozen denominator and stage runner

Record source commit/tree, selected v7.2 identity, ordered source module/path/kind/content hashes, imports/exports, capability profile, checked declaration/instance/assumption closure, generated-helper ownership, runtime/target profiles, checker/toolchain identity, comparison recipe and unchanged resource policy. Declare generated data and host adapters separately. Every consumed input belongs to this manifest or an explicit checked boundary.

Reject a missing/additional module, source-kind substitution, import cycle, source mutation during a request, changed environment/runtime identity, unchecked cache and a compiler lacking the actual selected API. Hash the bytes actually consumed. Generated workspaces cannot fall back to handwritten parent directories or alternate extensions.

## Acceptance observations

1. Parse and elaborate the full source set with owned selected readers. Report each module's first failing phase while retaining the complete denominator. Resolve the two mutual-data representations and bounded hash-padding loop explicitly.
2. Independently check logical declarations and exact metadata against the qualified Core seed. Preserve assumptions and resource gates, reject holes, and keep runtime implementation bodies separate from logical proof authority.
3. Compare compiler workload behavior across stages: Unicode positions, scope/names, source refusals and error order, declaration/interface metadata, prepared admissions, IR checking and emitted artifacts. Perturbed inputs must demonstrate that the generated compiler performs the work.
4. Compare Stage2/Stage3 canonical source, admissions, IR and target products under an advance-declared normalization recipe. Exclude only justified sidecars such as timing/host paths; do not normalize away semantic differences.
5. Execute the same fixed compiler workload through each advertised applicable backend, against an independent reference and identical runtime/word-size settings. JS bootstrap does not remove advertised Rust/Wasm emitters from the source denominator.
6. Rebuild with empty caches and pinned recorded inputs. Compare cold, warm and incremental paths. Publish exact stage receipts only for this complete route; changing the selected seed is a separate promotion.

## Retained preparation and final implementation order

The source sequence below is final selfhost work. Retain the passing tests now; extend it before M1–M5 acceptance only for a demonstrated Core language/runtime requirement.

Fingerprint/Replay extraction, explicit-context Engine, selected readers, deriving-helper separation and fresh portable project threading are implemented at their recorded probe scopes. Preserve their Full compatibility wrappers. These results establish reusable preparation and checking boundaries; they do not establish Stage1.

The first complete compiler-source workload is Foundation.Source plus Foundation.List, with every original source declaration and its ProofScript counterpart retained. An importing entry makes both real modules reachable. Complete selected preparation and canonical independent admission are qualified against the measured candidate, retaining exact source paths, bytes, hashes, generated declarations and metadata. Expand to Syntax.Token, Foundation.Name and Syntax.Cursor only with measured source, deriving and UTF8/string dependencies or an explicitly qualified conversion.

The mutual Syntax and ECMA data groups require a faithful selected representation. One candidate is an indexed family over a closed role tag with unchanged constructor telescopes, checked eliminators and API/runtime correspondence. Do not use an untyped representation or enable native-only syntax silently.

Expand to an actual parser worker, checked elaboration worker and finally the whole compiler manifest. Report subset acceptance as subset acceptance. Every new external native dependency becomes either an admitted Core declaration/runtime obligation or a justified selected-source conversion.

## Reusable historical machinery

`selfhost-source-workspace.mjs` supplies useful consumed-file and dependency-order mechanics. `sh1-qualify.mjs` supplies stage and artifact comparison mechanics. The Linux five-source bridge supplies source-selection and recipient-owned AST transport techniques. Reuse these mechanisms after changing their historical grammar/API/closure identities and adding current checking gates; do not relabel old receipts.

The old selfhost seed and package scripts belong to earlier compiler/kernel/toolchain identities. The successful historical 20-module/five-source bridge was not the complete v7.2 compiler fixed point. Native Lean compilation of current files also remains distinct from compiling those files through PSC0's selected input contract.

## First retained source extension when final selfhost resumes

The [source inspection](core-first-evidence/next-compiler-source-workload.json) recommends `Ps.Syntax.Token`: 1,085 source bytes, exactly three source declarations and an import of Foundation.Source. It defines the seven-case token kind, exhaustive Boolean equality and a token record. The record's `text : String` is its first added native requirement; the module performs no string operation.

Pinned native String contains ByteArray and a ByteArray.IsValidUTF8 proof. The predicate reaches noncomputable List.utf8Encode and its actual character/word dependencies. Measure a separate additive closure from the existing foundation roots plus String; inspect exact native kinds, bodies, assumptions and metadata, then admit the full closure. Do not remove the text field or infer closure size/policy from its type-only use. Retain all three Token declarations and its Source import in the selected paired-source gate.

Cursor (2,808 bytes, eleven explicit source declarations) is a useful later step before Name (3,984 bytes, eleven declarations). Both use `String.Internal` extern declarations whose source has no explicit body. Those names differ from later checked String operations; their exact imported values, assumption closure and runtime contracts still require inspection. Any replacement must be an explicit, qualified source conversion. Cursor also tests strict-child recursive results returned as functions and actual UTF8 byte/line/column behavior. Name adds decimal rendering and its implementation correspondence.

These are inspected future workloads, with no selected-source or runtime acceptance assigned yet.

## Current completed source step

At `1995a478af7aeb83032749fbdb9a2cfa96d28a88`, [run 39191534560](https://github.com/dwijayuda/pskernel/actions/runs/39191534560) passed all four Core-first Linux jobs. PSC0 accepted both complete original Foundation.Source and Foundation.List files and their ProofScript counterparts through the explicit-context project engine, produced identical canonical admissions, and independently admitted both results over the measured 92-declaration candidate. It retained every original seed declaration/effective reducibility and the measured source metadata. Native elaboration parity, emitted backend execution and whole-compiler selfhost remain unqualified.

After M1–M5 acceptance, resume at the first unresolved owned source boundary: the additive String closure and complete Token gate described above, unless intervening Core language work has already qualified that exact dependency. Preserve the Source/List source pins and candidate assets. Do not repeat completed extraction work or omit functions to make a larger source manifest pass.
