# ProofScript compatibility and contract model

**Status:** forward compatibility/versioning guide. It defines how the architecture should evolve without turning unrelated changes into one global language version.

## 1. Principle

ProofScript has multiple contracts with different stability rates. Version them independently.

The source language, kernel, executable IR, FFI, plugins, package metadata, and target runtime ABI are not one thing.

## 2. Contract registry

The production system should eventually identify at least these contracts:

| Contract | Purpose | Expected change rate |
| --- | --- | --- |
| SourceLanguage | accepted source grammar/semantics | slow |
| StandardProfile | closed standard surface | slow |
| Core | kernel-facing semantic terms/declarations | very slow |
| KernelContract | admission/checking rules/provider protocol; current frozen identity `proofscript-kernel-contract/1` | extremely slow |
| CheckedCore | checked artifact schema/capability | very slow |
| ErasedIR | construction/runtime lowering IR | moderate |
| VerifiedIR | validated target-neutral executable contract; current initial contract `psc-verified-ir/1` | slow |
| RuntimeSemantics | portable observable runtime behavior; current frozen identity `psc-runtime-semantics/1` | slow |
| TargetRuntimeABI | per-target representation/calling convention | moderate |
| ModuleInterface | separate compilation/link contract | slow |
| InterfaceIR | foreign API description | moderate |
| CapabilityContract | effect/host authority vocabulary | moderate |
| PluginAPI | controlled compiler/tool extension API | moderate |
| PackageManifest | semantic package metadata | moderate |
| BuildAction | hermetic build action schema | moderate |
| EvidenceManifest | build/proof provenance schema | moderate |

## 3. Version identity

Use stable machine identities, for example:

```text
ps-source/0.9-r3
psc-core/1
psc-kernel/1
psc-checked-core/1
psc-erased-ir/1
psc-verified-ir/1
psc-runtime-semantics/1
psc-js-runtime-abi/1
psc-wasm-runtime-abi/1
psc-interface-ir/1
psc-capabilities/1
psc-plugin-api/1
psc-package-manifest/1
psc-build-action/1
psc-evidence/1
```

The identities `proofscript-kernel-contract/1`, `psc-verified-ir/1`, and `psc-runtime-semantics/1` are now frozen by their contract documents and executable guards. Other names in the example remain illustrative until separately frozen.

## 4. Compatibility rules

### Source-language changes

A pure surface desugaring may change source version without changing Core semantics.

### Core/kernel changes

Require explicit review because they affect foundational semantics and admission.

### CheckedCore changes

May change serialization/receipt shape without changing Core rules only if compatibility is explicit and kernel authority remains intact.

### VerifiedIR changes

Must preserve target neutrality. Backends declare the versions they accept.

### Runtime semantics changes

Are semantic changes and require explicit version/profile change even if all backends can be patched locally.

### Target ABI changes

Do not imply a source-language version bump. They may require package relinking/rebuild.

### InterfaceIR/plugin changes

Do not imply Core/kernel changes.

## 5. Fail-closed negotiation

Do not silently coerce incompatible contracts.

A consumer must choose one of:

```text
exactly supported
explicitly migrated by a versioned converter
rejected
```

Every converter itself has:

- source version;
- destination version;
- deterministic identity;
- validation/tests/proof classification.

## 6. Compatibility matrix

Packages and artifacts should be able to answer:

```text
requires:
  source >= ...
  core = ...
  kernel = ...
  checkedCore = ...
  verifiedIr = ...
  runtimeSemantics = ...
  interfaceIr = ...
  pluginApi = ...
  capabilities = ...
targets:
  js:
    runtimeAbi = ...
  wasm:
    runtimeAbi = ...
```

Avoid open-ended “compatible with latest” declarations in locked/release builds.

## 7. Runtime semantics versus target ABI

Keep `RuntimeSemantics` separate from `JsRuntimeABI`, `WasmRuntimeABI`, `LeanRuntimeABI`, and `RustRuntimeABI`.

