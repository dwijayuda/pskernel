# New pskernel-core.old3 architecture

Status: target design plus the first executed data/structural foundation; the public
API still exports identity metadata only. See FOUNDATION.md for implemented scope.
This document is not an implementation, soundness proof, or compatibility report.

## 1. Identity and separation

The new owned checker is `pskernel-core.old3`, npm `@proofscript/pskernel-core.old3`.
The previous package is `pskernel-core.old`, npm `@proofscript/pskernel-core.old`.
The old Lean namespace remains `Ps.KernelCore` solely to preserve legacy source and
its tests. Reserve `Ps.Kernel` for the new implementation. No old implementation,
provider fallback, or compatibility evidence is inherited by the new package.

The initial semantic target is Lean 4.34.0, upstream commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, with an explicit `lean4.34-proof`
profile. The package's own semantic version is independent of this Lean version.
Exact vendor/upstream provenance must be checked before claiming pinned equivalence.

## 2. One kernel, two producers

```text
PSC2 source -> PSC2 frontend -> PSC admissions adapter ----+
                                                         |
Lean source -> pinned Lean frontend -> export adapter -----+
                                                         v
                                      validated canonical declarations
                                                         |
                                      owned proof-checking kernel
                                                         |
                                   CheckedModule / verification report
                                              /                       \
                                    PSC2 erasure                 proof verification
                                         |
                                    compiler IR -> backend
```

Adapters, the frontend, tactics, and exporters are not declaration-admission
authorities. The kernel checks their output rather than trusting their success.
The independent verification path needs only exported declarations and the checker;
it does not execute Lean. Processing arbitrary `.lean` source still requires a
compatible frontend. Export format and exporter commit are separately pinned;
latest exporter output is not assumed compatible with a pinned importer.

Acceptance establishes the exported statement under the recorded assumptions.
Claiming the intended source theorem also requires binding the expected statement
and relevant definitions to that input; an exporter-supplied name or digest alone
is not such a comparison.

## 3. Semantic module target (Data/structural foundation now present)

| Module | Responsibility |
| --- | --- |
| Data | Owned names, universes, immutable expression DAGs, declaration schemas. |
| Binding | De Bruijn operations, abstraction, capture-avoiding substitution, scope validation. |
| Universes | zero/succ/max/imax/parameters, instantiation, normalization and pinned comparison. |
| Context | Internally validated locals and private append-only global environments. |
| Conversion | Weak-head reduction, conversion, beta/delta/iota/zeta, eta and proof irrelevance. |
| Typing | Full checking of expressions and declared types; no infer-only admission shortcut. |
| Inductive | Positivity, universe/parameter/index checks, mutual/nested inductives and recursors. |
| Quotient | Controlled quotient initialization and corresponding reduction rules. |
| Primitive | Validated natural/string primitives and exact arithmetic behavior. |
| Admission | Transactional checking of definitions, theorems, opaque bodies and inductive blocks. |
| Policy | Exact axiom signatures, profile restrictions, native-evaluation exclusions. |
| Input | Canonical bytes decoding, bounded DAG validation, dependency order and identity binding. |
| API | Checked sessions, module checks, diagnostics and non-authoritative metadata. |

These are internal module boundaries, not a proposal for a dozen npm dependencies.
The first distributable should contain the checker and its necessary runtime closure.

Source dependency direction is outward from Data/Binding/Universes. Typing and
Conversion require carefully controlled mutual recursion; Inductive uses the
ordinary checker while producing and validating recursor rules. The diagram is not
a claim that all semantic modules can be implemented as an acyclic call graph.

## 4. Full logical profile, smaller toolchain

Retain dependent functions and universes, proof irrelevance, all required conversion
rules, safe declaration checking, recursive/mutual/indexed/nested inductives,
recursor validation/reduction, projections, quotients, and necessary literal behavior.
A subset is a development milestone, not the full capability release requirement.

Do not include source parsing, macro expansion, tactic execution, type-class search,
metavariable solving, LSP state, package resolution, compiler optimizations, code
generation, dynamic plugins or native proof evaluation in the logical checker.

`Lean.reduceBool` / `Lean.reduceNat` execution and native-result axioms are excluded
from the strict target profile. Do not silently substitute logical unfolding and
claim identical native behavior. Equivalent proofs need ordinary derivations or
independently checked certificates. A larger trust profile would be a separate,
explicit product decision.

Allowing axioms means reporting conditional proofs. An approved axiom must match its
universe parameters and type, not merely its name. Reject `sorryAx` and unapproved
axioms in the standard release policy. Track assumptions through dependencies.
Primitives are recognized only after their declarations are validated; spelling a
constant `Nat.add` must not grant it trusted arithmetic semantics.

## 5. Admission and environment invariants

Input is untrusted bytes, not caller-owned mutable objects. Reject unknown schema
versions/tags, invalid encodings, undeclared universe parameters, metavariables,
escaping variables, duplicate names, malformed DAGs and unknown dependencies.
Bound variables inside binders are valid; scope validation must not reject them
merely for being represented as bound variables.

Start from an empty environment and check the profile's complete required prelude,
or use a separately documented trusted base. Different PSC2 and Lean prelude
profiles must not be mixed by constant spelling. The default independent claim
requires checking the relevant transitive dependency closure.

Check declaration types and bodies before committing. Failed modules must not leak
partially added constants. Inductive mutual blocks use a dedicated validated
transaction; arbitrary recursive definition cycles are not admitted as ordinary
safe definitions. Never accept user-provided recursor computation rules solely
because their right-hand sides have some type.

