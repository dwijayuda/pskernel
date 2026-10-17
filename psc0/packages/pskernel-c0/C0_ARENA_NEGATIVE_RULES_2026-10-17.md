# PSKernel-C0 — Lean 4.35 Arena negative-root-cause corrections

**Date:** 17 October 2026. **Target:** native Lean 4.35.0, Git `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. **Scope:** adapter and independent reference harness, not the trusted C0 WHNF/DefEq/admission engine.

This continuation uses original, SHA-authenticated September 2026 Lean Kernel Arena NDJSON **declaration bodies** and a **test-only, explicitly disclosed version-header adaptation**. Genuine Lean 4.35 source re-exports are covered by separate workflows. No test-only adapted file may be represented as a native 4.35 exporter artifact.

## Root-cause evidence

[CI 39008796107](https://github.com/dwijayuda/pskernel/actions/runs/39008796107) independently ran the 25 old unqualified negative cases under **official Lean 4.35** and **native C0**, capturing the exact C0 `--trace-declarations` failure reasons. The findings were not guessed from error categories:

| Original negative family | Observed C0 issue | Official Lean 4.35 source/invariant | Repair, deliberately narrow |
| --- | --- | --- | --- |
| Noncanonical recursor name manifests | `unsupported NDJSON recursor family is not canonical` | `src/kernel/inductive.cpp::mk_rec_name` produces exactly `I.rec`; non-nested ordinary/mutual groups generate one per inductive type | A wrong, duplicated or missing non-nested recursor name multiset is semantically invalid; nested families remain on their separate path |
| Duplicate declarations | Official `leanchecker` emits `uncaught exception: Duplicate declaration: <name>`; harness called this `official_driver_error` | `src/kernel/environment.cpp::check_name` raises `already_declared_exception` | Only this exact single-line, nonzero-exit official exception is a reference rejection; arbitrary crashes remain driver errors |
| Duplicate constructor identities | C0 labeled the second constructor's conflicting `cidx` as malformed | Official environment `check_name` prevents duplicate constructor constants | Exact duplicate *structural constructor names*, not hashes or IDs, are invalid |
| Forged constructor `numFields` | C0 independently generated a different count | `src/kernel/inductive.cpp::check_constructors` derives `num_fields = raw Pi arity - numParams` | On non-nested source, compare exported numFields with its own syntax telescope; only this proven mismatch rejects |
| Impossible K-like recursors | `unsupported generated recursor K/safety mismatch` | `src/kernel/inductive.cpp::init_K_target` requires exactly one inductive with one constructor, Prop result and no nonparameter fields | Any `k=true` with more than one inductive or constructor is invalid; no assumption that every single-constructor recursor has K |
| Invalid parametric large elimination | Recursor universe/type mismatch after checked generation | `src/kernel/inductive.cpp::elim_only_at_universe_zero` forbids large elimination for multi-constructor predicates whose result level may be zero | Extend the existing **specific** large-elimination guard from `Sort 0` to also cover bare `Sort u`; do not generalize to arbitrary `imax`, `max`, Π or nested groups |
| Bogus recursor type `False` | Generated recursor type differs | `src/kernel/inductive.cpp::declare_recursors` creates `mk_pi(info.m_major, C_app)`, then wraps it in further Π binders | A non-nested generated recursor whose *raw* declared type is not a Π binder cannot be valid |
| Orphan constructor | `malformed NDJSON constructor with unknown inductive owner` | Generated constructors are bound to exactly one family owner in `check_constructors` | Constructor with no declared family owner is semantically invalid; unrelated malformed JSON remains malformed |

These are **necessary conditions** for official generated declarations. They never grant acceptance. The common architecture is source-independent structural invalidity, not an opportunistic promotion of every C0 metadata disagreement. Unproved generalized recursor/K rules, all nested-inductive special cases, and unresolved unsafe/partial handling **continue to decline**.

## Corpus classification and regression policy

Initial 193-case baseline: **152 matching official/C0 verdicts** and **41 unqualified cases** (no observed false accepts/rejects) on [PR #112](https://github.com/dwijayuda/pskernel/pull/112). [CI 39009410983](https://github.com/dwijayuda/pskernel/actions/runs/39009410983) qualified the first eight recursor-name and duplicate-environment classifications, totaling 168 matched in that specific execution (two host-timeout outcomes also changed).

The current topic-branch ledger has been narrowed to **19 explicitly unqualified cases**, with **24 independently checked mandatory cases** (22 source-grounded negative targets plus the two genuine sparse-index positives). The final score and completion are **not claimed until the exact final-HEAD CI passes**. The 193-case aggregate retains the source-byte digest, all unique case IDs, reference and C0 verdicts, and strict no-false-acceptance/no-false-rejection gates. A new decline on any now-mandatory case is a CI failure.

### Explicit remaining work

The **three negative semantic gaps** cannot safely be resolved by the above rules:

- `bugs/rec-missing-ih`: nested recursive occurrence not supported by C0's source admission; implementing or formally excluding this family requires the proper nested checker/recursor path.
- `tutorial/140_falseFromUnsafe` and `tutorial/141_falseFromPartial`: current importer declines unsupported `unsafe` and `partial` definitions; a sound fix must carry safety provenance and ensure no logical theorem depends on such declarations.

The remaining **16 resource/reference cases** require different engineering: source-fuel exhaustion, C0 whole-operation timeouts, and two official-reference timeouts. They are **not** proof invalidity. Avoid raising C0 source fuel or weakening output gates just to improve apparent coverage. Instead profile repeated application checking, lambda/Pi inference, WHNF/DefEq and substitution; measure on exact same exported bytes with unchanged semantic budgets.

## Independent testing and guardrails

- Native 4.35 C0 `C0OfficialNdjsonReplay.lean` now contains direct classification regressions. Its existing forged-recursion metadata tests continue to forbid unexplained admission or rejecting arbitrary unsupported mismatches.
- `.github/workflows/pskernel-c0-arena-adversarial435.yml` requires an impossible canonical recursor-name/K flag to **reject**, but does not claim a generic generated metadata mismatch is invalid.
- `test/arena_435_oracle_unit.py` asserts that *only* exact official duplicate-name exceptions become reference rejections; unrelated exceptions stay errors.
- `test/arena_435_known_gaps.json` must list only actual **unqualified** outcomes. `required_correct_cases` must include every case promoted out of the ledger. The four-shard aggregate confirms all 193 original case identities and body SHA-256s are preserved.
- Evidence from official Lean 4.35 and PSKernel-C0 must be obtained on the same adapted case. Neither official 4.35 source-compatibility nor 193-case bounded pass proves kernel consistency, formal soundness or full Init/Std/Mathlib acceptance.

**Acceptance target for this change:** exact source and native CI green, official/C0 parity on all newly mandatory negative cases, no new false acceptance, and a deterministic remaining debt ledger. Record precise CI run IDs and counts in `AI_WORK_STATE.md` after verification.
