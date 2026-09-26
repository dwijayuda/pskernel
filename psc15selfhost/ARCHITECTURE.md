# PSC2 minimal self-host architecture

Status: architecture contract for `psc15selfhost/`.

This directory owns the smallest stable PSC2 self-host compiler and its local assurance
machinery. Everything outside `psc15selfhost/` is reference material only and must not
become a bootstrap dependency accidentally.

## 1. Bootstrap contract

The first PSC2 compiler intentionally separates the language used to implement the
compiler from the language the compiler may eventually accept:

```text
implementationProfile = PSC1-compatible Lean
acceptedLanguageProfile = PSC2-bootstrap
bootstrapHost = official Lean 4.34 + Lake
selfHostBackend = TypeScript / JavaScript
```

The compiler does not need to use a feature in order to implement that feature. PSC2
features should normally be implemented using the previous stable implementation
profile and dogfooded into compiler source only after the fixed point remains stable.

At the first fixed point, `PSC2-bootstrap` may intentionally expose only the stable PSC1
surface needed by the compiler. The first milestone is architectural self-host closure,
not feature-count parity.

During bootstrap:

- `.lean` is the only handwritten portable compiler source;
- that `.lean` must stay inside the PSC1 source profile;
- official Lean checks/builds the bootstrap compiler;
- canonical `.ps` is generated, not manually duplicated;
- `.ps` becomes authoritative only after fixed-point parity is demonstrated.

## 2. Smallest stable compiler closure

The fixed point is import-closure based. It contains only the semantic compiler plus the
single backend required to produce the next compiler generation:

```text
packages/bootstrap          tiny composition root
        |
        +-- compiler        backend-neutral semantic compiler
        |     |
        |     +-- syntax
        |     +-- core
        |     +-- environment
        |     +-- meta
        |     +-- elab
        |     +-- bridge
        |     +-- erasure
        |     +-- compiler-ir
        |
        +-- backend-ts      one bootstrap backend
        |
        +-- portable stdlib modules actually imported
```

The bootstrap closure deliberately excludes:

```text
project
backend-rust
backend-wasm
pskernel-core
pskernel
host IO from portable semantic source
future plugins / FFI / LSP / large libraries
```

Exclusion from the first fixed point does not mean deletion. It means those capabilities
must not be prerequisites for the compiler generation that first establishes self-host.

## 3. Fixed-point pipeline

```text
PSC1-compatible .lean compiler source
        |
        | Lean 4.34 + Lake
        v
Lean-hosted bootstrap compiler
        |
        | canonical .lean -> .ps translation
        v
generated .ps compiler workspace
        |
        | generated compiler -> VerifiedIR -> TypeScript -> tsc
        v
JavaScript compiler generation N
        |
        | canonical re-emission + recompilation
        v
JavaScript compiler generation N+1
        |
        +-> exact generated-source parity
        +-> exact generated-TypeScript parity
```

A passing compiler fixed point means generation N and N+1 agree for this bootstrap
profile. It does not establish full Lean 4 equivalence or kernel soundness.

## 4. Semantic architecture

Keep capabilities moving upward whenever possible:

```text
Ecosystem: npm / React / databases / native systems
                       |
FFI / future InterfaceIR / capability adapters
                       |
Libraries: collections / effects / Task / math / proof libs
                       |
Controlled extensions: syntax / derive / tactics / compiler plugins
                       |
Frontend: parser -> resolver -> Meta -> elaborator
                       |
Canonical dependent Core
                       |
Kernel admission provider
                       |
CheckedModule / CheckedCore
                       |
Erasure
                       |
Target-neutral VerifiedIR
                       |
Backend plugins: TS / Rust / Wasm / future targets
```

Rules:

1. If it can be a library, make it a library.
2. If it is ergonomic syntax, desugar it.
3. If it produces proofs, keep it in Meta/tactic code and check the result.
4. If it needs compiler participation, use a controlled/versioned extension boundary.
5. If it is target-specific, keep it behind VerifiedIR or a separate FFI/InterfaceIR
   boundary.
6. Change Core/kernel semantics only for genuinely foundational requirements.

## 5. Current compiler admission boundary

The current compiler produces `PsCompilerAdmissionReadyModule`, not `CheckedCore`.
That distinction is intentional.

```text
source
  -> parse / elaborate
  -> AdmissionReadyModule
  -> validation + deterministic environment reconstruction
  -> erasure
  -> VerifiedIR
  -> backend
```

`AdmissionReadyModule` is hardened for its current role:

- canonical admissions are recomputed before erasure;
- mismatched/forged canonical admissions are rejected;
- the environment is reconstructed from the bootstrap prelude plus declarations;
- arbitrary caller-provided environment authority is not carried through the artifact;
- backend APIs receive VerifiedIR only through the semantic compiler path.

This is stronger than erasing arbitrary elaborated declarations, but it is still weaker
than genuine kernel admission.

The later authority transition must be explicit:

```text
AdmissionReadyModule
        |
        v
Core -> kernel adapter -> pskernel-core
        |
        v
CheckedModule / CheckedCore
        |
        v
Erasure -> VerifiedIR
```

