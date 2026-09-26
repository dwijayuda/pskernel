# PSC1 Source and Evidence Map

Status: **research traceability map**

This file records the principal repository inputs used to synthesize the PSC1
Language Reference. It is not a replacement for those source documents; it
makes their roles and precedence explicit.

Baseline: `main@165468c7f195c60906075e774543c1e65b3518f1`.

## 1. Controlling scope documents

### `docs/plans/07_SELF_HOSTING_FOUNDATION.md`

Role: **highest-priority PSC1 scope/freeze plan**.

Key authority used here:

- v0.7 + v0.6.1 source baseline; v0.8 non-normative;
- `def`/`const`/`function` identity rules;
- REQUIRED/OPTIONAL/DEFERRED/HOST classification;
- Go-like minimality policy;
- complete PSC1 scalar vocabulary;
- scalar freeze obligation;
- pure/effect boundary;
- target-neutral VerifiedIR;
- TS/Rust/Wasm backend separation;
- SH7 freeze conditions;
- SH8 Lean-authored compiler;
- SH9 JS bootstrap;
- SH10 `.ps` source transition;
- later Rust/Wasm cross-host milestones.

When another older plan makes a feature appear mandatory but this plan
explicitly marks it optional/non-blocking, the self-hosting plan controls PSC1
freeze scope.

### `docs/plans/00_MASTER_PLAN.md`

Role: global architecture and package dependency direction.

Key authority:

- one source -> Meta/Elab -> pskernel -> CheckedCore -> erasure -> compiler-IR
  path;
- legacy semantic lane retired;
- small independent pskernel;
- parser/elab/tactics/compiler/LSP outside default TCB;
- active self-host priority override.

### `docs/plans/05_LANGUAGE_COMPLETION.md`

Role: current feature evidence, theorem/tactic roadmap, dual-source and
JavaScript ecosystem status.

Key authority:

- current preferred-path feature evidence;
- bounded proof/tactic behavior and limitations;
- dual-source anti-drift;
- current named-ESM FFI extension;
- ProofScript-written standard-library dogfood;
- fail-closed implementation rules.

It is subordinate to the self-host plan for first-freeze priority.

### `docs/plans/06_DUAL_SOURCE_LEAN_INTEROP.md`

Role: supported `.ps` <-> bounded `.lean` source model.

Key authority:

- source-kind frontend separation;
- canonicalization rather than byte-preserving round trip;
- semantic fingerprint equivalence;
- mixed-source project graph;
- fail-closed Lean subset;
- editor/source-kind integration.

### `docs/plans/02_FRONTEND_AND_THEOREM_PROVER.md`

Role: frontend/Meta/Elab/tactic package boundaries.

Key authority:

- syntax does not decide kernel validity;
- Meta handles metavariables/unification/implicits/instances;
- elaborator produces kernel-facing declarations;
- tactics construct proof terms;
- all output is rechecked by pskernel.

### `docs/plans/03_COMPILER_RUNTIME_BACKENDS.md`

Role: compiler/runtime architecture.

Key authority:

- compiler IR distinct from kernel Expr;
- explicit runtime support where semantics require it;
- compiler correctness separate from kernel correctness;
- no host JS evaluation in the kernel.

## 2. Current architecture and policy

### `docs/STUDY_REFERENCE_POLICY.md`

Role: evidence precedence.

Key authority:

- pinned Lean 4.34 source is primary for Lean semantics;
- v0.7 study reference is primary for ProofScript language intent;
- v0.6.1 is compatibility/history;
- current repository implementation/docs may intentionally supersede study
  snapshots;
- TypeScript sources are host/backend references, never proof semantics;
- semantic changes should identify source evidence before implementation.

### `docs/PROOFSCRIPT_ARCHITECTURE.md`

Role: active compiler architecture and feature checkpoints.

Key authority:

- bounded frontend semantics;
- checked-core convergence;
- theorem/type expression checkpoints;
- current FFI extension;
- proof/backend trust separation.

### `docs/research/LEAN434_FRONTEND_COMPILER_ARCHITECTURE.md`

Role: architectural lessons from Lean 4.34 source.

Key authority:

- parser != elaborator;
- focused elaboration modules;
- rich surface -> smaller semantic core;
- compiler IR != kernel Expr;
- backends consume compiler IR, not raw source;
- every feature needs authority/tests/semantic path/claim ceiling.

## 3. Self-host implementation documents

### `docs/selfhost/PSC1_LEAN_BOOTSTRAP.md`

Role: bootstrap source authority and package/source-lane model.

Key authority:

- portable source is intersection of PSC1 semantics, canonical `.ps`, and
  ordinary supported Lean 4.34 syntax;
- Lean acceptance alone does not imply PSC1;
- exact scalar vocabulary;
- portable compiler source excludes Lean implementation APIs/macros/unsafe/IO;
- same VerifiedIR for TS/Rust/Wasm;
- TS oracle -> Lean bootstrap -> generated ProofScript source transition.

### `selfhost/SELFHOSTING.md`

Role: concrete self-host pipeline and current blocker.

Key authority:

- one compiler, staged execution hosts;
- VerifiedIR target-neutrality;
- backend-polymorphic pure libraries;
- scalar vocabulary;
- source transition;
- active portable source-closure blocker.

### `selfhost/ARCHITECTURE_MAP.md`

