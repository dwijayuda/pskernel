# Acceptance and evidence contract

Status: gate definitions. For current results consult [STATUS.md](STATUS.md).
New gate IDs below are planned acceptance requirements, not existing npm commands.

## Gate matrix

| ID | Acceptance requirement | Required failure coverage |
| --- | --- | --- |
| P2-WORKSPACE | Clean manifest/Lake/module graph; all semantic packages inventoried; no broken declared roots | Missing manifest/source; unresolved module; duplicate logical name; accidental excluded semantic module |
| P2-LEAN | Exact closure builds under recorded Lean/toolchain; applicable tests execute | Unsupported implementation feature diagnosed; missing host dependency fails |
| P2-ADMISSION | Normal check/build obtains actual independent kernel admission; evidence binds environment and input | Ill-typed definition/proof, unresolved metavariable, malformed inductive, forged reply, version mismatch, rollback |
| P2-SOURCE | Real compiler entry and full import closure pass owned parse/elab/admission | First unsupported source form reported with file/span; no token-only substitute |
| P2-COMPOSE | Multi-module text/collections/JSON/effects/Meta/bridge fixture reaches JS through the real path | Module ambiguity, failed branch rollback, malformed JSON/protocol and unavailable capability |
| P2-DUAL | Generated `.ps` and `.lean` give equal canonical admitted Core/IR and stable reverse translation | Dropped imports/proofs/universes/annotations; alias misuse; non-idempotent printer |
| P2-GENERATE | G0 produces G1 from actual generated compiler source; G1 runs without hidden Lean compilation | Stale executable fallback, missing generated module, unsupported emitted runtime operation |
| P2-FIXED | G1 -> G2 -> G3 passes BOOTSTRAP comparison/evidence contract | Changed source closure, tampered proof/dependency, differing Core/IR/output |
| P2-KERNEL | Generated embedded kernel checks real compiler closure and agrees with independent reference on its promised profile | Adversarial admission, resource exhaustion, malformed conversion, cache/transaction corruption |
| P2-KFIXED | Kernel closure also regenerates and passes independent parity across generations | Generated checker accepting a known-invalid declaration; incomplete kernel omitted from manifest |
| P2-TARGETS | Same pre-backend IR, validated artifacts and matching specified behavior for supported TS/Rust/Wasm corpus | Unsupported target rejection; integer overflow/width; persistence/aliasing; closures; Unicode; Float edge policy |
| P2-RUST-HOST | JS/native compiler cross-regeneration, Core/IR parity and native source fixed point | Host-dependent resolver, numeric or runtime divergence |
| P2-WASM-HOST | Explicit Wasm host reproduces compiler generations under declared capabilities | Missing filesystem/process capability; limits; validator/runtime incompatibility |
| P2-LANGUAGE | Required rows of declared PSC2 profile pass source/checking/behavior gates | Unsupported neighboring syntax, ambiguity and invalid proofs fail closed |
| P2-CONTRACTS | Final theorem connects program/spec/effect semantics and closes required obligations | False contract/invariant, unmet caller precondition, wrong program hash, missing failure/cancel case |
| P2-RELEASE | Clean rebuild, reproducible evidence, declared profiles, assumptions and practical resource envelope | Missing/altered dependency, incompatible schema, stale evidence, unsupported profile upgrade |

`P2-KERNEL` includes source conversion and execution of the generated checker;
native Lean replay alone cannot close it. Its corpus scope must be declared.
Full Std/Lean replay and formal equivalence remain separately named assurance
claims, not silent prerequisites or implied consequences of compiler self-host.

## Milestone prerequisites

- Lean-hosted usable compiler: WORKSPACE, LEAN, ADMISSION and supported corpus.
- Compiler JS self-host: preceding gates plus SOURCE, COMPOSE, DUAL, GENERATE,
  FIXED, and TS target conformance for the complete compiler closure.
- Compiler + kernel JS self-host: compiler self-host plus KERNEL and KFIXED.
- PSC2 profile release: WORKSPACE, LEAN, ADMISSION, LANGUAGE and applicable
  CONTRACTS/TARGETS/RELEASE gates,
  with every required profile row covered. It may not advertise unfinished
  optional profiles as supported.
- Rust/Wasm host self-host: corresponding HOST gate in addition to relevant
  source/kernel prerequisites, with external checkers disclosed if still used.

## Evidence states

PASS means the actual required procedure ran successfully on the identified
revision and complete declared scope. FAIL means an executed requirement failed.
BLOCKED identifies a dependency/resource/tool impediment. NOT RUN means there is
no execution evidence. PLANNED means the harness/capability is not implemented.
INHERITED REPORT may describe donor-branch prose but never closes a local gate.

Record one result per command/gate; do not hide failure behind the last command
in a shell sequence. Store commit, branch, UTC time, exact command/cwd, toolchain,
input corpus/hash, profile, expected and actual result, exit status, elapsed
time/resource limit and artifact/log location. If a gate is conditional, record
why its condition applies or does not apply. A zero-step CI job is NOT RUN.

## Required negative and differential evidence

Both checker providers must receive the same canonical declarations and
foundation/environment policy. Compare acceptance/rejection and relevant
semantic outputs; distinguish timeout/unsupported from semantic rejection.
Test the actual normal compiler admission route, not only a replay helper.
Reject forged checked artifacts even when their codec accepts the shape.

Backend comparison must include explicit expected answers; agreement between
two wrong backends is insufficient. Test immutable arrays after update, alias
reuse, recursive ADTs, captured functions, exact large integers, string/Char
behavior, scalar conversion/overflow and effect order. Float NaN/signed-zero
comparison follows the declared bit/value policy rather than naive `==`.

Dual-source tests cover `def`, parameterless `const`, parameterized `function`,
dependent binders, imports, proofs, recursion and every claimed PSC2 extension.
Unsupported source or target forms must fail deterministically.

## Cost-aware execution

Run the smallest regression exposing the concrete failure, then affected
package/vertical gates. Before release run the declared full gate set on the
candidate revision. Use the repository's
[assurance ladder](../docs/research/KERNEL_ASSURANCE_FALLBACK_LADDER.md) for
expensive kernel diagnosis. Bounded probes do not close exhaustive gates.

After repeated equivalent OOM/timeouts without semantic progress, diagnose or
reduce the scope instead of rerunning unchanged. Preserve limits and report
the blocked larger gate. A resource problem does not authorize weakened checking.

## Formal assurance

Self-hosting and differential testing establish engineering evidence. Formal
preservation requires a stated theorem about a specified transformation.
The existing formal co-signer work is a possible later certification lane for
the exact accepted stream and its stated model assumptions. It does not prove
all PSC2 programs, JS execution, backend correctness, checker completeness or
Lean implementation equivalence. A certificate checker adds its own trust
obligations unless its reconstruction is verified in the kernel.
