# ProofScript — Programming Language Lifecycle, EOL, LTS, and Verification-Foundation Research

**Date:** 2026-10-13 (Asia/Jakarta)  
**Status:** RESEARCH / DISCUSSION DRAFT — not a normative PSCV0 v7 change and not a support commitment  
**Scope:** ProofScript language editions, compiler releases, verification foundations, generated target packages, and reproducible proof artifacts  
**Repository context:** `dwijayuda/pskernel`, `psc0`, native PSCV0 v7; pinned upstream Lean 4.35.0-rc4 for the currently documented design  
**Implementation impact:** None. This document proposes policy for later discussion; no current compiler or package behavior is changed.

## Executive summary

The central finding is that **EOL policy, source compatibility, binary compatibility, proof validity, toolchain availability, and security maintenance are different concepts**. No existing language supplies one policy that optimizes all of them.

A good prospective ProofScript policy combines:
1. **Rust-style, opt-in language editions** and cross-edition package interoperation where semantically sound.
2. **Java/.NET-style published maintenance commitments** for selected stable release trains, backed by actual capacity.
3. **Python/PHP-style transparent active, security-only, and EOL stages** with explicit calendars.
4. **Lean-style reproducible pinning of proof environments**, extended with durable archival of checker sources/binaries, declarations, axioms, proof terms, dependency closure, and executable-correspondence evidence.
5. **Per-target runtime compatibility** for npm/Node, browsers, Cargo/Rust, Wasm/WASI, Python/PyPI, PHP/Composer, JVM, Go, and .NET artifacts.

**Do not announce three- or five-year LTS guarantees now.** Those would be unfunded obligations without a release, backport, security response, and toolchain qualification program. Establish a measurable support capacity and then commit to dates.

**Important ongoing constraint:** A Lean-kernel-checked source theorem does not automatically prove generated JavaScript/Rust/Wasm/Python/PHP behavior. Verified-package claims must bind logical foundation, source, compiler transformations, target artifact identity, runtime assumptions, and external dependencies.

## 1. Questions to decide later

1. Does ProofScript need **language editions**, **compiler release trains**, **verification foundations**, and **target profiles** as separately versioned identities?
2. Is a stable edition a primarily syntactic choice, or does it freeze computational/definitional semantics? If semantic changes are allowed, what proof obligations govern migration?
3. What operational support duration is feasible once production releases begin? Could the project initially promise support for only a current release and one previous stable line?
4. What compatibility is actually guaranteed across editions: source, proof interfaces, runtime ABI, or only checked translations?
5. What constitutes historical proof reproducibility across a kernel or standard-environment upgrade?
6. When a verified package is compiled for an unsupported runtime, which claims remain valid, and which become unsupported?
7. Should target-version range enforcement be in `psconfig.json`, a project/package manifest, a target manifest, or a derived lock? Avoid duplicate authorities.
8. Does each binary/runtime target need its own certificate, in addition to the source theorem?
9. How should verified package dependency resolvers handle foundation mismatches and supposedly compatible proof theorem imports?
10. What must be demonstrated before promising any compatibility or LTS period publicly?

## 2. Research taxonomy: six different clocks

| Dimension | Exact meaning | Example |
|---|---|---|
| Language edition | Source interpretation and compatibility epoch | Rust 2021 versus Rust 2024 |
| Compiler/toolchain | Product version with compiler fixes/support | rustc or Lean 4.x release |
| Runtime/vendor lifecycle | Host receiving maintained updates | Node LTS, CPython, PHP, JVM, .NET |
| Library/package API compatibility | Import signatures, metadata, semantics and ABI | Cargo MSRV, Java classfiles |
| Verification foundation | Kernel rules, axioms, declared environment and proof-term acceptance | Pinned Lean commit + proof environment digest |
| Executable assurance | Evidence connecting source semantics and the actual emitted artifact | JS/Rust/Wasm target qualification/certificate |

An edition surviving for decades **does not** mean an old compiler receives security updates. A proof remaining valid in its original logic **does not** mean its runtime or hosted service is secure.

## 3. Source-grounded comparison — October 13, 2026

