# PSKernel-C0 — Proof-Carrying Trusted Foundation and Assumption Audit

**Checkpoint:** 2026-10-14 (Asia/Jakarta)  
**Scope:** native Lean 4.35.0 PSKernel-C0 only  
**Repository/branch:** `dwijayuda/pskernel` / `perf/pskernel-c0-v7-rust-20261012`  
**Status:** source-checked admission, trust-capability tracking, exact axiom-signature matching and incrementally maintained Lean audit proofs implemented. Not a consistency or kernel-soundness theorem.

## 1. Motivation: a checked environment does not imply an axiom-free environment

The native source kernel can legitimately admit an axiom whose proof is not
constructed by inference or DefEq. An admission history establishes that
each declaration passed the source checker; it **does not** establish that
the full environment is assumption-free, consistent, or independent of
trusted primitives.

`Architecture/TrustedAdmission.lean` therefore carries a dependent
history from the **literal empty source environment**, where each transition
contains an equality witness of the exact source-admission function's
successful result. The history is preserved across trusted source WHNF,
inference, full checking, DefEq, and verified syntax staging. Failed source
admission or checked-root publication produces no successor.

`Architecture/AuditedAssumptions.lean` adds a second,
caller-selected **explicit trust policy**. This layer cannot bypass source
checking or authorize a candidate WHNF expression.

## 2. What requires authorization

### Ordinary axioms: the entire signature, not just a name

An approved axiom is an exact `PsKernelAxiomInfo` declaration. Structural
DecidableEq matches its name, universe-parameter list, complete source
proposition type (including all binder annotations), and `isUnsafe` flag.
Approving a name **never** approves a different proposition at that name.
The checked history retains these exact source requests as
`psKernelC0HistoryAxiomSignatures`; the human-facing list of names is
display-only, never an authorization predicate.

This is designed to support pinning source-exact mathematical foundations
such as `propext` without allowing an unrelated axiom to reuse its name.
No specific mathematical axiom is silently auto-approved.

### Additional trust capabilities

The distinct `PsKernelC0TrustCapability` cases are:

| Capability | Source admission request |
|---|---|
| `quotientBootstrap` | Eq-dependent intrinsic Quot initialization |
| `unsafeAxiom name` | An explicitly unsafe ordinary axiom, in addition to its exact signature |
| `unsafeDefinition name` | An unsafe definition |
| `partialDefinition name` | A partial definition |
| `unsafeOpaque name` | An unsafe opaque declaration |
| `unsafeInductive name` | Unsafe ordinary, mutual or nested inductive family member |

Safe definitions, opaques and inductives still require full source
admission, but do not create those extra trust events. A request with
multiple unsafe mutual/nested family members requires approval of every
member. The default `AuditedSourceBegin` has **no** additional capability
permissions. In particular, a valid Eq does **not** implicitly authorize
Quot: an explicit `quotientBootstrap` permission is required in addition
to successful source checking of Eq and the Quot definitions.

Quot bootstrap and ordinary axioms are different trust categories; neither
is silently counted as a theorem proved by the source checker.

## 3. Proof-carrying invariant and scalable update

`PsKernelC0AuditedSourceWork` carries proofs that every historically
admitted exact axiom signature and every historically admitted capability
occurs in its respective approved list. Those are Lean propositions with
decidable, structural membership.

- **Initial certification/policy changes:** scan the entire immutable checked
  history, then construct the two proofs. A requested widening or narrowing
  is an explicit action and cannot silently skip existing assumptions.
- **Steady-state declaration admission:** reject unapproved incoming
  signatures/events before source admission; run the original source-admission
  function; inspect the exact checked result's request; extend the previous
  proofs with only that event batch via `List.all_append`. This avoids
  quadratic repeated scans as large libraries add declarations.
