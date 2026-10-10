# PSC0 — Sound, Secure, Small, Self-Hosting & Extensible Compiler Architecture

**Status:** normative *target architecture / migration contract*, **not** an implementation-complete or soundness-certified release.  
**Document version:** `PSC0-ARCH/1` · **Review date:** 2026-10-11 · **Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel).  
**Frozen evaluated npm source:** `psc0/npm-modular-packages-v1` at [`2f42a52814f3`](https://github.com/dwijayuda/pskernel/tree/2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a/psc0).  
**Separate kernel research:** `psc0/pskernel-core-lean435-arena-v1`, verified proof source [`902f902b`](https://github.com/dwijayuda/pskernel/commit/902f902b96361a8b14943b02bef503671893b3c0), [focused CI 38076656535](https://github.com/dwijayuda/pskernel/actions/runs/38076656535). This proof work is **not** implicitly incorporated into the frozen npm binary.  
**Implementation authority:** executable source, actual dependency graph and qualified run receipts always prevail over aspirational text; this document governs *new work* and is not a license to relabel an old build.

## 0. Decision in one page

**Build one small, host-owned, fail-closed path from immutable sources through independently checked canonical terms to an immutable artifact.** Let normal npm libraries supply *source*, tactics and syntax guests supply *proposals*, and executable backends supply *output candidates*. None of them may manufacture checked authority, change kernel rules, suppress assumptions or publish verified artifacts by itself.

1. **Keep the existing 12-source-package PSC0 self-host compiler closure plus the PSKernel Core runtime.** The current npm packages are mostly source-ownership boundaries with façades over one compiled JavaScript runtime, **not** independently self-hosted packages. Do not split the runtime until doing so preserves its actual fixed point; after a clean installed-package fixed point, consider a smaller default *binary* dependency set while retaining 12 source packages as optional development/rebuild packages.
2. **Unify `npm-cli/psc.js` and the stronger `scripts/checked-prepared-session.mjs` contract** behind a single host-owned build service. A checked handle has host-controlled construction and life cycle; a JSON receipt, TypeScript type assertion or third-party JS object is never proof authority.
3. **JS PSKernel Core is the requested default for the new npm CLI**; no Lean-WASM fallback after rejection or failure. It is **only boundedly qualified**, not proved sound. The separate Lean-WASM/native/Lean 4 oracles remain opt-in comparison and CI assurance components.
4. **Separate four statements rigorously:** (A) kernel accepted a declaration relative to assumptions; (B) policy covered its specifications/effects/assumptions; (C) generated code preserves required semantics; (D) released binary has authenticated source/build provenance. Evidence for one does not imply the others.
5. **Use explicit stable data protocols and OS isolation before executable third-party plugins.** Libraries are source-only by default; tactics/syntax emit untrusted AST/Core proposals; backends accept host-validated IR; no guest receives mutable checking state, release credentials or a method for creating a `CheckedCore` token.

**Non-goals of this design document:** reimplement PSKernel, fork Lean or tsc, immediately implement full PSCV, promise that JS output is formally verified today, mandate Wasm for simple source libraries, silently activate old plugins, rename every package again, or restart already qualified source work.

## 1. What the inspected code actually establishes

| Grounded checkpoint | Established | Explicitly not established |
| --- | --- | --- |
| `psc0/docs/selfhost-language/CURRENT.md` strict SH/1 | Bounded source/language conformance, C2/C3 fixed-point evidence, and separately accepted pinned admission streams on exact qualified source | Current installed npm closure's independently reproduced fixed point; full PSCV grammar |
| `psc0/packages/pskernel-core` (79-module root `Ps.KernelCore.SelfHost`) | One source-owned semantic rule implementation; checked API; 34 Lean-4.34 rule inventory entries, 33 direct-differential, one direct invariant; M3/M4 limited performance and provider evidence | Full formal kernel soundness, universal Lean compatibility, cache/backend refinement |
| `psc0/npm-runtime/core-checker.mjs` | Separate Node checker process, fixed files' SHA-256 checks, 16 MiB input, 512 MiB configured V8 old space, timeout and provider identity check; no automatic checker fallback | OS-level sandbox, total-process RSS guarantee, signed executable authority, arbitrary stream soundness |
| `psc0/scripts/npm-core-qualification.mjs` | Exactly **five** JS/Lean-WASM comparisons: four accepted, one rejected in last green npm CI | Comprehensive negative corpus, inductive/metatheory proof or complete JS kernel equivalence |
| `psc0/npm-cli/psc.js` | `check` and `build` call JS Core before emitting TS; uses pinned TypeScript 7.0.2; staged output; Linux and Windows x64 installation tests | Session-local accepted-graph token, exact re-encoding before emit, complete filesystem transaction or JS semantic preservation |
| `psc0/npm-cli/libraries.mjs` | Declared npm source library resolution, reserved namespaces, installed package metadata and realpath containment; no guest JS imported through normal source lookup | Safety of arbitrary npm lifecycle scripts, arbitrary in-process JavaScript, hostile guest isolation |
| `psc0/scripts/npm-distribution.mjs` | Complete PS/Lean source-edition npm tarballs, **13 required** core packages; seven optional modules absent from default installation; third-party source library canary | Independent runtime implementation in most scoped façades, complete `.ps` translation, optional backends' correctness |
| npm CI [38075437516](https://github.com/dwijayuda/pskernel/actions/runs/38075437516) | Successful compiler/kernel JS emission, Linux and Windows x64 CLI smoke, five-case parity, npm install | Installed JS compiler reproducing itself with multiple independent generations |
| Workspace CI [38075437553](https://github.com/dwijayuda/pskernel/actions/runs/38075437553) | **Failed** with missing legacy `proofscript.sourceRoots` metadata in package declarations | All workspace/source-contract checks passing |
| New Lean 4.35 model proof [38076656535](https://github.com/dwijayuda/pskernel/actions/runs/38076656535) | Checked actual empty-environment model and conditional no-stored-`False` and reference constant-arity lemmas; 269 jobs, 334 audited declarations, 84 companion files | Actual all-declaration admission preserves model, complete infer/WHNF/DefEq soundness, full public relative consistency, or refinement of shipped 4.34 JS |

**Version fence:** the packaged npm kernel targets **Lean 4.34.0**. The distinct proof branch targets **Lean 4.35.0-rc4**. Lean 4.35 removes the `Lean.reduceBool`/`Lean.reduceNat` native kernel mechanism; do not transplant 4.35 theorems/behavior into 4.34 shipping artifacts or vice versa without a versioned semantic mapping and full requalification. See [Lean 4.35 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/).

**Historical TCB discrepancy:** `psc0/scripts/checked-kernel-provider.mjs` still defaults to `lean434-wasm` and selects a *legacy owned kernel* for `pskernel-core`, whereas new `npm-cli/psc.js` directly selects the newer `@proofscript/pskernel-core/check`. Treat these as **two existing application paths**, not one fully unified authority. P1 below removes this divergence without pretending the two kernels are identical.

## 2. Proof, program, and release claims

The compiler SHALL label claims independently in the output receipt:

- **Kernel-admitted:** canonical declarations accepted by the *explicitly selected and pinned* kernel, relative to named assumptions, imported constants and a specific environment. Does not assert those assumptions are consistent or that the implementation is itself proved correct.
- **Policy-verified:** verified profile's mandatory contracts, effects, axiom/assumption allowlist, coverage and erasure obligations are closed. In current PSC0 only a deliberately bounded development profile can be declared; no full-PSCV claim without separate evidence.
- **Semantics-qualified executable:** backend/runtime combination has the required target-specific correspondence assurance for the statement being made. Ordinary `tsc` successful type checking is **not** a proof of preservation.
- **Released / reproducible:** exact source closure, npm dependencies, compiler and kernel IDs, target compiler binary, environment and output digests match an authenticated and separately verified release provenance. A hash manifest packaged next to code alone does not authenticate that code.
- **Formally sound / consistent:** *only* once executable checker success has the requisite independently checked model theorem, with explicit mathematical and axiom premises, and runtime/backends are separately refined where claimed.

Profiles SHALL be explicit: `ps-standard` (ordinary bounded compilation), `pscv-verified` (mandatory verified policy, only when implemented/qualified), and optionally `assurance-experimental` (research comparison, **never a verified release alias**). Names are proposed future protocol labels, not currently shipped profile switches.

**Assumptions are not inherently defects:** Lean-compatible admission may accept `axiom impossible : False` as an *assumption*. This is different from deriving `False` without unmodeled assumptions. A verified policy MAY decline unmodeled axioms, but normal Lean-fidelity mode must not covertly adopt the same rejection semantics. Version the `False` primitive and permitted mathematical basis.

## 3. Logical and execution architecture

```text
                   Third-party npm source libraries      User .ps / allowed .lean
                                |                              |
                                +-----------+------------------+
                                            |
                        Frozen, digest-addressed source graph
                  (realpaths, content, pinning, imports, versions)
                                            |
       Syntax/tactic guests --untrusted proposal data--> Parser / Elaborator
             [isolated OS/Wasm]                 |               |
                                                v               |
                                       Prepared canonical terms |
                                                |               |
                                                v               |
                                     Canonical admission bytes  |
                                                |               |
                                                v               |
                          +-----------------------------+       |
                          | Selected PSKernel Core      |       |
                          | independent checking        |       |
                          | explicit axioms, environment|       |
                          +-----------------------------+       |
                                      | accepted                |
                                      v                         |
                 +------------------------------------------+   |
                 | TRUSTED HOST CHECKED-SESSION OWNER       |<--+
                 | sealed identity + immutable prepared    |
                 | graph + re-encoded admission equivalence |
                 +------------------------------------------+
                                      |
                            original-IR validation
                                      |
                           erasure / effect/contract gate
                                      |
                             host-owned checked IR
                                      |
                     +----------------+------------------+
                     |                |                  |
                    TS/JS            Wasm               Rust
                boot backend      opt-in guest       opt-in guest
                     |                |                  |
                     +----------------+------------------+
                                      |
                      emitted candidate in private staging
                                      |
                 runtime semantics / target obligations /
                  post-emit input-and-identity revalidation
                                      |
                           atomic-release discipline
                                      |
                 artifact + claims + untrusted audit receipt
                 + authenticated provenance from CI builder
```

**Only the selected kernel decides canonical logical acceptance.** The host owns checking order, mandatory obligations, source graph, policies and artifact publication. A backend's output is not allowed to assert a higher level of proof assurance than the input evidence supports.

The host does not need to contain the entire elaborator. Untrusted syntax/tactic execution may run outside it as long as proposals are decoded by the host and actual terms are kernel checked. *Trusted compilation orchestration* and *small logical TCB* are different boundaries.

### 3.1 Explicit TCB ledger (normative)

| Class | Included in trust for the corresponding claim | Mitigation / qualification |
| --- | --- | --- |
| Logical semantic checker | PSKernel Core rules, public admission API, initial prelude/primitive definitions and admitted-axiom policy | Prove reference-mode public successful admission preserves model; audit axioms |
| Semantic acceleration | DefEq/inference caches and indexed environment lookup **if enabled** | Prove cached/reference accepted-direction equivalence; compare negative and positive corpora |
| Trusted capabilities | Any native reduction oracle, primitive FFI or injected evaluator that can influence defeq | Disable unless explicitly versioned and justified; don't call it an optimization outside TCB |
| JS execution | Generated kernel JS, JS runtime, compiler/backend producing its JS, decoder and subprocess adapter | Independent JS-vs-reference checks, compiler/backends' semantic refinement; hash/sign provenance |
| Checked host | Source snapshot, provider selection, checked-token constructor, file validation and release transaction | Small auditable API with focused negative tests; no untrusted in-process plugin hooks |
| Executable fidelity | Erasure, typed IR, target lowering, TypeScript, emitted runtime and target ABI | Formal simulation where possible; translation validation and differential tests until then |
| Distribution | npm tarballs, installed binaries, optional native TS platform packages, CI builder | Versioned lockfile, signed provenance, reproducible release, install-script policy |
| Outside TCB by design | Source libraries, syntax/tactic guest algorithms, formatters, LSP, normal backend *proposals* | Accept **data only**, never delegate checking or granting proof/release authority |

**A malicious compiler/host process is not contained by an in-memory `WeakMap`.** An opaque token is useful against API misuse, not a hostile same-process participant. Guest process isolation and release-host control are required for the stronger threat model. The OS, hardware and npm installer remain residual trusted assumptions.

## 4. Mandatory safety invariants

Use `MUST` for obligations required to grant a new release claim; `SHOULD` for targets requiring separate cost justification.

- **INV-01 / authority:** Every checked term is accepted by exactly one host-selected kernel identity. No guest, config, serializable object, receipt or backend can set `accepted=true` as authority.
- **INV-02 / complete closure:** Record and freeze every transitive source and npm resolution input *before* checking. No change to import graph, package contents, snapshot identity, trusted prelude or policy between check and emission.
- **INV-03 / same object:** Erasure receives the same host-retained prepared declarations whose canonical encodings were accepted. At emit time, recompute admissions, compare accepted bytes/digest *and* the snapshot binding. Require no post-acceptance mutation.
- **INV-04 / no failure promotion:** Kernel reject, unsupported feature, resource exhaustion, timeout, bad JSON, identity mismatch, missing source, guest crash, open obligations, unsafe erasure, codegen failure or input drift → **no new executable artifact**. Never substitute Lean-WASM or a different checker automatically.
- **INV-05 / independent claims:** A `typechecked by TS` result cannot mint `semantics-preserved` or `formally verified` status. Evidence level is monotone and cannot be raised by plugins or UI labels.
- **INV-06 / assumption accounting:** The actual axiom/opaque/unsafe/partial basis, transitive dependency closure and versioned policy travel with the checked artifact. New user axioms are never silently relabeled as proved theorems.
- **INV-07 / extension purity of authority:** No guest gets a mutable kernel environment, unchecked session constructor, release write path, host credentials or `markChecked` operation. No install-time code runs as part of *checking* a source library.
- **INV-08 / output ownership:** Stage in a private directory, validate destination, reject symlink/junction escape and output collision, and publish with crash-consistent discipline. A multi-file publish is not atomic just because each rename is atomic.
- **INV-09 / resources:** Bound source bytes, declaration count, import depth, recursion, emitted size, wall time, aggregate CPU/memory and guest output; exhaustion always declines without unchecked success.
- **INV-10 / cache safety:** A cache or red/green query hit must not skip mandatory logical admission after relevant kernel/prelude/environment/policy changes. Cache identity includes all semantically relevant inputs.
- **INV-11 / reproducibility:** Every source-to-binary step records exact toolchain and kernel version pins; build provenance binds the *output subject digest* and source commit. A release without independently verified provenance can claim only bounded development status.
- **INV-12 / explicit disclosure:** Host-controlled diagnostics and release metadata enumerate which third-party extensions executed, their exact digests and granted capabilities. A guest cannot suppress or alter this log.

**Negative-contract rule:** Every invariant must have at least one CI test where its antecedent is deliberately violated and emission is refused. Passing negative tests shows bounded enforcement, *not* a mathematical theorem about all inputs.

## 5. One checked-build state machine

Define the **one** service behind both `psc check` and `psc build`:

```text
OPEN
  -> SNAPSHOTTED
  -> ELABORATED (untrusted proposals normalized)
  -> ADMISSION_PREPARED
  -> KERNEL_ACCEPTED (selected checker; no fallback)
  -> CHECKED_CORE (host-only ephemeral handle)
  -> IR_VALIDATED
  -> ERASED_WITH_POLICY
  -> OUTPUT_STAGED
  -> OUTPUT_QUALIFIED (where applicable)
  -> COMMITTED + AUDIT_RECEIPT
                           \-> FAILED/DECLINED: zero new executable artifacts
```

**Definition `CheckedBuildAuthority/1`:** a host-owned ephemeral capability to continue a particular accepted build; it is *not* a serializable proof credential. Authorized continuation is bound to (a) immutable source closure; (b) exact canonical admission stream; (c) kernel/prelude/target and environment digests; (d) build policy and assumption/effect ledger; (e) host process session; (f) optional accepted source IR. The host must verify them on every trust-boundary transition.

Conceptual TypeScript interface (design specification, **not shipped code**):

```ts
type SourceSnapshot = Readonly<{
  sourceClosureSha256: string; importGraphSha256: string;
  sourceKind: "ps" | "lean"; packageLockSha256: string;
  policySha256: string; semanticVersion: string;
}>;

interface CheckedBuildService {
  check(snapshot: SourceSnapshot, entry: string):
    Promise<{ kind: "declined"; code: string } |
            { kind: "checked"; handle: unknown; audit: CheckedAudit }>;
  emit(handle: unknown, target: "ts" | "js" | "wasm" | "rust"):
    Promise<{ kind: "declined"; code: string } |
            { kind: "candidate"; stagingId: string; claims: ClaimSet }>;
  commit(stagingId: string): Promise<CommitResult>;
}
// The real handle is created only inside the trusted service.
// Guest callers never construct it, and a receipt cannot replace it.
```

Construction uses a private host registry (e.g. retained immutable state + `WeakMap` for same-process clients). This **prevents accidental or untrusted API-level minting only**; hostile guest code must remain outside that process. Do not put an `admitted` boolean in `VerifiedIR`, accept a caller-supplied prelude, trust a saved `*.checked.json` as capability, or allow user-configured provider binaries in verified release mode.

Use the existing `scripts/checked-prepared-session.mjs` as the starting point, preserving its freeze, session-local handle and re-encode-before-emission checks. Do **not** copy two competing definitions into the npm CLI. Move the authoritative service to a minimal host module, make `npm-cli/psc.js` a façade, and retain backwards-facing adapters only if their equivalence is tested.

### 5.1 Binding and hashes

Canonicalize source closure order and metadata deterministically. Bind content and path (case-normalized for target OS), package IDs and versions, resolved package *integrity* digests, import graph, allowed axioms, prelude, profile, checker identity and compiler identity. If hashing JSON across independent languages, define a **versioned deterministic encoding**; do not assume default JS `JSON.stringify` is a universal canonical encoding.

Use domain-separated digests, e.g. `SHA256("PSC0/SNAPSHOT/1\0" || canonicalBytes)`. Avoid treating an output's own self-declared digest as attestation. Do not sign private checked handles; separately sign or attest **audit evidence** after release.

At commit time, validate destination and source fingerprints again. A successful kernel decision with changed source is invalid for the new snapshot and must be retried as a new checking transaction, never silently reused.

### 5.2 Crash consistency and failure semantics

Write candidates only under the host-owned staging root. For a single output, use filesystem-safe rename after verification. For multiple outputs and receipts, prefer versioned content-addressed directories plus **one atomic manifest/pointer switch** in the same filesystem, rather than multiple uncoordinated renames. A failure retains the previously committed generation and reports the new failure; no partial new generation becomes current. Do not assume filesystem transactions span volumes or Windows/Linux semantics identically: test both.

## 6. Extension architecture: powers, never proof authority

There are two different classes of extensibility:

**Libraries** are data: `.ps`/`.lean` modules installed as npm packages, read as text, compiled inside the usual checked source closure. A namespace-to-package mapping is explicit in root `package.json`. Existing `npm-cli/libraries.mjs` is the seed implementation. It does not grant executable hooks.

**Executable extensions** run outside the trusted host as process-isolated/Wasm guests, proposed for a later phase. Installation via npm is only distribution; it does **not** itself authorize execution.

| Extension category | Input → output | Default grants | Must never be able to do |
| --- | --- | --- | --- |
| `ps-library/1` | Source graph → ordinary declarations | Source reads only | Set kernel state, run lifecycle scripts through parser, import trusted `Ps` namespace |
| `ps-syntax/1` | Syntax/context snapshot → AST proposal | No fs/network/clock unless explicitly granted | Directly admit a theorem or mutate host parser policy |
| `ps-tactic/1` | Goal and environment projection → untrusted proof-term proposal | Pure CPU/memory/fuel | Mark goals solved without kernel acceptance; import arbitrary host JS |
| `ps-derive/1` | Declared type → declarations/proofs | Read-only projections | Add axioms silently or bypass coverage policy |
| `ps-backend/1` | Host-validated IR → candidate bytes + metadata | One isolated output sink | Issue `CheckedCore` or publish a verified release |
| `ps-command/1` | Command arguments → explicit host requests | Named command capability | Replace `psc build` verification with unchecked emission |
| `ps-lsp/1` | Project snapshot → diagnostics/suggestions | Read-only snapshot | Become a compile-time proof authority |

Executable guest loading SHALL require an explicit root-project allowlist (`package@integrity`, allowed capabilities, protocol version, and trust disclosure) and a digest-locked binary. No automatic discovery that executes arbitrary `node_modules` JS; do not use `require`/`import` for untrusted guest entry points inside the trusted host.

### 6.1 Proposed guest ABI

Start with a small JSON-length-framed `PSC0-EXT/1` protocol over OS pipes for the cheapest MVP. A **WIT/Wasm Component Model** ABI is a later alternative for portable, narrowly imported capabilities; WIT specifies imported/exported interfaces but does not prove guest code correct. Keep the same semantic message schema across transports.

```text
Host -> Guest: { protocol, extensionIdentity, invocationId,
                 capabilities, budgets, immutableInputDigest,
                 proposalRequest }
Guest -> Host: { protocol, invocationId, immutableInputDigest,
                 proposal: {kind, bytes, formatVersion}, diagnostics }
Host: decode with limits -> validate ownership -> check Core/proof
      -> record execution identity -> continue or decline
```

Requests are length-limited and schema-validated; unknown message versions, duplicate request IDs, mismatched input hashes, malformed UTF-8, nondeterministic response claims, exceeded budgets and unsolicited host operations decline. Process environment, filesystem and network are denied by default using an **actual OS sandbox** or a capability-configured Wasm runtime, not solely Node's `--permission` option (documented as *not* a security boundary against intentional same-process misuse).

**Critical nuance:** a guest can propose an intentionally unsafe runtime algorithm. Kernel admission of associated proof terms does not make its emitted backend program faithful. Backend certification remains separate.

### 6.2 npm integration, stdlib and hooks

- Keep `proofscript` minimal; the current npm release bundles 13 scoped packages (12 compiler source-ownership modules + kernel runtime). The other seven scoped packages, including source-only `@proofscript/stdlib` and alternative native/Wasm providers, remain independently installable. Don't add every backend to `proofscript.dependencies`.
- A *future binary-only root reduction* to `@proofscript/compiler` + `@proofscript/pskernel-core` + TS toolchain is conditioned on installed-package self-host reproduction and exact source-dependency reconstruction. It is **not** mandated now.
- Libraries declare `proofscript.library.modulePrefix` and `sourceRoot`. Their source data are read with realpath containment and source-size budgets; no guest runtime is needed for ordinary imports.
- `@proofscript/stdlib` is an optional, versioned source library, *not* a kernel primitive authority. The admitted prelude/minimal intrinsic definitions remain under host/kernel semantic versioning even when a library shares textual names.
- npm package lifecycle scripts may execute during installation. `psc` cannot retroactively sandbox an earlier `npm install`; recommend locked releases, explicit install-script approval or `--ignore-scripts` where supported, and never tell users that “safe library import” makes third-party npm installation safe.
- Pin `typescript@7.0.2`; npm resolves the matching OS/CPU package. Don't bundle Linux's TypeScript native executable in a Windows release. Platform support is evidence-based, not assumed from JavaScript's nominal portability.

## 7. Runtime semantics and backend contract

A proof-bearing source program passes through semantic compilation and an execution backend. **Logical acceptance and executable semantics are separate obligations.**

1. The backend-neutral frontend produces one typed semantic IR with deterministic, versioned serialization.
2. `Erasure` must document proof irrelevance, representation of `Nat`/`Int`/machine integers/`Float`/`String`/`Char`, closures, ADTs, recursion, partiality and exceptions/effects under a named `RuntimeSemantics` snapshot.
3. The validator checks typing, well-formedness, resource policy, effect contracts, erasure constraints and exact input identity. Validation is not a proof that backend semantics match the source.
4. Each backend declares its target ABI (Node `ES2022`+TypeScript 7, Wasm, Rust, other future targets), limitations, required runtime dependencies and *qualified claims*. A backend cannot upgrade the checked status.
5. For a verified executable, require a semantics-preservation proof chain or explicitly qualified per-module translation validation. Until proved, label outputs as `kernel-checked source; target behavior empirically tested`—not “fully verified executable”.
6. FFI effects are always explicit: foreign code may break application-level properties unless those effects/assumptions are modeled or wrapped in verified contracts. No backend is trusted to erase a remaining verified obligation.

**Recommended staged approach:** first qualify TS/JS erasure and checked IR on the actual bootstrap subset. Keep direct JS, Wasm and Rust optional and behind the same IR serialization. Do not require full backends just to make the kernel sound. The verified-compilation paradigm of [CompCert](https://compcert.org/man/manual001.html) motivates the *behavior-preservation statement*, not an inference that PSC0 has already established it.

## 8. Kernel proof and axiom assurance track (separate owner)

The active kernel research uses proof-guided co-design on **one production checking algorithm**, with a cache-disabled reference specialization (not an independent sound checker). The desired theorem is:

```text
Given:
  - set-theoretic foundation assumptions V,
  - a pinned, modeled initial environment and logical primitives,
  - explicit modeled-axiom/unsafe/partial policy,
  - actual successful public checking/admission of a complete declaration stream,
Then:
  - the resulting environment has a valid semantic interpretation,
  - every accepted derived theorem denotes an inhabitant of its interpreted type,
  - no derived theorem of modeled empty False exists.
```

Do not state “the kernel rejects any axiom of False”: normal Lean-compatible checking permits assumptions. Distinguish a `verified-model` policy from a `lean-compatible` policy with observable, versioned decline rules.

**Proof phases (exactly sequenced; no shortcuts):**

- **K0:** Pin Lean version and primitive/axiom/`False` basis; model actual successful *public* empty session and its prelude, not a hand-constructed ideal context. Empty history model is a completed **fragment** on the newer proof branch.
- **K1:** Connect concrete reference checked inference, WHNF and defeq, including binder opening, universe-zero annotations, substitutions, proof irrelevance and every shortcut, through one accepting-direction recursion invariant. No “every type inhabits Sort 0” vacuous legacy judgment.
- **K2:** Prove actual admitted safe definitions, theorems, opaques, ordinary/mutual/nested inductives and recursors, quotient and primitive/native policies preserve the environment model; carry transaction boundaries.
- **K3:** Compose public-session acceptance → model → relative no-derived-`False` corollary with honest permitted-axiom premises; audit proof dependencies and absence of admitted shortcut axioms.
- **K4:** Prove or independently qualify cached-mode acceptance refinement to the reference specialization, then generated JS acceptance refinement (including JS runtime, marshalling and checker adapter). Native/Wasm shipping variants separately.
- **K5:** Strengthen Lean compatibility with finite differential corpora (malformed-input rejection and accepted programs) and named target-version migration. A passing corpus is evidence, not a replacement for K1–K4.

Until K0–K4 have reached their specific conclusion, **`soundnessProved`, `relativeConsistencyProved` and `jsRefinementProved` MUST be false** in automatically generated release evidence. Do not hide incomplete steps with an assumed theorem about the checker itself. PSKernel's cache can influence acceptance if incorrect, and any Lean-4.34 native reduction capability that influences acceptance extends TCB.

**Independent comparison strategy:** official Lean checker pinned by version, Con Leche's *external checker and model-theory research* (do not import its proof of a different algorithm as PSKernel proof), malformed-input suites, second-runtime tests, and source-level proof audit. The newer 4.35 branch's proof success must not silently promote old 4.34 npm binaries.

## 9. Source/package graph and self-hosting

### 9.1 Preserve current repository layout initially

| Current path | Target role | Migration rule |
| --- | --- | --- |
| `packages/foundation`, `syntax`, `core`, `environment`, `meta`, `elab` | Compiler semantic frontend | Preserve source and packages; define ABI/contracts without mandatory renaming |
| `packages/bridge`, `compiler-ir`, `erasure`, `compiler` | Canonical admissions + IR | Place one host-checked service over the code; no independent bypass |
| `packages/backend-ts`, `bootstrap` | One required self-host executable backend/root | Preserve TS7 bootstrap; pin original production source closure |
| `packages/pskernel-core` | Independent proof checking | Sole default npm proof authority; separate formal proof ownership |
| `npm-cli/psc.js`, `npm-runtime/*` | Thin checked host and kernel adapter | Reuse `checked-prepared-session`; reduce duplicated logic |
| `scripts/checked-*`, `host`, `lean-checked` | Existing checked/session/native seed utilities | Reconcile as one API; preserve historical Lean provider paths for qualification |
| `packages/backend-js`, `backend-rust`, `backend-wasm` | Optional backends | Real independent implementations after ABI/fidelity acceptance, not generic re-export façades |
| `packages/pskernel-lean{,-wasm}` | Explicit oracle/alternative providers | Never automatic fallback in requested npm default |
| `packages/stdlib` and `stdlib/ProofScript` | Optional external/source stdlib; private authoring | Keep authoring/publishing package names distinct; source imports only |
| `legacy` and historical receipts | Reproduction/archive | Keep immutable, exclude from default published/runtime authority |

**Fix existing workspace check before expanding package refactors:** [run 38075437553](https://github.com/dwijayuda/pskernel/actions/runs/38075437553) failed `PSC1_WORKSPACE_SOURCE_ROOTS: @proofscript/backend-js`. Update the workspace validator to accept precisely scoped *publishable* package metadata without exempting every package from source-root verification. Keep separate authoring and packaged stdlib identities.

### 9.2 Distinguish self-host claims

- **Source self-host:** generated PSC compiler can compile the pinned source language used to implement the compiler; the existing SH/1 qualification is specific to its compiled closure.
- **Installed binary self-host:** a clean `npm install` of a specific tarball, with no Lean available in the self-host stage, rebuilds the *complete pinned compiler source closure* using installed `psc`, checks its canonical admissions through the declared JS kernel, emits TS/JS, then re-compiles with generated C1 and C2 and compares required C2/C3 source, admissions, TS and JS products. Compare not only output execution examples but exact architecture-relevant digests. Rebuilding kernel JS as well requires an independently declared kernel closure and its checking model.
- **Independent package self-host:** each scoped package has its own defined input/runtime ABI and can generate and use its own implementation independently of unacknowledged shared compiler façades. **Not currently established.**
- **Joint compiler/kernel fixed point:** self-host compiler plus generated kernel requalification with sound admission and exact identity. **Not established by the current npm workflow.**

The CI bootstrap path may still use Lean-native `psc1` to *seed* generation. A separate **installed-package fixed-point gate** must not. No general fixed-point theorem follows solely from C2/C3 hash equality: exact semantic soundness and toolchain trust are separate claims.

### 9.3 Cache and incremental builds

A red/green graph is useful, but only **below** the trust-boundary decisions. Cache keys MUST include source content, module graph, compiler binary, kernel/prelude IDs, target runtime ABI, extension binaries/config, assumptions, effect/spec profile, IR format and toolchain flags. Cached `prepared` IR is untrusted until admitted under the *current* kernel/environment. Never cache a free-floating “verified” boolean or reuse a saved checked token after process restart.

## 10. Resource and performance contract

Use layered budgets and observable failure categories, with budgets calibrated and versioned per platform rather than treating arbitrary caps as semantics:

| Stage | Required controls | Known present basis / gap |
| --- | --- | --- |
| Source loader and npm resolver | Maximum files/bytes, maximum import depth, realpath containment, symlink policy, duplicate/cycle detection, cancellation and file-change check | Current `npm-cli/psc.js` walks imports but lacks complete aggregate size/depth limits |
| Parser/elaborator and graph | CPU wall, stack/recursion, memory, AST/module/declaration counts, diagnostics size | Missing comprehensive subprocess budget in released npm path |
| Kernel adapter | Canonical JSON/input depth/size, declaration count, memory/CPU/wall, provider identity, explicit resource/internal distinction | Current npm checker has 16 MiB input and 20k declaration max; configured 512 MiB V8 old space and timeout do **not** bound all RSS |
| External syntax/tactic/backend guest | Fuel/instruction budget, max memory/pages, no ambient network/filesystem, timeout and output-byte bound | **Proposed**; no claim of operational hardened guest sandbox today |
| Emission/`tsc` | Target binary+version pins, stage size/files/count, process timeout, stable output and rollback | TS7 version checks and stage exist; multi-file commit/host path constraints need strengthening |
| Release/build system | Locked dependencies, reproducibility, authenticated provenance, offline audit | npm tarballs and hashes exist; signatures/builder attestation and independent reconstruction not established |

Current PSKernel M3 small-workload acceptance had native RSS near 73 MiB on one historical benchmark and JS shared beta-WHNF ~15.5s for 1000 operations. Those numbers indicate optimization opportunity; they are **not** startup-to-release, large proof-library, current JS npm pipeline or multitenant resource guarantees. Avoid performance claims without matching workload/runtime identities.

Performance roadmap: profile and cache semantic-neutral queries; prove cache invariants before trust-critical acceleration; benchmark cold/warm separately; prioritize source graph incremental invalidation, immutable IR and host orchestration before speculative optimizer rewrites. Use negative resource fixtures that cannot be “passed” by throwing or incorrectly accepting.

## 11. Threat scenarios and mandatory refusal tests

| Scenario | Required response | Gate |
| --- | --- | --- |
| Invalid term, theorem type mismatch, unsupported inductive | Kernel rejection or explicit decline; no output | `PSC-ARCH-001` |
| Guest proposes `accepted:true` or forged checked token | Refuse host authority transfer; plugin never sees minting API | `PSC-ARCH-002` |
| Mutate prepared graph or admissions after check | Re-encode detects mismatch; no output | `PSC-ARCH-003` |
| Source file/symlink swapped before publish | Snapshot/realpath/digest mismatch aborts and preserves old output | `PSC-ARCH-004` |
| Change kernel, prelude, axiom basis or semantic version with cached prepared IR | Cache miss + recheck under selected identity | `PSC-ARCH-005` |
| Kernel crash, wrong identity, malformed decision, timeout, memory limit | Distinct failure, never fallback or successful publish | `PSC-ARCH-006` |
| Guest attempts filesystem/network/host process access | OS/Wasm capability denial, execution disclosed | `PSC-ARCH-007` |
| Third-party package tries `Ps` or `ProofScript` namespace takeover | Package policy/name/digest mismatch → refusal | `PSC-ARCH-008` |
| npm library has install script or unexpected optional dependency | Publish/install policy blocks or explicitly warns; source import remains non-executing | `PSC-ARCH-009` |
| Backend changes output semantics, erases unchecked effect or drops contract | IR/target validation/refinement gate refuses *verified* claim; no silent escalation | `PSC-ARCH-010` |
| Host receives fabricated JSON receipt | Cannot reconstruct checked capability from JSON | `PSC-ARCH-011` |
| Error occurs during multi-output commit | Old committed release preserved; no partial new current generation | `PSC-ARCH-012` |
| Compiler generated by installed package diverges in next generation | Self-host claim withdrawn; release gate fails | `PSC-ARCH-013` |
| Artifact hash is correct but generated by untrusted builder | Verify independent signed provenance against approved builder and source | `PSC-ARCH-014` |
| Model-violating / unmodeled user axiom | Compatible-mode assumption is reported; verified-only profile declines per explicit policy | `PSC-ARCH-015` |
| Malformed JSON or oversized nested source/proof input | Resource/schema failure before unbounded work | `PSC-ARCH-016` |

Distinguish these tests from *simulated* malice against a same-process host: Node's resource permissions are **not** an OS sandbox for deliberately hostile code. Compromised CI infrastructure and compromised npm installer remain residual supply-chain risks even after these CI checks.

## 12. Incremental execution plan — architecture first, no broad rewrite

Each phase starts with a written architecture delta, one canonical owner, acceptance test IDs, and one traceable CI receipt. Preserve exact source commits and concurrent branch history. **Do not modify the separate kernel-proof branch as part of packaging/host refactoring.**

| Phase | Concrete scope | Exit condition / no-go |
| --- | --- | --- |
| **P0: authority audit** | Fix workspace package metadata CI; inventory all paths to emission and checker selection; map current 4.34/4.35 and old/new kernel identities | No unreviewed `emit` route; green workspace and npm CI; inventory checked into docs |
| **P1: checked host** | Extract one service from `checked-prepared-session.mjs`; bind snapshot + exact admissions + guest inventory + policy + kernel version; make npm CLI use it | `PSC-ARCH-001..006,011,012` green; negative mutation/no-output; existing Linux/Windows build behavior preserved |
| **P2: source graph** | Immutable canonical source closure, robust imports, lock-integrity, optional `stdlib`, package resolution, tracked source conversion exceptions | `PSC-ARCH-004,005,008,009,016` and both PS/Lean npm consumer suites green |
| **P3: explicit extension proposal ABI** | First data-only syntax/tactic guest, then optional executable guest in real OS/Wasm sandbox; protected disclosure | `PSC-ARCH-002,007`; host cannot execute untrusted extension JS in-process; no proof admission bypass |
| **P4: backend contract** | Versioned IR validation + TS7 runtime semantics map, effect/spec coverage policy; backend guest output only | `PSC-ARCH-010`; correct labeling of fidelity guarantees; kernel never supplies codegen release credentials |
| **P5: installed npm self-host** | Clean npm C0→C1→C2→C3 generation and exact parity; kernel source/JS identities separately qualified | `PSC-ARCH-013`; fixed-point results tied to current package tarball and source hashes; no Lean in generation stage |
| **P6: provenance + release profiles** | Signed builder provenance, independent verification, versioned assumption/effect reports; optional stronger `pscv-verified` mode only after obligations actually implemented | `PSC-ARCH-014,015`; verified release blocked if any mandatory obligation unresolved |
| **K track: PSKernel proof** | Current proof branch's concrete public acceptance→model→relative consistency, then cache/JS refinement | Separate proof owner; no promotion of formal-soundness labels until theorem and SHA-bound runtime correspondence pass |

**Sequencing decision:** P0→P1→P2 is the lowest-cost, highest-assurance improvement. P3 may proceed after P1 without waiting for full metatheory, because no guest receives proof authority. K runs independently. Do not block simple source library development on K; do block **formal verification claims** on the corresponding proof obligations. Avoid full backend rewrites, generalized language plugin frameworks or extra registries in P0–P2.

**Definition of “done”:** not just green smoke checks. A phase is complete only with (1) versioned interface/invariant; (2) acceptance and negative evidence from actual installed candidate; (3) immutable source and toolchain pins; (4) failure modes tested; (5) updated `AI_WORK_STATE.md`; and (6) a recorded decision about what stronger claim is *still not justified*.

## 13. Fifteen-criterion acceptance matrix

The numerical baseline is a **design review estimate, not a formal measurement**. Targets are meaningful required evidence; no requirement to reach an arbitrary score by documenting rather than implementing.

| Criterion | Baseline (0–10) | Required architecture evidence |
| --- | ---: | --- |
| Soundness / fidelity | 4 | Actual public checker model theorem + separate source→IR→target preservation claims |
| TCB transparency | 6 | One manifest listing semantic, runtime, host, compiler, caches, primitives and build-chain dependencies |
| Adversarial robustness | 4 | Negative-source/guest/input-drift suites, no output after every failure, no same-process hostile code |
| Small compiler / extensibility | 4 | Frozen minimal self-host closure, data extension ABI, optional packages excluded from core |
| Architecture | 5 | One checked build state machine, typed host boundaries, no duplicate provider-selection semantics |
| Independent evidence | 5 | Differential oracles, independent proof review, installed npm self-host, signed release evidence |
| Performance | 3 | Matched source/target benchmarks, cold/warm separation, controlled regression budgets |
| Resource behavior | 4 | Stage-wide CPU/memory/bytes/depth budgets, cancellation and accurate rejection |
| Portability | 6 | Linux/Windows Node22/26 qualification; other targets separately qualified; no OS binary grafting |
| Longevity | 4 | Stable versioned IR/ext protocols, pin migrations, no old-semantic downgrade fallback |
| Interoperability | 5 | npm source library ABI, TS7 ES module contract, explicit future Rust/Wasm IR ABI |
| Self-host / bootstrap | 5 | Installed npm C0/C1/C2/C3 with source/admission/TS/JS digests; separately bound kernel |
| Auditability | 7 | Comprehensive evidence ledger, sha-bound CI logs, explicit source and theorem provenance |
| Security | 4 | Release host isolation, safe npm install policy, staging/rollback, extension capability denial |
| Soundness security | 2 | Every plugin proposal rechecked, no caller-minted trusted states, reference→JS semantic proof track |

**Review question for every architectural edit:** Does it reduce the amount of code that can turn an untrusted proposal into a “verified executable”, or merely move that code behind a different package name? Favor the former.

## 14. Tradeoffs and rejected shortcuts

| Option | Decision and reason |
| --- | --- |
| Fork/reimplement Lean wholesale | **Reject for PSC0 bootstrap.** Expands TCB, size and maintenance cost without closing verified emission |
| Put all 20 scoped packages in `proofscript` | **Reject.** Keep the qualified compiler closure and required kernel in default npm runtime; optional backends stay optional |
| Immediately compress runtime to two npm modules | **Defer.** Could reduce install size, but first reproduce self-host source/dependency closure from installed artifacts |
| Switch entirely to native/Wasm kernel for “security” | **Do not infer trust from target binary format.** Wasm may improve containment; soundness still requires correct semantics and runtime refinement. Keep requested JS default for bounded experimental npm releases |
| Accept plugin-generated TypeScript as “verified” | **Reject.** Target behavior and effect/contract coverage need separate evidence |
| Let plugins load JavaScript into trusted host because proof terms are checked | **Reject.** Same-process JS can alter host state, emitted bytes or disclosure; isolate executable guests |
| Rely solely on tests and differential agreement for kernel soundness | **Reject as formal-assurance claim.** Useful confidence, but proof of public admission→model and optimized/backends' refinement remain open |
| Treat saved receipt as transferable checked token | **Reject.** A receipt is audit data. Checked authority lives in trusted session and must be recreated by checking |
| Treat npm `--ignore-scripts` as a guarantee for all installation paths | **Reject.** It is one installer policy for that invocation, not source-language semantic proof or permanent sandbox |
| Demand proofs for all backend features before testing anything | **Reject.** Stage verified-only release gates by declared profile; ordinary development may compile with visibly weaker claims |

## 15. Supporting research and concrete links

These are **external design evidence**, not automatically imported PSKernel proofs. Re-check upstream pinned version before implementing source-sensitive rules.

1. Lean 4 language reference, [Elaboration and Compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/) — parser/macros/elaborator separate from kernel checking.
2. Lean 4 reference, [Tactic Proofs](https://lean-lang.org/doc/reference/latest/Tactic-Proofs/) — tactics construct independent checkable proof terms.
3. Lean [4.35.0 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/) — version-sensitive native reduction behavior and removal of older kernel mechanisms.
4. [Con Leche](https://github.com/leanprover/con-leche/blob/master/README.md) and [pinned source](https://github.com/leanprover/con-leche/tree/65e74db49e89ad2bbd1e90aa4f784954db41fa3a) — checker-success-to-set-model methodology and explicitly relative assumptions; a theorem for a different checker does not prove PSKernel soundness.
5. [CompCert compiler manual](https://compcert.org/man/manual001.html) — observable-behavior semantic preservation, separate from “target compiles”.
6. [Wasmtime security](https://docs.wasmtime.dev/security.html) and [WIT worlds](https://component-model.bytecodealliance.org/design/worlds.html) — guest isolation and explicit imported capabilities.
7. [Node.js Security / Permission Model Boundaries](https://github.com/nodejs/node/blob/main/SECURITY.md) — limitations of same-process resource permissions for untrusted code.
8. [npm package lifecycle scripts](https://docs.npmjs.com/misc/scripts/) and [npm install controls](https://docs.npmjs.com/cli/install/) — install-time JavaScript is a separate ecosystem trust concern.
9. [SLSA build provenance](https://github.com/slsa-framework/slsa/blob/main/spec/build-provenance.md) and [artifact verification](https://github.com/slsa-framework/slsa/blob/main/spec/verifying-artifacts.md) — source/builder/artifact identity and authenticity.
10. [Reproducible Builds definition](https://reproducible-builds.org/docs/definition/) — identical source, environment and recipe may be independently checked for bit-identical artifacts.
11. [NIST SP 800-218 SSDF v1.1](https://csrc.nist.gov/pubs/sp/800/218/final) — security practices throughout development and release, not a substitute for proof.
12. PSC0 source: [architecture](../ARCHITECTURE.md), [npm package architecture](NPM_PACKAGING_ARCHITECTURE.md), [current self-host guidance](selfhost-language/CURRENT.md), [kernel contract](../packages/pskernel-core/KERNEL_CONTRACT_V1.md), [kernel TCB manifest](../packages/pskernel-core/PSKERNEL_TCB.json), [kernel M3 budgets](../packages/pskernel-core/M3_ACCEPTANCE.md), [npm checked CLI](../npm-cli/psc.js), [existing checked session](../scripts/checked-prepared-session.mjs), [npm distribution](../scripts/npm-distribution.mjs), and [ongoing proof-first plan](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md).

---

## 16. Adoption and status

**Adopt this document as the target architecture for PSC0's next implementation slice, not as a report of finished work.** Preserve the separate proof branch and historical SH/1 evidence. First commit P0's complete checker/emission-owner audit and correct workspace CI, then P1's one checked host with failure-injection tests, then P2's frozen npm source graph. Changes are not complete until cloud CI demonstrates the exact promised invariants.

At the frozen source, **no unrestricted verified-executable, formally sound JS kernel, secure arbitrary extension, independent 13-package self-host, or full PSCV claim is warranted**. The purpose of this architecture is to make those future claims possible without unnecessarily bloating the compiler or hiding trust inside npm packages.