The entries below describe *official policies* where published. A missing fixed EOL is **not** scored as zero years. Dates and policy rules may be revised by maintainers; re-check before making product commitments.

| Language / ecosystem | Official version policy | Source/ABI compatibility angle | EOL status interpretation | Primary reference |
|---|---|---|---|---|
| **Java / Oracle JDK** | Oracle LTS lines (8, 11, 17, 21, 25); Premier and Extended Support dates, vendor-specific | Strong JVM binary compatibility tradition; bytecode target and module/API constraints | Dates refer to **Oracle commercial offerings**, not universally to every OpenJDK distribution | [Oracle Java roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) |
| **Rust** | Rolling stable releases; editions 2015/2018/2021/2024 opt in | Older editions compile on newer rustc; mixed-edition crates interoperate; separate MSRV | No single multiyear rustc LTS or language-edition EOL schedule | [Rust Editions](https://doc.rust-lang.org/edition-guide/editions/) |
| **Go** | Each release supported until two newer releases exist | Go 1 source compatibility promise, with documented exceptions | Typically roughly one year of upstream compiler security maintenance | [Go release policy](https://go.dev/doc/devel/release) |
| **Python** | About five years total; first ~two bugfix then security-only | Strong Python 3 continuity but interpreter, ABI, extension and deprecation constraints | Feature-release-specific EOL; security maintenance ends | [Python devguide versions](https://devguide.python.org/versions/) |
| **PHP** | Two years active + two years critical-security support | Backwards-incompatible major/minor changes possible; version constraints matter | Explicit four-year EOL per branch | [PHP supported versions](https://www.php.net/supported-versions.php) |
| **Node.js** | Versioned LTS lifecycle; announced schedule change from Node 27 onward: annual April major, October LTS, ~April three years later EOL | Node runtime support separate from ECMAScript edition | Check schedule for each line; Node 26 follows previous scheme | [Node.js 2026 schedule revision](https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule) |
| **ECMAScript (JavaScript language)** | Annual standards editions; no product LTS/EOL for an edition | Historical syntax/semantics largely supported by newer engines, with exceptions | Security belongs to V8/SpiderMonkey/JavaScriptCore/browser/Node/Bun/Deno, not the ES edition | [ECMA-262](https://tc39.es/ecma262/) |
| **TypeScript** | Frequent compiler versions and evolving typing behavior; no multiyear LTS release series equivalent to Python/PHP | TS source may be rejected by a new type checker even if emitted JS runs | Treat compiler support and declaration compatibility separately | [TypeScript releases](https://github.com/microsoft/TypeScript/releases) |
| **.NET / C#** | .NET LTS three years, STS two years; major releases annually | Runtime/framework target compatibility distinct from C# language version | Published runtime-specific end-of-support dates, patch currency required | [.NET policy](https://dotnet.microsoft.com/en-us/platform/support/policy) |
| **Scala 3** | Separate LTS and Scala Next; Scala 3.9 LTS announced Sept 2026 | Compatibility within LTS patch line, cross-version artifact concerns | Do not invent universal years from the “LTS” label | [Scala 3.9 LTS](https://www.scala-lang.org/news/3.9/) |
| **Lean 4** | Approximately monthly minor releases intended; no strong backwards-compatibility guarantee | Source proof/tactic/library and `.olean`/toolchain stability are not general cross-version guarantees | No published general LTS/EOL schedule identified | [Lean RELEASES.md](https://github.com/leanprover/lean4/blob/master/RELEASES.md) |
| **WebAssembly** | Standards/features and host implementations evolve separately | Core Wasm compatibility does not imply all GC, component, WASI imports work on every host | Runtime-specific and interface-version support, not a universal language-release EOL | [Wasm spec](https://webassembly.github.io/spec/core/), [Component Model](https://component-model.bytecodealliance.org/) |
| **Ruby** | Maintained release lines with normal/security/end-of-life phases | Ruby source/API compatibility varies by branch | Explicit branch EOL schedules; verify current entries before exact date claims | [Ruby branches](https://www.ruby-lang.org/en/downloads/branches/) |
| **Kotlin** | Compiler and stdlib support policies can differ | Kotlin language, metadata and JVM ABI compatibility need separate treatment | Do not infer a universal SDK LTS from library policies | [Kotlin releases](https://kotlinlang.org/docs/releases.html) |
| **Dart** | Rolling stable SDK and explicit language versions | `pubspec` SDK constraints and language version affect packages | Historically latest stable SDK actively supported; confirm current details before commitment | [Dart support policy](https://dart.dev/get-dart/archive) |
| **C/C++** | Language standards editions, no central runtime EOL clock | Compiler and ABI/platform compatibility depend on toolchain/vendors | Support by GCC/Clang/MSVC, runtime, OS and standard library versions | [ISO C++ status](https://isocpp.org/std/status), [GCC releases](https://gcc.gnu.org/releases.html) |

### Examples of explicitly scheduled support dates

- **Oracle Java 21 LTS:** Premier through September 2028, Extended through September 2031. **Oracle Java 25 LTS:** Premier September 2030, Extended September 2033. These dates are tied to a defined Oracle support offering, not a blanket property of Java language syntax.
- **PHP 8.2:** security support until December 31, 2026; **PHP 8.5:** until December 31, 2029.
- **.NET 10 LTS:** support through November 14, 2028, as documented in Microsoft's September 2026 policy.
- **Node.js 26:** EOL planned April 2029 under the existing schedule. **Node.js 27:** new schedule planned for 2027 release and April 2030 EOL; proposed future dates can change.
- **Go:** Go 1.27 appeared August 2026; the policy still says two newer releases supersede the oldest supported line.

Avoid translating these facts into a misleading universal “the language supports X years” promise.

## 4. Ranking methodology — do not conflate incomparable metrics

Instead of a single pseudo-precise score, rank **policy patterns** in separate dimensions. The following are **reasoned judgments**, not benchmark measurements, and their order changes with evaluation goals.

### Ranking A: long-term compatibility design for reusable code

| Rank | Model | Why |
|---:|---|---|
| 1 | Rust-style editions | Independent opt-in migrations plus cross-edition crates offer a useful design for long-lived libraries |
| 2 | Go 1 compatibility | Strong promise of continued source compatibility, though its compiler support window is relatively short |
| 3 | Java/JVM compatibility | Long-lived binary ecosystem, versioned bytecode plus mature vendor support |
| 4 | ECMAScript/browser compatibility | Stable installed base and largely additive language standards, but engine support is not standardized EOL |
| 5 | .NET target frameworks | Explicit framework targeting and considerable compatibility tooling |
| 6 | Python/PHP | Predictable maintenance; incremental source changes still possible |
| 7 | TypeScript | Rapidly improving type checker but possible source typing breakages |
| 8 | Lean 4 | Valuable proof kernel and pinned reproduction; weaker cross-release compatibility contract |

This is not a popularity, software-correctness, language-quality or maintenance-duration ranking.

### Ranking B: transparency and predictability of operational maintenance

| Tier | Strong examples | Main rationale |
|---|---|---|
| 1 — explicit supported versions and dates | Python, PHP, Node.js, .NET, Oracle JDK | Users can plan upgrades; Oracle's terms are vendor-specific |
| 2 — deterministic moving window | Go | Simple supersession rule but short lifecycle |
| 3 — edition/LTS channels without universal multi-year per-toolchain policy | Rust, Scala | Compatibility and maintained branches are meaningful; avoid implying an arbitrary support duration |
| 4 — specification or evolving toolchain without central EOL commitment | ECMAScript, Wasm, TypeScript, Lean 4 | Need to inspect concrete engines/toolchains or packages |

### Ranking C: most useful models for ProofScript

1. **Rust:** separate language edition from compiler release and support mixed-edition packages.
2. **Lean + reproducible archival:** freeze formal environment, proof terms, declarations and assumptions for historical theorem rechecking.
3. **Python/PHP:** unambiguous published lifecycle states: active, security, EOL.
4. **Java/.NET:** optional funded stable/LTS trains with defined backports.
5. **Go:** a narrow, precise compatibility promise with exceptions, rather than vague “will not break” language.
6. **Node/Wasm:** treat target runtime and host capability/version support as separate contracts.

**Why different rankings?** Longest vendor servicing time is not the same as best future source compatibility. An old theorem may remain checkable long after its original source stops elaborating on the latest Lean.

## 5. Proposed ProofScript version identity model

Avoid using a single `"proofscriptVersion"` to represent five independent compatibility commitments.

```text
ProofScript source package
  languageEdition          -> syntax and stated source/semantic behavior
  compilerRelease          -> implementation and build toolchain
  verificationFoundation   -> checked logical/kernel environment, axioms
  sourceInterfaceDigest    -> API/specification/proof contract identities
  targetProfiles[]         -> runtime/ABI/features/MSRV and output libraries
  artifactCertificates[]   -> per-target evidence, version/hashes and limits
```

**Prototype metadata sketch** (not a new approved schema):

```json
{
  "languageEdition": "experimental-pscv0-v7",
  "compiler": {"version": "development", "commit": "<compiler-commit>"},
  "verificationFoundation": {
    "kernel": "Lean",
    "leanVersion": "4.35.0-rc4",
    "leanCommit": "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364",
    "environmentDigest": "<sha256>",
    "assumptionsDigest": "<sha256>",
    "proofArtifactDigest": "<sha256>"
  },
  "targets": {
    "javascript": {"ecma": "ES2022", "nodeRange": "<tested-supported-range>"},
    "rust": {"edition": "2024", "msrv": "<tested-msrv>"},
    "wasm": {"features": ["gc"], "componentModel": "<supported-version>"},
    "python": {"requiresPython": "<tested-range>", "backend": "binding-or-native"},
    "php": {"phpConstraint": "<tested-range>", "backend": "binding-or-native"}
  }
}
```

The environment digest, axiom roster, toolchain identity, and proof terms must be *mutually consistent*. A digest by itself is not proof authority. Keep source theorem identity separate from an executable or runtime security support claim.

## 6. Lifecycle states proposed for ProofScript

| State | Source/compiler maintenance | Security handling | New features | Verification status |
|---|---|---|---|---|
| Development | Fast iteration | Best effort; no production promise | Allowed | Clearly experimental |
| Stable / Active | Regular fixes, backward-compat checks | Maintained | Compatible additions only | Per-foundation and per-artifact claim |
| LTS Active | Restricted and audited backports | Maintained by staffed policy | Normally no language changes | Freeze semantics, check migrations |
| Security Only | Necessary security/critical integrity fixes | Maintained through announced date | No | Preserve proof provenance; requalify changes |
| Operational EOL | No ongoing release/security promise | Not maintained | No | Historical proof may still be reproducibly checked |
| Archived Foundation | Read-only checker/proof/environment materials | **Not an actively supported runtime** | No | A historical mathematical derivation remains checkable under archived assumptions |

An archive is **not** a security-maintained installation; avoid confusing these two statuses.

### Initial policy proposal (not yet a commitment)

- Before v1.0, **no LTS promise**. Publish development snapshots with pinned Lean and clear risk classification.
- At v1.0, define one stable source edition and test at least the current plus preceding stable compiler, if sustainable.
- Consider **three-year LTS** only once the project has an actual supported release process, issue-response channel, automated backport matrix, regression budget, and security remediation capacity.
- Consider **five-year LTS** only if sponsorship/maintainers and downstream adoption justify it.
- Make archival of verification foundations a priority **before** long-period release-support claims.

## 7. What does EOL mean for a verified package?

Consider a formally proved function `transfer` with a theorem about preservation of the sum of balances.

**A source theorem's logical status:** A derivation from given axioms under a specific proof kernel/foundation continues to hold in that fixed logical system after an old runtime reaches EOL, assuming the derivation/checker is sound and preserved. The proof does not need to expire on a calendar date.

**A compiled artifact's assurance:** If the emitted JavaScript package is running on an EOL Node.js runtime, the source theorem is unchanged, but claims about target execution, runtime primitives, vulnerabilities and operational support must be reassessed. The same holds for Python, PHP, JVM, native Rust-linked binaries and Wasm component hosts.

**A rewritten implementation:** A source package update may preserve its public theorem statement while invalidating the proof that this new implementation satisfies it. Recheck the new body and its connection to the target artifact. A source theorem about an abstract translation is not automatically end-to-end executable verification.

Proposed reporting shape:

| Field | Example status |
|---|---|
| Kernel theorem | `checked`, for exact proposition and foundation |
| Source implementation relation | `proved`, `assumed`, `tested`, `not-established` |
| Code generation relation | Per backend: `proved`, `translation-validated`, `tested`, `not-established` |
| Runtime security support | `supported`, `security-only`, `eol`, `unknown` |
| Runtime FFI assumptions | Named, versioned and disclosed |
| Archive/checker available | Yes/no, with checksummed artifacts |

Never map `kernel checked` to `binary verified` automatically.

## 8. Cross-target package implications

| Output | Declare | Qualification needed | EOL source |
|---|---|---|---|
| npm JavaScript/TypeScript | ECMAScript target, Node/browser/edge runtime engine range, `.d.ts`/module contract | Install/import/run on supported engines and type-check declarations | Node/browser/engine providers |
| Cargo Rust | Rust edition, MSRV, dependencies, ABI rules | `cargo check` on MSRV and current stable, build/run test | rustc compatibility/MSRV; OS/libc dependencies |
| Wasm core/component | Required features (e.g. GC), WIT package/world, WASI imports, host runtime | Execute on claimed Wasmtime/browser hosts and validate ABI | Host/runtime/WASI provider |
| PyPI Python | `requires-python`, wheel platform tags or pure Python source, native extension ABI | pip install, import, runtime behavior on supported interpreter/platform matrix | CPython and other supported interpreter lifecycles |
| Composer PHP | `php` constraint, extensions, PSR-4 mapping | Composer install, autoload, run on supported PHP branches | PHP official support and hosting providers |
| Java/JVM | Classfile/API baseline, supported JDK distribution | Test against minimum JVM and supported vendor/runtime lines | Vendor-specific JDK support |
| Lean package | Exact `lean-toolchain`, Lake dependencies and proof-environment identity | Rebuild/recheck and inspect axiom/assumption closure | Lean releases; no blanket LTS |

Support claims must be target- and feature-specific. A host capability or ABI that is missing cannot be papered over by a generic success report.

## 9. Migration and compatibility design

A safe edition transition should have:

1. An explicit old/new syntax/semantics delta, especially where definitional equality changes.
2. Reproducible source-to-source migration for compatible changes.
3. **No automatic upgrade of theorem authority**. A new proof foundation must independently recheck imported proof declarations and assumptions or reject them.
4. Versioned module public interfaces, theorem/spec fingerprints and FFI contracts.
5. Exact checks for transitive dependency/source invalidation and any generated target bundle.
6. Negative conformance tests for false acceptance and false verification labels.
7. Clear remediation procedures for old security-only and EOL runtime versions.

Do not promise that Rust-like editions can be transplanted directly onto Lean's dependent semantics without proving that mixed-edition components share a coherent logical meaning.

## 10. Open research and falsification tests

**Proposed experiments, not yet executed:**

- Recheck representative pinned Lean proof modules after upgrading several Lean releases; inventory source edits and changes in axioms/theorem interfaces.
- Define two ProofScript “editions” with an intentionally changed syntactic rule, then test mixed-edition imports without changing proof meaning.
- Produce `ps-json` outputs for npm, Cargo and Wasm and test each against a current and oldest advertised supported target environment.
- Inject one expired runtime version and assert package validation reports operational EOL independently of the valid source theorem.
- Change one package theorem assumption without modifying its exported executable type; verify downstream dependency invalidation.
- Change one generated backend runtime primitive without changing source proofs; assert that any target verification claim requires renewed evidence.
- Test deterministic reconstruction of a historical proof environment from archived dependency and checker information in an isolated environment.
- Measure CI matrix cost and security-backport complexity for 1, 2 and 3 concurrently supported stable ProofScript lines before selecting LTS duration.

**Failure/stop conditions:** If historical proofs cannot be reproduced, do not claim permanent verification archival. If more than one maintained release train exceeds realistic capacity, reduce the LTS promise. If mixed-edition semantics conflict, isolate or recheck instead of inventing compatibility.

## 11. Decision record for future discussion

| Topic | Preliminary direction | Status |
|---|---|---|
| Distinct language edition vs compiler release | Yes | **Proposal** |
| Distinct verification foundation | Yes; exact Lean pin and transitive context | **Proposal** |
| Stable language edition compatibility | Aim for opt-in upgrades | **Open proof/semantics design** |
| Operational phases | Active → security-only → EOL | **Proposal** |
| Immediate LTS guarantee | No | **Recommendation** |
| Long-term LTS target | Investigate 3 years; 5 years contingent | **Undecided** |
| Archive original checked proof environments | Yes | **Foundational objective** |
| Preserve `.olean` as sole portable certificate | No | **Reject** |
| Claim cross-target correctness from one Lean theorem alone | No | **Reject** |
| Generate target runtime support status | Yes | **Proposal** |
| Expand backends solely for lifecycle reasons | No | **Reject** |
| Change PSCV0 v7 language specification now | No | **Not authorized by this research** |

## 12. Sources and confidence

Official links checked October 13, 2026:

1. [Python developer guide: supported branches and phases](https://devguide.python.org/versions/) — high confidence for 5-year policy.
2. [PHP supported versions](https://www.php.net/supported-versions.php) — high confidence for 2+2-year policy.
3. [Node.js evolving release schedule (2026)](https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule) — high confidence for announced policy; future calendar is subject to revision.
4. [Go release history/policy](https://go.dev/doc/devel/release) — high confidence for two newer major releases.
5. [Rust editions](https://doc.rust-lang.org/edition-guide/editions/) — high confidence for language-edition continuity, **not** an LTS toolchain promise.
6. [Oracle Java SE support roadmap (updated September 2026)](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) — high confidence for stated Oracle commercial offerings, vendor-specific.
7. [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy) — high confidence for 3-year LTS and 2-year STS.
8. [Scala 3.9 LTS announcement](https://www.scala-lang.org/news/3.9/) — high confidence for LTS-vs-Next distinction; no fabricated fixed duration.
9. [Lean 4 release statement](https://github.com/leanprover/lean4/blob/master/RELEASES.md) — high confidence for monthly intent and no strong backward compatibility.
10. [ECMAScript specification](https://tc39.es/ecma262/), [Wasm Core](https://webassembly.github.io/spec/core/) and [Component Model](https://component-model.bytecodealliance.org/) — standards, not runtime EOL calendars.
11. [TypeScript releases](https://github.com/microsoft/TypeScript/releases), [Ruby branches](https://www.ruby-lang.org/en/downloads/branches/), [Kotlin releases](https://kotlinlang.org/docs/releases.html), [Dart archive](https://dart.dev/get-dart/archive) — official entry points; exact lifecycle comparisons require further dedicated research.

**Evidence limitations:** This is a primary-policy survey with architectural analysis, not a benchmark, independent vendor audit, costed LTS staffing plan, or formal proof of cross-edition compatibility. No software or tests were changed or executed as part of this research document.

## 13. Suggested discussion agenda

1. First approve the **four independent identities**: language edition, compiler, logical foundation, target runtime.
2. Decide the **minimum compatibility promise** ProofScript can demonstrate.
3. Specify the **historical proof archive/checker format**, avoiding dependence on mutable external registries or `.olean` alone.
4. Decide **when** security and support dates become public commitments.
5. Design the **per-target artifact provenance fields** jointly with package metadata and FFI contracts.
6. Only after those decisions consider an implementation plan; retain current M1→M5 / A→E execution priorities.

---

**Bottom line:** ProofScript's distinctive promise should not be “no EOL.” It should be **clear operational EOL, conservative compatibility, exact proof-environment pinning, and historically recheckable mathematical evidence**—without pretending an old runtime or generated binary stays secure merely because a theorem remains valid.
