# Changelog

## 0.1.1

- Remove duplicate compilation and artifact-publication work from editor checks; retain genuine compiler analysis and exact-graph Wasm admission through public APIs.
- Fix the non-Linux publication-platform refusal without modifying compiler platform restrictions.
- Preserve unsaved buffers and terminal Infoview status across encoded Windows file URIs.
- Reuse exact checked snapshots in a bounded cache and avoid rechecking unchanged saves.
- Keep unrelated terminal errors visible; validate dependency versions before showing verification.
- Resolve cursor Infoview selection from current compiler metadata without a round-trip.
- Add measured before/after latency receipts and native Windows/macOS installed-package qualification.

## 0.1.0

- New PSC1 language client and compiler-backed language server integration.
- Cursor-following Infoview in the Secondary Side Bar, compiler messages, declaration status, and declared types.
- Current-version check indicators, compiler error markers, bottom-left status, and restart / output / server-information commands.
- Explicit PSC1 Lean subset language mode without taking over `.lean` files.
- Original syntax grammar and icons; the previous VSIX was used only as a UI reference.

This is an initial development release. The Infoview does not fabricate tactic goals or expected types when the compiler does not expose them.
