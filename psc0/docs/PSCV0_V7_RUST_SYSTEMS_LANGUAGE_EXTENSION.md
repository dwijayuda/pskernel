# ProofScript PSCV0 v7 — Rust-Target Verified Systems Programming Language Extension

**Document status:** DESIGN PROPOSAL / NOT ADOPTED / NOT IMPLEMENTED  
**Edition:** `PS-SYSTEMS/0` (proposed extension to the PSCV0 v7 language design)  
**Research date:** 2026-10-11  
**Repository placement:** `psc0/docs/PSCV0_V7_RUST_SYSTEMS_LANGUAGE_EXTENSION.md`  
**Reference authority:** [PSCV0 v7 language reference](../PSCV0_LANGUAGE_REFERENCE.md), repository-declared SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`  
**Lean semantic baseline for admitted proof terms:** Lean `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`  
**Related target architecture:** [PSC0 soundness and secure extensibility](PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md)  
**Evidence rule:** This file proposes source-language and verification requirements. It is neither a change to current PSCV0 v7 normative grammar nor evidence that PSC0 currently supports Rust systems programming or verifies emitted Rust.

## 0. Decision and scope

**Decision proposed:** extend ProofScript with an explicitly selected **Rust-target systems-programming profile** that can express real Linux kernel components and the components of a small new OS kernel. Prioritize a **verifiable systems subset**, not all Rust syntax, and use existing Rust compilation, borrowing, `no_std`, and kernel libraries rather than reproducing `rustc`.

It should be practical to author the *substantial logic and resource-aware code* of a driver or kernel subsystem in `.ps`, compile that code to reviewable Rust, and prove selected behavioral properties with Lean. Platform-dependent boot code, inline assembly, complex Rust macro expansion, and unsound-if-misused foreign operations may initially remain **small, explicitly identified Rust or assembly boundaries**. Those are not silently called verified ProofScript code.

**Proposed goals:**

1. Linux contributions: ProofScript-authored kernel state machines, algorithms, and later drivers through Linux's Rust APIs and Kbuild; generated Rust must be reviewable and fit the selected subsystem's actual interfaces.
2. New OS: build increasingly large `no_std` kernel components with explicit layout, capabilities, resource management, interrupts, virtual-memory abstractions, and system-call/IPC protocols.
3. Verify claims that matter: functional invariants, bounds, resource ownership, protocol transitions, lock/context discipline, and selected implementation-to-specification correspondence.
4. Reduce routine Rust ownership difficulty through conservative inference and safe wrappers. Do **not** silently insert clones, atomics, runtime borrow cells, heap allocation, or blocking operations to appease borrow checking.
5. Preserve independent Lean kernel checking for every claimed theorem. Ordinary Rust output, an accepted Rust borrow check, and a mathematically verified executable are three different claims.

**Non-goals for the first release:** complete Rust source compatibility; full Rust macro/trait syntax in `.ps`; verified arbitrary unsafe Rust; full Linux C API coverage; a theorem that all generated binaries preserve ProofScript semantics; rewriting the existing PSC0 self-host compiler; replacing PSKernel Core or changing its trusted rules; requiring every kernel component to be total or free from runtime/environment assumptions.

### 0.1 What this proposal does *not* supersede

The authoritative [v7 `.ps` reference](../PSCV0_LANGUAGE_REFERENCE.md) currently treats ProofScript as a selected Lean-semantic subset. Its exclusions of source `partial`, `unsafe`, and `axiom` are valid **within its existing profile**. This proposal deliberately does **not** edit, override, or silently reinterpret v7.

A future adoption requires a separate versioned language-profile decision. Systems-only syntax and execution semantics may exceed the Lean subset, but that extension has **no authority to add Lean proof axioms or change the kernel**. The Rust target alone MUST NOT activate systems-only syntax or relax the source profile; source/profile/target selection must be explicit and replayable.

### 0.2 Profile and target separation

| Proposed identity | Source acceptance | Execution | Proof authority |
|---|---|---|---|
| `pscv0` (existing) | v7 closed `.ps` grammar and Lean-grounded restrictions | Existing admitted outputs | Existing Lean-compatible proof checking |
| `ps-systems-rust/0` | v7 common syntax **plus** explicitly named Rust-only systems forms; ordinary partial/effectful runtime functions admitted | Rust-backed, may use safe `no_std` facilities | Runtime code is NOT automatically a transparent Lean definition |
| `ps-systems-rust-verified/0` | Same systems language; mandatory selected contracts, dependency and representation obligations | Rust-backed, with an auditable model and checked proof obligations | Lean checks logical proof terms; correspondence to Rust is separate evidence |
| `ps-systems-rust-raw/0` | Explicit privileged boundaries for raw pointers, `unsafe`, assembly/FFI where available | Rust/platform-specific | Assumed, audited or independently verified boundaries only; never automatically closed proof |
| `ps-linux/0` | Additional Linux-versioned API/context restrictions over `ps-systems-rust` | Kernel Rust through selected Kbuild/toolchain | Kernel ABI/behavior assumptions reported |
| `ps-microkernel/0` | Additional freestanding ABI, architecture and kernel services | A standalone `no_std` kernel target or seL4 Microkit service | Target and hardware assumptions reported |

These names and version numbers are **candidates**, not current PSC0 command-line flags or shipped package identities. Do not infer `ps-systems-rust-verified` from a successful `rustc` invocation. Selecting the `raw` capability may permit a non-certified executable; it does not relax Lean proof checking.

## 1. Empirical foundations and trade-offs

| Upstream evidence | Design implication | Important limit |
|---|---|---|
| Rust Reference: references, moves, destructors, `unsafe`, type layout | Reuse `rustc` for borrow/move checking and code generation | Borrow checking is not verification of driver protocols or foreign behavior |
| Lean 4 compiler/runtime and PSCV0 v7 | Reuse pure Lean models, inductives, dependent/refined data and proof checking | Lean ordinary values are not automatically affine resources or C-compatible layouts |
| Linux Rust `no_std`, kernel abstractions and misc-device sample | Target *actual* driver APIs, fallible allocation, pinned initialization and kernel conventions | Linux subsystem APIs and toolchain constraints vary by kernel revision/configuration |
| Verus, RefinedRust and Aeneas | Adopt selective contracts and proof-to-runtime correspondence strategies | Each tool supports a bounded fragment; none verifies arbitrary Linux kernel code |
| seL4 Microkit, Tock OS | Favor capability-restricted components and a small low-level boundary | Existing seL4/Tock proofs do not transfer automatically to a new ProofScript kernel |

Do not describe all Rust values as zero-cost/zero-overhead: copies, locks, reference counts, trait dispatch, heap allocations, panics, and foreign operations have real semantics and costs. Default ProofScript `Nat` and Lean `Array` also cannot silently become Rust `usize` and `Vec<T>` without a representation and behavioral contract.

## 2. Feature classification: source grammar versus libraries versus target facilities

**Rule:** A capability should be a library if an existing type/API can express it faithfully; use new source syntax only where source-level ownership, effect, layout or control-flow enforcement genuinely requires it.

The classification below is **proposed**, not a statement about current PSC0 parser support.

| Feature family | Required capability | Owner | Priority | Verified claim that may be supported |
|---|---|---|---|---|
| Integer/bitvector operations | `UInt*`/`Int*`, `BitVec`, explicit wrapping/checked/overflow operations | Shared types + Rust emitter | P0 | Arithmetic and range proofs |
| Native value data | POD structs, tagged sums, fixed arrays, slices | Lean types plus target layout/library definitions | P0 | Shape, bounds and invariants |
| Runtime functions | General recursion, loops, early return, mutable local state and typed errors | Rust-only runtime grammar/effects | P0 | Step/safety invariants; not guaranteed termination |
| Ownership | Moves, consuming parameters, noncopyable handles | Rust profile static resource discipline | P0 | No accidental duplication/use-after-move |
| Borrowing | Shared and exclusive references; scoped and escaping borrows | Rust profile plus `rustc` | P0/P1 | Aliasing restrictions within supported safe Rust |
| Standard error interface | `Result`, `Option`, failure propagation | Rust-adapted library; optional `?` sugar | P0 | Error-handling and recovery invariants |
| No implicit heap | `core`-only compilation, explicit allocator API and failure | Toolchain/target + typed API | P0 | No unexpected allocator dependency |
| Kernel API wrappers | Typed handles, registration, locks and callbacks | `ps-linux` libraries and a small Rust glue boundary | P1 | Contract-conditional resource/state correctness |
| Memory layout and ABI | `repr(C)`, `repr(transparent)`, alignment, field offsets, calling convention | Allowlisted attributes and target checks | P1 | Checked layout obligations relative to target ABI |
| Heap resources | `Box`/kernel allocator equivalents, vectors, fallible allocation, RAII | Libraries plus resource tracking | P1 | Ownership and cleanup obligations |
| Pin and initialization | `Pin`, in-place construction, immovability, partial-init safety | Approved libraries/typed construction | P1 | Initialization, no move-after-pin |
| Memory-mapped I/O | MMIO region/register handles, volatile operations, device ordering | Capability library over low-level boundary | P2 | Register protocol conditional on device model |
| DMA | Buffer ownership handoff, cache-coherency and lifetime discipline | Capability/effect library | P2 | Transfer correctness conditional on hardware/IOMMU |
| Concurrency | Locks, atomics, IRQ-context permissions, blocking/sleeping restrictions | Libraries + effect/context rules | P2 | Lock/state invariants; ordering/liveness requires separate proof |
| C FFI | Typed symbol imports, target calling convention, representations | Restricted foreign boundary | P1 | Pre/post claims under explicit foreign assumptions |
| Raw pointers/assembly | Explicit unsafe operation and raw target attributes | Privileged profile only | P2/P3 | Not verified without separate memory/architecture model |
| Kernel boot/VM | Paging, traps, scheduler, IPC, context switching | Kernel libraries + architecture shims | P3 | Subsystem/machine refinement by selected architecture |

**P0/P1/P2/P3 mean implementation *priority*, not assurance levels.** Linux integration itself should start after P0 value, ownership and Rust emission are established.

## 3. Proposed source surface: minimal, readable Rust-only deltas

### 3.1 Grammar ownership and versioning

The PSCV0 v7 parser remains unchanged until this proposal is explicitly adopted. A future Rust extension may introduce:

- A distinct **systems runtime declaration category**, provisionally `systems function`, for operations whose body may be partial/effectful and is **not automatically available for theorem unfolding**.
- Resource-aware binder/type forms with `owned`, `borrow`, `borrow mut`, and optionally explicit lifetime variables when inference is insufficient.
- Braced `do { ... }` statement sequencing in systems function bodies, without changing the meaning of v7's ordinary single-term declaration wrapper.
- A small allowlist of Rust-specific attributes for ABI and layout (e.g. `@[rust.reprC]`) distinct from arbitrary user attributes.
- A separate, visibly privileged declaration/boundary category for unsafe Rust/FFI, plus a source diagnostic that disallows it in ordinary safe systems code.
- Rust target capability imports bound to exact manifest identities; installing a normal library cannot silently register new syntax or trusted proof facts.

These are **candidate spellings**, not frozen grammar. Admission requires one agreed grammar mapping, source-location rules, ownership/error diagnostics and both positive and negative acceptance examples.

### 3.2 Examples: illustrative only, not runnable v7 `.ps`

```proofscript
-- CANDIDATE ps-systems-rust source. Not valid in current PSCV0 v7.
systems function send(
  dev: borrow mut Device(Ready),
  request: owned Request
): KernelResult Unit := do {
  dev.submit(request)        -- `request` is consumed
  return ()
}
```

Intended rules: `dev` is an exclusive borrow, `request` cannot be reused after successful consumption, and a failure path has defined rollback/ownership behavior. `KernelResult`, `Device`, `Ready` and `Request` are **illustrative placeholders**, not existing guaranteed PSC0 standard-library names.

```proofscript
-- CANDIDATE Rust-only layout declaration; names are illustrative.
@[rust.reprC]
structure RingHeader where {
  producer: UInt32
  consumer: UInt32
}
```

This **does not** imply that a normal Lean structure automatically has Rust/C layout. The annotation must be target-gated and require admissible field representations and target layout validation. `repr(C)` must not be applied blindly to arbitrarily dependent or proof-bearing fields.

```proofscript
-- CANDIDATE ordinary runtime loop; no Lean termination theorem implied.
systems function runForever(driver: borrow mut Driver): Never := do {
  loop {
    driver.step()
  }
}
```

`Never` is a proposed Rust-runtime type correspondence. A loop that never returns can still have useful **partial-correctness and invariant proofs**. Liveness, fairness and eventual progress are distinct obligations.

### 3.3 Source-position and semantic hygiene

- All existing PSCV0 v7 **application-adjacency**, explicit binder, tuple/Unit, Lean-comment, and braced-body rules remain authoritative for the *portable* part of the language.
- Systems-only new tokens must have dedicated grammar contexts; do not silently reinterpret existing `function` or `by` forms based solely on the selected target.
- Avoid TypeScript false friends: `const` remains the established ProofScript declaration alias where portable; no ambient JS `any`, truthiness or prototype dispatch.
- Do not silently borrow Rust's parser as a fallback after the selected ProofScript grammar rejects a source file.
- Generated `.rs` files require reversible source maps/diagnostics for normal compiler errors. Their successful parsing is not enough to establish `.ps` elaboration fidelity.

## 4. Resource-aware static semantics

### 4.1 Core obligation

Lean's ordinary dependent types and ProofScript's existing `structure` declarations do not themselves prevent values from being duplicated or used after an owning resource has been transferred. A systems extension MUST introduce an **affine resource discipline** distinct from the Lean kernel's proof typing.

An abstract judgment can be written:

```text
Gamma ; Delta |- e : T ! EffectSet ; Delta'
Gamma = ordinary logical/value assumptions
Delta = live owned resources and active borrow permissions
Delta' = remaining resource state
```

This is a **proposed frontend judgment**, not a Lean kernel rule and not an implemented PSC0 representation. Proof terms about this relation must be ordinary kernel-checkable Lean terms under an explicit model.

### 4.2 Ownership requirements

1. **Move** consumes the prior owning binding unless its type is specifically `Copy`-like in the Rust representation. The source must not retain a callable alias that bypasses the move.
2. **Borrow** permits access within a statically bounded lifetime; shared borrows do not permit unsanctioned mutation.
3. **Exclusive borrow** prevents concurrent incompatible access until the borrow's validated lifetime ends.
4. **Drop/cleanup** is operational behavior, potentially effectful. It may run at scope exit and on error paths; a proof about a pure Lean value does not model destructor side effects by default.
5. **Explicit duplication** may be available for suitable values. Never insert hidden arbitrary resource clones, heap allocation, `Arc`, `Mutex`, or runtime borrow cells as a silent general-purpose repair.
6. **Escaping borrows** must obey lifetime and aliasing constraints; initial support may reject complex escapes and defer to a native Rust wrapper.
7. **Interior mutability** must be declared by the selected resource type/API; it is not implied by any logical equality or structure update.
8. **FFI handles** require a declared destructor/ownership policy, including what happens on partial initialization and failed acquisition.

Reuse `rustc` to check emitted Rust moves and borrows. This provides a strong backend validation gate but does **not** prove that the emitter preserves the source program's resource semantics. Unsafe dependencies must be audited/modelled independently.

### 4.3 Types and runtime representation

| Source family | Candidate Rust representation | Condition |
|---|---|---|
| `UInt8`, `UInt16`, `UInt32`, `UInt64` | Rust fixed unsigned integers | Use wrapping or checked operations as specified; no build-mode-dependent overflow behavior |
| `Int8`, `Int16`, `Int32`, `Int64` | Rust fixed signed integers | Preserve specified arithmetic and overflow conditions |
| `Nat`, `Int` | Arbitrary precision or strictly proved bounded specialization | **Never** silently map to `usize` / `isize` |
| `Bool`, `Unit`, products, selected structures | Rust values/enums/tuples where representation is valid | Match logical and erasure semantics |
| Lean `Array T` | Managed/COW representation or proven restricted native mapping | Rust `Vec<T>` is **not automatically equivalent** |
| Fixed array / borrowed slice | `[T; N]` / `&[T]` or `&mut [T]` under systems profile | Explicit extent, validity and ownership model |
| Proof and subtype evidence | Erasure according to approved Lean source relation | No runtime layout inference from a proof-carrying logical type |
| `Pin`/reference-counted/kernel handles | Versioned Rust wrapper types | Depend on approved lifetime/ownership API contracts |

This table is a *required correspondence inventory*, not a blanket equivalence declaration.

## 5. Systems effects, totality and verification

### 5.1 Two kinds of computation

**Logical computation:** total, Lean-grounded definitions and ordinary proof terms under PSCV0 v7 checking. These are suitable for invariant definitions and theorems.

**Systems runtime computation:** may loop forever, allocate, return errors, mutate resources, use synchronization and call external APIs. It is checked by the Rust-profile resource/effect discipline and `rustc`, not automatically transparent in Lean logic.

A `systems function` MUST NOT be elaborated as a transparent total Lean definition merely because its source looks like a normal function. Logical reasoning about it proceeds through an **explicit specification and a proved or assumed correspondence theorem**. An opaque declaration/contract alone is a statement of intent, not implementation proof.

### 5.2 Effect vocabulary and capabilities

Candidate effects include `Alloc`, `MayFail`, `Panic`, `Block`, `Sleep`, `Irq`, `Atomic`, `Mmio`, `Dma`, `Ffi`, and `Unsafe`. These names are **model tags**, not automatically adopted source keywords.

Prefer typed API/context capabilities over a global effect syntax when feasible. At minimum:

- An IRQ/atomic context MUST NOT call a potentially sleeping API unless a specific admitted transition changes the context.
- Allocation can fail and may depend on allocation flags/context; return typed errors where the kernel contract requires fallibility.
- `volatile`/MMIO access does not itself establish CPU memory ordering, coherent DMA, or hardware protocol correctness.
- Atomics need a target-specific memory-order model, not merely a syntactic `atomic` wrapper.
- Device and foreign callbacks need exact lifetime and reentrancy assumptions; lock-order and deadlock properties are not provided by Rust's borrow checker.

### 5.3 Partial correctness, totality and liveness

Verified kernel routines generally require a range of guarantees:

| Requirement | Example | Proof requirement |
|---|---|---|
| Safety invariant | ring indices remain in bounds | Inductive state-step proof |
| Resource invariant | no buffer used after transfer | Affine ownership/borrow check; external assumptions identified |
| Functional correctness | read returns selected bytes | Pre/post proof and implementation correspondence |
| Termination | `parseHeader` terminates | Well-founded measure or bounded loop |
| Partial correctness | event loop preserves device invariant | Inductive step invariant; termination not assumed |
| Progress/liveness | queued request eventually completes | Fairness/scheduling/device assumptions and temporal proof |
| Concurrency correctness | lock prevents invalid interleaving | Lock invariant, memory-order and scheduling model |

**MUST distinguish proof scope.** Proving a logical transition theorem is not proof that generated driver callbacks preserve it; the implementation-to-specification relation is a separate obligation.

### 5.4 Unsafe boundary admission

Ordinary safe systems code SHOULD be sufficient for the majority of drivers and system services. A raw target facility MAY admit unsafe Rust/FFI/assembly after:

1. Explicit source privilege and target identity (never imported invisibly).
2. A documented safety contract for every unsafe API or boundary type.
3. A versioned trusted-implementation locator and exact external dependency closure.
4. An assurance classification: **modeled assumption**, **audited implementation**, or **independently proved/refined implementation**.
5. Proven closure for any property that claims more than these assumptions warrant.

No registered tactic, plugin, build backend or raw operation may manufacture a kernel-admitted theorem or erase disallowed assumptions.

## 6. Linux kernel subprofile (`ps-linux/0`)

### 6.1 Actual integration strategy

Generate **reviewable native Rust** that uses the Rust APIs supplied by the selected Linux source tree. Use that Linux tree's supported Rust/Clang/LLVM/Kbuild configuration rather than assuming that a standalone Cargo build is sufficient.

Initial work should preserve Linux's `no_std` constraints, error conventions, kernel allocator interfaces, module registration/initialization, source documentation and required safety comments. The Rust-for-Linux documentation distinguishes raw C bindings from safer kernel abstractions; use safe abstractions first and add narrowly reviewed wrappers when necessary.

### 6.2 Feature matrix for Linux work

| Kernel use case | Necessary features | First implementation boundary |
|---|---|---|
| Pure parser/checksum/ring logic | Fixed integers, arrays, sums, total functions | PSCV0 model + safe Rust emission |
| Misc-device driver | Device registration, typed callbacks, owned handles, locks, errors | Selected Linux `kernel` crate APIs |
| Character/virtual device state machine | State transitions, ownership and lifecycle | Rust module adapter + proved abstract state machine |
| Platform driver | Device resources, fallible init, pinned storage | Kernel wrapper contracts |
| Interrupt work | IRQ context, atomics, lock discipline | Approved context capability types |
| MMIO register driver | Fixed layout, mapped regions, volatile and ordering | Raw region wrapper + hardware protocol assumptions |
| DMA device | Pinned/owned buffers, lifetime, alignment, coherency | Narrow DMA API and IOMMU/device assumptions |
| Filesystem/network subsystem | Shared state, concurrency, callbacks, resource lifetime | Later subsystem-specific extensions |

**Initial Linux example:** use the kernel's `samples/rust/rust_misc_device.rs` as a reference benchmark, not an assertion that its exact public API will remain unchanged across kernel versions.

### 6.3 Linux proof boundary

A verified driver claim SHALL state which part is proved:

- Source state-machine theorem in Lean.
- Resource/move/borrow checks for generated Rust.
- Interface-usage proof relative to pinned wrapper specifications.
- Generated Rust to logical-specification correspondence (if established).
- C/kernel ABI, scheduler, device, DMA and hardware assumptions.

A kernel contributor may submit generated `.rs` code with traceable `.ps` source and optional proofs, but Linux maintainers decide whether code is acceptable for upstream inclusion. Generated code needs idiomatic layout, comments, stable maintenance and normal review. A formal proof is not an automatic merge guarantee.

## 7. New OS-kernel subprofile (`ps-microkernel/0`)

The first OS target SHOULD be a **single-architecture, single-core, capability-oriented microkernel**, rather than a full Linux-class monolithic kernel. A smaller kernel surface allows reusable state-machine and interface proofs and reduces the number of privileged operations that must be modeled.

### 7.1 Layering

```text
ProofScript pure specs, proofs, total algorithms
    |
