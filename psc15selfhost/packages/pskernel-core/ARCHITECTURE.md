# New pskernel-core architecture

Status: design, not an implemented checker. Date: 2026-10-02.
Package: `@proofscript/pskernel-core`. Previous package: `@proofscript/pskernel-core.old`.

## 1. Goal and non-goals

An owned proof-checking kernel, shared by PSC2 and a separate Lean declaration
importer. The target is the logical kernel profile of Lean 4.34.0, pinned to upstream
commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, not merely a small PSC2-only type
checker. Compatibility is unverified until replay and adversarial gates pass.

Keep dependent types, universe polymorphism, proof irrelevance, conversion,
ordinary/mutual/indexed/nested inductives, recursor generation and validation,
quotients, opaque declarations with checked bodies, validated literals and arithmetic,
and controlled axiom declarations. Do not claim all-version or full frontend compatibility.

Exclude source parsing, macros, tactics, unification, elaboration, termination
search, code generation, editor tooling, package resolution and filesystem/network
access from the checking engine. A partial development profile is permitted only
when explicitly reported as partial. It is not the full-capability release.

## 2. Data flow and package boundary

```text
PSC2 parser/elaborator --- PSC adapter --------+
                                              |
Lean frontend/exporter -- Lean import adapter -+--> versioned declaration bundle
                                                        |
                                           bounded decode and validation
                                                        |
                                            independent pskernel-core
                                                        |
                                      accepted immutable CheckedModule
                                             /                      \
                                 proof validation              PSC2 erasure
                                                                   |
                                                            IR and backend
```

The adapters and frontend do not authorize declarations. The checker reconstructs
its own environment and validates all dependency declarations required by the
selected checking mode. No runtime dependency on Lean, the old kernel, KernelOne,
PSC elaboration, or an external provider may be hidden inside the new package.
A host can explicitly choose a different checker, but it must report that identity;
it cannot silently relabel another provider's acceptance as new-kernel evidence.

An exporter need not be trusted to produce well-typed terms. However, proving that
those terms express the intended source statement is a distinct claim. Bind results
to the expected statement, relevant definitions, source/export provenance, dependency
closure and configured axiom policy. An exporter that changes the theorem can
produce a valid proof of the wrong theorem.

## 3. Proposed internal source modules

These modules are planned, not yet present. The new source prefix is `Ps.Kernel`.
`Ps.KernelCore` remains the legacy prefix and must not resolve to the new package.

```text
src/Ps/Kernel/
  Data/Name       Data/Level      Data/Expr       Data/Declaration
  Binding/Subst   Binding/Abstract                Context
  Universe        Environment    Budget           Error
  Primitive       Reduce         Conversion       Check
  Inductive       Recursor       Quotient         Admission
  Bundle          Policy         Api
```

**Data and binding:** own immutable names, level expressions, expression DAGs and
declarations; correct bound-variable operations; local contexts created internally.
Reject loose variables, metas, undeclared universe parameters and malformed indices
at the relevant boundary. Metadata cannot carry authority. Do not equate hashes with
expression equality; collisions require structural confirmation.

**Universe:** implement the pinned `zero`, `succ`, `max`, `imax` and parameter algebra,
including normalization and bounds. Integer universe ranks or a flat set of max
leaves are not sufficient for the target.

**Environment:** private append-only checked declarations, reserved primitives and
quotient state, dependency and axiom provenance, and scoped caches. Admission must
be transactional: failure cannot expose partially installed declarations or cache
entries from an aborted environment. Rejected input does not mutate the accepted
module snapshot.

**Reduction, conversion and checking:** weak-head reduction, the required beta,
delta, iota, zeta, eta, projection, quotient and literal behavior; proof irrelevance;
full checking of terms and declared types. These algorithms are mutually dependent
and should be one audited engine, not separate interchangeable plugin packages.
`infer` with well-typed-input preconditions is not a public admission substitute.
Use bounded pair caches with explicit context/environment validity. Preserve the
pinned conversion behavior rather than assuming a generic union-find is equivalent.

