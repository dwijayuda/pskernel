# T05 production decoder storage and semantic bridge

## 2026-10-25 — actual production decoder bridge: native51 qualification pending

This isolated proof branch starts from `25cff6f2ad8fa6cd8b24b8c9241d9c6e3028089b`. Production remains byte-identical to qualified T05/layout source `20224a295359abb201f56c72395690bf0bfac9fa`. It does not carry the separately qualified empty-cache production change at `054edfce56eda28a166624ddc92dfac5af8499c0`.

The new `PsKernelExprV2DecodedBridgeProofs.lean` supplies twelve native obligations for actual fixed-64 decoded storage, old/new Require lookup preservation, semantic-prefix preservation, successful actual DecodeCanonicalFuel execution, and actual DecodeChecked success/correspondence after public validation. Internal DecodedLayout is established from the real empty owner and preserved by Push. The public theorems impose no validity/layout premise on untrusted external arenas, and use the actual canonical size-plus-one fuel. All claims about this new slice remain **pending** until native51 and independent artifact verification pass.

Retained qualification: local replay29 is archive-audited at `0b9d2086`; semantic-prefix37 at `58f90033` passed native run 40164899138 and actual21-member ZIP audit 40166874952 at auditor `6affe3f4` (37 ordered reports,13 inputs,four successful statuses,errors=[]). Actual decoded-node39 at `25cff6f2` passed run 40165751680 (39 reports,five modules,15 inputs); its independent ZIP audit is still pending.

Next: use the single matching-source `.github/workflows/psc1-pskernel-decoder-bridge-preflight.yml` run. Require exactly51 reports across six modules,16 source inputs,six successful proof commands and26 archive members. Repair only demonstrated errors without changing theorem statements. Then audit actual archive contents and combine the qualified proof modules into a fresh complete source-bound native/generated cohort.

Broader ArenaModel/full-kernel correctness and performance remain unproved by this slice. Project A scoped qualification is retained; B OPEN; C FAIL (173/193 strict matches,17 timeouts,one reduction-budget exhaustion,two separate unsafe/partial agreements on the last full Arena source); D OPEN. Church fuel exhaustion and Init.Prelude timeout remain unresolved. Preserve Lean4.35, fuel4096, negative controls, histories and supported generated/canonical routes; full DirectJS remains unsupported.

---

