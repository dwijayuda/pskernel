# ProofScript trust and security model

**Status:** forward security architecture. This document defines the threat model and target authority boundaries. It does not claim all controls are implemented today.

## 1. Security objective

ProofScript should allow large, useful, partially untrusted ecosystems while keeping semantic authority small.

Security rule:

> Large components may propose results; small authorities decide whether those results enter trusted semantic or release state.

## 2. Trust zones

### 2.1 Untrusted or potentially buggy

Treat these as untrusted for foundational soundness:

- source text and dependencies;
- parser/resolver convenience;
- elaboration heuristics;
- tactics, `simp`, deriving, macros;
- AI-generated code/proofs;
- external solvers;
- third-party plugins;
- optimizer implementations when separately validated;
- package registries;
- remote build caches;
- CI workers;
- backend heuristics;
- npm/Rust ecosystem adapters.

A bug here may cause rejection, diagnostics, wrong candidate output, or build failure, but must not gain authority to forge CheckedCore or validated artifacts.

### 2.2 Small authorities

Target trusted/formally justified set:

- PSC Core rules/semantics;
- designated kernel provider under the frozen kernel contract (currently the pinned `pskernel-lean-wasm`; long-term target `pskernel-core`);
- CheckedCore construction boundary;
- ErasedIR/VerifiedIR validator;
- proved transformations or small translation validators;
- artifact canonicalization/hash verifier;
- capability host policy;
- package signature/provenance verifier;
- minimal evidence/certificate verifier.

### 2.3 External assumptions

State these explicitly rather than pretending PSC proves them:

- JS engine;
- Wasm engine/validator;
- OS;
- hardware;
- Lean/rustc/tsc when used as adapters;
- declared FFI implementations;
- cryptographic primitives.

## 3. Authority invariants

1. No frontend/plugin/tactic API constructs a CheckedCore value.
2. No backend consumes arbitrary elaborated declarations.
3. Erasure accepts only the checked authority boundary in the production pipeline.
4. No optimizer can replace mandatory IR without a proof or configured validator.
5. No package/plugin receives filesystem/network/process authority unless declared.
6. No remote cache result is trusted without content verification.
7. No incompatible contract version is silently coerced.
8. No unsupported semantic case falls back to a weaker backend behavior.

## 4. Threat model

| Threat | Required defense |
| --- | --- |
| malicious source causes parser/elaborator/kernel DoS | explicit `CompilationBudget` |
| deep recursive terms exhaust host stack/resources | bounded iterative/fuel workers where needed |
| malicious package executes during compile | no ambient compile-time execution |
| plugin reads filesystem/secrets | capability-scoped sandbox |
| plugin uses network/process unexpectedly | deny by default; explicit world/capability imports |
| plugin forges checked artifact | opaque CheckedCore authority |
| malformed kernel bridge payload | bounded canonical decoder/framing |
| replay/confused bridge response | request identity + contract/hash binding |
| dependency confusion | canonical package identity + lockfile |
| compromised dependency | digest/signature/provenance verification |
| remote cache poisoning | CAS digest verification; action identity verification |
| backend miscompilation | differential execution + proof/validator |
| optimizer miscompilation | translation validator or reject/fallback-to-unoptimized |
| compiler binary compromised | reproducibility + diverse bootstrap/DDC |
| CI compromised | signed provenance + independent rebuild |
| published artifact replaced | transparency/signature verification |
| signing key compromised | role separation/recovery metadata |
| FFI breaks claimed semantics | explicit FFI/capability contract and assumptions |
| accidental nondeterminism | hermetic build inputs + canonical ordering |
| diagnostic/log secret leakage | structured redaction policy |

## 5. Compilation budgets

Introduce one explicit `CompilationBudget` instead of scattered hidden limits.

Recommended dimensions:

```text
sourceBytes
tokenCount
astNodes
nestingDepth
moduleCount
importEdges
declarationCount
universeSteps
reductionSteps
defeqSteps
instanceSearchSteps
kernelSteps
erasureNodes
irNodes
specializationCount
generatedBytes
diagnosticCount
```

Profiles:

```text
interactive
ci
release
serverSandbox
```

Failure is explicit:

```text
ResourceLimitExceeded {
  limit
  configured
  observed
  phase
}
```

Budgets are availability/security policy. They must not change successful program semantics.

## 6. Capability security

Portable PSC code must not receive ambient host authority.

Prefer values/contracts such as:

