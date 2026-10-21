# TypeScript tail-continuation performance defect

Status: corrected and full scoped application qualification passed at
81824afb29cff6e22a693f7988797dd62a524026, Linux run 39672943069.

At implementation 908cbc300ef0f3e96c1112e458da66b558c4782e, Linux run
39662002050 focused job 119437554172 independently type-checks the TypeScript
single-constructor compiler application and executes its finite diagnostics.
The 100000-statement / 500000-byte workload returns the correct result, but
takes 13.29 seconds and peaks at 3463956 KiB RSS. It refuses the unchanged
1048576-KiB acceptance bound. The corresponding JS workload takes 1.53 seconds
and 304400 KiB. Logs and failed measurement artifacts remain in that run.

The TS generator driver previously pushed every called implementation and
retained its caller, including complete-result tail calls. The correction
marks tail position through function/lambda results, let bodies, conditional
branches and match alternatives. Function expressions, operands, arguments,
conditions, local RHSs, fields and projection targets stay non-tail.
The driver replaces its current logical frame for a tail request; ordinary
requests retain their continuation. This includes indirect/mutual calls and
escaping closures, without special-casing application names.

No source/IR semantics, logical declarations, public signatures, resource
bounds or foreign-error policy is changed. Generated owners contain no native
JS finally blocks; source typed errors remain checked result values. Host traps
still escape. Existing self-loop and pure-declaration fast paths remain.

A strict-IR metatest independently type-checks and executes the emitted TS.
It covers 1000001 mutual tail calls with a 256-MiB process RSS bound, 5000
non-tail recursive continuations, local-value versus tail contexts, condition
continuations, escaping closures, old captures, callee/argument order and
tail/non-tail foreign traps. An unused divergent local RHS must still time out.
This backend test is not source admission evidence: the actual checked
compiler-like application still requires both grammars, all seven targets,
minimum Python and complete Linux qualification under its original bounds.

The historical G2 JS heap exhaustion and later post-fusion timeout remain
separate tracked evidence. Do not infer that this TS correction resolves them
or reopen G2/G3 before Practical Core feature freeze.

## Exact qualification

Both authored grammars pass the original application bounds on all seven
backends and minimum Python; every full job step and aggregate gate succeeds.
Native runtime/IR negative boundaries and all historical failed runs remain.
Exact identities and measurements:
PSC1_COMPILER_APPLICATION_QUALIFICATION_2026-10-22.json.
This result does not resolve or reopen the separate G2/G3 performance work.
