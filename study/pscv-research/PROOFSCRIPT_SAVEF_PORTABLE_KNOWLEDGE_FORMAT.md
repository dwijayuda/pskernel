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