- **Steady-state source WHNF/infer/full-check/DefEq or syntax staging:**
  transport the complete proof bundle along a Lean equality witnessing the
  **identical environment**, rather than recomputing the assumption ledger.
  Syntax staging still recertifies its changed canonical store.
- **Closed-root publication:** the original checker still validates every
  selected root, allowed universe parameters, and full term types; approved
  axioms cannot turn a locally typed `fvar` into a closed publication.

The direct membership theorems expose that every exact admitted axiom and
every trust event is approved. A further empty-policy theorem establishes
that an audited history with zero permissions contains zero source-admitted
ordinary axioms and zero tracked extra capabilities.

**These proofs do not mean the underlying native source checker is sound,
that ordinary built-in type theory is consistent, or that its imported
dependencies have an independently verified trusted computing base.**

## 4. Native acceptance evidence

- [CI 38482323697](https://github.com/dwijayuda/pskernel/actions/runs/38482323697):
  source-authoritative audited axiom history.
- [CI 38483637367](https://github.com/dwijayuda/pskernel/actions/runs/38483637367):
  additional Quot/unsafe/partial capabilities, real checked Eq → Quot.
- [CI 38484100584](https://github.com/dwijayuda/pskernel/actions/runs/38484100584):
  source admission's per-step incremental permission-proof extension.
- [CI 38484334563](https://github.com/dwijayuda/pskernel/actions/runs/38484334563):
  proof transport across immutable-environment source judgments and staging.
- [CI 38484442675](https://github.com/dwijayuda/pskernel/actions/runs/38484442675):
  regression with 24 safe checked definitions and a separate full audit of
  the final history, including unsafe-axiom preflight.
- [CI 38484702307](https://github.com/dwijayuda/pskernel/actions/runs/38484702307):
  full axiom-type/universe/safety signature matching and negative checks.

- [CI 38485235073](https://github.com/dwijayuda/pskernel/actions/runs/38485235073):
  complete successful native qualification of direct history-membership
  and zero-permission/no-admitted-event mathematical theorems.
- [CI 38485455649](https://github.com/dwijayuda/pskernel/actions/runs/38485455649):
  complete family-wide unsafe mutual/nested capability enforcement.
- [CI 38485620934](https://github.com/dwijayuda/pskernel/actions/runs/38485620934):
  the **latest fully qualified executable** at
  [`572c99a7`](https://github.com/dwijayuda/pskernel/commit/572c99a78834bc1219fc462046b023fad1b762f5),
  including a matched incremental-vs-whole-history audit microbenchmark.

**Observed audit microbenchmark:** after 96 safe source-checked definitions,
112 identical native source WHNF queries consumed 1 ms with incremental
admission-proof transport and 3 ms with full-history re-audit after each
query. This is a single millisecond-resolution timing sample on one native
CI runner—not proof of worst-case complexity, throughput at millions of
declarations, or speed relative to Lean/con-leche/con-ron on matched
whole-checker workloads.

Each qualifying workflow also includes the official Lean 4.35 accepted/rejected
export fixtures, negative kernel tests, C0 architecture regressions,
microbenchmarks, and independent original-versus-C0 checker comparison.

## 5. Open final acceptance requirements

This audit applies only to histories built by the new trusted-source
genesis/admission API. It does not validate arbitrary externally supplied
source environments or import histories whose declaration proofs and
assumption manifests are unavailable.

Remaining higher-level gates include an independently proved relationship
between executable source kernel checks and their intended type-theory
semantics; a complete admission/policy manifest for any externally imported
standard environment; proof of the claimed StoreWF and checker refinement
properties; an independent optimized accepting kernel; complete pinned
Lean Init/Std/Mathlib compatibility; competitive fully checked performance;
and formal soundness/consistency claims with a transparent, exact trusted base.

Never treat policy approval, a source-check equality receipt, source WHNF
agreement or successful CI differential tests as an independent soundness
proof. Never weaken soundness, rejection, resource classification, or the
pinned Lean source semantics to produce a green test.
