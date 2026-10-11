# ProofScript PSCV0 v7 — Rust-Native Verified Programming Extension

**Status:** REVISED DESIGN PROPOSAL — **not adopted, not implemented, not compiler-conformant**  
**Proposal edition:** `PS-RUST-NATIVE/0` (revision 2, 2026-10-11)  
**First backend:** Rust source generation through a selected `rustc` toolchain  
**Reference authority:** [PSCV0 v7 language reference](../PSCV0_LANGUAGE_REFERENCE.md), exact repository-adopted SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`  
**Lean logic pin:** Lean 4.35.0-rc4, commit [`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364)  
**Architecture boundary:** [PSC0-ARCH/1](PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md); [PSCV0 v7 source-only policy](PSCV0_V7_ONLY_SOURCE_POLICY.md)  
**File location:** `psc0/docs/PSCV0_V7_RUST_SYSTEMS_LANGUAGE_EXTENSION.md` (retain the old filename to preserve links).

> **Status invariant:** Nothing in this document changes today's PSCV0 v7 source language, trusted kernel, installed runtime or supported backends. All proposed spellings and examples below are *design illustrations*, **not accepted `.ps` code or executed proofs**. No Rust build, Lean compilation, or conformance test is claimed by this revision.

## 0. Decision — cross-domain correctness, Rust first

**Proposed direction:** make ProofScript a practical **Rust-native verified programming language** for native libraries, parsers, codecs, storage engines, protocols, networking services, embedded/real-time components, compiler/runtime infrastructure, and eventually Linux drivers and OS kernels. **Do not optimize the whole language around Linux alone.** Linux and freestanding targets should be *optional platform profiles* using the same small foundational language extension.

The distinguishing value is **combining Rust's existing memory-safety/resource discipline with Lean-checkable functional specifications**, not pretending Rust is unsafe, recreating all of Rust's syntax, or guaranteeing proof of arbitrary native code.

**Four intentionally small additional source/semantic families:**

1. **Native runtime declaration classification.** Distinguish a Rust-executed function from a transparent total Lean definition. Reuse Lean's existing total recursion, `termination_by`, selected `partial_fixpoint` and intrinsic contract mechanisms when their actual applicability suffices. A target-only native marker supplies otherwise missing operational semantics.
2. **Ownership and borrowing.** Only the minimal source-visible resource roles: ownership/consumption, shared borrowing and exclusive mutable borrowing; allow conservative inference of call-site borrows and moves. Reuse `rustc`'s real borrow checker.
3. **Native layout and ABI declarations.** A small, frozen attribute/binding inventory, not a second record/type system and not a full Rust attribute grammar.
4. **Explicit privileged foreign/low-level boundary.** Raw pointers, FFI, platform intrinsics and unsafe operations only in explicitly identified wrappers/capabilities, with separate assumptions and proof obligations.

**Everything else should first be a library or target option**: `Vec`, slices, `Result`, error propagation, allocation, atomics, MMIO, async cancellation, transaction models, serialization, tensor shapes, cryptographic primitives, target toolchains and linker configuration.

**Non-goals for the first edition:** full Rust syntax/traits/macros/async ownership; automatically verified unsafe or concurrent Rust; arbitrary C++ ABI interop; replacing Lean's kernel with Rust checking; LLVM or Rust MIR emission from PSC0; Linux kernel upstream acceptance; a verified Rust compiler; a second logical type theory.

### 0.1 Three separate meanings of "correct"

- **Rust-checked:** emitted Rust is well typed and accepted by its selected borrow checker; valid safe-Rust use inherits Rust's memory-safety guarantees under its unsafe dependencies and assumptions.
- **Logic-model-verified:** an explicit theorem or invariant about an abstract/program model has kernel-checked Lean evidence, relative to named axioms and imports.
- **Implementation-correspondence-verified:** additional checked evidence relates the *specific emitted Rust behavior* to the model/property. Neither a Rust compile nor a logical theorem alone establishes this stronger claim.

These distinctions MUST appear in every later build/assurance policy and output receipt. Upstream Rust's own type system is not a general-purpose proof of functional behavior, crash durability, noninterference or hardware correctness.

## 1. Source authority, profiles and adoption boundaries

### 1.1 Do not silently weaken existing PSCV0 v7

[PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md) remains the **sole currently adopted forward-looking `.ps` language reference**, with selected Lean 4.35.0-rc4 semantics. Its source `partial`, `unsafe`, `axiom`, unregistered syntax and proof-hole restrictions remain unchanged for `pscv0`. Existing `.lean` source/archival bootstrap material and prior CI receipts are separate historical/implementation lanes, not a syntax fallback.

A *future* Rust native source profile may accept functions that are nonterminating, effectful or resource-owning, and may admit explicitly privileged boundaries. This is an **explicit new semantic profile**, not a claim that such programs are transparent Lean definitions or that their Rust behavior is established by the Lean kernel.

Selection must be explicit in the source-graph/profile/target identity; **choosing a Rust backend must never, by itself, turn forbidden PSCV0 source into accepted source**.

### 1.2 Proposed identity dimensions

