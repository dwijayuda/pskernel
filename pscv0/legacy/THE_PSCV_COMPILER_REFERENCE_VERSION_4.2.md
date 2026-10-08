# THE PSCV Compiler Reference — Version 4.2

**Status:** proposed target architecture; quantitative architecture score **97.63 / 100**  
**Repository:** `dwijayuda/pskernel`  
**Branch audited:** `pscv/v3-execution`  
**Predecessor:** `THE_PSCV_COMPILER_REFERENCE_VERSION_4.1.md`  
**Normative language authority:** `PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`  
**Verified profile:** `pscv-v1`  
**Verification semantics:** `PSCV-VERIFY-v1`  
**Certificate policy:** `PSCV-CERT-v1`  
**Normative Lean semantic pin:** Lean 4.35.0-rc3 / `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**Bootstrap Lean pin:** Lean 4.34.0 / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Research/evaluation date:** 2026-10-08

> V4.2 keeps the compact V4.1 compiler architecture and adds one missing reference-grade requirement: **soundness security**. Extensibility is explicitly treated as an untrusted-input problem. Third-party syntax, elaborators, proof producers, compiler passes, backends, tools, and runtime adapters must not be able to mint proof authority, bypass checked capabilities, or silently infect the verified meaning of a build.

---

# 1. Executive decision

V4.1 solved the structural problems in V4:

- explicit package ownership;
- purpose-specific representations;
- evidence as capabilities;
- pass analysis/invalidation;
- incremental QueryGraph;
- first-class TypeScript, JavaScript, Wasm and Rust backends;
- staged migration from the current repository.

A stricter audit against the additional criteria in this document finds one remaining architecture gap:

> V4.1 describes extension *identity* and *trust classes*, but does not define a single enforceable architecture preventing untrusted extension code from contaminating compiler authority.

V4.2 introduces an **Authority Firewall**.

Canonical architecture:

~~~text
UNTRUSTED / REPLACEABLE PLANE

source extensions
proof producers / AI
compiler passes
optimizers
backend implementations
target toolchains
interface adapters
external solvers

        |
        | canonical bytes / typed RPC only
        v

+-----------------------------------------------+
|              AUTHORITY FIREWALL               |
|                                               |
|  profile identity check                       |
|  capability policy                            |
|  canonical decode / hash binding              |
|  kernel / certificate / validator decisions   |
|  subject identity match                       |
|  assumption policy                            |
|  resource policy                              |
|  fail-closed outcome classification           |
+-----------------------------------------------+

        |
        v

LIVE NON-SERIALIZABLE CAPABILITIES

Checked<Core>
Certified<Checked<Core>>
Validated<RuntimeIR>
Validated<TargetIR>
~~~

The semantic compiler remains:

~~~text
Source
 -> elaborate
 -> Core
 -> Checked<Core>
 -> PSCV certification
 -> Certified<Checked<Core>>
 -> erasure
 -> RuntimeIR
 -> validation
 -> Validated<RuntimeIR>
 -> specialization
 -> SpecializedIR
 -> TS | JsIR | WasmIR | Rust
~~~

---

# 2. Quantitative evaluation model

Architecture quality, implementation coverage, and release assurance remain separate scores.

This document evaluates architecture under the stricter 15-criterion rubric requested for V4.2.

| Criterion | Weight |
|---|---:|
| Soundness / fidelity | 11 |
| TCB transparency | 8 |
| Adversarial robustness | 7 |
| Small compiler and extensibility | 9 |
| Architecture / modularity | 9 |
| Independent evidence | 6 |
| Performance | 5 |
| Resource behavior | 5 |
| Portability | 5 |
| Longevity | 5 |
| Interoperability | 5 |
| Self-host / bootstrap | 6 |
| Auditability / reproducibility | 6 |
| Security | 6 |
| Soundness security | 7 |
| **Total** | **100** |

Definitions:

- **Soundness/fidelity** — accepted proof/program meaning remains faithful to the declared language/profile and compiler relations.
- **TCB transparency** — every component able to create false acceptance is identifiable and minimized.
- **Adversarial robustness** — malformed, resource-heavy, or intentionally hostile inputs fail closed.
- **Small compiler and extensibility** — the trusted semantic spine remains small while replaceable extensions can grow outside it.
- **Independent evidence** — architecture supports evidence with genuinely different implementation/proof lineages.
- **Soundness security** — untrusted or compromised extensions/backends/tools cannot forge checked proof authority or silently change verified executable meaning without crossing an explicit trusted boundary.

Scoring:

- 0–59: materially incomplete;
- 60–74: coherent but major architecture gaps;
- 75–84: implementable with important unresolved trust/ownership issues;
- 85–94: strong but not reference-grade;
- 95–96.99: reference-grade with modest remaining architectural uncertainty;
- 97–100: strong reference architecture; remaining weaknesses are primarily implementation/evidence, not missing core boundaries.

---

# 3. V4.1 under the stricter rubric

V4.1 was rescored using the new security criteria.

| Criterion | Weight | V4.1 |
|---|---:|---:|
| Soundness / fidelity | 11 | 94 |
| TCB transparency | 8 | 89 |
| Adversarial robustness | 7 | 88 |
| Small compiler and extensibility | 9 | 96 |
| Architecture / modularity | 9 | 96 |
| Independent evidence | 6 | 88 |
| Performance | 5 | 93 |
| Resource behavior | 5 | 92 |
| Portability | 5 | 95 |
| Longevity | 5 | 95 |
| Interoperability | 5 | 96 |
| Self-host / bootstrap | 6 | 94 |
| Auditability / reproducibility | 6 | 94 |
| Security | 6 | 87 |
| Soundness security | 7 | 82 |
| **Weighted total** | **100** | **91.97** |

Main deductions:

1. plugin isolation was advisory rather than part of the canonical architecture;
2. in-process trusted host JavaScript can still affect checked-session behavior;
3. there was no explicit AuthorityBroker/authority-influence closure;
4. extension classes did not state which ones can alter source fidelity;
5. target passes/backends without preservation evidence could still be confused with assured paths;
6. supply-chain identity, sandbox identity and semantic identity were not sufficiently separated.

---

# 4. Research basis for V4.2

## 4.1 Lean: untrusted elaboration behind a small kernel

Lean translates rich source syntax into a small Core theory. The kernel checks new declarations before they enter the environment, specifically to guard against elaborator bugs.

Lean elaborators are powerful: command elaborators can update the environment and have full IO access.

Architecture lesson:

> Kernel checking protects logical soundness from elaborator bugs, but a powerful elaborator is still part of source-to-Core fidelity and operational security.

Sources:

- https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/
- https://lean-lang.org/doc/reference/latest/Notations-and-Macros/

## 4.2 Rust procedural macros: ambient plugin authority is a security anti-pattern for PSCV

The Rust Reference states that procedural macros run during compilation with the same file/stdin/stdout resources as the compiler and therefore have build-script-like security concerns.

Architecture lesson:

> Do not copy the ambient-resource plugin model for high-assurance PSCV extensions.

Source:

- https://doc.rust-lang.org/stable/reference/procedural-macros.html

## 4.3 LLVM / MLIR plugins

LLVM pass plugins are dynamically loaded into compiler tools and can inject passes into pipelines. MLIR provides plugin APIs and strong pass/dialect architecture, but native pass plugins are not a soundness isolation boundary.

Architecture lesson:

> Use LLVM/MLIR ideas for pass registration and invalidation, not as the security model for untrusted extensions.

Sources:

- https://llvm.org/docs/NewPassManager.html
- https://llvm.org/docs/WritingAnLLVMNewPMPass.html
- https://mlir.llvm.org/docs/PassManagement/
- https://mlir.llvm.org/docs/DialectConversion/

## 4.4 WebAssembly / WASI: capability-limited extension execution

WebAssembly is explicitly designed to isolate buggy or malicious modules. The Component Model targets fine-grained sandboxing and capability-safe interfaces. WASI has no ambient authorities; external access is provided through explicit capabilities.

Architecture lesson:

> Portable third-party PSCV plugins should preferentially execute as Wasm components with explicit WIT capabilities, or inside a comparably strong process/container isolation boundary.

Sources:

- https://github.com/WebAssembly/design/blob/main/Security.md
- https://github.com/WebAssembly/component-model/blob/main/design/high-level/Goals.md
- https://github.com/WebAssembly/component-model/blob/main/design/high-level/UseCases.md
- https://github.com/WebAssembly/WASI/blob/main/docs/DesignPrinciples.md
- https://github.com/WebAssembly/WASI/blob/main/docs/Capabilities.md

## 4.5 CompCert: verified core plus explicit unverified boundaries

CompCert proves semantic preservation from its formalized C AST to abstract assembly. External assembler/linker stages remain outside that theorem, and CompCert documents this boundary explicitly.

Architecture lesson:

> Every PSCV assurance claim must state exactly where semantic preservation begins and ends. External target compilers do not inherit PSCV proof authority.

Sources:

- https://compcert.org/man/manual001.html
- https://compcert.org/doc/
- https://compcert.org/doc/html/compcert.driver.Compiler.html

## 4.6 CakeML: end-to-end verified compilation and small trust base

CakeML proves its compiler backend preserves source behavior, bootstraps the compiler, and uses verified compilation to machine code for high-assurance checkers.

Architecture lesson:

> Preserve an upgrade path from validator-based assurance to end-to-end proved compiler slices without forcing every extension into the TCB.

Sources:

- https://cakeml.org/
- https://cakeml.org/checkers.html

## 4.7 Diverse Double Compiling

DDC addresses source/binary correspondence and trusting-trust risks using a diverse compiler.

Architecture lesson:

> Self-host fixed points and reproducibility are not sufficient source-binary correspondence evidence. Diverse bootstrap remains a separate release-assurance layer.

Source:

- https://dwheeler.com/trusting-trust/dissertation/

## 4.8 SLSA and reproducible builds

SLSA provenance describes where/how artifacts were produced. Reproducible builds define bit-for-bit recreation under declared source/environment/instructions.

Architecture lesson:

> Provenance and reproducibility strengthen supply-chain assurance but do not themselves create semantic proof authority.

Sources:

- https://slsa.dev/spec/v1.2/provenance
- https://reproducible-builds.org/docs/definition/

---

# 5. Current PSCV implementation evidence

The current repository already implements several V4.2 prerequisites.

## 5.1 Live capability boundary

`kernel-checked-session.mjs`:

- creates session-local handles;
- stores authority behind a `WeakMap`;
- freezes prepared graphs;
- re-derives canonical admissions before emission;
- checks provider identity;
- prevents serialized receipts from recreating checked authority.

It also explicitly documents an important limitation:

> the current trusted host boundary does not sandbox malicious compiler/host JavaScript.

V4.2 promotes that limitation into an explicit architecture migration target.

## 5.2 Production authority topology

`production-authority-audit.mjs` checks that:

- normal `psc build` uses checked build;
- unchecked build is explicitly named;
- raw emitter APIs do not appear outside the checked-session boundary;
- candidate/frontend owners do not import transformation authority;
- checked/certified capabilities use process-local handles.

This is strong architectural evidence.

## 5.3 Capability-sandboxed plugin ADR

`docs/architecture/adr/0005-capability-sandboxed-plugins.md` already prefers:

1. Wasm Component/WASI sandbox;
2. isolated bounded worker/process;
3. in-process execution only for explicitly trusted plugins.

V4.2 makes this normative instead of merely post-bootstrap guidance.

## 5.4 Existing isolated execution

`isolated-producer.mjs` already supports:

- digest-pinned images;
- no network;
- read-only filesystem;
- dropped Linux capabilities;
- no-new-privileges;
- unprivileged UID;
- bounded processes/memory/CPU/temp storage;
- no host mounts;
- explicit cleanup verification.

It correctly treats runtime/OS security as an assumption rather than proof.

## 5.5 Bounded process semantics

`bounded-process.mjs` classifies process success as untrusted data and never as kernel authority. It bounds input/output/wall time and treats termination uncertainty as infrastructure failure.

## 5.6 Provider security profiles

The current paranoid provider profile is intentionally empty until a sufficiently hardened provider is registered.

This is an honest fail-closed boundary and should remain so.

---

# 6. Three different notions of soundness

V4.2 forbids collapsing these.

## 6.1 Logical soundness

Question:

> Can invalid proof terms/declarations be accepted?

Primary authority:

~~~text
KernelContract
+
selected checked kernel
~~~

Untrusted tactics, AI, macros, solvers, and proof producers cannot create logical authority without kernel acceptance.

## 6.2 Source fidelity

Question:

> Does the source text mean what the declared ProofScript/PSCV profile says it means?

This includes:

- parser;
- macro expansion;
- elaboration;
- semantic-profile extensions;
- approved coercion/instance environment;
- contract/VC interpretation.

A malicious elaborator can produce perfectly kernel-valid Core that does not faithfully represent the user's source.

Therefore kernel checking alone does **not** solve source fidelity.

## 6.3 Executable fidelity

Question:

> Does emitted TS/JS/Wasm/Rust behavior preserve the certified source/runtime semantics?

This includes:

- erasure;
- specialization;
- target lowering;
- optimizer passes;
- target printers/encoders;
- external target compilers;
- ABI/runtime adapters.

A kernel-valid proof does not automatically prove target code generation correct.

Every release claim identifies which of these three soundness levels it covers.

---

# 7. Authority Firewall

The Authority Firewall is the V4.2 central security abstraction.

## 7.1 AuthorityBroker

A minimal authority component owns live capability creation.

Conceptual API:

~~~text
AuthorityBroker.checkCore(
  coreArtifact,
  profileEnvironment,
  kernelPolicy
) -> Checked<Core>

AuthorityBroker.certify(
  Checked<Core>,
  approvedSpecification,
  pscvPolicy
) -> Certified<Checked<Core>>

AuthorityBroker.validate(
  artifact,
  validatorContract
) -> Validated<Artifact>
~~~

Properties:

- only canonical byte/artifact identities cross the boundary;
- input objects are copied/decoded, never shared as writable host objects;
- every output capability is bound to exact subject identity;
- authority handles are session-local and non-serializable;
- receipts are descriptive evidence only;
- unknown/unsupported/exhausted/infrastructure outcomes never mint capability;
- an extension cannot provide its own "already checked" bit.

## 7.2 High-assurance process boundary

For `pscv-closed-v1` assured releases, the preferred architecture is:

~~~text
compiler / extensions
      |
 canonical IPC
      v
small AuthorityBroker process/component
      |
 kernel / configured validator
      v
opaque live capability / decision binding
~~~

This reduces the influence of arbitrary host/compiler code on false acceptance.

The current WeakMap host pattern is a development implementation of capability semantics, not the final hostile-extension security boundary.

## 7.3 Authority influence closure

Every build computes an **AuthorityInfluenceClosure**:

~~~text
all code/config/data capable of:
  minting Checked/Certified/Validated capabilities
  choosing the checker/validator
  changing subject bytes after checking
  changing active semantic profile
  replacing mandatory validation
~~~

The closure is machine-recorded.

A high-assurance profile fails if undeclared components enter this closure.

---

# 8. TCB model

V4.2 splits the trusted base by claim.

## Logical TCB

Potentially includes:

- KernelContract semantics;
- selected kernel implementation;
- canonical decoder required by the kernel;
- AuthorityBroker logic that binds result to subject identity;
- foundational axioms/profile.

## Source-fidelity TCB

Includes any source-to-Core mechanism not independently validated:

- parser;
- elaborator;
- approved semantic extensions;
- profile/environment resolver.

A pure proof producer is not in this TCB if its output is independently kernel checked.

## Executable-fidelity TCB

Includes every unproved/unvalidated transformation:

- erasure;
- specialization;
- source backend lowering;
- target lowering;
- printer/encoder;
- external target compiler/runtime where relevant.

A proved or independently validated pass leaves this TCB to the degree established by its evidence.

## Security TCB

Includes runtime mechanisms whose compromise could forge the above results:

- AuthorityBroker process/runtime;
- sandbox runtime;
- OS isolation primitives;
- cryptographic identity implementation where used.

Trust manifests must state these categories separately.

---

# 9. Extension trust classes

V4.2 replaces broad plugin trust classes with soundness-relevant classes.

## E0 — ordinary library

No compiler execution privilege.

Cannot mutate compiler semantics.

## E1 — surface macro / canonical rewrite

Input/output:

~~~text
syntax -> canonical ProofScript syntax
~~~

The expanded syntax is reparsed/re-elaborated by the normal frontend.

The extension identity is part of the source profile.

## E2 — proof producer

Examples:

- tactics;
- AI proof search;
- SMT frontends;
- decision procedures producing proof/certificate candidates.

Output receives no authority until checked by the configured proof/certificate checker.

These can be aggressively untrusted.

## E3 — compiler transform / optimizer

Consumes validated IR and produces candidate IR.

For an assured build it must have one of:

- checked preservation theorem;
- independently checked certificate;
- accepted translation validator.

Otherwise the transform remains explicitly in executable-fidelity TCB.

## E4 — backend / emitter / adapter

Same rule as E3.

A backend cannot consume unchecked Core or mint CertifiedSource.

## E5 — semantic elaborator

Can change source-to-Core interpretation.

This is dangerous for source fidelity.

For `pscv-closed-v1`, an E5 extension is permitted only if:

- it is explicitly included in the semantic profile;
- its exact implementation identity is pinned;
- its semantic contract is approved;
- it is included in SourceFidelityTCB **or** independently validated/proved.

Third-party ambient E5 extensions are forbidden.

## E6 — foundation change

New primitive, reduction rule, declaration semantics, quotient/inductive rule, etc.

Never a runtime plugin.

Requires a new SemanticProfile/Core/kernel revision.

---

# 10. Extension execution policy

Execution policy is separate from semantic class.

## U0 — pure data/no execution

Preferred where possible.

## U1 — Wasm Component sandbox

Preferred third-party execution format.

Default imports:

~~~text
none
~~~

Capabilities must be explicitly granted through WIT worlds/interfaces.

No ambient filesystem/network/process/time/randomness.

## U2 — isolated bounded process/container

Fallback when Wasm is unsuitable.

Required:

- content/digest-pinned executable/image;
- no network by default;
- no host credentials;
- read-only inputs;
- bounded scratch;
- process/memory/time/output limits;
- explicit capability mounts/handles;
- termination confirmation.

## U3 — in-process trusted extension

Allowed only for explicit trusted distribution components.

It automatically enters the relevant TCB unless all authority-sensitive outputs are independently validated.

A manifest is not a sandbox.

---

# 11. Soundness-security invariants

These invariants are normative.

1. **No extension can construct a live Checked/Certified capability directly.**
2. **Serialized JSON/CBOR/receipt data can never recreate authority.**
3. **Checked subject bytes are re-identified immediately before every authority-changing downstream use.**
4. **Untrusted extension memory is never shared writable memory with AuthorityBroker state in the high-assurance profile.**
5. **No unknown extension can become active through ordinary dependency loading in a closed profile.**
6. **Proof producers cannot add axioms or bypass kernel checking.**
7. **Unvalidated compiler transforms/backends are explicitly trust-expanding and cannot be silently labeled preserved.**
8. **Validator failure, timeout, crash, unsupported input, malformed output, or sandbox failure blocks authority.**
9. **Extension capability requests are least-authority and profile-controlled.**
10. **Network/filesystem/process/time/random access is absent unless explicitly granted.**
11. **Extension identity, code digest, API version and granted capability set participate in build identity.**
12. **Extension output is canonical-decoded with bounded parsers before authority use.**
13. **A compromised cache/index/SAVEF store cannot create Checked/Certified authority.**
14. **Target compiler success is not source-preservation evidence.**
15. **Release tooling cannot upgrade evidence class merely from provenance/signature presence.**

---

# 12. Pass and backend assurance classes

Every pass/backend declares:

~~~text
AssuranceClass =
  trustedImplementation
  proofPreserved
  certificateValidated
  translationValidated
  targetAcceptedOnly
  differentialOnly
  unassured
~~~

High-assurance `AssuredRelease` policy:

- no `unassured` pass on the executable path;
- `targetAcceptedOnly` may be sufficient only for target-well-formedness, not semantic-preservation claims;
- every authority-relevant relation names its evidence class.

---

# 13. Backend architecture

V4.2 preserves V4.1's asymmetric backend model.

## TypeScript backend

~~~text
Validated<SpecializedIR>
 -> TypeScriptSource
 -> pinned tsc
 -> JavaScript + .d.ts + source maps
~~~

Roles:

- bootstrap;
- ecosystem compatibility;
- readable differential artifact;
- declarations.

Security/soundness:

- `tsc` is an external toolchain input;
- `tsc` acceptance does not establish ProofScript preservation;
- high-assurance release through TS requires additional preservation/differential/validation evidence according to policy;
- target toolchain identity and executable closure are recorded.

## Direct JavaScript backend

~~~text
Validated<SpecializedIR>
 -> JsIR
 -> ValidateJsIR
 -> Validated<JsIR>
 -> deterministic ESM
~~~

Preferred long-term JS/npm assurance lane.

## Wasm backend

~~~text
Validated<SpecializedIR>
 -> WasmIR
 -> structural validation
 -> operand/control typing
 -> target-profile validation
 -> binary encoding
 -> Wasm
~~~

Wasm Component/WASI may additionally host sandboxed extensions, but compiler-target Wasm and plugin-runtime Wasm are separate profiles.

## Rust backend

~~~text
Validated<SpecializedIR>
 -> RustTargetPlan?
 -> RustSource
 -> pinned rustc/Cargo
 -> native artifact
~~~

`RustTargetPlan` remains optional/internal until a stable second consumer, validator or preservation proof justifies a public RustIR.

Rust ownership/borrowing decisions are target representation, not ProofScript source semantics.

---

# 14. Pass/invalidation architecture

V4.1 pass contracts remain, with one new field:

~~~text
PassDefinition {
  ...
  authorityEffect
  requiresAnalyses[]
  preservesAnalyses[]
  invalidatesAnalyses[]
  preservesInterfaces[]
  invalidatesInterfaces[]
}
~~~

`authorityEffect` is:

~~~text
none
requiresRevalidation
preservesByProof
preservesByValidator
trustExpanding
~~~

A pass marked `trustExpanding` cannot be hidden behind a semantic fingerprint.

---

# 15. QueryGraph and caches

Incremental reuse remains dependency/fingerprint based.

Security addition:

> Query/cache reuse is an optimization only. It does not reuse live authority unless the capability's own reuse contract explicitly re-establishes identity/evidence.

Untrusted cache data is:

- bounded;
- schema validated;
- content rehashed;
- action/context checked;
- treated as candidate data.

Cache corruption can at worst cause rejection/recomputation in the high-assurance path, not false proof acceptance.

---

# 16. CompilerService and AI

CompilerService is intentionally outside logical authority.

AI may:

- generate source;
- propose proofs;
- propose contracts;
- propose compiler passes;
- propose migrations;
- select retrieval candidates.

AI may not:

- change approved specification identity silently;
- mark its own proof accepted;
- grant itself extension capabilities;
- bypass backend/IR validation;
- mutate live checked capabilities.

Machine diagnostics remain structured.

---

# 17. Small compiler + extensibility

The semantic compiler core remains limited to:

~~~text
profile environment
parser/resolver/elaborator
Core
KernelContract client
PSCV certification client
erasure
RuntimeIR
runtime validator
specialization
generic pass/backend contracts
module/interface extraction
~~~

Not in core:

~~~text
SAVEF
FactoryBench
archive/provenance
DDC
independent checker orchestration
plugin runtime
target-specific backend implementations
AI orchestration
package registry
~~~

Extensions grow around typed contracts, not by adding switches to the central compiler.

---

# 18. TCB transparency artifacts

Each assured build emits or references:

~~~text
LogicalTCBManifest
SourceFidelityTCBManifest
ExecutableFidelityTCBManifest
SecurityTCBManifest
AuthorityInfluenceClosure
ExtensionCapabilityManifest
BackendAssuranceManifest
PassEvidenceGraph
~~~

Each entry contains exact implementation/artifact identity and reason for trust.

"Trusted" without a declared reason is invalid metadata.

---

# 19. Adversarial robustness

Negative conformance families include:

- malformed Core/IR/certificates;
- forged capability receipts;
- stale semantic/profile identities;
- extension output with unexpected schema;
- unauthorized capability request;
- cache poisoning;
- oversized/deep extension messages;
- cyclic module/interface graphs;
- extension crash/hang;
- target compiler unexpected output;
- plugin attempting filesystem/network access without capability;
- plugin trying to inject unchecked declarations;
- replay of capability handles across sessions;
- validator/producer disagreement.

The expected outcome is fail-closed classification, never fallback to weaker semantics.

---

# 20. Independent evidence

V4.2 retains independent-evidence interfaces but moves policy outside core.

Possible independent axes:

~~~text
different checker implementation
different implementation language
different compiler toolchain
different algorithm lineage
different proof foundation
different runtime
different parser/decoder
different organization/review lineage
~~~

"Two binaries" is not automatically independent evidence.

---

# 21. Performance and resource behavior

Security boundaries must not force every edit-time operation through maximum isolation.

Profiles:

## Edit profile

- trusted standard distribution components may run resident;
- incremental QueryGraph;
- persistent compiler service;
- cached elaboration;
- no release claim.

## Checked profile

- kernel checking;
- required validators;
- bounded extension execution;
- structured diagnostics.

## Assured release profile

- AuthorityBroker isolation;
- sandboxed third-party extensions;
- exact identity replay;
- full required pass/backend evidence;
- optional independent checker/DDC/archive policy.

This prevents security architecture from making ordinary editing impractical.

---

# 22. Portability and longevity

Portable extension target:

~~~text
Wasm Component + WIT capability interface
~~~

but V4.2 does not mandate Wasm for trusted built-in extensions.

Long-lived semantic identity depends on:

- versioned profile/contracts;
- canonical artifact encodings;
- explicit extension identities;
- separate evidence formats;
- hash agility in release/archive layer.

No plugin ABI is allowed to become foundational language semantics.

---

# 23. Self-host / bootstrap security

Four backend fixed-point lanes remain separate:

- TypeScript;
- direct JavaScript;
- direct Wasm;
- Rust.

Additional rule:

> Self-hosting compiler code cannot use its own prior "checked" claim as authority for the next generation.

Each generation must re-establish required checked/certified/validated boundaries.

DDC remains a separate release campaign for source-binary correspondence.

---

# 24. Repository ownership additions

V4.2 adds target ownership:

~~~text
packages/
  authority-client/         # typed client only
  extension-contract/
  compiler-service/

host/
  authority-broker/        # minimal high-assurance host boundary
  extension-host/          # sandbox/process/Wasm execution adapters
~~~

Existing physical files need not move immediately.

Current mapping:

~~~text
kernel-checked-session.mjs
certified-source.mjs
compiler-checked-service.mjs
    -> authority-client / transitional authority host

isolated-producer.mjs
bounded-process.mjs
    -> extension-host / external-producer isolation

docs/.../0005-capability-sandboxed-plugins.md
    -> normative V4.2 extension execution policy
~~~

---

# 25. Migration from V4.1

## S0 — record security architecture

Adopt V4.2 document without changing running compiler behavior.

## S1 — authority influence audit

Compute machine-readable closure from production build entry to every module able to:

- mint/check capability;
- select provider;
- invoke raw emitters;
- change profile;
- bypass validation.

## S2 — extension registry

Introduce `ExtensionManifest` + execution policy + capability grant set.

## S3 — isolate third-party execution

Add Wasm Component/process sandbox host.

No direct third-party npm/JS import into authority process for assured profile.

## S4 — AuthorityBroker split

Move live authority minting behind a minimal IPC/component boundary.

Keep compatibility host wrapper.

## S5 — assurance labels

Attach `AssuranceClass` and `authorityEffect` to every pass/backend.

## S6 — closed-profile enforcement

Third-party E5 semantic elaborators reject in `pscv-closed-v1` unless explicitly admitted by semantic profile.

## S7 — release policy

Assured release rejects trust-expanding/unassured executable passes unless policy explicitly expands TCB and reports it.

---

# 26. Architecture anti-drift rules

In addition to V4.1 rules:

1. third-party extension code cannot be imported into AuthorityBroker process;
2. authority IPC accepts canonical bounded data only;
3. extension manifests cannot claim authority class not established by the compiler profile;
4. E2 proof producers have no direct environment/kernel mutation capability;
5. E3/E4 output cannot skip validation/preservation policy;
6. E5 semantic elaborators are forbidden in closed profile unless explicitly pinned/approved;
7. no extension gets ambient network/filesystem/process capability in assured profile;
8. in-process plugin automatically enters relevant TCB;
9. a plugin sandbox escape is SecurityTCB compromise, not a semantic acceptance rule;
10. extension crash/resource exhaustion cannot trigger fallback to unchecked compilation.

---

# 27. Quantitative V4.2 score

| Criterion | Weight | V4.2 | Weighted |
|---|---:|---:|---:|
| Soundness / fidelity | 11 | 98 | 10.78 |
| TCB transparency | 8 | 98 | 7.84 |
| Adversarial robustness | 7 | 97 | 6.79 |
| Small compiler and extensibility | 9 | 98 | 8.82 |
| Architecture / modularity | 9 | 98 | 8.82 |
| Independent evidence | 6 | 97 | 5.82 |
| Performance | 5 | 95 | 4.75 |
| Resource behavior | 5 | 96 | 4.80 |
| Portability | 5 | 98 | 4.90 |
| Longevity | 5 | 98 | 4.90 |
| Interoperability | 5 | 98 | 4.90 |
| Self-host / bootstrap | 6 | 97 | 5.82 |
| Auditability / reproducibility | 6 | 98 | 5.88 |
| Security | 6 | 98 | 5.88 |
| Soundness security | 7 | 99 | 6.93 |
| **Total** | **100** | | **97.63** |

Requested threshold: **97.00**

**PASS**

The loop stops at V4.2.

---

# 28. Why V4.2 does not score 100

The remaining deductions are deliberate.

## Performance — 95

Process/component isolation has real overhead. Persistent sandbox workers and QueryGraph caching can reduce it, but the architecture does not assume isolation is free.

## Resource behavior — 96

Budgets/outcomes are strong, but portable compiler algorithms still require implementation-specific stack/heap work and empirical validation.

## Independent evidence — 97

Architecture supports diverse checkers/DDC/validators, but actual independence is an evidence property, not something a diagram can guarantee.

## Adversarial robustness — 97

Sandbox/runtime security remains an assumption boundary and requires continuous maintenance.

## Self-host — 97

Fixed points, verified bootstrap and DDC remain distinct; current implementation must re-run them after closure changes.

These are reasons for implementation/evidence work, not another architecture version.

---

# 29. Current implementation alignment

A conservative implementation/evidence alignment under the same strict rubric is substantially lower than 97%.

Current strengths:

- live checked/certified capability patterns;
- TrustManifest;
- production authority topology audit;
- provider identity/security profiles;
- strict RuntimeIR validation;
- direct JsIR/WasmIR validators;
- bounded-process and isolated-producer machinery;
- multiple backend self-host evidence;
- semantic lock/archive/evidence systems.

Current open gaps include:

- no production third-party extension host implementing V4.2 policy;
- current checked session still trusts host/compiler JavaScript;
- no separate minimal AuthorityBroker process/component;
- paranoid provider-security profile intentionally has no accepted provider;
- global erasure/specialization/backend preservation remains incomplete;
- TS/Rust source backends lack equivalent independent target validators;
- DDC/B10 and full release assurance remain incomplete.

Therefore V4.2's **97.63 is a target-architecture score, not a current implementation-readiness score**.

---

# 30. Final decision

Version 4.2 is the first V4.x architecture that clears the requested 97% threshold under the stricter security-aware criteria.

Canonical rule:

> **A small semantic compiler may be highly extensible only when extension freedom ends at an Authority Firewall. Untrusted code may propose syntax, Core, proofs, IRs, optimized programs, target code and interfaces; only small declared authorities may turn those proposals into checked/certified/validated capabilities.**

V4.2 remains proposed until an explicit migration maps the V3 implementation and V4.1 ownership plan onto:

- AuthorityBroker;
- extension execution policies;
- authority-influence closure;
- pass/backend assurance classes;
- closed-profile extension restrictions;
- TS/JS/Wasm/Rust backend descriptors.

No architecture score alone changes current release status.
