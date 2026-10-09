# Kernel research and PSC0 migration — 2026-10-10

## Exact research identities

- PSKernel proof source: 85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62.
- PSKernel Arena baseline: 132d817071cd62c23a70c15984d6c73e14d6e856.
- PSC0 base: e356162ddf1d0780337b2f510925455c70fb658d.
- Requested Lean target: 4.35.0-rc4, c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
- Lean development head inspected separately: 5e96ee1153f945234f126ed024043a0697c9d6f3.
- Con Leche source inspected: 65e74db49e89ad2bbd1e90aa4f784954db41fa3a.
- Arena: b83254de5146ef34147ab82a48edbe1856b0edcc.
- Arena's Con Leche pin: 67f04630d88718e81aa4d07ab64501f68f105398.
- Nanoda: 4c544ed4099c8227f07d5de77ad1e69fb0740a27.
- Lean4Lean Arena: bce3448115f7819fc12d647fadd3bb090666637e.

The latest stable Lean release at inspection was 4.34.1. The user explicitly
selected 4.35.0-rc4. Development-master changes are research material, not the
selected semantic target.

## Confirmed defects and fixes

### Speculative Nat evaluation

PSKernel's psKernelReduceNatWith normalized both arguments of every binary
constant application, then checked whether the constant was a supported Nat
operation. It also evaluated the right operand before discovering that the
left operand was not a numeral. The official checker dispatches by name
first, and exits on a non-numeral left operand.

This is an algorithmic evaluation-order defect, not simply a too-small timeout.
The fix limits operand normalization to the supported operation names and
short-circuits on the left operand. Poison-callback regressions detect both
unwanted evaluations; existing numeral guards and error propagation remain.

Source comparison:
https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp
https://github.com/dwijayuda/pskernel/blob/132d817071cd62c23a70c15984d6c73e14d6e856/psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Checker/Reduction/KernelReductions.lean

### Actual 4.35 semantic change

Comparing every direct src/kernel file between 4.34.0 and 4.35.0-rc4 found
two changed files: type_checker.cpp and environment.cpp. The first removes
compiler-backed native reduction; the second corrects an external function's
return declaration from uint8* to uint8. Runtime/compiler/prelude changes
outside src/kernel still require the new toolchain and fresh conformance.

psKernelReduceNative now always returns no reduction, even if a legacy caller
supplies an evaluator. A theorem discharges its soundness obligation without
assuming a native evaluator. The regression installs callbacks that fail if
invoked. Updating only the version string would have been insufficient.

https://github.com/leanprover/lean4/commit/2a7175c74ba17b160299accd7e6ea6984d7ea86f

## Architectural comparison

| Area | Official Lean / Con Leche / Nanoda | PSKernel finding |
|---|---|---|
| Hashing | Stored per-expression hash; constant-time lookup key preparation | Recursive expression/name/level hashing |
| Equality | Identity/hash rejection and sharing-aware fallback | Structural recursive comparisons |
| Binding metadata | Cached loose-variable information | Repeated structural scans |
| Substitution | Memoized DAG traversal; unchanged terms reused | Tree-style structural substitution remains |
| Memoization | Separate inference/checking modes; explicit state scope | Conservative free-variable exclusion and bounded key traversal |
| Definitional equality | Pair-query cache; no transitive union-find inference | Existing pair-set design should be preserved |
| Verification | Con Leche proves accepting-direction consistency relative to its set model and restricted axioms | PSKernel concrete refinement is substantial but final semantic closure is still unfinished |
| Parallelism | Arena Con Leche and Nanoda use four workers | PSKernel is currently sequential |

Sources:
https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Cached/StateC.lean
https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Expr.lean
https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/README.md
https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/expr.rs
https://github.com/digama0/lean4lean/blob/bce3448115f7819fc12d647fadd3bb090666637e/Lean4Lean/TypeChecker.lean

Con Leche's public Arena page reports full Init, Std, and Mathlib acceptance
at its Arena pin, in verified mode with four workers. Those wall times are not
a controlled speed ratio against PSKernel. Its axiom policy and metatheory
also differ: do not transplant its consistency statement or unrestricted
performance shortcuts into PSKernel.

The 256-node cache eligibility policy materially improved one Init prefix,
but does not supply constant-time metadata. Free-variable cache exclusion
must not simply be removed: cache validity must account for local-context
changes and inference mode. Hash equality must never substitute for term
equality. Imported serialized metadata must be checked/recomputed, not trusted.

## Evidence gates and next research

The initial migrated revision is a candidate until its exact cloud checks pass.
No copied receipt, old green workflow, or diagnostic timeout certifies it.
Tutorial contains both expected accepts and expected rejects: require all 141
correct verdicts, not 141 acceptances. Historical bugs require all 18 results;
the known rec-missing-ih decline is explicitly tracked, never counted as a reject.
Full Init/Std acceptance requires the complete stream, not a prefix.

After measuring the dispatch fix, prioritize a portable representation with
constructor-maintained hashes and variable summaries, DAG-aware substitution,
and precise cache scopes. Prove the representation/erasure relation and
collision handling before adoption. PSC0's richer bounded profile permits
clearer structural workers, but does not itself establish computed-field or
pointer-runtime support. Parallel checking is a later optimization requiring
an explicit environment-installation/checking argument.

Preserve the latest metatheory when moving source. Do not overwrite the selected
PSC0 compiler seed or promote this package as its default provider merely
because native tests pass. The standalone package pin permits kernel work
under 4.35 while compiler seed reproduction remains separately pinned.
