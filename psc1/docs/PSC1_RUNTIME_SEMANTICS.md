# PSC1 runtime semantics and target boundaries

Contract identifier: `psc1-runtime-semantics/1`. The semantic reference is official
Lean **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
This document describes the retained executable IR and the bounded source forms
qualified by the focused Linux suite. It is not a claim that arbitrary Lean or
every Practical Core feature compiles to every target.

## One checked source path

The native host captures the dependency-ordered source text once, elaborates it,
independently admits its logical declarations with the pinned Lean kernel, and
checks the erased executable IR. Closed backends share one specialization plan and
validate the transformed IR again. Rust retains its existing generic typed path.
A public `PsValidatedIrModule` wrapper is constructible data, so public emitter
entry points revalidate it; only the private host session records completed source
admission. Target helpers, npm manifests and formatter results are not proof evidence.

The two assurance modes preserve their established distinction. Default
`checked` uses the qualified checked source slice. Explicit `ordinary` permits
the qualified partial-function slice while checking its logical companion and
exact logical/runtime body pairing. `verified` fails explicitly because backend
behavioral certificates are unavailable. Logical admission and execution tests
do not establish a formal backend-preservation theorem.

## Scalar meanings

| Operation or value | Contract for the retained slice |
| --- | --- |
| Nat | Arbitrary nonnegative integer, without machine-width truncation |
| Nat subtraction | Saturates at zero |
| Nat division by zero | Returns zero |
| Nat modulo by zero | Returns the original dividend |
| Nat nonzero division/modulo | Natural quotient and remainder |
| Int | Arbitrary signed integer; qualified conversion, negation, addition, subtraction, multiplication, comparison and decimal representation |
| Int division/modulo | Absent from the active executable IR; not a qualified capability |
| Bool | Exactly two values; conjunction/disjunction preserve conditional evaluation |
| Char | Unicode scalar; invalid `Char.ofNat` input becomes NUL |
| String | Sequence of Unicode scalars; UTF-8 byte size is distinct from character length |
| Unit | One computational value |
| Fixed-width integers and floats | Not qualified by this direct profile; reject rather than silently use host arithmetic |

The Char check applies to the original natural number. It does not first truncate
through a 32-bit host value. The native oracle checks a surrogate, 0x110000 and
2^32 + 65; all produce NUL.

The ordinary source operator slice does not expose every equality intrinsic in
the IR. In particular, this qualification compares Int/String observations using
the source operations actually accepted by the frontend. An emitter implementation
of an IR operation alone does not establish source-language acceptance.

## UTF-8 positions and raw String operations

The retained `String.Internal` operations use raw byte positions. For the string
`A😀é`, character length is 3 and UTF-8 byte size is 7. The emoji starts at
byte position 1 and the final character starts at position 5.

Pinned Lean behavior for a raw invalid position is deliberate:

| Observation on `A😀é` | Reference result |
| --- | --- |
| Get at position 1 | Emoji, scalar 128512 |
| Get at continuation position 2 | Default Char `A`, scalar 65 |
| Get at end position 7 | Default Char `A`, scalar 65 |
| Next at position 1 | 5 |
| Next at continuation position 2 | 3 |
| Next at end position 7 | 8 |
| Extract from 1 to 5 | Emoji |
| Extract from 1 to continuation position 2 | Remaining suffix `😀é` |

These are the pinned raw operations, not host-language substring conventions.
Python helpers explicitly encode UTF-8 and check boundaries. PHP helpers traverse
valid UTF-8 characters using the standard PCRE extension. JS/TS, Rust and Wasm
retain their backend-owned representations and selected helpers.

## Public ABIs and internal representations

| Target | Public scalar representation and limits |
| --- | --- |
| JavaScript | Nat/Int `bigint`, Bool `boolean`, Char one-scalar string, String `string`, Unit `undefined`; the existing qualified scalar boundary |
| TypeScript | The same runtime scalar model with direct typed source and declaration companions |
| Rust | Existing checked Rust values and signatures, including retained generic/aggregate public support; exact numeric types select Cargo dependencies |
| Core Wasm | Existing lowered Wasm interface; the exported ABI is described by the emitted module and current capability checks |
| Component Wasm | Selected Bool-only public interface, with exact WIT and component validation |
| Python | Nat/Int exact `int` (Bool rejected as an integer), Bool `bool`, Char one-scalar `str`, String surrogate-free `str`, Unit `None` |
| PHP | Nat/Int `GMP`, Bool `bool`, Char one-scalar UTF-8 `string`, String valid UTF-8 `string`, Unit `null` |

Python and PHP public compound types, public function values and unresolved public
generics are rejected. Internally their printers handle retained records,
inductives, matches, closures and immutable array operations. The frontend and
strict IR checker still decide which source forms reach those printers.

Python public names must be valid ASCII identifiers excluding keywords,
`__all__` and the `_psc_` prefix. Unsupported public names fail before publication.
Internal names encode admitted identities without collisions. PHP preserves
public identities as associative export-map keys, with implementation variables
and helper closures inside a module factory. Neither target silently renames the
selected public API.

Both new targets validate argument type, Nat nonnegativity, Unicode validity and
arity. PHP arguments deliberately use `mixed` plus explicit guards so a caller
without strict typing cannot coerce a bad argument before validation.

## Evaluation, values and recursion

Generated code evaluates nested calls and operands in the lowered order using
fresh lexical temporaries. Closures capture the intended bindings across source
shadowing. Records and constructors preserve field evaluation before organizing
their representation. Array updates return independent persistent values:
Python uses tuples; PHP uses its array value-copy semantics.

