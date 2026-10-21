# PSC1 active development checkpoint

Updated 2026-10-21. GitHub APIs and Linux Actions only.
Draft PR #172: https://github.com/dwijayuda/pskernel/pull/172
Branch: fix/psc1-closure-normalization-20261021
Base #171: 1fad9ed53cda9b23ac30be9cea85e7857437564e.
Preserve history with fresh HEAD reads, expected-HEAD updates and force=false.
No merge, registry publication or protection change is authorized.

## Active checked ordering implementation

Adding recursive Nat/Int order propositions, total constructive decisions and existing
exact comparison lowering. No new logical axiom or Bool-as-Prop encoding. Both
source grammars, true/false/equal/sign/large-integer cases and typed refusals are
required through Linux CI before this is called tested or qualified. Existing
qualified typed IO evidence below remains historical. Next: actual CLI/JSON apps.

Native Linux ordering run 39636740787 passed operator admission, corruption
refusal and existing regressions. G1, host boundary and semantic closure also
passed. The focused run stopped at the new independent native order oracle:
HAdd (Id Nat) Nat needed an explicit Nat observation before arithmetic. The
fixture now supplies that context; target/full gates must rerun. No test or
correctness requirement was removed. The next source
commit adds 136 independent native true/false inhabitation boundaries and the
actual CLI/JSON application: twenty-one child-process cases per grammar/target,
standalone adapters, independent native JSON reference and strict receipt checks.
Do not call the application qualified until its complete matrix/full CI succeeds.

## Latest scoped qualification

Implementation 74179eb664e132502a24ce60b52a3dbd52b1d0cc passes Linux run 39627387430:
https://github.com/dwijayuda/pskernel/actions/runs/39627387430
Tested merge 2a6dbec7b7f3d02c6dc6399360422da350e646e7. Static, native, focused, all three complete compiler
closures, G1, host boundary, full scoped integration and aggregate gate pass.
Historical benchmark is dependency-skipped. Exact jobs, artifacts and hashes:
docs/PSC1_TYPED_IO_EXECUTION_QUALIFICATION_2026-10-21.json.

Both grammars/all seven targets: 28 general IO sequencing obligations, with 4 more on
minimum Python; fourteen actual general IO consumers; two minimum-Python
consumers; two installed unpublished-package JS consumers. Four host providers
retain 20 actual Linux policy cases each, including malformed field classes.
Core/component String consumers, ten native ABI checks and the oversized-GC
request comparison pass. Existing inference, CompilerM, collections, JSON,
typed-error, runtime, divergence, package and negative suites remain required.

Readiness: 15 qualified / 22 blocked; releaseReady=false. The typed-io family's three finite
criteria are scoped-qualified through exact-commit actual execution evidence.
Complete CLI/JSON/library/compiler-like application acceptance remains blocked.
This documentation-only descendant preserves the tested implementation; its
static gate is not a new full compiler qualification.

## Typed IO implementation and boundaries

ProofScript.System.IO is independently authored in IO.lean and IO.ps.
Io A is the checked CompilerM alias with a String-to-String dispatcher, Unit
state and IoError. Existing checked bind, loop, mutation, return and handler
semantics provide general source sequencing. No foreign logical axiom exists.
Successful host effects remain visible after later typed errors. Foreign traps,
checker failures and integration defects escape source error handlers.

--abi io-dispatcher selects the explicit dispatcher boundary; other public
values retain their qualified scalar policy. Rust/Python/PHP have standalone
hosts; Rust uses owned safe Read/Write streams and forbids unsafe code.
Rust/PHP FFI profiles explicitly admit the qualified Linux x86_64 ABI. PHP FFI
must be enabled before guest loading and grants no source FFI primitive.
Rust consumer locks preserve both generated guest and committed host graphs.

--abi wasm-string adds public Bool/String marshaling for core/components.
Wasm IO binds the checked dispatcher argument to an explicit host import.
GC strings own validated UTF8 bytes/scalar counts. Typed memory operations,
pointer/size checks, canonical allocation, post-return and source/schema
rechecking remain mandatory. The linear arena is fixed 16 MiB; Wasm IO payload
configuration above 2 MiB refuses before loading, leaving room for JSON escaping
and responses. Oversized requests return portable typed tooLarge before host
dispatch. Unsupported shapes refuse; default ABIs remain unchanged.

Node/Python/Rust/PHP hosts preserve explicit capabilities, held root directories,
no-follow traversal, regular-file checks, bounded fatal UTF8 reads, atomic writes
and defined line/EOF behavior. Host adapters are for independently checked guests;
they confer no admission authority. Source/IR checks, all negative tests and
resource policies remain. IO providers and Wasm String details:
docs/PSC1_TYPED_IO_V1.md and docs/PSC1_WASM_STRING_ABI_V1.md.

Unpublished npm qualification ships all host resources, Node/Wasm entry points,
and the locked Rust crate. Installed canaries explicitly vendor source libraries
and compile them independently; no ambient workspace fallback is assumed.
No registry publication occurred.

## Authoritative remaining work

docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json freezes 14 families, 37 criteria, four
applications,both grammars and seven targets. Its dependency-ordered workQueue
and docs/PSC1_DEVELOPMENT_ROADMAP.md remain authoritative.
Readiness comes from actual exact-commit receipts, never source inspection.

Continue unbound inference/control acceptance and constructive admitted Nat/Int
order, then finish actual CLI/JSON/library/compiler-like applications and measured
100000-item workloads under existing limits. Preserve working features and all
independent references. Full scoped success is necessary, not release readiness.

## G1 and history