| Dimension | Candidate identity | Semantic consequence |
|---|---|---|
| Source language | `pscv0` | Existing Lean-grounded, v7-closed grammar and ordinary/verified assurance rules |
| Source language extension | `ps-rust-native/0` | Explicitly adopted selected native declarations, resource qualifiers and target bindings |
| Target | `rust-hosted/0` | Rust `std`/selected native-library runtime, pinned toolchain |
| Target | `rust-core/0` | `no_std`/`core` subset; allocation requires separately selected `alloc` and allocator |
| Target | `rust-linux/0` | Pinned Linux kernel tree, kernel API wrappers, Kbuild and context policies |
| Target | `rust-freestanding/0` | Entry/startup/linker/ABI rules for selected embedded or kernel platform |
| Capability | `native-privileged/0` | Independently declared unsafe/FFI/raw boundary; **not** proof authority |
| Assurance | `rust-checked` / `logic-model-verified` / `implementation-correspondence-verified` | Separate evidence, never automatically upgraded |

Names are candidates, not shipped command-line flags. Portable v7 functions can be targeted to Rust **without enabling the extension** if the selected backend preserves their semantics. Future non-Rust backends must define their own execution mappings; they do not automatically inherit Rust resource guarantees.

### 1.3 Scope of earlier proposal

The former `PS-SYSTEMS/0` emphasis on Linux drivers and a new OS has been **demoted to optional advanced use cases**, not deleted. The current proposal moves the common native/resource/verification substrate ahead of kernel-specific concerns. Preserve prior branch history, CI receipts and the exact v7 reference digest.

## 2. What PSCV0 v7 and Lean already provide

Reuse actual Lean mechanisms before introducing duplicate ProofScript grammar.

| Capability | Existing source or Lean foundation | Rust-extension implication |
|---|---|---|
| `Prop`, `Type`, Pi, equality, `Subtype`, `Fin`, indexed data | PSCV0 v7 / Lean core and libraries | Keep for specifications, bounds and abstract models |
| `structure`, `inductive`, matches, dependent matches, `if let` | Selected v7 source | Reuse for models, enums and pure Rust-admissible values |
| `Nat`, `Int`, `UInt*`, `Int*`, `Float*`, `BitVec`, `Array`, `ByteArray` | v7 catalog with pinned import/instance requirements | Define exact target representation, not name-based equivalence |
| `do`, immutable and mutable local bindings, loops and errors | Selected v7, staged P1 where marked | Do not relabel pending P1 source as already conformant |
| `termination_by`, `decreasing_by` | v7 selected well-founded recursion | Preferred for provably terminating algorithms |
| Lean `partial_fixpoint` | Upstream Lean recursion technique; **not automatically v7 admitted** | Evaluate selective adoption for supported partial-equation reasoning before inventing recursion constructs |
| Lean `partial def`, `unsafe def` | Upstream Lean runtime/logic distinction; **v7 excludes source forms** | Optional runtime profile may admit a deliberately selected opaque/unsafe boundary with exact rules |
| Lean `@&` borrowed argument annotation | Lean 4.30+ compiled borrow/RC optimization | Helpful for Lean-runtime optimization, **not** Rust's general affine lifetime model |
| `given`, `requires`, `ensures`, `assert`, `erased`, invariant/decreasing annotations | Selected experimental RC4 intrinsic verification + `Std.WP` prerequisite | Reuse vocabulary; a Rust implementation requires a separate operational model and correspondence |
| `theorem`, `by`, `simp`, `omega`, `grind` and selected tactics | v7 proof selection | **No new proof language** for Rust |

**Upstream constraints:** Lean `partial` definitions are opaque in logic; `unsafe` functions are excluded from normal logical reasoning; `partial_fixpoint` admits only certain recursion patterns and does not promise arbitrary total correctness. Lean user `@&` annotations help reference-counted C emission, not Rust lifetime checking. RC4 intrinsic verification is experimental; proof-object checking and proof-to-runtime correspondence remain separate.

**Lean's C emitter is not a freestanding-C semantics guarantee.** Its usual representation expects Lean runtime services for allocation, reference counting and data layout. A `no_std` Rust target must use deliberately chosen representations and library dependencies instead of assuming Lean-generated C is already a low-level zero-runtime backend.

## 3. Cross-domain use cases drive the feature choices

| Real application family | High-value correctness goal | Shared ProofScript features; domain-specific library |
|---|---|---|
| Binary formats, codecs and parsers | Bounds, exact decoding, canonical round-trip, malformed-input rejection | `Fin`/`Subtype`, bitvectors, read-only slices, proved codec combinators |
| Databases, filesystems, storage | B-tree/log invariants, transactional state, rollback, crash recovery | State transitions, functional models, durable-I/O specifications |
| Networking/proxies/protocols | Legal state transitions, length/flow control, cancellation correctness | Protocol automata, buffer borrowing, typed error/cancellation contracts |
| Cryptography | Arithmetic equivalence and selected secret-dependence properties | Bitvector proofs, native fixed width, specialized security models |
| Cloud runtimes/compilers | Semantic preservation and resource lifecycle | ADTs, transformation lemmas, owned native collections |
| Embedded/robotics | No hidden heap, admissible context/effects, range/actuator invariants | `no_std`, resource policy, bounded numeric models |
| Numerical/HPC | Bounds and shape correctness, explicit overflow/float assumptions | Indexed arrays, native representation, optional SIMD wrappers |
| Linux drivers/OS kernels | Driver lifecycle, device protocol, lock/IRQ/resource rules | Optional Linux/freestanding platform libraries, tiny low-level boundary |

**Initial showcase:** a **verified binary codec compiled to safe Rust**, followed by a zero-copy borrowed buffer and a small protocol state machine. These exercise cross-domain value with less trusted platform surface than a Linux driver. A whole database, full cryptographic constant-time assurance and a microkernel are **not** first-release requirements.

