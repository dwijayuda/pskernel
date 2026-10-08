# PSC2 Lean 4.34 kernel provider integration contract

This document defines the semantic and host boundary between the PSC2 self-host compiler and `packages/pskernel-lean`.

It complements:

- `README.md` — provider purpose and status;
- `BUILDING.md` — how to build/run it;
- `LEAN_SOURCE_PIN.json` — machine-readable Lean identity.

## 1. Design rule

The PSC2 semantic compiler must not depend directly on Lean C++ APIs, Lean runtime object layouts, or the provider process implementation.

The integration boundary is:

```text
PSC source
  -> PSC parser / resolver / elaborator
  -> canonical PSC declarations
  -> canonical checked-admissions v2 text
  -> KernelProvider host boundary
  -> accept / reject
```

For the current `lean434` provider:

```text
canonical admissions v2
  -> native pskernel-lean process
  -> decode to PSC Core values
  -> map to Lean semantic values
  -> Lean.Environment.addDeclCore
  -> response JSON
```

There is deliberately no `.lean` source generation and no Lean parser/elaborator round-trip in this verification path.

## 2. Provider identity

Current provider identity is exact:

```text
protocol:     pskernel-lean/1
provider:     lean4-cpp
profile:      lean4.34-core
Lean version: 4.34.0
Lean commit:  293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
```

A different Lean version or source commit is not silently interchangeable with this profile.

The host adapter validates provider identity before accepting an `accepted: true` result.

## 3. Request protocol

The provider receives one complete UTF-8 document on stdin.

Current module envelope:

```json
{
  "admissions": [],
  "format": "proofscript-checked-admissions",
  "version": 2
}
```

This is the existing PSC canonical admissions format. The provider must not invent a second semantic encoding for the same PSC declarations.

Properties:

- `format` must be exactly `proofscript-checked-admissions`;
- `version` must be numeric `2`;
- declaration order is preserved;
- structured PSC names/levels/expressions are decoded directly;
- malformed/unknown tags fail closed;
- free variables, metavariables, and unsupported Core forms fail closed;
- regular reducibility heights must round-trip exactly into Lean 4.34 `UInt32`.

## 4. Response protocol

Accepted response contains at least:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": true,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core"
}
```

Rejected response contains the same provider identity plus a stable error classification:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": false,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core",
  "errorKind": "kernel-rejection",
  "declarationIndex": 0,
  "message": "..."
}
```

`message` is diagnostic text, not a stable semantic API. `errorKind` and provider identity are the machine-facing contract.

## 5. Fail-closed classes

The host must stop on all of these:

- provider binary cannot start;
- provider exits non-zero;
- stdout is empty or not exactly parseable as the expected response;
- wrong protocol;
- wrong provider identity;
- wrong Lean version;
- wrong Lean source commit;
- wrong provider profile;
- malformed canonical request;
- unsupported PSC Core form;
- prelude reconstruction failure;
- kernel rejection;
- provider internal error.

No class above may be converted to an implicit acceptance or warning-only result.

## 6. Prelude/trust policy

The caller does not supply the trusted prelude.

The provider owns reconstruction of `psSelfHostProdPreludeEnvironment` and starts from:

```text
Lean.mkEmptyEnvironment 0
```

Every declaration installed into the provider environment is checked through the Lean kernel.

The PSC prelude currently contains forward references, so reconstruction is dependency-aware:

1. attempt pending declarations;
2. accept declarations the kernel admits;
3. defer only `unknownConstant` failures;
4. fail immediately on other kernel errors;
5. repeat while progress exists;
6. fail if unresolved declarations remain without progress.

This is scheduling only. It does not bypass Lean admission.

## 7. Inductive ownership

PSC environment metadata may contain entries for an inductive declaration, its constructors, and generated recursor metadata.

Lean kernel inductive admission owns generation/registration of constructor and recursor constants. The provider must not re-admit those generated constants independently after admitting the parent inductive block.

This rule avoids duplicate declaration acceptance and semantic drift.

## 8. Host boundary

Current Node adapter is:

```text
packages/pskernel-lean/host/node-provider.mjs
```

Logical interface:

```text
checkCanonicalAdmissions(source, options?) -> provider response
```

