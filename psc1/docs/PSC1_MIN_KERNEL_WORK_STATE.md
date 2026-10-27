# PSC1 minimal-kernel work state

Updated 2026-10-27 Asia/Jakarta. Research branch:
`research/psc1-minkernel-consistency-selfhost-20261027`.
The full engineering assignment is **incomplete**. The initial directly modeled
STLC fragment has a passing source consistency proof; current PSC1 portability
and generated execution qualification is being completed separately.

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
`checkEnvironment`/`infer` equations and constructs denotations for checked bodies.

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

The historical SH1 source profile also refuses namespace commands. The current
candidate therefore uses flat PsMin*/psMin* runtime identifiers, preserving the
same calculus and theorem names. Its changed source identity requires a fresh
proof/portable qualification; the earlier passing proofs are not relabeled.
