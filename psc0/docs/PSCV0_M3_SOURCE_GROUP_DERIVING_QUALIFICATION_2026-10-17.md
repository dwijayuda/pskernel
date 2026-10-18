# PSCV0 M3+B source and group deriving qualification — 2026-10-17

## Accepted compiler/test identity

Compiler/test SHA: `03000e7b0c257fb8f8d2e2b387b7b65a53e8f504`.
Repository: `dwijayuda/pskernel`; branch: `psc0/pscv0-v7-native-lean-v1`;
[PR #109](https://github.com/dwijayuda/pskernel/pull/109) remains open, draft and unmerged.

This receipt qualifies the accumulated source/predefinition and deriving work
after the earlier accepted `fbbc5271419dde8b183be723f07ff1f75a462013`.
It does not declare M3+B complete.

Pinned Lean is **4.35.0** at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The language authority remains `PSCV0_LANGUAGE_REFERENCE_v7.2.md),
blob `694115223777599ba28ee175e14bb642b7b6aa4b`.
Only `propext` and `Quot.sound` are approved logical assumptions.

## Same-SHA gates

| Gate | Run | Result |
| --- | --- | --- |
| Native Linux | [38991805487](https://github.com/dwijayuda/pskernel/actions/runs/38991805487) | SUCCESS; 34 reported steps |
| F1 canonical model | [38991805477](https://github.com/dwijayuda/pskernel/actions/runs/38991805477) | SUCCESS |
| F2 logical operations | [38991805491](https://github.com/dwijayuda/pskernel/actions/runs/38991805491) | SUCCESS |
| F3/F4 and platform | [38991805538](https://github.com/dwijayuda/pskernel/actions/runs/38991805538) | SUCCESS |
| Focused M3 qualification | [38991805453](https://github.com/dwijayuda/pskernel/actions/runs/38991805453) | SUCCESS; 15 reported steps |

Every run's `head_sha` is the compiler/test identity above. Successful
compilation alone was insufficient: all original native workloads and all
focused source and runtime lanes completed.

Native artifact: **12085094168**, **6,795,772 bytes**, SHA-256 `2e074f49132e8efdc5cb22aaabfe1a0bb8825f38a291e3beff9f927597995db9`.
Focused artifact: **12085147807**, **2,464,032 bytes**,
SHA-256 `49be3cc7aeab088a1fba5c53fc90de7582c2ae00fd0099e5fd6799f6fc45dda5`.

The native workflow retains source/Standard qualification, the three-module
application, GC core and component formats, TypeScript, Rust, repeated native
Wasmtime embedding and the existing compiler/collection measurements.
Dependency pins, request/output expectations and budgets were not changed.

## Root causes resolved

### Nested Repr accumulator closure

At `8390cdc647ce0f5e5bd45678f000795ea5afb93c), focused
[38987840331](https://github.com/dwijayuda/pskernel/actions/runs/38987840331)
rejected the outer `Prod Display (Prod Branch Display)` minor.
The exact term was `ihRight (List.cons Format (ihLeft 0) $39)), missing
`fun tail : List Format => ...`. The orphan free variable was later reused
for the reopened `fst : Display`, producing the reported type mismatch.

Pinned Lean's bound-do elaboration preserves the enclosing return continuation.
The two inner `return` expressions in `let body ← if ...` could therefore
leave `psElabDeriveReprContainerBranch` before its final `psLogicLam`.
Commit [e85012f5](https://github.com/dwijayuda/pskernel/commit/e85012f5f6d5a9e702779c0b13372e46eac1af0f)
changes these yields to `pure`, so both actual right-IH paths close the
accumulator through the existing owner. No recursor, motive, IH association,
unifier or runtime workaround was added.

Authoritative references:
[pinned BuiltinDo/Basic](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/BuiltinDo/Basic.lean),
[BuiltinDo/Jump](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/BuiltinDo/Jump.lean)
and the retained bounded generated-term diagnostic in the fixture.

### Demand-order observation

The Repr repair passed four gates but focused
[38990964814](https://github.com/dwijayuda/pskernel/actions/runs/38990964814)
next failed its Boolean demand-order assertion. `psReduceIota` reduces a major
only to select a constructor; a blocked recursor retains its original
application through `psWhnfSpineWithTransparencyFuel`. The assertion was
comparing that unreduced major with a free variable.

Commit [03000e7b](https://github.com/dwijayuda/pskernel/commit/03000e7b0c257fb8f8d2e2b387b7b65a53e8f504)
WHNF-reduces the observed major before the same exact alpha-equality check.
It retains the Bool.rec head check, List-first and Array-last expected locals,
unequal-length short-circuit, second demand and both open kernel-checked
equations. Bounded diagnostics show both raw and demanded guards on failure.
Production reduction and BEq construction are unchanged by this correction.

The selected order matches pinned
[List](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/List/Basic.lean)
and [Array](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Array/Basic.lean):
Array checks equal lengths before its reverse traversal.

## Newly qualified accumulated source work

The shared typed predefinition owner preserves original-main strategy
validation, complete block capture, body-only universe closure, typed
dependency/SCC ordering and atomic publication. It handles the selected
disconnected and recursive components without inventing peer axioms.

`Pscv0M3PreDefinitions`, invoked within the existing mutual structural
fixture, checks five source functions, three captures (`A`, `a`, `bias`),
two universes including one present only in the body, exact source/body
signatures and equations, and native results **15, 9, 2, 7, 11**. It also
rejects capture/peer/strategy/WF identity corruption and late-component failure
without partial publication.

`Pscv0M3Where` retains **seven host requests**: one positive aggregate and six
phase-specific refusals. The checks cover omitted local codomains, typed
defaults, sibling recursion, parent/helper cliques, inferred theorem helpers,
proof shadowing, private identities, source-local scope, original-block P0
inheritance, ignored hints without extra capture and checked local WF.
The positive fixture checks **16 local origins** and **five equation witnesses**.
Its **six exports** are checked for both Boolean inputs in every target lane.

## Newly qualified accumulated deriving work

`Pscv0M3NestedDeriving` checks **five generated instances**: two mutual Repr,
two nonindexed mutual BEq and one indexed Repr. The complete public/auxiliary
plan has **11 signature witnesses**, **nine slots**, **18 minors**, two
parameters and one Repr dictionary capture. Its atomic-slot vector remains
`[false, false, true, false, false, false, false, false, false]`.

Worker ownership remains exact: four groups of nine workers and one group of
two workers, each with three captures. Actual IHs carry the heterogeneous
`Nat → Format` and `List Format → List Format` results; independent field
dictionaries are used only for their genuine independent fields.

The fixture retains native collection and tuple formatting, generic and
nonreflexive BEq dictionaries, every recursor signature, portable reduction,
List/Array demand order and checked equations. It exports **six** scalar probes.
Full native Repr text is compared at widths **23/120** and root precedences
**0/1024** for display, branch, tuple and indexed values; comparison is on
complete text rather than a checksum.

`Pscv0M3GroupProofDeriving` checks **six generated instances**: two direct
mutual DecidableEq and four ordered group/nested Inhabited. It retains
**13 signature witnesses**, four checked projection equations, four logical
default equations and eight output equations. The worker invariant remains
exactly **two two-member groups with three captures**. Right-case proof
construction omits only the unused actual right IH locals; every real
enclosing minor binder and all actual left IHs are retained.

The fixture exports **four** scalar probes. Dependent proof fields, complete
group projections/discriminators, constructor order and exact parameter
requirements remain checked. Nested DecidableEq stays refused, consistent
with the pinned native handler.

## Focused execution and unchanged contracts

The workflow runs **13 required outer source fixtures**. The original fixtures
continue to pass, including their existing mutation/refusal cases.

The three newly qualified runtime fixtures above contribute
**16 exports × two Boolean inputs = 32 scalar comparisons per lane**, or
**160 additional comparisons** over the five existing target lanes:

- Direct JavaScript.
- Strict compiled TypeScript.
- Locked Rust.
- V8 GC core WebAssembly.
- Native Wasmtime components.

Their ABI remains exactly Bool → UInt64. Complete text comparisons inside
the Repr probes remain part of the oracle. The focused log reports PASS for
`wherefixture`, `nestedderive` and `groupproof` in each lane, together with
every previously qualified runtime fixture.

## Progress and remaining obligations

This same-SHA evidence raises the accepted engineering estimate from
**67/100 to 74/100**. It is an estimate of the six milestone exits, not measured
language coverage or a claim that any complete milestone has closed.

| Exit | Weight | Previously accepted | Accepted now |
| --- | ---: | ---: | ---: |
| Data, elimination and deriving | 30 | 21 | 24 |
| v7.2 source strategies | 15 | 10 | 13 |
| Total structural/WF recursion | 20 | 14 | 14 |
| P0 ordinary partial execution | 15 | 13 | 13 |
| P1 selected partial_fixpoint | 10 | 1 | 1 |
| Cross-stage integration | 10 | 8 | 9 |
| Total | 100 | 67 | 74 |

M3+B remains open, approximately **70–75%** by this engineering estimate.
M4+C/D and M5+E are not declared complete.

The following remain unqualified or bounded: optional main-result inference;
full checked WF foundation activation and broader relation selection;
empty runtime dictionaries; dependent unary packing with curried calls;
general mutual WF; broader indexed BEq/DecidableEq and constructor-directed
indexed Inhabited; arbitrary positive containers and function-valued nested
fields; remaining P0 exits and final cross-stage qualification.

The focused assumption audit still finds **Classical.choice** in
`Lean.Order.CCPO.csup`, `Lean.Order.fix`, their equations and the native
Unit/Option fixedpoint examples. P1 remains unavailable under the approved
assumption policy. The implementation retains its fail-closed source refusal.

Independently prepared candidates add no points to this receipt. The next
concrete integration is the proposed WF foundation audit: import the exact
recovered asset into the authoring check, independently verify it against
native Lean and print prospective fingerprints while active Standard
selection and all pins remain fixed.
