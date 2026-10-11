# Native record construction and updates

The v7 record AST distinguishes literals from single-source updates. Parsing
shares the strict comma-separated field reader; declaration braces distinguish
a record update from a term block after reading the first expression once.
Scope capture, recursion traversal, APP-02 validation and source printers visit
both the source and replacements.

Elab/Record selects a nominal structure from the expected type or update source.
The obsolete environment scan that guessed literal types by field names is gone.
Duplicate, unknown and missing required fields are explicit errors. A shared
ordered argument engine accepts either syntax or typed Core values, preserving
the same expected-type propagation, dependent telescope substitution, implicits
and completion rules as ordinary applications.

An update binds its source in one Core let. Unchanged fields are typed Core
projections. Constructor order, not replacement order, determines checking.
Changing a field therefore rechecks retained dependent fields against the new
domain; incompatible proofs/data must be replaced. Record parameters and
universe arguments stay in the shared constructor/application path. Both runtime
targets consume the existing checked Core/erasure/IR representation.

This follows the selected record rule in PSCV0_LANGUAGE_REFERENCE.md and the
single-source binding/reconstruction design in Lean's src/Lean/Elab/StructInst.lean
at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. The full host elaborator is not imported.

Declared field defaults and record inheritance are pending. Update field holes
use the shared delayed abstraction in PSCV0_NATIVE_SCOPES.md, preserving their
captured contexts until the internal let can close safely.
The compact composite covers generic/proposition/dependent/empty updates and
both braced forms. Six refusals cover duplicates, unknown/missing fields,
untyped literal guessing, stale dependent proofs and recursive APP-02 checking.
