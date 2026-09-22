# Package scaffolds

This directory contains **private package boundaries**, not a live npm workspace yet.

The root pskernel build remains independent while Lean 4.34 Full Std certification is active. Do not add root `workspaces` or make the trusted kernel depend on packages here until an explicit migration plan is approved.

## Status source of truth

See `package-map.json` for:
- package name/path
- phase
- trust classification
- scaffold/implementation status
- intended dependency direction

## Current implementation state

- `cli/` — prototype with replay/check and module commands.
- `module/` — MVP checked-module artifact implementation.
- `conformance/` — MVP Arena-style conformance runner.
- `lean4export/` — MVP pinned Lean exporter transport.
- remaining `@proofscript/*` directories — package-boundary scaffolds only unless their local README/source says otherwise.

## Trust rule

A support package may construct, serialize, elaborate, compile, transport, display, or orchestrate declarations, but it does not make them trusted. Logical authority remains pskernel admission.

Final Lean 4.34 has no in-kernel native compiler-evaluation extension. Compiler/backend packages remain outside the kernel TCB unless a future feature explicitly documents otherwise.

## When to enable workspaces

Only after:
1. canonical Full Std is closed or the current kernel API is otherwise frozen for the transition;
2. package names are intentionally chosen;
3. dependency cycles are reviewed;
4. root build/test behavior is reproduced under the workspace layout.

Until then, manifests are architectural scaffolds rather than installable release packages.


## Source language policy

Package implementation source is **TypeScript-first**.

- Author package code as `.ts`.
- Compile to ESM `.js` under `dist/`.
- Do not add hand-authored `.mjs` under `packages/` without an explicit architecture exception.
- Root `scripts/*.mjs` are separate oracle/CI scripts and are not covered by this package-source rule.

The root anti-drift check enforces this policy so new packages cannot silently bypass strict TypeScript checking.
