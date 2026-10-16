# M3+B first runtime slice: suspension-aware generic lowering

16 October 2026. Candidate implementation; full native qualification remains required. M2+A stays accepted at 2a707206. This does not complete M3+B.

## Measured diagnosis

Cloud study38837301337/job116769178297 executed the exact accepted generated artifact under Node22.23.3. Its checksums passed. Logs report 285437 generated characters,1135 generator functions and608 occurrences of the scheduler helper. The emitted m1ArrayAt/m1ListAt contain nested dictionary construction, curried applications, OfNat evidence and Option.getD calls through the scheduler. These counts include the generated support closure, not only user functions.

Longer checked batches still show real cost: baseline8192 listTail median37.630004ms/call; fromList22.013064ms/call; toList28.576926ms/call. The listTail profile includes nested closures, garbage collection, __ps$run, _psc0Standard_listGetWorker and __ps$wrap. Thus warmup alone does not resolve the issue. These are diagnostic-run observations, not directly comparable speedup measurements against another machine. The initial artifact upload skipped the hidden .study directory; logs contain the results, but no study artifact was published. Repair publication for the paired comparison.

## Mechanism

`Ps.BackendEcma.Sync` conservatively checks the actual lowered expression/statement AST for suspension. It rejects generators/yield and fails closed at the existing4096 budget. The check is after intrinsic lowering, avoiding a separate incomplete callback roster (notably arrayBuild). No runtime types, arithmetic semantics, representation or persistent-array mutation changes.

`Lower` emits ordinary functions for suspension-free lambdas, scopes and declarations, including generic helpers. Scopes retain lexical bindings, argument evaluation order and once-only evaluation. General calls still use the existing stack-safe scheduler; non-tail/dynamic recursion is not reclassified as safe.

The existing tail recognizer now admits generic declarations only when self calls preserve every ordered type parameter. Type-changing recursive instantiations fall back. Its scoped alias handling is extended through the same existing alias mechanism after proving uniform instantiation. Tail argument assignment remains simultaneous, preserving source order. Existing count-loop logic and ABI are unchanged.

## Focused validation

Added recognizer checks to the existing native measurement harness: generic uniform self-tail, type-changing refusal, uniform alias, arrayBuild suspension, budget fallback and direct lambda. Added one officially checked .ps generic total-recursion fixture, m3Keep(alpha,n,x), and runtime checks with Nat/Bool at100000/50000 steps. Existing original performance operations/counts/checksums/samples and all1069 shared observations remain intact. This fixture is application source, not compiler-source migration.

Pinned source studied: Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc `src/Lean/Compiler/LCNF/ToLCNF.lean` (scope/substitution, argument binding and join points); `tests/elab/funind_unfolding.lean` (structural versus well-founded recursion, nested calls and motives). The upstream test's unrelated testSorry axiom is not imported or admitted. These sources guide invariants; no Lean compiler fallback or new trusted checking authority was introduced.

## Qualification and next work

Require complete native/JS/TS/Rust/GC/component checks on the exact candidate, then rerun the paired same-runner study using its successful native artifact and the accepted baseline. Do not claim improvement until that comparison exists. Next shared optimization is dictionary/closure specialization and direct-call analysis, not simply passing generated TypeScript through tsc. Broader M3 mutual/nested data, elimination, total recursion and deriving remain OPEN.
