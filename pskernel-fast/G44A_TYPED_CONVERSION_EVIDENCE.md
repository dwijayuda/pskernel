# PSKernel-Fast G4.4a — Actual Checked, Fail-Closed One-Head Conversion

**GREEN and intentionally incomplete. Not full Lean 4.35 WHNF/DefEq and NOT proof-admission authority.**

## Exact qualified evidence

- Repository `dwijayuda/pskernel`, sole development branch `research/pskernel-fast-clean-v3-20261011`.
- First independently green G4.4a operational checker/certificate/proof/regression source [`e9d4d99c2df14fe2b9546973470e62c83bee6742`](https://github.com/dwijayuda/pskernel/commit/e9d4d99c2df14fe2b9546973470e62c83bee6742), [CI 38137265546](https://github.com/dwijayuda/pskernel/actions/runs/38137265546), **105 Lake builds, 49 source files, 154 audited theorem assumptions**.
- Zero-budget nonacceptance proof and first timing source at [`b96ffa0f00b3fa68631790ebeb46d6bd6539007b`](https://github.com/dwijayuda/pskernel/commit/b96ffa0f00b3fa68631790ebeb46d6bd6539007b), [CI 38137583782](https://github.com/dwijayuda/pskernel/actions/runs/38137583782), **108 builds/50 files/155 receipts**. The *constant-input, 20,000 iteration* timing print was 0 ms across all families and was **NOT ACCEPTED AS PERFORMANCE EVIDENCE**.
- Revised timing at [`fe0f53c693cd6ce4a6f1d0c88b77e37be59b6c40`](https://github.com/dwijayuda/pskernel/commit/fe0f53c693cd6ce4a6f1d0c88b77e37be59b6c40), [CI 38137855798](https://github.com/dwijayuda/pskernel/actions/runs/38137855798), **108 builds/50 sources/155 receipts**. Runtime-indexed 127-variety term arrays, 100,000 checked operations per family, `IO.monoNanosNow`, and independently checked counters; active operations timed but array lookup included.
- **Latest full source/policy baseline:** [`7dd6f175f57b3c091826c6e12391ada5139488dd`](https://github.com/dwijayuda/pskernel/commit/7dd6f175f57b3c091826c6e12391ada5139488dd), [**CI 38138084007**](https://github.com/dwijayuda/pskernel/actions/runs/38138084007), job `114466008004`, **SUCCESS**, pinned official Lean **4.35.0-rc4**, upstream SHA `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, **109 Lake builds, 51 audited independent Lean sources, 157 exact theorem receipts** and all prior G1–G4.3b smokes/bench targets passing.

## What really executes

[`src/PSKernelFast/TypedConversion.lean`](src/PSKernelFast/TypedConversion.lean):

- `HeadConversion` is an inspectable certificate for **exact reflexivity**, ONE literal head `(fun x => body) arg` beta contraction using the actual `KExpr.instantiateBVar`, or ONE `nondep=false` `let` zeta contraction. No recursive WHNF, no delta/iota, no proof irrelevance, eta, quotients, recursors or symmetric/transitive DefEq.
- `compareTypedHead` checks actual G4.3b source typing for **BOTH sides** in the same independently validated `GeneralPiContext`, rejects malformed terms before consuming budget, declines on zero budget, and **returns Equal only with the SAME exact inferred type and a real head contraction certificate**. Unsupported valid cases are `unresolved`, NOT semantically unequal.
- [`Proof/TypedConversion.lean`](src/PSKernelFast/Proof/TypedConversion.lean) proves the executable positive direction produces two `GeneralPiRule` derivations and an actual `HeadConversion` witness, plus **zero-budget cannot return Equal**. This is proof of a TINY operational reduction relation plus matching source typing, **NOT a set-theoretic denotation-preservation theorem or complete Lean kernel soundness proof**.
- [`TypedConversionSmoke.lean`](src/PSKernelFast/TypedConversionSmoke.lean) checks actual beta/let/reflexivity successes, one-way behavior, unsolved equality cases, unsupported constants, invalid binder scope, 0 budget and source-certified nonempty context.
- Executing G4.3b inferred typing rules are NOT modified, and no declaration checker/accept API is added; admitted declarations remain **0**.

## The first ACTUAL checked-operation timings (NOT competitive kernel results)

These are the nanoseconds per measured active loop operation from the single [latest green #38138084007](https://github.com/dwijayuda/pskernel/actions/runs/38138084007) GitHub runner, NOT a median or controlled comparison:

| Internally measured operation | 100,000 varied calls | Reported mean |
| --- | ---: | ---: |
| `ctx.infer` on beta source | 16,479,258 ns | 164 ns/call |
| Typed exact reflexivity | 55,334,098 ns | 553 ns/call |
| Typed head beta comparison | 34,256,147 ns | 342 ns/call |
| Typed head zeta comparison | 32,461,293 ns | 324 ns/call |

These measurements use input arrays of 127 prebuilt name-varied source expressions and `IO.monoNanosNow`; exclude fixture construction and process startup but include array lookup and actual executable checking. A preceding green [#38137855798](https://github.com/dwijayuda/pskernel/actions/runs/38137855798) produced broadly similar values (165/512/340/293 ns/call) but the experiments do NOT yet establish confidence intervals, kernel-only overall performance, equivalently capable workloads, official Lean comparison, allocation/RSS or Mathlib compatibility. Do NOT interpret the apparent fast numbers as "PSKernel-Fast beats Lean."

## Research / design boundaries

- Official Lean 4.35 [`src/kernel/type_checker.cpp`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp) is the semantic oracle for `ensure_pi`, typed application, WHNF and official DefEq rules. Our G4.4a deliberately covers only a syntactically exact subset.
- The future optimized kernel may use closures, DAG or flat arenas, but MUST produce results refining a pinned, proof-backed semantic authority (or use independently proven canonical rechecks). Proof-only reasoning must not add a runtime cost unless deliberately measured.
- Before claiming *true* WHNF/DefEq completeness, add resource-indexed multistep typed reduction, exact symbolic levels, transparency/checked immutable environment identity, proof irrelevance/eta, and all Lean primitives; confirm positive-result **set-model denotation preservation**, then matched official kernel conformance and CPU/RSS/allocations on actual checking.
- No global `SetTheoryBasis V` instance or model existence, relative `no_derived_False`, Type Pi or typed-quotient writable safeguard is obtained here. Model proof point representation and assumptions remain proof-only.
