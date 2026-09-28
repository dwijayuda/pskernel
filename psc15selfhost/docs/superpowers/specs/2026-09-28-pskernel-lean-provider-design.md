# PSC2 Lean 4.34 Kernel Provider Design

Status: approved conversational design captured for written review before implementation.

Date: 2026-09-28

Branch: `psc2/pskernel-lean-provider`

Base branch: `psc2/minimal-selfhost-psc15`

## Purpose

Turn `psc15selfhost/packages/pskernel-lean/` into a real Lean 4.34-backed kernel provider that can check the canonical dependent Core produced by the PSC2 compiler before erasure.

The provider is an external assurance/runtime component. It must not become a dependency of the minimal PSC2 compiler fixed point. The PSC2 compiler remains self-hostable independently of Lean, while the original Lean kernel can be selected as a reference/admission provider and later as one side of dual-kernel checking.

Success means PSC2 can produce a canonical admission request, submit it to the Lean 4.34 provider, receive a fail-closed accept/reject result from the real Lean kernel path, and only continue to erasure when the selected host policy accepts the result.

## Current state

`psc15selfhost/packages/pskernel-lean/` currently contains copied Lean 4.34 source trees:

```text
kernel/
runtime/
util/
```

These sources are not standalone. The C++ kernel depends on Lean runtime headers and on exported functions generated from Lean source, including environment and declaration constructors. Therefore the first milestone must not pretend that `kernel/ + runtime/ + util/` can simply be linked as a complete independent executable.

The PSC2 compiler currently has this semantic boundary:

```text
source
  -> parse / resolve / elaborate
  -> PsCompilerAdmissionReadyModule
  -> erasure
  -> VerifiedIR
```

`PsCompilerAdmissionReadyModule` already carries:

```text
declarations
canonicalAdmissions
```

The canonical admissions encoding is deterministic and rejects metavariables/free variables and unsupported declaration forms before a request reaches a provider.

## Architectural constraints

1. Do not add `pskernel-lean` to the minimal bootstrap/fixed-point import closure.
2. Do not make the self-hosted compiler depend on native C++, WASM, Node APIs, Lake, or an installed Lean executable.
3. Keep the compiler semantic API backend-neutral and kernel-provider-neutral.
4. Do not translate PSC Core to `.lean` source for kernel checking. The provider must consume the elaborated semantic representation encoded by the existing canonical admissions protocol.
5. Kernel checking must fail closed on malformed input, unsupported declaration kinds, protocol/version mismatch, missing prelude assumptions, provider crashes, kernel exceptions, or ambiguous results.
6. A caller must not be able to manufacture a trusted `CheckedModule` merely by presenting canonical JSON. Successful provider admission is distinct from codec validation.
7. The original Lean 4.34 semantics must remain version-pinned. Provider metadata must identify the Lean version and compatibility profile.
8. Native provider support comes first. WASM reuses the same logical protocol after native semantic mapping is validated.
9. Keep copied upstream Lean source changes minimal and isolated. Prefer adapters/wrappers over rewriting upstream kernel internals.
10. No claim of full Lean 4 equivalence follows merely from successful checking of the PSC2 bootstrap subset.

## Recommended architecture

```text
PSC2 source
    |
    v
parser / resolver / elaborator
    |
    v
Canonical PSC Core
    |
    v
PsCompilerAdmissionReadyModule
    |
    | canonicalAdmissions
    v
Host KernelProvider boundary
    |
    +-------------------------------+
    |                               |
    v                               v
Lean434 provider                 PSC kernel provider
(native first, WASM later)       (current/future self-host kernel)
    |                               |
    +---------------+---------------+
                    |
                    v
              admission result
                    |
                    v
               CheckedModule
                    |
                    v
                  erasure
                    |
                    v
                VerifiedIR
              /     |      \
             TS    Rust    Wasm
```

The important boundary is `KernelProvider`, not Lean C++ itself. Lean is one implementation of the provider contract.

## Provider placement

The implementation lives under:

```text
psc15selfhost/packages/pskernel-lean/
```

Recommended owned additions:

