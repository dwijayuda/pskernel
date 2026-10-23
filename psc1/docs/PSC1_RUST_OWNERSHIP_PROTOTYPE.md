# Rust ownership prototype

This isolated branch follows exact generated compiler evidence. It uses the same
production emitter, checked IR, source closure and independent qualification.

Ordinary expression emission already yields owned values; preserve grouping
while removing redundant clones of computed values. Exact monomorphic ordered
String intrinsic forwarding wrappers borrow initialized locals. Tail exits
evaluate all changing arguments before moving unique, unshadowed String locals.
Scope-aware last-use lets transfer renamed worker parameters without copying;
capture-analysis exhaustion or a live original binding conservatively refuses.
Duplicate roots and shadows retain ordinary cloning.

Retained old Expr/Tail emitters and generated Rust runtime comparisons cover
Unicode, argument ordering, duplicate values, aliases, retained originals,
captures, lexical shadows and reserved names. Mechanism timings are not full
compiler qualification. Both owned source grammars must pass before generation.
Use unchanged official Lean admission, strict IR, frozen ten-case corpus and
resource limits. No private ABI/runtime changes or stack increase are included.

Run 39886083977 passes G1, then aborts G2 with stack overflow; 39888964045 is
qualifying the last-use correction. Check actual terminal results before claims.
Main normal CI 39887884270 concerns the separate integrated TS annotation source.
No prototype integration, merge or publication is authorized by these results.
