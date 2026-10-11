# P1g — Tagged Proposition Interpreter and Checked Source Requalification

**Status: GREEN — narrowly scoped, conditional tagged proposition model.**
This is proof-only set-model mathematics and independent checked-source evidence.
It is NOT a proof-admitting kernel, a general model of Lean terms, or a
relative-consistency theorem.

## Verified source / exact cloud evidence

- Repo: `dwijayuda/pskernel`, branch `research/pskernel-fast-clean-v3-20261011`.
- **Qualified source:** [`8cc2d41aee99ec82fc2fbcd265c11875d4581590`](https://github.com/dwijayuda/pskernel/commit/8cc2d41aee99ec82fc2fbcd265c11875d4581590).
- [GitHub Actions **run 38133327235**](https://github.com/dwijayuda/pskernel/actions/runs/38133327235), job `114451991620`: **completed SUCCESS**; exactly pinned **Lean 4.35.0-rc4** upstream source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **96 Lake build jobs**, **44 independent Lean source modules** checked by the source boundary audit, **129 exact #print-axioms theorem-assumption receipts** in a fail-closed allowlist of `propext`, `Classical.choice`, and `Quot.sound`; no `sorryAx`. The existing focused G1–G4.3b smoke suites and exploratory beta benchmark ran successfully.
- Previous green P1f policy [run 38129970282](https://github.com/dwijayuda/pskernel/actions/runs/38129970282) remains the pre-P1g baseline (94 jobs, 42 modules, 110 receipts). The P1g code did not edit running G4.3b source, kernel admission or old proof branches.

## One tagged semantics tier for NEW proofs

- [`Spec/TaggedPropSemantics.lean`](src/PSKernelFast/Spec/TaggedPropSemantics.lean) uses the **P1f-proven** `taggedPoint/taggedTrue/taggedProp/taggedSortSet`, not the provisional true value in P1d/P1e. It defines only one new tagged proposition-valued Pi semantics, a new `interpTaggedProp` for the pre-existing `PropInterpTerm` source-independent syntax, and explicit `TaggedPropPiFibresValid`.
- It proves tagged Pi membership, exact truth condition, counterexample false, two-valued range, and the semantic membership of its tagged interpretation conditional on separately valid fibres. The two concrete source fragments now have **independently proved** semantic fibre validity and new **false** denotation for `∀(P:Prop), P` and **true** denotation for `∀(P:Prop), P → P`.
- The tagged false formula has no inhabitant; the tagged true set has **exactly the distinguished tagged proof point** as its inhabitant. These are mathematical statements about these two interpreted proposition values, **not** a typed source proof-term soundness theorem.
- [`Proof/TaggedPropModelBridge.lean`](src/PSKernelFast/Proof/TaggedPropModelBridge.lean) gives a general source-judgment-backed Prop-Pi rule **conditional on explicitly validated fibres** and proves for BOTH actual `inferClosedGeneralPi` successes: exact checked annotations, exact source and inferred-type erasure, exact symbolic `imax` Prop regime under any level valuation, model membership under the new tagged carrier, and their distinct false/true interpretations. No theorem delegates its new true/false value to the old `interpProp`.
- The older `sortSet/propPi/interpProp` and older P1e examples remain compiled strictly as **historical, provisional reference evidence**. The canonical tagged source-model proofs are explicitly named and isolated; complete retirement or replacement of the old interpreter is **OPEN**. No runtime rule or trusted conversion is changed.

## Mathematical assumption / nonclaims

All semantic set-theoretic claims remain conditional on **caller-supplied `[SetTheoryBasis V]`**. No constructed instance, global model-existence proof, new model axiom, general term soundness, proof irrelevance for checked proof terms, Type-valued dependent graph Pi, beta/let semantic preservation, checked quotient-slot freshness, `WellDenoted` induction, full WHNF/DefEq, checked declaration environment, model-preserving extension, kernel consistency or Lean 4.35 full compatibility follows.

P1f's exact graph/pair/numeral anti-collision proofs are retained. A GLOBAL arbitrary-image or arbitrary-quotient freshness claim is false; source-typed writable slot restrictions are a future theorem obligation, not an extra assumption.

## CI diagnostic provenance

- Initial [run 38133021503](https://github.com/dwijayuda/pskernel/actions/runs/38133021503) built the old 94-job closure but failed while the audit compiler's output was redirected to a temporary file. The workflow now logs compiler diagnostics and explicitly builds both new proof modules.
- [Run 38133151703](https://github.com/dwijayuda/pskernel/actions/runs/38133151703) exposed four restricted-simplification mismatches between raw `SetTheoryBasis.member` and its definitional `Mem` wrapper. Normalizing P1g semantics to the P1f raw membership convention resolved these without modifying mathematical statements.
- [Run 38133250018](https://github.com/dwijayuda/pskernel/actions/runs/38133250018) confirmed the tagged semantics built, but reported the same definitional wrapper mismatch in its bridge. The bridge was normalized to the same raw convention.
- Final [run 38133327235](https://github.com/dwijayuda/pskernel/actions/runs/38133327235) is GREEN, with both new files in the actual build DAG, all 129 assumption receipts and all focused regressions.

## Next mathematical milestone

P1h: introduce a **hereditary, model-environment-indexed WellDenoted relation**, derive binder-fibre evidence from source-certified typing where genuinely possible, and prove semantic laws for the actually executing Sort/bvar/Pi slice. Keep proof point/irrelevance, Type-valued Pi graph/eta/app, quotient guarded writability and general substitution/DefEq as separate typed obligations; never replace proof obligations with blanket freshness or untyped frontend hints. The future fast runtime remains unconstrained by proof-only research architecture.
