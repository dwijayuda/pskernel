# PSCV V6 Core npm architecture — minimal authority, extensible capabilities

**Status:** implementation plan plus small runnable P0 package scaffold. **Not** the full PSCV compiler, a successful verified build, an npm release or a claim of formal soundness.

**Location:** main target workspace pscv0/v6; implementation branch pscv/v6-minimal-npm-core.
**Date:** 2026-10-08. **Authority:** normative PSCV language specification and V6 architecture, not this implementation sketch.
**Lean implementation/semantic mismatch:** existing kernel packages pin 4.34.0/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b; the PSCV language reference pins 4.35.0-rc3/470d5ce1400764999581fd26d5d72b00d990b0f4. This is an explicit blocker to a verified PSCV release until compatibility is proven or providers repinned.

## 1. Decision

Build a **new**, minimal, Lean-based native PSCV compiler, released as npm packages and independent executable archives. Do not carry forward old self-host/PSC2 frontend architecture, package APIs, source profiles or compatibility shims only to preserve them. The old source tree is neither a runtime dependency nor a mandatory migration target. Its history/evidence can inform regression tests but must not dictate the implementation.

Reuse existing official Lean-backed checker **npm APIs**, not in-repository relative imports. The core cannot derive source fidelity from a kernel decision alone. Keep the *trusted verification/certification authority* extremely narrow while allowing the *language and tooling ecosystem* to grow via selected npm extension packages.

The first implementation unit is the **checked Core admission boundary**, not a fake all-features parser. A premature build() that returns a file without a proof/effect/runtime/backend gate is architecturally worse than an explicit unsupported error.

## 2. Trust ownership: five orthogonal questions

1. **Parsing:** did the selected, versioned, possibly extended syntax correctly map the exact source text to syntax nodes?
2. **Elaboration/source fidelity:** did the owned elaborator translate the source into the *intended* Core meaning and did it use only admitted environment declarations/coercions/instances?
3. **Logical checking:** did the pinned kernel check those exact declarations, proof terms and their permitted axiom dependencies? Kernel acceptance never proves answers to (1) or (2).
4. **PSCV certified source:** do approved contracts/specifications, mandatory proof obligations, effect/assumption/erasure policies, imported proof identities and semantic bridge conditions all close?
5. **Executable fidelity:** did IR lowering, specialization, backend codegen and target validation preserve observable behavior (or carry explicit trusted limitations)?

A malicious/incorrect extension can miscompile while a correct kernel checks a theorem about the *wrong* program. Consequently no extension can self-authorize correctness by emitting an accepted flag, source map, npm provenance object, theorem label or certificate JSON.

## 3. Minimal semantic and execution topology

~~~text
.ps source + locked packages + exact profile
  |
  v
small owned syntax and name-resolution / elaboration contracts
  |  E0 libraries; E1 syntax candidates only in named extensible profile
  |  E2 proof producers; E3/E4 optimizer/backend candidates
  v
immutable PSCV Core + source/environment binding
  |                 |
  |                 +-- exact obligations/specification approval
  |                           +-- .proof.ps, native checker
  |                           +-- .proof.lean, OPTIONAL pinned Lean frontend
  |                                          +--> Lean export/replay/comparator
  |                                          +--> checked PSCV↔Lean bridge
  v
provider-owned official Lean kernel (native / Wasm)
  |
  v
KernelChecked<ExactCore> -- + all above mandatory proof obligations -->
  |
  v
PSCVSourceCertified (one-session authority, cannot deserialize from JSON)
  |
  v
erasure/RuntimeIR validation/specialization
  |
  +--> TS source backend (optional tsc)
  +--> Direct JS + JsIR validator
  +--> Wasm + WasmIR validator
  +--> Rust source backend (optional rustc)
  |
  v
typed ArtifactBundle + independent ClaimSet + archive
~~~

**Core runtime ownership:** contracts, primitive Core syntax/types, session-bound kernel check and certified-source gate, deterministic module/profile identity, mandatory validators and extension-isolation broker. Do not load third-party JavaScript into this authority process. Third-party code should execute as an isolated process or sufficiently constrained Wasm component; receiving messages is not permission to trust them.