```text
pskernel-lean/
├── kernel/                 # pinned upstream Lean C++ kernel source
├── runtime/                # pinned upstream Lean runtime source
├── util/                   # pinned upstream Lean utility source
├── provider/
│   ├── Main.lean
│   ├── Protocol.lean
│   ├── Codec.lean
│   └── Check.lean
├── js/
│   └── provider.mjs
├── scripts/
│   ├── build-native.mjs
│   ├── test-native.mjs
│   └── build-wasm.mjs      # introduced only after native milestone
├── test/
│   ├── accept/
│   └── reject/
├── lakefile.lean
├── lean-toolchain
├── README.md
├── BUILDING.md
└── INTEGRATION.md
```

The exact file split may be adjusted during implementation if Lean 4.34 build constraints require it, but responsibilities must stay separated: protocol, codec/mapping, kernel admission, host adapter, build tooling, and tests.

## Why native first

The copied C++ kernel has dependencies on generated Lean support functions. Building a tiny standalone C++ artifact immediately would require reconstructing that dependency closure before the PSC-to-Lean semantic mapping is even proven.

The first provider therefore uses the exact Lean 4.34 toolchain and its real checked kernel environment path. This gives the project a correctness oracle with the least semantic invention. After the request mapping is validated, the same provider can be reduced to a smaller native artifact and then cross-compiled to WASM.

The sequence is:

```text
Milestone A: native exact-Lean provider
Milestone B: reduce/capture explicit native dependency closure
Milestone C: Emscripten/WASM build of the same provider semantics
```

WASM is a packaging/runtime target, not a different semantic provider.

## Wire protocol

Version 1 reuses the compiler's existing canonical admissions encoding. Do not invent a second PSC Core serializer unless the existing format proves insufficient.

The host wrapper supplies a small envelope around the canonical request. Conceptually:

```json
{
  "protocol": "pskernel-lean/1",
  "providerProfile": "lean4.34-core",
  "canonicalAdmissions": "<existing canonical payload>"
}
```

The provider returns a deterministic result envelope. Accepted result:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": true,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "profile": "lean4.34-core"
}
```

Rejected result:

```json
{
  "protocol": "pskernel-lean/1",
  "accepted": false,
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "profile": "lean4.34-core",
  "declarationIndex": 7,
  "errorKind": "kernel-rejection",
  "message": "..."
}
```

The wire protocol must not expose raw C++ pointers or rely on Lean internal object addresses. Native and WASM implementations must be substitutable at the protocol boundary.

## Semantic mapping

The provider decodes the existing PSC canonical representation directly into Lean semantic objects. The mapping target is Lean `Name`, `Level`, `Expr`, and `Declaration`, not Lean parser syntax.

Required initial expression support follows the canonical admissions codec:

```text
name
universe zero/succ/max/imax/param
bvar
sort
const
app
lambda
forall/pi
let
Nat literal
String literal
projection
```

Metavariables and free variables are rejected before kernel admission.

Initial declaration support must match the PSC2 bootstrap subset represented by the canonical codec. Inductives and constructors must preserve the declaration grouping and metadata required by Lean's kernel admission logic. Unsupported forms fail closed rather than being lowered approximately.

## Prelude and environment policy

Kernel checking must begin from a deterministic, documented environment corresponding to the PSC2 bootstrap prelude assumptions.

The provider must not trust a caller-supplied arbitrary environment. Environment construction must be one of:

1. a provider-owned pinned prelude reconstructed deterministically; or
2. a provider-owned digest-identified prelude artifact whose exact contents are checked before use.

The initial implementation should choose the smallest path that faithfully checks the current PSC2 bootstrap declarations.

The provider result must record the provider profile/prelude identity so acceptance cannot silently depend on a mutable host environment.

## Lean admission path

The native provider must ultimately submit decoded declarations through the real Lean 4.34 checked kernel environment path (`Kernel.Environment` / `addDeclCore` semantics), not a host-side imitation of type checking.

The provider may use Lean code as the integration shell for the first milestone because Lean's own C++ kernel and generated runtime support are already correctly linked there. The trusted semantic decision remains the original Lean kernel check.

Native reduction behavior that requires compiler-IR execution is outside the first `lean4.34-core` profile unless the PSC2 bootstrap corpus demonstrates it is required. Unsupported native-reduction cases fail closed. A later `lean4.34-exact` profile may add the complete Lean 4.34 behavior explicitly.

## Compiler/host integration

The minimal self-host compiler continues to produce `PsCompilerAdmissionReadyModule` exactly as today.

The external host flow becomes:

```text
generated compiler
    |
    | psCompilerPrepareSource(...)
    v
