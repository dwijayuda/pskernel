# PSKernel-C0 — Nonadmitting safety provenance for Lean 4.35 Arena

**Status:** qualified PR [#115](https://github.com/dwijayuda/pskernel/pull/115), merged at `84fee9c0470aa45166b620e1c07f6c84241cefbc` · **Pinned Lean:** 4.35.0, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

## Proven defect and official rule

The archived Lean Kernel Arena `tutorial/140_falseFromUnsafe` and `tutorial/141_falseFromPartial` were both previously `c0_unsupported`, even though official Lean 4.35 rightly rejects the theorem's attempted proof dependence. The original source declarations are unsafe or partial, so the adapter's earlier `if safety != "safe" then unsupported` returned before encountering the theorem.

The actual pinned Lean C++ implementation, `src/kernel/type_checker.cpp::infer_const`, rejects an unsafe constant when the checked context is not unsafe, and rejects a partial constant in a safe context. Its `environment.cpp::add_theorem` invokes a fully checked safe typechecker. These are independent necessary conditions; **neither ordinary unsafe definitions nor ignored executable source are automatically logical contradictions**.

## Resolution and trust boundary

`test/C0OfficialNdjsonReplay.lean` introduces `C0ExportDeclaration.nonlogicalDefinition (name,safety)` as **source provenance, never a checked kernel declaration**:

1. Read the original 3.1.0 definition fields completely, including name and safety mode `unsafe` or `partial`. Unknown safety labels still fail closed.
2. Do **not** execute/check/admit these definitions into the original C0 kernel environment. Track only their source names and modes in the portable replay session.
3. When a later checked-safe theorem mentions a prior blocked definition anywhere in its type or proof tree (apps, lambda/Π, lets, metadata, projections), return a genuine `rejected` result via the source-grounded **forbidden unsafe/partial reference** rule. Ordinary source checking still handles all unrelated declarations.
4. An export containing a blocked definition without a proven forbidden safe use remains `unsupported` upon completion; it is never accepted by omission.
5. Retained whole-batch and online replay follow the same logic. Source checker fuel, cache layout, trust assumptions, import version gate, and atomically admitted environments remain unchanged.

The new constant-reference traversal is **conditional on non-empty blocked provenance**. In the overwhelmingly common valid, safe Lean 4.35 Init/Std/Mathlib exports there is **no extra proof-expression traversal or new successful cache entry**.

## Independent evidence

Native differential [39012466755](https://github.com/dwijayuda/pskernel/actions/runs/39012466755) and [39012415247](https://github.com/dwijayuda/pskernel/actions/runs/39012415247) succeeded:

| Native pinned test | Official Lean 4.35 | PSKernel-C0 |
| --- | --- | --- |
| `C0ArenaSafetySafeAccept.ndjson` | accepted | accepted |
| `C0ArenaSafetyUnsafeReject.ndjson` | rejected | rejected |
| `C0ArenaSafetyPartialReject.ndjson` | rejected | rejected |
| `C0ArenaSafetyUnsafeDecline.ndjson` | not asserted | unsupported |

The exact full historical-body [4-shard CI 39012466756](https://github.com/dwijayuda/pskernel/actions/runs/39012466756) also succeeded: `176/193` independently matching real Lean-4.35/C0 acceptance/rejection, `17` still-unqualified, zero observed mismatched checked verdicts, **193/193** byte-identical historical bodies. Both previously unqualified Arena safety negatives truly rejected by each checker.

**Limitations:** the CI adapter's historical source-header substitution is transparent and test-only. This does not establish actual unsafe executable support, the validity of any untrusted definition, general kernel soundness/consistency, the remaining `rec-missing-ih` generated-recursor-rule negative, full Init/Std/Mathlib compatibility, or performance parity.

## Next source-grounded work

The one remaining negative semantic debt case involves a historical generated recursor whose step minor premise expects an extra IH but whose RHS omits it. The pinned Lean C++ `inductive.cpp::mk_rec_rules` appends **every** original field argument and recursively constructed IH to the minor premise application. Study whether the required minor-premise arity can be validated independently from the exported recursor type/RHS without trusting the exporter and without treating an unsupported nested source as proof of invalidity. Preserve exact source syntactic names, binder shifts, conditions, recursor rule order and helper APIs.

The other 16 Arena debt cases are resource/reference limitations; solve their source-checker hot paths with precise same-input/fuel CPU and memory measurements, not synthetic acceptance via increased budgets.
