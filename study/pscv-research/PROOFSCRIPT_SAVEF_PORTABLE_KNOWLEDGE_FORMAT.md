# ProofScript SAVEF Portable Knowledge Format

**Status:** research architecture and proposed portable format; non-normative.

**Working identity:** SPKF-v1 — SAVEF Portable Knowledge Format v1.

**Research snapshot:** 2026-10-06.

**Target architecture score:** **9.39 / 10**

**Current implementation/evidence readiness:** **approximately 5.63 / 10**

**Repository:** dwijayuda/pskernel

**Purpose:** define a registry-neutral, content-addressed, mirrorable, cross-ecosystem format for distributing and accumulating SAVEF knowledge independently from npm, Cargo, PyPI, Maven, Composer, GitHub, OCI, or future package registries.

The central decision is:

> **The unit of SAVEF knowledge must not be an npm package, Rust crate, Python distribution, Maven artifact, Composer package, GitHub repository, or OCI manifest.**

Those are distribution systems.

The unit of SAVEF knowledge should be a **content-addressed semantic object** whose identity derives from canonical bytes and whose meaning is explicitly tied to a semantic profile.

Package ecosystems publish bindings to the same knowledge object.

---

# 1. Why this matters

Without a portable knowledge identity:

~~~text
npm theorem
Cargo theorem
PyPI theorem
Maven theorem
Composer theorem
~~~

can become disconnected copies.

With SPKF:

~~~text
                         theorem T
                       SPKF object T
                            |
          +----------+------+-------+----------+
          |          |              |          |
         npm       crates.io       PyPI      Maven
          |          |              |          |
          +----------+------+-------+----------+
                            |
                            v
                 everyone reuses theorem T
~~~

A theorem discovered during Rust development can become useful to JavaScript, Python, PHP, JVM, Wasm, and ProofScript users if it is stated against a sufficiently portable semantic abstraction.

---

# 2. Design goals

SPKF-v1 SHOULD provide:

1. **Registry independence.** Knowledge identity survives movement across package managers, OCI registries, GitHub releases, local filesystems, archives, and content-addressed stores.
2. **Semantic identity.** Registry name, URL, compression, package version, upload time, and filesystem path do not define theorem identity.
3. **Explicit semantic profile.** Every authority-bearing object is tied to exact PSCV/Lean/kernel/runtime contracts.
4. **Proof-authority separation.** Metadata and registry claims cannot manufacture theorem validity.
5. **Incremental extensibility.** Third parties can publish new theorems, refinements, implementation witnesses, compatibility evidence, and empirical evidence about an immutable subject.
6. **Free mirroring.** Anyone with permitted bytes can mirror/archive knowledge without a central ProofScript service.
7. **Cross-language distribution.** One theory can have JavaScript, Wasm, Rust, Python, JVM, PHP, or other implementation witnesses.
8. **Bounded verification.** Hostile objects cannot force unlimited graph expansion, decompression, allocation, parsing, or proof replay.
9. **Practical bootstrap.** The first implementation reuses current ProofScript artifacts and existing standards; it does not require a new global registry.

---

# 3. Non-goals

SPKF-v1 is NOT:

- a new package manager;
- a replacement for npm, Cargo, PyPI, Maven, or Composer;
- a replacement for PSKernel;
- a new foundational proof logic;
- a universal cross-proof-assistant calculus;
- a mandatory global search service;
- a blockchain;
- an authority system based on popularity.

SPKF is a portable **knowledge object and graph format**.

---

# 4. Relationship to current ProofScript architecture

The current ProofScript build architecture already proposes:

~~~text
SourceArtifact
CandidateCoreArtifact
CheckedCoreArtifact
ErasedIrArtifact
VerifiedIrArtifact
ModuleInterfaceArtifact
InterfaceIrArtifact
ExecutableArtifact
EvidenceManifest
~~~

and already plans:

- domain-separated ArtifactId values;
- canonical serialization;
- semantic package manifests;
- psc.lock;
- content-addressed storage;
- deterministic BuildAction identities;
- semantic red/green QueryGraph invalidation.

SPKF SHOULD reuse these concepts.

~~~text
ProofScript canonical artifacts
            |
            v
       SPKF envelope
            |
            v
portable content-addressed graph
            |
       +----+----+
       |         |
       v         v
 package      OCI / mirror
 bindings      transport