Do not introduce a global `transaction`, `packet`, `irq` or `kernel` keyword for these domains. Admit code through **reusable mathematical abstractions and typed libraries**.

## 4. Minimal source-language additions (proposal)

### 4.1 Native execution declaration — one role, preferably no new keyword

**Preferred candidate:** one allowlisted `@[native]` declaration modifier accepted **only** in `ps-rust-native/0`. It signals that the source declaration is an operational Rust function; its body may use selected native effect/resource syntax and **is not automatically a transparent Lean total definition**.

```proofscript
-- PROPOSED syntax: not currently valid PSCV0 v7.
@[native]
function runService(
  server: owned Rust.Server
): Rust.Result Unit Rust.IoError := do {
  loop {
    let request ← server.accept()
    server.respond(request)
  }
}
```

- `Rust.Server`, `Rust.IoError` and the `loop` body are **illustrative bindings**, not established PSCV0 APIs.
- `@[native]` is a newly selected attribute **candidate**, not a current v7 user attribute.
- A `partial`/general-recursive native function must not be silently represented as transparent Lean.
- Ordinary mathematical `function` remains the v7 rule when not in the native declaration category.
- Prefer already selected `termination_by` or upstream `partial_fixpoint` where an accurate Lean logical model is desired; adding `@[native]` does **not** establish such a model.
- If a new declaration category proves necessary, revisit syntax only after a concrete parser/semantic counterexample. Do not introduce a redundant `systems function` alongside `@[native]` in the initial proposal.

### 4.2 Minimal resource qualifiers and conservative inference

The *semantic* addition is an affine/resource typing discipline. Proposed source roles:

| Role | Candidate spelling | Intended mapping |
|---|---|---|
| Owned resource | `owned T` | Rust value owned by current binding, moved when consumed |
| Shared borrow | `borrow T` | Rust `&T` for a statically valid scoped borrow |
| Exclusive borrow | `borrow mut T` | Rust `&mut T` with exclusivity/lifetime constraints |
| Temporary call-site borrowing | Unwritten where unambiguous | Infer Rust borrow/reborrow, **not** arbitrary cloning |
| Complex escaping borrow | Explicit lifetime/binding or Rust wrapper (later) | No forged/extended reference lifetime |

Do **not** claim that adding a Lean structure named `Owned` creates linearity. The systems frontend must enforce or correctly project moves, valid borrows, drop effects and ownership of failure results. Use `rustc` as the final authoritative borrow checker for the emitted safe Rust, not as a substitute for a source-to-Rust resource correspondence argument.

A formal reference judgment may use `Gamma ; Delta ⊢ e : T ! E ; Delta'`, where `Gamma` contains logical/value assumptions, `Delta` owned resources/borrow permissions, `E` effects and `Delta'` the resulting resource state. This is **proposed operational/static semantics**, not a new Lean kernel rule.

### 4.3 Representation/ABI selection

Proposed allowlisted syntax:

```proofscript
-- PROPOSED systems-only attribute; NOT current PSCV0 syntax.
@[native.reprC]
structure PacketHeader where {
  flags: UInt32
  length: UInt32
}
```

This must require every field to have an admissible native representation under the pinned ABI; it does not make arbitrary Lean inductives, proof fields or dependent structures C-compatible. Representations should include explicit size, alignment, offsets, endianness where relevant, calling convention and layout guarantees.

Start with Rust-owned scalar structs/arrays and selected `repr(C)` mappings. Defer packed unions, C bitfields and arbitrary Rust layout attributes to named wrapper modules unless a practical case justifies them.

### 4.4 Privileged boundary without proof privilege

Raw pointers, FFI, inline assembly, volatile/atomic operations and unsafe Rust belong in *explicitly opted-in, versioned boundary modules*. The first `ps-rust-native/0` needs typed references to approved external APIs; it need not expose inline assembly or unrestricted raw pointer syntax.

```text
native user code
  -> safe typed Rust API / resource contract
  -> explicit boundary manifest
  -> pinned Rust/C/architecture implementation
  -> external behavior: modeled / audited / separately proved
```

No ordinary npm package, crate, procedural macro, backend or tactic may silently register such a capability, introduce axioms into verified claims, or declare its own executable output verified.

### 4.5 No additional mandatory syntax families initially

Do NOT add mandatory Rust-like `fn`, `impl`, `trait`, macro, `&'a`, lifetime elision, `async`, `await`, `unsafe {}`, `Box<T>` punctuation, C-style pointer arithmetic or a universal effect keyword. These can be introduced **selectively and later** if source API usability demands them. Rust's full capabilities remain reachable through **native `.rs` modules and checked typed interfaces** where the `.ps` subset is insufficient, but that is project-level interoperability, not full Rust source compatibility.

## 5. Rust representation and arithmetic correspondence

**Rule:** the Rust backend MUST preserve the meaning of a portable v7 expression. Changing target must not silently change the mathematical meaning, lifetime semantics or public effects of the portable source.

