# Continue PSC0 v7.2 Core-first compiler development

Continue authorized open-source compiler correctness and formal-verification work in `dwijayuda/pskernel`. Execute useful implementation through GitHub tools and cloud Linux CI. Preserve selected v7.2 and the existing architecture; do not restart the compiler or work on independent kernel/research branches.

## Restore actual current state first

Read current refs, draft PR #151 and [AI_WORK_STATE.md](AI_WORK_STATE.md), then the Core architecture, capability inventory, roadmap, environment ledger, selfhost plan and qualification ledger. The working branch is `psc0/core-first-environments-20261019`, based on qualified Stage0 `33676076bcda7b0de5ec1f9803f49b8b1d28a058`. The qualified branch and PR #109 remain separate; unfinished Full work remains at `bf496ce399d9ec39794d6e9f7c3be919dfcffa58`.

Latest qualified code: `e059098683d3388fc9f893ec12027b4998eafd52`, tree `bc0cffc2ab7ad51bb133bc8943602c10b6afd29f`. [Run 39183454255](https://github.com/dwijayuda/pskernel/actions/runs/39183454255) completed successfully on 19 October 2026 at 01:08:19 UTC (08:08:19 Asia/Jakarta). All four jobs passed: source-inventory 117840891994, native-seams 117840891940, bootstrap-closure 117840891809 and candidate-authoring 117840892112.

The final code correction loads native class metadata explicitly for reporting. It finds `Decidable` and `Nonempty`, both unregistered in the Bootstrap seed and registered in Full. All 76 declaration-comparison rows and the complete raw Bootstrap manifest are unchanged from the prior successful run. [Exact qualification evidence](docs/core-first-evidence/e059-qualification.json) records the code SHA, job scopes, identities and measured command resources.

An evidence-only descendant can be newer than the qualified code commit. Verify that only documentation/evidence changed; do not invent a same-SHA CI receipt or reset the branch.

## Do not repeat completed work

Fingerprint/Replay extraction, explicit-context Engine, selected Pscv0Engine and 24 unchanged deriving helper moves are implemented. The actual paired selected-source/canonical-admission probe passed. The exact 76-declaration Bootstrap seed passed finite empty trust-zero replay, native reproduction and independent payload reconstruction. Source/typed ownership manifests and literal Full comparison are recorded.

The seed's source SHA256 is `05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54`; logical SHA256 `8b89d77e562378015e70d95560735e5727994016615255c84842eab190dae041`; FNV64 decimal string `15218654452277382292`. Preserve this UInt64 without JavaScript Number rounding.

## Continue the measured critical path

Bootstrap target is the smallest dependency-complete environment that compiles the whole authoritative compiler. The 76-declaration root is a checked seed component; it is not that finished profile. Core then adds the essential general-purpose application contract; Full adds independently checked optional compositions.

Resolve the actual seed/Full and source-registration boundary: 42/76 declarations match literally, 31 present names differ and 3 names are absent. Do not silently normalize, delete or replace qualified Full declarations. Bind the actual environment/runtime identity through Pscv0Modules, host admission, module interfaces and caches; the existing project composition is still Full and the in-process context record is not an authentication token.

Compile a real selected compiler-source subset, retaining its exact consumed-file/source/profile manifest and both selected input routes. Then expand to the entire authoritative compiler. Address the two native mutual-data groups with faithful checked representations; qualify actual fuel/recursion/deriving/control and word/string dependencies. Source token absence cannot justify omitting library proof dependencies.

The native full compiler route reaches 5,690 external declarations and the three approved logical assumptions. Recorded Classical.choice paths include while/string/order theorem dependencies; they are not executable-erasure proofs. The measured byte/word candidate is 16.1 MB source, not a tiny package. Keep exporter policies and runtime-choice refusals strict while reviewing the actual paths.

Qualify independent kernel admission, runtime/selected backend correspondence, whole Stage1–3 deterministic behavior, then real npm payload boundaries and clean install sizes. Existing source packages do not implement new compiler features. Core M1–M5/A–E exits use the actual workload; unrelated advanced Full exits are not prerequisites. No milestone closes merely because its Full scope was deferred.

## Operating constraints

GitHub connectors/cloud Linux only; no local repository operations or builds. Refresh expected HEAD before every write and use force:false; preserve concurrent history and healthy CI. Root is sole writer. Keep one active/one pending Core run, with cancellation disabled. Documentation-only evidence is not a loadable profile input and need not rebuild unchanged code.

Keep the canonical v7.2 reference unchanged and Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. No unchecked proofs, holes, new logical authority, runtime choice, enlarged budgets or relaxed negatives. Maintain all assurance distinctions, exact dependency/runtime identity, compiler WasmGC internals and explicit ABI boundaries. The independent kernel does not have to selfhost with the compiler.

Preserve Full tests and identities. Do not merge or select a Core release default while its closure, profile, runtime, package or selfhost gates remain open. Update both handoffs with exact code/test evidence and the next owned obligation. Work through concrete fixes; do not stop at a plan or repeat completed research.
