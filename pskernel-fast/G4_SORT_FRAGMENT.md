# G4.2 — Certified Sort/Pi formation fragment (scope intentionally narrow)

Source: `src/PSKernelFast/SortFragment.lean`. Current stage is an independent formation-fragment pilot, not a usable Lean kernel or a substitute for checking arbitrary declarations.

Official 4.35 reference: [`type_checker.cpp::infer_type_core` and `infer_pi`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp).

## What can be inferred

- For well-formed `Sort u` under declared universe parameters, result is `Sort (succ u)`.
- For syntactically `forallE x (Sort u) (Sort v)` under well-formed levels, result is `Sort (imax (succ u) (succ v))`.
- Every success carries a dependent proof from the executing `inferSortShape` that the corresponding two-rule `SortFragmentRule` holds. `inferClosedSortFragment_sound` additionally connects successful execution to G3's proved closed-input structural validity.

The second rule is deliberately restricted to explicit sorts at both domain and codomain. It does NOT check dependent codomains containing the bound variable, constants, reductions, parameterized types, universe definitional equivalence or general type inference.

## Fail-closed behavior

Malformed/ill-scoped terms yield `FormationError.malformed`. Structurally valid terms outside this tiny subset yield `FormationError.unsupported`. Neither error is a false proof rejection/acceptance claim for the full language. There is **no theorem admission or checked declaration API**. No plugin or untrusted candidate catalog is allowed to manufacture a fully checked result.

## Next major implementation

Develop an exact scoped local-context representation and universe substitution, with a real environment and proper conversion. Extend inference across sort/Pi/lambda/application/let using the actual checking rules, not by loosening `SortFragmentRule`. Release any checked admission only after the full constraints, quotient/inductive rules and verified policy are implemented.

Evidence will be added to this file only after the corresponding source's Lean 4.35 cloud workflow passes.

## Validated cloud checkpoint (October 11, 2026)

Source `dc43ce850291dc5527c933a8f5d86c408c40eb27`, [CI run 38110171823](https://github.com/dwijayuda/pskernel/actions/runs/38110171823), job `114383914870`, passed all **40 native build targets**, independent source audit and formation regression tests. Exact theorem `inferClosedSortFragment_sound` compiled; this result is a *fragment*, not general Lean kernel correctness. See [evidence](G4_SORT_EVIDENCE.md).
