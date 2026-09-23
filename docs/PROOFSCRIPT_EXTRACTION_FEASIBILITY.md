# ProofScript Extraction Feasibility

Status: **kernel-consumer boundary spike only**

Branch: `integration/proofscript-extraction-feasibility`  
Base branch: `main`  
Base at spike creation: `f2e8c4b417b868cf0f1cccd5ad5a3eb93e0f0010`

## Intended repository role

If the paired ProofScript adoption spike succeeds, this repository should
converge toward a deliberately boring independent trusted component:

- Lean-compatible Core values;
- environments and local contexts;
- type checking and definitional equality;
- reduction;
- inductive/recursor/quotient admission;
- primitive recognition;
- checked module/replay support;
- Lean 4.34 conformance/differential tests.

Parser, Meta/Elab, erasure, compiler IR, runtime, TypeScript backend, project
tooling, language service and LSP are outside the TCB. The versions currently in
this repository are architectural/implementation donors; they should not keep
growing into a second full ProofScript product if the product repo successfully
adopts the standalone kernel.

## External consumer contract

The spike keeps the package `private: true`. It does not publish PSKernel.

The root package now has:

- a `prepare` build hook for packed/git-package consumption;
- a narrow `files` allowlist;
- `test:public-consumer`;
- `docs/EXTERNAL_CONSUMER_CONTRACT.md`.

The public consumer test imports only from `lean-ts-kernel`, constructs and
admits a dependent identity definition, and never imports an internal
`src/core/*` or `src/kernel/*` path.

## Dependency rule

```text
ProofScript -> lean-ts-kernel
```

No kernel code may import ProofScript packages.

## Hosted gate status

Workflow `feasibility-kernel-consumer` was created only on this branch.

Run `35848629530` concluded as failure before execution. Job
`public-consumer` had:

- `runner_id = 0`;
- empty `runner_name`;
- `steps = []`.

Therefore no repository command ran. Treat this as runner-allocation
infrastructure failure, not a failed public-API test.

## Local executable gate

```bash
npm install
npm run test:public-consumer
node scripts/anti-drift.mjs
npm pack
```

Only after those commands run green should the packed artifact be used by the
paired ProofScript feasibility branch.

## Disposition of outer packages during the spike

| Package area | Disposition |
| --- | --- |
| root `src/core`, `src/kernel` | KEEP / TCB |
| `packages/module`, conformance, lean4export | KEEP if they remain kernel-facing support |
| `packages/syntax` | FREEZE NEW PRODUCT EXPANSION; donor |
| `packages/meta`, `packages/elab` | FREEZE NEW PRODUCT EXPANSION; donor |
| `packages/checked-core` | architectural donor; likely port concept to ProofScript |
| `packages/erasure`, compiler-ir, backend-ts, compiler | donor; do not race the ProofScript product implementation |
| runtime | donor for exact semantic ideas only |
| language-service/LSP/project/editor | donor; do not independently complete as the main product |
| root CLI kernel/module inspection capabilities | may remain kernel tooling |
| ProofScript-style product CLI behavior | should move/remain in ProofScript |

No outer package is deleted in this spike.

## STOP conditions

Stop extraction/convergence work if making the kernel externally consumable
requires:

- a reverse dependency on ProofScript;
- exposing broad internal implementation files as public API;
- moving parser/compiler/runtime behavior into the TCB;
- weakening anti-drift or Lean 4.34 conformance gates.

The root public façade should stay small even if the ProofScript product grows
substantially.
