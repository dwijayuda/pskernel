# SPKF Minimal Proof of Concept

**Status:** executable research PoC, not a production SPKF implementation.

This directory demonstrates the smallest useful form of the
**SAVEF Portable Knowledge Format** idea:

1. one registry-independent semantic KnowledgeRoot;
2. two different package ecosystems pointing to the same root;
3. one third-party TheoryExtension targeting the immutable root;
4. content integrity for the extension's proof-source payload;
5. canonical object-key ordering;
6. semantic mutations changing semantic identity;
7. package/distribution-coordinate changes not changing semantic identity.

It intentionally does **not** implement the full
`PROOFSCRIPT_SAVEF_PORTABLE_KNOWLEDGE_FORMAT.md` specification.

## Files

~~~text
spkf-poc/
├── theory.json
├── extension.json
├── proof/
│   └── Identity.lean
├── bindings/
│   ├── npm.json
│   └── cargo.json
├── verify.mjs
├── package.json
└── README.md
~~~

## The tiny theory

`theory.json` describes only:

~~~text
identityNat : Nat -> Nat

specification:
    forall x : Nat,
      identityNat x = x
~~~

Its PoC semantic identity is:

~~~text
spkf-poc-v0:sha256:fb24f3a56242051134f95ef4036d5c985f3c7d085602e738f825c96764c6afe6
~~~

The identity is derived only from canonical semantic content.

It contains no npm package name and no Cargo crate name.

## Two distributions, one theory

The npm binding points to:

~~~text
pkg:npm/%40proofscript/spkf-poc-identity@0.0.1
~~~

The Cargo binding points to:

~~~text
pkg:cargo/proofscript-spkf-poc-identity@0.0.1
~~~

Both bind to the exact same SPKF root:

~~~text
                          KnowledgeRoot
                         spkf:fb24...
                             /    \
                            /      \
                           v        v
                    npm binding   Cargo binding
~~~

This is the central portability property.

The package coordinate is not the theorem/theory identity.

## Third-party theorem extension

`extension.json` targets the immutable KnowledgeRoot and contributes the theorem:

~~~text
forall x : Nat,
    identityNat x = x
~~~

The proof source is `proof/Identity.lean`:

~~~lean
def identityNat (x : Nat) : Nat := x

theorem identityNat_spec (x : Nat) : identityNat x = x := by
  rfl
~~~

Its proof-source blob ID is:

~~~text
spkf-poc-blob-v0:sha256:f4f6c65555c95780b0b236bb1ac1f8826503465a58e6f2079b68f1f04ba1c02a
~~~

The extension binds to that exact source blob.

**Important:** the PoC labels this payload
`candidate-source-only`.

The Node verifier checks content identity.

It does **not** perform Lean/PSKernel proof replay.

## Run

From this directory:

~~~bash
npm test
~~~

or:

~~~bash
node verify.mjs
~~~

The script has no third-party dependencies.

## Verified output from the PoC

~~~text
SPKF_POC: PASS
knowledgeRoot=spkf-poc-v0:sha256:fb24f3a56242051134f95ef4036d5c985f3c7d085602e738f825c96764c6afe6
proofSourceBlob=spkf-poc-blob-v0:sha256:f4f6c65555c95780b0b236bb1ac1f8826503465a58e6f2079b68f1f04ba1c02a
theoryExtension=spkf-poc-v0:sha256:5ec6ad68b1f6b9ca22c9afd7d0c3596b8f270dff7a9b705793efbff4d96a9566
npm=pkg:npm/%40proofscript/spkf-poc-identity@0.0.1
cargo=pkg:cargo/proofscript-spkf-poc-identity@0.0.1
registryIndependentSubject=PASS
keyOrderIndependence=PASS
semanticMutationChangesId=PASS
proofSourceIntegrity=PASS
kernelReplay=NOT_RUN_BY_THIS_FORMAT_POC
~~~

## What the verifier proves about the PoC

### 1. Registry-independent identity

Both bindings must target the same KnowledgeRoot.

Changing:

~~~text
npm package name/version
~~~

does not change:

~~~text
KnowledgeRoot ID
~~~

### 2. Semantic sensitivity

The script changes:

~~~text
identity.nat
~~~

to:

~~~text
identity.nat.changed
~~~

and requires the KnowledgeRoot ID to change.

So distribution metadata is outside semantic identity, while semantic content is inside it.

### 3. Canonical key ordering

The script reconstructs the same object with object keys inserted in reverse order.

The resulting ID must remain identical.

### 4. Proof-source integrity

The TheoryExtension contains the expected digest of
`proof/Identity.lean`.

Editing the proof source causes verification to fail until the extension is updated.

### 5. Open extension model

The extension is a separate immutable object pointing to the root.

The original KnowledgeRoot does not need to be changed in order to add the theorem evidence.

## What this PoC does NOT prove

This is deliberately important.

It does not prove:

- RFC 8785/JCS conformance;
- that `Identity.lean` has been accepted by Lean or PSKernel;
- CheckedCore production;
- PSCV-CERT closure;
- CertifiedModuleInterface generation;
- OCI/GHCR transport;
- package tarball integrity;
- Cargo crate publication;
- backend semantic preservation;
- cross-language executable equivalence;
- theorem-index curation;
- SAVEF self-amplification.

Those belong to later slices.

## Why the canonicalizer is intentionally small

`verify.mjs` uses a tiny deterministic JSON canonicalizer suitable only for these fixtures.

It accepts:

- strings;
- booleans;
- null;
- arrays;
- objects;
- safe integer JSON values.

It is **not** claimed to implement RFC 8785.

A production SPKF implementation should replace it with the restricted JCS profile specified by the research document and frozen cross-implementation test vectors.

## Next smallest slices

### PoC 1 — this directory

~~~text
portable semantic ID
+
npm/Cargo bindings
+
TheoryExtension
+
blob integrity
~~~

**Implemented here.**

### PoC 2 — kernel replay

Replace:

~~~text
candidate-source-only
~~~

with:

~~~text
canonical admission/Core evidence
    ->
KernelContract
    ->
checked evidence
~~~

This is the first step that turns the theorem payload from an integrity-bound claim into logical authority.

### PoC 3 — OCI mirror

Publish the same KnowledgeRoot and TheoryExtension through GHCR/OCI.

Then verify:

~~~text
local files
    and
OCI mirror

recover the same SPKF IDs
~~~

### PoC 4 — actual ecosystem carriers

Create tiny:

~~~text
npm package
Cargo crate
~~~

that embed/locate the same root.

No semantic duplication.

### PoC 5 — Wasm implementation witness

Attach a Wasm implementation witness to the same theory root.

That demonstrates:

~~~text
one theory
    ->
multiple executable distributions
~~~

## Success criterion

This first PoC succeeds if it makes this statement mechanically true:

> **Changing where knowledge is distributed does not change what the knowledge is; changing the semantic knowledge does.**

That is the smallest foundation needed before building the larger SAVEF cross-ecosystem knowledge network.
