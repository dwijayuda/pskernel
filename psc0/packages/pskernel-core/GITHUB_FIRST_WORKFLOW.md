# PSKernel Core GitHub workflow for PSC0

## Proof-first consistency checkpoint — 2026-10-11

The user has explicitly deferred **all full Init/Std/Mathlib suites and full Init profiling** until PSKernel's full modeled environment and relative-consistency theorem are established. Commit [`10d4bf84`](https://github.com/dwijayuda/pskernel/commit/10d4bf84ffbb91f048cd5e7afc22ace2218c3613) hard-disables broad corpus jobs in the Lean 4.35 and extended-diagnostic workflows while keeping focused metatheory, type checking, axiom and dependency auditing and native regressions. [Cloud run 38075260577](https://github.com/dwijayuda/pskernel/actions/runs/38075260577) passed with broad corpus jobs skipped. Do not restart full corpora as an implementation-substitute or remove the CI guard before proof completion.

**Last fully validated new model source:** [`f644cef8`](https://github.com/dwijayuda/pskernel/commit/f644cef8c183bcb8bb0ec395828171077118bcee), [proof run 38075788368](https://github.com/dwijayuda/pskernel/actions/runs/38075788368): 268 build jobs (223 focused), 84 companion proofs, **331 axiom-audited semantic declarations**, 154 semantic model dependency modules (12 pinned Con Leche pure-math, zero checker-assurance imports), 1,840 reference definitions with zero cache fallback, and seven native test executables passed. The `SemanticEnvironmentModel.lean` file provides a fixed-annotation history/lookup model, derives a relative model for the actual successful empty public kernel session, and connects it to reference constant-inference under a then-explicit arity premise. This is a model of the **empty history**, not of a fully admitted Lean prelude or of a checked theorem.

**Current unqualified proof candidate:** source [`902f902b`](https://github.com/dwijayuda/pskernel/commit/902f902b96361a8b14943b02bef503671893b3c0), [audit run 38076656535](https://github.com/dwijayuda/pskernel/actions/runs/38076656535), whose result must be read before calling it validated. It adds a conditional modeled-environment no-stored-`False` theorem and removes the supplied arity premise using the actual reference inference success branch. The intermediate [run 38076107666](https://github.com/dwijayuda/pskernel/actions/runs/38076107666) found missing `List.map []` normalization; later [runs 38076280819](https://github.com/dwijayuda/pskernel/actions/runs/38076280819) and [38076396352](https://github.com/dwijayuda/pskernel/actions/runs/38076396352) found an unavailable `Nat.beq_eq_true.mp` name and an unclosed false-arity branch; these were amended in the candidate. Do not re-label failed runs as passes.

**Still missing for full metatheory/consistency:** prove the model is preserved by every successful actual safe declaration, inductive, recursor and quotient admission; establish the pinned primitive/`False` basis and modeled-axiom policy; carry fixed annotated readings and universe-zero regimes across the *joint* graded infer/WHNF/DefEq accepting path, including all shortcuts; then compose the real public reference acceptance theorem with the model and derive no-derived-`False`. Cached mode and JS/Wasm/native shipping backends require separate verified refinement. No runtime checker changes or newly asserted axioms have been introduced in this stage.


Repository: `dwijayuda/pskernel`.
Current development branch: `psc0/pskernel-core-lean435-arena-v1`.
PSC0 base: `psc0/architecture-plan-v1` at
`e356162ddf1d0780337b2f510925455c70fb658d`.
Kernel location: `psc0/packages/pskernel-core`.

Read the live remote head before work and before every branch update. Use
expected-head leases and preserve published branches. Keep coherent changes in
GitHub and run builds/tests in cloud CI. The user's current instruction excludes
local checkouts, builds, tests and repository files for this work.

Use the current PSC0 authoring guide linked in README. Historical PSC1 profiles,
4.34 receipts and old topic branches are provenance, not current constraints or
evidence for this migration. Keep fail-closed checking and one semantic source;
never patch generated JavaScript or use a fallback checker after failure.

The 4.35 workflow checks the toolchain identity, kernel build, main metatheory,
all 84 companion proofs, foundations, dispatch regressions, historical Arena
verdict coverage and fresh 4.35 exports. Source portability and joint generated
compiler/kernel qualification remain separately reported until established.
Do not silently promote a compiler seed or default provider.

Record exact source commits, binary identity, workload versions, complete
coverage and every failure/decline/timeout. A doc-only evidence commit may cite
an earlier tested code commit explicitly; do not describe it as a fresh run.
