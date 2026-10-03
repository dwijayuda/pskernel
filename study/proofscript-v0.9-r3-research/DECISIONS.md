# r3 Decision Ledger

Status: **living research ledger**

A decision here is a recommendation for the r3 candidate. It does not activate the language in the production compiler.

| ID | Topic | Decision | Status | Evidence |
|---|---|---|---|---|
| R3-001 | Parenthesized calls | In <code>.ps</code>, ordinary trivia before <code>(</code> does not change parenthesized-call ownership; tuple argument requires extra grouping. Reclassify as E-class exception. | recommended | reference research; formal proof plan documented |
| R3-002 | Owned braces | Owned braces define outer member boundaries; use comma fields, marker alternatives, and native semicolons where the native sequence has them. | recommended | reference research; prototype pending |
| R3-003 | <code>function f()</code> | Lower to one explicit Unit binder; <code>f()</code> remains Unit application. | recommended | semantic design; oracle test pending |
| R3-004 | <code>const</code> | Retain as top-level/namespace parameterless-def alias, but freeze only after human comprehension study. | provisional | design analysis; human study not run |
| R3-005 | Source profiles | Add <code>ps-standard</code> closed syntax and <code>ps-lean-extensible</code> declared extension profile over the same core. | recommended | architecture/reference research |
| R3-006 | Contracts | Define PSC-owned stable contract semantics tied to ordinary admitted theorems/program logic. Lean intrinsic verification becomes optional compatibility/oracle. | recommended | design; implementation/proof pending |
| R3-007 | App effects | Standardize a library/runtime model around <code>App</code>, <code>Fiber</code>, <code>Resource</code>, <code>Stream</code>, and explicit exits; do not reuse Promise as semantics. | recommended | research; prototype pending |
| R3-008 | JS/TS boundary | Introduce versioned InterfaceIR, raw/safe/spec layers, and fail closed on unsupported <code>.d.ts</code> machinery. | recommended | research; prototype pending |
| R3-009 | Formal slices | Prove a small call-overlay model and RuntimeIR-to-JS-core preservation theorem before broad claims. | required | formal proof plans documented; no executed proof claimed in final docs-only branch |
| R3-010 | Human study | Do not freeze high-risk syntax before controlled TypeScript/Lean participant study. | required gate | protocol complete; study not run |

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

Any reversal of R3-001 through R3-010 must update the relevant design document, migration/conformance plans, this ledger, <code>MANIFEST.json</code>, and the integrated candidate if it already exists.

Human-study results may change the provisional <code>const</code> decision without implying a change to Lean semantics.
