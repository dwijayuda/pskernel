# T05 public paged layout proof handoff — 2026-10-25

## Implemented proof boundary

The five theorems in `psc1/test/PsKernelExprV2LayoutBoundaryProofs.lean` prove physical Layout from the actual production shape guard and replay validator. No production code changes are required. The fixed proof module is 11,733 UTF-8 bytes, Git blob `923d74270fdc307e58922ad78c44887eaf4041a7`, SHA256 `7a56146d72dcd6b6ea8515be962eaba49a1af392d868e76eff6f68ca9fa03c3b`.

| Theorem | Premise and conclusion |
|---|---|
| `shape_valid_establishes_layout` | The actual shape guard returns true for an arbitrary source; derive its positive page capacity, complete frozen pages, active-page bound and exact total size. |
| `validate_ok_establishes_source_layout` | The actual public validator returns success; derive source Layout without a source validity premise. |
| `replay_node_ok_preserves_layout` | The internal canonical accumulator has Layout and an actual replay step succeeds; derive returned accumulator Layout for every node constructor. |
| `validate_fuel_ok_preserves_layout` | An actual fuelled validator succeeds from an internal accumulator with Layout; derive result Layout for arbitrary source and starting ID. |
| `validate_ok_establishes_canonical_layout` | The actual public validator succeeds; derive returned canonical Layout from the real empty seed, with no caller-supplied source or output Layout premise. |

The internal accumulator assumptions are explicit. No theorem supplies or assumes metadata correctness, topological decoding, decoder correspondence, or ArenaModel. Those obligations remain open. All previous paged proofs and the checked-index/getD repair remain unchanged.

## Native checkpoint and artifact contents

Exact source `9c48af315d254b0263f4013eb3f0183e27b662af` passed [native preflight 40154659804](https://github.com/dwijayuda/pskernel/actions/runs/40154659804), attempt 1, job 121053355557: metadata8 + paged17 + boundary5 = 30 ordered reports, only the standard permitted axioms. Its source archive includes all ten inputs and the hidden workflow, for 17 total files. Artifact 12583768183 is 26,125 bytes; ZIP SHA256 `c601465fd3b980775d7c8cb03e29479df68d5130b1aa605eca148eca0aacd9be`.

[Independent content audit 40155650832](https://github.com/dwijayuda/pskernel/actions/runs/40155650832), source `fe01b4709b86d24cdb81b694ed7073a1054642d4`, job 121056378892, authenticated all 17 extracted files, ten exact source byte/blob pins, both receipts, all 30 ordered reports and statuses, and their limited scope. It independently hashed the raw ZIP and checked the pinned official download action's matching actual digest. It uses official extraction; it does not implement or claim an independent raw ZIP parser. Audit artifact 12583759407 contains 23 files, 63,157 ZIP bytes, SHA256 `b43f0726b24ec8b42035fea5e5b57e492118df281efc271283b8ca471f752c52`.

The complete source/native/audit evidence is `qualification/T05_LAYOUT_BOUNDARY_PREFLIGHT_9c48af31.json`. The isolated branch inherits the held 80005 transform experiment; do not merge that branch. The active work branch copies only the exact proof blob onto restored production.

## Fresh full qualification required

The containing source includes the exact new module and extends `.github/workflows/psc1-pskernel-t05-header.yml` to 497 reports / 30 modules / 93 explicit inputs. It builds the already registered `PsKernelExprV2PagedModelNativeProofs` library before the early new proof check. The dedicated five-report log is separate from the dependency build log.

The existing 492-report and all earlier receipt chains remain required. A new `layout-boundary-native-receipt.json` records the five new proof names, source/log/status digests, the retained492 parent digest and explicit physical-layout scope. Both generated routes retain all 17 scripts and runtime obligations. Only the archived source inventory gains the new proof file. Pinned Lean, fuel4096, negative controls, fallback and all production bytes remain unchanged.

The independent auditor's `layout` profile must require the fresh exact source/run/attempt, all497 globally distinct theorem names /30 distinct modules, the entire restored production tree, the fixed proof byte/blob pin, all source archives and all inherited runtime/ZIP checks. Run the existing native-first workflow; do not dispatch duplicates or reuse old qualification. Integration must advance only to the exact fully qualified source using a non-force expected-SHA update.

## Remaining work

Complete whole-arena metadata and decoder correspondence and connect actual replay validation to ArenaModel. Keep their current receipt flags false until proved. The broader B/C/D obligations remain separate: B OPEN, C FAIL, D OPEN. The held transform experiment must remain excluded; Church reduction-budget exhaustion and Init.Prelude timeout are unresolved.