AdmissionReadyModule
    |
    | canonicalAdmissions
    v
host provider adapter
    |
    v
pskernel-lean native/WASM provider
    |
    v
accepted / rejected
    |
    +-- rejected -> stop
    |
    +-- accepted -> compiler continues from prepared declarations
                   through erasure/backend emission
```

The first integration is host-orchestrated. Do not import `pskernel-lean` into `packages/compiler`, `packages/backend-ts`, or `packages/bootstrap`.

This preserves the current fixed-point closure while making kernel-backed builds available through the Node CLI/tooling layer.

## CLI policy

Target CLI shape:

```text
psc build app.ps --out app.js --kernel lean434
psc build app.ps --out app.js --kernel psc
psc build app.ps --out app.js --kernel dual
```

Initial implementation may expose only `lean434` while the portable PSC provider integration is completed separately.

Policy meanings:

- `lean434`: the Lean 4.34 provider must accept before emission.
- `psc`: the selected PSC kernel provider must accept before emission.
- `dual`: both providers must independently accept the same canonical request; disagreement is a hard failure.

The ordinary bootstrap/fixed-point commands retain their current dependency policy and must not require `pskernel-lean`.

## Checked artifact semantics

`PsCompilerAdmissionReadyModule` remains an untrusted/prepared artifact.

The long-term semantic distinction is:

```text
AdmissionReadyModule
  -> successful KernelProvider decision
  -> CheckedModule
  -> erasure
