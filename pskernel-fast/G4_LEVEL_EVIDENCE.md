# PSKernel-Fast V3 — G4.0 symbolic universe positive equivalence

**Semantics target:** pinned Lean `4.35.0-rc4` at commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Current validated source:** [`4c37b7f4a0cc287dbba77d004dd33ffd6f10dd8b`](https://github.com/dwijayuda/pskernel/commit/4c37b7f4a0cc287dbba77d004dd33ffd6f10dd8b).  
**Validated cloud run:** [GitHub Actions 38109715920](https://github.com/dwijayuda/pskernel/actions/runs/38109715920), job `114382566956`, **passed**.  
**Independent V3 audit:** 12 Lean source files; zero legacy kernel imports. 30 native Lean build jobs passed.

## Implemented symbolic semantics

- `ULevel.denote ρ` gives a mathematical Nat interpretation for all symbolic assignments.
- `smartMax`, `smartIMax`, `smartSucc` and recursive `normalize` implement *conservative* positive-equivalence rewrite families; hashes select orientation only, with exact `DecidableEq` for all positive identities.
- `positiveEquivalent` answers true only when structural normalized forms agree. `compare` first verifies declared universe parameters and bans metavariables; results are `equal`, `unresolved`, `malformed`. **Unresolved never implies not equal.**
- `smartMax_denote`, `smartIMax_denote`, `smartSucc_denote`, `normalize_denote`, `positiveEquivalent_sound` and `compare_equal_sound` compile as Lean theorems; they establish that **every positive answer entails equal Nat denotation under all KName assignments**. This is *not* full Lean 4.35 algorithmic completeness, nor an environment/model consistency proof.
- The G4.0 test harness—not the normalizer—calls official Lean's `Level.isEquiv` for independent positive-outcome agreement. It also reports how many official-positive pairs remain undecided.

## Pinned Lean-4.35 differential counts (source-specific)

| Source and run | Paired test expressions | Recognized positives | Official-positive unresolved | False positive vs official |
| --- | ---: | ---: | ---: | ---: |
| `99613fd`, [run 38109322957](https://github.com/dwijayuda/pskernel/actions/runs/38109322957) | 13 (169 pairs) | 27 | 0 | 0 |
| `ae846d1`, [run 38109450733](https://github.com/dwijayuda/pskernel/actions/runs/38109450733) | 36 (1296 pairs) | 84 | 22 | 0 |
| **`4c37b7f`, [run 38109715920](https://github.com/dwijayuda/pskernel/actions/runs/38109715920)** | **36 (1296 pairs)** | **98** | **8** | **0** |

Latest additions are proved `imax 1 u = u` and `succ(max u v) = max(succ u)(succ v)` rewrite families. The remaining **eight test-pair** gaps and all untested term families need further completeness research; do not infer an 8-case global difference.

## Remaining mandatory work

1. Official-style max flattening, ordering, offsets, duplicate/subsumed terms, and more complete `imax` simplification where proven worthwhile; validate against larger structured oracle corpora.
2. `is_geq` and symbolic universe inequality/constraint logic. A denotationally sound normalization shortcut is **not** necessarily a complete official decision procedure.
3. Environment-backed constants, arity, safety and immutable transaction semantics (G4.1).
4. Actual fully checked `Sort`/`Pi`/lambda/application/let judgments, typed proof irrelevance, kernel DefEq, recursors/quotients and admission.
5. Complete model/refinement and conditional consistency; no `False` assurance without declared modeled-axiom policy.

No proof-acceptance API exists. G4.0's equality mechanism is still **research-only and may return unresolved**. Never equate a positive theorem about Nat interpretations with a proof of full Lean kernel soundness.
