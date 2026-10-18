# M3+B positive dependent recursive fields

Status: implemented on preparation; CI qualification pending. M3+B remains open.

## Pinned implementation study

Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc:

- kernel/inductive.cpp: strict positivity opens recursive field Pi codomains,
  rejects recursive occurrences in their domains and preserves family parameters.
- src/Lean/Elab/PreDefinition/Structural/BRecOn.lean, toBelowAux / replaceRecApps:
  a positive field's actual argument spine specializes its IH before source
  function positions select a component; unchanged universe constraints apply.
- src/Lean/Elab/PreDefinition/Structural/IndPred.lean,
  replaceIndPredRecApp: the actual recursive field fvar and its actual arguments
  select the predicate hypothesis. Automatic predicate recursion is Prop-valued.
- src/Lean/Compiler/LCNF/ToLCNF.lean: proof erasure and constructor/recursor
  processing consume actual typed metadata rather than invented runtime slots.
- tests/elab/structuralOverNested.lean: RTree.simple_size and VTree.size use
  function-valued recursive fields, including dependent/indexed telescopes.

These upstream sources are the primary design/semantic reference. This change
is an original implementation over owned PSC0 Core and contexts; it does not
copy native implementation bodies. Existing Apache-2.0 notices remain intact.

## Architecture and invariants

1. Data's existing recursive-field traversal opens each Pi with a fresh local,
   checks the domain has no recursive family, and checks the codomain under
   that context. Selected nested containers and uniform parameters retain their
   checks. Ordinary checked recursor construction and official kernel admission
   remain the final formation authority.
2. StructuralField owns shared lookup of an actual applied constructor field.
   Term applies its real IH to the field arguments; MutualStructural first checks
   the closed full IH telescope against the real motive, then applies arguments
   before selecting the source function component. Actual applied child indices
   determine recursive argument validation. No name-based decrease evidence.
3. The runtime singleton plan retains opened Core identities rather than guessed
   runtime slot positions. Singleton and group builders construct actual Core
   recursive calls. A single positive-field telescope helper closes those calls
   under lambdas; ordinary erasure handles type/proof/index/runtime arguments.
   Every match replacement is inferred and compared to the real IH domain.
   Structure auxiliary slots use the same helper and retain shared projection lets.
4. Pinned native automatic predicate recursion constraints remain distinct from
   primitive-recursion large elimination. No arithmetic-decrease assumption,
   new foundation constant, host elaborator dependency or backend primitive.

## Focused qualification

Extend Pscv0M3InputParity in place, preserving all existing requests and refusals.
Paired .lean/.ps programs declare ParityBranch with a field of type
forall (i : Nat), i = i -> ParityBranch. They use singleton structural recursion,
mutual recursion with reordered/changing state, explicit primitive recursion,
and a theorem consuming the exact dependent IH. Metadata, types and values are
compared across actual source adapters. The official kernel admits the checked
source; native Lean gives oracle results. A negative occurrence in a function
domain is parsed successfully and must fail the specific positivity check.

m3fields true = 192013; false = 232417. Existing JS/TS/Rust/Wasm-GC/component
observers execute those outputs for both input kinds after preparation passes.
Emission is not execution evidence. Existing invalid-field/owner/family/index,
Acc predicate, nondecreasing-call and forged-runtime-body controls remain.

No local builds, pskernel-core, self-hosting, C5 or expanded time budgets.

## Native oracle boundary

Lean4.35.0 rejects native code generation for the explicit ParityBranch.rec
application. The native fixture retains it as a noncomputable logical definition
and proves branchByRec_agrees against an executable structural reference. The
PSC0 source fixtures still contain the explicit primitive recursor and still
must emit and execute it on all targets. Native kernel agreement, the executable
reference and backend execution remain distinct evidence layers.