~~~

SPKF is not a second compiler artifact hierarchy.

---

# 5. Relationship to Applied SAVEF

Applied SAVEF defines the authority chain:

~~~text
Source
    |
    v
CandidateCore
    |
    v
AdmissionReady
    |
    v
CheckedCore
    |
    v
CertifiedSource
    |
    v
CertifiedModuleInterface
    |
    v
RuntimeIR
    |
    v
VerifiedIR
    |
    v
PreservedTargetArtifact
~~~

SPKF answers:

> How are these semantic artifacts, theorems, specifications, assumptions, capabilities, and implementation relations given durable portable identities and shared across ecosystems?

SPKF MUST NOT weaken any state in this chain.

---

# 6. Standards reused instead of reinvented

## 6.1 RFC 8785 JCS

JSON Canonicalization Scheme provides deterministic JSON bytes suitable for hashing and signing.

SPKF-v1 uses a restricted JCS-compatible JSON profile for graph objects.

Source:
https://www.rfc-editor.org/rfc/rfc8785.html

## 6.2 RFC 8949 deterministic CBOR

Deterministic CBOR is reserved as a future compact binary encoding for large metadata/payloads.

Source:
https://www.rfc-editor.org/rfc/rfc8949.html

## 6.3 OCI 1.1

OCI 1.1 provides:

- content-addressed descriptors;
- artifactType;
- subject;
- referrers API;
- manifest/index DAGs.

SPKF's recommended OCI mapping SHOULD use OCI Image Manifest 1.1 artifact conventions. OCI deliberately removed the proposed dedicated artifact-manifest type from the final 1.1 release for portability reasons.

Sources:
https://opencontainers.org/posts/blog/2024-03-13-image-and-distribution-1-1/
https://specs.opencontainers.org/image-spec/manifest/

## 6.4 ORAS

ORAS provides practical generic OCI push/pull/discovery tooling.

SPKF MAY use ORAS tooling without making ORAS formats semantic authority.

Source:
https://oras.land/

## 6.5 Package URL / ECMA-427

PURL defines ecosystem-independent software package coordinates.

SPKF uses PURL for distribution bindings.

Source:
https://ecma-international.org/publications-and-standards/standards/ecma-427/

## 6.6 in-toto Attestation Framework

in-toto Statement v1 binds digest-addressed subjects to typed predicates.

SPKF SHOULD reuse it for authenticated supply-chain claims where appropriate.

Source:
https://github.com/in-toto/attestation

## 6.7 SLSA v1.2

SLSA provenance describes where/how an artifact was produced.

It is provenance, not semantic proof.

Source:
https://slsa.dev/spec/v1.2/

## 6.8 SPDX 3.0.1

SPDX can represent software artifacts, external identifiers, content identifiers, licenses, and supply-chain relationships.

SPKF SHOULD integrate with SPDX rather than encode SBOM semantics itself.

Source:
https://spdx.github.io/spdx-spec/v3.0.1/

---

# 7. Core identity model

SPKF-v1 defines two identity classes.

## 7.1 Object identity

Textual form:

~~~text
spkf-v1:sha256:<hex>
~~~

This is an SPKF identifier string, not a registered URL scheme.

Conceptual digest:

~~~text
SHA256(
    UTF8 domain separator "SPKF/1" plus NUL
    concatenated with
    JCS(canonical object without an id field)
)
~~~

The object schema and kind are part of the canonical object, providing semantic domain separation.

## 7.2 Blob identity

Large opaque payloads use:

~~~text
spkf-blob-v1:sha256:<hex>
~~~

Conceptual digest:

~~~text
SHA256(
    UTF8 domain separator "SPKF-BLOB/1" plus NUL
    concatenated with
    raw uncompressed bytes
)
~~~

The SPKF semantic identity is independent from package-registry transport digests.

---

# 8. Why SPKF identity is not OCI identity

OCI digests identify particular transported manifest/blob bytes.

SPKF semantic identity must remain stable if the same canonical knowledge is:

- placed in another registry;
- compressed differently;
- embedded in npm;
- embedded in a crate;
- archived in a GitHub release.

Therefore:

~~~text
SPKF semantic ID
    !=
transport artifact digest
~~~

DistributionBinding connects the two.

