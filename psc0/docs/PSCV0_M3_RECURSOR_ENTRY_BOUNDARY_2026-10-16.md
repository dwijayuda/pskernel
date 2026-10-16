# M3 recursor preparation — declaration entry versus returned closure

16 October 2026. **Shared correction implemented; exact qualification pending.** This continues the recursive DecidableEq slice, not a new admission policy or a backend-specific workaround.

## Observed failure and source evidence

The corrected equality candidate2407ff54e8dc61b471f7e395e95c0b91f9c71eed passed independent native-oracle compilation and official kernel checking of the complete new source program. Focused38909571471/job117001701333 then failed at erasure: `PSCV0-ERASURE: runtime use of erased local: 5 (in M3HashTree.instDecidableEq)`. Thus the previous invalid native proof-field fixture is no longer the blocker. The actual generic equality's runtime lowering remains unqualified.

`Ps.Compiler.RecursorLift` previously treated every leading value lambda as a declaration argument after weak-head-normalizing its type. In contrast, `psErasureEntryInfoWithFuel` and `psEraseOpenDefinitionWithFuel` deliberately count only the aligned raw forall/lambda prefix. An arrow exposed by reducing a result alias is a returned function, not another flat declaration parameter. This distinction is already documented in those erasure owners and is needed to preserve declaration call arity and curried function values.

A derived `DecidableEq A` directly returns the comparison function behind that type alias. Preparation previously retained root eligibility for its hidden comparison arguments, so it could leave a recursor expecting to reuse the declaration's recursion entry. Erasure's actual entry did not own that major argument. The optional recursive-call plan could not be constructed, and the induction hypothesis correctly remained erased rather than inventing a recursive call.

## Correction and invariant

In RecursorLift's lambda case, root eligibility is now retained only while the incoming raw type is a forall. Weak-head normalization still obtains the checked function telescope for typing, but it does not extend the flat entry boundary. Once that boundary ends, the existing typed closure-conversion helper owns recursive majors and captures. This is independent of declaration names, class names, source syntax and target backend.

Existing helper construction still checks capture dependencies, substitutes fresh indices/major, restores the exact original Core expression by beta application, and requires alpha equality before inserting the helper. Official kernel checking subsequently checks the generated declaration. No equality proof, erased-local refusal, runtime call arity, representation, assumption or fuel budget is relaxed.

## Pinned comparison

Studied official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc `src/Lean/Compiler/LCNF/ToLCNF.lean`, including seqToCode's treatment of function-valued cases through a local function/eta expansion rather than confusing it with a value join point. Lean's exact IR architecture differs; the reusable principle is keeping declaration entries, local functions and captured values explicit. PSC0's raw-entry rule comes from its own already checked shared representation contract, not a claim that Lean uses this exact raw-prefix algorithm.

## Required qualification

The existing recursive equality fixture already exposes the alias boundary and now requires full source/kernel/preparation/erasure and JS/strict TS/Rust/V8 GC/Wasmtime behavior, including independent field dictionaries, generic instantiation, equal/unequal cases and dependent scalar proof fields. Existing native generic/call/recursor cases and all other mandatory gates remain unchanged. No new test executable or benchmark is added.

Require all five workflows on the exact correction commit. A passing kernel check or plausible source explanation does not by itself qualify runtime behavior. M3+B remains open for broader data/elimination/total recursion/P0/P1. BEq058fb67f and earlier accepted baselines remain unchanged; no new performance or global preservation claim.
