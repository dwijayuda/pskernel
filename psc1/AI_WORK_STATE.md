# PSC1 current work state — continuous compiler closure normalization

Updated 2026-10-21. This continuation preserves qualified draft
[PR #171](https://github.com/dwijayuda/pskernel/pull/171) at
1fad9ed53cda9b23ac30be9cea85e7857437564e and all earlier ancestry.
Its final scoped run39508739868 passed37/37 steps and focused39508739941
passed11/11. Tested merge16581a45341e73b716865ff6c4446f4ca2c07728.

## Active execution

Continue the attached [Sol High execution plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md)
from current work state, not its historical #169 blocker list. The user requests
continuous execution through subsequent blockers, not a handoff at each small
milestone. Source normalization and complete selected closure acceptance remain
the current dependency. Do not report compiler self-hosting from transport or census.

ParseDo source normalization is pending Linux CI. Replace grouped-expression field
projections through named span helpers, use explicit constructors/Except sequencing,
type local match results, and correctly apply structural range/header workers.
Preserve source spans, token ownership, catch/match layout, namespace rules,
evaluation placement, signatures and all budgets. No declaration filtering or
notation expansion. The focused workflow adds existing do/while admission and
execution suites; maintained census gates require complete ParseDo acceptance.

Current qualified census before this change, modules/parse/elaboration:
semantic67/44/40, JS79/52/46, Rust83/53/45. First parse refusal:
Ps.Syntax.ParseDo124:67, grouped `(psSyntaxTermSpan value).stop`.
Ast, ParseCommon, ParseBinding, Operators and Erasure.Definition are accepted.
New acceptance/counts await actual CI.

## Next execution

Run focused/native census, diagnose the first true refusal with declaration/span
evidence, fix the complete source module, then continue topologically. Add an
independently tracked PS frontend lane and strict selected-phase census checks.
Qualify substantial source batches with full scoped Linux CI, retaining all
existing tests. Continue into whole-closure admission/IR and generated JS compiler
execution only after their source prerequisites pass.

Resume cloud commands:
`lake build psc1 psc1_source_census_probe psc1_census_normalization_tests psc1_operator_tests psc1_data_tests psc1_do_tests psc1_while_tests`;
`node scripts/compiler-source-census.mjs`.
Inspect compiler-source-census inventory/stages and all refused/import-blocked rows.

## Retained assurance and constraints

Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains the independent
checker. Owned-kernel native checks are separate. Preserve ordinary exact
source/body pairing, strict IR, target/ABI validation, unavailable-verified refusal
and atomic publication. No unchecked axioms or fabricated certificates.

Census is currently Lean-only; whole-closure admission/IR, generated compiler
execution, self-compilation and fixed points remain not-run. All fourteen full
Practical Core families remain incomplete. Efficient collections/iteration,
Rust aggregate callbacks, typed IO and remaining parity are still open.
Wasm component ABI is Bool-only. Historical Lean4.34/PSC2 receipts are not
qualification of this compiler. Existing immutable receipts remain unchanged.

GitHub/Linux CI only. Expected-SHA non-forced updates, no main merge/release/npm
publication, no changed tool pins or relaxed tests/budgets. Keep exact passed,
failed, in-progress and pending boundaries here and in execution status.
