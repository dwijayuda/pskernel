# `dag_app_binder`: the actual proof obligation (Lean 4.35)

Status: **open — genuine proof still unaccepted by C0 at published fuel 4096**.

## Authenticated shape of the original input

Upstream source is `leanprover/lean-kernel-arena/tests/perf/app-lam.lean` at `5d7ca987618f1136aaa296057b50a2c10c4ce77a`.

The declaration `dag_app_binder : Nat` builds `n=4000` layers:

```lean
body := .bvar (n - 1)
-- A left-associated Nat.add expression using all n bound variables.
for i in [:n] do
  let lam := Expr.lam (Name.mkSimple s!"x{n-i}") nat body .default
  body := mkApp2 (mkConst ``wrap2) lam lam
```

The two arguments at each `wrap2` level are the *same* lambda expression object. Each nested lambda's body references outer binders, so opening it requires capture-avoiding substitution. This alternates two application nodes with one binder at each level. An optimization restricted to **long application-head spines** cannot reach this structure.

Official Lean 4.35 `src/kernel/type_checker.cpp` handles consecutive lambdas with a telescope, checks application function and argument, uses WHNF for Pi exposure and kernel definitional equality for the domain, then performs capture-avoiding instantiation. A real C0 redesign must retain those semantic rules, including binder scoping, fresh-name provenance, safety and error precedence.

## Pinned ground truth

- Original September Arena body: SHA-256 `3f7b7a595dc29b0e289c9031c4edaef42d0e12b8aee3cbb48cf15cb715adc09a`; *only* first-line version-envelope adaptation is allowed for the historical 4.29.1 corpus.
- Official pinned Lean 4.35 independently accepts the exact adapted body.
- C0 at **source fuel4096** returns `C0ExportVerdict.resourceExhausted` for `dag_app_binder` in `body/full_check`, reason **kernel inference budget exhausted**. The separate, unqualified 8192 diagnostic also exhausts.
- Real runs: [39245777183](https://github.com/dwijayuda/pskernel/actions/runs/39245777183), diagnostic [39246222186](https://github.com/dwijayuda/pskernel/actions/runs/39246222186).
- The published C0 resource policy defines `fuel` as a **recursive bound**, not a total instruction count; default is 4096. Do not silently reset fuel on descendants, skip checked arguments, raise fuel, or reinterpret a timeout as an acceptance.

## Crucial logical distinction

The legacy fuel-4096 function **returns an error** on this source. Hence there can be **no theorem** asserting both
`newChecker(4096, dag_app_binder) = oldChecker(4096, dag_app_binder)`
and `newChecker(4096, dag_app_binder) = .ok result`.

Source-equivalence theorems for one application frame, or for substitution results, are valuable but *by themselves* cannot prove the required new positive judgment. A correct redesigned machine must establish a **fuel-independent typing soundness refinement**, or a precisely defined resource-accounting semantics in which iteration avoids recursive calls while retaining the published actual per-operation recursive bound. The latter is not permission to enlarge the logical recursion budget invisibly.

## Engineering and proof-critical path

1. Build a mixed **app/lambda explicit continuation machine**, not only the currently implemented application-spine fold. Keep the full typed state: original expression, scoped local context, fresh-name state, source-aware substitutions, and outstanding type/domain/error continuations. Share repeated DAG nodes only when their contextual typing judgments are *proved* reusable; source-pointer equality is only an index hint.
2. Provide a **closure-based substitute/instantiate** operation with exact de Bruijn-offset and sequential binder-opening proofs. Defer materialization only where the proof demonstrates its indistinguishability at the next inspection boundary.
3. Prove each transition preserves kernel typing, full checker state and error behavior when resource permits. Separately prove *successful* whole-machine outputs are derivable by the reference rules regardless of the old checker exhausting its recursion bound. No new `axiom`, `sorry`, nonlogical `unsafe`, unchecked provider or trust shortcut.
4. Author a strict pinned GitHub A/B: official 4.35 accepts same body; C0 complete `--require-accepted ... 4096` result must be exactly `C0ExportVerdict.accepted`. Log body SHA, original source policy, RSS and wall time. Before full semantic proof, new machine must remain non-admitting.
5. Follow with 193-case negative/differential corpus, original real Array proof and real selected PSC0 Core compiler closure. Timeouts, unsupported exports and proof failures remain unqualified.

**Gate:** This branch is not eligible to replace production C0 until steps 1–5 actually pass. Do not call it a source-proved `dag_app_binder` acceptance until the all-input semantic proof and the authentic strict replay both exist.
