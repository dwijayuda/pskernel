# PSC1 current work state — semantic source closed; continue admission and backend sources

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

## Active whole-closure qualification — pending actual CI

The source checkpoint above has NOT independently admitted or erased the whole
compiler closure. A separate Linux workflow now exercises those stages instead
of inferring them from census or small fixtures.

`node scripts/compiler-closure-qualification.mjs --phase semantic-compiler`
requires complete accepted census inputs and starts fresh native-owned PSC1
states for the exact ordered phase in BOTH grammars. PS reads the retained actual
PS parser inputs; it never borrows Lean preparation state. Preserve complete
source/import/hash ownership and actual source/member origins. Every prepared
Core batch is counted, and exact canonical admission bytes are retained.

The existing official Lean4.35 provider checks every encoded declaration in a
fresh provider-prelude environment. The same immutable prepared value then feeds
erasure and the actual strict IR entry point. Retain failed stages/findings;
compare canonical admission bytes across grammars. No generated execution,
self-compilation, fixed point or formal-preservation result is claimed. A JSON
report is diagnostic, never an admission capability or authority token.

New host-only probe/driver/workflow code is pending Linux validation. All existing
budgets/pins remain unchanged; each native probe retains the240s process bound,
and closure workflow15min. Do not turn resource failure into source acceptance.
Canonical admissions, complete origin records, input/binary hashes and stage
diagnostics are CI artifacts under compiler-closure/semantic-compiler/.

## Continue backend source normalization

Next actual parse refusal in DirectJS and Rust is
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

## Boundaries and constraints

Official checker Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Owned-kernel checks are separate and are not the active logical checker.
Whole-closure independent admission/strict IR are pending the new workflow;
generated compiler execution, self-compilation and G1/G2/G3/R1/R2/R3 remain not-run.
All14 full Practical Core families remain incomplete; collections/iteration
efficiency, Rust callbacks, typed IO and remaining parity stay open.
Wasm component ABI remains Bool-only. PSC2/Lean4.34 history is not qualification
of this compiler. The final #171 scoped39508739868/focused39508739941 were verified
before this continuation's writes.

GitHub/Linux CI only. Expected-SHA non-forced descendants; no main merge, release,
registry publication, unchecked axioms/authority, test weakening or budget/pin
relaxation. Preserve all prior immutable receipts and exact passed/pending bounds.
