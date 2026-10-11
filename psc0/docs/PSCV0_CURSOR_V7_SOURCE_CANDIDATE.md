# PSCV0 v7 — Cursor compiler-source migration candidate

**Date:** 11 October 2026. **Status:** proposed source candidate and strict Linux-only graph differential, *not yet qualified or promoted*. **Branch:** `psc0/pscv0-compiler-fast-loop-v1`.

The new [`Ps.Syntax.Cursor.ps`](../packages/syntax/src-ps/Ps/Syntax/Cursor.ps) is a direct, conservative v7 rendition of the historical 92-line [`Ps.Syntax.Cursor.lean`](../packages/syntax/src/Ps/Syntax/Cursor.lean). It contains two source-structure types (`PsLexCursor` and `PsLexStep`), nine typed functions, list pattern matches, `Option` constructors, UTF-8 source-position updates, a function-returning lambda and a dependent import of `Ps.Foundation.Source`. In the first version we preserve the original algorithms; source brevity, performance gains and full v7 language conformance are **not** claimed.

## Required invariants

- **Exact source authority:** the sole forward-looking PSCV0 v7 reference defines `.ps` grammar; no fallback to PSC1 or older `.ps` editions and no parser-gap exemptions.
- **Owned source graph:** `Cursor` depends on `Source` through its imported source position/span types. The graph also includes the `Token` type module and independent `List` helpers. Both original Lean and candidate v7 sources must use the same import names.
- **Typed semantics:** candidate `psLexStringToListFromWithFuel` returns the same higher-order typed function, with correct structural fuel recursion and UTF-8 byte positions. `psLexCursorPeekSecond`, source line/column movement and character access must preserve the original compiler's ADTs and first-error/Option behavior.
- **Strict product identity:** the in-memory, prefix-cached [Linux graph compiler differential](../tools/abi/compiler-graph.mjs) compares all final canonical compiler admission bytes and emitted TypeScript 7 bytes across nine scenario combinations. The two new scenarios select Cursor v7 alone and all four v7 candidates together. Both must remain identical to the original Lean-rooted reference graph.
- **No kernel or Windows tests:** every step is compiler syntax, elaboration, TypeScript generation and Linux JavaScript evaluation only. Windows is covered by a static source-portability checklist, not an actual Windows CI result; kernel release assurance remains a separate deferred gate.

An early parsing failure is evidence that a useful v7 grammar family is not yet accepted by the present generated source frontend. Investigate the language/parser ownership and concrete source, **not** changes to expected test results or old-grammar compatibility. If a feature truly is not yet implemented, leave this fourth candidate unqualified while recording the missing capability and preserve the previously green Source/Token/List state.
