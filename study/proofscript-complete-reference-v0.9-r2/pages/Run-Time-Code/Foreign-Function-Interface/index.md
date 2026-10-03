<a id="ffi"></a>

# ProofScript — 12.4. Foreign Function Interface

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler and coverage boundary.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Run-Time-Code/Foreign-Function-Interface/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Run-Time-Code/Foreign-Function-Interface/index.html). Source Git blob: `56d6d5658e2358331ca9aa77af46ffdcbb6fd81d`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 12.4. Foreign Function Interface

**The current interface was designed for internal use in Lean and should be considered unstable**. It will be refined and extended in the future.

Lean offers efficient interoperability with any language that supports the C ABI. This support is, however, currently limited to transferring Lean data types; in particular, it is not yet possible to pass or return compound data structures such as C `struct`s by value from or to Lean.

There are two primary attributes for interoperating with other languages:

- `@[export sym] def leanSym : ...`

<a id="attr-next-next-next-next-next-next"></a>

**attribute**

**External Symbols**

<a id="Lean___Parser___Attr___extern"></a>

```ebnf
attr ::= ...
    | extern str
```

Binds a Lean declaration to the specified external symbol.

<a id="attr-next-next-next-next-next-next-next"></a>

**attribute**

**Exported Symbols**

<a id="Lean___Parser___Attr___export"></a>

```ebnf
attr ::= ...
    | export ident
```

Exports a Lean constant with the unmangled symbol name `sym`.