---

# 9. Canonical JSON profile

Authority-bearing SPKF JSON MUST:

- be UTF-8;
- satisfy the selected JCS/I-JSON restrictions;
- reject duplicate keys;
- canonicalize deterministically;
- avoid semantically irrelevant timestamps;
- avoid ambient filesystem paths;
- avoid host map iteration order.

## Numeric rule

JCS follows ECMAScript numeric serialization.

Therefore arbitrary mathematical Nat/Int values MUST NOT be represented as unconstrained JSON numbers.

Use:

- bounded schema-defined integers for sizes/counts;
- canonical decimal strings for arbitrary integers;
- separately versioned proof payloads for formal terms.

Example:

~~~json
{
  "declarationCount": 91,
  "largeNatural": "340282366920938463463374607431768211456"
}
~~~

---

# 10. Canonical KnowledgeRoot

Conceptual root:

~~~json
{
  "schema": "spkf/1",
  "kind": "knowledge-root",

  "semanticProfile": {
    "id": "spkf-v1:sha256:..."
  },

  "interface": {
    "id": "spkf-v1:sha256:..."
  },

  "specifications": {
    "id": "spkf-v1:sha256:..."
  },

  "theorems": {
    "id": "spkf-v1:sha256:..."
  },

  "assumptions": {
    "id": "spkf-v1:sha256:..."
  },

  "capabilities": {
    "id": "spkf-v1:sha256:..."
  },

  "license": {
    "spdxExpression": "Apache-2.0"
  }
}
~~~

This example is architectural, not a frozen schema.

---

# 11. SemanticProfile object

A PSCV profile object binds all meaning-relevant contracts.

Conceptual fields:

~~~text
logic
ProofScript edition
PSCV profile
verification semantics
certificate policy
Lean semantic version/commit
KernelContract identity
runtime semantics
Standard environment digest
artifact schema contracts
~~~

Evidence from another semantic profile is not automatically reusable.

---

# 12. Authority classes

SPKF must distinguish:

## Semantic authority

- kernel-accepted theorem;
- checked semantic interface;
- accepted refinement.

## Validation authority

- accepted translation validator;
- certified decision-procedure certificate.

## Empirical evidence

- benchmark;
- conformance test;
- differential test;
- monitoring result.

## Provenance evidence

- SLSA;
- in-toto;
- GitHub/npm artifact provenance.

## Advisory knowledge

- AI hints;
- failure traces;
- examples;
- proof-search strategies.

Advisory knowledge MUST NOT discharge proof obligations.

---

# 13. Core SPKF object kinds

SPKF-v1 should standardize:

1. knowledge-root
2. semantic-profile
3. certified-interface
4. specification-set
5. theorem-set
6. assumption-set
7. capability-set
8. theory-extension
9. implementation-witness
10. backend-evidence
11. compatibility-certificate
12. distribution-binding
13. boundary-evidence
14. advisory-knowledge
15. snapshot-index

Every kind has separate validation rules.

---

# 14. Theory extensions

Third parties can add immutable knowledge without changing the root.

~~~text
KnowledgeRoot A
    Json theory

TheoryExtension T1
    subject = A
    adds theorem parse_token_partition

TheoryExtension T2
    subject = A
    adds theorem streaming_buffer_bound
~~~

T1 and T2 have independent IDs.

The original A is unchanged.

---

# 15. Proof payload rule

SPKF MUST NOT invent a new proof calculus.

For PSCV:

~~~text
SPKF
    transports
canonical PSCV / PSKernel evidence
~~~

The target proof payload should eventually be a stable, fully elaborated Core export suitable for PSKernel and independent checkers.

Current canonical admission payloads may be transported as candidate material, but AdmissionReady data MUST NOT become checked evidence merely because it was packaged in SPKF.

Only successful kernel replay establishes that authority.


---

# 16. Authority graph must be acyclic

Content-addressed objects cannot directly hash cyclic references.

Therefore authority-bearing SPKF references MUST form a DAG.

Mutually recursive semantic declarations are represented inside one canonical bundle.

~~~text
mutually recursive declarations
        |
        v
one semantic bundle
        |
        v
one SPKF object ID
~~~

If package-level semantic dependencies form a true cycle, the relevant profile must either:

- normalize the strongly connected component into one semantic bundle; or
- reject the cycle.

