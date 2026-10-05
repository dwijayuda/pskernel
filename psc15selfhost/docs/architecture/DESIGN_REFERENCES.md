# ProofScript production architecture design references

**Status:** research guide. These references influence architecture decisions; none is a semantic dependency or blanket endorsement.

## 1. Verified compilers and formal semantics

### CompCert

Reference: https://compcert.org/

Use for:

- adjacent/pass-by-pass semantic preservation;
- small trusted semantic layers;
- validators for difficult transformations;
- separate compilation/linking as a real correctness topic;
- distinguishing compiler correctness from bootstrap provenance.

Do not copy its source language or backend architecture literally.

### CakeML

Reference: https://cakeml.org/

Use for:

- multiple explicit intermediate languages;
- end-to-end verified compiler architecture;
- verified/self-bootstrapped compiler as a long-term precedent;
- disciplined separation of semantics and implementation.

### Software Foundations

Reference: https://softwarefoundations.cis.upenn.edu/

Use for:

- mechanized operational semantics;
- type soundness/progress/preservation patterns;
- compiler correctness proof engineering.

### Types and Programming Languages / Practical Foundations for Programming Languages

Use for:

- separating syntax, static semantics, dynamic semantics, and representation;
- avoiding accidental host-language semantic leakage.

## 2. Conventional compiler engineering

### Engineering a Compiler

Use for:

- IR design;
- pass boundaries;
- data-flow analysis;
- code-generation architecture;
- phase-local invariants.

PSC should combine conventional compiler engineering with smaller verified/validated boundaries rather than treating formal verification as a substitute for normal compiler design.

## 3. Incremental and build-system design

### rustc incremental compilation

Reference: https://rustc-dev-guide.rust-lang.org/queries/incremental-compilation.html

Use for:

- dependency queries;
- input/result fingerprints;
- red/green invalidation;
- preserving downstream green state when recomputation produces the same semantic result.

The current resident self-host red/green cache is already an early PSC-specific application of this principle.

### Build Systems à la Carte

Reference: https://www.microsoft.com/en-us/research/publication/build-systems-la-carte/

Use for:

- separating dependency discovery, scheduling, rebuild policy, and storage;
- avoiding one monolithic “build system” abstraction.

### Bazel hermeticity and remote caching

References:

- https://bazel.build/basics/hermeticity
- https://bazel.build/remote/caching

Use for:

- explicit action inputs;
- toolchain identity;
- content-addressable storage;
- action cache versus CAS separation;
- safe remote cache design;
- deterministic/hermetic release builds.

Do not make Bazel itself a PSC semantic dependency.

## 4. WebAssembly, interfaces, and capabilities

### WebAssembly Component Model and WIT

References:

- https://component-model.bytecodealliance.org/
- https://component-model.bytecodealliance.org/design/wit.html
- https://component-model.bytecodealliance.org/design/worlds.html

Use for:

- interface contracts separate from executable implementation;
- records/variants/results/options/resources;
- owned/borrowed resource handles;
- explicit imported/exported capability worlds;
- plugin/FFI sandbox design.

Do not make WIT the PSC portable type system. Adapt it through InterfaceIR.

### WASI

Reference: https://wasi.dev/

Use for:

- capability-oriented portable host APIs;
- sandboxed plugin/runtime execution;
- async/stream/future integration where appropriate.

## 5. Secure and reliable systems

### Building Secure & Reliable Systems

Reference: https://sre.google/books/building-secure-reliable-systems/

Use for:

- treating security and reliability as one production design concern;
- least privilege;
- compartmentalization;
- operationally meaningful failure modes.

### Reproducible Builds

Reference: https://reproducible-builds.org/docs/

Use for:

- identifying timestamp/path/locale/timezone/random/order/environment sources of nondeterminism;
- release build normalization.

## 6. Supply-chain integrity

### SLSA

Reference: https://slsa.dev/spec/v1.2/

Use for:

- source/build provenance concepts;
- release verification vocabulary;
- builder identity and build inputs.

### in-toto

Reference: https://in-toto.io/

Use for:

- signed statements about supply-chain steps;
- composing PSC evidence into standard provenance envelopes.

### Sigstore

Reference: https://docs.sigstore.dev/about/overview/

Use for:

- public artifact signing;
- identity-bound ephemeral signing;
- transparency-log verification.

### The Update Framework

Reference: https://theupdateframework.io/

Use for:

- registry/update metadata;
- key compromise resilience;
- role separation and recovery.

## 7. Trusting-trust defense

### Diverse Double-Compiling

Reference: https://dwheeler.com/trusting-trust/

Use for:

- distinguishing self-host fixed points from source/binary provenance;
- preserving the Lean/reference route as an independent bootstrap input;
- designing stronger diverse-bootstrap release evidence.

## 8. How to use these references

For every architectural proposal, classify what is being borrowed:

```text
semantic principle
verification technique
build-system pattern
security pattern
interface pattern
release/provenance pattern
```

Do not import unrelated machinery merely because a reference system is successful.

The target remains a ProofScript-owned architecture with:

- Lean-faithful source/Core semantics;
- small kernel authority;
- checked/validated intermediate artifacts;
- direct JS/Wasm portable backends;
- capability-scoped ecosystem integration;
- deterministic self-host and release evidence.
