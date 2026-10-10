# PSCV P1-D — imported Lean result-class index (uncertified review data)

**Status: qualified environment/typeclass candidate index, not a frozen or activated PSCV Standard registry.**

## Architecture and source ownership

Existing PSC0 folder names remain canonical. The index is experimental source under `packages/pscv/`, not a new compiler, runtime backend or authority-granting npm plugin. It reuses the exact pinned Lean **4.35.0-rc3** environment imported through `PSCVL.Policy`; it is separate from the qualifying native PSC0 Core (historical Lean4.34) and concurrently refining PSKernel Core RC4. No semantic re-pin occurs.

## What the implementation actually captures

`PSCVL/RegistryProbe.lean` now reads `Meta.instanceExtension.getState` from the exact loaded environment. For each instance it reads the actual imported constant's declaration type, recursively strips Pi binders and takes the **syntactic result application head** (`Expr.getAppFn`). It records the declared class-head name (or null if it is not syntactically a constant), the registered priority, `InstanceEntry.synthOrder` metadata and the environment's module-import presence for that declaration. The exact value in an imported environment may represent a synthetic or typeclass-generated declaration. This probe does not synthesize metavariables, perform definitional equality, rewrite source interpretation or approve a Standard instance.

`packages/pscv/src/ambient-registry-inventory.mjs` validates this additional typed metadata and rejects malformed class-head names, fake priority/synthesis order/import status, unknown fields and self-reported proof/emission flags. The record remains tagged `psc-lean-ambient-registrations/0`.

`packages/pscv/src/instance-class-index.mjs` groups registered instances by observed result-class head. Each group includes its instance names, priorities, synthesis ordering metadata and import status. This **review ordering is priority/name sorting**, NOT Lean's actual scoped lookup or equal-priority/import tie-breaking. It has no mapping of source snapshot IDs to class heads, no source-line locators for instances, and no ability to activate any registry or issue a PSCV verified-executable certificate.

An independent exact-normative §24.3 worksheet still lists 230 type/operator/literal requirements and 194 distinct snapshot IDs. Three Boolean direct IDs are source-located from P1-C. All **191 `std.*` requirements remain unresolved**, because a class head is not by itself a verified class-instance binding for a specific operator and basis type.

## Measured candidate space

At qualified source commit `80570393844e08876c3356c553845b6f89846b88` the pinned Lean4.35rc3 imported `PSCVL.Policy` environment reported:

| Measurement | Result |
| --- | ---: |
| Registered instances in the imported environment | **9,742** |
| Distinct syntactic result-class heads | **411** |
| Instances without a syntactic class head | **0** |
| Instance entries observed as imported | **9,742** |
| Source-required snapshot IDs awaiting mapping | **191** |

Typed index identity SHA256 `e9512a596111f2fb095698d0704d3122e0ac1aa1074922acb18ffae5c9dc63db`. Revised ambient registry identity SHA256 `c4710a375287b8b45884b0030f1fd8055020b1e849543fae3c837ec0fca0e17c`. The three Boolean direct source mappings still have evidence SHA256 `c9e5dce7f97646779dc8a00d5c441226550a353190c9ebbe7c9b1aac70c70b9d`.

These figures describe the imported Lean ambient environment, **not** a PSCV-approved instance set. The 411 distinct heads are an index to support targeted qualification; they are not 411 PSCV packages, extensions, kernel primitives, or approved Standard classes.

## Cloud qualification

[GitHub Actions run 38053043569](https://github.com/dwijayuda/pskernel/actions/runs/38053043569), attempt 1, **all six jobs passed**: Linux Node22.23.3 **29/29**, Linux Node26.7.0 **29/29**, Windows Node26.7.0 **29/29** (87 unit tests total); real Lean imported registry probe; full 40-root pinned source provenance audit; real Lean valid/invalid contract preflight. The code remains separate from runtime output publication.

[Download the imported class-head index, raw and reviewed registry and direct Bool mapping](https://github.com/dwijayuda/pskernel/actions/runs/38053043569/artifacts/11670241857) (ZIP SHA256 `d015f8b3ec6b67b652b50a06ff44c2004af19f728e859fe7b030411b91425481`). [Download corresponding 40-root Lean source provenance](https://github.com/dwijayuda/pskernel/actions/runs/38053043569/artifacts/11670701127) (ZIP SHA256 `f91dbd38b7069412cd6e264c7b5539fe21f5ca44071405348e0d503a01ae6698`). Both are expiring GitHub Actions artifacts (9 Nov 2026 UTC), not durable release packages.

## Next source-to-typeclass qualification (not done)

Implement a closed, versioned **instance-resolution rule and test matrix**, not a spelling heuristic: for each of the 191 Standard snapshot IDs, determine the required typeclass family, basis operand/result types, actual candidate declarations, visibility, priorities, `synthOrder`, local/import tie rules and source provenance. Test the actual Lean elaborator's selected instance for that exact source/operator/type combination and independently replay relevant Core evidence before approving a mapping.

Then reconstruct/freeze complete `instances`, `default_instances`, `coercions`, `simp`, `simprocs`, `ext` and `grind`, class-parameter modes, verified-effect and WP law registrations, **per-entry Git source-line provenance**, normative ordering, and an approved canonical Standard manifest SHA256. Until that happens, PSCV profile activation, `PSCV-CERT-v1`, `VerifiedExecutableModule` construction and PSCV executable publication remain blocked. Do not grant authority from source indexes or imported Lean ambient data alone.

No edits to the 62-module portable/self-host compiler, existing release, TS7 backend, bootstrap seed, selected native PSKernel algorithms or other proof branches. Keep cloud/GitHub-only workflow, expected-HEAD leased updates and fail-closed publication controls.