Example:

`Nat.add` has one portable semantic contract. JS may represent Nat using BigInt or a runtime object; Wasm may use GC structures; Lean/Rust adapters may use their own runtime representations. Those implementations must refine the same portable behavior.

## 8. InterfaceIR compatibility

InterfaceIR describes external APIs, not PSC executable semantics.

It may carry:

- source ecosystem identity;
- ABI/version profile;
- ownership/borrowing;
- resources/handles;
- sync/async/stream/future;
- errors;
- capability/effect requirements;
- target availability.

Generated PSC bindings must record the InterfaceIR identity they were derived from.

If authoritative foreign metadata exists, adapters must not silently invent a different signature.

## 9. Capability contract

Capability identities are explicit, for example:

```text
psc.cap.fs.read/v1
psc.cap.fs.write/v1
psc.cap.net.client/v1
psc.cap.process.spawn/v1
psc.cap.clock.monotonic/v1
psc.cap.random.secure/v1
```

A plugin/package requesting a capability declares it in semantic metadata.

Capability compatibility is not inferred from name similarity.

## 10. Plugin compatibility

Plugin manifest includes:

```text
plugin ID/version
plugin kind
PluginAPI version
Source/Core compatibility
Meta API version when used
deterministic flag
requested capabilities
target restrictions
input/output contract versions
```

Plugin classes remain distinct:

- syntax/desugaring;
- derive/code generation;
- meta/tactic;
- backend;
- tooling.

No plugin API grants kernel admission authority.

## 11. Module interface contract

A module interface must include all information that can affect downstream semantics, including:

- exported declarations/types;
- public structures/inductives;
- instances and their exact ordering metadata where relevant;
- public theorem/declaration identities where downstream behavior depends on them;
- capabilities;
- runtime ABI requirements;
- import interface identities.

If an implementation changes but this canonical interface is unchanged, dependents may remain green.

## 12. Package compatibility

Package compatibility is the intersection of:

```text
language compatibility
semantic contract compatibility
module-interface compatibility
capability compatibility
target/runtime ABI compatibility
toolchain/platform policy
```

Do not reduce package compatibility to semver alone.

## 13. Target-neutrality rules

Core and VerifiedIR must not acquire:

- JavaScript `number`/prototype/object conventions;
- TypeScript structural typing;
- Rust lifetimes/borrowing/container policy;
- Wasm opcodes/value types/GC layout;
- WIT/WASI type-layout policy;
- npm package-resolution semantics;
- OS file/process/network semantics.

If a target needs such information, introduce target IR, InterfaceIR, ABI profile, or host capability below/around the portable boundary.

## 14. Migration policy

Before changing a frozen contract:

1. write the incompatibility/use case;
2. show why a library/adapter/plugin cannot solve it;
3. define old/new versions;
4. define whether conversion is possible;
5. add compatibility tests;
6. update semantic/package manifests;
7. update lockfile/tooling behavior;
8. update assurance classification;
9. preserve old reader support only if its cost is justified;
10. never silently reinterpret old bytes under a new semantic version.

## 15. Contract documentation template

Every frozen contract should eventually state:

```text
Name / version
Status
Owners
Purpose
Invariants
Canonical encoding
Hash domain
Inputs
Outputs
Failure modes
Compatibility policy
Security/resource limits
Proof/validator status
Reference implementation
Conformance tests
Change procedure
```

## 16. Anti-drift rules

1. Language version is not package-manifest version.
2. Core version is not kernel-provider implementation version.
3. Runtime semantics are not target ABI.
4. VerifiedIR is not InterfaceIR.
5. Plugin API is not Meta API and neither is kernel authority.
6. Package semver does not replace semantic contract identities.
7. A converter is an explicit transformation with its own assurance classification.
8. Unknown/incompatible versions reject in locked/release mode.
