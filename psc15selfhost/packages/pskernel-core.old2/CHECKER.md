# Experimental dependent checking checkpoint — 2026-10-02

Version: `@proofscript/pskernel-core@0.1.0-checker.0` (private).

## What changed

Five new owned semantic modules add `Environment`, `Reduction`, `Conversion`,
`TypeCheck` and `Admission` to the previous eight-module foundation. All thirteen
modules compile with the pinned PSC seed from flattened Lean-subset source and
canonical PS. Both source forms emit the same TypeScript. Strict TypeScript
compilation generates executable ESM and declaration files; semantic generated
code is never patched or replaced by handwritten JavaScript.

This is an actual, limited proof-term checker: for example it checks
`fun (P : Prop) (p : P) => p : forall (P : Prop), P -> P` and rejects attempting
to use a proposition itself as a proof. It is not the complete target kernel.
The package's public `canCheckProofs` and `authoritative` flags remain false
because no supported public proof-certification API or complete profile exists.

## Internal rule coverage

`psKernelCheckStart` checks that the submitted expected type itself has a sort,
infers the submitted value's type, then compares that inferred type with the
expected type. There is no shortcut that accepts a caller's claimed type.

The supported universe syntax in type judgments is closed zero, successor,
max and imax. The type of `Sort u` is `Sort (succ u)`; the universe of a Pi type
uses `imax`, including impredicative Prop. All universe parameters in these term
judgments are currently rejected, not treated as free trusted parameters.

Local variables use de Bruijn indices. A context entry stores its type in that
binder's outer context; lookup lifts it by index plus one into the current
context. Lambda domains and Pi domains/codomains must themselves be types.
Applications require a Pi-shaped function type after weak-head reduction,
check the argument type and instantiate the dependent result type. A let checks
both annotation and value even when the body does not use it. The value is then
substituted into the body without variable capture, permitting local type aliases.

Reduction is beta, zeta and transparent delta. Normal-form conversion ignores
binder display names and visibility annotations, compares expression structure,
and invokes bounded universe comparison for sorts. This is deliberately
conservative: **function eta and proof irrelevance are not implemented**. A
`different` result is not a proof of full Lean definitional inequivalence.

`psKernelAdmissionStart` starts with an empty environment and processes a batch
of closed monomorphic transparent definitions in source order. Earlier admitted
definitions may be referenced; duplicates, anonymous declaration names, forward
references, self references and circular batches are rejected. There is no axiom
constructor. If any declaration fails, the result contains no environment.

The internal `infer`, `check`, reduction and conversion starts that accept an
explicit environment require a correctly admitted environment. Merely constructing
a raw environment object does not validate it. Only fresh batch admission is
intended to establish the fragment's sequential environment invariant. These
internal values are not public or immutable `CheckedModule` capabilities.

## Machine execution and budgets

The semantic machines are first-order task/value stacks. A nested reduction,
conversion, lookup, binding or type-checking submachine is stepped through the
same outer budget: subcalls do not reset a full budget. Exhaustion is distinct
from acceptance, rejection and conversion inequality. Tests compare generated
curried fuel runners with iterative host drivers that only invoke generated
semantic transitions. No semantic rule is implemented in that host loop.

This is **not yet a complete hostile-input resource boundary**. Some supporting
operations, including binary successor/predecessor and level-offset stripping,
have internal recursion that is not separately transition-metered. Input bytes,
allocation, wall time and every host stack frame are not all covered. Raw ADTs
are mutable internal objects with no hostile JSON decoder, cycle guard, byte-range
or UTF-8 validation. No exception, invalid machine state or out-of-fuel result may
be upgraded into proof acceptance by a future host adapter.

## Evidence and its limits

The exact current commands, counts, source and tool hashes are recorded in
`manifests/EVIDENCE.json` and the accompanying evidence bundle.

* Unit tests execute the generated implementation and include 54 named typing
  fixtures plus environment, reduction, capture-avoidance, ordering, deep-type,
  budget, invalid-state, package-boundary and source-reproducibility tests.
* `CHECKER_DIFFERENTIAL.json` summarizes 559 actual closed monomorphic term judgments
  against the pinned native Lean provider: 156 accepted and 403 rejected.
  Complete probe records are retained in the tarball/evidence bundle under
  `dist/evidence/`, identified by paths and hashes in the summary manifests.
  All 559 agree. Native rejections must occur at the submitted declaration,
  not an earlier environment entry or transport decoder.
