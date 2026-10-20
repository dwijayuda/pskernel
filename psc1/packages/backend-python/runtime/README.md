# Python runtime ownership

Executable helper text lives in `../src/Ps/BackendPython/Runtime.lean` and is
embedded in the native compiler. The package supplies stable helper identifiers,
dependency closure, runtime version and exact selected source text. Selection is
per emitted bundle; generated output needs no external Python runtime package.
