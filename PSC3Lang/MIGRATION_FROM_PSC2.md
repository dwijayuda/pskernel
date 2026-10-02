# Migration from PSC2 and earlier PSC3 drafts

**Proposed migration policy. No source or compiler migration was performed by this documentation change.**

## 1. Edition boundary

PSC3 is a new public-source edition, not a silent reinterpretation of PSC1/PSC2. Existing source keeps its declared semantics. The manifest specifies the edition; a filename is insufficient because `.ps` and `.psx` have different proposed roles across versions.

The migrator must parse using the old grammar, produce new native syntax, preserve module/definition identities as specified, and report ambiguity. Global replacement of braces, semicolons or calls is not a safe migration. The old grammar explicitly distinguishes adjacent calls from Lean-neighbor tuple/application forms. [R01–R02](RESEARCH_SOURCES.md#repository-baselines)

## 2. Main changes

| Existing design | PSC3 recommendation | Migration/evidence requirement |
|---|---|---|
| `def` / `const` / `function` aliases | Canonical native `def`. | Preserve binders, types, defaults and body. |
| `f(x,y)` adjacent curried call | Native `f x y`; tuple calls remain explicit. | Parse the old AST; do not guess from whitespace alone. |
| Owned braced declaration/proof blocks | Native Lean forms/layout. | Correct scope, semicolon and macro-category handling. |
| `.lean` and `.ps` related but distinct surfaces | Strict byte-identical content profile. | Record old-to-new source correspondence and official Lean checks. |
| Multiple contract clauses in draft prose | Exact pinned native clause grammar or ordinary theorem. | Preserve conjunction/binders and effect-spec meaning. |
| Inconsistent `Result` ordering examples | Standard `Except ε α`; explicit user Result types allowed. | Transform data constructors/specifications together. |
| Abstract Task promise | Native Task unchanged; separate proposed `Psc.Async`. | No renaming alone can prove scheduler/cancellation equivalence. |
| `.psx` mixed/unverified possibility | Explicit optional UI extension in a new edition. | Reject old escape semantics unless a separately named legacy profile is selected. |
| Feature inclusion by syntax | Source/elaboration/logical/runtime/assurance coverage matrix. | Do not infer executable support from parsing. |
| Library generation emphasis | Full-app platform and concrete application acceptance gates. | Implement adapters, tooling and end-to-end workflows. |
| Earlier TS/Rust-only PSC3 proposal | Preserve routes; favor gated direct JS/direct Wasm too. | No deletion or bootstrap change implied. |

## 3. Lean patch proposal

The repository design baseline used v4.34.0; this proposal selects v4.34.1 for the new profile after checking its tag and official runtime-fix guidance. Existing pins and artifacts remain unchanged. [L01–L02](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Before migration, rebuild the selected oracle/tooling, audit logical/native changes, replay positive and adversarial evidence, compare relevant source elaboration, and validate runtime representation behavior. A patch number is not proof of compatibility. Do not mix prebuilt artifacts from different pins under one identity.

## 4. Specification compatibility

Retain actual program/specification statements or establish the appropriate equivalence/refinement under an explicit migration plan. Changing input domains, error cases, resource behavior, logical assumptions or numeric operations is a semantic change even when the exported name stays the same.

Changing tactics without changing the proved statement is different from weakening the statement. The migration report must distinguish proof-script repair, API change, program behavior change and assumption change.

When a PSC2 behavior is underspecified, do not fabricate an equivalence proof to the newly chosen rule. Identify the ambiguity, propose a rule and require explicit review with regression cases.

## 5. Generated source and artifacts

Do not hand-maintain two diverging compiler sources while claiming a canonical relationship. Bootstrap source policy and the user-language edition are separate; the compiler need not immediately use every new feature it accepts.

The migration tool and its printer are transformations with their own correctness obligations. Hash equality can establish identical bytes, not equality of different source programs. Old checked reports are not automatically valid for new source, runtime or compiler artifacts.

## 6. Rollout

Maintain a legacy reader or explicit migration tool as appropriate. Provide a report listing changed syntax, retained statements, renamed library operations, target restrictions and manual review items. Build example projects under the old and new declared environments, compare specified behavior and replay relevant proofs.

Do not introduce the new edition into the active bootstrap until the source subset and generation gates are ready. This documentation folder is a review artifact, not an authorization to rename packages, merge workstreams or modify implementation progress.