* Two **additional known completeness gaps**, function eta and proof irrelevance,
  are explicitly exercised. Lean accepts them; this fragment rejects them.
  They are recorded separately and are not counted as successful agreement.
  Seven unencodable/unsupported named cases are explicitly excluded from direct
  comparison, but are covered by the local/source-computation rejection tests.
* `CHECKER_ORACLE.json` contains 68 ground computation theorems about the owned
  checking, conversion, reduction and admission machines, checked by the external
  kernel over PSC-serialized source definitions. Three false claims of acceptance
  are rejected at the intended theorem. This independently exercises the source
  computations in addition to executing generated JavaScript.
* The prior 47 structural and 88 binding/universe/arithmetic ground computations
  and 671 direct universe-equality probes are rerun on this source checkpoint.

Bounded test agreement is not a general soundness proof, complete coverage,
backend-correctness proof or complete Lean compatibility result. The source
computation theorems are checked by the **external** pinned provider, not by the
new kernel. The new checker does not yet admit its own inductive source closure.
The external source path uses PSC serialization, not an independently executed
native Lean frontend parse. The external provider's recorded prelude and trust
assumptions remain relevant to all reference evidence.

## Reproduction defects repaired from foundation.1

The recovered foundation.1 tarball did not reproduce every earlier summary
claim. Its baseline test run passed 180 of 181 tests: a metadata-status assertion
was stale. Two reference scripts imported helper exports absent from source.mjs,
and named a provider digest field not present in TOOLCHAIN.json. The semantic
oracle also used an incorrect field name in its indexed-equality declaration.
Those harness and test defects are fixed here. New pin/helper regression tests
reject missing or altered executables rather than downloading replacements.

Once the harness ran, it exposed genuine source/runtime agreement problems.
Some owned arithmetic/universe helpers used `Bool` and `if`; their PSC Core
lowering depended on an opaque prelude `ite`, which the reference kernel could
not reduce. The helpers now use an owned `PsKernelFlag` inductive with explicit
constructor matches.

The seed also mis-lowered a recursive wildcard branch in `psKernelLevelOffset`:
it captured the original outer scrutinee rather than reconstructing the current
recursive child. Explicit zero/parameter/max/imax cases now reconstruct that
child. The generated output was not edited. Regression cases cover each base
constructor under successors, and the reference computation suite now passes.
These fixes do not establish that the seed has no other lowering defects.

## What is still missing before trusted compiler integration

Term universe polymorphism/instantiation, full conversion (including eta and
proof irrelevance), inductive/recursor positivity and admission, quotient support,
validated literals/primitives/projections/prelude, opaque/theorem/axiom policies,
a hostile-input decoder, protected checked-module ownership and compiler emission
enforcement are unfinished. Unsupported forms are rejected, not inserted as axioms.

The complete compiler/kernel dependency closure has not been admitted by this
checker. The generated compiler/kernel fixed point and promised Lean library
replay have not been executed. Native Lean/Lake workspace and legacy suites, and
CI on the actual latest combined repository tree, remain outstanding. Compiler
source/parser failures on the integration branch are a separate workstream.

## Repository delivery boundary

The cumulative continuation patch targets PR #53's existing package at commit
`12b6c0f9d63b606eae893e759093b9ab9e008b68`, including the foundation.1 changes.
It touches only `psc15selfhost/packages/pskernel-core/`; it does not alter the
legacy `.old` package, its routing, compiler source, default provider, or main.
The PR package baseline is verified by Git tree hashes before patch creation.

The integration branch was observed separately at
`f51a2c01c0bf09f1a509e170b38af9ac31cf3be3`. A clean package patch against PR #53
is not a tested merge of that whole integration tree. Repository publication and merge status are reported separately by PR #53 and
the delivery record; neither is inferred from a local test run or a PR comment.
This checkpoint must not replace the compiler provider merely because it is
committed to the draft development branch.

## Toolchain and release

The seed/provider executables are explicitly digest-pinned historical tools from
source c680b2016ff8e23bdae2bc102128b1308fb5a324. Their historical Actions artifact
expires on 2026-10-08 and its complete workflow failed elsewhere. No binary is
automatically downloaded or included as a hidden runtime dependency. A durable,
reviewed seed rebuild/distribution remains a separate requirement.

The package remains private, metadata-only at the public export, and excluded
from the compiler bootstrap closure. `npm run release:check` and
`prepublishOnly` reject it. Licensing/provenance and public publication remain
unresolved. These process gates are not mathematical or hostile-code safeguards.
