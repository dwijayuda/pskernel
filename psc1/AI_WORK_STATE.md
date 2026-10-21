# PSC1 current work state — semantic closure admitted and strict IR accepted; continue backends

Updated 2026-10-21. Active draft [PR #172](https://github.com/dwijayuda/pskernel/pull/172)
preserves #171 at1fad9ed53cda9b23ac30be9cea85e7857437564e and every prior commit.
Execute the [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md) continuously.
The user explicitly requests no small-milestone handoffs.

## Qualified semantic source checkpoint

Head50c4fa029677643cc34038513f32a117755116e1 passed full scoped Linux
[39518543422](https://github.com/dwijayuda/pskernel/actions/runs/39518543422)
37/37 steps and focused
[39518543586](https://github.com/dwijayuda/pskernel/actions/runs/39518543586)
11/11. Tested merge43f9becf9d4175aaf4231c8f19a5ca43d9b806a9.
Exact [semantic source receipt](docs/PSC1_SEMANTIC_SOURCE_QUALIFICATION_2026-10-21.json).
Scoped artifact12310957077 digest
sha256:ab86b1dcba2da911ac57755b67b5bba292eb5ac250ec8fb1b89bde2b539dd0a0.
Artifact retention applies; committed receipt is durable.

BOTH grammar lanes: semantic67/67/67, DirectJS79/75/73, Rust83/76/72
(modules/parse/elaboration). The actual strict semantic command accepted the
complete67-module phase in each lane.38 census integrity checks passed.
PS is owned canonical translation from repository Lean, retained with exact
input byte counts/SHA256; it is not independently authored PS compiler source.

ParseDo and all subsequent semantic source blockers are corrected. Maintained
both-lane gates cover the syntax frontends/printers, environment/context, do/data/
operator elaboration, Term, Recursion, loop lifting, Declaration and Ordinary.
Every original named declaration remains; structural workers make changing state
explicit. All prior Ast/Erasure.Definition/ParseCommon/Binding/Operators gates remain.
Dedicated ordinary/namespace groups and all existing native admission, strict IR,
seven-target, Python minimum, installed-toolchain, Wasm and source tests passed
within their existing scopes. This is scoped execution evidence, not preservation
or self-hosting proof. The earlier frontend receipt at4906ff5f remains unchanged.

## Exact whole semantic closure — passed both grammar lanes

Headb412fb2335605cad2423fec29bf91b4f3b602ccb passed the dedicated
[whole-closure Linux run39520368282](https://github.com/dwijayuda/pskernel/actions/runs/39520368282).
Tested merge3488a870288f87bdfb96b7072fe6da0e57797869.
Both fresh native-owned PSC1 grammar lanes prepared and independently admitted
all2423 actual Core declarations for the exact67-module phase, then erased the
SAME immutable prepared value and passed the actual strict IR entry point.
Canonical admission bytes match across languages. Exact source/import/hash
ownership and complete source/member origin coverage were checked.

[Committed closure receipt](docs/PSC1_SEMANTIC_CLOSURE_ADMISSION_IR_2026-10-21.json).
Artifact12309984018 digest
sha256:a71399ab08b4fa05f3cda0e66aa87c9265ceb623caa3021c3a9a12c55c2f37be
retains exact parser inputs, canonical admissions, origins, hashes and stage
diagnostics. Retention applies. The receipt is diagnostic, not an authority token.

The existing official Lean4.35 provider replays every converted declaration using
its unchanged kernel limits in a fresh provider-prelude environment. Owned-kernel
checks are separate. These results concern the exact compiler source graph.
They do not prove erasure/backend preservation, general language conformance,
generated compiler execution, self-compilation or fixed points.

`node scripts/compiler-closure-qualification.mjs --phase semantic-compiler`
reproduces the fresh-state check. New dedicated workflow and focused regression
workflow both passed at that head. Full scoped source qualification is recorded
at the prior50c4fa0 checkpoint above; newer full scoped CI is still tracked live.

## Continue backend source normalization

The current complete Specialize normalization candidate addresses the next actual
parse refusal in DirectJS and Rust:
Ps.CompilerIr.Specialize51:15 (infix product type). Then Validate/BackendCommon.Plan
deriving/library sugar and JS/Rust printer/type/expr/module blockers remain.
Normalize complete source modules; preserve specialization keys, request order,
validation gates and every budget. Do not filter declarations or widen grammar as
a shortcut. Research shared helpers/finite iteration when the real compiler
workload requires them.

Cloud commands:
`lake build psc1_source_census_probe psc1_ordinary_tests`;
`node scripts/compiler-source-census-contract-tests.mjs`;
`node scripts/compiler-source-census.mjs --strict-phase semantic-compiler`;
`node scripts/compiler-closure-qualification.mjs --phase semantic-compiler`.
Strict selected phases also accept directjs-compiler/rust-compiler once complete.
Source reports: inventory.json, stages.json, stages-ps.json, strict-semantic.json,
translated-ps/. PS diagnostic coordinates belong to retained PS input.

## Active Specialize candidate — pending Linux CI

Normalize the complete CompilerIr.Specialize source, not only51:15. Preserve every
original named declaration, exact specialization key formats, request/diagnostic
ordering, duplicate handling, ground/arity checks, record/binding reconstruction,
and validation before/after specialization. Use explicit Prod/constructors, named
projections and existing owned list/string helpers. Recursion state is returned
as typed functions; budgets64/128/16384 remain unchanged. Existing generic,
forged-validation rejection and closed-input specialization tests run in focused
CI in addition to every previous group. Both grammar gates require full module
parse/elaboration. No semantic source or checker algorithm was changed.

Whole-closure logs now also print actual canonical admission hashes and the first
strict-IR findings while full diagnostics remain in the artifact.

## Boundaries and constraints

Official checker Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Owned-kernel checks are separate and are not the active logical checker.
Whole semantic closure independent admission/strict IR passed the exact run above;
DirectJS/Rust whole closures remain not-run;
generated compiler execution, self-compilation and G1/G2/G3/R1/R2/R3 remain not-run.
All14 full Practical Core families remain incomplete; collections/iteration
efficiency, Rust callbacks, typed IO and remaining parity stay open.
Wasm component ABI remains Bool-only. PSC2/Lean4.34 history is not qualification
of this compiler. The final #171 scoped39508739868/focused39508739941 were verified
before this continuation's writes.

GitHub/Linux CI only. Expected-SHA non-forced descendants; no main merge, release,
registry publication, unchecked axioms/authority, test weakening or budget/pin
relaxation. Preserve all prior immutable receipts and exact passed/pending bounds.