No verifier may resolve a hash cycle by trusting mutable external names.

---

# 17. Typed relationship vocabulary

Initial relationship types:

~~~text
imports
extends
proves
discharges
refines
implements
preserves
assumes
validates
benchmarks
conforms-to
binds-distribution
derived-from
generalizes
specializes
replaces
compatible-with
~~~

Unknown relation types MAY be preserved as opaque extension data.

Unknown relation types MUST NOT establish semantic authority.

---

# 18. Knowledge portability classes

Not all knowledge has equal reuse value.

## K0 — Foundation

Examples:

- logical metatheory;
- generic algebraic results.

## K1 — Semantic

Target-independent PSCV definitions/specifications/theorems.

Example:

~~~text
map preserves length
~~~

## K2 — Capability

Knowledge over abstract effects/capabilities.

Example:

~~~text
transaction preserves conservation under TransactionEffectModel
~~~

## K3 — Backend

Backend-specific semantic preservation.

Example:

~~~text
VerifiedIR to Wasm preserves observable result
~~~

## K4 — Ecosystem adapter

Examples:

- Node adapter;
- Rust crate mapping;
- Python wrapper;
- JVM binding;
- PHP binding.

## K5 — Deployment

Examples:

- benchmark on hardware H;
- service SLA;
- runtime observation.

SAVEF search/generalization SHOULD prefer K0-K2 when the task can be stated at that abstraction level.

---

# 19. ImplementationWitness

One theory can have multiple executable witnesses.

Concept:

~~~json
{
  "schema": "spkf/1",
  "kind": "implementation-witness",

  "subjectTheory": {
    "spkf": "spkf-v1:sha256:..."
  },

  "implementation": {
    "artifact": "spkf-blob-v1:sha256:..."
  },

  "target": {
    "kind": "wasm-component"
  },

  "relation": "implements",

  "evidence": {
    "spkf": "spkf-v1:sha256:..."
  }
}
~~~

The witness object is a claim container.

Referenced evidence determines whether the claimed relation is accepted.

---

# 20. Two implementation lanes

Cross-ecosystem feasibility improves substantially if SPKF supports two lanes.

## 20.1 Native ecosystem implementation

Examples:

~~~text
JavaScript
Rust
Python
JVM
PHP
~~~

Benefits:

- idiomatic ecosystem integration;
- potentially best performance;
- native debugging/tooling.

Costs:

- each target semantic path requires its own evidence model;
- complete formal refinement may be expensive.

## 20.2 Portable Wasm Component implementation

Near-term strategy:

~~~text
PSCV theory
    |
    v
Certified PSCV implementation
    |
    v
VerifiedIR
    |
    v
preserved Wasm
    |
    v
Wasm Component / WIT boundary
    |
 +--+-------+--------+--------+
 |          |        |        |
JS        Rust     Python    other hosts
~~~

The Wasm Component Model provides language-neutral interfaces through WIT and a Canonical ABI for passing rich values between components.

WIT describes API shape, not behavior.

SPKF supplies behavioral specifications/theorems.

This lane lets one strong PSCV-to-Wasm preservation result support many host ecosystems while native backends mature separately.

Source:
https://component-model.bytecodealliance.org/

---

# 21. Why WIT complements SPKF

WIT can describe:

~~~text
parse: bytes -> result json parse-error
~~~

SPKF can additionally establish:

~~~text
parse is deterministic
parse never reads out of bounds
successful parse satisfies JsonGrammar
~~~

Therefore:

~~~text
WIT
    language-neutral interface

SPKF
    behavior/specification/proof knowledge
~~~

The two systems solve different problems.

---

# 22. DistributionBinding

DistributionBinding maps an SPKF semantic/implementation object to an ecosystem artifact.

Concept:

~~~json
{
  "schema": "spkf/1",
  "kind": "distribution-binding",

  "subject": {
    "spkf": "spkf-v1:sha256:..."
  },

  "package": {
    "purl": "pkg:npm/%40proofscript/json@3.2.0"
  },

  "artifactIntegrity": {
    "algorithm": "sha512",
    "digest": "..."
  },

  "embeddedLocator": "proofscript/savef.json"
}
~~~

PURL identifies the package coordinate.

Artifact integrity identifies exact package bytes where available.