**Inductive, recursor and quotient admission:** validate universes, parameter
uniformity, positivity, indices, elimination restrictions and generated rules.
Do not accept supplied constructor/recursor tables merely because they decode.
Either generate trusted metadata internally or validate a sufficient certificate.
Nested-inductive support is part of the final target, not unrelated compiler code.

**Primitives:** reserve and validate specially recognized declarations before their
reduction rules are enabled. Arbitrary constants named `Nat.add` do not gain built-in
meaning. Exact natural numbers, strings and all required representations must be
consistent with the logical prelude. Host arithmetic is not automatically Lean
arithmetic. A small runtime may be bundled and counted in the execution TCB.

**Bundle and admission:** the only public way to create accepted state is validated
admission. Check names, closedness, level scope, declared types, bodies, dependencies,
safety and policy. The module verdict is produced only after the entire requested
admission succeeds.

## 4. Proposed public API

The current package exports metadata only. The following is a future interface:

```ts
const kernel = createKernel({
  profile: 'lean4.34-proof-core',
  axiomPolicy: approvedPolicy,
  limits: configuredLimits
});
const result = kernel.checkModule(bundleBytes);
```

The actual input encoding and numeric limits must be specified before implementation.
No filesystem or user-supplied evaluation callback belongs in `createKernel`.

```text
CheckResult =
  accepted(CheckedModule, report)
  rejected(diagnostic)
  unsupported(feature)
  resourceLimit(kind)
  malformedInput(diagnostic)
  cancelled
  internalError(diagnostic)
```

Only `accepted` authorizes the exact checked snapshot. Unknown versions, unsupported
features, exceeded limits, cancellation and internal errors cannot authorize
emission. They must not be mislabeled as proofs of logical invalidity either.

Report kernel/package identity, semantic profile, prelude identity, checked statements,
dependency coverage, axiom dependencies and relevant resource outcomes. Hashes are
integrity identifiers, not proofs. Never accept a report or serialized Boolean in
place of running admission.

The future `CheckedModule` should be an instance-local handle backed by private
immutable state, not caller-controlled fields or just a TypeScript brand. A handle
from another instance must be rejected. Re-imported bytes must be rechecked; no
public constructor, `trust`, `skipCheck`, or unchecked environment insertion.

An export allowlist improves API discipline but is not a security sandbox. Arbitrary
hostile JavaScript in the same process cannot be made safe by TypeScript types,
package exports, or private naming. Use a separate process for hostile clients;
use bounded copied messages and no shared mutable expression buffers. Count the
host runtime, trusted adapter/decoder behavior and IPC statement binding in the
appropriate assurance boundary.

## 5. Semantic profile versus axiom policy

The semantic profile defines rules and recognized primitives. A separate policy
specifies permitted axioms and their exact declarations, not just their names.
A standard Lean-oriented policy can allow the intended extensionality, choice and
quotient assumptions. A more restrictive constructive policy may reject proofs
that use those assumptions without implying a conversion-engine incompatibility.
Track dependencies transitively and report the assumptions for each requested theorem.

Reject `sorryAx`, arbitrary axioms, unchecked declarations, trusted native evaluation,
and native-result axioms under the strict proof policy. Reject unsafe or partial
logical dependencies. This does not prohibit the surrounding compiler/runtime from
having a separate execution language; it prohibits importing that execution as proof.
Native-evaluation-based proofs need ordinary proof terms, checked certificates, or a
separately named larger trust profile. Exact acceptance parity for such inputs is not
part of the strict proof-only profile.

## 6. npm delivery

Use the repository's existing scope: `@proofscript/pskernel-core`. The short project
and folder name is `pskernel-core`; the old identity becomes
`@proofscript/pskernel-core.old`. No registry publication or ownership claim is made.