ProofScript systems components and typed capabilities
    |
Rust emission + borrow checking + optional correspondence evidence
    |
small no_std resource/interrupt/VM/IPC libraries
    |
architecture-specific Rust/assembly + hardware/platform assumptions
    |
bootloader, MMU, interrupts and hardware
```

Required topics for a standalone kernel: entry/boot ABI, linker regions, panic strategy, global allocation or no-heap policy, page tables and memory protection, interrupt/trap vectors, scheduling, synchronization, syscalls, IPC, capability security, timers, and target-specific assembly. Many can remain audited architecture libraries initially; the goal is **ProofScript authorship of substantial kernel logic** with explicit trust boundaries, not a misleading zero-Rust kernel claim.

### 7.2 Lower-risk intermediate target: seL4 Microkit

Before writing a new kernel, compile isolated ProofScript services to Rust for **seL4 Microkit protection domains** through its existing Rust bindings/runtime where applicable. This exercises `no_std`, IPC protocols, capability access, static resource assignment and system assumptions while reusing an existing microkernel.

Microkit's own security and proof claims are tied to its exact SDK, kernel configuration and platform; they do not automatically verify generated ProofScript services.

### 7.3 Bootable-kernel proof stages

1. Prove the mathematical state transition invariants for a toy allocator/queue.
2. Emit a `no_std` Rust module with a safe wrapper and show resource-checking behavior.
3. Add a single-core interrupt/timer interface with a pinned architecture model.
4. Build a tiny capability/IPC system and establish interface isolation invariants.
5. Add task scheduling and page-table models with selected refinement evidence.
6. Only then expand device/drivers/concurrency/multi-core proof scope.

A bootable binary is an engineering milestone, **not** an end-to-end proof of the entire kernel.

## 8. Rust compiler and proof-system integration

### 8.1 Compilation and checking lanes

```text
User .ps + explicit ps-systems-rust profile
   -> bounded source graph and versioned extension identity
   -> shared PSCV0 frontend for admitted portable forms
   -> owned systems elaboration: resources, effects, ABI, representation
       |                                        |
       |                                        +-> Lean specifications/VCs
       |                                             -> selected kernel checker
       v
   typed target IR with source provenance
   -> Rust source + pinned FFI/unsafe wrapper set
   -> rustc / Linux Kbuild type and borrow checking
   -> object/module/kernel image
   -> optional independently validated correspondence evidence
   -> host-owned artifact publication with explicit assurance label