The distribution binding does not define theorem truth.

---

# 23. npm mapping

Recommended npm carrier:

~~~text
package.json
proofscript/savef.json
~~~

Example package.json fragment:

~~~json
{
  "name": "@proofscript/json",
  "version": "3.2.0",

  "proofscript": {
    "savef": {
      "root": "spkf-v1:sha256:...",
      "locator": "./proofscript/savef.json"
    }
  }
}
~~~

The custom field is a locator only.

Ordinary npm consumers do not need SPKF-aware tooling.

---

# 24. Cargo mapping

Cargo explicitly provides package.metadata for external tools.

Recommended:

~~~toml
[package.metadata.savef]
root = "spkf-v1:sha256:..."
locator = "savef.json"
~~~

The .crate archive MAY include a compact locator and CertifiedModuleInterface.

Full evidence MAY live in OCI or another mirror.

Source:
https://doc.rust-lang.org/cargo/reference/manifest.html

---

# 25. PyPI mapping

Python core project metadata has a fixed set of standard fields.

SPKF should not require a custom core metadata field.

Recommended:

1. include savef.json in the wheel/sdist;
2. optionally use a Project-URL label such as SAVEF for discovery;
3. bind the exact wheel/sdist digest through DistributionBinding.

Example:

~~~toml
[project.urls]
SAVEF = "https://example.org/savef/spkf-v1-sha256-..."
~~~

Project-URL labels may be custom free text.

The URL is discovery metadata.

The SPKF digest is identity.

Sources:
https://packaging.python.org/en/latest/specifications/core-metadata/
https://packaging.python.org/en/latest/specifications/well-known-project-urls/

---

# 26. Composer mapping

Composer permits arbitrary tool data in the extra field.

Recommended:

~~~json
{
  "extra": {
    "savef": {
      "root": "spkf-v1:sha256:...",
      "locator": "savef.json"
    }
  }
}
~~~

Source:
https://getcomposer.org/doc/04-schema.md

---

# 27. Maven mapping

Maven supports attached/classified secondary artifacts.

Recommended options:

- embed META-INF/savef.json in the main JAR;
- attach a compact artifact with classifier savef;
- attach heavyweight evidence separately with classifier savef-evidence.

Example:

~~~text
org.proofscript:json:3.2.0
org.proofscript:json:3.2.0:savef
~~~

Sources:
https://maven.apache.org/plugins/maven-jar-plugin/examples/attached-jar.html
https://maven.apache.org/plugins/maven-deploy-plugin/examples/deploying-with-classifiers.html

---

# 28. GitHub mapping

GitHub can serve three distinct roles.

## Source

Git repository stores human-authored source/review/history.

## Immutable releases

A release MAY archive:

- SPKF root bundle;
- knowledge snapshots;
- independent verification bundles.

GitHub immutable releases lock associated tags and assets after publication and generate release attestations.

Source:
https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases

## GHCR

GitHub Container Registry can act as the first public OCI mirror for SPKF objects.

No custom SAVEF registry is required for an MVP.

---

# 29. Preferred OCI mapping

SPKF-v1 recommends OCI Image Manifest 1.1 artifact usage.

Provisional vendor media types:

~~~text
application/vnd.proofscript.savef.knowledge.v1+json
application/vnd.proofscript.savef.theory-extension.v1+json
application/vnd.proofscript.savef.implementation.v1+json
application/vnd.proofscript.savef.backend-evidence.v1+json
application/vnd.proofscript.savef.distribution-binding.v1+json
application/vnd.proofscript.savef.advisory.v1+json
~~~

These names should be reviewed/registered before being frozen as a public standard.

---

# 30. OCI subject/referrers rule

When subject and extension are stored in the same OCI repository, an extension SHOULD additionally use OCI subject/referrers.

However SPKF semantic subject identity MUST remain inside the canonical SPKF object.

Reason:

- OCI subject is repository-local;
- SPKF subjects may be mirrored across repositories/registries;
- the same SPKF object may be packaged by different OCI manifests.

Therefore:

~~~text
OCI subject
    mirror-local discovery optimization

SPKF subject ID
    portable semantic relationship
~~~

This is a critical portability rule.

---

# 31. Cross-registry discovery

A search service may maintain:

