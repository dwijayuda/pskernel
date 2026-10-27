# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active branch `feat/psc1-npm-umbrella-20261027`, based on qualified PR #197 HEAD `9d0e23c34484e4b1159f3e2428f5452139df530a`.
GitHub/Linux CI only; non-force expected-HEAD updates. No merge or npm publication.

## Active: automatic core npm installation without cycles

The user's new requirement is that installing proofscript automatically includes the existing core @proofscript packages. Cohort .13 makes proofscript the umbrella and the existing @proofscript/compiler the one shared implementation owner. Root declares/bundles all20 core dependencies; adapters point to compiler, never root. Python/PHP/native and engine/SDK payloads stay optional. New root subpaths allow access to the bundled core APIs without depending on npm hoisting.

Canonical compiler/kernel/host implementation bodies and frozen executors are unchanged. Reuse official Lean4.35.0 and existing exact execution hashes; repin only explicit package metadata. Source-only interfaces remain source-only. Independent compiler-internal modularization is deferred.

Implementation and expanded installed/graph qualification are pending Linux CI. Preserve previous .12 artifacts/evidence in the dated receipt and PR #197; no .13 success claim until CI passes. Next: run the complete package contract, resolve actual failures, then record exact artifacts and qualification.



This simple npm milestone is complete in the documented Linux scope. No remaining package failure in the 42-case contract.
Before universal registry release: qualify actual non-Linux SDK/provider/publication consumers, permanently retain pinned bootstrap assets, and obtain merge/publication authorization.
The user-arranged independent human maintainer trial remains pending.
The dependency-ordered roadmap retains diagnostics, component String/IO and other finite release work.

Full internal compiler partitioning, recursive-group packaging and modular G1/G2/G3 are deferred.
PR #195/#196 qualified component work remains intact. Separate branch `feat/psc1-modular-partitions-20261027` retains unqualified intermediate implementation `b9461a3c6cd556a2c73abdee5cd9156e745c7f5d` (failed run 40489837660); it is not part of PR #197.
Actual graph measurement at 177e41a3 passes 40488488194: 125 modules, 3154 original/3950 specialized/4520 fused values, no cross-source runtime SCC larger than one, 111938 ms/maxRSS 389420 KiB. This is measurement, not successful emission or self-hosting.
