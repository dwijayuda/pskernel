# THE PSCV COMPILER REFERENCE — VERSION 6
## Lean-built standalone compiler · bounded ProofScript language · optional Lean proofs · npm-first ecosystem

**Status:** proposed successor architecture, for review and staged adoption; **not** an implementation-complete or certified-release claim.  
**Repository:** [`dwijayuda/pskernel`](https://github.com/dwijayuda/pskernel)  
**Audited branch / HEAD (2026-10-08):** `pscv/v3-execution` / `93add6da4e501c57f9016c7c3666ea52c87a66e7`  
**Primary source tree:** `psc15selfhost/`  
**Previous architecture:** [`THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md`](THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md)  
**Normative language authority:** [`PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md)  
**Inherited design contracts:** Semantic Spine, Claim Lattice, Authority Firewall, ProfileEnvironment, Build/Query Identity, typed ArtifactBundle, KernelContract, PSCV-CERT, RuntimeIR/target validation.  
**Base language edition:** `ps-0.9-r3` · **closed verified profile:** `pscv-v1` · **verification semantics:** `PSCV-VERIFY-v1` · **certificate policy:** `PSCV-CERT-v1`  
**Normative semantic reference:** Lean 4.35.0-rc3, commit `470d5ce1400764999581fd26d5d72b00d990b0f4`.  
**Existing bootstrap implementation:** Lean 4.34.0, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.  
**Current compiler milestone:** `psc2-compiler-v1`, not `pscv-compiler-v1`.  
**Research date:** 2026-10-08.

> **V6 decision:** Lean 4 may build, typecheck and verify the *implementation* of PSCV. Release a standalone native `psc` with its necessary runtime and selected checker-provider dependencies, but **without requiring the Lean frontend, `lean`, Lake, elan, `.olean` workspace, or npm at runtime**. The optional `psc-lean` integration delegates complete `.lean` parsing/elaboration/tactics/Mathlib to pinned official Lean; its output is not automatically PSCV-certified. Write executable programs in `.ps`, and allow linked proofs in `.proof.ps` and/or `.proof.lean`. Use npm as the primary **distribution** channel for the compiler, libraries, proofs, extensions, adapters, and runtime bindings—not as logical or semantic authority. **Self-hosting is a deferred independent goal, not a prerequisite for a functional standalone compiler.**

> **Truth hierarchy:** This reference decides architecture, packaging, and integration. It does not override the normative language grammar, verification rules, standard-environment manifest, PSKernel-owned kernel contracts, or actual checked-service implementation. Proposals and sample CLI/JSON below are *proposed*, not existing public API. Neither a Lean-checked theorem, successful backend emission, a fixed point, npm integrity, CI provenance, nor installation success alone constitutes `PSCV-CERT-v1`.

---

# 1. Executive decision and V5.1-to-V6 delta

V5.1 established a small checked semantic spine with four first-class backends and separate assurance, development, interoperability and release systems. **V6 retains this spine unchanged**, but changes *how it is built, verified, extended, packaged and adopted*.

| Architectural issue | V5.1 preserved baseline | V6 explicit decision |
|---|---|---|
| Primary PSCV implementation | Lean-written portable/bootstrap source with later self-host closure | **Lean-hosted native compiler first**; compiler self-host is non-blocking, kept as a separate preserved lane |
| Distribution | Typed artifacts and release/provenance design | **Standalone native `psc` and npm-first registry**; distinct binary archives for Node-free users |
| Lean build dependency | Official Lean + Lake for bootstrap | Lean/Lake **build-time only** for native PSCV, not user-install prerequisites |
| Runtime proof checker | KernelContract and provider-authority separation | Keep provider-neutral interface; explicit native/Lean reference-provider selection; no unchecked fallback |
| Full Lean syntax | Bounded `lean-subset-psc2-v1` | `.ps` remains bounded; **full `.lean` only via optional official Lean sidecar**, not via native parser emulation |
| Program/proof authoring | PSCV spec coverage and checked evidence | `.ps` executable with `.proof.ps` and/or `.proof.lean` proofs, including mixed project closure |
| npm | JS ecosystem target and package workspace | Registry delivery of `.ps` source, proof sources, interfaces, WIT/Wasm, compiled JS/TS and metadata; **npm is never proof authority** |
| Extensions | E0–E6 / U0–U3 with Authority Firewall | npm-packaged, disabled-until-declared, profile-pinned, capability-bounded and isolated; semantic E5 requires explicit trust |
| Interop | InterfaceIR/WIT/Canonical ABI | Optional Lean proof adapters and target/platform consumers; no hidden change to four backend semantics |
| Assurance | Separate claims and eventual DDC/self-host | Implementation first **without weakening certified emission**; independent proof-assurance and bootstrap evidence later |
| SAVEF | Companion system | Reuse as portable knowledge/evidence graph across npm, WIT/Wasm and other registries; no proprietary mandatory `.psenv`/`.psk` |
| Release gates | ClaimSet, ArtifactBundle and identity | Add clean-machine independence, platform/package integrity, mixed-proof equivalence and extension-isolation gates |

## 1.1 Non-negotiable laws

1. **Lean builds PSCV; PSCV compiles `.ps`.** Do not confuse building a compiler with compiling user programs through Lean.
2. **No hidden runtime toolchain.** The default `psc` package must function without Lean, Lake or elan. Native runtime libraries and optional checker processes are permitted when shipped and disclosed.
3. **One small native language.** `.ps` has a specified, closed semantic meaning in `pscv-v1`; arbitrary Lean extensions never silently leak into it.
4. **Full Lean compatibility is delegated, not reimplemented.** `.lean` remains genuine Lean 4 via an explicit optional integration. A new native `.lean` parser does not claim full Lean compatibility.
5. **Proof language is not executable language.** Application source is `.ps`; `.proof.ps` and `.proof.lean` are separate proof roots and may be mixed.
6. **Cross-language theorem identity is mandatory.** A proof of a translated Lean lookalike is not proof of the actual PSCV source absent a checked correspondence relation.
7. **Fail closed on verified emission.** Unchecked Core, invalid IR, missing approved specifications, unresolved proof obligations, nonconforming imported assumptions and unvalidated adapters prevent certified artifact emission.
8. **npm is a transport, not a trusted compiler extension host.** No automatic authority from package presence, dependency scripts, provenance or registry signatures.
9. **No forced bootstrap churn.** Existing PSC1 portable/self-host stable source, historical fixed points, kernel branch boundaries and their evidence remain intact.
10. **Capability-first modularity.** Optional Lean, proof packs, backends, extension hosts, SAVEF, archive and release machinery cannot widen the core compiler's trusted computation silently.
11. **Evidence is separate from semantics.** Parsing, checking, certification, preservation, reproducibility, source–binary correspondence, DDC and publication provenance are distinct claims.
12. **Prefer measured simplification over ideological purity.** Relax historical self-host syntax restrictions for a new Lean-native implementation lane *only where behavior and trust boundaries can be preserved*.
13. **No trust from generated API names.** A `VerifiedIR`-named value or a native `check` command is not automatically a checked or certified handle.
14. **Exact semantic identities.** Accepted proof imports and compiled artifacts bind source bytes, dependencies, profile, standard environment, toolchain/bridge versions, checker identity and applicable proof/effect policies.

---

# 2. Deep research: what Lean can and cannot be reused for

## 2.1 Lean as a build-time implementation language — adopted

Official Lean processes source through parsing, macro expansion/elaboration, kernel checking, executable lowering and compilation. Lake has `lean_exe` targets that build native executables from a `main` module. A Lean-built binary depends on Lean's runtime/linked native libraries **as packaged**, not inherently on the developer's `lean` or `lake` commands at runtime.

* Primary references: [Lean elaboration and compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/), [Lake executable targets](https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/), [Lean IO and runtime model](https://lean-lang.org/doc/reference/latest/IO/).
* Repository observation: [`psc15selfhost/lakefile.lean`](lakefile.lean) already declares `lean_exe psc` rooted at `PscMain`, and [`packages/cli/src/PscMain.lean`](packages/cli/src/PscMain.lean) already calls `psCliMain`.
* **Caveat:** size/startup/dependency savings are hypotheses until native distribution closure is measured for each platform. Static vs dynamic linking must be audited; no universal "single static executable" promise.
* **Caveat:** compiling the compiler with Lean checks its Lean declarations but does **not** prove that PSCV's parser, elaborator, translation, erasure or target backends preserve source semantics.
* Lean initialization brings real runtime modules and may retain more than obvious import closure; do not assume simply linking a kernel eliminates Lean's implementation costs. [Lean initialization source](https://github.com/leanprover/lean4/blob/master/stage0/src/initialize/init.cpp).

## 2.2 Lean as the runtime frontend — optional only

Lean's parser/elaborator is incrementally extensible: imported modules and preceding commands can change syntax, elaborators, attributes, environment extensions and tactic behavior. A hand-maintained PSCV parser for a fixed Lean subset cannot provide equivalent behavior for arbitrary `.lean` files or Mathlib.

* Reference: [Lean elaboration, command/environment changes and initialization](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/).
* Official Lean parsing, elaboration, macro/tactic machinery and pinned environments therefore belong in an **optional isolated `psc-lean` sidecar/toolchain integration**.
* "Full Lean source compatibility" applies only to **that Lean mode and its exact Lean/version/library closure**. It does **not** promise that all accepted Lean code lowers to PSCV RuntimeIR or all four target languages.
* A `.lean` program may be checked/compiled by official Lean without becoming a PSCV-certified executable. This is an explicit product distinction.

## 2.3 Lean kernel options — provider contract preserved

Three roles are separate:

| Role | Checker | Trust claim |
|---|---|---|
| Lean checks PSCV's **implementation** at build time | Official Lean kernel | Its own Lean declarations are well typed under pinned assumptions |
| Optional `.proof.lean` elaboration / proof checking | Official pinned Lean frontend + kernel in external/optional tool | That Lean proposition/theorem was accepted under an exact Lean environment and assumptions |
| `.ps` certified project gate | KernelContract-selected PSCV checker + certificate/bridge validation | All PSCV obligations, imports, mappings and policy closure accepted |

Initial standalone releases may ship a **separate native checker provider** rather than embedding the Lean frontend. This is still standalone distribution if the provider binary and needed libraries are included. No provider substitution, PSKernel promotion or cross-version equality claim occurs without explicit conformance evidence.

Repository evidence: [`packages/pskernel-core/README.md`](packages/pskernel-core/README.md) records `lean434-wasm` as trusted default and native PSKernel promotion as a separate decision; [`host/src/Ps/Host/LeanChecked.lean`](host/src/Ps/Host/LeanChecked.lean) checks prepared declarations through a Lean provider but explicitly does not prove erasure or backend preservation. Kernel implementation/metatheory remain owned by the separate kernel workstream.

## 2.4 Alternatives rejected/deferred

| Choice | Immediate value | Why not adopted as default |
|---|---|---|
| Embed full Lean frontend in native `psc` | Complete `.lean` frontend behavior in one executable | Larger and version-coupled dependency/runtime surface; defeats minimal independent release |
| Reimplement all Lean syntax, macros, elaborators, tactics and Mathlib in PSCV | No external Lean frontend | Duplicates a language/compiler ecosystem; severe soundness and maintenance costs |
| Translate `.ps` to Lean then invoke `lean` for every build | Easy early prototyping, reuse kernel/elab | Makes Lean mandatory at runtime; creates unproved source/representation and execution-translation obligations |
| Immediately self-host PSCV on JS, TS, Wasm and Rust | Diverse bootstrap and portability | Expensive, not needed for standalone native compiler; risks optimizing compiler source for historical restrictive subset |
| Make npm an executable plugin-loader by default | Easy extensions | Supply-chain execution and semantic authority risks; npm installation isn't an approval/verification step |
| Make Lake/npm `.olean` artifacts PSCV's certified knowledge format | Reuse existing binary cache | `.olean` is tied to exact Lean environments/toolchains and is not by itself a PSCV source/link/proof identity |
| Publish only npm JS build | Familiar Node distribution | Excludes native standalone users and compromises "no Node required" release objective |

---

# 3. Canonical architecture and system boundaries

```text
BUILD / AUTHORING (toolchains installed in CI or developer environment)
  Lean source for PSCV compiler -- Lean 4 + Lake/C/Clang --> native psc
  Lean proof authoring -----------------------------------> optional psc-lean
  npm source/artifact packages -- bounded package resolver ---------+
                                                                      |
RUNTIME / COMPILATION                                                |
  .ps source + source/profile/lock + approved specifications         |
      |                                                               |
      v                                                               v
  PSCV resolver -> parser -> elaborator -> typed Core / interfaces
      |                          |
      | KernelContract           +-- generate exact ProofObligationSet
      v                                      |
  Checked<Core>                              +-- .proof.ps via PSCV checker
      |                                      +-- .proof.lean via official Lean
      |                                            + checked bridge/identity
      +---------------------------+------------------------+
                                  v
                       Check proof + spec + effect closure
                                  |
                          Certified<Checked<Core>>
                                  |
                              erasure
                                  v
                     RuntimeIR -> strict validation
                                  |
                       Validated<RuntimeIR>
                                  |
                       specialization and pass contracts
                                  |
          +-----------------------+----------------------+
          |                       |           |          |
        TS source              direct JS     Wasm       Rust source
          |                       |           |          |
      opt-in tsc             JsIR verify   WasmIR verify opt-in rustc
          +-----------------------+-----------+----------+
                                  |
                      ArtifactBundle + ClaimSet
                                  |
                         npm / binary / other consumers
```

**Build-time dependence is not runtime dependence.** User computers need the distributed native compiler's actual runtime dependencies and a selected checker provider; the `psc-lean` sidecar is only required when a workflow explicitly requests full `.lean` elaboration or proofs not otherwise resolved by accepted reusable evidence.

## 3.1 Minimal semantic spine (unchanged from V5.1)

`SourceArtifact -> ProfileEnvironment -> Syntax/Elaboration -> Core -> Checked<Core> -> Certified<Checked<Core>> -> RuntimeIR -> Validated<RuntimeIR> -> SpecializedIR -> Backend TargetIR/Source -> ArtifactBundle`.

Compile-time obligations are *not* invented as separate runtime semantics; evidence and stronger claims wrap exact subject artifacts. Keep existing model/validators, pass contracts, query fingerprints, OriginGraph, PublicApiIR, structural/behavioral module interfaces, independent archive/evidence consumers and explicit resource limits.

## 3.2 Package ownership and import law

Recommended logical ownership, not a demand for immediate repository churn:

```text
psc-core/                     only semantic Core models and contracts
psc-frontend/                 .ps parser, resolver, elaborator, diagnostics
psc-checking/                 provider-neutral checked sessions
psc-obligations/              obligations, coverage, specification binding
psc-proofs/                   .ps proof producer, immutable evidence consumer
psc-lean-adapter/             optional external official Lean adapter
psc-bridge/                   typed Core/proposition semantic correspondence
psc-runtime-ir/               erased IR, validation and specialization
psc-backends/{ts,js,wasm,rust}/ backend contracts and generation
psc-interface/                PublicApiIR, InterfaceIR, WIT, ABI
psc-package/                  npm asset resolver, semantic dependency lock
psc-extension-host/           isolated producer execution, pinned manifests
psc-release/                  bundles, reproducibility, provenance, archive
psc-cli/                      native composition root, no implicit authorities
```

The current `psc15selfhost/packages/*`, `host/`, `scripts/` and `contracts/*` remain implementation sources of truth. Prefer logical interfaces and wrappers initially; physical moves must be separately justified by import-closure evidence.

---

# 4. Native compiler packaging and release profiles

## 4.1 Two distribution formats, one compiler identity

1. **Native archive** (`psc-<version>-<target>.tar.gz` or platform equivalent): directly executable `psc`, required native libraries, selected checker-provider binaries/config, licenses and exact manifest; **no Node, npm, Lean or Lake needed** for default supported compilation.
2. **npm CLI** (`@proofscript/cli`): thin JS launch shim plus platform-specific optional native packages. Node is used by the *npm launcher only*; after launch the native semantic compiler must not depend on the Node process unless an explicit Node-specific extension/host is requested.

Suggested platform split: `@proofscript/cli-linux-x64-gnu`, `...-linux-x64-musl`, `...-linux-arm64-gnu`, `...-darwin-arm64`, `...-darwin-x64`, `...-win32-x64`. These names are provisional, and publication should cover only platforms for which CI has built and tested binaries. Use npm `os`, `cpu`, `libc`, `optionalDependencies` and `bin` correctly; validate missing/unsupported platform as an explicit actionable error. No silent download of replacement executables or unverified fallback; no install-script compilation.

* References: [npm `package.json` platform and bin fields](https://docs.npmjs.com/files/package.json/), [Lake executable output and runtime](https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/).

## 4.2 Release levels

| Product mode | Required capability | Permitted claim |
|---|---|---|
| `psc --version` / `psc check` basic | Native installed compiler, syntax/elab diagnostics | Diagnostics, not kernel or PSCV certificate unless specifically checked |
| `psc build --profile standard` | The selected nonverified profile's explicit rules and valid target representations | Plain compiled artifact; **never** claim verified |
| `psc check --kernel ...` | Selected provider session checks exact Core under declared environment | Kernel checked with exact provider, not automatically certified |
| `psc verify --profile pscv-v1` | Complete coverage, obligations, assumptions, imported bridge evidence | PSCV-certified only when the full certificate contract is satisfied |
| `psc build --verified` | Above certificate plus target-specific validation/preservation policy | Verified-release claim exactly as supported by evidence and policy |
| `psc lean ...` | Optional official Lean frontend present, pinned version and library lock | Lean check/Lean compile; **not** default PSCV certification |
| `psc build --backend rust/ts` | PSCV emitted target source; optional external compilation to executable | Target source or native output distinctly recorded |

These are *proposed CLI semantics*. Existing [`packages/cli/src/PsCli.lean`](packages/cli/src/PsCli.lean) exposes a different bootstrap CLI; compatibility aliases must not silently increase their checking claims.

## 4.3 Release gates

A candidate native `psc` is *standalone* only after CI:

- builds the exact pinned Lean source closure (with reproducible build metadata);
- installs archive and npm tarball on **clean** Linux/macOS/Windows runners without developer Lean/Lake/elan or project build tree;
- verifies `psc --version`, parsing, a valid/invalid checked `.ps` case, a verified-profile rejection case, JS/TS/Wasm/Rust source emission and applicable target validation;
- confirms no mandatory shell-out to `lean`, `lake`, `node`, `npm`, `tsc` or `rustc` in default native `.ps` compile paths; target post-compilers may be explicitly selected;
- audits dynamic dependencies (`ldd`/`readelf`, `otool`, Windows equivalents), bundled runtime licenses, libc/ABI compatibility and executable signature/digest;
- verifies that the *production* native CLI composes checked-session capabilities instead of the unchecked bootstrap `psHostCompilerCheck` admission-ready path;
- tests failure of missing provider, incompatible provider, malformed proof receipt, invalid profile, absent platform package and disabled extension;
- tests no install script and no unapproved network access on verification/build paths;
- measures native archive/package size, cold start, peak RSS, representative compile times and cross-platform variance; budgets are set from actual measurements, not invented here.

**Current blocker:** The repo's production checked authority resides substantially in [`scripts/compiler-checked-service.mjs`](scripts/compiler-checked-service.mjs), whereas `PsCli.lean`'s `check` uses a host preparation route. V6 requires functional native capability parity *before* claiming a fully checked standalone `psc`.

---

# 5. Source compatibility: `.ps` bounded, `.lean` optional and full

## 5.1 Profiles

- **`.ps` / `pscv-v1`:** closed PSCV source grammar and verification semantics; user/ordinary dependencies cannot mutate parsing or elaboration implicitly.
- **`.ps` / `ps-standard-0.9-r3`:** the closed base language profile, potentially buildable without verified claims.
- **`.lean` / `lean-subset-psc2-v1`:** existing bounded native compatibility profile only; implement exactly declared source-compatible families and reject unsupported constructs.
- **`.lean` / optional full Lean frontend:** invoke pinned official Lean for arbitrary supported Lean syntax, macros, attributes, tactics, libraries and Mathlib relative to its exact environment. It is **not** a PSCV semantic profile or implicit permission to emit every Lean declaration through PSCV backends.
- **Extensible non-PSCV profile:** explicit E1/E5 source extensions with pinned identities and isolation/trust disposition; never silently convert to `pscv-v1`.

Normative basis: [`PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md), chapters 2, 28, 29 and 30. V6 does not replace its finite grammar or accidentally add unrestricted Lean syntax to `.ps`.

## 5.2 Full Lean adapter modes

| Operation | Input | Engine | Output | Allowed guarantee |
|---|---|---|---|---|
| `lean check` | `.lean` | Official Lean at pinned revision | Diagnostics / checked declarations | Lean acceptance |
| `lean build` | `.lean` | Official Lean native pipeline | Lean native artifact | Lean compile, not PSCV certified |
| `lean prove` | `.proof.lean` plus checked PSCV interface | Official Lean + bridge validator | Lean proof receipt/candidate checked content | Lean proof accepted for *mapped proposition* |
| `lean import` | Lean declarations/checked exports | Explicit checked bridge | Supported PSCV Core/interface/evidence | Only if correspondence checker accepts |
| `psc build --frontend lean` | `.lean` | Optional Lean and selective PSCV conversion | Target artifact or explicit unsupported error | Strictly partial cross-compilation |

Avoid "full Lean source to all PSCV backends" promises. Expressions with unsupported computational representations, FFI/IO, partial/unsafe recursion, exotic compiler intrinsics or unsupported environment extensions must reject or remain on Lean's own target route.

---

# 6. Mixed `.ps`/`.lean` proof architecture

## 6.1 Canonical project convention

```text
my-project/
  package.json
  proofscript.json
  psc.lock.json                       # proposed semantic/proof lock, not .psenv/.psk
  src/
    Counter.ps
    Main.ps
  proof/
    Counter.proof.ps
    Arithmetic.proof.lean
    Main.proof.ps
  dist/                               # generated, not authoritative
```

A program module can have zero, one or many proof roots. Filename matching is a **discovery convention**, not proof identity. A stable theorem/obligation ID in an approved specification manifest binds each proof to its exact obligation; proof file names cannot silently select/replace specifications.

The default is `.proof.ps` because it keeps the project lightweight; use `.proof.lean` for Mathlib or richer tactics. Both may discharge distinct obligations in the same project. Every mandatory obligation needs **accepted** evidence, not two redundant proofs.

## 6.2 Example: `.ps` program, ProofScript proof

**Illustrative proposed cross-file form; syntax belongs to the normative language reference.**

`src/Counter.ps`:

```proofscript
function increment(x: Nat): Nat := x + 1
```

`proof/Counter.proof.ps`:

```proofscript
import Counter

theorem increment_correct(x: Nat):
    Counter.increment(x) = x + 1 := by {
  rfl
}
```

`psc` checks the theorem against the actual checked `Counter` declaration and the approved obligation. A theorem merely sharing a name is not sufficient.

## 6.3 Example: the same `.ps` program, official Lean proof

`proof/Counter.proof.lean` (proposed generated Lean-facing name):

```lean
import PSCV.Generated.Counter

namespace Counter

theorem increment_correct (x : Nat) :
    increment x = x + 1 := by
  rfl

end Counter
```

The generated `PSCV.Generated.Counter` module must be **derived from exact checked PSCV Core and a checked semantics bridge**, not handwritten duplication. The bridge proves or independently validates that each exported Lean definition/proposition corresponds to the immutable PSCV semantics. An equality proof about some other Lean function is not accepted.

For Mathlib-dependent proofs, the isolated Lean project can use a generated Lake workspace with a pinned `lean-toolchain` and `lake-manifest.json`. The resulting proof evidence is exported through a versioned, bounded interface; `.olean` is an optional Lean cache, not the PSCV proof certificate.

## 6.4 Mandatory cross-language proof handoff

Proposed immutable `ProofObligation` / `ProofEvidence` ownership:

```text
ProofObligation {
  obligationId,
  sourceModuleId,
  checkedDeclarationId,
  sourceCoreHash,
  approvedSpecHash,
  propositionCoreHash,
  semanticProfileId,
  standardEnvironmentId,
  importedInterfaceIds,
  assumptionsPolicyId,
  effectOrFrameContractId?
}

LeanProofReceipt {
  obligationId,
  leanToolchainCommit,
  leanPackageLockHash,
  generatedLeanModuleHash,
  leanPropositionHash,
  checkedTheoremIdentity,
  admittedAssumptionInventory,
  bridgeContractId,
  bridgeEvidenceHash,
  checkerIdentity,
  resourcePolicyId,
  receiptHash
}
```

These field names are schematic: require canonical versioned encodings, deterministic IDs, fixed resource limits and replayable validation. `LeanProofReceipt` alone is **not** `PSCV-CERT`; the bridge must establish proposition/environment correspondence and the PSCV certificate consumer must validate all subjects and assumption policies. Never silently trust JSON `accepted: true`.

**Required relation:** for an obligation `P_ps` and its Lean image `P_lean`, verify `TranslateProp(P_ps) = P_lean` under a pinned semantics-preserving bridge, or provide an independently checked theorem/translation-validation certificate justifying the relation. An unchecked pretty-print/source translation cannot replace this obligation. Runtime computation correspondence must separately be established for source functions referenced by the proposition.

Failure cases: changed source/contract/import/profile, bridge mismatch, unsupported Lean declaration, `sorry`/unapproved axiom, untrusted extension, theorem of different proposition, different Lean revision/library lock, modified receipt bytes, resource exhaustion or missing checker. Fail closed and identify the exact stage.

## 6.5 Distinct proof claims

- `LeanAcceptedProof`: official Lean accepted a theorem under an exact Lean environment.
- `BridgeMatchedProof`: the theorem's proposition/subject and allowed assumptions are matched by checked PSCV bridge evidence.
- `PSCVObligationClosed`: a required PSCV obligation is discharged under the active policy.
- `PSCVSourceCertified`: the selected executable roots have complete specification coverage and proof/effect/erasure closure.
- `BackendValidated` / `PreservationSupported`: backend-specific independent target validation/preservation evidence.
- `VerifiedExecutable`: only the conjunction demanded by the selected assurance policy, never a synonym for success of Lean elaboration.

This follows V5.1's Claim Lattice and avoids a dangerous "Lean proof accepted = PSCV program verified" shortcut.

---

# 7. npm-first package model

## 7.1 Decision and limits

**Primary distribution** is npm: `.ps` source libraries, `.proof.ps` and `.proof.lean` sources, prevalidated interfaces, runtime products, executable targets, extensions, WIT packages/adapters, compiler binaries and evidence manifests can reside in an npm tarball.

**Compiler semantics do not depend on npm:** npm resolves/transports tarballs and their lock-integrity; PSCV independently parses approved assets, constructs a frozen logical module graph and validates exact semantic/proof/ABI dependencies.

Secondary channels (GitHub Releases, Cargo, PyPI, Maven, WIT/component registries, direct binary archives) may mirror the same subject identity with platform-specific adapters. Avoid designing a mandatory dedicated registry or inventing `.psenv` / `.psk`.

## 7.2 Proposed official package families

| Package | Purpose | Runtime/build role |
|---|---|---|
| `@proofscript/cli` | Native `psc` launch shim, platform selection | Tool distribution |
| `@proofscript/cli-<target>` | Platform-specific `psc` binary + selected runtime closure | Native install |
| `@proofscript/stdlib` | Versioned `.ps` Standard library / interfaces | Logical dependency |
| `@proofscript/runtime-js`, `@proofscript/runtime-wasm` | Target adapters/ABI runtime | Generated executable |
| `@proofscript/lean` | Optional official Lean frontend integration adapter | External proof/build tool |
| `@proofscript/pskernel-core` | Independently owned kernel/checker package when promoted | Provider candidate; not auto-trusted |
| `@proofscript/proof-tools` | Proof packaging, manifest validation, diagnostics | Non-authoritative tooling |
| `@proofscript/ext-<name>` | Optional proof producer, syntax sugar, target backend or interface adapter | Explicit pinned extension |
| Community `@scope/my-lib` | `.ps` library plus `.proof.ps`/`.lean`, JS/Wasm/Rust products as available | Source/build/interop |

Names are suggestions; npm availability and ownership must be checked before publication. Do not leak internal `*-next` / `0.0.0-dev` bootstrap package naming into the stable release without a documented migration.

## 7.3 Proposed contents of a mixed package

```text
@example/safe-math/
  package.json
  proofscript.json
  src/SafeMath.ps
  proof/SafeMath.proof.ps
  proof/Arithmetic.proof.lean
  interface/                   # checked structural/public contract products
  evidence/                    # immutable linkage manifests / proof receipts
  wit/                         # optional WIT interfaces
  dist/js/index.js
  dist/js/index.d.ts
  dist/wasm/safe_math.wasm
  LICENSE
```

**Valid for four audiences:**
- `.ps` importers use checked PSCV source/interface and semantic lock.
- Lean proof tools use optional `.lean` project artifacts under a separate Lean lock.
- TypeScript/JavaScript consumers use ordinary `exports` and emitted `.js`/`.d.ts`.
- Wasm/foreign consumers use versioned ABI/WIT bindings and validated target bytes.

No requirement to publish every target for every library. ArtifactBundle advertises which outputs exist and what checks have actually been performed.

## 7.4 Two manifests, two dependency graphs

`package.json`: npm identity/version/tarball, `dependencies`, `optionalDependencies`, JS `exports`, platform restrictions, provenance.  
`proofscript.json`: PSCV package ID, module roots, profile/environments, exact import/export contracts, source/proof roots, declared extension/backends and minimum compatible verifier, mandatory artifacts and digests.

Example, **illustrative V6 schema to be separately specified**:

```json
{
  "schemaVersion": 1,
  "package": "@example/safe-math",
  "proofscriptEdition": "ps-0.9-r3",
  "sourceProfile": "pscv-v1",
  "moduleRoots": ["src"],
  "proofRoots": ["proof"],
  "semanticEnvironment": "STD-ENV-PSCV-V1-L435RC3-RC1",
  "checkedInterfaces": "interface/index.json",
  "evidenceManifest": "evidence/index.json",
  "artifactManifest": "dist/artifacts.json"
}
```

Do not use this illustrative JSON as a pre-existing executable contract; fields/serialization must be finalized with fixtures and a `PSC-PKG-*` version.

**Important:** npm semver alone cannot identify a checked logical environment. Different tarballs may have matching version labels, and npm may install nested copies of the same package. PSCV module IDs must include fully resolved package instance/path, canonical content hash, semantic profile, source module identity and checked imports. Ambiguous resolution fails rather than picking an arbitrary copy.

## 7.5 Semantic lock (separate from npm's integrity lock)

**Proposed `psc.lock.json`** binds:

- npm package identity + exact resolved tarball integrity for every reachable PSCV package;
- `.ps` module source/interface digests and approved profile/environment manifests;
- proof and specification closure identifiers, chosen checker-provider contracts, assumptions and certificates;
- optional exact Lean revision + Lake manifest/digest for `.proof.lean`;
- selected E0–E5 extension-set ID, ABI/WIT revision and affected trust policies;
- exact backend descriptor/target runtime profile IDs;
- required source mapping/erasure/preservation contracts for assured builds.

Generate deterministic, canonical JSON with versioned hashing. An external package's integrity hash proves byte equality with the resolved tarball, **not** semantic or proof acceptance. Regenerate dependency evidence when relevant semantic inputs change; never accept stale proof caches on version-range equality alone. A missing frozen Standard manifest SHA is a release blocker (still explicitly PENDING in the current normative RC).

`npm ci` is the recommended locked installation step; it refuses to rewrite mismatched lockfiles. `--ignore-scripts` blocks install lifecycle scripts. Policy must also prevent implicit execution of installed extensions at compile time. [npm CI docs](https://docs.npmjs.com/cli/commands/npm-ci/).

## 7.6 Import and package graph invariants

1. Filesystem package resolution precedes *logical* PSCV module resolution, but npm layout does not define theorem identity.
2. Every `.ps` import resolves to one canonical package instance/module source and checked signature.
3. Dependency upgrades re-evaluate ABI/spec and proof closure; only proven-safe unaffected caches remain reusable.
4. Imported certificates are checked for subject, profile, assumptions, standard environment and checker contract. Registry/provenance labels cannot authorize proof assumptions.
5. A package may be useful for plain compilation but inadmissible in closed verified profile; errors must explain which capability is missing.
6. A verified application cannot import arbitrary JS/TS runtime code as if it were a proved PSCV function; use explicit audited foreign-boundary contracts.
7. Package install-time scripts do not run as part of PSCV's proof/build protocol; official release paths should test `npm ci --ignore-scripts`.
8. Registry availability is not required for offline certified replay when exact referenced package bytes and evidence have been preserved.

---

# 8. Extension execution and source-fidelity firewall

V6 **retains V5.1 E0–E6 and U0–U3**:

| Class | Capability | Native `pscv-v1` default |
|---|---|---|
| E0 Library | Data, `.ps` modules, checked interfaces | Allowed after ordinary dependency validation |
| E1 Surface syntax | Canonical rewrite/sugar | Only explicit profile-pinned declared extension; output reprocessed |
| E2 Proof producer | Tactics, AI, SMT or Lean proof adapter | Produces *candidate*, not proof authority |
| E3 Compiler optimization | IR pass | Explicit pass contract plus proof/validator/TCB disposition |
| E4 Backend/ABI adapter | Target artifacts, WIT/foreign adapters | Explicit backend and interface descriptor; target validator |
| E5 Semantic elaborator | May alter source-to-Core meaning | Not in closed source profiles except explicit trusted/validated revision |
| E6 Foundation revision | Core/kernel meaning changes | **Not** a normal npm plugin; requires named SemanticProfile/kernel revision |

Execution: U0 data only; U1 Wasm Component + explicit WIT capabilities; U2 isolated bounded process/container; U3 trusted in-process code (enlarges TCB). Favor U1/U2 for third-party extensions. A manifest is not a sandbox; the selected runner enforces filesystem, process, network, resource and deterministic-output policy.

**Install ≠ enable:** `npm install @example/pscv-tactic` only delivers bytes. Activation requires project-side manifest selection, compatible pinned API/profile, capability approval and exact extension-set ID. Extensions cannot import themselves into closed profile syntax through ordinary library dependencies.

**External Lean sidecar:** treat third-party Lean macros/tactics/elaborators as *executable metaprograms* and run them with isolation appropriate to their trust and side effects. Their generated terms are still kernel checked. Builtins/foundation trusted surfaces are pinned, auditable and distinct from third-party logic.

WebAssembly component/WIT support is promising as a portable extension ABI, but **do not promise the entire Component Model as a finalized stable standard**. WIT defines typed imports/exports; feature support must be pinned to an actually deployed component runtime/toolchain. [Component Model design](https://github.com/WebAssembly/component-model); [WIT format](https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md). Core Wasm 3.0 is a separate specification, updated 2026-10-03: [W3C Core spec](https://www.w3.org/TR/wasm-core/).

### Extension manifest sketch (not a published contract)

```json
{
  "schemaVersion": 1,
  "extensionId": "@example/pscv-omega",
  "apiVersion": "psc-extension/1",
  "semanticClass": "E2",
  "executionClass": "U1",
  "entry": "dist/component.wasm",
  "witWorld": "example:pscv-tactic@1.0.0",
  "capabilities": [],
  "acceptedProfiles": ["pscv-v1"]
}
```

For E5, a closed-profile verified build must reject unless explicitly approved with independently validated source-fidelity evidence and declared semantic profile. No "trusted" boolean in untrusted npm metadata can self-authorize admission.

---

# 9. Four first-class backends, interop and target products

Keep **four first-class compiler backends**—TypeScript, direct JavaScript, Wasm and Rust—because each has independent ecosystem value:

| Backend | Principal output | Toolchain dependence | V6 obligations |
|---|---|---|---|
| TypeScript | TS module/source, optional JS/maps/declarations via pinned `tsc` | `tsc` only for downstream JS/transpilation | Source fidelity, explicit TS runtime mappings, declaration compatibility |
| Direct JS | ESM JS, `.d.ts` and maps where implemented | No `tsc` for JS emission | JsIR structural validation, stable runtime ABI, tracked debug origins |
| Wasm | Wasm Core validated modules and selected Canonical ABI/WIT adapters | Optional target runtime/host | Target validation, canonical bindings, exact memory/text behavior |
| Rust | Rust source and optional native/library artifacts via pinned `rustc`/Cargo | `rustc` only for requested native output | Rust type/representation correspondence, clear ownership/FFI semantics |

Do **not** add a fifth mandatory backend merely because Lean can compile `.ps` via source translation; Lean-native is an optional compatibility route. Future Python/PHP/Java/Go backends use descriptor/pass contracts and must not modify foundational Core.

Preserve V5.1 laws: typed ArtifactBundle (executable/API/debug/InterfaceIR/evidence), PublicApiIR derived from checked Core, source maps from OriginGraph, no automatic equivalence between target compile success and semantic preservation, no DDC implication from fixed points.

**External ABI:** WIT/canonical scalar/string/record contracts describe portable ABI, not logical proofs. Any FFI call used in a verified profile requires an explicit boundary model/assumption policy. WIT and native package metadata cannot mint semantic authority.

---

# 10. SAVEF and package-agnostic knowledge portability

SAVEF (ProofScript's Self-Amplifying Verified Ecosystem Factory) is an optional **factory and evidence-reuse system**. V6 gives it a clear job:

- Package verified source/interface/proof/evidence as versioned files within npm tarballs and portable archives.
- Index exact subjects, dependencies, checks, assumptions and permitted transformations using content-addressed descriptors.
- Reuse immutable generated proof targets and compile products across builds only after verifying current subject/profile/toolchain/resource identity.
- Allow output mirrors in npm, GitHub Releases, Cargo, PyPI, Maven, WIT/component packaging without mutating Core logical meaning.
- Permit independent offline verifier to reconstruct an evidence graph from canonical manifests and checkers.
- Prefer JSON/NDJSON + `.ps`/`.lean` text, `.wasm`, WIT, signatures and bounded binary artifacts as needed; **no requirement** to invent or adopt `.psenv` or `.psk`.
- Use `.olean` strictly as an optional Lean-side local compilation cache; it cannot substitute for a portable PSCV-certified proof receipt or required checker replay.

Keep AI/factory/caches out of the semantic compiler's trusted acceptance path; generated knowledge is a candidate until accepted by exact checkers.

---

# 11. Trust, soundness and artifact-release claims

V6 retains the independent trust partitions:

- **LogicalTCB:** meaning of Core, selected kernel/checker, admitted axioms and checked statement identity.
- **SourceFidelityTCB:** parser, elaborator, normative environment, translation and Lean bridge mappings.
- **ExecutableFidelityTCB:** erasure, specialization, backend lowering, runtime/ABI and target validation.
- **SecurityTCB:** extension isolation, tool execution, untrusted package resolution, integrity validation and resource budgets.
- **DistributionTCB:** release builder, platform binaries, package integrities and provenance; not proof authority.

ClaimSet must separately record: Parsed; Elaborated; AdmissionReady; KernelChecked; ApprovedSpecCovered; ProofObligationsClosed; PSCVCertified; RuntimeIRValidated; BackendIRValidated; PreservationVerified/Validated/Trusted; NativeBinaryPackaged; IndependentOfLeanToolchain; ReproducibleBuild; DiverseDDC; npmProvenanceRecorded. No boolean "verified" substitutes for this lattice.

**Build-time official Lean trust ≠ runtime PSKernel truth.** No silent equality between 4.34 bootstrap kernel behavior and 4.35 RC semantic reference. If program/proof matching crosses versions, validate or pin matching semantics, and report version-specific unsupported rules. Do not silently rebase the language semantic authority on whatever Lean executable is on PATH.

## 11.1 Source/target and logical safety conditions

- A successful `.proof.lean` proof is about its exact Lean declaration; to discharge a `.ps` obligation it needs a checked mapping to the PSCV subject and all relevant assumptions.
- A valid `.proof.ps` theorem cannot bypass the kernel or substitute runtime assertions for proofs.
- Verified effectful code requires frozen WP/frame/effect contracts and accepted noninterference/erasure obligations under PSCV's normative reference.
- Compiler passes/backends either carry formal preservation evidence, independently checkable translation validation or an explicitly declared remaining executable-fidelity TCB; no fabricated "fully proven" claim.
- Plugins/solvers may generate candidate proofs; none may issue a certificate outside AuthorityBroker's exact capability rules.
- Target-language UB/runtime differences, memory/word size, Unicode/text, exceptions, resource behavior and host calls remain separately audited.

## 11.2 Supply chain and publishing

Use npm trusted publishing via OIDC where available, publish from pinned public CI builds, and preserve provenance and hashes. npm publishing provenance indicates build/source origin, **not correctness or proof closure**. Do not use plaintext or long-lived write tokens where a suitable OIDC workflow exists. References: [npm trusted publishing and provenance](https://docs.npmjs.com/trusted-publishers/), [npm clean-install/lock behavior](https://docs.npmjs.com/cli/commands/npm-ci/).

Require package-name namespace governance, signing where supported, dependency integrity and lockfile review, no automatic native source builds in install scripts, exact binary/package byte matching and independent clean-machine execution. Repository permissions, branch protection and release approval are organizational controls, not logical theorems.

---

# 12. Implementation-language strategy: readable Lean now, `.ps` self-host later

V6 **does not require the main compiler development source to satisfy every historical PSC1 self-host portability restriction**. A dedicated **Lean-native implementation lane** may use Lean language features that improve maintainability, profiling and proof engineering: total ADTs, typed `Except`, controlled state/reader monads, `do`, local `let mut`, standard recursion and modular libraries.

Conditions:

1. Freeze and preserve `PSC1-selfhost-stable/1`, `PSC1-portable-selfhost/1` and their published historical fixed points as reference artifacts; no rewriting the stable seed in place.
2. A new Lean-native implementation lane must not modify the normative PSCV source grammar merely to use more Lean implementation conveniences.
3. Refactor by *architecture family* and data/pipeline invariants, not iterative single-test patches; compare exact checked Core, diagnostics policy and backend artifacts where applicable.
4. Separate host-only IO/compilation adapters from the pure semantic core; avoid importing all Lean Meta/Elab APIs into runtime PSCV by convenience.
5. Record formal proof obligations and trust boundaries while implementing; nonverified development is permitted, but a build claiming PSCV-certified status remains fail-closed.
6. Whole compiler self-host tests across TS/JS/Wasm/Rust continue as **independent optional evidence**, never a gate for the first native standalone release.
7. When later undertaking self-host, choose a readable `PSCV-selfhost-portable` implementation fragment by measured compiler closure, not by retroactively distorting V6's native reference compiler.

This is a strategic *priority change* from V5.1, **not** evidence that maintaining two forever-divergent compilers is desirable. Define a future reconciliation plan before claiming common semantic ownership.

---

# 13. Real repository inventory and implementation gaps

At the audited `pscv/v3-execution` HEAD:

| Feature | Evidence at exact source path | Current honest assessment |
|---|---|---|
| Native `psc` entry | [`lakefile.lean`](lakefile.lean), [`packages/cli/src/PscMain.lean`](packages/cli/src/PscMain.lean) | Lean native executable target exists; independent cross-platform release not evidenced |
| Existing npm workspaces | [`package.json`](package.json), [`packages/cli/package.json`](packages/cli/package.json), [`packages/compiler/package.json`](packages/compiler/package.json) | Internal `0.0.0-dev`, mostly `private: true`; stable public registry packages not evidenced |
| Four backends | `packages/backend-{ts,js,wasm,rust}`, `contracts/backends/BACKEND_REGISTRY_V3.json` | Significant implementations exist; full conformance/preservation not claimed |
| Checked composition | [`scripts/compiler-checked-service.mjs`](scripts/compiler-checked-service.mjs), `scripts/kernel-checked-session.mjs` | Live authority pattern exists in JS host; standalone native composition parity remains |
| Native bootstrap CLI | [`packages/cli/src/PsCli.lean`](packages/cli/src/PsCli.lean), [`host/src/Ps/Host/CompilerDriver.lean`](host/src/Ps/Host/CompilerDriver.lean) | Current `check` prepares/checks admissibility; not identical to production certified pipeline |
| Lean checked provider | [`lean-checked/lakefile.lean`](lean-checked/lakefile.lean), `packages/pskernel-lean/provider` | Narrow checker integration exists; not full optional `.lean` frontend/Mathlib sidecar |
| PSKernel Core | [`packages/pskernel-core/README.md`](packages/pskernel-core/README.md) | Separate native/portable checker with ongoing compatibility/metatheory; promotion not automatic |
| `.ps` proof support | Normative language reference, proof/kernel modules | Proof semantics specified; mixed proof-file binding/replay not established |
| `.lean` proof about `.ps` | Theory bridge contracts and Lean provider foundation | **No complete semantic-bridge evidence chain yet**; critical new V6 implementation |
| Locked npm-semantic package graph | Internal npm dependencies and V5 BuildAction contracts | New `proofscript.json`/semantic lock/resolver contracts and validation needed |
| Full Lean extension | Current bounded `ParseLean.lean` | Optional official Lean frontend packaging/invocation not yet established |
| Extension isolation | V5.1 E0–E6 model and host infrastructure | Final AuthorityBroker/execution-host acceptance pending |
| Release/provenance | TrustManifest/ClaimSet/artifact/archive infrastructure | Native npm/binary product assurance and platform CI pending |

[`AI_WORK_STATE.md`](AI_WORK_STATE.md) estimated approximately **60–70% compiler-side V5.1 implementation** at a specific checkpoint, explicitly excluding kernel work and final assurance; this is a historical planning estimate, **not** V6 implementation readiness. New V6 deployment, mixed-proof bridge and registry requirements introduce unmeasured work.

**Parallel workstream safety:** V6 is an architecture proposal. Do not edit PSKernel kernel/provider internals, defeq/cache implementation or kernel metatheory here. Kernel workstream independently owns implementation and promotion evidence. Preserve branch history and V5.1 evidence; do not mark V6 as master target until adopted through an explicit design migration.

---

# 14. Architecture acceptance and migration plan

The plan is intentionally staged so native distribution and independent proof work deliver value before self-host expansion.

| Stage | Engineering work | Hard acceptance criterion | Explicitly out of scope |
|---|---|---|---|
| V6-D0 | Ratify architecture and ownership; new contract IDs; capture baseline | Approved V6 decision record; V5.1 unchanged; cross-workstream no-overlap | Coding new kernel |
| V6-N1 | Standalone native `psc` bundle/CI | Clean-machine native bundle, correct dependency closure, no Lean/Lake/Node requirements, published native binary checks | Full `.lean` support |
| V6-N2 | Native checked-service parity | End-to-end real provider check, source/profile/handle identity, certified gating; reject bypass or provider mutation | Global proof-preservation theorem |
| V6-P1 | First-class `.proof.ps` separate proof roots | Exact obligation discovery/binding, mixed source/module imports, coverage and stale-proof rejection | Mathlib proof link |
| V6-L1 | Optional full Lean sidecar | Exact Lean version/Lake lock, isolated elaboration, real `.lean`/Mathlib check, no effect on default `.ps` CLI | Full Lean-to-four-backend translation |
| V6-B1 | Lean proof-to-PSCV bridge | Checked statement/environment/assumption relation; reject false bridge; replay exact proof subject | Claim automatic equivalence of source translations |
| V6-P2 | Mixed `.proof.ps` / `.proof.lean` certification | Both proof modes discharge chosen obligations in one project with complete PSCV certificate/coverage | Compiling arbitrary Lean code |
| V6-R1 | npm compiler + platform binaries | `npm ci --ignore-scripts`, verified binary selection/digests, native/Node-free parity, optional Lean not installed by default | Public release without provenance |
| V6-R2 | `.ps` library and proof npm packages | Deterministic module lookup, semantic lock, signed/hashed artifacts, stale/duplicate dependency rejection, offline replay | Dedicated registry |
| V6-E1 | Extension API / bounded host | E0/E1/E2/E3/E4 plugin contracts, declared capabilities, isolation, denied unauthorized authority | Full arbitrary E5 |
| V6-I1 | InterfaceIR, WIT/ABI and multi-target packaging | JS declarations, Wasm interfaces and Rust source consumers have exact checked bundle descriptors | Promise future backends |
| V6-A1 | Independent assurance/release | Target validators/preservation closure, logical assumptions, replayable receipts, resource budgets, provable release claims | Automatically infer proof from provenance |
| V6-S1 | Optional self-host / diverse DDC | Exact-source self-application and independent backend/bootstrap evidence with recorded closure and semantic claims | Block earlier stages on self-host |

## 14.1 Dependency graph and critical path

```text
V6-D0
  +--> V6-N1 --> V6-N2 --> V6-P1 --> V6-P2 --> V6-A1
  |                         |                 ^
  |                         +--> V6-L1 --> V6-B1
  +--> V6-R1 --> V6-R2 --> V6-E1 ---------+
  +--> V6-I1 ------------------------------+
  +--> V6-S1 (nonblocking, optional and separately budgeted)
```

A release called **standalone native PSCV compiler** need not wait for optional Lean or self-host, but it MUST pass the correct native checked-provider boundary for every checking claim it makes. A release called **mixed Lean/PSCV proof certified** must wait for V6-L1/B1/P2. A release called **fully verified compiler** requires evidence far beyond those release mechanics.

## 14.2 Conformance fixtures and negative cases

Assign stable test families (names proposed):

- `PSC-V6-NATIVE-*`: clean OS/arch install, no Lean or Node on PATH, runtime dependencies, missing platform binary, license and checksum audit.
- `PSC-V6-CLAIM-*`: legacy bootstrap `check` is not certified, reject missing kernel, wrong kernel ID, stale Certified handle and altered IR before emission.
- `PSC-V6-PROOF-*`: `.proof.ps` and `.proof.lean` successes; conflicting proof, false proposition, wrong import, changed source/spec, unapproved axiom/`sorry`, incompatible Lean package lock.
- `PSC-V6-BRIDGE-*`: prove same proposition from exact PSCV Core, mutated generated Lean module, changed frontend version, missing bridge theorem, model mismatch, effectful representation drift.
- `PSC-V6-NPM-*`: workspace/nested package duplicate identity, hash mismatch, offline replay, re-export, unexpected postinstall scripts, unsupported platform, npm integrity ≠ PSCV certificate.
- `PSC-V6-EXT-*`: install-not-enable, denied filesystem/network, unauthorized E5, resource exhaustion, proof producer unable to mint checks, validator rejects changed target output.
- `PSC-V6-BACKEND-*`: four target outputs, typed ArtifactBundle, target-specific validators, typed failures and runtime semantics.
- `PSC-V6-PROVENANCE-*`: package/artifact digest correspondence, trusted publishing identity, exact SBOM/license, provenance not read as logical proof.
- `PSC-V6-CACHE-*`: incremental identical subject reuse, transitive invalidation under profile/bridge/extension changes, no stale certified output.
- `PSC-V6-SELFHOST-*`: optional exact fixed-point and source closure, never confused with production native release claim.

A test pass is evidence for the precise fixture and build identity only. This matrix must later be expanded into file/function-level rules and independent oracle fixtures, not used as marketing language.

---

# 15. Detailed tradeoffs and evaluation

## 15.1 Comparable alternatives (qualitative design review)

| Criterion | A: Lean-built minimal runtime | B: Embed full Lean frontend in `psc` | C: Lean-built PSCV + optional Lean adapter (V6) |
|---|---|---|---|
| Fast initial standalone compiler | Excellent | Medium | Excellent |
| Minimal default runtime closure | Excellent | Lower | Excellent |
| Full Lean authoring/proof compatibility | Separate product needed | High | High **in optional mode** |
| `.ps` closed semantic determinism | High | Requires careful separation | High |
| Mathlib reuse for `.ps` proof | Via explicit bridge | Via explicit bridge | Via explicit bridge |
| Trust base visibility | High | Larger runtime TCB | High with named sidecar TCB |
| npm modular distribution | High | More bundled native weight | High |
| Four-backend neutrality | High | Possible but more coupling | High |
| Long-term maintenance | High | More tightly coupled to Lean releases | High if versioned bridge is maintained |
| Self-host dependency | None | None | None initially |

V6 selects **C**. The *hard cost* is the checked cross-language proof bridge; sidecar integration alone does not solve semantic correspondence. Packaging Lean tooling on demand has real download, storage, cross-platform and sandbox costs and must be benchmarked.

## 15.2 Assessment rubric (design coverage vs evidence)

Continue V5.1's criteria, but **do not fabricate an improved 99+ implementation score** merely by adding chapters.

| Criterion | V6 design provision | Missing empirical/assurance evidence |
|---|---|---|
| Soundness/fidelity | Immutable checked Core + proof bridge + fail-closed cert | Bridge correctness, preservation |
| TCB transparency | Lean-build/runtime/provider/extension partitions | Final authority inventory |
| Formal/metatheoretic verification | Lean implementation proof route, optional Lean proofs | Checked complete proofs of compiler transformations |
| Negative-input robustness | Explicit rejection matrix, isolated adapters | Broad differential test campaigns |
| Compatibility completeness | Bounded `.ps`; official Lean full `.lean` sidecar | Supported cross-compiler mapping matrix |
| Architecture | V5.1 semantic spine + release/package layers | Final native integration and packaging |
| Independent evidence | Cross-language/target evidence and replay | Diverse checkers and DDC |
| Performance | Minimal default runtime plus real measurement plan | Binary size/startup/memory benchmarks |
| Resource behavior | Budgeted providers/extensions/packages | Platform stress measurements |
| Portability | Native binaries + npm + WIT/ABI | Platform artifact coverage |
| Longevity | Version pins, separable adapters, semver + semantic locks | Upgrade simulation evidence |
| Interoperability | Lean proof sidecar, JS/TS, WIT, Rust, npm | Actual proof/ABI bridges |
| Self-host/bootstrap | Preserved historical closures, explicit optional lane | Fresh V6 self-host evidence (not gate) |
| Auditability | Typed ClaimSet, manifest/proof links, provenance | External audit |
| Security | No scripts/implicit extension authority, isolated runners | Isolation regression and supply chain campaign |
| Soundness security | Checked proposition subject/assumptions, no `sorry` shortcut | Independent negative proof corpus |
| Ecosystem/package UX | npm-first mixed `.ps`/`.lean` package shape | User study, naming, publishing rehearsal |
| SAVEF | Portable content-addressed evidence across registries | Independent offline proof replay |

**Evidence grading:** `specified` is not `implemented`; `implemented` is not `tested`; `tested` is not `formally proved`; `LeanAccepted` is not `PSCVCertified`; `npmPublished` is not `Reproducible`; `Reproducible` is not `DDC`. V5.1's **99.15/100** was its own self-assessed target-architecture score, not a release milestone. V6 claims architectural coverage but does not convert speculative rubric numbers into measured confidence. A numeric release-readiness score requires actual tests, sizes, platform builds, proof evidence and external review.

---

# 16. Product UX principles

**Default workflow** (proposed, not implemented):

```sh
npm install -D @proofscript/cli
npm install @example/safe-math
npx psc check src/Main.ps
npx psc build src/Main.ps --backend javascript
```

**Verified workflow** (proposed):

```sh
npx psc verify --profile pscv-v1
npx psc build src/Main.ps --backend wasm --verified
```

**Optional Lean proof authoring** (proposed; installed only when selected):

```sh
npm install -D @proofscript/lean
npx psc lean check proof/Arithmetic.proof.lean
npx psc verify --profile pscv-v1
```

**Without npm** (native release, same semantic compiler):

```sh
psc check src/Main.ps
psc build src/Main.ps --backend rust
```

The CLI must distinguish `check` (syntax/type/kernel?), `verify` (PSCV obligations/certification) and `build` (artifact emission) explicitly. Avoid current ambiguity where a bootstrap `check` result might be mistaken for a kernel-checked certification claim. Named output products must state `plain`, `checked`, `certified`, `preservation-validated` or `trusted-backend` accurately.

**Proof discoverability:** default convention `proof/<Module>.proof.ps` and `proof/<Module>.proof.lean`; manifests can override discovery and map multiple proofs across module/requirement IDs. Proof roots do not implicitly execute in the runtime image, and bundling `.lean` files never silently enables the Lean elaborator.

---

# 17. Source-backed research and references

Repository sources (audited branch; some documents explicitly predate current HEAD):

1. [V5.1 compiler architecture](THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md) — semantic spine, extension model, backends, claim lattice, migration and explicit target-score meaning.
2. [Normative PSCV language reference](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) — closed `pscv-v1`, bounded Lean syntax, `PSCV-VERIFY-v1`, `PSCV-CERT-v1`, specification and proof closure, semantic version pins and **PENDING** Standard manifest digest.
3. [Current architecture and bootstrap profile](ARCHITECTURE.md) — current `psc2-compiler-v1`, stable self-host source and Lean bootstrap identity.
4. [Current work-state checkpoint](AI_WORK_STATE.md) — V5.1 implementation gates, honest gaps and CI identifiers; read again before implementation.
5. [Native Lake targets](lakefile.lean), [native CLI source](packages/cli/src/PsCli.lean), [production JS checked service](scripts/compiler-checked-service.mjs).
6. [PSKernel Core ownership/status](packages/pskernel-core/README.md), [Lean-checked host boundary](host/src/Ps/Host/LeanChecked.lean), [backend registry](contracts/backends/BACKEND_REGISTRY_V3.json).
7. [Existing npm workspaces](package.json), [CLI npm bootstrap package](packages/cli/package.json), [compiler npm package](packages/compiler/package.json).
8. [Portable self-host study at repository root](../PSCV_SELFHOST_PORTABLE.md) — valuable future implementation fragment; does not force immediate native compiler source restrictions.

External primary references (accessed 2026-10-08):

9. [Lean 4 elaboration and compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/) — command-by-command parser/elab changes, core/kernel check and initialization.
10. [Lean Lake build tools](https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/) — native executables, build products, manifest/lock and dependency rules.
11. [Lean IO model](https://lean-lang.org/doc/reference/latest/IO/) — effect distinction and runtime nature.
12. [Lean 4 repository initializers](https://github.com/leanprover/lean4/blob/master/stage0/src/initialize/init.cpp) — initialization/import-closure limitations relevant to size.
13. [npm package manifest](https://docs.npmjs.com/files/package.json/) — platform restrictions, binaries and dependencies.
14. [npm clean-install and scripts](https://docs.npmjs.com/cli/commands/npm-ci/) — lockfile reproducibility boundaries and install-script policy.
15. [npm trusted publishing](https://docs.npmjs.com/trusted-publishers/) — CI/OIDC provenance and its limitations.
16. [Wasm Core 3.0 specification](https://www.w3.org/TR/wasm-core/) — target validation baseline at date of writing.
17. [WebAssembly Component Model](https://github.com/WebAssembly/component-model), [WIT format](https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md) — portable interface types and implementation maturity.

External references describe **upstream capabilities and constraints**; they do not establish that the PSCV implementation already meets the V6 requirements.

---

# 18. Final decision and promotion rule

**Adopt the following target, conditional on design review and explicit migration approval:**

> **PSCV V6 is a Lean-built but standalone native ProofScript compiler that keeps `.ps` small and semantically closed; checks mandatory proofs written in `.ps` and/or `.lean` through explicit checked semantic correspondence; treats full Lean as an optional pinned external frontend; distributes itself, libraries, proofs and extensions primarily through npm and secondarily through native binaries and other registries; preserves all four target backends; and defers self-hosting without relaxing verified-executable acceptance.**

The first deliverable is **working independently packaged native `psc` with correct checked-service authority and four target source/codegen paths**. The second major capability is **replayable mixed-language proof linkage**. The third is **npm-first verified package resolution and isolated extensions**. Full self-host/diverse bootstrap and deep formal assurance remain separate, explicitly tracked workstreams.

**Promotion checklist:**
- V6 architecture peer-reviewed against the normative PSCV language and V5.1 retained invariants.
- Explicit decision to migrate `AI_WORK_STATE.md` master target from V5.1 to V6; do not alter it simply because this document exists.
- V6 contract/interface IDs versioned and ownership assigned without touching kernel internals.
- Native checked-service transition plan validated before advertising certified `psc`.
- No release-readiness or formal-soundness claims until corresponding executable fixtures and proof/evidence checks pass.

**Status at document creation:** Architecture research and proposal only; no code migration, package publication, native binary-size benchmarking, cross-language bridge proof or independent V6 conformance testing performed by writing this reference.
