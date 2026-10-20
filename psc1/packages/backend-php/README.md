# PSC1 DirectPHP

This package owns the Lean-native PHP emitter and selected target runtime
snippets. The native host supplies the independently admitted and revalidated
closed IR. `psPhpEmitValidatedModule` revalidates the constructible IR wrapper and
independently checks the selected public scalar ABI.

PHP >=8.5 is required. Exact tested versions and the Linux qualification run are
recorded in [backend conformance](../../docs/PSC1_BACKEND_CONFORMANCE.md).

## Output and scalar ABI

The generated `.php` file returns an associative public API map from a private
module factory. Public functions are closures; nullary scalar exports are values.
Helper closures and implementation variables do not enter the PHP global namespace.

| PSC1 type | PHP representation |
| --- | --- |
| Nat | Nonnegative `GMP` object |
| Int | `GMP` object |
| Bool | `bool` |
| Char | One Unicode scalar in a valid UTF-8 `string` |
| String | Valid UTF-8 `string` |
| Unit | `null` |

Parameters use `mixed` with exact checks to prevent weakly typed PHP callers from
coercing invalid arguments before the generated function checks them. The guards
also check Nat nonnegativity, Unicode validity and arity. Complex public signatures,
foreign IR imports, unresolved generics, fixed-width scalars and floats are refused.

Internally the printer handles the retained records, constructors, matches,
closures, arrays and scalar operations. Fresh locals preserve lexical bindings.
Array updates use PHP value-copy semantics. Nullary declarations are pure thunks,
so internal references can repeat computation; module-wide memoization is not claimed.
This also keeps mutable exported GMP objects from becoming a shared internal
constant cache.

## Selected runtime

The `.composer.json` companion declares PHP >=8.5. It adds `ext-gmp` only when
the selected operations or types need exact integers. UTF-8 helpers use PHP's
standard PCRE support and do not require mbstring. Pure Bool/String/Unit programs
can be emitted without GMP or runtime helper code. Helper selection respects
lexical shadowing.

A small private WeakMap/generator scheduler is selected for source calls and
callbacks. Generated functions remain ordinary callables while the scheduler
holds suspended calls on the heap. It does not interpret IR and imposes no execution
fuel. PHP tail calls currently retain frames; the deep cloud test allows 1 GiB for
100,000 suspended calls. External process timeouts observe deliberate divergence.

Nat subtraction saturates, division by zero returns zero, and modulo by zero
returns its dividend. Numeric values do not silently truncate to PHP machine ints.
Char conversion checks the original Nat scalar range. Raw String byte positions
match the pinned Lean model, including default Char `A` at invalid positions.
Int division/modulo are not present in the current IR and are not claimed.

The helper catalogue is embedded in `src/Ps/BackendPhp/Runtime.lean`. Returned
runtime text is the exact source substring used for hashing. Declaration origin
lines refer to final emitted source; companion coverage is explicitly limited to
declaration starts.

See [runtime semantics](../../docs/PSC1_RUNTIME_SEMANTICS.md) for the reference
definitions and full publication boundary. Backend preservation is not formally
proved; actual qualified cases are recorded from Linux CI.
