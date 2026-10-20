# PSC1 architecture integration — qualification pending

Updated 2026-10-21. Branch: `research/psc1-ultra-architecture-20261021`.

This branch integrates typed-error source from PR #167 at `a830668d2c23886843e616951836d8d990aa2ff5` with qualified PR #166 at `da880d864ca5f9e35729255fd7e4f8a17953cd39`. Pattern, namespace, admission and runtime changes from #166 are retained. Source/IR/backend qualification for this integration is pending. Prior exact receipts keep their original scope. No merge to main, publication or self-host claim.

The architecture audit, Wasm decision, self-host source census and Sol High handoff are in progress. Compiler-only self-hosting is authorized in this phase; the prior checkpoint exclusion below describes historical scope.

---

# PSC1 current work state — tuple bindings and namespace scopes

Updated 2026-10-20. Branch: `feature/psc1-practical-control-data-20261020`.
Draft [PR #166](https://github.com/dwijayuda/pskernel/pull/166) remains stacked on
PR #165 at `5539059a47c13a3dbc9806a504775b72f7bfd0fe`. Earlier branches and PRs
are preserved; no merge or publication was performed.

## Qualified implementation checkpoint

Implementation head `7e1158875cdf236a677448598bd5f677c11d4daf` passed all **34/34** steps in
[focused Linux run 39467579973](https://github.com/dwijayuda/pskernel/actions/runs/39467579973).
The workflow tested GitHub merge commit `45169fa903b6bd68c3d9cc46348f8c4487d382c3`
against the preserved PR #165 base.

The [immutable qualification receipt](docs/PSC1_PRACTICAL_CORE_PATTERNS_NAMESPACES_QUALIFICATION_2026-10-20.json)
records exact source/tool identities, observed checks and package hashes.
[Retained evidence archive](https://github.com/dwijayuda/pskernel/actions/runs/39467579973/artifacts/12285373763):
38,945,246 bytes,
SHA-256 `86415bd383aac67e11084b580d3ce0d33834def6cf1e01681d66db5cfbcc5e58`.
GitHub's artifact retention applies; the committed receipt does not extend it.

This is scoped execution evidence for the implementation head above. Later
heads, including documentation-only changes, require their own successful
focused Linux check. All fourteen feature families remain incomplete:
13 have qualified selected cases; typed IO remains missing.

## Current increment

Immutable named, wildcard, Unit and nested/right-associated product patterns
work in ordinary `let` and selected `do let`. One strict Core let retains each
RHS evaluation, including all-wildcard patterns, while checked projections
introduce immutable body-local names. The RHS uses the original scope and
earlier closures retain captured values. Duplicate leaves, mutable-name
conflicts, mutable patterns and monadic patterns are refused.

Namespace/end commands preserve per-declaration semantic metadata. The
elaborator qualifies declaration identity and resolves exact locals, then
current/enclosing/root globals, including relative qualified names. Nested,
reopened and dotted scopes, dotted declarations, qualified projections,
constructors, contextual pure and structural recursion share that policy.
Matched ends and duplicate identities are checked. Namespace identity does
not grant entry-module export ownership.

Reference-only `_root_.Name` preserves generated builtin notation through
translation. Tuple/array constructors, product types, List/Nat syntax and legacy
controller helpers retain exact root identity. Authored relative names continue
to use namespace lookup. Namespace/declaration/import root escapes, open/section/
export aliases and unnamed ends remain outside the selected surface.

The native suite has 323 categorical outcomes: Do 101, Data 135, While 27 and
Namespaces 60. The authentic native-Lean oracle has 84 fields: 82 observed
results plus two toolchain identity fields. Both grammars execute on all seven
targets, with 18 individual regular predicates plus `semantic`; component
Wasm retains the combined Bool export.

Selected ordinary while retains 14 finite bundles, 14 external divergence
deadlines and 16 refusals. A separate all-wildcard pattern RHS fixture adds
14 external deadlines. Minimum Python repeats both grammars, including two
additional pattern strictness deadlines. Namespace host checks retain
12 refusals, ten prior-output preservation cases, private imported helpers,
scoped entry exports and source origins. All installed npm/source-library
checks and preserved native/backend regressions passed.

## Preserved assurance and boundaries

Official Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, remains the independent admission
authority. The owned kernel is separately natively tested. Ordinary partial
execution still pairs a constructive opaque witness with a separately checked
exact body and revalidates the immutable graph before erasure. Explicit
verified execution refuses; no new axiom, unchecked opcode, generated runtime
fuel or behavioral certificate is introduced.

Finite continuation construction and optional array lookup retain their linear
costs. Selected ordinary while excludes the previously documented unsupported
loop/effect/capture shapes. Public component and scripting aggregate ABI limits
remain. CompilerM evidence is native admission/IR plus private-JS comparisons,
not an all-seven native-oracle claim.

## Resume from here

Read [current scope and evidence](docs/PSC1_PRACTICAL_CORE_PATTERNS_NAMESPACES.md),
[the status matrix](docs/PSC1_PRACTICAL_CORE_STATUS.json), and the immutable
receipt before broadening any claim. Verify the actual branch head and use an
expected-SHA, non-forced update for every write.

The remaining source work includes throw/try/catch with control/state semantics,
Prop-valued ordering with checked decisions, and bounded typed IO. Typed IO
requires console line input/output plus UTF-8 file read/write with explicit
path roots, EOF/newline, size/error semantics and target adapters. Stdout alone
is insufficient. Broader pattern/namespace/effect forms require separate
selected cases and end-to-end qualification.

Continue repository work through GitHub and Linux CI. Full self-host,
joint-census, fixed-point, merge, release and npm registry publication remain
excluded.

## Historical checkpoints

The preceding control/data state, including its seven-backend history, is
preserved [verbatim](docs/history/AI_WORK_STATE_BEFORE_PATTERNS_NAMESPACES_2026-10-20.md).
Its implementation checkpoint remains
`8d6f80ea5813edd0644440971095abffd9dddacd`,
[run 39407097682](https://github.com/dwijayuda/pskernel/actions/runs/39407097682),
with its original [immutable receipt](docs/PSC1_PRACTICAL_CORE_CONTROL_DATA_QUALIFICATION_2026-10-20.json).
The previous exact documentation head
`1e63628169459539783450e28c641f3f70bf701f` also passed
[run 39408221046](https://github.com/dwijayuda/pskernel/actions/runs/39408221046).
These checkpoints retain their original scope.