**Optional systems:** full Lean frontend, Mathlib, Std.WP, LSP, target postcompilers, package registry/cache, SAVEF, arbitrary E1 syntax and E4 backends. These are not normal mandatory dependencies of minimal native psc.

**Goal for package count:** a few coarse-grained, well-defined package boundaries, not one npm package per Lean source module. Split only if independent deployment/lifecycle/performance is demonstrated.

## 4. Proposed public packages

| Package | Responsibility | Initial deployment |
|---|---|---|
| @proofscript/pscv-core | Small trusted composition, typed source/Core/claim boundaries | Runnable P0 Node skeleton; later native core |
| @proofscript/pscv-kernel | Provider-neutral selection for the exact official kernel npm package | Runnable P0; pinned 4.34-only |
| @proofscript/pscv-extensions | Extension metadata, class/policy validation and activation fingerprint | Runnable data-only P0 |
| @proofscript/pscv-cli | Development executable psc-core, later thin npm shim for native psc | Runnable limited P0 |
| @proofscript/pscv-frontend | Owned minimal PSCV parser/elaborator, generated Core | Not yet implemented |
| @proofscript/pscv-proofs | Obligation set, approved spec and evidence binding, proof file registry | Not yet implemented |
| @proofscript/pscv-lean-proof | Optional full Lean/Mathlib proof frontend + LeanExport/checker/comparator | Not yet implemented |
| @proofscript/pscv-ir | RuntimeIR and mandatory validators/specialization | Not yet implemented |
| @proofscript/pscv-backends | Four backend descriptors / code emitters and validators | Not yet implemented |
| @proofscript/pscv-extension-host | Isolated Wasm/process executor and capability broker | Not yet implemented |
| @proofscript/pscv-runtime-* | Optional target runtime and ABI/WIT packages | Not yet implemented |
| @proofscript/pscv-<os-arch> | Pinned native compiler release binaries | Not yet implemented |

Provider dependencies: @proofscript/pskernel-lean@4.34.0 and @proofscript/pskernel-lean-wasm@4.34.0. Each is optional and never a dynamic arbitrary package name. No user-configurable provider path in verified build policies.

A production packaging transition must address that the P0 JS host itself can execute arbitrary installed code if its trusted dependencies are compromised. Pin versions and tarball integrity, reduce dependency count, and move authoritative certification into a measured native/isolated component; JavaScript's Object.freeze is not an operating-system sandbox.

## 5. Language feature extensions as npm packages

| Kind | Allowed proposal | Proof/semantic rule |
|---|---|---|
| E0 library | .ps definitions, checked structural interfaces | Normal kernel and package import checking; no compiler execution |
| E1 syntax rewrite/notation | Explicit grammar rule and canonical syntax transformation | Forbidden in closed Standard/pscv-v1; in extensible profile parser must reparse expanded output and verify source meaning |
| E2 proof producer | tactic/SMT/AI/Lean proof candidate | Candidate elaborates to full proof term; independently kernel checked with approved axioms |
| E3 optimizer | typed IR-to-IR transformed candidate | Independently check IR plus transformation equivalence or explicitly account for executable-fidelity TCB |
| E4 backend/ABI | target artifact candidates | Exact source/IR subject, target validation, trust/translation-validation disposition; never semantic authority |
| E5 semantic elaborator | alters source-to-Core meaning | **No normal third-party plugin in verified closed profile**; requires trusted audited profile revision or independently checked refinement |
| E6 foundations/kernel | changes universe, defeq, inductive rules, axiom policy | **Not an npm plugin**; separately versioned semantic/kernel release |

A package installation is not activation. Manifests are data, activations must be explicitly named in a locked ProfileEnvironment and their digest must participate in cache keys and proof identities. The execution environment cannot be selected by the npm package alone.