| Portable / abstract | Rust-native candidate | Required conditions |
|---|---|---|
| `UInt8`, `UInt16`, `UInt32`, `UInt64` | `u8`, `u16`, `u32`, `u64` | Explicit wrapping/checked operations matching Lean values, not accidental debug/release overflow modes |
| `Int8`, `Int16`, `Int32`, `Int64` | `i8`, `i16`, `i32`, `i64` | Preserve specified signed/shift/division/overflow behavior |
| `Nat`, `Int` | Arbitrary-precision representation, or selected bounded conversion | **Never** silently use `usize`/`isize`; bounds/proof and error behavior explicit |
| `USize`, `ISize` | `usize`, `isize` where target model agrees | Freeze word width, numeric conversions and overflow semantics |
| `Bool`, `Unit`, products, ADTs | Rust primitive/tuple/enum where admissible | Define constructor, field, equality and proof-erasure correspondence |
| `Fin n`, `Subtype` | Native bounded scalar or owned value | Preserve invariant/erasure; checked conversion or approved proof |
| Lean `Array`, `ByteArray`, `String` | Lean-compatible managed view or explicitly native type | **Not** automatically Rust `Vec`, `Vec<u8>` or `String`; sharing, UTF-8, mutation and allocation modeled |
| Native `Rust.Vec T`, `Rust.Slice T` | Rust `Vec<T>` / `&[T]` | Separate library identity, ownership and borrowing rules |
| Native `Result`/`Option` | Rust standard versions | Explicit error/value mapping to Lean `Except`/`Option` where required |
| Native `Pin`, `Arc`, lock/FFI handles | Pinned Rust wrapper types | Exact destructor, aliasing, synchronization, safety contract |
| Native FFI structure | `repr(C)` or other selected representation | Target-specific ABI/layout constraints, no fabricated C++ ABI compatibility |

Default Rust arithmetic is not a license to substitute `a + b` for a specified modular or checked Lean operation without proving/codifying the same overflow behavior. Floating point needs equally explicit rounding/NaN/optimization assumptions. `no_std` means `core` availability, not automatically an allocator, stack setup, OS or Lean runtime.

## 6. Ownership, borrows, cleanup and performance policy

1. **Move/consume:** an owning binding becomes unusable after transfer when the type is noncopyable. A consumed resource cannot be reconstructed through a duplicated ProofScript logical value.
2. **Borrow:** shared borrows permit access without unsanctioned mutation; exclusive borrows exclude incompatible aliases. Escaping references have checked lifetime constraints.
3. **Call-site inference:** infer borrow or move only where callee signatures, resource types and a deterministic rule yield one valid meaning. An ambiguous call is a diagnostic, not a random codegen heuristic.
4. **Drop:** destructors and cleanup can be effectful; exact normal, error, early-return, panic/unwind and cancellation behavior must be represented for each supported target policy. Rust `Drop` is not automatically pure Lean computation.
5. **No invisible cost change:** do not silently add arbitrary `clone`, `Arc`, `Mutex`, `RefCell`, allocation, blocking or synchronization to repair a borrow failure; suggest an explicit user decision.
6. **Interior mutability:** only via selected types/contracts; Rust's safety is conditional on the correctness of unsafe internals in those abstractions.
7. **Zero-copy:** borrowed slices can be used as views over owned buffers, but lifetime, alignment and output ownership must hold. A zero-copy optimization must not change decoded logical results.
8. **Performance claims:** preserve explicit profiles such as "no implicit heap", "no blocking" and "fallible allocation", and report when a native library needs a more permissive policy. Formal worst-case execution time is a separate obligation.

### 6.1 Low-annotation example

```proofscript
-- PROPOSED ps-rust-native/0 spelling.
@[native]
function pushByte(
  bytes: borrow mut Rust.Vec UInt8,
  b: UInt8
): Rust.Result Unit Rust.AllocError := do {
  bytes.tryPush(b)
}
```

Call-site borrowing may be inferred; `tryPush` is an **illustrative wrapper**, not the currently established Rust `Vec` API. The wrapper must describe failure, capacity growth, ownership and cleanup. Rust's ordinary `Vec::push` is not a fallible-allocator API by itself, so this wrapper must not be assumed to exist without implementation and validation.

Rust equivalent *shape*:

```rust
fn push_byte(bytes: &mut Vec<u8>, b: u8) -> Result<(), TryReserveError> {
    bytes.try_reserve(1)?;
    bytes.push(b);
    Ok(())
}
```

The example does not prove a postcondition. It only illustrates conservative borrow mapping and a fallible allocation strategy.

## 7. Contracts, proofs, erasure and totality — reuse Lean vocabulary

### 7.1 Native behavior versus logical specification

An `@[native]` function may loop, allocate, panic, mutate native resources, borrow them, use I/O or call an external API. It is **not** automatically interpreted as a transparent total Lean function.

Its usable logical view must be one of:

- A separately defined *total* pure function or inductive state transition with ordinary checked theorems.
- A selected Lean partial-fixpoint definition with the supported equational/partial-correctness interpretation; this must be explicitly admitted and checked, not assumed from a similar runtime loop.
- A typed weakest-precondition/Hoare/specification relation over an explicit state and effect model.
- A named foreign assumption/axiom *in the model's assumption ledger* when implementation behavior is not proved; this is NOT permission for arbitrary user `axiom` declarations in `pscv0`.

A specification or `ensures` clause is **not** executable correctness evidence by itself. Runtime operations cannot acquire theorem-like logical unfoldability through an attribute or a Rust compiler success flag.

### 7.2 Reuse, do not fork, the proof language

Use the selected PSCV0 `theorem`, `by`, `simp`, `omega`, `grind`, `Subtype`, `Fin`, inductive invariants, and eligible RC4 `given` / `requires` / `ensures` / `assert` / `erased` forms.

**Important:** RC4's intrinsic `Std.WP` contracts are experimental and are defined for selected Lean effect/verification environments. Applying the same words to arbitrary native Rust operations would require a **new declared WP/resource model and explicit translation**. It is incorrect to state that Rust functions are thereby automatically supported by RC4's verifier. Keep generated `f.spec` proof attachment and exact contract clause ordering under their pinned Lean rules when that mechanism is reused.

