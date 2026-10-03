# r3 Remaining Work After Specification Completion

Status: **the ten specification-completion gaps are resolved at design/specification level**.

The remaining items are implementation/evidence work or later API ergonomics; they do not leave the accepted base-r3 semantics undefined.

1. Implement the exact r3 parser/lowerer and prove/refine it against the accepted grammar.
2. Implement `ps-standard-0.9-r3` registry enforcement and semantic-bundle import/recheck.
3. Implement the pure contract core, frame metadata, and higher-order CallableSpec library model.
4. Design later versioned state/loop/async contract surfaces and program logics; they are intentionally not base-r3 syntax.
5. Choose final public Lean-library API names/encodings for the already-frozen App/Fiber/Resource/Stream semantics.
6. Implement RuntimeFault classification/adapters for JS and Wasm hosts.
7. Implement InterfaceIR v1 importer/exporter and runtime validator/schema library.
8. Build the real npm binding corpus and reference applications.
9. Establish the planned formal overlay/refinement/backend-preservation theorems.
10. Establish exact ECMAScript and direct-Wasm artifact/semantics relations.
11. Run the TypeScript/Lean human study before stable/1.0 freeze.
12. Reconsider only explicitly usability-gated spellings (especially `const`) if the study crosses the pre-registered change threshold.

Resolved in the specification-completion pass:

- r3 is a complete exact delta over the vendored r2 baseline;
- r2 primitive/runtime/module/compiler-assurance semantics remain authoritative unless overridden;
- `CallGap` is horizontal; line terminators break parenthesized-call ownership;
- native dot adjacency remains unchanged;
- `f()` has complete empty-invocation semantics and is distinguished from `f(())`;
- r2 empty calls migrate to explicit `f(())` to preserve old Unit intent;
- structural brace grammar and category-specific separators are explicit;
- Standard registry identity is frozen;
- Extensible-to-Standard Semantic Bundle v1 is specified;
- the base contract core is narrowed to total pure `requires`/`ensures`, with semantic frames and a higher-order CallableSpec model;
- App is cold, Fiber is started, cancellation/join/cleanup shielding/RuntimeFault/capabilities/native-IO relationship are defined;
- InterfaceIR v1 has a concrete schema and exact package/module-resolution identity.

No implementation or evidence item may be silently reported as completed because its specification is complete.