```

For the first external-host integration, the host may enforce the kernel decision before invoking the existing prepared-to-erasure compiler function, because the self-hosted compiler cannot perform native process/WASM calls itself without polluting its portable closure.

A later portable protocol package may introduce an explicit `CheckedModule` token/artifact into the compiler API. Such a token must be unforgeable by ordinary source-level callers or must carry verifiable admission evidence. Do not merely rename `AdmissionReadyModule` to `CheckedModule`.

## Build strategy

### Native milestone

The repository must contain reproducible instructions for a developer machine with Lean 4.34 available through the project's pinned toolchain.

Expected command shape:

```text
cd psc15selfhost/packages/pskernel-lean
lake build
```

or an equivalent repository-owned script if the provider must share the parent `psc15selfhost` Lake configuration.

The documentation must identify every external prerequisite and include Windows/WSL/Linux notes where behavior differs.

### Standalone native closure milestone

After the semantic mapping works, audit the exact symbols required from:

```text
kernel/
runtime/
util/
Lean-generated support
include/lean/lean.h
```

Reduce the provider to the smallest practical reproducible dependency closure without modifying kernel semantics.

Do not vendor arbitrary `Std`, elaborator, tactic, parser, Lake, or LSP code into the provider unless a concrete required symbol proves it necessary.

### WASM milestone

Use Emscripten only after native provider tests are green. WASM must expose the same protocol and produce the same acceptance results on the conformance corpus.

The WASM implementation should avoid unnecessary IO/libuv/compiler functionality. If upstream dependencies make a truly kernel-only WASM impossible without significant surgery, retain a larger mechanically-linked artifact first and optimize size only after semantic parity is demonstrated.

## Error handling

The provider is fail-closed.

Distinct error classes should include at least:

```text
protocol-version
malformed-request
unsupported-core-form
prelude-mismatch
provider-version-mismatch
kernel-rejection
provider-internal-error
provider-unavailable
provider-crash
result-shape-error
```

A provider crash, missing executable, missing WASM artifact, or unparseable response is not acceptance.

Kernel rejection diagnostics may be normalized for stability, but raw developer diagnostics may also be printed in verbose/debug mode.

## Testing strategy

Testing is layered.

### Protocol tests

Verify deterministic request/response parsing, malformed input rejection, version mismatch rejection, and result-shape validation.

### Mapping tests

For every supported PSC Core constructor, exercise at least one direct fixture and edge cases involving nested binders/universes.

### Positive kernel fixtures

Known-well-typed declarations must be accepted, including the minimal declaration forms used by the PSC2 compiler itself.

### Negative kernel fixtures

Construct declarations that pass the codec shape but are semantically invalid, for example wrong result types, invalid applications, bad universe relationships, malformed inductive data, or invalid definition bodies. The real Lean kernel must reject them.

### Differential tests

Where the existing `packages/pskernel` supports the same subset, feed both providers the same semantic corpus and require matching accept/reject decisions. A mismatch is a hard assurance failure, not something to normalize away.

### Integration tests

A PSC2 source file must:

```text
parse -> elaborate -> canonical admissions -> Lean provider -> emission
```

and an intentionally unsound/invalid prepared declaration must be stopped before emission.

### Bootstrap regression

Existing bootstrap/fixed-point gates must continue to pass without building or invoking `pskernel-lean`.

## Acceptance milestones

### KLP0 — provider skeleton

- provider protocol documented;
- pinned version metadata present;
- native provider builds;
- deterministic health/version command works.

### KLP1 — semantic decoding

- canonical admissions request decodes to Lean semantic objects;
- supported subset is explicit;
- unsupported input fails closed.

### KLP2 — real kernel admission

- positive declarations accepted by Lean 4.34 kernel;
- negative semantic declarations rejected;
- provider does not use Lean parser/elaborator to reinterpret PSC source.

### KLP3 — PSC2 host integration

- `psc build ... --kernel lean434` gates emission on provider acceptance;
- provider failures are surfaced deterministically;
- existing fixed-point flow is unchanged.

### KLP4 — differential assurance

- shared corpus runs through Lean provider and PSC kernel provider;
- disagreement causes a hard failure;
- results are recorded with provider/version metadata.

### KLP5 — WASM provider

- same protocol exposed from WASM;
- native and WASM provider results agree on the corpus;
- Node can use WASM without a native Lean executable.

## Non-goals for the first implementation

The first provider does not need to:

- ship the complete Lean frontend or elaborator;
- parse arbitrary `.lean` source;
- support tactics or Meta;
- reproduce the entire Lean executable;
- make PSC2's fixed point depend on Lean;
- implement every planned PSC2 language feature;
- provide browser deployment before native semantics are proven;
- claim formal equivalence between PSC's kernel and Lean 4.34;
- optimize binary size before correctness and reproducibility are established.

## Source provenance

The copied `kernel/`, `runtime/`, and `util/` trees are treated as pinned upstream Lean 4.34 reference sources. The implementation must document their upstream version and avoid semantic edits unless a change is explicitly justified and tested.

The provider should identify itself as Lean 4.34-compatible and, where available, record the exact upstream Lean tag/commit used by the repository's established Lean 4.34 conformance work.

## Documentation deliverables

`pskernel-lean` must contain enough documentation for a future AI or human contributor to reproduce and continue the work without relying on chat history:

- `README.md`: purpose, status, provider profiles, quick commands;
- `BUILDING.md`: exact native and later WASM build instructions and troubleshooting;
- `INTEGRATION.md`: protocol, PSC2 host boundary, CLI behavior, fixed-point isolation;
- provider protocol/source comments describing trust assumptions;
- a status/checklist section recording which KLP milestones are actually complete.

## Definition of done for this branch

This branch is ready to merge only when at least KLP0 through KLP3 are complete and verified, while all existing PSC2 bootstrap/fixed-point gates remain semantically unchanged.

WASM (KLP5) is desirable but does not block the first merge if native provider integration is fully working, documented, and isolated. Differential assurance (KLP4) should be included before merge when the existing PSC kernel adapter can consume the same canonical corpus without broad unrelated changes.

No milestone may be claimed solely because files exist or code compiles. Acceptance requires executable positive and negative evidence.