Environments and checked handles have private constructors. Copy input into owned
storage; use immutable nodes and scope/cache identities. Hashes index data but do
not prove equality or soundness. Do not replace pinned pairwise conversion caching
with an assumed transitive closure of successful incomplete comparisons.

Resource limits cover input size, nesting, DAG nodes, allocation, reduction work,
big integers and cancellation. Exhaustion never becomes acceptance. A failed or
unsupported check is distinct from a mathematical claim that no proof exists.

## 6. Public API (proposal, not exported today)

```text
createSession(profile, limits) -> session
session.checkDeclarations(canonicalBytes) -> result
checkBundle(canonicalBytes, profile, limits) -> result
kernelInfo -> identity and explicitly achieved capabilities

result = accepted(checkedModule, report)
       | rejected(diagnostic)
       | unsupported(feature)
       | resourceLimit(reason)
       | internalError(diagnostic)
```

Only `accepted` may carry a checked handle. Bind it to the exact statements,
declarations, dependency closure, prelude, policy and checker identity. Erasure must
consume that same admitted Core, not re-elaborate a different source after approval.

Separate request/response protocol versions, semantic-profile versions, package
versions, and canonical format versions. A future npm API can expose the checking
entry point, metadata and bounded codec utilities. Do not publicly export
`addUnchecked`, mutable environments, caller-provided primitive evaluators, or a
constructor that blesses an arbitrary `CheckedModule`.

A serialized report or `accepted: true` object is not a portable proof certificate.
Recheck after a process boundary unless an explicit authenticated attestation policy
is used. That policy introduces its own trust assumptions. TypeScript types and
package `exports` organize an API, not a hostile-code security boundary. Run hostile
code generation/elaboration separately from the verifier with restricted OS access.

## 7. npm package and distribution

Target deployment: generated ESM JavaScript plus TypeScript declarations, installed
without Lean, Lake, a PSC compiler, build tools, install hooks or network downloads.
A small exact-integer/runtime layer may be bundled, but belongs in the audited
closure. No dependency on the old kernel, official Lean providers or compiler service.
Browser/worker support is a target to test, not an existing compatibility claim.
A Node-only CLI/process wrapper stays separate from the pure checking entry point.

Future release layout:

```text
pskernel-core/
  package.json
  src/Ps/Kernel/             # exact owned portable source
  dist/                     # prebuilt JavaScript and declarations
  runtime/                  # only audited support actually used
  profiles/                 # logical/prelude/axiom policies
  manifests/                # source, build, dependency and capability evidence
  scripts/                  # package-local reproducible build instructions
  test/                     # semantic and adversarial suites
  README.md
  ARCHITECTURE.md
  LICENSE / NOTICE          # resolved before public release
```

Prefer zero third-party production dependencies. Build tools can be development
dependencies without being silently loaded during proof checking. npm scope
ownership and publishing authorization must be verified separately. The design
scaffold is private; no npm release or registry-name reservation is claimed.

Use an explicit npm file allowlist and packed-consumer tests. Before public release,
include exact source and generated artifacts with manifests, resolve license and
attribution, and configure authenticated publishing/provenance. Provenance links an
artifact to its source/build; it is not a kernel soundness proof.

## 8. Self-hosting and TCB

During bootstrap, implement semantics in the stable PSC-compatible source subset
rather than requiring not-yet-working advanced PSC2 syntax. The final authority for
source switches to canonical `.ps` only after declared source-parity and execution
gates. Generated JS/TS must not be independently hand-maintained semantic sources.
The scaffold's handwritten JS is metadata only, not the future checker.

```text
seed toolchain -> compiler and kernel generation 0
PSC sources   -> compiler generation 0 -> generation 1
same sources  -> compiler generation 1 -> generation 2
```

Run semantic and adversarial tests on the generated checker, then compare generations.
No cycle is required in runtime dependencies: the compiler calls the kernel; the
installed kernel does not call the compiler. The compiler remains a build input.

Distinguish the logical rules, executable runtime/host assumptions, build-chain
trust, and intended-statement binding. A JavaScript package still depends on correct
JavaScript execution. Self-hosting and a stable fixed point do not prove soundness
or backend/erasure correctness. Existing Lean providers remain optional external
oracles, never hidden fallbacks in an independent success result.

## 9. Required evidence before authority

1. Pin and audit semantic sources, profile, protocol, prelude and allowed assumptions.
2. Validate data/binding/universe operations with positive and adversarial tests.
3. Complete checking, conversion, inductives/recursors, quotients and primitives.
4. Differentially replay pinned Lean declarations and reject malformed/ill-typed input.
5. Check the actual PSC2 compiler/kernel transitive closure; integrate an exact CheckedModule.
6. Execute PSC-generated checker code; establish generation comparisons separately.
7. Test clean packed npm consumers and measure artifact size, memory and checking cost.
8. Expand replay to the promised libraries and pursue formal admission-soundness proofs.

No legacy test, successful encoding, metadata flag, hash, source translation, or
package installation closes a semantic gate. A release capability manifest must
say what was actually run and at which commits.

## References

- Lean elaboration/kernel separation: https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- Lean export tooling (pin a compatible revision): https://github.com/leanprover/lean4export
- Pinned project provider: `psc15selfhost/packages/pskernel-lean/README.md` on the selected integration snapshot when present.
- npm package fields: https://docs.npmjs.com/files/package.json/
- Node package entry points and encapsulation limitations: https://nodejs.org/api/packages.html
- npm provenance limitations: https://docs.npmjs.com/generating-provenance-statements/
