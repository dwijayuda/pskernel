# PSCV P1-G — Required Standard review inventory

This experimental tool enumerates the **230** required rows and **194**
snapshot IDs from the pinned PSCV-RC-v2 reference. It attaches seven
observations from actual Lean 4.35.0-rc3 instance queries.

Three direct Boolean IDs have earlier source-location evidence. The other
**191** remain unresolved. Observing an instance while elaborating a type
does not establish which Standard snapshot ID it implements.

The review output leaves all selected-declaration/registry permissions
unset. Future P1 steps must establish the exact class and basis types,
dependency choices, ordered visible instances, source-module and source-line
identities, and the allowed simplifier, coercion and effect registries.

Only a completed and approved Standard environment can close P1.
P2 requires an independently complete pure verification-condition plan
and actual proof checking. P3 adds language coverage, P4 executable
preservation, and P5 independent conformance and release qualification.

The normal compiler, self-host seed, selected kernel, release and PSCV
certification policy are unchanged.
