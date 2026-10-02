# PSC3 Design Decision Ledger

Status: **living draft ledger**

This file records the current PSC3 design direction at the level needed to prevent accidental drift.

A DECISION here is adopted by the PSC3 research draft. It is not a claim that the implementation exists or that the language is frozen.

## Status meanings

- **DECISION** — chosen for the current PSC3 draft; change requires an explicit design revision.
- **CANDIDATE** — preferred direction, but evidence/semantics are not sufficient for freeze.
- **RESEARCH** — active alternatives remain.
- **DEFERRED** — intentionally outside the initial Standard profile.
- **REJECTED** — deliberately not part of native PSC3 semantics.

## Language identity

| Topic | Status | Current direction |
| --- | --- | --- |
| General-purpose language | DECISION | Full applications are a first-class goal, not only verified libraries. |
| Theorem prover | DECISION | Native dependent theorem proving remains a core identity. |
| Formal verification | DECISION | Contracts/invariants produce kernel-checkable evidence. |
| AI/SDD | DECISION | Specification-enforced development is a major workflow, but AI has no proof authority. |
| Go-like philosophy | DECISION | Favor orthogonality, predictability, explicit dependencies and integrated tooling; do not copy Go's type system. |

## Source profiles

| Topic | Status | Current direction |
| --- | --- | --- |
| .lean | DECISION | Strict subset/profile of official pinned Lean; never add PSC-only syntax. |
| Initial Lean baseline | DECISION | Stable Lean 4.34.1 for this research draft. |
| .ps | DECISION | Preferred native application/library language over the same canonical semantics. |
| .psx | CANDIDATE | Fixed component-markup profile lowering to ordinary .ps expressions. |
| Full Lean syntax in .ps | REJECTED | Native .ps remains intentionally smaller/more regular. |
| Full TypeScript source compatibility | REJECTED | Interoperate through generated/foreign bindings rather than inherit TS semantics. |

## Native syntax

| Topic | Status | Current direction |
| --- | --- | --- |
| f(x) vs f (x) | DECISION | Same native call meaning; remove PSC2 whitespace-sensitive call ownership in PSC3 edition. |
| Explicit import/export | DECISION | ESM-like native source surface with PSC-defined deterministic resolution. |
| Canonical function/const vocabulary | CANDIDATE | Prefer application-friendly function/const; retain def as migration/theorem-oriented form if useful. |
| Semicolon policy | RESEARCH | Avoid JavaScript ASI; freeze only after grammar/formatter experiments. |
| Optional field sugar field?: T | CANDIDATE | Sugar for Option T only. |
| ?. and ?? | CANDIDATE | Option operations, not null/undefined semantics. |
| Error propagation spelling | RESEARCH | Compare try-like, postfix and do/pattern approaches. |
| Resource syntax | RESEARCH | Freeze semantics before spelling. |

## Type/data system

| Topic | Status | Current direction |
| --- | --- | --- |
| Nominal structures/inductives | DECISION | Native logical data identity is declared, not TS structural assignability. |
| any | REJECTED | No unchecked universal native type. |
| implicit null/undefined | REJECTED | Option is the portable absence model. |
| truthiness | REJECTED | Conditions have explicit Bool/proposition semantics. |
| prototype inheritance/this | REJECTED | Modules/functions/structures/classes/method notation instead. |
| Result order | DECISION | Result(A, E): success type first, error type second. |
| enum | DECISION | Only payload-free inductive sugar; no JS/TS enum runtime model. |
| advanced TS conditional/mapped/template types | REJECTED from native core | Supported as needed by the .d.ts interop/binding layer. |
| dependent structure update | RESEARCH | Must explicitly handle fields whose types depend on changed fields. |

## Elaboration

| Topic | Status | Current direction |
| --- | --- | --- |
| Method notation | DECISION | Static elaboration to ordinary calls; no prototype lookup. |
| Named/default arguments | DECISION | Deterministic elaboration with stable parameter names. |
| Instance search | CANDIDATE | Scoped, bounded, deterministic and explainable; exact Lean compatibility lives in .lean profile. |
| Coercions | CANDIDATE | Bounded deterministic chains with explanation tooling. |
| Explainability | DECISION | psc explain or equivalent exposes inferred selections and obligations. |

## Execution and effects

