# PSKernel-C0 — Certified Indexed Stores and Atomic Checked Publication

**Status:** implementation and native regression checkpoint · **Date:** 2026-10-14  
**Repository:** `dwijayuda/pskernel` · **Branch:** `perf/pskernel-c0-v7-rust-20261012`  
**Language/toolchain:** native Lean 4.35 · **Scope:** `psc0/packages/pskernel-c0/`

## 1. Architecture objective

The existing C0 indexed-expression representation provides persistent/scratch
stores with deterministic whole-index replay validation. The previous
architecture repeatedly rechecked that entire store for every source WHNF,
inference and DefEq operation, even though these operations changed only the
source checker state and the syntax store was an immutable value.

The certified layer makes an **immutable replay-validation certificate** part
of the Lean type of a store, root, and work transaction. It preserves that
certificate by construction on source checked-session updates. It does not
create new proof-checking rules, replace the native source checker, use
candidate WHNF as an authority, or accept arbitrary numeric handles.

## 2. Data and proof invariants

`Core/CertifiedStore.lean`:

| Value | Explicit Lean witness | What it means |
|---|---|---|
| `PsKernelC0CertifiedStore` | `psKernelC0ReplayValidateStore store = true` | Entire deterministic canonical replay predicate succeeded on one immutable store |
| `PsKernelC0CertifiedRoot` | In-bounds and `psKernelC0DecodeExpr store id = some expression` | A root belongs to its attached store and has exact decoded source syntax |
| `PsKernelC0CertifiedTransfer` | `psKernelExprEqual source.expression target.expression = true` | Both separately owned, replay-certified roots agree under the exact metadata-sensitive source-syntax equality predicate |

Certificates can be constructed only after the corresponding executable
validation succeeds (or by supplying an actual Lean proof). They do not
convert a store hash, radix-bucket match, or bare `Nat` handle into typing
evidence. Rehoming encodes the certified source expression into the selected
destination store, revalidates the result, and records exact syntax agreement.

**Formal boundary:** A Lean proof of the *executable validation predicate*
is not yet a mechanized theorem that this predicate entails every desired
mathematical `StoreWF` property. The truth of `psKernelExprEqual = true`
is a certified Boolean test, not yet a separate theorem establishing
propositional equality of all source expressions. Phase G retains these proof
requirements.

## 3. Proof-carrying checked transactions

`Architecture/CertifiedWork.lean` binds the complete
`psKernelC0ArchitectureWorkValid raw = true` predicate to the immutable
transaction. The checker can subsequently perform source WHNF, inference,
DefEq, isProp, full term checking, and source-first typed-demand observation
without re-running whole-store replay when **only the checked session
changes**. No speculative reduction result becomes a trusted judgment.

Operations that change indexed syntax do not simply transport this proof:
staging and atomic admission both recertify the resulting state. All source
declaration families continue to use their existing independent checker and
preserve source environment/cache revision semantics. Failed admission leaves
the original work unchanged.

`CertifiedWorkStageRoot` returns a source-root certificate for newly staged
syntax. `CertifiedWorkCheckRoot` performs **full source checking** on the
certified root's exact decoded expression; certification alone cannot make
an ill-typed de Bruijn variable or an untrusted proof term valid.

## 4. Source-checked publication is all-or-nothing

`psKernelC0CertifiedWorkCommit` is **syntax-only** promotion: a malformed
type is not rejected simply for being staged.

`psKernelC0CertifiedWorkCommitChecked` is the stronger optional publication
operation. It validates and promotes selected roots to an immutable candidate
store, then runs the source declaration-level checks for free variables,
metavariables and permitted universe parameters, followed by **full source
term checking for every selected root**. It returns the store and a
`PsKernelC0SourceCheckedRoot` witness **for each root** only when all checks
succeed; one failure returns an error and does not publish a partially
accepted result. The input transaction and its persistent prefix remain
immutable.

Each witness contains its exact owner-bound decoded expression, active
source-checker context, pre-check state, checked fuel, resulting type and
post-check state, with an actual Lean equality proof:
`psKernelCheckerCheck fuel context stateBefore root.expression =
  .ok (checkedType, stateAfter)`.
This records one real full source-check result, not a guessed or synthesized
typing judgment. In a successful batch the witnesses are produced in source
order using the evolving checker state. It is still **not** an independent
proof that the source checker implementation is sound.

A term may be well-typed in a **local hypothesis context** while being
ineligible for closed publication; the publication path rejects such `fvar`
terms. Bare syntax hashes, candidate WHNF, and type inference alone cannot
bypass this gate. These source-check equality witnesses are context- and fuel-bound evidence
of the actual source checker result; they are not independently verified
kernel soundness proofs or universally portable executable-artifact receipts.

## 5. Native regression and negative cases

The mandatory `test/C0CertifiedWorkRegression.lean` checks:

- Certified canonical store construction and total exact-root readback.
- Corrupt node/checker hashes, invalid handles and forged radix-index entries
  cannot acquire a replay-validation certificate.
- Independent stores with different binder metadata remain distinct;
  cross-store transfer preserves exact source syntax after re-encoding.
- Staging an unbound `bvar` is valid syntax but fails full source checking
  and fails atomic checked publication.
- Full checking on certified valid source sorts returns the correct type.
- A locally inferable `fvar` and an undeclared universe level cannot escape
  the global checked-publication boundary.
- Mixed valid/invalid selected roots fail the whole publication without
  mutating the persistent prefix.
- Repeated source WHNF, inference, DefEq, full checking, isProp and
  source-authoritative typed-demand queries preserve transaction validity.
- Admission remains source-checked, refreshes the source checking cache, and
  rejects duplicate declarations.

The full native workflow continues to run official same-byte positive and
negative Lean export fixtures, architecture/source differentials, malformed
kernel cases, C0 native microbenchmarks and independently rebuilt
original-versus-C0 checker comparison.

## 5A. Matched source-operation overhead benchmark

`test/C0CertifiedWorkPerfMicrobench.lean` runs exactly the same source
WHNF and DefEq operations against a large validated shared-DAG store,
comparing the prior replay-per-query work interface with the new
certificate-preserving interface. The timings are recorded by one
native Lean process and are informational: this is not a proof of a speedup,
nor a matched Lean/con-leche/con-ron whole-workload comparison.

## 6. Exact remaining scope

This milestone improves **Phase C representation provenance** and
**Phase E source-checked transaction integration**. It does not establish:

- A formally proven mathematical `StoreWF` theorem or a proof of
  `psKernelExprEqual` soundness.
- A full independent accepting optimized WHNF/DefEq/inference checker.
- Runtime-accurate peak-memory accounting of Lean's internal allocations.
- Full Lean 4.35 Init/Std/Mathlib same-byte acceptance.
- Competitive whole-checked-workload performance or formal soundness
  and refinement assurance.

The CDE-9 base and closed-publication regressions passed native
[CI 38472570733](https://github.com/dwijayuda/pskernel/actions/runs/38472570733).
The newer source-check equality-witness and matched source-operation
benchmark regressions require their own complete native CI qualification. The latest independently
qualified predecessor is tracked in `AI_WORK_STATE.md`. No original
`pskernel-core`, PSC0 compiler, Rust/Wasm, or self-hosting change is involved.