For simple examples of how to call foreign code from Lean and vice versa, see [the FFI](https://github.com/leanprover/lean4/tree/master/tests/lake/examples/ffi) and [reverse FFI](https://github.com/leanprover/lean4/tree/master/tests/lake/examples/reverse-ffi) examples in the Lean source repository.

<a id="The-Lean-Language-Reference--Run-Time-Code--Foreign-Function-Interface--The-Lean-ABI"></a>
### 12.4.1. The Lean ABI

The Lean 
<a id="--tech-term-Application-Binary-Interface"></a>
*Application Binary Interface* (ABI) describes how the signature of a Lean declaration is encoded in the platform-native calling convention. It is based on the standard C ABI and calling convention of the target platform. Lean declarations can be marked for interaction with foreign functions using either the attribute `extern "sym"`, which causes compiled code to use the C declaration `sym` as the implementation, or the attribute `export sym`, which makes the declaration available as `sym` to C.

In both cases, the C declaration's type is derived from the Lean type of the declaration with the attribute. Let `α₁ → ... → αₙ → β` be the declaration's [normalized](../../The-Type-System/index.md#--tech-term-normal-form) type. If `n` is 0, the corresponding C declaration is

```text
extern s sym;
```

where `s` is the C translation of `β` as specified in [the next section](index.md#ffi-types). In the case of a definition marked `extern`, the symbol's value is only guaranteed to be initialized after calling the Lean module's initializer or that of an importing module. The section on [initialization](index.md#ffi-initialization) describes initializers in greater detail.

If `n` is greater than 0, the corresponding C declaration is

```text
s sym(t₁, ..., tₙ);
```

where the parameter types `tᵢ` are the C translations of the types `αᵢ`. In the case of `extern`, all [irrelevant](../../The-Type-System/Inductive-Types/index.md#--tech-term-irrelevant) types are removed first.

<a id="ffi-types"></a>
#### 12.4.1.1. Translating Types from Lean to C

In the [ABI](index.md#--tech-term-Application-Binary-Interface), Lean types are translated to C types as follows:

- The integer types `UInt8`, …, `UInt64`, `USize` are represented by the C types `uint8_t`, ..., `uint64_t`, `size_t`, respectively. If their [run-time representation](../../Basic-Types/Fixed-Precision-Integers/index.md#fixed-int-runtime) requires [boxing](../Boxing/index.md#--tech-term-Boxed), then they are unboxed at the FFI boundary.
- `Char` is represented by `uint32_t`.
- `Float` is represented by `double`.
- `Nat` and `Int` are represented by `lean_object *`. Their runtime values is either a pointer to an opaque bignum object or, if the lowest bit of the “pointer” is 1 (`lean_is_scalar`), an encoded natural number or integer (`lean_box`/`lean_unbox`).
- A universe `Sort u`, type constructor `... → Sort u`, or proposition `p`​`:``Prop` is [irrelevant](../../The-Type-System/Inductive-Types/index.md#--tech-term-irrelevant) and is either statically erased (see above) or represented as a `lean_object *` with the runtime value `lean_box(0)`
- The ABI for other inductive types that don't have special compiler support depends on the specifics of the type. It is the same as the [run-time representation](../../The-Type-System/Inductive-Types/index.md#run-time-inductives) of these types. Its runtime value is either a pointer to an object of a subtype of `lean_object` (see the “Inductive types” section below) or it is the value `lean_box(cidx)` for the `cidx`th constructor of an inductive type if this constructor does not have any relevant parameters.

<a id="Unit--in-the-ABI"></a>
`Unit` in the ABI 

The runtime value of `u`​`:``Unit` is always `lean_box(0)`.

<a id="ffi-borrowing"></a>
#### 12.4.1.2. Borrowing

By default, all `lean_object *` parameters of an `extern` function are considered 
<a id="--tech-term-owned"></a>
*owned*. The external code is passed a “virtual RC token” and is responsible for passing this token along to another consuming function (exactly once) or freeing it via `lean_dec`. To reduce reference counting overhead, parameters can be marked as 
<a id="--tech-term-borrowed"></a>
*borrowed* by prefixing their type with [`@&`](index.md#Lean___Parser___Term___borrowed). Borrowed objects must only be passed to other non-consuming functions (arbitrarily often) or converted to owned values using `lean_inc`. In `lean.h`, the `lean_object *` aliases `lean_obj_arg` and `b_lean_obj_arg` are used to mark this difference on the C side. Return values and `@[export]` parameters are always owned at the moment.

<a id="term-next-next-next-next-next-next-next-next"></a>

**syntax**

**Borrowed Parameters**

<a id="Lean___Parser___Term___borrowed"></a>

```ebnf
term ::= ...
    | @& term
```

Parameters may be marked as [borrowed](index.md#--tech-term-borrowed) by prefixing their types with `@&`.

<a id="ffi-initialization"></a>
### 12.4.2. Initialization

When including Lean code in a larger program, modules must be 
<a id="--tech-term-initialized"></a>
*initialized* before accessing any of their declarations. Module initialization entails:

- initialization of all “constant definitions” (nullary functions), including closed terms lifted out of other functions,
- execution of all code marked with the `init` attribute, and
- execution of all code marked with the `builtin_init` attribute, if the `builtin` parameter of the module initializer has been set.

The module initializer is automatically run with the `builtin` flag for executables compiled from Lean code and for “plugins” loaded with `lean --plugin`. For all other modules imported by `lean`, the initializer is run without `builtin`. In other words, `init` functions are run if and only if their module is imported, regardless of whether they have native code available, while `builtin_init` functions are only run for native executable or plugins, regardless of whether their module is imported. The Lean compiler uses built-in initializers for purposes such as registering basic parsers that should be available even without importing their module, which is necessary for bootstrapping.

The initializer for module `A.B` in a package `foo` is called `initialize_foo_A_B`. For modules in the Lean core (e.g., `Init.Prelude`), the initializer is called `initialize_Init_Prelude`. Module initializers will automatically initialize any imported modules. They are also idempotent (when run with the same `builtin` flag), but not thread-safe.

**Important for process-related functionality**: applications that use process-related functions from `libuv`, such as `Std.IO.Process.getProcessTitle` and `Std.IO.Process.setProcessTitle`, must call `lean_setup_args(argc, argv)` (which returns a potentially modified `argv` that must be used in place of the original) **before** calling any module initializer. This sets up process handling capabilities correctly, which is essential for certain system-level operations that Lean's runtime may depend on.

Putting everything together, code like the following should be run exactly once before accessing any Lean declarations:

```text
char ** lean_setup_args(int argc, char ** argv);

lean_object * initialize_A_B(uint8_t builtin);
lean_object * initialize_C(uint8_t builtin);
...

argv = lean_setup_args(argc, argv); // if using process-related functionality

lean_object * res;
// use same default as for Lean executables
uint8_t builtin = 1;
res = initialize_foo_A_B(builtin);
if (lean_io_result_is_ok(res)) {
    lean_dec_ref(res);
} else {
    lean_io_result_show_error(res);
    lean_dec(res);
    return ...;  // do not access Lean declarations if initialization failed
}
res = initialize_bar_C(builtin);
if (lean_io_result_is_ok(res)) {
...

//lean_init_task_manager();  // necessary for code that (indirectly) uses `Task`
lean_io_mark_end_initialization();
```

In addition, any other thread not spawned by the Lean runtime itself must be initialized for Lean use by calling

```text
void lean_initialize_thread();
```

and should be finalized in order to free all thread-local resources by calling

```text
void lean_finalize_thread();
```

<a id="The-Lean-Language-Reference--Run-Time-Code--Foreign-Function-Interface--____LSQ_extern_RSQ_--in-the-Interpreter"></a>
### 12.4.3. @[extern] in the Interpreter

The Lean interpreter can run Lean declarations for which symbols are available in loaded shared libraries, which includes declarations that are marked `extern`. To run this code (e.g. with [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval)), the following steps are necessary:

1. The module containing the declaration and its dependencies must be compiled into a shared library
2. This shared library should be provided to `lean --load-dynlib=` to run code that imports the module.

It is not sufficient to load the foreign library containing the external symbol because the interpreter depends on code that is emitted for each `extern` declaration. Thus it is not possible to interpret an `extern` declaration in the same file. The Lean source repository contains an example of this usage in [`tests/compiler/foreign`](https://github.com/leanprover/lean4/tree/master/tests/compiler/foreign/).

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Indicates that an argument to a function marked `@[extern]` is borrowed.

Being borrowed only affects the ABI and runtime behavior of the function when compiled or interpreted. From the perspective of Lean's type system, this annotation has no effect. It similarly has no effect on functions not marked `@[extern]`.

When a function argument is borrowed, the function does not consume the value. This means that the function will not decrement the value's reference count or deallocate it, and the caller is responsible for doing so.

Please see https://lean-lang.org/doc/reference/latest/find/?domain=Verso.Genre.Manual.section&name=ffi-borrowing for a complete description.
```

