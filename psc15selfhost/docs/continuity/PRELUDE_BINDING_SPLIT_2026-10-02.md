# Prelude elaboration context

The protected tail-loop replay spent 3,379,431 ms elaborating the prelude module.
Its bootstrap environment construction placed 136 bindings in one local context.
Those bindings are now closed, explicitly typed top-level definitions. This
reduces the repeated local-context work during generated compiler elaboration.

The native inventory compares all 81 prelude declarations, including their
types, values, metadata and order, against the preserved complete declaration
inventory. Exact parity passes. The full bootstrap regression suite passes,
including source guards, bridge, translation, backend, erasure, specialization,
source isolation and the 20,000-step generated runtime regressions.

Generated replay speed and a compiler fixed point remain separate checks; this
change does not claim either has completed. Existing replay processes retain
their immutable original source snapshots and generated compilers.
