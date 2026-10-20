# PSC1 current work state — continuous compiler closure normalization

Updated 2026-10-21. Active draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172)
preserves [PR #171](https://github.com/dwijayuda/pskernel/pull/171) at
1fad9ed53cda9b23ac30be9cea85e7857437564e and all earlier ancestry.
Parent final scoped run39508739868 passed37/37 steps; focused39508739941
passed11/11. Tested merge16581a45341e73b716865ff6c4446f4ca2c07728.

## Active execution

Execute the attached [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md)
from current evidence, not its historical #169 blockers. The user explicitly
requests continuous work through subsequent blockers, without small milestone
handoffs. Current prerequisite is complete compiler closure source acceptance.

ParseDo now parses and elaborates in focused Linux run39511079292
(head cd1f0bfa3303efb3f8e45cc5b6e5b457485dcde2). Existing typed-error,
normalization, operator, data, do and while native suites passed in that run.
Semantic67/45/41, JS79/53/47, Rust83/54/46 (modules/parse/elaboration).
Scoped CI for that intermediate head was superseded/cancelled, not qualified.

Changes preserve token/span ownership, layout, evaluation placement and budgets:
named span helpers, explicit constructors/Except sequencing, typed local matches,
and structural range/header workers. ParseData normalization additionally preserves
tuple grouping/comma policy, array push order and strict optional-index adjacency.
Its next confirmed refusal was infix cons construction at44:63 in run39511657432;
the current candidate uses List.cons. ParseLean source sequencing and shorthand
normalization is also submitted. Complete acceptance of both remains pending.

## Independent grammar measurement and strict gate

The native census now runs fresh Lean and PS preparation states over the same
ordered explicit import closure. PS input is owned canonical translation of each
repository Lean module, retained with UTF8 byte count, SHA256 and readable .ps
artifacts. It is not an independently authored PS compiler or a fixed point.
Both lanes actually parse/elaborate; acceptance is never copied across lanes.

Run39511657432 passed38 census contract checks and independently measured both
lanes. Each then reported semantic67/45/41, JS79/53/47, Rust83/54/46, with
ParseData refusing Lean parsing and PS translation. Its overall result failed,
as required by the maintained ParseData acceptance gate. No refusal was waived.

Integrity checks reject missing/duplicate/reordered/unknown modules, incorrect
source metadata/import ownership, invalid stage transitions and stale outputs.
The driver rehashes original sources after both probes. Optional
`--strict-phase semantic-compiler|directjs-compiler|rust-compiler` refuses until
every module translates where needed, parses and elaborates in BOTH lanes,
including every import-blocked module. Default mode is an explicit partial census.
The consolidated scoped receipt now requires and records both actual lanes.

## Continue execution

Inspect current focused Linux run, correct complete source modules topologically,
and retain maintained gates. Prepare PS frontend normalization next. Qualify
substantial batches with full scoped Linux CI; keep every existing test.
Whole-closure independent admission/IR and generated compiler execution follow
only when their source prerequisites pass.

Cloud commands:
`lake build psc1 psc1_source_census_probe psc1_census_normalization_tests psc1_operator_tests psc1_data_tests psc1_do_tests psc1_while_tests`;
`node scripts/compiler-source-census-contract-tests.mjs`;
`node scripts/compiler-source-census.mjs`;
`node scripts/compiler-source-census.mjs --strict-phase semantic-compiler`.
Strict mode is currently expected to refuse incomplete closure; its refusal is not
a completed source qualification. Inspect inventory.json, stages.json,
stages-ps.json and translated-ps/ artifacts.

## Assurance boundaries and constraints

Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc is the independent
checker. Owned-kernel checks remain separate. Preserve exact source/body pairing,
strict IR, ABI validation, unavailable-verified refusal and atomic publication.
No unchecked axioms, fabricated authority, parser expansion, skipped declarations,
runtime execution fuel, changed tool pins or relaxed tests/budgets.

Whole-closure admission/IR, generated compiler execution, self-compilation and
fixed points remain not-run. All fourteen full Practical Core families remain
incomplete. Efficient collections/iteration, Rust callbacks, typed IO and parity
remain open. Wasm component ABI remains Bool-only. Historical PSC2/Lean4.34
receipts do not qualify this compiler. Immutable prior receipts remain unchanged.

GitHub/Linux CI only; expected-SHA non-forced branch updates. No main merge,
release or npm registry publication. Record exact passed, failed, cancelled,
in-progress and pending boundaries.
