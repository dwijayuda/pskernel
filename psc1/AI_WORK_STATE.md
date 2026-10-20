# PSC1 current work state — compiler census blockers corrected

Updated 2026-10-21. Draft [PR #170](https://github.com/dwijayuda/pskernel/pull/170)
on fix/psc1-census-normalization-20261021 continues qualified
[PR #169](https://github.com/dwijayuda/pskernel/pull/169) at
6d2cc114f6534a8d56343cfe91a6c966368ccacf. All prior branches and ancestry are
preserved. Updates use expected-SHA fast-forwards. No main merge, release or publication.

## Exact implementation and qualification

Source checkpoint: 81f271292086da3cd9f266115300086998360217.
The commit recording this state is a documentation descendant; source, tests,
workflow and tool pins are unchanged by that documentation update.

[Scoped Linux run 39501336732](https://github.com/dwijayuda/pskernel/actions/runs/39501336732)
passed all 37 steps, testing merge 6eb2a7c140ac56a32d37dbef00a874c296137605.
Focused [Linux run 39501336380](https://github.com/dwijayuda/pskernel/actions/runs/39501336380)
passed all seven existing native control groups, all eleven new census behavior
checks, and the full source census. See
[census normalization receipt](docs/PSC1_CENSUS_NORMALIZATION_QUALIFICATION_2026-10-21.json)
for exact heads, merge commits, artifacts and scope.

## Corrected source boundary

Ast now parses and elaborates as a complete module. A named structural name-list
append preserves left-to-right order, duplicates and source spans. Namespace
helpers use explicit list/name/declaration constructors. Recursive binding-name,
size, declaration qualification and span helpers expose structural source
arguments; qualification recurses on the declaration before receiving the
namespace accumulator. No parser feature was added or declaration omitted.

Erasure.Definition now elaborates as a complete module. Its runtime-prelude
closure binds the recursive function at exactly its three explicit arguments
before applying the selection. Existing fuel, candidate ordering, metadata,
transitive dependency pruning and stabilization are retained.

The census requires Ast parse/elaboration and Erasure.Definition elaboration
acceptance. Failures retain source declaration/index/span from the actual
elaboration attempt. Native checks cover duplicate names/spans, nested namespace
order, declaration spans, pattern size, zero fuel, direct/transitive dependencies,
unused-definition pruning, metadata order, empty candidates and stabilization.

Reproductions remain in history: caa31ae6686091f450a6c9e03a84816120ca0ceb,
[run 39500111608 attempt 2](https://github.com/dwijayuda/pskernel/actions/runs/39500111608),
resolved erasure but exposed Ast shorthand constructor parsing at 193:7.
Attempt 1 failed downloading pinned Lean due to TLS, before compilation.
5246906a1211fb521701717c3ee7c6f8ead8cae0,
[focused run 39500923458](https://github.com/dwijayuda/pskernel/actions/runs/39500923458),
passed the earlier parse-only Ast gate but still reported
`unknownName:psSyntaxBindingPatternNames`; that checkpoint is partial.
The current stronger gate requires Ast elaboration too.

## Measured census and next work

Counts are modules / parse accepted / elaboration accepted:

| Phase | PR #169 | Current source |
| --- | --- | --- |
| semantic-compiler | 67 / 40 / 35 | 67 / 41 / 37 |
| directjs-compiler | 79 / 48 / 41 | 79 / 49 / 43 |
| rust-compiler | 83 / 49 / 40 | 83 / 50 / 42 |

The first parse refusal in all three phases is now Ps.Syntax.ParseCommon,
`86:26: expected ', or }', got '::'`, in psSyntaxRootName.
There is no remaining direct elaboration refusal in this observed inventory;
later modules still refuse parsing or remain blocked by failed imports.
Census completion is not complete source acceptance.

Next continue dependency-ordered source normalization from ParseCommon, then
strict dual-grammar census with explicit translation/parse/elaboration evidence.
The current census is Lean-only. Whole-closure independent admission, IR,
generated compiler execution, self-compilation and fixed points remain not-run.
Generated JS/Rust checker transport is not compiler self-hosting.

## Preserved architecture

One shared AST/elaborator, canonical Core and checked expression IR remain.
Official Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
is the independent logical checker; owned-kernel tests are separate.
Ordinary source/body pairing, strict IR, target/ABI validation, unavailable-verified
refusal and atomic publication remain mandatory. No backend-preservation theorem.

The [qualified foundation receipt](docs/PSC1_ULTRA_FOUNDATION_QUALIFICATION_2026-10-21.json)
is unchanged. All fourteen full Practical Core families remain incomplete,
including efficient optional indexing/finite iteration, Rust aggregate callbacks,
typed IO and remaining grammar/backend contracts. Wasm component ABI is Bool-only.

Continue the [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md) with this
state taking precedence over its historical blocker list. Preserve tests and
budgets; use GitHub/Linux CI only. Historical Lean4.34/PSC2 receipts do not qualify
the current 4.35 compiler. Record exact completed/pending boundaries.
