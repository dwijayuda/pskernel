# Lean 4 ↔ ProofScript `ps-rust-native/0` ↔ Rust — Language Features, Syntax, Grammar, and Examples

**Status:** Proposed language-extension reference. Not implemented and not evidence of compiler conformance.  
**Edition:** `ps-rust-native/0`, an optional Rust-only source profile extending `pscv0` v7 · **Date:** 2026-10-11.  
**Inherited source authority:** [PSCV0 v7 language reference](../PSCV0_LANGUAGE_REFERENCE.md), targeting Lean 4.35.0-rc4 at commit [`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364).  
**Scope:** Language features, source syntax, selected grammar, static and operational meaning, Lean/Rust correspondence, and accepted/rejected source examples. No implementation architecture, CLI, package design, build procedures, milestones or release gates.

> **Important:** Every example using `@[native]`, native resource qualifiers, native representation attributes or foreign bindings is a **proposed** `.ps` spelling, not valid in PSCV0 v7 today. No source snippet or proof in this document is claimed to have been executed. Qualified `Rust.*` names in examples illustrate future pinned native-library types and adapters, not existing PSC0 Standard APIs.

> **Semantic identity:** The ordinary V7 subset keeps exactly its Lean-grounded meaning, whether Rust or another backend is used. Explicitly selected native declarations have Rust operational/resource semantics and are **not** transparent Lean total definitions. The Lean proof kernel still checks logical proof terms; Rust's borrow checking alone does not prove functional correctness or correspondence to Lean models.

## Executive syntax map

| Concern | Existing Lean / PSCV0 v7 | Rust | Proposed `ps-rust-native/0` |
|---|---|---|---|
| Pure definition | `function f(x: A): B := term` | `fn f(x: A) -> B` | **Keep V7 syntax and Lean meaning** |
| Runtime definition | V7 excludes source `partial`/`unsafe` | Native effectful or looping `fn` | `@[native] function f(...) ...` |
| Required zero-argument `Unit` | `function f()`, `f()`, `f(())` | `fn f()` | Keep V7 Unit semantics for source `function` |
| Function call | `f(x, y)` or `f x y` | `f(x, y)` | Retain V7 adjacency and currying; **reject** `f (x)` as application |
| Owned resource | No general affine type in V7 | Native owned `T` | `owned T` |
| Shared reference | Lean `@&` is an RC optimization annotation | `&T` | `borrow T` |
| Exclusive reference | `let mut` is local mutable state | `&mut T` | `borrow mut T` |
| Complex escaping lifetime | No Rust lifetime binders in V7 | `'a`, HRTB | Initially **not admitted** in `.ps`; named native Rust wrapper |
| Integers | `UInt32`, `Int32`, `Nat`, `Int` | `u32`, `i32`, `usize` | Exact type mapping; never silently narrow `Nat` |
| Collections | Lean `List`, `Array`, `ByteArray` | `Vec<T>`, `&[T]`, `[T; N]` | Distinct native library types; no silent semantic substitution |
| Errors | `Except`, `Option`, selected `do` | `Result`, `Option` | Qualified types and typed adapters |
| Recursion/loops | Total `def`; selected braced `for`/`while` | General `loop`, `while`, `for` | Add native-only `loop { ... }`; no implicit termination proof |
| Data layout | Nominal `structure` | `repr(C)`, `repr(transparent)` | `@[native.reprC]`, `@[native.reprTransparent]` |
| External symbols | V7 excludes arbitrary `extern` | Edition-2024 `unsafe extern "C"` | Restricted `@[native.externC("symbol")]` declaration |
| Privileged body | V7 source `unsafe` excluded | Rust `unsafe` operations | `@[native.unsafe]` boundary declaration |
| Logical contracts | Selected RC4 `given`, `requires`, `ensures` | Native function + separate verifier | Reuse words, but specify native operational WP meaning |
| Theorems | `theorem`, `by`, `omega`, `simp`, `grind` | No built-in full theorem system | **Keep Lean's proof language** |
| General Rust syntax | V7 closed grammar | `fn`, `impl`, macros, traits | **No implicit Rust parser fallback** |

**Four new source/semantic families:** native execution, ownership/borrowing, native representation/ABI, and privileged/foreign declarations. Domain-specific operations (binary codecs, networking, storage, cryptography, embedded, Linux) should be **library types and functions**, not new source keywords.

## Comparison guide and grammar authority

| Status label | Meaning |
|---|---|
| **Inherited V7** | Same accepted `.ps` syntax and same Lean meaning as [the reference](../PSCV0_LANGUAGE_REFERENCE.md) |
| **Selected Lean** | Existing Lean grammar/semantics, only if expressly admitted by V7 |
| **Native addition** | Proposed Rust-only `.ps` surface or resource/effect rule |
| **Library** | Named type/function with a separately selected Rust binding, not a grammar change |
| **Privileged** | Foreign/unsafe operation requiring explicit permissions and unproved or separately proved obligations |
| **Illustrative** | A code shape describing a design rather than evidence that it compiles or proves |

The following grammar fragments are **schematic Lean/V7-category selections**, not standalone executable EBNF. `command`, `term`, `binder`, `doSeqItem`, `tactic`, `structField` and `attribute` refer to inherited V7/Lean categories. A new nonterminal begins `psNative`. Ellipses are not permission to accept unrestricted Rust or Lean syntax.

## 0. Source files, lexical rules and naming

### Source identity and explicit extension selection

The same `.ps` module syntax is used under an explicitly named language edition. Selecting a Rust **output target** alone does not activate native syntax or override PSCV0 restrictions.

```text
psNativeSourceFile ::=
  V7.importHeader (V7.selectedCommand | psNativeCommand)* EOF

psNativeCommand ::=
    psNativeFunction
  | psNativeUnsafeFunction
  | psNativeExternalFunction
  | psNativeRepresentedStructure
```

The language edition is a source/profile identity, **not a new token** such as `profile rust` or a magic filename suffix. V7 `import`, `public import`, `namespace`, `section`, `variable`, `include`, `omit`, visibility and module rules retain their meaning. An imported native library can add named declarations, not arbitrary parser forms or Lean axioms.

### Lean comments, whitespace, binders and calls

| Fragment | Status | Grammar ownership |
|---|---|---|
| `f(x, y)` | Accepted when well-typed | Adjacent comma call, two explicit source arguments |
| `f x y` | Accepted where V7 admits it | Curried Lean application |
| `f((x, y))` | Accepted | One tuple argument |
| `f(())` | Accepted when `Unit` parameter required | Explicit Unit argument |
| `f()` | Only V7 completion rules | No JavaScript/Rust zero-arity reinterpretation |
| `f (x)` | **Reject** when a spaced parenthesized application | `PSCV0-APP-02` |
| `f /- gap -/ (x)` | **Reject** as an application | Lean comment breaks adjacency |
| `variable (n: Nat)` | Accepted | Fresh command binder, not application |
| `#check (f x)` | Accepted | Grouped fresh term |
| `borrow mut (Rust.Vec UInt8)` | Native-only | Type qualifier, not function call |

V7's Lean `--` and nested block comments, line-break, brace and application rules remain unchanged. In particular, **no C-style block comments**, Rust macro token trees, Rust path `::` syntax, JS truthiness or automatic semicolon insertion are added.

## 1. Functions, native declarations, recursion and bodies

### Ordinary logical `function`, `def` and `const`

**Feature/profile:** Inherited V7.

| Rust implementation equivalent | V7 ProofScript |
|---|---|
| `fn add(a: u32, b: u32) -> u32 { a.wrapping_add(b) }` | `function add(a: UInt32, b: UInt32): UInt32 := a + b` |

The target mapping must preserve Lean's `UInt32` arithmetic; this is an intended correspondence, not a proved one. The `function`, `def`, `const`, implicit binders, named/default parameters and call forms are **not modified** by this extension.

### Native execution modifier

**Feature/profile:** New allowlisted attribute, recognized only in a native declaration position. It denotes a Rust-executed function and does not make its body transparently reducible in Lean logic.

**Grammar (schematic):**

```text
psNativeFunction ::=
  '@[' 'native' ']' 'function' declId
  V7.psFunctionBinders (':' psNativeType)?
  psNativeContract? ':=' psNativeBody

psNativeBody ::= V7.selectedTerm
               | 'do' '{' psNativeDoSeq '}'
```

It is intentionally **one marker**, not both `runtime function` and `systems function`. A native runtime declaration may be partial/effectful when its native profile permits it. The unmarked `function` remains the V7 total Lean-grounded form.

| Rust | Proposed ProofScript |
|---|---|
| `fn bump(n: &mut u32) { *n = n.wrapping_add(1); }` | `@[native] function bump(n: borrow mut UInt32): Unit := do { n.set(n.get() + 1) }` |

The `.get()`/`.set()` methods are **schematic native-reference operations**, not V7 built-ins.

### Recursion and nontermination: source distinctions

| Source kind | Acceptance | Logical meaning |
|---|---|---|
| `function f(...) := ... termination_by ...` | V7 rules | Transparent total Lean definition with accepted termination evidence |
| Lean upstream `partial_fixpoint` | **Not automatically admitted** in V7 or this extension | Only selected Lean-supported partial-equation/partial-correctness rules |
| V7 source `partial function ...` | Rejected | V7 excludes source `partial` |
| `@[native] function service(...): Unit := do { loop { ... } }` | Proposed native | Operational loop; no automatic totality proof |
| V7 source `unsafe def ...` | Rejected | No new general Lean unsafe source permission |

**Native loop grammar:**

```text
psNativeDoSeq  ::= psNativeDoItem
                   (V7.doItemSeparator psNativeDoItem)*

psNativeDoItem ::= V7.selectedDoSeqItem
                 | 'loop' '{' psNativeDoSeq '}'
```

Native `while`, `for`, `if`, `if let`, `match`, `let mut`, assignment, `return`, `break` and `continue` reuse their *selected V7 braced syntax* when applicable. `loop` is the only additional native control-flow head selected here. Runtime loops need not have a termination proof, although a claim of invariant preservation or termination needs the corresponding proof.

```proofscript
-- Proposed operational function; no predefined socket API implied.
@[native]
function run(server: owned Rust.Server): Unit := do {
  loop {
    let request ← server.receive()
    server.reply(request)
  }
}
```

### Nullary functions, binders and Unit

`function f()` **continues to mean** a required logical `Unit` binder under V7, even when marked `@[native]`. The source `f()` requests V7 empty-call completion, and `f(())` explicitly supplies `Unit`. Do **not** silently equate the source declaration with every foreign ABI's zero-parameter convention. A bodyless FFI declaration (see §6) has an independent ABI signature.

## 2. Ownership, move and borrowed resource types

### Native type grammar

**Feature/profile:** Affine/resource-qualified *native types*, not new Lean kernel constructors.

```text
psNativeType ::=
    V7.selectedType
  | 'owned' psNativeResourceBase
  | 'borrow' psNativeResourceBase
  | 'borrow' 'mut' psNativeResourceBase

psNativeResourceBase ::= psNativeNominalType
                       | '(' psNativeType ')'

psNativeNominalType ::= selectedRustBoundType
```

`selectedRustBoundType` denotes a named native-library type such as `Rust.Vec UInt8`. The qualifiers are recognized only in selected native type positions. They are **not** ordinary curried term application, and `let mut` remains a separate `do` construct.

| Rust | Proposed `.ps` parameter | Static meaning |
|---|---|---|
| `value: Resource` | `value: owned Resource` | Owned, transferable native resource |
| `value: &Resource` | `value: borrow Resource` | Shared borrow for validated lifetime |
| `value: &mut Resource` | `value: borrow mut Resource` | Exclusive mutable borrow |
| `xs: &[u8]` | `xs: borrow (Rust.Slice UInt8)` | Non-owning read-only view |
| `xs: &mut [u8]` | `xs: borrow mut (Rust.Slice UInt8)` | Exclusive mutable view |
| `n: u32` | `n: UInt32` | Ordinary copyable scalar, no resource qualifier required |

`owned` does **not** make an ordinary duplicable Lean value affine throughout the logic. Its enforceable meaning is restricted to native resource typing and Rust-corresponding operations.

### Move and borrow rules

- A noncopyable owned value cannot be used after being moved/consumed.
- Shared borrows disallow invalid mutation, and exclusive borrows disallow overlapping incompatible aliases.
- An inferred call-site borrow is allowed only when the already-resolved function signature and current resource state give one valid interpretation.
- Inference **may not** silently add `clone`, `Rc`, `Arc`, `Mutex`, `RefCell`, allocation or locking to resolve an ownership conflict.
- An escaping borrow requires a proven lifetime relation. Complex returned borrows, higher-ranked lifetimes and self-referential types are **not initially selected** in `.ps`; a typed native Rust wrapper is permitted instead.
- `Drop` and cleanup are operational, potentially effectful actions. Logical proof erasure may not suppress or invent them.

**Example:**

```proofscript
-- Assumed signatures:
-- inspect(x: borrow Rust.Packet): Unit
-- consume(x: owned Rust.Packet): Unit
@[native]
function inspectThenSend(packet: owned Rust.Packet): Unit := do {
  inspect(packet)   -- inferred shared borrow
  consume(packet)   -- ownership transferred
  -- inspect(packet) would be INVALID: use after move
}
```

The Rust borrow checker can reject invalid generated Rust. But the source-to-Rust translation must also preserve the source's ownership choices; the compiler must not claim the Rust check proves arbitrary business logic correct.

### Explicit failure ownership

```proofscript
-- Illustrative queue API, not an existing PSC0 signature.
@[native]
function submit(
  q: borrow mut Rust.Queue,
  req: owned Rust.Request
): Rust.Result Unit (Rust.Error, Rust.Request) := do {
  return q.tryPush(req)
}
```

Success may consume `req`; the failure result returns ownership according to the **selected queue contract**. The return type alone does not prove that queue contents were unchanged, nor that a destructor or callback has no side effects.

## 3. Scalars, native collections, pointers and representations

### Existing numeric types

| V7/Lean source | Rust representation candidate | Required semantic condition |
|---|---|---|
| `UInt8`/`UInt16`/`UInt32`/`UInt64` | `u8`/`u16`/`u32`/`u64` | Explicit wrapping and shift/division behavior |
| `Int8`/`Int16`/`Int32`/`Int64` | `i8`/`i16`/`i32`/`i64` | Signed overflow and other operations preserved |
| `USize`/`ISize` | `usize`/`isize` | Target machine-width assumptions selected |
| `Nat`/`Int` | Big integers or explicitly bounded values | Never silently narrow to machine width |
| `Bool`, `Unit` | `bool`, `()` | Correct valid-value and control-flow meaning |
| `Float`/`Float32` | `f64`/`f32` where justified | IEEE/NaN/rounding and target optimizations specified |
| `Fin n`, `Subtype` | Native representation plus approved erasure | Evidence/value correspondence maintained |

**Side-by-side:**

```rust
fn add32(a: u32, b: u32) -> u32 { a.wrapping_add(b) }
```

```proofscript
function add32(a: UInt32, b: UInt32): UInt32 := a + b
```

This requires **no new ProofScript syntax**. It requires a faithful mapping: debug/release Rust overflow differences must not change the source meaning.

### Native collections are not silently Lean arrays

| Selected native-library type | Rust equivalent | Distinction |
|---|---|---|
| `Rust.Vec T` | `Vec<T>` | Owned, mutable, potentially allocating collection |
| `Rust.Slice T` with borrow qualifier | `&[T]` / `&mut [T]` | Non-owning contiguous view |
| `Rust.FixedArray T n` | `[T; N]` | Inline fixed-size array when `n` maps to a target constant |
| `Rust.Result T E` | `Result<T,E>` | Native error sum, not automatically Lean `Except` |
| `Rust.Option T` | `Option<T>` | Native optional sum |
| `Rust.RawPtr T` | `*const T` / `*mut T` via a selected binding | Privileged raw pointer; not safe to dereference |
| `Rust.Box T` / `Rust.Arc T` | Native owning/shared allocations | Allocation/sharing/destructor semantics remain explicit |

These are **illustrative names**, not claims that PSC0 defines them. Do not substitute native `Rust.Vec T` for Lean persistent `Array T` merely because their element types match. Use an explicit adapter and an appropriate copying/aliasing/semantic contract.

### Borrowed slice example

**Rust:**

```rust
fn first(xs: &[u8]) -> Option<u8> {
    xs.first().copied()
}
```

**Proposed ProofScript:**

```proofscript
@[native]
function first(
  xs: borrow (Rust.Slice UInt8)
): Rust.Option UInt8 := xs.firstCopied()
```

`firstCopied` is a *selected-library placeholder*. It illustrates non-escaping borrowing, without inventing an unsafe pointer operation or a returned lifetime.

## 4. Structures, layout and ABI

### Structure representation annotations

**Feature/profile:** Native source attributes that attach Rust representation requirements to a V7 structure declaration.

```text
psNativeRepresentedStructure ::=
  psNativeReprAttribute V7.structureDecl

psNativeReprAttribute ::=
    '@[' 'native.reprC' ']'
  | '@[' 'native.reprTransparent' ']'
```

**Rust:**

```rust
#[repr(C)]
struct Header {
    flags: u32,
    length: u32,
}
```

**Proposed ProofScript:**

```proofscript
@[native.reprC]
structure Header where {
  flags: UInt32
  length: UInt32
}
```

V7 structure declaration fields remain **newline-separated**, not C/Rust-style comma- or semicolon-terminated fields. `native.reprC` requires a representable field telescope, target alignment and ABI correspondence. `native.reprTransparent` follows the stricter single-nonzero-sized-field representation requirements. Neither attribute automatically proves logical field invariants or external ABI compatibility.

### Native variables and storage

Top-level V7 `const` remains a *parameterless Lean definition*, not Rust `const` or mutable `static`. Exported symbols, thread locals, linker sections, static mutable state, packed unions and C bitfields are not admitted by this initial native grammar. They may be expressed using selected typed native Rust wrappers, without importing unrestricted Rust source syntax into `.ps`.

## 5. Native control flow, errors and effects

### Braced `do`, runtime loops and sequencing

**Grammar:**

```text
psNativeBody ::= V7.selectedTerm
               | 'do' '{' psNativeDoSeq '}'

psNativeDoSeq ::= psNativeDoItem
                  (V7.doItemSeparator psNativeDoItem)*

psNativeDoItem ::= V7.selectedDoSeqItem
                 | 'loop' '{' psNativeDoSeq '}'
```

The ordinary V7 `if`, `match`, `if let`, `for`, `while`, `let`, `let mut`, assignment, `return`, `break`, `continue`, and selected errors keep their existing surface categories. Staged V7 P1 forms do **not** become accepted merely because they resemble Rust features. The only new native control-flow head specified here is `loop`.

**Rust:**

```rust
fn count_nonzero(xs: &[u8]) -> u32 {
    let mut total = 0u32;
    for &x in xs {
        if x != 0 { total = total.wrapping_add(1); }
    }
    total
}
```

**Proposed ProofScript:**

```proofscript
@[native]
function countNonzero(
  xs: borrow (Rust.Slice UInt8)
): UInt32 := do {
  let mut total: UInt32 := 0
  for x in xs {
    if (x != 0) {
      total := total + 1
    }
  }
  return total
}
```

This is a **proposed source equivalence**, subject to the selected iterator binding and integer semantics; not an executed comparison.

### Native typed errors

`Rust.Result T E` is a named native type with the semantics of a typed success/error result. Rust `?` is **not** added to V7 grammar in the initial extension. Use selected `do`/typed-result combinators until a specific new sugar is justified.

**Rust:**

```rust
use std::collections::TryReserveError;

fn add_byte(v: &mut Vec<u8>, x: u8) -> Result<(), TryReserveError> {
    v.try_reserve(1)?;
    v.push(x);
    Ok(())
}
```

**Proposed ProofScript:**

```proofscript
@[native]
function addByte(
  v: borrow mut (Rust.Vec UInt8),
  x: UInt8
): Rust.Result Unit Rust.AllocError := do {
  return v.tryPush(x)
}
```

`tryPush` is a **hypothetical approved wrapper** combining fallible reserve and insertion; it is not a standard `Vec::tryPush` Rust API. Its normal and failed resource states require an exact contract.

### Operational effects, no new universal syntax

| Effect or context | Selected source meaning |
|---|---|
| Allocation/failure | Native API may allocate or return a typed error; no hidden allocator in no-heap context |
| Blocking/sleeping | Context capability may forbid selected calls |
| Native memory mutation | Requires valid resource ownership/borrow |
| FFI | Requires selected foreign binding and its safety conditions |
| Atomic/volatile/MMIO | Named library operations with memory-order/device semantics |
| Async cancellation | Only with an explicitly admitted native effect/cleanup model |
| Cleanup/panic | Drop/unwind/abort behavior follows the selected operational type/target constraints |

These are type and library properties; **no `effect`, `irq`, `transaction`, `packet` or `kernel` language keyword is introduced**.

## 6. Foreign functions and privileged memory

### Bodyless C ABI declarations

**Feature/profile:** Restricted external command syntax. The symbol is an explicit string literal. A foreign declaration is *not* a Lean `axiom` or a checked theorem.

```text
psNativeExternalFunction ::=
  '@[' 'native.externC' '(' stringLiteral ')' ']'
  'function' declId V7.psFunctionBinders ':' psNativeType

-- No ':=' body.
-- ABI parameter/return types must be admitted native representations.
```

**Rust (2024 edition):**

```rust
unsafe extern "C" {
    fn abs(input: i32) -> i32;
}
```

**Proposed ProofScript:**

```proofscript
@[native.externC("abs")]
function cAbs(input: Int32): Int32
```

This example is a **declared foreign symbol**, not a proof of symbol existence, ABI validity or call safety. Calls remain privileged unless an approved wrapper establishes the necessary conditions. Other ABI families and variadics are not selected in the initial grammar.

### Explicit native unsafe wrappers

**Grammar:**

```text
psNativeUnsafeFunction ::=
  '@[' 'native.unsafe' ']' '@[' 'native' ']'
  'function' declId V7.psFunctionBinders
  (':' psNativeType)? psNativeContract? ':=' psNativeBody
```

The order of the two attributes is selected rather than introducing both alternative spellings. `native.unsafe` grants a **source privilege and an effect boundary**, not theorems or permission to omit assumptions.

```proofscript
-- Illustrative raw-memory binding, not an existing PSC0 primitive.
@[native.unsafe]
@[native]
function read32(p: Rust.RawPtr UInt32): UInt32 := do {
  return Rust.Raw.load32(p)
}
```

Correctness of such a load requires the relevant pointer provenance, alignment, initialized-value, lifetime and memory-access conditions. Ordinary `@[native]` code cannot invoke arbitrary raw dereference operations as if they were safe.

**Preferred safe wrapper:**

```proofscript
@[native]
function readReg(r: borrow Rust.Register32): UInt32 := do {
  return r.read()
}
```

`Rust.Register32` and `read` are schematic interfaces. Hardware register correctness or memory ordering must not be inferred merely from their types.

### Privileged forms excluded from normal source

| Source form | Status |
|---|---|
| `@[native] function` using selected safe operations | Proposed accepted native source |
| `@[native.unsafe]` followed by `@[native]` | Proposed accepted privileged wrapper |
| Raw dereference inside ordinary safe native function | **Reject** |
| Arbitrary Rust `unsafe { ... }` pasted into `.ps` | **Reject** |
| Bare Lean `unsafe def` / `partial def` in V7 | **Reject** under V7 |
| User `axiom proof : False` | **Reject** under V7 |
| Native `.rs` module with typed wrapper | Interoperability boundary, **not** native `.ps` syntax |

## 7. Formal specifications, proof terms and executable meaning

### Pure Lean-grounded theorems

Keep V7's `Prop`, `Subtype`, `Fin`, dependent types, ordinary `theorem`, `by { ... }`, `simp`, `omega`, `grind`, and other selected proof terms. Nothing about a Rust target changes the kernel's inference or definitional-equality rules.

**Pure specification example:**

```proofscript
inductive State where {
  | ready
  | removed
}

inductive Event where {
  | retry
  | remove
}

function step(s: State, e: Event): State := {
  match s, e with {
    | .removed, _ => .removed
    | _, .remove => .removed
    | other, _ => other
  }
}

theorem removedStaysRemoved(e: Event):
  step(.removed, e) = .removed := by {
  cases e <;> rfl
}
```

The theorem proof is **illustrative, not execution-tested**. If checked, it proves a property of `step`, not automatically that a separately written Rust driver follows `step`.

### Reuse `given`, `requires`, `ensures` for native specifications

**Grammar selection:**

```text
psNativeContract ::=
  psNativeGiven? psNativeRequires? psNativeEnsures?

psNativeGiven    ::= 'given' V7.selectedGivenBinders
psNativeRequires ::= 'requires' V7.selectedContractPredicate
psNativeEnsures  ::= 'ensures' V7.selectedResultBinder '=>' term
```

At most one clause of each kind, always in **`given`, `requires`, `ensures` order**. A `given` binder denotes a logical specification variable, never a runtime argument. Native contract terms are Lean propositions over a selected abstract state/resource model.

**Crucial distinction:** Lean 4.35 RC4's experimental intrinsic `Std.WP` verification does **not** automatically establish the effects of arbitrary native Rust functions. Reusing the *surface keywords* requires a corresponding Rust-native WP/resource interpretation; a well-formed contract is not evidence that the native body satisfies it.

```proofscript
-- Schematic native API and relational specification.
@[native]
function appendBounded(
  out: borrow mut (Rust.Vec UInt8),
  byte: UInt8,
  limit: Rust.USize
): Rust.Result Bool Rust.AllocError
  given (before: BufferModel)
  requires models(out, before)
  ensures result =>
    appendPost(before, out, byte, limit, result)
:= do {
  return NativeBuffer.appendBounded(out, byte, limit)
}
```

`BufferModel`, `models`, `appendPost` and `NativeBuffer.appendBounded` are *not* declared by V7. They describe the expected native resource model and a future typed wrapper.

### Partial correctness, erasure and nontermination

A native event loop may preserve a stated invariant without terminating. Termination, liveness, cancellation, crash recovery, lock freedom and constant-time behavior require **separate specifications**, not a generic Rust safety claim.

`erased` proof data and abstract specifications must not determine runtime branch conditions, destructor execution, atomic operations or observable foreign calls. A ProofScript function marked `@[native]` is **opaque to ordinary Lean proof unfolding** unless an explicitly justified logical correspondence supplies the relevant meaning.

### Three independent meanings of "checked"

| Result | Meaning | Does not imply |
|---|---|---|
| Rust type/borrow accepted | Native program satisfies selected Rust static rules | Functional correctness |
| Lean theorem checked | Logical property of a given model, relative to assumptions | The emitted Rust implements that model |
| Implementation corresponds to specification | Property of a **specific** native implementation, when evidence is supplied | Arbitrary external hardware/OS correctness |

This is a semantic distinction, not a new theorem-proving grammar or proof-kernel rule.

## 8. Further side-by-side examples

### A. Fixed-width arithmetic without new syntax

**Rust:**

```rust
fn sum32(a: u32, b: u32) -> u32 {
    a.wrapping_add(b)
}
```

**V7:**

```proofscript
function sum32(a: UInt32, b: UInt32): UInt32 := a + b
```

Portable arithmetic meaning takes precedence over incidental Rust debug/release overflow behavior.

### B. Read-only slice and inferred borrow

**Rust:**

```rust
fn checksum(bytes: &[u8]) -> u32 {
    bytes.iter().fold(0u32, |x, &b| x.wrapping_add(b as u32))
}
```

**Proposed native `.ps`:**

```proofscript
@[native]
function checksum(xs: borrow (Rust.Slice UInt8)): UInt32 := do {
  let mut total: UInt32 := 0
  for x in xs {
    total := total + UInt32.ofNat(x.toNat)
  }
  return total
}
```

The loop and conversion depend on the selected Rust-native slice library. A borrow of the source slice ends without returning a reference to it.

### C. Native memory-safe error handling

**Rust:**

```rust
fn reserve_one(v: &mut Vec<u8>) -> Result<(), std::collections::TryReserveError> {
    v.try_reserve(1)
}
```

**Proposed `.ps`:**

```proofscript
@[native]
function reserveOne(v: borrow mut (Rust.Vec UInt8)):
  Rust.Result Unit Rust.AllocError := do {
  return v.tryReserve(1)
}
```

The Rust-facing error representation and wrapper (`tryReserve`) must be specified; they are not already supplied by PSC0.

### D. Protocol invariants

**Rust:**

```rust
#[derive(Clone, Copy, PartialEq, Eq)]
enum Phase { Active, Removed }

fn remove(_: Phase) -> Phase { Phase::Removed }
```

**Portable ProofScript logical model:**

```proofscript
inductive Phase where {
  | active
  | removed
}

function remove(_: Phase): Phase := .removed

theorem removeIsRemoved(p: Phase):
  remove(p) = .removed := by {
  rfl
}
```

A checked theorem would constrain the source logical function; a Rust implementation must separately be related to it before the theorem is claimed for executable code.

### E. C-compatible native structure

**Rust:**

```rust
#[repr(C)]
struct Header {
    length: u32,
    kind: u32,
}
```

**Proposed `.ps`:**

```proofscript
@[native.reprC]
structure Header where {
  length: UInt32
  kind: UInt32
}
```

An ordinary Lean structure without the native attribute has **no implicit C representation**.

### F. Restricted FFI function

**Rust:**

```rust
unsafe extern "C" {
    fn abs(x: i32) -> i32;
}
```

**Proposed `.ps`:**

```proofscript
@[native.externC("abs")]
function cAbs(x: Int32): Int32
```

A bodyless foreign declaration is not a user axiom. Its externally implemented behavior is not established by the source signature.

## 9. Grammar concordance (deltas only)

```text
psNativeSourceFile ::=
  V7.importHeader (V7.selectedCommand | psNativeCommand)* EOF

psNativeCommand ::=
    psNativeFunction
  | psNativeUnsafeFunction
  | psNativeExternalFunction
  | psNativeRepresentedStructure

psNativeFunction ::=
  '@[' 'native' ']' 'function' declId
  V7.psFunctionBinders (':' psNativeType)?
  psNativeContract? ':=' psNativeBody

psNativeUnsafeFunction ::=
  '@[' 'native.unsafe' ']' '@[' 'native' ']' 'function'
  declId V7.psFunctionBinders (':' psNativeType)?
  psNativeContract? ':=' psNativeBody

psNativeExternalFunction ::=
  '@[' 'native.externC' '(' stringLiteral ')' ']'
  'function' declId V7.psFunctionBinders ':' psNativeType

psNativeRepresentedStructure ::=
  ('@[' 'native.reprC' ']' |
   '@[' 'native.reprTransparent' ']')
  V7.structureDecl

psNativeBody ::= V7.selectedTerm
               | 'do' '{' psNativeDoSeq '}'

psNativeDoSeq ::= psNativeDoItem
                  (V7.doItemSeparator psNativeDoItem)*

psNativeDoItem ::= V7.selectedDoSeqItem
                 | 'loop' '{' psNativeDoSeq '}'

psNativeType ::=
    V7.selectedType
  | 'owned' psNativeResourceBase
  | 'borrow' psNativeResourceBase
  | 'borrow' 'mut' psNativeResourceBase

psNativeResourceBase ::=
    psNativeNominalType
  | '(' psNativeType ')'

psNativeNominalType ::= selectedRustBoundType

psNativeContract ::=
  psNativeGiven? psNativeRequires? psNativeEnsures?

psNativeGiven    ::= 'given' V7.selectedGivenBinders
psNativeRequires ::= 'requires' V7.selectedContractPredicate
psNativeEnsures  ::= 'ensures' V7.selectedResultBinder '=>' term
```

These are schematic category selections, **not a complete Rust parser**, and are interpreted with all V7 restrictions on source applications, binders, comments, newlines and proof expressions. The Rust-only lexical items are recognized only in their designated source grammar categories.

## 10. Accepted and rejected language fixtures (proposed)

| ID | Fragment or source situation | Expected result |
|---|---|---|
| RN-P01 | V7 pure `function inc(n: Nat): Nat := n+1` for Rust target | Same V7 syntax/meaning |
| RN-P02 | `@[native] function ... := do { loop { ... } }` in native profile | Accept operational loop if its types/effects are valid |
| RN-N01 | `@[native]` in ordinary V7 profile | Reject profile/attribute |
| RN-P03 | `x: owned Rust.Packet` | Selected owned type |
| RN-P04 | `xs: borrow (Rust.Slice UInt8)` | Selected shared borrow |
| RN-P05 | `xs: borrow mut (Rust.Vec UInt8)` | Selected exclusive borrow |
| RN-N02 | Owned resource reused after consuming move | Reject resource use |
| RN-N03 | Overlapping conflicting exclusive borrows | Reject resource use |
| RN-N04 | Returning reference to destroyed local | Reject |
| RN-N05 | Escaping borrow whose lifetime relation is not selected | Reject or require native wrapper |
| RN-N06 | Compiler silently clones or adds `Arc` to fix a borrow error | Reject hidden behavior |
| RN-P06 | Fixed-width `UInt32` semantics mapped to explicit wrapping Rust | Admit semantics-preserving mapping |
| RN-N07 | `Nat` silently narrowed to `usize` | Reject representation |
| RN-N08 | Lean persistent `Array` silently treated as mutable `Rust.Vec` | Reject without correspondence |
| RN-P07 | `@[native.reprC]` with native ABI-representable fields | Accept |
| RN-N09 | `native.reprC` over unsupported proof/dependent field | Reject |
| RN-P08 | Bodyless `native.externC` foreign declaration | Admit as external signature, not proof |
| RN-N10 | Unmarked bodyless ordinary `function` | Reject |
| RN-P09 | Explicit `@[native.unsafe]` wrapper with selected raw operation | Admit privileged category, not automatically proved |
| RN-N11 | Raw dereference in unprivileged native body | Reject |
| RN-N12 | Arbitrary user `axiom` supplied from native source | Reject |
| RN-P10 | Logical theorem over pure state transition | Kernel-checkable proof if actually supplied |
| RN-N13 | Logical theorem alone claimed proof of native executable | Reject stronger claim |
| RN-N14 | Arbitrary Rust `impl`/macro or Rust unsafe block inside `.ps` | Reject no fallback |
| RN-P11 | V7 `variable (n: Nat)`, `#check (f x)`, `f((x,y))` | Retain V7 grammar |
| RN-N15 | V7-invalid `f (x)` application | Reject adjacency |
| RN-P12 | Ordered `given`, `requires`, `ensures` on native declaration | Well-formed specification if model exists |
| RN-N16 | Well-formed specification called verified without implementation evidence | Reject executable-verification claim |

These describe intended **language semantics and source acceptance**, not executed tests or implementation readiness.

## 11. Exclusions and exact language scope

| Requested capability | `ps-rust-native/0` selection |
|---|---|
| V7 logical programming, proof tactics and mathematical syntax | Inherited |
| Runtime nontermination and native effects | Only explicit native declaration |
| Rust-owned/mutable/native library types | Selected named bindings |
| `owned`, `borrow`, `borrow mut` | Initial resource surface |
| Full Rust lifetime syntax/HRTB/GATs | Not selected; typed native Rust adapters may handle them |
| Native C ABI structures | Restricted `native.reprC` / transparent representation |
| FFI function import | Restricted `native.externC` bodyless signature |
| Raw pointers in safe code | Not admitted |
| Privileged raw/unsafe boundary | Explicit native unsafe declaration |
| C++ templates and arbitrary object ABI | No automatic syntax or ABI equivalence |
| Rust trait/impl/procedural-macro language syntax | Not selected as `.ps` syntax |
| Inline assembly and platform-specific intrinsics | Native wrapper boundary |
| `async`/`await` global syntax | Not added in initial profile |
| Linux-driver, database, packet or transaction keywords | No special source grammar |
| New proof kernel axioms or arbitrary user `axiom` | Not admitted |
| ProofScript v7 source `partial` and `unsafe` | Remain excluded in plain V7 |
| Arbitrary existing Rust code interpreted as `.ps` | Never accepted by a parser fallback |

**Native software domains use these common facilities through libraries and bindings.** A language need not add separate syntactic families for embedded, storage, networking, cryptography, numerical computing or OS kernels.

## 12. Source concordance (grammar and semantics only)

- [ProofScript PSCV0 v7](../PSCV0_LANGUAGE_REFERENCE.md) — authoritative grammar for the inherited language.
- [Pinned Lean 4.35.0-rc4 source](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364).
- [Lean recursive definitions, including partial fixpoints](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/).
- [Lean 4.35.0 verification notation](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/).
- [Lean 4.30 borrowed-argument annotation](https://lean-lang.org/doc/reference/latest/releases/v4.30.0/) — RC optimization, **not** Rust lifetime semantics.
- [Rust reference: pointer/reference types](https://doc.rust-lang.org/reference/types/pointer.html).
- [Rust reference: structure and C layout](https://doc.rust-lang.org/reference/type-layout.html).
- [Rust 2024 unsafe-extern syntax](https://doc.rust-lang.org/edition-guide/rust-2024/unsafe-extern.html).
- [Rust reference: destructor behavior](https://doc.rust-lang.org/reference/destructors.html).
- [Rust reference: unsafe behavior](https://doc.rust-lang.org/reference/unsafe-keyword.html).

**Final language distinction:** `ps-rust-native/0` adds **native execution, affine resource-qualified types, selected native representation and explicitly privileged foreign code** while retaining V7's Lean proof grammar and precise portable semantics. That is a deliberately small **language-design proposal**; it is neither an implemented Rust backend nor a claim that Rust memory safety alone establishes the Lean specifications.