Qualified G1 service 80d68437af9db1b7db42be3889cb62fe99adad0b6355e0a25cb97aa3cccb280f, 84 modules,ten-case v2 corpus,one native seed and no
later native frontend/emitter delegation. Artifact 12356714805 is retained to
2027-01-19T15:37:43Z. Receipt records source/admission/original/specialized IR digests.
Earlier services 18518dab471043762d4d01f28c97f99bb8b34f54810c27b4cfb93380404a0534
and 9fee036b0ee9e2bdd9617bf2df0811409a4893ad8c7f59ab2ab478c0ea1be757,
artifacts 12347821634 and 12333713515,source,tests and CI evidence remain preserved.

The f7993e3d51917e2ec18f3c758a61468f06caaeb2 inference/protocol checkpoint
(run 39603714675),5a0f999a1b5d06f5b68461392fab05a8c86ca535 sequencing checkpoint
(run 39612250401),and1fbff4dca6a262de4b3d6d418afcb018ba1037fe five-target standalone
checkpoint(run 39615391064) remain exact historical qualifications.
All prior qualification files and failed diagnostic commits remain in history.

G2/G3/fixed-point work stays manual until stable feature freeze. Preserve the
original V8 heap-exhaustion and later post-fusion timeout evidence; do not repoint
old CPU replay to new G1 artifacts. PSKernel-Core Expression V2 research stays
independent. Official Lean 4.35.0 admission remains pinned at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.


## JSON correctness follow-up

Application review found the shared parser accepted a closing delimiter after a
comma. Empty-container and post-comma states are now distinguished for arrays
and objects, including intervening whitespace. Existing syntax, Unicode,
resource and rejection policies are retained. Both authored core fixtures and
actual CLI/file cases require refusal and preservation of the old output.
The latest source requires fresh Linux qualification; queued earlier runs are
not success evidence. No local checkout, build or test is used.

## Active library application continuation

Source d03c1d70fad1af0c0bcc2829071d99ed6da68026 run 39639135736 failed static
qualification because the JSON parity contract test still expected the previous
98 rows after the strict separator case expanded the matrix to 112. It now
derives the count from the explicit retained eight-case list and both/seven
matrix. No negative test is removed. Earlier queued queries were stale; use
fresh attempts/jobs endpoints and terminal logs before reporting CI state.

The next coherent source commit adds the PracticalLibrary Input/Transform modules
in both grammars, persistent alias/set/map/fold and optional large-index cases,
independent native Array reference, missing/duplicate source refusal and entry-only
exports across the seven consumers. Exact authored module/reference identities
and boundary checks are mandatory in parity receipts. Focused, full and minimum
Python runners are registered. This remains implemented, not tested/qualified,
until a successful exact-commit Linux run. Compiler-like diagnostics and measured
100000-item corpus remain next. G2/G3 remain deferred.

## Latest ordering diagnosis: run 39642134686

Head 9eb1f18cca58a87bd43745cda05feed1e9cb1b39 passed static and native gates,
including 136 independently kernel-checked true/false Nat/Int order boundaries.
Direct-JS and Rust complete compiler closures passed. Focused positives executed
for .ps on JS/TS/Rust before the chained-comparison refusal assertion expected
elaboration instead of the correct nonassociative parser refusal. The .lean
fixture needed a grouped do RHS plus its pure-let separator before the following
Nat observation. Both harness issues are corrected without relaxing source or
negative-test acceptance. Full target/application qualification remains pending.

Normal development now schedules native/focused gates before heavyweight
closures and G1, preventing observed two-runner starvation. Selected integration
jobs and aggregate requirements remain unchanged; a failed fast gate keeps the
full test debt. Compiler-like source/diagnostic/100000-input harness is prepared
in the active continuation, but is not yet a qualification claim.

## Focused ordering pass and application grammar correction

Implementation 89f37ccb5a7528a8ab539763102e09ab396bb540, tested merge
7184fa392b7b2924fc842dc124db984e671a0563, run 39644133851 focused job
119377105591 passes all 24 checked-order obligations (four cases, two authored
grammars, JS/TS/Rust), including precise parser/typing/verified refusals and
generation preservation. All seven/minimum/full qualification is still pending.

The new CLI application then failed source parsing: .ps match/data blocks needed
owned braces and constructor-spine patterns; Lean nested effectful branches
needed explicit grouped do actions. All newly authored CLI, library and JSON
separator .ps examples are corrected to the established grammar. CLI diagnostics
are pure formatters and each action branch is explicitly sequenced. No compiler
grammar is broadened, capability is granted or test expectation relaxed.
The compiler-like source/harness remains prepared, uncommitted and unqualified
until these prerequisites pass.

## Actual Lean CLI/JSON subset: run 39646253173

Source 46f40ca2d9ee7336001187d9add1e3635c9ecd93, tested merge
48e047140fc2a61eb106b100e00b4e4de0f8f493, passes native and all 24 focused
ordering obligations. Focused job 119384406337 executes all 21 actual CLI/JSON
child-process cases for Lean JS/TS/Rust: 63 cases pass, including strict trailing
commas, Unicode/quoted argv paths, permissions, file/output size, invalid UTF8,
denied capability before guest loading/invocation, exact exits/console and prior
output preservation. Lean source closure f15fe4b05d3df51856277164809276b8a3076aa7a201403391ed36088de37c23;
admission 71c5eda616d14a0fd9bfe9fd2bbd560ebf6812b9afa8003fc77f5f721ba10b36.
The .ps source stopped at unsupported pure else-if spelling in Args.ps.
It now uses the established nested else braces. No grammar or acceptance rule
is relaxed. The complete two/seven matrix, library application and full gate
remain required. Heavy closure/G1 jobs correctly skipped after fast-gate failure.