The first executable distribution target is prebuilt ESM JavaScript plus `.d.ts`
types, with no install-time build/download and ideally no runtime npm dependencies.
Bundle and audit any minimal generated runtime that is actually required. There is
no need to ship Lean, Lake, the full PSC compiler, study sources or test corpora to
ordinary consumers. This delivery target does not prove that the generated runtime
already exists or that the JavaScript engine is outside the execution TCB.

Use a small public export allowlist. Proposed future entries are the root checker
API and `/metadata`. Put CLI, filesystem/worker orchestration, Lean export support
and PSC-specific conversion in separate adapter packages. Native/WASM execution can
be added later without changing the semantic protocol. A WASM build of Lean is not
an independently implemented PSC kernel.

Package semver, input-format version, logical profile and upstream source pin are
separate identifiers. An acceptance-affecting semantic change needs explicit profile
review and regression evidence, not just a package patch-number change.

The current private design package has no root checker export. It can be packed and
installed locally for interface/metadata tests only. Publication stays blocked until
implementation, provenance, license, packaging and release gates are satisfied.

## 7. Self-hosting and TCB accounting

Implement semantics in the stable PSC-supported subset. During bootstrap, handwritten
PSC-compatible `.lean` and generated canonical `.ps` can follow the workspace's
existing source discipline. Promote `.ps` only after source, semantic execution and
fixed-point parity. Do not hand-maintain two semantic implementations pretending to
be the same source.

```text
seed compiler -> generated PSC kernel and compiler
                         |
                execute and recheck proofs
                         |
               build next generations
                         |
         compare artifacts and repeat semantic gates
```

A Lean seed and differential oracle can exist in development. The independently
running delivered checker must not call them. Compilation of the checker itself
remains in build-trust accounting. A compiler generating proof terms may be untrusted
because the checker validates the terms; a compiler building the checker executable
has a different trust role. A fixed point is not a soundness proof.

Kernel acceptance of compiler definitions also does not establish compiler
correctness, correct erasure, correct backend output or correct external behavior.
Those require their own specifications and evidence.

## 8. Acceptance and release gates

1. Freeze the Core/bundle format, complete profile, primitive/prelude policy and
   source lineage; inventory the actual compiler/kernel dependency closure.
2. Implement and test binding and universe operations, reduction/conversion and
   type checking, then complete transactional declaration/inductive/quotient admission.
3. Test invalid universes, proofs, axioms, primitive spoofing, positivity, recursor
   metadata, duplicate names, cache isolation, numeric boundaries and malformed input.
4. Differentially replay against the pinned Lean oracle, then the required library
   corpora. Separate semantic disagreements from resource limits and unsupported input.
5. Integrate real CheckedModule consumption before erasure; mutation after checking,
   forged handles and replayed reports cannot authorize emission.
6. Execute the PSC-generated checker on positive and adversarial corpora, rebuild
   compiler/kernel generations and establish the specified fixed-point evidence.
7. Test the packed npm artifact in a clean consumer with no Lean/PSC installations.
   Audit package contents, exports, dependency closure, install behavior and provenance.
8. Measure trusted semantic source, bundled runtime, compressed/unpacked package,
   memory and proof-checking throughput against equivalent profiles/corpora.

The goal is a smaller audited dependency closure, not a fabricated size number.
Formal verification should progressively establish that successful admission preserves
well-formedness under the declared rules and assumptions. Testing and reuse of another
project's theory do not themselves establish that theorem for this implementation.

## References inspected for this design

- `study/lean4-4.34.0/src/kernel/` and `src/Lean/Environment.lean` in this repository.
- `study/lean4lean-master/`, especially its divergence documentation.
- `psc15selfhost/ARCHITECTURE.md` and the existing kernel-provider interfaces.
- npm package manifest documentation: https://docs.npmjs.com/files/package.json/
- Node package exports: https://nodejs.org/api/packages.html
- npm pack: https://docs.npmjs.com/cli/v11/commands/npm-pack/
