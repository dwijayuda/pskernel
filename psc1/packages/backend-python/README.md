# PSC1 DirectPython

This package owns the Lean-native Python emitter and its selected Python runtime
snippets. The native compiler calls `psPythonEmitModule` after captured-source
admission, erasure, specialization and executable IR validation. The emitter
revalidates its input and rejects unsupported public ABIs. An IR wrapper is data,
not admission evidence.

## Qualified boundary

Python >=3.14 is the selected minimum. The focused Linux suite runs Python 3.15
and checks compatibility on Python 3.14; exact tested versions, commit and run
belong to [backend conformance](../../docs/PSC1_BACKEND_CONFORMANCE.md).

Public Nat/Int values use exact Python `int`, Bool uses `bool`, Char uses one
Unicode scalar `str`, String uses surrogate-free `str`, and Unit uses `None`.
Public wrappers reject bad argument types, negative Nat values and invalid arity.
Public compound types and foreign imports are rejected. Internal closures, calls,
records, inductives, matches and immutable tuple-backed arrays use the existing
typed IR. No machine-width or float capability is added. Int division/modulo are
absent from the active IR and are not claimed.

Public names must be valid ASCII Python identifiers excluding keywords, `__all__`
and the reserved `_psc_` prefix. Unsupported names fail before publication.
Internal names encode admitted identities without collisions.

Every lexical binding has a unique local name. Generated statements evaluate
callees and operands once in lowered order. Boolean short-circuit forms branch
before the second operand. Function calls use a selected generator trampoline
with an explicit stack; tail requests replace the current frame. This scheduler
executes generated functions, not serialized IR. There is no runtime fuel or
change to Python's recursion limit.

Nullary declarations use pure thunks, with definitions emitted before public
values are forced. Internal references can re-evaluate a thunk. This handles
forward values without relying on declaration ordering; memoization is not claimed.

Nat subtraction saturates; division by zero returns zero; modulo by zero returns
the dividend. `Int.repr` uses base-10^9 chunks without changing Python's global
decimal conversion limit. Literals with 600 or more decimal digits use hexadecimal
syntax. The cloud suite executes 5,001-digit tests with a digit limit of 640.

Helpers are selected with their transitive dependencies and embedded in the output.
A scalar constant can be runtime-free. Public argument checks need only a builtin
alias unless other operations require helpers. The selected API appears exactly in
`__all__` and `.pyi`. Declaration origins record generated line starts after the
selected runtime prefix; they are not a full debugger source map.

## Source ownership

The helper catalogue is embedded in `src/Ps/BackendPython/Runtime.lean`; no external
Python package or development-tree runtime file is needed. The host hashes the
exact selected runtime text and each final artifact independently.

See [runtime semantics](../../docs/PSC1_RUNTIME_SEMANTICS.md) for the reference
operations, ABI and limitations. Backend preservation is not formally proved.
