# PSCV0 — direct-recursive Repr qualified; M3+B continues

Updated 16 October 2026. **The direct-recursive Repr slice is complete; M3+B remains OPEN.** v7.2 is the sole forward `.ps` reference. Before every new coherent slice, reapply the attached user prompt and `docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md`, read fresh HEAD/CI/both handoffs, and study the affected pinned Lean source. No legacy mode or restriction on native `.lean` semantics.

## Exact accepted compiler and evidence

Qualified compiler/test commit: **4501164e5f1c32e00c81ae98d171e7bf201d1907**, tree `b41b9db561108596a95cc0879ba8dcfa0d964f8d`. This receipt is a documentation-only child; do not attach qualification to an untested new executable change.

All required same-commit runs passed: native **38898123679** (job116963430156), F1 **38898123552**, F2 **38898123501**, F3/F4/platform **38898123787**, focused Hashable/Repr **38898124015** (job116963431087). Native completed 2026-10-16T12:22:03Z; all 33 reported steps including setup/cleanup succeeded, with none skipped. Source/Standard, modules, GC/components, TypeScript/Rust, repeated native Wasmtime/post-return, measurement and artifact publication passed.

Read `docs/PSCV0_M3_RECURSIVE_REPR_QUALIFICATION_2026-10-16.md` for the final exact run/artifact inventory. Native artifact12044554729 has digest `sha256:a21b4955502b3a2237d233a57cecf531cd040a05466138aed502a8ebe44f7cfa`; focused artifact12045001218 has digest `sha256:5a3d5807763726e1ed1988a856aa62babc65f6a022e4dc90b6b880882f7081e4`. Both match the qualified head. Use these final metadata-derived IDs rather than intermediate summaries.

## What changed

Repr now consumes actual checked direct-recursive induction printers of type Nat -> Format, applying children at precedence1024. Independent dictionaries, structure/constructor formatting, hidden/proof/type fields and shared motive checks remain. Native and separately compiled `.ps` trees compare exact strings for Nat/Bool at root0/1024 and width40 on all selected VMs. Recursive values stay internal; the ABI is still Bool-to-UInt64. Existing Hashable law and refusals remain; three Repr refusal cases cover unsupported nested/indexed/missing-dictionary cases.

Candidate c942112d's new fixture used an unavailable String.beq spelling. f0d22372 corrected it to checked == without changing compiler logic or expected strings. The final reconciliation migrated one obsolete direct-recursive Repr negative to nested-recursive Repr, retained assertions/phase/budgets, and removed the completed temporary diagnostic/preparation workflow. Its exact prepared native-test blob is913c02e94f1688da595c6bad617eb8a7f8f9c83b. Previous failures remain historical, not current blockers. Parent58d439's abstracted-motive capture correction and qualified Hashable remain unchanged.

## Next M3 work — no new implementation claimed

Continue through shared data/elimination/recursion mechanisms. Recursive BEq/DecidableEq and broader nested/indexed/mutual deriving remain pending. Local DerivingBEq, pinned upstream Deriving/BEq and shared Meta.Recursor/Erasure.Recursion were reviewed: left-child comparison induction must combine with right-constructor case analysis without extra unintended traversal. The existing psRecursorUsesHypotheses analysis is a candidate building block, not a completed new lowering. Do not enable a guard without matching positive and intended-rule refusal evidence.

Current partial logical checking independently constructs a constructive inhabitant, admits public opaque logical self, checks the actual recursive body and retains the private numeric partial marker in the prepared graph. Shared executable admission still refuses every partial marker across modules/targets. P0 ordinary execution/assurance and P1 fixedpoint construction remain OPEN. Never execute the witness, erase the marker, invent logical body equations/totality, add a Classical/Nonempty fallback, or downgrade verified requests.

The full M3 exit still includes broader data/motives/pattern matrices, structural/well-founded total recursion, recursion-strategy ownership, deriving and selected v7.2 P0/P1 obligations. A green Repr slice is not completion of M3 or the language.

## Preserved authority and performance

v7.2 blob694115223777599ba28ee175e14bb642b7b6aa4b, SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e; adoption521a4a66 and whole-reference audit38840967041 are recorded. M2+A original profile73 remains accepted at2a707206/280e1e4e with its original receipts/artifact12018546813. Do not repeat or relabel that acceptance as full v7.2.

Runtime133af061 and paired38840337837/artifact12021226623 remain authoritative:9.25–10.11xfromList, smaller head/array gains, unresolved deep-list lookup/reversal. This slice claims no new speedup. Preserve original benchmarks, stack-safety evidence, exact numeric semantics and persistent data behavior.

## Working contract

GitHub connector/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`; official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Approved assumptions only propext/Quot.sound. No sorry/unchecked admission/weaker tests/larger budgets/pskernel-core/self-hosting/compiler-source migration/immediate C5. Wasm GC internally, linear memory explicit ABI. Preserve concurrent history with fresh expected-HEAD/non-force writes. Update BOTH handoffs and exact receipts each slice. PR109 draft/open on psc0/pscv0-v7-m1-parser-ownership-v1, never merge. Continue M3+B -> M4+C/D -> M5+E without fabricated qualification or completion percentages.