When a proof is erased from Rust output, proof erasure must preserve all operational behavior required by the approved model. Erased logical evidence cannot determine runtime branches or observable foreign effects.

### 7.3 Partial correctness, total correctness and liveness

| Claim | Example | Necessary evidence |
|---|---|---|
| Pure total correctness | `decode(encode(x)) = ok x` | Lean proof plus implementation correspondence |
| Bounds validity | `index < length` | Checked type/arithmetical proof or safe bounds check |
| Resource safety | owned buffer cannot be reused after transfer | Static discipline and Rust checking; unsafe wrappers modeled separately |
| Partial correctness | invariant preserved by every service-loop step | Step theorem and operational mapping; no termination claim |
| Termination | parser/event handler terminates | Well-founded proof or bounded control argument |
| Cancellation safety | dropping async work leaves protocol valid | Cancellation/recovery model and applicable implementation proof |
| Crash recovery | disk state recovers committed transaction | Explicit I/O order, durability and failure assumptions |
| Security noninterference | secret does not affect observable output/timing | Selected leakage/target model, not just no secret-dependent branch |
| Concurrency correctness | lock/state invariant preserved | Interleaving/memory-order model and corresponding proof |
| Liveness | request eventually completes | Fairness, scheduler and environment assumptions |

## 8. Two principal verified-execution routes, plus explicit boundaries

### Route A — specification-derived Rust for a provable subset

```text
total PSCV0 definition -> Lean kernel-checked properties
           |
           v
 selected representation + code-generation correspondence
           |
           v
       safe Rust output + rustc
```

This should be the **first** route. One source definition can supply both the mathematical meaning and executable code when its representation, erasure and target operations admit a faithful translation. Verus's `exec_spec_verified!` research supplies a related *bounded* precedent, not a universal ProofScript lowering proof.

A plain successful Rust code generation does NOT establish the correspondence arrow.

### Route B — Rust implementation-derived functional model

```text
resource-owning `.ps` -> generated safe Rust -> rustc/MIR
                                  |
                                  v
                 selected Rust-to-functional translation
                                  |
                                  v
                        Lean model + theorem proof
```

Aeneas offers relevant functionalization of **supported safe Rust** for Lean and other provers; the supported subset and limitations change over time. Concurrency, unsafe code and some complex borrow/generic patterns remain independent research issues; never label unsupported code verified via Aeneas.

### Route C — low-level wrapper with explicit assumptions or stronger proof

For unmodeled FFI, hardware, unsafe memory, C++ libraries, assembly, or unsupported Rust constructs, rely on a small native wrapper. A wrapper's *signature* does not verify its implementation. The artifact must identify whether the wrapper is **modeled/assumed, reviewed/audited, or independently proved/refined** for the claimed property.

**Failure-closed assurance:** if a project requests implementation-level verification but has only model-level proofs, it must **reject the stronger artifact label**, not silently downgrade the claimed evidence or auto-admit assumptions.

## 9. Native effects and reusable high-value libraries

**Do not introduce a global systems-effect keyword until the typed-library route demonstrates a concrete gap.** Start with capabilities and contracts describing, where applicable:

| Effects or operations | Example libraries/domains | Important distinction |
|---|---|---|
| Allocation, failure, deallocation | collections, embedded, codecs | `no_std` can be allocator-free; `alloc` requires explicit allocator |
| Blocking/sleeping | networking, real-time, kernel | No-blocking type/effect policy not implied by Rust borrow checking |
| Cancellation and drop | async services, storage | A function can be memory-safe but not cancellation-safe |
| I/O, durable writes and crash | database/filesystem | Logical state proof != physical durability guarantee |
| Locks and atomics | concurrent servers, runtimes | Rust data-race safety != deadlock freedom or protocol correctness |
| Foreign/untrusted calls | C/C++/Rust crates | Imported signatures != verified external behavior |
| Volatile/MMIO/DMA | embedded and kernels | Volatile != coherent DMA or sufficient memory ordering |
| Secret-dependent operation | crypto | Constant-time guarantee needs a leakage/target model |

**Domain libraries before syntax:** binary codecs/parsers, byte slices and endian conversions; protocol state machines; transactional invariants; checked collections; native resource wrappers; fixed-point/control-range models; bitvector arithmetic; later numerical shape/SIMD, synchronization and crypto assurance.

### 9.1 Cross-domain exemplar: verified codec first

```proofscript
-- PSCV0-style LOGICAL sketch; not a completed proof or compiled fixture.
function highByte(x: UInt16): UInt8 := UInt8.ofNat(x.toNat / 256)
function lowByte(x: UInt16): UInt8 := UInt8.ofNat(x.toNat % 256)

function decodeWord(hi: UInt8, lo: UInt8): UInt16 :=
  UInt16.ofNat(hi.toNat * 256 + lo.toNat)

-- The proof obligation for a concrete exported implementation:
theorem wordRoundTrip(x: UInt16):
  decodeWord(highByte(x), lowByte(x)) = x := by {
  -- actual pinned bitvector/integer proof required
}
```

The theorem is **unproved in this document**. A future implementation must prove it under the selected environment and show that its emitted Rust native-byte operations correspond to this meaning. Noncanonical formats and malformed-input rules require separately stated predicates. This benchmark is reusable for networking, storage, images, compilers and embedded protocols.

### 9.2 Resource exemplar: bounded native append

