# PSC1 minimal-kernel work state

Updated 2026-10-27 Asia/Jakarta. Research branch:
`research/psc1-minkernel-consistency-selfhost-20261027`.
The full engineering assignment is **incomplete**. The initial directly modeled
STLC fragment has a passing source consistency proof and current PSC1 portability/
generated-vector qualification at `d6bebd230bcaadf35a254bfbc5a26a17228db55f`.
The existing full PSC1 regression and installed-toolchain runs have also passed.
[Exact qualification receipt](PSC1_MIN_KERNEL_QUALIFICATION_2026-10-27.json).

## Immutable base and preserved state

Base: `refactor/psc1-layout-20261026` /
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340`. Live PR #193's head was
`91c5d898adea8e8d184b7927adf2ed988af8c2d8`, eleven commits ahead, with
qualification pending at selection. The selected base retained the passing
source/installed/current-source-Wasm-G1/layout receipts in PR #192.
All writes are single-parent, fresh expected-HEAD and non-force. No merge,
registry publication or parent-branch modification is authorized or performed.

The runtime and proof have independent Lake projects with explicit roots.
Only executable/checker test source enters the PSC1 source compilation call.
The existing compiler source package allowlist and workspace module map register
`MinKernel` as a known package section; this grants no logical or host authority.
The official provider set, default, checker binaries, manifests, compiler engines,
IR validators, publication and frozen G3 payloads are unchanged.

## Proved boundary

Architecture: direct concrete Type model for Empty/Unit/Nat/simple arrows, not a
modified con-leche or an inherited consistency theorem. The executable source is
one module and imports no proofs or official checker. The proof consumes actual
`psMinCheckEnvironment`/`psMinInfer` equations and constructs denotations for checked bodies.

Theorems: `Ps.MinKernel.Proofs.minKernel_hasModel` and
`Ps.MinKernel.Proofs.minKernel_consistent`. All five printed dependency reports
are exactly `[propext]`; no sorry, sorryAx, new axiom or unsafe admission.
Proof run 40442690663/job121986507126 passed at
`23888f344c836b7a2c24ba2449cc420a19bc2974`, including 16 native semantic vectors
and min/dual canonical refusal. The later source-subset syntax update is rechecked
at `40706193698639923b08d70e458b856b55b7c756`,
run40443347456/proof-job121988640949. Run-level and portable outcomes are separate.

Native source consistency is relative to Lean 4.35 and the reported standard
propext dependency. No set-theory/inaccessible-cardinal assumption is added.
The proof is not a theorem about PSC1-generated machine code or arbitrary raw
JSON. That translation/preservation bridge remains unproved.

## Actual compiler closure

At `23888f344c836b7a2c24ba2449cc420a19bc2974`, the production ordinary-checked
probe independently admitted and strictly validated the complete current compiler:
124 modules, 4742 source Core members, 4747 logical members, 3465 canonical records,
308 inductive groups, 7168 projection occurrences, and 115 foundation declarations
with 60 axioms. The machine census retains exact source/tool/admission/IR/prelude
identities and actual expression/universe occurrence counts.

This fragment qualifies **0 complete compiler modules and 0/37 Practical Core
criteria**. Full compiler G1/G2/G3 with the minimal checker is not qualified.
The frozen122-module release closure073e5156 and its original four-engine fixed
points retain their historical evidence. They are not promoted by these tests.

## Integration and resources

The isolated research adapter exposes `min`, `lean-wasm`, `lean-native`, `dual`;
official Wasm remains default. Official modes delegate to the existing pinned
installed toolchain. Canonical min and dual return explicit
`PSC1_MIN_CANONICAL_BRIDGE_UNPROVED`, never fallback. No production path uses this
adapter or mistakes that refusal scaffold for completed min/dual integration.
Standalone typed-source checking is available independently.

Fuel bounds inference/type-equality recursion depth and declaration count, not
aggregate work, heap/stack or hostile AST ingress. Those limits and a proved raw
canonical bridge must precede untrusted minimal admission. Compiler-Wasm stays GC;
official C++/Emscripten kernel-Wasm stays linear memory.

## Linux CI and continuation

Workflow `.github/workflows/psc1-minkernel.yml` builds the source theorem, checks
axioms, runs native/refusal cases, compiles exact runtime/tests through the owned
PSC1 API, independently admits their exact graph, typechecks/executes emitted
vectors, runs finite native-reference fixtures, and audits the complete compiler
closure. Artifacts retain diagnostics even when a preceding qualification fails.
No local builds/tests or Desktop Commander were used.

Development failures are retained: first proof attempts had Lean API/transport/
termination-elaboration errors and correctly failed; a stale unused legacy
StrictSourceCompile driver was replaced with an isolated current-API caller;
the new source package needed registration; Lean constructor-result signatures,
nested patterns, open commands and numeral test patterns were adjusted to the
actual PSC1-supported source grammar. No acceptance rule was weakened.

Next mathematical obligations are the actual dependent Core calculus, a model of
each allowed primitive/foundation declaration, and proved executable inference/
conversion/inductive/recursor/projection rules. Alternatively, establish a complete
translation/refinement to an existing proved checker without inheriting its
theorem by analogy. Research comparisons and pins are in the research document.

After those proofs, add a bounded canonical decoder preserving exact identities,
qualify generated minimal-checker admission of the entire current source closure,
then run genuine min-checked G1/G2/G3 using the project's existing exact fixed-point
criteria. Existing official-checked generations cannot substitute for this gate.
Only then can production min/dual integration, graph benchmarks or self-hosting
be claimed. Full current-backend regressions remain required for changed compiler
source; unchanged frozen payload evidence retains its exact original boundary.

The historical SH1 source profile also refuses namespace commands. The final
candidate therefore uses flat PsMin*/psMin* runtime identifiers, preserving the
same calculus and theorem names. Its changed source identity was freshly qualified
by both jobs in run40444275459; earlier results are kept at their original commits.

## Qualified initial-fragment checkpoint

Implementation `d6bebd230bcaadf35a254bfbc5a26a17228db55f`; Linux run
[40444275459](https://github.com/dwijayuda/pskernel/actions/runs/40444275459),
proof/native job121991681809 and portability/census job121991681546: **success**.
All five theorem axiom reports are exactly [propext]. Native16/generated16
semantic/refusal vectors and5 finite official-native cases pass. The entire new
checker/test source graph is independently accepted by pinned official Lean.

Runtime source:1 module/93 lines/3322 UTF-8 bytes; SHA256
`2fb59b7477d42ee6c351e9c42db2afef94dc01f6db37764108141eeca016303c`.
There are0 explicit runtime imports and0 proof imports. Source API names are
PsMinTy/PsMinExpr/PsMinDeclaration and psMinTyEq/psMinLookup/psMinInfer/
psMinCheckDeclarations/psMinCheckEnvironment.

The emitted **test bundle** includes runtime and vectors:30836 bytes TypeScript,
35869 bytes JS, JS SHA256`9c0286037d1900cf5c54a35e6d6b69ac5dae6bee9cea99100ff99b4818cd2e42`.
It is not a separately packed pure-kernel payload. Compilation through the actual
PSC1 source API took1073.54ms; independent official source-graph admission46.81ms;
cold import+16vectors5.37ms; warm160000vectors4955.51ms. The test-process RSS was
138334208 bytes; this includes Node/harness, not isolated kernel memory. Finite
reference invocations took38.19-43.74ms including process startup, while generated
calls were in-process; these are deliberately different timing scopes, not a
claimed speedup. No minimal-checker Wasm payload or full-compiler graph benchmark
is qualified. WHNF/DefEq are absent from this simple-type calculus.

Portable/census artifact12707935407 has ZIP SHA256
b3fe8b8ad20e0b8e7d2c61412394c5d9e3e6a828cc01b74496169b587708537c.
Proof/native artifact12707632026 has ZIP SHA256
4bb77439bcbd196b080310bdba71422a8df231db449e8fca7c6d9bc2acfbc85a.
Artifacts require GitHub sign-in and expire under the recorded retention policy.
The receipt binds actual requests, source/admission/JS hashes and exact artifact IDs.

The census repeated successfully at this implementation with the same measured
compiler/foundation occurrence counts; report SHA256
`27dcd121b27e544550e8fd59a7d70d063f28b3265e1764a4c51d14124f50657c`. Full min closure coverage remains0/124 modules;
Practical Core0/37 criteria; min-checked G1/G2/G3 not qualified. Canonical min/dual
still refuse. This checkpoint closes only the first complete proved fragment and
its empirical source-portability milestone, not the full assignment.

## Existing regressions and continuation guideline

Main run40444282214 is terminal success: full121996032136, gate122004044236,
all selected dependencies pass; the benchmark was intentionally unselected.
Readiness is37/37 finite existing Practical Core criteria, zero blocked.
Tested merge1192135a60b7570ace969591f71f723521c32521 shares implementation tree
1e6eb1bf349cdde90b2ff35cc2b418b51a44a834. Both current124-module source
inventories retain the qualified base's exact Lean/PS closure identities.
The official-checked JS G1 is the existing88-module/10-case selected corpus;
it is not full self-compilation, a fixed point or a min-checked generation.

Installed run40444275465 is terminal success (jobs121991853908/121992045246).
It retains the frozen122-module source and executable identities. Its fresh
unpublished .9 root and artifact hashes are recorded separately in the receipt;
they do not replace older dated receipts or requalify historical G2/G3.

[Continuation guideline for GPT-6.1 Sol / High](PSC1_MIN_KERNEL_CONTINUATION_GUIDE.md)
is the next-session entry point. It links detailed proof, repository and upstream
decision-experiment appendices. Additional read-only inspection of existing CI
JSON establishes the checker's own12-record Core workload (3inductives/9defs)
and diagnoses34 direct foundation axioms/62 syntactically reached declarations.
That scan is not a foundation-pruning theorem or new checker execution.

The guideline's immediate batch is runtime-only dependency/frontier measurement,
then a bounded A-D architecture decision and one complete proof/implementation
extension. New findings include con-leche's arbitrary-axiom refusal, static
metaprogramming/pin-asset closure and monomorphic-List/String-literal mismatch.
No new upstream experiment or theorem is claimed passed by the guideline alone.
