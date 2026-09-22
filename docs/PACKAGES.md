# Package architecture

pskernel should remain a small trusted-kernel project. Supporting npm packages
must sit **outside** the trusted computing base unless explicitly documented.

## Package layers

### 1. Kernel library — trusted

Current repository/root package.

Public entry points:

- `lean-ts-kernel` — stable high-level kernel API
- `lean-ts-kernel/lean4export` — version-pinned replay boundary
- `lean-ts-kernel/native` — optional native-evaluator interface only

Support packages should not import arbitrary `src/kernel/**` implementation
files. The public façade exists to prevent accidental coupling to internal
checker structure.

A future publish may rename the package (for example to a ProofScript-owned
npm scope), but the API boundary should stay the same.

### 2. CLI — untrusted support layer

Planned package: `pskernel-cli`.

Responsibilities:

- stream replay/check of Lean4export NDJSON
- machine-readable JSON result output
- resource/progress reporting
- no parser/elaborator/compiler semantics
- no bypass around kernel declaration admission

The CLI can fail, crash, or misreport progress without making an invalid proof
valid; the kernel library remains the authority.

### 3. Lean4export tooling — untrusted transport layer

Future package: `pskernel-lean4export`.

Responsibilities:

- launch the pinned Lean exporter
- stream NDJSON into the kernel
- corpus/module orchestration
- version/fingerprint checks

Exporter logic is compatibility/oracle infrastructure, not trusted kernel
semantics.

### 4. Conformance/Arena tooling — test-only

Future package: `pskernel-conformance`.

Responsibilities:

- Lean Kernel Arena execution
- differential oracle orchestration
- adversarial suites
- corpus manifests/reports

This package must never be imported by the trusted kernel.

### 5. Native IR provider — optional TCB extension

Future package: `pskernel-native-ir`.

This is intentionally separate because implementing `Lean.reduceNat` /
`Lean.reduceBool` through compiler IR expands the trusted computing base.
The normal kernel remains fail-closed when no provider is configured.

### 6. Browser/worker wrapper — untrusted host layer

Future package: `pskernel-browser`.

Responsibilities may include Web Workers, stream transport, persistence, and
browser-friendly APIs. It must depend on the same stable kernel façade rather
than fork kernel semantics.

## Dependency direction

```text
                 pskernel-conformance
                        |
                        v
pskernel-cli --> kernel public API <-- pskernel-browser
                        ^
                        |
               pskernel-lean4export

pskernel-native-ir ----> NativeEvaluator interface
       (optional TCB extension)
```

Nothing in the kernel package may depend on CLI, conformance, exporter process
management, browser hosting, or a native provider implementation.

## Current rule during Lean 4.34 certification

Do not physically split `src/core` and `src/kernel` while Full Std is still
being certified. Package extraction should occur around the stable façade,
not by moving trusted source files between packages.

The root package remains `private: true` until release/versioning/licensing
decisions are explicit. Support packages may be developed privately in this
repository in the meantime.
