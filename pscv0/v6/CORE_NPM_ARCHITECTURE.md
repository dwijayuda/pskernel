# PSCV V6 — Lean-native core npm architecture

**Status:** P0 native Lean implementation. Compiler implementation and extension-policy logic are written in .lean. npm is a distribution layer, not a compiler implementation language.

## Read first

- [Lean-native code-reuse research](LEAN_NATIVE_REUSE_RESEARCH.md) is the detailed source audit and implementation plan.
- [Normative PSCV language reference](../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) owns .ps grammar, logical meaning and certified-profile gates.
- [V6 compiler reference](../THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) owns the standalone compiler architecture.

## Package architecture

| npm package | Lean code | Initial native capability |
|---|---|---|
| @proofscript/pscv-core | packages/core/src/Pscv/Core/Model.lean | Small Init-only source/profile contracts; does not import full logical checker |
| @proofscript/pscv-extensions | packages/extensions/src/Pscv/Extensions/Policy.lean | Typed extension classes, reject in-process authority and closed-profile syntax changes |
| @proofscript/pscv-kernel | packages/kernel/src/Pscv/Kernel | Lean 4.35 checker and small pinned-provider catalog; no PSCV certification |
| @proofscript/pscv-cli | packages/cli/src/PscvDevMain.lean | Small native development tool without full Lean kernel import; incomplete compilation commands rejected |
| @proofscript/pskernel-lean | packages/pskernel-lean (complete copied tree) | Existing pinned Lean 4.34 native kernel npm provider, bundled artifacts and integrity checking |
| @proofscript/pskernel-lean-wasm | packages/pskernel-lean-wasm (complete copied tree) | Existing pinned Lean 4.34 Wasm kernel npm provider, bundled Wasm artifacts and integrity checking |

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

## Provider reuse and V6 ownership

The working `@proofscript/pskernel-lean@4.34.0` and `@proofscript/pskernel-lean-wasm@4.34.0` packages are now direct **npm workspaces within V6**. Their complete Git trees are preserved exactly as copied. Reuse their existing source, prebuilt native/Wasm binaries, protocol `pskernel-lean/1`, integrity manifests and public npm exports instead of rebuilding kernels from scratch.

The current Lean-written `Pscv.Kernel.ProviderCatalog` encodes the original exact identities without importing the heavy checker into the small native CLI. The existing provider APIs run actual candidate-admission tests from local V6 packages, including proof acceptance and rejection. Package-install scripts never authorize source semantics; provider IDs and responses are separately checked by the provider APIs.

**Critical limitation:** the V6 normative semantic reference uses Lean 4.35rc3; copied providers use Lean 4.34. Thus the provider API is an operational 4.34 kernel checker but **not** yet the authorized V6 verified-profile provider. Source elaboration correctness, assumptions, certificate creation and backend preservation are separate checks. A production native provider-neutral subprocess adapter remains to be implemented, with provider-binary hash and protocol verification, an explicit checker identity and no user-controlled binary override.

Old compiler `.lean` implementations may be imported or extracted as migration candidates when their semantic and dependency contracts are verified. Do not treat a legacy filename, a modern npm manifest, or a passing build as proof of PSCV V6 language-conformance. V6 reference architecture decides authoritative boundaries, not a rule to rewrite working code for appearance.
