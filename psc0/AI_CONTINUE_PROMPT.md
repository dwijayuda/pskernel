# Continue PSC0 / PSCV0 v7 M2 + Phase A

## 15 October — constructor source and full proof audit passed; regeneration environment corrected

At research 1e45a3dd, full proof replay 38713950619 passed; native 38713950473 passed source checks, all three exact pins (1,879 declarations /25 classes /226 instances), and constructor argument/runtime refusals. The new byte-regeneration step could not locate the host Ps module because it lacked Lake's search path. It now invokes the native exporter through lake env, matching the successful independent authoring workflow. No compiler semantics or acceptance checks changed. Full runtime qualification is pending on this revision; main remains qualified at e5d1bdd6.

## 15 October — constructor pins measured; independent audit boundary fixed

Research dd532710 compiled the complete candidate. Native CI38712915969 refused the deliberate old pins and independently reported FNV fnv1a64:9256054256618924345, declaration SHA-256 0f62a5df0a7273a183e10700bf8eb49563afd0ff8d03b7be3935d4d310a12f04, surface SHA-256 240050e325b7c7d06827c36bffe7ed017ef18680b61ccf4fa7701807a62874b4. Pins now record exactly these values.

The separate full proof audit correctly refused a root already present in the newly selected constructor layer. All Float constructor authoring exports now use the frozen pre-constructor stage, so selected output cannot cut its own proof replay. No acceptance guard was relaxed. Full qualification of this revised candidate remains pending; the last qualified main code is e5d1bdd6. M2+A and executable Float remain incomplete.

## 15 October — minimal logical Float constructor integration candidate

Qualified baseline: main e5d1bdd6 (native 38711192827; full mask proof audit 38711192777). The independently checked 21-declaration /2-root constructor asset from research 412697cf, CI38711557857, is now integrated on this research branch, with a frozen pre-constructor boundary and mandatory byte-for-byte regeneration. Public Float.ofBits/Float32.ofBits wrappers retain ordinary typed lambda entries and actual Format.Valid evidence. No proof substitution, new assumption or runtime override.

The 922-declaration representation proof remains an authoring audit, not selected Standard. A compact source batch checks both logical constructors/projections, refuses a wrong-width argument, and requires unsupported Float execution to fail at the shared IR capability gate. Existing full runtime observations are reused unchanged. Snapshot pins remain the old reviewed values until independently measured; source/runtime integration qualification is pending. M2+A and executable F1-F4 remain incomplete.

## 15 October — List/kernel scope MAIN QUALIFIED; F1 constructor closure minimized

**Qualified main code `e5d1bdd6d667057bfd5376e8b39f3069f1dfc93c`** passed [native 38711192827](https://github.com/dwijayuda/pskernel/actions/runs/38711192827) and [portable mask proof audit 38711192777](https://github.com/dwijayuda/pskernel/actions/runs/38711192777). All native/backend gates passed at the same SHA. Complete List indexing is universe-polymorphic; actual C++ kernel counters are isolated by one shared awaited pooled-task mechanism. Standard stays 1,856 declarations /25 classes /226 instances, with the measured List pins recorded below. No test or kernel limit was weakened.

The next architectural cut has independent evidence: research `412697cf6811e32a37cf79ef955ed0c6c5a14b8c`, [38711557857](https://github.com/dwijayuda/pskernel/actions/runs/38711557857), passed both the full 30-root /922-declaration representation audit and the **two-root /21-declaration constructor closure**. The latter has 1,702 shared nodes, **307,290 UTF-8 bytes**, SHA-256 `3042b3db951a1c68f8df24c5161889841082f9f4ee03783e1e5b4da918b3f9a7`, only approved propext/Quot.sound, no axioms/replaced axioms and no theorem substitutions. Keep the 11 MB representation proof audit out of the selected constructor dependency closure.

Next: integrate only that small logical constructor/Format.Valid asset behind a frozen regeneration boundary, expose checked Float.ofBits/Float32.ofBits aliases, and validate logical source admission while runtime Float remains refused. Then complete F1 typed representation/erasure/IR and JS/TS/Rust/Wasm/ABI together, followed by F2-F4 and remaining M2+A. No runtime Float or M2+A completion claim. No pskernel-core, self-hosting or C5.

## Working contract

GitHub canonical: dwijayuda/pskernel, branch psc0/pscv0-v7-native-lean-v1,
draft PR109. Inspect actual HEAD and exact-commit CI before writes; preserve
history using non-force expected-HEAD updates. The entry above records qualified main code and constructor research, not M2+A completion. Historical audit details remain in
AI_WORK_STATE.md; use its newest entries and live evidence.

Native portable .lean, pinned Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study corresponding official
sources/tests before each substantial feature. No Desktop Commander,
pskernel-core, self-hosting, bootstrap, compiler-source .ps migration or C5.
Wasm GC internally, linear memory only at explicit ABI boundaries.
Only propext and Quot.sound are approved; do not ask again or expand them.
Classical.choice-dependent native research is not portable proof evidence.

## Next critical path

1. Main List/kernel scope integration is qualified. Preserve that baseline.
   Integrate the independently checked 21-declaration constructor/validity asset
   using a frozen pre-constructor export boundary. Preserve byte-for-byte
   regeneration and inspect source aliases; keep runtime Float refused.
2. Keep the 30-root /922-declaration representation proof audit separate from
   the selected constructor closure. Its all-input mask bridges already replay;
   native upstream-ofBits correspondence still imports Classical.choice and is
   not a selected assumption or portable admission theorem.
3. Complete F1 selected Float32/64 source constructors, proof-carrying validity,
   shared typed erasure/IR and canonical bits; then F2 arithmetic/equality,
   F3 literals/conversions/rounding, F4 all-target ABI. Keep logical equality
   distinct from IEEE BEq, preserve signed zero, normalize NaN per pinned Lean.
4. Continue independent M2+A requirements: explicit 32/64 USize/ISize profiles,
   selected Standard APIs, deriving/search/elaboration and comprehensive manifest.
   Follow existing M2+A → M3+B → M4+C/D roadmap; no unrelated later work.

Implement coherent features then validate at meaningful milestones. Before
advancing, update BOTH AI_WORK_STATE.md and this continuation prompt with exact
SHAs, CI results, remaining limitations and next dependencies. Never declare
M2+A complete from bounded green CI or Float proof research alone.
