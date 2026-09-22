# Language service, LSP and project tooling plan

Status: after syntax/meta/elab APIs stabilize.

Lean 4.34 analogues:
- `Lean.Language`
- `Lean.Server`
- Lake responsibilities, but not Lake's package-manager model

## @proofscript/language

This package sits below LSP.

MVP:
- document snapshots
- incremental parse/elaboration
- cancellation
- dependency-aware invalidation
- diagnostics
- source ranges
- info tree / source-to-term mapping
- reusable task results

Consumers:
- CLI watch mode
- browser playground
- LSP
- tests

## @proofscript/lsp

Protocol adapter only.

MVP:
- diagnostics
- hover
- definition
- references
- completion
- semantic tokens
- inlay hints
- goal display
- cancellation

Do not duplicate parser/elaborator logic here.

## @proofscript/project

Use npm rather than replace it.

MVP:
- discover ProofScript project config
- map npm dependencies to checked ProofScript modules
- incremental build graph
- content-addressed cache
- compiler target/profile settings
- source/output conventions
- CLI integration

Potential configuration location:
- a `proofscript` section in `package.json`, or
- a small `proofscript.json` when separation is clearer.

## @proofscript/browser

MVP:
- Web Worker checker
- stream transport
- cancellation/progress
- module cache
- browser-safe diagnostics

This package must not fork kernel semantics.
