# Empty semantic-cache lookup guard — isolated implementation checkpoint

## Change

This branch is based on `20224a295359abb201f56c72395690bf0bfac9fa` and changes only `psKernelSemanticExprMapGet` in `Runtime/Acceleration/CacheAnalysis.lean`, plus its adjacent explanatory comment. If the cache has no index and its small list is empty, the function returns `Option.none` immediately. Nonempty small caches retain the existing eligibility check and exact lookup; indexed caches retain the original analysis and collision-aware lookup.

An empty map cannot yield a value. Skipping the otherwise unnecessary eligibility traversal can save work on closed expressions and expressions with a late free variable. This is a candidate optimization with no measured performance claim. The observed historical Church cheap-left snapshot has an early neutral-head free variable, so the change is not claimed to fix that failure or the reduction budget.

The current full production predecessor is exact ae47, with CacheAnalysis blob `4d5ca3d8e2a6136d5fcb35dec131e5c28e6b743b`. The entire new file is reconstructed from that predecessor by one helper change (546 to648 bytes) and the explicit comment correction. All other production files, fuel policies and cache publication code are unchanged. The held three-binding transform experiment is absent.

## Proof obligations

`PsKernelEmptySemanticCacheProofs.lean` freezes the exact predecessor helper and adds two theorems:

1. Equality of every lookup result between the new and old helpers, for arbitrary typed expressions and arbitrary raw cache values, including seeded open entries.
2. Immediate empty-map lookup returns none for every typed expression.

The existing `semantic_map_get_eq` theorem statement remains unchanged. Its proof body now handles the empty and nonempty small-list cases. The other six retained closed-cache theorem bodies, all seven report names, and all60 cache-scope proofs are byte-preserved.

## Qualification

The native-only25-minute workflow `.github/workflows/psc1-empty-semantic-cache-preflight.yml` first authenticates exact Git source, full production delta, the frozen helper, the single retained proof-body repair, and pinned toolchain inputs. It builds production imports, checks all69 reports (60 retained scope +7 retained closed-cache +2 new), verifies their exact names/order/standard axioms/statuses and archives all11 source inputs. The completed artifact must contain18 files, including the hidden workflow copy.

At creation this source is not yet compiled or qualified. Use only its unique matching-source run and inspect actual logs and artifact contents. Do not infer qualification from the main T05 source or from an older optimization.

After native69 succeeds, qualify paired baseline/candidate CacheAnalysis leaves using an authenticated compiler and the explicit existing bootstrap policy. Retain the unchanged1884 closed-cache assertions and add a separate21-assertion empty-map matrix; do not replace or weaken the1884 controls. Measure only after both semantic routes pass, using fresh Node22 processes, fixed inputs/iterations, observable checksums, empty PATH,2048MiB old-space and the unchanged60-second process bound. Keep warm small/indexed and seeded-open controls.

Whole-kernel adoption still requires fresh complete native/generated/canonical qualification, independent artifact checks and the original Church/repeated/Prelude/stuck-projection comparison. This branch is isolated from the main497 candidate; do not merge it or relax the main restored-production guard prematurely. B OPEN, C FAIL and D OPEN remain unchanged.