```text
FileSystem
Network
Clock
Random
Process
Environment
Console
```

and effect-aware library abstractions such as:

```text
Result E A
Task A
Resource A
```

A capability declaration records at least:

```text
identity/version
target set
purity/effect class
sync/async
blocking/nonblocking
deterministic/nondeterministic
error model
resource behavior
cancellation behavior
thread/executor requirements
encoding/ABI profile
```

Do not add an unrestricted host `IO` escape to portable semantics merely for convenience.

## 7. Plugin sandbox

Design capability policy before a general plugin ecosystem ships.

Plugin manifest concept:

```text
plugin:
  id
  version
  kind
  pluginApi

requires:
  meta.read
  diagnostics.write

hostCapabilities:
  filesystem: none
  network: none
  process: none
  clock: none
  random: none

deterministic: true
```

Preferred execution:

1. Wasm Component/WASI sandbox for third-party semantic plugins where practical;
2. otherwise isolated worker/process with explicit RPC;
3. in-process trusted plugins only by explicit policy.

Never load arbitrary npm JavaScript into the compiler process and treat a manifest declaration as a sandbox.

## 8. Kernel bridge hardening

The existing bridge already binds protocol/version/kernel/foundation identities. Production hardening should additionally define:

- canonical request framing;
- maximum request size;
- maximum declaration/node/string/integer sizes;
- allowed operation set;
- request ID;
- timeout and fuel/budget;
- canonical response receipt;
- response artifact hash;
- explicit kernel artifact identity.

If the bridge crosses a process/trust boundary, prefer a bounded length-prefixed canonical binary protocol for production. Keep JSON as a debug/human representation.

## 9. Dependency and registry security

A locked package dependency records:

- canonical package ID;
- version;
- source;
- source digest;
- semantic manifest digest;
- interface digest;
- capability set;
- required language/contract versions.

Rules:

- `--locked` never silently resolves a newer version;
- `--offline --locked` is supported for release verification;
- registry namespace/canonical IDs prevent dependency confusion;
- downloaded artifacts are content-verified before use.

## 10. Release supply-chain controls

Recommended outer release stack:

```text
PSC evidence manifest
       |
       +-- source/artifact hashes
       +-- semantic contract versions
       +-- toolchain identities
       +-- kernel/IR/backend identities
       +-- declared assumptions
       |
       v
in-toto / SLSA-style provenance
       |
       v
public artifact signature/transparency

registry/update metadata
       |
       v
role-separated compromise-recovery metadata
```

Use standard ecosystems where possible rather than inventing proprietary outer security formats.

Candidate technologies:

- SLSA/in-toto for provenance;
- SBOM format for dependencies/artifacts;
- Sigstore for public signing/transparency;
- TUF-style metadata for registry/update compromise resilience.

These remain outside Core/kernel semantics.

## 11. Trusting-trust defense

Keep at least two bootstrap routes:

```text
                 compiler.ps
                 /        \
                /          \
      Lean/reference       self-host
             |                |
             v                v
       candidate A        candidate B
                \          /
                 \        /
             diverse bootstrap checks
```

A self-host fixed point is bootstrap stability, not a trusting-trust defense. Reproducibility and diverse double-compilation style evidence are separate release properties.

## 12. External solver and AI boundary

Preferred:

```text
goal
 -> external solver / AI / search
 -> proof term or compact certificate
 -> pskernel / small certificate checker
```

External tools do not receive theorem-admission authority.

## 13. Secure defaults

Production defaults should be:

- fail closed;
- no network during semantic compile unless explicitly requested;
- no process execution by semantic plugins;
- no ambient environment-variable semantics;
- locked dependencies in CI/release;
- canonical deterministic ordering;
- bounded diagnostics/input;
- content verification on cache/package boundaries;
- kernel/IR/backend contract mismatch = error;
- sandboxed third-party semantic plugins.

Developer convenience modes may be more permissive but must be visibly distinct from hermetic/release modes.

## 14. Security review gates

Before shipping a new authority-bearing feature, answer:

1. What capability does it gain?
2. Can it forge CheckedCore or bypass IR validation?
3. What untrusted bytes does it parse?
4. What resource limits apply?
5. Is the output canonical/content-addressed?
6. What version contract identifies it?
7. Can a remote/cache/registry attacker substitute it?
8. Can it access filesystem/network/process/secret state?
9. What independent validator/proof checks its result?
10. What release evidence records the feature and assumptions?
