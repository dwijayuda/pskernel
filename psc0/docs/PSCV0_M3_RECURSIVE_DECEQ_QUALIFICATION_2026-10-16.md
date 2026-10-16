# Direct-recursive DecidableEq — accepted 16 October 2026

## Exact accepted boundary

The selected direct-recursive DecidableEq implementation is qualified at **3fc077fd836e32b0d4250ea7b21183bb06897eab**, tree **52d39bde0d280342e4ccadf5ba483ea88e5e2ca3**. This receipt is a documentation-only child. M3+B remains OPEN; the receipt does not claim complete dependent/nested/mutual deriving, general recursion, P0 execution, P1 fixedpoints, or full v7.2.

The public source target remains v7.2 only, reference blob694115223777599ba28ee175e14bb642b7b6aa4b / SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Official Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc; only propext and Quot.sound are approved logical assumptions.

## Same-commit CI

These are the final workflow identities read from GitHub for the exact compiler SHA, not earlier candidate summaries:

| Gate | Run | Conclusion |
| --- | --- | --- |
| Full native Linux pipeline | [38910660953](https://github.com/dwijayuda/pskernel/actions/runs/38910660953) | SUCCESS |
| F1 canonical model | [38910660803](https://github.com/dwijayuda/pskernel/actions/runs/38910660803) | SUCCESS |
| F2 logical operations | [38910660921](https://github.com/dwijayuda/pskernel/actions/runs/38910660921) | SUCCESS |
| F3/F4/platform | [38910661102](https://github.com/dwijayuda/pskernel/actions/runs/38910661102) | SUCCESS |
| Focused recursive deriving and target execution | [38910660969](https://github.com/dwijayuda/pskernel/actions/runs/38910660969) | SUCCESS |

Native job117005717235 reports all33 steps successful, including setup/cleanup, none skipped. Compilation, existing native source/Standard and frozen-asset checks, module emission, GC/component qualification, TypeScript/Rust execution, repeated native Wasmtime/post-return, unchanged measurement and artifact publication passed. This step count is not a count of independent semantic suites. Artifact publication passed; this receipt deliberately does not substitute an unverified artifact identifier or digest from an intermediate summary.

## Semantics and correction

The direct-recursive implementation uses actual checked child equality decisions. Constructor analysis, congruence, discrimination and dependent proof transport remain checked Core; it does not assume a recursive instance, LawfulBEq, a BEq-to-equality axiom, or a backend equality primitive. The focused fixture includes Nat/Bool decisions, a non-reflexive BEq disagreement check, a recursive chain with a scalar-dependent proof field, checked decision equations and intended-rule refusals. See [implementation design](PSCV0_M3_RECURSIVE_DECEQ_2026-10-16.md).

The final compiler correction concerns a shared declaration-entry boundary, described in [recursor entry](PSCV0_M3_RECURSOR_ENTRY_BOUNDARY_2026-10-16.md). Preparation used to extend the root entry through a reduced result alias while erasure used the raw aligned forall/lambda prefix. RecursorLift now preserves root eligibility only for a raw forall. Function-valued results hidden behind an alias use the existing capture-preserving helper lifting instead of incorrectly borrowing the declaration recursion entry. Existing helper beta-restoration, alpha-equality and official kernel checks remain; there is no class-name special case or weakened erased-local refusal.

Prior candidate failures remain in Git history: the native oracle's recursive-child proof field was invalid and was replaced with the valid scalar-dependent value=value field; a later official-kernel-accepted candidate then exposed the recursor-entry mismatch in erasure. Neither earlier failure is a current blocker after the same-commit results above. The final correction changed no tests, budgets, reference pin or logical assumptions.

## Continuing M3

Do not repeat accepted M2+A, Hashable/Repr or BEq qualification as a substitute for progress. Continue broader nested/indexed/mutual data and deriving, elimination/motives/pattern matrices, structural/well-founded recursion, recursion-strategy ownership and selected P0/P1 obligations. Read the active roadmap and attached stage directive before the next coherent slice.

Partial logical checking retains its independent constructive inhabitant, public opaque logical declaration and actual private partial-body marker. Shared executable admission still rejects partial markers. Never execute the witness, drop the marker, invent a defining equation or totality, introduce Classical/Nonempty fallback, or downgrade a verified request.

No new performance gain is claimed. Runtime133af061 and paired38840337837/artifact12021226623 remain the measured 9.25–10.11x List-to-Array improvement; deep-list lookup/reversal remain unresolved. Native portable .lean, GitHub/cloud Linux only, focused tests, no pskernel-core/self-hosting/compiler-source migration/C5. PR109 stays draft/open on its original base and unmerged.
