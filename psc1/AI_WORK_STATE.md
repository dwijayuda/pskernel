# PSC1 current work state — continuous source closure execution

Updated 2026-10-21. Active draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172)
preserves #171 at1fad9ed53cda9b23ac30be9cea85e7857437564e and all prior history.
Execute the [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md) continuously
through subsequent blockers; the user explicitly rejects small-milestone handoffs.

## Qualified frontend checkpoint

Head4906ff5f520acda45cf4128effcbe226f2311e6f passed scoped Linux
[39512729664](https://github.com/dwijayuda/pskernel/actions/runs/39512729664)
37/37 steps and focused
[39512729792](https://github.com/dwijayuda/pskernel/actions/runs/39512729792)
11/11. Tested merge8733eb8d419c073f401527519ad2c4f02c48351c. Exact receipt:
[frontend qualification](docs/PSC1_FRONTEND_NORMALIZATION_QUALIFICATION_2026-10-21.json).
Retained scoped artifact12306479654 digest
sha256:7747d254008f59389b3f51b93b491e136556bdfadb3966a57850e39001ce206a.
Artifact retention applies; the committed receipt is durable.

ParseDo, ParseData, ParseLean, ParseProofScript, PrintCommon, PrintLean and
PrintProofScript now parse AND elaborate in BOTH measured grammar lanes.
All earlier Ast, Erasure.Definition, ParseCommon, ParseBinding and Operators
gates remain enforced. No original declaration was removed. ParseDo adds span
helpers. Native do/while/data/operators/typed-error/normalization checks and the
full scoped admission, strict IR, seven-target runtime, namespace, minimum
Python, direct Wasm component and installed npm toolchain checks passed within
their existing scopes. This is scoped execution evidence, not full language proof.

Both lanes: semantic67/51/48, JS79/59/54, Rust83/60/53
(modules/parse/elaboration). First Lean parse refusal is
Ps.Environment.Control30:7 (missing explicit let separator); PS translation
refuses at the same original source. Full per-module refusals are in CI logs.

## Subsequent focused source checkpoint — full scoped CI pending

Normalize Environment.Control, SelfHostProd, Resolve, Elab.Context, DoBase,
DoFor, DoWhile, DoTry, Data and Operators. Keep exact checked operation construction and guards.
Use explicit constructors, binders, Except sequencing and structural workers.
Control application carries its changing expression through a returned function.
Resolve retains default no-self lookup plus an explicit self-candidate helper.
Context initializes namespace/helper fields explicitly. Do joins/open-state workers
carry evolving contexts/state through structural list folds. Preserve collection
and bound evaluation order, continuation delay/capture, primitive/inductive while
result restrictions, partial-helper requirement, error state reset, early return
packets, and handler boundaries. No runtime execution fuel or new selected feature.

All ten subsequent modules have maintained parse/elaboration gates in BOTH
lanes and now pass focused Linux CI at4250f5d0de52d4d409804c380b33d8c073c38eed
(run39515329696). Native typed-error, normalization, data, operator, do, while
and namespace suites passed.38 integrity checks and live strict incomplete-closure
refusal passed. Both lanes: semantic67/61/60, JS79/69/66, Rust83/70/65.
Full scoped qualification of this later source batch is still pending. Existing tests remain; focused CI additionally executes the dedicated
namespace suite and retains the actual resolver/context caller audit.
Do not transfer the qualified checkpoint to this candidate before actual CI.

Latest focused run39514902700 at e285ed994727654823fffb75f2187d45307ae861:
all native behavior and dedicated namespace groups passed;38 census contract
checks passed. Both lanes measured semantic67/58/53, JS79/66/59, Rust83/67/58.
The maintained Resolve gate correctly refused nested constructor pattern107:17.
The current candidate expands that pattern into nested matches, then continues
Data and Operators. Earlier run39514468960 stopped before census solely because
rg was absent; the audit now uses grep when necessary. No checks were waived.

Data keeps checked fold-based optional lookup, exact array/index evaluation order,
duplicate binding rejection and tuple projection scope. Operators retain literal
constraint ordering, left-to-right constructed runtime evaluation, Nat/Bool
equality, selected arithmetic and explicit proposition-order refusal. Existing
private data helper names are retained as plain definitions so every declaration
is part of source preparation, rather than filtered out.

## Active do-controller candidate — pending Linux CI

The next actual refusal is Ps.Elab.Do27:11, untyped fuel-branch lambdas.
Normalize complete controller source with typed callbacks, explicit constructors,
list construction and let separators. Preserve psElabDoBodyWithExit and all public
entry points; a new structural worker carries result/onReturn/liftTerminal in its
returned function so nested try contexts do not change fixed recursion parameters.
The existing4096 controller budget is unchanged. No runtime execution fuel added.
The full module must parse/elaborate in BOTH lanes. Continue to Term, Recursion,
DoLoopLift, Declaration and Ordinary after the next actual census result.

## Census integrity and continuation

Fresh Lean and PS preparation states measure the full ordered explicit import
closure. PS input is owned canonical translation from repository Lean, retained
as readable .ps with exact byte counts and SHA256. It is not independently
authored PS compiler source. Record path/grammar/bytes/order/import ownership,
failure propagation, unchanged source snapshots, and fresh output integrity are
checked.38 contract checks passed. The live strict semantic check actually
refused incomplete closure as expected; it does not qualify the source closure.

Cloud commands:
`lake build psc1 psc1_source_census_probe psc1_census_normalization_tests psc1_operator_tests psc1_data_tests psc1_do_tests psc1_while_tests psc1_namespace_tests`;
`node scripts/compiler-source-census-contract-tests.mjs`;
`node scripts/compiler-source-census.mjs`;
`node scripts/compiler-source-census-strict-tests.mjs`.
Manual strict gate:
`node scripts/compiler-source-census.mjs --strict-phase semantic-compiler`
(or directjs-compiler/rust-compiler). Every selected module must translate where
needed, parse and elaborate in BOTH lanes; import-blocked modules also refuse.
Inspect inventory.json, stages.json, stages-ps.json, strict-semantic.json and
translated-ps/. PS diagnostic coordinates refer to retained translated input.
Continue correcting the complete next refused module, then whole-closure
independent admission/IR and generated compiler execution after prerequisites.

## Retained boundaries

Official Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc is the independent
checker. Owned-kernel checks are separate. Whole-closure admission/IR, generated
compiler execution, self-compilation and fixed points remain not-run. All14 full
Practical Core families remain incomplete. Collection/iteration efficiency, Rust
callbacks, typed IO and parity remain open. Wasm component ABI remains Bool-only.
Earlier PSC2/Lean4.34 receipts do not qualify this compiler. Historical receipts
are preserved. Parent #171 final scoped39508739868 and focused39508739941 were
also verified before writes.

GitHub/Linux CI only. Expected-SHA non-forced history-preserving commits; no main
merge, release or npm registry publication. No unchecked axioms, fabricated
authority, declaration filtering, parser widening, relaxed tests/budgets or pins.