```proofscript
-- PROPOSED native syntax. Types/predicates are placeholders.
@[native]
function appendBounded(
  out: borrow mut Rust.Vec UInt8,
  byte: UInt8,
  limit: Rust.USize
): Rust.Result Bool Rust.AllocError
  given (before: BufferModel)
  requires models(out, before)
  ensures r => appendPost(before, out, byte, limit, r)
:= do {
  NativeBuffer.appendBounded(out, byte, limit)
}
```

The intended postcondition distinguishes success, capacity-limit refusal and allocation failure, and states preservation of the preexisting bytes, final element and resource ownership. Neither `models` nor `appendPost` is currently a PSCV0 library declaration. The example is a *contract target*, **not** a claim that RC4 automatically proves a Rust-mutating function. The outcome also depends on the wrapper's exact failure and unwind behavior.

### 9.3 Protocol exemplar: abstract transitions first

Use an ordinary PSCV0 `inductive` state/event model; prove that invalid transitions cannot occur under a selected transition function. Then relate the Rust operation/driver state to that model. This is beneficial for network handshakes, parser modes, database transactions, device lifecycles and OS capability protocols.

## 10. Optional low-level/native-platform facilities

These capabilities are **necessary for some use cases**, but not required to validate the core language's value. Keep their low-level implementation in versioned libraries or small Rust/FFI modules.

| Facility | First route | Later verification task |
|---|---|---|
| Typed C ABI, symbol imports/exports | `extern` metadata and Rust `extern "C"` wrappers | ABI/layout, ownership, lifetime and callback assumptions |
| C++ interop | Stable C ABI bridge or explicit C++ wrapper | Native C++ ABI/template compatibility NOT inferred |
| Raw pointer/unsafe memory | Explicit approved Rust wrapper | Pointer provenance, initialization, alignment, aliasing, allocation proofs |
| Static storage/linker sections | Target attributes and linker configuration | Startup, initialization and placement assumptions |
| `no_std` freestanding | Rust `core`, optional `alloc`, board/OS runtime setup | Allocation and panic policy, ABI/platform assumptions |
| Atomics/locks | Selected Rust synchronization APIs | Ordering, fairness and protocol invariants |
| MMIO/DMA | Typed device/region capability libraries | Device ordering, memory coherence and ownership transfer |
| Pin/self-referential objects | Approved Rust `Pin` wrappers | Initialization and immovability invariants |
| Inline assembly/CPU intrinsics | Native Rust/assembly module | Machine-level semantics for claimed properties |
| GPU/SIMD | Target-specific native wrappers | Numerical, layout and target semantics as separate profile |

Linux and standalone kernels use these primitives; **they are not the initial definition of the language**.

### 10.1 Linux remains an advanced target

Use a pinned Linux kernel Rust API and Kbuild integration, not a generic Cargo-only assumption. A misc-device state machine remains a useful **later** benchmark: prove transitions and resource invariants, validate generated Rust ownership/lifecycle, then establish the implementation-to-model relation. IRQ constraints, fallible allocation, MMIO and DMA require separately approved kernel and hardware assumptions.

### 10.2 Small OS kernels remain advanced targets

For a new kernel, begin with a single-core capability-oriented microkernel or an isolated service on seL4 Microkit before a monolithic OS. Defer boot/interrupt vectors, page tables, custom allocators, scheduling, assembly, IPC and multi-core weak-memory verification to platform-specific stages. A bootable kernel is an engineering result, not automatically a whole-kernel correctness theorem.

## 11. Compiler placement and trust architecture

```text
versioned `.ps` source graph + selected profile and target identity
          |
          v
existing v7-selected parser/Lean-grounded elaboration (portable subset)
          |                       \
          |                        +-> total specifications/proof terms
          |                                    |
          |                                    v
          |                          selected independent kernel checker
          v
native resource/effect and ABI elaboration for `ps-rust-native/0`
          |
          v
typed target IR with exact source spans, ownership/effect provenance
          |
          v
readable `.rs` generation and selected approved wrapper imports
          |
          v
pinned rustc / target toolchain (type/move/borrow/native checks)
          |
          v
selected implementation correspondence and assumption/effect audit
          |
          v
host-owned staging, receipt and artifact publication
```

**Trusted boundary constraints:**

- A backend is an untrusted *output candidate producer*; it cannot mint a kernel-checked handle, alter proof rules, ignore rejected obligations, or publish a verified artifact by itself.
- Native operational resource typing is not a second Lean kernel. If proofs formalize its soundness, those proofs are Lean terms checked by the selected kernel.
- Generated source and Rust JSON diagnostics need dependable mapping back to `.ps` positions and exact dependency/environment provenance.
- Rust crates, build scripts and procedural macros are executable external dependencies; they require separate trust and toolchain policy. `rustc` success is not authentication or universal semantic preservation.
- Keep Rust source generation and wrappers **outside** the existing mandatory PSC0 bootstrap/self-host closure until explicitly adopted and qualified. Do not change the selected TypeScript 7 historical bootstrap or previous receipts.
- No source profile silently inherits new language syntax from imports or the target backend.

## 12. Prioritized feature roadmap: small language, broad utility

