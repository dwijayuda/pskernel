# PSKernel-Fast V3 — G4.3b general-domain typing fragment

**Qualification:** independent, **restricted and non-authoritative** Lean 4.35.0-rc4 typing research. This is a verified source-to-**fragment-judgment** vertical slice, NOT a general Lean kernel, full DefEq, proof admission, or model soundness theorem.

- **Exact qualifying code SHA:** [`253afb42b477aacab22def288a2dd42d7ca9633b`](https://github.com/dwijayuda/pskernel/commit/253afb42b477aacab22def288a2dd42d7ca9633b).
- **Completed Actions run:** [38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150), job `114403520665`, **success**.
- **Toolchain:** pinned Lean `4.35.0-rc4` at upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Observed gate:** 54 successful Lake build jobs, audit of 22 independent V3 Lean sources, all existing G1–G4.3 smoke suites plus dedicated G4.3b general-domain `Pi`/lambda/application/restricted-let tests and input/output scope-certificate checks.

## Exact rule support and semantic authority

The owned modules are [`GeneralPiFormation.lean`](src/PSKernelFast/GeneralPiFormation.lean) and [`GeneralPiFormationSmoke.lean`](src/PSKernelFast/GeneralPiFormationSmoke.lean). The source-matched inductive `GeneralPiRule` has six constructors:

1. **Sort:** validated named universes, `Sort u : Sort (succ u)`.
2. **Bound variable:** look up an original validated binder domain and lift its de Bruijn indices by `index + 1`.
3. **Dependent Pi:** only when both domain and codomain actually infer types *syntactically* shaped as `Sort u` and `Sort v`; construct `Sort (imax u v)`.
4. **Lambda:** check the domain as a type, check the body in the extended context, construct the resulting dependent `Pi` type.
5. **Application:** infer a function with a syntactic `Pi` type; infer the argument; require actual `DecidableEq KExpr` proof of **exact** argument-type/domain equality; instantiate the result type capture-avoidantly.
6. **Restricted let:** only `nondep=false`; independently check the declared type has a Sort type, the value has that exact declared type, and the body under the extended binder; instantiate the dependent result type. `nondep=true` is explicitly unsupported pending exact Lean flag treatment.

`GeneralPiContextWF` records the type-formation of each nested binder domain from actual preceding certified inferences. The runtime wrapper `GeneralPiContext.extend` cannot add a domain unless `inferGeneralPi` returns a `Sort`-shaped type certificate. This is an **experimental restricted context**, not a protected production kernel environment.

The **compiling** theorem `inferClosedGeneralPi_sound` states that a successful actual value-only closed inference has a separately specified `GeneralPiRule` witness and satisfies G3 closed-input structural validity. `inferClosedGeneralPiCertified` adds an independently executable **OUTPUT** scope/level-parameter check, and its dependent success type carries all three exact results: structural source validity, structural inferred-type validity, and `GeneralPiRule`. A failure is `malformed`, `malformedResult`, or `unsupported`. The source term, candidate checked context, and inferred type are not permitted to authorize a theorem.

## Executed examples

- Type formation of `∀ (A : Sort 1), ∀ (x : A), A` with a **non-Sort syntactic domain** `x : A`.
- Pi expressions used as validated function-domain types, nested dependent references and symbolic universe parameters.
- The dependent identity lambda `fun (A : Sort 1) (x : A) => x`, with the inferred `Pi` type computed from recursive body checking.
- Exact-type application with dependent result-type instantiation; a higher-universe identity applied twice to Sort terms.
- Restricted let whose inferred function type depends on the substituted binder value.
- Explicit malformed/out-of-context variables, unknown symbolic universes, nonfunction application, mismatched argument type, unsupported nondep-let/constructors and source/output certificate validation.

## Assurance and completeness boundaries

**Still unproved and unimplemented:**

- This fragment's **type-preserving substitution theorem**, its implementation refinement to a full Lean kernel, end-to-end checker/model soundness, relative consistency or any complete proof-acceptance contract.
- Typed WHNF/DefEq, semantic conversion beyond exact syntactic equality, symbolic Level `isEquiv/isGEq` completeness, proof irrelevance, eta, delta transparency, constants, literals, recursors, quotients and inductive checking.
- A production immutable checked declaration environment, axiom-policy assurance, nonforgeable checked-result/session identity, runtime proof admission, exact Lean interchange, formal resource bounds and real kernel-only performance measurements.
- Official Lean 4.35 **differential results on the new typed corpus**. Its rules were studied at the exact upstream `src/kernel/type_checker.cpp`, especially `infer_pi`, `infer_lambda`, `infer_app`, `infer_let` and `infer_type_core`; passing these unit fixtures is NOT an independent oracle replay.

An `unsupported` result is **not** a proof of type inequality or Lean rejection; e.g. a Lean-valid DefEq convertible type may not have the same syntactic AST. Only exact positive syntactic agreement is used as equality evidence.

**No G4.4 completion claim:** the existing architecture reserves G4.4 for typed WHNF/DefEq, proof irrelevance and eta. This completed *G4.3b* experiment is preparatory, not evidence of that later stage or native/JS/Wasm self-hosting.

## Failed candidates and provenance

- `ff23ed8` [run 38116105991](https://github.com/dwijayuda/pskernel/actions/runs/38116105991): an implicit Lean parameter metavariable in the source proof wrapper prevented elaboration, fixed by pinning `params` and transporting inferred equality. No semantic rule weakened.
- `68107d6` [run 38116170732](https://github.com/dwijayuda/pskernel/actions/runs/38116170732): semantic module compiled; test harness contained a parser-hostile multiline error, fixed at green `2354bce` [run 38116230816](https://github.com/dwijayuda/pskernel/actions/runs/38116230816).
- `b74aa19` [run 38116362287](https://github.com/dwijayuda/pskernel/actions/runs/38116362287): green lambda introduction.
- `8e6665c` [run 38116477676](https://github.com/dwijayuda/pskernel/actions/runs/38116477676): green exact-type application; new `DecidableEq` instances for KExpr/binder/literal.
- `61eb3a9` [run 38116633427](https://github.com/dwijayuda/pskernel/actions/runs/38116633427): green restricted let.
- `9ed4580` [run 38116800825](https://github.com/dwijayuda/pskernel/actions/runs/38116800825): green closed input+output scope-certified boundary.
- `253afb4` [run 38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150): final green source, test and stage-label qualification.

Next choose the **one** trusted conversion path: exact and positive-sound symbolic levels, typed WHNF/DefEq with proof irrelevance and version-specific Lean 4.35 primitive behavior, explicit context/env/cache identity; then show accepting-rule refinement and official Lean differential results. Do not prematurely merge into PSKernel Core, claim general `FullyChecked`, or admit any theorem.
