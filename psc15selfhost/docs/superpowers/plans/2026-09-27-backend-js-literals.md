# Direct JS literal slice implementation plan

> Execute inline using the executing-plans and test-driven-development skills.

Goal: implement the first fail-closed VerifiedIR -> JsIR -> ESM slice in PSC1 `.lean`.
Spec: `../../design/PSC2_BACKEND_JS.md`.
Architecture: independent optional backend, never a dependency of the current TS root.
Tech stack: Lean 4.34 bootstrap, PSC1 source compiler, Node ESM, TS differential oracle.

## Global constraints

- User explicitly authorized parallel implementation before the TS freeze on 2026-09-27.
- That exception permits development, not authority cutover or merge without gates.
- Portable production code is PSC1-subset `.lean`; JS scripts only orchestrate tests.
- Preserve VerifiedIR, compiler admission boundary, TS bootstrap closure and existing gates.

## Review focus

Test unescaped/injected names, duplicate exports, lossy large integers, mistyped literals,
and unsupported nodes that otherwise might be silently omitted.

## Task 1: Literal backend and executable differential tests

Files: `packages/backend-js/{package.json,src/Ps/BackendJs/{Model,Lower,Emit,Module}.lean}`;
`test/BackendJsTests.lean`; `scripts/backend-js-tests.mjs`; `lakefile.lean`; `package.json`.

Interface: `psJsEmitModule : PsVerifiedIrModule -> Except PsJsError String`.
Internal: `psJsLowerModule : PsVerifiedIrModule -> Except PsJsError PsJsModule` and
`psJsEmitTargetModule : PsJsModule -> String`.

- [ ] Add Lean fixtures plus Node execution assertions for Nat/Int beyond 2^53,
      Bool, Unicode/control strings, Unit, deterministic output and empty modules.
- [ ] Run RED before implementing; missing backend is the expected first failure.
- [ ] Implement typed JsIR literals, validated ASCII export names, duplicates,
      strict literal/result-type agreement, and rejection of every unsupported IR shape.
- [ ] Run Lean fixtures and import output with Node; compare to compiled TS output.
- [ ] Audit source, dependency boundaries and unchanged TS closure.

## Task 2: Executable PSC1 source gate and branch CI

Files: `scripts/check-backend-js-source.mjs`, `scripts/check-backend-js-dependencies.mjs`,
branch CI, workspace layout mapping, continuity/design documents.

- [ ] Resolve the backend import closure using the workspace mapping, reject host/other
      backend dependencies, and invoke the actual PSC compiler on the flattened source.
- [ ] Compile generated canonical `.ps` backend when the seed supports the closure;
      report any seed blocker separately from the Lean/runtime slice.
- [ ] Add CI commands which execute the real gates, with no success placeholders.
- [ ] Run existing structural gates and relevant regression suites, review changes,
      commit and push only `psc2/backend-js`. Do not merge.

## Execution ledger

Ruling: implement ahead of Generation A freeze on explicit user instruction; keep the
TS root unchanged. Risk is future integration drift, controlled through isolation and
re-running gates against the eventual frozen base.
