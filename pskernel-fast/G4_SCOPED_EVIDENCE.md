# G4.3 scoped binder frame — exact source and proof evidence

**Source:** [`df800d5f390e36a0c807bd88397221adce488394`](https://github.com/dwijayuda/pskernel/commit/df800d5f390e36a0c807bd88397221adce488394)  
**CI:** [run 38110413629](https://github.com/dwijayuda/pskernel/actions/runs/38110413629), job `114384612773`, **PASS**.  
**Toolchain:** Lean 4.35.0-rc4, `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Validated gate:** 45 native build targets, 18 independently audited Lean V3 source files, G1/G2/G3/G4.0/G4.1/G4.2/G4.3 focused suites and exploratory toy beta benchmark all passed.

## Actual correctness properties

`ScopedFrame params depth` is an **indexed** immutable binder sequence whose extension constructor demands an actual `KExpr.StructurallyValid params depth domain` proof. `AnyScopedFrame.extend` invokes the executable `KExpr.validAt` check and constructs the corresponding proof via the previously validated `KExpr.validAt_sound` theorem.

- `ScopedFrame.rawDomainAt_top` proves exact raw top-domain retrieval; no implicit shift or typing assertion is made.
- `AnyScopedFrame.extend_depth` proves successful frame extension increases its indexed depth by exactly 1.
- Smoke tests cover three nested binder scopes, retrieval at valid/invalid depths, immutable parent preservation, undeclared universe parameters, escaped bound indices and unsupported free/metavariables.

These proofs establish a meaningful scope invariant **for the structural frame**, but not actual dependent typing of those domains. A term from `rawDomainAt` is observed in its original insertion context and **MUST** be shifted/instantiated before using it as a type under newer binders. V3 deliberately exposes no such unchecked type-authoritative operation.

## Remaining kernel requirements

- Correct capture-avoiding shifting/opening/closing and context-sensitive local-type inference.
- Symbolic universe `isEquiv` and `isGEq` full compatible decision strategy; the current positive-only subset has 8 fixture oracle positives unresolved among 1296 comparisons.
- Complete checked-vs-infer-only grades and validated expression type/annotation witnesses.
- Definition/axiom/opaque/theorem/inductive/quotient admissibility, transaction atomicity and explicit axiom-model consistency policy.
- Actual Lean 4.35 external export replay, performance measurements of REAL kernel checking, and independently qualified native/portable backends.

**No theorem-admission API exists.** The project remains an experimental soundness-oriented substrate, not yet a complete Lean 4.35 kernel.
