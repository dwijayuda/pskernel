# Kernel research and PSC0 migration — 2026-10-10

**Stage checkpoint:** the PSC0 migration, Lean 4.35.0-rc4 build, main metatheory,
all 84 companion proofs, foundations and focused regressions pass. Broad corpus
conformance is **not complete**: Init times out, Std exhausts an internal
reduction bound, and Mathlib is gated off. Stop here before the next stage.
[MIGRATION_EVIDENCE.json](MIGRATION_EVIDENCE.json) records exact identities and
results, including the known historical bug decline.

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

## First passing code checkpoint

At code commit c3ce027239dad67983bc04ebc53d861ec29f559f,
[cloud run 37979443559](https://github.com/dwijayuda/pskernel/actions/runs/37979443559)
built the 4.35 candidate, passed foundation conformance and the poisoned-callback
Nat-dispatch regressions, built the complete metatheory, and checked all 84
companion proofs. Tutorial verdict coverage was 141/141 correct with zero
declines (mixed expected accept/reject inputs).

The exact native executable SHA-256 was
f7faafb345aba02950e1aaf6e6c0e6495ad613de0fad2253125457eef5e93c21.

Fresh exports using lean4export 05d43a2bc773b40ecfdebb32294192a5ef756951
and Lean 4.35.0-rc4 passed exact metadata checks:
- Prelude: 65,406 records, 1,840 declarations, 2,121 constants; 0.56 seconds,
  72,072 KiB maximum RSS.
- UTF8 assemble₃_eq_some_of_toBitVec dependency closure: 159,345 records,
  2,146 declarations, 2,353 constants; 8.45 seconds, 84,268 KiB maximum RSS.

The prior 4.34 focused UTF8 export timed out at 360 seconds. These are different
exports and toolchains, so this is not a controlled speedup ratio. Full Init/Std
and Mathlib evidence must be reported separately.

Initial CI failures exposed missing Lake reference/self-host roots, a removed
String.trim adapter API, stale version literals, and three companion proofs
that still unfolded the old cache policy. These were repaired without weakening
the theorem statements. The first bug-suite launch selected the nonexistent
group name "bugs" instead of "bugs/*" and ran no tests. Commit
05542332ab589314917cd67a7eb7b74e80557770 repairs the harness selection; it does
not alter the compiled kernel source.

## Specific next-stage work, ordered by evidence

1. **Expression metadata and sharing.** Cache.lean computes expression, level,
   name and string hashes recursively. The hash modulus is 65,521; collisions
   are resolved with equality, so a wider hash is a performance choice, not a
   semantic shortcut. Core/Expr.lean also recursively tests equality and loose
   variables. Design constructor-maintained metadata with a proved erasure
   relation and collision-safe equality before changing the representation.
2. **Substitution traversal.** Instantiate.lean first computes full tree node
   count to obtain fuel, then traverses again; Instantiate1 can scan for loose
   variables before both. Reusing unchanged nodes is already present, but it
   does not prevent repeated visits to shared subexpressions. Qualify the
   appropriate structural-worker form against the actual PSC0 frontend, or
   supply verified cached bounds and context-sensitive DAG memoization.
3. **Cache scope.** Preserve separate checked/infer-only modes and account for
   local contexts and environment changes. Removing the free-variable guard
   without these invariants would trade a performance limitation for unsound
   reuse. Keep pair-query caching for algorithmic definitional equality:
   arbitrary transitive union-find closure is not justified by its outcomes.
4. **Conformance and integration.** Resolve the known rec-missing-ih decline
   with precise diagnostics, continue complete corpus gates, and separately
   qualify generated PSC0 kernel artifacts before provider promotion.
   Arena timeout, resource failure, unsupported decline, invalid rejection,
   and export/build infrastructure failure are distinct outcomes.

These changes are not implemented in this stage. Increasing timeout or adding
threads alone does not remove the measured unnecessary work. Conversely, the
8.45-second fresh UTF8 result means it would be wrong to label every remaining
cost as the same original Nat-dispatch defect.

The richer PSC0 authoring profile helps write structural workers; its documented
Nat/List accumulator capabilities do not automatically certify arbitrary Expr
workers, Lean computed fields or pointer APIs. All profile claims remain bounded
by the current guide and the selected compiler's actual qualification.

## Corrected-run small-suite results

At 05542332ab589314917cd67a7eb7b74e80557770,
[run 37979868377](https://github.com/dwijayuda/pskernel/actions/runs/37979868377)
again passed the build, foundation regressions, all 84 companion proofs and
metatheory. Tutorial was 141 correct / 0 declined. The 18 historical bug cases
produced 17 correct rejections and one rec-missing-ih decline; the latter is an
explicit known exception to the gate, not a successful rejection or a full
bug-suite conformance claim. No bug case was accepted.

Fresh 4.35 Prelude passed in 0.68 seconds (71,976 KiB RSS), and the same focused
UTF8 export passed in 9.29 seconds (84,336 KiB RSS), with the same record and
declaration counts as above. The sample variation is reported rather than
selecting only the fastest result.

The rec-missing-ih fixture is a frozen malformed recursor export from older
Lean. Its upstream description identifies hash-dependent transitive defeq-cache
reuse, fixed by [Lean #14806](https://github.com/leanprover/lean4/pull/14806).
PSKernel's pair-query cache avoids that design; the current decline does not
prove this specific malformed input was rejected by the intended semantic
check. Preserve it as unresolved conformance work.

## Full-corpus result and stage boundary

The completed run 37979868377 at 05542332ab589314917cd67a7eb7b74e80557770
did not pass the full-corpus gates:

| Corpus | Actual result | Evidence |
|---|---|---|
| Arena Init | Wall-clock timeout, 500.082 seconds | Last progress: 1,099,999 records and 9,330 declarations; not a complete acceptance |
| Arena Std | Resource exhaustion, reported by Arena as a decline, 396.229 seconds | Record 1,227,585, definition Std.Sat.AIG.mkXorCached: kernel reduction budget exhausted |
| Arena Mathlib | Not run | Prerequisite Init/Std gates failed; no Mathlib speed or verdict is claimed |

The native binary hash remained identical between the two passing build jobs.
The old baseline had full Init/Std timeouts; the new Std result now exposes a
specific resource failure. This does not establish that all performance problems
have been solved or that the failing declaration itself consumed the entire run
time.

The diagnostic does **not** identify which fuel source was exhausted.
The global Arena policy is 16,777,216, but
[Checker/Knot.lean](https://github.com/dwijayuda/pskernel/blob/05542332ab589314917cd67a7eb7b74e80557770/psc0/packages/pskernel-core/src/Ps/KernelCore/Checker/Knot.lean#L266)
also supplies the projection shortcut's reducer with
1 + nodeCount(left) + nodeCount(right). Term size is not generally a bound on
the reduction of referenced definitions. This is a concrete suspect to isolate
with a focused mkXorCached export and fuel-origin diagnostics; the current log
does not prove that this shortcut caused this failure. Do not merely raise the
global fuel and declare the issue fixed.

The next stage should start with that reproducer and locate Init's next slow
declaration, then pursue the sharing/metadata work above under PSC0's actual
profile. This stage does not implement that redesign, qualify generated kernel
artifacts, select a new compiler seed, or promote the default provider.

The PSC0 base branch subsequently advanced to
4c79a2e921b3b3c27e3be477f7646f89b6b3526a with one documentation-only compiler
proof-workspace update. It does not conflict with these package changes.
Compiler proofs can reuse this package's assurance library without duplicating
its ownership; full Lean assurance remains outside the runtime/self-host closure.