This P0 intentionally implements only manifest validation/activation records and forbids E5/E6/U3. It does **not** execute even E1/E2/E3/E4 until isolated execution, canonical data transport and validators exist.

### Feature-addition recipe

For a new convenient source feature such as an alternative loop spelling: declare an E1 extension for an explicitly extensible profile; implement a deterministic expansion into existing standard forms; independently parse/elaborate the expansion through the core-owned frontend; expose origin maps; prove or validate the transformation; do not change Core theory. It cannot silently change the meaning of a closed pscv-v1 project.

For new verified effects, integer semantics, user axioms, reflection, unsafe FFI or new Core primitives: require a new semantic profile/verified boundary with explicit effect, erasure and kernel contracts, plus source-to-Core and runtime preservation. If a change can make an invalid theorem accepted, it belongs in the trusted semantic release, not an npm syntax plugin.

## 6. Exact provider/admission contract

P0 uses the provider-owned v2 envelope (UTF-8 JSON): format proofscript-checked-admissions, version 2, admissions array. The adapter checks bounded size, top-level shape, exact provider metadata (protocol pskernel-lean/1, provider lean4-cpp, profile lean4.34-core, pinned version/commit) and accepted boolean; it also requires errorKind on rejection.

**Native:** pass env={} and allowSourceCheckoutFallback=false into the trusted package adapter so PSC_LEAN_KERNEL_PROVIDER_BIN cannot bypass the bundled manifest-checked release binary. **Wasm:** use the default bundled launcher and prebuilt-verification path; no arbitrary launcher option. Limits are explicit. The provider wrapper and Node host are still in the TCB and can still be corrupted by privileged host compromise.

Only a result named **kernel-admissions-accepted** is produced. No automatic source hash association, PSCV certificate, global soundness proof or verified executable is invented. An admission report is serializable evidence, not a live checked-Core capability.

For assured implementation, the provider should run as a separate checked authority process with anti-replay session handles, exact bytes and full selected environmental policy captured. The host must not take an arbitrary checker callback from an extension.

## 7. First-class *.proof.ps and *.proof.lean

Build the proof authoring API around **one immutable obligation set derived from actual checked PSCV Core**, not around the filename of the proof.

- Native .proof.ps proof elaboration uses the owned PSCV language and selected kernel provider.
- Optional .proof.lean loads a generated Lean module containing the *checked program meaning* and the approved theorem statements. Full Lean syntax, metaprogramming and Mathlib run only in an isolated pinned Lean proof sidecar.
- Reuse the upstream Lean 4.35-rc3 LeanExport NDJSON, LeanChecker/Replay, Lake.Check.Compare and Lake.Check.Axioms. Their output is candidate proof evidence that must be independently checked.
- **Freeze the actual program definitions.** The Lean comparator can intentionally let a challenge's definition holes be filled; PSCV must designate only proof bodies as fillable, never a checked .ps implementation. A different implementation trivially satisfying a theorem must reject.
- Bind proof statement, checked source Core hash, approved spec hash, semantic profile, environment, exact upstream Lean revision/Mathlib lock, extension set, permitted assumptions and checker identity. Record all permitted axioms; forbid sorry/admit or unapproved axioms.
- Match the Lean proposition against the PSCV proposition through an independently checked Core-to-Lean correspondence relation. Proof that a convenient Lean lookalike is correct does not prove compiled .ps behavior.
- In future, cache accepted Lean proof evidence for reuse when the exact correspondence and subject identities match. .olean is a Lean cache, not sufficient portable certification evidence.
- Do not claim PSCV certified compilation until source/obligation/effect/erasure/backend gates separately succeed.

The existing kernel 4.34 providers are not compatible *by assertion alone* with V6's Lean 4.35 proof/export source. Build and validate 4.35 version-aligned kernel packages before accepting 4.35 proof evidence as V6 certification.

## 8. Security/soundness threat model

**Trust inputs:** arbitrary downloaded npm packages, source, proof terms, plugin outputs, challenge/solution export files, target ABI declarations, caches, build scripts and user-supplied paths.

