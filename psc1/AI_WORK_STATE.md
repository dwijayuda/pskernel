# PSC1 current work state — ParseCommon source normalization

Updated 2026-10-21. This continuation preserves draft
[PR #170](https://github.com/dwijayuda/pskernel/pull/170) at
bdd26a4bd501cf92d207e72a98f5f15874885d82 and all prior histories.
Repository development and qualification remain GitHub/Linux CI only.
No merge, release or publication. Use expected-SHA non-forced updates.

## Current work

ParseCommon is accepted in focused Linux run39505999415 at
48aa400b347f262631e99fdb06a1c8a86a055619. That checkpoint passed all24 census
behavior checks and retained native control groups. Census advanced to
semantic67/42/38, JS79/50/44, Rust83/51/43. It remains partial source coverage.

Continue with ParseBinding and Operators. Retain the binding-parser alias as a
named type definition, spell monadic failure sequencing explicitly, and expose
structural workers. Operator implementation uses named String equality and Bool
Nat comparison while retaining source operator acceptance/refusal policy.
The focused workflow now executes the existing independent operator equivalence
and data/pattern admission/execution suites. Lean installation gets bounded
retries for observed transient TLS failures; all tool pins and timeouts remain.
These additional modules are pending Linux qualification.


Normalize the whole Ps.Syntax.ParseCommon source module, starting from its
86:26 unsupported list-cons expression. Root names use explicit construction.
Recursive namespace text/equality/path helpers expose structural arguments;
scoped declaration parsing uses typed partial workers and explicit constructors.
Preserve declaration/reference root-escape separation, source spans, namespace
stack order, exact end-name matching, token ownership, signatures and fuel.

Native regressions exercise root references, declaration root refusal, remaining
tokens, namespace paths/equality, nested declarations in both grammars and
malformed/unclosed scopes. Maintained census gates now require ParseCommon
parse and elaboration as well as Ast and Erasure.Definition acceptance.
New source qualification is pending Linux CI; prior green CI is not transferred.

## Preserved qualified boundary

PR #170 source 81f271292086da3cd9f266115300086998360217 passed scoped
[39501336732](https://github.com/dwijayuda/pskernel/actions/runs/39501336732)
and focused [39501336380](https://github.com/dwijayuda/pskernel/actions/runs/39501336380).
Its final head bdd26a4bd501cf92d207e72a98f5f15874885d82 passed
[scoped 39502865307](https://github.com/dwijayuda/pskernel/actions/runs/39502865307)
(all37 steps; merge46624bf15fb36ddf3d57aeb45fa6922947bd1918) and
[focused 39502865431](https://github.com/dwijayuda/pskernel/actions/runs/39502865431).
[Immutable source receipt](docs/PSC1_CENSUS_NORMALIZATION_QUALIFICATION_2026-10-21.json).

Last census: semantic 67/41/37, JS 79/49/43, Rust 83/50/42
(modules/parse accepted/elaboration accepted), Lean grammar only.
Ast and Erasure.Definition are accepted as complete modules.
First parse refusal was Ps.Syntax.ParseCommon86:26 at `::`.
New counts and first refusals await CI.

## Continue

Follow the [Sol High prompt](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md), using
this state and current receipts over its historical blocker list.
Continue source normalization topologically, then independently tracked PS
frontend census and strict selected-phase closure checks. Preserve private
ownership, definitions and unsupported-declaration refusals.

Whole-closure independent admission/IR, generated compiler execution,
self-compilation and fixed points remain not-run. Generated JS/Rust checker
transport is not compiler self-hosting. Official Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc is the independent checker.
Ordinary exact source/body pairing, strict IR, ABI validation, verified refusal
and atomic publication remain mandatory. No backend-preservation theorem.

All fourteen complete Practical Core families remain incomplete. Efficient
optional indexing/finite iteration, Rust aggregate callbacks, typed IO and
remaining language/backend contracts remain work. Component ABI stays Bool-only.
No test/budget/tool-pin relaxation; historical Lean4.34/PSC2 receipts do not
qualify this compiler.
