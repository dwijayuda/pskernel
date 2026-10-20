# PSC1 current work state — shared parser source normalization

Updated 2026-10-21. Draft [PR #171](https://github.com/dwijayuda/pskernel/pull/171),
branch fix/psc1-parsecommon-normalization-20261021, preserves
[PR #170](https://github.com/dwijayuda/pskernel/pull/170) at
bdd26a4bd501cf92d207e72a98f5f15874885d82 and all earlier ancestry.
GitHub/Linux CI only; expected-SHA non-forced updates. No merge, release or publication.

## Exact qualification

PR #170's final head was verified before writes: scoped
[39502865307](https://github.com/dwijayuda/pskernel/actions/runs/39502865307)
passed37/37 steps, tested merge46624bf15fb36ddf3d57aeb45fa6922947bd1918;
focused [39502865431](https://github.com/dwijayuda/pskernel/actions/runs/39502865431) passed.

Current source checkpoint: db72f0d9947aa1700599eca9cffbe6879a684b5e.
[Scoped Linux 39506934493](https://github.com/dwijayuda/pskernel/actions/runs/39506934493)
passed37/37 steps, testing merge483be6cff76389e8c88613b7b9ecf58a082e4b2e.
Focused [39506934509](https://github.com/dwijayuda/pskernel/actions/runs/39506934509)
passed all25 census behavior observations, seven existing control groups,
the independent operator Core-equivalence/refusal suite, and data/pattern
admission/execution suite. These are scoped observations, not a preservation theorem.
The commit recording this state is a documentation descendant with unchanged
source/test/workflow/pin bytes. See
[immutable receipt](docs/PSC1_SYNTAX_NORMALIZATION_QUALIFICATION_2026-10-21.json).

## Corrected and retained

- ParseCommon: explicit list/name/result constructors, typed structural namespace
  text/equality/path workers, typed scoped parser state and explicit local match
  result. Replace grouped-expression field projection with a named span.
- ParseBinding: retain its public parser type alias as a named type definition;
  spell Except sequencing, tuple grouping and structural fuel workers explicitly.
  Preserve unit/singleton/right-nested tuple shapes, comma policy, annotation and
  exact token consumption, without skipping declarations.
- Operators: retain the fixed precedence table, associativity, nonassociative
  comparison refusal and primitive-domain restrictions. Use named String equality,
  an equivalent Bool Nat guard, and correctly applied structural fuel workers.
  No new source operator or proposition-order feature is enabled.
- Preserve worker evaluation placement. Empty scoped input returns with an
  unused billion-unit fuel bound in native execution. This is not a generated
  compiler complexity or stack-safety qualification.
- Census gates require complete parse/elaboration of Ast, ParseCommon,
  ParseBinding, Operators and Erasure.Definition. Diagnostics and all other
  refused/import-blocked records remain. Budgets and tool pins are unchanged.
  Focused Lean installation has bounded retries for observed TLS failures.

## Evidence progression

Initial test checkpoint2f86128a88ed07c3532049fc89ff73a15eb5cfdd failed because the
new native harness mixed the two frontend error types. The harness was corrected;
no source/test refusal was waived.
49bb03d36d625d1eff38ab7078c667c424d29b32 run39505209801 attempt1 failed pinned-Lean
TLS before compilation; attempt2 passed behavior checks and exposed Common814:69
grouped projection. 706073bcaefbd7c2532acdb2480b97e5fd13c40d run39505667269
then parsed Common and isolated `matchExpectedType` at its scoped worker.
48aa400b347f262631e99fdb06a1c8a86a055619 run39505999415 accepted Common.
12641fd2cc14c515fdd1286eeafefc8fed41f1dd run39506354023 accepted all three
modules and existing suites. Superseded scoped runs were cancelled, not qualified.
Current qualification above includes the evaluation-placement regression.

## Census and next work

Modules / parse accepted / elaboration accepted:

| Phase | PR #170 | Current |
| --- | --- | --- |
| semantic-compiler | 67 / 41 / 37 | 67 / 44 / 40 |
| directjs-compiler | 79 / 49 / 43 | 79 / 52 / 46 |
| rust-compiler | 83 / 50 / 42 | 83 / 53 / 45 |

Next first parse refusal in every phase: Ps.Syntax.ParseDo124:67,
`expected ', or }', got '.'`. Source owner psParseDoBindingValue projects
`(psSyntaxTermSpan value).stop`; normalize through a named span, then rerun
the complete module to expose subsequent refusals. Preserve do/catch layout.
There is no direct elaboration refusal in the observed inventory; later source
still fails parsing or is import-blocked. Census completion is not closure acceptance.

Resume in Linux CI: `lake build psc1 psc1_source_census_probe psc1_census_normalization_tests psc1_operator_tests psc1_data_tests`;
`node scripts/compiler-source-census.mjs`. Inspect the inventory/stages artifacts.
Continue topological normalization, independently tracked PS census and strict
selected-phase acceptance from the [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md).
Its historical Ast/erasure blockers are superseded by current work state/receipts.

## Assurance boundary

Census remains Lean-only. Whole-closure independent admission/IR, generated
compiler execution, self-compilation and fixed points remain not-run. Generated
JS/Rust transport is not compiler self-hosting. Official Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc remains the independent checker;
owned-kernel testing is separate. Ordinary exact source/body pairing, strict IR,
ABI validation, verified refusal and atomic publication remain mandatory.

All fourteen full Practical Core families remain incomplete, including efficient
indexing/finite iteration, Rust aggregate callbacks, typed IO and full parity.
Component ABI is Bool-only. Historical Lean4.34/PSC2 receipts do not qualify the
current compiler. Foundation and PR #170 receipts remain unchanged.
