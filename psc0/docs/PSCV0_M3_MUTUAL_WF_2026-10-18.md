# Typed mutual WF component design and PSum authoring

Status: standalone export independently passed; exact6779-byte five-declaration
asset retained. Portable typed component packing and its consolidated kernel
probe are candidates awaiting qualification. Standard selection, source mutual
WF admission, exact unfolding equations and runtime ownership remain separate.

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc is the reference.
Study: Init/Core.lean PSum; Lean/Meta/ArgsPacker.lean Unary and Mutual;
Lean/Elab/PreDefinition/WF/{PackMutual,Rel,Fix,Unfold}.lean; FixedParams.lean.
Relevant tests: wfrecUnary.lean, mutual_termination_by_errors.lean,
fixedParamsReorder.lean and funind_mutual_dep.lean. The latter two expose
different header order, heterogeneous dependent results and parameter
ownership requirements. Upstream test_sorry controls are design references
only and must never enter the portable foundation or qualification fixtures.

## Foundation

Inventory39078076219 confirms selected PSigma, PSigma.mk and PSigma.casesOn,
but no PSum, inl, inr, rec or casesOn. The existing Sum asset is Type-only.
Mutual WF domains must admit arbitrary sorts without conflating a user sum
field with a compiler-owned component tag.

The native authoring exporter closes exactly PSum/inl/inr/rec/casesOn from
pinned Init.Core against an empty boundary and empty replay base. The
closure is standalone, so there is no need to duplicate the complete growing
Standard boundary. The existing exporter independently replays all declarations
from an empty official kernel and compares both generated recursor rules.
No assumption, class or instance registration is requested. A successful
export is a candidate asset only; activation requires exact retained bytes,
native comparison, immutable Standard manifest/surface identities and normal
source/kernel/integration gates.

## Component construction invariant

Follow the existing typed predefinition SCC owner and retain its actual
source headers, captures, source bodies and per-member termination clauses.
A compatible component has complete compatible strategies, a common fixed
measure codomain/relation, and actual typed call/decrease evidence for every
member. Preserve member and universe identity through the entire component.

The domain combines arity-owned dependent parameter packs with arity-owned
PSum component tags. Shared fixed parameters/captures stay outside; changing
parameters and dependent result/state families retain their original order.
Keep the original telescope authoritative. Neither user PSigma/PSum types
nor equal source spellings authorize further decomposition or parameter
identification.

Re-elaborate each retained source body under its actual proof-restricted
callbacks, as singleton WF already does. Dependent matching must refine the
current member and all callbacks before creating the decrease goals.
Do not rewrite calls under an already elaborated match using stale majors.
Share ordinary application completion and the newly added capture mechanism.

Construct one checked WellFounded.fix functional, its dependent sum motive,
and public member projections. Derive each original-header equation from
the actual fix_eq theorem with checked constructor/callback extensionality.
Then compare the equation with the independently retained source body, using
the existing typed-predefinition identity discipline. No temporary axiom,
Boolean component shortcut, assumed equation or P0 substitute.

Executable adaptation must validate the complete component and every original
entry/body/equation association before exposing recursive runtime calls.
Generalize the existing typed runtime owner if it reduces duplication; do not
trust new source metadata or treat unrelated same-shaped helpers as witnesses.
The executable observer matrix must include three members, heterogeneous
results, dependent argument/state, genuine captures and invalid cross-calls.

## Boundaries and next work

The standalone export does not implement the component consumer, source policy,
exact equations or runtime adapter. Existing mutual WF refusal remains until
those form a complete checked path. The next implementation should share
packing and source-application machinery, preserve independent singleton
qualification, and avoid introducing a second elaborator.

M3+B remains open. Main stays at its accepted exact-SHA receipt. M4 effects
and contracts and M5 target correspondence/C5 remain separate. No PSKernel-Core
or self-hosting activity.

## Runtime ownership refinement

A public fixedpoint equation is necessary but insufficient for ordinary runtime
adaptation: even a genuine proof of f = f says nothing about replacing its body.
The runtime owner must reconstruct every curried callback from the checked
component's actual functional and full original entry telescope, match its
typed adapters exactly, and reject remaining raw callbacks. Preserve the
singleton WF adapter's complete-before/after type checks. Factor the source
adapter rather than rewriting already checked matches with stale majors.
The current packing library supplies only domain/motive operations; it does
not confer this execution authority.
