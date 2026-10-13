# PSKernel-C0 — Intermediate Rewrite Resource Accounting Audit

**Status:** implemented candidate syntactic-work accounting, native qualification pending on current executable head.  
**Kernel pin:** Lean 4.35.0 · **Scope:** `psc0/packages/pskernel-c0/`  
**Authority:** source `psKernelSessionWhnf`, inference, DefEq and checked admission only.  
**Non-goal:** This is **not** a demonstrated bound on all Lean runtime heap allocations, nor a kernel soundness/refinement proof.

**Qualification:** executable [`bf95088c`](https://github.com/dwijayuda/pskernel/commit/bf95088c338c8e9b8dda7686ce8f26e4f323dac6) — **full [native CI 38459330291](https://github.com/dwijayuda/pskernel/actions/runs/38459330291) SUCCESS**. This qualifies the candidate abstract syntactic-work accounting and regression coverage described here, **not a proven Lean runtime peak-heap bound or theorem-checker replacement**.

## 1. Resource contract

The experimental candidate execution has two independent finite limits:

* **Transition fuel** decreases with each demand-machine transition, including entering and resuming nested premises.
* **Syntactic-work quota** decreases throughout the *same operation*, without per-argument/per-frame reset. This is a deliberately conservative abstract work measure. It charges traversed expression nodes, numeral bytes, UTF-8 names and literals, bound/free-variable identifiers, universe-level syntax, active and saved closure environments, preflight rewrite work, metered intermediate quotation and the complete resulting machine state. Final readback receives **only the remaining quota**.

A larger quota may yield a candidate observation; insufficient quota produces an **untrusted candidate decline**, never a logical rejection. Source WHNF is computed independently first in `ObserveDemandMetered`; only source checked operations can return the checked next session. The legacy non-metered evaluator stays experimental and does not enter admission.

## 2. Per-rewrite coverage

| Family | Before constructing/inspecting | Result/post-transition work |
|---|---|---|
| Applications, β, ζ, metadata | Active expression, delayed argument syntax and binder environments; one fuel unit | Fresh control, pending arguments and saved frames charged before continuation |
| Local lets and neutral heads | Source control/local-context syntax, captured values | Result closure or stuck syntax charged; no acceptance from candidate |
| δ and unfolding | Source definition body, universe-substitution tree and expanded application spine; metered reification of the current machine | Instantiated definition/body control and arguments charged |
| Nat successor and all 14 binary Nat primitives | Metered operand readback and operand-dependent numerical-work allowance; pow/shift growth reservation | Nat numeral payload bytes and next machine state charged |
| Constructor projection | Metered scrutinee quotation, including captured environment | Selected field, captured application tail and continuation state charged |
| Quot.lift/Quot.ind | Metered normalized major and saved eliminator/function argument readbacks | Function application/representative and remaining spine charged |
| Ordinary non-K recursor iota | Metered major and saved parent quotation, exact source rule RHS, occurrence universe levels, fixed/constructor/surplus argument construction | Instantiated rule application and continuation syntax charged |
| String literal elimination/projection | UTF-8 byte charge and pre-expansion `String.ofList` reservation | Expanded source syntax and resumed result charged in the same operation |
| Final readback | Source expression, quoted captured environments, conservative duplication/lifting reserve and application-spine nodes | Final result returned with remaining quota, or explicit candidate decline |

**Cost semantics:** Nat payloads and Nat name components charge source numeral-storage bytes; String/name segments charge UTF-8 bytes; level max/imax/succ/param and constructor metadata are recursively traversed. Work can be intentionally overcounted where source syntax is reused or a speculative rewrite is not taken. It must not be undercounted at a metered readback or returned candidate state.

**Important limitation:** several source helpers (`psKernelUnfoldDefinition`, `psKernelReduceNatBinary`, `psKernelExprInstantiate`, and recursor RHS instantiation) still allocate temporary Lean values internally. The preflight is an abstract conservative reservation, not instrumentation of every heap allocation. It does **not** establish a runtime memory cap or full peak allocation bound. It can be conservative enough to decline a candidate even when the source checker completes.

## 3. Single-operation ownership and invariant

`psKernelC0DemandRunWithBudget` owns the remaining work quota and calls, in order:

1. Charge active control, delayed environments and saved continuation-frame syntax.
2. Reserve String expansion, source δ and recursor RHS/universe substitution/app construction.
3. Reserve intermediate quotation and primitive computation work for the **active** head and pending Nat frame.
4. Invoke the **existing** candidate demand transition; never duplicate acceptance semantics.
5. Charge every reachable expression in the newly materialized state *before* any following transition.
6. Finally quote through `psKernelC0QuoteMachineMetered` using only the quota returned by the transition loop.

No step intentionally increases the quota; every helper returns `Option Nat` or a resource decline. The result is an observable candidate value, never a proof receipt. Source error classes and checked-session state are not changed by candidate exhaustion.

## 4. Negative and differential gates

Mandatory `C0ArchitectureBudgetRegression.lean` includes:

* Exact source-node, numeral byte, UTF-8 String/name and universe-level costs.
* Nested, wide and repeated captured substitutions, binder metadata preservation, saved frame and delayed-argument work.
* Low-quota failures for string expansion, δ body, polymorphic levels, recursor rule RHS, arithmetic growth and saved continuation.
* Quotation under projection, constant-head δ and recursor parent frames; intermediate materialized state charge.
* Nested Nat.pow beneath an outer Nat continuation, ensuring its inner growth is still preflighted.
* Source WHNF agreement for metered β/ζ, safe δ and Nat primitives; quota-only declines must not change source checking.
* The entire native CI continues to run official positive/negative export fixtures, kernel negative/semantics checks, microbenchmarks and comparison with an unchanged rebuilt original kernel.

## 4A. Additional bypass checks closed in CDE-8A.4

CDE-8A.4 closes four previously missed accounting cases: **blocked**
recursor/Quot child resumption quotes its saved parent/function through the
same metered readback helper as ordinary halted children; **nested Nat**
primitive computation is preflighted at the *active* head before resuming
any outer Nat frame; **polymorphic δ and ordinary iota** account for nested
universe-substitution syntax and subsequent application construction; and
**recursive names** spend their component cost before descending, stopping
deep untrusted names at a finite quota.

The budgeted result continues to charge newly generated intermediate syntax
before the next transition and gives final readback only the remaining quota.
These are regression-tested syntactic-work properties, not Lean-runtime peak
heap/CPU guarantees. Executable commit `bf95088c`, native
[CI 38459330291](https://github.com/dwijayuda/pskernel/actions/runs/38459330291)
is the full qualification gate.

## 5. What remains for a stronger claim

The **syntactic-work contract** covers the candidate transition families named above when entered through the opt-in metered runner. This is different from proving `allocated_bytes <= quota` for a concrete runtime.

To claim an exact heap/CPU resource bound, introduce budget-aware constructors and allocation wrappers into every source primitive, substitution, universe-instantiation and recursor helper (or instrument the Lean runtime allocator), with verified amortized cost proofs. Tie these to all checked-session policies, whole-library conformance and formal refinement. Those stronger gates remain open; no candidate may authorize theorem/declaration acceptance in the meantime.

Keep Phase B full real Init/Std/Mathlib acceptance, Phase F comparable workloads and Phase G soundness/refinement gates unchanged.