**Threats:** altered parser/elaborator output; unapproved axiom or fake theorem; different program in Lean proof than compiled .ps; malicious JS/wasm backend output; extension code modifying host globals; postinstall scripts; package substitution/version drift; checked-handle replay; unbounded memory/CPU; path escape, network/data access and poisoned evidence caches.

**Required controls:**

1. Minimal exact pinned kernel and authority provider, ideally isolated from extension workers.
2. Admit only registered canonical logical rules; explicit pinned prelude, assumption allowlist and standard environment.
3. No trust from serialized claim flags, signatures, file names, npm provenance, source-map metadata or test status.
4. No third-party runtime import/eval/require inside authority process. Extension workers exchange canonical bounded messages; host sandbox enforces allowed filesystem/network/CPU/memory capabilities. Wasm alone is not a sandbox if host grants unbounded powers.
5. CI install with --ignore-scripts for nonessential dependencies; separately audit runtime code that still executes under its declared capabilities.
6. Full byte and identity binding between source/Core/spec/proof/IR/backend artifacts; mutation invalidates cached evidence.
7. Explicit downgrade for plain/unverified compilation. Verified emission fails closed on any missing, stale or unsupported obligation.
8. Never claim a backend is logically sound because the Lean kernel accepted source declarations; executable fidelity needs its own validation.
9. Native/Wasm differential kernel conformance on malformed and accepted inputs; a disagreement blocks claimed consensus.
10. Audit supply-chain manifests, runtime linked libraries, updater capabilities and platform-specific binaries.

**Residual risk:** a compromised trusted kernel binary, JS host or incorrectly implemented source-to-Core bridge can still violate soundness. No packaging strategy proves the absence of malicious code. The correct goal is a small measurable TCB, explicit remaining trust, independent checkers, isolation and reproducible negative evidence.

## 9. Lean source reuse strategy

| Lean source family | Reuse location | Default runtime impact |
|---|---|---|
| C++ kernel + Lean Core models | Already via official provider npm packages | Checker only |
| LeanExport, LeanChecker/Replay, comparator/axioms | Optional Lean proof package | None for default .ps use |
| Lean.Elab and Lean.Parser | Optional full Lean frontend and maybe internal build tooling | Avoid importing full frontend into minimal authority runtime |
| Std.WP, Std.Do, proof automation | Optional proof producer and pinned verification library | No logical-authority shortcut |
| Lean runtime / Lean native compiler | Build native PSCV; package measured runtime closure | Lean runtime may be linked, but no Lean toolchain installed |
| Lean LCNF, IR and C backend | Optional native backend / building PSCV | Do not replace four first-class PSCV backends |
| Lake and Mathlib | Optional .proof.lean authoring dependency | No default requirement |
| Lean LSP | Optional IDE integration | No default requirement |

Primary upstream pins: [Lean 4.35 src](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src), [LeanExporter](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/LeanExport.lean), [LeanChecker](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/LeanChecker.lean), [Lake comparison](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/Check/Compare.lean), [Std.WP](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP.lean).

## 10. Evaluation against requested criteria

The values below describe **architectural design intent**, not measured conformance or formal security proof. Each requires explicit exit evidence.

| Criterion | Core design mechanism | Evidence needed |
|---|---|---|
| Soundness/fidelity | Kernel/Core/Source/Runtime distinct checks, immutable subject identities | Formal relation or independent translation validation |
| TCB transparency | Small authority kernel + explicit node/FFI/extension boundary | Machine-readable TCB inventory, binary link map |
| Adversarial robustness | Strict parser/codec budgets, deny unknown/untrusted claims | Negative input corpus, differential/conformance results |
| Small compiler/extendibility | Data-only declarative E0-E4, optional isolated hosts | Measured core binary size/import closure and feature addition |
| Architecture | Typed semantic spine + package contracts | Import graph and owner-level integration tests |
| Performance | Incremental hashed DAG, optional proof sidecar | Cold start, RSS, package footprint, large project benchmarks |
| Longevity | Versioned protocol/semantic locks, few interfaces | Cross-version upgrade/downgrade tests |
| Interoperability | npm/native + optional Lean/WIT/TS/JS/Wasm/Rust | Target and ABI bridge fixtures |
| Future self-host | No source restrictions today; preserve small owned semantic core | Optional fixed-point and verified bootstrap later |
| Auditability | Canonical declared extension set, source/proof/claim receipts | Independent offline replay, provenance |
| Security | No extension JS authority, no install scripts, isolated runners | Sandboxing, dependency and resource reviews |
| Soundness security | No unapproved axioms/false proof/unchecked compiler equivalence | Cross-language negative proof tests and checker diversity |