| Topic | Status | Current direction |
| --- | --- | --- |
| Pure default semantics | DECISION | Ordinary portable pure functions are referentially transparent. |
| Typed recoverable errors | DECISION | Result/Except semantics; host exceptions are boundary behavior. |
| Local mutable-looking syntax | DECISION | Lexically scoped lowering, not shared JS object mutation semantics. |
| Partial runtime functions | DECISION | Supported for real apps but separated from total logical computation. |
| Partial-program proof model | RESEARCH | Need partial-correctness/safety/trace semantics. |
| General algebraic effects | DEFERRED | Study Koka-like systems but do not add to PSC3 core without demonstrated need. |
| Application App effect | CANDIDATE | Conventional application context may improve usability if capabilities stay visible. |
| Resource abstraction | CANDIDATE | Deterministic cleanup independent of GC finalizers. |
| Structured concurrency | CANDIDATE | Scoped children/cancellation/failure before async freeze. |
| Promise as Task semantics | REJECTED | Promise is one target mapping only. |

## Verification

| Topic | Status | Current direction |
| --- | --- | --- |
| requires/ensures/assert/invariant/decreasing | DECISION | Standard verification surface. |
| VC generator trust | DECISION | Untrusted proof construction. |
| Final program-spec theorem binding | DECISION | Verification must establish property of actual accepted implementation. |
| Solver result as proof | REJECTED | Require reconstruction/certificate under strict profile. |
| Runtime test/assert as proof | REJECTED | Runtime evidence is separately labeled. |
| Specification dependency protection | DECISION | Approved spec meaning includes referenced definitions/axioms/profile. |
| Single global verified flag | REJECTED | Report typed/kernel/contract/termination/compiler/runtime statuses separately. |

## JavaScript ecosystem

| Topic | Status | Current direction |
| --- | --- | --- |
| ESM | DECISION | Primary JS module/artifact model. |
| npm integration | DECISION | First-class binding/package workflow. |
| .d.ts output | DECISION | Generate for TypeScript consumers. |
| .d.ts input | DECISION | Binding generator interprets supported TS declarations. |
| CJS | DEFERRED/interop | Adapter only; not native module semantics. |
| Runtime codecs/schema | DECISION | Standard capability for untrusted JSON/foreign boundaries. |
| Browser/Node/Bun/Deno | DECISION | Platform profiles/adapters over shared PSC semantics. |

## UI

| Topic | Status | Current direction |
| --- | --- | --- |
| .psx | CANDIDATE | Typed generic markup lowering. |
| React semantics in core | REJECTED | React is an adapter/library. |
| Component = function | DECISION for proposal | Component sugar lowers to typed functions/calls. |
| Raw HTML | DECISION for proposal | Explicit trusted/sanitized boundary; safe escaping by default. |
| State/hooks in language | REJECTED initially | Framework/platform libraries define state mechanisms. |

## Backends

| Topic | Status | Current direction |
| --- | --- | --- |
| Direct JS | DECISION | Primary strategic application backend. |
| Direct Wasm | DECISION | Secondary strategic backend; start bounded and grow toward Component/WASI. |
| TypeScript emitter | DEFERRED optional | Useful compatibility/debug output but not required in normal execution chain. |
| Rust emitter | DEFERRED optional | Ecosystem/native bridge, not normative PSC3 semantics. |
| Target-specific source semantics | REJECTED | Backends implement PSC semantics rather than define them. |
| Compiler-preservation story | DECISION | Separate erasure, RuntimeIR, target lowering, serialization and runtime assumptions. |
| Translation validation | DECISION direction | Use per-pass proofs and/or sound validators; not implemented by this document. |

## Packages/tooling

| Topic | Status | Current direction |
| --- | --- | --- |
| One canonical formatter | DECISION | Native source has stable formatting. |
| One primary psc CLI | DECISION | Integrated ordinary workflow. |
| LSP | DECISION | Essential product surface. |
| Structured diagnostics | DECISION | Stable machine-readable codes/data. |
| Small project manifest + lock | DECISION direction | Exact proofscript.json naming remains CANDIDATE. |
| Arbitrary parser mutation | REJECTED initially | Controlled/versioned extensions only. |
| Plugin proof authority | REJECTED | Plugins cannot override kernel admission. |

## Decisions requiring empirical validation before freeze

The following are intentionally prominent:
- native function/declaration spelling;
- semicolon/body grammar;
- optional chaining;
- error propagation;
- instance/coercion policy;
- dependent structure update;
- Resource;
- Task structured-concurrency semantics;
- partial/effectful program logic;
- .psx component abstraction;
- package manifest details;
- first compiler-preservation theorem/profile;
- Wasm memory/GC/runtime representation.

These are not details to be filled in by backend convenience.

They require design experiments, models, representative programs and conformance tests.
