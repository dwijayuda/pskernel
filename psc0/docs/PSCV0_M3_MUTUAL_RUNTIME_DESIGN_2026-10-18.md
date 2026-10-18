# Mutual WF executable ownership — design under evaluation

PROVISIONAL design under study; not implemented:
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
type inference is in original contexts. Restore auxiliary-owned helpers too, or
prefer skip RecursorLift on recognized logical-only component auxiliary (it is
never executed); private implementation recursors still get ordinary checked
workers and their proofs in canonical admissions. Native host checks the entire
original graph before runtime-view substitution. Preserve worker ownership.
Need inspect naming/origin/assurance/readable-output interactions and full
RecursorLift pipeline before implementing. Add focused tampered-private-body
negative, paired native/.ps source and existing backend observers at activation.
Pinned WF/Main uses addAndCompilePartialRec after logical construction; adapt
its separation without temporary axioms or total/partial strategy conflation.
Source dispatch and PSum selection remain disabled until this is coherent.

This note is not an implementation or qualification claim. The active code first
qualifies public exact equations. Study pinned source and the complete affected
subsystem before adopting or changing this design.