Execution mechanism today:

```text
Node host
  -> spawn native executable with --check
  -> write canonical admissions to stdin
  -> read one JSON response
```

The public semantic boundary is text/bytes. Callers must not depend on Lean C++ pointers, `lean_object` representation, or C++ class layouts.

`PSC_LEAN_KERNEL_PROVIDER_BIN` may override the default native binary location without changing the semantic contract.

## 9. Generated PSC2 compiler integration

The generated PSC2 compiler exposes canonical admissions for a flattened project. Host orchestration then checks those admissions before optional code generation.

Current check path:

```text
psc check Main.ps --kernel lean434
```

Current gated build path:

```text
psc build Main.ps --out Main.js --kernel lean434
```

Required ordering for the gated build:

```text
flatten project
  -> generated compiler canonical admissions
  -> selected kernel provider
  -> if accepted only: TypeScript generation / compilation
```

If the provider rejects, no requested JS/TS output should be created.

## 10. Fixed-point isolation

The current Lean provider is **not** part of the first PSC2 bootstrap/fixed-point closure.

`pskernel-lean` is explicitly forbidden by `bootstrap-closure-contract.mjs`.

Therefore:

- normal bootstrap must not require the provider binary;
- normal fixed-point must not require the provider binary;
- compiler Lean imports must not import provider code;
- portable workspace package dependencies must not depend on `pskernel-lean`;
- `--kernel lean434` is an explicit host-selected assurance path.

This preserves the goal that PSC2 can progress toward its own self-hosted kernel rather than making the Lean provider a permanent hidden dependency.

## 11. Current trust statement

An accepted response means:

> The canonical PSC declarations submitted to this provider were accepted by the pinned Lean 4.34 kernel path on top of the provider-owned reconstructed PSC2 prelude.

It does **not** mean:

- all Lean 4 frontend behavior is reproduced;
- PSC and Lean are proven fully equivalent;
- PSC's future self-host kernel is proven equivalent to Lean;
- every Lean runtime/native reduction mechanism is supported;
- the current portable compiler erasure boundary already consumes a provider-neutral `CheckedCore`.

Do not make any stronger claim without separate evidence.

## 12. Next provider-neutral compiler seam

The desired later architecture is:

```text
AdmissionReadyModule
      |
      v
KernelProvider.check
      |
      v
CheckedModule / CheckedCore
      |
      v
erasure
      |
      v
VerifiedIR
```

`CheckedModule` should be non-forgeable through ordinary compiler APIs and carry enough identity/evidence to state which provider/profile checked the canonical Core.

The current host-only `lean434` gate is intentionally a step toward that architecture, not a fake replacement for it.

## 13. KLP4: dual/differential checking

Follow-up provider mode:

```text
canonical PSC Core
      |
   +--+------------------+
   |                     |
   v                     v
PSC self-host kernel   Lean 4.34 provider
   |                     |
   +----------+----------+
              |
          compare result
```

Desired CLI eventually:

```text
--kernel psc
--kernel lean434
--kernel dual
```

`dual` must fail on disagreement. It should record enough normalized diagnostic information to turn each disagreement into a regression fixture.

Do not implement `dual` by accepting when either checker succeeds.

## 14. KLP5: standalone C++ / WASM execution

The copied Lean source trees under this package are retained for a later provider execution mechanism:

```text
kernel/
runtime/
util/
```

The standalone provider should preserve the same logical request/response contract.

Preferred ABI shape is bytes-only, conceptually:

```c
int psc_kernel_init(void);
int psc_kernel_check(
  const uint8_t *input,
  size_t input_len,
  uint8_t **output,
  size_t *output_len
);
void psc_kernel_free(void *ptr);
```

Do not expose Lean C++ classes or runtime object pointers as the stable PSC API.

Recommended sequence:

1. build a standalone native executable/library from the exact pinned source/dependency closure;
2. make it pass the existing canonical provider fixtures;
3. keep the Node adapter contract unchanged;
4. compile the same narrow bridge to WebAssembly/Emscripten;
5. add a WASM adapter behind the same `KernelProvider` semantics;
6. differential-test native official-toolchain provider vs standalone native vs WASM provider.

The execution mechanism may change. The checked semantic payload should not.
