# PSCV P1-G — Required Standard review inventory

**Qualified (non-authoritative):** [run 38057594392](https://github.com/dwijayuda/pskernel/actions/runs/38057594392) passed all four jobs, including actual Lean4.35.0-rc3 witness execution and Linux/Windows review tests. [Machine qualification](pscv-p1g-qualification-2026-10-10.json), [ledger artifact](https://github.com/dwijayuda/pskernel/actions/runs/38057594392/artifacts/11671753807), identity SHA256 `e562efe944af9a55eff7c2960fd2a143877cf9ec6c85a5e7b826983ade74b8c0`. Nothing is approved for PSCV Standard or certified execution.

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