No arbitrary >97% score is assigned before measured evidence exists. A quality bar must measure whether malicious or buggy extensions can cause false acceptance or silently alter compiled behavior, not simply whether an API has a validator-shaped function.

## 11. Engineering milestones / non-negotiable gates

**P0 — implemented on this branch:** new npm-shaped workspaces, profile+extension manifest parser, exact Lean 4.34 native/Wasm provider adapter, source hash inspection, noncertifying kernel-admission CLI, negative tests and cloud provider integration. Do not call this a full compiler. Validate published packages separately before release.

**P1 — real owned PSCV frontend:** implement only a small normative .ps grammar and elaboration closure, using well-founded compiler-owned Lean-compatible Core. Need valid/invalid source-to-Core differential fixtures against exact semantics, no implicit Lean frontend fallback, resource budgets, untrusted E1 expansion isolated. No legacy parser dependency.

**P2 — live checked Core issuer:** kernel check exactly the resulting Core under one provider/session, fail on provider mismatch and source mutation, with immutable inputs. Only the issuer may create live checked capability; no serializable capabilities. Add native standalone Lean-built tool and clean-machine package checks.

**P3 — proof obligations:** approved specification identity, mandatory closure, native .proof.ps; optional pinned Lean 4.35 proof toolchain and .proof.lean bridge with immutable exact proposition matching, axiom closure and independent replay.

**P4 — real target pipeline:** erasure -> validated RuntimeIR -> specialized IR -> TS/JS/Wasm/Rust, backend validators, typed artifacts. Source codegen and behavioral preservation are separate claims. Extensions only produce candidates until host validators accept them.

**P5 — npm ecosystems and security:** npm platform binaries, .ps source+proof modules, semantic dependency lock, install-not-enable extension descriptors, isolated U1/U2 extension host, native and cross-platform release, E0-E4 extension conformance fixtures. No E5 arbitrary semantic extension in verified closed profile.

**P6 — formal evidence, portability, optimization:** reduce TCB, complete semantic/binary correspondence, compare kernel implementations, resource/supply-chain campaigns; optional self-host and diverse bootstrap do not block earlier functional compiler engineering.

Promotion requires objective acceptance matrix for each stage. Do not weaken certified build gates for green CI. Do not preserve obsolete code only to satisfy historical imports; replace the import/ownership relationship and remove superseded code in a deliberate commit after the new path works.

## 12. P0 test evidence requirements

- Manifest class and profile negative cases; unknown E5/E6/U3 and accessor-bearing descriptors reject.
- Exact provider metadata/native binary checksum and Wasm prebuilt validation are delegated to pinned packages; main adapter ensures overrides disabled.
- Pinned native/Wasm test: valid empty declaration set accepted; malformed declaration rejected; only kernel-admission claim returned.
- Source scan explicitly not called parser/elaboration; plain JSON accepted flag cannot mint certificate.
- build()/verify() and unsupported profiles reject; npm package tarball dry-run succeeds.
- No tests here can establish arbitrary .ps compilation, full Lean 4.35 semantics, or PSCV-CERT.

**Final decision:** a small new core with strong authority partitioning, npm-first extensions for safe new syntax and tools, no legacy compatibility debt, four future first-class targets, and Lean proof reuse through independently checked relations. The core remains boring; optional packages provide powerful features without silently altering the meaning of valid proofs.
