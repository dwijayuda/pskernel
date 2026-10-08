# PSCVL — Lean-powered ProofScript/PSCV frontend (experimental)

**Status: executable frontend + experimental verification preflight, NOT full PSCV v1 conformance or a certified compiler.**

Source: [normative PSCV language reference](../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) §2, §8–10, §21, §28–32 and Appendices A/F/I/J. Compiler architecture: [PSCV V6](../pscv0/THE_PSCV_COMPILER_REFERENCE_VERSION_6.md). Pin: **official Lean 4.35.0-rc3**. This is a **separate Lean-powered experiment** from V6's eventual standalone-native PSCV compiler, not a revision of its accepted architecture.

**Proposed future compiler architecture:** [ProofScript PSCV — Lean-Powered Native Compiler Architecture](PROOFSCRIPT_PSCV_LEAN_POWERED_NATIVE_COMPILER_ARCHITECTURE.md). It includes a pinned Lean 4.35.0-rc3 source-code reuse inventory, closed grammar and deterministic elaboration constraints, PSCV-CERT-v1/native gate, implementation milestones, and a standalone `psc` SDK packaging plan. **Design only; not yet a native compiler or certification result.** The PSCV V6 proposal remains a separate workstream.

From `PSCVL/` with the pinned Lean toolchain installed:

```sh
lake build
lake exe pscvl check examples/normative/pass_minimal.ps
lake exe pscvl check examples/normative/pass_strict_binders.ps
lake exe pscvl check-preview examples/pass_language.ps
lake exe pscvl check-preview examples/pass_state.ps
lake exe pscvl check-preview examples/pass_while.ps
```

The CLI distinguishes source profiles:
- `lake exe pscvl check FILE.ps` uses the **new strict, still incomplete PSCV RC-v2 source-fragment gate**. Known Lean-only syntax is rejected before elaboration. Green output remains **UNCERTIFIED**; it is not proof of full Appendix-A conformance.
- `lake exe pscvl check-preview FILE.ps` uses the **older bounded Lean-compatibility prototype grammar**, explicitly *not* the PSCV Standard source profile. Existing examples that rely on indentation-only native Lean `by`/`do` run here.
- `lake exe pscvl syntax-kinds FILE.ps` inventories accepted parser kinds without elaborating source. This is for building a recursive grammar whitelist.

See [NORMATIVE_ALIGNMENT.md](NORMATIVE_ALIGNMENT.md), which binds this effort to the exact committed normative RC-v2 source.

The CLI accepts only `check`, `check-preview`, or `syntax-kinds` for a `.ps` input file. A successful check prints **UNCERTIFIED**. It does not generate native code, a Lean module, `.olean`, a `PSCV-CERT-v1`, or any executable artifact. No verified emission occurs.

## Implemented in Lean (.lean)

- `PSCVL/Syntax.lean` adds bounded ProofScript spellings: `const`, `function f(x: A, y: B)`, implicit/instance binders, explicit defaults, the optional-`Unit` zero-source-argument convention, adjacent curried calls `f(a,b)` with a bounded named-argument suffix, a finite `refine type` to Lean `Subtype`, and one-sided/two-sided `requires`/`ensures` function syntax. Braced single-expression and `if (c) {a} else {b}` forms are supported. The strict-implicit owned binder now uses the normative ASCII `{{α : Type}}`, and anonymous instance binders use `[C α]`. Not all PSCV grammar forms exist.
- Lean's native `def`, `theorem`, `example`, `structure`, `inductive`, `instance`, `match`, total recursion, dependent types and tactics cover their Lean-compatible subsets. This is *not* a faithful implementation of every PSCV-specific lexical/layout/grammar restriction.
- The pinned Lean `Std.WP` intrinsic `given`/`requires`/`ensures`, proof-only `assert`, owned `ghost` lowering, and preview-only annotated `for`/`while` can produce checked specification theorems and reject open verification conditions. Current exercised effect families include `Id`, `StateM`, `ReaderM`, and concrete `Except`; a typed-error clause is available for concrete `Except` results. These relations have kernel-checked correspondence theorems to the pinned Lean WP instances. The upstream facilities are experimental; PSCV verification semantics must be frozen and validated independently.
- `PSCVL/Grammar.lean` checks a conservative set of *top-level* Lean AST command kinds before elaboration; rejects source imports, parser/extension commands, several proof escapes and unapproved attributes. This now has a stricter default that rejects known Lean-only indentation proof/do syntax and native equations, but **does not fully restrict nested expression, tactic, notation, or macro syntax** to Appendix A. Source is trusted input; it is not a sandbox.
- `PSCVL/Policy.lean` requires at least one `@[pscv_export, pscv_type_spec]` root, rejects local `axiom`, `unsafe` and `partial` declarations, checks local declarations' transitive axiom use (allowing only `propext`, `Quot.sound`, `Classical.choice`), and rejects directly `noncomputable` executable roots and direct raw-`IO` export types. This is **preliminary** and not a dependency/effect-closure certification.

`pscv_type_spec` is only a developer annotation, **not an externally approved spec identity**. Lean kernel acceptance and theorem closure are **not** proof of application-level specification coverage or compiler preservation.

## Implementation and conformance boundaries

See [CONFORMANCE.md](CONFORMANCE.md) for a chapter-to-feature matrix and evidence status. Significant incomplete work:

1. **Exact grammar** of source, term, proof, and verified-do clauses; typed named/default calls, groups, closed options/attributes/notations, and import/module graph (current module imports are intentionally blocked).
2. **Verification semantics** independent of experimental Lean drift: complete given/requires/ensures, frame/reads/modifies, typed errors, `old`, `ghost`/noninterference, contracts at call sites, effects WP-law evidence, and explicit `verify` attachment.
3. **Approved specification and assurance:** immutable approved identity/digest, full exported API coverage, proof and assumption closure across imports, all reachable effects, proof replay, noncomputable/FFI closure and checked erasure.
4. **Actual compiler**: validated checked executable IR, native code production only after PSCV-CERT gate, compiler-preservation evidence, backend/runtime mappings, independently replayable certification.
5. **Trust and distribution**: extension isolation/capability policy, dependency identity, deterministic build outputs, npm integration and full conformance testing.

The CI workflow tests the supported positive fragment plus negative policy and verification cases. Passing those examples is not language coverage or certification. **Do not treat this prototype as production assured code.**

## Development principles

Use GitHub as source of truth; implement reusable feature families and their tests rather than patches for individual examples. Do not alter the existing PSCV compiler or PSKernel-owned kernels. Never permit source options or extensions to strengthen proof authority, and never unblock executable emission based only on an annotation or a successful Lean check.