At that point erasure should accept only the checked artifact. Do not rename codec
validation to `CheckedCore` to manufacture the milestone.

## 6. Two kernel packages, two jobs

### `packages/pskernel-core`

`pskernel-core` is the intentionally small trusted-kernel candidate.

Properties:

- handwritten PSC1-compatible `.lean`;
- no Lean implementation APIs, macros, unsafe code, IO, or other forbidden bootstrap
  conveniences;
- independently source-audited and checked by the PSC compiler;
- built from small foundational modules such as Name and Level;
- parity-tested against accepted reference foundations;
- **not** a first-fixed-point dependency yet.

It should grow only with semantics required for independent checked-core authority.
Compiler ergonomics must not leak into it.

### `packages/pskernel`

`packages/pskernel` is the larger bounded reference/assurance implementation. It is
valuable for differential testing, Lean-behavior study, and parity evidence. Its size
and richer machinery make it the wrong object to pull wholesale into the small trusted
bootstrap closure.

The long-term direction is therefore:

```text
small pskernel-core = candidate TCB
large pskernel      = reference / oracle / assurance
```

## 7. Shared workspace and resolver contract

Self-host failures often come from orchestration rather than semantics: generation N
and N+1 resolve the same import differently, use different entries, or silently include
an extension package.

For that reason:

- `scripts/workspace-layout.mjs` is the single Node-side authority for
  module-section -> package mapping and source-path resolution;
- bootstrap collection and bootstrap-closure checking use Lean-only resolution;
- project emission prefers the source extension being emitted from and may fall back to
  the alternate source representation;
- generated compiler builds preserve the old fail-closed rule: `Ps.*` and
  `ProofScript.*` prefer authoritative Lean if both forms exist, while ambiguous user
  modules with both `.lean` and `.ps` are rejected;
- `host/src/Ps/Host/ProjectCompiler.lean` mirrors package routing needed by the Lean
  bootstrap host, including `Ps.KernelCore -> packages/pskernel-core`;
- `scripts/check-layout-drift.mjs` guards these contracts with actual resolver fixtures.

Do not add another local module/package routing table to a generation script.

## 8. Package responsibilities

- `packages/bootstrap`: tiny composition root for the first self-host compiler.
- `packages/compiler`: backend-neutral semantic orchestration; no `Ps.Backend*` imports.
- `packages/backend-ts`: the one backend in the fixed-point dependency closure.
- `packages/backend-rust`, `packages/backend-wasm`: optional VerifiedIR consumers.
- `packages/project`: project/module graph capability, outside the first fixed point.
- `packages/pskernel-core`: small trusted-kernel candidate, independently gated.
- `packages/pskernel`: larger assurance/reference kernel.
- `host`: Lean-bootstrap filesystem/process/`tsc` integration; not portable semantics.
- `stdlib`: ordinary portable libraries.

Preserve useful package boundaries. Make the dependency closure small; do not make the
codebase small by collapsing it into one file.

## 9. Gate layering

Bootstrap-critical gates are narrower than release assurance:

```text
check:workspace
check:source:bootstrap
check:layout
check:bootstrap-closure
check:selfhost-orchestration
check:ir-neutrality
build:lean
test:bootstrap
fixed-point
```

Full assurance additionally includes:

```text
check:source:all
check:kernel-core-source
test:kernel-core
test:regression
test:extensions
```

`bootstrap` and `fixed-point` must stay independent of project/Rust/Wasm/kernel-core
extension work until an explicit milestone changes the contract. `npm run check` remains
the broader release gate so reducing the fixed-point closure does not delete assurance.

## 10. PSC2 growth after the first fixed point

Only after the minimal fixed point is demonstrated should the accepted source profile
expand. Preferred first usability layer:

```text
richer patterns
namespace ergonomics
method notation
practical local/mutual recursion lowering
structured proof terms
```

These should lower through the existing frontend/elaboration pipeline and should not
change kernel rules unless there is evidence of a real foundational requirement.

Then grow outward through libraries and controlled extensions:

```text
Meta/tactic APIs and simp
contracts / VC generation
deriving and controlled attributes
Task / async / resource libraries
plugin API stabilization
InterfaceIR / FFI
additional backend plugins
larger proof and math libraries
```

Every PSC2 feature should record at least:

```text
featureName
implementationProfile
acceptedProfile
loweringTarget
kernelRequirements
backendRequirements
```

A feature must not be mandatory for the compiler generation that first implements it
unless an explicit external bootstrap host is recorded.

## 11. Completion claims

Use precise milestone language:

- **architecture ready**: dependency boundaries and gates exist;
- **Lean bootstrap passes**: official Lean successfully builds/tests the bootstrap;
- **compiler self-host fixed point passes**: generated `.ps` and generated TS agree
  across compiler generations;
- **kernel-backed self-host**: a real small-kernel adapter admits Core and erasure accepts
  only CheckedCore;
- **Lean-equivalent**: only after the relevant equivalence claim is separately proven.

Do not collapse these into one “finished” claim.
