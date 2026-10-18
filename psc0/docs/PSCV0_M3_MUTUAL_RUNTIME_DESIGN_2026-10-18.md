Implementation candidate (qualification pending):
Use ordinary checked private implementation definitions (not partialDecl and no
new Core variant). After logical auxiliary/public definitions and exact source
equations are checked, derive each implementation body DIRECTLY from the checked
component functional: open the exact public raw header, identify actual fixed
arguments and compiler-owned PSum injection/PSigma pack, apply actual functional
to that entry and replace its proof-restricted aggregate callback by a typed
aggregate of genuine public callees. This is the existing singleton
Erasure/WellFounded callback recovery generalized to multiple targets.
Private bodies reference actual public logical constants, so are ordinary
nonrecursive kernel-checkable definitions. Compile-time runtime view replaces
public bodies with these checked private bodies to obtain ordinary typed mutual
calls; omit private aliases and logical packed auxiliary, retain used helpers.
Do not authorize runtime via an Eq f=f or unverified retained source sidecar.

Avoid new metadata if possible: private names can use existing generated
PsName.num public 0 convention (ordinary definition for total WF, partialDecl
continues to mean P0/P1). Actual public raw lambda prefix owns original header
arity; beta/zeta exposes exact aux fixedArgs currentInjection. Group count/order
comes from unique validated public projections onto one actual auxiliary.
Validate complete unique projection coverage, exact types/universes, fixed
bijections and original varying pack; never flatten a user's final PSum/PSigma.

Independent runtime consumer re-derives raw private body from checked logical
auxiliary/public definitions and alpha-compares with retained private body after
restoring only private-owned RecursorLift helpers (existing P1 restore pattern).
Wrong body/owner/equation cannot obtain executable authority. Shared helper
implementation for producer/validator avoids duplicate algorithms; all actual
type inference is in original contexts. Restore auxiliary-owned helpers too; do not skip RecursorLift. Private
implementation recursors still get ordinary checked workers and their proofs
in canonical admissions. Native host checks the entire
original graph before runtime-view substitution. Preserve worker ownership.
Need inspect naming/origin/assurance/readable-output interactions and full
RecursorLift pipeline before implementing. Add focused tampered-private-body
negative, paired native/.ps source and existing backend observers at activation.
Pinned WF/Main uses addAndCompilePartialRec after logical construction; adapt
its separation without temporary axioms or total/partial strategy conflation.
Source dispatch and PSum selection remain disabled until this is coherent.

Further subsystem audit:
- Compiler/Api.prepare runs RecursorLift before canonical admissions; NativeV7
  checks original admissions then chooses ordinary-partial or general runtime.
  There is no export pruning before this whole prepared graph is checked.
- A private ordinary implementation definition can reference genuine public
  logical functions without creating a kernel cycle: publics reference the
  closed WF auxiliary, which uses proof-restricted callbacks, not public names.
- Prefer one shared typed recovery module under Elab/WellFoundedRuntime (pure
  checked-Core work, no source parse) reused by producer and compiler validator;
  Compiler already depends on Elab. No compiler->elab cycle is permitted.
- Recover inventory from actual public raw lambda prefix + beta/zeta exposure of
  aux fixedArgs packedEntry; original header count excludes returned lambdas
  because public generated projection body is an application. Require complete
  unique projection coverage, exact fixed fvar bijection and typed varying tuple.
- Build aggregate of genuine public unary projections in the common fixed scope,
  instantiate it back into each original member context, and build a two-binder
  smaller/proof callback of the ACTUAL inferred callback type. Apply the actual
  checked functional to current injection and this callback, close original
  header, infer/check exact original type. This derived body contains no fixpoint.
- Private implementation names can be PsName.num public 0 as ordinary definitions,
  distinguished from P0/P1 partialDecl. No new Core declaration variant needed.
- Independent runtime validator reconstructs this exact body from logical
  auxiliary/publics and compares against private body after restoring only
  private-owned RecursorLift helpers. Move/generalize existing P1 helper restore
  (~55lines) into a shared pure module rather than duplicating it. Restore
  auxiliary helpers too, or deliberately skip lifting logical-only auxiliary;
  do not skip private implementation workers or their canonical kernel admission.
- Runtime graph replaces public body with prepared private body, omits private
  alias + packed auxiliary + auxiliary-owned helpers, keeps private-body workers.
  Shared worker-group filtering must reject partially-owned groups. Apply total
  WF recovery alongside P0/P1 ordinary runtime view, but keep general partial
  guard and original logical environment/assurance rules.
- Existing complete source fixture currently checks 1 shared auxiliary +3public
  definitions +3exact equations; future executable activation needs actual body,
  tampered private/body-owner refusal, paired .ps/.lean source observations and
  existing five backend lanes. PSum selection then updates strict identities.
- Pinned WF/Main31-35 explicitly refuses zero-varying members; no PUnit feature
  is required. Basic.addAndCompilePartialRec280-294 compiles renamed original
  definitions with partial safety after WF logic; PSC0 should retain stronger
  independent actual-functional recovery rather than importing unsafe machinery.

Candidate now implements shared Elab/WellFoundedRuntime, independent
Compiler/WellFoundedRuntime ownership, and shared RuntimeOwnership helpers used
by P1 and total WF. The existing three-member packing fixture checks original
headers, complete component coverage, prepared helper restoration and same-typed
forged private bodies; all original and prepared bodies go through the official
kernel. This candidate does not activate source dispatch or select PSum, and
runtime backend execution is still pending. No test budget or foundation changes.

Fresh-scope review after candidate3e226c69 (preparation39095552319):
the new runtime recovery opened a common fixed context at local zero, overlapping
original member header IDs. Ordered local substitution then composed reordered
parameters accidentally (e.g. a type became a value), correctly rejected by type
inference. Source construction already used fresh disjoint IDs. Runtime recovery
now allocates its common fixed scope above every actual original raw header.
This preserves the existing ordered substitution contract and follows the same
RecursionOpenFixedScope invariant; do not globally change substitution semantics.
The existing three-member dependent/reordered fixture covers this family.
The PSum exporter now measures the exact extended candidate against a frozen
pre-mutual boundary, without changing selected manifests or selecting the asset.
