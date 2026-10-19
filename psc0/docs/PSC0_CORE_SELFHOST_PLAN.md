# Core selfhost qualification plan

## Stage definitions

| Stage | Required result | Insufficient evidence |
| --- | --- | --- |
| Stage0 | Qualified Lean-backed PSC0 `33676076bcda7b0de5ec1f9803f49b8b1d28a058`, exact reference/Standard/runtime/checker identities | Repository default branch, arbitrary native Lean, unfinished Full preparation tip |
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

## Incremental implementation

First isolate fingerprint/serialization, host kernel replay and an explicit-context Engine while preserving Full wrappers. Check their import closure and real preparation/refusal behavior; this is not Stage1.

Next compile a real selected-source subset such as Foundation.Source, Foundation.List and Syntax.Token against a independently checked Core seed. Use both selected source routes and retain the output comparison contract. Include missing-source, wrong-environment, malformed-source and invalid-recursion controls. Add Foundation.Name and Syntax.Cursor only with exact UTF8/string dependencies or a checked conversion.

The mutual Syntax and ECMA data groups require a faithful selected representation. One candidate is an indexed family over a closed role tag with unchanged constructor telescopes, checked eliminators and API/runtime correspondence. Do not use an untyped representation or enable native-only syntax silently.

Expand to an actual parser worker, checked elaboration worker and finally the whole compiler manifest. Report subset acceptance as subset acceptance. Every new external native dependency becomes either an admitted Core declaration/runtime obligation or a justified selected-source conversion.

## Reusable historical machinery

`selfhost-source-workspace.mjs` supplies useful consumed-file and dependency-order mechanics. `sh1-qualify.mjs` supplies stage and artifact comparison mechanics. The Linux five-source bridge supplies source-selection and recipient-owned AST transport techniques. Reuse these mechanisms after changing their historical grammar/API/closure identities and adding current checking gates; do not relabel old receipts.

The old selfhost seed and package scripts belong to earlier compiler/kernel/toolchain identities. The successful historical 20-module/five-source bridge was not the complete v7.2 compiler fixed point. Native Lean compilation of current files also remains distinct from compiling those files through PSC0's selected input contract.