~~~text
SPKF root
    -> known mirrors
    -> known extensions
    -> known implementation witnesses
    -> known distribution bindings
~~~

The search service is disposable.

If it disappears:

- SPKF IDs still resolve from mirrors;
- package locators still identify roots;
- snapshots can rebuild indexes;
- proofs remain independently replayable.

---

# 32. Mirror protocol

Conceptual command:

~~~text
psc knowledge mirror <root>
~~~

A mirror operation should:

1. fetch root;
2. recompute root ID;
3. traverse required authority-bearing references within explicit limits;
4. verify every object/blob ID;
5. store immutable local objects;
6. optionally fetch selected extensions/implementations;
7. emit mirror inventory.

Mirror policies may select:

- theory only;
- full proof evidence;
- specific ecosystems;
- advisory knowledge;
- snapshots.

---

# 33. Offline verification

Target:

~~~text
psc knowledge fetch --closure <root>
psc knowledge verify --offline <root>
~~~

A release-critical closure should be verifiable without live registry access after required objects are fetched.

This supports:

- reproducibility;
- air-gapped use;
- disaster recovery;
- archival research;
- long-term theorem replay.

---

# 34. Knowledge snapshots

SnapshotIndex may represent a curated ecosystem state:

~~~text
SAVEF Snapshot
    |
    +-- theory roots
    +-- selected canonical theorem extensions
    +-- distribution bindings
    +-- checker profiles
~~~

Snapshots can be distributed through:

- OCI;
- GitHub immutable releases;
- institutional archives;
- object stores;
- offline media.

Snapshot signatures establish curation/provenance, not theorem validity.

---

# 35. Build/cache integration

SPKF should integrate with ProofScript's existing CAS/BuildAction model.

Nix demonstrates content-addressed outputs and build derivations over precise inputs.

Bazel Remote Execution separates:

- ContentAddressableStorage for immutable blobs;
- ActionCache mapping deterministic Action IDs to results.

ProofScript already plans equivalent concepts.

Recommended:

~~~text
BuildActionId
    ->
CheckedCoreArtifact
CertifiedModuleInterface
VerifiedIR
backend artifact
SPKF root
~~~

SPKF objects MAY reference existing ProofScript artifact IDs.

The build cache remains an accelerator rather than semantic authority.

---

# 36. Provenance model

Separate semantic truth from supply-chain origin.

~~~text
PSCV / PSKernel
    checks semantic claims

in-toto / SLSA
    authenticates claims about how artifacts were produced
~~~

An in-toto Statement MAY bind an SPKF digest or distribution artifact digest as subject.

SLSA provenance MAY record:

- source repository;
- commit;
- builder identity;
- build inputs;
- output digests.

None of this proves a program theorem.

---

# 37. SPDX integration

SPKF SHOULD emit/reference SPDX where useful.

Possible mappings:

~~~text
SPKF implementation
    -> SPDX SoftwareArtifact

DistributionBinding PURL
    -> SPDX ExternalIdentifier

SPKF digest
    -> SPDX contentIdentifier

selected artifact relations
    -> SPDX Relationship
~~~

Do not encode PSCV proof calculus into SPDX.

---

# 38. Licensing

Free distribution requires explicit rights.

Every public KnowledgeRoot or TheoryExtension SHOULD state:

- SPDX license expression;
- authorship/provenance reference;
- source project;
- optional notice/attribution.

A theorem derived while working with a package is not automatically redistributable under arbitrary terms.

Mirrors must respect object licensing and policy.

---

# 39. Curation and theorem spam

Logical validity is not usefulness.

An open graph may accumulate:

- duplicate lemmas;
- highly specialized lemmas;
- AI-generated low-value facts;
- misleading titles;
- redundant implementation witnesses.

SPKF therefore separates:

## Accepted

Evidence is semantically valid.

## Indexed

Object meets index metadata/resource policy.

## Canonical

Curator/factory recommends this abstraction as preferred reusable knowledge.

Canonical status affects search ranking only.

It does not create proof authority.

---

# 40. Generalization workflow

Suppose many extensions prove similar local facts.

The factory may propose a generalized theorem G.

Process:

1. generate G statement;
2. generate proof;
3. PSKernel checks proof;
4. publish G as immutable extension;
5. index records G generalizes older facts;
6. search prefers G when appropriate.

Old objects remain immutable.
