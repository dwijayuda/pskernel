# Changelog

## 0.1.0

- New PSC1 language client and compiler-backed language server integration.
- Cursor-following Infoview in the Secondary Side Bar, compiler messages, declaration status, and declared types.
- Current-version check indicators, compiler error markers, bottom-left status, and restart / output / server-information commands.
- Explicit PSC1 Lean subset language mode without taking over `.lean` files.
- Original syntax grammar and icons; the previous VSIX was used only as a UI reference.

This is an initial development release. The Infoview does not fabricate tactic goals or expected types when the compiler does not expose them.
