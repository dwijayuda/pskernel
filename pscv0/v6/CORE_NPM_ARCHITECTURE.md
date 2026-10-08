# PSCV V6 — Lean-native core npm architecture

**Status:** P0 native Lean implementation. Compiler implementation and extension-policy logic are written in .lean. npm is a distribution layer, not a compiler implementation language.

## Read first

- [Lean-native code-reuse research](LEAN_NATIVE_REUSE_RESEARCH.md) is the detailed source audit and implementation plan.
- [Normative PSCV language reference](../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) owns .ps grammar, logical meaning and certified-profile gates.
- [V6 compiler reference](../THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) owns the standalone compiler architecture.

## Package architecture

| npm package | Lean code | Initial native capability |
|---|---|---|
| @proofscript/pscv-core | packages/core/src/Pscv/Core/Model.lean | Lean.Declaration-based immutable candidate model |
| @proofscript/pscv-extensions | packages/extensions/src/Pscv/Extensions/Policy.lean | Typed extension classes, reject in-process authority and closed-profile syntax changes |
| @proofscript/pscv-kernel | packages/kernel/src/Pscv/Kernel/Checker.lean | Official Separate native Lean 4.35 kernel checker, including closed-profile axiom/unsafe declaration rejection; not PSCV certification |
| @proofscript/pscv-cli | packages/cli/src/PscvDevMain.lean | Small native development tool without full Lean kernel import; incomplete compilation commands rejected |

Build these using the pinned root lean-toolchain and lakefile.lean. npm package manifests currently ship Lean source; real native platform artifacts will be added only after measured binaries and release tests. Node .mjs is permitted for external provider oracle tests or thin launch shims but must not implement compiler, kernel authority, grammar or passes.

## Critical trust laws

1. Only the selected kernel checks Lean Core declarations; candidate Core objects and serializable reports cannot mint CheckedCore or PSCV-CERT.
2. Source-to-Core elaboration must preserve exact PSCV source semantics; using Lean.Expr avoids duplicating kernel Core but does not automatically prove frontend correctness.
3. Verification profile and normative standard environment are exact and pinned; Lean 4.34 provider outputs cannot silently certify a Lean 4.35-rc3 PSCV program.
4. No npm install, manifest, syntax rewrite, tactic, optimizer or backend may change checked meaning or approve a false theorem.
5. Untrusted feature implementation is authored in Lean but compiled into an isolated native/Wasm worker. Never link arbitrary third-party extension code into the authority process.
6. Verified compilation requires separately checked approved specifications, proof obligations (.proof.ps or .proof.lean), assumptions, erasure, runtime/IR and target preservation policy.
7. The four future first-class backends remain TS, direct JS, Wasm and Rust. Lean's native compiler is the **build host for the compiler**, not a substitute for the four backends.
8. Self-hosting is optional later work. Old PSC1 source restrictions are not carried over as new compiler constraints.

## Current evidence and limitations

Native Lean unit smoke checks a genuine theorem candidate and a false proof term with official Lean kernel. Extension policy tests deny E5/E6 and closed-profile E1 source syntax. Independent 4.34 native/Wasm provider packages run via separate npm oracle tests.

No arbitrary .ps file can yet be parsed/elaborated/compiled by this P0. No compliant PSCV standard manifest, checked proof bridge, runtime codegen, certified build, plugin sandbox or published npm native distribution is claimed.

## Reuse vs replacement

Extract old source spans/lexer/diagnostics selectively, old TypedIR/validator/ABI/backend code when their dependency and semantic mapping is established, and old negative-conformance cases as fixtures. Prefer Lean.Expr/Declaration/Environment to maintaining a redundant PsExpr foundation; prefer official Lean metavariable handling rather than copying a standalone old inference/defeq engine. Do not preserve legacy bootstrap or handwritten source patterns solely for history.

See detailed matrix, staged engineering gates and explicit performance/security criteria in LEAN_NATIVE_REUSE_RESEARCH.md.