```

The existing PSC0 architecture requires immutable checked-session authority; a new Rust backend MUST NOT replace that with an unchecked plugin success flag. At the same time, the new resource-type/effect checker is *not* a new Lean proof kernel. Portable logical admissions and target resource checking are different operations, with separately identified results.

### 8.2 Two emitter approaches

| Approach | Benefit | Limitation |
|---|---|---|
| Lean-runtime-compatible Rust | Faster potential coverage for persistent `Array`, strings and closure behavior | Runtime footprint and refcount/allocator assumptions; poor initial `no_std` kernel fit |
| Native Rust systems subset | Predictable ownership, layout and `no_std`; suitable for drivers | Smaller feature coverage; more target-specific IR and proof correspondence work |

Use the **native Rust systems subset** for the first kernel prototype. No silent fallback from a native systems type to an RC-managed Lean runtime representation when the target promises no hidden allocations.

### 8.3 Toolchain and artifact identity

Freeze at least: Rust compiler binary and target triple; std/core/alloc profile; selected Linux commit/config or Microkit SDK/board; Kbuild/LLVM/linker inputs; generated source and wrappers; kernel/Lean pin; source/profile registry identity; approved foreign dependency identities; and assumption/model/proof digests.

Treat compiler success, borrow checking, kernel checking, verification-policy closure, target semantic preservation and binary provenance as **separate claims**. This follows [PSC0-ARCH/1](PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md), not a new permission for backends to publish verified artifacts.

## 9. Proposed proof and assurance levels

| Label (proposed) | Meaning | Explicit nonclaim |
|---|---|---|
| `rust-compiled` | Pinned Rust toolchain accepted generated/native target code | No functional-correctness proof |
| `rust-resource-checked` | Selected resource rules and Rust borrow/move checking accepted | No proof of unsafe/foreign behavior |
| `logic-model-verified` | Selected specification/invariant has checked Lean proof terms | No proof emitted implementation refines the model |
| `implementation-correspondence-verified` | Checked evidence relates **specific emitted implementation** to a model for specified properties | No universal backend correctness unless independently proved |
| `boundary-assumption-verified` | Verified relative to listed, approved low-level/API/hardware assumptions | Not a closed hardware or Linux correctness theorem |
| `closed-verified` | All obligations required by the **exact declared scope** are proved, with only the explicitly accepted logical/physical premises | Not a blanket claim about all Linux/architecture/environment behavior |

An output receipt MUST state its assurance scope, unverified boundaries and exact source/target/toolchain identity. `rust-compiled` MUST NOT be called `verified` by default. Source `unsafe` or `partial` may be accepted in the non-certified systems profile without allowing them to contaminate a fully proved logical dependency closure.

## 10. Initial normative acceptance matrix (proposed, not executed)

These are **requirements for a future implementation**. They are not test results.

| ID | Scenario | Expected disposition | Phase |
|---|---|---|---|
| SYS-P01 | Portable PSCV0 function, Rust backend selected, no systems extensions | Preserve v7 grammar and Lean meaning | SOURCE/ELAB |
| SYS-P02 | Explicit systems profile, finite safe owned buffer move | Accept iff ownership preserved | RESOURCE + RUSTC |
| SYS-N01 | Use a consumed owned resource after move | Reject | RESOURCE/RUSTC |
| SYS-N02 | Two overlapping exclusive borrows without an admitted disjointness proof | Reject | RESOURCE/RUSTC |
| SYS-N03 | Borrow escaping an invalid lifetime | Reject | RESOURCE/RUSTC |
| SYS-N04 | Implicitly add `Arc`, heap allocation or clone to resolve borrow failure | Reject as an automatic silent fix | COMPILER POLICY |
| SYS-P03 | Explicit typed error on failed allocation | Accepted when target API available | ELAB/RUSTC |
| SYS-N05 | Attempt to call a sleeping API from IRQ context | Reject absent valid context transition | EFFECT/CONTEXT |
| SYS-N06 | Represent `Nat` as `usize` without a range/correspondence proof | Reject target mapping | REPRESENTATION |
| SYS-P04 | `@[rust.reprC]` structure of permitted ABI fields | Accept with ABI checks | TARGET/ABI |
| SYS-N07 | `repr(C)` over an unrepresentable dependent/proof field layout | Reject | TARGET/ABI |
| SYS-N08 | Raw pointer dereference in the safe systems profile | Reject; require explicit privileged boundary | SOURCE/CAPABILITY |
| SYS-P05 | Privileged unsafe wrapper with declared safety contract | Permit non-certified Rust; report trust class | BOUNDARY |
| SYS-N09 | Treat a foreign API contract as independently proved because it typechecks | Reject verified claim | ASSURANCE |
| SYS-N10 | Partial runtime loop unfolded as transparent total Lean theorem | Reject logical use | PROOF/ASSURANCE |
| SYS-P06 | Proof of abstract state-machine invariant | Accept only kernel-checked proof | PROOF |
| SYS-N11 | Abstract proof used to claim executable correctness without correspondence evidence | Reject claim | ASSURANCE |
| SYS-P07 | `no_std` target with no allocator-dependent operations | Accept for compatible target/wrappers | TARGET |
| SYS-N12 | Implicit hidden heap/RC dependency in no-allocation profile | Reject | TARGET/EFFECT |
| SYS-P08 | Selected Linux misc-device wrapper backed by exact kernel API snapshot | Accept only if matching target/API contracts | TARGET/LINK |
| SYS-N13 | Unpinned kernel/Cargo/procedural-macro source silently adds proof authority | Reject | ENV/ASSURANCE |
| SYS-N14 | Unknown target-specific syntax in portable PSCV0 source | Reject; no Rust parser fallback | SOURCE |
| SYS-P09 | Rust kernel build and Lean proof both succeed but no translation theorem exists | Report separately as compiled + model-proved, not executable-verified | RECEIPT |

The acceptance suite should separately test *source rejection*, *Rust compiler rejection*, *VC failure*, *kernel rejection*, and *verified artifact refusal*. A Rust compilation error does not count as a passing Lean-proof-rejection test.

## 11. Proposed implementation order and cheap path

| Stage | Concrete deliverable | Stop condition / evidence |
|---|---|---|
| S0 — Language contract | Define versioned systems profile, source/target separation, resource judgment, effect and assurance classifications | Document review and source-to-operator traceability; no implementation claim |
| S1 — Safe native Rust emitter | Selected fixed-width arithmetic, structs/enums, total functions, `no_std` values | Executable Rust acceptance, exact source semantics checks on declared subset |
| S2 — Resource-aware source | Owned handles, borrowed slices, explicit moves, fallible allocation | Negative ownership/context cases and no hidden-allocation policy |
| S3 — Linux misc-driver | ProofScript-owned driver state machine + safe Rust kernel glue | Linux build/driver smoke + checked invariant theorem; honest boundary ledger |
| S4 — Implementation correspondence | One nontrivial state transition related to its actual emitted Rust | Independent checked proof/translation-validation evidence for precisely stated scope |
| S5 — Wider kernel APIs | Pinning, registration, locks, MMIO and selected async work queues | Per-API versioned safety/effect contracts and tests |
| S6 — Microkit service | Isolated `no_std` service and IPC protocol proved at the source-model level | Correct board/SDK runtime and checked protocol theorem |
| S7 — Small OS kernel | Bootable single-core microkernel with selected verified subsystems | Architecture assumptions, composition and preservation evidence |
| S8 — Research expansion | DMA, multi-core weak memory, scheduler liveness, unsafe boundary refinement | Independent model/refinement results; no deadlines or completeness claims |

**First acceptance exemplar:** a very small misc-device state machine with `Uninitialized -> Registered -> Active -> Removed`, a fallible registration path, a lock-protected value, ownership-safe cleanup, and a proved transition invariant. The kernel may expose the final wrapper as native Rust for any APIs not yet expressible in `.ps`. The initial proof claim concerns the *state machine*, not Linux itself. A later stage must establish that the emitted implementation follows it.

## 12. Interaction with current PSC0 v7 adoption and self-hosting

The repository's active authoring plan deliberately treats [v7 as the only future source-language authority](PSCV0_V7_ONLY_SOURCE_POLICY.md) and identifies current bridge support as a **bounded subset**, not full v7. This systems document is therefore **a future, separate proposal**, not license to add an older `.ps` grammar mode, silently loosen today's parser, or relabel the compiler as systems-capable.

If adopted later:

- Put portable syntax and type elaboration in the existing source owners, but avoid putting target-specific raw Rust operations into the shared Lean kernel.
- Keep the Rust emitter and platform API libraries outside the mandatory self-host bootstrap closure until an explicit migration gate selects them.
- Keep source-only npm imports separate from executable plugin trust; rustc, Kbuild and generated native code are target processes, not proof or release authorities.
- Preserve all earlier checked compiler/kernel receipts and independently record new Rust-target evidence; no source history deletion or non-force branch rewrite.
- No automatic upgrade of ordinary `pscv0` or `ps-standard` to `ps-systems-rust`; there is one explicit profile per source graph/artifact claim.

## 13. Decisions to resolve before promotion from proposal

1. **Source grammar:** whether to use `systems function`, a declaration attribute, or an explicit file-level Rust profile; exact bodies, resource binder grammar and fallback behavior.
2. **Resource model:** choose the minimal affine ownership judgment and how resource operations are represented for proofs; ensure that the logical specification has a model even when the executable is not Lean-reducible.
3. **Inference policy:** determine the narrow inferable borrow/move cases and required explicit annotations. Reject ambiguous cases rather than inventing clones.
4. **Representation:** define which `Nat`/`Int`/`Array` values can be emitted natively without changing semantics; pin ABI/layout and proof-erasure rules.
5. **Effects and errors:** select core `Result`/allocator/context APIs and initial proof obligations; do not start with a full universal concurrent effect logic.
6. **Verification boundary:** decide required proof coverage for the first misc-device exemplar and what may remain audited or assumed.
7. **Linux integration:** choose a pinned Linux commit/config and safe Rust kernel APIs; do not promise that a generated module is upstream-ready before maintainer review.
8. **Target toolchain:** specify `rustc`/LLVM/Kbuild capture, provenance, staging and error mapping using the existing host-owned publication policy.
9. **Long-term kernel platform:** choose Microkit integration versus a standalone bootable single-core kernel as distinct milestones.

These are open **design choices**. They should not be filled in with unsupported claims about existing PSC0 code.

## 14. External research and source concordance

Research sources describe available upstream capabilities; they are **not** an implementation or proof of this proposal.

- [Rust Reference — pointer types and borrowing](https://doc.rust-lang.org/reference/types/pointer.html)
- [Rust Reference — type layout and representations](https://doc.rust-lang.org/reference/type-layout.html)
- [Rust Reference — the unsafe keyword](https://doc.rust-lang.org/reference/unsafe-keyword.html)
- [Rust Reference — destructor scope and drop behavior](https://doc.rust-lang.org/reference/destructors.html)
- [Rust Reference — operator expressions](https://doc.rust-lang.org/reference/expressions/operator-expr.html)
- [Linux kernel Rust — general information, `no_std` and abstractions](https://www.kernel.org/doc/html/latest/rust/general-information.html)
- [Linux kernel Rust — coding and `// SAFETY` documentation requirements](https://www.kernel.org/doc/html/latest/rust/coding-guidelines.html)
- [Linux kernel Rust — quick start](https://www.kernel.org/doc/html/latest/rust/quick-start.html)
- [Linux reference misc-device sample](https://github.com/torvalds/linux/blob/master/samples/rust/rust_misc_device.rs)
- [Verus verified Rust project](https://github.com/verus-lang/verus)
- [Aeneas verification toolchain and documented limitations](https://github.com/AeneasVerif/aeneas)
- [RefinedRust project](https://plv.mpi-sws.org/refinedrust/)
- [seL4 Microkit user manual](https://docs.sel4.systems/projects/microkit/manual/latest/)
- [seL4 Rust userspace and Microkit bindings](https://docs.sel4.systems/projects/rust/tutorial/introduction.html)
- [Lean 4.35.0-rc4 source pin](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364)
- [PSC0 v7 current implementation/adoption matrix](PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md)
- [PSC0 target toolchain trust boundary](PSC0_TARGET_TOOLCHAIN_BOUNDARY.md)

The external Rust/Linux links are moving upstream references; any future *normative* systems edition MUST freeze exact commits, toolchains, API snapshots and environment identities before claiming target or proof conformance.

---

**Bottom line:** An incremental, verifiable `ps-systems-rust` subset can be valuable for both real Linux contributions and a new small OS kernel without reproducing full Rust. The economical route is **Lean-checked abstract models + resource-aware `.ps` syntax + safe Rust/Kbuild reuse + tiny explicit low-level boundaries + separately proved implementation correspondence**. This document proposes that route; it does not assert that PSC0 implements it today.