Both new targets represent nullary declarations as pure thunks and emit all
function definitions before forcing exported scalar values. This preserves valid
forward value references regardless of specialization order. Internal references
can re-evaluate a thunk; module-wide memoization is not claimed. Public
PHP callers must treat generated GMP values as the exact scalar ABI and supply
valid values on later calls; no general aliasing or ownership API is introduced.

Python uses a selected generator-call trampoline with an explicit continuation
stack. Tail requests replace the current frame. PHP uses a selected private
WeakMap/generator scheduler and stores suspended calls on the heap. These helpers
schedule generated function calls; they do not interpret serialized IR.

Generated programs have no compiler-imposed execution fuel. Compile-time structural
traversal bounds and bounded helper dependency-closure traversal are not execution
fuel. Host memory and external process limits still apply. The deep PHP regression
allows 1 GiB for 100,000 pending frames. Deliberately divergent ordinary code is
observed only through an external timeout.

The new-target suite tests deep non-tail recursion and ordinary partial recursion
on actual interpreters. It does not extend every existing backend's recursion
qualification. Use the conformance record for the precise tested cases.

## Large decimal integers in Python

Python's decimal conversion guard must not narrow Nat/Int semantics or be disabled
globally by an emitted library. Integer source literals with 600 or more decimal
digits use hexadecimal Python syntax. `Int.repr` formats base-10^9 chunks, each
well below the conversion limit, and joins them into the full decimal string.

The focused consumer runs with `-X int_max_str_digits=640`, checks a 5,001-digit
source integer and a 5,001-digit decimal result, and confirms the global limit is
unchanged. No third-party Python runtime is needed. PHP uses GMP decimal parsing
and formatting for the same unbounded values.

## Selective runtime ownership and hashing

Each backend owns its semantic helper catalogue. It emits only the selected helper
dependency closure. A nullary Bool constant demonstrates a runtime-free module in
every applicable new target; call-free Rust and core Wasm examples also demonstrate
absence of unrelated numeric runtime dependencies.

| Target | Selection and evidence |
| --- | --- |
| JS / TS | UTF-8 and stack helper groups selected from lowered typed expressions |
| Rust | Per-helper closure, required numeric types/traits and exact selected Cargo dependencies |
| Core / component Wasm | Runtime function closure rooted in user functions, exports and function references |
| Python | Builtin alias, calls, decimal representation, UTF-8 and array helpers selected independently |
| PHP | GMP requirement, calls and Unicode helper closures selected independently |

The private `psc1-target.json` plan includes helper requirements, runtime version,
runtime source and generated declaration positions. Publication records
`runtimeSha256`, `runtimeBytes`, `runtimeFree` and `runtimeEncoding` in the
bundle manifest without duplicating the embedded runtime text.

For textual backends, `utf8-source` hashes the canonical selected runtime text
supplied by the native emitter. Formatter changes may alter its physical placement
or presentation in JS/TS/Rust output; artifact hashes independently cover the exact
published files. Python/PHP runtime text is checked as an exact emitted substring.

Wasm uses `psc-wasm-ir-json/1:functions`: the digest covers canonical JSON of the
selected lowered runtime function definitions, not an asserted byte range of
the final binary. Artifact hashes separately cover the exact `.wasm` and `.wat`
files. Runtime-byte counts with different encodings are not interchangeable size
measurements of executable machine code.

## Source ownership and publication

JS/TS maps refer to the captured source text and final formatted output. Python/PHP
`.origins.json` files use schema `psc1-source-origins/1` and explicitly declare
`coverage: declaration-starts-only`. Generated and original lines are one-based;
original columns are zero-based UTF-16 positions. Runtime helper lines are unmapped.
No full Python/PHP debugger stepping or standard source-map compatibility is claimed.

Public exports are structured inputs to printers. Imported/private declarations
can support implementation but do not become public by post-processing printed
`export` or `pub` text. Python `__all__` and `.pyi` exports are checked together;
PHP's Composer companion declares PHP >=8.5 and ext-gmp only when required.

The host validates target syntax/tools and seals the complete inventory before
atomic generation publication. Python compilation checks source and stub without
executing user code. PHP syntax checking uses `php -l`. A failed source, target
tool or publication attempt preserves the previously published generation.
Combined TS/JS generation performs both validations before one shared publication.

## Executable evidence and primary references

`test/RuntimeOracle.lean` obtains reference observations in the pinned native Lean
runtime. `scripts/runtime-conformance-tests.mjs` generates both source grammars and
executes the seven real targets against those observations.
`test/BackendScriptTests.lean` directly checks forged-wrapper rejection, public ABI
refusal and private compound closure capture. `scripts/script-backend-tests.mjs`
checks the host ABI, large integers, recursion and publication failure boundaries.

Exact successful commit/run evidence belongs in
[backend conformance](PSC1_BACKEND_CONFORMANCE.md) and the generated qualification
receipts. Tests are evidence for their explicit cases, not a preservation proof.

- [Pinned Lean Nat division](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/Nat/Div/Basic.lean)
- [Pinned Lean Char/Prelude definitions](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Prelude.lean)
- [Pinned Lean String operations](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Basic.lean)
- [Python integer conversion limits](https://docs.python.org/3/library/stdtypes.html#integer-string-conversion-length-limitation)
- [PHP GMP](https://www.php.net/manual/en/book.gmp.php)
- [WebAssembly component WIT](https://component-model.bytecodealliance.org/design/wit.html)