| Phase | Deliverable | Required evidence; nonclaim |
|---|---|---|
| **R0** | Freeze `ps-rust-native/0` grammar and semantic boundaries, type/resource/assurance matrix | Document-only decision; not proof of compiler conformance |
| **R1** | Generate safe Rust for bounded pure fixed-width functions, products/ADTs and a verified codec prototype | Rust compilation, semantic differential cases and *separately checked* codec theorem |
| **R2** | Exact implementation correspondence for a small pure/total subset | Property-scoped checked translation/refinement evidence; no universal backend theorem |
| **R3** | Typed Rust crate wrappers, native `Vec`/slice/`Result`, native-runtime declaration and basic effects | API, ownership, allocation and failure-path cases |
| **R4** | Conservative borrowed/owned inference and zero-copy codec | `rustc` accepted source, resource semantics checks; no hidden clone/allocation |
| **R5** | Resource contract/WP model and selected Rust-derived Lean verification | Audited assumptions, independently checked generated proof terms |
| **R6** | Protocol and transaction-state models, cancellation-safe effects | Invariant, failure and cancellation properties on a clearly scoped implementation |
| **R7** | ABI/FFI, `no_std`, fallible allocation, controlled low-level facilities | Pinned toolchain/ABI/target and explicit boundaries |
| **R8** | Advanced concurrency, embedded/real-time, cryptography, Linux and OS profiles | Domain-specific models and separately validated claims |

Stages describe **goals, not elapsed-time estimates or current completion**. Kernel, concurrency and verified-unsafe work do not block the cross-domain first benchmark.

### 12.1 First two acceptance exemplars

**Exemplar A — verified binary codec:** a v7 total codec, Lean-checked round-trip theorem, safe emitted Rust, exact native fixed-width meaning, negative malformed inputs and performance comparisons against handwritten Rust. Without a real implementation-correspondence proof, report `rust-checked` + `logic-model-verified`, **not** `implementation-correspondence-verified`.

**Exemplar B — borrowed native buffer:** a Rust-owned vector with a borrowed mutable view, fallible growth, no unintended implicit allocations, preserved contents on error, correct output resources and (where supported) a Lean proof of the specified postcondition related to the emitted implementation.

**These two exemplars matter more initially than an entire verified Linux driver.**

## 13. Conformance requirements (design fixtures; not executed)

| ID | Scenario | Required result and rejection owner |
|---|---|---|
| RN-P01 | Standard v7 pure function emitted to Rust without native profile | Preserve v7 acceptance and semantics; target may only change representation under correspondence |
| RN-N01 | A `@[native]` modifier in ordinary `pscv0` | Reject at source/profile selection |
| RN-P02 | Native runtime function with an intentionally nonterminating loop | Accept only under selected native operational rules; no Lean transparency claim |
| RN-N02 | Treat native nontermination/unsafe as a transparent total Lean proof | Reject logical/assurance use |
| RN-P03 | Native `Rust.Vec` with short exclusive borrow inferred | Accept if exact Rust borrow relation holds |
| RN-N03 | Use an owned noncopyable resource after move | Reject at resource analysis or `rustc`; no silent clone |
| RN-N04 | Two overlapping conflicting mutable borrows | Reject at resource analysis or `rustc` |
| RN-N05 | Escaping reference whose owner does not live long enough | Reject |
| RN-N06 | Compiler silently inserts `Arc`, `RefCell`, `Mutex`, clone or heap allocation as borrow repair | Reject compiler policy |
| RN-P04 | Fixed-width wrap operation maps to Rust `wrapping_*` correctly | Accept after semantic evidence |
| RN-N07 | `Nat` silently becomes target `usize` without range/model | Reject representation mapping |
| RN-N08 | Lean persistent `Array` silently becomes observable mutable `Vec` | Reject without approved correspondence |
| RN-P05 | Explicit native ABI struct with admissible fields | Accept with target ABI/layout checks |
| RN-N09 | `repr(C)` claimed for nonrepresentable proof/dependent fields | Reject |
| RN-N10 | Foreign function signature claimed proved solely by typecheck | Reject stronger assurance |
| RN-P06 | Kernel-checked theorem about an abstract codec/protocol state model | Accept `logic-model-verified` only |
| RN-N11 | Abstract proof claims correctness of emitted Rust without translation proof | Reject executable-verification label |
| RN-P07 | Bounded Rust-to-functional model for a supported borrowed safe-Rust subset | Admit proofs only with tool subset, target identity and evidence checked |
| RN-N12 | Unsupported Aeneas/foreign translation silently accepted as verified | Reject |
| RN-P08 | `no_std` value program without hidden allocator dependency | Accept on compatible selected target |
| RN-N13 | Hidden heap/RC dependency in declared no-heap target | Reject |
| RN-P09 | Selected audited unsafe wrapper used in ordinary native program | Permit with explicit assumed/audited boundary; no closed-verified label inferred |
| RN-N14 | Imported crate/macro changes proof authority or language grammar silently | Reject |
| RN-P10 | Native build and Lean theorem both succeed but correspondence is unknown | Report both facts separately, no executable correctness claim |
| RN-N15 | Native P1 async/protocol syntax unsupported by current selected profile | Reject source; do not fall back to Rust/old ProofScript parsing |

A negative test must fail **for the intended phase**: source/profile, resource/effect, Rust compilation, Lean proof construction, kernel rejection, target correspondence, or assurance/publication. A Rust borrow-check failure must not be counted as a passing Lean theorem-rejection test.

## 14. Prior research, optional advanced targets and unresolved questions

**Research-informed decisions** above are based on Lean/Rust reference material, Rust verification work, and the earlier Linux-specific proposal. External links are informational and may move; a conformant edition must freeze exact Rust toolchain, library and binding revisions.

### 14.1 Open decisions before adoption

