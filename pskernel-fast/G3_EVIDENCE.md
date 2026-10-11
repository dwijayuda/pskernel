# G3 structural preflight — pinned evidence

**Source:** [`f767415fc1d1824ae50ab83b73f67e8cd8b21e21`](https://github.com/dwijayuda/pskernel/commit/f767415fc1d1824ae50ab83b73f67e8cd8b21e21).  
**Cloud:** [GitHub Actions run 38108276674](https://github.com/dwijayuda/pskernel/actions/runs/38108276674), job `114378309523`, **passed**.  
**Target:** Lean `4.35.0-rc4` pinned `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Exact scope:** nine V3 standalone Lean modules audited for no legacy imports; 23 native build jobs succeeded; G1, G2 and G3 small smoke suites executed successfully.

## Implemented structure

`CoreSyntax.lean` represents the official core's syntax categories—names, universe levels, bound/free/metavariables, sorts, constants, application, lambda/Pi/let, Nat/String literals, metadata marker and projections—**without** being a checker. Binder styles include the official recursion annotation under V3's `recursive` name. The actual Lean metadata map is not yet faithfully imported (placeholder opaque tag).

`ULevel.validParams` prevents undeclared universe parameters or universe metavariables in checked *input preflight*; `KExpr.validAt` handles binder depth and excludes free/metavariables from closed declaration input. It does not establish type correctness, referenced constant existence or correct universe parameter arity. Ground `imax` is compared to official `Lean.Nat.imax` over **400** combinations, but symbolic `max/imax` normalization and universe equivalence remain open.

## Proved structural claims

The separately authored `CoreSyntaxProofs.lean` constructs:

- `ULevel.WellFormed` and theorem `ULevel.validParams_sound`.
- `KExpr.StructurallyValid` and theorem `KExpr.validAt_sound`.
- `KExpr.closedInput_sound` connecting actual top-level input check and binder/level preflight.

The name type derives **lawful Boolean equality**, allowing logical universe parameter membership to be distinguished from unproved hash/index equality. No `sorry`, new logical axiom or old proof import was needed. These theorems are **not** formal soundness of a type checker or DefEq evaluator.

## Negative implementation and proof-status facts

- No environment-backed typed constant lookup, checked inference grades, symbolic definitional equality, recursor/quotient admission or public theorem acceptance.
- No full Lean 4.35 differential library, Init/Std/Mathlib replay, full relative consistency/model theorem or formal lazy WHNF refinement.
- G2 beta-only performance remains exploratory, and no native-to-JS/Wasm self-host qualification has been performed.
- A preceding G3 candidate first lacked `LawfulBEq KName` and a later candidate needed explicit theorem goal exposure. Those cloud runs failed; they are recorded in `AI_WORK_STATE.md`, not presented as successes.

The current milestone is **structural correctness groundwork only**. Next authority for checked behavior requires G4's exact type/DefEq/admission specification and source-matched positive/negative oracle cases.
