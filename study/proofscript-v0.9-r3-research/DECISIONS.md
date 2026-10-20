# r3 Decision Ledger

> **Historical design record.** Current source syntax and language meaning are defined only by `ProofScript_Language_Reference_v0.9.0_r3.md`. This file records accepted research decisions and may also mention platform/runtime/protocol decisions that are scoped to their own documents.

Status: **accepted r3 design baseline**

These decisions are accepted into the r3 language design. They define the documentation/specification baseline, not an implemented compiler claim.

| ID | Topic | Decision | Status | Evidence |
|---|---|---|---|---|
| R3-001 | Parenthesized calls | In <code>.ps</code>, ordinary trivia before <code>(</code> does not change parenthesized-call ownership; tuple argument requires extra grouping. Reclassify as E-class exception. | accepted | reference research; formal proof plan documented |
| R3-002 | Owned braces | Owned braces define outer member boundaries; structure/class commas appear only between fields (no trailing field comma); use marker alternatives and native semicolons where the native sequence has them. | accepted | reference research; prototype pending |
| R3-003 | <code>function f()</code> | Lower to one native optional Unit binder defaulting to <code>()</code>; empty invocation uses the general r3 default-completion rule. | accepted | semantic design; oracle test pending |
| R3-004 | <code>const</code> | Retain as top-level/namespace parameterless-def alias in r3. Re-evaluate before stable/1.0 freeze if usability evidence shows harmful false familiarity. | accepted for r3 | design analysis; human study not run |
| R3-005 | Source profiles | Add <code>ps-standard</code> closed syntax and <code>ps-lean-extensible</code> declared extension profile over the same core. | accepted | architecture/reference research |
| R3-006 | Contracts | Define PSC-owned stable contract semantics tied to ordinary admitted theorems/program logic. Lean intrinsic verification becomes optional compatibility/oracle. | accepted | design; implementation/proof pending |
| R3-007 | App effects | Standardize a library/runtime model around <code>App</code>, <code>Fiber</code>, <code>Resource</code>, <code>Stream</code>, capabilities, and explicit exits; do not reuse Promise as semantics. | accepted architecture | research; prototype pending |
| R3-008 | JS/TS boundary | Introduce versioned InterfaceIR, raw/safe/spec layers, and fail closed on unsupported <code>.d.ts</code> machinery. | accepted architecture | research; prototype pending |
| R3-009 | Formal slices | Prove a small call-overlay model and RuntimeIR-to-JS-core preservation theorem before broad claims. | accepted future evidence requirement | formal proof plans documented; no executed proof claimed in final docs-only branch |
| R3-010 | Human study | Run the controlled TypeScript/Lean participant study before stable/1.0 syntax freeze; r3 may record the accepted design before the study. | accepted future freeze gate | protocol complete; study not run |

## Rejected directions

- a new ProofScript kernel/type theory;
- JavaScript truthiness or implicit null/undefined;
- native <code>any</code>;
- generic statement blocks with implicit return;
- JavaScript automatic semicolon insertion;
- silently treating Promise as native Task;
- treating <code>.d.ts</code> as runtime validation;
- arbitrary package parser mutation in <code>ps-standard</code>;
- calling tests, self-hosting, or output hashes a proof of compiler preservation.

## Revision policy

Any reversal of R3-001 through R3-010 must update the relevant design document, migration/conformance plans, this ledger, <code>MANIFEST.json</code>, and the accepted r3 language reference.

Human-study results may still justify a later pre-1.0 change to <code>const</code> or other high-risk surface syntax without implying a change to Lean semantics.

| R3-011 | Complete-delta authority | r3 is a complete exact delta over vendored r2 SHA-256 d29c0b2d...; unchanged r2 rules remain normative. | accepted | authority + 89-section matrix |
| R3-012 | Empty call | `f()` is a complete empty invocation lowered as native high-level `f ..`; only native optional/automatic explicit parameters may be omitted, while ordinary required explicit parameters reject. `function f()` supplies this via an optional Unit default; `f(())` is explicit Unit. | accepted | Lean function-application/default-parameter research |
| R3-013 | Call boundary / field dot | CallGap is horizontal only; line terminator breaks r3 call ownership. Lean field-dot adjacency is unchanged. | accepted | Lean reference research |
| R3-014 | Standard registry / bundles | `ps-standard-0.9-r3` uses a closed machine-readable registry; Extensible libraries cross through Semantic Bundle v1 with no syntax/meta exports. | accepted | architecture/specification |
| R3-015 | Contract core | Base r3 freezes total-pure requires/ensures, semantic FrameSpec and higher-order CallableSpec; state/loop/async surface clauses are staged. | accepted | verification-language research |
| R3-016 | Application semantics | App is cold; Fiber is started; Exit excludes RuntimeFault; cancellation is two-phase; cleanup is shielded; capabilities are type-visible; native IO/Task are low-level/nonportable substrate. | accepted | async/resource research |
| R3-017 | InterfaceIR v1 | Versioned JSON schema binds TS resolver/version, package/export conditions, runtime/type entries and declaration hashes with explicit support classes. | accepted | Node/TypeScript research |

| R3-018 | Pre-stable evidence gates | Stable/1.0 review requires the consolidated usability, frontend-proof, backend-preservation, primitive/runtime, application-semantics, InterfaceIR/npm, reference-app, Standard-profile, contract, and artifact-binding evidence plan. None is completed by the documentation pass. | accepted future release gate | `23-PRE-STABLE-EVIDENCE-GATES.md` |
| R3-019 | Braced definition body | `def`, `const`, and `function` accept `:= { PSTerm }` as a single-term body wrapper exactly equivalent to `:= PSTerm`. The wrapper has no statement/implicit-return semantics and does not steal ownership from record literals/updates or other complete braced terms. | accepted | grammar coherence review; implementation/conformance pending |
| R3-020 | Module public API / re-export | PSC2 adopts Lean-compatible `public import M` as the only core module re-export form. Ordinary top-level declarations are public unless `private`; ordinary `import` is not re-exported; `open` never re-exports; selective/default/namespace export syntax is outside PSC2 core. Contracted functions reuse the ordinary `DefinitionBody` grammar. | accepted | Lean 4.34 module import semantics + r3 language-freeze review |