1. Choose exact `@[native]` grammar and whether the native profile selects upstream `partial`, `partial_fixpoint`, or a dedicated opaque runtime-lowering category for each use. Do not mix their logical meanings.
2. Define the smallest Rust-owned/borrowed type representation, source-visible qualifier grammar and lifetime inference/rejection policy.
3. State which ordinary v7 terms may occur inside native runtime bodies and how Lean proof/specification terms are isolated from operational resource terms.
4. Define native type representation for every P0 exported type; establish wrapping/overflow, string, collection, proof erasure and ABI rules.
5. Select initial API bindings: `Vec`, slices, `Result`, allocation failure, library linkage; pin actual signatures rather than invent them.
6. Specify the exact subset of RC4 WP/contracts adaptable to native Rust effects and how contract proofs are attached without treating foreign models as theorem facts.
7. Choose the first property-scoped semantics-preservation strategy: shared-source verified lowering, translation validation, or Rust-functional model extraction.
8. Define toolchain and crate/macro/build-script trust, compilation diagnostics, source-map provenance and artifact receipts.
9. Decide performance constraints before permitting compiler-automated borrowing; document deterministic legal coercions and prohibited hidden allocations.
10. Select the exact first codec and native-buffer benchmark and their independent proof/resource/correspondence acceptance cases.

### 14.2 Lean and Rust references

- [PSCV0 v7 authoritative source](../PSCV0_LANGUAGE_REFERENCE.md)
- [PSC0 v7 source-policy](PSCV0_V7_ONLY_SOURCE_POLICY.md) and [adoption matrix](PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md)
- [PSC0 secure, extensible architecture](PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md)
- [Lean 4.35 RC4 source pin](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364)
- [Lean recursive definitions, `partial_fixpoint`, `partial`, `unsafe`](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/)
- [Lean 4.30 borrow annotations and LCNF compiler](https://lean-lang.org/doc/reference/latest/releases/v4.30.0/)
- [Lean 4.35 intrinsic-verification release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/)
- [Rust reference — pointer and reference types](https://doc.rust-lang.org/reference/types/pointer.html)
- [Rust reference — representations and layout](https://doc.rust-lang.org/reference/type-layout.html)
- [Rust reference — destructors](https://doc.rust-lang.org/reference/destructors.html)
- [Rust reference — unsafe keyword](https://doc.rust-lang.org/reference/unsafe-keyword.html)
- [Rust embedded `no_std`](https://doc.rust-lang.org/embedded-book/intro/no-std.html)

### 14.3 Verification projects and cross-domain precedents

- [Aeneas: supported Rust functionalization and documented limitations](https://aeneasverif.github.io/aeneas/)
- [Aeneas paper: Rust verification by functional translation](https://doi.org/10.1145/3547647)
- [Verus project](https://github.com/verus-lang/verus) and [supported `exec_spec_verified!` precedent](https://docs.rs/verus_builtin_macros/latest/verus_builtin_macros/macro.exec_spec_verified.html)
- [RefinedRust: refinement types and separation logic](https://plv.mpi-sws.org/refinedrust/)
- [Flux: ownership-aided Rust refinement verification](https://flux-rs.github.io/flux/)
- [Swift noncopyable types and ownership](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/ownership/)
- [EverParse verified parsers/serializers](https://github.com/project-everest/everparse)
- [CompCert: verified C compilation](https://compcert.org/)

### 14.4 Optional platform references

- [Linux kernel Rust: general information](https://www.kernel.org/doc/html/latest/rust/general-information.html)
- [Linux kernel Rust: quick start](https://www.kernel.org/doc/html/latest/rust/quick-start.html)
- [Linux kernel Rust: coding guidelines](https://www.kernel.org/doc/html/latest/rust/coding-guidelines.html)
- [Rust misc-device example](https://github.com/torvalds/linux/blob/master/samples/rust/rust_misc_device.rs)
- [seL4 Microkit user manual](https://docs.sel4.systems/projects/microkit/manual/latest/)

## 15. Revision disposition (previous `PS-SYSTEMS/0` → this proposal)

| Earlier proposal | Revision |
|---|---|
| Linux kernel/OS as primary benchmark | Binary codec + owned zero-copy buffer first; Linux and microkernel optional advanced profiles |
| `systems function` as mandatory new keyword | Prefer one profile-gated `@[native]` marker and existing Lean constructs where sufficient; keyword pending evidence |
| Rust semantics implied by target | Explicit versioned source/profile separation, no automatic relaxation of PSCV0 v7 |
| New verification vocabulary | Reuse Lean `theorem`, dependent types and RC4 contract syntax where *actually supported*; native WP model required |
| Specialized Linux effect model | Common allocation, failure, cleanup, cancellation, sync and foreign effect libraries; Linux-specific context libraries optional |
| Native Rust resource representation only | Separate Lean logical values, Rust-native owned resources and explicit shared values |
| Proof of abstract state model as feature headline | Three distinct assurance outcomes plus implementation correspondence requirement |
| Broad Rust support promised through `.ps` | Small safe `.ps` subset; full Rust project-level reach via native `.rs` wrappers, not full `.ps` compatibility |
| Linux-first acceptance test | First pure codec semantics/proof/Rust lowering; second mutable owned-buffer contract |
| Existing core/kernel or bootstrap implicitly changed | Explicit non-adoption and no modification until separate reviewed migration |

**Final proposal:** a small Rust-native resource and execution extension over the stable Lean-grounded ProofScript foundation, with cross-domain verified libraries and explicit proof-to-Rust correspondence. **Four compact source/semantic additions can unlock substantial useful capability; they do not remove the considerable work of correct native code generation, typed resource models, FFI/ABI, contracts and independent assurance.**