Role: implementation ownership map for the Lean-first self-host compiler.

Used to avoid turning the language reference into a copy of current TypeScript
module/file names while preserving the same semantic responsibilities.

### `selfhost/packages/compiler-ir/CONTRACT.md`

Role: explicit VerifiedIR target-neutrality contract.

Key authority:

- only PSC semantic concepts before backend lowering;
- target-specific representation forbidden in shared IR;
- backend-private target IRs allowed after VerifiedIR.

## 4. ProofScript language study corpus

### `study/proofscript-language-reference-v0.7.0/`

Role: principal source-language intent.

Key authority:

- TypeScript-friendly surface + Lean semantics;
- L/D/E/X feature model;
- punctuation rules;
- parser ownership;
- `def`, `const`, `function`;
- D-CALL;
- braced if/structure/class/inductive/match/where forms;
- dependent binders/functions;
- proof/effect vocabulary;
- source/runtime trust separation;
- conformance methodology.

Important reconciliation:

The v0.7 study package was produced before some newer repository scope
decisions. Current PSC1 docs intentionally narrow inherited Lean breadth and add
new repository-defined facilities such as the named-ESM FFI and signed machine
scalar/Float32 foundation. Those are recorded as explicit repository revisions,
not silently attributed to the old study draft.

### `study/proofscript-language-reference-v0.6.1/`

Role: compatible compiler-ready historical baseline.

Used for:

- source forms that v0.7 deliberately preserved;
- conformance cases;
- parser/lowering behavior;
- diagnostic obligations;
- compatibility regression reasoning.

It does not override a deliberate newer v0.7/current-repository decision.

## 5. Lean semantic study corpus

### `study/lean4-4.34.0/`

Role: primary pinned semantic/implementation evidence for Lean-compatible
behavior.

Relevant areas studied by current plans include:

- `src/Init/`;
- `src/Lean/Parser/`;
- `src/Lean/Meta/`;
- `src/Lean/Elab/`;
- `src/Lean/Compiler/`;
- runtime/primitive type implementation sources.

PSC1 uses these sources to understand semantics and useful compiler facilities.
It does not attempt to copy all Lean implementation features.

### `study/lean4-language-reference/`

Role: secondary user-facing Lean syntax/behavior reference.

When generated prose and executable pinned Lean source appear to disagree,
repository policy says to inspect source/tests before choosing semantic
behavior.

## 6. Current implementation evidence

### `packages/syntax/`

Evidence used:

- source positions/trivia;
- D-CALL adjacency;
- v0.6.1/v0.7 owned forms;
- feature IDs;
- current operator precedence;
- bounded Lean-subset parser;
- canonical ProofScript/Lean printers;
- D-EXTERN-FFI parser;
- import/module header behavior.

Not semantic authority by itself.

### `packages/elab/`

Evidence used:

- current Nat/Bool notation semantics;
- dependent header/type elaboration;
- structures/inductives/classes/instances;
- theorem/proof paths;
- runtime external elaboration;
- fail-closed unsupported cases.

All relevant declarations still require pskernel admission.

### `packages/checked-core/`, `packages/erasure/`,
`packages/compiler-ir/`

Evidence used for the single semantic compiler handoff and post-check execution
path.

### `selfhost/packages/*`

Evidence used for current PSC1 Lean-authored compiler source, scalar model,
erasure/IR/backend work, and source-closure status.

## 7. Conflict-resolution rules used in this reference

### Conflict A: v0.7 broad inherited Lean surface vs PSC1 bounded subset

Resolution:

- Lean remains semantic authority;
- PSC1 only accepts the explicitly supported/frozen subset;
- unknown Lean syntax does not automatically become PSC1;
- fail closed.

### Conflict B: v0.7 primitive list vs newer PSC1 scalar foundation

Resolution:

The active self-host plan explicitly freezes the expanded PSC1 vocabulary:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

This newer repository decision controls PSC1.

### Conflict C: old "all admitted Lean conveniences" impression vs minimality

Resolution:

The controlling plan marks many conveniences optional/non-blocking. Existing
support remains supported, but first-freeze completion depends only on REQUIRED
capabilities plus optional features actually adopted by compiler source.

### Conflict D: source FFI absent from v0.7

Resolution:

The current `extern function ... from ... import ...;` form is documented as a
post-v0.7 repository extension and host-boundary capability. It is not
misrepresented as old v0.7 conformance.

### Conflict E: target representations vs semantic types

Resolution:

VerifiedIR stays target-neutral. TypeScript, Rust, and Wasm mappings live below
the semantic boundary.

## 8. Evidence still required for final freeze

Research found no basis to pretend these are already fully resolved:

- complete scalar operation/conversion matrix;
- executable cross-backend scalar corpus;
- final SH7 required-feature census;
- composed SELFHOST-FEATURE pass;
- complete source closure of the compiler;
- generated full-tree ProofScript parity after compiler translation exists;
- stronger compiler semantic-preservation proofs.

The language reference marks these as open rather than inventing completion.

## 9. Maintenance rule

When PSC1 changes:

1. update the controlling plan/feature decision first;
2. identify semantic source authority;
3. update this reference;
4. add/adjust executable conformance cases;
5. preserve negative/fail-closed tests;
6. record whether the change affects PSC1 REQUIRED scope or only a later
   optional/profile capability.

A backend patch alone is not a language-reference change.
